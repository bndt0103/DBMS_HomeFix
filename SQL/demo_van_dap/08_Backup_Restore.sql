-- Demo FULL -> DIFF -> LOG voi du lieu thay doi giua cac ban sao.
-- Chay TOAN BO file trong SSMS, khong can SQLCMD Mode.
-- Chi doi recovery cua DB on tap. Khong ghi de DB nguon hay DB dich da co.
USE master;
GO
SET NOCOUNT ON;
DECLARE @Nguon SYSNAME=N'HomeFix_VanDap_20261022', @Dich SYSNAME=N'HomeFix_VanDap_20261022_Restore';
IF DB_ID(@Nguon) IS NULL THROW 51999,'CHUA_TAO_DATABASE_DEMO',1;
IF DB_ID(@Dich) IS NOT NULL THROW 51999,'DATABASE_RESTORE_DA_CO_CHON_TEN_DICH_MOI',1;
DECLARE @ThuMuc NVARCHAR(1000)=CONVERT(NVARCHAR(1000),SERVERPROPERTY('InstanceDefaultBackupPath'));
IF @ThuMuc IS NULL THROW 51999,'CAN_KIEM_TRA_THU_MUC_BACKUP',1;
DECLARE @Ma NVARCHAR(32)=REPLACE(CONVERT(NVARCHAR(36),NEWID()),'-','');
DECLARE @Full NVARCHAR(1000)=@ThuMuc+N'\'+@Nguon+N'_'+@Ma+N'_Full.bak';
DECLARE @Diff NVARCHAR(1000)=@ThuMuc+N'\'+@Nguon+N'_'+@Ma+N'_Diff.bak';
DECLARE @Log NVARCHAR(1000)=@ThuMuc+N'\'+@Nguon+N'_'+@Ma+N'_Log.trn';
DECLARE @DataDir NVARCHAR(1000)=CONVERT(NVARCHAR(1000),SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogDir NVARCHAR(1000)=CONVERT(NVARCHAR(1000),SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @DataName SYSNAME,@LogName SYSNAME,@DataFile NVARCHAR(1000),@LogFile NVARCHAR(1000);
IF (SELECT COUNT(*) FROM sys.master_files WHERE database_id=DB_ID(@Nguon))<>2
    THROW 51999,'DEMO_CHI_HO_TRO_MOT_DATA_MOT_LOG',1;
SELECT @DataName=name FROM sys.master_files WHERE database_id=DB_ID(@Nguon) AND type=0;
SELECT @LogName=name FROM sys.master_files WHERE database_id=DB_ID(@Nguon) AND type=1;
SET @DataFile=@DataDir+@Dich+N'.mdf';
SET @LogFile=@LogDir+@Dich+N'_log.ldf';
DECLARE @Q NVARCHAR(MAX)=N'ALTER DATABASE '+QUOTENAME(@Nguon)+N' SET RECOVERY FULL;';
EXEC sys.sp_executesql @Q;
BACKUP DATABASE @Nguon TO DISK=@Full WITH CHECKSUM, STATS=10;
DECLARE @Khoa VARCHAR(80)='VanDap_'+CONVERT(VARCHAR(32),@Ma);
SET @Q=N'INSERT '+QUOTENAME(@Nguon)+N'.dbo.CauHinh (KhoaCauHinh,GiaTri,NhanHienThi) VALUES (@K,N''SAU_FULL'',N''Moc demo backup'');';
EXEC sys.sp_executesql @Q,N'@K VARCHAR(80)',@Khoa;
BACKUP DATABASE @Nguon TO DISK=@Diff WITH DIFFERENTIAL,CHECKSUM,STATS=10;
SET @Q=N'UPDATE '+QUOTENAME(@Nguon)+N'.dbo.CauHinh SET GiaTri=N''SAU_DIFF'' WHERE KhoaCauHinh=@K;';
EXEC sys.sp_executesql @Q,N'@K VARCHAR(80)',@Khoa;
BACKUP LOG @Nguon TO DISK=@Log WITH CHECKSUM,STATS=10;
RESTORE VERIFYONLY FROM DISK=@Full WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@Diff WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK=@Log WITH CHECKSUM;
RESTORE FILELISTONLY FROM DISK=@Full;
RESTORE DATABASE @Dich FROM DISK=@Full
WITH MOVE @DataName TO @DataFile, MOVE @LogName TO @LogFile,NORECOVERY,CHECKSUM;
RESTORE DATABASE @Dich FROM DISK=@Diff WITH NORECOVERY,CHECKSUM;
RESTORE LOG @Dich FROM DISK=@Log WITH RECOVERY,CHECKSUM;
SET @Q=N'DBCC CHECKDB ('+QUOTENAME(@Dich)+N') WITH NO_INFOMSGS;'
    +N'SELECT KhoaCauHinh,GiaTri FROM '+QUOTENAME(@Dich)+N'.dbo.CauHinh WHERE KhoaCauHinh=@K;'
    +N'IF NOT EXISTS (SELECT 1 FROM '+QUOTENAME(@Dich)+N'.dbo.CauHinh WHERE KhoaCauHinh=@K AND GiaTri=N''SAU_DIFF'') THROW 51999,''RESTORE_DATA_MISMATCH'',1;';
EXEC sys.sp_executesql @Q,N'@K VARCHAR(80)',@Khoa;
SELECT name,state_desc,recovery_model_desc FROM sys.databases WHERE name IN (@Nguon,@Dich);
SELECT @Full AS TepFull,@Diff AS TepDiff,@Log AS TepLog,@Dich AS DatabasePhucHoi;
GO
