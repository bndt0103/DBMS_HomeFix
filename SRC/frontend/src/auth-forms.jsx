import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from './api';
import { useApp, Field, Submit, ErrorBox, roleNames } from './shared';

function useOtp() {
  const [challenge, setChallenge] = useState(null),
    [otp, setOtp] = useState(''),
    [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (!challenge) return;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [challenge]);
  const reset = () => {
    setChallenge(null);
    setOtp('');
  };
  return {
    challenge,
    otp,
    setOtp,
    reset,
    received: (data) => {
      const now = Date.now();
      setNow(now);
      setChallenge({
        ...data,
        retryAt: now + data.retryAfter * 1000,
        endAt: now + data.expiresIn * 1000,
      });
      setOtp('');
    },
    wait: challenge ? Math.max(0, Math.ceil((challenge.retryAt - now) / 1000)) : 0,
    remaining: challenge ? Math.max(0, Math.ceil((challenge.endAt - now) / 1000)) : 0,
    proof: () => ({ challengeId: challenge?.challengeId, otp }),
  };
}
function OtpFields({ flow, busy, resend }) {
  return (
    <>
      {flow.challenge && (
        <div className="otp-panel">
          <p role="status">{flow.challenge.message}</p>
          <Field
            label="Mã OTP"
            hint={
              flow.remaining
                ? `Mã còn hiệu lực ${flow.remaining} giây.`
                : 'Mã đã hết hạn. Vui lòng gửi lại mã.'
            }
          >
            <input
              required
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9]{6}"
              maxLength={6}
              placeholder="Nhập 6 chữ số"
              value={flow.otp}
              onChange={(e) => flow.setOtp(e.target.value.replace(/\D/g, ''))}
            />
          </Field>
          <button
            type="button"
            className="text-btn"
            disabled={busy || flow.wait > 0}
            onClick={resend}
          >
            {flow.wait ? `Gửi lại sau ${flow.wait}s` : 'Gửi lại mã OTP'}
          </button>
        </div>
      )}
    </>
  );
}

