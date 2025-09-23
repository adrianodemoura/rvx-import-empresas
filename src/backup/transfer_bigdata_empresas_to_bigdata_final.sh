#!/bin/bash
#
source "./config/config.sh"
LOG_NAME_SUCCESS="backup_schemas"

writeLog "============================================================================================================================="
writeLog "✅ Iniciando a exportação do schema '$DB_SCHEMA' para o schema '$DB_SCHEMA_FINAL' "
echo

writeLog "📣 Checando diretório de backup..."
echo
docker exec -t $CONTAINER_NAME mkdir -p $DIR_BACKUP

TABLES=(pj_cnaes_list pj_qualificacoes_socios pj_empresas pj_empresas_cnaes pj_empresas_emails pj_empresas_enderecos pj_empresas_socios pj_empresas_telefones pj_empresas_juridicas)

for tbl in "${TABLES[@]}"; do
    START_TIME_IMPORT=$(date +%s%3N)

    EXISTS=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "SELECT to_regclass('${DB_SCHEMA_FINAL}.${tbl}');" | tr -d '[:space:]')
    [[ -n "$EXISTS" ]] && {
        writeLog "✅ Tabela $DB_SCHEMA_FINAL.$tbl já existe, pulando..."
        continue
    }

    # Cria tabela sem índices/constraints
    writeLog "⚡ Criando tabela $DB_SCHEMA_FINAL.$tbl (sem índices/constraints)"
    SQL="CREATE TABLE ${DB_SCHEMA_FINAL}.${tbl} (LIKE ${DB_SCHEMA}.${tbl} INCLUDING DEFAULTS INCLUDING GENERATED INCLUDING IDENTITY);"
    OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "$SQL" 2>&1)
    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao criar tabela \"$DB_SCHEMA_FINAL.$tbl\": $(echo "$OUTPUT" | tr -d '\n')" "$LOG_NAME_ERROR"
        exit 1
    fi

    # Copia os dados
    writeLog "📥 Copiando dados de $DB_SCHEMA.$tbl → $DB_SCHEMA_FINAL.$tbl"
    OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "COPY ${DB_SCHEMA}.${tbl} TO STDOUT" \
      | PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "COPY ${DB_SCHEMA_FINAL}.${tbl} FROM STDIN" 2>&1)

    if [[ $? -ne 0 ]]; then
        writeLog "❌ Erro ao copiar dados \"$DB_SCHEMA.$tbl\": $(echo "$OUTPUT" | tr -d '\n')" "$LOG_NAME_ERROR"
        exit 1
    fi

    writeLog "✅ Cópia de dados concluída em $(calculateExecutionTime $START_TIME_IMPORT)"
    echo

    # Recria índices
    writeLog "⚡ Recriando índices em $DB_SCHEMA_FINAL.$tbl"
    INDEXES=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "
        SELECT pg_get_indexdef(i.indexrelid) || ';'
        FROM pg_index i
        JOIN pg_class c ON c.oid = i.indrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = '${DB_SCHEMA}'
          AND c.relname = '${tbl}'
          AND NOT i.indisprimary;")
    if [[ -n "$INDEXES" ]]; then
        while IFS= read -r index_sql; do
            [[ -n "$index_sql" ]] && {
                OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "$index_sql" 2>&1)
                if [[ $? -ne 0 ]]; then
                    writeLog "❌ Erro ao recriar índice: $index_sql -> $OUTPUT"
                fi
            }
        done <<< "$INDEXES"
    fi

    # Recria constraints (PK, Unique, Foreign Keys)
    writeLog "⚡ Recriando constraints em $DB_SCHEMA_FINAL.$tbl"
    CONSTRAINTS=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -t -A -c "
        SELECT 'ALTER TABLE ${DB_SCHEMA_FINAL}.' || quote_ident(conrelid::regclass::text) || ' ADD CONSTRAINT ' || conname || ' ' || pg_get_constraintdef(oid) || ';'
        FROM pg_constraint
        WHERE connamespace = (SELECT oid FROM pg_namespace WHERE nspname='${DB_SCHEMA}')
          AND conrelid::regclass::text = '${DB_SCHEMA}.${tbl}';
    ")
    if [[ -n "$CONSTRAINTS" ]]; then
        while IFS= read -r con_sql; do
            [[ -n "$con_sql" ]] && {
                OUTPUT=$(PGPASSWORD="$DB_PASSWORD" "${PSQL_CMD[@]}" -c "$con_sql" 2>&1)
                if [[ $? -ne 0 ]]; then
                    writeLog "❌ Erro ao recriar constraint: $con_sql -> $OUTPUT"
                fi
            }
        done <<< "$CONSTRAINTS"
    fi

    writeLog "✅ Estruturas recriadas para $DB_SCHEMA_FINAL.$tbl"
    echo
done

# FIM
echo "---------------------------------------------------------------------------"
writeLog "✅ Importação de tabelas do Schema \"$DB_SCHEMA\" para o Schema '$DB_SCHEMA_FINAL' finalizada em $(calculateExecutionTime $START_TIME_IMPORT)"
echo
