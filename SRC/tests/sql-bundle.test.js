import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { dbConfig, config } from '../backend/src/config.js';
import { sql } from '../backend/src/db.js';
import { databaseDir, sqlSources, sqlBatches } from '../scripts/sql-sources.js';

const exec = promisify(execFile);
const root = fileURLToPath(new URL('../', import.meta.url));
const sqlDir = path.resolve(root, '../SQL');
const resultsDir = path.join(root, 'test-results/sql-bundle');
fs.mkdirSync(resultsDir, { recursive: true });
const normalize = (text) =>
  text
    .replace(/--[^\n]*/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^CREATE OR ALTER /, 'CREATE ');
const expected = new Map();
for (const file of sqlSources) {
  for (const batch of sqlBatches(fs.readFileSync(path.join(databaseDir, file), 'utf8'))) {
    const match = normalize(batch).match(/^CREATE (PROCEDURE|FUNCTION|VIEW|TRIGGER) dbo\.(\w+)/);
    if (match) expected.set(match[2], normalize(batch));
  }
}

test('SQL bundle: full and modular installers match migrations and survive reinitialization', async (t) => {
  await exec(process.execPath, ['scripts/build-sql.js', '--check'], {
    cwd: root,
    windowsHide: true,
  });
  const master = await new sql.ConnectionPool(dbConfig('master')).connect();
  const snapshots = [];
  const evidence = [];
  try {
    for (const [variant, filename] of [
      ['full', 'CSDL_HomeFix.sql'],
      ['modules', 'CSDL_HomeFix_Modules.sql'],
    ]) {
      await t.test(
        variant + ' installer, definitions, seed, refusal to overwrite, migration replay',
        async () => {
          const database = 'HomeFix_DBMS_SqlBundleTest_' + crypto.randomBytes(6).toString('hex');
          assert.match(database, /^HomeFix_DBMS_SqlBundleTest_[a-f0-9]{12}$/);
          const input = path.join(resultsDir, variant + '.sql');
          const source = fs
            .readFileSync(path.join(sqlDir, filename), 'utf8')
            .replace(/:setvar TenCSDL "[^"]+"/, `:setvar TenCSDL "${database}"`)
            .replace(
              ':setvar ThuMucSQL "."',
              `:setvar ThuMucSQL "${sqlDir.replaceAll('\\', '/')}"`,
            );
          fs.writeFileSync(input, source);
          const args = [
            '-S',
            config.server,
            '-b',
            '-C',
            '-f',
            '65001',
            '-i',
            input,
            ...(config.windows ? ['-E'] : ['-U', process.env.DB_USER]),
          ];
          const options = {
            cwd: sqlDir,
            windowsHide: true,
            maxBuffer: 2 * 1024 * 1024,
            env: { ...process.env, SQLCMDPASSWORD: process.env.DB_PASSWORD || '' },
          };
          let connection;
          try {
            await exec('sqlcmd', args, options);
            await assert.rejects(exec('sqlcmd', args, options), (error) =>
              /DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME/.test(error.stdout + error.stderr),
            );
            connection = await new sql.ConnectionPool(dbConfig(database)).connect();
            const query = async (text) => (await connection.request().query(text)).recordset || [];
            const definitions = await query(
              'SELECT o.name,m.definition FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id',
            );
            assert.equal(definitions.length, expected.size);
            for (const object of definitions)
              assert.equal(normalize(object.definition), expected.get(object.name), object.name);
            const columns =
              await query(`SELECT OBJECT_NAME(c.object_id) tableName,c.name,TYPE_NAME(c.user_type_id) typeName,c.max_length,c.is_nullable
            FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id ORDER BY tableName,c.column_id`);
            snapshots.push(columns);
            const indexNames = sqlSources
              .flatMap((file) =>
                [
                  ...fs
                    .readFileSync(path.join(databaseDir, file), 'utf8')
                    .matchAll(/CREATE (?:UNIQUE )?INDEX\s+(\w+)/gi),
                ].map((match) => match[1]),
              )
              .sort();
            assert.deepEqual(
              (
                await query(
                  "SELECT i.name FROM sys.indexes i JOIN sys.tables t ON t.object_id=i.object_id WHERE t.is_ms_shipped=0 AND i.is_unique_constraint=0 AND (i.name LIKE 'IX[_]%' OR i.name LIKE 'UX[_]%')",
                )
              )
                .map((row) => row.name)
                .sort(),
              indexNames,
            );
            const ledger = await query('SELECT * FROM dbo.vw_ViKyThuatVien WHERE ChenhLech<>0');
            assert.equal(ledger.length, 0);
            assert.ok((await query('SELECT Id FROM dbo.DichVu WHERE DangHoatDong=1')).length > 0);
            const before = await query('SELECT Id,MatKhauBam FROM dbo.NguoiDung ORDER BY Id');
            assert.equal(before.length, 9);
            await query(`INSERT dbo.TepDinhKem(ChuSoHuuId,MucDich,KhoaLuuTru,TenTepGoc,KieuMIME,KichThuoc)
            SELECT TOP 1 Id,'Avatar','bundle-avatar.png',N'avatar.png','image/png',100 FROM dbo.NguoiDung;
            INSERT dbo.TepDinhKem(ChuSoHuuId,MucDich,KhoaLuuTru,TenTepGoc,KieuMIME,KichThuoc)
            SELECT TOP 1 Id,'TechnicianSignature','bundle-signature.png',N'signature.png','image/png',100 FROM dbo.NguoiDung WHERE VaiTro='KTV';`);
            await exec(process.execPath, ['scripts/init-db.js'], {
              cwd: root,
              windowsHide: true,
              env: { ...process.env, DB_NAME: database },
            });
            assert.deepEqual(
              await query('SELECT Id,MatKhauBam FROM dbo.NguoiDung ORDER BY Id'),
              before,
            );
            assert.equal(
              (
                await query(
                  "SELECT COUNT(*) n FROM dbo.TepDinhKem WHERE KhoaLuuTru LIKE 'bundle-%'",
                )
              )[0].n,
              2,
            );
            assert.equal((await query('DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS')).length, 0);
            if (variant === 'modules') {
              const backupInput = path.join(resultsDir, 'backup-recovery.sql');
              fs.writeFileSync(
                backupInput,
                fs
                  .readFileSync(path.join(sqlDir, 'modules/10_backup_recovery.sql'), 'utf8')
                  .replace(/:setvar TenCSDL "[^"]+"/, `:setvar TenCSDL "${database}"`)
                  .replace(':setvar ThucHienPhucHoi "0"', ':setvar ThucHienPhucHoi "1"'),
              );
              const backupArgs = [...args];
              backupArgs[backupArgs.indexOf('-i') + 1] = backupInput;
              const backup = await exec('sqlcmd', backupArgs, options);
              fs.writeFileSync(path.join(resultsDir, 'backup-recovery.log'), backup.stdout);
              const restored = await master
                .request()
                .query(`SELECT state_desc FROM sys.databases WHERE name=N'${database}_Restore'`);
              assert.equal(restored.recordset[0]?.state_desc, 'ONLINE');
              assert.deepEqual(
                await query(
                  `SELECT Id,MatKhauBam FROM [${database}_Restore].dbo.NguoiDung ORDER BY Id`,
                ),
                before,
              );
              assert.equal(
                (
                  await query(
                    `SELECT COUNT(*) n FROM [${database}_Restore].dbo.TepDinhKem WHERE KhoaLuuTru LIKE 'bundle-%'`,
                  )
                )[0].n,
                2,
              );
              evidence.push({
                backupRecovery: 'PASS',
                chain: ['FULL', 'DIFF', 'LOG'],
                restoredState: 'ONLINE',
                checkdb: 'PASS',
              });
            }
            evidence.push({
              variant,
              status: 'PASS',
              objects: definitions.length,
              users: before.length,
              migrationReplay: 'PASS',
            });
          } finally {
            if (connection) await connection.close();
            for (const ownedDatabase of [database + '_Restore', database]) {
              await master.request().query(`IF DB_ID(N'${ownedDatabase}') IS NOT NULL BEGIN
              ALTER DATABASE [${ownedDatabase}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
              DROP DATABASE [${ownedDatabase}]; END`);
            }
            // Remove only backup files created for this invocation's random database.
            {
              const backups = await master.request().input('database', sql.NVarChar, database)
                .query(`
              SELECT m.physical_device_name path FROM msdb.dbo.backupset s
              JOIN msdb.dbo.backupmediafamily m ON m.media_set_id=s.media_set_id WHERE s.database_name=@database`);
              for (const row of backups.recordset) {
                assert.match(
                  path.win32.basename(row.path),
                  new RegExp('^' + database + '_(FULL|DIFF|LOG)_[0-9A-F]{32}\\.(bak|trn)$', 'i'),
                );
                await master
                  .request()
                  .input('file', sql.NVarChar, row.path)
                  .query(
                    'DECLARE @backupFile nvarchar(260)=@file; EXEC master.sys.xp_delete_files @backupFile',
                  );
              }
            }
          }
        },
      );
    }
    assert.deepEqual(snapshots[0], snapshots[1]);
  } finally {
    await master.close();
    fs.writeFileSync(
      path.join(root, 'test-results/sql-bundle.json'),
      JSON.stringify(evidence, null, 2),
    );
  }
});
