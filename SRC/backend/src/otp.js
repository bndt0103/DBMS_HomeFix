import crypto from 'node:crypto';
import { config } from './config.js';
import { q, one, transaction } from './db.js';
import { fail, z } from './common.js';
import { deliverOtp, deliveryConfigured } from './otp-delivery.js';

export const otpFields = {
  challengeId: z.uuid(),
  otp: z.string().regex(/^\d{6}$/, 'Mã OTP gồm 6 chữ số.'),
};
export const otpBinding = (value) =>
  crypto.createHmac('sha256', config.secret).update(JSON.stringify(value)).digest('hex');
const codeHash = (id, code) => otpBinding([id, code]);
export const accountBinding = (u) => otpBinding([u.id, u.tokenVersion, u.phone, u.email]);
export const registrationBinding = (b) =>
  otpBinding([b.fullName, b.phone, b.email ?? null, b.password]);
export const otpEmailDeliverable = (email) => {
  const domain = String(email || '')
    .toLowerCase()
    .split('@')
    .at(-1);
  return (
    Boolean(domain) &&
    !['localhost', 'local', 'test', 'invalid', 'example'].includes(domain) &&
    !domain.endsWith('.local') &&
    !domain.endsWith('.test') &&
    !domain.endsWith('.invalid') &&
    !domain.endsWith('.example')
  );
};

export async function issueOtp({ purpose, destination, binding, deliver = true }) {
  if (!deliveryConfigured())
    fail(
      503,
      'OTP_NOT_CONFIGURED',
      'Dịch vụ gửi email OTP chưa được cấu hình. Vui lòng liên hệ hỗ trợ.',
    );
  const id = crypto.randomUUID(),
    code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  await transaction(null, async (t) => {
    await q('DELETE dbo.XacThucOTP WHERE NgayTao<DATEADD(day,-1,SYSUTCDATETIME())', {}, t);
    const recent = await one(
      `SELECT
  COUNT(*) n,
  MAX(NgayTao) lastSent
FROM
  dbo.XacThucOTP
WHERE
  DiaChiNhan = @DiaChiNhan
  AND NgayTao > DATEADD(hour, -1, SYSUTCDATETIME())`,
      { destination },
      t,
    );
    if (recent.n >= 3 || (recent.lastSent && Date.now() - recent.lastSent.getTime() < 90000))
      fail(
        429,
        'OTP_RATE_LIMITED',
        'Chờ ít nhất 90 giây trước khi gửi lại; tối đa 3 mã mỗi giờ cho một địa chỉ nhận.',
      );
    await q(
      'UPDATE dbo.XacThucOTP SET DaSuDung=1 WHERE DiaChiNhan=@DiaChiNhan AND MucDich=@MucDich',
      { destination, purpose },
      t,
    );
    await q(
      `INSERT
  dbo.XacThucOTP (Id, MucDich, KenhGui, DiaChiNhan, DuLieuRangBuoc, MaBamOTP, NgayHetHan)
VALUES
  (@Id, @MucDich, @KenhGui, @DiaChiNhan, @DuLieuRangBuoc, @hash, DATEADD(minute, 5, SYSUTCDATETIME()))`,
      { id, purpose, channel: 'email', destination, binding, hash: codeHash(id, code) },
      t,
    );
  });
  try {
    if (deliver) await deliverOtp(destination, code);
    await q('UPDATE dbo.XacThucOTP SET SanSang=1 WHERE Id=@Id', { id });
  } catch {
    await q('UPDATE dbo.XacThucOTP SET DaSuDung=1 WHERE Id=@Id', { id });
    fail(503, 'OTP_DELIVERY_FAILED', 'Chưa gửi được email OTP. Vui lòng thử lại sau.');
  }
  return {
    challengeId: id,
    expiresIn: 300,
    retryAfter: 90,
    message: 'Nếu thông tin hợp lệ, mã OTP sẽ được gửi đến email của bạn. Mã có hiệu lực 5 phút.',
  };
}

// Persist failed attempts even when verification fails; consume and mutate together.
// The shared transaction lock also prevents two processes from replaying a code.
export async function withOtp(body, purpose, binding, actor, action) {
  const result = await transaction(actor, async (t) => {
    const row = await one(
      'SELECT *,CASE WHEN NgayHetHan>SYSUTCDATETIME() THEN 1 ELSE 0 END validTime FROM dbo.XacThucOTP WHERE Id=@Id',
      { id: body.challengeId },
      t,
    );
    if (
      !row ||
      row.channel !== 'email' ||
      row.purpose !== purpose ||
      row.binding !== binding ||
      !row.ready ||
      row.consumed ||
      !row.validTime ||
      row.attempts >= 5
    )
      return { invalid: true };
    if (
      !crypto.timingSafeEqual(
        Buffer.from(row.codeHash, 'hex'),
        Buffer.from(codeHash(row.id.toLowerCase(), body.otp), 'hex'),
      )
    ) {
      await q(
        'UPDATE dbo.XacThucOTP SET SoLanThu=SoLanThu+1 WHERE Id=@Id',
        { id: body.challengeId },
        t,
      );
      return { invalid: true };
    }
    const data = await action(t);
    await q('UPDATE dbo.XacThucOTP SET DaSuDung=1 WHERE Id=@Id', { id: body.challengeId }, t);
    return { data };
  });
  if (result.invalid)
    fail(
      422,
      'INVALID_OTP',
      'Mã OTP không đúng, đã hết hạn, đã dùng hoặc thông tin đã thay đổi. Sau 5 lần sai, hãy yêu cầu mã mới.',
    );
  return result.data;
}
