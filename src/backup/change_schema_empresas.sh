#!/bin/bash
# Altera o schema das tabelas de empresa para o bigdata_final
#
source "./config/config.sh"
LOG_NAME_SUCCESS="change_tables_pj_empresas_schemas"
tables=(pj_cnaes_list pj_qualificacoes_socios pj_empresas pj_empresas_cnaes pj_empresas_emails pj_empresas_enderecos pj_empresas_socios pj_empresas_telefones pj_naturezas_juridicas)

writeLog "============================================================================================================================="
writeLog "✅ Iniciando a TROCA de schema das tabelas de '$DB_SCHEMA' para o schema '$DB_SCHEMA_FINAL' "
echo

changeTablesSchemas() {
    for table in "${tables[@]}"; do
        writeLog "🔍 Verificando se a tabela '$DB_SCHEMA.$table' existe..."
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='$DB_SCHEMA' AND table_name='$table')" 2>&1)
        if [[ "$OUTPUT" == "f" ]]; then
            writeLog "❌ A tabela '$DB_SCHEMA.$table' não existe!"
            continue
        fi

        writeLog "🛑 Removendo '$DB_SCHEMA_FINAL.$table'..."
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "DROP TABLE IF EXISTS $DB_SCHEMA_FINAL.$table CASCADE" 2>&1 )
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao tentar EXCLUIR '$DB_SCHEMA_FINAL.$table'!"
            continue
        fi

        # Executando a troca do schema
        writeLog "📥 Alterando '$DB_SCHEMA.$table' para '$DB_SCHEMA_FINAL.$table'"
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "ALTER TABLE IF EXISTS $DB_SCHEMA.$table SET SCHEMA $DB_SCHEMA_FINAL;" 2>&1)
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao alterar '$DB_SCHEMA.$table' para '$DB_SCHEMA_FINAL.$table': $(echo "$OUTPUT" | tr -d '\n')"
        fi
        echo
    done
}

moveTablesSchemas() {
    local DB_SCHEMA_OLD="$DB_SCHEMA_FINAL"+"_OLD"
    writeLog "🔍 Criando o schema '$DB_SCHEMA_OLD'"
    OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "CREATE SCHEMA IF NOT EXISTS $DB_SCHEMA_OLD;" 2>&1)
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar o schema '$DB_SCHEMA_OLD': $(echo "$OUTPUT" | tr -d '\n')"
        exit 1
    fi
    echo

    writeLog "🔍 Movendo as tabelas do schema '$DB_SCHEMA_FINAL' para o schema '$DB_SCHEMA_OLD'"
    for table in "${tables[@]}"; do
        writeLog "🔍 Movendo '$DB_SCHEMA_FINAL.$table' para '$DB_SCHEMA_OLD.$table'"
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "ALTER TABLE IF EXISTS $DB_SCHEMA_FINAL.$table SET SCHEMA $DB_SCHEMA_OLD;" 2>&1)
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao alterar '$DB_SCHEMA_FINAL.$table' para '$DB_SCHEMA_OLD.$table': $(echo "$OUTPUT" | tr -d '\n')"
        fi
        echo
    done
}

moveTablesSchemas

changeTablesSchemas

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Troca de schema das tabelas do Schema \"$DB_SCHEMA\" para o Schema '$DB_SCHEMA_FINAL' finalizada em $(calculateExecutionTime $START_TIME_IMPORT)"
echo
