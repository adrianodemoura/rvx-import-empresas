#!/bin/bash

if [[ -z "$1" ]]; then
    writeLog "❌ Erro: O parâmetro 'Schema' é obrigatório!"
    exit 1
fi
DB_SCHEMA="$1"

# Verifica se as tabelas existem
writeLog "📣 Verificando tabelas no Schema \"$DB_SCHEMA\"..."
for LINE in "${TABLES[@]}"; do
    TABLE=${LINE%%=*}
    TABLE_CHECK="SELECT to_regclass('$DB_SCHEMA.$TABLE');"
    TABLE_EXISTS=$("${PSQL_CMD[@]}" -c "$TABLE_CHECK" -t -A)
    if [[ "$TABLE_EXISTS" == "$DB_SCHEMA.$TABLE" ]]; then
        writeLog "✅ Tabela \"$TABLE\" checada com sucesso no schema $DB_SCHEMA."
    else
        # Cria a tabela se não existir
        MIGRATION_FILE="./src/$MODULE_DIR/sqls/create_table_$TABLE.sql"
        if [[ -f "$MIGRATION_FILE" ]]; then
            SQL=$(<$MIGRATION_FILE)
            SQL="${SQL//\{schema\}/$DB_SCHEMA}"
            SQL="${SQL//\{table\}/$TABLE}"

            OUTPUT=$("${PSQL_CMD[@]}" -c "$SQL" 2>&1)
            if [ $? -ne 0 ]; then
                writeLog "❌ Erro: Não foi possível criar a Tabela \"$TABLE\"."
                writeLog "Mensagem de erro: $OUTPUT" "$LOG_NAME_ERROR"
                exit 1
            else
                writeLog "✅ Tabela \"$TABLE\" CRIADA com sucesso."
            fi
        else
            writeLog "🗃  Arquivo de migração NÃO encontrado para a tabela \"$TABLE\". $MIGRATION_FILE"
            exit 1
        fi
    fi
done