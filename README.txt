HOMEFIX — ĐỒ ÁN HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU DBMS330284
Nhóm 08

Hướng dẫn đầy đủ: README.md
Báo cáo Word/PDF: DOC
Bài thuyết trình: SLIDES
SQL tái tạo toàn bộ CSDL: SQL/00_TaoLaiToanBoCSDL.sql
Mã web và API: SRC

Cài lần đầu: CAI_DAT.bat
Chạy chương trình: CHAY_HOMEFIX_DBMS.bat
Tài khoản mẫu và phạm vi kiểm thử được ghi trong README.md.

## Bản CSDL tiếng Việt

Toàn bộ tên bảng, cột và tham số nghiệp vụ dùng tiếng Việt không dấu theo PascalCase, ví dụ `NgayTao`, `NguoiThucHienId`, `TrangThai`. Xem `DOC/QUY_UOC_TEN_SQL.md` để tra tên cũ–mới và quy tắc trình bày.

Nếu đã cài bản trước, sửa `DB_NAME=HomeFix_DBMS_Nhom08_TiengViet` trong `SRC/backend/.env`, rồi chạy lại các bước khởi tạo và build. Giữ nguyên khóa JWT và cấu hình kết nối riêng. Không chạy script mới trên lược đồ tiếng Anh cũ; bản này tạo CSDL mới và không tự di chuyển dữ liệu cũ.

Đối chiếu lược đồ xác nhận 30 bảng, 315 cột, 64 khóa ngoại và 95 ràng buộc CHECK/PRIMARY KEY/UNIQUE giữ nguyên cấu trúc ngoài việc đổi tên. Bằng chứng: `DOC/evidence/vietnamese-schema-check.json`.
