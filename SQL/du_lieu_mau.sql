USE [HomeFix_DBMS_Clean_20261022];
GO
/* BỔ SUNG DỮ LIỆU MINH HỌA HOMEFIX
   Chạy trên database đã cài cấu trúc; không xóa/sửa giao dịch hiện có.
   Tên, địa chỉ và SĐT dưới đây là dữ liệu giả lập cho bài học.
   Mật khẩu tài khoản bổ sung: 123456. Bản ghi ảnh/chữ ký/chứng từ là giả lập phục vụ truy vấn SQL.
   Không kèm tập tin ảnh; giữ bản ghi để thể hiện quan hệ chứng từ và chữ ký.
   Khi chạy riêng trong SSMS: chọn HomeFix_DBMS_Clean_20261022 ở danh sách database.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

IF EXISTS (SELECT 1 FROM dbo.CauHinh WHERE Khoa = 'DuLieuMinhHoa20261023')
BEGIN
    PRINT N'Bộ dữ liệu minh họa đã có. Không chèn trùng, không sửa đơn đã demo.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Admin INT, @DieuPhoi INT, @KeToan INT, @NganHang INT;
    SELECT @Admin = MIN(Id) FROM dbo.NguoiDung WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1;
    SELECT @DieuPhoi = MIN(Id) FROM dbo.NguoiDung WHERE VaiTro = 'DPV' AND DangHoatDong = 1;
    SELECT @KeToan = MIN(Id) FROM dbo.NguoiDung WHERE VaiTro = 'KT' AND DangHoatDong = 1;
    SELECT @NganHang = MIN(Id) FROM dbo.TaiKhoanNganHang WHERE DangHoatDong = 1;
    IF @Admin IS NULL OR @DieuPhoi IS NULL OR @KeToan IS NULL OR @NganHang IS NULL
        THROW 51009, N'Cần có ADMIN, DPV, KT và tài khoản ngân hàng đang hoạt động trước khi tạo dữ liệu.', 1;

    DECLARE @MatKhauBam VARCHAR(100) = '$2b$10$6R3Jy/EiVEhpVTLlbrO1SuUsl9VMoJuAolWgiIYQ7V/1s0XW8OxHS';
    DECLARE @NguoiMau TABLE (Stt INT PRIMARY KEY, HoTen NVARCHAR(120), SDT VARCHAR(15), VaiTro VARCHAR(10), DiaChi NVARCHAR(500), TayNghe NVARCHAR(200));
    INSERT INTO @NguoiMau(Stt, HoTen, SDT, VaiTro, DiaChi, TayNghe)
    VALUES (1, N'Nguyễn Minh Anh', '0900001001', 'KH', N'24 Võ Văn Ngân, phường Linh Chiểu, TP. Hồ Chí Minh', NULL),
           (2, N'Trần Thu Hà', '0900001002', 'KH', N'56 Hoàng Diệu 2, phường Linh Trung, TP. Hồ Chí Minh', NULL),
           (3, N'Lê Hoàng Nam', '0900001003', 'KH', N'18 Đặng Văn Bi, phường Bình Thọ, TP. Hồ Chí Minh', NULL),
           (4, N'Phạm Ngọc Lan', '0900001004', 'KH', N'72 Lê Văn Việt, phường Hiệp Phú, TP. Hồ Chí Minh', NULL),
           (5, N'Võ Quốc Huy', '0900001005', 'KH', N'35 Dương Văn Cam, phường Linh Tây, TP. Hồ Chí Minh', NULL),
           (6, N'Đặng Văn Dũng', '0900002001', 'KTV', N'12 Kha Vạn Cân, TP. Hồ Chí Minh', N'DIEN'),
           (7, N'Bùi Thành Đạt', '0900002002', 'KTV', N'48 Tô Ngọc Vân, TP. Hồ Chí Minh', N'DIEN_LANH'),
           (8, N'Nguyễn Đức Long', '0900002003', 'KTV', N'29 Đỗ Xuân Hợp, TP. Hồ Chí Minh', N'DO_GO');

    IF EXISTS (SELECT 1 FROM dbo.NguoiDung nd INNER JOIN @NguoiMau m ON m.SDT = nd.SoDienThoai)
        THROW 51009, N'SĐT của bộ dữ liệu minh họa đã tồn tại. Không ghi đè tài khoản hiện có.', 1;
    DECLARE @Stt INT = 1, @HoTen NVARCHAR(120), @SDT VARCHAR(15), @VaiTro VARCHAR(10), @DiaChi NVARCHAR(500), @TayNghe NVARCHAR(200), @NguoiId INT, @PhienBanTho BINARY(8);
    WHILE @Stt <= 8
    BEGIN
        SELECT @HoTen = HoTen, @SDT = SDT, @VaiTro = VaiTro, @DiaChi = DiaChi, @TayNghe = TayNghe FROM @NguoiMau WHERE Stt = @Stt;
        IF @VaiTro = 'KH'
            EXEC dbo.sp_DangKyKhachHang @HoTen = @HoTen, @SoDienThoai = @SDT, @MatKhauBam = @MatKhauBam;
        ELSE
            EXEC dbo.sp_TaoTaiKhoanNoiBo @NguoiThucHienId = @Admin, @HoTen = @HoTen, @SoDienThoai = @SDT, @MatKhauBam = @MatKhauBam, @VaiTro = @VaiTro;
        SELECT @NguoiId = Id FROM dbo.NguoiDung WHERE SoDienThoai = @SDT;
        EXEC dbo.sp_CapNhatThongTinNguoiDung @NguoiThucHienId = @NguoiId, @HoTen = @HoTen, @DiaChi = @DiaChi;
        IF @VaiTro = 'KTV'
        BEGIN
            EXEC dbo.sp_CapNhatTho @NguoiThucHienId = @NguoiId, @NhomTayNghe = @TayNghe, @KhuVucPhucVu = N'TP. Hồ Chí Minh';
            SELECT @PhienBanTho = PhienBan FROM dbo.KyThuatVien WHERE Id = @NguoiId;
            EXEC dbo.sp_CapNhatTrangThaiKTV @NguoiThucHienId = @NguoiId, @TrangThaiSanSang = 'SanSang', @PhienBanDuKien = @PhienBanTho;
        END;
        SET @Stt += 1;
    END;

    DECLARE @DichVuMau TABLE (Stt INT PRIMARY KEY, MaNhom VARCHAR(20), Ten NVARCHAR(200), MoTa NVARCHAR(1000), Phi DECIMAL(18,2), Cong DECIMAL(18,2));
    INSERT INTO @DichVuMau(Stt, MaNhom, Ten, MoTa, Phi, Cong)
    VALUES (1, 'DIEN', N'Thay ổ cắm điện', N'Kiểm tra tiếp điểm, thay ổ cắm và thử tải.', 50000, 120000),
           (2, 'DIEN', N'Lắp đèn chiếu sáng', N'Lắp đèn LED, kiểm tra công tắc và đấu nối.', 50000, 150000),
           (3, 'DIEN', N'Thay aptomat gia đình', N'Kiểm tra tải và thay thiết bị bảo vệ điện.', 60000, 200000),
           (4, 'DIEN', N'Kiểm tra chập điện', N'Tìm vị trí chạm chập và xử lý đường dây.', 80000, 250000),
           (5, 'NUOC', N'Thay vòi nước', N'Tháo vòi cũ, lắp vòi mới và kiểm tra rò rỉ.', 50000, 100000),
           (6, 'NUOC', N'Thông tắc bồn rửa', N'Kiểm tra và thông đường thoát nước bồn rửa.', 50000, 180000),
           (7, 'NUOC', N'Sửa bồn cầu rò nước', N'Kiểm tra bộ xả, phao nước và van cấp.', 60000, 180000),
           (8, 'NUOC', N'Sửa đường ống rò rỉ', N'Xác định vị trí rò và thay đoạn ống hư.', 60000, 220000),
           (9, 'DIEN_LANH', N'Vệ sinh máy lạnh treo tường', N'Vệ sinh dàn lạnh, dàn nóng và kiểm tra vận hành.', 50000, 200000),
           (10, 'DIEN_LANH', N'Sửa máy lạnh không mát', N'Kiểm tra quạt, điện và áp suất môi chất.', 80000, 300000),
           (11, 'DIEN_LANH', N'Vệ sinh máy giặt', N'Vệ sinh lồng giặt và kiểm tra cấp thoát nước.', 50000, 250000),
           (12, 'DIEN_LANH', N'Kiểm tra tủ lạnh', N'Kiểm tra nguồn, cảm biến và khả năng làm lạnh.', 70000, 250000),
           (13, 'DO_GO', N'Thay bản lề tủ', N'Cân chỉnh cánh tủ và thay bản lề phù hợp.', 40000, 120000),
           (14, 'DO_GO', N'Sửa ray ngăn kéo', N'Kiểm tra độ lệch và thay bộ ray ngăn kéo.', 40000, 150000),
           (15, 'DO_GO', N'Cân chỉnh cửa gỗ', N'Xử lý cửa cạ sàn, xệ bản lề và khó đóng.', 50000, 200000),
           (16, 'DO_GO', N'Gia cố bàn ghế gỗ', N'Kiểm tra mối nối và gia cố phần lỏng.', 50000, 180000),
           (17, 'KHOA', N'Thay ruột khóa cửa', N'Thay ruột khóa và kiểm tra chìa, chốt khóa.', 50000, 150000),
           (18, 'KHOA', N'Lắp khóa tay gạt', N'Lắp bộ khóa tay gạt cho cửa gia đình.', 60000, 200000),
           (19, 'KHOA', N'Sửa khóa cửa kẹt', N'Kiểm tra cơ cấu khóa và chỉnh chốt bị kẹt.', 50000, 180000),
           (20, 'KHOA', N'Bảo dưỡng khóa cửa', N'Vệ sinh và kiểm tra hoạt động của bộ khóa.', 40000, 100000);

    DECLARE @NhomId INT, @TenDichVu NVARCHAR(200), @MoTa NVARCHAR(1000), @Phi DECIMAL(18,2), @Cong DECIMAL(18,2);
    SET @Stt = 1;
    WHILE @Stt <= 20
    BEGIN
        SELECT @NhomId = dm.Id, @TenDichVu = m.Ten, @MoTa = m.MoTa, @Phi = m.Phi, @Cong = m.Cong
        FROM @DichVuMau m INNER JOIN dbo.DanhMucDichVu dm ON dm.Ma = m.MaNhom WHERE m.Stt = @Stt;
        IF NOT EXISTS (SELECT 1 FROM dbo.DichVu WHERE DanhMucId = @NhomId AND Ten = @TenDichVu)
            EXEC dbo.sp_LuuDichVu @NguoiThucHienId = @Admin, @DanhMucId = @NhomId, @Ten = @TenDichVu, @MoTa = @MoTa, @PhiKiemTra = @Phi, @TienCong = @Cong, @TyLeHoaHong = 15, @DangHoatDong = 1;
        SET @Stt += 1;
    END;

    -- Mỗi ví có chứng từ nạp và quyết định duyệt; không sửa trực tiếp SoDu.
    DECLARE @ThoId INT, @TepId INT, @YeuCauId INT, @PhienBan BINARY(8), @KhoaTep NVARCHAR(255);
    SET @Stt = 6;
    WHILE @Stt <= 8
    BEGIN
        SELECT @ThoId = nd.Id FROM dbo.NguoiDung nd INNER JOIN @NguoiMau m ON m.SDT = nd.SoDienThoai WHERE m.Stt = @Stt;
        SET @KhoaTep = CONVERT(VARCHAR(36), NEWID()) + '.png';
        EXEC dbo.sp_LuuTepDinhKem @NguoiThucHienId = @ThoId, @MucDich = 'WalletProof', @KhoaLuuTru = @KhoaTep, @TenTepGoc = N'Chứng từ nạp ví minh họa.png', @KieuMIME = 'image/png', @KichThuoc = 19517;
        SELECT @TepId = Id FROM dbo.TepDinhKem WHERE KhoaLuuTru = @KhoaTep;
        EXEC dbo.sp_TaoYeuCauVi @NguoiThucHienId = @ThoId, @Loai = 'Deposit', @SoTien = 1000000, @GhiChu = N'Nạp ví minh họa, không chuyển tiền thật.', @ChungTuId = @TepId;
        SELECT TOP (1) @YeuCauId = Id, @PhienBan = PhienBan FROM dbo.YeuCauVi WHERE KyThuatVienId = @ThoId ORDER BY Id DESC;
        EXEC dbo.sp_DuyetYeuCauVi @NguoiThucHienId = @KeToan, @YeuCauViId = @YeuCauId, @QuyetDinh = 'Approved', @PhienBanDuKien = @PhienBan;
        SET @Stt += 1;
    END;

    DECLARE @KeHoach TABLE (Stt INT PRIMARY KEY, KhachSDT VARCHAR(15), ThoSDT VARCHAR(15), DichVu NVARCHAR(200), Dich VARCHAR(30), PTTT VARCHAR(4), DonId INT);
    INSERT INTO @KeHoach(Stt, KhachSDT, ThoSDT, DichVu, Dich, PTTT)
    VALUES (1, '0900001001', '0900002001', N'Thay ổ cắm điện', 'HoanThanh', 'COD'),
           (2, '0900001002', '0900002002', N'Vệ sinh máy lạnh treo tường', 'HoanThanh', 'BANK'),
           (3, '0900001003', '0900002003', N'Cân chỉnh cửa gỗ', 'HoanThanh', 'COD'),
           (4, '0900001004', NULL, N'Cân chỉnh cửa gỗ', 'Huy', NULL),
           (5, '0900001005', NULL, N'Thông tắc bồn rửa', 'ChoDuyetSoBo', NULL),
           (6, '0900001001', NULL, N'Lắp đèn chiếu sáng', 'ChoPhanCong', NULL),
           (7, '0900001002', '0900002001', N'Thay aptomat gia đình', 'ChoNhan', NULL),
           (8, '0900001003', '0900002002', N'Sửa máy lạnh không mát', 'DangXuLy', NULL),
           (9, '0900001004', '0900002003', N'Thay bản lề tủ', 'ChoNghiemThu', NULL),
           (10, '0900001005', NULL, N'Bảo dưỡng khóa cửa', 'ChoTiepNhan', NULL);

    DECLARE @KhachId INT, @DichVuId INT, @DonId INT, @BaoGiaId INT, @LenhId INT, @NghiemThuId INT;
    DECLARE @Dich VARCHAR(30), @PTTT VARCHAR(4), @DanhGia INT, @TongTien DECIMAL(18,2), @ChuKyTho INT, @ChuKyKhach INT, @AnhId INT;
    DECLARE @AnhJSON NVARCHAR(MAX), @ThamChieu VARCHAR(100), @Hen DATETIME2;
    SET @Stt = 1;
    WHILE @Stt <= 10
    BEGIN
        SELECT @KhachId = kh.Id, @ThoId = tho.Id, @DichVuId = dv.Id, @Dich = m.Dich, @PTTT = m.PTTT, @DiaChi = kh.DiaChi,
               @Phi = dv.PhiKiemTra, @Cong = dv.TienCong
        FROM @KeHoach m INNER JOIN dbo.NguoiDung kh ON kh.SoDienThoai = m.KhachSDT
        INNER JOIN dbo.DichVu dv ON dv.Ten = m.DichVu
        LEFT JOIN dbo.NguoiDung tho ON tho.SoDienThoai = m.ThoSDT WHERE m.Stt = @Stt;
        SET @MoTa = N'[MINHHOA-' + RIGHT('00' + CONVERT(VARCHAR(2), @Stt), 2) + N'] Thiết bị gặp sự cố, khách đề nghị kiểm tra tại nhà.';
        SET @Hen = DATEADD(DAY, 1, SYSUTCDATETIME());
        EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @KhachId, @DichVuId = @DichVuId, @DiaChi = @DiaChi, @MoTa = @MoTa, @NgayHen = @Hen;
        SELECT @DonId = MAX(Id) FROM dbo.DonHang WHERE KhachHangId = @KhachId AND MoTa = @MoTa;
        UPDATE @KeHoach SET DonId = @DonId WHERE Stt = @Stt;
        IF @Dich = 'ChoTiepNhan' BEGIN SET @Stt += 1; CONTINUE; END;
        IF @Dich = 'Huy'
        BEGIN
            SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
            EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @KhachId, @DonHangId = @DonId, @TrangThaiTiepTheo = 'Huy', @PhienBanDuKien = @PhienBan, @LyDo = N'Khách thay đổi lịch sinh hoạt, hủy trước khi phân công.';
            SET @Stt += 1; CONTINUE;
        END;
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_TaoBaoGiaSoBo @NguoiThucHienId = @DieuPhoi, @DonHangId = @DonId, @PhiKiemTra = @Phi, @TienCong = @Cong, @TyLeHoaHong = 15, @ChanDoan = N'Kiểm tra và xử lý theo mô tả của khách; vật tư phát sinh sẽ báo riêng.', @PhienBanDuKien = @PhienBan;
        IF @Dich = 'ChoDuyetSoBo' BEGIN SET @Stt += 1; CONTINUE; END;
        SELECT @BaoGiaId = Id, @PhienBan = PhienBan FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonId;
        EXEC dbo.sp_KhachDuyetBaoGiaSoBo @NguoiThucHienId = @KhachId, @BaoGiaId = @BaoGiaId, @QuyetDinh = 'Approved', @PhienBanDuKien = @PhienBan;
        IF @Dich = 'ChoPhanCong' BEGIN SET @Stt += 1; CONTINUE; END;
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_TaoLenhDieuPhoi @NguoiThucHienId = @DieuPhoi, @DonHangId = @DonId, @KyThuatVienId = @ThoId, @PhienBanDuKien = @PhienBan;
        IF @Dich = 'ChoNhan' BEGIN SET @Stt += 1; CONTINUE; END;
        SELECT @LenhId = Id, @PhienBan = PhienBan FROM dbo.LenhDieuPhoi WHERE DonHangId = @DonId AND DangHoatDong = 1;
        EXEC dbo.sp_KTVPhanHoiDieuPhoi @NguoiThucHienId = @ThoId, @LenhDieuPhoiId = @LenhId, @QuyetDinh = 'Accepted', @PhienBanDuKien = @PhienBan;
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @TrangThaiTiepTheo = 'DangDiChuyen', @PhienBanDuKien = @PhienBan;
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @TrangThaiTiepTheo = 'DaDenNoi', @PhienBanDuKien = @PhienBan;
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @TrangThaiTiepTheo = 'DangXuLy', @PhienBanDuKien = @PhienBan;

        IF @Stt IN (1, 2, 8)
        BEGIN
            SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
            EXEC dbo.sp_LuuBangKeVatTu @NguoiThucHienId = @ThoId, @DonHangId = @DonId,
                @VatTu = N'[{"Ten":"Linh kiện thay thế minh họa","SoLuong":1,"DonGia":150000,"SoThangBaoHanh":6}]', @PhienBanDuKien = @PhienBan;
            IF @Dich = 'DangXuLy' BEGIN SET @Stt += 1; CONTINUE; END;
        END;
        SET @KhoaTep = CONVERT(VARCHAR(36), NEWID()) + '.png';
        EXEC dbo.sp_LuuTepDinhKem @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @MucDich = 'TechnicianSignature', @KhoaLuuTru = @KhoaTep, @TenTepGoc = N'Chữ ký thợ minh họa.png', @KieuMIME = 'image/png', @KichThuoc = 19517;
        SELECT @ChuKyTho = Id FROM dbo.TepDinhKem WHERE KhoaLuuTru = @KhoaTep;
        SET @KhoaTep = CONVERT(VARCHAR(36), NEWID()) + '.png';
        EXEC dbo.sp_LuuTepDinhKem @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @MucDich = 'AcceptancePhoto', @KhoaLuuTru = @KhoaTep, @TenTepGoc = N'Ảnh thiết bị minh họa.png', @KieuMIME = 'image/png', @KichThuoc = 19517;
        SELECT @AnhId = Id FROM dbo.TepDinhKem WHERE KhoaLuuTru = @KhoaTep;
        SET @AnhJSON = '[' + CONVERT(VARCHAR(20), @AnhId) + ']';
        SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
        EXEC dbo.sp_TaoPhieuNghiemThu @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @NguyenNhan = N'Linh kiện bị mòn hoặc tiếp xúc kém.', @PhuongAnXuLy = N'Vệ sinh, sửa chữa và kiểm tra lại hoạt động.', @PhienBanDuKien = @PhienBan, @ChuKyKTVId = @ChuKyTho, @AnhThanhPham = @AnhJSON;
        IF @Dich = 'ChoNghiemThu' BEGIN SET @Stt += 1; CONTINUE; END;
        SET @KhoaTep = CONVERT(VARCHAR(36), NEWID()) + '.png';
        EXEC dbo.sp_LuuTepDinhKem @NguoiThucHienId = @KhachId, @DonHangId = @DonId, @MucDich = 'CustomerSignature', @KhoaLuuTru = @KhoaTep, @TenTepGoc = N'Chữ ký khách minh họa.png', @KieuMIME = 'image/png', @KichThuoc = 19517;
        SELECT @ChuKyKhach = Id FROM dbo.TepDinhKem WHERE KhoaLuuTru = @KhoaTep;
        SELECT @NghiemThuId = Id, @PhienBan = PhienBan, @TongTien = TongTien FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonId AND TrangThai = 'Pending';
        EXEC dbo.sp_KhachHangKyNghiemThu @NguoiThucHienId = @KhachId, @NghiemThuId = @NghiemThuId, @ChuKyId = @ChuKyKhach, @PhuongThucThanhToan = @PTTT, @PhienBanDuKien = @PhienBan, @TaiKhoanNganHangId = @NganHang;
        IF @PTTT = 'COD'
        BEGIN
            SELECT @PhienBan = PhienBan FROM dbo.DonHang WHERE Id = @DonId;
            EXEC dbo.sp_XacNhanThanhToanCOD @NguoiThucHienId = @ThoId, @DonHangId = @DonId, @PhienBanDuKien = @PhienBan;
        END
        ELSE
        BEGIN
            SET @KhoaTep = CONVERT(VARCHAR(36), NEWID()) + '.png';
            EXEC dbo.sp_LuuTepDinhKem @NguoiThucHienId = @KhachId, @DonHangId = @DonId, @MucDich = 'PaymentProof', @KhoaLuuTru = @KhoaTep, @TenTepGoc = N'Chứng từ ngân hàng minh họa.png', @KieuMIME = 'image/png', @KichThuoc = 19517;
            SELECT @TepId = Id FROM dbo.TepDinhKem WHERE KhoaLuuTru = @KhoaTep;
            SET @ThamChieu = 'MINHHOA-20261023-' + CONVERT(VARCHAR(20), @DonId);
            EXEC dbo.sp_TaoYeuCauThanhToan @NguoiThucHienId = @KhachId, @DonHangId = @DonId, @TaiKhoanNganHangId = @NganHang, @ChungTuId = @TepId, @MaThamChieu = @ThamChieu;
            SELECT @YeuCauId = Id, @PhienBan = PhienBan FROM dbo.YeuCauThanhToan WHERE DonHangId = @DonId AND TrangThai = 'Pending';
            EXEC dbo.sp_XacNhanThanhToanNganHang @NguoiThucHienId = @KeToan, @YeuCauThanhToanId = @YeuCauId, @QuyetDinh = 'Confirmed', @PhienBanDuKien = @PhienBan, @SoTienThucNhan = @TongTien, @MaThamChieu = @ThamChieu;
        END;
        -- Giữ đơn 03 chờ đối soát để kế toán có dữ liệu thao tác.
        IF @Stt <> 3
        BEGIN
            SELECT @YeuCauId = Id, @PhienBan = PhienBan FROM dbo.DoiSoat WHERE DonHangId = @DonId AND TrangThai = 'Pending';
            EXEC dbo.sp_DoiSoatCOD @NguoiThucHienId = @KeToan, @DoiSoatId = @YeuCauId, @PhienBanDuKien = @PhienBan;
        END;
        SET @DanhGia = CASE WHEN @Stt = 1 THEN 4 ELSE 5 END;
        EXEC dbo.sp_TaoDanhGiaDonHang @NguoiThucHienId = @KhachId, @DonHangId = @DonId, @Diem = @DanhGia, @NhanXet = N'Thợ đến đúng hẹn, giải thích rõ và kiểm tra thiết bị sau khi sửa.';
        SET @Stt += 1;
    END;

    SELECT @ThoId = Id FROM dbo.NguoiDung WHERE SoDienThoai = '0900002003';
    EXEC dbo.sp_TaoYeuCauVi @NguoiThucHienId = @ThoId, @Loai = 'Withdrawal', @SoTien = 200000, @GhiChu = N'Rút tiền minh họa về tài khoản mô phỏng; chờ kế toán duyệt.';

    EXEC dbo.sp_LuuCauHinh @NguoiThucHienId = @Admin, @Khoa = 'DuLieuMinhHoa20261023', @GiaTri = N'10 đơn, 5 khách, 3 thợ bổ sung', @NhanHienThi = N'Bộ dữ liệu minh họa';
    COMMIT TRANSACTION;
    PRINT N'Đã bổ sung dữ liệu minh họa. Không xóa hoặc ghi đè dữ liệu cũ.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
