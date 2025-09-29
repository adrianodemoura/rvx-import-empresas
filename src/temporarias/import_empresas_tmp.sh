#!/bin/bash
#
source "./config/config.sh"

CHECK_DB_SCHEMA=true
CHECK_INDEX_TRIGGER=false
LOG_NAME="import_empresas_tmp"
readonly MODULE_DIR="temporarias"
readonly ORIGEM="estabelecimentos"
readonly TABLES=("naturezas" "municipios" "paises" "motivos" "qualificacoes" "cnaes" "empresas" "socios" "simples" "estabelecimentos")

writeLog "============================================================================================================================="
writeLog "✅ Iniciando a importação CSV para as tabelas do Banco de Dados \"$POSTGRES_DB_DATABASE\" e o Schema \"$POSTGRES_DB_SCHEMA\""

# Campos e quantidade de colunas por tabela
declare -A TABLE_FIELDS=(
  [naturezas]="codigo,descricao"
  [municipios]="codigo,descricao"
  [paises]="codigo,descricao"
  [motivos]="codigo,descricao"
  [qualificacoes]="codigo,descricao"
  [cnaes]="codigo,descricao"
  [empresas]="cnpj_basico,razao_social,natureza_juridica,qualificacao_responsavel,capital_social_str,porte_empresa,ente_federativo_responsavel"
  [socios]="cnpj_basico,identificador_de_socio,nome_socio,cnpj_cpf_socio,qualificacao_socio,data_entrada_sociedade,pais,representante_legal,nome_representante,qualificacao_representante_legal,faixa_etaria"
  [simples]="cnpj_basico,opcao_simples,data_opcao_simples,data_exclusao_simples,opcao_mei,data_opcao_mei,data_exclusao_mei"
  [estabelecimentos]="cnpj_basico,cnpj_ordem,cnpj_dv,matriz_filial,nome_fantasia,situacao_cadastral,data_situacao_cadastral,motivo_situacao_cadastral,nome_cidade_exterior,pais,data_inicio_atividades,cnae_fiscal,cnae_fiscal_secundaria,tipo_logradouro,logradouro,numero,complemento,bairro,cep,uf,municipio,ddd1,telefone1,ddd2,telefone2,ddd_fax,fax,correio_eletronico,situacao_especial,data_situacao_especial"
)

checkDbSchema() {
  [ "$CHECK_DB_SCHEMA" != true ] && return

  writeLog "🔍 Removendo o schema '$POSTGRES_DB_SCHEMA_TMP' se existir..."
  OUTPUT=$("${PSQL_CMD[@]}" -c "DROP SCHEMA IF EXISTS $POSTGRES_DB_SCHEMA_TMP CASCADE;" 2>&1)
  if [[ $? -ne 0 ]]; then
      writeLog "❌ Erro ao remover o schema '$POSTGRES_DB_SCHEMA_TMP': $(echo "$OUTPUT" | tr -d '\n')"
      exit 1
  fi
  echo

  source "./src/util/database/check_db.sh" "$POSTGRES_DB_SCHEMA_TMP"
  source "./src/util/database/check_tables.sh" "$POSTGRES_DB_SCHEMA_TMP"
  echo
}

checkIndexTrigger() {
  [ "$CHECK_INDEX_TRIGGER" != true ] && return

  source "./src/util/database/check_indexes.sh" "$POSTGRES_DB_SCHEMA_TMP"
  source "./src/util/database/check_triggers.sh" "$POSTGRES_DB_SCHEMA_TMP"
}

checkDbSchema

importTable() {
  local TABLE_NAME="$1"
  local CSV_FILE="$2"
  local part_files=() was_split=false
  local FILE_SIZE_LIMIT=$((2000 * 1024 * 1024))   # 2GB 
  local LINE_LIMIT=5000000                        # 5 milhões de linhas

  # Verifica se a tabela existe no mapeamento
  local fields="${TABLE_FIELDS[$TABLE_NAME]}"
  if [ -z "$fields" ]; then
    writeLog "⚠️ Tabela desconhecida: $TABLE_NAME" "$LOG_NAME_ERROR"
    return 1
  fi

  # Divide o arquivo se maior que FILE_SIZE_LIMIT
  local file_size
  file_size=$(stat -c %s "$CSV_FILE")
  part_files=("$CSV_FILE")
  if [ "$file_size" -gt "$FILE_SIZE_LIMIT" ]; then
    split -l "$LINE_LIMIT" "$CSV_FILE" "${CSV_FILE}_part_"
    part_files=("${CSV_FILE}_part_"*)
    was_split=true
  fi

  # Importa cada parte
  for part_file in "${part_files[@]}"; do
    # Captura saída de erro do psql
    local TOTAL_IMPORT
    if TOTAL_IMPORT=$("${PSQL_CMD[@]}" \
        -c "\copy $POSTGRES_DB_SCHEMA_TMP.$TABLE_NAME($fields) \
        FROM '$part_file' WITH (FORMAT csv, HEADER false, DELIMITER ';', ENCODING 'LATIN1')" 2>&1); then

      writeLog "✅ Importação de $(basename "$part_file") (${TOTAL_IMPORT#COPY }) concluída com sucesso."

      # remove apenas se foi split
      if $was_split; then
        rm -f "$part_file"
      fi
    else
      writeLog "❌ Erro ao importar $(basename "$part_file"): ${TOTAL_IMPORT#COPY }" "$LOG_NAME_ERROR"
    fi
  done
  CHECK_INDEX_TRIGGER=true
}

loopTables() {
  for i in "${!TABLES[@]}"; do
    tabela="${TABLES[$i]}"
    for CSV_FILE in "$DIR_CSV/${tabela}"*.csv; do
      [ -f "$CSV_FILE" ] || continue
      importTable "$tabela" "$CSV_FILE"
    done
  done
  echo
}
loopTables

checkIndexTrigger

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Fim da importação CSV para as tabelas do Schema \"$POSTGRES_DB_SCHEMA_TMP\" em $(calculateExecutionTime)"
echo