const ALLOWED_TRACTION_TYPES = ['4x2', '4x4', 'track'];
const ALLOWED_STATUS = ['available', 'maintenance', 'inactive', 'out_of_service'];
// Tipos genéricos del CRUD + los 9 implementos de la Tabla 1 (Chaparro) usados
// por el cálculo de potencia por implemento (implementPowerService).
const ALLOWED_IMPLEMENT_TYPES = [
  'plow', 'harrow', 'seeder', 'sprayer', 'harvester', 'cultivator', 'mower', 'trailer', 'other',
  'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
  'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
  'rastra_pesada_26', 'rastra_pesada_24',
];

import { isValidLocalImagePath } from '../config/storage.js';

const isValidImageReference = (value, localSubdir) => {
  if (typeof value !== 'string' || !value.trim()) return false;

  const imageUrl = value.trim();
  if (/^https?:\/\//i.test(imageUrl)) {
    try {
      const parsed = new URL(imageUrl);
      return ['http:', 'https:'].includes(parsed.protocol) && Boolean(parsed.hostname);
    } catch {
      return false;
    }
  }

  return isValidLocalImagePath(imageUrl, localSubdir);
};

export const validateTractor = (req, res, next) => {
  const errors = [];
  const {
    brand,
    model,
    image_url,
    model_year,
    engine_power_hp,
    price,
    weight_kg,
    fuel_tank_l,
    traction_type,
    status,
  } = req.body || {};

  const isCreate = req.method === 'POST';

  if (isCreate) {
    if (!brand || typeof brand !== 'string' || !brand.trim()) {
      errors.push('brand es requerido');
    }

    if (!model || typeof model !== 'string' || !model.trim()) {
      errors.push('model es requerido');
    }

    if (
      engine_power_hp === undefined ||
      engine_power_hp === null ||
      `${engine_power_hp}`.trim() === ''
    ) {
      errors.push('engine_power_hp es requerido');
    }

    if (!traction_type || typeof traction_type !== 'string' || !traction_type.trim()) {
      errors.push('traction_type es requerido');
    }
  } else {
    if (brand !== undefined && (!brand || !`${brand}`.trim())) {
      errors.push('brand no puede estar vacío');
    }

    if (model !== undefined && (!model || !`${model}`.trim())) {
      errors.push('model no puede estar vacío');
    }
  }

  const positiveFields = [
    { name: 'model_year', value: model_year },
    { name: 'engine_power_hp', value: engine_power_hp },
    { name: 'price', value: price },
    { name: 'weight_kg', value: weight_kg },
    { name: 'fuel_tank_l', value: fuel_tank_l },
  ];

  positiveFields.forEach(({ name, value }) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      const num = Number(value);
      if (Number.isNaN(num) || num <= 0) {
        errors.push(`${name} debe ser un número positivo`);
      }
    }
  });

  if (model_year !== undefined && model_year !== null && `${model_year}`.trim() !== '') {
    const yearNum = Number(model_year);
    if (!Number.isInteger(yearNum) || yearNum < 1900 || yearNum > 2100) {
      errors.push('model_year debe ser un año válido entre 1900 y 2100');
    }
  }

  if (image_url !== undefined && image_url !== null) {
    if (!isValidImageReference(image_url, 'tractors')) {
      errors.push('image_url debe ser una URL http/https o una ruta local válida de tractor');
    }
  }

  if (traction_type !== undefined && traction_type !== null && `${traction_type}`.trim() !== '') {
    if (!ALLOWED_TRACTION_TYPES.includes(traction_type)) {
      errors.push(`traction_type debe ser uno de: ${ALLOWED_TRACTION_TYPES.join(', ')}`);
    }
  }

  if (status !== undefined && status !== null && `${status}`.trim() !== '') {
    if (!ALLOWED_STATUS.includes(status)) {
      errors.push(`status debe ser uno de: ${ALLOWED_STATUS.join(', ')}`);
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      errors,
    });
  }

  return next();
};

// ============================================
// VALIDACIÓN DE IMPLEMENTOS
// ============================================

export const validateImplement = (req, res, next) => {
  const errors = [];
  const {
    implement_name,
    brand,
    image_url,
    power_requirement_hp,
    working_width_m,
    working_depth_cm,
    n_tines,
    weight_kg,
    implement_type,
    status,
  } = req.body || {};

  const isCreate = req.method === 'POST';

  // Campos requeridos en creación
  if (isCreate) {
    if (!implement_name || typeof implement_name !== 'string' || !implement_name.trim()) {
      errors.push('implement_name es requerido');
    }

    if (!brand || typeof brand !== 'string' || !brand.trim()) {
      errors.push('brand es requerido');
    }

    if (
      power_requirement_hp === undefined ||
      power_requirement_hp === null ||
      `${power_requirement_hp}`.trim() === ''
    ) {
      errors.push('power_requirement_hp es requerido');
    }

    if (
      working_width_m === undefined ||
      working_width_m === null ||
      `${working_width_m}`.trim() === ''
    ) {
      errors.push('working_width_m es requerido');
    }

    if (!implement_type || typeof implement_type !== 'string' || !implement_type.trim()) {
      errors.push('implement_type es requerido');
    }
  } else {
    // Validación para actualización - campos no pueden estar vacíos si se envían
    if (implement_name !== undefined && (!implement_name || !`${implement_name}`.trim())) {
      errors.push('implement_name no puede estar vacío');
    }

    if (brand !== undefined && (!brand || !`${brand}`.trim())) {
      errors.push('brand no puede estar vacío');
    }
  }

  // Validar campos numéricos positivos
  const positiveFields = [
    { name: 'power_requirement_hp', value: power_requirement_hp },
    { name: 'working_width_m', value: working_width_m },
    { name: 'working_depth_cm', value: working_depth_cm },
    { name: 'weight_kg', value: weight_kg },
  ];

  positiveFields.forEach(({ name, value }) => {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      const num = Number(value);
      if (Number.isNaN(num) || num <= 0) {
        errors.push(`${name} debe ser un número positivo`);
      }
    }
  });

  // Validar n_tines (opcional): entero entre 1 y 20 o null
  if (n_tines !== undefined && n_tines !== null && `${n_tines}`.trim() !== '') {
    const tines = Number(n_tines);
    if (!Number.isInteger(tines) || tines < 1 || tines > 20) {
      errors.push('n_tines debe ser un entero entre 1 y 20');
    }
  }

  // Validar enum implement_type
  if (implement_type !== undefined && implement_type !== null && `${implement_type}`.trim() !== '') {
    if (!ALLOWED_IMPLEMENT_TYPES.includes(implement_type)) {
      errors.push(`implement_type debe ser uno de: ${ALLOWED_IMPLEMENT_TYPES.join(', ')}`);
    }
  }

  if (image_url !== undefined && image_url !== null) {
    if (!isValidImageReference(image_url, 'implements')) {
      errors.push('image_url debe ser una URL http/https o una ruta local válida de implemento');
    }
  }

  // Validar enum status
  if (status !== undefined && status !== null && `${status}`.trim() !== '') {
    if (!ALLOWED_STATUS.includes(status)) {
      errors.push(`status debe ser uno de: ${ALLOWED_STATUS.join(', ')}`);
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      errors,
    });
  }

  return next();
};

export default {
  validateTractor,
  validateImplement,
};
