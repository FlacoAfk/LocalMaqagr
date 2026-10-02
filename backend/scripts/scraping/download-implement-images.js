/**
 * Descarga la imagen principal de cada implemento cosechado (data/implements/*.json),
 * la convierte a WebP 960px/q65 (misma política del instalador que los tractores)
 * y actualiza image_url con /uploads/implements/...
 *
 * Uso:
 *   node download-implement-images.js [--dry-run] [--force] [--max-width=800] [--quality=55]
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';

/** Descarga binaria vía curl: el CDN de Baldan tiene TLS que el fetch de Node rechaza. */
function curlBinary(url) {
  return new Promise((resolve, reject) => {
    execFile(
      'curl',
      ['-sk', '-m', '40', '-L', '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', url],
      { maxBuffer: 30 * 1024 * 1024, encoding: 'buffer', timeout: 60000 },
      (err, stdout) => (err ? reject(err) : resolve(stdout)),
    );
  });
}

let sharp = null;
try {
  sharp = (await import('sharp')).default;
} catch {
  sharp = null; // fallback: guardar el original sin convertir
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, 'data', 'implements');
const INSTALL_DIR = path.resolve(__dirname, '..', '..', '..', 'install-assets', 'uploads', 'implements');
const DEV_DIR = path.resolve(__dirname, '..', '..', 'uploads', 'implements');

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const force = args.includes('--force');
const maxWidth = parseInt(args.find((a) => a.startsWith('--max-width='))?.split('=')[1] || '800', 10);
const quality = parseInt(args.find((a) => a.startsWith('--quality='))?.split('=')[1] || '55', 10);
const EXT = sharp ? '.webp' : '.jpg';

fs.mkdirSync(INSTALL_DIR, { recursive: true });
fs.mkdirSync(DEV_DIR, { recursive: true });

const files = fs.readdirSync(DATA_DIR).filter((f) => f.endsWith('.json'));
console.log(`🖼️  ${files.length} ficheros de implemento (máx ${maxWidth}px, q${quality}, ${sharp ? 'webp' : 'sin sharp'})\n`);

let ok = 0;
let skipped = 0;
let failed = 0;
let totalBytes = 0;
let counter = 0;
// Las variantes de un producto comparten imagen: caché url → buffer
const imgCache = new Map();

async function fetchCachedBinary(url) {
  if (imgCache.has(url)) return imgCache.get(url);
  const buf = await curlBinary(url);
  imgCache.set(url, buf);
  return buf;
}

for (const file of files) {
  const recordPath = path.join(DATA_DIR, file);
  const data = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
  // Los JSON de Baldan agrupan registros por producto; los del harvester genérico son un registro único
  const registros = data.registros || [data];

  for (let i = 0; i < registros.length; i++) {
    const r = registros[i];
    const url = r.main_image || (r.images && r.images[0]) || null;
    if (!url) { skipped++; continue; }
    if (r.image_url && !force) { skipped++; continue; }

    counter++;
    const baseName = path.basename(file, '.json').replace(/^baldan-/, 'baldan-') + (data.registros ? `-${i + 1}` : '');
    const localName = `${baseName}${EXT}`.slice(0, 100);
    const installPath = path.join(INSTALL_DIR, localName);
    const devPath = path.join(DEV_DIR, localName);

    if (dryRun) {
      console.log(`[dry-run] ${r.implement_name} → ${localName}`);
      continue;
    }

    try {
      // Candidatos en orden: imagen principal y resto de la galería
      const candidatos = [url, ...(r.images || [])].filter(Boolean);
      let buf = null;
      for (const c of candidatos) {
        try {
          const b = await fetchCachedBinary(c);
          if (b && b.length > 2000) { buf = b; break; } // ignora 404/páginas de error
        } catch { /* siguiente candidato */ }
      }
      if (!buf) throw new Error('sin imagen descargable');
      let finalBuf = buf;
      let finalKb = Math.round(buf.length / 1024);
      if (sharp) {
        try {
          const out = await sharp(buf).resize(maxWidth, null, { withoutEnlargement: true }).webp({ quality }).toBuffer();
          if (out.length <= buf.length) { finalBuf = out; finalKb = Math.round(out.length / 1024); }
        } catch (err) {
          console.log(`   ⚠️ conversión falló, original (${err.message?.slice(0, 60)})`);
        }
      }
      fs.writeFileSync(installPath, finalBuf);
      fs.copyFileSync(installPath, devPath);

      r.image_url = `/uploads/implements/${localName}`;
      r.fuente = r.fuente || {};
      r.fuente.imagen_original = url;
      r.fuente.imagen_calidad = `${finalKb} KB`;
      ok++;
      totalBytes += finalKb * 1024;
      console.log(`✅ ${r.implement_name} → ${localName} (${finalKb} KB)`);
    } catch (err) {
      failed++;
      console.log(`❌ ${r.implement_name} — ${err.message.slice(0, 80)}`);
    }
  }

  fs.writeFileSync(recordPath, JSON.stringify(data, null, 2) + '\n');
}

console.log(`\n📊 Imágenes: ${ok}, omitidas: ${skipped}, errores: ${failed}` +
  (ok ? ` | total ${Math.round(totalBytes / 1024)} KB (promedio ${Math.round(totalBytes / 1024 / ok)} KB)` : ''));
