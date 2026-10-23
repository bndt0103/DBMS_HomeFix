# Thực hành SQL và phân công vấn đáp nhóm 08

Đề tài: **HomeFix – Quản lý dịch vụ sửa chữa và bảo trì tại nhà**. Lớp `261DBMS330284_02`.

Tài liệu bám theo `Rubric_Project_DBMS.docx` và cấu trúc đang chạy ngày 23/10/2026. Đọc mục chuẩn bị, phần được phân công và câu hỏi chung trước khi mở SQL demo. Các ví dụ không yêu cầu thuộc lòng Id của dữ liệu.

[Danh mục đối tượng](DANH_MUC_DOI_TUONG.md) chỉ ra tên, loại, module và dòng mã nguồn để mở nhanh khi cô hỏi. [Kết quả rà soát](KET_QUA_RASOAT.md) ghi nhận các bước đã kiểm chứng.

## 1. Mở đúng database và chạy đúng cách

1. Mở SQL Server Management Studio, kết nối instance SQL Server của máy bạn bằng tài khoản Windows hiện tại (ví dụ `localhost\SQLEXPRESS`; máy nhóm trưởng là `MSI\SQLEXPRESS`).
2. Trong Object Explorer: **Databases → HomeFix_DBMS_Clean_20261022 → Tables/Views/Programmability/Security**. Nếu chưa thấy, nhấp phải Databases → Refresh.
3. Mở file SQL của mình, chạy phần từ `USE` đến `GO` thứ hai. Không bật SQLCMD Mode cho các file thực hành này. SQLCMD chỉ cần cho bộ cài tổng.
4. Bôi đen **trọn một khối** từ mã bài đến trước `GO`, rồi F5. Biến `DECLARE` chỉ sống trong batch hiện tại. Không bôi đen riêng dòng EXEC khi biến chưa được khai báo.
5. Đọc cả **Results**, **Messages** và **Execution Plan**. Ctrl+M trước khi chạy bài index để lấy kế hoạch thực thi thực tế.
6. Khi kết thúc, chạy `SELECT @@TRANCOUNT;`: kết quả phải bằng **0**. Sau bài phân quyền, `SELECT USER_NAME();` phải trở về `dbo` trên máy hiện tại.

```sql
USE [HomeFix_DBMS_Clean_20261022];
GO
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL, USER_NAME() AS NguCanh;
```

`HomeFix_Final_20261007` là bản của môn CNPM, không dùng để trình bày đồ án DBMS. Không chạy lại `CSDL_HomeFix.sql`/`08_seed.sql` trên bản đang dùng. Máy nhóm trưởng đã nạp `du_lieu_mau.sql`; thành viên cài máy mới làm theo [hướng dẫn cài đặt](../CAI_DAT_THANH_VIEN.md), không nạp lại seed trước mỗi lần demo.

Các bài ghi dữ liệu sử dụng transaction ngoài rồi rollback; IDENTITY và bộ đếm rowversion vẫn có thể tăng dù rollback. Không suy ra mất dữ liệu chỉ vì Id không liên tiếp. Không dừng giữa khối phân quyền hoặc giữa chuỗi backup. Nếu lỡ dừng: `REVERT` nếu đang ở `hf_*`, rồi `IF @@TRANCOUNT > 0 ROLLBACK;`; đóng cửa sổ và mở kết nối mới nếu không chắc ngữ cảnh.

## 2. Bảng phân công để đưa vào báo cáo

Bản [Word](BangPhanCong_SQL_Nhom08.docx) và [PDF](BangPhanCong_SQL_Nhom08.pdf) nằm cùng thư mục bài thực hành để thành viên pull về có đầy đủ tài liệu. Máy nhóm trưởng còn giữ bản bàn giao tại `ProjectCK/TaiLieuVanDap_Nhom08`. Bảng giữ 7 cột, độ rộng, viền và font theo bảng cuối rubric. Phần việc được tách thành 8–10 gạch đầu dòng mỗi người; mã bài V/T/D/A đối chiếu với file SQL. Tiêu đề bảng lặp ở trang sau và toàn bộ phần việc của một thành viên được giữ trên cùng trang. Xem [phân công chi tiết](PHAN_CONG.md) để tra cứu từng đầu việc.

Ô **Tỉ lệ hoàn thành**, **Điểm**, **Ký tên** để nhóm tự xác nhận sau khi thực hành. Đây là phân công chuẩn bị, rà soát và bảo vệ SQL; không phải kết luận về tác giả lịch sử của từng commit.

