-- Kịch bản sao lưu và phục hồi cơ sở dữ liệu HomeFix.
USE master;
GO

SET NOCOUNT ON;
GO

-- 1. Thiết lập mô hình phục hồi Full để hỗ trợ sao lưu nhật ký giao dịch.
DECLARE @TenCSDL NVARCHAR(128) = N'HomeFix_DBMS_Nhom08';

IF DB_ID(@TenCSDL) IS NULL AND DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    SET @TenCSDL = N'HomeFix_DBMS_Nhom08_TiengViet';

IF DB_ID(@TenCSDL) IS NOT NULL
BEGIN
    DECLARE @SqlRecovery NVARCHAR(MAX) = N'ALTER DATABASE ' + QUOTENAME(@TenCSDL) + N' SET RECOVERY FULL WITH NO_WAIT;';
    EXEC sp_executesql @SqlRecovery;
END
GO

-- 2. Sao lưu toàn phần (Full Backup).
DECLARE @TenCSDL NVARCHAR(128) = N'HomeFix_DBMS_Nhom08';
IF DB_ID(@TenCSDL) IS NULL AND DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    SET @TenCSDL = N'HomeFix_DBMS_Nhom08_TiengViet';

DECLARE @ThuMuc NVARCHAR(500);
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @ThuMuc OUTPUT;

IF @ThuMuc IS NULL OR @ThuMuc = ''
    SET @ThuMuc = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500));
IF @ThuMuc IS NULL OR @ThuMuc = ''
    SET @ThuMuc = N'C:\';

DECLARE @TepFull NVARCHAR(600) = RTRIM(@ThuMuc) + N'\' + @TenCSDL + N'_Full.bak';
DECLARE @LenhFull NVARCHAR(MAX) = N'BACKUP DATABASE ' + QUOTENAME(@TenCSDL) + N'
TO DISK = @DuongDan
WITH FORMAT, INIT, COMPRESSION,
     NAME = N''HomeFix-Full Backup'',
     STATS = 10;';

EXEC sp_executesql @LenhFull, N'@DuongDan NVARCHAR(600)', @DuongDan = @TepFull;
GO

-- 3. Sao lưu vi sai (Differential Backup).
DECLARE @TenCSDL NVARCHAR(128) = N'HomeFix_DBMS_Nhom08';
IF DB_ID(@TenCSDL) IS NULL AND DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    SET @TenCSDL = N'HomeFix_DBMS_Nhom08_TiengViet';

DECLARE @ThuMuc NVARCHAR(500);
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @ThuMuc OUTPUT;

IF @ThuMuc IS NULL OR @ThuMuc = ''
    SET @ThuMuc = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500));

DECLARE @TepDiff NVARCHAR(600) = RTRIM(@ThuMuc) + N'\' + @TenCSDL + N'_Diff.bak';
DECLARE @LenhDiff NVARCHAR(MAX) = N'BACKUP DATABASE ' + QUOTENAME(@TenCSDL) + N'
TO DISK = @DuongDan
WITH DIFFERENTIAL, FORMAT, INIT, COMPRESSION,
     NAME = N''HomeFix-Diff Backup'',
     STATS = 20;';

EXEC sp_executesql @LenhDiff, N'@DuongDan NVARCHAR(600)', @DuongDan = @TepDiff;
GO

-- 4. Sao lưu nhật ký giao dịch (Transaction Log Backup).
DECLARE @TenCSDL NVARCHAR(128) = N'HomeFix_DBMS_Nhom08';
IF DB_ID(@TenCSDL) IS NULL AND DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    SET @TenCSDL = N'HomeFix_DBMS_Nhom08_TiengViet';

DECLARE @ThuMuc NVARCHAR(500);
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @ThuMuc OUTPUT;

IF @ThuMuc IS NULL OR @ThuMuc = ''
    SET @ThuMuc = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500));

DECLARE @TepLog NVARCHAR(600) = RTRIM(@ThuMuc) + N'\' + @TenCSDL + N'_Log.trn';
DECLARE @LenhLog NVARCHAR(MAX) = N'BACKUP LOG ' + QUOTENAME(@TenCSDL) + N'
TO DISK = @DuongDan
WITH FORMAT, INIT,
     NAME = N''HomeFix-Log Backup'',
     STATS = 25;';

EXEC sp_executesql @LenhLog, N'@DuongDan NVARCHAR(600)', @DuongDan = @TepLog;
GO

-- 5. Kiểm tra thông tin và tính toàn vẹn của tệp sao lưu.
DECLARE @TenCSDL NVARCHAR(128) = N'HomeFix_DBMS_Nhom08';
IF DB_ID(@TenCSDL) IS NULL AND DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    SET @TenCSDL = N'HomeFix_DBMS_Nhom08_TiengViet';

DECLARE @ThuMuc NVARCHAR(500);
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @ThuMuc OUTPUT;

IF @ThuMuc IS NULL OR @ThuMuc = ''
    SET @ThuMuc = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500));

