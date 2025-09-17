#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!" "$LOG_NAME_ERROR"
    exit 1
fi
DB_SCHEMA="$1"
 
echo "📣 Verificando triggers no SCHEMA \"$DB_SCHEMA\"..."
TRIGGER_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_triggers.sql"
if [[ -f "$TRIGGER_MIGRATION_FILE" ]]; then
    SQL=$(<"$TRIGGER_MIGRATION_FILE")
    SQL="${SQL//\{schema\}/$DB_SCHEMA}"

    ERROR=$(PGPASSWORD="$DB_PASSWORD" psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "$SQL" 2>&1)
    if [[ $? -eq 0 ]]; then
        writeLog "✅ Triggers criadas com sucesso." "$LOG_NAME_SUCCESS"
    else
        if [[ $ERROR == *"already exists"* ]]; then
            writeLog "📣 Algumas triggers já existiam e não foram recriadas." "$LOG_NAME_SUCCESS"
        else
            writeLog "Erro ao criar triggers: $ERROR" "$LOG_NAME_ERROR"
            exit 1
        fi
    fi
else
    writeLog "🗄 Arquivo de migração para criação de triggers não encontrado: $TRIGGER_MIGRATION_FILE" "$LOG_NAME_ERROR"
    exit 1
fi
echo