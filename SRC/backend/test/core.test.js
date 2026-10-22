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
  assert.equal(result.status, 0, result.stdout + "\n" + result.stderr);
  ({ sql, databaseConfig, pool, close } = await import("../src/db.js"));
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
  const material = await api("POST", `/orders/${orderId}/materials`, "KTV", {
    VatTu: [
      { Ten: "Vật tư kiểm thử", SoLuong: 2, DonGia: 50000, SoThangBaoHanh: 6 },
    ],
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  await api("POST", `/materials/${material.Id}/decision`, "KH", {
    QuyetDinh: "Approved",
    PhienBanDuKien: material.PhienBan,
  });
  d = await details("KTV");
  const acceptance = await api("POST", `/orders/${orderId}/acceptance`, "KTV", {
    NguyenNhan: "Linh kiện hư",
    PhuongAnXuLy: "Thay linh kiện và chạy thử",
    PhienBanDuKien: d.DonHang.PhienBan,
  });
  assert.equal(acceptance.TongTien, 350000);
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
    PhienBanDuKien: ticket.PhienBan,
  });
  assert.equal(
    (await api("GET", `/support/${ticket.Id}/messages`, "CSKH")).length,
    1,
  );
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
    DECLARE @Truoc INT=(SELECT COUNT(*) FROM dbo.ChiTietDeXuatVatTu);
    BEGIN TRY
      BEGIN TRANSACTION;
      INSERT dbo.DeXuatVatTu(DonHangId,LanSuaDoi,DangApDung,TrangThai,NguoiTaoId)
      VALUES(${orderId},99,0,'Pending',${users.KTV.Id});
      DECLARE @Moi INT=SCOPE_IDENTITY(),@Cu INT=(SELECT MIN(Id) FROM dbo.DeXuatVatTu WHERE DonHangId=${orderId} AND TrangThai='Approved');
      INSERT dbo.ChiTietDeXuatVatTu(DeXuatVatTuId,Ten,SoLuong,DonGia)
      VALUES(@Moi,N'Dòng pending hợp lệ',1,10000),(@Cu,N'Dòng đã duyệt không được sửa',1,20000);
      ROLLBACK;
      THROW 51999,'DEMO_FAIL',1;
    END TRY
    BEGIN CATCH
      IF XACT_STATE()<>0 ROLLBACK;
      SELECT ERROR_NUMBER() AS MaLoi;
    END CATCH;
    SELECT COUNT(*)-@Truoc AS SoDongThem FROM dbo.ChiTietDeXuatVatTu;`);
  assert.equal(checked.recordsets[0][0].MaLoi, 51009);
  assert.equal(checked.recordsets[1][0].SoDongThem, 0);
});
