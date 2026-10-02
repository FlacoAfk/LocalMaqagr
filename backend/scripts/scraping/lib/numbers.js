/** Parseo de números con unidades ("5,070 lbs 2299 kg") y tamaños de neumáticos. */

const UNIT_ALIASES = {
  lb: 'lb', lbs: 'lb', pound: 'lb', pounds: 'lb',
  kg: 'kg', kilogram: 'kg', kilograms: 'kg',
  hp: 'hp', horsepower: 'hp', cv: 'hp',
  kw: 'kW',
  gal: 'gal', gallon: 'gal', gallons: 'gal',
  'l/hour': 'lph', 'liters/hour': 'lph', 'l/hr': 'lph',
  'gal/hour': 'gph',
  l: 'L', liter: 'L', liters: 'L', litre: 'L', litres: 'L',
  qt: 'qt', qts: 'qt', quart: 'qt', quarts: 'qt',
  in: 'in', inch: 'in', inches: 'in',
  cm: 'cm',
  mm: 'mm',
  ft: 'ft',
  mph: 'mph',
  'km/h': 'kmh',
  n: 'N',
  kn: 'kN',
};

/**
 * "5,070 lbs 2299 kg" → [{ value: 5070, unit: 'lb' }, { value: 2299, unit: 'kg' }]
 */
export function parseUnitPairs(text) {
  const pairs = [];
  const re =
    /(-?\d[\d,]*(?:\.\d+)?)\s*(lbs?|pounds?|kg|kilograms?|hp|kW|kWatt|kN|N\b|gal\/hour|l\/hour|liters\/hour|gal|liters?|litres?|qts?|in(?:ches)?|cm|mm|mph|km\/h)/gi;
  let m;
  while ((m = re.exec(text)) !== null) {
    const value = parseFloat(m[1].replace(/,/g, ''));
    if (!Number.isFinite(value)) continue;
    const unit = UNIT_ALIASES[m[2].toLowerCase()];
    if (unit) pairs.push({ value, unit });
  }
  return pairs;
}

/** Primera pareja cuya unidad esté en la lista preferida. */
export function pickUnit(pairs, preferredUnits) {
  for (const u of preferredUnits) {
    const hit = pairs.find((p) => p.unit === u);
    if (hit) return hit.value;
  }
  return null;
}

export function toNumber(s) {
  if (typeof s === 'number') return s;
  const n = parseFloat(String(s).replace(/,/g, ''));
  return Number.isFinite(n) ? n : null;
}

const IN_TO_MM = 25.4;
/** Relación aspecto típica de neumáticos agrícolas (flanco/anchura). */
const ASPECT_RATIO = 0.85;

/**
 * "16.9-28" | "16.9R30" | "7.50-16" | "11L-15" | "280/85R28" →
 * { width_mm, rim_in, radial, diameter_mm_est, original }
 * diameter_mm_est es una estimación (diámetro total ≈ llanta + 2×flanco).
 */
export function parseTire(text) {
  if (!text) return null;
  const t = text.trim();

  // Métrico: 280/85R28
  let m = t.match(/^(\d{3})\s*\/\s*(\d{2})\s*(R|-)\s*(\d{2}(?:\.\d+)?)$/);
  if (m) {
    const widthMm = parseFloat(m[1]);
    const aspect = parseInt(m[2], 10) / 100;
    const rimIn = parseFloat(m[4]);
    return {
      original: t,
      radial: m[3] === 'R',
      width_mm: Math.round(widthMm),
      rim_in: rimIn,
      diameter_mm_est: Math.round(rimIn * IN_TO_MM + 2 * aspect * widthMm),
    };
  }

  // Diámetro × anchura - llanta: 23x8.50-12 (diámetro publicado, sin estimar)
  m = t.match(/^(\d{2}(?:\.\d+)?)\s*x\s*(\d{1,2}(?:\.\d+)?)\s*-\s*(\d{1,2}(?:\.\d+)?)$/);
  if (m) {
    const diameterIn = parseFloat(m[1]);
    const widthIn = parseFloat(m[2]);
    const rimIn = parseFloat(m[3]);
    return {
      original: t,
      radial: false,
      width_mm: Math.round(widthIn * IN_TO_MM),
      rim_in: rimIn,
      diameter_mm_est: Math.round(diameterIn * IN_TO_MM),
    };
  }

  // Imperial: 16.9-28 / 16.9R30 / 7.50-16 / 11L-15 / 6.0x16 / 13.6x28
  m = t.match(/^(\d{1,2}(?:\.\d+)?)\s*(L|R|-|x)\s*(\d{1,2}(?:\.\d+)?)$/);
  if (m) {
    const widthIn = parseFloat(m[1]);
    const rimIn = parseFloat(m[3]);
    return {
      original: t,
      radial: m[2] === 'R',
      width_mm: Math.round(widthIn * IN_TO_MM),
      rim_in: rimIn,
      diameter_mm_est: Math.round((rimIn + 2 * ASPECT_RATIO * widthIn) * IN_TO_MM),
    };
  }

  return null;
}

/**
 * Peso → kg. Prefiere pares en kg; si solo hay lb convierte.
 */
export function weightKg(text) {
  const pairs = parseUnitPairs(text);
  const kg = pickUnit(pairs, ['kg']);
  if (kg != null) return kg;
  const lb = pickUnit(pairs, ['lb']);
  return lb != null ? Math.round(lb * 0.45359237) : null;
}

/** "7,066 lbs 3205 kg" | "13.3 kN" | "13,345 N" → kN */
export function forceKn(text) {
  const pairs = parseUnitPairs(text);
  const kn = pickUnit(pairs, ['kN']);
  if (kn != null) return kn;
  const n = pickUnit(pairs, ['N']);
  if (n != null) return Math.round((n / 1000) * 10) / 10;
  const kg = pickUnit(pairs, ['kg']);
  if (kg != null) return Math.round(((kg * 9.80665) / 1000) * 10) / 10;
  const lb = pickUnit(pairs, ['lb']);
  return lb != null ? Math.round(lb * 0.0044482216 * 10) / 10 : null;
}

/** "64.42 hp 48.0 kW" → hp */
export function horsepower(text) {
  return pickUnit(parseUnitPairs(text), ['hp']);
}

/** "4.1 gal/hour 15.5 l/hour" → 15.5 */
export function litersPerHour(text) {
  return pickUnit(parseUnitPairs(text), ['lph']);
}
