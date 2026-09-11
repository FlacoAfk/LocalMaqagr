import baseConfig from "./jest.config.js";

export default {
  ...baseConfig,
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
