import { describe, expect, jest, test, beforeEach } from '@jest/globals';

const mockUnlink = jest.fn();

jest.unstable_mockModule('fs/promises', () => ({
  default: {
    unlink: mockUnlink,
    mkdir: jest.fn(),
    writeFile: jest.fn(),
  },
  __esModule: true,
}));

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  default: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
  __esModule: true,
}));

const {
  DELETE_RESULT_CODES,
  deleteImage,
  extractImagePath,
  resolveDiskPath,
} = await import('../../../src/config/storage.js');

describe('local storage path safety', () => {
  beforeEach(() => {
    mockUnlink.mockReset();
  });

  test('normalizes known local URL formats and keeps paths inside the root', () => {
    expect(extractImagePath('/uploads/tractors/tractor-1.jpg')).toBe('tractors/tractor-1.jpg');
    expect(extractImagePath('uploads/implements/implement-1.webp')).toBe('implements/implement-1.webp');
    expect(extractImagePath('http://localhost:4000/uploads/tractors/tractor-1.jpg')).toBe('tractors/tractor-1.jpg');
    expect(resolveDiskPath('/uploads/tractors/tractor-1.jpg')).toMatch(/[\\/]uploads[\\/]tractors[\\/]tractor-1\.jpg$/);
  });

  test('rejects traversal, encoded traversal, alternate separators, remote URLs, and absolute paths', () => {
    for (const value of [
      '/uploads/tractors/../secret.jpg',
      '/uploads/tractors/%2e%2e/secret.jpg',
      '/uploads/tractors/%252e%252e/secret.jpg',
      '/uploads/tractors/..\\secret.jpg',
      'C:\\ProgramData\\MaqAgr\\uploads\\tractors\\tractor-1.jpg',
      'C:/ProgramData/MaqAgr/uploads/tractors/tractor-1.jpg',
      'https://evil.example/uploads/tractors/tractor-1.jpg',
    ]) {
      expect(extractImagePath(value)).toBeNull();
      expect(resolveDiskPath(value)).toBeNull();
    }
  });

  test('classifies permission failure without collapsing it into not found', async () => {
    mockUnlink.mockRejectedValue(Object.assign(new Error('access denied'), { code: 'EPERM' }));

    await expect(deleteImage('/uploads/tractors/tractor-1.jpg')).resolves.toEqual({
      ok: false,
      code: DELETE_RESULT_CODES.PERMISSION_DENIED,
    });
  });

  test('treats an already-missing file as idempotent success', async () => {
    mockUnlink.mockRejectedValue(Object.assign(new Error('missing'), { code: 'ENOENT' }));

    await expect(deleteImage('/uploads/implements/implement-1.webp')).resolves.toEqual({
      ok: true,
      code: DELETE_RESULT_CODES.NOT_FOUND,
    });
  });
});
