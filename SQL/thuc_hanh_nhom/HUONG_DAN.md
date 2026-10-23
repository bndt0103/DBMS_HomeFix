# Hướng dẫn thực hành và vấn đáp SQL – nhóm 08

## 1. Cách phân công mới

**Cả bốn thành viên làm đủ 10 nhóm kiến thức, cùng mức trách nhiệm; khác nhau ở phân hệ và ví dụ.**
Không còn cách chia Việt chỉ học index, Tuấn chỉ học view/function, Trung chỉ học SP và Tài chỉ học quyền/backup.
Mỗi người phải tự chạy bài của mình, sửa được tham số và giải thích được thông báo SQL.

[Phân công 7 cột theo rubric](PHAN_CONG.md) · [Word](BangPhanCong_SQL_Nhom08.docx) · [PDF](BangPhanCong_SQL_Nhom08.pdf) · [Danh mục mã nguồn](DANH_MUC_DOI_TUONG.md) · [Kiểm chứng](KET_QUA_RASOAT.md)

| Thành viên | Phân hệ để minh họa | Mã bài |
|---|---|---|
| Nguyễn Quốc Việt – 24110381 | Khách hàng, dịch vụ và đánh giá | [V01–V10](01_NguyenQuocViet.sql) |
| Đỗ Anh Tuấn – 24110369 | Đặt đơn, báo giá và điều phối | [T01–T10](02_DoAnhTuan.sql) |
| Bùi Nguyễn Duy Trung – 24110363 | Vật tư, nghiệm thu và bảo hành | [D01–D10](03_BuiNguyenDuyTrung.sql) |
| Lê Tấn Tài – 24110319 | Thanh toán, đối soát và ví kỹ thuật viên | [A01–A10](04_LeTanTai.sql) |

Nhóm 01 là schema và seed (module 00, 08); 02 index (01); 03 view (03); 04 function (02);
05 SP (04, 05); 06 trigger (06); 07 transaction (05); 08 security (07); 09 migration (09); 10 backup/restore (10).
Như vậy đủ **10 nhóm kiến thức, phủ 11 module 00–10**. Thứ tự bài học khác thứ tự tạo đối tượng khi cài CSDL.

## 2. Chuẩn bị SSMS

1. Thành viên chưa có DB: làm theo [cài đặt thành viên](../CAI_DAT_THANH_VIEN.md), chạy `db:init`, `db:demo` trên tên DB mới. Không chạy lại seed trên DB đang có dữ liệu.
2. Kết nối đúng SQL instance của máy mình bằng tài khoản DBA. Máy nhóm trưởng dùng `localhost\SQLEXPRESS`, DB `HomeFix_DBMS_Clean_20261022`; bản CNPM `HomeFix_Final_20261007` không dùng cho bài này.
3. Mở file của mình bằng UTF-8. Sửa `USE` nếu DB trên máy có tên khác. Chạy hai batch đầu trước. File thực hành không cần SQLCMD Mode.
4. Chọn **nguyên một mục XX01…XX10 đến trước GO**, rồi F5. Biến chỉ tồn tại trong batch; chọn riêng dòng EXEC sẽ báo chưa khai báo biến.
5. Đọc Results và Messages. Với XX02, Ctrl+M trước khi chạy để có Actual Execution Plan. Không kết luận hiệu năng chỉ từ thời gian vài mili giây.
6. Kết thúc phải có `SELECT @@TRANCOUNT;` bằng 0 và `SELECT USER_NAME();` trở lại DBA. Các bài ghi dữ liệu/DDL được rollback; số IDENTITY và bộ đếm rowversion vẫn có thể tăng.

```sql
USE [HomeFix_DBMS_Clean_20261022];
GO
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL, USER_NAME() AS NguCanh;
SELECT @@TRANCOUNT AS SoGiaoDichDangMo;
```

Không dừng giữa khối phân quyền. Bài XX08 khóa quyền trong giao dịch rồi rollback đúng quyền ban đầu; khi chạy trên DB dùng chung nên tạm ngừng thao tác web. Nếu dừng giữa chừng, REVERT nếu đang ở `hf_*`, rollback giao dịch còn mở hoặc đóng kết nối đó và mở kết nối DBA mới.

