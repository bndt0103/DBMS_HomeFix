import { Router } from "express";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";
import {
  queryView,
  queryFunction,
  first,
  exec,
  withDatabaseRole,
} from "./db.js";
import { ok, wrap, roles, fail, positiveId, orderFor } from "./common.js";
import { shape, sum } from "./web-shape.js";
import { webPasswordChange } from "./auth.js";
import { webReports } from "./web-reports.js";

// API cho giao diện web; thủ tục SQL kiểm tra quyền và nghiệp vụ.
export const webRouter = Router();
const read = async (view, filter = {}, options = {}) =>
  shape(await queryView(view, filter, { all: true, ...options }));
const one = async (view, filter = {}) => shape(await first(view, filter));
const actor = (req) => ({
  NguoiThucHienId: req.user.Id,
  PhienBanDuKien: req.body.expectedVersion,
});
const run = async (req, name, params) =>
  shape(await exec(name, { ...params, ...actor(req) }));
const submitPolicyProposal = async (req, proposal) => {
  const { policyKey, ...content } = proposal;
  // Mỗi lần gửi luôn là một đề xuất mới. Thủ tục SQL xóa đề xuất đang chờ
  // cùng policyKey trong một giao dịch trước khi lưu bản mới này.
  const id = randomUUID();
  await run(req, "sp_LuuCauHinh", {
    Khoa: "DeXuatChinhSach_" + id,
    GiaTri: JSON.stringify({
      status: "Pending",
      proposalCode: "CS-" + id.slice(0, 8).toUpperCase(),
      department: "Quản trị",
      submittedAt: new Date().toISOString(),
      policySubject: policyKey,
      ...content,
    }),
    NhanHienThi: "Đề xuất chính sách chờ duyệt",
  });
  return { id, status: "Pending" };
};
const get = (path, allowed, fn) =>
  webRouter.get(
    path,
    roles(...allowed),
    wrap(async (req, res) => ok(res, await fn(req))),
  );
const change = (method, path, allowed, fn) =>
  webRouter[method](
    path,
    roles(...allowed),
    wrap(async (req, res) => {
      const result = await fn(req);
      ok(
        res,
        Array.isArray(result) && result.length === 1 ? result[0] : result,
      );
    }),
  );
webRouter.post("/users/me/password", webPasswordChange);
const all = ["KH", "KTV", "DPV", "CSKH", "KT", "GD", "ADMIN"];
const operators = ["KH", "KTV", "DPV", "CSKH", "KT", "ADMIN"];
const finance = ["KT", "GD", "ADMIN"];
const inPeriod = (rows, req, key = "createdAt") =>
  rows.filter(
    (row) =>
      (!req.query.from || new Date(row[key]) >= new Date(req.query.from)) &&
      (!req.query.to || new Date(row[key]) < new Date(req.query.to)),
  );

