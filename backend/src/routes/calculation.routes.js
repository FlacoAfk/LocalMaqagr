import { Router } from 'express';
import { calculatePowerLoss, calculateMinimumPower, calculateDirectPowerLoss, calculateDirectMinimumPower, calculateDirectImplementPower, calculateImplementPower, getCalculationHistory } from '../controllers/calculationController.js';
import { validatePowerLossRequest, validateImplementRequirement, validateDirectPowerLossRequest, validateDirectMinimumPowerRequest, validateDirectImplementPowerRequest, validateImplementPowerRequest } from '../middleware/calculationValidation.middleware.js';
import { verifyTokenMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

// ============================================
// RUTAS DE CÁLCULOS
// Base path: /api/calculations
// ============================================

/**
 * @swagger
 * /api/calculations/power-loss:
 *   post:
 *     summary: Calcular pérdidas de potencia
 *     description: |
 *       Calcula las pérdidas de potencia de un tractor en un terreno específico.
 *       
 *       **Factores de pérdida calculados:**
 *       - 🏔️ **Pendiente**: Pérdida por inclinación del terreno
 *       - 🌐 **Altitud**: Pérdida por altitud sobre el nivel del mar (densidad del aire)
 *       - 🔄 **Resistencia al rodamiento**: Según tipo de suelo (Índice de Cono ASABE D497.7)
 *       - 💨 **Deslizamiento**: Pérdida por patinaje de las ruedas
 *       
 *       El resultado se persiste en la base de datos con registro de auditoría.
 *     tags: [Calculations]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PowerLossRequest'
 *           example:
 *             tractor_id: 1
 *             terrain_id: 1
 *             working_speed_kmh: 7.5
 *             carried_objects_weight_kg: 500
 *             slippage_percent: 10
 *     responses:
 *       200:
 *         description: Cálculo de pérdidas de potencia realizado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/PowerLossResponse'
 *       400:
 *         description: Campos requeridos faltantes o datos inválidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               success: false
 *               message: "Faltan campos requeridos: tractor_id, terrain_id, working_speed_kmh"
 *       401:
 *         description: Token no proporcionado o inválido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Tractor o terreno no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             examples:
 *               tractorNoEncontrado:
 *                 summary: Tractor no existe
 *                 value:
 *                   success: false
 *                   message: "Tractor no encontrado"
 *               terrenoNoEncontrado:
 *                 summary: Terreno no existe
 *                 value:
 *                   success: false
 *                   message: "Terreno no encontrado"
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/power-loss', verifyTokenMiddleware, validatePowerLossRequest, calculatePowerLoss);

/**
 * @swagger
 * /api/calculations/direct-power-loss:
 *   post:
 *     summary: Calcular perdidas de potencia con datos manuales
 *     description: Flujo Tengo Tractor - acepta datos crudos sin IDs de DB. No requiere tractor_id ni terrain_id. No requiere login.
 *     tags: [Calculations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/DirectPowerLossRequest'
 *     responses:
 *       200:
 *         description: Calculo de perdidas de potencia realizado exitosamente
 *       400:
 *         description: Campos requeridos faltantes o datos invalidos
 *       500:
 *         description: Error interno del servidor
 */
router.post('/direct-power-loss', validateDirectPowerLossRequest, calculateDirectPowerLoss);

/**
 * @swagger
 * /api/calculations/direct-minimum-power:
 *   post:
 *     summary: Calcular potencia minima con datos manuales
 *     description: Flujo Tengo Maquinaria - acepta datos crudos sin IDs de DB. No requiere implement_id ni terrain_id. No requiere login.
 *     tags: [Calculations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/DirectMinimumPowerRequest'
 *     responses:
 *       200:
 *         description: Calculo de potencia minima completado con recomendaciones
 *       400:
 *         description: Campos requeridos faltantes o datos invalidos
 *       500:
 *         description: Error interno del servidor
 */
router.post('/direct-minimum-power', validateDirectMinimumPowerRequest, calculateDirectMinimumPower);

/**
 * @swagger
 * /api/calculations/direct-implement-power:
 *   post:
 *     summary: Calcular potencia por implemento con datos manuales
 *     description: |
 *       Flujo manual (sin IDs de DB, sin login). Calcula la potencia requerida por el
 *       implemento según la "Tabla 1" de Chaparro (9 implementos, coeficientes por suelo:
 *       arena/limo/arcilla) y la disponible del tractor con la corrección Zoz & Grisso (2003).
 *
 *       Para implementos de TDF (implemento_rotativo) compara contra la potencia en la TDF;
 *       para implementos de tiro (drawbar) compara contra la potencia neta en la barra de tiro.
 *       El patinaje no se descuenta aparte: está absorbido en la pérdida de eje de Zoz.
 *     tags: [Calculations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/DirectImplementPowerRequest'
 *           example:
 *             implement_type: rastra_pesada_26
 *             working_width_m: 3
 *             working_speed_kmh: 7.5
 *             soil_type: arcilla
 *             engine_power_hp: 100
 *             traction_type: 4x2
 *             soil_condition: bueno
 *     responses:
 *       200:
 *         description: Calculo de potencia por implemento completado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/DirectImplementPowerResponse'
 *             examples:
 *               sinTractor:
 *                 summary: Sin engine_power_hp (solo potencia requerida)
 *                 value:
 *                   success: true
 *                   message: "Cálculo directo de potencia por implemento realizado con éxito"
 *                   data:
 *                     power_required_hp: 82.13
 *                     power_kind: drawbar
 *                     detail:
 *                       family: draft_per_meter
 *                       coefficient: 1000
 *                       working_width_m: 3
 *                       working_speed_kmh: 7.5
 *                       constant_used: T_RASTRA_PESADA_26
 *                     warnings: []
 *               conTractor:
 *                 summary: Con engine_power_hp (comparación + clasificación)
 *                 value:
 *                   success: true
 *                   message: "Cálculo directo de potencia por implemento realizado con éxito"
 *                   data:
 *                     power_required_hp: 82.13
 *                     power_kind: drawbar
 *                     available_power_hp: 47.1
 *                     pto_available_power_hp: 45.22
 *                     margin_hp: -35.03
 *                     is_adequate: false
 *                     classification: NO_ADECUADO
 *                     detail:
 *                       family: draft_per_meter
 *                       coefficient: 1000
 *                     warnings: []
 *                     losses:
 *                       total_loss_hp: 41.13
 *                     zoz:
 *                       soil_condition: bueno
 *                       tractor_type: 2WD
 *       400:
 *         description: Campos requeridos faltantes o datos invalidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/direct-implement-power', validateDirectImplementPowerRequest, calculateDirectImplementPower);

/**
 * @swagger
 * /api/calculations/minimum-power:
 *   post:
 *     summary: Calcular potencia mínima requerida
 *     description: |
 *       Calcula la potencia mínima requerida para operar un implemento agrícola en un terreno específico,
 *       y clasifica los tractores disponibles por compatibilidad.
 *       
 *       **Sistema de clasificación de tractores:**
 *       - 🟢 **OPTIMAL**: Potencia entre 100-125% de la requerida (ajuste perfecto)
 *       - 🟡 **OVERPOWERED**: Potencia >125% de la requerida (sobredimensionado pero compatible)
 *       - 🔴 **INSUFFICIENT**: Potencia insuficiente (no compatible)
 *       
 *       **Factores considerados:**
 *       - Requerimiento base del implemento (HP)
 *       - Profundidad de trabajo
 *       - Tipo de suelo
 *       - Pendiente del terreno
 *     tags: [Calculations]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/MinimumPowerRequest'
 *           example:
 *             implement_id: 1
 *             terrain_id: 1
 *             working_depth_m: 0.3
 *     responses:
 *       200:
 *         description: Cálculo de potencia mínima completado con recomendaciones de tractores
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/MinimumPowerResponse'
 *       400:
 *         description: Campos requeridos faltantes
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               success: false
 *               message: "Faltan campos requeridos: implement_id, terrain_id"
 *       401:
 *         description: Token no proporcionado o inválido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Implemento o terreno no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             examples:
 *               implementoNoEncontrado:
 *                 summary: Implemento no existe
 *                 value:
 *                   success: false
 *                   message: "Implemento no encontrado"
 *               terrenoNoEncontrado:
 *                 summary: Terreno no existe
 *                 value:
 *                   success: false
 *                   message: "Terreno no encontrado"
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/minimum-power', verifyTokenMiddleware, validateImplementRequirement, calculateMinimumPower);

/**
 * @swagger
 * /api/calculations/implement-power:
 *   post:
 *     summary: Calcular potencia por implemento con entidades de la BD
 *     description: |
 *       Flujo autenticado con tractor_id + terrain_id + (implement_id O parámetros
 *       explícitos del implemento). Calcula la potencia requerida según la "Tabla 1"
 *       de Chaparro y la disponible con la corrección Zoz & Grisso (2003), usando la
 *       tracción del tractor y la condición del suelo del terreno (fallback: 'medio').
 *
 *       Clasificación: ADECUADO (margen >= 0 y excedente <= 25%), SOBREPOTENCIADO
 *       (excedente > 25%) o NO_ADECUADO (margen negativo).
 *     tags: [Calculations]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ImplementPowerRequest'
 *           example:
 *             tractor_id: 1
 *             terrain_id: 1
 *             implement_id: 1
 *             working_speed_kmh: 7.5
 *     responses:
 *       200:
 *         description: Calculo de potencia por implemento completado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ImplementPowerResponse'
 *       400:
 *         description: Campos requeridos faltantes o datos invalidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       401:
 *         description: Token no proporcionado o inválido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Tractor, terreno o implemento no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/implement-power', verifyTokenMiddleware, validateImplementPowerRequest, calculateImplementPower);

/**
 * @swagger
 * /api/calculations/history:
 *   get:
 *     summary: Obtener historial de cálculos
 *     description: |
 *       Retorna el historial de cálculos realizados por el usuario autenticado.
 *       Soporta paginación y filtrado por tipo de cálculo.
 *     tags: [Calculations]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Número de página
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *           maximum: 100
 *         description: Registros por página (máximo 100)
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [power_loss, minimum_power]
 *         description: Filtrar por tipo de cálculo
 *     responses:
 *       200:
 *         description: Historial de cálculos obtenido exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       query_id:
 *                         type: integer
 *                       query_type:
 *                         type: string
 *                         enum: [power_loss, minimum_power]
 *                       query_date:
 *                         type: string
 *                         format: date-time
 *                       status:
 *                         type: string
 *                       tractor_name:
 *                         type: string
 *                       terrain_name:
 *                         type: string
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     currentPage:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 *                     totalItems:
 *                       type: integer
 *                     itemsPerPage:
 *                       type: integer
 *       401:
 *         description: Token no proporcionado o inválido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Error interno del servidor
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/history', verifyTokenMiddleware, getCalculationHistory);

export default router;
