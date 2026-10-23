import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import path from "node:path";
import fs from "node:fs";
import { pathToFileURL } from "node:url";
import { config, backendDirectory } from "./config.js";
import { queryView, withDatabaseRole, close } from "./db.js";
import { authRouter, profileRouter, authenticate, loadActor } from "./auth.js";
import { ordersRouter } from "./orders.js";
import { financeRouter } from "./finance.js";
import { adminRouter } from "./admin.js";
import { supportRouter } from "./support.js";
import { webRouter } from "./web.js";
import { uploadsRouter } from "./uploads.js";
import { ok, wrap, fail } from "./common.js";

export const app = express();
app.disable("x-powered-by");
app.use(helmet({ contentSecurityPolicy: false }));
app.use(
  cors({
    origin: (
      process.env.CLIENT_ORIGINS ||
      "http://localhost:5173,http://localhost:3000"
    ).split(","),
  }),
);
app.use(express.json({ limit: "1mb" }));
app.get("/api/health", (_req, res) => ok(res, { TrangThai: "HoatDong" }));
app.use(
  "/api/auth",
  rateLimit({
    windowMs: 15 * 60000,
    limit: process.env.NODE_ENV === "test" ? 1000 : 100,
  }),
  authRouter,
);
app.get(
  "/api/services",
  wrap(async (req, res) => {
    const actor = req.query.all === "1" ? await loadActor(req) : null;
    if (actor && actor.VaiTro !== "ADMIN")
      fail(403, "Chỉ quản trị được xem danh mục ngừng hoạt động.");
    ok(
      res,
      await withDatabaseRole(actor, () =>
        queryView(actor ? "vw_DichVu" : "vw_DichVuCongKhai"),
      ),
    );
  }),
);
app.get(
  "/api/categories",
  wrap(async (req, res) => {
    const actor = req.query.all === "1" ? await loadActor(req) : null;
    if (actor && actor.VaiTro !== "ADMIN")
      fail(403, "Chỉ quản trị được xem danh mục ngừng hoạt động.");
    ok(
      res,
      await withDatabaseRole(actor, () =>
        queryView("vw_DanhMucDichVu", actor ? {} : { DangHoatDong: true }),
      ),
    );
  }),
);
app.use("/api", authenticate);
app.use("/api", (req, res, next) => {
  withDatabaseRole(
    req.user,
    () =>
      new Promise((resolve) => {
        res.once("finish", resolve);
        res.once("close", resolve);
        next();
      }),
  ).catch(next);
});
app.use("/api/auth", profileRouter);
app.use("/api/web", webRouter);
app.use(
  "/api",
  ordersRouter,
  financeRouter,
  adminRouter,
  supportRouter,
  uploadsRouter,
);
app.use("/api", (_req, res) =>
  res.status(404).json({
    ok: false,
    error: { code: "NOT_FOUND", message: "Không có API này." },
  }),
);
const frontend = path.resolve(backendDirectory, "../frontend/dist");
if (fs.existsSync(frontend)) {
  app.use(express.static(frontend));
  app.get("/{*path}", (_req, res) =>
    res.sendFile(path.join(frontend, "index.html")),
  );
}
app.use((error, _req, res, _next) => {
  if (res.headersSent || res.destroyed) return;
  const number = error.number || error.originalError?.info?.number;
  const sqlMessage = (
    error.originalError?.info?.message ||
    error.message ||
    ""
  ).replace(/^(?:\[[^\]]+\])+\s*/, "");
  let status =
    error.status ||
    {
      51003: 403,
      51004: 404,
      51009: 409,
      2627: 409,
      2601: 409,
      547: 400,
      515: 400,
      229: 403,
      230: 403,
    }[number] ||
    500;
  if (error.code === "LIMIT_FILE_SIZE") status = 400;
  const messages = {
    FORBIDDEN: "Bạn không có quyền thực hiện thao tác này.",
    VERSION_CONFLICT: "Dữ liệu đã thay đổi. Hãy tải lại rồi thử lại.",
    INVALID_TRANSITION: "Không thể chuyển trạng thái theo bước này.",
    INSUFFICIENT_BALANCE: "Ví không đủ số dư.",
    LEDGER_IMMUTABLE: "Giao dịch ví đã ghi không được sửa hoặc xóa.",
  };
  const code =
    error.code ||
    (/^[A-Z_]+$/.test(sqlMessage) ? sqlMessage : "DATABASE_ERROR");
  const message =
    messages[sqlMessage] ||
    (status < 500
      ? number === 2627 || number === 2601
        ? "Dữ liệu đã tồn tại hoặc thao tác bị gửi lặp."
        : sqlMessage
      : "Không thể xử lý yêu cầu. Vui lòng kiểm tra cấu hình và dữ liệu.");
  if (status >= 500)
    console.error("HomeFix error:", number || code, sqlMessage);
  res.status(status).json({ ok: false, error: { code, message } });
});

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  if (!config.jwtSecret || config.jwtSecret.length < 32)
    throw new Error("JWT_SECRET phải có ít nhất 32 ký tự.");
  const server = app.listen(config.port, "127.0.0.1", () =>
    console.log(`HomeFix: http://localhost:${config.port}`),
  );
  async function stop() {
    server.close();
    await close();
  }
  process.once("SIGINT", stop);
  process.once("SIGTERM", stop);
}
