-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF COL_LENGTH('dbo.NguoiDung', 'KhoaDenNgay') IS NULL
    ALTER TABLE dbo.NguoiDung
        ADD KhoaDenNgay DATETIME2 NULL;

GO
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 7)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (7);
GO
