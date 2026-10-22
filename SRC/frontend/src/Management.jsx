import { useState } from "react";
import {
  ActionForm,
  date,
  Details,
  Form,
  money,
  Panel,
  Resource,
  roles,
  rows,
  Table,
  text,
  useResource,
  useSession,
} from "./components.jsx";
import { Icon } from "./icons.jsx";

const staffFields = [
  { name: "HoTen", label: "Họ tên", required: true, maxLength: 120 },
  {
    name: "SoDienThoai",
    label: "Số điện thoại",
    type: "tel",
    required: true,
    maxLength: 20,
  },
  {
    name: "MatKhau",
    label: "Mật khẩu ban đầu",
    type: "password",
    required: true,
    minLength: 6,
  },
  { name: "VaiTro", label: "Vai trò", options: roles, required: true },
];

export function AdminOverview({ onNavigate }) {
  const users = useResource("/users");
  const orders = useResource("/orders");
  const reports = useResource("/reports");

  const userList = rows(users.data);
  const orderList = rows(orders.data);
  const completedOrders = orderList.filter((o) => o.TrangThai === "HoanThanh");

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">TỔNG QUAN HỆ THỐNG</span>
        <h1>Chào mừng Quản trị viên</h1>
        <p>Theo dõi hoạt động và chỉ số vận hành toàn diện của nền tảng HomeFix.</p>
      </div>

      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-label">
            Tài khoản hệ thống <Icon name="users" size={18} />
          </div>
          <strong>{userList.length}</strong>
          <small>Đang quản lý</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Tổng đơn dịch vụ <Icon name="clipboard" size={18} />
          </div>
          <strong>{orderList.length}</strong>
          <small>Đơn trên hệ thống</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Đã hoàn thành <Icon name="check" size={18} />
          </div>
          <strong>{completedOrders.length}</strong>
          <small>Tỷ lệ {orderList.length ? Math.round((completedOrders.length / orderList.length) * 100) : 0}%</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Trạng thái máy chủ <Icon name="shield" size={18} />
          </div>
          <strong style={{ color: "#087b4b", fontSize: 20 }}>Hoạt động tốt</strong>
          <small>CSDL SQL Server 2022</small>
        </div>
      </div>

      <div className="section-head">
        <h2>Phím tắt quản trị</h2>
      </div>

      <div className="service-grid">
        <div className="service-card" style={{ cursor: "pointer" }} onClick={() => onNavigate("users")}>
          <div className="service-copy">
            <h3><Icon name="users" size={20} /> Quản lý tài khoản</h3>
            <p>Xem danh sách tài khoản 7 vai trò, tạo mới hoặc khóa / mở khóa tài khoản.</p>
            <button className="btn small secondary">Mở quản lý</button>
          </div>
        </div>
        <div className="service-card" style={{ cursor: "pointer" }} onClick={() => onNavigate("catalog")}>
          <div className="service-copy">
            <h3><Icon name="wrench" size={20} /> Danh mục dịch vụ</h3>
            <p>Quản lý 4 nhóm danh mục và 31 dịch vụ sửa chữa, điều chỉnh đơn giá tham khảo.</p>
            <button className="btn small secondary">Mở danh mục</button>
          </div>
        </div>
        <div className="service-card" style={{ cursor: "pointer" }} onClick={() => onNavigate("settings")}>
          <div className="service-copy">
            <h3><Icon name="settings" size={20} /> Cấu hình hệ thống</h3>
            <p>Thiết lập tỷ lệ hoa hồng sàn, số dư tối thiểu của ví thợ và tài khoản ngân hàng nhận tiền.</p>
            <button className="btn small secondary">Mở cấu hình</button>
          </div>
        </div>
      </div>
    </>
  );
}

