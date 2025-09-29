#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'
mkdir -p "$DIR_CACHE/replicate"

readonly table_main='pf_pessoas'
readonly tables=(pf_emails.emails pf_telefones.telefones)
readonly BATCH_SIZE=10
readonly MAX_ROWS=100

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando replicação de '$POSTGRES_DB_HOST.$POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' para '$MONGODB_HOST.$MONGODB_DATABASE'..."
echo

replicateWithSubcollections() {
    local loop=1
    local table=""
    local nick=""
    local offset=0

    writeLog "🔄 Replicando tabela principal '$table_main' com subcollections ..."
    for item in "${tables[@]}"; do
        table=${item%%.*}
        nick=${item#*.}

        echo
        writeLog "🔎 Buscando dados de '$table' ..."
        while true; do
            SQL="SELECT p1.cpf AS _id, p1.id as id, COALESCE( (SELECT json_agg(p2.*) FROM $POSTGRES_DB_SCHEMA_FINAL.$table p2 WHERE p2.cpf = p1.cpf), '[]') AS $nick
                FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main p1
                ORDER BY p1.cpf
                LIMIT $BATCH_SIZE OFFSET $offset"
            SQL="SELECT row_to_json(t) FROM ( $SQL ) t;"
            if [ $loop == 1 ]; then
                SQL="${SQL//"p1.cpf AS _id, p1.id as id,"/"p1.cpf AS _id, p1.*, now() AS imported_at,"}"
            fi

            OUT=$("${PSQL_CMD[@]}" -t -A -F "" -c "$SQL")
            if [[ -z "$OUT" ]]; then
                writeLog "⚠️ Nenhum dado retornado no lote OFFSET $offset/$BATCH_SIZE e no loop $loop!"
                break
            fi

            # Envia para o MongoDB
            echo "$OUT" | "${MONGOIMPORT_CMD[@]}" \
                --collection "$table_main" \
                --mode upsert \
                --upsertFields _id \
                --type json > /dev/null 2>&1

            if [[ $? -ne 0 ]]; then
                writeLog "❌ Erro ao importar lote OFFSET $offset. Abortando..."
                exit 1
            fi

            ((offset += BATCH_SIZE))
            writeLog "📦 $(printf "%09d" "$loop")] Lote $(format_number $offset)/$(format_number $BATCH_SIZE) processado com sucesso em $(calculateExecutionTime)"

            [[ $offset -ge $MAX_ROWS ]] && break
            ((loop++))
        done
        offset=0
    done

    TOTAL_DOCS=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$table_main').countDocuments()")
    echo
    writeLog "✅ Tabela '$table_main' replicada com sucesso com '$(format_number $TOTAL_DOCS)' documentos no MongoDB!"
    echo
}

OUTPUT=$("${MONGO_CMD[@]}" --quiet --eval "use $MONGODB_DATABASE; db.dropDatabase()")
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar excluir a database $MONGO_DATABASE"
    exit 1
fi

replicateWithSubcollections

writeLog "$(repeat_char '-')"
writeLog "🏁 Replicação concluída com sucesso!"
