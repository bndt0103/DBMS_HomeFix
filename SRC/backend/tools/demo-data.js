import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../src/config.js";
import { pool, close } from "../src/db.js";

// Công cụ dữ liệu học tập, chạy riêng; không đăng ký thêm API.
const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);
if (!/^HomeFix_[A-Za-z0-9_]+$/.test(config.database))
  throw new Error("Tên database HomeFix không hợp lệ.");
try {
  const connection = await pool();
  const script = fs
    .readFileSync(path.join(root, "SQL/du_lieu_mau.sql"), "utf8")
    .replace("USE [HomeFix_DBMS_Clean_20261022];", `USE [${config.database}];`);
  for (const batch of script.split(/^GO\s*$/im).filter((s) => s.trim())) {
    await connection.request().batch(batch);
  }
  const result = await connection.request().query(`
    SELECT DB_NAME() AS TenCSDL,
      (SELECT COUNT(*) FROM dbo.NguoiDung) AS SoTaiKhoan,
      (SELECT COUNT(*) FROM dbo.DichVu) AS SoDichVu,
      (SELECT COUNT(*) FROM dbo.DonHang WHERE MoTa LIKE N'[[]MINHHOA-%') AS SoDonMinhHoa,
      (SELECT COUNT(*) FROM dbo.vw_ViKyThuatVien WHERE ChenhLech <> 0) AS SoViLech;
  `);
  const summary = result.recordset[0];
  if (summary.SoDonMinhHoa !== 10 || summary.SoViLech !== 0)
    throw new Error("Dữ liệu minh họa hoặc đối chiếu ví không đạt.");
  console.log(JSON.stringify(summary, null, 2));
  console.log(
    "Đã chuẩn bị dữ liệu SQL minh họa, không tạo file ảnh. Mật khẩu tài khoản mới: 123456.",
  );
} finally {
  await close();
}
