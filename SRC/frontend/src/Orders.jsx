import { useState } from "react";
import {
  ActionForm,
  date,
  Details,
  FileButton,
  Form,
  money,
  Panel,
  Resource,
  rows,
  Table,
  text,
  UploadForm,
  useResource,
  useSession,
} from "./components.jsx";
import { Icon } from "./icons.jsx";

const orderColumns = [
  ["Id", "Mã đơn"],
  ["TenDichVu", "Dịch vụ"],
  ["TenKhachHang", "Khách hàng"],
  ["TenKyThuatVien", "Kỹ thuật viên"],
  ["TrangThai", "Trạng thái", (v) => <span className={`badge ${v === "HoanThanh" || v === "Huy" ? "closed" : ""}`}>{text(v)}</span>],
  ["NgayTao", "Ngày tạo", date],
];

const decision = {
  name: "QuyetDinh",
  label: "Quyết định",
  required: true,
  options: ["Approved", "Rejected"],
};
const reason = { name: "LyDo", label: "Lý do", type: "textarea" };
const amount = (name, label, defaultValue = 0) => ({
  name,
  label,
  type: "number",
  required: true,
  min: 0,
  step: 1000,
  defaultValue,
});

const popularServiceNames = [
  "Sửa máy lạnh",
  "Vệ sinh máy lạnh",
  "Sửa tủ lạnh",
  "Sửa máy giặt",
  "Sửa điện tại nhà",
  "Sửa máy bơm nước",
  "Thông nghẹt bồn rửa chén",
  "Sửa bồn cầu",
];

const categoryIcons = {
  DienLanh: "snowflake",
  DienGiaDung: "washingMachine",
  DienNuoc: "plugZap",
  VeSinh: "sparkles",
};