DECLARE @TepFull NVARCHAR(600) = RTRIM(@ThuMuc) + N'\' + @TenCSDL + N'_Full.bak';

RESTORE HEADERONLY FROM DISK = @TepFull;
RESTORE VERIFYONLY FROM DISK = @TepFull;
GO

-- 6. Quy trình mẫu phục hồi cơ sở dữ liệu khi gặp sự cố.
/*
USE master;
GO

ALTER DATABASE [HomeFix_DBMS_Nhom08] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Bước 6.1: Phục hồi bản Full Backup với tùy chọn NORECOVERY.
RESTORE DATABASE [HomeFix_DBMS_Nhom08]
FROM DISK = N'C:\HomeFix_DBMS_Nhom08_Full.bak'
WITH REPLACE, NORECOVERY, STATS = 10;

-- Bước 6.2: Phục hồi bản Differential Backup gần nhất.
RESTORE DATABASE [HomeFix_DBMS_Nhom08]
FROM DISK = N'C:\HomeFix_DBMS_Nhom08_Diff.bak'
WITH NORECOVERY, STATS = 20;

-- Bước 6.3: Phục hồi bản Log và đưa cơ sở dữ liệu về trạng thái sẵn sàng.
RESTORE LOG [HomeFix_DBMS_Nhom08]
FROM DISK = N'C:\HomeFix_DBMS_Nhom08_Log.trn'
WITH RECOVERY, STATS = 25;

-- Phục hồi theo thời điểm (Point-in-Time Recovery):
-- RESTORE LOG [HomeFix_DBMS_Nhom08] FROM DISK = N'C:\HomeFix_DBMS_Nhom08_Log.trn'
-- WITH STOPAT = '2026-10-11 20:00:00', RECOVERY;

ALTER DATABASE [HomeFix_DBMS_Nhom08] SET MULTI_USER;
GO
*/

-- 7. Thủ tục tự động hóa sao lưu cơ sở dữ liệu.
IF DB_ID(N'HomeFix_DBMS_Nhom08') IS NOT NULL
    USE [HomeFix_DBMS_Nhom08];
ELSE IF DB_ID(N'HomeFix_DBMS_Nhom08_TiengViet') IS NOT NULL
    USE [HomeFix_DBMS_Nhom08_TiengViet];
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaoLuuHeThong
    @LoaiSaoLuu VARCHAR(10) = 'FULL',
    @DuongDanThuMuc NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TenCSDL NVARCHAR(128) = DB_NAME();
    DECLARE @ThuMuc NVARCHAR(500) = @DuongDanThuMuc;

    IF @ThuMuc IS NULL OR @ThuMuc = ''
    BEGIN
        EXEC master.dbo.xp_instance_regread
            N'HKEY_LOCAL_MACHINE',
            N'Software\Microsoft\MSSQLServer\MSSQLServer',
            N'BackupDirectory',
            @ThuMuc OUTPUT;
        IF @ThuMuc IS NULL OR @ThuMuc = ''
            SET @ThuMuc = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500));
    END

    DECLARE @DauThoiGian NVARCHAR(30) = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), '-', ''), ' ', '_'), ':', '');
    DECLARE @TepDich NVARCHAR(600);
    DECLARE @CauLenh NVARCHAR(MAX);

    IF UPPER(@LoaiSaoLuu) = 'FULL'
    BEGIN
        SET @TepDich = RTRIM(@ThuMuc) + '\' + @TenCSDL + '_Full_' + @DauThoiGian + '.bak';
        SET @CauLenh = N'BACKUP DATABASE ' + QUOTENAME(@TenCSDL) + N' TO DISK = @pPath WITH INIT, COMPRESSION, STATS = 10;';
        EXEC sp_executesql @CauLenh, N'@pPath NVARCHAR(600)', @pPath = @TepDich;
    END
    ELSE IF UPPER(@LoaiSaoLuu) = 'DIFF'
    BEGIN
        SET @TepDich = RTRIM(@ThuMuc) + '\' + @TenCSDL + '_Diff_' + @DauThoiGian + '.bak';
        SET @CauLenh = N'BACKUP DATABASE ' + QUOTENAME(@TenCSDL) + N' TO DISK = @pPath WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10;';
        EXEC sp_executesql @CauLenh, N'@pPath NVARCHAR(600)', @pPath = @TepDich;
    END
    ELSE IF UPPER(@LoaiSaoLuu) = 'LOG'
    BEGIN
        SET @TepDich = RTRIM(@ThuMuc) + '\' + @TenCSDL + '_Log_' + @DauThoiGian + '.trn';
        SET @CauLenh = N'BACKUP LOG ' + QUOTENAME(@TenCSDL) + N' TO DISK = @pPath WITH INIT, STATS = 10;';
        EXEC sp_executesql @CauLenh, N'@pPath NVARCHAR(600)', @pPath = @TepDich;
    END
    ELSE
    BEGIN
        THROW 51009, 'INVALID_BACKUP_TYPE', 1;
    END
END;
GO
