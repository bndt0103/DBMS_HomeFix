import fs from 'node:fs';
import { qRaw as q, close } from '../backend/src/db.js';
import { config } from '../backend/src/config.js';

if (config.database !== 'HomeFix_DBMS_Nhom08_TiengViet') {
  throw new Error('Chỉ xuất bộ dữ liệu mẫu từ HomeFix_DBMS_Nhom08_TiengViet.');
}
const files = [
  '001_schema.sql',
  '002_procedures_triggers.sql',
  '003_cancellation_snapshot.sql',
  '004_auth_otp.sql',
  '005_bank_payments.sql',
  '006_service_catalog.sql',
  '007_user_avatar.sql',
  '007_temporary_account_locks.sql',
  '008_policy_proposals.sql',
  '008_technician_application.sql',
  '009_customer_location.sql',
  '010_functions_views.sql',
  '011_indexes_integrity.sql',
  '012_transactions.sql',
  '013_security.sql',
];
let source = `-- Đồ án Hệ quản trị cơ sở dữ liệu DBMS330284, Nhóm 08.
-- Chạy bằng sqlcmd hoặc bật SQLCMD Mode trong SSMS.
-- Đổi TenCSDL nếu cần; script từ chối ghi vào CSDL đã tồn tại.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08_Import"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO
`;
for (const file of files)
  source += `\n-- ===== ${file} =====\n` + fs.readFileSync('database/' + file, 'utf8') + '\n';
const literal = (value) => {
  if (value === null) return 'NULL';
  if (value instanceof Date) return "'" + value.toISOString() + "'";
  if (typeof value === 'boolean') return value ? '1' : '0';
  if (typeof value === 'number') return String(value);
  return "N'" + String(value).replaceAll("'", "''") + "'";
};
for (const name of ['NguoiDung', 'KyThuatVien', 'DichVu', 'CauHinh', 'GiaoDichVi']) {
  const columns = await q(
    `SELECT name,is_identity AS identityColumn FROM sys.columns
    WHERE object_id=OBJECT_ID(@Ten) AND is_computed=0 AND system_type_id<>189 ORDER BY column_id`,
    { name: 'dbo.' + name },
  );
  const columnList = columns.map((c) => '[' + c.name + ']').join(',');
  const rows = await q(`SELECT ${columnList} FROM dbo.[${name}]`);
  if (columns.some((c) => c.identityColumn)) source += `SET IDENTITY_INSERT dbo.[${name}] ON;\n`;
  for (const row of rows) {
    if (name === 'KyThuatVien') row.SoDu = 0; // Trigger ghi so se tinh lai so du.
    source += `INSERT INTO dbo.[${name}] (${columns.map((c) => '[' + c.name + ']').join(', ')})\nVALUES (${columns.map((c) => literal(row[c.name])).join(', ')});\n`;
  }
  if (columns.some((c) => c.identityColumn)) source += `SET IDENTITY_INSERT dbo.[${name}] OFF;\n`;
  source += 'GO\n';
}
source +=
  'IF NOT EXISTS(SELECT 1 FROM dbo.PhienBanCSDL WHERE PhienBan=6) INSERT dbo.PhienBanCSDL(PhienBan) VALUES(6);\nGO\nDBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;\nGO\n';
fs.mkdirSync('../SQL', { recursive: true });
fs.writeFileSync('../SQL/00_TaoLaiToanBoCSDL.sql', source);
await close();
console.log('Đã xuất script khôi phục đầy đủ lược đồ, phân quyền và dữ liệu mẫu.');
