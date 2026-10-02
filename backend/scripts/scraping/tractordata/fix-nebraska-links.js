/**
 * Reemplaza los enlaces muertos de tractortestlab.unl.edu por los artículos
 * de UNL Digital Commons, emparejando por número de prueba Nebraska (único).
 *
 * 1. Extrae "Nebraska Tractor Test NNN" de la página -tests.html cacheada
 * 2. Busca NNN en el índice de Digital Commons (harvest-dc-index.js)
 * 3. Actualiza fuente.nebraska_pdf del JSON; sin match → enlace NULL
 *
 * Uso: node tractordata/fix-nebraska-links.js
 */
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';
import { createFetcher } from '../lib/http.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data', 'tractors');
const CACHE_DIR = path.join(__dirname, '..', 'data', 'cache');
const INDEX_FILE = path.join(__dirname, '..', 'data', 'nebraska-dc-index.json');

const index = JSON.parse(fs.readFileSync(INDEX_FILE, 'utf8'));
const fetchHtml = createFetcher({ cacheDir: CACHE_DIR, minDelayMs: 700 });

async function main() {
  const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
  console.log(`🔗 ${files.length} registros — emparejando con ${Object.keys(index).length} informes de Digital Commons\n`);

  let actualizados = 0;
  let sinPrueba = 0;
  let sinMatch = 0;
  let yaOk = 0;

  for (const file of files) {
    const recordPath = path.join(DATA_DIR, file);
    const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
    const testsUrl = record.fuente?.tests_url;
    if (!testsUrl) { sinPrueba++; continue; }

    // Número de prueba desde el caché (o red si no está cacheado)
    let testHtml;
    try {
      const key = crypto.createHash('sha1').update(testsUrl).digest('hex');
      const cached = path.join(CACHE_DIR, `${key}.html`);
      testHtml = fs.existsSync(cached) ? fs.readFileSync(cached, 'utf8') : await fetchHtml(testsUrl);
    } catch { sinPrueba++; continue; }

    const numMatch = testHtml.match(/Nebraska\s+Tractor\s+Test\s+(\d+)/i);
    if (!numMatch) {
      if (record.fuente.nebraska_pdf) { record.fuente.nebraska_pdf = null; fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n'); }
      sinPrueba++;
      continue;
    }

    const testNum = parseInt(numMatch[1], 10);
    const hit = index[testNum];
    if (!hit) {
      if (record.fuente.nebraska_pdf) { record.fuente.nebraska_pdf = null; fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n'); }
      sinMatch++;
      continue;
    }

    const nuevaUrl = hit.url;
    if (record.fuente.nebraska_pdf === nuevaUrl) { yaOk++; continue; }
    record.fuente.nebraska_pdf = nuevaUrl;
    record.fuente.nebraska_test = testNum;
    fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n');
    actualizados++;
  }

  console.log(`✅ enlaces actualizados a Digital Commons: ${actualizados}`);
  console.log(`   ya correctos: ${yaOk} | sin prueba publicada: ${sinPrueba} | prueba sin informe en DC: ${sinMatch}`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
