/**
 * FIX-004: Coverage complementario para error.middleware.js
 *
 * Aditivo: cubre ramas no ejercitadas del errorHandler global:
 * códigos MulterError, mapa de errores PostgreSQL, detección CORS,
 * NODE_ENV=development (detalle), err.errors[], fallback de codes.
 */
import { describe, test, expect, jest, beforeEach, afterEach } from '@jest/globals';

const mockLoggerWarn = jest.fn();
const mockLoggerError = jest.fn();

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  default: {
    info: jest.fn(),
    warn: mockLoggerWarn,
    error: mockLoggerError,
    http: jest.fn(),
  },
  __esModule: true,
}));

const { errorHandler, notFound } = await import('../../../src/middleware/error.middleware.js');

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const createMockReq = (overrides = {}) => ({
  method: 'POST',
  originalUrl: '/api/test',
  ip: '127.0.0.1',
  requestId: undefined,
  headers: {},
  params: {},
  query: {},
  body: {},
  ...overrides,
});

describe('error.middleware (FIX-004 extra)', () => {
  const originalNodeEnv = process.env.NODE_ENV;

  beforeEach(() => {
    mockLoggerWarn.mockClear();
    mockLoggerError.mockClear();
    process.env.NODE_ENV = 'test';
  });

  afterEach(() => {
    process.env.NODE_ENV = originalNodeEnv;
  });

  describe('errorHandler — MulterError (caracterización de DEFECTO conocido)', () => {
    // DEFECTO SRC REAL (descubierto por FIX-004, NO corregido — fuera de alcance):
    // error.middleware.js línea 105-119 intenta mapear MulterError a 413/400,
    // pero el bloque `if (err.code)` (línea 128) sobreescribe SIEMPRE el resultado:
    // todo código MulterError (LIMIT_FILE_SIZE, etc.) no está en pgMap, no empieza
    // con '2'/'4' → cae en el else → 500 'Error en la base de datos'.
    // Estos tests documentan el COMPORTAMIENTO ACTUAL (defectuoso); el delta FIX-005
    // debe corregir el middleware y actualizar estas expectativas a 413/400.
    const assertCurrentBehavior = (err, res) => {
      errorHandler(err, createMockReq(), res, jest.fn());
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Error en la base de datos' })
      );
    };

    test('LIMIT_FILE_SIZE → ACTUAL 500 (intención: 413)', () => {
      assertCurrentBehavior({ name: 'MulterError', code: 'LIMIT_FILE_SIZE', message: 'File too large' }, createMockRes());
    });

    test('LIMIT_FILE_COUNT → ACTUAL 500 (intención: 400)', () => {
      assertCurrentBehavior({ name: 'MulterError', code: 'LIMIT_FILE_COUNT', message: 'Too many files' }, createMockRes());
    });

    test('LIMIT_UNEXPECTED_FILE → ACTUAL 500 (intención: 400)', () => {
      assertCurrentBehavior({ name: 'MulterError', code: 'LIMIT_UNEXPECTED_FILE', message: 'Unexpected field' }, createMockRes());
    });

    test('código MulterError desconocido → ACTUAL 500 (intención: 400 genérico)', () => {
      assertCurrentBehavior({ name: 'MulterError', code: 'SOMETHING_ELSE', message: 'x' }, createMockRes());
    });
  });

  describe('errorHandler — errores PostgreSQL por código', () => {
    const pgCases = [
      ['23505', 409, 'Ya existe un registro'],
      ['23503', 400, 'Referencia a un registro'],
      ['23502', 400, 'Falta un campo obligatorio'],
      ['22P02', 400, 'Formato de datos inválido'],
      ['42P01', 500, 'Error de configuración de base de datos'],
    ];

    pgCases.forEach(([code, status, messagePart]) => {
      test(`código ${code} → ${status}`, () => {
        const err = { name: 'error', code, message: 'db error' };
        const res = createMockRes();

        errorHandler(err, createMockReq(), res, jest.fn());

        expect(res.status).toHaveBeenCalledWith(status);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ message: expect.stringContaining(messagePart) })
        );
      });
    });

    test('código que empieza con 2 o 4 (no mapeado) → 400', () => {
      const err = { name: 'error', code: '23599', message: 'db error' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Error en la base de datos' })
      );
    });

    test('código que NO empieza con 2 o 4 → 500', () => {
      const err = { name: 'error', code: '5A001', message: 'db error' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Error en la base de datos' })
      );
    });
  });

  describe('errorHandler — detección CORS y errores de nombre', () => {
    test('mensaje con "cors" → 403', () => {
      const err = { name: 'Error', message: 'Not allowed by CORS policy' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'No permitido por la política CORS' })
      );
    });

    test('JsonWebTokenError → 401 Token inválido', () => {
      const err = { name: 'JsonWebTokenError', message: 'jwt malformed' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Token inválido' })
      );
    });

    test('TokenExpiredError → 401 Token expirado', () => {
      const err = { name: 'TokenExpiredError', message: 'jwt expired' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Token expirado' })
      );
    });

    test('ValidationError sin statusCode → 400', () => {
      const err = { name: 'ValidationError', message: 'bad data', errors: ['a', 'b'] };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Error de validación',
          errors: ['a', 'b'],
        })
      );
    });

    test('CastError → 400 Formato de ID inválido', () => {
      const err = { name: 'CastError', message: 'Cast to ObjectId failed' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Formato de ID inválido' })
      );
    });

    test('mensaje con "Tipo de archivo no permitido" → 400', () => {
      const err = { name: 'Error', message: 'Tipo de archivo no permitido: pdf' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
    });
  });

  describe('errorHandler — logging y contexto', () => {
    test('error 5xx → logger.error con stack y contexto pg', () => {
      const err = { name: 'Error', message: 'boom', statusCode: 500, stack: 'at x', query: 'SELECT 1', detail: 'detail' };
      const req = createMockReq({ headers: { 'x-request-id': 'req-123' } });
      const res = createMockRes();

      errorHandler(err, req, res, jest.fn());

      expect(mockLoggerError).toHaveBeenCalledWith(
        '[500] boom',
        expect.objectContaining({
          requestId: 'req-123',
          pgQuery: 'SELECT 1',
          pgDetail: 'detail',
          stack: 'at x',
        })
      );
    });

    test('error 4xx → logger.warn sin stack en producción', () => {
      process.env.NODE_ENV = 'production';
      const err = { name: 'Error', message: 'bad', statusCode: 400, stack: 'at x' };
      const req = createMockReq({ user: { user_id: 7, email: 'a@b.c', role_id: 2 } });
      const res = createMockRes();

      errorHandler(err, req, res, jest.fn());

      expect(mockLoggerWarn).toHaveBeenCalledWith(
        '[400] bad',
        expect.objectContaining({
          userId: 7,
          userEmail: 'a@b.c',
          userRole: 2,
          stack: undefined,
        })
      );
    });

    test('NODE_ENV=development → response.error con detalle', () => {
      process.env.NODE_ENV = 'development';
      const err = { name: 'Error', message: 'debug', statusCode: 500, stack: 'at dev', code: 'X1' };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: 'INTERNAL_ERROR',
          error: {
            name: 'Error',
            message: 'debug',
            stack: 'at dev',
            code: 'X1',
          },
        })
      );
    });

    test('código de estado mapeado: 409 → CONFLICT, 403 → FORBIDDEN', () => {
      const res409 = createMockRes();
      errorHandler({ name: 'Error', message: 'dup', statusCode: 409 }, createMockReq(), res409, jest.fn());
      expect(res409.json).toHaveBeenCalledWith(expect.objectContaining({ code: 'CONFLICT' }));

      const res403 = createMockRes();
      errorHandler({ name: 'Error', message: 'nope', statusCode: 403 }, createMockReq(), res403, jest.fn());
      expect(res403.json).toHaveBeenCalledWith(expect.objectContaining({ code: 'FORBIDDEN' }));
    });

    test('código no mapeado → INTERNAL_ERROR', () => {
      const err = { name: 'Error', message: 'weird', statusCode: 418 };
      const res = createMockRes();

      errorHandler(err, createMockReq(), res, jest.fn());

      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ code: 'INTERNAL_ERROR' }));
    });
  });

  describe('notFound', () => {
    test('responde 404 con mensaje de ruta inexistente', () => {
      const req = createMockReq({ originalUrl: '/api/nope', requestId: 'rid-1', user: { user_id: 3 } });
      const res = createMockRes();
      const next = jest.fn();

      notFound(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'NOT_FOUND',
          message: 'La ruta /api/nope no existe en este servidor',
        })
      );
      expect(mockLoggerWarn).toHaveBeenCalled();
    });
  });
});
