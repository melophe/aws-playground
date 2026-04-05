import express, { Request, Response } from "express";

const app = express();
const PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;
const VERSION = process.env.APP_VERSION ?? "1.0.0";

app.get("/", (_req: Request, res: Response) => {
  res.json({
    message: "Hello from Code Series Handson!",
    version: VERSION,
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "healthy" });
});

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export { app, server };
