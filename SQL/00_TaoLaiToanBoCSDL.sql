-- Đồ án Hệ quản trị cơ sở dữ liệu DBMS330284, Nhóm 08.
-- Chạy bằng sqlcmd hoặc bật SQLCMD Mode trong SSMS.
-- Đổi TenCSDL nếu cần; script từ chối ghi vào CSDL đã tồn tại.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08_Import"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO

-- ===== 001_schema.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

GO
CREATE TABLE dbo.PhienBanCSDL (
    PhienBan INT NOT NULL PRIMARY KEY,
    NgayApDung DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.NguoiDung (
    Id INT IDENTITY PRIMARY KEY,
    HoTen NVARCHAR(120) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL UNIQUE,
    Email NVARCHAR(200) NULL,
    CCCD VARCHAR(12) NULL,
    MatKhauBam VARCHAR(100) NOT NULL,
    VaiTro VARCHAR(10) NOT NULL CHECK (VaiTro IN ('KH', 'KTV', 'DPV', 'CSKH', 'KT', 'ADMIN', 'GD')),
    DiaChiMacDinh NVARCHAR(500) NULL,
    DangHoatDong BIT DEFAULT 1 NOT NULL,
    PhienBanXacThuc INT DEFAULT 0 NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    PhienBan ROWVERSION
);

CREATE UNIQUE INDEX UX_NguoiDung_Email
    ON dbo.NguoiDung(Email) WHERE Email IS NOT NULL;

CREATE UNIQUE INDEX UX_NguoiDung_CCCD
    ON dbo.NguoiDung(CCCD) WHERE CCCD IS NOT NULL;

CREATE TABLE dbo.KyThuatVien (
    Id INT PRIMARY KEY FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NhomTayNghe NVARCHAR(60) NOT NULL,
    KhuVucPhucVu NVARCHAR(120) NOT NULL,
    TrangThaiSanSang VARCHAR(15) DEFAULT 'TamBan' NOT NULL CHECK (TrangThaiSanSang IN ('SanSang', 'TamBan', 'DangBan')),
    SoDu DECIMAL(18, 2) DEFAULT 0 NOT NULL CHECK (SoDu >= 0),
    ViDo DECIMAL(10, 7) NULL,
    KinhDo DECIMAL(10, 7) NULL,
    DoChinhXacMet DECIMAL(12, 2) NULL,
    NgayCapNhatViTri DATETIME2 NULL,
    PhienBan ROWVERSION,
    CHECK (ViDo BETWEEN -90 AND 90),
    CHECK (KinhDo BETWEEN -180 AND 180)
);

CREATE TABLE dbo.DichVu (
    Id INT IDENTITY PRIMARY KEY,
    Ten NVARCHAR(150) NOT NULL,
    MaNhom NVARCHAR(60) NOT NULL,
    MoTa NVARCHAR(1500) NOT NULL,
    PhiKiemTra DECIMAL(18, 2) NOT NULL CHECK (PhiKiemTra >= 0),
    TienCong DECIMAL(18, 2) NOT NULL CHECK (TienCong >= 0),
    TyLeHoaHong DECIMAL(5, 2) NOT NULL CHECK (TyLeHoaHong BETWEEN 0 AND 100),
    PhoBien BIT DEFAULT 0 NOT NULL,
    DangHoatDong BIT DEFAULT 1 NOT NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.DonHang (
    Id INT IDENTITY PRIMARY KEY,
    KhachHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    DichVuId INT NOT NULL FOREIGN KEY REFERENCES dbo.DichVu (Id),
    TenDichVu NVARCHAR(150) NOT NULL,
    NhomDichVu NVARCHAR(60) NOT NULL,
    TenLienHe NVARCHAR(120) NOT NULL,
    SoDienThoaiLienHe VARCHAR(15) NOT NULL,
    DiaChi NVARCHAR(500) NOT NULL,
    MoTa NVARCHAR(2000) NOT NULL,
    NgayHen DATETIME2 NULL,
    TrangThai VARCHAR(30) DEFAULT 'ChoTiepNhan' NOT NULL CHECK (TrangThai IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi', 'DangXuLy', 'ChoNghiemThu', 'HoanThanh', 'Huy')),

    KyThuatVienDuocGiaoId INT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    NgayKhoiHanh DATETIME2 NULL,
    LyDoHuy NVARCHAR(1000) NULL,
    PhiHuy DECIMAL(18, 2) DEFAULT 0 NOT NULL CHECK (PhiHuy >= 0),
    TrangThaiThanhToanPhiHuy VARCHAR(10) DEFAULT 'Unpaid' NOT NULL,
    NgayHuy DATETIME2 NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayCapNhat DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    PhienBan ROWVERSION
);

CREATE INDEX IX_DonHang_KhachHang
    ON dbo.DonHang(KhachHangId, NgayTao DESC);

CREATE INDEX IX_DonHang_TrangThai
    ON dbo.DonHang(TrangThai, NgayTao);

CREATE TABLE dbo.BaoGiaSoBo (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.DonHang (Id),
    ChanDoan NVARCHAR(2000) NOT NULL,
    PhiKiemTra DECIMAL(18, 2) NOT NULL CHECK (PhiKiemTra >= 0),
    TienCong DECIMAL(18, 2) NOT NULL CHECK (TienCong >= 0),
    TyLeHoaHong DECIMAL(5, 2) NOT NULL CHECK (TyLeHoaHong BETWEEN 0 AND 100),
    TongTien AS CAST (PhiKiemTra + TienCong AS DECIMAL(18, 2)),
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'Rejected')),
    NguoiTaoId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayDuyet DATETIME2 NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.LenhDieuPhoi (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Accepted', 'Rejected', 'Expired')),
    DangHoatDong BIT DEFAULT 1 NOT NULL,
    NgayHetHan DATETIME2 NOT NULL,
    NguoiTaoId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayDuyet DATETIME2 NULL,
    PhienBan ROWVERSION
);

CREATE UNIQUE INDEX UX_PhanCong_DonHang
    ON dbo.LenhDieuPhoi(DonHangId) WHERE DangHoatDong = 1;

CREATE UNIQUE INDEX UX_PhanCong_KyThuatVien
    ON dbo.LenhDieuPhoi(KyThuatVienId) WHERE DangHoatDong = 1;

CREATE TABLE dbo.DeXuatVatTu (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    LanSuaDoi INT NOT NULL,
    DangApDung BIT DEFAULT 1 NOT NULL,
    GhiChu NVARCHAR(1000) NULL,
    TongTien DECIMAL(18, 2) DEFAULT 0 NOT NULL CHECK (TongTien >= 0),
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'Rejected')),
    NguoiTaoId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayDuyet DATETIME2 NULL,
    PhienBan ROWVERSION,
    UNIQUE (DonHangId, LanSuaDoi)
);

CREATE UNIQUE INDEX UX_VatTu_DangApDung
    ON dbo.DeXuatVatTu(DonHangId) WHERE DangApDung = 1;

