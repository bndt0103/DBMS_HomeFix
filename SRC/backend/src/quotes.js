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
  decisionSchema,
  checkVersion,
  state,
  getOrder,
  activeTech,
  transition,
  touch,
  notify,
} from './common.js';
import { setting } from './orders.js';
import { selectPayment } from './payments.js';
export const quotesRouter = Router();
const fresh = (table, rid, t) => one(`SELECT * FROM dbo.${table} WHERE Id=@Id`, { id: rid }, t);
for (const [route, table] of [
  ['preliminary-quotes', 'BaoGiaSoBo'],
  ['material-quotes', 'DeXuatVatTu'],
  ['acceptances', 'PhieuNghiemThu'],
]) {
  const decorate = async (row) => {
    if (table === 'DeXuatVatTu')
      row.items = await q('SELECT * FROM dbo.ChiTietDeXuatVatTu WHERE BaoGiaId=@Id', {
        id: row.id,
      });
    if (table === 'PhieuNghiemThu')
      row.photos = await q(
        "SELECT Id,MucDich,TenTepGoc FROM dbo.TepDinhKem WHERE NghiemThuId=@Id AND MucDich='AcceptancePhoto'",
        { id: row.id },
      );
    return row;
  };
  quotesRouter.get(
    `/orders/:id/${route}`,
    wrap(async (req, res) => {
      const oid = id(req.params.id);
      await getOrder(oid, req.user);
      const rows = await q(`SELECT * FROM dbo.${table} WHERE DonHangId=@Id ORDER BY Id DESC`, {
        id: oid,
      });
      ok(res, await Promise.all(rows.map(decorate)));
    }),
  );
  quotesRouter.get(
    `/orders/:id/${route}/:recordId`,
    wrap(async (req, res) => {
      const oid = id(req.params.id);
      await getOrder(oid, req.user);
      const row = await one(`SELECT * FROM dbo.${table} WHERE DonHangId=@oid AND Id=@Id`, {
        oid,
        id: id(req.params.recordId),
      });
      if (!row) fail(404, 'NOT_FOUND', 'Không tìm thấy phiếu.');
      ok(res, await decorate(row));
    }),
  );
}
quotesRouter.post(
  '/orders/:id/preliminary-quotes',
  roles('DPV'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = z
        .strictObject({ diagnosis: str(5, 2000), expectedVersion: versionSchema })
        .parse(req.body);
    const quote = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      checkVersion(o, b.expectedVersion);
      state(o, 'ChoTiepNhan');
      const quote = await one(
        `INSERT
  dbo.BaoGiaSoBo (DonHangId, ChanDoan, PhiKiemTra, TienCong, TyLeHoaHong, NguoiTaoId) OUTPUT INSERTED.*
SELECT
  @oid,
  @ChanDoan,
  PhiKiemTra,
  TienCong,
  TyLeHoaHong,
  @uid
FROM
  dbo.DichVu
WHERE
  Id = @DichVuId`,
        { oid, diagnosis: b.diagnosis, uid: req.user.id, serviceId: o.serviceId },
        t,
      );
      await transition(t, o, req.user, 'ChoDuyetSoBo', 'Đã gửi báo giá sơ bộ');
      await notify(
        t,
        o.customerId,
        oid,
        'Báo giá sơ bộ cần xác nhận',
        'Vui lòng xem chi tiết trước khi đồng ý.',
      );
      return quote;
    });
    ok(res, quote, 201);
  }),
);
quotesRouter.post(
  '/orders/:id/preliminary-quotes/:recordId/decision',
  roles('KH'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      rid = id(req.params.recordId),
      b = decisionSchema.parse(req.body);
    const quote = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      const current = await one(
        'SELECT * FROM dbo.BaoGiaSoBo WHERE DonHangId=@oid AND Id=@Id',
        { oid, id: rid },
        t,
      );
      checkVersion(current, b.expectedVersion);
      state(current, 'Pending');
      state(o, 'ChoDuyetSoBo');
      await q(
        'UPDATE dbo.BaoGiaSoBo SET TrangThai=@decision,LyDo=@LyDo,NguoiDuyetId=@uid,NgayDuyet=SYSUTCDATETIME() WHERE Id=@Id',
        { id: rid, uid: req.user.id, decision: b.decision, reason: b.reason },
        t,
      );
      await transition(
        t,
        o,
        req.user,
        b.decision === 'Approved' ? 'ChoPhanCong' : 'Huy',
        b.reason || 'Khách duyệt báo giá sơ bộ',
      );
      if (b.decision === 'Rejected')
        await q(
          'UPDATE dbo.DonHang SET LyDoHuy=@LyDo,NgayHuy=SYSUTCDATETIME() WHERE Id=@Id',
          { id: oid, reason: b.reason },
          t,
        );
      return fresh('BaoGiaSoBo', rid, t);
    });
    ok(res, quote);
  }),
);
const itemSchema = z.strictObject({
  name: str(1, 200),
  quantity: z
    .string()
    .regex(/^\d{1,3}(\.\d{1,2})?$/)
    .refine((s) => Number(s) > 0 && Number(s) <= 999.99),
  unitPrice: money,
  unit: str(1, 30),
  warrantyMonths: z.number().int().min(0).max(60),
});
quotesRouter.post(
  '/orders/:id/material-quotes',
  roles('KTV'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = z
        .strictObject({
          items: z.array(itemSchema).min(1).max(20),
          note: str(0, 1000).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    const quote = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      await activeTech(t, o, req.user);
      checkVersion(o, b.expectedVersion);
      state(o, 'DangXuLy');
      if (
        await one(
          "SELECT Id FROM dbo.DeXuatVatTu WHERE DonHangId=@Id AND TrangThai IN('Pending','Approved')",
          { id: oid },
          t,
        )
      )
        fail(409, 'MATERIAL_QUOTE_EXISTS', 'Đã có đề xuất chờ duyệt hoặc đã duyệt.');
      await q('UPDATE dbo.DeXuatVatTu SET DangApDung=0 WHERE DonHangId=@Id', { id: oid }, t);
      const quote = await one(
        `INSERT
  dbo.DeXuatVatTu (DonHangId, LanSuaDoi, GhiChu, NguoiTaoId) OUTPUT INSERTED.*
SELECT
  @oid,
  COALESCE(MAX(LanSuaDoi), 0) + 1,
  @GhiChu,
  @uid
FROM
  dbo.DeXuatVatTu
WHERE
  DonHangId = @oid`,
        { oid, note: b.note, uid: req.user.id },
        t,
      );
      for (const item of b.items)
        await q(
          `INSERT
  dbo.ChiTietDeXuatVatTu (BaoGiaId, Ten, SoLuong, DonGia, DonViTinh, SoThangBaoHanh)
VALUES
  (
    @qid,
    @Ten,
    CAST(@SoLuong AS decimal(10, 2)),
    CAST(@DonGia AS decimal(18, 2)),
    @DonViTinh,
    @SoThangBaoHanh
  )`,
          { qid: quote.id, ...item },
          t,
        );
      await q(
        'UPDATE dbo.DeXuatVatTu SET TongTien=(SELECT SUM(ThanhTien) FROM dbo.ChiTietDeXuatVatTu WHERE BaoGiaId=@Id) WHERE Id=@Id',
        { id: quote.id },
        t,
      );
      await touch(t, oid);
      await notify(
        t,
        o.customerId,
        oid,
        'Đề xuất vật tư cần duyệt',
        'Thợ chỉ thay vật tư sau khi bạn đồng ý.',
      );
      return {
        ...(await fresh('DeXuatVatTu', quote.id, t)),
        items: await q(
          'SELECT * FROM dbo.ChiTietDeXuatVatTu WHERE BaoGiaId=@Id',
          { id: quote.id },
          t,
        ),
      };
    });
    ok(res, quote, 201);
  }),
);
quotesRouter.post(
  '/orders/:id/material-quotes/:recordId/decision',
  roles('KH'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      rid = id(req.params.recordId),
      b = decisionSchema.parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      state(o, 'DangXuLy');
      const current = await one(
        'SELECT * FROM dbo.DeXuatVatTu WHERE DonHangId=@oid AND Id=@Id',
        { oid, id: rid },
        t,
      );
      checkVersion(current, b.expectedVersion);
      state(current, 'Pending');
      if (!current.isCurrent) fail(409, 'QUOTE_EXPIRED', 'Phiếu không còn hiệu lực.');
      await q(
        'UPDATE dbo.DeXuatVatTu SET TrangThai=@decision,LyDo=@LyDo,NguoiDuyetId=@uid,NgayDuyet=SYSUTCDATETIME() WHERE Id=@Id',
        { id: rid, decision: b.decision, reason: b.reason, uid: req.user.id },
        t,
      );
      await touch(t, oid);
      await notify(
        t,
        o.assignedTechnicianId,
        oid,
        'Khách đã phản hồi vật tư',
        b.decision === 'Approved' ? 'Đã đồng ý thay vật tư.' : b.reason,
      );
      return fresh('DeXuatVatTu', rid, t);
    });
    ok(res, result);
  }),
);
quotesRouter.post(
  '/orders/:id/acceptances',
  roles('KTV'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      b = z
        .strictObject({
          cause: str(5, 2000),
          solution: str(5, 2000),
          photoIds: z.array(z.number().int().positive()).min(1).max(5),
          signatureId: z.number().int().positive().optional(),
          proposedPaymentMethod: z.enum(['COD', 'BANK']).optional(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      await activeTech(t, o, req.user);
      checkVersion(o, b.expectedVersion);
      state(o, 'DangXuLy');
      if (new Set(b.photoIds).size !== b.photoIds.length)
        fail(422, 'DUPLICATE_ATTACHMENT', 'Ảnh bị lặp.');
      if (
        await one(
          "SELECT Id FROM dbo.DeXuatVatTu WHERE DonHangId=@Id AND TrangThai='Pending'",
          { id: oid },
          t,
        )
      )
        fail(409, 'MATERIAL_DECISION_PENDING', 'Khách chưa phản hồi vật tư.');
      for (const fid of b.photoIds)
        if (
          !(await one(
            `SELECT
  Id
FROM
  dbo.TepDinhKem
WHERE
  Id = @Id
  AND ChuSoHuuId = @uid
  AND DonHangId = @oid
  AND MucDich = 'AcceptancePhoto'
  AND NghiemThuId IS NULL`,
            { id: fid, uid: req.user.id, oid },
            t,
          ))
        )
          fail(404, 'ATTACHMENT_NOT_FOUND', 'Ảnh nghiệm thu không đúng quyền, đơn hoặc đã dùng.');
      if (
        b.signatureId &&
        !(await one(
          `SELECT
  Id
FROM
  dbo.TepDinhKem
WHERE
  Id = @Id
  AND ChuSoHuuId = @uid
  AND DonHangId = @oid
  AND MucDich = 'CustomerSignature'
  AND NghiemThuId IS NULL`,
          { id: b.signatureId, uid: req.user.id, oid },
          t,
        ))
      )
        fail(404, 'ATTACHMENT_NOT_FOUND', 'Chữ ký hiện trường không hợp lệ hoặc đã dùng.');
      const preliminary = await one(
        "SELECT * FROM dbo.BaoGiaSoBo WHERE DonHangId=@Id AND TrangThai='Approved'",
        { id: oid },
        t,
      );
      if (!preliminary) fail(409, 'QUOTE_NOT_APPROVED', 'Chưa có báo giá được duyệt.');
      const material = await one(
        "SELECT * FROM dbo.DeXuatVatTu WHERE DonHangId=@Id AND TrangThai='Approved' AND DangApDung=1",
        { id: oid },
        t,
      );
      const acceptance = await one(
        `INSERT
  dbo.PhieuNghiemThu (
    DonHangId,
    KyThuatVienId,
    LanSuaDoi,
    NguyenNhan,
    PhuongAnXuLy,
    DeXuatVatTuId,
    PhiKiemTra,
    TienCong,
    TongTienVatTu
  ) OUTPUT INSERTED.*
SELECT
  @oid,
  @uid,
  COALESCE(MAX(LanSuaDoi), 0) + 1,
  @NguyenNhan,
  @PhuongAnXuLy,
  @mid,
  CAST(@inspection AS decimal(18, 2)),
  CAST(@labor AS decimal(18, 2)),
  CAST(@material AS decimal(18, 2))
FROM
  dbo.PhieuNghiemThu
WHERE
  DonHangId = @oid`,
        {
          oid,
          uid: req.user.id,
          cause: b.cause,
          solution: b.solution,
          mid: material?.id,
          inspection: String(preliminary.inspectionFee),
          labor: String(preliminary.laborFee),
          material: String(material?.total ?? 0),
        },
        t,
      );
      await q(
        'UPDATE dbo.PhieuNghiemThu SET ChuKyId=@signature,PhuongThucThanhToanDeXuat=@PhuongThuc WHERE Id=@Id',
        { id: acceptance.id, signature: b.signatureId, method: b.proposedPaymentMethod },
        t,
      );
      if (b.signatureId)
        await q(
          'UPDATE dbo.TepDinhKem SET NghiemThuId=@aid WHERE Id=@Id',
          { aid: acceptance.id, id: b.signatureId },
          t,
        );
      for (const fid of b.photoIds)
        await q(
          'UPDATE dbo.TepDinhKem SET NghiemThuId=@aid WHERE Id=@Id',
          { aid: acceptance.id, id: fid },
          t,
        );
      await transition(t, o, req.user, 'ChoNghiemThu', 'Thợ gửi phiếu nghiệm thu');
      await notify(
        t,
        o.customerId,
        oid,
        'Vui lòng xác nhận nghiệm thu',
        'Kiểm tra thiết bị, ảnh, chữ ký và tổng tiền trước khi xác nhận.',
      );
      return fresh('PhieuNghiemThu', acceptance.id, t);
    });
    ok(res, result, 201);
  }),
);
quotesRouter.post(
  '/orders/:id/acceptances/:recordId/decision',
  roles('KH'),
  wrap(async (req, res) => {
    const oid = id(req.params.id),
      rid = id(req.params.recordId),
      b = decisionSchema
        .safeExtend({
          paymentMethod: z.enum(['COD', 'BANK']).optional(),
          bankAccountId: z.number().int().positive().optional(),
        })
        .parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const o = await getOrder(oid, req.user, t);
      state(o, 'ChoNghiemThu');
      const current = await one(
        'SELECT * FROM dbo.PhieuNghiemThu WHERE DonHangId=@oid AND Id=@Id',
        { oid, id: rid },
        t,
      );
      checkVersion(current, b.expectedVersion);
      state(current, 'Pending');
      if (b.decision === 'Approved') {
        if ((await setting(t, 'signatureRequired', 'false')) === 'true' && !b.signatureId)
          fail(422, 'SIGNATURE_REQUIRED', 'Vui lòng bổ sung chữ ký.');
        if (
          b.signatureId &&
          !(await one(
            `SELECT
  Id
FROM
  dbo.TepDinhKem
WHERE
  Id = @Id
  AND DonHangId = @oid
  AND MucDich = 'CustomerSignature'
  AND (
    ChuSoHuuId = @uid
    OR (
      ChuSoHuuId = @techId
      AND Id = @capturedId
      AND NghiemThuId = @NghiemThuId
    )
  )`,
            {
              id: b.signatureId,
              uid: req.user.id,
              oid,
              techId: current.technicianId,
              capturedId: current.signatureId,
              acceptanceId: current.id,
            },
            t,
          ))
        )
          fail(404, 'ATTACHMENT_NOT_FOUND', 'Chữ ký không hợp lệ.');
      }
      await q(
        `UPDATE dbo.PhieuNghiemThu
SET
  TrangThai = @decision,
  LyDo = @LyDo,
  ChuKyId = @signature,
  NguoiDuyetId = @uid,
  NgayDuyet = SYSUTCDATETIME()
WHERE
  Id = @Id`,
        {
          id: rid,
          decision: b.decision,
          reason: b.reason,
          signature: b.signatureId ?? current.signatureId,
          uid: req.user.id,
        },
        t,
      );
      if (b.decision === 'Approved')
        await selectPayment(t, o, current, b.paymentMethod || 'COD', b.bankAccountId, req.user);
      await transition(
        t,
        o,
        req.user,
        b.decision === 'Approved' ? 'HoanThanh' : 'DangXuLy',
        b.reason || 'Khách xác nhận nghiệm thu',
      );
      if (b.decision === 'Approved') {
        await q(
          'UPDATE dbo.LenhDieuPhoi SET DangHoatDong=0 WHERE DonHangId=@Id AND DangHoatDong=1',
          { id: oid },
          t,
        );
        await q(
          "UPDATE dbo.KyThuatVien SET TrangThaiSanSang='TamBan' WHERE Id=@Id",
          { id: current.technicianId },
          t,
        );
      }
      await notify(
        t,
        current.technicianId,
        oid,
        b.decision === 'Approved' ? 'Khách đã nghiệm thu' : 'Khách yêu cầu xử lý lại',
        b.reason ||
          (b.paymentMethod === 'BANK'
            ? 'Khách chuyển khoản về HomeFix. Không thu thêm tiền mặt.'
            : 'Thu tiền mặt và xác nhận sau khi thực nhận.'),
      );
      return fresh('PhieuNghiemThu', rid, t);
    });
    ok(res, result);
  }),
);
