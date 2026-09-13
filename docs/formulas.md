# Documento técnico de fórmulas y cálculos — MaqAgr

> **Propósito:** referencia completa de todas las fórmulas y cálculos que utiliza (o utilizó) cada proceso del software MaqAgr — relación tractor–implemento por potencia — incluyendo los modelos anteriores, los que los reemplazaron y la razón del cambio.
> **Fecha:** 2026-09-13 · **Estado del código:** implementado y verificado (540 tests unitarios; migración 007; corrección secuencial v2.1 revisada por pares y validada con los ejercicios del profesor en el sistema real).
> **Fuentes verificadas:** artículo del Prof. Chaparro (*Potencia en Máquinas Agrícolas*, Ing. e Investigación, UNAL), Zoz & Grisso (2003, *Traction and Tractor Performance*, ASAE Distinguished Lecture #27, Figs. 43 y 47), notas de clase manuscritas (incluida la corrección del 04/09/2026) y el código real del backend.

---

## 1. Los tres procesos del software

| Proceso | Flujo | Entrada | Salida |
|---|---|---|---|
| P1. Potencia disponible del tractor | "Tengo tractor" | Potencia del motor, peso, tracción, turbo; terreno (altitud, temperatura, pendiente, suelo) | Potencia neta real en campo y eficiencia |
| P2. Potencia requerida por el implemento | "Tengo maquinaria" | Implemento (tipo, ancho, profundidad, N de puntas, velocidad) y tipo de suelo | Potencia requerida (barra de tiro o TDF) |
| P3. Compatibilidad tractor–implemento | Matchmaker / comparación | P1 + P2 | Margen y clasificación (adecuado / no adecuado / sobrepotenciado) |
| P4. Recomendación y scoring | "No tengo nada" | Finca + presupuesto | Top de tractores con puntaje |

Constante de conversión usada en todo el sistema (SI): **1 HP = F(kgf) × V(km/h) / 274,4**, equivalente a **× 3,65×10⁻³**. Derivación de Chaparro (ec. 6): `F(lb)×V(mph)/375` con `×2,2 lb/kg` y `/1,609 km/h→mph` → `2,2/(1,609×375) = 1/274,26 ≈ 1/274,4`. Para el arado (ancho en m × profundidad en cm) la constante combinada es **0,365 = 100 × 3,65×10⁻³**.

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

### 2.2 Modelo corregido (v2.1 — `calculateTotalLossWithZoz`, activo cuando se envía `soil_condition`)

Base teórica: **Zoz & Grisso (2003), Fig. 43 (cadena de transmisión) y Fig. 47 (eficiencia de entrega al eje y a la TDF)**, que actualizan los valores fijos de Chaparro con mediciones por condición de suelo y tipo de tractor. La corrección manuscrita del profesor (04/09/2026) — **`ΔP_T = 0,215 + ET`** — es **notación comprimida de etapas secuenciales**, no dos fracciones paralelas de la potencia bruta:

```
P_eje        = (P_bruta − P_alt − P_temp) × 0,785          ← eficiencia bruta→eje (Fig. 43, rango 0,77–0,80)
P_disponible = P_eje × (1 − ET_eje) − P_pendiente           ← ET = pérdida eje→barra (Fig. 47)
P_tdf        = (P_bruta − P_alt − P_temp) × 0,785 × EFICIENCIA_TDF
```

En forma de pérdidas explícitas (equivalente): `ΔP_total = P_bruta × (0,215 + 0,785 × ET)`.

**Por qué ET se aplica sobre el eje y no sobre la bruta (verificado):** los valores de la Fig. 47 son eficiencia de entrega **eje→barra de tiro**. La prueba es aritmética: 2WD en concreto = 0,91 en la Fig. 47, pero la eficiencia bruta→eje sola (Fig. 43) es ≈ 0,78 — si 0,91 incluyera la transmisión sería imposible. Son etapas secuencialmente compuestas: `0,785 × 0,75 = 0,589 ≡ pérdida total 0,215 + 0,785 × 0,25 = 0,411`.

**Rodamiento y patinamiento ya están dentro de ET:** la definición de E.T. de Chaparro lo dice explícitamente (*"se presentan diversos factores que producen pérdidas en la tracción (p. e. patinamiento, resistencia al rodamiento, fricción, etc.)"*). Por eso en v2 **no se resta** `P_rod = μr·W·cosθ·V` — sería doble conteo. La **pendiente sí se resta**: es una fuerza geométrica externa, no incluida en la Fig. 47.

- Las pérdidas atmosféricas se calculan igual que en v1 (1 %/300 m y 1 %/5 °C, solo aspirados, sobre bruta).
- Constantes configurables: `ZOZ_GROSS_TO_AXLE_EFFICIENCY = 0,785` (punto medio del rango 0,77–0,80 de Fig. 43) y `ZOZ_AXLE_LOSS` (tabla Fig. 47). Ambas marcadas para confirmación del profesor.
- `μr = 1,2/Cn + 0,04` y los valores Cn quedan **solo en el camino legacy** (v1); en v2 el rodamiento va dentro de ET.

**Tabla de pérdidas de entrega al eje (ET = 1 − eficiencia, Fig. 47; columnas: suelo bueno / medio / malo):**

| Tipo de tractor | Bueno | Medio | Malo |
|---|---:|---:|---:|
| 2WD (4x2) | 0,25 | 0,30 | 0,43 |
| MFWD (4x4 asistido) | 0,21 | 0,25 | 0,34 |
| 4WD (4x4 doble tracción) | 0,20 | 0,22 | 0,27 |
| Oruga (belt) | 0,15 | 0,17 | 0,19 |

Mapeo desde la base de datos (`tractor.traction_type`): `4x2 → 2WD`, `4x4 → 4WD`, `track/oruga → BELT`, `mfwd → MFWD`. Tracción no reconocida ⇒ 2WD con advertencia (`zoz.tractor_type_defaulted`).

**Tabla de eficiencia de entrega a la TDF (Fig. 47, fila PTO)** — para el implemento rotativo:

| Tipo de tractor | Bueno | Medio | Malo |
|---|---:|---:|---:|
| 2WD | 0,72 | 0,67 | 0,55 |
| MFWD | 0,76 | 0,72 | 0,64 |
| 4WD | 0,77 | 0,75 | 0,70 |
| Oruga | 0,76 | 0,74 | 0,72 |

**Ejemplo de verificación** (probado en el endpoint real): tractor 100 HP bruto, 4x2, suelo bueno, turbo (sin pérdidas atmosféricas), sin pendiente → `P_eje = 100 × 0,785 = 78,5 HP`; `P_disp = 78,5 × 0,75 = 58,88 HP`; `P_tdf = 78,5 × 0,72 = 56,52 HP`; pérdida total de transmisión+tracción = 41,1 % de la potencia tras atmosféricas.

> **Historial de corrección (v2.0 → v2.1):** la primera implementación aplicaba 0,215 y ET como fracciones paralelas sobre la bruta (`100 × (1 − 0,215 − 0,25) = 53,5 HP`) y además descontaba rodamiento aparte. Fue detectado en revisión por pares, verificado contra las Figs. 43/47 y la definición de E.T. de Chaparro, y corregido a la cadena secuencial (58,88 HP). El número 53,5 y cualquier valor derivado de versiones anteriores quedan obsoletos.

### 2.3 v1 vs v2 — por qué cambió

| Aspecto | v1 (legacy) | v2.1 (Zoz, corrección 04/09) |
|---|---|---|
| Transmisión | 13 % fijo sobre potencia tras atmosféricas | Cadena secuencial: `× 0,785` (bruta→eje, Fig. 43) y `× (1 − ET)` (eje→barra, Fig. 47, según suelo y tipo de tractor) |
| Rodamiento | `μr·W·cosθ·V` (usa Cn) | **No se resta**: ya está dentro de ET (definición E.T. de Chaparro) |
| Patinamiento | % manual sobre potencia restante | Absorbido en la pérdida de eje de Zoz |
| Pendiente | `W·sinθ·V` | Igual que v1 (fuerza geométrica externa, no está en Fig. 47) |
| TDF | No existía | `P_tdf = P_tras_atm × 0,785 × eficiencia TDF(suelo, tractor)` |
| Sensibilidad | Solo peso/velocidad/pendiente | Distingue 2WD/MFWD/4WD/oruga y suelo bueno/medio/malo |

---

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

Si no se envían datos del tractor, el endpoint devuelve solo la potencia requerida (con `power_kind: drawbar|pto`), para usarlo como calculadora independiente.

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
| Servicio de potencia por implemento | `backend/src/services/implementPowerService.js` |
| Pérdidas (legacy + Zoz) | `backend/src/services/powerLossService.js` |
| Potencia mínima (legacy) | `backend/src/services/minimumPowerService.js` |
| Controladores / rutas / validación | `calculationController.js`, `routes/calculation.routes.js`, `middleware/calculationValidation.middleware.js` |
| Endpoints nuevos | `POST /api/calculations/implement-power` (auth) · `POST /api/calculations/direct-implement-power` (público) |
| Migración | `backend/database/migrations/007_add_implement_power_fields.sql` (n_tines, soil_condition, has_turbo, CHECK query_type ampliado) |
| Frontend | `DatosImplemento.jsx` (9 aperos + N + resultados), `DatosTractor.jsx` (condición del suelo), `calculationApi.js` (API + mock con paridad verificada) |
| Modo real | `VITE_ENABLE_REMOTE_CALCULATION_API=true` en `frontend/.env` antes de compilar |

---

## 7. Supuestos y puntos con el profesor

1. **RESUELTO (v2.1):** la lectura de `ΔP_T = 0,215 + ET` es notación comprimida de la cadena secuencial `× 0,785 × (1 − ET)` — confirmada por la definición de la Fig. 47 (eje→barra) y la Fig. 43 (bruta→eje 0,77–0,80). Queda usar el punto medio **0,785** como constante configurable: confirmar con el profesor si prefiere otro valor del rango.
2. **Patinamiento:** absorbido en ET (criterio Zoz). El campo de patinamiento del formulario no tiene efecto en el camino v2; confirmar si se quiere conservar como término aparte o eliminarlo de la UI en modo v2.
3. **Rotativo:** desglose 16/24/32 reconstruido por patrón (Tabla 1 solo da el rango 16–32).
4. **Franco/loam:** mapeado a limo (la Tabla 1 no tiene franco).
5. **Tracción:** `4x4 → 4WD` (no existe MFWD en la base de datos; la tabla Zoz sí lo distingue).
6. **Margen de seguridad:** ¿se conserva 1,15 del modelo anterior o se adopta el factor de carga 0,80 de los ejercicios de Chaparro sobre el ancho?
7. **Cn (solo legacy):** el código usa 45/35/25/50/20 y la Tabla 2 de Chaparro dice 50/30/20/15. En v2 ya no interviene (el rodamiento va dentro de ET), pero confirmar si el camino legacy debe alinearse a la Tabla 2.

## 8. Trazabilidad de fuentes

- **Chaparro, J. M.** *Potencia en Máquinas Agrícolas*: ec. (6) `HPbt = F×V/274,4`; ec. (12) `CRR = 1,2/Cn + 0,04` y Tabla 2 de Cn (duro 50, firme 30, labrado 20, arenoso 15 — **difiere de los valores del código**, ver §7-punto pendiente adicional: unificar criterio de Cn); Fig. 8 (cadenas de eficiencia 0,96–0,98 → transmisión → 0,94–0,96 TDF / 0,85–0,89 barra); Tabla 1 (pg. 13); Ejercicio 3 (pg. 18, factor de carga 0,80, cadena `HPmotor = HPeje/(0,87×0,97)`).
- **Zoz & Grisso (2003)**: Fig. 43 (pg. 35: 0,91/0,92 bruta→neta; 0,77–0,80 bruta→eje; 0,99; 0,89–0,91; 0,85–0,90; 0,90–0,92; 0,96; 0,82–0,84 neta→TDF) y Fig. 47 (pg. 39: eficiencias de entrega al eje y a la TDF por tipo de tractor y condición de suelo).
- **Notas manuscritas de clase** (9 fotos): cascada de pérdidas, corrección 04/09/2026 `ΔP_T = 0,215 + ET` con remisión a la pg. 2-202 de Zoz & Grisso, tablas de coeficientes por implemento con desglose de suelo, derivación de la constante 0,365 y cuestionamiento del modelo de factores genéricos.
