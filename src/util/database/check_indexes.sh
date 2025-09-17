#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro SCHEMA é obrigatório!" "$LOG_NAME_ERROR"
    exit 1
fi
DB_SCHEMA="$1"

writeLog "📣 Verificando índices das tabelas do Schema \"$DB_DATABASE.$DB_SCHEMA\"..."
INDEX_MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_all_indexes.sql"
if [[ -f "$INDEX_MIGRATION_FILE" ]]; then
    SQL=$(<"$INDEX_MIGRATION_FILE")
    SQL="${SQL//\{schema\}/$DB_SCHEMA}"

    OUTPUT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE" -c "$SQL" 2>&1)
    if [ $? -eq 0 ]; then
        writeLog "✅ Índices checados com sucesso."
    else
        writeLog "❌ Erro ao criar índices: $OUTPUT" "$LOG_NAME_ERROR"
        exit 1
    fi
else
    writeLog "🗄  Arquivo de migração para criação de índices não encontrado: $INDEX_MIGRATION_FILE" "$LOG_NAME_ERROR"
    exit 1
fi
echo
