#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!"
    exit 1
fi
CHECK_DB_SCHEMA="$1"
 
writeLog "📣 Verificando triggers no SCHEMA \"$CHECK_DB_SCHEMA\"..."
TRIGGER_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_triggers.sql"
if [[ -f "$TRIGGER_MIGRATION_FILE" ]]; then
    SQL=$(<"$TRIGGER_MIGRATION_FILE")
    SQL="${SQL//\{schema\}/$CHECK_DB_SCHEMA}"

    OUTPUT=$("${PSQL_CMD[@]}" -c "$SQL" 2>&1)
    if [[ $? -eq 0 ]]; then
        writeLog "✅ Triggers checadas com sucesso."
    else
        if [[ $OUTPUT == *"already exists"* ]]; then
            writeLog "📣 Algumas triggers já existiam e não foram recriadas."
        else
            writeLog "Erro ao criar triggers: $OUTPUT"
            exit 1
        fi
    fi
else
    writeLog "🗄 Arquivo de migração para criação de triggers não encontrado: $TRIGGER_MIGRATION_FILE"
    exit 1
fi
echo
