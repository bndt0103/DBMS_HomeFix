-- HomeFix: bộ cài được sinh từ SRC/database bởi npm run sql:build.
-- Không sửa bản sinh; sửa nguồn rồi sinh lại. Chỉ cài vào CSDL mới.
:on error exit
:setvar TenCSDL "HomeFix_VanDap_20261022"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO

-- sqlcmd: chạy từ thư mục SQL. SSMS: đặt ThuMucSQL thành đường dẫn tuyệt đối tới SQL.
:setvar ThuMucSQL "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/00_schema.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/01_index.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/02_function.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/03_view.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/04_sp.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/05_transaction.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/06_trigger.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/07_security.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/08_seed.sql"
:r "D:/Subject_K5/DBMS/ProjectCK/Nhom08_QuanLyDichVuHomeFix/SQL/modules/09_data_migration.sql"
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
