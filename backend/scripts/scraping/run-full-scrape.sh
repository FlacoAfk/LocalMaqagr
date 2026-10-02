#!/bin/bash
# Scraping completo del catálogo TractorData — autorizado por el usuario 2026-09-30
cd "$(dirname "$0")"
LOG=data/full-run.log
echo "[$(date '+%F %T')] INICIO scraping completo (12 marcas, 4102 modelos)" > "$LOG"
for brand in johndeere massferg ford newholland kubota caseih case fiat belarus challenger zetor deutz; do
  echo "[$(date '+%F %T')] === MARCA: $brand ===" >> "$LOG"
  node tractordata/run.js --urls="data/catalog/$brand.txt" --delay=800 >> "$LOG" 2>&1
  echo "[$(date '+%F %T')] --- imágenes acumuladas ---" >> "$LOG"
  node download-images.js >> "$LOG" 2>&1
done
echo "[$(date '+%F %T')] IMPORTACIÓN FINAL A POSTGRES" >> "$LOG"
node import.js >> "$LOG" 2>&1
echo "[$(date '+%F %T')] FIN — ver data/tractors/*.json y $LOG" >> "$LOG"
