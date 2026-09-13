/**
 * @overview Servicio de cálculo de pérdidas de potencia en tractores
 * @module services/powerLossService
 */

// CONSTANTES FÍSICAS (Paper & Tesis)

const CONSTANTS = {
  /** Divisor de conversión métrica a HP (kgf*m/s -> HP) */
  HP_CONVERSION_FACTOR: 274.4,
  
  /** Temperatura base de referencia en °C */
  BASE_TEMPERATURE_C: 15,
  
  /** Pérdida porcentual por cada 5°C sobre temperatura base */
  TEMP_LOSS_PER_5C: 1,
  
  /** Altitud de referencia (nivel del mar) en metros */
  BASE_ALTITUDE_M: 0,
  
  /** Pérdida porcentual por cada 300m sobre nivel del mar */
  ALTITUDE_LOSS_PER_300M: 1,
  
  /** Factor de pérdida por transmisión mecánica (default 13%) */
  DEFAULT_TRANSMISSION_LOSS: 0.13,
  
  /** Gravedad estándar (implícita en kgf) */
  GRAVITY_KGF: 1, // 1 kgf = 1 kg * g
};

// FUNCIONES AUXILIARES DE CONVERSIÓN

/**
 * Convierte grados a radianes
 * @param {number} degrees - Ángulo en grados
 * @returns {number} Ángulo en radianes
 */
export const degreesToRadians = (degrees) => {
  return degrees * (Math.PI / 180);
};

/**
 * Convierte radianes a grados
 * @param {number} radians - Ángulo en radianes
 * @returns {number} Ángulo en grados
 */
export const radiansToDegrees = (radians) => {
  return radians * (180 / Math.PI);
};

/**
 * Convierte porcentaje de pendiente a grados
 * @param {number} slopePercent - Pendiente en porcentaje (ej: 10 para 10%)
 * @returns {number} Ángulo en grados
 */
export const slopePercentToDegrees = (slopePercent) => {
  return radiansToDegrees(Math.atan(slopePercent / 100));
};

/**
 * Convierte grados a porcentaje de pendiente
 * @param {number} degrees - Ángulo en grados
 * @returns {number} Pendiente en porcentaje
 */
export const degreesToSlopePercent = (degrees) => {
  return Math.tan(degreesToRadians(degrees)) * 100;
};

/**
 * Convierte velocidad de km/h a m/s
 * @param {number} speedKmh - Velocidad en km/h
 * @returns {number} Velocidad en m/s
 */
export const kmhToMs = (speedKmh) => {
  return speedKmh / 3.6;
};

// FUNCIONES DE CÁLCULO DE PÉRDIDAS

/**
 * Calcula la pérdida de potencia por altitud
 * Descuenta 1% por cada 300m sobre el nivel del mar
 * Solo aplica para tractores aspirados (sin turbo).
 * Tractores turboalimentados compensan la pérdida de densidad del aire.
 *
 * @param {number} enginePower - Potencia del motor en HP
 * @param {number} altitudeMeters - Altitud sobre nivel del mar en metros
 * @param {boolean} hasTurbo - Si el tractor tiene turbocompresor
 * @returns {number} Potencia perdida por altitud en HP
 *
 * @example
 * // A 1500m de altitud con motor de 100 HP (aspirado)
 * calculateAltitudeLoss(100, 1500, false) // -> 5 HP (5% de pérdida)
 * // Con turbo: sin pérdida
 * calculateAltitudeLoss(100, 1500, true) // -> 0 HP
 */
export const calculateAltitudeLoss = (enginePower, altitudeMeters, hasTurbo = false) => {
  // Tractores turboalimentados compensan la pérdida de densidad del aire
  if (hasTurbo) {
    return 0;
  }

  if (altitudeMeters <= CONSTANTS.BASE_ALTITUDE_M) {
    return 0;
  }

  const lossPercent = (altitudeMeters / 300) * CONSTANTS.ALTITUDE_LOSS_PER_300M;
  return enginePower * (lossPercent / 100);
};

