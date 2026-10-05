import { Router } from 'express';
import { q, one, transaction } from './db.js';
import { z, str, ok, wrap, roles, fail, notify, checkVersion, versionSchema } from './common.js';
export const reportsRouter = Router();
function period(req) {
  const schema = z.iso.datetime({ offset: true }),
    from = req.query.from
      ? new Date(schema.parse(req.query.from))
      : new Date('2020-01-01T00:00:00Z'),
    to = req.query.to ? new Date(schema.parse(req.query.to)) : new Date(Date.now() + 86400000);
  if (from >= to) fail(422, 'INVALID_PERIOD', 'Ngày kết thúc phải sau ngày bắt đầu.');
  return { from, to };
}
reportsRouter.get(
  '/reports/quality',
  roles('GD', 'CSKH'),
  wrap(async (req, res) => {
    const p = period(req);
    const customers = await one(
      `SELECT (SELECT COUNT(*) FROM dbo.NguoiDung WHERE VaiTro='KH' AND NgayTao>=@from AND NgayTao<@to) newCustomers,
 (SELECT COUNT(DISTINCT KhachHangId) FROM dbo.DonHang WHERE NgayTao>=@from AND NgayTao<@to) activeCustomers,
 (SELECT COUNT(*) FROM dbo.DonHang WHERE NgayTao>=@from AND NgayTao<@to) TongSoDon,
 (SELECT COUNT(*) FROM dbo.ThanhToan WHERE NgayThanhToan>=@from AND NgayThanhToan<@to) SoDonHoanThanh,
 (SELECT COUNT(DISTINCT o.KhachHangId) FROM dbo.ThanhToan p JOIN dbo.DonHang o ON o.Id=p.DonHangId WHERE p.NgayThanhToan>=@from AND p.NgayThanhToan<@to) servedCustomers,
 (SELECT COUNT(DISTINCT o.Id) FROM dbo.DonHang o JOIN dbo.YeuCauHoTro t ON t.DonHangId=o.Id AND t.Loai='Complaint' WHERE o.NgayTao>=@from AND o.NgayTao<@to) complaintOrders`,
      p,
    );
    const ratings = await q(
      'SELECT DiemDanhGia,COUNT(*) count FROM dbo.DanhGia WHERE NgayTao>=@from AND NgayTao<@to GROUP BY DiemDanhGia',
      p,
    );
    const lowRatings = await q(
      `SELECT TOP 100 r.DonHangId,r.DiemDanhGia,r.NhanXet,r.NgayTao,o.TenLienHe,o.SoDienThoaiLienHe,n.HoTen TenKyThuatVien
 FROM dbo.DanhGia r JOIN dbo.DonHang o ON o.Id=r.DonHangId LEFT JOIN dbo.NguoiDung n ON n.Id=r.KyThuatVienId
 WHERE r.DiemDanhGia<3 AND r.NgayTao>=@from AND r.NgayTao<@to ORDER BY r.NgayTao DESC`,
      p,
    );
    const complaints = await q(
      `SELECT TOP 100 t.Id,t.DonHangId,t.MoTa,t.TrangThai,t.NgayTao,n.HoTen TenKhachHang
 FROM dbo.YeuCauHoTro t JOIN dbo.NguoiDung n ON n.Id=t.KhachHangId WHERE t.Loai='Complaint' AND t.NgayTao>=@from AND t.NgayTao<@to ORDER BY t.Id DESC`,
      p,
    );
    const total = ratings.reduce((sum, r) => sum + Number(r.count), 0),
      averageRating = total
        ? ratings.reduce((sum, r) => sum + Number(r.count) * r.rating, 0) / total
        : null;
    ok(res, {
      ...customers,
      averageRating,
      reviews: total,
      ratings,
      lowRatings,
      complaints,
      complaintRate: Number(customers.totalOrders)
        ? (100 * Number(customers.complaintOrders)) / Number(customers.totalOrders)
        : null,
    });
  }),
);
reportsRouter.get(
  '/reports/performance',
  roles('GD', 'KT', 'DPV', 'CSKH'),
  wrap(async (req, res) => {
    const rows = await q(
      `SELECT k.Id,n.HoTen,k.NhomTayNghe,k.TrangThaiSanSang,n.DangHoatDong,n.NgayTao,
 (SELECT COUNT(DISTINCT a.DonHangId) FROM dbo.LenhDieuPhoi a WHERE a.KyThuatVienId=k.Id AND a.TrangThai='Accepted' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to) assignedOrders,
 (SELECT COUNT(DISTINCT a.DonHangId) FROM dbo.LenhDieuPhoi a JOIN dbo.DonHang o ON o.Id=a.DonHangId WHERE a.KyThuatVienId=k.Id AND a.TrangThai='Accepted' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to AND o.TrangThai='HoanThanh') finishedOrders,
 (SELECT COUNT(DISTINCT a.DonHangId) FROM dbo.LenhDieuPhoi a JOIN dbo.YeuCauHoTro t ON t.DonHangId=a.DonHangId AND t.Loai='Complaint' WHERE a.KyThuatVienId=k.Id AND a.TrangThai='Accepted' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to) complaintOrders,
 (SELECT COUNT(*) FROM dbo.LenhDieuPhoi a WHERE a.KyThuatVienId=k.Id AND a.TrangThai='Rejected' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to) rejectedOrders,
 (SELECT AVG(CAST(DiemDanhGia AS decimal(5,2))) FROM dbo.DanhGia r WHERE r.KyThuatVienId=k.Id AND r.NgayTao>=@from AND r.NgayTao<@to) DiemTrungBinh
 FROM dbo.KyThuatVien k JOIN dbo.NguoiDung n ON n.Id=k.Id`,
      period(req),
    );
    const timings = await q(
      `WITH cohort AS (
 SELECT DISTINCT a.KyThuatVienId,a.DonHangId FROM dbo.LenhDieuPhoi a WHERE a.TrangThai='Accepted' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to
 ) SELECT c.KyThuatVienId,
 SUM(CASE WHEN o.TrangThai='Huy' THEN 1 ELSE 0 END) SoDonHuy,
 SUM(CASE WHEN w.hasWarranty=1 THEN 1 ELSE 0 END) warrantyOrders,
 SUM(CASE WHEN o.NgayHen IS NOT NULL AND h.arrivedAt IS NOT NULL THEN 1 ELSE 0 END) scheduledVisits,
 SUM(CASE WHEN o.NgayHen IS NOT NULL AND h.arrivedAt<=o.NgayHen THEN 1 ELSE 0 END) onTimeVisits,
 COUNT(CASE WHEN h.finishedAt>=h.startedAt THEN 1 END) measuredJobs,
 SUM(CASE WHEN h.finishedAt>=h.startedAt THEN DATEDIFF(second,h.startedAt,h.finishedAt)/60.0 ELSE 0 END) processingMinutes
 FROM cohort c JOIN dbo.DonHang o ON o.Id=c.DonHangId
 OUTER APPLY(SELECT MIN(CASE WHEN TrangThaiSau='DaDenNoi' THEN NgayPhatSinh END) arrivedAt,
 MIN(CASE WHEN TrangThaiSau='DangXuLy' THEN NgayPhatSinh END) startedAt,
 MIN(CASE WHEN TrangThaiSau='ChoNghiemThu' THEN NgayPhatSinh END) finishedAt
 FROM dbo.LichSuDonHang WHERE DonHangId=c.DonHangId AND NguoiThucHienId=c.KyThuatVienId) h
 OUTER APPLY(SELECT TOP 1 1 hasWarranty FROM dbo.YeuCauHoTro WHERE DonHangId=c.DonHangId AND Loai='Warranty') w
 GROUP BY c.KyThuatVienId`,
      period(req),
    );
    ok(
      res,
      rows.map((r) => {
        const t = timings.find((t) => t.technicianId === r.id) || {},
          count = Number(r.assignedOrders);
        return {
          ...r,
          ...t,
          completionRate: count ? (100 * Number(r.finishedOrders)) / count : null,
          complaintRate: count ? (100 * Number(r.complaintOrders)) / count : null,
          cancellationRate: count ? (100 * Number(t.cancelledOrders || 0)) / count : null,
          warrantyRate: count ? (100 * Number(t.warrantyOrders || 0)) / count : null,
          onTimeRate: Number(t.scheduledVisits)
            ? (100 * Number(t.onTimeVisits)) / Number(t.scheduledVisits)
            : null,
          averageMinutes: Number(t.measuredJobs)
            ? Number(t.processingMinutes) / Number(t.measuredJobs)
            : null,
        };
      }),
    );
  }),
);
reportsRouter.get(
  '/reports/cashflow',
  roles('GD', 'KT'),
  wrap(async (req, res) => {
    const rows = await q(
      `WITH movements AS (
 SELECT NgayThanhToan NgayPhatSinh,SoTien incoming,CAST(0 AS decimal(18,2)) outgoing FROM dbo.ThanhToan WHERE PhuongThuc='BANK'
 UNION ALL SELECT NgayTao,CASE WHEN Loai='Deposit' THEN SoTien ELSE 0 END,CASE WHEN Loai='Withdrawal' THEN -SoTien ELSE 0 END
 FROM dbo.GiaoDichVi WHERE Loai IN('Deposit','Withdrawal')
 ) SELECT CONVERT(varchar(10),DATEADD(hour,7,NgayPhatSinh),23) day,SUM(incoming) incoming,SUM(outgoing) outgoing
 FROM movements WHERE NgayPhatSinh>=@from AND NgayPhatSinh<@to
 GROUP BY CONVERT(varchar(10),DATEADD(hour,7,NgayPhatSinh),23) ORDER BY day`,
      period(req),
    );
    ok(res, rows);
  }),
);
const defaults = {
  qualityAlerts: false,
  weeklyReport: false,
  showComplaints: true,
  performanceAlerts: false,
  performanceWeekly: false,
  showTechnicians: true,
  financeAlerts: false,
  financeWeekly: false,
  showCashflow: true,
};
const preferenceSchema = z.strictObject({
  qualityAlerts: z.boolean(),
  weeklyReport: z.boolean(),
  showComplaints: z.boolean(),
  performanceAlerts: z.boolean().optional(),
  performanceWeekly: z.boolean().optional(),
  showTechnicians: z.boolean().optional(),
  financeAlerts: z.boolean().optional(),
  financeWeekly: z.boolean().optional(),
  showCashflow: z.boolean().optional(),
  expectedVersion: versionSchema.optional(),
});
reportsRouter.get(
  '/reports/monitoring',
  roles('GD', 'CSKH'),
  wrap(async (req, res) => {
    const row = await one(
      'SELECT GiaTri,PhienBan FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh',
      {
        key: 'report-monitor-' + req.user.id,
      },
    );
    ok(res, { ...defaults, ...(row ? JSON.parse(row.value) : {}), version: row?.version ?? null });
  }),
);
reportsRouter.patch(
  '/reports/monitoring',
  roles('GD', 'CSKH'),
  wrap(async (req, res) => {
    const b = preferenceSchema.parse(req.body),
      key = 'report-monitor-' + req.user.id;
    ok(
      res,
      await transaction(req.user, async (t) => {
        const row = await one(
          'SELECT GiaTri,PhienBan FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh',
          { key },
          t,
        );
        if (row) checkVersion(row, b.expectedVersion);
        const { expectedVersion, ...changes } = b;
        if (
          req.user.role !== 'GD' &&
          [
            'performanceAlerts',
            'performanceWeekly',
            'showTechnicians',
            'financeAlerts',
            'financeWeekly',
            'showCashflow',
          ].some((key) => key in changes)
        )
          fail(403, 'FORBIDDEN', 'Chỉ giám đốc được chỉnh giám sát tài chính và hiệu suất.');
        const value = JSON.stringify({
          ...defaults,
          ...(row ? JSON.parse(row.value) : {}),
          ...changes,
        });
        if (row)
          await q(
            'UPDATE dbo.CauHinh SET GiaTri=@GiaTri WHERE [KhoaCauHinh]=@KhoaCauHinh',
            { key, value },
            t,
          );
        else
          await q(
            "INSERT dbo.CauHinh([KhoaCauHinh],GiaTri,NhanHienThi) VALUES(@KhoaCauHinh,@GiaTri,N'Cài đặt báo cáo cá nhân')",
            { key, value },
            t,
          );
        const updated = await one(
          'SELECT PhienBan FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh',
          { key },
          t,
        );
        return { ...JSON.parse(value), version: updated.version };
      }),
    );
  }),
);
// In-app monitoring only. No email or third-party delivery is performed.
export async function sendReportNotifications() {
  const configs = await q(
    "SELECT [KhoaCauHinh],GiaTri FROM dbo.CauHinh WHERE [KhoaCauHinh] LIKE 'report-monitor-%'",
  );
  if (!configs.length) return;
  const now = new Date(),
    local = new Date(now.getTime() + 7 * 3600000),
    day = local.getUTCDay(),
    monday = new Date(
      Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate() - ((day + 6) % 7)) -
        7 * 3600000,
    ),
    previous = new Date(monday.getTime() - 7 * 86400000);
  for (const row of configs) {
    let prefs;
    try {
      prefs = JSON.parse(row.value);
    } catch {
      continue;
    }
    const uid = Number(row.key.slice('report-monitor-'.length));
    if (!Number.isInteger(uid)) continue;
    if (
      !prefs.weeklyReport &&
      !prefs.qualityAlerts &&
      !prefs.performanceAlerts &&
      !prefs.performanceWeekly &&
      !prefs.financeAlerts &&
      !prefs.financeWeekly
    )
      continue;
    await transaction(null, async (t) => {
      const user = await one(
        "SELECT Id,VaiTro FROM dbo.NguoiDung WHERE Id=@Id AND DangHoatDong=1 AND VaiTro IN('GD','CSKH')",
        { id: uid },
        t,
      );
      if (!user) return;
      if (prefs.weeklyReport) {
        const title =
          'Báo cáo chất lượng tuần ' +
          previous.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
        if (
          !(await one(
            'SELECT Id FROM dbo.ThongBao WHERE NguoiDungId=@uid AND TieuDe=@TieuDe AND NgayTao>=@monday',
            { uid, title, monday },
            t,
          ))
        ) {
          const stats = await one(
            `SELECT
  COUNT(*) SoDanhGia,
  AVG(CAST(DiemDanhGia AS decimal(5, 2))) DiemTrungBinh
FROM
  dbo.DanhGia
WHERE
  NgayTao >= @from
  AND NgayTao < @to`,
            { from: previous, to: monday },
            t,
          );
          await notify(
            t,
            uid,
            null,
            title,
            `${stats.reviews} đánh giá; điểm trung bình ${stats.averageRating == null ? 'chưa có' : Number(stats.averageRating).toFixed(2) + '/5'}. Mở Báo cáo để xem chi tiết.`,
          );
        }
      }
      if (user.role === 'GD') {
        const emit = async (title, body) => {
          if (
            !(await one(
              'SELECT Id FROM dbo.ThongBao WHERE NguoiDungId=@uid AND TieuDe=@TieuDe AND NgayTao>=@monday',
              { uid, title, monday },
              t,
            ))
          )
            await notify(t, uid, null, title, body);
        };
        if (prefs.financeWeekly || prefs.financeAlerts) {
          const cash = await one(
            `SELECT
      (SELECT COALESCE(SUM(SoTien),0) FROM dbo.ThanhToan WHERE PhuongThuc='BANK' AND NgayThanhToan>=@from AND NgayThanhToan<@to)+
      (SELECT COALESCE(SUM(SoTien),0) FROM dbo.GiaoDichVi WHERE Loai IN('Deposit','Withdrawal') AND NgayTao>=@from AND NgayTao<@to) netFlow`,
            { from: previous, to: monday },
            t,
          );
          if (prefs.financeWeekly)
            await emit(
              'Báo cáo tài chính tuần ' +
                previous.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }),
              `Dòng tiền thuần đã ghi nhận tuần trước: ${Number(cash.netFlow).toLocaleString('vi-VN')} đ. Mở Báo cáo tài chính để xem phạm vi và chi tiết.`,
            );
          if (prefs.financeAlerts && Number(cash.netFlow) < 0)
            await emit(
              'Cảnh báo dòng tiền thấp',
              'Tổng tiền ra vượt tiền vào trong tuần trước. Mở Báo cáo tài chính để kiểm tra.',
            );
        }
        if (prefs.performanceWeekly || prefs.performanceAlerts) {
          const perf = await one(
            `SELECT COUNT(*) assignedOrders,COALESCE(SUM(CASE WHEN o.TrangThai='HoanThanh' THEN 1 ELSE 0 END),0) finishedOrders
      FROM dbo.LenhDieuPhoi a JOIN dbo.DonHang o ON o.Id=a.DonHangId WHERE a.TrangThai='Accepted' AND a.NgayDuyet>=@from AND a.NgayDuyet<@to`,
            { from: previous, to: monday },
            t,
          );
          if (prefs.performanceWeekly)
            await emit(
              'Báo cáo hiệu suất tuần ' +
                previous.toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }),
              `${perf.finishedOrders}/${perf.assignedOrders} đơn đã nhận tuần trước hiện đã hoàn thành. Mở Hiệu suất KTV để xem chi tiết.`,
            );
          if (
            prefs.performanceAlerts &&
            Number(perf.assignedOrders) > 0 &&
            Number(perf.finishedOrders) / Number(perf.assignedOrders) < 0.9
          )
            await emit(
              'Cảnh báo hiệu suất thấp',
              'Dưới 90% đơn nhận tuần trước đã hoàn thành; số liệu gồm cả đơn đang làm. Mở Hiệu suất KTV để kiểm tra.',
            );
        }
      }

      if (prefs.qualityAlerts) {
        const stats = await one(
          `SELECT (SELECT AVG(CAST(DiemDanhGia AS decimal(5,2))) FROM dbo.DanhGia WHERE NgayTao>=@from) DiemTrungBinh,
     (SELECT COUNT(*) FROM dbo.DonHang WHERE NgayTao>=@from) TongSoDon,(SELECT COUNT(DISTINCT o.Id) FROM dbo.DonHang o JOIN dbo.YeuCauHoTro t ON t.DonHangId=o.Id AND t.Loai='Complaint' WHERE o.NgayTao>=@from) complaints`,
          { from: previous },
          t,
        );
        const badRating = stats.averageRating != null && Number(stats.averageRating) < 4.2,
          badRate =
            Number(stats.totalOrders) > 0 &&
            Number(stats.complaints) / Number(stats.totalOrders) > 0.03;
        if (
          (badRating || badRate) &&
          !(await one(
            "SELECT Id FROM dbo.ThongBao WHERE NguoiDungId=@uid AND TieuDe=N'Cảnh báo chất lượng dịch vụ' AND NgayTao>=@monday",
            { uid, monday },
            t,
          ))
        )
          await notify(
            t,
            uid,
            null,
            'Cảnh báo chất lượng dịch vụ',
            'Điểm đánh giá dưới 4,2 sao hoặc tỷ lệ đơn có khiếu nại trên 3%. Mở Báo cáo để kiểm tra các đơn cần chăm sóc.',
          );
      }
    });
  }
}
