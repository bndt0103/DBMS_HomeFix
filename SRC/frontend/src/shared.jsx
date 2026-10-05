import { AttentionDot, useAttention } from './attention';
import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  AlertCircle,
  CheckCircle2,
  LoaderCircle,
  X,
  ChevronRight,
  Wrench,
  Clock,
  MapPin,
} from 'lucide-react';
import { api } from './api';
export const AppContext = createContext(null);
export const useApp = () => useContext(AppContext);
export const labels = {
  ChoTiepNhan: 'Chờ tiếp nhận',
  ChoDuyetSoBo: 'Chờ duyệt báo giá',
  ChoPhanCong: 'Chờ phân công',
  ChoNhan: 'Chờ thợ nhận',
  DaTiepNhan: 'Thợ đã nhận',
  DangDiChuyen: 'Đang di chuyển',
  DaDenNoi: 'Đã đến nơi',
  DangXuLy: 'Đang sửa chữa',
  ChoNghiemThu: 'Chờ nghiệm thu',
  HoanThanh: 'Hoàn thành',
  Huy: 'Đã hủy',
  AwaitingTransfer: 'Chờ chuyển khoản',
  PendingReview: 'Chờ xác minh tiền',
  Pending: 'Chờ xử lý',
  Approved: 'Đã duyệt',
  Rejected: 'Từ chối',
  Accepted: 'Đã nhận',
  Expired: 'Hết hạn',
  Confirmed: 'Đã đối soát',
  Open: 'Mới tiếp nhận',
  InProgress: 'Đang xử lý',
  Resolved: 'Đã giải quyết',
  Cancelled: 'Đã hủy',
  Paid: 'Đã thanh toán',
  Unpaid: 'Chưa thanh toán',
  SanSang: 'Sẵn sàng',
  TamBan: 'Tạm nghỉ',
  DangBan: 'Đang làm việc',
};
export const roleNames = {
  KH: 'Khách hàng',
  KTV: 'Kỹ thuật viên',
  DPV: 'Điều phối viên',
  CSKH: 'Chăm sóc khách hàng',
  KT: 'Kế toán',
  ADMIN: 'Quản trị viên',
  GD: 'Giám đốc',
};
export const groups = {
  DienLanh: 'Điện lạnh',
  DienGiaDung: 'Điện gia dụng',
  DienNuoc: 'Điện nước',
  VeSinh: 'Vệ sinh & bảo trì',
};
export const money = (v) =>
  Number(v ?? 0).toLocaleString('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  });
export const date = (v) =>
  v
    ? new Date(v).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' })
    : 'Ngay khi có thợ phù hợp';
export const code = (id) => 'HF-' + String(id).padStart(6, '0');
export function Badge({ value }) {
  return (
    <span
      className={
        'badge ' +
        (['HoanThanh', 'Approved', 'Accepted', 'Confirmed', 'Paid', 'Resolved', 'SanSang'].includes(
          value,
        )
          ? 'green'
          : ['Huy', 'Rejected', 'Expired', 'Cancelled'].includes(value)
            ? 'red'
            : 'amber')
      }
    >
      {labels[value] || value}
    </span>
  );
}
export function ErrorBox({ error }) {
  if (!error) return null;
  return (
    <div className="notice error" role="alert">
      <AlertCircle size={19} />
      <div>
        {error.message || error}
        {error.details?.fields && (
          <ul>
            {Object.entries(error.details.fields).map(([k, v]) => (
              <li key={k}>
                {k === '_form' ? '' : k + ': '}
                {v}
              </li>
            ))}
          </ul>
        )}
        {error.status === 409 && (
          <small>Tải lại dữ liệu rồi kiểm tra trước khi thao tác tiếp.</small>
        )}
      </div>
    </div>
  );
}
export function Loading() {
  return (
    <div className="loading">
      <LoaderCircle className="spin" size={24} /> Đang tải dữ liệu…
    </div>
  );
}
export function Empty({
  title = 'Chưa có dữ liệu',
  text = 'Các thông tin mới sẽ xuất hiện tại đây.',
  children,
}) {
  return (
    <div className="empty">
      <Wrench size={34} />
      <h3>{title}</h3>
      <p>{text}</p>
      {children}
    </div>
  );
}
export function PageHead({ eyebrow, title, text, children }) {
  return (
    <div className="page-head">
      <div>
        {eyebrow && <span className="eyebrow">{eyebrow}</span>}
        <h1>{title}</h1>
        {text && <p>{text}</p>}
      </div>
      <div className="actions">{children}</div>
    </div>
  );
}
export function Card({ title, children, className = '' }) {
  return (
    <section className={'card ' + className}>
      {title && <h2>{title}</h2>}
      {children}
    </section>
  );
}
export function Field({ label, children, hint }) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
      {hint && <small>{hint}</small>}
    </label>
  );
}
export function Modal({ title, children, onClose }) {
  const dialog = useRef(null),
    close = useRef(null),
    latestClose = useRef(onClose);
  latestClose.current = onClose;
  useEffect(() => {
    const previous = document.activeElement,
      old = document.body.style.overflow;
    const focusable = () =>
      [
        ...dialog.current.querySelectorAll(
          'button,input:not([type="hidden"]),select,textarea,a[href],[tabindex]',
        ),
      ].filter((el) => !el.disabled && el.tabIndex >= 0 && el.getClientRects().length);
    const first = dialog.current.querySelector(
      'input:not([type="hidden"]):not([disabled]),textarea:not([disabled]),select:not([disabled])',
    );
    (first || close.current)?.focus({ preventScroll: true });
    const key = (e) => {
      if (!dialog.current || e.isComposing || e.keyCode === 229) return;
      if (e.key === 'Escape') {
        e.preventDefault();
        latestClose.current?.();
      }
      if (e.key === 'Tab') {
        const elements = focusable(),
          first = elements[0],
          last = elements.at(-1);
        if (!first) {
          e.preventDefault();
          return;
        }
        if (!dialog.current.contains(document.activeElement)) {
          e.preventDefault();
          first.focus();
        } else if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };
    document.addEventListener('keydown', key);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', key);
      document.body.style.overflow = old;
      if (previous?.isConnected) previous.focus({ preventScroll: true });
    };
  }, []);
  return (
    <div className="modal-backdrop">
      <section ref={dialog} className="modal" role="dialog" aria-modal="true" aria-label={title}>
        <header>
          <h2>{title}</h2>
          <button
            ref={close}
            type="button"
            className="icon-btn"
            onClick={onClose}
            aria-label="Đóng"
          >
            <X />
          </button>
        </header>
        {children}
      </section>
    </div>
  );
}
export function useData(path, interval = 0) {
  const [data, setData] = useState(null),
    [meta, setMeta] = useState(null),
    [error, setError] = useState(null),
    [loading, setLoading] = useState(true),
    [tick, setTick] = useState(0);
  const reload = () => setTick((t) => t + 1);
  useEffect(() => {
    if (!path) {
      setLoading(false);
      return;
    }
    const c = new AbortController();
    let alive = true,
      running = false,
      again = false;
    const load = async () => {
      if (running) {
        again = true;
        return;
      }
      running = true;
      try {
        const r = await api(path, { signal: c.signal });
        if (alive) {
          setData(r.data);
          setMeta(r.meta);
          setError(null);
        }
      } catch (e) {
        if (alive && e.name !== 'AbortError') setError(e);
      } finally {
        running = false;
        if (alive) {
          setLoading(false);
          if (again) {
            again = false;
            load();
          }
        }
      }
    };
    load();
    const timer = interval ? setInterval(load, interval) : null;
    const visible = () => {
      if (document.visibilityState === 'visible') load();
    };
    window.addEventListener('focus', load);
    window.addEventListener('homefix:changed', load);
    document.addEventListener('visibilitychange', visible);
    return () => {
      alive = false;
      c.abort();
      if (timer) clearInterval(timer);
      window.removeEventListener('focus', load);
      window.removeEventListener('homefix:changed', load);
      document.removeEventListener('visibilitychange', visible);
    };
  }, [path, tick, interval]);
  return { data, meta, error, loading, reload, setData };
}
export function useAction() {
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null);
  const { toast } = useApp();
  const busyRef = useRef(false);
  const run = async (fn, message = 'Đã cập nhật thành công.') => {
    if (busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    setError(null);
    try {
      const result = await fn();
      if (message) toast(message);
      return result;
    } catch (e) {
      setError(e);
      return undefined;
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  };
  return { busy, error, run, setError };
}
export function Submit({ busy, children = 'Lưu thay đổi', ...rest }) {
  return (
    <button className="btn primary" type="submit" disabled={busy} {...rest}>
      {busy ? <LoaderCircle size={17} className="spin" /> : <CheckCircle2 size={17} />}{' '}
      {busy ? 'Đang xử lý…' : children}
    </button>
  );
}
export function OrderCard({ order }) {
  const { user } = useApp();
  const attention = useAttention();
  return (
    <Link className="order-card" to={'/orders/' + order.id}>
      <div className="order-symbol">
        <Wrench size={23} />
      </div>
      <div className="order-main">
        <div className="row wrap">
          <small>{code(order.id)}</small>
          <AttentionDot show={attention.orderIds.includes(order.id)} label="Đơn cần bạn xử lý" />
          <Badge value={order.status} />
        </div>
        <h3>{order.serviceName}</h3>
        <p>
          <MapPin size={14} />
          {order.address}
        </p>
        <small>
          <Clock size={13} /> {date(order.scheduledAt || order.createdAt)}
        </small>
      </div>
      {user.role === 'KH' && order.status === 'ChoDuyetSoBo' && (
        <span className="order-card-cta pending">Xem và chấp nhận báo giá sơ bộ</span>
      )}
      {user.role === 'KTV' && !['HoanThanh', 'Huy'].includes(order.status) && (
        <span className={'order-card-cta ' + (order.status === 'ChoNhan' ? 'pending' : '')}>
          {order.status === 'ChoNhan' ? 'Xem và phản hồi đơn' : 'Tiếp tục cập nhật tiến độ'}
        </span>
      )}
      <ChevronRight className="order-arrow" />
    </Link>
  );
}
export function ProtectedImage({ id, alt = 'Ảnh đính kèm' }) {
  const [url, setUrl] = useState('');
  useEffect(() => {
    let alive = true,
      objectUrl;
    api('/uploads/' + id, { blob: true })
      .then((blob) => {
        objectUrl = URL.createObjectURL(blob);
        if (alive) setUrl(objectUrl);
        else URL.revokeObjectURL(objectUrl);
      })
      .catch(() => {});
    return () => {
      alive = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [id]);
  return url ? (
    <a href={url} target="_blank" rel="noreferrer">
      <img src={url} alt={alt} />
    </a>
  ) : (
    <span className="image-placeholder">Đang tải ảnh…</span>
  );
}
export function MoneyBreakdown({ value }) {
  return (
    <div className="money-lines">
      <div>
        <span>Phí kiểm tra</span>
        <b>{money(value.inspectionFee)}</b>
      </div>
      <div>
        <span>Tiền công</span>
        <b>{money(value.laborFee)}</b>
      </div>
      {value.materialTotal !== undefined && (
        <div>
          <span>Vật tư được duyệt</span>
          <b>{money(value.materialTotal)}</b>
        </div>
      )}
      <div className="total">
        <span>Tổng cộng</span>
        <strong>{money(value.total)}</strong>
      </div>
    </div>
  );
}