## 3. Cách trình bày 10 nội dung

| Mục | Cách demo và kết quả cần đọc | Điều cần giải thích |
|---|---|---|
| 01 | Đọc cột/khóa/miền giá trị, chạy UPDATE giá trị âm; bắt lỗi CHECK 547 | PK định danh; FK tham chiếu; UNIQUE ngăn trùng; NOT NULL khác CHECK; DEFAULT không tự chạy khi UPDATE. Tiền DECIMAL, chữ NVARCHAR và N'…'. |
| 02 | Hai SELECT giống nhau trên 50.000 dòng bảng tạm; đọc IO/plan trước và sau CREATE INDEX; DROP INDEX | Mỗi lần có 50 kết quả; so logical reads của SELECT, bỏ chi phí tạo index. Index thêm dung lượng/chi phí ghi; không ép FORCESEEK, không DROP index ứng dụng. |
| 03 | Đọc View thật, OBJECT_DEFINITION; tự CREATE VIEW, SELECT và rollback | View thông thường là truy vấn đóng gói, không là bản sao dữ liệu hay bảng lưu riêng. JOIN có thể nhân dòng nếu ghép quan hệ 1–n. |
| 04 | Chạy hàm thật; tự viết scalar, gọi với số đơn giản rồi rollback | Scalar dùng trong SELECT, TVF trong FROM/APPLY. Hàm không thay đổi dữ liệu, không mở transaction; NULL/COALESCE phải được hiểu đúng. |
| 05 | Chạy SP nghiệp vụ trong transaction ngoài; đọc dòng trước/sau; tạo thêm SP tra cứu có tham số rồi rollback | SP kiểm tra actor, vai trò, trạng thái, phiên bản và giá trị; SELECT tổng do SQL tính. Không cộng lại tiền theo tổng tùy ý từ client. |
| 06 | Mở trigger thật rồi cố ý sửa dữ liệu sai; nhận 51009 và kiểm tra rollback | AFTER chạy sau kiểm tra ràng buộc; INSTEAD OF thay thao tác gốc. inserted/deleted là tập hợp; một lệnh UPDATE có thể tác động nhiều dòng. |
| 07 | BEGIN TRAN, SAVE TRAN, UPDATE thử, ROLLBACK đến điểm lưu, COMMIT; giá trị cuối bằng ban đầu | Savepoint không phải transaction độc lập. @@TRANCOUNT là độ lồng; XACT_STATE -1 phải rollback toàn bộ. TRY/CATCH xử lý lỗi, THROW chuyển lỗi lên. |
| 08 | GRANT → đọc được; REVOKE → lỗi 229/230; GRANT → đọc lại; DENY → bị chặn; REVERT/ROLLBACK | Thử bằng hf_role, không bằng sysadmin. REVOKE gỡ khai báo trực tiếp, không phủ quyền kế thừa; DENY cấm rõ ràng. Bảng thật bị DENY, View/SP dùng ownership chaining cùng dbo. |
| 09 | Xem cấu trúc thật; ALTER ADD có IF trên bảng tạm; chạy kiểm tra hai lần, dữ liệu cũ còn và không trùng cột | Migration là nâng phiên bản có bảo toàn dữ liệu, khác xóa DB/cài lại seed. File 09 thật do DBA chạy qua db:upgrade, cần backup trước. |
| 10 | Mỗi người tự chạy COPY_ONLY có MSSV trong tên file, VERIFYONLY; tiếp tục tự chạy file 05 chung để restore | Backup trên máy SQL Server; tài khoản dịch vụ cần quyền thư mục. VERIFYONLY chưa đủ: phải restore và truy vấn kiểm chứng. FULL thường làm nền DIFF; LOG cần FULL recovery và chuỗi log hợp lệ. |

Các đối tượng `vw_TH_*`, `fn_TH_*`, `sp_TH_*` là bài viết SQL ngắn có tên riêng của mỗi người; transaction rollback gỡ chúng, không thêm chức năng vào hệ thống HomeFix.

