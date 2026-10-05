import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { rateLimit } from 'express-rate-limit';
import { config } from './config.js';
import { q, one, transaction } from './db.js';
import { z, str, id, ok, wrap, fail, roles, versionSchema, checkVersion, audit } from './common.js';
import {
  otpFields,
  issueOtp,
  withOtp,
  accountBinding,
  registrationBinding,
  otpEmailDeliverable,
} from './otp.js';
export const authRouter = Router();
const phone = z.string().regex(/^0\d{9}$/, 'Số điện thoại gồm 10 chữ số, bắt đầu bằng 0.');
const email = z
  .email()
  .max(200)
  .transform((s) => s.toLowerCase())
  .nullable()
  .optional();
const password = z
  .string()
  .min(8, 'Mật khẩu ít nhất 8 ký tự.')
  .refine((s) => Buffer.byteLength(s, 'utf8') <= 72, 'Mật khẩu tối đa 72 byte UTF-8.');
export const userColumns =
  'Id,HoTen,SoDienThoai,Email,VaiTro,DiaChiMacDinh,DuongDanAnhDaiDien,DangHoatDong,KhoaDenNgay,PhienBanXacThuc,NgayTao,PhienBan';
export const profile = (u) => {
  const { tokenVersion, ...safe } = u;
  return safe;
};
export async function auth(req, res, next) {
  try {
    const raw = req.get('Authorization');
    if (!raw?.startsWith('Bearer ')) fail(401, 'UNAUTHENTICATED', 'Vui lòng đăng nhập.');
    let token;
    try {
      token = jwt.verify(raw.slice(7), config.secret, { algorithms: ['HS256'], issuer: 'homefix' });
    } catch {
      fail(401, 'SESSION_EXPIRED', 'Phiên đã hết hạn. Vui lòng đăng nhập lại.');
    }
    const u = await one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, {
      id: Number(token.sub),
    });
    if (!u || u.tokenVersion !== token.tokenVersion)
      fail(401, 'SESSION_REVOKED', 'Phiên đăng nhập đã bị thu hồi.');
    if (u.lockedUntil && new Date(u.lockedUntil) > new Date())
      fail(403, 'ACCOUNT_LOCKED', 'Tài khoản đang bị khóa tạm thời.');
    if (!u.isActive) fail(403, 'ACCOUNT_DISABLED', 'Tài khoản đang bị khóa.');
    req.user = u;
    next();
  } catch (e) {
    next(e);
  }
}
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 60,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    error: { code: 'RATE_LIMITED', message: 'Bạn thử quá nhiều lần. Vui lòng đợi 15 phút.' },
  },
});
const requiredEmail = z
  .email()
  .max(200)
  .transform((s) => s.toLowerCase());
