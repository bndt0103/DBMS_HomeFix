import { useState } from "react";
import {
  ActionForm,
  date,
  Details,
  money,
  Panel,
  Resource,
  rows,
  Table,
  UploadForm,
  useResource,
  useSession,
} from "./components.jsx";

export function WalletPage() {
  const wallet = useResource("/wallet");
  const banks = useResource("/bank-accounts");
  return (
    <>
      <Panel title="Ví kỹ thuật viên">
        <Resource state={wallet}>
          {(data) => (
            <>
              <Details
                row={rows(data.KyThuatVien)[0]}
                fields={[
                  ["HoTen", "Kỹ thuật viên"],
                  ["SoDu", "Số dư khả dụng", money],
                  ["TrangThaiSanSang", "Trạng thái làm việc"],
                ]}
              />
              <h3>Yêu cầu nạp / rút</h3>
              <Table
                data={data.YeuCau}
                columns={[
                  ["Id", "Mã"],
                  ["Loai", "Loại"],
                  ["SoTien", "Số tiền", money],
                  ["TrangThai", "Trạng thái"],
                  ["LyDo", "Lý do xử lý"],
                  ["NgayTao", "Thời gian", date],
                ]}
              />
              <h3>Sổ giao dịch</h3>
              <Table
                data={data.GiaoDich}
                columns={[
                  ["Id", "Mã"],
                  ["Loai", "Loại"],
                  ["SoTien", "Phát sinh", money],
                  ["GhiChu", "Diễn giải"],
                  ["NgayTao", "Thời gian", date],
                ]}
              />
            </>
          )}
        </Resource>
      </Panel>
      <Panel title="Tạo yêu cầu ví">
        <p>
          Khi nạp tiền, chuyển khoản vào tài khoản bên dưới, tải chứng từ rồi
          điền mã tệp vừa nhận. Kế toán kiểm tra trước khi cộng số dư.
        </p>
        <Resource state={banks}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["TenNganHang", "Ngân hàng"],
                ["SoTaiKhoan", "Số tài khoản"],
                ["ChuTaiKhoan", "Chủ tài khoản"],
              ]}
            />
          )}
        </Resource>
        <UploadForm purposes={["WalletProof"]} />
        <ActionForm
          title="Nạp / rút tiền"
          path="/wallet/requests"
          fields={[
            {
              name: "Loai",
              label: "Loại yêu cầu",
              options: ["Deposit", "Withdrawal"],
              required: true,
            },
            {
              name: "SoTien",
              label: "Số tiền",
              type: "number",
              required: true,
              min: 1000,
              step: 1000,
            },
            {
              name: "ChungTuId",
              label: "Mã tệp chứng từ (bắt buộc khi nạp)",
              type: "number",
              min: 1,
            },
            {
              name: "GhiChu",
              label: "Ghi chú / tài khoản nhận tiền khi rút",
              type: "textarea",
              required: true,
            },
          ]}
          submit="Gửi yêu cầu"
        />
      </Panel>
    </>
  );
}

