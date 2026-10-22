SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* DỮ LIỆU BAN ĐẦU SẠCH: 7 người dùng, 1 hồ sơ thợ, 5 nhóm/5 dịch vụ,
   1 tài khoản ngân hàng MÔ PHỎNG và cấu hình. KHÔNG có đơn/OTP/sổ cái/nhật ký.
   Mật khẩu cả 7 tài khoản: 123456. Chỉ dùng cho học tập trên máy cá nhân.
   Script chỉ chèn khi database còn trắng; không xóa giao dịch đang có. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.NguoiDung) OR EXISTS (SELECT 1 FROM dbo.DonHang)
        THROW 51009, N'Seed chỉ chạy trên database trắng. Không tự động xóa dữ liệu hiện có.', 1;
    DECLARE @MatKhauBam VARCHAR(100) = '$2b$10$6R3Jy/EiVEhpVTLlbrO1SuUsl9VMoJuAolWgiIYQ7V/1s0XW8OxHS';
    INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, MatKhauBam, VaiTro)
    VALUES (N'Khách hàng mẫu', '0900000001', @MatKhauBam, 'KH'),
           (N'Kỹ thuật viên mẫu', '0900000002', @MatKhauBam, 'KTV'),
           (N'Điều phối viên mẫu', '0900000003', @MatKhauBam, 'DPV'),
           (N'Chăm sóc khách hàng mẫu', '0900000004', @MatKhauBam, 'CSKH'),
           (N'Kế toán mẫu', '0900000005', @MatKhauBam, 'KT'),
           (N'Giám đốc mẫu', '0900000006', @MatKhauBam, 'GD'),
           (N'Quản trị viên mẫu', '0900000007', @MatKhauBam, 'ADMIN');
    INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu)
    SELECT Id, N'Điện, Nước, Điện lạnh', N'Thành phố Hồ Chí Minh', 'SanSang', 0 FROM dbo.NguoiDung WHERE VaiTro = 'KTV';
    INSERT INTO dbo.DanhMucDichVu(Ten, Ma)
    VALUES (N'Điện', 'DIEN'), (N'Nước', 'NUOC'), (N'Điện lạnh', 'DIEN_LANH'), (N'Đồ gỗ', 'DO_GO'), (N'Khóa', 'KHOA');
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Kiểm tra và sửa chữa điện', N'Sửa ổ cắm, công tắc và sự cố điện gia đình.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DIEN';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Kiểm tra và sửa chữa nước', N'Khắc phục rò rỉ và thay phụ kiện đường nước.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'NUOC';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Bảo dưỡng máy lạnh', N'Kiểm tra và vệ sinh máy lạnh gia đình.', 50000, 200000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DIEN_LANH';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Sửa đồ gỗ gia đình', N'Sửa bản lề, cánh tủ và phụ kiện đồ gỗ.', 50000, 180000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DO_GO';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Sửa và thay khóa', N'Kiểm tra, sửa hoặc thay khóa dân dụng.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'KHOA';
    INSERT INTO dbo.TaiKhoanNganHang(MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan)
    VALUES ('DEMO', N'Ngân hàng mô phỏng - không chuyển tiền thật', '000000000000', N'HOMEFIX DEMO');
    INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi)
    VALUES ('TyLeHoaHongMacDinh', N'15', N'Tỷ lệ hoa hồng mặc định'),
           ('TaiKhoanNganHangMacDinh', N'1', N'Id tài khoản ngân hàng nhận tiền'),
           ('TenHeThong', N'HomeFix', N'Tên hệ thống'),
           ('SoDienThoaiHoTro', N'02800000000', N'Số điện thoại hỗ trợ mô phỏng');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
SELECT Id, HoTen, SoDienThoai, VaiTro, DangHoatDong FROM dbo.vw_NguoiDung ORDER BY Id;
GO