const registration = { fullName: str(2, 120), phone, email: requiredEmail, password };
const sendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    error: {
      code: 'OTP_RATE_LIMITED',
      message: 'Bạn gửi quá nhiều yêu cầu OTP. Vui lòng thử lại sau 15 phút.',
    },
  },
});
authRouter.post(
  '/auth/register/otp',
  sendLimiter,
  wrap(async (req, res) => {
    const b = z.strictObject(registration).parse(req.body);
    if (!otpEmailDeliverable(b.email))
      fail(
        422,
        'OTP_EMAIL_UNDELIVERABLE',
        'Email này không nhận được OTP. Hãy dùng Gmail/email thật; tài khoản demo .local không nhận email.',
      );
    if (
      await one(
        'SELECT Id FROM dbo.NguoiDung WHERE SoDienThoai=@SoDienThoai OR (Email=@Email AND @Email IS NOT NULL)',
        { phone: b.phone, email: b.email },
      )
    )
      fail(
        409,
        'ACCOUNT_EXISTS',
        'Số điện thoại hoặc email đã được đăng ký. Bạn có thể dùng Quên mật khẩu.',
      );
    ok(
      res,
      await issueOtp({
        purpose: 'register',
        destination: b.email,
        binding: registrationBinding(b),
      }),
    );
  }),
);
authRouter.post(
  '/auth/register',
  limiter,
  wrap(async (req, res) => {
    const b = z.strictObject({ ...registration, ...otpFields }).parse(req.body);
    const hash = await bcrypt.hash(b.password, 12);
    const u = await withOtp(b, 'register', registrationBinding(b), null, async (t) => {
      const row = await one(
        `INSERT dbo.NguoiDung(HoTen,SoDienThoai,Email,MatKhauBam,VaiTro) OUTPUT INSERTED.Id VALUES(@HoTen,@SoDienThoai,@Email,@hash,'KH')`,
        { ...b, hash },
        t,
      );
      await audit(t, null, 'Register', 'NguoiDung', row.id);
      return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, row, t);
    });
    ok(res, profile(u), 201);
  }),
);
authRouter.post(
  '/auth/login',
  limiter,
  wrap(async (req, res) => {
    const b = z.strictObject({ identifier: str(3, 200), password: str(1, 200) }).parse(req.body);
    const u = await one('SELECT * FROM dbo.NguoiDung WHERE SoDienThoai=@login OR Email=@login', {
      login: b.identifier.toLowerCase(),
    });
    if (
      !u ||
      Buffer.byteLength(b.password, 'utf8') > 72 ||
      !(await bcrypt.compare(b.password, u.passwordHash))
    )
      fail(401, 'INVALID_CREDENTIALS', 'Số điện thoại/email hoặc mật khẩu không đúng.');
    if (u.lockedUntil && new Date(u.lockedUntil) > new Date())
      fail(403, 'ACCOUNT_LOCKED', 'Tài khoản đã bị khóa tạm thời. Vui lòng liên hệ quản trị viên.');
    if (!u.isActive) fail(403, 'ACCOUNT_DISABLED', 'Tài khoản đang bị khóa.');
    const accessToken = jwt.sign({ role: u.role, tokenVersion: u.tokenVersion }, config.secret, {
      subject: String(u.id),
      expiresIn: '15m',
      issuer: 'homefix',
      algorithm: 'HS256',
    });
    const { passwordHash, cccd, ...safe } = u;
    ok(res, { accessToken, expiresIn: 900, user: profile(safe) });
  }),
);
const recovery = { identifier: requiredEmail };
function recoveryDestination(b) {
  return b.identifier;
}
async function recoveryUser(b, t) {
  const destination = recoveryDestination(b);
  return one(
    'SELECT * FROM dbo.NguoiDung WHERE Email=@DiaChiNhan AND DangHoatDong=1',
    { destination },
    t,
  );
}
authRouter.post(
  '/auth/forgot-password/otp',
  sendLimiter,
  wrap(async (req, res) => {
    const b = z.strictObject(recovery).parse(req.body),
      destination = recoveryDestination(b),
      u = await recoveryUser(b);
    if (u && !otpEmailDeliverable(u.email))
      fail(
        422,
        'OTP_EMAIL_UNDELIVERABLE',
        'Tài khoản demo .local không nhận OTP. Hãy dùng mật khẩu demo hoặc email thật.',
      );
    ok(
      res,
      await issueOtp({
        purpose: 'reset',
        destination,
        binding: u ? accountBinding(u) : 'unknown',
        deliver: Boolean(u),
      }),
    );
  }),
);
authRouter.post(
  '/auth/reset-password',
  limiter,
  wrap(async (req, res) => {
    const b = z.strictObject({ ...recovery, ...otpFields, newPassword: password }).parse(req.body),
      u = await recoveryUser(b);
    const hash = await bcrypt.hash(b.newPassword, 12);
    await withOtp(b, 'reset', u ? accountBinding(u) : 'unknown', null, async (t) => {
      const current = await recoveryUser(b, t);
      if (!current || !u || accountBinding(current) !== accountBinding(u))
        fail(422, 'INVALID_OTP', 'Thông tin tài khoản đã thay đổi. Vui lòng yêu cầu mã mới.');
      await q(
        'UPDATE dbo.NguoiDung SET MatKhauBam=@hash,PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id',
        { id: current.id, hash },
        t,
      );
      await audit(t, current, 'ResetPassword', 'NguoiDung', current.id);
    });
    ok(res, { loginRequired: true });
  }),
);
authRouter.use(auth);
authRouter.post(
  '/admin/security/otp',
  sendLimiter,
  roles('ADMIN'),
  wrap(async (req, res) => {
    const destination = req.user.email;
    if (!destination)
      fail(
        422,
        'EMAIL_REQUIRED',
        'Tài khoản quản trị chưa có email. Vui lòng cập nhật email trước khi yêu cầu mã OTP.',
      );
    ok(
      res,
      await issueOtp({ purpose: 'admin-security', destination, binding: accountBinding(req.user) }),
    );
  }),
);
authRouter.post(
  '/users/:id/temporary-lock',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const uid = id(req.params.id),
      b = z
        .strictObject({
          duration: z.coerce.number().int().min(1).max(365),
          unit: z.enum(['day', 'week', 'month', 'year']),
          reason: str(5, 1000),
          ...otpFields,
        })
        .parse(req.body);
    const datePart = { day: 'day', week: 'week', month: 'month', year: 'year' }[b.unit];
    const locked = await withOtp(
      b,
      'admin-security',
      accountBinding(req.user),
      req.user,
      async (t) => {
        const current = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: uid }, t);
        if (!current) fail(404, 'NOT_FOUND', 'Không tìm thấy tài khoản.');
        if (current.id === req.user.id)
          fail(409, 'CANNOT_LOCK_SELF', 'Không thể tự khóa tài khoản quản trị đang đăng nhập.');
        if (
          current.role === 'ADMIN' &&
          (
            await one(
              `SELECT
  COUNT(*) n
FROM
  dbo.NguoiDung
WHERE
VaiTro = 'ADMIN'
AND DangHoatDong = 1
AND Id <> @Id
AND (
  KhoaDenNgay IS NULL
  OR KhoaDenNgay <= SYSUTCDATETIME()
)`,
              { id: uid },
              t,
            )
          ).n < 1
        )
          fail(409, 'LAST_ADMIN', 'Không thể khóa quản trị viên hoạt động cuối cùng.');
        if (
          current.role === 'KTV' &&
          (await one(
            'SELECT Id FROM dbo.LenhDieuPhoi WHERE KyThuatVienId=@Id AND DangHoatDong=1',
            { id: uid },
            t,
          ))
        )
          fail(
            409,
            'ACTIVE_ASSIGNMENT',
            'Kỹ thuật viên đang có ca, cần hoàn tất hoặc điều phối lại.',
          );
        await q(
          `UPDATE dbo.NguoiDung SET KhoaDenNgay=DATEADD(${datePart},@duration,SYSUTCDATETIME()),PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id`,
          { id: uid, duration: b.duration },
          t,
        );
        await audit(
          t,
          req.user,
          'TemporaryLockUser',
          'NguoiDung',
          uid,
          `${b.duration} ${b.unit}: ${b.reason}`,
        );
        return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, { id: uid }, t);
      },
    );
    ok(res, profile(locked));
  }),
);
authRouter.post(
  '/users/:id/unlock',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const uid = id(req.params.id),
      b = z.strictObject({ ...otpFields }).parse(req.body);
    const unlocked = await withOtp(
      b,
      'admin-security',
      accountBinding(req.user),
      req.user,
      async (t) => {
        const current = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: uid }, t);
        if (!current) fail(404, 'NOT_FOUND', 'Không tìm thấy tài khoản.');
        await q(
          'UPDATE dbo.NguoiDung SET KhoaDenNgay=NULL,PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id',
          { id: uid },
          t,
        );
        await audit(t, req.user, 'UnlockUser', 'NguoiDung', uid);
        return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, { id: uid }, t);
      },
    );
    ok(res, profile(unlocked));
  }),
);
authRouter.post(
  '/users/me/password/otp',
  sendLimiter,
  wrap(async (req, res) => {
    const b = z.strictObject({ currentPassword: str(1, 200) }).parse(req.body);
    const u = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: req.user.id });
    if (
      Buffer.byteLength(b.currentPassword) > 72 ||
      !(await bcrypt.compare(b.currentPassword, u.passwordHash))
    )
      fail(422, 'WRONG_PASSWORD', 'Mật khẩu hiện tại không đúng.');
    const destination = u.email;
    if (!destination)
      fail(
        422,
        'EMAIL_REQUIRED',
        'Tài khoản chưa có email. Vui lòng cập nhật email trong hồ sơ trước.',
      );
    if (!otpEmailDeliverable(destination))
      fail(
        422,
        'OTP_EMAIL_UNDELIVERABLE',
        'Tài khoản demo .local không nhận OTP. Hãy dùng email thật.',
      );
    ok(res, await issueOtp({ purpose: 'change', destination, binding: accountBinding(u) }));
  }),
);
authRouter.get(
  '/auth/me',
  wrap(async (req, res) => ok(res, profile(req.user))),
);
authRouter.post(
  '/auth/logout',
  wrap(async (req, res) => {
    await transaction(req.user, (t) =>
      q(
        'UPDATE dbo.NguoiDung SET PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id',
        { id: req.user.id },
        t,
      ),
    );
    ok(res, { loggedOut: true });
  }),
);
authRouter.get(
  '/users/me',
  wrap(async (req, res) => ok(res, profile(req.user))),
);
authRouter.patch(
  '/users/me',
  wrap(async (req, res) => {
    const b = z
      .strictObject({
        fullName: str(2, 120),
        email,
        defaultAddress: str(0, 500).nullable().optional(),
        currentPassword: str(1, 200).optional(),
        expectedVersion: versionSchema,
      })
      .parse(req.body);
    const result = await transaction(req.user, async (t) => {
      const u = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: req.user.id }, t);
      checkVersion(u, b.expectedVersion);
      if (
        (b.email ?? null) !== (u.email ?? null) &&
        (!b.currentPassword ||
          Buffer.byteLength(b.currentPassword) > 72 ||
          !(await bcrypt.compare(b.currentPassword, u.passwordHash)))
      )
        fail(422, 'WRONG_PASSWORD', 'Nhập mật khẩu hiện tại để thay đổi email khôi phục.');
      await q(
        'UPDATE dbo.NguoiDung SET HoTen=@HoTen,Email=@Email,DiaChiMacDinh=@DiaChiMacDinh WHERE Id=@Id',
        { ...b, id: u.id },
        t,
      );
      return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, { id: u.id }, t);
    });
    ok(res, profile(result));
  }),
);
authRouter.post(
  '/users/me/password',
  limiter,
  wrap(async (req, res) => {
    const b = z
      .strictObject({ currentPassword: str(1, 200), newPassword: password, ...otpFields })
      .parse(req.body);
    const hash = await bcrypt.hash(b.newPassword, 12);
    await withOtp(b, 'change', accountBinding(req.user), req.user, async (t) => {
      const u = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: req.user.id }, t);
      if (accountBinding(u) !== accountBinding(req.user))
        fail(422, 'INVALID_OTP', 'Thông tin tài khoản đã thay đổi. Vui lòng yêu cầu mã mới.');
      if (
        Buffer.byteLength(b.currentPassword) > 72 ||
        !(await bcrypt.compare(b.currentPassword, u.passwordHash))
      )
        fail(422, 'WRONG_PASSWORD', 'Mật khẩu hiện tại không đúng.');
      await q(
        'UPDATE dbo.NguoiDung SET MatKhauBam=@hash,PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id',
        { hash, id: req.user.id },
        t,
      );
      await audit(t, req.user, 'ChangePassword', 'NguoiDung', req.user.id);
    });
    ok(res, { loginRequired: true });
  }),
);

