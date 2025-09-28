#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!"
    exit 1
fi
DB_SCHEMA="$1"
 
writeLog "📣 Verificando constraints no SCHEMA '$DB_SCHEMA'..."
CONSTRAINTS_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_constraints.sql"
if [[ ! -f "$CONSTRAINTS_MIGRATION_FILE" ]]; then
    writeLog "🗄 Arquivo de migração para criação de constraints não encontrado: $CONSTRAINTS_MIGRATION_FILE"
    exit 1
fi

SQL=$(<"$CONSTRAINTS_MIGRATION_FILE")
SQL="${SQL//\{schema\}/$DB_SCHEMA}"

OUTPUT=$("${PSQL_CMD[@]}" -c "$SQL" 2>&1)

case "$OUTPUT" in
  *"error"*|*"Erro"*)
    writeLog "❌ Erro ao verificar constraints $OUTPUT"
    exit 1
    ;;
  *"already exists"*)
    writeLog "✅ Algumas constraints já existiam e não foram recriadas."
    ;;
  *)
    if [[ $? -eq 1 ]]; then
      writeLog "❌ Erro ao verificar constraints $OUTPUT"
      exit 1
    fi
    writeLog "✅ Constraints criadas com sucesso."
    ;;
esac
echo