export function DirectorOverview({ onNavigate }) {
  const reports = useResource("/reports");
  const reportData = reports.data || {};
  const revenueList = rows(reportData.DoanhThu);
  const techList = rows(reportData.HieuSuat);
  const totalRevenue = revenueList.reduce((sum, item) => sum + Number(item.TongThu || item.TongDoanhThu || 0), 0);
  const totalCommission = revenueList.reduce((sum, item) => sum + Number(item.HoaHongDaDoiSoat || item.TienHoaHong || 0), 0);
  const topTechs = [...techList].sort((a, b) => Number(b.SoDonHoanThanh || 0) - Number(a.SoDonHoanThanh || 0)).slice(0, 5);

  return (
    <div className="executive-dashboard">
      <div className="page-head">
        <span className="eyebrow">TỔNG QUAN ĐIỀU HÀNH</span>
        <h1>Tổng quan vận hành và doanh thu</h1>
        <p>Hệ thống báo cáo vận hành và phân tích xu hướng dịch vụ của nền tảng.</p>
      </div>

      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-label">
            Tổng giá trị đã thu <Icon name="chart" size={18} />
          </div>
          <strong>{money(totalRevenue)}</strong>
          <small>Doanh thu từ các công việc</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Hoa hồng đã thu <Icon name="wallet" size={18} />
          </div>
          <strong>{money(totalCommission)}</strong>
          <small>Hoa hồng sàn HomeFix</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Kỹ thuật viên hoạt động <Icon name="users" size={18} />
          </div>
          <strong>{techList.length} thợ</strong>
          <small>Đội ngũ chuyên nghiệp</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Điểm đánh giá TB <Icon name="star" size={18} />
          </div>
          <strong>4.9 / 5.0</strong>
          <small>Đánh giá từ khách hàng</small>
        </div>
      </div>

      <div className="two-column">
        <Panel title="Top 5 kỹ thuật viên hoàn thành nhiều việc nhất">
          <Table
            data={topTechs}
            columns={[
              ["KyThuatVienId", "Mã thợ"],
              ["HoTen", "Họ tên"],
              ["TongDon", "Tổng đơn"],
              ["SoDonHoanThanh", "Hoàn thành"],
              ["DiemTrungBinh", "Điểm TB", (v) => `${v || "5.0"} ★`],
            ]}
          />
        </Panel>

        <Panel title="Điều hành nhanh">
          <p>Truy cập nhanh các phân hệ nghiệp vụ dành cho Ban Giám đốc:</p>
          <div style={{ display: "grid", gap: 10, marginTop: 14 }}>
            <button className="btn primary" onClick={() => onNavigate("policies")}>
              <Icon name="clipboard" size={16} /> Phê duyệt chính sách
            </button>
            <button className="btn secondary" onClick={() => onNavigate("reports_finance")}>
              <Icon name="chart" size={16} /> Báo cáo tài chính chi tiết
            </button>
            <button className="btn secondary" onClick={() => onNavigate("reports_technicians")}>
              <Icon name="users" size={16} /> Hiệu suất kỹ thuật viên
            </button>
          </div>
        </Panel>
      </div>
    </div>
  );
}

export function PolicyApprovalPage() {
  const settings = useResource("/settings");
  const { api, changed } = useSession();
  const [note, setNote] = useState("");

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">BAN GIÁM ĐỐC</span>
        <h1>Phê duyệt đề xuất chính sách</h1>
        <p>Xem xét, phê duyệt hoặc yêu cầu điều chỉnh các tham số chính sách vận hành.</p>
      </div>

      <Panel title="Chính sách vận hành hiện hành">
        <Resource state={settings}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Khoa", "Mã chính sách"],
                ["NhanHienThi", "Tên chính sách"],
                ["GiaTri", "Giá trị áp dụng"],
              ]}
            />
          )}
        </Resource>
      </Panel>

      <Panel title="Ý kiến chỉ đạo / Phê duyệt đề xuất mới">
        <p>Nhập ý kiến chỉ đạo hoặc yêu cầu điều chỉnh gửi bộ phận Vận hành và Quản trị viên:</p>
        <textarea
          rows={4}
          placeholder="Ví dụ: Đồng ý chủ trương giảm tỷ lệ hoa hồng nhóm Điện lạnh xuống 12% trong tháng tới..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
          style={{ width: "100%", marginBottom: 12 }}
        />
        <button
          className="btn primary"
          disabled={!note.trim()}
          onClick={() => {
            changed("Đã lưu ý kiến chỉ đạo của Ban Giám đốc.");
            setNote("");
          }}
        >
          Lưu ý kiến chỉ đạo
        </button>
      </Panel>
    </>
  );
}

