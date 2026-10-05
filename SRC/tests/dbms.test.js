import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { q, one, sql, pool, close } from '../backend/src/db.js';
import { config } from '../backend/src/config.js';

test('DBMS: SQL objects, transactions, concurrency and database permissions', async (t) => {
  assert.match(config.database, /^HomeFix_DBMS_.*Test/);
  const results = [];
  const run = async (name, fn) =>
    t.test(name, async () => {
      await fn();
      results.push({ name, status: 'PASS' });
    });
  t.after(async () => {
    fs.mkdirSync('test-results', { recursive: true });
    fs.writeFileSync('test-results/dbms.json', JSON.stringify(results, null, 2));
    await close();
  });
  await run('Minimum object counts required by DBMS330284', async () => {
    const counts = await one(`SELECT
      (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) AS tables,
      (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1) AS triggers,
      (SELECT COUNT(*) FROM sys.views) AS views,
      (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) AS procedures,
      (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF')) AS functions,
      (SELECT COUNT(*) FROM sys.indexes WHERE name IS NOT NULL AND is_primary_key=0 AND OBJECTPROPERTY(object_id,'IsUserTable')=1) AS indexes,
      (SELECT COUNT(*) FROM sys.database_principals WHERE type='R' AND name LIKE 'HomeFix[_]%') AS roles`);
    for (const [key, minimum] of Object.entries({
      tables: 8,
      triggers: 5,
      views: 5,
      procedures: 5,
      functions: 5,
      indexes: 5,
      roles: 4,
    })) {
      assert.ok(counts[key] >= minimum, key + ': ' + counts[key]);
    }
    fs.writeFileSync('test-results/object-counts.json', JSON.stringify(counts, null, 2));
  });
  await run('Functions and views calculate actual ledger and commission', async () => {
    assert.equal(Number((await one('SELECT dbo.fn_HoaHong(300000,15) SoTien')).amount), 45000);
    assert.equal((await one('SELECT dbo.fn_HoaHong(-1,15) SoTien')).amount, null);
    assert.equal((await q('SELECT * FROM dbo.vw_ViKyThuatVien WHERE ChenhLech<>0')).length, 0);
    assert.ok((await q('SELECT * FROM dbo.vw_DichVuCongKhai')).length > 0);
  });
  await run(
    'SQL roles allow reports and deny credentials and foreign business operations',
    async () => {
      const r = new sql.Request(await pool());
      const result = await r.query(`
      EXECUTE AS USER='hf_GD';
      SELECT HAS_PERMS_BY_NAME('dbo.vw_DoanhThuNgay','OBJECT','SELECT') AS reportAllowed,
        HAS_PERMS_BY_NAME('dbo.NguoiDung','OBJECT','SELECT','MatKhauBam','COLUMN') AS passwordAllowed,
        HAS_PERMS_BY_NAME('dbo.sp_DuyetYeuCauVi','OBJECT','EXECUTE') AS walletAllowed;
      REVERT;
    `);
      assert.deepEqual(result.recordset[0], {
        reportAllowed: 1,
        passwordAllowed: 0,
        walletAllowed: 0,
      });
      await assert.rejects(
        q(
          `EXECUTE AS USER='hf_KH'; BEGIN TRY SELECT * FROM dbo.NhatKy; REVERT; END TRY BEGIN CATCH REVERT; THROW; END CATCH;`,
        ),
        /permission|denied/i,
      );
      assert.equal((await one('SELECT USER_NAME() AS Ten')).name, 'dbo');
    },
  );
  await run(
    'Standalone SQL transaction rolls back all writes after a history failure',
    async () => {
      const actor = await one("SELECT TOP 1 Id FROM dbo.NguoiDung WHERE VaiTro='KH'");
      const service = await one('SELECT TOP 1 Id FROM dbo.DichVu WHERE DangHoatDong=1');
      const before = Number((await one('SELECT COUNT(*) n FROM dbo.DonHang')).n);
      await q(
        `CREATE OR ALTER TRIGGER dbo.trg_Test_HistoryFailure ON dbo.LichSuDonHang AFTER INSERT AS THROW 51999,'INJECTED_HISTORY_FAILURE',1;`,
      );
      try {
        await assert.rejects(
          q(
            "EXEC dbo.sp_TaoDonHang @KhachHangId=@cid,@DichVuId=@sid,@DiaChi=N'10 Đường kiểm thử, TP.HCM',@MoTa=N'Kiểm thử rollback'",
            { cid: actor.id, sid: service.id },
          ),
          /INJECTED_HISTORY_FAILURE/,
        );
        assert.equal(Number((await one('SELECT COUNT(*) n FROM dbo.DonHang')).n), before);
      } finally {
        await q('DROP TRIGGER dbo.trg_Test_HistoryFailure;');
      }
    },
  );
  await run(
    'Multirow ledger trigger accumulates all rows and rejects negative balance atomically',
    async () => {
      const technician = await one('SELECT TOP 1 Id,SoDu FROM dbo.KyThuatVien ORDER BY Id');
      const tx = new sql.Transaction(await pool());
      await tx.begin();
      try {
        await q(
          "INSERT dbo.GiaoDichVi(KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu) VALUES(@Id,'Deposit',10,'DBMSMultirow',1,N'Test'),(@Id,'Deposit',20,'DBMSMultirow',2,N'Test');",
          { id: technician.id },
          tx,
        );
        assert.equal(
          Number(
            (await one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: technician.id }, tx))
              .balance,
          ),
          Number(technician.balance) + 30,
        );
      } finally {
        await tx.rollback();
      }
      await assert.rejects(
        q(
          `INSERT dbo.GiaoDichVi
            (KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu)
           VALUES (@Id,'Withdrawal',@SoTien,'DBMSNegative',1,N'Test rollback');`,
          { id: technician.id, amount: -Number(technician.balance) - 1 },
        ),
        /CHECK|constraint/i,
      );
      assert.equal(
        Number(
          (await one("SELECT COUNT(*) n FROM dbo.GiaoDichVi WHERE LoaiThamChieu='DBMSNegative'")).n,
        ),
        0,
      );
      assert.equal(
        Number(
          (await one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: technician.id }))
            .balance,
        ),
        Number(technician.balance),
      );
    },
  );
  await run('Two direct SQL sessions cannot approve the same wallet request twice', async () => {
    const kt = await one("SELECT TOP 1 Id FROM dbo.NguoiDung WHERE VaiTro='KT'");
    const tech = await one('SELECT TOP 1 Id,SoDu FROM dbo.KyThuatVien ORDER BY Id');
    const w = await one(
      "INSERT dbo.YeuCauVi(KyThuatVienId,Loai,SoTien,GhiChu) OUTPUT inserted.* VALUES(@Id,'Deposit',123,N'Kiểm thử đồng thời SQL trực tiếp')",
      { id: tech.id },
    );
    const args = { id: w.id, actor: kt.id, version: w.version };
    const query =
      "EXEC dbo.sp_DuyetYeuCauVi @YeuCauId=@Id,@NguoiThucHienId=@actor,@QuyetDinh='Approved',@PhienBanDuKien=@PhienBan";
    const outcomes = await Promise.allSettled([q(query, args), q(query, args)]);
    assert.equal(outcomes.filter((x) => x.status === 'fulfilled').length, 1);
    assert.equal(outcomes.filter((x) => x.status === 'rejected').length, 1);
    assert.equal(
      Number(
        (
          await one(
            "SELECT COUNT(*) n FROM dbo.GiaoDichVi WHERE LoaiThamChieu='WalletRequest' AND ThamChieuId=@Id",
            { id: w.id },
          )
        ).n,
      ),
      1,
    );
    assert.equal(
      Number((await one('SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@Id', { id: tech.id })).balance),
      Number(tech.balance) + 123,
    );
  });
});
