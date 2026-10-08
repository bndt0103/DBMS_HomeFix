-- Bảng dữ liệu và ràng buộc toàn vẹn.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
CREATE UNIQUE INDEX UX_NguoiDung_Email
    ON dbo.NguoiDung (Email) WHERE Email IS NOT NULL;

-- Ngăn trùng căn cước công dân.
CREATE UNIQUE INDEX UX_NguoiDung_CCCD
    ON dbo.NguoiDung (CCCD) WHERE CCCD IS NOT NULL;

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
CREATE INDEX IX_DonHang_KhachHang
    ON dbo.DonHang (KhachHangId, NgayTao DESC);

-- Tăng tốc lọc đơn theo trạng thái.
CREATE INDEX IX_DonHang_TrangThai
    ON dbo.DonHang (TrangThai, NgayTao);

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
CREATE UNIQUE INDEX UX_PhanCong_DonHang
    ON dbo.LenhDieuPhoi (DonHangId) WHERE DangHoatDong = 1;

-- Mỗi kỹ thuật viên có tối đa một lệnh đang hoạt động.
CREATE UNIQUE INDEX UX_PhanCong_KyThuatVien
    ON dbo.LenhDieuPhoi (KyThuatVienId) WHERE DangHoatDong = 1;

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
CREATE UNIQUE INDEX UX_VatTu_DangApDung
    ON dbo.DeXuatVatTu (DonHangId) WHERE DangApDung = 1;

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
CREATE UNIQUE INDEX UX_NghiemThu_ChoDuyet
    ON dbo.PhieuNghiemThu (DonHangId) WHERE TrangThai = 'Pending';

-- Mỗi đơn có tối đa một nghiệm thu đã duyệt.
CREATE UNIQUE INDEX UX_NghiemThu_DaDuyet
    ON dbo.PhieuNghiemThu (DonHangId) WHERE TrangThai = 'Approved';

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
CREATE UNIQUE INDEX UX_HoSo_ChoDuyet
    ON dbo.HoSoKTV (NguoiDungId) WHERE TrangThai = 'Pending';

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
