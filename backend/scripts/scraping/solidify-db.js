/**
 * Solidificación de la BD de catálogo (petición del usuario):
 *  1. COMPLETAR lo buscable:
 *     - llantas: extraer cualquier dato de neumáticos de la ficha JSON
 *     - fuerza de tiro: estimación documentada (0.70 × P_motor a 6 km/h)
 *     - imágenes: respaldo del scrape (/uploads) cuando exista
 *     - peso de implementos: extraer de la ficha del fabricante
 *  2. BORRAR todo tractor/implemento que siga faltando un dato obligatorio
 *     (el usuario lo autorizó explícitamente: "si no los encuentras, bórralos")
 *
 * Obligatorios tractor: hp, peso, tiro, tracción válida, llantas, imagen
 * Obligatorios implemento: nombre, marca, potencia, ancho, tipo, imagen, peso
 *
 * Uso: node solidify-db.js [--dry-run]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from '../../src/config/db.js';
import { parseTire } from './lib/numbers.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TRACTORS_JSON = path.join(__dirname, 'data', 'tractors');
const IMPL_JSON = path.join(__dirname, 'data', 'implements');
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

const norm = (s) => (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');

function loadJsonMap(dir, keyA, keyB) {
  const map = new Map();
  if (!fs.existsSync(dir)) return map;
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.json')) continue;
    try {
      const data = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
      const regs = data.registros || [data];
      for (const r of regs) {
        const k = norm(r[keyA] ?? data[keyA]) + '|' + norm(r[keyB] ?? data[keyB]);
        if (!map.has(k)) map.set(k, { file: path.join(dir, f), data, reg: r });
      }
    } catch { /* ignorar corruptos */ }
  }
  return map;
}

/** Busca CUALQUIER dato de neumático en el texto de la ficha (rear primero). */
function tireFromSpecs(jsonText) {
  if (!jsonText) return null;
  const lower = jsonText.toLowerCase();
  // priorizar segmentos que mencionen "rear"/"trasera"
  const segments = [];
  let i = lower.indexOf('rear');
  while (i !== -1) { segments.push(lower.slice(i, i + 120)); i = lower.indexOf('rear', i + 1); }
  segments.push(lower);
  for (const seg of segments) {
    const m = seg.match(/(\d{1,2}(?:\.\d+)?)\s*(?:L|R|-|x)\s*(\d{1,2}(?:\.\d+)?)/i);
    if (m) {
      const tire = parseTire(m[0]);
      if (tire) return tire;
    }
  }
  return null;
}

