# Kiểm chứng bộ thực hành chia đều – nhóm 08

Ngày kiểm tra: **23/10/2026**. CSDL nguồn: **HomeFix_DBMS_Clean_20261022**.

## Phạm vi thay đổi

Phân công lại theo yêu cầu mỗi thành viên đều thực hiện đủ các loại công việc SQL. Bốn file cá nhân có cùng 10 nhóm kiến thức, khác phân hệ và đối tượng. Bảng Word/PDF giữ khung 7 cột rubric; **40 gạch đầu dòng, mỗi người 10 ý**; 4 trang, tiêu đề bảng lặp và không chia đôi phần việc của một người. Ô đánh giá/ký tên để nhóm tự xác nhận, không ghi nhận lại tác giả commit.

Không sửa schema, SP, function, trigger hay quyền vận hành của HomeFix trong đợt thay tài liệu này. Không nạp lại seed hoặc thay dữ liệu DB gốc.

## Cách kiểm chứng

Sao lưu COPY_ONLY/CHECKSUM CSDL nguồn và VERIFYONLY, phục hồi sang tên tạm rồi chạy toàn bộ file SQL mới. Sau từng file, so sánh toàn bộ dòng của **28 bảng theo khóa chính**, quyền đối tượng và index với trạng thái trước thử. Kiểm tra cuối bài không còn transaction, user trở về dbo và không để lại SESSION_CONTEXT actor.

| Thành viên / bài | Batch | Tập kết quả | Lỗi dự kiến |
|---|---:|---:|---:|
| Nguyễn Quốc Việt – V01–V10 | 12 | 43 | 4 |
| Đỗ Anh Tuấn – T01–T10 | 12 | 46 | 4 |
| Bùi Nguyễn Duy Trung – D01–D10 | 12 | 41 | 4 |
| Lê Tấn Tài – A01–A10 | 12 | 42 | 4 |
| Phục hồi chung, chạy độc lập 4 lượt | 8 | 36 | 0 |

Tổng **56 batch / 208 tập kết quả**, **16 lỗi dự kiến** được bắt đúng mã: mỗi người 547 (CHECK), 51009 (trigger), hai lần 229/230 (REVOKE và DENY). Không coi thông báo vi phạm do bài học chủ động tạo là lỗi hệ thống.

- Cả 4 người: tạo/gỡ index trên bảng tạm, cùng truy vấn trước/sau trả 50 dòng; có Messages IO để so sánh. Không gỡ index ứng dụng và không dùng FORCESEEK.
- Cả 4 người: tự CREATE VIEW, CREATE FUNCTION, CREATE PROCEDURE và gọi thử; rollback gỡ các đối tượng `*_TH_*`.
- SP nghiệp vụ sử dụng dữ liệu thật của phân hệ trên bản sao và rollback về ban đầu. Không bỏ qua mục nào vì thiếu dữ liệu chuẩn bị trong lượt chạy này.
- Quyền được GRANT/REVOKE/GRANT/DENY và thực thi truy vấn thật dưới hf_role; quyền ban đầu được khôi phục. Không để lại lỗi quyền trên web.
- Cả 4 file cá nhân chạy COPY_ONLY/VERIFYONLY với MSSV riêng. Bài FULL/DIFF/LOG và phục hồi chung được chạy 4 lượt, mỗi lượt truy vấn đủ 3 dòng tại 3 mốc và CHECKDB.
- CHECKDB/CHECKCONSTRAINTS trên bản kiểm chứng không báo lỗi. Mọi dòng dữ liệu, quyền và index được so sánh sau từng file đều khớp trước thử nghiệm.
- Database thực hành/phục hồi được gỡ ở cuối. Các tệp backup được giữ tại thư mục mặc định của SQL Server; không đưa .bak/.trn vào Git.

## Cần hiểu đúng khi trình bày

- Có 10 nhóm kiến thức nhưng module 00–10 gồm 11 file; nhóm đầu gộp schema và seed. Migration và backup là việc mỗi thành viên đều phải làm.
- Lệnh UPDATE trực tiếp trong bài ràng buộc/trigger/transaction là bài DBA ở SSMS, có hoàn tác; backend vẫn ghi qua SP.
- Chênh lệch IO trong bảng 50.000 dòng là ví dụ đo tác dụng index, không phải đo tăng tốc toàn web.
- Bài hai cửa sổ giữ khóa và lỗi ROWVERSION được hướng dẫn trong HUONG_DAN.md; lượt này không tự coi thao tác hai cửa sổ của sinh viên đã hoàn thành.
- Kết quả trên xác nhận file chạy được trên bản sao CSDL hiện tại. Thành viên vẫn cần tự thực hành và xác nhận tỉ lệ hoàn thành; không phải chứng minh mọi tình huống hệ thống đều không có lỗi.