## 4. Phần riêng của từng thành viên

### Nguyễn Quốc Việt – 24110381

Mở [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql). Chủ đề: **Khách hàng, dịch vụ và đánh giá**.

| Bài | Công việc cụ thể | Cô hỏi / cần tự giải thích |
|---|---|---|
| V01 | DichVu, DanhMucDichVu, NguoiDung và DanhGia | Vì sao tách danh mục với dịch vụ? FK không tự kiểm tra vai trò người dùng; SP làm bước đó. |
| V02 | Lọc dịch vụ theo DanhMucId trên bảng tạm | Vì sao đưa cột lọc trước INCLUDE? INCLUDE dùng phủ truy vấn, không làm cột tìm kiếm đầu index. |
| V03 | vw_DichVuCongKhai | View lọc dịch vụ/danh mục ngừng hoạt động ở đâu? Mở định nghĩa chỉ từng điều kiện. |
| V04 | fn_DiemDanhGia và hàm giá sau giảm tự viết | AVG bỏ qua NULL; không có điểm thì COALESCE về 0 theo quy ước ứng dụng; 200000 giảm 10% còn 180000. |
| V05 | sp_LuuDanhMucDichVu: thêm, sửa, ngừng dùng | Vì sao không xóa danh mục đã có dịch vụ? Giải thích FK và việc giữ lịch sử. |
| V06 | tr_DanhGia_KiemTraDon | Đổi khách của đánh giá sang một KH có thật: FK vẫn đúng nhưng trigger chặn vì không phải chủ đơn hoàn thành. |
| V07 | SAVEPOINT trên PhiKiemTra của DichVu | Giá tạm tăng 1 rồi về đúng giá cũ; COMMIT kết thúc giao dịch sau rollback đến điểm lưu. |
| V08 | Role KH và vw_DichVuCongKhai | Thu hồi SELECT rồi chạy truy vấn thật với hf_KH; sau bài phải trả lại quyền ban đầu. |
| V09 | Bổ sung DangHoatDong trên bản danh mục cũ mô phỏng | DEFAULT 1 cho dữ liệu cũ và IF COL_LENGTH ngăn thêm cột hai lần. |
| V10 | Backup có MSSV 24110381, sau đó file 05 | Tự phục hồi bản riêng và chỉ ra 3 dòng tương ứng FULL, DIFF, LOG. |

### Đỗ Anh Tuấn – 24110369

Mở [02_DoAnhTuan.sql](02_DoAnhTuan.sql). Chủ đề: **Đặt đơn, báo giá và điều phối**.

| Bài | Công việc cụ thể | Cô hỏi / cần tự giải thích |
|---|---|---|
| T01 | DonHang, BaoGiaSoBo, LenhDieuPhoi | Một đơn có một báo giá sơ bộ hiện hành; giá âm bị CHECK chặn; phiên bản rowversion không phải thời gian. |
| T02 | Lọc đơn theo KhachHangId trên bảng tạm | So với IX_DonHang_Khach_TrangThai trong module 01: cột khóa và cột INCLUDE dùng làm gì? |
| T03 | vw_DonHangTongHop | INNER JOIN khách/dịch vụ, LEFT JOIN thợ vì đơn mới chưa có thợ; tổng tiền lấy từ hàm. |
| T04 | fn_KyThuatVienPhuHop, fn_ThongKeDon; tự viết hàm cộng phí | Danh sách rỗng có thể do chưa có đơn chờ phân công hoặc không có thợ đủ điều kiện; không phải lỗi hàm. |
| T05 | Tạo đơn → báo giá → KH duyệt | Khách phải duyệt trước phân công. Điều chỉnh trước phân công đưa báo giá về Pending và phải duyệt lại. |
| T06 | tr_DonHang_KiemTraTrangThai | Cố đổi đơn hoàn thành về chờ tiếp nhận bị chặn; UPDATE nhiều dòng cần xét toàn tập inserted/deleted. |
| T07 | SAVEPOINT trên PhiKiemTra của BaoGiaSoBo | Chỉ minh họa lệnh DBA tạm, web bắt buộc dùng SP. Trình bày khóa dòng và kiểm tra phiên bản. |
| T08 | Role DPV và vw_DonHangTongHop | Có SELECT View không đồng nghĩa được sửa bảng DonHang; quyền ghi đi qua SP. |
| T09 | Bổ sung NgayCapNhat trên bảng đơn cũ mô phỏng | DEFAULT thời gian chỉ cấp lúc thêm cột/chèn dữ liệu, không tự cập nhật sau mỗi UPDATE. |
| T10 | Backup có MSSV 24110369, sau đó file 05 | Giải thích NORECOVERY ở các bước trung gian và RECOVERY ở bước cuối. |

