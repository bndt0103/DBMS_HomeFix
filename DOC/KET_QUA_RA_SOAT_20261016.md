# Kết quả tích hợp và kiểm thử HomeFix — 16/10/2026

## Phạm vi và kết quả

Đã fetch và tích hợp commit `a79dff9` của thành viên trên nhánh `cap-nhat-homefix-20261008` bằng fast-forward. Các chỉnh sửa sau tích hợp đang nằm trong working tree để xem xét; chưa push lên GitHub.

Kiểm thử bằng SQL Server SQLEXPRESS cục bộ, Node.js và trình duyệt Edge qua Playwright. Lệnh `npm run test:sql-usage` build frontend, tạo CSDL kiểm thử riêng, chạy kiểm thử API/SQL, kiểm tra màn hình và nghiệp vụ xuyên suốt, rồi dọn CSDL kiểm thử. Toàn bộ lần chạy cuối hoàn tất thành công.

| Hạng mục | Kết quả |
|---|---|
| Kiểm thử tự động API, nghiệp vụ, quyền, OTP và SQL | 108 ca đạt (36 + 72), không fail/skip |
| Kiểm tra màn hình của 7 vai trò | 92 lượt đạt, desktop 1440×1000 và mobile 390×844 |
| Lỗi JavaScript/API và tràn ngang trang trong smoke test | Không phát hiện |
| Nghiệp vụ xuyên suốt bằng trình duyệt | 17 bước đạt |
| Cài SQL nguyên khối và SQL chia module | Cả hai đạt, đối chiếu 26 định nghĩa SP/function/view/trigger |
| Chạy lại migration với dữ liệu ảnh/chữ ký hiện hữu | Đạt; giữ tài khoản, mật khẩu và dữ liệu cần bảo toàn |
| Chống ghi đè CSDL đã tồn tại bằng bộ cài mới | Đạt |
| Backup Full → Diff → Log và restore CSDL riêng | Đạt; ONLINE, CHECKDB đạt và dữ liệu phục hồi được đối chiếu |
| Bằng chứng API thực sự gọi SP | Extended Events ghi nhận 6 SP |

Các ca SQL gồm rollback khi ghi lịch sử thất bại, trigger nhiều dòng, từ chối số dư âm, hai kết nối đồng thời duyệt một yêu cầu ví và kiểm tra quyền database role. Smoke test kiểm tra khả năng mở màn hình; các thao tác nghiệp vụ được kiểm chứng riêng bằng API và kịch bản 17 bước, không đồng nghĩa mọi thao tác có thể có đều đã được tự động hóa.

## Thay đổi chính

- Tách SQL thành `schema`, `index`, `function`, `view`, `sp`, `transaction`, `trigger`, `security`, `seed`, `data_migration`, `backup_recovery`. Bộ nguyên khối và bộ module được sinh cùng nguồn từ `SRC/database`, có lệnh kiểm tra đồng bộ.
- Bổ sung định nghĩa SQL mới còn thiếu trong bộ cài cũ; sửa migration ràng buộc loại ảnh để chạy lại không làm hỏng dữ liệu avatar/chữ ký KTV.
- Hoàn thiện script backup/restore chạy được trên SQL Server Express, tên bản sao duy nhất, kiểm tra checksum, phục hồi sang CSDL mới và từ chối ghi đè CSDL đích hiện hữu.
- Dashboard giám đốc hiển thị đề xuất chính sách thật và hoa hồng đã đối soát; bỏ dữ liệu đề xuất giả, công thức lợi nhuận cố định 15% và nút duyệt tài chính chỉ hiện thông báo. Chỉnh nhãn thời gian, liên kết báo cáo và trạng thái KTV bị khóa.
- Sửa tràn ngang dashboard giám đốc trên mobile; lọc trạng thái đơn theo đúng danh mục nghiệp vụ; bỏ liên kết đặt dịch vụ không phù hợp quyền ADMIN.
- Sửa nút đặt dịch vụ trong chat sang `/services`; điều chỉnh hướng dẫn AI theo đúng trình tự báo giá, khách duyệt rồi phân công. Chỉnh chế độ dev để theo dõi cả mã nguồn backend.
- Nâng kiểm thử chữ ký để xác minh chữ ký KH/KTV riêng biệt, khách ký khi nghiệm thu; mở rộng kiểm thử dashboard, chính sách, chat mobile và các màn hình của 7 vai trò.

