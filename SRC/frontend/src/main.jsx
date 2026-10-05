import {
  AttentionProvider,
  AttentionDot,
  AttentionPanel,
  useAttention,
  needsAttention,
} from './attention';
import { AuthForm } from './auth-forms';
import React, { useCallback, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import {
  BrowserRouter,
  Routes,
  Route,
  NavLink,
  Link,
  useNavigate,
  useLocation,
  Navigate,
} from 'react-router-dom';
import {
  Wrench,
  House,
  ClipboardList,
  Wallet,
  Users,
  Settings,
  ChartNoAxesCombined,
  Headphones,
  Bell,
  LogOut,
  Menu,
  X,
  UserRound,
  ShieldCheck,
  ArrowRight,
  ArrowDownUp,
  Server,
  CheckCircle2,
  Snowflake,
  FileCheck2,
} from 'lucide-react';
import { api, setSession, baseUrl, saveBaseUrl } from './api';
import { AppContext, useApp, roleNames, ErrorBox, Field, Submit, Modal, useAction } from './shared';
import {
  Dashboard,
  Services,
  Booking,
  Orders,
  Profile,
  Notifications,
  PolicyApproval,
} from './pages';
import { OrderDetail } from './order-detail';
import { Management, Finance, WalletPage, Support, Reports, Applications } from './management';
import './style.css';
import './technician.css';
function Connection({ onClose }) {
  const [url, setUrl] = useState(
    baseUrl().startsWith('http') ? baseUrl() : window.location.origin + '/api',
  );
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null),
    [done, setDone] = useState(false);
  return (
    <Modal title="Kết nối máy chủ" onClose={onClose}>
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          setError(null);
          setDone(false);
          try {
            saveBaseUrl(url);
            await api('/health');
            setDone(true);
          } catch (e) {
            setError(e);
          } finally {
            setBusy(false);
          }
        }}
      >
        <p>
          Nhập địa chỉ HTTPS của máy chủ HomeFix để sử dụng qua Wi-Fi hoặc dữ liệu di động. Địa chỉ
          máy tính nội bộ chỉ hoạt động khi cùng mạng và máy chủ đang bật.
        </p>
        <Field label="Địa chỉ máy chủ">
          <input
            type="url"
            required
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://may-chu-cua-nhom.vn/api"
          />
        </Field>
        <ErrorBox error={error} />
        {done && (
          <div className="notice success">
            <CheckCircle2 size={18} /> Kết nối thành công. Bạn có thể đăng nhập.
          </div>
        )}
        <div className="actions">
          <Submit busy={busy}>Lưu và kiểm tra kết nối</Submit>
          <button type="button" className="btn" onClick={onClose}>
            Đóng
          </button>
        </div>
      </form>
    </Modal>
  );
}
function AuthPage() {
  const [connection, setConnection] = useState(false);
  return (
    <div className="auth-page">
      <section className="auth-story">
        <Link className="brand" to="/">
          <span className="brand-mark">
            <House />
          </span>
          HomeFix<span className="brand-dot">.</span>
        </Link>
        <div className="story-copy">
          <span className="eyebrow light">DỊCH VỤ CHĂM SÓC NHÀ CỬA</span>
          <h1>
            Nhà an tâm.
            <br />
            Cuộc sống nhẹ nhàng.
          </h1>
          <p>
            Từ một thiết bị cần sửa đến những lần bảo trì định kỳ — HomeFix luôn đồng hành cùng bạn.
          </p>
          <div className="house-illustration" aria-hidden="true">
            <div className="roof" />
            <div className="house-body">
              <Snowflake size={62} />
              <div className="window" />
              <div className="door" />
            </div>
            <span className="illustration-badge">
              <ShieldCheck size={20} /> Báo giá minh bạch
            </span>
          </div>
          <div className="trust-row">
            <span>
              <CheckCircle2 /> Đúng chuyên môn
            </span>
            <span>
              <CheckCircle2 /> Rõ chi phí
            </span>
            <span>
              <CheckCircle2 /> Có nghiệm thu
            </span>
          </div>
        </div>
        <small>HomeFix · Nhóm 08 · Đồ án Hệ quản trị cơ sở dữ liệu</small>
      </section>
      <section className="auth-form-panel">
        <div className="mobile-brand brand">
          <span className="brand-mark">
            <House />
          </span>
          HomeFix.
        </div>
        <div className="auth-form">
          <AuthForm />
          <button className="connection-link" onClick={() => setConnection(true)}>
            <Server size={15} /> Cài đặt kết nối
          </button>
        </div>
        <small className="auth-foot">Dịch vụ minh bạch từ đặt lịch đến nghiệm thu.</small>
      </section>
      {connection && <Connection onClose={() => setConnection(false)} />}
    </div>
  );
}
const menuByRole = {
  KH: [
    ['/', 'Trang chủ', House],
    ['/services', 'Dịch vụ', Wrench],
    ['/orders', 'Đơn của tôi', ClipboardList],
    ['/support', 'Hỗ trợ', Headphones],
  ],
  KTV: [
    ['/', 'Tổng quan', House],
    ['/orders', 'Công việc', ClipboardList],
    ['/wallet', 'Ví & thu nhập', Wallet],
    ['/profile', 'Cá nhân', UserRound],
  ],
  DPV: [
    ['/', 'Tổng quan', House],
    ['/orders', 'Điều phối đơn', ClipboardList],
    ['/reports', 'Báo cáo', ChartNoAxesCombined],
  ],
  CSKH: [
    ['/', 'Tổng quan', House],
    ['/support', 'Yêu cầu hỗ trợ', Headphones],
    ['/orders', 'Tra cứu đơn', ClipboardList],
  ],
  KT: [
    ['/', 'Tổng quan tài chính', ChartNoAxesCombined],
    ['/finance?tab=settlements', 'Đối soát doanh thu', ClipboardList],
    ['/finance?tab=wallet', 'Duyệt Ví KTV', Wallet],
    ['/finance?tab=bank', 'Giao dịch', ArrowDownUp],
    ['/reports', 'Báo cáo dòng tiền', ChartNoAxesCombined],
  ],
  ADMIN: [
    ['/', 'Tổng quan hệ thống', House],
    ['/admin/users', 'Quản lý tài khoản', Users],
    ['/admin/orders', 'Đơn sửa chữa & Bảo trì', ClipboardList],
    ['/applications', 'Duyệt hồ sơ KTV', FileCheck2],
    ['/admin/services', 'Danh mục dịch vụ', Wrench],
    ['/admin/audit', 'Nhật ký hệ thống', ShieldCheck],
    ['/admin/settings', 'Cấu hình hệ thống', Settings],
  ],
  GD: [
    ['/', 'Tổng quan điều hành', ChartNoAxesCombined],
    ['/?tab=policies', 'Phê duyệt chính sách', ClipboardList],
    ['/reports?tab=quality', 'Khách hàng & chất lượng', ShieldCheck],
    ['/reports', 'Báo cáo tài chính', Wallet],
    ['/reports?tab=technicians', 'Hiệu suất KTV', Users],
  ],
};
function Layout() {
  const { user } = useApp();
  return (
    <AttentionProvider key={user.id} user={user}>
      <LayoutContent />
    </AttentionProvider>
  );
}
function LayoutContent() {
  const attention = useAttention();
  const { user, logout } = useApp(),
    location = useLocation();
  const [opened, setOpened] = useState(false);
  useEffect(() => setOpened(false), [location.pathname, location.search]);
  const customer = user.role === 'KH',
    technician = user.role === 'KTV',
    accountant = user.role === 'KT',
    menus = menuByRole[user.role];
  const isMenuActive = (url) => {
    if (user.role === 'GD' && location.pathname === '/reports' && url.startsWith('/reports')) {
      const params = new URLSearchParams(location.search),
        view = params.get('view') || params.get('tab') || 'finance';
      const target =
        view === 'quality'
          ? '/reports?tab=quality'
          : ['technicians', 'performance'].includes(view)
            ? '/reports?tab=technicians'
            : '/reports';
      return url === target;
    }
    return url.includes('?')
      ? location.pathname === url.split('?')[0] && location.search === url.slice(url.indexOf('?'))
      : location.pathname === url && !location.search;
  };
  return (
    <div
      className={
        'app-shell ' +
        (customer ? 'customer-shell' : 'staff-shell') +
        (technician ? ' technician-shell' : '')
      }
    >
      <aside
        className={
          (opened ? 'sidebar opened' : 'sidebar') + (accountant ? ' accountant-sidebar' : '')
        }
      >
        <Link to="/" className="brand">
          <span className="brand-mark">
            <House />
          </span>
          HomeFix<span className="brand-dot">.</span>
        </Link>
        <div className="sidebar-label">{roleNames[user.role]}</div>
        <nav>
          {menus.map(([url, name, Icon]) => (
            <NavLink
              end={url === '/'}
              to={url}
              key={url}
              aria-label={name}
              className={() => (isMenuActive(url) ? 'active' : '')}
            >
              <Icon size={20} />
              {name}
              <AttentionDot show={needsAttention(attention, url)} />
            </NavLink>
          ))}
        </nav>
        {accountant ? (
          <div className="sidebar-bottom accountant-sidebar-bottom">
            <Link to="/profile" className="accountant-profile">
              <span className="avatar">{user.fullName.split(' ').at(-1).slice(0, 1)}</span>
              <span>
                <b>{user.fullName}</b>
                <small>Trưởng Bộ Phận Kế Toán</small>
              </span>
            </Link>
            <button onClick={logout}>
              <LogOut size={18} /> Đăng xuất khỏi hệ thống
            </button>
          </div>
        ) : (
          <div className="sidebar-bottom">
            <NavLink to="/profile">
              <UserRound size={18} /> Hồ sơ cá nhân
            </NavLink>
            <button onClick={logout}>
              <LogOut size={18} /> Đăng xuất
            </button>
            <small>HomeFix · Nhóm 08</small>
          </div>
        )}
      </aside>
      {opened && (
        <button aria-label="Đóng menu" className="sidebar-shade" onClick={() => setOpened(false)} />
      )}
      <div className="app-body">
        <header className="topbar">
          {customer ? (
            <Link to="/" className="brand">
              <span className="brand-mark">
                <House />
              </span>
              HomeFix.
            </Link>
          ) : (
            <button
              className="icon-btn menu-toggle"
              onClick={() => setOpened(true)}
              aria-label="Mở menu"
            >
              <Menu />
            </button>
          )}
          {customer ? (
            <nav className="customer-nav">
              {menus.map(([url, name]) => (
                <NavLink end={url === '/'} to={url} key={url} aria-label={name}>
                  {name}
                  <AttentionDot show={needsAttention(attention, url)} />
                </NavLink>
              ))}
            </nav>
          ) : (
            <div className="topbar-title">
              {roleNames[user.role]}
              <span>Không gian làm việc HomeFix</span>
            </div>
          )}
          <div className="topbar-actions">
            <Link
              className="icon-btn notification-bell"
              to="/notifications"
              aria-label="Thông báo"
              title={`${attention.unread} thông báo chưa đọc`}
            >
              <Bell size={20} />
              <AttentionDot
                show={
                  attention.unread > 0 ||
                  attention.orderIds.length > 0 ||
                  needsAttention(attention, '/finance') ||
                  attention.support > 0 ||
                  attention.applications > 0
                }
                label="Có thông báo hoặc việc cần xử lý"
              />
            </Link>
            <Link className="profile-chip" to="/profile">
              <span className="avatar">{user.fullName.split(' ').at(-1).slice(0, 1)}</span>
              <div>
                <b>{user.fullName}</b>
                <small>{roleNames[user.role]}</small>
              </div>
            </Link>
            {customer && (
              <button className="icon-btn" onClick={logout} aria-label="Đăng xuất">
                <LogOut size={18} />
              </button>
            )}
          </div>
        </header>
        <main className="main-content">
          <AttentionPanel role={user.role} />
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route
              path="/services"
              element={
                <Guard roles={['KH']}>
                  <Services />
                </Guard>
              }
            />
            <Route
              path="/book/:serviceId"
              element={
                <Guard roles={['KH']}>
                  <Booking />
                </Guard>
              }
            />
            <Route
              path="/orders"
              element={
                <Guard roles={['KH', 'KTV', 'DPV', 'KT', 'CSKH', 'ADMIN']}>
                  <Orders />
                </Guard>
              }
            />
            <Route
              path="/orders/:id"
              element={
                <Guard roles={['KH', 'KTV', 'DPV', 'KT', 'CSKH', 'ADMIN']}>
                  <OrderDetail />
                </Guard>
              }
            />
            <Route path="/profile" element={<Profile />} />
            <Route path="/notifications" element={<Notifications />} />
            <Route
              path="/admin/:section"
              element={
                <Guard roles={['ADMIN']}>
                  <Management />
                </Guard>
              }
            />
            <Route
              path="/applications"
              element={
                <Guard roles={['ADMIN', 'KH']}>
                  <Applications />
                </Guard>
              }
            />
            <Route
              path="/finance"
              element={
                <Guard roles={['KT']}>
                  <Finance />
                </Guard>
              }
            />
            <Route
              path="/wallet"
              element={
                <Guard roles={['KTV']}>
                  <WalletPage />
                </Guard>
              }
            />
            <Route
              path="/support"
              element={
                <Guard roles={['KH', 'CSKH']}>
                  <Support />
                </Guard>
              }
            />
            <Route
              path="/reports"
              element={
                <Guard roles={['GD', 'KT', 'DPV', 'CSKH']}>
                  <Reports />
                </Guard>
              }
            />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
        <footer className="site-footer">
          HomeFix · Chăm sóc ngôi nhà của bạn <span>Nhóm 08 · Hệ quản trị cơ sở dữ liệu</span>
        </footer>
      </div>
      {(customer || technician) && (
        <nav className="bottom-nav">
          {menus.map(([url, name, Icon]) => (
            <NavLink end={url === '/'} to={url} key={url} aria-label={name}>
              <Icon size={21} />
              <span>
                {name}
                <AttentionDot show={needsAttention(attention, url)} />
              </span>
            </NavLink>
          ))}
        </nav>
      )}
    </div>
  );
}
function Guard({ roles, children }) {
  const { user } = useApp();
  return roles.includes(user.role) ? (
    children
  ) : (
    <div className="empty">
      <ShieldCheck />
      <h1>Không có quyền truy cập</h1>
      <Link to="/" className="btn primary">
        Về trang chủ
      </Link>
    </div>
  );
}
function App() {
  const [user, setUser] = useState(null),
    [message, setMessage] = useState('');
  const toast = useCallback((m) => setMessage(m), []);
  useEffect(() => {
    if (!message) return;
    const t = setTimeout(() => setMessage(''), 4500);
    return () => clearTimeout(t);
  }, [message]);
  const logout = async (notice) => {
    try {
      await api('/auth/logout', { method: 'POST', body: {} });
    } catch {}
    setSession('');
    setUser(null);
    if (typeof notice === 'string') setMessage(notice);
  };
  const login = (data) => {
    setSession(data.accessToken, () => {
      setUser(null);
      setMessage('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    });
    setUser(data.user);
  };
  return (
    <AppContext.Provider value={{ user, setUser, login, logout, toast }}>
      <BrowserRouter>{user ? <Layout /> : <AuthPage />}</BrowserRouter>
      {message && (
        <div className="toast" role="status">
          <CheckCircle2 size={20} />
          {message}
          <button aria-label="Đóng thông báo" onClick={() => setMessage('')}>
            <X size={17} />
          </button>
        </div>
      )}
    </AppContext.Provider>
  );
}
menuByRole.CSKH.push(['/reports', 'Chất lượng dịch vụ', ChartNoAxesCombined]);
menuByRole.KT = [
  ['/', 'Tổng quan tài chính', ChartNoAxesCombined],
  ['/finance?tab=revenue', 'Đối soát doanh thu', ClipboardList],
  ['/finance?tab=wallet', 'Duyệt Ví KTV', Wallet],
  ['/finance?tab=bank', 'Giao dịch', ArrowDownUp],
  ['/reports', 'Báo cáo dòng tiền', ChartNoAxesCombined],
];
createRoot(document.getElementById('root')).render(<App />);