### Bùi Nguyễn Duy Trung – 24110363

Mở [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql). Chủ đề: **Vật tư, nghiệm thu và bảo hành**.

| Bài | Công việc cụ thể | Cô hỏi / cần tự giải thích |
|---|---|---|
| D01 | BangKeVatTu, ChiTietVatTu, PhieuNghiemThu | BangKe–ChiTiet là 1–n; thành tiền = số lượng * đơn giá, không nhập tay cột tính toán. |
| D02 | Lọc vật tư theo BangKeVatTuId trên bảng tạm | Đối chiếu IX_ChiTietVatTu_DeXuat: INCLUDE ThanhTien và SoThangBaoHanh. |
| D03 | vw_PhieuNghiemThu | Đọc phí, tiền công, tổng vật tư, tổng phiếu; tránh JOIN vật tư rồi cộng lặp tổng phiếu. |
| D04 | fn_HanBaoHanh, fn_TongTienDonHang; tự viết hàm thành tiền | 2 * 50000 = 100000; không có vật tư bảo hành thì hạn có thể NULL. |
| D05 | Kê khai vật tư → lập nghiệm thu | Không có khách duyệt bảng kê riêng; khách ký nghiệm thu cuối cùng. Cần một đơn DangXuLy. |
| D06 | tr_ChiTietVatTu_KhoaNghiemThu | Đơn giá dương vẫn bị cấm sửa nếu bảng kê đã được dùng trong nghiệm thu, kể cả phiếu bị từ chối. |
| D07 | SAVEPOINT trên số lần sửa của BangKeVatTu | Dùng bảng kê để tránh sửa chi tiết đã khóa; số lần sửa tạm được rollback ngay. Không sử dụng cách này trong API. |
| D08 | Role KTV và vw_PhieuNghiemThu | Backend còn kiểm tra thợ có được phân công hay không; role SQL không tự lọc theo người dùng thực tế. |
| D09 | Bổ sung SoThangBaoHanh trên vật tư cũ mô phỏng | Giá trị mặc định 0 nghĩa không bảo hành vật tư; dữ liệu trước nâng cấp vẫn giữ nguyên. |
| D10 | Backup có MSSV 24110363, sau đó file 05 | Giải thích logical name khác tên file vật lý; RESTORE FILELISTONLY dùng để viết MOVE. |

### Lê Tấn Tài – 24110319

Mở [04_LeTanTai.sql](04_LeTanTai.sql). Chủ đề: **Thanh toán, đối soát và ví kỹ thuật viên**.

