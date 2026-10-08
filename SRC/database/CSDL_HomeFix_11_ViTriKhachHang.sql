-- Vị trí khách hàng theo đơn hàng.
IF OBJECT_ID('dbo.ViTriKhachHang', 'U') IS NULL
    BEGIN
        -- Vị trí khách hàng.
        CREATE TABLE dbo.ViTriKhachHang (
            DonHangId INT NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES dbo.DonHang (Id),
            ViDo DECIMAL(10, 7) NOT NULL CHECK (ViDo BETWEEN -90 AND 90),
            KinhDo DECIMAL(10, 7) NOT NULL CHECK (KinhDo BETWEEN -180 AND 180),
            DoChinhXacMet DECIMAL(12, 2) NOT NULL CHECK (DoChinhXacMet BETWEEN 0 AND 100000),
            NgayCapNhatViTri DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
        );
    END
GO
