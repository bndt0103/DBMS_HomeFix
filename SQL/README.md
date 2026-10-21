# Cơ sở dữ liệu HomeFix

`CSDL_HomeFix.sql` tạo đầy đủ cấu trúc, thủ tục, hàm, view, trigger, phân quyền và dữ liệu mẫu. Chạy bằng SQLCMD Mode trong SSMS hoặc `sqlcmd`. Biến `TenCSDL` mặc định là `HomeFix_DBMS_Nhom08_Import`; script từ chối ghi đè CSDL đã tồn tại.

Các script thành phần nằm trong `SRC/database`, có tiền tố `CSDL_HomeFix` và số thứ tự thực thi. `npm run db:init` áp dụng chúng vào CSDL được cấu hình trong `SRC/backend/.env`.

## Bộ SQL chia theo chức năng

Mở [hướng dẫn vấn đáp](HUONG_DAN_VAN_DAP.md) để tra nhanh đối tượng, luồng nghiệp vụ và câu hỏi thường gặp.

| File | Nội dung |
| --- | --- |
| [00_schema.sql](modules/00_schema.sql) | Bảng, khóa, ràng buộc và các cột nâng cấp |
| [01_index.sql](modules/01_index.sql) | 20 lệnh tạo index tường minh; index của PK/UNIQUE vẫn đi cùng ràng buộc bảng |
| [02_function.sql](modules/02_function.sql) | 5 hàm tính toán/tra cứu |
| [03_view.sql](modules/03_view.sql) | 6 view tổng hợp |
| [04_sp.sql](modules/04_sp.sql) | 2 thủ tục tra cứu/báo cáo |
| [05_transaction.sql](modules/05_transaction.sql) | 5 thủ tục nghiệp vụ có transaction, savepoint và xử lý lỗi |
| [06_trigger.sql](modules/06_trigger.sql) | 8 trigger toàn vẹn, sổ ví, lịch sử và thông báo |
| [07_security.sql](modules/07_security.sql) | 7 role, user minh họa, GRANT/DENY/REVOKE |
| [08_seed.sql](modules/08_seed.sql) | Dữ liệu mẫu đã có trong bộ cài |
| [09_data_migration.sql](modules/09_data_migration.sql) | Đồng bộ thông báo và dọn các đề xuất mẫu cũ |
| [10_backup_recovery.sql](modules/10_backup_recovery.sql) | Chạy riêng: sao lưu FULL/DIFF/LOG và phục hồi sang CSDL mới |

[CSDL_HomeFix_Modules.sql](CSDL_HomeFix_Modules.sql) gọi lần lượt các file 00–09. Từ thư mục `SQL`, chạy:

```powershell
sqlcmd -S "localhost\SQLEXPRESS" -E -C -b -f 65001 -i CSDL_HomeFix_Modules.sql
```

Trong SSMS, bật **Query → SQLCMD Mode**, sửa `TenCSDL` thành tên chưa tồn tại và `ThuMucSQL` thành đường dẫn tuyệt đối đến thư mục `SQL`. Chỉ chọn **một** bộ cài tổng hoặc chia file. Không chạy bộ cài tạo mới lên CSDL đang dùng. Khi nâng cấp CSDL đang dùng, chạy `npm.cmd run db:init` từ `SRC`.

Nguồn chuẩn là `SRC/database/CSDL_HomeFix_*.sql` và `sample-data.sql`. Các file trong `SQL/modules` và bộ cài tổng được sinh đồng thời để tránh lệch phiên bản; mỗi đoạn ghi rõ file nguồn. Từ `SRC`:

```powershell
npm.cmd run sql:build
npm.cmd run sql:check
npm.cmd run test:sql-bundle
```

Kiểm thử bộ SQL dùng `sqlcmd` thật trên CSDL tạm: so sánh định nghĩa đối tượng/chỉ mục, kiểm tra dữ liệu mẫu, chặn cài đè, chạy lại migration khi đã có avatar/chữ ký, và sao lưu/phục hồi thực tế. Máy kiểm thử cần `sqlcmd`, quyền tạo/xóa CSDL và BACKUP/RESTORE. Tệp backup thử nghiệm được xóa theo đúng tên CSDL ngẫu nhiên của lượt chạy; không dọn backup dự án.