| Thành viên | Phụ trách chính | File thực hành | Mục cần trình bày |
|---|---|---|---|
| Nguyễn Quốc Việt – 24110381 | 00 schema, 01 index, 08 seed | [01_NguyenQuocViet.sql](01_NguyenQuocViet.sql) | V01–V06: PK/FK, chuẩn hóa, CHECK/UNIQUE, CRUD danh mục, seed và đo index trước/sau |
| Đỗ Anh Tuấn – 24110369 | 02 function, 03 view; báo cáo đọc trong 05 | [02_DoAnhTuan.sql](02_DoAnhTuan.sql) | T01–T06: JOIN, GROUP BY/HAVING, 6 hàm, view, tính tiền, báo cáo, tự viết view/hàm ngắn |
| Bùi Nguyễn Duy Trung – 24110363 | 04 SP, 05 transaction; trigger trạng thái trong 06 | [03_BuiNguyenDuyTrung.sql](03_BuiNguyenDuyTrung.sql) | D01–D08: tham số SP, nghiệp vụ đơn, TRY/CATCH, savepoint, rowversion, trigger nhiều dòng, vật tư, hỗ trợ, phí hủy |
| Lê Tấn Tài – 24110319 | 06 trigger chứng từ/vật tư, 07 security, 09 migration, 10 backup; đối soát trong 05 | [04_LeTanTai.sql](04_LeTanTai.sql), [04b_SaoLuuPhucHoi.sql](04b_SaoLuuPhucHoi.sql) | A01–A08: 7 trigger, sổ cái, GRANT/REVOKE/DENY, quyền EXECUTE, đối soát, nâng cấp, FULL/DIFF/LOG và phục hồi |

**Mọi thành viên phải biết phần chung ở mục 8.** Cô có thể hỏi chéo. Người phụ trách chính phải mở được định nghĩa đối tượng, giải thích điều kiện và tự sửa tham số ví dụ. Không chỉ đọc kết quả do file in sẵn.

## 3. Đối chiếu rubric và các module

Chuỗi SQL hiện tại là **00–10, gồm 11 file** vì đánh số từ 0; tài liệu này bao phủ tất cả, không bỏ seed, migration hay backup.

| Module | Nội dung thực tế | Người chính | Bài minh chứng |
|---|---|---|---|
| 00_schema | 28 bảng; kiểu dữ liệu; PK, FK, UNIQUE, CHECK, DEFAULT, cột tính toán, rowversion | Việt | V01, V04; T04 |
| 01_index | 21 index viết tường minh, gồm 9 UNIQUE lọc và 12 index thường; chưa tính index tự sinh bởi PK/UNIQUE | Việt | V05, V06 |
| 02_function | 2 scalar, 4 inline TVF | Tuấn | T03, T06 |
| 03_view | 34 view, tách view công khai và xác thực nội bộ | Tuấn | T01, T02, T04, T06 |
| 04_sp | 19 SP tài khoản, danh mục, cấu hình, tệp và tiện ích | Trung | D01; V03 minh họa SP danh mục |
| 05_transaction | 30 SP nghiệp vụ/báo cáo; ghi có transaction và savepoint | Trung | D02–D08; T05, A05 |
| 06_trigger | 7 trigger, xử lý theo tập hợp | Tài, Trung | A01, A02; D05 |
| 07_security | 7 role nghiệp vụ; user `hf_*`; role kỹ thuật nội bộ đăng nhập | Tài | A03, A04 |
| 08_seed | Dữ liệu gốc, không có giao dịch | Việt | V02 |
| 09_data_migration | Nâng cấu trúc và giữ dữ liệu cũ | Tài | A06; giải thích các IF/ALTER trong module |
| 10_backup_recovery | SP sao lưu; quản trị phục hồi | Tài | A07, A08 |

Rubric yêu cầu chứng minh **tác dụng**, không chỉ đếm đối tượng. TC1: giải thích mô hình/chuẩn hóa; TC2: ràng buộc, trigger, view, index; TC3: SP/function/xử lý lỗi; TC4: giao dịch/quyền; TC5: đối chiếu web gọi SQL; TC6: thao tác và thông báo; TC7: tài liệu tái hiện; TC8: mỗi người demo/trả lời phần mình.

Trong rubric, bảng tổng hợp ghi TC3 là **20%**, nhưng tiêu đề phần mô tả ghi **15%**. Bảng tổng hợp cộng đủ 100%. Nhóm giữ nguyên mẫu, không tự sửa rubric; khi cần xác nhận trọng số thì hỏi giảng viên.

## 4. Nguyễn Quốc Việt: thiết kế, dữ liệu gốc và index

### V01–V02: giải thích thiết kế từ một đơn dịch vụ

Mở `00_schema.sql` và chỉ vào `NguoiDung`, `KyThuatVien`, `DanhMucDichVu`, `DichVu`, `DonHang`. Một khách có nhiều đơn; một danh mục có nhiều dịch vụ; một dịch vụ được đặt trong nhiều đơn. Thợ là phần mở rộng của người dùng: `KyThuatVien.Id` vừa là PK vừa là FK sang `NguoiDung.Id`.

Các nhóm bảng còn lại: báo giá/phân công; bảng kê/chi tiết vật tư; nghiệm thu/chữ ký; thanh toán/đối soát/sổ ví; hỗ trợ/trao đổi; cấu hình/nhật ký/tệp. Không lưu nhiều vật tư trong một cột chuỗi: tách `BangKeVatTu` và `ChiTietVatTu` theo quan hệ 1–n.

