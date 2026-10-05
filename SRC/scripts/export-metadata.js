import fs from 'node:fs';
import { q, close } from '../backend/src/db.js';

const tables = await q(`
  SELECT t.name AS tableName,c.column_id AS ordinal,c.name AS columnName,
    ty.name AS dataType,c.max_length AS maxLength,c.precision,c.scale,
    c.is_nullable AS nullable,c.is_identity AS identityColumn,c.is_computed AS computed,
    dc.definition AS defaultValue,cc.definition AS computedDefinition
  FROM sys.tables t JOIN sys.columns c ON c.object_id=t.object_id
  JOIN sys.types ty ON ty.user_type_id=c.user_type_id
  LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id
  LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
  WHERE t.is_ms_shipped=0 ORDER BY t.name,c.column_id
`);
const foreignKeys = await q(`
  SELECT f.name,OBJECT_NAME(f.parent_object_id) AS sourceTable,
    COL_NAME(f.parent_object_id,c.parent_column_id) AS sourceColumn,
    OBJECT_NAME(f.referenced_object_id) AS targetTable,
    COL_NAME(f.referenced_object_id,c.referenced_column_id) AS targetColumn
  FROM sys.foreign_keys f JOIN sys.foreign_key_columns c ON c.constraint_object_id=f.object_id
  ORDER BY sourceTable,sourceColumn
`);
const constraints = await q(`
  SELECT OBJECT_NAME(parent_object_id) AS tableName,name,type_desc,definition
  FROM sys.check_constraints
  UNION ALL SELECT OBJECT_NAME(parent_object_id),name,type_desc,NULL FROM sys.key_constraints
`);
const indexes = await q(`
  SELECT t.name AS tableName,i.name,i.is_unique AS isUnique,i.is_primary_key AS isPrimaryKey,
    i.filter_definition AS filterDefinition,c.name AS columnName,ic.key_ordinal AS ordinal,
    ic.is_included_column AS included
  FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id
  JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
  WHERE t.is_ms_shipped=0 AND i.name IS NOT NULL ORDER BY t.name,i.name,ic.index_column_id
`);
const modules = await q(`
  SELECT o.name,o.type_desc,m.definition FROM sys.objects o
  JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.type,o.name
`);
fs.mkdirSync('../DOC/evidence', { recursive: true });
fs.writeFileSync(
  '../DOC/evidence/schema.json',
  JSON.stringify({ tables, foreignKeys, constraints, indexes, modules }, null, 2),
);
await close();
console.log('Đã xuất từ điển dữ liệu và đối tượng SQL từ CSDL thực tế.');
