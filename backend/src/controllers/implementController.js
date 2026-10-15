import Implement from "../models/Implement.js";
import { asyncHandler } from "../middleware/error.middleware.js";
import { applyPagination } from "../utils/pagination.util.js";
import { uploadToGCS, deleteFromGCS, extractGCSPath } from '../config/storage.js';
import logger from '../utils/logger.js';

export const getAllImplements = asyncHandler(async (req, res) => {
  const implementsList = await Implement.getAll();
  const { limit = 10, sort = null, order = "asc", page = 1 } = req.pagination || {};

  const sortedRows = [...implementsList];

  if (sort && sortedRows.length > 0 && Object.prototype.hasOwnProperty.call(sortedRows[0], sort)) {
    sortedRows.sort((a, b) => {
      let valA = a[sort];
      let valB = b[sort];

      if (typeof valA === "string") valA = valA.toLowerCase();
      if (typeof valB === "string") valB = valB.toLowerCase();

      if (valA < valB) return order === "desc" ? 1 : -1;
      if (valA > valB) return order === "desc" ? -1 : 1;
      return 0;
    });
  }

  const startIndex = (page - 1) * limit;
  const rows = sortedRows.slice(startIndex, startIndex + limit);
  const { data, pagination } = applyPagination(rows, sortedRows.length, page, limit);

  return res.json({
    success: true,
    data,
    pagination: {
      ...pagination,
      totalPages: pagination.pages,
    },
  });
});

export const getImplementById = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  if (Number.isNaN(id) || id <= 0) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "ID de implemento inválido",
    });
  }

  const implementItem = await Implement.findById(id);

  if (!implementItem) {
    return res.status(404).json({
      success: false,
      code: "NOT_FOUND",
      message: "Implemento no encontrado",
    });
  }

  return res.json({
    success: true,
    data: implementItem,
  });
});

import Tractor from "../models/Tractor.js";

export const searchImplements = asyncHandler(async (req, res) => {
  const {
    q,
    type,
    minWidth,
    maxWidth,
    minPower,
    maxPower,
    maxWeight,
    requiredPower,
    tractorId,
  } = req.query;
  const { limit, page, sort, order } = req.pagination;
  const offset = (page - 1) * limit;

  const parseOptionalNumber = (value) =>
    value === undefined || value === null || value === "" ? null : Number(value);
  const minWidthNum = parseOptionalNumber(minWidth);
  const maxWidthNum = parseOptionalNumber(maxWidth);
  const minPowerNum = parseOptionalNumber(minPower);
  const maxPowerNum = parseOptionalNumber(maxPower);
  const maxWeightNum = parseOptionalNumber(maxWeight);
  const requiredPowerNum = parseOptionalNumber(requiredPower);

  const invalidNonNegativeFilter = (value) =>
    value !== null && (!Number.isFinite(value) || value < 0);

  // Validate numeric filters
  if (invalidNonNegativeFilter(minWidthNum)) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "minWidth debe ser un número positivo",
    });
  }

  if (invalidNonNegativeFilter(maxWidthNum)) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "maxWidth debe ser un número positivo",
    });
  }

  if (
    minWidthNum !== null &&
    maxWidthNum !== null &&
    minWidthNum > maxWidthNum
  ) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "minWidth no puede ser mayor que maxWidth",
    });
  }

  if (
    invalidNonNegativeFilter(requiredPowerNum)
  ) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "requiredPower debe ser un número positivo",
    });
  }

  if (invalidNonNegativeFilter(minPowerNum)) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "minPower debe ser un número positivo",
    });
  }

  if (invalidNonNegativeFilter(maxPowerNum)) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "maxPower debe ser un número positivo",
    });
  }

  if (invalidNonNegativeFilter(maxWeightNum)) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "maxWeight debe ser un número positivo",
    });
  }

  if (
    minPowerNum !== null &&
    maxPowerNum !== null &&
    minPowerNum > maxPowerNum
  ) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "minPower no puede ser mayor que maxPower",
    });
  }

  let tractorPower = null;
  if (tractorId) {
    const parsedTractorId = parseInt(tractorId, 10);
    if (Number.isNaN(parsedTractorId) || parsedTractorId <= 0) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "ID de tractor inválido",
      });
    }

    const tractor = await Tractor.findById(parsedTractorId);
    if (!tractor) {
      return res.status(404).json({
        success: false,
        code: "NOT_FOUND",
        message: "Tractor referenciado no encontrado",
      });
    }

    tractorPower = tractor.engine_power_hp;
  }

  const filters = {
    q: q || null,
    type: type || null,
    minWidth: minWidthNum,
    maxWidth: maxWidthNum,
    minPower: minPowerNum,
    maxPower: maxPowerNum,
    maxWeight: maxWeightNum,
    requiredPower: requiredPowerNum,
    page,
    limit,
    offset,
    sort,
    order,
  };

  const { data, total } = await Implement.advancedSearch(filters, tractorPower);
  const totalPages = Math.ceil(total / limit);

  return res.json({
    success: true,
    data,
    pagination: {
      page,
      limit,
      total,
      totalPages,
    },
    filters: {
      q: q || null,
      type: type || null,
      minWidth: minWidthNum,
      maxWidth: maxWidthNum,
      minPower: minPowerNum,
      maxPower: maxPowerNum,
      maxWeight: maxWeightNum,
      requiredPower: requiredPowerNum,
      tractorId: tractorId ? parseInt(tractorId, 10) : null,
    },
  });
});