/**
 * Calcula la pérdida de potencia por temperatura
 * Descuenta 1% por cada 5°C sobre 15°C
 * Solo aplica para tractores aspirados (sin turbo).
 * Tractores turboalimentados compensan la menor densidad del aire caliente.
 *
 * @param {number} enginePower - Potencia del motor en HP
 * @param {number} temperatureC - Temperatura ambiente en °C
 * @param {boolean} hasTurbo - Si el tractor tiene turbocompresor
 * @returns {number} Potencia perdida por temperatura en HP
 *
 * @example
 * // A 35°C con motor de 100 HP (aspirado)
 * calculateTemperatureLoss(100, 35, false) // -> 4 HP (4% de pérdida por 20°C sobre base)
 * // Con turbo: sin pérdida
 * calculateTemperatureLoss(100, 35, true) // -> 0 HP
 */
export const calculateTemperatureLoss = (enginePower, temperatureC, hasTurbo = false) => {
  // Tractores turboalimentados compensan la menor densidad del aire caliente
  if (hasTurbo) {
    return 0;
  }

  if (temperatureC <= CONSTANTS.BASE_TEMPERATURE_C) {
    return 0;
  }

  const tempDiff = temperatureC - CONSTANTS.BASE_TEMPERATURE_C;
  const lossPercent = (tempDiff / 5) * CONSTANTS.TEMP_LOSS_PER_5C;
  return enginePower * (lossPercent / 100);
};

/**
 * Calcula la pérdida de potencia por transmisión mecánica
 * Aplica un factor de pérdida mecánica (default 13%)
 * 
 * @param {number} netEnginePower - Potencia neta del motor en HP
 * @param {number} [transmissionLossFactor=0.13] - Factor de pérdida (0-1)
 * @returns {number} Potencia perdida por transmisión en HP
 * 
 * @example
 * calculateTransmissionLoss(100) // -> 13 HP con factor default
 * calculateTransmissionLoss(100, 0.15) // -> 15 HP con factor custom
 */
export const calculateTransmissionLoss = (
  netEnginePower,
  transmissionLossFactor = CONSTANTS.DEFAULT_TRANSMISSION_LOSS
) => {
  return netEnginePower * transmissionLossFactor;
};

/**
 * Calcula el coeficiente de rodadura del suelo
 * Basado en el número de cono del suelo (Cn)
 * 
 * @param {number} soilCn - Número de cono del suelo (índice de penetración)
 * @returns {number} Coeficiente de rodadura (adimensional)
 */
export const calculateRollingCoefficient = (soilCn) => {
  // Fórmula empírica: μr = 1.2/Cn + 0.04
  // Para suelos más blandos (Cn bajo), mayor resistencia
  return (1.2 / soilCn) + 0.04;
};

/**
 * Calcula la pérdida de potencia por resistencia a la rodadura
 * Incluye componente del coseno del ángulo para mayor precisión
 * 
 * @param {number} totalWeightKg - Peso total del tractor en kg
 * @param {number} soilCn - Número de cono del suelo (índice de penetración)
 * @param {number} slopePercent - Pendiente del terreno en porcentaje
 * @param {number} speedKmh - Velocidad de desplazamiento en km/h
 * @returns {number} Potencia perdida por rodadura en HP
 * 
 * @example
 * // Tractor de 5000kg en suelo con Cn=50, pendiente 10%, a 8 km/h
 * calculateRollingResistanceHP(5000, 50, 10, 8)
 */
