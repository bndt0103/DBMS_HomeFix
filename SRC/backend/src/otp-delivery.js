import nodemailer from 'nodemailer';

// Serialize Gmail sends in one API process so repeated clicks cannot open
// several SMTP connections at once. The database rate limit remains the
// authoritative limit across multiple API processes.
let gmailSendQueue = Promise.resolve();
const queuedGmailSend = (operation) => {
  const next = gmailSendQueue.then(operation, operation);
  gmailSendQueue = next.catch(() => {});
  return next;
};

// Gmail app passwords may be copied with grouping spaces from Google's screen.
const gmailPassword = (env) => (env.GMAIL_APP_PASSWORD || '').replace(/\s/g, '');
export const emailProvider = (env = process.env) =>
  (env.OTP_EMAIL_PROVIDER || 'resend').trim().toLowerCase();
export function deliveryConfigured(env = process.env) {
  if (emailProvider(env) === 'gmail')
    return (
      /^[^\s@<>]+@gmail\.com$/i.test((env.GMAIL_USER || '').trim()) &&
      /^[a-zA-Z]{16}$/.test(gmailPassword(env))
    );
  return emailProvider(env) === 'resend' && Boolean(env.RESEND_API_KEY && env.OTP_EMAIL_FROM);
}
function gmailTransport(env, createTransport) {
  return createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: { user: env.GMAIL_USER.trim(), pass: gmailPassword(env) },
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 20000,
    dnsTimeout: 10000,
    tls: { minVersion: 'TLSv1.2', rejectUnauthorized: true },
    logger: false,
    debug: false,
    disableFileAccess: true,
    disableUrlAccess: true,
  });
}
// Verifies SMTP login without sending an email. Errors are rendered safely by the CLI.
export async function verifyGmail({
  env = process.env,
  createTransport = nodemailer.createTransport,
} = {}) {
  if (emailProvider(env) !== 'gmail' || !deliveryConfigured(env))
    throw new Error('OTP_PROVIDER_NOT_CONFIGURED');
  const transport = gmailTransport(env, createTransport);
  try {
    await transport.verify();
  } finally {
    transport.close();
  }
}
// Credentials and OTP values are never logged or returned to the browser.
export async function deliverOtp(
  destination,
  code,
  { env = process.env, fetcher = fetch, createTransport = nodemailer.createTransport } = {},
) {
  if (!deliveryConfigured(env)) throw new Error('OTP_PROVIDER_NOT_CONFIGURED');
  const text = `HomeFix: Mã xác thực của bạn là ${code}. Hết hạn sau 5 phút. Không chia sẻ mã này.`;
  const message = { to: [destination], subject: 'HomeFix - Mã xác thực OTP', text };
  if (emailProvider(env) === 'gmail') {
    await queuedGmailSend(async () => {
      const transport = gmailTransport(env, createTransport);
      try {
        // Always use the authenticated Gmail account as sender; ignore any old Resend From.
        const result = await transport.sendMail({
          ...message,
          from: { name: 'HomeFix', address: env.GMAIL_USER.trim() },
        });
        if (
          !result.accepted?.some(
            (address) => String(address).toLowerCase() === destination.toLowerCase(),
          )
        )
          throw new Error('OTP_DELIVERY_FAILED');
      } finally {
        transport.close();
      }
    });
    return;
  }
  const response = await fetcher('https://api.resend.com/emails', {
    method: 'POST',
    signal: AbortSignal.timeout(15000),
    headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...message, from: env.OTP_EMAIL_FROM }),
  });
  if (!response.ok) throw new Error('OTP_DELIVERY_FAILED');
}
