import { config, dbConfig } from './config.js';
import { apiColumns, sqlParameters } from './sql-names.js';
export const sql = (await import(config.windows ? 'mssql/msnodesqlv8.js' : 'mssql')).default;
let connection;
export async function pool() {
  if (!connection)
    connection = new sql.ConnectionPool(dbConfig()).connect().catch((e) => {
      connection = null;
      throw e;
    });
  return connection;
}
export function request(connection, params = {}) {
  const r = new sql.Request(connection);
  for (const [parameter, v] of Object.entries(params)) {
    const k = sqlParameters[parameter] || parameter;
    if (Buffer.isBuffer(v)) r.input(k, sql.VarBinary(8), v);
    else if (v instanceof Date) r.input(k, sql.DateTime2, v);
    else if (typeof v === 'boolean') r.input(k, sql.Bit, v);
    else if (typeof v === 'number')
      r.input(k, Number.isInteger(v) ? sql.Int : sql.Decimal(18, 7), v);
    else r.input(k, sql.NVarChar(sql.MAX), v ?? null);
  }
  return r;
}
export async function qRaw(text, params = {}, connection) {
  return (await request(connection || (await pool()), params).query(text)).recordset || [];
}
export async function q(text, params = {}, connection) {
  const result = await qRaw(text, params, connection);
  const integers = new Set([
    'id',
    'n',
    'revision',
    'tokenVersion',
    'rating',
    'warrantyMonths',
    'size',
    'totalOrders',
    'completedOrders',
    'cancelledOrders',
    'paidOrders',
    'reviews',
  ]);
  return result.map((row) =>
    Object.fromEntries(
      Object.entries(row).map(([column, v]) => {
        const k = apiColumns[column] || column;
        return [
          k,
          typeof v === 'string' && /^-?\d+$/.test(v) && (integers.has(k) || k.endsWith('Id'))
            ? Number(v)
            : v,
        ];
      }),
    ),
  );
}
export async function one(text, params = {}, connection) {
  return (await q(text, params, connection))[0];
}
export async function transaction(actor, fn) {
  const t = new sql.Transaction(await pool());
  await t.begin(sql.ISOLATION_LEVEL.READ_COMMITTED);
  try {
    // Coarse lock keeps student-scale commands simple and serializable across multiple API processes.
    await q(
      `DECLARE @r int;

EXEC @r = sp_getapplock @Resource = 'HomeFixCommands',
@LockMode = 'Exclusive',
@LockOwner = 'Transaction',
@LockTimeout = 15000;

IF @r < 0 THROW 51009,
'REQUEST_IN_PROGRESS',
1;`,
      {},
      t,
    );
    if (actor) {
      const u = await one(
        'SELECT DangHoatDong,PhienBanXacThuc FROM dbo.NguoiDung WHERE Id=@Id',
        { id: actor.id },
        t,
      );
      if (!u?.isActive || u.tokenVersion !== actor.tokenVersion) {
        const e = new Error('Phiên đăng nhập đã hết hiệu lực.');
        e.status = 401;
        e.code = 'SESSION_REVOKED';
        throw e;
      }
    }
    const result = await fn(t);
    await t.commit();
    return result;
  } catch (e) {
    try {
      await t.rollback();
    } catch {}
    throw e;
  }
}
export async function close() {
  if (connection) {
    await (await connection).close();
    connection = null;
  }
}
const moneyFields = new Set([
  'inspectionFee',
  'laborFee',
  'unitPrice',
  'lineTotal',
  'materialTotal',
  'total',
  'amount',
  'balance',
  'commissionAmount',
  'commissionRatePercent',
  'cancellationFee',
  'gmv',
  'commissionRevenue',
  'income',
  'materialReimbursement',
  'averageRating',
  'quantity',
]);
export function dto(value, key = '') {
  if (value === null || value === undefined) return value ?? null;
  if (Buffer.isBuffer(value)) return value.toString('base64');
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map((v) => dto(v));
  if (typeof value === 'object')
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, dto(v, k)]));
  if (moneyFields.has(key) && typeof value === 'number') return value.toFixed(2);
  return value;
}