export const calculateRollingResistanceHP = (
  totalWeightKg,
  soilCn,
  slopePercent,
  speedKmh
) => {
  // Calcular ángulo de pendiente
  const slopeDegrees = slopePercentToDegrees(slopePercent);
  const slopeRadians = degreesToRadians(slopeDegrees);
  
  // Calcular coeficiente de rodadura
  const rollingCoef = calculateRollingCoefficient(soilCn);
  
  // Fuerza normal = W * cos(θ) [en kgf ya que W está en kg y g=1 kgf/kg]
  const normalForce = totalWeightKg * Math.cos(slopeRadians);
  
  // Fuerza de resistencia a la rodadura = μr * Fn
  const rollingResistanceForce = rollingCoef * normalForce;
  
  // Velocidad en m/s
  const speedMs = kmhToMs(speedKmh);
  
  // Potencia = Fuerza * Velocidad (kgf*m/s)
  const powerKgfMs = rollingResistanceForce * speedMs;
  
  // Convertir a HP usando el factor 274.4
  return powerKgfMs / CONSTANTS.HP_CONVERSION_FACTOR;
};

/**
 * Calcula la pérdida de potencia por pendiente (componente gravitacional)
 * Calcula la fuerza componente del peso W*sin(θ)
 * 
 * @param {number} totalWeightKg - Peso total del tractor en kg
 * @param {number} slopePercent - Pendiente del terreno en porcentaje
 * @param {number} speedKmh - Velocidad de desplazamiento en km/h
 * @returns {number} Potencia perdida por pendiente en HP
 * 
 * @example
 * / Tractor de 5000kg en pendiente 15% a 6 km/h
 * calculateSlopeLossHP(5000, 15, 6)
 */
export const calculateSlopeLossHP = (totalWeightKg, slopePercent, speedKmh) => {
  // Si la pendiente es 0 o negativa (bajada), no hay pérdida
  if (slopePercent <= 0) {
    return 0;
  }
  
  // Calcular ángulo de pendiente
  const slopeDegrees = slopePercentToDegrees(slopePercent);
  const slopeRadians = degreesToRadians(slopeDegrees);
  
  // Fuerza componente gravitacional = W * sin(θ) [en kgf]
  const slopeForce = totalWeightKg * Math.sin(slopeRadians);
  
  // Velocidad en m/s
  const speedMs = kmhToMs(speedKmh);
  
  // Potencia = Fuerza * Velocidad (kgf*m/s)
  const powerKgfMs = slopeForce * speedMs;
  
  // Convertir a HP usando el factor 274.4
  return powerKgfMs / CONSTANTS.HP_CONVERSION_FACTOR;
};

/**
 * Calcula la potencia "desperdiciada" por patinaje de las ruedas
 * 
 * @param {number} powerAvailable - Potencia disponible en HP
 * @param {number} slippagePercent - Porcentaje de patinaje (0-100)
 * @returns {number} Potencia perdida por patinaje en HP
 * 
 * @example
 * / Con 80 HP disponibles y 15% de patinaje
 * calculateSlippageLossHP(80, 15) // -> 12 HP perdidos
 */
export const calculateSlippageLossHP = (powerAvailable, slippagePercent) => {
  if (slippagePercent <= 0) {
    return 0;
  }
  
  return powerAvailable * (slippagePercent / 100);
};

// FUNCIÓN ORQUESTADORA PRINCIPAL

