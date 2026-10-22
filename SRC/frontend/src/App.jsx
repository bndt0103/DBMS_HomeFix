import { useCallback, useEffect, useMemo, useState } from "react";
import { createApi } from "./api.js";
import { Form, roles, Session, text } from "./components.jsx";
import { OrdersPage, ServicesPage } from "./Orders.jsx";
import {
  AdminPage,
  CatalogPage,
  ProfilePage,
  ReportsPage,
  SettingsPage,
} from "./Management.jsx";
import { FinancePage, SupportPage, WalletPage } from "./SupportFinance.jsx";

const navigation = [
  ["orders", "Đơn dịch vụ", ["KH", "KTV", "DPV", "CSKH", "KT", "ADMIN"]],
  ["services", "Dịch vụ", ["KH", "KTV", "DPV", "CSKH", "KT", "GD", "ADMIN"]],
  ["wallet", "Ví của tôi", ["KTV"]],
  ["finance", "Thanh toán / đối soát", ["KT"]],
  ["support", "Phiếu hỗ trợ", ["KH", "CSKH", "ADMIN"]],
  ["users", "Tài khoản", ["ADMIN"]],
  ["catalog", "Danh mục dịch vụ", ["ADMIN"]],
  ["settings", "Cấu hình", ["ADMIN", "GD", "KT"]],
  ["reports", "Báo cáo", ["ADMIN", "GD", "KT"]],
  [
    "profile",
    "Hồ sơ / thông báo",
    ["KH", "KTV", "DPV", "CSKH", "KT", "GD", "ADMIN"],
  ],
];

export default function App() {
  const [token, setToken] = useState(
    () => localStorage.getItem("homefix-token") || "",
  );
  const [user, setUser] = useState(null);
  const [page, setPage] = useState("orders");
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
    setPage("orders");
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
          setPage(
            { GD: "reports", ADMIN: "users", KT: "finance" }[current.VaiTro] ||
              "orders",
          );
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
          <div className="brand">HomeFix</div>
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
            <summary>Tài khoản thực hành</summary>
            <p>
              Mật khẩu mặc định: <code>123456</code>. Đổi mật khẩu trước khi sử
              dụng thực tế.
            </p>
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

  const views = {
    orders: <OrdersPage />,
    services: <ServicesPage />,
    wallet: <WalletPage />,
    finance: <FinancePage />,
    support: <SupportPage />,
    users: <AdminPage />,
    catalog: <CatalogPage />,
    settings: <SettingsPage />,
    reports: <ReportsPage />,
    profile: <ProfilePage />,
  };
  return (
    <Session.Provider value={context}>
      <header className="app-header">
        <div>
          <strong className="brand">HomeFix</strong>
          <span>Dịch vụ gia đình</span>
        </div>
        <div className="user-box">
          <span>
            {user.HoTen} · {text(user.VaiTro)}
          </span>
          <button className="secondary" onClick={logout}>
            Đăng xuất
          </button>
        </div>
      </header>
      <nav aria-label="Điều hướng chính">
        {navigation
          .filter(([, , allowed]) => allowed.includes(user.VaiTro))
          .map(([id, title]) => (
            <button
              key={id}
              type="button"
              className={page === id ? "active" : ""}
              onClick={() => {
                setPage(id);
                setNotice("");
              }}
            >
              {title}
            </button>
          ))}
      </nav>
      <main className="content">
        <div className="toolbar">
          <span>{navigation.find(([id]) => id === page)?.[1]}</span>
          <button
            className="secondary"
            onClick={() => changed("Đã tải lại dữ liệu.")}
          >
            Tải lại
          </button>
        </div>
        {notice && (
          <div className="notice" role="status">
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
        {views[page] || views.orders}
      </main>
      <footer>HomeFix · Dịch vụ sửa chữa và bảo trì gia đình.</footer>
    </Session.Provider>
  );
}
