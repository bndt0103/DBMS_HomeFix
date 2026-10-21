-- HomeFix: bộ cài được sinh từ SRC/database bởi npm run sql:build.
-- Không sửa bản sinh; sửa nguồn rồi sinh lại. Chỉ cài vào CSDL mới.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08_Import"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO

-- sqlcmd: chạy từ thư mục SQL. SSMS: đặt ThuMucSQL thành đường dẫn tuyệt đối tới SQL.
:setvar ThuMucSQL "."
:r $(ThuMucSQL)/modules/00_schema.sql
:r $(ThuMucSQL)/modules/01_index.sql
:r $(ThuMucSQL)/modules/02_function.sql
:r $(ThuMucSQL)/modules/03_view.sql
:r $(ThuMucSQL)/modules/04_sp.sql
:r $(ThuMucSQL)/modules/05_transaction.sql
:r $(ThuMucSQL)/modules/06_trigger.sql
:r $(ThuMucSQL)/modules/07_security.sql
:r $(ThuMucSQL)/modules/08_seed.sql
:r $(ThuMucSQL)/modules/09_data_migration.sql
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
