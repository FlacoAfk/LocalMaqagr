# HANDOFF — Contexto completo del proyecto MaqAgr (para otra IA)

> Documento autocontenido generado el 2026-10-02. Contiene TODO el contexto
> de los chats de ZCode de los proyectos **localmaqagr** (app + catálogo +
> scraping + release) y **calculos mqagr** (validación de cálculos con el
> profesor). Una IA sin memoria previa puede continuar desde aquí.

---

## 1. Qué es MaqAgr

Aplicación full-stack de **cálculo de maquinaria agrícola** que corre 100% local
(sin nube): elige tractor + implemento + terreno y calcula potencia disponible
vs. requerida, con recomendaciones de compatibilidad.

- **Backend**: Node/Express + PostgreSQL + Redis(opcional), Swagger, JWT auth,
  roles. Sirve TODO en un puerto: SPA React + API + uploads.
- **Frontend**: React + Vite + Tailwind. Rutas: `/Calculadora`, `/TengoTractor`
  (flujo 4 pasos: Motor→Llantas→Clima→Resultados, con **ventana flotante
  "Buscar en catálogo"** que rellena los datos del tractor automáticamente),
  `/TengoMaquinaria`, `/BuscoEquipo`, `/Catalogo`, `/CatalogoTractor`,
  `/CatalogoMaquinas`, detalle `/tractor/:id` y `/maquinaria/:id`, panel admin.
- **Instalador Windows**: Inno Setup 6 (bundlea Node portable + PostgreSQL
  portable + app). CI de GitHub (`build-installer.yml`) compila el instalador
  en cada release publicado y adjunta `MaqAgr-Setup.exe`.
- **Repo**: https://github.com/FlacoAfk/LocalMaqagr — `main` en `6d13de0`,
  **release vigente v1.4.10** (la v1.4.5 verificada 20/20 queda como historial; la v1.4.0 a la v1.4.4 fueron retiradas).

## 2. Estado actual (cierre 2026-10-02)

| Componente | Estado |
|---|---|
| Release | **v1.4.10** con `MaqAgr-Setup.exe` compilado por CI ✓ |
| BD catálogo | **3.043 tractores + 291 implementos, CERO campos faltantes** |
| Prioritarios | 31 tractores curados con ficha oficial del fabricante (ordenan primero) |
| Fichas técnicas | **Solo enlaces** (`ficha_pdf_url`), sin PDFs embebidos |
| Imágenes | WebP 800px/q55 (~45 KB promedio) en `install-assets/uploads` |
| Versiones | 1.4.1 en `MaqAgr-Installer.iss` y los 3 `package.json` |
| Puerto 4000 | Backend del **repo** (`pnpm run start` en backend/, con nodemon) |

### Regla de calidad de BD (decisión del usuario, obligatoria)
«Si a un tractor/implemento le falta uno o varios datos, **búscalos** (fichas
JSON, PDFs de fichas técnicas); si no los encuentras, **bórralo**. Quiero una
BD sólida.» Ejecutado por `backend/scripts/scraping/solidify-db.js`
(re-ejecutable): completó 661 tractores + 11 implementos y **borró 746 + 9**.
Campos obligatorios — tractor: hp, peso, tiro, tracción (4x2/4x4/track),
llantas (tipo/ancho/diámetro), imagen; implemento: potencia, ancho, peso,
tipo, imagen. **Kubota MU4501 (4WD)** fue borrado por error y restaurado:
su llanta estaba en el PDF de su ficha (lección en §6).

## 3. Modelo de cálculo v3.1 (validado con el profesor) — de los chats "calculos mqagr"

Cadena de potencia disponible (v3 del profesor, v3.1 con patinamiento):

```
P_N    = 0,92 · P_B                                  (ecu. 27, bruta→neta)
P_ALT  = gate: solo si altitud > 300 m
P_TEMP = gate: solo si T > 15 °C, (T−15)/(5×100)
P_PAT  = patinamiento 12 % — va DENTRO del corchete
P_ROD  = W·V·(ρ·cosα + senα)/274,4   (ρ por superficie, lámina 26; arena_suelta=0,35)
P_EJE  = (P_N − P_ALT − P_TEMP − P_PAT − P_ROD) · 0,86   (0,86 = neta→eje)
P_BDT  = P_EJE · ET            (ET de Fig. 47 de Zoz & Grisso, columna AXLE)
```

