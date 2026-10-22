# HomeFix: cài đặt và đọc hiểu SQL

## 1. Chạy đúng database

Trên máy được bàn giao, chọn database **HomeFix_DBMS_Clean_20261022** trước khi chạy ví dụ. Bộ cài dùng tên mặc định khác để hỗ trợ cài mới trên máy khác.

Mở `CSDL_HomeFix.sql` trong SSMS, chọn Windows Authentication và tài khoản quản trị SQL Server. Bật **Query → SQLCMD Mode**, đọc phần đầu file, đổi biến `TenCSDL` nếu cần rồi chạy toàn bộ bằng F5. Bộ cài tạo database mới và từ chối tên đã tồn tại; không tự xóa dữ liệu cũ. Tên mặc định là `HomeFix_DBMS_Nhom08`. Nếu tên này đang được ứng dụng cũ sử dụng, chọn tên khác và cập nhật `DB_NAME` của backend theo hướng dẫn ở README chính.

Sau khi cài, chọn đúng database ở danh sách phía trên cửa sổ truy vấn. Không chạy lại seed lên database đã có tài khoản. `seed_data.sql` là bản seed riêng cho database đã tạo cấu trúc nhưng chưa có dữ liệu; nội dung giống module `08_seed.sql`.

| Module | Nội dung và cách hiểu |
|---|---|
| `00_schema.sql` | 28 bảng, khóa chính/ngoại, UNIQUE, CHECK, DEFAULT, cột tính toán, ROWVERSION |
| `01_index.sql` | Tra cứu nhanh và UNIQUE có điều kiện, ví dụ mỗi thợ chỉ có một phân công còn hiệu lực |
| `02_function.sql` | 2 hàm trả một giá trị và 4 hàm trả bảng, chỉ đọc/tính toán |
| `03_view.sql` | 34 view; định nghĩa cột được đọc, che mật khẩu khỏi các view nghiệp vụ |
| `04_sp.sql` | 19 thủ tục tài khoản, danh mục, OTP, tệp và cấu hình |
| `05_transaction.sql` | 26 thủ tục đặt đơn, điều phối, nghiệm thu, thanh toán, ví, hỗ trợ, báo cáo |
| `06_trigger.sql` | 7 trigger bảo vệ trạng thái/chứng từ, vật tư, chữ ký và đánh giá |
| `07_security.sql` | 7 role nghiệp vụ, user kiểm chứng quyền và role xác thực nội bộ |
| `08_seed.sql` | Dữ liệu khởi tạo sạch, không có giao dịch giả |
| `09_data_migration.sql` | Ghi chú chuyển đổi, không chạy lệnh chuyển giao dịch cũ vào bản sạch |
| `10_backup_recovery.sql` | Thủ tục sao lưu và các lệnh phục hồi có chú thích |

Thứ tự cài được bộ cài tổng hợp xử lý. Nếu mở từng module, phải chạy schema → index → function → view → thủ tục → trigger → security → seed. Backup module chỉ tạo thủ tục; chưa sao lưu ngay.

## 2. Tài khoản và dữ liệu ban đầu

Mật khẩu cả bảy tài khoản là **`123456`**, chỉ dùng cho bản học tập. Trong bảng chỉ lưu chuỗi băm bcrypt; giao diện đăng nhập nhận mật khẩu rõ rồi backend dùng bcrypt để đối chiếu.

| Số điện thoại | Vai trò | Công việc |
|---|---|---|
| `0900000001` | KH | Đặt đơn, duyệt giá/vật tư, ký nghiệm thu, hỗ trợ và đánh giá |
| `0900000002` | KTV | Nhận việc, cập nhật tiến độ, lập vật tư/nghiệm thu và yêu cầu ví |
| `0900000003` | DPV | Báo giá sơ bộ và phân công thợ |
| `0900000004` | CSKH | Xử lý phiếu hỗ trợ và trao đổi với khách |
| `0900000005` | KT | Xác nhận chuyển khoản, duyệt ví và đối soát |
| `0900000006` | GD | Xem báo cáo tổng hợp |
| `0900000007` | ADMIN | Tài khoản, vai trò, khóa/mở khóa, duyệt hồ sơ thợ và danh mục |

