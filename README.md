# HomeFix — Đồ án Hệ quản trị cơ sở dữ liệu

Ứng dụng đặt dịch vụ sửa chữa tại nhà dùng **SQL Server + Node.js/Express + React**. Bản tinh gọn ngày 22/10/2026 tập trung vào SQL và quy trình nghiệp vụ để có thể đọc, chạy và giải thích trong SSMS.

## 1. Cấu trúc

```text
SQL/
  CSDL_HomeFix.sql          Bộ cài database mới, đầy đủ module
  seed_data.sql            Seed riêng, chỉ chạy khi các bảng còn trắng
  README.md                Giải thích SQL và câu lệnh thực hành trong SSMS
  modules/
    00_schema.sql          28 bảng và ràng buộc
    01_index.sql           Index truy vấn và UNIQUE có điều kiện
    02_function.sql        6 hàm
    03_view.sql            34 view
    04_sp.sql              19 SP tài khoản/tiện ích
    05_transaction.sql     26 SP nghiệp vụ/báo cáo
    06_trigger.sql         7 trigger
    07_security.sql        Quyền của các role
    08_seed.sql            Dữ liệu sạch
    09_data_migration.sql  Ghi chú phiên bản, không nhập giao dịch cũ
    10_backup_recovery.sql SP sao lưu và hướng dẫn phục hồi
SRC/
  package.json             Lệnh cài, chạy và kiểm thử
  backend/
    src/                   API và tầng truy cập SP/View/TVF
    tools/                 Dựng bộ cài, cài database, tạo môi trường
    test/core.test.js      Kiểm thử tích hợp cốt lõi trên database riêng
    .env.example           Mẫu cấu hình, không có bí mật thật
  frontend/
    src/                   Giao diện theo vai trò, form và bảng dữ liệu
```

Thư mục DOC, SLIDES, HELP, bản hướng dẫn vấn đáp cũ và các bộ test/chụp màn hình cũ đã được đưa ra ngoài mã vận hành. Bản sao trước thay đổi trên máy nằm tại `D:\Subject_K5\DBMS\_archives\HomeFix_TruocTaiCauTruc_20261022`.

## 2. Kiến trúc truy cập dữ liệu

- Controller backend gọi `exec('sp_...', params)` để ghi hoặc thực hiện nghiệp vụ. Hàm này dùng `request.execute()` và kiểu tham số lấy từ hợp đồng SQL đã sinh; không nhận câu SQL từ HTTP.
- Đọc dùng `queryView()` hoặc `queryFunction()`. Tên đối tượng có trong danh sách đăng ký; điều kiện lọc được dựng từ các toán tử cho phép và giá trị được tham số hóa.
- Không có SELECT/INSERT/UPDATE/DELETE bảng trong controller. Các câu SELECT dữ liệu trong `db.js` chỉ nhắm đến view/TVF đã đăng ký. Công cụ cài đặt và kiểm thử quản trị có quyền khác với API vận hành.
- Mỗi SP ghi kiểm tra vai trò, quyền sở hữu, dữ liệu, trạng thái và phiên bản trước khi cập nhật. Có transaction, savepoint khi nằm trong transaction ngoài, TRY/CATCH và XACT_STATE.
- Có **46 SP**: 44 SP ghi có giao dịch; `sp_BaoCaoTongHop` chỉ đọc; `sp_SaoLuuHeThong` dành cho DBA và không mở transaction vì SQL Server không cho BACKUP nằm trong transaction. [Quy định BACKUP của Microsoft](https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql).
- Số dư ví được SP duyệt ví/đối soát cập nhật cùng giao dịch ghi sổ cái. View ví đối chiếu số dư với SUM sổ. Trigger sổ cái ngăn UPDATE/DELETE; không có cơ chế cập nhật số dư lần hai bằng trigger.
- Tỷ lệ hoa hồng lưu theo phần trăm: `15` nghĩa là **15%** của tiền công, không phải `0.15`.

Khi thay đổi SQL, sửa module trước rồi chạy `npm.cmd run sql:build`. Lệnh dựng lại bộ cài tổng, seed riêng và `backend/src/db-contract.json` dùng để kiểm tra tên/kiểu tham số. Không sửa riêng file tổng rồi để module lệch nhau.