- **Ejercicio H2 del profesor**: tractor 350 hp, 5500 kg, 1800 m, 18 °C, 8 %,
  4,5 km/h, ρ=0,35, arenoso/suelto → P_N=322, P_ALT=19,32, P_TEMP=1,93,
  P_ROD=38,72 (divisor **274**, no 274,4), **246,88 hp = Potencia Máxima TDP
  del tractor (dato del fabricante), NO un resultado de barra** — por eso
  supera P_EJE. Confirmado: 350×0,85×0,96 − 38,72 = 246,88 EXACTO (ecs. 28-29
  de Zoz & Grisso; 0,85=ec. 29 TDP, 0,96=ec. 28 TDP→eje).
- **P_BDT de la hoja está rotulado PBDT por el profesor**; no renombrar a TDP.
- **Pmax TDP es INPUT del usuario** (default 0,85·P_B si no lo da) e
  independiente de P_BDT calculada.
- **Patinamiento (12 % en H2) se resta DENTRO del corchete sobre P_N**:
  `P_EJE = (P_N − P_ALT − P_TEMP − P_PAT − P_ROD)·0,86` → H2 = 109,51 hp
  implementado, 603 tests verdes (decisión del usuario 2026-10-01).
- **ET (Fig. 47 Zoz & Grisso)**: eficiencia Axle→Drawbar por tipo/condición de
  suelo (multiplicada al final). Fig. 43: 0,92 bruta→neta; 0,86-0,92 eje.
- **Divisor de P_ROD = 274** (el manuscrito dice 274; 274,4 era redondeo).
- Sincronización de fórmulas: **unidireccional** `docs/formulas.md` ← código.
- **Lecturas previas corregidas**: P_ROD del H2 = **38,7 hp** (no 38,1); la
  cifra del corchete inferior de la hoja 1 es **300,8 hp**; el neto del
  ejemplo de clase con pendiente real (2,29° ≈ 4 %) es **40,73 HP** (la
  lámina 13 del deck tenía 41,16 con error grados-vs-porcentaje).
- **Implementos (Tabla 1 Chaparro)**: 9 tipos del catálogo
  (arado_disco_vertedera CL, subsolador T, arado_cincel, implemento_rotativo
  CV/m, rastrillos, rastras pesadas) con corrección por suelo y velocidad
  4-10 km/h; `soil_type` se normaliza a arena|limo|arcilla (franco→limo con
  warning). Unidades nuevas: kg/surco × N surcos (sembradoras), CV/m (TDF),
  y "Personalizado (tiro manual)".
- **Documentos generados** (en Downloads y repo): `docs/formulas.md` (fuente
  de verdad), `Preguntas_para_confirmar_con_el_profesor_MaqAgr_v3.docx` (con
  ecuaciones OMML), `Contexto_Verificacion_IA.md` (handoff de verificación
  para IA externa — ya ejecutada y verificada), deck
  `Documento_Formulas_MaqAgr.pptx` auditado (127 afirmaciones,
  contra-revisado, 20 correcciones, PASS 16/16).
- **Preguntas aún abiertas con el profesor**: el 0,92 en lámina 31,
  discrepancias ET, tiro de sembradora, origen del 0,86, el "246,88 como
  Pmax TDP" ya confirmado por la madrugada de Codex.

## 4. BD de catálogo (detalles)

- **Semilla**: `backend/database/03-supabase-data.sql` (pg_dump COPY, 0,63 MB)
  — el instalador la aplica en la primera ejecución. **Regenerar con
  pg_dump DESPUÉS de cualquier cambio en BD**:
  `C:\Program Files\MaqAgr\runtime\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5435 -U postgres -d maqagr_local --no-owner --no-privileges --no-comments`
  con `PGPASSWORD=postgres`.
- **prioridad BOOLEAN**: los 27-31 curados (ficha oficial fabricante en
  español: brochures CNH/Massey, fichas dieselkubota.com.co y
  dinissanmaquinaria.com) ordenan primero (`ORDER BY prioridad DESC` en
  Tractor.advancedSearch y getAvailable). Los curados sin datos hallables
  salieron del set según la regla de calidad.
- **Fichas por enlace**: tractor con prueba Nebraska → página del informe en
  UNL Digital Commons (`digitalcommons.unl.edu/<set>/<id>/` — NUNCA
  `cgi/viewcontent.cgi`: 403 anti-bot en clic frío); implemento → página
  del producto Baldan. Índice de pruebas cosechado vía **OAI-PMH**
  (`/do/oai/`, el buscador web da 403 a bots): 225 informes en
  `data/nebraska-dc-index.json`. Solo ~225 de ~600 pruebas están
  digitalizadas; el resto de modelos nunca tuvo prueba Nebraska.
- **Migraciones nuevas**: `009_add_ficha_pdf.sql` (VARCHAR 500, tractor e
  implement), `010_add_prioridad.sql` (BOOLEAN). También en `schema.sql`.
