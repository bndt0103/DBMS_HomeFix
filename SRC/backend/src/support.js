import { Router } from "express";
import { queryView, first } from "./db.js";
import { ok, wrap, roles, write, positiveId, fail } from "./common.js";
export const supportRouter = Router();
supportRouter.get(
  "/support",
  roles("KH", "CSKH", "ADMIN"),
  wrap(async (req, res) =>
    ok(
      res,
      await queryView(
        "vw_YeuCauHoTro",
        req.user.VaiTro === "KH" ? { KhachHangId: req.user.Id } : {},
      ),
    ),
  ),
);
supportRouter.post("/support", roles("KH"), write("sp_TaoYeuCauHoTro"));
supportRouter.patch(
  "/support/:id",
  roles("CSKH"),
  write("sp_XuLyHoTro", (req) => ({
    YeuCauHoTroId: positiveId(req.params.id),
    YeuCauId: positiveId(req.params.id),
  })),
);
async function ticket(req) {
  const row = await first("vw_YeuCauHoTro", { Id: positiveId(req.params.id) });
  if (!row) fail(404, "Không có phiếu hỗ trợ.");
  if (req.user.VaiTro === "KH" && row.KhachHangId !== req.user.Id)
    fail(403, "Bạn không có quyền xem phiếu này.");
}
supportRouter.get(
  "/support/:id/messages",
  roles("KH", "CSKH", "ADMIN"),
  wrap(async (req, res) => {
    await ticket(req);
    ok(
      res,
      await queryView("vw_TraoDoiHoTro", {
        YeuCauHoTroId: positiveId(req.params.id),
      }),
    );
  }),
);
supportRouter.post(
  "/support/:id/messages",
  roles("KH", "CSKH"),
  write("sp_ThemTraoDoiHoTro", (req) => ({
    YeuCauHoTroId: positiveId(req.params.id),
    YeuCauId: positiveId(req.params.id),
  })),
);
