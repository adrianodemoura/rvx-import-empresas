#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
LOG_NAME="import_pf"
readonly MODULE_DIR="bigdata"
readonly PF_ORIGEM="bigdata_final"
readonly PF_DATA_ORIGEM=$(date +%F)
readonly TABLES=(pf_pessoas pf_telefones pf_emails)

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando a importação das tabelas PF para o Banco de Dados '$PROD_POSTGRES_DB_DATABASE' e o Schema '$PROD_POSTGRES_DB_SCHEMA'"
echo

checkFunctions() {
  local OUTPUT
  local SQL="CREATE EXTENSION IF NOT EXISTS dblink SCHEMA $POSTGRES_DB_SCHEMA_FINAL;"
  writeLog "📣 Aguarde a verificação da função 'dblink' no schema '$POSTGRES_DB_SCHEMA_FINAL'..."
  OUTPUT=$("${PSQL_CMD[@]}" -t -A -c "$SQL" 2>&1)
  if [[ $? -ne 0 ]]; then
    writeLog "❌ Falha ao tentar criar função 'dblink' no schema '$POSTGRES_DB_SCHEMA_FINAL': $OUTPUT"
    exit 1
  fi
  writeLog "✅ Função 'dblink' checada com sucesso."
  echo
}

importPfTables() {
    local START_TIME_IMPORT START_ID=1 END_ID=$BATCH_SIZE TOTAL TOTAL_IMPORTED OUTPUT ROWS_AFFECTED COUNT
    local MAX_RECORDS=$(echo "1.000.000.000" | tr -d '.') LIMIT=$(echo "10.000.000" | tr -d '.') END_ID=$(echo "1.000.000" | tr -d '.')
    # local MAX_RECORDS=$(echo "1.000" | tr -d '.') LIMIT=$(echo "100" | tr -d '.')

    # Importando tabela a tabela
    for table in "${TABLES[@]}"; do
        START_TIME_IMPORT=$(date +%s%3N)

        OUTPUT=$("${PSQL_CMD[@]}" -t -A -c "SELECT EXISTS(SELECT 1 FROM $POSTGRES_DB_SCHEMA_FINAL.${table})")
        if [ "$OUTPUT" = "t" ]; then
            writeLog "📣 A Tabela \"$POSTGRES_DB_SCHEMA_FINAL.$table\" já possui registros, importação ignorada."
            continue
        fi

        writeLog "🔎 Aguarde a Importação de \"$PROD_POSTGRES_DB_HOST.$PROD_POSTGRES_DB_SCHEMA.$table\" para \"$POSTGRES_DB_HOST.$POSTGRES_DB_SCHEMA_FINAL.$table\"..."
        TOTAL_IMPORTED=0
        for ((i=0; i<=MAX_RECORDS; i+=$LIMIT))
        do
            START_TIME_IMPORT=$(date +%s%3N)

            case "$table" in
                pf_emails)
                    OUTPUT=$(docker exec -e PGPASSWORD="$POSTGRES_DB_PASSWORD" postgres-db psql -U $POSTGRES_DB_USER -d $POSTGRES_DB_DATABASE -t -A -c \
                        "INSERT INTO $POSTGRES_DB_SCHEMA_FINAL.$table (id, cpf, email, origem, data_origem)
                        SELECT id, cpf, email, origem, data_origem
                        FROM $POSTGRES_DB_SCHEMA_FINAL.dblink(
                            'dbname=$PROD_POSTGRES_DB_DATABASE port=$PROD_POSTGRES_DB_PORT host=$PROD_POSTGRES_DB_HOST user=$PROD_POSTGRES_DB_USER password=$PROD_POSTGRES_DB_PASSWORD',
                            'SELECT id, cpf, email, ''$PF_ORIGEM'' as origem, 
                                to_date(''$PF_DATA_ORIGEM'', ''YYYY-MM-DD'') as data_origem
                            FROM $PROD_POSTGRES_DB_SCHEMA.$table ORDER BY id LIMIT $LIMIT OFFSET $i'
                        ) AS t(id integer, cpf text, email text, origem text, data_origem date);" 2>&1)
                    ;;
                pf_telefones)
                    OUTPUT=$(docker exec -e PGPASSWORD="$POSTGRES_DB_PASSWORD" postgres-db psql -U $POSTGRES_DB_USER -d $POSTGRES_DB_DATABASE -t -A -c \
                        "INSERT INTO $POSTGRES_DB_SCHEMA_FINAL.$table (id, cpf, telefone, tipo, localization, status, origem, data_origem)
                        SELECT id, cpf, telefone, tipo, localization, status, origem, data_origem
                        FROM $POSTGRES_DB_SCHEMA_FINAL.dblink(
                            'dbname=$PROD_POSTGRES_DB_DATABASE port=$PROD_POSTGRES_DB_PORT host=$PROD_POSTGRES_DB_HOST user=$PROD_POSTGRES_DB_USER password=$PROD_POSTGRES_DB_PASSWORD',
                            'SELECT id, cpf, telefone, tipo, localization, status,  ''$PF_ORIGEM'' as origem, 
                                to_date(''$PF_DATA_ORIGEM'', ''YYYY-MM-DD'') as data_origem
                            FROM $PROD_POSTGRES_DB_SCHEMA.$table ORDER BY id LIMIT $LIMIT OFFSET $i'
                        ) AS t(id integer, cpf text, telefone text, tipo text, localization integer, status boolean, origem text, data_origem date);" 2>&1)
                    ;;
                pf_pessoas)
                    OUTPUT=$(docker exec -e PGPASSWORD="$POSTGRES_DB_PASSWORD" postgres-db psql -U $POSTGRES_DB_USER -d $POSTGRES_DB_DATABASE -t -A -c \
                        "INSERT INTO $POSTGRES_DB_SCHEMA_FINAL.$table (id, cpf, nome, cpf_basico, sexo, nascimento)
                        SELECT id, cpf, nome, cpf_basico, sexo, nascimento
                        FROM $POSTGRES_DB_SCHEMA_FINAL.dblink(
                            'dbname=$PROD_POSTGRES_DB_DATABASE port=$PROD_POSTGRES_DB_PORT host=$PROD_POSTGRES_DB_HOST user=$PROD_POSTGRES_DB_USER password=$PROD_POSTGRES_DB_PASSWORD',
                            'SELECT id, cpf, nome, cpf_basico, sexo, nascimento FROM $PROD_POSTGRES_DB_SCHEMA.$table ORDER BY id LIMIT $LIMIT OFFSET $i'
                        ) AS t(id integer, cpf text, nome text, cpf_basico text, sexo text, nascimento text);
                        " 2>&1)
                    ;;
            esac
            if echo "$OUTPUT" | grep -iq "error"; then
                writeLog "❌ Erro ao importar dados: $OUTPUT"
                exit 1
            fi

            ROWS_AFFECTED=$(echo "$OUTPUT" | grep -oP '(?<=INSERT 0 )\d+')
            if [ "$ROWS_AFFECTED" = "0" ]; then
                writeLog "🏁 Nenhum registro retornado, encerrando o loop."
                break
            fi

            TOTAL_IMPORTED=$((TOTAL_IMPORTED + LIMIT))
            writeLog "📣 Transferido bloco $(format_number $i)/$(format_number $LIMIT) em $(calculateExecutionTime $START_TIME_IMPORT)"
        done
        writeLog "🏁 Importação concluída de '$table'. até: $(format_number $TOTAL_IMPORTED) registros em $(calculateExecutionTime $START_TIME_IMPORT)"
        echo
    done
}

source "./src/util/database/check_db.sh" "$POSTGRES_DB_SCHEMA_FINAL"

checkFunctions

source "./src/util/database/check_tables.sh" "$POSTGRES_DB_SCHEMA_FINAL"

importPfTables

source "./src/util/database/check_indexes.sh" "$POSTGRES_DB_SCHEMA_FINAL"
source "./src/util/database/check_triggers.sh" "$POSTGRES_DB_SCHEMA_FINAL"
source "./src/util/database/check_constraints.sh" "$POSTGRES_DB_SCHEMA_FINAL"

writeLog "$(repeat_char '-')"
writeLog "✅ Fim da importação Pessoas em $(calculateExecutionTime)"
echo
