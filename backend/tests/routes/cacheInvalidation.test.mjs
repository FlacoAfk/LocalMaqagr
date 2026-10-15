import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

// Run with: node --experimental-vm-modules --test tests/routes/cacheInvalidation.test.mjs
// Isolate route dependencies without loading databases, uploads, or network clients.
const loadRoutes = async (routeFile) => {
  const entries = new Map();
  const routes = [];
  const context = vm.createContext({});
  const redis = {
    status: 'ready',
    async keys(pattern) {
      const expression = new RegExp(`^${pattern.split('*').map(
        (part) => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      ).join('.*')}$`);
      return [...entries.keys()].filter((key) => expression.test(key));
    },
    pipeline() {
      const pending = [];
      return {
        del(key) { pending.push(key); },
        async exec() { pending.forEach((key) => entries.delete(key)); },
      };
    },
  };
  const pass = (req, res, next) => next();
  const handler = (req, res) => {
    res.statusCode = req.responseStatus ?? 201;
    res.emit('finish');
  };
  const router = {};
  for (const method of ['get', 'post', 'put', 'delete']) {
    router[method] = (path, ...handlers) => routes.push({ method, path, handlers });
  }
  const modules = new Map();
  const mockModule = (key, exports) => {
    const module = new vm.SyntheticModule(Object.keys(exports), function () {
      for (const [name, value] of Object.entries(exports)) this.setExport(name, value);
    }, { context, identifier: key });
    modules.set(key, module);
    return module;
  };
  const fileModule = async (path) => {
    if (modules.has(path)) return modules.get(path);
    const module = new vm.SourceTextModule(await readFile(new URL(path), 'utf8'), {
      context, identifier: path,
    });
    modules.set(path, module);
    await module.link(async (specifier, parent) => {
      if (specifier === 'express') return mockModule('express', { Router: () => router });
      const url = new URL(specifier, parent.identifier).href;
      if (modules.has(url)) return modules.get(url);
      if (url.endsWith('/cache.middleware.js') || url.endsWith('/cache.util.js')) {
        return fileModule(url);
      }
      if (url.endsWith('/config/redis.js')) return mockModule(url, { default: redis });
      if (url.endsWith('/utils/logger.js')) {
        return mockModule(url, { default: { info() {}, error() {} } });
      }
      const names = url.endsWith('/implementController.js')
        ? ['getAllImplements', 'getAvailableImplements', 'searchImplements',
          'getImplementById', 'createImplement', 'updateImplement', 'deleteImplement']
        : url.endsWith('/recommendationController.js')
          ? ['generateRecommendation', 'generateAdvancedRecommendation',
            'getRecommendationHistory', 'getRecommendationById']
          : url.endsWith('/auth.middleware.js') ? ['verifyTokenMiddleware', 'isAdmin']
            : url.endsWith('/validation.middleware.js') ? ['validateImplement']
              : url.endsWith('/upload.middleware.js') ? ['uploadMiddleware']
                : url.endsWith('/pagination.middleware.js') ? ['paginationMiddleware'] : [];
      assert.ok(names.length, `Unexpected dependency: ${url}`);
      return mockModule(url, Object.fromEntries(names.map((name) => [
        name, name === 'paginationMiddleware' ? () => pass
          : url.includes('/controllers/') ? handler : pass,
      ])));
    });
    return module;
  };
  const module = await fileModule(new URL(`../../src/routes/${routeFile}`, import.meta.url).href);
  await module.evaluate();
  return {
    entries,
    async invoke(method, path, responseStatus, user = { id: 42 }) {
      const route = routes.find((item) => item.method === method && item.path === path);
      assert.ok(route, `${method} ${path} must exist`);
      const res = new EventEmitter();
      const req = { method: method.toUpperCase(), user, responseStatus };
      let index = 0;
      const next = () => route.handlers[index++]?.(req, res, next);
      next();
      await new Promise((resolve) => setImmediate(resolve));
    },
  };
};

for (const [method, path] of [['post', '/'], ['put', '/:id'], ['delete', '/:id']]) {
  test(`implement ${method} invalidates catalog and recommendation cache only after success`, async () => {
    const { entries, invoke } = await loadRoutes('implement.routes.js');
    for (const status of [400, 500, 201, 204]) {
      entries.set('cache:/api/implements?page=2', 'old catalog');
      entries.set('cache:/api/recommendations/history:42', 'old history');
      entries.set('cache:/api/tractors', 'unrelated');
      await invoke(method, path, status);
      assert.equal(entries.has('cache:/api/implements?page=2'), status >= 300);
      assert.equal(entries.has('cache:/api/recommendations/history:42'), status >= 300);
      assert.equal(entries.has('cache:/api/tractors'), true);
    }
  });
}

for (const path of ['/generate', '/advanced']) {
  test(`recommendation ${path} invalidates only the authenticated user's history after success`, async () => {
    const { entries, invoke } = await loadRoutes('recommendation.routes.js');
    for (const status of [400, 500, 200, 201]) {
      const ownKeys = ['cache:/api/recommendations/history:42',
        'cache:/api/recommendations/history?page=2&limit=5:42'];
      for (const key of ownKeys) entries.set(key, 'old history');
      entries.set('cache:/api/recommendations/history:142', 'other user');
      entries.set('cache:/api/recommendations/17:42', 'detail');
      await invoke('post', path, status);
      for (const key of ownKeys) assert.equal(entries.has(key), status >= 300);
      assert.equal(entries.has('cache:/api/recommendations/history:142'), true);
      assert.equal(entries.has('cache:/api/recommendations/17:42'), true);
    }
  });
}
