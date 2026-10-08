# Quy ước đặt tên và trình bày SQL

Tên bảng, cột và tham số dùng tiếng Việt không dấu theo PascalCase, ví dụ `DonHang`, `NgayTao`, `NguoiThucHienId`. Chú thích dùng tiếng Việt có dấu, ngắn gọn và giải thích mục đích từng phần.

| Tiền tố | Ý nghĩa | Ví dụ |
|---|---|---|
| `PK` / `FK` | Khóa chính / khóa ngoại | `PK_ChongLapYeuCau` |
| `CK` / `DF` | Điều kiện kiểm tra / mặc định | `CK_DonHang_PhuongThucThanhToan` |
| `IX` / `UX` | Chỉ mục / chỉ mục duy nhất | `IX_DonHang_KhachHang` |
| `sp_` | Thủ tục | `sp_TaoDonHang` |
| `fn_` | Hàm | `fn_HoaHong` |
| `vw_` | Khung nhìn | `vw_DonHangTongHop` |
| `trg_` | Trigger | `trg_DonHang_GhiNhatKy` |

Từ khóa SQL viết hoa. Khối `BEGIN…END`, `TRY…CATCH` và giao dịch thụt lề bốn khoảng trắng. Mỗi cột trong lệnh tạo bảng nằm trên một dòng. `GO` phân tách các lô lệnh. Chuỗi tiếng Việt sử dụng tiền tố `N`.

Script theo mô-đun nằm trong `SRC/database/CSDL_HomeFix_*.sql`. Bản tái tạo đầy đủ nằm tại `SQL/CSDL_HomeFix.sql`; cách chạy được mô tả trong [hướng dẫn SQL](../SQL/README.md).

Ứng dụng dùng CSDL mặc định `HomeFix_DBMS_Nhom08_TiengViet`. Tên cột SQL được ánh xạ với thuộc tính JSON tại `SRC/backend/src/sql-names.js`. Metadata của cấu trúc, khóa và đối tượng được lưu trong `DOC/evidence/schema.json`.