### Phân quyền thực thi

JWT middleware kiểm tra phiên/tài khoản/role ở mỗi request. `DB_IMPERSONATE=true` là cấu hình mặc định: backend mở kết nối riêng cho request, ghi Id người dùng vào SESSION_CONTEXT chỉ đọc, rồi thực thi dưới `hf_KH`, `hf_KTV`, … tương ứng. Kết nối được đóng sau phản hồi để tránh lẫn ngữ cảnh giữa người dùng. SP đối chiếu actor do server cung cấp với ngữ cảnh này.

Database có **7 role nghiệp vụ** được nêu trong yêu cầu. Role kỹ thuật bổ sung `HomeFix_UngDung`/user `hf_UngDung` chỉ phục vụ đăng nhập, đăng ký và OTP; chỉ view xác thực nội bộ chứa hash bcrypt. Các view danh sách không trả hash. User WITHOUT LOGIN là ngữ cảnh thực thi bên trong database, không phải 7 tài khoản đăng nhập SQL độc lập.

Các role bị DENY truy cập bảng trực tiếp; được GRANT EXECUTE đúng SP và SELECT đúng view/TVF. SP/view và bảng cùng chủ sở hữu `dbo` để sử dụng ownership chaining. [Microsoft: ownership chaining và context switching](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-ownership-chains-and-context-switching). Quyền xem từng đơn/tệp còn được backend kiểm tra theo người dùng thực tế; role SQL chỉ đại diện nhóm nghiệp vụ.

Tài khoản kết nối của backend phải có quyền IMPERSONATE các user `hf_*`. Môi trường học tập hiện dùng Windows Authentication của chủ máy; khi triển khai máy chủ nên dùng login kỹ thuật riêng có đúng quyền kết nối/IMPERSONATE các user này, không cấp thông tin kết nối SQL cho người dùng web. Tài khoản cài đặt/backup cần quyền quản trị riêng.

## 3. Cài từ database trắng

Yêu cầu máy: Node.js từ 22.12, npm, SQL Server/Express đang chạy, `sqlcmd`, ODBC Driver 17 for SQL Server khi dùng Windows Authentication. Backend chọn đúng một driver theo `DB_AUTH`; không nhập đồng thời hai driver.

Mở PowerShell trong thư mục dự án:

```powershell
cd SRC
npm.cmd install
node backend/tools/setup-environment.js
```

Mở `backend/.env`, kiểm tra:

```dotenv
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HomeFix_DBMS_Nhom08
DB_AUTH=windows
DB_IMPERSONATE=true
PORT=3000
```

Công cụ setup chỉ tạo `.env` khi chưa có và sinh JWT_SECRET ngẫu nhiên. Không đưa `.env` lên GitHub. Nếu dùng SQL Authentication, đặt `DB_AUTH=sql`, `DB_USER`, `DB_PASSWORD` của tài khoản kết nối có quyền cần thiết. Cài đặt bằng tài khoản đủ quyền tạo database; không dùng các user WITHOUT LOGIN của nghiệp vụ để cài.

```powershell
npm.cmd run sql:build
npm.cmd run db:init
npm.cmd run build
npm.cmd start
```

Mở **http://localhost:3000**. Khi phát triển, `npm.cmd run dev` mở API và Vite ở http://localhost:5173.

**Bộ cài chỉ tạo database mới:** nếu DB_NAME đã tồn tại, chương trình dừng và yêu cầu tên khác. Không tự DROP database hoặc chạy seed để xóa giao dịch. Muốn bắt đầu một lần demo trắng, đổi DB_NAME sang tên mới bắt đầu `HomeFix_`, cài lại và khởi động lại server. `seed_data.sql` từ chối database đã có tài khoản; không chạy seed lần hai sau bộ cài tổng.

Máy được bàn giao đang dùng database **`HomeFix_DBMS_Clean_20261022`**. Cấu hình `.env` cục bộ trỏ đúng database đó; tên này khác tên mặc định của bộ cài để giữ bản trước tái cấu trúc phục vụ khôi phục khi cần.

## 4. Seed sạch và đăng nhập

