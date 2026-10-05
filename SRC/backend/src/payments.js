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
  state,
  getOrder,
  touch,
  notify,
  audit,
  idempotent,
} from './common.js';
import { banks } from './banks.js';

export const paymentsRouter = Router();
const bankCode = z.enum(banks.map((bank) => bank.code));
const accountSchema = z.strictObject({
  bankCode,
  accountNumber: z
    .string()
    .trim()
    .regex(/^\d{6,30}$/, 'Số tài khoản gồm 6–30 chữ số.'),
  accountHolder: str(2, 120),
});
const choiceSchema = z.strictObject({
  method: z.enum(['COD', 'BANK']),
  bankAccountId: z.number().int().positive().optional(),
  expectedVersion: versionSchema,
});
export async function selectPayment(t, order, acceptance, method, bankAccountId, actor) {
  if (await one('SELECT Id FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: order.id }, t))
    fail(409, 'PAYMENT_ALREADY_PAID', 'Đơn đã thanh toán.');
  const old = await one(
    'SELECT * FROM dbo.YeuCauThanhToan WHERE DonHangId=@Id AND DangHoatDong=1',
    { id: order.id },
    t,
  );
  if (old?.status === 'PendingReview')
    fail(
      409,
      'PAYMENT_UNDER_REVIEW',
      'Chứng từ đang chờ kế toán xác nhận. Chưa thể đổi phương thức.',
    );
  let account;
  if (method === 'BANK') {
    if (!bankAccountId) fail(422, 'BANK_ACCOUNT_REQUIRED', 'Vui lòng chọn tài khoản nhận tiền.');
    account = await one(
      'SELECT * FROM dbo.TaiKhoanNhanTien WHERE Id=@Id AND DangHoatDong=1',
      { id: bankAccountId },
      t,
    );
    if (!account)
      fail(
        409,
        'BANK_ACCOUNT_UNAVAILABLE',
        'Tài khoản nhận tiền không còn được sử dụng. Hãy chọn lại.',
      );
    if (Number(acceptance.total) <= 0)
      fail(409, 'ZERO_TRANSFER', 'Đơn không phát sinh tiền không cần chuyển khoản.');
  }
  if (old)
    await q(
      `UPDATE dbo.YeuCauThanhToan
SET
  TrangThai = 'Cancelled',
  DangHoatDong = 0,
  NgayDuyet = SYSUTCDATETIME(),
  LyDo = N'Khách đổi phương thức trước khi báo chuyển tiền'
WHERE
  Id = @Id`,
      { id: old.id },
      t,
    );
  await q(
    'UPDATE dbo.DonHang SET PhuongThucThanhToan=@PhuongThuc,NgayCapNhat=SYSUTCDATETIME() WHERE Id=@Id',
    { method, id: order.id },
    t,
  );
  let request = null;
  if (account) {
    request = await one(
      `INSERT dbo.YeuCauThanhToan(DonHangId,NghiemThuId,KhachHangId,TaiKhoanNganHangId,MaNganHang,TenNganHang,SoTaiKhoan,ChuTaiKhoan,SoTien)
   OUTPUT INSERTED.* VALUES(@oid,@aid,@cid,@bid,@MaNganHang,@TenNganHang,@SoTaiKhoan,@ChuTaiKhoan,CAST(@SoTien AS decimal(18,2)))`,
      {
        oid: order.id,
        aid: acceptance.id,
        cid: order.customerId,
        bid: account.id,
        bankCode: account.bankCode,
        bankName: account.bankName,
        accountNumber: account.accountNumber,
        accountHolder: account.accountHolder,
        amount: String(acceptance.total),
      },
      t,
    );
    await q(
      'UPDATE dbo.YeuCauThanhToan SET NoiDungChuyenKhoan=@content WHERE Id=@Id',
      { id: request.id, content: 'HF' + order.id + 'CK' + request.id },
      t,
    );
    request = await one('SELECT * FROM dbo.YeuCauThanhToan WHERE Id=@Id', { id: request.id }, t);
  }
  await audit(t, actor, 'SelectPayment', 'DonHang', order.id, method);
  return request;
}

paymentsRouter.get(
  '/payment-options',
  wrap(async (req, res) =>
    ok(res, {
      banks,
      accounts: await q(
        'SELECT Id,MaNganHang,TenNganHang,SoTaiKhoan,ChuTaiKhoan FROM dbo.TaiKhoanNhanTien WHERE DangHoatDong=1 ORDER BY Id',
      ),
    }),
  ),
);
paymentsRouter.get(
  '/bank-accounts',
  roles('ADMIN'),
  wrap(async (req, res) => ok(res, await q('SELECT * FROM dbo.TaiKhoanNhanTien ORDER BY Id DESC'))),
);
paymentsRouter.post(
  '/bank-accounts',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const b = accountSchema.parse(req.body);
    const account = await transaction(req.user, async (t) => {
      const row = await one(
        `INSERT
  dbo.TaiKhoanNhanTien (MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, NguoiTaoId) OUTPUT INSERTED.*
VALUES
  (@MaNganHang, @TenNganHang, @SoTaiKhoan, @ChuTaiKhoan, @uid)`,
        { ...b, bankName: banks.find((x) => x.code === b.bankCode).name, uid: req.user.id },
        t,
      );
      await audit(t, req.user, 'CreateBankAccount', 'TaiKhoanNhanTien', row.id);
      return row;
    });
    ok(res, account, 201);
  }),
);
paymentsRouter.patch(
  '/bank-accounts/:id',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const bid = id(req.params.id),
      b = z.strictObject({ isActive: z.boolean(), expectedVersion: versionSchema }).parse(req.body);
    const row = await transaction(req.user, async (t) => {
      checkVersion(
        await one('SELECT * FROM dbo.TaiKhoanNhanTien WHERE Id=@Id', { id: bid }, t),
        b.expectedVersion,
      );
      await q(
        'UPDATE dbo.TaiKhoanNhanTien SET DangHoatDong=@active WHERE Id=@Id',
        { id: bid, active: b.isActive },
        t,
      );
      await audit(t, req.user, 'ToggleBankAccount', 'TaiKhoanNhanTien', bid, String(b.isActive));
      return one('SELECT * FROM dbo.TaiKhoanNhanTien WHERE Id=@Id', { id: bid }, t);
    });
    ok(res, row);
  }),
);

