import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import sharp from 'sharp';

export async function paymentHarness(base) {
  const tokens = {},
    users = {},
    password = 'HomeFix@123';
  async function call(method, path, body, role = 'KH', key) {
    const headers = {};
    if (tokens[role]) headers.Authorization = 'Bearer ' + tokens[role];
    if (body) headers['Content-Type'] = 'application/json';
    if (key) headers['Idempotency-Key'] = key;
    const response = await fetch(base + path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: response.status, ...(await response.json()) };
  }
  async function request(method, path, body, role = 'KH', status = 200, key) {
    const result = await call(method, path, body, role, key);
    assert.equal(result.status, status, method + ' ' + path + ' ' + JSON.stringify(result));
    return result.data;
  }
  async function login(role, email) {
    const result = await request('POST', '/auth/login', { identifier: email, password }, 'NONE');
    tokens[role] = result.accessToken;
    users[role] = result.user;
  }
  for (const role of ['KH', 'DPV', 'KT', 'ADMIN', 'KTV', 'OTHER'])
    await login(role, (role === 'OTHER' ? 'kh2' : role.toLowerCase()) + '@homefix.local');
  const stamp = Date.now().toString(),
    suffix = stamp.slice(-8),
    techEmail = 'bank-test-' + stamp + '@homefix.local';
  const service = (await request('GET', '/services', null, 'NONE'))[0];
  await request(
    'POST',
    '/users',
    {
      fullName: 'TEST bank technician ' + stamp,
      phone: '08' + suffix,
      email: techEmail,
      role: 'KTV',
      initialPassword: password,
      technicianProfile: { skillGroup: service.groupCode, serviceArea: 'TP.HCM' },
    },
    'ADMIN',
    201,
  );
  await login('TECH', techEmail);
  async function upload(purpose, role, orderId) {
    const image = await sharp({
      create: { width: 80, height: 80, channels: 3, background: '#237d4f' },
    })
      .png()
      .toBuffer();
    const form = new FormData();
    form.set('purpose', purpose);
    if (orderId) form.set('orderId', String(orderId));
    form.set('file', new Blob([image], { type: 'image/png' }), 'TEST-payment-proof.png');
    const response = await fetch(base + '/uploads', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + tokens[role] },
      body: form,
    });
    const result = await response.json();
    assert.equal(response.status, 201, JSON.stringify(result));
    return result.data.id;
  }
  const key = () => crypto.randomUUID();
  const proof = await upload('WalletProof', 'TECH');
  const deposit = await request(
    'POST',
    '/wallet-requests',
    { type: 'Deposit', amount: '1000000', note: 'TEST setup bank payment flow', proofId: proof },
    'TECH',
    201,
    key(),
  );
  await request(
    'POST',
    '/wallet-requests/' + deposit.id + '/decision',
    { decision: 'Approved', expectedVersion: deposit.version },
    'KT',
    200,
    key(),
  );
  async function order(id) {
    return request('GET', '/orders/' + id);
  }
  async function acceptance() {
    const me = await request('GET', '/technicians/me', null, 'TECH');
    await request(
      'PATCH',
      '/technicians/me/availability',
      { availability: 'SanSang', expectedVersion: me.version },
      'TECH',
    );
    let o = await request(
      'POST',
      '/orders',
      {
        serviceId: service.id,
        address: 'TEST ONLY 1 Võ Văn Ngân, Thủ Đức, TP.HCM',
        description: '[TEST BANK] Device repair verification',
      },
      'KH',
      201,
      key(),
    );
    const quote = await request(
      'POST',
      '/orders/' + o.id + '/preliminary-quotes',
      { diagnosis: 'TEST diagnosis for banking flow', expectedVersion: o.version },
      'DPV',
      201,
    );
    await request('POST', `/orders/${o.id}/preliminary-quotes/${quote.id}/decision`, {
      decision: 'Approved',
      expectedVersion: quote.version,
    });
    o = await order(o.id);
    const assignment = await request(
      'POST',
      `/orders/${o.id}/assignments`,
      { technicianId: users.TECH.id, expectedVersion: o.version },
      'DPV',
      201,
    );
    await request(
      'POST',
      `/assignments/${assignment.id}/decision`,
      { decision: 'Accepted', expectedVersion: assignment.version },
      'TECH',
    );
    for (const nextStatus of ['DangDiChuyen', 'DaDenNoi', 'DangXuLy']) {
      o = await order(o.id);
      await request(
        'PATCH',
        `/orders/${o.id}/progress`,
        { nextStatus, expectedVersion: o.version },
        'TECH',
      );
    }
    o = await order(o.id);
    const a = await request(
      'POST',
      `/orders/${o.id}/acceptances`,
      {
        cause: 'TEST cause of malfunction',
        solution: 'TEST repaired and verified',
        photoIds: [await upload('AcceptancePhoto', 'TECH', o.id)],
        expectedVersion: o.version,
      },
      'TECH',
      201,
    );
    return { order: await order(o.id), acceptance: a, quote };
  }
  async function bankAccount() {
    return request(
      'POST',
      '/bank-accounts',
      {
        bankCode: 'MB',
        accountNumber: '0000' + stamp,
        accountHolder: 'TEST ONLY - NOT FOR REAL TRANSFERS',
      },
      'ADMIN',
      201,
    );
  }
  return {
    call,
    request,
    upload,
    acceptance,
    bankAccount,
    order,
    key,
    tokens,
    users,
    proof,
    techEmail,
    stamp,
  };
}
