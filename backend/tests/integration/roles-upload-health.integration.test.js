import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import { mkdtempSync } from 'node:fs';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import sharp from 'sharp';

// Keep real upload requests isolated from the application's normal storage.
const uploadDir = mkdtempSync(path.join(os.tmpdir(), 'maqagr-integration-uploads-'));
process.env.UPLOAD_DIR = uploadDir;

const { request, registerAndGetToken, createAdminAndGetToken, resetTestDB } =
  await import('./helpers/testHelpers.js');
const { pool } = await import('../../src/config/db.js');

describe('Roles, uploads, and health API integration', () => {
  let userToken;
  let adminToken;
  let customRoleId;
  let uploadedImageUrl;

  beforeAll(async () => {
    await resetTestDB();
    const user = await registerAndGetToken({
      name: 'Route Coverage User',
      email: 'route.coverage.user@integration.test',
      password: 'TestPassword1',
    });
    const admin = await createAdminAndGetToken();
    userToken = user.token;
    adminToken = admin.token;
  });

  afterAll(async () => {
    if (uploadedImageUrl && adminToken) {
      await request
        .delete('/api/upload')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ url: uploadedImageUrl });
    }
    await pool.end();
    await fs.rm(uploadDir, { recursive: true, force: true });
  });

  describe('Health endpoints', () => {
    it('exposes a lightweight public health response', async () => {
      const response = await request.get('/health');

      expect(response.status).toBe(200);
      expect(response.body).toMatchObject({ status: 'ok' });
      expect(Number.isFinite(response.body.uptime)).toBe(true);
      expect(Number.isNaN(Date.parse(response.body.timestamp))).toBe(false);
    });

    it('restricts detailed health checks to administrators', async () => {
      const anonymous = await request.get('/health/detailed');
      const user = await request
        .get('/health/detailed')
        .set('Authorization', `Bearer ${userToken}`);
      const admin = await request
        .get('/health/detailed')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(anonymous.status).toBe(401);
      expect(user.status).toBe(403);
      expect(admin.status).toBe(200);
      expect(admin.body.services.database.status).toBe('connected');
    });
  });

  describe('Role CRUD endpoints', () => {
    it('requires authentication to list roles and returns active roles to users', async () => {
      const anonymous = await request.get('/api/roles');
      const authenticated = await request
        .get('/api/roles?page=1&limit=2')
        .set('Authorization', `Bearer ${userToken}`);

      expect(anonymous.status).toBe(401);
      expect(authenticated.status).toBe(200);
      expect(authenticated.body.data.roles).toHaveLength(2);
      expect(authenticated.body.data.pagination).toMatchObject({
        currentPage: 1,
        itemsPerPage: 2,
        totalItems: 3,
      });
    });

    it('blocks non-admin role mutations', async () => {
      const response = await request
        .post('/api/roles')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ role_name: 'blocked-role' });

      expect(response.status).toBe(403);
    });

    it('creates, updates, and soft-deletes an unassigned role', async () => {
      const created = await request
        .post('/api/roles')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ role_name: 'route-coverage-role', description: 'Initial description' });

      expect(created.status).toBe(201);
      expect(created.body.data.role).toMatchObject({
        role_name: 'route-coverage-role',
        status: 'active',
      });
      customRoleId = created.body.data.role.role_id;

      const duplicate = await request
        .post('/api/roles')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ role_name: 'route-coverage-role' });
      expect(duplicate.status).toBe(409);

      const updated = await request
        .put(`/api/roles/${customRoleId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ role_name: 'route-coverage-updated', description: 'Updated description' });
      expect(updated.status).toBe(200);
      expect(updated.body.data.role).toMatchObject({
        role_name: 'route-coverage-updated',
        description: 'Updated description',
      });

      const removed = await request
        .delete(`/api/roles/${customRoleId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(removed.status).toBe(200);
      expect(removed.body.data.role.status).toBe('inactive');

      const listed = await request
        .get('/api/roles')
        .set('Authorization', `Bearer ${userToken}`);
      expect(listed.body.data.roles.some((role) => role.role_id === customRoleId)).toBe(false);
    });

    it('prevents deleting protected or assigned roles', async () => {
      const protectedRole = await request
        .delete('/api/roles/1')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(protectedRole.status).toBe(403);

      const assignedRole = await request
        .post('/api/roles')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ role_name: 'assigned-route-role' });
      const roleId = assignedRole.body.data.role.role_id;
      await pool.query(
        'UPDATE users SET role_id = $1 WHERE email = $2',
        [roleId, 'route.coverage.user@integration.test'],
      );

      const deletion = await request
        .delete(`/api/roles/${roleId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(deletion.status).toBe(409);

      // Preserve the role claim associated with userToken for later upload tests.
      await pool.query(
        'UPDATE users SET role_id = 2 WHERE email = $1',
        ['route.coverage.user@integration.test'],
      );
    });
  });

  describe('Image upload endpoints', () => {
    it('enforces authentication and administrator permissions before upload parsing', async () => {
      const anonymous = await request.post('/api/upload');
      const regularUser = await request
        .post('/api/upload')
        .set('Authorization', `Bearer ${userToken}`);

      expect(anonymous.status).toBe(401);
      expect(regularUser.status).toBe(403);
    });

    it('validates missing files, uploads a raster image, and deletes only its local URL', async () => {
      const missing = await request
        .post('/api/upload')
        .set('Authorization', `Bearer ${adminToken}`)
        .field('folder', 'tractors');
      expect(missing.status).toBe(400);

      const png = await sharp({
        create: { width: 2, height: 2, channels: 4, background: '#336699' },
      }).png().toBuffer();
      const upload = await request
        .post('/api/upload')
        .set('Authorization', `Bearer ${adminToken}`)
        .field('folder', 'tractors')
        .attach('image', png, { filename: 'tractor-test.png', contentType: 'image/png' });

      expect(upload.status).toBe(201);
      expect(upload.body.data).toMatchObject({ folder: 'tractors', mimetype: 'image/webp' });
      expect(upload.body.data.url).toMatch(/^\/uploads\/tractors\/.+\.webp$/);
      uploadedImageUrl = upload.body.data.url;

      const remoteDelete = await request
        .delete('/api/upload')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ url: 'https://example.invalid/private/image.jpg' });
      expect(remoteDelete.status).toBe(400);

      const deleted = await request
        .delete('/api/upload')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ url: uploadedImageUrl });
      expect(deleted.status).toBe(200);
      expect(deleted.body.success).toBe(true);
      uploadedImageUrl = undefined;
    });
  });
});
