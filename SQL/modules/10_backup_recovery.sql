SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/* Sao lưu/phục hồi thuộc quyền DBA, không cho tài khoản ứng dụng chạy từ web.
   LƯU Ý SQL Server: BACKUP/RESTORE KHÔNG được chạy bên trong BEGIN TRANSACTION.
   Đây là ngoại lệ kỹ thuật của lệnh quản trị, không phải CRUD ngoài giao dịch.
   Module chỉ tạo thủ tục và hướng dẫn; cài đặt không tự sao lưu/xóa/phục hồi.
   Thư mục đích nằm trên MÁY CHỦ SQL Server, service account phải có quyền ghi. */
CREATE OR ALTER PROCEDURE dbo.sp_SaoLuuHeThong
    @DuongDan NVARCHAR(4000),
    @Loai VARCHAR(4) = 'FULL',
    @BanSaoDocLap BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1 AND ISNULL(IS_ROLEMEMBER('db_owner'), 0) <> 1
        THROW 51003, N'Chỉ quản trị viên SQL Server/db_owner được sao lưu.', 1;
    IF @@TRANCOUNT > 0 THROW 51009, N'BACKUP không được chạy trong giao dịch đang mở.', 1;
    IF @Loai NOT IN ('FULL','DIFF','LOG') THROW 51009, N'Loại sao lưu chỉ gồm FULL, DIFF, LOG.', 1;
    IF NULLIF(LTRIM(RTRIM(@DuongDan)), N'') IS NULL
        THROW 51009, N'Phải cung cấp đường dẫn tập tin trên máy chủ SQL Server.', 1;
    IF @BanSaoDocLap = 1 AND @Loai <> 'FULL'
        THROW 51009, N'Bản sao độc lập COPY_ONLY chỉ dùng với FULL trong bài này.', 1;
    DECLARE @TenCSDL SYSNAME = DB_NAME();
    BEGIN TRY
        -- NOINIT: bổ sung backup set, không ghi đè backup cũ nếu trùng đường dẫn.
        -- Khi demo nên dùng tên tập tin mới cho từng lần chạy.
        IF @Loai = 'FULL' AND @BanSaoDocLap = 1
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH COPY_ONLY, NOINIT, CHECKSUM, STATS = 10;
        ELSE IF @Loai = 'FULL'
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH NOINIT, CHECKSUM, STATS = 10;
        ELSE IF @Loai = 'DIFF'
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH DIFFERENTIAL, NOINIT, CHECKSUM, STATS = 10;
        ELSE
        BEGIN
            IF DATABASEPROPERTYEX(@TenCSDL, 'Recovery') <> 'FULL'
                THROW 51009, N'Sao lưu LOG yêu cầu recovery model FULL và full backup đầu tiên.', 1;
            BACKUP LOG @TenCSDL TO DISK = @DuongDan WITH NOINIT, CHECKSUM, STATS = 10;
        END;
        SELECT @TenCSDL AS TenCSDL, @Loai AS Loai, @DuongDan AS DuongDan, SYSUTCDATETIME() AS NgayHoanTat;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
