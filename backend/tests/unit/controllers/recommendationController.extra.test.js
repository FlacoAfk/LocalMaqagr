import { beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockFindTerrainByUser = jest.fn();
const mockImplementFindById = jest.fn();
const mockTractorGetAll = jest.fn();
const mockRecommendationFindById = jest.fn();
const mockGenerateRecommendation = jest.fn();
const mockGenerateAdvancedRecommendation = jest.fn();
const mockAnalyzeTerrain = jest.fn();
const mockCalculateMinimumPower = jest.fn();
const mockNotifyRecommendationCreated = jest.fn();
const mockConnect = jest.fn();
const mockPoolQuery = jest.fn();

const mockClient = {
  query: jest.fn(),
  release: jest.fn(),
};

jest.unstable_mockModule('../../../src/models/Terrain.js', () => ({
  __esModule: true,
  default: {
    findByIdAndUser: mockFindTerrainByUser,
  },
}));

jest.unstable_mockModule('../../../src/models/Implement.js', () => ({
  __esModule: true,
  default: {
    findById: mockImplementFindById,
  },
}));

jest.unstable_mockModule('../../../src/models/Tractor.js', () => ({
  __esModule: true,
  default: {
    getAll: mockTractorGetAll,
  },
}));

jest.unstable_mockModule('../../../src/models/Recommendation.js', () => ({
  __esModule: true,
  default: {
    findById: mockRecommendationFindById,
  },
}));

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  __esModule: true,
  pool: {
    connect: mockConnect,
    query: mockPoolQuery,
  },
}));

jest.unstable_mockModule('../../../src/services/minimumPowerService.js', () => ({
  __esModule: true,
  calculateMinimumPower: mockCalculateMinimumPower,
}));

jest.unstable_mockModule('../../../src/services/notificationService.js', () => ({
  __esModule: true,
  notifyRecommendationCreated: mockNotifyRecommendationCreated,
}));

jest.unstable_mockModule('../../../src/services/recommendationService.js', () => ({
  __esModule: true,
  generateRecommendation: mockGenerateRecommendation,
  generateAdvancedRecommendation: mockGenerateAdvancedRecommendation,
  analyzeTerrain: mockAnalyzeTerrain,
}));

const controller = await import('../../../src/controllers/recommendationController.js');
const {
  generateRecommendation,
  getRecommendationHistory,
  getRecommendationById,
} = controller;

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const callHandler = async (handler, req, res, next = jest.fn()) => {
  handler(req, res, next);
  await new Promise((resolve) => setImmediate(resolve));
  return next;
};

