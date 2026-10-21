# Bàn giao báo cáo và hướng dẫn HomeFix

## Tệp sử dụng

- [Báo cáo Word](Nhom08_BaoCao_HQTCSDL_HomeFix.docx): bản chỉnh sửa tại đúng đường dẫn yêu cầu.
- [Báo cáo PDF](Nhom08_BaoCao_HQTCSDL_HomeFix.pdf): bản đọc/in, mục lục và danh mục đã cập nhật.
- [Hướng dẫn CHM](../HELP/HomeFix_HuongDan.chm): 17 chủ đề, gồm cài đặt, cấu hình, 7 vai trò, quy trình, xử lý lỗi, backup/recovery.
- [Hướng dẫn HTML](../HELP/html/index.html): nội dung dự phòng khi không mở được CHM.
- [Bản Word trước sửa](archive/Nhom08_BaoCao_TruocBoSung_20261016.docx).

## Nội dung đã hoàn thiện

Giữ cấu trúc 6 chương, bìa, lề, heading, phong cách bảng và mã SQL của báo cáo cũ. Phần văn bản dùng Times New Roman 13, giãn dòng 1,5. Bổ sung lời mở đầu, bộ SQL module, cột chữ ký KTV, trigger thứ tám, ma trận quyền và minh chứng quyền SQL; hoàn thiện backup/recovery, cài đặt, kiểm thử Input–thao tác–Output, kết luận, tham khảo và phụ lục đối chiếu rubric.

PDF gồm 100 trang tổng, trong đó Chương 1–6 chiếm 85 trang (trang nội dung 1–85); đáp ứng giới hạn 50–100 trang nội dung của rubric. PDF không có trang trắng hoặc lỗi tham chiếu phát hiện được. Word có 19 hình và 115 bảng, gồm cả các khung mã SQL.

Word được cập nhật trường/mục lục bằng Microsoft Word. Vì bộ xuất PDF của Word bị chờ, PDF được xuất bằng LibreOffice và cập nhật lại các danh mục theo chính bản PDF. Hai bộ hiển thị có thể ngắt trang khác nhau một trang; mục lục của từng định dạng được cập nhật theo phân trang tương ứng. Bản Word gốc và các style không bị chuyển đổi sang định dạng LibreOffice.

## Kiểm chứng

- Lượt chạy mới: 108 ca API/SQL đạt, 92 lượt màn hình desktop/mobile đạt, 17 bước nghiệp vụ đạt; thêm 29 ảnh trước/sau thao tác.
- Đã kiểm thử cài SQL nguyên khối/module, chạy lại migration, backup/restore Full–Diff–Log, trạng thái ONLINE và CHECKDB.
- CHM biên dịch thành công; các tệp bên trong khớp nội dung nguồn; mục lục ASCII. Đọc bằng bộ hiển thị Windows xác nhận UTF-8 và không tràn chiều ngang ở trang đầu. Toàn bộ 17 trang HTML qua kiểm tra ở 2 độ rộng, không thiếu ảnh/tràn ngang.
- Bằng chứng tại [20261016-report](evidence/20261016-report/); kết quả kiểm tra tài liệu tại [report-revision](evidence/report-revision/).

## Phạm vi cần trình bày đúng

Email/OTP dùng provider giả lập trong bộ kiểm thử; AI bên ngoài và STOPAT chưa được kiểm thử trực tiếp. Chưa kiểm thử tải sản xuất. Tài khoản SQL nghiệp vụ chưa được tách toàn bộ theo quyền tối thiểu từng phân hệ; lịch sao lưu/RPO/RTO trong báo cáo là đề xuất, không được trình bày là cam kết đã đo. Báo cáo đã nêu các giới hạn này.

Chưa sửa slide và chưa push GitHub trong đợt hoàn thiện tài liệu. Không tự chấm điểm hoặc thay đổi phân công thành viên đã có trong báo cáo.
