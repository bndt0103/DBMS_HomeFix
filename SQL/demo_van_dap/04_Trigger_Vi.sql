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

-- A. Mot INSERT nhieu dong: trigger cong tong 30.000, khong bo sot dong.
DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
DECLARE @Truoc DECIMAL(18,2)=(SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@KTV);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.GiaoDichVi (KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu)
    VALUES (@KTV,'Deposit',10000,'VanDapDemo',-91001,N'Dong thu nhat'),
           (@KTV,'Deposit',20000,'VanDapDemo',-91002,N'Dong thu hai');
    SELECT @Truoc AS Truoc, SoDu AS Sau, SoDu-@Truoc AS MucTang FROM dbo.KyThuatVien WHERE Id=@KTV;
    IF (SELECT SoDu FROM dbo.KyThuatVien WHERE Id=@KTV) <> @Truoc+30000
        THROW 51999, 'DEMO_FAIL: TRIGGER_TINH_SAI', 1;
    SELECT * FROM dbo.vw_ViKyThuatVien WHERE Id=@KTV;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- B. So am vuot so du: CHECK tren KyThuatVien chan UPDATE trong trigger.
DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
DECLARE @SoTien DECIMAL(18,2)=-(SELECT SoDu+1 FROM dbo.KyThuatVien WHERE Id=@KTV);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.GiaoDichVi (KyThuatVienId,Loai,SoTien,LoaiThamChieu,ThamChieuId,GhiChu)
    VALUES (@KTV,'Withdrawal',@SoTien,'VanDapDemo',-91003,N'Co tinh rut qua so du');
    ROLLBACK TRANSACTION;
    THROW 51999, 'DEMO_FAIL: CHO_PHEP_VI_AM', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER()<>547 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiDuKien;
END CATCH;
SELECT COUNT(*) AS GiaoDichSaiConLai FROM dbo.GiaoDichVi WHERE LoaiThamChieu='VanDapDemo';
GO
-- C. So vi bat bien: sua dong da ghi bi INSTEAD OF trigger tu choi.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.GiaoDichVi SET GhiChu=N'Co tinh sua so' WHERE Id=(SELECT MIN(Id) FROM dbo.GiaoDichVi);
    ROLLBACK TRANSACTION;
    THROW 51999, 'DEMO_FAIL: SUA_DUOC_SO_VI', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF ERROR_MESSAGE()<>'LEDGER_IMMUTABLE' THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiDuKien;
END CATCH;
GO