async function orderRows(req) {
  const filters =
    req.user.VaiTro === "KH"
      ? { KhachHangId: req.user.Id }
      : req.user.VaiTro === "KTV"
        ? { KyThuatVienId: req.user.Id }
        : {};
  if (req.query.status) filters.TrangThai = req.query.status;
  const orders = await read("vw_DonHangTongHop", filters);
  // Chứng từ không được suy đoán từ trạng thái đơn.
  const payments = await read("vw_ThanhToan");
  const acceptance = await read("vw_PhieuNghiemThu");
  return inPeriod(orders, req).map((o) => {
    const paid = payments.find((p) => p.orderId === o.id),
      a = acceptance.find((a) => a.orderId === o.id && a.status !== "Rejected");
    return {
      ...o,
      paymentStatus: paid ? "Paid" : "Unpaid",
      paymentMethod:
        paid?.method ||
        (o.status === "Huy" && o.cancellationFee > 0
          ? "BANK"
          : a?.paymentMethod || "COD"),
      inspectionFee: a?.inspectionFee || 0,
      laborFee: a?.laborFee || 0,
      materialTotal: a?.materialTotal || 0,
      paidAt: paid?.createdAt,
      warrantyUntil: o.HanBaoHanh,
      contactName: o.customerName,
      contactPhone: o.customerPhone,
    };
  });
}
function paginate(req, res, rows) {
  const normalize = (value) =>
    String(value ?? "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[đĐ]/g, "d")
      .toLowerCase();
  const words = normalize(req.query.search).trim().split(/\s+/).filter(Boolean);
  const fields = [
    "id",
    "fullName",
    "phone",
    "email",
    "role",
    "customerName",
    "customerPhone",
    "serviceName",
    "technicianName",
    "address",
    "description",
    "skillGroup",
  ];
  rows = rows.filter((row) => {
    const roles = {
      KH: "Khách hàng",
      KTV: "Kỹ thuật viên",
      DPV: "Điều phối viên",
      CSKH: "Chăm sóc khách hàng",
      KT: "Kế toán",
      GD: "Giám đốc",
      ADMIN: "Quản trị viên",
    };
    const text = normalize(
      [
        roles[row.role],
        ...fields.map((key) => row[key]),
        "HF-" + String(row.id).padStart(6, "0"),
      ].join(" "),
    );
    return (
      words.every((word) => text.includes(word)) &&
      (!req.query.role || row.role === req.query.role) &&
      (!req.query.serviceGroup || row.groupCode === req.query.serviceGroup) &&
      (!req.query.status ||
        (["active", "inactive"].includes(req.query.status)
          ? !!row.isActive === (req.query.status === "active")
          : row.status === req.query.status))
    );
  });
  const size = Math.min(200, Math.max(1, Number(req.query.pageSize) || 50)),
    page = Math.max(1, Number(req.query.page) || 1);
  res.json({
    ok: true,
    data: rows.slice((page - 1) * size, page * size),
    meta: { total: rows.length, page, pageSize: size },
  });
}
get("/services", all, () => read("vw_DichVuCongKhai"));
get("/admin/services", ["ADMIN"], async () => {
  const categories = await read("vw_DanhMucDichVu");
  return (await read("vw_DichVu")).map((s) => ({
    ...s,
    groupCode: categories.find((c) => c.id === s.DanhMucId)?.Ma,
  }));
});
get("/app-config", all, async () => {
  const rows = await read("vw_CauHinh", {}, { order: "Khoa" });
  const values = Object.fromEntries(
    rows
      .filter((r) =>
        [
          "TyLeHoaHongMacDinh",
          "TenHeThong",
          "SoDienThoaiHoTro",
          "PhiHuyDon",
        ].includes(r.key),
      )
      .map((r) => [r.key, r.value]),
  );
  return {
    ...values,
    signatureRequired: true,
    cancellationFee: Number(values.PhiHuyDon || 60000),
    commissionRatePercent: Number(values.TyLeHoaHongMacDinh || 15),
  };
});
webRouter.get(
  "/users",
  roles("ADMIN"),
  wrap(async (req, res) => {
    const [users, technicians] = await Promise.all([
      read("vw_NguoiDung"),
      read("vw_KyThuatVien"),
    ]);
    const skillByUserId = new Map(
      technicians.map((technician) => [
        technician.id,
        technician.skillGroup,
      ]),
    );
    paginate(
      req,
      res,
      users.map((user) => ({
        ...user,
        skillGroup:
          user.role === "KTV" ? skillByUserId.get(user.id) || null : null,
      })),
    );
  }),
);
get("/users/me", all, async (req) => {
  const user = await one("vw_NguoiDung", { Id: req.user.Id });
  if (user.role !== "KTV") return user;
  const technician = await one("vw_KyThuatVien", { Id: req.user.Id });
  return { ...user, skillGroup: technician?.skillGroup || null };
});
change("patch", "/users/me", all, async (req) => {
  if ((req.body.email || null) !== (req.user.Email || null)) {
    const current = await withDatabaseRole(null, () =>
      first("vw_XacThucDangNhap", { Id: req.user.Id }),
    );
    if (
      !(await bcrypt.compare(
        String(req.body.currentPassword || ""),
        current.MatKhauBam,
      ))
    )
      fail(400, "Mật khẩu hiện tại không đúng.");
  }
  return run(req, "sp_CapNhatThongTinNguoiDung", {
    HoTen: req.body.fullName,
    Email: req.body.email,
    DiaChi: req.body.defaultAddress,
  });
});
change("post", "/users", ["ADMIN"], async (req) => {
  const password = String(req.body.initialPassword || "");
  if (password.length < 6 || Buffer.byteLength(password) > 72)
    fail(400, "Mật khẩu từ 6 ký tự, không quá 72 byte.");
  return run(req, "sp_TaoTaiKhoanNoiBo", {
    HoTen: req.body.fullName,
    SoDienThoai: req.body.phone,
    MatKhauBam: await bcrypt.hash(password, 10),
    VaiTro: req.body.role,
  });
});
change("patch", "/users/:id/status", ["ADMIN"], (req) =>
  run(req, "sp_KhoaMoKhoaTaiKhoan", {
    NguoiDungId: positiveId(req.params.id),
    DangHoatDong: req.body.isActive,
  }),
);
change("patch", "/users/:id/role", ["ADMIN"], (req) =>
  run(req, "sp_DoiVaiTroNguoiDung", {
    NguoiDungId: positiveId(req.params.id),
    VaiTro: req.body.role,
  }),
);
change("patch", "/users/:id", ["ADMIN"], (req) =>
  run(req, "sp_AdminCapNhatTaiKhoan", {
    NguoiDungId: positiveId(req.params.id),
    HoTen: req.body.fullName,
    SoDienThoai: req.body.phone,
    Email: req.body.email || null,
    VaiTro: req.body.role,
    NhomTayNghe: req.body.skillGroup || null,
    DangHoatDong: req.body.isActive,
  }),
);
for (const method of ["post", "patch"])
  change(
    method,
    method === "post" ? "/services" : "/services/:id",
    ["ADMIN"],
    async (req) => {
      const category = await first("vw_DanhMucDichVu", {
        Ma: req.body.groupCode,
      });
      if (!category) fail(400, "Nhóm dịch vụ không hợp lệ.");
      const id = req.params.id ? positiveId(req.params.id) : null;
      const current = id ? await first("vw_DichVu", { Id: id }) : null;
      if (id && !current) fail(404, "Không tìm thấy dịch vụ.");
      const proposed = {
        inspectionFee: Number(req.body.inspectionFee),
        laborFee: Number(req.body.laborFee),
        commissionRatePercent: Number(req.body.commissionRatePercent),
      };
      const changes = current && [
        ["Phí kiểm tra", current.PhiKiemTra, proposed.inspectionFee],
        ["Tiền công", current.TienCong, proposed.laborFee],
        ["Tỷ lệ hoa hồng (%)", current.TyLeHoaHong, proposed.commissionRatePercent],
      ].filter(([, before, after]) => Number(before) !== Number(after));
      if (changes?.length)
        return submitPolicyProposal(req, {
          policyKey: "DichVu_" + id,
          title: "Điều chỉnh giá và hoa hồng dịch vụ: " + current.Ten,
          impact: "Chỉ áp dụng cho các báo giá tạo sau khi Giám đốc phê duyệt.",
          reason: "Admin đề xuất điều chỉnh biểu giá dịch vụ.",
          changes: changes.map(([label, current, proposed]) => ({
            label,
            current,
            proposed,
          })),
          payload: {
            type: "ServicePricing",
            serviceId: id,
            expectedVersion: current.PhienBan,
            currentInspectionFee: Number(current.PhiKiemTra),
            currentLaborFee: Number(current.TienCong),
            currentCommissionRatePercent: Number(current.TyLeHoaHong),
            ...proposed,
          },
        });
      return run(req, "sp_LuuDichVu", {
        Id: id,
        DanhMucId: category.Id,
        Ten: req.body.name,
        MoTa: req.body.description,
        PhiKiemTra: req.body.inspectionFee,
        TienCong: req.body.laborFee,
        TyLeHoaHong: req.body.commissionRatePercent,
        DangHoatDong: req.body.isActive,
      });
    },
  );
get("/settings", ["ADMIN"], async () =>
  (await read("vw_CauHinh", {}, { order: "Khoa" })).filter(
    (r) => !/^(GiamSat_|DeXuatChinhSach_|DuLieuMinhHoa)/.test(r.key),
  ),
);
change("patch", "/settings/:key", ["ADMIN"], async (req) => {
  const existing = await first(
    "vw_CauHinh",
    { Khoa: req.params.key },
    { order: "Khoa" },
  );
  if (
    ["TyLeHoaHongMacDinh", "PhiHuyDon"].includes(req.params.key) &&
    existing &&
    String(existing.GiaTri) !== String(req.body.value)
  )
    return submitPolicyProposal(req, {
      policyKey: "CauHinh_" + req.params.key,
      title: "Điều chỉnh chính sách: " + existing.NhanHienThi,
      impact: "Chỉ áp dụng sau khi Giám đốc phê duyệt.",
      reason: "Admin đề xuất điều chỉnh cấu hình chính sách.",
      changes: [
        {
          label: existing.NhanHienThi,
          current: existing.GiaTri,
          proposed: String(req.body.value),
        },
      ],
      payload: {
        type: "Configuration",
        key: req.params.key,
        currentValue: existing.GiaTri,
        value: String(req.body.value),
      },
    });
  return run(req, "sp_LuuCauHinh", {
    Khoa: req.params.key,
    GiaTri: String(req.body.value),
    NhanHienThi: existing?.NhanHienThi || req.params.key,
  });
});
get("/audit-logs", ["ADMIN"], () => read("vw_NhatKy"));

webRouter.get(
  "/orders",
  roles(...operators),
  wrap(async (req, res) => paginate(req, res, await orderRows(req))),
);
async function details(req) {
  const raw = await orderFor(req.user, req.params.id),
    o = shape(raw),
    filter = { DonHangId: raw.Id };
  const [quotes, assignments, acceptances, payments, service, history] =
    await Promise.all([
      read("vw_BaoGiaSoBo", filter),
      read("vw_LenhDieuPhoi", filter),
      read("vw_PhieuNghiemThu", filter),
      read("vw_ThanhToan", filter),
      one("vw_DichVu", { Id: raw.DichVuId }),
      read("vw_LichSuDonHang", filter),
    ]);
  const a = acceptances.find((a) => a.status !== "Rejected"),
    q = quotes.find((q) => q.status === "Approved") || quotes[0];
  let preliminary = quotes[0] || null;
  if (preliminary && preliminary.status === "Rejected") {
    const rejection = history
      .filter((h) => h.fromStatus === "ChoDuyetSoBo")
      .sort((h1, h2) => new Date(h2.createdAt) - new Date(h1.createdAt))[0];
    if (rejection?.reason) {
      preliminary = { ...preliminary, reason: rejection.reason.trim() };
    }
  }
  let cancelReason = null;
  if (o.status === "Huy") {
    const cancelLog = history
      .filter((h) => h.toStatus === "Huy")
      .sort((h1, h2) => new Date(h2.createdAt) - new Date(h1.createdAt))[0];
    if (cancelLog?.reason) cancelReason = cancelLog.reason.trim();
  }
  return {
    ...o,
    cancelReason,
    currentAcceptance: a,
    contactName: o.customerName,
    contactPhone: o.customerPhone,
    currentPreliminaryQuote: preliminary,
    currentAssignment: assignments[0] || null,
    paymentStatus: payments.length ? "Paid" : "Unpaid",
    paymentMethod:
      payments[0]?.method ||
      (o.status === "Huy" && o.cancellationFee > 0
        ? "BANK"
        : a?.paymentMethod || "COD"),
    inspectionFee:
      a?.inspectionFee ?? q?.inspectionFee ?? service?.inspectionFee ?? 0,
    laborFee: a?.laborFee ?? q?.laborFee ?? service?.laborFee ?? 0,
    materialTotal: a?.materialTotal || 0,
    commissionRatePercent: q?.commissionRatePercent || 0,
    total:
      o.status === "Huy"
        ? o.cancellationFee
        : (a?.total ?? q?.total ?? o.total),
    warrantyUntil: o.HanBaoHanh,
  };
}
get("/orders/:id", operators, details);
for (const [suffix, view] of [
  ["history", "vw_LichSuDonHang"],
  ["attachments", "vw_TepDinhKem"],
  ["reviews", "vw_DanhGia"],
  ["acceptances", "vw_PhieuNghiemThu"],
]) {
  get("/orders/:id/" + suffix, operators, async (req) => {
    await orderFor(req.user, req.params.id);
    const rows = await read(view, { DonHangId: positiveId(req.params.id) });
    if (suffix === "history")
      return rows.map((r) => ({
        ...r,
        actorName: "#" + r.actorId,
        note: r.reason,
      }));
    if (suffix === "acceptances") {
      const files = await read("vw_TepDinhKem", {
        DonHangId: positiveId(req.params.id),
      });
      return rows.map((r) => ({
        ...r,
        revision: rows.length - rows.indexOf(r),
        proposedPaymentMethod: r.paymentMethod || "COD",
        photos: files.filter((f) => f.purpose === "AcceptancePhoto"),
        photoIds: files
          .filter((f) => f.purpose === "AcceptancePhoto")
          .map((f) => f.id),
      }));
    }
    return rows;
  });
}
get("/orders/:id/materials", operators, async (req) => {
  await orderFor(req.user, req.params.id);
  const rows = await read("vw_BangKeVatTu", {
    DonHangId: positiveId(req.params.id),
  });
  for (const row of rows) {
    row.items = await read("vw_ChiTietVatTu", { BangKeVatTuId: row.id });
    row.total = sum(row.items, "lineTotal");
  }
  return rows;
});
get("/orders/:id/notes", operators, async (req) => {
  await orderFor(req.user, req.params.id);
  return (
    await read("vw_GhiChuDon", {
      DonHangId: positiveId(req.params.id),
      ...(req.user.VaiTro === "KH" ? { NoiBo: false } : {}),
    })
  ).map((r) => ({
    ...r,
    visibility: r.NoiBo ? "Internal" : "Public",
    authorName: "#" + r.authorId,
  }));
});
change("post", "/orders", ["KH"], (req) =>
  run(req, "sp_TaoDonHang", {
    DichVuId: req.body.serviceId,
    DiaChi: req.body.address,
    MoTa: req.body.description,
    NgayHen: req.body.scheduledAt,
    TepDinhKem: JSON.stringify(req.body.attachmentIds || []),
  }),
);
change("post", "/orders/:id/preliminary-quotes", ["DPV"], async (req) => {
  const order = await orderFor(req.user, req.params.id),
    service = await first("vw_DichVuCongKhai", { Id: order.DichVuId }),
    quote = await first("vw_BaoGiaSoBo", { DonHangId: order.Id });
  if (!service) fail(400, "Dịch vụ đang ngừng cung cấp.");
  return run(req, "sp_TaoBaoGiaSoBo", {
    DonHangId: order.Id,
    PhiKiemTra: req.body.inspectionFee ?? service.PhiKiemTra,
    TienCong: req.body.laborFee ?? service.TienCong,
    TyLeHoaHong: quote?.TyLeHoaHong ?? service.TyLeHoaHong,
    ChanDoan: req.body.diagnosis,
  });
});
change("post", "/orders/:id/assignments", ["DPV"], (req) =>
  run(req, "sp_TaoLenhDieuPhoi", {
    DonHangId: positiveId(req.params.id),
    KyThuatVienId: req.body.technicianId,
  }),
);
change("post", "/assignments/:id/decision", ["KTV"], (req) =>
  run(req, "sp_KTVPhanHoiDieuPhoi", {
    LenhDieuPhoiId: positiveId(req.params.id),
    QuyetDinh: req.body.decision,
    LyDo: req.body.reason,
  }),
);
change("patch", "/orders/:id/progress", ["KTV"], (req) =>
  run(req, "sp_ChuyenTrangThaiDon", {
    DonHangId: positiveId(req.params.id),
    TrangThaiTiepTheo: req.body.nextStatus,
  }),
);
change("post", "/orders/:id/cancel", ["KH", "DPV"], (req) =>
  run(req, "sp_ChuyenTrangThaiDon", {
    DonHangId: positiveId(req.params.id),
    TrangThaiTiepTheo: "Huy",
    LyDo: req.body.reason,
    DongYPhiHuy: req.body.acceptCancellationFee,
    PhiHuyDuKien: req.body.expectedCancellationFee,
  }),
);
change("post", "/orders/:id/notes", ["KH", "KTV", "DPV", "CSKH"], (req) =>
  run(req, "sp_ThemGhiChuDon", {
    DonHangId: positiveId(req.params.id),
    NoiDung: req.body.text,
    NoiBo: req.body.visibility === "Internal",
  }),
);
change("post", "/orders/:id/materials", ["KTV"], (req) =>
  run(req, "sp_LuuBangKeVatTu", {
    DonHangId: positiveId(req.params.id),
    VatTu: JSON.stringify(
      (req.body.items || []).map((i) => ({
        Ten: i.name,
        SoLuong: Number(i.quantity),
        DonGia:
          i.unitPrice === "" || i.unitPrice == null
            ? null
            : Number(i.unitPrice),
        SoThangBaoHanh: Number(i.warrantyMonths || 0),
      })),
    ),
  }),
);
change(
  "post",
  "/orders/:orderId/preliminary-quotes/:id/decision",
  ["KH"],
  (req) =>
    run(req, "sp_KhachDuyetBaoGiaSoBo", {
      BaoGiaId: positiveId(req.params.id),
      QuyetDinh: req.body.decision,
      LyDo: req.body.reason,
    }),
);
change("post", "/orders/:id/acceptances", ["KTV"], (req) => {
  if (!req.body.technicianSignatureId || !req.body.photoIds?.length)
    fail(400, "Cần chữ ký thợ và ảnh thành phẩm.");
  return run(req, "sp_TaoPhieuNghiemThu", {
    DonHangId: positiveId(req.params.id),
    NguyenNhan: req.body.cause,
    PhuongAnXuLy: req.body.solution,
    ChuKyKTVId: req.body.technicianSignatureId,
    AnhThanhPham: JSON.stringify(req.body.photoIds || []),
  });
});
change("post", "/orders/:orderId/acceptances/:id/decision", ["KH"], (req) =>
  run(
    req,
    req.body.decision === "Rejected"
      ? "sp_TuChoiNghiemThu"
      : "sp_KhachHangKyNghiemThu",
    {
      NghiemThuId: positiveId(req.params.id),
      ChuKyId: req.body.signatureId,
      PhuongThucThanhToan: req.body.paymentMethod,
      TaiKhoanNganHangId: req.body.bankAccountId,
      LyDo: req.body.reason,
    },
  ),
);
change("post", "/orders/:id/payments/cod", ["KTV"], (req) =>
  run(req, "sp_XacNhanThanhToanCOD", { DonHangId: positiveId(req.params.id) }),
);
change("post", "/orders/:id/reviews", ["KH"], (req) =>
  run(req, "sp_TaoDanhGiaDonHang", {
    DonHangId: positiveId(req.params.id),
    Diem: req.body.rating,
    NhanXet: req.body.comment,
  }),
);
get("/technicians/me", ["KTV"], async (req) => {
  const t = await one("vw_KyThuatVien", { Id: req.user.Id });
  const jobs = (
    await read("vw_DonHangTongHop", { KyThuatVienId: req.user.Id })
  ).filter((o) => !["HoanThanh", "Huy"].includes(o.status));
  const ratings = await read("vw_DanhGia", { KyThuatVienId: req.user.Id });
  return {
    ...t,
    walletEligibility: { minimum: 0 },
    activeAssignmentSummary: jobs.length
      ? jobs.length + " công việc đang giữ"
      : null,
    averageRating: ratings.length
      ? sum(ratings, "rating") / ratings.length
      : null,
  };
});
get("/technicians/available", ["DPV"], async (req) => {
  const order = await orderFor(req.user, req.query.orderId);
  return shape(
    await queryFunction("fn_KyThuatVienPhuHop", { DonHangId: order.Id }),
  ).map((technician) => ({ ...technician, canAssign: true }));
});
change("patch", "/technicians/me/availability", ["KTV"], async (req) =>
  run(req, "sp_CapNhatTrangThaiKTV", {
    TrangThaiSanSang: req.body.availability,
  }),
);
get("/technician-applications", ["ADMIN"], async () => {
  const users = await read("vw_NguoiDung");
  return (await read("vw_HoSoKTV")).map((a) => ({
    ...a,
    fullName: users.find((u) => u.id === a.NguoiDungId)?.fullName,
    phone: users.find((u) => u.id === a.NguoiDungId)?.phone,
  }));
});
get("/technician-applications/me", ["KH"], (req) =>
  read("vw_HoSoKTV", { NguoiDungId: req.user.Id }),
);
change("post", "/technician-applications", ["KH"], (req) =>
  run(req, "sp_GuiHoSoKTV", {
    NhomTayNghe: req.body.skillGroup,
    KhuVucPhucVu: req.body.serviceArea,
    KinhNghiem: req.body.experience,
    HoSoJSON: JSON.stringify({
      ...req.body.profile,
      identityNumber: req.body.identityNumber,
    }),
    GiayToMatTruocId: req.body.frontDocumentId,
    GiayToMatSauId: req.body.backDocumentId,
  }),
);
change("post", "/technician-applications/:id/decision", ["ADMIN"], (req) =>
  run(req, "sp_DuyetHoSoKTV", {
    HoSoId: positiveId(req.params.id),
    QuyetDinh: req.body.decision,
    LyDo: req.body.reason,
  }),
);

async function bankAccounts(req) {
  return read(
    "vw_TaiKhoanNganHang",
    req.user.VaiTro === "ADMIN" ? {} : { DangHoatDong: true },
  );
}
get("/bank-accounts", all, bankAccounts);
get("/payment-options", all, async (req) => ({
  accounts: await bankAccounts(req),
  banks: [
    { code: "VCB", name: "Vietcombank" },
    { code: "BIDV", name: "BIDV" },
    { code: "ICB", name: "VietinBank" },
    { code: "MB", name: "MB Bank" },
    { code: "ACB", name: "ACB" },
    { code: "TCB", name: "Techcombank" },
  ],
}));
for (const method of ["post", "patch"])
  change(
    method,
    method === "post" ? "/bank-accounts" : "/bank-accounts/:id",
    ["ADMIN"],
    async (req) => {
      const old = req.params.id
        ? await one("vw_TaiKhoanNganHang", { Id: positiveId(req.params.id) })
        : {};
      const b = { ...old, ...req.body };
      return run(req, "sp_LuuTaiKhoanNganHang", {
        Id: old.id,
        MaNganHang: b.bankCode,
        TenNganHang: b.bankName || b.bankCode,
        SoTaiKhoan: b.accountNumber,
        ChuTaiKhoan: b.accountHolder,
        DangHoatDong: b.isActive ?? true,
      });
    },
  );
get("/orders/:id/payment-details", operators, async (req) => {
  const o = await details(req),
    f = { DonHangId: positiveId(req.params.id) };
  const banks = await read("vw_TaiKhoanNganHang");
  const requests = (await read("vw_YeuCauThanhToan", f)).map((r) => ({
    ...r,
    ...bankFor(r, banks),
    status: r.status === "Pending" ? "PendingReview" : r.status,
    isActive: ["Pending", "Rejected"].includes(r.status),
  }));
  const receipts = await read("vw_ThanhToan", f);
  const acceptance = (await read("vw_PhieuNghiemThu", f)).find(
    (a) => a.status === "Approved",
  );
  if (
    o.paymentMethod === "BANK" &&
    !receipts.length &&
    !requests.some((r) => r.status === "PendingReview")
  ) {
    const account =
      o.status === "Huy"
        ? banks.find((b) => b.isActive)
        : banks.find((b) => b.id === acceptance?.bankAccountId && b.isActive);
    if (account)
      requests.unshift({
        id: "draft",
        orderId: o.id,
        bankAccountId: account.id,
        amount: o.total,
        status: "AwaitingTransfer",
        isActive: true,
        ...bankFor({ bankAccountId: account.id, orderId: o.id }, banks),
      });
  }
  return {
    method: o.paymentMethod,
    receipt: receipts.length
      ? { ...receipts[0], paidAt: receipts[0].createdAt }
      : null,
    requests,
  };
});
change("post", "/orders/:id/payment-method", ["KH"], (req) =>
  run(req, "sp_DoiPhuongThucThanhToan", {
    DonHangId: positiveId(req.params.id),
    PhuongThuc: req.body.method,
    TaiKhoanNganHangId: req.body.bankAccountId,
  }),
);
function bankFor(r, banks) {
  const b = banks.find((b) => b.id === r.bankAccountId);
  return {
    bankName: b?.bankName,
    bankCode: b?.bankCode,
    accountNumber: b?.accountNumber,
    accountHolder: b?.accountHolder,
    transferContent: r.bankReference || "HF-" + r.orderId,
  };
}
get("/bank-payment-requests", ["KT"], async () => {
  const banks = await read("vw_TaiKhoanNganHang"),
    users = await read("vw_NguoiDung");
  return (await read("vw_YeuCauThanhToan")).map((r) => ({
    ...r,
    ...bankFor(r, banks),
    customerName: users.find((u) => u.id === r.customerId)?.fullName,
    status: r.status === "Pending" ? "PendingReview" : r.status,
  }));
});
change("post", "/orders/:id/payments/bank", ["KH"], (req) =>
  run(req, "sp_TaoYeuCauThanhToan", {
    DonHangId: positiveId(req.params.id),
    TaiKhoanNganHangId: req.body.bankAccountId,
    ChungTuId: req.body.proofId,
    MaThamChieu: req.body.customerReference,
  }),
);
change("post", "/payment-requests/:id/decision", ["KT"], (req) =>
  run(req, "sp_XacNhanThanhToanNganHang", {
    YeuCauThanhToanId: positiveId(req.params.id),
    QuyetDinh:
      req.body.decision === "Approved" ? "Confirmed" : req.body.decision,
    SoTienThucNhan: req.body.actualAmount ?? req.body.receivedAmount,
    MaThamChieu: req.body.bankReference,
  }),
);
async function settlements(req) {
  const filter =
    req.user.VaiTro === "KTV" ? { KyThuatVienId: req.user.Id } : {};
  const receipts = await read("vw_ThanhToan"),
    users = await read("vw_NguoiDung"),
    orders = await read("vw_DonHangTongHop"),
    acceptances = await read("vw_PhieuNghiemThu", { TrangThai: "Approved" });
  return (await read("vw_DoiSoat", filter)).map((s) => {
    const p = receipts.find((p) => p.id === s.paymentId),
      o = orders.find((o) => o.id === s.orderId),
      acceptance = acceptances.find((a) => a.orderId === s.orderId);
    return {
      ...s,
      method: p?.method,
      amount: p?.amount,
      paidAt: p?.createdAt,
      paymentType: p?.paymentType || "DichVu",
      travelFee: p?.paymentType === "PhiHuyDon" ? Number(p.amount) : 0,
      materialTotal: acceptance?.materialTotal || 0,
      inspectionFee: acceptance?.inspectionFee || 0,
      serviceName: o?.serviceName,
      customerName: o?.customerName,
      technicianName: users.find((u) => u.id === s.technicianId)?.fullName,
      technicianCredit:
        Number(p?.amount || 0) - Number(s.commissionAmount || 0),
    };
  });
}
get("/settlements", ["KT", "KTV", "GD"], settlements);
change("post", "/settlements/:id/confirm", ["KT"], (req) =>
  run(req, "sp_DoiSoatCOD", { DoiSoatId: positiveId(req.params.id) }),
);
get("/wallet-requests", ["KT", "KTV"], async (req) => {
  const rows = await read(
      "vw_YeuCauVi",
      req.user.VaiTro === "KTV" ? { KyThuatVienId: req.user.Id } : {},
    ),
    users = await read("vw_NguoiDung");
  return rows.map((r) => ({
    ...r,
    technicianName: users.find((u) => u.id === r.technicianId)?.fullName,
  }));
});
change("post", "/wallet-requests", ["KTV"], (req) =>
  run(req, "sp_TaoYeuCauVi", {
    Loai: req.body.type,
    SoTien: req.body.amount,
    GhiChu: req.body.note,
    ChungTuId: req.body.proofId,
  }),
);
change("post", "/wallet-requests/:id/decision", ["KT"], (req) =>
  run(req, "sp_DuyetYeuCauVi", {
    YeuCauViId: positiveId(req.params.id),
    QuyetDinh: req.body.decision,
    LyDo: req.body.reason,
  }),
);
change("post", "/wallet-requests/:id/cancel", ["KTV"], (req) =>
  run(req, "sp_HuyYeuCauVi", { YeuCauViId: positiveId(req.params.id) }),
);
get("/technicians/me/wallet", ["KTV"], async (req) => {
  const t = await one("vw_KyThuatVien", { Id: req.user.Id }),
    pending = await read("vw_YeuCauVi", {
      KyThuatVienId: req.user.Id,
      Loai: "Withdrawal",
      TrangThai: "Pending",
    });
  return { ...t, availableBalance: Number(t.balance) - sum(pending, "amount") };
});
get("/technicians/me/wallet-transactions", ["KTV"], async (req) => {
  let rows = await read("vw_GiaoDichVi", { KyThuatVienId: req.user.Id });
  rows = rows.filter(
    (r) =>
      (req.query.direction !== "in" || r.amount > 0) &&
      (req.query.direction !== "out" || r.amount < 0) &&
      (!req.query.month || r.createdAt?.startsWith(req.query.month)),
  );
  return rows.slice(0, Math.min(200, Number(req.query.limit) || 20));
});
get("/technicians/me/income", ["KTV"], async (req) => {
  const rows = (await settlements(req)).filter(
    (r) =>
      !req.query.today ||
      new Date(r.paidAt).toDateString() === new Date().toDateString(),
  );
  const acceptances = await read("vw_PhieuNghiemThu", {
    KyThuatVienId: req.user.Id,
    TrangThai: "Approved",
  });
  const materialReimbursement = sum(
    acceptances.filter((a) => rows.some((r) => r.orderId === a.orderId)),
    "materialTotal",
  );
  return {
    income: sum(rows, "technicianCredit") - materialReimbursement,
    materialReimbursement,
    completedOrders: rows.filter((r) => r.paymentType !== "PhiHuyDon").length,
    total: sum(rows, "amount"),
  };
});

get("/support/order-options", ["KH"], (req) =>
  read("vw_DonHangTongHop", { KhachHangId: req.user.Id }),
);
get("/support/tickets", ["KH", "CSKH", "ADMIN"], (req) =>
  read(
    "vw_YeuCauHoTro",
    req.user.VaiTro === "KH" ? { KhachHangId: req.user.Id } : {},
  ),
);
get("/support/tickets/:id", ["KH", "CSKH", "ADMIN"], async (req) => {
  const t = await one("vw_YeuCauHoTro", { Id: positiveId(req.params.id) });
  if (!t) fail(404, "Không tìm thấy phiếu hỗ trợ.");
  if (req.user.VaiTro === "KH" && t.customerId !== req.user.Id)
    fail(403, "Không có quyền xem phiếu hỗ trợ.");
  t.history = (
    await read(
      "vw_TraoDoiHoTro",
      { YeuCauHoTroId: t.id },
      { order: "Id", ascending: true },
    )
  ).map((m) => ({
    ...m,
    note: m.text,
    actorName: m.fullName,
    authorRole: m.role,
  }));
  return t;
});
change("post", "/support/tickets", ["KH"], (req) =>
  run(req, "sp_TaoYeuCauHoTro", {
    DonHangId: req.body.orderId,
    Loai: req.body.type,
    MoTa: req.body.description,
  }),
);
change("patch", "/support/tickets/:id", ["CSKH"], (req) =>
  run(req, "sp_XuLyHoTro", {
    YeuCauHoTroId: positiveId(req.params.id),
    TrangThai: req.body.status,
    KetQuaXuLy: req.body.resolution,
  }),
);
change("post", "/support/tickets/:id/messages", ["KH", "CSKH"], (req) =>
  run(req, "sp_ThemTraoDoiHoTro", {
    YeuCauHoTroId: positiveId(req.params.id),
    NoiDung: req.body.text,
  }),
);
get("/notifications", all, (req) =>
  read("vw_ThongBao", { NguoiDungId: req.user.Id }),
);
change("post", "/notifications/:id/read", all, (req) =>
  run(req, "sp_DanhDauThongBao", { ThongBaoId: positiveId(req.params.id) }),
);
get("/attention-summary", all, async (req) => {
  const notifications = (
    await read("vw_ThongBao", { NguoiDungId: req.user.Id })
  ).filter((n) => !n.isRead);
  const orders = req.user.VaiTro === "GD" ? [] : await orderRows(req);
  const wanted =
    {
      KH: ["ChoDuyetSoBo", "ChoNghiemThu"],
      KTV: [
        "ChoNhan",
        "DaTiepNhan",
        "DangDiChuyen",
        "DaDenNoi",
        "DangXuLy",
        "ChoNghiemThu",
      ],
      DPV: ["ChoTiepNhan", "ChoPhanCong"],
    }[req.user.VaiTro] || [];
  const actionable = orders.filter(
    (o) =>
      wanted.includes(o.status) ||
      (req.user.VaiTro === "KH" &&
        o.status === "Huy" &&
        o.cancellationFee > 0 &&
        o.paymentStatus !== "Paid"),
  );
  const support =
    req.user.VaiTro === "CSKH"
      ? (
          await read(
            "vw_YeuCauHoTro",
            req.user.VaiTro === "KH" ? { KhachHangId: req.user.Id } : {},
          )
        ).filter((t) => ["Open", "InProgress"].includes(t.status)).length
      : 0;
  const applications =
    req.user.VaiTro === "ADMIN"
      ? (await read("vw_HoSoKTV", { TrangThai: "Pending" })).length
      : 0;
  const counts = { settlements: 0, bank: 0, wallet: 0 };
  if (req.user.VaiTro === "KT") {
    counts.settlements = (
      await read("vw_DoiSoat", { TrangThai: "Pending" })
    ).length;
    counts.bank = (
      await read("vw_YeuCauThanhToan", { TrangThai: "Pending" })
    ).length;
    counts.wallet = (
      await read("vw_YeuCauVi", { TrangThai: "Pending" })
    ).length;
  }
  return {
    unread: notifications.length,
    unreadNotifications: notifications,
    orders: actionable,
    orderIds: actionable.map((o) => o.id),
    support,
    applications,
    policies: 0,
    finance: counts,
  };
});
function csv(res, rows) {
  const keys = Object.keys(rows[0] || { id: null, status: null });
  const cell = (v) =>
    '"' +
    String(v ?? "")
      .replace(/^[=+@-]/, "'$&")
      .replaceAll('"', '""') +
    '"';
  res
    .type("text/csv")
    .send(
      "\ufeff" +
        [keys, ...rows.map((r) => keys.map((k) => r[k]))]
          .map((r) => r.map(cell).join(","))
          .join("\r\n"),
    );
}
webRouter.get(
  "/orders.csv",
  roles("ADMIN", "DPV"),
  wrap(async (req, res) => csv(res, await orderRows(req))),
);
webRouter.use(webReports);
