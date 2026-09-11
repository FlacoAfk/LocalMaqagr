# TROUBLESHOOTING - MaqAgr Backend API

## 1. Problemas comunes

### 1.1 Error 401 - Token invalido o expirado
Sintoma:
- Respuesta `401 Unauthorized`.
- Mensajes tipicos: `Token no proporcionado`, `Token invalido`, `Token expirado`.

Causas frecuentes:
- Falta el header `Authorization`.
- El token ya expiro.
- El token fue copiado incompleto.

Solucion:
1. Verifica header `Authorization: Bearer <token>`.
2. Repite `POST /api/auth/login` para generar token nuevo.
3. Actualiza variable `token` en Postman.

### 1.2 Error 403 - Permisos insuficientes
Sintoma:
- Respuesta `403 Forbidden`.

Causas frecuentes:
- Usuario sin rol admin accediendo a rutas de administracion.
- Token correcto pero con `role_id` no autorizado.

Solucion:
1. Validar rol del usuario en `GET /api/auth/profile`.
2. Usar cuenta admin para endpoints admin/CRUD protegido.

### 1.3 Error 429 - Rate limit excedido
Sintoma:
- Respuesta `429 Too Many Requests`.

Causas frecuentes:
- Muchas peticiones en poco tiempo.
- Pruebas automatizadas muy agresivas sin pausa.

Solucion:
1. Esperar ventana de enfriamiento.
2. Reducir concurrencia o frecuencia de requests.
3. Usar retries con backoff exponencial en clientes.

### 1.4 Error 500 - Error del servidor
Sintoma:
- Respuesta `500 Internal Server Error`.

Causas frecuentes:
- Falla de DB o Redis.
- Datos inconsistentes en request.
- Error no controlado en controller/service.

Solucion:
1. Revisar logs de aplicacion.
2. Verificar conexion DB y migraciones.
3. Confirmar estructura del request y tipos de datos.

## 2. Como debuggear problemas

Checklist rapido:
1. Confirmar base URL correcta (`baseUrl`) en Postman.
2. Verificar token activo en environment.
3. Reproducir request con payload minimo.
4. Comparar respuesta real vs contrato esperado (Swagger/Postman).
5. Revisar stack trace en entorno `development`.

Comandos utiles:
```bash
pnpm run dev
pnpm test
pnpm run test:e2e
```

## 3. Logs utiles

Ubicaciones y tipos:
- Logs HTTP: middleware `src/middleware/httpLogger.middleware.js`.
- Logs de aplicacion: `src/utils/logger.js`.
- Logs locales del proyecto: carpeta `logs/`.

Que revisar en logs:
- Metodo y endpoint.
- Status code y tiempo de respuesta.
- Mensajes de error DB/Redis/JWT.
- Correlacion de hora con peticiones fallidas.

## 4. Soporte

Si el problema persiste, compartir:
1. Endpoint + metodo HTTP.
2. Payload usado (sin credenciales).
3. Status code y body de respuesta.
4. Timestamp aproximado y extracto de logs.
5. Environment usado (dev/staging).

Canal sugerido:
- Abrir issue en el repositorio con etiqueta `bug`.
- Incluir pasos para reproducir y resultado esperado.

## 5. Referencias
- Guia de usuario: `docs/USER-GUIDE.md`.
- Seguridad: `docs/SECURITY.md`.
- Coleccion Postman: `postman/MaqAgr-Backend.postman_collection.json`.
