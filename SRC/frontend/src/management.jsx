import { MonitoringSettings, ReportOverview, CashflowChart, useReportData } from './report-widgets';
import { ReportWorkspace, csvDownload } from './reports-ui';
import { ApplicationWizard } from './application-wizard';
import { WalletHistory } from './wallet-history';
import { BankAccounts, BankPaymentQueue } from './bank-admin';
import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation, useParams } from 'react-router-dom';
import {
  Plus,
  Pencil,
  CheckCircle2,
  Wallet,
  ArrowDownToLine,
  ArrowUpFromLine,
  RefreshCw,
  Download,
  Star,
  ShieldCheck,
  Users,
  ChartNoAxesCombined,
  Lock,
  ChevronRight,
  Search,
  UserCircle,
} from 'lucide-react';
import { api, upload, uuid } from './api';
import {
  useApp,
  useData,
  useAction,
  PageHead,
  Card,
  Field,
  ErrorBox,
  Loading,
  Empty,
  Submit,
  Badge,
  money,
  date,
  code,
  labels,
  roleNames,
  groups,
  Modal,
  ProtectedImage,
} from './shared';
import { Stat } from './pages';
function Table({ headers, rows, render, empty = 'Chưa có dữ liệu' }) {
  return rows?.length ? (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {headers.map((h) => (
              <th key={h}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>{rows.map(render)}</tbody>
      </table>
    </div>
  ) : (
    <Empty title={empty} />
  );
}
function AdminOrders() {
  const [filter, setFilter] = useState({ status: '', serviceGroup: '', from: '', to: '', page: 1 });
  const q = new URLSearchParams();
  if (filter.status) q.set('status', filter.status);
  if (filter.serviceGroup) q.set('serviceGroup', filter.serviceGroup);
  if (filter.from) q.set('from', new Date(filter.from + 'T00:00:00+07:00').toISOString());
  if (filter.to) {
    const t = new Date(filter.to + 'T00:00:00+07:00');
    t.setDate(t.getDate() + 1);
    q.set('to', t.toISOString());
  }
  q.set('page', filter.page);
  q.set('pageSize', 15);
  const r = useData('/orders?' + q.toString());
  const set = (k, v) => setFilter((s) => ({ ...s, [k]: v, page: k === 'page' ? v : 1 }));
  const exportCsv = async () => {
    const blob = await api('/orders.csv?' + q.toString(), { blob: true });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'DanhSachDonHang.csv';
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };
  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title="Đơn sửa chữa & Bảo trì"
        text="Quản lý và tra cứu toàn bộ đơn dịch vụ trên hệ thống."
      >
        <Link className="btn primary" to="/services">
          <Plus size={17} /> Khởi tạo đơn mới
        </Link>
        <button className="btn" onClick={exportCsv}>
          <Download size={16} /> Xuất CSV
        </button>
      </PageHead>
      <div className="filter-bar">
        <Field label="Trạng thái">
          <select value={filter.status} onChange={(e) => set('status', e.target.value)}>
            <option value="">Tất cả</option>
            {Object.entries(labels).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Nhóm dịch vụ">
          <select value={filter.serviceGroup} onChange={(e) => set('serviceGroup', e.target.value)}>
            <option value="">Tất cả</option>
            {Object.entries(groups).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Từ ngày">
          <input type="date" value={filter.from} onChange={(e) => set('from', e.target.value)} />
        </Field>
        <Field label="Đến ngày">
          <input type="date" value={filter.to} onChange={(e) => set('to', e.target.value)} />
        </Field>
      </div>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          <Table
            headers={[
              'Mã đơn',
              'Dịch vụ',
              'Khách hàng',
              'Kỹ thuật viên',
              'Ngày tạo',
              'Trạng thái',
              'Thao tác',
            ]}
            rows={r.data}
            render={(o) => (
              <tr key={o.id}>
                <td>
                  <b>{code(o.id)}</b>
                </td>
                <td>
                  {o.serviceName}
                  <small>{groups[o.serviceGroup]}</small>
                </td>
                <td>
                  {o.contactName}
                  <small>{o.contactPhone}</small>
                </td>
                <td>{o.technicianName || '—'}</td>
                <td>{date(o.createdAt)}</td>
                <td>
                  <Badge value={o.status} />
                </td>
                <td>
                  <Link className="btn small" to={'/orders/' + o.id}>
                    Chi tiết
                  </Link>
                </td>
              </tr>
            )}
          />
        </Card>
      )}
      <div className="pagination">
        <button
          className="btn"
          disabled={filter.page === 1}
          onClick={() => set('page', filter.page - 1)}
        >
          Trang trước
        </button>
        <span>Trang {filter.page}</span>
        <button
          className="btn"
          disabled={!r.data || r.data.length < 15}
          onClick={() => set('page', filter.page + 1)}
        >
          Trang sau
        </button>
      </div>
    </>
  );
}
function AdminUsers() {
  const { toast } = useApp();
  const [filter, setFilter] = useState({ search: '', role: '', status: '', page: 1 });
  const [view, setView] = useState({ type: 'list', record: null });
  const q = new URLSearchParams();
  if (filter.search) q.set('search', filter.search);
  if (filter.role) q.set('role', filter.role);
  if (filter.status) q.set('status', filter.status);
  q.set('page', filter.page);
  q.set('pageSize', 15);
  const r = useData('/users?' + q.toString());
  const set = (k, v) => setFilter((s) => ({ ...s, [k]: v, page: k === 'page' ? v : 1 }));
  const refresh = () => {
    r.reload();
    toast('Đã gửi yêu cầu tải lại danh sách tài khoản.');
  };

  const getDepartment = (u) => {
    if (u.role === 'KH') return '—';
    if (u.role === 'KTV')
      return u.skillGroup ? 'Đội kỹ thuật ' + groups[u.skillGroup] : 'Đội kỹ thuật';
    if (u.role === 'DPV') return 'Đội Điều phối';
    if (u.role === 'CSKH') return 'Đội CSKH Online';
    if (u.role === 'KT') return 'Đội Kế toán Tổng hợp';
    if (u.role === 'ADMIN') return 'Đội Vận hành Hệ thống';
    if (u.role === 'GD') return 'Ban Giám đốc Điều hành';
    return '—';
  };

  if (view.type === 'detail')
    return (
      <UserDetail
        record={view.record}
        onBack={() => setView({ type: 'list', record: null })}
        onSecurity={(u) => setView({ type: 'security', record: u })}
      />
    );
  if (view.type === 'security')
    return (
      <UserSecurity
        record={view.record}
        onBack={() => setView({ type: 'list', record: null })}
        onLocked={(user) => {
          r.setData((users) =>
            users?.map((item) => (item.id === user.id ? { ...item, ...user } : item)),
          );
          setView({ type: 'list', record: null });
        }}
      />
    );

  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title="Danh sách tài khoản hệ thống"
        text="Tra cứu thông tin, vai trò, trạng thái hoạt động thực tế trên HomeFix"
      >
        <button className="btn" onClick={refresh}>
          <RefreshCw size={16} /> Cập nhật
        </button>
        <button className="btn primary" onClick={() => setView({ type: 'create', record: {} })}>
          <Plus size={17} /> Thêm tài khoản
        </button>
      </PageHead>
      <div className="filter-bar">
        <Field label="Tìm kiếm">
          <input
            type="search"
            placeholder="Tìm họ tên, số điện thoại..."
            value={filter.search}
            onChange={(e) => set('search', e.target.value)}
          />
        </Field>
        <Field label="Vai trò">
          <select value={filter.role} onChange={(e) => set('role', e.target.value)}>
            <option value="">Tất cả</option>
            {Object.entries(roleNames).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Trạng thái">
          <select value={filter.status} onChange={(e) => set('status', e.target.value)}>
            <option value="">Tất cả</option>
            <option value="active">Hoạt động</option>
            <option value="inactive">Bị khóa / Chờ duyệt</option>
          </select>
        </Field>
      </div>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          <Table
            headers={[
              'Mã ID',
              'Họ và tên',
              'Số điện thoại',
              'Email',
              'Vai trò',
              'Bộ phận',
              'Trạng thái',
              'Thao tác',
            ]}
            rows={r.data}
            render={(u) => {
              const isLocked = u.lockedUntil && new Date(u.lockedUntil) > new Date();
              return (
                <tr key={u.id}>
                  <td>
                    <b style={{ color: '#116a4e' }}>
                      {u.role}-{String(u.id).padStart(4, '0')}
                    </b>
                  </td>
                  <td>
                    <div
                      className="flex-row"
                      style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                    >
                      <div
                        style={{
                          width: '24px',
                          height: '24px',
                          borderRadius: '12px',
                          background: '#eee',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <Users size={14} color="#888" />
                      </div>{' '}
                      <b>{u.fullName}</b>
                    </div>
                  </td>
                  <td>{u.phone}</td>
                  <td>{u.email || '—'}</td>
                  <td>
                    <b>{roleNames[u.role]}</b>
                  </td>
                  <td>
                    <small>{getDepartment(u)}</small>
                  </td>
                  <td>
                    <span className={'badge ' + (u.isActive && !isLocked ? 'green' : 'red')}>
                      {isLocked ? 'Đang khóa' : u.isActive ? 'Hoạt động' : 'Bị khóa'}
                    </span>
                    {isLocked && <small>{'Đến ' + date(u.lockedUntil)}</small>}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '4px' }}>
                      <button
                        className="icon-btn small"
                        onClick={() => setView({ type: 'detail', record: u })}
                        title="Chi tiết tài khoản"
                      >
                        <Pencil size={14} />
                      </button>
                      <button
                        className="icon-btn small"
                        onClick={() => setView({ type: 'security', record: u })}
                        title="Khóa/Xóa tài khoản"
                        style={{ color: '#d93025' }}
                      >
                        <Lock size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              );
            }}
          />
        </Card>
      )}
      <div className="pagination">
        <span style={{ marginRight: 'auto' }}>
          Hiển thị {(filter.page - 1) * 15 + 1} - {Math.min(filter.page * 15, r.meta?.total || 0)}{' '}
          của {r.meta?.total || 0} tài khoản
        </span>
        <button
          className="btn"
          disabled={filter.page === 1}
          onClick={() => set('page', filter.page - 1)}
        >
          Trang trước
        </button>
        <span>Trang {filter.page}</span>
        <button
          className="btn"
          disabled={!r.data || r.data.length < 15}
          onClick={() => set('page', filter.page + 1)}
        >
          Trang sau
        </button>
      </div>
      {view.type === 'create' && (
        <Editor
          section="users"
          record={view.record}
          onClose={() => setView({ type: 'list', record: null })}
          onDone={() => {
            setView({ type: 'list', record: null });
            r.reload();
          }}
        />
      )}
    </>
  );
}
function UserDetail({ record, onBack, onSecurity }) {
  const a = useAction();
  const [form, setForm] = useState({
    fullName: record.fullName || '',
    phone: record.phone || '',
    role: record.role || 'KH',
    skillGroup: record.skillGroup || 'DienLanh',
    isActive: record.isActive ?? true,
  });
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));

  const PERMS_DEF = [
    { key: 'xem_bao_cao', label: 'Xem báo cáo' },
    { key: 'dieu_phoi_don', label: 'Điều phối đơn' },
    { key: 'phe_duyet_vi', label: 'Phê duyệt ví' },
    { key: 'quan_ly_tk', label: 'Quản lý tài khoản' },
    { key: 'xem_tai_chinh', label: 'Xem tài chính' },
    { key: 'chinh_sua_dich_vu', label: 'Chỉnh sửa dịch vụ' },
    { key: 'xem_nhat_ky', label: 'Xem nhật ký hệ thống' },
    { key: 'cau_hinh_he_thong', label: 'Cấu hình hệ thống' },
  ];
  const defaultPerms = () =>
    Object.fromEntries(PERMS_DEF.map((p) => [p.key, ['ADMIN'].includes(record.role)]));
  const [perms, setPerms] = useState(defaultPerms);
  const togglePerm = (k) => setPerms((s) => ({ ...s, [k]: !s[k] }));

  const MODULES = [
    {
      mod: 'Quản lý tài khoản',
      cols: ['Xem', 'Thêm', 'Sửa', 'Duyệt', 'Xóa'],
      vals: [1, 1, 1, 0, 0],
    },
    {
      mod: 'Đơn hàng & sửa chữa',
      cols: ['Xem', 'Thêm', 'Sửa', 'Duyệt', 'Xóa'],
      vals: [1, 1, 1, 1, 0],
    },
    {
      mod: 'Dịch vụ & bảng giá',
      cols: ['Xem', 'Thêm', 'Sửa', 'Duyệt', 'Xóa'],
      vals: [1, 0, 0, 0, 0],
    },
    {
      mod: 'Tài chính & Ví KTV',
      cols: ['Xem', 'Thêm', 'Sửa', 'Duyệt', 'Xóa'],
      vals: [1, 1, 0, 0, 0],
    },
    {
      mod: 'Cấu hình hệ thống',
      cols: ['Xem', 'Thêm', 'Sửa', 'Duyệt', 'Xóa'],
      vals: [1, 0, 0, 0, 0],
    },
  ];
  const [modulePerms, setModulePerms] = useState(() =>
    Object.fromEntries(MODULES.map((m) => [m.mod, m.vals.map(Boolean)])),
  );
  const toggleModulePerm = (mod, idx) =>
    setModulePerms((s) => ({ ...s, [mod]: s[mod].map((v, i) => (i === idx ? !v : v)) }));

  const save = () =>
    a.run(async () => {
      await api('/users/' + record.id, {
        method: 'PATCH',
        body: {
          fullName: form.fullName,
          role: form.role,
          skillGroup: form.skillGroup,
          isActive: form.isActive,
          expectedVersion: record.version,
        },
      });
    }, 'Đã cập nhật tài khoản thành công.');

  const logs = useData(record.id ? '/audit-logs' : '');
  const userLogs = (logs.data || []).filter((l) => l.actorId === record.id).slice(0, 5);

  const hasDeletePerm = Object.values(modulePerms).some((cols) => cols[4]);

  return (
    <div className="user-detail-page">
      <div
        className="breadcrumb"
        style={{
          display: 'flex',
          gap: '8px',
          alignItems: 'center',
          color: '#5f6368',
          marginBottom: '24px',
        }}
      >
        <span onClick={onBack} style={{ cursor: 'pointer', fontWeight: '500' }}>
          Quản lý tài khoản
        </span>
        <ChevronRight size={16} />
        <b style={{ color: '#202124' }}>Chi tiết tài khoản</b>
      </div>

      <div
        className="detail-header"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          paddingBottom: '24px',
          borderBottom: '1px solid #eee',
          marginBottom: '24px',
        }}
      >
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          <div
            style={{
              width: '48px',
              height: '48px',
              borderRadius: '24px',
              background: '#eee',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Users size={24} color="#888" />
          </div>
          <div>
            <h2 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
              Hồ sơ TK: {record.fullName}{' '}
              <Badge value={record.isActive ? 'Hoạt động' : 'Bị khóa'} />
            </h2>
            <small style={{ color: '#5f6368' }}>
              Mã số tài khoản: {record.role}-{record.id ? String(record.id).padStart(4, '0') : ''} •
              Email: {record.email || '—'}
            </small>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            className="btn"
            style={{ color: '#d93025', borderColor: '#fce8e6', background: '#fce8e6' }}
            onClick={() => onSecurity(record)}
          >
            Khóa tài khoản
          </button>
          <button
            className="btn primary"
            style={{ background: '#116a4e' }}
            disabled={a.busy}
            onClick={save}
          >
            {a.busy ? 'Đang lưu…' : 'Lưu thay đổi'}
          </button>
        </div>
      </div>
      <ErrorBox error={a.error} />

      <div
        className="detail-body"
        style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '24px' }}
      >
        <Card title="Chỉnh sửa thông tin hồ sơ">
          <Field label="Họ và tên">
            <input
              type="text"
              value={form.fullName}
              onChange={(e) => set('fullName', e.target.value)}
            />
          </Field>
          <Field label="Số điện thoại">
            <input
              type="text"
              value={form.phone}
              readOnly
              style={{ background: '#f1f3f4', cursor: 'not-allowed' }}
            />
          </Field>
          <Field label="Nhóm vai trò">
            <select value={form.role} onChange={(e) => set('role', e.target.value)}>
              {Object.entries(roleNames).map(([k, n]) => (
                <option key={k} value={k}>
                  {n}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Bộ phận trực thuộc">
            <select value={form.skillGroup} onChange={(e) => set('skillGroup', e.target.value)}>
              <option value="DienLanh">Đội Kỹ thuật số 1</option>
              <option value="DienNuoc">Đội Kỹ thuật số 2</option>
              <option value="DienGiaDung">Đội CSKH Online</option>
              <option value="VeSinh">Đội Kế toán Tổng hợp</option>
            </select>
          </Field>
          <label className="checkbox" style={{ marginTop: '12px' }}>
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => set('isActive', e.target.checked)}
            />{' '}
            Tài khoản hoạt động
          </label>
          <div
            style={{
              border: '1px solid #eee',
              padding: '16px',
              borderRadius: '8px',
              marginTop: '16px',
            }}
          >
            <b style={{ display: 'block', marginBottom: '12px' }}>Lịch sử hoạt động gần đây</b>
            {logs.loading ? (
              <small style={{ color: '#aaa' }}>Đang tải…</small>
            ) : userLogs.length === 0 ? (
              <div
                style={{ fontSize: '13px', color: '#aaa', textAlign: 'center', padding: '12px 0' }}
              >
                Không có lịch sử hoạt động nào.
              </div>
            ) : (
              userLogs.map((l) => (
                <div
                  key={l.id}
                  style={{ fontSize: '13px', color: '#5f6368', marginBottom: '12px' }}
                >
                  <span style={{ color: '#202124' }}>
                    {l.action} — {l.entity}
                    {l.entityId ? ' #' + l.entityId : ''}
                    {l.detail ? ' (' + l.detail + ')' : ''}
                  </span>
                  <br />
                  <small style={{ color: '#aaa' }}>{date(l.createdAt)}</small>
                </div>
              ))
            )}
          </div>
        </Card>

        <Card title="Ma trận phân quyền chi tiết theo module">
          <p style={{ color: '#5f6368', fontSize: '14px', marginBottom: '16px' }}>
            Nhấp trực tiếp để tích chọn hoặc bỏ chọn từng quyền cụ thể của tài khoản
          </p>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Module Hệ Thống</th>
                  <th style={{ textAlign: 'center' }}>Xem</th>
                  <th style={{ textAlign: 'center' }}>Thêm</th>
                  <th style={{ textAlign: 'center' }}>Sửa</th>
                  <th style={{ textAlign: 'center' }}>Duyệt</th>
                  <th style={{ textAlign: 'center' }}>Xóa</th>
                </tr>
              </thead>
              <tbody>
                {MODULES.map((m) => (
                  <tr key={m.mod}>
                    <td>
                      <b>{m.mod}</b>
                    </td>
                    {modulePerms[m.mod].map((checked, i) => (
                      <td key={i} style={{ textAlign: 'center' }}>
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() => toggleModulePerm(m.mod, i)}
                          style={{
                            width: '16px',
                            height: '16px',
                            cursor: 'pointer',
                            accentColor: '#116a4e',
                          }}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <b style={{ display: 'block', margin: '20px 0 12px' }}>Quyền nghiệp vụ nhanh</b>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            {PERMS_DEF.map((p) => (
              <label
                key={p.key}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '10px 14px',
                  border: '1px solid ' + (perms[p.key] ? '#116a4e' : '#e0e0e0'),
                  borderRadius: '8px',
                  cursor: 'pointer',
                  background: perms[p.key] ? '#f0faf5' : '#fff',
                  transition: 'all .15s',
                }}
              >
                <input
                  type="checkbox"
                  checked={perms[p.key]}
                  onChange={() => togglePerm(p.key)}
                  style={{ accentColor: '#116a4e', width: '15px', height: '15px' }}
                />
                <span style={{ fontSize: '13px', fontWeight: '500' }}>{p.label}</span>
              </label>
            ))}
          </div>

          {hasDeletePerm && (
            <div
              style={{
                background: '#fce8e6',
                padding: '16px',
                borderRadius: '8px',
                marginTop: '16px',
                display: 'flex',
                gap: '12px',
              }}
            >
              <ShieldCheck size={24} color="#d93025" />
              <div>
                <b style={{ color: '#d93025', display: 'block' }}>Cảnh báo: Đang cấp quyền Xóa</b>
                <small style={{ color: '#d93025' }}>
                  Tài khoản này đang được cấp quyền Xóa dữ liệu — đây là quyền nhạy cảm cao. Hãy
                  chắc chắn người dùng đủ tin cậy trước khi lưu thay đổi.
                </small>
              </div>
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}
function UserSecurity({ record, onBack, onLocked }) {
  const [tab, setTab] = useState('lock');
  const [lockDuration, setLockDuration] = useState(1);
  const [lockDurationUnit, setLockDurationUnit] = useState('day');
  const [disciplineReason, setDisciplineReason] = useState(
    'Tự ý tăng giá vật tư thay thế cho khách hàng vượt mức 40% mà không qua hệ thống kiểm duyệt.',
  );
  const [otp, setOtp] = useState('');
  const [otpChallenge, setOtpChallenge] = useState(null);
  const otpAction = useAction();
  const isDelete = tab === 'delete';
  const isTemporarilyLocked = record.lockedUntil && new Date(record.lockedUntil) > new Date();
  const requestOtp = () =>
    otpAction.run(async () => {
      const response = await api('/admin/security/otp', { method: 'POST' });
      setOtpChallenge(response.data);
      setOtp('');
    }, 'Mã OTP đã được gửi đến email quản trị viên.');
  const confirmTemporaryLock = () =>
    otpAction.run(
      async () => {
        const response = await api(
          '/users/' + record.id + (isTemporarilyLocked ? '/unlock' : '/temporary-lock'),
          {
            method: 'POST',
            body: isTemporarilyLocked
              ? { challengeId: otpChallenge.challengeId, otp }
              : {
                  duration: Number(lockDuration),
                  unit: lockDurationUnit,
                  reason: disciplineReason,
                  challengeId: otpChallenge.challengeId,
                  otp,
                },
          },
        );
        setOtp('');
        setOtpChallenge(null);
        onLocked(response.data);
      },
      isTemporarilyLocked ? 'Đã hủy khóa tài khoản.' : 'Đã khóa tài khoản tạm thời.',
    );
  return (
    <div className="user-security-page">
      <div
        className="breadcrumb"
        style={{
          display: 'flex',
          gap: '8px',
          alignItems: 'center',
          color: '#5f6368',
          marginBottom: '24px',
        }}
      >
        <span onClick={onBack} style={{ cursor: 'pointer', fontWeight: '500' }}>
          Quản lý tài khoản
        </span>
        <ChevronRight size={16} />
        <b style={{ color: '#202124' }}>Quản trị rủi ro & Khóa/Xóa</b>
      </div>

      <PageHead
        title="Hành động rủi ro & Bảo mật tài khoản"
        text="Quản lý tập trung các tài khoản cần tạm dừng hoạt động hoặc thu hồi vĩnh viễn quyền truy cập"
      />

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
        <Card title="Danh sách tài khoản cần rà soát đặc biệt">
          <div
            style={{
              border: '1px solid #116a4e',
              borderRadius: '8px',
              padding: '16px',
              marginBottom: '12px',
              background: '#f8fdfa',
              display: 'flex',
              justifyContent: 'space-between',
            }}
          >
            <div>
              <b>{record.fullName}</b>{' '}
              <small style={{ color: '#5f6368' }}>{roleNames[record.role]}</small>
              <div style={{ color: '#d93025', fontSize: '13px', margin: '4px 0' }}>
                Lý do: Tự ý tăng giá vật tư thay thế cho khách hàng
              </div>
              <small style={{ color: '#888' }}>Lần cuối: Đăng nhập 2 phút trước</small>
            </div>
            <div style={{ textAlign: 'right' }}>
              <Badge value="Yêu cầu rà soát" />
              <div
                style={{ color: '#1a73e8', fontSize: '13px', marginTop: '16px', cursor: 'pointer' }}
              >
                Đang xử lý →
              </div>
            </div>
          </div>
        </Card>

        <Card
          title={
            'Xử lý kỷ luật tài khoản: ' + record.role + '-' + String(record.id).padStart(4, '0')
          }
        >
          <p style={{ color: '#5f6368', marginBottom: '16px', fontSize: '14px' }}>
            Áp dụng cho: {record.fullName}
          </p>

          <div
            style={{
              display: 'flex',
              background: '#f1f3f4',
              borderRadius: '8px',
              padding: '4px',
              marginBottom: '24px',
            }}
          >
            <div
              onClick={() => setTab('lock')}
              style={{
                flex: 1,
                textAlign: 'center',
                padding: '8px',
                borderRadius: '6px',
                fontWeight: '500',
                cursor: 'pointer',
                transition: 'all .15s',
                background: !isDelete ? '#fff' : 'transparent',
                color: !isDelete ? '#202124' : '#5f6368',
                boxShadow: !isDelete ? '0 1px 2px rgba(0,0,0,0.1)' : 'none',
              }}
            >
              Khóa tài khoản tạm thời
            </div>
            <div
              onClick={() => setTab('delete')}
              style={{
                flex: 1,
                textAlign: 'center',
                padding: '8px',
                borderRadius: '6px',
                fontWeight: '500',
                cursor: 'pointer',
                transition: 'all .15s',
                background: isDelete ? '#fff' : 'transparent',
                color: isDelete ? '#d93025' : '#5f6368',
                boxShadow: isDelete ? '0 1px 2px rgba(0,0,0,0.1)' : 'none',
              }}
            >
              Xóa vĩnh viễn dữ liệu
            </div>
          </div>

          {isDelete && (
            <div
              style={{
                background: '#fce8e6',
                border: '1px solid #f5c6c2',
                borderRadius: '8px',
                padding: '12px 16px',
                marginBottom: '16px',
                display: 'flex',
                gap: '10px',
              }}
            >
              <ShieldCheck size={20} color="#d93025" style={{ flexShrink: 0, marginTop: '2px' }} />
              <div>
                <b style={{ color: '#d93025', display: 'block', marginBottom: '4px' }}>
                  Cảnh báo: Hành động không thể hoàn tác
                </b>
                <small style={{ color: '#c62828' }}>
                  Toàn bộ dữ liệu tài khoản sẽ bị xóa vĩnh viễn khỏi hệ thống. Hãy chắc chắn đã sao
                  lưu đầy đủ trước khi thực hiện.
                </small>
              </div>
            </div>
          )}

          {!isDelete && isTemporarilyLocked && (
            <div className="notice warning">
              Tài khoản đang bị khóa đến {date(record.lockedUntil)}. Nhận và nhập OTP quản trị để
              hủy khóa sớm.
            </div>
          )}

          {!isTemporarilyLocked && (
            <Field label="Lý do áp dụng biện pháp">
              <textarea
                rows={2}
                value={disciplineReason}
                onChange={(event) => setDisciplineReason(event.target.value)}
              />
            </Field>
          )}

          {!isDelete && !isTemporarilyLocked && (
            <div className="form-grid">
              <Field label="Thời hạn khóa">
                <input
                  type="number"
                  min="1"
                  max="365"
                  step="1"
                  value={lockDuration}
                  onChange={(event) => setLockDuration(event.target.value)}
                />
              </Field>
              <Field label="Đơn vị thời hạn khóa">
                <select
                  value={lockDurationUnit}
                  onChange={(event) => setLockDurationUnit(event.target.value)}
                >
                  <option value="day">Ngày</option>
                  <option value="week">Tuần</option>
                  <option value="month">Tháng</option>
                  <option value="year">Năm</option>
                </select>
              </Field>
            </div>
          )}

          <Field label="Chuyển giao công việc & dữ liệu">
            <select>
              <option>Bàn giao cho KTV Lê Anh Tuấn</option>
            </select>
          </Field>
          <small style={{ color: '#5f6368', display: 'block', marginBottom: '24px' }}>
            {isDelete
              ? 'Dữ liệu công việc đang dở dang sẽ được chuyển sang người nhận bàn giao trước khi xóa.'
              : 'Hệ thống sẽ tự động gán lại 4 đơn bảo trì đang dở dang sang KTV nhận bàn giao.'}
          </small>

          <div style={{ border: '1px solid #eee', padding: '16px', borderRadius: '8px' }}>
            <b style={{ display: 'block', marginBottom: '12px' }}>
              Xác nhận OTP Quản trị để thực thi
            </b>
            <ErrorBox error={otpAction.error} />
            <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
              <input
                className="admin-otp-input"
                type="text"
                value={otp}
                onChange={(event) => setOtp(event.target.value.replace(/\D/g, '').slice(0, 6))}
                inputMode="numeric"
                autoComplete="one-time-code"
                placeholder="Nhập OTP"
                aria-label="Mã OTP quản trị"
                style={{
                  width: '120px',
                  letterSpacing: '4px',
                  textAlign: 'center',
                  color: '#d93025',
                  fontWeight: 'bold',
                  fontSize: '18px',
                }}
              />
              <button
                type="button"
                className={'btn ' + (otpChallenge ? 'otp-request-btn' : '')}
                disabled={otpAction.busy}
                onClick={requestOtp}
              >
                {otpAction.busy ? 'Đang gửi…' : otpChallenge ? 'Gửi lại mã' : 'Nhận mã OTP'}
              </button>
            </div>
            <small style={{ color: '#5f6368', display: 'block', marginTop: '10px' }}>
              {otpChallenge
                ? 'Mã đã gửi về email quản trị viên và có hiệu lực trong 5 phút.'
                : 'Nhấn “Nhận mã OTP” để gửi mã xác thực về email quản trị viên.'}
            </small>
            <button
              type="button"
              className="btn primary"
              disabled={isDelete || otpAction.busy || !otpChallenge || otp.length !== 6}
              onClick={confirmTemporaryLock}
              style={{
                background: isTemporarilyLocked ? '#116a4e' : '#d93025',
                width: '100%',
                marginTop: '16px',
                borderColor: isTemporarilyLocked ? '#116a4e' : '#d93025',
              }}
            >
              {isDelete
                ? 'XÁC NHẬN XÓA VĨNH VIỄN TÀI KHOẢN'
                : isTemporarilyLocked
                  ? 'HỦY KHÓA TÀI KHOẢN'
                  : 'XÁC NHẬN KHÓA TÀI KHOẢN NGAY'}
            </button>
          </div>
        </Card>
      </div>
    </div>
  );
}

export function Management() {
  const { toast } = useApp(),
    { section } = useParams();
  if (section === 'orders') return <AdminOrders />;
  if (section === 'users') return <AdminUsers />;
  const path = { services: '/admin/services', settings: '/settings', audit: '/audit-logs' }[
    section
  ];
  const r = useData(path),
    [edit, setEdit] = useState(null);
  const title = {
    services: 'Danh mục dịch vụ',
    settings: 'Cấu hình nghiệp vụ',
    audit: 'Nhật ký hệ thống',
  }[section];
  const refresh = () => {
    r.reload();
    toast('Đã gửi yêu cầu tải lại dữ liệu.');
  };
  return (
    <>
      <PageHead
        eyebrow="QUẢN TRỊ HOMEFIX"
        title={title || 'Quản trị'}
        text={
          section === 'audit'
            ? 'Các thao tác quan trọng được ghi lại để tra cứu.'
            : 'Dữ liệu được lưu trên máy chủ và áp dụng thống nhất cho web/mobile.'
        }
      >
        {['services'].includes(section) && (
          <button className="btn primary" onClick={() => setEdit({})}>
            <Plus size={17} /> Thêm dịch vụ
          </button>
        )}
        <button className="btn" onClick={refresh}>
          <RefreshCw size={16} /> Cập nhật
        </button>
      </PageHead>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          {section === 'services' && (
            <Table
              headers={['Dịch vụ', 'Nhóm', 'Phí kiểm tra / công', 'Hoa hồng', 'Trạng thái', '']}
              rows={r.data}
              render={(s) => (
                <tr key={s.id}>
                  <td>
                    <b>{s.name}</b>
                    <small>{s.description}</small>
                  </td>
                  <td>{groups[s.groupCode]}</td>
                  <td>
                    {money(s.inspectionFee)}
                    <small>{money(s.laborFee)} tiền công</small>
                  </td>
                  <td>{Number(s.commissionRatePercent)}%</td>
                  <td>
                    <span className={'badge ' + (s.isActive ? 'green' : 'red')}>
                      {s.isActive ? 'Đang cung cấp' : 'Đã ẩn'}
                    </span>
                  </td>
                  <td>
                    <button className="btn small" onClick={() => setEdit(s)}>
                      <Pencil size={14} /> Sửa
                    </button>
                  </td>
                </tr>
              )}
            />
          )}
          {section === 'settings' && (
            <Table
              headers={['Tham số', 'Giá trị', 'Thao tác']}
              rows={r.data}
              render={(s) => (
                <tr key={s.key}>
                  <td>
                    <b>{s.label}</b>
                    <small>{s.key}</small>
                  </td>
                  <td>
                    {s.key === 'signatureRequired'
                      ? s.value === 'true'
                        ? 'Bắt buộc'
                        : 'Không bắt buộc'
                      : s.value}
                  </td>
                  <td>
                    <button className="btn small" onClick={() => setEdit(s)}>
                      Điều chỉnh
                    </button>
                  </td>
                </tr>
              )}
            />
          )}
          {section === 'audit' && (
            <Table
              headers={['Thời gian', 'Người thực hiện', 'Thao tác', 'Đối tượng', 'Chi tiết']}
              rows={r.data}
              render={(a) => (
                <tr key={a.id}>
                  <td>{date(a.createdAt)}</td>
                  <td>{a.actorName || 'Hệ thống / trigger'}</td>
                  <td>{a.action}</td>
                  <td>
                    {a.entity} #{a.entityId || '—'}
                  </td>
                  <td>{a.detail || '—'}</td>
                </tr>
              )}
            />
          )}
        </Card>
      )}
      {section === 'settings' && <BankAccounts />}
      {edit && (
        <Editor
          section={section}
          record={edit}
          onClose={() => setEdit(null)}
          onDone={() => {
            setEdit(null);
            r.reload();
          }}
        />
      )}
    </>
  );
}
function Editor({ section, record, onClose, onDone }) {
  const a = useAction();
  const [form, setForm] = useState(
    section === 'users'
      ? {
          fullName: record.fullName || '',
          phone: record.phone || '',
          email: record.email || '',
          role: record.role || 'KH',
          initialPassword: '',
          isActive: record.isActive ?? true,
          skillGroup: 'DienLanh',
          serviceArea: 'TP.HCM',
        }
      : section === 'services'
        ? {
            name: record.name || '',
            groupCode: record.groupCode || 'DienLanh',
            description: record.description || '',
            inspectionFee: String(record.inspectionFee || '50000'),
            laborFee: String(record.laborFee || '300000'),
            commissionRatePercent: String(record.commissionRatePercent || '15'),
            isActive: record.isActive ?? true,
          }
        : { value: record.value },
  );
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));
  const input = (k, label, type = 'text', required = true) => (
    <Field label={label}>
      <input
        type={type}
        required={required}
        value={form[k]}
        onChange={(e) => set(k, e.target.value)}
      />
    </Field>
  );
  return (
    <Modal
      title={
        section === 'settings'
          ? 'Điều chỉnh ' + record.label
          : (record.id ? 'Cập nhật' : 'Thêm') +
            ' ' +
            (section === 'users' ? 'tài khoản' : 'dịch vụ')
      }
      onClose={onClose}
    >
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            let path, body;
            if (section === 'users') {
              path = '/users' + (record.id ? '/' + record.id : '');
              body = record.id
                ? {
                    fullName: form.fullName,
                    role: form.role,
                    skillGroup: form.skillGroup,
                    isActive: form.isActive,
                    expectedVersion: record.version,
                  }
                : {
                    fullName: form.fullName,
                    phone: form.phone,
                    email: form.email || null,
                    role: form.role,
                    initialPassword: form.initialPassword,
                    ...(form.role === 'KTV'
                      ? {
                          technicianProfile: {
                            skillGroup: form.skillGroup,
                            serviceArea: form.serviceArea,
                          },
                        }
                      : {}),
                  };
            } else if (section === 'services') {
              path = '/services' + (record.id ? '/' + record.id : '');
              body = { ...form, ...(record.id ? { expectedVersion: record.version } : {}) };
            } else {
              path = '/settings/' + record.key;
              body = { value: form.value, expectedVersion: record.version };
            }
            await api(path, {
              method: record.id || section === 'settings' ? 'PATCH' : 'POST',
              body,
            });
            onDone();
          });
        }}
      >
        <ErrorBox error={a.error} />
        {section === 'users' && (
          <>
            {input('fullName', 'Họ và tên')}
            {!record.id && (
              <>
                {input('phone', 'Số điện thoại')}
                {input('email', 'Email', 'email', false)}
                <Field label="Vai trò">
                  <select value={form.role} onChange={(e) => set('role', e.target.value)}>
                    {Object.entries(roleNames).map(([k, n]) => (
                      <option key={k} value={k}>
                        {n}
                      </option>
                    ))}
                  </select>
                </Field>
                {input('initialPassword', 'Mật khẩu ban đầu (từ 8 ký tự)', 'password')}
                {form.role === 'KTV' && (
                  <>
                    <Field label="Chuyên môn">
                      <select
                        value={form.skillGroup}
                        onChange={(e) => set('skillGroup', e.target.value)}
                      >
                        {Object.entries(groups).map(([k, n]) => (
                          <option key={k} value={k}>
                            {n}
                          </option>
                        ))}
                      </select>
                    </Field>
                    {input('serviceArea', 'Khu vực phục vụ')}
                  </>
                )}
              </>
            )}
            {record.id && (
              <>
                <p>
                  {record.phone} · {roleNames[record.role]}
                </p>
                <label className="checkbox">
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(e) => set('isActive', e.target.checked)}
                  />{' '}
                  Tài khoản được hoạt động
                </label>
                <small>Khóa tài khoản sẽ thu hồi các phiên đăng nhập.</small>
              </>
            )}
          </>
        )}
        {section === 'services' && (
          <>
            {input('name', 'Tên dịch vụ')}
            <Field label="Nhóm dịch vụ">
              <select value={form.groupCode} onChange={(e) => set('groupCode', e.target.value)}>
                {Object.entries(groups).map(([k, n]) => (
                  <option key={k} value={k}>
                    {n}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Mô tả">
              <textarea
                required
                minLength={5}
                value={form.description}
                onChange={(e) => set('description', e.target.value)}
              />
            </Field>
            <div className="form-grid">
              {input('inspectionFee', 'Phí kiểm tra (đ)', 'number')}
              {input('laborFee', 'Tiền công (đ)', 'number')}
              {input('commissionRatePercent', 'Hoa hồng trên tiền công (%)', 'number')}
            </div>
            <label className="checkbox">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) => set('isActive', e.target.checked)}
              />{' '}
              Dịch vụ đang được cung cấp
            </label>
            <small>
              Giá mới áp dụng cho báo giá lập sau khi lưu. Không sửa chi phí đã được khách duyệt.
            </small>
          </>
        )}
        {section === 'settings' &&
          (record.key === 'signatureRequired' ? (
            <Field label="Yêu cầu chữ ký">
              <select value={form.value} onChange={(e) => set('value', e.target.value)}>
                <option value="false">Không bắt buộc</option>
                <option value="true">Bắt buộc ảnh chữ ký KH</option>
              </select>
            </Field>
          ) : (
            input('value', 'Giá trị mới', 'number')
          ))}
        <div className="form-actions">
          <button className="btn" type="button" onClick={onClose}>
            Hủy
          </button>
          <Submit busy={a.busy} />
        </div>
      </form>
    </Modal>
  );
}
export function Finance() {
  const requestedTab = new URLSearchParams(useLocation().search).get('tab'),
    tab = ['revenue', 'bank', 'wallet'].includes(requestedTab) ? requestedTab : 'revenue',
    [selected, setSelected] = useState(null),
    exportAction = useAction();
  const settlements = useData(tab === 'revenue' || tab === 'wallet' ? '/settlements' : null, 15000),
    walletRequests = useData(tab === 'wallet' ? '/wallet-requests' : null, 15000);
  const reload = () => {
    settlements.reload();
    walletRequests.reload();
  };
  const download = () =>
    exportAction.run(async () => {
      const blob = await api('/reports/finance.csv', { blob: true }),
        url = URL.createObjectURL(blob),
        link = document.createElement('a');
      link.href = url;
      link.download = 'HomeFix_DoiSoatDoanhThu.csv';
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }, 'Đã tải báo cáo đối soát.');
  if (tab === 'revenue')
    return (
      <RevenueReconciliation
        rows={settlements.data || []}
        loading={settlements.loading}
        error={settlements.error || exportAction.error}
        busy={exportAction.busy}
        onDownload={download}
      />
    );
  if (tab === 'bank')
    return (
      <>
        <PageHead
          eyebrow="TÀI CHÍNH HOMEFIX"
          title="Giao dịch chuyển khoản"
          text="Kiểm tra chứng từ và xác minh các khoản thanh toán chuyển khoản trước khi ghi nhận."
        />
        <BankPaymentQueue />
      </>
    );
  return (
    <>
      <PageHead
        eyebrow="TÀI CHÍNH HOMEFIX"
        title="Duyệt Ví KTV"
        text="Xử lý đối soát và các yêu cầu nạp, rút ví của kỹ thuật viên. Các thao tác ghi sổ được thực hiện tại đây."
      />
      <ErrorBox error={settlements.error || walletRequests.error} />
      <Card title="Đối soát thu hộ & khấu trừ hoa hồng">
        <Table
          headers={[
            'Đơn dịch vụ',
            'Kỹ thuật viên',
            'Khoản đã thu',
            'Hoa hồng',
            'Trạng thái',
            'Thao tác',
          ]}
          rows={settlements.data}
          render={(s) => (
            <tr key={s.id}>
              <td>
                <Link to={'/orders/' + s.orderId}>{code(s.orderId)}</Link>
                <small>{date(s.paidAt)}</small>
              </td>
              <td>{s.technicianName}</td>
              <td>
                {money(s.amount)}
                <small>
                  {s.method === 'BANK' ? 'HomeFix nhận chuyển khoản' : 'KTV nhận tiền mặt'}
                </small>
              </td>
              <td>
                <b>{money(s.commissionAmount)}</b>
                <small>{Number(s.commissionRatePercent)}% tiền công</small>
              </td>
              <td>
                <Badge value={s.status} />
              </td>
              <td>
                {s.status === 'Pending' && (
                  <button
                    className="btn small primary"
                    onClick={() => setSelected({ type: 'settlement', row: s })}
                  >
                    Đối soát
                  </button>
                )}
              </td>
            </tr>
          )}
        />
      </Card>
      <Card title="Yêu cầu nạp / rút ví">
        <Table
          headers={['Yêu cầu', 'Kỹ thuật viên', 'Số tiền', 'Trạng thái', 'Thao tác']}
          rows={walletRequests.data}
          render={(w) => (
            <tr key={w.id}>
              <td>
                <b>{w.type === 'Deposit' ? 'Nạp ví' : 'Rút tiền'}</b>
                <small>{date(w.createdAt)}</small>
              </td>
              <td>
                {w.technicianName}
                <small>{w.note}</small>
              </td>
              <td>{money(w.amount)}</td>
              <td>
                <Badge value={w.status} />
              </td>
              <td>
                <button
                  className="btn small"
                  onClick={() => setSelected({ type: 'wallet', row: w })}
                >
                  {w.status === 'Pending' ? 'Xem & xử lý' : 'Xem chi tiết'}
                </button>
              </td>
            </tr>
          )}
        />
      </Card>
      {selected && (
        <FinanceDecision
          {...selected}
          onClose={() => setSelected(null)}
          onDone={() => {
            setSelected(null);
            reload();
          }}
        />
      )}
    </>
  );
}
function RevenueReconciliation({ rows = [], loading, error, busy, onDownload }) {
  const [query, setQuery] = useState(''),
    [status, setStatus] = useState('Pending');
  const needle = query.trim().toLocaleLowerCase('vi');
  const filtered = rows.filter(
    (row) =>
      (status === 'All' || row.status === status) &&
      (!needle ||
        [code(row.orderId), row.technicianName, 'KTV-' + row.technicianId].some((value) =>
          String(value || '')
            .toLocaleLowerCase('vi')
            .includes(needle),
        )),
  );
  const codTotal = rows
      .filter((row) => row.method === 'COD')
      .reduce((sum, row) => sum + Number(row.amount || 0), 0),
    commissionTotal = rows.reduce((sum, row) => sum + Number(row.commissionAmount || 0), 0),
    pending = rows.filter((row) => row.status === 'Pending').length,
    displayedTotal = filtered.reduce((sum, row) => sum + Number(row.amount || 0), 0),
    displayedMaterials = filtered.reduce((sum, row) => sum + Number(row.materialTotal || 0), 0),
    displayedLabor = filtered.reduce((sum, row) => sum + Number(row.laborFee || 0), 0),
    displayedCommission = filtered.reduce((sum, row) => sum + Number(row.commissionAmount || 0), 0);
  return (
    <div className="reconciliation-page">
      <div className="reconciliation-heading">
        <div>
          <div className="breadcrumb-text">
            HomeFix <span>›</span> Đối soát doanh thu
          </div>
          <h1>Đối soát doanh thu, chiết khấu & tiền mặt COD</h1>
          <p>Khấu trừ tiền ví kỹ thuật viên và kiểm tra số tiền mặt thu hộ khách hàng.</p>
        </div>
        <div className="reconciliation-actions">
          <button className="btn" disabled={busy} onClick={onDownload}>
            <Download size={17} /> Xuất báo cáo
          </button>
          <Link className="btn primary" to="/finance?tab=wallet">
            <Wallet size={17} /> Xác nhận đối soát
          </Link>
        </div>
      </div>
      <ErrorBox error={error} />
      <section className="reconciliation-kpis">
        <ReconciliationKpi
          label="Tổng tiền mặt KTV thu COD"
          value={money(codTotal)}
          icon={<Wallet size={24} />}
          tone="green"
        />
        <ReconciliationKpi
          label="Tổng phí chiết khấu thu hồi"
          value={money(commissionTotal)}
          icon={<ShieldCheck size={24} />}
          tone="blue"
        />
        <ReconciliationKpi
          label="Số đơn chưa đối soát"
          value={`${pending} đơn hàng`}
          icon={<CheckCircle2 size={24} />}
          tone="red"
        />
      </section>
      <section className="reconciliation-filter">
        <label>
          Trạng thái:
          <select value={status} onChange={(event) => setStatus(event.target.value)}>
            <option value="Pending">Chưa đối soát</option>
            <option value="Confirmed">Đã khấu trừ</option>
            <option value="All">Tất cả</option>
          </select>
        </label>
        <div>
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Lọc theo mã thợ, tên kỹ thuật viên hoặc mã đơn hàng..."
          />
        </div>
      </section>
      {loading ? (
        <Loading />
      ) : (
        <div className="reconciliation-table table-wrap">
          <table>
            <thead>
              <tr>
                <th>Mã đơn hàng</th>
                <th>Mã KTV</th>
                <th>Tên KTV</th>
                <th>Tổng tiền khách trả</th>
                <th>Tiền vật tư</th>
                <th>Phí nhân công</th>
                <th>% Chiết khấu</th>
                <th>Số tiền trừ ví</th>
                <th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length ? (
                filtered.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <Link to={'/orders/' + row.orderId}>{code(row.orderId)}</Link>
                    </td>
                    <td>KTV-{row.technicianId}</td>
                    <td>
                      <b>{row.technicianName}</b>
                    </td>
                    <td>{money(row.amount)}</td>
                    <td>{money(row.materialTotal)}</td>
                    <td>{money(row.laborFee)}</td>
                    <td>{Number(row.commissionRatePercent || 0)}%</td>
                    <td>
                      <b>{money(row.commissionAmount)}</b>
                    </td>
                    <td>
                      <span
                        className={
                          'reconciliation-status ' +
                          (row.status === 'Confirmed' ? 'confirmed' : 'pending')
                        }
                      >
                        {row.status === 'Confirmed' ? 'Đã khấu trừ' : 'Chưa trừ'}
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="9" className="reconciliation-empty">
                    Chưa có đơn phù hợp với bộ lọc.
                  </td>
                </tr>
              )}
            </tbody>
            {filtered.length > 0 && (
              <tfoot>
                <tr>
                  <td colSpan="3">Tổng kết dòng đơn hiển thị</td>
                  <td>{money(displayedTotal)}</td>
                  <td>{money(displayedMaterials)}</td>
                  <td>{money(displayedLabor)}</td>
                  <td>—</td>
                  <td>{money(displayedCommission)}</td>
                  <td>—</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}
    </div>
  );
}
function ReconciliationKpi({ label, value, icon, tone }) {
  return (
    <article className={'reconciliation-kpi ' + tone}>
      <span>{icon}</span>
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
      </div>
    </article>
  );
}
function FinanceDecision({ type, row, onClose, onDone }) {
  const a = useAction(),
    requestKey = useRef(uuid()),
    [decision, setDecision] = useState('Approved'),
    [reason, setReason] = useState('');
  return (
    <Modal
      title={type === 'settlement' ? 'Xác nhận đối soát thanh toán' : 'Xử lý yêu cầu ví'}
      onClose={onClose}
    >
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            await api(
              type === 'settlement'
                ? `/settlements/${row.id}/confirm`
                : `/wallet-requests/${row.id}/decision`,
              {
                method: 'POST',
                body:
                  type === 'settlement'
                    ? { expectedVersion: row.version }
                    : { decision, expectedVersion: row.version, ...(reason ? { reason } : {}) },
                key: requestKey.current,
              },
            );
            onDone();
          });
        }}
      >
        <p>
          <b>{row.technicianName}</b>
        </p>
        <div className="confirmation-amount">
          {money(
            type === 'settlement'
              ? row.method === 'BANK'
                ? row.technicianCredit
                : row.commissionAmount
              : row.amount,
          )}
        </div>
        {type === 'settlement' ? (
          <p>
            {row.method === 'BANK'
              ? 'HomeFix đã nhận chuyển khoản. Số tiền trên là phần thuộc KTV sau hoa hồng, gồm phí kiểm tra và vật tư; hệ thống cộng vào ví đúng một lần. KTV có thể yêu cầu rút tiền sau đó.'
              : 'KTV đã nhận tiền mặt trực tiếp. Hệ thống chỉ trừ hoa hồng từ ví đúng một lần, không cộng tiền mặt vào ví.'}
          </p>
        ) : (
          <>
            <p>{row.note}</p>
            <Badge value={row.status} />
            {row.proofId && (
              <div className="image-grid">
                <ProtectedImage id={row.proofId} alt="Chứng từ yêu cầu ví" />
              </div>
            )}
            {row.status === 'Pending' && (
              <>
                <Field label="Kết quả xét duyệt">
                  <select value={decision} onChange={(e) => setDecision(e.target.value)}>
                    <option value="Approved">Đồng ý và ghi sổ</option>
                    <option value="Rejected">Từ chối</option>
                  </select>
                </Field>
                <Field label="Lý do / ghi chú">
                  <textarea
                    required={decision === 'Rejected'}
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                  />
                </Field>
                <small>
                  Đây là xét duyệt thủ công. Chỉ đồng ý khi đã kiểm tra chứng từ / việc chi tiền
                  thực tế.
                </small>
              </>
            )}
          </>
        )}
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <button className="btn" type="button" onClick={onClose}>
            Đóng
          </button>
          {(type === 'settlement' || row.status === 'Pending') && (
            <Submit busy={a.busy}>Xác nhận xử lý</Submit>
          )}
        </div>
      </form>
    </Modal>
  );
}
export function WalletPage() {
  const location = useLocation(),
    [revision, setRevision] = useState(0);
  const wallet = useData('/technicians/me/wallet'),
    income = useData('/technicians/me/income'),
    requests = useData('/wallet-requests'),
    a = useAction();
  const [type, setType] = useState(
    new URLSearchParams(location.search).get('request') === 'Deposit' ? 'Deposit' : null,
  );
  const refresh = () => {
    wallet.reload();
    income.reload();
    requests.reload();
    setRevision((v) => v + 1);
  };
  return (
    <>
      <PageHead
        eyebrow="VÍ KỸ THUẬT VIÊN"
        title="Ví & thu nhập"
        text="Tiền chuyển khoản được cộng vào ví sau đối soát và trừ hoa hồng; tiền mặt đã nhận chỉ trừ hoa hồng."
      >
        <button className="btn" onClick={refresh}>
          <RefreshCw size={16} /> Cập nhật
        </button>
      </PageHead>
      <ErrorBox error={wallet.error || requests.error || a.error} />
      <section className="wallet-hero">
        <span>Số dư ví hiện tại</span>
        <strong>{money(wallet.data?.balance)}</strong>
        <div className="actions">
          <button className="btn white" onClick={() => setType('Deposit')}>
            <Plus size={17} /> Nạp ví
          </button>
          <button className="btn glass" onClick={() => setType('Withdrawal')}>
            <ArrowUpFromLine size={17} /> Yêu cầu rút
          </button>
        </div>
      </section>
      <div className="stat-grid three">
        <Stat
          label="Thu nhập trước chi phí khác"
          value={money(income.data?.income)}
          icon={Wallet}
        />
        <Stat
          label="Hoàn chi vật tư"
          value={money(income.data?.materialReimbursement)}
          icon={ShieldCheck}
        />
        <Stat label="Đơn đã thu tiền" value={income.data?.completedOrders || 0} />
      </div>
      <Card title="Yêu cầu nạp / rút">
        <Table
          headers={['Loại yêu cầu', 'Số tiền', 'Thời gian', 'Trạng thái', '']}
          rows={requests.data}
          render={(r) => (
            <tr key={r.id}>
              <td>
                {r.type === 'Deposit' ? 'Nạp ví' : 'Rút tiền'}
                <small>{r.note}</small>
              </td>
              <td>{money(r.amount)}</td>
              <td>{date(r.createdAt)}</td>
              <td>
                <Badge value={r.status} />
                {r.reason && <small>{r.reason}</small>}
              </td>
              <td>
                {r.status === 'Pending' && (
                  <button
                    className="btn small danger"
                    disabled={a.busy}
                    onClick={() =>
                      a.run(async () => {
                        await api(`/wallet-requests/${r.id}/cancel`, {
                          method: 'POST',
                          body: { expectedVersion: r.version },
                        });
                        refresh();
                      })
                    }
                  >
                    Hủy yêu cầu
                  </button>
                )}
              </td>
            </tr>
          )}
        />
      </Card>
      <WalletHistory revision={revision} />
      {type && (
        <WalletRequest
          key={type}
          type={type}
          balance={wallet.data?.balance}
          onTypeChange={setType}
          onClose={() => setType(null)}
          onDone={() => {
            setType(null);
            refresh();
          }}
        />
      )}
    </>
  );
}
function WalletRequest({ type, balance, onTypeChange, onClose, onDone }) {
  const a = useAction(),
    [amount, setAmount] = useState(''),
    [note, setNote] = useState(''),
    [bank, setBank] = useState({ name: '', account: '', holder: '' }),
    [file, setFile] = useState(null),
    proof = useRef(null),
    requestKey = useRef(uuid());
  return (
    <Modal title={type === 'Deposit' ? 'Yêu cầu nạp ví' : 'Yêu cầu rút tiền'} onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            if (type === 'Withdrawal' && Number(amount) > Number(balance))
              throw new Error('Số tiền rút vượt số dư ví.');
            if (file && !proof.current) proof.current = (await upload(file, 'WalletProof')).id;
            await api('/wallet-requests', {
              method: 'POST',
              body: {
                type,
                amount,
                note:
                  type === 'Withdrawal'
                    ? `${bank.name} · STK ${bank.account} · ${bank.holder}. ${note}`
                    : note,
                ...(proof.current ? { proofId: proof.current } : {}),
              },
              key: requestKey.current,
            });
            onDone();
          });
        }}
      >
        <div className="segmented-control">
          {[
            ['Deposit', 'Nạp tiền'],
            ['Withdrawal', 'Rút tiền'],
          ].map(([key, name]) => (
            <button
              key={key}
              type="button"
              disabled={a.busy}
              className={'btn ' + (type === key ? 'primary' : '')}
              onClick={() => onTypeChange(key)}
            >
              {name}
            </button>
          ))}
        </div>
        <div className="notice info">
          Yêu cầu được kế toán xét duyệt. Số dư chỉ thay đổi sau khi duyệt; chưa hỗ trợ chuyển tiền
          tức thì.
        </div>
        <Field label="Số tiền (đ)">
          <input
            required
            min="1"
            max={type === 'Withdrawal' ? Math.min(Number(balance || 0), 100000000) : 100000000}
            step="1"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </Field>
        <div className="quick-amounts">
          {[500000, 1000000, 2500000].map((v) => (
            <button
              key={v}
              className="btn"
              type="button"
              disabled={type === 'Withdrawal' && v > Number(balance)}
              onClick={() => setAmount(String(v))}
            >
              {money(v)}
            </button>
          ))}
          {type === 'Withdrawal' && (
            <button
              type="button"
              className="btn"
              onClick={() => setAmount(String(Math.min(Number(balance || 0), 100000000)))}
            >
              Tất cả
            </button>
          )}
        </div>
        {type === 'Withdrawal' && (
          <>
            <p>
              Số dư hiện tại: <b>{money(balance)}</b>
            </p>
            <Field label="Ngân hàng nhận tiền">
              <input
                required
                maxLength={100}
                value={bank.name}
                onChange={(e) => setBank({ ...bank, name: e.target.value })}
              />
            </Field>
            <Field label="Số tài khoản nhận tiền">
              <input
                required
                inputMode="numeric"
                pattern="[0-9]{6,30}"
                value={bank.account}
                onChange={(e) => setBank({ ...bank, account: e.target.value })}
              />
            </Field>
            <Field label="Chủ tài khoản">
              <input
                required
                maxLength={100}
                value={bank.holder}
                onChange={(e) => setBank({ ...bank, holder: e.target.value })}
              />
            </Field>
          </>
        )}
        <Field label={type === 'Withdrawal' ? 'Ghi chú rút tiền' : 'Nội dung nạp ví'}>
          <textarea
            required={type === 'Deposit'}
            minLength={type === 'Deposit' ? 5 : 0}
            maxLength={600}
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </Field>
        {type === 'Deposit' && (
          <Field label="Ảnh chứng từ">
            <input
              required
              type="file"
              accept="image/png,image/jpeg"
              onChange={(e) => {
                setFile(e.target.files[0]);
                proof.current = null;
              }}
            />
          </Field>
        )}
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <button className="btn" type="button" disabled={a.busy} onClick={onClose}>
            Quay lại
          </button>
          <Submit busy={a.busy}>Gửi yêu cầu</Submit>
        </div>
      </form>
    </Modal>
  );
}
export function Support() {
  const { user } = useApp(),
    r = useData('/support/tickets', 15000);
  const [selected, setSelected] = useState(null);
  return (
    <>
      <PageHead
        eyebrow="CHĂM SÓC KHÁCH HÀNG"
        title={user.role === 'KH' ? 'Yêu cầu hỗ trợ của tôi' : 'Tiếp nhận & xử lý hỗ trợ'}
        text={
          user.role === 'KH'
            ? 'Mở đơn dịch vụ và chọn “Gửi yêu cầu hỗ trợ” để tạo phiếu.'
            : 'Kiểm tra lịch sử đơn trước khi cập nhật hướng xử lý.'
        }
      >
        {user.role === 'KH' && (
          <Link className="btn primary" to="/orders">
            Chọn đơn cần hỗ trợ
          </Link>
        )}
      </PageHead>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : (
        <Card>
          <Table
            headers={['Phiếu', 'Nội dung', 'Trạng thái', 'Cập nhật', '']}
            rows={r.data}
            render={(t) => (
              <tr key={t.id}>
                <td>
                  <b>HT-{t.id}</b>
                  <small>{t.type === 'Warranty' ? 'Bảo hành' : 'Khiếu nại / hỗ trợ'}</small>
                  <Link to={'/orders/' + t.orderId}>{code(t.orderId)}</Link>
                </td>
                <td>
                  <b>{t.customerName}</b>
                  <small>{t.description}</small>
                </td>
                <td>
                  <Badge value={t.status} />
                </td>
                <td>{date(t.updatedAt)}</td>
                <td>
                  <button className="btn small" onClick={() => setSelected(t.id)}>
                    Chi tiết
                  </button>
                </td>
              </tr>
            )}
          />
        </Card>
      )}
      {selected && (
        <Ticket
          id={selected}
          onClose={() => setSelected(null)}
          onDone={() => {
            setSelected(null);
            r.reload();
          }}
        />
      )}
    </>
  );
}
function Ticket({ id, onClose, onDone }) {
  const { user } = useApp(),
    r = useData('/support/tickets/' + id),
    a = useAction(),
    [status, setStatus] = useState('InProgress'),
    [resolution, setResolution] = useState('');
  return (
    <Modal title={'Yêu cầu HT-' + id} onClose={onClose}>
      <ErrorBox error={r.error || a.error} />
      {r.data && (
        <>
          <p className="pre-wrap">{r.data.description}</p>
          <Badge value={r.data.status} />
          <div className="timeline">
            {r.data.history.map((h) => (
              <div key={h.id}>
                <span />
                <section>
                  <b>{labels[h.status]}</b>
                  <p>{h.note}</p>
                  <small>
                    {h.actorName} · {date(h.createdAt)}
                  </small>
                </section>
              </div>
            ))}
          </div>
          {user.role === 'CSKH' && ['Open', 'InProgress'].includes(r.data.status) && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                a.run(async () => {
                  await api('/support/tickets/' + id, {
                    method: 'PATCH',
                    body: { status, resolution, expectedVersion: r.data.version },
                  });
                  onDone();
                });
              }}
            >
              <Field label="Trạng thái xử lý">
                <select value={status} onChange={(e) => setStatus(e.target.value)}>
                  <option value="InProgress">Đang xử lý</option>
                  <option value="Resolved">Đã giải quyết</option>
                  <option value="Rejected">Từ chối có lý do</option>
                </select>
              </Field>
              <Field label="Kết quả / hướng xử lý">
                <textarea
                  required
                  minLength={5}
                  value={resolution}
                  onChange={(e) => setResolution(e.target.value)}
                />
              </Field>
              <Submit busy={a.busy}>Cập nhật phiếu</Submit>
            </form>
          )}
        </>
      )}
    </Modal>
  );
}
export function Applications() {
  const { user } = useApp(),
    r = useData(user.role === 'ADMIN' ? '/technician-applications' : '/technician-applications/me'),
    a = useAction();
  const [selected, setSelected] = useState(null);
  return (
    <>
      <PageHead
        eyebrow="ĐỘI NGŨ HOMEFIX"
        title={
          user.role === 'ADMIN' ? 'Xét duyệt hồ sơ kỹ thuật viên' : 'Đăng ký cộng tác kỹ thuật viên'
        }
        text="Hồ sơ được quản trị viên kiểm tra trước khi cấp quyền nhận việc."
      />
      <ErrorBox error={r.error || a.error} />
      {user.role === 'KH' && !r.data?.some((x) => x.status === 'Pending') && (
        <ApplicationWizard onDone={r.reload} />
      )}
      <Card title="Hồ sơ đã gửi">
        <Table
          headers={['Người nộp', 'Chuyên môn', 'Kinh nghiệm', 'Trạng thái', '']}
          rows={r.data}
          render={(h) => (
            <tr key={h.id}>
              <td>
                {h.fullName || user.fullName}
                <small>{date(h.createdAt)}</small>
              </td>
              <td>
                {groups[h.skillGroup]}
                <small>{h.serviceArea}</small>
              </td>
              <td>{h.experience}</td>
              <td>
                <Badge value={h.status} />
                <small>{h.reason}</small>
              </td>
              <td>
                {user.role === 'ADMIN' && h.status === 'Pending' && (
                  <button className="btn small" onClick={() => setSelected(h)}>
                    Xét duyệt
                  </button>
                )}
              </td>
            </tr>
          )}
        />
      </Card>
      {selected && (
        <ApplicationDecision
          record={selected}
          onClose={() => setSelected(null)}
          onDone={() => {
            setSelected(null);
            r.reload();
          }}
        />
      )}
    </>
  );
}
function ApplicationDecision({ record, onClose, onDone }) {
  const a = useAction(),
    [decision, setDecision] = useState('Approved'),
    [reason, setReason] = useState('');
  return (
    <Modal title={'Xét hồ sơ ' + record.fullName} onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          a.run(async () => {
            await api('/technician-applications/' + record.id + '/decision', {
              method: 'POST',
              body: { decision, expectedVersion: record.version, ...(reason ? { reason } : {}) },
            });
            onDone();
          });
        }}
      >
        <p>{record.experience}</p>
        {record.profileJson && <ApplicationProfile json={record.profileJson} />}
        {(record.frontDocumentId || record.backDocumentId) && (
          <div className="image-grid">
            {record.frontDocumentId && (
              <ProtectedImage id={record.frontDocumentId} alt="CCCD mặt trước" />
            )}
            {record.backDocumentId && (
              <ProtectedImage id={record.backDocumentId} alt="CCCD mặt sau" />
            )}
          </div>
        )}
        <Field label="Kết quả">
          <select value={decision} onChange={(e) => setDecision(e.target.value)}>
            <option value="Approved">Duyệt thành kỹ thuật viên</option>
            <option value="Rejected">Từ chối</option>
          </select>
        </Field>
        <Field label="Lý do">
          <textarea
            required={decision === 'Rejected'}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
        </Field>
        <small>
          Chỉ duyệt khi người nộp không còn đơn khách hàng đang mở. Người được duyệt cần đăng nhập
          lại và nạp ví trước khi nhận việc.
        </small>
        <ErrorBox error={a.error} />
        <div className="form-actions">
          <Submit busy={a.busy}>Xác nhận kết quả</Submit>
        </div>
      </form>
    </Modal>
  );
}
export function Reports() {
  return <ReportWorkspace finance={<FinancialReport />} />;
}
function FinancialReport() {
  const { user } = useApp();
  const [range, setRange] = useState({ from: '', to: '' }),
    [query, setQuery] = useState(''),
    [rangeError, setRangeError] = useState(null);
  const cashflow = useReportData('/reports/cashflow' + query),
    settings = useReportData(user.role === 'GD' ? '/reports/monitoring' : null);
  const summary = useReportData('/reports/summary' + query),
    techs = useReportData('/reports/technicians'),
    finance = useReportData(['GD', 'KT'].includes(user.role) ? '/reports/finance' + query : null),
    a = useAction();
  async function download() {
    await a.run(async () => {
      const blob = await api('/reports/finance.csv' + query, { blob: true });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'HomeFix_BaoCaoThu.csv';
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }, 'Đã tải báo cáo CSV.');
  }
  const d = summary.data;
  return (
    <>
      <PageHead
        eyebrow="SỐ LIỆU HOẠT ĐỘNG"
        title="Dòng tiền, doanh thu & lợi nhuận"
        text="Giá trị đơn đã thu và hoa hồng đã đối soát là hai chỉ số riêng. Chưa bao gồm chi phí vận hành."
      >
        <button
          className="btn"
          disabled={cashflow.loading || !!cashflow.error}
          onClick={() =>
            csvDownload('HomeFix_DongTien.csv', [
              ['Từ thời điểm', new URLSearchParams(query).get('from') || 'Toàn bộ'],
              ['Đến trước thời điểm', new URLSearchParams(query).get('to') || 'Hiện tại'],
              ['Ngày', 'Tiền vào', 'Tiền ra', 'Chênh lệch'],
              ...(cashflow.data || []).map((r) => [
                r.day,
                r.incoming,
                r.outgoing,
                Number(r.incoming) - Number(r.outgoing),
              ]),
            ])
          }
        >
          Xuất dòng tiền
        </button>
        <button
          className="btn"
          onClick={() =>
            document.getElementById('finance-details')?.scrollIntoView({ behavior: 'smooth' })
          }
        >
          Xem chi tiết
        </button>
        {user.role !== 'DPV' && (
          <button
            className="btn primary"
            disabled={a.busy || finance.loading || !!finance.error}
            onClick={download}
          >
            <Download size={17} /> Xuất CSV
          </button>
        )}
      </PageHead>
      <form
        className="filter-bar"
        onSubmit={(e) => {
          e.preventDefault();
          if (range.from && range.to && range.from > range.to) {
            setRangeError(new Error('Ngày kết thúc phải bằng hoặc sau ngày bắt đầu.'));
            return;
          }
          setRangeError(null);
          const p = new URLSearchParams();
          if (range.from) p.set('from', new Date(range.from + 'T00:00:00+07:00').toISOString());
          if (range.to) {
            const end = new Date(new Date(range.to + 'T00:00:00+07:00').getTime() + 86400000);
            p.set('to', end.toISOString());
          }
          setQuery(p.size ? '?' + p : '');
        }}
      >
        <Field label="Từ ngày">
          <input
            type="date"
            value={range.from}
            onChange={(e) => setRange({ ...range, from: e.target.value })}
          />
        </Field>
        <Field label="Đến hết ngày">
          <input
            type="date"
            value={range.to}
            onChange={(e) => setRange({ ...range, to: e.target.value })}
          />
        </Field>
        <button className="btn" type="submit">
          Áp dụng
        </button>
        <button
          className="btn"
          type="button"
          onClick={() => {
            setRange({ from: '', to: '' });
            setQuery('');
            setRangeError(null);
          }}
        >
          Toàn bộ thời gian
        </button>
      </form>
      <ErrorBox
        error={
          rangeError ||
          summary.error ||
          finance.error ||
          cashflow.error ||
          settings.error ||
          a.error
        }
      />
      {d && (
        <>
          <div className="stat-grid">
            <Stat label="Đơn được tạo trong kỳ" value={d.totalOrders} />
            <Stat label="Giá trị đơn đã thu" value={money(d.gmv)} icon={Wallet} />
            <Stat
              label="Hoa hồng đã đối soát"
              value={money(d.commissionRevenue)}
              icon={ShieldCheck}
            />
            <Stat
              label="Đánh giá trung bình"
              value={d.averageRating ? Number(d.averageRating).toFixed(1) + '/5' : 'Chưa có'}
              icon={Star}
            />
          </div>
          <div className="two-column report-columns">
            <div>
              <Card title="Dòng tiền vào / ra">
                <CashflowChart rows={cashflow.data} />
                <p className="report-note">
                  Tiền vào: thanh toán ngân hàng đã xác minh và nạp ví được duyệt. Tiền ra: rút ví
                  đã duyệt. Tiền mặt KTV thu và bút toán đối soát nội bộ không tính vào biểu đồ này.
                </p>
              </Card>
              {settings.data?.showCashflow !== false && (
                <Card title="Chi tiết dòng tiền">
                  <Table
                    headers={['Ngày', 'Tiền vào', 'Tiền ra', 'Chênh lệch']}
                    rows={cashflow.data}
                    render={(r) => (
                      <tr key={r.day}>
                        <td>{r.day}</td>
                        <td className="text-green">{money(r.incoming)}</td>
                        <td className="text-red">{money(r.outgoing)}</td>
                        <td>{money(Number(r.incoming) - Number(r.outgoing))}</td>
                      </tr>
                    )}
                  />
                </Card>
              )}
            </div>
            <aside>
              <ReportOverview
                items={[
                  ['Giá trị đơn đã thu', money(d.gmv)],
                  ['Hoa hồng đã đối soát', money(d.commissionRevenue)],
                  [
                    'Dòng tiền thuần',
                    money(
                      (cashflow.data || []).reduce(
                        (n, r) => n + Number(r.incoming) - Number(r.outgoing),
                        0,
                      ),
                    ),
                  ],
                  ['Lợi nhuận ròng', 'Chưa đủ dữ liệu'],
                ]}
              />
              {user.role === 'GD' && (
                <MonitoringSettings scope="finance" settings={settings} action={a} />
              )}
              <Card title="Phạm vi báo cáo">
                <p>
                  Chưa có sổ chi phí vận hành để tính chi phí tổng và lợi nhuận ròng. Phần tiền
                  thuộc KTV và vật tư được trình bày riêng bên dưới.
                </p>
                {settings.data?.financeAlerts &&
                  (cashflow.data || []).reduce(
                    (n, r) => n + Number(r.incoming) - Number(r.outgoing),
                    0,
                  ) < 0 && <div className="notice warning">Dòng tiền thuần trong kỳ đang âm.</div>}
              </Card>
            </aside>
          </div>
          <FinancialBreakdown rows={finance.data} />
          <Card title="Giá trị thu theo ngày">
            {d.trend?.length ? (
              <div className="bar-chart">
                {d.trend.map((item) => (
                  <div className="bar-row" key={item.day}>
                    <span>{item.day}</span>
                    <div>
                      <i
                        style={{
                          width:
                            Math.max(
                              3,
                              (Number(item.amount) /
                                Math.max(...d.trend.map((x) => Number(x.amount)), 1)) *
                                100,
                            ) + '%',
                        }}
                      />
                    </div>
                    <b>{money(item.amount)}</b>
                  </div>
                ))}
              </div>
            ) : (
              <Empty title="Chưa có khoản thu trong kỳ" />
            )}
          </Card>
        </>
      )}
      <Card title="Hiệu suất kỹ thuật viên (toàn bộ thời gian)">
        <Table
          headers={['Kỹ thuật viên', 'Chuyên môn', 'Đơn đã thu', 'Điểm đánh giá', 'Trạng thái']}
          rows={techs.data}
          render={(t) => (
            <tr key={t.id}>
              <td>{t.fullName}</td>
              <td>{groups[t.skillGroup]}</td>
              <td>{t.completedOrders}</td>
              <td>{t.averageRating ? Number(t.averageRating).toFixed(1) : 'Chưa có'}</td>
              <td>
                <Badge value={t.availability} />
              </td>
            </tr>
          )}
        />
      </Card>
      {user.role !== 'DPV' && (
        <div id="finance-details">
          <Card title="Các khoản thu trong kỳ">
            <Table
              headers={['Đơn', 'Thợ thực hiện', 'Khoản đã thu', 'Hoa hồng', 'Đối soát']}
              rows={finance.data}
              render={(f) => (
                <tr key={f.id}>
                  <td>
                    {code(f.orderId)}
                    <small>{date(f.paidAt)}</small>
                  </td>
                  <td>{f.technicianName}</td>
                  <td>
                    {money(f.amount)}
                    <small>{f.method === 'BANK' ? 'Chuyển khoản' : 'Tiền mặt'}</small>
                  </td>
                  <td>{money(f.commissionAmount)}</td>
                  <td>
                    <Badge value={f.settlementStatus} />
                  </td>
                </tr>
              )}
            />
          </Card>
        </div>
      )}
    </>
  );
}

