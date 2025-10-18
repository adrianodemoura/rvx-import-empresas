#!/bin/bash
#
# Importação de CSVs SIAPE para múltiplas tabelas PostgreSQL
#
# amarelo: pf_pessoas
# cinza : pf_siape_bancos
# verde: pf_siape_matriculass
# roxo: pf_siape_contratos
# vermelho: pf_enderecos
# laranja: pf_telefones
# bege: pf_emails
#
# se for pensionista, criar campo "tipo_aposentadoria", arquivo 1 e 6
# levar cpf e matrícula, para novas tabelas
# quando importar novamente, deletar empréstimos, pois virá tudo novamente.
# 6_siape_setembro_2025_pensionistas_excluidos.csv, colocar FLAG `excluído`.
#
source "./config/config.sh"
source "./src/import_siape/fields.sh"

declare -i COUNT_LINES=0
readonly LIMIT_LINES=${1:-2}
readonly LOG_NAME="import_siape"
readonly DIR_CSV_SIAPE="$DIR_CACHE/siape_csv"
readonly POSTGRES_DB_SCHEMA="bigdata_tmp"

checkStart() {
    writeLog "$(repeat_char '=')"
    writeLog "🚀 Iniciando a importação SIAPE de $(format_number $LIMIT_LINES) linhas para o Banco de Dados '$POSTGRES_DB_DATABASE' e o Schema '$POSTGRES_DB_SCHEMA'"
    echo ""
}

checkEnd() {
    writeLog "$(repeat_char '-')"
    writeLog "✅ Importação SIAPE completa em $(calculateExecutionTime)"
    echo ""
}

# Função utilitária para pegar o valor de um campo do CSV
get_csv_value() {
    local header_name="$1"
    local header_idx="${HEADERS_MAP[$header_name]}"
    if [[ -n "$header_idx" ]]; then
        echo "${LINE_VALUES[$header_idx]}"
    else
        echo ""
    fi
}

# Cria mapa de índices do cabeçalho → nome da coluna
build_headers_map() {
    local header_line="$1"
    IFS=';' read -ra HEADER_ARRAY <<< "$header_line"
    declare -gA HEADERS_MAP
    for i in "${!HEADER_ARRAY[@]}"; do
        key=$(echo "${HEADER_ARRAY[$i]}" | tr -d '\r' | xargs)
        HEADERS_MAP["$key"]=$i
    done
}

#
# get_fields_values() {
#     local table_name=$1
#     [[ -z "$table_name" ]] && return

#     # cria um array associativo local
#     declare -A result=()

#     for field in "${FIELDS[@]}"; do
#         local field_name=${field%%:*}
#         local field_table=${field#*:}
#         field_table=${field_table%%.*}

#         if [[ "$field_table" == "$table_name" ]]; then
#             local field_value
#             field_value=$(get_csv_value "$field_name")
#             result["$field_name"]="$field_value"
#         fi
#     done

#     # “retorna” o array — na prática, faz um declare -p para capturar fora
#     declare -p result
# }
get_field_value() {
    local table_name=$1
    local field_name=$2
    [[ -z "$table_name" ]] && return

    declare -A fields_values=()

    for field in "${FIELDS[@]}"; do
        local field_name=${field%%:*}
        local field_table=${field#*:}
        field_table=${field_table%%.*}

        if [[ "$field_table" == "$table_name" ]]; then
            local field_value
            field_value=$(get_csv_value "$field_name")
            fields_values["$field_name"]="$field_value"
        fi
    done

    echo "$fields_values"
}

# Atualiza pf_pessoas
update_pf_pessoas() {
    local START_TIME_UPDATE=$(date +%s%3N)
    local cpf="$(get_csv_value "cpf")"
    [[ -z "$cpf" ]] && return

    local fields_values=$(get_fields_values "pf_pessoas")
    echo $fields_values
    echo
    echo "${fields_values[nome]}"

    # local nome="$(get_csv_value "nome")"
    # local sexo="$(get_csv_value "SEXO")"
    # local nascimento="$(get_csv_value "DT_NASCIMENTO")"
    # local nome_mae="$(get_csv_value "NOME_MAE")"

    # echo "('$cpf', '$nome', '$sexo', '$nascimento', '$nome_mae')"

    writeLog "✅ 'pf_pessoas' atualizada com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

# Atualiza pf_siape_bancos
update_pf_siape_bancos() {
    local START_TIME_UPDATE=$(date +%s%3N)
    local cpf="$(get_csv_value "cpf")"
    [[ -z "$cpf" ]] && return
    local bco_pagto="$(get_csv_value "BCO_PAGTO")"
    local ag="$(get_csv_value "AG")"
    local cc="$(get_csv_value "CC")"
    local banco="$(get_csv_value "banco")"

    # echo "('$cpf', '$bco_pagto', '$ag', '$cc', '$banco')"

    # $PSQL <<SQL
    #     INSERT INTO ${POSTGRES_DB_SCHEMA}.pf_siape_bancos (cpf, bco_pagto, ag, cc, banco)
    #     VALUES ('$cpf', '$bco_pagto', '$ag', '$cc', '$banco')
    #     ON CONFLICT (cpf)
    #     DO UPDATE SET bco_pagto=EXCLUDED.bco_pagto, ag=EXCLUDED.ag, cc=EXCLUDED.cc, banco=EXCLUDED.banco;
    # SQL
    writeLog "✅ 'pf_pessoas' atualizada com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

# Atualiza pf_siape_contratos
update_pf_siape_contratos() {
    local START_TIME_UPDATE=$(date +%s%3N)
    local cpf="$(get_csv_value "cpf")"
    [[ -z "$cpf" ]] && return
    local rub="$(get_csv_value "rub")"
    local parcela="$(get_csv_value "parcela")"
    local prazo="$(get_csv_value "prazo")"
    local codigo_uf_siafi="$(get_csv_value "codigo_uf_siafi")"

    writeLog "✅ 'pf_siape_contratos' atualizada com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

# Atualiza pf_enderecos
update_pf_enderecos() {
    local START_TIME_UPDATE=$(date +%s%3N)
    writeLog "✅ 'pf_enderecos' atualizado com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

# Atualiza pf_telefones
update_pf_telefones() {
    local START_TIME_UPDATE=$(date +%s%3N)
    writeLog "✅ 'pf_telefones' atualizado com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

# Atualiza pf_emails
update_pf_emails() {
    local START_TIME_UPDATE=$(date +%s%3N)
    writeLog "✅ 'pf_emails' atualizado com sucesso em $(calculateExecutionTime $START_TIME_UPDATE)"
}

process_csv() {
    local csv_file="$1"
    local header_line
    header_line=$(head -n1 "$csv_file")
    build_headers_map "$header_line"

    COUNT_LINES+=1
    writeLog "📂 $(format_number $COUNT_LINES)) Lendo arquivo: '$csv_file'..."
    tail -n +2 "$csv_file" | \
        head -n $LIMIT_LINES | \
            while IFS=';' read -r -a LINE_VALUES; do
                update_pf_pessoas
                # update_pf_siape_bancos
                # update_pf_enderecos
                # update_pf_telefones
                # update_pf_emails
                echo ""
            done
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
