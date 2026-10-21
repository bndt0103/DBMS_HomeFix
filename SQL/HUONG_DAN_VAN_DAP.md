# Tra cứu SQL khi trình bày HomeFix

## 1. Mở file nào khi cô hỏi?

| Nội dung | File nên mở | Ví dụ giải thích |
| --- | --- | --- |
| Bảng, PK/FK/CHECK/UNIQUE | [00_schema.sql](modules/00_schema.sql) | `DonHang` liên kết khách hàng/dịch vụ; `ThanhToan` gắn đúng một nghiệm thu |
| Index | [01_index.sql](modules/01_index.sql) | `UX_PhanCong_KyThuatVien`: chỉ một lệnh đang hoạt động cho mỗi thợ; `IX_DonHang_KhachHang`: tìm đơn theo khách |
| Function | [02_function.sql](modules/02_function.sql) | `fn_HoaHong`, `fn_SoDuVi`, `fn_DiemDanhGia`, `fn_HanBaoHanh`, `fn_ThongKeDon` |
| View | [03_view.sql](modules/03_view.sql) | `vw_DonHangTongHop`, `vw_ViKyThuatVien`, `vw_DoanhThuNgay` |
| Stored procedure | [04_sp.sql](modules/04_sp.sql) | `sp_DonHangCuaKhach` tra cứu; `sp_BaoCaoTongHop` gọi hàm thống kê |
| Transaction | [05_transaction.sql](modules/05_transaction.sql) | `sp_TaoDonHang`, `sp_ChuyenTrangThaiDon`, `sp_DoiSoatCOD`, `sp_DuyetYeuCauVi`, `sp_XuLyHoTro` |
| Trigger | [06_trigger.sql](modules/06_trigger.sql) | `trg_Vi_GhiSo` xử lý nhiều dòng; `trg_Vi_BatBien` bảo vệ sổ ví; trigger đơn ghi lịch sử |
| Security | [07_security.sql](modules/07_security.sql) | `HomeFix_KH`, `HomeFix_KTV`, `HomeFix_DPV`, `HomeFix_CSKH`, `HomeFix_KT`, `HomeFix_ADMIN`, `HomeFix_GD` |
| Backup/recovery | [10_backup_recovery.sql](modules/10_backup_recovery.sql) | FULL → DIFF → LOG; VERIFYONLY; phục hồi sang DB mới; CHECKDB |
| Minh họa chỉ đọc | [CSDL_HomeFix_MinhHoa.sql](CSDL_HomeFix_MinhHoa.sql) | Liệt kê đối tượng, xem view và gọi các hàm/thủ tục tra cứu |

`05_transaction.sql` chứa **định nghĩa 5 stored procedure có transaction**, không phải 5 lần thực hiện nghiệp vụ ngay khi mở file. Tổng cộng bộ cài có 7 procedure; không cộng hai lần các procedure trong file transaction.

## 2. Một luồng demo liên kết đủ website và SQL

1. **KH** đặt dịch vụ → `POST /api/orders` → `sp_TaoDonHang`. Dữ liệu không hợp lệ bị chặn; đặt lặp cùng idempotency key không tạo hai đơn.
2. **DPV** lập báo giá sơ bộ → **KH** duyệt → đơn mới được phân công. Chưa duyệt thì chưa giao thợ.
3. **DPV** chọn thợ phù hợp → **KTV** nhận lệnh, di chuyển, đến nơi, xử lý. Trạng thái chuyển theo thứ tự, có lịch sử.
4. **KTV** đề xuất vật tư → **KH** duyệt. Vật tư chưa được duyệt thì chưa nghiệm thu.
5. **KTV** lập phiếu, ảnh và chữ ký của mình → **KH** xác nhận, chữ ký khách lưu riêng. Chữ ký KTV không thay cho chữ ký KH.
6. **COD**: KTV xác nhận tiền mặt đã thu. **BANK**: KH gửi chứng từ, KT xác minh đúng tiền rồi mới ghi nhận thanh toán.
7. **KT** đối soát → `sp_DoiSoatCOD` → sổ ví → trigger cập nhật số dư. COD trừ hoa hồng khỏi ví; BANK ghi nhận tiền trả thợ theo nghiệp vụ chuyển khoản.
8. **KH** đánh giá/tạo phiếu hỗ trợ → **CSKH** xử lý qua `sp_XuLyHoTro`; **GD** xem báo cáo dữ liệu thật.

## 3. Các câu hỏi thường gặp

**Vì sao cần transaction?** Một thao tác có thể ghi nhiều bảng. Nếu tạo đơn thành công nhưng ghi lịch sử lỗi, phải rollback cả thao tác để tránh dữ liệu dở dang. Mở `sp_TaoDonHang` và phần kiểm thử rollback trong `SRC/tests/dbms.test.js`.