/**
 * Calcula todas las pérdidas de potencia y retorna el desglose completo
 *
 * @param {Object} params - Parámetros de entrada
 * @param {number} params.enginePower - Potencia nominal del motor en HP
 * @param {number} params.altitudeMeters - Altitud sobre nivel del mar en metros
 * @param {number} params.temperatureC - Temperatura ambiente en °C
 * @param {number} params.totalWeightKg - Peso total del tractor en kg
 * @param {number} params.soilCn - Número de cono del suelo
 * @param {number} params.slopePercent - Pendiente del terreno en porcentaje
 * @param {number} params.speedKmh - Velocidad de desplazamiento en km/h
 * @param {number} params.slippagePercent - Porcentaje de patinaje
 * @param {number} [params.transmissionLossFactor=0.13] - Factor de pérdida de transmisión
 * @param {boolean} [params.hasTurbo=false] - Si el tractor tiene turbocompresor
 *
 * @returns {Object} Objeto con desglose de pérdidas y potencia neta final
 * @returns {number} returns.grossPower - Potencia bruta del motor (HP)
 * @returns {Object} returns.losses - Desglose de pérdidas
 * @returns {number} returns.losses.altitude - Pérdida por altitud (HP)
 * @returns {number} returns.losses.temperature - Pérdida por temperatura (HP)
 * @returns {number} returns.losses.transmission - Pérdida por transmisión (HP)
 * @returns {number} returns.losses.rollingResistance - Pérdida por rodadura (HP)
 * @returns {number} returns.losses.slope - Pérdida por pendiente (HP)
 * @returns {number} returns.losses.slippage - Pérdida por patinaje (HP)
 * @returns {number} returns.losses.total - Total de pérdidas (HP)
 * @returns {number} returns.netPower - Potencia neta disponible para trabajo (HP)
 * @returns {number} returns.efficiency - Eficiencia total (%)
 * @returns {boolean} returns.hasTurbo - Si el tractor tiene turbo
 *
 * @example
 * const result = calculateTotalLoss({
 *   enginePower: 120,
 *   altitudeMeters: 2000,
 *   temperatureC: 30,
 *   totalWeightKg: 6000,
 *   soilCn: 45,
 *   slopePercent: 12,
 *   speedKmh: 7,
 *   slippagePercent: 10,
 *   hasTurbo: false  // Tractor aspirado: pérdidas atmosféricas SÍ aplican
 * });
 */
export const calculateTotalLoss = ({
  enginePower,
  altitudeMeters,
  temperatureC,
  totalWeightKg,
  soilCn,
  slopePercent,
  speedKmh,
  slippagePercent,
  transmissionLossFactor = CONSTANTS.DEFAULT_TRANSMISSION_LOSS,
  hasTurbo = false,
}) => {
  // 1. Pérdidas atmosféricas (solo para tractores aspirados — sin turbo)
  // Según Chaparro: altitud y temperatura "solo para tractores aspirados"
  const altitudeLoss = calculateAltitudeLoss(enginePower, altitudeMeters, hasTurbo);
  const temperatureLoss = calculateTemperatureLoss(enginePower, temperatureC, hasTurbo);
  
  // Potencia después de pérdidas atmosféricas
  const powerAfterAtmospheric = enginePower - altitudeLoss - temperatureLoss;
  
  // 2. Pérdida por transmisión (sobre potencia ajustada)
  const transmissionLoss = calculateTransmissionLoss(
    powerAfterAtmospheric,
    transmissionLossFactor
  );
  
  // Potencia en el eje de las ruedas
  const powerAtWheels = powerAfterAtmospheric - transmissionLoss;
  
  // 3. Pérdidas mecánicas del terreno
  const rollingResistanceLoss = calculateRollingResistanceHP(
    totalWeightKg,
    soilCn,
    slopePercent,
    speedKmh
  );
  
  const slopeLoss = calculateSlopeLossHP(totalWeightKg, slopePercent, speedKmh);
  
  // Potencia disponible antes de patinaje
  const powerBeforeSlippage = powerAtWheels - rollingResistanceLoss - slopeLoss;
  
  // 4. Pérdida por patinaje
  const slippageLoss = calculateSlippageLossHP(
    Math.max(0, powerBeforeSlippage),
    slippagePercent
  );
  
  // Potencia neta final
  const netPower = Math.max(0, powerBeforeSlippage - slippageLoss);
  
  // Total de pérdidas
  const totalLosses =
    altitudeLoss +
    temperatureLoss +
    transmissionLoss +
    rollingResistanceLoss +
    slopeLoss +
    slippageLoss;
  
  // Eficiencia
  const efficiency = (netPower / enginePower) * 100;
  
  return {
    grossPower: enginePower,
    hasTurbo,
    losses: {
      altitude: parseFloat(altitudeLoss.toFixed(2)),
      temperature: parseFloat(temperatureLoss.toFixed(2)),
      transmission: parseFloat(transmissionLoss.toFixed(2)),
      rollingResistance: parseFloat(rollingResistanceLoss.toFixed(2)),
      slope: parseFloat(slopeLoss.toFixed(2)),
      slippage: parseFloat(slippageLoss.toFixed(2)),
      total: parseFloat(totalLosses.toFixed(2)),
    },
    netPower: parseFloat(netPower.toFixed(2)),
    efficiency: parseFloat(efficiency.toFixed(2)),
  };
};

