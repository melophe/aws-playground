import request from "supertest";
import { app, server } from "./server";

describe("GET /", () => {
  it("returns message and version", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Hello from Code Series Handson!");
    expect(res.body.version).toBeDefined();
    expect(res.body.timestamp).toBeDefined();
  });
});

describe("GET /health", () => {
  it("returns healthy status", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("healthy");
  });
});

afterAll(() => {
  server.close();
});
