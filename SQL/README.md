# Cơ sở dữ liệu HomeFix

`CSDL_HomeFix.sql` là **bộ cài hoàn chỉnh duy nhất**: tạo database mới, đầy đủ bảng/ràng buộc, index, hàm, View, SP, trigger, quyền và dữ liệu gốc. Mở bằng SSMS, bật **Query → SQLCMD Mode**, sửa `TenCSDL` nếu cần rồi chạy. Bộ cài dừng nếu tên database đã tồn tại.

Các file trong `modules/` là mã nguồn để đọc và bảo trì. Không sửa riêng bộ cài tổng. Sau khi sửa module, chạy trong `SRC`:

```powershell
npm.cmd run sql:build
```

| Module | Nội dung hiện hành |
|---|---|
| `00_schema.sql` | 26 bảng, PK/FK, CHECK, UNIQUE, DEFAULT và ROWVERSION |
| `01_index.sql` | 20 index tường minh, gồm 9 UNIQUE có lọc |
| `02_function.sql` | 7 hàm: 2 scalar, 5 TVF |
| `03_view.sql` | 31 View đọc dữ liệu và báo cáo |
| `04_sp.sql` | 16 SP tài khoản, hồ sơ và tiện ích |
| `05_transaction.sql` | 28 SP nghiệp vụ/giao dịch/báo cáo |
| `06_trigger.sql` | 7 trigger bảo vệ dữ liệu |
| `07_security.sql` | 7 role nghiệp vụ và ngữ cảnh xác thực nội bộ |
| `08_seed.sql` | 7 tài khoản, 5 danh mục/5 dịch vụ, cấu hình/ngân hàng mẫu |
| `09_data_migration.sql` | Nâng các cột/ràng buộc đang sử dụng; chỉ chạy qua db:upgrade |
| `10_backup_recovery.sql` | SP sao lưu dành cho DBA; không tự BACKUP khi cài |

Tổng 45 SP: 43 SP ghi/tiện ích có giao dịch, 1 SP báo cáo chỉ đọc và 1 SP sao lưu. Module 09 không ghép vào bộ cài mới. Database không còn bảng của tính năng đã dừng và không có cột tọa độ; điều phối dùng chuyên môn và khu vực dạng văn bản.

Module `08_seed.sql` đã nằm trong bộ cài tổng; không chạy riêng sau khi cài. `du_lieu_mau.sql` được công cụ `db:demo` dùng để nạp 15 tài khoản, 25 dịch vụ và 10 đơn mẫu; chạy lặp không tạo trùng. File dữ liệu mẫu không phải bộ cài CSDL khác.

Trên máy nhóm trưởng: server `MSI\SQLEXPRESS`, database `HomeFix_DBMS_Clean_20261022`. Xác nhận trước khi thao tác:

```sql
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL;
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech
FROM dbo.vw_ViKyThuatVien WHERE ChenhLech <> 0;
```

Nâng khung dữ liệu hiện hành: sao lưu bằng SSMS/sp_SaoLuuHeThong, dừng ứng dụng rồi chạy `npm.cmd run db:upgrade` trong SRC. Database phiên bản cũ còn bảng ngoài khung 26 bảng phải được sao lưu và cài mới vào tên khác. Không dùng seed để nâng cấp hoặc xóa dữ liệu đang làm việc.

Truy vấn mẫu, bài sao lưu/phục hồi và phân công của bốn thành viên được gom trong `thuc_hanh_nhom`. Thư mục này không được theo dõi Git và có thể cắt ra ngoài; ứng dụng không đọc bất kỳ file nào trong đó. Hướng dẫn cài ứng dụng nằm trong README ở thư mục gốc.