// ============================================
// CORRECCIÓN ZOZ & GRISSO (2003) — Cadena secuencial de entrega de potencia
// Ruta corregida: reemplaza el % de transmisión fijo + patinaje separado por
// la cadena secuencial bruta → eje → barra de tiro:
//   P_eje = (P_bruta − alt − temp) × η_bruta_eje   (Fig. 43 de Zoz & Grisso)
//   P_barra = P_eje × (1 − ET) − P_pendiente       (Fig. 47 de Zoz & Grisso)
// La E.T. de la Fig. 47 ya incluye patinamiento, resistencia a la rodadura y
// fricción (definición de E.T. de Chaparro): ni el patinaje ni la rodadura se
// descuentan aparte. La pendiente sí (fuerza geométrica externa).
// El flujo legacy (calculateTotalLoss) se mantiene intacto.
// ============================================

/** Normaliza la condición del suelo a los valores de la Fig. 47 (bueno|medio|malo, default medio) */
const normalizeSoilCondition = (soilCondition) => {
  const normalized = String(soilCondition ?? '').toLowerCase().trim();
  return ['bueno', 'medio', 'malo'].includes(normalized) ? normalized : 'medio';
};

// CONSTANTES ZOZ & GRISSO (para testing/debugging)

/**
 * Pérdida interna del tren de potencia bruta→eje (1 − 0,785, rango 0,77–0,80
 * de Fig. 43 de Zoz & Grisso). Se aplica secuencialmente ANTES de la pérdida
 * de entrega eje→barra (Fig. 47): P_eje = P_post_atmosférica × (1 − 0,215).
 */
export const ZOZ_FIXED_DRIVETRAIN_LOSS = 0.215;

/**
 * Eficiencia bruta→eje (Fig. 43 de Zoz & Grisso, rango 0,77–0,80). Etapa secuencial previa a la pérdida de entrega eje→barra (Fig. 47).
 */
export const ZOZ_GROSS_TO_AXLE_EFFICIENCY = 0.785;

/**
 * Pérdida de entrega de potencia eje→barra de tiro (1 − eficiencia de tracción,
 * Fig. 47 de Zoz & Grisso). Incluye patinamiento, resistencia a la rodadura y
 * fricción (definición de E.T. de Chaparro): por eso la ruta Zoz NO aplica el
 * % de patinaje ni la rodadura aparte.
 * Filas: 2WD / MFWD / 4WD / BELT. Columnas: condición del suelo [bueno, medio, malo].
 */
export const ZOZ_AXLE_LOSS = {
  '2WD': { bueno: 0.25, medio: 0.3, malo: 0.43 },
  MFWD: { bueno: 0.21, medio: 0.25, malo: 0.34 },
  '4WD': { bueno: 0.2, medio: 0.22, malo: 0.27 },
  BELT: { bueno: 0.15, medio: 0.17, malo: 0.19 },
};

/**
 * Eficiencia de entrega de potencia en la TDF (Fig. 47 de Zoz & Grisso).
 * Filas: 2WD / MFWD / 4WD / BELT. Columnas: condición del suelo [bueno, medio, malo].
 */
export const ZOZ_PTO_EFFICIENCY = {
  '2WD': { bueno: 0.72, medio: 0.67, malo: 0.55 },
  MFWD: { bueno: 0.76, medio: 0.72, malo: 0.64 },
  '4WD': { bueno: 0.77, medio: 0.75, malo: 0.7 },
  BELT: { bueno: 0.76, medio: 0.74, malo: 0.72 },
};

/**
 * Tipos de tracción reconocidos explícitamente por mapTractionTypeToZoz.
 * Cualquier otro valor (o ausencia) cae en 2WD con advertencia.
 */
