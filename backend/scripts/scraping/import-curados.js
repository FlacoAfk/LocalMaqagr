/**
 * Importa los tractores CURADOS del proyecto anterior (ProyectoAgricola/BD):
 * 4 dumps MySQL con fichas técnicas OFICIALES del fabricante (brochures CNH,
 * Massey Ferguson y fichas de concesionarios Kubota/Nissan Colombia) + fotos.
 *
 * 80 tractores: Case IH 30, New Holland 18, Massey Ferguson 22, Kubota 10.
 *
 * Cada registro curado se marca prioridad=true (aparecen primero en el
 * catálogo). Si el modelo ya existe en la BD (scraping TractorData), se
 * ENRIQUECE: la ficha/foto/hp/peso vienen del curado y la tracción/neumáticos
 * del scrapeado.
 *
 * Uso: node import-curados.js [--dry-run]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from '../../src/config/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BD = 'C:/Users/elkaw/Desktop/ProyectoAgricola/BD';

// Orden de columnas en cada dump (después de marca y modelo):
//   Case IH / Kubota : potencia, peso, turbo, FOTO, FICHA
//   Massey Ferguson  : potencia, peso, turbo, FICHA, FOTO
//   New Holland      : peso, potencia, turbo, FICHA, FOTO
const SOURCES = [
  { file: `${BD}/Case IH DB/Case IH.sql`, pesoPrimero: false, fichaPrimera: false },
  { file: `${BD}/Kubora DB/Base de datos/tractors.sql`, pesoPrimero: false, fichaPrimera: false },
  { file: `${BD}/Massey Ferguson/Massey Ferguson/normal/tractor_tractor.sql`, pesoPrimero: false, fichaPrimera: true },
  { file: `${BD}/New Holland/New Holland.sql`, pesoPrimero: true, fichaPrimera: true },
];

function parseArgs(argv) {
  const args = {};
  for (const a of argv) {
    const m = a.match(/^--([a-z-]+)(?:=(.*))?$/);
    if (m) args[m[1]] = m[2] ?? true;
  }
  return args;
}

function toBool(v) {
  return v === 'si' || v === '1' || v === 1 || v === true;
}

/** Extrae tuplas MySQL de un dump (tolera NULL en el peso). */
function parseDump(sql, { pesoPrimero, fichaPrimera }) {
  const re = /\(\s*(\d+)\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*([\d.]+|NULL)\s*,\s*([\d.]+|NULL)\s*,\s*'?((?:si)|(?:no)|(?:1)|(?:0))'?\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*\)/gi;
  const out = [];
  let m;
  while ((m = re.exec(sql)) !== null) {
    const [, , marca, modelo, a, b, turbo, c, d] = m;
    const num = (v) => (v && v.toUpperCase() !== 'NULL' ? parseFloat(v) : null);
    const potencia = pesoPrimero ? num(b) : num(a);
    const peso = pesoPrimero ? num(a) : num(b);
    const ficha = fichaPrimera ? c : d;
    const foto = fichaPrimera ? d : c;
    out.push({
      brand: marca.trim(),
      model: modelo.trim(),
      engine_power_hp: potencia,
      weight_kg: peso,
      has_turbo: toBool(turbo),
      image_url: foto?.trim() || null,
      ficha_pdf_url: ficha?.trim() || null,
    });
  }
  return out;
}

const norm = (s) => (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');

/** Inferencia honesta cuando no hay datos scrapeados del modelo */
function inferirTraccion(modelo) {
  return /(4wd|4x4|doble\s*tracc)/i.test(modelo) ? '4x4' : '4x2';
}
function estimarTiroKn(hp) {
  // P_tracción ≈ 0.70 × P_motor (PTO 0.85 × entrega 0.82) a 6 km/h
  if (!hp) return null;
  return Math.round((hp * 0.70 * 0.7457) / (6 / 3.6) * 10) / 10;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  // 1. Cargar curados
  let curados = [];
  for (const src of SOURCES) {
    const sql = fs.readFileSync(src.file, 'utf8');
    const recs = parseDump(sql, src);
    console.log(`📄 ${path.basename(src.file)}: ${recs.length} tractores`);
    curados.push(...recs);
  }
  console.log(`\n📦 Total curados: ${curados.length}\n`);

  if (args['dry-run']) {
    curados.forEach((r) => console.log(`[dry-run] ${r.brand} ${r.model} — ${r.engine_power_hp} hp, ${r.weight_kg} kg, turbo: ${r.has_turbo}`));
    await pool.end();
    return;
  }

  // 2. Mapa de modelos scrapeados existentes (brand → [{id, model, ...}])
  const existentes = await pool.query('SELECT tractor_id, brand, model, traction_type, traction_force_kn, tire_type, tire_width_mm, tire_diameter_mm, model_year FROM tractor');
  const porMarca = new Map();
  for (const t of existentes.rows) {
    const k = norm(t.brand);
    if (!porMarca.has(k)) porMarca.set(k, []);
    porMarca.get(k).push(t);
  }

  const client = await pool.connect();
  let enriquecidos = 0;
  let insertados = 0;

  try {
    await client.query('BEGIN');

    for (const r of curados) {
      // Buscar match de scraping: modelo exacto normalizado, o prefijo con
      // diferencia de longitud pequeña (evita falsos positivos TD95↔TD95D)
      const candidatos = porMarca.get(norm(r.brand)) || [];
      const a = norm(r.model);
      const match =
        candidatos.find((t) => norm(t.model) === a) ||
        candidatos.find((t) => {
          const b = norm(t.model);
          return (b.startsWith(a) || a.startsWith(b)) && Math.abs(b.length - a.length) <= 3;
        });

      if (match) {
        // Enriquecer el scrapeado: el curado es la fuente de verdad para
        // ficha, foto, potencia, peso y turbo (el peso NULL conserva el del scrape)
        await client.query(
          `UPDATE tractor SET
             engine_power_hp = $1,
             weight_kg = COALESCE($2, weight_kg),
             has_turbo = $3,
             image_url = $4,
             ficha_pdf_url = $5, prioridad = TRUE
           WHERE tractor_id = $6`,
          [r.engine_power_hp, r.weight_kg, r.has_turbo, r.image_url, r.ficha_pdf_url, match.tractor_id],
        );
        enriquecidos++;
        console.log(`🟡 enriquecido #${match.tractor_id} ${r.brand} ${r.model}`);
      } else {
        // Nuevo: peso estimado si el curado no lo trae; tracción inferida; tiro estimado
        const peso = r.weight_kg ?? Math.round(r.engine_power_hp * 42);
        const kn = estimarTiroKn(r.engine_power_hp);
        await client.query(
          `INSERT INTO tractor (
             name, brand, model, engine_power_hp, weight_kg, traction_force_kn,
             traction_type, has_turbo, image_url, ficha_pdf_url, prioridad, status
           ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,TRUE,'available')`,
          [
            `${r.brand} ${r.model}`, r.brand, r.model, r.engine_power_hp, peso,
            kn, inferirTraccion(r.model), r.has_turbo, r.image_url, r.ficha_pdf_url,
          ],
        );
        insertados++;
        console.log(`🟢 insertado ${r.brand} ${r.model} (peso ${peso} kg, tiro ${kn} kN)`);
      }
    }

    await client.query('COMMIT');
    console.log(`\n✅ Curados aplicados: ${enriquecidos} enriquecidos, ${insertados} nuevos (todos prioridad=TRUE)`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ rollback:', err.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(async (e) => {
  console.error('❌', e.message);
  try { await pool.end(); } catch { /* noop */ }
});
