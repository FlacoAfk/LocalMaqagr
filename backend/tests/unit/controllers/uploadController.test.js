/**
 * FIX-004: Coverage para uploadController.js (uploadImage / deleteImage)
 *
 * Aditivo: archivo nuevo; mockea storage (config/storage.js) y logger.
 * asyncHandler no retorna la promesa → se usa flush con setImmediate.
 */
import { describe, test, expect, jest, beforeEach } from '@jest/globals';

const mockStorageUpload = jest.fn();
const mockStorageDelete = jest.fn();
const mockExtractImagePath = jest.fn();
const DELETE_RESULT_CODES = {
  DELETED: 'DELETED',
  NOT_FOUND: 'NOT_FOUND',
  INVALID_PATH: 'INVALID_PATH',
  PERMISSION_DENIED: 'PERMISSION_DENIED',
  IO_ERROR: 'IO_ERROR',
};

jest.unstable_mockModule('../../../src/config/storage.js', () => ({
  uploadImage: mockStorageUpload,
  deleteImage: mockStorageDelete,
  extractImagePath: mockExtractImagePath,
  DELETE_RESULT_CODES,
  __esModule: true,
}));

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  default: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
  __esModule: true,
}));

const { uploadImage, deleteImage } = await import('../../../src/controllers/uploadController.js');

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const callHandler = async (handler, req, res) => {
  handler(req, res, jest.fn());
  await new Promise((resolve) => setImmediate(resolve));
};

describe('uploadController (FIX-004)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('uploadImage', () => {
    test('rechaza si no hay req.file', async () => {
      const req = { body: {} };
      const res = createMockRes();

      await callHandler(uploadImage, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: 'VALIDATION_ERROR',
          message: expect.stringContaining('No se proporcionó ninguna imagen'),
        })
      );
      expect(mockStorageUpload).not.toHaveBeenCalled();
    });

    test('rechaza carpeta no permitida', async () => {
      const req = { body: { folder: 'hacks' }, file: { mimetype: 'image/png', size: 100 } };
      const res = createMockRes();

      await callHandler(uploadImage, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('Carpeta inválida') })
      );
      expect(mockStorageUpload).not.toHaveBeenCalled();
    });

    test('sube imagen con éxito usando carpeta por defecto "general"', async () => {
      mockStorageUpload.mockResolvedValue('/uploads/general/foto.png');
      const req = { body: {}, file: { mimetype: 'image/png', size: 2048 } };
      const res = createMockRes();

      await callHandler(uploadImage, req, res);

      expect(mockStorageUpload).toHaveBeenCalledWith(req.file, 'general');
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            url: '/uploads/general/foto.png',
            folder: 'general',
            filename: 'general/foto.png',
            mimetype: 'image/png',
            size: 2048,
          }),
        })
      );
    });

    test('sube imagen a carpeta explícita', async () => {
      mockStorageUpload.mockResolvedValue('/uploads/tractors/t.png');
      const req = { body: { folder: 'tractors' }, file: { mimetype: 'image/jpeg', size: 512 } };
      const res = createMockRes();

      await callHandler(uploadImage, req, res);

      expect(mockStorageUpload).toHaveBeenCalledWith(req.file, 'tractors');
      expect(res.status).toHaveBeenCalledWith(201);
    });

    test('error del storage → 500 UPLOAD_ERROR', async () => {
      mockStorageUpload.mockRejectedValue(new Error('disk full'));
      const req = { body: {}, file: { mimetype: 'image/png', size: 10 } };
      const res = createMockRes();

      await callHandler(uploadImage, req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'UPLOAD_ERROR',
        })
      );
    });
  });

  describe('deleteImage', () => {
    test('rechaza si falta url', async () => {
      const req = { body: {} };
      const res = createMockRes();

      await callHandler(deleteImage, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'URL de imagen es requerida' })
      );
    });

    test('rechaza url ajena al almacenamiento del proyecto', async () => {
      mockExtractImagePath.mockReturnValue(null);
      const req = { body: { url: 'https://evil.com/x.png' } };
      const res = createMockRes();

      await callHandler(deleteImage, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('no pertenece al almacenamiento') })
      );
      expect(mockStorageDelete).not.toHaveBeenCalled();
    });

    test('200 idempotente si el storage no encontró la imagen', async () => {
      mockExtractImagePath.mockReturnValue('C:\\uploads\\x.png');
      mockStorageDelete.mockResolvedValue({ ok: true, code: 'NOT_FOUND' });
      const req = { body: { url: '/uploads/x.png' } };
      const res = createMockRes();

      await callHandler(deleteImage, req, res);

      expect(res.status).not.toHaveBeenCalled();
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    });

    test('503 si el storage devuelve permiso denegado', async () => {
      mockExtractImagePath.mockReturnValue('tractors/x.png');
      mockStorageDelete.mockResolvedValue({ ok: false, code: 'PERMISSION_DENIED' });
      const req = { body: { url: '/uploads/tractors/x.png' } };
      const res = createMockRes();

      await callHandler(deleteImage, req, res);

      expect(res.status).toHaveBeenCalledWith(503);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        code: 'STORAGE_PERMISSION_DENIED',
      }));
      expect(res.json.mock.calls[0][0].message).not.toContain('EPERM');
    });

    test('elimina imagen con éxito', async () => {
      mockExtractImagePath.mockReturnValue('C:\\uploads\\x.png');
      mockStorageDelete.mockResolvedValue(true);
      const req = { body: { url: '/uploads/x.png' } };
      const res = createMockRes();

      await callHandler(deleteImage, req, res);

      expect(mockStorageDelete).toHaveBeenCalledWith('/uploads/x.png');
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, message: 'Imagen eliminada exitosamente' })
      );
    });
  });
});