| Bài | Công việc cụ thể | Cô hỏi / cần tự giải thích |
|---|---|---|
| A01 | KyThuatVien, ThanhToan, DoiSoat, GiaoDichVi | Ví phải không âm; sổ cái là lịch sử có dấu; thanh toán và đối soát là hai bước khác nhau. |
| A02 | Lọc giao dịch theo KyThuatVienId trên bảng tạm | Đối chiếu IX_GiaoDichVi_Tho_Ngay; index hỗ trợ tra cứu lịch sử một thợ theo thời gian. |
| A03 | vw_ViKyThuatVien | SoDu lưu nhanh và SoDuSoCai phải bằng nhau, ChenhLech phải bằng 0. |
| A04 | fn_SoDuVi, fn_HoaHong; tự viết hàm hoa hồng | Tiền ví lấy SUM số có dấu; 200000 * 15 / 100 = 30000, không nhập 0.15 khi hàm nhận phần trăm. |
| A05 | sp_LuuTaiKhoanNganHang: thêm/sửa/ngừng hoạt động | Số tài khoản chỉ gồm chữ số theo CHECK. Tài khoản đã tham gia giao dịch không tùy ý đổi danh tính. |
| A06 | tr_GiaoDichVi_BatBien | INSTEAD OF DELETE luôn từ chối; chỉnh sai phải dùng nghiệp vụ bù, không sửa/xóa lịch sử. |
| A07 | SAVEPOINT trên SoDu của KyThuatVien | Số dư tạm tăng rồi được trả lại trước COMMIT; vận hành thật chỉ cập nhật ví cùng sổ cái trong SP. |
| A08 | Role KT và vw_ViKyThuatVien | Kế toán được đọc View, không UPDATE/DELETE sổ cái; admin web không phải SQL sysadmin. |
| A09 | Bổ sung GhiChu cho bản ghi tài chính cũ mô phỏng | Cột nullable có thể thêm mà giữ dữ liệu cũ; kiểm tra trạng thái cấu trúc trước ALTER. |
| A10 | Backup có MSSV 24110319, sau đó file 05 | COPY_ONLY không làm nền DIFF; bản FULL thường trên DB thực hành mới là nền cho DIFF. |

## Chuyên môn KTV sau khi đồng bộ main

Mỗi KTV có đúng một mã chuyên môn: `DIEN`, `NUOC`, `DIEN_LANH`, `DO_GO` hoặc `KHOA`.
`fn_KyThuatVienPhuHop` so mã này với `DanhMucDichVu.Ma`; không dùng chuỗi nhiều tay nghề
ngăn cách bằng dấu phẩy. Chỉ khu vực phục vụ được khai báo nhiều phần. CHECK bảo vệ quy tắc
này ở cả `KyThuatVien` và `HoSoKTV`; khi minh họa dữ liệu cũ cần đọc module 09 để biết quy
tắc chuyển đổi thực tế, không tự suy đoán mã theo vị trí trong chuỗi.

## 5. Bài đồng thời: mỗi người tự làm bằng hai cửa sổ

Chọn bảng theo phần mình: Việt `DichVu`, Tuấn `BaoGiaSoBo`, Trung `BangKeVatTu`, Tài `KyThuatVien`.
Thay tên bảng trong **cả hai cửa sổ**, dùng cùng một Id có thật. Đây là khóa đọc, không tạo giao dịch mẫu.

**Cửa sổ A:** chạy và giữ transaction mở đến khi đã thử ở B.

```sql
BEGIN TRANSACTION;
SELECT TOP (1) Id FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) ORDER BY Id;
-- Sau khi cửa sổ B báo 1222: chạy ROLLBACK TRANSACTION ở cửa sổ A.
```

**Cửa sổ B:**

```sql
SET LOCK_TIMEOUT 3000;
BEGIN TRY
    SELECT TOP (1) Id FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) ORDER BY Id;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao; -- 1222 khi A giữ khóa.
END CATCH;
SET LOCK_TIMEOUT -1;
```

Sau ROLLBACK A, B đọc lại được. UPDLOCK giữ khóa để chuẩn bị cập nhật, HOLDLOCK dùng ngữ nghĩa SERIALIZABLE trong transaction. Khóa không thay thế kiểm tra phiên bản; SP còn so `PhienBanDuKien` với rowversion đang lưu. Có thể mở hai tab web cùng một bản ghi để chứng minh bản cũ bị từ chối; không tắt kiểm tra phiên bản để demo.

## 6. Backup/restore: ai cũng thực hiện

Mỗi người chạy XX10 trong file mình: COPY_ONLY có MSSV, VERIFYONLY và xem đường dẫn trả về.
Sau đó **mỗi người tự chạy toàn bộ** [05_SaoLuuPhucHoi_Chung.sql](05_SaoLuuPhucHoi_Chung.sql).
File chung là cùng quy trình quản trị ở cấp database, không phải phần việc chỉ của Tài.

