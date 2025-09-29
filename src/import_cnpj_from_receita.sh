#!/bin/bash
# Importa as empresas da receita para o banco bigdata
#
source "./config/config.sh"

# ./src/import_temporarias/download_cnpj_zip_and_unzip.sh
# if [[ $? -ne 0 ]]; then
    # writeLog "❌ Erro ao tentar importar empresas!"
    # exit 1
# fi

./src/temporarias/import_empresas_tmp.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar importar empresas!"
    exit 1
fi

./src/bigdata/import_empresas.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar importar empresas para o schema $POSTGRES_DB_SCHEMA"
    exit 1
fi

./src/backup/change_schema_empresas.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar altera o schema de pj_empresas"
    exit 1
fi