export const getAvailableImplements = asyncHandler(async (req, res) => {
  const implementsList = await Implement.getAvailable();
  const { limit = 10, sort = null, order = "asc", page = 1 } = req.pagination || {};

  const sortedRows = [...implementsList];

  if (sort && sortedRows.length > 0 && Object.prototype.hasOwnProperty.call(sortedRows[0], sort)) {
    sortedRows.sort((a, b) => {
      let valA = a[sort];
      let valB = b[sort];

      if (typeof valA === "string") valA = valA.toLowerCase();
      if (typeof valB === "string") valB = valB.toLowerCase();

      if (valA < valB) return order === "desc" ? 1 : -1;
      if (valA > valB) return order === "desc" ? -1 : 1;
      return 0;
    });
  }

  const startIndex = (page - 1) * limit;
  const rows = sortedRows.slice(startIndex, startIndex + limit);
  const { data, pagination } = applyPagination(rows, sortedRows.length, page, limit);

  return res.json({
    success: true,
    data,
    pagination: {
      ...pagination,
      totalPages: pagination.pages,
    },
  });
});

// ============================================
// OPERACIONES DE ESCRITURA (ADMIN)
// ============================================

export const createImplement = asyncHandler(async (req, res) => {
  const {
    implement_name,
    brand,
    power_requirement_hp,
    working_width_m,
    soil_type,
    working_depth_cm,
    n_tines,
    weight_kg,
    implement_type,
    status,
  } = req.body || {};

  // If a file was uploaded, save to local storage
  let image_url = req.body?.image_url;
  if (req.file) {
    try {
      image_url = await uploadToGCS(req.file, 'implements');
    } catch (uploadError) {
      logger.error('Error uploading implement image', { error: uploadError.message });
      return res.status(500).json({
        success: false,
        code: 'UPLOAD_ERROR',
        message: 'Error al subir la imagen del implemento',
      });
    }
  }

  // Validaciones de negocio
  if (
    power_requirement_hp !== undefined &&
    (Number(power_requirement_hp) < 10 || Number(power_requirement_hp) > 500)
  ) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "La potencia requerida debe estar entre 10 y 500 HP",
    });
  }

  // n_tines: opcional; si viene debe ser un entero entre 1 y 20
  if (n_tines !== undefined && n_tines !== null) {
    const tines = Number(n_tines);
    if (!Number.isInteger(tines) || tines < 1 || tines > 20) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "n_tines debe ser un entero entre 1 y 20",
      });
    }
  }

  const payload = {
    implement_name,
    brand,
    image_url,
    power_requirement_hp:
      power_requirement_hp !== undefined && power_requirement_hp !== null
        ? Number(power_requirement_hp)
        : undefined,
    working_width_m:
      working_width_m !== undefined && working_width_m !== null
        ? Number(working_width_m)
        : undefined,
    soil_type,
    working_depth_cm:
      working_depth_cm !== undefined && working_depth_cm !== null
        ? Number(working_depth_cm)
        : undefined,
    n_tines:
      n_tines !== undefined && n_tines !== null
        ? Number(n_tines)
        : undefined,
    weight_kg:
      weight_kg !== undefined && weight_kg !== null
        ? Number(weight_kg)
        : undefined,
    implement_type,
    status,
  };

  const newImplement = await Implement.create(payload);

  return res.status(201).json({
    success: true,
    message: "Implemento creado exitosamente",
    data: newImplement,
  });
});

