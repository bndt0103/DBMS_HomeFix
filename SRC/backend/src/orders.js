import { Router } from "express";
import { exec, queryView, first } from "./db.js";
import { ok, wrap, roles, write, orderFor, positiveId } from "./common.js";

export const ordersRouter = Router();
ordersRouter.get(
  "/orders",
  roles("KH", "KTV", "DPV", "CSKH", "KT", "ADMIN"),
  wrap(async (req, res) => {
    const filter = {};
    if (req.user.VaiTro === "KH") filter.KhachHangId = req.user.Id;
    if (req.user.VaiTro === "KTV") filter.KyThuatVienId = req.user.Id;
    if (req.query.TrangThai) filter.TrangThai = String(req.query.TrangThai);
    ok(res, await queryView("vw_DonHangTongHop", filter));
  }),
);
ordersRouter.post("/orders", roles("KH"), write("sp_TaoDonHang"));
ordersRouter.get(
  "/orders/:id",
  roles("KH", "KTV", "DPV", "CSKH", "KT", "ADMIN"),
  wrap(async (req, res) => {
    const DonHang = await orderFor(req.user, req.params.id);
    const id = DonHang.Id;
    const BangKeVatTu = await queryView("vw_BangKeVatTu", { DonHangId: id });
    const ChiTietVatTu = [];
    for (const item of BangKeVatTu)
      ChiTietVatTu.push(
        ...(await queryView("vw_ChiTietVatTu", {
          BangKeVatTuId: item.Id,
        })),
      );
    const GhiChu = await queryView(
      "vw_GhiChuDon",
      req.user.VaiTro === "KH"
        ? { DonHangId: id, NoiBo: false }
        : { DonHangId: id },
    );
    ok(res, {
      DonHang,
      BangKeVatTu,
      ChiTietVatTu,
      GhiChu,
      BaoGiaSoBo: await queryView("vw_BaoGiaSoBo", { DonHangId: id }),
      LenhDieuPhoi: await queryView("vw_LenhDieuPhoi", { DonHangId: id }),
      NghiemThu: await queryView("vw_PhieuNghiemThu", { DonHangId: id }),
      ThanhToan: await queryView("vw_ThanhToan", { DonHangId: id }),
      LichSu: await queryView("vw_LichSuDonHang", { DonHangId: id }),
      TepDinhKem: await queryView("vw_TepDinhKem", { DonHangId: id }),
    });
  }),
);
ordersRouter.patch(
  "/orders/:id/status",
  roles("KH", "KTV", "DPV"),
  write("sp_ChuyenTrangThaiDon", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/orders/:id/assign",
  roles("DPV"),
  write("sp_TaoLenhDieuPhoi", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/assignments/:id/respond",
  roles("KTV"),
  write("sp_KTVPhanHoiDieuPhoi", (req) => ({
    LenhDieuPhoiId: positiveId(req.params.id),
    LenhId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/orders/:id/quote",
  roles("DPV"),
  write("sp_TaoBaoGiaSoBo", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/quotes/:id/decision",
  roles("KH"),
  write("sp_KhachDuyetBaoGiaSoBo", (req) => ({
    BaoGiaId: positiveId(req.params.id),
    BaoGiaSoBoId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/orders/:id/materials",
  roles("KTV"),
  write("sp_LuuBangKeVatTu", (req) => ({
    DonHangId: positiveId(req.params.id),
    VatTu: JSON.stringify(req.body.VatTu || []),
  })),
);
ordersRouter.post(
  "/orders/:id/acceptance",
  roles("KTV"),
  write("sp_TaoPhieuNghiemThu", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/acceptances/:id/technician-sign",
  roles("KTV"),
  write("sp_KTVKyNghiemThu", (req) => ({
    NghiemThuId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/acceptances/:id/customer-sign",
  roles("KH"),
  write("sp_KhachHangKyNghiemThu", (req) => ({
    NghiemThuId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/orders/:id/notes",
  roles("KH", "KTV", "DPV", "CSKH"),
  write("sp_ThemGhiChuDon", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
ordersRouter.post(
  "/orders/:id/review",
  roles("KH"),
  write("sp_TaoDanhGiaDonHang", (req) => ({
    DonHangId: positiveId(req.params.id),
  })),
);
