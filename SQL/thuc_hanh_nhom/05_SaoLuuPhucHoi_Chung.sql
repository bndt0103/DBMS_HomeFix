USE [HomeFix_DBMS_Clean_20261022];
GO
SET NOCOUNT ON;
/* THỰC HÀNH CHUNG - V10/T10/D10/A10. Mỗi thành viên tự thực hiện toàn bộ. Chạy TRỌN khối sau GO bằng DBA, không bôi đen từng lệnh con.
   1. Sao lưu COPY_ONLY CSDL hiện tại, không đổi recovery model của bản gốc.
   2. Phục hồi thành bản thực hành, trên bản đó làm FULL -> DIFF -> LOG.
   3. Phục hồi sang bản kiểm chứng khác, kiểm tra đủ dữ liệu, rồi gỡ hai bản thực hành.
   Các tệp backup được giữ trong thư mục mặc định của SQL Server để đối chiếu.
   Không dùng WITH REPLACE. Không tự xóa bất kỳ database có sẵn nào.
   Script dành cho cấu trúc HomeFix hiện tại: một data file và một log file. */
IF @@TRANCOUNT <> 0 THROW 51999, N'BACKUP/RESTORE không chạy bên trong transaction người dùng.', 1;
IF IS_SRVROLEMEMBER('sysadmin') <> 1 THROW 51999, N'Bài tạo/phục hồi CSDL thực hành cần chạy bằng DBA sysadmin.', 1;
IF (SELECT COUNT(*) FROM sys.database_files WHERE type IN (0, 1)) <> 2
    THROW 51999, N'Hãy kiểm tra FILELISTONLY và thêm MOVE cho từng file nếu CSDL có hơn hai file.', 1;

DECLARE @Ma VARCHAR(12) = LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 12);
DECLARE @TenNguon SYSNAME = N'HomeFix_TH_Nguon_' + @Ma;
DECLARE @TenDich SYSNAME = N'HomeFix_TH_PhucHoi_' + @Ma;
DECLARE @DaTaoNguon BIT = 0, @DaTaoDich BIT = 0;
DECLARE @ThuMucBackup NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
DECLARE @ThuMucData NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @ThuMucLog NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @TepGoc NVARCHAR(4000) = @ThuMucBackup + N'\HomeFix_TH_' + @Ma + N'_Goc.bak';
DECLARE @TepFull NVARCHAR(4000) = @ThuMucBackup + N'\HomeFix_TH_' + @Ma + N'_Full.bak';
DECLARE @TepDiff NVARCHAR(4000) = @ThuMucBackup + N'\HomeFix_TH_' + @Ma + N'_Diff.bak';
DECLARE @TepLog NVARCHAR(4000) = @ThuMucBackup + N'\HomeFix_TH_' + @Ma + N'_Log.trn';
DECLARE @LogicalData SYSNAME = (SELECT name FROM sys.database_files WHERE type = 0);
DECLARE @LogicalLog SYSNAME = (SELECT name FROM sys.database_files WHERE type = 1);
DECLARE @Lenh NVARCHAR(MAX), @ThuTuc NVARCHAR(776);

