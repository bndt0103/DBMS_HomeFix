import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

export const databaseDir = fileURLToPath(new URL('../database/', import.meta.url));
export const sqlSources = fs
  .readdirSync(databaseDir)
  .filter((name) => /^CSDL_HomeFix_\d{2}_.*\.sql$/.test(name))
  .sort();

export function sqlBatches(source) {
  return source
    .replace(/\r\n/g, '\n')
    .split(/^GO\s*$/im)
    .filter((batch) => batch.trim());
}
