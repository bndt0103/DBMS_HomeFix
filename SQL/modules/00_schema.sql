-- HomeFix / 00_schema: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
-- Phiên bản cơ sở dữ liệu.
CREATE TABLE dbo.PhienBanCSDL (
    PhienBan INT NOT NULL PRIMARY KEY,
    NgayApDung DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Tài khoản người dùng.
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

-- Ngăn trùng địa chỉ email.


-- Ngăn trùng căn cước công dân.


-- Thông tin và số dư kỹ thuật viên.
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

-- Danh mục dịch vụ.
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

-- Đơn đặt dịch vụ.
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

-- Tăng tốc tra cứu đơn theo khách hàng.


-- Tăng tốc lọc đơn theo trạng thái.


-- Báo giá sơ bộ.
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

-- Lệnh phân công kỹ thuật viên.
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

-- Mỗi đơn có tối đa một lệnh phân công đang hoạt động.


-- Mỗi kỹ thuật viên có tối đa một lệnh đang hoạt động.


-- Đề xuất vật tư.
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

-- Mỗi đơn có tối đa một đề xuất vật tư đang áp dụng.


-- Chi tiết vật tư và bảo hành.
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

-- Phiếu nghiệm thu.
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

-- Mỗi đơn có tối đa một nghiệm thu chờ duyệt.


-- Mỗi đơn có tối đa một nghiệm thu đã duyệt.


-- Tệp đính kèm.
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

-- Khoản thanh toán.
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

-- Đối soát thanh toán.
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

-- Yêu cầu nạp và rút ví.
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

-- Sổ giao dịch ví.
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

-- Đánh giá dịch vụ.
CREATE TABLE dbo.DanhGia (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL UNIQUE FOREIGN KEY REFERENCES dbo.DonHang (Id),
    KhachHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    KyThuatVienId INT NOT NULL FOREIGN KEY REFERENCES dbo.KyThuatVien (Id),
    DiemDanhGia INT NOT NULL CHECK (DiemDanhGia BETWEEN 1 AND 5),
    NhanXet NVARCHAR(1500) NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Lịch sử trạng thái đơn hàng.
CREATE TABLE dbo.LichSuDonHang (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    TrangThaiTruoc VARCHAR(30) NULL,
    TrangThaiSau VARCHAR(30) NOT NULL,
    NguoiThucHienId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    LyDo NVARCHAR(1000) NOT NULL,
    NgayPhatSinh DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Nhật ký hệ thống.
CREATE TABLE dbo.NhatKy (
    Id INT IDENTITY PRIMARY KEY,
    NguoiThucHienId INT NULL,
    ThaoTac VARCHAR(80) NOT NULL,
    DoiTuong VARCHAR(60) NOT NULL,
    DoiTuongId INT NULL,
    ChiTiet NVARCHAR(2000) NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Ghi chú đơn hàng.
CREATE TABLE dbo.GhiChuDon (
    Id INT IDENTITY PRIMARY KEY,
    DonHangId INT NOT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    NguoiVietId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    NoiDung NVARCHAR(2000) NOT NULL,
    PhamViHienThi VARCHAR(10) NOT NULL CHECK (PhamViHienThi IN ('Customer', 'Internal')),
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Thông báo người dùng.
CREATE TABLE dbo.ThongBao (
    Id INT IDENTITY PRIMARY KEY,
    NguoiDungId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    DonHangId INT NULL FOREIGN KEY REFERENCES dbo.DonHang (Id),
    TieuDe NVARCHAR(200) NOT NULL,
    NoiDungThongBao NVARCHAR(1000) NOT NULL,
    NgayDoc DATETIME2 NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Yêu cầu hỗ trợ.
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

-- Lịch sử xử lý hỗ trợ.
CREATE TABLE dbo.LichSuHoTro (
    Id INT IDENTITY PRIMARY KEY,
    YeuCauHoTroId INT NOT NULL FOREIGN KEY REFERENCES dbo.YeuCauHoTro (Id),
    NguoiThucHienId INT NOT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
    TrangThai VARCHAR(15) NOT NULL,
    GhiChu NVARCHAR(2000) NOT NULL,
    NgayTao DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL
);

-- Hồ sơ đăng ký kỹ thuật viên.
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

-- Mỗi người dùng có tối đa một hồ sơ chờ duyệt.


-- Cấu hình nghiệp vụ.
CREATE TABLE dbo.CauHinh (
    [KhoaCauHinh] VARCHAR(80) PRIMARY KEY,
    GiaTri NVARCHAR(1000) NOT NULL,
    NhanHienThi NVARCHAR(200) NOT NULL,
    PhienBan ROWVERSION
);

-- Kết quả xử lý yêu cầu chống lặp.
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

-- Nguồn: SRC/database/CSDL_HomeFix_03_PhiHuyDon.sql
-- Phí hủy tại thời điểm đặt đơn.
IF COL_LENGTH('dbo.DonHang', 'PhiHuyTaiThoiDiemDat') IS NULL
    ALTER TABLE dbo.DonHang
        ADD PhiHuyTaiThoiDiemDat DECIMAL(18, 2) CONSTRAINT DF_DonHang_PhiHuyTaiThoiDiemDat DEFAULT 50000 WITH VALUES NOT NULL CONSTRAINT CK_DonHang_PhiHuyTaiThoiDiemDat CHECK (PhiHuyTaiThoiDiemDat >= 0);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_03_PhiHuyDon.sql
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 2)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (2);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_04_XacThucOTP.sql
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

    END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
-- Thanh toán và xác nhận chuyển khoản.
SET XACT_ABORT ON;

IF COL_LENGTH('dbo.DonHang', 'PhuongThucThanhToan') IS NULL
    ALTER TABLE dbo.DonHang
        ADD PhuongThucThanhToan VARCHAR(10) CONSTRAINT DF_DonHang_PhuongThucThanhToan DEFAULT 'COD' NOT NULL CONSTRAINT CK_DonHang_PhuongThucThanhToan CHECK (PhuongThucThanhToan IN ('COD', 'BANK'));

IF OBJECT_ID('dbo.TaiKhoanNhanTien') IS NULL
    -- Tài khoản ngân hàng nhận tiền.
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

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
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

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
IF OBJECT_ID('dbo.YeuCauThanhToan') IS NULL
    BEGIN
        -- Yêu cầu xác nhận chuyển khoản.
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
        -- Mỗi đơn có tối đa một yêu cầu chuyển khoản đang hoạt động.

        -- Ngăn trùng nội dung chuyển khoản.

        -- Ngăn dùng lại chứng từ chuyển khoản.

    END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId') OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.TepDinhKem
    -- Giữ đủ mục đích hiện hành khi migration chạy lại trên dữ liệu đã nâng cấp.
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'TechnicianSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar'));

SET @LenhSQL = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.GiaoDichVi DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.GiaoDichVi') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.GiaoDichVi'), 'Loai', 'ColumnId') OR name = 'CK_Vi_Loai');

