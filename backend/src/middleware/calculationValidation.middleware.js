/**
 * Middleware de validación para el cálculo de pérdida de potencia
 * Valida los datos del body antes de procesar la solicitud
 */

import {
  isPositiveInteger,
  isPositiveNumber,
  isNonNegativeNumber,
  isNonEmptyString,
  isInRange,
  isValidEnum
} from '../utils/validators.util.js';
import { IMPLEMENT_TYPES, IMPLEMENT_CATALOG } from '../services/implementPowerService.js';

/**
 * Familias de implementos que requieren working_depth_cm (Tabla 1 — Chaparro)
 */
const FAMILIES_REQUIRING_DEPTH = ['draft_plow', 'tined'];

/**
 * Familias de implementos de tiro (drawbar) que requieren working_speed_kmh
 */
const DRAWBAR_FAMILIES = ['draft_plow', 'tined', 'draft_per_meter'];

/**
 * Condiciones de suelo válidas para la corrección Zoz & Grisso (Fig. 47)
 */
const VALID_SOIL_CONDITIONS = ['bueno', 'medio', 'malo'];

/**
 * Middleware para validar la solicitud de cálculo de pérdida de potencia
 * 
 * Reglas de validación:
 * - tractor_id: entero > 0
 * - terrain_id: entero > 0
 * - working_speed_kmh: número > 0 y < 40
 * - carried_objects_weight_kg: número >= 0
 * 
 * @param {import('express').Request} req 
 * @param {import('express').Response} res 
 * @param {import('express').NextFunction} next 
 */
export const validatePowerLossRequest = (req, res, next) => {
  const { 
    tractor_id, 
    terrain_id, 
    working_speed_kmh, 
    carried_objects_weight_kg 
  } = req.body;

  // Validar tractor_id: debe ser entero > 0
  if (tractor_id === undefined || tractor_id === null) {
    return res.status(400).json({ error: 'tractor_id es requerido' });
  }
  if (!isPositiveInteger(tractor_id)) {
    return res.status(400).json({ error: 'tractor_id debe ser un entero mayor a 0' });
  }

  // Validar terrain_id: debe ser entero > 0
  if (terrain_id === undefined || terrain_id === null) {
    return res.status(400).json({ error: 'terrain_id es requerido' });
  }
  if (!isPositiveInteger(terrain_id)) {
    return res.status(400).json({ error: 'terrain_id debe ser un entero mayor a 0' });
  }

  // Validar working_speed_kmh: debe ser número > 0 y < 40
  if (working_speed_kmh === undefined || working_speed_kmh === null) {
    return res.status(400).json({ error: 'working_speed_kmh es requerido' });
  }
  if (!isPositiveNumber(working_speed_kmh)) {
    return res.status(400).json({ error: 'working_speed_kmh debe ser un número mayor a 0' });
  }
  const speedNum = Number(working_speed_kmh);
  if (speedNum >= 40) {
    return res.status(400).json({ error: 'working_speed_kmh debe ser menor a 40 km/h (velocidad agrícola razonable)' });
  }

  // Validar carried_objects_weight_kg: debe ser número >= 0
  if (carried_objects_weight_kg === undefined || carried_objects_weight_kg === null) {
    return res.status(400).json({ error: 'carried_objects_weight_kg es requerido' });
  }
  if (!isNonNegativeNumber(carried_objects_weight_kg)) {
    return res.status(400).json({ error: 'carried_objects_weight_kg debe ser un número mayor o igual a 0' });
  }

  // Convertir valores a números para el controlador
  req.body.tractor_id = Number(tractor_id);
  req.body.terrain_id = Number(terrain_id);
  req.body.working_speed_kmh = Number(working_speed_kmh);
  req.body.carried_objects_weight_kg = Number(carried_objects_weight_kg);

  // Todas las validaciones pasaron
  next();
};

/**
 * Middleware para validar la solicitud de cálculo de potencia mínima de implementos
 * 
 * Reglas de validación:
 * - implement_id: entero > 0
 * - terrain_id: entero > 0
 * - working_depth_m: número > 0 y <= 1.0 (opcional, máx 1 metro)
 * 
 * @param {import('express').Request} req 
 * @param {import('express').Response} res 
 * @param {import('express').NextFunction} next 
 */
