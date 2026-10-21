-- Chay tung khoi trong SSMS. Du lieu demo rieng.
USE [HomeFix_VanDap_20261022];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
-- Fixture SQL tong hop CHI de co lap dieu kien trigger; khong thay the luong duyet/chu ky tren web.

-- Thanh toan sai so tien
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @KH INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KH');
    DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
    DECLARE @DV INT=(SELECT MIN(Id) FROM dbo.DichVu WHERE DangHoatDong=1);
    EXEC dbo.sp_TaoDonHang @KH,@DV,N'123 Duong demo Thu Duc',N'Du lieu tong hop de kiem trigger',NULL;
    DECLARE @Don INT=(SELECT MAX(Id) FROM dbo.DonHang);
INSERT dbo.PhieuNghiemThu (DonHangId,KyThuatVienId,LanSuaDoi,NguyenNhan,PhuongAnXuLy,PhiKiemTra,TienCong,TongTienVatTu,TrangThai,NgayDuyet)
    VALUES (@Don,@KTV,1,N'Loi demo',N'Xu ly demo',50000,200000,100000,'Approved',SYSUTCDATETIME());
    DECLARE @NT INT=SCOPE_IDENTITY();
INSERT dbo.ThanhToan (DonHangId,NghiemThuId,SoTien,PhuongThuc,NguoiThuTienId) VALUES (@Don,@NT,1,'COD',@KTV);
    ROLLBACK TRANSACTION;
    THROW 51999,'DEMO_FAIL: DU_LIEU_SAI_KHONG_BI_CHAN',1;
END TRY
BEGIN CATCH
    DECLARE @Loi NVARCHAR(4000)=ERROR_MESSAGE();
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @Loi<>'PAYMENT_ACCEPTANCE_MISMATCH' THROW;
    SELECT N'Thanh toan sai so tien' AS BaiDemo,@Loi AS LoiDuKien;
END CATCH;
GO

-- Thanh toan bat bien
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @KH INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KH');
    DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
    DECLARE @DV INT=(SELECT MIN(Id) FROM dbo.DichVu WHERE DangHoatDong=1);
    EXEC dbo.sp_TaoDonHang @KH,@DV,N'123 Duong demo Thu Duc',N'Du lieu tong hop de kiem trigger',NULL;
    DECLARE @Don INT=(SELECT MAX(Id) FROM dbo.DonHang);
INSERT dbo.PhieuNghiemThu (DonHangId,KyThuatVienId,LanSuaDoi,NguyenNhan,PhuongAnXuLy,PhiKiemTra,TienCong,TongTienVatTu,TrangThai,NgayDuyet)
    VALUES (@Don,@KTV,1,N'Loi demo',N'Xu ly demo',50000,200000,100000,'Approved',SYSUTCDATETIME());
    DECLARE @NT INT=SCOPE_IDENTITY();
INSERT dbo.ThanhToan (DonHangId,NghiemThuId,SoTien,PhuongThuc,NguoiThuTienId)
    VALUES (@Don,@NT,350000,'COD',@KTV);
    DECLARE @TT INT=SCOPE_IDENTITY();
UPDATE dbo.ThanhToan SET SoTien=1 WHERE Id=@TT;
    ROLLBACK TRANSACTION;
    THROW 51999,'DEMO_FAIL: DU_LIEU_SAI_KHONG_BI_CHAN',1;
END TRY
BEGIN CATCH
    DECLARE @Loi NVARCHAR(4000)=ERROR_MESSAGE();
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @Loi<>'PAYMENT_IMMUTABLE' THROW;
    SELECT N'Thanh toan bat bien' AS BaiDemo,@Loi AS LoiDuKien;
END CATCH;
GO

-- Danh gia khi chua thanh toan
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @KH INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KH');
    DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
    DECLARE @DV INT=(SELECT MIN(Id) FROM dbo.DichVu WHERE DangHoatDong=1);
    EXEC dbo.sp_TaoDonHang @KH,@DV,N'123 Duong demo Thu Duc',N'Du lieu tong hop de kiem trigger',NULL;
    DECLARE @Don INT=(SELECT MAX(Id) FROM dbo.DonHang);
INSERT dbo.DanhGia (DonHangId,KhachHangId,KyThuatVienId,DiemDanhGia,NhanXet) VALUES (@Don,@KH,@KTV,5,N'Demo danh gia chua du dieu kien');
    ROLLBACK TRANSACTION;
    THROW 51999,'DEMO_FAIL: DU_LIEU_SAI_KHONG_BI_CHAN',1;
END TRY
BEGIN CATCH
    DECLARE @Loi NVARCHAR(4000)=ERROR_MESSAGE();
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @Loi<>'REVIEW_NOT_ELIGIBLE' THROW;
    SELECT N'Danh gia khi chua thanh toan' AS BaiDemo,@Loi AS LoiDuKien;
END CATCH;
GO

-- Moi de xuat tao mot thong bao cho moi GD dang hoat dong.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Ma VARCHAR(30)='VD'+LEFT(REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),12);
    INSERT dbo.DeXuatChinhSach (MaDeXuat,TieuDe,BoPhan,NgayGui,NhomDichVu,TacDong,LyDo)
    VALUES (@Ma,N'Demo thong bao',N'Ke toan',SYSUTCDATETIME(),N'DienLanh',N'Tac dong demo',N'Kiem chung trigger');
    DECLARE @SoGD INT=(SELECT COUNT(*) FROM dbo.NguoiDung WHERE VaiTro='GD' AND DangHoatDong=1);
    DECLARE @SoTB INT=(SELECT COUNT(*) FROM dbo.ThongBao WHERE NoiDungThongBao LIKE @Ma+N'%');
    SELECT @SoGD AS SoGDDangHoatDong,@SoTB AS SoThongBao;
    IF @SoGD<>@SoTB THROW 51999,'DEMO_FAIL: THIEU_THONG_BAO',1;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
