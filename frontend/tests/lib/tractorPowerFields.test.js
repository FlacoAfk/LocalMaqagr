import { test, describe } from 'node:test';
import { deepStrictEqual, strictEqual } from 'node:assert/strict';
import { getEstimatedTdp, updateTractorPowerFields } from '../../src/lib/tractorPowerFields.js';

describe('Campos de potencia del tractor', () => {
  test('cambiar la TDP no cambia la potencia bruta ni otros campos', () => {
    const previous = { pb: '60', pmax_tdp: '51', peso: '4500' };
    deepStrictEqual(updateTractorPowerFields(previous, 'pmax_tdp', '50'), {
      pb: '60', pmax_tdp: '50', peso: '4500',
    });
    deepStrictEqual(previous, { pb: '60', pmax_tdp: '51', peso: '4500' });
  });

  test('la potencia bruta nueva estima la TDP al 85% (ec. 29 Zoz & Grisso)', () => {
    const updated = updateTractorPowerFields(
      { pb: '60', pmax_tdp: '51' }, 'pb', '80',
    );
    strictEqual(updated.pb, '80');
    strictEqual(updated.pmax_tdp, '68');
  });

  test('el valor de TDP desconocido se calcula desde la potencia bruta, no es fijo', () => {
    strictEqual(getEstimatedTdp('60'), '51');
    strictEqual(getEstimatedTdp(''), '');
  });
});
