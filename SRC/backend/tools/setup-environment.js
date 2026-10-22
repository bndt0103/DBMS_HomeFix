import fs from "node:fs";
import path from "node:path";
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";

const directory = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const target = path.join(directory, ".env");
if (fs.existsSync(target)) {
  console.log(
    "Giữ cấu hình backend/.env hiện có. Kiểm tra DB_NAME trước khi cài database.",
  );
} else {
  const source = fs.readFileSync(path.join(directory, ".env.example"), "utf8");
  fs.writeFileSync(
    target,
    source.replace(
      "replace-with-a-random-secret-at-least-32-characters",
      randomBytes(48).toString("base64url"),
    ),
  );
  console.log(
    "Đã tạo backend/.env với JWT_SECRET ngẫu nhiên. Kiểm tra DB_SERVER và DB_NAME.",
  );
}
