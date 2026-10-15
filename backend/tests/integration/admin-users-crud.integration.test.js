/**
 * API integration coverage for administrative user management.
 */

import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import {
  request,
  createAdminAndGetToken,
  registerAndGetToken,
  createTestTerrain,
  resetTestDB,
  closePool,
} from './helpers/testHelpers.js';

describe('Gestión administrativa de usuarios - Integración', () => {
  let admin;
  let managedUser;

  beforeAll(async () => {
    await resetTestDB();
    admin = await createAdminAndGetToken();
    ({ user: managedUser } = await registerAndGetToken({
      name: 'Managed Integration User',
      email: `managed-${Date.now()}@integration.test`,
      password: 'ManagedPassword1',
    }));
  });

  afterAll(async () => {
    await closePool();
  });

  it('permite a un admin listar, leer, actualizar y eliminar otro usuario', async () => {
    const list = await request
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${admin.token}`);

    expect(list.status).toBe(200);
    expect(list.body.data.some((user) => user.user_id === managedUser.user_id)).toBe(true);

    const fetched = await request
      .get(`/api/admin/users/${managedUser.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);

    expect(fetched.status).toBe(200);
    expect(fetched.body.data.email).toBe(managedUser.email);

    const updated = await request
      .put(`/api/admin/users/${managedUser.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ name: 'Managed User Updated', status: 'suspended' });

    expect(updated.status).toBe(200);
    expect(updated.body.data).toMatchObject({ name: 'Managed User Updated', status: 'suspended' });

    const deleted = await request
      .delete(`/api/auth/users/${managedUser.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);

    expect(deleted.status).toBe(200);
    expect(deleted.body.success).toBe(true);

    const missing = await request
      .get(`/api/admin/users/${managedUser.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);

    expect(missing.status).toBe(404);
  });

  it('rechaza la gestión administrativa de usuarios para un usuario normal', async () => {
    const { token: userToken } = await registerAndGetToken({
      name: 'Unauthorized Integration User',
      email: `unauthorized-${Date.now()}@integration.test`,
      password: 'UnauthorizedPassword1',
    });
    const list = await request
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${userToken}`);
    const update = await request
      .put(`/api/admin/users/${managedUser.user_id}`)
      .set('Authorization', `Bearer ${userToken}`)
      .send({ role_id: 1 });

    expect(list.status).toBe(403);
    expect(update.status).toBe(403);
  });

  it('impide a un admin desactivar, degradar o eliminar su propia cuenta', async () => {
    const demote = await request
      .put(`/api/admin/users/${admin.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ role_id: 2 });
    const deactivate = await request
      .put(`/api/admin/users/${admin.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ status: 'inactive' });
    const deleteSelf = await request
      .delete(`/api/auth/users/${admin.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);

    expect(demote.status).toBe(400);
    expect(deactivate.status).toBe(400);
    expect(deleteSelf.status).toBe(400);

    const stillAdmin = await request
      .get(`/api/admin/users/${admin.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);
    expect(stillAdmin.status).toBe(200);
    expect(stillAdmin.body.data).toMatchObject({ role_id: 1, status: 'active' });
  });

  it('no elimina una cuenta que todavía tiene terrenos asociados', async () => {
    const terrainOwner = await registerAndGetToken({
      name: 'Terrain Owner',
      email: `terrain-owner-${Date.now()}@integration.test`,
      password: 'OwnerPassword1',
    });
    await createTestTerrain(terrainOwner.token, {
      name: 'Protected Test Terrain',
      area_hectares: 2,
      altitude_meters: 1000,
      slope_percentage: 5,
      soil_type: 'Loam',
      temperature_celsius: 20,
    });

    const deleted = await request
      .delete(`/api/auth/users/${terrainOwner.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);

    expect(deleted.status).toBe(400);
    expect(deleted.body.message).toMatch(/terrenos registrados/i);

    const stillPresent = await request
      .get(`/api/admin/users/${terrainOwner.user.user_id}`)
      .set('Authorization', `Bearer ${admin.token}`);
    expect(stillPresent.status).toBe(200);
  });
});
