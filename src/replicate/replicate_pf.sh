#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'

LAST_ID_TO_IMPORT=0
TOTAL_REPLICATED=0
LAST_UPDATED_AT=0
LAST_SAVED_ID=0
readonly NUM_INSTANCES=10
readonly NUM_MAX_PER_TRACK=$(echo "10.000" | tr -d '.')
readonly table_main='pf_pessoas'
# readonly tables=(pf_emails.emails pf_telefones.telefones)
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
writeLog "✅ Iniciando replicação de '$POSTGRES_DB_HOST.$POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' para '$MONGODB_HOST.$MONGODB_DATABASE'..."
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
    local OUT
    # Recuperando a atualização do primeiro documento
    OUT=$("${MONGO_CMD[@]}" --quiet --eval "db.getCollection('$table_main').findOne({}, { updated_at: 1, _id: 0 })?.updated_at")
    LAST_UPDATED_AT=${OUT:-0}
    writeLog "🔄 Iniciando a replicação com dados MAIOR QUE '$LAST_UPDATED_AT'"

    # recuperando o último ID
    LAST_SAVED_ID=$(( (x=$(cat "$DIR_CACHE/replicate_last_saved_id" 2>/dev/null || echo "0")) > 0 ? x : 1 ))
    writeLog "🔎 Último ID já importado: $(format_number $LAST_SAVED_ID)"

    # Descobrindo o último ID no postgres
    LAST_ID_TO_IMPORT=$("${PSQL_CMD[@]}" -t -A -F "" -c "SELECT id FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main ORDER BY id DESC LIMIT 1")
    # LAST_ID_TO_IMPORT=$(echo "250.000" | tr -d '.')
    # LAST_ID_TO_IMPORT=$(echo "20.000" | tr -d '.')
    # LAST_ID_TO_IMPORT=$(echo "33" | tr -d '.')

    writeLog "✅ Último ID de '$table_main': $(format_number $LAST_ID_TO_IMPORT)"
    echo ""
}

checkEnd() {
    local totalReplicated
    if [[ -e "/tmp/total_replicated" ]]; then
        totalReplicated=$(cat "/tmp/total_replicated")
    fi

    if [[ $totalReplicated -gt 0 ]]; then
        $("${MONGO_CMD[@]}" --quiet --eval "db.$table_main.createIndex({ updated_at: 1 }, { sparse: true })" > /dev/null)
        writeLog "✅ Index 'updated_at' atualizado com sucesso."

        local total_replicated=$("${MONGO_CMD[@]}" --quiet --eval "db.$table_main.countDocuments()")
        writeLog "✅ Tabela '$table_main' replicada com $total_replicated documentos com sucesso no MongoDB em $(calculateExecutionTime)"
    fi
    writeLog "$(repeat_char '-')"
    writeLog "🏁 Replicação concluída com sucesso! em $(calculateExecutionTime)"
}

replicateWithSubcollections() {
    local SQL OUT START_TIME_REPLICATE=$(date +%s%3N)
    local start_id=$1 end_id=$2
    local table="" nick="" offset=0 last_updated_at=$(date +"%Y-%m-%dT%H:%M:%S.%3N")
    local dif_ids=$(( $end_id - $start_id +1 ))

    [[ -z "$1" || -z "$2" ]] && { writeLog "❌ Erro: Os IDs inicial e final são obrigatórios!"; exit 1; }

    SQL="SELECT p1.cpf AS _id, p1.*, now() AS imported_at" 
    for item in "${tables[@]}"; do
        table=${item%%.*}
        nick=${item#*.}
        SQL+=", COALESCE( (SELECT json_agg($nick.*) FROM $POSTGRES_DB_SCHEMA_FINAL.$table $nick WHERE $nick.cpf = p1.cpf), '[]') AS $nick"
    done
    SQL+=" FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main p1"
    SQL+=" WHERE p1.id >= $start_id AND p1.id <= $end_id"
    SQL+=" ORDER BY p1.id"
    [[ "$LAST_UPDATED_AT" > 0 ]] && SQL+=" AND p1.updated_at > '$LAST_UPDATED_AT'"
    SQL="SELECT row_to_json(t) FROM ( $SQL ) t;"
    echo $SQL > "$DIR_CACHE/replicate_last_sql"

    writeLog "🔎 Aguarde a BUSCA da faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas no postgreSQL remoto..."
    OUT=$("${PROD_PSQL_CMD[@]}" -t -A -F "" -c "$SQL")
    if [[ -z "$OUT" ]]; then
        writeLog "📦 Nenhum dado retornado na faixa $start_id/$end_id"
    else
        writeLog "🔎 Aguarde a INSERÇÃO da faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas no mongoDB"
        echo "$OUT" | "${MONGOIMPORT_CMD[@]}" --collection "$table_main" --mode upsert --upsertFields _id --type json > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao importar lote OFFSET $offset. Abortando..."
            exit 1
        fi
        ((TOTAL_REPLICATED+=$dif_ids))
        echo "$TOTAL_REPLICATED" > "/tmp/replicate_total"
        [ $end_id -gt $(cat "$DIR_CACHE/replicate_last_saved_id" 2>/dev/null || echo 0) ] && echo "$end_id" > "$DIR_CACHE/replicate_last_saved_id"

        writeLog "📦 Faixa $(format_number $start_id)/$(format_number $end_id) com $(format_number $dif_ids) linhas replicadas com sucesso em $(calculateExecutionTime $START_TIME_REPLICATE)"
    fi
}

clearDatabaseMongo

checkStart

MAX_LOOP_PROCESSES=$(( $((LAST_ID_TO_IMPORT / NUM_MAX_PER_TRACK)) +1))
for (( a=1; a<=$MAX_LOOP_PROCESSES; a++ )); do
    chunk_size=$((NUM_MAX_PER_TRACK * a))
    start_loop=$(( (a-1) * NUM_MAX_PER_TRACK + 1 ))
    end_loop=$(( a * NUM_MAX_PER_TRACK ))
    [ $a -eq $MAX_LOOP_PROCESSES ] && end_loop=$LAST_ID_TO_IMPORT

    skip_loop_a=false
    for ((i=0; i<NUM_INSTANCES; i++)); do
        start_id=$(( start_loop + (i * (end_loop - start_loop + 1) / NUM_INSTANCES) ))
        end_id=$(( start_loop + ((i + 1) * (end_loop - start_loop + 1) / NUM_INSTANCES) - 1 ))

        [ $end_id -lt $LAST_SAVED_ID ] && { skip_loop_a=true; continue; }

        if [[ $LAST_SAVED_ID -ge $start_id && $LAST_SAVED_ID -le $end_id ]]; then
            start_id=$((LAST_SAVED_ID + 1))
        fi

        [ $i -eq $((NUM_INSTANCES - 1)) ] && end_id=$end_loop

        # writeLog "loop: $a - sub-loop: $i start_id: $start_id end_id: $end_id"
        replicateWithSubcollections $start_id $end_id &
    done
    wait
    [ "$skip_loop_a" = true ] &&  { continue; }
    writeLog "📦 ID até $(format_number $end_id) processado com sucesso em $(calculateExecutionTime)."
    echo ""
done

checkEnd
