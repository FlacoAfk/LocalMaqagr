# USER GUIDE - MaqAgr Backend API

## 1. Introduccion
MaqAgr Backend es una API REST para gestionar maquinaria agricola, terrenos, calculos de potencia y recomendaciones.

Base URL local sugerida:
- `http://localhost:3000`

Si ejecutas el backend con configuracion por defecto de `.env`, puede correr en:
- `http://localhost:4000`

## 2. Autenticacion (obtener token)
La API usa JWT Bearer Token.

### 2.1 Registro
`POST /api/auth/register`

Body ejemplo:
```json
{
  "name": "Demo User",
  "email": "demo.user@example.com",
  "password": "DemoPass123!"
}
```

Respuesta esperada (201):
```json
{
  "success": true,
  "message": "Usuario registrado exitosamente",
  "data": {
    "user": {
      "user_id": 101,
      "name": "Demo User",
      "email": "demo.user@example.com",
      "role_id": 2,
      "status": "active"
    },
    "token": "<jwt>"
  }
}
```

### 2.2 Login
`POST /api/auth/login`

Body ejemplo:
```json
{
  "email": "demo.user@example.com",
  "password": "DemoPass123!"
}
```

Respuesta esperada (200):
```json
{
  "success": true,
  "message": "Inicio de sesion exitoso",
  "data": {
    "token": "<jwt>",
    "user": {
      "name": "Demo User",
      "email": "demo.user@example.com",
      "role_id": 2
    }
  }
}
```

### 2.3 Enviar token en requests protegidos
Header requerido:
```http
Authorization: Bearer <jwt>
```

### 2.4 Logout y perfil
- `POST /api/auth/logout`
- `GET /api/auth/profile`

## 3. Flujos tipicos

### Flujo A: Crear terreno
1. Login para obtener token.
2. Crear terreno con `POST /api/terrains`.
3. Consultar terreno con `GET /api/terrains/:id`.

Request ejemplo (crear terreno):
```json
{
  "name": "Parcela Norte",
  "altitude_meters": 2500,
  "slope_percentage": 12,
  "soil_type": "clay",
  "temperature_celsius": 19
}
```

Respuesta esperada (201):
```json
{
  "success": true,
  "message": "Terreno creado exitosamente",
  "data": {
    "terrain_id": 1,
    "name": "Parcela Norte",
    "soil_type": "clay"
  }
}
```

### Flujo B: Obtener recomendacion
1. Tener al menos un terreno y un implemento valido.
2. Ejecutar `POST /api/recommendations/generate`.
3. Revisar ranking y score de tractores.

Request ejemplo:
```json
{
  "terrain_id": 1,
  "implement_id": 2,
  "working_depth_m": 0.25,
  "work_type": "tillage"
}
```

Respuesta esperada (200):
```json
{
  "success": true,
  "message": "Recomendaciones generadas exitosamente",
  "data": {
    "queryId": 10,
    "recommendations": [
      {
        "rank": 1,
        "score": {
          "total": 87.5
        }
      }
    ]
  }
}
```

### Flujo C: Consultar catalogos
Catalogos publicos:
- `GET /api/tractors`
- `GET /api/implements`
- `GET /api/tractors/search?q=john`
- `GET /api/implements/search?q=arado`

Ejemplo respuesta catalogo:
```json
{
  "success": true,
  "data": [
    {
      "tractor_id": 3,
      "name": "John Deere 6130M",
      "engine_power_hp": 130
    }
  ],
  "pagination": {
    "total": 1,
    "limit": 10,
    "offset": 0
  }
}
```

## 4. Ejemplos rapidos de requests/responses

### 4.1 Power Loss
`POST /api/calculations/power-loss`

```json
{
  "tractor_id": 1,
  "terrain_id": 1,
  "working_speed_kmh": 7.5,
  "carried_objects_weight_kg": 400,
  "slippage_percent": 10
}
```

### 4.2 Minimum Power
`POST /api/calculations/minimum-power`

```json
{
  "implement_id": 1,
  "terrain_id": 1,
  "working_depth_m": 0.3
}
```

### 4.3 Notificaciones
- `GET /api/notifications`
- `PUT /api/notifications/read-all`
- `PUT /api/notifications/:id/read`
- `DELETE /api/notifications/:id`

## 5. Troubleshooting basico
- `401 Unauthorized`: token faltante, invalido o expirado. Rehacer login.
- `403 Forbidden`: el usuario no tiene rol requerido (ej. admin).
- `429 Too Many Requests`: excediste rate limit. Espera y reintenta.
- `500 Internal Server Error`: revisar logs del backend y de DB.

Para guia completa de errores comunes, ver `docs/TROUBLESHOOTING.md`.

## 6. Uso con Postman
1. Importar la coleccion: `postman/MaqAgr-Backend.postman_collection.json`.
2. Importar environment de desarrollo o staging.
3. Definir `loginEmail` y `loginPassword` en el environment.
4. Ejecutar `Auth > Login` o dejar que el pre-request script haga auto-login.

## 7. Endpoints por modulo (resumen)
- Auth: register, login, refresh (re-login), logout, profile, update profile, change password.
- Tractors: CRUD, available, search.
- Implements: CRUD, available, search.
- Terrains: CRUD.
- Queries: power-loss, minimum-power, history.
- Recommendations: generate, advanced, history, by id.
- Notifications: list, unread count, mark read, mark all read, delete.
- Admin: stats, cache stats, broadcast notifications.
- Health: health check publico y detallado admin.
