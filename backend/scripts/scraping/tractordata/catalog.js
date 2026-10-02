/**
 * Genera el catálogo de URLs de modelos por marca desde los índices de
 * TractorData.com. Salida: data/catalog/<marca>.txt y data/catalog/all.txt
 *
 * Uso:
 *   node catalog.js --brands=johndeere,ford,massferg
 *   node catalog.js --brands=all
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createFetcher } from '../lib/http.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CATALOG_DIR = path.join(__dirname, '..', 'data', 'catalog');

// Slugs verificados de los índices por marca en TractorData
const BRAND_SLUGS = {
  johndeere: 'johndeere',
  'john deere': 'johndeere',
  massferg: 'massferg', // así llama TractorData a Massey Ferguson
  'massey ferguson': 'massferg',
  newholland: 'newholland',
  'new holland': 'newholland',
  kubota: 'kubota',
  ford: 'ford',
  case: 'case',
  caseih: 'caseih',
  'case ih': 'caseih',
  fiat: 'fiat',
  belarus: 'belarus',
  challenger: 'challenger',
  caterpillar: 'caterpillar',
  zetor: 'zetor',
  deutz: 'deutz',
  universal: 'universal',
  lamborghini: 'lamborghini',
  same: 'same',
};

// Sufijos de subpáginas de detalle que NO son páginas principales de modelo
const SECTION_SUFFIXES = [
  'dimensions', 'tests', 'photos', 'engine', 'transmission', 'attachments',
  'loader', 'hydraulics', 'serial-numbers', 'videos', 'prices', 'parts', 'page',
];

function isModelPage(url) {
  const m = url.match(/\/(\d+)-([a-z0-9-]+)\.html$/);
  if (!m) return false;
  const slug = m[2];
  return !SECTION_SUFFIXES.some((s) => slug.endsWith(`-${s}`));
}

async function main() {
  const args = process.argv.slice(2);
  const brandsArg = args.find((a) => a.startsWith('--brands='))?.split('=')[1];

  if (!brandsArg || args.includes('--help') || args.includes('-h')) {
    console.log(`Uso: node catalog.js --brands=<lista|all>

Marcas disponibles (slug TractorData):
  ${Object.keys(BRAND_SLUGS).filter((k) => !k.includes(' ')).join(', ')}

Ejemplos:
  node catalog.js --brands=johndeere,massferg,ford
  node catalog.js --brands=all`);
    process.exit(brandsArg ? 0 : 1);
  }

  let slugs;
  if (brandsArg === 'all') {
    slugs = [...new Set(Object.values(BRAND_SLUGS))];
  } else {
    slugs = brandsArg.split(',').map((b) => BRAND_SLUGS[b.trim().toLowerCase()]);
    if (slugs.some((s) => !s)) {
      console.error('❌ Marca desconocida. Verifica los slugs con --help');
      process.exit(1);
    }
  }

  fs.mkdirSync(CATALOG_DIR, { recursive: true });
  const fetchHtml = createFetcher({ cacheDir: path.join(__dirname, '..', 'data', 'cache') });

  const all = new Set();
  for (const slug of slugs) {
    const url = `https://www.tractordata.com/farm-tractors/tractor-brands/${slug}/${slug}-tractors.html`;
    process.stdout.write(`📄 ${slug.padEnd(12)} ... `);
    try {
      const html = await fetchHtml(url);
      const links = html
        .match(/https?:\/\/www\.tractordata\.com\/farm-tractors\/0\d\d\/\d+\/\d+\/\d+-[a-z0-9-]+\.html/g) || [];
      const modelUrls = [...new Set(links.map((u) => u.replace(/^http:/, 'https:')))].filter(isModelPage);
      fs.writeFileSync(path.join(CATALOG_DIR, `${slug}.txt`), modelUrls.sort().join('\n') + '\n');
      modelUrls.forEach((u) => all.add(u));
      console.log(`${modelUrls.length} modelos`);
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
    }
  }

  fs.writeFileSync(path.join(CATALOG_DIR, 'all.txt'), [...all].sort().join('\n') + '\n');
  console.log(`\n✅ Catálogo total: ${all.size} modelos → data/catalog/all.txt`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
