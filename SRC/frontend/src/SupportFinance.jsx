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
import { Icon } from "./icons.jsx";

export function FinanceOverview({ onNavigate }) {
  const reports = useResource("/reports");
  const settlements = useResource("/settlements");
  const walletRequests = useResource("/wallet/requests");
  const bankRequests = useResource("/bank-requests");

  const reportData = reports.data || {};
  const revenueList = rows(reportData.DoanhThu);
  const totalRevenue = revenueList.reduce(
    (sum, item) => sum + Number(item.TongThu || item.TongDoanhThu || 0),
    0,
  );
  const totalCommission = revenueList.reduce(
    (sum, item) => sum + Number(item.HoaHongDaDoiSoat || item.TienHoaHong || 0),
    0,
  );

  const settlementList = rows(settlements.data);
  const pendingSettlements = settlementList.filter(
    (item) => item.TrangThai === "Pending",
  );
  const pendingWallet = rows(walletRequests.data).filter(
    (item) => item.TrangThai === "Pending",
  );
  const pendingBank = rows(bankRequests.data).filter(
    (item) => item.TrangThai === "Pending",
  );

  const pendingCodAmount = pendingSettlements.reduce(
    (sum, item) => sum + Number(item.TienCong || 0),
    0,
  );

  return (
    <div className="finance-dashboard">
      <div className="page-head">
        <span className="eyebrow">PHÂN HỆ KẾ TOÁN</span>
        <h1>Tổng quan tài chính và dòng tiền</h1>
        <p>Theo dõi tiền khách đã thanh toán, hoa hồng sàn và các khoản cần đối soát.</p>
      </div>

      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-label">
            Tổng doanh thu dịch vụ <Icon name="chart" size={18} />
          </div>
          <strong>{money(totalRevenue)}</strong>
          <small>Tổng giá trị dịch vụ đã thu</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Hoa hồng sàn thực thu <Icon name="wallet" size={18} />
          </div>
          <strong style={{ color: "#087b4b" }}>{money(totalCommission)}</strong>
          <small>Đã đối soát vào doanh thu sàn</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Yêu cầu Nạp / Rút chờ duyệt <Icon name="wallet" size={18} />
          </div>
          <strong style={{ color: pendingWallet.length ? "#d97706" : "#253846" }}>
            {pendingWallet.length} lệnh
          </strong>
          <small>{pendingWallet.length ? "Cần kế toán xử lý" : "Không có yêu cầu chờ"}</small>
        </div>
        <div className="stat-card">
          <div className="stat-label">
            Tiền COD chưa đối soát thợ <Icon name="arrowDownUp" size={18} />
          </div>
          <strong style={{ color: pendingCodAmount > 0 ? "#dc2626" : "#253846" }}>
            {money(pendingCodAmount)}
          </strong>
          <small>{pendingSettlements.length} đơn tiền mặt đang chờ</small>
        </div>
      </div>

      <div className="two-column">
        <Panel title="Giao dịch gần đây cần xử lý">
          {pendingWallet.length || pendingSettlements.length || pendingBank.length ? (
            <div style={{ display: "grid", gap: 10 }}>
              {pendingWallet.slice(0, 3).map((w) => (
                <div className="order-card" key={`wallet-${w.Id}`}>
                  <div className="order-symbol">
                    <Icon name="wallet" size={20} />
                  </div>
                  <div className="order-main">
                    <span className="badge">{w.Loai === "Deposit" ? "Nạp ví" : "Rút ví"}</span>
                    <h3>Thợ #{w.KyThuatVienId} — {money(w.SoTien)}</h3>
                    <p>{w.GhiChu || "Chờ kế toán phê duyệt"}</p>
                  </div>
                  <button className="primary" onClick={() => onNavigate("wallet_admin")}>
                    Xử lý
                  </button>
                </div>
              ))}
              {pendingSettlements.slice(0, 3).map((s) => (
                <div className="order-card" key={`settle-${s.Id}`}>
                  <div className="order-symbol">
                    <Icon name="clipboard" size={20} />
                  </div>
                  <div className="order-main">
                    <span className="badge">Chờ đối soát COD</span>
                    <h3>Đơn #{s.DonHangId} — Thợ #{s.KyThuatVienId}</h3>
                    <p>Tiền công: {money(s.TienCong)} · Hoa hồng: {money(s.TienHoaHong)}</p>
                  </div>
                  <button className="primary" onClick={() => onNavigate("settlements")}>
                    Đối soát
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-card">
              <p>Mọi thứ đã được đối soát. Không có giao dịch đang chờ xử lý.</p>
            </div>
          )}
        </Panel>

        <Panel title="Cảnh báo & Lối tắt tài chính">
          <div className={pendingSettlements.length ? "notice warning" : "notice success"}>
            <Icon name="shield" size={20} />
            <div>
              <b>{pendingSettlements.length ? "Cảnh báo tiền mặt COD" : "Tài chính an toàn"}</b>
              <p>
                {pendingSettlements.length
                  ? `Có ${pendingSettlements.length} đơn COD thợ đã thu tiền mặt của khách nhưng chưa đối soát hoa hồng.`
                  : "Toàn bộ đơn hàng COD đã được đối soát đầy đủ."}
              </p>
            </div>
          </div>
          <div style={{ display: "grid", gap: 10, marginTop: 16 }}>
            <button className="btn secondary" onClick={() => onNavigate("settlements")}>
              <Icon name="clipboard" size={16} /> Quản lý đối soát doanh thu
            </button>
            <button className="btn secondary" onClick={() => onNavigate("wallet_admin")}>
              <Icon name="wallet" size={16} /> Phê duyệt yêu cầu ví KTV
            </button>
            <button className="btn secondary" onClick={() => onNavigate("bank_requests")}>
              <Icon name="shield" size={16} /> Kiểm tra chuyển khoản ngân hàng
            </button>
            <button className="btn secondary" onClick={() => onNavigate("reports")}>
              <Icon name="chart" size={16} /> Báo cáo dòng tiền toàn sàn
            </button>
          </div>
        </Panel>
      </div>
    </div>
  );
}

export function SettlementsPage() {
  const settlements = useResource("/settlements");
  const [selectedId, setSelectedId] = useState(null);
  const settlementRow = rows(settlements.data).find((row) => row.Id === selectedId);

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">ĐỐI SOÁT & HOA HỒNG</span>
        <h1>Đối soát doanh thu dịch vụ</h1>
        <p>Kiểm tra số tiền thợ đã thu của khách và khấu trừ hoa hồng theo hợp đồng sàn.</p>
      </div>

      <Panel title="Danh sách đối soát COD">
        <Resource state={settlements}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã đối soát"],
                ["DonHangId", "Đơn hàng"],
                ["KyThuatVienId", "Mã KTV"],
                ["TienCong", "Tiền công thợ", money],
                ["TyLeHoaHong", "Tỷ lệ (%)", (v) => `${v}%`],
                ["TienHoaHong", "Hoa hồng sàn", money],
                ["TrangThai", "Trạng thái", (v) => <span className={`badge ${v === "Confirmed" ? "" : "closed"}`}>{v === "Confirmed" ? "Đã đối soát" : "Chờ đối soát"}</span>],
                ["NgayTao", "Ngày tạo", date],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button className="primary" onClick={() => setSelectedId(row.Id)}>
                    Đối soát
                  </button>
                )
              }
            />
          )}
        </Resource>
      </Panel>

      {settlementRow?.TrangThai === "Pending" && (
        <ActionForm
          key={`settle-${settlementRow.Id}-${settlementRow.PhienBan}`}
          title={`Xác nhận đối soát #${settlementRow.Id} — Đơn #${settlementRow.DonHangId}`}
          path={`/settlements/${settlementRow.Id}/confirm`}
          extra={{ PhienBanDuKien: settlementRow.PhienBan }}
          fields={[]}
          submit="Xác nhận đã đối soát và khấu trừ hoa hồng"
          onDone={() => setSelectedId(null)}
        >
          <p>
            Tiền công: <strong>{money(settlementRow.TienCong)}</strong>. Hoa hồng sàn cần trừ:{" "}
            <strong>{money(settlementRow.TienHoaHong)}</strong>.
          </p>
        </ActionForm>
      )}
    </>
  );
}

