#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'
mkdir -p "$DIR_CACHE/replicate"

readonly table_main='pf_pessoas'
readonly tables=(pf_telefones pf_emails)
readonly MAX_ROWS=10000
readonly MAX_PARALLEL=4
readonly BATCH_SIZE=1000

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando replicação de '$POSTGRES_DB_HOST.$POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' para '$MONGODB_HOST.$MONGODB_DATABASE'..."
echo

replicateTable() {
    local table=$1
    local collection=${2:-$table_main}
    local offset=0

    writeLog "🔄 Replicando tabela '$table' para collection '$collection' ..."

    while true; do
        SQL_PF="SELECT cpf AS _id, *, now() as imported_at FROM $POSTGRES_DB_SCHEMA_FINAL.$table ORDER BY cpf LIMIT $BATCH_SIZE OFFSET $offset"
        # writeLog "🛑 Executando '$SQL_PF'"

        # Exporta e envia direto pro mongoimport dentro do container
        "${PSQL_CMD[@]}" -c "\copy ($SQL_PF) TO STDOUT WITH CSV HEADER" | \
        docker exec -i $MONGO_CONTAINER mongoimport \
            --host "$MONGODB_HOST" \
            --port "$MONGODB_PORT" \
            --username "$MONGODB_USER" \
            --password "$MONGODB_PASSWORD" \
            --authenticationDatabase "$MONGODB_DATABASE" \
            --db "$MONGODB_DATABASE" \
            --collection "$collection" \
            --type csv \
            --headerline \
            --mode upsert > /dev/null 2>&1

        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao importar lote OFFSET $offset da tabela '$table'. Abortando..."
            exit 1
        fi

        ((offset += BATCH_SIZE))
        writeLog "📦 Lote de $(format_number $BATCH_SIZE) linhas processado (OFFSET $(format_number $offset))"
        if [[ $offset -ge $MAX_ROWS ]]; then
            writeLog "🏁 Offset chegou em '$(format_number $offset)' no máximo de '$(format_number $MAX_ROWS)' linhas para serem importadas."
            break
        fi
    done

    # Total de documentos na collection no MongoDB
    TOTAL_DOCS=$(docker exec -i $MONGO_CONTAINER mongosh \
        --quiet \
        --username "$MONGODB_USER" \
        --password "$MONGODB_PASSWORD" \
        --authenticationDatabase "$MONGODB_DATABASE" \
        "$MONGODB_DATABASE" \
        --eval "db.getCollection('$collection').countDocuments()")
    writeLog "ℹ️ Total de documentos na collection '$collection': $(format_number $TOTAL_DOCS)"

    # FIM
    writeLog "✅ Tabela '$table' replicada com sucesso com '$(format_number $offset)' linhas em $(calculateExecutionTime)"
    echo
}

# Primeiro importa a tabela principal
replicateTable "$table_main" "$table_main"

# Depois importa as sub-tabelas em paralelo (se quiser habilitar)
# count=0
# for table in "${tables[@]}"; do
#     replicateTable "$table" "$table_main" &
#     ((count++))
#     [[ $count -ge $MAX_PARALLEL ]] && wait && count=0
# done
# wait

writeLog "$(repeat_char '-')"
writeLog "🏁 Todas as tabelas foram replicadas para o MongoDB!"
