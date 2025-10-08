#!/bin/bash
#
source "./config/config.sh"

LAST_OFFSET=0
LAST_IMPORTED_AT=0
LIMIT_OFFSET_TO_IMPORT=0
readonly DATE_NOW=$(date +'%Y-%m-%d %H:%M:%S.%3N')
readonly LOG_NAME="export_pf_from_postgres_to_mongodb"
readonly FILE_OFFSET="${LOG_NAME}_LAST_OFFSET"
readonly FILE_IMPORTED="${LOG_NAME}_LAST_IMPORTED_AT"
readonly EXECUTION_MODE="${1:-update}"
readonly BATCH_SIZE=1000
readonly NUM_INSTANCES=20
readonly TABLE_MAIN='pf_pessoas'

writeLog "$(repeat_char '=')"
writeLog "✅ Exportando dados PF do PostgreSQL → MongoDB"
echo ""

checkStart() {
    writeLog "🚀 Iniciando a replicação do postgreSQL para mongoDB no modo '$EXECUTION_MODE'..."

    # Checa se existe o índice da tabela TABLE_MAIN
    local exists_index=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT * FROM pg_indexes WHERE schemaname='$POSTGRES_DB_SCHEMA_FINAL' AND tablename='$TABLE_MAIN'")
    [ -z "$exists_index" ] && {
        writeLog "❌ A tabela '$TABLE_MAIN' não possui índice para executar a pesquisa!"
        exit 1
    }

    if [ $EXECUTION_MODE != 'update' ]; then 
        LAST_OFFSET=$(cat "$DIR_CACHE/$FILE_OFFSET" 2>/dev/null || echo 0);
    else
        LAST_IMPORTED_AT=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$TABLE_MAIN').findOne({}, { imported_at: 1, _id: 0 })?.imported_at" | sed 's/-[0-9]\{2\}:[0-9]\{2\}$//')
        LAST_IMPORTED_AT=${LAST_IMPORTED_AT:-1970-01-01}
        echo "$DATE_NOW" > "$DIR_CACHE/$FILE_IMPORTED"
        writeLog "🏁 Iniciando a replicação com dados MAIOR QUE '$LAST_IMPORTED_AT'"
    fi
    writeLog "🏁 OFFSET inicial da tabela '$TABLE_MAIN' : $(format_number $LAST_OFFSET)"

    LIMIT_OFFSET_TO_IMPORT=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT count(1) as total FROM $POSTGRES_DB_SCHEMA_FINAL.$TABLE_MAIN")
    writeLog "🏁 Limite do Último OFFSET de '$TABLE_MAIN' : $(format_number $LIMIT_OFFSET_TO_IMPORT)"
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    local total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$TABLE_MAIN.countDocuments()")
    writeLog "✅ $(format_number $total_mongo) documentos no mongoDB no total."
    writeLog "🏁 Exportação completa em $(calculateExecutionTime)"
    echo ""
}

getSQL() {
    local SQL_SOURCE="" SUBQUERIES="" SQL_WHERE=""

    [ $EXECUTION_MODE == 'update' ] && {
        SQL_WHERE="WHERE p.updated_at>'$LAST_IMPORTED_AT'"
    }

    SQL_SOURCE="COPY (
        SELECT row_to_json(row)
        FROM (
            SELECT p.cpf AS _id, p.*, '{DATE_NOW}' AS imported_at 
            {SUBQUERIES}
            FROM $POSTGRES_DB_SCHEMA_FINAL.$TABLE_MAIN p 
            {WHERE}
            ORDER BY p.id 
            OFFSET $LAST_OFFSET
            LIMIT $BATCH_SIZE
        ) row
    ) TO STDOUT;"

    for entry in "${TABLES[@]}"; do
        pg_table="${entry%%.*}"
        sub_name=$(echo "$entry" | cut -d '.' -f 2 | cut -d ' ' -f 1);
        [ "$pg_table" = "$TABLE_MAIN" ] && continue
        SUBQUERIES+=", COALESCE( (SELECT json_agg(row_to_json(t)) FROM ${POSTGRES_DB_SCHEMA_FINAL}.${pg_table} t WHERE t.cpf = p.cpf), '[]'::json) AS ${sub_name}"
    done

    SQL_SOURCE="${SQL_SOURCE//\{SUBQUERIES\}/$SUBQUERIES}"
    SQL_SOURCE="${SQL_SOURCE//\{WHERE\}/$SQL_WHERE}"
    SQL_SOURCE="${SQL_SOURCE//\{DATE_NOW\}/$DATE_NOW}"

    echo $SQL_SOURCE
}

copyPostgresToMongo() {
    local START_TIME=$(date +%s%3N)
    local SQL="" DATA="" SQL_SOURCE="" SUBQUERIES=""

    SQL="$(getSQL)"
    echo $SQL > "$DIR_CACHE/${LOG_NAME}_LAST_SQL"

    # DATA=$("${PSQL_CMD[@]}" -t -A -c "$SQL")
    # [ -z "$DATA" ] && {
    #     writeLog "❎ Fim dos dados em '$pg_table'."; 
    #     break;
    # }
    writeLog "🔎 Faixa $(format_number $LAST_OFFSET)/$(format_number $BATCH_SIZE) recuperada do PostgreSQL com sucesso em $(calculateExecutionTime $START_TIME)"

    # echo "$DATA" | "${MONGOIMPORT_CMD[@]}" --collection "$TABLE_MAIN" --mode upsert --upsertFields _id --type json > /dev/null 2>&1
    writeLog "✅ $(format_number $BATCH_SIZE) $(format_number $OFFSET) replicada para o MongoDB com sucesso em $(calculateExecutionTime $START_TIME)"

    # Salva o último OFFSET
    LAST_OFFSET=$(( $LAST_OFFSET + $BATCH_SIZE ))
    [ $LAST_OFFSET -gt $(cat "$DIR_CACHE/$FILE_OFFSET" 2>/dev/null || echo 0) ] && echo "$(( $LAST_OFFSET + $BATCH_SIZE ))" > "$DIR_CACHE/$FILE_OFFSET"
}

checkStart

while true; do
    continue_loop=true
    for ((current_instance=1; current_instance<=NUM_INSTANCES; current_instance++)); do
        [ $LAST_OFFSET -ge $LIMIT_OFFSET_TO_IMPORT ] && {
            continue_loop=false; 
            break;
        }
        copyPostgresToMongo
    done
    wait
    [ $continue_loop == false ] && { writeLog "🏁 Loop interrompido"; break; }
    echo ""
done

checkEnd