#!/bin/bash
#
source "./config/config.sh"

# Variáveis do script
CHECK_DATABASE_SCHEMA=true
CHECK_INDEX_TRIGGER_CONSTRAINT=false
readonly MODULE_DIR="import_bigdata_empresas"
readonly ORIGEM="estabelecimentos"
readonly LOG_NAME_SUCCESS="success_import_${DB_SCHEMA,,}"
readonly LOG_NAME_ERROR="error_import_${DB_SCHEMA,,}"
readonly TABLES=( "pj_cnaes_list" "pj_empresas_cnaes" "pj_empresas" "pj_empresas_emails" "pj_empresas_enderecos" "pj_empresas_socios" "pj_empresas_telefones" "pj_naturezas_juridicas" "pj_qualificacoes_socios")

writeLog "============================================================================================================================="
writeLog "✅ [$(date +'%Y-%m-%d %H:%M:%S.%3N')] Iniciando a importação de tabelas para o Banco de Dados \"$DB_DATABASE\" e o Schema \"$DB_SCHEMA\""

carregarSQL() {
  local SQL_FILE=$1
  local LAST_ID=$2
  local LIMIT=$3
  local SQL=""

  if [[ -f "$SQL_FILE" ]]; then
    SQL=$(<$SQL_FILE)
    SQL="${SQL//\$DB_SCHEMA_PESSOAS/$DB_SCHEMA_PESSOAS}"
    SQL="${SQL//\$DB_SCHEMA_TMP/$DB_SCHEMA_TMP}"
    SQL="${SQL//\$DB_SCHEMA/$DB_SCHEMA}"
    SQL="${SQL//\$DATA_ORIGEM/$DATA_ORIGEM}"
    SQL="${SQL//\$ORIGEM/$ORIGEM}"
    SQL="${SQL//\$LIMIT/$LIMIT}"
    SQL="${SQL//\$LAST_ID/$LAST_ID}"
  else
    echo "❌ Erro ao tentar importar SQL!"
    exit 1
  fi

  echo "$SQL"
}

checkDbSchemaTables() {
  if [ "$CHECK_DATABASE_SCHEMA" != true ]; then
    writeLog "📣 A verificação do Schema \"$DB_SCHEMA\" foi ignorada."
    echo
    return
  fi

  source "./src/util/database/check_db.sh" "$DB_SCHEMA"
  source "./src/util/database/check_tables.sh" "$DB_SCHEMA"
  echo
}

checkIndexTriggerConstraint() {
  if [ "$CHECK_INDEX_TRIGGER_CONSTRAINT" != true ]; then
    writeLog "📣 A verificação dos Índices, Triggers e Constraints do Schema \"$DB_SCHEMA\" foi ignorada."
    echo
    return
  fi

  source "./src/util/database/check_indexes.sh" "$DB_SCHEMA"
  source "./src/util/database/check_triggers.sh" "$DB_SCHEMA"
  source "./src/util/database/check_constraints.sh" "$DB_SCHEMA"
  echo
}

importTable() {
  # local MAX_RECORDS=$(echo "1.000.000.000" | tr -d '.') LIMIT=$(echo "10.000.000" | tr -d '.')
  local MAX_RECORDS=$(echo "1.000" | tr -d '.') LIMIT=$(echo "100" | tr -d '.')  
  local LAST_ID=0 IMPORTED=0
  local OUTPUT START_TIME_IMPORT SQL LAST_ID_ROW
  local TABLE_IMPORT="$1"
  local SQL_FILE="./src/$MODULE_DIR/sqls/$2.sql"

  # Verifica se já tem algo na tabela
  OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "SELECT EXISTS(SELECT 1 FROM $DB_SCHEMA.${TABLE_IMPORT})")
  if [ "$OUTPUT" = "t" ]; then
    writeLog "📣 A Tabela \"$DB_SCHEMA.$TABLE_IMPORT\" já possui registros, importação ignorada."
    return
  fi

  writeLog "📣 Aguarde o fim da importação na tabela \"$DB_SCHEMA.${TABLE_IMPORT}\"..."
  while (( IMPORTED < MAX_RECORDS )); do
    START_TIME_IMPORT=$(date +%s%3N)

    # carrega SQL substituindo placeholders ($SQL_FILE $LAST_ID e $LIMIT)
    SQL=$(carregarSQL "$SQL_FILE" "$LAST_ID" "$LIMIT")

    # Executa a SQL de importação
    OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "$SQL" 2>&1)
    if [[ $? -ne 0 ]]; then
      writeLog "❌ Erro ao popular \"$DB_SCHEMA.$TABLE_IMPORT\": $(echo "$OUTPUT" | tr -d '\n')" "$LOG_NAME_ERROR"
      exit 1
    fi

    # pega o último ID retornado (a SQL retorna apenas MAX(id) como last_id)
    LAST_ID_ROW=$(echo "$OUTPUT" | grep -E '^[0-9]+$' | tail -1)
    if [[ -z "$LAST_ID_ROW" ]]; then
      writeLog "🏁 Nenhum registro retornado, encerrando loop."
      break
    fi
    LAST_ID="$LAST_ID_ROW"
    IMPORTED=$((IMPORTED + LIMIT))

    writeLog "📥 $(format_number $IMPORTED) linhas (ID até=$(format_number $LAST_ID)) importadas para \"$DB_SCHEMA.$TABLE_IMPORT\" em $(calculateExecutionTime $START_TIME_IMPORT)"
  done

  CHECK_INDEX_TRIGGER_CONSTRAINT=true
  writeLog "✅ Importação concluída: $(format_number $LAST_ID) linhas no total para \"$DB_SCHEMA.$TABLE_IMPORT\""
  echo
}

checkDbSchemaTables

importTable "pj_cnaes_list" "insert_pj_empresas_cnaes_list-select_cnaes"
importTable "pj_naturezas_juridicas" "insert_pj_naturezas_juridicas-select_naturezas"
importTable "pj_qualificacoes_socios" "insert_pj_qualificacoes_socios-select_qualificacoes"
importTable "pj_empresas_emails" "insert_pj_empresas_emails-select_estabelecimentos"
importTable "pj_empresas_telefones" "insert_pj_empresas_telefones-select_estabelecimentos"
importTable "pj_empresas_enderecos" "insert_pj_empresas_enderecos-select_estabelecimentos"
importTable "pj_empresas_socios" "insert_pj_empresas_socios-select_socios"
importTable "pj_empresas" "insert_pj_empresas-select_empresas"
importTable "pj_empresas_cnaes" "insert_pj_empresas_cnaes-select_estabelecimentos"

echo
checkIndexTriggerConstraint

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ [$(date +'%Y-%m-%d %H:%M:%S.%3N')] Importação de tabelas para o Schema \"$DB_SCHEMA\" finalizada em $(calculateExecutionTime)"
echo