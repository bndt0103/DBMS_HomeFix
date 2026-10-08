import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const env = path.join(root, 'backend/.env');
if (!fs.existsSync(env)) {
  const template = fs
    .readFileSync(env + '.example', 'utf8')
    .replace(
      'replace-with-a-random-value-at-least-32-characters',
      crypto.randomBytes(48).toString('base64url'),
    );
  fs.writeFileSync(env, template);
}
const { config, dbConfig } = await import('../backend/src/config.js');
const { sql, q, one, transaction, close } = await import('../backend/src/db.js');
const { applyServiceCatalog } = await import('./service-catalog.js');
const bcrypt = (await import('bcryptjs')).default;
if (!config.database.startsWith('HomeFix_DBMS'))
  throw new Error('Chỉ khởi tạo CSDL có tiền tố HomeFix_DBMS.');
if (!/^[A-Za-z][A-Za-z0-9_]{0,60}$/.test(config.database)) throw new Error('DB_NAME không hợp lệ.');
const master = await new sql.ConnectionPool(dbConfig('master')).connect();
const exists = await one(
  'SELECT database_id FROM sys.databases WHERE name=@Ten',
  { name: config.database },
  master,
);
if (!exists) await master.request().query(`CREATE DATABASE [${config.database}]`);
await master.close();
const v = await one("SELECT OBJECT_ID('dbo.PhienBanCSDL') AS Id");
if (!v.id) {
  const existing = await one('SELECT COUNT(*) n FROM sys.tables');
  if (existing.n) throw new Error('DB đã có bảng khác. Chọn DB_NAME trống để bảo vệ dữ liệu.');
  const text = fs.readFileSync(
    path.join(root, 'database/CSDL_HomeFix_01_BangVaRangBuoc.sql'),
    'utf8',
  );
  for (const batch of text.split(/^GO\s*$/m).filter((x) => x.trim())) await q(batch);
}
for (const filename of [
  'CSDL_HomeFix_02_ThuTucVaTrigger.sql',
  'CSDL_HomeFix_03_PhiHuyDon.sql',
  'CSDL_HomeFix_04_XacThucOTP.sql',
  'CSDL_HomeFix_05_ThanhToanNganHang.sql',
  'CSDL_HomeFix_07_AnhDaiDien.sql',
  'CSDL_HomeFix_08_KhoaTaiKhoan.sql',
  'CSDL_HomeFix_09_DeXuatChinhSach.sql',
  'CSDL_HomeFix_10_HoSoKyThuatVien.sql',
  'CSDL_HomeFix_11_ViTriKhachHang.sql',
  'CSDL_HomeFix_12_HamVaView.sql',
  'CSDL_HomeFix_13_ChiMucVaToanVen.sql',
  'CSDL_HomeFix_14_GiaoDich.sql',
  'CSDL_HomeFix_15_PhanQuyen.sql',
])
  for (const batch of fs
    .readFileSync(path.join(root, 'database', filename), 'utf8')
    .split(/^GO\s*$/m)
    .filter((x) => x.trim()))
    await q(batch);
const hash = await bcrypt.hash('HomeFix@123', 12);
await transaction(null, async (t) => {
  const demo = [
    ['KH', 'Khách hàng An', 'kh'],
    ['KTV', 'Kỹ thuật viên Minh', 'ktv'],
    ['DPV', 'Điều phối Linh', 'dpv'],
    ['CSKH', 'Chăm sóc khách hàng', 'cskh'],
    ['KT', 'Kế toán Hạnh', 'kt'],
    ['ADMIN', 'Quản trị HomeFix', 'admin'],
    ['GD', 'Giám đốc HomeFix', 'gd'],
    ['KH', 'Khách hàng Bình', 'kh2'],
    ['KTV', 'Kỹ thuật viên Nam', 'ktv2'],
  ];
  for (let i = 0; i < demo.length; i++) {
    const [role, name, login] = demo[i];
    const email = login + '@homefix.local';
    if (await one('SELECT Id FROM dbo.NguoiDung WHERE Email=@Email', { email }, t)) continue;
    const u = await one(
      "INSERT dbo.NguoiDung(HoTen,SoDienThoai,Email,MatKhauBam,VaiTro,DiaChiMacDinh) OUTPUT INSERTED.Id VALUES(@Ten,@SoDienThoai,@Email,@hash,@VaiTro,N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM')",
      { name, phone: '090000000' + (i + 1), email, hash, role },
      t,
    );
    if (role === 'KTV') {
      await q(
        "INSERT dbo.KyThuatVien(Id,NhomTayNghe,KhuVucPhucVu,TrangThaiSanSang) VALUES(@Id,N'DienLanh',N'TP.HCM','SanSang')",
        { id: u.id },
        t,
      );
      await q(
        "INSERT dbo.GiaoDichVi(KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu) VALUES(@Id,'Opening',1000000,'Opening',@Id,N'Số dư mở đầu bộ dữ liệu demo')",
        { id: u.id },
        t,
      );
    }
  }
  await applyServiceCatalog(t);
  for (const [key, value, label] of [
    ['minimumWallet', '200000', 'Số dư tối thiểu nhận việc'],
    ['assignmentMinutes', '10', 'Phút phản hồi lệnh'],
    ['cancellationFee', '50000', 'Phí hủy khi đang di chuyển'],
    ['signatureRequired', 'false', 'Yêu cầu chữ ký nghiệm thu'],
  ])
    if (
      !(await one(
        'SELECT [KhoaCauHinh] FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh',
        { key },
        t,
      ))
    )
      await q(
        'INSERT dbo.CauHinh([KhoaCauHinh],GiaTri,NhanHienThi) VALUES(@KhoaCauHinh,@GiaTri,@NhanHienThi)',
        { key, value, label },
        t,
      );
});
await close();
console.log(
  'DB ready: ' + config.database + '. Seed giữ nguyên dữ liệu và mật khẩu tài khoản đã tồn tại.',
);