export function WalletApprovalPage() {
  const walletRequests = useResource("/wallet/requests");
  const [selectedId, setSelectedId] = useState(null);
  const walletRow = rows(walletRequests.data).find((row) => row.Id === selectedId);

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">QUẢN LÝ VÍ THỢ</span>
        <h1>Duyệt nạp / rút ví kỹ thuật viên</h1>
        <p>Kiểm tra sao kê chứng từ nạp tiền hoặc xác nhận chuyển tiền khi thợ rút ví.</p>
      </div>

      <Panel title="Danh sách yêu cầu nạp / rút ví">
        <Resource state={walletRequests}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã lệnh"],
                ["KyThuatVienId", "Mã thợ"],
                ["Loai", "Loại", (v) => <span className="badge">{v === "Deposit" ? "Nạp tiền" : "Rút tiền"}</span>],
                ["SoTien", "Số tiền", money],
                ["GhiChu", "Ghi chú"],
                ["ChungTuId", "Chứng từ", (v) => (v ? <EvidenceLink id={v} /> : "Không có")],
                ["TrangThai", "Trạng thái", (v) => <span className={`badge ${v === "Approved" ? "" : v === "Rejected" ? "closed" : ""}`}>{v}</span>],
                ["NgayTao", "Thời điểm", date],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button className="primary" onClick={() => setSelectedId(row.Id)}>
                    Xử lý lệnh
                  </button>
                )
              }
            />
          )}
        </Resource>
      </Panel>

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
              label: "Ghi chú đối chiếu / lý do từ chối",
              type: "textarea",
              required: true,
            },
          ]}
          onDone={() => setSelectedId(null)}
        >
          {walletRow.ChungTuId && <EvidenceLink id={walletRow.ChungTuId} />}
        </ActionForm>
      )}
    </>
  );
}

