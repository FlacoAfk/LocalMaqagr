import { describe, expect, test } from "@jest/globals";

describe("regression bugs", () => {
  test("admin routes can be imported without duplicate middleware declarations", async () => {
    await expect(
      import("../../src/routes/admin.routes.js"),
    ).resolves.toHaveProperty("default");
  });
});
