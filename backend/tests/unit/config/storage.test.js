import { describe, expect, jest, test, beforeEach } from '@jest/globals';
import sharp from 'sharp';

const mockUnlink = jest.fn();
const mockMkdir = jest.fn();
const mockWriteFile = jest.fn();

jest.unstable_mockModule('fs/promises', () => ({
  default: {
    unlink: mockUnlink,
    mkdir: mockMkdir,
    writeFile: mockWriteFile,
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
  uploadImage,
} = await import('../../../src/config/storage.js');

describe('local upload raster validation', () => {
  beforeEach(() => {
    mockMkdir.mockReset();
    mockWriteFile.mockReset();
  });

  test.each([
    ['payload.html', '<html><script>alert(1)</script></html>'],
    ['payload.js', 'alert(document.cookie)'],
    ['payload.svg', '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'],
  ])('rejects active content %s despite a forged image MIME', async (originalname, content) => {
    await expect(uploadImage({ originalname, mimetype: 'image/png', buffer: Buffer.from(content) }))
      .rejects.toMatchObject({ code: 'INVALID_IMAGE', statusCode: 400 });
    expect(mockMkdir).not.toHaveBeenCalled();
    expect(mockWriteFile).not.toHaveBeenCalled();
  });

  test('rejects a truncated image with an accepted magic signature', async () => {
    await expect(uploadImage({
      originalname: 'fake.png',
      mimetype: 'image/png',
      buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    })).rejects.toMatchObject({ code: 'INVALID_IMAGE' });
    expect(mockWriteFile).not.toHaveBeenCalled();
  });

  test.each(['png', 'jpeg', 'webp', 'gif'])('decodes %s and stores only canonical WebP bytes', async (format) => {
    const input = await sharp({ create: {
      width: 2, height: 2, channels: 4, background: { r: 32, g: 64, b: 128, alpha: 1 },
    } }).toFormat(format).toBuffer();
    const url = await uploadImage({ originalname: 'payload.html', mimetype: 'image/png', buffer: input }, 'tractors');

    expect(url).toMatch(/^\/uploads\/tractors\/[a-f0-9-]+-payload\.webp$/);
    const [diskPath, output, options] = mockWriteFile.mock.calls[0];
    expect(diskPath).toMatch(/payload\.webp$/);
    expect(options).toEqual({ flag: 'wx' });
    expect(output).not.toBe(input);
    const metadata = await sharp(output).metadata();
    expect(metadata).toMatchObject({ format: 'webp', width: 2, height: 2 });
    expect(metadata.exif).toBeUndefined();
    expect(metadata.xmp).toBeUndefined();
  });

  test('strips appended executable payload instead of copying original bytes', async () => {
    const png = await sharp({ create: {
      width: 1, height: 1, channels: 3, background: '#112233',
    } }).png().toBuffer();
    const payload = Buffer.from('<script>uniqueActivePayload()</script>');
    await uploadImage({ originalname: 'polyglot.js', mimetype: 'image/png', buffer: Buffer.concat([png, payload]) });
    const output = mockWriteFile.mock.calls[0][1];
    expect(output.includes(payload)).toBe(false);
    expect((await sharp(output).metadata()).format).toBe('webp');
  });

  test('rejects oversized compressed images before writing', async () => {
    const input = await sharp({ create: {
      width: 4097, height: 4097, channels: 3, background: '#000000',
    } }).png().toBuffer();
    await expect(uploadImage({ originalname: 'large.png', mimetype: 'image/png', buffer: input }))
      .rejects.toMatchObject({ code: 'INVALID_IMAGE' });
    expect(mockWriteFile).not.toHaveBeenCalled();
  });

  test('rejects oversized buffers even when storage is called without Multer', async () => {
    const buffer = Buffer.alloc(5 * 1024 * 1024 + 1);
    await expect(uploadImage({ originalname: 'large.png', buffer }))
      .rejects.toMatchObject({ code: 'INVALID_IMAGE' });
    expect(mockWriteFile).not.toHaveBeenCalled();
  });
});

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
