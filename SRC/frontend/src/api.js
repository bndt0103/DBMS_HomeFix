const base = (import.meta.env.VITE_API_BASE || "/api").replace(/\/$/, "");

export function createApi(token) {
  return async function api(path, { method = "GET", body, raw = false } = {}) {
    const headers = {};
    if (token) headers.Authorization = `Bearer ${token}`;
    const options = { method, headers };
    if (body instanceof FormData) {
      options.body = body;
    } else if (body !== undefined) {
      headers["Content-Type"] = "application/json";
      options.body = JSON.stringify(body);
    }
    const response = await fetch(`${base}${path}`, options);
    if (raw && response.ok) return response.blob();
    const result = await response.json().catch(() => null);
    if (!response.ok || !result?.ok) {
      const message =
        result?.error?.message || `Yêu cầu thất bại (HTTP ${response.status}).`;
      const error = new Error(message);
      error.status = response.status;
      error.code = result?.error?.code;
      throw error;
    }
    return result.data;
  };
}
