import { AsyncLocalStorage } from "node:async_hooks";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "./config.js";

export const sql = (
  await import(config.sqlAuth ? "mssql" : "mssql/msnodesqlv8.js")
).default;
const directory = path.dirname(fileURLToPath(import.meta.url));
const registry = JSON.parse(
  fs.readFileSync(path.join(directory, "db-contract.json"), "utf8"),
);
const context = new AsyncLocalStorage();
let sharedPool;

export function databaseConfig(database = config.database) {
  const base = {
    server: config.server,
    database,
    connectionTimeout: 15000,
    requestTimeout: 30000,
    pool: { min: 0, max: 8, idleTimeoutMillis: 30000 },
    options: { encrypt: false, trustServerCertificate: true, useUTC: true },
  };
  if (config.sqlAuth)
    return { ...base, user: config.dbUser, password: config.dbPassword };
  const quote = (value) => "{" + value.replaceAll("}", "}}") + "}";
  return {
    ...base,
    connectionString: `Driver={ODBC Driver 17 for SQL Server};Server=${quote(config.server)};Database=${quote(database)};Trusted_Connection=Yes;TrustServerCertificate=Yes;`,
  };
}

export function pool() {
  sharedPool ??= new sql.ConnectionPool(databaseConfig())
    .connect()
    .catch((error) => {
      sharedPool = undefined;
      throw error;
    });
  return sharedPool;
}

export async function close() {
  if (sharedPool) await (await sharedPool).close();
  sharedPool = undefined;
}

export function publicValue(value, key = "") {
  if (
    typeof value === "string" &&
    /^-?\d+$/.test(value) &&
    (key === "Id" ||
      key.endsWith("Id") ||
      [
        "SoDon",
        "TongDon",
        "DonHoanThanh",
        "DonHuy",
        "DonDangXuLy",
        "SoDonHoanThanh",
        "SoLanThu",
        "LanSuaDoi",
        "SoThangBaoHanh",
        "Diem",
      ].includes(key))
  )
    return Number(value);
  if (Buffer.isBuffer(value)) return "0x" + value.toString("hex");
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map((item) => publicValue(item));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([column, item]) => [
        column,
        publicValue(item, column),
      ]),
    );
  }
  return value;
}

function inputType(definition) {
  const [name, args] = definition.toUpperCase().split("(");
  const numbers = (args || "")
    .replace(")", "")
    .split(",")
    .map((part) => part.trim());
  if (name === "DECIMAL" || name === "NUMERIC")
    return sql.Decimal(Number(numbers[0]), Number(numbers[1] || 0));
  if (
    name === "VARCHAR" ||
    name === "NVARCHAR" ||
    name === "CHAR" ||
    name === "NCHAR" ||
    name === "BINARY" ||
    name === "VARBINARY"
  ) {
    const constructors = {
      VARCHAR: sql.VarChar,
      NVARCHAR: sql.NVarChar,
      CHAR: sql.Char,
      NCHAR: sql.NChar,
      BINARY: sql.Binary,
      VARBINARY: sql.VarBinary,
    };
    return constructors[name](
      numbers[0] === "MAX" ? sql.MAX : Number(numbers[0] || 1),
    );
  }
  const types = {
    INT: sql.Int,
    BIGINT: sql.BigInt,
    BIT: sql.Bit,
    DATETIME2: sql.DateTime2,
    DATE: sql.Date,
    UNIQUEIDENTIFIER: sql.UniqueIdentifier,
    SYSNAME: sql.NVarChar(128),
  };
  if (!types[name])
    throw new Error("Unsupported SQL parameter type: " + definition);
  return types[name];
}

function inputValue(value, definition) {
  if (value === "" || value === undefined || value === null) return null;
  if (/^(VAR)?BINARY/i.test(definition)) {
    if (Buffer.isBuffer(value)) return value;
    if (!/^0x[0-9a-f]{16}$/i.test(String(value))) {
      const error = new Error(
        "PhienBanDuKien phải là phiên bản 8 byte nhận từ máy chủ.",
      );
      error.status = 400;
      throw error;
    }
    return Buffer.from(value.slice(2), "hex");
  }
  if (/^(INT|BIGINT|DECIMAL|NUMERIC)/i.test(definition)) {
    const number = Number(value);
    if (
      !Number.isFinite(number) ||
      (/^(INT|BIGINT)$/i.test(definition) && !Number.isSafeInteger(number))
    ) {
      const error = new Error("Tham số số không hợp lệ.");
      error.status = 400;
      throw error;
    }
    return number;
  }
  if (definition.toUpperCase() === "BIT")
    return value === true || value === 1 || value === "1";
  if (/^(DATETIME2|DATE)/i.test(definition)) {
    const date = new Date(value);
    if (Number.isNaN(date.valueOf()))
      throw Object.assign(new Error("Ngày không hợp lệ."), { status: 400 });
    return date;
  }
  return typeof value === "object" ? JSON.stringify(value) : String(value);
}

