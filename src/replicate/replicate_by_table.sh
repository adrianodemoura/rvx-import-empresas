#!/bin/bash
#
source "./config/config.sh"

readonly EXECUTION_MODE="${1:-update}"
readonly LOG_NAME="replicate_by_table"
readonly NUM_INSTANCES=10
readonly TABLE_MAIN='pf_pessoas'
LAST_IMPORTED_AT=""

writeLog "$(repeat_char '=')"
writeLog "✅ Exportando dados PF do PostgreSQL → MongoDB"
echo ""

checkStart() {
    writeLog "🚀 Iniciando replicação do PostgreSQL para MongoDB, no modo '$EXECUTION_MODE'..."
    mkdir -p "$DIR_CACHE/${LOG_NAME}"

    # Checando o último offset
    if [ "$EXECUTION_MODE" == "update" ]; then 
        LAST_IMPORTED_AT=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$TABLE_MAIN').findOne({}, { imported_at: 1, _id: 0 })?.imported_at" | sed 's/-[0-9]\{2\}:[0-9]\{2\}$//')
        LAST_IMPORTED_AT=${LAST_IMPORTED_AT:-1970-01-01}
        writeLog "🏁 Iniciando replicação com dados MAIOR QUE '$LAST_IMPORTED_AT'"
    fi

    # Checa se existe o índice da tabela TABLE_MAIN
    local exists_index=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT * FROM pg_indexes WHERE schemaname='$POSTGRES_DB_SCHEMA_FINAL' AND tablename='$TABLE_MAIN'")
    [ -z "$exists_index" ] && {
        writeLog "❌ A tabela '$TABLE_MAIN' não possui índice para executar a pesquisa!"
        exit 1
    }
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    writeLog "🔎 Aguarde a contagem de documentos no MongoDB..."
    local total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$TABLE_MAIN.estimatedDocumentCount()")
    writeLog "✅ Estimasse $(format_number $total_mongo) documentos no total do MongoDB."
    writeLog "✅ Exportação completa em $(calculateExecutionTime)"
    echo ""
}

getSQLPP() {
    local table="$1"
    local SQL_SOURCE=""

    [ "$EXECUTION_MODE" == "update" ] && {
        SQL_WHERE="WHERE p.updated_at>'$LAST_IMPORTED_AT'"
    }

    SQL_SOURCE="COPY (
        SELECT row_to_json(row)
        FROM (SELECT p.cpf AS _id, p.*
            FROM $POSTGRES_DB_SCHEMA_FINAL.$table p $SQL_WHERE ORDER BY p.id
            OFFSET $LAST_OFFSET LIMIT $BATCH_SIZE
        ) row
    ) TO STDOUT;"

    echo "$SQL_SOURCE"
}

getSQLPF() {
    local DATE_NOW=$(date +'%Y-%m-%d %H:%M:%S.%3N') SQL_SOURCE=""
    local LAST_OFFSET="$1"

    [ "$EXECUTION_MODE" == "update" ] && {
        SQL_WHERE="WHERE p.updated_at>'$LAST_IMPORTED_AT'"
    }

    SQL_SOURCE="COPY (
        SELECT row_to_json(row)
        FROM (
            SELECT p.cpf AS _id, p.*, '$DATE_NOW' AS imported_at
            FROM $POSTGRES_DB_SCHEMA_FINAL.pf_pessoas p $SQL_WHERE ORDER BY p.id
            OFFSET $LAST_OFFSET LIMIT $BATCH_SIZE
        ) row
    ) TO STDOUT;"

    echo "$SQL_SOURCE"
}

copyPfFromPostgresPasteToMongo() {
    local COUNT_LOOP=0
    local LAST_OFFSET=0
    local LAST_IMPORTED_AT=""
    local BATCH_SIZE=$(echo "5.000.000" | tr -d '.' )
    local TOTAL_LINES_PF_POSTGRES=$(echo "10.000.000" | tr -d '.')
    local TOTAL_LOOP=$(( TOTAL_LINES_PF_POSTGRES / BATCH_SIZE ))
    local FILE_OFFSET="${DIR_CACHE}/${LOG_NAME}/last_offset_pf_pessoas"
    local SQL OUT

    LAST_OFFSET=$(cat "$FILE_OFFSET" 2>/dev/null || echo 0)
    while (( $COUNT_LOOP < $TOTAL_LOOP )); do
        for ((current_instance=1; current_instance<=NUM_INSTANCES; current_instance++)); do
            (( COUNT_LOOP += 1 ))
            local START_TIME=$(date +%s%3N)

            writeLog "🔄 "$COUNT_LOOP") Aguarde a replica do Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET)..."

            SQL="$(getSQLPF "$LAST_OFFSET")"
            echo "$SQL" > "$DIR_CACHE/${LOG_NAME}/LAST_SQL"

            # STREAM: psql → mongoimport (sem armazenar em variável)
            "${PSQL_CMD[@]}" -t -A -c "$SQL" | \
                "${MONGOIMPORT_CMD[@]}" \
                --collection "$TABLE_MAIN" \
                --mode upsert \
                --upsertFields _id \
                --type json > /dev/null 2>&1

            writeLog "✅ "$COUNT_LOOP") Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET) replicado com sucesso em $(calculateExecutionTime $START_TIME)"

            [ $LAST_OFFSET -gt $(cat "$FILE_OFFSET" 2>/dev/null || echo 0) ] && { echo "$(( $LAST_OFFSET + $BATCH_SIZE ))" > "$FILE_OFFSET"; }

            LAST_OFFSET=$(( LAST_OFFSET + BATCH_SIZE ))
        done
        wait
        echo ""
    done   
}

copyPpFromPostgresPasteToMongo() {
    local COUNT_LOOP=0
    local BATCH_SIZE=$(echo "200.000" | tr -d '.')
    local LAST_OFFSET=0
    local LAST_IMPORTED_AT=""

    for table in "${TABLES[@]}"; do
        LAST_OFFSET=$(cat "${DIR_CACHE}/${LOG_NAME}/last_offset_$table" 2>/dev/null || echo 0)

        # writeLog "🔄 "$COUNT_LOOP") Aguarde a recuperação da tabela '$table' com o Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET) para exportação e importação..."
    done

}

# -------------------- MAIN --------------------

checkStart

copyPfFromPostgresPasteToMongo

copyPpFromPostgresPasteToMongo

checkEnd
