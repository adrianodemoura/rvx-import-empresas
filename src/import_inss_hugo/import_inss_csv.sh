#!/bin/bash
#
# Importação de CSVs Inss Hugo
#
# CPF;TELEFONE1;TELEFONE2;TELEFONE3;TELEFONE4;TELEFONE5;CODIGO;NOME
# criar campo: "ranking", ordem pelo CSV, depois o que já tem no banco
# limpar campos: temp_min até o campo last_error_date
# origem = LEMIT, data_origem='01/mes/ano'
#

source "./config/config.sh"
source "./src/import_siape/fields.sh"

declare -i COUNT_LINES=0
declare -i TOTAL_INSERTS=0
declare -i TOTAL_UPDATES=0
readonly LIMIT_LINES=${1:-100}
readonly LOG_NAME="import_inss_hugo"
readonly DIR_CSV_SIAPE="$DIR_CACHE/inss_hugo"
readonly ORIGEM="LEMIT"
readonly DATA_ORIGEM="$(date +%Y-%m-01)"

checkStart() {
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Iniciando a importação '$ORIGEM' de $(format_number $LIMIT_LINES) linhas para o Banco '$POSTGRES_DB_DATABASE' e o Schema '$POSTGRES_DB_SCHEMA_FINAL'"
    echo ""
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    writeLog "📈 Totais gerais:"
    writeLog "📣 INSERTs: $TOTAL_INSERTS"
    writeLog "📣 UPDATEs: $TOTAL_UPDATES"
    writeLog "✅ Importação INSS HUGO completa em $(calculateExecutionTime)"
    echo ""
}

# Atualiza pf_telefones
update_pf_telefones() {
    IFS=';' read -ra LINE_VALUES <<< "$1"
    local START_TIME_UPDATE=$(date +%s%3N) cpf="${LINE_VALUES[0]}" nome="${LINE_VALUES[7]}" all_phones
    local fields="id, telefone, ranking, origem, data_origem, temp_min, temp_max, ok_calls_total, last_ok_date, whatsapp_checked_at, err_404_notfound, err_503_blacklist_stage, penal_487_cancel, penal_480_noanswer, last_error_date"
    local -i inserts=0 updates=0 data_total=0

    [[ -z "$cpf" ]] && continue
    COUNT_LINES+=1

    # Criando o novo registro do telefone
    local -i last_ranking=1 data_new_total=0
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

        ((data_new_total++))
        ((last_ranking++))
    done

    # Recupeando telefones do CPF no banco de dados 
    local query="SELECT $fields FROM $POSTGRES_DB_SCHEMA_FINAL.pf_telefones WHERE cpf = '$cpf' ORDER BY ranking"
    local out=$("${PROD_PSQL_CMD[@]}" -t -c "$query" < /dev/null )
    eval "$(outToArray "$out" "$fields")"
    data_total=$(( data_index + data_new_total ))

    # Loop no data, resultado da query
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
            ((data_new_total++))
            ((last_ranking++))
        }
    done

    local -i index=1
    IFS=';' read -ra array_phones <<< "${all_phones#;}"
    for telefone in "${array_phones[@]}"; do
        local id="${data_new[$telefone,id]}"
        declare "data_new[$telefone,ranking]=$index"

        if [[ -v $id ]]; then
            ((inserts++))
        else
            ((updates++))
        fi

        echo "Cpf: $cpf Telefone: ${data_new[$telefone,telefone]} | Ranking: ${data_new[$telefone,ranking]} | Id: $id"
        ((index++))
    done

    writeLog "📥 $(format_number $COUNT_LINES)) CPF '$cpf' com '$data_new_total' telefones atualizado com sucesso. INSERTs: $inserts, UPDATEs: $updates"
    echo ""

    TOTAL_INSERTS+=$inserts
    TOTAL_UPDATES+=$updates
}

main() {
    checkStart

    for CSV_FILE in "$DIR_CSV_SIAPE/"*.csv; do
        [ -f "$CSV_FILE" ] || continue

        writeLog "📂 Lendo arquivo: '$(echo $CSV_FILE | cut -d'/' -f 5)'..."
        echo ""

        while IFS= read -r line || [ -n "$line" ]; do
            update_pf_telefones "$line"
        done < <(tail -n +2 "$CSV_FILE" | head -n $LIMIT_LINES)
    done

    checkEnd
}

main
