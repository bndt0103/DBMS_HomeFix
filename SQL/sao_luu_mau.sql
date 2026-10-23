USE [HomeFix_DBMS_Clean_20261022];
GO
/* Chạy bằng Windows Authentication có quyền sysadmin hoặc db_owner.
   Không chạy trong BEGIN TRANSACTION. SQL Server ghi lên ổ của máy chủ.
   Tạo tập tin mới, COPY_ONLY không thay đổi nền sao lưu vi sai hiện có. */
DECLARE @ThuMuc NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
IF @ThuMuc IS NULL THROW 51009, N'Không đọc được thư mục backup mặc định; DBA cần chỉ định đường dẫn tồn tại.', 1;
IF RIGHT(@ThuMuc, 1) NOT IN ('\', '/') SET @ThuMuc += N'\';
DECLARE @TapTin NVARCHAR(4000) = @ThuMuc + DB_NAME() + N'_MinhHoa_' + CONVERT(VARCHAR(36), NEWID()) + N'.bak';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = @TapTin, @Loai = 'FULL', @BanSaoDocLap = 1;
RESTORE VERIFYONLY FROM DISK = @TapTin WITH FILE = 1, CHECKSUM;
RESTORE FILELISTONLY FROM DISK = @TapTin WITH FILE = 1;
SELECT DB_NAME() AS TenCSDL, @TapTin AS TepSaoLuu, N'Đã sao lưu và VERIFYONLY thành công' AS KetQua;
/* VERIFYONLY không thay thế kiểm thử phục hồi thực tế.
   Khi RESTORE: dùng database đích MỚI, MOVE từng LogicalName tới file MDF/LDF mới.
   Không WITH REPLACE lên database đang dùng. Xem modules/10_backup_recovery.sql.
   FULL/DIFF/LOG trong module cần cùng chuỗi backup; COPY_ONLY này không tạo nền DIFF. */
GO
