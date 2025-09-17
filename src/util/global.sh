# função para escrever LOGs
writeLog() {
  local msg="$1"
  local type="${2:-${LOG_NAME_SUCCESS:-undefined}}"  # fallback encadeado
  local output="${3:-true}"

  mkdir -p "$DIR_LOG"

  # Data atual no formato ANO_MES_DIA
  local log_date
  log_date=$(date +'%Y_%m_%d')

  # Nome do arquivo com data + tipo
  local log_file="$DIR_LOG/${log_date}_$type.log"

  # Escreve a mensagem com timestamp de precisão milissegundos
  echo "[$(date +'%Y-%m-%d %H:%M:%S.%3N')] $msg" >> "$log_file"
  if [ "$output" = "true" ]; then
    echo "$msg"
  fi
}

# função para calcular o tempo de execução
calculateExecutionTime() {
  local start_time="${1:-START_TIME}" # Padrão para 'START_TIME' se não fornecido
  local end_time
  end_time=$(date +%s%3N)

  # Diferença em ms
  local duration_ms=$((end_time - start_time))

  # Quebra em horas, minutos, segundos e ms
  local hours=$((duration_ms / 3600000))
  local minutes=$(( (duration_ms % 3600000) / 60000 ))
  local seconds=$(( (duration_ms % 60000) / 1000 ))
  local millis=$((duration_ms % 1000))

  # Formata bonitinho
  local time_spend=$(printf "%02d:%02d:%02d.%03d\n" "$hours" "$minutes" "$seconds" "$millis")
  echo $time_spend
}

# Função para carregar variáveis do .env
loadEnv() {
  local ENV_FILE="${1}"

  if [[ -f "$ENV_FILE" ]]; then
      # exporta automaticamente as variáveis
      set -a

      # carrega o .env
      source "./.env"

      # carrega o .env específico
      source "$ENV_FILE"  
      set +a
  else
      echo "❌ Arquivo .env não encontrado em: $ENV_FILE"
      exit 1
  fi
}

# Função que retorna a chave de um array
getFields() {
  local -n tables_ref=$1   # referência para o array passado
  local table_name="$2"
  local entry

  entry=$(printf "%s\n" "${tables_ref[@]}" | grep "^$table_name=" | sed 's/ //g')

  echo "${entry#*=}" | xargs
}

# Função para formatar números
format_number() {
  if [[ $1 =~ \. ]]; then
    printf "%'.2f\n" "$1"
  else
    printf "%'.0f\n" "$1"
  fi
}

