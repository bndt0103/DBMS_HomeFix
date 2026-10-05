import { attentionSummary } from './attention.js';
import { Router } from 'express';
import { q, one, transaction } from './db.js';
import {
  z,
  str,
  id,
  ok,
  wrap,
  fail,
  roles,
  versionSchema,
  money,
  checkVersion,
  audit,
  notify,
  state,
} from './common.js';
export const adminRouter = Router();
export const publicServices = wrap(async (req, res) =>
  ok(res, await q('SELECT * FROM dbo.DichVu WHERE DangHoatDong=1 ORDER BY Id')),
);
const serviceSchema = z.strictObject({
  name: str(2, 150),
  groupCode: z.enum(['DienLanh', 'DienNuoc', 'DienGiaDung', 'VeSinh']),
  description: str(5, 1500),
  inspectionFee: money,
  laborFee: money,
  commissionRatePercent: z
    .string()
    .regex(/^\d{1,3}(\.\d{1,2})?$/)
    .refine((s) => Number(s) <= 100),
  isPopular: z.boolean().optional().default(false),
  isActive: z.boolean(),
});
adminRouter.get(
  '/admin/services',
  roles('ADMIN'),
  wrap(async (req, res) => ok(res, await q('SELECT * FROM dbo.DichVu ORDER BY Id'))),
);
adminRouter.post(
  '/services',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const b = serviceSchema.parse(req.body);
    ok(
      res,
      await transaction(req.user, async (t) => {
        const s = await one(
          `INSERT
  dbo.DichVu (
    Ten,
    MaNhom,
    MoTa,
    PhiKiemTra,
    TienCong,
    TyLeHoaHong,
    PhoBien,
    DangHoatDong
  ) OUTPUT INSERTED.*
VALUES
  (
    @Ten,
    @MaNhom,
    @MoTa,
    CAST(@PhiKiemTra AS decimal(18, 2)),
    CAST(@TienCong AS decimal(18, 2)),
    CAST(@TyLeHoaHong AS decimal(5, 2)),
    @PhoBien,
    @DangHoatDong
  )`,
          b,
          t,
        );
        await audit(t, req.user, 'CreateService', 'DichVu', s.id);
        return s;
      }),
      201,
    );
  }),
);
adminRouter.patch(
  '/services/:id',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const sid = id(req.params.id),
      b = serviceSchema.extend({ expectedVersion: versionSchema }).parse(req.body);
    ok(
      res,
      await transaction(req.user, async (t) => {
        const s = await one('SELECT * FROM dbo.DichVu WHERE Id=@Id', { id: sid }, t);
        checkVersion(s, b.expectedVersion);
        await q(
          `UPDATE dbo.DichVu
SET
  Ten = @Ten,
  MaNhom = @MaNhom,
  MoTa = @MoTa,
  PhiKiemTra = CAST(@PhiKiemTra AS decimal(18, 2)),
  TienCong = CAST(@TienCong AS decimal(18, 2)),
  TyLeHoaHong = CAST(@TyLeHoaHong AS decimal(5, 2)),
  PhoBien = @PhoBien,
  DangHoatDong = @DangHoatDong
WHERE
  Id = @Id`,
          { ...b, id: sid },
          t,
        );
        await audit(t, req.user, 'UpdateService', 'DichVu', sid);
        return one('SELECT * FROM dbo.DichVu WHERE Id=@Id', { id: sid }, t);
      }),
    );
  }),
);
adminRouter.get(
  '/app-config',
  wrap(async (req, res) => {
    const values = Object.fromEntries(
      (
        await q(
          "SELECT [KhoaCauHinh],GiaTri FROM dbo.CauHinh WHERE [KhoaCauHinh] NOT LIKE 'report-monitor-%'",
        )
      ).map((r) => [r.key, r.value]),
    );
    ok(res, {
      ...values,
      signatureRequired: values.signatureRequired === 'true',
      supportedPaymentMethods: ['COD', 'BANK'],
      maxOrderImages: 5,
      maxImageBytes: 5242880,
      enabledFeatures: {
        wallet: true,
        support: true,
        notifications: true,
        location: true,
        onlinePayment: false,
        bankTransfer: true,
      },
    });
  }),
);
adminRouter.get(
  '/settings',
  roles('ADMIN'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        "SELECT * FROM dbo.CauHinh WHERE [KhoaCauHinh] NOT LIKE 'report-monitor-%' ORDER BY [KhoaCauHinh]",
      ),
    ),
  ),
);
adminRouter.patch(
  '/settings/:key',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const key = z
        .enum(['minimumWallet', 'assignmentMinutes', 'cancellationFee', 'signatureRequired'])
        .parse(req.params.key),
      b = z.strictObject({ value: str(1, 100), expectedVersion: versionSchema }).parse(req.body);
    if (key === 'signatureRequired') {
      if (!['true', 'false'].includes(b.value))
        fail(422, 'INVALID_SETTING', 'Giá trị phải là true hoặc false.');
    } else {
      if (!/^\d+$/.test(b.value))
        fail(422, 'INVALID_SETTING', 'Giá trị phải là số nguyên không âm.');
      const v = Number(b.value);
      if (v > 10000000 || (key === 'assignmentMinutes' && (v < 1 || v > 60)))
        fail(422, 'INVALID_SETTING', 'Giá trị ngoài giới hạn.');
    }
    ok(
      res,
      await transaction(req.user, async (t) => {
        const s = await one(
          'SELECT * FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh',
          { key },
          t,
        );
        checkVersion(s, b.expectedVersion);
        await q(
          'UPDATE dbo.CauHinh SET GiaTri=@GiaTri WHERE [KhoaCauHinh]=@KhoaCauHinh',
          { key, value: b.value },
          t,
        );
        await audit(t, req.user, 'UpdateSetting', 'CauHinh', null, key);
        return one('SELECT * FROM dbo.CauHinh WHERE [KhoaCauHinh]=@KhoaCauHinh', { key }, t);
      }),
    );
  }),
);
adminRouter.get(
  '/audit-logs',
  roles('ADMIN'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT
  TOP 200 a.*,
  n.HoTen actorName
FROM
  dbo.NhatKy a
  LEFT JOIN dbo.NguoiDung n ON n.Id = a.NguoiThucHienId
ORDER BY
  a.Id DESC`,
      ),
    ),
  ),
);
adminRouter.get(
  '/attention-summary',
  wrap(async (req, res) => ok(res, await attentionSummary(req.user))),
);
adminRouter.get(
  '/notifications',
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        'SELECT TOP 100 * FROM dbo.ThongBao WHERE NguoiDungId=@Id ORDER BY CASE WHEN NgayDoc IS NULL THEN 0 ELSE 1 END,Id DESC',
        { id: req.user.id },
      ),
    ),
  ),
);
adminRouter.patch(
  '/notifications/:id/read',
  wrap(async (req, res) => {
    const nid = id(req.params.id);
    const n = await transaction(req.user, async (t) => {
      const n = await one(
        'SELECT * FROM dbo.ThongBao WHERE Id=@Id AND NguoiDungId=@uid',
        { id: nid, uid: req.user.id },
        t,
      );
      if (!n) fail(404, 'NOT_FOUND', 'Không tìm thấy thông báo.');
      await q(
        'UPDATE dbo.ThongBao SET NgayDoc=COALESCE(NgayDoc,SYSUTCDATETIME()) WHERE Id=@Id',
        { id: nid },
        t,
      );
      return one('SELECT * FROM dbo.ThongBao WHERE Id=@Id', { id: nid }, t);
    });
    ok(res, n);
  }),
);
adminRouter.post(
  '/technician-applications',
  roles('KH'),
  wrap(async (req, res) => {
    const b = z
      .strictObject({
        skillGroup: z.enum(['DienLanh', 'DienNuoc', 'DienGiaDung', 'VeSinh']),
        serviceArea: str(2, 120),
        experience: str(10, 2000),
        identityNumber: z
          .string()
          .regex(/^\d{12}$/)
          .optional(),
        frontDocumentId: z.number().int().positive().optional(),
        backDocumentId: z.number().int().positive().optional(),
        profile: z
          .strictObject({
            years: z.number().int().min(0).max(60),
            equipment: str(1, 300),
            certificates: str(0, 300),
            vehicle: str(1, 100),
          })
          .optional(),
      })
      .parse(req.body);
    ok(
      res,
      await transaction(req.user, async (t) => {
        const extended = b.profile || b.identityNumber || b.frontDocumentId || b.backDocumentId;
        if (
          extended &&
          (!b.profile ||
            !b.identityNumber ||
            !b.frontDocumentId ||
            !b.backDocumentId ||
            b.frontDocumentId === b.backDocumentId)
        )
          fail(
            422,
            'DOCUMENTS_REQUIRED',
            'Cần thông tin chuyên môn, số CCCD và ảnh hai mặt riêng biệt.',
          );
        for (const fid of [b.frontDocumentId, b.backDocumentId].filter(Boolean))
          if (
            !(await one(
              "SELECT Id FROM dbo.TepDinhKem WHERE Id=@Id AND ChuSoHuuId=@uid AND MucDich='TechnicianDocument'",
              { id: fid, uid: req.user.id },
              t,
            ))
          )
            fail(404, 'ATTACHMENT_NOT_FOUND', 'Giấy tờ không thuộc người nộp.');
        if (
          b.identityNumber &&
          (await one(
            "SELECT Id FROM dbo.HoSoKTV WHERE SoGiayTo=@number AND NguoiDungId<>@uid AND TrangThai IN('Pending','Approved')",
            { number: b.identityNumber, uid: req.user.id },
            t,
          ))
        )
          fail(409, 'IDENTITY_EXISTS', 'CCCD này đã được đăng ký.');
        return one(
          `INSERT
  dbo.HoSoKTV (
    NguoiDungId,
    NhomTayNghe,
    KhuVucPhucVu,
    KinhNghiem,
    SoGiayTo,
    GiayToMatTruocId,
    GiayToMatSauId,
    HoSoJSON
  ) OUTPUT INSERTED.*
VALUES
  (
    @uid,
    @NhomTayNghe,
    @KhuVucPhucVu,
    @KinhNghiem,
    @SoGiayTo,
    @GiayToMatTruocId,
    @GiayToMatSauId,
    @HoSoJSON
  )`,
          {
            uid: req.user.id,
            skillGroup: b.skillGroup,
            serviceArea: b.serviceArea,
            experience: b.experience,
            identityNumber: b.identityNumber,
            frontDocumentId: b.frontDocumentId,
            backDocumentId: b.backDocumentId,
            profileJson: b.profile ? JSON.stringify(b.profile) : null,
          },
          t,
        );
      }),
      201,
    );
  }),
);
adminRouter.get(
  '/technician-applications/me',
  roles('KH', 'KTV'),
  wrap(async (req, res) =>
    ok(
      res,
      await q('SELECT * FROM dbo.HoSoKTV WHERE NguoiDungId=@Id ORDER BY Id DESC', {
        id: req.user.id,
      }),
    ),
  ),
);
adminRouter.get(
  '/technician-applications',
  roles('ADMIN'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        'SELECT h.*,n.HoTen,n.SoDienThoai FROM dbo.HoSoKTV h JOIN dbo.NguoiDung n ON n.Id=h.NguoiDungId ORDER BY h.Id DESC',
      ),
    ),
  ),
);
adminRouter.post(
  '/technician-applications/:id/decision',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const hid = id(req.params.id),
      b = z
        .strictObject({
          decision: z.enum(['Approved', 'Rejected']),
          reason: str(1, 1000).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    if (b.decision === 'Rejected' && !b.reason) fail(422, 'REASON_REQUIRED', 'Cần lý do từ chối.');
    ok(
      res,
      await transaction(req.user, async (t) => {
        const h = await one('SELECT * FROM dbo.HoSoKTV WHERE Id=@Id', { id: hid }, t);
        checkVersion(h, b.expectedVersion);
        state(h, 'Pending');
        if (b.decision === 'Approved') {
          const u = await one('SELECT VaiTro FROM dbo.NguoiDung WHERE Id=@Id', { id: h.userId }, t);
          if (u.role !== 'KH') fail(409, 'ROLE_CHANGED', 'Vai trò người nộp đã thay đổi.');
          if (
            await one(
              "SELECT Id FROM dbo.DonHang WHERE KhachHangId=@Id AND TrangThai NOT IN('HoanThanh','Huy')",
              { id: h.userId },
              t,
            )
          )
            fail(409, 'OPEN_CUSTOMER_ORDER', 'Người nộp còn đơn khách hàng chưa hoàn tất.');
          await q(
            "UPDATE dbo.NguoiDung SET VaiTro='KTV',PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id",
            { id: h.userId },
            t,
          );
          await q(
            'INSERT dbo.KyThuatVien(Id,NhomTayNghe,KhuVucPhucVu) VALUES(@Id,@skill,@area)',
            { id: h.userId, skill: h.skillGroup, area: h.serviceArea },
            t,
          );
        }
        await q(
          'UPDATE dbo.HoSoKTV SET TrangThai=@decision,LyDo=@LyDo,NguoiDuyetId=@uid WHERE Id=@Id',
          { id: hid, decision: b.decision, reason: b.reason, uid: req.user.id },
          t,
        );
        await audit(t, req.user, 'DecideApplication', 'HoSoKTV', hid, b.decision);
        return one('SELECT * FROM dbo.HoSoKTV WHERE Id=@Id', { id: hid }, t);
      }),
    );
  }),
);
adminRouter.get(
  '/director/policy-proposals',
  roles('GD'),
  wrap(async (req, res) =>
    ok(
      res,
      await q("SELECT * FROM dbo.DeXuatChinhSach WHERE TrangThai='Pending' ORDER BY NgayGui,Id"),
    ),
  ),
);
adminRouter.post(
  '/director/policy-proposals/:id/decision',
  roles('GD'),
  wrap(async (req, res) => {
    const pid = id(req.params.id),
      b = z
        .strictObject({
          decision: z.enum(['Approved', 'RevisionRequested', 'Rejected']),
          note: str(1, 2000).optional(),
          effectiveAt: z.enum(['tomorrow', 'week', 'month']).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    if (['RevisionRequested', 'Rejected'].includes(b.decision) && !b.note)
      fail(422, 'DIRECTOR_NOTE_REQUIRED', 'Vui lòng nhập ý kiến chỉ đạo hoặc lý do.');
    ok(
      res,
      await transaction(req.user, async (t) => {
        const proposal = await one(
          'SELECT * FROM dbo.DeXuatChinhSach WHERE Id=@Id',
          { id: pid },
          t,
        );
        checkVersion(proposal, b.expectedVersion);
        state(proposal, 'Pending');
        await q(
          `UPDATE dbo.DeXuatChinhSach
SET
  TrangThai = @decision,
  YKienGiamDoc = @GhiChu,
  NgayHieuLuc = @NgayHieuLuc,
  NguoiDuyetId = @uid,
  NgayDuyet = SYSUTCDATETIME()
WHERE
  Id = @Id`,
          {
            id: pid,
            decision: b.decision,
            note: b.note || null,
            effectiveAt: b.effectiveAt || null,
            uid: req.user.id,
          },
          t,
        );
        await audit(t, req.user, 'DecidePolicyProposal', 'DeXuatChinhSach', pid, b.decision);
        return one('SELECT * FROM dbo.DeXuatChinhSach WHERE Id=@Id', { id: pid }, t);
      }),
    );
  }),
);
function period(req) {
  const schema = z.iso.datetime({ offset: true });
  const from = req.query.from
    ? new Date(schema.parse(req.query.from))
    : new Date('2020-01-01T00:00:00Z');
  const to = req.query.to ? new Date(schema.parse(req.query.to)) : new Date(Date.now() + 86400000);
  if (from >= to) fail(422, 'INVALID_PERIOD', 'Ngày kết thúc phải sau ngày bắt đầu.');
  return { from, to };
}
adminRouter.get(
  '/reports/summary',
  roles('GD', 'KT', 'CSKH', 'ADMIN', 'DPV'),
  wrap(async (req, res) => {
    const params = period(req);
    const reportUser = {
      GD: 'hf_GD',
      KT: 'hf_KT',
      CSKH: 'hf_CSKH',
      ADMIN: 'hf_ADMIN',
      DPV: 'hf_DPV',
    }[req.user.role];
    const grouped = await q(
      `EXECUTE AS USER='${reportUser}';
      BEGIN TRY
        EXEC dbo.sp_BaoCaoTongHop @TuNgay=@from,@DenNgay=@to;
        REVERT;
      END TRY
      BEGIN CATCH
        REVERT;
        THROW;
      END CATCH;`,
      params,
    );
    const orders = grouped.reduce(
      (acc, row) => ({
        totalOrders: acc.totalOrders + Number(row.totalOrders),
        completedOrders: acc.completedOrders + Number(row.completedOrders),
        cancelledOrders: acc.cancelledOrders + Number(row.cancelledOrders),
      }),
      { totalOrders: 0, completedOrders: 0, cancelledOrders: 0 },
    );
    const money = await one(
      'SELECT COALESCE(SUM(SoTien),0) TongGiaTriGiaoDich,COUNT(*) SoDonDaThanhToan FROM dbo.ThanhToan WHERE NgayThanhToan>=@from AND NgayThanhToan<@to',
      params,
    );
    const commission = await one(
      `SELECT
  COALESCE(SUM(TienHoaHong), 0) DoanhThuHoaHong
FROM
  dbo.DoiSoat
WHERE
  TrangThai = 'Confirmed'
  AND NgayXacNhan >= @from
  AND NgayXacNhan < @to`,
      params,
    );
    const quality = await one(
      `SELECT
  AVG(CAST(DiemDanhGia AS decimal(5, 2))) DiemTrungBinh,
  COUNT(*) SoDanhGia
FROM
  dbo.DanhGia
WHERE
  NgayTao >= @from
  AND NgayTao < @to`,
      params,
    );
    const trend = await q(
      `SELECT
  CONVERT(varchar(10), DATEADD(hour, 7, NgayThanhToan), 23) day,
  SUM(SoTien) SoTien,
  COUNT(*) orders
FROM
  dbo.ThanhToan
WHERE
  NgayThanhToan >= @from
  AND NgayThanhToan < @to
GROUP BY
  CONVERT(varchar(10), DATEADD(hour, 7, NgayThanhToan), 23)
ORDER BY
  day`,
      params,
    );
    ok(res, { ...orders, ...money, ...commission, ...quality, trend });
  }),
);
adminRouter.get(
  '/reports/technicians',
  roles('GD', 'KT', 'DPV'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT
  k.Id,
  n.HoTen,
  k.NhomTayNghe,
  k.TrangThaiSanSang,
  (
    SELECT
      COUNT(*)
    FROM
      dbo.ThanhToan p
      JOIN dbo.PhieuNghiemThu a ON a.Id = p.NghiemThuId
    WHERE
      a.KyThuatVienId = k.Id
  ) SoDonHoanThanh,
  (
    SELECT
      AVG(CAST(DiemDanhGia AS decimal(5, 2)))
    FROM
      dbo.DanhGia d
    WHERE
      d.KyThuatVienId = k.Id
  ) DiemTrungBinh
FROM
  dbo.KyThuatVien k
  JOIN dbo.NguoiDung n ON n.Id = k.Id`,
      ),
    ),
  ),
);
adminRouter.get(
  '/reports/finance',
  roles('GD', 'KT'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT
  p.Id,
  p.DonHangId,
  p.SoTien,
  p.NgayThanhToan,
  p.PhuongThuc,
  a.PhiKiemTra,
  a.TienCong,
  a.TongTienVatTu,
  n.HoTen TenKyThuatVien,
  s.TienHoaHong,
  s.TrangThai settlementStatus
FROM
  dbo.ThanhToan p
  JOIN dbo.PhieuNghiemThu a ON a.Id = p.NghiemThuId
  JOIN dbo.NguoiDung n ON n.Id = a.KyThuatVienId
  JOIN dbo.DoiSoat s ON s.ThanhToanId = p.Id
WHERE
  p.NgayThanhToan >= @from
  AND p.NgayThanhToan < @to
ORDER BY
  p.Id DESC`,
        period(req),
      ),
    ),
  ),
);
adminRouter.get(
  '/reports/finance.csv',
  roles('GD', 'KT'),
  wrap(async (req, res) => {
    const rows = await q(
      `SELECT
  p.DonHangId,
  p.SoTien,
  p.NgayThanhToan,
  p.PhuongThuc,
  s.TienHoaHong,
  s.TrangThai
FROM
  dbo.ThanhToan p
  JOIN dbo.DoiSoat s ON s.ThanhToanId = p.Id
WHERE
  p.NgayThanhToan >= @from
  AND p.NgayThanhToan < @to
ORDER BY
  p.Id`,
      period(req),
    );
    const lines = [
      'DonHangId,SoTien,NgayThanhToan,PhuongThuc,TienHoaHong,TrangThai',
      ...rows.map((r) =>
        [
          r.orderId,
          r.amount,
          new Date(r.paidAt).toISOString(),
          r.method,
          r.commissionAmount,
          r.status,
        ].join(','),
      ),
    ];
    res
      .attachment('HomeFix_Finance.csv')
      .type('text/csv')
      .send('\ufeff' + lines.join('\r\n'));
  }),
);