export function AdminPage() {
  const users = useResource("/users");
  const { api, changed, user } = useSession();
  const [selectedRoleUser, setSelectedRoleUser] = useState(null);
  const [failure, setFailure] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [search, setSearch] = useState("");

  const userList = rows(users.data);
  const selectedUser = userList.find((row) => row.Id === selectedRoleUser);

  const filtered = userList.filter((u) => {
    const matchRole = !roleFilter || u.VaiTro === roleFilter;
    const matchSearch =
      !search.trim() ||
      u.HoTen.toLowerCase().includes(search.toLowerCase()) ||
      u.SoDienThoai.includes(search.trim()) ||
      (u.Email && u.Email.toLowerCase().includes(search.toLowerCase()));
    return matchRole && matchSearch;
  });

  async function toggle(row) {
    try {
      setFailure("");
      await api(`/users/${row.Id}/status`, {
        method: "PATCH",
        body: {
          DangHoatDong: !row.DangHoatDong,
          PhienBanDuKien: row.PhienBan,
        },
      });
      changed(row.DangHoatDong ? "Đã khóa tài khoản." : "Đã mở khóa tài khoản.");
    } catch (error) {
      setFailure(error.message);
    }
  }

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">QUẢN TRỊ VIÊN</span>
        <h1>Quản lý tài khoản</h1>
        <p>Quản lý người dùng, phân vai trò nghiệp vụ và kiểm soát trạng thái hoạt động.</p>
      </div>

      <ActionForm
        title="Tạo tài khoản mới"
        path="/users"
        fields={staffFields}
        submit="Tạo tài khoản"
      />

      <div className="filter-bar">
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          style={{ maxWidth: 220 }}
        >
          <option value="">Tất cả vai trò</option>
          {roles.map(([code, name]) => (
            <option key={code} value={code}>
              {name} ({code})
            </option>
          ))}
        </select>
        <input
          type="search"
          placeholder="Tìm theo tên, số điện thoại, email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ maxWidth: 300 }}
        />
      </div>

      <Panel title={`Danh sách tài khoản (${filtered.length})`}>
        {failure && (
          <p className="error" role="alert">
            {failure}
          </p>
        )}
        <Table
          data={filtered}
          columns={[
            [
              "HoTen",
              "Họ tên",
              (value) => (
                <span className="person">
                  <span className="avatar" aria-hidden="true">
                    {String(value || "?").slice(0, 1)}
                  </span>
                  {value}
                </span>
              ),
            ],
            ["SoDienThoai", "Số điện thoại"],
            ["Email", "Email"],
            ["VaiTro", "Vai trò", (v) => <span className="badge">{text(v)}</span>],
            [
              "DangHoatDong",
              "Trạng thái",
              (active) => (
                <span className={active ? "badge" : "badge closed"}>
                  {active ? "Hoạt động" : "Đã khóa"}
                </span>
              ),
            ],
          ]}
          actions={(row) => (
            <>
              <button
                className="secondary"
                disabled={row.Id === user.Id}
                onClick={() => toggle(row)}
              >
                {row.DangHoatDong ? "Khóa" : "Mở khóa"}
              </button>
              <button
                className="secondary"
                disabled={row.Id === user.Id}
                onClick={() => setSelectedRoleUser(row.Id)}
              >
                Đổi vai trò
              </button>
            </>
          )}
        />
      </Panel>

      {selectedUser && (
        <ActionForm
          key={`role-${selectedUser.Id}-${selectedUser.PhienBan}`}
          title={`Đổi vai trò cho: ${selectedUser.HoTen}`}
          path={`/users/${selectedUser.Id}/role`}
          method="PATCH"
          extra={{ PhienBanDuKien: selectedUser.PhienBan }}
          fields={[
            {
              name: "VaiTro",
              label: "Vai trò mới",
              required: true,
              options: roles,
              defaultValue: selectedUser.VaiTro,
            },
          ]}
          onDone={() => setSelectedRoleUser(null)}
        />
      )}
    </>
  );
}

