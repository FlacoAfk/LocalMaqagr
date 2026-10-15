import { describe, expect, jest, test, beforeEach } from '@jest/globals';

const mockQuery = jest.fn();

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  pool: { query: mockQuery },
  __esModule: true,
}));

const { default: Tractor } = await import('../../../src/models/Tractor.js');

describe('Tractor.advancedSearch weight filter', () => {
  beforeEach(() => {
    mockQuery.mockReset();
    mockQuery.mockResolvedValueOnce({ rows: [{ total: '1' }] })
      .mockResolvedValueOnce({ rows: [{ tractor_id: 1 }] });
  });

  test.each([3500, 0])('uses the same parameterized weight bound for count and data (%s)', async (maxWeight) => {
    const result = await Tractor.advancedSearch({ q: 'Deere', minPower: 50, maxWeight, limit: 5, offset: 10 });

    const [countSql, countValues] = mockQuery.mock.calls[0];
    const [dataSql, dataValues] = mockQuery.mock.calls[1];
    expect(countSql).toContain('weight_kg <= $3');
    expect(dataSql).toContain('weight_kg <= $3');
    expect(countValues).toEqual(['%Deere%', 50, maxWeight]);
    expect(dataValues).toEqual(['%Deere%', 50, maxWeight, 'Deere', 5, 10]);
    expect(dataSql).toContain('LIMIT $5 OFFSET $6');
    expect(result).toEqual({ data: [{ tractor_id: 1 }], total: 1 });
  });

  test('does not add a weight condition when omitted', async () => {
    await Tractor.advancedSearch({});

    expect(mockQuery.mock.calls[0][0]).not.toContain('weight_kg <=');
    expect(mockQuery.mock.calls[0][1]).toEqual([]);
    expect(mockQuery.mock.calls[1][1]).toEqual([10, 0]);
  });
});

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
