import fs from 'node:fs';
import assert from 'node:assert/strict';
import { config } from '../backend/src/config.js';
import { sql, pool, one, q, close } from '../backend/src/db.js';

if (!/^HomeFix_DBMS_.*Test/.test(config.database)) {
  throw new Error('Chỉ đo trên CSDL HomeFix_DBMS_*Test. Dữ liệu sinh thêm được rollback.');
}
const tx = new sql.Transaction(await pool());
await tx.begin();
try {
  const service = await one('SELECT TOP 1 Id,Ten,MaNhom FROM dbo.DichVu', {}, tx);
  const customers = await q(
    "SELECT TOP 2 Id,HoTen,SoDienThoai FROM dbo.NguoiDung WHERE VaiTro='KH' ORDER BY Id",
    {},
    tx,
  );
  assert.equal(customers.length, 2);
  await q(
    `
    ;WITH numbers AS (
      SELECT TOP (50000) ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) n
      FROM sys.all_objects a CROSS JOIN sys.all_objects b
    )
    INSERT dbo.DonHang(KhachHangId,DichVuId,TenDichVu,NhomDichVu,TenLienHe,SoDienThoaiLienHe,DiaChi,MoTa)
    SELECT CASE WHEN n%1000=0 THEN @rare ELSE @common END,@service,@Ten,@group,
      N'Khách hàng đo hiệu năng','0999999999',N'Địa chỉ dữ liệu đo',REPLICATE(N'Mô tả ',150)
    FROM numbers;
    UPDATE STATISTICS dbo.DonHang IX_DonHang_KhachHang WITH FULLSCAN;
  `,
    {
      rare: customers[1].id,
      common: customers[0].id,
      service: service.id,
      name: service.name,
      group: service.groupCode,
    },
    tx,
  );
  const evidence = [];
  for (const [label, index] of [
    ['clustered_scan', '0'],
    ['customer_index', 'IX_DonHang_KhachHang'],
  ]) {
    const messages = [];
    const request = new sql.Request(tx);
    request.input('customer', sql.Int, customers[1].id);
    request.on('info', (info) => messages.push(info.message));
    const start = performance.now();
    const result = await request.query(`
      SET STATISTICS IO ON;
      SET STATISTICS TIME ON;
      SELECT Id,KhachHangId,NgayTao FROM dbo.DonHang WITH(INDEX(${index}))
      WHERE KhachHangId=@customer ORDER BY NgayTao DESC OPTION(RECOMPILE);
      SET STATISTICS IO OFF;
      SET STATISTICS TIME OFF;
    `);
    evidence.push({
      label,
      rows: result.recordset.length,
      milliseconds: +(performance.now() - start).toFixed(2),
      messages,
    });
  }
  assert.equal(evidence[0].rows, evidence[1].rows);
  fs.mkdirSync('../DOC/evidence', { recursive: true });
  fs.writeFileSync(
    '../DOC/evidence/index-benchmark.json',
    JSON.stringify(
      {
        addedRows: 50000,
        query: 'Loc KhachHangId, sap xep NgayTao giam dan',
        note: 'Same transaction and result; INDEX(0) is a forced scan baseline, not an optimizer prediction. Times are one local run, not an SLA.',
        evidence,
      },
      null,
      2,
    ),
  );
  console.log(JSON.stringify(evidence));
} finally {
  await tx.rollback();
  await close();
}
