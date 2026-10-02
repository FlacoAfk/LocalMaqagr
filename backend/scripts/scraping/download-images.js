/**
 * Descarga la foto principal de cada registro scrapeado, la re-comprime para
 * el instalador (calidad/peso mínimos con buena resolución) y actualiza
 * image_url con la ruta local (/uploads/tractors/...).
 *
 * Estrategia:
 *  - Prefiere la foto GRANDE de la ficha (photo_url_large); si no hay, usa la
 *    miniatura (photo_url).
 *  - Compresión para el instalador: WebP 1000px/q75 vía sharp (≈60-100 KB);
 *    si sharp no está disponible, JPEG q80/1200px vía System.Drawing.
 *  - Escribe en DOS sitios:
 *      install-assets/uploads/tractors/  → lo que empaqueta el instalador
 *      backend/uploads/tractors/         → copia para el servidor de desarrollo
 *
 * Uso:
 *   node download-images.js [--dry-run] [--force] [--max-width=1000] [--quality=75]
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';
import { fetchBinary, createFetcher } from './lib/http.js';

let sharp = null;
try {
  sharp = (await import('sharp')).default;
} catch {
  sharp = null; // fallback a JPEG/System.Drawing
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, 'data', 'tractors');
const INSTALL_DIR = path.resolve(__dirname, '..', '..', '..', 'install-assets', 'uploads', 'tractors');
const DEV_DIR = path.resolve(__dirname, '..', '..', 'uploads', 'tractors');

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const force = args.includes('--force');
const maxWidth = parseInt(args.find((a) => a.startsWith('--max-width='))?.split('=')[1] || '800', 10);
const quality = parseInt(args.find((a) => a.startsWith('--quality='))?.split('=')[1] || '55', 10);
const EXT = sharp ? '.webp' : '.jpg';

fs.mkdirSync(INSTALL_DIR, { recursive: true });
fs.mkdirSync(DEV_DIR, { recursive: true });

/** Re-comprime un JPEG con System.Drawing (.NET incluido en Windows). */
function recompress(file, maxW, q) {
  return new Promise((resolve) => {
    const script = `
      Add-Type -AssemblyName System.Drawing
      $f = '${file.replace(/'/g, "''")}'
      $img = [System.Drawing.Image]::FromFile($f)
      $w = $img.Width; $h = $img.Height
      if ($w -gt ${maxW}) {
        $nh = [int]($h * ${maxW} / $w)
        $bmp = New-Object System.Drawing.Bitmap(${maxW}, $nh)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = 'HighQualityBicubic'
        $g.DrawImage($img, 0, 0, ${maxW}, $nh)
        $g.Dispose()
      } else {
        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.DrawImage($img, 0, 0, $w, $h)
        $g.Dispose()
      }
      $img.Dispose()
      $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
      $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]${q})
      $tmp = $f + '.tmp'
      $bmp.Save($tmp, $codec, $ep)
      $bmp.Dispose()
      Move-Item -Force $tmp $f
      Write-Output ([math]::Round((Get-Item $f).Length/1KB))
    `;
    execFile('powershell', ['-NoProfile', '-Command', script], { timeout: 60000 }, (err, stdout) => {
      if (err) resolve(null);
      else resolve(parseInt(String(stdout).trim(), 10));
    });
  });
}

const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
console.log(`🖼️  ${files.length} registros en data/tractors (máx ${maxWidth}px, calidad ${quality})\n`);

let ok = 0;
let skipped = 0;
let failed = 0;
let totalBytes = 0;

