import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { config } from "../src/config.js";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);
const name = process.env.DB_NAME || config.database;
if (!/^HomeFix_[A-Za-z0-9_]+$/.test(name))
  throw new Error(
    "DB_NAME phải bắt đầu HomeFix_ và chỉ gồm chữ, số, dấu gạch dưới.",
  );
const source = fs
  .readFileSync(path.join(root, "SQL", "CSDL_HomeFix.sql"), "utf8")
  .replace(
    ':setvar TenCSDL "HomeFix_DBMS_Nhom08"',
    `:setvar TenCSDL "${name}"`,
  );
const temp = fs.mkdtempSync(path.join(os.tmpdir(), "homefix-install-"));
try {
  const file = path.join(temp, "install.sql");
  fs.writeFileSync(file, "\uFEFF" + source, "utf8");
  const args = ["-S", config.server, "-C", "-b", "-f", "65001", "-i", file];
  if (config.sqlAuth) args.push("-U", config.dbUser);
  else args.push("-E");
  let executed = false;
  try {
    const result = spawnSync("sqlcmd", args, {
      stdio: "inherit",
      env: {
        ...process.env,
        ...(config.sqlAuth ? { SQLCMDPASSWORD: config.dbPassword } : {}),
      },
      windowsHide: true,
    });
    if (result.error) {
      if (result.error.code === "ENOENT") {
        console.log("sqlcmd không có trong PATH, chuyển sang cài đặt trực tiếp bằng Node.js...");
      } else {
        throw result.error;
      }
    } else {
      executed = true;
      if (result.status !== 0) process.exitCode = result.status || 1;
      else console.log("Database đã cài và seed sạch: " + name);
    }
  } catch (err) {
    if (err.code !== "ENOENT") throw err;
  }

  if (!executed) {
    const { sql, databaseConfig } = await import("../src/db.js");
    const masterPool = await new sql.ConnectionPool(databaseConfig("master")).connect();
    try {
      const check = await masterPool.request().query(`SELECT DB_ID(N'${name}') AS id`);
      if (check.recordset[0].id) {
        throw new Error(`Database ${name} đã tồn tại. Hãy chọn tên khác theo quy định để bảo đảm dữ liệu sạch.`);
      }
      await masterPool.request().query(`CREATE DATABASE [${name}]`);
    } finally {
      await masterPool.close();
    }

    const dbPool = await new sql.ConnectionPool(databaseConfig(name)).connect();
    try {
      const modulesFolder = path.join(root, "SQL", "modules");
      const moduleNames = [
        "00_schema.sql",
        "01_index.sql",
        "02_function.sql",
        "03_view.sql",
        "04_sp.sql",
        "05_transaction.sql",
        "06_trigger.sql",
        "07_security.sql",
        "08_seed.sql",
        "09_data_migration.sql",
        "10_backup_recovery.sql",
      ];
      for (const m of moduleNames) {
        const content = fs.readFileSync(path.join(modulesFolder, m), "utf8").replace(/^\uFEFF/, "");
        const batches = content.split(/^GO\s*$/im);
        for (const batch of batches) {
          const trimmed = batch.trim();
          if (!trimmed) continue;
          await dbPool.request().batch(trimmed);
        }
      }
      console.log("Database đã cài và seed sạch: " + name);
    } finally {
      await dbPool.close();
    }
  }
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}

