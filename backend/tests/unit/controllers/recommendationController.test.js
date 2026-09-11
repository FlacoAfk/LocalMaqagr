import { jest, describe, test, expect, beforeEach } from "@jest/globals";

// ==================== DECLARACIÓN DE MOCKS ====================

const mockFindById = jest.fn();
jest.unstable_mockModule("../../../src/models/Implement.js", () => ({
  default: { findById: mockFindById },
  __esModule: true,
}));

const mockFindTerrain = jest.fn();
jest.unstable_mockModule("../../../src/models/Terrain.js", () => ({
  default: { findByIdAndUser: mockFindTerrain },
  __esModule: true,
}));

const mockGetAll = jest.fn();
jest.unstable_mockModule("../../../src/models/Tractor.js", () => ({
  default: { getAll: mockGetAll },
  __esModule: true,
}));

const mockClient = {
  query: jest.fn().mockResolvedValue({ rows: [{ query_id: 100 }] }),
  release: jest.fn(),
};
const mockConnect = jest.fn().mockResolvedValue(mockClient);
const mockQuery = jest.fn();

jest.unstable_mockModule("../../../src/config/db.js", () => ({
  pool: { connect: mockConnect, query: mockQuery },
  __esModule: true,
}));

const mockGenerateAdvancedRec = jest.fn();
jest.unstable_mockModule(
  "../../../src/services/recommendationService.js",
  () => ({
    generateAdvancedRecommendation: mockGenerateAdvancedRec,
    generateRecommendation: jest.fn(),
    analyzeTerrain: jest.fn().mockReturnValue({ slopeClass: "FLAT" }),
    __esModule: true,
  }),
);

jest.unstable_mockModule("../../../src/config/logger.js", () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  default: {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  },
  __esModule: true,
}));

// ==================== IMPORT DEL CONTROLLER ====================

const controller =
  await import("../../../src/controllers/recommendationController.js");
const { generateAdvancedRecommendation } = controller;

// ==================== HELPERS ====================
const callHandler = async (handler, req, res, next = jest.fn()) => {
  handler(req, res, next);
  await new Promise((resolve) => setImmediate(resolve));
};

