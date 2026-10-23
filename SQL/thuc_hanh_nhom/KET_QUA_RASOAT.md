# Rà soát CSDL và kiểm chứng bộ thực hành nhóm 08

Ngày kiểm tra: **23/10/2026**. Máy chủ: **MSI\SQLEXPRESS**. CSDL: **HomeFix_DBMS_Clean_20261022**.

## Kết luận trong phạm vi kiểm tra

Đã sửa thiếu quyền đọc thông tin ngân hàng/yêu cầu thanh toán của DPV và CSKH, thêm hàm lọc thợ dùng chung cho danh sách và thủ tục phân công, cho phép điều chỉnh báo giá trước phân công với bước khách duyệt lại, bổ sung tên người thực hiện và ghi nhận thao tác quản trị vào nhật ký. Không reset seed hay xóa dữ liệu hiện có.

Định nghĩa toàn bộ SP, view, function và trigger trong CSDL đang chạy trùng các module nguồn. Đã áp dụng nâng cấp sau sao lưu COPY_ONLY/CHECKSUM và VERIFYONLY; so sánh trước/sau giữ nguyên từng dòng của 28 bảng.

Đây là kết quả kiểm tra các điều kiện liệt kê dưới đây; không phải khẳng định đã chứng minh mọi tình huống đồng thời hay mọi lỗi có thể xảy ra.

## Đối chiếu cấu trúc và dữ liệu

| Nội dung | Kết quả |
|---|---|
| Đối tượng | 28 bảng, 34 view, 50 SP, 7 function (2 scalar, 5 TVF), 7 trigger |
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

Thống kê tại thời điểm rà soát: **16 tài khoản, 25 dịch vụ, 14 đơn, 7 nghiệm thu, 6 thanh toán, 5 giao dịch ví**. Số có thể thay đổi khi nhóm thao tác web.

## Chạy thử tài liệu thực hành

Các file được chạy trên bản phục hồi tạm từ backup COPY_ONLY của CSDL đang dùng. Trước/sau mỗi file, bộ kiểm chứng so sánh toàn bộ dòng của 28 bảng theo khóa chính và cấu hình quyền/index; kết thúc không còn transaction, không còn impersonation/context actor. Các bộ đếm IDENTITY/rowversion có thể tiến lên do thử nghiệm, còn dòng dữ liệu được rollback đúng.

| File | Batch đã chạy | Bảng kết quả | Lỗi dự kiến được xác nhận |
|---|---:|---:|---:|
| [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql) | 10 | 24 | 3 |
| [02_DoAnhTuan.sql](02_DoAnhTuan.sql) | 8 | 24 | 0 |
| [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql) | 10 | 35 | 3 |
| [04_LeTanTai.sql](04_LeTanTai.sql) | 10 | 27 | 6 |
| [04b_SaoLuuPhucHoi.sql](04b_SaoLuuPhucHoi.sql) | 2 | 9 | 0 |

Tổng cộng **40 batch, 119 tập kết quả**, kiểm tra **12 lỗi dự kiến**. Lỗi dự kiến có bắt lỗi và đối chiếu mã, không được tính nhầm thành lỗi chạy chương trình.

- Index: cùng truy vấn 50 kết quả; kế hoạch thực tế **Clustered Index Scan → Index Seek**, logical reads **1475 → 2 trang** trong lượt đo. Không dùng FORCESEEK. Đây là bảng tạm 50.000 dòng mô phỏng cùng dạng lọc, không phải phép đo tăng tốc toàn hệ thống.
- Quyền: GRANT đọc được; REVOKE không đọc được; GRANT lại đọc được; DENY bị chặn. Thu hồi EXECUTE của báo cáo cũng chặn lời gọi SP thật. Đều REVERT và rollback về quyền ban đầu.
- Đồng thời: hai kết nối lấy UPDLOCK/HOLDLOCK cùng dòng; kết nối B nhận **1222** khi A giữ khóa, đọc lại thành công sau rollback A. Không ghi dữ liệu trong bài khóa.
- Phục hồi: COPY_ONLY bản gốc; trên bản sao riêng làm FULL thường, DIFF, LOG; khôi phục sang tên khác đúng thứ tự, truy vấn đủ **3 dòng tại 3 mốc**, CHECKDB thành công.
- Bản sao phục hồi và database kiểm thử đã được gỡ ở cuối lượt chạy. Chỉ còn **HomeFix_DBMS_Clean_20261022** và **HomeFix_Final_20261007** trong nhóm HomeFix.

## Kiểm tra hệ thống sau sửa điều phối và quyền đọc