authRouter.get(
  '/users',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const { page = 1, pageSize = 15, search, role, status } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let where = '1=1';
    const params = { offset, limit: Number(pageSize) };
    if (search) {
      where += ' AND (HoTen LIKE @search OR SoDienThoai LIKE @search OR Email LIKE @search)';
      params.search = `%${search}%`;
    }
    if (role) {
      where += ' AND VaiTro=@VaiTro';
      params.role = role;
    }
    if (status) {
      if (status === 'active') {
        where += ' AND DangHoatDong=1 AND (KhoaDenNgay IS NULL OR KhoaDenNgay<=SYSUTCDATETIME())';
      } else if (status === 'inactive') {
        where += ' AND (DangHoatDong=0 OR KhoaDenNgay>SYSUTCDATETIME())';
      }
    }
    const total = await one(`SELECT COUNT(*) n FROM dbo.NguoiDung WHERE ${where}`, params);
    const rows = await q(
      `SELECT ${userColumns}, (SELECT TOP 1 NhomTayNghe FROM dbo.KyThuatVien WHERE Id=dbo.NguoiDung.Id) NhomTayNghe FROM dbo.NguoiDung WHERE ${where} ORDER BY Id DESC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`,
      params,
    );
    ok(res, rows.map(profile), 200, {
      total: total.n,
      page: Number(page),
      pageSize: Number(pageSize),
    });
  }),
);
authRouter.post(
  '/users',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const b = z
      .strictObject({
        fullName: str(2, 120),
        phone,
        email,
        role: z.enum(['KH', 'KTV', 'DPV', 'CSKH', 'KT', 'ADMIN', 'GD']),
        initialPassword: password,
        technicianProfile: z
          .strictObject({ skillGroup: str(1, 60), serviceArea: str(1, 120) })
          .optional(),
      })
      .parse(req.body);
    if (b.role === 'KTV' && !b.technicianProfile)
      fail(422, 'PROFILE_REQUIRED', 'Cần chuyên môn và khu vực kỹ thuật viên.');
    const hash = await bcrypt.hash(b.initialPassword, 12);
    const u = await transaction(req.user, async (t) => {
      const u = await one(
        `INSERT
  dbo.NguoiDung (
    HoTen,
    SoDienThoai,
    Email,
    MatKhauBam,
    VaiTro
  ) OUTPUT INSERTED.Id
VALUES
  (@HoTen, @SoDienThoai, @Email, @hash, @VaiTro)`,
        { ...b, hash, technicianProfile: null },
        t,
      );
      if (b.role === 'KTV')
        await q(
          'INSERT dbo.KyThuatVien(Id,NhomTayNghe,KhuVucPhucVu) VALUES(@Id,@NhomTayNghe,@KhuVucPhucVu)',
          { id: u.id, ...b.technicianProfile },
          t,
        );
      await audit(t, req.user, 'CreateUser', 'NguoiDung', u.id);
      return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, u, t);
    });
    ok(res, profile(u), 201);
  }),
);
authRouter.patch(
  '/users/:id',
  roles('ADMIN'),
  wrap(async (req, res) => {
    const uid = id(req.params.id),
      b = z
        .strictObject({
          fullName: str(2, 120),
          role: z.enum(['KH', 'KTV', 'DPV', 'CSKH', 'KT', 'ADMIN', 'GD']),
          skillGroup: z.enum(['DienLanh', 'DienNuoc', 'DienGiaDung', 'VeSinh']),
          isActive: z.boolean(),
          expectedVersion: versionSchema,
        })
        .parse(req.body);
    const u = await transaction(req.user, async (t) => {
      const current = await one('SELECT * FROM dbo.NguoiDung WHERE Id=@Id', { id: uid }, t);
      checkVersion(current, b.expectedVersion);
      if (current.id === req.user.id && b.role !== current.role)
        fail(
          409,
          'CANNOT_CHANGE_OWN_ROLE',
          'Không thể tự thay đổi vai trò của tài khoản quản trị đang đăng nhập.',
        );
      if (
        (!b.isActive || b.role !== 'ADMIN') &&
        current.role === 'ADMIN' &&
        (
          await one(
            "SELECT COUNT(*) n FROM dbo.NguoiDung WHERE VaiTro='ADMIN' AND DangHoatDong=1 AND Id<>@Id",
            { id: uid },
            t,
          )
        ).n < 1
      )
        fail(
          409,
          'LAST_ADMIN',
          'Không thể vô hiệu hóa hoặc đổi vai trò quản trị viên hoạt động cuối cùng.',
        );
      if (
        current.role === 'KTV' &&
        b.role !== 'KTV' &&
        (await one(
          'SELECT Id FROM dbo.LenhDieuPhoi WHERE KyThuatVienId=@Id AND DangHoatDong=1',
          { id: uid },
          t,
        ))
      )
        fail(
          409,
          'ACTIVE_ASSIGNMENT',
          'Kỹ thuật viên đang có ca, cần hoàn tất hoặc điều phối lại.',
        );
      if (b.role === 'KTV') {
        const technician = await one('SELECT Id FROM dbo.KyThuatVien WHERE Id=@Id', { id: uid }, t);
        if (technician)
          await q(
            'UPDATE dbo.KyThuatVien SET NhomTayNghe=@NhomTayNghe WHERE Id=@Id',
            { id: uid, skillGroup: b.skillGroup },
            t,
          );
        else
          await q(
            "INSERT dbo.KyThuatVien(Id,NhomTayNghe,KhuVucPhucVu,TrangThaiSanSang) VALUES(@Id,@NhomTayNghe,N'TP.HCM','TamBan')",
            { id: uid, skillGroup: b.skillGroup },
            t,
          );
      } else if (current.role === 'KTV')
        await q(
          "UPDATE dbo.KyThuatVien SET TrangThaiSanSang='TamBan' WHERE Id=@Id",
          { id: uid },
          t,
        );
      await q(
        'UPDATE dbo.NguoiDung SET HoTen=@HoTen,VaiTro=@VaiTro,DangHoatDong=@DangHoatDong,PhienBanXacThuc=PhienBanXacThuc+1 WHERE Id=@Id',
        { ...b, id: uid },
        t,
      );
      await audit(t, req.user, 'UpdateUser', 'NguoiDung', uid, `${current.role} -> ${b.role}`);
      return one(`SELECT ${userColumns} FROM dbo.NguoiDung WHERE Id=@Id`, { id: uid }, t);
    });
    ok(res, profile(u));
  }),
);
