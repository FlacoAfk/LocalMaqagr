import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createImplementWizardForm, getAvailableTractorPower } from '../../src/lib/calculatorWizardState.js';

describe('tractor wizard available power', () => {
  it('preserves zero net power instead of recommending against gross power', () => {
    assert.equal(getAvailableTractorPower(0, 120), 0);
    assert.equal(20 <= getAvailableTractorPower(0, 120), false);
  });

  it('uses gross power only for absent net power and a default only for absent powers', () => {
    assert.equal(getAvailableTractorPower(45, 120), 45);
    assert.equal(getAvailableTractorPower(null, 120), 120);
    assert.equal(getAvailableTractorPower(undefined, 0), 0);
    assert.equal(getAvailableTractorPower(undefined, null), 100);
  });
});

describe('implement wizard reset', () => {
  it('restores all custom draft fields with the initial unit', () => {
    const form = createImplementWizardForm();
    Object.assign(form, { tiro: '350', draft_unit: 'kg/surco', n_surcos: '4', implement_weight_kg: '700' });
    const reset = createImplementWizardForm();
    assert.equal(reset.draft_unit, 'kg/m');
    assert.equal(reset.tiro, '');
    assert.equal(reset.n_surcos, '');
    assert.equal(reset.implement_weight_kg, '');
    for (const [field, value] of Object.entries(reset)) {
      if (field !== 'draft_unit') assert.equal(value, '', field);
    }
    assert.deepEqual(Object.keys(reset), Object.keys(form));
    assert.notEqual(reset, form);
  });
});