const RECOGNIZED_TRACTION_TYPES = ['mfwd', '4x4', '4wd', 'track', 'oruga', 'belt', '4x2', '2wd'];

/**
 * Mapea el tipo de tracción del tractor a las filas de las tablas de Zoz & Grisso
 *
 * @param {string} tractionType - Tipo de tracción ('4x2', '2wd', 'mfwd', '4x4', '4wd', 'track', 'oruga', 'belt')
 * @returns {string} Tipo Zoz ('2WD' | 'MFWD' | '4WD' | 'BELT')
 *
 * @example
 * mapTractionTypeToZoz('4x2')   // -> '2WD'
 * mapTractionTypeToZoz('4x4')   // -> '4WD'
 * mapTractionTypeToZoz('oruga') // -> 'BELT'
 * mapTractionTypeToZoz('otro')  // -> '2WD' (default)
 */
export const mapTractionTypeToZoz = (tractionType) => {
  const normalized = String(tractionType ?? '').toLowerCase().trim();

  if (normalized === 'mfwd') return 'MFWD';
  if (normalized === '4x4' || normalized === '4wd') return '4WD';
  if (normalized === 'track' || normalized === 'oruga' || normalized === 'belt') return 'BELT';

  // '4x2', '2wd' y cualquier valor desconocido caen en 2WD
  return '2WD';
};

/**
 * Retorna la pérdida de eje (fracción) según condición del suelo y tipo de tractor (Fig. 47)
 *
 * @param {string} [soilCondition='medio'] - Condición del suelo ('bueno' | 'medio' | 'malo')
 * @param {string} tractorType - Tipo de tracción (se mapea con mapTractionTypeToZoz)
 * @returns {number} Pérdida de eje como fracción (ej: 0.25)
 *
 * @example
 * getAxleLossBySoilAndTractorType('bueno', '2WD') // -> 0.25
 * getAxleLossBySoilAndTractorType('malo', 'BELT') // -> 0.19
 */
export const getAxleLossBySoilAndTractorType = (soilCondition = 'medio', tractorType) => {
  const zozType = mapTractionTypeToZoz(tractorType);
  const condition = normalizeSoilCondition(soilCondition);
  return ZOZ_AXLE_LOSS[zozType][condition];
};

/**
 * Retorna la eficiencia de entrega en la TDF (fracción) según condición del suelo
 * y tipo de tractor (Fig. 47)
 *
 * @param {string} [soilCondition='medio'] - Condición del suelo ('bueno' | 'medio' | 'malo')
 * @param {string} tractorType - Tipo de tracción (se mapea con mapTractionTypeToZoz)
 * @returns {number} Eficiencia TDF como fracción (ej: 0.67)
 *
 * @example
 * getPtoEfficiencyBySoilAndTractorType('medio', '2WD') // -> 0.67
 */
export const getPtoEfficiencyBySoilAndTractorType = (soilCondition = 'medio', tractorType) => {
  const zozType = mapTractionTypeToZoz(tractorType);
  const condition = normalizeSoilCondition(soilCondition);
  return ZOZ_PTO_EFFICIENCY[zozType][condition];
};

