import test from 'node:test';
import assert from 'node:assert/strict';
import { deliverOtp, deliveryConfigured } from '../backend/src/otp-delivery.js';

test('Email OTP is sent server-side through Resend', async () => {
  const env = { RESEND_API_KEY: 'test-key', OTP_EMAIL_FROM: 'HomeFix <otp@example.com>' };
  await deliverOtp('customer@gmail.com', '123456', {
    env,
    fetcher: async (url, options) => {
      assert.equal(url, 'https://api.resend.com/emails');
      const body = JSON.parse(options.body);
      assert.deepEqual(body.to, ['customer@gmail.com']);
      assert.match(body.text, /123456/);
      assert.equal(options.headers.Authorization, 'Bearer test-key');
      return { ok: true };
    },
  });
});
test('Missing credentials and provider failures cannot report successful delivery', async () => {
  assert.equal(deliveryConfigured({}), false);
  await assert.rejects(deliverOtp('test@example.com', '123456', { env: {} }), /NOT_CONFIGURED/);
  await assert.rejects(
    deliverOtp('test@example.com', '123456', {
      env: { RESEND_API_KEY: 'test', OTP_EMAIL_FROM: 'test@example.com' },
      fetcher: async () => ({ ok: false }),
    }),
    /DELIVERY_FAILED/,
  );
});

test('Gmail sends to other recipients over TLS using the authenticated sender', async () => {
  const env = {
    OTP_EMAIL_PROVIDER: 'gmail',
    GMAIL_USER: 'sender@gmail.com',
    GMAIL_APP_PASSWORD: 'abcd efgh ijkl mnop',
    OTP_EMAIL_FROM: 'HomeFix <onboarding@resend.dev>',
  };
  let closed = false;
  await deliverOtp('another@gmail.com', '654321', {
    env,
    fetcher: async () => {
      throw new Error('Must not use Resend');
    },
    createTransport: (options) => {
      assert.equal(options.host, 'smtp.gmail.com');
      assert.equal(options.port, 465);
      assert.equal(options.secure, true);
      assert.equal(options.tls.rejectUnauthorized, true);
      assert.equal(options.logger, false);
      assert.equal(options.debug, false);
      assert.equal(options.auth.pass, 'abcdefghijklmnop');
      return {
        sendMail: async (message) => {
          assert.deepEqual(message.from, { name: 'HomeFix', address: 'sender@gmail.com' });
          assert.deepEqual(message.to, ['another@gmail.com']);
          assert.match(message.text, /654321/);
          return { accepted: ['another@gmail.com'] };
        },
        close: () => {
          closed = true;
        },
      };
    },
  });
  assert.equal(closed, true);
});
test('Incomplete Gmail configuration and unknown providers do not fall back to Resend', async () => {
  const env = {
    OTP_EMAIL_PROVIDER: 'gmail',
    RESEND_API_KEY: 'test',
    OTP_EMAIL_FROM: 'sender@example.com',
    GMAIL_USER: 'sender@gmail.com',
  };
  assert.equal(deliveryConfigured(env), false);
  assert.equal(deliveryConfigured({ ...env, GMAIL_APP_PASSWORD: 'too-short' }), false);
  assert.equal(deliveryConfigured({ ...env, OTP_EMAIL_PROVIDER: 'typo' }), false);
  await assert.rejects(deliverOtp('test@gmail.com', '123456', { env }), /NOT_CONFIGURED/);
});
test('SMTP authentication failure and rejected recipients cannot report success', async () => {
  const env = {
    OTP_EMAIL_PROVIDER: 'gmail',
    GMAIL_USER: 'sender@gmail.com',
    GMAIL_APP_PASSWORD: 'abcdefghijklmnop',
  };
  for (const failAuth of [true, false]) {
    let closed = false;
    await assert.rejects(
      deliverOtp('test@gmail.com', '123456', {
        env,
        createTransport: () => ({
          sendMail: async () => {
            if (failAuth) throw Object.assign(new Error('Auth failed'), { code: 'EAUTH' });
            return { accepted: [], rejected: ['test@gmail.com'] };
          },
          close: () => {
            closed = true;
          },
        }),
      }),
    );
    assert.equal(closed, true);
  }
});
test('SMTP configuration check verifies login without sending email', async () => {
  const { verifyGmail } = await import('../backend/src/otp-delivery.js');
  let verified = false,
    closed = false;
  await verifyGmail({
    env: {
      OTP_EMAIL_PROVIDER: 'gmail',
      GMAIL_USER: 'sender@gmail.com',
      GMAIL_APP_PASSWORD: 'abcdefghijklmnop',
    },
    createTransport: () => ({
      verify: async () => {
        verified = true;
      },
      sendMail: async () => {
        throw new Error('Must not send');
      },
      close: () => {
        closed = true;
      },
    }),
  });
  assert.ok(verified && closed);
});
