/**
 * API integration coverage for the tractor and implement catalog CRUD routes.
 * These routes are admin-only for writes and soft-delete catalog rows.
 */

import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import {
  request,
  createAdminAndGetToken,
  registerAndGetToken,
  resetTestDB,
  closePool,
} from './helpers/testHelpers.js';

describe('CRUD de catálogos - Integración', () => {
  let adminToken;
  let userToken;

  beforeAll(async () => {
    await resetTestDB();
    ({ token: adminToken } = await createAdminAndGetToken());
    ({ token: userToken } = await registerAndGetToken({
      name: 'Catalog Reader',
      email: `catalog-reader-${Date.now()}@integration.test`,
      password: 'ReaderPassword1',
    }));
  });

  afterAll(async () => {
    await closePool();
  });

  it('restringe las escrituras de tractores a administradores', async () => {
    const payload = {
      brand: 'Integration Brand',
      model: `Restricted-${Date.now()}`,
      engine_power_hp: 85,
      weight_kg: 3500,
      traction_force_kn: 35,
      traction_type: 'mfwd',
    };

    const anonymous = await request.post('/api/tractors').send(payload);
    const regularUser = await request
      .post('/api/tractors')
      .set('Authorization', `Bearer ${userToken}`)
      .send(payload);

    expect(anonymous.status).toBe(401);
    expect(regularUser.status).toBe(403);
  });

  it('completa el CRUD de tractor, persiste tracción y archiva al eliminar', async () => {
    const model = `Crud-${Date.now()}`;
    const created = await request
      .post('/api/tractors')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: `Integration ${model}`,
        brand: 'Integration Brand',
        model,
        model_year: 2025,
        engine_power_hp: 85,
        price: 65000,
        weight_kg: 3500,
        traction_force_kn: 35,
        traction_type: 'mfwd',
        status: 'available',
      });

    expect(created.status).toBe(201);
    expect(created.body.success).toBe(true);
    expect(created.body.data).toMatchObject({ brand: 'Integration Brand', model, traction_type: 'mfwd' });
    const tractorId = created.body.data.tractor_id;

    const listed = await request.get('/api/tractors');
    expect(listed.status).toBe(200);
    expect(listed.body.data.some((tractor) => tractor.tractor_id === tractorId)).toBe(true);

    const available = await request.get('/api/tractors/available');
    expect(available.status).toBe(200);
    expect(available.body.data.some((tractor) => tractor.tractor_id === tractorId)).toBe(true);

    const searched = await request.get('/api/tractors/search').query({ brand: 'Integration Brand' });
    expect(searched.status).toBe(200);
    expect(searched.body.data.some((tractor) => tractor.tractor_id === tractorId)).toBe(true);

    const fetched = await request.get(`/api/tractors/${tractorId}`);
    expect(fetched.status).toBe(200);
    expect(fetched.body.data.traction_type).toBe('mfwd');

    const updated = await request
      .put(`/api/tractors/${tractorId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ model: `${model}-Updated`, traction_type: 'track', engine_power_hp: 90 });

    expect(updated.status).toBe(200);
    expect(updated.body.data).toMatchObject({ model: `${model}-Updated`, traction_type: 'track', engine_power_hp: 90 });

    const deleted = await request
      .delete(`/api/tractors/${tractorId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(deleted.status).toBe(200);
    expect(deleted.body.data.status).toBe('inactive');

    const archived = await request.get(`/api/tractors/${tractorId}`);
    expect(archived.status).toBe(200);
    expect(archived.body.data.status).toBe('inactive');

    const availableAfterArchive = await request.get('/api/tractors/available');
    expect(availableAfterArchive.body.data.some((tractor) => tractor.tractor_id === tractorId)).toBe(false);
  });

  it('rechaza tipo de tracción fuera del catálogo', async () => {
    const invalid = await request
      .post('/api/tractors')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        brand: 'Integration Brand',
        model: `Invalid-${Date.now()}`,
        engine_power_hp: 85,
        weight_kg: 3500,
        traction_force_kn: 35,
        traction_type: 'front-wheel-drive',
      });

    expect(invalid.status).toBe(400);
    expect(invalid.body.success).toBe(false);
    expect(invalid.body.errors).toContain('traction_type debe ser uno de: 4x2, mfwd, 4x4, track');
  });

  it('completa el CRUD de implemento y archiva al eliminar', async () => {
    const implementName = `Integration Implement ${Date.now()}`;
    const created = await request
      .post('/api/implements')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        implement_name: implementName,
        brand: 'Integration Brand',
        implement_type: 'cultivator',
        power_requirement_hp: 45,
        working_width_m: 2.4,
        working_depth_cm: 23,
        n_tines: 7,
        weight_kg: 520,
        status: 'available',
      });

    expect(created.status).toBe(201);
    expect(created.body.success).toBe(true);
    expect(created.body.data).toMatchObject({ implement_name: implementName, implement_type: 'cultivator' });
    const implementId = created.body.data.implement_id;

    const listed = await request.get('/api/implements');
    expect(listed.status).toBe(200);
    expect(listed.body.data.some((implement) => implement.implement_id === implementId)).toBe(true);

    const available = await request.get('/api/implements/available');
    expect(available.status).toBe(200);
    expect(available.body.data.some((implement) => implement.implement_id === implementId)).toBe(true);

    const searched = await request.get('/api/implements/search').query({ q: implementName });
    expect(searched.status).toBe(200);
    expect(searched.body.data.some((implement) => implement.implement_id === implementId)).toBe(true);

    const fetched = await request.get(`/api/implements/${implementId}`);
    expect(fetched.status).toBe(200);
    expect(fetched.body.data.implement_name).toBe(implementName);

    const updated = await request
      .put(`/api/implements/${implementId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ implement_name: `${implementName} Updated`, working_depth_cm: 27, n_tines: 9 });

    expect(updated.status).toBe(200);
    expect(updated.body.data).toMatchObject({
      implement_name: `${implementName} Updated`,
      working_depth_cm: 27,
      n_tines: 9,
    });

    const deleted = await request
      .delete(`/api/implements/${implementId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(deleted.status).toBe(200);
    expect(deleted.body.data.status).toBe('inactive');

    const archived = await request.get(`/api/implements/${implementId}`);
    expect(archived.status).toBe(200);
    expect(archived.body.data.status).toBe('inactive');
  });
});
