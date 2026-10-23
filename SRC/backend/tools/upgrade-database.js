import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool, close, sql } from "../src/db.js";
import { splitSqlBatches } from "./sql-batches.js";

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
  "10_backup_recovery.sql",
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
  const schema = fs.readFileSync(
    path.join(root, "SQL/modules/00_schema.sql"),
    "utf8",
  );
  const tables = new Set(
    [...schema.matchAll(/CREATE TABLE dbo\.(\w+)/g)].map((m) => m[1]),
  );
  const actual = await connection
    .request()
    .query(
      "SELECT t.name FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 AND s.name='dbo'",
    );
  if (actual.recordset.some((row) => !tables.has(row.name)))
    throw new Error(
      "Database còn bảng ngoài cấu trúc HomeFix hiện hành. Sao lưu và cài CSDL_HomeFix.sql vào database mới; công cụ này chỉ nâng cấp cấu trúc hiện hành.",
    );
  console.log(
    "Nâng cấu trúc, giữ dữ liệu nghiệp vụ:",
    current.recordset[0].Ten,
  );
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
    for (const batch of splitSqlBatches(source))
      await new sql.Request(transaction).batch(batch);
    console.log("OK", name);
  }
  await transaction.commit();
  transaction = null;
} finally {
  if (transaction) await transaction.rollback().catch(() => {});
  await close();
}
