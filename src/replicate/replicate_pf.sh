#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'

LAST_ID_TO_IMPORT=0
LAST_UPDATED_AT=0
LAST_SAVED_ID=0
readonly SALT_ID_TO_IMPORT=10000
readonly NUM_INSTANCES=10
readonly table_main='pf_pessoas'
readonly tables=(
    pf_banco_gov.banco_gov
    pf_bolsa_familia.bolsa_familia
    pf_capacidade_pagamento.capacidade_pagamento
    pf_carteira_trabalho.carteira_trabalho
    pf_cbo.cbo
    pf_classe_social.classe_social
    pf_emails.emails
    pf_enderecos.enderecos
    pf_escolaridade.escolaridade
    pf_fgts.fgts
    pf_governos.governos
    pf_imoveis_ibge.imoveis_ibge
    pf_modelo_analitico_credito.modelo_analitico_credito
    pf_nacionalidade.nacionalidade
    pf_obitos.obitos
    pf_persona_demografica.persona_demografica
    pf_pis.pis
    pf_poder_aquisitivo.poder_aquisitivo
    pf_politicamente_exposta.politicamente_exposta
    pf_propensao_pagamento.propensao_pagamento
    pf_renda.renda
    pf_score.score
    pf_score_digital.score_digital
    pf_situacao_receita.situacao_receita
    pf_telefones.telefones
    pf_titulo_eleitor.titulo_eleitor
    pf_triagem_risco.triagem_risco
    pf_veiculos.veiculos
    pf_vinculo_empregaticio.vinculo_empregaticio
    pf_vinculos_familiares.vinculos_familiares
)

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando replicação de '$POSTGRES_DB_HOST.$POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' (postgres) para '$MONGODB_HOST.$MONGODB_DATABASE' (mongoDB)..."
echo ""

clearDatabaseMongo() {
    local OUTPUT=$("${MONGO_CMD[@]}" --quiet --eval "db.dropDatabase()")
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao tentar excluir a database $MONGO_DATABASE"
        exit 1
    fi
    wait
    writeLog "✅ Banco de dados '$MONGODB_DATABASE' do MongoDB, limpo com sucesso."
}

checkStart() {
    # Descobrindo o último ID no postgres
    # LAST_ID_TO_IMPORT=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT id FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main ORDER BY id DESC LIMIT 1")
    LAST_ID_TO_IMPORT=1000
    writeLog "🏁 Último ID de '$table_main': $(format_number $LAST_ID_TO_IMPORT)"

    # recuperando o último ID SALVO
    LAST_SAVED_ID=$(( (x=$(cat "$DIR_CACHE/replicate_last_saved_id" 2>/dev/null || echo "0")) > 0 ? x : LAST_SAVED_ID ))
    # LAST_SAVED_ID=$("${MONGO_CMD[@]}" --quiet --eval 'db.pf_pessoas.find().sort({id: -1}).limit(1).toArray()[0].id')
    # LAST_SAVED_ID=$(echo "954" | tr -d '.')
    writeLog "🏁 Último ID já salvo: $(format_number $LAST_SAVED_ID)"
    if [[ $LAST_SAVED_ID -eq 0 ]]; then # Se não tem ULTIMO ID para salvar, então vai pela atualização.
        local OUT=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$table_main').findOne({}, { updated_at: 1, _id: 0 })?.updated_at")
        LAST_UPDATED_AT=${OUT:-0}
        writeLog "🔄 Iniciando a replicação com dados MAIOR QUE '$LAST_UPDATED_AT'"
    fi

    echo ""
}

checkEnd() {
    local total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$table_main.countDocuments()")
    writeLog "✅ $(format_number $total_mongo) documentos no mongoDB no total."
    writeLog "$(repeat_char '-')"
    writeLog "🏁 Replicação concluída com sucesso! em $(calculateExecutionTime)"
}

