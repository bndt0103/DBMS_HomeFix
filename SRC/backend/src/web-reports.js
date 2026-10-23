import { Router } from "express";
import { queryView, first, exec } from "./db.js";
import { ok, wrap, roles, fail } from "./common.js";
import { shape, sum } from "./web-shape.js";

export const webReports = Router();
const office = ["DPV", "CSKH", "KT", "GD", "ADMIN"];
const financial = ["KT", "GD", "ADMIN"];
const read = async (view, filter = {}, options = {}) =>
  shape(await queryView(view, filter, { all: true, ...options }));
function period(req, rows, key = "createdAt") {
  const { from, to } = req.query;
  if (
    (from && isNaN(Date.parse(from))) ||
    (to && isNaN(Date.parse(to))) ||
    (from && to && new Date(from) >= new Date(to))
  )
    fail(400, "Khoảng thời gian không hợp lệ.");
  return rows.filter(
    (r) =>
      (!from || new Date(r[key]) >= new Date(from)) &&
      (!to || new Date(r[key]) < new Date(to)),
  );
}
const get = (path, allowed, fn) =>
  webReports.get(
    path,
    roles(...allowed),
    wrap(async (req, res) => ok(res, await fn(req))),
  );
const businessDay = (value) =>
  new Date(value).toLocaleDateString("en-CA", { timeZone: "Asia/Ho_Chi_Minh" });
