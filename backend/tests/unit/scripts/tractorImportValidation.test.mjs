import assert from 'node:assert/strict';
import test from 'node:test';
import { validateTractorImportRecord } from '../../../scripts/scraping/lib/tractor-import-validation.js';

const validRecord = {
  name: 'MFWD Tractor',
  brand: 'Audit',
  model: 'MFWD-1',
  engine_power_hp: 75,
  weight_kg: 3200,
  traction_force_kn: 45,
  traction_type: 'mfwd',
};

test('tractor import accepts every traction type allowed by the API', () => {
  for (const traction_type of ['4x2', 'mfwd', '4x4', 'track']) {
    assert.deepEqual(
      validateTractorImportRecord({ ...validRecord, traction_type }),
      [],
      `${traction_type} should be importable`,
    );
  }
});

test('tractor import rejects unsupported traction types', () => {
  assert.deepEqual(
    validateTractorImportRecord({ ...validRecord, traction_type: 'unknown' }),
    ['traction_type inválido: unknown'],
  );
});
