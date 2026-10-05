-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF OBJECT_ID('dbo.XacThucOTP') IS NULL
    BEGIN
        CREATE TABLE dbo.XacThucOTP (
            Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            MucDich NVARCHAR(20) NOT NULL,
            KenhGui NVARCHAR(10) NOT NULL,
            DiaChiNhan NVARCHAR(200) NOT NULL,
            DuLieuRangBuoc NVARCHAR(64) NOT NULL,
            MaBamOTP NVARCHAR(64) NOT NULL,
            SoLanThu INT DEFAULT 0 NOT NULL,
            SanSang BIT DEFAULT 0 NOT NULL,
            DaSuDung BIT DEFAULT 0 NOT NULL,
            NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
            NgayHetHan DATETIME2 NOT NULL
        );
        CREATE INDEX IX_XacThucOTP_DiaChiNhan
            ON dbo.XacThucOTP(DiaChiNhan, NgayTao);
    END
GO
