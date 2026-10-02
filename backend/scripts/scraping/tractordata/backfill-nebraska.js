/**
 * Backfill del enlace a la ficha técnica PDF (prueba Nebraska) para los
 * registros scrapeados antes de que el parser lo extrajera. Usa el caché
 * HTML de las páginas -tests.html cuando existe.
 *
 *   node tractordata/backfill-nebraska.js
 */
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';
import { createFetcher } from '../lib/http.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data', 'tractors');
const CACHE_DIR = path.join(__dirname, '..', 'data', 'cache');

function extractPdfLink(testsHtml) {
  const m =
    testsHtml.match(/href="([^"]*(?:\.pdf[^"]*|get_file\?uuid=[^"]*))"[^>]*>\s*Nebraska[^<]*test[^<]*file/i) ||
    testsHtml.match(/href="(http[^"]*tractortestlab[^"]*)"/i);
  return m ? m[1].replace(/&amp;/g, '&') : null;
}

async function main() {
  const fetchHtml = createFetcher({ cacheDir: CACHE_DIR, minDelayMs: 700 });
  const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
  console.log(`📄 ${files.length} registros — backfill de enlace Nebraska PDF\n`);

  let added = 0;
  let sinTest = 0;
  let conEnlace = 0;

  for (const file of files) {
    const recordPath = path.join(DATA_DIR, file);
    const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
    if (record.fuente?.nebraska_pdf) { conEnlace++; continue; }
    const testsUrl = record.fuente?.tests_url;
    if (!testsUrl) { sinTest++; continue; }

    try {
      const key = crypto.createHash('sha1').update(testsUrl).digest('hex');
      const cached = path.join(CACHE_DIR, `${key}.html`);
      let html;
      if (fs.existsSync(cached)) html = fs.readFileSync(cached, 'utf8');
      else html = await fetchHtml(testsUrl);

      const link = extractPdfLink(html);
      if (link) {
        record.fuente.nebraska_pdf = link;
        fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n');
        added++;
      } else {
        sinTest++;
      }
    } catch {
      sinTest++;
    }
  }

  console.log(`✅ enlace añadido: ${added} | ya lo tenían: ${conEnlace} | sin prueba publicada: ${sinTest}`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
