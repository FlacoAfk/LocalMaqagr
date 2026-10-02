/**
 * Scraper de implementos Baldan (WooCommerce, español).
 *
 * Nota: baldan.com.br tiene una cadena TLS incompleta (falla el fetch nativo
 * de Node), así que las descargas van vía curl -k. robots.txt permite el
 * rastreo de contenido público.
 *
 * Cada producto puede tener VARIANles en su tabla de especificaciones
 * (p. ej. "AF 2/3/4/5 discos"): se genera un registro por variante, que es
 * lo que el motor de recomendaciones necesita (ancho/peso/potencia reales).
 *
 * Uso:
 *   node implementos/baldan.js                        # catálogo completo (241 productos)
 *   node implementos/baldan.js --limit=10             # prueba
 *   node implementos/baldan.js --urls=archivo.txt     # catálogo alternativo
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';
import { stripTags, firstH1, pageText } from '../lib/html.js';
import { tableToGrid, mergeHeaderRows, tablesFromHtml } from '../lib/table-grid.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.join(__dirname, '..', 'data', 'implements');
const CACHE_DIR = path.join(__dirname, '..', 'data', 'cache', 'baldan');
const CATALOG = path.join(__dirname, '..', 'data', 'catalog', 'baldan-productos-es.txt');

const BRAND = 'Baldan';
const LICENCE_NOTE =
  'Datos factuales del catálogo público de Baldan (baldan.com.br), obtenidos del sitio oficial. Uso como referencia del catálogo local de MaqAgr; conservar atribución.';

// ── Tipos MaqAgr a partir de la categoría/categoría-produto y el nombre ──
const CATEGORY_TYPE = {
  arados: 'plow',
  'grades-aradoras': 'harrow',
  'grades-niveladoras': 'harrow',
  'grades': 'harrow',
  sembradoras: 'seeder',
  cultivadores: 'cultivator',
  escarificadores: 'subsoiler',
  subsoladores: 'subsoiler',
  'implementos-rotativos': 'implemento_rotativo',
  pulverizadores: 'pulverizador',
  carretas: 'carreta',
  distribuidores: 'distribuidor',
  'conjuntos-frontales': 'otro',
  'discos-baldan': 'repuesto',
  diversos: 'otro',
};

const NAME_TYPE = [
  [/arado.*disco|disc.*plough/i, 'plow'],
  [/abonador|fertilizadora|fertilizer|distribution de fertilizante/i, 'abonador'],
  [/arado/i, 'plow'],
  [/grade|harrow|rastra/i, 'harrow'],
  [/sembradora|seeder|plantadeira/i, 'seeder'],
  [/subsolador|escarificador|riper|chisel/i, 'subsoiler'],
  [/cultivador/i, 'cultivator'],
  [/rotativo|rotagolpe|rotavator|distribuidor de rastrojo/i, 'implemento_rotativo'],
  [/pulverizador|sprayer|pulveriz/i, 'pulverizador'],
  [/carreta|trailer/i, 'carreta'],
];

function parseArgs(argv) {
  const args = {};
  for (const a of argv) {
    const m = a.match(/^--([a-z-]+)(?:=(.*))?$/);
    if (m) args[m[1]] = m[2] ?? true;
  }
  return args;
}

/** Descarga vía curl -k (TLS de Baldan rechaza el CA store de Node). */
function curlGet(url) {
  return new Promise((resolve, reject) => {
    execFile('curl', ['-sk', '-m', '30', '-L', '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', url], { maxBuffer: 10 * 1024 * 1024 }, (err, stdout) => {
      if (err) reject(err);
      else resolve(stdout);
    });
  });
}

async function fetchCached(url) {
  const key = url.replace(/[^a-z0-9]+/gi, '_').slice(-100) + '.html';
  const file = path.join(CACHE_DIR, key);
  if (fs.existsSync(file)) return fs.readFileSync(file, 'utf8');
  const html = await curlGet(url);
  fs.writeFileSync(file, html);
  return html;
}