export function BankRequestsPage() {
  const bankRequests = useResource("/bank-requests");
  const [selectedId, setSelectedId] = useState(null);
  const bankRow = rows(bankRequests.data).find((row) => row.Id === selectedId);

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">GIAO DỊCH CHUYỂN KHOẢN</span>
        <h1>Xác nhận thanh toán khách hàng</h1>
        <p>Kiểm tra sao kê ngân hàng và chứng từ khách đã chuyển khoản để thanh toán đơn dịch vụ.</p>
      </div>

      <Panel title="Danh sách yêu cầu thanh toán chuyển khoản">
        <Resource state={bankRequests}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã yêu cầu"],
                ["DonHangId", "Đơn hàng"],
                ["KhachHangId", "Khách hàng"],
                ["SoTien", "Số tiền", money],
                ["MaThamChieu", "Mã tham chiếu"],
                ["ChungTuId", "Chứng từ", (v) => (v ? <EvidenceLink id={v} /> : "Chưa có")],
                ["TrangThai", "Trạng thái", (v) => <span className={`badge ${v === "Confirmed" ? "" : v === "Rejected" ? "closed" : ""}`}>{v}</span>],
                ["NgayTao", "Thời gian", date],
              ]}
              actions={(row) =>
                row.TrangThai === "Pending" && (
                  <button className="primary" onClick={() => setSelectedId(row.Id)}>
                    Kiểm tra sao kê
                  </button>
                )
              }
            />
          )}
        </Resource>
      </Panel>

      {bankRow?.TrangThai === "Pending" && (
        <ActionForm
          key={`bank-${bankRow.Id}-${bankRow.PhienBan}`}
          title={`Xác nhận thanh toán #${bankRow.Id} — Đơn #${bankRow.DonHangId}`}
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
              label: "Mã giao dịch ngân hàng đã kiểm tra",
              defaultValue: bankRow.MaThamChieu,
            },
          ]}
          onDone={() => setSelectedId(null)}
        >
          <p>Đối chiếu sao kê tài khoản ngân hàng trước khi xác nhận.</p>
          {bankRow.ChungTuId && <EvidenceLink id={bankRow.ChungTuId} />}
        </ActionForm>
      )}
    </>
  );
}

