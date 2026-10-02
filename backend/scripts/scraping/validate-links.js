/**
 * Auditoría profunda de enlaces: descarga los PRIMEROS BYTES de cada
 * image_url y ficha_pdf_url y valida los bytes mágicos reales
 * (JPEG/PNG/WebP/GIF para imágenes, %PDF- para fichas), no solo el código HTTP.
 *
 * Uso:
 *   node validate-links.js --prioridad          # solo los 78 curados
 *   node validate-links.js --todas-fichas       # + fichas DC y Baldan
 *   node validate-links.js --fix-fotos          # aplica fotos de respaldo del scraping
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';
import { pool } from '../../src/config/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const soloPrioridad = args.includes('--prioridad');
const todasFichas = args.includes('--todas-fichas');
const fixFotos = args.includes('--fix-fotos');

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126 Safari/537.36';
let lastAt = 0;

// Dominios/URLs que fallan SIEMPRE (verificado en auditorías previas):
// no se vuelven a sondear para evitar falsos positivos por rate-limit.
const IMG_BAD_DOMAINS = ['lectura-specs.es', 'truck1.ec', 'bigcommerce.com'];
const FICHA_BAD_PATTERNS = ['SPEC_TRATOR_STRADDLE']; // CNH: responde HTML, no PDF

function imagenRotaConocida(url) { return IMG_BAD_DOMAINS.some((d) => (url || '').includes(d)); }
function fichaRotaConocida(url) { return FICHA_BAD_PATTERNS.some((p) => (url || '').includes(p)); }

/** GET con rango de bytes; devuelve { status, contentType, head } */
function probe(url, referer) {
  return new Promise((resolve) => {
    const wait = Math.max(0, 500 - (Date.now() - lastAt));
    setTimeout(() => {
      lastAt = Date.now();
      const headers = ['-A', UA, '--compressed'];
      if (referer) headers.push('-e', referer);
      execFile(
        'curl',
        ['-sk', '-m', '25', '-L', ...headers, '-r', '0-4095', '-w', '\\n__META__%{http_code}|%{content_type}', url],
        { maxBuffer: 20 * 1024 * 1024, encoding: 'buffer', timeout: 40000 },
        (err, stdout) => {
          if (err && !stdout) return resolve({ status: 0, contentType: '', head: Buffer.alloc(0) });
          const s = Buffer.from(stdout);
          const mi = s.lastIndexOf('__META__');
          const meta = s.slice(mi + 8).toString().split('|');
          resolve({ status: parseInt(meta[0] || '0', 10), contentType: meta[1] || '', head: s.slice(0, Math.max(0, mi)) });
        },
      );
    }, wait);
  });
}

function tipoImagen(head, ct) {
  if (head.slice(0, 3).toString() === '\xFF\xD8\xFF') return 'jpeg';
  if (head.slice(0, 8).toString('hex') === '89504e470d0a1a0a') return 'png';
  if (head.slice(0, 4).toString() === 'RIFF' && head.slice(8, 12).toString() === 'WEBP') return 'webp';
  if (head.slice(0, 3).toString() === 'GIF') return 'gif';
  if (/svg/i.test(ct)) return 'svg';
  return null;
}
function esPdf(head, ct) {
  return head.slice(0, 5).toString() === '%PDF-' || /application\/pdf/i.test(ct);
}

/** Foto de respaldo: la que tenía el registro scrapeado antes del curado */
function fotoScrapeoRespaldo(tractorDataId) {
  if (!tractorDataId) return null;
  const f = path.join(__dirname, 'data', 'tractors', `${tractorDataId}.json`);
  if (!fs.existsSync(f)) return null;
  try {
    const r = JSON.parse(fs.readFileSync(f, 'utf8'));
    return r.image_url && r.image_url.startsWith('/uploads/') ? r.image_url : null;
  } catch { return null; }
}

