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

SELECT @@SERVERNAME AS MayChu, DB_NAME() AS CSDL, @@TRANCOUNT AS GiaoDichDangMo;
SELECT type_desc, COUNT(*) AS SoLuong
FROM sys.objects
WHERE is_ms_shipped = 0 AND type IN ('U','P','FN','IF','V','TR')
GROUP BY type_desc;
SELECT OBJECT_NAME(parent_object_id) AS Bang, name, definition, is_disabled, is_not_trusted
FROM sys.check_constraints ORDER BY Bang, name;
SELECT OBJECT_NAME(parent_object_id) AS BangCon, name,
       OBJECT_NAME(referenced_object_id) AS BangCha, delete_referential_action_desc
FROM sys.foreign_keys ORDER BY BangCon, name;
SELECT OBJECT_NAME(object_id) AS Bang, name, is_unique, is_primary_key, filter_definition
FROM sys.indexes WHERE index_id > 0 AND OBJECTPROPERTY(object_id,'IsUserTable') = 1
ORDER BY Bang, name;
SELECT TOP (5) Id, Ten, TienCong, TyLeHoaHong FROM dbo.DichVu ORDER BY Id;
-- Khong SELECT MatKhauBam khi trinh chieu.
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
