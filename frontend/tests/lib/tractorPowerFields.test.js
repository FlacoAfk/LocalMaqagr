import { test, describe } from 'node:test';
import { deepStrictEqual, strictEqual } from 'node:assert/strict';
import { getEstimatedTdp, updateTractorPowerFields } from '../../src/lib/tractorPowerFields.js';

describe('Campos de potencia del tractor', () => {
  test('cambiar la TDP no cambia la potencia bruta ni otros campos', () => {
    const previous = { pb: '65', pmax_tdp: '55.9', peso: '4500' };
    deepStrictEqual(updateTractorPowerFields(previous, 'pmax_tdp', '50'), {
      pb: '65', pmax_tdp: '50', peso: '4500',
    });
    deepStrictEqual(previous, { pb: '65', pmax_tdp: '55.9', peso: '4500' });
  });

  test('la potencia bruta nueva estima la TDP al 86%', () => {
    const updated = updateTractorPowerFields(
      { pb: '65', pmax_tdp: '55.9' }, 'pb', '80',
    );
    strictEqual(updated.pb, '80');
    strictEqual(updated.pmax_tdp, '68.8');
  });

  test('el valor de TDP desconocido se calcula desde la potencia bruta, no es fijo', () => {
    strictEqual(getEstimatedTdp('65'), '55.9');
    strictEqual(getEstimatedTdp(''), '');
  });
});
