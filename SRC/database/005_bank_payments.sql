-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET XACT_ABORT ON;

IF COL_LENGTH('dbo.DonHang', 'PhuongThucThanhToan') IS NULL
    ALTER TABLE dbo.DonHang
        ADD PhuongThucThanhToan VARCHAR(10) CONSTRAINT DF_DonHang_PhuongThucThanhToan DEFAULT 'COD' NOT NULL CONSTRAINT CK_DonHang_PhuongThucThanhToan CHECK (PhuongThucThanhToan IN ('COD', 'BANK'));

IF OBJECT_ID('dbo.TaiKhoanNhanTien') IS NULL
    CREATE TABLE dbo.TaiKhoanNhanTien (
        Id INT IDENTITY PRIMARY KEY,
        MaNganHang VARCHAR(20) NOT NULL,
        TenNganHang NVARCHAR(100) NOT NULL,
        SoTaiKhoan VARCHAR(30) NOT NULL,
        ChuTaiKhoan NVARCHAR(120) NOT NULL,
        DangHoatDong BIT DEFAULT 1 NOT NULL,
        NguoiTaoId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
        NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
        PhienBan ROWVERSION,
        CONSTRAINT UX_TaiKhoanNganHang UNIQUE (MaNganHang, SoTaiKhoan)
    );

GO
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.ThanhToan DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.ThanhToan') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.ThanhToan'), 'PhuongThuc', 'ColumnId') OR name = 'CK_ThanhToan_PhuongThuc');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.ThanhToan
    ADD CONSTRAINT CK_ThanhToan_PhuongThuc CHECK (PhuongThuc IN ('COD', 'BANK'));

SET @LenhSQL = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.ThanhToan DROP CONSTRAINT ' + QUOTENAME(f.name) + ';'
FROM sys.foreign_keys AS f
     INNER JOIN sys.foreign_key_columns AS c ON c.constraint_object_id = f.object_id
WHERE f.parent_object_id = OBJECT_ID('dbo.ThanhToan') AND c.parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.ThanhToan'), 'NguoiThuTienId', 'ColumnId');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.ThanhToan
    ADD CONSTRAINT FK_ThanhToan_NguoiThuTien FOREIGN KEY (NguoiThuTienId) REFERENCES dbo.NguoiDung (Id);

IF COL_LENGTH('dbo.ThanhToan', 'TaiKhoanNganHangId') IS NULL
    ALTER TABLE dbo.ThanhToan
        ADD TaiKhoanNganHangId INT NULL FOREIGN KEY REFERENCES dbo.TaiKhoanNhanTien (Id),
            MaThamChieuNganHang VARCHAR(100) NULL;

GO
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE name = 'UX_ThanhToan_MaThamChieuNganHang' AND object_id = OBJECT_ID('dbo.ThanhToan'))
    CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieuNganHang
        ON dbo.ThanhToan(TaiKhoanNganHangId, MaThamChieuNganHang) WHERE MaThamChieuNganHang IS NOT NULL;

IF OBJECT_ID('dbo.YeuCauThanhToan') IS NULL
    BEGIN
        CREATE TABLE dbo.YeuCauThanhToan (
            Id INT IDENTITY PRIMARY KEY,
            DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
            NghiemThuId INT NOT NULL FOREIGN KEY REFERENCES dbo.PhieuNghiemThu (Id),
            KhachHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
            TaiKhoanNganHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.TaiKhoanNhanTien (Id),
            MaNganHang VARCHAR(20) NOT NULL,
            TenNganHang NVARCHAR(100) NOT NULL,
            SoTaiKhoan VARCHAR(30) NOT NULL,
            ChuTaiKhoan NVARCHAR(120) NOT NULL,
            SoTien DECIMAL(18, 2) NOT NULL CHECK (SoTien > 0),
            NoiDungChuyenKhoan VARCHAR(60) NULL,
            TrangThai VARCHAR(20) DEFAULT 'AwaitingTransfer' NOT NULL CHECK (TrangThai IN ('AwaitingTransfer', 'PendingReview', 'Confirmed', 'Rejected', 'Cancelled')),
            DangHoatDong BIT DEFAULT 1 NOT NULL,
            ChungTuId INT NULL FOREIGN KEY REFERENCES dbo.TepDinhKem (Id),
            MaThamChieuKhachHang NVARCHAR(100) NULL,
            LyDo NVARCHAR(1000) NULL,
            NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
            ThanhToanId INT NULL FOREIGN KEY REFERENCES dbo.ThanhToan (Id),
            NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
            NgayGui DATETIME2 NULL,
            NgayDuyet DATETIME2 NULL,
            PhienBan ROWVERSION
        );
        CREATE UNIQUE INDEX UX_ChuyenKhoan_DangHoatDong
            ON dbo.YeuCauThanhToan(DonHangId) WHERE DangHoatDong = 1;
        CREATE UNIQUE INDEX UX_ChuyenKhoan_NoiDung
            ON dbo.YeuCauThanhToan(NoiDungChuyenKhoan) WHERE NoiDungChuyenKhoan IS NOT NULL;
        CREATE UNIQUE INDEX UX_ChuyenKhoan_ChungTu
            ON dbo.YeuCauThanhToan(ChungTuId) WHERE ChungTuId IS NOT NULL;
    END

GO
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId') OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof'));

SET @LenhSQL = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.GiaoDichVi DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.GiaoDichVi') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.GiaoDichVi'), 'Loai', 'ColumnId') OR name = 'CK_Vi_Loai');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.GiaoDichVi
    ADD CONSTRAINT CK_Vi_Loai CHECK (Loai IN ('Opening', 'Deposit', 'Withdrawal', 'Commission', 'Reversal', 'SettlementCredit'));

GO
CREATE OR ALTER TRIGGER dbo.trg_DanhGia_DieuKien
    ON dbo.DanhGia
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.DonHang AS d ON d.Id = i.DonHangId
                    LEFT OUTER JOIN dbo.ThanhToan AS p ON p.DonHangId = d.Id
                    LEFT OUTER JOIN dbo.PhieuNghiemThu AS a ON a.Id = p.NghiemThuId
               WHERE i.KhachHangId <> d.KhachHangId OR d.TrangThai <> 'HoanThanh' OR p.Id IS NULL OR i.KyThuatVienId <> a.KyThuatVienId)
        THROW 51009, 'REVIEW_NOT_ELIGIBLE', 1;
END
GO
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 5)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (5);
GO
