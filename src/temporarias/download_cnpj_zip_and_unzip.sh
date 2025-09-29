#!/bin/bash
#
source "./config/config.sh"
LOG_NAME="download_cnpj_zip_and_unzip"

writeLog "=====================================================================================================================" "$LOG_NAME_SUCCESS"
writeLog "⚠️ Iniciando a importação CSV às [$(date +'%Y-%m-%d %H:%M:%S.%3N')]..."
echo

mkdir -p "$DIR_ZIP" "$DIR_CSV"

#
writeLog "📁 Diretório mais recente: \"$LATEST_DIR\""
writeLog "📆 Data do diretório: $LATEST_DATE"

# Concatena a URL completa
URL_BASE_FULL="$URL_BASE$LATEST_DIR/"
writeLog "🌐 URL completa: $URL_BASE_FULL"

downloadFiles() {
  mkdir -p "$DIR_ZIP"
  writeLog "⬇️ Baixando arquivos ZIP para $DIR_ZIP ..."

  curl -s "$URL_BASE_FULL" | grep -oP 'href="\K[^"]+\.zip(?=")' | while read -r zip_file; do
    if [ -f "$DIR_ZIP/$zip_file" ]; then
      writeLog "📄 Arquivo $zip_file já existe, pulando..."
    else
      writeLog "⬇️ Baixando $zip_file ..."
      curl -# -o "$DIR_ZIP/$zip_file" "$URL_BASE_FULL$zip_file"
    fi
  done

  writeLog "⬇️  Download de $(du -h "$DIR_ZIP") concluído."
  echo
}

unzipFiles() {
  for zip_file in "$DIR_ZIP"/*.zip; do
    if [ -f "$zip_file" ]; then
      ZIP_FILENAME=$(basename "$zip_file")
      ZIP_FILENAME_WITH_CSV="${ZIP_FILENAME%.zip}"
      CSV_FILENAME=$(unzip -l "$zip_file" | awk 'NR==4 {print $4}')
      writeLog "⬇️ Descompactando $CSV_FILENAME -  $ZIP_FILENAME_WITH_CSV -  $ZIP_FILENAME para $DIR_CSV ..."

      # Se arquivo já existe, pula
      if [ -f "$DIR_CSV/${ZIP_FILENAME_WITH_CSV,,}.csv" ]; then
        writeLog "📄 Arquivo ${ZIP_FILENAME_WITH_CSV,,}.csv já existe, pulando..."
        continue
      fi

      # Descompacta o arquivo .zip para o diretório de CSV
      unzip -o "$zip_file" -d "$DIR_CSV"

      # renomeia o arquivo extraído
      if [ -f "$DIR_CSV/$CSV_FILENAME" ]; then
        mv -f "$DIR_CSV/$CSV_FILENAME" "$DIR_CSV/${ZIP_FILENAME_WITH_CSV,,}.csv"
        writeLog "✅ Renomeado para: $ZIP_FILENAME_WITH_CSV"
      else
        writeLog "❌ Arquivo $CSV_FILENAME não encontrado após unzip"
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
writeLog "⚠️ Fim do download CSV em $(calculateExecutionTime)"
echo