- **Enriquecimiento curado↔scraping**: si el modelo existe scrapeado, el
  curado aporta ficha/foto/hp/peso/turbo y el scrapeado tracción/llantas;
  si es nuevo, tracción inferida (4WD en el nombre → 4x4) y tiro estimado.
- **Datos de prueba del usuario en BD**: filas "Test Tractor Admin",
  "Tractor Direct Upload", "Test Implement Admin", "Rastra Pesada 26 QA" —
  se borraron en la solidificación por incompletas.

## 5. Toolkit de scraping (`backend/scripts/scraping/`, ver su README.md)

**Flujo completo (orden obligatorio):**
```
1. tractordata/run.js --urls=…          scraping TractorData (4 pág/modelo)
2. download-images.js                   fotos → WebP 800px/q55
3. import.js                            scraping → BD (upsert)
4. implementos/baldan.js                fichas Baldan (WooCommerce + sitemaps)
5. download-implement-images.js
6. import-implements.js
7. import-curados.js                    curados (ficha oficial, prioridad=TRUE)
8. extract-tires-from-pdf.js            llantas desde fichas PDF (pdf-parse)
9. validate-links.js --prioridad        auditoría por bytes mágicos
10. solidify-db.js                      completa lo buscable y BORRA lo faltante
```
- **TractorData.com**: robots abierto; ~4.102 modelos en 12 marcas; parser con
  fallbacks (Belt claimed para antiguos, PTO claimed para clásicos sin gross,
  foto grande por `max-width:100%`, pesos "Gear/Hydro/ROPS/2WD Shipping",
  etiqueta `&nbsp` = fila de continuación). Los gaps de llantas son REALES
  (~30% de las páginas tienen la tabla Tires vacía).
- **Baldan**: WooCommerce con sitemaps públicos (`product-sitemap1..4.xml`,
  241 fichas `/es/productos/`); TLS incompleto → descargar con `curl -k`;
  tabla de especificaciones con rowspan/colspan → `lib/table-grid.js`;
  1 registro por variante.
- **Imágenes WebP**: 800px/q55 con sharp (los escaneos viejos INFLAN con
  q75+); convertir desde buffer (reabrir el archivo recién escrito dispara
  lock del antivirus); renombrar .jpg→.webp exige
  `REPLACE(image_url,'.jpg','.webp')` en BD.
- **Curados**: dumps MySQL en `C:\Users\elkaw\Desktop\ProyectoAgricola\BD` con
  ORDEN DE COLUMNAS distinto por marca (Case IH/Kubota: potencia,peso,turbo,
  FOTO,FICHA; MF: potencia,peso,turbo,FICHA,FOTO; NH: peso,potencia,turbo,
  FICHA,FOTO) y turbo 'si/no' vs 1/0 vs NULL en peso.

## 6. Infraestructura local (crítico para operar)

- **BD dev = Postgres portable de la app instalada**: `C:\ProgramData\MaqAgr\pgdata`,
  puerto **5435** (backend/.env: postgres/postgres). **Muere cada pocas horas**
  (kill abrupto sin crash log). Rearrancar: `postgres.exe -D C:\ProgramData\MaqAgr\pgdata -p 5435`
  vía PowerShell `Start-Process -WindowStyle Hidden` (con `-NoNewWindow` muere
  al cerrar la consola padre) tras borrar un `postmaster.pid` rancio.
- Servicio Windows `postgresql-x64-18` en **5433** — NO es de MaqAgr, no tocar.
- **dotenv lee ./.env según cwd**: correr scripts con cwd=`backend/scripts/scraping/`;
  desde `backend/` carga el .env (5435). Desde la raíz falla.
- **Puerto 4000**: verificar SIEMPRE quién escucha antes de depurar
  (`Get-CimInstance Win32_Process -Filter "ProcessId=<pid>"`): puede ser el
  backend del repo (correcto) o la **app instalada** (backend viejo, sin CSP
  nueva ni ORDER BY prioridad) si el usuario rearrancó con
  `start-maqagr.bat`. La app instalada sirve frontend desde
  `C:\Program Files\MaqAgr\app\frontend-dist` e imágenes desde
  `C:\ProgramData\MaqAgr\uploads` (sincronizar ahí tras cada lote).
- **CSP**: `img-src 'self' data: https:` en `security.middleware.js` — sin
  `https:` el navegador bloqueaba TODA imagen externa (las /uploads locales
  sí pasaban; curl no ve la CSP, solo el navegador).
- `apiClient` del frontend convierte TODA respuesta a camelCase
  (`ficha_pdf_url`→`fichaPdfUrl`); los scripts de prueba que leen JSON crudo
  deben usar snake_case.
- Frontend muestra placeholder SOLO si `image_url` IS NULL; URL rota = ícono
  de imagen rota. `nodemon.json` ignora `uploads/**` y `scripts/scraping/**`.