/** Punto medio de un rango "40-50" → 45 */
function midpoint(range) {
  const nums = String(range).match(/\d+(?:[.,]\d+)?/g);
  if (!nums || !nums.length) return null;
  const vals = nums.map((n) => parseFloat(n.replace(',', '.')));
  return Math.round((Math.min(...vals) + Math.max(...vals)) / 2 * 10) / 10;
}

/** Identifica el rol de una columna por su encabezado */
function columnRole(header) {
  const h = header.toLowerCase();
  if (/modelo/.test(h)) return 'modelo';
  if (/disco/.test(h)) return 'n_discos';
  if (/ancho/.test(h)) return 'ancho';
  if (/peso/.test(h)) return 'peso';
  if (/potencia|cv|hp/.test(h)) return 'potencia';
  if (/profund/.test(h)) return 'profundidad';
  if (/linea|hilera|surco|bico|punta|diente|reja|tine/.test(h)) return 'n_lineas';
  if (/diametro|diámetro/.test(h)) return 'diametro';
  return null;
}

function guessType(text, breadcrumb) {
  for (const slug of breadcrumb) if (CATEGORY_TYPE[slug]) return CATEGORY_TYPE[slug];
  for (const [re, tipo] of NAME_TYPE) if (re.test(text)) return tipo;
  return 'otro';
}