- PK phân biệt từng dòng, không NULL và không trùng. IDENTITY cấp số, tự nó không phải PK.
- FK bảo vệ tham chiếu. Xóa danh mục đang có dịch vụ bị chặn vì không có ON DELETE CASCADE.
- UNIQUE điện thoại bảo vệ đăng nhập duy nhất. Index UNIQUE lọc Email cho phép nhiều Email NULL, chỉ kiểm tra giá trị có dữ liệu.
- CHECK giá/hoa hồng/trạng thái bảo vệ miền giá trị. CHECK có thể chấp nhận UNKNOWN do NULL; dùng NOT NULL ở các cột bắt buộc, không trông chờ CHECK thay nó.
- DEFAULT cấp giá trị khi INSERT không truyền cột; không tự cập nhật ngày sửa khi UPDATE.
- Tiền dùng DECIMAL, tên/địa chỉ dùng NVARCHAR; literal tiếng Việt phải có `N'...'`. VARCHAR lưu mã ASCII/điện thoại, không dùng để lưu họ tên tiếng Việt.

Về chuẩn hóa: thuộc tính không khóa phụ thuộc vào định danh thực thể; tên danh mục tách khỏi dịch vụ; nhiều chi tiết vật tư tách thành bảng con. Có dữ liệu giữ tại thời điểm giao dịch: `DonHang.TenDichVu`, giá trên báo giá/nghiệm thu và số dư ví lưu nhanh. Giải thích đây là lựa chọn giữ chứng từ/hiệu năng; không khẳng định mọi cột lặp đều sai hay toàn hệ thống không có đánh đổi chuẩn hóa. `vw_ViKyThuatVien` đối chiếu số dư lưu với sổ cái.

### V03–V04: demo được cả đúng và sai

V03 lần lượt thêm, sửa và ngừng dùng danh mục qua cùng SP. Mỗi lần sửa lấy rowversion mới. Kết thúc rollback nên không còn danh mục thực hành. Khi cô hỏi xóa: giải thích ngừng sử dụng để giữ tham chiếu lịch sử; thử DELETE cha có con sẽ bị FK, không xóa dữ liệu thật để chứng minh.

V04a: `TienCong = -1` vi phạm `CK_DichVu_Gia`, lỗi 547. V04b: danh mục -1 không tồn tại, lỗi 547 từ FK. V04c: điện thoại trùng, lỗi 2601/2627. Nhìn **tên constraint** trong thông báo để phân biệt lỗi, không chỉ nhìn mã lỗi. TRY/CATCH xác nhận đúng lỗi dự kiến, rollback rồi trả kết quả đọc được.

### V05–V06: demo index có căn cứ

V05 cho cô xem index thật của HomeFix. Hai UNIQUE lọc trên lệnh điều phối vừa giúp tra cứu vừa ngăn một đơn/một thợ có hai phân công còn hiệu lực; không bỏ chúng khi thử nghiệm.

V06 dùng bảng tạm có cùng kiểu lọc đơn theo khách/trạng thái, 50.000 dòng để khác biệt dễ thấy:

1. Bật Ctrl+M. Chạy toàn bộ V06.
2. Hai SELECT trả cùng 50 dòng. Trước tạo index: dự kiến Clustered Index Scan. Sau tạo: dự kiến Index Seek.
3. Trong Messages đọc `logical reads` của hai SELECT. Lượt kiểm thử đã ghi nhận **1475 trang → 2 trang**; số có thể khác theo môi trường. Không lấy thời gian CPU 0 ms làm bằng chứng duy nhất.
4. Chỉ so sánh hai SELECT; chi phí dựng 50.000 dòng và CREATE INDEX là chi phí chuẩn bị riêng.
5. INCLUDE giúp đáp ứng cột cần trả mà không quay lại lấy dữ liệu gốc. Index nonclustered có khóa clustered Id đi kèm nên truy vấn này được bao phủ.

Nếu cô hỏi vì sao dùng bảng tạm: CSDL thật hiện ít đơn, Scan có thể hợp lý; không ép FORCESEEK hoặc xóa index đang bảo vệ nghiệp vụ để tạo kết quả mong muốn. Thí nghiệm minh họa cùng dạng truy vấn, không tuyên bố tăng tốc 737 lần cho toàn ứng dụng. Khóa đứng đầu index phải phù hợp điều kiện lọc; nhiều index làm INSERT/UPDATE/DELETE và lưu trữ tốn hơn.

## 5. Đỗ Anh Tuấn: view, function và báo cáo

### T01–T02: từ nhiều bảng thành kết quả dễ đọc

Mở `vw_DonHangTongHop` trong `03_view.sql`: JOIN dịch vụ/danh mục/khách là INNER JOIN vì đơn phải tham chiếu các dòng tồn tại. Thợ dùng LEFT JOIN vì đơn mới chưa có thợ. Nếu đổi LEFT thành INNER, đơn chưa phân công sẽ biến mất khỏi danh sách. View không mặc nhiên giới hạn theo từng khách; API còn lọc Id chủ đơn theo JWT.

T02 minh họa `WHERE` lọc dòng, `GROUP BY` gom dòng, `HAVING` lọc nhóm. `COUNT(*)` đếm cả dòng có cột NULL, `COUNT(cot)` bỏ NULL. Khi nối thêm chi tiết vật tư, một đơn có thể thành nhiều dòng; phải tổng hợp chi tiết trước hoặc đếm đúng khóa để tránh phóng đại số đơn/doanh thu.

