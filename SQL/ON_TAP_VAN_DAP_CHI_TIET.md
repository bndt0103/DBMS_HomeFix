# HomeFix — Hướng dẫn hiểu dự án và vấn đáp SQL Server

Ngày rà soát: **21/10/2026**. Chuẩn bị cho buổi vấn đáp ngày **22/10/2026**.

Tài liệu này dựa trên mã dự án, `Rubric_Project_DBMS.docx`, cấu trúc lấy trực tiếp từ SQL Server và kết quả chạy thử. Những đoạn “Em có thể trình bày” là gợi ý cách giải thích sau khi đã hiểu và tự chạy, không phải nội dung cần học thuộc từng chữ.

## 1. Bắt đầu từ đâu nếu còn yếu SQL?

Đọc theo thứ tự sau, chưa cần đọc toàn bộ các file SQL từ đầu đến cuối:

1. Đọc mục 2–5: hiểu hệ thống, bảng và ràng buộc.
2. Mở `modules/05_transaction.sql`, tìm `sp_TaoDonHang`; đọc mục 7–8 của tài liệu này.
3. Mở `modules/06_trigger.sql`, tìm `trg_Vi_GhiSo`; đọc mục 6.
4. Mở SSMS và chạy lần lượt các file **01 → 08** trong [demo_van_dap](demo_van_dap/). Riêng file 08 xem lưu ý database phục hồi đã tồn tại ở mục 11.
5. Đọc mục 12–15, tự giải thích mỗi thao tác thành tiếng. Chưa giải thích được thì chạy lại đúng ví dụ đó.
6. Tra [phụ lục cấu trúc thực tế](PHU_LUC_CAU_TRUC_VAN_DAP.md) khi cô hỏi một bảng, cột hoặc ràng buộc cụ thể.

Sau phần cơ bản, chạy file **09** để xem thêm trigger thanh toán, đánh giá, thông báo; file **10** để thực hành SP đối soát và xử lý hỗ trợ. Bộ demo có **11 file, từ 00 đến 10**; file 00 chỉ tạo database lần đầu. Các số demo này không phải số module cài đặt trong `SQL/modules`.

### Kế hoạch ôn trong khoảng 3 giờ

| Thời gian | Việc cần làm | Kết quả tự kiểm tra |
|---|---|---|
| 20 phút | Đọc nghiệp vụ và quan hệ chính | Vẽ được KH → đơn → phân công → nghiệm thu → thanh toán → đối soát |
| 35 phút | Constraint và trigger | Giải thích được tại sao tiền âm, sai khách hoặc sửa sổ ví bị chặn |
| 40 phút | SP, transaction, lỗi và đồng thời | Tự chạy tạo đơn, chuyển trạng thái đúng/sai và rollback |
| 20 phút | Hàm, view, index | Phân biệt được ba đối tượng và chỉ ra một ví dụ thật |
| 20 phút | Phân quyền | Chạy được `EXECUTE AS`, thấy quyền được cấp/bị từ chối, biết `REVERT` |
| 25 phút | Backup/restore | Nêu được thứ tự FULL → DIFF → LOG và phục hồi sang DB mới |
| 20 phút | Tập trình bày toàn bộ demo | Mỗi bước nói được mục đích, dòng SQL quan trọng, kết quả và giới hạn |

## 2. Rubric yêu cầu chứng minh điều gì?

| Tiêu chí | Trọng số ở bảng tổng | Nội dung cần trình bày trong HomeFix |
|---|---:|---|
| Phân tích, thiết kế CSDL | 10% | Quan hệ, PK/FK, kiểu dữ liệu, chuẩn hóa và lý do lưu dữ liệu lịch sử |
| Constraint, trigger, view, index | 15% | Không chỉ đếm số lượng: nhập sai phải bị chặn; trigger xử lý nhiều dòng; index phù hợp truy vấn |
| SP, function, xử lý lỗi | 20% | Tham số, kiểm tra đầu vào, `TRY/CATCH`, `THROW`, hàm được tái sử dụng |
| Transaction và bảo mật | 15% | Rollback thật khi lỗi; chống duyệt lặp; chứng minh quyền cho phép và từ chối |
| Ứng dụng kết nối SQL Server | 15% | Website thật gọi SQL; tham số hóa, connection pool, xử lý ngoại lệ |
| Giao diện | 5% | Luồng rõ, thông báo lỗi, thao tác được theo vai trò |
| Báo cáo và tài liệu | 10% | Nội dung khớp sản phẩm, có bằng chứng kiểm thử, hướng dẫn tái hiện |
| Thuyết trình, vấn đáp, nhóm | 10% | Giải thích được quyết định và phần việc thực tế của mỗi người |

**Rubric có một chỗ lệch:** bảng tổng ghi tiêu chí lập trình CSDL **20%**, phần mô tả riêng ghi **15%**. Tổng bảng đầu là 100%. Tài liệu ôn theo đầy đủ nội dung, không tự sửa rubric hoặc tự khẳng định cách cô sẽ tính điểm.

Backup/recovery không có một dòng trọng số riêng trong rubric này, nhưng là phần kỹ thuật của dự án cần trình bày và thực hành được. Số lượng đối tượng chỉ là bằng chứng triển khai, không bảo đảm mức điểm. Muốn giải thích tốt, với mỗi đối tượng hãy trả lời bốn câu: **dùng để làm gì — chạy khi nào — dữ liệu sai thì sao — có giới hạn gì**.

## 3. Trạng thái dự án và database trên máy

### 3.1. GitHub

