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

// ===== Cadena V3 del profesor (hojas H1/H2 + láminas 13/21/26/27 de la expo) =====
// Misma cadena que el backend (powerLossService.calculateTotalLossV3):
//   P_N = 0,92·P_B → P_ALT/P_TEMP sobre P_N (solo aspirados; A > 300 m; T > 15 °C)
//   → P_ROD = W·V·(ρ·cosα + senα)/274 con α = atan(pend%/100) (lám. 26/27)
//   → P_EJE = (P_N − P_ALT − P_TEMP − P_ROD)·0,86 (Fig. 43: neta→eje 0,84–0,88)
//   → P_BDT = P_EJE·ET (Fig. 47 multiplicada como eficiencia)
// El patinamiento NO se resta aparte: ya viene dentro de ET; solo se advierte
// cuando queda fuera del rango ideal 7–15 %.

/** Eficiencia bruta→neta del motor (Fig. 43 de Zoz & Grisso). */
const V3_GROSS_TO_NET_EFFICIENCY = 0.92;

/** Eficiencia neta→eje: punto medio del rango 0,84–0,88 (Fig. 43 de Zoz & Grisso). */
const V3_NET_TO_AXLE_EFFICIENCY = 0.86;

/** ρ de resistencia al rodamiento por superficie (lámina 26 del profesor).
 *  Columnas: llantas / oruga. Concreto no aplica para oruga (N.A.). */
const V3_RHO_SUPERFICIE = {
  concreto: { llantas: 0.025, oruga: null }, // punto medio del rango 0,02–0,03
  carretable: { llantas: 0.05, oruga: 0.06 },
  arcilloso_humedo: { llantas: 0.1, oruga: 0.07 },
  arcilloso_seco: { llantas: 0.07, oruga: 0.07 }, // punto medio del rango 0,06–0,08
  limoso: { llantas: 0.2, oruga: 0.1 },
  arena_suelta: { llantas: 0.35, oruga: 0.2 },
};

/** ET de entrega eje→barra de tiro (Fig. 47 de Zoz & Grisso, como eficiencia).
 *  Filas: 2WD / MFWD / 4WD / oruga (BELT). Columnas: bueno / medio / malo. */
const V3_ET_FIG47 = {
  '2WD': { bueno: 0.75, medio: 0.7, malo: 0.57 },
  MFWD: { bueno: 0.79, medio: 0.75, malo: 0.66 },
  '4WD': { bueno: 0.8, medio: 0.78, malo: 0.73 },
  BELT: { bueno: 0.85, medio: 0.83, malo: 0.81 },
};

/** Tipos de tracción reconocidos; cualquier otro cae en 2WD con advertencia. */
const V3_RECOGNIZED_TRACTION_TYPES = ['mfwd', '4x4', '4wd', 'track', 'oruga', 'belt', '4x2', '2wd'];

/** Normaliza la condición del suelo a los valores de la Fig. 47 (default medio). */
const normalizeSoilConditionV3 = (soilCondition) => {
  const normalized = String(soilCondition ?? '').toLowerCase().trim();
  return ['bueno', 'medio', 'malo'].includes(normalized) ? normalized : 'medio';
};

/** Mapea el tipo de tracción a las filas de la Fig. 47 ('track'/'oruga'/'belt' → BELT). */
const mapTractionTypeToZozV3 = (tractionType) => {
  const normalized = String(tractionType ?? '').toLowerCase().trim();
  if (normalized === 'mfwd') return 'MFWD';
  if (normalized === '4x4' || normalized === '4wd') return '4WD';
  if (normalized === 'track' || normalized === 'oruga' || normalized === 'belt') return 'BELT';
  // '4x2', '2wd' y cualquier valor desconocido caen en 2WD
  return '2WD';
};

const round2 = (value) => Math.round(value * 100) / 100;

