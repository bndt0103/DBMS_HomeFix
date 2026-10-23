# Bảng phân công SQL nhóm 08

Lớp: **261DBMS330284_02**. Đề tài: **HomeFix – Quản lý dịch vụ sửa chữa và bảo trì tại nhà**.

Bản [Word](BangPhanCong_SQL_Nhom08.docx) và [PDF](BangPhanCong_SQL_Nhom08.pdf) giữ 7 cột theo mẫu cuối rubric. Công việc trong Word được tách thành các gạch đầu dòng; chi tiết từng người nằm dưới bảng tóm tắt. Tỉ lệ hoàn thành, điểm và ký tên để nhóm tự xác nhận sau thực hành.

| STT | Họ và tên | MSSV | Công việc phụ trách | Tỉ lệ hoàn thành | Điểm | Ký tên |
|---|---|---|---|---|---|---|
| 1 | Nguyễn Quốc Việt | 24110381 | - Module 00, 01, 08.<br>- Thiết kế, ràng buộc, CRUD danh mục, seed và index.<br>- Demo: V01–V06. | | | |
| 2 | Đỗ Anh Tuấn | 24110369 | - Module 02, 03; báo cáo đọc trong 05.<br>- View, JOIN, tổng hợp, 6 hàm và báo cáo.<br>- Demo: T01–T06. | | | |
| 3 | Bùi Nguyễn Duy Trung | 24110363 | - Module 04, 05; trigger trạng thái trong 06.<br>- SP nghiệp vụ, transaction, savepoint và đồng thời.<br>- Demo: D01–D08. | | | |
| 4 | Lê Tấn Tài | 24110319 | - Module 06, 07, 09, 10; đối soát trong 05.<br>- Trigger, phân quyền, đối soát, migration và backup/restore.<br>- Demo: A01–A08. | | | |

## 1. Nguyễn Quốc Việt – 24110381

**Phạm vi:** Module 00, 01, 08.

**File thực hành:** [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql)

- Thiết kế 28 bảng; xác định PK, FK và quan hệ giữa các bảng (V01).
- Giải thích kiểu dữ liệu, NOT NULL, DEFAULT, cột tính toán và chuẩn hóa (V01).
- Kiểm tra CHECK giá âm, FK sai và UNIQUE trùng số điện thoại (V04a–V04c).
- Thêm, sửa, ngừng dùng danh mục qua SP; rollback dữ liệu thử (V03).
- Phân biệt seed 7 vai trò với bộ dữ liệu minh họa có khách, thợ và đơn (V02).
- Giải thích index thường, UNIQUE lọc và điều kiện phân công còn hiệu lực (V05).
- Tạo/gỡ index trên bảng tạm; so sánh Scan/Seek và logical reads trước/sau (V06).
- Trình bày lợi ích, chi phí ghi và lý do chọn cột khóa/INCLUDE của index (V06).

## 2. Đỗ Anh Tuấn – 24110369

**Phạm vi:** Module 02, 03; báo cáo đọc trong 05.

**File thực hành:** [02_DoAnhTuan.sql](02_DoAnhTuan.sql)

- Giải thích view đơn hàng, dịch vụ và danh mục; dùng INNER JOIN/LEFT JOIN (T01).
- Viết truy vấn GROUP BY, HAVING, COUNT, SUM để thống kê đúng số đơn (T02).
- Giải thích tổng thu, COD/BANK và hoa hồng đã đối soát trong view doanh thu (T02).
- Trình bày hai hàm scalar: hoa hồng và tổng tiền đơn hàng (T03).
- Trình bày bốn TVF: số dư ví, điểm đánh giá, thống kê đơn và hạn bảo hành (T03).
- Đối chiếu đơn giá vật tư, thành tiền, tổng nghiệm thu và chênh lệch ví (T04).
- Gọi SP báo cáo; đọc nhiều tập kết quả và view hiệu suất KTV (T05).
- Tự viết view/hàm ngắn, gọi thử và rollback đối tượng thực hành (T06).

## 3. Bùi Nguyễn Duy Trung – 24110363

**Phạm vi:** Module 04, 05; trigger trạng thái trong 06.

**File thực hành:** [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql)

- Rà soát SP tài khoản, danh mục, cấu hình; giải thích tham số và kiểm tra vai trò (D01).
- Demo tạo đơn, báo giá sơ bộ và khách duyệt; đối chiếu lịch sử đơn (D02).
- Đọc SP phân công, phản hồi KTV và chuyển trạng thái; giải thích thứ tự nghiệp vụ.
- Demo BEGIN/COMMIT/ROLLBACK, SAVEPOINT và XACT_STATE (D02–D03).
- Giải thích TRY/CATCH/THROW; xử lý sai đầu vào và rollback khi lỗi (D01–D04).
- Thử ROWVERSION cũ; giải thích UPDLOCK/HOLDLOCK và cập nhật đồng thời (D04).
- Demo trigger chặn nhảy trạng thái khi UPDATE nhiều dòng (D05).
- Kê khai vật tư có đơn giá, lập nghiệm thu và kiểm tra tổng tiền tại SQL (D06).
- Demo khách gửi hỗ trợ, CSKH tiếp nhận, phản hồi và giải quyết (D07).
- Demo hủy sau di chuyển có phí 60.000đ; phân biệt hủy miễn phí và yêu cầu CSKH (D08).

## 4. Lê Tấn Tài – 24110319

**Phạm vi:** Module 06, 07, 09, 10; đối soát trong 05.

**File thực hành:** [04_LeTanTai.sql](04_LeTanTai.sql) và [04b_SaoLuuPhucHoi.sql](04b_SaoLuuPhucHoi.sql)

- Giải thích 7 trigger; phân biệt AFTER và INSTEAD OF, inserted/deleted (A01).
- Demo sổ cái bất biến; giải thích bảo vệ vật tư, chữ ký và đánh giá (A02, module 06).
- Trình bày 7 role nghiệp vụ, user hf_* và ngữ cảnh đăng nhập nội bộ (module 07).
- Demo GRANT, REVOKE, DENY quyền SELECT; chạy truy vấn trước/sau để so sánh (A03).
- Thu hồi quyền EXECUTE của SP; dùng EXECUTE AS/REVERT và khôi phục quyền (A04).
- Giải thích đối soát COD/BANK, hoa hồng, biến động ví và chặn duyệt lặp (A05).
- Kiểm tra migration giữ dữ liệu, tên bảng/cột mới và UNIQUE lọc nghiệm thu (A06).
- Kiểm tra FK/CHECK, recovery model và ví khớp sổ cái trước sao lưu (A07).
- Demo backup FULL, DIFF, LOG; giải thích COPY_ONLY và VERIFYONLY (A08).
- Phục hồi sang tên mới bằng MOVE, NORECOVERY/RECOVERY; đọc dữ liệu và CHECKDB (A08).

Mỗi thành viên còn cần nắm phần chung và câu hỏi chéo trong [HUONG_DAN.md](HUONG_DAN.md). Các mã V/T/D/A đối chiếu trực tiếp với khối SQL trong file thực hành.
