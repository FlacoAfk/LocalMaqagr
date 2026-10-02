# Scraping de catálogo para MaqAgr

Toolkit para llenar las tablas `tractor` e `implement` con datos reales
(especificaciones, fichas técnicas e imágenes) extraídos de fuentes públicas.

**Sin dependencias externas** — usa `fetch` nativo de Node 18+.

## Nota legal

- Se extraen **datos factuales** (potencias, pesos, medidas) con atribución de
  fuente por registro (campo `fuente.licencia` en cada JSON).
- La compilación de TractorData.com tiene copyright propio: no redistribuir el
  volcado completo; usar como referencia del catálogo local.
- Las fotos descargadas pertenecen a sus autores (se guardan en
  `backend/uploads/tractors/`, que está fuera del control de versiones).
- robots.txt de TractorData permite el rastreo (`Allow: /`). Los fabricantes de
  implementos (Baldan, Tatu, Basso, Semeato…) usan SPAs o Cloudflare: para esos
  casos usar automatización de navegador y no forzar el acceso.

## Pipeline de tractores (TractorData.com) — probado de punta a punta

```bash
cd backend/scripts/scraping

# 1. Catálogo de modelos por marca (data/catalog/<marca>.txt)
node tractordata/catalog.js --brands=johndeere,massferg,ford,newholland,kubota,caseih,case,fiat,belarus,challenger,zetor,deutz
# slugs disponibles: johndeere massferg newholland kubota ford case caseih fiat
#                    belarus challenger caterpillar zetor deutz universal lamborghini same

# 2. Scraping (4 páginas por modelo; cachea HTML en data/cache/)
node tractordata/run.js --urls=data/catalog/massferg.txt --limit=50
node tractordata/run.js --url="https://www.tractordata.com/farm-tractors/…"   # un modelo
#   --delay=1200   más pausa entre peticiones
#   --force        re-procesa aunque exista el JSON

# 3. Imágenes → WebP comprimido (instalador-friendly)
node download-images.js            # [--dry-run] [--force] [--max-width=960] [--quality=65]

# 4. Importar a Postgres (upsert por brand+model, ejecutar desde backend/)
node scripts/scraping/import.js --dry-run
node scripts/scraping/import.js
```

Cada modelo queda en `data/tractors/<id>.json` con el registro para la BD **más
la ficha técnica cruda** (`specs.ficha_completa`: producción, motor,
transmisión, dimensiones, prueba Nebraska completa) y las URLs de origen.

### Mapeo y supuestos

| Campo BD | Fuente | Nota |
|---|---|---|
| `engine_power_hp` | "Engine (gross)" | clásicos sin gross → PTO claimed como proxy (`engine_power_source` lo indica) |
| `traction_type` | texto Mechanical | "two- or four-wheel drive" → 4x4 si hay filas 4WD (`traction_type_derivado`) |
| `traction_force_kn` | "Max pull" (prueba Nebraska) | si no hay prueba se estima: tiro ≈ 0,82·PTO / 6 km/h (`traction_force_estimado`) |
| `weight_kg` | filas de peso (dimensions) | preferencia Shipping de la tracción; etiquetas Gear/Hydro/ROPS soportadas |
| `tire_type/width/diameter` | neumático trasero | diámetro estimado (llanta + 2×flanco×0,85); formato métrico e imperial |
| `fuel_consumption_lph` | "Fuel use" de la prueba | |
| `price`, `tire_pressure_psi`, `maintenance_cost_per_hour` | — | TractorData no los publica: se dejan NULL para carga manual |

### Política de imágenes (restricción de instalador)

Todo lo que envía el instalador debe pesar poco. `download-images.js`:

1. Prefiere la **foto grande** de la ficha (`photo_url_large`, `<img style="max-width:100%">`);
   si el modelo solo tiene miniatura, usa la de 180px.
2. Convierte a **WebP máx 960px / calidad 65** con `sharp` (dep. de desarrollo del
   backend) → promedio ~70 KB por foto. Fallback sin sharp: JPEG q80/1200px vía
   System.Drawing de .NET. La conversión se hace desde el buffer en memoria:
   reabrir el archivo recién escrito dispara locks del antivirus en Windows.
3. Escribe en dos sitios: `install-assets/uploads/tractors/` (lo que empaqueta
   `MaqAgr-Installer.iss`) y `backend/uploads/tractors/` (servidor de desarrollo).