**Savepoint khác transaction riêng thế nào?** Procedure kiểm tra `@@TRANCOUNT`. Nếu chưa có giao dịch thì tự BEGIN/COMMIT. Nếu backend đã mở giao dịch thì tạo SAVEPOINT; khi lỗi và `XACT_STATE()=1` có thể rollback đến điểm lưu. Khi giao dịch không còn commit được, giao dịch bao ngoài phải rollback.

**Hai người cùng bấm duyệt thì sao?** `ROWVERSION` kiểm tra dữ liệu người dùng đang nhìn có còn mới không; `UPDLOCK/HOLDLOCK`, điều kiện trạng thái, unique index và transaction bảo vệ lúc ghi. Backend còn dùng application lock `HomeFixCommands` để tuần tự hóa các lệnh ghi ở quy mô đồ án. Đây là lựa chọn đơn giản, có giới hạn thông lượng khi mở rộng.

**Trigger có xử lý được nhiều dòng không?** Có: `inserted/deleted` là tập dữ liệu. Trigger sổ ví tổng hợp theo KTV, không giả định mỗi lệnh chỉ có một dòng. Test kiểm tra cập nhật nhiều dòng và rollback khi số dư âm.

**Index có phải lúc nào cũng nhanh hơn?** Index phục vụ mẫu lọc/join cụ thể và tăng chi phí ghi. `01_index.sql` có 20 lệnh index tường minh; số 33 index ngoài PK trong metadata còn bao gồm index do UNIQUE tạo ra. Dùng execution plan và `SRC/scripts/benchmark-index.js` khi cần minh chứng hiệu năng; không suy ra mức tăng tốc chỉ từ việc có index.

**Hàm/view nào được website dùng thật?** Báo cáo gọi `sp_BaoCaoTongHop` → `fn_ThongKeDon`; chọn thợ dùng `fn_DiemDanhGia`; đơn hàng dùng `vw_DonHangTongHop`. Một số hàm/view dùng để minh họa hoặc được view khác gọi. Bảng đối chiếu đầy đủ nằm trong [README](README.md); không trình bày mọi đối tượng là API đều trực tiếp gọi.

**Phân quyền SQL có thay thế phân quyền API không?** Không. API kiểm tra JWT, vai trò, chủ đơn và trạng thái nghiệp vụ. Script SQL có 7 role và 7 user `WITHOUT LOGIN` để demo GRANT/DENY/REVOKE, không phải 7 server login. Báo cáo có `EXECUTE AS USER`; nhiều thao tác khác chạy qua tài khoản kết nối của backend rồi kiểm quyền ở API/SQL.

**Doanh thu, hoa hồng và số dư ví khác nhau thế nào?** Giá trị thanh toán là tiền khách đã trả; hoa hồng đã đối soát là phần đã được KT xác nhận; số dư ví là tổng sổ giao dịch. Hoa hồng không phải lợi nhuận ròng vì dự án chưa hạch toán đủ chi phí vận hành. Không lấy cố định 15% toàn bộ tiền khách trả làm doanh thu hoa hồng.

**Vì sao backup thành công chưa đủ?** VERIFYONLY kiểm tra khả năng đọc bản backup; cần thử RESTORE vào DB mới, kiểm tra dữ liệu và CHECKDB. Chuỗi phục hồi dùng FULL cùng nền của DIFF và các LOG liên tục. NORECOVERY chờ bản tiếp theo; RECOVERY đưa DB online. STOPAT cần log chứa đúng mốc thời gian.

**Làm sao chứng minh API thực sự gọi procedure?** Chạy `npm.cmd run test:sql-usage` trong `SRC`. `test-results/sql-usage.json` ghi số lần chạy 6 procedure bằng Extended Events trong lúc gửi HTTP, không suy ra từ sự tồn tại của procedure.

## 4. Cách chuẩn bị trước khi demo

- Dùng CSDL demo phù hợp và đúng tên trong `.env`; chạy `npm.cmd run db:init`, `npm.cmd run build`, `npm.cmd start` từ `SRC`.
- Mở sẵn các file trong `modules` để tra cứu. Chỉ chạy script minh họa khi cần xem dữ liệu; bộ cài `00_schema` dành cho CSDL mới qua file điều phối.
- Chạy `npm.cmd run sql:check` khi sửa SQL để phát hiện file tổng/chia nhỏ chưa đồng bộ. Sửa nguồn trong `SRC/database`, rồi `npm.cmd run sql:build`.
- Chạy backup/recovery trên CSDL demo riêng; chọn rõ `TenCSDL`. Đặt `ThucHienPhucHoi=1` để tạo bản `_Restore`; nếu bản này đã tồn tại thì script dừng.
- Phân biệt kiểm thử tự động với dịch vụ ngoài: OTP dùng nhà cung cấp giả lập trong test, AI dùng phản hồi dự phòng; gửi email thật và AI thật phụ thuộc cấu hình riêng.

Tham khảo cú pháp bộ điều phối: [Microsoft Learn – SQLCMD commands](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-commands).
