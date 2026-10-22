import { createContext, useContext, useEffect, useState } from "react";

export const Session = createContext(null);
export const useSession = () => useContext(Session);

export const roles = [
  ["KH", "Khách hàng"],
  ["KTV", "Kỹ thuật viên"],
  ["DPV", "Điều phối viên"],
  ["CSKH", "Chăm sóc khách hàng"],
  ["KT", "Kế toán"],
  ["GD", "Giám đốc"],
  ["ADMIN", "Quản trị viên"],
];

const labels = {
  ChoTiepNhan: "Chờ tiếp nhận",
  ChoDuyetSoBo: "Chờ duyệt báo giá",
  ChoPhanCong: "Chờ phân công",
  ChoNhan: "Chờ thợ nhận",
  DaTiepNhan: "Đã tiếp nhận",
  DangDiChuyen: "Đang di chuyển",
  DaDenNoi: "Đã đến nơi",
  DangXuLy: "Đang xử lý",
  ChoNghiemThu: "Chờ nghiệm thu",
  HoanThanh: "Hoàn thành",
  Huy: "Đã hủy",
  Pending: "Chờ xử lý",
  Approved: "Đã duyệt",
  Rejected: "Từ chối",
  Accepted: "Đã nhận",
  Confirmed: "Đã xác nhận",
  Open: "Mới mở",
  InProgress: "Đang xử lý",
  Resolved: "Đã giải quyết",
  SanSang: "Sẵn sàng",
  TamBan: "Tạm bận",
  DangBan: "Đang làm đơn",
  Deposit: "Nạp tiền",
  Withdrawal: "Rút tiền",
  Commission: "Hoa hồng",
  SettlementCredit: "Ghi có đối soát",
  Reversal: "Hoàn tiền",
  Complaint: "Khiếu nại",
  Warranty: "Bảo hành",
  COD: "Tiền mặt",
  BANK: "Chuyển khoản",
  OrderFault: "Ảnh tình trạng",
  AcceptancePhoto: "Ảnh nghiệm thu",
  CustomerSignature: "Chữ ký khách",
  TechnicianSignature: "Chữ ký thợ",
  WalletProof: "Chứng từ ví",
  PaymentProof: "Chứng từ thanh toán",
  TechnicianDocument: "Hồ sơ thợ",
  Avatar: "Ảnh đại diện",
  ...Object.fromEntries(roles),
};

export function text(value) {
  if (value == null || value === "") return "—";
  if (typeof value === "boolean") return value ? "Có" : "Không";
  if (typeof value === "object") return JSON.stringify(value);
  return labels[value] || String(value);
}

export function money(value) {
  return Number(value || 0).toLocaleString("vi-VN", {
    style: "currency",
    currency: "VND",
  });
}

export function date(value) {
  return value ? new Date(value).toLocaleString("vi-VN") : "—";
}

export function rows(value) {
  return Array.isArray(value) ? value : value ? [value] : [];
}

export function useResource(path) {
  const { api, revision } = useSession();
  const [state, setState] = useState({
    data: null,
    loading: !!path,
    error: "",
  });
  useEffect(() => {
    let active = true;
    if (!path) {
      setState({ data: null, loading: false, error: "" });
      return undefined;
    }
    setState((old) => ({ ...old, loading: true, error: "" }));
    api(path).then(
      (data) => active && setState({ data, loading: false, error: "" }),
      (error) =>
        active &&
        setState({ data: null, loading: false, error: error.message }),
    );
    return () => {
      active = false;
    };
  }, [api, path, revision]);
  return state;
}

export function Resource({ state, children }) {
  if (state.loading)
    return (
      <p className="muted" role="status">
        Đang tải…
      </p>
    );
  if (state.error)
    return (
      <p className="error" role="alert">
        {state.error}
      </p>
    );
  return children(state.data);
}

export function Panel({ title, children, hint }) {
  return (
    <section className="panel">
      <h2>{title}</h2>
      {hint && <p className="muted">{hint}</p>}
      {children}
    </section>
  );
}

