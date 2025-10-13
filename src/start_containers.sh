#!/bin/bash
# Inicia os containers postgre-db e mongo-repl
source "./config/config.sh"
LOG_NAME='start_containers'

writeLog "$(repeat_char '=')"
writeLog "🛑 Iniciando os containers..."

start_container() {
  local NAME=$1
  local RUN_CMD=$2

  if [ "$(docker ps -q -f name=^/${NAME}$)" ]; then
    writeLog "📣 Container '$NAME' já está rodando."
  elif [ "$(docker ps -aq -f name=^/${NAME}$)" ]; then
    writeLog "📣 Container '$NAME' existe mas está parado. Iniciando..."
    docker start "$NAME"
  else
    writeLog "🚀 Criando e iniciando container '$NAME'..."
    eval "$RUN_CMD"
  fi
}

# Postgres
start_container $POSTGRES_CONTAINER "docker run --restart=always -d --name $POSTGRES_CONTAINER \
  --cpuset-cpus=0-5 \
  --memory=10g \
  -e TZ=America/Sao_Paulo \
  -e POSTGRES_PASSWORD=$POSTGRES_DB_PASSWORD \
  -v $(pwd)/storage:/storage \
  -v $POSTGRES_DIR_DATA:/var/lib/postgresql/data \
  -p $POSTGRES_DB_PORT:5432 \
  postgres:14.2-alpine \
  -c max_wal_size=3GB"

# MongoDB
start_container $MONGO_CONTAINER "docker run --restart=always -d --name $MONGO_CONTAINER \
  -p $MONGODB_PORT:27017 \
  -v $MONGODB_DIR_DATA:/data/db \
  mongo:7"

writeLog "$(repeat_char '-')"
writeLog "✅ Todos os containers foram iniciados/verificados!"
writeLog "🐘 Postgres: $POSTGRES_DB_HOST:$POSTGRES_DB_PORT"
writeLog "🍃 MongoDB: $MONGODB_HOST:$MONGODB_PORT"
