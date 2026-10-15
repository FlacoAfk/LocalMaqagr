import { describe, expect, jest, test } from '@jest/globals';
import { assertSafeTestDatabaseTarget, cleanTestDB } from '../../../src/config/db.test.js';

describe('test database safety guard', () => {
  const safeTarget = {
    nodeEnv: 'test',
    databaseName: 'maqagr_test',
    host: '127.0.0.1',
    port: 5432,
    applicationDatabaseName: 'maqagr_local',
  };

  test('allows only the dedicated local test database', () => {
    expect(() => assertSafeTestDatabaseTarget(safeTarget)).not.toThrow();
  });

  test.each([
    [{ ...safeTarget, nodeEnv: 'production' }, /NODE_ENV=test/],
    [{ ...safeTarget, databaseName: 'maqagr_local' }, /Refusing destructive/],
    [{ ...safeTarget, applicationDatabaseName: 'maqagr_test' }, /Refusing destructive/],
    [{ ...safeTarget, host: 'db.example.com' }, /non-local host/],
    [{ ...safeTarget, port: 70000 }, /invalid port/],
  ])('rejects unsafe target configuration', (options, message) => {
    expect(() => assertSafeTestDatabaseTarget(options)).toThrow(message);
  });

  test('does not truncate a pool pointed at an application database', async () => {
    const query = jest.fn();
    const pool = {
      options: {
        database: 'maqagr_local',
        host: '127.0.0.1',
        port: 5432,
      },
      query,
    };

    await expect(cleanTestDB(pool)).rejects.toThrow(/Refusing destructive/);
    expect(query).not.toHaveBeenCalled();
  });

  test('does not truncate an unverified pool', async () => {
    const query = jest.fn();

    await expect(cleanTestDB({ query })).rejects.toThrow(/unverified database pool/);
    expect(query).not.toHaveBeenCalled();
  });
});
