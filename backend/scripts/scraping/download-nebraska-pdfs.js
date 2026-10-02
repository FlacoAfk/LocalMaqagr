/**
 * Descarga las fichas técnicas PDF (pruebas Nebraska) de los tractores
 * scrapeados que tienen fuente.nebraska_pdf.
 *
 * Los URLs originales de tractortestlab.unl.edu hoy devuelven 404 (el lab
 * reestructuró su sitio): se descargan desde Wayback Machine con el patrón
 * web/<año>id_/, probando varios años y respetando sus límites (delay largo
 * y backoff ante 429).
 *
 * NOTA DE PESO: cada PDF pesa ~0.1-3 MB. NO se copian a install-assets;
 * dataset de referencia en data/nebraska-pdf/.
 *
 * Uso:
 *   node download-nebraska-pdfs.js [--limit=N] [--force]
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, 'data', 'tractors');
const PDF_DIR = path.join(__dirname, 'data', 'nebraska-pdf');

const args = process.argv.slice(2);
const force = args.includes('--force');
const limit = args.find((a) => a.startsWith('--limit='))?.split('=')[1];

fs.mkdirSync(PDF_DIR, { recursive: true });

const YEARS = ['2020', '2019', '2021', '2022', '2023', '2024'];
const DELAY_MS = 6000;

let lastAt = 0;
function curlBinary(url) {
  return new Promise((resolve, reject) => {
    const wait = Math.max(0, DELAY_MS - (Date.now() - lastAt));
    setTimeout(() => {
      lastAt = Date.now();
      execFile(
        'curl',
        ['-sk', '-m', '90', '-L', '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', url],
        { maxBuffer: 40 * 1024 * 1024, encoding: 'buffer', timeout: 100000 },
        (err, stdout) => (err ? reject(err) : resolve(stdout)),
      );
    }, wait);
  });
}

async function downloadPdf(originalUrl) {
  for (const year of YEARS) {
    try {
      const buf = await curlBinary(`https://web.archive.org/web/${year}id_/${originalUrl}`);
      if (buf.length > 5000 && buf.slice(0, 5).toString() === '%PDF-') return buf;
      const head = buf.slice(0, 200).toString();
      if (head.includes('429') || head.toLowerCase().includes('too many')) {
        // Rate limit de Wayback: pausa larga y reintentar el mismo año
        await new Promise((r) => setTimeout(r, 45000));
        const retry = await curlBinary(`https://web.archive.org/web/${year}id_/${originalUrl}`);
        if (retry.length > 5000 && retry.slice(0, 5).toString() === '%PDF-') return retry;
      }
    } catch { /* siguiente año */ }
  }
  return null;
}

const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
const pendientes = [];
for (const f of files) {
  const r = JSON.parse(fs.readFileSync(path.join(DATA_DIR, f), 'utf8'));
  if (r.fuente?.nebraska_pdf) pendientes.push(r);
}
const batch = limit ? pendientes.slice(0, parseInt(limit, 10)) : pendientes;
console.log(`📕 ${batch.length} de ${pendientes.length} fichas PDF por descargar vía Wayback (destino: data/nebraska-pdf/)\n`);

let ok = 0;
let skipped = 0;
let failed = 0;
let totalBytes = 0;

for (const r of batch) {
  const localName = `td${r.tractor_data_id}.pdf`;
  const localPath = path.join(PDF_DIR, localName);
  if (fs.existsSync(localPath) && !force) { skipped++; continue; }
  try {
    const buf = await downloadPdf(r.fuente.nebraska_pdf);
    if (!buf) throw new Error('sin copia en Wayback');
    fs.writeFileSync(localPath, buf);
    totalBytes += buf.length;
    ok++;
    console.log(`✅ ${r.name} → ${localName} (${Math.round(buf.length / 1024)} KB)`);
  } catch (err) {
    failed++;
    console.log(`❌ ${r.name} — ${err.message.slice(0, 70)}`);
  }
}

console.log(`\n📊 PDFs: ${ok} ok, ${skipped} ya estaban, ${failed} errores` +
  (ok ? ` | total ${Math.round(totalBytes / 1048576)} MB` : ''));
