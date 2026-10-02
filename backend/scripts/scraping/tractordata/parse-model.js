/**
 * Parser de fichas de modelo de TractorData.com → registro con el esquema
 * de la tabla `tractor` de MaqAgr (más ficha técnica cruda para referencia).
 *
 * Páginas usadas por modelo:
 *   <url>.html                 — potencia, mecánica (tracción), capacidades, foto
 *   <url>-dimensions.html      — neumáticos y pesos
 *   <url>-tests.html           — prueba Nebraska: consumo y tiro máximo
 *   <url>-engine.html          — para detectar turbo
 */
import { allRows, splitTables, pageText, firstH1 } from '../lib/html.js';
import {
  parseUnitPairs,
  pickUnit,
  parseTire,
  weightKg,
  forceKn,
  horsepower,
  litersPerHour,
} from '../lib/numbers.js';

const LICENCE_NOTE =
  'Datos factuales extraídos de TractorData.com para uso como referencia del catálogo local de MaqAgr. La compilación de TractorData tiene copyright propio: no redistribuir el volcado completo; conservar la atribución de fuente por registro.';

function rowsToSpec(rows) {
  const spec = {};
  let sectionIndex = 0;
  for (const row of rows) {
    if (row.section) spec[`__seccion_${++sectionIndex}__`] = row.section;
    else spec[row.label] = row.value;
  }
  return spec;
}

/** Busca una fila por regex de etiqueta entre todas las filas (ya aplanadas). */
function findRow(rows, labelRe) {
  return rows.find((row) => row.label && labelRe.test(row.label)) || null;
}

function tireInfo(text) {
  if (!text) return null;
  const tire = parseTire(text.split(/[\s,]+/).find((tok) => /^\d/.test(tok)));
  if (!tire) return null;
  return {
    ...tire,
    tipo: tire.radial ? 'Radial' : 'Diagonal',
    texto: text.trim(),
  };
}

/**
 * Decide el tipo de tracción. Señales en orden de confianza:
 *  1. Texto de la sección Mechanical ("two-/four-wheel drive", "tracked")
 *  2. Frases completas en el resto de la página (nunca "4WD" suelto: aparece
 *     en filas ajenas como "4WD Hydraulic system")
 *  3. Prefijos 2WD/4WD de las filas de peso
 */
function resolveTractionType(mainTablesGrouped, mainText, weightLabels) {
  const mechanical = mainTablesGrouped.find((t) =>
    t.some((r) => r.section && /^Mechanical/i.test(r.section)),
  );
  const mechText = mechanical
    ? mechanical.map((r) => r.section ?? `${r.label} ${r.value}`).join(' ')
    : '';

  const has4wd = weightLabels.some((l) => /4WD/i.test(l));
  const has2wd = weightLabels.some((l) => /2WD/i.test(l));

  const driveRe = /two- or four-wheel drive|four-wheel drive|4-wheel drive|two-wheel drive|2-wheel drive|tracked?\s+drive|crawler/i;

  const source = mechText.match(driveRe) || mainText.match(driveRe);
  if (source) {
    const s = source[0].toLowerCase();
    if (/track|crawler/.test(s)) return { traction_type: 'track', derivado: false };
    if (/two- or four/.test(s)) {
      return { traction_type: has4wd || !has2wd ? '4x4' : '4x2', derivado: true };
    }
    if (/four-wheel|4-wheel/.test(s)) return { traction_type: '4x4', derivado: false };
    return { traction_type: '4x2', derivado: false };
  }
  return { traction_type: has4wd ? '4x4' : '4x2', derivado: true };
}

/**
 * Estima la fuerza de tiro (kN) cuando no hay prueba Nebraska publicada:
 *   tiro ≈ P_tracción / velocidad de diseño (6 km/h)
 *   P_tracción ≈ 0.82 × PTO (eficiencia típica de entrega eje→barra, Zoz & Grisso)
 */
function estimateTractionKn(ptoHp) {
  if (!ptoHp) return null;
  const drawbarHp = ptoHp * 0.82;
  const kw = drawbarHp * 0.7457;
  const speedMs = 6 / 3.6; // 6 km/h
  return Math.round((kw / speedMs) * 10) / 10;
}

/**
 * @param {object} pages  { main, dimensions, tests, engine } HTML de cada página
 * @param {string} url    URL de la página principal del modelo
 */
