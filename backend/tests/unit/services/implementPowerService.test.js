/**
 * Tests unitarios para implementPowerService
 * Verifica el cálculo de potencia requerida por implemento según la
 * "Tabla 1" de Chaparro (9 implementos, coeficientes por tipo de suelo).
 */

import { jest, describe, test, expect } from "@jest/globals";
import * as implementPowerService from "../../../src/services/implementPowerService.js";

describe("implementPowerService", () => {
  const {
    calculateImplementRequiredPower,
    normalizeSoilType,
    IMPLEMENT_CATALOG,
    IMPLEMENT_TYPES,
    METRIC_HP_FACTOR,
    PLOW_COMBINED_FACTOR,
  } = implementPowerService;

  // ========================================================
  // 1. CONSTANTES
  // ========================================================
  describe("constantes", () => {
    test("METRIC_HP_FACTOR = 0.00365 (≈ 1/274.4)", () => {
      expect(METRIC_HP_FACTOR).toBe(0.00365);
      expect(1 / 274.4).toBeCloseTo(METRIC_HP_FACTOR, 4);
    });

    test("PLOW_COMBINED_FACTOR = 0.365 = 100 × METRIC_HP_FACTOR (ancho en m, profundidad en cm)", () => {
      expect(PLOW_COMBINED_FACTOR).toBe(0.365);
      expect(PLOW_COMBINED_FACTOR).toBeCloseTo(100 * METRIC_HP_FACTOR, 10);
    });

    test("catálogo con los 9 implementos de la Tabla 1", () => {
      expect(IMPLEMENT_TYPES).toHaveLength(9);
      expect(Object.keys(IMPLEMENT_CATALOG)).toEqual([
        "arado_disco_vertedera",
        "subsolador",
        "arado_cincel",
        "implemento_rotativo",
        "rastrillo_simple_discos",
        "rastrillo_pulidor",
        "rastrillo_californiano",
        "rastra_pesada_26",
        "rastra_pesada_24",
      ]);
    });
  });

  // ========================================================
  // 2. NORMALIZACIÓN DE SUELO
  // ========================================================
  describe("normalizeSoilType", () => {
    test("mapea aliases a arena/limo/arcilla", () => {
      expect(normalizeSoilType("arena")).toBe("arena");
      expect(normalizeSoilType("arenoso")).toBe("arena");
      expect(normalizeSoilType("sand")).toBe("arena");
      expect(normalizeSoilType("sandy")).toBe("arena");
      expect(normalizeSoilType("limo")).toBe("limo");
      expect(normalizeSoilType("silt")).toBe("limo");
      expect(normalizeSoilType("arcilla")).toBe("arcilla");
      expect(normalizeSoilType("arcilloso")).toBe("arcilla");
      expect(normalizeSoilType("clay")).toBe("arcilla");
    });

    test("franco/loam se mapea a limo CON advertencia", () => {
      const warnings = [];
      const soil = normalizeSoilType("franco", warnings);
      expect(soil).toBe("limo");
      expect(warnings).toContain("franco/loam mapeado a limo (la Tabla 1 no tiene franco)");
    });
  });

  // ========================================================
  // 3. CASOS DE ACEPTACIÓN (Tabla 1 — Chaparro)
  // ========================================================
  describe("calculateImplementRequiredPower - casos de aceptación", () => {
    test("a) rastra_pesada_26, ancho 3, arcilla, velocidad 7.5 → 82.13 HP", () => {
      // T = 1000 kgf/m (arcilla) × 3 m = 3000 kgf
      // P = 3000 × 7.5 × 0.00365 = 82.125 → 82.13
      // (Chaparro reporta 82 usando el divisor exacto 1/274.4; aquí se usa el
      //  factor 0.00365 de la Tabla 1, de ahí el 82.13 vs 82.00)
      const result = calculateImplementRequiredPower({
        implement_type: "rastra_pesada_26",
        working_width_m: 3,
        working_speed_kmh: 7.5,
        soil_type: "arcilla",
      });
      expect(result.power_required_hp).toBe(82.13);
      expect(result.power_kind).toBe("drawbar");
      expect(result.detail.coefficient).toBe(1000);
      expect(result.detail.draft_force_kgf).toBe(3000);
      expect(result.detail.constant_used).toBe("T_RASTRA_PESADA_26");
      expect(result.warnings).toHaveLength(0);
    });

    test("b) arado_disco_vertedera, ancho 3, profundidad 15, velocidad 4, arcilla → 45.99 HP", () => {
      // CL (4 km/h, arcilla) = 0.70 (fila 4 de la tabla, sin interpolación)
      // P = 3 × 15 × 4 × 0.70 × 0.365 = 45.99
      const result = calculateImplementRequiredPower({
        implement_type: "arado_disco_vertedera",
        working_width_m: 3,
        working_depth_cm: 15,
        working_speed_kmh: 4,
        soil_type: "arcilla",
      });
      expect(result.power_required_hp).toBe(45.99);
      expect(result.detail.coefficient).toBe(0.7);
      expect(result.detail.cl_interpolated).toBe(false);
      expect(result.detail.constant_used).toBe("CL_TABLA_ARADO");
      expect(result.power_kind).toBe("drawbar");
    });

    test("c) subsolador, limo, 3 rejillas, profundidad 40, velocidad 5 → 52.56 HP", () => {
      // T = 24 kgf/cm por rejilla (limo)
      // P = 24 × 3 × 40 × 5 × 0.00365 = 52.56
      const result = calculateImplementRequiredPower({
        implement_type: "subsolador",
        n_tines: 3,
        working_depth_cm: 40,
        working_speed_kmh: 5,
        soil_type: "limo",
      });
      expect(result.power_required_hp).toBe(52.56);
      expect(result.detail.coefficient).toBe(24);
      expect(result.detail.n_tines).toBe(3);
      expect(result.detail.draft_force_kgf).toBe(2880); // 24 × 3 × 40
      expect(result.detail.constant_used).toBe("T_SUBSOLADOR");
    });

    test("d) arado_cincel, arena, 5 rejillas, profundidad 25, velocidad 6 → 24.64 HP", () => {
      // T = 9 kgf/cm por rejilla (arena)
      // P = 9 × 5 × 25 × 6 × 0.00365 = 24.6375 → 24.64
      const result = calculateImplementRequiredPower({
        implement_type: "arado_cincel",
        n_tines: 5,
        working_depth_cm: 25,
        working_speed_kmh: 6,
        soil_type: "arena",
      });
      expect(result.power_required_hp).toBe(24.64);
      expect(result.detail.coefficient).toBe(9);
      expect(result.detail.constant_used).toBe("T_ARADO_CINCEL");
    });

    test("e) implemento_rotativo, ancho 2, arcilla → 64 HP tdf (power_kind pto)", () => {
      // Factor = 32 HP tdf/m (arcilla) → P_tdf = 32 × 2 = 64
      const result = calculateImplementRequiredPower({
        implement_type: "implemento_rotativo",
        working_width_m: 2,
        soil_type: "arcilla",
      });
      expect(result.power_required_hp).toBe(64);
      expect(result.power_kind).toBe("pto");
      expect(result.detail.coefficient).toBe(32);
      expect(result.detail.constant_used).toBe("FACTOR_IMPLEMENTO_ROTATIVO");
      // Profundidad conceptual fija de 10 cm; sin velocidad
      expect(result.detail.working_depth_cm).toBe(10);
      expect(result.detail.working_speed_kmh).toBeNull();
    });
  });

  // ========================================================
  // 4. INTERPOLACIÓN DE CL Y FUERA DE RANGO
  // ========================================================
  describe("interpolación de CL (arado)", () => {
    test("velocidad 4.5 arena → 0.21 (filas 4 y 5 valen 0.21 en arena)", () => {
      // CL = 0.21 + (0.21 − 0.21) × 0.5 = 0.21
      const result = calculateImplementRequiredPower({
        implement_type: "arado_disco_vertedera",
        working_width_m: 2,
        working_depth_cm: 20,
        working_speed_kmh: 4.5,
        soil_type: "arena",
      });
      expect(result.detail.coefficient).toBe(0.21);
      expect(result.detail.cl_interpolated).toBe(true);
    });

    test("velocidad 7.5 limo → 0.735 (interpolación entre 0.70 y 0.77)", () => {
      // CL = 0.70 + (0.77 − 0.70) × 0.5 = 0.735
      const result = calculateImplementRequiredPower({
        implement_type: "arado_disco_vertedera",
        working_width_m: 2,
        working_depth_cm: 20,
        working_speed_kmh: 7.5,
        soil_type: "limo",
      });
      expect(result.detail.coefficient).toBe(0.735);
      expect(result.detail.cl_interpolated).toBe(true);
    });

    test("velocidad bajo 4: clamp a la fila 4 con advertencia", () => {
      const result = calculateImplementRequiredPower({
        implement_type: "arado_disco_vertedera",
        working_width_m: 2,
        working_depth_cm: 20,
        working_speed_kmh: 3,
        soil_type: "arena",
      });
      expect(result.detail.coefficient).toBe(0.21); // valor de la fila 4
      expect(result.detail.cl_interpolated).toBe(false);
      expect(result.warnings.some((w) => w.includes("4-10 km/h"))).toBe(true);
    });

    test("velocidad sobre 10: clamp a la fila 10 con advertencia", () => {
      const result = calculateImplementRequiredPower({
        implement_type: "arado_disco_vertedera",
        working_width_m: 2,
        working_depth_cm: 20,
        working_speed_kmh: 12,
        soil_type: "arena",
      });
      expect(result.detail.coefficient).toBe(0.29); // valor de la fila 10
      expect(result.warnings.some((w) => w.includes("4-10 km/h"))).toBe(true);
    });
  });

  // ========================================================
  // 5. MAPEO DE SUELO EN EL CÁLCULO
  // ========================================================
  describe("mapeo de suelo en el cálculo", () => {
    test("g) soil 'franco' → usa limo y agrega advertencia", () => {
      const result = calculateImplementRequiredPower({
        implement_type: "rastrillo_simple_discos",
        working_width_m: 2,
        working_speed_kmh: 5,
        soil_type: "franco",
      });
      expect(result.detail.coefficient).toBe(113); // T de limo (no existe franco en Tabla 1)
      expect(result.warnings).toContain("franco/loam mapeado a limo (la Tabla 1 no tiene franco)");
    });

    test("soil en mayúsculas y con espacios se normaliza", () => {
      const result = calculateImplementRequiredPower({
        implement_type: "rastrillo_pulidor",
        working_width_m: 2,
        working_speed_kmh: 5,
        soil_type: "  ARCILLA  ",
      });
      expect(result.detail.coefficient).toBe(450); // T de arcilla
      expect(result.warnings).toHaveLength(0);
    });
  });

  // ========================================================
  // 6. VALIDACIONES
  // ========================================================
  describe("validaciones", () => {
    test("rechaza tipos de implemento no soportados", () => {
      expect(() =>
        calculateImplementRequiredPower({ implement_type: "tractor", soil_type: "limo" })
      ).toThrow(/no soportado/);
    });

    test("exige n_tines (entero 1-20) para familia tined", () => {
      expect(() =>
        calculateImplementRequiredPower({
          implement_type: "subsolador",
          working_depth_cm: 40,
          working_speed_kmh: 5,
          soil_type: "limo",
        })
      ).toThrow(/n_tines/);
      expect(() =>
        calculateImplementRequiredPower({
          implement_type: "subsolador",
          n_tines: 25,
          working_depth_cm: 40,
          working_speed_kmh: 5,
          soil_type: "limo",
        })
      ).toThrow(/n_tines/);
    });

    test("exige working_depth_cm para draft_plow y tined", () => {
      expect(() =>
        calculateImplementRequiredPower({
          implement_type: "arado_cincel",
          n_tines: 5,
          working_speed_kmh: 5,
          soil_type: "limo",
        })
      ).toThrow(/working_depth_cm/);
    });

    test("exige working_speed_kmh para familias drawbar (no para pto)", () => {
      expect(() =>
        calculateImplementRequiredPower({
          implement_type: "rastra_pesada_24",
          working_width_m: 2.8,
          soil_type: "limo",
        })
      ).toThrow(/working_speed_kmh/);
      expect(() =>
        calculateImplementRequiredPower({
          implement_type: "implemento_rotativo",
          working_width_m: 1.5,
          soil_type: "limo",
        })
      ).not.toThrow();
    });
  });

  // ========================================================
  // 7. COBERTURA COMPLETA DE COEFICIENTES (Tabla 1, 9 × 3)
  // ========================================================
  describe("cobertura completa de coeficientes de la Tabla 1 (9 implementos × 3 suelos)", () => {
    const SOILS = ["arena", "limo", "arcilla"];

    // Matriz de coeficientes puros de la Tabla 1 por implemento: [arena, limo, arcilla].
    // Para el arado es la fila de 4 km/h: con V = 1 km/h el servicio ajusta (clamp)
    // al borde inferior del rango 4-10 km/h.
    const COEFICIENTES = {
      arado_disco_vertedera: [0.21, 0.56, 0.7],
      subsolador: [18, 24, 30],
      arado_cincel: [9, 12, 15],
      implemento_rotativo: [16, 24, 32],
      rastrillo_simple_discos: [75, 113, 150],
      rastrillo_pulidor: [150, 300, 450],
      rastrillo_californiano: [350, 475, 600],
      rastra_pesada_26: [800, 900, 1000],
      rastra_pesada_24: [700, 800, 900],
    };

    // Con ancho/profundidad/velocidad = 1 (y 1 rejilla), cada fórmula queda
    // P = coeficiente × factor de la familia (solo 'pto' tiene factor 1,
    // por lo que ahí la potencia es exactamente el coeficiente):
    const FACTOR_POR_FAMILIA = {
      draft_plow: 0.365, // P = ancho × prof × V × CL × 0.365
      tined: 0.00365, // P = T × rejillas × prof × V × 0.00365
      pto: 1, // P = factor × ancho (sin velocidad)
      draft_per_meter: 0.00365, // P = T × ancho × V × 0.00365
    };

    const round2 = (value) => Math.round(value * 100) / 100;

    test.each(
      Object.entries(COEFICIENTES).flatMap(([implement_type, coeficientes]) =>
        SOILS.map((soil_type, i) => [implement_type, soil_type, coeficientes[i]]),
      ),
    )("%s en %s → coeficiente puro %s", (implement_type, soil_type, coeficienteEsperado) => {
      const result = calculateImplementRequiredPower({
        implement_type,
        working_width_m: 1,
        working_depth_cm: 1,
        working_speed_kmh: 1,
        n_tines: 1,
        soil_type,
      });

      // Coeficiente puro de la celda implemento × suelo (Tabla 1)
      expect(result.detail.coefficient).toBe(coeficienteEsperado);

      // Con entradas unitarias la potencia aísla el coeficiente:
      // P = coeficiente × factor de la familia (para 'pto' es exactamente el coeficiente)
      const factor = FACTOR_POR_FAMILIA[IMPLEMENT_CATALOG[implement_type].family];
      expect(result.power_required_hp).toBe(round2(coeficienteEsperado * factor));

      if (implement_type === "arado_disco_vertedera") {
        // V = 1 km/h < 4: se ajusta (clamp) a la fila de 4 km/h con advertencia
        expect(result.detail.cl_interpolated).toBe(false);
        expect(result.warnings.some((w) => w.includes("4-10 km/h"))).toBe(true);
      }
    });
  });
});
