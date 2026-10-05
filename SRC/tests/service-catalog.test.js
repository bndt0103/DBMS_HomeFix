import test from 'node:test';
import assert from 'node:assert/strict';
import { q, transaction, close } from '../backend/src/db.js';
import { applyServiceCatalog } from '../scripts/service-catalog.js';
import { serviceCatalog } from '../database/service-catalog.js';
test(
  'catalog migration preserves custom services, prices, IDs and repeats without writes',
  { skip: !/^HomeFix_.*Test/.test(process.env.DB_NAME || '') },
  async () => {
    try {
      await transaction(null, async (t) => {
        await q('DELETE FROM dbo.PhienBanCSDL WHERE PhienBan=6', {}, t);
        const columns = 'Id,Ten,MaNhom,MoTa,PhiKiemTra,TienCong,TyLeHoaHong,DangHoatDong,PhoBien';
        const before = await q('SELECT ' + columns + ' FROM dbo.DichVu ORDER BY Id', {}, t);
        await applyServiceCatalog(t);
        const after = await q('SELECT ' + columns + ' FROM dbo.DichVu ORDER BY Id', {}, t);
        for (const old of before)
          assert.deepEqual(
            after.find((row) => row.id === old.id),
            old,
          );
        for (const [name] of serviceCatalog)
          assert.ok(
            after.some((row) => row.name === name),
            name,
          );
        const unchanged = await q('SELECT * FROM dbo.DichVu ORDER BY Id', {}, t);
        assert.equal((await applyServiceCatalog(t)).alreadyApplied, true);
        assert.deepEqual(await q('SELECT * FROM dbo.DichVu ORDER BY Id', {}, t), unchanged);
      });
    } finally {
      await close();
    }
  },
);
