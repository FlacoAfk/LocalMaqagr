import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const loadCacheStatsHandler = async (redisClient) => {
  const routes = [];
  const router = {};
  for (const method of ['get', 'post', 'put', 'delete']) {
    router[method] = (path, ...handlers) => routes.push({ method, path, handlers });
  }

  const context = vm.createContext({});
  const mocks = new Map([
    ['express', { Router: () => router }],
    ['../config/redis.js', { default: redisClient }],
    ['../middleware/auth.middleware.js', {
      verifyTokenMiddleware: (_req, _res, next) => next(),
      requireRole: () => (_req, _res, next) => next(),
      isAdmin: (_req, _res, next) => next(),
    }],
    ['../controllers/adminController.js', {
      getOverviewStats() {}, getRecommendationStats() {}, getUserStats() {},
    }],
    ['../services/notificationService.js', { notifySystemMaintenance() {} }],
    ['../utils/response.util.js', { successResponse() {} }],
    ['../controllers/adminUserController.js', {
      getAllUsers() {}, getUserById() {}, updateUser() {},
    }],
  ]);

  const source = await readFile(new URL('../../src/routes/admin.routes.js', import.meta.url), 'utf8');
  const module = new vm.SourceTextModule(source, { context });
  await module.link(async (specifier) => {
    const exports = mocks.get(specifier);
    assert.ok(exports, `Unexpected admin route dependency: ${specifier}`);
    return new vm.SyntheticModule(Object.keys(exports), function () {
      for (const [name, value] of Object.entries(exports)) this.setExport(name, value);
    }, { context, identifier: specifier });
  });
  await module.evaluate();

  const route = routes.find(({ method, path }) => method === 'get' && path === '/cache/stats');
  assert.ok(route, 'GET /cache/stats must be registered');
  return route.handlers.at(-1);
};

const invoke = async (handler) => {
  const response = {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  await handler({}, response);
  return response;
};

test('cache stats clearly reports disabled Redis without failing', async () => {
  const response = await invoke(await loadCacheStatsHandler(null));

  assert.equal(response.statusCode, 200);
  assert.deepEqual(JSON.parse(JSON.stringify(response.body)), {
    status: 'disabled',
    enabled: false,
    hits: 0,
    misses: 0,
    hitRate: '0.00%',
    latency: '0ms',
  });
});

test('cache stats parses Redis counters when Redis is available', async () => {
  const redisClient = { info: async () => '# Stats\r\nkeyspace_hits:9\r\nkeyspace_misses:1\r\n' };
  const response = await invoke(await loadCacheStatsHandler(redisClient));

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.status, 'available');
  assert.equal(response.body.enabled, true);
  assert.equal(response.body.hits, 9);
  assert.equal(response.body.misses, 1);
  assert.equal(response.body.hitRate, '90.00%');
  assert.match(response.body.latency, /^\d+ms$/);
});

test('cache stats returns a sanitized unavailable response when Redis errors', async () => {
  const redisClient = { info: async () => { throw new Error('secret connection details'); } };
  const response = await invoke(await loadCacheStatsHandler(redisClient));

  assert.equal(response.statusCode, 503);
  assert.deepEqual(JSON.parse(JSON.stringify(response.body)), {
    status: 'unavailable',
    message: 'Cache statistics are temporarily unavailable',
  });
  assert.equal(JSON.stringify(response.body).includes('secret connection details'), false);
});
