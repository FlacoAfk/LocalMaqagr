import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

// Run with: node --experimental-vm-modules --test tests/routes/implementSearchFilters.test.mjs
// Load the real model while replacing only its database pool with a query recorder.
const loadImplementModel = async (pool) => {
  const context = vm.createContext({});
  const databaseModule = new vm.SyntheticModule(
    ['pool'],
    function setExports() {
      this.setExport('pool', pool);
    },
    { context, identifier: 'mock:database' },
  );
  const modelUrl = new URL('../../src/models/Implement.js', import.meta.url);
  const modelModule = new vm.SourceTextModule(await readFile(modelUrl, 'utf8'), {
    context,
    identifier: modelUrl.href,
  });

  await modelModule.link((specifier) => {
    assert.equal(specifier, '../config/db.js');
    return databaseModule;
  });
  await modelModule.evaluate();
  return modelModule.namespace.default;
};

test('implement search applies power and weight bounds in count and paginated queries', async () => {
  const queries = [];
  const model = await loadImplementModel({
    async query(sql, values) {
      queries.push({ sql, values });
      return queries.length === 1
        ? { rows: [{ total: '1' }] }
        : { rows: [{ implement_id: 7 }] };
    },
  });

  const result = await model.advancedSearch({
    minPower: 20,
    maxPower: 100,
    maxWeight: 1500,
    requiredPower: 80,
    limit: 12,
    offset: 12,
  });

  assert.equal(queries.length, 2);
  for (const { sql } of queries) {
    assert.match(sql, /power_requirement_hp >= \$1/);
    assert.match(sql, /power_requirement_hp <= \$2/);
    assert.match(sql, /weight_kg <= \$3/);
    assert.match(sql, /power_requirement_hp <= \$4/);
  }
  assert.deepEqual(Array.from(queries[0].values), [20, 100, 1500, 80]);
  assert.deepEqual(Array.from(queries[1].values), [20, 100, 1500, 80, 12, 12]);
  assert.deepEqual(JSON.parse(JSON.stringify(result)), {
    data: [{ implement_id: 7 }],
    total: 1,
  });
});
