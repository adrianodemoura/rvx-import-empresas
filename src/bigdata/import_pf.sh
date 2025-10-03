#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
LOG_NAME="import_pf"
readonly MODULE_DIR="bigdata"
readonly PF_ORIGEM="bigdata_final"
readonly PF_DATA_ORIGEM=$(date +%F)
readonly TABLES=(pf_pessoas pf_telefones pf_emails pf_enderecos)

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

copyDataFromRemote() {
  local table="$1"
  local BATCH_SIZE=$(echo "1.000" | tr -d '.')
  local MAX_RECORDS=$(echo "10.000" | tr -d '.')
  local OFFSET=0
  local RECORDS_IMPORTED=0
  local RESULT=""

  while true; do
    local START_TIME_COPY=$(date +%s%3N)
    writeLog "🔎 Buscando os dados da tabela '$table' no remoto...."
    local DATA=$("${PROD_PSQL_CMD[@]}" -c "\copy (SELECT * FROM $PROD_POSTGRES_DB_SCHEMA.$table LIMIT $BATCH_SIZE OFFSET $OFFSET) TO STDOUT WITH CSV HEADER")
    if [[ -z "$DATA" ]]; then
        writeLog "✅ Não há mais dados para copiar da tabela '$table'."
        break
    fi

    writeLog "📥 Inserindo os dados da tabela '$table' no local..."
    RESULT=$(echo "$DATA" | "${PSQL_CMD[@]}" -c "\copy $POSTGRES_DB_SCHEMA_FINAL.$table FROM STDIN WITH CSV HEADER")
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao copiar dados da tabela '$table' do remoto para o local"
        exit 1
    fi

    RECORDS_IMPORTED=$((RECORDS_IMPORTED + $(echo "$RESULT" | grep -oE '[0-9]+')))
    OFFSET=$((OFFSET + BATCH_SIZE))
    writeLog "✅ $(format_number $BATCH_SIZE) registros copiadas da tabela '$table' do remoto para o local em $(calculateExecutionTime $START_TIME_COPY)"
    if [[ $RECORDS_IMPORTED -ge $MAX_RECORDS ]]; then
        writeLog "✅ Máximo de registros alcançado $(format_number $MAX_RECORDS). Parando a importação da tabela '$table'."
        break
    fi
  done
  writeLog "✅ $(format_number $RECORDS_IMPORTED) registros da tabela copiados com sucesso em $(calculateExecutionTime)"
  echo ""
}

createTableFromRemote() {
    local START_TIME_CREATE=$(date +%s%3N)
    local table="$1"

    local TABLE_EXISTS=$("${PSQL_CMD[@]}" -c "SELECT 1 FROM pg_tables WHERE schemaname = '$POSTGRES_DB_SCHEMA_FINAL' AND tablename = '$table'" | grep -q 1 && echo true || echo false)
    if [[ "$TABLE_EXISTS" != "false" ]]; then
        writeLog "✅ Tabela '$table' já existe no local, pulando criação..."
        return
    fi

    writeLog "🔎 Recuperando a DDL da tabela '$table' no remoto..."
    DDL=$("${PROD_PG_DUMP[@]}" --no-owner --no-privileges --schema-only --table "$PROD_POSTGRES_DB_SCHEMA.$table" | sed -n '/CREATE TABLE/,/;/p')
    if [[ -z "$DDL" ]]; then
        writeLog "❌ Não consegui extrair DDL da tabela '$table' no remoto"
        exit 1
    fi

    writeLog "📦 Criando a tabela '$table' no local..."
    echo "$DDL" | "${PSQL_CMD[@]}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar tabela '$table' no local"
        exit 1
    fi

    writeLog "✅ Tabela '$table' criada com sucesso no local em $(calculateExecutionTime $START_TIME_CREATE)"
    echo ""
}

importPfTables() {
    for table in "${TABLES[@]}"; do
        createTableFromRemote "$table"
        copyDataFromRemote "$table"
    done
}

source "./src/util/database/check_db.sh" $POSTGRES_DB_SCHEMA_FINAL

importPfTables

writeLog "$(repeat_char '-')"
writeLog "✅ Fim da importação Pessoas em $(calculateExecutionTime)"
echo