Seed có 5 nhóm Điện/Nước/Điện lạnh/Đồ gỗ/Khóa, mỗi nhóm một dịch vụ. Thợ có số dư **0**; tài khoản ngân hàng là mô phỏng, không chuyển tiền thật. Không có đơn, lịch sử đơn, thanh toán, giao dịch ví, OTP hoặc nhật ký được chèn sẵn.

```sql
SELECT Id, HoTen, SoDienThoai, VaiTro FROM dbo.vw_NguoiDung;
SELECT Id, TenDanhMuc, Ten, PhiKiemTra, TienCong FROM dbo.vw_DichVuCongKhai;
SELECT Id, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien;
SELECT TongDon, DonHoanThanh, DonHuy FROM dbo.fn_ThongKeDon(NULL, NULL);
SELECT dbo.fn_HoaHong(200000, 15) AS HoaHong; -- 30000; 15 là 15%
```

## 3. Cách giải thích những thành phần chính

**PK** định danh một dòng, **FK** bắt buộc dòng được tham chiếu tồn tại. `DonHang.KhachHangId` tham chiếu người dùng; thủ tục kiểm tra thêm người đó có vai trò KH. FK không tự kiểm tra được vai trò. Không dùng xóa dây chuyền cho chứng từ để tránh mất lịch sử.

**CHECK** kiểm tra điều kiện trên dòng: số dư không âm, điểm 1–5, tỷ lệ hoa hồng 0–100, số lượng vật tư dương. **UNIQUE** chống trùng số điện thoại, một thanh toán cho mỗi đơn, một đánh giá cho mỗi đơn. UNIQUE lọc chỉ xét các dòng thỏa điều kiện, ví dụ `DangHoatDong = 1` của lệnh điều phối. Vì vậy lịch sử điều phối cũ được giữ nhưng không thể phân hai đơn đồng thời cho cùng một thợ.

**DEFAULT** chỉ cấp giá trị khi INSERT bỏ qua cột; không tự cập nhật thời gian khi UPDATE. **Cột tính toán** lấy `SoLuong * DonGia` hoặc cộng các khoản tiền; backend không gửi tổng tiền tùy ý. Tiền dùng DECIMAL để tính chính xác theo thang số thập phân.

**ROWVERSION** là 8 byte tự thay đổi khi UPDATE, không phải ngày giờ. Khi mở form, web nhận `PhienBan`; khi lưu gửi lại `PhienBanDuKien`. Thủ tục khóa dòng bằng `UPDLOCK, HOLDLOCK`, so phiên bản, kiểm tra trạng thái rồi ghi. Phiên bản cũ bị từ chối để tránh người sau ghi đè quyết định của người trước.

**View** đóng gói một câu SELECT; **hàm scalar** trả một giá trị, ví dụ hoa hồng; **TVF** trả bảng, dùng trong FROM. `fn_SoDuVi` cộng sổ cái, `fn_DiemDanhGia` tính trung bình, `fn_HanBaoHanh` tìm hạn bảo hành từ vật tư nghiệm thu, `fn_ThongKeDon` thống kê theo ngày. `fn_TongTienDonHang` ưu tiên tiền nghiệm thu, nếu chưa có thì lấy báo giá và vật tư đã duyệt.

**Stored Procedure** nhận tham số có kiểu, kiểm tra người thực hiện/quyền sở hữu, trạng thái và dữ liệu rồi mới ghi. Ví dụ `sp_TaoBaoGiaSoBo` chỉ nhận DPV/ADMIN, đơn phải ở `ChoTiepNhan`, giá hợp lệ và phiên bản phải khớp. SP ghi báo giá, chuyển đơn sang `ChoDuyetSoBo` và lưu lịch sử trong cùng giao dịch.

