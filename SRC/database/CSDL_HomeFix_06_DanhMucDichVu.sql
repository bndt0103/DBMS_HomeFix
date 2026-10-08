-- Phân loại dịch vụ phổ biến.
IF COL_LENGTH('dbo.DichVu', 'PhoBien') IS NULL
    ALTER TABLE dbo.DichVu
        ADD PhoBien BIT CONSTRAINT DF_DichVu_PhoBien DEFAULT 0 NOT NULL;
GO
