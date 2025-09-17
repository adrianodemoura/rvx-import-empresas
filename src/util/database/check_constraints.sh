#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!" "$LOG_NAME_ERROR"
    exit 1
fi
DB_SCHEMA="$1"
 
echo "📣 Verificando constraints no SCHEMA \"$DB_SCHEMA\"..."
CONSTRAINTS_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_constraints.sql"
if [[ -f "$CONSTRAINTS_MIGRATION_FILE" ]]; then
    SQL=$(<"$CONSTRAINTS_MIGRATION_FILE")
    SQL="${SQL//\{schema\}/$DB_SCHEMA}"

    ERROR=$(PGPASSWORD="$DB_PASSWORD" psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "$SQL" 2>&1)
    if [[ $? -eq 0 ]]; then
        writeLog "✅ Constraints criadas com sucesso." "$LOG_NAME_SUCCESS"
    else
        if [[ $ERROR == *"already exists"* ]]; then
            writeLog "📣 Algumas constraints já existiam e não foram recriadas." "$LOG_NAME_SUCCESS"
        else
            writeLog "Erro ao criar constraint: $ERROR" "$LOG_NAME_ERROR"
            exit 1
        fi
    fi
else
    writeLog "🗄 Arquivo de migração para criação de constraints não encontrado: $CONSTRAINTS_MIGRATION_FILE" "$LOG_NAME_ERROR"
    exit 1
fi
echo