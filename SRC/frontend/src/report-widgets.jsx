import React, { useEffect, useState } from 'react';
import { useApp, Card, Empty, money } from './shared';
import { api } from './api';

// Keep filtered exports and labels aligned with the response for the current period.
export function useReportData(path) {
  const [result, setResult] = useState({ path: null, data: null, error: null, loading: true });
  useEffect(() => {
    if (!path) {
      setResult({ path, data: null, error: null, loading: false });
      return;
    }
    const controller = new AbortController();
    setResult({ path, data: null, error: null, loading: true });
    api(path, { signal: controller.signal })
      .then((r) => {
        if (!controller.signal.aborted)
          setResult({ path, data: r.data, error: null, loading: false });
      })
      .catch((error) => {
        if (!controller.signal.aborted) setResult({ path, data: null, error, loading: false });
      });
    return () => controller.abort();
  }, [path]);
  return {
    ...(result.path === path ? result : { data: null, error: null, loading: !!path }),
    setData: (data) => setResult({ path, data, error: null, loading: false }),
  };
}

export function MonitoringSettings({ scope = 'quality', settings, action }) {
  const { user } = useApp();
  if (!settings.data) return null;
  const fields =
    scope === 'finance'
      ? [
          ['financeAlerts', 'Cảnh báo dòng tiền thấp'],
          ['financeWeekly', 'Gửi báo cáo hàng tuần'],
          ['showCashflow', 'Hiển thị chi tiết dòng tiền'],
        ]
      : scope === 'performance'
        ? [
            ['performanceAlerts', 'Cảnh báo hiệu suất thấp'],
            ['performanceWeekly', 'Gửi báo cáo hàng tuần'],
            ['showTechnicians', 'Hiển thị chi tiết KTV'],
          ]
        : [
            ['qualityAlerts', 'Cảnh báo chất lượng thấp'],
            ['weeklyReport', 'Gửi báo cáo hàng tuần'],
            ['showComplaints', 'Hiển thị chi tiết khiếu nại'],
          ];
  function change(key, value) {
    action.run(async () => {
      const current = settings.data;
      const body = {
        qualityAlerts: current.qualityAlerts,
        weeklyReport: current.weeklyReport,
        showComplaints: current.showComplaints,
        [key]: value,
        ...(current.version ? { expectedVersion: current.version } : {}),
      };
      const result = await api('/reports/monitoring', { method: 'PATCH', body });
      settings.setData(result.data);
    });
  }
  return (
    <Card title="Cài đặt giám sát" className="report-settings">
      {fields.map(([key, label]) => (
        <label key={key}>
          <span>{label}</span>
          <input
            type="checkbox"
            role="switch"
            checked={!!settings.data[key]}
            disabled={action.busy || (user.role !== 'GD' && scope !== 'quality')}
            onChange={(e) => change(key, e.target.checked)}
          />
        </label>
      ))}
      <small>
        Báo cáo tuần và cảnh báo được gửi vào mục Thông báo trong ứng dụng khi máy chủ hoạt động.
      </small>
      <p className="report-note">
        {scope === 'finance'
          ? 'Cảnh báo khi tiền ra vượt tiền vào trong tuần trước. Dòng tiền không phải lợi nhuận.'
          : scope === 'performance'
            ? 'Cảnh báo khi dưới 90% đơn nhận tuần trước đã hoàn thành; cần xem cả đơn đang làm.'
            : 'Cảnh báo khi đánh giá dưới 4,2 sao hoặc tỷ lệ đơn có khiếu nại trên 3%.'}
      </p>
    </Card>
  );
}
export function ReportOverview({ title = 'Tổng quan hiệu suất', items }) {
  return (
    <Card title={title}>
      <div className="report-overview">
        {items.map(([label, value]) => (
          <div key={label}>
            <small>{label}</small>
            <strong>{value}</strong>
          </div>
        ))}
      </div>
    </Card>
  );
}
export function PerformanceChart({ rows }) {
  const top = [...rows]
      .sort((a, b) => Number(b.finishedOrders) - Number(a.finishedOrders))
      .slice(0, 8),
    max = Math.max(1, ...top.map((t) => Number(t.assignedOrders)));
  return (
    <Card title="Đơn đã nhận & hoàn thành theo KTV">
      <div className="chart-legend">
        <span>
          <i className="chart-received" />
          Đã nhận
        </span>
        <span>
          <i />
          Hoàn thành
        </span>
      </div>
      {top.length ? (
        <div
          className="performance-chart"
          role="img"
          aria-label="Biểu đồ so sánh đơn đã nhận và hoàn thành của tối đa 8 kỹ thuật viên"
        >
          <div className="report-note">Xếp theo số đơn hoàn thành trong kỳ.</div>
          {top.map((t) => (
            <div className="performance-chart-row" key={t.id}>
              <span>{t.fullName}</span>
              <div>
                <div
                  className="chart-received"
                  style={{ width: (100 * Number(t.assignedOrders)) / max + '%' }}
                />
                <div style={{ width: (100 * Number(t.finishedOrders)) / max + '%' }} />
              </div>
              <b>
                {t.finishedOrders} / {t.assignedOrders}
              </b>
            </div>
          ))}
        </div>
      ) : (
        <Empty title="Chưa có dữ liệu kỹ thuật viên" />
      )}
    </Card>
  );
}
export function CashflowChart({ rows }) {
  if (!rows?.length) return <Empty title="Chưa có dòng tiền trong kỳ" />;
  const grouped = new Map(),
    monthly = rows.length > 45;
  for (const row of rows) {
    const key = monthly ? row.day.slice(0, 7) : row.day;
    const d = grouped.get(key) || { day: key, incoming: 0, outgoing: 0 };
    d.incoming += Number(row.incoming);
    d.outgoing += Number(row.outgoing);
    grouped.set(key, d);
  }
  const points = [...grouped.values()],
    max = Math.max(1, ...points.flatMap((r) => [r.incoming, r.outgoing])),
    width = Math.max(640, points.length * 24),
    plot = width - 92,
    step = plot / points.length;
  return (
    <>
      <div className="chart-legend">
        <span>
          <i />
          Tiền vào
        </span>
        <span>
          <i className="chart-outgoing" />
          Tiền ra
        </span>
        <small>Đơn vị: triệu đồng · {monthly ? 'Theo tháng' : 'Theo ngày'}</small>
      </div>
      <div className="cashflow-chart-scroll">
        <svg
          viewBox={`0 0 ${width} 274`}
          style={{ minWidth: Math.min(width, 900) }}
          role="img"
          aria-label="Biểu đồ dòng tiền: tiền vào phía trên, tiền ra phía dưới trục 0"
        >
          <line x1="70" y1="130" x2={width - 12} y2="130" stroke="#aabeb3" />
          {[-1, 0, 1].map((t) => (
            <g key={t}>
              <line x1="70" y1={130 - t * 92} x2={width - 12} y2={130 - t * 92} stroke="#e4ece7" />
              <text x="62" y={134 - t * 92} textAnchor="end" fontSize="11" fill="#5d7167">
                {((t * max) / 1000000).toLocaleString('vi-VN', { maximumFractionDigits: 2 })}
              </text>
            </g>
          ))}
          {points.map((r, i) => (
            <g key={r.day}>
              <title>
                {r.day}: vào {money(r.incoming)}, ra {money(r.outgoing)}
              </title>
              <rect
                x={76 + i * step}
                y={130 - (r.incoming / max) * 92}
                width={Math.max(2, step * 0.56)}
                height={(r.incoming / max) * 92}
                rx="2"
                fill="#22b767"
              />
              <rect
                x={76 + i * step}
                y="130"
                width={Math.max(2, step * 0.56)}
                height={(r.outgoing / max) * 92}
                rx="2"
                fill="#e74b51"
              />
              {(i % Math.max(1, Math.ceil(points.length / 8)) === 0 || i === points.length - 1) && (
                <text x={76 + i * step} y="251" fontSize="10" fill="#5d7167">
                  {monthly ? r.day : r.day.slice(5).split('-').reverse().join('/')}
                </text>
              )}
            </g>
          ))}
        </svg>
      </div>
    </>
  );
}
