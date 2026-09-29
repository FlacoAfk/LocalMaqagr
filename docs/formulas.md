# Documento técnico de fórmulas y cálculos — MaqAgr

> **Propósito:** referencia completa de todas las fórmulas y cálculos que utiliza (o utilizó) cada proceso del software MaqAgr — relación tractor–implemento por potencia — incluyendo los modelos anteriores, los que los reemplazaron y la razón del cambio.
> **Fecha:** 2026-10-01 · **Estado del código:** cadena v3 del profesor implementada y verificada (603 tests unitarios; migraciones 007 y 008; revisión con 4 lentes + contra-revisión independiente; mock del frontend en paridad exacta con el backend).
> **v3 = la cadena definitiva que dictó el profesor en la expo** (hojas H1/H2/H3 escaneadas + láminas 13, 21, 26, 27 de "Potencia disponible y requerida 2026-2").
> **Fuentes verificadas:** artículo del Prof. Chaparro (*Potencia en Máquinas Agrícolas*, Ing. e Investigación, UNAL), Zoz & Grisso (2003, *Traction and Tractor Performance*, ASAE Distinguished Lecture #27, Figs. 43 y 47), notas de clase manuscritas (incluida la corrección del 04/09/2026) y el código real del backend.

---

## 1. Los tres procesos del software

| Proceso | Flujo | Entrada | Salida |
|---|---|---|---|
| P1. Potencia disponible del tractor | "Tengo tractor" | Potencia del motor, peso, tracción, turbo; terreno (altitud, temperatura, pendiente, suelo) | Potencia neta real en campo y eficiencia |
| P2. Potencia requerida por el implemento | "Tengo maquinaria" | Implemento (tipo, ancho, profundidad, N de puntas, velocidad) y tipo de suelo | Potencia requerida (barra de tiro o TDF) |
| P3. Compatibilidad tractor–implemento | Matchmaker / comparación | P1 + P2 | Margen y clasificación (adecuado / no adecuado / sobrepotenciado) |
| P4. Recomendación y scoring | "No tengo nada" | Finca + presupuesto | Top de tractores con puntaje |

La fórmula v3 de potencia del tractor sigue el divisor **274** escrito en la ecuación limpia del profesor. Los cálculos legacy y los implementos conservan **274,4** (equivalente a **3,65×10⁻³**), según la conversión de Chaparro; no mezclar esas dos convenciones al comparar ejemplos.

---

## 2. P1 — Potencia disponible del tractor

### 2.1 Modelo anterior (v1 — implementado en `powerLossService.js`, sigue disponible)

Cascada secuencial sobre la potencia del motor:

1. **Altitud** (solo aspirados; turbo ⇒ 0): `P_alt = P_motor × (altitud_m / 300) × 0,01` → 1 % por cada 300 m s.n.m., aplicada sobre la potencia bruta.
2. **Temperatura** (solo aspirados): `P_temp = P_motor × ((T °C − 15) / 5) × 0,01` → 1 % por cada 5 °C sobre 15 °C, sobre la potencia bruta.
3. **Transmisión**: `P_transm = (P_bruta − P_alt − P_temp) × 0,13` → **13 % fijo**, aplicado sobre la potencia ya reducida por pérdidas atmosféricas.
4. **Rodamiento**: `μr = 1,2/Cn + 0,04`; `Fn = W × cos(θ)` con `θ = atan(pend% / 100)`; `P_rod = μr × Fn × V(km/h) / 3,6 / 274,4` (fuerza en kgf, velocidad convertida a m/s).
5. **Pendiente** (si p > 0): `P_pend = W × sin(θ) × V / 3,6 / 274,4`.
6. **Patinamiento**: `P_pat = P_restante × S` (S ingresado por el usuario; default backend 10 %, frontend modo simple 15 %).
7. Salida: `P_neta = máx(0, P_restante − P_pat)`; `eficiencia = P_neta / P_bruta × 100`.

Valores Cn del código (índice de cono, `getSoilCn`): arcilla 45 · franco 35 · arena 25 · firme 50 · suave 20 (default 35; los tipos `silt` y `rocky` caen al default).

**Observación del profesor (04/09/2026):** el 13 % fijo no depende del suelo ni del tipo de tractor y el manuscrito indica *"mejor bajar desde potencia bruta"* (la eficiencia 0,98 × 0,89 de la Fig. 8 de Chaparro ≈ 0,87 justifica el orden de magnitud, pero es una constante única). Se reemplaza por el modelo v2.

### 2.2 Cadena v3 — el modelo definitivo del profesor (expo del 2026-10, hojas H1/H2)

El profesor dictó la cadena completa en clase (hojas manuscritas escaneadas + láminas 13, 21, 26 y 27 de su presentación). Es la que el software ejecuta hoy cuando el body incluye `soil_condition`:

```
P_N   = 0,92 · P_B                                     ← P_B la ingresa el usuario (Fig. 43: bruta→neta)
P_ALT = (A / 300 m) · 1 % · P_N   — solo aspirados, solo si A > 300 m
P_TEMP= ((T − 15 °C) / 5 °C) · 1 % · P_N   — solo aspirados, solo si T > 15 °C
P_ROD = W · V · (ρ·cos α + sen α) / 274     ← rodamiento + pendiente JUNTOS (lám. 26/27)
P_EJE = (P_N − P_ALT − P_TEMP − P_ROD) · 0,86   ← 0,86 = punto medio neta→eje (Fig. 43: 0,84–0,88)
P_BDT = P_EJE · ET                     ← ET de la Fig. 47, MULTIPLICADA como eficiencia
```

- **0,92 y 0,86 sustituyen al 0,785 único**: el producto 0,92 × 0,86 = 0,791 cae dentro del rango bruta→eje 0,77–0,80 de la Fig. 43 — dos etapas con las pérdidas atmosféricas y la rodadura en medio.
- **La rodadura VUELVE y se resta antes del 0,86**, combinada con la pendiente: `P_ROD = W·V·(ρ·cos α + sen α)/274` (láminas 26/27 y ecuación limpia de la hoja). El patinamiento sigue sin restarse (tachado en H2) y queda como alerta cuando sale del rango ideal 7–15 % (lámina 21).
- **ρ por superficie** (lámina 26) reemplaza a Cn para el tractor — menú propio "Superficie de rodadura":

| Superficie | Llantas | Oruga |
|---|---:|---:|
| Concreto | 0,02–0,03 | N.A. |
| Carretable | 0,05 | 0,06 |
| Arcilloso húmedo | 0,10 | 0,07 |
| Arcilloso seco | 0,06–0,08 | 0,07 |
| Limoso | 0,20 | 0,10 |
| Arena suelta seca | **0,35** | 0,20 |

- **ET se multiplica como eficiencia**: se toma de la columna izquierda, **Axle Power Delivery Efficiency**, de la Fig. 47; la tabla derecha es PTO y no se usa como ET de barra. La app implementa las columnas GOOD/MED/POOR: 2WD 0,75/0,70/0,57 · MFWD 0,79/0,75/0,66 · 4WD 0,80/0,78/0,73 · Oruga 0,85/0,83/0,81. La columna CONC aún no tiene opción propia en el selector.
- **TDF (hoja H3):** la potencia disponible en la TDF es **la que ingresa el usuario** (`Pmax TDP`, "no siempre el 85 % de P_b"); si no se ingresa, la pantalla y la API estiman 0,86·P_B. Ingresar Pmax TDP manualmente no modifica P_B ni P_BDT. La columna PTO de la Fig. 47 es distinta de ET de barra.

**Ejemplo verificado en el software (H2 del profesor):** 350 HP aspirado, 5500 kg, 1800 msnm, 18 °C, pendiente 8 % (α = 4,57°), V = 4,5 km/h, 2WD/POOR, arena suelta (ρ = 0,35) → P_N 322 · P_ALT 19,32 · P_TEMP 1,93 · P_ROD 38,72 (la hoja anota 38,7) · P_EJE 225,35 · P_BDT (ET 0,57) = **128,45 HP**. La hoja anota 246,88 HP; excede P_EJE, así que no puede resultar de `P_BDT=P_EJE×ET` con una eficiencia ET ≤ 1. Confirmar con el profesor qué representa.

> **Historial:** v2.1 aplicaba `× 0,785 × (1 − ET)` sin paso 0,92 y sin restar rodadura (se asumía dentro de ET). El profesor la reemplazó con esta cadena explícita en su expo. El modelo v1 (13 % fijo) sigue disponible como camino legacy.

### 2.3 v1 vs v3 — por qué cambió

| Aspecto | v1 (legacy) | v3 (profesor, expo 2026-10) |
|---|---|---|
| Primer paso | Pérdidas atmosféricas sobre bruta | **P_N = 0,92·P_B** y todo lo demás sobre P_N |
| Transmisión | 13 % fijo | **0,86** sobre (P_N − alt − temp − P_ROD), punto medio neta→eje 0,84–0,88 |
| Rodamiento | μr = 1,2/Cn + 0,04 | **ρ por superficie** (lám. 26), combinado con la pendiente en P_ROD |
| Pendiente | Término aparte tras la transmisión | Dentro de P_ROD, antes del 0,86 |
| Patinamiento | % manual que resta | Absorbido en ET; **alerta** fuera de 7–15 % |
| Entrega final | (implícita en el 13 %) | **× ET** (Fig. 47, eficiencia según suelo × tracción) |
| TDF | No existía | **Pmax TDP ingresable** (default 0,86·P_B) |

## 3. P2 — Potencia requerida por el implemento

### 3.1 Modelo anterior (v1 — `minimumPowerService.js`, sigue disponible para compatibilidad)

```
HP_min = HP_base × F_suelo × F_pendiente × F_profundidad × 1,15
```

- `F_suelo`: arcilla 1,3 · franco 1,0 · arena 0,8 · rocoso 1,5
- `F_pendiente = 1 + (pend% / 100) × 0,5`
- `F_profundidad = profundidad_m / 0,25`
- Margen de seguridad 1,15. Luego filtra tractores con `engine_power_hp ≥ HP_min` y devuelve el top 5 por menor excedente.

**Observación del profesor (en clase, foto 13):** la fórmula quedó tachada con *"¿De dónde?"* y *"¿Fuente?"* sobre P_base, F_suelo, F_pendiente y F_profundidad: son factores genéricos sin fuente, ajenos a la Tabla 1 de Chaparro. **Se reemplaza** por el cálculo por implemento. (El margen 1,15 convive con el factor de carga 0,80 de los ejercicios de Chaparro — punto abierto, §7.)

### 3.2 Modelo nuevo (v2 — `implementPowerService.js`, Tabla 1 de Chaparro pg. 13)

Nueve implementos, dos familias:

**Familia A — implementos de tiro** (resultado en HP de barra de tiro):

| Implemento | Fórmula | Coeficientes (arena / limo / arcilla) |
|---|---|---|
| Arado de disco y vertedera | `P = a(m) × P(cm) × V(km/h) × CL × 0,365` | CL según Tabla 1 (abajo) |
| Subsolador | `P = T(kgf/cm) × N × P(cm) × V × 3,65×10⁻³` | 18 / 24 / 30 |
| Arado cincel | `P = T(kgf/cm) × N × P(cm) × V × 3,65×10⁻³` | 9 / 12 / 15 |
| Rastrillo simple de discos | `P = T(kgf/m) × A(m) × V × 3,65×10⁻³` | 75 / 113 / 150 |
| Rastrillo pulidor | ídem | 150 / 300 / 450 |
| Rastrillo californiano | ídem | 350 / 475 / 600 |
| Rastra pesada de discos 26" | ídem | 800 / 900 / 1000 |
| Rastra pesada de discos 24" | ídem | 700 / 800 / 900 |

**Coeficiente de labranza CL (kgf/cm²)** para el arado de disco y vertedera (Tabla 1; tiro = ancho × profundidad × CL):

| V (km/h) | Arena | Limo | Arcilla |
|---:|---:|---:|---:|
| 4,0 | 0,21 | 0,56 | 0,70 |
| 5,0 | 0,21 | 0,60 | 0,73 |
| 6,0 | 0,22 | 0,63 | 0,77 |
| 7,0 | 0,24 | 0,70 | 0,85 |
| 8,0 | 0,26 | 0,77 | 0,92 |
| 9,0 | 0,28 | 0,84 | 1,02 |
| 10,0 | 0,29 | 0,95 | 1,12 |

Velocidades intermedias: interpolación lineal entre filas; fuera de 4–10 km/h se toma el extremo con advertencia.

**Familia B — implemento rotativo (10 cm de profundidad)** (resultado en HP de toma de fuerza):

```
HP_tdf = demanda(HP tdf/m) × ancho(m)     demanda: 16 / 24 / 32 (arena / limo / arcilla)
```

El rango 16–32 HP tdf/m es textual de la Tabla 1; el desglose por suelo sigue el patrón mínimo/medio/máximo de los demás implementos (constante `FACTOR_IMPLEMENTO_ROTATIVO`, marcada para confirmación). La comparación contra el tractor se hace contra `P_tdf` (§2.2), **no** contra la barra de tiro.

### Modelo de fuerza del implemento y unidades nuevas (expo, láminas 19/32/35)

- **Fuerza total:** `F = R_syc + R_r` — a la fuerza de suelo y cultivo (`R_syc = tiro × ancho`) se suma la **rodadura propia del implemento con ruedas**: `R_r = (1,2/Cn + 0,04) × peso`, con Cn por textura de la **lámina 17** (duro 50 · firme 30 · labrado 20 · suelto/arenoso 10). Ejemplo de clase: sembradora 204 kg/surco × 4 surcos, peso 1700 kg, Cn 20 → R_r = 170 kg.
- **Potencia en barra:** `P_bdt = F × V / 274,4` (la lámina 32 usa /270 en CV — diferencia documentada como pregunta abierta).
- **Unidades nuevas aceptadas:** `kg/surco × N surcos` (sembradoras) y `CV/m` (implementos de TDF; 1 CV = 0,9863 HP), además de un tipo **Personalizado (tiro manual)** con el tiro que indique el usuario — reproduce el Ejercicio 1 completo (cincel 950 kg/m → 36,55 HP; aspersora 4,5 CV/m × 16 m → 71,01 HP tdf).
- **Conversión a TDP (lámina 19, ecuación verificada en el propio archivo):** `P_tdp = P_bdt / (0,96 × ET)` — 0,96 = eje↔TDP (Fig. 1 de Chaparro). Así un implemento de tiro se compara contra tractores evaluados por TDP.

**Casos de validación** (fijados en tests unitarios):

| Caso | Cálculo | Resultado |
|---|---|---:|
| Rastra 26" de 3 m, arcilloso, 7,5 km/h (Ej. 3 de Chaparro) | 1000×3 = 3000 kgf; 3000×7,5×3,65×10⁻³ | **82,13 HP** (Chaparro: 82 con /274,4) |
| Arado 3 m × 15 cm, arcilla, 4 km/h | 3×15×4×0,70×0,365 | **45,99 HP** |
| Subsolador limo, 3 puntas, 40 cm, 5 km/h | 24×3×40×5×3,65×10⁻³ | **52,56 HP** |
| Arado cincel arena, 5 puntas, 25 cm, 6 km/h | 9×5×25×6×3,65×10⁻³ | **24,64 HP** |
| Rotativo 2 m, arcilla | 32×2 | **64 HP tdf** |

Mapeo de suelos: `arena/sand/sandy → arena`; `limo/silt → limo`; `arcilla/clay → arcilla`; `franco/loam → limo` con advertencia (la Tabla 1 no tiene franco).

---

## 4. P3 — Compatibilidad tractor–implemento

**Antes:** el flujo "tengo maquinaria" filtraba `tractor.engine_power_hp ≥ HP_min` y clasificaba con `SUITABILITY_THRESHOLDS`: `INSUFFICIENT` si `tractorHP < requerido`; `OPTIMAL` si `tractorHP ≤ requerido × 1,25`; `OVERPOWERED` por encima.

**Ahora** (`POST /api/calculations/implement-power` y `/direct-implement-power`):

```
Disponible = P_neta (barra de tiro, §2.2)   o   P_tdf (§2.2) si el implemento es rotativo
Margen = Disponible − Requerida
Margen ≥ 0 → ADECUADO · Margen < 0 → NO_ADECUADO · Excedente > 25 % → SOBREPOTENCIADO
```

Si no se envían datos del tractor, el endpoint devuelve solo la potencia requerida (con `power_kind: drawbar|pto`), para usarlo como calculadora independiente. Con contexto de tractor, los implementos de tiro devuelven además `pto_equivalent_hp = P_bdt / (0,96 × ET)` para comparar contra la TDP del catálogo.

---

## 5. P4 — Recomendación y scoring (sin cambios en esta iteración)

`recommendationService.js` — motor determinista "El Matchmaker Agrícola":

- Pesos (modo estándar): eficiencia 30 · tracción 25 · suelo 20 · económico 15 · disponibilidad 10. Modo avanzado: power_match 40 · precio 30 · marca 20 · combustible 10.
- Clases de pendiente: plano < 5 % · ondulado 5–15 % · fuerte ≥ 15 %. **Regla de oro:** pendiente > 15 % exige 4x4 u oruga; arcilla húmeda (o arcilla + pendiente fuerte) exige oruga; 4x2 en pendiente fuerte −50 puntos.
- Bonificación por tracción: 4x4 {plano 5, ondulado 15, fuerte 25} · oruga {0, 20, 30} · 4x2 {10, 0, −50}.
- Dificultad de suelo: arena 20 · franco 40 · arcilla 70 · rocoso 85 · arcilla húmeda 95.
- Clasificación por utilización (`requerido/tractor`): ≥ 85 % OPTIMAL · ≥ 70 % GOOD · ≥ 50 % OVERPOWERED · < 50 % EXCESSIVE; umbral de sobrepotencia 1,3.

Teoría de respaldo documentada (diagrama de Zoz, tractor IH 886, prueba Nebraska 1339 — Cuadro 1 de Chaparro): E.T. concreto 0,91 · firme 0,76 · labrado 0,62 · arenoso 0,52; patinamiento 3,8/7,5/9/18 %. Fórmulas asociadas: `E.T. = HPbt / HPeje`, `C.T. = Tiro / PEET`, `Vsp = Vop / (1 − pat%)`.

---

## 6. Referencia de implementación

| Elemento | Ubicación |
|---|---|
| Servicio de potencia por implemento | `backend/src/services/implementPowerService.js` (Tabla 1 + R_r + personalizado + `computePtoEquivalent`) |
| Pérdidas (legacy + v3) | `backend/src/services/powerLossService.js` — `calculateTotalLossV3` es la ruta activa; `calculateTotalLoss` (legacy) y `calculateTotalLossWithZoz` (v2.1) quedan para compatibilidad |
| Potencia mínima (legacy) | `backend/src/services/minimumPowerService.js` |
| Controladores / rutas / validación | `calculationController.js`, `routes/calculation.routes.js`, `middleware/calculationValidation.middleware.js` |
| Endpoints nuevos | `POST /api/calculations/implement-power` (auth) · `POST /api/calculations/direct-implement-power` (público) |
| Migraciones | `007_add_implement_power_fields.sql` (n_tines, soil_condition, has_turbo, CHECK query_type) · `008_add_rodadura_surface.sql` (terrain.superficie_rodadura para el ρ) |
| Frontend | `DatosImplemento.jsx` (9 aperos + N + resultados), `DatosTractor.jsx` (condición del suelo), `calculationApi.js` (API + mock con paridad verificada) |
| Modo real | `VITE_ENABLE_REMOTE_CALCULATION_API=true` en `frontend/.env` antes de compilar |

---

## 7. Preguntas abiertas para el profesor (verificadas, cada una con el dato que falta)

1. **246,88 hp (hoja H2):** con la propia cadena, (300,8 − 38,7)·0,86 = 225,4 y ninguna ET de la Fig. 47 supera 1. ¿Qué ET o paso adicional usó?
2. **Altitud:** el 1 % ¿cuenta desde 0 m o desde 300 m? La fórmula escrita usa A/300 (a 1800 m → 6 % ✓), pero la nota dice "solo si A > 300 m" (a 500 m: ¿0,67 % o 1,67 %?). El software implementa la fórmula tal cual (desde 0, con el gate).
3. **Sembradora (lám. 35):** los datos dicen 204 kg/surco pero la fórmula usa 240 (y el "ajuste en clase" a 1130 kg) — ¿cuál vale?
4. **Constante de implementos:** la lámina 32 usa /270 con resultado en CV; las hojas de los 9 aperos usan 3,65×10⁻³ (≈ 274,4) en HP. El software usa 274,4/HP — ¿correcto?
5. **ET de la conversión a TDP:** el ejemplo de la lámina 32 usa ET = 0,484 (leída del diagrama de Zoz), no de la Fig. 47 (0,57–0,85). ¿Cuál debe usar el software?
6. **Cn:** la lámina 17 da arenoso = 10 (Chaparro Tabla 2: 15) — el software usa 10/20/20 para la rodadura del implemento (lám. 17 manda por ser lo último del profesor).
7. **Caso 2 (H3):** faltan velocidad y tipo de tractor para cerrarlo como caso de prueba.
8. **Pendiente de la lámina 13 vs el software:** el ejemplo de clase (42,9 → 40,73/41,16) anota pendiente en grados; el software la toma en % — el deck ya lo aclara.

## 7b. Estado de los supuestos anteriores

| Supuesto de la v2.1 | Estado en v3 |
|---|---|
| 0,785 punto medio de 0,77–0,80 | **Reemplazado**: el profesor lo descompone en 0,92 × 0,86 |
| Patinamiento absorbido en ET | **Confirmado por el profesor** (tachado en H2); queda como alerta 7–15 % |
| Rotativo 16/24/32 por patrón | Vigente (pregunta 3 del profesor pendiente) |
| franco → limo | Vigente |
| 4x4 → 4WD en la tabla Zoz | Vigente (la ET ahora se multiplica, no se resta) |
| Margen 1,15 vs factor de carga 0,80 | Pendiente (el 0,80 de Chaparro aplica sobre el ancho) |
| Cn 45/35/25/50/20 del código | **Reemplazado**: ρ por superficie para el tractor; Cn 50/30/20/10 (lám. 17) para la rodadura del implemento |

## 8. Trazabilidad de fuentes

- **Chaparro, J. M.** *Potencia en Máquinas Agrícolas*: ec. (6) `HPbt = F×V/274,4`; ec. (12) `CRR = 1,2/Cn + 0,04` y Tabla 2 de Cn (duro 50, firme 30, labrado 20, arenoso 15 — **difiere de los valores del código**, ver §7-punto pendiente adicional: unificar criterio de Cn); Fig. 8 (cadenas de eficiencia 0,96–0,98 → transmisión → 0,94–0,96 TDF / 0,85–0,89 barra); Tabla 1 (pg. 13); Ejercicio 3 (pg. 18, factor de carga 0,80, cadena `HPmotor = HPeje/(0,87×0,97)`).
- **Zoz & Grisso (2003)**: Fig. 43 (pg. 35: 0,91/0,92 bruta→neta; 0,77–0,80 bruta→eje; 0,99; 0,89–0,91; 0,85–0,90; 0,90–0,92; 0,96; 0,82–0,84 neta→TDF) y Fig. 47 (pg. 39: eficiencias de entrega al eje y a la TDF por tipo de tractor y condición de suelo).
- **Notas manuscritas de clase** (9 fotos): cascada de pérdidas, corrección 04/09/2026 `ΔP_T = 0,215 + ET` con remisión a la pg. 2-202 de Zoz & Grisso, tablas de coeficientes por implemento con desglose de suelo, derivación de la constante 0,365 y cuestionamiento del modelo de factores genéricos.
