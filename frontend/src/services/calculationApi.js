import { apiClient } from '../lib/apiClient';

const REMOTE_CALCULATION_API_ENABLED = import.meta.env.VITE_ENABLE_REMOTE_CALCULATION_API === 'true';

// Mocks
const mockPowerLoss = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        success: true,
        data: {
          queryId: 998,
          tractor: { brand: 'MockBrand', model: 'M-100' },
          terrain: { name: 'Campo Mock', soilType: 'rocky' },
          losses: {
            slopeLossHp: 5.5,
            altitudeLossHp: 2.0,
            rollingResistanceLossHp: 3.5,
            slippageLossHp: 4.0,
            totalLossHp: 15.0
          },
          netPowerHp: 85.0,
          enginePowerHp: 100.0,
          efficiencyPercentage: 85.0
        }
      });
    }, 1500);
  });
};

const mockDirectPowerLoss = async (payload) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const enginePowerHp = payload.enginePowerHp || 100;

      // Soil type affects rolling resistance.
      // Base factor: loam (0%). Clay: +30%, Silt: +10%, Sandy: -20%.
      const soilRollingFactor = {
        clay:  1.30,
        silt:  1.10,
        loam:  1.00,
        sandy: 0.80,
      }[payload.soilType] ?? 1.00;

      const losses = {
        slopeLossHp:              +(enginePowerHp * 0.04).toFixed(2),
        altitudeLossHp:           payload.hasTurbo ? 0 : +(enginePowerHp * 0.03).toFixed(2),
        rollingResistanceLossHp:  +(enginePowerHp * 0.03 * soilRollingFactor).toFixed(2),
        slippageLossHp:           +(enginePowerHp * (payload.slippagePercent || 10) / 100 * 0.5).toFixed(2),
      };
      const totalLossHp = +(
        losses.slopeLossHp +
        losses.altitudeLossHp +
        losses.rollingResistanceLossHp +
        losses.slippageLossHp
      ).toFixed(2);
      const netPowerHp = +(enginePowerHp - totalLossHp).toFixed(2);

      resolve({
        success: true,
        data: {
          queryId: null,
          tractor: { brand: 'Manual', model: 'Input', hasTurbo: payload.hasTurbo || false },
          terrain: { name: 'Terreno ingresado', soilType: payload.soilType || 'loam' },
          losses,
          totalLossHp,
          netPowerHp,
          enginePowerHp,
          efficiencyPercentage: +((netPowerHp / enginePowerHp) * 100).toFixed(2),
        },
      });
    }, 1500);
  });
};

const mockMinimumPower = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        success: true,
        data: {
          queryId: 997,
          implement: { id: 1, name: 'Sembradora Mock', brand: 'MockB', powerRequirementHp: 70 },
          powerRequirement: { minimumPowerHp: 80.5, calculatedPowerHp: 75.0 },
          tractorAnalysis: {
            totalEvaluated: 10,
            summary: { optimal: 2, overpowered: 5, insufficient: 3 }
          },
          recommendations: {
            top5: [
              {
                tractorId: 1,
                name: 'Tractor A',
                brand: 'Brand X',
                enginePowerHp: 90,
                suitability: { score: 'OPTIMAL', label: 'Óptimo', color: 'green', utilizationPercent: 88, isCompatible: true }
              }
            ]
          }
        }
      });
    }, 1500);
  });
};

export const calculatePowerLoss = async (payload) => {
  const token = localStorage.getItem('token') || sessionStorage.getItem('token');
  if (!REMOTE_CALCULATION_API_ENABLED || !token) {
    return mockPowerLoss();
  }

  // payload expected in camelCase: tractorId, terrainId, workingSpeedKmh, carriedObjectsWeightKg, slippagePercent
  return apiClient('/api/calculations/power-loss', {
    method: 'POST',
    body: payload,
  });
};

