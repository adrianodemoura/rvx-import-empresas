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
readonly ORIGEM="INSS_HUGO"

checkStart() {
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Iniciando a importação INSS HUGO de $(format_number $LIMIT_LINES) linhas para o Banco de Dados '$POSTGRES_DB_DATABASE' e o Schema '$POSTGRES_DB_SCHEMA'"
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
    local START_TIME_UPDATE=$(date +%s%3N)
    local cpf="${LINE_VALUES[0]}"
    local nome="${LINE_VALUES[7]}"
    local inserts=0
    local updates=0

    for i in {1..5}; do
        local numero_telefone="${LINE_VALUES[$i]}"
        [[ -z "$numero_telefone" ]] && continue

        local query_check="SELECT COUNT(*) FROM $POSTGRES_DB_SCHEMA_FINAL.pf_telefones WHERE cpf = '$cpf' AND telefone = '$numero_telefone'"
        local count=$("${PROD_PSQL_CMD[@]}" -t -c "$query_check" < /dev/null | tr -d '[:space:]')

        if [ "$count" = "0" ]; then
            local query_insert="INSERT INTO $POSTGRES_DB_SCHEMA_FINAL.pf_telefones (cpf, telefone, tipo, origem) VALUES ('$cpf', '$numero_telefone', '$telefone', '$ORIGEM')"
            # "${PSQL_CMD[@]}" -q -t -c "$query_insert" < /dev/null
            ((inserts++))
        else
            local query_update="UPDATE $POSTGRES_DB_SCHEMA_FINAL.pf_telefones SET tipo = '$telefone' WHERE cpf = '$cpf' AND telefone = '$numero_telefone'"
            # "${PSQL_CMD[@]}" -q -t -c "$query_update" < /dev/null
            ((updates++))
        fi
    done
    writeLog "📥 CPF '$cpf' atualizado com sucesso. INSERTs: $inserts, UPDATEs: $updates"

    TOTAL_INSERTS+=$inserts
    TOTAL_UPDATES+=$updates
}

process_csv() {
    local csv_file="$1"
    local header_line
    header_line=$(head -n1 "$csv_file")
    COUNT_LINES+=1

    writeLog "📂 $(format_number $COUNT_LINES)) Lendo arquivo: '$csv_file'..."

    # Usa process substitution em vez de pipe
    while IFS= read -r line || [ -n "$line" ]; do
        update_pf_telefones "$line"
    done < <(tail -n +2 "$csv_file" | head -n $LIMIT_LINES)

    echo ""
}

main() {
    for CSV_FILE in "$DIR_CSV_SIAPE/"*.csv; do
        [ -f "$CSV_FILE" ] || continue
        process_csv "$CSV_FILE"
    done
}

checkStart
main
checkEnd
