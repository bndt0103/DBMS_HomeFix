# Rà soát CSDL và kiểm chứng bộ thực hành nhóm 08

Ngày kiểm tra: **23/10/2026**. Máy chủ: **MSI\SQLEXPRESS**. CSDL: **HomeFix_DBMS_Clean_20261022**.

## Kết luận trong phạm vi kiểm tra

Không phát hiện bất nhất cần ALTER thêm cấu trúc/nghiệp vụ trong lượt này. Định nghĩa toàn bộ SP, view, function và trigger đang chạy trùng các module nguồn, bỏ qua cách SQL Server lưu từ khóa CREATE và phần chú thích đầu batch. Không reset seed, không xóa đơn/khách/tệp đang được sử dụng. Bổ sung bộ học tập và tài liệu phân công, giữ giao diện và dữ liệu hiện tại.

Đây là kết quả kiểm tra các điều kiện liệt kê dưới đây; không phải khẳng định đã chứng minh mọi tình huống đồng thời hay mọi lỗi có thể xảy ra.

## Đối chiếu cấu trúc và dữ liệu

| Nội dung | Kết quả |
|---|---|
| Đối tượng | 28 bảng, 34 view, 50 SP, 6 function, 7 trigger |
| Ràng buộc | 28 PK, 57 FK, 47 CHECK, 51 DEFAULT, 13 UNIQUE constraint; UNIQUE lọc được kiểm tra riêng ở index |
| FK/CHECK bị tắt hoặc chưa được xác thực | Không có |
| Trigger/index bị tắt | Không có |
| DBCC CHECKDB, CHECKCONSTRAINTS | Không phát hiện lỗi |
| Liên kết đối tượng | Không có tham chiếu nghiệp vụ thiếu; inserted/deleted là bảng logic hợp lệ của trigger |
| Ví lưu và sổ cái | Tất cả chênh lệch bằng 0 |
| Vật tư/nghiệm thu | Tổng vật tư khớp tổng các chi tiết của bảng kê được tham chiếu |
| Thanh toán | Khớp nghiệm thu đã duyệt hoặc phí hủy BANK, trạng thái đơn tương ứng |
| Hỗ trợ | Khách trên phiếu khớp khách của đơn; phiếu đang xử lý/đã giải quyết có người phụ trách |
| Nâng cấp | Chạy db:upgrade hai lần trên bản sao; dữ liệu nghiệp vụ giữ nguyên |

Thống kê tại thời điểm rà soát: **16 tài khoản, 25 dịch vụ, 13 đơn, 6 nghiệm thu, 5 thanh toán, 5 giao dịch ví**. Số có thể thay đổi khi nhóm thao tác web.

## Chạy thử tài liệu thực hành

Các file được chạy trên bản phục hồi tạm từ backup COPY_ONLY của CSDL đang dùng. Trước/sau mỗi file, bộ kiểm chứng so sánh toàn bộ dòng của 28 bảng theo khóa chính và cấu hình quyền/index; kết thúc không còn transaction, không còn impersonation/context actor. Các bộ đếm IDENTITY/rowversion có thể tiến lên do thử nghiệm, còn dòng dữ liệu được rollback đúng.

| File | Batch đã chạy | Bảng kết quả | Lỗi dự kiến được xác nhận |
|---|---:|---:|---:|
| [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql) | 10 | 24 | 3 |
| [02_DoAnhTuan.sql](02_DoAnhTuan.sql) | 8 | 23 | 0 |
| [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql) | 10 | 36 | 3 |
| [04_LeTanTai.sql](04_LeTanTai.sql) | 10 | 27 | 6 |
| [04b_SaoLuuPhucHoi.sql](04b_SaoLuuPhucHoi.sql) | 2 | 9 | 0 |

Tổng cộng **40 batch, 119 tập kết quả**, kiểm tra **12 lỗi dự kiến**. Lỗi dự kiến có bắt lỗi và đối chiếu mã, không được tính nhầm thành lỗi chạy chương trình.

