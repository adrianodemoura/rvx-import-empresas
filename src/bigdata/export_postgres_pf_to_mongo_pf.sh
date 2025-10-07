#!/bin/bash
#
source "./config/config.sh"

LOG_NAME="export_pf_from_postgres_to_mongodb"
readonly TABLE_MAIN='pf_pessoas'
readonly TABLES=(
    pf_pessoas.pf_pessoas 
    pf_escolaridade.escolaridade
    pf_score.score
    pf_banco_gov.banco_gov
    pf_bolsa_familia.bolsa_familia
    pf_capacidade_pagamento.capacidade_pagamento
    pf_carteira_trabalho.carteira_trabalho
    pf_cbo.cbo
    pf_classe_social.classe_social
    pf_emails.emails
    pf_enderecos.enderecos
    pf_fgts.fgts
    pf_governos.governos
    pf_imoveis_ibge.imoveis_ibge
    pf_modelo_analitico_credito.modelo_analitico_credito
    pf_nacionalidade.nacionalidade
    pf_obitos.obitos
    pf_persona_demografica.persona_demografica
    pf_propensao_pagamento.propensao_pagamento
    pf_renda.renda
    pf_pis.pis
    pf_poder_aquisitivo.poder_aquisitivo
    pf_politicamente_exposta.politicamente_exposta
    pf_score_digital.score_digital
    pf_situacao_receita.situacao_receita
    pf_telefones.telefones
    pf_titulo_eleitor.titulo_eleitor
    pf_triagem_risco.triagem_risco
    pf_veiculos.veiculos
    pf_vinculo_empregaticio.vinculo_empregaticio
    pf_vinculos_familiares.vinculos_familiares
)
BATCH_MAX=1000
BATCH_SIZE=100
OFFSET=0

writeLog "$(repeat_char '=')"
writeLog "✅ Exportando dados PF do PostgreSQL → MongoDB"
echo ""

copyTable() {
    local entry="$1"
    local pg_table="${entry%%.*}"   # tabela real no Postgres
    local sub_name="${entry#*.}"    # nome da subcollection no Mongo
    local START_TIME=$(date +%s%3N)
    local DATA SQL

    if [ "$pg_table" == "$TABLE_MAIN" ]; then
        SQL="COPY (
                SELECT row_to_json(row) 
                FROM (SELECT p.cpf AS _id, p.*, now() AS imported_at FROM $POSTGRES_DB_SCHEMA.$pg_table p ORDER BY p.id LIMIT $BATCH_SIZE OFFSET $OFFSET) row
            ) TO STDOUT;"

        DATA=$("${PSQL_CMD[@]}" -t -A -c "$SQL")
        [ -z "$DATA" ] && {
            writeLog "❌ A busca em '$pg_table' não retornou nenhuma linha!"
            return 1;
        }

        echo "$DATA" | "${MONGOIMPORT_CMD[@]}" --collection "$TABLE_MAIN" \
            --mode upsert --upsertFields _id --type json > /dev/null 2>&1

    else
        # 👉 Sub-collections com todos os campos t.*
        SQL="COPY (
                SELECT json_build_object('_id', t.cpf, '$sub_name', json_agg(row_to_json(t)))
                FROM (SELECT t.* FROM $POSTGRES_DB_SCHEMA.$pg_table t ORDER BY t.id LIMIT $BATCH_SIZE OFFSET $OFFSET) t
                GROUP BY t.cpf
            ) TO STDOUT;"

        DATA=$("${PSQL_CMD[@]}" -t -A -c "$SQL")
        [ -z "$DATA" ] && { 
            writeLog "❌ A busca em '$pg_table' não retornou nenhuma linha!"
            return 1;
        }

        echo "$DATA" | "${MONGOIMPORT_CMD[@]}" --collection "$TABLE_MAIN" \
            --mode merge --upsertFields _id --type json > /dev/null 2>&1
    fi
    # echo "$SQL" > "$DIR_CACHE/export_last_sql"
    # echo "$DATA" > "$DIR_CACHE/export_last_data"

    local COUNT=$(echo "$DATA" | wc -l)
    writeLog "✅ $(format_number $COUNT) registros processados da tabela '$pg_table' (→ $sub_name) em $(calculateExecutionTime $START_TIME)"
    return 0
}

for table in "${TABLES[@]}"; do
    writeLog "📦 Copiando '$table'..."
    OFFSET=0
    while true; do
        copyTable "$table"
        [ $? -ne 0 ] && break

        OFFSET=$((OFFSET + BATCH_SIZE))

        [ $OFFSET -ge $BATCH_MAX ] && break
    done
done

writeLog "$(repeat_char '-')"
total_mongo=$("${MONGO_CMD[@]}" --quiet --eval "db.$TABLE_MAIN.countDocuments()")
writeLog "✅ $(format_number $total_mongo) documentos no mongoDB no total."
writeLog "🏁 Exportação completa em $(calculateExecutionTime)"
echo ""
