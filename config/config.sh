#!/bin/bash
#

# Configurações para matar processo
# trap 'kill $(jobs -p)' EXIT

# Inicio da contagem do tempo de execução
readonly START_TIME=$(date +%s%3N)

# Carrega as variáveis de ambiente do arquivo .env e .local
source "./config/tables.sh"
source "./src/util/global.sh"
loadEnv ".env.local"
LOG_NAME="${DB_SCHEMA,,}"

# Recupera a data de origem, do arquivo raiz ou do site
DATA_ORIGEM=$(cat .data_origem 2>/dev/null)
if [[ ${#DATA_ORIGEM} -eq 0 ]]; then
  getLatestDir
  DATA_ORIGEM=$(cat .data_origem 2>/dev/null)
fi

# Atalho para conexão com o banco de dados local
readonly PSQL_CMD=( docker exec -i -e PGPASSWORD="$POSTGRES_DB_PASSWORD" $POSTGRES_CONTAINER 
  psql 
  -h "127.0.0.1" 
  -p "5432" 
  -U "$POSTGRES_DB_USER" 
  -d "$POSTGRES_DB_DATABASE"
)

# Atalho para conexão com o MongoDB (dentro do container)
readonly MONGO_CMD=( 
  docker exec -i $MONGO_CONTAINER mongosh --quiet 
  --port "27017" 
  --host "127.0.0.1" 
  -u "$MONGODB_USER" 
  -p "$MONGODB_PASSWORD" 
  "$MONGODB_DATABASE"
)
# Atalho para conexão com o MongoImport (dentro do container)
readonly MONGOIMPORT_CMD=( 
  docker exec -i $MONGO_CONTAINER mongoimport --quiet 
  --port "27017" 
  --host "127.0.0.1" 
  -u "$MONGODB_USER" 
  -p "$MONGODB_PASSWORD" 
  --db "$MONGODB_DATABASE"
)