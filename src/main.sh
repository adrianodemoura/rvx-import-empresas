#!/bin/bash
#
#
source "./config/config.sh"

./src/import_temporarias/download_cnpj_zip_and_unzip.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar importar empresas!"
    exit 1
fi

./src/import_temporarias/import_empresas_tmp.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar importar empresas!"
    exit 1
fi

./src/import_bigdata_empresas/import_empresas.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar importar empresas para o schema $DB_SCHEMA"
    exit 1
fi

./src/backup/change_schema_empresas.sh
if [[ $? -ne 0 ]]; then
    writeLog "❌ Erro ao tentar altera o schema de pj_empresas"
    exit 1
fi