replicateWithSubcollections() {
    local SQL OUT START_TIME_REPLICATE=$(date +%s%3N)
    local start_id=$1 end_id=$2 table="" nick="" offset=0
    local dif_ids=$(( $end_id - $start_id +1 ))

    [[ -z "$1" || -z "$2" ]] && { writeLog "❌ Erro: Os IDs inicial e final são obrigatórios!"; exit 1; }

    # Montando a SQL que vai buscar pf_pessoas no postgres
    SQL="SELECT p1.cpf AS _id, p1.*, now() AS imported_at" 
    for item in "${tables[@]}"; do
        table=${item%%.*}
        nick=${item#*.}
        SQL+=", COALESCE( (SELECT json_agg($nick.*) FROM $POSTGRES_DB_SCHEMA_FINAL.$table $nick WHERE $nick.cpf = p1.cpf), '[]') AS $nick"
    done
    SQL+=" FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main p1"
    SQL+=" WHERE p1.id >= $start_id AND p1.id <= $end_id"
    [[ "$LAST_UPDATED_AT" > 0 && LAST_SAVED_ID == 0 ]] && SQL+=" AND p1.updated_at > '$LAST_UPDATED_AT'"
    SQL+=" ORDER BY p1.id"

    # Configurando para retornar JSON
    SQL="SELECT row_to_json(t) FROM ( $SQL ) t;"
    echo "$SQL" > "$DIR_CACHE/replicate_last_sql"

    writeLog "🔎 Aguarde a BUSCA da faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas no postgreSQL remoto..."
    OUT=$("${PSQL_CMD[@]}" -t -A -F "" -c "$SQL")
    if [[ -z "$OUT" ]]; then
        writeLog "📦 Nenhum dado retornado na faixa $start_id/$end_id"
    else
        writeLog "🔎 Aguarde a INSERÇÃO/ATUALIZAÇÃO da faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas no mongoDB"
        echo "$OUT" | "${MONGOIMPORT_CMD[@]}" --collection "$table_main" --mode upsert --upsertFields _id --type json > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao importar lote OFFSET $offset. Abortando..."
            exit 1
        fi

        # salva o maior ID replicado no mongoDB
        [ $end_id -gt $(cat "$DIR_CACHE/replicate_last_saved_id" 2>/dev/null || echo 0) ] && echo "$end_id" > "$DIR_CACHE/replicate_last_saved_id"

        writeLog "📦 Faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas replicadas com sucesso em $(calculateExecutionTime $START_TIME_REPLICATE)"
    fi
}

# clearDatabaseMongo

checkStart

writeLog "🏁 Iniciando a replicação de $(format_number $TOTAL_RECORDS_TO_IMPORT) registros do postgres..."

for ((current_id=LAST_SAVED_ID; current_id<=LAST_ID_TO_IMPORT; current_id+=SALT_ID_TO_IMPORT)); do
    BATCH_SIZE=$(( SALT_ID_TO_IMPORT / NUM_INSTANCES ))

    for ((current_instance=1; current_instance<=NUM_INSTANCES; current_instance++)); do

        # Calculando início e fim da faixa.
        start_id=$(($current_id + ($BATCH_SIZE * $current_instance) - $BATCH_SIZE +1 ))
        end_id=$(($BATCH_SIZE + $start_id -1 ))

        # Verificações para a faixa
        [ $end_id -gt $LAST_ID_TO_IMPORT ] && { end_id=$LAST_ID_TO_IMPORT; }
        [ $start_id -gt $LAST_ID_TO_IMPORT ] && { continue; }
        [ $end_id -gt $(cat "$DIR_CACHE/replicate_last_saved_id" 2>/dev/null || echo 0) ] && echo "$end_id" > "$DIR_CACHE/replicate_last_saved_id"

        # writeLog "$current_id) sub-loop: $current_instance start_id: $start_id end_id: $end_id"
        replicateWithSubcollections $start_id $end_id &
    done
    wait
    echo
done

checkEnd
