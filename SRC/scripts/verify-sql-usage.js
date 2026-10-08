import assert from 'node:assert/strict';
import fs from 'node:fs';
import { q, one, close } from '../backend/src/db.js';
import { config } from '../backend/src/config.js';

const required = [
  'sp_TaoDonHang',
  'sp_ChuyenTrangThaiDon',
  'sp_DoiSoatCOD',
  'sp_DuyetYeuCauVi',
  'sp_XuLyHoTro',
  'sp_BaoCaoTongHop',
];

assert.match(config.database, /^HomeFix_DBMS_AutoTest_[a-f0-9]{12}$/);
const session = 'HomeFix_SQLUsage_' + config.database.slice(-12);
const mode = process.argv[2];
assert.ok(['start', 'verify', 'stop'].includes(mode));

async function removeSession() {
  await q(`
    IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = '${session}')
        DROP EVENT SESSION [${session}] ON SERVER;
  `);
}

try {
  if (mode === 'start') {
    const { databaseId } = await one('SELECT DB_ID() AS databaseId');
    assert.ok(Number.isInteger(databaseId) && databaseId > 4);
    try {
      await q(`
        CREATE EVENT SESSION [${session}] ON SERVER
        ADD EVENT sqlserver.module_end (
          SET collect_statement = (0)
          WHERE ([source_database_id] = (${databaseId}))
        )
        ADD TARGET package0.ring_buffer (SET max_memory = (1024))
        WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, STARTUP_STATE = OFF);
        ALTER EVENT SESSION [${session}] ON SERVER STATE = START;
      `);
    } catch (error) {
      await removeSession();
      throw error;
    }
  } else if (mode === 'stop') {
    await removeSession();
  } else {
    await verify();
  }
} finally {
  await close();
}

async function verify() {
  const procedures = await q(`
    DECLARE @Events XML;
    SELECT @Events = CONVERT(XML, t.target_data)
    FROM sys.dm_xe_sessions AS s
    INNER JOIN sys.dm_xe_session_targets AS t ON t.event_session_address = s.address
    WHERE s.name = '${session}' AND t.target_name = 'ring_buffer';

    IF @Events IS NULL
        THROW 51999, 'SQL_USAGE_SESSION_NOT_FOUND', 1;
    IF @Events.value('(/RingBufferTarget/@truncated)[1]', 'int') = 1
       OR @Events.value('(/RingBufferTarget/@droppedCount)[1]', 'int') > 0
        THROW 51999, 'SQL_USAGE_EVENTS_INCOMPLETE', 1;

    SELECT p.name AS procedureName, COUNT(*) AS executionCount
    FROM @Events.nodes('/RingBufferTarget/event[@name="module_end"]') AS x(e)
    INNER JOIN sys.procedures AS p
      ON p.object_id = x.e.value('(data[@name="object_id"]/value)[1]', 'int')
    WHERE p.is_ms_shipped = 0
    GROUP BY p.name
    ORDER BY p.name;
  `);
  for (const name of required) {
    const row = procedures.find((item) => item.procedureName === name);
    assert.ok(Number(row?.executionCount) > 0, `${name}: chưa ghi nhận thực thi trong SQL Server`);
  }
  fs.mkdirSync('test-results', { recursive: true });
  fs.writeFileSync(
    'test-results/sql-usage.json',
    JSON.stringify(
      {
        database: config.database,
        checkedAt: new Date().toISOString(),
        mechanism: 'Extended Events: sqlserver.module_end',
        workflow: 'tests/api.test.js -> HTTP API -> SQL Server',
        procedures,
      },
      null,
      2,
    ),
  );
  console.table(procedures);
  console.log('SQL usage PASS: 6 thủ tục được SQL Server thực thi qua API.');
}