- Index: cùng truy vấn 50 kết quả; kế hoạch thực tế **Clustered Index Scan → Index Seek**, logical reads **1475 → 2 trang** trong lượt đo. Không dùng FORCESEEK. Đây là bảng tạm 50.000 dòng mô phỏng cùng dạng lọc, không phải phép đo tăng tốc toàn hệ thống.
- Quyền: GRANT đọc được; REVOKE không đọc được; GRANT lại đọc được; DENY bị chặn. Thu hồi EXECUTE của báo cáo cũng chặn lời gọi SP thật. Đều REVERT và rollback về quyền ban đầu.
- Đồng thời: hai kết nối lấy UPDLOCK/HOLDLOCK cùng dòng; kết nối B nhận **1222** khi A giữ khóa, đọc lại thành công sau rollback A. Không ghi dữ liệu trong bài khóa.
- Phục hồi: COPY_ONLY bản gốc; trên bản sao riêng làm FULL thường, DIFF, LOG; khôi phục sang tên khác đúng thứ tự, truy vấn đủ **3 dòng tại 3 mốc**, CHECKDB thành công.
- Bản sao phục hồi và database kiểm thử đã được gỡ ở cuối lượt chạy. Chỉ còn **HomeFix_DBMS_Clean_20261022** và **HomeFix_Final_20261007** trong nhóm HomeFix.

## Những điểm cần ghi đúng khi báo cáo

1. Luồng vật tư hiện tại không có khách duyệt bảng kê; khách ký nghiệm thu cuối cùng. Thủ tục dùng tên `sp_LuuBangKeVatTu`, bảng `BangKeVatTu`/`ChiTietVatTu`.
2. Tạo đơn không tự tạo phiếu hỗ trợ. CSKH tiếp nhận trước khi phản hồi/kết thúc; nhật ký có thời điểm riêng.
3. Hủy trước di chuyển miễn phí; sau di chuyển/chưa sửa là 60.000đ BANK. Đã sửa thì CSKH xử lý. Phí hủy không biến thành doanh thu đơn hoàn thành, không cần nghiệm thu giả; đối soát cộng đầy đủ phí cho thợ.
4. ADMIN trên web không phải SQL sysadmin; role kỹ thuật đăng nhập không phải bộ phận thứ tám. Quyền đối tượng không thay thế lọc theo khách trên API; chưa triển khai Row-Level Security.
5. CSDL gốc đang ở recovery **SIMPLE**. Bài LOG chỉ chuyển **bản thực hành** sang FULL, không đổi bản gốc. COPY_ONLY FULL không dùng làm nền DIFF.
6. Module 00–10 là **11 file**. Hai cấu trúc OTP/vị trí cũ còn để tương thích, không quảng bá thành luồng OTP/bản đồ đang hoạt động.
7. Rubric có TC3 lệch 20% ở bảng tổng hợp và 15% ở tiêu đề mô tả; giữ nguyên rubric tham chiếu, không tự điều chỉnh thang điểm.

## Kiểm tra định dạng bảng Word

Bảng 7 cột được lấy trực tiếp từ cuối rubric. Đã đối chiếu XML: tblPr, tblGrid, hàng tiêu đề, trPr, tcPr, pPr và thiết lập trang đều giữ nguyên. Bốn dòng điền tên/MSSV theo báo cáo gốc. Word đã mở và xuất PDF kiểm tra: **1 trang, đủ 4 thành viên**, không cắt cột/chữ. Ba cột đánh giá/ký tên để nhóm xác nhận.

Việc bàn giao main và tái lập CSDL trên máy khác được hướng dẫn riêng tại [cài đặt thành viên](../CAI_DAT_THANH_VIEN.md). Kết quả trên ghi nhận lượt kiểm tra SQL ngày 23/10/2026.
