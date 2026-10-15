import path from 'node:path';

const PUBLIC_RASTER_EXTENSIONS = new Set(['.gif', '.jpeg', '.jpg', '.png', '.webp']);

/**
 * Prevent previously stored active-content files from being served from the
 * same origin as the application. New uploads are normalized to WebP, but
 * older installations may still contain arbitrary extensions.
 */
export const publicImageMiddleware = (req, res, next) => {
  const extension = path.extname(req.path).toLowerCase();
  if (!PUBLIC_RASTER_EXTENSIONS.has(extension)) {
    return res.sendStatus(404);
  }

  res.setHeader('X-Content-Type-Options', 'nosniff');
  return next();
};

export default publicImageMiddleware;
