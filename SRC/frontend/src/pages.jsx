import { AssignmentAlerts } from './assignment-alerts';
import { PasswordChange } from './auth-forms';
import React, { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  ArrowRight,
  Plus,
  Snowflake,
  Refrigerator,
  WashingMachine,
  PlugZap,
  Droplets,
  Sparkles,
  ShieldCheck,
  Clock,
  Star,
  Wallet,
  MapPin,
  CalendarDays,
  Bell,
  Check,
  CheckCircle2,
  RefreshCw,
  BarChart3,
  ArrowDownUp,
  ReceiptText,
  AlertTriangle,
  Download,
  UsersRound,
  ClipboardCheck,
  FileText,
  TrendingUp,
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
  OrderCard,
  Badge,
  money,
  date,
  groups,
  roleNames,
  labels,
} from './shared';
const icons = [Snowflake, Sparkles, Refrigerator, WashingMachine, PlugZap, Droplets];
function ServiceCards({ services }) {
  return (
    <div className="service-grid">
      {services.map((s, i) => {
        const Icon = icons[i % icons.length];
        return (
          <Link className="service-card" to={'/book/' + s.id} key={s.id}>
            <div className={'service-art color-' + (i % 4)}>
              <Icon size={47} strokeWidth={1.5} />
              <span>{groups[s.groupCode]}</span>
            </div>
            <div className="service-copy">
              <h3>{s.name}</h3>
              <p>{s.description}</p>
              <div className="service-price">
                <div>
                  <small>Tiền công tham khảo</small>
                  <strong>{money(s.laborFee)}</strong>
                </div>
                <span className="circle-arrow">
                  <ArrowRight size={18} />
                </span>
              </div>
            </div>
          </Link>
        );
      })}
    </div>
  );
}
export function Dashboard() {
  const { user } = useApp();
  if (user.role === 'KH') return <CustomerHome />;
  if (user.role === 'KTV') return <TechnicianHome />;
  if (user.role === 'KT') return <FinanceDashboard />;
  if (user.role === 'GD')
    return new URLSearchParams(window.location.search).get('tab') === 'policies' ? (
      <PolicyApproval />
    ) : (
      <ExecutiveDashboard />
    );
  return <StaffHome />;
}
function CustomerHome() {
  const { user } = useApp(),
    services = useData('/services'),
    orders = useData('/orders?pageSize=5', 10000);
  return (
    <>
      <section className="customer-hero">
        <div>
          <span className="eyebrow">CHĂM SÓC NHÀ CỬA, THẬT DỄ DÀNG</span>
          <h1>
            Nhà cần sửa?
            <br />
            <em>Đã có HomeFix.</em>
          </h1>
          <p>
            Chào {user.fullName.split(' ').at(-1)}, đặt dịch vụ ngay để thiết bị trong nhà luôn hoạt
            động tốt.
          </p>
          <Link to="/services" className="btn primary">
            Đặt dịch vụ ngay <ArrowRight size={18} />
          </Link>
          <div className="hero-trust">
            <span>
              <ShieldCheck /> Giá rõ ràng
            </span>
            <span>
              <Clock /> Đặt lịch thuận tiện
            </span>
          </div>
        </div>
        <div className="hero-visual" aria-hidden="true">
          <div className="hero-circle">
            <WashingMachine size={118} strokeWidth={1} />
            <span className="orbit one">
              <Snowflake />
            </span>
            <span className="orbit two">
              <PlugZap />
            </span>
            <span className="orbit three">
              <Droplets />
            </span>
          </div>
          <div className="hero-label">
            <ShieldCheck size={22} />
            <div>
              <b>An tâm từng dịch vụ</b>
              <small>Xác nhận trước khi sửa chữa</small>
            </div>
          </div>
        </div>
      </section>
      <div className="section-head">
        <div>
          <span className="eyebrow">GIẢI PHÁP CHO NGÔI NHÀ</span>
          <h2>Dịch vụ phổ biến</h2>
        </div>
        <Link to="/services" className="text-link">
          Xem tất cả <ArrowRight size={16} />
        </Link>
      </div>
      <ErrorBox error={services.error} />
      {services.loading ? (
        <Loading />
      ) : (
        services.data && (
          <ServiceCards services={services.data.filter((s) => s.isPopular).slice(0, 6)} />
        )
      )}
      <div className="section-head">
        <h2>Đơn dịch vụ gần đây</h2>
        <Link className="text-link" to="/orders">
          Xem lịch sử <ArrowRight size={16} />
        </Link>
      </div>
      <ErrorBox error={orders.error} />
      {orders.data?.length ? (
        <div className="order-list">
          {orders.data.slice(0, 3).map((o) => (
            <OrderCard order={o} key={o.id} />
          ))}
        </div>
      ) : (
        <Empty
          title="Ngôi nhà đang được chăm sóc tốt"
          text="Khi cần sửa chữa hoặc bảo trì, bạn có thể đặt dịch vụ trong vài bước."
        />
      )}
      <div className="benefit-row">
        <div>
          <ShieldCheck />
          <h3>Báo giá minh bạch</h3>
          <p>Xem và duyệt chi phí trước khi thợ thực hiện.</p>
        </div>
        <div>
          <CalendarDays />
          <h3>Chủ động thời gian</h3>
          <p>Đặt ngay hoặc chọn lịch hẹn phù hợp.</p>
        </div>
        <div>
          <Star />
          <h3>Lắng nghe phản hồi</h3>
          <p>Đánh giá và gửi yêu cầu hỗ trợ sau dịch vụ.</p>
        </div>
      </div>
    </>
  );
}
function TechnicianHome() {
  const me = useData('/technicians/me', 10000),
    orders = useData('/orders?pageSize=20', 10000),
    income = useData('/technicians/me/income?today=1', 15000),
    action = useAction();
  const active = orders.data?.filter((o) => !['HoanThanh', 'Huy'].includes(o.status)) || [];
  return (
    <>
      <PageHead
        eyebrow="HOMEFIX PARTNER"
        title="Sẵn sàng cho một ngày làm việc?"
        text="Theo dõi ca làm, phản hồi lệnh và cập nhật tiến độ tại đây."
      />
      <ErrorBox error={me.error || orders.error || action.error} />
      <AssignmentAlerts orders={active} />
      {me.data && (
        <>
          <div className="availability-card">
            <div>
              <span className="eyebrow">TRẠNG THÁI LÀM VIỆC</span>
              <h2>
                <span
                  className={'status-dot ' + (me.data.availability === 'SanSang' ? 'on' : '')}
                />
                {labels[me.data.availability]}
              </h2>
              <p>
                {groups[me.data.skillGroup]} · {me.data.serviceArea}
              </p>
            </div>
            <button
              className={'btn ' + (me.data.availability === 'SanSang' ? '' : 'primary')}
              role="switch"
              aria-checked={me.data.availability === 'SanSang'}
              aria-label="Sẵn sàng nhận việc"
              disabled={
                action.busy ||
                !!me.data.activeAssignmentSummary ||
                (me.data.availability !== 'SanSang' &&
                  Number(me.data.balance) < Number(me.data.walletEligibility.minimum))
              }
              onClick={() =>
                action.run(async () => {
                  await api('/technicians/me/availability', {
                    method: 'PATCH',
                    body: {
                      availability: me.data.availability === 'SanSang' ? 'TamBan' : 'SanSang',
                      expectedVersion: me.data.version,
                    },
                  });
                  me.reload();
                })
              }
            >
              {me.data.availability === 'SanSang' ? 'Tạm nghỉ' : 'Bật sẵn sàng'}
            </button>
          </div>
          <div className="stat-grid three">
            <Stat label="Số dư ví" value={money(me.data.balance)} icon={Wallet} />
            <Stat
              label="Thu nhập hôm nay"
              value={
                income.error ? 'Chưa tải được' : income.loading ? '…' : money(income.data?.income)
              }
              icon={Wallet}
            />
            <Stat label="Công việc đang giữ" value={active.length} icon={Clock} />
            <Stat
              label="Đánh giá trung bình"
              value={
                me.data.averageRating ? Number(me.data.averageRating).toFixed(1) + '/5' : 'Chưa có'
              }
              icon={Star}
            />
          </div>
          {Number(me.data.balance) < Number(me.data.walletEligibility.minimum) && (
            <div className="notice warning">
              Ví cần tối thiểu {money(me.data.walletEligibility.minimum)} để nhận việc.{' '}
              <Link className="btn reject-order" to="/wallet?request=Deposit">
                Nạp tiền ngay
              </Link>
            </div>
          )}
        </>
      )}
      <div className="section-head">
        <h2>Công việc cần xử lý</h2>
        <button
          className="text-btn"
          onClick={() => {
            me.reload();
            orders.reload();
          }}
        >
          <RefreshCw size={16} /> Cập nhật
        </button>
      </div>
      {orders.loading ? (
        <Loading />
      ) : active.length ? (
        <div className="order-list">
          {active.map((o) => (
            <OrderCard order={o} key={o.id} />
          ))}
        </div>
      ) : (
        <Empty
          title="Chưa có ca đang chờ"
          text="Bật sẵn sàng để điều phối viên có thể giao công việc phù hợp."
        />
      )}
    </>
  );
}
export function Stat({ label, value, icon: Icon = Clock, detail }) {
  return (
    <div className="stat-card">
      <div className="stat-label">
        {label}
        <Icon size={19} />
      </div>
      <strong>{value}</strong>
      {detail && <small>{detail}</small>}
    </div>
  );
}
function amountByWeek(rows, dateKey, amountKey) {
  const now = new Date();
  const weeks = Array.from({ length: 5 }, (_, index) => ({
    label: 'Tuần ' + (index + 1),
    amount: 0,
  }));
  for (const row of rows || []) {
    const at = new Date(row[dateKey]);
    const age = Math.floor((now - at) / 86400000);
    const slot = 4 - Math.floor(age / 7);
    if (slot >= 0 && slot < 5) weeks[slot].amount += Number(row[amountKey] || 0);
  }
  return weeks;
}
function FinanceDashboard() {
  const summary = useData('/reports/summary', 15000),
    settlements = useData('/settlements', 15000),
    walletRequests = useData('/wallet-requests', 15000);
  const pendingWallet = (walletRequests.data || []).filter((item) => item.status === 'Pending');
  const pendingCod = (settlements.data || []).filter(
    (item) => item.status === 'Pending' && item.method === 'COD',
  );
  const walletWeeks = amountByWeek(walletRequests.data, 'createdAt', 'amount');
  const codWeeks = amountByWeek(
    (settlements.data || []).filter((item) => item.method === 'COD'),
    'paidAt',
    'amount',
  );
  const peak = Math.max(
    1,
    ...walletWeeks.map((item) => item.amount),
    ...codWeeks.map((item) => item.amount),
  );
  const recent = [
    ...pendingWallet.map((item) => ({
      type: 'wallet',
      id: item.id,
      name: item.technicianName,
      amount: item.amount,
      status: item.type === 'Deposit' ? 'Chờ xác minh nạp ví' : 'Chờ duyệt rút ví',
    })),
    ...pendingCod.map((item) => ({
      type: 'cod',
      id: item.id,
      name: item.technicianName,
      amount: item.amount,
      status: 'Chờ đối soát COD',
    })),
  ].slice(0, 4);
  const errors = [summary.error, settlements.error, walletRequests.error].filter(Boolean);
  return (
    <div className="finance-dashboard">
      <div className="finance-heading">
        <div>
          <div className="breadcrumb-text">
            HomeFix <span>›</span> Tổng quan tài chính
          </div>
          <h1>Dashboard Tài chính & Dòng tiền</h1>
          <p>
            Theo dõi trực quan doanh thu tổng, thực thu hoa hồng và trạng thái thanh toán thợ sửa.
          </p>
        </div>
        <Link className="btn finance-report-button" to="/reports">
          <Download size={17} /> Báo cáo đối soát
        </Link>
      </div>
      {errors.map((error, index) => (
        <ErrorBox error={error} key={index} />
      ))}
      <section className="finance-kpis">
        <FinanceKpi
          label="Tổng doanh thu dịch vụ"
          value={money(summary.data?.gmv)}
          detail={`${summary.data?.paidOrders || 0} đơn đã ghi nhận thanh toán`}
          tone="navy"
        />
        <FinanceKpi
          label="Thực thu chiết khấu hoa hồng sàn"
          value={money(summary.data?.commissionRevenue)}
          detail="Hoa hồng đã được kế toán đối soát"
          tone="green"
        />
        <FinanceKpi
          label="Yêu cầu Nạp / Rút chờ duyệt"
          value={`${pendingWallet.length} lệnh`}
          detail={
            pendingWallet.length ? 'Đang chờ bộ phận Kế toán xử lý' : 'Không có yêu cầu đang chờ'
          }
          tone="orange"
        />
        <FinanceKpi
          label="Tiền mặt COD chưa đối soát thợ"
          value={money(pendingCod.reduce((total, item) => total + Number(item.amount || 0), 0))}
          detail={
            pendingCod.length
              ? `Được giữ bởi ${pendingCod.length} lệnh COD`
              : 'Không có COD đang chờ đối soát'
          }
          tone="red"
        />
      </section>
      <section className="finance-panel finance-chart-panel">
        <div className="finance-panel-title">
          <div>
            <h2>Xu hướng dòng tiền 5 tuần gần đây</h2>
            <p>So sánh giá trị yêu cầu ví kỹ thuật viên và tiền COD phát sinh theo tuần.</p>
          </div>
          <div className="finance-legend">
            <span>
              <i className="wallet-bar" />
              Yêu cầu ví
            </span>
            <span>
              <i className="cod-bar" />
              Thu COD
            </span>
          </div>
        </div>
        <div className="finance-chart">
          {walletWeeks.map((week, index) => (
            <div className="finance-chart-group" key={week.label}>
              <div className="finance-bars">
                <i
                  className="wallet-bar"
                  style={{ height: (week.amount / peak) * 100 + '%' }}
                  title={money(week.amount)}
                />
                <i
                  className="cod-bar"
                  style={{ height: (codWeeks[index].amount / peak) * 100 + '%' }}
                  title={money(codWeeks[index].amount)}
                />
              </div>
              <span>{week.label}</span>
            </div>
          ))}
        </div>
      </section>
      <div className="finance-bottom-grid">
        <section className="finance-panel">
          <div className="finance-panel-title">
            <div>
              <h2>Giao dịch gần đây cần xử lý</h2>
              <p>Các yêu cầu ví và khoản COD chưa được đối soát.</p>
            </div>
            <Link className="text-link" to="/finance">
              Mở xử lý <ArrowRight size={15} />
            </Link>
          </div>
          {recent.length ? (
            <div className="finance-transaction-list">
              {recent.map((item) => (
                <Link to="/finance" className="finance-transaction" key={item.type + '-' + item.id}>
                  <span className={'finance-dot ' + item.type} />
                  <b>
                    {item.name || 'Kỹ thuật viên'} · {item.type === 'wallet' ? 'Ví KTV' : 'COD'} ·{' '}
                    {money(item.amount)}
                  </b>
                  <small>{item.status}</small>
                </Link>
              ))}
            </div>
          ) : (
            <Empty
              title="Không có giao dịch chờ xử lý"
              text="Các yêu cầu mới sẽ xuất hiện tại đây."
            />
          )}
        </section>
        <section className="finance-panel finance-alert-panel">
          <div className="finance-panel-title">
            <div>
              <h2>Cảnh báo tài chính</h2>
              <p>Ưu tiên xử lý các khoản tiền mặt cần đối soát.</p>
            </div>
          </div>
          <div className={pendingCod.length ? 'finance-alert warning' : 'finance-alert success'}>
            <AlertTriangle size={20} />
            <span>
              {pendingCod.length
                ? `${pendingCod.length} lệnh COD đang chờ đối soát. Mở đối soát để kiểm tra và xử lý.`
                : 'Chưa có lệnh COD quá hạn hoặc chờ đối soát.'}
            </span>
          </div>
        </section>
      </div>
    </div>
  );
}
function FinanceKpi({ label, value, detail, tone }) {
  const icons = { navy: BarChart3, green: ReceiptText, orange: Wallet, red: ArrowDownUp };
  const Icon = icons[tone];
  return (
    <article className={'finance-kpi ' + tone}>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
        <small>{detail}</small>
      </div>
      <Icon size={26} />
    </article>
  );
}
function ExecutiveDashboard() {
  const { toast } = useApp(),
    summary = useData('/reports/summary', 15000),
    technicians = useData('/reports/technicians', 15000);
  const techs = technicians.data || [],
    topTechs = [...techs]
      .sort((a, b) => Number(b.completedOrders || 0) - Number(a.completedOrders || 0))
      .slice(0, 5),
    activeTechs = techs.filter((tech) => tech.availability === 'SanSang').length,
    averageRating = techs.length
      ? techs.reduce((total, tech) => total + Number(tech.averageRating || 0), 0) /
        techs.filter((tech) => tech.averageRating).length
      : 0;
  const monthData = executiveMonths(summary.data?.trend || []),
    maximum = Math.max(1, ...monthData.flatMap((item) => [item.revenue, item.profit]));
  return (
    <div className="executive-dashboard">
      <div className="executive-heading">
        <div>
          <div className="breadcrumb-text">
            HomeFix <span>›</span> Tổng quan điều hành
          </div>
          <h1>Executive Dashboard - Chỉ số KPI & Doanh thu</h1>
          <p>Hệ thống báo cáo vận hành và phân tích xu hướng dịch vụ của nền tảng.</p>
        </div>
      </div>
      <ErrorBox error={summary.error || technicians.error} />
      <section className="executive-kpis">
        <ExecutiveKpi
          label="Tổng doanh thu tháng"
          value={money(summary.data?.gmv)}
          note={`${summary.data?.paidOrders || 0} đơn đã thanh toán`}
          icon={TrendingUp}
          tone="green"
        />
        <ExecutiveKpi
          label="Lợi nhuận ròng"
          value={money(summary.data?.commissionRevenue)}
          note="Hoa hồng đã đối soát"
          icon={Wallet}
          tone="teal"
        />
        <ExecutiveKpi
          label="Tổng số đơn hoàn thành"
          value={`${summary.data?.completedOrders || 0} đơn`}
          note={`Tỷ lệ hoàn thành ${summary.data?.totalOrders ? Math.round((summary.data.completedOrders / summary.data.totalOrders) * 100) : 0}%`}
          icon={ClipboardCheck}
          tone="blue"
        />
        <ExecutiveKpi
          label="Điểm đánh giá TB hệ thống"
          value={
            summary.data?.averageRating
              ? `${Number(summary.data.averageRating).toFixed(1)} / 5.0`
              : 'Chưa có'
          }
          note="Đánh giá từ khách hàng"
          icon={Star}
          tone="orange"
        />
      </section>
      <section className="executive-main-grid">
        <div className="executive-chart-card">
          <div className="executive-card-head">
            <div>
              <h2>Xu hướng doanh thu & lợi nhuận 6 tháng</h2>
              <p>Biểu đồ tổng hợp dòng tiền thực tế theo thời gian thực</p>
            </div>
            <div className="executive-legend">
              <span>
                <i className="revenue-line" />
                Doanh thu
              </span>
              <span>
                <i className="profit-line" />
                Lợi nhuận
              </span>
            </div>
          </div>
          <ExecutiveChart rows={monthData} maximum={maximum} />
        </div>
        <div className="executive-operation-card">
          <h2>Tổng quan vận hành</h2>
          <ExecutiveSignal
            icon={UsersRound}
            label={`${techs.length} Kỹ thuật viên`}
            text={`${activeTechs} thợ sẵn sàng nhận việc`}
            tone="teal"
          />
          <ExecutiveSignal
            icon={TrendingUp}
            label={`${activeTechs} KTV hoạt động tích cực`}
            text="Theo trạng thái sẵn sàng hiện tại"
            tone="blue"
          />
          <ExecutiveSignal
            icon={ShieldCheck}
            label={`Tỷ lệ hoàn thành ${summary.data?.totalOrders ? Math.round((summary.data.completedOrders / summary.data.totalOrders) * 100) : 0}%`}
            text="Dựa trên toàn bộ đơn phát sinh"
            tone="green"
          />
        </div>
      </section>
      <section className="executive-bottom-grid">
        <div className="executive-table-card">
          <div className="executive-card-head">
            <div>
              <h2>Top 5 Kỹ thuật viên xuất sắc trong tháng</h2>
              <p>Bảng xếp hạng theo đơn hoàn thành và chất lượng dịch vụ</p>
            </div>
            <Link to="/reports?tab=quality" className="text-link">
              Xem toàn bộ KTV <ArrowRight size={15} />
            </Link>
          </div>
          <div className="executive-table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Hạng</th>
                  <th>Mã KTV</th>
                  <th>Họ và tên</th>
                  <th>Đơn hoàn thành</th>
                  <th>Đánh giá</th>
                  <th>Trạng thái</th>
                </tr>
              </thead>
              <tbody>
                {topTechs.length ? (
                  topTechs.map((tech, index) => (
                    <tr key={tech.id}>
                      <td>{index + 1}</td>
                      <td>KTV-{tech.id}</td>
                      <td>
                        <b>{tech.fullName}</b>
                      </td>
                      <td>{tech.completedOrders || 0} đơn</td>
                      <td className="executive-rating">
                        {tech.averageRating ? Number(tech.averageRating).toFixed(2) : '—'}{' '}
                        <Star size={13} />
                      </td>
                      <td>{labels[tech.availability]}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="6" className="executive-empty">
                      Chưa có dữ liệu kỹ thuật viên.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
        <div className="executive-policy-card">
          <h2>Chính sách chờ phê duyệt</h2>
          <ExecutivePolicy
            title="Điều chỉnh chính sách chiết khấu 18% → 15%"
            text="Yêu cầu bộ phận vận hành xem xét hiệu quả."
          />
          <ExecutivePolicy
            title="Cập nhật bảng giá sản phẩm vệ sinh thiết bị"
            text="Đề xuất thay đổi đơn giá dịch vụ định kỳ."
          />
          <ExecutivePolicy
            title="Chương trình ưu đãi Khách hàng mới tháng 10"
            text="Đề xuất từ bộ phận Marketing."
          />
        </div>
      </section>
      <div className="executive-actions">
        <Link className="btn" to="/reports">
          <FileText size={17} /> Xuất báo cáo tổng
        </Link>
        <button
          className="btn primary"
          onClick={() => toast('Đã ghi nhận phê duyệt báo cáo kỳ hiện tại.')}
        >
          <CheckCircle2 size={17} /> Phê duyệt báo cáo tài chính
        </button>
      </div>
    </div>
  );
}
function ExecutiveKpi({ label, value, note, icon: Icon, tone }) {
  return (
    <article className={'executive-kpi ' + tone}>
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
        <span>{note}</span>
      </div>
      <Icon size={20} />
    </article>
  );
}
function ExecutiveSignal({ icon: Icon, label, text, tone }) {
  return (
    <div className={'executive-signal ' + tone}>
      <Icon size={18} />
      <div>
        <b>{label}</b>
        <small>{text}</small>
      </div>
    </div>
  );
}
function ExecutivePolicy({ title, text }) {
  return (
    <article>
      <b>{title}</b>
      <small>{text}</small>
      <Link to="/?tab=policies">
        Xem chi tiết <ArrowRight size={13} />
      </Link>
    </article>
  );
}
function executiveMonths(trend) {
  const months = Array.from({ length: 6 }, (_, index) => {
    const date = new Date();
    date.setDate(1);
    date.setMonth(date.getMonth() - (5 - index));
    return {
      key: `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`,
      label: `T${date.getMonth() + 1}`,
      revenue: 0,
      profit: 0,
    };
  });
  for (const item of trend) {
    const month = String(item.day || '').slice(0, 7),
      target = months.find((entry) => entry.key === month);
    if (target) {
      target.revenue += Number(item.amount || 0);
      target.profit += Number(item.amount || 0) * 0.15;
    }
  }
  return months;
}
function ExecutiveChart({ rows, maximum }) {
  const points = (key) =>
    rows.map((row, index) => `${20 + index * 88},${164 - (row[key] / maximum) * 130}`).join(' ');
  return (
    <div className="executive-chart">
      <svg
        viewBox="0 0 480 190"
        preserveAspectRatio="none"
        aria-label="Biểu đồ doanh thu và lợi nhuận"
      >
        <path className="chart-grid" d="M20 35H460M20 78H460M20 121H460M20 164H460" />
        <polyline className="chart-revenue" points={points('revenue')} />
        <polyline className="chart-profit" points={points('profit')} />
      </svg>
      <div className="executive-chart-labels">
        {rows.map((row) => (
          <span key={row.key}>{row.label}</span>
        ))}
      </div>
    </div>
  );
}
export function PolicyApproval() {
  const { toast } = useApp(),
    [proposals, setProposals] = useState([
      {
        id: 'CS-10222',
        title: 'Điều chỉnh chiết khấu dịch vụ Điện nước từ 18% → 15%',
        department: 'Đề xuất: Lê Anh Tuấn',
        submittedAt: 'Hôm nay, 10:42',
        group: 'Điện nước',
        currentDiscount: '18.0%',
        proposedDiscount: '15.0%',
        currentBonus: '2.0% / đơn',
        proposedBonus: '3.5% / đơn',
        impact:
          'Dự báo tăng trưởng biên lợi nhuận ròng +2.4% cho nhóm dịch vụ kỹ thuật điện nước. Chính sách mới kỳ vọng tăng 12% lượng đơn hoàn thành do thu hút được đội ngũ kỹ thuật viên chất lượng cao.',
        reason:
          'Các hệ số chiết khấu hiện tại đang làm giảm động lực đăng ký mới của đội ngũ KTV, đề xuất giảm mức chiết khấu để tăng thưởng trực tiếp trên mỗi ca hoàn thành xuất sắc.',
      },
      {
        id: 'CS-10223',
        title: 'Cập nhật bảng giá sản phẩm Vệ sinh thiết bị',
        department: 'Người gửi: Đỗ Văn An',
        submittedAt: 'Hôm qua, 15:30',
        group: 'Vệ sinh & bảo trì',
        currentDiscount: '12.0%',
        proposedDiscount: '10.0%',
        currentBonus: '1.5% / đơn',
        proposedBonus: '2.0% / đơn',
        impact: 'Điều chỉnh phù hợp với biến động giá vật tư vệ sinh và duy trì mức cạnh tranh.',
        reason: 'Bảng giá vật tư đã được rà soát theo nhà cung cấp mới.',
      },
      {
        id: 'CS-10224',
        title: 'Chương trình ưu đãi Khách hàng mới tháng 11',
        department: 'Người gửi: Nguyễn Thị Hằng',
        submittedAt: '22/10/2026',
        group: 'Marketing',
        currentDiscount: '0%',
        proposedDiscount: '10%',
        currentBonus: '—',
        proposedBonus: '—',
        impact: 'Dự kiến tăng lượng khách hàng mới và tỷ lệ đặt dịch vụ lần đầu.',
        reason: 'Áp dụng mã giảm giá cho khách hàng lần đầu sử dụng HomeFix.',
      },
    ]),
    [selectedId, setSelectedId] = useState('CS-10222'),
    [note, setNote] = useState(''),
    [effectiveAt, setEffectiveAt] = useState('tomorrow');
  const selected = proposals.find((proposal) => proposal.id === selectedId) || proposals[0];
  const decide = (status) => {
    setProposals((items) => items.filter((item) => item.id !== selected.id));
    toast(
      status === 'approved'
        ? `Đã phê duyệt ${selected.id}.`
        : status === 'revision'
          ? `Đã gửi yêu cầu chỉnh sửa ${selected.id}.`
          : `Đã từ chối ${selected.id}.`,
    );
    setNote('');
  };
  return (
    <div className="policy-approval">
      <div className="policy-heading">
        <div>
          <div className="breadcrumb-text">
            HomeFix <span>›</span> Phê duyệt chính sách
          </div>
          <h1>Phê duyệt chính sách & Bảng giá mới</h1>
          <p>
            Xem xét các đề xuất điều chỉnh giá sản phẩm, chiết khấu và cơ chế thưởng cho kỹ thuật
            viên.
          </p>
        </div>
      </div>
      <div className="policy-layout">
        <section className="policy-list">
          <h2>Danh sách đề xuất chờ duyệt</h2>
          {proposals.length ? (
            proposals.map((proposal) => (
              <button
                type="button"
                key={proposal.id}
                className={proposal.id === selected.id ? 'selected' : ''}
                onClick={() => setSelectedId(proposal.id)}
              >
                <span>Chờ duyệt</span>
                <b>{proposal.title}</b>
                <small>
                  {proposal.department}
                  <em>{proposal.submittedAt}</em>
                </small>
                <i>
                  Đang chọn <ArrowRight size={13} />
                </i>
              </button>
            ))
          ) : (
            <Empty
              title="Không còn đề xuất chờ duyệt"
              text="Các đề xuất mới sẽ xuất hiện tại đây."
            />
          )}
        </section>
        {selected && (
          <section className="policy-detail">
            <div className="policy-detail-head">
              <div>
                <h2>Chi tiết đề xuất {selected.id}</h2>
                <small>Bảng so sánh giá & chiết khấu</small>
              </div>
              <small>Ngày gửi: {selected.submittedAt}</small>
            </div>
            <div className="policy-compare">
              <div className="policy-compare-head">
                <span>Hạng mục</span>
                <span>Hiện tại</span>
                <span>Đề xuất mới</span>
              </div>
              <div>
                <b>Chiết khấu dịch vụ</b>
                <span>{selected.currentDiscount}</span>
                <strong>{selected.proposedDiscount}</strong>
              </div>
              <div>
                <b>Thưởng hiệu suất</b>
                <span>{selected.currentBonus}</span>
                <strong>{selected.proposedBonus}</strong>
              </div>
            </div>
            <div className="policy-impact">
              <b>Dự báo tăng trưởng biên lợi nhuận ròng</b>
              <p>{selected.impact}</p>
            </div>
            <div className="policy-readonly">
              <b>Ghi chú người đề xuất</b>
              <p>{selected.reason}</p>
            </div>
            <label className="policy-note">
              Ý kiến phê duyệt / Chỉ đạo
              <textarea
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder="Nhập chỉ đạo hoặc yêu cầu chỉnh sửa chính sách..."
              />
            </label>
            <label className="policy-effective">
              Thời gian áp dụng
              <select value={effectiveAt} onChange={(event) => setEffectiveAt(event.target.value)}>
                <option value="tomorrow">Áp dụng sau 00h00 ngày hôm sau</option>
                <option value="week">Áp dụng từ đầu tuần sau</option>
                <option value="month">Áp dụng từ đầu tháng sau</option>
              </select>
            </label>
            <div className="policy-actions">
              <button className="btn danger" onClick={() => decide('rejected')}>
                Từ chối
              </button>
              <button className="btn warning" onClick={() => decide('revision')}>
                Yêu cầu sửa
              </button>
              <button className="btn primary" onClick={() => decide('approved')}>
                <CheckCircle2 size={17} /> Phê duyệt
              </button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
function StaffHome() {
  const { user } = useApp();
  const summary = useData('/reports/summary', 15000),
    orders = useData(['DPV', 'CSKH'].includes(user.role) ? '/orders?pageSize=8' : null),
    users = useData(user.role === 'ADMIN' ? '/users' : null);
  const targets = {
    DPV: ['/orders', 'Mở bàn điều phối'],
    CSKH: ['/support', 'Xử lý yêu cầu hỗ trợ'],
    KT: ['/finance', 'Mở đối soát & ví'],
    ADMIN: ['/admin/users', 'Quản lý tài khoản'],
    GD: ['/reports', 'Xem báo cáo chi tiết'],
  };
  return (
    <>
      <PageHead
        eyebrow="TỔNG QUAN HOẠT ĐỘNG"
        title={`Xin chào, ${user.fullName.split(' ').at(-1)}`}
        text="Dữ liệu cập nhật từ các đơn dịch vụ trong hệ thống."
      >
        <Link className="btn primary" to={targets[user.role][0]}>
          {targets[user.role][1]} <ArrowRight size={17} />
        </Link>
      </PageHead>
      <ErrorBox error={summary.error} />
      {summary.data && (
        <div className="stat-grid">
          <Stat label="Tổng đơn dịch vụ" value={summary.data.totalOrders} />
          <Stat label="Đã hoàn thành" value={summary.data.completedOrders} icon={ShieldCheck} />
          <Stat label="Giá trị đơn đã thu" value={money(summary.data.gmv)} icon={Wallet} />
          <Stat
            label="Hoa hồng đã đối soát"
            value={money(summary.data.commissionRevenue)}
            icon={Star}
          />
        </div>
      )}
      <div className="two-column">
        <Card title={user.role === 'ADMIN' ? 'Tài khoản hệ thống' : 'Đơn dịch vụ gần đây'}>
          {user.role === 'ADMIN' ? (
            <>
              <p>Quản lý tài khoản và quyền truy cập theo bảy vai trò nghiệp vụ.</p>
              <strong className="big-number">{users.data?.length ?? '—'}</strong>
              <p>Tài khoản đang được quản lý</p>
              <Link to="/admin/users" className="btn">
                Xem danh sách <ArrowRight size={16} />
              </Link>
            </>
          ) : orders.data?.length ? (
            orders.data.slice(0, 4).map((o) => <OrderCard key={o.id} order={o} />)
          ) : (
            <Empty
              title="Mọi thứ sẵn sàng"
              text="Dữ liệu mới xuất hiện khi khách đặt và hoàn tất dịch vụ."
            />
          )}
        </Card>
        <Card title="Luồng phục vụ khách hàng">
          <ol className="workflow-list">
            {[
              'Tiếp nhận yêu cầu & báo giá',
              'Khách duyệt và điều phối thợ',
              'Sửa chữa & duyệt vật tư',
              'Nghiệm thu, thu COD & đánh giá',
            ].map((s, i) => (
              <li key={s}>
                <span>{i + 1}</span>
                <div>
                  <b>{s}</b>
                  <small>
                    {
                      [
                        'Kiểm tra thông tin và ảnh lỗi',
                        'Đúng chuyên môn, đúng quyền',
                        'Mọi phát sinh đều được xác nhận',
                        'Đối soát hoa hồng đúng một lần',
                      ][i]
                    }
                  </small>
                </div>
              </li>
            ))}
          </ol>
        </Card>
      </div>
    </>
  );
}
export function Services() {
  const s = useData('/services');
  const [group, setGroup] = useState('all'),
    [search, setSearch] = useState('');
  return (
    <>
      <PageHead
        eyebrow="DỊCH VỤ TẠI NHÀ"
        title="Bạn cần HomeFix hỗ trợ gì?"
        text="Chọn dịch vụ phù hợp. Báo giá chính thức sẽ được gửi để bạn xác nhận trước khi phân công thợ."
      />
      <div className="filter-bar" style={{ marginBottom: '1rem' }}>
        <Field label="">
          <input
            type="text"
            placeholder="Tìm kiếm dịch vụ (ví dụ: Sửa máy lạnh...)"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ minWidth: '300px' }}
          />
        </Field>
      </div>
      <div className="tabs">
        <button className={group === 'all' ? 'active' : ''} onClick={() => setGroup('all')}>
          Tất cả dịch vụ
        </button>
        {Object.entries(groups).map(([key, name]) => (
          <button key={key} className={group === key ? 'active' : ''} onClick={() => setGroup(key)}>
            {name}
          </button>
        ))}
      </div>
      <ErrorBox error={s.error} />
      {s.loading ? (
        <Loading />
      ) : (
        <ServiceCards
          services={(s.data || []).filter(
            (x) =>
              (group === 'all' || x.groupCode === group) &&
              x.name.toLowerCase().includes(search.toLowerCase()),
          )}
        />
      )}
    </>
  );
}
export function Booking() {
  const { serviceId } = useParams(),
    { user } = useApp(),
    navigate = useNavigate();
  const services = useData('/services'),
    policy = useData('/app-config'),
    a = useAction();
  const [form, setForm] = useState({
      address: user.defaultAddress || '',
      description: '',
      scheduledAt: '',
    }),
    [files, setFiles] = useState([]);
  const uploaded = useRef(new Map()),
    intent = useRef(null);
  const service = services.data?.find((s) => s.id === Number(serviceId));
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));
  async function submit(e) {
    e.preventDefault();
    await a.run(async () => {
      const ids = [];
      for (const file of files) {
        if (!uploaded.current.has(file))
          uploaded.current.set(file, (await upload(file, 'OrderFault')).id);
        ids.push(uploaded.current.get(file));
      }
      const body = {
        serviceId: Number(serviceId),
        address: form.address,
        description: form.description,
        scheduledAt: form.scheduledAt ? new Date(form.scheduledAt).toISOString() : null,
        attachmentIds: ids,
      };
      const sig = JSON.stringify(body);
      if (intent.current?.sig !== sig) intent.current = { sig, key: uuid() };
      const r = await api('/orders', { method: 'POST', body, key: intent.current.key });
      navigate('/orders/' + r.data.id);
    }, 'Đặt dịch vụ thành công.');
  }
  return (
    <>
      <PageHead
        eyebrow="ĐẶT DỊCH VỤ"
        title={service?.name || 'Thông tin yêu cầu'}
        text="Một đơn phục vụ một thiết bị. Bạn chỉ thanh toán sau khi nghiệm thu."
      />
      <ErrorBox error={services.error} />
      {services.loading ? (
        <Loading />
      ) : !service ? (
        <Empty title="Dịch vụ không còn được cung cấp" />
      ) : (
        <form onSubmit={submit} className="two-column booking-layout">
          <Card title="Thông tin đặt lịch">
            <div className="contact-summary">
              <span className="avatar">{user.fullName.slice(0, 1)}</span>
              <div>
                <b>{user.fullName}</b>
                <small>{user.phone}</small>
                <Link to="/profile">Chỉnh sửa thông tin liên hệ</Link>
              </div>
            </div>
            <Field
              label="Địa chỉ thực hiện"
              hint="Ghi rõ số nhà, đường, phường và TP.HCM để điều phối đúng khu vực."
            >
              <textarea
                required
                minLength={10}
                maxLength={500}
                value={form.address}
                onChange={(e) => set('address', e.target.value)}
                placeholder="Ví dụ: 1 Võ Văn Ngân, Thủ Đức, TP.HCM"
              />
            </Field>
            <Field label="Thiết bị gặp vấn đề gì?">
              <textarea
                required
                minLength={5}
                maxLength={2000}
                value={form.description}
                onChange={(e) => set('description', e.target.value)}
                placeholder="Mô tả hiện tượng, loại thiết bị và thông tin cần lưu ý…"
                rows={4}
              />
            </Field>
            <Field
              label="Lịch hẹn (để trống nếu cần sớm nhất)"
              hint="08:00–17:30, khung 30 phút; đặt trước ít nhất 30 phút, tối đa 30 ngày."
            >
              <input
                type="datetime-local"
                step="1800"
                value={form.scheduledAt}
                onChange={(e) => set('scheduledAt', e.target.value)}
              />
            </Field>
            <Field
              label="Ảnh tình trạng thiết bị"
              hint="Tối đa 5 ảnh JPG/PNG, mỗi ảnh không quá 5 MB."
            >
              <input
                type="file"
                accept="image/jpeg,image/png"
                multiple
                onChange={(e) => {
                  const chosen = [...e.target.files];
                  if (chosen.length > 5 || chosen.some((f) => f.size > 5242880)) {
                    a.setError(new Error('Chọn tối đa 5 ảnh, mỗi ảnh không quá 5 MB.'));
                    e.target.value = '';
                    return;
                  }
                  setFiles(chosen);
                  a.setError(null);
                }}
              />
            </Field>
            {files.length > 0 && <small>Đã chọn {files.length} ảnh.</small>}
            <ErrorBox error={a.error} />
            <div className="form-actions">
              <Link className="btn" to="/services">
                Quay lại
              </Link>
              <Submit busy={a.busy}>Gửi yêu cầu đặt dịch vụ</Submit>
            </div>
          </Card>
          <aside>
            <Card title="Chi phí tham khảo">
              <div className="money-lines">
                <div>
                  <span>Phí kiểm tra</span>
                  <b>{money(service.inspectionFee)}</b>
                </div>
                <div>
                  <span>Tiền công</span>
                  <b>{money(service.laborFee)}</b>
                </div>
              </div>
              <div className="notice info">
                <ShieldCheck size={20} />
                <p>
                  Điều phối viên gửi báo giá để bạn duyệt. Vật tư phát sinh chỉ được tính khi bạn
                  đồng ý.
                </p>
              </div>
              <p className="policy-note">
                Miễn phí hủy trước khi thợ xuất phát. Hủy lúc thợ đang di chuyển:{' '}
                {policy.data ? money(policy.data.cancellationFee) : 'đang tải mức phí'}. Khi thợ đã
                đến nơi, liên hệ hỗ trợ để xử lý.
              </p>
              <ul className="check-list">
                <li>
                  <Check />
                  Theo dõi tiến độ trong ứng dụng
                </li>
                <li>
                  <Check />
                  Xác nhận nghiệm thu bằng tài khoản
                </li>
                <li>
                  <Check />
                  Thanh toán tiền mặt hoặc chuyển khoản
                </li>
              </ul>
            </Card>
          </aside>
        </form>
      )}
    </>
  );
}
export function Orders() {
  const { user } = useApp();
  const [status, setStatus] = useState(''),
    [page, setPage] = useState(1);
  const r = useData(
    '/orders?pageSize=20&page=' + page + (status ? '&status=' + status : ''),
    10000,
  );
  return (
    <>
      <PageHead
        eyebrow={user.role === 'KH' ? 'DỊCH VỤ CỦA BẠN' : 'QUẢN LÝ CÔNG VIỆC'}
        title={user.role === 'KH' ? 'Đơn dịch vụ của tôi' : 'Danh sách đơn dịch vụ'}
        text="Mở một đơn để xem thông tin và thực hiện bước tiếp theo."
      >
        {user.role === 'KH' && (
          <Link className="btn primary" to="/services">
            <Plus size={18} /> Đặt dịch vụ
          </Link>
        )}
        <button className="btn" onClick={r.reload}>
          <RefreshCw size={16} /> Cập nhật
        </button>
      </PageHead>
      <div className="filter-bar">
        <Field label="Trạng thái">
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setPage(1);
            }}
          >
            <option value="">Tất cả trạng thái</option>
            {Object.entries(labels)
              .slice(0, 11)
              .map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
          </select>
        </Field>
        <span>Trang {page}</span>
      </div>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : r.data?.length ? (
        <div className="order-list">
          {r.data.map((o) => (
            <OrderCard key={o.id} order={o} />
          ))}
        </div>
      ) : (
        <Empty title="Chưa có đơn phù hợp" text="Thử chọn trạng thái khác hoặc đặt dịch vụ mới." />
      )}
      <div className="pagination">
        <button className="btn" disabled={page === 1} onClick={() => setPage((p) => p - 1)}>
          Trang trước
        </button>
        <button
          className="btn"
          disabled={!r.data || r.data.length < 20}
          onClick={() => setPage((p) => p + 1)}
        >
          Trang sau
        </button>
      </div>
    </>
  );
}
export function Profile() {
  const { user, setUser, logout } = useApp(),
    r = useData('/users/me'),
    a = useAction();
  const [form, setForm] = useState(null),
    [contactPassword, setContactPassword] = useState('');
  useEffect(() => {
    if (r.data)
      setForm({
        fullName: r.data.fullName,
        email: r.data.email || '',
        defaultAddress: r.data.defaultAddress || '',
      });
  }, [r.data]);
  return (
    <>
      <PageHead
        eyebrow="TÀI KHOẢN HOMEFIX"
        title="Thông tin cá nhân"
        text="Giữ thông tin liên hệ chính xác để việc phục vụ được thuận tiện."
      />
      <ErrorBox error={r.error || a.error} />
      {form && (
        <div className="two-column">
          <Card title="Hồ sơ của bạn">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                a.run(async () => {
                  const result = await api('/users/me', {
                    method: 'PATCH',
                    body: {
                      ...form,
                      email: form.email || null,
                      ...(form.email !== (r.data.email || '')
                        ? { currentPassword: contactPassword }
                        : {}),
                      expectedVersion: r.data.version,
                    },
                  });
                  setUser(result.data);
                  setContactPassword('');
                  r.reload();
                });
              }}
            >
              <div className="profile-heading">
                <span className="avatar large">{user.fullName.slice(0, 1)}</span>
                <div>
                  <h3>{user.fullName}</h3>
                  <span className="badge green">{roleNames[user.role]}</span>
                </div>
              </div>
              <Field label="Họ và tên">
                <input
                  required
                  value={form.fullName}
                  onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                />
              </Field>
              <Field label="Số điện thoại đăng nhập">
                <input readOnly value={user.phone} />
              </Field>
              <Field label="Email">
                <input
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                />
              </Field>
              {form.email !== (r.data.email || '') && (
                <Field label="Mật khẩu hiện tại để thay đổi email">
                  <input
                    required
                    type="password"
                    autoComplete="current-password"
                    value={contactPassword}
                    onChange={(e) => setContactPassword(e.target.value)}
                  />
                </Field>
              )}
              <Field label="Địa chỉ mặc định">
                <textarea
                  value={form.defaultAddress}
                  onChange={(e) => setForm({ ...form, defaultAddress: e.target.value })}
                />
              </Field>
              <Submit busy={a.busy}>Lưu thông tin</Submit>
            </form>
          </Card>
          <div>
            <Card title="Đổi mật khẩu">
              <PasswordChange user={r.data || user} logout={logout} />
            </Card>
            {user.role === 'KH' && (
              <Card title="Trở thành kỹ thuật viên">
                <p>Bạn có kinh nghiệm sửa chữa? Gửi hồ sơ chuyên môn để quản trị viên xét duyệt.</p>
                <Link to="/applications" className="btn">
                  Đăng ký cộng tác
                </Link>
              </Card>
            )}
            <button className="btn danger full" onClick={logout}>
              Đăng xuất tài khoản
            </button>
          </div>
        </div>
      )}
    </>
  );
}