`vw_DoanhThuNgay` dùng ngày Việt Nam từ thời gian UTC +7; tổng thu gồm COD/BANK và có thể có phí hủy. Tổng thu của hệ thống không đồng nghĩa tiền lãi. Hoa hồng tính trên tiền công và cần phân biệt phần đã đối soát. `TongTienDaThu` ở hiệu suất chỉ cộng đơn hoàn thành; đơn hủy có phí không được tính là sửa xong.

### T03: phải phân biệt đủ 6 hàm

| Hàm | Loại | Ý nghĩa và điểm cần giải thích |
|---|---|---|
| `fn_HoaHong` | Scalar | Nhận tiền công và phần trăm; `200000 * 15 / 100 = 30000` |
| `fn_TongTienDonHang` | Scalar | Ưu tiên nghiệm thu còn hiệu lực; nếu chưa có thì báo giá đã duyệt + bảng kê đang áp dụng; đơn hủy trả phí hủy |
| `fn_SoDuVi` | TVF | Tổng sổ cái có dấu, không có dòng trả 0 |
| `fn_DiemDanhGia` | TVF | Trung bình điểm, không có đánh giá trả 0 theo quy ước hiển thị |
| `fn_ThongKeDon` | TVF | Đếm toàn bộ/hoàn thành/hủy/đang xử lý, nhận khoảng ngày Việt Nam |
| `fn_HanBaoHanh` | TVF | Hạn lớn nhất từ vật tư có số tháng bảo hành, dựa trên nghiệm thu đã duyệt; không có trả NULL |

Scalar đặt trong SELECT; TVF đặt trong FROM hoặc APPLY và có thể nhận tham số từng dòng. Không gọi TVF như một số đơn lẻ. Hàm hiện tại chỉ đọc/tính, không sửa bảng, không mở transaction. SP gọi bằng EXEC và có thể trả nhiều tập kết quả; SP không được đặt thẳng trong FROM.

### T04–T06: tính tiền và tự viết SQL

Chỉ rõ `ThanhTien` và `TongTien` là cột tính toán PERSISTED, SQL tự tính; không INSERT tùy ý vào cột tính toán. KTV kê khai vật tư có đơn giá; khách không duyệt bảng kê riêng, chỉ kiểm tra/ký nghiệm thu cuối cùng. Bảng kê cũ vẫn giữ theo lần sửa, chỉ một bản đang áp dụng.

T05 chạy báo cáo với Id của giám đốc. T06 tự tạo view nhóm trạng thái và hàm hoa hồng ngắn để cô thấy cú pháp CREATE thực tế. DDL ở trong EXEC vì CREATE VIEW/FUNCTION phải đầu batch; đây là batch con cho đối tượng học tập, không phải cách backend nối chuỗi SQL. Sau rollback, hai OBJECT_ID đều NULL.

## 6. Bùi Nguyễn Duy Trung: SP và giao dịch nghiệp vụ

### D01–D02: đọc SP theo đúng thứ tự

Mở `sp_TaoDonHang`, giải thích:

1. Nhận tham số có kiểu; không ghép chuỗi từ input vào câu INSERT.
2. Ghi nhận `@@TRANCOUNT`. Chưa có giao dịch thì BEGIN; đã có thì SAVE TRANSACTION.
3. Kiểm tra tài khoản hoạt động, vai trò KH và ngữ cảnh SESSION_CONTEXT khi caller là `hf_*`.
4. Kiểm tra địa chỉ/mô tả/ngày hẹn, dịch vụ đang hoạt động và tệp thuộc đúng khách.
5. INSERT đơn và INSERT lịch sử trong cùng transaction. `SCOPE_IDENTITY()` lấy Id mới trong phạm vi hiện tại, không dùng MAX(Id).
6. Chỉ COMMIT khi SP tự mở giao dịch. CATCH rollback đúng phạm vi rồi THROW lại cho API xử lý.

D01 dùng actor ADMIN gọi nghiệp vụ chỉ dành KH nên bị 51003. Đây là kiểm tra quyền **nghiệp vụ trong SP**; bài A03/A04 mới là kiểm tra quyền **đối tượng của SQL Role**.

D02 tạo đơn, DPV báo giá, KH duyệt: `ChoTiepNhan → ChoDuyetSoBo → ChoPhanCong`, giá dự kiến 250.000đ. Mỗi bước đọc lại phiên bản của đúng đối tượng cần sửa. Sau rollback, đơn/báo giá/lịch sử thực hành cùng biến mất.

Luồng đầy đủ để trình bày: tạo đơn → báo giá sơ bộ → KH đồng ý → DPV phân công → KTV nhận → di chuyển → đến nơi → sửa → kê khai vật tư → lập nghiệm thu → KTV/KH ký → ghi nhận COD hoặc KT xác nhận BANK → hoàn thành → KT đối soát. Báo giá sơ bộ, bảng kê và nghiệm thu là ba chứng từ khác nhau.

### D03–D05: giao dịch, đồng thời và trigger