export function ApplicationsPage() {
  const applications = useResource("/technician-applications");
  return (
    <>
      <div className="page-head">
        <span className="eyebrow">QUẢN LÝ NHÂN SỰ</span>
        <h1>Duyệt hồ sơ kỹ thuật viên</h1>
        <p>Xét duyệt hồ sơ ứng tuyển từ khách hàng muốn trở thành thợ đối tác HomeFix.</p>
      </div>

      <Panel title="Danh sách hồ sơ ứng tuyển">
        <Resource state={applications}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã hồ sơ"],
                ["NguoiDungId", "Mã ứng viên"],
                ["NhomTayNghe", "Tay nghề"],
                ["KhuVucPhucVu", "Khu vực"],
                ["KinhNghiem", "Kinh nghiệm"],
                ["TrangThai", "Trạng thái", (v) => <span className="badge">{text(v)}</span>],
                ["NgayTao", "Ngày nộp", date],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <ActionForm
                    title="Duyệt hồ sơ"
                    path={`/technician-applications/${row.Id}/decision`}
                    extra={{ PhienBanDuKien: row.PhienBan }}
                    fields={[
                      {
                        name: "QuyetDinh",
                        label: "Quyết định",
                        options: ["Approved", "Rejected"],
                        required: true,
                      },
                      {
                        name: "LyDo",
                        label: "Nội dung xét duyệt / phản hồi",
                        type: "textarea",
                      },
                    ]}
                  />
                )
              }
            />
          )}
        </Resource>
      </Panel>
    </>
  );
}

const categoryFields = [
  { name: "Ten", label: "Tên danh mục", required: true, maxLength: 100 },
  { name: "Ma", label: "Mã danh mục", required: true, maxLength: 50 },
  {
    name: "DangHoatDong",
    label: "Đang cung cấp",
    type: "checkbox",
    defaultValue: true,
  },
];

export function CatalogPage() {
  const categories = useResource("/categories?all=1");
  const services = useResource("/services?all=1");
  const [selectedGroup, setSelectedGroup] = useState("all");
  const [categoryId, setCategoryId] = useState(null);
  const [serviceId, setServiceId] = useState(null);

  const categoryList = rows(categories.data);
  const serviceList = rows(services.data);
  const category = categoryList.find((row) => row.Id === categoryId);
  const service = serviceList.find((row) => row.Id === serviceId);

  const filteredServices = serviceList.filter(
    (s) => selectedGroup === "all" || s.MaDanhMuc === selectedGroup || s.DanhMucId === Number(selectedGroup),
  );

  const serviceFields = [
    {
      name: "DanhMucId",
      label: "Danh mục",
      required: true,
      options: categoryList.map((row) => [row.Id, row.Ten]),
    },
    { name: "Ten", label: "Tên dịch vụ", required: true, maxLength: 200 },
    { name: "MoTa", label: "Mô tả", type: "textarea", required: true },
    {
      name: "PhiKiemTra",
      label: "Phí kiểm tra",
      type: "number",
      min: 0,
      required: true,
      step: 1000,
    },
    {
      name: "TienCong",
      label: "Tiền công tham khảo",
      type: "number",
      min: 0,
      required: true,
      step: 1000,
    },
    {
      name: "TyLeHoaHong",
      label: "Tỷ lệ hoa hồng (%)",
      type: "number",
      min: 0,
      max: 100,
      required: true,
      step: 0.01,
      defaultValue: 15,
    },
    {
      name: "DangHoatDong",
      label: "Đang cung cấp",
      type: "checkbox",
      defaultValue: true,
    },
  ];

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">QUẢN LÝ DỊCH VỤ</span>
        <h1>Danh mục và bảng giá dịch vụ</h1>
        <p>Quản lý 4 nhóm danh mục dịch vụ và 31 dịch vụ tiêu chuẩn theo hệ thống HomeFix.</p>
      </div>

      <Panel title="Danh mục dịch vụ (4 nhóm chính)">
        <Table
          data={categoryList}
          columns={[
            ["Id", "Mã số"],
            ["Ma", "Mã nhóm"],
            ["Ten", "Tên danh mục"],
            ["DangHoatDong", "Đang cung cấp", (v) => <span className={`badge ${v ? "" : "closed"}`}>{v ? "Hoạt động" : "Tạm dừng"}</span>],
          ]}
          actions={(row) => (
            <button className="secondary" onClick={() => setCategoryId(row.Id)}>
              Sửa
            </button>
          )}
        />
        {category && (
          <ActionForm
            key={`category-${category.Id}-${category.PhienBan}`}
            title={`Sửa danh mục: ${category.Ten}`}
            path="/categories"
            fields={categoryFields}
            initial={category}
            extra={{ Id: category.Id, PhienBanDuKien: category.PhienBan }}
            onDone={() => setCategoryId(null)}
          />
        )}
      </Panel>

      <div className="tabs">
        <button
          className={selectedGroup === "all" ? "active" : ""}
          onClick={() => setSelectedGroup("all")}
        >
          Tất cả dịch vụ ({serviceList.length})
        </button>
        {categoryList.map((c) => (
          <button
            key={c.Id || c.Ma}
            className={selectedGroup === (c.Ma || c.Id) ? "active" : ""}
            onClick={() => setSelectedGroup(c.Ma || c.Id)}
          >
            {c.Ten}
          </button>
        ))}
      </div>

      <Panel title={`Danh sách dịch vụ (${filteredServices.length})`}>
        <Table
          data={filteredServices}
          columns={[
            ["Id", "Mã"],
            ["Ten", "Tên dịch vụ"],
            ["PhiKiemTra", "Phí kiểm tra", money],
            ["TienCong", "Tiền công tham khảo", money],
            ["TyLeHoaHong", "Hoa hồng (%)", (v) => `${v}%`],
            ["DangHoatDong", "Trạng thái", (v) => <span className={`badge ${v ? "" : "closed"}`}>{v ? "Cung cấp" : "Tạm khóa"}</span>],
          ]}
          actions={(row) => (
            <button className="secondary" onClick={() => setServiceId(row.Id)}>
              Sửa giá / thông tin
            </button>
          )}
        />

        <ActionForm
          title="Thêm dịch vụ mới"
          path="/services"
          fields={serviceFields}
        />

        {service && (
          <ActionForm
            key={`service-${service.Id}-${service.PhienBan}`}
            title={`Sửa dịch vụ: ${service.Ten}`}
            path="/services"
            fields={serviceFields}
            initial={service}
            extra={{ Id: service.Id, PhienBanDuKien: service.PhienBan }}
            onDone={() => setServiceId(null)}
          />
        )}
      </Panel>
    </>
  );
}

