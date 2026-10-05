import { RouteMap } from './route-map';
import { ContactActions, PhotoPicker, PhotoPreview, SignaturePad } from './technician-ui';
import { noPaymentDue, displayPaymentStatus } from './payment-status';
import { AttentionDot } from './attention';
import React, { useEffect, useRef, useState } from 'react';
import { Link, useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ArrowRight,
  MapPin,
  Phone,
  Clock,
  Plus,
  Trash2,
  RefreshCw,
  ShieldCheck,
  CheckCircle2,
  Receipt,
  Navigation,
  Star,
} from 'lucide-react';
import { PaymentPanel, PaymentMethodFields } from './payments-ui';
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
  ProtectedImage,
  MoneyBreakdown,
  Modal,
} from './shared';
export function OrderDetail() {
  const { id } = useParams(),
    { user } = useApp(),
    navigate = useNavigate();
  const order = useData('/orders/' + id, 10000),
    history = useData('/orders/' + id + '/history'),
    materials = useData('/orders/' + id + '/material-quotes'),
    acceptances = useData('/orders/' + id + '/acceptances'),
    files = useData(user.role === 'KT' ? null : '/orders/' + id + '/attachments'),
    reviews = useData('/orders/' + id + '/reviews'),
    cfg = useData('/app-config');
  const [modal, setModal] = useState(null);
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);
  const o = order.data;
  const refresh = () => {
    order.reload();
    history.reload();
    materials.reload();
    acceptances.reload();
    files.reload();
    reviews.reload();
  };
  useEffect(() => {
    if (o?.version) {
      history.reload();
      materials.reload();
      acceptances.reload();
      files.reload();
      reviews.reload();
    }
  }, [o?.version]);
  const open = (type, record) => setModal({ type, record, expectedVersion: o.version });
  if (order.loading) return <Loading />;
  if (order.error)
    return (
      <>
        <ErrorBox error={order.error} />
        <Link className="btn" to="/orders">
          Quay lại danh sách
        </Link>
      </>
    );
  if (!o) return null;
  const preliminary = o.currentPreliminaryQuote,
    material = materials.data?.[0],
    acceptance = acceptances.data?.[0],
    assignment = o.currentAssignment;
  const customer = user.role === 'KH',
    tech = user.role === 'KTV',
    dispatcher = user.role === 'DPV';
  const currentTech = tech && o.assignedTechnicianId === user.id;
  const actions = [];
  if (dispatcher && o.status === 'ChoTiepNhan') actions.push(['preliminary', 'Lập báo giá sơ bộ']);
  if (dispatcher && o.status === 'ChoPhanCong') actions.push(['assign', 'Phân công kỹ thuật viên']);
  const pendingAssignment =
    currentTech && o.status === 'ChoNhan' && assignment?.status === 'Pending';
  const expired = pendingAssignment && new Date(assignment.expiresAt).getTime() <= now;
  const next = {
    DaTiepNhan: ['DangDiChuyen', 'Bắt đầu di chuyển'],
    DangDiChuyen: ['DaDenNoi', 'Xác nhận đã đến nơi'],
    DaDenNoi: ['DangXuLy', 'Bắt đầu xử lý'],
  };
  if (currentTech && next[o.status]) actions.push(['progress', next[o.status][1]]);
  if (currentTech && o.status === 'DangXuLy') {
    if (!material || material.status === 'Rejected') actions.push(['material', 'Đề xuất vật tư']);
    if (!material || material.status !== 'Pending')
      actions.push(['acceptance', 'Hoàn thành · Lập phiếu nghiệm thu']);
  }
  if (
    currentTech &&
    o.status === 'HoanThanh' &&
    o.paymentStatus === 'Unpaid' &&
    !noPaymentDue(o) &&
    (o.paymentMethod || 'COD') === 'COD'
  )
    actions.push(['cod', 'Xác nhận đã thu COD']);
  const techStep = ['DaTiepNhan', 'DangDiChuyen'].includes(o.status)
    ? 0
    : o.status === 'DaDenNoi'
      ? 1
      : ['DangXuLy', 'ChoNghiemThu'].includes(o.status)
        ? 2
        : o.status === 'HoanThanh'
          ? 3
          : -1;
  const step = ['ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan'].includes(o.status)
    ? 0
    : ['DaTiepNhan', 'DangDiChuyen'].includes(o.status)
      ? 1
      : ['DaDenNoi', 'DangXuLy', 'ChoNghiemThu'].includes(o.status)
        ? 2
        : 3;
  return (
    <>
      <Link to="/orders" className="back-link">
        <ArrowLeft size={16} /> Danh sách đơn dịch vụ
      </Link>
      <PageHead eyebrow={code(o.id)} title={o.serviceName} text={'Tạo lúc ' + date(o.createdAt)}>
        <Badge value={o.status} />
        <span title={noPaymentDue(o) ? 'Không phát sinh chi phí cần thanh toán' : undefined}>
          <Badge value={displayPaymentStatus(o)} />
        </span>
        <button className="icon-btn" onClick={refresh} aria-label="Tải lại đơn">
          <RefreshCw size={19} />
        </button>
      </PageHead>
      {o.status !== 'Huy' && (
        <div className="order-stepper">
          {(tech
            ? ['Đã nhận', 'Đến nơi', 'Đang làm', 'Hoàn thành']
            : ['Tiếp nhận', 'Di chuyển', 'Xử lý', 'Hoàn thành']
          ).map((s, i) => (
            <div key={s} className={i <= (tech ? techStep : step) ? 'done' : ''}>
              <span>{i < (tech ? techStep : step) ? <CheckCircle2 size={18} /> : i + 1}</span>
              <b>{s}</b>
            </div>
          ))}
        </div>
      )}
      {pendingAssignment && (
        <section className="assignment-response">
          <div>
            <b>Đơn mới cần phản hồi</b>
            <p>Kiểm tra địa chỉ, mô tả và báo giá trước khi quyết định.</p>
          </div>
          <div className="contact-actions">
            <button
              className="btn reject-order"
              disabled={expired}
              onClick={() => open('receive', { decision: 'Rejected' })}
            >
              Từ chối đơn
            </button>
            <button
              className="btn accept-order"
              disabled={expired}
              onClick={() => open('receive', { decision: 'Accepted' })}
            >
              <CheckCircle2 size={18} />
              Chấp nhận đơn
            </button>
          </div>
        </section>
      )}
      {actions.length > 0 && (
        <div className="next-action">
          <div>
            <ShieldCheck size={23} />
            <div>
              <b>Bước tiếp theo</b>
              <small>
                {o.status === 'ChoNhan'
                  ? 'Phản hồi trước khi lệnh hết hạn.'
                  : 'Thực hiện khi đã kiểm tra thông tin công việc.'}
              </small>
            </div>
          </div>
          <div className="actions">
            {actions.map(([type, title], i) => (
              <button
                key={type}
                className={'btn ' + (i === actions.length - 1 ? 'primary' : '')}
                onClick={() => open(type)}
              >
                <AttentionDot />
                {title} <ArrowRight size={16} />
              </button>
            ))}
          </div>
        </div>
      )}
      {o.status === 'ChoNhan' &&
        assignment?.status === 'Pending' &&
        (dispatcher || currentTech) && (
          <Countdown value={assignment.expiresAt} dispatcher={dispatcher} />
        )}
      {customer && o.status === 'ChoDuyetSoBo' && preliminary && (
        <Card title="Báo giá sơ bộ cần bạn xác nhận" className="highlight">
          <p>{preliminary.diagnosis}</p>
          <MoneyBreakdown value={preliminary} />
          <div className="actions">
            <button className="btn danger" onClick={() => open('reject-preliminary', preliminary)}>
              Từ chối báo giá
            </button>
            <button
              className="btn primary"
              onClick={() => open('approve-preliminary', preliminary)}
            >
              <AttentionDot />
              Đồng ý báo giá
            </button>
          </div>
        </Card>
      )}
      {customer && o.status === 'DangXuLy' && material?.status === 'Pending' && (
        <div className="notice warning">
          <ShieldCheck />
          <div>Thợ đề xuất vật tư phát sinh. Xem chi tiết bên dưới rồi duyệt hoặc từ chối.</div>
        </div>
      )}
      {customer && o.status === 'ChoNghiemThu' && acceptance?.status === 'Pending' && (
        <div className="notice warning">
          <ShieldCheck />
          <div>
            Thợ đã gửi phiếu nghiệm thu. Hãy kiểm tra thiết bị và xác nhận ở phần nghiệm thu bên
            dưới.
          </div>
        </div>
      )}
      <div className="two-column order-layout">
        <div>
          {(currentTech || customer) &&
            o.assignedTechnicianId &&
            !['HoanThanh', 'Huy'].includes(o.status) && (
              <RouteMap key={o.id} order={o} technician={currentTech} />
            )}
          <Card title="Thông tin dịch vụ">
            <div className="detail-facts">
              <div>
                <MapPin />
                <p>
                  <small>Địa chỉ thực hiện</small>
                  <b>{o.address}</b>
                </p>
              </div>
              <div>
                <Clock />
                <p>
                  <small>Thời gian hẹn</small>
                  <b>{date(o.scheduledAt)}</b>
                </p>
              </div>
              <div>
                <Phone />
                <p>
                  <small>Khách hàng</small>
                  <b>
                    {o.contactName} · <a href={'tel:' + o.contactPhone}>{o.contactPhone}</a>
                  </b>
                </p>
              </div>
            </div>
            <div className="divider" />
            {currentTech && <ContactActions phone={o.contactPhone} />}
            <h3>Mô tả tình trạng</h3>
            <p className="pre-wrap">{o.description}</p>
            {o.technicianName && (
              <p>
                <b>Kỹ thuật viên:</b> {o.technicianName}
              </p>
            )}
            {files.data?.some((f) => f.purpose === 'OrderFault') && (
              <div className="image-grid">
                {files.data
                  .filter((f) => f.purpose === 'OrderFault')
                  .map((f) => (
                    <ProtectedImage key={f.id} id={f.id} alt="Ảnh lỗi thiết bị" />
                  ))}
              </div>
            )}
            {files.data?.some((f) => f.purpose === 'MaterialEvidence') && (
              <>
                <h3>Ảnh hiện trạng / vật tư</h3>
                <div className="image-grid">
                  {files.data
                    .filter((f) => f.purpose === 'MaterialEvidence')
                    .map((f) => (
                      <ProtectedImage key={f.id} id={f.id} alt="Ảnh vật tư đề xuất" />
                    ))}
                </div>
              </>
            )}
            {currentTech && !['HoanThanh', 'Huy'].includes(o.status) && (
              <button className="btn" onClick={() => open('location')}>
                <Navigation size={17} /> Cập nhật vị trí hiện tại
              </button>
            )}
          </Card>
          {preliminary && !(customer && o.status === 'ChoDuyetSoBo') && (
            <Card title="Báo giá sơ bộ">
              <Badge value={preliminary.status} />
              <p>{preliminary.diagnosis}</p>
              <MoneyBreakdown value={preliminary} />
              {preliminary.reason && <p>Lý do: {preliminary.reason}</p>}
            </Card>
          )}
          {materials.data?.map((m) => (
            <Card key={m.id} title={'Đề xuất vật tư · Phiên bản ' + m.revision}>
              <div className="row space">
                <Badge value={m.status} />
                <small>{date(m.createdAt)}</small>
              </div>
              {m.note && <p>{m.note}</p>}
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Vật tư</th>
                      <th>SL</th>
                      <th>Đơn giá</th>
                      <th>Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody>
                    {m.items?.map((item) => (
                      <tr key={item.id}>
                        <td>
                          <b>{item.name}</b>
                          <small>Bảo hành {item.warrantyMonths} tháng</small>
                        </td>
                        <td>
                          {Number(item.quantity)} {item.unit}
                        </td>
                        <td>{money(item.unitPrice)}</td>
                        <td>{money(item.lineTotal)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="row space total-line">
                <b>Tổng vật tư</b>
                <strong>{money(m.total)}</strong>
              </div>
              {m.reason && <p>Lý do: {m.reason}</p>}
              {currentTech && m.status === 'Pending' && (
                <div className="material-waiting">
                  <div className="notice warning">
                    <Clock size={20} />
                    <div>
                      <b>Đang chờ khách duyệt</b>
                      <p>Đã gửi lúc {date(m.createdAt)}. Chỉ thay vật tư sau khi khách đồng ý.</p>
                    </div>
                  </div>
                  <ContactActions phone={o.contactPhone} reminder />
                </div>
              )}
              {customer && m.status === 'Pending' && o.status === 'DangXuLy' && (
                <div className="actions">
                  <button className="btn danger" onClick={() => open('reject-material', m)}>
                    Từ chối
                  </button>
                  <button className="btn primary" onClick={() => open('approve-material', m)}>
                    <AttentionDot />
                    Đồng ý thay vật tư
                  </button>
                </div>
              )}
            </Card>
          ))}
          {acceptances.data?.map((a) => (
            <Card key={a.id} title={'Phiếu nghiệm thu · Phiên bản ' + a.revision}>
              <Badge value={a.status} />
              <h3>Nguyên nhân</h3>
              <p className="pre-wrap">{a.cause}</p>
              <h3>Biện pháp xử lý</h3>
              <p className="pre-wrap">{a.solution}</p>
              {user.role !== 'KT' && (
                <div className="image-grid">
                  {a.photos?.map((p) => (
                    <ProtectedImage key={p.id} id={p.id} alt="Ảnh sau sửa chữa" />
                  ))}
                </div>
              )}
              <MoneyBreakdown value={a} />
              {a.proposedPaymentMethod && (
                <p>
                  Thanh toán dự kiến:{' '}
                  {a.proposedPaymentMethod === 'BANK' ? 'Chuyển khoản' : 'Tiền mặt'}
                </p>
              )}
              {a.signatureId && user.role !== 'KT' && (
                <>
                  <h3>Chữ ký khách hàng</h3>
                  <div className="image-grid">
                    <ProtectedImage id={a.signatureId} alt="Chữ ký trên phiếu nghiệm thu" />
                  </div>
                </>
              )}
              {a.reason && <p>Lý do yêu cầu sửa lại: {a.reason}</p>}
              {customer && a.status === 'Pending' && o.status === 'ChoNghiemThu' && (
                <div className="actions">
                  <button className="btn danger" onClick={() => open('reject-acceptance', a)}>
                    Yêu cầu xử lý lại
                  </button>
                  <button className="btn primary" onClick={() => open('approve-acceptance', a)}>
                    <AttentionDot />
                    Xác nhận nghiệm thu
                  </button>
                </div>
              )}
            </Card>
          ))}
          {o.status === 'HoanThanh' && (
            <Card title="Thanh toán & đánh giá">
              <PaymentPanel order={o} onRefresh={refresh} />
              {customer && o.paymentStatus === 'Paid' && !reviews.data?.length && (
                <button className="btn primary" onClick={() => open('review')}>
                  <Star size={17} /> Đánh giá dịch vụ
                </button>
              )}
              {reviews.data?.map((r) => (
                <div className="review" key={r.id}>
                  <div className="stars">
                    {'★'.repeat(r.rating)}
                    {'☆'.repeat(5 - r.rating)}
                  </div>
                  <p>{r.comment || 'Khách đã đánh giá dịch vụ.'}</p>
                  <small>{date(r.createdAt)}</small>
                </div>
              ))}
            </Card>
          )}
          {o.status === 'Huy' && (
            <Card title="Thông tin hủy đơn">
              <p>{o.cancelReason || 'Khách không đồng ý báo giá.'}</p>
              <p>
                Phí phải thu: <b>{money(o.cancellationFee)}</b>
              </p>
              {noPaymentDue(o) && (
                <div className="notice success">
                  Đã thanh toán · Đơn hủy không phát sinh phí, bạn không cần thanh toán thêm.
                </div>
              )}
              {Number(o.cancellationFee) > 0 && (
                <div className="notice warning">
                  Khoản phí này chưa được ghi nhận đã thu. Bộ phận hỗ trợ sẽ xử lý theo chính sách
                  của nhóm.
                </div>
              )}
            </Card>
          )}
        </div>
        <aside>
          <Card title="Lịch sử xử lý">
            <div className="timeline">
              {history.data?.map((h) => (
                <div key={h.id}>
                  <span />
                  <section>
                    <b>{labels[h.toStatus] || h.toStatus}</b>
                    <p>{h.reason}</p>
                    <small>
                      {date(h.happenedAt)}
                      {h.actorName ? ' · ' + h.actorName : ''}
                    </small>
                  </section>
                </div>
              ))}
            </div>
          </Card>
          {dispatcher && (
            <Card title="Ghi chú điều phối">
              <p>Lưu nội dung chẩn đoán từ ảnh hoặc trao đổi qua điện thoại.</p>
              <button className="btn" onClick={() => open('note')}>
                Thêm ghi chú
              </button>
              <Notes orderId={id} version={o.version} />
            </Card>
          )}
          {customer && (
            <Card title="Thông tin từ điều phối">
              <Notes orderId={id} version={o.version} />
            </Card>
          )}
          {customer && (
            <Card title="Cần hỗ trợ thêm?">
              <p>Gửi yêu cầu khiếu nại hoặc bảo hành để bộ phận chăm sóc khách hàng tiếp nhận.</p>
              <button className="btn" onClick={() => open('support')}>
                Gửi yêu cầu hỗ trợ
              </button>
            </Card>
          )}
          {(customer || dispatcher) && !['HoanThanh', 'Huy'].includes(o.status) && (
            <button className="btn danger full" onClick={() => open('cancel')}>
              Hủy yêu cầu dịch vụ
            </button>
          )}
        </aside>
      </div>
      {modal && (
        <ActionModal
          modal={modal}
          order={o}
          config={cfg.data}
          next={next[o.status]}
          onClose={() => setModal(null)}
          onDone={() => {
            const declined = modal.type === 'receive' && modal.record?.decision === 'Rejected';
            setModal(null);
            if (declined) navigate('/orders');
            else refresh();
          }}
        />
      )}
    </>
  );
}
function Notes({ orderId, version }) {
  const n = useData('/orders/' + orderId + '/notes');
  useEffect(() => {
    n.reload();
  }, [version]);
  return (
    <div className="notes">
      {n.data?.map((note) => (
        <article key={note.id}>
          <b>{note.visibility === 'Internal' ? 'Nội bộ' : 'Khách có thể xem'}</b>
          <p>{note.text}</p>
          <small>{date(note.createdAt)}</small>
        </article>
      ))}
    </div>
  );
}
function Countdown({ value, dispatcher }) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);
  const left = Math.max(0, Math.ceil((new Date(value).getTime() - now) / 1000));
  useEffect(() => {
    if (!dispatcher && left > 0 && left < 120) navigator.vibrate?.([150, 80, 150]);
  }, [left > 0 && left < 120, dispatcher]);
  const time =
    String(Math.floor(left / 60)).padStart(2, '0') + ':' + String(left % 60).padStart(2, '0');
  return (
    <div className={'notice ' + (left < 120 ? 'error assignment-urgent' : 'info')}>
      <span
        className={'assignment-clock ' + (left < 120 ? 'urgent' : '')}
        aria-label={'Còn ' + time}
      >
        {time}
      </span>
      <div>
        <b>
          {left === 0
            ? 'Lệnh nhận việc đã hết hạn'
            : dispatcher
              ? 'Chờ kỹ thuật viên nhận việc · Còn ' + time
              : 'Vui lòng nhận hoặc từ chối công việc trong ' + time}
        </b>
        <p>
          {dispatcher
            ? 'Nếu kỹ thuật viên không phản hồi đúng hạn, đơn sẽ được chuyển về chờ phân công để bạn chọn kỹ thuật viên khác.'
            : left === 0
              ? 'Hệ thống đang cập nhật lại lệnh. Bạn không thể nhận lệnh đã hết hạn.'
              : 'Hãy kiểm tra địa chỉ và nội dung công việc trước khi phản hồi.'}
        </p>
      </div>
    </div>
  );
}

const titles = {
  preliminary: 'Lập báo giá sơ bộ',
  assign: 'Phân công kỹ thuật viên',
  receive: 'Phản hồi lệnh công việc',
  progress: 'Cập nhật tiến độ',
  material: 'Đề xuất thay vật tư',
  acceptance: 'Lập phiếu nghiệm thu',
  cod: 'Xác nhận thu tiền mặt',
  review: 'Đánh giá dịch vụ',
  support: 'Gửi yêu cầu hỗ trợ',
  cancel: 'Hủy yêu cầu dịch vụ',
  note: 'Ghi chú điều phối',
  location: 'Cập nhật vị trí',
  'approve-preliminary': 'Đồng ý báo giá',
  'reject-preliminary': 'Từ chối báo giá',
  'approve-material': 'Duyệt vật tư phát sinh',
  'reject-material': 'Từ chối vật tư',
  'approve-acceptance': 'Xác nhận nghiệm thu',
  'reject-acceptance': 'Yêu cầu xử lý lại',
};
function ActionModal({ modal, order, config, next, onClose, onDone }) {
  const a = useAction(),
    { type, record, expectedVersion } = modal;
  const [form, setForm] = useState({
    diagnosis: '',
    reason: '',
    technicianId: '',
    decision: record?.decision || 'Accepted',
    reasonChoice: '',
    cause: '',
    solution: '',
    note: '',
    rating: '5',
    comment: '',
    ticketType: 'Complaint',
    description: '',
    visibility: 'Internal',
    confirmed: false,
    paymentMethod: record?.proposedPaymentMethod || 'COD',
    bankAccountId: '',
  });
  const [items, setItems] = useState([
      { name: '', quantity: '1', unit: 'cái', unitPrice: '', warrantyMonths: 0 },
    ]),
    [files, setFiles] = useState([]);
  const [preview, setPreview] = useState(false),
    [capturedSignature, setCapturedSignature] = useState(null);
  const approvedMaterials = useData(
    type === 'acceptance' ? '/orders/' + order.id + '/material-quotes' : null,
  );
  const uploadCache = useRef(new Map()),
    keyRef = useRef(uuid());
  const candidates = useData(
    type === 'assign' ? '/technicians/available?orderId=' + order.id : null,
  );
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));
  const rejection = type.startsWith('reject-');
  async function fileIds(purpose) {
    const ids = [];
    for (const f of files) {
      if (!uploadCache.current.has(f))
        uploadCache.current.set(f, (await upload(f, purpose, order.id)).id);
      ids.push(uploadCache.current.get(f));
    }
    return ids;
  }
  async function submit(e) {
    e.preventDefault();
    await a.run(async () => {
      if (type === 'acceptance' && !files.length)
        throw new Error('Cần ít nhất một ảnh thành phẩm.');
      if (
        type === 'approve-acceptance' &&
        config?.signatureRequired &&
        !files.length &&
        !record?.signatureId
      )
        throw new Error('Vui lòng ký xác nhận hoặc chọn ảnh chữ ký.');
      if (
        type === 'receive' &&
        form.decision === 'Rejected' &&
        (!form.reasonChoice ||
          (form.reasonChoice === 'Lý do khác' && form.reason.trim().length < 5))
      )
        throw new Error('Chọn lý do từ chối; lý do khác cần ít nhất 5 ký tự.');
      let path = '/orders/' + order.id,
        method = 'POST',
        body = { expectedVersion },
        key;
      if (type === 'preliminary') {
        path += '/preliminary-quotes';
        body.diagnosis = form.diagnosis;
      } else if (type === 'assign') {
        path += '/assignments';
        body.technicianId = Number(form.technicianId);
      } else if (type === 'receive') {
        path = '/assignments/' + order.currentAssignment.id + '/decision';
        body = {
          decision: form.decision,
          expectedVersion: order.currentAssignment.version,
          ...(form.decision === 'Rejected'
            ? {
                reason:
                  form.reasonChoice === 'Lý do khác'
                    ? 'Lý do khác: ' + form.reason.trim()
                    : form.reasonChoice,
              }
            : {}),
        };
      } else if (type === 'progress') {
        path += '/progress';
        method = 'PATCH';
        body.nextStatus = next[0];
      } else if (type === 'material') {
        await fileIds('MaterialEvidence');
        path += '/material-quotes';
        body = {
          items: items.map((i) => ({ ...i, warrantyMonths: Number(i.warrantyMonths) })),
          note: form.note,
          expectedVersion,
        };
      } else if (type === 'acceptance') {
        path += '/acceptances';
        body = {
          cause: form.cause,
          solution: form.solution,
          photoIds: await fileIds('AcceptancePhoto'),
          proposedPaymentMethod: form.paymentMethod,
          expectedVersion,
        };
        if (capturedSignature) {
          if (!uploadCache.current.has(capturedSignature))
            uploadCache.current.set(
              capturedSignature,
              (await upload(capturedSignature, 'CustomerSignature', order.id)).id,
            );
          body.signatureId = uploadCache.current.get(capturedSignature);
        }
      } else if (type === 'cod') {
        path += '/payments/cod';
        key = keyRef.current;
      } else if (type === 'review') {
        path += '/reviews';
        body = { rating: Number(form.rating), comment: form.comment };
      } else if (type === 'support') {
        path = '/support/tickets';
        body = { orderId: order.id, type: form.ticketType, description: form.description };
      } else if (type === 'cancel') {
        path += '/cancel';
        body.reason = form.reason;
      } else if (type === 'note') {
        path += '/notes';
        body = { text: form.note, visibility: form.visibility, expectedVersion };
      } else if (type === 'location') {
        if (!navigator.geolocation) throw new Error('Thiết bị chưa hỗ trợ vị trí.');
        const p = await new Promise((resolve, reject) =>
          navigator.geolocation.getCurrentPosition(
            resolve,
            () =>
              reject(
                new Error(
                  'Không lấy được vị trí. Hãy cấp quyền hoặc tiếp tục làm việc không dùng vị trí.',
                ),
              ),
            { timeout: 12000, maximumAge: 30000 },
          ),
        );
        path = '/technicians/me/location';
        method = 'PATCH';
        body = {
          latitude: p.coords.latitude,
          longitude: p.coords.longitude,
          accuracyMeters: p.coords.accuracy,
        };
      } else {
        const resource = type.split('-')[1];
        path +=
          '/' +
          {
            preliminary: 'preliminary-quotes',
            material: 'material-quotes',
            acceptance: 'acceptances',
          }[resource] +
          '/' +
          record.id +
          '/decision';
        body = {
          decision: rejection ? 'Rejected' : 'Approved',
          expectedVersion: record.version,
          ...(rejection ? { reason: form.reason } : {}),
        };
        if (type === 'approve-acceptance') {
          body.paymentMethod = form.paymentMethod;
          if (form.paymentMethod === 'BANK') body.bankAccountId = Number(form.bankAccountId);
          if (files.length) body.signatureId = (await fileIds('CustomerSignature'))[0];
          else if (record.signatureId) body.signatureId = record.signatureId;
        }
      }
      await api(path, { method, body, key });
      onDone();
    });
  }
  const fileInput = (label, required = false, multiple = true) => (
    <PhotoPicker
      label={label}
      required={required}
      multiple={multiple}
      files={files}
      onChange={setFiles}
    />
  );
  const approved = approvedMaterials.data?.find((m) => m.status === 'Approved');
  const breakdown = {
    ...order.currentPreliminaryQuote,
    materialTotal: approved?.total || 0,
    total: Number(order.currentPreliminaryQuote?.total || 0) + Number(approved?.total || 0),
  };
  return (
    <Modal
      title={
        type === 'receive'
          ? form.decision === 'Rejected'
            ? 'Lý do từ chối đơn'
            : 'Chấp nhận đơn'
          : titles[type]
      }
      onClose={onClose}
    >
      <form onSubmit={submit}>
        <ErrorBox error={a.error || candidates.error} />
        {type === 'preliminary' && (
          <>
            <Field label="Chẩn đoán sơ bộ">
              <textarea
                required
                minLength={5}
                maxLength={2000}
                value={form.diagnosis}
                onChange={(e) => set('diagnosis', e.target.value)}
                rows={4}
              />
            </Field>
            <div className="notice info">
              Giá kiểm tra, tiền công và tỷ lệ hoa hồng lấy từ danh mục hiện hành. Khách cần đồng ý
              trước khi phân công.
            </div>
          </>
        )}
        {type === 'assign' && (
          <>
            <Field label="Chọn kỹ thuật viên">
              <select
                required
                value={form.technicianId}
                onChange={(e) => set('technicianId', e.target.value)}
              >
                <option value="">Chọn thợ phù hợp</option>
                {candidates.data?.map((k) => (
                  <option key={k.id} value={k.id}>
                    {k.fullName} · {k.serviceArea}
                  </option>
                ))}
              </select>
            </Field>
            {candidates.data?.length === 0 && (
              <div className="notice warning">
                Chưa có thợ cùng chuyên môn sẵn sàng và đủ số dư ví. Hãy kiểm tra tài khoản KTV hoặc
                thử lại sau.
              </div>
            )}
            <p>Một thợ chỉ giữ một lệnh hoặc ca đang làm tại một thời điểm.</p>
          </>
        )}
        {type === 'receive' && (
          <>
            <p>
              {order.serviceName} · {order.address}
            </p>
            <Countdown value={order.currentAssignment.expiresAt} />
            {form.decision === 'Rejected' ? (
              <fieldset className="rejection-reasons">
                <legend>Chọn lý do từ chối</legend>
                {['Quá xa', 'Không đủ dụng cụ', 'Đang xử lý đơn khác', 'Lý do khác'].map(
                  (reason) => (
                    <label key={reason}>
                      <input
                        type="radio"
                        name="rejectionReason"
                        value={reason}
                        checked={form.reasonChoice === reason}
                        onChange={() => set('reasonChoice', reason)}
                        required
                      />
                      {reason}
                    </label>
                  ),
                )}
                {form.reasonChoice === 'Lý do khác' && (
                  <Field label="Nội dung lý do khác">
                    <textarea
                      required
                      minLength={5}
                      maxLength={950}
                      value={form.reason}
                      onChange={(e) => set('reason', e.target.value)}
                    />
                  </Field>
                )}
              </fieldset>
            ) : (
              <div className="notice info">
                Sau khi nhận đơn, hãy liên hệ khách và cập nhật tiến độ công việc.
              </div>
            )}
          </>
        )}
        {type === 'progress' && (
          <p>
            Xác nhận: <b>{next?.[1]}</b>. Thời gian thực hiện sẽ được ghi lại trong lịch sử đơn.
          </p>
        )}
        {type === 'material' && (
          <>
            <p>Liệt kê vật tư cần thay. Chỉ thực hiện sau khi khách đã duyệt.</p>
            {items.map((item, i) => (
              <div className="material-editor" key={i}>
                <div className="row space">
                  <b>Vật tư {i + 1}</b>
                  {items.length > 1 && (
                    <button
                      type="button"
                      className="icon-btn danger"
                      onClick={() => setItems(items.filter((_, n) => n !== i))}
                      aria-label="Xóa dòng"
                    >
                      <Trash2 size={17} />
                    </button>
                  )}
                </div>
                <Field label="Tên vật tư">
                  <input
                    required
                    value={item.name}
                    onChange={(e) =>
                      setItems(items.map((v, n) => (n === i ? { ...v, name: e.target.value } : v)))
                    }
                  />
                </Field>
                <div className="form-grid">
                  <Field label="Số lượng">
                    <input
                      type="number"
                      min="0.01"
                      max="999.99"
                      step="0.01"
                      required
                      value={item.quantity}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) => (n === i ? { ...v, quantity: e.target.value } : v)),
                        )
                      }
                    />
                  </Field>
                  <Field label="Đơn vị">
                    <input
                      required
                      value={item.unit}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) => (n === i ? { ...v, unit: e.target.value } : v)),
                        )
                      }
                    />
                  </Field>
                  <Field label="Đơn giá (đ)">
                    <input
                      type="number"
                      min="0"
                      max="100000000"
                      required
                      value={item.unitPrice}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) => (n === i ? { ...v, unitPrice: e.target.value } : v)),
                        )
                      }
                    />
                  </Field>
                  <Field label="Bảo hành (tháng)">
                    <input
                      type="number"
                      min="0"
                      max="60"
                      required
                      value={item.warrantyMonths}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) =>
                            n === i ? { ...v, warrantyMonths: e.target.value } : v,
                          ),
                        )
                      }
                    />
                  </Field>
                </div>
              </div>
            ))}
            <button
              type="button"
              className="btn"
              disabled={items.length >= 20}
              onClick={() =>
                setItems([
                  ...items,
                  { name: '', quantity: '1', unit: 'cái', unitPrice: '', warrantyMonths: 0 },
                ])
              }
            >
              <Plus size={16} /> Thêm vật tư
            </button>
            <div className="confirmation-amount">
              <small>Tổng vật tư đề xuất</small>
              {money(
                items.reduce(
                  (sum, item) => sum + Number(item.quantity || 0) * Number(item.unitPrice || 0),
                  0,
                ),
              )}
            </div>
            <Field label="Ghi chú">
              <textarea value={form.note} onChange={(e) => set('note', e.target.value)} />
            </Field>
            {fileInput('Ảnh vật tư / hiện trạng (không bắt buộc)')}
          </>
        )}
        {type === 'acceptance' && (
          <>
            <div className="notice info">
              {order.contactName} · {order.address}
            </div>
            {preview ? (
              <Card title="Xem lại phiếu nghiệm thu">
                <h3>Nguyên nhân thực tế</h3>
                <p className="pre-wrap">{form.cause}</p>
                <h3>Biện pháp xử lý</h3>
                <p className="pre-wrap">{form.solution}</p>
                <PhotoPreview files={files} />
                {capturedSignature && (
                  <PhotoPreview files={[capturedSignature]} label="Chữ ký khách tại hiện trường" />
                )}
                <p>
                  Phương thức dự kiến: {form.paymentMethod === 'BANK' ? 'Chuyển khoản' : 'Tiền mặt'}
                </p>
              </Card>
            ) : (
              <>
                <Field label="Nguyên nhân hư hỏng">
                  <textarea
                    required
                    minLength={5}
                    maxLength={2000}
                    value={form.cause}
                    onChange={(e) => set('cause', e.target.value)}
                  />
                </Field>
                <Field label="Biện pháp đã thực hiện">
                  <textarea
                    required
                    minLength={5}
                    maxLength={2000}
                    value={form.solution}
                    onChange={(e) => set('solution', e.target.value)}
                  />
                </Field>
                {fileInput('Ảnh thiết bị sau sửa chữa', true)}
                <Field label="Phương thức thanh toán dự kiến">
                  <select
                    value={form.paymentMethod}
                    onChange={(e) => set('paymentMethod', e.target.value)}
                  >
                    <option value="COD">Tiền mặt</option>
                    <option value="BANK">Chuyển khoản</option>
                  </select>
                </Field>
                <SignaturePad onChange={setCapturedSignature} />
                {capturedSignature && (
                  <PhotoPreview files={[capturedSignature]} label="Chữ ký đã lưu tạm" />
                )}
                <small>
                  Khách có thể ký tại hiện trường. Phiếu vẫn cần khách xác nhận bằng tài khoản; lựa
                  chọn thanh toán cuối cùng do khách xác nhận.
                </small>
              </>
            )}
            {approved?.items?.length > 0 && (
              <Card title="Vật tư đã được khách duyệt">
                {approved.items.map((item) => (
                  <p key={item.id}>
                    {item.name} × {Number(item.quantity)} · {money(item.lineTotal)} · BH{' '}
                    {item.warrantyMonths} tháng
                  </p>
                ))}
              </Card>
            )}
            <MoneyBreakdown value={breakdown} />
            <button
              className="btn"
              type="button"
              disabled={
                form.cause.trim().length < 5 || form.solution.trim().length < 5 || !files.length
              }
              onClick={() => setPreview((v) => !v)}
            >
              {preview ? 'Tiếp tục chỉnh sửa' : 'Xem lại phiếu'}
            </button>
            <div className="notice info">
              Gửi phiếu để khách xác nhận nghiệm thu và chọn phương thức thanh toán. Chỉ xác nhận
              thu tiền khi đã thực nhận.
            </div>
          </>
        )}
        {type.startsWith('approve-') && (
          <>
            <p>Xác nhận đồng ý nội dung phiếu và chi phí đã xem.</p>
            {record?.total !== undefined && (
              <div className="confirmation-amount">{money(record.total)}</div>
            )}
            {type === 'approve-acceptance' && (
              <>
                <PaymentMethodFields
                  method={form.paymentMethod}
                  bankAccountId={form.bankAccountId}
                  onChange={(paymentMethod, bankAccountId) =>
                    setForm((s) => ({ ...s, paymentMethod, bankAccountId }))
                  }
                />
                {record.signatureId && (
                  <>
                    <h3>Chữ ký đã thu tại hiện trường</h3>
                    <div className="image-grid">
                      <ProtectedImage
                        id={record.signatureId}
                        alt="Chữ ký khách trên phiếu nghiệm thu"
                      />
                    </div>
                    <p>Kiểm tra chữ ký này trước khi xác nhận. Bạn có thể ký lại bên dưới.</p>
                  </>
                )}
                <SignaturePad onChange={(file) => setFiles(file ? [file] : [])} />
                {fileInput('Ảnh chữ ký của khách hàng', config?.signatureRequired, false)}
                {!config?.signatureRequired && (
                  <small>Chữ ký tùy chọn; xác nhận vẫn được ghi theo tài khoản khách hàng.</small>
                )}
                <label className="checkbox">
                  <input type="checkbox" required /> Tôi đã kiểm tra thiết bị và đồng ý nghiệm thu.
                </label>
              </>
            )}
          </>
        )}
        {(rejection || type === 'cancel') && (
          <>
            <Field label={type === 'cancel' ? 'Lý do hủy' : 'Lý do từ chối / yêu cầu xử lý lại'}>
              <textarea
                required
                minLength={5}
                value={form.reason}
                onChange={(e) => set('reason', e.target.value)}
                rows={4}
              />
            </Field>
            {type === 'cancel' && (
              <div className="notice warning">
                {order.status === 'DangDiChuyen'
                  ? `Thợ đã di chuyển: phí hủy ${money(order.cancellationFeeSnapshot)}. Khoản này chờ bộ phận hỗ trợ thu theo chính sách.`
                  : 'Hủy trước khi thợ xuất phát không phát sinh phí. Từ lúc thợ đã đến nơi, yêu cầu sẽ được chuyển hỗ trợ.'}
              </div>
            )}
          </>
        )}
        {type === 'cod' && (
          <>
            <p>Chỉ xác nhận sau khi đã thực nhận đủ tiền mặt từ khách.</p>
            <div className="confirmation-amount">{money(order.currentAcceptance?.total)}</div>
            <label className="checkbox">
              <input type="checkbox" required /> Tôi đã nhận đủ số tiền trên từ khách hàng.
            </label>
          </>
        )}
        {type === 'review' && (
          <>
            <Field label="Mức độ hài lòng">
              <select value={form.rating} onChange={(e) => set('rating', e.target.value)}>
                {[5, 4, 3, 2, 1].map((n) => (
                  <option key={n} value={n}>
                    {'★'.repeat(n)} · {n} sao
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Nhận xét của bạn">
              <textarea
                maxLength={1500}
                value={form.comment}
                onChange={(e) => set('comment', e.target.value)}
              />
            </Field>
          </>
        )}
        {type === 'support' && (
          <>
            <Field label="Loại yêu cầu">
              <select value={form.ticketType} onChange={(e) => set('ticketType', e.target.value)}>
                <option value="Complaint">Khiếu nại / hỗ trợ</option>
                <option value="Warranty">Yêu cầu bảo hành vật tư</option>
              </select>
            </Field>
            <Field label="Mô tả yêu cầu">
              <textarea
                required
                minLength={10}
                maxLength={2000}
                value={form.description}
                onChange={(e) => set('description', e.target.value)}
                rows={4}
              />
            </Field>
            <small>
              Khiếu nại trong 7 ngày từ nghiệm thu; bảo hành được kiểm tra theo vật tư còn hạn.
            </small>
          </>
        )}
        {type === 'note' && (
          <>
            <Field label="Nội dung">
              <textarea required value={form.note} onChange={(e) => set('note', e.target.value)} />
            </Field>
            <Field label="Phạm vi xem">
              <select value={form.visibility} onChange={(e) => set('visibility', e.target.value)}>
                <option value="Internal">Nội bộ điều phối / CSKH</option>
                <option value="Customer">Khách hàng có thể xem</option>
              </select>
            </Field>
          </>
        )}
        {type === 'location' && (
          <p>
            Cho phép lấy vị trí khi ứng dụng đang mở. Vị trí này chỉ hiển thị cho khách của đơn đang
            phục vụ và điều phối viên.
          </p>
        )}
        <div className="form-actions">
          <button type="button" className="btn" disabled={a.busy} onClick={onClose}>
            Quay lại
          </button>
          <Submit
            busy={a.busy}
            className={
              'btn ' +
              (type === 'receive' && form.decision === 'Rejected' ? 'reject-order' : 'primary')
            }
            disabled={
              a.busy ||
              (type === 'receive' &&
                (new Date(order.currentAssignment.expiresAt).getTime() <= Date.now() ||
                  (form.decision === 'Rejected' &&
                    (!form.reasonChoice ||
                      (form.reasonChoice === 'Lý do khác' && form.reason.trim().length < 5)))))
            }
          >
            {type === 'receive'
              ? form.decision === 'Rejected'
                ? 'Xác nhận từ chối'
                : 'Xác nhận nhận đơn'
              : type === 'material'
                ? 'Gửi khách hàng duyệt'
                : type === 'acceptance'
                  ? 'Gửi phiếu nghiệm thu'
                  : 'Xác nhận'}
          </Submit>
        </div>
      </form>
    </Modal>
  );
}
