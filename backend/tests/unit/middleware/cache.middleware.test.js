import { beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockRedisGet = jest.fn();
const mockRedisSet = jest.fn();
const mockLoggerInfo = jest.fn();
const mockLoggerError = jest.fn();
const mockInvalidateCache = jest.fn();

jest.unstable_mockModule('../../../src/config/redis.js', () => ({
  __esModule: true,
  default: {
    get: mockRedisGet,
    set: mockRedisSet,
  },
}));

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  __esModule: true,
  default: {
    info: mockLoggerInfo,
    error: mockLoggerError,
  },
}));

jest.unstable_mockModule('../../../src/utils/cache.util.js', () => ({
  __esModule: true,
  invalidateCache: mockInvalidateCache,
}));

const middlewareModule = await import('../../../src/middleware/cache.middleware.js');
const {
  cacheMiddleware,
  invalidateCacheMiddleware,
} = middlewareModule;

const createMockRes = () => {
  const res = {};
  res.setHeader = jest.fn();
  res.json = jest.fn().mockReturnValue(res);
  res.on = jest.fn((event, callback) => {
    res.__listeners = res.__listeners || {};
    res.__listeners[event] = callback;
    return res;
  });
  res.statusCode = 200;
  return res;
};

describe('cache.middleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('cacheMiddleware omite caché en métodos distintos de GET', async () => {
    const req = { method: 'POST' };
    const res = createMockRes();
    const next = jest.fn();

    await cacheMiddleware(60)(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(mockRedisGet).not.toHaveBeenCalled();
  });

  test('cacheMiddleware responde HIT cuando existe contenido cacheado', async () => {
    const req = {
      method: 'GET',
      originalUrl: '/api/tractors?limit=5',
      user: { id: 3 },
    };
    const res = createMockRes();
    const next = jest.fn();
    const payload = { success: true, data: [{ tractor_id: 1 }] };
    mockRedisGet.mockResolvedValue(JSON.stringify(payload));

    await cacheMiddleware(120)(req, res, next);

    expect(mockRedisGet).toHaveBeenCalledWith('cache:/api/tractors?limit=5:3');
    expect(res.setHeader).toHaveBeenCalledWith('X-Cache', 'HIT');
    expect(res.json).toHaveBeenCalledWith(payload);
    expect(next).not.toHaveBeenCalled();
  });

  test('cacheMiddleware responde MISS e intercepta res.json para guardar en redis', async () => {
    const req = {
      method: 'GET',
      originalUrl: '/api/tractors',
      user: { id: 9 },
    };
    const res = createMockRes();
    const next = jest.fn();
    const payload = { success: true, data: [{ tractor_id: 10 }] };

    mockRedisGet.mockResolvedValue(null);
    mockRedisSet.mockResolvedValue('OK');

    await cacheMiddleware(300)(req, res, next);

    expect(res.setHeader).toHaveBeenCalledWith('X-Cache', 'MISS');
    expect(next).toHaveBeenCalled();

    res.json(payload);

    expect(mockRedisSet).toHaveBeenCalledWith(
      'cache:/api/tractors:9',
      JSON.stringify(payload),
      'EX',
      300,
    );
    expect(mockLoggerInfo).toHaveBeenCalledWith('Cache MISS for cache:/api/tractors:9');
  });

  test('cacheMiddleware registra error cuando falla redis get y deja continuar', async () => {
    const req = {
      method: 'GET',
      url: '/api/simple',
    };
    const res = createMockRes();
    const next = jest.fn();
    mockRedisGet.mockRejectedValue(new Error('redis unavailable'));

    await cacheMiddleware(30)(req, res, next);

    expect(mockLoggerError).toHaveBeenCalledWith('Redis cache error: redis unavailable');
    expect(next).toHaveBeenCalled();
  });

  test('cacheMiddleware registra error si falla redis set durante la respuesta', async () => {
    const req = {
      method: 'GET',
      url: '/api/simple',
    };
    const res = createMockRes();
    const next = jest.fn();
    mockRedisGet.mockResolvedValue(null);
    mockRedisSet.mockRejectedValue(new Error('set failed'));

    await cacheMiddleware(45)(req, res, next);
    res.json({ ok: true });
    await new Promise((resolve) => setImmediate(resolve));

    expect(mockLoggerError).toHaveBeenCalledWith('Redis cache save error: set failed');
  });

  test('invalidateCacheMiddleware invalida solo respuestas 2xx', () => {
    const req = {};
    const successRes = createMockRes();
    const next = jest.fn();

    invalidateCacheMiddleware(['cache:tractors:*'])(req, successRes, next);
    successRes.statusCode = 204;
    successRes.__listeners.finish();

    expect(next).toHaveBeenCalled();
    expect(mockInvalidateCache).toHaveBeenCalledWith(['cache:tractors:*']);

    const errorRes = createMockRes();
    invalidateCacheMiddleware(['cache:tractors:*'])(req, errorRes, jest.fn());
    errorRes.statusCode = 500;
    errorRes.__listeners.finish();

    expect(mockInvalidateCache).toHaveBeenCalledTimes(1);
  });
});
