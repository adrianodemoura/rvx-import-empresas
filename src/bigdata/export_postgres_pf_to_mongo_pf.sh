#!/bin/bash
#
source "./config/config.sh"

LOG_NAME="export_pf_from_postgres_to_mongodb"
LAST_ID=0
LAST_ID_TO_IMPORT=0
readonly EXECUTION_MODE="${1:-update}"
readonly FILE_ID="${LOG_NAME}_LAST_ID"
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

    LAST_ID=$(cat "$DIR_CACHE/$FILE_ID" 2>/dev/null || echo 0)
    writeLog "🏁 Último ID importado da tabela '$TABLE_MAIN' : $(format_number $LAST_ID)"

    LAST_ID_TO_IMPORT=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT id FROM $POSTGRES_DB_SCHEMA_FINAL.$TABLE_MAIN ORDER BY id DESC LIMIT 1")
    writeLog "🏁 Limite do Último ID da tabela '$TABLE_MAIN' : $(format_number $LAST_ID_TO_IMPORT)"
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    local total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$TABLE_MAIN.countDocuments()")
    writeLog "✅ $(format_number $total_mongo) documentos no mongoDB no total."
    writeLog "🏁 Exportação completa em $(calculateExecutionTime)"
    echo ""
}

getSQL() {
    local SQL_SOURCE SUBQUERIES

    SQL_SOURCE="COPY (
        SELECT row_to_json(row)
        FROM (
            SELECT p.cpf AS _id, p.*, now() AS imported_at 
            {SUBQUERIES}
            FROM $POSTGRES_DB_SCHEMA.$TABLE_MAIN p WHERE p.id > $LAST_ID ORDER BY p.id LIMIT $BATCH_SIZE
        ) row
    ) TO STDOUT;"

    # for entry in "${TABLES[@]}"; do
    #     pg_table="${entry%%.*}"
    #     sub_name="${entry#*.}"
    #     [ "$pg_table" = "$TABLE_MAIN" ] && continue
    #     SUBQUERIES+=", COALESCE( (SELECT json_agg(row_to_json(t)) FROM ${POSTGRES_DB_SCHEMA}.${pg_table} t WHERE t.cpf = p.cpf), '[]'::json) AS ${sub_name}"
    # done

    SQL_SOURCE="${SQL_SOURCE//\{SUBQUERIES\}/$SUBQUERIES}"

    echo $SQL_SOURCE
}

copyPostgresToMongo() {
    local START_TIME=$(date +%s%3N)
    local SQL="" DATA="" SQL_SOURCE="" SUBQUERIES=""

    SQL="$(getSQL)"
    # SQL="${SQL_SOURCE//\{BATCH_SIZE\}/$BATCH_SIZE}"
    # echo $SQL > "$DIR_CACHE/sql_${pg_table}_${OFFSET}_${BATCH_SIZE}"
    echo $SQL

    # DATA=$("${PSQL_CMD[@]}" -t -A -c "$SQL")
    # [ -z "$DATA" ] && {
    #     writeLog "❎ Fim dos dados em '$pg_table'."; 
    #     break;
    # }
    # writeLog "🔎 Faixa $(format_number $OFFSET)/$(format_number $BATCH_SIZE) recuperada do PostgreSQL com sucesso em $(calculateExecutionTime $START_TIME)"

    # echo "$DATA" | "${MONGOIMPORT_CMD[@]}" --collection "$TABLE_MAIN" --mode upsert --upsertFields _id --type json > /dev/null 2>&1
    # writeLog "✅ $(format_number $BATCH_SIZE) $(format_number $OFFSET) replicada para o MongoDB com sucesso em $(calculateExecutionTime $START_TIME)"

    # Atualiza o maior ID salvo
    LAST_ID=$(( $LAST_ID + $BATCH_SIZE ))
    [ $LAST_ID -gt $(cat "$DIR_CACHE/$FILE_ID" 2>/dev/null || echo 0) ] && echo "$(( $LAST_ID + $BATCH_SIZE ))" > "$DIR_CACHE/$FILE_ID"
}

checkStart

while true; do
    continue_loop=true
    for ((current_instance=1; current_instance<=NUM_INSTANCES; current_instance++)); do
        [ $LAST_ID -ge $LAST_ID_TO_IMPORT ] && { continue_loop=false; break; }
        copyPostgresToMongo
    done
    wait
    [ $continue_loop == false ] && { writeLog "🏁 Loop interrompido"; break; }
    echo ""
done

checkEnd