/** Extrae la categoría-produto de los breadcrumbs del HTML */
function extractBreadcrumbs(html) {
  return [...new Set(
    (html.match(/categoria-produto\/([a-z-]+)\//g) || []).map((s) => s.replace('categoria-produto/', '').replace('/', '')),
  )];
}

function extractGallery(html) {
  const imgs = [...new Set(
    (html.match(/https:\/\/midias\.baldan\.com\.br\/wp-content\/uploads\/[^"'\s]+\.(?:jpe?g|png|webp)/gi) || []),
  )]
    .filter((u) => !/badge|logo|iso|bandeira|flag|icon|fav/i.test(u))
    // ".jpg.webp" → ".jpg" (el original existe); los ".webp" puros se quedan igual
    .map((u) => (u.endsWith('.jpg.webp') ? u.slice(0, -5) : u));
  return [...new Set(imgs)].slice(0, 6);
}

function parseProduct(html, url) {
  const title = (firstH1(html) || '').trim() || url.split('/').filter(Boolean).pop().replace(/-/g, ' ');
  const breadcrumb = extractBreadcrumbs(html);
  const gallery = extractGallery(html);
  const ogMatch = html.match(/property="og:image"[^>]*content="([^"]+)"/i)
    || html.match(/content="([^"]+)"[^>]*property="og:image"/i);
  const ogImage = ogMatch ? ogMatch[1].replace(/\.webp$/i, '') : null;

  const text = pageText(html);
  const descripcionCorta =
    (html.match(/<meta name="description" content="([^"]+)"/i) || [])[1]
    || text.slice(0, 300);

  // ── Tabla(s) de especificaciones → variantes ──
  const variants = [];
  const specTables = [];
  for (const tableHtml of tablesFromHtml(html)) {
    const grid = tableToGrid(tableHtml);
    const merged = mergeHeaderRows(grid);
    const headers = merged ? merged.headers : grid[0];
    const dataRows = merged ? merged.dataRows : grid.slice(1);
    const roles = headers.map(columnRole);
    if (!roles.some(Boolean)) continue;

    specTables.push({ headers, filas: dataRows });

    for (const row of dataRows) {
      const v = {};
      roles.forEach((role, c) => {
        if (!role) return;
        v[role] = v[role] ?? row[c];
      });
      // Solo filas con al menos un dato numérico
      if (Object.values(v).some((x) => /\d/.test(x ?? ''))) variants.push(v);
    }
  }

  return { title, breadcrumb, gallery, ogImage, descripcionCorta, variants, specTables, text };
}

function variantToRecord(base, v, idx) {
  const modelo = (v.modelo || '').trim();
  // Nombre por variante: producto + modelo (si varía entre filas) o
  // nº de discos/líneas o ancho. Productos de una sola variante: solo el título.
  let nombre = base.title;
  if (base.variants.length > 1) {
    const modelos = new Set(base.variants.map((x) => (x.modelo || '').trim()).filter(Boolean));
    if (modelo && modelos.size > 1) nombre = `${base.title} ${modelo}`;
    else if (v.n_discos) nombre = `${base.title} ${v.n_discos} discos`;
    else if (v.n_lineas) nombre = `${base.title} ${v.n_lineas} líneas`;
    else if (v.ancho) nombre = `${base.title} ${v.ancho}`;
    else nombre = `${base.title} ${idx + 1}`;
  }

  const anchoMm = parseFloat(String(v.ancho || '').replace(',', '.'));
  const pesoVal = parseFloat(String(v.peso || '').replace(',', '.'));
  const potencia = v.potencia ? midpoint(v.potencia) : null;
  const discos = parseInt(String(v.n_discos || '').match(/\d+/)?.[0], 10)
    ?? parseInt(String(v.n_lineas || '').match(/\d+/)?.[0], 10)
    ?? null;

  return {
    fuente: {
      sitio: 'baldan.com.br',
      url: base.url,
      categoria: base.breadcrumb[0] ?? null,
      licencia: LICENCE_NOTE,
      recuperado: new Date().toISOString(),
    },
    implement_name: nombre.slice(0, 150),
    brand: BRAND,
    power_requirement_hp: potencia,
    power_origen: v.potencia ?? null,
    working_width_m: Number.isFinite(anchoMm) ? Math.round((anchoMm / 1000) * 1000) / 1000 : null,
    working_depth_cm: v.profundidad ? parseFloat(String(v.profundidad).replace(',', '.')) || null : null,
    n_tines: Number.isFinite(discos) ? discos : null,
    weight_kg: Number.isFinite(pesoVal) ? pesoVal : null,
    implement_type: guessType(base.title, []),
    variante: modelo || null,
    variante_idx: idx,
    images: base.gallery,
    main_image: base.ogImage || base.gallery[0] || null,
    image_url: null,
    descripcion: base.descripcionCorta,
    specs: { ficha_tecnica: base.specTables },
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const limit = args.limit ? parseInt(args.limit, 10) : Infinity;
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  fs.mkdirSync(OUT_DIR, { recursive: true });

  let urls;
  if (args.urls) urls = fs.readFileSync(path.resolve(args.urls), 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
  else urls = fs.readFileSync(CATALOG, 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);

  const batch = urls.slice(0, limit);
  console.log(`🔧 Baldan: ${batch.length} de ${urls.length} productos\n`);

  let ok = 0;
  let sinTabla = 0;
  let fail = 0;
  let records = 0;

  for (let i = 0; i < batch.length; i++) {
    const url = batch[i];
    const slug = url.split('/').filter(Boolean).pop();
    const outFile = path.join(OUT_DIR, `baldan-${slug}.json`);
    if (fs.existsSync(outFile) && !args.force) {
      continue;
    }
    const label = `[${i + 1}/${batch.length}]`;
    try {
      const html = await fetchCached(url);
      const parsed = parseProduct(html, url);
      if (!parsed.variants.length) {
        sinTabla++;
        console.log(`${label} ⚠️  sin tabla de especificaciones: ${parsed.title}`);
        continue;
      }
      const recs = parsed.variants.map((v, idx) => variantToRecord({ ...parsed, url }, v, idx));
      fs.writeFileSync(outFile, JSON.stringify({ producto: parsed.title, url, registros: recs }, null, 2) + '\n');
      ok++;
      records += recs.length;
      const v0 = recs[0];
      console.log(`${label} ✅ ${parsed.title} (${recs.length} variantes) — ${v0.working_width_m ?? '?'}m, ${v0.weight_kg ?? '?'}kg, ${v0.power_requirement_hp ?? '?'}hp, tipo: ${v0.implement_type}`);
    } catch (err) {
      fail++;
      console.log(`${label} ❌ ${url} — ${err.message.slice(0, 90)}`);
    }
  }

  console.log(`\n📊 Productos: ${ok} con tabla, ${sinTabla} sin tabla, ${fail} errores → ${records} registros de implemento`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
