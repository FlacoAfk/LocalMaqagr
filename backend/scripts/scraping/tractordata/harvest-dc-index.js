/**
 * Cosecha el índice de informes de prueba de Nebraska desde UNL Digital
 * Commons vía OAI-PMH (los URLs viejos de tractortestlab.unl.edu murieron
 * cuando el laboratorio reestructuró su sitio).
 *
 * Recorre todas las series publication:tractor* y extrae los registros cuyo
 * título es "Test NNN: <modelo>" — el número de prueba es único globalmente.
 *
 * Salida: data/nebraska-dc-index.json  { [testNumber]: { titulo, url } }
 *
 * Uso: node tractordata/harvest-dc-index.js
 */
import fs from 'fs';
import path from 'path';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'data', 'nebraska-dc-index.json');
const BASE = 'https://digitalcommons.unl.edu/do/oai/';

const SETS = [
  'publication:tractor', 'publication:tractorbigbud', 'publication:tractorcase',
  'publication:tractorcletrac', 'publication:tractordeere', 'publication:tractorduetz',
  'publication:tractoreagle', 'publication:tractorfarmall', 'publication:tractorford',
  'publication:tractorhesston', 'publication:tractorkubota', 'publication:tractormanufacturer',
  'publication:tractorminnmoline', 'publication:tractormuseumlit', 'publication:tractorpower',
  'publication:tractorresearch', 'publication:tractorrock', 'publication:tractorrumely',
  'publication:tractorzetor',
];

function curlGet(url) {
  return new Promise((resolve, reject) => {
    execFile('curl', ['-sk', '-m', '60', '-L', '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126', url], { maxBuffer: 60 * 1024 * 1024 }, (err, stdout) => (err ? reject(err) : resolve(stdout)));
  });
}

function decode(s) {
  return s.replace(/&amp;/g, '&').replace(/&#39;|&apos;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}

function parseRecords(xml) {
  const out = [];
  const re = /<record>([\s\S]*?)<\/record>/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    const rec = m[1];
    const title = decode((rec.match(/<dc:title>([\s\S]*?)<\/dc:title>/) || [])[1] || '').replace(/\s+/g, ' ').trim();
    const idMatch = rec.match(/<identifier>oai:digitalcommons\.unl\.edu:([a-z_]+)-(\d+)<\/identifier>/);
    const tm = title.match(/^Test\s+(\d+)\s*:\s*(.+)$/i);
    if (idMatch && tm) {
      out.push({
        test: parseInt(tm[1], 10),
        titulo: title,
        url: `https://digitalcommons.unl.edu/${idMatch[1]}/${idMatch[2]}/`,
      });
    }
  }
  const token = (xml.match(/<resumptionToken[^>]*>([^<]+)<\/resumptionToken>/) || [])[1];
  return { records: out, token: token ? decode(token) : null };
}

async function harvestSet(setSpec) {
  const idx = {};
  let url = `${BASE}?verb=ListRecords&metadataPrefix=oai_dc&set=${setSpec}`;
  let pages = 0;
  for (;;) {
    const xml = await curlGet(url);
    const { records, token } = parseRecords(xml);
    for (const r of records) if (!idx[r.test]) idx[r.test] = { titulo: r.titulo, url: r.url };
    pages++;
    if (!token || pages > 40) break;
    await new Promise((r) => setTimeout(r, 400));
    url = `${BASE}?verb=ListRecords&metadataPrefix=oai_dc&resumptionToken=${encodeURIComponent(token)}`;
  }
  return { idx, pages };
}

async function main() {
  const index = fs.existsSync(OUT) ? JSON.parse(fs.readFileSync(OUT, 'utf8')) : {};
  const antes = Object.keys(index).length;

  for (const set of SETS) {
    try {
      const { idx, pages } = await harvestSet(set);
      const n = Object.keys(idx).length;
      Object.assign(index, idx);
      console.log(`${set.padEnd(32)} ${String(n).padStart(4)} pruebas (${pages} pág.)`);
    } catch (err) {
      console.log(`${set.padEnd(32)} ERROR: ${err.message.slice(0, 60)}`);
    }
  }

  fs.writeFileSync(OUT, JSON.stringify(index, null, 1) + '\n');
  console.log(`\n📊 Índice: ${antes} → ${Object.keys(index).length} pruebas con informe → ${path.basename(OUT)}`);
}

main().catch((e) => {
  console.error('❌', e);
  process.exit(1);
});
