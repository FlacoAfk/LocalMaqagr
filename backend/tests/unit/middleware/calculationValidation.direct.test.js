/**
 * FIX-004: Coverage complementario para validateDirectPowerLossRequest
 * (flujo "Tengo Tractor" — datos manuales sin IDs de DB)
 *
 * Este archivo es ADITIVO: no modifica tests existentes.
 * Cubre ramas no ejercitadas de calculationValidation.middleware.js
 * (validateDirectPowerLossRequest estaba sin tests).
 */
import { describe, test, expect, jest, beforeEach } from '@jest/globals';
import { validateDirectPowerLossRequest, validateDirectImplementPowerRequest } from '../../../src/middleware/calculationValidation.middleware.js';

describe('validateDirectPowerLossRequest (FIX-004)', () => {
  let mockReq, mockRes, mockNext;

  beforeEach(() => {
    mockReq = { body: {} };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
  });

  const validBody = () => ({
    engine_power_hp: 100,
    weight_kg: 5000,
    soil_type: 'loam',
    altitude_m: 100,
    ambient_temperature_c: 25,
    slope_percent: 5,
    slippage_percent: 10,
  });

  describe('casos exitosos', () => {
    test('pasa validación con body válido completo', () => {
      mockReq.body = validBody();

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockRes.status).not.toHaveBeenCalled();
    });

    test('aplica defaults: working_speed_kmh = 7 y carried_objects_weight_kg = 0 cuando no se envían', () => {
      mockReq.body = validBody();

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockReq.body.working_speed_kmh).toBe(7);
      expect(mockReq.body.carried_objects_weight_kg).toBe(0);
    });

    test('convierte valores numéricos string a number', () => {
      mockReq.body = {
        ...validBody(),
        engine_power_hp: '110.5',
        altitude_m: '200',
        ambient_temperature_c: '18',
        slope_percent: '3',
        slippage_percent: '12',
        working_speed_kmh: '8.5',
        carried_objects_weight_kg: '450',
      };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockReq.body.engine_power_hp).toBe(110.5);
      expect(mockReq.body.altitude_m).toBe(200);
      expect(mockReq.body.ambient_temperature_c).toBe(18);
      expect(mockReq.body.slope_percent).toBe(3);
      expect(mockReq.body.slippage_percent).toBe(12);
      expect(mockReq.body.working_speed_kmh).toBe(8.5);
      expect(mockReq.body.carried_objects_weight_kg).toBe(450);
    });

    test('acepta límite inferior: working_speed_kmh 39.9', () => {
      mockReq.body = { ...validBody(), working_speed_kmh: 39.9 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('campos requeridos faltantes', () => {
    const cases = [
      { missing: 'engine_power_hp', error: 'engine_power_hp es requerido' },
      { missing: 'weight_kg', error: 'weight_kg es requerido' },
      { missing: 'soil_type', error: 'soil_type es requerido' },
      { missing: 'altitude_m', error: 'altitude_m es requerido' },
      { missing: 'ambient_temperature_c', error: 'ambient_temperature_c es requerido' },
      { missing: 'slope_percent', error: 'slope_percent es requerido' },
      { missing: 'slippage_percent', error: 'slippage_percent es requerido' },
    ];

    cases.forEach(({ missing, error }) => {
      test(`rechaza si falta ${missing}`, () => {
        const body = validBody();
        delete body[missing];
        mockReq.body = body;

        validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith(
          expect.objectContaining({
            success: false,
            errors: expect.arrayContaining([error]),
          })
        );
        expect(mockNext).not.toHaveBeenCalled();
      });
    });

    test('rechaza si soil_type es string vacío', () => {
      mockReq.body = { ...validBody(), soil_type: '' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockNext).not.toHaveBeenCalled();
    });

    test('rechaza si soil_type es solo espacios', () => {
      mockReq.body = { ...validBody(), soil_type: '   ' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
    });
  });

  describe('valores inválidos', () => {
    test('rechaza engine_power_hp no numérico', () => {
      mockReq.body = { ...validBody(), engine_power_hp: 'muchos' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('mayor a 0')]),
        })
      );
    });

    test('rechaza engine_power_hp = 0', () => {
      mockReq.body = { ...validBody(), engine_power_hp: 0 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
    });

    test('rechaza engine_power_hp negativo', () => {
      mockReq.body = { ...validBody(), engine_power_hp: -5 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
    });

    test('rechaza weight_kg negativo', () => {
      mockReq.body = { ...validBody(), weight_kg: -1 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('mayor a 0')]),
        })
      );
    });

    test('rechaza altitude_m negativo', () => {
      mockReq.body = { ...validBody(), altitude_m: -10 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('mayor o igual a 0')]),
        })
      );
    });

    test('rechaza ambient_temperature_c no numérico', () => {
      mockReq.body = { ...validBody(), ambient_temperature_c: 'caluroso' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining(['ambient_temperature_c debe ser un número']),
        })
      );
    });

    test('rechaza slope_percent negativo', () => {
      mockReq.body = { ...validBody(), slope_percent: -1 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
    });

    test('rechaza slippage_percent negativo', () => {
      mockReq.body = { ...validBody(), slippage_percent: -5 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
    });

    test('rechaza slippage_percent > 100', () => {
      mockReq.body = { ...validBody(), slippage_percent: 150 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining(['slippage_percent debe estar entre 0 y 100']),
        })
      );
    });

    test('rechaza working_speed_kmh no numérico', () => {
      mockReq.body = { ...validBody(), working_speed_kmh: 'rapido' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('mayor a 0')]),
        })
      );
    });

    test('rechaza working_speed_kmh = 40 (límite superior)', () => {
      mockReq.body = { ...validBody(), working_speed_kmh: 40 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('menor a 40')]),
        })
      );
    });

    test('rechaza carried_objects_weight_kg negativo', () => {
      mockReq.body = { ...validBody(), carried_objects_weight_kg: -100 };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining([expect.stringContaining('mayor o igual a 0')]),
        })
      );
    });
  });

  describe('has_turbo (opcional, normalización)', () => {
    const turboTrueCases = ['si', 'sí', 'true', true];
    turboTrueCases.forEach((value) => {
      test(`normaliza has_turbo = ${JSON.stringify(value)} a true`, () => {
        mockReq.body = { ...validBody(), has_turbo: value };

        validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockReq.body.has_turbo).toBe(true);
      });
    });

    const turboFalseCases = ['no', 'false', false];
    turboFalseCases.forEach((value) => {
      test(`normaliza has_turbo = ${JSON.stringify(value)} a false`, () => {
        mockReq.body = { ...validBody(), has_turbo: value };

        validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockReq.body.has_turbo).toBe(false);
      });
    });

    test('has_turbo ausente → false', () => {
      mockReq.body = validBody();

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockReq.body.has_turbo).toBe(false);
    });

    test('rechaza has_turbo con valor inválido', () => {
      mockReq.body = { ...validBody(), has_turbo: 'quizas' };

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          errors: expect.arrayContaining(['has_turbo debe ser boolean o si/no']),
        })
      );
    });
  });

  describe('múltiples errores y formato de respuesta', () => {
    test('acumula todos los errores con body vacío', () => {
      mockReq.body = {};

      validateDirectPowerLossRequest(mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Errores de validación',
          errors: expect.arrayContaining([
            'engine_power_hp es requerido',
            'weight_kg es requerido',
            'soil_type es requerido',
            'altitude_m es requerido',
            'ambient_temperature_c es requerido',
            'slope_percent es requerido',
            'slippage_percent es requerido',
          ]),
        })
      );
      expect(mockNext).not.toHaveBeenCalled();
    });
  });
});