export const validateImplementRequirement = (req, res, next) => {
  const { implement_id, terrain_id, working_depth_m } = req.body;

  // Validar implement_id: debe ser entero > 0
  if (implement_id === undefined || implement_id === null) {
    return res.status(400).json({ 
      success: false, 
      error: 'implement_id es requerido' 
    });
  }
  if (!isPositiveInteger(implement_id)) {
    return res.status(400).json({ 
      success: false, 
      error: 'implement_id debe ser un entero mayor a 0' 
    });
  }

  // Validar terrain_id: debe ser entero > 0
  if (terrain_id === undefined || terrain_id === null) {
    return res.status(400).json({ 
      success: false, 
      error: 'terrain_id es requerido' 
    });
  }
  if (!isPositiveInteger(terrain_id)) {
    return res.status(400).json({ 
      success: false, 
      error: 'terrain_id debe ser un entero mayor a 0' 
    });
  }

  // Validar working_depth_m (opcional): si se proporciona, debe ser número > 0 y <= 1.0
  if (working_depth_m !== undefined && working_depth_m !== null) {
    if (!isPositiveNumber(working_depth_m)) {
      return res.status(400).json({ 
        success: false, 
        error: 'working_depth_m debe ser un número mayor a 0' 
      });
    }
    const depthNum = Number(working_depth_m);
    if (depthNum > 1.0) {
      return res.status(400).json({ 
        success: false, 
        error: 'working_depth_m no puede exceder 1.0 metros (profundidad agrícola máxima)' 
      });
    }
    req.body.working_depth_m = depthNum;
  }

  // Convertir IDs a números
  req.body.implement_id = Number(implement_id);
  req.body.terrain_id = Number(terrain_id);

  next();
};

