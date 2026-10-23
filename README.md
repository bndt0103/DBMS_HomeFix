# HomeFix — Đồ án Hệ quản trị cơ sở dữ liệu

Ứng dụng đặt dịch vụ sửa chữa tại nhà dùng **SQL Server + Node.js/Express + React**. Giao diện gồm: bố cục, thanh điều hướng, trang dịch vụ, đơn hàng, điều phối, ví và báo cáo. Chỉ bỏ chatbot AI và phần ma trận quyền tại trang tài khoản Admin. Tầng SQL vẫn đóng gói nghiệp vụ để đọc, chạy và giải thích trong SSMS.

## Thành viên lấy bản mới và CSDL

Nhánh dùng chung: **main**. Làm theo [hướng dẫn cài trên máy thành viên](SQL/CAI_DAT_THANH_VIEN.md) để pull/clone, tạo CSDL mới và nạp 10 đơn mẫu. Cấu hình `.env` là riêng từng máy. [Bảng phân công Word](SQL/thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.docx), [PDF](SQL/thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.pdf) và [bài học SQL cho 4 thành viên](SQL/thuc_hanh_nhom/HUONG_DAN.md) đã có trong repo.

## 1. Cấu trúc

```text
SQL/
  CSDL_HomeFix.sql          Bộ cài database mới, đầy đủ module
  seed_data.sql            Seed riêng, chỉ chạy khi các bảng còn trắng
  README.md                Giải thích SQL và câu lệnh thực hành trong SSMS
  modules/
    00_schema.sql          28 bảng và ràng buộc
    01_index.sql           Index truy vấn và UNIQUE có điều kiện
    02_function.sql        7 hàm
    03_view.sql            34 view
    04_sp.sql              19 SP tài khoản/tiện ích
    05_transaction.sql     30 SP nghiệp vụ/báo cáo
    06_trigger.sql         7 trigger
    07_security.sql        Quyền của các role
    08_seed.sql            Dữ liệu sạch
    09_data_migration.sql  Nâng cấu trúc hiện có, giữ dữ liệu
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
- Có **51 SP**: 49 SP ghi có giao dịch; `sp_BaoCaoTongHop` chỉ đọc; `sp_SaoLuuHeThong` dành cho DBA và không mở transaction vì SQL Server không cho BACKUP nằm trong transaction. [Quy định BACKUP của Microsoft](https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql).
- Số dư ví được SP duyệt ví/đối soát cập nhật cùng giao dịch ghi sổ cái. View ví đối chiếu số dư với SUM sổ. Trigger sổ cái ngăn UPDATE/DELETE; không có cơ chế cập nhật số dư lần hai bằng trigger.
- Tỷ lệ hoa hồng lưu theo phần trăm: `15` nghĩa là **15%** của tiền công, không phải `0.15`.

`/api/web` nối hợp đồng JSON của giao diện gốc với SP/View hiện tại. `web.js` xử lý các màn hình nghiệp vụ; `web-reports.js` đọc dữ liệu báo cáo; `web-shape.js` đổi tên thuộc tính trả về. Các lớp này không ghi trực tiếp vào bảng và không thay thế kiểm tra quyền ở SQL. Các API dùng tên tiếng Việt hiện có vẫn được giữ để kiểm thử và minh họa.

Khi thay đổi SQL, sửa module trước rồi chạy `npm.cmd run sql:build`. Lệnh dựng lại bộ cài tổng, seed riêng và `backend/src/db-contract.json` dùng để kiểm tra tên/kiểu tham số. Không sửa riêng file tổng rồi để module lệch nhau.

### Phân quyền thực thi

JWT middleware kiểm tra phiên/tài khoản/role ở mỗi request. `DB_IMPERSONATE=true` là cấu hình mặc định: backend mở kết nối riêng cho request, ghi Id người dùng vào SESSION_CONTEXT chỉ đọc, rồi thực thi dưới `hf_KH`, `hf_KTV`, … tương ứng. Kết nối được đóng sau phản hồi để tránh lẫn ngữ cảnh giữa người dùng. SP đối chiếu actor do server cung cấp với ngữ cảnh này.

Database có **7 role nghiệp vụ** được nêu trong yêu cầu. Role kỹ thuật bổ sung `HomeFix_UngDung`/user `hf_UngDung` chỉ phục vụ đăng nhập và đăng ký; chỉ view xác thực nội bộ chứa hash bcrypt. Các view danh sách không trả hash. User WITHOUT LOGIN là ngữ cảnh thực thi bên trong database, không phải 7 tài khoản đăng nhập SQL độc lập.

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

### Nâng bản đang có dữ liệu

Khi nâng cấp database đang dùng, sao lưu database trước theo module `10_backup_recovery.sql`, dừng ứng dụng rồi chạy trong `SRC`:

```powershell
npm.cmd install
npm.cmd run sql:build
npm.cmd run db:upgrade
npm.cmd run build
npm.cmd start
```

`db:upgrade` đọc đúng `DB_NAME` trong `.env`, bổ sung các cột còn thiếu, chuyển DeXuatVatTu/ChiTietDeXuatVatTu sang BangKeVatTu/ChiTietVatTu, bỏ quyết định duyệt vật tư và cập nhật function, view, SP, trigger, quyền. Id và chứng từ cũ được giữ nguyên; bảng kê bị từ chối trước đây không tự tính tiền. Không chạy `00_schema` hay `08_seed` lên database đang sử dụng. Công cụ dành cho bản refactor có bảng `KyThuatVien`, không chuyển tự động database HomeFix đời trước.

## 4. Seed sạch và đăng nhập

| Số điện thoại | Vai trò | Công việc |
|---|---|---|
| 0900000001 | KH | Đặt dịch vụ, duyệt báo giá sơ bộ, ký, chuyển khoản, hỗ trợ, đánh giá |
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

1. Đăng nhập KTV → Ví & thu nhập → Nạp ví, chọn ảnh chứng từ mô phỏng.
2. Nhập số tiền, ví dụ 500.000, và ghi chú rồi gửi yêu cầu. Giao diện tự tải ảnh và gắn chứng từ.
3. Đăng nhập KT → Tài chính → duyệt yêu cầu. Ví tăng sau khi duyệt; duyệt lặp/phiên bản cũ bị từ chối.

Yêu cầu rút tiền được kiểm số dư khả dụng sau khi giữ tiền cho các yêu cầu đang chờ; khi đang có phân công hoạt động không được rút. Không cộng tiền vào ví bằng sửa trực tiếp bảng.

### Một đơn COD đầy đủ

1. KH chọn dịch vụ, nhập địa chỉ và mô tả, tạo đơn.
2. DPV mở đơn → Lập báo giá sơ bộ, nhập chẩn đoán. Giá được lấy từ danh mục dịch vụ; chọn dịch vụ Bảo dưỡng máy lạnh để minh họa phí kiểm tra 50.000, tiền công 200.000 và tỷ lệ 15%.
3. KH duyệt báo giá. DPV giao KTV mẫu đang sẵn sàng.
4. KTV nhận phân công, cập nhật Di chuyển → Đến nơi → Đang xử lý.
5. KTV kê khai vật tư và đơn giá đã trao đổi trực tiếp với khách; không có bước duyệt vật tư riêng. Hai vật tư giá 50.000 sẽ tính 100.000 tại SQL.
6. KTV chọn Hoàn thành · Lập phiếu nghiệm thu; nhập nguyên nhân, biện pháp, thêm ảnh thành phẩm và ký trong khung chữ ký thợ. Gửi phiếu.
7. KH mở phiếu, ký trực tiếp trong khung chữ ký khách (hoặc chọn ảnh chữ ký), chọn Tiền mặt và xác nhận. Đơn vẫn chờ nghiệm thu/thanh toán cho đến khi KTV ghi nhận tiền.
8. KTV ghi nhận đã thu tiền COD. Đơn hoàn thành và tạo đối soát Pending.
9. KT chọn Đối soát ở đúng dòng và xác nhận trong hộp thoại tại chỗ. Hoa hồng là 200.000 × 15% = 30.000, trừ ví thợ; không tính 15% trên tổng tiền gồm vật tư/phí kiểm tra.
10. KH đánh giá hoặc mở phiếu hỗ trợ; CSKH phản hồi và xử lý phiếu.

Khách chọn đơn và gửi phiếu ngay trong mục Hỗ trợ, không bị chuyển qua danh sách đặt dịch vụ. CSKH tiếp nhận, trao đổi và kết thúc/từ chối có lý do; khách theo dõi phản hồi và bổ sung thông tin. Đặt đơn và dữ liệu mẫu không tự tạo phiếu hỗ trợ.

Khách hủy miễn phí trước khi KTV di chuyển. Khi KTV đang di chuyển/đã đến nhưng chưa bắt đầu sửa, khách phải xác nhận phí 60.000đ và chỉ chuyển khoản vào tài khoản HomeFix. KT xác minh tiền rồi đối soát để cộng đủ phí di chuyển vào ví KTV, không trừ hoa hồng; đơn vẫn đã hủy. Khi đang sửa/nghiệm thu, khách gửi phiếu cho CSKH, không hủy trực tiếp. Chi tiết SQL ở mục 9 của [SQL/README.md](SQL/README.md).

### Một đơn BANK

Lặp các bước đến nghiệm thu nhưng KH chọn BANK. KH tải chứng từ mục đích PaymentProof của đúng đơn rồi tạo yêu cầu chuyển khoản, chọn tài khoản nhận tiền và nhập mã tham chiếu. KT xác nhận đúng số tiền thực nhận; chỉ lúc đó mới ghi khoản ThanhToan. Khi đối soát, tiền thuộc thợ bằng tổng thanh toán trừ hoa hồng được cộng vào ví. Chứng từ, mã tham chiếu, phiên bản và trạng thái giúp ngăn dùng lại/ghi nhận hai lần.

Giao diện Admin chỉ có danh sách tài khoản, tạo tài khoản bằng dropdown vai trò, đổi vai trò và Khóa/Mở khóa. Không có bảng ma trận phân quyền. Hệ thống giữ phiếu hỗ trợ truyền thống của CSKH.

## 6. Demo SQL và giải thích lỗi

Đọc [SQL/README.md](SQL/README.md), mở các module cần giải thích. Tài liệu có câu lệnh SELECT trên view, EXEC tạo đơn/báo giá/điều phối trong giao dịch rồi rollback, ví dụ trigger từ chối dữ liệu sai và EXECUTE AS kiểm quyền. Bài thực hành đã chia theo 4 thành viên trong [SQL/thuc_hanh_nhom](SQL/thuc_hanh_nhom/HUONG_DAN.md).

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

Kiểm thử tự tạo database tên `HomeFix_Test_<ngẫu nhiên>`, chạy API với database role thật, kiểm tra seed, COD/BANK, số tiền, concurrency, quyền, tài khoản, đổi mật khẩu và trigger. Cuối lượt chạy xóa đúng database thử của lượt đó. Cần tài khoản đủ quyền tạo/xóa database và IMPERSONATE để chạy test. Không chạy các thao tác thử lên database đang dùng.

`node_modules`, `.env`, `dist`, `uploads`, ảnh chụp và test-results/log được bỏ qua bằng .gitignore. Chỉ giữ bộ kiểm thử cốt lõi ở `backend/test`, không cần các bộ ảnh/log cũ.

Bản web DBMS không dùng OTP/SMTP hoặc Google Maps/GPS. Đăng ký bằng số điện thoại, email không bắt buộc. Đổi mật khẩu tại Hồ sơ yêu cầu mật khẩu hiện tại; đổi thành công sẽ thu hồi phiên đăng nhập cũ. Quên mật khẩu hiển thị hướng dẫn liên hệ quản trị viên, không mở API đổi mật khẩu công khai. Các đối tượng SQL OTP/vị trí cũ được giữ để tương thích cấu trúc và không được web gọi.

Bộ kiểm thử tích hợp gồm 20 nhóm: quyền của bảy vai trò, seed, COD/BANK, vật tư/nghiệm thu, sổ ví, hỗ trợ hai chiều và phí hủy đơn. Kiểm thử trình duyệt xác minh các màn hình theo vai trò và các nút trong luồng hỗ trợ, hủy, gửi chứng từ và đối soát. Thử nghiệm sử dụng database riêng và tự dọn sau khi chạy.

## Dữ liệu và truy vấn minh họa

Bản local dùng `HomeFix_DBMS_Clean_20261022` trên `MSI\SQLEXPRESS`. Đã bổ sung 5 khách, 3 thợ, 20 dịch vụ và 10 đơn; giữ dữ liệu cũ. Tài khoản KH mới `0900001001`–`0900001005`, KTV mới `0900002001`–`0900002003`, mật khẩu `123456`. Danh tính, ảnh và chứng từ là giả lập.

Trên bản cài mới, chạy `npm.cmd run db:demo` tại `SRC` để bổ sung một lần; không chạy lại seed trắng. Lệnh không đặt lại các đơn đã demo. Mở `SQL/truy_van_mau.sql` trong SSMS để chạy ví dụ SP/function/view/index/transaction/trigger/bảo mật; mở `SQL/sao_luu_mau.sql` để sao lưu. Xem hướng dẫn và kết quả mong đợi trong [SQL/README.md](SQL/README.md).
