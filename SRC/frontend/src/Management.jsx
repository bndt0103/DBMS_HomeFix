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

export function AdminPage() {
  const users = useResource("/users");
  const applications = useResource("/technician-applications");
  const { api, changed, user } = useSession();
  const [selected, setSelected] = useState(null);
  const [failure, setFailure] = useState("");
  const selectedUser = rows(users.data).find((row) => row.Id === selected);
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
      changed(
        row.DangHoatDong ? "Đã khóa tài khoản." : "Đã mở khóa tài khoản.",
      );
    } catch (error) {
      setFailure(error.message);
    }
  }
  return (
    <>
      <ActionForm
        title="Tạo tài khoản"
        path="/users"
        fields={staffFields}
        submit="Tạo tài khoản"
      />
      <Panel title="Quản lý tài khoản">
        <p>
          Chọn một vai trò cho mỗi tài khoản. Quyền nghiệp vụ được kiểm tra khi
          tài khoản sử dụng chức năng tương ứng.
        </p>
        {failure && (
          <p className="error" role="alert">
            {failure}
          </p>
        )}
        <Resource state={users}>
          {(data) => (
            <Table
              data={data}
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
                ["VaiTro", "Vai trò"],
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
                    onClick={() => setSelected(row.Id)}
                  >
                    Đổi vai trò
                  </button>
                </>
              )}
            />
          )}
        </Resource>
        {selectedUser && (
          <ActionForm
            key={`role-${selectedUser.Id}-${selectedUser.PhienBan}`}
            title={`Vai trò của ${selectedUser.HoTen}`}
            path={`/users/${selectedUser.Id}/role`}
            method="PATCH"
            extra={{ PhienBanDuKien: selectedUser.PhienBan }}
            fields={[
              {
                name: "VaiTro",
                label: "Vai trò",
                required: true,
                options: roles,
                defaultValue: selectedUser.VaiTro,
              },
            ]}
            onDone={() => setSelected(null)}
          />
        )}
      </Panel>
      <Panel title="Hồ sơ đăng ký kỹ thuật viên">
        <Resource state={applications}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã hồ sơ"],
                ["NguoiDungId", "Người đăng ký"],
                ["NhomTayNghe", "Tay nghề"],
                ["KhuVucPhucVu", "Khu vực"],
                ["KinhNghiem", "Kinh nghiệm"],
                ["TrangThai", "Trạng thái"],
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
                        label: "Nội dung xét duyệt",
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
  const [categoryId, setCategoryId] = useState(null);
  const [serviceId, setServiceId] = useState(null);
  const category = rows(categories.data).find((row) => row.Id === categoryId);
  const service = rows(services.data).find((row) => row.Id === serviceId);
  const serviceFields = [
    {
      name: "DanhMucId",
      label: "Danh mục",
      required: true,
      options: rows(categories.data).map((row) => [row.Id, row.Ten]),
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
      <Panel title="Danh mục dịch vụ">
        <Resource state={categories}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã số"],
                ["Ma", "Mã danh mục"],
                ["Ten", "Tên danh mục"],
                ["DangHoatDong", "Đang cung cấp"],
              ]}
              actions={(row) => (
                <button onClick={() => setCategoryId(row.Id)}>Sửa</button>
              )}
            />
          )}
        </Resource>
        <ActionForm
          title="Thêm danh mục"
          path="/categories"
          fields={categoryFields}
        />
        {category && (
          <ActionForm
            key={`category-${category.Id}-${category.PhienBan}`}
            title={`Sửa danh mục ${category.Ten}`}
            path="/categories"
            fields={categoryFields}
            initial={category}
            extra={{ Id: category.Id, PhienBanDuKien: category.PhienBan }}
            onDone={() => setCategoryId(null)}
          />
        )}
      </Panel>
      <Panel title="Dịch vụ">
        <Resource state={services}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["Ten", "Dịch vụ"],
                ["PhiKiemTra", "Phí kiểm tra", money],
                ["TienCong", "Tiền công", money],
                ["TyLeHoaHong", "Hoa hồng (%)"],
                ["DangHoatDong", "Đang cung cấp"],
              ]}
              actions={(row) => (
                <button onClick={() => setServiceId(row.Id)}>Sửa</button>
              )}
            />
          )}
        </Resource>
        <ActionForm
          title="Thêm dịch vụ"
          path="/services"
          fields={serviceFields}
        />
        {service && (
          <ActionForm
            key={`service-${service.Id}-${service.PhienBan}`}
            title={`Sửa dịch vụ ${service.Ten}`}
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

export function SettingsPage() {
  const { user } = useSession();
  const settings = useResource("/settings");
  const banks = useResource("/bank-accounts?all=1");
  const [selectedBank, setSelectedBank] = useState(null);
  const bank = rows(banks.data).find((row) => row.Id === selectedBank);
  const bankFields = [
    {
      name: "MaNganHang",
      label: "Mã ngân hàng",
      required: true,
      maxLength: 20,
    },
    {
      name: "TenNganHang",
      label: "Tên ngân hàng",
      required: true,
      maxLength: 150,
    },
    {
      name: "SoTaiKhoan",
      label: "Số tài khoản",
      required: true,
      maxLength: 50,
    },
    {
      name: "ChuTaiKhoan",
      label: "Chủ tài khoản",
      required: true,
      maxLength: 150,
    },
    {
      name: "DangHoatDong",
      label: "Đang sử dụng",
      type: "checkbox",
      defaultValue: true,
    },
  ];
  return (
    <>
      <Panel title="Cấu hình hệ thống">
        <Resource state={settings}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Khoa", "Khóa cấu hình"],
                ["NhanHienThi", "Tên cấu hình"],
                ["GiaTri", "Giá trị"],
              ]}
              actions={(row) =>
                user.VaiTro === "ADMIN" && (
                  <ActionForm
                    title="Sửa"
                    path={`/settings/${encodeURIComponent(row.Khoa)}`}
                    method="PUT"
                    fields={[
                      {
                        name: "GiaTri",
                        label: "Giá trị",
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
                ["MaNganHang", "Mã ngân hàng"],
                ["TenNganHang", "Ngân hàng"],
                ["SoTaiKhoan", "Số tài khoản"],
                ["ChuTaiKhoan", "Chủ tài khoản"],
                ["DangHoatDong", "Đang sử dụng"],
              ]}
              actions={(row) =>
                user.VaiTro === "ADMIN" && (
                  <button onClick={() => setSelectedBank(row.Id)}>Sửa</button>
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

export function ProfilePage() {
  const { api, user, changed, setUser } = useSession();
  const profile = useResource("/auth/me");
  const notifications = useResource("/notifications");
  return (
    <>
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
                  ["VaiTro", "Vai trò"],
                  ["DiaChi", "Địa chỉ"],
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
      {user.VaiTro === "KTV" && <TechnicianProfile />}
      {user.VaiTro === "KH" && (
        <ActionForm
          title="Đăng ký trở thành kỹ thuật viên"
          path="/technician-applications"
          fields={[
            {
              name: "NhomTayNghe",
              label: "Tay nghề",
              required: true,
              maxLength: 200,
            },
            {
              name: "KhuVucPhucVu",
              label: "Khu vực phục vụ",
              required: true,
              maxLength: 200,
            },
            {
              name: "KinhNghiem",
              label: "Kinh nghiệm",
              required: true,
              type: "textarea",
            },
          ]}
          submit="Gửi hồ sơ"
        />
      )}
      <Panel title="Thông báo">
        <Resource state={notifications}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["TieuDe", "Tiêu đề"],
                ["NoiDung", "Nội dung"],
                ["DaDoc", "Đã đọc"],
                ["NgayTao", "Thời gian", date],
              ]}
              actions={(row) =>
                !row.DaDoc && (
                  <ActionForm
                    title="Đánh dấu đã đọc"
                    path={`/notifications/${row.Id}/read`}
                    fields={[]}
                    submit="Đã đọc"
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

function TechnicianProfile() {
  const technician = useResource("/technician/me");
  return (
    <Panel title="Hồ sơ và trạng thái làm việc">
      <Resource state={technician}>
        {(data) => {
          const row = rows(data)[0];
          if (!row)
            return <p className="empty">Chưa có hồ sơ kỹ thuật viên.</p>;
          return (
            <>
              <Details
                row={row}
                fields={[
                  ["NhomTayNghe", "Tay nghề"],
                  ["KhuVucPhucVu", "Khu vực"],
                  ["TrangThaiSanSang", "Trạng thái"],
                  ["SoDu", "Số dư ví", money],
                ]}
              />
              <ActionForm
                key={`tech-status-${row.PhienBan}`}
                title="Đổi trạng thái sẵn sàng"
                path="/technician/status"
                method="PATCH"
                extra={{ PhienBanDuKien: row.PhienBan }}
                fields={[
                  {
                    name: "TrangThaiSanSang",
                    label: "Trạng thái",
                    options: ["SanSang", "TamBan"],
                    required: true,
                    defaultValue: row.TrangThaiSanSang,
                  },
                ]}
              />
              <ActionForm
                title="Cập nhật tay nghề / khu vực / vị trí"
                path="/technician/me"
                method="PATCH"
                initial={row}
                fields={[
                  {
                    name: "NhomTayNghe",
                    label: "Tay nghề",
                    required: true,
                    maxLength: 200,
                  },
                  {
                    name: "KhuVucPhucVu",
                    label: "Khu vực phục vụ",
                    required: true,
                    maxLength: 200,
                  },
                  {
                    name: "ViDo",
                    label: "Vĩ độ",
                    type: "number",
                    min: -90,
                    max: 90,
                    step: 0.000001,
                    allowEmpty: true,
                  },
                  {
                    name: "KinhDo",
                    label: "Kinh độ",
                    type: "number",
                    min: -180,
                    max: 180,
                    step: 0.000001,
                    allowEmpty: true,
                  },
                ]}
              />
            </>
          );
        }}
      </Resource>
    </Panel>
  );
}

export function ReportsPage() {
  const report = useResource("/reports");
  return (
    <Resource state={report}>
      {(data) => (
        <>
          <Panel title="Thống kê đơn dịch vụ">
            <ReportTable data={data.ThongKe} />
          </Panel>
          <Panel title="Doanh thu theo ngày">
            <ReportTable data={data.DoanhThu} />
          </Panel>
          <Panel title="Hiệu suất kỹ thuật viên">
            <ReportTable data={data.HieuSuat} />
          </Panel>
          <Panel title="Số dư ví kỹ thuật viên">
            <ReportTable data={data.Vi} />
          </Panel>
        </>
      )}
    </Resource>
  );
}

const reportLabels = {
  Id: "Mã",
  KyThuatVienId: "Mã thợ",
  HoTen: "Họ tên",
  TenKyThuatVien: "Kỹ thuật viên",
  Ngay: "Ngày",
  NgayThanhToan: "Ngày",
  TrangThai: "Trạng thái",
  SoLuong: "Số lượng",
  SoDon: "Số đơn",
  TongDon: "Tổng đơn",
  TongSoDon: "Tổng số đơn",
  SoDonHoanThanh: "Đơn hoàn thành",
  SoDonDangXuLy: "Đơn đang xử lý",
  SoDonHuy: "Đơn hủy",
  TongTien: "Tổng tiền",
  DoanhThu: "Doanh thu",
  TongDoanhThu: "Tổng doanh thu",
  TienHoaHong: "Hoa hồng",
  TongHoaHong: "Tổng hoa hồng",
  SoDu: "Số dư",
  DiemTrungBinh: "Điểm trung bình",
  DiemDanhGia: "Điểm đánh giá",
  TrangThaiSanSang: "Trạng thái làm việc",
  TyLeHoanThanh: "Tỷ lệ hoàn thành",
  SoDonDaNhan: "Đơn đã nhận",
  SoDanhGia: "Số đánh giá",
  TongThu: "Tổng thu",
  ThuCOD: "Thu tiền mặt",
  ThuNganHang: "Thu chuyển khoản",
  HoaHongDaDoiSoat: "Hoa hồng đã đối soát",
  SoDuSoCai: "Số dư sổ giao dịch",
  ChenhLech: "Chênh lệch số dư",
  TongTienDaThu: "Tổng tiền đã thu",
};

function ReportTable({ data }) {
  const list = rows(data);
  const columns = Object.keys(list[0] || {})
    .filter((key) => key !== "PhienBan")
    .map((key) => [
      key,
      reportLabels[key] || key.replace(/([a-z])([A-Z])/g, "$1 $2"),
      (value) =>
        /Tien|DoanhThu|HoaHong|SoDu|ThuCOD|ThuNganHang|TongThu|ChenhLech/.test(
          key,
        ) && !/TyLe/.test(key)
          ? money(value)
          : /Ngay/.test(key)
            ? date(value)
            : text(value),
    ]);
  return <Table data={list} columns={columns} />;
}