export const calculateDirectPowerLoss = async (payload) => {
  if (!REMOTE_CALCULATION_API_ENABLED) {
    return mockDirectPowerLoss(payload);
  }

  // payload in camelCase: enginePowerHp, weightKg, soilType, altitudeM, etc.
  // apiClient converts camelCase → snake_case before sending to backend
  return apiClient('/api/calculations/direct-power-loss', {
    method: 'POST',
    body: payload,
  });
};

const mockDirectMinimumPower = async (payload) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const basePower = payload.powerRequirementHp || 70;
      const soilFactor = { clay: 1.3, loam: 1.0, sandy: 0.8, rocky: 1.5 }[payload.soilType] || 1.0;
      const slopeFactor = 1 + ((payload.slopePercentage || 0) / 100) * 0.5;
      const depthFactor = (payload.workingDepthM || 0.25) / 0.25;
      const calculatedPower = basePower * soilFactor * slopeFactor * depthFactor;
      const minimumPower = calculatedPower * 1.15;

      resolve({
        success: true,
        data: {
          queryId: null,
          implement: {
            id: null,
            name: 'Implemento ingresado',
            type: 'Manual',
            powerRequirementHp: basePower,
          },
          terrain: {
            id: null,
            name: 'Terreno ingresado',
            soilType: payload.soilType || 'loam',
            slopePercentage: payload.slopePercentage || 0,
          },
          powerRequirement: {
            minimumPowerHp: Math.round(minimumPower * 100) / 100,
            calculatedPowerHp: Math.round(calculatedPower * 100) / 100,
            factors: {
              basePowerHp: basePower,
              soilFactor,
              slopeFactor,
              depthFactor,
              safetyMargin: 0.15,
            },
          },
          tractorAnalysis: {
            totalEvaluated: 10,
            summary: { optimal: 2, overpowered: 5, insufficient: 3 },
          },
          recommendations: {
            top5: [
              {
                tractorId: 1,
                name: 'Tractor A',
                brand: 'Brand X',
                enginePowerHp: Math.round(minimumPower * 1.1),
                suitability: { score: 'OPTIMAL', label: 'Óptimo', color: 'green', utilizationPercent: 88, isCompatible: true },
              },
            ],
            bestMatch: null,
          },
        },
      });
    }, 1500);
  });
};

export const calculateMinimumPower = async (payload) => {
  const token = localStorage.getItem('token') || sessionStorage.getItem('token');
  if (!REMOTE_CALCULATION_API_ENABLED || !token) {
    return mockMinimumPower();
  }

  // payload expected in camelCase: implementId, terrainId, workingDepthM
  return apiClient('/api/calculations/minimum-power', {
    method: 'POST',
    body: payload,
  });
};

export const calculateDirectMinimumPower = async (payload) => {
  if (!REMOTE_CALCULATION_API_ENABLED) {
    return mockDirectMinimumPower(payload);
  }

  // payload in camelCase: powerRequirementHp, workingDepthM, soilType, slopePercentage
  // apiClient converts camelCase → snake_case before sending to backend
  return apiClient('/api/calculations/direct-minimum-power', {
    method: 'POST',
    body: payload,
  });
};

// ---------------------------------------------------------------------------
// Cálculo directo de potencia requerida por tipo de implemento
// ---------------------------------------------------------------------------

/** Constante de las fórmulas expresadas en kgf/m y kgf/cm. */
const DIRECT_IMPLEMENT_KGF_CONSTANT = 0.00365;

/** Constante de la familia del arado de disco y vertedera (100 × 0.00365). */
const DIRECT_IMPLEMENT_PLOW_CONSTANT = 0.365;

/** Índice de columna de las tablas de coeficientes: [arena, limo, arcilla]. */
const DIRECT_SOIL_INDEX = { arena: 0, limo: 1, arcilla: 2 };

/**
 * Coeficiente CL del arado de disco y vertedera según la velocidad (km/h).
 * Para velocidades no enteras se interpola linealmente entre filas adyacentes.
 */