BEGIN TRY
    IF DB_ID(@TenNguon) IS NOT NULL OR DB_ID(@TenDich) IS NOT NULL
        THROW 51999, N'Tên thực hành bị trùng, dừng để không đụng bản có sẵn.', 1;

    -- A08.1. BẢN GỐC: chỉ tạo backup độc lập. File mới nên FILE = 1 là backup set cần dùng.
    EXEC dbo.sp_SaoLuuHeThong @DuongDan = @TepGoc, @Loai = 'FULL', @BanSaoDocLap = 1;
    RESTORE VERIFYONLY FROM DISK = @TepGoc WITH FILE = 1, CHECKSUM;
    RESTORE FILELISTONLY FROM DISK = @TepGoc WITH FILE = 1;
    -- LogicalName là tên nội bộ trong backup; PhysicalName là đường dẫn file trên máy chủ.

    -- A08.2. TẠO BẢN THỰC HÀNH bằng tên và đường dẫn mới.
    SET @DaTaoNguon = 1;
    SET @Lenh = N'RESTORE DATABASE ' + QUOTENAME(@TenNguon) + N' FROM DISK = N''' + REPLACE(@TepGoc, '''', '''''') + N'''
        WITH FILE = 1, RECOVERY,
        MOVE N''' + REPLACE(@LogicalData, '''', '''''') + N''' TO N''' + REPLACE(@ThuMucData + @TenNguon + N'.mdf', '''', '''''') + N''',
        MOVE N''' + REPLACE(@LogicalLog, '''', '''''') + N''' TO N''' + REPLACE(@ThuMucLog + @TenNguon + N'_log.ldf', '''', '''''') + N''';';
    EXEC(@Lenh);
    SET @Lenh = N'ALTER DATABASE ' + QUOTENAME(@TenNguon) + N' SET RECOVERY FULL;';
    EXEC(@Lenh);
    SET @Lenh = N'CREATE TABLE ' + QUOTENAME(@TenNguon) + N'.dbo.ThucHanhPhucHoi(Id INT PRIMARY KEY, NoiDung NVARCHAR(100));
        INSERT INTO ' + QUOTENAME(@TenNguon) + N'.dbo.ThucHanhPhucHoi(Id, NoiDung) VALUES (1, N''Có trước FULL'');';
    EXEC(@Lenh);

    -- A08.3. FULL làm nền cho DIFF; không dùng COPY_ONLY cho FULL này.
    SET @ThuTuc = QUOTENAME(@TenNguon) + N'.dbo.sp_SaoLuuHeThong';
    EXEC @ThuTuc @DuongDan = @TepFull, @Loai = 'FULL';
    SET @Lenh = N'INSERT INTO ' + QUOTENAME(@TenNguon) + N'.dbo.ThucHanhPhucHoi(Id, NoiDung) VALUES (2, N''Có sau FULL, trước DIFF'');';
    EXEC(@Lenh);
    EXEC @ThuTuc @DuongDan = @TepDiff, @Loai = 'DIFF';
    SET @Lenh = N'INSERT INTO ' + QUOTENAME(@TenNguon) + N'.dbo.ThucHanhPhucHoi(Id, NoiDung) VALUES (3, N''Có sau DIFF, trước LOG'');';
    EXEC(@Lenh);
    EXEC @ThuTuc @DuongDan = @TepLog, @Loai = 'LOG';
    RESTORE VERIFYONLY FROM DISK = @TepFull WITH FILE = 1, CHECKSUM;
    RESTORE VERIFYONLY FROM DISK = @TepDiff WITH FILE = 1, CHECKSUM;
    RESTORE VERIFYONLY FROM DISK = @TepLog WITH FILE = 1, CHECKSUM;

    -- A08.4. PHỤC HỒI: FULL -> DIFF -> LOG. Chỉ RECOVERY ở bước cuối.
    SET @DaTaoDich = 1;
    SET @Lenh = N'RESTORE DATABASE ' + QUOTENAME(@TenDich) + N' FROM DISK = N''' + REPLACE(@TepFull, '''', '''''') + N'''
        WITH FILE = 1, NORECOVERY,
        MOVE N''' + REPLACE(@LogicalData, '''', '''''') + N''' TO N''' + REPLACE(@ThuMucData + @TenDich + N'.mdf', '''', '''''') + N''',
        MOVE N''' + REPLACE(@LogicalLog, '''', '''''') + N''' TO N''' + REPLACE(@ThuMucLog + @TenDich + N'_log.ldf', '''', '''''') + N''';';
    EXEC(@Lenh);
    SET @Lenh = N'RESTORE DATABASE ' + QUOTENAME(@TenDich) + N' FROM DISK = N''' + REPLACE(@TepDiff, '''', '''''') + N''' WITH FILE = 1, NORECOVERY;';
    EXEC(@Lenh);
    SET @Lenh = N'RESTORE LOG ' + QUOTENAME(@TenDich) + N' FROM DISK = N''' + REPLACE(@TepLog, '''', '''''') + N''' WITH FILE = 1, RECOVERY;';
    EXEC(@Lenh);

    -- A08.5. CHỨNG MINH PHỤC HỒI, không chỉ VERIFYONLY.
    SET @Lenh = N'SELECT Id, NoiDung FROM ' + QUOTENAME(@TenDich) + N'.dbo.ThucHanhPhucHoi ORDER BY Id;
        IF (SELECT COUNT(*) FROM ' + QUOTENAME(@TenDich) + N'.dbo.ThucHanhPhucHoi) <> 3
            THROW 51999, N''Phục hồi chưa đủ ba thời điểm dữ liệu.'', 1;
        SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM ' + QUOTENAME(@TenDich) + N'.dbo.vw_ViKyThuatVien;
        DBCC CHECKDB(' + QUOTENAME(@TenDich) + N') WITH NO_INFOMSGS;';
    EXEC(@Lenh);
    SELECT N'Đã phục hồi đủ 3 dòng, CHECKDB hoàn tất' AS KetQua,
        @TepGoc AS BanSaoGoc, @TepFull AS FullBackup, @TepDiff AS DiffBackup, @TepLog AS LogBackup;

    -- A08.6. DỌN đúng hai bản vừa tạo. Không gỡ database gốc.
    SET @Lenh = N'ALTER DATABASE ' + QUOTENAME(@TenDich) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ' + QUOTENAME(@TenDich) + N';';
    EXEC(@Lenh);
    SET @DaTaoDich = 0;
    SET @Lenh = N'ALTER DATABASE ' + QUOTENAME(@TenNguon) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ' + QUOTENAME(@TenNguon) + N';';
    EXEC(@Lenh);
    SET @DaTaoNguon = 0;
END TRY
BEGIN CATCH
    -- Chỉ dọn các tên ngẫu nhiên do chính lượt chạy này sinh ra.
    IF @DaTaoDich = 1 AND DB_ID(@TenDich) IS NOT NULL
    BEGIN
        SET @Lenh = N'ALTER DATABASE ' + QUOTENAME(@TenDich) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ' + QUOTENAME(@TenDich) + N';';
        EXEC(@Lenh);
    END;
    IF @DaTaoNguon = 1 AND DB_ID(@TenNguon) IS NOT NULL
    BEGIN
        SET @Lenh = N'ALTER DATABASE ' + QUOTENAME(@TenNguon) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ' + QUOTENAME(@TenNguon) + N';';
        EXEC(@Lenh);
    END;
    THROW;
END CATCH;
SELECT DB_NAME() AS VanLaDatabaseGoc, @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO
