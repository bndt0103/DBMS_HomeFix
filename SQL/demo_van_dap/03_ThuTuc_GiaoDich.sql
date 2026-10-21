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

-- A. Tao don, chuyen trang thai, xem lich su/trigger; cuoi cung rollback.
DECLARE @KH INT = (SELECT TOP (1) Id FROM dbo.NguoiDung WHERE VaiTro='KH' AND DangHoatDong=1 ORDER BY Id);
DECLARE @DV INT = (SELECT TOP (1) Id FROM dbo.DichVu WHERE DangHoatDong=1 ORDER BY Id);
DECLARE @DPV INT = (SELECT TOP (1) Id FROM dbo.NguoiDung WHERE VaiTro='DPV' ORDER BY Id);
DECLARE @Truoc INT = (SELECT COUNT(*) FROM dbo.DonHang);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @KH, @DV, N'123 Duong demo, Thu Duc', N'Dieu hoa khong lam lanh', NULL;
    DECLARE @Don INT = (SELECT MAX(Id) FROM dbo.DonHang);
    DECLARE @PB BINARY(8) = (SELECT PhienBan FROM dbo.DonHang WHERE Id=@Don);
    EXEC dbo.sp_ChuyenTrangThaiDon @Don, @DPV, @PB, 'ChoDuyetSoBo', N'Demo chuyen buoc hop le';
    SELECT Id, TrangThai, PhienBan FROM dbo.DonHang WHERE Id=@Don;
    SELECT TrangThaiTruoc, TrangThaiSau, LyDo FROM dbo.LichSuDonHang WHERE DonHangId=@Don;
    SELECT ThaoTac, ChiTiet FROM dbo.NhatKy WHERE DoiTuong='DonHang' AND DoiTuongId=@Don;
    ROLLBACK TRANSACTION;
    SELECT @Truoc AS Truoc, COUNT(*) AS SauRollback FROM dbo.DonHang;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- B. Loi o thao tac thu hai: don vua tao cung phai rollback.
DECLARE @KH INT = (SELECT TOP (1) Id FROM dbo.NguoiDung WHERE VaiTro='KH' AND DangHoatDong=1 ORDER BY Id);
DECLARE @DV INT = (SELECT TOP (1) Id FROM dbo.DichVu WHERE DangHoatDong=1 ORDER BY Id);
DECLARE @Truoc INT = (SELECT COUNT(*) FROM dbo.DonHang);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @KH, @DV, N'123 Duong demo, Thu Duc', N'Demo rollback khi buoc sau loi', NULL;
    DECLARE @Don INT = (SELECT MAX(Id) FROM dbo.DonHang);
    DECLARE @PB BINARY(8) = (SELECT PhienBan FROM dbo.DonHang WHERE Id=@Don);
    EXEC dbo.sp_ChuyenTrangThaiDon @Don, @KH, @PB, 'HoanThanh', N'Co tinh nhay buoc';
    ROLLBACK TRANSACTION;
    THROW 51999, 'DEMO_FAIL: CHAP_NHAN_NHAY_BUOC', 1;
END TRY
BEGIN CATCH
    DECLARE @Loi NVARCHAR(4000)=ERROR_MESSAGE(), @Ma INT=ERROR_NUMBER();
    SELECT XACT_STATE() AS TrangThaiTruocRollback, @@TRANCOUNT AS SoMucGiaoDich;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @Ma<>51009 OR @Loi<>'INVALID_TRANSITION' THROW;
    SELECT @Ma AS MaLoi, @Loi AS LoiDuKien, @Truoc AS Truoc, COUNT(*) AS SauRollback FROM dbo.DonHang;
END CATCH;
GO
-- C. Tham so ngay sai: SP tra loi cu the, khong tra bao cao vo nghia.
BEGIN TRY
    EXEC dbo.sp_BaoCaoTongHop '20261022', '20261021';
    THROW 51999, 'DEMO_FAIL: KHOANG_NGAY_SAI_KHONG_BI_CHAN', 1;
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE()<>'INVALID_DATE_RANGE' THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiDuKien;
END CATCH;
GO
