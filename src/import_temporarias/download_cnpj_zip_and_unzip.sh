#!/bin/bash
#
source "./config/config.sh"
readonly LOG_NAME_SUCCESS="success_csv_download"
readonly LOG_NAME_ERROR="error_csv_download"

writeLog "=====================================================================================================================" "$LOG_NAME_SUCCESS"
writeLog "⚠️ Iniciando a importação CSV às [$(date +'%Y-%m-%d %H:%M:%S.%3N')]..." "$LOG_NAME_SUCCESS"
echo

mkdir -p "$DIR_ZIP" "$DIR_CSV"

# Função para descobrir o último diretório disponível
get_latest_dir() {
  local url="$1"
  curl -s "$url" | grep '<tr>' | grep -v 'Parent Directory' | awk '
    match($0, /href="([0-9]{4}-[0-9]{2})\//, a) && match($0, /align="right">([0-9]{4}-[0-9]{2}-[0-9]{2})/, b) {
      print a[1], b[1]
    }
  ' | sort | tail -n 1
}

# Pegando os dados do site
LATEST_INFO=$(get_latest_dir "$URL_BASE")
LATEST_DIR=$(echo "$LATEST_INFO" | awk '{print $1}')
LATEST_DATE=$(echo "$LATEST_INFO" | awk '{print $2}')
writeLog "📁 Diretório mais recente: \"$LATEST_DIR\"" "$LOG_NAME_SUCCESS"
writeLog "📆 Data do diretório: $LATEST_DATE" "$LOG_NAME_SUCCESS"
echo "$LATEST_DATE" > "./.data_origem"

# Concatena a URL completa
URL_BASE_FULL="$URL_BASE$LATEST_DIR/"
writeLog "🌐 URL completa: $URL_BASE_FULL" "$LOG_NAME_SUCCESS"

downloadFiles() {
  mkdir -p "$DIR_ZIP"
  writeLog "⬇️ Baixando arquivos ZIP para $DIR_ZIP ..."

  curl -s "$URL_BASE_FULL" | grep -oP 'href="\K[^"]+\.zip(?=")' | while read -r zip_file; do
    if [ -f "$DIR_ZIP/$zip_file" ]; then
      writeLog "📄 Arquivo $zip_file já existe, pulando..." "$LOG_NAME_SUCCESS"
    else
      writeLog "⬇️ Baixando $zip_file ..." "$LOG_NAME_SUCCESS"
      curl -# -o "$DIR_ZIP/$zip_file" "$URL_BASE_FULL$zip_file"
    fi
  done

  writeLog "⬇️  Download de $(du -h "$DIR_ZIP") concluído." "$LOG_NAME_SUCCESS"
  echo
}

unzipFiles() {
  for zip_file in "$DIR_ZIP"/*.zip; do
    if [ -f "$zip_file" ]; then
      ZIP_FILENAME=$(basename "$zip_file")
      ZIP_FILENAME_WITH_CSV="${ZIP_FILENAME%.zip}"
      CSV_FILENAME=$(unzip -l "$zip_file" | awk 'NR==4 {print $4}')
      writeLog "⬇️ Descompactando $CSV_FILENAME -  $ZIP_FILENAME_WITH_CSV -  $ZIP_FILENAME para $DIR_CSV ..." "$LOG_NAME_SUCCESS"

      # Se arquivo já existe, pula
      if [ -f "$DIR_CSV/${ZIP_FILENAME_WITH_CSV,,}.csv" ]; then
        writeLog "📄 Arquivo ${ZIP_FILENAME_WITH_CSV,,}.csv já existe, pulando..." "$LOG_NAME_SUCCESS"
        continue
      fi

      # Descompacta o arquivo .zip para o diretório de CSV
      unzip -o "$zip_file" -d "$DIR_CSV"

      # renomeia o arquivo extraído
      if [ -f "$DIR_CSV/$CSV_FILENAME" ]; then
        mv -f "$DIR_CSV/$CSV_FILENAME" "$DIR_CSV/${ZIP_FILENAME_WITH_CSV,,}.csv"
        writeLog "✅ Renomeado para: $ZIP_FILENAME_WITH_CSV" "$LOG_NAME_SUCCESS"
      else
        writeLog "❌ Arquivo $CSV_FILENAME não encontrado após unzip" "$LOG_NAME_ERROR"
      fi
    fi
  done
  echo
}

subscribeFiles() {
  for csv_file in "$DIR_CSV"/*.csv; do

    # estabelecimentos
    if [[ $csv_file == *"estabelecimentos"* ]]; then
      writeLog "🛑 Removendo caracter nulo em $csv_file"
      sed -i 's/\x0//g' "$csv_file" || writeLog "❌ Erro ao tentar remover caracter nulo de $csv_file"
    fi

    # sócios
    if [[ $csv_file == *"socios"* ]]; then
      writeLog "🛑 Removendo asterisco em $csv_file"
      sed -i 's/\*\*\*//g; s/\*\*//g' "$csv_file" || writeLog "❌ Erro ao tentar remover * de cpf em $csv_file"
    fi
  done
}

# Baixando os arquivos ZIP
downloadFiles

# Descompactando os arquivos ZIP para CSV
unzipFiles

# Subscreve alguns arquivos
subscribeFiles

# FIM
echo "---------------------------------------------------------------------------"
writeLog "⚠️ Fim do download CSV em $(calculateExecutionTime)" "$LOG_NAME_SUCCESS"
echo