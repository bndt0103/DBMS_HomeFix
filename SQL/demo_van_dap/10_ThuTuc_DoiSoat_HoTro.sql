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
-- Fixture tong hop tren DB demo; rollback toan bo.
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

    DECLARE @KT INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KT');
    INSERT dbo.DoiSoat (DonHangId,KyThuatVienId,ThanhToanId,TienCong,TyLeHoaHong)
    VALUES (@Don,@KTV,@TT,200000,15);
    DECLARE @DS INT=SCOPE_IDENTITY();
    DECLARE @PB BINARY(8)=(SELECT PhienBan FROM dbo.DoiSoat WHERE Id=@DS);
    DECLARE @SoDuTruoc DECIMAL(18,2)=(SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@KTV);
    EXEC dbo.sp_DoiSoatCOD @DS,@KT,@PB;
    SELECT TrangThai,TienHoaHong FROM dbo.DoiSoat WHERE Id=@DS;
    SELECT @SoDuTruoc AS Truoc,SoDu AS Sau,@SoDuTruoc-SoDu AS HoaHongDaTru FROM dbo.KyThuatVien WHERE Id=@KTV;
    IF (SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@KTV)<>@SoDuTruoc-30000
        THROW 51999,'DEMO_FAIL: DOI_SOAT_SAI',1;
    DECLARE @CSKH INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='CSKH');
    INSERT dbo.YeuCauHoTro (DonHangId,KhachHangId,Loai,MoTa)
    VALUES (@Don,@KH,'Complaint',N'Demo luu lich su xu ly');
    DECLARE @YC INT=SCOPE_IDENTITY();
    SET @PB=(SELECT PhienBan FROM dbo.YeuCauHoTro WHERE Id=@YC);
    EXEC dbo.sp_XuLyHoTro @YC,@CSKH,'InProgress',N'Da tiep nhan va lien he khach',@PB;
    SELECT TrangThai,KetQuaXuLy FROM dbo.YeuCauHoTro WHERE Id=@YC;
    SELECT TrangThai,GhiChu FROM dbo.LichSuHoTro WHERE YeuCauHoTroId=@YC;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