1. Sao lưu COPY_ONLY bản gốc để không đổi nền DIFF.
2. Phục hồi sang tên mới có mã ngẫu nhiên; đổi bản thực hành sang FULL.
3. Tạo dòng mốc 1 rồi FULL thường; thêm dòng mốc 2 rồi DIFF; thêm dòng mốc 3 rồi LOG.
4. Phục hồi FULL → DIFF → LOG sang DB kiểm chứng, MOVE data/log sang file khác. Hai bước đầu NORECOVERY, bước cuối RECOVERY.
5. SELECT đủ ba dòng và CHECKDB. Tự gỡ đúng hai DB vừa tạo; giữ tệp backup để đối chiếu. Bản gốc vẫn SIMPLE và không mất dữ liệu.

BACKUP/RESTORE không chạy trong transaction người dùng. Thư mục D: trên máy bạn không phải D: trên máy SQL Server khác. Không dùng WITH REPLACE hoặc chọn DB CNPM làm đích. File chung hiện hỗ trợ cấu trúc một data file và một log file; nếu có thêm file phải đọc FILELISTONLY và viết đủ MOVE.

## 7. Lỗi thường gặp và cách xử lý

| Biểu hiện | Giải thích / thao tác |
|---|---|
| Invalid object name | Kiểm tra DB_NAME, tên schema dbo, bản cài hiện tại và tên DB trong USE. Không cài lại seed để chữa nhầm DB. |
| Must declare scalar variable | Chọn đủ phần DECLARE đến GO; không chia batch tùy ý. |
| 547 ở XX01 | Lỗi CHECK chủ động tạo; đọc tên constraint trong message. FK sai cũng có thể là 547 nhưng message khác. |
| 51009 ở XX06 | Trigger đang bảo vệ nghiệp vụ đúng thiết kế; không tắt trigger để làm lệnh sai chạy được. |
| 229/230 ở XX08 | Lỗi dự kiến sau REVOKE/DENY. Cuối bài quyền phải về trạng thái trước thử nghiệm. |
| Bài D05 báo cần chuẩn bị | Dùng dữ liệu minh họa hoặc một đơn KTV đã bấm Bắt đầu xử lý, rồi chạy lại; không giả đổi trạng thái bằng UPDATE để vượt nghiệp vụ. |
| TVF lọc thợ rỗng | Kiểm tra trạng thái ChoPhanCong, tay nghề, khu vực, sẵn sàng và đơn đang giữ. Không phải mọi View/TVF đều luôn có dòng. |
| Database in use khi restore | Chọn tên mới như file mẫu; kiểm tra kết nối riêng. Không cưỡng chế gỡ DB gốc. |
| Không ghi được .bak | Quyền thư mục của dịch vụ SQL Server, không phải chỉ quyền tài khoản Windows mở SSMS. Dùng thư mục mặc định trả bởi SERVERPROPERTY. |
| chữ tiếng Việt sai | Mở file UTF-8, nhập chuỗi SQL có N, dữ liệu dùng NVARCHAR. Không sửa thành chữ không dấu để che lỗi mã hóa. |

## 8. Tự kiểm trước khi vấn đáp

- Mỗi người đánh dấu làm được cả XX01–XX10 và chạy bài phục hồi chung, không chỉ đọc tài liệu.
- Mỗi người phải tự sửa một tham số, một điều kiện WHERE và giải thích vì sao kết quả đổi.
- Với mỗi câu lệnh chỉ rõ dữ liệu đầu vào, kết quả dự kiến, ràng buộc/SP/trigger nào bảo vệ và cách xử lý lỗi.
- Tỉ lệ hoàn thành/điểm/chữ ký do nhóm xác nhận; không tự khai đã làm xong nếu chưa chạy thử cá nhân.
- Mở web để chỉ đường đi: giao diện → API → SP/View/TVF → bảng/ràng buộc/trigger. Quyền Role SQL không thay thế bộ lọc sở hữu ở backend.

Trọng tâm đánh giá là hiểu tác dụng và thao tác được. Bảng tổng hợp và tiêu đề mô tả TC3 trong rubric có chênh trọng số; giữ nguyên rubric tham chiếu, không tự sửa thang điểm.
