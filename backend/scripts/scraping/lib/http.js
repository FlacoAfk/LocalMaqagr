/**
 * Cliente HTTP cortés para scraping: User-Agent identificable,
 * delay mínimo entre peticiones, reintentos y caché en disco.
 */
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

const DEFAULT_UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36 MaqAgrCatalogBot/1.0 (local project)';

let lastRequestAt = 0;

/**
 * @param {object} opts
 * @param {string|null} opts.cacheDir  Si se define, cachea el HTML por URL (hash sha1)
 * @param {number} opts.minDelayMs     Delay mínimo entre peticiones (cortesía)
 * @param {number} opts.maxRetries
 * @param {number} opts.timeoutMs
 */
export function createFetcher({
  cacheDir = null,
  minDelayMs = 800,
  maxRetries = 3,
  timeoutMs = 30000,
} = {}) {
  if (cacheDir) fs.mkdirSync(cacheDir, { recursive: true });

  return async function fetchHtml(url) {
    const key = crypto.createHash('sha1').update(url).digest('hex');
    const cacheFile = cacheDir ? path.join(cacheDir, `${key}.html`) : null;
    if (cacheFile && fs.existsSync(cacheFile)) {
      return fs.readFileSync(cacheFile, 'utf8');
    }

    const wait = minDelayMs - (Date.now() - lastRequestAt);
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));

    let lastErr;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        lastRequestAt = Date.now();
        const res = await fetch(url, {
          headers: { 'User-Agent': DEFAULT_UA, 'Accept-Language': 'en' },
          signal: AbortSignal.timeout(timeoutMs),
          redirect: 'follow',
        });
        if (res.status === 404) {
          const err = new Error(`HTTP 404: ${url}`);
          err.notFound = true;
          throw err;
        }
        if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
        const html = await res.text();
        if (cacheFile) fs.writeFileSync(cacheFile, html);
        return html;
      } catch (err) {
        if (err.notFound) throw err;
        lastErr = err;
        await new Promise((r) => setTimeout(r, attempt * 1500));
      }
    }
    throw lastErr;
  };
}

/** Descarga un binario (imagen) con los mismos recaudos. Devuelve Buffer. */
export async function fetchBinary(url, { minDelayMs = 500, timeoutMs = 30000 } = {}) {
  const wait = minDelayMs - (Date.now() - lastRequestAt);
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastRequestAt = Date.now();
  const res = await fetch(url, {
    headers: { 'User-Agent': DEFAULT_UA },
    signal: AbortSignal.timeout(timeoutMs),
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  const type = res.headers.get('content-type') || '';
  if (!type.startsWith('image/')) {
    throw new Error(`No es una imagen (${type}): ${url}`);
  }
  return Buffer.from(await res.arrayBuffer());
}
