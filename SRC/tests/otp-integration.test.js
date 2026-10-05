import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import express from 'express';
import nodemailer from 'nodemailer';

// A disposable DB and intercepted provider calls: no real email is sent.
test('OTP registration, recovery and password change against SQL Server', async (t) => {
  process.env.DB_NAME = 'HomeFix_DBMS_OtpTest_' + crypto.randomBytes(6).toString('hex');
  process.env.JWT_SECRET = crypto.randomBytes(48).toString('hex');
  Object.assign(process.env, {
    OTP_EMAIL_PROVIDER: 'gmail',
    GMAIL_USER: 'test-sender@gmail.com',
    GMAIL_APP_PASSWORD: 'abcdefghijklmnop',
  });
  const { dbConfig, config } = await import('../backend/src/config.js');
  const { sql, q, one, close } = await import('../backend/src/db.js');
  const master = await new sql.ConnectionPool(dbConfig('master')).connect();
  await master.request().query(`CREATE DATABASE [${config.database}]`);
  let server;
  const originalTransport = nodemailer.createTransport;
  const realFetch = globalThis.fetch;
  const deliveries = [];
  let providerFails = false;
  t.after(async () => {
    globalThis.fetch = realFetch;
    nodemailer.createTransport = originalTransport;
    if (server) await new Promise((resolve) => server.close(resolve));
    await close();
    await master
      .request()
      .query(
        `ALTER DATABASE [${config.database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${config.database}]`,
      );
    await master.close();
  });
  for (const file of [
    '001_schema.sql',
    '004_auth_otp.sql',
    '007_user_avatar.sql',
    '007_temporary_account_locks.sql',
  ]) {
    const source = await fs.readFile(new URL('../database/' + file, import.meta.url), 'utf8');
    for (const batch of source.split(/^GO\s*$/m).filter((s) => s.trim())) await q(batch);
  }
  nodemailer.createTransport = () => ({
    sendMail: async (message) => {
      deliveries.push(message.text.match(/\b\d{6}\b/)[0]);
      return { accepted: providerFails ? [] : message.to };
    },
    close: () => {},
  });
  globalThis.fetch = async () => {
    throw new Error('Unexpected external request');
  };
  const { authRouter } = await import('../backend/src/auth.js');
  const app = express();
  app.use(express.json());
  app.use('/api', authRouter);
  app.use((e, req, res, next) =>
    res
      .status(e.name === 'ZodError' ? 422 : e.status || 500)
      .json({ error: { code: e.code, message: e.message } }),
  );
  server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api`;
  async function call(path, body, token, method = 'POST') {
    const r = await realFetch(base + path, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: 'Bearer ' + token } : {}),
      },
      body: JSON.stringify(body),
    });
    return { status: r.status, ...(await r.json()) };
  }
  const account = {
    fullName: 'OTP test user',
    phone: '0912345678',
    email: 'otp-test@example.com',
    password: 'Original@123',
  };
  let proof, token, user;
  const age = () => q('UPDATE dbo.XacThucOTP SET NgayTao=DATEADD(hour,-2,SYSUTCDATETIME())');
  await t.test('registration requires both email and OTP', async () => {
    assert.equal((await call('/auth/register', account)).status, 422);
    assert.equal((await call('/auth/register', { ...account, email: null })).status, 422);
  });
  await t.test('registration OTP is hashed and binds all registration fields', async () => {
    await age();
    const r = await call('/auth/register/otp', { ...account });
    assert.equal(r.status, 200, JSON.stringify(r));
    proof = { challengeId: r.data.challengeId, otp: deliveries.at(-1) };
    assert.equal(r.data.otp, undefined);
    const row = await one('SELECT * FROM dbo.XacThucOTP WHERE Id=@Id', { id: proof.challengeId });
    assert.notEqual(row.codeHash, proof.otp);
    assert.equal(
      (await call('/auth/register', { ...account, phone: '0912345679', ...proof })).status,
      422,
    );
    assert.equal((await call('/auth/register/otp', { ...account })).status, 429);
  });
  await t.test('wrong guesses persist and a code locks after five failures', async () => {
    for (let i = 0; i < 5; i++)
      assert.equal(
        (
          await call('/auth/register', {
            ...account,
            ...proof,
            otp: proof.otp === '000000' ? '111111' : '000000',
          })
        ).status,
        422,
      );
    assert.equal(
      (await one('SELECT SoLanThu FROM dbo.XacThucOTP WHERE Id=@Id', { id: proof.challengeId }))
        .attempts,
      5,
    );
    assert.equal((await call('/auth/register', { ...account, ...proof })).status, 422);
  });
  await t.test('Email registration succeeds; simultaneous replay succeeds only once', async () => {
    await age();
    const r = await call('/auth/register/otp', { ...account });
    assert.equal(r.status, 200, JSON.stringify(r));
    proof = { challengeId: r.data.challengeId, otp: deliveries.at(-1) };
    const responses = await Promise.all([
      call('/auth/register', { ...account, ...proof }),
      call('/auth/register', { ...account, ...proof }),
    ]);
    assert.deepEqual(responses.map((r) => r.status).sort(), [201, 422]);
    user = responses.find((r) => r.status === 201).data;
    const login = await call('/auth/login', {
      identifier: account.phone,
      password: account.password,
    });
    assert.equal(login.status, 200);
    token = login.data.accessToken;
  });
  await t.test('changing recovery email requires the current password', async () => {
    const r = await call(
      '/users/me',
      {
        fullName: account.fullName,
        email: 'attacker@example.com',
        defaultAddress: '',
        expectedVersion: user.version,
      },
      token,
      'PATCH',
    );
    assert.equal(r.status, 422);
    assert.equal(r.error.code, 'WRONG_PASSWORD');
  });
  await t.test('OTP cannot cross from registration into password change', async () => {
    assert.equal(
      (
        await call(
          '/users/me/password',
          { currentPassword: account.password, newPassword: 'Changed@123', ...proof },
          token,
        )
      ).status,
      422,
    );
    assert.equal(
      (
        await call(
          '/users/me/password',
          { currentPassword: account.password, newPassword: 'Changed@123' },
          token,
        )
      ).status,
      422,
    );
  });
  await t.test('password change requires current password and expires old OTP', async () => {
    assert.equal(
      (await call('/users/me/password/otp', { currentPassword: 'wrong' }, token)).status,
      422,
    );
    await age();
    const r = await call('/users/me/password/otp', { currentPassword: account.password }, token);
    assert.equal(r.status, 200);
    proof = { challengeId: r.data.challengeId, otp: deliveries.at(-1) };
    await q(
      'UPDATE dbo.XacThucOTP SET NgayHetHan=DATEADD(second,-1,SYSUTCDATETIME()) WHERE Id=@Id',
      {
        id: proof.challengeId,
      },
    );
    assert.equal(
      (
        await call(
          '/users/me/password',
          { currentPassword: account.password, newPassword: 'Changed@123', ...proof },
          token,
        )
      ).status,
      422,
    );
  });
  await t.test('successful password change revokes existing sessions', async () => {
    await age();
    const r = await call('/users/me/password/otp', { currentPassword: account.password }, token);
    assert.equal(r.status, 200);
    proof = { challengeId: r.data.challengeId, otp: deliveries.at(-1) };
    assert.equal(
      (
        await call(
          '/users/me/password',
          { currentPassword: account.password, newPassword: 'Changed@123', ...proof },
          token,
        )
      ).status,
      200,
    );
    assert.equal(
      (await call('/users/me/password/otp', { currentPassword: 'Changed@123' }, token)).status,
      401,
    );
    assert.equal(
      (await call('/auth/login', { identifier: account.phone, password: account.password })).status,
      401,
    );
  });
  await t.test('email recovery resets password and invalidates replay', async () => {
    await age();
    const r = await call('/auth/forgot-password/otp', { identifier: account.email });
    assert.equal(r.status, 200);
    const body = {
      identifier: account.email,
      newPassword: 'Recovered@123',
      challengeId: r.data.challengeId,
      otp: deliveries.at(-1),
    };
    assert.equal((await call('/auth/reset-password', body)).status, 200);
    assert.equal((await call('/auth/reset-password', body)).status, 422);
    assert.equal(
      (await call('/auth/login', { identifier: account.email, password: 'Recovered@123' })).status,
      200,
    );
  });
  await t.test('phone recovery and SMS channel are rejected', async () => {
    assert.equal(
      (
        await call('/auth/reset-password', {
          identifier: account.phone,
          newPassword: 'Example@123',
          ...proof,
        })
      ).status,
      422,
    );
    assert.equal(
      (
        await call('/auth/reset-password', {
          identifier: account.email,
          channel: 'sms',
          newPassword: 'Example@123',
          ...proof,
        })
      ).status,
      422,
    );
  });
  await t.test('unknown recovery addresses have the same response without sending', async () => {
    const before = deliveries.length;
    const r = await call('/auth/forgot-password/otp', { identifier: 'unknown@example.com' });
    assert.equal(r.status, 200);
    assert.equal(deliveries.length, before);
    assert.ok(r.data.challengeId);
  });
  await t.test('provider failure prevents confirmation', async () => {
    providerFails = true;
    await age();
    const r = await call('/auth/forgot-password/otp', { identifier: account.email });
    assert.equal(r.status, 503);
    const row = await one(
      "SELECT TOP 1 DaSuDung,SanSang FROM dbo.XacThucOTP WHERE MucDich='reset' AND DiaChiNhan=@DiaChiNhan ORDER BY NgayTao DESC",
      { destination: account.email },
    );
    assert.equal(row.consumed, true);
    assert.equal(row.ready, false);
  });
});
