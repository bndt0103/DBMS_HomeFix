// Bank names/codes verified with https://api.vietqr.io/v2/banks on 2026-09-28.
// Receiving accounts are configured by ADMIN; no fictitious account is seeded.
export const banks = [
  ['VCB', 'Vietcombank'],
  ['ICB', 'VietinBank'],
  ['BIDV', 'BIDV'],
  ['VBA', 'Agribank'],
  ['TCB', 'Techcombank'],
  ['MB', 'MBBank'],
  ['ACB', 'ACB'],
  ['VPB', 'VPBank'],
  ['TPB', 'TPBank'],
  ['STB', 'Sacombank'],
  ['HDB', 'HDBank'],
  ['VIB', 'VIB'],
  ['OCB', 'OCB'],
  ['MSB', 'MSB'],
  ['SHB', 'SHB'],
].map(([code, name]) => ({ code, name }));
