# HomeFix — Quản lý dịch vụ sửa chữa và bảo trì thiết bị tại nhà

Đồ án học phần **Hệ quản trị cơ sở dữ liệu (DBMS330284)**, lớp **261DBMS330284_02**, Nhóm **08**. HomeFix quản lý quy trình đặt dịch vụ, báo giá, điều phối kỹ thuật viên, nghiệm thu, thanh toán, đối soát và hỗ trợ sau dịch vụ.

Ứng dụng sử dụng **React + Vite**, **Node.js + Express** và **Microsoft SQL Server**. Các nghiệp vụ chính sử dụng thủ tục, hàm, view, trigger và transaction trên CSDL thật.

## 1. Thông tin nhóm

**GVHD:** ThS. Phan Thị Thể. **Học kỳ:** 1, năm học 2026–2027.

| Thành viên | MSSV |
| --- | --- |
| Nguyễn Quốc Việt | 24110381 |
| Đỗ Anh Tuấn | 24110369 |
| Bùi Nguyễn Duy Trung | 24110363 |
| Lê Tấn Tài | 24110319 |

## 2. Thành phần bản nộp

| Đường dẫn | Nội dung |
| --- | --- |
| [Báo cáo Word](DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.docx) / [PDF](DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.pdf) | Phân tích, thiết kế, SQL, giao dịch, phân quyền, giao diện và kiểm thử |
| [Slide PowerPoint](SLIDES/Nhom08_ThuyetTrinh_HQTCSDL_HomeFix.pptx) / [PDF](SLIDES/Nhom08_ThuyetTrinh_HQTCSDL_HomeFix.pdf) | Nội dung trình bày |
| [SQL/CSDL_HomeFix.sql](SQL/CSDL_HomeFix.sql) | Script tạo toàn bộ CSDL, quyền và dữ liệu mẫu |
| [SQL/CSDL_HomeFix_MinhHoa.sql](SQL/CSDL_HomeFix_MinhHoa.sql) | Truy vấn minh họa trên CSDL đã khởi tạo |
| [SQL/README.md](SQL/README.md) | Đối chiếu đường gọi API với thủ tục/hàm/view |
| [Đối chiếu yêu cầu](DOC/DOI_CHIEU_YEU_CAU.md) | Ánh xạ yêu cầu học phần với sản phẩm |
| `SRC/backend`, `SRC/frontend` | Mã nguồn API và giao diện |
| `SRC/database` | Script SQL thành phần theo thứ tự thực thi |
| `SRC/scripts`, `SRC/tests` | Khởi tạo CSDL và kiểm thử |
| `DOC/images`, `DOC/evidence` | Hình minh họa và kết quả kiểm chứng |

## 3. Yêu cầu môi trường

Hướng dẫn này dành cho **Windows**.

| Thành phần | Yêu cầu |
| --- | --- |
| Node.js | **22.12 trở lên**, kèm npm |
| SQL Server | Database Engine đang chạy; cấu hình mẫu dùng `localhost\SQLEXPRESS` |
| ODBC | **ODBC Driver 17 for SQL Server**, 64-bit, khi dùng Windows Authentication |
| Quyền SQL | Tài khoản kết nối có quyền tạo CSDL và các đối tượng bên trong |
| Internet | Cần khi cài thư viện bằng npm |
| SSMS hoặc sqlcmd | Dùng để xem CSDL và thực thi script SQL độc lập |
| Microsoft Edge | Cần khi chạy kiểm thử giao diện tự động |

Kiểm tra Node.js bằng `node --version`, npm bằng `npm.cmd --version`. **SSMS là công cụ quản trị; cài SSMS chưa đồng nghĩa đã cài SQL Server Database Engine.** Mở `services.msc`, kiểm tra `SQL Server (SQLEXPRESS)` đang Running. Nếu dùng instance khác, xem mục 5.

## 4. Cài đặt và chạy lần đầu

Với `localhost\SQLEXPRESS` và Windows Authentication:

1. Tải, giải nén mã nguồn hoặc clone repository:

   ```powershell
   git clone https://github.com/bndt0103/DBMS_HomeFix.git
   cd DBMS_HomeFix
   ```

2. Chạy **`CAI_DAT.bat`** ở thư mục gốc. Script cài thư viện, khởi tạo CSDL và build giao diện.
3. Khi cài đặt thành công, chạy **`CHAY_HOMEFIX_DBMS.bat`**.
4. Mở **http://localhost:3000**. Đăng nhập bằng tài khoản tại mục 7.

Lần đầu, script tạo `SRC/backend/.env`, sinh JWT ngẫu nhiên và tạo CSDL `HomeFix_DBMS_Nhom08_TiengViet` nếu chưa có. Dữ liệu và mật khẩu tài khoản đã tồn tại được giữ khi chạy lại khởi tạo.

**Những lần sau chỉ cần chạy `CHAY_HOMEFIX_DBMS.bat`.** Giữ cửa sổ server mở khi sử dụng. Nhấn `Ctrl+C` để dừng.

