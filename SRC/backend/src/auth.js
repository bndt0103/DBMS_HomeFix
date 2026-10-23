import { createHash } from "node:crypto";
import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { exec, first, withDatabaseRole } from "./db.js";
import { shape } from "./web-shape.js";
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
const credentialFingerprint = (hash) =>
  createHash("sha256").update(hash).digest("hex");
const publicUser = ({ MatKhauBam, ...user }) => user;
const internal = (callback) => withDatabaseRole(null, callback);

authRouter.post(
  "/login",
  wrap(async (req, res) => {
    const identifier = String(
      req.body.SoDienThoai || req.body.identifier || "",
    );
    const user = await internal(() =>
      first(
        "vw_XacThucDangNhap",
        identifier.includes("@")
          ? { Email: identifier }
          : { SoDienThoai: identifier },
      ),
    );
    if (
      !user?.DangHoatDong ||
      !(await bcrypt.compare(
        String(req.body.MatKhau || req.body.password || ""),
        user.MatKhauBam,
      ))
    )
      fail(
        401,
        "Số điện thoại hoặc mật khẩu không đúng.",
        "INVALID_CREDENTIALS",
      );
    const token = jwt.sign(
      {
        sub: String(user.Id),
        VaiTro: user.VaiTro,
        credential: credentialFingerprint(user.MatKhauBam),
      },
      config.jwtSecret,
      { expiresIn: "8h", issuer: "homefix-dbms" },
    );
    ok(res, {
      token,
      accessToken: token,
      user: { ...publicUser(user), ...shape(publicUser(user)) },
    });
  }),
);

authRouter.post(
  "/register",
  wrap(async (req, res) => {
    const MatKhauBam = await passwordHash(
      req.body.MatKhau || req.body.password,
    );
    const rows = await internal(() =>
      exec("sp_DangKyKhachHang", {
        HoTen: req.body.HoTen || req.body.fullName,
        SoDienThoai: req.body.SoDienThoai || req.body.phone,
        Email: req.body.Email || req.body.email || null,
        MatKhauBam,
      }),
    );
    ok(res, rows[0]);
  }),
);

authRouter.post("/logout", (_req, res) => ok(res, { loggedOut: true }));
export const webPasswordChange = wrap(async (req, res) => {
  const user = await internal(() =>
    first("vw_XacThucDangNhap", { Id: req.user.Id }),
  );
  if (
    !(await bcrypt.compare(
      String(req.body.currentPassword || ""),
      user.MatKhauBam,
    ))
  )
    fail(400, "Mật khẩu hiện tại không đúng.");
  const hash = await passwordHash(req.body.newPassword);
  await exec("sp_DoiMatKhau", {
    NguoiThucHienId: req.user.Id,
    MatKhauBam: hash,
  });
  ok(res, { updated: true });
});

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
  const credentials = await first("vw_XacThucDangNhap", { Id: user.Id });
  if (
    payload.credential !== credentialFingerprint(credentials?.MatKhauBam || "")
  )
    fail(
      401,
      "Mật khẩu đã thay đổi. Vui lòng đăng nhập lại.",
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
