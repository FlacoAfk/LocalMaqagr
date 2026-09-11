# 🔒 Seguridad - BackMaqAgr

Documentación de las medidas de seguridad implementadas en la API.

---

## Tabla de Contenidos

- [Resumen de Protecciones](#-resumen-de-protecciones)
- [Helmet (Headers HTTP)](#-helmet-headers-http)
- [Rate Limiting](#-rate-limiting)
- [CORS](#-cors-por-entorno)
- [Sanitización (XSS / SQL Injection)](#-sanitización-xss--sql-injection)
- [Autenticación JWT](#-autenticación-jwt)
- [OWASP Top 10 - Mitigaciones](#-owasp-top-10---mitigaciones)
- [Checklist de Seguridad](#-checklist-de-seguridad)

---

## 🛡️ Resumen de Protecciones

| Capa                | Herramienta          | Archivo                                    |
| ------------------- | -------------------- | ------------------------------------------ |
| Headers HTTP        | Helmet               | `src/middleware/security.middleware.js`    |
| Rate Limiting       | express-rate-limit   | `src/middleware/rateLimiter.middleware.js` |
| CORS                | cors (dinámico)      | `src/middleware/cors.middleware.js`        |
| XSS / SQL Injection | xss + custom         | `src/middleware/sanitize.middleware.js`    |
| Autenticación       | JWT (jsonwebtoken)   | `src/middleware/auth.middleware.js`        |
| Contraseñas         | bcrypt (hash + salt) | `src/controllers/authController.js`        |

---

## 🪖 Helmet (Headers HTTP)

**Archivo:** `src/middleware/security.middleware.js`

Helmet configura automáticamente headers HTTP de seguridad en cada respuesta:

| Header                      | Valor                                                         | Propósito                            |
| --------------------------- | ------------------------------------------------------------- | ------------------------------------ |
| `X-Powered-By`              | _(removido)_                                                  | No revelar tecnología del servidor   |
| `X-Frame-Options`           | `DENY`                                                        | Prevenir clickjacking                |
| `X-Content-Type-Options`    | `nosniff`                                                     | Prevenir MIME sniffing               |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload`                | Forzar HTTPS                         |
| `Content-Security-Policy`   | `default-src 'self'; script-src 'self'; object-src 'none'...` | Prevenir XSS e inyección de recursos |
| `X-DNS-Prefetch-Control`    | `off`                                                         | Prevenir fuga de información DNS     |
| `Referrer-Policy`           | `strict-origin-when-cross-origin`                             | Controlar información del referrer   |

---

## ⏱️ Rate Limiting

**Archivo:** `src/middleware/rateLimiter.middleware.js`

Tres niveles de protección contra abuso:

| Limitador       | Límite         | Ventana | Aplicado en                                                         |
| --------------- | -------------- | ------- | ------------------------------------------------------------------- |
| `loginLimiter`  | 5 intentos     | 15 min  | `POST /api/auth/login`                                              |
| `publicLimiter` | 50 peticiones  | 15 min  | `POST /api/auth/register`                                           |
| `apiLimiter`    | 100 peticiones | 15 min  | Todas las rutas de dominio (`/api/tractors`, `/api/terrains`, etc.) |

**Respuesta al exceder el límite (HTTP 429):**

```json
{
  "success": false,
  "message": "Demasiados intentos de inicio de sesión. Por favor, intente de nuevo en 15 minutos."
}
```

---

## 🌐 CORS por Entorno

**Archivo:** `src/middleware/cors.middleware.js`

Los orígenes permitidos cambian según `NODE_ENV`:

| Entorno       | Orígenes Permitidos                                                    |
| ------------- | ---------------------------------------------------------------------- |
| `development` | `localhost:3000`, `localhost:5173`, `127.0.0.1:3000`, `127.0.0.1:5173` |
| `staging`     | `STAGING_CLIENT_URL` (env var)                                         |
| `production`  | `PROD_CLIENT_URL` (env var)                                            |

**Configuración adicional:**

- `credentials: true` — Permite cookies y headers de autorización
- `methods: GET, POST, PUT, DELETE` — Métodos permitidos
- `allowedHeaders: Content-Type, Authorization` — Headers permitidos
- Peticiones sin `Origin` (Postman, curl, S2S) son permitidas

---

## 🧹 Sanitización (XSS / SQL Injection)

**Archivos:** `src/middleware/sanitize.middleware.js` y `src/utils/validators.util.js`

### XSS Protection

- Usa la librería [`xss`](https://www.npmjs.com/package/xss) (activamente mantenida)
- Filtra `<script>`, `onerror`, `onmouseover`, y otros vectores HTML/JS
- Se aplica recursivamente a objetos anidados en `req.body`

### SQL Injection Protection

- Escapa comillas simples (`'` → `''`)
- Remueve comentarios SQL (`--`, `/* */`)
- Remueve punto y coma (`;`) para evitar múltiples sentencias
- **Defensa en profundidad:** Las consultas parametrizadas de `pg` son la defensa primaria

### Orden de sanitización

1. `sanitizeSQLInput()` — Opera sobre texto plano
2. `sanitizeString()` (xss) — Codifica entidades HTML

---

## 🔑 Autenticación JWT

- **Algoritmo:** HS256
- **Expiración:** 24 horas (configurable via `JWT_EXPIRES_IN`)
- **Contraseñas:** Hasheadas con bcrypt (salt rounds configurables)
- **Middleware:** `verifyTokenMiddleware` valida el token en rutas protegidas

---

## 📋 OWASP Top 10 - Mitigaciones

| #   | Riesgo OWASP                  | Estado | Mitigación                                                                             |
| --- | ----------------------------- | ------ | -------------------------------------------------------------------------------------- |
| A01 | **Broken Access Control**     | ✅     | JWT con verificación de roles, CORS restrictivo, `X-Frame-Options: DENY`               |
| A02 | **Cryptographic Failures**    | ✅     | Contraseñas con bcrypt, HSTS forzando HTTPS, JWT con secret fuerte                     |
| A03 | **Injection**                 | ✅     | Sanitización XSS/SQL, consultas parametrizadas (pg), validadores robustos              |
| A04 | **Insecure Design**           | ✅     | Defensa en profundidad (múltiples capas), rate limiting, validación de inputs          |
| A05 | **Security Misconfiguration** | ✅     | Helmet (headers seguros), CSP estricto, `X-Powered-By` removido                        |
| A06 | **Vulnerable Components**     | ⚠️     | Dependencias actualizadas, `pnpm audit` recomendado en CI/CD                            |
| A07 | **Auth Failures**             | ✅     | Rate limiting en login (5 intentos/15min), contraseñas fuertes requeridas              |
| A08 | **Data Integrity Failures**   | ✅     | Input sanitizado antes de procesamiento, CSP bloquea scripts externos                  |
| A09 | **Logging & Monitoring**      | ✅     | Logger centralizado con niveles (ERROR, WARN, INFO, DEBUG), HTTP request logging       |
| A10 | **SSRF**                      | ✅     | CSP `default-src 'self'`, no se realizan peticiones a URLs proporcionadas por usuarios |

---

## ✅ Checklist de Seguridad

### Headers HTTP

- [x] Helmet configurado con opciones avanzadas
- [x] Content Security Policy (CSP) con directivas restrictivas
- [x] X-Frame-Options: DENY
- [x] X-Content-Type-Options: nosniff
- [x] HSTS con preload habilitado
- [x] X-Powered-By removido
- [x] Referrer-Policy configurado

### Rate Limiting

- [x] Login: 5 intentos / 15 min
- [x] API general: 100 peticiones / 15 min
- [x] Rutas públicas: 50 peticiones / 15 min
- [x] Mensajes de error en formato JSend
- [x] Headers estándar de rate limiting incluidos

### CORS

- [x] Orígenes configurados por entorno (dev/staging/prod)
- [x] Credentials habilitados
- [x] Métodos restringidos (GET, POST, PUT, DELETE)
- [x] Headers permitidos (Content-Type, Authorization)
- [x] Orígenes no autorizados son bloqueados

### Sanitización

- [x] XSS: Filtrado de HTML/JS peligroso (librería `xss`)
- [x] SQL Injection: Escape de comillas, remoción de comentarios y punto y coma
- [x] Sanitización recursiva de objetos anidados
- [x] Compatible con Express 5 (req.query read-only)

### Autenticación

- [x] JWT con expiración de 24h
- [x] Contraseñas hasheadas con bcrypt
- [x] Validación de contraseña fuerte (8+ chars, mayúscula, número)
- [x] Middleware de verificación de token

### Testing

- [x] 30 tests de seguridad automatizados
- [x] Tests de Helmet (7 tests)
- [x] Tests de Rate Limiting (6 tests)
- [x] Tests de CORS (7 tests)
- [x] Tests de Sanitización XSS/SQL (10 tests)

---

## 🧪 Ejecutar Tests de Seguridad

```bash
# Todos los tests de seguridad
node --experimental-vm-modules node_modules/jest/bin/jest.js tests/security/

# Test específico
node --experimental-vm-modules node_modules/jest/bin/jest.js tests/security/helmet.test.js
```
