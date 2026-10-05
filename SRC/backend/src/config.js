import dotenv from 'dotenv';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
export const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
dotenv.config({ path: path.join(backendDir, '.env'), quiet: true });
export const config = {
  port: Number(process.env.PORT || 3000),
  server: process.env.DB_SERVER || 'localhost',
  database: process.env.DB_NAME || 'HomeFix_DBMS_Nhom08_TiengViet',
  windows: process.env.DB_AUTH !== 'sql',
  secret: process.env.JWT_SECRET,
  uploads: path.join(backendDir, 'uploads'),
  origins: [
    ...new Set(
      (
        process.env.CLIENT_ORIGINS ||
        'http://localhost:5173,http://localhost:3000,https://localhost,http://localhost'
      )
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),
  ],
};
export function dbConfig(database = config.database) {
  const shared = {
    server: config.server,
    database,
    requestTimeout: 20000,
    connectionTimeout: 10000,
    pool: { min: 0, max: 8, idleTimeoutMillis: 30000 },
    options: {
      encrypt: process.env.DB_ENCRYPT === 'true',
      trustServerCertificate: true,
      useUTC: true,
      abortTransactionOnError: true,
    },
  };
  if (config.windows) {
    const escaped = (s) => '{' + s.replaceAll('}', '}}') + '}';
    return {
      ...shared,
      connectionString: `Driver=${escaped(process.env.DB_ODBC_DRIVER || 'ODBC Driver 17 for SQL Server')};Server=${escaped(config.server)};Database=${escaped(database)};Trusted_Connection=Yes;Encrypt=${process.env.DB_ENCRYPT === 'true' ? 'Yes' : 'No'};TrustServerCertificate=Yes;`,
      options: { ...shared.options, trustedConnection: true },
    };
  }
  return { ...shared, user: process.env.DB_USER, password: process.env.DB_PASSWORD };
}
