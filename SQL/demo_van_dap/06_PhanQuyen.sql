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

-- Database user WITHOUT LOGIN chi duoc gia lap trong phien co quyen IMPERSONATE.
DECLARE @DaDoi BIT=0;
BEGIN TRY
    EXECUTE AS USER='hf_KH';
    SET @DaDoi=1;
    SELECT USER_NAME() AS DangDongVai;
    SELECT TOP (3) Id,Ten,TongTienDuKien FROM dbo.vw_DichVuCongKhai;
    SELECT HAS_PERMS_BY_NAME('dbo.vw_DichVuCongKhai','OBJECT','SELECT') AS DuocXemView,
           HAS_PERMS_BY_NAME('dbo.GiaoDichVi','OBJECT','UPDATE') AS DuocSuaSoVi;
    BEGIN TRY
        SELECT TOP (0) MatKhauBam FROM dbo.NguoiDung;
        THROW 51999, 'DEMO_FAIL: DUOC_DOC_MAT_KHAU', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229,230) THROW;
        SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiQuyenDuKien;
    END CATCH;
    REVERT;
    SET @DaDoi=0;
END TRY
BEGIN CATCH
    IF @DaDoi=1 REVERT;
    THROW;
END CATCH;
SELECT USER_NAME() AS DaTroLai;
GO
-- Xem ket qua GRANT roi REVOKE trong ma nguon: GD khong duoc doc NhatKy.
EXECUTE AS USER='hf_GD';
SELECT HAS_PERMS_BY_NAME('dbo.NhatKy','OBJECT','SELECT') AS QuyenNhatKySauRevoke,
       HAS_PERMS_BY_NAME('dbo.sp_BaoCaoTongHop','OBJECT','EXECUTE') AS QuyenBaoCao;
REVERT;
GO
