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
  const result = spawnSync("sqlcmd", args, {
    stdio: "inherit",
    env: {
      ...process.env,
      ...(config.sqlAuth ? { SQLCMDPASSWORD: config.dbPassword } : {}),
    },
    windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exitCode = result.status || 1;
  else console.log("Database đã cài và seed sạch: " + name);
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}
