#!/bin/bash
# Recupera origem e data_origem dos telefones com ID até 276260285
#
source "./config/config.sh"
LAST_ID=276260285
LOG_NAME='rollback'
declare -i TOTAL_ROLLBACK

# Atalho para conexão com o banco remoto
readonly ANTIGO_PROD_PSQL_CMD=( docker exec -i -e PGPASSWORD="$PROD_POSTGRES_DB_PASSWORD" $POSTGRES_CONTAINER 
  psql 
  -p "5454" 
  -h "5.189.187.92" 
  -U "$PROD_POSTGRES_DB_USER" 
  -d "$PROD_POSTGRES_DB_DATABASE"
)


checkStart() {
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Iniciando, com o ID $(format_number $LAST_ID), o rollback de 'origem' e 'data origem' do Banco '$PROD_POSTGRES_DB_HOST/$PROD_POSTGRES_DB_DATABASE/$PROD_POSTGRES_DB_SCHEMA'"
    echo ""
}

checkEnd() {
    echo ""
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Finalizando, com o ID $(format_number $LAST_ID), o rollback de 'origem' e 'data origem' do Banco '$PROD_POSTGRES_DB_HOST/$PROD_POSTGRES_DB_DATABASE/$PROD_POSTGRES_DB_SCHEMA'"
}

main() {
    checkStart

    local query out id origem data_origem

    # Loop na tabela telefones para pegar o ID dos registros que vão sofrer o rollBack
    query="SELECT id FROM bigdata_final.pf_telefones  WHERE id < $LAST_ID AND origem='LEMIT' ORDER BY id ASC LIMIT 1000"
    out=$("${PROD_PSQL_CMD[@]}" -t -c "$query" < /dev/null | paste -sd, | sed 's/,$//')
    [[ -z "$out" ]] && {
        writeLog "❎ Não existem mais registros para o rollBack!"
        checkEnd
        return
    }
    query="SELECT id, origem, data_origem FROM bigdata_final.pf_telefones WHERE id IN ($out)"
    out=$("${ANTIGO_PROD_PSQL_CMD[@]}" -t -c "$query" < /dev/null)

    # Loop no resultado para atualizar os campos origem e data_origem
    mapfile -t arrayIds < <(echo "$out" | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/&\n/g')
    for linha in "${arrayIds[@]}"; do
        id=$(echo "$linha" | cut -d '|' -f1 | tr -d ' ')
        origem=$(echo "$linha" | cut -d '|' -f2 | tr -d ' ')
        data_origem=$(echo "$linha" | cut -d '|' -f3 | tr -d ' ')
        [[ -z $id ]] && continue
        query="UPDATE bigdata_final.pf_telefones SET origem='$origem', data_origem='$data_origem' WHERE id=$id"
        out=$("${PROD_PSQL_CMD[@]}" -c "$query" < /dev/null)
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao tentar atualizar origem e data origem do ID $id!"
            exit 1
        fi
        if [[ $out =~ UPDATE\ ([0-9]+) ]]; then
            linhas_atualizadas=${BASH_REMATCH[1]}
            writeLog "✅ Origem e data origem do ID $id atualizados com sucesso! ($linhas_atualizadas linha(s) afetada(s))"
        else
            writeLog "❌ Não foi possível determinar o número de linhas afetadas para o ID $id!"
            exit 1
        fi
    done

    checkEnd
}


main