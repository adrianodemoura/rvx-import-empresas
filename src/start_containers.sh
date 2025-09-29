#!/bin/bash
# Inicia os containers postgre-db e mongo-repl
source "./config/config.sh"
LOG_NAME='replicate'

writeLog "$(repeat_char '=')"
writeLog "🛑 Iniciando os containers..."

start_container() {
  local NAME=$1
  local RUN_CMD=$2

  if [ "$(docker ps -q -f name=^/${NAME}$)" ]; then
    writeLog "⚠️ Container '$NAME' já está rodando."
  elif [ "$(docker ps -aq -f name=^/${NAME}$)" ]; then
    writeLog "⚠️ Container '$NAME' existe mas está parado. Iniciando..."
    docker start "$NAME"
  else
    writeLog "🚀 Criando e iniciando container '$NAME'..."
    eval "$RUN_CMD"
  fi
}

# Postgres
start_container "postgres-db" "docker run --restart=always -d --name $POSTGRES_CONTAINER \
  -e TZ=America/Sao_Paulo \
  -e POSTGRES_PASSWORD=$POSTGRES_DB_PASSWORD \
  -v $(pwd)/storage:/storage \
  -v $POSTGRES_DIR_DATA:/var/lib/postgresql/data \
  -p $POSTGRES_DB_PORT:5432 \
  postgres:14.2-alpine"

# MongoDB
start_container "mongo-repl" "docker run --restart=always -d --name $MONGO_CONTAINER \
  -p $MONGODB_PORT:27017 \
  -v $MONGODB_DIR_DATA:/data/db \
  mongo:7"

# Cria usuário somente se não existir ou atualiza senha
docker exec -i mongo-repl mongosh <<EOF >/dev/null 2>&1
use $MONGODB_DATABASE
db.getUser("$MONGODB_USER") ? db.updateUser("$MONGODB_USER", { pwd: "$MONGODB_PASSWORD" }) : db.createUser({ user: "$MONGODB_USER", pwd: "$MONGODB_PASSWORD", roles: [{ role: "readWrite", db: "$MONGODB_DATABASE" }] })
EOF

writeLog "$(repeat_char '-')"
writeLog "✅ Todos os containers foram iniciados/verificados!"
writeLog "🐘 Postgres: $POSTGRES_DB_HOST:$POSTGRES_DB_PORT"
writeLog "🍃 MongoDB: $MONGODB_HOST:$MONGODB_PORT"