**Transaction** bảo đảm nhiều thao tác cùng thành công hoặc cùng hủy. SP tự BEGIN/COMMIT nếu chưa có giao dịch; nếu bên ngoài đã mở thì chỉ SAVE TRANSACTION. Trong CATCH, `XACT_STATE() = 1` còn quay về savepoint được; `-1` là giao dịch không còn khả năng COMMIT, bên sở hữu giao dịch phải ROLLBACK toàn bộ. `XACT_ABORT ON` làm các lỗi ghi dữ liệu nghiêm trọng hủy khả năng COMMIT, không được cố COMMIT tiếp.

**Trigger** tự chạy khi bảng bị tác động. `inserted`/`deleted` chứa nhiều dòng, vì vậy code dùng EXISTS/JOIN, không gán tùy tiện một dòng vào biến. Trigger chặn chuyển trạng thái sai, thanh toán lệch nghiệm thu, sửa/xóa sổ cái hoặc thanh toán, sửa chi tiết vật tư đã duyệt, đánh giá sai chủ đơn và chữ ký sai người/đơn. Trigger kiểm tra quy tắc; SP vẫn chịu trách nhiệm lưu lịch sử và điều phối nghiệp vụ.

## 4. Demo luồng SQL và tự hoàn tác

Chạy **nguyên khối** bên dưới trong database vừa cài. Mọi thay đổi nằm trong một giao dịch ngoài và cuối cùng ROLLBACK, nên dữ liệu khởi tạo vẫn sạch. Các Id được tra từ view, không giả định luôn bằng 1/2/3.

```sql
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @KH INT, @DPV INT, @KTV INT, @DV INT, @Don INT, @BaoGia INT, @Lenh INT;
    DECLARE @PB BINARY(8), @Dau NVARCHAR(100) = N'Demo SSMS ' + CONVERT(NVARCHAR(36), NEWID());
    SELECT @KH = Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900000001';
    SELECT @KTV = Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900000002';
    SELECT @DPV = Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900000003';
    SELECT TOP (1) @DV = Id FROM dbo.vw_DichVuCongKhai ORDER BY Id;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @KH, @DichVuId = @DV,
        @DiaChi = N'01 Võ Văn Ngân, Thành phố Hồ Chí Minh', @MoTa = @Dau;
    SELECT @Don = Id, @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE KhachHangId = @KH AND MoTa = @Dau;
    EXEC dbo.sp_TaoBaoGiaSoBo @NguoiThucHienId = @DPV, @DonHangId = @Don,
        @PhiKiemTra = 50000, @TienCong = 200000, @TyLeHoaHong = 15,
        @ChanDoan = N'Kiểm tra và sửa công tắc bị hỏng', @PhienBanDuKien = @PB;
    SELECT @BaoGia = Id, @PB = PhienBan FROM dbo.vw_BaoGiaSoBo WHERE DonHangId = @Don;
    EXEC dbo.sp_KhachDuyetBaoGiaSoBo @NguoiThucHienId = @KH, @BaoGiaId = @BaoGia,
        @QuyetDinh = 'Approved', @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_TaoLenhDieuPhoi @NguoiThucHienId = @DPV, @DonHangId = @Don,
        @KyThuatVienId = @KTV, @PhienBanDuKien = @PB;
    SELECT @Lenh = Id, @PB = PhienBan FROM dbo.vw_LenhDieuPhoi WHERE DonHangId = @Don AND DangHoatDong = 1;
    EXEC dbo.sp_KTVPhanHoiDieuPhoi @NguoiThucHienId = @KTV, @LenhDieuPhoiId = @Lenh,
        @QuyetDinh = 'Accepted', @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @KTV, @DonHangId = @Don,
        @TrangThaiTiepTheo = 'DangDiChuyen', @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @KTV, @DonHangId = @Don,
        @TrangThaiTiepTheo = 'DaDenNoi', @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @KTV, @DonHangId = @Don,
        @TrangThaiTiepTheo = 'DangXuLy', @PhienBanDuKien = @PB;
    SELECT Id, TrangThai, TenKhachHang, TenKyThuatVien, TongTien FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    SELECT TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo FROM dbo.vw_LichSuDonHang WHERE DonHangId = @Don ORDER BY Id;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS NoiDung;
END CATCH;
```