- **Atomicity:** các bước đơn/lịch sử, hoặc đối soát/ví/sổ cái cùng thành công hoặc cùng hủy.
- **Consistency:** CHECK/FK/UNIQUE/trigger cùng SP giữ các quy tắc hợp lệ.
- **Isolation:** khóa cập nhật và khóa giữ tới cuối transaction ngăn hai người cùng quyết định từ trạng thái/số dư đã cũ.
- **Durability:** thay đổi bền vững sau COMMIT ngoài cùng; SAVEPOINT không tạo giao dịch độc lập.

D03 giữ dòng bảng tạm trước savepoint, tạo đơn sau savepoint, rollback về điểm lưu rồi COMMIT. Kết quả: dòng tạm còn, đơn thử không còn. ROLLBACK toàn bộ sẽ hủy cả phần trước điểm lưu. `XACT_STATE()`: 1 còn commit được, -1 đã lỗi không thể commit/rollback về savepoint, 0 không có giao dịch. Khi -1 cần caller rollback toàn bộ.

D04 mô phỏng hai form đọc cùng phiên bản. DPV báo giá làm rowversion đổi; form cũ gửi phiên bản trước sẽ bị 51009. Cách xử lý là tải lại, không tự thay phiên bản nhằm ghi đè. Khóa là kiểm soát trong lúc thực thi; rowversion phát hiện dữ liệu form cũ từ trước khi request bắt đầu. Hai cách phục vụ hai thời điểm khác nhau.

D05 UPDATE hai đơn mới sang HoanThanh. CHECK chỉ biết HoanThanh là mã hợp lệ; trigger biết bước chuyển từ trạng thái cũ sang mới là sai, nên chặn cả câu lệnh. Trigger phải dùng inserted/deleted như tập hợp, không SELECT một giá trị bất kỳ từ inserted.

### D06–D08: những nghiệp vụ vừa được chỉnh lại

D06: chọn một đơn `DangXuLy` để thử vật tư/nghiệm thu, sau đó rollback. Nếu không có, thực hiện đúng tiến độ một đơn trên web; không UPDATE trạng thái trực tiếp để chuẩn bị. Tổng vật tư thử là 100.000đ; tổng nghiệm thu còn phí kiểm tra và tiền công. Vật tư đã dùng trong nghiệm thu bị khóa, muốn đổi phải tạo bảng kê phiên bản mới.

D07: đặt đơn chưa có phiếu hỗ trợ; chỉ EXEC `sp_TaoYeuCauHoTro` mới phát sinh. CSKH tiếp nhận trước, phản hồi rồi giải quyết; lưu lịch sử trạng thái và thời gian trong `TraoDoiHoTro`. Khách chỉ xem/gửi bổ sung; không có quyền đổi trạng thái xử lý. Mỗi lần thay đổi phải đọc rowversion mới.

D08: lấy đơn đang di chuyển/đã đến nơi. SQL tự lấy mức phí cấu hình và kiểm tra khách đã đồng ý đúng mức. Hủy lúc này lưu `PhiHuyDon`, chỉ BANK; thanh toán phí hủy không có nghiệm thu giả, không đổi đơn Huy sang HoanThanh. KT xác nhận BANK rồi đối soát cộng đủ phí cho thợ, hoa hồng 0. Trước di chuyển hủy miễn phí; đã bắt đầu sửa thì gửi CSKH.

## 7. Lê Tấn Tài: trigger, quyền, nâng cấp và phục hồi

### A01–A02: nắm được đủ 7 trigger

| Trigger | Khi chạy | Quy tắc cần giải thích |
|---|---|---|
| `tr_DonHang_KiemTraTrangThai` | AFTER INSERT/UPDATE | Trạng thái bắt đầu, bước chuyển, phải có thợ, hoàn thành phải có thanh toán; bảo vệ phí hủy |
| `tr_ThanhToan_KiemTraChungTu` | AFTER INSERT | Khớp nghiệm thu đã duyệt hoặc đúng phí hủy BANK của đơn Huy |
| `tr_ThanhToan_BatBien` | INSTEAD OF UPDATE/DELETE | Không sửa/xóa chứng từ thanh toán |
| `tr_GiaoDichVi_BatBien` | INSTEAD OF UPDATE/DELETE | Không sửa/xóa sổ cái |
| `tr_DanhGia_KiemTraDon` | AFTER INSERT/UPDATE | Đúng khách, đúng thợ, đơn hoàn thành |
| `tr_ChiTietVatTu_KhoaNghiemThu` | AFTER INSERT/UPDATE/DELETE | Không đổi chi tiết bảng kê đã được bất kỳ nghiệm thu nào tham chiếu |
| `tr_PhieuNghiemThu_KiemTraChuKy` | AFTER INSERT/UPDATE | Đúng thợ, chữ ký đúng chủ/đơn/mục đích |

AFTER không có nghĩa là dữ liệu đã COMMIT. Trigger vẫn trong cùng giao dịch của câu lệnh gọi. A02 dùng DBA thử sửa 2 dòng sổ cái; dù DBA qua được DENY, trigger vẫn chặn bằng 51009. Còn user KH thường bị 229 ngay tại kiểm tra quyền, chưa đến trigger.