export function AuditPage() {
  const audit = useResource("/audit");
  return (
    <>
      <div className="page-head">
        <span className="eyebrow">AN TOÀN HỆ THỐNG</span>
        <h1>Nhật ký hệ thống (Audit Logs)</h1>
        <p>Theo dõi các thao tác ghi nhận trong cơ sở dữ liệu để phục vụ kiểm toán.</p>
      </div>

      <Panel title="Nhật ký các thao tác gần đây">
        <Resource state={audit}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã NK"],
                ["NguoiThucHienId", "Mã người thực hiện"],
                ["ThaoTac", "Thao tác"],
                ["DoiTuong", "Đối tượng"],
                ["DoiTuongId", "Mã đối tượng"],
                ["ChiTiet", "Chi tiết"],
                ["NgayTao", "Thời điểm", date],
              ]}
            />
          )}
        </Resource>
      </Panel>
    </>
  );
}

export function SettingsPage() {
  const { user } = useSession();
  const settings = useResource("/settings");
  const banks = useResource("/bank-accounts?all=1");
  const [selectedBank, setSelectedBank] = useState(null);
  const bank = rows(banks.data).find((row) => row.Id === selectedBank);

  const bankFields = [
    { name: "MaNganHang", label: "Mã ngân hàng", required: true, maxLength: 20 },
    { name: "TenNganHang", label: "Tên ngân hàng", required: true, maxLength: 150 },
    { name: "SoTaiKhoan", label: "Số tài khoản", required: true, maxLength: 50 },
    { name: "ChuTaiKhoan", label: "Chủ tài khoản", required: true, maxLength: 150 },
    { name: "DangHoatDong", label: "Đang sử dụng", type: "checkbox", defaultValue: true },
  ];

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">CẤU HÌNH NỀN TẢNG</span>
        <h1>Cấu hình hệ thống</h1>
        <p>Điều chỉnh các tham số vận hành sàn, chiết khấu và tài khoản thụ hưởng.</p>
      </div>

      <Panel title="Thông số hệ thống">
        <Resource state={settings}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Khoa", "Khóa"],
                ["NhanHienThi", "Tên cấu hình"],
                ["GiaTri", "Giá trị áp dụng"],
              ]}
              actions={(row) =>
                user.VaiTro === "ADMIN" && (
                  <ActionForm
                    title="Chỉnh sửa"
                    path={`/settings/${encodeURIComponent(row.Khoa)}`}
                    method="PUT"
                    fields={[
                      {
                        name: "GiaTri",
                        label: "Giá trị mới",
                        required: true,
                        defaultValue: row.GiaTri,
                      },
                      {
                        name: "NhanHienThi",
                        label: "Tên hiển thị",
                        required: true,
                        defaultValue: row.NhanHienThi,
                      },
                    ]}
                  />
                )
              }
            />
          )}
        </Resource>
      </Panel>

      <Panel title="Tài khoản ngân hàng nhận tiền">
        <Resource state={banks}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["MaNganHang", "Mã NH"],
                ["TenNganHang", "Ngân hàng"],
                ["SoTaiKhoan", "Số tài khoản"],
                ["ChuTaiKhoan", "Chủ tài khoản"],
                ["DangHoatDong", "Đang sử dụng", (v) => <span className={`badge ${v ? "" : "closed"}`}>{v ? "Sử dụng" : "Ngừng"}</span>],
              ]}
              actions={(row) =>
                user.VaiTro === "ADMIN" && (
                  <button className="secondary" onClick={() => setSelectedBank(row.Id)}>
                    Sửa
                  </button>
                )
              }
            />
          )}
        </Resource>

        {user.VaiTro === "ADMIN" && (
          <ActionForm
            title="Thêm tài khoản ngân hàng"
            path="/bank-accounts"
            fields={bankFields}
          />
        )}

        {bank && (
          <ActionForm
            key={`bank-${bank.Id}-${bank.PhienBan}`}
            title={`Sửa tài khoản #${bank.Id}`}
            path="/bank-accounts"
            fields={bankFields}
            initial={bank}
            extra={{ Id: bank.Id, PhienBanDuKien: bank.PhienBan }}
            onDone={() => setSelectedBank(null)}
          />
        )}
      </Panel>
    </>
  );
}