Proyección: 4.102 modelos × ~70 KB ≈ **290 MB** de imágenes si se envía el
catálogo completo — decidir alcance (marcas/modelos) antes de armar el
instalador. Las fotos antiguas de `install-assets` se re-comprimieron a JPEG
mozjpeg q72/960px manteniendo el nombre `.jpg` (compatibilidad con seeds previos).

Regenerar con datos nuevos es seguro: el importe hace upsert y no toca
`price` ni campos manuales.

## Pipeline de implementos — Baldan (adaptador WooCommerce) ✓ operativo

Baldan (baldan.com.br) es WooCommerce con el listado cargado por AJAX, pero
expone **sitemaps** con las 241 fichas de producto en español y las páginas son
server-rendered. Su TLS es incompleto: las descargas van vía `curl -k`.

```bash
# 1. Catálogo (ya generado): data/catalog/baldan-productos-es.txt (241 URLs
#    del sitemap product-sitemap1..4.xml, rutas /es/productos/)
# 2. Scraping de fichas técnicas (tabla de especificaciones por variante)
node implementos/baldan.js                 # [--limit=10] [--force]
#    → data/implements/baldan-<slug>.json: un registro por VARIANTE con
#      ancho/peso/potencia/nº de discos + ficha técnica cruda (specs.ficha_tecnica)
# 3. Imágenes → WebP 960/q65 (misma política que tractores)
node download-implement-images.js          # [--dry-run] [--force]
# 4. Importar (ejecutar desde backend/)
node scripts/scraping/import-implements.js --dry-run
node scripts/scraping/import-implements.js
```

Tipos añadidos por el catálogo de fabricantes: `abonador`, `pulverizador`,
`carreta`, `distribuidor`, `repuesto`, `otro` (además de los 14 de la Tabla 1).

## Pipeline de implementos (cosecha + curación)

Los fabricantes LATAM de implementos no tienen páginas estáticas; el flujo es
**cosechar → curar a mano → importar**:

```bash
# Cosecha genérica (cualquier página con tablas de especificaciones)
node harvest-implements.js --urls=urls.txt --brand=Baldan
node harvest-implements.js --html=pagina-renderizada.html --url="https://…" --brand=Tatu --type=subsolador

# Cura: editar data/implements/*.json (los campos NOT NULL obligatorios:
# implement_name, brand, power_requirement_hp, working_width_m, implement_type)

# Importar
node import-implements.js --dry-run
node import-implements.js
```

Tipos válidos de `implement_type` (los 9 de la Tabla 1 de Chaparro + genéricos):
`plow, harrow, seeder, cultivator, subsoiler, arado_disco_vertedera, subsolador,
arado_cincel, implemento_rotativo, rastrillo_simple_discos, rastrillo_pulidor,
rastrillo_californiano, rastra_pesada_26, rastra_pesada_24`.

### Sitios JS/Cloudflare

Para fabricantes con SPA o protección (Baldan, Tatu Marchesan, Basso, AgriExpo…):
1. Renderizar la página con automatización de navegador (skill `browser-use` de
   ZCode) y guardar el HTML final.
2. Pasarlo al harvester con `--html=<archivo>`.
3. Alternativa: los catálogos PDF de los fabricantes → copiar la tabla de
   especificaciones al JSON a mano.

## Costes y cortesía

- Delay por defecto: 800 ms entre peticiones (configurable con `--delay`).
- Caché en disco: re-ejecutar un lote **no** vuelve a descargar páginas.
- El catálogo completo (4.102 modelos de 12 marcas) son ~16.400 peticiones;
  a 800 ms ≈ 3,7 h + tiempo de descarga. Recomendado por tandas de marca.

## Flujo completo de datos (orden obligatorio)

```
1. node tractordata/run.js --urls=…       (scraping TractorData)
2. node download-images.js               (fotos WebP)
3. node import.js                        (scraping → BD)
4. node implementos/baldan.js            (fichas Baldan)
5. node download-implement-images.js
6. node import-implements.js
7. node import-curados.js                (curados: ficha oficial, prioridad=TRUE)
8. node extract-tires-from-pdf.js        (llantas desde fichas PDF de fabricantes)
9. node validate-links.js --prioridad    (auditoría por bytes mágicos)
10. node solidify-db.js                  (completa lo buscable y BORRA lo incompleto)
```

El paso 8 es clave: antes de que `solidify-db.js` borre un tractor prioritario
por faltarle llantas, extrae esa información del PDF de la ficha técnica
(p. ej. Kubota MU4501: "RUEDAS Y GOMAS — Traseras 13.6 x 28").