describe('validateDirectImplementPowerRequest (tractor opcional)', () => {
  let mockReq, mockRes, mockNext;

  beforeEach(() => {
    mockReq = { body: {} };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
  });

  const implementBody = () => ({
    implement_type: 'rastra_pesada_26',
    working_width_m: 3,
    working_speed_kmh: 7.5,
    soil_type: 'arcilla',
  });

  test('sin engine_power_hp pasa la validación (solo potencia requerida)', () => {
    mockReq.body = implementBody();

    validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

    expect(mockNext).toHaveBeenCalled();
    expect(mockRes.status).not.toHaveBeenCalled();
    expect(mockReq.body.engine_power_hp).toBeUndefined();
  });

  test('con engine_power_hp lo normaliza a número y aplica defaults de tractor', () => {
    mockReq.body = {
      ...implementBody(),
      engine_power_hp: '100',
      traction_type: '4x2',
      soil_condition: 'Bueno',
    };

    validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

    expect(mockNext).toHaveBeenCalled();
    expect(mockReq.body.engine_power_hp).toBe(100);
    expect(mockReq.body.soil_condition).toBe('bueno');
    expect(mockReq.body.soil_type).toBe('arcilla');
  });

  test('con engine_power_hp inválido (<= 0) rechaza con 400', () => {
    mockReq.body = { ...implementBody(), engine_power_hp: 0 };

    validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

    expect(mockNext).not.toHaveBeenCalled();
    expect(mockRes.status).toHaveBeenCalledWith(400);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        errors: expect.arrayContaining([
          'engine_power_hp debe ser un número mayor a 0',
        ]),
      }),
    );
  });
});

