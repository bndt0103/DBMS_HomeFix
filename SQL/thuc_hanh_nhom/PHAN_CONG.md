# Phân công SQL nhóm 08

Đề tài: **HomeFix – Quản lý dịch vụ sửa chữa và bảo trì tại nhà**. Lớp: **261DBMS330284_02**.

Mỗi thành viên thực hiện **đủ 10 nhóm kiến thức**, với ví dụ trên phân hệ khác nhau. Không chia độc quyền một người chỉ làm index hay một người chỉ làm phân quyền. Các nhóm này phủ module **00–10 (11 file)**: nhóm 01 gộp schema và seed.

Đây là phân công thực hành, rà soát và bảo vệ; không dùng bảng này để khẳng định lại tác giả lịch sử commit. Tỉ lệ hoàn thành, điểm và chữ ký để thành viên tự xác nhận sau khi làm.

[Bản Word](BangPhanCong_SQL_Nhom08.docx) · [Bản PDF](BangPhanCong_SQL_Nhom08.pdf)

| STT | Họ và tên | MSSV | Công việc phụ trách | Tỉ lệ hoàn thành | Điểm | Ký tên |
|---|---|---|---|---|---|---|
| 1 | Nguyễn Quốc Việt | 24110381 | - Khách hàng, dịch vụ và đánh giá.<br>- Đủ 10 nhóm: V01–V10; tự thực hành sao lưu/phục hồi file 05. | | | |
| 2 | Đỗ Anh Tuấn | 24110369 | - Đặt đơn, báo giá và điều phối.<br>- Đủ 10 nhóm: T01–T10; tự thực hành sao lưu/phục hồi file 05. | | | |
| 3 | Bùi Nguyễn Duy Trung | 24110363 | - Vật tư, nghiệm thu và bảo hành.<br>- Đủ 10 nhóm: D01–D10; tự thực hành sao lưu/phục hồi file 05. | | | |
| 4 | Lê Tấn Tài | 24110319 | - Thanh toán, đối soát và ví kỹ thuật viên.<br>- Đủ 10 nhóm: A01–A10; tự thực hành sao lưu/phục hồi file 05. | | | |

## Ma trận phân công ngang nhau

| Nhóm / module | Việt | Tuấn | Trung | Tài |
|---|---|---|---|---|
| 01. Thiết kế, ràng buộc và dữ liệu (00, 08) | V01 | T01 | D01 | A01 |
| 02. Index (01) | V02 | T02 | D02 | A02 |
| 03. View (03) | V03 | T03 | D03 | A03 |
| 04. Function (02) | V04 | T04 | D04 | A04 |
| 05. Stored procedure (04, 05) | V05 | T05 | D05 | A05 |
| 06. Trigger (06) | V06 | T06 | D06 | A06 |
| 07. Transaction và đồng thời (05) | V07 | T07 | D07 | A07 |
| 08. Phân quyền (07) | V08 | T08 | D08 | A08 |
| 09. Migration (09) | V09 | T09 | D09 | A09 |
| 10. Sao lưu và phục hồi (10) | V10 | T10 | D10 | A10 |

## Nguyễn Quốc Việt – 24110381

**Phân hệ:** Khách hàng, dịch vụ và đánh giá. **File:** [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql).

- Thiết kế và ràng buộc DichVu; giải thích PK/FK, CHECK, UNIQUE, DEFAULT và dữ liệu gốc; thử đầu vào sai (V01).
- Tra cứu theo DanhMucId; tạo/gỡ index trên dữ liệu mô phỏng, so sánh IO và Scan/Seek (V02).
- Đọc, giải thích vw_DichVuCongKhai; tự tạo view ngắn cho phân hệ và kiểm tra kết quả (V03).
- Sử dụng fn_DiemDanhGia; tự viết hàm tính toán và phân biệt scalar/TVF (V04).
- Gọi sp_LuuDanhMucDichVu; giải thích tham số, quyền và nghiệp vụ; tự viết SP tra cứu theo mã (V05).
- Giải thích tr_DanhGia_KiemTraDon; chạy lệnh vi phạm để chứng minh trigger chặn (V06).
- Thực hành BEGIN/COMMIT/ROLLBACK, SAVEPOINT, TRY/CATCH trên DichVu; giải thích khóa và phiên bản (V07).
- GRANT/REVOKE/GRANT/DENY SELECT trên vw_DichVuCongKhai cho role KH; EXECUTE AS, REVERT và khôi phục quyền (V08).
- Đối chiếu module nâng cấp; tự mô phỏng ALTER có điều kiện cho dữ liệu khách hàng, dịch vụ và đánh giá, chạy lại không trùng cột (V09).
- Tự sao lưu COPY_ONLY theo MSSV, VERIFYONLY; thực hiện FULL/DIFF/LOG, RESTORE MOVE và kiểm tra dữ liệu trên bản riêng (V10; file 05).

## Đỗ Anh Tuấn – 24110369

**Phân hệ:** Đặt đơn, báo giá và điều phối. **File:** [02_DoAnhTuan.sql](02_DoAnhTuan.sql).

