#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro Schema é obrigatório!" "$LOG_NAME_ERROR"
    exit 1
fi
DB_SCHEMA="$1"

writeLog "📣 Verificando conexão com o Banco de Dados \"$DB_DATABASE\"..."
ERROR_MSG=$("${PSQL_CMD[@]}" -c '\q' 2>&1)
if [ $? -eq 0 ]; then
  writeLog "✅ Conexão bem-sucedida com o Banco de Dados \"$DB_DATABASE\"."
else
  writeLog "❌ Erro: Não foi possível conectar ao Banco de Dados \"$DB_DATABASE\". $ERROR_MSG"
  exit 1
fi
echo

writeLog "📣 Verificando o Schema \"$DB_SCHEMA\"..."
SCHEMA_CHECK="SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$DB_SCHEMA';"
SCHEMA_EXISTS=$("${PSQL_CMD[@]}" -c "$SCHEMA_CHECK" -t -A)
if [[ -n "$SCHEMA_EXISTS" ]]; then
    writeLog "✅ Conexão bem-sucedida com o SCHEMA \"$DB_SCHEMA\"."
else
    OUTPUT=$("${PSQL_CMD[@]}" -c "CREATE SCHEMA ${DB_SCHEMA};" 2>/dev/null)
    if [ $? -eq 0 ]; then
        writeLog "✅ SCHEMA \"$DB_SCHEMA\" criado com sucesso."
    else
        writeLog "❌ Erro: Não foi possível criar o Schema \"$DB_SCHEMA\"." "$LOG_NAME_ERROR"
        writeLog "$OUTPUT" "$LOG_NAME_ERROR"
        exit 1
    fi
fi
echo