### A03–A04: demo quyền trước/sau, không chỉ in danh sách quyền

A03 chạy trong một transaction để hoàn tác cấu hình quyền ở cuối:

1. GRANT SELECT view cho role KH, EXECUTE AS `hf_KH`: có dữ liệu, `HAS_PERMS_BY_NAME = 1`.
2. REVERT về DBA, REVOKE quyền, EXECUTE AS lại: `HAS_PERMS_BY_NAME = 0`, SELECT bị 229/230.
3. GRANT lại: SELECT chạy được.
4. DENY: SELECT bị chặn; REVERT và ROLLBACK khôi phục quyền ban đầu.

`GRANT` cấp; `REVOKE` xóa quyết định cấp/cấm trực tiếp; `DENY` cấm rõ ràng. REVOKE không bảo đảm mất quyền nếu user còn được cấp từ role khác. Ví dụ này đã kiểm tra trên cấu hình hiện tại; nếu nhóm tự cấp thêm quyền schema/database thì phải xét quyền kế thừa. DENY thường thắng GRANT theo quan hệ role, nhưng không dùng kết luận đó cho sysadmin, chủ sở hữu hoặc các ngoại lệ quyền theo cột.

A04 đọc được view không có hash, đọc bảng NguoiDung/MatKhauBam bị chặn. Ownership chain cùng dbo cho phép view/SP truy cập bảng bên trong mà không cần cấp quyền bảng cho người gọi. View thường không tự lọc chủ sở hữu: trong ứng dụng, backend còn lọc theo JWT; không tuyên bố hệ thống đang triển khai Row-Level Security.

Phần tiếp theo A04 GRANT/REVOKE **EXECUTE** báo cáo cho GD và gọi SP thực tế để chứng minh khác biệt. SESSION_CONTEXT giả lập Id đã xác thực; chạy trên kết nối SSMS mới, không dùng context read_only của một request web. Luôn REVERT, rollback và trả context về ban đầu.

7 role nghiệp vụ là KH, KTV, DPV, CSKH, KT, GD, ADMIN. Role `HomeFix_UngDung` chỉ là ngữ cảnh kỹ thuật đăng nhập trước khi có JWT, không phải bộ phận thứ tám. Windows DBA không phải tài khoản ứng dụng bị giới hạn; phải EXECUTE AS để minh chứng quyền của role.

### A05–A07: sổ cái và nâng cấp

Đối soát đọc đúng phiên bản và trạng thái Pending, khóa dòng đối soát/ví/yêu cầu rút; tính biến động; cập nhật ví; INSERT sổ cái; xác nhận đối soát trong cùng giao dịch. UNIQUE `(LoaiThamChieu, ThamChieuId)` ngăn ghi sổ cùng nghiệp vụ hai lần. A05 gọi lại một đối soát Confirmed, phải bị 51009. Không đủ ví COD cũng phải từ chối, không cộng tiền giả để làm demo chạy qua.

- COD 250.000đ, tiền công 200.000đ, hoa hồng 15%: thợ đã giữ tiền mặt; ví chỉ trừ 30.000đ.
- BANK cùng hóa đơn: ví cộng 250.000 - 30.000 = 220.000đ.
- Phí hủy 60.000đ: chỉ BANK, hoa hồng 0, cộng 60.000đ khi đối soát.

Module 09 dùng điều kiện kiểm tra tồn tại trước khi thêm/đổi cấu trúc, giữ Id và liên kết cũ. A06 kiểm tra các cột/bảng/index sau nâng cấp. `NghiemThuId` của phí hủy là NULL, nên UNIQUE có điều kiện NOT NULL thay cho UNIQUE toàn cột. Chạy `db:upgrade` để thực hiện đầy đủ chuỗi, không chạy riêng schema hay seed lên CSDL đang có dữ liệu. Bộ kiểm chứng đã nâng cấp hai lần trên bản sao và đối chiếu toàn bộ dòng trước/sau.

### A08: sao lưu và phục hồi thực tế

Chạy file `04b_SaoLuuPhucHoi.sql` đầy đủ. Script không chuyển recovery của bản gốc. Nó sao lưu COPY_ONLY bản gốc, tạo bản sao thực hành tên ngẫu nhiên, chuyển **bản sao** sang FULL rồi làm thí nghiệm:

| Mốc | Hành động | Dữ liệu trong bảng thực hành |
|---|---|---|
| 1 | Chèn dòng 1, backup FULL thường | 1 |
| 2 | Chèn dòng 2, backup DIFFERENTIAL | 1, 2 |
| 3 | Chèn dòng 3, backup LOG | 1, 2, 3 |
| 4 | Restore FULL → DIFF → LOG sang tên khác | Phải đủ 1, 2, 3 |

Lệnh cốt lõi cần tự giải thích khi cô yêu cầu viết:

```sql
-- Chạy trên CSDL thực hành ở recovery FULL đã có FULL nền.
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'<duong_dan_may_chu>\Full.bak', @Loai = 'FULL';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'<duong_dan_may_chu>\Diff.bak', @Loai = 'DIFF';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'<duong_dan_may_chu>\Log.trn', @Loai = 'LOG';
```

