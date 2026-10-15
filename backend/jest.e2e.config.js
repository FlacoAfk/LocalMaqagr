import baseConfig from "./jest.config.js";

export default {
  ...baseConfig,
  // Redirect database configuration before app modules are imported. E2E
  // fixtures perform writes and cleanup, so they must never inherit .env's
  // application database target.
  setupFiles: ["<rootDir>/src/__tests__/e2e/setup-env.js"],
  testMatch: ["**/__tests__/e2e/**/*.test.js"],
  testPathIgnorePatterns: [
    "/node_modules/",
    "/dist/",
    "/build/",
    "/testing/.*\\.test\\.js$",
  ],
  testTimeout: 20000,
  collectCoverageFrom: [],
  coverageThreshold: undefined,
};