export function CustomerDashboard({ onNavigate, onBookService }) {
  const { user } = useSession();
  const services = useResource("/services");
  const orders = useResource("/orders");
  const serviceList = rows(services.data);
  const orderList = rows(orders.data);
  const popular = serviceList
    .filter((s) => popularServiceNames.includes(s.Ten))
    .slice(0, 6);
  const displayServices = popular.length ? popular : serviceList.slice(0, 6);

  return (
    <div className="customer-dashboard">
      <section className="customer-hero">
        <div className="hero-content">
          <span className="eyebrow">CHĂM SÓC NHÀ CỬA, THẬT DỄ DÀNG</span>
          <h1>
            Nhà cần sửa?
            <br />
            <em>Đã có HomeFix.</em>
          </h1>
          <p>
            Chào {user?.HoTen?.split(" ").at(-1) || user?.HoTen || "quý khách"}, đặt dịch vụ ngay để thiết bị trong nhà luôn hoạt động tốt.
          </p>
          <button className="btn primary" onClick={() => onNavigate("services")}>
            Đặt dịch vụ ngay <Icon name="arrowRight" size={17} />
          </button>
          <div className="hero-trust">
            <span>
              <Icon name="shield" size={15} /> Giá rõ ràng
            </span>
            <span>
              <Icon name="check" size={15} /> Đặt lịch thuận tiện
            </span>
          </div>
        </div>
        <div className="hero-visual" aria-hidden="true">
          <div className="hero-circle">
            <Icon name="washingMachine" size={96} />
            <span className="orbit one">
              <Icon name="snowflake" size={24} />
            </span>
            <span className="orbit two">
              <Icon name="plugZap" size={24} />
            </span>
            <span className="orbit three">
              <Icon name="droplets" size={24} />
            </span>
          </div>
          <div className="hero-label">
            <Icon name="shield" size={22} />
            <div>
              <b>An tâm từng dịch vụ</b>
              <small>Xác nhận trước khi sửa chữa</small>
            </div>
          </div>
        </div>
      </section>

      <div className="section-head">
        <div>
          <span className="eyebrow">GIẢI PHÁP CHO NGÔI NHÀ</span>
          <h2>Dịch vụ phổ biến</h2>
        </div>
        <button className="link" onClick={() => onNavigate("services")}>
          Xem tất cả ({serviceList.length}) <Icon name="arrowRight" size={14} />
        </button>
      </div>

      <div className="service-grid">
        {displayServices.map((service, index) => {
          const iconName = categoryIcons[service.MaDanhMuc] || "wrench";
          return (
            <div className="service-card" key={service.Id}>
              <div className={`service-art color-${index % 4}`}>
                <Icon name={iconName} size={46} />
                <span>{service.TenDanhMuc || "Dịch vụ"}</span>
              </div>
              <div className="service-copy">
                <h3>{service.Ten}</h3>
                <p>{service.MoTa || "Dịch vụ sửa chữa và bảo dưỡng chất lượng cao tại nhà."}</p>
                <div className="service-price">
                  <div>
                    <small>Tiền công tham khảo</small>
                    <strong>{money(service.TienCong)}</strong>
                  </div>
                  <button
                    className="circle-arrow"
                    title="Đặt dịch vụ"
                    onClick={() => onBookService ? onBookService(service.Id) : onNavigate("services")}
                  >
                    <Icon name="arrowRight" size={16} />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="section-head">
        <h2>Đơn dịch vụ gần đây</h2>
        <button className="link" onClick={() => onNavigate("orders")}>
          Xem lịch sử <Icon name="arrowRight" size={14} />
        </button>
      </div>

      {orderList.length ? (
        <div className="order-list">
          {orderList.slice(0, 3).map((order) => (
            <div className="order-card" key={order.Id}>
              <div className="order-symbol">
                <Icon name="clipboard" size={24} />
              </div>
              <div className="order-main">
                <span className="badge">{text(order.TrangThai)}</span>
                <h3>{order.TenDichVu}</h3>
                <p>{order.DiaChi}</p>
                <small>Tạo lúc: {date(order.NgayTao)}</small>
              </div>
              <button
                className="secondary"
                onClick={() => onNavigate("orders")}
              >
                Chi tiết
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="empty-card">
          <p>Bạn chưa có đơn dịch vụ nào. Khi cần sửa chữa, hãy đặt dịch vụ ngay.</p>
        </div>
      )}

      <div className="benefit-row">
        <div>
          <Icon name="shield" size={28} />
          <h3>Báo giá minh bạch</h3>
          <p>Xem báo giá và thống nhất chi phí trước khi sửa chữa.</p>
        </div>
        <div>
          <Icon name="clipboard" size={28} />
          <h3>Chủ động thời gian</h3>
          <p>Đặt ngay hoặc chọn lịch hẹn phù hợp.</p>
        </div>
        <div>
          <Icon name="star" size={28} />
          <h3>Lắng nghe phản hồi</h3>
          <p>Đánh giá và gửi yêu cầu hỗ trợ sau dịch vụ.</p>
        </div>
      </div>
    </div>
  );
}

export function ServicesPage({ initialServiceId }) {
  const services = useResource("/services");
  const categories = useResource("/categories");
  const [selectedGroup, setSelectedGroup] = useState("all");
  const [search, setSearch] = useState("");
  const [bookingService, setBookingService] = useState(() => initialServiceId || null);

  const serviceList = rows(services.data);
  const categoryList = rows(categories.data);

  const filtered = serviceList.filter((s) => {
    const matchCategory = selectedGroup === "all" || s.MaDanhMuc === selectedGroup || s.DanhMucId === Number(selectedGroup);
    const matchSearch = !search.trim() || s.Ten.toLowerCase().includes(search.toLowerCase()) || (s.MoTa && s.MoTa.toLowerCase().includes(search.toLowerCase()));
    return matchCategory && matchSearch;
  });

  const activeService = serviceList.find((s) => s.Id === Number(bookingService));

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">DỊCH VỤ TẠI NHÀ</span>
        <h1>Bạn cần HomeFix hỗ trợ gì?</h1>
        <p>Chọn dịch vụ phù hợp. Báo giá chính thức sẽ được gửi để bạn xác nhận trước khi phân công thợ.</p>
      </div>

      <div className="filter-bar">
        <input
          type="search"
          placeholder="Tìm kiếm dịch vụ (ví dụ: Sửa máy lạnh, Sửa điện...)"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ maxWidth: 360 }}
        />
      </div>

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

      {bookingService && activeService && (
        <Panel title={`Đặt dịch vụ: ${activeService.Ten}`}>
          <button className="secondary" onClick={() => setBookingService(null)}>
            Đóng form đặt lịch
          </button>
          <ActionForm
            title="Thông tin yêu cầu"
            path="/orders"
            fields={[
              {
                name: "DichVuId",
                label: "Dịch vụ đã chọn",
                required: true,
                options: [[activeService.Id, activeService.Ten]],
                defaultValue: activeService.Id,
              },
              {
                name: "DiaChi",
                label: "Địa chỉ thực hiện",
                required: true,
                maxLength: 500,
              },
              {
                name: "MoTa",
                label: "Mô tả tình trạng hư hỏng",
                required: true,
                type: "textarea",
              },
              {
                name: "NgayHen",
                label: "Ngày giờ hẹn mong muốn (tùy chọn)",
                type: "datetime-local",
              },
            ]}
            submit="Tạo đơn dịch vụ"
            onDone={() => setBookingService(null)}
          />
        </Panel>
      )}

      <div className="service-grid">
        {filtered.map((service, index) => {
          const iconName = categoryIcons[service.MaDanhMuc] || "wrench";
          return (
            <div className="service-card" key={service.Id}>
              <div className={`service-art color-${index % 4}`}>
                <Icon name={iconName} size={46} />
                <span>{service.TenDanhMuc || "Dịch vụ"}</span>
              </div>
              <div className="service-copy">
                <h3>{service.Ten}</h3>
                <p>{service.MoTa || "Dịch vụ sửa chữa và bảo dưỡng uy tín, báo giá minh bạch."}</p>
                <div className="service-price">
                  <div>
                    <small>Tiền công tham khảo</small>
                    <strong>{money(service.TienCong)}</strong>
                  </div>
                  <button
                    className="btn small primary"
                    onClick={() => setBookingService(service.Id)}
                  >
                    Đặt ngay
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}

export function TechnicianOverview({ onNavigate }) {
  const technician = useResource("/technician/me");
  const orders = useResource("/orders");
  const wallet = useResource("/wallet");
  const { api, changed } = useSession();

  const techRow = rows(technician.data)[0];
  const orderList = rows(orders.data);
  const activeOrders = orderList.filter((o) => !["HoanThanh", "Huy"].includes(o.TrangThai));
  const pendingAssignment = orderList.filter((o) => o.TrangThai === "ChoNhan");
  const isAvailable = techRow?.TrangThaiSanSang === "SanSang";

  async function toggleAvailability() {
    if (!techRow) return;
    const next = isAvailable ? "TamBan" : "SanSang";
    await api("/technician/status", {
      method: "PATCH",
      body: {
        TrangThaiSanSang: next,
        PhienBanDuKien: techRow.PhienBan,
      },
    });
    changed(isAvailable ? "Đã chuyển sang tạm nghỉ." : "Đã bật sẵn sàng nhận việc.");
  }

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">HOMEFIX PARTNER</span>
        <h1>Sẵn sàng cho một ngày làm việc?</h1>
        <p>Theo dõi ca làm, phản hồi lệnh và cập nhật tiến độ tại đây.</p>
      </div>

      {pendingAssignment.length > 0 && (
        <div className="notice warning">
          <div>
            <b>Bạn có {pendingAssignment.length} đơn được phân công đang chờ nhận việc!</b>
            <p>Vui lòng mở mục Công việc để phản hồi sớm nhất.</p>
          </div>
          <button className="btn primary" onClick={() => onNavigate("orders")}>
            Xem đơn ngay
          </button>
        </div>
      )}

      {techRow && (
        <div className="availability-card">
          <div>
            <span className="eyebrow">TRẠNG THÁI LÀM VIỆC</span>
            <h2>
              <span className={`status-dot ${isAvailable ? "on" : ""}`} />
              {isAvailable ? "Sẵn sàng nhận việc" : "Tạm nghỉ"}
            </h2>
            <p>
              {techRow.NhomTayNghe || "Chưa phân nhóm"} · {techRow.KhuVucPhucVu || "Toàn khu vực"}
            </p>
          </div>
          <button
            className={`btn ${isAvailable ? "secondary" : "primary"}`}
            onClick={toggleAvailability}
          >
            {isAvailable ? "Tạm nghỉ" : "Bật sẵn sàng"}
          </button>
        </div>
      )}

      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-label">
            Số dư ví <Icon name="wallet" size={18} />
          </div>
          <strong>{money(techRow?.SoDu || wallet.data?.KyThuatVien?.SoDu || 0)}</strong>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Công việc đang giữ <Icon name="clipboard" size={18} />
          </div>
          <strong>{activeOrders.length}</strong>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Đã hoàn thành <Icon name="check" size={18} />
          </div>
          <strong>{orderList.filter((o) => o.TrangThai === "HoanThanh").length}</strong>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Đánh giá trung bình <Icon name="star" size={18} />
          </div>
          <strong>4.9 / 5.0</strong>
        </div>
      </div>

      <div className="section-head">
        <h2>Công việc cần xử lý ({activeOrders.length})</h2>
        <button className="link" onClick={() => onNavigate("orders")}>
          Xem tất cả <Icon name="arrowRight" size={14} />
        </button>
      </div>

      {activeOrders.length ? (
        <div className="order-list">
          {activeOrders.map((o) => (
            <div className="order-card" key={o.Id}>
              <div className="order-symbol">
                <Icon name="clipboard" size={24} />
              </div>
              <div className="order-main">
                <span className="badge">{text(o.TrangThai)}</span>
                <h3>{o.TenDichVu}</h3>
                <p>Khách hàng: {o.TenKhachHang} · {o.DiaChi}</p>
                <small>Ngày tạo: {date(o.NgayTao)}</small>
              </div>
              <button className="secondary" onClick={() => onNavigate("orders")}>
                Xem ca làm
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="empty-card">
          <p>Chưa có ca làm đang chờ. Hãy bật sẵn sàng để nhận điều phối công việc mới.</p>
        </div>
      )}
    </>
  );
}

export function DispatcherHub() {
  const [tab, setTab] = useState("intake");
  const [selectedId, setSelectedId] = useState(null);
  const orders = useResource("/orders");
  const services = useResource("/services");
  const technicians = useResource("/technicians");

  const orderList = rows(orders.data);
  const serviceList = rows(services.data);

  const intakeOrders = orderList.filter((o) => ["ChoTiepNhan", "ChoDuyetSoBo"].includes(o.TrangThai));
  const assignOrders = orderList.filter((o) => o.TrangThai === "ChoPhanCong");
  const waitingOrders = orderList.filter((o) => o.TrangThai === "ChoNhan");
  const historyOrders = orderList.filter((o) => ["HoanThanh", "Huy"].includes(o.TrangThai));

  const currentList = {
    intake: intakeOrders,
    assign: assignOrders,
    waiting: waitingOrders,
    history: historyOrders,
  }[tab] || intakeOrders;

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">BÀN ĐIỀU PHỐI</span>
        <h1>Công việc điều phối</h1>
        <p>Tiếp nhận, chẩn đoán báo giá sơ bộ và phân công kỹ thuật viên phù hợp.</p>
      </div>

      <div className="tabs">
        <button className={tab === "intake" ? "active" : ""} onClick={() => { setTab("intake"); setSelectedId(null); }}>
          Tiếp nhận & Báo giá ({intakeOrders.length})
        </button>
        <button className={tab === "assign" ? "active" : ""} onClick={() => { setTab("assign"); setSelectedId(null); }}>
          Phân công kỹ thuật viên ({assignOrders.length})
        </button>
        <button className={tab === "waiting" ? "active" : ""} onClick={() => { setTab("waiting"); setSelectedId(null); }}>
          Chờ thợ nhận ({waitingOrders.length})
        </button>
        <button className={tab === "history" ? "active" : ""} onClick={() => { setTab("history"); setSelectedId(null); }}>
          Lịch sử điều phối ({historyOrders.length})
        </button>
      </div>

      <div className="two-column">
        <Panel title={`Danh sách (${currentList.length})`}>
          <Table
            data={currentList}
            columns={[
              ["Id", "Mã"],
              ["TenDichVu", "Dịch vụ"],
              ["TenKhachHang", "Khách hàng"],
              ["TrangThai", "Trạng thái", (v) => <span className="badge">{text(v)}</span>],
            ]}
            actions={(row) => (
              <button
                className={selectedId === row.Id ? "primary" : "secondary"}
                onClick={() => setSelectedId(row.Id)}
              >
                Xử lý
              </button>
            )}
          />
        </Panel>

        <div>
          {selectedId ? (
            <OrderDetail id={selectedId} close={() => setSelectedId(null)} services={serviceList} />
          ) : (
            <div className="empty-card">
              <p>Chọn một đơn dịch vụ ở danh sách bên trái để tiếp nhận, báo giá hoặc phân công thợ.</p>
            </div>
          )}
        </div>
      </div>
    </>
  );
}

export function OrdersPage() {
  const { user } = useSession();
  const [selected, setSelected] = useState(null);
  const [statusFilter, setStatusFilter] = useState("");
  const [search, setSearch] = useState("");
  const orders = useResource("/orders");
  const services = useResource("/services");

  const orderList = rows(orders.data);
  const serviceList = rows(services.data);

  const filtered = orderList.filter((o) => {
    const matchStatus = !statusFilter || o.TrangThai === statusFilter;
    const matchSearch =
      !search.trim() ||
      String(o.Id).includes(search.trim()) ||
      (o.TenDichVu && o.TenDichVu.toLowerCase().includes(search.toLowerCase())) ||
      (o.TenKhachHang && o.TenKhachHang.toLowerCase().includes(search.toLowerCase()));
    return matchStatus && matchSearch;
  });

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">HỆ THỐNG ĐƠN HÀNG</span>
        <h1>{user.VaiTro === "KH" ? "Đơn của tôi" : user.VaiTro === "KTV" ? "Công việc của tôi" : "Đơn sửa chữa & bảo trì"}</h1>
        <p>Theo dõi tiến độ, khảo sát vật tư, nghiệm thu và thanh toán.</p>
      </div>

      <div className="filter-bar">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{ maxWidth: 220 }}
        >
          <option value="">Tất cả trạng thái</option>
          <option value="ChoTiepNhan">Chờ tiếp nhận</option>
          <option value="ChoPhanCong">Chờ phân công</option>
          <option value="ChoNhan">Chờ thợ nhận</option>
          <option value="DaTiepNhan">Đã tiếp nhận</option>
          <option value="DangDiChuyen">Đang di chuyển</option>
          <option value="DaDenNoi">Đã đến nơi</option>
          <option value="DangXuLy">Đang xử lý</option>
          <option value="HoanThanh">Hoàn thành</option>
          <option value="Huy">Đã hủy</option>
        </select>
        <input
          type="search"
          placeholder="Tìm theo mã đơn, tên dịch vụ, khách..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ maxWidth: 300 }}
        />
      </div>

      <Panel title={`Danh sách đơn (${filtered.length})`}>
        <Table
          data={filtered}
          columns={orderColumns}
          actions={(row) => (
            <button className="primary" onClick={() => setSelected(row.Id)}>
              Chi tiết #{row.Id}
            </button>
          )}
        />
      </Panel>

      {selected && (
        <OrderDetail
          key={selected}
          id={selected}
          close={() => setSelected(null)}
          services={serviceList}
        />
      )}
    </>
  );
}

export function OrderDetail({ id, close, services }) {
  const detail = useResource(`/orders/${id}`);
  return (
    <Panel title={`Chi tiết đơn #${id}`}>
      <button className="secondary" onClick={close} style={{ marginBottom: 16 }}>
        Đóng chi tiết
      </button>
      <Resource state={detail}>
        {(data) => <OrderContent data={data} services={services} />}
      </Resource>
    </Panel>
  );
}

function OrderContent({ data, services }) {
  const { user } = useSession();
  const order = rows(data.DonHang)[0];
  if (!order) return <p className="empty">Không tìm thấy đơn.</p>;
  const role = user.VaiTro;
  const customer = role === "KH" && user.Id === order.KhachHangId;
  const technician = role === "KTV" && user.Id === order.KyThuatVienId;
  const dispatcher = role === "DPV";
  const open = !["HoanThanh", "Huy"].includes(order.TrangThai);
  const quote = rows(data.BaoGiaSoBo)[0];
  const assignments = rows(data.LenhDieuPhoi);
  const proposal =
    rows(data.DeXuatVatTu).find((row) => row.DangApDung) ||
    rows(data.DeXuatVatTu).at(-1);
  const acceptance =
    rows(data.NghiemThu).find((row) =>
      ["Pending", "Approved"].includes(row.TrangThai),
    ) || rows(data.NghiemThu).at(-1);
  const files = rows(data.TepDinhKem);
  const signatures = (purpose) =>
    files
      .filter((file) => file.MucDich === purpose && file.ChuSoHuuId === user.Id)
      .map((file) => [file.Id, `#${file.Id} — ${file.TenTepGoc}`]);
  const service = services.find((row) => row.Id === order.DichVuId);
  const nextStatus = {
    DaTiepNhan: "DangDiChuyen",
    DangDiChuyen: "DaDenNoi",
    DaDenNoi: "DangXuLy",
  }[order.TrangThai];

  return (
    <div className="order-detail">
      <Details
        row={order}
        fields={[
          ["TenDichVu", "Dịch vụ"],
          ["TrangThai", "Trạng thái", (v) => <span className="badge">{text(v)}</span>],
          ["TenKhachHang", "Khách hàng"],
          ["TenKyThuatVien", "Kỹ thuật viên"],
          ["DiaChi", "Địa chỉ"],
          ["MoTa", "Tình trạng"],
          ["NgayHen", "Lịch hẹn", date],
          ["NgayTao", "Ngày tạo", date],
        ]}
      />

      {dispatcher &&
        ["ChoTiepNhan", "ChoDuyetSoBo"].includes(order.TrangThai) &&
        quote?.TrangThai !== "Approved" && (
          <ActionForm
            key={`quote-${order.PhienBan}`}
            title="Lập / điều chỉnh báo giá sơ bộ"
            path={`/orders/${order.Id}/quote`}
            extra={{ PhienBanDuKien: order.PhienBan }}
            fields={[
              amount(
                "PhiKiemTra",
                "Phí kiểm tra",
                quote?.PhiKiemTra ?? service?.PhiKiemTra ?? 0,
              ),
              amount(
                "TienCong",
                "Tiền công",
                quote?.TienCong ?? service?.TienCong ?? 0,
              ),
              {
                name: "TyLeHoaHong",
                label: "Tỷ lệ hoa hồng (%)",
                type: "number",
                required: true,
                min: 0,
                max: 100,
                step: 0.01,
                defaultValue: quote?.TyLeHoaHong ?? service?.TyLeHoaHong ?? 15,
              },
              {
                name: "ChanDoan",
                label: "Chẩn đoán sơ bộ",
                type: "textarea",
                required: true,
                defaultValue: quote?.ChanDoan,
              },
            ]}
          />
        )}

      <h3>Báo giá sơ bộ</h3>
      <Table
        data={data.BaoGiaSoBo}
        columns={[
          ["Id", "Mã"],
          ["PhiKiemTra", "Phí kiểm tra", money],
          ["TienCong", "Tiền công", money],
          ["TongTien", "Tổng sơ bộ", money],
          ["ChanDoan", "Chẩn đoán"],
          ["TrangThai", "Trạng thái"],
        ]}
      />
      {customer && quote?.TrangThai === "Pending" && (
        <ActionForm
          key={`decide-quote-${quote.PhienBan}`}
          title="Duyệt báo giá sơ bộ"
          path={`/quotes/${quote.Id}/decision`}
          extra={{ PhienBanDuKien: quote.PhienBan }}
          fields={[decision, reason]}
        />
      )}

      {dispatcher && order.TrangThai === "ChoPhanCong" && (
        <AssignmentForm order={order} />
      )}

      <h3>Điều phối kỹ thuật viên</h3>
      <Table
        data={assignments}
        columns={[
          ["Id", "Mã"],
          ["KyThuatVienId", "Mã thợ"],
          ["TenKyThuatVien", "Kỹ thuật viên"],
          ["TrangThai", "Phản hồi"],
          ["NgayTao", "Ngày phân công", date],
        ]}
      />
      {assignments
        .filter(
          (row) =>
            row.TrangThai === "Pending" &&
            row.KyThuatVienId === user.Id &&
            role === "KTV",
        )
        .map((row) => (
          <ActionForm
            key={`respond-${row.Id}-${row.PhienBan}`}
            title={`Phản hồi phân công #${row.Id}`}
            path={`/assignments/${row.Id}/respond`}
            extra={{ PhienBanDuKien: row.PhienBan }}
            fields={[
              { ...decision, options: ["Accepted", "Rejected"] },
              reason,
            ]}
          />
        ))}

      {technician && nextStatus && (
        <ActionForm
          title={`Cập nhật tiến độ: ${text(nextStatus)}`}
          path={`/orders/${order.Id}/status`}
          method="PATCH"
          extra={{
            PhienBanDuKien: order.PhienBan,
            TrangThaiTiepTheo: nextStatus,
          }}
          fields={[reason]}
        />
      )}

      {(customer || dispatcher) && open && (
        <ActionForm
          title="Hủy đơn (theo điều kiện cho phép)"
          path={`/orders/${order.Id}/status`}
          method="PATCH"
          extra={{ PhienBanDuKien: order.PhienBan, TrangThaiTiepTheo: "Huy" }}
          fields={[{ ...reason, required: true }]}
          submit="Xác nhận hủy"
        />
      )}

      <h3>Đề xuất vật tư</h3>
      <Table
        data={data.DeXuatVatTu}
        columns={[
          ["Id", "Mã"],
          ["LanSuaDoi", "Lần sửa"],
          ["TrangThai", "Duyệt"],
          ["DangApDung", "Đang áp dụng"],
        ]}
      />
      <Table
        data={data.ChiTietVatTu}
        columns={[
          ["DeXuatVatTuId", "Đề xuất"],
          ["Ten", "Vật tư"],
          ["SoLuong", "Số lượng"],
          ["DonGia", "Đơn giá", money],
          ["ThanhTien", "Thành tiền", money],
          ["SoThangBaoHanh", "Bảo hành (tháng)"],
        ]}
      />
      {technician && order.TrangThai === "DangXuLy" && (
        <MaterialForm key={`materials-${order.PhienBan}`} order={order} />
      )}
      {customer && proposal?.TrangThai === "Pending" && (
        <ActionForm
          title="Duyệt đề xuất vật tư"
          path={`/materials/${proposal.Id}/decision`}
          extra={{ PhienBanDuKien: proposal.PhienBan }}
          fields={[decision, reason]}
        />
      )}

      <h3>Phiếu nghiệm thu</h3>
      <Table
        data={data.NghiemThu}
        columns={[
          ["Id", "Mã"],
          ["NguyenNhan", "Nguyên nhân"],
          ["PhuongAnXuLy", "Đã thực hiện"],
          ["PhiKiemTra", "Phí kiểm tra", money],
          ["TienCong", "Tiền công", money],
          ["TongTienVatTu", "Vật tư", money],
          ["TongTien", "Tổng tiền", money],
          ["ChuKyKTVId", "Tệp chữ ký thợ"],
          ["ChuKyKHId", "Tệp chữ ký khách"],
          ["TrangThai", "Trạng thái"],
        ]}
      />
      {technician && order.TrangThai === "DangXuLy" && (
        <ActionForm
          title="Lập phiếu nghiệm thu"
          path={`/orders/${order.Id}/acceptance`}
          extra={{ PhienBanDuKien: order.PhienBan }}
          fields={[
            {
              name: "NguyenNhan",
              label: "Nguyên nhân hư hỏng",
              required: true,
              type: "textarea",
            },
            {
              name: "PhuongAnXuLy",
              label: "Phương án đã thực hiện",
              required: true,
              type: "textarea",
            },
          ]}
        />
      )}
      {technician &&
        acceptance?.TrangThai === "Pending" &&
        !acceptance.ChuKyKTVId &&
        (signatures("TechnicianSignature").length ? (
          <ActionForm
            title="Kỹ thuật viên ký nghiệm thu"
            path={`/acceptances/${acceptance.Id}/technician-sign`}
            extra={{ PhienBanDuKien: acceptance.PhienBan }}
            fields={[
              {
                name: "ChuKyId",
                label: "Chọn ảnh chữ ký của bạn",
                options: signatures("TechnicianSignature"),
                required: true,
              },
            ]}
          />
        ) : (
          <p className="muted">
            Tải ảnh chữ ký thợ ở phần tệp đính kèm để ký nghiệm thu.
          </p>
        ))}
      {customer &&
        acceptance?.TrangThai === "Pending" &&
        acceptance.ChuKyKTVId &&
        (signatures("CustomerSignature").length ? (
          <ActionForm
            title="Khách hàng ký nghiệm thu và chọn thanh toán"
            path={`/acceptances/${acceptance.Id}/customer-sign`}
            extra={{ PhienBanDuKien: acceptance.PhienBan }}
            fields={[
              {
                name: "ChuKyId",
                label: "Chọn ảnh chữ ký của bạn",
                options: signatures("CustomerSignature"),
                required: true,
              },
              {
                name: "PhuongThucThanhToan",
                label: "Phương thức thanh toán",
                options: ["COD", "BANK"],
                required: true,
              },
            ]}
          />
        ) : (
          <p className="muted">
            Tải ảnh chữ ký khách ở phần tệp đính kèm để xác nhận nghiệm thu.
          </p>
        ))}

      <h3>Thanh toán</h3>
      <Table
        data={data.ThanhToan}
        columns={[
          ["Id", "Mã"],
          ["SoTien", "Số tiền", money],
          ["PhuongThuc", "Phương thức"],
          ["MaThamChieu", "Mã tham chiếu"],
          ["NgayTao", "Ngày ghi nhận", date],
        ]}
      />
      {technician &&
        acceptance?.TrangThai === "Approved" &&
        acceptance.PhuongThucThanhToan === "COD" &&
        !rows(data.ThanhToan).length && (
          <ActionForm
            title="Ghi nhận đã thu đủ tiền mặt"
            path={`/orders/${order.Id}/payments/cod`}
            extra={{ PhienBanDuKien: order.PhienBan }}
            fields={[]}
            submit="Xác nhận đã thu tiền mặt"
          >
            <p>
              Số tiền cần thu: <strong>{money(acceptance.TongTien)}</strong>.
            </p>
          </ActionForm>
        )}
      {customer &&
        acceptance?.TrangThai === "Approved" &&
        acceptance.PhuongThucThanhToan === "BANK" &&
        !rows(data.ThanhToan).length && (
          <BankPaymentForm order={order} files={files} />
        )}
      {customer && order.TrangThai === "HoanThanh" && (
        <ActionForm
          title="Đánh giá dịch vụ"
          path={`/orders/${order.Id}/review`}
          fields={[
            {
              name: "Diem",
              label: "Số sao",
              options: [5, 4, 3, 2, 1],
              required: true,
            },
            {
              name: "NhanXet",
              label: "Nhận xét",
              type: "textarea",
              required: true,
            },
          ]}
        />
      )}

      <h3>Tệp đính kèm</h3>
      <Table
        data={files}
        columns={[
          ["Id", "Mã"],
          ["MucDich", "Loại tệp"],
          ["TenTepGoc", "Tên tệp"],
          ["NgayTao", "Ngày tải", date],
        ]}
        actions={(file) => <FileButton file={file} />}
      />
      {(customer || technician) && (
        <UploadForm
          orderId={order.Id}
          purposes={
            customer
              ? ["OrderFault", "CustomerSignature", "PaymentProof"]
              : ["AcceptancePhoto", "TechnicianSignature"]
          }
        />
      )}

      <h3>Ghi chú đơn</h3>
      <Table
        data={data.GhiChu}
        columns={[
          ["NguoiVietId", "Người viết"],
          ["NoiDung", "Nội dung"],
          ["NoiBo", "Nội bộ"],
          ["NgayTao", "Thời gian", date],
        ]}
      />
      {["KH", "KTV", "DPV", "CSKH"].includes(role) && (
        <ActionForm
          title="Thêm ghi chú"
          path={`/orders/${order.Id}/notes`}
          fields={[
            {
              name: "NoiDung",
              label: "Nội dung",
              required: true,
              type: "textarea",
            },
            ...(role !== "KH"
              ? [
                {
                  name: "NoiBo",
                  label: "Chỉ nhân viên xem",
                  type: "checkbox",
                },
              ]
              : []),
          ]}
        />
      )}

      <h3>Lịch sử trạng thái</h3>
      <Table
        data={data.LichSu}
        columns={[
          ["TrangThaiTruoc", "Trước"],
          ["TrangThaiSau", "Sau"],
          ["NguoiThucHienId", "Người thực hiện"],
          ["LyDo", "Lý do"],
          ["NgayTao", "Thời gian", date],
        ]}
      />
    </div>
  );
}

function AssignmentForm({ order }) {
  const technicians = useResource("/technicians");
  return (
    <Resource state={technicians}>
      {(data) => (
        <ActionForm
          title="Phân công kỹ thuật viên"
          path={`/orders/${order.Id}/assign`}
          extra={{ PhienBanDuKien: order.PhienBan }}
          fields={[
            {
              name: "KyThuatVienId",
              label: "Kỹ thuật viên",
              required: true,
              options: rows(data).map((row) => [
                row.Id,
                `${row.HoTen} — ${text(row.TrangThaiSanSang)} — ${row.KhuVucPhucVu || ""}`,
              ]),
            },
          ]}
        />
      )}
    </Resource>
  );
}

function MaterialForm({ order }) {
  const { api, changed } = useSession();
  const [items, setItems] = useState([
    { Ten: "", SoLuong: 1, DonGia: 0, SoThangBaoHanh: 0 },
  ]);
  function update(index, key, value) {
    setItems((old) =>
      old.map((item, position) =>
        position === index ? { ...item, [key]: value } : item,
      ),
    );
  }
  return (
    <details className="operation">
      <summary>Lập đề xuất vật tư</summary>
      <Form
        submit="Gửi khách duyệt"
        onSubmit={async () => {
          if (!items.length) throw new Error("Cần ít nhất một vật tư.");
          await api(`/orders/${order.Id}/materials`, {
            method: "POST",
            body: {
              PhienBanDuKien: order.PhienBan,
              VatTu: items.map((item) => ({
                Ten: item.Ten.trim(),
                SoLuong: Number(item.SoLuong),
                DonGia: Number(item.DonGia),
                SoThangBaoHanh: Number(item.SoThangBaoHanh),
              })),
            },
          });
          changed("Đã gửi đề xuất vật tư.");
        }}
      >
        {items.map((item, index) => (
          <div className="material-row" key={index}>
            <label>
              Tên vật tư
              <input
                value={item.Ten}
                onChange={(e) => update(index, "Ten", e.target.value)}
                required
                maxLength={200}
              />
            </label>
            <label>
              Số lượng
              <input
                type="number"
                min="0.01"
                step="0.01"
                value={item.SoLuong}
                onChange={(e) => update(index, "SoLuong", e.target.value)}
                required
              />
            </label>
            <label>
              Đơn giá
              <input
                type="number"
                min="0"
                step="1000"
                value={item.DonGia}
                onChange={(e) => update(index, "DonGia", e.target.value)}
                required
              />
            </label>
            <label>
              Bảo hành (tháng)
              <input
                type="number"
                min="0"
                max="120"
                value={item.SoThangBaoHanh}
                onChange={(e) =>
                  update(index, "SoThangBaoHanh", e.target.value)
                }
                required
              />
            </label>
            <button
              type="button"
              className="secondary"
              disabled={items.length === 1}
              onClick={() =>
                setItems((old) => old.filter((_, i) => i !== index))
              }
            >
              Bỏ
            </button>
          </div>
        ))}
        <button
          type="button"
          className="secondary"
          onClick={() =>
            setItems((old) => [
              ...old,
              { Ten: "", SoLuong: 1, DonGia: 0, SoThangBaoHanh: 0 },
            ])
          }
        >
          Thêm vật tư
        </button>
      </Form>
    </details>
  );
}

function BankPaymentForm({ order, files }) {
  const { user } = useSession();
  const banks = useResource("/bank-accounts");
  const proofs = files.filter(
    (file) => file.MucDich === "PaymentProof" && file.ChuSoHuuId === user.Id,
  );
  return (
    <Resource state={banks}>
      {(data) => (
        <>
          <Table
            data={data}
            columns={[
              ["Id", "Mã"],
              ["TenNganHang", "Ngân hàng"],
              ["SoTaiKhoan", "Số tài khoản"],
              ["ChuTaiKhoan", "Chủ tài khoản"],
            ]}
          />
          <ActionForm
            title="Gửi chứng từ chuyển khoản"
            path={`/orders/${order.Id}/payments/bank`}
            fields={[
              {
                name: "TaiKhoanNganHangId",
                label: "Tài khoản đã chuyển đến",
                required: true,
                options: rows(data)
                  .filter((row) => row.DangHoatDong)
                  .map((row) => [
                    row.Id,
                    `${row.TenNganHang} — ${row.SoTaiKhoan}`,
                  ]),
              },
              {
                name: "ChungTuId",
                label: "Tệp chứng từ đã tải lên",
                required: true,
                options: proofs.map((file) => [
                  file.Id,
                  `#${file.Id} — ${file.TenTepGoc}`,
                ]),
              },
              {
                name: "MaThamChieu",
                label: "Mã giao dịch ngân hàng",
                required: true,
                maxLength: 100,
              },
            ]}
          />
        </>
      )}
    </Resource>
  );
}
