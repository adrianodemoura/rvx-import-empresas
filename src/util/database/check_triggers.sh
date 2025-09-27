#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!"
    exit 1
fi
DB_SCHEMA="$1"
 
writeLog "📣 Verificando triggers no SCHEMA \"$DB_SCHEMA\"..."
TRIGGER_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_triggers.sql"
if [[ -f "$TRIGGER_MIGRATION_FILE" ]]; then
    SQL=$(<"$TRIGGER_MIGRATION_FILE")
    SQL="${SQL//\{schema\}/$DB_SCHEMA}"

    ERROR=$(PGPASSWORD="$POSTGRES_DB_PASSWORD" psql -h $POSTGRES_DB_HOST -p $POSTGRES_DB_PORT -U $POSTGRES_DB_USER -d $POSTGRES_DB_DATABASE -c "$SQL" 2>&1)
    if [[ $? -eq 0 ]]; then
        writeLog "✅ Triggers checadas com sucesso."
    else
        if [[ $ERROR == *"already exists"* ]]; then
            writeLog "📣 Algumas triggers já existiam e não foram recriadas."
        else
            writeLog "Erro ao criar triggers: $ERROR"
            exit 1
        fi
    fi
else
    writeLog "🗄 Arquivo de migração para criação de triggers não encontrado: $TRIGGER_MIGRATION_FILE"
    exit 1
fi
echo