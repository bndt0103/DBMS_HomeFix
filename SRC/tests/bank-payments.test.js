import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { paymentHarness } from './helpers/payments.mjs';
const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const allowed = /^HomeFix_.*Test/.test(process.env.DB_NAME || '');
test('Bank payment workflow, ownership, amounts and settlement', { skip: !allowed }, async (t) => {
  const h = await paymentHarness(base),
    { request, call, key } = h;
  let bank,
    a,
    o,
    transfer,
    receipt,
    bankReference = 'TESTREF' + h.stamp,
    initialWallet;
  await t.test('only ADMIN configures valid receiving accounts', async () => {
    assert.equal(
      (
        await call(
          'POST',
          '/bank-accounts',
          { bankCode: 'MB', accountNumber: '123', accountHolder: 'Test' },
          'KH',
        )
      ).status,
      403,
    );
    assert.equal(
      (
        await call(
          'POST',
          '/bank-accounts',
          { bankCode: 'MB', accountNumber: 'x', accountHolder: 'Test' },
          'ADMIN',
        )
      ).status,
      422,
    );
    bank = await h.bankAccount();
    assert.equal(
      (
        await call(
          'PATCH',
          '/bank-accounts/' + bank.id,
          { accountNumber: '123456789', isActive: true, expectedVersion: bank.version },
          'ADMIN',
        )
      ).status,
      422,
    );
  });
  await t.test('acceptance selects BANK and freezes server-calculated amount/account', async () => {
    const created = await h.acceptance();
    a = created.acceptance;
    o = created.order;
    const body = { decision: 'Approved', paymentMethod: 'BANK', expectedVersion: a.version };
    assert.equal(
      (await call('POST', `/orders/${o.id}/acceptances/${a.id}/decision`, body)).status,
      422,
    );
    await request('POST', `/orders/${o.id}/acceptances/${a.id}/decision`, {
      ...body,
      bankAccountId: bank.id,
    });
    o = await h.order(o.id);
    assert.equal(o.paymentMethod, 'BANK');
    assert.equal(o.paymentStatus, 'Unpaid');
    transfer = (await request('GET', `/orders/${o.id}/payment-details`)).requests[0];
    assert.equal(Number(transfer.amount), Number(a.total));
    assert.equal(transfer.accountNumber, bank.accountNumber);
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${o.id}/payments/cod`,
          { expectedVersion: o.version },
          'TECH',
          key(),
        )
      ).error.code,
      'PAYMENT_METHOD_MISMATCH',
    );
  });
  await t.test(
    'stale/malicious choices rejected; changing unsubmitted request cancels old reference',
    async () => {
      const choice = { method: 'BANK', bankAccountId: bank.id, expectedVersion: o.version };
      assert.equal(
        (
          await call(
            'POST',
            `/orders/${o.id}/payment-method`,
            { ...choice, amount: '1' },
            'KH',
            key(),
          )
        ).status,
        422,
      );
      assert.equal(
        (await call('POST', `/orders/${o.id}/payment-method`, choice, 'OTHER', key())).status,
        404,
      );
      const previous = transfer,
        keyValue = key();
      transfer = (
        await request('POST', `/orders/${o.id}/payment-method`, choice, 'KH', 201, keyValue)
      ).request;
      assert.equal(
        (await request('POST', `/orders/${o.id}/payment-method`, choice, 'KH', 200, keyValue))
          .request.id,
        transfer.id,
      );
      assert.notEqual(transfer.transferContent, previous.transferContent);
      assert.equal(
        (
          await call(
            'POST',
            '/payment-requests/' + previous.id + '/submit',
            { expectedVersion: previous.version, proofId: h.proof },
            'KH',
            key(),
          )
        ).status,
        409,
      );
    },
  );
  await t.test('proof ownership, pending status and no premature paid flag', async () => {
    assert.equal(
      (
        await call(
          'POST',
          '/payment-requests/' + transfer.id + '/submit',
          { expectedVersion: transfer.version, proofId: h.proof },
          'KH',
          key(),
        )
      ).status,
      404,
    );
    const proof = await h.upload('PaymentProof', 'KH', o.id);
    for (const [role, status] of [
      ['KT', 200],
      ['OTHER', 404],
      ['TECH', 404],
    ]) {
      const response = await fetch(base + '/uploads/' + proof, {
        headers: { Authorization: 'Bearer ' + h.tokens[role] },
      });
      assert.equal(response.status, status);
    }
    const submit = {
        expectedVersion: transfer.version,
        proofId: proof,
        customerReference: 'TEST CUSTOMER REFERENCE',
      },
      submitKey = key();
    transfer = await request(
      'POST',
      '/payment-requests/' + transfer.id + '/submit',
      submit,
      'KH',
      200,
      submitKey,
    );
    assert.equal(
      (
        await request(
          'POST',
          '/payment-requests/' + transfer.id + '/submit',
          submit,
          'KH',
          200,
          submitKey,
        )
      ).id,
      transfer.id,
    );
    assert.equal(transfer.status, 'PendingReview');
    o = await h.order(o.id);
    assert.equal(o.paymentStatus, 'Unpaid');
    assert.equal(
      (
        await call(
          'POST',
          `/orders/${o.id}/payment-method`,
          { method: 'COD', expectedVersion: o.version },
          'KH',
          key(),
        )
      ).error.code,
      'PAYMENT_UNDER_REVIEW',
    );
    assert.equal(
      (await call('POST', `/orders/${o.id}/reviews`, { rating: 5, comment: 'Not yet' })).status,
      409,
    );
  });
  await t.test(
    'rejection preserves unpaid status and allows resubmission without another transfer',
    async () => {
      assert.equal(
        (
          await call(
            'POST',
            '/payment-requests/' + transfer.id + '/decision',
            { decision: 'Rejected', expectedVersion: transfer.version },
            'KT',
            key(),
          )
        ).status,
        422,
      );
      await request(
        'POST',
        '/payment-requests/' + transfer.id + '/decision',
        {
          decision: 'Rejected',
          reason: 'TEST wrong proof; please check again',
          expectedVersion: transfer.version,
        },
        'KT',
        200,
        key(),
      );
      o = await h.order(o.id);
      assert.equal(o.paymentStatus, 'Unpaid');
      const previous = transfer;
      transfer = (await request('GET', `/orders/${o.id}/payment-details`)).requests[0];
      assert.equal(transfer.isActive, true);
      assert.equal(transfer.transferContent, previous.transferContent);
      transfer = await request(
        'POST',
        '/payment-requests/' + transfer.id + '/submit',
        { proofId: await h.upload('PaymentProof', 'KH', o.id), expectedVersion: transfer.version },
        'KH',
        200,
        key(),
      );
    },
  );
  await t.test('only KT confirms exact received amount; retries produce one receipt', async () => {
    const body = {
      decision: 'Approved',
      expectedVersion: transfer.version,
      receivedAmount: String(a.total),
      bankReference,
    };
    for (const role of ['KH', 'TECH', 'ADMIN'])
      assert.equal(
        (await call('POST', '/payment-requests/' + transfer.id + '/decision', body, role, key()))
          .status,
        403,
      );
    assert.equal(
      (
        await call(
          'POST',
          '/payment-requests/' + transfer.id + '/decision',
          { ...body, receivedAmount: '1' },
          'KT',
          key(),
        )
      ).error.code,
      'AMOUNT_MISMATCH',
    );
    initialWallet = Number((await request('GET', '/technicians/me/wallet', null, 'TECH')).balance);
    const token = key(),
      responses = await Promise.all([
        call('POST', '/payment-requests/' + transfer.id + '/decision', body, 'KT', token),
        call('POST', '/payment-requests/' + transfer.id + '/decision', body, 'KT', token),
      ]);
    assert.deepEqual(
      responses.map((r) => r.status),
      [200, 200],
    );
    assert.equal(responses[0].data.paymentId, responses[1].data.paymentId);
    assert.equal(
      (await call('POST', '/payment-requests/' + transfer.id + '/decision', body, 'KT', key()))
        .status,
      409,
    );
    o = await h.order(o.id);
    assert.equal(o.paymentStatus, 'Paid');
    const receipts = await request('GET', `/orders/${o.id}/payments`);
    assert.equal(receipts.length, 1);
    receipt = receipts[0];
    assert.equal(receipt.method, 'BANK');
    assert.equal(receipt.receivedBy, h.users.KT.id);
    assert.equal(
      Number((await request('GET', '/technicians/me/wallet', null, 'TECH')).balance),
      initialWallet,
    );
  });
  await t.test(
    'bank settlement credits net once, not COD debit; review belongs to technician',
    async () => {
      const settlement = (await request('GET', '/settlements', null, 'KT')).find(
          (s) => s.orderId === o.id,
        ),
        token = key(),
        body = { expectedVersion: settlement.version };
      await request('POST', '/settlements/' + settlement.id + '/confirm', body, 'KT', 200, token);
      await request('POST', '/settlements/' + settlement.id + '/confirm', body, 'KT', 200, token);
      const wallet = await request('GET', '/technicians/me/wallet', null, 'TECH');
      assert.equal(
        Number(wallet.balance),
        initialWallet + Number(receipt.amount) - Number(settlement.commissionAmount),
      );
      assert.equal(wallet.transactions.filter((x) => x.type === 'SettlementCredit').length, 1);
      const review = await request(
        'POST',
        `/orders/${o.id}/reviews`,
        { rating: 5, comment: 'TEST bank receipt verified' },
        'KH',
        201,
      );
      assert.equal(review.technicianId, h.users.TECH.id);
      assert.equal(
        (await request('GET', '/reports/finance', null, 'KT')).find((p) => p.orderId === o.id)
          .method,
        'BANK',
      );
    },
  );
  await t.test(
    'bank reference cannot pay another order; rejected transfer can return to COD',
    async () => {
      const created = await h.acceptance(),
        next = created.order,
        acc = created.acceptance;
      await request('POST', `/orders/${next.id}/acceptances/${acc.id}/decision`, {
        decision: 'Approved',
        paymentMethod: 'BANK',
        bankAccountId: bank.id,
        expectedVersion: acc.version,
      });
      let tr = (await request('GET', `/orders/${next.id}/payment-details`)).requests[0];
      tr = await request(
        'POST',
        '/payment-requests/' + tr.id + '/submit',
        { proofId: await h.upload('PaymentProof', 'KH', next.id), expectedVersion: tr.version },
        'KH',
        200,
        key(),
      );
      assert.equal(
        (
          await call(
            'POST',
            '/payment-requests/' + tr.id + '/decision',
            {
              decision: 'Approved',
              expectedVersion: tr.version,
              receivedAmount: String(acc.total),
              bankReference,
            },
            'KT',
            key(),
          )
        ).error.code,
        'BANK_REFERENCE_USED',
      );
      await request(
        'POST',
        '/payment-requests/' + tr.id + '/decision',
        {
          decision: 'Rejected',
          expectedVersion: tr.version,
          reason: 'TEST duplicate transaction reference',
        },
        'KT',
        200,
        key(),
      );
      const latest = await h.order(next.id);
      await request(
        'POST',
        `/orders/${next.id}/payment-method`,
        { method: 'COD', expectedVersion: latest.version },
        'KH',
        201,
        key(),
      );
      const cashOrder = await h.order(next.id);
      await request(
        'POST',
        `/orders/${next.id}/payments/cod`,
        { expectedVersion: cashOrder.version },
        'TECH',
        201,
        key(),
      );
      assert.equal((await request('GET', `/orders/${next.id}/payments`))[0].method, 'COD');
    },
  );
  fs.mkdirSync('test-results', { recursive: true });
  fs.writeFileSync(
    'test-results/bank-payments.json',
    JSON.stringify(
      { base, orderId: o.id, bankAccountId: bank.id, passed: true, at: new Date().toISOString() },
      null,
      2,
    ),
  );
});
