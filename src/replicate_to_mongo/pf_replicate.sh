#!/bin/bash
# Inicia os banco postgre, redis e mongoDB
source "./config/config.sh"
LOG_NAME='replicate'

mkdir -p "$DIR_CACHE/replicate"

readonly tables=(pf_pessoas pf_emails pf_telefones pf_enderecos)
readonly DATE_UPDATED="2025-09-26 18:17:35.975"

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando a exportação de tabelas DE \"$DB_SCHEMA_FINAL\" para MongoDB..."

carregarSQL() {
    local SQL=$1
    local LAST_ID=$2
    local LIMIT=$3

    if [[ -z "$1" ]]; then
        writeLog "❌ Erro: O parâmetro Schema é obrigatório!" "$LOG_NAME_ERROR"
        exit 1
    fi

    SQL="${SQL//\$DB_SCHEMA_FINAL/$DB_SCHEMA_FINAL}"
    SQL="${SQL//\$DB_SCHEMA_TMP/$DB_SCHEMA_TMP}"
    SQL="${SQL//\$DB_SCHEMA/$DB_SCHEMA}"
    SQL="${SQL//\$DATA_ORIGEM/$DATA_ORIGEM}"
    SQL="${SQL//\$ORIGEM/$ORIGEM}"
    SQL="${SQL//\$LIMIT/$LIMIT}"
    SQL="${SQL//\$LAST_ID/$LAST_ID}"

    echo "$SQL"
}

exportPostgreToMongo() {
    local SQL SQL_MONGO OFFSET START_TIME_IMPORT IMPORTED DATE_UPDATE
    # local MAX_RECORDS=$(echo "1.000.000.000" | tr -d '.') LIMIT=$(echo "1.000.000" | tr -d '.')
    local MAX_RECORDS=$(echo "1.000" | tr -d '.') LIMIT=$(echo "100" | tr -d '.')

    writeLog "🔍 Iniciando a exportação ..."
    for table in "${tables[@]}"; do
        OFFSET=0
        IMPORTED=0

        while (( IMPORTED < MAX_RECORDS )); do
            writeLog "🔍 Exportando $(format_number $LIMIT) linhas de '$POSTGRES_DB_SCHEMA_FINAL.$table' para 'Mongo'..."
            START_TIME_IMPORT=$(date +%s%3N)
            DATE_UPDATE="2025-09-26 20:18:07.456"

            SQL="SELECT * FROM $table WHERE $table.updated_at>\"$DATE_UPDATE\" LIMIT $LIMIT OFFSET $OFFSET"
            SQL=$(carregarSQL "$SQL" "$OFFSET" "$LIMIT")
            writeLog "🛑 executar... $SQL"
            
            # OUTPUT=$("${PSQL_CMD[@]}" -t -A -F"" -c "$SQL" \
            #     | "${MONGO_CMD[@]}" --eval "$SQL_MONGO" \
            #     2>&1)
            # if [[ $? -ne 0 ]]; then
            #     writeLog "❌ Erro ao alterar '$DB_SCHEMA_FINAL.$table' para '$DB_SCHEMA_OLD.$table': $(echo "$OUTPUT" | tr -d '\n')"
            # fi

            OFFSET=$((OFFSET + LIMIT))
            IMPORTED=$((IMPORTED + LIMIT))

            writeLog "📥 $(format_number $LIMIT) linhas exportadas com sucesso em $(calculateExecutionTime $START_TIME_IMPORT)"
        done
        echo
    done

    # Executa a SQL de importação
    # OUTPUT=$("${PSQL_CMD[@]}" -t -A -F"" -c "$SQL" 2>&1)
    # if [[ $? -ne 0 ]]; then
    #   writeLog "❌ Erro ao popular \"$DB_SCHEMA.$TABLE_IMPORT\": $(echo "$OUTPUT" | tr -d '\n')"
    #   exit 1
    # fi
    # psql "$PG_CONN" -t -A -F"" -c "SELECT json_build_object(...) FROM pf_pessoa ..." \
    #     | mongo "$MONGO_URI" --eval 'while(getline(doc)){db.pf_pessoas.updateOne({_id: doc.cpf}, {$set: doc}, {upsert:true})}'
}

exportPostgreToMongo

# FIM
writeLog "$(repeat_char '-')"
writeLog "✅ Importação de tabelas para o Schema '$POSTGRES_DB_SCHEMA_FINAL' finalizada em $(calculateExecutionTime)"
echo