export function Table({ data, columns, actions }) {
  const list = rows(data);
  if (!list.length) return <p className="empty">Chưa có dữ liệu.</p>;
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map(([key, title]) => (
              <th key={key}>{title}</th>
            ))}
            {actions && <th>Thao tác</th>}
          </tr>
        </thead>
        <tbody>
          {list.map((row, index) => (
            <tr key={row.Id ?? row.Khoa ?? row.DonHangId ?? index}>
              {columns.map(([key, , render]) => (
                <td key={key}>
                  {render ? render(row[key], row) : text(row[key])}
                </td>
              ))}
              {actions && (
                <td>
                  <div className="actions">{actions(row)}</div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function Details({ row, fields }) {
  if (!row) return <p className="empty">Chưa có dữ liệu.</p>;
  return (
    <dl className="info">
      {fields.map(([key, title, render]) => (
        <div key={key}>
          <dt>{title}</dt>
          <dd>{render ? render(row[key], row) : text(row[key])}</dd>
        </div>
      ))}
    </dl>
  );
}

export function Form({
  title,
  fields = [],
  onSubmit,
  submit = "Lưu",
  children,
  initial = {},
  id,
}) {
  const { busy } = useSession() || {};
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    const form = event.currentTarget;
    const formData = new FormData(form);
    const values = {};
    for (const field of fields) {
      const value = formData.get(field.name);
      if (field.type === "checkbox")
        values[field.name] = formData.has(field.name);
      else if (field.type === "file") values[field.name] = value;
      else if (value !== null && value !== "") {
        values[field.name] = field.type === "number" ? Number(value) : value;
      } else if (field.allowEmpty) values[field.name] = null;
    }
    try {
      setSending(true);
      await onSubmit(values, formData, form);
    } catch (failure) {
      setError(failure.message);
    } finally {
      setSending(false);
    }
  }
  return (
    <form onSubmit={handleSubmit} className="form" id={id}>
      {title && <h3>{title}</h3>}
      <fieldset disabled={busy || sending}>
        <div className="fields">
          {fields.map((field) => (
            <label
              key={field.name}
              className={field.type === "textarea" ? "wide" : ""}
            >
              <span>
                {field.label}
                {field.required ? " *" : ""}
              </span>
              {field.options ? (
                <select
                  name={field.name}
                  required={field.required}
                  defaultValue={initial[field.name] ?? field.defaultValue ?? ""}
                >
                  {!field.required && <option value="">— Chọn —</option>}
                  {field.options.map((option) => {
                    const [value, title] = Array.isArray(option)
                      ? option
                      : [option, text(option)];
                    return (
                      <option value={value} key={value}>
                        {title}
                      </option>
                    );
                  })}
                </select>
              ) : field.type === "textarea" ? (
                <textarea
                  name={field.name}
                  required={field.required}
                  maxLength={field.maxLength || 2000}
                  defaultValue={initial[field.name] ?? field.defaultValue ?? ""}
                />
              ) : (
                <input
                  name={field.name}
                  type={field.type || "text"}
                  required={field.required}
                  min={field.min}
                  max={field.max}
                  step={field.step}
                  accept={field.accept}
                  minLength={field.minLength}
                  maxLength={field.maxLength}
                  defaultChecked={
                    field.type === "checkbox"
                      ? Boolean(initial[field.name] ?? field.defaultValue)
                      : undefined
                  }
                  defaultValue={
                    ["checkbox", "file"].includes(field.type)
                      ? undefined
                      : (initial[field.name] ?? field.defaultValue ?? "")
                  }
                  placeholder={field.placeholder}
                />
              )}
              {field.hint && <small>{field.hint}</small>}
            </label>
          ))}
        </div>
        {children}
        <button type="submit">{sending ? "Đang gửi…" : submit}</button>
      </fieldset>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
    </form>
  );
}

export function ActionForm({
  title,
  path,
  method = "POST",
  fields,
  extra = {},
  initial,
  submit,
  children,
  onDone,
}) {
  const { api, changed } = useSession();
  return (
    <details className="operation">
      <summary>{title}</summary>
      <Form
        fields={fields}
        initial={initial}
        submit={submit}
        onSubmit={async (values) => {
          const result = await api(path, {
            method,
            body: { ...values, ...extra },
          });
          changed("Thao tác thành công.");
          onDone?.(result);
        }}
      >
        {children}
      </Form>
    </details>
  );
}

export function FileButton({ file }) {
  const { api } = useSession();
  const [error, setError] = useState("");
  async function open() {
    try {
      setError("");
      const blob = await api(`/uploads/${file.Id}`, { raw: true });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = file.TenTepGoc || `tep-${file.Id}`;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (failure) {
      setError(failure.message);
    }
  }
  return (
    <>
      <button type="button" className="secondary" onClick={open}>
        Tải tệp #{file.Id}
      </button>
      {error && <small className="error">{error}</small>}
    </>
  );
}

export function UploadForm({ orderId, purposes }) {
  const { api, changed } = useSession();
  return (
    <details className="operation">
      <summary>Đính kèm ảnh / chữ ký / chứng từ</summary>
      <Form
        fields={[
          {
            name: "MucDich",
            label: "Loại tệp",
            required: true,
            options: purposes,
          },
          {
            name: "file",
            label: "Tệp ảnh",
            type: "file",
            accept: "image/png,image/jpeg,image/webp",
            required: true,
          },
        ]}
        submit="Tải lên"
        onSubmit={async (values) => {
          const payload = new FormData();
          payload.set("file", values.file);
          payload.set("MucDich", values.MucDich);
          if (orderId) payload.set("DonHangId", String(orderId));
          const result = await api("/uploads", {
            method: "POST",
            body: payload,
          });
          changed(`Đã tải tệp #${rows(result)[0]?.Id ?? ""}.`);
        }}
      >
        <p className="muted">
          Với chữ ký, chọn ảnh PNG/JPEG chữ ký của chính bạn, sau đó chọn tệp ở
          bước ký nghiệm thu.
        </p>
      </Form>
    </details>
  );
}
