import { describe, expect, jest, test } from '@jest/globals';
import { publicImageMiddleware } from '../../../src/middleware/publicImage.middleware.js';

describe('publicImageMiddleware', () => {
  test.each(['/legacy.html', '/legacy.js', '/legacy.svg', '/no-extension']) (
    'hides non-raster upload paths (%s)', (requestPath) => {
      const res = { sendStatus: jest.fn(), setHeader: jest.fn() };
      const next = jest.fn();

      publicImageMiddleware({ path: requestPath }, res, next);

      expect(res.sendStatus).toHaveBeenCalledWith(404);
      expect(next).not.toHaveBeenCalled();
    },
  );

  test.each(['/photo.webp', '/photo.png', '/photo.jpg', '/photo.jpeg', '/photo.gif']) (
    'allows raster paths with nosniff protection (%s)', (requestPath) => {
      const res = { sendStatus: jest.fn(), setHeader: jest.fn() };
      const next = jest.fn();

      publicImageMiddleware({ path: requestPath }, res, next);

      expect(res.sendStatus).not.toHaveBeenCalled();
      expect(res.setHeader).toHaveBeenCalledWith('X-Content-Type-Options', 'nosniff');
      expect(next).toHaveBeenCalledTimes(1);
    },
  );
});
