-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF COL_LENGTH('dbo.HoSoKTV', 'HoSoJSON') IS NULL
    ALTER TABLE dbo.HoSoKTV
        ADD HoSoJSON NVARCHAR(2000) NULL;

IF COL_LENGTH('dbo.HoSoKTV', 'GiayToMatTruocId') IS NULL
    ALTER TABLE dbo.HoSoKTV
        ADD GiayToMatTruocId INT NULL FOREIGN KEY REFERENCES dbo.TepDinhKem (Id);

IF COL_LENGTH('dbo.HoSoKTV', 'GiayToMatSauId') IS NULL
    ALTER TABLE dbo.HoSoKTV
        ADD GiayToMatSauId INT NULL FOREIGN KEY REFERENCES dbo.TepDinhKem (Id);

IF COL_LENGTH('dbo.HoSoKTV', 'SoGiayTo') IS NULL
    ALTER TABLE dbo.HoSoKTV
        ADD SoGiayTo VARCHAR(12) NULL;

IF COL_LENGTH('dbo.PhieuNghiemThu', 'PhuongThucThanhToanDeXuat') IS NULL
    ALTER TABLE dbo.PhieuNghiemThu
        ADD PhuongThucThanhToanDeXuat VARCHAR(10) NULL CHECK (PhuongThucThanhToanDeXuat IN ('COD', 'BANK'));
GO