function ApplicationProfile({ json }) {
  let profile;
  try {
    profile = JSON.parse(json);
  } catch {
    return null;
  }
  return (
    <dl>
      <dt>Kinh nghiệm</dt>
      <dd>{profile.years} năm</dd>
      <dt>Thiết bị</dt>
      <dd>{profile.equipment}</dd>
      <dt>Chứng chỉ</dt>
      <dd>{profile.certificates || 'Không có'}</dd>
      <dt>Phương tiện</dt>
      <dd>{profile.vehicle}</dd>
    </dl>
  );
}

function FinancialBreakdown({ rows }) {
  if (!rows) return null;
  const sum = (key, predicate = () => true) =>
    rows.filter(predicate).reduce((total, row) => total + Number(row[key] || 0), 0);
  const collected = sum('amount'),
    commission = sum('commissionAmount'),
    materials = sum('materialTotal');
  return (
    <div className="two-column">
      <Card title="Dòng tiền đã thu trong kỳ">
        <div className="money-lines">
          <div>
            <span>Khách thanh toán tiền mặt</span>
            <b>{money(sum('amount', (r) => r.method === 'COD'))}</b>
          </div>
          <div>
            <span>Khách chuyển khoản về HomeFix</span>
            <b>{money(sum('amount', (r) => r.method === 'BANK'))}</b>
          </div>
          <div className="total">
            <span>Tổng giá trị đơn đã thu</span>
            <strong>{money(collected)}</strong>
          </div>
        </div>
        <p>{rows.length} giao dịch thanh toán trong kỳ.</p>
      </Card>
      <Card title="Phân bổ doanh thu & chi phí dịch vụ">
        <div className="money-lines">
          <div>
            <span>Vật tư được khách duyệt</span>
            <b>{money(materials)}</b>
          </div>
          <div>
            <span>Phí kiểm tra & tiền công</span>
            <b>{money(sum('inspectionFee') + sum('laborFee'))}</b>
          </div>
          <div>
            <span>Hoa hồng của HomeFix</span>
            <b>{money(commission)}</b>
          </div>
          <div>
            <span>Trong đó đã đối soát</span>
            <b>{money(sum('commissionAmount', (r) => r.settlementStatus === 'Confirmed'))}</b>
          </div>
          <div className="total">
            <span>Phần thuộc KTV, gồm hoàn chi vật tư</span>
            <strong>{money(collected - commission)}</strong>
          </div>
        </div>
        <small>
          Chưa tính lợi nhuận ròng vì hệ thống chưa ghi nhận chi phí vận hành. Hoa hồng là khoản thu
          của HomeFix; không đồng nhất với toàn bộ tiền khách trả.
        </small>
      </Card>
    </div>
  );
}
