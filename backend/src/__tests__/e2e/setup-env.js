import { assertSafeTestDatabaseTarget } from '../../config/db.test.js';

process.env.NODE_ENV = 'test';

// db.test.js loads the project's .env first; preserve that application target
// before redirecting the application pool used by E2E suites.
process.env.MAQAGR_APPLICATION_DB_NAME ??= process.env.DB_NAME || 'maqagr_local';

const databaseName = process.env.TEST_DB_NAME || 'maqagr_test';
const host = process.env.TEST_DB_HOST || '127.0.0.1';
const port = Number.parseInt(process.env.TEST_DB_PORT || '5432', 10);

process.env.DB_NAME = databaseName;
process.env.DB_HOST = host;
process.env.DB_PORT = String(port);
process.env.DB_USER = process.env.TEST_DB_USER || process.env.DB_USER || 'postgres';
process.env.DB_SSL = process.env.TEST_DB_SSL || 'false';

if (process.env.TEST_DB_PASS !== undefined) {
  process.env.DB_PASS = process.env.TEST_DB_PASS;
}

assertSafeTestDatabaseTarget({
  databaseName,
  host,
  port,
  applicationDatabaseName: process.env.MAQAGR_APPLICATION_DB_NAME,
});
