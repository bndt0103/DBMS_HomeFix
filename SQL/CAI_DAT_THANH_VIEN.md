# Lấy bản main và dựng CSDL HomeFix trên máy thành viên

Repo: **https://github.com/bndt0103/DBMS_HomeFix**, nhánh **main**. Bản này gồm SQL module mới, backend, frontend, dữ liệu mẫu và bài thực hành của 4 thành viên.

## 1. Lấy mã nguồn

Chưa có repo:

```powershell
git clone --branch main https://github.com/bndt0103/DBMS_HomeFix.git
cd DBMS_HomeFix
```

Đã có repo, lưu hoặc commit công việc riêng trước khi chuyển nhánh:

```powershell
git fetch origin
git switch main
git pull --ff-only origin main
```

Nếu Git báo nhánh local đã phân kỳ hoặc có thay đổi chưa lưu, giữ nguyên công việc riêng và clone ra thư mục khác để chạy bản mới. Không cần xóa database đang dùng để cập nhật code.

## 2. Chuẩn bị máy và cấu hình

Cần Node.js từ 22.12, SQL Server/SQL Server Express đang chạy, SSMS, `sqlcmd` và ODBC Driver 17 for SQL Server khi dùng Windows Authentication. Kiểm tra tên instance SQL Server trên **máy của bạn**, không chép tên máy MSI của thành viên khác.

Trong thư mục repo:

```powershell
cd SRC
npm.cmd ci
node backend/tools/setup-environment.js
```

Mở `SRC/backend/.env` vừa tạo, sửa các dòng sau cho đúng máy:

```dotenv
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HomeFix_DBMS_Clean_20261022
DB_AUTH=windows
DB_IMPERSONATE=true
PORT=3000
```

Giữ JWT_SECRET ngẫu nhiên do công cụ tạo. `.env` là cấu hình riêng trên từng máy, không có trong GitHub. Tài khoản Windows chạy cài đặt cần quyền tạo database và cấp quyền; các bài backup/restore cần DBA. Nếu instance của bạn khác `SQLEXPRESS`, sửa DB_SERVER theo tên thật trong SSMS.

Tên `HomeFix_DBMS_Clean_20261022` được khuyến nghị để trùng với USE trong các bài thực hành. Đây là database riêng trên máy bạn, không phải kết nối đến máy của nhóm trưởng.

## 3. Máy chưa có database này: cài cấu trúc mới và dữ liệu mẫu

Chạy trong `SRC`:

```powershell
npm.cmd run db:init
npm.cmd run db:demo
npm.cmd run build
npm.cmd start
```

Mở **http://localhost:3000**. `db:init` dùng bộ cài `SQL/CSDL_HomeFix.sql` đã được dựng từ các module và tạo 7 tài khoản gốc. `db:demo` bổ sung dữ liệu học tập. Không cần tự chạy `seed_data.sql` sau `db:init`.

Kết quả trên bản cài mới: **15 tài khoản, 5 danh mục, 25 dịch vụ, 10 đơn minh họa** cùng chứng từ và sổ ví liên quan. Có 7 tài khoản vai trò gốc, 5 khách mẫu và 3 KTV mẫu. Mật khẩu các tài khoản mẫu: **123456**.

| Đăng nhập | Vai trò |
|---|---|
| 0900000001 | Khách hàng |
| 0900000002 | Kỹ thuật viên |
| 0900000003 | Điều phối viên |
| 0900000004 | CSKH |
| 0900000005 | Kế toán |
| 0900000006 | Giám đốc |
| 0900000007 | Admin |

Khách bổ sung: `0900001001`–`0900001005`; KTV bổ sung: `0900002001`–`0900002003`. Dữ liệu là giả lập. Không kèm ảnh minh họa vật lý; nếu cần thử tải ảnh/chữ ký/chứng từ trên web, tự chọn tệp mới trong form.

Git lưu mã nguồn và script SQL, **không tự sao chép database đang chạy trên máy nhóm trưởng**. Các đơn/tài khoản phát sinh khi từng thành viên thử web được lưu riêng trên máy đó; số dòng thực tế có thể nhiều hơn bộ mẫu trên.

## 4. Máy đã có database HomeFix của bản refactor

Kiểm tra `.env` trỏ đúng database cần cập nhật. Sao lưu trước theo [sao_luu_mau.sql](sao_luu_mau.sql), dừng ứng dụng rồi chạy trong `SRC`:

```powershell
npm.cmd ci
npm.cmd run db:upgrade
npm.cmd run db:demo
npm.cmd run build
npm.cmd start
```

`db:upgrade` dành cho cấu trúc refactor có bảng `KyThuatVien`, cập nhật module và giữ dữ liệu. `db:demo` chạy lặp không tạo lại bộ đơn đã có; không đưa các đơn đã thao tác về trạng thái ban đầu. Không dùng `db:init` trên database đã tồn tại.

Nếu máy chỉ có database HomeFix đời CNPM hoặc chưa rõ phiên bản, giữ bản đó, chọn một tên database mới bắt đầu `HomeFix_` trong `.env` rồi thực hiện mục 3. Khi dùng tên khác tên khuyến nghị, sửa dòng USE ở các file demo cho đúng tên trước khi chạy.

## 5. Kiểm tra CSDL và mở bài học

Trong SSMS, chọn đúng instance trên máy bạn:

```sql
USE [HomeFix_DBMS_Clean_20261022];
GO
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL;
SELECT COUNT(*) AS SoTaiKhoan FROM dbo.vw_NguoiDung;
SELECT COUNT(*) AS SoDichVu FROM dbo.vw_DichVuCongKhai;
SELECT COUNT(*) AS SoDon FROM dbo.vw_DonHangTongHop;
SELECT Id, HoTen, ChenhLech FROM dbo.vw_ViKyThuatVien WHERE ChenhLech <> 0;
```

Ba số đếm của bản mới là **15 / 25 / 10**; truy vấn cuối rỗng nghĩa là ví khớp sổ cái. Các thành phần SQL: **28 bảng, 34 view, 50 SP, 7 function, 7 trigger**.

- [Hướng dẫn học và demo theo 4 thành viên](thuc_hanh_nhom/HUONG_DAN.md).
- [Bảng phân công Word](thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.docx), [PDF](thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.pdf).
- [Truy vấn tổng hợp](truy_van_mau.sql), [giải thích các module](README.md).

Nếu muốn thay đổi module, sửa `SQL/modules/` rồi chạy `npm.cmd run sql:build`; không sửa riêng bộ cài tổng. Không đẩy `.env`, uploads, node_modules, dist hoặc các file backup/data/log SQL Server lên GitHub.
