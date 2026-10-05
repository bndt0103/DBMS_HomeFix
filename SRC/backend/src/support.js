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
  checkVersion,
  state,
  getOrder,
  touch,
  notify,
  audit,
} from './common.js';
export const supportRouter = Router();
supportRouter.get(
  '/orders/:id/reviews',
  wrap(async (req, res) => {
    const oid = id(req.params.id);
    await getOrder(oid, req.user);
    ok(res, await q('SELECT * FROM dbo.DanhGia WHERE DonHangId=@Id', { id: oid }));
  }),
);
supportRouter.post(
  '/orders/:id/reviews',
  roles('KH'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = z
        .strictObject({ rating: z.number().int().min(1).max(5), comment: str(0, 1500) })
        .parse(req.body);
    ok(
      res,
      await transaction(req.user, async (t) => {
        const o = await getOrder(oid, req.user, t);
        state(o, 'HoanThanh');
        const p = await one(
          'SELECT p.*,a.KyThuatVienId FROM dbo.ThanhToan p JOIN dbo.PhieuNghiemThu a ON a.Id=p.NghiemThuId WHERE p.DonHangId=@Id',
          { id: oid },
          t,
        );
        if (!p) fail(409, 'PAYMENT_REQUIRED', 'Chỉ đánh giá sau khi đã thanh toán.');
        if (await one('SELECT Id FROM dbo.DanhGia WHERE DonHangId=@Id', { id: oid }, t))
          fail(409, 'REVIEW_ALREADY_EXISTS', 'Bạn đã đánh giá đơn này.');
        return one(
          `INSERT
  dbo.DanhGia (DonHangId, KhachHangId, KyThuatVienId, DiemDanhGia, NhanXet)
VALUES
  (@oid, @uid, @kid, @DiemDanhGia, @NhanXet);

SELECT
  *
FROM
  dbo.DanhGia
WHERE
  Id = SCOPE_IDENTITY()`,
          { oid, uid: req.user.id, kid: p.technicianId, ...b },
          t,
        );
      }),
      201,
    );
  }),
);
supportRouter.get(
  '/support/tickets',
  roles('KH', 'CSKH'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT t.*,n.HoTen TenKhachHang FROM dbo.YeuCauHoTro t JOIN dbo.NguoiDung n ON n.Id=t.KhachHangId ${req.user.role === 'KH' ? 'WHERE KhachHangId=@uid' : ''} ORDER BY t.Id DESC`,
        { uid: req.user.id },
      ),
    ),
  ),
);
supportRouter.post(
  '/support/tickets',
  roles('KH'),
  wrap(async (req, res) => {
    const b = z
      .strictObject({
        orderId: z.number().int().positive(),
        type: z.enum(['Complaint', 'Warranty']),
        description: str(10, 2000),
      })
      .parse(req.body);
    const ticket = await transaction(req.user, async (t) => {
      const o = await getOrder(b.orderId, req.user, t);
      const a = await one(
        "SELECT *,DATEADD(day,7,NgayDuyet) complaintUntil FROM dbo.PhieuNghiemThu WHERE DonHangId=@Id AND TrangThai='Approved'",
        { id: o.id },
        t,
      );
      if (b.type === 'Complaint' && a && new Date(a.complaintUntil) < new Date())
        fail(
          409,
          'COMPLAINT_WINDOW_CLOSED',
          'Đã quá 7 ngày từ nghiệm thu. Vui lòng liên hệ tổng đài để xem xét.',
        );
      if (b.type === 'Warranty') {
        if (!a) fail(409, 'ACCEPTANCE_REQUIRED', 'Chưa nghiệm thu để yêu cầu bảo hành.');
        const warranty = await one(
          `SELECT
  MAX(DATEADD(month, i.SoThangBaoHanh, @approvedAt)) expires
FROM
  dbo.ChiTietDeXuatVatTu i
WHERE
  BaoGiaId = @qid
  AND SoThangBaoHanh > 0`,
          { approvedAt: new Date(a.decidedAt), qid: a.materialQuoteId },
          t,
        );
        if (!warranty?.expires || new Date(warranty.expires) < new Date())
          fail(409, 'WARRANTY_EXPIRED', 'Không có vật tư còn bảo hành trên phiếu.');
      }
      if (
        await one(
          "SELECT Id FROM dbo.YeuCauHoTro WHERE DonHangId=@oid AND Loai=@Loai AND TrangThai IN('Open','InProgress')",
          { oid: o.id, type: b.type },
          t,
        )
      )
        fail(409, 'OPEN_TICKET_EXISTS', 'Đã có yêu cầu cùng loại đang xử lý.');
      const row = await one(
        `INSERT
  dbo.YeuCauHoTro (
    DonHangId,
    KhachHangId,
    Loai,
    MoTa
  ) OUTPUT INSERTED.*
VALUES
  (@DonHangId, @uid, @Loai, @MoTa)`,
        { ...b, uid: req.user.id },
        t,
      );
      await q(
        "INSERT dbo.LichSuHoTro(YeuCauHoTroId,NguoiThucHienId,TrangThai,GhiChu) VALUES(@Id,@uid,'Open',@GhiChu)",
        { id: row.id, uid: req.user.id, note: b.description },
        t,
      );
      return row;
    });
    ok(res, ticket, 201);
  }),
);
supportRouter.get(
  '/support/tickets/:id',
  roles('KH', 'CSKH'),
  wrap(async (req, res) => {
    const tid = id(req.params.id),
      t = await one('SELECT * FROM dbo.YeuCauHoTro WHERE Id=@Id', { id: tid });
    if (!t || (req.user.role === 'KH' && t.customerId !== req.user.id))
      fail(404, 'NOT_FOUND', 'Không tìm thấy yêu cầu.');
    ok(res, {
      ...t,
      history: await q(
        `SELECT
  h.*,
  n.HoTen actorName
FROM
  dbo.LichSuHoTro h
  JOIN dbo.NguoiDung n ON n.Id = h.NguoiThucHienId
WHERE
  YeuCauHoTroId = @Id
ORDER BY
  h.Id`,
        { id: tid },
      ),
    });
  }),
);
supportRouter.patch(
  '/support/tickets/:id',
  roles('CSKH'),
  wrap(async (req, res) => {
    const tid = id(req.params.id),
      b = z
        .strictObject({
          status: z.enum(['InProgress', 'Resolved', 'Rejected']),
          resolution: str(5, 2000),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    ok(
      res,
      await transaction(req.user, async (t) => {
        const ticket = await one('SELECT * FROM dbo.YeuCauHoTro WHERE Id=@Id', { id: tid }, t);
        checkVersion(ticket, b.expectedVersion);
        state(ticket, 'Open', 'InProgress');
        await q(
          'EXEC dbo.sp_XuLyHoTro @YeuCauHoTroId=@Id,@NguoiThucHienId=@uid,@TrangThai=@TrangThai,@KetQuaXuLy=@KetQuaXuLy,@PhienBanDuKien=@PhienBan',
          {
            id: tid,
            uid: req.user.id,
            status: b.status,
            resolution: b.resolution,
            version: Buffer.from(b.expectedVersion, 'base64'),
          },
          t,
        );
        await notify(
          t,
          ticket.customerId,
          ticket.orderId,
          'Yêu cầu hỗ trợ được cập nhật',
          b.resolution,
        );
        return one('SELECT * FROM dbo.YeuCauHoTro WHERE Id=@Id', { id: tid }, t);
      }),
    );
  }),
);
