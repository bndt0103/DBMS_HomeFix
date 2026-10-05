import { q, one } from './db.js';

// Only return work visible to the current user; do not infer tasks from unread messages.
export async function attentionSummary(user) {
  const unread = await one(
    'SELECT COUNT(*) n FROM dbo.ThongBao WHERE NguoiDungId=@uid AND NgayDoc IS NULL',
    { uid: user.id },
  );
  let condition = '';
  if (user.role === 'KH')
    condition = `d.KhachHangId=@uid AND (
  d.TrangThai IN('ChoDuyetSoBo','ChoNghiemThu')
  OR (d.TrangThai='DangXuLy' AND EXISTS(SELECT 1 FROM dbo.DeXuatVatTu m WHERE m.DonHangId=d.Id AND m.TrangThai='Pending'))
  OR (d.TrangThai='HoanThanh' AND NOT EXISTS(SELECT 1 FROM dbo.ThanhToan p WHERE p.DonHangId=d.Id)
   AND NOT EXISTS(SELECT 1 FROM dbo.YeuCauThanhToan r WHERE r.DonHangId=d.Id AND r.DangHoatDong=1 AND r.TrangThai='PendingReview'))
 )`;
  if (user.role === 'DPV') condition = "d.TrangThai IN('ChoTiepNhan','ChoPhanCong')";
  if (user.role === 'KTV')
    condition = `d.KyThuatVienDuocGiaoId=@uid AND (
  (d.TrangThai='ChoNhan' AND EXISTS(SELECT 1 FROM dbo.LenhDieuPhoi a WHERE a.DonHangId=d.Id AND a.KyThuatVienId=@uid AND a.DangHoatDong=1 AND a.TrangThai='Pending' AND a.NgayHetHan>SYSUTCDATETIME()))
  OR d.TrangThai IN('DaTiepNhan','DangDiChuyen','DaDenNoi')
  OR (d.TrangThai='DangXuLy' AND NOT EXISTS(SELECT 1 FROM dbo.DeXuatVatTu m WHERE m.DonHangId=d.Id AND m.TrangThai='Pending'))
  OR (d.TrangThai='HoanThanh' AND COALESCE(d.PhuongThucThanhToan,'COD')='COD' AND NOT EXISTS(SELECT 1 FROM dbo.ThanhToan p WHERE p.DonHangId=d.Id))
 )`;
  const orders = condition
    ? await q(
        'SELECT d.Id,d.TrangThai,d.TenDichVu FROM dbo.DonHang d WHERE ' +
          condition +
          ' ORDER BY d.Id DESC',
        { uid: user.id },
      )
    : [];
  const finance =
    user.role === 'KT'
      ? await one(`SELECT
  (SELECT COUNT(*) FROM dbo.DoiSoat WHERE TrangThai='Pending') settlements,
  (SELECT COUNT(*) FROM dbo.YeuCauThanhToan WHERE DangHoatDong=1 AND TrangThai='PendingReview') bank,
  (SELECT COUNT(*) FROM dbo.YeuCauVi WHERE TrangThai='Pending') wallet`)
      : { settlements: 0, bank: 0, wallet: 0 };
  const support =
    user.role === 'CSKH'
      ? await one(
          `SELECT
  COUNT(*) n
FROM
  dbo.YeuCauHoTro
WHERE
  TrangThai IN ('Open', 'InProgress')
  AND (
    NguoiDuocGiaoId IS NULL
    OR NguoiDuocGiaoId = @uid
  )`,
          { uid: user.id },
        )
      : { n: 0 };
  const applications =
    user.role === 'ADMIN'
      ? await one("SELECT COUNT(*) n FROM dbo.HoSoKTV WHERE TrangThai='Pending'")
      : { n: 0 };
  return {
    unread: Number(unread.n),
    orderIds: orders.map((o) => o.id),
    orders,
    finance,
    support: Number(support.n),
    applications: Number(applications.n),
  };
}
