import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const source = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const project = path.resolve(source, "..");
const database = "HomeFix_Test_" + randomBytes(6).toString("hex");
const uploadDirectory = path.resolve(os.tmpdir(), database + "_uploads");
process.env.UPLOADS_DIR = uploadDirectory;
process.env.DB_NAME = database;
process.env.JWT_SECRET = randomBytes(48).toString("hex");
process.env.NODE_ENV = "test";
process.env.DB_IMPERSONATE = "true";
let server, base, sql, databaseConfig, pool, close;
const tokens = {},
  users = {};
let orderId, proofId;
async function api(method, route, role, body, expected = 200) {
  const headers = {};
  if (role) headers.Authorization = "Bearer " + tokens[role];
  if (body && !(body instanceof FormData))
    headers["Content-Type"] = "application/json";
  const response = await fetch(base + route, {
    method,
    headers,
    body: body
      ? body instanceof FormData
        ? body
        : JSON.stringify(body)
      : undefined,
  });
  const result = await response.json();
  assert.equal(
    response.status,
    expected,
    `${method} ${route}: ${JSON.stringify(result)}`,
  );
  return result.data;
}
async function upload(role, purpose, order) {
  const sharp = (await import("sharp")).default;
  const image = await sharp({
    create: { width: 10, height: 10, channels: 3, background: "#135789" },
  })
    .png()
    .toBuffer();
  const form = new FormData();
  form.set("file", new Blob([image], { type: "image/png" }), "test.png");
  form.set("MucDich", purpose);
  if (order) form.set("DonHangId", String(order));
  return api("POST", "/uploads", role, form);
}
const details = (role = "KH") => api("GET", "/orders/" + orderId, role);
async function progress(state) {
  const d = await details("KTV");
  return api("PATCH", `/orders/${orderId}/status`, "KTV", {
    TrangThaiTiepTheo: state,
    PhienBanDuKien: d.DonHang.PhienBan,
    LyDo: "Kiểm thử tiến độ",
  });
}
before(async () => {
  const result = spawnSync(
    process.execPath,
    ["backend/tools/install-database.js"],
    { cwd: source, env: process.env, encoding: "utf8", windowsHide: true },
  );
  ({ sql, databaseConfig, pool, close } = await import("../src/db.js"));
  assert.equal(result.status, 0, result.stdout + "\n" + result.stderr);
  const { app } = await import("../src/server.js");
  server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  base = `http://127.0.0.1:${server.address().port}/api`;
});
after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (close) await close();
  if (
    uploadDirectory.startsWith(path.resolve(os.tmpdir()) + path.sep) &&
    path.basename(uploadDirectory) === database + "_uploads"
  )
    fs.rmSync(uploadDirectory, { recursive: true, force: true });
  if (!sql) return;
  const connection = await new sql.ConnectionPool(
    databaseConfig("master"),
  ).connect();
  try {
    assert.match(database, /^HomeFix_Test_[a-f0-9]{12}$/);
    await connection
      .request()
      .query(
        `IF DB_ID(N'${database}') IS NOT NULL BEGIN ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${database}]; END;`,
      );
  } finally {
    await connection.close();
  }
});