export function AuthForm() {
  const { login } = useApp(),
    navigate = useNavigate(),
    flow = useOtp();
  const [mode, setMode] = useState('login'),
    [values, setValues] = useState({
      identifier: '',
      password: '',
      confirmPassword: '',
      fullName: '',
      phone: '',
      email: '',
    });
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null),
    [notice, setNotice] = useState('');
  const register = mode === 'register',
    forgot = mode === 'forgot';
  function changeMode(value) {
    setMode(value);
    flow.reset();
    setError(null);
    setNotice('');
    setValues((s) => ({
      ...s,
      password: '',
      confirmPassword: '',
      identifier: value === 'forgot' ? '' : s.identifier,
    }));
  }
  function set(key, value) {
    setValues((s) => ({ ...s, [key]: value }));
    flow.reset();
    setError(null);
    setNotice('');
  }
  const registration = () => ({
    fullName: values.fullName,
    phone: values.phone,
    email: values.email || null,
    password: values.password,
  });
  async function requestCode() {
    const r = await api(register ? '/auth/register/otp' : '/auth/forgot-password/otp', {
      method: 'POST',
      body: register ? registration() : { identifier: values.identifier },
    });
    flow.received(r.data);
  }
  async function run(fn) {
    setBusy(true);
    setError(null);
    setNotice('');
    try {
      await fn();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
  async function submit(e) {
    e.preventDefault();
    if ((register || forgot) && values.password !== values.confirmPassword) {
      setError(
        new Error(
          forgot
            ? 'Mật khẩu mới và xác nhận mật khẩu không khớp.'
            : 'Mật khẩu và xác nhận mật khẩu không khớp.',
        ),
      );
      return;
    }
    await run(async () => {
      if (mode === 'login') {
        const r = await api('/auth/login', {
          method: 'POST',
          body: { identifier: values.identifier, password: values.password },
        });
        login(r.data);
        navigate('/');
        return;
      }
      if (!flow.challenge) {
        await requestCode();
        return;
      }
      if (register) {
        await api('/auth/register', {
          method: 'POST',
          body: { ...registration(), ...flow.proof() },
        });
        setValues((s) => ({ ...s, identifier: s.phone, password: '', confirmPassword: '' }));
      } else {
        await api('/auth/reset-password', {
          method: 'POST',
          body: { identifier: values.identifier, newPassword: values.password, ...flow.proof() },
        });
        setValues((s) => ({ ...s, password: '', confirmPassword: '' }));
      }
      setMode('login');
      flow.reset();
      setNotice(
        register
          ? 'Đăng ký thành công. Vui lòng đăng nhập.'
          : 'Đã đặt lại mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.',
      );
    });
  }
  return (
    <>
      <span className="eyebrow">CHÀO MỪNG BẠN</span>
      <h1>{register ? 'Tạo tài khoản' : forgot ? 'Quên mật khẩu' : 'Đăng nhập HomeFix'}</h1>
      <p>
        {register
          ? 'Mã OTP sẽ được gửi qua email để xác nhận đăng ký.'
          : forgot
            ? 'Nhập email đã đăng ký để nhận mã OTP đặt lại mật khẩu.'
            : 'Quản lý dịch vụ và theo dõi công việc ở một nơi.'}
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
                  onChange={(e) => set('fullName', e.target.value)}
                />
              </Field>
              <Field label="Số điện thoại">
                <input
                  required
                  type="tel"
                  pattern="0[0-9]{9}"
                  autoComplete="tel"
                  value={values.phone}
                  onChange={(e) => set('phone', e.target.value)}
                />
              </Field>
              <Field label="Email / Gmail">
                <input
                  required
                  type="email"
                  maxLength={200}
                  autoComplete="email"
                  value={values.email}
                  onChange={(e) => set('email', e.target.value)}
                />
              </Field>
            </>
          ) : (
            <Field label={forgot ? 'Email / Gmail đã đăng ký' : 'Số điện thoại hoặc email'}>
              <input
                required
                type={forgot ? 'email' : 'text'}
                autoComplete="username"
                value={values.identifier}
                onChange={(e) => set('identifier', e.target.value)}
              />
            </Field>
          )}
          <Field
            label={forgot ? 'Mật khẩu mới' : 'Mật khẩu'}
            hint={mode !== 'login' ? 'Ít nhất 8 ký tự, tối đa 72 byte UTF-8.' : undefined}
          >
            <input
              required
              type="password"
              minLength={mode === 'login' ? 1 : 8}
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              value={values.password}
              onChange={(e) => set('password', e.target.value)}
            />
          </Field>
          {(register || forgot) && (
            <Field label={forgot ? 'Xác nhận mật khẩu mới' : 'Xác nhận mật khẩu'}>
              <input
                required
                type="password"
                minLength={8}
                autoComplete="new-password"
                value={values.confirmPassword}
                onChange={(e) => set('confirmPassword', e.target.value)}
              />
            </Field>
          )}
          {mode !== 'login' && (
            <OtpFields flow={flow} busy={busy} resend={() => run(requestCode)} />
          )}
          <ErrorBox error={error} />
          {notice && (
            <div className="notice success" role="status">
              {notice}
            </div>
          )}
          <Submit busy={busy}>
            {mode === 'login'
              ? 'Đăng nhập'
              : !flow.challenge
                ? register
                  ? 'Đăng ký tài khoản'
                  : 'Đặt lại mật khẩu'
                : register
                  ? 'Xác nhận đăng ký'
                  : 'Xác nhận đặt lại mật khẩu'}
          </Submit>
        </fieldset>
      </form>
      <div className="auth-switch auth-links">
        <button
          className="text-btn"
          disabled={busy}
          onClick={() => changeMode(register ? 'login' : 'register')}
        >
          {register ? 'Đăng nhập' : 'Đăng ký ngay'}
        </button>
        <span>·</span>
        <button
          className="text-btn"
          disabled={busy}
          onClick={() => changeMode(forgot ? 'login' : 'forgot')}
        >
          {forgot ? 'Quay lại đăng nhập' : 'Quên mật khẩu?'}
        </button>
      </div>
      {mode === 'login' && (
        <details className="demo-help">
          <summary>Tài khoản dùng thử cho đồ án</summary>
          <p>
            Mật khẩu chung: <code>HomeFix@123</code>
          </p>
          <div className="demo-roles">
            {Object.entries(roleNames).map(([r, name]) => (
              <button
                key={r}
                type="button"
                disabled={busy}
                onClick={() =>
                  setValues((s) => ({
                    ...s,
                    identifier: r.toLowerCase() + '@homefix.local',
                    password: 'HomeFix@123',
                  }))
                }
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

export function PasswordChange({ user, logout }) {
  const flow = useOtp(),
    [currentPassword, setCurrent] = useState(''),
    [newPassword, setNew] = useState(''),
    [confirmPassword, setConfirm] = useState('');
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(null);
  useEffect(() => {
    flow.reset();
  }, [user.email, user.phone]);
  async function run(fn) {
    setBusy(true);
    setError(null);
    try {
      await fn();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
  async function requestCode() {
    const r = await api('/users/me/password/otp', { method: 'POST', body: { currentPassword } });
    flow.received(r.data);
  }
  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        if (newPassword !== confirmPassword) {
          setError(new Error('Mật khẩu mới và xác nhận mật khẩu không khớp.'));
          return;
        }
        run(async () => {
          if (!flow.challenge) {
            await requestCode();
            return;
          }
          await api('/users/me/password', {
            method: 'POST',
            body: { currentPassword, newPassword, ...flow.proof() },
          });
          await logout('Đã đổi mật khẩu thành công. Vui lòng đăng nhập lại.');
        });
      }}
    >
      <fieldset disabled={busy} className="auth-fields">
        <p>
          {user.email
            ? `Mã OTP sẽ được gửi đến ${user.email}.`
            : 'Tài khoản chưa có email. Vui lòng cập nhật email trong hồ sơ trước.'}
        </p>
        <Field label="Mật khẩu hiện tại">
          <input
            required
            type="password"
            autoComplete="current-password"
            value={currentPassword}
            onChange={(e) => {
              setCurrent(e.target.value);
              flow.reset();
            }}
          />
        </Field>
        <Field label="Mật khẩu mới" hint="Ít nhất 8 ký tự, tối đa 72 byte UTF-8.">
          <input
            required
            type="password"
            minLength={8}
            autoComplete="new-password"
            value={newPassword}
            onChange={(e) => {
              setNew(e.target.value);
              setError(null);
            }}
          />
        </Field>
        <Field label="Xác nhận mật khẩu mới">
          <input
            required
            type="password"
            minLength={8}
            autoComplete="new-password"
            value={confirmPassword}
            onChange={(e) => {
              setConfirm(e.target.value);
              setError(null);
            }}
          />
        </Field>
        <OtpFields flow={flow} busy={busy} resend={() => run(requestCode)} />
        <ErrorBox error={error} />
        <Submit busy={busy} disabled={busy || !user.email}>
          {flow.challenge ? 'Xác nhận đổi mật khẩu' : 'Đổi mật khẩu'}
        </Submit>
      </fieldset>
    </form>
  );
}
