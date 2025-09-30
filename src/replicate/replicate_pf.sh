#!/bin/bash
source "./config/config.sh"
LOG_NAME='replicate'
mkdir -p "$DIR_CACHE/replicate"

readonly BATCH_SIZE=10000
readonly MAX_ROWS=100000
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
writeLog "✅ Iniciando replicação de '$POSTGRES_DB_HOST.$POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' para '$MONGODB_HOST.$MONGODB_DATABASE'..."
echo

replicateWithSubcollections() {
    local loop=1
    local table=""
    local nick=""
    local offset=0

    writeLog "🔄 Replicando tabela principal '$table_main' com subcollections ..."

    echo
    writeLog "🔎 Iniciando a replicação de pessoas..."
    while true; do
        SQL="SELECT p1.cpf AS _id, p1.*, now() AS imported_at" 
        for item in "${tables[@]}"; do
            table=${item%%.*}
            nick=${item#*.}
            SQL+=", COALESCE( (SELECT json_agg($nick.*) FROM $POSTGRES_DB_SCHEMA_FINAL.$table $nick WHERE $nick.cpf = p1.cpf), '[]') AS $nick"
        done
        SQL+=" FROM $POSTGRES_DB_SCHEMA_FINAL.$table_main p1 ORDER BY p1.cpf LIMIT $BATCH_SIZE OFFSET $offset"
        SQL="SELECT row_to_json(t) FROM ( $SQL ) t;"

        OUT=$("${PROD_PSQL_CMD[@]}" -t -A -F "" -c "$SQL")
        if [[ -z "$OUT" ]]; then
            writeLog "⚠️ Nenhum dado retornado no lote OFFSET $offset/$BATCH_SIZE e no loop $loop!"
            break
        fi

        # Envia para o MongoDB
        echo "$OUT" | "${MONGOIMPORT_CMD[@]}" --collection "$table_main" --mode upsert --upsertFields _id --type json > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao importar lote OFFSET $offset. Abortando..."
            exit 1
        fi

        ((offset += BATCH_SIZE))
        writeLog "📦 $(printf "%09d" "$loop") - Lote $(format_number $offset)/$(format_number $BATCH_SIZE) processado com sucesso em $(calculateExecutionTime)"

        [[ $offset -ge $MAX_ROWS ]] && break
        ((loop++))
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
writeLog "✅ Limpando o banco de dados '$MONGODB_DATABASE' do MongoDB."

replicateWithSubcollections

writeLog "$(repeat_char '-')"
writeLog "🏁 Replicação concluída com sucesso! em $(calculateExecutionTime)"