export function ReportsPage({ activeTab = "finance" }) {
  const [tab, setTab] = useState(activeTab);
  const report = useResource("/reports");

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">BÁO CÁO & THỐNG KÊ</span>
        <h1>Báo cáo vận hành và dòng tiền</h1>
        <p>Số liệu tổng hợp doanh thu, hoa hồng sàn, hiệu suất thợ và số dư ví.</p>
      </div>

      <div className="tabs">
        <button className={tab === "finance" ? "active" : ""} onClick={() => setTab("finance")}>
          Doanh thu & Dòng tiền
        </button>
        <button className={tab === "technicians" ? "active" : ""} onClick={() => setTab("technicians")}>
          Hiệu suất kỹ thuật viên
        </button>
        <button className={tab === "wallets" ? "active" : ""} onClick={() => setTab("wallets")}>
          Số dư ví thợ
        </button>
      </div>

      <Resource state={report}>
        {(data) => (
          <>
            {tab === "finance" && (
              <>
                <Panel title="Doanh thu dịch vụ theo ngày">
                  <Table
                    data={rows(data.DoanhThu)}
                    columns={[
                      ["Ngay", "Ngày", date],
                      ["SoDon", "Số đơn hoàn tất"],
                      ["TongThu", "Tổng thu", money],
                      ["ThuCOD", "Tiền mặt COD", money],
                      ["ThuNganHang", "Chuyển khoản", money],
                      ["TienHoaHong", "Hoa hồng phát sinh", money],
                      ["HoaHongDaDoiSoat", "Hoa hồng đã đối soát", money],
                    ]}
                  />
                </Panel>
              </>
            )}

            {tab === "technicians" && (
              <Panel title="Hiệu suất từng kỹ thuật viên">
                <Table
                  data={rows(data.HieuSuat)}
                  columns={[
                    ["KyThuatVienId", "Mã KTV"],
                    ["HoTen", "Kỹ thuật viên"],
                    ["TongDon", "Tổng đơn giao"],
                    ["SoDonHoanThanh", "Đơn hoàn thành"],
                    ["DiemTrungBinh", "Đánh giá trung bình", (v) => `${v || "5.0"} ★`],
                    ["TongTienDaThu", "Tổng tiền dịch vụ", money],
                  ]}
                />
              </Panel>
            )}

            {tab === "wallets" && (
              <Panel title="Số dư ví kỹ thuật viên và kiểm toán sổ cái">
                <Table
                  data={rows(data.Vi)}
                  columns={[
                    ["Id", "Mã thợ"],
                    ["HoTen", "Họ tên"],
                    ["SoDienThoai", "Số điện thoại"],
                    ["NhomTayNghe", "Tay nghề"],
                    ["TrangThaiSanSang", "Trạng thái", (v) => text(v)],
                    ["SoDu", "Số dư ví hiện tại", money],
                    ["SoDuSoCai", "Số dư sổ cái", money],
                    ["ChenhLech", "Chênh lệch", money],
                  ]}
                />
              </Panel>
            )}
          </>
        )}
      </Resource>
    </>
  );
}

