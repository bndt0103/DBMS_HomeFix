import fs from 'node:fs';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import net from 'node:net';

const database = 'HomeFix_DBMS_AutoTest_' + crypto.randomBytes(6).toString('hex');
const listener = net.createServer();
await new Promise((resolve) => listener.listen(0, '127.0.0.1', resolve));
const port = listener.address().port;
await new Promise((resolve) => listener.close(resolve));
const env = {
  ...process.env,
  DB_NAME: database,
  PORT: String(port),
  HOST: '127.0.0.1',
  TEST_BASE_URL: `http://127.0.0.1:${port}/api`,
  JWT_SECRET: crypto.randomBytes(48).toString('base64url'),
};
fs.mkdirSync('test-results', { recursive: true });
let api;
const log = fs.createWriteStream('test-results/full-test.log');
function run(args) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, { env, windowsHide: true });
    child.stdout.on('data', (data) => {
      process.stdout.write(data);
      log.write(data);
    });
    child.stderr.on('data', (data) => {
      process.stderr.write(data);
      log.write(data);
    });
    child.on('error', reject);
    child.on('exit', (code) =>
      code === 0 ? resolve() : reject(new Error(`${args.join(' ')}: exit ${code}`)),
    );
  });
}
try {
  await run(['scripts/init-db.js']);
  api = spawn(process.execPath, ['backend/src/server.js'], { env, windowsHide: true });
  api.stdout.on('data', (data) => log.write(data));
  api.stderr.on('data', (data) => log.write(data));
  let ready = false;
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      ready = (await fetch(env.TEST_BASE_URL + '/health')).ok;
    } catch {}
    if (ready) break;
    if (api.exitCode !== null) throw new Error('Máy chủ kiểm thử đã dừng.');
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  if (!ready) throw new Error('Máy chủ không sẵn sàng sau 15 giây.');
  const tests = fs
    .readdirSync('tests')
    .filter((name) => name.endsWith('.test.js'))
    .map((name) => 'tests/' + name);
  await run(['--test', '--test-concurrency=1', ...tests]);
  if (process.argv.includes('--ui')) {
    await run(['tests/ui-smoke.mjs']);
    await run(['tests/ui-workflow.mjs']);
  }
  console.log('Hoàn tất kiểm thử trên CSDL tách biệt.');
} finally {
  if (api && api.exitCode === null) {
    api.kill();
    await new Promise((resolve) => api.once('exit', resolve));
  }
  log.end();
  // Only the unique database allocated by this invocation is removed.
  process.env.DB_NAME = database;
  const { dbConfig } = await import('../backend/src/config.js');
  const { sql } = await import('../backend/src/db.js');
  const master = await new sql.ConnectionPool(dbConfig('master')).connect();
  try {
    if (!/^HomeFix_DBMS_AutoTest_[a-f0-9]{12}$/.test(database))
      throw new Error('Tên CSDL kiểm thử không hợp lệ.');
    await master.request().query(`IF DB_ID(N'${database}') IS NOT NULL BEGIN
      ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE [${database}];
    END;`);
  } finally {
    await master.close();
  }
}
