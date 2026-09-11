import { describe, expect, jest, test, beforeEach } from '@jest/globals';

const mockQuery = jest.fn();

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  pool: { query: mockQuery },
  __esModule: true,
}));

const { default: Tractor } = await import('../../../src/models/Tractor.js');

describe('Tractor.update image intent', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockQuery.mockResolvedValue({ rows: [{ tractor_id: 1 }] });
  });

  test('explicit null is sent as a clear operation', async () => {
    await Tractor.update(1, { image_url: null });

    const [query, values] = mockQuery.mock.calls[0];
    expect(query).toContain('image_url = CASE WHEN $20 THEN $4 ELSE image_url END');
    expect(values[3]).toBeNull();
    expect(values[19]).toBe(true);
  });

  test('omitted image_url preserves the current database value', async () => {
    await Tractor.update(1, { status: 'inactive' });

    const [, values] = mockQuery.mock.calls[0];
    expect(values[3]).toBeUndefined();
    expect(values[19]).toBe(false);
  });

  test('undefined image_url is also treated as omitted', async () => {
    await Tractor.update(1, { image_url: undefined });

    const [, values] = mockQuery.mock.calls[0];
    expect(values[19]).toBe(false);
  });
});