// Actor ID is always supplied by the server, never copied from an HTTP request body.
export async function exec(spName, params = {}, transaction) {
  const definition = registry.procedures[spName];
  if (!definition) throw new Error("Procedure is not registered: " + spName);
  const connection = transaction || context.getStore()?.pool || (await pool());
  const request = new sql.Request(connection);
  for (const parameter of definition) {
    if (parameter.output) continue;
    let value = params[parameter.name];
    if (parameter.name === "NguoiThucHienId" && context.getStore()?.actor)
      value = context.getStore().actor.Id;
    if (value === undefined && parameter.optional) continue;
    if (value === undefined)
      throw Object.assign(new Error("Thiếu tham số " + parameter.name), {
        status: 400,
      });
    request.input(
      parameter.name,
      inputType(parameter.type),
      inputValue(value, parameter.type),
    );
  }
  const result = await request.execute("dbo." + spName);
  return publicValue(result.recordset || []);
}

// Only known views and a small set of operators are accepted. No arbitrary SQL fragments.
export async function queryView(
  viewName,
  conditions = {},
  params = {},
  transaction,
) {
  if (!registry.views.includes(viewName))
    throw new Error("View is not registered: " + viewName);
  const request = new sql.Request(
    transaction || context.getStore()?.pool || (await pool()),
  );
  const clauses = [];
  let index = 0;
  for (const [column, supplied] of Object.entries(conditions)) {
    if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(column))
      throw new Error("Invalid filter column");
    const condition =
      supplied && typeof supplied === "object" && !Array.isArray(supplied)
        ? supplied
        : { eq: supplied };
    for (const [operator, value] of Object.entries(condition)) {
      const operations = {
        eq: "=",
        ne: "<>",
        gte: ">=",
        lte: "<=",
        gt: ">",
        lt: "<",
        contains: "LIKE",
      };
      if (!operations[operator]) throw new Error("Invalid filter operator");
      if (value === null) {
        if (!["eq", "ne"].includes(operator))
          throw new Error("Invalid NULL filter");
        clauses.push(`[${column}] IS ${operator === "ne" ? "NOT " : ""}NULL`);
      } else {
        const name = "filter" + index++;
        request.input(
          name,
          typeof value === "number"
            ? sql.Decimal(18, 7)
            : typeof value === "boolean"
              ? sql.Bit
              : sql.NVarChar(2000),
          operator === "contains"
            ? "%" +
                String(value).replace(
                  /[\[\]%_]/g,
                  (character) => "[" + character + "]",
                ) +
                "%"
            : value,
        );
        clauses.push(`[${column}] ${operations[operator]} @${name}`);
      }
    }
  }
  const limit = Math.min(Math.max(Number(params.limit) || 200, 1), 1000);
  const order = params.order || "Id";
  if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(order))
    throw new Error("Invalid sort column");
  const statement = `SELECT ${params.all === true ? "" : `TOP (${Math.trunc(limit)}) `}v.* FROM dbo.[${viewName}] AS v${clauses.length ? " WHERE " + clauses.join(" AND ") : ""} ORDER BY [${order}] ${params.ascending ? "ASC" : "DESC"};`;
  return publicValue((await request.query(statement)).recordset);
}

export async function first(viewName, conditions, options) {
  return (await queryView(viewName, conditions, { ...options, limit: 1 }))[0];
}

export async function queryFunction(functionName, params = {}) {
  const parameters = registry.functions[functionName];
  if (!parameters)
    throw new Error("Table-valued function is not registered: " + functionName);
  const request = new sql.Request(context.getStore()?.pool || (await pool()));
  const argumentsList = [];
  for (const parameter of parameters) {
    request.input(
      parameter.name,
      inputType(parameter.type),
      inputValue(params[parameter.name], parameter.type),
    );
    argumentsList.push("@" + parameter.name);
  }
  return publicValue(
    (
      await request.query(
        `SELECT f.* FROM dbo.[${functionName}](${argumentsList.join(",")}) AS f;`,
      )
    ).recordset,
  );
}

// Each HTTP request has a dedicated single-connection pool when database impersonation is on.
// Closing it after the response prevents a database user context from leaking to another request.
export async function withDatabaseRole(actor, callback) {
  if (!config.impersonate) return context.run({ actor }, callback);
  const allowed = new Set([
    "KH",
    "KTV",
    "DPV",
    "CSKH",
    "KT",
    "GD",
    "ADMIN",
    "UngDung",
  ]);
  const role = actor?.VaiTro || "UngDung";
  if (!allowed.has(role)) throw new Error("Invalid database role");
  const connection = await new sql.ConnectionPool({
    ...databaseConfig(),
    pool: { min: 1, max: 1, idleTimeoutMillis: 30000 },
  }).connect();
  try {
    if (actor) {
      await connection
        .request()
        .input("key", sql.NVarChar(128), "NguoiDungId")
        .input("value", sql.Int, actor.Id)
        .input("read_only", sql.Bit, true)
        .execute("sys.sp_set_session_context");
    }
    await connection
      .request()
      .query(
        `SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF; EXECUTE AS USER = 'hf_${role}';`,
      );
    return await context.run({ actor, pool: connection }, callback);
  } finally {
    await connection.close();
  }
}
