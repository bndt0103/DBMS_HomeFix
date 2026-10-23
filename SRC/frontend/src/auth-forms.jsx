import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "./api";
import { useApp, Field, Submit, ErrorBox, roleNames } from "./shared";

const demoPhones = {
  KH: "0900000001",
  KTV: "0900000002",
  DPV: "0900000003",
  CSKH: "0900000004",
  KT: "0900000005",
  GD: "0900000006",
  ADMIN: "0900000007",
};

export function AuthForm() {
  const { login } = useApp(),
    navigate = useNavigate();
  const [mode, setMode] = useState("login");
  const [values, setValues] = useState({
    identifier: "",
    password: "",
    confirmPassword: "",
    fullName: "",
    phone: "",
    email: "",
  });
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null),
    [notice, setNotice] = useState("");
  const register = mode === "register";
  function set(key, value) {
    setValues((s) => ({ ...s, [key]: value }));
    setError(null);
    setNotice("");
  }
  function changeMode(value) {
    setMode(value);
    setError(null);
    setNotice("");
    setValues((s) => ({ ...s, password: "", confirmPassword: "" }));
  }
  async function submit(e) {
    e.preventDefault();
    if (register && values.password !== values.confirmPassword) {
      setError(new Error("Mật khẩu và xác nhận mật khẩu không khớp."));
      return;
    }
    setBusy(true);
    setError(null);
    setNotice("");
    try {
      if (register) {
        await api("/auth/register", {
          method: "POST",
          body: {
            fullName: values.fullName.trim(),
            phone: values.phone.trim(),
            email: values.email.trim() || null,
            password: values.password,
          },
        });
        setValues((s) => ({
          ...s,
          identifier: s.phone,
          password: "",
          confirmPassword: "",
        }));
        setMode("login");
        setNotice("Đăng ký thành công. Vui lòng đăng nhập.");
      } else {
        const r = await api("/auth/login", {
          method: "POST",
          body: {
            identifier: values.identifier.trim(),
            password: values.password,
          },
        });
        login(r.data);
        navigate("/");
      }
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
  return (
    <>
      <span className="eyebrow">CHÀO MỪNG BẠN</span>
      <h1>{register ? "Tạo tài khoản" : "Đăng nhập HomeFix"}</h1>
      <p>
        {register
          ? "Đăng ký bằng số điện thoại để đặt dịch vụ và theo dõi đơn."
          : "Quản lý dịch vụ và theo dõi công việc ở một nơi."}
      </p>
      <form onSubmit={submit}>
        <fieldset disabled={busy} className="auth-fields">
          {register ? (
            <>
              <Field label="Họ và tên">
                <input
                  required
                  minLength={2}
                  maxLength={120}
                  autoComplete="name"
                  value={values.fullName}
                  onChange={(e) => set("fullName", e.target.value)}
                />
              </Field>
              <Field label="Số điện thoại">
                <input
                  required
                  type="tel"
                  pattern="0[0-9]{9}"
                  autoComplete="tel"
                  value={values.phone}
                  onChange={(e) => set("phone", e.target.value)}
                />
              </Field>
              <Field label="Email (không bắt buộc)">
                <input
                  type="email"
                  maxLength={200}
                  autoComplete="email"
                  value={values.email}
                  onChange={(e) => set("email", e.target.value)}
                />
              </Field>
            </>
          ) : (
            <Field label="Số điện thoại hoặc email">
              <input
                required
                autoComplete="username"
                value={values.identifier}
                onChange={(e) => set("identifier", e.target.value)}
              />
            </Field>
          )}
          <Field
            label="Mật khẩu"
            hint={register ? "Từ 6 ký tự, tối đa 72 byte UTF-8." : undefined}
          >
            <input
              required
              type="password"
              minLength={register ? 6 : 1}
              autoComplete={register ? "new-password" : "current-password"}
              value={values.password}
              onChange={(e) => set("password", e.target.value)}
            />
          </Field>
          {register && (
            <Field label="Xác nhận mật khẩu">
              <input
                required
                type="password"
                minLength={6}
                autoComplete="new-password"
                value={values.confirmPassword}
                onChange={(e) => set("confirmPassword", e.target.value)}
              />
            </Field>
          )}
          <ErrorBox error={error} />
          {notice && (
            <div className="notice success" role="status">
              {notice}
            </div>
          )}
          <Submit busy={busy}>
            {register ? "Đăng ký tài khoản" : "Đăng nhập"}
          </Submit>
        </fieldset>
      </form>
      <div className="auth-switch auth-links">
        <button
          className="text-btn"
          disabled={busy}
          onClick={() => changeMode(register ? "login" : "register")}
        >
          {register ? "Đăng nhập" : "Đăng ký ngay"}
        </button>
        <span>·</span>
        <button
          className="text-btn"
          disabled={busy}
          onClick={() => {
            setError(null);
            setNotice(
              "Nếu quên mật khẩu, vui lòng liên hệ quản trị viên để được hỗ trợ. Nếu vẫn đăng nhập được, bạn có thể đổi mật khẩu tại mục Hồ sơ.",
            );
          }}
        >
          Quên mật khẩu?
        </button>
      </div>
      {!register && (
        <details className="demo-help">
          <summary>Tài khoản dùng thử cho đồ án</summary>
          <p>
            Mật khẩu chung: <code>123456</code>
          </p>
          <div className="demo-roles">
            {Object.entries(roleNames).map(([r, name]) => (
              <button
                key={r}
                type="button"
                disabled={busy}
                onClick={() => {
                  setValues((s) => ({
                    ...s,
                    identifier: demoPhones[r],
                    password: "123456",
                  }));
                  setError(null);
                  setNotice("");
                }}
              >
                {name}
              </button>
            ))}
          </div>
        </details>
      )}
    </>
  );
}

export function PasswordChange({ logout }) {
  const [currentPassword, setCurrent] = useState(""),
    [newPassword, setNew] = useState(""),
    [confirmPassword, setConfirm] = useState("");
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null);
  async function submit(e) {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setError(new Error("Mật khẩu mới và xác nhận mật khẩu không khớp."));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await api("/users/me/password", {
        method: "POST",
        body: { currentPassword, newPassword },
      });
      await logout("Đã đổi mật khẩu thành công. Vui lòng đăng nhập lại.");
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
  return (
    <form onSubmit={submit}>
      <fieldset disabled={busy} className="auth-fields">
        <p>Nhập mật khẩu hiện tại để xác nhận thay đổi.</p>
        <Field label="Mật khẩu hiện tại">
          <input
            required
            type="password"
            autoComplete="current-password"
            value={currentPassword}
            onChange={(e) => setCurrent(e.target.value)}
          />
        </Field>
        <Field label="Mật khẩu mới" hint="Từ 6 ký tự, tối đa 72 byte UTF-8.">
          <input
            required
            type="password"
            minLength={6}
            autoComplete="new-password"
            value={newPassword}
            onChange={(e) => setNew(e.target.value)}
          />
        </Field>
        <Field label="Xác nhận mật khẩu mới">
          <input
            required
            type="password"
            minLength={6}
            autoComplete="new-password"
            value={confirmPassword}
            onChange={(e) => setConfirm(e.target.value)}
          />
        </Field>
        <ErrorBox error={error} />
        <Submit busy={busy}>Đổi mật khẩu</Submit>
      </fieldset>
    </form>
  );
}
