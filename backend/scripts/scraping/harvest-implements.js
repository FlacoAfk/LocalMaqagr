/**
 * Cosechador genérico de implementos: dada una lista de URLs de páginas de
 * producto (fabricante, distribuidor, catálogo B2B), extrae título, marca,
 * todas las tablas/listas de especificaciones y las imágenes, e intenta el
 * mapeo al esquema de la tabla `implement` de MaqAgr.
 *
 * Los sitios modernos de fabricantes (Baldan, Tatu, Basso, Semeato…) son
 * SPAs o están tras Cloudflare: para esos casos usar automatización de
 * navegador (skill browser-use de ZCode) y guardar el HTML renderizado con
 * --html=<archivo>, que este script también acepta.
 *
 * Uso:
 *   node harvest-implements.js --urls=urls.txt --brand=Baldan
 *   node harvest-implements.js --html=pagina.html --url="https://…" --brand=Baldan --type=subsolador
 *
 * Salida: data/implements/<slug>.json — revisar/curar antes de importar.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createFetcher } from './lib/http.js';
import { allRows, splitTables, pageText, firstH1 } from './lib/html.js';
import { parseUnitPairs, pickUnit, toNumber } from './lib/numbers.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.join(__dirname, 'data', 'implements');

// ── Tipos válidos en el catálogo MaqAgr (Tabla 1 + genéricos) ──
const TIPOS = new Set([
  'plow', 'harrow', 'seeder', 'cultivator', 'subsoiler',
  'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
  'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
  'rastra_pesada_26', 'rastra_pesada_24',
]);

const TIPO_KEYWORDS = [
  [/(arado).*disco.*vertedera|vertedera/i, 'arado_disco_vertedera'],
  [/subsol[ae]|riper|ripper/i, 'subsolador'],
  [/arado.*cincel|cincel|chisel/i, 'arado_cincel'],
  [/rastra.*26/i, 'rastra_pesada_26'],
  [/rastra.*24/i, 'rastra_pesada_24'],
  [/rastrillo|pulidor|californiano/i, 'rastrillo_californiano'],
  [/rotagolpe|rotativo|rotavator|power harrow/i, 'implemento_rotativo'],
  [/grade|harrow|rastra/i, 'harrow'],
  [/arado|plough|plow/i, 'plow'],
  [/sembradora|seeder|plantadeira|plantadora/i, 'seeder'],
  [/cultivad|escarificad|cultivator/i, 'cultivator'],
];

function guessType(text) {
  for (const [re, tipo] of TIPO_KEYWORDS) if (re.test(text)) return tipo;
  return null;
}

/** Busca un valor numérico cuyo contexto combine con los patrones. */
function findSpec(rows, text, unitPrefs) {
  for (const row of rows) {
    const label = (row.label || row.section || '').toLowerCase();
    for (const pat of text) {
      if (pat.test(label)) {
        const v = pickUnit(parseUnitPairs(row.value ?? row.section ?? ''), unitPrefs);
        if (v != null) return { value: v, origen: row.label || row.section };
      }
    }
  }
  // Buscar en el texto completo de la página como último recurso
  const t = text;
  void t;
  return null;
}

function parseArgs(argv) {
  const args = {};
  for (const a of argv) {
    const m = a.match(/^--([a-z-]+)(?:=(.*))?$/);
    if (m) args[m[1]] = m[2] ?? true;
  }
  return args;
}

