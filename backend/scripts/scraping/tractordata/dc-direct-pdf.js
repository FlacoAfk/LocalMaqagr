/**
 * Convierte los enlaces de ficha técnica de Digital Commons a enlaces DIRECTOS
 * al PDF (cgi/viewcontent.cgi?article=NNN&context=SET), extrayéndolo de la
 * página del artículo. Así el botón abre el PDF sin pasar por la landing.
 *
 * Uso: node tractordata/dc-direct-pdf.js
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createFetcher } from '../lib/http.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data', 'tractors');

const fetchHtml = createFetcher({ cacheDir: path.join(__dirname, '..', 'data', 'cache'), minDelayMs: 800 });

function extractPdfUrl(articleHtml) {
  const m = articleHtml.match(/href="(https?:\/\/digitalcommons\.unl\.edu\/cgi\/viewcontent\.cgi\?[^"]+)"/i);
  return m ? m[1].replace(/&amp;/g, '&') : null;
}

async function main() {
  const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
  console.log(`📄 Reemplazando landing por PDF directo en los registros con enlace DC\n`);

  let ok = 0;
  let sinPdf = 0;

  for (const file of files) {
    const recordPath = path.join(DATA_DIR, file);
    const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
    const url = record.fuente?.nebraska_pdf;
    if (!url || !url.includes('digitalcommons.unl.edu') || /viewcontent/.test(url)) continue;

    try {
      const html = await fetchHtml(url);
      const pdfUrl = extractPdfUrl(html);
      if (pdfUrl) {
        record.fuente.nebraska_pdf = pdfUrl;
        fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n');
        ok++;
        console.log(`✅ ${record.name} → ${pdfUrl.slice(0, 75)}`);
      } else {
        sinPdf++;
        console.log(`⚠️  ${record.name} — sin viewcontent en la página`);
      }
    } catch (err) {
      sinPdf++;
      console.log(`❌ ${record.name} — ${err.message.slice(0, 60)}`);
    }
  }

  console.log(`\n📊 PDF directos: ${ok} | sin enlace directo: ${sinPdf}`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
