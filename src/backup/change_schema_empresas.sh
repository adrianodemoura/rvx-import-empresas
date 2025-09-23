#!/bin/bash
# Altera o schema das tabelas de empresa para o bigdata_final
#
source "./config/config.sh"
LOG_NAME_SUCCESS="change_schemas"
tables=(pj_cnaes_list pj_qualificacoes_socios)

writeLog "============================================================================================================================="
writeLog "✅ Iniciando a TROCA de schema das tabelas de '$DB_SCHEMA' para o schema '$DB_SCHEMA_FINAL' "
echo

changeSchemas() {
    for table in "${tables[@]}"; do
        writeLog "🛑 Removendo '$DB_SCHEMA_FINAL.$table'..."
        # OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='$DB_SCHEMA' AND table_name='$table')" 2>&1)
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "DROP TABLE IF EXISTS $DB_SCHEMA_FINAL.$table CASCADE" 2>&1 )
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao tentar EXCLUIR '$DB_SCHEMA_FINAL.$table'!"
            continue
        fi

        # Se a tabela já existe, renomeia ela pra OLD
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='$DB_SCHEMA_FINAL' AND table_name='$table')" 2>&1)
        if [[ "$OUTPUT" == "t" ]]; then
            writeLog "✅ Tabela '$DB_SCHEMA_FINAL.$table' existe. Renomeando para '$table_old'..."
            OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "ALTER TABLE $DB_SCHEMA_FINAL.$table RENAME TO $table_old")
            if [[ $? -ne 0 ]]; then
                writeLog "❌ Erro ao renomear tabela '$DB_SCHEMA_FINAL.$table' para '$table_old'!"
            fi
        fi

        # Executando a troca do schema
        writeLog "📥 Alterando '$DB_SCHEMA.$table' para '$DB_SCHEMA_FINAL.$table'"
        OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "ALTER TABLE IF EXISTS $DB_SCHEMA.$table SET SCHEMA $DB_SCHEMA_FINAL;" 2>&1)
        if [[ $? -ne 0 ]]; then
            writeLog "❌ Erro ao alterar '$DB_SCHEMA.$table' para '$DB_SCHEMA_FINAL.$table': $(echo "$OUTPUT" | tr -d '\n')"
        fi

        # Se a cópia foi bem sucedida deleta a old
        
        echo
    done
}

changeSchemas

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Troca de schema das tabelas do Schema \"$DB_SCHEMA\" para o Schema '$DB_SCHEMA_FINAL' finalizada em $(calculateExecutionTime $START_TIME_IMPORT)"
echo
