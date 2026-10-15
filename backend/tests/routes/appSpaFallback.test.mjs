import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { once } from 'node:events';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';

const tempRoot = await mkdtemp(path.join(os.tmpdir(), 'maqagr-spa-fallback-'));
process.env.NODE_ENV = 'test';
process.env.REDIS_ENABLED = 'false';
process.env.LOG_DIR = tempRoot;
process.env.UPLOAD_DIR = path.join(tempRoot, 'uploads');
process.env.FRONTEND_DIST = path.join(tempRoot, 'frontend');
await mkdir(process.env.FRONTEND_DIST, { recursive: true });
await writeFile(path.join(process.env.FRONTEND_DIST, 'index.html'), '<html>frontend sentinel</html>');

const { default: app } = await import('../../src/app.js');

test('SPA fallback serves client routes but never masks API or health 404s', async (t) => {
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(async () => {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(tempRoot, { recursive: true, force: true });
  });

  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const clientRoute = await fetch(`${baseUrl}/tractor/catalog-detail`);
  assert.equal(clientRoute.status, 200);
  assert.equal(await clientRoute.text(), '<html>frontend sentinel</html>');

  for (const route of ['/api/does-not-exist', '/api', '/health/does-not-exist']) {
    const response = await fetch(`${baseUrl}${route}`);
    assert.equal(response.status, 404, `${route} must remain a backend 404`);
    assert.match(response.headers.get('content-type') ?? '', /application\/json/);
  }
});
