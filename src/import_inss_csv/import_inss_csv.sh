#!/bin/bash
#
# Importação de CSVs Inss Hugo
#
# CPF;TELEFONE1;TELEFONE2;TELEFONE3;TELEFONE4;TELEFONE5;CODIGO;NOME
# criar campo: "ranking", ordem pelo CSV, depois o que já tem no banco
# limpar campos: temp_min até o campo last_error_date
# origem = LEMIT, data_origem='01/mes/ano', somente para novos importados, já do banco manter.
#

source "./config/config.sh"

declare -i COUNT_LINES=0
declare -i TOTAL_INSERTS=0
declare -i TOTAL_UPDATES=0
declare -i LIMIT_LINES=${1:-0}
readonly LOG_NAME="import_inss"
readonly DIR_CSV_SIAPE="$DIR_CACHE/inss_csv"
readonly ORIGEM="LEMIT"
readonly DATA_ORIGEM="$(date +%Y-%m-01)"

checkStart() {
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Iniciando a importação '$ORIGEM' de $(format_number $LIMIT_LINES) linhas para o Banco '$PROD_POSTGRES_DB_HOST/$PROD_POSTGRES_DB_DATABASE/$PROD_POSTGRES_DB_SCHEMA'"
    echo ""
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    writeLog "📈 Totais gerais:"
    writeLog "📣 INSERTs: $TOTAL_INSERTS"
    writeLog "📣 UPDATEs: $TOTAL_UPDATES"
    writeLog "✅ Importação INSS completa em $(calculateExecutionTime)"
    echo ""
}

# Atualiza pf_telefones
update_pf_telefones() {
    IFS=';' read -ra LINE_VALUES <<< "$1"
    local START_TIME_UPDATE=$(date +%s%3N) all_phones
    local fields="id, telefone, ranking, origem, data_origem, temp_min, temp_max, ok_calls_total, last_ok_date, whatsapp_checked_at, err_404_notfound, err_503_blacklist_stage, penal_487_cancel, penal_480_noanswer, last_error_date"
    local updated_at=$(date +"%Y-%m-%d %H:%M:%S.%N")
    local cpf="${LINE_VALUES[0]}" nome="${LINE_VALUES[7]}" tipo_celular="CELULAR"
    local -i inserts=0 updates=0

    # normalizando cpf
    cpf=$(printf "%011s" "$cpf" | tr ' ' '0')

    [[ -z "$cpf" ]] && continue
    COUNT_LINES+=1

    # Criando o novo registro do telefone com base no CPF do CSV
    local -i last_ranking=1 count_total_phones_cpf=0
    declare -A data_new
    for i in {1..5}; do
        local numero_telefone="${LINE_VALUES[$i]}"
        [[ -z "$numero_telefone" ]] && continue

        all_phones+=";$numero_telefone"

        IFS=',' read -ra arr_fields <<< "${fields// /}"
        for o in "${!arr_fields[@]}"; do
            declare "data_new[$numero_telefone,${arr_fields[$o]}]=0"
        done
        declare "data_new[$numero_telefone,id]=0"
        declare "data_new[$numero_telefone,telefone]=$numero_telefone"
        declare "data_new[$numero_telefone,cpf]=$cpf"
        declare "data_new[$numero_telefone,origem]=$ORIGEM"
        declare "data_new[$numero_telefone,data_origem]=$DATA_ORIGEM"

        ((count_total_phones_cpf++))
        ((last_ranking++))
    done

    # Recupeando telefones do CPF no banco de dados 
    local query="SELECT $fields FROM $PROD_POSTGRES_DB_SCHEMA.pf_telefones WHERE cpf = '$cpf' ORDER BY ranking, id"
    local out=$("${PROD_PSQL_CMD[@]}" -t -c "$query" < /dev/null )
    eval "$(outToArray "$out" "$fields")"

    # Loop nos telefones do banco de dados
    for ((i=0; i<$data_index; i++)); do
        local idBanco="${data[$i,id]}"
        local telefoneBanco="${data[$i,telefone]}"
        local telefoneCsv="${data_new[$telefoneBanco,telefone]}"

        declare "data_new[$telefoneBanco,id]=$idBanco"
        declare "data_new[$telefoneBanco,telefone]=$telefoneBanco"
        declare "data_new[$telefoneBanco,cpf]=$cpf"
        declare "data_new[$telefoneBanco,origem]=$ORIGEM"
        declare "data_new[$telefoneBanco,data_origem]=$DATA_ORIGEM"

        [[ $telefoneBanco != $telefoneCsv ]] && {
            all_phones+=";$telefoneBanco"
            ((count_total_phones_cpf++))
            ((last_ranking++))
        }
    done

    # Atualizando e/ou inserindo no banco
    local -i ranking=1
    IFS=';' read -ra array_phones <<< "${all_phones#;}"
    for telefone in "${array_phones[@]}"; do
        declare "data_new[$telefone,ranking]=$ranking"
        local id="${data_new[$telefone,id]}"

        case ${#telefone} in
            11) tipo_celular="CELULAR";;
             *) tipo_celular="FIXO";;
        esac

        if [[ -v $id ]]; then
            local query_insert="INSERT INTO 
                $PROD_POSTGRES_DB_SCHEMA.pf_telefones 
                (cpf, telefone, ranking, origem, data_origem, updated_at, tipo) VALUES 
                ('$cpf', '$telefone', $ranking, '$ORIGEM', '$DATA_ORIGEM', '$updated_at', '$tipo_celular')"

            "${PROD_PSQL_CMD[@]}" -q -t -c "$query_insert" < /dev/null
            ((inserts++))
            ((TOTAL_INSERTS++))
        else
            local query_update="UPDATE 
                $PROD_POSTGRES_DB_SCHEMA.pf_telefones SET 
                    ranking = $ranking, 
                    temp_min = null, 
                    temp_max = null, 
                    ok_calls_total = null, 
                    last_ok_date = null, 
                    whatsapp_checked_at = null, 
                    err_404_notfound = null, 
                    err_503_blacklist_stage = null, 
                    penal_487_cancel = null, 
                    penal_480_noanswer = null, 
                    last_error_date = null,
                    tipo = '$tipo_celular',
                    updated_at = '$updated_at'
                    WHERE id=$id"

            "${PROD_PSQL_CMD[@]}" -q -t -c "$query_update" < /dev/null
            ((updates++))
            ((TOTAL_UPDATES++))
        fi
        ((ranking++))
    done

    (( COUNT_LINES % 3000 == 0 || COUNT_LINES == 1 )) && {
        writeLog "📥 $(format_number $COUNT_LINES)) CPF '$cpf' com '$count_total_phones_cpf' telefones atualizado com sucesso. INSERTs: $inserts, UPDATEs: $updates"
    }
}

main() {
    checkStart

    for CSV_FILE in "$DIR_CSV_SIAPE/"*.csv; do
        [ -f "$CSV_FILE" ] || continue

        writeLog "📂 Lendo arquivo: '$(echo $CSV_FILE | cut -d'/' -f 5)'..."
        echo ""

        if [[ $LIMIT_LINES == 0 ]]; then
            local LIMIT_LINES=$(wc -l "$CSV_FILE" | cut -d' ' -f1)
        fi

        while IFS= read -r line || [ -n "$line" ]; do
            update_pf_telefones "$line"
        done < <(tail -n +2 "$CSV_FILE" | head -n $LIMIT_LINES)
    done

    checkEnd
}

main
