#!/bin/bash
#
source "./config/config.sh"

POSTGRES_DB_SCHEMA_FINAL='bigdata_tmp'

COUNT_LOOP=0
LAST_OFFSET=0
LAST_IMPORTED_AT=0

readonly LOG_NAME="export_pf_from_postgres_to_mongodb"
readonly FILE_OFFSET="${DIR_CACHE}/${LOG_NAME}/LAST_OFFSET"
readonly FILE_IMPORTED="${DIR_CACHE}/${LOG_NAME}/LAST_IMPORTED_AT"
readonly FILE_HAS_END="${DIR_CACHE}/${LOG_NAME}/HAS_END"
readonly EXECUTION_MODE="${1:-update}"
readonly BATCH_SIZE=$(echo "1.000.000" | tr -d '.' )
readonly NUM_INSTANCES=10
readonly TABLE_MAIN='pf_pessoas'

writeLog "$(repeat_char '=')"
writeLog "✅ Exportando dados PF do PostgreSQL → MongoDB"
echo ""

checkStart() {
    writeLog "🚀 Iniciando replicação do PostgreSQL para MongoDB, com lotes de '$(format_number $BATCH_SIZE)' linhas, no modo '$EXECUTION_MODE'..."
    mkdir -p "$DIR_CACHE/${LOG_NAME}"
    rm -rf "$FILE_HAS_END"

    # Checa se existe o índice da tabela TABLE_MAIN
    local exists_index=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT * FROM pg_indexes WHERE schemaname='$POSTGRES_DB_SCHEMA_FINAL' AND tablename='$TABLE_MAIN'")
    [ -z "$exists_index" ] && {
        writeLog "❌ A tabela '$TABLE_MAIN' não possui índice para executar a pesquisa!"
        exit 1
    }

    # Checando o último offset
    if [ "$EXECUTION_MODE" != "update" ]; then 
        LAST_OFFSET=$(cat "$FILE_OFFSET" 2>/dev/null || echo 0)
        echo $LAST_OFFSET
    else
        LAST_IMPORTED_AT=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$TABLE_MAIN').findOne({}, { imported_at: 1, _id: 0 })?.imported_at" | sed 's/-[0-9]\{2\}:[0-9]\{2\}$//')
        LAST_IMPORTED_AT=${LAST_IMPORTED_AT:-1970-01-01}
        echo "$LAST_IMPORTED_AT" > "$FILE_IMPORTED"
        writeLog "🏁 Iniciando replicação com dados MAIOR QUE '$LAST_IMPORTED_AT'"
    fi
    writeLog "🏁 Offset final de '$TABLE_MAIN': $(format_number $LAST_OFFSET)"
    echo ""
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    writeLog "🔎 Aguarde a contagem de documentos no MongoDB..."
    local total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$TABLE_MAIN.estimatedDocumentCount()")
    writeLog "✅ Estimasse $(format_number $total_mongo) documentos no total do MongoDB."
    writeLog "✅ Exportação completa em $(calculateExecutionTime)"
    echo ""
}

getSQL() {
    local SQL_SOURCE="" SUBQUERIES SQL_WHERE
    local DATE_NOW=$(date +'%Y-%m-%d %H:%M:%S.%3N')

    [ "$EXECUTION_MODE" == "update" ] && {
        SQL_WHERE="WHERE p.updated_at>'$LAST_IMPORTED_AT'"
    }

    # Monta os subselects das tabelas relacionadas
    for entry in "${TABLES[@]}"; do
        pg_table="${entry%%.*}"
        sub_name=$(echo "$entry" | cut -d '.' -f 2 | cut -d ' ' -f 1)
        [ "$pg_table" = "$TABLE_MAIN" ] && continue
        SUBQUERIES+=", COALESCE((SELECT json_agg(row_to_json(t)) FROM ${POSTGRES_DB_SCHEMA_FINAL}.${pg_table} t WHERE t.cpf = p.cpf), '[]'::json) AS ${sub_name}"
    done

    SQL_SOURCE="COPY (
        SELECT row_to_json(row)
        FROM (
            SELECT p.cpf AS _id, p.*, '$DATE_NOW' AS imported_at
            $SUBQUERIES
            FROM $POSTGRES_DB_SCHEMA_FINAL.$TABLE_MAIN p $SQL_WHERE ORDER BY p.id
            OFFSET $LAST_OFFSET
            LIMIT $BATCH_SIZE
        ) row
    ) TO STDOUT;"

    echo "$SQL_SOURCE"
}

copyFromPostgresPasteToMongo() {
    local START_TIME=$(date +%s%3N)
    local SQL="$(getSQL)"
    echo "$SQL" > "$DIR_CACHE/${LOG_NAME}/LAST_SQL"

    writeLog "🔄 "$COUNT_LOOP") Aguarde a recuperação do Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET) para exportação e importação..."
    # STREAM: psql → mongoimport (sem armazenar em variável)
    "${PSQL_CMD[@]}" -t -A -c "$SQL" | \
        (read -r line && { echo "$line"; cat; } | \
        "${MONGOIMPORT_CMD[@]}" --collection "$TABLE_MAIN" --mode upsert --upsertFields _id --type json > /dev/null 2>&1) || {
            echo "1" > "$FILE_HAS_END";
            writeLog "📣 "$COUNT_LOOP") O Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET) retornou vazio!";
            return;
        }
    if [ $? -ne 0 ]; then
        writeLog "🛑 Erro ao importar o Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET)!"
        exit 1
    fi

    [ $LAST_OFFSET -gt $(cat "$FILE_OFFSET" 2>/dev/null || echo 0) ] && {
        echo "$(( $LAST_OFFSET + $BATCH_SIZE ))" > "$FILE_OFFSET";
        echo "$SQL" > "${DIR_CACHE}/${LOG_NAME}_LAST_SQL"
    }
    writeLog "✅ "$COUNT_LOOP") Lote $(format_number $BATCH_SIZE)/$(format_number $LAST_OFFSET) replicado com sucesso em $(calculateExecutionTime $START_TIME)"
}

# -------------------- MAIN --------------------

checkStart

while true; do
    continue_loop=true
    for ((current_instance=1; current_instance<=NUM_INSTANCES; current_instance++)); do
        [ -f "$FILE_HAS_END" ] && {
            continue_loop=false
            break
        }
        (( COUNT_LOOP += 1 ))
        copyFromPostgresPasteToMongo
        LAST_OFFSET=$(( LAST_OFFSET + BATCH_SIZE ))
    done
    wait
    [ "$continue_loop" == false ] && {
        writeLog "✅ "$COUNT_LOOP") Loop chegou ao final."
        break
    }
    echo ""
done

checkEnd