export function FinancePage() {
  const bank = useResource("/bank-requests");
  const wallet = useResource("/wallet/requests");
  const settlements = useResource("/settlements");
  const [selectedBank, setSelectedBank] = useState(null);
  const [selectedWallet, setSelectedWallet] = useState(null);
  const [selectedSettlement, setSelectedSettlement] = useState(null);
  const bankRow = rows(bank.data).find((row) => row.Id === selectedBank);
  const walletRow = rows(wallet.data).find((row) => row.Id === selectedWallet);
  const settlementRow = rows(settlements.data).find(
    (row) => row.Id === selectedSettlement,
  );
  return (
    <>
      <Panel title="Xác nhận thanh toán chuyển khoản">
        <Resource state={bank}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["DonHangId", "Đơn"],
                ["KhachHangId", "Khách hàng"],
                ["SoTien", "Số tiền", money],
                ["ChungTuId", "Mã tệp chứng từ"],
                ["MaThamChieu", "Mã giao dịch"],
                ["TrangThai", "Trạng thái"],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button onClick={() => setSelectedBank(row.Id)}>
                    Kiểm tra
                  </button>
                )
              }
            />
          )}
        </Resource>
        {bankRow?.TrangThai === "Pending" && (
          <ActionForm
            key={`bank-${bankRow.Id}-${bankRow.PhienBan}`}
            title={`Duyệt thanh toán #${bankRow.Id}`}
            path={`/bank-requests/${bankRow.Id}/confirm`}
            extra={{ PhienBanDuKien: bankRow.PhienBan }}
            fields={[
              {
                name: "QuyetDinh",
                label: "Quyết định",
                options: ["Confirmed", "Rejected"],
                required: true,
              },
              {
                name: "SoTienThucNhan",
                label: "Số tiền thực nhận",
                type: "number",
                min: 0,
                step: 1000,
                required: true,
                defaultValue: bankRow.SoTien,
              },
              {
                name: "MaThamChieu",
                label: "Mã giao dịch đã kiểm tra",
                defaultValue: bankRow.MaThamChieu,
              },
            ]}
            onDone={() => setSelectedBank(null)}
          >
            <p>
              Đối chiếu sao kê ngân hàng trước khi xác nhận. Mã chứng từ:{" "}
              {bankRow.ChungTuId || "chưa có"}.
            </p>
            <EvidenceLink id={bankRow.ChungTuId} />
          </ActionForm>
        )}
      </Panel>
      <Panel title="Duyệt yêu cầu nạp / rút ví">
        <Resource state={wallet}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["KyThuatVienId", "Mã thợ"],
                ["Loai", "Loại"],
                ["SoTien", "Số tiền", money],
                ["GhiChu", "Ghi chú"],
                ["ChungTuId", "Chứng từ"],
                ["TrangThai", "Trạng thái"],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button onClick={() => setSelectedWallet(row.Id)}>
                    Xử lý
                  </button>
                )
              }
            />
          )}
        </Resource>
        {walletRow?.TrangThai === "Pending" && (
          <ActionForm
            key={`wallet-${walletRow.Id}-${walletRow.PhienBan}`}
            title={`Xử lý yêu cầu ví #${walletRow.Id}`}
            path={`/wallet/requests/${walletRow.Id}/decision`}
            extra={{ PhienBanDuKien: walletRow.PhienBan }}
            fields={[
              {
                name: "QuyetDinh",
                label: "Quyết định",
                options: ["Approved", "Rejected"],
                required: true,
              },
              {
                name: "LyDo",
                label: "Nội dung đối chiếu / lý do từ chối",
                type: "textarea",
                required: true,
              },
            ]}
            onDone={() => setSelectedWallet(null)}
          >
            <EvidenceLink id={walletRow.ChungTuId} />
          </ActionForm>
        )}
      </Panel>
      <Panel title="Đối soát và hoa hồng">
        <Resource state={settlements}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["DonHangId", "Đơn"],
                ["KyThuatVienId", "Thợ"],
                ["TienCong", "Tiền công", money],
                ["TyLeHoaHong", "Tỷ lệ"],
                ["TienHoaHong", "Hoa hồng", money],
                ["TrangThai", "Trạng thái"],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button onClick={() => setSelectedSettlement(row.Id)}>
                    Đối soát
                  </button>
                )
              }
            />
          )}
        </Resource>
        {settlementRow?.TrangThai === "Pending" && (
          <ActionForm
            title={`Xác nhận đối soát #${settlementRow.Id}`}
            fields={[]}
            path={`/settlements/${settlementRow.Id}/confirm`}
            extra={{ PhienBanDuKien: settlementRow.PhienBan }}
            submit="Xác nhận đối soát"
            onDone={() => setSelectedSettlement(null)}
          >
            <p>
              Hoa hồng tính trên tiền công:{" "}
              <strong>{money(settlementRow.TienHoaHong)}</strong>.
            </p>
          </ActionForm>
        )}
      </Panel>
    </>
  );
}