CREATE TABLE dbo.ChiTietDeXuatVatTu (
    Id INT IDENTITY PRIMARY KEY,
    BaoGiaId INT NOT NULL FOREIGN KEY REFERENCES dbo.DeXuatVatTu (Id),
    Ten NVARCHAR(200) NOT NULL,
    SoLuong DECIMAL(10, 2) NOT NULL CHECK (SoLuong > 0 AND SoLuong <= 999.99),
    DonViTinh NVARCHAR(30) NOT NULL,
    DonGia DECIMAL(18, 2) NOT NULL CHECK (DonGia >= 0 AND DonGia <= 100000000),
    ThanhTien AS CAST (ROUND(SoLuong * DonGia, 2) AS DECIMAL(18, 2)) PERSISTED,
    SoThangBaoHanh INT DEFAULT 0 NOT NULL CHECK (SoThangBaoHanh BETWEEN 0 AND 60)
);

CREATE TABLE dbo.PhieuNghiemThu (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    LanSuaDoi INT NOT NULL,
    NguyenNhan NVARCHAR(2000) NOT NULL,
    PhuongAnXuLy NVARCHAR(2000) NOT NULL,
    DeXuatVatTuId INT NULL FOREIGN KEY REFERENCES dbo.DeXuatVatTu (Id),
    PhiKiemTra DECIMAL(18, 2) NOT NULL CHECK (PhiKiemTra >= 0),
    TienCong DECIMAL(18, 2) NOT NULL CHECK (TienCong >= 0),
    TongTienVatTu DECIMAL(18, 2) NOT NULL CHECK (TongTienVatTu >= 0),
    TongTien AS CAST (PhiKiemTra + TienCong + TongTienVatTu AS DECIMAL(18, 2)),
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'Rejected')),
    NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NULL,
    ChuKyId INT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayDuyet DATETIME2 NULL,
    PhienBan ROWVERSION,
    UNIQUE (DonHangId, LanSuaDoi)
);

CREATE UNIQUE INDEX UX_NghiemThu_ChoDuyet
    ON dbo.PhieuNghiemThu(DonHangId) WHERE TrangThai = 'Pending';

CREATE UNIQUE INDEX UX_NghiemThu_DaDuyet
    ON dbo.PhieuNghiemThu(DonHangId) WHERE TrangThai = 'Approved';

CREATE TABLE dbo.TepDinhKem (
    Id INT IDENTITY PRIMARY KEY,
    ChuSoHuuId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    DonHangId INT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    NghiemThuId INT NULL FOREIGN KEY REFERENCES dbo.PhieuNghiemThu (Id),
    MucDich VARCHAR(30) NOT NULL CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'WalletProof', 'TechnicianDocument')),
    KhoaLuuTru VARCHAR(100) NOT NULL UNIQUE,
    TenTepGoc NVARCHAR(255) NOT NULL,
    KieuMIME VARCHAR(50) NOT NULL,
    KichThuoc INT NOT NULL CHECK (KichThuoc > 0 AND KichThuoc <= 5242880),
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

ALTER TABLE dbo.PhieuNghiemThu
    ADD CONSTRAINT FK_NghiemThu_ChuKy FOREIGN KEY (ChuKyId) REFERENCES dbo.TepDinhKem (Id);

