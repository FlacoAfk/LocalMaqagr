/**
 * @overview Servicio de cálculo de potencia requerida por implemento agrícola
 * @module services/implementPowerService
 *
 * @description
 * Implementa la potencia requerida por implemento según la "Tabla 1" del paper de Chaparro
 * (9 implementos, coeficientes por tipo de suelo: arena, limo, arcilla).
 *
 * Familias de cálculo:
 * - draft_plow:      P_hp = ancho_m × prof_cm × velocidad_kmh × CL(velocidad, suelo) × 0.365
 * - tined:           P_hp = T(kgf/cm/rejilla) × n_rejillas × prof_cm × velocidad_kmh × 0.00365
 * - pto:             P_tdf_hp = factor(HA tdf/m) × ancho_m (sin velocidad ni CL)
 * - draft_per_meter: P_hp = T(kgf/m) × ancho_m × velocidad_kmh × 0.00365
 *
 * Todas las funciones son puras (sin acceso a DB), al estilo de powerLossService.
 *
 * @example
 * import { calculateImplementRequiredPower } from './implementPowerService.js';
 *
 * const result = calculateImplementRequiredPower({
 *   implement_type: 'rastra_pesada_26',
 *   working_width_m: 3,
 *   working_speed_kmh: 7.5,
 *   soil_type: 'arcilla',
 * });
 * // result.power_required_hp -> 82.13
 */

// CONSTANTES FÍSICAS (Tabla 1 — Chaparro)

/** Factor de conversión métrico a HP (kgf·km/h -> HP), ≈ 1/274.4 */
export const METRIC_HP_FACTOR = 0.00365;

/**
 * Factor combinado del arado: = 100 × METRIC_HP_FACTOR (0.365).
 * Necesario porque el ancho se expresa en m y la profundidad en cm.
 */
export const PLOW_COMBINED_FACTOR = 0.365;

/**
 * Tabla CL del arado de discos y vertedera (Tabla 1 — Chaparro).
 * Filas: velocidad en km/h (4 a 10). Columnas: [arena, limo, arcilla].
 */
export const CL_TABLA_ARADO = {
  4: [0.21, 0.56, 0.7],
  5: [0.21, 0.6, 0.73],
  6: [0.22, 0.63, 0.77],
  7: [0.24, 0.7, 0.85],
  8: [0.26, 0.77, 0.92],
  9: [0.28, 0.84, 1.02],
  10: [0.29, 0.95, 1.12],
};

/** T de subsolador en kgf/cm de profundidad por rejilla — [arena, limo, arcilla] */
export const T_SUBSOLADOR = [18, 24, 30];

/** T de arado cincel en kgf/cm de profundidad por rejilla — [arena, limo, arcilla] */
export const T_ARADO_CINCEL = [9, 12, 15];

/**
 * Factor del implemento rotativo en HP tdf por metro de ancho — [arena, limo, arcilla].
 * NOTA: 16/24/32 es una reconstrucción basada en el patrón de la tabla de Chaparro.
 * PENDIENTE: debe confirmarse con el profesor.
 */
export const FACTOR_IMPLEMENTO_ROTATIVO = [16, 24, 32];

/** T de rastrillo simple de discos en kgf/m de ancho — [arena, limo, arcilla] */
export const T_RASTRILLO_SIMPLE_DISCOS = [75, 113, 150];

/** T de rastrillo pulidor en kgf/m de ancho — [arena, limo, arcilla] */
export const T_RASTRILLO_PULIDOR = [150, 300, 450];

/** T de rastrillo californiano en kgf/m de ancho — [arena, limo, arcilla] */
export const T_RASTRILLO_CALIFORNIANO = [350, 475, 600];

/** T de rastra pesada de 26 discos en kgf/m de ancho — [arena, limo, arcilla] */
export const T_RASTRA_PESADA_26 = [800, 900, 1000];

/** T de rastra pesada de 24 discos en kgf/m de ancho — [arena, limo, arcilla] */
export const T_RASTRA_PESADA_24 = [700, 800, 900];

// CATÁLOGO DE IMPLEMENTOS (Tabla 1 — Chaparro)

/**
 * Catálogo de los 9 implementos de la Tabla 1.
 * Por tipo: label (es), familia de cálculo, power_kind, unidad del coeficiente,
 * inputs requeridos, constante de la tabla y coeficientes por suelo [arena, limo, arcilla].
 */