## Luồng đã chạy xuyên suốt

KH đặt dịch vụ → điều phối lập báo giá sơ bộ → KH đồng ý → điều phối phân công → KTV nhận đơn → KH cập nhật GPS, bản đồ KTV cập nhật → KTV di chuyển/đến nơi/bắt đầu → đề xuất vật tư → KH duyệt → KTV hoàn thành và ký → KH ký nghiệm thu → kiểm tra hai chữ ký → thu COD → kế toán đối soát → KH đánh giá.

Chi tiết 17 thao tác và danh sách màn hình được lưu trong [bằng chứng kiểm thử](evidence/20261016/). File thời gian JSON dùng UTC; tương ứng ngày 16/10 theo giờ Việt Nam.

## CSDL hiện tại và cách chạy

CSDL `HomeFix_DBMS_Nhom08_TiengViet` đã được sao lưu COPY_ONLY, CHECKSUM và VERIFYONLY trước khi chạy migration. Sau nâng cấp vẫn có 9 tài khoản, dấu kiểm tra mật khẩu không đổi và số đơn giữ nguyên (0 đơn trong CSDL cục bộ trước nâng cấp). Cột chữ ký KTV đã tồn tại. Bản sao trước nâng cấp được giữ tại thư mục Backup của SQL Server; đường dẫn cụ thể nằm trong `SRC/test-results/local-upgrade.json`.

Ứng dụng được khởi động tại <http://localhost:3000>. Khi khởi động lại máy, chạy `npm start` trong `SRC` sau khi SQL Server hoạt động. Nếu thay đổi frontend, chạy `npm run build` trước.

Các lệnh xác minh, chạy trong `SRC`:

```powershell
npm run format:check
npm run sql:check
npm run test:sql-usage
```

Bộ kiểm thử tích hợp cần SQL Server và quyền tạo/xóa CSDL thử nghiệm; kiểm thử backup/restore, dọn file backup và Extended Events cần quyền quản trị SQL phù hợp. Không dùng tài khoản ứng dụng giới hạn quyền để chạy bộ kiểm thử quản trị này.

## Chuẩn bị báo cáo và vấn đáp

- [Hướng dẫn đọc/chạy SQL](../SQL/README.md).
- [Bản đồ kiến thức và câu hỏi vấn đáp](../SQL/HUONG_DAN_VAN_DAP.md).
- [Đối chiếu yêu cầu đồ án](DOI_CHIEU_YEU_CAU.md).
- Số lượng hiện tại: 30 bảng, 7 SP nghiệp vụ, 5 function, 6 view, 8 trigger, 33 index ngoài PK, 7 database role và 7 user WITHOUT LOGIN. Script backup cài thêm SP sao lưu riêng khi chạy.

Các giới hạn cần nói đúng khi trình bày: kiểm thử email sử dụng provider giả lập, chưa chứng minh gửi email thật đến hộp thư; AI ngoài hệ thống không được gọi trong bộ kiểm thử; duyệt đề xuất chính sách lưu quyết định nhưng chưa phải cơ chế tự động áp dụng giá/lịch hiệu lực. Chức năng phục hồi theo thời điểm STOPAT có ví dụ để trình bày, chưa nằm trong bài kiểm thử phục hồi tự động Full/Diff/Log. Chưa có kiểm thử tải sản xuất hoặc rà soát bảo mật độc lập.

Báo cáo Word/PDF đã được bổ sung và xuất lại trong đợt hoàn thiện tài liệu ngày 16/10/2026; hướng dẫn CHM nằm tại `HELP/HomeFix_HuongDan.chm`. Bằng chứng lượt chạy mới có ảnh Input/Output nằm trong `DOC/evidence/20261016-report`. Slide chưa được tái xuất theo đợt cập nhật báo cáo này.
