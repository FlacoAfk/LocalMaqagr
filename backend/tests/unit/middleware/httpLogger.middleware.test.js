import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockMorganMiddleware = jest.fn();
const mockMorgan = jest.fn(() => mockMorganMiddleware);
const tokenRegistrations = [];
mockMorgan.token = jest.fn((name, fn) => {
  tokenRegistrations.push([name, fn]);
});

const mockLoggerHttp = jest.fn();
const mockLoggerDebug = jest.fn();

jest.unstable_mockModule('morgan', () => ({
  __esModule: true,
  default: mockMorgan,
}));

jest.unstable_mockModule('../../../src/config/logger.js', () => ({
  __esModule: true,
  default: {
    http: mockLoggerHttp,
    debug: mockLoggerDebug,
  },
}));

const httpLoggerModule = await import('../../../src/middleware/httpLogger.middleware.js');
const httpLogger = httpLoggerModule.default;

const originalNodeEnv = process.env.NODE_ENV;
const morganOptions = mockMorgan.mock.calls[0][1];

const createMockRes = () => ({
  setHeader: jest.fn(),
});

describe('httpLogger.middleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.NODE_ENV = 'development';
  });

  afterEach(() => {
    process.env.NODE_ENV = originalNodeEnv;
  });

  test('registra request body sanitizado y conserva x-request-id existente', () => {
    const req = {
      headers: { 'x-request-id': 'req-123' },
      method: 'POST',
      originalUrl: '/api/auth/login',
      body: {
        email: 'user@test.com',
        password: 'secret',
        token: 'abc',
        currentPassword: 'old',
        keep: 'value',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    mockMorganMiddleware.mockImplementation((innerReq, innerRes, callback) => {
      morganOptions.stream.write('POST /api/auth/login 200 10 ms\n');
      callback();
    });

    httpLogger(req, res, next);

    expect(req.requestId).toBe('req-123');
    expect(res.setHeader).toHaveBeenCalledWith('x-request-id', 'req-123');
    expect(mockLoggerHttp).toHaveBeenCalledWith('POST /api/auth/login 200 10 ms');
    expect(mockLoggerDebug).toHaveBeenCalledWith('Request body', {
      requestId: 'req-123',
      method: 'POST',
      url: '/api/auth/login',
      body: {
        currentPassword: 'old',
        email: 'user@test.com',
        keep: 'value',
      },
    });
    expect(next).toHaveBeenCalled();
  });

  test('genera request-id cuando no existe y no loggea body fuera de development', () => {
    process.env.NODE_ENV = 'production';

    const req = {
      headers: {},
      method: 'GET',
      originalUrl: '/api/tractors',
      body: {
        q: 'tractor',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    mockMorganMiddleware.mockImplementation((_req, _res, callback) => {
      callback();
    });

    httpLogger(req, res, next);

    expect(req.requestId).toEqual(expect.stringMatching(/^\d+-[a-z0-9]{6}$/));
    expect(res.setHeader).toHaveBeenCalledWith('x-request-id', req.requestId);
    expect(mockLoggerDebug).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalled();
  });

  test('propaga error si morgan falla y expone skip en test env', () => {
    const req = {
      headers: {},
      method: 'GET',
      originalUrl: '/api/error',
      body: {},
    };
    const res = createMockRes();
    const next = jest.fn();
    const error = new Error('morgan failed');

    mockMorganMiddleware.mockImplementation((_req, _res, callback) => {
      callback(error);
    });

    httpLogger(req, res, next);

    expect(next).toHaveBeenCalledWith(error);
    process.env.NODE_ENV = 'test';
    expect(morganOptions.skip()).toBe(true);
    process.env.NODE_ENV = 'development';
    expect(morganOptions.skip()).toBe(false);
    expect(tokenRegistrations.map(([name]) => name)).toEqual(
      expect.arrayContaining(['user-id', 'request-id']),
    );
  });

  test('los tokens registrados por morgan resuelven user-id y request-id con fallback', () => {
    const tokenMap = Object.fromEntries(tokenRegistrations);

    expect(tokenMap['user-id']({ user: { user_id: 17 } })).toBe('17');
    expect(tokenMap['user-id']({})).toBe('anon');
    expect(tokenMap['request-id']({ requestId: 'abc-123' })).toBe('abc-123');
    expect(tokenMap['request-id']({})).toBe('-');
  });
});
