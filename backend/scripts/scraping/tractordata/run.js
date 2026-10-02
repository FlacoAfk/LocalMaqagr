/**
 * Orquestador de scraping de tractores desde TractorData.com.
 * Por cada URL de modelo descarga 4 páginas (principal, dimensions, tests,
 * engine), parsea y guarda un JSON en data/tractors/<id>.json.
 *
 * Uso:
 *   node run.js --urls=data/catalog/massferg.txt --limit=20
 *   node run.js --url="https://www.tractordata.com/farm-tractors/005/7/9/5793-john-deere-5075e.html"
 *   node run.js --urls=data/catalog/all.txt --limit=50 --delay=1000
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createFetcher } from '../lib/http.js';
import { parseModel } from './parse-model.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.join(__dirname, '..', 'data', 'tractors');
const ERRORS_LOG = path.join(OUT_DIR, '_errors.log');

function parseArgs(argv) {
  const args = {};
  for (const a of argv) {
    const m = a.match(/^--([a-z-]+)(?:=(.*))?$/);
    if (m) args[m[1]] = m[2] ?? true;
  }
  return args;
}

async function scrapeOne(fetchHtml, url) {
  const base = url.replace(/\.html$/, '');
  // Secuencial para respetar el delay de cortesía entre peticiones
  const main = await fetchHtml(url);
  const dimensions = await fetchHtml(`${base}-dimensions.html`).catch(() => null);
  const tests = await fetchHtml(`${base}-tests.html`).catch(() => null);
  const engine = await fetchHtml(`${base}-engine.html`).catch(() => null);
  return parseModel({ main, dimensions, tests, engine }, url);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const limit = args.limit ? parseInt(args.limit, 10) : Infinity;
  const minDelayMs = args.delay ? parseInt(args.delay, 10) : 800;

  let urls = [];
  if (args.url) {
    urls = [args.url];
  } else if (args.urls) {
    const file = path.resolve(args.urls);
    urls = fs.readFileSync(file, 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
  } else {
    console.error('Uso: node run.js --urls=<archivo> | --url=<una URL> [--limit=N] [--delay=ms]');
    process.exit(1);
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const fetchHtml = createFetcher({
    cacheDir: path.join(__dirname, '..', 'data', 'cache'),
    minDelayMs,
  });

  const batch = urls.slice(0, limit === Infinity ? urls.length : limit);
  console.log(`🚜 Scraping ${batch.length} de ${urls.length} modelos (delay ${minDelayMs} ms)\n`);

  let ok = 0;
  let fail = 0;
  for (let i = 0; i < batch.length; i++) {
    const url = batch[i];
    const idMatch = url.match(/\/(\d+)-/);
    const id = idMatch ? idMatch[1] : String(i);
    const outFile = path.join(OUT_DIR, `${id}.json`);
    const label = `[${i + 1}/${batch.length}]`;

    if (fs.existsSync(outFile) && !args.force) {
      console.log(`${label} ⏭️  ya existe (${id}.json)`);
      continue;
    }

    try {
      const record = await scrapeOne(fetchHtml, url);
      if (!record.brand || !record.model || record.engine_power_hp == null) {
        throw new Error(`registro incompleto: brand=${record.brand} model=${record.model} hp=${record.engine_power_hp}`);
      }
      fs.writeFileSync(outFile, JSON.stringify(record, null, 2) + '\n');
      ok++;
      console.log(
        `${label} ✅ ${record.name} — ${record.engine_power_hp} hp, ${record.traction_type}, ${record.weight_kg ?? '?'} kg` +
          (record.traction_force_estimado ? ' (tiro estimado)' : ''),
      );
    } catch (err) {
      fail++;
      const line = `${new Date().toISOString()}\t${url}\t${err.message}\n`;
      fs.appendFileSync(ERRORS_LOG, line);
      console.log(`${label} ❌ ${url} — ${err.message}`);
    }
  }

  console.log(`\n📊 Completado: ${ok} ok, ${fail} errores${fail ? ` (detalle en ${path.basename(ERRORS_LOG)})` : ''}`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