async function main() {
  const tractorMap = loadJsonMap(TRACTORS_JSON, 'brand', 'model');
  const implMap = loadJsonMap(IMPL_JSON, 'brand', 'implement_name');

  const report = { tractor: { llenados: 0, borrados: 0 }, implement: { llenados: 0, borrados: 0 } };

  // ══════════════ TRACTORES ══════════════
  const tractors = (await pool.query('SELECT tractor_id, name, brand, model, engine_power_hp, weight_kg, traction_force_kn, traction_type, image_url, tire_type, tire_width_mm, tire_diameter_mm FROM tractor')).rows;

  const borrarTractores = [];
  for (const t of tractors) {
    const key = norm(t.brand) + '|' + norm(t.model);
    const json = tractorMap.get(key);
    const updates = {};

    // ── llantas ──
    if (t.tire_type == null || t.tire_width_mm == null || t.tire_diameter_mm == null) {
      const tire = json ? tireFromSpecs(JSON.stringify(json.data.specs || '')) : null;
      if (tire) {
        updates.tire_type = `${tire.radial ? 'Radial' : 'Diagonal'} ${tire.original}`;
        updates.tire_width_mm = tire.width_mm;
        updates.tire_diameter_mm = tire.diameter_mm_est;
      }
    }
    // ── fuerza de tiro ──
    if (t.traction_force_kn == null || t.traction_force_kn <= 0) {
      if (t.engine_power_hp > 0) {
        updates.traction_force_kn = Math.round(((t.engine_power_hp * 0.70 * 0.7457) / (6 / 3.6)) * 10) / 10;
      }
    }
    // ── imagen ──
    if (t.image_url == null && json) {
      const candidates = [
        json.data.image_url,
        json.reg.image_url,
      ].filter((u) => u && u.startsWith('/uploads/'));
      if (candidates.length) updates.image_url = candidates[0];
    }

    const fails = [];
    const hp = updates.engine_power_hp ?? t.engine_power_hp;
    const peso = updates.weight_kg ?? t.weight_kg;
    const tiro = updates.traction_force_kn ?? t.traction_force_kn;
    const img = updates.image_url ?? t.image_url;
    const tt = updates.tire_type ?? t.tire_type;
    const tw = updates.tire_width_mm ?? t.tire_width_mm;
    const td = updates.tire_diameter_mm ?? t.tire_diameter_mm;
    if (!(hp > 0)) fails.push('hp');
    if (!(peso > 0)) fails.push('peso');
    if (!(tiro > 0)) fails.push('tiro');
    if (!['4x2', '4x4', 'track'].includes(t.traction_type)) fails.push('traccion');
    if (!(tt && tw && td)) fails.push('llantas');
    if (!img) fails.push('imagen');

    if (Object.keys(updates).length && !fails.length) {
      report.tractor.llenados++;
      if (!dryRun) {
        const keys = Object.keys(updates);
        await pool.query(
          `UPDATE tractor SET ${keys.map((k, i) => `${k} = $${i + 1}`).join(', ')} WHERE tractor_id = $${keys.length + 1}`,
          [...Object.values(updates), t.tractor_id],
        );
      }
    }
    if (fails.length) borrarTractores.push({ id: t.tractor_id, name: t.name, fails });
  }

  console.log(`TRACTORES: ${tractors.length} → completados: ${report.tractor.llenados}, a borrar: ${borrarTractores.length}`);
  const porFalta = {};
  for (const b of borrarTractores) for (const f of b.fails) porFalta[f] = (porFalta[f] || 0) + 1;
  console.log('  motivos de borrado:', JSON.stringify(porFalta));
  if (dryRun) {
    borrarTractores.slice(0, 10).forEach((b) => console.log(`   [dry-run] borrar #${b.id} ${b.name} — falta: ${b.fails.join(', ')}`));
  } else {
    for (const b of borrarTractores) {
      await pool.query('DELETE FROM tractor WHERE tractor_id = $1', [b.id]);
      report.tractor.borrados++;
    }
  }

  // ══════════════ IMPLEMENTOS ══════════════
  const impls = (await pool.query('SELECT implement_id, implement_name, brand, power_requirement_hp, working_width_m, weight_kg, image_url, implement_type FROM implement')).rows;
  const borrarImpl = [];
  for (const im of impls) {
    const key = norm(im.brand) + '|' + norm(im.implement_name);
    const json = implMap.get(key);
    const updates = {};

    if (im.weight_kg == null && json) {
      // Extrae la columna "Peso" de las tablas de especificaciones
      // (formatos: {headers, filas} y pares etiqueta→valor)
      const specs = json.data.specs || json.reg?.specs || {};
      let peso = null;
      const tables = specs?.ficha_tecnica || specs?.ficha_completa || [];
      for (const table of tables) {
        if (table.headers && table.filas) {
          const idx = table.headers.findIndex((h) => /peso/i.test(h));
          if (idx === -1) continue;
          for (const fila of table.filas) {
            const v = parseFloat(String(fila[idx]).replace(',', '.'));
            if (v > 0) { peso = v; break; }
          }
        } else {
          for (const [k, v] of Object.entries(table)) {
            if (/peso/i.test(k)) {
              const n = parseFloat(String(v).replace(',', '.'));
              if (n > 0) { peso = n; break; }
            }
          }
        }
        if (peso) break;
      }
      if (!peso) {
        const pairRe = /"etiqueta"\s*:\s*"([^"]*[Pp]eso[^"]*)"\s*,\s*"(?:valor|etiqueta2)"\s*:\s*"?(\d{2,5}(?:[.,]\d+)?)/g;
        let pm;
        while ((pm = pairRe.exec(JSON.stringify(specs))) !== null) { peso = parseFloat(pm[2].replace(',', '.')); break; }
      }
      if (peso > 0) updates.weight_kg = peso;
    }

    const fails = [];
    if (!(im.power_requirement_hp > 0)) fails.push('potencia');
    if (!(im.working_width_m > 0)) fails.push('ancho');
    const pesoI = updates.weight_kg ?? im.weight_kg;
    if (!(pesoI > 0)) fails.push('peso');
    const imgI = updates.image_url ?? im.image_url;
    if (!imgI) fails.push('imagen');
    if (!im.implement_type) fails.push('tipo');

    if (Object.keys(updates).length && !fails.length) {
      report.implement.llenados++;
      if (!dryRun) {
        const keys = Object.keys(updates);
        await pool.query(
          `UPDATE implement SET ${keys.map((k, i) => `${k} = $${i + 1}`).join(', ')} WHERE implement_id = $${keys.length + 1}`,
          [...Object.values(updates), im.implement_id],
        );
      }
    }
    if (fails.length) borrarImpl.push({ id: im.implement_id, name: im.implement_name, fails });
  }

  console.log(`IMPLEMENTOS: ${impls.length} → completados: ${report.implement.llenados}, a borrar: ${borrarImpl.length}`);
  if (dryRun) {
    borrarImpl.slice(0, 10).forEach((b) => console.log(`   [dry-run] borrar #${b.id} ${b.name} — falta: ${b.fails.join(', ')}`));
  } else {
    for (const b of borrarImpl) {
      await pool.query('DELETE FROM implement WHERE implement_id = $1', [b.id]);
      report.implement.borrados++;
    }
  }

  if (!dryRun) {
    console.log(`\n✅ BD solidificada: tractores +${report.tractor.llenados}/-${report.tractor.borrados}, implementos +${report.implement.llenados}/-${report.implement.borrados}`);
  }
  await pool.end();
}

main().catch(async (e) => {
  console.error('❌', e);
  try { await pool.end(); } catch { /* noop */ }
});
