-- Ảnh đại diện và mục đích tệp đính kèm.
IF COL_LENGTH('dbo.NguoiDung', 'DuongDanAnhDaiDien') IS NULL
    ALTER TABLE dbo.NguoiDung
        ADD DuongDanAnhDaiDien NVARCHAR(500) NULL;
GO

DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId') OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;
GO

ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar'));
GO