test("Kiến trúc: controller không chứa SQL trực tiếp và các SP/View đều có registry", () => {
  const folder = path.join(source, "backend/src");
  for (const file of fs
    .readdirSync(folder)
    .filter((name) => name.endsWith(".js") && name !== "db.js")) {
    const contents = fs.readFileSync(path.join(folder, file), "utf8");
    assert.doesNotMatch(
      contents,
      /\b(?:SELECT|INSERT\s+INTO|UPDATE\s+dbo\.|DELETE\s+FROM)\b/i,
      file,
    );
    assert.doesNotMatch(contents, /\.query\s*\(/, file);
  }
  assert.ok(!fs.existsSync(path.join(folder, "ai.js")));
  const registry = JSON.parse(
    fs.readFileSync(path.join(folder, "db-contract.json")),
  );
  assert.ok(Object.keys(registry.procedures).length >= 40);
  assert.ok(registry.views.length >= 25);
  assert.ok(registry.functions.fn_ThongKeDon);
  assert.equal(
    fs.readFileSync(path.join(project, "SQL", "seed_data.sql"), "utf8"),
    fs.readFileSync(
      path.join(project, "SQL", "modules", "08_seed.sql"),
      "utf8",
    ),
    "Standalone seed must match the clean seed module",
  );
});

test("Seed: đúng 7 vai trò, danh mục gốc, số dư 0 và không có giao dịch mẫu", async () => {
  const p = await pool();
  const result = await p
    .request()
    .query(
      `SELECT COUNT(*) AS N FROM dbo.NguoiDung; SELECT COUNT(*) AS N FROM dbo.DanhMucDichVu; SELECT COUNT(*) AS N FROM dbo.DonHang; SELECT COUNT(*) AS N FROM dbo.GiaoDichVi; SELECT COUNT(*) AS N FROM dbo.NhatKy; SELECT COUNT(*) AS N FROM dbo.XacThucOTP; SELECT COUNT(*) AS N FROM dbo.KyThuatVien WHERE SoDu<>0;`,
    );
  assert.deepEqual(
    result.recordsets.map((rows) => rows[0].N),
    [7, 5, 0, 0, 0, 0, 0],
  );
});

test("Đăng nhập đủ 7 vai trò, public catalog; chặn sai mật khẩu và sai vai trò", async () => {
  const roles = ["KH", "KTV", "DPV", "CSKH", "KT", "GD", "ADMIN"];
  for (const [index, role] of roles.entries()) {
    const data = await api("POST", "/auth/login", null, {
      SoDienThoai: "090000000" + (index + 1),
      MatKhau: "123456",
    });
    tokens[role] = data.token;
    users[role] = data.user;
    assert.equal(data.user.VaiTro, role);
    assert.equal(data.user.MatKhauBam, undefined);
    assert.equal((await api("GET", "/auth/me", role)).Id, data.user.Id);
  }
  assert.equal((await api("GET", "/services")).length, 5);
  await api(
    "POST",
    "/auth/login",
    null,
    { SoDienThoai: "0900000001", MatKhau: "wrong!" },
    401,
  );
  await api("GET", "/users", "KH", null, 403);
  await api("GET", "/services?all=1", "KH", null, 403);
});

test("Ví: nạp có chứng từ, chỉ kế toán duyệt và từ chối phiên bản cũ", async () => {
  proofId = (await upload("KTV", "WalletProof")).Id;
  const request = await api("POST", "/wallet/requests", "KTV", {
    Loai: "Deposit",
    SoTien: 500000,
    GhiChu: "Nạp ví kiểm thử",
    ChungTuId: proofId,
  });
  await api(
    "POST",
    `/wallet/requests/${request.Id}/decision`,
    "KH",
    { QuyetDinh: "Approved", PhienBanDuKien: request.PhienBan },
    403,
  );
  await api("POST", `/wallet/requests/${request.Id}/decision`, "KT", {
    QuyetDinh: "Approved",
    PhienBanDuKien: request.PhienBan,
  });
  await api(
    "POST",
    `/wallet/requests/${request.Id}/decision`,
    "KT",
    { QuyetDinh: "Approved", PhienBanDuKien: request.PhienBan },
    409,
  );
  assert.equal((await api("GET", "/wallet", "KTV")).KyThuatVien.SoDu, 500000);
});

test("Đơn hàng: tạo, báo giá, khách duyệt; giữ quyền sở hữu và concurrency", async () => {
  const services = await api("GET", "/services");
  const order = await api("POST", "/orders", "KH", {
    DichVuId: services[0].Id,
    DiaChi: "123 Đường kiểm thử, Thủ Đức",
    MoTa: "Thiết bị không hoạt động",
    NguoiThucHienId: users.KTV.Id,
  });
  orderId = order.Id;
  assert.equal(order.KhachHangId, users.KH.Id);
  await api(
    "PATCH",
    `/orders/${orderId}/status`,
    "KH",
    { TrangThaiTiepTheo: "HoanThanh", PhienBanDuKien: order.PhienBan },
    403,
  );
  const quote = await api("POST", `/orders/${orderId}/quote`, "DPV", {
    PhiKiemTra: 50000,
    TienCong: 200000,
    TyLeHoaHong: 15,
    ChanDoan: "Cần kiểm tra thiết bị",
    PhienBanDuKien: order.PhienBan,
  });
  await api(
    "POST",
    `/orders/${orderId}/quote`,
    "DPV",
    {
      PhiKiemTra: 50000,
      TienCong: 200000,
      TyLeHoaHong: 15,
      ChanDoan: "Gửi lại phiên bản cũ",
      PhienBanDuKien: order.PhienBan,
    },
    409,
  );
  await api("POST", `/quotes/${quote.Id}/decision`, "KH", {
    QuyetDinh: "Approved",
    PhienBanDuKien: quote.PhienBan,
  });
  assert.equal((await details()).DonHang.TrangThai, "ChoPhanCong");
});

test("Điều phối và tiến độ: chỉ thợ được giao nhận và đi đúng thứ tự", async () => {
  const tech = await api("GET", "/technician/me", "KTV");
  await api("PATCH", "/technician/status", "KTV", {
    TrangThaiSanSang: "SanSang",
    PhienBanDuKien: tech.PhienBan,
  });
  const d = await details("DPV");
  const assignment = await api("POST", `/orders/${orderId}/assign`, "DPV", {
    KyThuatVienId: users.KTV.Id,
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  await api("POST", `/assignments/${assignment.Id}/respond`, "KTV", {
    QuyetDinh: "Accepted",
    PhienBanDuKien: assignment.PhienBan,
  });
  await progress("DangDiChuyen");
  await progress("DaDenNoi");
  await progress("DangXuLy");
});

test("Vật tư và nghiệm thu: tổng tiền tại SQL, chữ ký KH/KTV riêng", async () => {
  let d = await details("KTV");
  for (const role of ["KH", "DPV", "CSKH", "KT", "GD", "ADMIN"])
    await api("POST", `/orders/${orderId}/materials`, role, {}, 403);
  for (const line of [
    { Ten: "Sai số lượng", SoLuong: 0, DonGia: 10000 },
    { Ten: "Sai giá", SoLuong: 1, DonGia: -1 },
    { Ten: "Thiếu giá", SoLuong: 1 },
  ])
    await api(
      "POST",
      `/orders/${orderId}/materials`,
      "KTV",
      {
        VatTu: [line],
        PhienBanDuKien: d.DonHang.PhienBan,
      },
      409,
    );
  const firstMaterial = await api(
    "POST",
    `/orders/${orderId}/materials`,
    "KTV",
    {
      VatTu: [{ Ten: "Bảng kê ban đầu", SoLuong: 1, DonGia: 999 }],
      PhienBanDuKien: d.DonHang.PhienBan,
    },
  );
  await api(
    "POST",
    `/orders/${orderId}/materials`,
    "KTV",
    {
      VatTu: [{ Ten: "Phiên bản cũ", SoLuong: 1, DonGia: 1 }],
      PhienBanDuKien: d.DonHang.PhienBan,
    },
    409,
  );
  d = await details("KTV");
  const material = await api("POST", `/orders/${orderId}/materials`, "KTV", {
    VatTu: [
      { Ten: "Vật tư kiểm thử", SoLuong: 2, DonGia: 50000, SoThangBaoHanh: 6 },
    ],
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  assert.equal(material.TrangThai, undefined);
  await api("POST", `/materials/${material.Id}/decision`, "KH", {}, 404);
  d = await details("KTV");
  const acceptance = await api("POST", `/orders/${orderId}/acceptance`, "KTV", {
    NguyenNhan: "Linh kiện hư",
    PhuongAnXuLy: "Thay linh kiện và chạy thử",
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  assert.equal(acceptance.TongTien, 350000);
  const lists = (await details("KTV")).BangKeVatTu;
  assert.equal(
    lists.find((row) => row.Id === firstMaterial.Id).DangApDung,
    false,
  );
  assert.equal(lists.find((row) => row.Id === material.Id).DangApDung, true);
  const connection = await pool();
  assert.equal(
    Number(
      (
        await connection
          .request()
          .query(`SELECT dbo.fn_TongTienDonHang(${orderId}) AS Tong`)
      ).recordset[0].Tong,
    ),
    350000,
  );
  await assert.rejects(
    connection.request()
      .query(`SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
    UPDATE dbo.ChiTietVatTu SET DonGia=1 WHERE BangKeVatTuId=${material.Id};`),
    /Vật tư đã lập nghiệm thu/,
  );

  const technicianSign = await upload("KTV", "TechnicianSignature", orderId);
  await api("POST", `/acceptances/${acceptance.Id}/technician-sign`, "KTV", {
    ChuKyId: technicianSign.Id,
    PhienBanDuKien: acceptance.PhienBan,
  });
  const customerSign = await upload("KH", "CustomerSignature", orderId);
  d = await details();
  await api("POST", `/acceptances/${acceptance.Id}/customer-sign`, "KH", {
    ChuKyId: customerSign.Id,
    PhuongThucThanhToan: "COD",
    PhienBanDuKien: d.NghiemThu[0].PhienBan,
  });
  d = await details();
  assert.equal(d.NghiemThu[0].TrangThai, "Approved");
  assert.notEqual(d.NghiemThu[0].ChuKyKHId, d.NghiemThu[0].ChuKyKTVId);
});

test("COD, đối soát và đánh giá: không ghi tiền hai lần, ví và sổ luôn khớp", async () => {
  let d = await details("KTV");
  await api("POST", `/orders/${orderId}/payments/cod`, "KTV", {
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  await api(
    "POST",
    `/orders/${orderId}/payments/cod`,
    "KTV",
    { PhienBanDuKien: d.DonHang.PhienBan },
    409,
  );
  const settlement = (await api("GET", "/settlements", "KT"))[0];
  await api("POST", `/settlements/${settlement.Id}/confirm`, "KT", {
    PhienBanDuKien: settlement.PhienBan,
  });
  assert.equal((await api("GET", "/wallet", "KTV")).KyThuatVien.SoDu, 470000);
  await api("POST", `/orders/${orderId}/review`, "KH", {
    Diem: 5,
    NhanXet: "Dịch vụ hoàn thành tốt",
  });
  const report = await api("GET", "/reports", "GD");
  assert.equal(report.Vi[0].ChenhLech, 0);
  assert.equal(Number(report.DoanhThu[0].HoaHongDaDoiSoat), 30000);
});

test("Hỗ trợ truyền thống và quản trị tài khoản hoạt động qua SP", async () => {
  const ticket = await api("POST", "/support", "KH", {
    DonHangId: orderId,
    Loai: "Complaint",
    MoTa: "Khách cần hỗ trợ kiểm tra thêm",
  });
  await api("POST", `/support/${ticket.Id}/messages`, "KH", {
    NoiDung: "Nội dung trao đổi kiểm thử",
  });
  await api("PATCH", `/support/${ticket.Id}`, "CSKH", {
    TrangThai: "InProgress",
    KetQuaXuLy: "Đã tiếp nhận và liên hệ",
    PhienBanDuKien: (await api("GET", "/support", "CSKH")).find(
      (row) => row.Id === ticket.Id,
    ).PhienBan,
  });
  const messages = await api("GET", `/support/${ticket.Id}/messages`, "CSKH");
  assert.ok(messages.some((m) => m.NoiDung === "Nội dung trao đổi kiểm thử"));
  assert.ok(messages.some((m) => m.TrangThai === "InProgress"));
  const account = await api("POST", "/users", "ADMIN", {
    HoTen: "Tài khoản kiểm thử",
    SoDienThoai: "0912345678",
    MatKhau: "123456",
    VaiTro: "KH",
  });
  await api("PATCH", `/users/${account.Id}/status`, "ADMIN", {
    DangHoatDong: false,
    PhienBanDuKien: account.PhienBan,
  });
  await api(
    "POST",
    "/auth/login",
    null,
    { SoDienThoai: "0912345678", MatKhau: "123456" },
    401,
  );
});

test("BANK: chứng từ đúng chủ, xác nhận đúng tiền, không ghi nhận hai lần", async () => {
  const services = await api("GET", "/services");
  const order = await api("POST", "/orders", "KH", {
    DichVuId: services[0].Id,
    DiaChi: "Địa chỉ kiểm thử BANK",
    MoTa: "Kiểm tra luồng thanh toán ngân hàng",
  });
  const id = order.Id;
  const read = (role) => api("GET", "/orders/" + id, role);
  const quote = await api("POST", `/orders/${id}/quote`, "DPV", {
    PhiKiemTra: 50000,
    TienCong: 200000,
    TyLeHoaHong: 15,
    ChanDoan: "Kiểm tra BANK",
    PhienBanDuKien: order.PhienBan,
  });
  await api("POST", `/quotes/${quote.Id}/decision`, "KH", {
    QuyetDinh: "Approved",
    PhienBanDuKien: quote.PhienBan,
  });
  let d = await read("DPV");
  const assignment = await api("POST", `/orders/${id}/assign`, "DPV", {
    KyThuatVienId: users.KTV.Id,
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  await api("POST", `/assignments/${assignment.Id}/respond`, "KTV", {
    QuyetDinh: "Accepted",
    PhienBanDuKien: assignment.PhienBan,
  });
  for (const state of ["DangDiChuyen", "DaDenNoi", "DangXuLy"]) {
    d = await read("KTV");
    await api("PATCH", `/orders/${id}/status`, "KTV", {
      TrangThaiTiepTheo: state,
      PhienBanDuKien: d.DonHang.PhienBan,
      LyDo: "Kiểm thử BANK",
    });
  }
  d = await read("KTV");
  const acceptance = await api("POST", `/orders/${id}/acceptance`, "KTV", {
    NguyenNhan: "Kiểm thử",
    PhuongAnXuLy: "Đã sửa xong",
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  const technicianSign = await upload("KTV", "TechnicianSignature", id);
  await api("POST", `/acceptances/${acceptance.Id}/technician-sign`, "KTV", {
    ChuKyId: technicianSign.Id,
    PhienBanDuKien: acceptance.PhienBan,
  });
  const customerSign = await upload("KH", "CustomerSignature", id);
  d = await read("KH");
  await api("POST", `/acceptances/${acceptance.Id}/customer-sign`, "KH", {
    ChuKyId: customerSign.Id,
    PhuongThucThanhToan: "BANK",
    PhienBanDuKien: d.NghiemThu[0].PhienBan,
  });
  const proof = await upload("KH", "PaymentProof", id);
  const bank = (await api("GET", "/bank-accounts", "KH"))[0];
  const request = await api("POST", `/orders/${id}/payments/bank`, "KH", {
    TaiKhoanNganHangId: bank.Id,
    ChungTuId: proof.Id,
    MaThamChieu: "BANK_TEST_001",
  });
  const confirmation = {
    QuyetDinh: "Confirmed",
    PhienBanDuKien: request.PhienBan,
    SoTienThucNhan: 250000,
    MaThamChieu: "BANK_TEST_001",
  };
  await api(
    "POST",
    `/bank-requests/${request.Id}/confirm`,
    "KT",
    { ...confirmation, SoTienThucNhan: 1 },
    409,
  );
  await api("POST", `/bank-requests/${request.Id}/confirm`, "KT", confirmation);
  await api(
    "POST",
    `/bank-requests/${request.Id}/confirm`,
    "KT",
    confirmation,
    409,
  );
  const settlement = (await api("GET", "/settlements", "KT")).find(
    (row) => row.DonHangId === id,
  );
  const before = (await api("GET", "/wallet", "KTV")).KyThuatVien.SoDu;
  await api("POST", `/settlements/${settlement.Id}/confirm`, "KT", {
    PhienBanDuKien: settlement.PhienBan,
  });
  assert.equal(
    (await api("GET", "/wallet", "KTV")).KyThuatVien.SoDu,
    before + 220000,
  );
});

test("Tài khoản: đăng ký, đổi mật khẩu và chặn KH xem đơn của người khác", async () => {
  await api("POST", "/auth/register", null, {
    HoTen: "Khách mới kiểm thử",
    SoDienThoai: "0911111111",
    Email: "homefix-test@example.invalid",
    MatKhau: "123456",
  });
  const login = await api("POST", "/auth/login", null, {
    SoDienThoai: "0911111111",
    MatKhau: "123456",
  });
  tokens.KH2 = login.token;
  await api("GET", "/orders/" + orderId, "KH2", null, 403);
  await api("PATCH", "/auth/profile", "KH2", {
    HoTen: "Khách đã cập nhật",
    Email: "homefix-test@example.invalid",
    DiaChi: "Địa chỉ mới",
  });
  await api("POST", "/auth/password", "KH2", {
    MatKhauCu: "123456",
    MatKhauMoi: "654321",
  });
  await api(
    "POST",
    "/auth/login",
    null,
    { SoDienThoai: "0911111111", MatKhau: "123456" },
    401,
  );
  assert.ok(
    (
      await api("POST", "/auth/login", null, {
        SoDienThoai: "0911111111",
        MatKhau: "654321",
      })
    ).token,
  );
});

test("OTP: lưu số lần sai, dùng một lần và không cung cấp mã băm qua view công khai", async () => {
  const { exec, first, withDatabaseRole } = await import("../src/db.js");
  const { randomUUID } = await import("node:crypto");
  const Id = randomUUID();
  await withDatabaseRole(null, async () => {
    await exec("sp_TaoMaOTP", {
      Id,
      MucDich: "ResetPassword",
      DiaChiNhan: "homefix-test@example.invalid",
      MaBam: "a".repeat(64),
      NgayHetHan: new Date(Date.now() + 60000),
    });
    assert.equal(
      (await exec("sp_XacThucOTP", { Id, MaBam: "b".repeat(64) }))[0].DaXacThuc,
      false,
    );
    const metadata = await first("vw_XacThucOTP", { Id });
    assert.equal(metadata.SoLanThu, 1);
    assert.equal(metadata.MaBam, undefined);
    assert.equal(
      (await exec("sp_XacThucOTP", { Id, MaBam: "a".repeat(64) }))[0].DaXacThuc,
      true,
    );
    assert.equal(
      (await exec("sp_XacThucOTP", { Id, MaBam: "a".repeat(64) }))[0].DaXacThuc,
      false,
    );
  });
});

test("SQL roles: DENY bảng nhạy cảm; trigger từ chối nguyên lệnh nhiều dòng sai", async () => {
  const p = await pool();
  const result = await p
    .request()
    .query(
      `EXECUTE AS USER='hf_KH'; SELECT HAS_PERMS_BY_NAME('dbo.NguoiDung','OBJECT','SELECT','MatKhauBam','COLUMN') AS DocMatKhau, HAS_PERMS_BY_NAME('dbo.GiaoDichVi','OBJECT','UPDATE') AS SuaSo; REVERT;`,
    );
  assert.equal(result.recordset[0].DocMatKhau, 0);
  assert.equal(result.recordset[0].SuaSo, 0);
  const checked = await p.request()
    .query(`SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
    DECLARE @Truoc INT=(SELECT COUNT(*) FROM dbo.ChiTietVatTu);
    BEGIN TRY
      BEGIN TRANSACTION;
      INSERT dbo.BangKeVatTu(DonHangId,LanSuaDoi,DangApDung,NguoiTaoId)
      VALUES(${orderId},99,0,${users.KTV.Id});
      DECLARE @Moi INT=SCOPE_IDENTITY(),@Cu INT=(SELECT MIN(BangKeVatTuId) FROM dbo.PhieuNghiemThu WHERE DonHangId=${orderId});
      INSERT dbo.ChiTietVatTu(BangKeVatTuId,Ten,SoLuong,DonGia)
      VALUES(@Moi,N'Dòng bảng kê mới',1,10000),(@Cu,N'Dòng đã nghiệm thu không được sửa',1,20000);
      ROLLBACK;
      THROW 51999,'DEMO_FAIL',1;
    END TRY
    BEGIN CATCH
      IF XACT_STATE()<>0 ROLLBACK;
      SELECT ERROR_NUMBER() AS MaLoi;
    END CATCH;
    SELECT COUNT(*)-@Truoc AS SoDongThem FROM dbo.ChiTietVatTu;`);
  assert.equal(checked.recordsets[0][0].MaLoi, 51009);
  assert.equal(checked.recordsets[1][0].SoDongThem, 0);
});

test("Giao diện gốc: hợp đồng JSON và các trang đọc đủ bảy vai trò", async () => {
  const login = await api("POST", "/auth/login", null, {
    identifier: "0900000001",
    password: "123456",
  });
  assert.equal(login.user.role, "KH");
  assert.ok(login.accessToken);
  const paths = {
    KH: [
      "/app-config",
      "/orders",
      "/users/me",
      "/support/tickets",
      "/technician-applications/me",
      "/payment-options",
    ],
    KTV: [
      "/technicians/me",
      "/orders",
      "/technicians/me/wallet",
      "/technicians/me/income",
      "/wallet-requests",
      "/technicians/me/wallet-transactions",
    ],
    DPV: ["/reports/summary", "/reports/performance", "/orders"],
    CSKH: [
      "/reports/summary",
      "/reports/quality",
      "/reports/monitoring",
      "/support/tickets",
    ],
    KT: [
      "/reports/summary",
      "/reports/finance",
      "/reports/cashflow",
      "/bank-payment-requests",
      "/settlements",
      "/wallet-requests",
    ],
    GD: [
      "/reports/summary",
      "/reports/quality",
      "/reports/performance",
      "/reports/cashflow",
      "/reports/monitoring",
      "/director/policy-proposals",
    ],
    ADMIN: [
      "/reports/summary",
      "/users",
      "/settings",
      "/audit-logs",
      "/admin/services",
      "/technician-applications",
      "/bank-accounts",
    ],
  };
  for (const [role, routes] of Object.entries(paths)) {
    for (const route of [...routes, "/notifications", "/attention-summary"])
      await api("GET", "/web" + route, role);
  }
  const tech = await api("GET", "/web/technicians/me", "KTV");
  assert.equal(tech.id, users.KTV.Id);
  assert.equal(typeof tech.balance, "number");
  assert.ok(tech.walletEligibility);
  const catalog = await api("GET", "/web/services", "KH");
  assert.ok(catalog[0].name);
  assert.ok(catalog[0].groupCode);
  for (const suffix of [
    "",
    "/history",
    "/materials",
    "/acceptances",
    "/attachments",
    "/reviews",
    "/notes",
    "/payment-details",
  ])
    await api("GET", "/web/orders/" + orderId + suffix, "KH");
  await api("GET", "/web/reports/finance", "DPV", null, 403);
  for (const role of ["KH", "KTV", "CSKH", "KT"]) {
    await api("GET", "/web/reports/performance", role, null, 403);
    await api("GET", "/web/reports/technicians", role, null, 403);
  }
  await api("GET", "/reports", "KT");
  await api("PATCH", "/web/users/1/role", "KH", { role: "ADMIN" }, 403);
});

test("Giao diện gốc: ảnh đặt đơn, nghiệm thu có chữ ký, ngân hàng và hủy giữ chỗ ví", async () => {
  const image = await upload("KH", "OrderFault");
  const order = await api("POST", "/web/orders", "KH", {
    serviceId: 1,
    address: "Địa chỉ kiểm thử giao diện gốc",
    description: "Kiểm tra ổ cắm điện",
    attachmentIds: [image.Id],
  });
  assert.ok(order.id);
  const id = order.id,
    getOrder = (role) => api("GET", "/web/orders/" + id, role || "KH");
  assert.equal(
    (await api("GET", `/web/orders/${id}/attachments`, "KH"))[0].id,
    image.Id,
  );
  await api("POST", `/web/orders/${id}/preliminary-quotes`, "DPV", {
    diagnosis: "Cần sửa đường dây và ổ cắm",
    expectedVersion: (await getOrder("DPV")).version,
  });
  let d = await getOrder();
  await api(
    "POST",
    `/web/orders/${id}/preliminary-quotes/${d.currentPreliminaryQuote.id}/decision`,
    "KH",
    {
      decision: "Approved",
      expectedVersion: d.currentPreliminaryQuote.version,
    },
  );
  await api("POST", `/web/orders/${id}/assignments`, "DPV", {
    technicianId: users.KTV.Id,
    expectedVersion: (await getOrder("DPV")).version,
  });
  d = await getOrder("KTV");
  await api(
    "POST",
    `/web/assignments/${d.currentAssignment.id}/decision`,
    "KTV",
    { decision: "Accepted", expectedVersion: d.currentAssignment.version },
  );
  for (const nextStatus of ["DangDiChuyen", "DaDenNoi", "DangXuLy"])
    await api("PATCH", `/web/orders/${id}/progress`, "KTV", {
      nextStatus,
      expectedVersion: (await getOrder("KTV")).version,
    });
  for (const unitPrice of ["", null, -1])
    await api(
      "POST",
      `/web/orders/${id}/materials`,
      "KTV",
      {
        items: [{ name: "Vật tư sai giá", quantity: 1, unitPrice }],
        expectedVersion: (await getOrder("KTV")).version,
      },
      409,
    );
  await api("POST", `/web/orders/${id}/materials`, "KTV", {
    items: [
      {
        name: "Vật tư qua web",
        quantity: 2,
        unitPrice: 50000,
        warrantyMonths: 6,
      },
    ],
    expectedVersion: (await getOrder("KTV")).version,
  });
  const photo = await upload("KTV", "AcceptancePhoto", id),
    signature = await upload("KTV", "TechnicianSignature", id);
  await api("POST", `/web/orders/${id}/acceptances`, "KTV", {
    cause: "Hỏng dây dẫn",
    solution: "Thay dây và kiểm tra",
    photoIds: [photo.Id],
    technicianSignatureId: signature.Id,
    expectedVersion: (await getOrder("KTV")).version,
  });
  let a = (await api("GET", `/web/orders/${id}/acceptances`, "KH"))[0];
  assert.equal(a.technicianSignatureId, signature.Id);
  await api("POST", `/web/orders/${id}/acceptances/${a.id}/decision`, "KH", {
    decision: "Rejected",
    reason: "Cần kiểm tra lại ổ cắm",
    expectedVersion: a.version,
  });
  assert.equal((await getOrder()).status, "DangXuLy");
  const oldList = (await api("GET", `/web/orders/${id}/materials`, "KTV"))[0];
  const connection = await pool();
  await assert.rejects(
    connection.request()
      .query(`SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
    UPDATE dbo.ChiTietVatTu SET DonGia=1 WHERE BangKeVatTuId=${oldList.id};`),
    /Vật tư đã lập nghiệm thu/,
  );
  await api("POST", `/web/orders/${id}/materials`, "KTV", {
    items: [
      {
        name: "Vật tư điều chỉnh sau kiểm tra",
        quantity: 2,
        unitPrice: 60000,
        warrantyMonths: 6,
      },
    ],
    expectedVersion: (await getOrder("KTV")).version,
  });
  const oldInvoice = (
    await api("GET", `/web/orders/${id}/acceptances`, "KH")
  ).find((row) => row.id === a.id);
  assert.equal(oldInvoice.materialTotal, 100000);
  assert.equal(oldInvoice.status, "Rejected");
  await api("POST", `/web/orders/${id}/acceptances`, "KTV", {
    cause: "Hỏng dây dẫn",
    solution: "Đã kiểm tra lại đầy đủ",
    photoIds: [photo.Id],
    technicianSignatureId: signature.Id,
    expectedVersion: (await getOrder("KTV")).version,
  });
  a = (await api("GET", `/web/orders/${id}/acceptances`, "KH"))[0];
  const customerSignature = await upload("KH", "CustomerSignature", id);
  await api("POST", `/web/orders/${id}/acceptances/${a.id}/decision`, "KH", {
    decision: "Approved",
    signatureId: customerSignature.Id,
    paymentMethod: "BANK",
    bankAccountId: 1,
    expectedVersion: a.version,
  });
  const details = await api("GET", `/web/orders/${id}/payment-details`, "KH");
  assert.equal(details.requests[0].status, "AwaitingTransfer");
  const proof = await upload("KH", "PaymentProof", id);
  await api("POST", `/web/orders/${id}/payments/bank`, "KH", {
    bankAccountId: 1,
    proofId: proof.Id,
    customerReference: "WEB-BANK-TEST",
  });
  const request = (await api("GET", "/web/bank-payment-requests", "KT")).find(
    (r) => r.orderId === id,
  );
  await api("POST", `/web/payment-requests/${request.id}/decision`, "KT", {
    decision: "Confirmed",
    receivedAmount: request.amount,
    bankReference: "WEB-BANK-TEST",
    expectedVersion: request.version,
  });
  assert.equal((await getOrder()).status, "HoanThanh");
  const settlement = (await api("GET", "/web/settlements", "KT")).find(
    (row) => row.orderId === id,
  );
  assert.equal(settlement.materialTotal, 120000);
  assert.equal(
    Number(settlement.amount),
    Number(settlement.inspectionFee) +
      Number(settlement.laborFee) +
      Number(settlement.materialTotal),
  );

  const wallet = await api("POST", "/web/wallet-requests", "KTV", {
    type: "Withdrawal",
    amount: 1000,
    note: "Kiểm tra hủy giữ chỗ",
  });
  await api("POST", `/web/wallet-requests/${wallet.id}/cancel`, "KTV", {
    expectedVersion: wallet.version,
  });
  assert.equal(
    (await api("GET", "/web/wallet-requests", "KTV")).find(
      (r) => r.id === wallet.id,
    ).status,
    "Cancelled",
  );
});

test("Web DBMS: đăng ký không OTP, chặn giả vai trò và thu hồi phiên sau đổi mật khẩu", async () => {
  const phone = "0998888777";
  const created = await api("POST", "/auth/register", null, {
    fullName: "Khách hàng kiểm thử không OTP",
    phone,
    password: "123456",
    VaiTro: "ADMIN",
    role: "ADMIN",
    MatKhauBam: "invalid-client-hash",
  });
  assert.equal(created.VaiTro, "KH");
  const login = await api("POST", "/auth/login", null, {
    identifier: phone,
    password: "123456",
  });
  tokens.NOOTP = login.token;
  assert.equal(login.user.email, null);
  await api(
    "POST",
    "/web/users/me/password",
    "NOOTP",
    { currentPassword: "wrong", newPassword: "654321" },
    400,
  );
  await api("GET", "/web/users/me", "NOOTP");
  await api("POST", "/web/users/me/password", "NOOTP", {
    currentPassword: "123456",
    newPassword: "654321",
  });
  await api("GET", "/web/users/me", "NOOTP", null, 401);
  await api(
    "POST",
    "/auth/login",
    null,
    { identifier: phone, password: "123456" },
    401,
  );
  const changed = await api("POST", "/auth/login", null, {
    identifier: phone,
    password: "654321",
  });
  tokens.NOOTP = changed.token;
  await api("GET", "/web/users/me", "NOOTP");
  await api(
    "PATCH",
    "/web/users/me",
    "NOOTP",
    {
      fullName: changed.user.fullName,
      email: "changed@example.invalid",
      defaultAddress: "Địa chỉ thử",
      expectedVersion: changed.user.version,
    },
    400,
  );
  const summary = await api("GET", "/web/reports/summary", "KT");
  const localDay = new Date().toLocaleDateString("en-CA", {
    timeZone: "Asia/Ho_Chi_Minh",
  });
  assert.ok(summary.trend.some((row) => row.day === localDay));
  const report = await api("GET", "/reports", "KT");
  assert.ok(report.DoanhThu.some((row) => row.Ngay.slice(0, 10) === localDay));
  const publicConfig = await api("GET", "/web/app-config", "NOOTP");
  assert.ok(
    !Object.keys(publicConfig).some((k) =>
      /^(GiamSat_|DeXuatChinhSach_)/.test(k),
    ),
  );
});

test("Tiếng Việt: nhãn UI không chứa ký tự bị thay bằng dấu hỏi hoặc chuỗi sai mã hóa", async () => {
  const { parse } = await import("@babel/parser");
  const problems = [];
  for (const folder of ["frontend/src", "backend/src"]) {
    for (const name of fs.readdirSync(path.join(source, folder))) {
      if (!/\.(jsx|js)$/.test(name)) continue;
      const text = fs.readFileSync(path.join(source, folder, name), "utf8");
      const ast = parse(text, { sourceType: "module", plugins: ["jsx"] });
      const visit = (node) => {
        if (!node || typeof node !== "object") return;
        if (
          ["StringLiteral", "JSXText", "TemplateElement"].includes(node.type)
        ) {
          const value =
            typeof node.value === "string" ? node.value : node.value?.raw;
          if (
            value &&
            !/^\s*(?:\/|https?:)/.test(value) &&
            /[\p{L}]\?[\p{L}]|\uFFFD|\u00e1\u00ba|\u00c3\u00a1/u.test(value)
          )
            problems.push(
              `${folder}/${name}:${node.loc.start.line}: ${value.trim()}`,
            );
        }
        for (const [key, value] of Object.entries(node)) {
          if (["loc", "extra"].includes(key)) continue;
          if (Array.isArray(value)) value.forEach(visit);
          else if (value && typeof value === "object") visit(value);
        }
      };
      visit(ast);
    }
  }
  assert.deepEqual(problems, []);
});

test("Tra cứu: tìm không dấu trước phân trang; giữ giới hạn chủ đơn và nhóm dịch vụ", async () => {
  const response = await fetch(
    base +
      "/web/orders?search=" +
      encodeURIComponent("HF-" + String(orderId).padStart(6, "0")),
    {
      headers: { Authorization: "Bearer " + tokens.KH },
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.meta.total, 1);
  assert.equal(body.data[0].id, orderId);
  assert.equal(
    (await api("GET", "/web/orders?search=zzzz_no_match", "KH")).length,
    0,
  );
  tokens.KH2 = (
    await api("POST", "/auth/login", null, {
      SoDienThoai: "0911111111",
      MatKhau: "654321",
    })
  ).token;
  assert.deepEqual(
    await api(
      "GET",
      "/web/orders?search=HF-" + String(orderId).padStart(6, "0"),
      "KH2",
    ),
    [],
  );
  const electrical = await api("GET", "/web/orders?serviceGroup=DIEN", "DPV");
  assert.ok(electrical.length > 0);
  assert.ok(electrical.every((row) => row.groupCode === "DIEN"));
  const tickets = await api("GET", "/web/support/tickets", "CSKH");
  assert.ok(tickets.length > 0);
  assert.ok(tickets.every((row) => row.customerName && row.customerPhone));
  const users = await api(
    "GET",
    "/web/users?search=" + encodeURIComponent("ky thuat vien"),
    "ADMIN",
  );
  assert.ok(users.length > 0);
  assert.ok(users.every((row) => row.role === "KTV"));
  assert.equal(
    (await api("GET", "/web/orders?serviceGroup=KHONG_CO", "DPV")).length,
    0,
  );
  for (const role of ["KH", "KTV", "DPV", "CSKH", "GD", "ADMIN"])
    await api("POST", "/web/settlements/1/confirm", role, {}, 403);
});

async function assignedOrder(state = "DaTiepNhan") {
  const order = await api("POST", "/web/orders", "KH", {
    serviceId: 1,
    address: "24 Võ Văn Ngân, Thủ Đức",
    description: "Đơn kiểm tra hỗ trợ và hủy dịch vụ",
  });
  const id = order.id,
    read = (role = "KH") => api("GET", "/web/orders/" + id, role);
  await api("POST", `/web/orders/${id}/preliminary-quotes`, "DPV", {
    diagnosis: "Kiểm tra thiết bị",
    expectedVersion: order.version,
  });
  let current = await read();
  await api(
    "POST",
    `/web/orders/${id}/preliminary-quotes/${current.currentPreliminaryQuote.id}/decision`,
    "KH",
    {
      decision: "Approved",
      expectedVersion: current.currentPreliminaryQuote.version,
    },
  );
  current = await read("DPV");
  await api("POST", `/web/orders/${id}/assignments`, "DPV", {
    technicianId: users.KTV.Id,
    expectedVersion: current.version,
  });
  current = await read("KTV");
  await api(
    "POST",
    `/web/assignments/${current.currentAssignment.id}/decision`,
    "KTV",
    {
      decision: "Accepted",
      expectedVersion: current.currentAssignment.version,
    },
  );
  for (const next of ["DangDiChuyen", "DaDenNoi", "DangXuLy"]) {
    if (state === "DaTiepNhan") break;
    current = await read("KTV");
    await api("PATCH", `/web/orders/${id}/progress`, "KTV", {
      nextStatus: next,
      expectedVersion: current.version,
    });
    if (next === state) break;
  }
  return { id, read };
}

test("Hỗ trợ: đặt đơn không tự tạo phiếu; KH gửi, CSKH tiếp nhận, trao đổi và kết thúc đúng quyền", async () => {
  const p = await pool(),
    count = async () =>
      Number(
        (await p.request().query("SELECT COUNT(*) AS N FROM dbo.YeuCauHoTro"))
          .recordset[0].N,
      );
  const before = await count();
  const order = await api("POST", "/web/orders", "KH", {
    serviceId: 1,
    address: "56 Hoàng Diệu 2, Thủ Đức",
    description: "Đặt đơn không tự tạo hỗ trợ",
  });
  assert.equal(await count(), before);
  assert.equal((await api("GET", "/web/attention-summary", "KH")).support, 0);
  const options = await api("GET", "/web/support/order-options", "KH");
  assert.ok(options.some((o) => o.id === order.id));
  assert.ok(options.every((o) => o.customerId === users.KH.Id));
  const ticket = await api("POST", "/web/support/tickets", "KH", {
    orderId: order.id,
    type: "Complaint",
    description: "Cần hỏi lại thời gian KTV đến nhà",
  });
  assert.equal(ticket.status, "Open");
  await api(
    "POST",
    "/web/support/tickets",
    "KH",
    {
      orderId: order.id,
      type: "Complaint",
      description: "Gửi trùng phiếu đang mở",
    },
    409,
  );
  await api("GET", `/web/support/tickets/${ticket.id}`, "KH2", null, 403);
  await api(
    "POST",
    `/web/support/tickets/${ticket.id}/messages`,
    "CSKH",
    { text: "Chưa tiếp nhận" },
    403,
  );
  await api(
    "POST",
    `/web/support/tickets/${ticket.id}/messages`,
    "KH2",
    { text: "Sai khách hàng" },
    403,
  );
  await api(
    "PATCH",
    `/web/support/tickets/${ticket.id}`,
    "KH",
    { status: "Resolved", expectedVersion: ticket.version },
    403,
  );
  await api("PATCH", `/web/support/tickets/${ticket.id}`, "CSKH", {
    status: "InProgress",
    resolution: "Đã tiếp nhận yêu cầu",
    expectedVersion: ticket.version,
  });
  await api(
    "PATCH",
    `/web/support/tickets/${ticket.id}`,
    "CSKH",
    {
      status: "Resolved",
      resolution: "Phiên bản cũ",
      expectedVersion: ticket.version,
    },
    409,
  );
  await api("POST", `/web/support/tickets/${ticket.id}/messages`, "KH", {
    text: "Tôi có mặt tại nhà sau 14 giờ",
  });
  await api("POST", `/web/support/tickets/${ticket.id}/messages`, "CSKH", {
    text: "KTV sẽ đến sau 14 giờ theo yêu cầu",
  });
  let detail = await api("GET", `/web/support/tickets/${ticket.id}`, "KH");
  assert.equal(detail.handlerId, users.CSKH.Id);
  assert.equal(detail.history[0].status, "InProgress");
  assert.ok(detail.history.some((h) => h.authorRole === "KH"));
  assert.ok(detail.history.some((h) => h.authorRole === "CSKH"));
  await api("PATCH", `/web/support/tickets/${ticket.id}`, "CSKH", {
    status: "Resolved",
    resolution: "Đã thống nhất lịch đến với khách",
    expectedVersion: detail.version,
  });
  detail = await api("GET", `/web/support/tickets/${ticket.id}`, "KH");
  assert.equal(detail.status, "Resolved");
  assert.equal(detail.history.at(-1).status, "Resolved");
  await api(
    "POST",
    `/web/support/tickets/${ticket.id}/messages`,
    "KH",
    { text: "Phiếu đã đóng" },
    409,
  );
  const second = await api("POST", "/web/support/tickets", "KH", {
    orderId: order.id,
    type: "Complaint",
    description: "Phiếu tiếp theo cần có lý do từ chối",
  });
  await api(
    "PATCH",
    `/web/support/tickets/${second.id}`,
    "CSKH",
    { status: "Rejected", expectedVersion: second.version },
    409,
  );
  await api("PATCH", `/web/support/tickets/${second.id}`, "CSKH", {
    status: "Rejected",
    resolution: "Yêu cầu không thuộc phạm vi dịch vụ",
    expectedVersion: second.version,
  });
});

test("Hủy đơn: miễn phí trước di chuyển; phí 60000 chỉ BANK, đối soát cộng đủ ví, không làm hỏng đơn mới của KTV", async () => {
  const p = await pool();
  const free = await assignedOrder();
  let d = await free.read();
  await api("POST", `/web/orders/${free.id}/cancel`, "KH", {
    reason: "Khách thay đổi lịch trước khi thợ đi",
    expectedVersion: d.version,
  });
  d = await free.read();
  assert.equal(d.status, "Huy");
  assert.equal(d.cancellationFee, 0);
  assert.equal(d.total, 0);
  const late = await assignedOrder("DangDiChuyen");
  d = await late.read();
  for (const body of [
    {},
    { acceptCancellationFee: true, expectedCancellationFee: 1 },
  ])
    await api(
      "POST",
      `/web/orders/${late.id}/cancel`,
      "KH",
      { reason: "Khách thay đổi lịch", expectedVersion: d.version, ...body },
      409,
    );
  await api(
    "POST",
    `/web/orders/${late.id}/cancel`,
    "KH2",
    { reason: "Không phải chủ đơn", expectedVersion: d.version },
    403,
  );
  await api("POST", `/web/orders/${late.id}/cancel`, "KH", {
    reason: "Khách bận, đồng ý phí di chuyển",
    expectedVersion: d.version,
    acceptCancellationFee: true,
    expectedCancellationFee: 60000,
  });
  d = await late.read();
  assert.equal(d.status, "Huy");
  assert.equal(d.total, 60000);
  assert.equal(d.cancellationFee, 60000);
  assert.equal(d.paymentMethod, "BANK");
  await api("POST", `/web/orders/${late.id}/payments/cod`, "KTV", {}, 409);
  await api(
    "POST",
    `/web/orders/${late.id}/payment-method`,
    "KH",
    { method: "COD", expectedVersion: d.version },
    409,
  );
  const another = await assignedOrder();
  const balance = (await api("GET", "/web/technicians/me/wallet", "KTV"))
    .balance;
  const bank = (
    await api("GET", "/web/orders/" + late.id + "/payment-details", "KH")
  ).requests[0];
  assert.equal(bank.amount, 60000);
  assert.equal(bank.status, "AwaitingTransfer");
  const proof = await upload("KH", "PaymentProof", late.id);
  await api("POST", `/web/orders/${late.id}/payments/bank`, "KH", {
    bankAccountId: bank.bankAccountId,
    proofId: proof.Id,
    customerReference: "CANCEL-ONE",
  });
  await api(
    "POST",
    `/web/orders/${late.id}/payments/bank`,
    "KH",
    {
      bankAccountId: bank.bankAccountId,
      proofId: proof.Id,
      customerReference: "CANCEL-ONE",
    },
    409,
  );
  const request = (await api("GET", "/web/bank-payment-requests", "KT")).find(
    (r) => r.orderId === late.id,
  );
  assert.equal(request.paymentType, "PhiHuyDon");
  assert.equal(request.acceptanceId, null);
  const confirmation = {
    decision: "Approved",
    receivedAmount: 60000,
    bankReference: "CANCEL-ONE",
    expectedVersion: request.version,
  };
  await api(
    "POST",
    `/web/payment-requests/${request.id}/decision`,
    "KT",
    { ...confirmation, receivedAmount: 59999 },
    409,
  );
  await api(
    "POST",
    `/web/payment-requests/${request.id}/decision`,
    "KT",
    confirmation,
  );
  await api(
    "POST",
    `/web/payment-requests/${request.id}/decision`,
    "KT",
    confirmation,
    409,
  );
  assert.equal((await late.read()).status, "Huy");
  assert.equal((await late.read()).paymentStatus, "Paid");
  assert.equal((await another.read()).status, "DaTiepNhan");
  assert.equal(
    (await api("GET", "/web/technicians/me", "KTV")).availability,
    "DangBan",
  );
  const settlement = (await api("GET", "/web/settlements", "KT")).find(
    (r) => r.orderId === late.id,
  );
  assert.equal(settlement.commissionAmount, 0);
  assert.equal(settlement.travelFee, 60000);
  await api("POST", `/web/settlements/${settlement.id}/confirm`, "KT", {
    expectedVersion: settlement.version,
  });
  await api(
    "POST",
    `/web/settlements/${settlement.id}/confirm`,
    "KT",
    { expectedVersion: settlement.version },
    409,
  );
  assert.equal(
    (await api("GET", "/web/technicians/me/wallet", "KTV")).balance,
    Number(balance) + 60000,
  );
  const invoiceCount = (
    await p
      .request()
      .query(
        `SELECT COUNT(*) AS N FROM dbo.PhieuNghiemThu WHERE DonHangId IN (${free.id},${late.id})`,
      )
  ).recordset[0].N;
  assert.equal(invoiceCount, 0);
  d = await another.read();
  await api("POST", `/web/orders/${another.id}/cancel`, "KH", {
    reason: "Hủy miễn phí đơn kế tiếp",
    expectedVersion: d.version,
  });
  const second = await assignedOrder("DaDenNoi");
  d = await second.read();
  await api("POST", `/web/orders/${second.id}/cancel`, "KH", {
    reason: "Hủy khi thợ đã đến",
    expectedVersion: d.version,
    acceptCancellationFee: true,
    expectedCancellationFee: 60000,
  });
  const proof2 = await upload("KH", "PaymentProof", second.id);
  await api("POST", `/web/orders/${second.id}/payments/bank`, "KH", {
    bankAccountId: bank.bankAccountId,
    proofId: proof2.Id,
    customerReference: "CANCEL-TWO",
  });
  const request2 = (await api("GET", "/web/bank-payment-requests", "KT")).find(
    (r) => r.orderId === second.id,
  );
  await api("POST", `/web/payment-requests/${request2.id}/decision`, "KT", {
    decision: "Approved",
    receivedAmount: 60000,
    bankReference: "CANCEL-TWO",
    expectedVersion: request2.version,
  });
  assert.equal((await second.read()).status, "Huy");
  const working = await assignedOrder("DangXuLy");
  d = await working.read();
  await api(
    "POST",
    `/web/orders/${working.id}/cancel`,
    "KH",
    {
      reason: "Không hủy trực tiếp khi đang sửa",
      expectedVersion: d.version,
      acceptCancellationFee: true,
      expectedCancellationFee: 60000,
    },
    403,
  );
  await api("POST", "/web/support/tickets", "KH", {
    orderId: working.id,
    type: "Complaint",
    description: "Xin CSKH hỗ trợ thay đổi khi đang sửa chữa",
  });
  assert.equal(
    (
      await p
        .request()
        .query(
          "SELECT COUNT(*) AS N FROM dbo.vw_ViKyThuatVien WHERE ChenhLech<>0",
        )
    ).recordset[0].N,
    0,
  );
  const summary = await api("GET", "/web/reports/summary", "KT");
  assert.equal(summary.cancellationFees, 120000);
});