- **El navegador embebido de ZCode (IAB) NO renderiza imágenes cross-origin
  en páginas** (ni siquiera el logo de Google via Image()/fetch; navegación
  directa sí funciona) — verificar imágenes externas por headers + bytes
  mágicos, nunca viéndolas en IAB.
- Tareas largas en background mueren en silencio si se apaga/apaga-reanuda la
  máquina: hacer los jobs reanudables (skip de existentes + caché en disco) y
  detectar muerte por mtime del log.

## 7. Frontend — puntos clave

- **Paginación server-side** (`Pagination.jsx`: elipsis, contador
  "Mostrando X–Y de Z", selector 12/24/48) integrada con el refactor
  `CatalogFilters` del compañero (props: filters/onFiltersChange/onClearFilters,
  EMPTY_CATALOG_FILTERS; en maquinaria `chipGroups=IMPLEMENT_WORK_TYPE_GROUPS`).
- El detalle (`TractorMachineDetail.jsx`) mapea con helper `pick(obj, …keys)`
  dual snake/camel y botón condicional de ficha ("Ficha técnica oficial (PDF)"
  tractores / "Ver ficha técnica del fabricante" implementos).
- Compilar: `pnpm build` en frontend/ → `frontend/dist` (el backend del repo
  lo sirve directamente; para la app instalada habría que copiar a
  `C:\Program Files\MaqAgr\app\frontend-dist` con UAC).

## 8. Pendientes conocidos (para la fase 2 "con calma")

1. Completar datos/fichas de los ~3.000 tractores scrapeados no prioritarios
   (el usuario quiere revisarlos con calma; hoy sólidos pero varios con tiro
   estimado y sin ficha oficial).
2. Enlaces Case IH de `assets.cnhindustrial.com` son INTERMITENTES (a veces
   302 → home de caseih.com) — reemplazar por páginas estables.
3. ~6 fotos de New Holland de lectura-specs.es dan 403 por hotlink — reemplazar
   por fotos de dinissanmaquinaria.
4. MF 5S: los brochures V24 de masseyferguson.com dieron 404 (ninguna versión
   V19-V25 existe) — buscar la URL vigente.
5. ~450 pruebas Nebraska existen pero no están digitalizadas en Digital
   Commons — alternativa: Wayback Machine (parcial, con rate-limit).
6. Probar H3 del profesor (faltan velocidad y tipo de tractor del enunciado).
7. `tire_pressure_psi`, `price`, `maintenance_cost_per_hour` quedan NULL
   (carga manual del admin; TractorData no los publica).

## 9. Mapa rápido de archivos

| Ruta | Qué es |
|---|---|
| `docs/formulas.md` | Fuente de verdad del modelo de cálculo |
| `backend/database/03-supabase-data.sql` | Semilla completa de BD (regenerar tras cambios) |
| `backend/database/schema.sql` + `migrations/009,010` | Esquema con ficha_pdf_url y prioridad |
| `backend/src/models/Tractor.js` | ORDER BY prioridad DESC + búsquedas |
| `backend/src/middleware/security.middleware.js` | CSP con img-src https |
| `backend/src/services/implementPowerService.js` | Tabla 1 Chaparro (potencia requerida) |
| `backend/scripts/scraping/` | Toolkit completo (ver su README.md) |
| `frontend/src/pages/catalog/` | Catálogos con CatalogFilters + Pagination |
| `frontend/src/pages/calculator/tractor/DatosTractor.jsx` | Ventana flotante "Buscar en catálogo" |
| `frontend/src/components/ui/Pagination.jsx` | Paginación reutilizable |
| `install-assets/uploads/` | Imágenes que empaqueta el instalador |
| `C:\Users\elkaw\Desktop\ProyectoAgricola\BD` | Dumps MySQL curados originales |

## 10. Comandos frecuentes

```bash
# Backend dev (puerto 4000)
cd backend && pnpm run start
# Frontend build
cd frontend && pnpm build
# Tests backend
cd backend && pnpm test
# Rearrancar Postgres portable (si 5435 no responde)
powershell -Command "Start-Process 'C:\Program Files\MaqAgr\runtime\pgsql\bin\postgres.exe' -ArgumentList '-D','C:\ProgramData\MaqAgr\pgdata','-p','5435' -WindowStyle Hidden"
# Regenerar semilla del instalador
PGPASSWORD=postgres "/c/Program Files/MaqAgr/runtime/pgsql/bin/pg_dump.exe" -h 127.0.0.1 -p 5435 -U postgres -d maqagr_local --no-owner --no-privileges --no-comments -f backend/database/03-supabase-data.sql
# Release: push del tag + gh release create vX.Y.Z (el CI adjunta el instalador)
```
