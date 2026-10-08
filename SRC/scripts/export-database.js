import fs from 'node:fs';
import { qRaw as q, close } from '../backend/src/db.js';
import { config } from '../backend/src/config.js';

if (config.database !== 'HomeFix_DBMS_Nhom08_TiengViet') {
  throw new Error('Chỉ xuất bộ dữ liệu mẫu từ HomeFix_DBMS_Nhom08_TiengViet.');
}
const files = [
  'CSDL_HomeFix_01_BangVaRangBuoc.sql',
  'CSDL_HomeFix_02_ThuTucVaTrigger.sql',
  'CSDL_HomeFix_03_PhiHuyDon.sql',
  'CSDL_HomeFix_04_XacThucOTP.sql',
  'CSDL_HomeFix_05_ThanhToanNganHang.sql',
  'CSDL_HomeFix_06_DanhMucDichVu.sql',
  'CSDL_HomeFix_07_AnhDaiDien.sql',
  'CSDL_HomeFix_08_KhoaTaiKhoan.sql',
  'CSDL_HomeFix_09_DeXuatChinhSach.sql',
  'CSDL_HomeFix_10_HoSoKyThuatVien.sql',
  'CSDL_HomeFix_11_ViTriKhachHang.sql',
  'CSDL_HomeFix_12_HamVaView.sql',
  'CSDL_HomeFix_13_ChiMucVaToanVen.sql',
  'CSDL_HomeFix_14_GiaoDich.sql',
  'CSDL_HomeFix_15_PhanQuyen.sql',
];
let source = `-- Khởi tạo cơ sở dữ liệu HomeFix bằng SQLCMD.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08_Import"

-- Tạo cơ sở dữ liệu mới.
USE master;
GO

IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO

USE [$(TenCSDL)];
GO
`;
for (const file of files) source += '\n' + fs.readFileSync('database/' + file, 'utf8');
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
fs.mkdirSync('../SQL', { recursive: true });
fs.writeFileSync('../SQL/CSDL_HomeFix.sql', source);
await close();
console.log('Đã xuất script khôi phục đầy đủ lược đồ, phân quyền và dữ liệu mẫu.');