Nếu thợ đang có đơn, thủ tục phân công sẽ báo lỗi thay vì phá dữ liệu. Dùng database seed mới để luyện. ROLLBACK không thu hồi số IDENTITY đã cấp nên Id có thể nhảy số; đây là hành vi bình thường, không phải mất đơn đã lưu. Muốn tiếp tục luồng từ trình duyệt, thực hiện lại các bước bằng giao diện để lưu thật: KTV lập vật tư → KH duyệt → KTV tạo và ký nghiệm thu → KH ký, chọn COD/BANK → ghi nhận tiền thực thu → KT đối soát. Chữ ký/chứng từ phải là tệp upload thật, đúng chủ sở hữu và đơn hàng; không tự INSERT metadata để giả lập tệp còn thiếu.

COD trừ hoa hồng từ ví KTV khi KT đối soát, vì vậy cần KTV gửi yêu cầu nạp ví và KT duyệt trước. BANK do KT xác nhận đúng số tiền/tham chiếu; đối soát ghi khoản được nhận theo quy tắc trong `sp_DoiSoatCOD`. Mỗi tham chiếu sổ cái là duy nhất, ngăn ghi tiền hai lần. Dùng view ví để so `SoDu` với `SoDuSoCai`; `ChenhLech` phải bằng 0.

## 5. Demo lỗi trigger, quyền và cách đọc lỗi

Đây là thao tác **DBA trong SSMS để chứng minh trigger**, không phải SQL chạy từ backend. Đơn vừa tạo chưa có báo giá/phân công/thanh toán nên không thể nhảy thẳng tới hoàn thành. Giao dịch sẽ hủy; CATCH hiển thị lỗi dự kiến.

```sql
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @KH INT, @DV INT, @Don INT, @Dau NVARCHAR(100) = CONVERT(NVARCHAR(36), NEWID());
    SELECT @KH = Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900000001';
    SELECT TOP (1) @DV = Id FROM dbo.vw_DichVuCongKhai ORDER BY Id;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @KH, @DichVuId = @DV, @DiaChi = N'Địa chỉ demo', @MoTa = @Dau;
    SELECT @Don = Id FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau AND KhachHangId = @KH;
    UPDATE dbo.DonHang SET TrangThai = 'HoanThanh' WHERE Id = @Don; -- dự kiến lỗi 51009
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS GiaiThich;
END CATCH;
```

```sql
EXECUTE AS USER = 'hf_KH';
SELECT Id, HoTen, VaiTro FROM dbo.vw_NguoiDung; -- được đọc cột công khai
BEGIN TRY
    SELECT Id FROM dbo.NguoiDung; -- lỗi 229: role không được đọc bảng gốc
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS GiaiThich;
END CATCH;
REVERT; -- bắt buộc trả lại quyền ban đầu
```

Bảy role `HomeFix_KH/KTV/DPV/CSKH/KT/GD/ADMIN` chỉ được EXECUTE các SP phù hợp, SELECT các view/TVF cần dùng; không có GRANT CRUD bảng. Có DENY cột `MatKhauBam` và cấm sửa/xóa `GiaoDichVi`. Role thứ tám `HomeFix_UngDung` chỉ phục vụ bước đăng nhập/OTP trước khi có JWT, được đọc view xác thực có hash; đây không phải vai trò nhân viên thứ tám. `hf_*` là user WITHOUT LOGIN để ứng dụng/demo mượn quyền; không phải bảy tài khoản web có mật khẩu.

