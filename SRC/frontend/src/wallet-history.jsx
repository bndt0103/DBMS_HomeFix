import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useData, Card, Field, ErrorBox, Loading, Empty, money, date, code } from './shared';
export function WalletHistory({ revision }) {
  const [direction, setDirection] = useState('all'),
    [month, setMonth] = useState(''),
    [limit, setLimit] = useState(20);
  const r = useData(
    `/technicians/me/wallet-transactions?direction=${direction}&month=${month}&limit=${limit}&revision=${revision}`,
  );
  return (
    <Card title="Lịch sử giao dịch">
      <div className="filter-bar">
        <div className="segmented-control">
          {[
            ['all', 'Tất cả'],
            ['in', 'Tiền vào'],
            ['out', 'Tiền ra'],
          ].map(([key, name]) => (
            <button
              key={key}
              className={'btn ' + (direction === key ? 'primary' : '')}
              aria-pressed={direction === key}
              onClick={() => {
                setDirection(key);
                setLimit(20);
              }}
            >
              {name}
            </button>
          ))}
        </div>
        <Field label="Tháng giao dịch">
          <input
            type="month"
            value={month}
            onChange={(e) => {
              setMonth(e.target.value);
              setLimit(20);
            }}
          />
        </Field>
      </div>
      <ErrorBox error={r.error} />
      {r.loading ? (
        <Loading />
      ) : !r.data?.length ? (
        <Empty title="Chưa có giao dịch phù hợp" />
      ) : (
        <div className="wallet-transactions">
          {r.data.map((row) => (
            <article key={row.id}>
              <div>
                <b>{row.note}</b>
                <small>{date(row.createdAt)}</small>
                {row.orderId && <Link to={'/orders/' + row.orderId}>{code(row.orderId)}</Link>}
                {row.commissionRatePercent != null && (
                  <small>
                    Hoa hồng {Number(row.commissionRatePercent)}% tiền công ·{' '}
                    {money(row.commissionAmount)}
                  </small>
                )}
              </div>
              <strong className={Number(row.amount) < 0 ? 'text-red' : 'text-green'}>
                {Number(row.amount) > 0 ? '+' : ''}
                {money(row.amount)}
              </strong>
            </article>
          ))}
        </div>
      )}
      {r.data?.length === limit && (
        <button className="btn full" onClick={() => setLimit((v) => v + 20)}>
          Tải thêm giao dịch
        </button>
      )}
    </Card>
  );
}