Có thể thực hiện bằng PowerShell, từ thư mục `SRC`:

```powershell
npm.cmd ci
npm.cmd run db:init
npm.cmd run build
npm.cmd start
```

Các lệnh dùng `npm.cmd` để hoạt động cả khi PowerShell chặn `npm.ps1`.

## 5. Cấu hình instance hoặc tài khoản SQL khác

Thực hiện trước khi chạy `CAI_DAT.bat` nếu máy không dùng cấu hình mặc định. Từ thư mục gốc:

```powershell
if (!(Test-Path SRC/backend/.env)) {
    Copy-Item SRC/backend/.env.example SRC/backend/.env
}
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Mở `SRC/backend/.env`, dán chuỗi vừa sinh vào `JWT_SECRET` và sửa kết nối:

```dotenv
PORT=3000
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=HomeFix_DBMS_Nhom08_TiengViet
DB_AUTH=windows
DB_ODBC_DRIVER=ODBC Driver 17 for SQL Server
DB_ENCRYPT=false
JWT_SECRET=<chuỗi ngẫu nhiên đã sinh>
CLIENT_ORIGINS=http://localhost:5173,http://localhost:3000
```

- Instance mặc định: đặt `DB_SERVER=localhost`.
- Named instance: dùng đúng tên kết nối được trong SSMS.
- Giữ cấu hình riêng nếu `.env` đã tồn tại. `db:init` chỉ tự sinh JWT khi tạo file lần đầu, không thay giá trị `replace-…` trong file có sẵn.

Để dùng SQL Server Authentication:

```dotenv
DB_AUTH=sql
DB_USER=<tài khoản SQL>
DB_PASSWORD=<mật khẩu SQL>
```

SQL Server phải cho phép SQL Authentication; tài khoản cần quyền phù hợp. Không bắt buộc dùng `sa`. Với kết nối TCP, kiểm tra TCP/IP và cấu hình mạng của instance. Lưu `.env`, chạy cài đặt theo mục 4. Sau mỗi lần đổi cấu hình, dừng và khởi động lại server.

### Email OTP

Đăng nhập tài khoản mẫu không cần email. Đăng ký, khôi phục và đổi mật khẩu qua OTP cần cấu hình nhà cung cấp gửi email trong `.env`:

```dotenv
OTP_EMAIL_PROVIDER=gmail
GMAIL_USER=<địa chỉ Gmail gửi thư>
GMAIL_APP_PASSWORD=<Google App Password>
```

Hoặc sử dụng `OTP_EMAIL_PROVIDER=resend`, `RESEND_API_KEY` và `OTP_EMAIL_FROM` theo cấu hình tài khoản Resend. Không đưa `.env`, mật khẩu và khóa dịch vụ thật vào repository.

## 6. Khởi tạo bằng file SQL độc lập

1. Mở [CSDL_HomeFix.sql](SQL/CSDL_HomeFix.sql) trong SSMS.
2. Bật **Query → SQLCMD Mode**.
3. Kiểm tra `TenCSDL` ở đầu file, mặc định `HomeFix_DBMS_Nhom08_Import`; tên này phải chưa tồn tại.
4. Thực thi toàn bộ file để tạo cấu trúc, quyền, dữ liệu mẫu và kiểm tra ràng buộc.

Hoặc chạy từ thư mục gốc:

```powershell
sqlcmd -S "localhost\SQLEXPRESS" -E -C -b -f 65001 -i "SQL/CSDL_HomeFix.sql"
```

Để website dùng CSDL vừa tạo, đặt `DB_NAME=HomeFix_DBMS_Nhom08_Import` trong `.env`, cấu hình JWT theo mục 5, rồi chạy `npm.cmd ci`, `npm.cmd run build`, `npm.cmd start` trong `SRC`.

Script từ chối ghi đè CSDL đã tồn tại. Muốn minh họa trên CSDL hiện có, chọn đúng CSDL trong SSMS và chạy [CSDL_HomeFix_MinhHoa.sql](SQL/CSDL_HomeFix_MinhHoa.sql).

## 7. Tài khoản mẫu

Mật khẩu khi khởi tạo lần đầu: **`HomeFix@123`**.

| Vai trò | Email | Chức năng |
| --- | --- | --- |
| Khách hàng | `kh@homefix.local` | Đặt dịch vụ, phê duyệt, thanh toán, đánh giá, hỗ trợ |
| Kỹ thuật viên | `ktv@homefix.local` | Nhận việc, tiến độ, vật tư, nghiệm thu, ví |
| Điều phối | `dpv@homefix.local` | Báo giá, phân công, theo dõi đơn |
| CSKH | `cskh@homefix.local` | Khiếu nại và bảo hành |
| Kế toán | `kt@homefix.local` | Chuyển khoản, duyệt ví, đối soát |
| Quản trị | `admin@homefix.local` | Tài khoản, dịch vụ, cấu hình, nhật ký |
| Giám đốc | `gd@homefix.local` | Báo cáo điều hành và chính sách |

Có thêm `kh2@homefix.local`, `ktv2@homefix.local` để kiểm tra quyền sở hữu và phân công. Mật khẩu đã đổi trên máy được giữ nguyên qua `db:init`.

## 8. Chạy khi phát triển

Sau khi cài thư viện và khởi tạo CSDL, từ `SRC` chạy:

```powershell
npm.cmd run dev
```

Mở **http://localhost:5173**. Vite cập nhật giao diện khi sửa mã và chuyển tiếp `/api` đến Express tại cổng `3000`. Backend tự khởi động lại khi mã thay đổi.

Để chạy bản build, dùng `npm.cmd run build` rồi `npm.cmd start`. Dừng server đang dùng cổng `3000` trước khi chuyển chế độ. Nếu đổi cổng API, cập nhật `PORT`, `CLIENT_ORIGINS` và proxy trong `SRC/frontend/vite.config.js`.

## 9. Kiểm tra và kiểm thử

- http://localhost:3000 hiển thị trang đăng nhập.
- http://localhost:3000/api/health trả `data.status = "ok"`.
- Đăng nhập khách hàng và kiểm tra danh mục dịch vụ.

Chạy trong `SRC`:

| Lệnh | Phạm vi |
| --- | --- |
| `npm.cmd run test:isolated` | API, SQL, transaction, quyền và đồng thời trên CSDL tạm |
| `npm.cmd run test:all` | Build, kiểm thử API/SQL và giao diện Edge |
| `npm.cmd run test:sql-usage` | Các kiểm thử trên và ghi nhận sáu thủ tục được gọi qua API bằng Extended Events |
| `npm.cmd run format:check` | Định dạng mã nguồn |

Các lệnh kiểm thử tách biệt tạo và dọn CSDL tạm. Tài khoản SQL cần quyền tạo/xóa CSDL; `test:sql-usage` cần thêm quyền quản lý/đọc Extended Events. Đặt `EDGE_PATH` nếu Edge nằm ngoài đường dẫn mặc định.

Kết quả mới nằm trong `SRC/test-results`. Minh chứng bản nộp nằm tại [DOC/evidence](DOC/evidence). `npm test` và `test:e2e` chỉ dành cho môi trường kiểm thử đã chuẩn bị; ưu tiên các lệnh tách biệt nêu trên.

## 10. Trình tự demo

1. Khách đặt dịch vụ, gửi mô tả và ảnh hiện trạng.
2. Điều phối lập báo giá; khách duyệt; điều phối phân công kỹ thuật viên đủ điều kiện.
3. Kỹ thuật viên nhận việc và cập nhật tiến độ đúng thứ tự.
4. Kỹ thuật viên đề xuất vật tư; khách duyệt; kỹ thuật viên gửi nghiệm thu và khách xác nhận.
5. Thu COD hoặc gửi chứng từ chuyển khoản; kế toán xác nhận và đối soát.
6. Khách đánh giá hoặc gửi hỗ trợ; các bộ phận xem báo cáo theo quyền.

Mở `SRC/database/CSDL_HomeFix_14_GiaoDich.sql` để giải thích transaction. Xem [SQL/README.md](SQL/README.md) để đối chiếu API, hàm/view và minh chứng thực thi.

## 11. Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
| --- | --- |
| Không tìm thấy Node.js/npm | Cài Node.js phù hợp, mở terminal mới và kiểm tra phiên bản |
| PowerShell chặn npm | Dùng `npm.cmd` |
| Không kết nối SQL | Kiểm tra dịch vụ, instance, ODBC, `.env`, quyền; thử cùng kết nối trong SSMS |
| JWT không hợp lệ | Thay `replace-…` bằng khóa ngẫu nhiên ít nhất 32 ký tự, khởi động lại |
| Cổng `3000` đang dùng | Dừng phiên HomeFix trước đó |
| API chạy nhưng thiếu giao diện | Chạy `npm.cmd run build` trong `SRC` |
| SQLCMD báo CSDL tồn tại | Chọn tên mới để import hoặc dùng CSDL có sẵn qua `.env` |
| Đăng nhập mẫu thất bại | Kiểm tra đúng CSDL và mật khẩu; `db:init` không đặt lại mật khẩu đã đổi |
| OTP không gửi được | Kiểm tra nhà cung cấp email; dùng tài khoản mẫu để kiểm tra riêng ứng dụng |
| Kiểm thử không tìm thấy Edge | Cài Edge hoặc đặt `EDGE_PATH` |

## 12. Phạm vi hệ thống

HomeFix phục vụ học tập và demo nghiệp vụ. Chuyển khoản được kế toán xác nhận bằng chứng từ; vị trí được cập nhật khi người dùng thao tác. Hệ thống chưa tích hợp tự động ngân hàng, gọi video hoặc theo dõi GPS liên tục. Báo cáo được tính từ dữ liệu lưu trong SQL Server.

Mỗi máy tự tạo `.env`, cài thư viện và khởi tạo CSDL. `node_modules`, `dist`, dữ liệu tải lên, khóa riêng và kết quả kiểm thử tạm được loại khỏi Git bằng `.gitignore`.