| Số điện thoại | Vai trò | Công việc |
|---|---|---|
| 0900000001 | KH | Đặt dịch vụ, duyệt giá/vật tư, ký, chuyển khoản, hỗ trợ, đánh giá |
| 0900000002 | KTV | Nhận đơn, tiến độ, vật tư, ký nghiệm thu, thu COD, ví |
| 0900000003 | DPV | Báo giá và điều phối |
| 0900000004 | CSKH | Xử lý phiếu hỗ trợ và trao đổi |
| 0900000005 | KT | Duyệt ví, xác minh BANK, đối soát |
| 0900000006 | GD | Báo cáo |
| 0900000007 | ADMIN | Tài khoản/role/khóa, danh mục, cấu hình, ngân hàng |

Mật khẩu cả 7 tài khoản mẫu: **`123456`**. Database lưu bcrypt hash, không lưu mật khẩu rõ. Tài khoản mẫu dành cho bài học.

Seed chỉ thêm: 7 người dùng, hồ sơ KTV số dư 0, 5 danh mục/5 dịch vụ gốc, tài khoản ngân hàng mô phỏng và cấu hình. Không có đơn, lịch sử, vật tư, nghiệm thu, thanh toán, sổ ví, đánh giá, OTP hoặc nhật ký chèn sẵn. Tài khoản ngân hàng `DEMO/000000000000` dùng minh họa, không chuyển tiền thật.

## 5. Chạy luồng nghiệp vụ sau khi cài

### Chuẩn bị ví

1. Đăng nhập KTV → Ví, tải ảnh chứng từ mô phỏng mục đích WalletProof, ghi nhận Id tệp.
2. Tạo yêu cầu Deposit, ví dụ 500.000, kèm Id chứng từ và ghi chú.
3. Đăng nhập KT → Tài chính → duyệt yêu cầu. Ví tăng sau khi duyệt; duyệt lặp/phiên bản cũ bị từ chối.

Yêu cầu rút tiền được kiểm số dư khả dụng sau khi giữ tiền cho các yêu cầu đang chờ; khi đang có phân công hoạt động không được rút. Không cộng tiền vào ví bằng sửa trực tiếp bảng.

### Một đơn COD đầy đủ

1. KH chọn dịch vụ, nhập địa chỉ và mô tả, tạo đơn.
2. DPV mở đơn, lập báo giá: phí kiểm tra 50.000, tiền công 200.000, tỷ lệ 15.
3. KH duyệt báo giá. DPV giao KTV mẫu đang sẵn sàng.
4. KTV nhận phân công, cập nhật Di chuyển → Đến nơi → Đang xử lý.
5. KTV lập đề xuất vật tư nếu cần; KH duyệt. Hai vật tư giá 50.000 sẽ tính 100.000 tại SQL.
6. KTV lập nghiệm thu, tải chữ ký với mục đích TechnicianSignature và ký bằng Id tệp đó.
7. KH tải chữ ký mục đích CustomerSignature, chọn đúng Id rồi ký nghiệm thu, chọn COD.
8. KTV ghi nhận đã thu tiền COD. Đơn hoàn thành và tạo đối soát Pending.
9. KT xác nhận đối soát. Hoa hồng là 200.000 × 15% = 30.000, trừ ví thợ; không tính 15% trên tổng tiền gồm vật tư/phí kiểm tra.
10. KH đánh giá hoặc mở phiếu hỗ trợ; CSKH phản hồi và xử lý phiếu.

### Một đơn BANK

Lặp các bước đến nghiệm thu nhưng KH chọn BANK. KH tải chứng từ mục đích PaymentProof của đúng đơn rồi tạo yêu cầu chuyển khoản, chọn tài khoản nhận tiền và nhập mã tham chiếu. KT xác nhận đúng số tiền thực nhận; chỉ lúc đó mới ghi khoản ThanhToan. Khi đối soát, tiền thuộc thợ bằng tổng thanh toán trừ hoa hồng được cộng vào ví. Chứng từ, mã tham chiếu, phiên bản và trạng thái giúp ngăn dùng lại/ghi nhận hai lần.

