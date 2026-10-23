import { SupportPage } from "./support-ui";
import {
  MonitoringSettings,
  ReportOverview,
  CashflowChart,
  useReportData,
} from "./report-widgets";
import { ReportWorkspace, csvDownload } from "./reports-ui";
import { ApplicationWizard } from "./application-wizard";
import { WalletHistory } from "./wallet-history";
import { BankAccounts, BankPaymentQueue } from "./bank-admin";
import React, { useEffect, useRef, useState } from "react";
import { Link, useLocation, useParams } from "react-router-dom";
import {
  Plus,
  Pencil,
  CheckCircle2,
  Wallet,
  ArrowDownToLine,
  ArrowUpFromLine,
  RefreshCw,
  Download,
  Star,
  ShieldCheck,
  Users,
  ChartNoAxesCombined,
  Lock,
  ChevronRight,
  Search,
  UserCircle,
} from "lucide-react";
import { api, upload, uuid } from "./api";
import {
  SearchField,
  matchesSearch,
  useApp,
  useData,
  useAction,
  PageHead,
  Card,
  Field,
  ErrorBox,
  Loading,
  Empty,
  Submit,
  Badge,
  money,
  date,
  code,
  labels,
  orderStatusLabels,
  roleNames,
  groups,
  Modal,
  ProtectedImage,
} from "./shared";
import { Stat } from "./pages";
function Table({
  headers,
  rows,
  render,
  empty = "Chưa có dữ liệu",
  searchable = true,
  className = "",
}) {
  const [query, setQuery] = useState("");
  const fields = [
    "id",
    "fullName",
    "phone",
    "email",
    "name",
    "key",
    "value",
    "label",
    "technicianName",
    "customerName",
    "description",
    "note",
    "status",
    "type",
    "action",
    "entity",
    "detail",
    "actorName",
    "entityId",
    "customerPhone",
    "text",
    "skillGroup",
    "serviceArea",
    "experience",
    "reason",
    "amount",
  ];
  const filtered = (rows || []).filter(
    (row) =>
      !searchable ||
      matchesSearch(query, [
        ...fields.map((key) => row[key]),
        labels[row.status],
        roleNames[row.role],
        groups[row.groupCode || row.skillGroup],
        row.orderId ? code(row.orderId) : "",
        "HT-" + row.id,
        row.type === "Deposit"
          ? "Nạp ví"
          : row.type === "Withdrawal"
            ? "Rút tiền"
            : row.type === "Warranty"
              ? "Bảo hành"
              : "",
      ]),
  );
  return (
    <>
      {searchable && !!rows?.length && (
        <div className="filter-bar">
          <SearchField value={query} onChange={setQuery} />
        </div>
      )}
      {filtered.length ? (
        <div className={"table-wrap " + className}>
          <table>
            <thead>
              <tr>
                {headers.map((h, index) => (
                  <th key={index}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>{filtered.map(render)}</tbody>
          </table>
        </div>
      ) : (
        <Empty title={query ? "Không tìm thấy dữ liệu phù hợp" : empty} />
      )}
    </>
  );
}
function AdminOrders() {
  const [filter, setFilter] = useState({
    search: "",
    status: "",
    serviceGroup: "",
    from: "",
    to: "",
    page: 1,
  });
  const q = new URLSearchParams();
  if (filter.search) q.set("search", filter.search);
  if (filter.status) q.set("status", filter.status);
  if (filter.serviceGroup) q.set("serviceGroup", filter.serviceGroup);
  if (filter.from)
    q.set("from", new Date(filter.from + "T00:00:00+07:00").toISOString());
  if (filter.to) {
    const t = new Date(filter.to + "T00:00:00+07:00");
    t.setDate(t.getDate() + 1);
    q.set("to", t.toISOString());
  }
  q.set("page", filter.page);
  q.set("pageSize", 15);
  const r = useData("/orders?" + q.toString());
  const set = (k, v) =>
    setFilter((s) => ({ ...s, [k]: v, page: k === "page" ? v : 1 }));
  const exportCsv = async () => {
    const blob = await api("/orders.csv?" + q.toString(), { blob: true });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "DanhSachDonHang.csv";
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };
  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title="Đơn sửa chữa & Bảo trì"
        text="Quản lý và tra cứu toàn bộ đơn dịch vụ trên hệ thống."
      >
        <button className="btn" onClick={exportCsv}>
          <Download size={16} /> Xuất CSV
        </button>
      </PageHead>
      <div className="filter-bar">
        <SearchField
          value={filter.search}
          onChange={(value) => set("search", value)}
          placeholder="Mã đơn, tên khách, số điện thoại, dịch vụ, địa chỉ..."
        />
        <Field label="Trạng thái">
          <select
            value={filter.status}
            onChange={(e) => set("status", e.target.value)}
          >
            <option value="">Tất cả</option>
            {Object.entries(orderStatusLabels).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Nhóm dịch vụ">
          <select
            value={filter.serviceGroup}
            onChange={(e) => set("serviceGroup", e.target.value)}
          >
            <option value="">Tất cả</option>
            {Object.entries(groups).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Từ ngày">
          <input
            type="date"
            value={filter.from}
            onChange={(e) => set("from", e.target.value)}
          />
        </Field>
        <Field label="Đến ngày">
          <input
            type="date"
            value={filter.to}
            onChange={(e) => set("to", e.target.value)}
          />
        </Field>
      </div>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          <Table
            className="users-table"
            headers={[
              "Mã đơn",
              "Dịch vụ",
              "Khách hàng",
              "Kỹ thuật viên",
              "Ngày tạo",
              "Trạng thái",
              "Thao tác",
            ]}
            rows={r.data}
            render={(o) => (
              <tr key={o.id}>
                <td>
                  <b>{code(o.id)}</b>
                </td>
                <td>
                  {o.serviceName}
                  <small>{groups[o.serviceGroup]}</small>
                </td>
                <td>
                  {o.contactName}
                  <small>{o.contactPhone}</small>
                </td>
                <td>{o.technicianName || "—"}</td>
                <td>{date(o.createdAt)}</td>
                <td>
                  <Badge value={o.status} />
                </td>
                <td>
                  <Link className="btn small" to={"/orders/" + o.id}>
                    Chi tiết
                  </Link>
                </td>
              </tr>
            )}
          />
        </Card>
      )}
      <div className="pagination">
        <button
          className="btn"
          disabled={filter.page === 1}
          onClick={() => set("page", filter.page - 1)}
        >
          Trang trước
        </button>
        <span>Trang {filter.page}</span>
        <button
          className="btn"
          disabled={!r.meta || filter.page * 15 >= r.meta.total}
          onClick={() => set("page", filter.page + 1)}
        >
          Trang sau
        </button>
      </div>
    </>
  );
}
function AdminUsers() {
  const [search, setSearch] = useState("");
  const r = useData("/users?pageSize=200&search=" + encodeURIComponent(search));
  const action = useAction();
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    fullName: "",
    phone: "",
    initialPassword: "",
    role: "KH",
  });
  const rows = r.data || [];
  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title="Danh sách tài khoản hệ thống"
        text="Quản lý tài khoản và vai trò sử dụng HomeFix"
      >
        <button className="btn" onClick={r.reload}>
          <RefreshCw size={16} /> Cập nhật
        </button>
        <button className="btn primary" onClick={() => setCreating(true)}>
          <Plus size={17} /> Thêm tài khoản
        </button>
      </PageHead>
      <div className="filter-bar">
        <Field label="Tìm kiếm">
          <input
            type="search"
            placeholder="Họ tên, số điện thoại, email, vai trò..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </Field>
      </div>
      <ErrorBox error={r.error || action.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          <Table
            className="users-table"
            headers={[
              "Họ và tên",
              "Số điện thoại",
              "Email",
              "Vai trò",
              "Chuyên môn",
              "Trạng thái",
              "Thao tác",
            ]}
            rows={rows}
            searchable={false}
            render={(u) => (
              <tr key={u.id}>
                <td>
                  <div className="row">
                    <span className="avatar">{u.fullName?.slice(0, 1)}</span>
                    <b>{u.fullName}</b>
                  </div>
                </td>
                <td>{u.phone}</td>
                <td>{u.email || "—"}</td>
                <td>
                  <select
                    aria-label={"Vai trò của " + u.fullName}
                    value={u.role}
                    disabled
                    onChange={(e) =>
                      action.run(async () => {
                        await api("/users/" + u.id + "/role", {
                          method: "PATCH",
                          body: {
                            role: e.target.value,
                            expectedVersion: u.version,
                          },
                        });
                        r.reload();
                      })
                    }
                  >
                    {Object.entries(roleNames).map(([value, label]) => (
                      <option key={value} value={value}>
                        {label}
                      </option>
                    ))}
                  </select>
                </td>
                <td>
                  {u.role === "KTV"
                    ? groups[u.skillGroup] || u.skillGroup || "Chưa cập nhật"
                    : "—"}
                </td>
                <td>
                  <span className={"badge " + (u.isActive ? "green" : "red")}>
                    {u.isActive ? "Hoạt động" : "Bị khóa"}
                  </span>
                </td>
                <td>
                  <button
                    className="btn small"
                    disabled={action.busy}
                    onClick={() => setEditing({ ...u, email: u.email || "" })}
                  >
                    <Pencil size={14} /> Sửa
                  </button>{" "}
                  <button
                    className={"btn small " + (u.isActive ? "danger" : "")}
                    disabled={action.busy}
                    onClick={() =>
                      action.run(async () => {
                        await api("/users/" + u.id + "/status", {
                          method: "PATCH",
                          body: {
                            isActive: !u.isActive,
                            expectedVersion: u.version,
                          },
                        });
                        r.reload();
                      })
                    }
                  >
                    {u.isActive ? "Khóa" : "Mở khóa"}
                  </button>
                </td>
              </tr>
            )}
          />
        </Card>
      )}
      {creating && (
        <Modal title="Thêm tài khoản" onClose={() => setCreating(false)}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              action.run(async () => {
                await api("/users", { method: "POST", body: form });
                setCreating(false);
                setForm({
                  fullName: "",
                  phone: "",
                  initialPassword: "",
                  role: "KH",
                });
                r.reload();
              });
            }}
          >
            <ErrorBox error={action.error} />
            {[
              ["fullName", "Họ tên", "text"],
              ["phone", "Số điện thoại", "tel"],
              ["initialPassword", "Mật khẩu (từ 6 ký tự)", "password"],
            ].map(([key, label, type]) => (
              <Field key={key} label={label}>
                <input
                  required
                  type={type}
                  minLength={type === "password" ? 6 : undefined}
                  value={form[key]}
                  onChange={(e) => setForm({ ...form, [key]: e.target.value })}
                />
              </Field>
            ))}
            <Field label="Vai trò">
              <select
                value={form.role}
                onChange={(e) => setForm({ ...form, role: e.target.value })}
              >
                {Object.entries(roleNames).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </Field>
            <div className="form-actions">
              <button
                type="button"
                className="btn"
                onClick={() => setCreating(false)}
              >
                Hủy
              </button>
              <Submit busy={action.busy}>Tạo tài khoản</Submit>
            </div>
          </form>
        </Modal>
      )}
      {editing && (
        <Modal title="Sửa thông tin tài khoản" onClose={() => setEditing(null)}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              action.run(async () => {
                await api("/users/" + editing.id, {
                  method: "PATCH",
                  body: {
                    ...editing,
                    expectedVersion: editing.version,
                  },
                });
                setEditing(null);
                r.reload();
              });
            }}
          >
            <ErrorBox error={action.error} />
            <Field label="Họ và tên">
              <input
                required
                value={editing.fullName}
                onChange={(e) =>
                  setEditing({ ...editing, fullName: e.target.value })
                }
              />
            </Field>
            <Field label="Số điện thoại">
              <input
                required
                inputMode="numeric"
                value={editing.phone}
                onChange={(e) =>
                  setEditing({ ...editing, phone: e.target.value })
                }
              />
            </Field>
            <Field label="Email">
              <input
                type="email"
                value={editing.email}
                onChange={(e) => setEditing({ ...editing, email: e.target.value })}
              />
            </Field>
            <Field label="Vai trò">
              <select
                value={editing.role}
                onChange={(e) =>
                  setEditing({
                    ...editing,
                    role: e.target.value,
                    skillGroup:
                      e.target.value === "KTV"
                        ? editing.skillGroup || "DIEN"
                        : "",
                  })
                }
              >
                {Object.entries(roleNames).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </Field>
            {editing.role === "KTV" && (
              <Field label="Chuyên môn">
                <select
                  required
                  value={editing.skillGroup || ""}
                  onChange={(e) =>
                    setEditing({ ...editing, skillGroup: e.target.value })
                  }
                >
                  {Object.entries(groups).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </select>
              </Field>
            )}
            <Field label="Trạng thái">
              <select
                value={editing.isActive ? "active" : "inactive"}
                onChange={(e) =>
                  setEditing({
                    ...editing,
                    isActive: e.target.value === "active",
                  })
                }
              >
                <option value="active">Hoạt động</option>
                <option value="inactive">Bị khóa</option>
              </select>
            </Field>
            <div className="form-actions">
              <button type="button" className="btn" onClick={() => setEditing(null)}>
                Hủy
              </button>
              <Submit busy={action.busy}>Lưu thay đổi</Submit>
            </div>
          </form>
        </Modal>
      )}
    </>
  );
}
export function Management() {
  const { toast } = useApp(),
    { section } = useParams();
  if (section === "orders") return <AdminOrders />;
  if (section === "users") return <AdminUsers />;
  const path = {
    services: "/admin/services",
    settings: "/settings",
    audit: "/audit-logs",
  }[section];
  const r = useData(path),
    [edit, setEdit] = useState(null);
  const title = {
    services: "Danh mục dịch vụ",
    settings: "Cấu hình nghiệp vụ",
    audit: "Nhật ký hệ thống",
  }[section];
  const refresh = () => {
    r.reload();
    toast("Đã gửi yêu cầu tải lại dữ liệu.");
  };
  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title={title || "Quản trị"}
        text={
          section === "audit"
            ? "Các thao tác quan trọng được ghi lại để tra cứu."
            : "Quản lý danh mục và cấu hình hệ thống."
        }
      >
        {["services"].includes(section) && (
          <button className="btn primary" onClick={() => setEdit({})}>
            <Plus size={17} /> Thêm dịch vụ
          </button>
        )}
        <button className="btn" onClick={refresh}>
          <RefreshCw size={16} /> Cập nhật
        </button>
      </PageHead>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          {section === "services" && (
            <Table
              headers={[
                "Dịch vụ",
                "Nhóm",
                "Phí kiểm tra / công",
                "Hoa hồng",
                "Trạng thái",
                "",
              ]}
              rows={r.data}
              render={(s) => (
                <tr key={s.id}>
                  <td>
                    <b>{s.name}</b>
                    <small>{s.description}</small>
                  </td>
                  <td>{groups[s.groupCode]}</td>
                  <td>
                    {money(s.inspectionFee)}
                    <small>{money(s.laborFee)} tiền công</small>
                  </td>
                  <td>{Number(s.commissionRatePercent)}%</td>
                  <td>
                    <span className={"badge " + (s.isActive ? "green" : "red")}>
                      {s.isActive ? "Đang cung cấp" : "Đã ẩn"}
                    </span>
                  </td>
                  <td>
                    <button className="btn small" onClick={() => setEdit(s)}>
                      <Pencil size={14} /> Sửa
                    </button>
                  </td>
                </tr>
              )}
            />
          )}
          {section === "settings" && (
            <Table
              headers={["Tham số", "Giá trị", "Thao tác"]}
              rows={r.data}
              render={(s) => (
                <tr key={s.key}>
                  <td>
                    <b>{s.label}</b>
                    <small>{s.key}</small>
                  </td>
                  <td>
                    {s.key === "signatureRequired"
                      ? s.value === "true"
                        ? "Bắt buộc"
                        : "Không bắt buộc"
                      : s.value}
                  </td>
                  <td>
                    <button className="btn small" onClick={() => setEdit(s)}>
                      Điều chỉnh
                    </button>
                  </td>
                </tr>
              )}
            />
          )}
          {section === "audit" && (
            <Table
              headers={[
                "Thời gian",
                "Người thực hiện",
                "Thao tác",
                "Đối tượng",
                "Chi tiết",
              ]}
              rows={r.data}
              render={(a) => (
                <tr key={a.id}>
                  <td>{date(a.createdAt)}</td>
                  <td>
                    {a.actorId
                      ? `#${a.actorId} · ${a.actorName || "Chưa có tên"}`
                      : "Hệ thống"}
                  </td>
                  <td>{a.action}</td>
                  <td>
                    {a.entity} #{a.entityId || "—"}
                  </td>
                  <td>{a.detail || "—"}</td>
                </tr>
              )}
            />
          )}
        </Card>
      )}
      {section === "settings" && <BankAccounts />}
      {edit && (
        <Editor
          section={section}
          record={edit}
          onClose={() => setEdit(null)}
          onDone={() => {
            setEdit(null);
            r.reload();
          }}
        />
      )}
    </>
  );
}
function Editor({ section, record, onClose, onDone }) {
  const a = useAction();
  const [form, setForm] = useState(
    section === "services"
      ? {
          name: record.name || "",
          groupCode: record.groupCode || "DIEN_LANH",
          description: record.description || "",
          inspectionFee: String(record.inspectionFee ?? "50000"),
          laborFee: String(record.laborFee ?? "300000"),
          commissionRatePercent: String(record.commissionRatePercent ?? "15"),
          isActive: record.isActive ?? true,
        }
      : { value: record.value },
  );
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));
  const input = (k, label, type = "text", required = true) => (
    <Field label={label}>
      <input
        type={type}
        required={required}
        value={form[k]}
        onChange={(e) => set(k, e.target.value)}
      />
    </Field>
  );
  return (
    <Modal
      title={
        section === "settings"
          ? "Điều chỉnh " + record.label
          : (record.id ? "Cập nhật" : "Thêm") + " " + "dịch vụ"
      }
      onClose={onClose}
    >
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            let path, body;
            if (section === "services") {
              path = "/services" + (record.id ? "/" + record.id : "");
              body = {
                ...form,
                ...(record.id ? { expectedVersion: record.version } : {}),
              };
            } else {
              path = "/settings/" + record.key;
              body = { value: form.value, expectedVersion: record.version };
            }
            await api(path, {
              method: record.id || section === "settings" ? "PATCH" : "POST",
              body,
            });
            onDone();
          });
        }}
      >
        <ErrorBox error={a.error} />
        {section === "services" && (
          <>
            {input("name", "Tên dịch vụ")}
            <Field label="Nhóm dịch vụ">
              <select
                value={form.groupCode}
                onChange={(e) => set("groupCode", e.target.value)}
              >
                {Object.entries(groups).map(([k, n]) => (
                  <option key={k} value={k}>
                    {n}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Mô tả">
              <textarea
                required
                minLength={5}
                value={form.description}
                onChange={(e) => set("description", e.target.value)}
              />
            </Field>
            <div className="form-grid">
              {input("inspectionFee", "Phí kiểm tra (đ)", "number")}
              {input("laborFee", "Tiền công (đ)", "number")}
              {input(
                "commissionRatePercent",
                "Hoa hồng trên tiền công (%)",
                "number",
              )}
            </div>
            <label className="checkbox">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) => set("isActive", e.target.checked)}
              />{" "}
              Dịch vụ đang được cung cấp
            </label>
            <small>
              Giá mới áp dụng cho báo giá lập sau khi lưu. Không sửa chi phí đã
              được khách duyệt.
            </small>
          </>
        )}
        {section === "settings" &&
          (record.key === "signatureRequired" ? (
            <Field label="Yêu cầu chữ ký">
              <select
                value={form.value}
                onChange={(e) => set("value", e.target.value)}
              >
                <option value="false">Không bắt buộc</option>
                <option value="true">Bắt buộc ảnh chữ ký KH</option>
              </select>
            </Field>
          ) : (
            input(
              "value",
              "Giá trị mới",
              ["TyLeHoaHongMacDinh", "TaiKhoanNganHangMacDinh"].includes(
                record.key,
              )
                ? "number"
                : "text",
            )
          ))}
        <div className="form-actions">
          <button className="btn" type="button" onClick={onClose}>
            Hủy
          </button>
          <Submit busy={a.busy} />
        </div>
      </form>
    </Modal>
  );
}
export function Finance() {
  const requestedTab = new URLSearchParams(useLocation().search).get("tab"),
    tab = ["revenue", "bank", "wallet"].includes(requestedTab)
      ? requestedTab
      : "revenue",
    [selected, setSelected] = useState(null),
    exportAction = useAction();
  const settlements = useData(tab === "revenue" ? "/settlements" : null, 15000),
    walletRequests = useData(
      tab === "wallet" ? "/wallet-requests" : null,
      15000,
    );
  const finishDecision = async () => {
    const isSettlement = selected?.type === "settlement";
    const result = await api(
      isSettlement ? "/settlements" : "/wallet-requests",
    );
    (isSettlement ? settlements : walletRequests).setData(result.data);
    setSelected(null);
  };
  const download = () =>
    exportAction.run(async () => {
      const blob = await api("/reports/finance.csv", { blob: true }),
        url = URL.createObjectURL(blob),
        link = document.createElement("a");
      link.href = url;
      link.download = "HomeFix_DoiSoatDoanhThu.csv";
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }, "Đã tải báo cáo đối soát.");
  if (tab === "revenue")
    return (
      <>
        <RevenueReconciliation
          rows={settlements.data || []}
          loading={settlements.loading}
          error={settlements.error || exportAction.error}
          busy={exportAction.busy}
          onDownload={download}
          onSettle={(row) => setSelected({ type: "settlement", row })}
        />
        {selected && (
          <FinanceDecision
            {...selected}
            onClose={() => setSelected(null)}
            onDone={finishDecision}
          />
        )}
      </>
    );
  if (tab === "bank")
    return (
      <>
        <PageHead
          eyebrow="TÀI CHÍNH HOMEFIX"
          title="Giao dịch chuyển khoản"
          text="Kiểm tra chứng từ và xác minh các khoản thanh toán chuyển khoản trước khi ghi nhận."
        />
        <BankPaymentQueue />
      </>
    );
  return (
    <>
      <PageHead
        eyebrow="TÀI CHÍNH HOMEFIX"
        title="Duyệt Ví KTV"
        text="Kiểm tra và xử lý yêu cầu nạp, rút ví của kỹ thuật viên."
      />
      <ErrorBox error={settlements.error || walletRequests.error} />
      <Card title="Yêu cầu nạp / rút ví">
        <Table
          headers={[
            "Yêu cầu",
            "Kỹ thuật viên",
            "Số tiền",
            "Trạng thái",
            "Thao tác",
          ]}
          rows={walletRequests.data}
          render={(w) => (
            <tr key={w.id}>
              <td>
                <b>{w.type === "Deposit" ? "Nạp ví" : "Rút tiền"}</b>
                <small>{date(w.createdAt)}</small>
              </td>
              <td>
                {w.technicianName}
                <small>{w.note}</small>
              </td>
              <td>{money(w.amount)}</td>
              <td>
                <Badge value={w.status} />
              </td>
              <td>
                <button
                  className="btn small"
                  onClick={() => setSelected({ type: "wallet", row: w })}
                >
                  {w.status === "Pending" ? "Xem & xử lý" : "Xem chi tiết"}
                </button>
              </td>
            </tr>
          )}
        />
      </Card>
      {selected && (
        <FinanceDecision
          {...selected}
          onClose={() => setSelected(null)}
          onDone={finishDecision}
        />
      )}
    </>
  );
}
function RevenueReconciliation({
  rows = [],
  loading,
  error,
  busy,
  onDownload,
  onSettle,
}) {
  const [query, setQuery] = useState(""),
    [status, setStatus] = useState("Pending");
  const filtered = rows.filter(
    (row) =>
      (status === "All" || row.status === status) &&
      matchesSearch(query, [
        code(row.orderId),
        row.technicianName,
        "KTV-" + row.technicianId,
        row.method === "BANK" ? "Chuyển khoản" : "Tiền mặt COD",
        row.amount,
      ]),
  );
  const codTotal = rows
      .filter((row) => row.method === "COD")
      .reduce((sum, row) => sum + Number(row.amount || 0), 0),
    commissionTotal = rows.reduce(
      (sum, row) => sum + Number(row.commissionAmount || 0),
      0,
    ),
    pending = rows.filter((row) => row.status === "Pending").length,
    displayedTotal = filtered.reduce(
      (sum, row) => sum + Number(row.amount || 0),
      0,
    ),
    displayedMaterials = filtered.reduce(
      (sum, row) => sum + Number(row.materialTotal || 0),
      0,
    ),
    displayedLabor = filtered.reduce(
      (sum, row) => sum + Number(row.laborFee || 0),
      0,
    );
  return (
    <div className="reconciliation-page">
      <div className="reconciliation-heading">
        <div>
          <div className="breadcrumb-text">
            HomeFix <span>›</span> Đối soát doanh thu
          </div>
          <h1>Đối soát thanh toán</h1>
          <p>
            Kiểm tra từng đơn đã thu tiền và xác nhận khoản ghi ví kỹ thuật
            viên.
          </p>
        </div>
        <div className="reconciliation-actions">
          <button className="btn" disabled={busy} onClick={onDownload}>
            <Download size={17} /> Xuất báo cáo
          </button>
        </div>
      </div>
      <ErrorBox error={error} />
      <section className="reconciliation-kpis">
        <ReconciliationKpi
          label="Tổng tiền mặt KTV thu COD"
          value={money(codTotal)}
          icon={<Wallet size={24} />}
          tone="green"
        />
        <ReconciliationKpi
          label="Hoa hồng theo đơn"
          value={money(commissionTotal)}
          icon={<ShieldCheck size={24} />}
          tone="blue"
        />
        <ReconciliationKpi
          label="Số đơn chưa đối soát"
          value={`${pending} đơn hàng`}
          icon={<CheckCircle2 size={24} />}
          tone="red"
        />
      </section>
      <section className="reconciliation-filter">
        <label>
          Trạng thái:
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
          >
            <option value="Pending">Chưa đối soát</option>
            <option value="Confirmed">Đã đối soát</option>
            <option value="All">Tất cả</option>
          </select>
        </label>
        <div>
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Lọc theo mã thợ, tên kỹ thuật viên hoặc mã đơn hàng..."
          />
        </div>
      </section>
      {loading ? (
        <Loading />
      ) : (
        <div className="reconciliation-table table-wrap">
          <table>
            <thead>
              <tr>
                <th>Mã đơn hàng</th>
                <th>Kỹ thuật viên</th>
                <th>Tổng tiền khách trả</th>
                <th>Kiểm tra / di chuyển</th>
                <th>Tiền vật tư</th>
                <th>Phí nhân công</th>
                <th>% Hoa hồng</th>
                <th>Ghi ví KTV</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length ? (
                filtered.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <Link to={"/orders/" + row.orderId}>
                        {code(row.orderId)}
                      </Link>
                    </td>
                    <td>
                      <b>{row.technicianName}</b>
                      <small>KTV-{row.technicianId}</small>
                    </td>
                    <td>
                      {money(row.amount)}
                      <small>
                        {row.method === "BANK"
                          ? "Chuyển khoản"
                          : "Tiền mặt COD"}
                      </small>
                    </td>
                    <td>
                      {money(
                        Number(row.inspectionFee || 0) +
                          Number(row.travelFee || 0),
                      )}
                      {row.travelFee > 0 && <small>Phí di chuyển</small>}
                    </td>
                    <td>{money(row.materialTotal)}</td>
                    <td>{money(row.laborFee)}</td>
                    <td>{Number(row.commissionRatePercent || 0)}%</td>
                    <td>
                      <b>
                        {money(
                          row.method === "BANK"
                            ? row.technicianCredit
                            : -Number(row.commissionAmount),
                        )}
                      </b>
                    </td>
                    <td>
                      <span
                        className={
                          "reconciliation-status " +
                          (row.status === "Confirmed" ? "confirmed" : "pending")
                        }
                      >
                        {row.status === "Confirmed"
                          ? "Đã đối soát"
                          : "Chờ đối soát"}
                      </span>
                    </td>
                    <td>
                      {row.status === "Pending" && (
                        <button
                          className="btn small primary"
                          onClick={() => onSettle(row)}
                        >
                          Đối soát
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="10" className="reconciliation-empty">
                    Chưa có đơn phù hợp với bộ lọc.
                  </td>
                </tr>
              )}
            </tbody>
            {filtered.length > 0 && (
              <tfoot>
                <tr>
                  <td colSpan="2">Tổng các dòng hiển thị</td>
                  <td>{money(displayedTotal)}</td>
                  <td>
                    {money(
                      filtered.reduce(
                        (sum, row) =>
                          sum +
                          Number(row.inspectionFee || 0) +
                          Number(row.travelFee || 0),
                        0,
                      ),
                    )}
                  </td>
                  <td>{money(displayedMaterials)}</td>
                  <td>{money(displayedLabor)}</td>
                  <td>—</td>
                  <td>
                    {money(
                      filtered.reduce(
                        (total, row) =>
                          total +
                          Number(
                            row.method === "BANK"
                              ? row.technicianCredit
                              : -Number(row.commissionAmount),
                          ),
                        0,
                      ),
                    )}
                  </td>
                  <td>—</td>
                  <td>—</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}
    </div>
  );
}
function ReconciliationKpi({ label, value, icon, tone }) {
  return (
    <article className={"reconciliation-kpi " + tone}>
      <span>{icon}</span>
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
      </div>
    </article>
  );
}
function FinanceDecision({ type, row, onClose, onDone }) {
  const a = useAction(),
    requestKey = useRef(uuid()),
    [decision, setDecision] = useState("Approved"),
    [reason, setReason] = useState("");
  return (
    <Modal
      title={
        type === "settlement"
          ? "Xác nhận đối soát thanh toán"
          : "Xử lý yêu cầu ví"
      }
      onClose={() => {
        if (!a.busy) onClose();
      }}
    >
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            await api(
              type === "settlement"
                ? `/settlements/${row.id}/confirm`
                : `/wallet-requests/${row.id}/decision`,
              {
                method: "POST",
                body:
                  type === "settlement"
                    ? { expectedVersion: row.version }
                    : {
                        decision,
                        expectedVersion: row.version,
                        ...(reason ? { reason } : {}),
                      },
                key: requestKey.current,
              },
            );
            await onDone();
          });
        }}
      >
        <p>
          <b>{row.technicianName}</b>
        </p>
        {type === "settlement" && (
          <p>
            Đồng ý đối soát đơn <b>{code(row.orderId)}</b> đã thu{" "}
            <b>{money(row.amount)}</b>? Hoa hồng:{" "}
            <b>{money(row.commissionAmount)}</b>.
          </p>
        )}
        <div className="confirmation-amount">
          {money(
            type === "settlement"
              ? row.method === "BANK"
                ? row.technicianCredit
                : row.commissionAmount
              : row.amount,
          )}
        </div>
        {type === "settlement" ? (
          <p>
            {row.paymentType === "PhiHuyDon"
              ? "Phí hủy đơn được chuyển đủ vào ví KTV để bù chi phí di chuyển; không trừ hoa hồng. Đơn vẫn giữ trạng thái đã hủy."
              : row.method === "BANK"
                ? "HomeFix đã nhận chuyển khoản. Số tiền trên là phần thuộc KTV sau hoa hồng, gồm phí kiểm tra và vật tư; hệ thống cộng vào ví đúng một lần. KTV có thể yêu cầu rút tiền sau đó."
                : "KTV đã nhận tiền mặt trực tiếp. Hệ thống chỉ trừ hoa hồng từ ví đúng một lần, không cộng tiền mặt vào ví."}
          </p>
        ) : (
          <>
            <p>{row.note}</p>
            <Badge value={row.status} />
            {row.proofId && (
              <div className="image-grid">
                <ProtectedImage id={row.proofId} alt="Chứng từ yêu cầu ví" />
              </div>
            )}
            {row.status === "Pending" && (
              <>
                <Field label="Kết quả xét duyệt">
                  <select
                    value={decision}
                    onChange={(e) => setDecision(e.target.value)}
                  >
                    <option value="Approved">Đồng ý và ghi sổ</option>
                    <option value="Rejected">Từ chối</option>
                  </select>
                </Field>
                <Field label="Lý do / ghi chú">
                  <textarea
                    required={decision === "Rejected"}
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                  />
                </Field>
                <small>
                  Đây là xét duyệt thủ công. Chỉ đồng ý khi đã kiểm tra chứng từ
                  / việc chi tiền thực tế.
                </small>
              </>
            )}
          </>
        )}
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <button
            className="btn"
            type="button"
            disabled={a.busy}
            onClick={onClose}
          >
            Đóng
          </button>
          {(type === "settlement" || row.status === "Pending") && (
            <Submit busy={a.busy}>
              {type === "settlement" ? "Đồng ý đối soát" : "Xác nhận xử lý"}
            </Submit>
          )}
        </div>
      </form>
    </Modal>
  );
}
export function WalletPage() {
  const location = useLocation(),
    [revision, setRevision] = useState(0);
  const wallet = useData("/technicians/me/wallet"),
    income = useData("/technicians/me/income"),
    requests = useData("/wallet-requests"),
    a = useAction();
  const [type, setType] = useState(
    new URLSearchParams(location.search).get("request") === "Deposit"
      ? "Deposit"
      : null,
  );
  const refresh = () => {
    wallet.reload();
    income.reload();
    requests.reload();
    setRevision((v) => v + 1);
  };
  return (
    <>
      <PageHead
        eyebrow="VÍ KỸ THUẬT VIÊN"
        title="Ví & thu nhập"
        text="Tiền chuyển khoản được cộng vào ví sau đối soát và trừ hoa hồng; tiền mặt đã nhận chỉ trừ hoa hồng."
      >
        <button className="btn" onClick={refresh}>
          <RefreshCw size={16} /> Cập nhật
        </button>
      </PageHead>
      <ErrorBox error={wallet.error || requests.error || a.error} />
      <section className="wallet-hero">
        <span>Số dư ví hiện tại</span>
        <strong>{money(wallet.data?.balance)}</strong>
        <div className="actions">
          <button className="btn white" onClick={() => setType("Deposit")}>
            <Plus size={17} /> Nạp ví
          </button>
          <button className="btn glass" onClick={() => setType("Withdrawal")}>
            <ArrowUpFromLine size={17} /> Yêu cầu rút
          </button>
        </div>
      </section>
      <div className="stat-grid three">
        <Stat
          label="Thu nhập trước chi phí khác"
          value={money(income.data?.income)}
          icon={Wallet}
        />
        <Stat
          label="Hoàn chi vật tư"
          value={money(income.data?.materialReimbursement)}
          icon={ShieldCheck}
        />
        <Stat
          label="Đơn đã thu tiền"
          value={income.data?.completedOrders || 0}
        />
      </div>
      <Card title="Yêu cầu nạp / rút">
        <Table
          headers={["Loại yêu cầu", "Số tiền", "Thời gian", "Trạng thái", ""]}
          rows={requests.data}
          render={(r) => (
            <tr key={r.id}>
              <td>
                {r.type === "Deposit" ? "Nạp ví" : "Rút tiền"}
                <small>{r.note}</small>
              </td>
              <td>{money(r.amount)}</td>
              <td>{date(r.createdAt)}</td>
              <td>
                <Badge value={r.status} />
                {r.reason && <small>{r.reason}</small>}
              </td>
              <td>
                {r.status === "Pending" && (
                  <button
                    className="btn small danger"
                    disabled={a.busy}
                    onClick={() =>
                      a.run(async () => {
                        await api(`/wallet-requests/${r.id}/cancel`, {
                          method: "POST",
                          body: { expectedVersion: r.version },
                        });
                        refresh();
                      })
                    }
                  >
                    Hủy yêu cầu
                  </button>
                )}
              </td>
            </tr>
          )}
        />
      </Card>
      <WalletHistory revision={revision} />
      {type && (
        <WalletRequest
          key={type}
          type={type}
          balance={wallet.data?.balance}
          availableBalance={wallet.data?.availableBalance}
          onTypeChange={setType}
          onClose={() => setType(null)}
          onDone={() => {
            setType(null);
            refresh();
          }}
        />
      )}
    </>
  );
}
function WalletRequest({
  type,
  balance,
  availableBalance,
  onTypeChange,
  onClose,
  onDone,
}) {
  const a = useAction(),
    [amount, setAmount] = useState(""),
    [note, setNote] = useState(""),
    [bank, setBank] = useState({ name: "", account: "", holder: "" }),
    [file, setFile] = useState(null),
    proof = useRef(null),
    requestKey = useRef(uuid());
  return (
    <Modal
      title={type === "Deposit" ? "Yêu cầu nạp ví" : "Yêu cầu rút tiền"}
      onClose={onClose}
    >
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            if (
              type === "Withdrawal" &&
              Number(amount) > Number(availableBalance)
            )
              throw new Error(
                "Số tiền rút vượt số dư khả dụng sau khi tính các yêu cầu đang chờ.",
              );
            if (file && !proof.current)
              proof.current = (await upload(file, "WalletProof")).id;
            await api("/wallet-requests", {
              method: "POST",
              body: {
                type,
                amount,
                note:
                  type === "Withdrawal"
                    ? `${bank.name} · STK ${bank.account} · ${bank.holder}. ${note}`
                    : note,
                ...(proof.current ? { proofId: proof.current } : {}),
              },
              key: requestKey.current,
            });
            onDone();
          });
        }}
      >
        <div className="segmented-control">
          {[
            ["Deposit", "Nạp tiền"],
            ["Withdrawal", "Rút tiền"],
          ].map(([key, name]) => (
            <button
              key={key}
              type="button"
              disabled={a.busy}
              className={"btn " + (type === key ? "primary" : "")}
              onClick={() => onTypeChange(key)}
            >
              {name}
            </button>
          ))}
        </div>
        <div className="notice info">
          Yêu cầu rút sẽ giữ chỗ số tiền tương ứng trong khi chờ kế toán xét
          duyệt. Hủy hoặc bị từ chối sẽ giải phóng khoản giữ chỗ; tiền chỉ được
          trừ khi kế toán duyệt.
        </div>
        <Field label="Số tiền (đ)">
          <input
            required
            min="1"
            max={
              type === "Withdrawal"
                ? Math.min(Number(availableBalance || 0), 100000000)
                : 100000000
            }
            step="1"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </Field>
        <div className="quick-amounts">
          {[500000, 1000000, 2500000].map((v) => (
            <button
              key={v}
              className="btn"
              type="button"
              disabled={type === "Withdrawal" && v > Number(availableBalance)}
              onClick={() => setAmount(String(v))}
            >
              {money(v)}
            </button>
          ))}
          {type === "Withdrawal" && (
            <button
              type="button"
              className="btn"
              onClick={() =>
                setAmount(
                  String(Math.min(Number(availableBalance || 0), 100000000)),
                )
              }
            >
              Tất cả
            </button>
          )}
        </div>
        {type === "Withdrawal" && (
          <>
            <p>
              Số dư hiện tại: <b>{money(balance)}</b>. Khả dụng để rút:{" "}
              <b>{money(availableBalance)}</b>
            </p>
            <Field label="Ngân hàng nhận tiền">
              <input
                required
                maxLength={100}
                value={bank.name}
                onChange={(e) => setBank({ ...bank, name: e.target.value })}
              />
            </Field>
            <Field label="Số tài khoản nhận tiền">
              <input
                required
                inputMode="numeric"
                pattern="[0-9]{6,30}"
                value={bank.account}
                onChange={(e) => setBank({ ...bank, account: e.target.value })}
              />
            </Field>
            <Field label="Chủ tài khoản">
              <input
                required
                maxLength={100}
                value={bank.holder}
                onChange={(e) => setBank({ ...bank, holder: e.target.value })}
              />
            </Field>
          </>
        )}
        <Field
          label={type === "Withdrawal" ? "Ghi chú rút tiền" : "Nội dung nạp ví"}
        >
          <textarea
            required={type === "Deposit"}
            minLength={type === "Deposit" ? 5 : 0}
            maxLength={600}
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </Field>
        {type === "Deposit" && (
          <Field label="Ảnh chứng từ">
            <input
              required
              type="file"
              accept="image/png,image/jpeg"
              onChange={(e) => {
                setFile(e.target.files[0]);
                proof.current = null;
              }}
            />
          </Field>
        )}
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <button
            className="btn"
            type="button"
            disabled={a.busy}
            onClick={onClose}
          >
            Quay lại
          </button>
          <Submit busy={a.busy}>Gửi yêu cầu</Submit>
        </div>
      </form>
    </Modal>
  );
}
export function Support() {
  return <SupportPage />;
}
export function Applications() {
  const { user } = useApp(),
    r = useData(
      user.role === "ADMIN"
        ? "/technician-applications"
        : "/technician-applications/me",
    ),
    a = useAction();
  const [selected, setSelected] = useState(null);
  return (
    <>
      <PageHead
        eyebrow="ĐỘI NGŨ HOMEFIX"
        title={
          user.role === "ADMIN"
            ? "Xét duyệt hồ sơ kỹ thuật viên"
            : "Đăng ký cộng tác kỹ thuật viên"
        }
        text="Hồ sơ được quản trị viên kiểm tra trước khi cấp quyền nhận việc."
      />
      <ErrorBox error={r.error || a.error} />
      {user.role === "KH" && !r.data?.some((x) => x.status === "Pending") && (
        <ApplicationWizard onDone={r.reload} />
      )}
      <Card title="Hồ sơ đã gửi">
        <Table
          headers={["Người nộp", "Chuyên môn", "Kinh nghiệm", "Trạng thái", ""]}
          rows={r.data}
          render={(h) => (
            <tr key={h.id}>
              <td>
                {h.fullName || user.fullName}
                <small>{date(h.createdAt)}</small>
              </td>
              <td>
                {groups[h.skillGroup] || h.skillGroup || "Chưa cập nhật"}
                <small>{h.serviceArea}</small>
              </td>
              <td>{h.experience}</td>
              <td>
                <Badge value={h.status} />
                <small>{h.reason}</small>
              </td>
              <td>
                {user.role === "ADMIN" && h.status === "Pending" && (
                  <button className="btn small" onClick={() => setSelected(h)}>
                    Xét duyệt
                  </button>
                )}
              </td>
            </tr>
          )}
        />
      </Card>
      {selected && (
        <ApplicationDecision
          record={selected}
          onClose={() => setSelected(null)}
          onDone={() => {
            setSelected(null);
            r.reload();
          }}
        />
      )}
    </>
  );
}
function ApplicationDecision({ record, onClose, onDone }) {
  const a = useAction(),
    [decision, setDecision] = useState("Approved"),
    [reason, setReason] = useState("");
  return (
    <Modal title={"Xét hồ sơ " + record.fullName} onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            await api("/technician-applications/" + record.id + "/decision", {
              method: "POST",
              body: {
                decision,
                expectedVersion: record.version,
                ...(reason ? { reason } : {}),
              },
            });
            onDone();
          });
        }}
      >
        <p>{record.experience}</p>
        {record.profileJson && (
          <div className="application-review">
            <ApplicationProfile json={record.profileJson} />
          </div>
        )}
        {(record.frontDocumentId || record.backDocumentId) && (
          <div className="image-grid">
            {record.frontDocumentId && (
              <ProtectedImage
                id={record.frontDocumentId}
                alt="CCCD mặt trước"
              />
            )}
            {record.backDocumentId && (
              <ProtectedImage id={record.backDocumentId} alt="CCCD mặt sau" />
            )}
          </div>
        )}
        <Field label="Kết quả">
          <select
            value={decision}
            onChange={(e) => setDecision(e.target.value)}
          >
            <option value="Approved">Duyệt thành kỹ thuật viên</option>
            <option value="Rejected">Từ chối</option>
          </select>
        </Field>
        <Field label="Lý do">
          <textarea
            required={decision === "Rejected"}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
        </Field>
        <small>
          Chỉ duyệt khi người nộp không còn đơn khách hàng đang mở. Người được
          duyệt cần đăng nhập lại và nạp ví trước khi nhận việc.
        </small>
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <Submit busy={a.busy}>Xác nhận kết quả</Submit>
        </div>
      </form>
    </Modal>
  );
}
export function Reports() {
  return <ReportWorkspace finance={<FinancialReport />} />;
}
function FinancialReport() {
  const { user } = useApp();
  const [range, setRange] = useState({ from: "", to: "" }),
    [query, setQuery] = useState(""),
    [rangeError, setRangeError] = useState(null);
  const cashflow = useReportData("/reports/cashflow" + query),
    settings = useReportData(user.role === "GD" ? "/reports/monitoring" : null);
  const summary = useReportData("/reports/summary" + query),
    finance = useReportData(
      ["GD", "KT", "ADMIN"].includes(user.role)
        ? "/reports/finance" + query
        : null,
    ),
    a = useAction();
  async function download() {
    await a.run(async () => {
      const blob = await api("/reports/finance.csv" + query, { blob: true });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "HomeFix_BaoCaoThu.csv";
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }, "Đã tải báo cáo CSV.");
  }
  const d = summary.data;
  return (
    <>
      <PageHead
        eyebrow="SỐ LIỆU HOẠT ĐỘNG"
        title="Dòng tiền và doanh thu"
        text="Giá trị đơn đã thu và hoa hồng đã đối soát là hai chỉ số riêng. Chưa bao gồm chi phí vận hành."
      >
        <button
          className="btn"
          disabled={cashflow.loading || !!cashflow.error}
          onClick={() =>
            csvDownload("HomeFix_DongTien.csv", [
              [
                "Từ thời điểm",
                new URLSearchParams(query).get("from") || "Toàn bộ",
              ],
              [
                "Đến trước thời điểm",
                new URLSearchParams(query).get("to") || "Hiện tại",
              ],
              ["Ngày", "Tiền vào", "Tiền ra", "Chênh lệch"],
              ...(cashflow.data || []).map((r) => [
                r.day,
                r.incoming,
                r.outgoing,
                Number(r.incoming) - Number(r.outgoing),
              ]),
            ])
          }
        >
          Xuất dòng tiền
        </button>
        <button
          className="btn"
          onClick={() =>
            document
              .getElementById("finance-details")
              ?.scrollIntoView({ behavior: "smooth" })
          }
        >
          Xem chi tiết
        </button>
        {user.role !== "DPV" && (
          <button
            className="btn primary"
            disabled={a.busy || finance.loading || !!finance.error}
            onClick={download}
          >
            <Download size={17} /> Xuất CSV
          </button>
        )}
      </PageHead>
      <form
        className="filter-bar"
        onSubmit={(e) => {
          e.preventDefault();
          if (range.from && range.to && range.from > range.to) {
            setRangeError(
              new Error("Ngày kết thúc phải bằng hoặc sau ngày bắt đầu."),
            );
            return;
          }
          setRangeError(null);
          const p = new URLSearchParams();
          if (range.from)
            p.set(
              "from",
              new Date(range.from + "T00:00:00+07:00").toISOString(),
            );
          if (range.to) {
            const end = new Date(
              new Date(range.to + "T00:00:00+07:00").getTime() + 86400000,
            );
            p.set("to", end.toISOString());
          }
          setQuery(p.size ? "?" + p : "");
        }}
      >
        <Field label="Từ ngày">
          <input
            type="date"
            value={range.from}
            onChange={(e) => setRange({ ...range, from: e.target.value })}
          />
        </Field>
        <Field label="Đến hết ngày">
          <input
            type="date"
            value={range.to}
            onChange={(e) => setRange({ ...range, to: e.target.value })}
          />
        </Field>
        <button className="btn" type="submit">
          Áp dụng
        </button>
        <button
          className="btn"
          type="button"
          onClick={() => {
            setRange({ from: "", to: "" });
            setQuery("");
            setRangeError(null);
          }}
        >
          Toàn bộ thời gian
        </button>
      </form>
      <ErrorBox
        error={
          rangeError ||
          summary.error ||
          finance.error ||
          cashflow.error ||
          settings.error ||
          a.error
        }
      />
      {d && (
        <>
          <div className="stat-grid">
            <Stat label="Đơn được tạo trong kỳ" value={d.totalOrders} />
            <Stat
              label="Giá trị đơn đã thu"
              value={money(d.gmv)}
              icon={Wallet}
            />
            <Stat
              label="Hoa hồng đã đối soát"
              value={money(d.commissionRevenue)}
              icon={ShieldCheck}
            />
            <Stat
              label="Đánh giá trung bình"
              value={
                d.averageRating
                  ? Number(d.averageRating).toFixed(1) + "/5"
                  : "Chưa có"
              }
              icon={Star}
            />
          </div>
          <div className="two-column report-columns">
            <div>
              <Card title="Dòng tiền vào / ra">
                <CashflowChart rows={cashflow.data} />
                <p className="report-note">
                  Tiền vào: thanh toán ngân hàng đã xác minh và nạp ví được
                  duyệt. Tiền ra: rút ví đã duyệt. Tiền mặt KTV thu và bút toán
                  đối soát nội bộ không tính vào biểu đồ này.
                </p>
              </Card>
              {settings.data?.showCashflow !== false && (
                <Card title="Chi tiết dòng tiền">
                  <Table
                    headers={["Ngày", "Tiền vào", "Tiền ra", "Chênh lệch"]}
                    rows={cashflow.data}
                    render={(r) => (
                      <tr key={r.day}>
                        <td>{r.day}</td>
                        <td className="text-green">{money(r.incoming)}</td>
                        <td className="text-red">{money(r.outgoing)}</td>
                        <td>
                          {money(Number(r.incoming) - Number(r.outgoing))}
                        </td>
                      </tr>
                    )}
                  />
                </Card>
              )}
            </div>
            <aside>
              <ReportOverview
                items={[
                  ["Giá trị đơn đã thu", money(d.gmv)],
                  ["Hoa hồng đã đối soát", money(d.commissionRevenue)],
                  [
                    "Dòng tiền thuần",
                    money(
                      (cashflow.data || []).reduce(
                        (n, r) => n + Number(r.incoming) - Number(r.outgoing),
                        0,
                      ),
                    ),
                  ],
                  ["Lợi nhuận ròng", "Chưa đủ dữ liệu"],
                ]}
              />
              {user.role === "GD" && (
                <MonitoringSettings
                  scope="finance"
                  settings={settings}
                  action={a}
                />
              )}
              <Card title="Phạm vi báo cáo">
                <p>
                  Chưa có sổ chi phí vận hành để tính chi phí tổng và lợi nhuận
                  ròng. Phần tiền thuộc KTV và vật tư được trình bày riêng bên
                  dưới.
                </p>
                {settings.data?.financeAlerts &&
                  (cashflow.data || []).reduce(
                    (n, r) => n + Number(r.incoming) - Number(r.outgoing),
                    0,
                  ) < 0 && (
                    <div className="notice warning">
                      Dòng tiền thuần trong kỳ đang âm.
                    </div>
                  )}
              </Card>
            </aside>
          </div>
          <FinancialBreakdown rows={finance.data} />
          <Card title="Giá trị thu theo ngày">
            {d.trend?.length ? (
              <div className="bar-chart">
                {d.trend.map((item) => (
                  <div className="bar-row" key={item.day}>
                    <span>{item.day}</span>
                    <div>
                      <i
                        style={{
                          width:
                            Math.max(
                              3,
                              (Number(item.amount) /
                                Math.max(
                                  ...d.trend.map((x) => Number(x.amount)),
                                  1,
                                )) *
                                100,
                            ) + "%",
                        }}
                      />
                    </div>
                    <b>{money(item.amount)}</b>
                  </div>
                ))}
              </div>
            ) : (
              <Empty title="Chưa có khoản thu trong kỳ" />
            )}
          </Card>
        </>
      )}

      {user.role !== "DPV" && (
        <div id="finance-details">
          <Card title="Các khoản thu trong kỳ">
            <Table
              headers={[
                "Đơn",
                "Thợ thực hiện",
                "Khoản đã thu",
                "Hoa hồng",
                "Đối soát",
              ]}
              rows={finance.data}
              render={(f) => (
                <tr key={f.id}>
                  <td>
                    {code(f.orderId)}
                    <small>{date(f.paidAt)}</small>
                  </td>
                  <td>{f.technicianName}</td>
                  <td>
                    {money(f.amount)}
                    <small>
                      {f.method === "BANK" ? "Chuyển khoản" : "Tiền mặt"}
                    </small>
                  </td>
                  <td>{money(f.commissionAmount)}</td>
                  <td>
                    <Badge value={f.settlementStatus} />
                  </td>
                </tr>
              )}
            />
          </Card>
        </div>
      )}
    </>
  );
}