Đây là mẫu giải thích có chỗ thay đường dẫn; file 04b đã tự lấy đường dẫn hợp lệ, không cần gõ `<...>` vào SSMS. Trong file, nhìn các đoạn A08.3/A08.4 để chỉ đúng lệnh backup và restore. Nhiều dòng dựng chuỗi chỉ nhằm tạo tên/file riêng và dọn dẹp, không phải thuật toán nghiệp vụ mới.

- FULL chứa dữ liệu cần để khôi phục toàn bộ CSDL tại điểm backup. DIFF chứa phần thay đổi từ FULL nền gần nhất, không phải từ DIFF liền trước. LOG ghi các bản ghi log từ backup log trước trong chuỗi hợp lệ.
- COPY_ONLY FULL tạo bản sao độc lập, không đặt lại nền DIFF. Vì vậy FULL dùng làm nền trong thí nghiệm là FULL thường.
- SIMPLE không hỗ trợ backup LOG. Chuyển FULL rồi phải có full backup đầu tiên để khởi động chuỗi. Không đổi recovery của bản đang dùng chỉ để thử.
- FILELISTONLY lấy LogicalName. MOVE đặt đường dẫn data/log **mới**, không đụng file của bản gốc. HEADERONLY cho biết backup set; FILE=1 đúng khi mỗi lượt dùng file mới.
- NORECOVERY giữ trạng thái chờ nhận DIFF/LOG; RECOVERY bước cuối đưa DB online. Khôi phục riêng FULL thì dùng RECOVERY ngay, bỏ DIFF/LOG.
- VERIFYONLY chưa chứng minh dữ liệu phục hồi truy vấn được; phải RESTORE thật, đọc ba dòng và CHECKDB. File 04b đã thực hiện các bước này.
- BACKUP/RESTORE không nằm trong BEGIN TRANSACTION. Nếu muốn khôi phục đến một thời điểm trong recovery FULL, cần chuỗi log đủ và STOPAT ở RESTORE LOG thích hợp; nếu cần dữ liệu tới sát sự cố thì xem khả năng tail-log backup. Bài hiện tại phục hồi tới cuối LOG, không giả làm bài STOPAT.
- File `.bak/.trn` nằm trên máy chạy dịch vụ SQL Server; user Windows mở SSMS có quyền thư mục chưa đủ nếu service account không có quyền ghi.

Kết thúc, script tự gỡ **đúng hai DB thực hành vừa tạo**, giữ backup. Object Explorer Refresh vẫn chỉ còn hai DB HomeFix gốc. Không dùng DROP DATABASE hoặc WITH REPLACE trên bản gốc khi trình bày.

## 8. Phần chung: mỗi người cần trả lời được

| Câu hỏi | Trả lời ngắn, đúng với HomeFix |
|---|---|
| Vì sao database-first? | SP giữ kiểm tra/ghi nghiệp vụ tập trung; web gọi SP có tham số, đọc view/TVF. Role hạn chế quyền đối tượng; API và SP kiểm tra danh tính/phạm vi. |
| Constraint khác trigger? | Constraint phù hợp PK/FK/miền giá trị/duy nhất. Trigger kiểm tra quy tắc cần nhiều bảng hoặc trạng thái cũ–mới và chặn sửa chứng từ. |
| SP khác function/view? | SP gọi bằng EXEC, có thể ghi/giao dịch/nhiều resultset. View dùng như bảng không nhận tham số. Function nhận tham số, trả giá trị hoặc bảng, chỉ tính/đọc trong thiết kế này. |
| Trigger có tự COMMIT không? | Không; cùng giao dịch với câu DML. Một lỗi có thể làm hủy cả câu/giao dịch. |
| Tại sao không SELECT * trong mã ứng dụng? | Cột rõ ràng dễ kiểm soát hợp đồng và tránh lộ bí mật khi schema đổi. SELECT * trong bài demo TVF ít cột chỉ để quan sát, không đọc bảng mật khẩu. |
| UNIQUE có tạo index không? | PK/UNIQUE được SQL hỗ trợ bằng unique index; không tạo thêm index trùng. UNIQUE lọc cần CREATE UNIQUE INDEX ... WHERE. |
| Có index luôn Seek không? | Không; tùy độ chọn lọc, số dòng, thống kê và cột cần trả. Kế hoạch/IO là bằng chứng, không phải tên index. |
| Tại sao rowversion khác ngày? | Là dấu phiên bản 8 byte tự tăng để phát hiện cập nhật, không phải DATETIME. |
| Rollback có trả lại Id không? | Không; khoảng trống IDENTITY là bình thường. |
| Khi nào cần savepoint? | SP được gọi bên trong transaction của caller, cần rollback phần SP khi còn trạng thái giao dịch hợp lệ. |
| Tài khoản Admin web có phải SQL sysadmin? | Không. ADMIN là một role nghiệp vụ; sao lưu/restore do DBA SQL quản lý. |
| Bảng nào không được sửa/xóa lịch sử? | ThanhToan và GiaoDichVi có trigger bất biến. Vật tư đã tham chiếu nghiệm thu phải giữ; điều chỉnh bằng phiên bản/chứng từ mới. |

