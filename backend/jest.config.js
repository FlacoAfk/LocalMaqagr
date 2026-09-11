/**
 * Jest Configuration
 * Testing setup para ES Modules
 */

export default {
  // Usar node como entorno de test
  testEnvironment: "node",

  // Patrón de archivos de test
  testMatch: ["**/__tests__/**/*.test.js", "**/?(*.)+(spec|test).js"],

  // Directorios a ignorar
  testPathIgnorePatterns: [
    "/node_modules/",
    "/dist/",
    "/build/",
    "/testing/.*\\.test\\.js$", // Excluir tests legacy (standalone scripts con process.exit)
    "/tests/integration/",
    "/src/__tests__/e2e/",
    "/src/config/db.test.js", // Helper de integración, no contiene tests unitarios
  ],

  // Coverage
  collectCoverageFrom: [
    "src/controllers/**/*.js",
    "src/services/**/*.js",
    "src/middleware/**/*.js",
    "!src/scripts/**",
    "!**/node_modules/**",
  ],

  // Umbral de cobertura core
  coverageThreshold: {
    global: {
      statements: 80,
      branches: 80,
      functions: 80,
      lines: 80,
    },
  },

  // Transformaciones (necesario para ES Modules)
  transform: {},

  // Timeout para tests (útil para tests de DB)
  testTimeout: 10000,

  // Verbose output
  verbose: true,

  // Setup files
  setupFilesAfterEnv: ["<rootDir>/src/__tests__/setup.js"],
};
