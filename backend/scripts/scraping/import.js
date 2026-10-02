/**
 * Importa los registros scrapeados (data/tractors/*.json) a la tabla
 * `tractor` de Postgres. Upsert por (brand, model). Si el mismo modelo
 * tiene varias generaciones, añade los años al name para diferenciarlas.
 *
 * Uso (desde backend/):
 *   node scripts/scraping/import.js --dry-run
 *   node scripts/scraping/import.js            # aplica
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { pool } from '../../src/config/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, 'data', 'tractors');

dotenv.config({ quiet: true });

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

const VALID_TRACTION = new Set(['4x2', '4x4', 'track']);

function loadRecords() {
  const files = fs.readdirSync(DATA_DIR).filter((f) => /^\d+\.json$/.test(f));
  const records = files.map((f) => {
    const r = JSON.parse(fs.readFileSync(path.join(DATA_DIR, f), 'utf8'));
    // Marca canónica: TractorData usa sufijos corporativos y nombres históricos
    r.brand = (r.brand || '')
      .replace(/\s*\(a part of.*\)$/i, '')
      .replace(/^J\.I\. Case$/i, 'Case IH')
      .trim();
    // Solo el ENLACE a la ficha técnica (no el PDF): mantiene el instalador liviano
    r.ficha_pdf_url = r.fuente?.nebraska_pdf ?? null;
    return r;
  });

  // Desambiguar generaciones del mismo modelo: "John Deere 5075E (2015-2022)"
  const count = {};
  for (const r of records) {
    const key = `${(r.brand || '').toLowerCase()}|${(r.model || '').toLowerCase()}`;
    count[key] = (count[key] || 0) + 1;
  }
  const seen = {};
  for (const r of records) {
    const key = `${(r.brand || '').toLowerCase()}|${(r.model || '').toLowerCase()}`;
    seen[key] = (seen[key] || 0) + 1;
    if (count[key] > 1 && r.years?.desde) {
      r.name = `${r.name} (${r.years.desde}-${r.years.hasta ?? ''})`.replace(/-\)$/, ')');
    }
  }
  return records;
}

function validate(r) {
  const problems = [];
  if (!r.name || r.name.length > 150) problems.push('name inválido');
  if (!r.brand) problems.push('sin brand');
  if (!r.model) problems.push('sin model');
  if (r.engine_power_hp == null) problems.push('sin engine_power_hp');
  if (r.weight_kg == null) problems.push('sin weight_kg');
  if (r.traction_force_kn == null) problems.push('sin traction_force_kn');
  if (!VALID_TRACTION.has(r.traction_type)) problems.push(`traction_type inválido: ${r.traction_type}`);
  if (r.image_url && !/^(https?:\/\/|\/uploads\/)/.test(r.image_url)) problems.push('image_url inválida');
  return problems;
}

async function upsert(client, r) {
  const existing = await client.query(
    'SELECT tractor_id FROM tractor WHERE brand = $1 AND LOWER(model) = LOWER($2::varchar)',
    [r.brand, r.model],
  );

  if (existing.rows.length > 0) {
    const id = existing.rows[0].tractor_id;
    const updValues = [
      r.name,
      r.image_url ?? null,
      r.model_year ?? null,
      r.engine_power_hp,
      r.weight_kg,
      r.traction_force_kn,
      r.traction_type,
      r.has_turbo ?? false,
      r.tire_type ?? null,
      r.tire_width_mm ?? null,
      r.tire_diameter_mm ?? null,
      r.fuel_consumption_lph ?? null,
      r.ficha_pdf_url ?? null,
      id,
    ];
    await client.query(
      `UPDATE tractor SET
         name = $1,
         image_url = CASE WHEN prioridad THEN image_url ELSE COALESCE($2, image_url) END,
         model_year = $3,
         engine_power_hp = $4,
         weight_kg = $5,
         traction_force_kn = $6,
         traction_type = $7, has_turbo = $8, tire_type = $9,
         tire_width_mm = $10, tire_diameter_mm = $11,
         fuel_consumption_lph = COALESCE($12, fuel_consumption_lph),
         ficha_pdf_url = CASE WHEN prioridad THEN ficha_pdf_url ELSE $13 END
       WHERE tractor_id = $14`,
      updValues,
    );
    return { action: 'update', id };
  }

  const insValues = [
    r.name,
    r.brand,
    r.model,
    r.image_url ?? null,
    r.model_year ?? null,
    r.engine_power_hp,
    null, // price: se define manualmente
    r.weight_kg,
    r.traction_force_kn,
    r.traction_type,
    r.has_turbo ?? false,
    r.tire_type ?? null,
    r.tire_width_mm ?? null,
    r.tire_diameter_mm ?? null,
    null, // tire_pressure_psi: se define manualmente
    null, // price_usd
    r.fuel_consumption_lph ?? null,
    null, // maintenance_cost_per_hour
    'available',
  ];
  const inserted = await client.query(
    `INSERT INTO tractor (
       name, brand, model, image_url, model_year, engine_power_hp, price,
       weight_kg, traction_force_kn, traction_type, has_turbo, tire_type,
       tire_width_mm, tire_diameter_mm, tire_pressure_psi, price_usd,
       fuel_consumption_lph, maintenance_cost_per_hour, status
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
     RETURNING tractor_id`,
    insValues,
  );
  return { action: 'insert', id: inserted.rows[0].tractor_id };
}

async function main() {
  const records = loadRecords();
  console.log(`📦 ${records.length} registros para importar${dryRun ? ' (DRY-RUN)' : ''}\n`);

  let valid = 0;
  const invalid = [];
  for (const r of records) {
    const problems = validate(r);
    if (problems.length) invalid.push({ name: r.name || '(sin nombre)', problems });
    else valid++;
  }
  if (invalid.length) {
    console.log(`⚠️  ${invalid.length} registros con problemas (se omiten):`);
    for (const { name, problems } of invalid) console.log(`   - ${name}: ${problems.join(', ')}`);
    console.log('');
  }

  if (dryRun) {
    for (const r of records) {
      if (validate(r).length) continue;
      console.log(`[dry-run] ${r.name.padEnd(40)} ${String(r.engine_power_hp).padStart(5)} hp  ${r.traction_type}  ${r.weight_kg} kg  ${r.traction_force_kn} kN  ${r.image_url ?? 'sin foto'}`);
    }
    await pool.end();
    return;
  }

  const client = await pool.connect();
  let inserted = 0;
  let updated = 0;
  try {
    await client.query('BEGIN');
    for (const r of records) {
      if (validate(r).length) continue;
      const { action, id } = await upsert(client, r);
      action === 'insert' ? inserted++ : updated++;
      console.log(`${action === 'insert' ? '🟢 insertado' : '🟡 actualizado'} #${id}  ${r.name}`);
    }
    await client.query('COMMIT');
    console.log(`\n✅ Importación completada: ${inserted} nuevos, ${updated} actualizados, ${invalid.length} omitidos`);
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
