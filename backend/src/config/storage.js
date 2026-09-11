import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import logger from '../utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Root directory for local file storage.
// UPLOAD_DIR env allows a writable location when the app is installed to
// read-only Program Files (set by the launcher script at runtime).
const UPLOADS_ROOT = process.env.UPLOAD_DIR
  ? path.resolve(process.env.UPLOAD_DIR)
  : path.resolve(__dirname, '../../uploads');

// Public URL prefix served by express.static in app.js
const PUBLIC_URL_PREFIX = '/uploads';

// MIME type -> file extension (used when originalname lacks an extension)
const MIME_EXT_MAP = {
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

// Subdirectories allowed for storage
const ALLOWED_SUBDIRS = ['tractors', 'implements', 'users', 'general'];

export const DELETE_RESULT_CODES = Object.freeze({
  DELETED: 'DELETED',
  NOT_FOUND: 'NOT_FOUND',
  INVALID_PATH: 'INVALID_PATH',
  PERMISSION_DENIED: 'PERMISSION_DENIED',
  IO_ERROR: 'IO_ERROR',
});

const LOCAL_HOSTNAMES = new Set(['localhost', '127.0.0.1', '::1', '[::1]']);
const SAFE_FILENAME = /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/;

/**
 * Sanitize an original filename into a safe base name (no path separators,
 * no unsafe characters). The extension is stripped here and re-added separately.
 */
const sanitizeName = (originalname) => {
  const base = (originalname || 'file')
    .replace(/\.[^./\\]+$/, '') // remove extension
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .replace(/_+/g, '_')
    .slice(0, 80);
  return base || 'file';
};

/**
 * Resolve the on-disk absolute path for a relative storage path
 * (e.g. "tractors/123-img.jpg").
 */
const decodePath = (value) => {
  let decoded = value;

  for (let attempt = 0; attempt < 8; attempt += 1) {
    let next;
    try {
      next = decodeURIComponent(decoded);
    } catch {
      return null;
    }

    if (next === decoded) return decoded;
    decoded = next;
  }

  return decoded;
};

const isLocalUrl = (value) => {
  if (!/^[a-z][a-z\d+.-]*:\/\//i.test(value)) return false;

  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    return false;
  }

  return ['http:', 'https:'].includes(parsed.protocol)
    && LOCAL_HOSTNAMES.has(parsed.hostname.toLowerCase());
};

/**
 * Extract the relative storage path (e.g. "tractors/123-img.jpg") from a public
 * URL or an already-relative path. Returns null when the input is not part of
 * the local storage (e.g. a legacy cloud URL).
 * @param {string} url - Public URL ("/uploads/...") or relative path ("subdir/file")
 * @returns {string|null} relative path or null
 */
export const extractImagePath = (url) => {
  if (!url || typeof url !== 'string') return null;

  const input = url.trim();
  if (!input || /[\u0000-\u001f\u007f]/.test(input)) return null;

  let candidate = input;
  if (isLocalUrl(input)) {
    candidate = new URL(input).pathname;
  } else if (/^[a-z][a-z\d+.-]*:\/\//i.test(input)) {
    // Remote and non-HTTP URLs are never local storage references.
    return null;
  }

  candidate = decodePath(candidate);
  if (!candidate || candidate.includes('\\') || candidate.includes('//')) return null;

  if (candidate.startsWith('/uploads/')) {
    candidate = candidate.slice('/uploads/'.length);
  } else if (candidate.startsWith('uploads/')) {
    candidate = candidate.slice('uploads/'.length);
  } else {
    // Reject absolute paths and arbitrary prefixes. Only the known local
    // public path formats above may be converted to a disk path.
    return null;
  }

  const segments = candidate.split('/');
  if (
    segments.length !== 2
    || !ALLOWED_SUBDIRS.includes(segments[0])
    || !SAFE_FILENAME.test(segments[1])
    || segments.some((segment) => segment === '.' || segment === '..')
  ) {
    return null;
  }

  return candidate;
};

/**
 * Resolve a validated local storage path inside UPLOADS_ROOT.
 * Returns null instead of ever returning a path outside the storage root.
 */
export const resolveDiskPath = (urlOrPath) => {
  const relativePath = extractImagePath(urlOrPath);
  if (!relativePath) return null;

  const root = path.resolve(UPLOADS_ROOT);
  const diskPath = path.resolve(root, relativePath);
  const relativeToRoot = path.relative(root, diskPath);

  if (
    relativeToRoot === '..'
    || relativeToRoot.startsWith(`..${path.sep}`)
    || path.isAbsolute(relativeToRoot)
  ) {
    return null;
  }

  return diskPath;
};

export const isValidLocalImagePath = (value, subdir) => {
  const relativePath = extractImagePath(value);
  return Boolean(relativePath && relativePath.startsWith(`${subdir}/`));
};

/**
 * Upload (write) a file to the local filesystem.
 * @param {object} file - Multer file object (memoryStorage): { buffer, originalname, mimetype }
 * @param {string} subdir - Target subdirectory: 'tractors' | 'implements' | 'users' | 'general'
 * @returns {Promise<string>} Public URL of the stored file: /uploads/<subdir>/<filename>
 */
export const uploadImage = async (file, subdir = 'general') => {
  if (!file || !file.buffer) {
    throw new Error('No file buffer provided for local upload.');
  }
  if (!ALLOWED_SUBDIRS.includes(subdir)) {
    throw new Error(`Invalid storage subdirectory: ${subdir}. Allowed: ${ALLOWED_SUBDIRS.join(', ')}`);
  }

  const safeBase = sanitizeName(file.originalname);
  let ext = path.extname(file.originalname || '').toLowerCase();
  if (!ext && file.mimetype && MIME_EXT_MAP[file.mimetype]) {
    ext = MIME_EXT_MAP[file.mimetype];
  } else if (!ext) {
    ext = '.jpg';
  }

  const filename = `${Date.now()}-${safeBase}${ext}`;
  const targetDir = path.resolve(UPLOADS_ROOT, subdir);
  const targetPath = path.join(targetDir, filename);
  const relativePath = `${subdir}/${filename}`;

  await fs.mkdir(targetDir, { recursive: true });
  await fs.writeFile(targetPath, file.buffer);

  const publicUrl = `${PUBLIC_URL_PREFIX}/${relativePath}`;
  logger.info('File saved to local storage', { url: publicUrl, subdir });
  return publicUrl;
};

/**
 * Delete a file from the local filesystem by public URL or relative path.
 * Tolerates missing files (logs, does not throw).
 * @param {string} urlOrPath - Public URL ("/uploads/...") or relative path ("subdir/file")
 * @returns {Promise<{ok: boolean, code: string}>} Classified storage result
 */
export const deleteImage = async (urlOrPath) => {
  const diskPath = resolveDiskPath(urlOrPath);
  if (!diskPath) {
    logger.warn('Local delete skipped: not a local storage path', { urlOrPath });
    return { ok: false, code: DELETE_RESULT_CODES.INVALID_PATH };
  }

  try {
    await fs.unlink(diskPath);
    logger.info('File deleted from local storage', { urlOrPath });
    return { ok: true, code: DELETE_RESULT_CODES.DELETED };
  } catch (error) {
    if (error.code === 'ENOENT') {
      logger.warn('Local file already absent (not deleted)', { urlOrPath });
      return { ok: true, code: DELETE_RESULT_CODES.NOT_FOUND };
    }
    if (error.code === 'EPERM' || error.code === 'EACCES') {
      logger.error('Permission denied deleting local file', { urlOrPath, error: error.message });
      return { ok: false, code: DELETE_RESULT_CODES.PERMISSION_DENIED };
    }

    logger.error('Error deleting local file', { urlOrPath, error: error.message });
    return { ok: false, code: DELETE_RESULT_CODES.IO_ERROR };
  }
};

// Backward-compatible aliases (kept so controllers importing uploadToGCS /
// deleteFromGCS / extractGCSPath continue to work without import changes).
export const uploadToGCS = uploadImage;
export const deleteFromGCS = deleteImage;
export const extractGCSPath = extractImagePath;

export const isAvailable = true;

export default {
  uploadImage,
  deleteImage,
  extractImagePath,
  resolveDiskPath,
  isValidLocalImagePath,
  DELETE_RESULT_CODES,
  uploadToGCS,
  deleteFromGCS,
  extractGCSPath,
  isAvailable,
};
