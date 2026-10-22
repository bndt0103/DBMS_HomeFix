import { Router } from "express";
import { first, queryView } from "./db.js";
import { ok, wrap, roles, write, positiveId } from "./common.js";
export const financeRouter = Router();

financeRouter.get(
  "/bank-accounts",
  wrap(async (req, res) =>
    ok(
      res,
      await queryView(
        "vw_TaiKhoanNganHang",
        req.user.VaiTro === "ADMIN" && req.query.all === "1"
          ? {}
          : { DangHoatDong: true },
      ),
    ),
  ),
);
financeRouter.post(
  "/bank-accounts",
  roles("ADMIN"),
  write("sp_LuuTaiKhoanNganHang"),
);
financeRouter.post(
  "/orders/:id/payments/cod",
  roles("KTV"),
  write("sp_XacNhanThanhToanCOD", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
financeRouter.post(
  "/orders/:id/payments/bank",
  roles("KH"),
  write("sp_TaoYeuCauThanhToan", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
financeRouter.get(
  "/bank-requests",
  roles("KH", "KT"),
  wrap(async (req, res) =>
    ok(
      res,
      await queryView(
        "vw_YeuCauThanhToan",
        req.user.VaiTro === "KH" ? { KhachHangId: req.user.Id } : {},
      ),
    ),
  ),
);
financeRouter.post(
  "/bank-requests/:id/confirm",
  roles("KT"),
  write("sp_XacNhanThanhToanNganHang", (req) => ({
    YeuCauId: positiveId(req.params.id),
    YeuCauThanhToanId: positiveId(req.params.id),
  })),
);
financeRouter.get(
  "/wallet",
  roles("KTV"),
  wrap(async (req, res) =>
    ok(res, {
      KyThuatVien: await first("vw_KyThuatVien", { Id: req.user.Id }),
      GiaoDich: await queryView("vw_GiaoDichVi", {
        KyThuatVienId: req.user.Id,
      }),
      YeuCau: await queryView("vw_YeuCauVi", { KyThuatVienId: req.user.Id }),
    }),
  ),
);
financeRouter.post("/wallet/requests", roles("KTV"), write("sp_TaoYeuCauVi"));
financeRouter.get(
  "/wallet/requests",
  roles("KT"),
  wrap(async (_req, res) => ok(res, await queryView("vw_YeuCauVi"))),
);
financeRouter.post(
  "/wallet/requests/:id/decision",
  roles("KT"),
  write("sp_DuyetYeuCauVi", (req) => ({
    YeuCauId: positiveId(req.params.id),
    YeuCauViId: positiveId(req.params.id),
  })),
);
financeRouter.get(
  "/settlements",
  roles("KT", "KTV", "GD"),
  wrap(async (req, res) =>
    ok(
      res,
      await queryView(
        "vw_DoiSoat",
        req.user.VaiTro === "KTV" ? { KyThuatVienId: req.user.Id } : {},
      ),
    ),
  ),
);
financeRouter.post(
  "/settlements/:id/confirm",
  roles("KT"),
  write("sp_DoiSoatCOD", (req) => ({ DoiSoatId: positiveId(req.params.id) })),
);
