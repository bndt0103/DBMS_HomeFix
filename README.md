# HomeFix — Hệ thống quản lý dịch vụ sửa chữa gia đình

**Đồ án môn Hệ quản trị cơ sở dữ liệu · Nhóm 08**

HomeFix hỗ trợ quản lý quy trình cung cấp dịch vụ sửa chữa tại nhà, từ tiếp nhận yêu cầu, báo giá và điều phối kỹ thuật viên đến nghiệm thu, thanh toán và chăm sóc khách hàng. Đồ án tập trung thiết kế và triển khai cơ sở dữ liệu trên **SQL Server**, kết hợp ứng dụng web để thực hiện và kiểm chứng các nghiệp vụ.

## Mục tiêu

- Xây dựng mô hình dữ liệu quan hệ phù hợp với quy trình cung cấp dịch vụ.
- Bảo đảm tính toàn vẹn dữ liệu bằng khóa, ràng buộc và trigger.
- Đóng gói nghiệp vụ trong stored procedure; khai thác dữ liệu qua view và function.
- Vận dụng giao dịch, xử lý đồng thời, phân quyền và sao lưu cơ sở dữ liệu.

## Chức năng chính

| Vai trò | Chức năng |
|---|---|
| Khách hàng | Đặt dịch vụ, duyệt báo giá sơ bộ, theo dõi đơn, ký nghiệm thu, thanh toán, đánh giá và gửi yêu cầu hỗ trợ |
| Kỹ thuật viên | Nhận phân công, cập nhật tiến độ, kê khai vật tư và đơn giá, lập phiếu nghiệm thu, quản lý ví |
| Điều phối viên | Lập và điều chỉnh báo giá sơ bộ, phân công kỹ thuật viên phù hợp chuyên môn, khu vực và trạng thái nhận việc |
| Chăm sóc khách hàng | Tiếp nhận, trao đổi và xử lý yêu cầu hỗ trợ |
| Kế toán | Xác nhận chuyển khoản, đối soát thanh toán, duyệt yêu cầu nạp và rút ví |
| Giám đốc | Theo dõi báo cáo doanh thu và hiệu suất hoạt động |
| Quản trị viên | Quản lý tài khoản, vai trò, danh mục dịch vụ, cấu hình và nhật ký hệ thống |

Quy trình chính: **Đặt dịch vụ → Báo giá → Điều phối → Thực hiện → Nghiệm thu → Thanh toán → Đối soát**.

## Công nghệ và kiến trúc

| Thành phần | Công nghệ |
|---|---|
| Cơ sở dữ liệu | Microsoft SQL Server, T-SQL |
| Backend | Node.js, Express, JWT, bcrypt |
| Frontend | React, Vite |
| Kiểm thử | Node.js Test Runner, kiểm thử tích hợp API và SQL Server |

```text
React → Express API → Stored Procedure / View / TVF → SQL Server
```

Backend ghi dữ liệu thông qua stored procedure và đọc dữ liệu qua view hoặc table-valued function (TVF). Các lời gọi sử dụng tham số có kiểu dữ liệu; controller không truy vấn trực tiếp bảng. Quyền truy cập được kiểm tra tại API và trong SQL Server theo vai trò, người thực hiện và quyền sở hữu dữ liệu.

## Thiết kế cơ sở dữ liệu

Cơ sở dữ liệu gồm **26 bảng, 45 stored procedure, 31 view, 7 function, 7 trigger và 20 index tường minh**.

| Nội dung | Cách triển khai |
|---|---|
| Toàn vẹn dữ liệu | PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, DEFAULT |
| Xử lý nghiệp vụ | Stored procedure kiểm tra dữ liệu, quyền và trạng thái trước khi cập nhật |
| Giao dịch | BEGIN TRANSACTION, SAVE TRANSACTION, TRY…CATCH và XACT_STATE |
| Kiểm soát đồng thời | ROWVERSION và kiểm tra phiên bản khi cập nhật |
| Truy vấn, thống kê | View tổng hợp; function tính toán và tra cứu |
| Tối ưu truy vấn | Index trên các trường tra cứu và liên kết; unique index có điều kiện |
| Phân quyền | Bảy role nghiệp vụ; cấp EXECUTE trên SP và SELECT trên View/TVF tương ứng |
| Sao lưu | Thủ tục sao lưu dành cho tài khoản quản trị cơ sở dữ liệu |

Các thay đổi số dư ví và ghi sổ giao dịch được thực hiện trong cùng một transaction. Trigger ngăn sửa, xóa giao dịch ví; view đối chiếu số dư với sổ giao dịch để kiểm tra tính nhất quán. Thủ tục sao lưu chạy ngoài transaction theo yêu cầu của SQL Server.

## Cấu trúc dự án

```text
HomeFix/
├── SQL/
│   ├── CSDL_HomeFix.sql        # Bộ cài CSDL hoàn chỉnh
│   ├── du_lieu_mau.sql         # Dữ liệu minh họa nghiệp vụ
│   ├── modules/               # Mã nguồn SQL theo nhóm chức năng
│   └── README.md              # Hướng dẫn sử dụng bộ SQL
├── SRC/
│   ├── backend/
│   │   ├── src/               # API và lớp truy cập dữ liệu
│   │   ├── tools/             # Công cụ cài đặt và nâng cấp CSDL
│   │   └── test/              # Kiểm thử tích hợp
│   └── frontend/              # Giao diện React
├── Report/                    # Báo cáo Word và PDF
├── CAI_DAT.bat
└── CHAY_HOMEFIX_DBMS.bat
```

