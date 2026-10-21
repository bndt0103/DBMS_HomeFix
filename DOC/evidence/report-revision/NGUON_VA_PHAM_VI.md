# Nguồn và phạm vi rà soát báo cáo

Ngày rà soát: 16/10/2026. Bản Word gốc được giữ trong `DOC/archive/Nhom08_BaoCao_TruocBoSung_20261016.docx`.

## Căn cứ chính

- Rubric DBMS330284 do người dùng cung cấp: cấu trúc 6 chương, Times New Roman 13, giãn dòng 1,5; 50–100 trang nội dung (không tính bìa, mục lục, phụ lục).
- Báo cáo gốc: giữ bìa, các section, lề, hệ thống heading/caption, màu bảng và sơ đồ. Phần thân bổ sung dùng style HF Body dựa trên Normal; bảng và mã SQL giữ phong cách bảng cũ.
- Mẫu `Mau_Caidatkiemthu.docx`: chỉ tham khảo cấu trúc điều kiện, Input, Output và thao tác. Không đưa Android, Capacitor, Cloudflare Tunnel hoặc bộ cài Inno Setup của bản CNPM sang bản DBMS.
- Mã nguồn, metadata SQL Server mới xuất và kiểm thử lại: `DOC/evidence/schema.json`, `DOC/evidence/20261016-report/`.

## Tham khảo ngoài dự án

1. [Đồ án Quản lý cửa hàng kinh doanh đồ trang trí nội thất Phúc Chí Thành, Nguyễn Thị Phương Linh, Đại học Dân lập Hải Phòng](https://lib.hpu.edu.vn/bitstream/handle/123456789/18404/87_NguyenThiPhuongLinh_CT902.pdf): tham khảo cách đặc tả giao diện theo mục đích, người sử dụng, thao tác và kết quả ở phần nội dung được công cụ tìm kiếm cung cấp; không tuyên bố đã đọc toàn bộ PDF khi máy chủ không cho tải trực tiếp.
2. [Đề cương CSDL nâng cao, Đại học Nông Lâm TP.HCM](https://fit.hcmuaf.edu.vn/fit-3901-1/vn/de-cuong-chi-tiet-mon-co-so-du-lieu-nang-cao.html): tham khảo định hướng gắn transaction và điều khiển truy xuất đồng thời với báo cáo thực hành. Đây là đề cương, không phải báo cáo của nhóm sinh viên.
3. Đã tra cứu danh mục báo cáo DBMS330284 của HCMUTE trên Studocu để đối chiếu cách tổ chức; không dùng các bản đăng lại làm nguồn khẳng định kỹ thuật hoặc sao chép nội dung. Nguồn báo cáo quán cà phê trong bản cũ chưa đủ căn cứ xác minh thông tin tác giả/năm nên được thay bằng nguồn xác định rõ hơn.
4. [Microsoft Learn — Restore and recovery overview](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-and-recovery-overview-sql-server), [CREATE USER](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql) và [Create a Help Project](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/create-a-help-project): đối chiếu thuật ngữ phục hồi, user không login và cách đóng gói CHM.

## Những điểm đã sửa/bổ sung

- Lời mở đầu; tên CSDL mặc định khác tên trên máy kiểm thử; thứ tự khách duyệt báo giá trước phân công.
- Cột `ChuKyKTVId`, phân biệt chữ ký KH/KTV; trigger thông báo chính sách thứ tám; cập nhật mã SP/function/view/trigger từ metadata hiện hành.
- Bộ SQL module; phân biệt 20 lệnh CREATE INDEX với 33 index ngoài PK.
- Ma trận quyền SQL, kiểm chứng GRANT/REVOKE/DENY; phân biệt tài khoản web, user WITHOUT LOGIN, tài khoản kết nối và ngữ cảnh báo cáo.
- Full/Diff/Log, VERIFYONLY, NORECOVERY/RECOVERY, CHECKDB, phạm vi STOPAT; sao lưu uploads và cấu hình; lịch/RPO/RTO chỉ là đề xuất nếu chưa triển khai/đo.
- Cài đặt thực tế, xử lý lỗi, kiểm thử Input–thao tác–Output, ảnh mới, kết luận và phụ lục đối chiếu rubric.
- CHM 17 chủ đề, mục lục ASCII, nội dung UTF-8; bản HTML dự phòng co giãn toàn chiều rộng.

Không tự chấm điểm thay giảng viên; không khẳng định mọi chức năng đã được chứng minh chỉ bằng smoke test hoặc ảnh. Kết quả tải, email thật, AI ngoài hệ thống và STOPAT chưa kiểm chứng được nêu trong hạn chế.