- `npm.cmd test`: **23/23 ca đạt**, gồm chuỗi COD/BANK, đối soát/ví, vật tư/nghiệm thu, hỗ trợ/hủy đơn, quyền và phiên bản dữ liệu.
- **501 yêu cầu API đọc thành công trên localhost** với đủ 7 vai trò, bao gồm các phần của chi tiết đơn và thanh toán. GD bị chặn xem chi tiết đơn theo thiết kế; KH/KTV vẫn bị giới hạn theo chủ đơn/phân công.
- **102 lượt mở màn hình bằng Chrome**, gồm dashboard, danh sách, báo cáo và toàn bộ đơn các vai trò được xem: không phát hiện lỗi API nghiệp vụ, JavaScript hoặc nhãn sai mã hóa. 11 ảnh đã bị xóa trước đó trả 404 và hiển thị “Không có tệp ảnh”; không phục hồi ảnh hay sửa lịch sử chứng từ để che việc thiếu tệp.
- Thực hiện qua UI: mở hộp điều chỉnh báo giá, sửa phí kiểm tra/tiền công, xác nhận, khách duyệt lại, mở danh sách chỉ gồm thợ đủ điều kiện và phân công thành công. Kiểm tra nhật ký hiển thị `#ID · Họ tên`.
- Test phủ thợ khác khu vực (Quận 1/Quận 10), khác tay nghề, tài khoản khóa, tạm bận, đang giữ đơn khác dù cờ sẵn sàng bị đặt sai, cùng quy tắc TP.HCM/Thủ Đức. Gửi tay mã thợ không phù hợp cũng bị SQL từ chối.
- Bộ cài mới và dữ liệu mẫu đạt: **15 tài khoản / 25 dịch vụ / 10 đơn**, ví khớp sổ; chạy dữ liệu mẫu hai lần không nhân bản; 45 tập kết quả truy vấn mẫu chạy được.
- Chạy nâng cấp hai lần trên bản sao không đổi dữ liệu. Trên bản chính, CHECKDB/CHECKCONSTRAINTS không báo lỗi, FK/CHECK/trigger/index đều hoạt động; ví, vật tư/nghiệm thu, thanh toán và hỗ trợ không có sai lệch trong truy vấn kiểm tra.
- Bài D08 cần đơn `DangDiChuyen` hoặc `DaDenNoi`. Dữ liệu hiện tại không có đơn ở hai trạng thái này, nên truy vấn đã chạy nhánh thông báo chuẩn bị và không hủy đơn. Khi demo, cho KTV bấm **Bắt đầu di chuyển** ở một đơn được giao trước; ca tự động 23/23 đã kiểm tra đầy đủ phí hủy BANK và cộng ví.
- Build Vite, Prettier và kiểm tra khoảng trắng Git đều đạt. Database kiểm thử được xóa sau khi chạy; hai database gốc được giữ lại.

## Những điểm cần ghi đúng khi báo cáo

1. Luồng vật tư hiện tại không có khách duyệt bảng kê; khách ký nghiệm thu cuối cùng. Thủ tục dùng tên `sp_LuuBangKeVatTu`, bảng `BangKeVatTu`/`ChiTietVatTu`.
2. Tạo đơn không tự tạo phiếu hỗ trợ. CSKH tiếp nhận trước khi phản hồi/kết thúc; nhật ký có thời điểm riêng.
3. Hủy trước di chuyển miễn phí; sau di chuyển/chưa sửa là 60.000đ BANK. Đã sửa thì CSKH xử lý. Phí hủy không biến thành doanh thu đơn hoàn thành, không cần nghiệm thu giả; đối soát cộng đầy đủ phí cho thợ.
4. ADMIN trên web không phải SQL sysadmin; role kỹ thuật đăng nhập không phải bộ phận thứ tám. Quyền đối tượng không thay thế lọc theo khách trên API; chưa triển khai Row-Level Security.
5. CSDL gốc đang ở recovery **SIMPLE**. Bài LOG chỉ chuyển **bản thực hành** sang FULL, không đổi bản gốc. COPY_ONLY FULL không dùng làm nền DIFF.
6. Module 00–10 là **11 file**. Hai cấu trúc OTP/vị trí cũ còn để tương thích, không quảng bá thành luồng OTP/bản đồ đang hoạt động.
7. Rubric có TC3 lệch 20% ở bảng tổng hợp và 15% ở tiêu đề mô tả; giữ nguyên rubric tham chiếu, không tự điều chỉnh thang điểm.

## Kiểm tra định dạng bảng Word

Bảng 7 cột được lấy từ cuối rubric, giữ độ rộng, viền, font và định dạng ô. Theo yêu cầu trình bày lại, công việc được tách thành 36 gạch đầu dòng: 8 ý của Việt, 8 ý của Tuấn, 10 ý của Trung và 10 ý của Tài. Bổ sung thụt dòng treo cho gạch đầu dòng, lặp tiêu đề và giữ nguyên phần việc mỗi thành viên khi phân trang. Word/PDF đã kiểm tra: **3 trang, đủ 4 thành viên**, không cắt cột/chữ và không chia đôi phần việc một người. Ba cột đánh giá/ký tên để nhóm xác nhận. Nội dung kiểm thử SQL ở trên không thay đổi.

Việc bàn giao main và tái lập CSDL trên máy khác được hướng dẫn riêng tại [cài đặt thành viên](../CAI_DAT_THANH_VIEN.md). Kết quả trên ghi nhận lượt kiểm tra SQL ngày 23/10/2026.
