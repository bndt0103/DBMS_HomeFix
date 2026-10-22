import { exec, first } from "./db.js";

export const wrap = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);
export const ok = (res, data) => res.json({ ok: true, data });
export function fail(status, message, code = "INVALID_REQUEST") {
  throw Object.assign(new Error(message), { status, code });
}
export function roles(...allowed) {
  return (req, _res, next) =>
    allowed.includes(req.user?.VaiTro)
      ? next()
      : next(
          Object.assign(
            new Error("Bạn không có quyền thực hiện thao tác này."),
            { status: 403, code: "FORBIDDEN" },
          ),
        );
}
export function positiveId(value) {
  const id = Number(value);
  if (!Number.isSafeInteger(id) || id <= 0) fail(400, "Id không hợp lệ.");
  return id;
}
export async function orderFor(actor, id) {
  if (!["KH", "KTV", "DPV", "CSKH", "KT", "ADMIN"].includes(actor.VaiTro))
    fail(403, "Vai trò này không được truy cập đơn hàng.", "FORBIDDEN");
  const order = await first("vw_DonHangTongHop", { Id: positiveId(id) });
  if (!order) fail(404, "Không tìm thấy đơn hàng.", "ORDER_NOT_FOUND");
  if (
    (actor.VaiTro === "KH" && actor.Id !== order.KhachHangId) ||
    (actor.VaiTro === "KTV" && actor.Id !== order.KyThuatVienId)
  )
    fail(403, "Bạn không có quyền xem đơn này.", "FORBIDDEN");
  return order;
}
export function write(spName, extra = {}) {
  return wrap(async (req, res) => {
    const additions = typeof extra === "function" ? extra(req) : extra;
    const rows = await exec(spName, {
      ...req.body,
      ...additions,
      NguoiThucHienId: req.user.Id,
    });
    ok(res, rows.length === 1 ? rows[0] : rows);
  });
}
