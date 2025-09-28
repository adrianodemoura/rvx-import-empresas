#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'
mkdir -p "$DIR_CACHE/replicate"

readonly tables=(pf_pessoas pf_emails)
LIMIT=10000
MAX_PARALLEL=4

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando replicação de '$DB_SCHEMA_FINAL' para MongoDB..."

replicateTable() {
    local table=$1
    writeLog "🔄 Replicando tabela '$table' ..."

    "${PSQL_CMD[@]}" -c "\copy (SELECT *, cpf AS _id FROM $POSTGRES_DB_SCHEMA_FINAL.$table) TO STDOUT WITH CSV HEADER" \
    | docker exec -i mongo-repl mongoimport \
        --host "$MONGODB_HOST" \
        --port "$MONGODB_PORT" \
        --username "$MONGODB_USER" \
        --password "$MONGODB_PASSWORD" \
        --authenticationDatabase "$MONGODB_DATABASE" \
        --db "$MONGODB_DATABASE" \
        --collection "$table" \
        --type csv \
        --headerline \
        --mode upsert

    writeLog "✅ Tabela '$table' replicada com sucesso!"
}

# Paralelismo
count=0
for table in "${tables[@]}"; do
    replicateTable "$table" &
    ((count++))
    [[ $count -ge $MAX_PARALLEL ]] && wait && count=0
done
wait

writeLog "$(repeat_char '-')"
writeLog "🏁 Todas as tabelas foram replicadas para o MongoDB!"