/**
 * Calcula todas las pérdidas de potencia con la corrección Zoz & Grisso (2003)
 * Misma forma de salida que calculateTotalLoss, pero con la cadena secuencial:
 * - Bruta→eje: η = 0,785 (Fig. 43). Eje→barra: pérdida de entrega ET (Fig. 47)
 * - El patinaje NO se descuenta aparte: ya está incluido en la pérdida de eje (ET)
 * - La rodadura NO se descuenta aparte: también está dentro de la E.T. de Fig. 47
 * - La pendiente sí se descuenta (fuerza geométrica externa a la Fig. 47)
 *
 * @param {Object} params - Parámetros de entrada (mismos que calculateTotalLoss más:)
 * @param {string} params.tractorTractionType - Tipo de tracción del tractor ('4x2', '4x4', 'track', ...)
 * @param {string} [params.soilCondition='medio'] - Condición del suelo ('bueno' | 'medio' | 'malo')
 * @param {number} [params.slippagePercent] - Ignorado en la ruta Zoz (patinaje absorbido en ET)
 *
 * @returns {Object} Misma estructura que calculateTotalLoss más el objeto `zoz`
 * @returns {Object} returns.zoz - Detalle de la corrección Zoz & Grisso
 * @returns {string} returns.zoz.soil_condition - Condición del suelo normalizada
 * @returns {string} returns.zoz.tractor_type - Tipo de tractor Zoz (2WD|MFWD|4WD|BELT)
 * @returns {boolean} returns.zoz.tractor_type_defaulted - true si la tracción venía ausente/no reconocida
 * @returns {string[]} returns.zoz.warnings - Advertencias (tracción no reconocida asumida como 2WD)
 * @returns {number} returns.zoz.gross_to_axle_efficiency - Eficiencia bruta→eje (0.785, Fig. 43)
 * @returns {number} returns.zoz.axle_loss - Pérdida de entrega eje→barra ET (fracción, Fig. 47)
 * @returns {number} returns.zoz.internal_drivetrain_loss_hp - Pérdida bruta→eje (HP)
 * @returns {number} returns.zoz.traction_loss_hp - Pérdida de entrega eje→barra (HP)
 * @returns {number} returns.zoz.combined_drivetrain_loss - Pérdida total de tracción como fracción de la potencia post-atmosférica (1 − η_eje × (1 − ET))
 * @returns {number} returns.zoz.pto_efficiency - Eficiencia TDO/TDF (fracción)
 * @returns {number} returns.zoz.pto_power_hp - Potencia disponible en la TDF (HP)
 * @returns {boolean} returns.zoz.rolling_included_in_et - true: rodadura incluida en ET (no se descuenta aparte)
 * @returns {boolean} returns.zoz.slippage_absorbed - true: patinaje incluido en ET
 *
 * @example
 * // Tractor turbo de 80 HP, 2WD en suelo bueno, sin peso ni pendiente:
 * // net = 80 × 0,785 × (1 − 0,25) = 47.1 HP
 * calculateTotalLossWithZoz({
 *   enginePower: 80, altitudeMeters: 0, temperatureC: 15,
 *   totalWeightKg: 0, soilCn: 35, slopePercent: 0, speedKmh: 7.5,
 *   hasTurbo: true, tractorTractionType: '4x2', soilCondition: 'bueno',
 * });
 */