export const updateImplement = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  if (Number.isNaN(id) || id <= 0) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "ID de implemento inválido",
    });
  }

  const existing = await Implement.findById(id);

  if (!existing) {
    return res.status(404).json({
      success: false,
      code: "NOT_FOUND",
      message: "Implemento no encontrado",
    });
  }

  const {
    implement_name,
    brand,
    power_requirement_hp,
    working_width_m,
    soil_type,
    working_depth_cm,
    n_tines,
    weight_kg,
    implement_type,
    status,
  } = req.body || {};

  // An explicit image_url (including null) is an update instruction. Omission
  // means that the current database value must be preserved.
  let imageUrlProvided = Object.prototype.hasOwnProperty.call(req.body || {}, 'image_url');
  let image_url = imageUrlProvided ? req.body.image_url : undefined;
  if (req.file) {
    try {
      image_url = await uploadToGCS(req.file, 'implements');
      imageUrlProvided = true;
    } catch (uploadError) {
      logger.error('Error uploading implement image', { error: uploadError.message });
      return res.status(500).json({
        success: false,
        code: 'UPLOAD_ERROR',
        message: 'Error al subir la imagen del implemento',
      });
    }
  }

  // Validaciones de negocio
  if (
    power_requirement_hp !== undefined &&
    (Number(power_requirement_hp) < 10 || Number(power_requirement_hp) > 500)
  ) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "La potencia requerida debe estar entre 10 y 500 HP",
    });
  }

  // n_tines: opcional; si viene debe ser un entero entre 1 y 20
  if (n_tines !== undefined && n_tines !== null) {
    const tines = Number(n_tines);
    if (!Number.isInteger(tines) || tines < 1 || tines > 20) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "n_tines debe ser un entero entre 1 y 20",
      });
    }
  }

  const updateData = {
    implement_name,
    brand,
    ...(imageUrlProvided ? { image_url } : {}),
    power_requirement_hp:
      power_requirement_hp !== undefined && power_requirement_hp !== null
        ? Number(power_requirement_hp)
        : undefined,
    working_width_m:
      working_width_m !== undefined && working_width_m !== null
        ? Number(working_width_m)
        : undefined,
    soil_type,
    working_depth_cm:
      working_depth_cm !== undefined && working_depth_cm !== null
        ? Number(working_depth_cm)
        : undefined,
    n_tines:
      n_tines !== undefined && n_tines !== null
        ? Number(n_tines)
        : undefined,
    weight_kg:
      weight_kg !== undefined && weight_kg !== null
        ? Number(weight_kg)
        : undefined,
    implement_type,
    status,
  };

  const updated = await Implement.update(id, updateData);

  if (imageUrlProvided && existing.image_url && existing.image_url !== image_url) {
    const oldPath = extractGCSPath(existing.image_url);
    if (oldPath) {
      try {
        const deleteResult = await deleteFromGCS(existing.image_url);
        if (deleteResult?.ok === false) {
          logger.warn('Failed to delete old implement image', { code: deleteResult.code });
        }
      } catch (deleteError) {
        logger.warn('Failed to delete old implement image', { error: deleteError.message });
      }
    }
  }

  return res.json({
    success: true,
    message: "Implemento actualizado exitosamente",
    data: updated,
  });
});

export const deleteImplement = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  if (Number.isNaN(id) || id <= 0) {
    return res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "ID de implemento inválido",
    });
  }

  const existing = await Implement.findById(id);

  if (!existing) {
    return res.status(404).json({
      success: false,
      code: "NOT_FOUND",
      message: "Implemento no encontrado",
    });
  }

  // Keep the image because this operation archives the row by marking it inactive.
  // Soft delete - cambiar status a 'inactive'
  const updated = await Implement.update(id, { status: "inactive" });

  return res.json({
    success: true,
    message: "Implemento eliminado exitosamente",
    data: updated,
  });
});

export default {
  getAllImplements,
  getImplementById,
  searchImplements,
  getAvailableImplements,
  createImplement,
  updateImplement,
  deleteImplement,
};
