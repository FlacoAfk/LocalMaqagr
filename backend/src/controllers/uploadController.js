/**
 * Upload Controller
 * Handles image uploads for tractors and implements
 * Returns public URLs after uploading to the local filesystem
 */
import {
  uploadImage as uploadToStorage,
  deleteImage as deleteFromStorage,
  extractImagePath,
  DELETE_RESULT_CODES,
} from '../config/storage.js';
import { asyncHandler } from '../middleware/error.middleware.js';
import logger from '../utils/logger.js';

/**
 * Upload an image and return the public URL
 * POST /api/upload
 * Accepts multipart/form-data with 'image' field
 * Optional: 'folder' field to specify subfolder (tractors, implements)
 */
export const uploadImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: 'No se proporcionó ninguna imagen. Envía un archivo en el campo "image".',
    });
  }

  const { folder = 'general' } = req.body;
  const allowedFolders = ['tractors', 'implements', 'users', 'general'];

  if (!allowedFolders.includes(folder)) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: `Carpeta inválida. Opciones: ${allowedFolders.join(', ')}`,
    });
  }

  try {
    const publicUrl = await uploadToStorage(req.file, folder);

    logger.info('Image uploaded', { url: publicUrl, folder });

    return res.status(201).json({
      success: true,
      message: 'Imagen subida exitosamente',
      data: {
        url: publicUrl,
        folder,
        filename: publicUrl.replace('/uploads/', ''),
        mimetype: req.file.mimetype,
        size: req.file.size,
      },
    });
  } catch (error) {
    logger.error('Error uploading image to storage', { error: error.message });
    return res.status(500).json({
      success: false,
      code: 'UPLOAD_ERROR',
      message: 'Error al subir la imagen. Intenta de nuevo.',
    });
  }
});

/**
 * Delete an image from storage by URL
 * DELETE /api/upload
 * Accepts JSON body with 'url' field
 */
export const deleteImage = asyncHandler(async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: 'URL de imagen es requerida',
    });
  }

  const storagePath = extractImagePath(url);

  if (!storagePath) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: 'La URL no pertenece al almacenamiento del proyecto',
    });
  }

  const deleteResult = await deleteFromStorage(url);
  const resultCode = deleteResult?.code
    || (deleteResult === true ? DELETE_RESULT_CODES.DELETED : DELETE_RESULT_CODES.IO_ERROR);

  if (resultCode === DELETE_RESULT_CODES.PERMISSION_DENIED) {
    return res.status(503).json({
      success: false,
      code: 'STORAGE_PERMISSION_DENIED',
      message: 'No se pudo eliminar la imagen por falta de permisos en el almacenamiento.',
    });
  }

  if (resultCode === DELETE_RESULT_CODES.IO_ERROR) {
    return res.status(500).json({
      success: false,
      code: 'STORAGE_IO_ERROR',
      message: 'No se pudo eliminar la imagen del almacenamiento. Intenta de nuevo.',
    });
  }

  if (resultCode === DELETE_RESULT_CODES.INVALID_PATH) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: 'La URL no pertenece al almacenamiento del proyecto',
    });
  }

  logger.info('Image deleted', { url });

  return res.json({
    success: true,
    message: 'Imagen eliminada exitosamente',
  });
});

export default { uploadImage, deleteImage };