paymentsRouter.get(
  '/orders/:id/payment-details',
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      order = await getOrder(oid, req.user);
    ok(res, {
      method: order.paymentMethod,
      receipt: await one('SELECT * FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: oid }),
      requests: await q('SELECT * FROM dbo.YeuCauThanhToan WHERE DonHangId=@Id ORDER BY Id DESC', {
        id: oid,
      }),
    });
  }),
);
paymentsRouter.post(
  '/orders/:id/payment-method',
  roles('KH'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = choiceSchema.parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const order = await getOrder(oid, req.user, t);
      return idempotent(t, req, b, async () => {
        checkVersion(order, b.expectedVersion);
        state(order, 'HoanThanh');
        const acceptance = await one(
          "SELECT * FROM dbo.PhieuNghiemThu WHERE DonHangId=@Id AND TrangThai='Approved'",
          { id: oid },
          t,
        );
        if (!acceptance)
          fail(409, 'ACCEPTANCE_REQUIRED', 'Vui lòng nghiệm thu trước khi chọn thanh toán.');
        const request = await selectPayment(
          t,
          order,
          acceptance,
          b.method,
          b.bankAccountId,
          req.user,
        );
        await notify(
          t,
          acceptance.technicianId,
          oid,
          'Khách chọn phương thức thanh toán',
          b.method === 'COD'
            ? 'Thu tiền mặt sau khi khách giao đủ tiền.'
            : 'Khách chuyển khoản về HomeFix. Không thu thêm tiền mặt.',
        );
        return { method: b.method, request };
      });
    });
    ok(res, result.data, result.replay ? 200 : 201);
  }),
);
paymentsRouter.post(
  '/payment-requests/:id/submit',
  roles('KH'),
  wrap(async (req, res) => {
    const rid = id(req.params.id),
      b = z
        .strictObject({
          proofId: z.number().int().positive(),
          customerReference: str(0, 100).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const request = await one(
        'SELECT * FROM dbo.YeuCauThanhToan WHERE Id=@Id AND KhachHangId=@uid',
        { id: rid, uid: req.user.id },
        t,
      );
      if (!request) fail(404, 'NOT_FOUND', 'Không tìm thấy yêu cầu.');
      await getOrder(request.orderId, req.user, t);
      return idempotent(t, req, b, async () => {
        checkVersion(request, b.expectedVersion);
        state(request, 'AwaitingTransfer', 'Rejected');
        if (!request.isActive) fail(409, 'PAYMENT_REQUEST_EXPIRED', 'Yêu cầu không còn hiệu lực.');
        if (
          await one('SELECT Id FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: request.orderId }, t)
        )
          fail(409, 'PAYMENT_ALREADY_PAID', 'Đơn đã thanh toán.');
        const proof = await one(
          "SELECT Id FROM dbo.TepDinhKem WHERE Id=@Id AND ChuSoHuuId=@uid AND DonHangId=@oid AND MucDich='PaymentProof'",
          { id: b.proofId, uid: req.user.id, oid: request.orderId },
          t,
        );
        if (!proof)
          fail(404, 'ATTACHMENT_NOT_FOUND', 'Chứng từ không thuộc khách hàng hoặc đơn này.');
        await q(
          `UPDATE dbo.YeuCauThanhToan
SET
  TrangThai = 'PendingReview',
  ChungTuId = @proof,
  MaThamChieuKhachHang = @reference,
  NgayGui = SYSUTCDATETIME(),
  LyDo = NULL,
  NguoiDuyetId = NULL,
  NgayDuyet = NULL
WHERE
  Id = @Id`,
          { id: rid, proof: b.proofId, reference: b.customerReference || null },
          t,
        );
        await touch(t, request.orderId);
        await audit(
          t,
          req.user,
          'SubmitTransferProof',
          'YeuCauThanhToan',
          rid,
          JSON.stringify({
            proofId: b.proofId,
            previousProofId: request.proofId,
            previousReason: request.reason,
          }),
        );
        for (const accountant of await q(
          "SELECT Id FROM dbo.NguoiDung WHERE VaiTro='KT' AND DangHoatDong=1",
          {},
          t,
        ))
          await notify(
            t,
            accountant.id,
            request.orderId,
            'Có chuyển khoản cần xác minh',
            request.transferContent,
          );
        return one('SELECT * FROM dbo.YeuCauThanhToan WHERE Id=@Id', { id: rid }, t);
      });
    });
    ok(res, result.data);
  }),
);
paymentsRouter.get(
  '/bank-payment-requests',
  roles('KT'),
  wrap(async (req, res) =>
    ok(
      res,
      await q(`SELECT TOP 200 r.*,n.HoTen TenKhachHang
 FROM dbo.YeuCauThanhToan r JOIN dbo.NguoiDung n ON n.Id=r.KhachHangId
 WHERE r.TrangThai IN('PendingReview','Confirmed','Rejected')
 ORDER BY CASE WHEN r.TrangThai='PendingReview' THEN 0 ELSE 1 END,r.Id DESC`),
    ),
  ),
);
paymentsRouter.post(
  '/payment-requests/:id/decision',
  roles('KT'),
  wrap(async (req, res) => {
    const rid = id(req.params.id),
      b = z
        .strictObject({
          decision: z.enum(['Approved', 'Rejected']),
          expectedVersion: versionSchema,
          reason: str(5, 1000).optional(),
          receivedAmount: money.optional(),
          bankReference: z
            .string()
            .trim()
            .toUpperCase()
            .regex(/^[A-Z0-9][A-Z0-9._\/-]{3,99}$/, 'Nhập mã giao dịch ngân hàng từ 4–100 ký tự.')
            .optional(),
        })
        .parse(req.body);
    if (b.decision === 'Rejected' && !b.reason)
      fail(422, 'REASON_REQUIRED', 'Cần lý do để khách kiểm tra và gửi lại.');
    if (b.decision === 'Approved' && (!b.receivedAmount || !b.bankReference))
      fail(
        422,
        'BANK_CONFIRMATION_REQUIRED',
        'Nhập số tiền thực nhận và mã giao dịch trên sao kê.',
      );
    const result = await transaction(req.user, (t) =>
      idempotent(t, req, b, async () => {
        const request = await one('SELECT * FROM dbo.YeuCauThanhToan WHERE Id=@Id', { id: rid }, t);
        checkVersion(request, b.expectedVersion);
        state(request, 'PendingReview');
        if (!request.isActive) fail(409, 'PAYMENT_REQUEST_EXPIRED', 'Yêu cầu không còn hiệu lực.');
        const order = await getOrder(request.orderId, req.user, t);
        state(order, 'HoanThanh');
        if (await one('SELECT Id FROM dbo.ThanhToan WHERE DonHangId=@Id', { id: order.id }, t))
          fail(409, 'PAYMENT_ALREADY_PAID', 'Đơn đã thanh toán.');
        let payment = null;
        if (b.decision === 'Approved') {
          if (Number(b.receivedAmount) !== Number(request.amount))
            fail(
              422,
              'AMOUNT_MISMATCH',
              'Số tiền thực nhận phải bằng tổng tiền nghiệm thu. Khoản thiếu/thừa cần xử lý qua hỗ trợ trước.',
            );
          if (
            await one(
              'SELECT Id FROM dbo.ThanhToan WHERE TaiKhoanNganHangId=@bid AND MaThamChieuNganHang=@reference',
              { bid: request.bankAccountId, reference: b.bankReference },
              t,
            )
          )
            fail(409, 'BANK_REFERENCE_USED', 'Giao dịch ngân hàng này đã dùng cho một khoản thu.');
          payment = await one(
            `INSERT dbo.ThanhToan(DonHangId,NghiemThuId,SoTien,PhuongThuc,NguoiThuTienId,TaiKhoanNganHangId,MaThamChieuNganHang)
    VALUES(@oid,@aid,CAST(@SoTien AS decimal(18,2)),'BANK',@uid,@bid,@reference); SELECT * FROM dbo.ThanhToan WHERE Id=SCOPE_IDENTITY()`,
            {
              oid: order.id,
              aid: request.acceptanceId,
              amount: String(request.amount),
              uid: req.user.id,
              bid: request.bankAccountId,
              reference: b.bankReference,
            },
            t,
          );
          await q(
            `INSERT dbo.DoiSoat(DonHangId,KyThuatVienId,ThanhToanId,TienCong,TyLeHoaHong)
    SELECT @oid,a.KyThuatVienId,@pid,b.TienCong,b.TyLeHoaHong FROM dbo.PhieuNghiemThu a JOIN dbo.BaoGiaSoBo b ON b.DonHangId=a.DonHangId WHERE a.Id=@aid`,
            { oid: order.id, pid: payment.id, aid: request.acceptanceId },
            t,
          );
        }
        await q(
          `UPDATE dbo.YeuCauThanhToan
SET
  TrangThai = @TrangThai,
  DangHoatDong = @active,
  LyDo = @LyDo,
  NguoiDuyetId = @uid,
  NgayDuyet = SYSUTCDATETIME(),
  ThanhToanId = @pid
WHERE
  Id = @Id`,
          {
            id: rid,
            status: payment ? 'Confirmed' : 'Rejected',
            active: !payment,
            reason: b.reason || null,
            uid: req.user.id,
            pid: payment?.id || null,
          },
          t,
        );
        await touch(t, order.id);
        await audit(
          t,
          req.user,
          payment ? 'ConfirmBankPayment' : 'RejectBankPayment',
          'YeuCauThanhToan',
          rid,
          b.reason || b.bankReference,
        );
        await notify(
          t,
          order.customerId,
          order.id,
          payment ? 'Đã xác nhận thanh toán chuyển khoản' : 'Chứng từ chuyển khoản cần kiểm tra',
          payment ? 'HomeFix đã nhận đủ tiền. Cảm ơn bạn.' : b.reason,
        );
        if (payment)
          await notify(
            t,
            order.assignedTechnicianId,
            order.id,
            'HomeFix đã nhận chuyển khoản',
            'Không thu tiền mặt. Kế toán sẽ đối soát để cộng phần tiền thuộc bạn vào ví.',
          );
        return one('SELECT * FROM dbo.YeuCauThanhToan WHERE Id=@Id', { id: rid }, t);
      }),
    );
    ok(res, result.data);
  }),
);
