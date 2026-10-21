-- Chạy riêng; không thuộc bộ cài. Xem hướng dẫn trong file.
-- HomeFix: sao lưu FULL -> DIFF -> LOG; tùy chọn phục hồi vào CSDL MỚI.
-- Bật SQLCMD Mode trong SSMS. Chọn đúng TenCSDL trước khi chạy.
-- Tài khoản SQL cần quyền BACKUP/RESTORE; SQL Server service cần quyền ghi thư mục backup.
-- Không dùng COMPRESSION bắt buộc để chạy được cả SQL Server Express.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08"
:setvar ThucHienPhucHoi "0"

USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NULL
    THROW 51009, 'SOURCE_DATABASE_NOT_FOUND', 1;
GO
USE [$(TenCSDL)];
GO

CREATE OR ALTER PROCEDURE dbo.sp_SaoLuuHeThong
    @LoaiSaoLuu VARCHAR(10) = 'FULL',
    @DuongDanThuMuc NVARCHAR(500) = NULL,
    @TepSaoLuu NVARCHAR(1000) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @LoaiSaoLuu = UPPER(@LoaiSaoLuu);
    IF @LoaiSaoLuu IS NULL OR @LoaiSaoLuu NOT IN ('FULL', 'DIFF', 'LOG')
        THROW 51009, 'INVALID_BACKUP_TYPE', 1;
    DECLARE @TenCSDL SYSNAME = DB_NAME();
    IF @TenCSDL NOT LIKE N'HomeFix[_]%'
        THROW 51009, 'HOMEFIX_DATABASE_REQUIRED', 1;
    DECLARE @ThuMuc NVARCHAR(500) = NULLIF(RTRIM(@DuongDanThuMuc), N'');
    IF @ThuMuc IS NULL
        SET @ThuMuc = CONVERT(NVARCHAR(500), SERVERPROPERTY('InstanceDefaultBackupPath'));
    IF @ThuMuc IS NULL
        EXEC master.dbo.xp_instance_regread
            N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',
            N'BackupDirectory', @ThuMuc OUTPUT;
    IF NULLIF(@ThuMuc, N'') IS NULL
        THROW 51009, 'BACKUP_DIRECTORY_REQUIRED', 1;
    -- Mỗi lần gọi tạo tệp mới; không ghi đè chuỗi sao lưu cũ.
    SET @TepSaoLuu = @ThuMuc + N'\' + @TenCSDL + N'_' + @LoaiSaoLuu
        + N'_' + REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N'')
        + CASE WHEN @LoaiSaoLuu='LOG' THEN N'.trn' ELSE N'.bak' END;
    DECLARE @Lenh NVARCHAR(MAX) =
        CASE WHEN @LoaiSaoLuu='LOG' THEN N'BACKUP LOG ' ELSE N'BACKUP DATABASE ' END
        + QUOTENAME(@TenCSDL) + N' TO DISK=@Tep WITH CHECKSUM, '
        + CASE WHEN @LoaiSaoLuu='DIFF' THEN N'DIFFERENTIAL, ' ELSE N'' END
        + N'NOFORMAT, NOINIT, STATS=10;';
    EXEC sys.sp_executesql @Lenh, N'@Tep NVARCHAR(1000)', @Tep=@TepSaoLuu;
END;
GO

-- FULL recovery cần một bản full để khởi đầu chuỗi log.
ALTER DATABASE [$(TenCSDL)] SET RECOVERY FULL;
GO
DECLARE @Full NVARCHAR(1000), @Diff NVARCHAR(1000), @Log NVARCHAR(1000);
EXEC dbo.sp_SaoLuuHeThong 'FULL', @TepSaoLuu=@Full OUTPUT;
EXEC dbo.sp_SaoLuuHeThong 'DIFF', @TepSaoLuu=@Diff OUTPUT;
EXEC dbo.sp_SaoLuuHeThong 'LOG', @TepSaoLuu=@Log OUTPUT;
RESTORE VERIFYONLY FROM DISK=@Full WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@Diff WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@Log WITH CHECKSUM;
SELECT @Full AS TepFull, @Diff AS TepDiff, @Log AS TepLog;

-- Đặt ThucHienPhucHoi=1 để thực hành. Không dùng REPLACE, không ghi đè CSDL nguồn.
IF $(ThucHienPhucHoi) = 1
BEGIN
    DECLARE @Nguon SYSNAME = DB_NAME(), @Dich SYSNAME = DB_NAME() + N'_Restore';
    IF DB_ID(@Dich) IS NOT NULL
        THROW 51009, 'RESTORE_DATABASE_ALREADY_EXISTS', 1;
    -- Bộ cài HomeFix tạo một file dữ liệu và một file log.
    IF (SELECT COUNT(*) FROM sys.database_files WHERE type IN (0,1)) <> 2
        THROW 51009, 'CUSTOM_FILE_LAYOUT_REQUIRES_MANUAL_MOVE', 1;
    DECLARE @TenData SYSNAME, @TenLog SYSNAME, @Data NVARCHAR(1000), @LogFile NVARCHAR(1000);
    SELECT @TenData=name,
           @Data=LEFT(physical_name,LEN(physical_name)-CHARINDEX(N'\',REVERSE(physical_name))+1) + @Dich + N'.mdf'
    FROM sys.database_files WHERE type=0;
    SELECT @TenLog=name,
           @LogFile=LEFT(physical_name,LEN(physical_name)-CHARINDEX(N'\',REVERSE(physical_name))+1) + @Dich + N'_log.ldf'
    FROM sys.database_files WHERE type=1;
    DECLARE @Restore NVARCHAR(MAX) = N'RESTORE DATABASE ' + QUOTENAME(@Dich)
        + N' FROM DISK=@Full WITH MOVE @TenData TO @Data, MOVE @TenLog TO @LogFile, NORECOVERY, CHECKSUM;'
        + N'RESTORE DATABASE ' + QUOTENAME(@Dich) + N' FROM DISK=@Diff WITH NORECOVERY, CHECKSUM;'
        + N'RESTORE LOG ' + QUOTENAME(@Dich) + N' FROM DISK=@Log WITH RECOVERY, CHECKSUM;'
        + N'DBCC CHECKDB (' + QUOTENAME(@Dich) + N') WITH NO_INFOMSGS;';
    EXEC sys.sp_executesql @Restore,
        N'@Full NVARCHAR(1000),@Diff NVARCHAR(1000),@Log NVARCHAR(1000),@TenData SYSNAME,@Data NVARCHAR(1000),@TenLog SYSNAME,@LogFile NVARCHAR(1000)',
        @Full,@Diff,@Log,@TenData,@Data,@TenLog,@LogFile;
    SELECT @Dich AS CSDLPhucHoi;
END;
GO

-- Vấn đáp: NORECOVERY giữ DB ở trạng thái RESTORING để nhận bản tiếp theo;
-- RECOVERY kết thúc chuỗi và mở DB. DIFF phải cùng bản FULL nền.
-- Phục hồi theo thời điểm: áp dụng lần lượt các bản LOG liên tục, dùng STOPAT
-- ở bản log chứa thời điểm cần phục hồi. Cân nhắc tail-log backup nếu nguồn còn truy cập được.
-- Ví dụ minh họa (thay tên và đường dẫn bằng tệp trong chuỗi của bạn):
-- RESTORE LOG [HomeFix_PhucHoi] FROM DISK=N'D:\Backup\log.trn'
-- WITH STOPAT='2026-10-15T09:30:00', RECOVERY;
