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

# Atalho para conexão com o banco de dados no servidor de testes
readonly PSQL_CMD=(
  docker exec -i $POSTGRES_CONTAINER psql
  -U "$POSTGRES_DB_USER"
  -d "$POSTGRES_DB_DATABASE"
  -v PGPASSWORD="$POSTGRES_DB_PASSWORD"
)

# Atalho para conexão com o MongoDB (dentro do container)
readonly MONGO_CMD=(
  docker exec -i $MONGO_CONTAINER mongosh
  --quiet
  -u "$MONGODB_USER"
  -p "$MONGODB_PASSWORD"
  "$MONGODB_DATABASE"
)

# Atalho para conexão com o MongoDB Import (dentro do container)
readonly MONGOIMPORT_CMD=(
  docker exec -i $MONGO_CONTAINER mongoimport
  --quiet
  -u "$MONGODB_USER"
  -p "$MONGODB_PASSWORD"
  --db "$MONGODB_DATABASE"
)