EXECUTE sp_executesql @LenhSQL;

ALTER TABLE dbo.GiaoDichVi
    ADD CONSTRAINT CK_Vi_Loai CHECK (Loai IN ('Opening', 'Deposit', 'Withdrawal', 'Commission', 'Reversal', 'SettlementCredit'));
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 5)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (5);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_06_DanhMucDichVu.sql
-- Phân loại dịch vụ phổ biến.
IF COL_LENGTH('dbo.DichVu', 'PhoBien') IS NULL
    ALTER TABLE dbo.DichVu
        ADD PhoBien BIT CONSTRAINT DF_DichVu_PhoBien DEFAULT 0 NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_07_AnhDaiDien.sql
-- Ảnh đại diện và mục đích tệp đính kèm.
IF COL_LENGTH('dbo.NguoiDung', 'DuongDanAnhDaiDien') IS NULL
    ALTER TABLE dbo.NguoiDung
        ADD DuongDanAnhDaiDien NVARCHAR(500) NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_07_AnhDaiDien.sql
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem') AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId') OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_07_AnhDaiDien.sql
ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'TechnicianSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar'));
GO

-- Nguồn: SRC/database/CSDL_HomeFix_08_KhoaTaiKhoan.sql
-- Thời hạn khóa tài khoản.
IF COL_LENGTH('dbo.NguoiDung', 'KhoaDenNgay') IS NULL
    ALTER TABLE dbo.NguoiDung
        ADD KhoaDenNgay DATETIME2 NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_08_KhoaTaiKhoan.sql
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 7)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (7);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_09_DeXuatChinhSach.sql
-- Bảng lưu đề xuất chính sách do các bộ phận gửi lên.
IF OBJECT_ID('dbo.DeXuatChinhSach') IS NULL
    BEGIN
        -- Đề xuất chính sách.
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

-- Nguồn: SRC/database/CSDL_HomeFix_09_DeXuatChinhSach.sql
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 8)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (8);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_10_HoSoKyThuatVien.sql
-- Thông tin hồ sơ kỹ thuật viên.
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

-- Nguồn: SRC/database/CSDL_HomeFix_11_ViTriKhachHang.sql
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

-- Nguồn: SRC/database/CSDL_HomeFix_16_ChuKyKyThuatVien.sql
-- Tach chu ky cua KTV khoi chu ky khach hang tren phieu nghiem thu.
IF COL_LENGTH('dbo.PhieuNghiemThu', 'ChuKyKTVId') IS NULL
    ALTER TABLE dbo.PhieuNghiemThu ADD ChuKyKTVId INT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_16_ChuKyKyThuatVien.sql
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_NghiemThu_ChuKyKTV'
)
    ALTER TABLE dbo.PhieuNghiemThu
        ADD CONSTRAINT FK_NghiemThu_ChuKyKTV FOREIGN KEY (ChuKyKTVId) REFERENCES dbo.TepDinhKem (Id);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_16_ChuKyKyThuatVien.sql
DECLARE @LenhSQL AS NVARCHAR(MAX) = '';

SELECT @LenhSQL = @LenhSQL + 'ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.TepDinhKem')
  AND (parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.TepDinhKem'), 'MucDich', 'ColumnId')
       OR name = 'CK_TepDinhKem_MucDich');

EXECUTE sp_executesql @LenhSQL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_16_ChuKyKyThuatVien.sql
ALTER TABLE dbo.TepDinhKem
    ADD CONSTRAINT CK_TepDinhKem_MucDich CHECK (
        MucDich IN ('OrderFault', 'MaterialEvidence', 'AcceptancePhoto', 'CustomerSignature', 'TechnicianSignature', 'WalletProof', 'TechnicianDocument', 'PaymentProof', 'Avatar')
    );
GO
