import test from 'node:test';
import assert from 'node:assert/strict';
const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const tokens = {};
async function call(role, path, body, method = body ? 'POST' : 'GET') {
  const r = await fetch(base + path, {
    method,
    headers: {
      'Idempotency-Key': crypto.randomUUID(),
      Authorization: 'Bearer ' + tokens[role],
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: r.status, ...(await r.json()) };
}
await test('Customer GPS ownership, validation, latest point and closed-order protection', async () => {
  for (const role of ['kh', 'kh2', 'ktv', 'dpv']) {
    const r = await call('', '/auth/login', {
      identifier: role + '@homefix.local',
      password: 'HomeFix@123',
    });
    assert.equal(r.status, 200);
    tokens[role] = r.data.accessToken;
  }
  const services = await call('kh', '/services');
  const created = await call('kh', '/orders', {
    serviceId: services.data[0].id,
    address: '1 Võ Văn Ngân, Thủ Đức, TP.HCM',
    description: '[TEST GPS] Kiểm thử vị trí khách theo từng đơn.',
  });
  assert.equal(created.status, 201, JSON.stringify(created));
  const id = created.data.id;
  try {
    const before = (await call('kh', '/orders/' + id)).data;
    const endpoint = '/orders/' + id + '/customer-location';
    assert.equal((await call('kh', endpoint)).data, null);
    const point = { latitude: 0, longitude: 0, accuracyMeters: 10 };
    assert.equal((await call('kh2', endpoint, point, 'PATCH')).status, 404);
    assert.equal((await call('kh2', endpoint)).status, 404);
    assert.equal((await call('ktv', endpoint, point, 'PATCH')).status, 403);
    assert.equal((await call('ktv', endpoint)).status, 404);
    for (const invalid of [
      { ...point, latitude: 91 },
      { ...point, longitude: -181 },
      { ...point, accuracyMeters: -1 },
    ])
      assert.equal((await call('kh', endpoint, invalid, 'PATCH')).status, 422);
    for (const current of [
      point,
      { latitude: 10.86123, longitude: 106.78123, accuracyMeters: 12 },
    ]) {
      const saved = await call('kh', endpoint, current, 'PATCH');
      assert.equal(saved.status, 200, JSON.stringify(saved));
      const read = await call('dpv', endpoint);
      assert.equal(Number(read.data.latitude), current.latitude);
      assert.equal(Number(read.data.longitude), current.longitude);
      assert.ok(read.data.positionUpdatedAt);
    }
    const after = (await call('kh', '/orders/' + id)).data;
    assert.equal(after.address, before.address);
    assert.equal(after.version, before.version, 'GPS update must not invalidate order workflows');
    assert.equal(
      (
        await call('kh', '/orders/' + id + '/cancel', {
          reason: 'Đã xong kiểm thử GPS, không điều phối thật.',
          expectedVersion: after.version,
        })
      ).status,
      200,
    );
    assert.equal((await call('kh', endpoint, point, 'PATCH')).status, 409);
    assert.equal((await call('kh', endpoint)).data, null);
  } finally {
    const o = (await call('kh', '/orders/' + id)).data;
    if (o && o.status !== 'Huy')
      await call('kh', '/orders/' + id + '/cancel', {
        reason: 'Dọn đơn kiểm thử GPS.',
        expectedVersion: o.version,
      });
  }
});
