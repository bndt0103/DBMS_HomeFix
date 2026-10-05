import { reportsRouter, sendReportNotifications } from './reports.js';
import { paymentsRouter } from './payments.js';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { ZodError } from 'zod';
import { config, backendDir } from './config.js';
import { pool, close, one } from './db.js';
import { ok, wrap } from './common.js';
import { authRouter } from './auth.js';
import { ordersRouter, expireAssignments } from './orders.js';
import { quotesRouter } from './quotes.js';
import { uploadsRouter, publicUploadsRouter } from './uploads.js';
import { financeRouter } from './finance.js';
import { adminRouter, publicServices } from './admin.js';
import { supportRouter } from './support.js';
if (!config.secret || config.secret.length < 32 || config.secret.startsWith('replace-'))
  throw new Error(
    'Chạy npm run db:init hoặc đặt JWT_SECRET ngẫu nhiên tối thiểu 32 ký tự trong backend/.env.',
  );
export const app = express();
app.disable('x-powered-by');
if (process.env.TRUST_PROXY === 'loopback') app.set('trust proxy', 'loopback');
app.use((req, res, next) => {
  req.requestId = crypto.randomUUID();
  res.set('X-Request-ID', req.requestId);
  next();
});
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        imgSrc: ["'self'", 'blob:', 'data:'],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        connectSrc: ["'self'"],
        upgradeInsecureRequests: null,
        frameSrc: ["'self'", 'https://www.google.com'],
        frameAncestors: null,
      },
    },
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    frameguard: false,
  }),
);
app.use((req, res, next) =>
  cors({
    origin: (origin, cb) => {
      const self = `${req.protocol}://${req.get('host')}`;
      if (!origin || origin === self || config.origins.includes(origin)) cb(null, true);
      else
        cb(
          Object.assign(new Error('Nguồn truy cập chưa được cấu hình.'), {
            status: 403,
            code: 'ORIGIN_NOT_ALLOWED',
          }),
        );
    },
    exposedHeaders: ['Content-Disposition'],
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  })(req, res, next),
);
app.use(express.json({ limit: '256kb' }));
app.get(
  '/api/health',
  wrap(async (req, res) => {
    await one('SELECT 1 AS available');
    ok(res, { status: 'ok' });
  }),
);
app.get('/api/services', publicServices);
app.use(
  '/api',
  publicUploadsRouter,
  authRouter,
  ordersRouter,
  quotesRouter,
  uploadsRouter,
  financeRouter,
  adminRouter,
  supportRouter,
  paymentsRouter,
  reportsRouter,
);
app.use('/api', (req, res) =>
  res.status(404).json({
    error: { code: 'NOT_FOUND', message: 'Không tìm thấy API.' },
    requestId: req.requestId,
  }),
);
const dist = path.resolve(backendDir, '../frontend/dist');
app.use(express.static(dist, { index: false }));
app.get(/.*/, (req, res) => {
  const index = path.join(dist, 'index.html');
  if (fs.existsSync(index)) res.sendFile(index, { dotfiles: 'allow' });
  else
    res
      .status(503)
      .type('text')
      .send('HomeFix API đang chạy. Build frontend bằng npm run build để mở website tại đây.');
});
app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);
  let status = err.status || 500,
    code = err.code || 'INTERNAL_ERROR',
    message = err.message,
    details;
  if (err instanceof ZodError) {
    status = 422;
    code = err.issues.some((i) => i.code === 'unrecognized_keys')
      ? 'FIELD_NOT_ALLOWED'
      : 'VALIDATION_ERROR';
    message = 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra các trường.';
    details = {
      fields: Object.fromEntries(err.issues.map((i) => [i.path.join('.') || '_form', i.message])),
    };
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    status = 413;
    code = 'FILE_TOO_LARGE';
    message = 'Ảnh tối đa 5 MB.';
  }
  if (err.type === 'entity.parse.failed') {
    status = 400;
    code = 'INVALID_JSON';
    message = 'Nội dung JSON không hợp lệ.';
  }
  const num = Number(err.number || err.originalError?.info?.number);
  if ([2601, 2627].includes(num)) {
    status = 409;
    code = 'DUPLICATE_RESOURCE';
    message = 'Dữ liệu đã tồn tại hoặc vừa được người khác xử lý.';
  }
  if (num === 547) {
    status = 409;
    code = 'CONSTRAINT_VIOLATION';
    message = 'Dữ liệu vi phạm ràng buộc hoặc số dư không đủ.';
  }
  if ([51003, 51004, 51009].includes(num)) {
    status = num === 51003 ? 403 : num === 51004 ? 404 : 409;
    code = (message.match(/[A-Z][A-Z_]{3,}/) || ['BUSINESS_CONFLICT'])[0];
    message =
      code === 'INSUFFICIENT_BALANCE'
        ? 'Ví không đủ số dư để đối soát.'
        : 'Không thể xử lý với trạng thái hoặc phiên bản hiện tại. Hãy tải lại dữ liệu.';
  }
  if (['ESOCKET', 'ECONNCLOSED', 'ENOTOPEN', 'ETIMEOUT', 'ELOGIN'].includes(err.code)) {
    status = 503;
    code = 'DATABASE_UNAVAILABLE';
    message = 'Không kết nối được cơ sở dữ liệu. Vui lòng thử lại sau.';
  }
  if (status >= 500) {
    console.error(
      JSON.stringify({
        requestId: req.requestId,
        code: err.code,
        number: num || undefined,
        message: err.message,
      }),
    );
    if (
      !(
        status === 503 &&
        ['OTP_NOT_CONFIGURED', 'OTP_DELIVERY_FAILED', 'DATABASE_UNAVAILABLE'].includes(code)
      )
    ) {
      code = 'INTERNAL_ERROR';
      message = 'Có lỗi xử lý. Vui lòng thử lại hoặc cung cấp mã yêu cầu cho nhóm hỗ trợ.';
    }
  }
  res
    .status(status)
    .json({ error: { code, message, ...(details ? { details } : {}) }, requestId: req.requestId });
});
await pool();
await expireAssignments();
const server = app.listen(config.port, process.env.HOST || '0.0.0.0', () =>
  console.log(`HomeFix running at http://localhost:${config.port}`),
);
let sweeping = false;
const interval = setInterval(async () => {
  if (sweeping) return;
  sweeping = true;
  try {
    await expireAssignments();
  } catch (e) {
    console.error('Assignment sweep:', e.message);
  } finally {
    sweeping = false;
  }
}, 10000);
interval.unref();
let reporting = false;
const reportInterval = setInterval(async () => {
  if (reporting) return;
  reporting = true;
  try {
    await sendReportNotifications();
  } catch (e) {
    console.error('Report monitoring:', e.message);
  } finally {
    reporting = false;
  }
}, 60000);
reportInterval.unref();
async function shutdown() {
  clearInterval(reportInterval);
  clearInterval(interval);
  server.close(async () => {
    await close();
    process.exit(0);
  });
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