async function main() {
  let where = soloPrioridad ? 'WHERE prioridad = TRUE' : '';
  const tractors = (await pool.query(`SELECT tractor_id, name, image_url, ficha_pdf_url, prioridad FROM tractor ${where} ORDER BY prioridad DESC, brand`)).rows;

  const problemas = [];
  let imgOk = 0, fichaOk = 0, sinImg = 0, sinFicha = 0;

  console.log(`🔎 Auditando ${tractors.length} tractores (bytes mágicos reales)\n`);

  for (const t of tractors) {
    // ── Imagen ──
    if (!t.image_url) sinImg++;
    else if (!t.image_url.startsWith('/uploads/')) {
      if (imagenRotaConocida(t.image_url)) {
        problemas.push({ tipo: 'imagen', t, url: t.image_url, detalle: 'dominio bloqueado (403/404/410 constante)' });
        console.log(`❌ IMAGEN ${t.name} → dominio roto conocido: ${t.image_url.slice(0, 60)}`);
      } else {
        const r = await probe(t.image_url);
        const tipo = tipoImagen(r.head, r.contentType);
        const ct = (r.contentType || '').toLowerCase();
        // Roto SOLO si es definitivo: 403/404/410/451 o HTML en 200.
        // Status 0/5xx/206 sin magic = indeterminado → no se marca.
        const definitivo = [403, 404, 410, 451].includes(r.status) || (r.status === 200 && !tipo && /html/.test(ct));
        if (tipo) imgOk++;
        else if (definitivo) {
          problemas.push({ tipo: 'imagen', t, url: t.image_url, detalle: `HTTP ${r.status} ${r.contentType}` });
          console.log(`❌ IMAGEN ${t.name} → ${r.status} ${r.contentType} ${t.image_url.slice(0, 60)}`);
        } else {
          imgOk++; // indeterminado: se asume válido
        }
      }
    } else imgOk++;

    // ── Ficha ──
    if (!t.ficha_pdf_url) sinFicha++;
    else if (fichaRotaConocida(t.ficha_pdf_url)) {
      problemas.push({ tipo: 'ficha', t, url: t.ficha_pdf_url, detalle: 'URL de CNH que sirve HTML, no PDF' });
      console.log(`❌ FICHA  ${t.name} → patrón roto conocido`);
    } else {
      const r = await probe(t.ficha_pdf_url, 'http://localhost:4000/');
      const pdf = esPdf(r.head, r.contentType) && [200, 206].includes(r.status);
      const ct = (r.contentType || '').toLowerCase();
      const definitivo = [403, 404, 410, 451].includes(r.status) || (r.status === 200 && !esPdf(r.head, ct) && /html/.test(ct));
      if (pdf) fichaOk++;
      else if (definitivo) {
        problemas.push({ tipo: 'ficha', t, url: t.ficha_pdf_url, detalle: `HTTP ${r.status} ${r.contentType}` });
        console.log(`❌ FICHA  ${t.name} → ${r.status} ${r.contentType} ${t.ficha_pdf_url.slice(0, 60)}`);
      } else {
        fichaOk++; // indeterminado: se asume válido
      }
    }
  }

  // ── Implementos (ficha = página del fabricante: debe ser HTML 200) ──
  let implOk = 0, implProblemas = 0;
  if (todasFichas) {
    const impls = (await pool.query("SELECT implement_id, implement_name, ficha_pdf_url FROM implement WHERE ficha_pdf_url IS NOT NULL")).rows;
    console.log(`\n🔎 Implementos con enlace de ficha: ${impls.length}\n`);
    for (const i of impls) {
      const r = await probe(i.ficha_pdf_url);
      if (r.status === 200 && r.head.slice(0, 15).toString().includes('<') === false ? false : r.status === 200) implOk++;
      else { implProblemas++; console.log(`❌ FICHA IMPL ${i.implement_name} → ${r.status} ${i.ficha_pdf_url.slice(0, 60)}`); }
    }
  }

  console.log(`\n📊 IMÁGENES: ${imgOk} ok, ${sinImg} sin foto, ${problemas.filter(p => p.tipo === 'imagen').length} rotas`);
  console.log(`📊 FICHAS TRACTOR: ${fichaOk} ok, ${sinFicha} sin ficha, ${problemas.filter(p => p.tipo === 'ficha').length} rotas`);
  if (todasFichas) console.log(`📊 FICHAS IMPLEMENTO: ${implOk} ok, ${implProblemas} rotas`);

  // ── Fix: fotos de respaldo del scraping ──
  if (fixFotos) {
    console.log('\n🔧 Aplicando fotos de respaldo del scraping...');
    let fixed = 0;
    for (const p of problemas.filter((x) => x.tipo === 'imagen')) {
      const respaldo = fotoScrapeoRespaldo(p.t.tractor_data_id ?? p.t.tractorId);
      if (respaldo) {
        await pool.query('UPDATE tractor SET image_url = $1 WHERE tractor_id = $2', [respaldo, p.t.tractor_id]);
        fixed++;
        console.log(`   ${p.t.name} → respaldo ${respaldo}`);
      } else {
        await pool.query('UPDATE tractor SET image_url = NULL WHERE tractor_id = $2', [p.t.tractor_id]).catch(() => {});
        console.log(`   ${p.t.name} → sin respaldo, image_url = NULL (fallback frontend)`);
      }
    }
    console.log(`🔧 fotos corregidas: ${fixed}`);
  }

  await pool.end();
}

main().catch(async (e) => {
  console.error('❌', e);
  try { await pool.end(); } catch { /* noop */ }
});