CREATE TABLE dbo.ThanhToan (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.DonHang (Id),
    NghiemThuId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.PhieuNghiemThu (Id),
    SoTien DECIMAL(18, 2) NOT NULL CHECK (SoTien >= 0),
    PhuongThuc VARCHAR(10) DEFAULT 'COD' NOT NULL CHECK (PhuongThuc = 'COD'),
    TrangThai VARCHAR(10) DEFAULT 'Paid' NOT NULL CHECK (TrangThai = 'Paid'),
    NguoiThuTienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    NgayThanhToan DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.DoiSoat (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    ThanhToanId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.ThanhToan (Id),
    TienCong DECIMAL(18, 2) NOT NULL CHECK (TienCong >= 0),
    TyLeHoaHong DECIMAL(5, 2) NOT NULL CHECK (TyLeHoaHong BETWEEN 0 AND 100),
    TienHoaHong AS CAST (ROUND(TienCong * TyLeHoaHong / 100, 2) AS DECIMAL(18, 2)) PERSISTED,
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Confirmed')),
    NguoiXacNhanId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NgayXacNhan DATETIME2 NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.YeuCauVi (
    Id INT IDENTITY PRIMARY KEY,
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    Loai VARCHAR(15) NOT NULL CHECK (Loai IN ('Deposit', 'Withdrawal')),
    SoTien DECIMAL(18, 2) NOT NULL CHECK (SoTien > 0),
    GhiChu NVARCHAR(1000) NOT NULL,
    ChungTuId INT NULL FOREIGN KEY REFERENCES dbo.TepDinhKem (Id),
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'Rejected', 'Cancelled')),
    LyDo NVARCHAR(1000) NULL,
    NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NgayDuyet DATETIME2 NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.GiaoDichVi (
    Id INT IDENTITY PRIMARY KEY,
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    Loai VARCHAR(20) NOT NULL CHECK (Loai IN ('Opening', 'Deposit', 'Withdrawal', 'Commission', 'Reversal')),
    SoTien DECIMAL(18, 2) NOT NULL CHECK (SoTien <> 0),
    LoaiThamChieu VARCHAR(20) NOT NULL,
    ThamChieuId INT NOT NULL,
    NguoiThucHienId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    GhiChu NVARCHAR(500) NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    UNIQUE (LoaiThamChieu, ThamChieuId)
);

CREATE TABLE dbo.DanhGia (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KhachHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    DiemDanhGia INT NOT NULL CHECK (DiemDanhGia BETWEEN 1 AND 5),
    NhanXet NVARCHAR(1500) NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.LichSuDonHang (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    TrangThaiTruoc VARCHAR(30) NULL,
    TrangThaiSau VARCHAR(30) NOT NULL,
    NguoiThucHienId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NOT NULL,
    NgayPhatSinh DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.NhatKy (
    Id INT IDENTITY PRIMARY KEY,
    NguoiThucHienId INT NULL,
    ThaoTac VARCHAR(80) NOT NULL,
    DoiTuong VARCHAR(60) NOT NULL,
    DoiTuongId INT NULL,
    ChiTiet NVARCHAR(2000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.GhiChuDon (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    NguoiVietId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NoiDung NVARCHAR(2000) NOT NULL,
    PhamViHienThi VARCHAR(10) NOT NULL CHECK (PhamViHienThi IN ('Customer', 'Internal')),
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.ThongBao (
    Id INT IDENTITY PRIMARY KEY,
    NguoiDungId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    DonHangId INT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    TieuDe NVARCHAR(200) NOT NULL,
    NoiDungThongBao NVARCHAR(1000) NOT NULL,
    NgayDoc DATETIME2 NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.YeuCauHoTro (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KhachHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    Loai VARCHAR(15) NOT NULL CHECK (Loai IN ('Complaint', 'Warranty')),
    MoTa NVARCHAR(2000) NOT NULL,
    TrangThai VARCHAR(15) DEFAULT 'Open' NOT NULL CHECK (TrangThai IN ('Open', 'InProgress', 'Resolved', 'Rejected')),
    NguoiDuocGiaoId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    KetQuaXuLy NVARCHAR(2000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    NgayCapNhat DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.LichSuHoTro (
    Id INT IDENTITY PRIMARY KEY,
    YeuCauHoTroId INT NOT NULL FOREIGN KEY REFERENCES dbo.YeuCauHoTro (Id),
    NguoiThucHienId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    TrangThai VARCHAR(15) NOT NULL,
    GhiChu NVARCHAR(2000) NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

CREATE TABLE dbo.HoSoKTV (
    Id INT IDENTITY PRIMARY KEY,
    NguoiDungId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NhomTayNghe NVARCHAR(60) NOT NULL,
    KhuVucPhucVu NVARCHAR(120) NOT NULL,
    KinhNghiem NVARCHAR(2000) NOT NULL,
    TrangThai VARCHAR(10) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'Rejected')),
    LyDo NVARCHAR(1000) NULL,
    NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    PhienBan ROWVERSION
);

CREATE UNIQUE INDEX UX_HoSo_ChoDuyet
    ON dbo.HoSoKTV(NguoiDungId) WHERE TrangThai = 'Pending';

CREATE TABLE dbo.CauHinh (
    [KhoaCauHinh] VARCHAR(80) PRIMARY KEY,
    GiaTri NVARCHAR(1000) NOT NULL,
    NhanHienThi NVARCHAR(200) NOT NULL,
    PhienBan ROWVERSION
);

CREATE TABLE dbo.ChongLapYeuCau (
    NguoiThucHienId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    DuongDan VARCHAR(160) NOT NULL,
    KhoaYeuCau VARCHAR(50) NOT NULL,
    MaBamDuLieu CHAR(64) NOT NULL,
    KetQuaJSON NVARCHAR(MAX) NOT NULL CHECK (ISJSON(KetQuaJSON) = 1),
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
    CONSTRAINT PK_ChongLapYeuCau PRIMARY KEY (NguoiThucHienId, DuongDan, KhoaYeuCau)
);

INSERT INTO dbo.PhienBanCSDL (PhienBan)
VALUES (1);
GO


-- ===== 002_procedures_triggers.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

GO
CREATE OR ALTER PROCEDURE dbo.sp_DonHangCuaKhach
    @KhachHangId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.*, CASE WHEN t.Id IS NULL THEN 'Unpaid' ELSE 'Paid' END AS TrangThaiThanhToan
    FROM dbo.DonHang AS d
         LEFT OUTER JOIN dbo.ThanhToan AS t ON t.DonHangId = d.Id
    WHERE KhachHangId = @KhachHangId
    ORDER BY d.Id DESC;
END

GO
CREATE OR ALTER TRIGGER dbo.trg_Vi_GhiSo
    ON dbo.GiaoDichVi
    AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    WITH ChenhLechVi
    AS (SELECT KyThuatVienId, SUM(SoTien) AS SoTien
        FROM inserted
        GROUP BY KyThuatVienId)
    UPDATE k
    SET SoDu = k.SoDu + d.SoTien
    FROM dbo.KyThuatVien AS k
         INNER JOIN ChenhLechVi AS d ON d.KyThuatVienId = k.Id;
END
GO
CREATE OR ALTER TRIGGER dbo.trg_Vi_BatBien
    ON dbo.GiaoDichVi
    INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51009, 'LEDGER_IMMUTABLE', 1;
END
GO
CREATE OR ALTER TRIGGER dbo.trg_ThanhToan_BatBien
    ON dbo.ThanhToan
    INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51009, 'PAYMENT_IMMUTABLE', 1;
END
GO
CREATE OR ALTER TRIGGER dbo.trg_DonHang_GhiNhatKy
    ON dbo.DonHang
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.NhatKy (ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
    SELECT 'OrderStatus', 'DonHang', i.Id, CONCAT(d.TrangThai, ' -> ', i.TrangThai)
    FROM inserted AS i
         INNER JOIN deleted AS d ON d.Id = i.Id
    WHERE i.TrangThai <> d.TrangThai;
END
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
               WHERE i.KhachHangId <> d.KhachHangId OR d.TrangThai <> 'HoanThanh' OR p.Id IS NULL OR i.KyThuatVienId <> p.NguoiThuTienId)
        THROW 51009, 'REVIEW_NOT_ELIGIBLE', 1;
END
GO


-- ===== 003_cancellation_snapshot.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
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


-- ===== 004_auth_otp.sql =====
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


-- ===== 005_bank_payments.sql =====
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


-- ===== 006_service_catalog.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF COL_LENGTH('dbo.DichVu', 'PhoBien') IS NULL
    ALTER TABLE dbo.DichVu
        ADD PhoBien BIT CONSTRAINT DF_DichVu_PhoBien DEFAULT 0 NOT NULL;
GO


-- ===== 007_user_avatar.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF COL_LENGTH('dbo.NguoiDung', 'DuongDanAnhDaiDien') IS NULL
    ALTER TABLE dbo.NguoiDung
        ADD DuongDanAnhDaiDien NVARCHAR(500) NULL;

GO
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId') OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;

GO
ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar'));
GO


-- ===== 007_temporary_account_locks.sql =====
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


-- ===== 008_policy_proposals.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF OBJECT_ID('dbo.DeXuatChinhSach') IS NULL
    BEGIN
        CREATE TABLE dbo.DeXuatChinhSach (
            Id INT IDENTITY PRIMARY KEY,
            MaDeXuat VARCHAR(20) NOT NULL UNIQUE,
            TieuDe NVARCHAR(250) NOT NULL,
            BoPhan NVARCHAR(120) NOT NULL,
            NgayGui DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
            NhomDichVu NVARCHAR(120) NOT NULL,
            ChietKhauHienTai DECIMAL(5, 2) NULL,
            ChietKhauDeXuat DECIMAL(5, 2) NULL,
            MucThuongHienTai NVARCHAR(50) NULL,
            MucThuongDeXuat NVARCHAR(50) NULL,
            TacDong NVARCHAR(2000) NOT NULL,
            LyDo NVARCHAR(2000) NOT NULL,
            TrangThai VARCHAR(20) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'RevisionRequested', 'Rejected')),
            YKienGiamDoc NVARCHAR(2000) NULL,
            NgayHieuLuc VARCHAR(20) NULL,
            NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
            NgayDuyet DATETIME2 NULL,
            PhienBan ROWVERSION
        );
    END

GO
IF NOT EXISTS (SELECT 1
               FROM dbo.DeXuatChinhSach)
    BEGIN
        INSERT INTO dbo.DeXuatChinhSach (MaDeXuat, TieuDe, BoPhan, NhomDichVu, ChietKhauHienTai, ChietKhauDeXuat, MucThuongHienTai, MucThuongDeXuat, TacDong, LyDo)
        VALUES ('CS-10222', N'Điều chỉnh chiết khấu dịch vụ Điện nước từ 18% → 15%', N'Đề xuất: Lê Anh Tuấn', N'Điện nước', 18, 15, N'2.0% / đơn', N'3.5% / đơn', N'Dự báo tăng trưởng biên lợi nhuận ròng +2.4% cho nhóm dịch vụ kỹ thuật điện nước. Chính sách mới kỳ vọng tăng 12% lượng đơn hoàn thành do thu hút được đội ngũ kỹ thuật viên chất lượng cao.', N'Các hệ số chiết khấu hiện tại đang làm giảm động lực đăng ký mới của đội ngũ KTV, đề xuất giảm mức chiết khấu để tăng thưởng trực tiếp trên mỗi ca hoàn thành xuất sắc.'),
        ('CS-10223', N'Cập nhật bảng giá sản phẩm Vệ sinh thiết bị', N'Người gửi: Đỗ Văn An', N'Vệ sinh & bảo trì', 12, 10, N'1.5% / đơn', N'2.0% / đơn', N'Điều chỉnh phù hợp với biến động giá vật tư vệ sinh và duy trì mức cạnh tranh.', N'Bảng giá vật tư đã được rà soát theo nhà cung cấp mới.'),

        ('CS-10224', N'Chương trình ưu đãi Khách hàng mới tháng 11', N'Người gửi: Nguyễn Thị Hằng', N'Marketing', 0, 10, N'—', N'—', N'Dự kiến tăng lượng khách hàng mới và tỷ lệ đặt dịch vụ lần đầu.', N'Áp dụng mã giảm giá cho khách hàng lần đầu sử dụng HomeFix.');
    END

GO
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 8)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (8);
GO


-- ===== 008_technician_application.sql =====
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


-- ===== 009_customer_location.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF OBJECT_ID('dbo.ViTriKhachHang', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.ViTriKhachHang (
            DonHangId INT NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES dbo.DonHang (Id),
            ViDo DECIMAL(10, 7) NOT NULL CHECK (ViDo BETWEEN -90 AND 90),
            KinhDo DECIMAL(10, 7) NOT NULL CHECK (KinhDo BETWEEN -180 AND 180),
            DoChinhXacMet DECIMAL(12, 2) NOT NULL CHECK (DoChinhXacMet BETWEEN 0 AND 100000),
            NgayCapNhatViTri DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
        );
    END
GO


-- ===== 010_functions_views.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

GO
CREATE OR ALTER FUNCTION dbo.fn_HoaHong
(@TienCongTinh DECIMAL(18, 2), @TyLe DECIMAL(5, 2))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN CASE WHEN @TienCongTinh >= 0 AND @TyLe BETWEEN 0 AND 100 THEN CONVERT (DECIMAL(18, 2), ROUND(@TienCongTinh * @TyLe / 100, 2)) ELSE NULL END;
END

GO
CREATE OR ALTER FUNCTION dbo.fn_SoDuVi
(@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN
    (SELECT COALESCE (SUM(SoTien), CONVERT (DECIMAL(38, 2), 0)) AS SoDu
     FROM dbo.GiaoDichVi
     WHERE KyThuatVienId = @KyThuatVienId)

GO
CREATE OR ALTER FUNCTION dbo.fn_DiemDanhGia
(@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN
    (SELECT COUNT(*) AS SoDanhGia, AVG(CONVERT (DECIMAL(5, 2), DiemDanhGia)) AS DiemTrungBinh
     FROM dbo.DanhGia
     WHERE KyThuatVienId = @KyThuatVienId)

GO
CREATE OR ALTER FUNCTION dbo.fn_HanBaoHanh
(@NghiemThuId INT)
RETURNS TABLE
AS
RETURN
    (SELECT i.Id AS VatTuId, i.Ten, i.SoThangBaoHanh, DATEADD(month, i.SoThangBaoHanh, a.NgayDuyet) AS NgayHetHan
     FROM dbo.PhieuNghiemThu AS a
          INNER JOIN dbo.ChiTietDeXuatVatTu AS i ON i.BaoGiaId = a.DeXuatVatTuId
     WHERE a.Id = @NghiemThuId AND a.TrangThai = 'Approved' AND i.SoThangBaoHanh > 0)

GO
CREATE OR ALTER FUNCTION dbo.fn_ThongKeDon
(@TuNgay DATETIME2, @DenNgay DATETIME2)
RETURNS TABLE
AS
RETURN
    (SELECT NhomDichVu, COUNT(*) AS TongSoDon, SUM(CASE WHEN TrangThai = 'HoanThanh' THEN 1 ELSE 0 END) AS SoDonHoanThanh, SUM(CASE WHEN TrangThai = 'Huy' THEN 1 ELSE 0 END) AS SoDonHuy
     FROM dbo.DonHang
     WHERE NgayTao >= @TuNgay AND NgayTao < @DenNgay
     GROUP BY NhomDichVu)

GO
CREATE OR ALTER VIEW dbo.vw_DonHangTongHop
AS
SELECT d.*, u.HoTen AS TenKhachHang, k.HoTen AS TenKyThuatVien, CASE WHEN p.Id IS NULL THEN 'Unpaid' ELSE 'Paid' END AS TrangThaiThanhToan
FROM dbo.DonHang AS d
     INNER JOIN dbo.NguoiDung AS u ON u.Id = d.KhachHangId
     LEFT OUTER JOIN dbo.NguoiDung AS k ON k.Id = d.KyThuatVienDuocGiaoId
     LEFT OUTER JOIN dbo.ThanhToan AS p ON p.DonHangId = d.Id;

GO
CREATE OR ALTER VIEW dbo.vw_DoanhThuNgay
AS
SELECT CONVERT (DATE, DATEADD(hour, 7, p.NgayThanhToan)) AS NgayNghiepVu,
    COUNT_BIG(*) AS SoDonDaThanhToan,
    SUM(p.SoTien) AS TongGiaTriGiaoDich,
    SUM(dbo.fn_HoaHong(s.TienCong, s.TyLeHoaHong)) AS DoanhThuHoaHong
FROM dbo.ThanhToan AS p
     INNER JOIN dbo.DoiSoat AS s ON s.ThanhToanId = p.Id
GROUP BY CONVERT (DATE, DATEADD(hour, 7, p.NgayThanhToan));

GO
CREATE OR ALTER VIEW dbo.vw_ViKyThuatVien
AS
SELECT k.Id, u.HoTen, k.TrangThaiSanSang, k.SoDu AS SoDuLuuSan, v.SoDu, k.SoDu - v.SoDu AS ChenhLech
FROM dbo.KyThuatVien AS k
     INNER JOIN dbo.NguoiDung AS u ON u.Id = k.Id CROSS APPLY dbo.fn_SoDuVi(k.Id) AS v;

GO
CREATE OR ALTER VIEW dbo.vw_HieuSuatKyThuatVien
AS
SELECT k.Id, u.HoTen, k.NhomTayNghe, r.SoDanhGia, r.DiemTrungBinh, (SELECT COUNT(*)
                                                                    FROM dbo.DonHang AS d
                                                                    WHERE d.KyThuatVienDuocGiaoId = k.Id) AS TongSoDon, (SELECT COUNT(*)
                                                                                                                         FROM dbo.DonHang AS d
                                                                                                                         WHERE d.KyThuatVienDuocGiaoId = k.Id AND d.TrangThai = 'HoanThanh') AS SoDonHoanThanh
FROM dbo.KyThuatVien AS k
     INNER JOIN dbo.NguoiDung AS u ON u.Id = k.Id CROSS APPLY dbo.fn_DiemDanhGia(k.Id) AS r;

GO
CREATE OR ALTER VIEW dbo.vw_HoTroCanXuLy
AS
SELECT t.Id, t.DonHangId, t.KhachHangId, u.HoTen AS TenKhachHang, t.Loai, t.MoTa, t.TrangThai, t.NguoiDuocGiaoId, t.NgayTao, DATEADD(hour, 24, t.NgayTao) AS HanPhanHoi
FROM dbo.YeuCauHoTro AS t
     INNER JOIN dbo.NguoiDung AS u ON u.Id = t.KhachHangId
WHERE t.TrangThai IN ('Open', 'InProgress');

GO
CREATE OR ALTER VIEW dbo.vw_DichVuCongKhai
AS
SELECT Id, Ten, MaNhom, MoTa, PhiKiemTra, TienCong, PhoBien, PhiKiemTra + TienCong AS TongTienDuKien
FROM dbo.DichVu
WHERE DangHoatDong = 1;

GO
CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTongHop
    @TuNgay DATETIME2, @DenNgay DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @TuNgay IS NULL OR @DenNgay IS NULL OR @TuNgay >= @DenNgay
            THROW 51009, 'INVALID_DATE_RANGE', 1;
        SELECT *
        FROM dbo.fn_ThongKeDon(@TuNgay, @DenNgay)
        ORDER BY NhomDichVu;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO


-- ===== 011_indexes_integrity.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.GiaoDichVi') AND name = 'IX_Vi_KyThuatVien_Ngay')
    CREATE INDEX IX_Vi_KyThuatVien_Ngay
        ON dbo.GiaoDichVi(KyThuatVienId, NgayTao DESC)
        INCLUDE(SoTien, Loai, ThamChieuId);

IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.DoiSoat') AND name = 'IX_DoiSoat_TrangThai')
    CREATE INDEX IX_DoiSoat_TrangThai
        ON dbo.DoiSoat(TrangThai, KyThuatVienId)
        INCLUDE(TienHoaHong, ThanhToanId);

IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.YeuCauHoTro') AND name = 'IX_HoTro_TrangThai_Ngay')
    CREATE INDEX IX_HoTro_TrangThai_Ngay
        ON dbo.YeuCauHoTro(TrangThai, NgayTao)
        INCLUDE(DonHangId, KhachHangId, Loai);

IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.ThanhToan') AND name = 'IX_ThanhToan_Ngay')
    CREATE INDEX IX_ThanhToan_Ngay
        ON dbo.ThanhToan(NgayThanhToan)
        INCLUDE(SoTien, PhuongThuc, DonHangId);

IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.DanhGia') AND name = 'IX_DanhGia_KyThuatVien')
    CREATE INDEX IX_DanhGia_KyThuatVien
        ON dbo.DanhGia(KyThuatVienId)
        INCLUDE(DiemDanhGia);

GO
CREATE OR ALTER TRIGGER dbo.trg_DonHang_KhachHang
    ON dbo.DonHang
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.NguoiDung AS u ON u.Id = i.KhachHangId
               WHERE u.VaiTro <> 'KH')
        THROW 51009, 'CUSTOMER_ROLE_REQUIRED', 1;
END
GO
CREATE OR ALTER TRIGGER dbo.trg_ThanhToan_NghiemThu
    ON dbo.ThanhToan
    AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.PhieuNghiemThu AS a ON a.Id = i.NghiemThuId
               WHERE a.DonHangId <> i.DonHangId OR a.TrangThai <> 'Approved' OR a.TongTien <> i.SoTien OR (i.PhuongThuc = 'COD' AND i.NguoiThuTienId <> a.KyThuatVienId))
        THROW 51009, 'PAYMENT_ACCEPTANCE_MISMATCH', 1;
END
GO


-- ===== 012_transactions.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

GO
CREATE OR ALTER PROCEDURE dbo.sp_ChuyenTrangThaiDon
    @DonHangId INT, @NguoiThucHienId INT, @PhienBanDuKien BINARY(8), @TrangThaiTiepTheo VARCHAR(30), @LyDo NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION sp_ChuyenTrangThaiDon;
        DECLARE @TrangThaiTruocDo AS VARCHAR(30), @PhienBanHienTai AS BINARY(8);
        SELECT @TrangThaiTruocDo = TrangThai, @PhienBanHienTai = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId;
        IF @TrangThaiTruocDo IS NULL
            THROW 51004, 'ORDER_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NOT NULL AND @PhienBanDuKien <> @PhienBanHienTai
            THROW 51009, 'VERSION_CONFLICT', 1;
        IF NOT ((@TrangThaiTruocDo = 'ChoTiepNhan' AND @TrangThaiTiepTheo IN ('ChoDuyetSoBo', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoDuyetSoBo' AND @TrangThaiTiepTheo IN ('ChoPhanCong', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoPhanCong' AND @TrangThaiTiepTheo IN ('ChoNhan', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoNhan' AND @TrangThaiTiepTheo IN ('DaTiepNhan', 'ChoPhanCong', 'Huy'))
            OR (@TrangThaiTruocDo = 'DaTiepNhan' AND @TrangThaiTiepTheo IN ('DangDiChuyen', 'Huy'))
            OR (@TrangThaiTruocDo = 'DangDiChuyen' AND @TrangThaiTiepTheo IN ('DaDenNoi', 'Huy'))
            OR (@TrangThaiTruocDo = 'DaDenNoi' AND @TrangThaiTiepTheo = 'DangXuLy')
            OR (@TrangThaiTruocDo = 'DangXuLy' AND @TrangThaiTiepTheo = 'ChoNghiemThu')
            OR (@TrangThaiTruocDo = 'ChoNghiemThu' AND @TrangThaiTiepTheo IN ('HoanThanh', 'DangXuLy')))
            THROW 51009, 'INVALID_TRANSITION', 1;
        UPDATE dbo.DonHang
        SET TrangThai    = @TrangThaiTiepTheo,
            NgayCapNhat  = SYSUTCDATETIME(),
            NgayKhoiHanh = CASE WHEN @TrangThaiTiepTheo = 'DangDiChuyen' THEN SYSUTCDATETIME() ELSE NgayKhoiHanh END
        WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThaiTruocDo, @TrangThaiTiepTheo, @NguoiThucHienId, @LyDo);
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION sp_ChuyenTrangThaiDon;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_DoiSoatCOD
    @DoiSoatId INT, @NguoiThucHienId INT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION sp_DoiSoatCOD;
        DECLARE @KTV AS INT,
            @HoaHong AS DECIMAL(18, 2),
            @TinhTrang AS VARCHAR(10),
            @PhienBan AS BINARY(8),
            @PhuongThuc AS VARCHAR(10),
            @TongTien AS DECIMAL(18, 2),
            @TienThucNhan AS DECIMAL(18, 2);
        SELECT @KTV = s.KyThuatVienId, @HoaHong = s.TienHoaHong, @TinhTrang = s.TrangThai, @PhienBan = s.PhienBan, @PhuongThuc = p.PhuongThuc, @TongTien = p.SoTien
        FROM dbo.DoiSoat AS s WITH (UPDLOCK, HOLDLOCK)
             INNER JOIN dbo.ThanhToan AS p ON p.Id = s.ThanhToanId
        WHERE s.Id = @DoiSoatId;
        IF @KTV IS NULL
            THROW 51004, 'SETTLEMENT_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @TinhTrang <> 'Pending' OR @PhienBan <> @PhienBanDuKien
            THROW 51009, 'SETTLEMENT_ALREADY_CONFIRMED_OR_STALE', 1;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'KT' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @PhuongThuc = 'COD'
            BEGIN
                IF (SELECT SoDu
                    FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK)
                    WHERE Id = @KTV) < @HoaHong
                    THROW 51009, 'INSUFFICIENT_BALANCE', 1;
                IF @HoaHong > 0
                    INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                    VALUES (@KTV, 'Commission', -@HoaHong, 'Settlement', @DoiSoatId, @NguoiThucHienId, N'Đối soát hoa hồng tiền mặt');
            END
        ELSE
            BEGIN
                SET @TienThucNhan = @TongTien - @HoaHong;
                IF @TienThucNhan < 0
                    THROW 51009, 'INVALID_SETTLEMENT_AMOUNT', 1;
                IF @TienThucNhan > 0
                    INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                    VALUES (@KTV, 'SettlementCredit', @TienThucNhan, 'Settlement', @DoiSoatId, @NguoiThucHienId, N'Tiền chuyển khoản HomeFix đã nhận: cộng tiền thuộc KTV sau hoa hồng (gồm phí kiểm tra và vật tư)');
            END
        UPDATE dbo.DoiSoat
        SET TrangThai      = 'Confirmed',
            NguoiXacNhanId = @NguoiThucHienId,
            NgayXacNhan    = SYSUTCDATETIME()
        WHERE Id = @DoiSoatId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, 'ConfirmSettlement', 'DoiSoat', @DoiSoatId);
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION sp_DoiSoatCOD;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_TaoDonHang
    @KhachHangId INT, @DichVuId INT, @DiaChi NVARCHAR(500), @MoTa NVARCHAR(2000), @NgayHen DATETIME2=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION TaoDonHang;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @KhachHangId AND VaiTro = 'KH' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF LEN(LTRIM(RTRIM(@DiaChi))) < 10 OR LEN(LTRIM(RTRIM(@MoTa))) < 5
            THROW 51009, 'INVALID_ORDER_INPUT', 1;
        IF @NgayHen IS NOT NULL AND (@NgayHen < DATEADD(minute, 30, SYSUTCDATETIME()) OR @NgayHen > DATEADD(day, 30, SYSUTCDATETIME()) OR DATEPART(hour, DATEADD(hour, 7, @NgayHen)) NOT BETWEEN 8 AND 17 OR DATEPART(minute, @NgayHen) % 30 <> 0 OR DATEPART(second, @NgayHen) <> 0)
            THROW 51009, 'INVALID_SCHEDULE', 1;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK)
                       WHERE Id = @DichVuId AND DangHoatDong = 1)
            THROW 51004, 'SERVICE_UNAVAILABLE', 1;
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, NhomDichVu, TenLienHe, SoDienThoaiLienHe, DiaChi, MoTa, NgayHen, PhiHuyTaiThoiDiemDat)
        SELECT u.Id, s.Id, s.Ten, s.MaNhom, u.HoTen, u.SoDienThoai, @DiaChi, @MoTa, @NgayHen, COALESCE ((SELECT TRY_CONVERT (DECIMAL(18, 2), GiaTri)
                                                                                                         FROM dbo.CauHinh
                                                                                                         WHERE [KhoaCauHinh] = 'cancellationFee'), 50000)
        FROM dbo.NguoiDung AS u CROSS JOIN dbo.DichVu AS s
        WHERE u.Id = @KhachHangId AND s.Id = @DichVuId;
        DECLARE @DonHangId AS INT = SCOPE_IDENTITY();
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoTiepNhan', @KhachHangId, N'Khách hàng đặt dịch vụ');
        SELECT *
        FROM dbo.DonHang
        WHERE Id = @DonHangId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION TaoDonHang;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_DuyetYeuCauVi
    @YeuCauId INT, @NguoiThucHienId INT, @QuyetDinh VARCHAR(10), @PhienBanDuKien BINARY(8), @LyDo NVARCHAR(1000)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION DuyetVi;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'KT' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @QuyetDinh NOT IN ('Approved', 'Rejected') OR @QuyetDinh IS NULL
            THROW 51009, 'INVALID_DECISION', 1;
        IF @QuyetDinh = 'Rejected' AND NULLIF (LTRIM(RTRIM(@LyDo)), '') IS NULL
            THROW 51009, 'REASON_REQUIRED', 1;
        DECLARE @KyThuatVienId AS INT, @SoTien AS DECIMAL(18, 2), @Loai AS VARCHAR(15), @TrangThai AS VARCHAR(10), @PhienBan AS BINARY(8);
        SELECT @KyThuatVienId = KyThuatVienId, @SoTien = SoTien, @Loai = Loai, @TrangThai = TrangThai, @PhienBan = PhienBan
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @YeuCauId;
        IF @KyThuatVienId IS NULL
            THROW 51004, 'REQUEST_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBan <> @PhienBanDuKien OR @TrangThai <> 'Pending'
            THROW 51009, 'VERSION_CONFLICT', 1;
        IF @QuyetDinh = 'Approved'
            BEGIN
                IF @Loai = 'Withdrawal'
                    BEGIN
                        IF (SELECT SoDu
                            FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK)
                            WHERE Id = @KyThuatVienId) < @SoTien
                            THROW 51009, 'INSUFFICIENT_BALANCE', 1;
                        IF EXISTS (SELECT 1
                                   FROM dbo.LenhDieuPhoi WITH (UPDLOCK, HOLDLOCK)
                                   WHERE KyThuatVienId = @KyThuatVienId AND DangHoatDong = 1)
                            THROW 51009, 'ACTIVE_ASSIGNMENT', 1;
                    END
                INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                SELECT KyThuatVienId, Loai, CASE WHEN [Loai] = 'Withdrawal' THEN -SoTien ELSE SoTien END, 'WalletRequest', Id, @NguoiThucHienId, GhiChu
                FROM dbo.YeuCauVi
                WHERE Id = @YeuCauId;
            END
        UPDATE dbo.YeuCauVi
        SET TrangThai    = @QuyetDinh,
            LyDo         = @LyDo,
            NguoiDuyetId = @NguoiThucHienId,
            NgayDuyet    = SYSUTCDATETIME()
        WHERE Id = @YeuCauId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, 'DecideWallet', 'YeuCauVi', @YeuCauId, @QuyetDinh);
        SELECT *
        FROM dbo.YeuCauVi
        WHERE Id = @YeuCauId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION DuyetVi;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_XuLyHoTro
    @YeuCauHoTroId INT, @NguoiThucHienId INT, @TrangThai VARCHAR(15), @KetQuaXuLy NVARCHAR(2000), @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION XuLyHoTro;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'CSKH' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @TrangThai IS NULL OR @TrangThai NOT IN ('InProgress', 'Resolved', 'Rejected') OR LEN(LTRIM(RTRIM(@KetQuaXuLy))) < 5
            THROW 51009, 'INVALID_SUPPORT_INPUT', 1;
        DECLARE @PhienBan AS BINARY(8), @TrangThaiTruocDo AS VARCHAR(15);
        SELECT @PhienBan = PhienBan, @TrangThaiTruocDo = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL
            THROW 51004, 'TICKET_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThaiTruocDo NOT IN ('Open', 'InProgress')
            THROW 51009, 'VERSION_CONFLICT', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai       = @TrangThai,
            KetQuaXuLy      = @KetQuaXuLy,
            NguoiDuocGiaoId = @NguoiThucHienId,
            NgayCapNhat     = SYSUTCDATETIME()
        WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.LichSuHoTro (YeuCauHoTroId, NguoiThucHienId, TrangThai, GhiChu)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @TrangThai, @KetQuaXuLy);
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, 'UpdateTicket', 'YeuCauHoTro', @YeuCauHoTroId, @TrangThai);
        SELECT *
        FROM dbo.YeuCauHoTro
        WHERE Id = @YeuCauHoTroId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION XuLyHoTro;
        THROW;
    END CATCH
