#!/bin/bash
#

# Inicio da contagem do tempo de execução
START_TIME=$(date +%s%3N)

# Carrega as variáveis de ambiente do arquivo .env e correspondente: local, dev, prod
source "./src/util/global.sh"
loadEnv ".env.local"

# Atalho para conexão com o banco de dados no servidor de testes
PSQL_CMD=(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DATABASE")

# Atalho para conexão com o banco de dados no servidor de produção (somente leitura)
PROD_PSQL_CMD=(psql -h "$PROD_DB_HOST" -p "$PROD_DB_PORT" -U "$PROD_DB_USER" -d "$PROD_DB_DATABASE")