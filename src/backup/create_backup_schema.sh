#!/bin/bash
# Executa o backup do SCHEMA via pg_dump
#
source "./config/config.sh"
LOG_NAME_SUCCESS="pg_dump"
# TABLES=(pj_cnaes_list pj_qualificacoes_socios pj_naturezas_juridicas)
# TABLES=(pf_pessoas pj_cnaes_list)
# TABLE_OPTIONS=$(printf -- "-t %s.%s " "$POSTGRES_DB_SCHEMA_FINAL" "${TABLES[@]}")

writeLog "$(repeat_char '=')"
writeLog "✅ Iniciando o Backup '$PROD_POSTGRES_DB_HOST.$PROD_POSTGRES_DB_DATABASE.$POSTGRES_DB_SCHEMA_FINAL' (postgres) para CACHE."
echo ""

readonly PG_DUMP=(
    docker exec -i -e PGPASSWORD="$PROD_POSTGRES_DB_PASSWORD" $POSTGRES_CONTAINER 
    pg_dump
    -h '127.0.0.1'
    -p '5432'
    -U $PROD_POSTGRES_DB_USER
    -d $PROD_POSTGRES_DB_DATABASE
)

"${PG_DUMP[@]}" -n $POSTGRES_DB_SCHEMA_FINAL -Fc -Z 9 -f "$DIR_CACHE/$POSTGRES_DB_SCHEMA_FINAL.dump"
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao executar BACKUP de '$POSTGRES_DB_SCHEMA_FINAL'!"
    exit 1
fi
writeLog "✅ Sucesso ao executar BACKUP de '$POSTGRES_DB_SCHEMA_FINAL' em $(calculateExecutionTime)"
echo ""