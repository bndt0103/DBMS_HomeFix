// A missing quote is not proof that a service is free.
const isZero = (value) =>
  value !== null && value !== undefined && String(value).trim() !== '' && Number(value) === 0;
export function noPaymentDue(order) {
  if (order.status === 'Huy') return isZero(order.cancellationFee);
  return (
    order.status === 'HoanThanh' &&
    order.currentAcceptance?.status === 'Approved' &&
    isZero(order.currentAcceptance.total)
  );
}
export function displayPaymentStatus(order) {
  return noPaymentDue(order) ? 'Paid' : order.paymentStatus;
}