/**
 * Middleware para validar la solicitud de cálculo directo de pérdida de potencia
 * (Flujo "Tengo Tractor" — datos manuales sin IDs de DB)
 *
 * Reglas de validación:
 * - engine_power_hp: número > 0
 * - weight_kg: número > 0
 * - soil_type: string no vacío
 * - altitude_m: número >= 0
 * - ambient_temperature_c: número
 * - slope_percent: número >= 0
 * - slippage_percent: número 0-100
 * - has_turbo: opcional, boolean o 'si'/'no'/'true'/'false'
 * - working_speed_kmh: opcional, número > 0 y < 40 (default 7)
 * - carried_objects_weight_kg: opcional, número >= 0 (default 0)
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const validateDirectPowerLossRequest = (req, res, next) => {
  const {
    engine_power_hp,
    weight_kg,
    soil_type,
    altitude_m,
    ambient_temperature_c,
    slope_percent,
    slippage_percent,
    has_turbo,
    working_speed_kmh,
    carried_objects_weight_kg,
  } = req.body;

  const errors = [];

  // Campos requeridos
  if (engine_power_hp === undefined || engine_power_hp === null) {
    errors.push('engine_power_hp es requerido');
  } else if (!isPositiveNumber(engine_power_hp)) {
    errors.push('engine_power_hp debe ser un número mayor a 0');
  }

  if (weight_kg === undefined || weight_kg === null) {
    errors.push('weight_kg es requerido');
  } else if (!isPositiveNumber(weight_kg)) {
    errors.push('weight_kg debe ser un número mayor a 0');
  }

  if (!soil_type) {
    errors.push('soil_type es requerido');
  } else if (!isNonEmptyString(soil_type)) {
    errors.push('soil_type debe ser un string no vacío');
  }

  if (altitude_m === undefined || altitude_m === null) {
    errors.push('altitude_m es requerido');
  } else if (!isNonNegativeNumber(altitude_m)) {
    errors.push('altitude_m debe ser un número mayor o igual a 0');
  }

  if (ambient_temperature_c === undefined || ambient_temperature_c === null) {
    errors.push('ambient_temperature_c es requerido');
  } else if (typeof Number(ambient_temperature_c) !== 'number' || isNaN(Number(ambient_temperature_c))) {
    errors.push('ambient_temperature_c debe ser un número');
  }

  if (slope_percent === undefined || slope_percent === null) {
    errors.push('slope_percent es requerido');
  } else if (!isNonNegativeNumber(slope_percent)) {
    errors.push('slope_percent debe ser un número mayor o igual a 0');
  }

  if (slippage_percent === undefined || slippage_percent === null) {
    errors.push('slippage_percent es requerido');
  } else if (!isInRange(slippage_percent, 0, 100)) {
    errors.push('slippage_percent debe estar entre 0 y 100');
  }

  // has_turbo: opcional, normalizar
  if (has_turbo !== undefined && has_turbo !== null) {
    const turboStr = String(has_turbo).toLowerCase();
    if (!['si', 'sí', 'no', 'true', 'false', ''].includes(turboStr) && typeof has_turbo !== 'boolean') {
      errors.push('has_turbo debe ser boolean o si/no');
    }
  }

  // working_speed_kmh: opcional
  if (working_speed_kmh !== undefined && working_speed_kmh !== null) {
    if (!isPositiveNumber(working_speed_kmh)) {
      errors.push('working_speed_kmh debe ser un número mayor a 0');
    } else if (Number(working_speed_kmh) >= 40) {
      errors.push('working_speed_kmh debe ser menor a 40 km/h');
    }
  }

  // carried_objects_weight_kg: opcional
  if (carried_objects_weight_kg !== undefined && carried_objects_weight_kg !== null) {
    if (!isNonNegativeNumber(carried_objects_weight_kg)) {
      errors.push('carried_objects_weight_kg debe ser un número mayor o igual a 0');
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Errores de validación',
      errors,
    });
  }

  // Normalizar y asignar defaults
  req.body.engine_power_hp = Number(engine_power_hp);
  req.body.weight_kg = Number(weight_kg);
  req.body.altitude_m = Number(altitude_m);
  req.body.ambient_temperature_c = Number(ambient_temperature_c);
  req.body.slope_percent = Number(slope_percent);
  req.body.slippage_percent = Number(slippage_percent);
  req.body.working_speed_kmh = working_speed_kmh !== undefined ? Number(working_speed_kmh) : 7;
  req.body.carried_objects_weight_kg = carried_objects_weight_kg !== undefined ? Number(carried_objects_weight_kg) : 0;

  // Normalizar has_turbo a boolean
  if (has_turbo !== undefined && has_turbo !== null) {
    const turboStr = String(has_turbo).toLowerCase();
    req.body.has_turbo = turboStr === 'si' || turboStr === 'sí' || turboStr === 'true' || has_turbo === true;
  } else {
    req.body.has_turbo = false;
  }

  next();
};

/**
 * Middleware para validar la solicitud de cálculo directo de potencia mínima
 * (Flujo "Tengo Maquinaria" — datos crudos sin IDs de DB, sin login)
 *
 * Reglas de validación:
 * - power_requirement_hp: número > 0 (requerido)
 * - working_depth_m: número > 0 y <= 1.0 (opcional, default 0.25)
 * - soil_type: string no vacío (requerido)
 * - slope_percentage: número >= 0 (requerido)
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const validateDirectMinimumPowerRequest = (req, res, next) => {
  const {
    power_requirement_hp,
    working_depth_m,
    soil_type,
    slope_percentage,
  } = req.body;

  const errors = [];

  // power_requirement_hp: requerido, número > 0
  if (power_requirement_hp === undefined || power_requirement_hp === null) {
    errors.push('power_requirement_hp es requerido');
  } else if (!isPositiveNumber(power_requirement_hp)) {
    errors.push('power_requirement_hp debe ser un número mayor a 0');
  }

  // soil_type: requerido, string no vacío
  if (!soil_type) {
    errors.push('soil_type es requerido');
  } else if (!isNonEmptyString(soil_type)) {
    errors.push('soil_type debe ser un string no vacío');
  }

  // slope_percentage: requerido, número >= 0
  if (slope_percentage === undefined || slope_percentage === null) {
    errors.push('slope_percentage es requerido');
  } else if (!isNonNegativeNumber(slope_percentage)) {
    errors.push('slope_percentage debe ser un número mayor o igual a 0');
  }

  // working_depth_m: opcional, si se proporciona debe ser > 0 y <= 1.0
  if (working_depth_m !== undefined && working_depth_m !== null) {
    if (!isPositiveNumber(working_depth_m)) {
      errors.push('working_depth_m debe ser un número mayor a 0');
    } else {
      const depthNum = Number(working_depth_m);
      if (depthNum > 1.0) {
        errors.push('working_depth_m no puede exceder 1.0 metros (profundidad agrícola máxima)');
      }
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Errores de validación',
      errors,
    });
  }

  // Normalizar y asignar defaults
  req.body.power_requirement_hp = Number(power_requirement_hp);
  req.body.slope_percentage = Number(slope_percentage);
  req.body.soil_type = soil_type.trim().toLowerCase();
  req.body.working_depth_m = working_depth_m !== undefined && working_depth_m !== null
    ? Number(working_depth_m)
    : 0.25; // Default: profundidad estándar de referencia

  next();
};

/**
 * Valida los parámetros del implemento contra la familia de la Tabla 1
 * (helper compartido por los validadores de implement-power)
 *
 * Reglas (según familia del implement_type):
 * - working_width_m: requerido, 0.1 a 50
 * - working_depth_cm: 0 a 100 (requerido para draft_plow y tined)
 * - working_speed_kmh: > 0 y < 40 (requerido para familias drawbar; no aplica a pto)
 * - n_tines: entero 1 a 20 (requerido para familia tined)
 * - soil_type: string no vacío (solo flujo directo; en flujo DB viene del terreno)
 *
 * @param {Object} body - req.body a validar
 * @param {Object} options - { requireSoilType: boolean }
 * @param {string[]} errors - Array donde se acumulan los errores
 * @returns {string|null} Familia del implemento (o null si el tipo es inválido)
 */
