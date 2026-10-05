-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF COL_LENGTH('dbo.DichVu', 'PhoBien') IS NULL
    ALTER TABLE dbo.DichVu
        ADD PhoBien BIT CONSTRAINT DF_DichVu_PhoBien DEFAULT 0 NOT NULL;
GO