Repository: [bndt0103/DBMS_HomeFix](https://github.com/bndt0103/DBMS_HomeFix).

Nhánh đang làm việc: **`cap-nhat-homefix-20261008`**. Sau `fetch`, HEAD cũ trên máy và nhánh từ xa đều là `a79dff9`; nhánh này đã chứa toàn bộ lịch sử `origin/main`. Không có commit mới từ xa cần pull. Các thay đổi chưa commit được kiểm thử, ghi thành [commit 931189a](https://github.com/bndt0103/DBMS_HomeFix/commit/931189a) và đã push. Nhánh `main` không được tự ý thay thế.

Ngày 21/10 đã chạy lại: kiểm tra định dạng đạt; các bản SQL đồng bộ; **108 ca API/SQL đạt (36 + 72), 92 lượt màn hình đạt, 17 bước nghiệp vụ UI đạt**. Có kiểm thử cài bộ tổng/module, backup/restore và ghi nhận backend gọi 6 SP bằng Extended Events. Đây là kết quả trên môi trường kiểm thử riêng, không phải kiểm thử tải hay kiểm toán bảo mật độc lập.

### 3.2. Kết quả kiểm tra SQL Server thật

| Thành phần | Kết quả |
|---|---|
| Instance kiểm tra | `MSI\SQLEXPRESS`, kết nối được bằng `.\SQLEXPRESS` |
| Phiên bản | Express Edition 17.0.1000.7 |
| Database ứng dụng | `HomeFix_DBMS_Nhom08_TiengViet`, ONLINE, recovery SIMPLE khi kiểm tra |
| Bảng | 30 |
| SP nghiệp vụ | 7 = 2 SP tra cứu + 5 SP có transaction |
| Hàm | 5 = 1 scalar + 4 inline table-valued |
| View / trigger | 6 / 8 |
| CHECK / FK / DEFAULT | 52 / 65 / 59 |
| Index | 63 tổng: 30 của PK và 33 ngoài PK; 20 lệnh CREATE INDEX tường minh |
| Phân quyền | 7 database role và 7 user WITHOUT LOGIN |
| Dữ liệu ứng dụng lúc kiểm tra | 9 người dùng, 0 đơn hàng, 2 giao dịch ví |
| Database ôn tập đã tạo | `HomeFix_VanDap_20261022` |
| Database phục hồi thử đã tạo | `HomeFix_VanDap_20261022_Restore` |

Database ôn tập được cài từ cùng bộ module. Các bài nhập sai và transaction đều rollback. Bài backup tạo thêm một khóa cấu hình để chứng minh bản log phục hồi được thay đổi phát sinh **sau bản DIFF**. Do đó DB ôn tập không thay đổi dữ liệu DB ứng dụng. Không có đơn trong DB ứng dụng không đồng nghĩa ứng dụng hỏng: nhiều view doanh thu/đơn hàng sẽ trả tập rỗng nếu chưa thực hiện nghiệp vụ.

### 3.3. “Đã chia file trên SQL chưa?”

**Trong mã nguồn: đã chia riêng 11 file `00_schema` đến `10_backup_recovery`. Trong SQL Server: các đối tượng nằm trong một database, không chia database theo tên file `.sql`.** File SQL là tập lệnh tạo hoặc sử dụng đối tượng.

Trong Object Explorer của SSMS:

- `Databases → HomeFix_VanDap_20261022 → Tables`: các bảng.
- `Views`: các view.
- `Programmability → Stored Procedures`: các SP.
- `Programmability → Functions`: hàm scalar và table-valued.
- `Tables → dbo.GiaoDichVi → Triggers`: trigger sổ ví.
- `Tables → một bảng → Keys / Constraints / Indexes`: khóa, ràng buộc và index.
- `Security → Users`, `Security → Roles → Database Roles`: user và role trong database.

File vật lý `.mdf` chứa dữ liệu/cấu trúc; `.ldf` chứa transaction log. File `.bak`/`.trn` là bản sao lưu. `.sql` không phải tệp lưu dữ liệu đang hoạt động của SQL Server. Xem đường dẫn vật lý bằng:

```sql
USE HomeFix_VanDap_20261022;
SELECT name, type_desc, physical_name FROM sys.database_files;
```

### 3.4. Mở file nào khi cô hỏi?

| File | Nội dung chính | Hành động an toàn khi vấn đáp |
|---|---|---|
| [00_schema](modules/00_schema.sql) | Bảng, PK/FK/UNIQUE/CHECK/DEFAULT, ALTER nâng cấp | Đọc định nghĩa; không chạy lại toàn bộ trên DB đã có |
| [01_index](modules/01_index.sql) | Index tìm kiếm và unique filtered index | Chỉ ra cột khóa, bộ lọc và INCLUDE |
| [02_function](modules/02_function.sql) | 5 hàm | Gọi bằng SELECT |
| [03_view](modules/03_view.sql) | 6 view | SELECT, giải thích JOIN và tổng hợp |
| [04_sp](modules/04_sp.sql) | 2 SP tra cứu | EXEC với tham số |
| [05_transaction](modules/05_transaction.sql) | 5 SP ghi dữ liệu | Dùng script demo gọi SP; không chỉ chạy CREATE OR ALTER rồi nói đã thực hiện nghiệp vụ |
| [06_trigger](modules/06_trigger.sql) | 8 trigger | INSERT/UPDATE/DELETE đúng bảng để kích hoạt |
| [07_security](modules/07_security.sql) | Role/user, GRANT/DENY/REVOKE | Dùng demo giả lập user |
| [08_seed](modules/08_seed.sql) | Dữ liệu mẫu | Đọc; không dùng để reset DB đang làm việc |
| [09_data_migration](modules/09_data_migration.sql) | Đồng bộ/dọn dữ liệu của phiên bản | Không bấm chạy tùy tiện khi cô hỏi |
| [10_backup_recovery](modules/10_backup_recovery.sql) | SP sao lưu và chuỗi phục hồi | Chọn đúng DB, hiểu recovery model và đích restore trước khi F5 |

Nguồn chuẩn để sửa là `SRC/database`. Các bản `SQL/modules` và `SQL/CSDL_HomeFix.sql` được sinh bằng `npm.cmd run sql:build`, kiểm tra bằng `npm.cmd run sql:check`. Module 00 còn chứa các đoạn nâng cấp: ví dụ CHECK cũ của thanh toán chỉ cho COD, nhưng đoạn ALTER phía sau mở rộng thành COD/BANK. Phải đọc **định nghĩa cuối trong database**, không dừng ở lần CREATE đầu. Phụ lục đi theo trạng thái cuối đã xác minh.

## 4. Hiểu nghiệp vụ và thiết kế trước khi đọc SQL

### 4.1. Bài toán trong một phút

> Em xây dựng HomeFix để quản lý dịch vụ sửa chữa tại nhà. Khách đặt dịch vụ; điều phối lập báo giá và giao kỹ thuật viên sau khi khách duyệt; kỹ thuật viên xử lý và lập nghiệm thu; khách xác nhận; hệ thống ghi thanh toán và kế toán đối soát. SQL Server bảo vệ dữ liệu bằng khóa và ràng buộc, trigger, thủ tục có giao dịch và phân quyền. Ứng dụng web kết nối SQL Server qua backend Node.js.

Vai trò: KH = khách hàng; KTV = kỹ thuật viên; DPV = điều phối; CSKH = chăm sóc khách hàng; KT = kế toán; ADMIN = quản trị; GD = giám đốc.

Luồng chính:

`Đặt đơn → Báo giá sơ bộ → Khách duyệt → Phân công → Thợ nhận → Di chuyển → Đến nơi → Xử lý → Nghiệm thu → Thanh toán → Đối soát`.

Vật tư là luồng đề xuất/duyệt trong quá trình xử lý. Khách có thể đánh giá sau khi đủ điều kiện; phiếu hỗ trợ quản lý khiếu nại/bảo hành. Chữ ký KTV và chữ ký KH là hai dữ liệu riêng. COD là tiền mặt thợ đã thu; BANK là tiền chuyển vào tài khoản HomeFix và phải được xác minh.

### 4.2. Các quan hệ cần tự vẽ được

| Quan hệ | Cách hiện thực | Ý nghĩa |
|---|---|---|
| NguoiDung → DonHang | `DonHang.KhachHangId` FK | Một KH có nhiều đơn; một đơn có một KH |
| NguoiDung → KyThuatVien | `KyThuatVien.Id` vừa PK vừa FK | Một người có tối đa một hồ sơ KTV; không phải mọi người dùng đều là KTV |
| DichVu → DonHang | `DonHang.DichVuId` FK | Nhiều đơn cùng sử dụng một dịch vụ |
| DonHang → BaoGiaSoBo | FK + UNIQUE DonHangId | Một đơn có tối đa một báo giá sơ bộ |
| DonHang → LenhDieuPhoi | FK, unique filtered index cho dòng đang hoạt động | Có lịch sử giao lại nhưng chỉ một phân công hoạt động |
| DonHang → DeXuatVatTu | FK + UNIQUE(DonHangId,LanSuaDoi) | Giữ các lần sửa, không trùng số lần sửa trong cùng đơn |
| DeXuatVatTu → ChiTietDeXuatVatTu | `BaoGiaId` FK | Một đề xuất có nhiều dòng vật tư; tên cột còn mang nghĩa báo giá |
| DonHang → PhieuNghiemThu | FK + unique theo lần sửa và trạng thái | Có lịch sử nghiệm thu, tối đa một bản chờ và một bản đã duyệt |
| DonHang/PhieuNghiemThu → ThanhToan | Hai FK và UNIQUE tương ứng | Một đơn và một nghiệm thu không bị ghi tiền hai lần |
| ThanhToan → DoiSoat | FK + UNIQUE ThanhToanId | Một khoản thanh toán có tối đa một đối soát |
| KyThuatVien → GiaoDichVi | FK | Một KTV có nhiều giao dịch làm tăng/giảm ví |
| YeuCauHoTro → LichSuHoTro | FK | Một phiếu có nhiều lần xử lý |

**Một-một trong bảng con thường là “tối đa một”**: FK + UNIQUE không buộc mọi bản ghi cha phải có ngay một bản ghi con. Một đơn mới chưa có thanh toán là hợp lệ.

### 4.3. Chuẩn hóa và dữ liệu lưu lặp có chủ đích

- 1NF: mỗi cột chứa giá trị của một thuộc tính; các dòng vật tư tách sang bảng chi tiết.
- 2NF: với khóa ghép, thuộc tính không khóa phải phụ thuộc toàn bộ khóa; ví dụ khóa chống lặp gồm người gọi + đường dẫn + khóa yêu cầu.
- 3NF: tránh lưu thuộc tính phụ thuộc bắc cầu không cần thiết; thông tin danh mục/tài khoản tách thành bảng riêng.
- `DonHang.TenDichVu`, thông tin liên hệ, phí hủy tại thời điểm đặt và thông tin tài khoản nhận tiền là **ảnh chụp nghiệp vụ tại thời điểm phát sinh**. Sửa danh mục hôm nay không được tự đổi chứng từ lịch sử.
- `KyThuatVien.SoDu` là số tổng hợp lưu sẵn để tra cứu nhanh, trong khi `GiaoDichVi` là sổ giao dịch. Trigger duy trì số dư; view đối chiếu phát hiện sai lệch. Đây là đánh đổi giữa tốc độ đọc và nhu cầu giữ đồng bộ, không nên nói thiết kế hoàn toàn không có dư thừa.

### 4.4. Đọc các kiểu dữ liệu thường gặp

`INT`: mã/số nguyên. `IDENTITY`: SQL Server tự sinh giá trị, vẫn cần PK/UNIQUE để bảo đảm duy nhất. Sau rollback, ID có thể bị nhảy; không phải mất dữ liệu.

`NVARCHAR` và chuỗi `N'...'`: nội dung tiếng Việt. `VARCHAR`: các mã quy ước như vai trò/trạng thái. Tên bảng/cột đã Việt hóa không đồng nghĩa mọi giá trị enum đều là tiếng Việt: `Approved`, `Pending`, `Deposit` vẫn là mã dùng chung với ứng dụng.

`DECIMAL(18,2)`: tổng 18 chữ số, 2 số sau dấu thập phân, dùng cho tiền để tránh tính gần đúng của FLOAT. `BIT`: cờ 0/1. `DATETIME2`: thời điểm; dự án lưu UTC bằng `SYSUTCDATETIME()`, có chỗ đổi +7 giờ để thống kê ngày Việt Nam.

`ROWVERSION`: 8 byte tự thay đổi khi dòng được cập nhật, **không phải ngày giờ**. Dùng để biết dữ liệu người dùng đang nhìn đã cũ chưa. Giá trị không liên tục cũng bình thường.

`NULL`: chưa có/không áp dụng, không đồng nghĩa 0 hay chuỗi rỗng. So sánh dùng `IS NULL`, không dùng `= NULL`.

## 5. Ràng buộc toàn vẹn — giải thích bằng dữ liệu sai

### 5.1. Sáu khái niệm phải phân biệt

| Thành phần | Tác dụng | Ví dụ HomeFix | Không bảo đảm điều gì? |
|---|---|---|---|
| PRIMARY KEY | Nhận diện dòng, duy nhất và không NULL | `NguoiDung.Id` | Không kiểm tra vai trò KH |
| FOREIGN KEY | Giá trị phải tham chiếu bản ghi cha tồn tại | `DonHang.KhachHangId` | Người đó tồn tại chưa chắc là KH |
| UNIQUE | Không trùng khóa nghiệp vụ | Số điện thoại; mỗi đơn một thanh toán | Không kiểm tra tiền khớp nghiệm thu |
| CHECK | Biểu thức trên dòng không được FALSE | Tiền công ≥ 0, điểm 1–5 | Không kiểm tra một quá trình chuyển trạng thái |
| NOT NULL | Bắt buộc có giá trị | Địa chỉ đơn hàng | Chuỗi rỗng vẫn khác NULL |
| DEFAULT | Giá trị dùng khi bỏ qua cột lúc INSERT | Trạng thái ban đầu, thời gian UTC | Không chặn người gọi truyền giá trị khác |

CHECK với dữ liệu NULL có thể cho kết quả UNKNOWN và không bị từ chối; vì vậy cột bắt buộc phải phối hợp `NOT NULL`. Ví dụ kinh độ/vĩ độ KTV cho NULL để thể hiện chưa có vị trí, nhưng khi có giá trị phải trong miền hợp lệ. CHECK tỷ lệ 0–100 không có nghĩa bắt buộc tỷ lệ phải 15%.

FK mặc định không tự xóa dây chuyền. Phụ lục ghi từng quan hệ và hành vi ON DELETE; không xóa khách/đơn có dữ liệu phụ thuộc để “dọn nhanh” lúc demo. Khóa hoặc vô hiệu hóa người dùng là khác xóa dữ liệu lịch sử.

### 5.2. Các nhóm ràng buộc quan trọng

- **Danh tính:** số điện thoại UNIQUE; email và CCCD dùng unique index có điều kiện `IS NOT NULL`, cho phép nhiều người chưa cung cấp nhưng không trùng giá trị đã cung cấp.
- **Tiền:** phí kiểm tra/tiền công/tiền thanh toán không âm; yêu cầu ví phải > 0; giao dịch ví phải khác 0 và có thể âm để thể hiện rút/hoa hồng; số dư KTV ≥ 0.
- **Vật tư:** số lượng > 0 và ≤ 999,99; đơn giá 0–100.000.000; bảo hành 0–60 tháng. `ThanhTien = ROUND(SoLuong * DonGia, 2)` là cột tính toán PERSISTED.
- **Trạng thái:** CHECK chỉ giới hạn tập mã hợp lệ. Từ `ChoTiepNhan` nhảy thẳng `HoanThanh` đều là hai mã hợp lệ nhưng sai quy trình; SP chuyển trạng thái mới là nơi kiểm tra cạnh chuyển.
- **Chống ghi lặp:** UNIQUE `(LoaiThamChieu, ThamChieuId)` trong sổ ví; UNIQUE đơn/nghiệm thu trong thanh toán; PK ghép bảng chống lặp; các filtered index của phân công, nghiệm thu, chuyển khoản.
- **Tệp:** kích thước > 0 và ≤ 5.242.880 byte, mục đích nằm trong danh sách cho phép; FK nối tệp với người sở hữu/đơn/nghiệm thu. SQL không tự đọc nội dung tệp để kiểm MIME hoặc kiểm quyền xem ảnh; backend còn phải xử lý.
- **Tọa độ:** vĩ độ −90…90, kinh độ −180…180; vị trí KH còn có miền độ chính xác 0…100.000 m.
- **JSON:** `ISJSON(KetQuaJSON)=1` bảo đảm cú pháp JSON của kết quả chống lặp, không xác nhận mọi trường bên trong đúng nghiệp vụ.

### 5.3. Chạy demo ràng buộc

Mở [02_RangBuoc_VaLoi.sql](demo_van_dap/02_RangBuoc_VaLoi.sql). Chạy phần khai báo đầu file rồi chọn trọn từng khối `BEGIN TRY ... END CATCH` đến `GO`, nhấn F5.

| Thử gì? | Kết quả cần thấy | Cách giải thích |
|---|---|---|
| TienCong = −1 | 547, thông báo CHECK | SQL Server bảo vệ miền giá trị dù ghi trực tiếp ngoài website |
| Ten = NULL | 515 | Cột bắt buộc, khác với kiểm tra chuỗi trắng của ứng dụng |
| Trùng số điện thoại | 2627 | UNIQUE giữ tính duy nhất |
| DichVuId không tồn tại | 547, thông báo FK | Đơn không thể tham chiếu dịch vụ không có |
| Dùng người vai trò KT làm KH | 51009, CUSTOMER_ROLE_REQUIRED | FK đã thỏa vì người đó tồn tại; trigger kiểm tra nghiệp vụ liên bảng |

Các lỗi đã được bắt và SELECT ra `LoiDuKien`, nên thấy bảng kết quả thay vì lỗi đỏ vẫn là đúng. Nếu bài sai không bị chặn, script chủ động ném lỗi `DEMO_FAIL`. Những demo này không lưu dữ liệu thử vì rollback.

## 6. Trigger — SQL tự chạy lúc nào và làm gì?

### 6.1. Ba điều cốt lõi

Trigger DML tự chạy khi có INSERT/UPDATE/DELETE trên bảng đã gắn, không gọi bằng EXEC như SP. Trigger chạy trong cùng giao dịch với lệnh gây ra nó. `AFTER` chạy sau thao tác và kiểm tra ràng buộc; nếu trigger ném lỗi, không được kết luận dữ liệu đã lưu thành công.

`inserted` và `deleted` là **hai bảng logic**, không phải hai biến một dòng:

| Lệnh | inserted | deleted |
|---|---|---|
| INSERT | Dòng mới | Rỗng |
| DELETE | Rỗng | Dòng cũ |
| UPDATE | Giá trị sau sửa | Giá trị trước sửa |

Một lệnh có thể tác động nhiều dòng. Thiết kế phải theo tập dữ liệu; không chọn tùy ý một `@Id` từ `inserted` rồi bỏ qua các dòng còn lại. Xem [hướng dẫn trigger nhiều dòng của Microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/triggers/create-dml-triggers-to-handle-multiple-rows-of-data).

### 6.2. Giải thích đủ tám trigger

| Trigger | Bảng/sự kiện | Dòng quan trọng và kết quả |
|---|---|---|
| `trg_Vi_GhiSo` | GiaoDichVi, AFTER INSERT | GROUP BY KTV, SUM tiền mới, JOIN KTV rồi cộng SoDu; hỗ trợ nhiều dòng |
| `trg_Vi_BatBien` | GiaoDichVi, INSTEAD OF UPDATE/DELETE | Thay việc sửa/xóa bằng THROW `LEDGER_IMMUTABLE` |
| `trg_ThanhToan_BatBien` | ThanhToan, INSTEAD OF UPDATE/DELETE | Ngăn sửa/xóa khoản đã ghi bằng `PAYMENT_IMMUTABLE` |
| `trg_DonHang_GhiNhatKy` | DonHang, AFTER UPDATE | JOIN inserted/deleted theo Id; chỉ ghi NhatKy nếu trạng thái thực sự khác |
| `trg_DanhGia_DieuKien` | DanhGia, AFTER INSERT/UPDATE | Đúng chủ đơn, đơn hoàn thành, có thanh toán và KTV đúng nghiệm thu; sai → REVIEW_NOT_ELIGIBLE |
| `trg_DeXuatChinhSach_ThongBaoGiamDoc` | DeXuatChinhSach, AFTER INSERT | CROSS JOIN từng đề xuất với các GD đang hoạt động để tạo ThongBao |
| `trg_DonHang_KhachHang` | DonHang, AFTER INSERT/UPDATE | KhachHangId phải là NguoiDung có VaiTro KH; sai → CUSTOMER_ROLE_REQUIRED |
| `trg_ThanhToan_NghiemThu` | ThanhToan, AFTER INSERT | Nghiệm thu thuộc đúng đơn, đã Approved, tiền khớp tổng; COD phải đúng thợ thu; sai → PAYMENT_ACCEPTANCE_MISMATCH |

Trigger kiểm tra điều kiện dùng `IF EXISTS`: chỉ cần **một dòng vi phạm** là lệnh bị từ chối. FK bảo đảm các dòng cha bắt buộc tồn tại, trigger kiểm tra thêm nội dung nghiệp vụ. Không tự khẳng định thứ tự giữa hai AFTER trigger cùng sự kiện nếu dự án không thiết lập thứ tự.

Trigger thông báo không gửi email: nó chỉ INSERT các dòng vào bảng `ThongBao`. Trigger nhật ký đơn ghi `NhatKy`; `LichSuDonHang` có người thực hiện/lý do được SP ghi riêng, nên hai bảng không hoàn toàn trùng mục đích.

Chạy thêm [09_Trigger_ThanhToan_DanhGia_ThongBao.sql](demo_van_dap/09_Trigger_ThanhToan_DanhGia_ThongBao.sql): tiền thanh toán sai → PAYMENT_ACCEPTANCE_MISMATCH; sửa khoản đã ghi → PAYMENT_IMMUTABLE; đánh giá chưa đủ điều kiện → REVIEW_NOT_ELIGIBLE; đề xuất mới → số thông báo bằng số GD hoạt động. Các bản ghi nghiệm thu trong file là **dữ liệu tổng hợp để kiểm riêng trigger**, không đại diện quy trình duyệt/chữ ký đầy đủ của website; mọi thay đổi được rollback.

### 6.3. Đọc từng dòng của trigger ví

```sql
WITH ChenhLechVi AS (
    SELECT KyThuatVienId, SUM(SoTien) AS SoTien
    FROM inserted
    GROUP BY KyThuatVienId
)
UPDATE k
SET SoDu = k.SoDu + d.SoTien
FROM dbo.KyThuatVien AS k
JOIN ChenhLechVi AS d ON d.KyThuatVienId = k.Id;
```

1. `WITH` tạo CTE: kết quả tạm dùng ngay cho câu UPDATE tiếp theo, không tạo bảng vật lý.
2. `inserted` chỉ chứa các giao dịch vừa thêm trong lệnh này, không phải toàn bộ sổ ví.
3. `SUM` cộng tiền của từng KTV; ví dụ hai dòng +10.000 và +20.000 thành +30.000.
4. JOIN ghép tổng đó với đúng KTV; UPDATE cộng vào số dư cũ.
5. Nếu một số dư sau cộng bị âm, CHECK trên KyThuatVien chặn; lệnh ghi sổ cũng không được hoàn tất.

Mở [04_Trigger_Vi.sql](demo_van_dap/04_Trigger_Vi.sql). Phần A phải tăng đúng **30.000** trong transaction, `ChenhLech=0`; cuối cùng rollback. Phần B cố rút quá số dư phải lỗi 547 và `GiaoDichSaiConLai=0`. Phần C sửa ghi chú sổ ví phải bị `LEDGER_IMMUTABLE`.

> Em không cập nhật số dư bằng cách lấy riêng một dòng inserted. Em tổng hợp toàn bộ tập theo KTV. Sổ giao dịch là dữ liệu gốc, số dư được trigger cập nhật; view giúp đối chiếu hai nguồn.

**Giới hạn cần hiểu:** người có quyền quản trị SQL cao vẫn có thể vô hiệu hóa trigger hoặc sửa trực tiếp SoDu. Quyền SQL phải giới hạn đúng; không gọi đây là sổ “không thể sửa trong mọi hoàn cảnh”. Muốn điều chỉnh hợp lệ thì thiết kế giao dịch bù và kiểm soát quyền, không sửa/xóa dòng cũ.

## 7. Stored procedure — hiểu bảy thủ tục

SP là một chương trình đặt tên trong database, nhận tham số và chạy bằng `EXEC`. File `CREATE OR ALTER PROCEDURE` chỉ cài định nghĩa; muốn chứng minh nghiệp vụ phải gọi SP và kiểm tra dữ liệu.

### 7.1. Hai SP tra cứu

- **sp_DonHangCuaKhach(@KhachHangId):** lấy đơn của KH, LEFT JOIN ThanhToan để gắn Paid/Unpaid, sắp theo Id giảm dần. Tên KH phải truyền qua tham số; không nối trực tiếp chuỗi người dùng vào SQL. SP này không tự chứng minh người gọi là chủ của Id được truyền; website phải kiểm soát danh tính.
- **sp_BaoCaoTongHop(@TuNgay,@DenNgay):** chặn NULL hoặc `TuNgay >= DenNgay`, gọi `fn_ThongKeDon`, sắp theo nhóm dịch vụ. Khoảng `[TuNgay, DenNgay)` gồm đầu nhưng loại cuối để ghép các khoảng liên tiếp không đếm trùng.

### 7.2. sp_TaoDonHang — ưu tiên học kỹ nhất

Đầu vào: `@KhachHangId`, `@DichVuId`, `@DiaChi`, `@MoTa`, `@NgayHen` (mặc định NULL).

Thứ tự đọc:

1. `SET NOCOUNT ON`: giảm thông báo “n rows affected”, không có nghĩa bỏ kết quả SELECT.
2. `SET XACT_ABORT ON`: hỗ trợ hủy giao dịch khi gặp lỗi thực thi; vẫn phải đọc TRY/CATCH và XACT_STATE.
3. Kiểm tra có giao dịch bên ngoài chưa; tự BEGIN hoặc tạo SAVEPOINT.
4. Kiểm tra KH tồn tại, đang hoạt động và đúng vai trò.
5. Kiểm tra độ dài địa chỉ/mô tả; nếu có lịch hẹn, kiểm tra từ hiện tại +30 phút đến +30 ngày, giờ địa phương 8–17 và phần giây bằng 0.
6. Kiểm tra dịch vụ hoạt động, dùng khóa cập nhật/giữ khóa khi đọc.
7. INSERT DonHang bằng SELECT từ người dùng và dịch vụ; chụp tên dịch vụ, liên hệ, phí hủy cấu hình.
8. `SCOPE_IDENTITY()` lấy Id đơn vừa tạo trong cùng scope, tránh lấy nhầm Id từ bảng do trigger chèn.
9. INSERT LichSuDonHang; SELECT đơn để trả về; chỉ tự COMMIT nếu chính SP đã mở transaction.
10. Nếu lỗi, rollback phù hợp rồi `THROW` lại.

Hai thao tác thêm đơn + thêm lịch sử phải cùng thành công. Thiếu lịch sử sau khi tạo đơn là trạng thái dở dang mà transaction cần ngăn chặn. `sp_TaoDonHang` tự nó không nhận idempotency key; cơ chế chống gửi lặp nằm ở backend và bảng `ChongLapYeuCau`.

**Lưu ý đầu vào:** điều kiện `LEN(NULL)` không ra số; SQL còn có NOT NULL ở cột đích và backend validation. Không nói mọi trường hợp NULL đều được SP trả về cùng mã lỗi nghiệp vụ.

### 7.3. sp_ChuyenTrangThaiDon

Đầu vào: Id đơn, Id người thực hiện, phiên bản dự kiến BINARY(8), trạng thái tiếp theo, lý do.

Đọc dòng đơn bằng `UPDLOCK,HOLDLOCK`; thiếu đơn → ORDER_NOT_FOUND; phiên bản khác → VERSION_CONFLICT. Danh sách OR trong IF là các bước được phép, ví dụ:

`ChoTiepNhan → ChoDuyetSoBo → ChoPhanCong → ChoNhan → DaTiepNhan → DangDiChuyen → DaDenNoi → DangXuLy → ChoNghiemThu → HoanThanh`.

Có nhánh hủy ở các trạng thái được liệt kê, trả về chờ phân công khi thợ từ chối, hoặc nghiệm thu bị trả về xử lý. Không được suy ra từ một mũi tên rằng mọi nhánh khác đều cấm; hãy chỉ vào danh sách thực tế.

UPDATE đơn làm trigger ghi NhatKy; SP đồng thời INSERT LichSuDonHang. `@PhienBanDuKien` NULL hiện bỏ qua kiểm tra phiên bản trong SP này; backend chịu trách nhiệm truyền đúng thông tin và quyền thao tác. Chính SP không có đầy đủ kiểm tra vai trò của từng người thực hiện cho từng bước. Đây là lý do không cấp EXECUTE rộng rãi cho người dùng không tin cậy.

### 7.4. sp_DoiSoatCOD

Đầu vào: Id đối soát, Id KT, phiên bản dự kiến. Tuy tên có COD, code xử lý **cả COD và BANK**.

Đọc/khóa đối soát và thanh toán; phải Pending, phiên bản khớp, người xử lý là KT hoạt động. COD: thợ đã nhận tiền mặt, hệ thống trừ hoa hồng khỏi ví và phải đủ số dư. BANK: HomeFix đã nhận tiền, cộng phần thuộc KTV bằng `Tổng thanh toán − Hoa hồng`. Ghi GiaoDichVi kích hoạt trigger ví; sau đó đánh dấu đối soát Confirmed và ghi nhật ký trong cùng transaction.

Ví dụ tiền công 200.000, tỷ lệ 15%, vật tư 100.000, phí kiểm tra 50.000: khách trả 350.000; hoa hồng 30.000. COD trừ ví 30.000; BANK cộng ví 320.000. Không lấy 15% của toàn bộ 350.000 vì công thức hoa hồng dùng **tiền công**. Hoa hồng cũng không phải lợi nhuận ròng đã trừ mọi chi phí.

### 7.5. sp_DuyetYeuCauVi

Đầu vào: Id yêu cầu, người KT duyệt, quyết định Approved/Rejected, phiên bản dự kiến, lý do.

Kiểm quyền KT; quyết định hợp lệ; từ chối phải có lý do. Khóa ví trước rồi khóa yêu cầu, tránh các luồng khóa ngược thứ tự gây tăng nguy cơ deadlock. Yêu cầu phải còn Pending và phiên bản khớp. Rút tiền cần đủ số dư dành cho các yêu cầu đang chờ và không có phân công hoạt động. Khi duyệt, nạp tạo giao dịch dương, rút tạo giao dịch âm. Sau đó cập nhật yêu cầu và nhật ký. Rejected không tạo giao dịch tiền.

Mở [07_DuyetVi_DongThoi.sql](demo_van_dap/07_DuyetVi_DongThoi.sql): lần đầu ví tăng 50.000; lần thứ hai dùng phiên bản cũ bị VERSION_CONFLICT; rollback giao dịch bao ngoài trả số dư về ban đầu. Đây là demo **duyệt lặp trên một session**, không giả gọi là hai session chạy đồng thời. Kiểm thử hai kết nối thật nằm trong `SRC/tests/dbms.test.js` và đã chạy đạt.

### 7.6. sp_XuLyHoTro

Đầu vào: Id phiếu, Id CSKH, trạng thái mới, kết quả xử lý, phiên bản dự kiến. Kiểm CSKH đang hoạt động; trạng thái InProgress/Resolved/Rejected; nội dung đủ độ dài; phiếu còn Open/InProgress và phiên bản khớp. Cập nhật phiếu + thêm LichSuHoTro + NhatKy trong một transaction. Khi một thao tác lỗi, không được chỉ lưu phần cập nhật trạng thái mà mất lịch sử.

Chạy [10_ThuTuc_DoiSoat_HoTro.sql](demo_van_dap/10_ThuTuc_DoiSoat_HoTro.sql) để thực hành hai SP cuối: đối soát COD chuyển Confirmed và trừ ví **30.000**; hỗ trợ chuyển InProgress và có lịch sử tương ứng. File tự chuẩn bị dữ liệu tổng hợp trong transaction, sau đó rollback toàn bộ.

## 8. Transaction, xử lý lỗi và đồng thời

### 8.1. ACID theo ví dụ HomeFix

- **Atomicity — nguyên tử:** đơn và lịch sử cùng thành công hoặc cùng hủy.
- **Consistency — nhất quán:** trước/sau giao dịch vẫn thỏa ràng buộc, ví không âm, thanh toán khớp nghiệm thu.
- **Isolation — cô lập:** hai người duyệt cùng yêu cầu không cùng ghi tiền; khóa, trạng thái và phiên bản cùng tham gia bảo vệ.
- **Durability — bền vững:** giao dịch đã commit được SQL Server ghi nhận qua cơ chế lưu trữ/log. Backup là phương án phục hồi khi mất/hỏng dữ liệu, không đồng nhất với COMMIT.

`BEGIN TRANSACTION`: bắt đầu; `COMMIT`: chấp nhận; `ROLLBACK`: hủy các thay đổi chưa chốt. `SAVE TRANSACTION`: đặt điểm lưu trong transaction hiện có, không tạo một giao dịch độc lập đã commit riêng.

### 8.2. Vì sao SP có @TuMoGiaoDich?

Nếu gọi trực tiếp từ SSMS, SP có thể tự BEGIN/COMMIT. Nếu backend đã mở giao dịch chứa nhiều thao tác, SP dùng savepoint và nhường COMMIT cuối cho backend. `@@TRANCOUNT` cho biết mức transaction, không cho biết nó có còn commit được hay không.

| XACT_STATE() | Ý nghĩa | Xử lý |
|---:|---|---|
| 0 | Không có transaction đang hoạt động | Không rollback một transaction không còn |
| 1 | Có transaction và còn commit được | Có thể rollback toàn bộ hoặc về savepoint phù hợp |
| −1 | Transaction không thể commit | Phải rollback toàn bộ; không rollback về savepoint |

Trong CATCH của SP, nếu SP không tự mở và trạng thái −1, bên gọi phải rollback toàn bộ. Backend `db.js` có catch/rollback để thực hiện trách nhiệm đó. [Microsoft giải thích XACT_STATE và giao dịch không thể commit](https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql).

### 8.3. Chạy chứng minh rollback

Mở [03_ThuTuc_GiaoDich.sql](demo_van_dap/03_ThuTuc_GiaoDich.sql):

- A: tạo đơn, chuyển hợp lệ sang ChoDuyetSoBo, đọc đơn/lịch sử/nhật ký; rollback; số đơn trước và sau bằng nhau.
- B: tạo đơn rồi cố chuyển thẳng HoanThanh. Phải thấy INVALID_TRANSITION, rollback và số đơn vẫn như trước.
- C: báo cáo có ngày bắt đầu lớn hơn ngày kết thúc. Phải thấy INVALID_DATE_RANGE.

Đọc `ERROR_NUMBER()` và `ERROR_MESSAGE()` để biết lỗi kỹ thuật/nghiệp vụ. `THROW;` trong CATCH giữ lại lỗi gốc. Không catch rồi trả “thành công” hoặc bỏ qua lỗi. Các mã 51003/51004/51009 là mã tự định nghĩa của dự án, khác mã hệ thống 547/2627/515.

### 8.4. Vì sao vừa ROWVERSION vừa khóa?

ROWVERSION phát hiện khách đang thao tác trên dữ liệu cũ. Khóa điều phối truy cập trong thời gian transaction chạy. `UPDLOCK` xin khóa cập nhật khi đọc để chuẩn bị sửa; `HOLDLOCK` giữ bảo vệ theo mức SERIALIZABLE cho tham chiếu bảng đó đến hết giao dịch, có thể bao gồm khoảng khóa tùy truy vấn/index.

Ví dụ A/B cùng thấy Pending: A khóa yêu cầu, duyệt và commit; B sau khi được đọc lại thấy trạng thái/phiên bản đã đổi và bị từ chối. Unique reference trong sổ ví là lớp bảo vệ bổ sung chống ghi hai lần.

Backend còn dùng `sp_getapplock` trên tài nguyên `HomeFixCommands` để tuần tự hóa lệnh ghi ở quy mô đồ án. Cách này dễ giữ nhất quán nhưng hạn chế thông lượng, không nên giới thiệu là giải pháp tối ưu cho tải rất lớn. Không dùng NOLOCK cho bài toán tiền để cố tránh chờ khóa.

Muốn thấy khóa bằng hai cửa sổ SSMS, ở cửa sổ A chọn DB ôn tập, `BEGIN TRAN`, SELECT một dòng KyThuatVien `WITH (UPDLOCK,HOLDLOCK)`, giữ giao dịch chưa kết thúc. Ở cửa sổ B, `SET LOCK_TIMEOUT 5000`, rồi SELECT cùng dòng với `UPDLOCK,HOLDLOCK`: B sẽ chờ và có thể báo 1222 sau 5 giây. Quay lại A ROLLBACK, chạy lại B sẽ đọc được; đặt `SET LOCK_TIMEOUT -1` để trả về mặc định. Đây là bài quan sát khóa, không thay cho kiểm thử toàn bộ nghiệp vụ duyệt đồng thời. Chỉ thực hành trên DB ôn tập và luôn kết thúc giao dịch của A.

## 9. Function, view và index

### 9.1. Năm hàm

| Hàm | Loại | Đầu vào → kết quả | Cách gọi/điểm dễ hỏi |
|---|---|---|---|
| fn_HoaHong | Scalar | Tiền công, tỷ lệ → một số tiền hoặc NULL khi ngoài miền | `SELECT dbo.fn_HoaHong(200000,15)` = 30000 |
| fn_SoDuVi | Inline TVF | Id KTV → một dòng tổng số dư | `SELECT * FROM dbo.fn_SoDuVi(@KTV)`; COALESCE đổi tổng NULL thành 0 |
| fn_DiemDanhGia | Inline TVF | Id KTV → số lượt và điểm TB | Chưa có đánh giá: số lượt 0, điểm TB NULL, không tự coi điểm 0 |
| fn_HanBaoHanh | Inline TVF | Id nghiệm thu → vật tư và ngày hết hạn | Chỉ Approved, tháng bảo hành >0; DATEADD tháng trên NgayDuyet |
| fn_ThongKeDon | Inline TVF | Khoảng ngày → thống kê nhóm dịch vụ | SUM(CASE ...) đếm hoàn thành/hủy trong từng nhóm |

Scalar trả một giá trị; TVF trả tập dòng có thể JOIN/APPLY. Function dùng trong truy vấn, không dùng để thực hiện các cập nhật nghiệp vụ như SP. Không nói hàm và SP chỉ khác tên gọi.

### 9.2. Sáu view

- **vw_DonHangTongHop:** đơn + tên KH/KTV + Paid/Unpaid. INNER JOIN KH vì đơn bắt buộc có KH; LEFT JOIN KTV/thanh toán vì đơn có thể chưa được giao hoặc chưa trả tiền. UNIQUE trên ThanhToan.DonHangId giúp tránh nhân đôi đơn khi JOIN.
- **vw_DoanhThuNgay:** tổng hợp thanh toán **có đối soát liên kết**, đổi UTC sang ngày VN +7. Code hiện không lọc DoiSoat.TrangThai='Confirmed', nên không gọi mọi giá trị ở view này là “hoa hồng đã xác nhận”. Báo cáo web có truy vấn nghiệp vụ riêng; phải phân biệt.
- **vw_ViKyThuatVien:** SoDuLuuSan so với tổng sổ qua fn_SoDuVi; ChenhLech cần bằng 0.
- **vw_HieuSuatKyThuatVien:** đếm đơn/hoàn thành và điểm đánh giá từ function; CROSS APPLY áp dụng hàm cho từng KTV.
- **vw_HoTroCanXuLy:** phiếu Open/InProgress và mốc phản hồi cộng 24 giờ. Cột hạn phản hồi không tự gửi cảnh báo hoặc tự xử lý quá hạn.
- **vw_DichVuCongKhai:** chỉ dịch vụ hoạt động, thêm tổng phí kiểm tra + tiền công. Đây là truy vấn được cấp SELECT cho KH/KTV.

View thông thường lưu định nghĩa truy vấn, không phải bản dữ liệu độc lập luôn chiếm dung lượng như bảng kết quả. Cấp quyền trên view giúp giới hạn phần dữ liệu công khai, nhưng các view hiện tại không tự thực hiện row-level security theo từng KH.

### 9.3. Index: mục đích và đánh đổi

Index giống một cấu trúc tra cứu bổ sung. Đọc có thể nhanh hơn nhưng INSERT/UPDATE/DELETE phải duy trì index và tốn dung lượng. PK/UNIQUE thường có index hỗ trợ, nên đừng cộng “20 CREATE INDEX” thành toàn bộ index của DB.

Ví dụ `IX_Vi_KyThuatVien_Ngay(KyThuatVienId, NgayTao DESC) INCLUDE(SoTien,Loai,ThamChieuId)`:

1. Cột đầu phục vụ điều kiện tìm đúng KTV.
2. Cột sau phục vụ thứ tự thời gian trong KTV đó.
3. INCLUDE đặt thêm cột để truy vấn có thể lấy đủ dữ liệu ngay từ index; chúng không phải cột khóa sắp xếp và không quyết định tính duy nhất.

`UX_PhanCong_KyThuatVien WHERE DangHoatDong=1` là **unique filtered index**: một thợ có tối đa một lệnh hoạt động, vẫn lưu được nhiều lệnh lịch sử không hoạt động. Các unique filtered index khác bảo vệ đơn được phân công một lần, đề xuất đang áp dụng, nghiệm thu pending/approved, email/CCCD và chứng từ chuyển khoản.

Mở [05_Ham_View_Index.sql](demo_van_dap/05_Ham_View_Index.sql). Bật Ctrl+M trong SSMS rồi chạy phần STATISTICS. Xem **Messages → logical reads** và tab Execution Plan. Với dữ liệu ít, optimizer có thể chọn Scan; đó chưa phải index bị lỗi. Không ép INDEX để kết luận tăng tốc và không tuyên bố “nhanh hơn X lần” khi chưa đo cùng dữ liệu/truy vấn.

## 10. Bảo mật và phân quyền

### 10.1. Ba tầng khác nhau

1. **Login:** danh tính đăng nhập vào instance SQL Server.
2. **Database user/role:** danh tính và nhóm quyền trong một database. `hf_KH` là user, `HomeFix_KH` là role.
3. **Vai trò ứng dụng:** NguoiDung.VaiTro + JWT + kiểm quyền API, ví dụ KH chỉ xem đơn của chính mình.

`CREATE USER ... WITHOUT LOGIN` dùng được cho `EXECUTE AS USER` nhưng không phải tài khoản đăng nhập SSMS độc lập. 7 role/user trong bài không có nghĩa website mở 7 kết nối bằng 7 login. Backend có tài khoản kết nối riêng; một số phần báo cáo dùng ngữ cảnh quyền SQL, nhiều thao tác vẫn kiểm quyền tại API và SP.

### 10.2. Quyền hiện có

| Role | Quyền tiêu biểu |
|---|---|
| HomeFix_KH | SELECT view dịch vụ, EXEC sp_TaoDonHang |
| HomeFix_KTV | SELECT view dịch vụ |
| HomeFix_DPV | SELECT view đơn/hiệu suất, EXEC báo cáo |
| HomeFix_CSKH | SELECT view hỗ trợ/đơn, EXEC xử lý hỗ trợ và báo cáo |
| HomeFix_KT | SELECT view ví/doanh thu, EXEC duyệt ví/đối soát/báo cáo |
| HomeFix_GD | SELECT view doanh thu/hiệu suất, EXEC báo cáo; quyền đọc nhật ký đã REVOKE |
| HomeFix_ADMIN | SELECT 6 view, EXEC báo cáo, đọc nhật ký, CRUD danh mục dịch vụ |

Các role đều bị DENY đọc cột MatKhauBam và DENY UPDATE/DELETE GiaoDichVi. ADMIN của ứng dụng không được đồng nhất với `sysadmin`/`db_owner` của SQL Server.

`GRANT`: cấp quyền. `DENY`: từ chối tường minh. `REVOKE`: gỡ thiết lập quyền ở phạm vi đó, không bảo đảm chặn quyền được kế thừa từ nguồn khác. Nói “DENY luôn thắng trong mọi trường hợp” là quá tuyệt đối vì SQL Server có ngoại lệ về cấp quyền cột và ngữ cảnh quản trị; bài demo kiểm chứng trực tiếp quyền thực tế của các user cụ thể.

### 10.3. Chạy quyền được phép và bị từ chối

Mở [06_PhanQuyen.sql](demo_van_dap/06_PhanQuyen.sql). `EXECUTE AS USER='hf_KH'` đổi ngữ cảnh trong phiên hiện tại. Kết quả: xem view dịch vụ được; đọc cột mật khẩu bị lỗi quyền; `HAS_PERMS_BY_NAME` với sửa sổ ví là 0. Cuối phần phải `REVERT` để quay lại danh tính cũ. Đoạn SELECT TOP(0) kiểm quyền mà không hiển thị giá trị mật khẩu.

Sau đó giả lập GD: quyền nhật ký là 0 trong cấu hình này, quyền thực thi báo cáo là 1. Người kiểm thử cần có quyền IMPERSONATE tương ứng. Nếu quên REVERT, các lệnh quản trị tiếp theo có thể báo thiếu quyền; chạy `SELECT USER_NAME()` để kiểm tra.

**Giới hạn:** các SP nhận Id người thực hiện như tham số; nhiều kiểm tra quyền theo bản ghi người dùng chưa gắn trực tiếp danh tính database user với chính Id đó. Không cấp truy cập SP trực tiếp cho người dùng tùy ý rồi cho rằng đã có bảo mật theo từng hàng hoàn chỉnh. Trong website, backend phải lấy Id từ phiên đã xác thực và kiểm tra quyền sở hữu/trạng thái, không tin Id do khách gửi.

## 11. Sao lưu và phục hồi ngay trong SQL

### 11.1. Phân biệt ba loại

| Loại | Nội dung | Dùng trong chuỗi nào? |
|---|---|---|
| FULL | Bản sao dữ liệu toàn database và thông tin cần cho nhất quán | Nền phục hồi |
| DIFF | Các extent thay đổi kể từ full nền gần nhất | FULL đúng nền → DIFF được chọn |
| LOG | Các bản ghi nhật ký cần cho chuỗi phục hồi | Sau FULL/DIFF, áp dụng các log cần thiết liên tục |

DIFF không chỉ chứa thay đổi từ bản DIFF trước. File đuôi `.bak` hay `.trn` là quy ước đặt tên; loại backup do câu lệnh quyết định. Chọn RECOVERY FULL không tự tạo bản full backup. Sau khi đổi từ SIMPLE sang FULL phải khởi tạo chuỗi phù hợp bằng backup dữ liệu; trong demo dùng full rồi diff/log. [Tài liệu Microsoft về backup](https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql).

`COPY_ONLY` phù hợp bản full bổ sung không muốn đổi nền differential hiện có. Không lấy một COPY_ONLY full mới làm “nền mới” rồi giả định mọi DIFF tương lai dựa trên nó.

### 11.2. Demo đã chuẩn bị, đã chạy thành công

File [08_Backup_Restore.sql](demo_van_dap/08_Backup_Restore.sql) là kịch bản học từng bước, không cần SQLCMD Mode:

1. Kiểm tra DB nguồn demo tồn tại, DB đích chưa tồn tại.
2. Lấy thư mục backup/data/log mặc định của instance và sinh tên tệp ngẫu nhiên.
3. Chỉ chuyển DB ôn tập sang FULL.
4. BACKUP DATABASE tạo FULL.
5. INSERT một khóa CauHinh có giá trị `SAU_FULL`.
6. BACKUP DATABASE WITH DIFFERENTIAL.
7. UPDATE khóa đó thành `SAU_DIFF`.
8. BACKUP LOG.
9. RESTORE VERIFYONLY từng tệp; RESTORE FILELISTONLY xem tên logic.
10. RESTORE full với MOVE và NORECOVERY; restore diff NORECOVERY; restore log RECOVERY.
11. DBCC CHECKDB; đọc khóa từ DB phục hồi, phải là **SAU_DIFF**, database phải ONLINE.

Giá trị SAU_DIFF chỉ được cập nhật **sau bản differential**, nên việc đọc lại đúng giá trị chứng minh bản log đã được áp dụng. Chỉ chạy VERIFYONLY không chứng minh điều này.

**Database `_Restore` đã được tạo khi chạy thử ngày 21/10. Trước khi demo lại, đổi duy nhất giá trị biến `@Dich` trong file 08 thành tên chưa có, ví dụ `HomeFix_VanDap_20261022_Restore_Lan2`. Không chạy DROP hoặc WITH REPLACE để giải quyết việc trùng tên.** Nếu muốn chạy lần ba, dùng tên mới. Tên tệp backup tự sinh mới, không ghi đè tệp đã kiểm thử. File 00 cũng đã chạy; không cần tạo DB ôn tập lại.

Xem trạng thái và thư mục trước demo:

```sql
SELECT name, state_desc, recovery_model_desc
FROM sys.databases WHERE name LIKE N'HomeFix_VanDap_%';

SELECT SERVERPROPERTY('InstanceDefaultBackupPath') AS ThuMucBackup;
```

### 11.3. Giải thích các từ khóa cho cô

`CHECKSUM`: hỗ trợ kiểm tra lỗi khi sao lưu/đọc backup. `VERIFYONLY`: kiểm tra bản sao có thể đọc và đầy đủ theo kiểm tra của lệnh, không thay thế restore thử. `FILELISTONLY`: liệt kê tên file logic để dùng MOVE.

`MOVE`: ánh xạ file logic trong backup sang file vật lý mới, tránh dùng chung .mdf/.ldf với nguồn. `NORECOVERY`: để DB ở RESTORING chờ bản tiếp theo; chưa truy vấn dữ liệu được. `RECOVERY`: hoàn tất chuỗi, đưa database ONLINE. `DBCC CHECKDB`: kiểm tra nhất quán cấu trúc database, không chứng minh mọi quy tắc kinh doanh là đúng. [Microsoft hướng dẫn chuỗi phục hồi đầy đủ](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/complete-database-restores-full-recovery-model).

`STOPAT`: dừng phục hồi đến thời điểm cần cứu, phải có các log phù hợp chứa mốc đó và dùng đúng mốc thời gian của hệ thống. Không chọn thời gian tùy ý ngoài chuỗi rồi mong SQL tự tìm dữ liệu. Kịch bản 08 kiểm thử phục hồi tới cuối log; **không phải kiểm thử STOPAT**. Nếu dữ liệu nguồn còn truy cập được và cần cứu phần chưa backup, xem xét tail-log backup trước phục hồi.

### 11.4. Thủ tục sao lưu của dự án

`modules/10_backup_recovery.sql` tạo **sp_SaoLuuHeThong** trong DB được chọn, nhận loại FULL/DIFF/LOG, thư mục tùy chọn và trả đường dẫn file qua OUTPUT. Nó kiểm loại sao lưu và tên DB HomeFix, sinh tên tệp duy nhất, dùng QUOTENAME cho tên DB và sp_executesql có tham số cho đường dẫn. Thủ tục này cài riêng, không tính vào 7 SP nghiệp vụ.

Muốn chạy cả file này trong SSMS: bật Query → SQLCMD Mode; sửa `TenCSDL` sang **HomeFix_VanDap_20261022**, không để tên mặc định khác; `ThucHienPhucHoi=0` chỉ backup, `1` có restore sang hậu tố `_Restore` nếu chưa tồn tại. File này còn đổi recovery sang FULL và thực hiện sao lưu ngay, không chỉ chứa CREATE PROCEDURE.

Chạy procedure riêng sau khi cài:

```sql
USE HomeFix_VanDap_20261022;
DECLARE @Tep NVARCHAR(1000);
EXEC dbo.sp_SaoLuuHeThong @LoaiSaoLuu='FULL', @TepSaoLuu=@Tep OUTPUT;
SELECT @Tep AS TepSaoLuu;
RESTORE VERIFYONLY FROM DISK=@Tep WITH CHECKSUM;
```

Nếu chưa cài SP sẽ gặp lỗi không tìm thấy; bài 08 không phụ thuộc SP này và đã được kiểm chứng riêng. Trong lúc vấn đáp nên chọn **một** kịch bản backup rõ ràng để tránh tạo nhiều chuỗi lẫn lộn.

### 11.5. Đường dẫn backup và dữ liệu ngoài database

BACKUP do **dịch vụ SQL Server** ghi file trên máy chạy SQL Server, không phải SSMS trên máy khách. Thư mục cần tồn tại và tài khoản dịch vụ phải có quyền ghi. Không cấp Everyone toàn quyền ổ đĩa để chữa lỗi. Máy hiện tại là Express; kịch bản không bắt buộc COMPRESSION hay SQL Server Agent.

Một bản `.bak` **không chứa các file ảnh vật lý trong `SRC/backend/uploads`**, mã web hoặc `.env`. Muốn chuyển cả ứng dụng sang máy khác cần SQL backup, tệp upload phù hợp, mã nguồn và cấu hình môi trường. Chỉ backup bảng TepDinhKem mới giữ metadata/khóa lưu trữ, chưa giữ nội dung ảnh.

## 12. Website gọi SQL như thế nào?

Frontend React gửi HTTP → backend Express xác thực/kiểm dữ liệu → `mssql`/`msnodesqlv8` dùng connection pool → SQL Server → kết quả/lỗi trả lại giao diện.

| Nghiệp vụ | File backend | SQL liên quan |
|---|---|---|
| KH tạo đơn | orders.js | sp_TaoDonHang, vw_DonHangTongHop |
| Chuyển bước, duyệt báo giá/nghiệm thu | common.js | sp_ChuyenTrangThaiDon → trigger nhật ký |
| Đối soát | finance.js | sp_DoiSoatCOD → GiaoDichVi → trigger ví |
| Duyệt nạp/rút | finance.js | sp_DuyetYeuCauVi |
| Xử lý hỗ trợ | support.js | sp_XuLyHoTro |
| Báo cáo tổng hợp | admin.js | sp_BaoCaoTongHop → fn_ThongKeDon |
| Tìm KTV | orders.js | CROSS APPLY fn_DiemDanhGia |

`db.js` dùng request.input để truyền tham số có kiểu. Giá trị nhập vào không được ghép trực tiếp thành câu SQL; đây là một phần bảo vệ khỏi SQL injection. Tên bảng/tên cột động không thể coi như giá trị tham số bình thường: phải lấy từ danh sách hợp lệ hoặc xử lý định danh đúng.

Connection pool tái sử dụng kết nối thay vì mỗi thao tác tạo kết nối tùy tiện. Hàm transaction backend mở giao dịch, khóa nghiệp vụ, kiểm phiên tài khoản rồi commit/rollback. `sql-names.js` ánh xạ tên API và cột SQL tiếng Việt; không tự đổi tên cột trong DB mà bỏ qua ánh xạ.

Không phải mọi truy vấn web đều dùng SP. `sp_DonHangCuaKhach` và `fn_HanBaoHanh` là đối tượng tra cứu/minh họa, chưa được backend trực tiếp gọi. Một số view phục vụ demo/SQL reporting. Nói đúng phạm vi sử dụng thuyết phục hơn khẳng định tất cả đều dùng trong giao diện.

Nếu cần chứng minh thay vì chỉ mở code: `npm.cmd run test:sql-usage` trong SRC dùng Extended Events ghi module_end của 6 SP khi test gửi HTTP. Xem `SRC/test-results/sql-usage.json`. Kiểm thử mock OTP/AI không chứng minh gửi email hoặc gọi AI bên ngoài thật.

Chạy web khi cần:

```powershell
cd D:\Subject_K5\DBMS\ProjectCK\Nhom08_QuanLyDichVuHomeFix\SRC
npm.cmd run build
npm.cmd start
```

Mở `http://localhost:3000`. Cấu hình hiện tại dùng DB ứng dụng, không tự chuyển sang DB ôn tập. Mở tab SQL cùng đúng DB nếu muốn theo dõi thao tác web. Không đổi `.env` hoặc chạy lại db:init trên dữ liệu đang làm việc chỉ để làm một ví dụ vấn đáp.

## 13. Kịch bản trình bày khoảng 15–20 phút

| Thời lượng | Mở gì/chạy gì? | Câu giải thích trọng tâm |
|---|---|---|
| 1 phút | Sơ đồ/luồng website | SQL bảo vệ quy trình sửa chữa, thu tiền và ví |
| 2 phút | 00_schema, quan hệ DonHang/ThanhToan | PK/FK/UNIQUE khác nhau; lịch sử cần được giữ |
| 2 phút | Demo 02, chọn CHECK và sai vai trò | Nhập sai từ SSMS cũng bị chặn; FK khác trigger |
| 3 phút | Demo 03 A/B và SP tạo đơn | Tạo đơn + lịch sử trong một giao dịch; lỗi bước sau rollback cả khối |
| 2 phút | Demo 04 A/B/C | Một INSERT nhiều dòng vẫn tính đủ; âm bị chặn; sổ không sửa/xóa |
| 2 phút | Demo 05 | Hàm trả giá trị/tập; view tổng hợp; index có mục tiêu và chi phí |
| 2 phút | Demo 06/07 | Có quyền/không quyền; phiên bản cũ không được duyệt lại |
| 3 phút | Demo 08, đổi @Dich trước khi chạy | FULL → DIFF → LOG, dữ liệu SAU_DIFF xuất hiện ở DB phục hồi |
| 1 phút | Web/API + minh chứng test | Chỉ ra đường gọi SQL thực tế và giới hạn dự án |

Nếu chỉ có 7 phút: chọn CHECK, tạo đơn/rollback, trigger ví, phân quyền và backup. Đừng cố chạy hết mọi SELECT mà không giải thích được kết quả.

Trước mỗi bước nói: “Em đang ở database …; em thử …; kết quả đúng phải là …”. Sau mỗi bước đối chiếu kết quả với dự đoán. Nếu bị hỏi sâu, mở đúng định nghĩa rồi giải thích dữ liệu đầu vào/đầu ra, không chạy lại toàn bộ module cài đặt.

## 14. Xử lý lỗi khi demo

| Hiện tượng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Không thấy DB | Sai instance hoặc Object Explorer chưa refresh | Kết nối MSI\SQLEXPRESS; SELECT @@SERVERNAME; refresh Databases |
| Lỗi gần dấu `:`/`$` | Chạy file SQLCMD khi chưa bật mode | Query → SQLCMD Mode cho file 00 hoặc module backup gốc |
| Không đọc được file :r | Đường dẫn khác máy hoặc thư mục hiện hành sai | File 00 demo dùng đường dẫn tuyệt đối; sửa đúng các :r khi chuyển máy |
| DATABASE_ALREADY_EXISTS | Bộ cài cố tạo trùng DB | Bỏ qua file 00 nếu đã chuẩn bị; không xóa DB đang dùng |
| Invalid object/không tìm SP | Sai DB hoặc chưa cài đủ module | SELECT DB_NAME(); chuyển đúng DB; Refresh không thay cho cài đặt |
| Lỗi 1934 QUOTED_IDENTIFIER | Session thiếu SET options cho index lọc/tính toán | Chạy phần SET đầu file demo trước phần INSERT/UPDATE |
| Lỗi 547 | CHECK hoặc FK bị vi phạm | Đọc tên constraint trong ERROR_MESSAGE; không tắt constraint để bỏ qua |
| Lỗi 2601/2627 | Trùng unique index/constraint | Xem khóa nghiệp vụ đã có; đổi dữ liệu demo hoặc kiểm yêu cầu bị gửi lặp |
| Lỗi 515 | Đưa NULL vào cột bắt buộc | Bổ sung giá trị hợp lệ; phân biệt NULL và chuỗi rỗng |
| VERSION_CONFLICT | Dữ liệu đã thay đổi/duyệt rồi | Đọc lại dòng và trạng thái; không sửa cưỡng bức rowversion |
| Lỗi 229/230 | Thiếu quyền hoặc đang EXECUTE AS | SELECT USER_NAME(); REVERT nếu đúng là còn ngữ cảnh demo |
| Query chờ lâu | Giao dịch khác giữ khóa | Xem cửa sổ nào chưa commit/rollback; kết thúc giao dịch do mình mở |
| Transaction không commit được | XACT_STATE = −1 | ROLLBACK toàn bộ; không COMMIT hoặc rollback savepoint |
| Backup OS error 3/5 | Sai đường dẫn hoặc service thiếu quyền | Dùng thư mục backup mặc định, kiểm quyền tài khoản dịch vụ |
| BACKUP LOG không chạy | DB SIMPLE hoặc chưa có nền backup phù hợp | Dùng đúng DB demo, FULL recovery và full backup theo kịch bản |
| Restore target exists | Đã thực hành lần trước | Đổi @Dich sang tên mới; giữ bản kiểm thử cũ |
| DB đứng RESTORING | Đã NORECOVERY nhưng chưa kết thúc | Còn diff/log thì áp dụng tiếp; chỉ RECOVERY khi kết thúc chuỗi |
| Không restore bản 17.x xuống bản SQL cũ | Đích có phiên bản thấp hơn | Dùng instance tương thích; chuyển schema/data bằng script nếu cần, không hứa .bak restore ngược phiên bản |
| Báo cáo không có dòng | DB chưa có nghiệp vụ/khoảng ngày sai | Kiểm COUNT đơn và thời gian UTC; tập rỗng không tự động là lỗi |
| Npm bị chặn ExecutionPolicy | PowerShell gọi npm.ps1 | Dùng npm.cmd, không cần đổi chính sách hệ thống |

Lệnh tự kiểm tra phiên làm việc:

```sql
SELECT @@SERVERNAME AS ServerName, DB_NAME() AS DatabaseName,
       USER_NAME() AS DatabaseUser, @@TRANCOUNT AS TranCount,
       XACT_STATE() AS XactState;
-- Chỉ khi biết đây là giao dịch thử chưa chốt của mình:
IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
```

Không để một BEGIN TRAN chưa kết thúc rồi chuyển sang demo backup. Không chọn riêng dòng ở giữa khối làm mất biến khai báo hoặc TRY/CATCH. `GO` là dấu phân cách batch của công cụ, không phải câu SQL gửi lên engine; biến cục bộ hết phạm vi sau GO.

## 15. Câu hỏi vấn đáp và cách trả lời ngắn

**Tại sao không chỉ kiểm tra trên web?** Người dùng hoặc công cụ khác có thể ghi trực tiếp DB. Constraint/trigger giữ các quy tắc cốt lõi ngay tại dữ liệu; web kiểm thêm trải nghiệm, quyền và luồng thao tác.

**FK bảo đảm KhachHangId là KH không?** Không, chỉ bảo đảm có NguoiDung đó. Trigger DonHang_KhachHang kiểm thêm VaiTro.

**Tại sao có UNIQUE DonHangId mà vẫn cần trigger thanh toán?** UNIQUE ngăn hai khoản cho cùng đơn; trigger kiểm đúng nghiệm thu, trạng thái và số tiền.

**CHECK trạng thái đã đủ chưa?** Chỉ đủ để chặn mã ngoài danh sách. SP kiểm chuyển từ trạng thái nào sang trạng thái nào.

**Trigger và SP khác nhau ở đâu?** SP được gọi chủ động bằng EXEC với tham số; trigger tự chạy khi sự kiện xảy ra trên bảng và dùng inserted/deleted.

**Một INSERT 100 dòng gọi trigger như thế nào?** Trigger xử lý tập các dòng của câu lệnh. Cần logic theo tập; trigger ví GROUP BY/SUM để không bỏ sót.

**Nếu trigger lỗi thì có mất đồng bộ số dư không?** Trong giao dịch bị lỗi, phải rollback lệnh ghi và các tác động liên quan. Demo rút quá số dư cho thấy không giữ giao dịch sai và không giảm ví.

**Sửa tiền thanh toán bằng UPDATE được không?** Bị trigger bất biến chặn. Muốn điều chỉnh cần quy trình nghiệp vụ/giao dịch bù, không phá chứng từ cũ.

**Vì sao dùng DECIMAL mà không FLOAT?** Tiền cần độ chính xác thập phân và quy tắc làm tròn rõ ràng.

**SCOPE_IDENTITY khác @@IDENTITY?** SCOPE_IDENTITY giới hạn trong scope hiện tại; @@IDENTITY có thể bị giá trị identity do trigger chèn ở scope khác ảnh hưởng.

**Có cần tạo index cho mọi cột không?** Không, phải dựa vào truy vấn và cân bằng chi phí ghi/dung lượng. Ví dụ index ví theo KTV và ngày phục vụ truy vấn lịch sử.

**View có tham số không?** View thường không nhận tham số như SP/function; cần tham số thì WHERE bên ngoài hoặc TVF/SP.

**CROSS APPLY trong view ví làm gì?** Gọi hàm trả bảng cho từng dòng KTV rồi ghép kết quả. fn_SoDuVi dùng tổng hợp không GROUP BY nên vẫn trả một dòng số dư 0 khi chưa có giao dịch.

**Rollback có trả IDENTITY về số cũ không?** Không bảo đảm. Khoảng trống Id bình thường; Id không phải số thứ tự chứng từ liên tục.

**Tại sao gọi lại duyệt ví bị lỗi?** Yêu cầu đã đổi trạng thái và rowversion; kiểm tra đồng thời cùng UNIQUE tham chiếu ngăn cộng tiền hai lần.

**Commit xong có rollback lệnh cũ để sửa được không?** Không bằng ROLLBACK của transaction đã kết thúc. Phải có thao tác bù hoặc phục hồi dữ liệu theo kế hoạch.

**Recovery FULL có nghĩa dữ liệu đã được backup?** Không. Cần thực hiện và quản lý chuỗi backup thực tế.

**VERIFYONLY thành công đã đủ chưa?** Chưa. Demo restore sang DB mới, CHECKDB và kiểm giá trị phát sinh sau DIFF là bằng chứng mạnh hơn.

**Backup database có cả ảnh người dùng không?** Chỉ metadata nếu ảnh lưu ngoài SQL Server. Phải sao lưu uploads riêng.

**Có hạn chế nào?** Quyền theo hàng chủ yếu ở API; một số SP tin Id từ tầng gọi; có khóa ghi toàn cục giảm thông lượng; chưa kiểm tải lớn; view doanh thu chưa tự lọc đối soát Confirmed; OTP/AI thật phụ thuộc cấu hình ngoài. Nêu đúng điểm mình biết và hướng cải thiện, không khẳng định hệ thống hoàn hảo.

**Ai làm phần nào?** Trình bày đúng phân công và commit thực tế; mỗi người phải nắm ít nhất luồng tổng và phần mình phụ trách. Không dùng số dòng code hoặc nội dung AI tạo ra làm thay thế cho hiểu biết khi vấn đáp.

## 16. Kiểm tra cuối trước khi đến lớp

- Mở được SSMS vào đúng instance; thấy DB ứng dụng và DB ôn tập.
- Mở sẵn 00_schema, 05_transaction, 06_trigger, 07_security và các demo 02/03/04/06/08.
- Biết DB ôn tập đã được tạo; không chạy lại bộ cài trên DB đó.
- Sửa trước tên đích mới của bài backup, để tránh dừng vì bản restore đã có.
- Tự chạy và giải thích lại ít nhất: tiền âm → lỗi, chuyển sai trạng thái → rollback, trigger cộng nhiều dòng, KH bị từ chối đọc mật khẩu, restore ra giá trị SAU_DIFF.
- Giữ bản PDF/Word, tài liệu này và mã nguồn cục bộ để không phụ thuộc mạng khi trình bày.
- Sau demo giao dịch kiểm `@@TRANCOUNT=0`; sau giả lập quyền chắc chắn đã REVERT.

Phụ lục sau đây cung cấp toàn bộ cấu trúc cần tra cứu: [PHU_LUC_CAU_TRUC_VAN_DAP.md](PHU_LUC_CAU_TRUC_VAN_DAP.md). Kết quả chạy script: [demo_van_dap/KET_QUA_KIEM_CHUNG.md](demo_van_dap/KET_QUA_KIEM_CHUNG.md).
