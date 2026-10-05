import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import sharp from 'sharp';
const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const evidence = [];
const tokens = {};
let order, assignment, material, acceptance, receipt, kid, customer, other, service;
async function call(method, path, body, role = 'KH', key) {
  const headers = {};
  if (tokens[role]) headers.Authorization = 'Bearer ' + tokens[role];
  if (body) headers['Content-Type'] = 'application/json';
  if (key) headers['Idempotency-Key'] = key;
  const r = await fetch(base + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await r.json();
  return { status: r.status, ...json };
}
async function login(email) {
  const r = await call(
    'POST',
    '/auth/login',
    { identifier: email, password: 'HomeFix@123' },
    'NONE',
  );
  assert.equal(r.status, 200, JSON.stringify(r));
  return r.data;
}
const key = () => crypto.randomUUID();
const reload = async () => {
  const r = await call('GET', '/orders/' + order.id);
  assert.equal(r.status, 200, JSON.stringify(r));
  order = r.data;
  return order;
};
async function upload(purpose, role, oid) {
  const buf = await sharp({ create: { width: 64, height: 64, channels: 3, background: '#227857' } })
    .png()
    .toBuffer();
  const f = new FormData();
  f.set('purpose', purpose);
  if (oid) f.set('orderId', String(oid));
  f.set('file', new Blob([buf], { type: 'image/png' }), 'test-evidence.png');
  const r = await fetch(base + '/uploads', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + tokens[role] },
    body: f,
  });
  const j = await r.json();
  assert.equal(r.status, 201, JSON.stringify(j));
  return j.data.id;
}
await test('HomeFix SQL Server integration', async (t) => {
  async function step(name, fn) {
    await t.test(name, async () => {
      const start = Date.now();
      try {
        await fn();
        evidence.push({ name, status: 'PASS', milliseconds: Date.now() - start });
      } catch (e) {
        evidence.push({ name, status: 'FAIL', message: e.message });
        throw e;
      }
    });
  }
  await step('TC01 Health và đăng nhập đủ 7 vai trò', async () => {
    assert.equal((await call('GET', '/health', null, 'NONE')).status, 200);
    for (const r of ['KH', 'KTV', 'DPV', 'CSKH', 'KT', 'ADMIN', 'GD']) {
      const v = await login(r.toLowerCase() + '@homefix.local');
      tokens[r] = v.accessToken;
      assert.equal(v.user.role, r);
      assert.equal(v.user.passwordHash, undefined);
    }
    service = (await call('GET', '/services', null, 'NONE')).data[0];
  });
  await step(
    'TC02 Tạo 2 KH bằng ADMIN; đăng ký công khai bắt buộc OTP và cấm tự cấp ADMIN',
    async () => {
      const stamp = String(Date.now()).slice(-8);
      for (const [r, n] of [
        ['KH', '1'],
        ['OTHER', '2'],
      ]) {
        const phone = '0' + n + stamp;
        const result = await call(
          'POST',
          '/users',
          {
            fullName: 'Khách kiểm thử ' + n,
            phone,
            email: `test${n}-${stamp}@homefix.local`,
            initialPassword: 'HomeFix@123',
            role: 'KH',
          },
          'ADMIN',
        );
        assert.equal(result.status, 201, JSON.stringify(result));
        const v = await login(`test${n}-${stamp}@homefix.local`);
        tokens[r] = v.accessToken;
        if (r === 'KH') customer = v.user;
        else other = v.user;
      }
      assert.equal(
        (
          await call(
            'POST',
            '/auth/register',
            { fullName: 'Thiếu OTP', phone: '0991112224', password: 'HomeFix@123' },
            'NONE',
          )
        ).status,
        422,
      );
      assert.equal(
        (
          await call(
            'POST',
            '/auth/register',
            {
              fullName: 'Không hợp lệ',
              phone: '0991112223',
              password: 'HomeFix@123',
              role: 'ADMIN',
            },
            'NONE',
          )
        ).status,
        422,
      );
    },
  );
  await step('TC03 Chuẩn bị KTV riêng, nạp ví có chứng từ và duyệt', async () => {
    const stamp = String(Date.now()).slice(-8);
    const r = await call(
      'POST',
      '/users',
      {
        fullName: 'Thợ kiểm thử ' + stamp,
        phone: '03' + stamp,
        email: `tech-${stamp}@homefix.local`,
        initialPassword: 'HomeFix@123',
        role: 'KTV',
        technicianProfile: { skillGroup: service.groupCode, serviceArea: 'TP.HCM' },
      },
      'ADMIN',
    );
    assert.equal(r.status, 201, JSON.stringify(r));
    kid = r.data.id;
    tokens.TECH = (await login(`tech-${stamp}@homefix.local`)).accessToken;
    const proof = await upload('WalletProof', 'TECH');
    const w = await call(
      'POST',
      '/wallet-requests',
      { type: 'Deposit', amount: '1000000.00', note: 'Nạp ví dữ liệu kiểm thử', proofId: proof },
      'TECH',
      key(),
    );
    assert.equal(w.status, 201, JSON.stringify(w));
    const d = await call(
      'POST',
      `/wallet-requests/${w.data.id}/decision`,
      { decision: 'Approved', expectedVersion: w.data.version },
      'KT',
      key(),
    );
    assert.equal(d.status, 200, JSON.stringify(d));
    const k = await call('GET', '/technicians/me', null, 'TECH');
    assert.equal(
      (
        await call(
          'PATCH',
          '/technicians/me/availability',
          { availability: 'SanSang', expectedVersion: k.data.version },
          'TECH',
        )
      ).status,
      200,
    );
  });
  await step('TC04 Input không hợp lệ và mật khẩu dài quá 72 byte', async () => {
    assert.equal(
      (
        await call(
          'POST',
          '/orders',
          { serviceId: service.id, address: 'x', description: 'x', total: 1 },
          'KH',
          key(),
        )
      ).status,
      422,
    );
    assert.equal(
      (
        await call(
          'POST',
          '/auth/register',
          { fullName: 'Test', phone: '0991112223', password: 'á'.repeat(40) },
          'NONE',
        )
      ).status,
      422,
    );
    const odd = new Date(Date.now() + 86400000);
    odd.setUTCHours(2, 0, 17, 0);
    assert.equal(
      (
        await call(
          'POST',
          '/orders',
          {
            serviceId: service.id,
            address: '1 Võ Văn Ngân, Thủ Đức, TP.HCM',
            description: 'Kiểm tra lịch không đúng khung.',
            scheduledAt: odd.toISOString(),
          },
          'KH',
          key(),
        )
      ).status,
      422,
    );
  });
  await step('TC05 Upload ảnh, đặt đơn cùng key đồng thời chỉ tạo một đơn', async () => {
    const attachment = await upload('OrderFault', 'KH');
    const body = {
      serviceId: service.id,
      address: '1 Võ Văn Ngân, Thủ Đức, TP.HCM',
      description: '[TEST] Thiết bị không hoạt động, cần kiểm tra.',
      scheduledAt: null,
      attachmentIds: [attachment],
    };
    const requestKey = key();
    const responses = await Promise.all([
      call('POST', '/orders', body, 'KH', requestKey),
      call('POST', '/orders', body, 'KH', requestKey),
    ]);
    assert.deepEqual(responses.map((r) => r.status).sort(), [200, 201], JSON.stringify(responses));
    assert.equal(responses[0].data.id, responses[1].data.id);
    order = responses[0].data;
    assert.equal(order.status, 'ChoTiepNhan');
    assert.equal(
      (
        await call(
          'POST',
          '/orders',
          { ...body, description: 'Đổi dữ liệu cùng key' },
          'KH',
          requestKey,
        )
      ).status,
      409,
    );
  });
  await step('TC06 Chặn KH khác xem đơn/ảnh và thợ chưa được giao', async () => {
    assert.equal((await call('GET', '/orders/' + order.id, null, 'OTHER')).status, 404);
    assert.equal((await call('GET', '/orders/' + order.id, null, 'TECH')).status, 404);
    const files = await call('GET', `/orders/${order.id}/attachments`);
    const r = await fetch(base + '/uploads/' + files.data[0].id, {
      headers: { Authorization: 'Bearer ' + tokens.OTHER },
    });
    assert.equal(r.status, 404);
  });
  await step('TC07 Không điều phối khi KH chưa duyệt', async () => {
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${order.id}/assignments`,
          { technicianId: kid, expectedVersion: order.version },
          'DPV',
        )
      ).status,
      409,
    );
  });
  await step('TC08 Lập báo giá sơ bộ; đúng chủ đơn duyệt; bấm lại bị chặn', async () => {
    const p = await call(
      'POST',
      `/orders/${order.id}/preliminary-quotes`,
      { diagnosis: 'Kiểm tra lỗi hoạt động tại nhà.', expectedVersion: order.version },
      'DPV',
    );
    assert.equal(p.status, 201, JSON.stringify(p));
    assert.equal(Number(p.data.total), 350000);
    const body = { decision: 'Approved', expectedVersion: p.data.version };
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${order.id}/preliminary-quotes/${p.data.id}/decision`,
          body,
          'OTHER',
        )
      ).status,
      404,
    );
    assert.equal(
      (await call('POST', `/orders/${order.id}/preliminary-quotes/${p.data.id}/decision`, body))
        .status,
      200,
    );
    assert.equal(
      (await call('POST', `/orders/${order.id}/preliminary-quotes/${p.data.id}/decision`, body))
        .status,
      409,
    );
    await reload();
  });
  await step('TC09 Hai điều phối cùng giao chỉ có một lệnh', async () => {
    const body = { technicianId: kid, expectedVersion: order.version };
    const r = await Promise.all([
      call('POST', `/orders/${order.id}/assignments`, body, 'DPV'),
      call('POST', `/orders/${order.id}/assignments`, body, 'DPV'),
    ]);
    assert.deepEqual(r.map((x) => x.status).sort(), [201, 409], JSON.stringify(r));
    assignment = r.find((x) => x.status === 201).data;
  });
  await step('TC10 Sai KTV không nhận; KTV đúng nhận được', async () => {
    const body = { decision: 'Accepted', expectedVersion: assignment.version };
    assert.equal(
      (await call('POST', `/assignments/${assignment.id}/decision`, body, 'KTV')).status,
      404,
    );
    const a = await call('POST', `/assignments/${assignment.id}/decision`, body, 'TECH');
    assert.equal(a.status, 200, JSON.stringify(a));
    await reload();
    assert.equal(order.status, 'DaTiepNhan');
  });
  await step('TC11 Tiến độ đúng thứ tự, chặn nhảy bước và phiên bản cũ', async () => {
    assert.equal(
      (
        await call(
          'PATCH',
          `/orders/${order.id}/progress`,
          { nextStatus: 'DangXuLy', expectedVersion: order.version },
          'TECH',
        )
      ).status,
      409,
    );
    const old = order.version;
    for (const nextStatus of ['DangDiChuyen', 'DaDenNoi', 'DangXuLy']) {
      const r = await call(
        'PATCH',
        `/orders/${order.id}/progress`,
        { nextStatus, expectedVersion: order.version },
        'TECH',
      );
      assert.equal(r.status, 200, JSON.stringify(r));
      order = r.data;
    }
    assert.equal(
      (
        await call(
          'PATCH',
          `/orders/${order.id}/progress`,
          { nextStatus: 'DangXuLy', expectedVersion: old },
          'TECH',
        )
      ).status,
      409,
    );
  });
  await step('TC12 Vật tư âm bị từ chối; phiếu hợp lệ tính tiền ở SQL', async () => {
    const body = {
      items: [
        {
          name: 'Van một chiều',
          quantity: '1.00',
          unitPrice: '220000.00',
          unit: 'cái',
          warrantyMonths: 6,
        },
      ],
      note: 'Thay van bị hỏng',
      expectedVersion: order.version,
    };
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${order.id}/material-quotes`,
          { ...body, items: [{ ...body.items[0], quantity: '-1' }] },
          'TECH',
        )
      ).status,
      422,
    );
    const r = await call('POST', `/orders/${order.id}/material-quotes`, body, 'TECH');
    assert.equal(r.status, 201, JSON.stringify(r));
    material = r.data;
    assert.equal(Number(material.total), 220000);
    await reload();
  });
  let photo;
  await step('TC13 Không nghiệm thu khi vật tư chưa được khách duyệt', async () => {
    photo = await upload('AcceptancePhoto', 'TECH', order.id);
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${order.id}/acceptances`,
          {
            cause: 'Van cũ đã hỏng.',
            solution: 'Đã thay van mới và thử máy.',
            photoIds: [photo],
            expectedVersion: order.version,
          },
          'TECH',
        )
      ).status,
      409,
    );
    const r = await call('POST', `/orders/${order.id}/material-quotes/${material.id}/decision`, {
      decision: 'Approved',
      expectedVersion: material.version,
    });
    assert.equal(r.status, 200, JSON.stringify(r));
    await reload();
  });
  await step('TC14 Thiếu ảnh không nghiệm thu; có ảnh đúng tạo phiếu 570.000', async () => {
    const body = {
      cause: 'Van cũ đã hỏng.',
      solution: 'Đã thay van mới và thử máy.',
      photoIds: [],
      expectedVersion: order.version,
    };
    assert.equal((await call('POST', `/orders/${order.id}/acceptances`, body, 'TECH')).status, 422);
    const r = await call(
      'POST',
      `/orders/${order.id}/acceptances`,
      { ...body, photoIds: [photo] },
      'TECH',
    );
    assert.equal(r.status, 201, JSON.stringify(r));
    acceptance = r.data;
    assert.equal(Number(acceptance.total), 570000);
  });
  await step('TC15 KTV không được nghiệm thu thay KH; KH duyệt đóng ca', async () => {
    const body = { decision: 'Approved', expectedVersion: acceptance.version };
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${order.id}/acceptances/${acceptance.id}/decision`,
          body,
          'TECH',
        )
      ).status,
      403,
    );
    assert.equal(
      (await call('POST', `/orders/${order.id}/acceptances/${acceptance.id}/decision`, body))
        .status,
      200,
    );
    await reload();
    assert.equal(order.status, 'HoanThanh');
    assert.equal(order.paymentStatus, 'Unpaid');
  });
  await step('TC16 Không đánh giá trước thanh toán', async () => {
    assert.equal(
      (await call('POST', `/orders/${order.id}/reviews`, { rating: 5, comment: 'Dịch vụ tốt' }))
        .status,
      409,
    );
  });
  await step('TC17 Chỉ KTV thực hiện thu COD; retry không nhân đôi', async () => {
    const body = { expectedVersion: order.version },
      requestKey = key();
    for (const role of ['KH', 'KT', 'ADMIN'])
      assert.equal(
        (await call('POST', `/orders/${order.id}/payments/cod`, body, role, requestKey)).status,
        403,
      );
    const r = await Promise.all([
      call('POST', `/orders/${order.id}/payments/cod`, body, 'TECH', requestKey),
      call('POST', `/orders/${order.id}/payments/cod`, body, 'TECH', requestKey),
    ]);
    assert.deepEqual(r.map((x) => x.status).sort(), [200, 201], JSON.stringify(r));
    receipt = r[0].data;
    assert.equal(Number(receipt.amount), 570000);
    await reload();
    assert.equal(order.paymentStatus, 'Paid');
    assert.equal(
      Number((await call('GET', '/technicians/me/wallet', null, 'TECH')).data.balance),
      1000000,
    );
  });
  await step('TC18 Đối soát một lần: 45.000 hoa hồng, ví còn 955.000', async () => {
    const all = await call('GET', '/settlements', null, 'KT');
    const s = all.data.find((s) => s.orderId === order.id),
      requestKey = key(),
      body = { expectedVersion: s.version };
    const a = await call('POST', `/settlements/${s.id}/confirm`, body, 'KT', requestKey);
    assert.equal(a.status, 200, JSON.stringify(a));
    assert.equal(
      (await call('POST', `/settlements/${s.id}/confirm`, body, 'KT', requestKey)).status,
      200,
    );
    const wallet = await call('GET', '/technicians/me/wallet', null, 'TECH');
    assert.equal(Number(wallet.data.balance), 955000);
    assert.equal(wallet.data.transactions.filter((x) => x.type === 'Commission').length, 1);
  });
  await step('TC19 Một đánh giá/đơn, giới hạn 1–5 sao', async () => {
    assert.equal(
      (await call('POST', `/orders/${order.id}/reviews`, { rating: 6, comment: 'Tốt' })).status,
      422,
    );
    const r = await call('POST', `/orders/${order.id}/reviews`, {
      rating: 5,
      comment: 'Tư vấn rõ ràng và sửa đúng hẹn.',
    });
    assert.equal(r.status, 201, JSON.stringify(r));
    assert.equal(
      (await call('POST', `/orders/${order.id}/reviews`, { rating: 5, comment: 'Lặp' })).status,
      409,
    );
  });
  await step('TC20 CSKH nhận/xử lý phiếu và KH khác không xem được', async () => {
    const r = await call('POST', '/support/tickets', {
      orderId: order.id,
      type: 'Complaint',
      description: 'Cần hướng dẫn sử dụng sau khi sửa chữa.',
    });
    assert.equal(r.status, 201, JSON.stringify(r));
    assert.equal((await call('GET', '/support/tickets/' + r.data.id, null, 'OTHER')).status, 404);
    assert.equal(
      (
        await call(
          'PATCH',
          '/support/tickets/' + r.data.id,
          {
            status: 'Resolved',
            resolution: 'Đã gọi hướng dẫn khách sử dụng thiết bị.',
            expectedVersion: r.data.version,
          },
          'CSKH',
        )
      ).status,
      200,
    );
  });
  await step('TC21 Báo cáo dữ liệu thật và phân quyền giám đốc', async () => {
    const r = await call('GET', '/reports/summary', null, 'GD');
    assert.equal(r.status, 200);
    assert.ok(Number(r.data.gmv) >= 570000);
    assert.ok(Number(r.data.commissionRevenue) >= 45000);
    assert.equal((await call('GET', '/reports/summary')).status, 403);
    const income = await call('GET', '/technicians/me/income', null, 'TECH');
    assert.equal(Number(income.data.income), 305000);
  });
  await step('TC22 Logout thu hồi token; không công khai hash/secret', async () => {
    assert.equal((await call('GET', '/users/me', null, 'OTHER')).data.passwordHash, undefined);
    assert.equal((await call('POST', '/auth/logout', {}, 'OTHER')).status, 200);
    assert.equal((await call('GET', '/users/me', null, 'OTHER')).status, 401);
  });
  const db = await import('../backend/src/db.js');
  const checked = async (method, path, body, role = 'KH', status = 200, idem) => {
    const r = await call(method, path, body, role, idem);
    assert.equal(r.status, status, JSON.stringify(r));
    return r.data;
  };
  const newOrder = () =>
    checked(
      'POST',
      '/orders',
      {
        serviceId: service.id,
        address: '1 Võ Văn Ngân, Thủ Đức, TP.HCM',
        description: '[EDGE TEST] Kiểm tra nhánh ngoại lệ và khôi phục',
      },
      'KH',
      201,
      key(),
    );
  const ready = async () => {
    const k = await checked('GET', '/technicians/me', null, 'TECH');
    if (k.availability !== 'SanSang')
      await checked(
        'PATCH',
        '/technicians/me/availability',
        { availability: 'SanSang', expectedVersion: k.version },
        'TECH',
      );
  };
  const approved = async () => {
    let o = await newOrder();
    const p = await checked(
      'POST',
      `/orders/${o.id}/preliminary-quotes`,
      { diagnosis: 'Kiểm tra tại nhà theo giá danh mục.', expectedVersion: o.version },
      'DPV',
      201,
    );
    await checked('POST', `/orders/${o.id}/preliminary-quotes/${p.id}/decision`, {
      decision: 'Approved',
      expectedVersion: p.version,
    });
    return checked('GET', '/orders/' + o.id);
  };
  const assign = async (o) => {
    await ready();
    return checked(
      'POST',
      `/orders/${o.id}/assignments`,
      { technicianId: kid, expectedVersion: o.version },
      'DPV',
      201,
    );
  };
  const progress = async (o, nextStatus) =>
    checked(
      'PATCH',
      `/orders/${o.id}/progress`,
      { nextStatus, expectedVersion: o.version },
      'TECH',
    );
  const setSetting = async (k, v) => {
    const s = (await checked('GET', '/settings', null, 'ADMIN')).find((x) => x.key === k);
    await checked('PATCH', '/settings/' + k, { value: v, expectedVersion: s.version }, 'ADMIN');
  };
  try {
    await step('TC23 Hủy trước xuất phát không phát sinh phí', async () => {
      const o = await newOrder();
      const c = await checked('POST', `/orders/${o.id}/cancel`, {
        reason: 'Khách đổi lịch sinh hoạt.',
        expectedVersion: o.version,
      });
      assert.equal(c.status, 'Huy');
      assert.equal(Number(c.cancellationFee), 0);
    });
    await step('TC24 Từ chối báo giá đóng đơn và không điều phối', async () => {
      const o = await newOrder(),
        p = await checked(
          'POST',
          `/orders/${o.id}/preliminary-quotes`,
          { diagnosis: 'Cần kiểm tra máy tại nhà.', expectedVersion: o.version },
          'DPV',
          201,
        );
      await checked('POST', `/orders/${o.id}/preliminary-quotes/${p.id}/decision`, {
        decision: 'Rejected',
        reason: 'Chưa phù hợp nhu cầu.',
        expectedVersion: p.version,
      });
      const c = await checked('GET', '/orders/' + o.id);
      assert.equal(c.status, 'Huy');
      assert.equal(
        (
          await call(
            'POST',
            `/orders/${o.id}/assignments`,
            { technicianId: kid, expectedVersion: c.version },
            'DPV',
          )
        ).status,
        409,
      );
    });
    await step('TC25 KTV từ chối trả đơn; mất quyền xem thông tin khách', async () => {
      const o = await approved(),
        a = await assign(o);
      await checked(
        'POST',
        `/assignments/${a.id}/decision`,
        { decision: 'Rejected', reason: 'Không thể đến đúng giờ.', expectedVersion: a.version },
        'TECH',
      );
      assert.equal((await checked('GET', '/orders/' + o.id)).status, 'ChoPhanCong');
      assert.equal((await call('GET', '/orders/' + o.id, null, 'TECH')).status, 404);
      assert.ok(
        !(await checked('GET', '/technicians/me/assignments', null, 'TECH')).some(
          (a) => a.orderId === o.id,
        ),
      );
    });
    await step('TC26 Lệnh hết hạn: đóng lệnh, trả đơn, không được nhận trễ', async () => {
      const o = await approved(),
        a = await assign(o);
      await db.transaction(null, (t) =>
        db.q(
          'UPDATE dbo.LenhDieuPhoi SET NgayHetHan=DATEADD(second,-2,SYSUTCDATETIME()) WHERE Id=@Id',
          { id: a.id },
          t,
        ),
      );
      const current = await checked('GET', '/assignments/' + a.id, null, 'TECH');
      assert.equal(
        (
          await call(
            'POST',
            `/assignments/${a.id}/decision`,
            { decision: 'Accepted', expectedVersion: current.version },
            'TECH',
          )
        ).status,
        409,
      );
      const changed = await checked('GET', '/orders/' + o.id);
      assert.equal(changed.status, 'ChoPhanCong');
      assert.equal((await call('GET', '/orders/' + o.id, null, 'TECH')).status, 404);
      assert.equal((await checked('GET', '/technicians/me', null, 'TECH')).availability, 'TamBan');
    });
    await step('TC27 Phí hủy giữ mức lúc đặt dù quản trị đổi cấu hình', async () => {
      const old = (await checked('GET', '/settings', null, 'ADMIN')).find(
        (s) => s.key === 'cancellationFee',
      ).value;
      try {
        await setSetting('cancellationFee', '60000');
        let o = await approved();
        assert.equal(Number(o.cancellationFeeSnapshot), 60000);
        await setSetting('cancellationFee', '70000');
        const a = await assign(o);
        await checked(
          'POST',
          `/assignments/${a.id}/decision`,
          { decision: 'Accepted', expectedVersion: a.version },
          'TECH',
        );
        o = await checked('GET', '/orders/' + o.id);
        o = await progress(o, 'DangDiChuyen');
        const c = await checked('POST', `/orders/${o.id}/cancel`, {
          reason: 'Khách có việc đột xuất.',
          expectedVersion: o.version,
        });
        assert.equal(Number(c.cancellationFee), 60000);
        assert.equal(c.cancellationPaymentStatus, 'Unpaid');
        assert.equal(
          (await checked('GET', '/technicians/me', null, 'TECH')).activeAssignmentSummary,
          null,
        );
      } finally {
        await setSetting('cancellationFee', old);
      }
    });
    let rework;
    await step('TC28 Vật tư bị từ chối được lập phiên bản mới; cấm hủy khi đã đến', async () => {
      let o = await approved();
      const a = await assign(o);
      await checked(
        'POST',
        `/assignments/${a.id}/decision`,
        { decision: 'Accepted', expectedVersion: a.version },
        'TECH',
      );
      o = await checked('GET', '/orders/' + o.id);
      for (const s of ['DangDiChuyen', 'DaDenNoi', 'DangXuLy']) o = await progress(o, s);
      assert.equal(
        (
          await call('POST', `/orders/${o.id}/cancel`, {
            reason: 'Đề nghị hủy sau khi thợ đến.',
            expectedVersion: o.version,
          })
        ).error.code,
        'SUPPORT_REQUIRED',
      );
      const body = {
        items: [
          { name: 'Van', quantity: '1', unitPrice: '200000', unit: 'cái', warrantyMonths: 6 },
        ],
        expectedVersion: o.version,
      };
      const m = await checked('POST', `/orders/${o.id}/material-quotes`, body, 'TECH', 201);
      await checked('POST', `/orders/${o.id}/material-quotes/${m.id}/decision`, {
        decision: 'Rejected',
        reason: 'Chọn vật tư khác phù hợp hơn.',
        expectedVersion: m.version,
      });
      o = await checked('GET', '/orders/' + o.id);
      const next = await checked(
        'POST',
        `/orders/${o.id}/material-quotes`,
        { ...body, expectedVersion: o.version },
        'TECH',
        201,
      );
      assert.equal(next.revision, 2);
      await checked('POST', `/orders/${o.id}/material-quotes/${next.id}/decision`, {
        decision: 'Approved',
        expectedVersion: next.version,
      });
      rework = await checked('GET', '/orders/' + o.id);
    });
    await step('TC29 Nghiệm thu lại có lịch sử; bật chữ ký bắt buộc được thực thi', async () => {
      const old = (await checked('GET', '/settings', null, 'ADMIN')).find(
        (s) => s.key === 'signatureRequired',
      ).value;
      try {
        let o = rework;
        const body = {
          cause: 'Van cũ bị hỏng.',
          solution: 'Thay van và chạy thử ổn định.',
          photoIds: [await upload('AcceptancePhoto', 'TECH', o.id)],
          expectedVersion: o.version,
        };
        const a = await checked('POST', `/orders/${o.id}/acceptances`, body, 'TECH', 201);
        await checked('POST', `/orders/${o.id}/acceptances/${a.id}/decision`, {
          decision: 'Rejected',
          reason: 'Kiểm tra lại tiếng kêu khi chạy.',
          expectedVersion: a.version,
        });
        o = await checked('GET', '/orders/' + o.id);
        assert.equal(o.status, 'DangXuLy');
        const next = await checked(
          'POST',
          `/orders/${o.id}/acceptances`,
          {
            ...body,
            photoIds: [await upload('AcceptancePhoto', 'TECH', o.id)],
            expectedVersion: o.version,
          },
          'TECH',
          201,
        );
        assert.equal(next.revision, 2);
        await setSetting('signatureRequired', 'true');
        const decision = { decision: 'Approved', expectedVersion: next.version };
        assert.equal(
          (await call('POST', `/orders/${o.id}/acceptances/${next.id}/decision`, decision)).error
            .code,
          'SIGNATURE_REQUIRED',
        );
        decision.signatureId = await upload('CustomerSignature', 'KH', o.id);
        await checked('POST', `/orders/${o.id}/acceptances/${next.id}/decision`, decision);
      } finally {
        await setSetting('signatureRequired', old);
      }
    });
    await step('TC30 Hai yêu cầu rút không thể làm ví âm', async () => {
      const requests = [];
      for (let i = 0; i < 2; i++)
        requests.push(
          await checked(
            'POST',
            '/wallet-requests',
            { type: 'Withdrawal', amount: '600000', note: 'Rút tiền kiểm thử giới hạn số dư.' },
            'TECH',
            201,
            key(),
          ),
        );
      const outcomes = await Promise.all(
        requests.map((r) =>
          call(
            'POST',
            `/wallet-requests/${r.id}/decision`,
            { decision: 'Approved', expectedVersion: r.version },
            'KT',
            key(),
          ),
        ),
      );
      assert.deepEqual(outcomes.map((r) => r.status).sort(), [200, 409]);
      assert.equal(
        Number((await checked('GET', '/technicians/me/wallet', null, 'TECH')).balance),
        355000,
      );
    });
    await step('TC31 SQL từ chối sửa sổ ví và biên nhận COD', async () => {
      await assert.rejects(
        db.transaction(null, (t) =>
          db.q('UPDATE dbo.GiaoDichVi SET SoTien=1 WHERE KyThuatVienId=@Id', { id: kid }, t),
        ),
        /LEDGER_IMMUTABLE/,
      );
      await assert.rejects(
        db.transaction(null, (t) =>
          db.q('UPDATE dbo.ThanhToan SET SoTien=1 WHERE DonHangId=@Id', { id: order.id }, t),
        ),
        /PAYMENT_IMMUTABLE/,
      );
      assert.equal(
        Number((await checked('GET', `/orders/${order.id}/invoice`)).receipt.amount),
        570000,
      );
    });
    await step('TC32 Trigger nhiều dòng tính đúng số dư và rollback nguyên giao dịch', async () => {
      const before = Number(
        (await db.one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: kid })).balance,
      );
      const rollback = new Error('ROLLBACK_TEST');
      await assert.rejects(
        db.transaction(null, async (t) => {
          await db.q(
            "INSERT dbo.GiaoDichVi(KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu) VALUES(@Id,'Deposit',12345,'RollbackTest',-1,N'Test'),(@Id,'Deposit',6789,'RollbackTest',-2,N'Test')",
            { id: kid },
            t,
          );
          assert.equal(
            Number(
              (await db.one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: kid }, t))
                .balance,
            ),
            before + 19134,
          );
          throw rollback;
        }),
        (e) => e === rollback,
      );
      assert.equal(
        Number(
          (await db.one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: kid })).balance,
        ),
        before,
      );
      assert.equal(
        (await db.one("SELECT COUNT(*) n FROM dbo.GiaoDichVi WHERE LoaiThamChieu='RollbackTest'"))
          .n,
        0,
      );
    });
    await step('TC33 Trigger chặn đánh giá trực tiếp cho đơn chưa hoàn thành', async () => {
      const o = await newOrder();
      await assert.rejects(
        db.transaction(null, (t) =>
          db.q(
            'INSERT dbo.DanhGia(DonHangId,KhachHangId,KyThuatVienId,DiemDanhGia,NhanXet) VALUES(@oid,@cid,@kid,5,@GhiChu)',
            { oid: o.id, cid: customer.id, kid, note: 'Test trigger' },
            t,
          ),
        ),
        /REVIEW_NOT_ELIGIBLE/,
      );
      assert.equal((await checked('GET', `/orders/${o.id}/reviews`)).length, 0);
    });
    await step('TC34 Ảnh giả và API thiếu xác thực bị chặn', async () => {
      const f = new FormData();
      f.set('purpose', 'OrderFault');
      f.set('file', new Blob(['<script>bad</script>'], { type: 'image/png' }), 'fake.png');
      assert.equal(
        (
          await fetch(base + '/uploads', {
            method: 'POST',
            headers: { Authorization: 'Bearer ' + tokens.KH },
            body: f,
          })
        ).status,
        415,
      );
      assert.equal((await call('GET', '/users/me', null, 'NONE')).status, 401);
      assert.equal((await call('GET', '/settings')).status, 403);
    });
    await step(
      'TC35 Không khóa quản trị viên cuối cùng; không lộ mật khẩu trong danh sách',
      async () => {
        const users = await checked('GET', '/users', null, 'ADMIN');
        assert.ok(users.every((u) => u.passwordHash === undefined));
        const admins = (
          await checked('GET', '/users?role=ADMIN&status=active', null, 'ADMIN')
        ).filter((u) => u.isActive);
        assert.equal(admins.length, 1);
        const a = admins[0];
        assert.equal(
          (
            await call(
              'PATCH',
              '/users/' + a.id,
              {
                fullName: a.fullName,
                role: a.role,
                skillGroup: 'DienLanh',
                isActive: false,
                expectedVersion: a.version,
              },
              'ADMIN',
            )
          ).status,
          409,
        );
      },
    );
  } finally {
    await db.close();
    fs.mkdirSync('test-results', { recursive: true });
    fs.writeFileSync(
      'test-results/api-results.json',
      JSON.stringify(
        { executedAt: new Date().toISOString(), base, orderId: order?.id, cases: evidence },
        null,
        2,
      ),
    );
  }
});