describe('validateDirectImplementPowerRequest (numéricos del tractor opcionales, issue #5)', () => {
  let mockReq, mockRes, mockNext;

  beforeEach(() => {
    mockReq = { body: {} };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
  });

  const implementBody = () => ({
    implement_type: 'rastra_pesada_26',
    working_width_m: 3,
    working_speed_kmh: 7.5,
    soil_type: 'arcilla',
  });

  test('sin datos numéricos del tractor pasa y aplica los defaults', () => {
    mockReq.body = implementBody();

    validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

    expect(mockNext).toHaveBeenCalled();
    expect(mockRes.status).not.toHaveBeenCalled();
    expect(mockReq.body.altitude_m).toBe(0);
    expect(mockReq.body.ambient_temperature_c).toBe(15);
    expect(mockReq.body.total_weight_kg).toBe(0);
    expect(mockReq.body.slope_percent).toBe(0);
  });

  const invalidCases = [
    { field: 'altitude_m', value: 'abc', error: 'altitude_m debe ser un número mayor o igual a 0' },
    { field: 'altitude_m', value: -10, error: 'altitude_m debe ser un número mayor o igual a 0' },
    { field: 'ambient_temperature_c', value: 'caluroso', error: 'ambient_temperature_c debe ser un número' },
    { field: 'total_weight_kg', value: 'pesado', error: 'total_weight_kg debe ser un número mayor o igual a 0' },
    { field: 'total_weight_kg', value: -100, error: 'total_weight_kg debe ser un número mayor o igual a 0' },
    { field: 'slope_percent', value: -1, error: 'slope_percent debe ser un número mayor o igual a 0' },
  ];

  invalidCases.forEach(({ field, value, error }) => {
    test(`rechaza ${field} = ${JSON.stringify(value)} con 400`, () => {
      mockReq.body = { ...implementBody(), [field]: value };

      validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

      expect(mockNext).not.toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          errors: expect.arrayContaining([error]),
        }),
      );
    });
  });

  test('acepta valores válidos en el límite (0 en altitude/peso/pendiente)', () => {
    mockReq.body = {
      ...implementBody(),
      altitude_m: 0,
      ambient_temperature_c: -5,
      total_weight_kg: 0,
      slope_percent: 0,
    };

    validateDirectImplementPowerRequest(mockReq, mockRes, mockNext);

    expect(mockNext).toHaveBeenCalled();
    expect(mockRes.status).not.toHaveBeenCalled();
    expect(mockReq.body.altitude_m).toBe(0);
    expect(mockReq.body.ambient_temperature_c).toBe(-5);
    expect(mockReq.body.total_weight_kg).toBe(0);
    expect(mockReq.body.slope_percent).toBe(0);
  });
});
