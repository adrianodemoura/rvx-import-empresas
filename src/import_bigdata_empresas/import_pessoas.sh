#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
readonly MODULE_DIR="import_bigdata_empresas"
readonly ORIGEM="estabelecimentos"
readonly LOG_NAME_SUCCESS="success_pf_pessoas_import_${DB_SCHEMA_FINAL,,}"
readonly LOG_NAME_ERROR="error_pf_pessoas_import_${DB_SCHEMA_FINAL,,}"
readonly TABLES=("pf_pessoas")

writeLog "============================================================================================================================="
writeLog "✅ [$(date +'%Y-%m-%d %H:%M:%S.%3N')] Iniciando a importação de Pessoas para o Banco de Dados \"$DB_DATABASE\" e o Schema \"$DB_SCHEMA_FINAL\""

checkFunctions() {
    local OUTPUT
    local SQL="CREATE EXTENSION IF NOT EXISTS dblink SCHEMA $DB_SCHEMA_TMP;"

    writeLog "📣 Aguarde a verificação da função \"dblink\" no schema \"$DB_SCHEMA_FINAL\"..."

    OUTPUT=$("${PSQL_CMD[@]}" -t -A -C "$SQL" 2>&1)
    if [[ $! -ne 0 ]]; then
        writeLog "❌ Falha ao tentar criar função \"dblink\" no schema $DB_SCHEMA_TMP"
        exit 1
    fi

    writeLog "✅ Função \"dblink\" checada com sucesso."
    echo
}

importPfPessoas() {
    local START_TIME_IMPORT START_ID=1 END_ID=$BATCH_SIZE TOTAL TOTAL_IMPORTED OUTPUT ROWS_AFFECTED COUNT
    local MAX_RECORDS=$(echo "1.000.000.000" | tr -d '.') LIMIT=$(echo "10.000.000" | tr -d '.') END_ID=$(echo "1.000.000" | tr -d '.')
    # local MAX_RECORDS=$(echo "1.000" | tr -d '.') LIMIT=$(echo "100" | tr -d '.')

    # Checa se a tabela está cheia, se sim não prossegue.
    COUNT=$("${PSQL_CMD[@]}" -t -A -c "SELECT COUNT(1) FROM ${DB_SCHEMA_FINAL}.pf_pessoas")
    if [ "$COUNT" -gt 0 ]; then
        writeLog "❌ Tabela \"${DB_SCHEMA_FINAL}.pf_pessoas\" já está populada."
        exit 1
    fi

    # Loop até chegar no final
    writeLog "🔎 Aguarde a Importação de \"$PROD_DB_HOST.$PROD_DB_SCHEMA.pf_pessoas\" para \"$DB_HOST.$DB_SCHEMA_FINAL.pf_pessoas\"..."
    TOTAL_IMPORTED=0
    for ((i=0; i<=MAX_RECORDS; i+=$LIMIT))
    do
        START_TIME_IMPORT=$(date +%s%3N)

        OUTPUT=$(docker exec -e PGPASSWORD="$PROD_DB_PASSWORD" postgres-db psql -U $DB_USER -d $DB_DATABASE -t -A -c \
            "INSERT INTO $DB_SCHEMA_FINAL.pf_pessoas (id, cpf, nome, cpf_basico, sexo, nascimento)
              SELECT id, cpf, nome, cpf_basico, sexo, nascimento
              FROM $DB_SCHEMA_TMP.dblink(
                  'dbname=$PROD_DB_DATABASE port=$PROD_DB_PORT host=$PROD_DB_HOST user=$PROD_DB_USER password=$PROD_DB_PASSWORD',
                  'SELECT id, cpf, nome, cpf_basico, sexo, nascimento FROM bigdata_final.pf_pessoas ORDER BY id LIMIT $LIMIT OFFSET $i'
              ) AS t(id integer, cpf text, nome text, cpf_basico text, sexo text, nascimento text);
            " 2>&1)

        ROWS_AFFECTED=$(echo "$OUTPUT" | grep -oP '(?<=INSERT 0 )\d+')
        if [ "$ROWS_AFFECTED" = "0" ]; then
            writeLog "🏁 Nenhum registro retornado, encerrando o loop."
            break
        fi

        TOTAL_IMPORTED=$((TOTAL_IMPORTED + LIMIT))
        writeLog "📣 Transferido bloco $(format_number $i)/$(format_number $LIMIT) em $(calculateExecutionTime $START_TIME_IMPORT)"
    done

    writeLog "🏁 Importação concluída. até: $(format_number $TOTAL_IMPORTED) registros."
}

# checa banco de dados e schema
source "./src/util/database/check_db.sh" "$DB_SCHEMA_FINAL"

# checa as funções
checkFunctions

# Checa a tabela pf_pessoas
source "./src/util/database/check_tables.sh" "$DB_SCHEMA_FINAL"

# Importa os Sócios do banco BigDATA
importPfPessoas

# Checa índices, triggers e constraints
source "./src/util/database/check_indexes.sh" "$DB_SCHEMA_FINAL"
source "./src/util/database/check_triggers.sh" "$DB_SCHEMA_FINAL"
source "./src/util/database/check_constraints.sh" "$DB_SCHEMA_FINAL"

# FIM
echo
echo "---------------------------------------------------------------------------"
writeLog "✅ Fim da importação Pessoas para \"$DB_SCHEMA_FINAL.pf_pessoas\" em $(calculateExecutionTime)"
echo
