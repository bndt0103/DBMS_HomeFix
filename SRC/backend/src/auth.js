import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { createHash, randomInt, randomUUID } from "node:crypto";
import nodemailer from "nodemailer";
import { exec, first, withDatabaseRole } from "./db.js";
import { config } from "./config.js";
import { ok, fail, wrap } from "./common.js";

export const authRouter = Router();
export const profileRouter = Router();
const passwordHash = async (value) => {
  if (
    typeof value !== "string" ||
    value.length < 6 ||
    Buffer.byteLength(value, "utf8") > 72
  )
    fail(400, "Mật khẩu từ 6 ký tự và không quá 72 byte.");
  return bcrypt.hash(value, 10);
};
const otpHash = (id, code) =>
  createHash("sha256")
    .update(id + ":" + String(code) + ":" + config.jwtSecret)
    .digest("hex");
const publicUser = ({ MatKhauBam, ...user }) => user;
const internal = (callback) => withDatabaseRole(null, callback);

authRouter.post(
  "/login",
  wrap(async (req, res) => {
    const user = await internal(() =>
      first("vw_XacThucDangNhap", {
        SoDienThoai: String(req.body.SoDienThoai || ""),
      }),
    );
    if (
      !user?.DangHoatDong ||
      !(await bcrypt.compare(String(req.body.MatKhau || ""), user.MatKhauBam))
    )
      fail(
        401,
        "Số điện thoại hoặc mật khẩu không đúng.",
        "INVALID_CREDENTIALS",
      );
    const token = jwt.sign(
      { sub: String(user.Id), VaiTro: user.VaiTro },
      config.jwtSecret,
      { expiresIn: "8h", issuer: "homefix-dbms" },
    );
    ok(res, { token, user: publicUser(user) });
  }),
);

authRouter.post(
  "/register",
  wrap(async (req, res) => {
    const MatKhauBam = await passwordHash(req.body.MatKhau);
    const rows = await internal(() =>
      exec("sp_DangKyKhachHang", { ...req.body, MatKhauBam }),
    );
    ok(res, rows[0]);
  }),
);

authRouter.post(
  "/otp",
  wrap(async (req, res) => {
    const { DiaChiNhan, MucDich } = req.body;
    if (
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(DiaChiNhan || "") ||
      !["ResetPassword", "Register"].includes(MucDich)
    )
      fail(400, "Email hoặc mục đích OTP không hợp lệ.");
    const Id = randomUUID();
    const code = String(randomInt(100000, 1000000));
    const NgayHetHan = new Date(Date.now() + 5 * 60000);
    await internal(() =>
      exec("sp_TaoMaOTP", {
        Id,
        MucDich,
        DiaChiNhan,
        MaBam: otpHash(Id, code),
        NgayHetHan,
      }),
    );
    if (process.env.SMTP_HOST) {
      const mail = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT || 587),
        secure: process.env.SMTP_SECURE === "true",
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD },
      });
      await mail.sendMail({
        from: process.env.SMTP_FROM,
        to: DiaChiNhan,
        subject: "HomeFix: mã xác thực",
        text: `Mã xác thực: ${code}. Hết hạn sau 5 phút.`,
      });
    } else if (process.env.OTP_PROVIDER === "console") {
      console.log(
        "OTP phát triển (không dùng trên máy chủ công khai):",
        Id,
        code,
      );
    } else {
      fail(
        503,
        "Chưa cấu hình nhà cung cấp email OTP.",
        "OTP_DELIVERY_UNAVAILABLE",
      );
    }
    ok(res, { Id, NgayHetHan });
  }),
);

authRouter.post(
  "/reset-password",
  wrap(async (req, res) => {
    const MatKhauBam = await passwordHash(req.body.MatKhauMoi);
    const outcome = await internal(async () => {
      const challenge = await first("vw_XacThucOTP", { Id: req.body.Id });
      if (!challenge || challenge.MucDich !== "ResetPassword")
        fail(400, "Yêu cầu xác thực không hợp lệ.");
      const result = await exec("sp_XacThucOTP", {
        Id: req.body.Id,
        MaBam: otpHash(req.body.Id, req.body.MaOTP),
      });
      if (!result[0]?.DaXacThuc)
        fail(400, "Mã OTP không đúng, hết hạn hoặc đã dùng.", "INVALID_OTP");
      const user = await first("vw_NguoiDung", { Email: challenge.DiaChiNhan });
      if (!user) fail(400, "Không có tài khoản phù hợp.");
      return exec("sp_DoiMatKhau", { NguoiThucHienId: user.Id, MatKhauBam });
    });
    ok(res, outcome[0] || { DaCapNhat: true });
  }),
);

export async function loadActor(req) {
  const token = /^Bearer\s+(.+)$/i.exec(req.headers.authorization || "")?.[1];
  if (!token) fail(401, "Bạn cần đăng nhập.", "UNAUTHENTICATED");
  let payload;
  try {
    payload = jwt.verify(token, config.jwtSecret, { issuer: "homefix-dbms" });
  } catch {
    fail(401, "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.", "INVALID_TOKEN");
  }
  const user = await first("vw_NguoiDung", { Id: Number(payload.sub) });
  if (!user?.DangHoatDong || user.VaiTro !== payload.VaiTro)
    fail(
      401,
      "Tài khoản bị khóa hoặc vai trò đã thay đổi. Vui lòng đăng nhập lại.",
      "SESSION_REVOKED",
    );
  return user;
}
export const authenticate = wrap(async (req, _res, next) => {
  req.user = await loadActor(req);
  next();
});

profileRouter.get("/me", (req, res) => ok(res, req.user));
profileRouter.patch(
  "/profile",
  wrap(async (req, res) =>
    ok(
      res,
      (
        await exec("sp_CapNhatThongTinNguoiDung", {
          ...req.body,
          NguoiThucHienId: req.user.Id,
        })
      )[0],
    ),
  ),
);
profileRouter.post(
  "/password",
  wrap(async (req, res) => {
    const user = await internal(() =>
      first("vw_XacThucDangNhap", { Id: req.user.Id }),
    );
    if (
      !(await bcrypt.compare(String(req.body.MatKhauCu || ""), user.MatKhauBam))
    )
      fail(400, "Mật khẩu hiện tại không đúng.");
    ok(
      res,
      await exec("sp_DoiMatKhau", {
        NguoiThucHienId: req.user.Id,
        MatKhauBam: await passwordHash(req.body.MatKhauMoi),
      }),
    );
  }),
);
