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
/* CÁCH DEMO TRONG SSMS - chạy từng khối sau khi sửa tên database/đường dẫn:

-- 1. Chọn database muốn sao lưu, ghi nhận recovery model trước khi thay đổi.
SELECT name, recovery_model_desc FROM sys.databases WHERE name = DB_NAME();
-- Dùng đường dẫn tồn tại, service account SQL có quyền ghi. Ví dụ D:\SQLBackup.
-- Không chạy trên database đang có giao dịch nghiệp vụ ngoài ý muốn.
ALTER DATABASE HomeFix_DBMS SET RECOVERY FULL;
GO
USE HomeFix_DBMS;
GO
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Full_20261023.bak', @Loai = 'FULL';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Diff_20261023.bak', @Loai = 'DIFF';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Log_20261023.trn', @Loai = 'LOG';

-- 2. Xem thông tin backup set/logical name và kiểm tra backup có đọc được.
-- FILE = 1 phù hợp tập tin mới. Nếu đã backup nhiều lần cùng tập tin,
-- RESTORE HEADERONLY để chọn đúng Position, không mặc định bản mới nhất ở số 1.
RESTORE HEADERONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261023.bak';
RESTORE FILELISTONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261023.bak' WITH FILE = 1;
RESTORE VERIFYONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261023.bak' WITH FILE = 1, CHECKSUM;
-- VERIFYONLY kiểm tra backup; chưa chứng minh toàn bộ CSDL phục hồi hoạt động.

-- 3. Khôi phục ra TÊN MỚI, không WITH REPLACE. Sửa logical name theo FILELISTONLY.
USE master;
GO
RESTORE DATABASE HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261023.bak'
WITH FILE = 1, NORECOVERY,
    MOVE N'HomeFix_DBMS_Clean_20261022' TO N'D:\SQLData\HomeFix_KiemTraPhucHoi.mdf',
    MOVE N'HomeFix_DBMS_Clean_20261022_log' TO N'D:\SQLData\HomeFix_KiemTraPhucHoi_log.ldf';
RESTORE DATABASE HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Diff_20261023.bak' WITH FILE = 1, NORECOVERY;
RESTORE LOG HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Log_20261023.trn' WITH FILE = 1, RECOVERY;
-- Nếu chỉ phục hồi FULL: thay NORECOVERY bằng RECOVERY ở lệnh FULL và bỏ DIFF/LOG.
-- Nếu cần tới một thời điểm: thêm STOPAT = '2026-10-22T14:30:00' vào RESTORE LOG.
-- FULL/DIFF/LOG phải cùng chuỗi hợp lệ. COPY_ONLY FULL không lập nền cho DIFF.

-- 4. Kiểm tra CSDL được khôi phục. Không chạy web lên bản này ngoài ý muốn.
DBCC CHECKDB(N'HomeFix_KiemTraPhucHoi') WITH NO_INFOMSGS;
USE HomeFix_KiemTraPhucHoi;
SELECT Id, HoTen, VaiTro FROM dbo.vw_NguoiDung;
SELECT Id, TrangThai FROM dbo.vw_DonHangTongHop;
SELECT Id, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien;

LỖI THƯỜNG GẶP:
- 3201/Operating system error 3: sai đường dẫn trên máy SQL Server.
- Operating system error 5: service account SQL Server thiếu quyền thư mục.
- 4214: LOG chưa có full backup đầu tiên sau khi chuyển recovery model.
- 3117/4305: sai thứ tự hoặc thiếu mắt xích LOG, phải kiểm tra HEADERONLY.
- 3154: file thuộc database khác; dùng tên đích mới và MOVE đúng logical name.
- 'database is in use': cần dùng master và đóng kết nối tới bản phục hồi.
*/
