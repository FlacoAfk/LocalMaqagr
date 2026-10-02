/**
 * Extrae datos de llantas desde las fichas técnicas PDF de los tractores
 * prioritarios que les faltan (búsqueda real en el documento del fabricante).
 *
 * Busca patrones "Traseras 13.6 x 28 / Delanteras 8 x 18", "Rear 14.9-28",
 * "LLANTAS", "NEUMÁTICOS", "RUEDAS Y GOMAS"… en el texto del PDF y llena
 * tire_type / tire_width_mm / tire_diameter_mm con el neumático trasero.
 *
 * Uso: node extract-tires-from-pdf.js [--dry-run]
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';
import { pool } from '../../src/config/db.js';
import { parseTire } from './lib/numbers.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PDF_DIR = path.join(__dirname, 'data', 'fichas-pdf');
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126';
let lastAt = 0;

function curlBinary(url) {
  return new Promise((resolve, reject) => {
    const wait = Math.max(0, 600 - (Date.now() - lastAt));
    setTimeout(() => {
      lastAt = Date.now();
      execFile('curl', ['-sk', '-m', '60', '-L', '-A', UA, url], { maxBuffer: 40 * 1024 * 1024, encoding: 'buffer', timeout: 80000 }, (err, stdout) => (err ? reject(err) : resolve(stdout)));
    }, wait);
  });
}

function normalizeToken(s) {
  return s.replace(/\s+/g, '').replace(',', '.');
}

/** Extrae llanta trasera (preferida) y delantera del texto del PDF. */
function extractTires(text) {
  const rear = text.match(/(?:trasera\w*|rear)\s*[:]?\s*(\d{1,2}(?:[.,]\d+)?)\s*[x\-]\s*(\d{1,2}(?:[.,]\d+)?)/i);
  const front = text.match(/(?:delantera\w*|front)\s*[:]?\s*(\d{1,2}(?:[.,]\d+)?)\s*[x\-]\s*(\d{1,2}(?:[.,]\d+)?)/i);
  return { rear: rear ? `${normalizeToken(rear[1])}-${normalizeToken(rear[2])}` : null, front: front ? `${normalizeToken(front[1])}-${normalizeToken(front[2])}` : null };
}

async function main() {
  const rows = (await pool.query(
    "SELECT tractor_id, name, ficha_pdf_url, image_url FROM tractor WHERE prioridad = TRUE AND ficha_pdf_url IS NOT NULL AND (tire_type IS NULL OR tire_width_mm IS NULL OR tire_diameter_mm IS NULL)",
  )).rows;
  console.log(`📕 ${rows.length} prioritarios sin llantas, con ficha PDF — extrayendo del documento\n`);

  const { PDFParse } = await import('pdf-parse');
  fs.mkdirSync(PDF_DIR, { recursive: true });

  let ok = 0;
  let sinDato = 0;
  let fail = 0;

  for (const t of rows) {
    const local = path.join(PDF_DIR, `td${t.tractor_id}.pdf`);
    try {
      if (!fs.existsSync(local)) {
        const buf = await curlBinary(t.ficha_pdf_url);
        if (buf.length < 5000 || buf.slice(0, 5).toString() !== '%PDF-') {
          throw new Error('el enlace no sirve un PDF');
        }
        fs.writeFileSync(local, buf);
      }
      const parser = new PDFParse({ data: new Uint8Array(fs.readFileSync(local)) });
      const doc = await parser.getText();
      const text = doc.text.replace(/[ \t]+/g, ' ');
      const { rear, front } = extractTires(text);
      const chosen = rear || front;
      const tire = chosen ? parseTire(chosen) : null;
      if (tire) {
        if (!dryRun) {
          await pool.query(
            'UPDATE tractor SET tire_type = $1, tire_width_mm = $2, tire_diameter_mm = $3 WHERE tractor_id = $4',
            [`${tire.radial ? 'Radial' : 'Diagonal'} ${tire.original}`, tire.width_mm, tire.diameter_mm_est, t.tractor_id],
          );
        }
        ok++;
        console.log(`✅ ${t.name} → ${rear ? `trasera ${rear}` : `delantera ${front}`} (${tire.width_mm} mm, Ø${tire.diameter_mm_est} mm)`);
      } else {
        sinDato++;
        console.log(`⚠️  ${t.name} — sin patrón de llantas en el PDF`);
      }
    } catch (err) {
      fail++;
      console.log(`❌ ${t.name} — ${err.message.slice(0, 70)}`);
    }
  }

  console.log(`\n📊 llantas extraídas de PDF: ${ok} | sin dato en el documento: ${sinDato} | ficha no descargable: ${fail}`);
}

main().catch(async (e) => {
  console.error('❌', e);
  try { await pool.end(); } catch { /* noop */ }
});
