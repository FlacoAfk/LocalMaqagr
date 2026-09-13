import { beforeAll, afterAll, beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockConnect = jest.fn();
const mockPoolQuery = jest.fn();
const mockTractorFindById = jest.fn();
const mockTractorGetAll = jest.fn();
const mockTerrainFindById = jest.fn();
const mockImplementFindById = jest.fn();
const mockCalculateTotalLoss = jest.fn();
const mockCalculateTotalLossWithZoz = jest.fn();
const mockCalculateMinimumPower = jest.fn();
const mockLoggerInfo = jest.fn();

const mockClient = {
  query: jest.fn(),
  release: jest.fn(),
};

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  __esModule: true,
  pool: {
    connect: mockConnect,
    query: mockPoolQuery,
  },
}));

jest.unstable_mockModule('../../../src/models/Tractor.js', () => ({
  __esModule: true,
  default: {
    findById: mockTractorFindById,
    getAll: mockTractorGetAll,
  },
}));

jest.unstable_mockModule('../../../src/models/Terrain.js', () => ({
  __esModule: true,
  default: {
    findById: mockTerrainFindById,
  },
}));

jest.unstable_mockModule('../../../src/models/Implement.js', () => ({
  __esModule: true,
  default: {
    findById: mockImplementFindById,
  },
}));

jest.unstable_mockModule('../../../src/services/powerLossService.js', () => ({
  __esModule: true,
  calculateTotalLoss: mockCalculateTotalLoss,
  calculateTotalLossWithZoz: mockCalculateTotalLossWithZoz,
}));

jest.unstable_mockModule('../../../src/services/minimumPowerService.js', () => ({
  __esModule: true,
  calculateMinimumPower: mockCalculateMinimumPower,
}));

jest.unstable_mockModule('../../../src/config/logger.js', () => ({
  __esModule: true,
  default: {
    info: mockLoggerInfo,
    error: jest.fn(),
    warn: jest.fn(),
  },
}));

const controller = await import('../../../src/controllers/calculationController.js');
const {
calculatePowerLoss,
calculateMinimumPower,
calculateDirectMinimumPower,
calculateDirectPowerLoss,
calculateDirectImplementPower,
getCalculationHistory,
} = controller;

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const callWrappedHandler = async (handler, req, res, next = jest.fn()) => {
  handler(req, res, next);
  await new Promise((resolve) => setImmediate(resolve));
  return next;
};

let consoleErrorSpy;

beforeAll(() => {
  consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  consoleErrorSpy.mockRestore();
});

