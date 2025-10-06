#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
LOG_NAME="import_pf"
readonly MODULE_DIR="bigdata"
readonly PF_ORIGEM="bigdata_final"
readonly PF_DATA_ORIGEM=$(date +%F)
readonly TABLES=(
    pf_pessoas 
    pf_telefones 
    pf_emails 
    pf_enderecos
    pf_banco_gov
    pf_bolsa_familia
    pf_capacidade_pagamento
    pf_carteira_trabalho
    pf_cbo
    pf_classe_social
    pf_escolaridade
    pf_fgts
    pf_governos
    pf_imoveis_ibge
    pf_modelo_analitico_credito
    pf_nacionalidade
    pf_obitos
    pf_persona_demografica
    pf_pis
    pf_poder_aquisitivo
    pf_politicamente_exposta
    pf_propensao_pagamento
    pf_renda
    pf_score
    pf_score_digital
    pf_situacao_receita
    pf_titulo_eleitor
    pf_triagem_risco
    pf_veiculos
    pf_vinculo_empregaticio
    pf_vinculos_familiares
)

readonly PROD_PG_DUMP=(
  docker exec -i -e PGPASSWORD="$PROD_POSTGRES_DB_PASSWORD" $POSTGRES_CONTAINER 
  pg_dump 
  -p "$PROD_POSTGRES_DB_PORT"
  -h "$PROD_POSTGRES_DB_HOST" 
  -U "$PROD_POSTGRES_DB_USER" 
  -d "$PROD_POSTGRES_DB_DATABASE"
)

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando a importação das tabelas PF para o Banco de Dados '$PROD_POSTGRES_DB_DATABASE' e o Schema '$PROD_POSTGRES_DB_SCHEMA'"
echo ""

copyDataFromRemote() {
    local table="$1"
    local BATCH_SIZE=$(echo "10.000.000" | tr -d '.') MAX_RECORDS=$(echo "300.000.000" | tr -d '.')
    local OFFSET=0
    local RECORDS_IMPORTED=0
    local RESULT=""

    local EXISTS=$("${PSQL_CMD[@]}" -A -c "SELECT EXISTS (SELECT 1 FROM $POSTGRES_DB_SCHEMA_FINAL.$table)" | tail -n 2 | grep -oE "(t|f)")
    [ "$EXISTS" == "t" ] && { writeLog "🏁 Tabela '$table' já está populada. Ignorando importação."; return; }

    while true; do
        local START_TIME_COPY=$(date +%s%3N)
        writeLog "🔎 $(format_number $BATCH_SIZE) linhas recuperadas na tabela '$table' no remoto...."

        local SQL="SELECT * 
            FROM $PROD_POSTGRES_DB_SCHEMA.$table 
            ORDER BY $table.id
            LIMIT $BATCH_SIZE 
            OFFSET $OFFSET"

        local DATA=$("${PROD_PSQL_CMD[@]}" -c "\copy ( $SQL ) TO STDOUT WITH CSV HEADER")
        [ -z "$DATA" ] && {
            writeLog "✅ Não há mais dados para copiar da tabela '$table'.";
            break;
        }

        writeLog "📥 $(format_number $BATCH_SIZE) linhas inseridas na tabela '$table' no local..."
        RESULT=$(echo "$DATA" | "${PSQL_CMD[@]}" -c "\copy $POSTGRES_DB_SCHEMA_FINAL.$table FROM STDIN WITH CSV HEADER")
        [ $? -ne 0 ] && {
            writeLog "❌ Erro ao copiar dados da tabela '$table' do remoto para o local"; 
            exit 1;
        }

        RECORDS_IMPORTED=$((RECORDS_IMPORTED + $(echo "$RESULT" | grep -oE '[0-9]+')))
        OFFSET=$((OFFSET + BATCH_SIZE))
        writeLog "✅ $(format_number $BATCH_SIZE) registros copiadas da tabela '$table' do remoto para o local em $(calculateExecutionTime $START_TIME_COPY)"
        [ $RECORDS_IMPORTED -ge $MAX_RECORDS ] && {
            writeLog "✅ $(format_number $MAX_RECORDS) registros alcançado. Parando a importação da tabela '$table'.";
            break;
        }
    done
    writeLog "✅ $(format_number $RECORDS_IMPORTED) registros da tabela copiados com sucesso em $(calculateExecutionTime)"
    echo ""
}

createTableFromRemote() {
    local START_TIME_CREATE=$(date +%s%3N)
    local table="$1"

    local TABLE_EXISTS=$("${PSQL_CMD[@]}" -c "SELECT 1 FROM pg_tables WHERE schemaname = '$POSTGRES_DB_SCHEMA_FINAL' AND tablename = '$table'" | grep -q 1 && echo true || echo false)
    if [[ "$TABLE_EXISTS" != "false" ]]; then
        writeLog "✅ Tabela '$table' já existe no local, pulando criação..."
        return
    fi

    writeLog "🔎 Recuperando a DDL da tabela '$table' no remoto..."
    DDL=$("${PROD_PG_DUMP[@]}" --no-owner --no-privileges --schema-only --table "$PROD_POSTGRES_DB_SCHEMA.$table" | sed -n '/CREATE TABLE/,/;/p')
    if [[ -z "$DDL" ]]; then
        writeLog "❌ Não consegui extrair DDL da tabela '$table' no remoto"
        exit 1
    fi

    writeLog "📦 Criando a tabela '$table' no local..."
    echo "$DDL" | "${PSQL_CMD[@]}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar tabela '$table' no local"
        exit 1
    fi

    writeLog "✅ Tabela '$table' criada com sucesso no local em $(calculateExecutionTime $START_TIME_CREATE)"
    echo ""
}

importPfTables() {
    for table in "${TABLES[@]}"; do
        createTableFromRemote "$table"
        copyDataFromRemote "$table"
    done
}

source "./src/util/database/check_db.sh" $POSTGRES_DB_SCHEMA_FINAL

importPfTables

writeLog "$(repeat_char '-')"
writeLog "✅ Fim da importação Pessoas em $(calculateExecutionTime)"
echo