END
GO


-- ===== 013_security.sql =====
-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF DATABASE_PRINCIPAL_ID(N'HomeFix_KH') IS NULL
    CREATE ROLE HomeFix_KH;

IF DATABASE_PRINCIPAL_ID(N'hf_KH') IS NULL
    CREATE USER hf_KH WITHOUT LOGIN;

ALTER ROLE HomeFix_KH ADD MEMBER hf_KH;

GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;

GRANT EXECUTE ON OBJECT::dbo.sp_TaoDonHang TO HomeFix_KH;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_KH;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KH;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_KTV') IS NULL
    CREATE ROLE HomeFix_KTV;

IF DATABASE_PRINCIPAL_ID(N'hf_KTV') IS NULL
    CREATE USER hf_KTV WITHOUT LOGIN;

ALTER ROLE HomeFix_KTV ADD MEMBER hf_KTV;

GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KTV;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_KTV;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KTV;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_DPV') IS NULL
    CREATE ROLE HomeFix_DPV;

IF DATABASE_PRINCIPAL_ID(N'hf_DPV') IS NULL
    CREATE USER hf_DPV WITHOUT LOGIN;

ALTER ROLE HomeFix_DPV ADD MEMBER hf_DPV;

GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;

GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_DPV;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_DPV;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_DPV;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_CSKH') IS NULL
    CREATE ROLE HomeFix_CSKH;