function ApplicationProfile({ json }) {
  let profile;
  try {
    profile = JSON.parse(json);
  } catch {
    return null;
  }
  return (
    <dl>
      <dt>Kinh nghiệm</dt>
      <dd>{profile.years} năm</dd>
      <dt>Thiết bị</dt>
      <dd>{profile.equipment}</dd>
      <dt>Chứng chỉ</dt>
      <dd>{profile.certificates || "Không có"}</dd>
      <dt>Phương tiện</dt>
      <dd>{profile.vehicle}</dd>
    </dl>
  );
}

function FinancialBreakdown({ rows }) {
  if (!rows) return null;
  const sum = (key, predicate = () => true) =>
    rows
      .filter(predicate)
      .reduce((total, row) => total + Number(row[key] || 0), 0);
  const collected = sum("amount"),
    commission = sum("commissionAmount"),
    materials = sum("materialTotal");
  return (
    <div className="two-column">
      <Card title="Dòng tiền đã thu trong kỳ">
        <div className="money-lines">
          <div>
            <span>Khách thanh toán tiền mặt</span>
            <b>{money(sum("amount", (r) => r.method === "COD"))}</b>
          </div>
          <div>
            <span>Khách chuyển khoản về HomeFix</span>
            <b>{money(sum("amount", (r) => r.method === "BANK"))}</b>
          </div>
          <div className="total">
            <span>Tổng giá trị đơn đã thu</span>
            <strong>{money(collected)}</strong>
          </div>
        </div>
        <p>{rows.length} giao dịch thanh toán trong kỳ.</p>
      </Card>
      <Card title="Phân bổ doanh thu & chi phí dịch vụ">
        <div className="money-lines">
          <div>
            <span>Vật tư được khách duyệt</span>
            <b>{money(materials)}</b>
          </div>
          <div>
            <span>Phí kiểm tra & tiền công</span>
            <b>{money(sum("inspectionFee") + sum("laborFee"))}</b>
          </div>
          <div>
            <span>Hoa hồng của HomeFix</span>
            <b>{money(commission)}</b>
          </div>
          <div>
            <span>Trong đó đã đối soát</span>
            <b>
              {money(
                sum(
                  "commissionAmount",
                  (r) => r.settlementStatus === "Confirmed",
                ),
              )}
            </b>
          </div>
          <div className="total">
            <span>Phần thuộc KTV, gồm hoàn chi vật tư</span>
            <strong>{money(collected - commission)}</strong>
          </div>
        </div>
        <small>
          Chưa tính lợi nhuận ròng vì hệ thống chưa ghi nhận chi phí vận hành.
          Hoa hồng là khoản thu của HomeFix; không đồng nhất với toàn bộ tiền
          khách trả.
        </small>
      </Card>
    </div>
  );
}
