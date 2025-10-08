# Função para repetir caracter
repeat_char() {
  printf "%0.s$1" $(seq 1 ${2:-99})
}

# função para escrever LOGs
writeLog() {
  [ $DEBUG == '0' ] && { return; }
  local msg="$1"
  local type="${2:-${LOG_NAME:-undefined}}"  # fallback encadeado
  local output="${3:-true}"

  # Só escreve no disco se o LOG está ativado
  if [ "$LOG" = "1" ]; then
    mkdir -p "$DIR_LOG"

    # Data atual no formato ANO_MES_DIA
    local log_date=$(date +'%Y_%m_%d')

    # Nome do arquivo com data + tipo
    local log_file="$DIR_LOG/${log_date}_$type.log"

    # Escreve a mensagem com timestamp de precisão milissegundos
    echo "[$(date +'%Y-%m-%d %H:%M:%S.%3N')] $msg" >> "$log_file"
  fi

  # Printa no console
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

# Função para descobri o último diretório disponível e sua data
getLatestDir() {
  # baixar HTML e colocar tudo em uma linha
  local HTML
  HTML=$(curl -s "$URL_BASE" | tr '\n' ' ')

  # pegar todos os diretórios YYYY-MM/ e pegar o último
  LATEST_DIR=$(echo "$HTML" \
    | grep -oP 'href="\d{4}-\d{2}/"' \
    | sed 's/href="//; s/"//g' \
    | sort \
    | tail -n1)

  # remover a barra final
  LATEST_DIR=${LATEST_DIR%/}

  # pegar o <tr> do último diretório
  local TR_LINE
  TR_LINE=$(echo "$HTML" | grep -oP "<tr>.*?href=\"$LATEST_DIR/\".*?</tr>")

  # pegar o segundo <td align="right"> (que contém a data) e extrair apenas YYYY-MM-DD
  # pegar a data correta do último diretório
  LATEST_DATE=$(echo "$HTML" \
    | grep -oP "href=\"$LATEST_DIR/\">$LATEST_DIR/.*?align=\"right\">[0-9]{4}-[0-9]{2}-[0-9]{2}" \
    | grep -oP "[0-9]{4}-[0-9]{2}-[0-9]{2}" \
    | head -n1)

  export LATEST_DIR
  export LATEST_DATE
}

# Função para recupear os atributos de uma tabela
getTableAttr() {
  local table_name="$1"
  local attr="$2"

  # percorre todas as entradas da constante TABLES
  for entry in "${TABLES[@]}"; do
    local table="${entry%%.*}"
    local rest="${entry#*.}"

    [ "$attr" == "name" ] && { echo $table; return 0; }

    if [[ "$table" == "$table_name" ]]; then
      [ "$attr" == "nick" ] && { echo $(echo "$entry" | cut -d '.' -f 2 | cut -d ' ' -f 1); return 0; }

      # procura o trecho do atributo solicitado, exemplo: fields. ou indexes.
      local value
      value=$(echo "$rest" | grep -oP "${attr}\.[^ ]+" | sed "s/${attr}\.//")
      if [[ -n "$value" ]]; then
        echo "$value"
        return 0
      else
        echo ""  # não encontrado
        return 1
      fi
    fi
  done

  echo "❌ Tabela '$table_name' não encontrada" >&2
  return 1
}