- Thiết kế và ràng buộc BaoGiaSoBo; giải thích PK/FK, CHECK, UNIQUE, DEFAULT và dữ liệu gốc; thử đầu vào sai (T01).
- Tra cứu theo KhachHangId; tạo/gỡ index trên dữ liệu mô phỏng, so sánh IO và Scan/Seek (T02).
- Đọc, giải thích vw_DonHangTongHop; tự tạo view ngắn cho phân hệ và kiểm tra kết quả (T03).
- Sử dụng fn_KyThuatVienPhuHop; tự viết hàm tính toán và phân biệt scalar/TVF (T04).
- Gọi sp_TaoBaoGiaSoBo; giải thích tham số, quyền và nghiệp vụ; tự viết SP tra cứu theo mã (T05).
- Giải thích tr_DonHang_KiemTraTrangThai; chạy lệnh vi phạm để chứng minh trigger chặn (T06).
- Thực hành BEGIN/COMMIT/ROLLBACK, SAVEPOINT, TRY/CATCH trên BaoGiaSoBo; giải thích khóa và phiên bản (T07).
- GRANT/REVOKE/GRANT/DENY SELECT trên vw_DonHangTongHop cho role DPV; EXECUTE AS, REVERT và khôi phục quyền (T08).
- Đối chiếu module nâng cấp; tự mô phỏng ALTER có điều kiện cho dữ liệu đặt đơn, báo giá và điều phối, chạy lại không trùng cột (T09).
- Tự sao lưu COPY_ONLY theo MSSV, VERIFYONLY; thực hiện FULL/DIFF/LOG, RESTORE MOVE và kiểm tra dữ liệu trên bản riêng (T10; file 05).

## Bùi Nguyễn Duy Trung – 24110363

**Phân hệ:** Vật tư, nghiệm thu và bảo hành. **File:** [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql).

- Thiết kế và ràng buộc ChiTietVatTu; giải thích PK/FK, CHECK, UNIQUE, DEFAULT và dữ liệu gốc; thử đầu vào sai (D01).
- Tra cứu theo BangKeVatTuId; tạo/gỡ index trên dữ liệu mô phỏng, so sánh IO và Scan/Seek (D02).
- Đọc, giải thích vw_PhieuNghiemThu; tự tạo view ngắn cho phân hệ và kiểm tra kết quả (D03).
- Sử dụng fn_HanBaoHanh; tự viết hàm tính toán và phân biệt scalar/TVF (D04).
- Gọi sp_LuuBangKeVatTu; giải thích tham số, quyền và nghiệp vụ; tự viết SP tra cứu theo mã (D05).
- Giải thích tr_ChiTietVatTu_KhoaNghiemThu; chạy lệnh vi phạm để chứng minh trigger chặn (D06).
- Thực hành BEGIN/COMMIT/ROLLBACK, SAVEPOINT, TRY/CATCH trên ChiTietVatTu; giải thích khóa và phiên bản (D07).
- GRANT/REVOKE/GRANT/DENY SELECT trên vw_PhieuNghiemThu cho role KTV; EXECUTE AS, REVERT và khôi phục quyền (D08).
- Đối chiếu module nâng cấp; tự mô phỏng ALTER có điều kiện cho dữ liệu vật tư, nghiệm thu và bảo hành, chạy lại không trùng cột (D09).
- Tự sao lưu COPY_ONLY theo MSSV, VERIFYONLY; thực hiện FULL/DIFF/LOG, RESTORE MOVE và kiểm tra dữ liệu trên bản riêng (D10; file 05).

## Lê Tấn Tài – 24110319

**Phân hệ:** Thanh toán, đối soát và ví kỹ thuật viên. **File:** [04_LeTanTai.sql](04_LeTanTai.sql).

- Thiết kế và ràng buộc KyThuatVien; giải thích PK/FK, CHECK, UNIQUE, DEFAULT và dữ liệu gốc; thử đầu vào sai (A01).
- Tra cứu theo KyThuatVienId; tạo/gỡ index trên dữ liệu mô phỏng, so sánh IO và Scan/Seek (A02).
- Đọc, giải thích vw_ViKyThuatVien; tự tạo view ngắn cho phân hệ và kiểm tra kết quả (A03).
- Sử dụng fn_SoDuVi; tự viết hàm tính toán và phân biệt scalar/TVF (A04).
- Gọi sp_LuuTaiKhoanNganHang; giải thích tham số, quyền và nghiệp vụ; tự viết SP tra cứu theo mã (A05).
- Giải thích tr_GiaoDichVi_BatBien; chạy lệnh vi phạm để chứng minh trigger chặn (A06).
- Thực hành BEGIN/COMMIT/ROLLBACK, SAVEPOINT, TRY/CATCH trên KyThuatVien; giải thích khóa và phiên bản (A07).
- GRANT/REVOKE/GRANT/DENY SELECT trên vw_ViKyThuatVien cho role KT; EXECUTE AS, REVERT và khôi phục quyền (A08).
- Đối chiếu module nâng cấp; tự mô phỏng ALTER có điều kiện cho dữ liệu thanh toán, đối soát và ví kỹ thuật viên, chạy lại không trùng cột (A09).
- Tự sao lưu COPY_ONLY theo MSSV, VERIFYONLY; thực hiện FULL/DIFF/LOG, RESTORE MOVE và kiểm tra dữ liệu trên bản riêng (A10; file 05).
