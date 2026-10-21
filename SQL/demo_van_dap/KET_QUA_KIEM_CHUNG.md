# Kết quả kiểm chứng bộ demo vấn đáp

Thực hiện ngày **21/10/2026**, SQL Server `MSI\SQLEXPRESS`, Windows Authentication. Đây là kết quả chạy trực tiếp bằng `sqlcmd`, không phải kết quả suy đoán từ mã nguồn.

## Database và dữ liệu

- Database ứng dụng `HomeFix_DBMS_Nhom08_TiengViet`: đã đọc metadata; không chạy các demo ghi dữ liệu vào DB này.
- Database luyện tập `HomeFix_VanDap_20261022`: đã tạo thành công bằng các module của dự án.
- Database phục hồi `HomeFix_VanDap_20261022_Restore`: ONLINE, FULL, CHECKDB không báo lỗi.
- File 00 dùng đường dẫn tuyệt đối tới dự án trên máy này. Chuyển máy cần sửa các dòng `:r`.
- Các bài sửa dữ liệu 02/03/04/07/09/10 đều rollback; bài 08 giữ một khóa cấu hình thử để chứng minh phục hồi dữ liệu sau DIFF.

## Kết quả từng bài

| File | Kết quả quan sát | Trạng thái |
|---|---|---|
| 00_TaoCSDL_Demo.sql | Bộ cài tạo database mới và CHECKCONSTRAINTS không báo dòng vi phạm | Đạt |
| 01_KiemTraCSDL.sql | Liệt kê đúng bảng/đối tượng/constraint/index, SELECT dữ liệu mẫu | Đạt |
| 02_RangBuoc_VaLoi.sql | CHECK 547, NOT NULL 515, UNIQUE 2627, FK 547, sai vai trò 51009 | Đạt |
| 03_ThuTuc_GiaoDich.sql | Chuyển hợp lệ có lịch sử/nhật ký; nhảy bước INVALID_TRANSITION; số đơn trước/sau rollback 0/0; khoảng ngày sai bị chặn | Đạt |
| 04_Trigger_Vi.sql | Hai dòng tăng 30.000; rút quá số dư lỗi 547; không còn giao dịch sai; sửa sổ bị LEDGER_IMMUTABLE | Đạt |
| 05_Ham_View_Index.sql | Hoa hồng 30.000; đầu vào âm trả NULL; gọi đủ 5 hàm, 6 view, 2 SP tra cứu; STATISTICS chạy được | Đạt |
| 06_PhanQuyen.sql | KH xem được view; không được đọc mật khẩu; quyền sửa sổ bằng 0; GD không đọc nhật ký và được gọi báo cáo; REVERT thành công | Đạt |
| 07_DuyetVi_DongThoi.sql | Lần đầu tăng 50.000; duyệt lại phiên bản cũ báo VERSION_CONFLICT; số dư được trả về sau rollback | Đạt |
| 08_Backup_Restore.sql | FULL/DIFF/LOG + VERIFYONLY + RESTORE + CHECKDB; đọc từ bản phục hồi được giá trị SAU_DIFF | Đạt |
| 09_Trigger_ThanhToan_DanhGia_ThongBao.sql | Sai tiền, sửa khoản và đánh giá sớm đều bị từ chối; số thông báo đúng số GD hoạt động | Đạt |
| 10_ThuTuc_DoiSoat_HoTro.sql | Đối soát Confirmed, trừ hoa hồng 30.000; hỗ trợ InProgress có lịch sử; rollback cuối | Đạt |

Tất cả file trên có exit code **0 ở lượt xác minh cuối**. Các lỗi nghiệp vụ dự kiến đã được bắt và đối chiếu trong script; nếu điều kiện sai được chấp nhận, script ném `DEMO_FAIL`. Đã bổ sung SET options ở đầu các demo để DML làm việc đúng với filtered index/cột tính toán.

**Phân biệt phạm vi:** file 07 chạy trong một session và chứng minh duyệt lặp/phiên bản cũ, không phải test hai session. Bài hai kết nối thật có trong bộ `SRC/tests/dbms.test.js` đã chạy đạt. Kịch bản 08 không kiểm thử STOPAT. Các view chưa có nghiệp vụ phù hợp trả tập rỗng là bình thường.

## Tệp backup đã tạo, vẫn giữ để demo

Thư mục dịch vụ SQL Server:

```text
C:\Program Files\Microsoft SQL Server\MSSQL17.SQLEXPRESS\MSSQL\Backup
```

Ba tệp cùng chuỗi:

```text
HomeFix_VanDap_20261022_B6B181DACBDA4A16971FE9ABEF7663BF_Full.bak
HomeFix_VanDap_20261022_B6B181DACBDA4A16971FE9ABEF7663BF_Diff.bak
HomeFix_VanDap_20261022_B6B181DACBDA4A16971FE9ABEF7663BF_Log.trn
```

Khóa kiểm tra trong CauHinh: `VanDap_B6B181DACBDA4A16971FE9ABEF7663BF`, giá trị phục hồi: `SAU_DIFF`.

**Chạy lại:** file 00 không cần chạy nếu DB đã có. Với file 08, đổi `@Dich` sang tên DB chưa tồn tại, chẳng hạn `HomeFix_VanDap_20261022_Restore_Lan2`; không xóa bản phục hồi cũ hoặc dùng REPLACE. Các bài 01–07, 09–10 có thể luyện lại trên DB ôn tập.

## Kiểm thử dự án trước khi đồng bộ GitHub

Chạy tại SRC:

```powershell
npm.cmd run sql:check
npm.cmd run format:check
npm.cmd run test:sql-usage
```

Kết quả ngày 21/10: SQL đồng bộ, định dạng đạt, 108 ca API/SQL đạt (36 + 72), 92 lượt giao diện đạt, 17 thao tác nghiệp vụ UI đạt. Các tệp bằng chứng máy tạo nằm trong `SRC/test-results` trên máy và được Git bỏ qua. Không đánh đồng kiểm thử cục bộ này với CI GitHub hoặc kiểm thử dịch vụ AI/email thật.

Đọc [hướng dẫn vấn đáp chi tiết](../ON_TAP_VAN_DAP_CHI_TIET.md) trước khi chạy demo.
