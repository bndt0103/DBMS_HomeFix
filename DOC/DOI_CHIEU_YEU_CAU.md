# Đối chiếu hướng dẫn đồ án DBMS330284

| Yêu cầu | Bản thực hiện | Minh chứng |
|---|---|---|
| ERD, lược đồ quan hệ, ≥8 bảng | 30 bảng, mô tả khóa và thiết kế chuẩn hóa; phân biệt snapshot và giá trị tổng hợp | Báo cáo Chương 2; evidence/schema.json |
| ≥5 CHECK/UNIQUE/DEFAULT | Số dư, số lượng, tiền, tỷ lệ, trạng thái, khóa chứng từ và mặc định thời gian | database/001_schema.sql và các mở rộng |
| ≥5 trigger | 7 trigger nghiệp vụ | 002_procedures_triggers.sql, 005_bank_payments.sql, 011_indexes_integrity.sql |
| ≥5 view | 6 view | 010_functions_views.sql |
| ≥5 index, có index ngoài PK | 33 index ngoài PK; lý do chọn và phép đo có cùng kết quả | 011_indexes_integrity.sql; evidence/index-benchmark.json |
| ≥5 procedure | 7 thủ tục, 5 nghiệp vụ ghi có giao dịch | 012_transactions.sql; API orders/finance/support |
| ≥5 function | 5 hàm, gồm scalar và inline TVF | 010_functions_views.sql |
| TRY…CATCH | Các thủ tục giao dịch xử lý XACT_STATE và savepoint | 012_transactions.sql |
| 5 transaction | Tạo đơn, chuyển trạng thái, đối soát, duyệt ví, xử lý hỗ trợ | tests/dbms.test.js; kiểm thử API |
| Đồng thời hoặc khôi phục sự cố | Hai kết nối cùng duyệt: một thành công, một bị từ chối, một bút toán; lỗi lịch sử rollback đơn | evidence/dbms.json |
| ≥4 role/login | 7 database role và 7 user WITHOUT LOGIN | 013_security.sql |
| GRANT/REVOKE/DENY | Cấp view/thủ tục, thu hồi đọc nhật ký, cấm sửa/xóa sổ và đọc mật khẩu | 013_security.sql; kiểm thử quyền |
| Kết nối SQL cấu hình được | Windows/SQL Authentication, .env | backend/.env.example |
| Đăng nhập và phân quyền | 7 vai trò API; báo cáo dùng EXECUTE AS user SQL tương ứng | backend/src/auth.js, admin.js |
| CRUD, tìm kiếm, thống kê | Quản lý đối tượng; hủy/ngừng hoạt động với dữ liệu cần giữ lịch sử | 26 trang đã kiểm tra; Chương 5 |
| Gọi SP/function từ ứng dụng | 5 nghiệp vụ ghi gọi thủ tục; báo cáo SP/TVF; điểm KTV qua hàm | backend/src/orders.js, finance.js, support.js, admin.js |
| Báo cáo theo định dạng | Word, Times New Roman 13, giãn dòng 1,5; đủ 6 chương, danh mục, tham khảo và phụ lục | DOC/*.docx, *.pdf |
| Trình chiếu ≤15 trang | 12 slide | SLIDES/*.pptx |
| Backup hoặc SQL tái tạo | SQL gồm cấu trúc/quyền/dữ liệu mẫu, đã chạy trên CSDL mới | SQL/00_TaoLaiToanBoCSDL.sql; evidence/recreate-sql.log |
| Source và hướng dẫn | Bản web sạch, README, script cài/chạy, ZIP | SRC; README.md |

## Nội dung nhóm cần xác nhận trước khi nộp

Phân công thực tế từng thành viên. Bảng trong báo cáo là phương án đề xuất, không khẳng định công việc đã được phân chia như vậy. Lịch sử Git cần phản ánh thay đổi thực tế; việc nộp qua kênh của giảng viên và phần trình bày trực tiếp do nhóm thực hiện.
