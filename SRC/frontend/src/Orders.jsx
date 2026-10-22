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

const orderColumns = [
  ["Id", "Mã đơn"],
  ["TenDichVu", "Dịch vụ"],
  ["TenKhachHang", "Khách hàng"],
  ["TenKyThuatVien", "Kỹ thuật viên"],
  ["TrangThai", "Trạng thái"],
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

export function ServicesPage() {
  const services = useResource("/services");
  return (
    <Panel title="Dịch vụ đang cung cấp">
      <Resource state={services}>
        {(data) => (
          <Table
            data={data}
            columns={[
              ["Id", "Mã"],
              ["TenDanhMuc", "Danh mục"],
              ["Ten", "Tên dịch vụ"],
              ["MoTa", "Mô tả"],
              ["PhiKiemTra", "Phí kiểm tra", money],
              ["TienCong", "Tiền công tham khảo", money],
            ]}
          />
        )}
      </Resource>
    </Panel>
  );
}

export function OrdersPage() {
  const { user } = useSession();
  const [selected, setSelected] = useState(null);
  const orders = useResource("/orders");
  const services = useResource("/services");
  return (
    <>
      {user.VaiTro === "KH" && (
        <ActionForm
          title="Đặt dịch vụ mới"
          path="/orders"
          fields={[
            {
              name: "DichVuId",
              label: "Dịch vụ",
              required: true,
              options: rows(services.data).map((s) => [s.Id, s.Ten]),
            },
            {
              name: "DiaChi",
              label: "Địa chỉ thực hiện",
              required: true,
              maxLength: 500,
            },
            {
              name: "MoTa",
              label: "Mô tả tình trạng",
              required: true,
              type: "textarea",
            },
            {
              name: "NgayHen",
              label: "Ngày giờ hẹn (tùy chọn)",
              type: "datetime-local",
            },
          ]}
          submit="Tạo đơn"
          onDone={(result) => setSelected(rows(result)[0]?.Id || null)}
        />
      )}
      <Panel
        title="Danh sách đơn dịch vụ"
        hint="Chọn Chi tiết để xem tiến độ và thực hiện các bước thuộc vai trò của bạn."
      >
        <Resource state={orders}>
          {(data) => (
            <Table
              data={data}
              columns={orderColumns}
              actions={(row) => (
                <button onClick={() => setSelected(row.Id)}>
                  Chi tiết #{row.Id}
                </button>
              )}
            />
          )}
        </Resource>
      </Panel>
      {selected && (
        <OrderDetail
          key={selected}
          id={selected}
          close={() => setSelected(null)}
          services={rows(services.data)}
        />
      )}
    </>
  );
}

function OrderDetail({ id, close, services }) {
  const detail = useResource(`/orders/${id}`);
  return (
    <Panel title={`Chi tiết đơn #${id}`}>
      <button className="secondary" onClick={close}>
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
          ["TrangThai", "Trạng thái"],
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
      {customer && open && (
        <ActionForm
          title="Chia sẻ vị trí tại địa chỉ thực hiện"
          path={`/orders/${order.Id}/location`}
          method="PUT"
          fields={[
            {
              name: "ViDo",
              label: "Vĩ độ",
              type: "number",
              required: true,
              min: -90,
              max: 90,
              step: 0.000001,
            },
            {
              name: "KinhDo",
              label: "Kinh độ",
              type: "number",
              required: true,
              min: -180,
              max: 180,
              step: 0.000001,
            },
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