function groupDays(rows, key, amount) {
  const map = new Map();
  for (const row of rows) {
    const day = row[key] ? businessDay(row[key]) : null;
    if (day) map.set(day, (map.get(day) || 0) + Number(row[amount] || 0));
  }
  return [...map]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([day, amount]) => ({ day, amount }));
}
async function summary(req) {
  const orders = period(req, await read("vw_DonHangTongHop"));
  const reviews = period(req, await read("vw_DanhGia"));
  const statusCounts = Object.fromEntries(
    [...new Set(orders.map((o) => o.status))].map((s) => [
      s,
      orders.filter((o) => o.status === s).length,
    ]),
  );
  const result = {
    totalOrders: orders.length,
    completedOrders: statusCounts.HoanThanh || 0,
    cancelledOrders: statusCounts.Huy || 0,
    statusCounts,
    byStatus: Object.entries(statusCounts).map(([status, count]) => ({
      status,
      count,
    })),
    averageRating: reviews.length
      ? sum(reviews, "rating") / reviews.length
      : null,
  };
  if (financial.includes(req.user.VaiTro)) {
    const payments = period(req, await read("vw_ThanhToan"));
    const settlements = period(
      req,
      await read("vw_DoiSoat", { TrangThai: "Confirmed" }),
    );
    Object.assign(result, {
      gmv: sum(
        payments.filter((p) => p.paymentType !== "PhiHuyDon"),
        "amount",
      ),
      cancellationFees: sum(
        payments.filter((p) => p.paymentType === "PhiHuyDon"),
        "amount",
      ),
      paidOrders: payments.length,
      commissionRevenue: sum(settlements, "commissionAmount"),
      trend: groupDays(payments, "createdAt", "amount"),
      commissionTrend: groupDays(settlements, "createdAt", "commissionAmount"),
    });
  }
  return result;
}
async function performance(req) {
  const techs = await read("vw_KyThuatVien"),
    users = await read("vw_NguoiDung");
  const orders = period(req, await read("vw_DonHangTongHop")),
    reviews = period(req, await read("vw_DanhGia"));
  const support = period(req, await read("vw_YeuCauHoTro"));
  return techs.map((t) => {
    const jobs = orders.filter((o) => o.technicianId === t.id),
      done = jobs.filter((o) => o.status === "HoanThanh"),
      ratings = reviews.filter((r) => r.technicianId === t.id);
    const complaints = new Set(
      support
        .filter(
          (s) => s.type === "Complaint" && jobs.some((o) => o.id === s.orderId),
        )
        .map((s) => s.orderId),
    ).size;
    return {
      ...t,
      isActive: users.find((u) => u.id === t.id)?.isActive,
      assignedOrders: jobs.length,
      finishedOrders: done.length,
      completedOrders: done.length,
      averageRating: ratings.length
        ? sum(ratings, "rating") / ratings.length
        : null,
      completionRate: jobs.length ? (100 * done.length) / jobs.length : null,
      complaintRate: jobs.length ? (100 * complaints) / jobs.length : null,
      warrantyRate: jobs.length
        ? (100 *
            new Set(
              support
                .filter(
                  (s) =>
                    s.type === "Warranty" &&
                    jobs.some((o) => o.id === s.orderId),
                )
                .map((s) => s.orderId),
            ).size) /
          jobs.length
        : null,
      cancellationRate: jobs.length
        ? (100 * jobs.filter((o) => o.status === "Huy").length) / jobs.length
        : null,
      averageMinutes: null,
      processingMinutes: null,
      measuredJobs: 0,
      scheduledVisits: 0,
      onTimeVisits: 0,
      onTimeRate: null,
      rejectedOrders: 0,
    };
  });
}
get("/reports/summary", office, summary);
get("/reports/technicians", ["DPV", "GD", "ADMIN"], performance);
get("/reports/performance", ["DPV", "GD", "ADMIN"], performance);
get("/reports/quality", ["CSKH", "GD", "ADMIN"], async (req) => {
  const orders = period(req, await read("vw_DonHangTongHop")),
    reviews = period(req, await read("vw_DanhGia"));
  const tickets = period(req, await read("vw_YeuCauHoTro")),
    users = await read("vw_NguoiDung");
  const complaints = tickets
    .filter((t) => t.type === "Complaint")
    .map((t) => ({
      ...t,
      customerName: users.find((u) => u.id === t.customerId)?.fullName,
    }));
  const finished = orders.filter((o) => o.status === "HoanThanh");
  const complaintOrders = new Set(complaints.map((c) => c.orderId)).size;
  return {
    totalOrders: orders.length,
    completedOrders: finished.length,
    servedCustomers: new Set(finished.map((o) => o.customerId)).size,
    activeCustomers: new Set(orders.map((o) => o.customerId)).size,
    newCustomers: period(
      req,
      users.filter((u) => u.role === "KH"),
    ).length,
    averageRating: reviews.length
      ? sum(reviews, "rating") / reviews.length
      : null,
    complaintOrders,
    complaintRate: orders.length
      ? (complaintOrders * 100) / orders.length
      : null,
    reviews,
    complaints,
    lowRatings: reviews.filter((r) => r.rating <= 2),
    ratings: [5, 4, 3, 2, 1].map((rating) => ({
      rating,
      count: reviews.filter((r) => r.rating === rating).length,
    })),
  };
});
async function financeRows(req) {
  const payments = period(req, await read("vw_ThanhToan")),
    settlements = await read("vw_DoiSoat"),
    orders = await read("vw_DonHangTongHop"),
    acceptances = await read("vw_PhieuNghiemThu"),
    users = await read("vw_NguoiDung");
  return payments.map((p) => {
    const s = settlements.find((s) => s.paymentId === p.id),
      o = orders.find((o) => o.id === p.orderId),
      a = acceptances.find((a) => a.id === p.acceptanceId);
    return {
      ...p,
      paidAt: p.createdAt,
      serviceName: o?.serviceName,
      customerName: o?.customerName,
      technicianName: users.find((u) => u.id === o?.technicianId)?.fullName,
      travelFee: p.paymentType === "PhiHuyDon" ? Number(p.amount) : 0,
      inspectionFee: a?.inspectionFee || 0,
      laborFee: a?.laborFee || 0,
      materialTotal: a?.materialTotal || 0,
      commissionAmount: s?.commissionAmount || 0,
      commissionRatePercent: s?.commissionRatePercent || 0,
      settlementStatus: s?.status,
      technicianIncome:
        Number(p.amount) -
        Number(s?.commissionAmount || 0) -
        Number(a?.materialTotal || 0),
    };
  });
}
get("/reports/finance", financial, financeRows);
get("/reports/cashflow", financial, async (req) => {
  const payments = period(
    req,
    await read("vw_ThanhToan", { PhuongThuc: "BANK" }),
  );
  const wallet = period(
    req,
    await read("vw_YeuCauVi", { TrangThai: "Approved" }),
  );
  const map = new Map();
  function add(row, flow) {
    const day = row.createdAt.slice(0, 10),
      value = map.get(day) || { day, incoming: 0, outgoing: 0 };
    value[flow] += Number(row.amount);
    map.set(day, value);
  }
  payments.forEach((p) => add(p, "incoming"));
  wallet.forEach((w) => add(w, w.type === "Deposit" ? "incoming" : "outgoing"));
  return [...map.values()].sort((a, b) => a.day.localeCompare(b.day));
});
webReports.get(
  "/reports/finance.csv",
  roles(...financial),
  wrap(async (req, res) => {
    const rows = await financeRows(req),
      keys = [
        "orderId",
        "paidAt",
        "method",
        "paymentType",
        "travelFee",
        "amount",
        "commissionAmount",
        "settlementStatus",
      ];
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
  }),
);
const monitoringDefaults = {
  qualityAlerts: false,
  weeklyReport: false,
  showComplaints: true,
  financeAlerts: false,
  financeWeekly: false,
  showCashflow: true,
  performanceAlerts: false,
  performanceWeekly: false,
  showTechnicians: true,
};
get("/reports/monitoring", ["GD", "CSKH", "ADMIN"], async (req) => {
  const row = await first(
    "vw_CauHinh",
    { Khoa: "GiamSat_" + req.user.Id },
    { order: "Khoa" },
  );
  return { ...monitoringDefaults, ...(row ? JSON.parse(row.GiaTri) : {}) };
});
webReports.patch(
  "/reports/monitoring",
  roles("GD", "CSKH", "ADMIN"),
  wrap(async (req, res) => {
    const row = await first(
      "vw_CauHinh",
      { Khoa: "GiamSat_" + req.user.Id },
      { order: "Khoa" },
    );
    const data = {
      ...monitoringDefaults,
      ...(row ? JSON.parse(row.GiaTri) : {}),
    };
    for (const key of Object.keys(monitoringDefaults))
      if (typeof req.body[key] === "boolean") data[key] = req.body[key];
    await exec("sp_LuuTuyChonGiamSat", {
      NguoiThucHienId: req.user.Id,
      GiaTri: JSON.stringify(data),
    });
    ok(res, data);
  }),
);
// Đề xuất được lưu dưới khóa DeXuatChinhSach_*, không chèn chính sách mẫu.
get("/director/policy-proposals", ["GD"], async () => {
  const rows = await read("vw_CauHinh", {}, { order: "Khoa" });
  return rows
    .filter((r) => r.key.startsWith("DeXuatChinhSach_"))
    .map((r) => ({
      ...JSON.parse(r.value),
      id: r.key.slice("DeXuatChinhSach_".length),
    }));
});
webReports.post(
  "/director/policy-proposals/:id/decision",
  roles("GD"),
  wrap(async (req, res) => {
    const rows = await exec("sp_DuyetChinhSach", {
      NguoiThucHienId: req.user.Id,
      Khoa: "DeXuatChinhSach_" + req.params.id,
      QuyetDinh: req.body.decision,
      GhiChu: req.body.note || "",
      NgayHieuLuc:
        req.body.effectiveAt === "tomorrow"
          ? new Date(Date.now() + 86400000)
          : new Date(),
    });
    ok(res, shape(rows[0]));
  }),
);
