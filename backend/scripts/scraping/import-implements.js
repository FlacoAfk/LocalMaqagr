/**
 * Importa implementos cosechados (data/implements/*.json) a la tabla
 * `implement` de Postgres. Upsert por (implement_name, brand).
 * Omite registros sin los NOT NULL: implement_name, brand,
 * power_requirement_hp, working_width_m, implement_type.
 *
 * Uso (desde backend/):
 *   node scripts/scraping/import-implements.js --dry-run
 *   node scripts/scraping/import-implements.js
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { pool } from '../../src/config/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, 'data', 'implements');

dotenv.config({ quiet: true });

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

const VALID_TIPOS = new Set([
  'plow', 'harrow', 'seeder', 'cultivator', 'subsoiler',
  'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
  'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
  'rastra_pesada_26', 'rastra_pesada_24',
  // tipos del catálogo ampliado (scraping fabricantes)
  'abonador', 'pulverizador', 'carreta', 'distribuidor', 'repuesto', 'otro',
]);

function validate(r) {
  const p = [];
  if (!r.implement_name || r.implement_name.length > 150) p.push('implement_name');
  if (!r.brand) p.push('brand');
  if (r.power_requirement_hp == null) p.push('power_requirement_hp');
  if (r.working_width_m == null) p.push('working_width_m');
  if (!r.implement_type || !VALID_TIPOS.has(r.implement_type)) p.push(`implement_type=${r.implement_type}`);
  return p;
}

async function upsert(client, r) {
  const existing = await client.query(
    'SELECT implement_id FROM implement WHERE implement_name = $1 AND brand = $2',
    [r.implement_name, r.brand],
  );

  if (existing.rows.length > 0) {
    const id = existing.rows[0].implement_id;
    const vals = [
      r.image_url ?? null,
      r.power_requirement_hp,
      r.working_width_m,
      r.soil_type ?? 'Franco',
      r.working_depth_cm ?? null,
      r.n_tines ?? null,
      r.weight_kg ?? null,
      r.implement_type,
      r.ficha_pdf_url ?? null,
      id,
    ];
    await client.query(
      `UPDATE implement SET
         image_url = COALESCE($1, image_url), power_requirement_hp = $2,
         working_width_m = $3, soil_type = COALESCE($4, soil_type),
         working_depth_cm = COALESCE($5, working_depth_cm),
         n_tines = COALESCE($6, n_tines), weight_kg = COALESCE($7, weight_kg),
         implement_type = $8, ficha_pdf_url = COALESCE($9, ficha_pdf_url)
       WHERE implement_id = $10`,
      vals,
    );
    return { action: 'update', id };
  }

  const vals = [
    r.implement_name,
    r.brand,
    r.image_url ?? null,
    r.power_requirement_hp,
    r.working_width_m,
    r.soil_type ?? 'Franco',
    r.working_depth_cm ?? null,
    r.n_tines ?? null,
    r.weight_kg ?? null,
    r.implement_type,
    r.ficha_pdf_url ?? null,
  ];
  const inserted = await client.query(
    `INSERT INTO implement (
       implement_name, brand, image_url, power_requirement_hp, working_width_m,
       soil_type, working_depth_cm, n_tines, weight_kg, implement_type, status, ficha_pdf_url
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'available',$11)
     RETURNING implement_id`,
    vals,
  );
  return { action: 'insert', id: inserted.rows[0].implement_id };
}

async function main() {
  const files = fs.existsSync(DATA_DIR)
    ? fs.readdirSync(DATA_DIR).filter((f) => f.endsWith('.json'))
    : [];
  // Los JSON del adaptador Baldan agrupan {producto, url, registros: [...]};
  // los del harvester genérico son un registro único. Se aplanan todos.
  const records = files.flatMap((f) => {
    const data = JSON.parse(fs.readFileSync(path.join(DATA_DIR, f), 'utf8'));
    const regs = data.registros || [data];
    // Enlace a la ficha técnica del fabricante (página del producto)
    const url = data.url || data.fuente?.url || null;
    return regs.map((r) => ({ ...r, ficha_pdf_url: r.ficha_pdf_url ?? url }));
  });
  console.log(`📦 ${records.length} implementos para importar${dryRun ? ' (DRY-RUN)' : ''}\n`);

  const valid = [];
  for (const r of records) {
    const problems = validate(r);
    if (problems.length) console.log(`⚠️  omitido ${r.implement_name || '(sin nombre)'}: falta ${problems.join(', ')}`);
    else valid.push(r);
  }

  if (dryRun) {
    for (const r of valid) console.log(`[dry-run] ${r.implement_name} (${r.brand}) ${r.implement_type} ${r.power_requirement_hp}hp ${r.working_width_m}m`);
    await pool.end();
    return;
  }
  if (!valid.length) {
    console.log('Nada válido para importar.');
    await pool.end();
    return;
  }

  const client = await pool.connect();
  let inserted = 0;
  let updated = 0;
  try {
    await client.query('BEGIN');
    for (const r of valid) {
      const { action, id } = await upsert(client, r);
      action === 'insert' ? inserted++ : updated++;
      console.log(`${action === 'insert' ? '🟢 insertado' : '🟡 actualizado'} #${id} ${r.implement_name}`);
    }
    await client.query('COMMIT');
    console.log(`\n✅ Importación completada: ${inserted} nuevos, ${updated} actualizados`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error, rollback aplicado:', err.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(async (e) => {
  console.error('❌', e.message);
  process.exitCode = 1;
  try { await pool.end(); } catch { /* noop */ }
});