export function parseModel({ main, dimensions, tests, engine }, url) {
  const idMatch = url.match(/\/(\d+)-([a-z0-9-]+)\.html/);
  const sourceId = idMatch ? Number(idMatch[1]) : null;
  const slug = idMatch ? idMatch[2] : null;

  const mainTables = allRows(main);
  const mainTablesGrouped = splitTables(main);
  const dimTables = dimensions ? allRows(dimensions) : [];
  const testTables = tests ? allRows(tests) : [];

  // ── Identidad ──────────────────────────────────────────────
  const h1 = firstH1(main); // "John Deere 5075E"
  const manufacturerRow = findRow(mainTables, /^Manufacturer/i);
  const brand = (manufacturerRow?.value || '').trim() || (h1 ? h1.split(/\s+/)[0] : null);

  // Años de producción: "1975 - 1983" o "2008 - 2025"
  const text = pageText(main);
  const yearsMatch = text.match(/\b(\d{4})\s*-\s*(\d{4})\b/);
  const yearFrom = yearsMatch ? parseInt(yearsMatch[1], 10) : null;
  const yearTo = yearsMatch ? parseInt(yearsMatch[2], 10) : null;

  // Modelo: del h1 quitando la marca; fallback al slug
  let model = slug || '';
  if (h1 && brand && h1.toLowerCase().startsWith(brand.toLowerCase())) {
    model = h1.slice(brand.length).trim();
  } else if (slug) {
    model = slug.replace(/^[a-z]+-/, ''); // "massey-ferguson-265" → "265"
  }
  model = model.replace(/-/g, ' ').trim();

  // ── Potencia ───────────────────────────────────────────────
  // Los clásicos (MF 265, Fiat 640…) no publican "Engine (gross)": se cae al
  // PTO claimed. Los antiguos (años 50-60) usan "Belt" en vez de PTO.
  const engineGrossRow = findRow(mainTables, /engine \(gross\)/i);
  const engineNetRow = findRow(mainTables, /engine \(net\)/i);
  const engineRow = findRow(mainTables, /^Engine(?!\s*\()/i);
  const ptoClaimedRow = findRow(mainTables, /pto \(claimed\)/i);
  const beltClaimedRow = findRow(mainTables, /belt \(claimed\)/i);
  const beltTestedRow = findRow(mainTables, /belt \(tested\)/i);
  const ptoTestedRow = findRow(mainTables, /pto \(tested\)/i);
  const drawbarClaimedRow = findRow(mainTables, /drawbar \(claimed\)/i);
  const drawbarTestedRow =
    findRow(testTables, /drawbar power/i) || findRow(mainTables, /drawbar \(tested\)/i);

  const hpOf = (row) => (row ? horsepower(row.value) : null);
  let enginePowerHp =
    hpOf(engineGrossRow) ?? hpOf(engineNetRow) ?? hpOf(engineRow) ?? null;
  let enginePowerSource = engineGrossRow
    ? 'engine_gross'
    : engineNetRow
      ? 'engine_net'
      : engineRow && enginePowerHp != null
        ? 'engine'
        : null;
  if (enginePowerHp == null) {
    const proxy =
      (ptoClaimedRow && { row: ptoClaimedRow, src: 'pto_claimed (proxy)' }) ||
      (beltClaimedRow && { row: beltClaimedRow, src: 'belt_claimed (proxy)' }) ||
      (beltTestedRow && { row: beltTestedRow, src: 'belt_tested (proxy)' }) ||
      (ptoTestedRow && { row: ptoTestedRow, src: 'pto_tested (proxy)' }) ||
      (drawbarClaimedRow && { row: drawbarClaimedRow, src: 'drawbar_claimed (proxy)' }) ||
      (drawbarTestedRow && { row: drawbarTestedRow, src: 'drawbar_tested (proxy)' });
    if (proxy) {
      enginePowerHp = horsepower(proxy.row.value);
      enginePowerSource = proxy.src;
    }
  }
  const ptoClaimedHp = ptoClaimedRow ? horsepower(ptoClaimedRow.value) : null;
  const ptoTestedHp = ptoTestedRow ? horsepower(ptoTestedRow.value) : null;
  const drawbarTestedHp = drawbarTestedRow ? horsepower(drawbarTestedRow.value) : null;

  // ── Mecánica / tracción ────────────────────────────────────
  const weightRowLabels = dimTables
    .filter((r) => r.label && /\d/.test(r.value || ''))
    .map((r) => r.label);
  const traction = resolveTractionType(mainTablesGrouped, text, weightRowLabels);

  // ── Peso ───────────────────────────────────────────────────
  // Las filas de peso viven en una tabla "…Weight" propia o dentro de
  // "Dimensions" con etiquetas tipo "2WD Weight"/"4WD Shipping weight".
  const dimGrouped = dimensions ? splitTables(dimensions) : [];
  const fromWeightTables = dimGrouped
    .filter((t) => t.some((r) => r.section && /weight/i.test(r.section)))
    .flat()
    .filter((r) => r.label);
  const fromWeightLabels = dimTables.filter(
    (r) => r.label && /weight/i.test(r.label) && weightKg(r.value) != null,
  );
  const weightRows = [...fromWeightTables, ...fromWeightLabels].filter(
    (r, i, arr) => arr.findIndex((x) => x.label === r.label && x.value === r.value) === i,
  );
  const prefix = traction.traction_type === '4x2' ? '2WD' : traction.traction_type === '4x4' ? '4WD' : null;
  const weightRow =
    (prefix && weightRows.find((r) => r.label.startsWith(prefix) && weightKg(r.value) != null)) ||
    weightRows.find((r) => !/2WD|4WD/i.test(r.label) && weightKg(r.value) != null) ||
    weightRows.find((r) => weightKg(r.value) != null) ||
    null;
  const weightKgValue = weightRow ? weightKg(weightRow.value) : null;
  const weightBasis = weightRow?.label ?? null;

  // ── Neumáticos (los de tracción trasera llenan las columnas de la BD) ──
  // Dos formatos según el modelo:
  //   a) filas combinadas "Standard tires (ag)": "Front: 9.5-24. Rear: 16.9-28 (4WD)"
  //   b) filas separadas "Ag front"/"Ag rear", con continuaciones sin etiqueta
  const combinedEntries = dimTables
    .filter((r) => (r.label && /Standard tires/i.test(r.label)) || (r.section && /Front:.*Rear:/i.test(r.section)))
    .map((r) => ({ text: r.value ?? r.section, label: r.label ?? '' }));
  let tires2wd = null;
  let tires4wd = null;
  let tiresSingle = null;
  for (const { text: tireValue, label } of combinedEntries) {
    // La variante puede venir como prefijo de la etiqueta ("4WD Standard tires (ag)")
    // o como sufijo del valor ("… Rear: 16.9-28 (4WD)")
    const variant = label.match(/(2WD|4WD)/i)?.[1] || tireValue.match(/\((2WD|4WD)\)/i)?.[1];
    if (/^2WD$/i.test(variant || '')) tires2wd = tireValue;
    else if (/^4WD$/i.test(variant || '')) tires4wd = tireValue;
    else if (!variant && !tiresSingle) tiresSingle = tireValue;
  }

  // Filas separadas, en orden de aparición
  const sep = { front: {}, rear: {} };
  let lastCat = null;
  for (const row of dimTables) {
    const text = (row.value ?? row.section ?? '').trim();
    if (!text || /Front:.*Rear:/i.test(text)) continue;
    // "&nbsp" sin decodificar actúa como etiqueta vacía (filas de continuación)
    const label = row.label && row.label !== '&nbsp' ? row.label : null;
    const looksLikeTire = /^\d/.test(text.split(/[\s,]+/)[0]);
    let cat = null;
    if (label && /front/i.test(label) && !/tread|hitch|loader|weight|axle/i.test(label)) cat = 'front';
    else if (label && /rear/i.test(label) && !/tread|hitch|axle/i.test(label)) cat = 'rear';
    if (cat) lastCat = cat;
    else if (!label && lastCat && looksLikeTire) cat = lastCat; // fila de continuación
    else continue;
    const variant = label?.match(/(2WD|4WD)/i)?.[1] || text.match(/\((2WD|4WD)\)/i)?.[1] || null;
    const store = sep[cat];
    // Continuación sin marcador tras una base = variante alternativa (4WD)
    const key = variant ? variant.toUpperCase() : store.plain || store['4WD'] ? '4WD' : 'plain';
    if (!store[key] && looksLikeTire) {
      store[key] = text.replace(/\(.*?\)/g, '').replace(/[.\s]+$/, '').trim();
    }
  }

  const pickTire = (cat) => {
    const store = sep[cat];
    const order =
      traction.traction_type === '4x2' ? ['2WD', 'plain', '4WD'] : ['4WD', 'plain', '2WD'];
    return order.map((k) => store[k]).find(Boolean) || null;
  };

  let frontTire = null;
  let rearTire = null;
  const combinedText =
    (traction.traction_type === '4x4' ? tires4wd : tires2wd) || tires4wd || tires2wd || tiresSingle;
  if (combinedText) {
    const frontText = combinedText.split(/Rear:/i)[0].match(/Front:\s*(.*?)[.\s]*$/i)?.[1]?.trim() || null;
    const rearText =
      combinedText
        .split(/Rear:/i)[1]
        ?.replace(/\(.*?\)/g, '')
        .replace(/[.\s]+$/, '')
        .trim() || null;
    frontTire = tireInfo(frontText);
    rearTire = tireInfo(rearText);
  }
  if (!frontTire) frontTire = tireInfo(pickTire('front'));
  if (!rearTire) rearTire = tireInfo(pickTire('rear'));

  // ── Combustible (prueba Nebraska: primer "Fuel use" = potencia máxima) ──
  const fuelUseRow = findRow(testTables, /^Fuel use/i);
  const fuelLph = fuelUseRow ? litersPerHour(fuelUseRow.value) : null;

  // ── Tiro: medido si hay prueba; si no, estimado ────────────
  const maxPullRow = findRow(testTables, /^Max pull/i);
  let tractionForceKn = maxPullRow ? forceKn(maxPullRow.value) : null;
  let tractionForceEstimated = false;
  if (tractionForceKn == null) {
    tractionForceKn = estimateTractionKn(ptoTestedHp ?? ptoClaimedHp ?? enginePowerHp);
    tractionForceEstimated = tractionForceKn != null;
  }

  // ── Turbo ──────────────────────────────────────────────────
  const hasTurbo = engine ? /turbocharg/i.test(pageText(engine)) : false;

  // ── Ficha técnica PDF (prueba Nebraska, alojada en unl.edu) ──
  let nebraskaPdf = null;
  if (tests) {
    const pdfMatch = tests.match(/href="([^"]*(?:\.pdf[^"]*|get_file\?uuid=[^"]*))"[^>]*>\s*Nebraska[^<]*test[^<]*file/i)
      || tests.match(/href="(http[^"]*tractortestlab[^"]*)"/i);
    if (pdfMatch) nebraskaPdf = pdfMatch[1].replace(/&amp;/g, '&');
  }

  // ── Foto principal ──
  // Miniatura: <id>-td3a.jpg (180px, ligera). Grande: el <img> con
  // max-width:100% de la ficha (orden de atributos no fijo: style puede ir
  // antes o después de src, por eso se busca el tag completo).
  const photoMatch = main.match(
    /https?:\/\/www\.tractordata\.com\/photos\/F\d+\/\d+\/\d+-td\d+[a-z]?\.jpg/i,
  );
  const photoUrl = photoMatch ? photoMatch[0] : null;
  let photoUrlLarge = null;
  for (const tag of main.match(/<img[^>]+>/gi) || []) {
    if (/max-width:100%/i.test(tag) && /photos\/F\d+/i.test(tag)) {
      const m = tag.match(/src="([^"]+)"/i);
      if (m) { photoUrlLarge = m[1]; break; }
    }
  }

  // ── Ficha técnica cruda (para referencia / futuras columnas) ──
  const specs = {
    ficha_completa: {
      principal: mainTablesGrouped.map(rowsToSpec),
      dimensiones: dimensions ? splitTables(dimensions).map(rowsToSpec) : [],
      pruebas: tests ? splitTables(tests).map(rowsToSpec) : [],
      motor: engine ? splitTables(engine).map(rowsToSpec) : [],
    },
  };

  return {
    fuente: {
      sitio: 'TractorData.com',
      url,
      dimensions_url: dimensions ? url.replace(/\.html$/, '-dimensions.html') : null,
      tests_url: tests ? url.replace(/\.html$/, '-tests.html') : null,
      engine_url: engine ? url.replace(/\.html$/, '-engine.html') : null,
      nebraska_pdf: nebraskaPdf,
      source_id: sourceId,
      licencia: LICENCE_NOTE,
      recuperado: new Date().toISOString(),
    },
    tractor_data_id: sourceId,
    name: h1 || `${brand} ${model}`,
    brand,
    model,
    years: { desde: yearFrom, hasta: yearTo },
    model_year: yearFrom,
    engine_power_hp: enginePowerHp,
    engine_power_source: enginePowerSource,
    pto_claimed_hp: ptoClaimedHp,
    pto_tested_hp: ptoTestedHp,
    drawbar_tested_hp: drawbarTestedHp,
    weight_kg: weightKgValue,
    weight_basis: weightBasis,
    traction_type: traction.traction_type,
    traction_type_derivado: traction.derivado,
    traction_force_kn: tractionForceKn,
    traction_force_estimado: tractionForceEstimated,
    tire_type: rearTire ? `${rearTire.tipo} ${rearTire.original}` : null,
    tire_width_mm: rearTire?.width_mm ?? null,
    tire_diameter_mm: rearTire?.diameter_mm_est ?? null,
    tire_front: frontTire,
    fuel_consumption_lph: fuelLph,
    has_turbo: hasTurbo,
    photo_url: photoUrl,
    photo_url_large: photoUrlLarge,
    image_url: null, // la llena download-images.js con /uploads/tractors/...
    specs,
  };
}
