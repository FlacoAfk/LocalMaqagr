import { describe, expect, jest, test } from '@jest/globals';
import {
  validateImplement,
  validateTractor,
} from '../../../src/middleware/validation.middleware.js';

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('validation.middleware', () => {
  test('validateTractor permite payload válido en creación', () => {
    const req = {
      method: 'POST',
      body: {
        brand: 'John Deere',
        model: '5075E',
        model_year: 2023,
        engine_power_hp: 75,
        price: 120000,
        weight_kg: 2500,
        fuel_tank_l: 90,
        traction_type: '4x4',
        status: 'available',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    validateTractor(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  test('validateTractor acepta imagen local segura y rechaza traversal o ruta absoluta', () => {
    const validReq = {
      method: 'PUT',
      body: { image_url: '/uploads/tractors/tractor-1.jpg' },
    };
    const validRes = createMockRes();
    const validNext = jest.fn();

    validateTractor(validReq, validRes, validNext);

    expect(validNext).toHaveBeenCalled();

    for (const image_url of [
      '/uploads/tractors/../secret.jpg',
      '/uploads/tractors/%2e%2e/secret.jpg',
      'C:\\ProgramData\\MaqAgr\\uploads\\tractors\\tractor-1.jpg',
    ]) {
      const res = createMockRes();
      const next = jest.fn();
      validateTractor({ method: 'PUT', body: { image_url } }, res, next);
      expect(next).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(400);
    }
  });

  test('validateImplement acepta imagen local segura y URLs http/https', () => {
    const next = jest.fn();
    const res = createMockRes();

    validateImplement(
      { method: 'PATCH', body: { image_url: '/uploads/implements/implement-1.webp' } },
      res,
      next,
    );

    expect(next).toHaveBeenCalled();

    const httpsNext = jest.fn();
    validateImplement(
      { method: 'PATCH', body: { image_url: 'https://images.example.test/implement.webp' } },
      createMockRes(),
      httpsNext,
    );
    expect(httpsNext).toHaveBeenCalled();
  });

  test('validateTractor agrega errores requeridos en POST', () => {
    const req = {
      method: 'POST',
      body: {},
    };
    const res = createMockRes();
    const next = jest.fn();

    validateTractor(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      errors: [
        'brand es requerido',
        'model es requerido',
        'engine_power_hp es requerido',
        'traction_type es requerido',
      ],
    });
  });

  test('validateTractor valida update con campos vacíos, numéricos inválidos, año inválido y enums inválidos', () => {
    const req = {
      method: 'PUT',
      body: {
        brand: ' ',
        model: '',
        model_year: 1800,
        engine_power_hp: -10,
        price: 'abc',
        weight_kg: 0,
        fuel_tank_l: -2,
        traction_type: '6x6',
        status: 'sold',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    validateTractor(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      errors: [
        'brand no puede estar vacío',
        'model no puede estar vacío',
        'engine_power_hp debe ser un número positivo',
        'price debe ser un número positivo',
        'weight_kg debe ser un número positivo',
        'fuel_tank_l debe ser un número positivo',
        'model_year debe ser un año válido entre 1900 y 2100',
        'traction_type debe ser uno de: 4x2, 4x4, track',
        'status debe ser uno de: available, maintenance, inactive, out_of_service',
      ],
    });
  });

  test('validateTractor acepta status out_of_service en creación y en update', () => {
    const createReq = {
      method: 'POST',
      body: {
        brand: 'John Deere',
        model: '5075E',
        engine_power_hp: 75,
        traction_type: '4x4',
        status: 'out_of_service',
      },
    };
    const updateReq = {
      method: 'PUT',
      body: { status: 'out_of_service' },
    };

    const createRes = createMockRes();
    validateTractor(createReq, createRes, jest.fn());
    expect(createRes.status).not.toHaveBeenCalled();

    const updateRes = createMockRes();
    validateTractor(updateReq, updateRes, jest.fn());
    expect(updateRes.status).not.toHaveBeenCalled();
  });

  test('validateImplement permite payload válido en creación', () => {
    const req = {
      method: 'POST',
      body: {
        implement_name: 'Arado',
        brand: 'Massey',
        power_requirement_hp: 90,
        working_width_m: 2.5,
        working_depth_cm: 30,
        weight_kg: 850,
        implement_type: 'plow',
        status: 'available',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    validateImplement(req, res, next);

    expect(next).toHaveBeenCalled();
  });

  test('validateImplement agrega errores requeridos y numéricos en POST', () => {
    const req = {
      method: 'POST',
      body: {
        power_requirement_hp: '',
        working_width_m: '',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    validateImplement(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      errors: [
        'implement_name es requerido',
        'brand es requerido',
        'power_requirement_hp es requerido',
        'working_width_m es requerido',
        'implement_type es requerido',
      ],
    });
  });

  test('validateImplement valida update con campos vacíos y enums inválidos', () => {
    const req = {
      method: 'PATCH',
      body: {
        implement_name: '',
        brand: ' ',
        power_requirement_hp: -1,
        working_width_m: 0,
        working_depth_cm: 'texto',
        weight_kg: -5,
        implement_type: 'laser',
        status: 'archived',
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    validateImplement(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      errors: [
        'implement_name no puede estar vacío',
        'brand no puede estar vacío',
        'power_requirement_hp debe ser un número positivo',
        'working_width_m debe ser un número positivo',
        'working_depth_cm debe ser un número positivo',
        'weight_kg debe ser un número positivo',
        'implement_type debe ser uno de: plow, harrow, seeder, sprayer, harvester, cultivator, mower, trailer, other',
        'status debe ser uno de: available, maintenance, inactive, out_of_service',
      ],
    });
  });

  test('validateImplement acepta status out_of_service en creación y en update', () => {
    const createReq = {
      method: 'POST',
      body: {
        implement_name: 'Arado',
        brand: 'Massey',
        power_requirement_hp: 90,
        working_width_m: 2.5,
        implement_type: 'plow',
        status: 'out_of_service',
      },
    };
    const updateReq = {
      method: 'PATCH',
      body: { status: 'out_of_service' },
    };

    const createRes = createMockRes();
    validateImplement(createReq, createRes, jest.fn());
    expect(createRes.status).not.toHaveBeenCalled();

    const updateRes = createMockRes();
    validateImplement(updateReq, updateRes, jest.fn());
    expect(updateRes.status).not.toHaveBeenCalled();
  });
});
