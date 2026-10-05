import { Router } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { config } from './config.js';
import { q, one, transaction } from './db.js';
import { z, id, ok, wrap, fail, getOrder, activeTech, state } from './common.js';
export const uploadsRouter = Router();
export const publicUploadsRouter = Router();
publicUploadsRouter.get(
  '/avatar/:id',
  wrap(async (req, res) => {
    const f = await one(
      "SELECT KhoaLuuTru,KieuMIME FROM dbo.TepDinhKem WHERE Id=@Id AND MucDich='Avatar'",
      { id: id(req.params.id) },
    );
    if (!f) fail(404, 'NOT_FOUND', 'Không tìm thấy ảnh.');
    res.set('Cache-Control', 'public, max-age=86400');
    res.type(f.mimeType).sendFile(path.join(config.uploads, f.storageKey), { dotfiles: 'allow' });
  }),
);
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1, fields: 3 },
});
const purposes = z.enum([
  'OrderFault',
  'MaterialEvidence',
  'AcceptancePhoto',
  'CustomerSignature',
  'WalletProof',
  'TechnicianDocument',
  'PaymentProof',
  'Avatar',
]);
uploadsRouter.post(
  '/uploads',
  upload.single('file'),
  wrap(async (req, res) => {
    const purpose = purposes.parse(req.body.purpose),
      oid = req.body.orderId ? id(req.body.orderId) : null;
    if (!req.file) fail(422, 'FILE_REQUIRED', 'Vui lòng chọn ảnh JPG hoặc PNG.');
    let format;
    try {
      const meta = await sharp(req.file.buffer, { limitInputPixels: 20000000 }).metadata();
      format = meta.format;
    } catch {
      fail(415, 'INVALID_IMAGE', 'Ảnh không đọc được hoặc vượt giới hạn kích thước.');
    }
    if (!['jpeg', 'png'].includes(format))
      fail(415, 'INVALID_IMAGE', 'Chỉ chấp nhận ảnh JPG/PNG thật.');
    const bytes = await sharp(req.file.buffer, { limitInputPixels: 20000000 })
      .rotate()
      .resize({ width: 1800, height: 1800, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 85 })
      .toBuffer();
    const key = crypto.randomUUID() + '.jpg';
    await fs.mkdir(config.uploads, { recursive: true });
    const target = path.join(config.uploads, key);
    await fs.writeFile(target, bytes);
    try {
      const record = await transaction(req.user, async (t) => {
        if (
          ['MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'PaymentProof'].includes(
            purpose,
          ) &&
          !oid
        )
          fail(422, 'ORDER_REQUIRED', 'Loại ảnh này phải gắn với đơn.');
        if (purpose === 'OrderFault' && req.user.role !== 'KH')
          fail(403, 'FORBIDDEN', 'Chỉ khách tải ảnh lỗi.');
        if (
          ['WalletProof', 'MaterialEvidence', 'AcceptancePhoto'].includes(purpose) &&
          req.user.role !== 'KTV'
        )
          fail(403, 'FORBIDDEN', 'Chỉ kỹ thuật viên tải loại ảnh này.');
        if (['TechnicianDocument', 'PaymentProof'].includes(purpose) && req.user.role !== 'KH')
          fail(403, 'FORBIDDEN', 'Chỉ khách dùng loại ảnh này.');
        if (purpose === 'CustomerSignature' && !['KH', 'KTV'].includes(req.user.role))
          fail(403, 'FORBIDDEN', 'Chỉ khách hoặc kỹ thuật viên thực hiện đơn được tải chữ ký.');
        if (oid) {
          const o = await getOrder(oid, req.user, t);
          if (['MaterialEvidence', 'AcceptancePhoto'].includes(purpose)) {
            await activeTech(t, o, req.user);
            state(o, 'DangXuLy');
          }
          if (purpose === 'PaymentProof') {
            state(o, 'HoanThanh');
            if (
              o.paymentMethod !== 'BANK' ||
              o.paymentStatus === 'Paid' ||
              !(await one(
                "SELECT Id FROM dbo.YeuCauThanhToan WHERE DonHangId=@oid AND TrangThai IN('AwaitingTransfer','Rejected') AND DangHoatDong=1",
                { oid },
                t,
              ))
            )
              fail(
                409,
                'PAYMENT_PROOF_NOT_ALLOWED',
                'Chọn chuyển khoản đang chờ thanh toán trước khi gửi chứng từ.',
              );
          }
          if (purpose === 'CustomerSignature') {
            if (req.user.role === 'KTV') {
              await activeTech(t, o, req.user);
              state(o, 'DangXuLy');
            } else state(o, 'ChoNghiemThu');
          }
          if (purpose === 'OrderFault') state(o, 'ChoTiepNhan');
        }
        if (
          oid &&
          (
            await one(
              'SELECT COUNT(*) n FROM dbo.TepDinhKem WHERE DonHangId=@oid AND MucDich=@MucDich AND NghiemThuId IS NULL',
              { oid, purpose },
              t,
            )
          ).n >= 5
        )
          fail(422, 'TOO_MANY_IMAGES', 'Đã đủ 5 ảnh cho nhóm này.');
        const f = await one(
          `INSERT
  dbo.TepDinhKem (ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc) OUTPUT INSERTED.Id,
  INSERTED.MucDich,
  INSERTED.KichThuoc,
  INSERTED.KieuMIME
VALUES
  (@uid, @oid, @MucDich, @KhoaCauHinh, @Ten, 'image/jpeg', @KichThuoc)`,
          {
            uid: req.user.id,
            oid,
            purpose,
            key,
            name: req.file.originalname.slice(0, 255),
            size: bytes.length,
          },
          t,
        );
        if (purpose === 'Avatar') {
          await q(
            'UPDATE dbo.NguoiDung SET DuongDanAnhDaiDien=@url WHERE Id=@uid',
            { url: '/api/avatar/' + f.id, uid: req.user.id },
            t,
          );
        }
        return {
          ...f,
          downloadPath: purpose === 'Avatar' ? '/api/avatar/' + f.id : '/api/uploads/' + f.id,
        };
      });
      ok(res, record, 201);
    } catch (e) {
      await fs.unlink(target).catch(() => {});
      throw e;
    }
  }),
);
uploadsRouter.get(
  '/uploads/:id',
  wrap(async (req, res) => {
    const f = await one('SELECT * FROM dbo.TepDinhKem WHERE Id=@Id', { id: id(req.params.id) });
    if (!f) fail(404, 'NOT_FOUND', 'Không tìm thấy ảnh.');
    if (f.purpose === 'PaymentProof') {
      if (f.ownerId !== req.user.id && req.user.role !== 'KT')
        fail(404, 'NOT_FOUND', 'Không tìm thấy ảnh.');
    } else if (['WalletProof', 'TechnicianDocument'].includes(f.purpose)) {
      if (
        f.ownerId !== req.user.id &&
        !(f.purpose === 'WalletProof' && req.user.role === 'KT') &&
        !(f.purpose === 'TechnicianDocument' && req.user.role === 'ADMIN')
      )
        fail(404, 'NOT_FOUND', 'Không tìm thấy ảnh.');
    } else if (f.purpose === 'Avatar') {
    } else if (f.orderId) {
      if (req.user.role === 'KT') fail(403, 'FORBIDDEN', 'Kế toán không xem ảnh hiện trường.');
      await getOrder(f.orderId, req.user);
    } else if (f.ownerId !== req.user.id) fail(404, 'NOT_FOUND', 'Không tìm thấy ảnh.');
    res.set('Cache-Control', 'private, no-store');
    res.type(f.mimeType).sendFile(path.join(config.uploads, f.storageKey), { dotfiles: 'allow' });
  }),
);
uploadsRouter.get(
  '/orders/:id/attachments',
  wrap(async (req, res) => {
    const oid = id(req.params.id);
    if (req.user.role === 'KT') fail(403, 'FORBIDDEN', 'Kế toán không xem ảnh hiện trường.');
    await getOrder(oid, req.user);
    ok(
      res,
      await q(
        `SELECT
  Id,
  MucDich,
  TenTepGoc,
  KieuMIME,
  KichThuoc,
  NghiemThuId,
  NgayTao
FROM
  dbo.TepDinhKem
WHERE
  DonHangId = @Id
  AND MucDich <> 'PaymentProof'
ORDER BY
  Id`,
        { id: oid },
      ),
    );
  }),
);
