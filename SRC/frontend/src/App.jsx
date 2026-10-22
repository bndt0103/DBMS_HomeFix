import { useCallback, useEffect, useMemo, useState } from "react";
import { createApi } from "./api.js";
import { Form, roles, Session, text } from "./components.jsx";
import { Icon } from "./icons.jsx";
import {
  CustomerDashboard,
  DispatcherHub,
  OrdersPage,
  ServicesPage,
  TechnicianOverview,
} from "./Orders.jsx";
import {
  AdminOverview,
  AdminPage,
  ApplicationsPage,
  AuditPage,
  CatalogPage,
  DirectorOverview,
  PolicyApprovalPage,
  ProfilePage,
  ReportsPage,
  SettingsPage,
} from "./Management.jsx";
import {
  BankRequestsPage,
  FinanceOverview,
  SettlementsPage,
  SupportPage,
  WalletApprovalPage,
  WalletPage,
} from "./SupportFinance.jsx";

const menuByRole = {
  KH: [
    { id: "dashboard", label: "Trang chủ", icon: "house" },
    { id: "services", label: "Dịch vụ", icon: "wrench" },
    { id: "orders", label: "Đơn của tôi", icon: "clipboard" },
    { id: "support", label: "Hỗ trợ", icon: "headphones" },
  ],
  KTV: [
    { id: "overview", label: "Tổng quan", icon: "house" },
    { id: "orders", label: "Công việc", icon: "clipboard" },
    { id: "wallet", label: "Ví & thu nhập", icon: "wallet" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
  DPV: [
    { id: "dispatch", label: "Công việc điều phối", icon: "users" },
    { id: "orders", label: "Tất cả đơn", icon: "clipboard" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
  CSKH: [
    { id: "support", label: "Công việc hỗ trợ", icon: "headphones" },
    { id: "orders", label: "Tra cứu đơn", icon: "clipboard" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
  KT: [
    { id: "overview", label: "Tổng quan tài chính", icon: "chart" },
    { id: "settlements", label: "Đối soát doanh thu", icon: "clipboard" },
    { id: "wallet_admin", label: "Duyệt ví KTV", icon: "wallet" },
    { id: "bank_requests", label: "Giao dịch", icon: "shield" },
    { id: "reports", label: "Báo cáo dòng tiền", icon: "chart" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
  ADMIN: [
    { id: "overview", label: "Tổng quan hệ thống", icon: "house" },
    { id: "users", label: "Quản lý tài khoản", icon: "users" },
    { id: "orders", label: "Đơn sửa chữa & Bảo trì", icon: "clipboard" },
    { id: "applications", label: "Duyệt hồ sơ KTV", icon: "file" },
    { id: "catalog", label: "Danh mục dịch vụ", icon: "wrench" },
    { id: "audit", label: "Nhật ký hệ thống", icon: "shield" },
    { id: "settings", label: "Cấu hình hệ thống", icon: "settings" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
  GD: [
    { id: "overview", label: "Tổng quan điều hành", icon: "chart" },
    { id: "policies", label: "Phê duyệt chính sách", icon: "clipboard" },
    { id: "reports_quality", label: "Khách hàng & chất lượng", icon: "shield" },
    { id: "reports_finance", label: "Báo cáo tài chính", icon: "wallet" },
    { id: "reports_technicians", label: "Hiệu suất KTV", icon: "users" },
    { id: "profile", label: "Cá nhân", icon: "user" },
  ],
};

const defaultPageByRole = {
  KH: "dashboard",
  KTV: "overview",
  DPV: "dispatch",
  CSKH: "support",
  KT: "overview",
  ADMIN: "overview",
  GD: "overview",
};

export default function App() {
  const [token, setToken] = useState(
    () => localStorage.getItem("homefix-token") || "",
  );
  const [user, setUser] = useState(null);
  const [page, setPage] = useState("dashboard");
  const [selectedServiceId, setSelectedServiceId] = useState(null);
  const [revision, setRevision] = useState(0);
  const [notice, setNotice] = useState("");
  const [authError, setAuthError] = useState("");
  const [loading, setLoading] = useState(Boolean(token));
  const [registering, setRegistering] = useState(false);

  const api = useMemo(() => createApi(token), [token]);

  const changed = useCallback((message) => {
    if (message) setNotice(message);
    setRevision((value) => value + 1);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("homefix-token");
    setToken("");
    setUser(null);
    setPage("dashboard");
    setNotice("");
  }, []);

  useEffect(() => {
    let active = true;
    if (!token) {
      setLoading(false);
      return undefined;
    }
    setLoading(true);
    api("/auth/me")
      .then((current) => {
        if (active) {
          setUser(current);
          setPage(defaultPageByRole[current.VaiTro] || "orders");
          setLoading(false);
        }
      })
      .catch((failure) => {
        if (active) {
          setAuthError(failure.message);
          logout();
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, [api, logout, token]);

  const context = useMemo(
    () => ({ api, user, revision, changed, setUser }),
    [api, user, revision, changed],
  );

  if (loading)
    return (
      <main className="auth">
        <p>Đang kiểm tra phiên đăng nhập…</p>
      </main>
    );

  if (!user)
    return (
      <Session.Provider value={context}>
        <main className="auth">
          <div className="brand">
            <span className="brand-mark">
              <Icon name="house" size={20} />
            </span>
            HomeFix.
          </div>
          <h1>{registering ? "Đăng ký khách hàng" : "Đăng nhập"}</h1>
          <p>Dịch vụ sửa chữa và bảo trì gia đình</p>
          {authError && <p className="error">{authError}</p>}
          {notice && (
            <p className="success" role="status">
              {notice}
            </p>
          )}
          <Form
            key={String(registering)}
            fields={[
              ...(registering
                ? [
                  {
                    name: "HoTen",
                    label: "Họ và tên",
                    required: true,
                    maxLength: 120,
                  },
                ]
                : []),
              {
                name: "SoDienThoai",
                label: "Số điện thoại",
                type: "tel",
                required: true,
                maxLength: 20,
              },
              ...(registering
                ? [
                  {
                    name: "Email",
                    label: "Email",
                    type: "email",
                    maxLength: 254,
                  },
                ]
                : []),
              {
                name: "MatKhau",
                label: "Mật khẩu",
                type: "password",
                required: true,
                minLength: 6,
              },
            ]}
            submit={registering ? "Tạo tài khoản" : "Đăng nhập"}
            onSubmit={async (values) => {
              setAuthError("");
              if (registering) {
                await api("/auth/register", { method: "POST", body: values });
                setNotice("Đăng ký thành công. Bạn có thể đăng nhập ngay.");
                setRegistering(false);
              } else {
                const result = await api("/auth/login", {
                  method: "POST",
                  body: values,
                });
                localStorage.setItem("homefix-token", result.token);
                setUser(result.user);
                setToken(result.token);
                setPage(defaultPageByRole[result.user.VaiTro] || "orders");
                setNotice("");
              }
            }}
          />
          <button
            type="button"
            className="link"
            onClick={() => {
              setRegistering(!registering);
              setNotice("");
              setAuthError("");
            }}
          >
            {registering
              ? "Đã có tài khoản? Đăng nhập"
              : "Chưa có tài khoản? Đăng ký khách hàng"}
          </button>
          <details className="demo-accounts">
            <summary>Tài khoản thực hành (mật khẩu: 123456)</summary>
            <ul>
              {roles.map(([code, name], index) => (
                <li key={code}>
                  {name}: <code>090000000{index + 1}</code>
                </li>
              ))}
            </ul>
          </details>
        </main>
      </Session.Provider>
    );

  const customer = user.VaiTro === "KH";
  const menus = menuByRole[user.VaiTro] || [];

  const renderView = () => {
    switch (page) {
      case "dashboard":
        return (
          <CustomerDashboard
            onNavigate={(p) => setPage(p)}
            onBookService={(id) => {
              setSelectedServiceId(id);
              setPage("services");
            }}
          />
        );
      case "services":
        return <ServicesPage initialServiceId={selectedServiceId} />;
      case "orders":
        return <OrdersPage />;
      case "support":
        return <SupportPage />;
      case "overview":
        if (user.VaiTro === "KTV")
          return <TechnicianOverview onNavigate={(p) => setPage(p)} />;
        if (user.VaiTro === "KT")
          return <FinanceOverview onNavigate={(p) => setPage(p)} />;
        if (user.VaiTro === "GD")
          return <DirectorOverview onNavigate={(p) => setPage(p)} />;
        if (user.VaiTro === "ADMIN")
          return <AdminOverview onNavigate={(p) => setPage(p)} />;
        return <OrdersPage />;
      case "dispatch":
        return <DispatcherHub />;
      case "wallet":
        return <WalletPage />;
      case "settlements":
        return <SettlementsPage />;
      case "wallet_admin":
        return <WalletApprovalPage />;
      case "bank_requests":
        return <BankRequestsPage />;
      case "policies":
        return <PolicyApprovalPage />;
      case "reports":
        return <ReportsPage activeTab="finance" />;
      case "reports_finance":
        return <ReportsPage activeTab="finance" />;
      case "reports_quality":
        return <ReportsPage activeTab="quality" />;
      case "reports_technicians":
        return <ReportsPage activeTab="technicians" />;
      case "users":
        return <AdminPage />;
      case "applications":
        return <ApplicationsPage />;
      case "catalog":
        return <CatalogPage />;
      case "audit":
        return <AuditPage />;
      case "settings":
        return <SettingsPage />;
      case "profile":
        return <ProfilePage />;
      default:
        return customer ? (
          <CustomerDashboard onNavigate={(p) => setPage(p)} />
        ) : (
          <OrdersPage />
        );
    }
  };

  return (
    <Session.Provider value={context}>
      <div className={`app-shell ${customer ? "customer-shell" : "staff-shell"}`}>
        {!customer && (
          <aside className="sidebar">
            <div className="brand">
              <span className="brand-mark">
                <Icon name="house" size={20} />
              </span>
              HomeFix<span className="brand-dot">.</span>
            </div>
            <div className="sidebar-label">{text(user.VaiTro)}</div>
            <nav>
              {menus.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={page === item.id ? "active" : ""}
                  onClick={() => {
                    setPage(item.id);
                    setNotice("");
                  }}
                >
                  <Icon name={item.icon} size={18} />
                  <span>{item.label}</span>
                </button>
              ))}
            </nav>
            <div className="sidebar-bottom">
              <button
                type="button"
                className={page === "profile" ? "active" : ""}
                onClick={() => setPage("profile")}
              >
                <Icon name="user" size={18} />
                <span>Hồ sơ cá nhân</span>
              </button>
              <button type="button" onClick={logout}>
                <Icon name="logout" size={18} />
                <span>Đăng xuất</span>
              </button>
              <small>HomeFix · Sửa chữa & bảo trì</small>
            </div>
          </aside>
        )}

        <div className="app-body">
          <header className="topbar">
            {customer ? (
              <div className="brand" onClick={() => setPage("dashboard")} style={{ cursor: "pointer" }}>
                <span className="brand-mark">
                  <Icon name="house" size={20} />
                </span>
                HomeFix<span className="brand-dot">.</span>
              </div>
            ) : (
              <div className="topbar-title">
                {text(user.VaiTro)}
                <span>Không gian làm việc HomeFix</span>
              </div>
            )}

            {customer && (
              <nav className="customer-nav">
                {menus.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    className={page === item.id ? "active" : ""}
                    onClick={() => {
                      setPage(item.id);
                      setNotice("");
                    }}
                  >
                    <Icon name={item.icon} size={16} />
                    <span>{item.label}</span>
                  </button>
                ))}
              </nav>
            )}

            <div className="topbar-actions">
              <div
                className="profile-chip"
                onClick={() => setPage("profile")}
                style={{ cursor: "pointer" }}
                title="Xem hồ sơ cá nhân"
              >
                <span className="avatar">
                  {user.HoTen?.split(" ").at(-1)?.slice(0, 1) || "U"}
                </span>
                <div>
                  <b>{user.HoTen}</b>
                  <small>{text(user.VaiTro)}</small>
                </div>
              </div>
              <button
                className="icon-btn"
                onClick={logout}
                title="Đăng xuất"
                aria-label="Đăng xuất"
              >
                <Icon name="logout" size={18} />
              </button>
            </div>
          </header>

          <main className="main-content">
            {notice && (
              <div className="notice success" role="status">
                <span>{notice}</span>
                <button
                  className="link"
                  aria-label="Đóng thông báo"
                  onClick={() => setNotice("")}
                >
                  Đóng
                </button>
              </div>
            )}
            {renderView()}
          </main>

          <footer className="site-footer">
            HomeFix · Chăm sóc ngôi nhà của bạn <span>Dịch vụ sửa chữa và bảo trì gia đình</span>
          </footer>
        </div>
      </div>
    </Session.Provider>
  );
}