describe("recommendationController", () => {
  let req, res;

  beforeEach(() => {
    jest.clearAllMocks();

    req = {
      body: {},
      user: { user_id: 1 },
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    mockConnect.mockResolvedValue(mockClient);
    mockClient.query.mockResolvedValue({ rows: [{ query_id: 100 }] });

    mockFindTerrain.mockResolvedValue({
      terrain_id: 1,
      user_id: 1,
      status: "active",
      soil_type: "loam",
      slope_percentage: 5,
      name: "Field 1",
    });

    mockFindById.mockResolvedValue({
      implement_id: 1,
      implement_name: "Plow",
      power_requirement_hp: 80,
      working_depth_cm: 25,
    });

    mockGetAll.mockResolvedValue([
      {
        tractor_id: 1,
        name: "Tractor A",
        brand: "BrandX",
        status: "available",
        engine_power_hp: 100,
        price_usd: 50000,
      },
      {
        tractor_id: 2,
        name: "Tractor B",
        brand: "BrandY",
        status: "available",
        engine_power_hp: 120,
        price_usd: 80000,
      },
    ]);

    mockQuery.mockImplementation((query) => {
      if (query.includes("FROM terrain")) {
        return Promise.resolve({
          rows: [
            {
              terrain_id: 1,
              user_id: 1,
              soil_type: "loam",
              slope_percentage: 5,
              name: "Field 1",
            },
          ],
        });
      }
      return Promise.resolve({ rows: [] });
    });

    mockGenerateAdvancedRec.mockReturnValue({
      success: true,
      recommendations: [
        {
          rank: 1,
          tractor: { id: 1, name: "Tractor A", engine_power_hp: 100 },
          score: {
            total: 85,
            breakdown: {
              power_match: 40,
              price: 30,
              brand_preference: 10,
              fuel_efficiency: 5,
            },
          },
          compatibility: { surplusHP: 20 },
          classification: { label: "OPTIMAL" },
          explanation: ["Explicacion"],
        },
      ],
      terrainAnalysis: { classification: { slopeClass: "FLAT" } },
      summary: { compatibleCount: 1 },
    });
  });

  describe("generateAdvancedRecommendation", () => {
    test("retorna 401 si el usuario no está autenticado", async () => {
      req.user = null;
      req.body = { terrain_id: 1, implement_id: 1 };

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: "Usuario no autenticado",
        }),
      );
    });

    test("retorna 400 si faltan campos requeridos", async () => {
      req.body = { terrain_id: 1 };

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: expect.stringContaining("Campos requeridos"),
        }),
      );
    });

    test("retorna 404 si el terreno no es accesible", async () => {
      req.body = { terrain_id: 1, implement_id: 1 };
      mockFindTerrain.mockResolvedValue(null);

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: "Terreno no encontrado o no accesible",
        }),
      );
    });

    test("retorna 404 si el implemento no existe", async () => {
      req.body = { terrain_id: 1, implement_id: 1 };
      mockFindById.mockResolvedValue(null);

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: "Implemento no encontrado",
        }),
      );
    });

    test("retorna 404 si no hay tractores disponibles", async () => {
      req.body = { terrain_id: 1, implement_id: 1 };
      mockGetAll.mockResolvedValue([{ tractor_id: 10, status: "maintenance" }]);

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: "No hay tractores disponibles en el sistema",
        }),
      );
    });

    test("llama a generateAdvancedRec en el servicio con los filtros y customWeights", async () => {
      req.body = {
        terrain_id: 1,
        implement_id: 1,
        filters: { budget: 60000, brandPreference: "BrandX" },
        customWeights: {
          power_match: 10,
          price: 80,
          brand_preference: 5,
          fuel_efficiency: 5,
        },
      };

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: expect.stringContaining("exitosamente"),
        }),
      );

      expect(mockGenerateAdvancedRec).toHaveBeenCalledWith(
        expect.objectContaining({
          filters: { budget: 60000, brandPreference: "BrandX" },
          customWeights: {
            power_match: 10,
            price: 80,
            brand_preference: 5,
            fuel_efficiency: 5,
          },
        }),
      );
    });

    test("retorna 200 sin recomendaciones compatibles cuando el servicio no encuentra matches", async () => {
      req.body = { terrain_id: 1, implement_id: 1 };
      mockGenerateAdvancedRec.mockReturnValue({
        success: false,
        recommendations: [],
        terrainAnalysis: { classification: { slopeClass: "FLAT" } },
        summary: { compatibleCount: 0 },
      });

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: "Cálculo realizado pero sin tractores compatibles",
          data: expect.objectContaining({
            queryId: null,
            recommendations: [],
          }),
        }),
      );
    });

    test("guarda la recomendacion de forma transaccional", async () => {
      req.body = { terrain_id: 1, implement_id: 1 };

      await callHandler(generateAdvancedRecommendation, req, res);

      expect(mockClient.query).toHaveBeenCalledWith("BEGIN");
      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining("INSERT INTO query"),
        expect.any(Array),
      );
      expect(mockClient.query).toHaveBeenCalledWith("COMMIT");
    });

    test("hace rollback cuando falla la persistencia", async () => {
      const next = jest.fn();
      req.body = { terrain_id: 1, implement_id: 1 };

      mockClient.query
        .mockResolvedValueOnce({})
        .mockRejectedValueOnce(new Error("insert failed"))
        .mockResolvedValueOnce({});

      await callHandler(generateAdvancedRecommendation, req, res, next);

      expect(mockClient.query).toHaveBeenCalledWith("ROLLBACK");
      expect(next).toHaveBeenCalled();
      expect(next.mock.calls[0][0]).toBeInstanceOf(Error);
    });
  });
});