function extract(html, url, overrides = {}) {
  const rows = allRows(html);
  const text = pageText(html);
  const h1 = firstH1(html) || (html.match(/<title>([^<]*)/i)?.[1]?.trim() ?? null);

  const specsTables = splitTables(html).map((t) =>
    t.map((r) => ({ etiqueta: r.label || r.section, valor: r.value ?? '' })),
  );

  // ── Mapeo best-effort al esquema implement ──
  const power = findSpec(rows, [/potencia requerida|potencia necesaria|potencia recomendad|required power|power required|potência/i], ['hp']);
  const width = findSpec(rows, [/ancho de trabajo|ancho util|ancho útil|working width|largura de trabalho|ancho de labor/i], ['m', 'cm', 'mm', 'in']);
  const depth = findSpec(rows, [/profundidad de trabajo|profundidad|working depth|profundidade/i], ['cm', 'mm', 'in']);
  const weight = findSpec(rows, [/^peso|peso aproximado|peso total|weight|massa|mass$|peso bruto/i], ['kg', 'lb']);
  const tines = findSpec(rows, [/n[uú]mero de (puntas|discos|dientes|rejas)|no. of tines|number of (tines|discs|shanks)|bicos/i], ['']);

  // Conversión simple de unidades para anchura/profundidad
  const conv = (v, unit) => {
    if (v == null) return null;
    if (unit === 'cm') return Math.round((v / 100) * 100) / 100;
    if (unit === 'mm') return Math.round((v / 1000) * 1000) / 1000;
    if (unit === 'in') return Math.round((v * 0.0254) * 1000) / 1000;
    return v;
  };
  const unitOf = (hit) => {
    if (!hit) return null;
    const u = (hit.origen.match(/(\d+(?:[.,]\d+)?)\s*(m\b|cm|mm|in\b|")/i) || [])[2];
    return u === '"' ? 'in' : u || 'm';
  };

  const widthVal = width ? pickUnit(parseUnitPairs(width.origen), ['m', 'cm', 'mm', 'in']) : null;
  const depthVal = depth ? pickUnit(parseUnitPairs(depth.origen), ['cm', 'mm', 'in']) : null;
  const weightVal = weight ? pickUnit(parseUnitPairs(weight.origen), ['kg', 'lb']) : null;
  const weightKg = weightVal != null
    ? (weight.origen.match(/kg/i) ? weightVal : Math.round(weightVal * 0.45359237 * 10) / 10)
    : null;

  const name = overrides.name || (h1 || '').replace(/\s*[|–-]\s*[^|–-]*(fabrica|manufacturer|site|oficial).*$/i, '').trim();
  const tipoDetectado = overrides.type || guessType(`${name} ${text.slice(0, 3000)}`);

  const images = [...new Set(
    (html.match(/<img[^>]+src="([^"]+\.(?:jpe?g|png|webp))"/gi) || [])
      .map((tag) => tag.match(/src="([^"]+)"/i)?.[1])
      .filter(Boolean)
      .filter((src) => !/logo|icon|banner|whatsapp|facebook|instagram/i.test(src))
      .map((src) => (src.startsWith('http') ? src : url ? new URL(src, url).href : src)),
  )].slice(0, 8);

  return {
    fuente: {
      url: url || 'archivo local',
      recuperado: new Date().toISOString(),
      nota: 'Revisar y curar antes de importar. Campos NOT NULL: implement_name, brand, power_requirement_hp, working_width_m, implement_type.',
    },
    implement_name: name,
    brand: overrides.brand || null,
    power_requirement_hp: power?.value ?? null,
    power_origen: power?.origen ?? null,
    working_width_m: conv(widthVal, unitOf(width && { origen: width.origen })),
    working_depth_cm: depthVal != null ? conv(depthVal, unitOf(depth && { origen: depth.origen })) : null,
    n_tines: tines ? toNumber(String(tines.origen).match(/\d+/)?.[0]) : null,
    weight_kg: weightKg,
    implement_type: tipoDetectado,
    images,
    specs: specsTables,
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const targets = [];
  if (args.html) {
    targets.push({ html: fs.readFileSync(path.resolve(args.html), 'utf8'), url: args.url || null });
  }
  if (args.urls) {
    const urls = fs.readFileSync(path.resolve(args.urls), 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
    const fetchHtml = createFetcher({ cacheDir: path.join(__dirname, 'data', 'cache'), minDelayMs: 1000 });
    for (const url of urls) {
      try {
        targets.push({ html: await fetchHtml(url), url });
      } catch (err) {
        console.log(`❌ ${url} — ${err.message}`);
      }
    }
  }
  if (!targets.length) {
    console.log('Uso: node harvest-implements.js --urls=<archivo> | --html=<archivo> --url=<origen> [--brand=X] [--type=Y]');
    process.exit(1);
  }

  let ok = 0;
  for (const { html, url } of targets) {
    const record = extract(html, url, { brand: args.brand, type: args.type });
    const slug =
      (record.implement_name || 'implemento')
        .toLowerCase()
        .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
        .slice(0, 60) || 'implemento';
    const outFile = path.join(OUT_DIR, `${slug}.json`);
    fs.writeFileSync(outFile, JSON.stringify(record, null, 2) + '\n');
    ok++;
    const pendientes = [
      record.brand ? null : 'brand',
      record.power_requirement_hp ? null : 'power_requirement_hp',
      record.working_width_m ? null : 'working_width_m',
      record.implement_type && TIPOS.has(record.implement_type) ? null : `implement_type=${record.implement_type}`,
    ].filter(Boolean);
    console.log(
      `✅ ${record.implement_name || '(sin título)'} → ${path.basename(outFile)}` +
        (pendientes.length ? `  ⚠️ falta: ${pendientes.join(', ')}` : '  listo'),
    );
  }
  console.log(`\n📊 ${ok} registros en data/implements — revisar, curar y luego: node import-implements.js`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