const validateImplementParamsByFamily = (body, { requireSoilType }, errors) => {
  const {
    implement_type,
    working_width_m,
    working_depth_cm,
    working_speed_kmh,
    n_tines,
    soil_type,
  } = body;

  // implement_type: requerido y dentro del enum de la Tabla 1
  if (implement_type === undefined || implement_type === null) {
    errors.push('implement_type es requerido');
    return null;
  }
  if (!isValidEnum(implement_type, IMPLEMENT_TYPES)) {
    errors.push(`implement_type debe ser uno de: ${IMPLEMENT_TYPES.join(', ')}`);
    return null;
  }

  const family = IMPLEMENT_CATALOG[implement_type].family;

  // working_width_m: requerido, entre 0.1 y 50
  if (working_width_m === undefined || working_width_m === null) {
    errors.push('working_width_m es requerido');
  } else if (!isInRange(working_width_m, 0.1, 50)) {
    errors.push('working_width_m debe estar entre 0.1 y 50 metros');
  }

  // working_depth_cm: 0 a 100 (requerido para draft_plow y tined)
  if (working_depth_cm !== undefined && working_depth_cm !== null) {
    if (!isInRange(working_depth_cm, 0, 100)) {
      errors.push('working_depth_cm debe estar entre 0 y 100 cm');
    }
  } else if (FAMILIES_REQUIRING_DEPTH.includes(family)) {
    errors.push('working_depth_cm es requerido para este tipo de implemento');
  }

  // working_speed_kmh: > 0 y < 40 (requerido para familias drawbar, no para pto)
  if (working_speed_kmh !== undefined && working_speed_kmh !== null) {
    if (!isPositiveNumber(working_speed_kmh) || Number(working_speed_kmh) >= 40) {
      errors.push('working_speed_kmh debe ser un número mayor a 0 y menor a 40 km/h');
    }
  } else if (DRAWBAR_FAMILIES.includes(family)) {
    errors.push('working_speed_kmh es requerido para este tipo de implemento');
  }

  // n_tines: entero 1 a 20 (requerido para familia tined)
  if (family === 'tined') {
    if (n_tines === undefined || n_tines === null) {
      errors.push('n_tines es requerido para este tipo de implemento');
    } else if (!Number.isInteger(Number(n_tines)) || Number(n_tines) < 1 || Number(n_tines) > 20) {
      errors.push('n_tines debe ser un entero entre 1 y 20');
    }
  } else if (n_tines !== undefined && n_tines !== null) {
    if (!Number.isInteger(Number(n_tines)) || Number(n_tines) < 1 || Number(n_tines) > 20) {
      errors.push('n_tines debe ser un entero entre 1 y 20');
    }
  }

  // soil_type: requerido solo en el flujo directo (en flujo DB viene del terreno)
  if (requireSoilType) {
    if (!soil_type) {
      errors.push('soil_type es requerido');
    } else if (!isNonEmptyString(soil_type)) {
      errors.push('soil_type debe ser un string no vacío');
    }
  }

  return family;
};

