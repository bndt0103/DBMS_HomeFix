import { Router } from "express";
import bcrypt from "bcryptjs";
import { queryView, exec, first, queryFunction } from "./db.js";
import { ok, wrap, roles, write, positiveId, fail } from "./common.js";
export const adminRouter = Router();

adminRouter.get(
  "/users",
  roles("ADMIN"),
  wrap(async (_req, res) => ok(res, await queryView("vw_NguoiDung"))),
);
adminRouter.post(
  "/users",
  roles("ADMIN"),
  wrap(async (req, res) => {
    const password = String(req.body.MatKhau || "");
    if (password.length < 6 || Buffer.byteLength(password, "utf8") > 72)
      fail(400, "Mật khẩu từ 6 ký tự, không quá 72 byte.");
    ok(
      res,
      (
        await exec("sp_TaoTaiKhoanNoiBo", {
          ...req.body,
          NguoiThucHienId: req.user.Id,
          MatKhauBam: await bcrypt.hash(password, 10),
        })
      )[0],
    );
  }),
);
adminRouter.patch(
  "/users/:id/status",
  roles("ADMIN"),
  write("sp_KhoaMoKhoaTaiKhoan", (req) => ({
    NguoiDungId: positiveId(req.params.id),
  })),
);
adminRouter.patch(
  "/users/:id/role",
  roles("ADMIN"),
  write("sp_DoiVaiTroNguoiDung", (req) => ({
    NguoiDungId: positiveId(req.params.id),
  })),
);
adminRouter.post("/services", roles("ADMIN"), write("sp_LuuDichVu"));
adminRouter.post("/categories", roles("ADMIN"), write("sp_LuuDanhMucDichVu"));
adminRouter.get(
  "/settings",
  roles("ADMIN", "GD", "KT"),
  wrap(async (_req, res) =>
    ok(res, await queryView("vw_CauHinh", {}, { order: "Khoa" })),
  ),
);
adminRouter.put(
  "/settings/:key",
  roles("ADMIN"),
  write("sp_LuuCauHinh", (req) => ({ Khoa: req.params.key })),
);
adminRouter.get(
  "/technicians",
  roles("DPV", "ADMIN", "CSKH"),
  wrap(async (_req, res) => ok(res, await queryView("vw_KyThuatVien"))),
);
adminRouter.get(
  "/technician/me",
  roles("KTV"),
  wrap(async (req, res) =>
    ok(res, await first("vw_KyThuatVien", { Id: req.user.Id })),
  ),
);
adminRouter.patch("/technician/me", roles("KTV"), write("sp_CapNhatTho"));
adminRouter.patch(
  "/technician/status",
  roles("KTV"),
  write("sp_CapNhatTrangThaiKTV"),
);
adminRouter.get(
  "/technician-applications",
  roles("KH", "ADMIN"),
  wrap(async (req, res) =>
    ok(
      res,
      await queryView(
        "vw_HoSoKTV",
        req.user.VaiTro === "KH" ? { NguoiDungId: req.user.Id } : {},
      ),
    ),
  ),
);
adminRouter.post(
  "/technician-applications",
  roles("KH"),
  write("sp_GuiHoSoKTV"),
);
adminRouter.post(
  "/technician-applications/:id/decision",
  roles("ADMIN"),
  write("sp_DuyetHoSoKTV", (req) => ({ HoSoId: positiveId(req.params.id) })),
);
adminRouter.get(
  "/notifications",
  wrap(async (req, res) =>
    ok(res, await queryView("vw_ThongBao", { NguoiDungId: req.user.Id })),
  ),
);
adminRouter.post(
  "/notifications/:id/read",
  write("sp_DanhDauThongBao", (req) => ({
    ThongBaoId: positiveId(req.params.id),
  })),
);
adminRouter.get(
  "/reports",
  roles("GD", "ADMIN", "KT"),
  wrap(async (req, res) => {
    ok(res, {
      DoanhThu: await queryView("vw_DoanhThuNgay", {}, { order: "Ngay" }),
      HieuSuat:
        req.user.VaiTro === "KT"
          ? undefined
          : await queryView(
              "vw_HieuSuatKyThuatVien",
              {},
              { order: "KyThuatVienId" },
            ),
      ThongKe: await queryFunction("fn_ThongKeDon", {
        TuNgay: req.query.TuNgay || null,
        DenNgay: req.query.DenNgay || null,
      }),
      Vi: await queryView("vw_ViKyThuatVien"),
    });
  }),
);
