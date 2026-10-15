/**
 * Test Setup para Tests de Integración
 * 
 * Configura variables de entorno y helpers comunes
 * Se ejecuta antes de cada suite de test (setupFilesAfterEnv)
 */

import { jest } from '@jest/globals';

// ============================================
// VARIABLES DE ENTORNO PARA TESTING
// ============================================
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key-for-integration-tests';
process.env.JWT_EXPIRES_IN = '1h';
process.env.BCRYPT_SALT_ROUNDS = '4';

// Cargar variables de .env del proyecto
import * as dotenv from 'dotenv';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const envPath = resolve(__dirname, '../../../.env');
dotenv.config({ path: envPath });

// Preserve the application target before redirecting the app pool to the test DB.
// Destructive test helpers compare both names and must fail closed on collisions.
process.env.MAQAGR_APPLICATION_DB_NAME ??= process.env.DB_NAME || 'maqagr_local';

// Redirect every connection setting used by the app pool, not only DB_NAME.
// This keeps integration requests on the same dedicated local database that
// globalSetup initializes through TEST_DB_*.
process.env.DB_NAME = process.env.TEST_DB_NAME || 'maqagr_test';
process.env.DB_HOST = process.env.TEST_DB_HOST || '127.0.0.1';
process.env.DB_PORT = process.env.TEST_DB_PORT || '5432';
process.env.DB_USER = process.env.TEST_DB_USER || process.env.DB_USER || 'postgres';
process.env.DB_SSL = process.env.TEST_DB_SSL || 'false';

if (process.env.TEST_DB_PASS !== undefined) {
  process.env.DB_PASS = process.env.TEST_DB_PASS;
}

// Timeout más amplio para operaciones de DB
jest.setTimeout(30000);

// Cleanup después de cada test
afterEach(() => {
  jest.restoreAllMocks();
});

afterAll(async () => {
  const { closeSequelize } = await import('../../../src/config/sequelize.js');
  await closeSequelize();
});
