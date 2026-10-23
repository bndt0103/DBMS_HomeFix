// GO chỉ phân tách batch khi nằm ngoài chuỗi, tên cột và comment SQL.
export function splitSqlBatches(source) {
  const batches = [];
  let lines = [];
  let commentDepth = 0;
  let quote = null;
  for (const line of source.replace(/^\uFEFF/, "").split(/\r?\n/)) {
    if (!commentDepth && !quote && /^\s*GO\s*(?:--.*)?$/i.test(line)) {
      if (lines.join("\n").trim()) batches.push(lines.join("\n"));
      lines = [];
      continue;
    }
    lines.push(line);
    for (let i = 0; i < line.length; i++) {
      const pair = line.slice(i, i + 2);
      if (commentDepth) {
        if (pair === "/*") {
          commentDepth++;
          i++;
        } else if (pair === "*/") {
          commentDepth--;
          i++;
        }
      } else if (quote) {
        if (line[i] === quote) {
          if (line[i + 1] === quote) i++;
          else quote = null;
        }
      } else if (pair === "--") break;
      else if (pair === "/*") {
        commentDepth++;
        i++;
      } else if (line[i] === "'" || line[i] === '"') quote = line[i];
      else if (line[i] === "[") quote = "]";
    }
  }
  if (commentDepth || quote)
    throw new Error("SQL còn chuỗi hoặc comment chưa đóng.");
  if (lines.join("\n").trim()) batches.push(lines.join("\n"));
  return batches;
}