const ARADO_DISCO_VERTEDERA_CL = [
  { speed: 4,  cl: [0.21, 0.56, 0.70] },
  { speed: 5,  cl: [0.21, 0.60, 0.73] },
  { speed: 6,  cl: [0.22, 0.63, 0.77] },
  { speed: 7,  cl: [0.24, 0.70, 0.85] },
  { speed: 8,  cl: [0.26, 0.77, 0.92] },
  { speed: 9,  cl: [0.28, 0.84, 1.02] },
  { speed: 10, cl: [0.29, 0.95, 1.12] },
];

/**
 * Resistencia específica T (kgf/m o kgf/cm) por familia de implemento.
 * Columnas: [arena, limo, arcilla].
 */
const DIRECT_IMPLEMENT_RESISTANCE = {
  subsolador: [18, 24, 30],
  arado_cincel: [9, 12, 15],
  implemento_rotativo: [16, 24, 32],
  rastrillo_simple_discos: [75, 113, 150],
  rastrillo_pulidor: [150, 300, 450],
  rastrillo_californiano: [350, 475, 600],
  rastra_pesada_26: [800, 900, 1000],
  rastra_pesada_24: [700, 800, 900],
};

/**
 * Normaliza el tipo de suelo como lo hace el backend (implementPowerService):
 * alias comunes a arena/limo/arcilla, con advertencia cuando el mapeo no es directo.
 */
const normalizeDirectSoilType = (soilType, warnings) => {
  const normalized = String(soilType ?? "").toLowerCase().trim();

  const soilAliases = {
    arena: "arena",
    arenoso: "arena",
    sand: "arena",
    sandy: "arena",
    limo: "limo",
    silt: "limo",
    arcilla: "arcilla",
    arcilloso: "arcilla",
    clay: "arcilla",
    // La Tabla 1 no tiene franco: se mapea a limo (suelo intermedio) con advertencia
    franco: "limo",
    loam: "limo",
  };

  if (normalized === "franco" || normalized === "loam") {
    warnings.push("franco/loam mapeado a limo (la Tabla 1 no tiene franco)");
    return "limo";
  }
  if (soilAliases[normalized]) {
    return soilAliases[normalized];
  }

  warnings.push(
    `Tipo de suelo no reconocido ("${soilType ?? "sin valor"}"), se usa limo por defecto`
  );
  return "limo";
};

/**
 * CL del arado para una velocidad dada: interpola linealmente entre las filas
 * de la tabla (4 a 10 km/h). Fuera de rango se ajusta (clamp) al borde más
 * cercano con advertencia — misma conducta y textos que el backend.
 */
const getDirectPlowClForSpeed = (speedKmh, soilIndex, warnings) => {
  // Fuera de rango por abajo: clamp a la fila 4 km/h
  if (speedKmh < 4) {
    warnings.push(
      "Velocidad fuera del rango 4-10 km/h de la Tabla 1 (se usó el valor del borde de 4 km/h)"
    );
    return { cl: ARADO_DISCO_VERTEDERA_CL[0].cl[soilIndex], interpolated: false };
  }

  // Fuera de rango por arriba: clamp a la fila 10 km/h
  if (speedKmh > 10) {
    warnings.push(
      "Velocidad fuera del rango 4-10 km/h de la Tabla 1 (se usó el valor del borde de 10 km/h)"
    );
    const lastRow = ARADO_DISCO_VERTEDERA_CL[ARADO_DISCO_VERTEDERA_CL.length - 1];
    return { cl: lastRow.cl[soilIndex], interpolated: false };
  }

  // Velocidad entera: valor directo de la tabla (sin interpolación)
  const lower = Math.floor(speedKmh);
  const lowerRow = ARADO_DISCO_VERTEDERA_CL[lower - 4]; // las filas arrancan en 4 km/h
  if (lower === speedKmh) {
    return { cl: lowerRow.cl[soilIndex], interpolated: false };
  }

  // Velocidad no entera: interpolación lineal entre filas adyacentes
  const upperRow = ARADO_DISCO_VERTEDERA_CL[lower - 4 + 1];
  const t = speedKmh - lower;
  const cl = lowerRow.cl[soilIndex] + (upperRow.cl[soilIndex] - lowerRow.cl[soilIndex]) * t;
  return { cl: Math.round(cl * 1000) / 1000, interpolated: true };
};

