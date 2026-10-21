import fs from 'node:fs';
import { qRaw as q, close } from '../backend/src/db.js';
import { config } from '../backend/src/config.js';

if (
  config.database !== 'HomeFix_DBMS_Nhom08' &&
  config.database !== 'HomeFix_DBMS_Nhom08_TiengViet'
) {
  throw new Error(
    'Chỉ xuất bộ dữ liệu mẫu từ HomeFix_DBMS_Nhom08 hoặc HomeFix_DBMS_Nhom08_TiengViet.',
  );
}
let source = '';
const literal = (value) => {
  if (value === null) return 'NULL';
  if (value instanceof Date) return "'" + value.toISOString() + "'";
  if (typeof value === 'boolean') return value ? '1' : '0';
  if (typeof value === 'number') return String(value);
  return "N'" + String(value).replaceAll("'", "''") + "'";
};
source += '\n-- Dữ liệu mẫu phục vụ vận hành.\n';
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
    if (name === 'KyThuatVien') row.SoDu = 0; // Trigger tính lại số dư từ sổ ví.
    source += `INSERT INTO dbo.[${name}] (${columns.map((c) => '[' + c.name + ']').join(', ')})\nVALUES (${columns.map((c) => literal(row[c.name])).join(', ')});\n`;
  }
  if (columns.some((c) => c.identityColumn)) source += `SET IDENTITY_INSERT dbo.[${name}] OFF;\n`;
  source += 'GO\n';
}
source +=
  'IF NOT EXISTS (SELECT 1 FROM dbo.PhienBanCSDL WHERE PhienBan = 6)\n    INSERT dbo.PhienBanCSDL(PhienBan) VALUES(6);\nGO\n\n-- Kiểm tra toàn bộ ràng buộc dữ liệu.\nDBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;\nGO\n';
fs.writeFileSync(new URL('../database/sample-data.sql', import.meta.url), source);
await import('./build-sql.js');
await close();
console.log('Đã xuất script khôi phục đầy đủ lược đồ, phân quyền và dữ liệu mẫu.');