IF DATABASE_PRINCIPAL_ID(N'hf_CSKH') IS NULL
    CREATE USER hf_CSKH WITHOUT LOGIN;

ALTER ROLE HomeFix_CSKH ADD MEMBER hf_CSKH;

GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_CSKH;

GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_CSKH;

GRANT EXECUTE ON OBJECT::dbo.sp_XuLyHoTro TO HomeFix_CSKH;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_CSKH;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_CSKH;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_KT') IS NULL
    CREATE ROLE HomeFix_KT;

IF DATABASE_PRINCIPAL_ID(N'hf_KT') IS NULL
    CREATE USER hf_KT WITHOUT LOGIN;

ALTER ROLE HomeFix_KT ADD MEMBER hf_KT;

GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;

GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_KT;

GRANT EXECUTE ON OBJECT::dbo.sp_DuyetYeuCauVi TO HomeFix_KT;

GRANT EXECUTE ON OBJECT::dbo.sp_DoiSoatCOD TO HomeFix_KT;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_KT;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KT;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_GD') IS NULL
    CREATE ROLE HomeFix_GD;

IF DATABASE_PRINCIPAL_ID(N'hf_GD') IS NULL
    CREATE USER hf_GD WITHOUT LOGIN;

ALTER ROLE HomeFix_GD ADD MEMBER hf_GD;

GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_GD;

GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_GD;

GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_GD;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_GD;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_GD;

IF DATABASE_PRINCIPAL_ID(N'HomeFix_ADMIN') IS NULL
    CREATE ROLE HomeFix_ADMIN;

IF DATABASE_PRINCIPAL_ID(N'hf_ADMIN') IS NULL
    CREATE USER hf_ADMIN WITHOUT LOGIN;

ALTER ROLE HomeFix_ADMIN ADD MEMBER hf_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_ADMIN;

GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_ADMIN;

DENY SELECT ON OBJECT::dbo.NguoiDung (MatKhauBam) TO HomeFix_ADMIN;

DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_ADMIN;

GRANT SELECT ON OBJECT::dbo.NhatKy TO HomeFix_GD;

REVOKE SELECT ON OBJECT::dbo.NhatKy TO HomeFix_GD;

GRANT SELECT ON OBJECT::dbo.NhatKy TO HomeFix_ADMIN;

GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DichVu TO HomeFix_ADMIN;

GO
GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_KT;

GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_CSKH;

GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_DPV;
GO

SET IDENTITY_INSERT dbo.[NguoiDung] ON;
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'1', N'Khách hàng An', N'0900000001', N'kh@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.746Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'2', N'Kỹ thuật viên Minh', N'0900000002', N'ktv@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KTV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.759Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'3', N'Điều phối Linh', N'0900000003', N'dpv@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'DPV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.797Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'4', N'Chăm sóc khách hàng', N'0900000004', N'cskh@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'CSKH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.805Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'5', N'Kế toán Hạnh', N'0900000005', N'kt@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KT', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.814Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'6', N'Quản trị HomeFix', N'0900000006', N'admin@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'ADMIN', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.824Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'7', N'Giám đốc HomeFix', N'0900000007', N'gd@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'GD', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.831Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'8', N'Khách hàng Bình', N'0900000008', N'kh2@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.836Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'9', N'Kỹ thuật viên Nam', N'0900000009', N'ktv2@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KTV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.845Z', NULL, NULL);
SET IDENTITY_INSERT dbo.[NguoiDung] OFF;
GO
INSERT INTO dbo.[KyThuatVien] ([Id], [NhomTayNghe], [KhuVucPhucVu], [TrangThaiSanSang], [SoDu], [ViDo], [KinhDo], [DoChinhXacMet], [NgayCapNhatViTri])
VALUES (2, N'DienLanh', N'TP.HCM', N'SanSang', 0, NULL, NULL, NULL, NULL);
INSERT INTO dbo.[KyThuatVien] ([Id], [NhomTayNghe], [KhuVucPhucVu], [TrangThaiSanSang], [SoDu], [ViDo], [KinhDo], [DoChinhXacMet], [NgayCapNhatViTri])
VALUES (9, N'DienLanh', N'TP.HCM', N'SanSang', 0, NULL, NULL, NULL, NULL);
GO
SET IDENTITY_INSERT dbo.[DichVu] ON;
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'1', N'Sửa máy lạnh', N'DienLanh', N'Kiểm tra và sửa máy lạnh không lạnh, chảy nước.', 50000, 300000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'2', N'Vệ sinh máy lạnh', N'DienLanh', N'Bảo dưỡng, vệ sinh dàn lạnh và dàn nóng.', 30000, 180000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'3', N'Sửa tủ lạnh', N'DienLanh', N'Khắc phục lỗi tủ lạnh không đông đá, hở ron.', 50000, 300000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'4', N'Sửa máy giặt', N'DienGiaDung', N'Sửa máy giặt mất nguồn, báo lỗi, không vắt.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'5', N'Sửa điện nước', N'DienNuoc', N'Sửa rò rỉ, đường ống và thiết bị điện gia đình.', 50000, 200000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'6', N'Vệ sinh thiết bị', N'VeSinh', N'Làm sạch và bảo trì định kỳ thiết bị gia đình.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'7', N'Sửa điện tại nhà', N'DienNuoc', N'Khắc phục sự cố chập điện, mất điện, nhảy aptomat.', 50000, 200000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'8', N'Sửa điện 3 pha', N'DienNuoc', N'Khắc phục sự cố tủ điện 3 pha, cân pha công nghiệp.', 100000, 500000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'9', N'Lắp quạt trần', N'DienNuoc', N'Thi công và lắp ráp các loại quạt trần dân dụng.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'10', N'Sửa quạt trần', N'DienNuoc', N'Sửa chữa quạt trần không quay, kêu to, hỏng tụ.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'11', N'Thi công đèn trong nhà', N'DienNuoc', N'Lắp đặt, đi dây và thiết kế hệ thống chiếu sáng.', 50000, 300000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'12', N'Sửa ống nước tại nhà', N'DienNuoc', N'Khắc phục các sự cố bục vỡ, rò rỉ đường ống nước.', 50000, 150000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'13', N'Sửa máy bơm nước', N'DienNuoc', N'Kiểm tra và sửa chữa máy bơm nước không lên nước, kêu to.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'14', N'Lắp phao nước tự động', N'DienNuoc', N'Lắp đặt phao điện, phao cơ ngắt nước tự động.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'15', N'Thông nghẹt bồn rửa chén', N'DienNuoc', N'Xử lý triệt để bồn rửa chén bị tắc nghẽn nước.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'16', N'Sửa vòi rửa bát', N'DienNuoc', N'Khắc phục vòi rửa bát bị rò rỉ nước, gãy vòi.', 30000, 100000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'17', N'Thay vòi hoa sen', N'DienNuoc', N'Lắp mới, thay thế bộ vòi hoa sen nhà tắm.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'18', N'Sửa bồn cầu', N'DienNuoc', N'Sửa bồn cầu rỉ nước, hỏng phao, nút nhấn không được.', 50000, 200000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'19', N'Dò tìm rò rỉ nước ngầm', N'DienNuoc', N'Sử dụng máy siêu âm tìm điểm vỡ ống nước ngầm âm tường/nền.', 100000, 800000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'20', N'Bơm gas máy lạnh', N'DienLanh', N'Kiểm tra và châm thêm gas cho máy lạnh.', 50000, 350000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'21', N'Vệ sinh máy lạnh âm trần', N'DienLanh', N'Bảo dưỡng máy lạnh cassette, máy lạnh âm trần ống gió.', 100000, 450000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'22', N'Sửa tủ mát, tủ đông', N'DienLanh', N'Bơm gas, thay lốc tủ đông công nghiệp/nhà hàng.', 100000, 500000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'23', N'Vệ sinh máy giặt lồng ngang', N'DienGiaDung', N'Tháo lồng và vệ sinh máy giặt cửa trước.', 50000, 400000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'24', N'Vệ sinh máy giặt lồng đứng', N'DienGiaDung', N'Tháo lồng và vệ sinh máy giặt cửa trên.', 50000, 250000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'25', N'Sửa lò vi sóng', N'DienGiaDung', N'Sửa lò vi sóng mất nguồn, không nóng.', 50000, 200000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'26', N'Sửa máy nước nóng năng lượng mặt trời', N'DienGiaDung', N'Khắc phục rò rỉ, thay ống thủy tinh năng lượng mặt trời.', 100000, 400000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'27', N'Sửa máy nước nóng', N'DienGiaDung', N'Sửa máy nước nóng trực tiếp/gián tiếp không nóng.', 50000, 250000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'28', N'Vệ sinh bồn nước inox', N'VeSinh', N'Súc rửa cặn bẩn bồn nước inox trên cao.', 50000, 350000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'29', N'Vệ sinh bồn nước ngầm', N'VeSinh', N'Hút cặn và khử khuẩn bể nước ngầm bằng máy.', 100000, 600000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'30', N'Vệ sinh sofa tại nhà', N'VeSinh', N'Giặt sofa nỉ, sofa da bằng công nghệ hơi nước.', 50000, 450000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'31', N'Rút hầm cầu', N'VeSinh', N'Hút hầm cầu, nạo vét hố ga, xử lý mùi hôi.', 150000, 800000, 15, 0, 1);
SET IDENTITY_INSERT dbo.[DichVu] OFF;
GO
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'assignmentMinutes', N'10', N'Phút phản hồi lệnh');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'cancellationFee', N'50000', N'Phí hủy khi đang di chuyển');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'minimumWallet', N'200000', N'Số dư tối thiểu nhận việc');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'signatureRequired', N'false', N'Yêu cầu chữ ký nghiệm thu');
GO
SET IDENTITY_INSERT dbo.[GiaoDichVi] ON;
INSERT INTO dbo.[GiaoDichVi] ([Id], [KyThuatVienId], [Loai], [SoTien], [LoaiThamChieu], [ThamChieuId], [NguoiThucHienId], [GhiChu], [NgayTao])
VALUES (N'1', 2, N'Opening', 1000000, N'Opening', 2, NULL, N'Số dư mở đầu bộ dữ liệu demo', '2026-10-05T10:46:48.771Z');
INSERT INTO dbo.[GiaoDichVi] ([Id], [KyThuatVienId], [Loai], [SoTien], [LoaiThamChieu], [ThamChieuId], [NguoiThucHienId], [GhiChu], [NgayTao])
VALUES (N'2', 9, N'Opening', 1000000, N'Opening', 9, NULL, N'Số dư mở đầu bộ dữ liệu demo', '2026-10-05T10:46:48.855Z');
SET IDENTITY_INSERT dbo.[GiaoDichVi] OFF;
GO
IF NOT EXISTS(SELECT 1 FROM dbo.PhienBanCSDL WHERE PhienBan=6) INSERT dbo.PhienBanCSDL(PhienBan) VALUES(6);
GO
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