describe('recommendationController extra coverage', () => {
  beforeEach(() => {
    [
      mockFindTerrainByUser,
      mockImplementFindById,
      mockTractorGetAll,
      mockRecommendationFindById,
      mockGenerateRecommendation,
      mockGenerateAdvancedRecommendation,
      mockAnalyzeTerrain,
      mockCalculateMinimumPower,
      mockNotifyRecommendationCreated,
      mockConnect,
      mockPoolQuery,
      mockClient.query,
      mockClient.release,
    ].forEach((mockFn) => mockFn.mockReset());

    mockConnect.mockResolvedValue(mockClient);
    mockNotifyRecommendationCreated.mockResolvedValue(null);
  });

  describe('generateRecommendation()', () => {
    test('retorna 401 si el usuario no está autenticado', async () => {
      const req = {
        body: { terrain_id: 1, implement_id: 2 },
      };
      const res = createMockRes();

      await callHandler(generateRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Usuario no autenticado',
      });
    });

    test('retorna 404 si el terreno no es accesible para el usuario', async () => {
      const req = {
        body: { terrain_id: 1, implement_id: 2 },
        user: { user_id: 9 },
      };
      const res = createMockRes();
      mockFindTerrainByUser.mockResolvedValue(null);

      await callHandler(generateRecommendation, req, res);

      expect(mockFindTerrainByUser).toHaveBeenCalledWith(1, 9);
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Terreno no encontrado o no accesible',
      });
    });

    test('retorna 404 si no hay tractores disponibles', async () => {
      const req = {
        body: { terrain_id: 1, implement_id: 2 },
        user: { user_id: 9 },
      };
      const res = createMockRes();

      mockFindTerrainByUser.mockResolvedValue({
        terrain_id: 1,
        status: 'active',
        soil_type: 'loam',
        slope_percentage: 5,
        name: 'Lote',
      });
      mockImplementFindById.mockResolvedValue({
        implement_id: 2,
        implement_name: 'Arado',
        implement_type: 'plow',
        brand: 'Agro',
        power_requirement_hp: 80,
        working_depth_cm: 25,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 5, status: 'maintenance', engine_power_hp: 120 },
      ]);

      await callHandler(generateRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'No hay tractores disponibles en el sistema',
      });
    });

    test('retorna cálculo sin compatibles cuando el filtro final elimina recomendaciones insuficientes', async () => {
      const req = {
        body: { terrain_id: 1, implement_id: 2 },
        user: { user_id: 9 },
      };
      const res = createMockRes();

      mockFindTerrainByUser.mockResolvedValue({
        terrain_id: 1,
        status: 'active',
        soil_type: 'loam',
        slope_percentage: 5,
        name: 'Lote',
      });
      mockImplementFindById.mockResolvedValue({
        implement_id: 2,
        implement_name: 'Arado',
        implement_type: 'plow',
        brand: 'Agro',
        power_requirement_hp: 80,
        working_depth_cm: 25,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 5, status: 'available', engine_power_hp: 95, brand: 'Case' },
      ]);
      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 90,
        factors: { slopeFactor: 1.1 },
      });
      mockGenerateRecommendation.mockReturnValue({
        success: true,
        recommendations: [
          {
            rank: 1,
            tractor: {
              tractor_id: 5,
              name: 'Insuficiente',
              brand: 'Case',
              model: 'X',
              engine_power_hp: 95,
            },
            score: { total: 70, breakdown: { efficiency: 20 } },
            compatibility: { utilizationPercent: 95 },
            classification: { label: 'GOOD' },
          },
        ],
        terrainAnalysis: { classification: { slopeClass: 'FLAT' } },
        summary: { compatibleCount: 1, reason: 'none' },
      });

      await callHandler(generateRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Cálculo realizado pero sin tractores compatibles',
          data: expect.objectContaining({
            queryId: null,
            recommendations: [],
          }),
        }),
      );
      expect(mockClient.query).not.toHaveBeenCalledWith('BEGIN');
    });

    test('persiste recomendaciones estándar y emite notificación asíncrona', async () => {
      const req = {
        body: {
          terrain_id: 2,
          implement_id: 3,
          work_type: 'tillage',
        },
        user: { user_id: 21 },
      };
      const res = createMockRes();

      mockFindTerrainByUser.mockResolvedValue({
        terrain_id: 2,
        status: 'active',
        soil_type: 'loam',
        slope_percentage: 6,
        name: 'Lote Centro',
      });
      mockImplementFindById.mockResolvedValue({
        implement_id: 3,
        implement_name: 'Subsolador',
        implement_type: 'plow',
        brand: 'Agro',
        power_requirement_hp: 80,
        working_depth_cm: 25,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, status: 'available', engine_power_hp: 110, brand: 'JD', model: 'A' },
        { tractor_id: 2, status: 'active', engine_power_hp: 150, brand: 'Case', model: 'B' },
      ]);
      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: { slopeFactor: 1.1 },
      });
      mockGenerateRecommendation.mockReturnValue({
        success: true,
        recommendations: [
          {
            rank: 1,
            tractor: {
              tractor_id: 1,
              name: '6130M',
              brand: 'JD',
              model: 'A',
              engine_power_hp: 110,
              traction_type: '4x4',
              weight_kg: 5000,
            },
            score: { total: 91, breakdown: { efficiency: 40, traction: 20 } },
            compatibility: { utilizationPercent: 91 },
            classification: { label: 'OPTIMAL' },
          },
          {
            rank: 2,
            tractor: {
              tractor_id: 2,
              name: 'Puma',
              brand: 'Case',
              model: 'B',
              engine_power_hp: 150,
              traction_type: '4x4',
              weight_kg: 6500,
            },
            score: { total: 80, breakdown: { traction: 30, efficiency: 15 } },
            compatibility: { utilizationPercent: 67 },
            classification: { label: 'GOOD' },
          },
        ],
        terrainAnalysis: { classification: { slopeClass: 'ROLLING' } },
        summary: { compatibleCount: 2 },
      });
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rows: [{ query_id: 55 }] })
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({});

      await callHandler(generateRecommendation, req, res);

      expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      expect(mockNotifyRecommendationCreated).toHaveBeenCalledWith(21, 55);
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            queryId: 55,
            recommendations: [
              expect.objectContaining({
                rank: 1,
                explanation: expect.stringContaining('Alta eficiencia energética'),
              }),
              expect.objectContaining({
                rank: 2,
                explanation: expect.stringContaining('Tracción óptima'),
              }),
            ],
            summary: expect.objectContaining({
              persistedCount: 2,
              bestMatch: expect.objectContaining({
                score: 91,
              }),
            }),
          }),
        }),
      );
    });

    test('hace rollback y pasa el error a next cuando la persistencia falla', async () => {
      const req = {
        body: {
          terrain_id: 2,
          implement_id: 3,
        },
        user: { user_id: 21 },
      };
      const res = createMockRes();
      const next = jest.fn();
      const dbError = new Error('insert failed');

      mockFindTerrainByUser.mockResolvedValue({
        terrain_id: 2,
        status: 'active',
        soil_type: 'loam',
        slope_percentage: 6,
        name: 'Lote Centro',
      });
      mockImplementFindById.mockResolvedValue({
        implement_id: 3,
        implement_name: 'Subsolador',
        implement_type: 'plow',
        brand: 'Agro',
        power_requirement_hp: 80,
        working_depth_cm: 25,
      });
      mockTractorGetAll.mockResolvedValue([
        { tractor_id: 1, status: 'available', engine_power_hp: 110, brand: 'JD', model: 'A' },
      ]);
      mockCalculateMinimumPower.mockReturnValue({
        minimumPowerHP: 100,
        calculatedPowerHP: 87,
        factors: {},
      });
      mockGenerateRecommendation.mockReturnValue({
        success: true,
        recommendations: [
          {
            rank: 1,
            tractor: {
              tractor_id: 1,
              name: '6130M',
              brand: 'JD',
              model: 'A',
              engine_power_hp: 110,
              traction_type: '4x4',
              weight_kg: 5000,
            },
            score: { total: 91, breakdown: { efficiency: 40 } },
            compatibility: { utilizationPercent: 91 },
            classification: { label: 'OPTIMAL' },
          },
        ],
        terrainAnalysis: { classification: { slopeClass: 'ROLLING' } },
        summary: { compatibleCount: 1 },
      });
      mockClient.query
        .mockResolvedValueOnce({})
        .mockRejectedValueOnce(dbError)
        .mockResolvedValueOnce({});

      await callHandler(generateRecommendation, req, res, next);

      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(next).toHaveBeenCalledWith(dbError);
    });
  });

  describe('getRecommendationHistory()', () => {
    test('retorna 401 si no hay usuario autenticado', async () => {
      const req = { query: {} };
      const res = createMockRes();

      await callHandler(getRecommendationHistory, req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Usuario no autenticado',
      });
    });

    test('retorna historial paginado y parsea observations JSON o texto libre', async () => {
      const req = {
        user: { user_id: 5 },
        query: { page: '2', limit: '2', work_type: 'siembra' },
      };
      const res = createMockRes();

      mockPoolQuery.mockImplementation((sql, params) => {
        if (sql.includes('COUNT(*) as total')) {
          expect(params).toEqual([5, '%siembra%']);
          return Promise.resolve({ rows: [{ total: '3' }] });
        }

        expect(sql).toContain('LOWER(r.work_type) LIKE LOWER($2)');
        expect(params).toEqual([5, '%siembra%', 2, 2]);
        return Promise.resolve({
          rows: [
            {
              recommendation_id: 1,
              compatibility_score: 90,
              observations: JSON.stringify({ note: 'ok' }),
              work_type: 'siembra',
              recommendation_date: '2026-03-20',
              terrain_id: 10,
              terrain_name: 'Lote A',
              soil_type: 'loam',
              slope_percentage: 4,
              tractor_id: 20,
              tractor_name: '6130M',
              tractor_brand: 'JD',
              tractor_model: 'A',
              engine_power_hp: 120,
              implement_id: 30,
              implement_name: 'Sembradora',
              implement_type: 'seeder',
            },
            {
              recommendation_id: 2,
              compatibility_score: 70,
              observations: 'texto libre',
              work_type: 'siembra',
              recommendation_date: '2026-03-18',
              terrain_id: 11,
              terrain_name: 'Lote B',
              soil_type: 'clay',
              slope_percentage: 7,
              tractor_id: 21,
              tractor_name: 'Puma',
              tractor_brand: 'Case',
              tractor_model: 'B',
              engine_power_hp: 150,
              implement_id: 31,
              implement_name: 'Arado',
              implement_type: 'plow',
            },
          ],
        });
      });

      await callHandler(getRecommendationHistory, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: {
          recommendations: [
            {
              id: 1,
              score: 90,
              work_type: 'siembra',
              date: '2026-03-20',
              terrain: {
                id: 10,
                name: 'Lote A',
                soil_type: 'loam',
                slope_percentage: 4,
              },
              tractor: {
                id: 20,
                name: '6130M',
                brand: 'JD',
                model: 'A',
                engine_power_hp: 120,
              },
              implement: {
                id: 30,
                name: 'Sembradora',
                type: 'seeder',
              },
              details: { note: 'ok' },
            },
            {
              id: 2,
              score: 70,
              work_type: 'siembra',
              date: '2026-03-18',
              terrain: {
                id: 11,
                name: 'Lote B',
                soil_type: 'clay',
                slope_percentage: 7,
              },
              tractor: {
                id: 21,
                name: 'Puma',
                brand: 'Case',
                model: 'B',
                engine_power_hp: 150,
              },
              implement: {
                id: 31,
                name: 'Arado',
                type: 'plow',
              },
              details: { raw: 'texto libre' },
            },
          ],
          pagination: {
            currentPage: 2,
            totalPages: 2,
            totalItems: 3,
            itemsPerPage: 2,
            hasNextPage: false,
            hasPrevPage: true,
          },
        },
      });
    });

    test('retorna 500 si falla la consulta del historial', async () => {
      const req = {
        user: { user_id: 5 },
        query: {},
      };
      const res = createMockRes();
      mockPoolQuery.mockRejectedValueOnce(new Error('history failed'));

      await callHandler(getRecommendationHistory, req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error obteniendo historial de recomendaciones',
        error: undefined,
      });
    });

    test('en development incluye error.message cuando falla el historial', async () => {
      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const req = {
        user: { user_id: 5 },
        query: {},
      };
      const res = createMockRes();
      mockPoolQuery.mockRejectedValueOnce(new Error('history failed dev'));

      await callHandler(getRecommendationHistory, req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error obteniendo historial de recomendaciones',
        error: 'history failed dev',
      });

      process.env.NODE_ENV = prevEnv;
    });
  });

  describe('getRecommendationById()', () => {
    test('valida autenticación e id válido', async () => {
      let req = { params: { id: '1' } };
      let res = createMockRes();
      await callHandler(getRecommendationById, req, res);
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Usuario no autenticado',
      });

      req = { user: { user_id: 8 }, params: { id: 'abc' } };
      res = createMockRes();
      await callHandler(getRecommendationById, req, res);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'ID de recomendación inválido',
      });
    });

    test('retorna 404 o 403 según existencia y ownership', async () => {
      let req = { user: { user_id: 8 }, params: { id: '99' } };
      let res = createMockRes();
      mockRecommendationFindById.mockResolvedValueOnce(null);
      await callHandler(getRecommendationById, req, res);
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Recomendación no encontrada',
      });

      req = { user: { user_id: 8 }, params: { id: '99' } };
      res = createMockRes();
      mockRecommendationFindById.mockResolvedValueOnce({
        recommendation_id: 99,
        user_id: 55,
      });
      await callHandler(getRecommendationById, req, res);
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'No tiene acceso a esta recomendación',
      });
    });

    test('retorna detalle parseado cuando la recomendación es del usuario', async () => {
      const req = { user: { user_id: 8 }, params: { id: '10' } };
      const res = createMockRes();
      mockRecommendationFindById.mockResolvedValueOnce({
        recommendation_id: 10,
        user_id: 8,
        compatibility_score: 88,
        work_type: 'general',
        recommendation_date: '2026-03-21',
        terrain_id: 5,
        terrain_name: 'Lote',
        soil_type: 'loam',
        slope_percentage: 4,
        tractor_id: 9,
        tractor_name: '6130M',
        tractor_brand: 'JD',
        tractor_model: 'A',
        engine_power_hp: 120,
        implement_id: 12,
        implement_name: 'Sembradora',
        implement_type: 'seeder',
        power_requirement_hp: 80,
        observations: JSON.stringify({ explanation: 'Buen match' }),
      });

      await callHandler(getRecommendationById, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: {
          id: 10,
          score: 88,
          work_type: 'general',
          date: '2026-03-21',
          terrain: {
            id: 5,
            name: 'Lote',
            soil_type: 'loam',
            slope_percentage: 4,
          },
          tractor: {
            id: 9,
            name: '6130M',
            brand: 'JD',
            model: 'A',
            engine_power_hp: 120,
          },
          implement: {
            id: 12,
            name: 'Sembradora',
            type: 'seeder',
            power_requirement_hp: 80,
          },
          details: {
            explanation: 'Buen match',
          },
        },
      });
    });

    test('retorna 500 cuando ocurre un error inesperado', async () => {
      const req = { user: { user_id: 8 }, params: { id: '10' } };
      const res = createMockRes();
      mockRecommendationFindById.mockRejectedValueOnce(new Error('detail failed'));

      await callHandler(getRecommendationById, req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error obteniendo recomendación',
        error: undefined,
      });
    });

    test('en development incluye error.message cuando falla getRecommendationById', async () => {
      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const req = { user: { user_id: 8 }, params: { id: '10' } };
      const res = createMockRes();
      mockRecommendationFindById.mockRejectedValueOnce(new Error('detail failed dev'));

      await callHandler(getRecommendationById, req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Error obteniendo recomendación',
        error: 'detail failed dev',
      });

      process.env.NODE_ENV = prevEnv;
    });
  });
});