## Đối chiếu yêu cầu SQL

Theo mục 3 và 4 của hướng dẫn DBMS330284, ứng dụng phải gọi được thủ tục/hàm và dùng view hoặc thủ tục cho truy vấn báo cáo. Hướng dẫn không yêu cầu chuyển mọi câu SQL thành thủ tục.

| Đối tượng | Tối thiểu | HomeFix |
| --- | ---: | ---: |
| Bảng | 8 | 30 |
| Thủ tục | 5 | 7 |
| Hàm | 5 | 5 |
| View | 5 | 6 |
| Trigger | 5 | 8 |
| Index | 5, có ít nhất 1 index ngoài khóa chính | 33 index ngoài khóa chính |
| Nghiệp vụ có transaction | 5 | 5 thủ tục giao dịch |
| Role/Login | 4 | 7 role và 7 user không có login |

Số lượng trên mô tả cấu trúc hiện tại; không thay thế việc đánh giá thiết kế, chuẩn hóa và minh chứng hiệu năng theo rubric.

## Đường gọi từ website đến SQL Server

| Thao tác trên website | Mã backend | Đối tượng SQL |
| --- | --- | --- |
| Khách hàng đặt dịch vụ | `orders.js`, `POST /api/orders` | `sp_TaoDonHang` → `vw_DonHangTongHop` |
| Chuyển tiến độ đơn, duyệt báo giá, nghiệm thu hoặc hủy đơn | `common.js`, hàm `transition` dùng chung | `sp_ChuyenTrangThaiDon` → trigger `trg_DonHang_GhiNhatKy` |
| Kế toán xác nhận đối soát | `finance.js` | `sp_DoiSoatCOD` → ghi sổ ví → trigger `trg_Vi_GhiSo` |
| Kế toán duyệt yêu cầu nạp/rút ví | `finance.js` | `sp_DuyetYeuCauVi` → trigger `trg_Vi_GhiSo` |
| CSKH cập nhật xử lý hỗ trợ | `support.js` | `sp_XuLyHoTro` |
| Xem báo cáo tổng hợp | `admin.js`, `GET /api/reports/summary` | `sp_BaoCaoTongHop` → `fn_ThongKeDon` |
| Điều phối xem kỹ thuật viên | `orders.js` | `CROSS APPLY fn_DiemDanhGia` |

Các file backend nằm trong `SRC/backend/src`. Định nghĩa hàm/view nằm trong `CSDL_HomeFix_12_HamVaView.sql`; năm thủ tục giao dịch nằm trong `CSDL_HomeFix_14_GiaoDich.sql`.

Backend còn có truy vấn trực tiếp vào bảng. `sp_DonHangCuaKhach`, `fn_HanBaoHanh` và các view ngoài `vw_DonHangTongHop` chưa được gọi trực tiếp từ backend. `fn_SoDuVi` được dùng trong `vw_ViKyThuatVien`; `fn_HoaHong` được dùng trong `vw_DoanhThuNgay`. Không nên trình bày các đối tượng này là đã được mọi màn hình sử dụng.

## Transaction và minh họa lỗi

