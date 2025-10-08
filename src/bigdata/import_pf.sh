#!/bin/bash
#
source "./config/config.sh"

LOG_NAME="import_pf"
readonly MODULE_DIR="bigdata"

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando a importação das tabelas PF para o Banco de Dados '$PROD_POSTGRES_DB_DATABASE' e o Schema '$PROD_POSTGRES_DB_SCHEMA'"
echo ""

copyDataFromRemote() {
    local table="$1" 
    local START_TIME_COPY SQL DATA DATA_FULL TOTAL_DATA RESULT OFFSET RECORDS_IMPORTED BATCH_SIZE EXISTS MAX_RECORDS SQL_PF
    BATCH_SIZE=$(echo "100" | tr -d '.') MAX_RECORDS=$(echo "1.000" | tr -d '.')
    EXISTS=$("${PSQL_CMD[@]}" -A -c "SELECT EXISTS (SELECT 1 FROM $POSTGRES_DB_SCHEMA_FINAL.$table)" | tail -n 2 | grep -oE "(t|f)")
    [ "$EXISTS" == "t" ] && { writeLog "🏁 Tabela '$table' já está populada, ignorando importação."; return; }

    writeLog "✅ Iniciando a cópia da tabela '$table'..."
    DATA=""
    DATA_FULL=""
    RECORDS_IMPORTED=0
    OFFSET=0
    while true; do
        SQL_PF="SELECT * FROM $PROD_POSTGRES_DB_SCHEMA.pf_pessoas p1 WHERE p1.cpf>'12345678901' ORDER BY p1.id OFFSET $OFFSET LIMIT $BATCH_SIZE"
        SQL=$SQL_PF
        [ "$table" != "pf_pessoas" ] && {
            SQL="SELECT p2.* FROM $PROD_POSTGRES_DB_SCHEMA.$table p2 WHERE p2.cpf IN ( $SQL_PF )"
            SQL=${SQL//"SELECT * FROM"/"SELECT p1.cpf FROM"}
        }
        echo "$SQL" > "$DIR_CACHE/${LOG_NAME}_lastSQL"

        START_TIME_COPY=$(date +%s%3N)
        DATA=$("${PROD_PSQL_CMD[@]}" -c "\copy ( $SQL ) TO STDOUT WITH CSV")
        [ -z "$DATA" ] && {
            writeLog "❎ Não há mais dados para copiar da tabela '$table'.";
            break;
        }
        DATA_FULL+="$DATA\n"
        TOTAL_DATA=$(echo "$DATA" | wc -l)
        writeLog "🔎 $(format_number $TOTAL_DATA) linhas recuperadas na tabela '$table' no remoto em $(calculateExecutionTime $START_TIME_COPY)"

        OFFSET=$((OFFSET + BATCH_SIZE))
        [ $OFFSET -ge $MAX_RECORDS ] && { break; }
    done

    START_TIME_COPY=$(date +%s%3N)
    RESULT=$(echo -e "$DATA_FULL" | head -n -1 | "${PSQL_CMD[@]}" -c "\copy $POSTGRES_DB_SCHEMA_FINAL.$table FROM STDIN WITH CSV")
    [ $? -ne 0 ] && {
        writeLog "❌ Erro ao copiar dados da tabela '$table' do remoto para o local"; 
        exit 1;
    }
    writeLog "📥 $(format_number $(echo "$RESULT" | grep -oE '[0-9]+')) linhas inseridas na tabela '$table' no local em $(calculateExecutionTime $START_TIME_COPY)"
    echo ""
}

createTableFromRemote() {
    local START_TIME_CREATE=$(date +%s%3N)
    local table="$1"

    local TABLE_EXISTS=$("${PSQL_CMD[@]}" -c "SELECT 1 FROM pg_tables WHERE schemaname = '$POSTGRES_DB_SCHEMA_FINAL' AND tablename = '$table'" | grep -q 1 && echo true || echo false)
    if [[ "$TABLE_EXISTS" != "false" ]]; then
        writeLog "🏁 Tabela '$table' já existe no local, pulando criação..."
        return
    fi

    writeLog "🔎 Recuperando a DDL da tabela '$table' no remoto..."
    DDL=$("${PROD_PG_DUMP[@]}" --no-owner --no-privileges --schema-only --table "$PROD_POSTGRES_DB_SCHEMA.$table" | sed -n '/CREATE TABLE/,/;/p')
    if [[ -z "$DDL" ]]; then
        writeLog "❌ Não consegui extrair DDL da tabela '$table' no remoto"
        exit 1
    fi
    DDL="${DDL//\bigdata_final/$POSTGRES_DB_SCHEMA_FINAL}"

    writeLog "📦 Criando a tabela '$table' no local..."
    echo "$DDL" | "${PSQL_CMD[@]}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar tabela '$table' no local"
        exit 1
    fi

    writeLog "✅ Tabela '$table' criada com sucesso no local em $(calculateExecutionTime $START_TIME_CREATE)"
    echo ""
}

source "./src/util/database/check_db.sh" $POSTGRES_DB_SCHEMA_FINAL
for entry in "${TABLES[@]}"; do
    table_name=${entry%%.*}
    createTableFromRemote "$table_name"
    copyDataFromRemote "$table_name"
done
source "./src/util/database/check_indexes.sh" "$POSTGRES_DB_SCHEMA_FINAL"
source "./src/util/database/check_triggers.sh" "$POSTGRES_DB_SCHEMA_FINAL"
source "./src/util/database/check_constraints.sh" "$POSTGRES_DB_SCHEMA_FINAL"

writeLog "$(repeat_char '-')"
writeLog "✅ Fim da importação Pessoas em $(calculateExecutionTime)"
echo
