-- Mã xác thực tài khoản.
IF OBJECT_ID('dbo.XacThucOTP') IS NULL
    BEGIN
        -- Mã xác thực OTP.
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
        -- Tăng tốc tra cứu OTP theo người nhận và thời gian.
        CREATE INDEX IX_XacThucOTP_DiaChiNhan
            ON dbo.XacThucOTP (DiaChiNhan, NgayTao);
    END
GO