Giao diện Admin chỉ có danh sách tài khoản, tạo tài khoản bằng dropdown vai trò, đổi vai trò và Khóa/Mở khóa. Không có bảng ma trận phân quyền. Hệ thống giữ phiếu hỗ trợ truyền thống của CSKH.

## 6. Demo SQL và giải thích lỗi

Đọc [SQL/README.md](SQL/README.md), mở các module cần giải thích. Tài liệu có câu lệnh SELECT trên view, EXEC tạo đơn/báo giá/điều phối trong giao dịch rồi rollback, ví dụ trigger từ chối dữ liệu sai và EXECUTE AS kiểm quyền. Không cần thư mục vấn đáp/demo riêng.

- `ROWVERSION` là 8 byte tự đổi, không phải ngày giờ; API trả chuỗi 0x… và gửi lại thành PhienBanDuKien.
- 51003 → quyền không phù hợp; 51004 → không có đối tượng; 51009 → trạng thái/phiên bản/dữ liệu không hợp lệ; 547 → CHECK/FK; 2601/2627 → trùng khóa.
- Thông báo lỗi từ SQL được API chuyển thành HTTP 400/403/404/409; giao diện hiện nội dung để người dùng tải lại hoặc sửa dữ liệu.
- `GO` tách batch trong SSMS/sqlcmd; biến khai báo hết phạm vi sau GO.
- Chỉ chạy CREATE TABLE trong bộ cài database mới. Khi muốn minh họa nghiệp vụ, gọi EXEC; chạy lại CREATE PROCEDURE không có nghĩa nghiệp vụ đã phát sinh.

## 7. Sao lưu và phục hồi

Mở `SQL/modules/10_backup_recovery.sql`. Sau bộ cài, sp_SaoLuuHeThong đã có trong database. Dùng tài khoản DBA, thư mục trên máy SQL Server có quyền ghi, và các tên file mới cho từng lần chạy. Bài hướng dẫn có FULL → DIFF → LOG, VERIFYONLY, FILELISTONLY, MOVE, NORECOVERY/RECOVERY và CHECKDB; không tự phục hồi đè database đang dùng.

BACKUP/RESTORE phải chạy ngoài transaction; đây là ngoại lệ kỹ thuật bắt buộc. Role Admin trên website không được cấp quyền backup từ HTTP. SQL backup không bao gồm ảnh vật lý trong backend/uploads; khi sao lưu ứng dụng cần giữ thư mục uploads riêng.

## 8. Kiểm thử và những tệp không đưa vào Git

```powershell
npm.cmd run format:check
npm.cmd test
```

Kiểm thử tự tạo database tên `HomeFix_Test_<ngẫu nhiên>`, chạy API với database role thật, kiểm tra seed, COD/BANK, số tiền, concurrency, quyền, tài khoản, OTP và trigger. Cuối lượt chạy xóa đúng database thử của lượt đó. Cần tài khoản đủ quyền tạo/xóa database và IMPERSONATE để chạy test. Không chạy các thao tác thử lên database đang dùng.

`node_modules`, `.env`, `dist`, `uploads`, ảnh chụp và test-results/log được bỏ qua bằng .gitignore. Chỉ giữ bộ kiểm thử cốt lõi ở `backend/test`, không cần các bộ ảnh/log cũ.

OTP phát triển có thể dùng `OTP_PROVIDER=console`: mã được in trên terminal cục bộ, không trả qua API. Để gửi email thật, cấu hình SMTP_HOST/PORT/USER/PASSWORD/FROM. Chức năng đổi mật khẩu khi đang đăng nhập kiểm mật khẩu cũ; API reset qua OTP kiểm mã dùng một lần và email tài khoản. Việc kiểm thử không tự khẳng định đã gửi email ra dịch vụ bên ngoài.

Kết quả xác minh ngày 22/10/2026: format và build đạt; 13 nhóm kiểm thử tích hợp cốt lõi đạt trên database tạm; 21 kiểm tra SQL nghiệp vụ và 33 lượt trang của 7 vai trò đã được kiểm chứng. Chuỗi FULL/DIFF/LOG được phục hồi sang database thử riêng và CHECKDB đạt. Database vận hành bàn giao vẫn có 7 tài khoản, 0 đơn, 0 giao dịch ví, 0 OTP và 0 nhật ký.
