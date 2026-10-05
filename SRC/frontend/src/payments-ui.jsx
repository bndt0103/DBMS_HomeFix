import { noPaymentDue } from './payment-status';
import { AttentionDot } from './attention';
import React, { useEffect, useRef, useState } from 'react';
import { Banknote, Landmark } from 'lucide-react';
import { api, upload, uuid } from './api';
import {
  useApp,
  useData,
  useAction,
  Field,
  Modal,
  Submit,
  ErrorBox,
  Loading,
  Badge,
  money,
  date,
} from './shared';
import './payments.css';

export function PaymentMethodFields({ method, bankAccountId, onChange }) {
  const options = useData('/payment-options');
  return (
    <div className="payment-methods">
      <h3>Phương thức thanh toán</h3>
      <label className={'payment-option ' + (method === 'COD' ? 'selected' : '')}>
        <span className="payment-option-icon" aria-hidden="true">
          <Banknote size={25} strokeWidth={1.8} />
        </span>
        <span className="payment-option-copy">
          <b>Tiền mặt</b>
          <small>Giao đủ tiền cho KTV sau nghiệm thu.</small>
        </span>
        <input
          type="radio"
          name="paymentMethod"
          checked={method === 'COD'}
          onChange={() => onChange('COD', '')}
        />
      </label>
      <label className={'payment-option ' + (method === 'BANK' ? 'selected' : '')}>
        <span className="payment-option-icon" aria-hidden="true">
          <Landmark size={25} strokeWidth={1.8} />
        </span>
        <span className="payment-option-copy">
          <b>Chuyển khoản ngân hàng</b>
          <small>Chuyển vào tài khoản HomeFix và chờ kế toán xác nhận.</small>
        </span>
        <input
          type="radio"
          name="paymentMethod"
          checked={method === 'BANK'}
          onChange={() => onChange('BANK', '')}
        />
      </label>
      <ErrorBox error={options.error} />
      {method === 'BANK' &&
        (options.loading ? (
          <Loading />
        ) : (
          <>
            <Field label="Ngân hàng / tài khoản nhận tiền">
              <select
                required
                value={bankAccountId}
                onChange={(e) => onChange('BANK', e.target.value)}
              >
                <option value="">Chọn tài khoản HomeFix</option>
                {options.data?.accounts.map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.bankName} · {a.accountNumber} · {a.accountHolder}
                  </option>
                ))}
              </select>
            </Field>
            {!options.data?.accounts.length && (
              <div className="notice warning">
                HomeFix chưa cấu hình tài khoản nhận tiền. Bạn có thể chọn tiền mặt hoặc liên hệ
                quản trị viên.
              </div>
            )}
            <small>
              Thông tin chuyển khoản được tạo sau khi xác nhận. Kiểm tra tên người nhận trong ứng
              dụng ngân hàng trước khi chuyển.
            </small>
          </>
        ))}
    </div>
  );
}
export function TransferInstructions({ request }) {
  const { toast } = useApp();
  async function copy(value) {
    try {
      await navigator.clipboard.writeText(value);
      toast('Đã sao chép.');
    } catch {
      toast('Hãy chọn và sao chép nội dung hiển thị.');
    }
  }
  return (
    <div className="transfer-details">
      <dl>
        <div>
          <dt>Ngân hàng nhận</dt>
          <dd>{request.bankName}</dd>
        </div>
        <div>
          <dt>Chủ tài khoản</dt>
          <dd>{request.accountHolder}</dd>
        </div>
        <div>
          <dt>Số tài khoản</dt>
          <dd>
            <span>{request.accountNumber}</span>
            <button type="button" className="text-btn" onClick={() => copy(request.accountNumber)}>
              Sao chép số tài khoản
            </button>
          </dd>
        </div>
        <div>
          <dt>Số tiền cần chuyển</dt>
          <dd>
            <strong>{money(request.amount)}</strong>
          </dd>
        </div>
        <div>
          <dt>Nội dung chuyển khoản</dt>
          <dd>
            <span>{request.transferContent}</span>
            <button
              type="button"
              className="text-btn"
              onClick={() => copy(request.transferContent)}
            >
              Sao chép nội dung
            </button>
          </dd>
        </div>
      </dl>
    </div>
  );
}
export function PaymentPanel({ order, onRefresh }) {
  const { user } = useApp(),
    details = useData('/orders/' + order.id + '/payment-details', 10000),
    [modal, setModal] = useState(null);
  useEffect(() => {
    details.reload();
  }, [order.version]);
  const data = details.data,
    request = data?.requests.find((r) => r.isActive),
    last = data?.requests[0];
  const done = () => {
    setModal(null);
    details.reload();
    onRefresh();
  };
  if (noPaymentDue(order))
    return (
      <div className="payment-panel">
        <Badge value="Paid" />
        <p>Không phát sinh chi phí cần thanh toán. Bạn không cần chuyển khoản hoặc trả tiền mặt.</p>
      </div>
    );
  return (
    <div className="payment-panel">
      <ErrorBox error={details.error} />
      <div className="row space">
        <b>
          {(data?.method || order.paymentMethod) === 'BANK' ? 'Chuyển khoản ngân hàng' : 'Tiền mặt'}
        </b>
        <Badge value={data?.receipt ? 'Paid' : request?.status || 'Unpaid'} />
      </div>
      {data?.receipt ? (
        <p>
          Đã ghi nhận đủ {money(data.receipt.amount)} lúc {date(data.receipt.paidAt)}.{' '}
          {data.receipt.method === 'BANK'
            ? 'Kế toán đã kiểm tra tiền thực nhận. Không cần trả thêm tiền mặt.'
            : 'Kỹ thuật viên đã xác nhận nhận tiền mặt.'}
        </p>
      ) : (
        <>
          {(data?.method || order.paymentMethod) === 'COD' ? (
            <p>
              Giao tiền trực tiếp cho KTV. Đơn chỉ được đánh dấu đã thanh toán sau khi KTV xác nhận
              thực nhận đủ.
            </p>
          ) : (
            <>
              {request && <TransferInstructions request={request} />}
              {request?.status === 'AwaitingTransfer' && (
                <p>
                  Sau khi chuyển đúng số tiền và nội dung trên, gửi ảnh chứng từ để kế toán kiểm
                  tra.
                </p>
              )}
              {request?.status === 'PendingReview' && (
                <div className="notice info">
                  Đang chờ kế toán xác minh. Không chuyển thêm tiền hoặc trả tiền mặt. Liên hệ hỗ
                  trợ nếu cần điều chỉnh.
                </div>
              )}
              {last?.status === 'Rejected' && (
                <div className="notice warning">
                  <div>
                    <b>Chứng từ chưa được chấp nhận</b>
                    <p>{last.reason}</p>
                    <small>
                      Kiểm tra giao dịch thực tế và liên hệ hỗ trợ nếu đã chuyển tiền. Không chuyển
                      thêm khi chưa làm rõ.
                    </small>
                  </div>
                </div>
              )}
            </>
          )}
          {user.role === 'KH' && order.paymentStatus !== 'Paid' && (
            <div className="actions">
              {request?.status !== 'PendingReview' && (
                <button className="btn" onClick={() => setModal('method')}>
                  {request ? 'Đổi phương thức / tài khoản' : 'Chọn phương thức thanh toán'}
                </button>
              )}
              {['AwaitingTransfer', 'Rejected'].includes(request?.status) && (
                <button className="btn primary" onClick={() => setModal('proof')}>
                  <AttentionDot />
                  {request.status === 'Rejected' ? 'Gửi lại chứng từ' : 'Tôi đã chuyển khoản'}
                </button>
              )}
            </div>
          )}
        </>
      )}
      {data?.requests.length > 0 && (
        <details className="payment-history">
          <summary>Lịch sử yêu cầu chuyển khoản</summary>
          {data.requests.map((r) => (
            <div key={r.id}>
              <span>
                {r.transferContent} · {date(r.createdAt)}
              </span>{' '}
              <Badge value={r.status === 'Confirmed' ? 'Paid' : r.status} />
              {r.reason && <p>{r.reason}</p>}
            </div>
          ))}
        </details>
      )}
      {modal === 'method' && (
        <ChangeMethod order={order} onClose={() => setModal(null)} onDone={done} />
      )}
      {modal === 'proof' && request && (
        <SubmitProof request={request} onClose={() => setModal(null)} onDone={done} />
      )}
    </div>
  );
}
function ChangeMethod({ order, onClose, onDone }) {
  const [method, setMethod] = useState(order.paymentMethod || 'COD'),
    [account, setAccount] = useState(''),
    action = useAction(),
    key = useRef(uuid());
  return (
    <Modal title="Chọn phương thức thanh toán" onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          action.run(async () => {
            await api('/orders/' + order.id + '/payment-method', {
              method: 'POST',
              key: key.current,
              body: {
                method,
                expectedVersion: order.version,
                ...(method === 'BANK' ? { bankAccountId: Number(account) } : {}),
              },
            });
            onDone();
          });
        }}
      >
        <PaymentMethodFields
          method={method}
          bankAccountId={account}
          onChange={(m, a) => {
            setMethod(m);
            setAccount(a);
          }}
        />
        <label className="checkbox">
          <input required type="checkbox" /> Tôi chưa chuyển tiền theo yêu cầu trước đó.
        </label>
        <p>Nếu đã chuyển tiền, hãy gửi chứng từ hoặc liên hệ hỗ trợ trước khi đổi.</p>
        <ErrorBox error={action.error} />
        <div className="form-actions">
          <button type="button" className="btn" onClick={onClose}>
            Quay lại
          </button>
          <Submit busy={action.busy}>Lưu phương thức</Submit>
        </div>
      </form>
    </Modal>
  );
}
function SubmitProof({ request, onClose, onDone }) {
  const action = useAction(),
    key = useRef(uuid()),
    proof = useRef(null),
    [file, setFile] = useState(null),
    [reference, setReference] = useState('');
  return (
    <Modal title="Gửi chứng từ chuyển khoản" onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          action.run(async () => {
            if (!file) throw Error('Vui lòng chọn ảnh chứng từ.');
            if (!proof.current)
              proof.current = (await upload(file, 'PaymentProof', request.orderId)).id;
            await api('/payment-requests/' + request.id + '/submit', {
              method: 'POST',
              key: key.current,
              body: {
                proofId: proof.current,
                customerReference: reference,
                expectedVersion: request.version,
              },
            });
            onDone();
          });
        }}
      >
        <TransferInstructions request={request} />
        <Field label="Mã giao dịch trên biên lai (nếu có)">
          <input maxLength={100} value={reference} onChange={(e) => setReference(e.target.value)} />
        </Field>
        <Field label="Ảnh chứng từ chuyển khoản" hint="JPG/PNG, tối đa 5 MB.">
          <input
            required
            type="file"
            accept="image/jpeg,image/png"
            onChange={(e) => {
              setFile(e.target.files[0] || null);
              proof.current = null;
            }}
          />
        </Field>
        <label className="checkbox">
          <input required type="checkbox" /> Tôi đã chuyển đúng số tiền và tài khoản trên.
        </label>
        <p>Gửi chứng từ chưa đồng nghĩa đã thanh toán. Kế toán cần đối chiếu với tiền thực nhận.</p>
        <ErrorBox error={action.error} />
        <div className="form-actions">
          <button type="button" className="btn" onClick={onClose}>
            Quay lại
          </button>
          <Submit busy={action.busy}>Gửi chứng từ</Submit>
        </div>
      </form>
    </Modal>
  );
}
