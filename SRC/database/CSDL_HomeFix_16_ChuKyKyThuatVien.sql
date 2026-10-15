-- Tach chu ky cua KTV khoi chu ky khach hang tren phieu nghiem thu.
IF COL_LENGTH('dbo.PhieuNghiemThu', 'ChuKyKTVId') IS NULL
    ALTER TABLE dbo.PhieuNghiemThu ADD ChuKyKTVId INT NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_NghiemThu_ChuKyKTV'
)
    ALTER TABLE dbo.PhieuNghiemThu
        ADD CONSTRAINT FK_NghiemThu_ChuKyKTV FOREIGN KEY (ChuKyKTVId) REFERENCES dbo.TepDinhKem (Id);
GO

DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem')
  AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId');

EXECUTE sp_executesql @LenhSQL;
GO

ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (
        MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'TechnicianSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar')
    );
GO