// Los registros scrapeados con el parser viejo no traen photo_url_large:
// se resuelve on-demand desde la página -photos.html (queda guardado en el JSON).
const fetchHtml = createFetcher({ cacheDir: path.join(__dirname, 'data', 'cache'), minDelayMs: 700 });
function extractLargePhoto(html) {
  for (const tag of html.match(/<img[^>]+>/gi) || []) {
    if (/max-width:100%/i.test(tag) && /photos\/F\d+/i.test(tag)) {
      const m = tag.match(/src="([^"]+)"/i);
      if (m) return m[1];
    }
  }
  return null;
}
async function resolveLargePhoto(record, recordPath) {
  if (record.photo_url_large) return record.photo_url_large;
  if (!record.fuente?.url) return null;
  try {
    const html = await fetchHtml(record.fuente.url.replace(/\.html$/, '-photos.html'));
    const large = extractLargePhoto(html);
    if (large) {
      record.photo_url_large = large;
      fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n');
    }
    return large;
  } catch {
    return null;
  }
}

for (const file of files) {
  const recordPath = path.join(DATA_DIR, file);
  const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
  const largeUrl = await resolveLargePhoto(record, recordPath);
  const url = largeUrl || record.photo_url;
  if (!url) {
    skipped++;
    continue;
  }
  if (record.image_url && !force) {
    skipped++;
    continue;
  }

  const baseName = `td${record.tractor_data_id}`;
  const localName = `${baseName}${EXT}`;
  const installPath = path.join(INSTALL_DIR, localName);
  const devPath = path.join(DEV_DIR, localName);

  if (dryRun) {
    console.log(`[dry-run] ${record.name} → ${localName} (${record.photo_url_large ? 'foto grande' : 'miniatura'})`);
    continue;
  }

  try {
    const buf = await fetchBinary(url);
    let finalBuf = buf;
    let finalKb = Math.round(buf.length / 1024);

    if (sharp) {
      // Conversión desde el buffer en memoria: reabrir el archivo recién
      // escrito falla en Windows (antivirus mantiene el lock un instante).
      try {
        const out = await sharp(buf)
          .resize(maxWidth, null, { withoutEnlargement: true })
          .webp({ quality })
          .toBuffer();
        if (out.length <= buf.length) {
          finalBuf = out;
          finalKb = Math.round(out.length / 1024);
        }
      } catch (err) {
        console.log(`   ⚠️ conversión falló, se guarda el original (${err.message?.slice(0, 80)})`);
      }
      fs.writeFileSync(installPath, finalBuf);
    } else {
      fs.writeFileSync(installPath, buf);
      const kb = await recompress(installPath, 1200, 80);
      if (kb != null && kb * 1024 <= buf.length) finalKb = kb;
      else fs.writeFileSync(installPath, buf);
    }
    fs.copyFileSync(installPath, devPath);

    // Limpia la variante antigua (.jpg ↔ .webp) para no dejar huérfanos
    const oldExt = EXT === '.webp' ? '.jpg' : '.webp';
    for (const dir of [INSTALL_DIR, DEV_DIR]) {
      fs.rmSync(path.join(dir, `${baseName}${oldExt}`), { force: true });
    }

    record.image_url = `/uploads/tractors/${localName}`;
    record.fuente.foto_original = url;
    record.fuente.foto_calidad = `${sharp ? 'webp' : 'jpeg'} ${maxWidth}px/q${quality} → ${finalKb} KB`;
    fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n');
    ok++;
    totalBytes += finalKb * 1024;
    const tipo = record.photo_url_large ? 'grande' : 'miniatura';
    console.log(`✅ ${record.name} → ${localName} (${tipo}, ${finalKb} KB)`);
  } catch (err) {
    failed++;
    console.log(`❌ ${record.name} — ${err.message}`);
  }
}

console.log(
  `\n📊 Descargadas: ${ok}, omitidas: ${skipped}, errores: ${failed}` +
    (ok ? ` | total: ${Math.round(totalBytes / 1024)} KB (promedio ${Math.round(totalBytes / 1024 / ok)} KB/foto)` : ''),
);
if (ok) console.log('📦 Copiadas a install-assets/uploads/tractors (instalador) y backend/uploads/tractors (dev)');
if (dryRun) console.log('(dry-run: no se descargó nada)');
