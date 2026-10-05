import test from 'node:test';
import assert from 'node:assert/strict';
import { q, close } from '../backend/src/db.js';
const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const tokens = {};
async function request(role, path, body) {
  const r = await fetch(base + path, {
    method: body ? 'PATCH' : 'GET',
    headers: {
      Authorization: 'Bearer ' + tokens[role],
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: r.status, ...(await r.json()) };
}
try {
  await test('Director merge reports use actual records and preserve settings', async (t) => {
    for (const role of ['GD', 'CSKH', 'KTV']) {
      const r = await fetch(base + '/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          identifier: role.toLowerCase() + '@homefix.local',
          password: 'HomeFix@123',
        }),
      });
      assert.equal(r.status, 200);
      tokens[role] = (await r.json()).data.accessToken;
    }
    await t.test('quality served customers and completed orders match paid orders', async () => {
      const result = await request('GD', '/reports/quality');
      assert.equal(result.status, 200, JSON.stringify(result));
      const [expected] = await q(
        'SELECT COUNT(*) SoDonHoanThanh,COUNT(DISTINCT o.KhachHangId) servedCustomers FROM dbo.ThanhToan p JOIN dbo.DonHang o ON o.Id=p.DonHangId',
      );
      assert.equal(result.data.completedOrders, expected.completedOrders);
      assert.equal(result.data.servedCustomers, expected.servedCustomers);
    });
    await t.test(
      'cashflow matches actual bank receipts and deposit/withdrawal entries without COD double counting',
      async () => {
        const r = await request('GD', '/reports/cashflow');
        assert.equal(r.status, 200, JSON.stringify(r));
        const [expected] = await q(
          `SELECT (SELECT COALESCE(SUM(SoTien),0) FROM dbo.ThanhToan WHERE PhuongThuc='BANK')+(SELECT COALESCE(SUM(SoTien),0) FROM dbo.GiaoDichVi WHERE Loai='Deposit') incoming,(SELECT COALESCE(-SUM(SoTien),0) FROM dbo.GiaoDichVi WHERE Loai='Withdrawal') outgoing`,
        );
        for (const key of ['incoming', 'outgoing'])
          assert.equal(
            r.data.reduce((n, x) => n + Number(x[key]), 0),
            Number(expected[key]),
          );
        assert.equal((await request('CSKH', '/reports/cashflow')).status, 403);
        assert.equal((await request('KTV', '/reports/cashflow')).status, 403);
        assert.deepEqual(
          (
            await request(
              'GD',
              '/reports/cashflow?from=2099-01-01T00:00:00Z&to=2099-02-01T00:00:00Z',
            )
          ).data,
          [],
        );
        assert.equal(
          (
            await request(
              'GD',
              '/reports/cashflow?from=2026-10-01T00:00:00Z&to=2026-09-01T00:00:00Z',
            )
          ).status,
          422,
        );
      },
    );
    await t.test(
      'performance aggregates do not fabricate unmeasured visits or durations',
      async () => {
        const r = await request('GD', '/reports/performance');
        assert.equal(r.status, 200, JSON.stringify(r));
        for (const row of r.data) {
          if (!Number(row.scheduledVisits)) assert.equal(row.onTimeRate, null);
          else
            assert.equal(
              Number(row.onTimeRate),
              (Number(row.onTimeVisits) / Number(row.scheduledVisits)) * 100,
            );
          if (!Number(row.measuredJobs)) assert.equal(row.averageMinutes, null);
          else assert.ok(Number(row.averageMinutes) >= 0);
          if (!Number(row.assignedOrders)) {
            assert.equal(row.cancellationRate, null);
            assert.equal(row.warrantyRate, null);
          }
        }
      },
    );
    await t.test(
      'new monitoring settings survive legacy updates, reject CSKH changes and stale versions',
      async () => {
        const before = (await request('GD', '/reports/monitoring')).data;
        const pick = ({ version, ...rest }) => ({
          ...rest,
          ...(version ? { expectedVersion: version } : {}),
        });
        const changed = await request('GD', '/reports/monitoring', {
          ...pick(before),
          showCashflow: !before.showCashflow,
          showTechnicians: !before.showTechnicians,
        });
        assert.equal(changed.status, 200, JSON.stringify(changed));
        try {
          assert.equal((await request('GD', '/reports/monitoring', pick(before))).status, 409);
          const legacy = await request('GD', '/reports/monitoring', {
            qualityAlerts: before.qualityAlerts,
            weeklyReport: before.weeklyReport,
            showComplaints: before.showComplaints,
            expectedVersion: changed.data.version,
          });
          assert.equal(legacy.status, 200);
          assert.equal(legacy.data.showCashflow, !before.showCashflow);
          assert.equal(legacy.data.showTechnicians, !before.showTechnicians);
          const c = (await request('CSKH', '/reports/monitoring')).data;
          assert.equal(
            (
              await request('CSKH', '/reports/monitoring', {
                qualityAlerts: c.qualityAlerts,
                weeklyReport: c.weeklyReport,
                showComplaints: c.showComplaints,
                financeAlerts: true,
                ...(c.version ? { expectedVersion: c.version } : {}),
              })
            ).status,
            403,
          );
        } finally {
          const current = (await request('GD', '/reports/monitoring')).data;
          assert.equal(
            (
              await request('GD', '/reports/monitoring', {
                ...pick(before),
                expectedVersion: current.version,
              })
            ).status,
            200,
          );
        }
      },
    );
  });
} finally {
  await close();
}