const mockDirectImplementPower = async (payload) => {
  // El mock replica las fórmulas del endpoint real para cada familia.
  if (
    payload.implementType !== 'arado_disco_vertedera' &&
    !DIRECT_IMPLEMENT_RESISTANCE[payload.implementType]
  ) {
    throw new Error('Tipo de implemento no soportado para el cálculo directo de potencia.');
  }

  return new Promise((resolve) => {
    setTimeout(() => {
      const implementType = payload.implementType;
      const workingWidthM = payload.workingWidthM || 0;
      const workingDepthCm = payload.workingDepthCm || 0;
      const workingSpeedKmh = payload.workingSpeedKmh || 0;
      const nTines = payload.nTines || 0;
      const warnings = [];
      const soil = normalizeDirectSoilType(payload.soilType, warnings);
      const soilIndex = DIRECT_SOIL_INDEX[soil] ?? 1;

      const detail = { soilType: soil };
      let powerKind = 'drawbar';
      let powerRequiredHp = 0;

      if (implementType === 'arado_disco_vertedera') {
        const { cl, interpolated } = getDirectPlowClForSpeed(workingSpeedKmh, soilIndex, warnings);
        detail.coefficientSpeedKmh = Math.min(10, Math.max(4, Math.floor(workingSpeedKmh)));
        detail.cl = cl;
        detail.clInterpolated = interpolated;
        powerRequiredHp = workingWidthM * workingDepthCm * workingSpeedKmh * cl * DIRECT_IMPLEMENT_PLOW_CONSTANT;
      } else if (implementType === 'subsolador' || implementType === 'arado_cincel') {
        const t = DIRECT_IMPLEMENT_RESISTANCE[implementType][soilIndex];
        detail.resistanceKgf = t;
        powerRequiredHp = t * nTines * workingDepthCm * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
      } else if (implementType === 'implemento_rotativo') {
        const t = DIRECT_IMPLEMENT_RESISTANCE.implemento_rotativo[soilIndex];
        powerKind = 'pto';
        detail.resistanceKgf = t;
        powerRequiredHp = t * workingWidthM;
      } else {
        const t = DIRECT_IMPLEMENT_RESISTANCE[implementType][soilIndex];
        detail.resistanceKgf = t;
        powerRequiredHp = t * workingWidthM * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
      }

      resolve({
        success: true,
        data: {
          implementType,
          powerKind,
          powerRequiredHp: Math.round(powerRequiredHp * 100) / 100,
          detail,
          warnings,
        },
      });
    }, 1500);
  });
};

export const calculateDirectImplementPower = async (payload) => {
  if (!REMOTE_CALCULATION_API_ENABLED) {
    return mockDirectImplementPower(payload);
  }

  // payload in camelCase: implementType, workingWidthM, workingDepthCm, workingSpeedKmh, soilType, nTines
  // apiClient converts camelCase → snake_case before sending to backend
  return apiClient('/api/calculations/direct-implement-power', {
    method: 'POST',
    body: payload,
  });
};

export const getCalculationHistory = async (page = 1, limit = 10, type = '') => {
  if (!REMOTE_CALCULATION_API_ENABLED) {
    return { success: true, data: [] }; // Mock empty history
  }

  const query = new URLSearchParams({ page, limit });
  if (type) query.append('type', type);

  return apiClient(`/api/calculations/history?${query.toString()}`, {
    method: 'GET',
  });
};
