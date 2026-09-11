import assert from 'node:assert/strict';
import test from 'node:test';
import { withImageUrl } from '../../src/lib/imagePayload.js';

test('image payload omits an untouched empty value', () => {
  const payload = { name: 'Tractor' };
  assert.deepEqual(withImageUrl(payload, ''), payload);
});

test('image payload preserves local replacement paths', () => {
  assert.deepEqual(
    withImageUrl({ name: 'Tractor' }, '/uploads/tractors/replacement.jpg'),
    { name: 'Tractor', imageUrl: '/uploads/tractors/replacement.jpg' },
  );
});

test('image payload sends null explicitly when cleared', () => {
  assert.deepEqual(
    withImageUrl({ name: 'Tractor' }, null),
    { name: 'Tractor', imageUrl: null },
  );
});
