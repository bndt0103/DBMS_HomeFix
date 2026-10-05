import test from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';
const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api',
  tokens = {};
async function request(role, path, body, method = body ? 'POST' : 'GET') {
  const r = await fetch(base + path, {
    method,
    headers: {
      Authorization: 'Bearer ' + tokens[role],
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: r.status, ...(await r.json()) };
}
async function login(role, email) {
  const r = await request('', '/auth/login', {
    identifier: email || role.toLowerCase() + '@homefix.local',
    password: 'HomeFix@123',
  });
  assert.equal(r.status, 200, JSON.stringify(r));
  tokens[role] = r.data.accessToken;
  return r.data.user;
}
await test('Technician profile and wallet preserve permissions and persist data', async (t) => {
  for (const role of ['GD', 'CSKH', 'KTV', 'KH', 'ADMIN']) await login(role);
  await t.test(
    'quality/performance reports, empty period, invalid period and role restrictions',
    async () => {
      for (const path of ['/reports/quality', '/reports/performance']) {
        const result = await request('GD', path);
        assert.equal(result.status, 200, JSON.stringify(result));
        assert.equal((await request('KH', path)).status, 403);
        assert.equal((await request('CSKH', path)).status, 200);
        assert.equal(
          (await request('GD', path + '?from=2026-10-02T00:00:00Z&to=2026-10-01T00:00:00Z')).status,
          422,
        );
      }
      const empty = await request(
        'GD',
        '/reports/quality?from=2099-01-01T00:00:00Z&to=2099-02-01T00:00:00Z',
      );
      assert.equal(empty.status, 200);
      assert.equal(Number(empty.data.totalOrders), 0);
      assert.equal(empty.data.complaintRate, null);
    },
  );
  await t.test('wallet filters respect direction, ordering and page limit', async () => {
    for (const direction of ['all', 'in', 'out']) {
      const r = await request(
        'KTV',
        '/technicians/me/wallet-transactions?limit=2&direction=' + direction,
      );
      assert.equal(r.status, 200, JSON.stringify(r));
      assert.ok(r.data.length <= 2);
      if (direction !== 'all')
        assert.ok(
          r.data.every((row) =>
            direction === 'in' ? Number(row.amount) > 0 : Number(row.amount) < 0,
          ),
        );
    }
    assert.equal((await request('KH', '/technicians/me/wallet-transactions')).status, 403);
    assert.equal(
      (await request('KTV', '/technicians/me/wallet-transactions?month=2026-99')).status,
      422,
    );
    assert.equal((await request('KTV', '/technicians/me/income?today=1')).status, 200);
  });
  await t.test('monitoring preferences persist and reject stale updates', async () => {
    const before = (await request('GD', '/reports/monitoring')).data;
    const changed = {
      qualityAlerts: !before.qualityAlerts,
      weeklyReport: before.weeklyReport,
      showComplaints: !before.showComplaints,
      ...(before.version ? { expectedVersion: before.version } : {}),
    };
    const updated = await request('GD', '/reports/monitoring', changed, 'PATCH');
    assert.equal(updated.status, 200, JSON.stringify(updated));
    assert.equal(
      (await request('GD', '/reports/monitoring')).data.showComplaints,
      changed.showComplaints,
    );
    assert.equal((await request('GD', '/reports/monitoring', changed, 'PATCH')).status, 409);
    const restored = await request(
      'GD',
      '/reports/monitoring',
      {
        qualityAlerts: before.qualityAlerts,
        weeklyReport: before.weeklyReport,
        showComplaints: before.showComplaints,
        expectedVersion: updated.data.version,
      },
      'PATCH',
    );
    assert.equal(restored.status, 200);
  });
  await t.test(
    'four-step application validates documents, preserves profile and protects identity images',
    async () => {
      const stamp = String(Date.now()).slice(-9),
        email = 'technician-profile-' + stamp + '@homefix.local';
      const created = await request('ADMIN', '/users', {
        fullName: 'Kiểm thử hồ sơ kỹ thuật viên',
        phone: '0' + stamp,
        email,
        initialPassword: 'HomeFix@123',
        role: 'KH',
      });
      assert.equal(created.status, 201, JSON.stringify(created));
      await login('APPLICANT', email);
      const docs = [];
      for (const color of ['#227857', '#224488']) {
        const bytes = await sharp({
            create: { width: 80, height: 60, channels: 3, background: color },
          })
            .png()
            .toBuffer(),
          form = new FormData();
        form.set('purpose', 'TechnicianDocument');
        form.set('file', new Blob([bytes], { type: 'image/png' }), 'test-document.png');
        const r = await fetch(base + '/uploads', {
            method: 'POST',
            headers: { Authorization: 'Bearer ' + tokens.APPLICANT },
            body: form,
          }),
          j = await r.json();
        assert.equal(r.status, 201, JSON.stringify(j));
        docs.push(j.data.id);
      }
      const body = {
        skillGroup: 'DienNuoc',
        serviceArea: 'TP.HCM',
        experience: 'Hồ sơ kiểm thử giao diện, không phải hồ sơ thật.',
        identityNumber: '999' + stamp,
        profile: { years: 3, equipment: 'Máy bơm', certificates: 'Không', vehicle: 'Xe máy' },
      };
      assert.equal((await request('APPLICANT', '/technician-applications', body)).status, 422);
      const submitted = await request('APPLICANT', '/technician-applications', {
        ...body,
        frontDocumentId: docs[0],
        backDocumentId: docs[1],
      });
      assert.equal(submitted.status, 201, JSON.stringify(submitted));
      assert.equal(JSON.parse(submitted.data.profileJson).equipment, 'Máy bơm');
      const other = await fetch(base + '/uploads/' + docs[0], {
        headers: { Authorization: 'Bearer ' + tokens.KH },
      });
      assert.equal(other.status, 404);
      const admin = await fetch(base + '/uploads/' + docs[0], {
        headers: { Authorization: 'Bearer ' + tokens.ADMIN },
      });
      assert.equal(admin.status, 200);
      const decided = await request(
        'ADMIN',
        '/technician-applications/' + submitted.data.id + '/decision',
        {
          decision: 'Rejected',
          reason: 'Hồ sơ kiểm thử tự động đã hoàn thành.',
          expectedVersion: submitted.data.version,
        },
      );
      assert.equal(decided.status, 200, JSON.stringify(decided));
    },
  );
});