Các module SQL được tổ chức theo thứ tự: schema, index, function, view, stored procedure, transaction, trigger, security, seed, migration và backup. Chi tiết tại [SQL/README.md](SQL/README.md).

## Cài đặt và chạy

### Yêu cầu môi trường

- Node.js **22.12 trở lên** và npm.
- SQL Server hoặc SQL Server Express; SQL Server Management Studio để thao tác trực tiếp.
- Công cụ `sqlcmd`; ODBC Driver 17 for SQL Server khi sử dụng Windows Authentication.
- Tài khoản cài đặt có quyền tạo database và thiết lập ngữ cảnh thực thi trong SQL Server.

### Thiết lập ứng dụng

Mở PowerShell tại thư mục dự án:

```powershell
cd SRC
npm.cmd install
node backend/tools/setup-environment.js
```

Cập nhật `SRC/backend/.env` theo SQL Server đang sử dụng:

```dotenv
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HomeFix_DBMS_Nhom08
DB_AUTH=windows
DB_IMPERSONATE=true
PORT=3000
```

Công cụ thiết lập tự sinh khóa JWT và chỉ tạo tệp cấu hình khi chưa tồn tại. Với SQL Authentication, sử dụng `DB_AUTH=sql` và khai báo `DB_USER`, `DB_PASSWORD`. Tài khoản kết nối cần quyền thực thi ngữ cảnh các user `hf_*` của ứng dụng. Tệp `.env` không được theo dõi trong Git.

### Khởi tạo cơ sở dữ liệu và khởi động

Chạy các lệnh sau trong `SRC`:

```powershell
npm.cmd run sql:build
npm.cmd run db:init
npm.cmd run db:demo
npm.cmd run build
npm.cmd start
```

Truy cập **http://localhost:3000**. Chế độ phát triển sử dụng `npm.cmd run dev`, giao diện tại **http://localhost:5173**.

`db:init` chỉ tạo database mới và dừng nếu tên đã tồn tại. Lệnh `db:demo` là tùy chọn, bổ sung dữ liệu minh họa để tra cứu và thử nghiệm nghiệp vụ. Sau khi cài mới và nạp dữ liệu mẫu, hệ thống có **15 tài khoản, 25 dịch vụ và 10 đơn hàng**; thông tin cá nhân và chứng từ đều là dữ liệu giả lập.

Có thể cài trực tiếp bằng [SQL/CSDL_HomeFix.sql](SQL/CSDL_HomeFix.sql) trong SSMS: bật **Query → SQLCMD Mode**, đặt biến `TenCSDL` thành tên database mới rồi thực thi.

### Tài khoản minh họa

| Số điện thoại | Vai trò |
|---|---|
| 0900000001 | Khách hàng |
| 0900000002 | Kỹ thuật viên |
| 0900000003 | Điều phối viên |
| 0900000004 | Chăm sóc khách hàng |
| 0900000005 | Kế toán |
| 0900000006 | Giám đốc |
| 0900000007 | Quản trị viên |

Mật khẩu chung: **`123456`**. Mật khẩu được lưu dưới dạng bcrypt hash. Các tài khoản và thông tin ngân hàng mẫu chỉ phục vụ minh họa đồ án.

## Bảo trì và kiểm thử

Sau khi sửa module SQL, chạy `npm.cmd run sql:build` trong `SRC` để đồng bộ bộ cài tổng và danh mục tham số dùng bởi backend.

Để nâng cấp database tương thích với cấu trúc hiện hành, sao lưu dữ liệu, dừng ứng dụng rồi chạy `npm.cmd run db:upgrade`. Công cụ kiểm tra cấu trúc trước khi cập nhật; database không tương thích cần được xử lý riêng theo [hướng dẫn SQL](SQL/README.md). Không chạy lại schema hoặc seed trên database đang sử dụng.

```powershell
npm.cmd run format:check
npm.cmd test
npm.cmd run build
```

Bộ kiểm thử gồm **24 ca**, bao phủ phân quyền, dữ liệu gốc, thanh toán, đối soát, ví, hỗ trợ, hủy đơn và tính toàn vẹn dữ liệu. Kiểm thử tích hợp tạo database riêng và tự dọn sau khi hoàn thành; tài khoản chạy kiểm thử cần quyền tạo, xóa database và thực thi ngữ cảnh người dùng.

## Tài liệu

- [Hướng dẫn cơ sở dữ liệu](SQL/README.md)
- [Mã nguồn các module SQL](SQL/modules/)
- [Báo cáo đồ án — PDF](Report/Nhom08_BaoCao_HQTCSDL_HomeFix_DongBoSQL.pdf)
- [Báo cáo đồ án — Word](Report/Nhom08_BaoCao_HQTCSDL_HomeFix_DongBoSQL.docx)