Năm thủ tục `sp_TaoDonHang`, `sp_ChuyenTrangThaiDon`, `sp_DoiSoatCOD`, `sp_DuyetYeuCauVi`, `sp_XuLyHoTro` đều có `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, `TRY...CATCH`. Khi được gọi trong transaction của backend, thủ tục dùng savepoint; `db.js` chịu trách nhiệm commit hoặc rollback giao dịch bao ngoài. Kiểm soát đồng thời sử dụng khóa, `ROWVERSION` và kiểm tra trạng thái nghiệp vụ.

`SRC/tests/dbms.test.js` kiểm tra rollback khi lỗi ghi lịch sử, trigger ví với nhiều dòng và hai phiên SQL cùng duyệt một yêu cầu ví. Các kiểm thử API/UI chạy quy trình đặt đơn, xử lý, thanh toán, đối soát và hỗ trợ.

Trong SSMS, chọn CSDL HomeFix rồi chạy [CSDL_HomeFix_MinhHoa.sql](CSDL_HomeFix_MinhHoa.sql). Script chỉ đọc dữ liệu, liệt kê đối tượng và chạy các hàm/view/thủ tục tra cứu; kết quả đơn hàng, doanh thu hoặc bảo hành có thể rỗng nếu chưa có nghiệp vụ tương ứng.

## Sao lưu và Phục hồi (Backup & Recovery)

Kịch bản sao lưu và phục hồi dữ liệu được xây dựng chi tiết trong [CSDL_HomeFix_SaoLuuPhucHoi.sql](CSDL_HomeFix_SaoLuuPhucHoi.sql):
- **Cấu hình**: Chuyển CSDL sang `RECOVERY FULL` hỗ trợ khôi phục đến từng thời điểm (Point-in-Time).
- **Chiến lược sao lưu**:
  - Full Backup (`.bak`): Sao lưu toàn phần với `CHECKSUM`, tên tệp riêng cho từng lần chạy; không bắt buộc nén để tương thích SQL Server Express.
  - Differential Backup (`.bak`): Sao lưu vi sai các thay đổi sau bản Full.
  - Transaction Log Backup (`.trn`): Sao lưu nhật ký giao dịch định kỳ.
- **Kiểm tra tính toàn vẹn**: `RESTORE VERIFYONLY ... WITH CHECKSUM`; sau khi phục hồi thực tế chạy `DBCC CHECKDB`.
- **Phục hồi thực hành**: Đặt `ThucHienPhucHoi=1` để khôi phục FULL → DIFF → LOG vào CSDL mới có hậu tố `_Restore`, với `MOVE`, `NORECOVERY` và `RECOVERY`. Script từ chối ghi đè CSDL đích có sẵn. `STOPAT` là ví dụ bổ sung để giải thích phục hồi theo thời điểm.
- **Thủ tục tự động**: `sp_SaoLuuHeThong` hỗ trợ sao lưu qua tham số `@LoaiSaoLuu ('FULL', 'DIFF', 'LOG')`.

Chọn `TenCSDL` chính xác trong file trước khi chạy; không tự dò rồi đổi sang một CSDL khác. Thủ tục sao lưu được cài riêng nên không nằm trong 7 thủ tục của bộ cài nghiệp vụ. Script thay recovery model của CSDL nguồn thành FULL; thư mục backup nằm trên **máy SQL Server** và cần quyền ghi của dịch vụ SQL Server.

Chạy từ `SRC` để kiểm tra ứng dụng và ghi nhận thực thi thủ tục:

```powershell
npm.cmd run test:sql-usage
```

Lệnh tạo CSDL kiểm thử riêng, ghi sự kiện `sqlserver.module_end` bằng Extended Events trong lúc chạy `tests/api.test.js`, lưu `test-results/sql-usage.json`, sau đó chạy các kiểm thử SQL còn lại và Edge. Sáu thủ tục trong bảng đường gọi phải có số lần thực thi lớn hơn 0. Bài kiểm thử API không gọi trực tiếp sáu thủ tục này: chúng được thực thi qua backend khi gửi yêu cầu HTTP. Phiên ghi sự kiện chỉ lọc CSDL kiểm thử, không thu thập nội dung câu lệnh, và được xóa cùng CSDL tạm khi kết thúc. Tài khoản chạy cần quyền tạo/xóa CSDL kiểm thử, quản lý phiên Extended Events và đọc dữ liệu phiên.

Việc đọc sự kiện sử dụng [ring buffer của Extended Events](https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/targets-for-extended-events-in-sql-server). Cách kiểm tra này ghi nhận sự kiện trong lượt chạy; bộ đếm `sys.dm_exec_procedure_stats` chỉ phản ánh thủ tục còn trong cache theo [tài liệu Microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-procedure-stats-transact-sql).

Kết quả khác được lưu trong `SRC/test-results/full-test.log`, `object-counts.json`, `dbms.json`, `ui-results.json` và `screenshots/`.