/**
 * Middleware para validar la solicitud de cálculo directo de potencia por implemento
 * (Flujo manual — Tabla 1 de Chaparro + corrección Zoz & Grisso, sin IDs de DB)
 *
 * Reglas de validación:
 * - implement_type: requerido, dentro del enum de la Tabla 1
 * - working_width_m: requerido, 0.1 a 50
 * - working_depth_cm: 0 a 100 (requerido para draft_plow y tined)
 * - working_speed_kmh: > 0 y < 40 (requerido para familias drawbar; no requerido para pto)
 * - n_tines: entero 1 a 20 (requerido para familia tined)
 * - soil_type: string no vacío (requerido)
 * - engine_power_hp: número > 0 (opcional, potencia del tractor; si falta el
 *   endpoint retorna solo la potencia requerida por el implemento)
 * - traction_type: opcional, string no vacío (mapeo Zoz acepta aliases)
 * - soil_condition: opcional, 'bueno' | 'medio' | 'malo' (default 'medio')
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const validateDirectImplementPowerRequest = (req, res, next) => {
  const {
    soil_type,
    engine_power_hp,
    soil_condition,
    traction_type,
  } = req.body;

  const errors = [];

  // Parámetros del implemento según familia (Tabla 1)
  const family = validateImplementParamsByFamily(req.body, { requireSoilType: true }, errors);

  // engine_power_hp: opcional, número > 0 (potencia bruta del tractor).
  // Si no viene, el endpoint retorna solo la potencia requerida por el implemento.
  if (engine_power_hp !== undefined && engine_power_hp !== null && !isPositiveNumber(engine_power_hp)) {
    errors.push('engine_power_hp debe ser un número mayor a 0');
  }

  // soil_condition: opcional, enum de la Fig. 47
  if (soil_condition !== undefined && soil_condition !== null) {
    if (!isValidEnum(String(soil_condition).toLowerCase(), VALID_SOIL_CONDITIONS)) {
      errors.push('soil_condition debe ser uno de: bueno, medio, malo');
    }
  }

  // traction_type: opcional; si viene, debe ser string no vacío (el mapeo Zoz acepta aliases)
  if (traction_type !== undefined && traction_type !== null && !isNonEmptyString(String(traction_type))) {
    errors.push('traction_type debe ser un string no vacío');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Errores de validación',
      errors,
    });
  }

  // Normalizar y asignar defaults
  req.body.implement_type = String(req.body.implement_type).trim();
  req.body.working_width_m = Number(req.body.working_width_m);
  if (req.body.working_depth_cm !== undefined && req.body.working_depth_cm !== null) {
    req.body.working_depth_cm = Number(req.body.working_depth_cm);
  }
  if (DRAWBAR_FAMILIES.includes(family)) {
    req.body.working_speed_kmh = Number(req.body.working_speed_kmh);
  }
  if (IMPLEMENT_CATALOG[req.body.implement_type].family === 'tined') {
    req.body.n_tines = Number(req.body.n_tines);
  }
  req.body.soil_type = String(soil_type).trim().toLowerCase();
  if (engine_power_hp !== undefined && engine_power_hp !== null) {
    req.body.engine_power_hp = Number(engine_power_hp);
  }
  req.body.soil_condition = soil_condition != null ? String(soil_condition).toLowerCase() : 'medio';
  req.body.has_turbo = req.body.has_turbo === true || ['si', 'sí', 'true'].includes(String(req.body.has_turbo ?? '').toLowerCase());
  req.body.altitude_m = req.body.altitude_m !== undefined && req.body.altitude_m !== null ? Number(req.body.altitude_m) : 0;
  req.body.ambient_temperature_c = req.body.ambient_temperature_c !== undefined && req.body.ambient_temperature_c !== null ? Number(req.body.ambient_temperature_c) : 15;
  req.body.total_weight_kg = req.body.total_weight_kg !== undefined && req.body.total_weight_kg !== null ? Number(req.body.total_weight_kg) : 0;
  req.body.slope_percent = req.body.slope_percent !== undefined && req.body.slope_percent !== null ? Number(req.body.slope_percent) : 0;

  next();
};

/**
 * Middleware para validar la solicitud de cálculo de potencia por implemento (flujo DB)
 * Acepta implement_id (usa datos de la BD) O parámetros explícitos del implemento.
 *
 * Reglas de validación:
 * - tractor_id: entero > 0 (requerido)
 * - terrain_id: entero > 0 (requerido)
 * - implement_id: entero > 0 (opcional; si falta, implement_type y working_width_m son requeridos)
 * - working_speed_kmh: > 0 y < 40 (requerido si implement_type explícito es drawbar; validado si viene)
 * - soil_condition: opcional, 'bueno' | 'medio' | 'malo'
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export const validateImplementPowerRequest = (req, res, next) => {
  const {
    tractor_id,
    terrain_id,
    implement_id,
    implement_type,
    soil_condition,
  } = req.body;

  const errors = [];

  // tractor_id: requerido, entero > 0
  if (tractor_id === undefined || tractor_id === null) {
    errors.push('tractor_id es requerido');
  } else if (!isPositiveInteger(tractor_id)) {
    errors.push('tractor_id debe ser un entero mayor a 0');
  }

  // terrain_id: requerido, entero > 0
  if (terrain_id === undefined || terrain_id === null) {
    errors.push('terrain_id es requerido');
  } else if (!isPositiveInteger(terrain_id)) {
    errors.push('terrain_id debe ser un entero mayor a 0');
  }

  // implement_id: opcional, entero > 0
  if (implement_id !== undefined && implement_id !== null && !isPositiveInteger(implement_id)) {
    errors.push('implement_id debe ser un entero mayor a 0');
  }

  // Sin implement_id: los parámetros explícitos del implemento son obligatorios
  // (soil_type no se exige: en flujo DB se toma del terreno)
  const hasExplicitImplement = implement_type !== undefined && implement_type !== null;
  if (implement_id === undefined || implement_id === null) {
    validateImplementParamsByFamily(req.body, { requireSoilType: false }, errors);
  } else if (hasExplicitImplement) {
    // implement_id presente: implement_type es opcional (override puntual).
    // Si viene, validar contra el enum; el resto de overrides los valida el servicio.
    if (!isValidEnum(implement_type, IMPLEMENT_TYPES)) {
      errors.push(`implement_type debe ser uno de: ${IMPLEMENT_TYPES.join(', ')}`);
    }
  }

  // working_speed_kmh: si viene, validar rango (el controlador la exige para drawbar)
  if (req.body.working_speed_kmh !== undefined && req.body.working_speed_kmh !== null) {
    if (!isPositiveNumber(req.body.working_speed_kmh) || Number(req.body.working_speed_kmh) >= 40) {
      errors.push('working_speed_kmh debe ser un número mayor a 0 y menor a 40 km/h');
    }
  }

  // soil_condition: opcional, enum de la Fig. 47
  if (soil_condition !== undefined && soil_condition !== null) {
    if (!isValidEnum(String(soil_condition).toLowerCase(), VALID_SOIL_CONDITIONS)) {
      errors.push('soil_condition debe ser uno de: bueno, medio, malo');
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Errores de validación',
      errors,
    });
  }

  // Normalizar IDs
  req.body.tractor_id = Number(tractor_id);
  req.body.terrain_id = Number(terrain_id);
  if (implement_id !== undefined && implement_id !== null) {
    req.body.implement_id = Number(implement_id);
  }
  if (soil_condition !== undefined && soil_condition !== null) {
    req.body.soil_condition = String(soil_condition).toLowerCase();
  }

  next();
};

export default validatePowerLossRequest;
