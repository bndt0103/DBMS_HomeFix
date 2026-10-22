import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const backendDirectory = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
dotenv.config({ path: path.join(backendDirectory, ".env"), quiet: true });
export const config = {
  server: process.env.DB_SERVER || "localhost\\SQLEXPRESS",
  database: process.env.DB_NAME || "HomeFix_DBMS_Nhom08",
  sqlAuth: process.env.DB_AUTH === "sql",
  dbUser: process.env.DB_USER,
  dbPassword: process.env.DB_PASSWORD,
  jwtSecret: process.env.JWT_SECRET,
  port: Number(process.env.PORT || 3000),
  uploads: process.env.UPLOADS_DIR
    ? path.resolve(process.env.UPLOADS_DIR)
    : path.join(backendDirectory, "uploads"),
  impersonate: process.env.DB_IMPERSONATE !== "false",
};
