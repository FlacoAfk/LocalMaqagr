# INFORME TÉCNICO DEL PROYECTO

**Preparado por: Juan David Yate Vargas**

**Backend MaqAgr**

**Fecha: 13 de abril de 2026 | Última actualización: 16 de abril de 2026 | Estado: ✅ LISTO PARA DESPLIEGUE**

---

## TABLA DE CONTENIDO

1. [DESCRIPCIÓN GENERAL DEL SISTEMA](#1-descripción-general-del-sistema)
2. [TECNOLOGÍAS UTILIZADAS](#2-tecnologías-utilizadas)
3. [ARQUITECTURA DEL SISTEMA](#3-arquitectura-del-sistema)
   - 3.1 [Estructura de Capas](#31-estructura-de-capas)
   - 3.2 [Estructura de Directorios](#32-estructura-de-directorios)
4. [BASE DE DATOS](#4-base-de-datos)
   - 4.1 [Modelo Entidad-Relación](#41-modelo-entidad-relación)
   - 4.2 [Descripción de Tablas Principales](#42-descripción-de-tablas-principales)
5. [MÓDULOS FUNCIONALES DEL SISTEMA](#5-módulos-funcionales-del-sistema)
   - 5.1 [Módulo de Autenticación (/api/auth)](#51-módulo-de-autenticación-apiauth)
   - 5.2 [Módulo de Catálogo de Tractores (/api/tractors)](#52-módulo-de-catálogo-de-tractores-apitractors)
   - 5.3 [Módulo de Catálogo de Implementos (/api/implements)](#53-módulo-de-catálogo-de-implementos-apiimplements)
   - 5.4 [Módulo de Gestión de Terrenos (/api/terrains)](#54-módulo-de-gestión-de-terrenos-apiterrains)
   - 5.5 [Módulo de Cálculos Técnicos (/api/calculations)](#55-módulo-de-cálculos-técnicos-apicalculations)
   - 5.6 [Módulo de Recomendaciones Inteligentes (/api/recommendations)](#56-módulo-de-recomendaciones-inteligentes-apirecommendations)
   - 5.7 [Módulo de Exportación (/api/export)](#57-módulo-de-exportación-apiexport)
   - 5.8 [Módulo de Notificaciones (/api/notifications)](#58-módulo-de-notificaciones-apinotifications)
   - 5.9 [Módulo de Administración (/api/admin)](#59-módulo-de-administración-apiadmin)
   - 5.10 [Health Check (/health)](#510-health-check-health)
6. [SISTEMA DE SEGURIDAD](#6-sistema-de-seguridad)
   - 6.1 [Autenticación y Autorización](#61-autenticación-y-autorización)
   - 6.2 [Protección contra Ataques](#62-protección-contra-ataques)
   - 6.3 [Headers de Seguridad HTTP (Helmet)](#63-headers-de-seguridad-http-helmet)
7. [SISTEMA DE LOGGING Y MONITOREO](#7-sistema-de-logging-y-monitoreo)
   - 7.1 [Logging con Winston](#71-logging-con-winston)
   - 7.2 [Correlación de Peticiones](#72-correlación-de-peticiones)
   - 7.3 [Niveles de Log Semánticos](#73-niveles-de-log-semánticos)
8. [SISTEMA DE CACHÉ](#8-sistema-de-caché)
9. [TAREAS PROGRAMADAS (BACKGROUND JOBS)](#9-tareas-programadas-background-jobs)
10. [DOCUMENTACIÓN INTERACTIVA DE LA API](#10-documentación-interactiva-de-la-api)
11. [PRUEBAS AUTOMATIZADAS](#11-pruebas-automatizadas)
12. [CONFIGURACIÓN Y DESPLIEGUE](#12-configuración-y-despliegue)
    - 12.1 [Variables de Entorno Requeridas](#121-variables-de-entorno-requeridas)
    - 12.2 [Pasos de Inicialización](#122-pasos-de-inicialización)
13. [ESTADO ACTUAL DEL PROYECTO](#13-estado-actual-del-proyecto)
    - 13.1 [Módulos Completados y Funcionales](#131-módulos-completados-y-funcionales)
    - 13.2 [Ajustes Pendientes Antes del Despliegue](#132-ajustes-pendientes-antes-del-despliegue)

---

## 1. DESCRIPCIÓN GENERAL DEL SISTEMA

MaqAgr es un sistema de gestión agrícola inteligente cuyo backend provee una API REST robusta que permite a los usuarios:

- Administrar un catálogo de tractores e implementos agrícolas.
- Registrar y gestionar terrenos con sus características físicas (pendiente, tipo de suelo, altitud, temperatura).
- Realizar cálculos técnicos de ingeniería agrícola: pérdida de potencia de motores y potencia mínima requerida para operar implementos.
- Obtener recomendaciones inteligentes de tractores compatibles con cada terreno e implemento.
- Exportar datos en formatos CSV y PDF.
- Recibir notificaciones del sistema.

El backend está construido con tecnología moderna y estándares de la industria, garantizando seguridad, escalabilidad y mantenibilidad.

---

## 2. TECNOLOGÍAS UTILIZADAS

| **Tecnología** | **Versión** | **Propósito** |
|---|---|---|
| Node.js | ≥18 | Entorno de ejecución del servidor |
| Express 5 | 5.2.x | Framework HTTP para la API REST |
| PostgreSQL | Compatible | Base de datos relacional principal |
| Redis | Compatible | Caché en memoria para alto rendimiento |
| JWT (jsonwebtoken) | 9.x | Autenticación sin estado (stateless) |
| bcrypt | 6.x | Cifrado seguro de contraseñas |
| Winston | 3.x | Logging estructurado a archivos y consola |
| Morgan | 1.x | Registro de peticiones HTTP |
| Helmet | 8.x | Headers de seguridad HTTP |
| express-rate-limit | 8.x | Protección contra ataques de fuerza bruta |
| ioredis | 5.x | Cliente Redis para Node.js |
| PDFKit | 0.17.x | Generación de reportes PDF |
| json2csv | 6.x | Exportación a formato CSV |
| Sequelize | 6.x | ORM para consultas de analítica del admin |
| Swagger (swagger-jsdoc + swagger-ui-express) | Latest | Documentación interactiva de la API |
| node-cron | 4.x | Tareas programadas automáticas |
| Jest + Supertest | 30.x | Pruebas unitarias e integración |

---

## 3. ARQUITECTURA DEL SISTEMA

### 3.1 Estructura de Capas

El sistema implementa una arquitectura en capas (Layered Architecture) que separa claramente las responsabilidades:

```
┌─────────────────────────────────────────┐
│         Cliente HTTP                    │
│      (Frontend / Postman)               │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            MIDDLEWARES                  │
│  Seguridad, autenticación,              │
│  validación, caché, logs                │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│           RUTAS (Routes)                │
│  Definición de endpoints y              │
│  mapeo a controladores                  │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          CONTROLADORES                  │
│  Orquestación: validación,              │
│  lógica de negocio, respuesta           │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            SERVICIOS                    │
│  Lógica de negocio pura                 │
│  (cálculos, recomendaciones)            │
└───────────────────┬─────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            MODELOS                      │
│  Acceso a base de datos                 │
│  (SQL parametrizado via pg)             │
└────────────┬────────────────────────────┘
             │
      ┌──────┴──────┐
      ▼             ▼
┌──────────┐  ┌──────────┐
│PostgreSQL│  │  Redis   │
│Persistenc│  │  Caché   │
│ia datos  │  │          │
└──────────┘  └──────────┘
```

### 3.2 Estructura de Directorios

```
src/
├── app.js                          # Punto de entrada de la aplicación
├── config/
│   ├── db.js                       # Conexión a PostgreSQL (pool de conexiones)
│   ├── logger.js                   # Configuración central de Winston
│   ├── redis.js                    # Conexión a Redis
│   ├── sequelize.js                # Instancia Sequelize para analytics
│   └── swagger/                  # Documentación Swagger
│       ├── swagger.js            # Configuración de Swagger UI
│       └── schemas.js            # Schemas OpenAPI reutilizables
├── controllers/
│   ├── authController.js           # Registro, login, perfil, contraseña
│   ├── tractorController.js        # CRUD de tractores
│   ├── implementController.js      # CRUD de implementos
│   ├── terrainController.js        # CRUD de terrenos del usuario
│   ├── calculationController.js    # Cálculos técnicos de potencia
│   ├── recommendationController.js # Sistema de recomendaciones inteligentes
│   ├── adminController.js          # Dashboard y estadísticas admin
│   ├── notificationController.js   # Gestión de notificaciones
│   ├── exportController.js         # Exportación PDF y CSV
│   └── healthController.js         # Health check del servidor
├── middleware/
│   ├── auth.middleware.js          # Verificación JWT y roles
│   ├── security.middleware.js      # Headers de seguridad (Helmet)
│   ├── cors.middleware.js          # Configuración de CORS por entorno
│   ├── rateLimiter.middleware.js   # Límites de peticiones por IP
│   ├── sanitize.middleware.js      # Sanitización contra XSS e inyección SQL
│   ├── cache.middleware.js         # Caché Redis para respuestas GET
│   ├── pagination.middleware.js    # Paginación estandarizada
│   ├── validation.middleware.js    # Validación de tractores e implementos
│   ├── calculationValidation.middleware.js  # Validación de cálculos
│   ├── error.middleware.js         # Manejo centralizado de errores
│   └── httpLogger.middleware.js    # Log de peticiones HTTP (Morgan+Winston)
├── models/
│   ├── User.js                     # Modelo de usuarios
│   ├── Tractor.js                  # Modelo de tractores
│   ├── Implement.js                # Modelo de implementos
│   ├── Terrain.js                  # Modelo de terrenos
│   ├── Query.js                    # Modelo de consultas/cálculos realizados
│   ├── PowerLoss.js                # Modelo de resultados de pérdida de potencia
│   ├── Recommendation.js           # Modelo de recomendaciones
│   ├── QueryHistory.js             # Modelo de historial de acciones
│   ├── Role.js                     # Modelo de roles de usuario
│   ├── Notification.js             # Modelo de notificaciones
│   └── adminAnalytics.models.js    # Modelos Sequelize para analítica admin
├── routes/
│   ├── auth.routes.js              # /api/auth/*
│   ├── tractor.routes.js           # /api/tractors/*
│   ├── implement.routes.js         # /api/implements/*
│   ├── terrain.routes.js           # /api/terrains/*
│   ├── calculation.routes.js       # /api/calculations/*
│   ├── recommendation.routes.js    # /api/recommendations/*
│   ├── admin.routes.js             # /api/admin/*
│   ├── notification.routes.js      # /api/notifications/*
│   ├── export.routes.js            # /api/export/*
│   └── health.routes.js            # /health/*
├── services/
│   ├── powerLossService.js         # Algoritmo de pérdida de potencia (física)
│   ├── minimumPowerService.js      # Algoritmo de potencia mínima requerida
│   ├── recommendationService.js    # Motor de recomendaciones con scoring
│   └── notificationService.js      # Lógica de notificaciones y envíos masivos
├── utils/
│   ├── jwt.util.js                 # Generación y verificación de tokens JWT
│   ├── validators.util.js          # Validadores: email, contraseña, tipos numéricos
│   ├── errors.util.js              # Clases de error personalizadas
│   ├── asyncHandler.util.js        # Wrapper para manejo automático de errores async
│   ├── cache.util.js               # Invalidación de caché Redis
│   ├── response.util.js            # Helpers para respuestas HTTP estandarizadas
│   ├── pagination.util.js          # Función compartida de paginación
│   └── logger.js                   # Re-exportación de config/logger.js
├── jobs/
│   ├── index.js                    # Inicializador de tareas programadas
│   ├── cleanupTokens.js            # Job diario (2 AM): limpieza de tokens
│   ├── cleanupCache.js             # Job diario (3 AM): limpieza de caché sin TTL
│   └── generateReports.js          # Job semanal (Lunes 1 AM): reporte de actividad
├── scripts/
│   ├── setup-db.js                 # Script de inicialización de la base de datos
│   ├── seed.js                     # Datos de prueba básicos
│   ├── seed-unified.js             # Datos de prueba completos y unificados
│   ├── run-migration.js            # Ejecutor de migraciones
│   └── check-data.js               # Verificador del estado de los datos
└── database/                         # (raíz del proyecto)
    ├── schema.sql                  # Schema SQL completo de la base de datos
    └── indexes.sql                 # Índices optimizados
```

---

## 4. BASE DE DATOS

### 4.1 Modelo Entidad-Relación

La base de datos PostgreSQL contiene 10 tablas con las siguientes relaciones:

```
role (role_id, role_name)
  └── users (user_id, name, email, password, role_id, status)
        ├── terrain (terrain_id, user_id, name, area_hectares, altitude_meters,
        │            slope_percentage, soil_type, temperature_celsius)
        ├── notification (notification_id, user_id, type, title, message, read)
        └── query (query_id, user_id, terrain_id, tractor_id, implement_id, query_type)
              ├── power_loss (query_id, slope_loss_hp, altitude_loss_hp,
              │               rolling_resistance_loss_hp, total_loss_hp, net_power_hp)
              └── query_history (history_id, user_id, query_id, action_type,
                                 description, result_json)

tractor (tractor_id, name, brand, model, engine_power_hp, weight_kg,
         traction_type, tire_type, price, status)

implement (implement_id, implement_name, brand, implement_type,
           power_requirement_hp, working_width_m, working_depth_cm, status)

recommendation (recommendation_id, user_id, terrain_id, tractor_id,
                implement_id, compatibility_score, work_type, observations)
```

### 4.2 Descripción de Tablas Principales

| **Tabla** | **Propósito** | **Registros esperados** |
|---|---|---|
| role | Catálogo de roles del sistema (admin, user) | ~3 registros fijos |
| users | Usuarios registrados en la plataforma | Crecimiento orgánico |
| tractor | Catálogo de tractores disponibles | Administrado por admin |
| implement | Catálogo de implementos agrícolas | Administrado por admin |
| terrain | Terrenos registrados por cada usuario | Variable por usuario |
| query | Registro de cada cálculo realizado | Alta frecuencia |
| power_loss | Resultados detallados de cálculos de potencia | 1:1 con query tipo power_loss |
| recommendation | Recomendaciones generadas y persistidas | Moderada frecuencia |
| query_history | Log de auditoría de todas las acciones | Alta frecuencia |
| notification | Notificaciones enviadas a usuarios | Alta frecuencia |

---

## 5. MÓDULOS FUNCIONALES DEL SISTEMA

### 5.1 Módulo de Autenticación (/api/auth)

Sistema completo de gestión de identidad:

| **Endpoint** | **Método** | **Acceso** | **Descripción** |
|---|---|---|---|
| /api/auth/register | POST | Público | Registro de nuevo usuario |
| /api/auth/login | POST | Público | Inicio de sesión, retorna JWT |
| /api/auth/logout | POST | Autenticado | Cierre de sesión (invalida sesión del lado cliente) |
| /api/auth/profile | GET | Autenticado | Consultar datos del perfil |
| /api/auth/profile | PUT | Autenticado | Actualizar nombre y/o email |
| /api/auth/password | PUT | Autenticado | Cambio de contraseña con verificación de la actual |
| /api/auth/users/:id | DELETE | Solo Admin | Eliminar usuario del sistema |

**Seguridad implementada:**

- Contraseñas cifradas con bcrypt (10 rondas de salt)
- Tokens JWT con expiración configurable
- Validación de complejidad de contraseña (mínimo 8 caracteres, mayúscula, minúscula, número, carácter especial)
- Rate limiting de 5 intentos de login por IP cada 15 minutos (protección contra fuerza bruta)
- Rate limiting de 50 peticiones por IP para registro y rutas públicas

### 5.2 Módulo de Catálogo de Tractores (/api/tractors)

Gestión completa del inventario de maquinaria:

| **Endpoint** | **Método** | **Acceso** | **Descripción** |
|---|---|---|---|
| /api/tractors | GET | Público | Listado paginado de todos los tractores |
| /api/tractors/available | GET | Público | Solo tractores con status "disponible" |
| /api/tractors/search | GET | Público | Búsqueda avanzada con filtros múltiples |
| /api/tractors/:id | GET | Público | Detalle de un tractor específico |
| /api/tractors | POST | Solo Admin | Crear nuevo tractor en el catálogo |
| /api/tractors/:id | PUT | Solo Admin | Actualizar datos de un tractor |
| /api/tractors/:id | DELETE | Solo Admin | Desactivar tractor (soft delete) |

**Características técnicas:**

- Búsqueda full-text en nombre, marca y modelo con ordenamiento por relevancia
- Filtros combinados: rango de potencia (HP), tipo de tracción, marca
- Paginación configurable con límite máximo de 100 registros
- Caché Redis de 24 horas para optimizar lecturas frecuentes
- Los tractores con recomendaciones activas no pueden eliminarse (integridad referencial)
- El "borrado" es lógico: cambia el status a "inactive" preservando histórico

### 5.3 Módulo de Catálogo de Implementos (/api/implements)

Gestión del inventario de herramientas agrícolas:

| **Endpoint** | **Método** | **Acceso** | **Descripción** |
|---|---|---|---|
| /api/implements | GET | Público | Listado paginado de implementos |
| /api/implements/available | GET | Público | Solo implementos disponibles |
| /api/implements/search | GET | Público | Búsqueda con filtros (tipo, ancho, potencia requerida) |
| /api/implements/:id | GET | Público | Detalle de un implemento |
| /api/implements | POST | Solo Admin | Crear implemento |
| /api/implements/:id | PUT | Solo Admin | Actualizar implemento |
| /api/implements/:id | DELETE | Solo Admin | Desactivar implemento (soft delete) |

**Tipos de implementos soportados:** plow (arado), harrow (rastra), seeder (sembradora), sprayer (aspersora), harvester (cosechadora), cultivator (cultivador), mower (segadora), trailer (remolque), other.

**Filtro inteligente por tractorId:** al buscar implementos con `?tractorId=5`, el sistema obtiene automáticamente la potencia del tractor referenciado y la usa como filtro de compatibilidad.

### 5.4 Módulo de Gestión de Terrenos (/api/terrains)

Registro y administración de las parcelas agrícolas del usuario:

| **Endpoint** | **Método** | **Acceso** | **Descripción** |
|---|---|---|---|
| /api/terrains | GET | Autenticado | Terrenos propios del usuario (paginado) |
| /api/terrains/:id | GET | Autenticado | Detalle de un terreno propio |
| /api/terrains | POST | Autenticado | Registrar nuevo terreno |
| /api/terrains/:id | PUT | Autenticado | Actualizar terreno |
| /api/terrains/:id | DELETE | Autenticado | Eliminar terreno |

**Datos capturados por terreno:**

- Nombre e identificación de la parcela
- Área en hectáreas
- Altitud sobre el nivel del mar (metros)
- Pendiente del terreno (porcentaje)
- Tipo de suelo (arcilla, franco, arena, rocoso)
- Temperatura ambiente promedio (°C)

**Seguridad de ownership:** cada usuario solo puede ver y modificar sus propios terrenos. El sistema verifica que el `user_id` del terreno coincida con el `user_id` del token JWT en cada operación.

### 5.5 Módulo de Cálculos Técnicos (/api/calculations)

El núcleo técnico del sistema, que implementa algoritmos de ingeniería agrícola:

#### 5.5.1 Cálculo de Pérdida de Potencia (POST /api/calculations/power-loss)

Calcula cuánta potencia útil queda disponible en un tractor dado un terreno y condiciones de trabajo específicas.

**Factores de pérdida calculados:**

| **Factor** | **Fórmula** | **Descripción** |
|---|---|---|
| Altitud | -1% por cada 300m s.n.m. | La densidad del aire disminuye con la altura, reduciendo la combustión |
| Temperatura | -1% por cada 5°C sobre 15°C | El calor reduce la eficiencia del motor |
| Transmisión | -13% fijo por defecto | Pérdidas mecánicas en el sistema de transmisión |
| Resistencia al rodamiento | μr = (1.2/Cn) + 0.04 | Basado en el índice de cono del suelo (ASABE D497.7) |
| Pendiente | W·sin(θ)·v / 274.4 | Componente gravitacional según inclinación del terreno |
| Patinaje | % configurado × potencia disponible | Pérdida por deslizamiento de las ruedas |

**Resultado devuelto:** desglose de pérdidas por factor, potencia neta disponible y porcentaje de eficiencia total. El resultado se persiste en la base de datos con registro de auditoría.

#### 5.5.2 Cálculo de Potencia Mínima (POST /api/calculations/minimum-power)

Determina la potencia mínima que debe tener un tractor para operar un implemento específico en un terreno dado.

**Fórmula:**

```
HP_mín = HP_base × F_suelo × F_pendiente × F_profundidad × 1.15
```

**Donde:**

- `F_suelo`: clay=1.3 | loam=1.0 | sandy=0.8 | rocky=1.5
- `F_pendiente`: 1 + (pendiente% / 100) × 0.5
- `F_profundidad`: profundidad_trabajo_m / 0.25 (referencia estándar 25cm)
- `1.15`: margen de seguridad del 15%

**Clasificación automática de tractores disponibles:**

- **OPTIMAL:** potencia entre 100% y 125% de la requerida
- **OVERPOWERED:** potencia mayor al 125% (sobredimensionado pero funcional)
- **INSUFFICIENT:** potencia menor a la requerida

#### 5.5.3 Historial de Cálculos (GET /api/calculations/history)

Retorna el historial paginado de todos los cálculos realizados por el usuario autenticado, con soporte de filtro por tipo (`power_loss` o `minimum_power`).

### 5.6 Módulo de Recomendaciones Inteligentes (/api/recommendations)

Sistema de "matchmaking agrícola" que recomienda los tractores más adecuados para cada combinación terreno-implemento mediante un algoritmo de scoring multi-criterio.

#### 5.6.1 Recomendación Estándar (POST /api/recommendations/generate)

**Flujo del algoritmo:**

1. Valida que el terreno pertenezca al usuario autenticado
2. Calcula la potencia mínima requerida (ver módulo 5.5.2)
3. Analiza características del terreno (pendiente, tipo de suelo)
4. Evalúa cada tractor disponible con scoring ponderado:

| **Criterio** | **Peso** | **Descripción** |
|---|---|---|
| Eficiencia energética | 30% | Penaliza el sobredimensionamiento; premia el uso óptimo |
| Tracción adecuada | 25% | Bonus según compatibilidad pendiente↔tipo de tracción |
| Compatibilidad de suelo | 20% | Adecuación del tipo de rodadura al suelo |
| Factor económico | 15% | Preferencia por menor consumo estimado |
| Disponibilidad | 10% | Solo tractores con status "available" obtienen puntuaje |

5. Retorna el **Top 5** de tractores ordenados por score, con clasificaciones: OPTIMAL, GOOD, ACCEPTABLE, OVERPOWERED
6. Persiste las **Top 3** recomendaciones en la base de datos para historial y exportación

#### 5.6.2 Recomendación Avanzada (POST /api/recommendations/advanced)

Permite al usuario personalizar los pesos del algoritmo y aplicar filtros adicionales:

- **Presupuesto máximo** (`budget`): filtra tractores cuyo precio supere el límite
- **Preferencia de marca** (`brandPreference`): otorga puntuaje adicional a la marca indicada
- **Pesos personalizables:** el usuario puede redistribuir los porcentajes según sus prioridades

### 5.7 Módulo de Exportación (/api/export)

Permite descargar datos del sistema en formatos portables:

| **Endpoint** | **Formato** | **Descripción** |
|---|---|---|
| GET /api/exports/tractors?format=csv | CSV | Catálogo completo de tractores (nombre, marca, potencia, año, precio) |
| GET /api/exports/recommendations?format=pdf | PDF | Reporte visual con todas las recomendaciones del usuario autenticado |

**El reporte PDF incluye:**

- Encabezado con logo del proyecto, nombre del usuario y fecha
- Tarjetas individuales por recomendación, con datos del terreno, tractor, implemento y score de compatibilidad
- Indicador visual del nivel de compatibilidad (verde/amarillo/rojo)
- Estado vacío si el usuario no tiene recomendaciones registradas
- Paginación automática del documento

### 5.8 Módulo de Notificaciones (/api/notifications)

Sistema de notificaciones internas para mantener informados a los usuarios:

| **Endpoint** | **Método** | **Descripción** |
|---|---|---|
| /api/notifications | GET | Listar notificaciones del usuario (con filtro leídas/no leídas) |
| /api/notifications/unread/count | GET | Contador de notificaciones pendientes |
| /api/notifications/:id/read | PUT | Marcar una notificación como leída |
| /api/notifications/read-all | PUT | Marcar todas como leídas |
| /api/notifications/:id | DELETE | Eliminar una notificación |

**Eventos que generan notificaciones automáticas:**

- Nuevo tractor disponible con potencia ≥ 90 HP: notifica a todos los usuarios activos con terrenos registrados
- Nueva recomendación generada: notifica al usuario
- Mensajes de sistema/mantenimiento: envío masivo mediante el endpoint admin

### 5.9 Módulo de Administración (/api/admin)

Panel de control exclusivo para administradores del sistema:

| **Endpoint** | **Descripción** |
|---|---|
| GET /api/admin/stats/overview | Totales globales: usuarios, tractores, implementos, terrenos, consultas, recomendaciones; tendencias por día/semana/mes |
| GET /api/admin/stats/recommendations | Distribución de recomendaciones, top 10 tractores e implementos más recomendados, distribución por tipo de terreno y rango de potencia |
| GET /api/admin/stats/users | Usuarios registrados por mes, activos/inactivos, promedios de terrenos y consultas |
| GET /api/admin/cache/stats | Métricas de rendimiento de Redis: hits, misses, hit rate, latencia |
| POST /api/admin/notifications/broadcast | Envío masivo de notificaciones a lista de usuarios |

Las estadísticas del overview tienen caché Redis de **1 hora** para optimizar consultas costosas al dashboard.

### 5.10 Health Check (/health)

Endpoints de diagnóstico del servidor:

| **Endpoint** | **Acceso** | **Descripción** |
|---|---|---|
| GET /health | Público | Estado rápido del servidor (uptime, timestamp) |
| GET /health/detailed | Solo Admin | Diagnóstico completo: latencia de DB, métricas de memoria y CPU |

Útil para sistemas de monitoreo, balanceadores de carga y orquestadores de contenedores (Docker, Kubernetes).

---

## 6. SISTEMA DE SEGURIDAD

El sistema implementa una defensa en capas (Defense in Depth):

### 6.1 Autenticación y Autorización

- **JWT (JSON Web Tokens):** cada petición protegida debe incluir el token en el header `Authorization: Bearer <token>`
- **Roles:** el sistema tiene 3 roles — admin (role_id: 1), user (role_id: 2), operator (role_id: 3)
- **Ownership:** usuarios solo acceden a sus propios terrenos y datos personales

### 6.2 Protección contra Ataques

| **Tipo de ataque** | **Protección implementada** |
|---|---|
| Inyección SQL | Queries parametrizadas con `pg` en todos los modelos; nunca concatenación de strings |
| XSS (Cross-Site Scripting) | Sanitización de todas las entradas (body, query, params) con librería `xss` |
| Fuerza bruta en login | Rate limiter: máximo 5 intentos por IP cada 15 minutos |
| Clickjacking | Helmet: `X-Frame-Options: DENY` |
| MIME sniffing | Helmet: `X-Content-Type-Options: nosniff` |
| Información sensible en errores | Detalles del error solo visibles en entorno `development` |
| Acceso cross-origin | CORS configurable por entorno: solo permite orígenes de la lista blanca |
| Contraseñas débiles | Validación: mínimo 8 caracteres, mayúscula, minúscula, número y carácter especial |

### 6.3 Headers de Seguridad HTTP (Helmet)

- **Content-Security-Policy:** restringe fuentes de scripts, estilos e imágenes
- **Strict-Transport-Security (HSTS):** fuerza HTTPS por 1 año con preload
- **X-XSS-Protection:** activo para navegadores legacy
- **Referrer-Policy:** `strict-origin-when-cross-origin`

---

## 7. SISTEMA DE LOGGING Y MONITOREO

### 7.1 Logging con Winston

El sistema registra toda la actividad en múltiples destinos simultáneamente:

| **Destino** | **Contenido** | **Nivel** |
|---|---|---|
| Consola (desarrollo) | Formato legible con colores | DEBUG y superiores |
| logs/combined.log | Todos los eventos | INFO y superiores |
| logs/error.log | Solo errores | ERROR únicamente |
| logs/app-YYYY-MM-DD.log | Rotación diaria, comprimido, 14 días de historial | INFO y superiores |

### 7.2 Correlación de Peticiones

Cada petición HTTP recibe un identificador único (`x-request-id`) que se incluye en todos los logs relacionados, permitiendo rastrear el ciclo completo de una petición incluso en logs distribuidos.

### 7.3 Niveles de Log Semánticos

- **ERROR:** fallos de servidor (5xx), errores de base de datos, excepciones no controladas
- **WARN:** errores de cliente (4xx), intentos de login fallidos, slow queries (>100ms)
- **INFO:** operaciones exitosas importantes (registro de usuario, cálculos completados, notificaciones enviadas)
- **HTTP:** cada petición y respuesta HTTP con método, URL, código de estado y duración
- **DEBUG:** cuerpos de petición (solo en desarrollo, sin datos sensibles)

---

## 8. SISTEMA DE CACHÉ

Redis se utiliza para reducir la carga sobre la base de datos en rutas de alta frecuencia:

| **Ruta cacheada** | **TTL** | **Invalidación automática** |
|---|---|---|
| GET /api/tractors | 24 horas | Al crear/actualizar/eliminar tractores |
| GET /api/recommendations/history | 1 hora | Manual (pendiente de mejora) |
| GET /api/admin/stats/overview | 1 hora | No aplica (datos estadísticos) |

**Estrategia de caché:** la respuesta se almacena con una clave que incluye la URL y el ID del usuario autenticado, evitando que usuarios distintos compartan caché con datos privados.

---

## 9. TAREAS PROGRAMADAS (BACKGROUND JOBS)

El sistema ejecuta tareas automáticas en segundo plano usando `node-cron`:

| **Job** | **Programación** | **Descripción** |
|---|---|---|
| cleanupTokensJob | Diario a las 2:00 AM | Limpieza de tokens expirados (registro de ejecución) |
| cleanupCacheJob | Diario a las 3:00 AM | Elimina claves Redis sin TTL para liberar memoria |
| generateReportsJob | Lunes a la 1:00 AM | Genera reporte semanal de actividad de la plataforma |

---

## 10. DOCUMENTACIÓN INTERACTIVA DE LA API

El sistema incluye documentación completa y ejecutable de todos los endpoints mediante **Swagger UI**, disponible en:

```
http://[servidor]/api/docs
```

**La documentación incluye:**

- Descripción de cada endpoint con sus parámetros
- Schemas de request y response con ejemplos reales
- Autenticación integrada (se puede ingresar el token JWT directamente)
- Posibilidad de ejecutar peticiones de prueba directamente desde el navegador

---

## 11. PRUEBAS AUTOMATIZADAS

El proyecto cuenta con una suite de pruebas con **Jest:**

```bash
pnpm test                 # Ejecutar todas las pruebas
pnpm run test:unit        # Solo pruebas unitarias
pnpm run test:integration # Pruebas de integración (requiere DB de prueba)
pnpm run test:coverage    # Reporte de cobertura de código
```

**Las pruebas cubren:**

- Servicios de cálculo (lógica matemática de potencia y recomendaciones)
- Middlewares de validación y autenticación
- Controladores con mocking de base de datos

---

## 12. CONFIGURACIÓN Y DESPLIEGUE

### 12.1 Variables de Entorno Requeridas

El sistema se configura completamente a través de variables de entorno (archivo `.env`):

```env
# Entorno
NODE_ENV=production

# Servidor
PORT=4000

# Base de datos PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=MaqAgr
DB_USER=postgres
DB_PASS=[contraseña_segura]

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=[contraseña_redis]

# JWT
JWT_SECRET=[secreto_aleatorio_largo_y_seguro]
JWT_EXPIRES_IN=7d

# CORS — URLs del frontend
PROD_CLIENT_URL=https://app.maqagr.com
STAGING_CLIENT_URL=https://staging.maqagr.com
```

### 12.2 Pasos de Inicialización

1. `pnpm install` — Instalar dependencias
2. Configurar `.env` con las variables del servidor de producción
3. `node src/scripts/setup-db.js` — Crear tablas en la base de datos
4. `node src/scripts/seed-unified.js` — Poblar datos iniciales (roles, tractores, implementos de ejemplo)
5. `pnpm start` — Iniciar el servidor

---

## 13. ESTADO ACTUAL DEL PROYECTO

### 13.1 Módulos Completados y Funcionales

- Sistema de autenticación y gestión de usuarios
- Catálogo de tractores (CRUD completo con búsqueda avanzada)
- Catálogo de implementos (CRUD completo con búsqueda avanzada)
- Gestión de terrenos por usuario
- Cálculo de pérdida de potencia con fundamentos físicos (ASABE D497.7)
- Cálculo de potencia mínima requerida
- Sistema de recomendaciones con scoring multi-criterio
- Recomendaciones avanzadas con filtros personalizables
- Exportación a PDF y CSV
- Sistema de notificaciones
- Dashboard de administración con estadísticas
- Documentación Swagger completa
- Logging estructurado con Winston
- Caché con Redis
- Headers de seguridad HTTP
- Rate limiting
- Sanitización de entradas
- Health checks

### 13.2 Ajustes Pendientes Antes del Despliegue

> **Estado: TODOS LOS AJUSTES RESUELTOS ✅**

Los siguientes ajustes fueron identificados y **completamente resueltos**:

- ~~**Corrección de seguridad crítica:** remover fallback de `user_id` del body en cálculo de potencia~~ ✅ RESUELTO
- ~~**Corrección de seguridad:** `JWT_SECRET` sin fallback en producción~~ ✅ RESUELTO
- ~~**Corrección de rutas:** eliminar duplicación de rutas POST/PUT/DELETE de tractores~~ ✅ RESUELTO
- ~~**Corrección de rutas:** eliminar duplicación de rutas GET/POST/PUT/DELETE de implementos~~ ✅ RESUELTO
- ~~**Refactorización menor:** unificar función de paginación duplicada en tres controladores~~ ✅ RESUELTO
- ~~**Limpieza de archivos:** eliminar archivos de depuración de la raíz del proyecto~~ ✅ RESUELTO
- ~~**Mejora del health check:** integrar Redis al diagnóstico detallado~~ ✅ RESUELTO
- ~~**Actualización del informe:** corregir discrepancias entre documentación y código~~ ✅ RESUELTO

> **El sistema está listo para el despliegue en producción y la integración con el frontend.**

### 13.3 Endpoints Adicionales (no documentados originalmente)

El sistema incluye endpoints adicionales que fueron agregados después de la versión inicial del informe:

| **Endpoint** | **Método** | **Acceso** | **Descripción** |
|---|---|---|---|
| /api/recommendations/history | GET | Autenticado | Historial paginado de recomendaciones (cache 1h) |
| /api/recommendations/:id | GET | Autenticado | Detalle de una recomendación específica |
| /api/roles/* | Varios | Admin | Gestión de roles del sistema |