Backend kiểm tra JWT và lọc đơn theo chủ sở hữu; mỗi request đăng nhập đặt Id vào SESSION_CONTEXT và chạy trong ngữ cảnh role tương ứng. SP đối chiếu Id tham số với ngữ cảnh đó và vai trò thực tế, chặn giả mạo actor. Quyền role SQL giới hạn loại đối tượng, không tự lọc từng dòng theo khách hàng. Không cấp tài khoản SQL hoặc quyền IMPERSONATE cho người dùng web. Ownership chain cho phép View/SP cùng chủ dbo truy cập bảng nội bộ dù caller bị cấm đọc/ghi trực tiếp.

Mã lỗi 51003 là thiếu quyền; 51004 là không tìm thấy; 51009 là dữ liệu/trạng thái/phiên bản không hợp lệ; 229 là SQL Server từ chối quyền đối tượng. Khi web báo dữ liệu đã thay đổi, tải lại trang rồi lấy phiên bản mới; không bỏ điều kiện phiên bản. FK lỗi 547: kiểm tra Id được tham chiếu có tồn tại. UNIQUE lỗi 2601/2627: kiểm tra dữ liệu trùng. Luôn đọc dòng `ERROR_MESSAGE()` trước khi sửa SQL.

## 6. Backup và phục hồi

Mở `modules/10_backup_recovery.sql`, đọc ví dụ cuối file và chạy từng khối sau khi đổi tên/đường dẫn. Chạy bằng tài khoản quản trị SQL Server, không phải role ADMIN của web. Có thể lấy thư mục mặc định bằng:

```sql
SELECT SERVERPROPERTY('InstanceDefaultBackupPath') AS ThuMucBackup;
SELECT name, recovery_model_desc FROM sys.databases WHERE name = DB_NAME();
-- Đổi đường dẫn cho đúng máy chủ, dùng tên file mới mỗi lần.
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Full_Lan1.bak', @Loai = 'FULL';
RESTORE HEADERONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_Lan1.bak';
RESTORE VERIFYONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_Lan1.bak' WITH FILE = 1, CHECKSUM;
```

FULL là bản đầy đủ; DIFF chứa phần thay đổi từ FULL thường gần nhất; LOG lưu phần nhật ký và cần recovery model FULL cùng chuỗi backup hợp lệ. COPY_ONLY FULL dùng làm bản độc lập, không tạo nền mới cho DIFF. Thủ tục dùng NOINIT nên nếu trùng tên file sẽ thêm backup set: xem Position bằng HEADERONLY và chọn đúng `FILE`, không mặc định bản mới nhất luôn là 1.

**BACKUP/RESTORE bị SQL Server cấm chạy trong BEGIN TRANSACTION.** Vì vậy SP sao lưu dùng TRY/CATCH và kiểm tra quyền, không mở giao dịch CRUD. Khôi phục từ `master` sang **tên database mới**, dùng `MOVE` theo logical name từ FILELISTONLY; phục hồi FULL → DIFF → LOG, NORECOVERY cho các bước trung gian và RECOVERY ở bước cuối. Không dùng WITH REPLACE để ghi đè bản đang chạy. Sau phục hồi, chạy `DBCC CHECKDB` và đọc lại view người dùng/đơn/ví để kiểm chứng. VERIFYONLY chỉ kiểm tra bản sao đọc được, không thay thế việc phục hồi thử.

Sai đường dẫn/thiếu quyền thư mục thường báo 3201 hoặc OS error 3/5: thư mục phải có trên **máy SQL Server**, service account SQL có quyền ghi. Lỗi LOG 4214: chưa có FULL đầu tiên. Lỗi 4305/3117: thiếu/sai thứ tự chuỗi backup. Hướng dẫn đầy đủ có sẵn ở cuối module, gồm các lệnh RESTORE không tự chạy khi cài.
