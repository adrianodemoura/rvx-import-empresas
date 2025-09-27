#!/bin/bash
#

# Inicio da contagem do tempo de execução
START_TIME=$(date +%s%3N)

# Carrega as variáveis de ambiente do arquivo .env e .local
source "./src/util/global.sh"
loadEnv ".env.local"
LOG_NAME="${DB_SCHEMA,,}"

# Recupera a data de origem, do arquivo raiz ou do site
DATA_ORIGEM=$(cat .data_origem 2>/dev/null)
if [[ ${#DATA_ORIGEM} -eq 0 ]]; then
  getLatestDir
  DATA_ORIGEM=$(cat .data_origem 2>/dev/null)
fi
if [[ ${#DATA_ORIGEM} -eq 0 ]]; then
  writeLog "❌ Impossível continuar sem a data de origem!"
  exit 1
fi

# Tratamento para CTRL+C
trap "writeLog '⛔ Cancelado pelo usuário'; kill 0; exit 130" INT TERM

# Atalho para conexão com o banco de dados no servidor de testes
readonly PSQL_CMD=(
  env
  PGPASSWORD="$POSTGRES_DB_PASSWORD"
  psql
  -h "$POSTGRES_DB_HOST"
  -p "$POSTGRES_DB_PORT"
  -U "$POSTGRES_DB_USER"
  -d "$POSTGRES_DB_DATABASE"
)

# Atalho para conexão com o MongoDB
readonly MONGO_CMD=(
  mongo
  --host "$MONGODB_HOST"
  --port "$MONGODB_PORT"
  -u "$MONGODB_USER"
  -p "$MONGODB_PASSWORD"
  "$MONGODB_DATABASE"
)
