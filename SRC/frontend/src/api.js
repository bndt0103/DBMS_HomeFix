import { normalizeApiUrl, resolveApiUrl } from './api-endpoint';
let token = '';
let onUnauthorized = () => {};
export function setSession(accessToken, handler) {
  token = accessToken || '';
  if (handler) onUnauthorized = handler;
}
export function baseUrl() {
  return resolveApiUrl({
    stored: localStorage.getItem('homefix.api') || '',
    configured: import.meta.env.VITE_API_BASE_URL || '',
  });
}
export function saveBaseUrl(value) {
  localStorage.setItem('homefix.api', normalizeApiUrl(value));
  setSession('');
}
export async function api(path, { method = 'GET', body, key, blob = false, signal } = {}) {
  if (!baseUrl())
    throw new Error('Chưa cấu hình máy chủ. Mở Cài đặt kết nối và nhập địa chỉ HTTPS của HomeFix.');
  const headers = {};
  if (token) headers.Authorization = 'Bearer ' + token;
  if (body && !(body instanceof FormData)) headers['Content-Type'] = 'application/json';
  if (key) headers['Idempotency-Key'] = key;
  let r;
  try {
    r = await fetch(baseUrl() + path, {
      method,
      headers,
      body: body instanceof FormData ? body : body ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (e) {
    if (e.name === 'AbortError') throw e;
    throw new Error(
      'Không kết nối được máy chủ. Kiểm tra mạng và địa chỉ API trong Cài đặt kết nối.',
    );
  }
  if (!r.ok) {
    const data = await r.json().catch(() => ({}));
    if (r.status === 401 && token) {
      setSession('');
      onUnauthorized();
    }
    const e = new Error(data.error?.message || 'Không thể xử lý yêu cầu.');
    e.status = r.status;
    e.code = data.error?.code;
    e.details = data.error?.details;
    e.requestId = data.requestId;
    throw e;
  }
  const result = await (blob ? r.blob() : r.json());
  if (!['GET', 'HEAD'].includes(method.toUpperCase()))
    window.dispatchEvent(new Event('homefix:changed'));
  return result;
}
export async function upload(file, purpose, orderId) {
  const body = new FormData();
  body.set('file', file);
  body.set('purpose', purpose);
  if (orderId) body.set('orderId', String(orderId));
  return (await api('/uploads', { method: 'POST', body })).data;
}
// getRandomValues also works on HTTP LAN addresses used for classroom demos.
export const uuid = () => {
  if (crypto.randomUUID) return crypto.randomUUID();
  const b = crypto.getRandomValues(new Uint8Array(16));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  const h = [...b].map((n) => n.toString(16).padStart(2, '0')).join('');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
};
