import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const loadAuthMiddleware = async ({ currentUser, databaseError, tokenUser }) => {
  const context = vm.createContext({});
  const queried = [];
  const verifyToken = (token) => {
    assert.equal(token, 'test-access-token');
    return tokenUser;
  };
  const pool = {
    async query(sql, values) {
      queried.push({ sql, values });
      if (databaseError) throw databaseError;
      return { rows: currentUser ? [currentUser] : [] };
    },
  };
  const modules = new Map([
    ['../utils/jwt.util.js', { verifyToken }],
    ['../utils/role.util.js', { ROLE_NAME_TO_ID: { admin: 1, user: 2 } }],
    ['../config/db.js', { pool }],
  ]);
  const source = await readFile(new URL('../../src/middleware/auth.middleware.js', import.meta.url), 'utf8');
  const module = new vm.SourceTextModule(source, { context });
  await module.link(async (specifier) => {
    const exports = modules.get(specifier);
    assert.ok(exports, `Unexpected authentication middleware dependency: ${specifier}`);
    return new vm.SyntheticModule(Object.keys(exports), function () {
      for (const [name, value] of Object.entries(exports)) this.setExport(name, value);
    }, { context, identifier: specifier });
  });
  await module.evaluate();
  return { middleware: module.namespace.verifyTokenMiddleware, queried };
};

const runMiddleware = async (options) => {
  const { middleware, queried } = await loadAuthMiddleware(options);
  const req = { headers: { authorization: 'Bearer test-access-token' } };
  const response = {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  const nextCalls = [];
  await middleware(req, response, (error) => nextCalls.push(error));
  return { req, response, nextCalls, queried };
};

const adminTokenUser = { user_id: 42, email: 'admin@example.test', role_id: 1, token_type: 'access' };

test('active users with unchanged role retain access', async () => {
  const result = await runMiddleware({
    tokenUser: adminTokenUser,
    currentUser: { role_id: 1, status: 'active' },
  });

  assert.equal(result.req.user, adminTokenUser);
  assert.equal(result.nextCalls.length, 1);
  assert.equal(result.nextCalls[0], undefined);
  assert.deepEqual(JSON.parse(JSON.stringify(result.queried)), [{
    sql: 'SELECT role_id, status FROM users WHERE user_id = $1',
    values: [42],
  }]);
});

test('demoted admin tokens are rejected against the current database role', async () => {
  const result = await runMiddleware({
    tokenUser: adminTokenUser,
    currentUser: { role_id: 2, status: 'active' },
  });

  assert.equal(result.response.statusCode, 401);
  assert.equal(result.response.body.code, 'UNAUTHORIZED');
  assert.equal(result.req.user, undefined);
  assert.equal(result.nextCalls.length, 0);
});

test('deleted and inactive user tokens are rejected', async (t) => {
  for (const currentUser of [null, { role_id: 1, status: 'inactive' }]) {
    await t.test(currentUser ? 'inactive' : 'deleted', async () => {
      const result = await runMiddleware({ tokenUser: adminTokenUser, currentUser });
      assert.equal(result.response.statusCode, 401);
      assert.equal(result.req.user, undefined);
      assert.equal(result.nextCalls.length, 0);
    });
  }
});

test('database failures reach Express error handling instead of becoming an auth denial', async () => {
  const databaseError = new Error('database unavailable');
  const result = await runMiddleware({ tokenUser: adminTokenUser, databaseError });

  assert.equal(result.response.statusCode, 200);
  assert.equal(result.nextCalls.length, 1);
  assert.equal(result.nextCalls[0], databaseError);
  assert.equal(result.req.user, undefined);
});