function EvidenceLink({ id }) {
  const { api } = useSession();
  const [error, setError] = useState("");
  if (!id) return null;
  return (
    <>
      <button
        className="secondary"
        type="button"
        onClick={async () => {
          try {
            setError("");
            const blob = await api(`/uploads/${id}`, { raw: true });
            const url = URL.createObjectURL(blob);
            const link = document.createElement("a");
            link.href = url;
            link.download = `chung-tu-${id}`;
            link.click();
            setTimeout(() => URL.revokeObjectURL(url), 60000);
          } catch (failure) {
            setError(failure.message);
          }
        }}
      >
        Tải chứng từ #{id}
      </button>
      {error && <p className="error">{error}</p>}
    </>
  );
}

export function SupportPage() {
  const { user } = useSession();
  const support = useResource("/support");
  const orders = useResource(user.VaiTro === "KH" ? "/orders" : null);
  const [selected, setSelected] = useState(null);
  const ticket = rows(support.data).find((row) => row.Id === selected);
  return (
    <>
      {user.VaiTro === "KH" && (
        <ActionForm
          title="Gửi phiếu hỗ trợ"
          path="/support"
          fields={[
            {
              name: "DonHangId",
              label: "Đơn cần hỗ trợ",
              required: true,
              options: rows(orders.data).map((row) => [
                row.Id,
                `#${row.Id} — ${row.TenDichVu}`,
              ]),
            },
            {
              name: "Loai",
              label: "Loại yêu cầu",
              required: true,
              options: ["Complaint", "Warranty"],
            },
            {
              name: "MoTa",
              label: "Nội dung yêu cầu",
              type: "textarea",
              required: true,
            },
          ]}
          submit="Gửi hỗ trợ"
        />
      )}
      <Panel title="Phiếu hỗ trợ / bảo hành">
        <Resource state={support}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã"],
                ["DonHangId", "Đơn"],
                ["Loai", "Loại"],
                ["MoTa", "Nội dung"],
                ["TrangThai", "Trạng thái"],
                ["KetQuaXuLy", "Kết quả"],
                ["NgayTao", "Ngày tạo", date],
              ]}
              actions={(row) => (
                <button onClick={() => setSelected(row.Id)}>Trao đổi</button>
              )}
            />
          )}
        </Resource>
      </Panel>
      {ticket && (
        <Panel title={`Trao đổi phiếu #${ticket.Id}`}>
          <p>{ticket.MoTa}</p>
          <TicketMessages ticket={ticket} />
          {user.VaiTro === "CSKH" && (
            <ActionForm
              key={`support-${ticket.Id}-${ticket.PhienBan}`}
              title="Cập nhật xử lý hỗ trợ"
              path={`/support/${ticket.Id}`}
              method="PATCH"
              extra={{ PhienBanDuKien: ticket.PhienBan }}
              fields={[
                {
                  name: "TrangThai",
                  label: "Trạng thái tiếp theo",
                  options: ["InProgress", "Resolved", "Rejected"],
                  required: true,
                },
                {
                  name: "KetQuaXuLy",
                  label: "Kết quả / lý do xử lý",
                  required: true,
                  type: "textarea",
                },
              ]}
            />
          )}
        </Panel>
      )}
    </>
  );
}

function TicketMessages({ ticket }) {
  const { user } = useSession();
  const messages = useResource(`/support/${ticket.Id}/messages`);
  return (
    <>
      <Resource state={messages}>
        {(data) => (
          <Table
            data={data}
            columns={[
              ["NguoiGuiId", "Người gửi"],
              ["NoiDung", "Nội dung"],
              ["NgayTao", "Thời gian", date],
            ]}
          />
        )}
      </Resource>
      {["KH", "CSKH"].includes(user.VaiTro) && (
        <ActionForm
          title="Thêm trao đổi"
          path={`/support/${ticket.Id}/messages`}
          fields={[
            {
              name: "NoiDung",
              label: "Nội dung trao đổi",
              type: "textarea",
              required: true,
            },
          ]}
          submit="Gửi"
        />
      )}
    </>
  );
}
