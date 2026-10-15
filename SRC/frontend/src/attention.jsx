import React, { createContext, useContext, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from './api';
const empty = {
  unread: 0,
  unreadNotifications: [],
  orderIds: [],
  orders: [],
  support: 0,
  applications: 0,
  policies: 0,
  error: null,
  finance: { settlements: 0, bank: 0, wallet: 0 },
};
const AttentionContext = createContext(empty);
export const useAttention = () => useContext(AttentionContext);
export function AttentionDot({ show = true, label = 'Có việc cần xử lý' }) {
  return show ? (
    <span className="attention-dot" role="img" aria-label={label} title={label} />
  ) : null;
}
export function AttentionProvider({ user, children }) {
  const [summary, setSummary] = useState(empty);
  useEffect(() => {
    let alive = true,
      running = false,
      again = false;
    const controller = new AbortController();
    async function refresh() {
      if (running) {
        again = true;
        return;
      }
      running = true;
      try {
        const r = await api('/attention-summary', { signal: controller.signal });
        if (alive) setSummary({ ...empty, ...r.data, error: null });
      } catch (error) {
        if (alive && error.name !== 'AbortError') setSummary((current) => ({ ...current, error }));
      } finally {
        running = false;
        if (again && alive) {
          again = false;
          refresh();
        }
      }
    }
    setSummary(empty);
    refresh();
    const timer = setInterval(refresh, 10000);
    window.addEventListener('homefix:changed', refresh);
    window.addEventListener('focus', refresh);
    const visible = () => {
      if (document.visibilityState === 'visible') refresh();
    };
    document.addEventListener('visibilitychange', visible);
    return () => {
      alive = false;
      controller.abort();
      clearInterval(timer);
      window.removeEventListener('homefix:changed', refresh);
      window.removeEventListener('focus', refresh);
      document.removeEventListener('visibilitychange', visible);
    };
  }, [user.id, user.role]);
  return <AttentionContext.Provider value={summary}>{children}</AttentionContext.Provider>;
}
export function needsAttention(summary, path) {
  const [pathname, query = ''] = path.split('?');
  const params = new URLSearchParams(query);
  const titles = (summary.unreadNotifications || []).map((item) => item.title.toLowerCase());
  const hasTitle = (...terms) => titles.some((title) => terms.some((term) => title.includes(term)));
  if (pathname === '/' && params.get('tab') === 'policies')
    return Number(summary.policies) > 0 || hasTitle('chính sách', 'đề xuất');
  if (pathname === '/orders' || pathname === '/admin/orders')
    return (
      summary.orderIds.length > 0 ||
      (summary.unreadNotifications || []).some((item) => item.orderId)
    );
  if (pathname === '/support')
    return Number(summary.support) > 0 || hasTitle('hỗ trợ', 'khiếu nại', 'bảo hành');
  if (pathname === '/applications')
    return Number(summary.applications) > 0 || hasTitle('hồ sơ kỹ thuật viên');
  if (pathname === '/wallet') return hasTitle('ví');
  if (pathname === '/finance') {
    const tab = params.get('tab');
    if (tab === 'bank') return Number(summary.finance.bank) > 0 || hasTitle('chuyển khoản');
    if (tab === 'wallet') return Number(summary.finance.wallet) > 0 || hasTitle('ví');
    if (tab === 'revenue' || tab === 'settlements')
      return Number(summary.finance.settlements) > 0 || hasTitle('đối soát', 'doanh thu');
    return (
      Object.values(summary.finance).some((n) => Number(n) > 0) ||
      hasTitle('ví', 'chuyển khoản', 'đối soát')
    );
  }
  if (pathname === '/reports') {
    const tab = params.get('tab');
    if (tab === 'quality') return hasTitle('chất lượng', 'khiếu nại');
    if (tab === 'technicians') return hasTitle('kỹ thuật viên', 'hiệu suất');
    return hasTitle('báo cáo', 'tài chính', 'doanh thu');
  }
  return false;
}
const taskName = (role, status) =>
  role === 'KH'
    ? {
        ChoDuyetSoBo: 'Xem và chấp nhận báo giá sơ bộ',
        DangXuLy: 'Duyệt vật tư phát sinh',
        ChoNghiemThu: 'Xác nhận nghiệm thu',
        HoanThanh: 'Thanh toán đơn dịch vụ',
      }[status] || 'Xem đơn cần xử lý'
    : role === 'DPV'
      ? status === 'ChoTiepNhan'
        ? 'Lập báo giá sơ bộ'
        : 'Phân công kỹ thuật viên'
      : status === 'ChoNhan'
        ? 'Phản hồi nhận đơn'
        : 'Cập nhật công việc';
export function AttentionPanel({ role }) {
  const summary = useAttention();
  const count =
    summary.orderIds.length +
    Object.values(summary.finance).reduce((n, v) => n + Number(v), 0) +
    Number(summary.support || 0) +
    Number(summary.applications || 0);
  if (summary.error)
    return (
      <div className="notice warning" role="status">
        Chưa tải được thông báo công việc. Hệ thống sẽ thử lại tự động; bạn vẫn có thể mở danh sách
        đơn để kiểm tra.
      </div>
    );
  if (!count) return null;
  return (
    <section className="attention-panel" aria-label="Công việc cần bạn xử lý">
      <div>
        <strong>
          <AttentionDot />
          Bạn có {count} việc cần xử lý
        </strong>
        <small>Cập nhật tự động; mở mục bên dưới để thực hiện.</small>
      </div>
      <div className="attention-links">
        {summary.orders.slice(0, 3).map((o) => (
          <Link key={o.id} to={'/orders/' + o.id}>
            HF-{String(o.id).padStart(6, '0')} · {taskName(role, o.status)}
          </Link>
        ))}
        {summary.orderIds.length > 3 && <Link to="/orders">Mở danh sách đơn</Link>}
        {Number(summary.finance.settlements) > 0 && (
          <Link to="/finance?tab=settlements">{summary.finance.settlements} đơn chờ đối soát</Link>
        )}
        {Number(summary.finance.wallet) > 0 && (
          <Link to="/finance?tab=wallet">{summary.finance.wallet} yêu cầu ví chờ duyệt</Link>
        )}
        {Number(summary.finance.bank) > 0 && (
          <Link to="/finance?tab=bank">{summary.finance.bank} chuyển khoản chờ xác minh</Link>
        )}
        {summary.support > 0 && <Link to="/support">{summary.support} yêu cầu hỗ trợ</Link>}
        {summary.applications > 0 && (
          <Link to="/applications">{summary.applications} hồ sơ KTV chờ duyệt</Link>
        )}
      </div>
    </section>
  );
}