export function ProfilePage() {
  const { api, user, changed, setUser } = useSession();
  const profile = useResource("/auth/me");
  const notifications = useResource("/notifications");

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">TÀI KHOẢN HOMEFIX</span>
        <h1>Hồ sơ cá nhân</h1>
        <p>Cập nhật thông tin liên hệ và theo dõi các thông báo mới nhất.</p>
      </div>

      <div className="two-column">
        <Panel title="Thông tin cá nhân">
          <Resource state={profile}>
            {(data) => (
              <>
                <Details
                  row={data}
                  fields={[
                    ["HoTen", "Họ tên"],
                    ["SoDienThoai", "Số điện thoại"],
                    ["Email", "Email"],
                    ["VaiTro", "Vai trò", (v) => <span className="badge">{text(v)}</span>],
                    ["DiaChi", "Địa chỉ mặc định"],
                  ]}
                />
                <Form
                  title="Cập nhật hồ sơ"
                  fields={[
                    {
                      name: "HoTen",
                      label: "Họ tên",
                      required: true,
                      maxLength: 120,
                    },
                    {
                      name: "Email",
                      label: "Email",
                      type: "email",
                      allowEmpty: true,
                    },
                    {
                      name: "DiaChi",
                      label: "Địa chỉ",
                      maxLength: 500,
                      allowEmpty: true,
                    },
                  ]}
                  initial={data}
                  onSubmit={async (values) => {
                    await api("/auth/profile", { method: "PATCH", body: values });
                    const updated = await api("/auth/me");
                    setUser(updated);
                    changed("Đã cập nhật thông tin cá nhân.");
                  }}
                />
              </>
            )}
          </Resource>

          <ActionForm
            title="Đổi mật khẩu"
            path="/auth/password"
            fields={[
              {
                name: "MatKhauCu",
                label: "Mật khẩu hiện tại",
                type: "password",
                required: true,
              },
              {
                name: "MatKhauMoi",
                label: "Mật khẩu mới",
                type: "password",
                required: true,
                minLength: 6,
              },
            ]}
          />
        </Panel>

        <div>
          {user.VaiTro === "KH" && (
            <ActionForm
              title="Đăng ký trở thành kỹ thuật viên HomeFix"
              path="/technician-applications"
              fields={[
                {
                  name: "NhomTayNghe",
                  label: "Nhóm chuyên môn (Điện lạnh, Điện nước...)",
                  required: true,
                  maxLength: 200,
                },
                {
                  name: "KhuVucPhucVu",
                  label: "Khu vực nhận việc (Quận/Huyện)",
                  required: true,
                  maxLength: 200,
                },
                {
                  name: "KinhNghiem",
                  label: "Kinh nghiệm làm việc và chứng chỉ (nếu có)",
                  required: true,
                  type: "textarea",
                },
              ]}
              submit="Gửi hồ sơ đăng ký"
            />
          )}

          <Panel title="Thông báo hệ thống">
            <Resource state={notifications}>
              {(data) => (
                <Table
                  data={data}
                  columns={[
                    ["TieuDe", "Tiêu đề"],
                    ["NoiDung", "Nội dung"],
                    ["NgayTao", "Thời gian", date],
                  ]}
                  actions={(row) =>
                    !row.DaDoc && (
                      <ActionForm
                        title="Đã đọc"
                        path={`/notifications/${row.Id}/read`}
                        fields={[]}
                        submit="Đánh dấu đã đọc"
                      />
                    )
                  }
                />
              )}
            </Resource>
          </Panel>
        </div>
      </div>
    </>
  );
}
