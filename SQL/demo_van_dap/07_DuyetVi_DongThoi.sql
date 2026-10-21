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

-- ROWVERSION: duyet thanh cong mot lan, dung lai phien ban cu bi tu choi.
DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
DECLARE @KT INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KT' AND DangHoatDong=1);
DECLARE @Truoc DECIMAL(18,2)=(SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@KTV);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.YeuCauVi (KyThuatVienId,Loai,SoTien,GhiChu)
    VALUES (@KTV,'Deposit',50000,N'Demo SQL thuan; ung dung con kiem tra chung tu truoc khi tao yeu cau');
    DECLARE @YC INT=SCOPE_IDENTITY();
    DECLARE @PB BINARY(8)=(SELECT PhienBan FROM dbo.YeuCauVi WHERE Id=@YC);
    EXEC dbo.sp_DuyetYeuCauVi @YC,@KT,'Approved',@PB,NULL;
    SELECT @Truoc AS Truoc,SoDu AS Sau FROM dbo.KyThuatVien WHERE Id=@KTV;
    SELECT TrangThai,PhienBan AS PhienBanMoi,@PB AS PhienBanCu FROM dbo.YeuCauVi WHERE Id=@YC;
    EXEC dbo.sp_DuyetYeuCauVi @YC,@KT,'Approved',@PB,NULL;
    ROLLBACK TRANSACTION;
    THROW 51999, 'DEMO_FAIL: DUYET_LAP_THANH_CONG', 1;
END TRY
BEGIN CATCH
    DECLARE @Loi NVARCHAR(4000)=ERROR_MESSAGE();
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @Loi<>'VERSION_CONFLICT' THROW;
    SELECT @Loi AS LoiDuKien, @Truoc AS Truoc,SoDu AS SauRollback FROM dbo.KyThuatVien WHERE Id=@KTV;
END CATCH;
GO
-- Day la minh hoa duyet lap/phien ban cu tren MOT session.
-- Kiem thu HAI ket noi dong thoi nam trong SRC/tests/dbms.test.js.
