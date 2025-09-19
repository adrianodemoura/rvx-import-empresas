#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
readonly MODULE_DIR="import_bigdata_empresas"
readonly ORIGEM="estabelecimentos"
readonly LOG_NAME_SUCCESS="success_pf_pessoas_import_${DB_SCHEMA_PESSOAS,,}"
readonly LOG_NAME_ERROR="error_pf_pessoas_import_${DB_SCHEMA_PESSOAS,,}"
readonly TABLES=("pf_pessoas")
readonly BATCH_SIZE=$(echo "1.000.000" | tr -d '.')

writeLog "============================================================================================================================="
writeLog "✅ [$(date +'%Y-%m-%d %H:%M:%S.%3N')] Iniciando a importação de Pessoas para o Banco de Dados \"$DB_DATABASE\" e o Schema \"$DB_SCHEMA_PESSOAS\""

checkIndiceTrigger() {
    local SQL="-- pf_pessoas
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_nome ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (nome);
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf_basico ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (cpf_basico);
        ALTER TABLE $DB_SCHEMA_PESSOAS.pf_pessoas ADD CONSTRAINT unique_pf_pessoas_id UNIQUE (id);
        "
    if PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "$SQL"; then
        writeLog "✅ Indíces criados com sucesso ..."
    else
        writeLog "❌ Falha ao tentar criar indices .."
    fi
}

importCpfSocios() {
    local START_TIME_IMPORT START_ID=1 END_ID=$BATCH_SIZE TOTAL TOTAL_IMPORTED OUTPUT ROWS_AFFECTED
    local MAX_RECORDS=$(echo "1.000.000.000" | tr -d '.') LIMIT=$(echo "1.000.000" | tr -d '.')
    # local MAX_RECORDS=$(echo "1.000" | tr -d '.') LIMIT=$(echo "100" | tr -d '.')

    # Checa a tabela pf_pessoas
    if PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "DROP TABLE IF EXISTS ${DB_SCHEMA_PESSOAS}.pf_pessoas CASCADE"; then
      writeLog "🗑️ Tabela \"${DB_SCHEMA_PESSOAS}.pf_pessoas\" removida com sucesso."
    else
      writeLog "⚠️ Falha ao tentar remover a tabela \"${DB_SCHEMA_PESSOAS}.pf_pessoas\"."
    fi
    source "./src/util/database/check_tables.sh" "$DB_SCHEMA_PESSOAS"

    # Descobre o maior ID do banco origem
    TOTAL=$(PGPASSWORD="$PROD_DB_PASSWORD" "${PROD_PSQL_CMD[@]}" -t -A -c "SELECT max(id) FROM ${PROD_DB_SCHEMA}.pf_pessoas")
    writeLog "🔎 Total de registros a importar: $(format_number $TOTAL)"

    # Loop até chegar no final
    TOTAL_IMPORTED=0
    for ((i=0; i<=MAX_RECORDS; i+=$LIMIT))
    do
        START_TIME_IMPORT=$(date +%s%3N)

        OUTPUT=$(PGPASSWORD="$PROD_DB_PASSWORD" docker exec -it postgres-db psql -U $DB_USER -d $DB_DATABASE \
            -c "
            INSERT INTO $DB_SCHEMA_PESSOAS.pf_pessoas (id, cpf, nome, cpf_basico)
            SELECT id, cpf, nome, cpf_basico
            FROM bigdata_final.dblink(
            'dbname=$PROD_DB_DATABASE port=$PROD_DB_PORT host=$PROD_DB_HOST user=$PROD_DB_USER password=$PROD_DB_PASSWORD',
            'SELECT id, cpf, nome, cpf_basico FROM bigdata_final.pf_pessoas LIMIT $LIMIT OFFSET $i'
            ) AS t(id integer, cpf text, nome text, cpf_basico text);
            " 2>&1)

        ROWS_AFFECTED=$(echo "$OUTPUT" | grep -oP '(?<=INSERT 0 )\d+')
        if [ "$ROWS_AFFECTED" = "0" ]; then
            writeLog "🏁 Nenhum registro retornado, encerrando o loop."
            break
        fi

        TOTAL_IMPORTED=$((TOTAL_IMPORTED + LIMIT))
        writeLog "📣 Transferido bloco $(format_number $i)/$(format_number $LIMIT) em $(calculateExecutionTime $START_TIME_IMPORT)"
    done

    writeLog "🏁 Importação concluída. Total: $(format_number $TOTAL_IMPORTED) registros."
}

# checa banco de dados e schema
source "./src/util/database/check_db.sh" "$DB_SCHEMA_PESSOAS"

# Importa os Sócios do banco BigDATA
importCpfSocios

# Checa índices e triggers
checkIndiceTrigger

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Fim da importação Pessoas para \"$DB_SCHEMA_PESSOAS.pf_pessoas\" em $(calculateExecutionTime)"
echo
