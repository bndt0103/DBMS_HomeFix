import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool, close, sql } from "../src/db.js";

// Công cụ DBA chạy riêng; không đăng ký thành API của ứng dụng.
const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);
const modules = [
  "09_data_migration.sql",
  "02_function.sql",
  "03_view.sql",
  "04_sp.sql",
  "05_transaction.sql",
  "06_trigger.sql",
  "07_security.sql",
];
let transaction;
try {
  const connection = await pool();
  const current = await connection
    .request()
    .query(
      "SELECT DB_NAME() AS Ten, OBJECT_ID('dbo.KyThuatVien') AS BangTho, COL_LENGTH('dbo.NguoiDung','HoTen') AS CotTen",
    );
  if (!current.recordset[0].BangTho || !current.recordset[0].CotTen)
    throw new Error("Database thiếu cấu trúc HomeFix cần thiết để nâng cấp.");
  console.log("Nâng cấu trúc, giữ dữ liệu:", current.recordset[0].Ten);
  transaction = new sql.Transaction(connection);
  await transaction.begin();
  await new sql.Request(transaction).query(
    "SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;",
  );
  for (const name of modules) {
    const source = fs.readFileSync(
      path.join(root, "SQL/modules", name),
      "utf8",
    );
    for (const batch of source.split(/^GO\s*$/im).filter((s) => s.trim()))
      await new sql.Request(transaction).batch(batch);
    console.log("OK", name);
  }
  await transaction.commit();
  transaction = null;
} finally {
  if (transaction) await transaction.rollback().catch(() => {});
  await close();
}