export function WalletPage() {
  const wallet = useResource("/wallet");
  const banks = useResource("/bank-accounts");

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">TÀI CHÍNH ĐỐI TÁC</span>
        <h1>Ví kỹ thuật viên & thu nhập</h1>
        <p>Theo dõi số dư khả dụng, lịch sử giao dịch và gửi yêu cầu nạp / rút tiền.</p>
      </div>

      <Resource state={wallet}>
        {(data) => {
          const tech = rows(data.KyThuatVien)[0];
          return (
            <>
              <div className="wallet-hero">
                <span>SỐ DƯ KHẢ DỤNG</span>
                <strong>{money(tech?.SoDu || 0)}</strong>
                <p>
                  Trạng thái: <b>{tech?.TrangThaiSanSang === "SanSang" ? "Sẵn sàng nhận việc" : "Tạm nghỉ"}</b>
                </p>
              </div>

              <div className="two-column">
                <Panel title="Nạp / Rút tiền">
                  <p>
                    Để nạp tiền vào ví nhận việc, hãy chuyển khoản đến tài khoản bên dưới, tải ảnh biên lai và điền mã chứng từ.
                  </p>
                  <Resource state={banks}>
                    {(bData) => (
                      <Table
                        data={bData}
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
                    title="Gửi yêu cầu ví"
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
                        label: "Số tiền (VNĐ)",
                        type: "number",
                        required: true,
                        min: 1000,
                        step: 1000,
                      },
                      {
                        name: "ChungTuId",
                        label: "Mã chứng từ (tải lên ở trên và nhập mã số)",
                        type: "number",
                        min: 1,
                      },
                      {
                        name: "GhiChu",
                        label: "Ghi chú / STK nhận tiền khi rút",
                        type: "textarea",
                        required: true,
                      },
                    ]}
                    submit="Gửi yêu cầu"
                  />
                </Panel>

                <Panel title="Yêu cầu nạp / rút gần đây">
                  <Table
                    data={data.YeuCau}
                    columns={[
                      ["Id", "Mã"],
                      ["Loai", "Loại", (v) => (v === "Deposit" ? "Nạp" : "Rút")],
                      ["SoTien", "Số tiền", money],
                      ["TrangThai", "Trạng thái", (v) => <span className="badge">{v}</span>],
                      ["NgayTao", "Ngày tạo", date],
                    ]}
                  />
                </Panel>
              </div>

              <Panel title="Lịch sử giao dịch ví (Sổ cái)">
                <Table
                  data={data.GiaoDich}
                  columns={[
                    ["Id", "Mã GD"],
                    ["Loai", "Loại"],
                    ["SoTien", "Biến động", money],
                    ["GhiChu", "Nội dung giao dịch"],
                    ["NgayTao", "Thời gian", date],
                  ]}
                />
              </Panel>
            </>
          );
        }}
      </Resource>
    </>
  );
}

