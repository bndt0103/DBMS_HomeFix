-- Phí hủy tại thời điểm đặt đơn.
IF COL_LENGTH('dbo.DonHang', 'PhiHuyTaiThoiDiemDat') IS NULL
    ALTER TABLE dbo.DonHang
        ADD PhiHuyTaiThoiDiemDat DECIMAL(18, 2) CONSTRAINT DF_DonHang_PhiHuyTaiThoiDiemDat DEFAULT 50000 WITH VALUES NOT NULL CONSTRAINT CK_DonHang_PhiHuyTaiThoiDiemDat CHECK (PhiHuyTaiThoiDiemDat >= 0);
GO

IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 2)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (2);
GO
