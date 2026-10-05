import { Router } from 'express';
import { q, one, transaction, sql } from './db.js';
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
  state,
  getOrder,
  notify,
  audit,
  idempotent,
} from './common.js';
export const financeRouter = Router();
financeRouter.get(
  '/orders/:id/invoice',
  roles('KH', 'KTV', 'KT'),
  wrap(async (req, res) => {
    const oid = id(req.params.id);
    await getOrder(oid, req.user);
    const a = await one(
      "SELECT * FROM dbo.PhieuNghiemThu WHERE DonHangId=@Id AND TrangThai='Approved'",
      { id: oid },
    );
    if (!a) fail(409, 'INVOICE_NOT_READY', 'Khách chưa xác nhận nghiệm thu.');
    const receipt = await one('SELECT * FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: oid });
    ok(res, { ...a, paymentStatus: receipt ? 'Paid' : 'Unpaid', receipt: receipt ?? null });
  }),
);
financeRouter.get(
  '/orders/:id/payments',
  roles('KH', 'KTV', 'KT'),
  wrap(async (req, res) => {
    const oid = id(req.params.id);
    await getOrder(oid, req.user);
    ok(res, await q('SELECT * FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: oid }));
  }),
);
financeRouter.post(
  '/orders/:id/payments/cod',
  roles('KTV'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = z.strictObject({ expectedVersion: versionSchema }).parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      const a = await one(
        "SELECT * FROM dbo.PhieuNghiemThu WHERE DonHangId=@Id AND TrangThai='Approved'",
        { id: oid },
        t,
      );
      if (!a) {
        state(o, 'HoanThanh');
        fail(409, 'ACCEPTANCE_REQUIRED', 'Chưa nghiệm thu.');
      }
      if (a.technicianId !== req.user.id) fail(404, 'NOT_FOUND', 'Bạn không phải thợ thực hiện.');
      return idempotent(t, req, b, async () => {
        checkVersion(o, b.expectedVersion);
        state(o, 'HoanThanh');
        if (o.paymentMethod !== 'COD')
          fail(
            409,
            'PAYMENT_METHOD_MISMATCH',
            'Khách đang chọn chuyển khoản. Không được thu thêm tiền mặt.',
          );
        if (await one('SELECT Id FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: oid }, t))
          fail(409, 'PAYMENT_ALREADY_PAID', 'Đơn đã được ghi nhận thu tiền.');
        const p = await one(
          `INSERT
  dbo.ThanhToan (DonHangId, NghiemThuId, SoTien, NguoiThuTienId)
SELECT
  DonHangId,
  Id,
  TongTien,
  KyThuatVienId
FROM
  dbo.PhieuNghiemThu
WHERE
  Id = @aid;

SELECT
  *
FROM
  dbo.ThanhToan
WHERE
  Id = SCOPE_IDENTITY()`,
          { aid: a.id },
          t,
        );
        await q(
          `INSERT
  dbo.DoiSoat (DonHangId, KyThuatVienId, ThanhToanId, TienCong, TyLeHoaHong)
SELECT
  @oid,
  @kid,
  @pid,
  TienCong,
  TyLeHoaHong
FROM
  dbo.BaoGiaSoBo
WHERE
  DonHangId = @oid`,
          { oid, kid: req.user.id, pid: p.id },
          t,
        );
        await q('UPDATE dbo.DonHang SET NgayCapNhat=SYSUTCDATETIME() WHERE Id=@Id', { id: oid }, t);
        await audit(t, req.user, 'ReceiveCOD', 'ThanhToan', p.id);
        await notify(
          t,
          o.customerId,
          oid,
          'Đã ghi nhận thanh toán COD',
          'Cảm ơn bạn. Bạn có thể đánh giá dịch vụ.',
        );
        return p;
      });
    });
    ok(res, result.data, result.replay ? 200 : 201);
  }),
);
financeRouter.get(
  '/settlements',
  roles('KT'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT
  s.*,
  n.HoTen TenKyThuatVien,
  p.SoTien,
  p.NgayThanhToan,
  p.PhuongThuc,
  p.SoTien - s.TienHoaHong technicianCredit,
  a.TongTienVatTu
FROM
  dbo.DoiSoat s
  JOIN dbo.NguoiDung n ON n.Id = s.KyThuatVienId
  JOIN dbo.ThanhToan p ON p.Id = s.ThanhToanId
  JOIN dbo.PhieuNghiemThu a ON a.Id = p.NghiemThuId
ORDER BY
  s.Id DESC`,
      ),
    ),
  ),
);
financeRouter.post(
  '/settlements/:id/confirm',
  roles('KT'),
  wrap(async (req, res) => {
    const sid = id(req.params.id),
      b = z.strictObject({ expectedVersion: versionSchema }).parse(req.body);
    const r = await transaction(req.user, (t) =>
      idempotent(t, req, b, async () => {
        const r = new sql.Request(t);
        r.input('DoiSoatId', sql.Int, sid)
          .input('NguoiThucHienId', sql.Int, req.user.id)
          .input('PhienBanDuKien', sql.Binary(8), Buffer.from(b.expectedVersion, 'base64'));
        await r.execute('dbo.sp_DoiSoatCOD');
        return one('SELECT * FROM dbo.DoiSoat WHERE Id=@Id', { id: sid }, t);
      }),
    );
    ok(res, r.data);
  }),
);
financeRouter.get(
  '/technicians/me/wallet',
  roles('KTV'),
  wrap(async (req, res) => {
    const k = await one('SELECT SoDu,PhienBan FROM dbo.KyThuatVien WHERE Id=@Id', {
      id: req.user.id,
    });
    ok(res, {
      ...k,
      transactions: await q(
        'SELECT * FROM dbo.GiaoDichVi WHERE KyThuatVienId=@Id ORDER BY Id DESC',
        { id: req.user.id },
      ),
    });
  }),
);
financeRouter.get(
  '/technicians/me/income',
  roles('KTV'),
  wrap(async (req, res) =>
    ok(
      res,
      await one(
        `SELECT
  COALESCE(SUM(a.PhiKiemTra + a.TienCong - s.TienHoaHong), 0) income,
  COALESCE(SUM(a.TongTienVatTu), 0) materialReimbursement,
  COUNT(*) SoDonHoanThanh
FROM
  dbo.ThanhToan p
  JOIN dbo.PhieuNghiemThu a ON a.Id = p.NghiemThuId
  JOIN dbo.DoiSoat s ON s.ThanhToanId = p.Id
WHERE
  s.KyThuatVienId = @Id
  AND (
    @today = 0
    OR CONVERT(date, DATEADD(hour, 7, p.NgayThanhToan)) = CONVERT(date, DATEADD(hour, 7, SYSUTCDATETIME()))
  )`,
        { id: req.user.id, today: req.query.today === '1' ? 1 : 0 },
      ),
    ),
  ),
);
financeRouter.get(
  '/wallet-requests',
  roles('KTV', 'KT'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(
        `SELECT w.*,n.HoTen TenKyThuatVien FROM dbo.YeuCauVi w JOIN dbo.NguoiDung n ON n.Id=w.KyThuatVienId ${req.user.role === 'KTV' ? 'WHERE KyThuatVienId=@Id' : ''} ORDER BY w.Id DESC`,
        { id: req.user.id },
      ),
    ),
  ),
);
financeRouter.post(
  '/wallet-requests',
  roles('KTV'),
  wrap(async (req, res) => {
    const b = z
      .strictObject({
        type: z.enum(['Deposit', 'Withdrawal']),
        amount: money.refine((s) => Number(s) > 0),
        note: str(5, 1000),
        proofId: z.number().int().positive().optional(),
      })
      .parse(req.body);
    const r = await transaction(req.user, (t) =>
      idempotent(t, req, b, async () => {
        if (b.type === 'Deposit' && !b.proofId)
          fail(422, 'PROOF_REQUIRED', 'Yêu cầu nạp cần ảnh chứng từ demo.');
        if (
          b.proofId &&
          !(await one(
            "SELECT Id FROM dbo.TepDinhKem WHERE Id=@Id AND ChuSoHuuId=@uid AND MucDich='WalletProof'",
            { id: b.proofId, uid: req.user.id },
            t,
          ))
        )
          fail(404, 'ATTACHMENT_NOT_FOUND', 'Chứng từ không hợp lệ.');
        return one(
          `INSERT
  dbo.YeuCauVi (
    KyThuatVienId,
    Loai,
    SoTien,
    GhiChu,
    ChungTuId
  ) OUTPUT INSERTED.*
VALUES
  (@uid, @Loai, CAST(@SoTien AS decimal(18, 2)), @GhiChu, @ChungTuId)`,
          { uid: req.user.id, proofId: null, ...b },
          t,
        );
      }),
    );
    ok(res, r.data, r.replay ? 200 : 201);
  }),
);
financeRouter.post(
  '/wallet-requests/:id/decision',
  roles('KT'),
  wrap(async (req, res) => {
    const wid = id(req.params.id),
      b = z
        .strictObject({
          decision: z.enum(['Approved', 'Rejected']),
          reason: str(1, 1000).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    if (b.decision === 'Rejected' && !b.reason) fail(422, 'REASON_REQUIRED', 'Cần lý do từ chối.');
    const r = await transaction(req.user, (t) =>
      idempotent(t, req, b, async () => {
        const w = await one(
          `EXEC dbo.sp_DuyetYeuCauVi @YeuCauId = @Id,
@NguoiThucHienId = @uid,
@QuyetDinh = @decision,
@PhienBanDuKien = @PhienBan,
@LyDo = @LyDo`,
          {
            id: wid,
            uid: req.user.id,
            decision: b.decision,
            version: Buffer.from(b.expectedVersion, 'base64'),
            reason: b.reason,
          },
          t,
        );
        await notify(
          t,
          w.technicianId,
          null,
          'Yêu cầu ví đã được xử lý',
          b.decision === 'Approved' ? 'Đã duyệt và ghi sổ.' : b.reason,
        );
        return one('SELECT * FROM dbo.YeuCauVi WHERE Id=@Id', { id: wid }, t);
      }),
    );
    ok(res, r.data);
  }),
);
financeRouter.post(
  '/wallet-requests/:id/cancel',
  roles('KTV'),
  wrap(async (req, res) => {
    const wid = id(req.params.id),
      b = z.strictObject({ expectedVersion: versionSchema }).parse(req.body);
    const w = await transaction(req.user, async (t) => {
      const w = await one(
        'SELECT * FROM dbo.YeuCauVi WHERE Id=@Id AND KyThuatVienId=@uid',
        { id: wid, uid: req.user.id },
        t,
      );
      checkVersion(w, b.expectedVersion);
      state(w, 'Pending');
      await q("UPDATE dbo.YeuCauVi SET TrangThai='Cancelled' WHERE Id=@Id", { id: wid }, t);
      return one('SELECT * FROM dbo.YeuCauVi WHERE Id=@Id', { id: wid }, t);
    });
    ok(res, w);
  }),
);

financeRouter.get(
  '/technicians/me/wallet-transactions',
  roles('KTV'),
  wrap(async (req, res) => {
    const direction = z.enum(['all', 'in', 'out']).parse(req.query.direction || 'all');
    const month = z
      .string()
      .regex(/^$|^\d{4}-(0[1-9]|1[0-2])$/)
      .parse(req.query.month || '');
    const limit = z.coerce
      .number()
      .int()
      .min(1)
      .max(10000)
      .parse(req.query.limit || 20);
    ok(
      res,
      await q(
        `SELECT TOP (@limit) w.*,s.DonHangId,s.TyLeHoaHong,s.TienHoaHong FROM dbo.GiaoDichVi w
 LEFT JOIN dbo.DoiSoat s ON w.LoaiThamChieu='Settlement' AND w.ThamChieuId=s.Id
 WHERE w.KyThuatVienId=@Id AND (@direction='all' OR (@direction='in' AND w.SoTien>0) OR (@direction='out' AND w.SoTien<0))
 AND (@month='' OR CONVERT(char(7),DATEADD(hour,7,w.NgayTao),126)=@month) ORDER BY w.Id DESC`,
        { id: req.user.id, direction, month, limit },
      ),
    );
  }),
);
