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

readonly PROD_PG_DUMP=(
  docker exec -i -e PGPASSWORD="$PROD_POSTGRES_DB_PASSWORD" $POSTGRES_CONTAINER 
  pg_dump 
  -p "$PROD_POSTGRES_DB_PORT"
  -h "$PROD_POSTGRES_DB_HOST" 
  -U "$PROD_POSTGRES_DB_USER" 
  -d "$PROD_POSTGRES_DB_DATABASE"
)

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando a importação das tabelas PF para o Banco de Dados '$PROD_POSTGRES_DB_DATABASE' e o Schema '$PROD_POSTGRES_DB_SCHEMA'"
echo

createTableFromRemote() {
    local START_TIME_CREATE=$(date +%s%3N)
    local table="$1"

    writeLog "🔎 Recuperando a DDL da tabela '$table' no remoto..."
    DDL=$("${PROD_PG_DUMP[@]}" --no-owner --no-privileges --schema-only --table "$PROD_POSTGRES_DB_SCHEMA.$table" | sed -n '/CREATE TABLE/,/;/p')
    if [[ -z "$DDL" ]]; then
        writeLog "❌ Não consegui extrair DDL da tabela '$table' no remoto"
        exit 1
    fi
    echo "$DDL" > "$DIR_CACHE/${table}_ddl"

    writeLog "❎ Removendo a table '$table' no local, se existir..."
    echo "DROP TABLE IF EXISTS $POSTGRES_DB_SCHEMA_FINAL.$table CASCADE;" | "${PSQL_CMD[@]}" > /dev/null 2>&1

    writeLog "🔎 Criando a tabela '$table' no local..."
    echo "$DDL" | "${PSQL_CMD[@]}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar tabela '$table' no local"
        exit 1
    fi

    writeLog "✅ Tabela '$table' criada com sucesso no local em $(calculateExecutionTime $START_TIME_CREATE)"
    echo
}

importPfTables() {
    for table in "${TABLES[@]}"; do
        createTableFromRemote "$table"
    done
}

importPfTables

writeLog "$(repeat_char '-')"
writeLog "✅ Fim da importação Pessoas em $(calculateExecutionTime)"
echo