describe('calculationController', () => {
  beforeEach(() => {
    [
      mockConnect,
      mockPoolQuery,
      mockTractorFindById,
      mockTractorGetAll,
      mockTerrainFindById,
      mockImplementFindById,
      mockCalculateTotalLoss,
      mockCalculateTotalLossWithZoz,
      mockCalculateMinimumPower,
      mockLoggerInfo,
      mockClient.query,
      mockClient.release,
    ].forEach((mockFn) => mockFn.mockReset());
    mockConnect.mockResolvedValue(mockClient);
    mockClient.query.mockResolvedValue({ rows: [] });
  });

  describe('calculatePowerLoss()', () => {
    test('retorna 401 cuando no hay usuario autenticado en req.user', async () => {
      const req = {
        body: {
          tractor_id: 1,
          terrain_id: 2,
          working_speed_kmh: 8,
          user_id: 999,
        },
      };
      const res = createMockRes();

      await callWrappedHandler(calculatePowerLoss, req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Usuario no autenticado',
      });
      expect(mockTractorFindById).not.toHaveBeenCalled();
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('retorna 400 cuando faltan campos requeridos', async () => {
      const req = {
        body: { tractor_id: 1 },
        user: { user_id: 10 },
      };
      const res = createMockRes();

      await callWrappedHandler(calculatePowerLoss, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Faltan campos requeridos: tractor_id, terrain_id, working_speed_kmh',
      });
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('retorna 404 cuando el tractor no existe', async () => {
      const req = {
        body: {
          tractor_id: 1,
          terrain_id: 2,
          working_speed_kmh: 8,
        },
        user: { user_id: 10 },
      };
      const res = createMockRes();
      mockTractorFindById.mockResolvedValue(null);
      mockTerrainFindById.mockResolvedValue({ terrain_id: 2 });

      await callWrappedHandler(calculatePowerLoss, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Tractor no encontrado',
      });
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('retorna 404 cuando el terreno no existe', async () => {
      const req = {
        body: {
          tractor_id: 1,
          terrain_id: 2,
          working_speed_kmh: 8,
        },
        user: { user_id: 10 },
      };
      const res = createMockRes();
      mockTractorFindById.mockResolvedValue({ tractor_id: 1, weight_kg: 5000, engine_power_hp: 120 });
      mockTerrainFindById.mockResolvedValue(null);

      await callWrappedHandler(calculatePowerLoss, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Terreno no encontrado',
      });
    });

    test('persiste y responde cálculo de pérdidas exitoso', async () => {
      const req = {
        body: {
          tractor_id: 4,
          terrain_id: 6,
          working_speed_kmh: 7,
          carried_objects_weight_kg: 500,
          slippage_percent: 12,
          user_id: 77,
        },
        user: {
          user_id: 22,
        },
      };
      const res = createMockRes();

      mockTractorFindById.mockResolvedValue({
        tractor_id: 4,
        brand: 'John Deere',
        model: '6130M',
        weight_kg: 5000,
        engine_power_hp: 130,
      });
      mockTerrainFindById.mockResolvedValue({
        terrain_id: 6,
        name: 'Lote Norte',
        soil_type: 'arcilla',
        slope_percentage: 8,
        altitude_meters: 1500,
        temperature_celsius: 18,
      });
      mockCalculateTotalLoss.mockReturnValue({
        grossPower: 130,
        netPower: 101.5,
        efficiency: 78.08,
        losses: {
          slope: 5,
          altitude: 3,
          rollingResistance: 12,
          slippage: 8.5,
          total: 28.5,
        },
      });
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rows: [{ query_id: 91 }] })
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({});

      await callWrappedHandler(calculatePowerLoss, req, res);

        expect(mockCalculateTotalLoss).toHaveBeenCalledWith({
          enginePower: 130,
          altitudeMeters: 1500,
          temperatureC: 18,
          totalWeightKg: 5500,
          soilCn: 45,
          slopePercent: 8,
          speedKmh: 7,
          slippagePercent: 12,
          hasTurbo: false,
        });
      expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      expect(mockLoggerInfo).toHaveBeenCalledWith('Power calculation completed', {
        queryId: 91,
        userId: 22,
        tractorId: 4,
        terrainId: 6,
        netPower: 101.5,
        efficiency: 78.08,
        totalLoss: 28.5,
      });
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            queryId: 91,
            net_power_hp: 101.5,
            engine_power_hp: 130,
            efficiency_percentage: 78.08,
          }),
        }),
      );
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('hace rollback y delega error cuando falla la persistencia', async () => {
      const req = {
        body: {
          tractor_id: 2,
          terrain_id: 3,
          working_speed_kmh: 6,
        },
        user: { user_id: 10 },
      };
      const res = createMockRes();
      const next = jest.fn();
      const dbError = new Error('insert failed');

      mockTractorFindById.mockResolvedValue({
        tractor_id: 2,
        brand: 'Case',
        model: 'Puma',
        weight_kg: 4000,
        engine_power_hp: 100,
      });
      mockTerrainFindById.mockResolvedValue({
        terrain_id: 3,
        name: 'Campo Sur',
        soil_type: 'loam',
        slope_percentage: 2,
        altitude_meters: 500,
        temperature_celsius: 15,
      });
      mockCalculateTotalLoss.mockReturnValue({
        grossPower: 100,
        netPower: 88,
        efficiency: 88,
        losses: {
          slope: 1,
          altitude: 2,
          rollingResistance: 5,
          slippage: 4,
          total: 12,
        },
      });
      mockClient.query
        .mockResolvedValueOnce({})
        .mockRejectedValueOnce(dbError)
        .mockResolvedValueOnce({});

      await callWrappedHandler(calculatePowerLoss, req, res, next);

      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(next).toHaveBeenCalledWith(dbError);
      expect(mockClient.release).toHaveBeenCalled();
    });
  });

  describe('calculateMinimumPower()', () => {
    test('retorna 400 cuando faltan implement_id o terrain_id', async () => {
      const req = {
        body: {},
        user: { user_id: 4 },
      };
      const res = createMockRes();

      await calculateMinimumPower(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Faltan campos requeridos: implement_id, terrain_id',
      });
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('retorna 404 cuando implemento o terreno no existen', async () => {
      let req = {
        body: { implement_id: 8, terrain_id: 9 },
        user: { user_id: 4 },
      };
      let res = createMockRes();
      mockImplementFindById.mockResolvedValue(null);
      mockTerrainFindById.mockResolvedValue({ terrain_id: 9 });
      mockTractorGetAll.mockResolvedValue([]);

      await calculateMinimumPower(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Implemento no encontrado',
      });

      req = {
        body: { implement_id: 8, terrain_id: 9 },
        user: { user_id: 4 },
      };
      res = createMockRes();
      mockImplementFindById.mockResolvedValue({
        implement_id: 8,
        implement_name: 'Arado',
        power_requirement_hp: 70,
      });
      mockTerrainFindById.mockResolvedValue(null);
      mockTractorGetAll.mockResolvedValue([]);

      await calculateMinimumPower(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Terreno no encontrado',
      });
    });

    test('retorna respuesta sin persistir cuando no hay tractores compatibles', async () => {
      const req = {
        body: { implement_id: 8, terrain_id: 9 },
        user: { user_id: 14 },
      };
      const res = createMockRes();

      mockImplementFindById.mockResolvedValue({
        implement_id: 8,
        implement_name: 'Subsolador',
        implement_type: 'plow',
        brand: 'Maq',
        power_requirement_hp: 90,
        working_depth_cm: 35,
      });
      mockTerrainFindById.mockResolvedValue({
        terrain_id: 9,
        name: 'Ladera',
        soil_type: 'rocky',
        slope_percentage: 16,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, name: 'A', brand: 'X', model: '1', engine_power_hp: 80, status: 'available' },
      ]);
      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 130,
        calculatedPowerHP: 113,
        factors: { soilFactor: 1.5 },
      });
      mockClient.query.mockResolvedValueOnce({}).mockResolvedValueOnce({});

      await calculateMinimumPower(req, res);

      expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Cálculo de potencia mínima realizado (sin tractores compatibles)',
          data: expect.objectContaining({
            queryId: null,
            recommendations: {
              top_5: [],
              best_match: null,
            },
          }),
        }),
      );
    });

    test('persiste cálculo mínimo y clasifica tractores por idoneidad', async () => {
      const req = {
        body: {
          implement_id: 3,
          terrain_id: 5,
          working_depth_m: 0.3,
        },
        user: { userId: 22 },
      };
      const res = createMockRes();

      mockImplementFindById.mockResolvedValue({
        implement_id: 3,
        implement_name: 'Sembradora',
        implement_type: 'seeder',
        brand: 'Agro',
        power_requirement_hp: 80,
        working_depth_cm: 25,
      });
      mockTerrainFindById.mockResolvedValue({
        terrain_id: 5,
        name: 'Plano 1',
        soil_type: 'loam',
        slope_percentage: 3,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 10, name: 'Optimo', brand: 'JD', model: 'A', engine_power_hp: 110, status: 'available' },
        { tractor_id: 11, name: 'Grande', brand: 'Case', model: 'B', engine_power_hp: 180, status: 'available' },
        { tractor_id: 12, name: 'Corto', brand: 'NH', model: 'C', engine_power_hp: 95, status: 'available' },
        { tractor_id: 13, name: 'Inactivo', brand: 'NH', model: 'D', engine_power_hp: 150, status: 'inactive' },
      ]);
      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { slopeFactor: 1.1 },
      });
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rows: [{ query_id: 81 }] })
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({});

      await calculateMinimumPower(req, res);

      expect(mockCalculateMinimumPower).toHaveBeenCalledWith(
        {
          power_requirement_hp: 80,
          working_depth_m: 0.3,
        },
        {
          soil_type: 'loam',
          slope_percentage: 3,
        },
      );
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            queryId: 81,
            tractorAnalysis: {
              total_evaluated: 4,
              summary: {
                optimal: 1,
                overpowered: 1,
                insufficient: 1,
              },
            },
            recommendations: {
              top_5: [
                expect.objectContaining({
                  tractor_id: 10,
                  rank: 1,
                }),
                expect.objectContaining({
                  tractor_id: 11,
                  rank: 2,
                }),
              ],
              best_match: expect.objectContaining({
                tractor_id: 10,
              }),
            },
          }),
        }),
      );
    });

    test('retorna 500 y rollback cuando ocurre un error inesperado', async () => {
      const req = {
        body: { implement_id: 3, terrain_id: 5 },
        user: { user_id: 2 },
      };
      const res = createMockRes();

      mockImplementFindById.mockResolvedValue({
        implement_id: 3,
        implement_name: 'Sembradora',
        power_requirement_hp: 80,
      });
      mockTerrainFindById.mockResolvedValue({
        terrain_id: 5,
        name: 'Plano 1',
        soil_type: 'loam',
        slope_percentage: 3,
      });
      mockTractorGetAll.mockResolvedValue([]);
      mockCalculateMinimumPower.mockImplementation(() => {
        throw new Error('service failed');
      });
      mockClient.query.mockResolvedValueOnce({});

      await calculateMinimumPower(req, res);

      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error procesando la solicitud de cálculo de potencia mínima',
        error: undefined,
      });
    });
  });

  describe('calculateDirectMinimumPower()', () => {
    test('retorna cálculo exitoso sin usuario (sin persistencia)', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          working_depth_m: 0.3,
          soil_type: 'loam',
          slope_percentage: 5,
        },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0, slopeFactor: 1.1 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 10, name: 'Optimo', brand: 'JD', model: 'A', engine_power_hp: 110, status: 'available' },
        { tractor_id: 11, name: 'Grande', brand: 'Case', model: 'B', engine_power_hp: 180, status: 'available' },
        { tractor_id: 12, name: 'Corto', brand: 'NH', model: 'C', engine_power_hp: 95, status: 'available' },
      ]);

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(mockCalculateMinimumPower).toHaveBeenCalledWith(
        { power_requirement_hp: 80, working_depth_m: 0.3 },
        { soil_type: 'loam', slope_percentage: 5 },
      );
      expect(mockConnect).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: expect.stringContaining('potencia mínima'),
          data: expect.objectContaining({
            queryId: null,
            implement: expect.objectContaining({ power_requirement_hp: 80 }),
            terrain: expect.objectContaining({ soil_type: 'loam', slope_percentage: 5 }),
            powerRequirement: {
              minimum_power_hp: 100,
              calculated_power_hp: 87,
              factors: { soilFactor: 1.0, slopeFactor: 1.1 },
            },
            tractorAnalysis: {
              total_evaluated: 3,
              summary: { optimal: 1, overpowered: 1, insufficient: 1 },
            },
            recommendations: {
              top_5: [
                expect.objectContaining({ tractor_id: 10, rank: 1 }),
                expect.objectContaining({ tractor_id: 11, rank: 2 }),
              ],
              best_match: expect.objectContaining({ tractor_id: 10 }),
            },
          }),
        }),
      );
    });

    test('retorna cálculo con persistencia cuando hay usuario autenticado', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          working_depth_m: 0.3,
          soil_type: 'loam',
          slope_percentage: 5,
        },
        user: { user_id: 42 },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 10, name: 'Optimo', brand: 'JD', model: 'A', engine_power_hp: 110, status: 'available' },
      ]);
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rows: [{ query_id: 55 }] })
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({});

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(mockConnect).toHaveBeenCalled();
      expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({ queryId: 55 }),
        }),
      );
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('retorna cálculo sin persistir cuando no hay tractores recomendados', async () => {
      const req = {
        body: {
          power_requirement_hp: 200,
          soil_type: 'rocky',
          slope_percentage: 15,
        },
        user: { user_id: 5 },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 300,
        calculatedPowerHP: 260,
        factors: { soilFactor: 1.5 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, name: 'Peque', brand: 'X', model: '1', engine_power_hp: 80, status: 'available' },
      ]);

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            queryId: null,
            recommendations: { top_5: [], best_match: null },
            tractorAnalysis: expect.objectContaining({
              summary: { optimal: 0, overpowered: 0, insufficient: 1 },
            }),
          }),
        }),
      );
    });

    test('degrada gracefulmente cuando Tractor.getAll falla', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          soil_type: 'loam',
          slope_percentage: 5,
        },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0 },
      });
      mockTractorGetAll.mockRejectedValue(new Error('DB unavailable'));

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            tractorAnalysis: {
              total_evaluated: 0,
              summary: { optimal: 0, overpowered: 0, insufficient: 0 },
            },
            recommendations: { top_5: [], best_match: null },
          }),
        }),
      );
    });

    test('filtra tractores inactive del análisis', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          soil_type: 'loam',
          slope_percentage: 5,
        },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, name: 'Inactive1', brand: 'X', model: '1', engine_power_hp: 110, status: 'inactive' },
        { tractor_id: 2, name: 'Maintenance', brand: 'Y', model: '2', engine_power_hp: 120, status: 'maintenance' },
        { tractor_id: 3, name: 'Active', brand: 'Z', model: '3', engine_power_hp: 105, status: 'available' },
      ]);

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      const responseData = res.json.mock.calls[0][0].data;
      // total_evaluated = classifiedTractors.length (only 'available' status)
      expect(responseData.tractorAnalysis.total_evaluated).toBe(1);
      expect(responseData.tractorAnalysis.summary.optimal).toBe(1);
      expect(responseData.recommendations.top_5.length).toBe(1);
      expect(responseData.recommendations.top_5[0]).toEqual(
        expect.objectContaining({ tractor_id: 3, name: 'Active' }),
      );
    });

    test('hace rollback cuando falla la persistencia con usuario autenticado', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          soil_type: 'loam',
          slope_percentage: 5,
        },
        user: { user_id: 10 },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 10, name: 'Optimo', brand: 'JD', model: 'A', engine_power_hp: 110, status: 'available' },
      ]);
      mockClient.query
        .mockResolvedValueOnce({})
        .mockRejectedValueOnce(new Error('insert failed'))
        .mockResolvedValueOnce({});

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({ queryId: null }),
        }),
      );
      expect(mockClient.release).toHaveBeenCalled();
    });

    test('clasifica tractores correctamente: INSUFFICIENT, OPTIMAL, OVERPOWERED', async () => {
      const req = {
        body: {
          power_requirement_hp: 80,
          soil_type: 'loam',
          slope_percentage: 5,
        },
      };
      const res = createMockRes();

      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { soilFactor: 1.0 },
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, name: 'Weak', brand: 'A', model: '1', engine_power_hp: 80, status: 'available' },
        { tractor_id: 2, name: 'Perfect', brand: 'B', model: '2', engine_power_hp: 100, status: 'available' },
        { tractor_id: 3, name: 'Good', brand: 'C', model: '3', engine_power_hp: 120, status: 'available' },
        { tractor_id: 4, name: 'Big', brand: 'D', model: '4', engine_power_hp: 200, status: 'available' },
      ]);

      await callWrappedHandler(calculateDirectMinimumPower, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      const responseData = res.json.mock.calls[0][0].data;
      expect(responseData.tractorAnalysis.summary).toEqual({
        optimal: 2,
        overpowered: 1,
        insufficient: 1,
      });
      expect(responseData.recommendations.top_5[0]).toEqual(
        expect.objectContaining({ tractor_id: 2, rank: 1 }),
      );
      expect(responseData.recommendations.top_5[1]).toEqual(
        expect.objectContaining({ tractor_id: 3, rank: 2 }),
      );
      expect(responseData.recommendations.top_5[2]).toEqual(
        expect.objectContaining({ tractor_id: 4, rank: 3 }),
      );
    });
  });

  describe('getCalculationHistory()', () => {
    test('retorna 400 con parámetros de paginación inválidos', async () => {
      const req = {
        user: { user_id: 9 },
        query: { page: '0', limit: '101' },
      };
      const res = createMockRes();

      await getCalculationHistory(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Parámetros de paginación inválidos (page >= 1, 1 <= limit <= 100)',
      });
    });

    test('retorna historial con filtro de tipo semántico y metadatos de paginación', async () => {
      const req = {
        user: { user_id: 50 },
        query: { page: '2', limit: '2', type: 'requirement' },
      };
      const res = createMockRes();

      mockPoolQuery.mockImplementation((sql, params) => {
        if (sql.includes('COUNT(*) as total')) {
          expect(params).toEqual([50, 'minimum_power']);
          return Promise.resolve({ rows: [{ total: '3' }] });
        }

        expect(sql).toContain('q.query_type = $2');
        expect(params).toEqual([50, 'minimum_power', 2, 2]);
        return Promise.resolve({
          rows: [
            {
              history_id: 1,
              query_id: 90,
              action_date: '2026-03-20',
              action_type: 'minimum_power_calculation',
              description: 'Cálculo',
              result_json: { minimumPowerHP: 100 },
              query_type: 'minimum_power',
              query_date: '2026-03-20',
              status: 'completed',
              tractor_name: 'Optimo',
              tractor_brand: 'JD',
              tractor_model: 'A',
              terrain_name: 'Plano',
              implement_name: 'Sembradora',
              implement_type: 'seeder',
            },
          ],
        });
      });

      await getCalculationHistory(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Historial de cálculos recuperado con éxito',
        data: {
          history: [
            {
              history_id: 1,
              query_id: 90,
              action_date: '2026-03-20',
              action_type: 'minimum_power_calculation',
              description: 'Cálculo',
              query_type: 'minimum_power',
              query_date: '2026-03-20',
              status: 'completed',
              entities: {
                tractor: {
                  name: 'Optimo',
                  brand: 'JD',
                  model: 'A',
                },
                terrain: {
                  name: 'Plano',
                },
                implement: {
                  name: 'Sembradora',
                  type: 'seeder',
                },
              },
              result_summary: { minimumPowerHP: 100 },
            },
          ],
          pagination: {
            current_page: 2,
            records_per_page: 2,
            total_records: 3,
            total_pages: 2,
            has_next_page: false,
            has_previous_page: true,
          },
          filters: {
            user_id: 50,
            type: 'requirement',
          },
        },
      });
    });

    test('retorna 500 cuando falla la consulta de historial', async () => {
      const req = {
        user: { user_id: 50 },
        query: {},
      };
      const res = createMockRes();
      mockPoolQuery.mockRejectedValueOnce(new Error('history failed'));

      await getCalculationHistory(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error al recuperar el historial de cálculos',
        error: undefined,
      });
    });
  });

  describe('calculateDirectImplementPower()', () => {
    // rastra_pesada_26: T = 1000 kgf/m (arcilla) → P = 1000 × 3 × 7.5 × 0.00365 = 82.13 HP
    const directBody = {
      implement_type: 'rastra_pesada_26',
      working_width_m: 3,
      working_speed_kmh: 7.5,
      soil_type: 'arcilla',
    };

    test('sin engine_power_hp retorna solo la potencia requerida (sin margen ni clasificación)', async () => {
      const req = { body: { ...directBody } };
      const res = createMockRes();

      await callWrappedHandler(calculateDirectImplementPower, req, res);

      expect(mockCalculateTotalLossWithZoz).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(200);
      // data con exactly estas claves: sin margin_hp/available_power_hp/classification
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: expect.stringContaining('potencia por implemento'),
          data: {
            power_required_hp: 82.13,
            power_kind: 'drawbar',
            detail: expect.objectContaining({
              family: 'draft_per_meter',
              working_speed_kmh: 7.5,
            }),
            warnings: [],
          },
        }),
      );
    });

    test('con engine_power_hp compara contra la potencia disponible y clasifica', async () => {
      const req = {
        body: {
          ...directBody,
          engine_power_hp: 100,
          traction_type: '4x2',
          soil_condition: 'bueno',
          has_turbo: true,
        },
      };
      const res = createMockRes();

      // Tractor turbo de 100 HP, 2WD, suelo bueno: net = 100 × (1 − 0.215 − 0.25) = 53.5 HP
      mockCalculateTotalLossWithZoz.mockReturnValue({
        grossPower: 100,
        hasTurbo: true,
        losses: {
          altitude: 0,
          temperature: 0,
          transmission: 46.5,
          rollingResistance: 0,
          slope: 0,
          slippage: 0,
          total: 46.5,
        },
        netPower: 53.5,
        efficiency: 53.5,
        zoz: {
          soil_condition: 'bueno',
          tractor_type: '2WD',
          axle_loss: 0.25,
          fixed_drivetrain_loss: 0.215,
          combined_drivetrain_loss: 46.5,
          pto_efficiency: 0.72,
          pto_power_hp: 72,
          slippage_absorbed: true,
        },
      });

      await callWrappedHandler(calculateDirectImplementPower, req, res);

      expect(mockCalculateTotalLossWithZoz).toHaveBeenCalledWith(
        expect.objectContaining({
          enginePower: 100,
          tractorTractionType: '4x2',
          soilCondition: 'bueno',
        }),
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            power_required_hp: 82.13,
            available_power_hp: 53.5,
            margin_hp: -28.63,
            is_adequate: false,
            classification: 'NO_ADECUADO',
          }),
        }),
      );
    });
  });

  describe('calculateDirectPowerLoss()', () => {
    const legacyBody = {
      engine_power_hp: 100,
      weight_kg: 5000,
      soil_type: 'loam',
      altitude_m: 0,
      ambient_temperature_c: 15,
      slope_percent: 0,
      slippage_percent: 10,
    };

    test('sin soil_condition usa la ruta legacy (calculateTotalLoss) y no incluye zoz', async () => {
      const req = { body: { ...legacyBody } };
      const res = createMockRes();

      mockCalculateTotalLoss.mockReturnValue({
        grossPower: 100,
        hasTurbo: false,
        losses: {
          altitude: 0,
          temperature: 0,
          transmission: 13,
          rollingResistance: 2,
          slope: 0,
          slippage: 5.4,
          total: 20.4,
        },
        netPower: 79.6,
        efficiency: 79.6,
      });

      await callWrappedHandler(calculateDirectPowerLoss, req, res);

      expect(mockCalculateTotalLoss).toHaveBeenCalledTimes(1);
      expect(mockCalculateTotalLossWithZoz).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(200);
      const payload = res.json.mock.calls[0][0];
      expect(payload.success).toBe(true);
      expect(payload.data.net_power_hp).toBe(79.6);
      expect(payload.data).not.toHaveProperty('zoz');
    });

    test('con soil_condition usa la corrección Zoz & Grisso e incluye el detalle zoz', async () => {
      const req = {
        body: {
          ...legacyBody,
          soil_condition: 'bueno',
          traction_type: '4x2',
          has_turbo: true,
        },
      };
      const res = createMockRes();

      mockCalculateTotalLossWithZoz.mockReturnValue({
        grossPower: 100,
        hasTurbo: true,
        losses: {
          altitude: 0,
          temperature: 0,
          transmission: 46.5,
          rollingResistance: 2,
          slope: 0,
          slippage: 0,
          total: 48.5,
        },
        netPower: 51.5,
        efficiency: 51.5,
        zoz: {
          soil_condition: 'bueno',
          tractor_type: '2WD',
          tractor_type_defaulted: false,
          warnings: [],
          axle_loss: 0.25,
          fixed_drivetrain_loss: 0.215,
          combined_drivetrain_loss: 46.5,
          pto_efficiency: 0.72,
          pto_power_hp: 72,
          slippage_absorbed: true,
        },
      });

      await callWrappedHandler(calculateDirectPowerLoss, req, res);

      expect(mockCalculateTotalLossWithZoz).toHaveBeenCalledWith(
        expect.objectContaining({
          enginePower: 100,
          totalWeightKg: 5000,
          tractorTractionType: '4x2',
          soilCondition: 'bueno',
        }),
      );
      expect(mockCalculateTotalLoss).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(200);
      const payload = res.json.mock.calls[0][0];
      expect(payload.success).toBe(true);
      expect(payload.data).toEqual(
        expect.objectContaining({
          net_power_hp: 51.5,
          losses: expect.objectContaining({ total_loss_hp: 48.5 }),
          zoz: expect.objectContaining({ tractor_type: '2WD', axle_loss: 0.25 }),
        }),
      );
    });
  });
});
