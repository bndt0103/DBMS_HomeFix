import { AttentionDot } from './attention';
import React, { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, uuid } from './api';
import {
  useData,
  useAction,
  Field,
  Modal,
  Submit,
  ErrorBox,
  Loading,
  Card,
  Badge,
  ProtectedImage,
  money,
  code,
} from './shared';
import { TransferInstructions } from './payments-ui';

export function BankAccounts() {
  const accounts = useData('/bank-accounts'),
    options = useData('/payment-options'),
    action = useAction(),
    [adding, setAdding] = useState(false);
  return (
    <Card title="Tài khoản ngân hàng nhận tiền">
      <p>
        Khách chọn trong các tài khoản HomeFix đang bật. Chỉ thêm tài khoản có thật và đã kiểm tra
        đúng chủ sở hữu.
      </p>
      <ErrorBox error={accounts.error || options.error || action.error} />
      {!accounts.loading && !accounts.data?.length && (
        <div className="notice info">
          Chưa có tài khoản nhận tiền. Thanh toán tiền mặt vẫn hoạt động.
        </div>
      )}
      {accounts.data?.map((a) => (
        <div className="bank-account-row" key={a.id}>
          <div>
            <b>
              {a.bankName} · {a.accountNumber}
            </b>
            <p>{a.accountHolder}</p>
            <small>{a.isActive ? 'Đang nhận thanh toán' : 'Đã ngừng nhận yêu cầu mới'}</small>
          </div>
          <button
            className="btn"
            disabled={action.busy}
            onClick={() =>
              action.run(async () => {
                await api('/bank-accounts/' + a.id, {
                  method: 'PATCH',
                  body: { isActive: !a.isActive, expectedVersion: a.version },
                });
                accounts.reload();
              })
            }
          >
            {a.isActive ? 'Ngừng sử dụng' : 'Bật sử dụng'}
          </button>
        </div>
      ))}
      <button className="btn primary" onClick={() => setAdding(true)}>
        Thêm tài khoản nhận tiền
      </button>
      <small className="bank-account-note">
        Thông tin trên yêu cầu đã tạo được giữ nguyên để đối chiếu. Nếu nhập sai, ngừng tài khoản đó
        và thêm tài khoản mới.
      </small>
      {adding && (
        <BankAccountForm
          banks={options.data?.banks || []}
          onClose={() => setAdding(false)}
          onDone={() => {
            setAdding(false);
            accounts.reload();
          }}
        />
      )}
    </Card>
  );
}
function BankAccountForm({ banks, onClose, onDone }) {
  const [form, setForm] = useState({ bankCode: '', accountNumber: '', accountHolder: '' }),
    action = useAction();
  return (
    <Modal title="Thêm tài khoản nhận tiền" onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          action.run(async () => {
            await api('/bank-accounts', { method: 'POST', body: form });
            onDone();
          });
        }}
      >
        <Field label="Ngân hàng">
          <select
            required
            value={form.bankCode}
            onChange={(e) => setForm({ ...form, bankCode: e.target.value })}
          >
            <option value="">Chọn ngân hàng</option>
            {banks.map((b) => (
              <option key={b.code} value={b.code}>
                {b.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Số tài khoản">
          <input
            required
            inputMode="numeric"
            pattern="[0-9]{6,30}"
            minLength={6}
            maxLength={30}
            value={form.accountNumber}
            onChange={(e) => setForm({ ...form, accountNumber: e.target.value })}
          />
        </Field>
        <Field label="Tên chủ tài khoản">
          <input
            required
            minLength={2}
            maxLength={120}
            value={form.accountHolder}
            onChange={(e) => setForm({ ...form, accountHolder: e.target.value })}
          />
        </Field>
        <label className="checkbox">
          <input required type="checkbox" /> Tôi đã kiểm tra ngân hàng, số tài khoản và tên chủ tài
          khoản.
        </label>
        <ErrorBox error={action.error} />
        <div className="form-actions">
          <button type="button" className="btn" onClick={onClose}>
            Quay lại
          </button>
          <Submit busy={action.busy}>Thêm tài khoản</Submit>
        </div>
      </form>
    </Modal>
  );
}
export function BankPaymentQueue() {
  const requests = useData('/bank-payment-requests', 10000),
    [selected, setSelected] = useState(null);
  return (
    <Card title="Xác minh tiền chuyển khoản">
      <p>
        Đối chiếu sao kê ngân hàng trước khi duyệt. Ảnh khách gửi không tự chứng minh HomeFix đã
        nhận tiền.
      </p>
      <ErrorBox error={requests.error} />
      {requests.loading ? (
        <Loading />
      ) : !requests.data?.length ? (
        <p>Chưa có chứng từ cần xử lý.</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Đơn / khách hàng</th>
                <th>Tài khoản nhận</th>
                <th>Số tiền</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {requests.data.map((r) => (
                <tr key={r.id}>
                  <td>
                    <Link to={'/orders/' + r.orderId}>{code(r.orderId)}</Link>
                    <small>{r.customerName}</small>
                  </td>
                  <td>
                    {r.bankName}
                    <small>{r.accountNumber}</small>
                  </td>
                  <td>
                    {money(r.amount)}
                    <small>{r.transferContent}</small>
                  </td>
                  <td>
                    <Badge value={r.status === 'Confirmed' ? 'Paid' : r.status} />
                  </td>
                  <td>
                    <button className="btn small" onClick={() => setSelected(r)}>
                      <AttentionDot show={r.status === 'PendingReview'} />
                      Xem chứng từ
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {selected && (
        <BankReview
          request={selected}
          onClose={() => setSelected(null)}
          onDone={() => {
            setSelected(null);
            requests.reload();
          }}
        />
      )}
    </Card>
  );
}
function BankReview({ request, onClose, onDone }) {
  const [decision, setDecision] = useState('Approved'),
    [amount, setAmount] = useState(''),
    [reference, setReference] = useState(''),
    [reason, setReason] = useState('');
  const action = useAction(),
    key = useRef(uuid()),
    pending = request.status === 'PendingReview';
  return (
    <Modal title={'Xác minh chuyển khoản ' + code(request.orderId)} onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          action.run(async () => {
            await api('/payment-requests/' + request.id + '/decision', {
              method: 'POST',
              key: key.current,
              body: {
                decision,
                expectedVersion: request.version,
                ...(decision === 'Approved'
                  ? { receivedAmount: amount, bankReference: reference }
                  : { reason }),
              },
            });
            onDone();
          });
        }}
      >
        <TransferInstructions request={request} />
        <p>Khách ghi mã giao dịch: {request.customerReference || 'Không cung cấp'}</p>
        {request.proofId && (
          <div className="image-grid">
            <ProtectedImage id={request.proofId} alt="Chứng từ chuyển khoản khách gửi" />
          </div>
        )}
        <Badge value={request.status === 'Confirmed' ? 'Paid' : request.status} />
        {request.reason && <p>{request.reason}</p>}
        {pending && (
          <>
            <Field label="Kết quả xác minh">
              <select value={decision} onChange={(e) => setDecision(e.target.value)}>
                <option value="Approved">Đã thực nhận đủ tiền</option>
                <option value="Rejected">Chưa khớp / cần kiểm tra lại</option>
              </select>
            </Field>
            {decision === 'Approved' ? (
              <>
                <Field label="Số tiền thực nhận (đ)">
                  <input
                    required
                    type="number"
                    min="0.01"
                    step="0.01"
                    max="100000000"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                </Field>
                <Field label="Mã giao dịch trên sao kê ngân hàng">
                  <input
                    required
                    minLength={4}
                    maxLength={100}
                    value={reference}
                    onChange={(e) => setReference(e.target.value)}
                  />
                </Field>
                <label className="checkbox">
                  <input required type="checkbox" /> Tôi đã kiểm tra đúng tài khoản, số tiền và mã
                  giao dịch trên sao kê.
                </label>
              </>
            ) : (
              <Field label="Lý do cần kiểm tra lại">
                <textarea
                  required
                  minLength={5}
                  maxLength={1000}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </Field>
            )}
          </>
        )}
        <ErrorBox error={action.error} />
        <div className="form-actions">
          <button type="button" className="btn" onClick={onClose}>
            Đóng
          </button>
          {pending && <Submit busy={action.busy}>Xác nhận kết quả</Submit>}
        </div>
      </form>
    </Modal>
  );
}