### Thử khóa với hai cửa sổ SSMS

Đây là bài học chung cho transaction. Chạy lúc không thao tác web; thử trên bản DBMS, không đổi dữ liệu. Mở hai cửa sổ cùng database, chạy A rồi ngay lập tức B. A giữ khóa 10 giây, B chờ tối đa 3 giây nên nhận 1222. Sau A rollback, chạy lại B sẽ lấy được dữ liệu.

```sql
-- CỬA SỔ A: chọn trọn khối, F5.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    SELECT Id, Ten FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = (SELECT MIN(Id) FROM dbo.DichVu);
    WAITFOR DELAY '00:00:10';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

```sql
-- CỬA SỔ B: chạy trong lúc A còn giữ khóa; thử lại sau khi A xong.
SET LOCK_TIMEOUT 3000;
BEGIN TRY
    BEGIN TRANSACTION;
    SELECT Id, Ten FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = (SELECT MIN(Id) FROM dbo.DichVu);
    ROLLBACK TRANSACTION;
    SELECT N'Lấy được khóa, truy vấn thành công' AS KetQua;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 1222 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, N'Bị chặn vì A đang giữ khóa' AS KetQua;
END CATCH;
SET LOCK_TIMEOUT -1;
```

UPDLOCK lấy khóa cập nhật, hai khóa cập nhật trên cùng tài nguyên không tương thích. HOLDLOCK tương đương SERIALIZABLE cho đối tượng/tham chiếu đó, giữ khóa đến cuối giao dịch; không phải chuyển isolation của toàn bộ ứng dụng. Bài này chỉ minh họa tranh chấp khóa, không tự nhận đã mô phỏng deadlock. Khi gặp deadlock 1205 thực tế, rollback/tải lại hoặc retry có giới hạn ở đơn vị giao dịch thích hợp; giảm thời gian giữ khóa, thống nhất thứ tự khóa và kiểm tra index.

### Lỗi nào là minh họa đúng, lỗi nào cần sửa?

| Mã | Tình huống | Xử lý đúng |
|---|---|---|
| 547 | CHECK hoặc FK | Đọc tên ràng buộc, sửa giá/Id; không tắt CHECK/FK |
| 2601/2627 | Trùng UNIQUE | Chọn giá trị không trùng hoặc giải thích chỉ một dòng hiệu lực |
| 229/230 | Thiếu quyền | Kiểm tra USER_NAME, role, grant/deny; REVERT về DBA sau demo |
| 51003 | Sai vai trò/chủ sở hữu/ngữ cảnh | Dùng đúng người, không giả actor |
| 51004 | Không tìm thấy dữ liệu | Kiểm tra Id, danh mục hoạt động |
| 51009 | Sai trạng thái/phiên bản/số dư/chứng từ | Đọc thông báo, tải dữ liệu mới hoặc thực hiện đúng bước trước |
| 1222 | Chờ khóa quá LOCK_TIMEOUT | Đợi giao dịch A kết thúc, chạy lại B |
| 3201/OS 3/OS 5 | Backup sai đường dẫn/quyền thư mục | Kiểm tra đường dẫn trên máy SQL và service account |
| 4214 | Backup LOG chưa có nền FULL | Kiểm tra FULL recovery và full backup đầu tiên |
| 3117/4305 | Sai trạng thái/thứ tự chuỗi phục hồi | Kiểm tra HEADERONLY, NORECOVERY và đủ các backup cần thiết |

Các bài lỗi dự kiến đã bắt lỗi và hiển thị ra Results. Nếu xuất hiện lỗi đỏ ngoài CATCH, không nói “demo thành công”: đọc lỗi, kiểm tra DB/ngữ cảnh/tham số trước.

## 9. Thứ tự trình bày trong khoảng 20–25 phút

1. **Việt (5 phút):** V01 một quan hệ, V03 một CRUD, V04a một lỗi CHECK, V06 index trước/sau.
2. **Tuấn (4 phút):** T01 view/JOIN, T03 scalar và TVF, T04 công thức tiền, T06 tự viết một đối tượng khi được hỏi.
3. **Trung (6 phút):** D02 giao dịch tạo đơn–báo giá, D03 savepoint, D04 phiên bản cũ, D05 trigger. Chuẩn bị D06–D08 để trả lời nghiệp vụ hiện tại.
4. **Tài (6 phút):** A02 bảo vệ sổ cái, A03 thu hồi/cấp quyền, A04 quyền SP, A08 chuỗi backup–restore. Dùng A06 giải thích migration khi cô hỏi cập nhật cấu trúc.
5. **Cả nhóm:** `@@TRANCOUNT = 0`, ví không lệch; đối chiếu thao tác web với SP/View của luồng vừa trình bày.

Trước khi nộp bảng phân công, từng người nên tự chạy ít nhất một lượt phần mình, tự đổi một tham số hợp lệ và giải thích được một trường hợp bị từ chối. Tài liệu là hướng dẫn thực hành; tỷ lệ hoàn thành/điểm do nhóm đánh giá sau lượt chạy đó.
