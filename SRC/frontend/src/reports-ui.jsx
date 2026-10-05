import {
  MonitoringSettings,
  ReportOverview,
  PerformanceChart,
  useReportData,
} from './report-widgets';
import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Download, Filter, Phone, Star, Users, ShieldCheck } from 'lucide-react';
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
  Modal,
  money,
  date,
  code,
  groups,
  Badge,
} from './shared';
import { api } from './api';
const percent = (value) => (value == null ? 'Chưa có' : Number(value).toFixed(1) + '%');
const rating = (value) => (value == null ? 'Chưa có' : Number(value).toFixed(2) + '/5');
const excellent = (t) =>
  t.completionRate != null &&
  Number(t.completionRate) >= 90 &&
  Number(t.complaintRate) < 3 &&
  t.averageRating != null &&
  Number(t.averageRating) >= 4.2;
export function csvDownload(name, rows) {
  const escape = (value) =>
    '"' +
    String(value ?? '')
      .replace(/^[=+\-@]/, "'$&")
      .replaceAll('"', '""') +
    '"';
  const blob = new Blob(['\ufeff' + rows.map((r) => r.map(escape).join(',')).join('\r\n')], {
      type: 'text/csv;charset=utf-8',
    }),
    url = URL.createObjectURL(blob),
    link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
function Metric({ title, value, detail }) {
  return (
    <div className="stat-card">
      <div className="stat-label">{title}</div>
      <strong>{value}</strong>
      {detail && <small>{detail}</small>}
    </div>
  );
}
export function ReportWorkspace({ finance }) {
  const { user } = useApp(),
    location = useLocation(),
    allowedQuality = ['GD', 'CSKH'].includes(user.role),
    allowedFinance = ['GD', 'KT'].includes(user.role);
  const params = new URLSearchParams(location.search),
    selected =
      params.get('view') ||
      { quality: 'quality', technicians: 'performance', finance: 'finance' }[params.get('tab')] ||
      (user.role === 'GD' ? 'finance' : null),
    tab =
      selected === 'quality' && allowedQuality
        ? 'quality'
        : selected === 'performance'
          ? 'performance'
          : selected === 'finance' && allowedFinance
            ? 'finance'
            : allowedQuality
              ? 'quality'
              : allowedFinance
                ? 'finance'
                : 'performance';
  return (
    <>
      {user.role !== 'GD' && (
        <nav className="report-tabs" aria-label="Nhóm báo cáo">
          {allowedQuality && (
            <Link className={tab === 'quality' ? 'active' : ''} to="/reports?view=quality">
              Khách hàng & chất lượng
            </Link>
          )}
          {allowedFinance && (
            <Link className={tab === 'finance' ? 'active' : ''} to="/reports?view=finance">
              Dòng tiền & doanh thu
            </Link>
          )}
          <Link className={tab === 'performance' ? 'active' : ''} to="/reports?view=performance">
            Hiệu suất kỹ thuật viên
          </Link>
        </nav>
      )}
      {tab === 'finance' ? (
        finance
      ) : (
        <QualityPerformance key={tab} tab={tab} allowedQuality={allowedQuality} />
      )}
    </>
  );
}
function QualityPerformance({ tab, allowedQuality }) {
  const [range, setRange] = useState({ from: '', to: '' }),
    [query, setQuery] = useState(''),
    [appliedRange, setAppliedRange] = useState({ from: '', to: '' }),
    [filter, setFilter] = useState('all'),
    [skill, setSkill] = useState('all'),
    [search, setSearch] = useState(''),
    [selected, setSelected] = useState(null),
    [rangeError, setRangeError] = useState(null);
  const quality = useReportData(tab === 'quality' ? '/reports/quality' + query : null),
    performance = useReportData('/reports/performance' + query),
    settings = useReportData(allowedQuality ? '/reports/monitoring' : null),
    action = useAction();
  const previousQuery = (() => {
    if (tab !== 'quality' || !appliedRange.from || !appliedRange.to) return null;
    const from = new Date(appliedRange.from + 'T00:00:00+07:00'),
      end = new Date(new Date(appliedRange.to + 'T00:00:00+07:00').getTime() + 86400000);
    return (
      '/reports/quality?' +
      new URLSearchParams({
        from: new Date(from.getTime() - (end - from)).toISOString(),
        to: from.toISOString(),
      })
    );
  })();
  const previous = useReportData(previousQuery);
  function comparison(label) {
    if (!previousQuery) return 'Chọn đủ ngày để so sánh';
    if (previous.loading) return 'Đang tải…';
    if (!previous.data) return 'Chưa có dữ liệu';
    const key = {
      'Khách hàng phục vụ': 'servedCustomers',
      'Đơn hoàn tất': 'completedOrders',
      'Điểm đánh giá': 'averageRating',
      'Tỷ lệ khiếu nại': 'complaintRate',
      'Khách hàng mới': 'newCustomers',
      'Khách hoạt động': 'activeCustomers',
    }[label];
    const current = quality.data?.[key],
      before = previous.data[key];
    if (current == null || before == null) return 'Chưa đủ dữ liệu';
    const diff = Number(current) - Number(before);
    if (key === 'averageRating' || key === 'complaintRate')
      return (
        (diff > 0 ? '+' : '') + diff.toFixed(2) + (key === 'averageRating' ? ' điểm' : ' điểm %')
      );
    if (!Number(before)) return Number(current) ? 'Mới phát sinh' : 'Không đổi';
    const change = (100 * diff) / Number(before);
    return (change > 0 ? '+' : '') + change.toFixed(1) + '%';
  }
  const q = quality.data,
    rows = (performance.data || [])
      .filter(
        (t) =>
          (skill === 'all' || t.skillGroup === skill) &&
          (!search ||
            t.fullName.toLocaleLowerCase('vi').includes(search.toLocaleLowerCase('vi'))) &&
          (filter === 'all' ||
            (filter === 'excellent' ? excellent(t) : t.assignedOrders > 0 && !excellent(t))),
      )
      .sort(
        (a, b) =>
          Number(b.completionRate || 0) - Number(a.completionRate || 0) ||
          Number(b.averageRating || 0) - Number(a.averageRating || 0),
      );
  function apply(e) {
    e.preventDefault();
    if (range.from && range.to && range.from > range.to) {
      setRangeError(new Error('Ngày kết thúc phải bằng hoặc sau ngày bắt đầu.'));
      return;
    }
    setRangeError(null);
    const params = new URLSearchParams();
    if (range.from) params.set('from', new Date(range.from + 'T00:00:00+07:00').toISOString());
    if (range.to)
      params.set(
        'to',
        new Date(new Date(range.to + 'T00:00:00+07:00').getTime() + 86400000).toISOString(),
      );
    setAppliedRange({ ...range });
    setQuery(params.size ? '?' + params : '');
  }
  function exportData() {
    if (tab === 'quality' && q)
      csvDownload('HomeFix_ChatLuong.csv', [
        ['Chỉ số', 'Giá trị'],
        ['Kỳ bắt đầu', appliedRange.from || 'Toàn bộ'],
        ['Kỳ kết thúc', appliedRange.to || 'Hiện tại'],
        ['Khách phục vụ', q.servedCustomers],
        ['Đơn hoàn tất', q.completedOrders],
        ['Khách mới', q.newCustomers],
        ['Khách hoạt động', q.activeCustomers],
        ['Điểm trung bình', q.averageRating],
        ['Tỷ lệ đơn có khiếu nại (%)', q.complaintRate],
        [],
        ['Đơn dưới 3 sao', 'Khách hàng', 'Điểm', 'Nhận xét'],
        ...q.lowRatings.map((r) => [code(r.orderId), r.contactName, r.rating, r.comment]),
      ]);
    else
      csvDownload('HomeFix_HieuSuatKTV.csv', [
        ['Kỳ bắt đầu', appliedRange.from || 'Toàn bộ'],
        ['Kỳ kết thúc', appliedRange.to || 'Hiện tại'],
        [],
        [
          'Kỹ thuật viên',
          'Chuyên môn',
          'Đơn đã nhận',
          'Hoàn thành',
          'Tỷ lệ hoàn thành (%)',
          'Tỷ lệ khiếu nại (%)',
          'Điểm',
          'Đơn từ chối',
          'Tỷ lệ hủy (%)',
          'Tỷ lệ bảo hành (%)',
          'Đúng giờ (%)',
          'Thời gian xử lý (phút)',
        ],
        ...rows.map((t) => [
          t.fullName,
          groups[t.skillGroup],
          t.assignedOrders,
          t.finishedOrders,
          t.completionRate,
          t.complaintRate,
          t.averageRating,
          t.rejectedOrders,
          t.cancellationRate,
          t.warrantyRate,
          t.onTimeRate,
          t.averageMinutes,
        ]),
      ]);
  }
  const alert =
    q &&
    settings.data?.qualityAlerts &&
    ((q.averageRating != null && Number(q.averageRating) < 4.2) ||
      (q.complaintRate != null && Number(q.complaintRate) > 3));
  return (
    <>
      <PageHead
        eyebrow="THỐNG KÊ & BÁO CÁO"
        title={tab === 'quality' ? 'Khách hàng & chất lượng dịch vụ' : 'Hiệu suất & năng suất KTV'}
        text="Lọc theo kỳ, xem chi tiết và xuất số liệu hiện tại."
      >
        <button
          className="btn"
          disabled={tab === 'quality' ? !q : !performance.data}
          onClick={() =>
            document
              .querySelector('.report-detail-section')
              ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
          }
        >
          Xem chi tiết
        </button>
        <button
          className="btn primary"
          disabled={tab === 'quality' ? !q : !performance.data}
          onClick={exportData}
        >
          <Download size={17} />
          Xuất báo cáo
        </button>
      </PageHead>
      <form className="filter-bar" onSubmit={apply}>
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
        <button type="submit" className="btn">
          <Filter size={17} />
          Lọc
        </button>
        <button
          type="button"
          className="btn"
          onClick={() => {
            setRange({ from: '', to: '' });
            setAppliedRange({ from: '', to: '' });
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
          quality.error ||
          previous.error ||
          performance.error ||
          settings.error ||
          action.error
        }
      />
      {(tab === 'quality' ? quality.loading : performance.loading) ? (
        <Loading />
      ) : tab === 'quality' && q ? (
        <>
          <div className="stat-grid">
            <Metric
              title="Khách hàng phục vụ"
              value={q.servedCustomers}
              detail="Khách có đơn thanh toán trong kỳ"
            />
            <Metric
              title="Đơn hoàn tất"
              value={q.completedOrders}
              detail="Đã nghiệm thu và thanh toán trong kỳ"
            />
            <Metric
              title="Điểm hài lòng"
              value={rating(q.averageRating)}
              detail={q.reviews + ' đánh giá trong kỳ'}
            />
            <Metric
              title="Tỷ lệ đơn có khiếu nại"
              value={percent(q.complaintRate)}
              detail={q.complaintOrders + ' / ' + q.totalOrders + ' đơn tạo trong kỳ'}
            />
          </div>
          {alert && (
            <div className="notice error">
              <ShieldCheck />
              <div>
                <b>Cần kiểm tra chất lượng phục vụ</b>
                <p>Điểm hài lòng dưới 4,2 hoặc tỷ lệ khiếu nại vượt 3%.</p>
              </div>
            </div>
          )}
          <div className="two-column report-columns">
            <div>
              <Card title="Bảng chất lượng dịch vụ">
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Chỉ tiêu</th>
                        <th>Mô tả</th>
                        <th>Giá trị</th>
                        <th>So kỳ trước</th>
                      </tr>
                    </thead>
                    <tbody>
                      {[
                        [
                          'Khách hàng phục vụ',
                          'Khách có đơn đã thanh toán trong kỳ',
                          q.servedCustomers,
                        ],
                        ['Đơn hoàn tất', 'Nghiệm thu và thanh toán trong kỳ', q.completedOrders],
                        [
                          'Điểm đánh giá',
                          'Trung bình đánh giá được gửi trong kỳ',
                          rating(q.averageRating),
                        ],
                        [
                          'Tỷ lệ khiếu nại',
                          'Đơn tạo trong kỳ có ít nhất một khiếu nại',
                          percent(q.complaintRate),
                        ],
                        ['Khách hàng mới', 'Tài khoản khách tạo trong kỳ', q.newCustomers],
                        ['Khách hoạt động', 'Khách có đơn được tạo trong kỳ', q.activeCustomers],
                      ].map(([label, note, value]) => (
                        <tr key={label}>
                          <td>{label}</td>
                          <td>{note}</td>
                          <td>
                            <b>{value}</b>
                          </td>
                          <td>{comparison(label)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <small>
                  So sánh với kỳ liền trước có cùng số ngày khi chọn đầy đủ ngày bắt đầu và kết
                  thúc.
                </small>
              </Card>
              <Card title="Phân bố đánh giá">
                <div className="rating-bars">
                  {[5, 4, 3, 2, 1].map((star) => {
                    const count = Number(q.ratings.find((r) => r.rating === star)?.count || 0);
                    return (
                      <div key={star}>
                        <b>{star} sao</b>
                        <progress max={Math.max(1, q.reviews)} value={count} />
                        <span>{count}</span>
                      </div>
                    );
                  })}
                </div>
              </Card>
              <Card title="Đánh giá dưới 3 sao cần chăm sóc" className="report-detail-section">
                {q.lowRatings.length ? (
                  <div className="table-wrap">
                    <table>
                      <thead>
                        <tr>
                          <th>Đơn / khách hàng</th>
                          <th>Đánh giá</th>
                          <th>Liên hệ</th>
                        </tr>
                      </thead>
                      <tbody>
                        {q.lowRatings.map((r) => (
                          <tr key={r.orderId}>
                            <td>
                              <b>{code(r.orderId)}</b>
                              <small>
                                {r.contactName} · {r.technicianName}
                              </small>
                            </td>
                            <td>
                              <b className="text-red">{r.rating} / 5 sao</b>
                              <small>{r.comment}</small>
                            </td>
                            <td>
                              <a className="btn small" href={'tel:' + r.contactPhone}>
                                <Phone size={15} />
                                Gọi khách
                              </a>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <Empty title="Không có đánh giá dưới 3 sao trong kỳ" />
                )}
              </Card>
            </div>
            <aside>
              <ReportOverview
                title="Tổng quan chất lượng"
                items={[
                  ['Điểm đánh giá', rating(q.averageRating)],
                  ['Tỷ lệ khiếu nại', percent(q.complaintRate)],
                  ['Khách phục vụ', q.servedCustomers],
                  ['Đơn hoàn tất', q.completedOrders],
                ]}
              />
              <Card title="Chất lượng kỹ thuật viên">
                <p>
                  {(performance.data || []).filter(excellent).length} kỹ thuật viên đạt cả ba tiêu
                  chí: hoàn thành từ 90%, khiếu nại dưới 3%, đánh giá từ 4,2 sao.
                </p>
                <Link className="btn" to="/reports?tab=technicians">
                  Xem hiệu suất KTV
                </Link>
              </Card>
              <MonitoringSettings settings={settings} action={action} />
            </aside>
          </div>
          {settings.data?.showComplaints && (
            <Card title="Chi tiết khiếu nại trong kỳ">
              {q.complaints.length ? (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Phiếu / đơn</th>
                        <th>Khách hàng</th>
                        <th>Nội dung</th>
                        <th>Trạng thái</th>
                      </tr>
                    </thead>
                    <tbody>
                      {q.complaints.map((c) => (
                        <tr key={c.id}>
                          <td>
                            HT-{c.id}
                            <small>{code(c.orderId)}</small>
                          </td>
                          <td>{c.customerName}</td>
                          <td>
                            {c.description}
                            <small>{date(c.createdAt)}</small>
                          </td>
                          <td>
                            <Badge value={c.status} />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <Empty title="Chưa có khiếu nại trong kỳ" />
              )}
            </Card>
          )}
        </>
      ) : tab === 'performance' ? (
        <>
          <div className="stat-grid">
            <Metric title="Tổng kỹ thuật viên" value={performance.data?.length || 0} />
            <Metric
              title="Đạt tiêu chí chất lượng"
              value={(performance.data || []).filter(excellent).length}
            />
            <Metric
              title="Đơn đã nhận trong kỳ"
              value={(performance.data || []).reduce((n, t) => n + Number(t.assignedOrders), 0)}
            />
            <Metric
              title="Cần xem xét"
              value={
                (performance.data || []).filter((t) => t.assignedOrders > 0 && !excellent(t)).length
              }
              detail="Có ít nhất một tiêu chí chưa đạt"
            />
          </div>
          <div className="stat-grid">
            <Metric
              title="KTV đang hoạt động"
              value={(performance.data || []).filter((t) => t.isActive).length}
              detail="Tài khoản đang được kích hoạt"
            />
            <Metric
              title="Đơn hoàn thành / KTV"
              value={
                performance.data?.length
                  ? (
                      (performance.data || []).reduce((n, t) => n + Number(t.finishedOrders), 0) /
                      performance.data.length
                    ).toFixed(1)
                  : 'Chưa có'
              }
            />
            <Metric
              title="Đúng giờ"
              value={percent(
                (() => {
                  const total = (performance.data || []).reduce(
                    (n, t) => n + Number(t.scheduledVisits || 0),
                    0,
                  );
                  return total
                    ? (100 *
                        (performance.data || []).reduce(
                          (n, t) => n + Number(t.onTimeVisits || 0),
                          0,
                        )) /
                        total
                    : null;
                })(),
              )}
              detail="Chỉ đơn có lịch hẹn và giờ đến"
            />
            <Metric
              title="Thời gian xử lý"
              value={(() => {
                const jobs = (performance.data || []).reduce(
                  (n, t) => n + Number(t.measuredJobs || 0),
                  0,
                );
                return jobs
                  ? Math.round(
                      (performance.data || []).reduce(
                        (n, t) => n + Number(t.processingMinutes || 0),
                        0,
                      ) / jobs,
                    ) + ' phút'
                  : 'Chưa có';
              })()}
              detail="Bắt đầu sửa đến lần gửi nghiệm thu đầu"
            />
          </div>
          {settings.data?.performanceAlerts &&
            rows.some((t) => t.assignedOrders > 0 && !excellent(t)) && (
              <div className="notice warning">
                Có kỹ thuật viên chưa đạt tiêu chí trong kỳ. Kiểm tra cả đơn đang làm trước khi đánh
                giá.
              </div>
            )}
          <div className="two-column report-columns">
            <div>
              <PerformanceChart rows={rows} />
              <Card title="Bảng xếp hạng kỹ thuật viên" className="report-detail-section">
                <div className="filter-bar">
                  <Field label="Tìm kỹ thuật viên">
                    <input
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      placeholder="Nhập tên kỹ thuật viên"
                    />
                  </Field>
                  <Field label="Chuyên môn">
                    <select
                      aria-label="Chuyên môn"
                      value={skill}
                      onChange={(e) => setSkill(e.target.value)}
                    >
                      <option value="all">Tất cả chuyên môn</option>
                      {Object.entries(groups).map(([key, label]) => (
                        <option key={key} value={key}>
                          {label}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <Field label="Xếp loại">
                    <select
                      aria-label="Xếp loại"
                      value={filter}
                      onChange={(e) => setFilter(e.target.value)}
                    >
                      <option value="all">Tất cả</option>
                      <option value="excellent">Đạt tiêu chí</option>
                      <option value="attention">Cần xem xét</option>
                    </select>
                  </Field>
                </div>
                <small>
                  Tỷ lệ hoàn thành và khiếu nại tính trên các đơn đã nhận trong kỳ; điểm đánh giá
                  tính theo ngày đánh giá. Đơn đang làm vẫn nằm trong số đơn đã nhận.
                </small>
                {settings.data?.showTechnicians === false ? (
                  <p>Chi tiết KTV đang ẩn. Bật trong Cài đặt giám sát để xem bảng.</p>
                ) : rows.length ? (
                  <div className="table-wrap">
                    <table>
                      <thead>
                        <tr>
                          <th>Kỹ thuật viên</th>
                          <th>Đã nhận</th>
                          <th>Hoàn thành</th>
                          <th>Tỷ lệ hoàn thành</th>
                          <th>Khiếu nại</th>
                          <th>Tỷ lệ hủy</th>
                          <th>Bảo hành</th>
                          <th>Đánh giá</th>
                          <th>Chi tiết</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((t, i) => (
                          <tr key={t.id}>
                            <td>
                              <b>
                                {i + 1}. {t.fullName}
                              </b>
                              <small>{groups[t.skillGroup]}</small>
                            </td>
                            <td>{t.assignedOrders}</td>
                            <td>{t.finishedOrders}</td>
                            <td
                              className={
                                t.completionRate != null && Number(t.completionRate) < 90
                                  ? 'text-red'
                                  : 'text-green'
                              }
                            >
                              {percent(t.completionRate)}
                            </td>
                            <td className={Number(t.complaintRate) >= 3 ? 'text-red' : ''}>
                              {percent(t.complaintRate)}
                            </td>
                            <td>{percent(t.cancellationRate)}</td>
                            <td>{percent(t.warrantyRate)}</td>
                            <td>{rating(t.averageRating)}</td>
                            <td>
                              <button className="btn small" onClick={() => setSelected(t)}>
                                Xem chi tiết
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <Empty title="Chưa có kỹ thuật viên phù hợp" />
                )}
              </Card>
            </div>
            <aside>
              <ReportOverview
                items={[
                  ['KTV trong bộ lọc', rows.length],
                  ['Đạt tiêu chí', rows.filter(excellent).length],
                  ['Cần xem xét', rows.filter((t) => t.assignedOrders > 0 && !excellent(t)).length],
                  ['Đơn hoàn tất', rows.reduce((n, t) => n + Number(t.finishedOrders), 0)],
                ]}
              />
              {allowedQuality && (
                <MonitoringSettings scope="performance" settings={settings} action={action} />
              )}
              <Card title="Cách đọc số liệu">
                <p>
                  Tỷ lệ hủy và yêu cầu bảo hành tính trên đơn đã nhận trong kỳ. Yêu cầu bảo hành
                  không đồng nghĩa đã tái khám.
                </p>
                <p>Chưa có dữ liệu được hiển thị riêng; không xếp thành 0%.</p>
              </Card>
            </aside>
          </div>
        </>
      ) : null}
      {selected && (
        <Modal title={selected.fullName} onClose={() => setSelected(null)}>
          <Badge value={selected.availability} />
          <div className="performance-detail">
            <Metric
              title="Hoàn thành / đã nhận"
              value={selected.finishedOrders + ' / ' + selected.assignedOrders}
            />
            <Metric title="Tỷ lệ hoàn thành" value={percent(selected.completionRate)} />
            <Metric title="Tỷ lệ khiếu nại" value={percent(selected.complaintRate)} />
            <Metric title="Điểm đánh giá" value={rating(selected.averageRating)} />
          </div>
          <p>
            Đơn từ chối trong kỳ: <b>{selected.rejectedOrders}</b>
          </p>
          <div className={'notice ' + (excellent(selected) ? 'success' : 'warning')}>
            {selected.assignedOrders === 0
              ? 'Chưa đủ dữ liệu đánh giá.'
              : excellent(selected)
                ? 'Đạt các tiêu chí chất lượng trong kỳ.'
                : 'Cần xem xét chi tiết trước khi quyết định đánh giá nhân sự.'}
          </div>
        </Modal>
      )}
    </>
  );
}
