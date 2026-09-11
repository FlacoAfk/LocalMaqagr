import { describe, expect, test } from '@jest/globals';
import {
  CONSTANTS,
  calculateAndMatch,
  calculateMinimumPower,
  findCompatibleTractors,
  normalizeSoilType,
} from '../../../src/services/minimumPowerService.js';

describe('minimumPowerService', () => {
  test('normalizeSoilType traduce aliases y aplica default loam', () => {
    expect(normalizeSoilType('Arcilla')).toBe('clay');
    expect(normalizeSoilType('pedregoso')).toBe('rocky');
    expect(normalizeSoilType('SANDY')).toBe('sandy');
    expect(normalizeSoilType('desconocido')).toBe('loam');
    expect(normalizeSoilType(null)).toBe('loam');
  });

  test('calculateMinimumPower valida inputs requeridos', () => {
    expect(() => calculateMinimumPower(null, { slope_percentage: 4 })).toThrow(
      'implementData.power_requirement_hp es requerido y debe ser un número',
    );
    expect(() =>
      calculateMinimumPower({ power_requirement_hp: 80 }, null),
    ).toThrow('terrainData.slope_percentage es requerido y debe ser un número');
  });

  test('calculateMinimumPower usa profundidad estándar cuando no se envía y redondea factores', () => {
    const result = calculateMinimumPower(
      { power_requirement_hp: 100 },
      { soil_type: 'arcilla', slope_percentage: 10 },
    );

    expect(result.minimumPowerHP).toBeCloseTo(156.98, 2);
    expect(result.calculatedPowerHP).toBeCloseTo(136.5, 2);
    expect(result.factors).toEqual({
      basePowerHP: 100,
      soilFactor: 1.3,
      slopeFactor: 1.05,
      depthFactor: 1,
      safetyMargin: CONSTANTS.SAFETY_MARGIN,
    });
    expect(result.input).toEqual({
      implementData: {
        power_requirement_hp: 100,
        working_depth_m: CONSTANTS.STANDARD_DEPTH_M,
      },
      terrainData: {
        soil_type: 'clay',
        slope_percentage: 10,
      },
    });
  });

  test('findCompatibleTractors retorna vacio si la lista no existe y valida minimumPower positivo', () => {
    expect(findCompatibleTractors(80, [])).toEqual([]);
    expect(() => findCompatibleTractors(0, [{ engine_power_hp: 90 }])).toThrow(
      'minimumPower debe ser un número positivo',
    );
  });

  test('findCompatibleTractors filtra, ordena por surplus y limita top 5', () => {
    const tractors = [
      { tractor_id: 1, engine_power_hp: 120 },
      { tractor_id: 2, enginePowerHp: 90 },
      { tractor_id: 3, engine_power_hp: 105 },
      { tractor_id: 4, engine_power_hp: 150 },
      { tractor_id: 5, engine_power_hp: 101 },
      { tractor_id: 6, engine_power_hp: 180 },
      { tractor_id: 7, engine_power_hp: 250 },
    ];

    const result = findCompatibleTractors(100, tractors);

    expect(result).toHaveLength(5);
    expect(result.map((tractor) => tractor.tractor_id)).toEqual([5, 3, 1, 4, 6]);
    expect(result[0].compatibility).toEqual({
      minimumPowerRequired: 100,
      tractorPowerHP: 101,
      surplusHP: 1,
      efficiencyPercent: 99.01,
      rank: 1,
    });
    expect(result[4].compatibility.rank).toBe(5);
  });

  test('calculateAndMatch integra cálculo, resumen y topRecommendation', () => {
    const tractors = [
      { tractor_id: 10, engine_power_hp: 160, name: 'A' },
      { tractor_id: 11, engine_power_hp: 120, name: 'B' },
      { tractor_id: 12, engine_power_hp: 95, name: 'C' },
    ];

    const result = calculateAndMatch(
      { power_requirement_hp: 80, working_depth_m: 0.25 },
      { soil_type: 'loam', slope_percentage: 0 },
      tractors,
    );

    expect(result.powerRequirement.minimumPowerHP).toBe(92);
    expect(result.compatibleTractors).toHaveLength(3);
    expect(result.summary).toEqual({
      minimumPowerHP: 92,
      totalTractorsEvaluated: 3,
      compatibleCount: 3,
      topRecommendation: expect.objectContaining({
        tractor_id: 12,
      }),
    });
  });
});
