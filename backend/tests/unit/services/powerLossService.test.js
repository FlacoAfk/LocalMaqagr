/**
 * Tests unitarios para powerLossService
 * Verifica cálculos físicos de pérdidas de potencia.
 */

import { jest, describe, test, expect } from "@jest/globals";
import * as powerLossService from "../../../src/services/powerLossService.js";

describe("powerLossService", () => {
  const {
    calculateAltitudeLoss,
    calculateTemperatureLoss,
    calculateSlopeLossHP,
    calculateRollingResistanceHP,
    calculateTransmissionLoss,
    calculateSlippageLossHP,
    calculateTotalLoss,
    degreesToRadians,
    slopePercentToDegrees,
  } = powerLossService;

  // ========================================================
  // 1. PÉRDIDAS ATMOSFÉRICAS
  // ========================================================
  describe("calculateAltitudeLoss", () => {
    test("calcula correctamente pérdida a 1500m (5%)", () => {
      // 1500m / 300m = 5 iteraciones * 1% = 5%
      const loss = calculateAltitudeLoss(100, 1500);
      expect(loss).toBeCloseTo(5.0);
    });

    test("retorna 0 si está a nivel del mar o abajo", () => {
      expect(calculateAltitudeLoss(100, 0)).toBe(0);
      expect(calculateAltitudeLoss(100, -50)).toBe(0);
    });

    test("retorna 0 si el tractor tiene turbo (altitud no afecta)", () => {
      expect(calculateAltitudeLoss(100, 1500, true)).toBe(0);
      expect(calculateAltitudeLoss(100, 3000, true)).toBe(0);
    });

    test("retorna pérdida si el tractor es aspirado (hasTurbo = false)", () => {
      expect(calculateAltitudeLoss(100, 1500, false)).toBeCloseTo(5.0);
    });

    test("retorna pérdida si hasTurbo no se pasa (default aspirado)", () => {
      expect(calculateAltitudeLoss(100, 1500)).toBeCloseTo(5.0);
    });
  });

  describe("calculateTemperatureLoss", () => {
    test("calcula correctamente pérdida a 35°C (4%)", () => {
      // (35 - 15) / 5 = 4 iteraciones * 1% = 4%
      const loss = calculateTemperatureLoss(100, 35);
      expect(loss).toBeCloseTo(4.0);
    });

    test("retorna 0 si temperatura es <= 15°C", () => {
      expect(calculateTemperatureLoss(100, 15)).toBe(0);
      expect(calculateTemperatureLoss(100, 10)).toBe(0);
    });

    test("retorna 0 si el tractor tiene turbo (temperatura no afecta)", () => {
      expect(calculateTemperatureLoss(100, 35, true)).toBe(0);
      expect(calculateTemperatureLoss(100, 45, true)).toBe(0);
    });

    test("retorna pérdida si el tractor es aspirado (hasTurbo = false)", () => {
      expect(calculateTemperatureLoss(100, 35, false)).toBeCloseTo(4.0);
    });

    test("retorna pérdida si hasTurbo no se pasa (default aspirado)", () => {
      expect(calculateTemperatureLoss(100, 35)).toBeCloseTo(4.0);
    });
  });

  // ========================================================
  // 2. PÉRDIDAS MECÁNICAS
  // ========================================================
  describe("calculateTransmissionLoss", () => {
    test("usa factor default 0.13", () => {
      expect(calculateTransmissionLoss(100)).toBeCloseTo(13.0);
    });

    test("usa factor personalizado", () => {
      expect(calculateTransmissionLoss(100, 0.15)).toBeCloseTo(15.0);
    });
  });

  // ========================================================
  // 3. PÉRDIDAS POR TERRENO
  // ========================================================
  describe("calculateRollingResistanceHP", () => {
    test("calcula resistencia en terreno plano", () => {
      // Caso manual: W=5000, Cn=50 (μr=0.064), slope=0, v=8km/h
      // Fn = 5000
      // Fr = 0.064 * 5000 = 320 kgf
      // P = 320 * (8/3.6) = 711.11 kgf*m/s
      // HP = 711.11 / 274.4 = 2.59 HP
      const loss = calculateRollingResistanceHP(5000, 50, 0, 8);
      expect(loss).toBeCloseTo(2.59, 1);
    });

    test("aumenta en suelos blandos (Cn bajo)", () => {
      const hardSoil = calculateRollingResistanceHP(5000, 100, 0, 5);
      const softSoil = calculateRollingResistanceHP(5000, 20, 0, 5);
      expect(softSoil).toBeGreaterThan(hardSoil);
    });
  });

  describe("calculateSlopeLossHP", () => {
    test("calcula pérdida por pendiente positiva", () => {
      // W=5000, 10% slope (5.71°), v=6km/h
      // F = 5000 * sin(5.71°) = 497.5 kgf
      // P = 497.5 * 1.66 = 829.1 kgf*m/s
      // HP = 829.1 / 274.4 = 3.02 HP
      const loss = calculateSlopeLossHP(5000, 10, 6);
      expect(loss).toBeCloseTo(3.02, 1);
    });

    test("retorna 0 en terreno plano o bajada", () => {
      expect(calculateSlopeLossHP(5000, 0, 6)).toBe(0);
      expect(calculateSlopeLossHP(5000, -5, 6)).toBe(0);
    });
  });

  // ========================================================
  // 4. PÉRDIDAS POR PATINAJE
  // ========================================================
  describe("calculateSlippageLossHP", () => {
    test("calcula porcentaje directo de potencia", () => {
      expect(calculateSlippageLossHP(80, 15)).toBeCloseTo(12.0); // 15% de 80
    });
  });

  // ========================================================
  // 5. INTEGRACIÓN (TOTAL LOSS)
  // ========================================================
  describe("calculateTotalLoss", () => {
    test("ejecuta flujo completo y retorna estructura correcta", () => {
      const result = calculateTotalLoss({
        enginePower: 120,
        altitudeMeters: 1500, // -6 HP
        temperatureC: 30, // -3.6 HP (aprox)
        totalWeightKg: 5000,
        soilCn: 50,
        slopePercent: 10,
        speedKmh: 6,
        slippagePercent: 10,
      });

      expect(result).toHaveProperty("grossPower", 120);
      expect(result).toHaveProperty("netPower");
      expect(result).toHaveProperty("efficiency");
      expect(result.losses).toHaveProperty("altitude");
      expect(result.losses.total).toBeGreaterThan(0);
      expect(result.netPower).toBeLessThan(120);
    });

    test("maneja potencia insuficiente (netPower 0)", () => {
      // Caso extremo: pendiente imposible
      const result = calculateTotalLoss({
        enginePower: 50,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 10000, // Muy pesado para 50HP
        soilCn: 20,
        slopePercent: 50, // Pendiente extrema
        speedKmh: 10,
        slippagePercent: 20,
      });

      expect(result.netPower).toBe(0);
    });

    test("con turbo: no aplica pérdidas atmosféricas", () => {
      const result = calculateTotalLoss({
        enginePower: 120,
        altitudeMeters: 1500,
        temperatureC: 30,
        totalWeightKg: 5000,
        soilCn: 50,
        slopePercent: 10,
        speedKmh: 6,
        slippagePercent: 10,
        hasTurbo: true,
      });

      expect(result.losses.altitude).toBe(0);
      expect(result.losses.temperature).toBe(0);
      expect(result.hasTurbo).toBe(true);
    });

    test("con turbo: netPower es mayor que sin turbo en las mismas condiciones", () => {
      const baseParams = {
        enginePower: 120,
        altitudeMeters: 1500,
        temperatureC: 30,
        totalWeightKg: 5000,
        soilCn: 50,
        slopePercent: 10,
        speedKmh: 6,
        slippagePercent: 10,
      };

      const withTurbo = calculateTotalLoss({ ...baseParams, hasTurbo: true });
      const withoutTurbo = calculateTotalLoss({ ...baseParams, hasTurbo: false });

      expect(withTurbo.netPower).toBeGreaterThan(withoutTurbo.netPower);
    });

    test("sin turbo: aplica pérdidas atmosféricas", () => {
      const result = calculateTotalLoss({
        enginePower: 120,
        altitudeMeters: 1500,
        temperatureC: 30,
        totalWeightKg: 5000,
        soilCn: 50,
        slopePercent: 10,
        speedKmh: 6,
        slippagePercent: 10,
        hasTurbo: false,
      });

      expect(result.losses.altitude).toBeGreaterThan(0);
      expect(result.losses.temperature).toBeGreaterThan(0);
    });
  });

  // ========================================================
  // 6. UTILIDADES
  // ========================================================
  describe("Utility Functions", () => {
    test("conversiones angulares correctas", () => {
      expect(degreesToRadians(180)).toBeCloseTo(Math.PI);
      expect(slopePercentToDegrees(100)).toBeCloseTo(45.0);
    });
  });

  // ========================================================
  // 7. CORRECCIÓN ZOZ & GRISSO (2003)
  // ========================================================
  describe("mapTractionTypeToZoz", () => {
    const { mapTractionTypeToZoz } = powerLossService;

    test("mapea aliases a filas de la Fig. 47", () => {
      expect(mapTractionTypeToZoz("4x2")).toBe("2WD");
      expect(mapTractionTypeToZoz("2wd")).toBe("2WD");
      expect(mapTractionTypeToZoz("mfwd")).toBe("MFWD");
      expect(mapTractionTypeToZoz("4x4")).toBe("4WD");
      expect(mapTractionTypeToZoz("4wd")).toBe("4WD");
      expect(mapTractionTypeToZoz("track")).toBe("BELT");
      expect(mapTractionTypeToZoz("oruga")).toBe("BELT");
      expect(mapTractionTypeToZoz("belt")).toBe("BELT");
    });

    test("valor desconocido cae en 2WD (default)", () => {
      expect(mapTractionTypeToZoz("otro")).toBe("2WD");
      expect(mapTractionTypeToZoz(undefined)).toBe("2WD");
    });
  });

  describe("getAxleLossBySoilAndTractorType", () => {
    const { getAxleLossBySoilAndTractorType, mapTractionTypeToZoz } = powerLossService;

    test("2WD en suelo bueno → 0.25", () => {
      expect(getAxleLossBySoilAndTractorType("bueno", "2WD")).toBe(0.25);
    });

    test("BELT en suelo malo → 0.19", () => {
      expect(getAxleLossBySoilAndTractorType("malo", "BELT")).toBe(0.19);
    });

    test("4WD (mapeado de '4x4') en suelo medio → 0.22", () => {
      expect(getAxleLossBySoilAndTractorType("medio", mapTractionTypeToZoz("4x4"))).toBe(0.22);
    });

    test("condición inválida cae en 'medio'", () => {
      expect(getAxleLossBySoilAndTractorType("inexistente", "2WD")).toBe(0.3);
      expect(getAxleLossBySoilAndTractorType(undefined, "2WD")).toBe(0.3);
    });
  });

  describe("getPtoEfficiencyBySoilAndTractorType", () => {
    const { getPtoEfficiencyBySoilAndTractorType } = powerLossService;

    test("2WD en suelo medio → 0.67", () => {
      expect(getPtoEfficiencyBySoilAndTractorType("medio", "2WD")).toBe(0.67);
    });

    test("4WD en suelo bueno → 0.77", () => {
      expect(getPtoEfficiencyBySoilAndTractorType("bueno", "4WD")).toBe(0.77);
    });
  });

  describe("calculateTotalLossWithZoz", () => {
    const { calculateTotalLossWithZoz } = powerLossService;

    test("80 HP turbo, 2WD, suelo bueno, sin peso ni pendiente → net 47.1 HP", () => {
      // Cadena secuencial: eje = 80 × 0.785 = 62.8 → net = 62.8 × (1 − 0.25) = 47.1
      // (turbo: sin pérdidas atmosféricas; peso 0 y pendiente 0: sin rodadura ni pendiente)
      const result = calculateTotalLossWithZoz({
        enginePower: 80,
        altitudeMeters: 1000, // no afecta: hasTurbo true
        temperatureC: 35, // no afecta: hasTurbo true
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 7.5,
        slippagePercent: 15, // ignorado en la ruta Zoz
        tractorTractionType: "4x2",
        soilCondition: "bueno",
        hasTurbo: true,
      });

      expect(result.netPower).toBe(47.1);
      expect(result.zoz.tractor_type).toBe("2WD");
      expect(result.zoz.soil_condition).toBe("bueno");
      expect(result.zoz.axle_loss).toBe(0.25);
      expect(result.zoz.gross_to_axle_efficiency).toBe(0.785);
      // Desglose de la pérdida de tracción: interna (bruta→eje) + entrega (eje→barra)
      expect(result.zoz.internal_drivetrain_loss_hp).toBeCloseTo(80 * 0.215, 2); // 17.2
      expect(result.zoz.traction_loss_hp).toBeCloseTo(80 * 0.785 * 0.25, 2); // 15.7
      // Fracción de la potencia post-atmosférica: 1 − 0.785 × (1 − 0.25) = 0.41125
      expect(result.zoz.combined_drivetrain_loss).toBeCloseTo(1 - 0.785 * 0.75, 2);
      expect(result.losses.transmission).toBeCloseTo(17.2 + 15.7, 2); // 32.9
      expect(result.losses.rollingResistance).toBe(0); // ya incluida en la E.T. (Fig. 47)
      expect(result.zoz.rolling_included_in_et).toBe(true);
      expect(result.losses.slippage).toBe(0); // absorbido en la pérdida de eje
      expect(result.zoz.slippage_absorbed).toBe(true);
    });

    test("potencia en la TDF = potencia en el eje × eficiencia Fig. 47", () => {
      // eje = 80 × 0.785 = 62.8 → TDF = 62.8 × 0.72 (2WD, suelo bueno) = 45.22 HP
      const result = calculateTotalLossWithZoz({
        enginePower: 80,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 0,
        tractorTractionType: "4x2",
        soilCondition: "bueno",
        hasTurbo: true,
      });
      expect(result.zoz.pto_efficiency).toBe(0.72);
      expect(result.zoz.pto_power_hp).toBe(45.22);
    });

    test("pto_power_hp aplica la etapa bruta→eje antes de la eficiencia TDF", () => {
      // post-atmosférico = 100 (turbo) → eje = 100 × 0.785 = 78.5
      // TDF = 78.5 × 0.72 (2WD, suelo bueno) = 56.52 HP
      const result = calculateTotalLossWithZoz({
        enginePower: 100,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 0,
        tractorTractionType: "4x2",
        soilCondition: "bueno",
        hasTurbo: true,
      });
      expect(result.zoz.pto_power_hp).toBe(56.52);
    });

    test("la rodadura NO se descuenta en la ruta Zoz (ya está dentro de la E.T. de Fig. 47)", () => {
      // Con 4000 kg (Cn 45 ≈ arcilla) a 7 km/h, la rodadura del flujo legacy
      // sería ≈ 1.89 HP. En la ruta Zoz no debe descontarse: la eficiencia de
      // entrega eje→barra ya incluye patinamiento, rodamiento y fricción.
      const params = {
        enginePower: 100,
        altitudeMeters: 0,
        temperatureC: 15,
        soilCn: 45,
        slopePercent: 0,
        speedKmh: 7,
        tractorTractionType: "4x2",
        soilCondition: "bueno",
        hasTurbo: true,
      };

      // La rodadura legacy con ese peso NO es cero (el input sí la produciría)...
      expect(calculateRollingResistanceHP(4000, 45, 0, 7)).toBeGreaterThan(0);

      // ...pero la ruta Zoz la reporta en 0 y no la descuenta del neto
      const conPeso = calculateTotalLossWithZoz({ ...params, totalWeightKg: 4000 });
      const sinPeso = calculateTotalLossWithZoz({ ...params, totalWeightKg: 0 });

      expect(conPeso.losses.rollingResistance).toBe(0);
      expect(conPeso.zoz.rolling_included_in_et).toBe(true);
      // net = 100 × 0.785 × (1 − 0.25) = 58.88, idéntico con o sin peso
      expect(conPeso.netPower).toBe(58.88);
      expect(sinPeso.netPower).toBe(58.88);
    });

    test("retorna la misma estructura que calculateTotalLoss más el objeto zoz", () => {
      const result = calculateTotalLossWithZoz({
        enginePower: 120,
        altitudeMeters: 1500,
        temperatureC: 30,
        totalWeightKg: 5000,
        soilCn: 50,
        slopePercent: 10,
        speedKmh: 6,
        tractorTractionType: "4x4",
        soilCondition: "medio",
        hasTurbo: false,
      });

      expect(result).toHaveProperty("grossPower", 120);
      expect(result).toHaveProperty("netPower");
      expect(result).toHaveProperty("efficiency");
      expect(result).toHaveProperty("hasTurbo", false);
      expect(result.losses).toHaveProperty("altitude");
      expect(result.losses).toHaveProperty("temperature");
      expect(result.losses).toHaveProperty("transmission");
      expect(result.losses).toHaveProperty("rollingResistance");
      expect(result.losses).toHaveProperty("slope");
      expect(result.losses).toHaveProperty("slippage", 0);
      expect(result.losses).toHaveProperty("total");
      expect(result.zoz).toHaveProperty("tractor_type", "4WD");
      expect(result.zoz).toHaveProperty("axle_loss", 0.22);
      expect(result.zoz).toHaveProperty("pto_power_hp");
    });

    test("a mayor dureza de suelo, menor potencia neta (mayor pérdida de eje)", () => {
      const baseParams = {
        enginePower: 100,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 0,
        tractorTractionType: "4x2",
        hasTurbo: true,
      };

      const bueno = calculateTotalLossWithZoz({ ...baseParams, soilCondition: "bueno" });
      const malo = calculateTotalLossWithZoz({ ...baseParams, soilCondition: "malo" });

      expect(malo.netPower).toBeLessThan(bueno.netPower);
    });

    test("tracción ausente o no reconocida: asume 2WD y agrega advertencia en zoz", () => {
      const baseParams = {
        enginePower: 80,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 7.5,
        hasTurbo: true,
      };

      // Tracción no reconocida
      const desconocida = calculateTotalLossWithZoz({
        ...baseParams,
        tractorTractionType: "otro",
        soilCondition: "medio",
      });
      expect(desconocida.zoz.tractor_type).toBe("2WD");
      expect(desconocida.zoz.tractor_type_defaulted).toBe(true);
      expect(desconocida.zoz.warnings).toEqual([
        "tipo de tracción no reconocido, se asumió 2WD",
      ]);

      // Tracción ausente
      const ausente = calculateTotalLossWithZoz({ ...baseParams, soilCondition: "medio" });
      expect(ausente.zoz.tractor_type).toBe("2WD");
      expect(ausente.zoz.tractor_type_defaulted).toBe(true);
      expect(ausente.zoz.warnings.length).toBe(1);

      // Tracción reconocida: sin advertencia ni flag
      const reconocida = calculateTotalLossWithZoz({
        ...baseParams,
        tractorTractionType: "4x4",
        soilCondition: "medio",
      });
      expect(reconocida.zoz.tractor_type).toBe("4WD");
      expect(reconocida.zoz.tractor_type_defaulted).toBe(false);
      expect(reconocida.zoz.warnings).toEqual([]);
    });
  });

  describe("calculateTotalLoss (legacy) permanece sin cambios", () => {
    test("mantiene el flujo con transmisión fija 13% y patinaje separado", () => {
      // Con turbo (sin pérdidas atmosféricas), peso 0 y pendiente 0:
      // transmisión = 80 × 0.13 = 10.4 → en ruedas = 69.6
      // patinaje = 69.6 × 0.15 = 10.44 → net = 69.6 − 10.44 = 59.16
      const result = calculateTotalLoss({
        enginePower: 80,
        altitudeMeters: 0,
        temperatureC: 15,
        totalWeightKg: 0,
        soilCn: 35,
        slopePercent: 0,
        speedKmh: 7.5,
        slippagePercent: 15,
        hasTurbo: true,
      });

      expect(result.losses.transmission).toBeCloseTo(10.4, 2); // 80 × 0.13
      expect(result.losses.slippage).toBeCloseTo(10.44, 2); // (80 − 10.4) × 0.15
      expect(result.netPower).toBeCloseTo(59.16, 1);
    });
  });

  describe('calculateTotalLossV3 (cadena v3 del profesor)', () => {
    const V3 = (over = {}) =>
      powerLossService.calculateTotalLossV3({
        enginePower: 350,
        altitudeMeters: 1800,
        temperatureC: 18,
        totalWeightKg: 5500,
        slopePercent: 8,
        speedKmh: 4.5,
        tractorTractionType: '4x2',
        soilCondition: 'malo',
        superficieRodadura: 'arena_suelta',
        slippagePercent: 12,
        hasTurbo: false,
        pmaxTdpHp: null,
        ...over,
      });

    test('reproduce la cadena del profesor paso a paso (ejemplo H2)', () => {
      const r = V3();
      // P_N = 0,92 × 350 = 322
      expect(r.zoz.p_n_hp).toBe(322);
      // P_ALT = (1800/300)×1%×322 = 19,32
      expect(r.zoz.p_alt_hp).toBe(19.32);
      // P_TEMP = ((18−15)/5)×1%×322 = 1,93
      expect(r.zoz.p_temp_hp).toBe(1.93);
      // P_PAT = 12 % × 322 = 38,64 (dato del ejercicio "Pat. 12 %", dentro del corchete)
      expect(r.zoz.p_pat_hp).toBe(38.64);
      expect(r.losses.slippage).toBe(38.64);
      // P_ROD = 5500×4,5×(0,35·cos α + sen α)/274 ≈ 38,72 (hoja: 38,7)
      expect(r.zoz.p_rod_hp).toBe(38.72);
      // P_EJE = (322 − 19,32 − 1,93 − 38,64 − 38,72)×0,86 ≈ 192,12
      expect(r.zoz.p_eje_hp).toBe(192.12);
      // P_BDT = P_EJE × ET (malo, 2WD = 0,57)
      expect(r.zoz.et).toBe(0.57);
      expect(r.netPower).toBe(109.51);
      // La hoja anota 246,88 como dato de TDP (Pmax TDP), no como resultado.
      // Ruta TDP del profesor: (0,85·350)·0,96 − 38,72 = 246,88 (el valor de la hoja)
      expect(r.zoz.p_eje_tdp_hp).toBe(285.6);
      expect(r.zoz.p_bdt_tdp_hp).toBe(246.88);
      expect(r.zoz.tdp_to_axle_efficiency).toBe(0.96);
    });

    test('umbrales: altitud solo si A > 300 m, temperatura solo si T > 15 °C, turbo anula ambas', () => {
      const sinGatillo = V3({ altitudeMeters: 200, temperatureC: 10 });
      expect(sinGatillo.zoz.p_alt_hp).toBe(0);
      expect(sinGatillo.zoz.p_temp_hp).toBe(0);
      const turbo = V3({ hasTurbo: true });
      expect(turbo.zoz.p_alt_hp).toBe(0);
      expect(turbo.zoz.p_temp_hp).toBe(0);
    });

    test('ρ depende de la superficie y del tipo de tractor (lám. 26)', () => {
      // oruga en arena suelta: ρ = 0,20 (columna "Tractor orugas")
      expect(V3({ tractorTractionType: 'track' }).zoz.rho).toBe(0.2);
      // concreto con llantas: ρ = 0,025 (punto medio de 0,02–0,03)
      expect(V3({ superficieRodadura: 'concreto' }).zoz.rho).toBe(0.025);
      // superficie no indicada → arena_suelta con advertencia
      const def = V3({ superficieRodadura: undefined });
      expect(def.zoz.rho_surface).toBe('arena_suelta');
      expect(def.zoz.warnings.some((w) => w.includes('arena suelta'))).toBe(true);
    });

    test('PTO: default 0,85 × P_B (ec. 29) y override del usuario (H3)', () => {
      expect(V3().zoz.pto_power_hp).toBe(297.5);
      expect(V3().zoz.pto_source).toBe('default 85% de la potencia bruta');
      const user = V3({ pmaxTdpHp: 246.88 });
      expect(user.zoz.pto_power_hp).toBe(246.88);
      expect(user.zoz.pto_source).toBe('ingresada por el usuario');
    });

    test('patinamiento: se resta en el corchete y mantiene la alerta 7–15 %', () => {
      const fuera = V3({ slippagePercent: 20 });
      expect(fuera.zoz.warnings.some((w) => w.includes('7% a 15%'))).toBe(true);
      expect(fuera.losses.slippage).toBe(64.4); // 20 % × 322
      const dentro = V3({ slippagePercent: 10 });
      expect(dentro.zoz.warnings.some((w) => w.includes('7% a 15%'))).toBe(false);
      expect(dentro.losses.slippage).toBe(32.2); // 10 % × 322
      // Sin dato → el término no aplica (0) y no hay alerta
      const sinDato = V3({ slippagePercent: undefined });
      expect(sinDato.losses.slippage).toBe(0);
      expect(sinDato.zoz.warnings.some((w) => w.includes('7% a 15%'))).toBe(false);
    });

    test('desglose consistente: bruta − total de pérdidas = neta', () => {
      const r = V3();
      expect(350 - r.losses.total).toBeCloseTo(r.netPower, 1);
    });

    test('ρ por superficie y tipo de tractor (lám. 26): carretable, arcilloso_humedo, arcilloso_seco y limoso', () => {
      // [superficie, ρ llantas ('4x2'), ρ oruga ('track')]
      const CASOS_RHO = [
        ['carretable', 0.05, 0.06],
        ['arcilloso_humedo', 0.1, 0.07],
        ['arcilloso_seco', 0.07, 0.07],
        ['limoso', 0.2, 0.1],
      ];
      for (const [superficie, rhoLlantas, rhoOruga] of CASOS_RHO) {
        expect(V3({ superficieRodadura: superficie }).zoz.rho).toBe(rhoLlantas);
        expect(
          V3({ superficieRodadura: superficie, tractorTractionType: 'track' }).zoz.rho
        ).toBe(rhoOruga);
      }
    });

    test('coerción de pmax_tdp_hp: el string "350" no lanza y da pto 350', () => {
      const r = V3({ pmaxTdpHp: '350' });
      expect(r.zoz.pto_power_hp).toBe(350);
      expect(r.zoz.pto_source).toBe('ingresada por el usuario');
    });

    test('pmax_tdp_hp inválida (no numérica o <= 0) cae al default 85% con advertencia', () => {
      const noNumerica = V3({ pmaxTdpHp: 'abc' });
      expect(noNumerica.zoz.pto_power_hp).toBe(297.5);
      expect(noNumerica.zoz.pto_source).toBe('default 85% de la potencia bruta');
      expect(noNumerica.zoz.warnings.some((w) => w.includes('Pmax TDP inválida'))).toBe(true);
      const cero = V3({ pmaxTdpHp: 0 });
      expect(cero.zoz.pto_power_hp).toBe(297.5);
      expect(cero.zoz.warnings.some((w) => w.includes('Pmax TDP inválida'))).toBe(true);
    });

    test('P_ROD mayor que lo disponible: desglose limitado y bruta − total = neta (neta 0)', () => {
      // Turbo 100 HP, 20000 kg en arena suelta (ρ 0,35), pendiente 30 % a 6 km/h:
      // P_ROD cruda ≈ 272 HP > 92 HP disponible → se escala al máximo disponible.
      const r = V3({
        enginePower: 100,
        altitudeMeters: 0,
        temperatureC: 15,
        hasTurbo: true,
        totalWeightKg: 20000,
        slopePercent: 30,
        speedKmh: 6,
      });
      expect(r.netPower).toBe(0);
      expect(r.losses.rollingResistance).toBeGreaterThan(0);
      expect(r.losses.slope).toBeGreaterThan(0);
      // El desglose nunca supera la potencia bruta: bruta − total = neta = 0
      expect(r.losses.total).toBeCloseTo(100, 2);
      expect(100 - r.losses.total).toBeCloseTo(r.netPower, 2);
      // Rodadura + pendiente escaladas cubren lo disponible tras el patinamiento:
      // 92 (turbo) − 11,04 (Pat. 12 % × 92) = 80,96
      expect(r.losses.rollingResistance + r.losses.slope).toBeCloseTo(80.96, 1);
    });
  });

});