const BaseProfile = Profile;
Profile = function ProfileWithAvatar() {
  const { user } = useApp(),
    [menu, setMenu] = useState(null),
    [viewing, setViewing] = useState(false),
    [editing, setEditing] = useState(false);
  const openMenu = (event) => {
    const avatar = event.target.closest('.profile-heading .avatar');
    if (!avatar) return;
    const bounds = avatar.getBoundingClientRect();
    setMenu({ top: bounds.bottom + 8, left: bounds.left });
  };
  return (
    <div
      className="profile-avatar-wrapper"
      style={user.avatarUrl ? { '--profile-avatar': `url(${user.avatarUrl})` } : undefined}
      onClick={openMenu}
    >
      <BaseProfile />
      {menu && (
        <AvatarMenu
          position={menu}
          onClose={() => setMenu(null)}
          onView={() => {
            setMenu(null);
            setViewing(true);
          }}
          onEdit={() => {
            setMenu(null);
            setEditing(true);
          }}
        />
      )}
      {viewing && <AvatarViewer onClose={() => setViewing(false)} />}
      {editing && <AvatarDialog onClose={() => setEditing(false)} />}
    </div>
  );
};
function AvatarMenu({ position, onClose, onView, onEdit }) {
  useEffect(() => {
    const close = (event) => {
      if (!event.target.closest('.avatar-actions-menu')) onClose();
    };
    window.addEventListener('mousedown', close);
    return () => window.removeEventListener('mousedown', close);
  }, [onClose]);
  return (
    <div className="avatar-actions-menu" style={position}>
      <button type="button" onClick={onView}>
        Xem ảnh đại diện
      </button>
      <button type="button" onClick={onEdit}>
        Chỉnh sửa ảnh đại diện
      </button>
    </div>
  );
}
function AvatarViewer({ onClose }) {
  const { user } = useApp();
  return (
    <div className="avatar-viewer-backdrop" role="presentation" onClick={onClose}>
      {user.avatarUrl ? (
        <img
          className="avatar-viewer-image"
          src={user.avatarUrl}
          alt="Ảnh đại diện"
          onClick={(event) => event.stopPropagation()}
        />
      ) : (
        <span className="avatar large">{user.fullName.slice(0, 1)}</span>
      )}
    </div>
  );
}
function AvatarDialog({ onClose }) {
  const { user, setUser } = useApp(),
    action = useAction(),
    input = useRef(null);
  const choose = (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    if (!['image/jpeg', 'image/png'].includes(file.type) || file.size > 5242880) {
      action.setError(new Error('Chỉ chọn ảnh JPG hoặc PNG, dung lượng tối đa 5 MB.'));
      return;
    }
    action.run(async () => {
      const uploaded = await upload(file, 'Avatar');
      setUser((current) => ({ ...current, avatarUrl: uploaded.downloadPath }));
      onClose();
    }, 'Đã cập nhật ảnh đại diện.');
  };
  return (
    <div
      className="modal-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <section
        className="modal avatar-dialog"
        role="dialog"
        aria-modal="true"
        aria-label="Đổi ảnh đại diện"
      >
        <header>
          <h2>Đổi ảnh đại diện</h2>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Đóng">
            ×
          </button>
        </header>
        <div className="avatar-dialog-body">
          {user.avatarUrl ? (
            <img className="avatar-preview" src={user.avatarUrl} alt="Ảnh đại diện hiện tại" />
          ) : (
            <span className="avatar large">{user.fullName.slice(0, 1)}</span>
          )}
          <p>Chọn ảnh JPG hoặc PNG, dung lượng tối đa 5 MB.</p>
          <button
            type="button"
            className="btn primary"
            disabled={action.busy}
            onClick={() => input.current?.click()}
          >
            Chọn ảnh mới
          </button>
          <input ref={input} hidden type="file" accept="image/jpeg,image/png" onChange={choose} />
          <ErrorBox error={action.error} />
        </div>
      </section>
    </div>
  );
}
function AvatarSettings() {
  const { user, setUser } = useApp(),
    action = useAction(),
    input = useRef(null);
  const choose = (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    if (!['image/jpeg', 'image/png'].includes(file.type) || file.size > 5242880) {
      action.setError(new Error('Chỉ chọn ảnh JPG hoặc PNG, dung lượng tối đa 5 MB.'));
      return;
    }
    action.run(async () => {
      const uploaded = await upload(file, 'Avatar');
      setUser((current) => ({ ...current, avatarUrl: uploaded.downloadPath }));
    }, 'Đã cập nhật ảnh đại diện.');
  };
  return (
    <Card title="Ảnh đại diện" className="avatar-settings">
      <div className="avatar-settings-row">
        {user.avatarUrl ? (
          <img className="avatar-preview" src={user.avatarUrl} alt="Ảnh đại diện" />
        ) : (
          <span className="avatar large">{user.fullName.slice(0, 1)}</span>
        )}
        <div>
          <b>Ảnh đại diện của bạn</b>
          <small>Chọn ảnh JPG hoặc PNG, tối đa 5 MB.</small>
          <button
            type="button"
            className="btn"
            disabled={action.busy}
            onClick={() => input.current?.click()}
          >
            Chọn ảnh mới
          </button>
          <input ref={input} hidden type="file" accept="image/jpeg,image/png" onChange={choose} />
        </div>
      </div>
      <ErrorBox error={action.error} />
    </Card>
  );
}
export function Notifications() {
  const r = useData('/notifications', 15000),
    a = useAction();
  return (
    <>
      <PageHead
        eyebrow="CẬP NHẬT MỚI"
        title="Thông báo"
        text="Các thay đổi liên quan đến đơn dịch vụ và tài khoản của bạn."
      />
      <ErrorBox error={r.error || a.error} />
      {r.loading ? (
        <Loading />
      ) : r.data?.length ? (
        <div className="notifications-list">
          {r.data.map((n) => (
            <article className={'notification ' + (!n.readAt ? 'unread' : '')} key={n.id}>
              <div className="notification-icon">
                <Bell size={20} />
              </div>
              <div>
                <h3>{n.title}</h3>
                <p>{n.body}</p>
                <small>{date(n.createdAt)}</small>
                <div className="actions">
                  {n.orderId && (
                    <Link to={'/orders/' + n.orderId} className="text-link">
                      Xem đơn dịch vụ <ArrowRight size={14} />
                    </Link>
                  )}
                  {!n.readAt && (
                    <button
                      className="text-btn"
                      disabled={a.busy}
                      onClick={() =>
                        a.run(async () => {
                          await api('/notifications/' + n.id + '/read', {
                            method: 'PATCH',
                            body: {},
                          });
                          r.reload();
                        }, '')
                      }
                    >
                      Đánh dấu đã đọc
                    </button>
                  )}
                </div>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <Empty title="Chưa có thông báo mới" />
      )}
    </>
  );
}