export const calculateTotalLossWithZoz = ({
  enginePower,
  altitudeMeters,
  temperatureC,
  totalWeightKg,
  soilCn, // Sin uso en esta ruta: la rodadura ya está incluida en la E.T. de Fig. 47
  slopePercent,
  speedKmh,
  slippagePercent, // Ignorado: el patinaje ya está absorbido en la pérdida de eje de Zoz (ET)
  tractorTractionType,
  soilCondition = 'medio',
  hasTurbo = false,
}) => {
  // 1. Pérdidas atmosféricas (igual que el flujo legacy, solo tractores aspirados)
  const altitudeLoss = calculateAltitudeLoss(enginePower, altitudeMeters, hasTurbo);
  const temperatureLoss = calculateTemperatureLoss(enginePower, temperatureC, hasTurbo);

  // Potencia después de pérdidas atmosféricas
  const powerAfterAtmospheric = enginePower - altitudeLoss - temperatureLoss;

  // 2. Cadena secuencial de entrega de potencia (Zoz & Grisso):
  //    bruta → eje (Fig. 43, η = 0,785) y eje → barra de tiro (Fig. 47, pérdida ET).
  //    La Fig. 47 es eje→barra: por eso se aplica sobre la potencia en el eje y
  //    no sobre la bruta.
  const zozTractorType = mapTractionTypeToZoz(tractorTractionType);
  const condition = normalizeSoilCondition(soilCondition);
  const axleLoss = ZOZ_AXLE_LOSS[zozTractorType][condition];

  const powerAtAxle = powerAfterAtmospheric * ZOZ_GROSS_TO_AXLE_EFFICIENCY;

  // Advertencia cuando la tracción viene ausente o no reconocida: se asumió 2WD
  const normalizedTraction = String(tractorTractionType ?? '').toLowerCase().trim();
  const tractionTypeDefaulted = !RECOGNIZED_TRACTION_TYPES.includes(normalizedTraction);
  const zozWarnings = tractionTypeDefaulted
    ? ['tipo de tracción no reconocido, se asumió 2WD']
    : [];

  // 3. Pendiente: fuerza geométrica externa, no incluida en la Fig. 47
  const slopeLoss = calculateSlopeLossHP(totalWeightKg, slopePercent, speedKmh);

  // Rodadura: ya viene dentro de la eficiencia de entrega eje→barra (E.T.);
  // se reporta en 0 para no duplicar el descuento en esta ruta.
  const rollingResistanceLoss = 0;

  // Potencia neta final en la barra de tiro (sin descuento separado de patinaje ni rodadura)
  const netPower = Math.max(0, powerAtAxle * (1 - axleLoss) - slopeLoss);

  // Desglose de la pérdida de tracción (HP):
  // - interna bruta→eje (0,215 de la potencia post-atmosférica)
  // - entrega eje→barra (ET sobre la potencia en el eje)
  const internalDrivetrainLossHp = powerAfterAtmospheric * ZOZ_FIXED_DRIVETRAIN_LOSS;
  const tractionLossHp = powerAtAxle * axleLoss;
  const combinedDrivetrainLossFraction =
    1 - ZOZ_GROSS_TO_AXLE_EFFICIENCY * (1 - axleLoss);
  const drivetrainLossHp = internalDrivetrainLossHp + tractionLossHp;

  // Total de pérdidas
  const totalLosses =
    altitudeLoss +
    temperatureLoss +
    drivetrainLossHp +
    rollingResistanceLoss +
    slopeLoss;

  // Eficiencia
  const efficiency = (netPower / enginePower) * 100;

  // Potencia disponible en la TDF según Fig. 47 (etapa bruta→eje incluida)
  const ptoEfficiency = ZOZ_PTO_EFFICIENCY[zozTractorType][condition];

  return {
    grossPower: enginePower,
    hasTurbo,
    losses: {
      altitude: parseFloat(altitudeLoss.toFixed(2)),
      temperature: parseFloat(temperatureLoss.toFixed(2)),
      transmission: parseFloat(drivetrainLossHp.toFixed(2)),
      rollingResistance: parseFloat(rollingResistanceLoss.toFixed(2)),
      slope: parseFloat(slopeLoss.toFixed(2)),
      slippage: 0, // Absorbido en la pérdida de eje (Zoz & Grisso)
      total: parseFloat(totalLosses.toFixed(2)),
    },
    netPower: parseFloat(netPower.toFixed(2)),
    efficiency: parseFloat(efficiency.toFixed(2)),
    zoz: {
      soil_condition: condition,
      tractor_type: zozTractorType,
      tractor_type_defaulted: tractionTypeDefaulted,
      warnings: zozWarnings,
      gross_to_axle_efficiency: ZOZ_GROSS_TO_AXLE_EFFICIENCY,
      axle_loss: axleLoss,
      internal_drivetrain_loss_hp: parseFloat(internalDrivetrainLossHp.toFixed(2)),
      traction_loss_hp: parseFloat(tractionLossHp.toFixed(2)),
      combined_drivetrain_loss: parseFloat(combinedDrivetrainLossFraction.toFixed(2)),
      pto_efficiency: ptoEfficiency,
      pto_power_hp: parseFloat((powerAtAxle * ptoEfficiency).toFixed(2)),
      rolling_included_in_et: true,
      slippage_absorbed: true,
    },
  };
};

// EXPORTACIÓN DE CONSTANTES (para testing/debugging)

export const getConstants = () => ({ ...CONSTANTS });
