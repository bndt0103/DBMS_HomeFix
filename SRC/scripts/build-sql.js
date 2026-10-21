import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { databaseDir, sqlSources, sqlBatches } from './sql-sources.js';

const sqlDir = fileURLToPath(new URL('../../SQL/', import.meta.url));
const groups = new Map([
  ['00_schema', []],
  ['01_index', []],
  ['02_function', []],
  ['03_view', []],
  ['04_sp', []],
  ['05_transaction', []],
  ['06_trigger', []],
  ['07_security', []],
  ['08_seed', []],
  ['09_data_migration', []],
]);
const objects = new Map();
const clean = (text) => text.replace(/--[^\n]*/g, '').trim();
const add = (group, source, batch) => {
  if (clean(batch))
    groups
      .get(group)
      .push(`-- Nguồn: SRC/database/${source}\n${batch.replace(/^[\t ]+$/gm, '').trim()}\nGO\n`);
};
for (const file of sqlSources) {
  for (let batch of sqlBatches(fs.readFileSync(path.join(databaseDir, file), 'utf8'))) {
    const definition = clean(batch).match(
      /^CREATE OR ALTER (PROCEDURE|FUNCTION|VIEW|TRIGGER)\s+(dbo\.\w+)/i,
    );
    if (definition) {
      const [, kind, name] = definition;
      const group =
        kind === 'PROCEDURE'
          ? /BEGIN TRANSACTION/i.test(batch)
            ? '05_transaction'
            : '04_sp'
          : { FUNCTION: '02_function', VIEW: '03_view', TRIGGER: '06_trigger' }[kind];
      // Migrations can replace an object; ship only its final definition.
      objects.set(name, { group, file, batch });
      continue;
    }
    if (/^SET ANSI_NULLS ON;\s*SET QUOTED_IDENTIFIER ON;\s*$/i.test(clean(batch))) continue;
    if (file.includes('_15_')) {
      add('07_security', file, batch);
      continue;
    }
    if (file.includes('_09_') && /^(INSERT|DELETE)\b/i.test(clean(batch))) {
      add('09_data_migration', file, batch);
      continue;
    }
    // Lift guarded indexes before plain indexes so no dangling IF remains in schema.
    batch = batch.replace(
      /IF NOT EXISTS\s*\(SELECT 1\s+FROM sys\.indexes\s+WHERE[^;]+?\)\s*(?:--[^\n]*\n\s*)*CREATE (?:UNIQUE )?INDEX\s+[\s\S]*?;/gi,
      (statement) => {
        add('01_index', file, statement);
        return '';
      },
    );
    batch = batch.replace(/CREATE (?:UNIQUE )?INDEX\s+[\s\S]*?;/gi, (statement) => {
      add('01_index', file, statement);
      return '';
    });
    add('00_schema', file, batch);
  }
}
for (const { group, file, batch } of objects.values()) add(group, file, batch);
const seedPath = path.join(databaseDir, 'sample-data.sql');
if (!fs.existsSync(seedPath)) throw new Error('Missing database/sample-data.sql.');
add(
  '08_seed',
  'sample-data.sql',
  fs
    .readFileSync(seedPath, 'utf8')
    .replace(/\r\n/g, '\n')
    .replace(/GO\s*$/, ''),
);

const settings = 'SET ANSI_NULLS ON;\nSET QUOTED_IDENTIFIER ON;\nSET XACT_ABORT ON;\nGO\n';
const header = `-- HomeFix: bộ cài được sinh từ SRC/database bởi npm run sql:build.
-- Không sửa bản sinh; sửa nguồn rồi sinh lại. Chỉ cài vào CSDL mới.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08_Import"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO
`;
const verify = '\nDBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;\nGO\n';
const outputs = new Map();
for (const [name, batches] of groups) {
  outputs.set(
    `modules/${name}.sql`,
    `-- HomeFix / ${name}: sinh bởi npm run sql:build.\n-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.\n${settings}\n${batches.join('\n')}`,
  );
}
outputs.set('CSDL_HomeFix.sql', header + [...outputs.values()].join('\n') + verify);
outputs.set(
  'CSDL_HomeFix_Modules.sql',
  header +
    `
-- sqlcmd: chạy từ thư mục SQL. SSMS: đặt ThuMucSQL thành đường dẫn tuyệt đối tới SQL.
:setvar ThuMucSQL "."
` +
    [...groups.keys()].map((name) => `:r $(ThuMucSQL)/modules/${name}.sql`).join('\n') +
    verify,
);
outputs.set(
  'modules/10_backup_recovery.sql',
  '-- Chạy riêng; không thuộc bộ cài. Xem hướng dẫn trong file.\n' +
    fs
      .readFileSync(path.join(sqlDir, 'CSDL_HomeFix_SaoLuuPhucHoi.sql'), 'utf8')
      .replace(/\r\n/g, '\n'),
);
const check = process.argv.includes('--check');
const stale = [];
for (const [name, source] of outputs) {
  const target = path.join(sqlDir, name);
  if (check) {
    if (!fs.existsSync(target) || fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') !== source)
      stale.push(name);
  } else {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, source);
  }
}
if (stale.length) throw new Error('SQL chưa đồng bộ; chạy npm run sql:build: ' + stale.join(', '));
console.log(
  `SQL ${check ? 'đồng bộ' : 'đã sinh'}: ${groups.size} nhóm cài đặt, ${objects.size} thủ tục/hàm/view/trigger và backup_recovery riêng.`,
);
