import test from 'node:test';
import assert from 'node:assert/strict';
import { noPaymentDue, displayPaymentStatus } from '../frontend/src/payment-status.js';
test('Cancelled orders without a fee display paid for all viewers', () => {
  for (const cancellationFee of [0, '0.00'])
    assert.equal(
      displayPaymentStatus({ status: 'Huy', cancellationFee, paymentStatus: 'Unpaid' }),
      'Paid',
    );
});
test('A real cancellation fee remains unpaid until collected', () => {
  assert.equal(
    displayPaymentStatus({ status: 'Huy', cancellationFee: '50000.00', paymentStatus: 'Unpaid' }),
    'Unpaid',
  );
});
test('Missing costs and unfinished work must not be inferred as free', () => {
  for (const cancellationFee of [undefined, null, '', 'invalid'])
    assert.equal(noPaymentDue({ status: 'Huy', cancellationFee }), false);
  assert.equal(noPaymentDue({ status: 'ChoNhan', cancellationFee: 0 }), false);
  assert.equal(noPaymentDue({ status: 'HoanThanh' }), false);
  assert.equal(
    noPaymentDue({ status: 'HoanThanh', currentAcceptance: { status: 'Pending', total: 0 } }),
    false,
  );
});
test('Approved zero-cost completion has nothing to collect', () => {
  assert.equal(
    displayPaymentStatus({
      status: 'HoanThanh',
      paymentStatus: 'Unpaid',
      currentAcceptance: { status: 'Approved', total: '0.00' },
    }),
    'Paid',
  );
  assert.equal(
    noPaymentDue({ status: 'HoanThanh', currentAcceptance: { status: 'Approved', total: 50000 } }),
    false,
  );
});
