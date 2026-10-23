import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);
const folder = path.join(root, "SQL", "modules");
const moduleNames = [
  "00_schema.sql",
  "01_index.sql",
  "02_function.sql",
  "03_view.sql",
  "04_sp.sql",
  "05_transaction.sql",
  "06_trigger.sql",
  "07_security.sql",
  "08_seed.sql",
  "09_data_migration.sql",
  "10_backup_recovery.sql",
];
const sources = moduleNames.map((name) =>
  fs.readFileSync(path.join(folder, name), "utf8").replace(/^\uFEFF/, ""),
);
const text = sources.join("\nGO\n");
const registry = { procedures: {}, views: [], functions: {} };
const parameterPattern =
  /@(\w+)\s+(NVARCHAR\s*\([^)]*\)|VARCHAR\s*\([^)]*\)|NCHAR\s*\([^)]*\)|CHAR\s*\([^)]*\)|VARBINARY\s*\([^)]*\)|BINARY\s*\([^)]*\)|DECIMAL\s*\([^)]*\)|NUMERIC\s*\([^)]*\)|DATETIME2(?:\s*\(\d+\))?|UNIQUEIDENTIFIER|BIGINT|SYSNAME|DATE|INT|BIT)\s*(=[^,\n]*)?(?:\s+(OUTPUT))?/gi;
function parameters(header) {
  return [...header.matchAll(parameterPattern)].map((match) => ({
    name: match[1],
    type: match[2].replace(/\s/g, "").replace(/DATETIME2\(\d+\)/i, "DATETIME2"),
    optional: Boolean(match[3]),
    output: Boolean(match[4]),
  }));
}
for (const match of text.matchAll(
  /CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\s+(?:dbo\.)?\[?(sp_\w+)\]?([\s\S]*?)\bAS\s*\n/gi,
))
  registry.procedures[match[1]] = parameters(match[2]);
for (const match of text.matchAll(
  /CREATE\s+(?:OR\s+ALTER\s+)?VIEW\s+(?:dbo\.)?\[?(vw_\w+)\]?/gi,
))
  registry.views.push(match[1]);
for (const block of text.split(/^GO\s*$/im)) {
  const match =
    /CREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\s+(?:dbo\.)?\[?(fn_\w+)\]?([\s\S]*?)RETURNS\s+TABLE/i.exec(
      block,
    );
  if (match) registry.functions[match[1]] = parameters(match[2]);
}
const installer =
  `-- HomeFix: cài đặt vào database MỚI, không ghi đè dữ liệu.\n-- Bật Query > SQLCMD Mode trong SSMS và sửa TenCSDL nếu cần.\n:on error exit\n:setvar TenCSDL "HomeFix_DBMS_Nhom08"\nUSE master;\nGO\nIF DB_ID(N'$(TenCSDL)') IS NOT NULL\n    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;\nCREATE DATABASE [$(TenCSDL)];\nGO\nUSE [$(TenCSDL)];\nGO\n` +
  sources
    .map((source, index) => ({ source, name: moduleNames[index] }))
    .filter(({ name }) => name !== "09_data_migration.sql")
    .map(({ source, name }) => `\n-- MODULE: ${name}\n${source}\n`)
    .join("\nGO\n");
fs.writeFileSync(
  path.join(root, "SQL", "CSDL_HomeFix.sql"),
  installer.trimEnd() + "\n",
);
fs.writeFileSync(
  path.join(root, "SQL", "seed_data.sql"),
  sources[moduleNames.indexOf("08_seed.sql")],
);
fs.writeFileSync(
  path.join(root, "SRC", "backend", "src", "db-contract.json"),
  JSON.stringify(registry, null, 2) + "\n",
);
console.log(
  `Database contract: ${Object.keys(registry.procedures).length} procedures, ${registry.views.length} views, ${Object.keys(registry.functions).length} TVFs.`,
);