export function SupportPage() {
  const { user } = useSession();
  const support = useResource("/support");
  const [selectedId, setSelectedId] = useState(null);
  const ticket = rows(support.data).find((row) => row.Id === selectedId);

  return (
    <>
      <div className="page-head">
        <span className="eyebrow">CHĂM SÓC KHÁCH HÀNG</span>
        <h1>{user.VaiTro === "KH" ? "Hỗ trợ & bảo hành" : "Công việc hỗ trợ khách hàng"}</h1>
        <p>Tiếp nhận, phản hồi và giải quyết các khiếu nại, sự cố kỹ thuật sau dịch vụ.</p>
      </div>

      {user.VaiTro === "KH" && (
        <ActionForm
          title="Tạo phiếu yêu cầu hỗ trợ mới"
          path="/support"
          fields={[
            {
              name: "DonHangId",
              label: "Mã đơn hàng cần hỗ trợ (tùy chọn)",
              type: "number",
              min: 1,
            },
            {
              name: "Loai",
              label: "Loại yêu cầu",
              options: ["Complaint", "Warranty", "Consultation"],
              required: true,
            },
            {
              name: "MoTa",
              label: "Mô tả chi tiết vấn đề",
              type: "textarea",
              required: true,
            },
          ]}
          submit="Gửi yêu cầu hỗ trợ"
        />
      )}

      <Panel title="Danh sách phiếu hỗ trợ">
        <Resource state={support}>
          {(data) => (
            <Table
              data={data}
              columns={[
                ["Id", "Mã phiếu"],
                ["DonHangId", "Đơn hàng"],
                ["Loai", "Phân loại"],
                ["MoTa", "Nội dung yêu cầu"],
                ["TrangThai", "Trạng thái", (v) => <span className="badge">{v}</span>],
                ["KetQuaXuLy", "Kết quả xử lý"],
                ["NgayTao", "Ngày tạo", date],
              ]}
              actions={(row) => (
                <button className="primary" onClick={() => setSelectedId(row.Id)}>
                  Trao đổi
                </button>
              )}
            />
          )}
        </Resource>
      </Panel>

      {ticket && (
        <Panel title={`Trao đổi phiếu hỗ trợ #${ticket.Id}`}>
          <button className="secondary" onClick={() => setSelectedId(null)} style={{ marginBottom: 14 }}>
            Đóng trao đổi
          </button>
          <p><b>Yêu cầu ban đầu:</b> {ticket.MoTa}</p>
          <TicketMessages ticket={ticket} />

          {user.VaiTro === "CSKH" && (
            <ActionForm
              key={`support-${ticket.Id}-${ticket.PhienBan}`}
              title="Cập nhật kết quả xử lý"
              path={`/support/${ticket.Id}`}
              method="PATCH"
              extra={{ PhienBanDuKien: ticket.PhienBan }}
              fields={[
                {
                  name: "TrangThai",
                  label: "Trạng thái xử lý",
                  options: ["InProgress", "Resolved", "Rejected"],
                  required: true,
                },
                {
                  name: "KetQuaXuLy",
                  label: "Kết quả / Ghi chú phản hồi",
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
          title="Gửi phản hồi"
          path={`/support/${ticket.Id}/messages`}
          fields={[
            {
              name: "NoiDung",
              label: "Nội dung trao đổi",
              type: "textarea",
              required: true,
            },
          ]}
          submit="Gửi tin nhắn"
        />
      )}
    </>
  );
}

function EvidenceLink({ id }) {
  const { api } = useSession();
  const [url, setUrl] = useState("");

  async function load() {
    try {
      const blob = await api(`/uploads/${id}`, { blob: true });
      setUrl(URL.createObjectURL(blob));
    } catch {
      setUrl("error");
    }
  }

  if (url === "error") return <small>Lỗi tải chứng từ</small>;
  if (url)
    return (
      <a href={url} target="_blank" rel="noreferrer" className="link">
        Mở chứng từ #{id}
      </a>
    );

  return (
    <button type="button" className="secondary small" onClick={load}>
      Xem chứng từ #{id}
    </button>
  );
}