const mockDirectPowerLoss = async (payload) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const enginePowerHp = Number(payload.enginePowerHp) || 0;
      const hasTurbo = Boolean(payload.hasTurbo);
      const totalWeightKg =
        (Number(payload.weightKg) || 0) + (Number(payload.carriedObjectsWeightKg) || 0);
      const speedKmh = Number(payload.workingSpeedKmh) || 7; // default del controlador
      const slopePercent = Number(payload.slopePercent) || 0;
      const warnings = [];

      // 1. Potencia neta del motor: P_N = 0,92 · P_B
      const pN = enginePowerHp * V3_GROSS_TO_NET_EFFICIENCY;

      // 2. Pérdidas atmosféricas sobre P_N — solo aspirados; altitud solo si A > 300 m
      const altitudeM = Number(payload.altitudeM);
      const altLoss = !hasTurbo && altitudeM > 300 ? pN * (altitudeM / 300) * 0.01 : 0;
      const temperatureC = Number(payload.ambientTemperatureC);
      const tempLoss =
        !hasTurbo && temperatureC > 15 ? pN * ((temperatureC - 15) / 5) * 0.01 : 0;

      // 3. Rodadura + pendiente combinadas (lám. 26/27): la hoja del profesor redondea
      //    la conversión y presenta P_ROD = W·V·(ρ·cosα + senα)/274.
      const zozTractorType = mapTractionTypeToZozV3(payload.tractionType);
      const surfaceKey = String(payload.superficieRodadura ?? '').toLowerCase().trim();
      const surfaceDefaulted = !Object.keys(V3_RHO_SUPERFICIE).includes(surfaceKey);
      const surface = surfaceDefaulted ? 'arena_suelta' : surfaceKey;
      if (surfaceDefaulted) {
        warnings.push('superficie de rodadura no indicada o no reconocida, se asumió arena suelta seca');
      }
      const rhoKind = zozTractorType === 'BELT' ? 'oruga' : 'llantas';
      let rho = V3_RHO_SUPERFICIE[surface][rhoKind];
      if (rho === null || rho === undefined) {
        rho = V3_RHO_SUPERFICIE[surface].llantas;
        warnings.push('la superficie seleccionada no aplica para oruga, se usó el coeficiente de llantas');
      }
      const alphaRadians = Math.atan(slopePercent / 100);
      let rollingPart = (totalWeightKg * Math.cos(alphaRadians) * rho * speedKmh) / 274;
      let slopePart = (totalWeightKg * Math.sin(alphaRadians) * speedKmh) / 274;

      // Invariante bruta − total = neta: cuando P_ROD supera lo disponible
      // (P_N − P_ALT − P_TEMP) se escala proporcionalmente al máximo disponible
      // (misma conducta que el backend).
      const availableBeforeRod = pN - altLoss - tempLoss;
      const pRodRaw = rollingPart + slopePart;
      if (pRodRaw > availableBeforeRod) {
        const scale = availableBeforeRod > 0 ? availableBeforeRod / pRodRaw : 0;
        rollingPart *= scale;
        slopePart *= scale;
      }
      const pRod = rollingPart + slopePart;

      // 4. Potencia en el eje: P_EJE = (P_N − P_ALT − P_TEMP − P_ROD) · 0,86
      const effectiveBase = Math.max(0, availableBeforeRod - pRod);
      const pEje = effectiveBase * V3_NET_TO_AXLE_EFFICIENCY;

      // 5. P_BDT = P_EJE · ET (Fig. 47 multiplicada como eficiencia)
      const soilCondition = normalizeSoilConditionV3(payload.soilCondition);
      const et = V3_ET_FIG47[zozTractorType][soilCondition];
      const axleLoss = 1 - et;
      const tractionLossHp = pEje * axleLoss;
      const netPowerHp = Math.max(0, pEje * et);

      // Advertencias: tracción no reconocida, patinamiento fuera de 7–15 %
      const normalizedTraction = String(payload.tractionType ?? '').toLowerCase().trim();
      const tractionTypeDefaulted = !V3_RECOGNIZED_TRACTION_TYPES.includes(normalizedTraction);
      if (tractionTypeDefaulted) {
        warnings.push('tipo de tracción no reconocido, se asumió 2WD');
      }
      const slippagePercent = payload.slippagePercent;
      if (
        slippagePercent !== undefined &&
        slippagePercent !== null &&
        (Number(slippagePercent) < 7 || Number(slippagePercent) > 15)
      ) {
        warnings.push('Patinamiento fuera del rango ideal (7% a 15%)');
      }

      // Desglose: transmission agrupa bruta→neta (0,92) + neta→eje (0,86) + entrega eje→barra (1 − ET)
      const grossToNetLoss = enginePowerHp - pN;
      const netToAxleLossHp = effectiveBase * (1 - V3_NET_TO_AXLE_EFFICIENCY);
      const transmissionLossHp = grossToNetLoss + netToAxleLossHp + tractionLossHp;
      const totalLossHp = altLoss + tempLoss + transmissionLossHp + rollingPart + slopePart;
      const efficiencyPercentage =
        enginePowerHp > 0 ? (netPowerHp / enginePowerHp) * 100 : 0;

      // Potencia disponible en la TDF: la que ingresa el usuario (hoja H3)
      // o 0,86 · P_B por defecto cuando no hay dato.
      let pmaxTdpHpNumber =
        payload.pmaxTdpHp === undefined || payload.pmaxTdpHp === null || payload.pmaxTdpHp === ''
          ? null
          : Number(payload.pmaxTdpHp);
      if (pmaxTdpHpNumber !== null && (!Number.isFinite(pmaxTdpHpNumber) || pmaxTdpHpNumber <= 0)) {
        warnings.push('Pmax TDP inválida, se usó el default 86% de la potencia bruta');
        pmaxTdpHpNumber = null;
      }
      const hasUserPto = pmaxTdpHpNumber !== null;
      const ptoPowerHp = hasUserPto ? pmaxTdpHpNumber : enginePowerHp * 0.86;
      const ptoSource = hasUserPto
        ? 'ingresada por el usuario'
        : 'default 86% de la potencia bruta';

      resolve({
        success: true,
        data: {
          queryId: null,
          tractor: { brand: 'Manual', model: 'Input', hasTurbo },
          terrain: {
            name: 'Terreno ingresado',
            soilType: payload.soilType || 'loam',
            superficieRodadura: surface,
          },
          losses: {
            slopeLossHp: round2(slopePart),
            altitudeLossHp: round2(altLoss),
            rollingResistanceLossHp: round2(rollingPart),
            slippageLossHp: 0, // No se resta aparte: absorbido en la ET de Fig. 47
            transmissionLossHp: round2(transmissionLossHp),
            totalLossHp: round2(totalLossHp),
          },
          netPowerHp: round2(netPowerHp),
          enginePowerHp,
          efficiencyPercentage: round2(efficiencyPercentage),
          warnings,
          ptoPowerHp: round2(ptoPowerHp),
          ptoSource,
          // Detalle de la cadena v3 paso a paso (paridad con el backend)
          zoz: {
            soilCondition,
            tractorType: zozTractorType,
            tractionTypeDefaulted,
            warnings,
            pNHp: round2(pN),
            pAltHp: round2(altLoss),
            pTempHp: round2(tempLoss),
            pRodHp: round2(pRod),
            pEjeHp: round2(pEje),
            rho,
            rhoSurface: surface,
            rhoKind,
            alphaDeg: round2((Math.atan(slopePercent / 100) * 180) / Math.PI),
            ejeEfficiency: V3_NET_TO_AXLE_EFFICIENCY,
            et: round2(et),
            ptoPowerHp: round2(ptoPowerHp),
            ptoSource,
            rollingIncludedInEt: false, // En v3 la rodadura SÍ se resta aparte (P_ROD)
            slippageAbsorbed: true,
          },
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
 * Cn por textura para la rodadura del implemento (lámina 17 del profesor):
 * arena 10 · limo 20 · arcilla 20. Aplica al calcular R_r = (1,2/Cn + 0,04)·peso.
 */
const CN_LAMINA17 = { arena: 10, limo: 20, arcilla: 20 };

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
    payload.implementType !== 'personalizado' &&
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
      } else if (implementType === 'personalizado') {
        const tiro = Number(payload.tiro) || 0;
        const draftUnit = payload.draftUnit || 'kg/m';
        const nSurcos = Number(payload.nSurcos) || 1;
        detail.draftUnit = draftUnit;
        detail.tiro = tiro;
        if (draftUnit === 'kg/m') {
          powerKind = 'drawbar';
          powerRequiredHp = tiro * workingWidthM * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
        } else if (draftUnit === 'kg/surco') {
          powerKind = 'drawbar';
          powerRequiredHp = tiro * nSurcos * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
        } else if (draftUnit === 'cv/m') {
          powerKind = 'pto';
          powerRequiredHp = tiro * workingWidthM * 0.9863;
        } else if (draftUnit === 'hp_tdf/m') {
          powerKind = 'pto';
          powerRequiredHp = tiro * workingWidthM;
        }
      } else {
        const t = DIRECT_IMPLEMENT_RESISTANCE[implementType][soilIndex];
        detail.resistanceKgf = t;
        powerRequiredHp = t * workingWidthM * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
      }

      // Modelo F = R_syc + R_r (lám. 32/35 del profesor): si el implemento tiene
      // peso propio y es de tiro (drawbar), se suma su resistencia al rodamiento
      // R_r = (1,2/Cn + 0,04) · peso, con Cn por textura según la lámina 17
      // (arena 10 · limo 20 · arcilla 20). Aplica al implemento personalizado y
      // también a los de catálogo cuando se ingresa implementWeightKg.
      const implementWeightKg = Number(payload.implementWeightKg) || 0;
      if (powerKind === 'drawbar' && implementWeightKg > 0) {
        const implementCn = CN_LAMINA17[soil] ?? 20;
        const Rr = (1.2 / implementCn + 0.04) * implementWeightKg;
        const P_rr = Rr * workingSpeedKmh * DIRECT_IMPLEMENT_KGF_CONSTANT;
        powerRequiredHp += P_rr;
        detail.resistanceWeightKg = implementWeightKg;
        detail.implementCn = implementCn;
        detail.rollingResistanceHp = Math.round(P_rr * 100) / 100;
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
