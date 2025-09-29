#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro Schema é obrigatório!"
    exit 1
fi
CHECK_DB_SCHEMA="$1"

writeLog "📣 Verificando conexão com o Banco de Dados '$POSTGRES_DB_DATABASE'..."
ERROR_MSG=$("${PSQL_CMD[@]}" -c '\q' 2>&1)
if [ $? -eq 0 ]; then
  writeLog "✅ Conexão bem-sucedida com o Banco de Dados \"$POSTGRES_DB_DATABASE\"."
else
  writeLog "❌ Erro: Não foi possível conectar ao Banco de Dados \"$POSTGRES_DB_DATABASE\". $ERROR_MSG"
  exit 1
fi
echo

writeLog "📣 Verificando o Schema \"$CHECK_DB_SCHEMA\"..."
SCHEMA_CHECK="SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$CHECK_DB_SCHEMA';"
SCHEMA_EXISTS=$("${PSQL_CMD[@]}" -c "$SCHEMA_CHECK" -t -A)
if [[ -n "$SCHEMA_EXISTS" ]]; then
    writeLog "✅ Conexão bem-sucedida com o SCHEMA \"$CHECK_DB_SCHEMA\"."
else
    OUTPUT=$("${PSQL_CMD[@]}" -c "CREATE SCHEMA ${CHECK_DB_SCHEMA};" 2>/dev/null)
    if [ $? -eq 0 ]; then
        writeLog "✅ SCHEMA \"$CHECK_DB_SCHEMA\" criado com sucesso."
    else
        writeLog "❌ Erro: Não foi possível criar o Schema '$CHECK_DB_SCHEMA'"
        writeLog "$OUTPUT"
        exit 1
    fi
fi
echo