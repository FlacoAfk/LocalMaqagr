import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const loadRoleController = async () => {
  const context = vm.createContext({});
  const role = {
    async findById() { return { role_id: 10, role_name: 'operator', status: 'active' }; },
    async findByName() { return null; },
    async create() { throw new Error('Role.create must not run for a missing body'); },
    async update() { throw new Error('Role.update must not run for a missing body'); },
  };
  const pool = { async query() { return { rows: [{ count: '0' }] }; } };
  const modules = new Map([
    ['../models/Role.js', { default: role }],
    ['../config/db.js', { pool }],
    ['../middleware/error.middleware.js', {
      asyncHandler: (handler) => (req, res, next) => Promise.resolve()
        .then(() => handler(req, res, next)).catch(next),
    }],
  ]);
  const source = await readFile(new URL('../../src/controllers/roleController.js', import.meta.url), 'utf8');
  const module = new vm.SourceTextModule(source, { context });
  await module.link(async (specifier) => {
    const exports = modules.get(specifier);
    assert.ok(exports, `Unexpected role controller dependency: ${specifier}`);
    return new vm.SyntheticModule(Object.keys(exports), function () {
      for (const [name, value] of Object.entries(exports)) this.setExport(name, value);
    }, { context, identifier: specifier });
  });
  await module.evaluate();
  return module.namespace;
};

const invoke = async (handler, req) => {
  const response = {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  let nextError;
  await handler(req, response, (error) => { nextError = error; });
  assert.equal(nextError, undefined);
  return response;
};

test('creating a role with no JSON body returns validation instead of throwing', async () => {
  const controller = await loadRoleController();
  const response = await invoke(controller.createRole, { body: undefined });

  assert.equal(response.statusCode, 400);
  assert.equal(response.body.success, false);
});

test('updating a role with no JSON body returns validation instead of throwing', async () => {
  const controller = await loadRoleController();
  const response = await invoke(controller.updateRole, {
    params: { id: '10' },
    body: undefined,
  });

  assert.equal(response.statusCode, 400);
  assert.equal(response.body.success, false);
});
