#!/bin/bash
# Inicia os banco postgre, redis e mongoDB
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
start_container "postgres-db" "docker run --restart=always -d --name postgres-db \
  -e TZ=America/Sao_Paulo \
  -e POSTGRES_PASSWORD=$POSTGRES_DB_PASSWORD \
  -v $POSTGRES_DIR_DATA:/var/lib/postgresql/data \
  -p $POSTGRES_DB_PORT:5432 \
  postgres:14.2-alpine"

# Redis Stack
start_container "redis-stack" "docker run -d --name redis-stack --restart=always \
  -p $REDIS_PORT:6379 \
  -p $REDIS_PORT_WEB:8001 \
  -v $REDIS_DIR_DATA:/data \
  redis/redis-stack:latest"

# -------------------------------
# MongoDB
# -------------------------------
# inicia o mongoDB
start_container "mongo-repl" "docker run -d --name mongo-repl \
  --restart=always \
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
writeLog "🗄 Redis: localhost:$REDIS_PORT (UI: localhost:$REDIS_PORT_WEB)"
writeLog "🍃 MongoDB: $MONGODB_HOST:$MONGODB_PORT"
