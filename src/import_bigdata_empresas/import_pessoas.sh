#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
readonly MODULE_DIR="import_bigdata_empresas"
readonly ORIGEM="estabelecimentos"
readonly DATA_ORIGEM='2025-08-10'
readonly LOG_NAME_SUCCESS="success_csv_import_${DB_SCHEMA_TMP,,}"
readonly LOG_NAME_ERROR="error_csv_import_${DB_SCHEMA_TMP,,}"
readonly TABLES=("pf_pessoas")
readonly BATCH_SIZE=$(echo "100.000" | tr -d '.')

writeLog "============================================================================================================================="
writeLog "✅ [$(date +'%Y-%m-%d %H:%M:%S.%3N')] Iniciando a importação de Pessoas para o Banco de Dados \"$DB_DATABASE\" e o Schema \"$DB_SCHEMA\""

checkIndiceTrigger() {
    local SQL="-- pf_pessoas
            CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (cpf);
            CREATE INDEX IF NOT EXISTS idx_pf_pessoas_nome ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (nome);
            CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf_basico ON $DB_SCHEMA_PESSOAS.pf_pessoas USING btree (cpf_basico);
            "
    if PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "$SQL"; then
        writeLog "✅ Indíces criados com sucesso ..."
    else
        writeLog "❌ Falha ao tentar criar indices .."
    fi
}

importCpfSocios() {
    local START_TIME_IMPORT START_ID=1 END_ID=$BATCH_SIZE TOTAL

    # Checa a tabela pf_pessoas
    # if PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "DROP TABLE IF EXISTS ${DB_SCHEMA}.pf_pessoas CASCADE"; then
    #   writeLog "🗑️ Tabela \"${DB_SCHEMA}.pf_pessoas\" removida com sucesso."
    # else
    #   writeLog "⚠️ Falha ao tentar remover a tabela \"${DB_SCHEMA}.pf_pessoas\"."
    # fi
    # source "./src/util/database/check_tables.sh" "$DB_SCHEMA_PESSOAS"

    # Descobre o maior ID do banco origem
    TOTAL=$(PGPASSWORD="$PROD_DB_PASSWORD" "${PROD_PSQL_CMD[@]}" -t -A -c \
        "SELECT max(id) FROM ${PROD_DB_SCHEMA}.pf_pessoas")
    writeLog "🔎 Total de registros a importar: $(format_number $TOTAL)"

    # Loop até chegar no final
    while [ $START_ID -le $TOTAL ]; do
        # Ajusta o último ID do lote se passar do total
        if [ $END_ID -gt $TOTAL ]; then
            END_ID=$TOTAL
        fi

        # Exporta do banco origem e importa via COPY no destino
        START_TIME_IMPORT=$(date +%s%3N)
        writeLog "📥 Importando pessoas IDs $(format_number $START_ID) até $(format_number $END_ID)..."
        if PGPASSWORD="$PROD_DB_PASSWORD" "${PROD_PSQL_CMD[@]}" -t -A -c \
            "SELECT pp.id, pp.cpf_basico, pp.cpf, pp.nome
            FROM ${PROD_DB_SCHEMA}.pf_pessoas pp
            WHERE pp.id BETWEEN $START_ID AND $END_ID
            ORDER BY pp.id
            LIMIT ${BATCH_SIZE}" \
        | PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c \
            "COPY ${DB_SCHEMA}.pf_pessoas (id, cpf_basico, cpf, nome) FROM STDIN WITH (FORMAT text, DELIMITER '|')"; then
            writeLog "✅ Lote $START_ID–$END_ID importado com sucesso em $(calculateExecutionTime $START_TIME_IMPORT)"
            echo
        else
            writeLog "❌ Falha ao importar lote $START_ID–$END_ID."
            echo
            exit 1
        fi

        START_ID=$((END_ID + 1))
        END_ID=$((END_ID + BATCH_SIZE))
    done

    writeLog "🏁 Importação concluída. Total: $(format_number $TOTAL) registros."
}

# checa banco de dados e schema
# source "./src/util/database/check_db.sh" "$DB_SCHEMA_PESSOAS"

# Importa os Sócios do banco BigDATA
# importCpfSocios

# Checa índices e triggers
checkIndiceTrigger

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Fim da importação Pessoas para \"$DB_SCHEMA\" em $(calculateExecutionTime)"
echo
