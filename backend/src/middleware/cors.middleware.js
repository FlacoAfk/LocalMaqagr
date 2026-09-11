import cors from "cors";

const parseExtraOrigins = (value) => {
  if (!value || typeof value !== 'string') return [];

  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
};

const isVercelPreviewOrigin = (origin) => {
  if (!origin || typeof origin !== 'string') return false;

  try {
    const { hostname, protocol } = new URL(origin);
    return protocol === 'https:' && hostname.endsWith('.vercel.app');
  } catch {
    return false;
  }
};

const dedupeOrigins = (origins) => {
  return Array.from(new Set(origins.filter(Boolean)));
};

/**
 * Middleware de configuración dinámica de CORS.
 * Las políticas de acceso cambian dependiendo del entorno (NODE_ENV).
 */
const getCorsOptions = () => {
  const env = process.env.NODE_ENV || "development";
  const currentPort = process.env.PORT || "4000";
  const productionClientUrl = process.env.PROD_CLIENT_URL || "https://app.maqagr.com";
  const sharedExtraOrigins = parseExtraOrigins(process.env.CORS_EXTRA_ORIGINS);
  const productionExtraOrigins = parseExtraOrigins(process.env.PROD_CLIENT_URLS);

  // Orígenes locales del modo single-process (frontend + API en el mismo puerto).
  // Los <script type="module"> y hojas de estilo de Vite envían Origin incluso
  // en peticiones same-origin, así que el propio origen DEBE estar permitido en
  // TODOS los entornos, incluido production (instalador 100% offline local).
  const localOrigins = [
    `http://localhost:${currentPort}`,
    `http://127.0.0.1:${currentPort}`,
  ];

  // Definición de orígenes permitidos por entorno
  const allowedOrigins = {
    development: [
      "http://localhost:3000",
      "http://localhost:5173",
      ...localOrigins,
      "http://127.0.0.1:3000",
      "http://127.0.0.1:5173",
      ...sharedExtraOrigins,
    ],
    staging: [
      process.env.STAGING_CLIENT_URL || "https://staging.maqagr.com",
      ...localOrigins,
      ...sharedExtraOrigins,
    ],
    production: [
      productionClientUrl,
      ...localOrigins,
      ...productionExtraOrigins,
      ...sharedExtraOrigins,
    ],
  };

  const origins = dedupeOrigins(allowedOrigins[env] || allowedOrigins.development);

  return {
    origin: (origin, callback) => {
      // Permitir peticiones sin origin (como de Postman, curl, S2S) o si está en la lista blanca
      if (!origin || origins.indexOf(origin) !== -1 || isVercelPreviewOrigin(origin)) {
        callback(null, true);
      } else {
        // En lugar de usar logger aquí que causaría dependencia circular si app invoca a logger
        callback(new Error("No permitido por la política CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  };
};

export const corsMiddleware = cors(getCorsOptions());