export const IMPLEMENT_CATALOG = {
  arado_disco_vertedera: {
    label: 'Arado de discos y vertedera',
    family: 'draft_plow',
    power_kind: 'drawbar',
    coefficient_unit: 'CL adimensional (Tabla 1, según velocidad y suelo)',
    required_inputs: ['working_width_m', 'working_depth_cm', 'working_speed_kmh', 'soil_type'],
    constant_used: 'CL_TABLA_ARADO',
    coefficients: CL_TABLA_ARADO,
  },
  subsolador: {
    label: 'Subsolador',
    family: 'tined',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/cm de profundidad por rejilla',
    required_inputs: ['n_tines', 'working_depth_cm', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_SUBSOLADOR',
    coefficients: T_SUBSOLADOR,
  },
  arado_cincel: {
    label: 'Arado cincel',
    family: 'tined',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/cm de profundidad por rejilla',
    required_inputs: ['n_tines', 'working_depth_cm', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_ARADO_CINCEL',
    coefficients: T_ARADO_CINCEL,
  },
  implemento_rotativo: {
    label: 'Implemento rotativo',
    family: 'pto',
    power_kind: 'pto',
    coefficient_unit: 'HP tdf por metro de ancho',
    required_inputs: ['working_width_m', 'soil_type'],
    constant_used: 'FACTOR_IMPLEMENTO_ROTATIVO',
    coefficients: FACTOR_IMPLEMENTO_ROTATIVO,
  },
  rastrillo_simple_discos: {
    label: 'Rastrillo simple de discos',
    family: 'draft_per_meter',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/m de ancho',
    required_inputs: ['working_width_m', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_RASTRILLO_SIMPLE_DISCOS',
    coefficients: T_RASTRILLO_SIMPLE_DISCOS,
  },
  rastrillo_pulidor: {
    label: 'Rastrillo pulidor',
    family: 'draft_per_meter',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/m de ancho',
    required_inputs: ['working_width_m', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_RASTRILLO_PULIDOR',
    coefficients: T_RASTRILLO_PULIDOR,
  },
  rastrillo_californiano: {
    label: 'Rastrillo californiano',
    family: 'draft_per_meter',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/m de ancho',
    required_inputs: ['working_width_m', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_RASTRILLO_CALIFORNIANO',
    coefficients: T_RASTRILLO_CALIFORNIANO,
  },
  rastra_pesada_26: {
    label: 'Rastra pesada de 26 discos',
    family: 'draft_per_meter',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/m de ancho',
    required_inputs: ['working_width_m', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_RASTRA_PESADA_26',
    coefficients: T_RASTRA_PESADA_26,
  },
  rastra_pesada_24: {
    label: 'Rastra pesada de 24 discos',
    family: 'draft_per_meter',
    power_kind: 'drawbar',
    coefficient_unit: 'kgf/m de ancho',
    required_inputs: ['working_width_m', 'working_speed_kmh', 'soil_type'],
    constant_used: 'T_RASTRA_PESADA_24',
    coefficients: T_RASTRA_PESADA_24,
  },
  personalizado: {
    label: 'Personalizado (tiro manual)',
    family: 'custom',
    // power_kind se determina por draft_unit: kg/m y kg/surco → drawbar; cv/m y hp_tdf/m → pto
    power_kind: null,
    coefficient_unit: 'tiro ingresado por el usuario (kg/m, kg/surco, CV/m o HP tdf/m)',
    required_inputs: ['tiro', 'draft_unit'],
    constant_used: 'TIRO_USUARIO',
    coefficients: null,
  },
};

/** Cn por textura para la rodadura del IMPLEMENTO (lámina 17 del profesor):
 *  duro 50 · firme 30 · labrado 20 · suelto/arenoso 10.
 *  Nota: difiere de la Tabla 2 de Chaparro (arenoso 15) — pendiente de confirmación. */
export const CN_LAMINA17 = { arena: 10, limo: 20, arcilla: 20 };

/** Tipos de implemento soportados (enum) */
export const IMPLEMENT_TYPES = Object.keys(IMPLEMENT_CATALOG);

// FUNCIONES AUXILIARES

/**
 * Redondea a 2 decimales (para valores de salida)
 * @param {number} value - Valor a redondear
 * @returns {number} Valor redondeado a 2 decimales
 */
const round2 = (value) => Math.round(value * 100) / 100;

/**
 * Redondea a 3 decimales (para coeficientes CL interpolados)
 * @param {number} value - Valor a redondear
 * @returns {number} Valor redondeado a 3 decimales
 */
const round3 = (value) => Math.round(value * 1000) / 1000;

/**
 * Normaliza el tipo de suelo a los 3 valores de la Tabla 1 (arena|limo|arcilla)
 * y acumula advertencias cuando el mapeo no es directo.
 *
 * @param {string} soilType - Tipo de suelo (cualquier alias común)
 * @param {string[]} warnings - Array donde se acumulan las advertencias
 * @returns {string} Suelo normalizado (arena|limo|arcilla)
 *
 * @example
 * normalizeSoilType('arenoso', warnings) // -> 'arena'
 * normalizeSoilType('franco', warnings)  // -> 'limo' + warning (la Tabla 1 no tiene franco)
 */
export const normalizeSoilType = (soilType, warnings = []) => {
  const normalized = String(soilType ?? '').toLowerCase().trim();

  const soilAliases = {
    arena: 'arena',
    arenoso: 'arena',
    sand: 'arena',
    sandy: 'arena',
    limo: 'limo',
    silt: 'limo',
    arcilla: 'arcilla',
    arcilloso: 'arcilla',
    clay: 'arcilla',
    // La Tabla 1 no tiene franco: se mapea a limo (suelo intermedio) con advertencia
    franco: 'limo',
    loam: 'limo',
  };

  if (normalized === 'franco' || normalized === 'loam') {
    warnings.push('franco/loam mapeado a limo (la Tabla 1 no tiene franco)');
    return 'limo';
  }

  if (soilAliases[normalized]) {
    return soilAliases[normalized];
  }

  warnings.push(`Tipo de suelo no reconocido ("${soilType ?? 'sin valor'}"), se usa limo por defecto`);
  return 'limo';
};

/**
 * Obtiene el CL del arado para una velocidad dada, interpolando linealmente
 * entre las filas de CL_TABLA_ARADO (4 a 10 km/h).
 * Fuera de rango: se ajusta (clamp) al borde más cercano con advertencia.
 *
 * @param {number} speedKmh - Velocidad de trabajo en km/h
 * @param {string} soil - Suelo normalizado (arena|limo|arcilla)
 * @param {string[]} warnings - Array donde se acumulan las advertencias
 * @returns {{cl: number, interpolated: boolean}} CL y flag de interpolación
 */
const getPlowClForSpeed = (speedKmh, soil, warnings) => {
  const soilColumn = { arena: 0, limo: 1, arcilla: 2 }[soil];

  // Fuera de rango por abajo: clamp a la fila 4 km/h
  if (speedKmh < 4) {
    warnings.push('Velocidad fuera del rango 4-10 km/h de la Tabla 1 (se usó el valor del borde de 4 km/h)');
    return { cl: CL_TABLA_ARADO[4][soilColumn], interpolated: false };
  }

  // Fuera de rango por arriba: clamp a la fila 10 km/h
  if (speedKmh > 10) {
    warnings.push('Velocidad fuera del rango 4-10 km/h de la Tabla 1 (se usó el valor del borde de 10 km/h)');
    return { cl: CL_TABLA_ARADO[10][soilColumn], interpolated: false };
  }

  // Velocidad entera: valor directo de la tabla (sin interpolación)
  const lower = Math.floor(speedKmh);
  if (lower === speedKmh) {
    return { cl: CL_TABLA_ARADO[lower][soilColumn], interpolated: false };
  }

  // Velocidad no entera: interpolación lineal entre filas adyacentes
  const upper = lower + 1;
  const t = speedKmh - lower;
  const cl = CL_TABLA_ARADO[lower][soilColumn] +
    (CL_TABLA_ARADO[upper][soilColumn] - CL_TABLA_ARADO[lower][soilColumn]) * t;
  return { cl: round3(cl), interpolated: true };
};

/**
 * Valida y convierte a número un input requerido
 * @param {*} value - Valor de entrada
 * @param {string} fieldName - Nombre del campo (para el mensaje de error)
 * @returns {number} Valor numérico
 * @throws {Error} Si el valor no es un número válido
 */
const requireNumber = (value, fieldName) => {
  const num = Number(value);
  if (value === undefined || value === null || !Number.isFinite(num)) {
    throw new Error(`${fieldName} es requerido y debe ser un número válido`);
  }
  return num;
};

/**
 * Igual que requireNumber pero exigiendo un valor estrictamente positivo
 * (requireNumber acepta 0; el tiro del usuario debe ser mayor que 0)
 * @param {*} value - Valor de entrada
 * @param {string} fieldName - Nombre del campo (para el mensaje de error)
 * @returns {number} Valor numérico > 0
 * @throws {Error} Si el valor no es un número válido o es <= 0
 */
const requirePositiveNumber = (value, fieldName) => {
  const num = requireNumber(value, fieldName);
  if (num <= 0) {
    throw new Error(`${fieldName} debe ser mayor que 0`);
  }
  return num;
};

// FUNCIÓN PRINCIPAL

/**
 * Calcula la potencia requerida por un implemento según la Tabla 1 de Chaparro
 *
 * @param {Object} input - Parámetros de entrada
 * @param {string} input.implement_type - Tipo de implemento (ver IMPLEMENT_TYPES)
 * @param {number} [input.working_width_m] - Ancho de trabajo en m
 * @param {number} [input.working_depth_cm] - Profundidad de trabajo en cm (requerido para draft_plow y tined)
 * @param {number} [input.working_speed_kmh] - Velocidad de trabajo en km/h (requerido para familias drawbar)
 * @param {number} [input.n_tines] - Cantidad de rejillas (requerido para familia tined, entero 1-20)
 * @param {string} input.soil_type - Tipo de suelo (arena|limo|arcilla o alias)
 * @param {number} [input.tiro] - Tiro manual del usuario (requerido para 'personalizado', > 0)
 * @param {string} [input.draft_unit='kg/m'] - Unidad del tiro ('kg/m' | 'kg/surco' | 'cv/m' | 'hp_tdf/m');
 *   se normaliza (trim + minúsculas) y un valor no reconocido lanza error
 * @param {number} [input.n_surcos] - Cantidad de surcos (requerido para draft_unit 'kg/surco', entero 1-100)
 *
 * @returns {Object} Resultado del cálculo
 * @returns {string} returns.implement_type - Tipo de implemento
 * @returns {string} returns.power_kind - 'drawbar' | 'pto'
 * @returns {number} returns.power_required_hp - Potencia requerida en HP (2 decimales)
 * @returns {Object} returns.detail - Desglose del cálculo
 * @returns {string[]} returns.warnings - Advertencias (mapeo de suelo, velocidad fuera de rango)
 *
 * @throws {Error} Si el tipo de implemento no está soportado o faltan inputs requeridos
 *
 * @example
 * calculateImplementRequiredPower({
 *   implement_type: 'subsolador',
 *   n_tines: 3,
 *   working_depth_cm: 40,
 *   working_speed_kmh: 5,
 *   soil_type: 'limo',
 * });
 * // -> { power_required_hp: 52.56, power_kind: 'drawbar', ... }
 */
export const calculateImplementRequiredPower = (input) => {
  const warnings = [];
  const {
    implement_type,
    working_width_m,
    working_depth_cm,
    working_speed_kmh,
    n_tines,
    soil_type,
    // Modelo F = R_syc + R_r (lám. 32/35): rodadura propia del implemento con ruedas
    implement_weight_kg,
    // Tipo 'personalizado': tiro manual del usuario
    tiro,
    draft_unit = 'kg/m',
    n_surcos,
  } = input || {};

  // 1. Validar tipo de implemento contra el catálogo
  const spec = IMPLEMENT_CATALOG[implement_type];
  if (!spec) {
    throw new Error(
      `Tipo de implemento no soportado: ${implement_type}. Tipos válidos: ${IMPLEMENT_TYPES.join(', ')}`
    );
  }

  // 2. Normalizar suelo (acumula advertencia si hay mapeo)
  const soil = normalizeSoilType(soil_type, warnings);

  // 3. Calcular según la familia del implemento
  let powerHp = 0;
  let coefficient = null;
  let draftForceKgf = null;
  let clInterpolated = false;
  let detailWidth = null;
  let detailDepth = null;
  let detailSpeed = null;
  let detailTines = null;
  let detailSurcos = null;
  // draft_unit normalizado (solo se usa en la familia 'custom')
  let draftUnitNormalized = null;

  if (spec.family === 'draft_plow') {
    // P_hp = ancho_m × prof_cm × velocidad_kmh × CL(velocidad, suelo) × 0.365
    const width = requireNumber(working_width_m, 'working_width_m');
    const depth = requireNumber(working_depth_cm, 'working_depth_cm');
    const speed = requireNumber(working_speed_kmh, 'working_speed_kmh');

    const { cl, interpolated } = getPlowClForSpeed(speed, soil, warnings);
    coefficient = cl;
    clInterpolated = interpolated;

    // Fuerza de tiro implícita: P = F × v × 0.00365  =>  F = ancho × prof × CL × (0.365 / 0.00365)
    draftForceKgf = width * depth * cl * (PLOW_COMBINED_FACTOR / METRIC_HP_FACTOR);
    powerHp = width * depth * speed * cl * PLOW_COMBINED_FACTOR;

    detailWidth = width;
    detailDepth = depth;
    detailSpeed = speed;
  } else if (spec.family === 'tined') {
    // P_hp = T × n_rejillas × prof_cm × velocidad_kmh × 0.00365
    const tines = Number(n_tines);
    if (!Number.isInteger(tines) || tines < 1 || tines > 20) {
      throw new Error('n_tines es requerido y debe ser un entero entre 1 y 20');
    }
    const depth = requireNumber(working_depth_cm, 'working_depth_cm');
    const speed = requireNumber(working_speed_kmh, 'working_speed_kmh');

    coefficient = spec.coefficients[{ arena: 0, limo: 1, arcilla: 2 }[soil]];

    draftForceKgf = coefficient * tines * depth;
    powerHp = coefficient * tines * depth * speed * METRIC_HP_FACTOR;

    detailDepth = depth;
    detailSpeed = speed;
    detailTines = tines;
    if (working_width_m !== undefined && working_width_m !== null) {
      detailWidth = Number(working_width_m);
    }
  } else if (spec.family === 'pto') {
    // P_tdf_hp = factor × ancho_m (profundidad conceptual fija de 10 cm; sin velocidad ni CL)
    const width = requireNumber(working_width_m, 'working_width_m');

    coefficient = spec.coefficients[{ arena: 0, limo: 1, arcilla: 2 }[soil]];
    powerHp = coefficient * width;

    detailWidth = width;
    detailDepth = 10; // Profundidad conceptual fija del implemento rotativo
  } else if (spec.family === 'draft_per_meter') {
    // draft_per_meter: P_hp = T × ancho_m × velocidad_kmh × 0.00365
    const width = requireNumber(working_width_m, 'working_width_m');
    const speed = requireNumber(working_speed_kmh, 'working_speed_kmh');

    coefficient = spec.coefficients[{ arena: 0, limo: 1, arcilla: 2 }[soil]];

    draftForceKgf = coefficient * width;
    powerHp = draftForceKgf * speed * METRIC_HP_FACTOR;

    detailWidth = width;
    detailSpeed = speed;
  } else if (spec.family === 'custom') {
    // Tipo 'personalizado': tiro manual del usuario.
    // Normalización de draft_unit (trim + minúsculas) con advertencia si cambió;
    // un valor no reconocido lanza error (antes caía en 0 HP silencioso).
    const rawDraftUnit = String(draft_unit ?? '');
    draftUnitNormalized = rawDraftUnit.trim().toLowerCase();
    if (rawDraftUnit !== '' && draftUnitNormalized !== rawDraftUnit) {
      warnings.push(`draft_unit normalizado de "${draft_unit}" a "${draftUnitNormalized}"`);
    }
    const VALID_DRAFT_UNITS = ['kg/m', 'kg/surco', 'cv/m', 'hp_tdf/m'];
    if (!VALID_DRAFT_UNITS.includes(draftUnitNormalized)) {
      throw new Error(
        `draft_unit no reconocido: ${JSON.stringify(draft_unit ?? null)}. Valores válidos: ${VALID_DRAFT_UNITS.join(', ')}`
      );
    }

    // El tiro del usuario debe ser positivo (requireNumber acepta 0)
    const tiroVal = requirePositiveNumber(tiro, 'tiro');

    if (draftUnitNormalized === 'kg/m') {
      // Tiro manual por metro: P = tiro × ancho × V × 0.00365 (drawbar)
      const width = requireNumber(working_width_m, 'working_width_m');
      const speed = requireNumber(working_speed_kmh, 'working_speed_kmh');
      coefficient = tiroVal;
      draftForceKgf = tiroVal * width;
      powerHp = draftForceKgf * speed * METRIC_HP_FACTOR;
      detailWidth = width;
      detailSpeed = speed;
    } else if (draftUnitNormalized === 'kg/surco') {
      // Tiro manual por surco: P = tiro × n_surcos × V × 0.00365 (drawbar)
      const rows = Number(n_surcos);
      if (!Number.isInteger(rows) || rows < 1 || rows > 100) {
        throw new Error('n_surcos es requerido y debe ser un entero entre 1 y 100');
      }
      const speed = requireNumber(working_speed_kmh, 'working_speed_kmh');
      coefficient = tiroVal;
      draftForceKgf = tiroVal * rows;
      powerHp = draftForceKgf * speed * METRIC_HP_FACTOR;
      // Contrato: el conteo de surcos viaja en detail.n_surcos, no como ancho
      detailSurcos = rows;
      detailTines = rows;
      detailSpeed = speed;
    } else {
      // Demanda manual en la TDF por metro (cv/m | hp_tdf/m): CV/m → HP con 1 CV = 0,9863 HP
      const width = requireNumber(working_width_m, 'working_width_m');
      coefficient = tiroVal;
      powerHp = draftUnitNormalized === 'cv/m' ? tiroVal * width * 0.9863 : tiroVal * width;
      detailWidth = width;
    }
  }

  // Modelo F = R_syc + R_r (lám. 32/35 del profesor): si el implemento tiene peso propio
  // y es de tiro (drawbar), se suma su resistencia al rodamiento R_r = (1,2/Cn + 0,04) · peso.
  // Cn por textura según la lámina 17 (arena 10 · limo 20 · arcilla 20).
  const weight = Number(implement_weight_kg);
  const isDrawbarFamily =
    spec.power_kind === 'drawbar' ||
    (spec.family === 'custom' &&
      (draftUnitNormalized === 'kg/m' || draftUnitNormalized === 'kg/surco'));
  let implementRrKgf = null;
  let implementCn = null;
  if (weight > 0 && isDrawbarFamily) {
    implementCn = CN_LAMINA17[soil] ?? 20;
    implementRrKgf = (1.2 / implementCn + 0.04) * weight;
    // La rodadura del implemento exige potencia extra en la barra: R_r · V / 274,4
    const speedForRr = Number(working_speed_kmh);
    if (Number.isFinite(speedForRr) && speedForRr > 0) {
      powerHp += implementRrKgf * speedForRr * METRIC_HP_FACTOR;
    } else {
      warnings.push('se ignoró la rodadura del implemento: falta la velocidad de operación');
    }
  }
  if (weight > 0 && !isDrawbarFamily) {
    warnings.push('el peso del implemento no aplica para implementos accionados por la TDF');
  }

  return {
    implement_type,
    power_kind: spec.family === 'custom'
      ? draftUnitNormalized === 'cv/m' || draftUnitNormalized === 'hp_tdf/m'
        ? 'pto'
        : 'drawbar'
      : spec.power_kind,
    power_required_hp: round2(powerHp),
    detail: {
      family: spec.family === 'custom' ? `custom_${draftUnitNormalized}` : spec.family,
      coefficient,
      coefficient_unit: spec.coefficient_unit,
      n_tines: detailTines,
      n_surcos: detailSurcos,
      working_width_m: detailWidth,
      working_depth_cm: detailDepth,
      working_speed_kmh: detailSpeed,
      draft_force_kgf: draftForceKgf !== null ? round2(draftForceKgf) : null,
      constant_used: spec.constant_used,
      cl_interpolated: clInterpolated,
      implement_r_r_kgf: implementRrKgf !== null ? round2(implementRrKgf) : null,
      implement_cn: implementCn,
    },
    warnings,
  };
};

/**
 * Conversión de la potencia requerida en la barra de tiro a su equivalente en la TDF
 * (lámina 19 del profesor): P_tdp = P_bdt / (0,96 × ET), donde 0,96 es la eficiencia
 * eje↔TDP (Fig. 1 de Chaparro / lámina 12) y ET la eficiencia de tracción (Fig. 47).
 */
export const computePtoEquivalent = (pRequiredBdt, et) => {
  if (!Number.isFinite(Number(pRequiredBdt)) || !Number.isFinite(Number(et)) || Number(et) <= 0) {
    return null;
  }
  return round2(Number(pRequiredBdt) / (0.96 * Number(et)));
};
