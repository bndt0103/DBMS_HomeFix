-- HomeFix: cài đặt vào database MỚI, không ghi đè dữ liệu.
-- Bật Query > SQLCMD Mode trong SSMS và sửa TenCSDL nếu cần.
:on error exit
:setvar TenCSDL "HomeFix_DBMS_Nhom08"
USE master;
GO
IF DB_ID(N'$(TenCSDL)') IS NOT NULL
    THROW 51009, 'DATABASE_ALREADY_EXISTS_CHOOSE_NEW_NAME', 1;
CREATE DATABASE [$(TenCSDL)];
GO
USE [$(TenCSDL)];
GO

-- MODULE: 00_schema.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* HomeFix: cấu trúc CSDL sạch. Chỉ chạy trên database mới, đã sao lưu bản cũ.
   Tiền: DECIMAL(18,2), thời gian: UTC, phiên bản: ROWVERSION.
   Không có ON DELETE CASCADE: chứng từ nghiệp vụ phải được bảo toàn. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dbo.NguoiDung', 'U') IS NOT NULL
    THROW 51009, N'Database đã có cấu trúc HomeFix; hãy dùng database mới.', 1;
GO
CREATE TABLE dbo.NguoiDung (
    Id INT IDENTITY CONSTRAINT PK_NguoiDung PRIMARY KEY,
    HoTen NVARCHAR(120) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL CONSTRAINT UQ_NguoiDung_SoDienThoai UNIQUE,
    Email NVARCHAR(254) NULL,
    MatKhauBam VARCHAR(100) NOT NULL,
    VaiTro VARCHAR(5) NOT NULL,
    DangHoatDong BIT NOT NULL CONSTRAINT DF_NguoiDung_HoatDong DEFAULT 1,
    DiaChi NVARCHAR(400) NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_NguoiDung_NgayTao DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_NguoiDung_VaiTro CHECK (VaiTro IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')),
    CONSTRAINT CK_NguoiDung_Ten CHECK (LEN(LTRIM(RTRIM(HoTen))) >= 2),
    CONSTRAINT CK_NguoiDung_SDT CHECK (LEN(SoDienThoai) BETWEEN 9 AND 15 AND SoDienThoai NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_NguoiDung_MatKhau CHECK (LEN(MatKhauBam) = 60 AND LEFT(MatKhauBam, 4) IN ('$2a$','$2b$','$2y$'))
);
CREATE TABLE dbo.KyThuatVien (
    Id INT CONSTRAINT PK_KyThuatVien PRIMARY KEY CONSTRAINT FK_KyThuatVien_NguoiDung REFERENCES dbo.NguoiDung(Id),
    NhomTayNghe VARCHAR(30) NOT NULL CONSTRAINT DF_KyThuatVien_TayNghe DEFAULT 'DIEN',
    KhuVucPhucVu NVARCHAR(200) NOT NULL CONSTRAINT DF_KyThuatVien_KhuVuc DEFAULT N'Chưa cập nhật',
    TrangThaiSanSang VARCHAR(12) NOT NULL CONSTRAINT DF_KyThuatVien_SanSang DEFAULT 'TamBan',
    SoDu DECIMAL(18,2) NOT NULL CONSTRAINT DF_KyThuatVien_SoDu DEFAULT 0,
    PhienBan ROWVERSION,
    CONSTRAINT CK_KyThuatVien_TrangThai CHECK (TrangThaiSanSang IN ('TamBan','SanSang','DangBan')),
    CONSTRAINT CK_KyThuatVien_MotChuyenMon CHECK (NhomTayNghe IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')),
    CONSTRAINT CK_KyThuatVien_SoDu CHECK (SoDu >= 0)
);
CREATE TABLE dbo.DanhMucDichVu (
    Id INT IDENTITY CONSTRAINT PK_DanhMucDichVu PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL CONSTRAINT UQ_DanhMucDichVu_Ten UNIQUE,
    Ma VARCHAR(30) NOT NULL CONSTRAINT UQ_DanhMucDichVu_Ma UNIQUE,
    DangHoatDong BIT NOT NULL CONSTRAINT DF_DanhMucDichVu_HoatDong DEFAULT 1,
    PhienBan ROWVERSION
);
CREATE TABLE dbo.DichVu (
    Id INT IDENTITY CONSTRAINT PK_DichVu PRIMARY KEY,
    DanhMucId INT NOT NULL CONSTRAINT FK_DichVu_DanhMuc REFERENCES dbo.DanhMucDichVu(Id),
    Ten NVARCHAR(180) NOT NULL,
    MoTa NVARCHAR(1000) NOT NULL,
    PhiKiemTra DECIMAL(18,2) NOT NULL,
    TienCong DECIMAL(18,2) NOT NULL,
    TyLeHoaHong DECIMAL(5,2) NOT NULL,
    DangHoatDong BIT NOT NULL CONSTRAINT DF_DichVu_HoatDong DEFAULT 1,
    PhienBan ROWVERSION,
    CONSTRAINT UQ_DichVu_DanhMuc_Ten UNIQUE (DanhMucId, Ten),
    CONSTRAINT CK_DichVu_Gia CHECK (PhiKiemTra >= 0 AND TienCong >= 0 AND TyLeHoaHong BETWEEN 0 AND 100)
);
CREATE TABLE dbo.DonHang (
    Id INT IDENTITY CONSTRAINT PK_DonHang PRIMARY KEY,
    KhachHangId INT NOT NULL CONSTRAINT FK_DonHang_Khach REFERENCES dbo.NguoiDung(Id),
    DichVuId INT NOT NULL CONSTRAINT FK_DonHang_DichVu REFERENCES dbo.DichVu(Id),
    TenDichVu NVARCHAR(180) NOT NULL,
    DiaChi NVARCHAR(400) NOT NULL,
    MoTa NVARCHAR(2000) NOT NULL,
    NgayHen DATETIME2(3) NULL,
    PhiHuyDon DECIMAL(18,2) NOT NULL CONSTRAINT DF_DonHang_PhiHuy DEFAULT 0,
    TrangThai VARCHAR(20) NOT NULL CONSTRAINT DF_DonHang_TrangThai DEFAULT 'ChoTiepNhan',
    KyThuatVienId INT NULL CONSTRAINT FK_DonHang_KTV REFERENCES dbo.KyThuatVien(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_DonHang_NgayTao DEFAULT SYSUTCDATETIME(),
    NgayCapNhat DATETIME2(3) NOT NULL CONSTRAINT DF_DonHang_CapNhat DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_DonHang_TrangThai CHECK (TrangThai IN ('ChoTiepNhan','ChoDuyetSoBo','ChoPhanCong','ChoNhan','DaTiepNhan','DangDiChuyen','DaDenNoi','DangXuLy','ChoNghiemThu','HoanThanh','Huy')),
    CONSTRAINT CK_DonHang_PhiHuy CHECK (PhiHuyDon >= 0 AND (PhiHuyDon = 0 OR (TrangThai = 'Huy' AND KyThuatVienId IS NOT NULL))),
    CONSTRAINT CK_DonHang_DiaChi CHECK (LEN(LTRIM(RTRIM(DiaChi))) >= 5)
);
CREATE TABLE dbo.LichSuDonHang (
    Id INT IDENTITY CONSTRAINT PK_LichSuDonHang PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_LichSuDonHang_Don REFERENCES dbo.DonHang(Id),
    TrangThaiTruoc VARCHAR(20) NULL,
    TrangThaiSau VARCHAR(20) NOT NULL,
    NguoiThucHienId INT NULL CONSTRAINT FK_LichSuDonHang_NguoiDung REFERENCES dbo.NguoiDung(Id),
    LyDo NVARCHAR(1000) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_LichSuDonHang_Ngay DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.LenhDieuPhoi (
    Id INT IDENTITY CONSTRAINT PK_LenhDieuPhoi PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_LenhDieuPhoi_Don REFERENCES dbo.DonHang(Id),
    KyThuatVienId INT NOT NULL CONSTRAINT FK_LenhDieuPhoi_KTV REFERENCES dbo.KyThuatVien(Id),
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_LenhDieuPhoi_TrangThai DEFAULT 'Pending',
    DangHoatDong BIT NOT NULL CONSTRAINT DF_LenhDieuPhoi_HoatDong DEFAULT 1,
    NguoiTaoId INT NOT NULL CONSTRAINT FK_LenhDieuPhoi_NguoiTao REFERENCES dbo.NguoiDung(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_LenhDieuPhoi_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_LenhDieuPhoi_TrangThai CHECK (TrangThai IN ('Pending','Accepted','Rejected'))
);
CREATE TABLE dbo.BaoGiaSoBo (
    Id INT IDENTITY CONSTRAINT PK_BaoGiaSoBo PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT UQ_BaoGiaSoBo_Don UNIQUE CONSTRAINT FK_BaoGiaSoBo_Don REFERENCES dbo.DonHang(Id),
    PhiKiemTra DECIMAL(18,2) NOT NULL,
    TienCong DECIMAL(18,2) NOT NULL,
    TyLeHoaHong DECIMAL(5,2) NOT NULL,
    TongTien AS (PhiKiemTra + TienCong) PERSISTED,
    ChanDoan NVARCHAR(1000) NOT NULL,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_BaoGiaSoBo_TrangThai DEFAULT 'Pending',
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_BaoGiaSoBo_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_BaoGiaSoBo_Gia CHECK (PhiKiemTra >= 0 AND TienCong >= 0 AND TyLeHoaHong BETWEEN 0 AND 100),
    CONSTRAINT CK_BaoGiaSoBo_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected'))
);
CREATE TABLE dbo.BangKeVatTu (
    Id INT IDENTITY CONSTRAINT PK_BangKeVatTu PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_BangKeVatTu_Don REFERENCES dbo.DonHang(Id),
    LanSuaDoi INT NOT NULL,
    DangApDung BIT NOT NULL CONSTRAINT DF_BangKeVatTu_ApDung DEFAULT 1,
    NguoiTaoId INT NOT NULL CONSTRAINT FK_BangKeVatTu_NguoiTao REFERENCES dbo.NguoiDung(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_BangKeVatTu_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT UQ_BangKeVatTu_PhienBan UNIQUE (DonHangId, LanSuaDoi),
    CONSTRAINT CK_BangKeVatTu_LanSuaDoi CHECK (LanSuaDoi > 0)
);
CREATE TABLE dbo.ChiTietVatTu (
    Id INT IDENTITY CONSTRAINT PK_ChiTietVatTu PRIMARY KEY,
    BangKeVatTuId INT NOT NULL CONSTRAINT FK_ChiTietVatTu_BangKe REFERENCES dbo.BangKeVatTu(Id),
    Ten NVARCHAR(200) NOT NULL,
    SoLuong DECIMAL(10,2) NOT NULL,
    DonGia DECIMAL(18,2) NOT NULL,
    SoThangBaoHanh INT NOT NULL CONSTRAINT DF_ChiTietVatTu_BaoHanh DEFAULT 0,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGia)) PERSISTED,
    CONSTRAINT CK_ChiTietVatTu_Gia CHECK (SoLuong > 0 AND DonGia >= 0 AND SoThangBaoHanh BETWEEN 0 AND 120)
);
CREATE TABLE dbo.TepDinhKem (
    Id INT IDENTITY CONSTRAINT PK_TepDinhKem PRIMARY KEY,
    ChuSoHuuId INT NOT NULL CONSTRAINT FK_TepDinhKem_Chu REFERENCES dbo.NguoiDung(Id),
    DonHangId INT NULL CONSTRAINT FK_TepDinhKem_Don REFERENCES dbo.DonHang(Id),
    MucDich VARCHAR(25) NOT NULL,
    KhoaLuuTru VARCHAR(100) NOT NULL CONSTRAINT UQ_TepDinhKem_Khoa UNIQUE,
    TenTepGoc NVARCHAR(255) NOT NULL,
    KieuMIME VARCHAR(100) NOT NULL,
    KichThuoc INT NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_TepDinhKem_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault','AcceptancePhoto','CustomerSignature','TechnicianSignature','WalletProof','MaterialEvidence','PaymentProof','TechnicianDocument','Avatar')),
    CONSTRAINT CK_TepDinhKem_KichThuoc CHECK (KichThuoc BETWEEN 1 AND 10485760),
    CONSTRAINT CK_TepDinhKem_MIME CHECK (KieuMIME IN ('image/jpeg','image/png','image/webp','application/pdf'))
);
CREATE TABLE dbo.PhieuNghiemThu (
    Id INT IDENTITY CONSTRAINT PK_PhieuNghiemThu PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_PhieuNghiemThu_Don REFERENCES dbo.DonHang(Id),
    KyThuatVienId INT NOT NULL CONSTRAINT FK_PhieuNghiemThu_KTV REFERENCES dbo.KyThuatVien(Id),
    BangKeVatTuId INT NULL CONSTRAINT FK_PhieuNghiemThu_VatTu REFERENCES dbo.BangKeVatTu(Id),
    NguyenNhan NVARCHAR(1000) NOT NULL,
    PhuongAnXuLy NVARCHAR(1000) NOT NULL,
    PhiKiemTra DECIMAL(18,2) NOT NULL,
    TienCong DECIMAL(18,2) NOT NULL,
    TongTienVatTu DECIMAL(18,2) NOT NULL,
    TongTien AS (PhiKiemTra + TienCong + TongTienVatTu) PERSISTED,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_PhieuNghiemThu_TrangThai DEFAULT 'Pending',
    ChuKyKTVId INT NULL CONSTRAINT FK_PhieuNghiemThu_ChuKyKTV REFERENCES dbo.TepDinhKem(Id),
    ChuKyKHId INT NULL CONSTRAINT FK_PhieuNghiemThu_ChuKyKH REFERENCES dbo.TepDinhKem(Id),
    PhuongThucThanhToan VARCHAR(4) NULL,
    NgayDuyet DATETIME2(3) NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_PhieuNghiemThu_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_PhieuNghiemThu_Gia CHECK (PhiKiemTra >= 0 AND TienCong >= 0 AND TongTienVatTu >= 0),
    CONSTRAINT CK_PhieuNghiemThu_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected')),
    CONSTRAINT CK_PhieuNghiemThu_PTTT CHECK (PhuongThucThanhToan IN ('COD','BANK')),
    CONSTRAINT CK_PhieuNghiemThu_Duyet CHECK (TrangThai <> 'Approved' OR (ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL AND PhuongThucThanhToan IS NOT NULL AND NgayDuyet IS NOT NULL))
);
CREATE TABLE dbo.TaiKhoanNganHang (
    Id INT IDENTITY CONSTRAINT PK_TaiKhoanNganHang PRIMARY KEY,
    MaNganHang VARCHAR(20) NOT NULL,
    TenNganHang NVARCHAR(150) NOT NULL,
    SoTaiKhoan VARCHAR(30) NOT NULL,
    ChuTaiKhoan NVARCHAR(150) NOT NULL,
    DangHoatDong BIT NOT NULL CONSTRAINT DF_TaiKhoanNganHang_HoatDong DEFAULT 1,
    PhienBan ROWVERSION,
    CONSTRAINT UQ_TaiKhoanNganHang UNIQUE (MaNganHang, SoTaiKhoan),
    CONSTRAINT CK_TaiKhoanNganHang_So CHECK (LEN(SoTaiKhoan) >= 6 AND SoTaiKhoan NOT LIKE '%[^0-9]%')
);
CREATE TABLE dbo.ThanhToan (
    Id INT IDENTITY CONSTRAINT PK_ThanhToan PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT UQ_ThanhToan_Don UNIQUE CONSTRAINT FK_ThanhToan_Don REFERENCES dbo.DonHang(Id),
    LoaiThanhToan VARCHAR(12) NOT NULL CONSTRAINT DF_ThanhToan_Loai DEFAULT 'DichVu',
    NghiemThuId INT NULL CONSTRAINT FK_ThanhToan_NghiemThu REFERENCES dbo.PhieuNghiemThu(Id),
    SoTien DECIMAL(18,2) NOT NULL,
    PhuongThuc VARCHAR(4) NOT NULL,
    NguoiThuTienId INT NOT NULL CONSTRAINT FK_ThanhToan_NguoiThu REFERENCES dbo.NguoiDung(Id),
    MaThamChieu VARCHAR(100) NULL,
    TaiKhoanNganHangId INT NULL CONSTRAINT FK_ThanhToan_NganHang REFERENCES dbo.TaiKhoanNganHang(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_ThanhToan_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_ThanhToan_Loai CHECK ((LoaiThanhToan = 'DichVu' AND NghiemThuId IS NOT NULL) OR (LoaiThanhToan = 'PhiHuyDon' AND NghiemThuId IS NULL AND PhuongThuc = 'BANK')),
    CONSTRAINT CK_ThanhToan_SoTien CHECK (SoTien > 0),
    CONSTRAINT CK_ThanhToan_PhuongThuc CHECK (PhuongThuc IN ('COD','BANK')),
    CONSTRAINT CK_ThanhToan_NganHang CHECK ((PhuongThuc = 'COD' AND TaiKhoanNganHangId IS NULL) OR (PhuongThuc = 'BANK' AND TaiKhoanNganHangId IS NOT NULL AND MaThamChieu IS NOT NULL))
);
CREATE TABLE dbo.DoiSoat (
    Id INT IDENTITY CONSTRAINT PK_DoiSoat PRIMARY KEY,
    ThanhToanId INT NOT NULL CONSTRAINT UQ_DoiSoat_ThanhToan UNIQUE CONSTRAINT FK_DoiSoat_ThanhToan REFERENCES dbo.ThanhToan(Id),
    DonHangId INT NOT NULL CONSTRAINT UQ_DoiSoat_Don UNIQUE CONSTRAINT FK_DoiSoat_Don REFERENCES dbo.DonHang(Id),
    KyThuatVienId INT NOT NULL CONSTRAINT FK_DoiSoat_KTV REFERENCES dbo.KyThuatVien(Id),
    TienCong DECIMAL(18,2) NOT NULL,
    TyLeHoaHong DECIMAL(5,2) NOT NULL,
    TienHoaHong AS (CONVERT(DECIMAL(18,2), ROUND(TienCong * TyLeHoaHong / 100, 2))) PERSISTED,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_DoiSoat_TrangThai DEFAULT 'Pending',
    NguoiDuyetId INT NULL CONSTRAINT FK_DoiSoat_NguoiDuyet REFERENCES dbo.NguoiDung(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_DoiSoat_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_DoiSoat_Tien CHECK (TienCong >= 0 AND TyLeHoaHong BETWEEN 0 AND 100),
    CONSTRAINT CK_DoiSoat_TrangThai CHECK (TrangThai IN ('Pending','Confirmed'))
);
CREATE TABLE dbo.YeuCauThanhToan (
    Id INT IDENTITY CONSTRAINT PK_YeuCauThanhToan PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_Don REFERENCES dbo.DonHang(Id),
    LoaiThanhToan VARCHAR(12) NOT NULL CONSTRAINT DF_YeuCauThanhToan_Loai DEFAULT 'DichVu',
    NghiemThuId INT NULL CONSTRAINT FK_YeuCauThanhToan_NghiemThu REFERENCES dbo.PhieuNghiemThu(Id),
    KhachHangId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_Khach REFERENCES dbo.NguoiDung(Id),
    TaiKhoanNganHangId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_NganHang REFERENCES dbo.TaiKhoanNganHang(Id),
    SoTien DECIMAL(18,2) NOT NULL,
    ChungTuId INT NULL CONSTRAINT FK_YeuCauThanhToan_Tep REFERENCES dbo.TepDinhKem(Id),
    MaThamChieu VARCHAR(100) NULL,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_YeuCauThanhToan_TrangThai DEFAULT 'Pending',
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauThanhToan_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_YeuCauThanhToan_Loai CHECK ((LoaiThanhToan = 'DichVu' AND NghiemThuId IS NOT NULL) OR (LoaiThanhToan = 'PhiHuyDon' AND NghiemThuId IS NULL)),
    CONSTRAINT CK_YeuCauThanhToan_Tien CHECK (SoTien > 0),
    CONSTRAINT CK_YeuCauThanhToan_TrangThai CHECK (TrangThai IN ('Pending','Confirmed','Rejected'))
);
CREATE TABLE dbo.YeuCauVi (
    Id INT IDENTITY CONSTRAINT PK_YeuCauVi PRIMARY KEY,
    KyThuatVienId INT NOT NULL CONSTRAINT FK_YeuCauVi_KTV REFERENCES dbo.KyThuatVien(Id),
    Loai VARCHAR(10) NOT NULL,
    SoTien DECIMAL(18,2) NOT NULL,
    GhiChu NVARCHAR(1000) NOT NULL,
    ChungTuId INT NULL CONSTRAINT FK_YeuCauVi_Tep REFERENCES dbo.TepDinhKem(Id),
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_YeuCauVi_TrangThai DEFAULT 'Pending',
    LyDo NVARCHAR(1000) NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauVi_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_YeuCauVi_Loai CHECK (Loai IN ('Deposit','Withdrawal')),
    CONSTRAINT CK_YeuCauVi_Tien CHECK (SoTien > 0),
    CONSTRAINT CK_YeuCauVi_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected','Cancelled'))
);
CREATE TABLE dbo.GiaoDichVi (
    Id INT IDENTITY CONSTRAINT PK_GiaoDichVi PRIMARY KEY,
    KyThuatVienId INT NOT NULL CONSTRAINT FK_GiaoDichVi_KTV REFERENCES dbo.KyThuatVien(Id),
    Loai VARCHAR(20) NOT NULL,
    SoTien DECIMAL(18,2) NOT NULL,
    LoaiThamChieu VARCHAR(30) NOT NULL,
    ThamChieuId INT NOT NULL,
    NguoiThucHienId INT NOT NULL CONSTRAINT FK_GiaoDichVi_NguoiDung REFERENCES dbo.NguoiDung(Id),
    GhiChu NVARCHAR(1000) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_GiaoDichVi_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_GiaoDichVi_ThamChieu UNIQUE (LoaiThamChieu, ThamChieuId),
    CONSTRAINT CK_GiaoDichVi_Loai CHECK (Loai IN ('Deposit','Withdrawal','Commission','SettlementCredit','Reversal')),
    CONSTRAINT CK_GiaoDichVi_Tien CHECK (SoTien <> 0 AND ((Loai IN ('Deposit','SettlementCredit') AND SoTien > 0) OR (Loai IN ('Withdrawal','Commission') AND SoTien < 0) OR Loai = 'Reversal'))
);
CREATE TABLE dbo.HoSoKTV (
    Id INT IDENTITY CONSTRAINT PK_HoSoKTV PRIMARY KEY,
    NguoiDungId INT NOT NULL CONSTRAINT FK_HoSoKTV_NguoiDung REFERENCES dbo.NguoiDung(Id),
    NhomTayNghe VARCHAR(30) NOT NULL,
    KhuVucPhucVu NVARCHAR(200) NOT NULL,
    KinhNghiem NVARCHAR(2000) NOT NULL,
    HoSoJSON NVARCHAR(MAX) NULL CONSTRAINT CK_HoSoKTV_JSON CHECK (HoSoJSON IS NULL OR ISJSON(HoSoJSON) = 1),
    CONSTRAINT CK_HoSoKTV_MotChuyenMon CHECK (NhomTayNghe IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')),
    GiayToMatTruocId INT NULL CONSTRAINT FK_HoSoKTV_MatTruoc REFERENCES dbo.TepDinhKem(Id),
    GiayToMatSauId INT NULL CONSTRAINT FK_HoSoKTV_MatSau REFERENCES dbo.TepDinhKem(Id),
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_HoSoKTV_TrangThai DEFAULT 'Pending',
    LyDo NVARCHAR(1000) NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_HoSoKTV_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_HoSoKTV_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected'))
);
CREATE TABLE dbo.YeuCauHoTro (
    Id INT IDENTITY CONSTRAINT PK_YeuCauHoTro PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_YeuCauHoTro_Don REFERENCES dbo.DonHang(Id),
    KhachHangId INT NOT NULL CONSTRAINT FK_YeuCauHoTro_Khach REFERENCES dbo.NguoiDung(Id),
    Loai VARCHAR(10) NOT NULL,
    MoTa NVARCHAR(2000) NOT NULL,
    TrangThai VARCHAR(12) NOT NULL CONSTRAINT DF_YeuCauHoTro_TrangThai DEFAULT 'Open',
    KetQuaXuLy NVARCHAR(2000) NULL,
    NguoiXuLyId INT NULL CONSTRAINT FK_YeuCauHoTro_NguoiXuLy REFERENCES dbo.NguoiDung(Id),
    NgayCapNhat DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauHoTro_CapNhat DEFAULT SYSUTCDATETIME(),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauHoTro_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_YeuCauHoTro_Loai CHECK (Loai IN ('Complaint','Warranty')),
    CONSTRAINT CK_YeuCauHoTro_TrangThai CHECK (TrangThai IN ('Open','InProgress','Resolved','Rejected'))
);
CREATE TABLE dbo.TraoDoiHoTro (
    Id INT IDENTITY CONSTRAINT PK_TraoDoiHoTro PRIMARY KEY,
    TrangThai VARCHAR(12) NULL CONSTRAINT CK_TraoDoiHoTro_TrangThai CHECK (TrangThai IN ('InProgress','Resolved','Rejected')),
    YeuCauHoTroId INT NOT NULL CONSTRAINT FK_TraoDoiHoTro_YeuCau REFERENCES dbo.YeuCauHoTro(Id),
    NguoiGuiId INT NOT NULL CONSTRAINT FK_TraoDoiHoTro_NguoiGui REFERENCES dbo.NguoiDung(Id),
    NoiDung NVARCHAR(2000) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_TraoDoiHoTro_Ngay DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.DanhGia (
    Id INT IDENTITY CONSTRAINT PK_DanhGia PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT UQ_DanhGia_Don UNIQUE CONSTRAINT FK_DanhGia_Don REFERENCES dbo.DonHang(Id),
    KhachHangId INT NOT NULL CONSTRAINT FK_DanhGia_Khach REFERENCES dbo.NguoiDung(Id),
    KyThuatVienId INT NOT NULL CONSTRAINT FK_DanhGia_KTV REFERENCES dbo.KyThuatVien(Id),
    Diem INT NOT NULL,
    NhanXet NVARCHAR(2000) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_DanhGia_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_DanhGia_Diem CHECK (Diem BETWEEN 1 AND 5)
);
CREATE TABLE dbo.GhiChuDon (
    Id INT IDENTITY CONSTRAINT PK_GhiChuDon PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_GhiChuDon_Don REFERENCES dbo.DonHang(Id),
    NguoiVietId INT NOT NULL CONSTRAINT FK_GhiChuDon_NguoiViet REFERENCES dbo.NguoiDung(Id),
    NoiDung NVARCHAR(2000) NOT NULL,
    NoiBo BIT NOT NULL CONSTRAINT DF_GhiChuDon_NoiBo DEFAULT 0,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_GhiChuDon_Ngay DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.ThongBao (
    Id INT IDENTITY CONSTRAINT PK_ThongBao PRIMARY KEY,
    NguoiDungId INT NOT NULL CONSTRAINT FK_ThongBao_NguoiDung REFERENCES dbo.NguoiDung(Id),
    DonHangId INT NULL CONSTRAINT FK_ThongBao_Don REFERENCES dbo.DonHang(Id),
    TieuDe NVARCHAR(200) NOT NULL,
    NoiDung NVARCHAR(2000) NOT NULL,
    DaDoc BIT NOT NULL CONSTRAINT DF_ThongBao_DaDoc DEFAULT 0,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_ThongBao_Ngay DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.NhatKy (
    Id INT IDENTITY CONSTRAINT PK_NhatKy PRIMARY KEY,
    NguoiThucHienId INT NULL CONSTRAINT FK_NhatKy_NguoiDung REFERENCES dbo.NguoiDung(Id),
    ThaoTac NVARCHAR(100) NOT NULL,
    DoiTuong NVARCHAR(100) NOT NULL,
    DoiTuongId INT NULL,
    ChiTiet NVARCHAR(2000) NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_NhatKy_Ngay DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.CauHinh (
    Khoa VARCHAR(80) CONSTRAINT PK_CauHinh PRIMARY KEY,
    GiaTri NVARCHAR(1000) NOT NULL,
    NhanHienThi NVARCHAR(150) NOT NULL
);
GO

-- Tài khoản được khách chọn lúc ký nghiệm thu, trước khi gửi chứng từ.
ALTER TABLE dbo.PhieuNghiemThu ADD TaiKhoanNganHangId INT NULL
    CONSTRAINT FK_NghiemThu_NganHang REFERENCES dbo.TaiKhoanNganHang(Id);
GO


GO

-- MODULE: 01_index.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* UNIQUE lọc bảo vệ quy tắc nghiệp vụ; chỉ mục thường tăng tốc tra cứu.
   Các khóa chính/UNIQUE trong schema đã tự có chỉ mục, không tạo trùng. */
CREATE UNIQUE INDEX UX_NguoiDung_Email ON dbo.NguoiDung(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_LenhDieuPhoi_Don ON dbo.LenhDieuPhoi(DonHangId) WHERE DangHoatDong = 1;
CREATE UNIQUE INDEX UX_LenhDieuPhoi_Tho ON dbo.LenhDieuPhoi(KyThuatVienId) WHERE DangHoatDong = 1;
CREATE UNIQUE INDEX UX_BangKeVatTu_DangApDung ON dbo.BangKeVatTu(DonHangId) WHERE DangApDung = 1;
CREATE UNIQUE INDEX UX_NghiemThu_Don ON dbo.PhieuNghiemThu(DonHangId) WHERE TrangThai <> 'Rejected';
CREATE UNIQUE INDEX UX_ThanhToan_NghiemThu ON dbo.ThanhToan(NghiemThuId) WHERE NghiemThuId IS NOT NULL;
CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieu ON dbo.ThanhToan(MaThamChieu) WHERE MaThamChieu IS NOT NULL;
CREATE UNIQUE INDEX UX_YeuCauThanhToan_DangCho ON dbo.YeuCauThanhToan(DonHangId) WHERE TrangThai = 'Pending';
CREATE UNIQUE INDEX UX_HoSoKTV_DangCho ON dbo.HoSoKTV(NguoiDungId) WHERE TrangThai = 'Pending';
CREATE INDEX IX_DonHang_Khach_TrangThai ON dbo.DonHang(KhachHangId, TrangThai) INCLUDE (DichVuId, KyThuatVienId, NgayTao);
CREATE INDEX IX_DonHang_Tho_TrangThai ON dbo.DonHang(KyThuatVienId, TrangThai) INCLUDE (KhachHangId, NgayTao);
CREATE INDEX IX_DonHang_TrangThai_Ngay ON dbo.DonHang(TrangThai, NgayTao DESC);
CREATE INDEX IX_LichSuDonHang_Don_Ngay ON dbo.LichSuDonHang(DonHangId, NgayTao, Id);
CREATE INDEX IX_ChiTietVatTu_BangKe ON dbo.ChiTietVatTu(BangKeVatTuId) INCLUDE (ThanhTien, SoThangBaoHanh);
CREATE INDEX IX_GiaoDichVi_Tho_Ngay ON dbo.GiaoDichVi(KyThuatVienId, NgayTao DESC) INCLUDE (SoTien, Loai);
CREATE INDEX IX_YeuCauVi_TrangThai_Ngay ON dbo.YeuCauVi(TrangThai, NgayTao) INCLUDE (KyThuatVienId, SoTien);
CREATE INDEX IX_YeuCauHoTro_TrangThai ON dbo.YeuCauHoTro(TrangThai, NgayTao) INCLUDE (DonHangId, KhachHangId);
CREATE INDEX IX_TraoDoiHoTro_YeuCau ON dbo.TraoDoiHoTro(YeuCauHoTroId, NgayTao);
CREATE INDEX IX_ThongBao_Nguoi_DaDoc ON dbo.ThongBao(NguoiDungId, DaDoc, NgayTao DESC);
CREATE INDEX IX_TepDinhKem_Don ON dbo.TepDinhKem(DonHangId, MucDich) INCLUDE (ChuSoHuuId);
GO


GO

-- MODULE: 02_function.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Hàm chỉ đọc/tính toán; không INSERT/UPDATE/DELETE và không mở transaction. */
CREATE OR ALTER FUNCTION dbo.fn_HoaHong (
    @TienCong DECIMAL(18,2), @TyLeHoaHong DECIMAL(5,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN CONVERT(DECIMAL(18,2), ROUND(@TienCong * @TyLeHoaHong / 100, 2));
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_SoDuVi (@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN (
    SELECT CONVERT(DECIMAL(18,2), COALESCE(SUM(SoTien), 0)) AS SoDu
    FROM dbo.GiaoDichVi WHERE KyThuatVienId = @KyThuatVienId
);
GO
CREATE OR ALTER FUNCTION dbo.fn_DiemDanhGia (@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN (
    SELECT CONVERT(DECIMAL(4,2), COALESCE(AVG(CONVERT(DECIMAL(4,2), Diem)), 0)) AS DiemTrungBinh
    FROM dbo.DanhGia WHERE KyThuatVienId = @KyThuatVienId
);
GO
CREATE OR ALTER FUNCTION dbo.fn_ThongKeDon (@TuNgay DATE = NULL, @DenNgay DATE = NULL)
RETURNS TABLE
AS
RETURN (
    SELECT COUNT_BIG(*) AS TongDon,
        COALESCE(SUM(CASE WHEN TrangThai = 'HoanThanh' THEN 1 ELSE 0 END), 0) AS DonHoanThanh,
        COALESCE(SUM(CASE WHEN TrangThai = 'Huy' THEN 1 ELSE 0 END), 0) AS DonHuy,
        COALESCE(SUM(CASE WHEN TrangThai NOT IN ('HoanThanh','Huy') THEN 1 ELSE 0 END), 0) AS DonDangXuLy
    FROM dbo.DonHang
    -- NgayTao lưu UTC; tham số DATE là ngày người dùng ở Việt Nam.
    WHERE (@TuNgay IS NULL OR NgayTao >= DATEADD(HOUR, -7, CONVERT(DATETIME2, @TuNgay)))
        AND (@DenNgay IS NULL OR NgayTao < DATEADD(HOUR, -7, DATEADD(DAY, 1, CONVERT(DATETIME2, @DenNgay))))
);
GO
CREATE OR ALTER FUNCTION dbo.fn_HanBaoHanh (@DonHangId INT)
RETURNS TABLE
AS
RETURN (
    SELECT MAX(CASE WHEN ct.SoThangBaoHanh > 0 THEN DATEADD(MONTH, ct.SoThangBaoHanh, nt.NgayDuyet) END) AS HanBaoHanh
    FROM dbo.PhieuNghiemThu AS nt
    LEFT JOIN dbo.ChiTietVatTu AS ct ON ct.BangKeVatTuId = nt.BangKeVatTuId
    WHERE nt.DonHangId = @DonHangId AND nt.TrangThai = 'Approved'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_TongTienDonHang (@DonHangId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18,2);
    IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE Id = @DonHangId AND TrangThai = 'Huy')
        RETURN (SELECT PhiHuyDon FROM dbo.DonHang WHERE Id = @DonHangId);
    SELECT @TongTien = TongTien FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai <> 'Rejected';
    IF @TongTien IS NULL
    BEGIN
        SELECT @TongTien = bg.TongTien + COALESCE((
            SELECT SUM(ct.ThanhTien)
            FROM dbo.BangKeVatTu AS dx
            INNER JOIN dbo.ChiTietVatTu AS ct ON ct.BangKeVatTuId = dx.Id
            WHERE dx.DonHangId = @DonHangId AND dx.DangApDung = 1
        ), 0)
        FROM dbo.BaoGiaSoBo AS bg WHERE bg.DonHangId = @DonHangId AND bg.TrangThai = 'Approved';
    END;
    RETURN COALESCE(@TongTien, 0);
END;
GO

-- Cùng một bộ lọc được dùng khi hiển thị danh sách và khi ghi lệnh phân công.
-- Mỗi KTV có đúng một chuyên môn; khu vực vẫn có thể ngăn cách bằng dấu phẩy hoặc chấm phẩy.
-- So từng thành phần địa chỉ để Quận 1 không bị nhầm với Quận 10.
CREATE OR ALTER FUNCTION dbo.fn_KyThuatVienPhuHop (@DonHangId INT)
RETURNS TABLE
AS
RETURN (
    SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe,
        ktv.KhuVucPhucVu, ktv.TrangThaiSanSang, ktv.PhienBan
    FROM dbo.DonHang AS dh
    INNER JOIN dbo.DichVu AS dv ON dv.Id = dh.DichVuId
    INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
    CROSS JOIN dbo.KyThuatVien AS ktv
    INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id
    WHERE dh.Id = @DonHangId AND dh.TrangThai = 'ChoPhanCong'
      AND nd.VaiTro = 'KTV' AND nd.DangHoatDong = 1
      AND ktv.TrangThaiSanSang = 'SanSang'
      AND NOT EXISTS (
          SELECT 1 FROM dbo.LenhDieuPhoi AS l
          WHERE l.KyThuatVienId = ktv.Id AND l.DangHoatDong = 1
      )
      AND NOT EXISTS (
          SELECT 1 FROM dbo.DonHang AS d
          WHERE d.KyThuatVienId = ktv.Id AND d.TrangThai NOT IN ('HoanThanh', 'Huy')
      )
      AND ktv.NhomTayNghe = dm.Ma
      AND EXISTS (
          SELECT 1
          FROM STRING_SPLIT(REPLACE(ktv.KhuVucPhucVu, N';', N','), N',') AS k
          CROSS JOIN STRING_SPLIT(dh.DiaChi, N',') AS d
          CROSS APPLY (SELECT
              REPLACE(REPLACE(REPLACE(REPLACE(LOWER(k.value) COLLATE Latin1_General_100_CI_AI,
                  N'.', N''), N' ', N''), N'thànhphố', N'tp'), N'quận', N'q') AS KhuVuc,
              REPLACE(REPLACE(REPLACE(REPLACE(LOWER(d.value) COLLATE Latin1_General_100_CI_AI,
                  N'.', N''), N' ', N''), N'thànhphố', N'tp'), N'quận', N'q') AS DiaChi
          ) AS c
          WHERE c.KhuVuc <> N'' AND (
              c.KhuVuc = c.DiaChi
              OR (c.KhuVuc IN (N'tphochiminh', N'hochiminh', N'tphcm', N'hcm')
                  AND c.DiaChi IN (N'tphochiminh', N'hochiminh', N'tphcm', N'hcm', N'thuduc', N'tpthuduc'))
              OR (c.KhuVuc IN (N'thuduc', N'tpthuduc') AND c.DiaChi IN (N'thuduc', N'tpthuduc'))
          )
      )
);
GO


GO

-- MODULE: 03_view.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* View công khai ghi rõ từng cột; bí mật chỉ dành cho view xác thực nội bộ. */
CREATE OR ALTER VIEW dbo.vw_NguoiDung
AS
SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan
FROM dbo.NguoiDung;
GO
CREATE OR ALTER VIEW dbo.vw_KyThuatVien
AS
SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe, ktv.KhuVucPhucVu,
    ktv.TrangThaiSanSang, ktv.SoDu, ktv.PhienBan
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id;
GO
CREATE OR ALTER VIEW dbo.vw_DanhMucDichVu
AS
SELECT Id, Ten, Ma, DangHoatDong, PhienBan
FROM dbo.DanhMucDichVu;
GO
CREATE OR ALTER VIEW dbo.vw_DichVu
AS
SELECT Id, DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong, PhienBan
FROM dbo.DichVu;
GO
CREATE OR ALTER VIEW dbo.vw_LichSuDonHang
AS
SELECT Id, DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo, NgayTao
FROM dbo.LichSuDonHang;
GO
CREATE OR ALTER VIEW dbo.vw_LenhDieuPhoi
AS
SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId, NgayTao, PhienBan
FROM dbo.LenhDieuPhoi;
GO
CREATE OR ALTER VIEW dbo.vw_BaoGiaSoBo
AS
SELECT Id, DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, TongTien, ChanDoan, TrangThai, NgayTao, PhienBan
FROM dbo.BaoGiaSoBo;
GO
CREATE OR ALTER VIEW dbo.vw_BangKeVatTu
AS
SELECT Id, DonHangId, LanSuaDoi, DangApDung, NguoiTaoId, NgayTao, PhienBan
FROM dbo.BangKeVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietVatTu
AS
SELECT Id, BangKeVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh, ThanhTien
FROM dbo.ChiTietVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_PhieuNghiemThu
AS
SELECT Id, DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, TaiKhoanNganHangId, NgayDuyet, NgayTao, PhienBan
FROM dbo.PhieuNghiemThu;
GO
CREATE OR ALTER VIEW dbo.vw_ThanhToan
AS
SELECT Id, DonHangId, LoaiThanhToan, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId, NgayTao
FROM dbo.ThanhToan;
GO
CREATE OR ALTER VIEW dbo.vw_DoiSoat
AS
SELECT Id, ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TienHoaHong, TrangThai, NguoiDuyetId, NgayTao, PhienBan
FROM dbo.DoiSoat;
GO
CREATE OR ALTER VIEW dbo.vw_TaiKhoanNganHang
AS
SELECT Id, MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong, PhienBan
FROM dbo.TaiKhoanNganHang;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauThanhToan
AS
SELECT Id, DonHangId, LoaiThanhToan, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai, NgayTao, PhienBan
FROM dbo.YeuCauThanhToan;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauVi
AS
SELECT Id, KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai, LyDo, NgayTao, PhienBan
FROM dbo.YeuCauVi;
GO
CREATE OR ALTER VIEW dbo.vw_GiaoDichVi
AS
SELECT Id, KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu, NgayTao
FROM dbo.GiaoDichVi;
GO
CREATE OR ALTER VIEW dbo.vw_HoSoKTV
AS
SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, HoSoJSON, GiayToMatTruocId, GiayToMatSauId, TrangThai, LyDo, NgayTao, PhienBan
FROM dbo.HoSoKTV;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauHoTro
AS
SELECT ht.Id, ht.DonHangId, ht.KhachHangId, kh.HoTen AS TenKhachHang, kh.SoDienThoai AS SDTKhachHang,
    ht.Loai, ht.MoTa, ht.TrangThai, ht.KetQuaXuLy, ht.NguoiXuLyId, nv.HoTen AS TenNguoiXuLy,
    dh.TenDichVu, dh.DiaChi, dh.TrangThai AS TrangThaiDon, ht.NgayTao, ht.NgayCapNhat, ht.PhienBan
FROM dbo.YeuCauHoTro AS ht
INNER JOIN dbo.NguoiDung AS kh ON kh.Id = ht.KhachHangId
INNER JOIN dbo.DonHang AS dh ON dh.Id = ht.DonHangId
LEFT JOIN dbo.NguoiDung AS nv ON nv.Id = ht.NguoiXuLyId;
GO
CREATE OR ALTER VIEW dbo.vw_TraoDoiHoTro
AS
SELECT td.Id, td.YeuCauHoTroId, td.NguoiGuiId, nd.HoTen, nd.VaiTro, td.NoiDung, td.TrangThai, td.NgayTao
FROM dbo.TraoDoiHoTro AS td INNER JOIN dbo.NguoiDung AS nd ON nd.Id = td.NguoiGuiId;
GO
CREATE OR ALTER VIEW dbo.vw_DanhGia
AS
SELECT Id, DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet, NgayTao
FROM dbo.DanhGia;
GO
CREATE OR ALTER VIEW dbo.vw_GhiChuDon
AS
SELECT Id, DonHangId, NguoiVietId, NoiDung, NoiBo, NgayTao
FROM dbo.GhiChuDon;
GO
CREATE OR ALTER VIEW dbo.vw_TepDinhKem
AS
SELECT Id, ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc, NgayTao
FROM dbo.TepDinhKem;
GO
CREATE OR ALTER VIEW dbo.vw_ThongBao
AS
SELECT Id, NguoiDungId, DonHangId, TieuDe, NoiDung, DaDoc, NgayTao
FROM dbo.ThongBao;
GO
CREATE OR ALTER VIEW dbo.vw_NhatKy
AS
SELECT nk.Id, nk.NguoiThucHienId, nd.HoTen AS TenNguoiThucHien,
    nk.ThaoTac, nk.DoiTuong, nk.DoiTuongId, nk.ChiTiet, nk.NgayTao
FROM dbo.NhatKy AS nk
LEFT JOIN dbo.NguoiDung AS nd ON nd.Id = nk.NguoiThucHienId;
GO
CREATE OR ALTER VIEW dbo.vw_CauHinh
AS
SELECT Khoa, GiaTri, NhanHienThi
FROM dbo.CauHinh;
GO

CREATE OR ALTER VIEW dbo.vw_XacThucDangNhap
AS
SELECT Id, HoTen, SoDienThoai, Email, MatKhauBam, VaiTro, DangHoatDong, PhienBan
FROM dbo.NguoiDung;
GO
CREATE OR ALTER VIEW dbo.vw_DonHangTongHop
AS
SELECT dh.Id, dv.DanhMucId, dm.Ma AS MaDanhMuc, dh.KhachHangId, kh.HoTen AS TenKhachHang, kh.SoDienThoai AS SDTKhachHang,
    dh.DichVuId, dh.TenDichVu, dh.DiaChi, dh.MoTa, dh.NgayHen, dh.TrangThai,
    dh.KyThuatVienId, ktv.HoTen AS TenKyThuatVien, ktv.SoDienThoai AS SDTKyThuatVien,
    dh.PhiHuyDon, dh.NgayTao, dh.NgayCapNhat, dh.PhienBan, dbo.fn_TongTienDonHang(dh.Id) AS TongTien,
    (SELECT HanBaoHanh FROM dbo.fn_HanBaoHanh(dh.Id)) AS HanBaoHanh
FROM dbo.DonHang AS dh
INNER JOIN dbo.DichVu AS dv ON dv.Id = dh.DichVuId
INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
INNER JOIN dbo.NguoiDung AS kh ON kh.Id = dh.KhachHangId
LEFT JOIN dbo.NguoiDung AS ktv ON ktv.Id = dh.KyThuatVienId;
GO
CREATE OR ALTER VIEW dbo.vw_DichVuCongKhai
AS
SELECT dv.Id, dv.DanhMucId, dm.Ten AS TenDanhMuc, dm.Ma AS MaDanhMuc,
    dv.Ten, dv.MoTa, dv.PhiKiemTra, dv.TienCong, dv.TyLeHoaHong, dv.DangHoatDong, dv.PhienBan
FROM dbo.DichVu AS dv
INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
WHERE dv.DangHoatDong = 1 AND dm.DangHoatDong = 1;
GO
CREATE OR ALTER VIEW dbo.vw_DoanhThuNgay
AS
SELECT CONVERT(DATE, DATEADD(HOUR, 7, tt.NgayTao)) AS Ngay, COUNT_BIG(*) AS SoDon,
    SUM(tt.SoTien) AS TongThu, SUM(CASE WHEN tt.PhuongThuc = 'COD' THEN tt.SoTien ELSE 0 END) AS ThuCOD,
    SUM(CASE WHEN tt.PhuongThuc = 'BANK' THEN tt.SoTien ELSE 0 END) AS ThuNganHang,
    SUM(ds.TienHoaHong) AS TienHoaHong,
    SUM(CASE WHEN ds.TrangThai = 'Confirmed' THEN ds.TienHoaHong ELSE 0 END) AS HoaHongDaDoiSoat
FROM dbo.ThanhToan AS tt
INNER JOIN dbo.DoiSoat AS ds ON ds.ThanhToanId = tt.Id
GROUP BY CONVERT(DATE, DATEADD(HOUR, 7, tt.NgayTao));
GO
CREATE OR ALTER VIEW dbo.vw_ViKyThuatVien
AS
SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe, ktv.KhuVucPhucVu,
    ktv.TrangThaiSanSang, ktv.SoDu, (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS SoDuSoCai,
    ktv.SoDu - (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS ChenhLech, ktv.PhienBan
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id;
GO
CREATE OR ALTER VIEW dbo.vw_HieuSuatKyThuatVien
AS
SELECT ktv.Id AS KyThuatVienId, nd.HoTen, COUNT(dh.Id) AS TongDon,
    COALESCE(SUM(CASE WHEN dh.TrangThai = 'HoanThanh' THEN 1 ELSE 0 END), 0) AS SoDonHoanThanh,
    (SELECT DiemTrungBinh FROM dbo.fn_DiemDanhGia(ktv.Id)) AS DiemTrungBinh,
    COALESCE(SUM(CASE WHEN dh.TrangThai = 'HoanThanh' THEN tt.SoTien ELSE 0 END), 0) AS TongTienDaThu
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id
LEFT JOIN dbo.DonHang AS dh ON dh.KyThuatVienId = ktv.Id
LEFT JOIN dbo.ThanhToan AS tt ON tt.DonHangId = dh.Id
GROUP BY ktv.Id, nd.HoTen;
GO


GO

-- MODULE: 04_sp.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Thủ tục tài khoản và tiện ích.
   Mỗi lệnh ghi là một giao dịch nguyên tử. Nếu được gọi trong giao dịch khác,
   SAVE TRANSACTION giữ điểm quay lui; không COMMIT giao dịch của bên gọi.
   Mật khẩu được băm bcrypt ở backend; SQL chỉ lưu chuỗi băm. */
CREATE OR ALTER PROCEDURE dbo.sp_DangKyKhachHang
    @HoTen NVARCHAR(120), @SoDienThoai VARCHAR(15), @MatKhauBam VARCHAR(100),
    @Email NVARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DangKyKhachHang;

        SET @HoTen = LTRIM(RTRIM(@HoTen));
        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        IF EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE SoDienThoai = @SoDienThoai)
            THROW 51009, N'Số điện thoại đã được đăng ký.', 1;
        IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Email = @Email)
            THROW 51009, N'Email đã được sử dụng.', 1;
        INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, Email, MatKhauBam, VaiTro)
        VALUES (@HoTen, @SoDienThoai, @Email, @MatKhauBam, 'KH');
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DangKyKhachHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoTaiKhoanNoiBo
    @NguoiThucHienId INT, @HoTen NVARCHAR(120), @SoDienThoai VARCHAR(15),
    @MatKhauBam VARCHAR(100), @VaiTro VARCHAR(5), @Email NVARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_TaoTaiKhoanNoiBo;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        SET @HoTen = LTRIM(RTRIM(@HoTen));
        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không nằm trong bảy vai trò hệ thống.', 1;
        IF EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE SoDienThoai = @SoDienThoai)
            THROW 51009, N'Số điện thoại đã được sử dụng.', 1;
        INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, Email, MatKhauBam, VaiTro)
        VALUES (@HoTen, @SoDienThoai, @Email, @MatKhauBam, @VaiTro);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @VaiTro = 'KTV' INSERT INTO dbo.KyThuatVien(Id) VALUES (@Id);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Tạo tài khoản', N'NguoiDung', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_TaoTaiKhoanNoiBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiMatKhau
    @NguoiThucHienId INT, @MatKhauBam VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DoiMatKhau;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo' AND USER_NAME() <> N'hf_UngDung'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        UPDATE dbo.NguoiDung SET MatKhauBam = @MatKhauBam WHERE Id = @NguoiThucHienId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Đổi mật khẩu', N'NguoiDung', @NguoiThucHienId);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DoiMatKhau;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatThongTinNguoiDung
    @NguoiThucHienId INT, @HoTen NVARCHAR(120),
    @Email NVARCHAR(254) = NULL, @DiaChi NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatThongTinNguoiDung;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        UPDATE dbo.NguoiDung SET HoTen = LTRIM(RTRIM(@HoTen)), Email = @Email, DiaChi = @DiaChi WHERE Id = @NguoiThucHienId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatThongTinNguoiDung;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhoaMoKhoaTaiKhoan
    @NguoiThucHienId INT, @NguoiDungId INT, @DangHoatDong BIT,
    @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_KhoaMoKhoaTaiKhoan;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @NguoiDungId = @NguoiThucHienId AND @DangHoatDong = 0
            THROW 51009, N'Quản trị viên không được tự khóa tài khoản đang sử dụng.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND VaiTro = 'ADMIN')
           AND (SELECT COUNT(*) FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId) = 0
            THROW 51009, N'Phải duy trì ít nhất một quản trị viên đang hoạt động.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId AND TrangThai NOT IN ('HoanThanh','Huy'))
            THROW 51009, N'Kỹ thuật viên còn đơn đang thực hiện; cần xử lý đơn trước khi khóa.', 1;
        UPDATE dbo.NguoiDung SET DangHoatDong = @DangHoatDong WHERE Id = @NguoiDungId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, CASE WHEN @DangHoatDong = 1 THEN N'Mở khóa tài khoản' ELSE N'Khóa tài khoản' END, N'NguoiDung', @NguoiDungId);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_KhoaMoKhoaTaiKhoan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiVaiTroNguoiDung
    @NguoiThucHienId INT, @NguoiDungId INT, @VaiTro VARCHAR(5),
    @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DoiVaiTroNguoiDung;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không hợp lệ.', 1;
        IF @NguoiDungId = @NguoiThucHienId AND @VaiTro <> 'ADMIN'
            THROW 51009, N'Không được tự bỏ quyền quản trị của phiên đăng nhập.', 1;
        IF @VaiTro <> 'ADMIN' AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND VaiTro = 'ADMIN')
           AND NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId)
            THROW 51009, N'Phải giữ lại ít nhất một quản trị viên.', 1;
        IF @VaiTro <> 'KTV' AND EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.GiaoDichVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.YeuCauVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiDungId)
                THROW 51009, N'Thợ đã có chứng từ; giữ vai trò để bảo toàn lịch sử, có thể khóa tài khoản.', 1;
            DELETE FROM dbo.KyThuatVien WHERE Id = @NguoiDungId;
        END;
        UPDATE dbo.NguoiDung SET VaiTro = @VaiTro WHERE Id = @NguoiDungId;
        IF @VaiTro = 'KTV' AND NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
            INSERT INTO dbo.KyThuatVien(Id) VALUES (@NguoiDungId);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Đổi vai trò', N'NguoiDung', @NguoiDungId, @VaiTro);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DoiVaiTroNguoiDung;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminCapNhatTaiKhoan
    @NguoiThucHienId INT, @NguoiDungId INT, @HoTen NVARCHAR(120),
    @SoDienThoai VARCHAR(15), @Email NVARCHAR(254) = NULL,
    @VaiTro VARCHAR(5), @NhomTayNghe VARCHAR(30) = NULL,
    @DangHoatDong BIT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @VaiTroCu VARCHAR(5);
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_AdminCapNhatTaiKhoan;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro = 'ADMIN' AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_ADMIN'
        ) THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        SELECT @VaiTroCu = VaiTro FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId;
        IF @VaiTroCu IS NULL THROW 51004, N'Không tìm thấy tài khoản cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;
        IF NULLIF(LTRIM(RTRIM(@HoTen)), N'') IS NULL OR @SoDienThoai LIKE '%[^0-9]%' OR LEN(@SoDienThoai) NOT BETWEEN 9 AND 15
            THROW 51009, N'Họ tên hoặc số điện thoại không hợp lệ.', 1;
        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không hợp lệ.', 1;
        IF @VaiTro = 'KTV' AND (@NhomTayNghe IS NULL OR @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA'))
            THROW 51009, N'KTV phải có đúng một chuyên môn hợp lệ.', 1;
        IF @NguoiDungId = @NguoiThucHienId AND (@VaiTro <> 'ADMIN' OR @DangHoatDong = 0)
            THROW 51009, N'Không được tự bỏ quyền hoặc khóa tài khoản quản trị đang dùng.', 1;
        IF (@VaiTroCu = 'ADMIN' AND (@VaiTro <> 'ADMIN' OR @DangHoatDong = 0))
           AND NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId)
            THROW 51009, N'Phải duy trì ít nhất một quản trị viên đang hoạt động.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId AND TrangThai NOT IN ('HoanThanh','Huy'))
            THROW 51009, N'KTV còn đơn đang thực hiện; cần xử lý trước khi khóa.', 1;
        IF @VaiTro <> 'KTV' AND EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.GiaoDichVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.YeuCauVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiDungId)
                THROW 51009, N'KTV đã có chứng từ; hãy giữ vai trò KTV hoặc khóa tài khoản.', 1;
            DELETE FROM dbo.KyThuatVien WHERE Id = @NguoiDungId;
        END;
        UPDATE dbo.NguoiDung
        SET HoTen = LTRIM(RTRIM(@HoTen)), SoDienThoai = @SoDienThoai,
            Email = NULLIF(LTRIM(RTRIM(@Email)), N''), VaiTro = @VaiTro, DangHoatDong = @DangHoatDong
        WHERE Id = @NguoiDungId;
        IF @VaiTro = 'KTV' AND NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
            INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe) VALUES (@NguoiDungId, @NhomTayNghe);
        ELSE IF @VaiTro = 'KTV'
            UPDATE dbo.KyThuatVien SET NhomTayNghe = @NhomTayNghe WHERE Id = @NguoiDungId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Cập nhật tài khoản', N'NguoiDung', @NguoiDungId, @VaiTro);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan
        FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_AdminCapNhatTaiKhoan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTho
    @NguoiThucHienId INT, @NhomTayNghe NVARCHAR(200), @KhuVucPhucVu NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatTho;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KTV') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')
            THROW 51009, N'Kỹ thuật viên chỉ được chọn một chuyên môn hợp lệ.', 1;

        UPDATE dbo.KyThuatVien SET NhomTayNghe = @NhomTayNghe, KhuVucPhucVu = @KhuVucPhucVu WHERE Id = @NguoiThucHienId;
        IF @@ROWCOUNT = 0 THROW 51004, N'Chưa có hồ sơ kỹ thuật viên.', 1;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatTho;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTrangThaiKTV
    @NguoiThucHienId INT, @TrangThaiSanSang VARCHAR(12), @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatTrangThaiKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KTV') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiThucHienId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiThucHienId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @TrangThaiSanSang NOT IN ('SanSang','TamBan')
            THROW 51009, N'Chỉ tự chuyển giữa sẵn sàng và tạm bận.', 1;
        IF EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51009, N'Đang có phân công; không được đổi trạng thái thủ công.', 1;
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = @TrangThaiSanSang WHERE Id = @NguoiThucHienId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatTrangThaiKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GuiHoSoKTV
    @NguoiThucHienId INT, @NhomTayNghe NVARCHAR(200), @KhuVucPhucVu NVARCHAR(200),
    @KinhNghiem NVARCHAR(2000),
    @HoSoJSON NVARCHAR(MAX) = NULL, @GiayToMatTruocId INT = NULL, @GiayToMatSauId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_GuiHoSoKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KH') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF EXISTS (SELECT 1 FROM dbo.HoSoKTV WITH (UPDLOCK, HOLDLOCK) WHERE NguoiDungId = @NguoiThucHienId AND TrangThai = 'Pending')
            THROW 51009, N'Đã có hồ sơ đang chờ duyệt.', 1;
        IF @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')
            THROW 51009, N'Kỹ thuật viên chỉ được chọn một chuyên môn hợp lệ.', 1;
        IF @HoSoJSON IS NOT NULL AND ISJSON(@HoSoJSON) <> 1
            THROW 51009, N'Nội dung hồ sơ phải là JSON hợp lệ.', 1;
        IF EXISTS (
            SELECT Id FROM (VALUES (@GiayToMatTruocId), (@GiayToMatSauId)) AS x(Id)
            WHERE Id IS NOT NULL AND NOT EXISTS (
                SELECT 1 FROM dbo.TepDinhKem AS t WHERE t.Id = x.Id
                AND t.ChuSoHuuId = @NguoiThucHienId AND t.MucDich = 'TechnicianDocument')
        ) THROW 51003, N'Ảnh giấy tờ phải thuộc người nộp hồ sơ.', 1;
        INSERT INTO dbo.HoSoKTV(NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, HoSoJSON, GiayToMatTruocId, GiayToMatSauId)
        VALUES (@NguoiThucHienId, @NhomTayNghe, @KhuVucPhucVu, @KinhNghiem, @HoSoJSON, @GiayToMatTruocId, @GiayToMatSauId);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, TrangThai, LyDo, NgayTao, PhienBan FROM dbo.vw_HoSoKTV WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_GuiHoSoKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetHoSoKTV
    @NguoiThucHienId INT, @HoSoId INT, @QuyetDinh VARCHAR(10), @PhienBanDuKien BINARY(8),
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DuyetHoSoKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WITH (UPDLOCK, HOLDLOCK) WHERE Id = @HoSoId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WHERE Id = @HoSoId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @QuyetDinh NOT IN ('Approved','Rejected') THROW 51009, N'Quyết định phải là Approved hoặc Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WHERE Id = @HoSoId AND TrangThai = 'Pending')
            THROW 51009, N'Hồ sơ đã được xử lý.', 1;
        DECLARE @NguoiDungId INT, @TayNghe NVARCHAR(200), @KhuVuc NVARCHAR(200);
        SELECT @NguoiDungId = NguoiDungId, @TayNghe = NhomTayNghe, @KhuVuc = KhuVucPhucVu FROM dbo.HoSoKTV WHERE Id = @HoSoId;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId AND VaiTro = 'KH' AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nộp hồ sơ đã bị khóa hoặc thay đổi vai trò.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            UPDATE dbo.NguoiDung SET VaiTro = 'KTV' WHERE Id = @NguoiDungId;
            INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe, KhuVucPhucVu)
            VALUES (@NguoiDungId, @TayNghe, @KhuVuc);
        END;
        UPDATE dbo.HoSoKTV SET TrangThai = @QuyetDinh, LyDo = @LyDo WHERE Id = @HoSoId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Duyệt hồ sơ thợ', N'HoSoKTV', @HoSoId, @QuyetDinh);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, TrangThai, LyDo, NgayTao, PhienBan FROM dbo.vw_HoSoKTV WHERE Id = @HoSoId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DuyetHoSoKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTepDinhKem
    @NguoiThucHienId INT, @DonHangId INT = NULL, @MucDich VARCHAR(25),
    @KhoaLuuTru VARCHAR(100), @TenTepGoc NVARCHAR(255), @KieuMIME VARCHAR(100), @KichThuoc INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuTepDinhKem;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        IF @KhoaLuuTru LIKE '%/%' OR @KhoaLuuTru LIKE '%\%' OR @KhoaLuuTru LIKE '%..%' OR LEN(@KhoaLuuTru) < 5
            THROW 51009, N'Khóa tệp không được chứa đường dẫn.', 1;
        IF @DonHangId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WHERE Id = @DonHangId)
                THROW 51004, N'Không tìm thấy đơn hàng của tệp.', 1;
            IF NOT EXISTS (
                SELECT 1 FROM dbo.DonHang AS dh INNER JOIN dbo.NguoiDung AS nd ON nd.Id = @NguoiThucHienId
                WHERE dh.Id = @DonHangId AND (dh.KhachHangId = @NguoiThucHienId OR dh.KyThuatVienId = @NguoiThucHienId OR nd.VaiTro IN ('DPV','CSKH','KT','ADMIN'))
            ) THROW 51003, N'Không được thêm tệp vào đơn của người khác.', 1;
        END;
        IF @MucDich IN ('MaterialEvidence','AcceptancePhoto','CustomerSignature','TechnicianSignature','PaymentProof') AND @DonHangId IS NULL
            THROW 51009, N'Tệp nghiệp vụ này cần gắn với đơn hàng.', 1;
        IF @MucDich IN ('CustomerSignature','TechnicianSignature') AND @KieuMIME NOT IN ('image/png','image/jpeg','image/webp')
            THROW 51009, N'Chữ ký phải là tệp ảnh.', 1;
        INSERT INTO dbo.TepDinhKem(ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc)
        VALUES (@NguoiThucHienId, @DonHangId, @MucDich, @KhoaLuuTru, @TenTepGoc, @KieuMIME, @KichThuoc);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc, NgayTao FROM dbo.vw_TepDinhKem WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuTepDinhKem;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DanhDauThongBao
    @NguoiThucHienId INT, @ThongBaoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DanhDauThongBao;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        UPDATE dbo.ThongBao SET DaDoc = 1 WHERE Id = @ThongBaoId AND NguoiDungId = @NguoiThucHienId;
        IF @@ROWCOUNT = 0 THROW 51004, N'Không tìm thấy thông báo của bạn.', 1;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, DonHangId, TieuDe, NoiDung, DaDoc, NgayTao FROM dbo.vw_ThongBao WHERE Id = @ThongBaoId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DanhDauThongBao;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuDichVu
    @NguoiThucHienId INT, @Id INT = NULL, @DanhMucId INT, @Ten NVARCHAR(180),
    @MoTa NVARCHAR(1000), @PhiKiemTra DECIMAL(18,2), @TienCong DECIMAL(18,2), @TyLeHoaHong DECIMAL(5,2),
    @DangHoatDong BIT = 1, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuDichVu;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF @DangHoatDong = 1 AND NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WHERE Id = @DanhMucId AND DangHoatDong = 1)
            THROW 51009, N'Danh mục chưa tồn tại hoặc đã ngừng hoạt động.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong)
            VALUES (@DanhMucId, @Ten, @MoTa, @PhiKiemTra, @TienCong, @TyLeHoaHong, @DangHoatDong);
            SET @Id = CONVERT(INT, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DichVu WHERE Id = @Id AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

            UPDATE dbo.DichVu SET DanhMucId = @DanhMucId, Ten = @Ten, MoTa = @MoTa, PhiKiemTra = @PhiKiemTra,
                TienCong = @TienCong, TyLeHoaHong = @TyLeHoaHong, DangHoatDong = @DangHoatDong WHERE Id = @Id;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu dịch vụ', N'DichVu', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong, PhienBan FROM dbo.vw_DichVu WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuDichVu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuDanhMucDichVu
    @NguoiThucHienId INT, @Id INT = NULL, @Ten NVARCHAR(100), @Ma VARCHAR(30),
    @DangHoatDong BIT = 1, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuDanhMucDichVu;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF NULLIF(LTRIM(RTRIM(@Ten)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Ma)), '') IS NULL
            THROW 51009, N'Tên và mã danh mục không được để trống.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.DanhMucDichVu(Ten, Ma, DangHoatDong) VALUES (@Ten, @Ma, @DangHoatDong);
            SET @Id = CONVERT(INT, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WHERE Id = @Id AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

            UPDATE dbo.DanhMucDichVu SET Ten = @Ten, Ma = @Ma, DangHoatDong = @DangHoatDong WHERE Id = @Id;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu danh mục dịch vụ', N'DanhMucDichVu', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, Ten, Ma, DangHoatDong, PhienBan FROM dbo.vw_DanhMucDichVu WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuDanhMucDichVu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuCauHinh
    @NguoiThucHienId INT, @Khoa VARCHAR(80), @GiaTri NVARCHAR(1000), @NhanHienThi NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuCauHinh;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF @Khoa = 'TyLeHoaHongMacDinh' AND (TRY_CONVERT(DECIMAL(5,2), @GiaTri) IS NULL OR TRY_CONVERT(DECIMAL(5,2), @GiaTri) NOT BETWEEN 0 AND 100)
            THROW 51009, N'Tỷ lệ hoa hồng phải từ 0 đến 100 phần trăm.', 1;
        IF @Khoa = 'PhiHuyDon' AND (TRY_CONVERT(DECIMAL(18,2), @GiaTri) IS NULL OR TRY_CONVERT(DECIMAL(18,2), @GiaTri) NOT BETWEEN 1000 AND 1000000)
            THROW 51009, N'Phí hủy đơn phải từ 1000 đến 1000000 đồng.', 1;
        IF @Khoa = 'TaiKhoanNganHangMacDinh' AND NOT EXISTS (
            SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = TRY_CONVERT(INT, @GiaTri) AND DangHoatDong = 1
        ) THROW 51009, N'Tài khoản ngân hàng mặc định phải đang hoạt động.', 1;
        IF @Khoa LIKE 'DeXuatChinhSach[_]%'
        BEGIN
            IF ISJSON(@GiaTri) <> 1
                THROW 51009, N'Đề xuất chính sách không hợp lệ.', 1;
            DECLARE @DoiTuongDeXuat VARCHAR(100) = JSON_VALUE(@GiaTri, '$.policySubject');
            IF NULLIF(@DoiTuongDeXuat, '') IS NULL
                THROW 51009, N'Đề xuất chính sách không hợp lệ.', 1;
            -- Bản gửi lại thay thế bằng cách xóa hẳn bản đang chờ cùng đối tượng,
            -- sau đó chèn đề xuất mới với khóa/mã mới.
            DELETE FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK)
            WHERE Khoa LIKE 'DeXuatChinhSach[_]%'
              AND ISJSON(GiaTri) = 1
              AND COALESCE(
                    JSON_VALUE(GiaTri, '$.policySubject'),
                    CASE JSON_VALUE(GiaTri, '$.payload.type')
                        WHEN 'ServicePricing' THEN CONCAT('DichVu_', JSON_VALUE(GiaTri, '$.payload.serviceId'))
                        WHEN 'Configuration' THEN CONCAT('CauHinh_', JSON_VALUE(GiaTri, '$.payload.key'))
                    END
                  ) = @DoiTuongDeXuat;
        END;
        IF EXISTS (SELECT 1 FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa)
            UPDATE dbo.CauHinh SET GiaTri = @GiaTri, NhanHienThi = @NhanHienThi WHERE Khoa = @Khoa;
        ELSE INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES (@Khoa, @GiaTri, @NhanHienThi);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, ChiTiet)
        VALUES (@NguoiThucHienId, N'Lưu cấu hình', N'CauHinh', @Khoa);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Khoa, GiaTri, NhanHienThi FROM dbo.vw_CauHinh WHERE Khoa = @Khoa;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuCauHinh;
        THROW;
    END CATCH;
END;
GO


GO

-- MODULE: 05_transaction.sql
-- Nghiep vu HomeFix: chi goi thu tuc; khong sua bang truc tiep tu ung dung.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDonHang
    @NguoiThucHienId INT,
    @DichVuId INT,
    @DiaChi NVARCHAR(500),
    @MoTa NVARCHAR(2000),
    @NgayHen DATETIME2 = NULL,
    @TepDinhKem NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoDonHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF NULLIF(LTRIM(RTRIM(@DiaChi)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@MoTa)), N'') IS NULL
            THROW 51009, N'Can nhap dia chi va mo ta su co.', 1;
        IF @NgayHen IS NOT NULL AND @NgayHen < SYSUTCDATETIME()
            THROW 51009, N'Ngay hen phai la thoi diem trong tuong lai (UTC).', 1;
        DECLARE @TenDichVu NVARCHAR(200);
        SELECT @TenDichVu = dv.Ten
        FROM dbo.DichVu AS dv WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
        WHERE dv.Id = @DichVuId AND dv.DangHoatDong = 1 AND dm.DangHoatDong = 1;
        IF @TenDichVu IS NULL
            THROW 51004, N'Dich vu khong ton tai hoac da tam ngung.', 1;
        IF @TepDinhKem IS NOT NULL
        BEGIN
            IF ISJSON(@TepDinhKem) <> 1 OR LEFT(LTRIM(@TepDinhKem), 1) <> '['
                THROW 51009, N'Danh sách ảnh không hợp lệ.', 1;
            IF EXISTS (
                SELECT 1 FROM OPENJSON(@TepDinhKem) AS j
                LEFT JOIN dbo.TepDinhKem AS t WITH (UPDLOCK, HOLDLOCK) ON t.Id = TRY_CONVERT(INT, j.value)
                WHERE t.Id IS NULL OR t.ChuSoHuuId <> @NguoiThucHienId
                   OR t.MucDich <> 'OrderFault' OR t.DonHangId IS NOT NULL
            ) THROW 51003, N'Ảnh sự cố phải thuộc khách hàng và chưa gắn đơn khác.', 1;
        END;
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen)
        VALUES (@NguoiThucHienId, @DichVuId, @TenDichVu, LTRIM(RTRIM(@DiaChi)), @MoTa, @NgayHen);
        DECLARE @Id INT = SCOPE_IDENTITY();
        UPDATE dbo.TepDinhKem SET DonHangId = @Id
        WHERE Id IN (SELECT TRY_CONVERT(INT, value) FROM OPENJSON(@TepDinhKem));
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@Id, NULL, 'ChoTiepNhan', @NguoiThucHienId, N'Khach hang tao yeu cau dich vu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen, TrangThai, KyThuatVienId, NgayTao, NgayCapNhat, PhienBan
        FROM dbo.DonHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDonHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoBaoGiaSoBo
    @NguoiThucHienId INT,
    @DonHangId INT,
    @PhiKiemTra DECIMAL(18,2),
    @TienCong DECIMAL(18,2),
    @TyLeHoaHong DECIMAL(5,2),
    @ChanDoan NVARCHAR(2000),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoBaoGiaSoBo;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @PhienBan BINARY(8), @Id INT;
        SELECT @TrangThai = TrangThai, @PhienBan = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThai NOT IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong')
            THROW 51009, N'Chỉ được điều chỉnh báo giá trước khi phân công kỹ thuật viên.', 1;
        IF @PhiKiemTra IS NULL OR @TienCong IS NULL OR @TyLeHoaHong IS NULL
           OR @PhiKiemTra NOT BETWEEN 0 AND 1000000000 OR @TienCong NOT BETWEEN 0 AND 1000000000
           OR @PhiKiemTra + @TienCong <= 0
           OR @TyLeHoaHong < 0 OR @TyLeHoaHong > 100
           OR NULLIF(LTRIM(RTRIM(@ChanDoan)), N'') IS NULL OR LEN(@ChanDoan) > 1000
            THROW 51009, N'Bao gia, chan doan hoac ty le hoa hong khong hop le.', 1;
        SELECT @Id = Id FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.BaoGiaSoBo (DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, ChanDoan, TrangThai)
            VALUES (@DonHangId, @PhiKiemTra, @TienCong, @TyLeHoaHong, @ChanDoan, 'Pending');
            SET @Id = SCOPE_IDENTITY();
        END
        ELSE
            UPDATE dbo.BaoGiaSoBo
            SET PhiKiemTra = @PhiKiemTra, TienCong = @TienCong, TyLeHoaHong = @TyLeHoaHong,
                ChanDoan = @ChanDoan, TrangThai = 'Pending', NgayTao = SYSUTCDATETIME()
            WHERE Id = @Id;
        UPDATE dbo.DonHang SET TrangThai = 'ChoDuyetSoBo', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoDuyetSoBo', @NguoiThucHienId,
            CASE WHEN @TrangThai = 'ChoTiepNhan' THEN N'Gửi báo giá sơ bộ cho khách hàng.'
                 ELSE N'Điều chỉnh báo giá sơ bộ; khách hàng cần duyệt lại.' END);
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, ChanDoan, TrangThai, TongTien, NgayTao, PhienBan
        FROM dbo.BaoGiaSoBo
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoBaoGiaSoBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachDuyetBaoGiaSoBo
    @NguoiThucHienId INT,
    @BaoGiaId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KhachDuyetBaoGiaSoBo;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @ChuSoHuuId INT, @TrangThai VARCHAR(30), @PhienBan BINARY(8);
        SELECT @DonHangId = DonHangId FROM dbo.BaoGiaSoBo WHERE Id = @BaoGiaId;
        IF @DonHangId IS NULL THROW 51004, N'Khong tim thay bao gia.', 1;
        -- Khóa đơn trước rồi khóa báo giá, cùng thứ tự với thủ tục điều chỉnh.
        SELECT @ChuSoHuuId = KhachHangId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND TrangThai = 'ChoDuyetSoBo';
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE Id = @BaoGiaId;
        IF @ChuSoHuuId IS NULL THROW 51009, N'Don hang khong con cho duyet bao gia.', 1;
        IF @ChuSoHuuId <> @NguoiThucHienId THROW 51003, N'Chi chu don hang duoc duyet bao gia.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Bao gia da thay doi hoac da duoc xu ly.', 1;
        IF @QuyetDinh NOT IN ('Approved', 'Rejected') OR @QuyetDinh IS NULL
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        DECLARE @TrangThaiMoi VARCHAR(30) = CASE WHEN @QuyetDinh = 'Approved' THEN 'ChoPhanCong' ELSE 'ChoTiepNhan' END;
        UPDATE dbo.BaoGiaSoBo SET TrangThai = @QuyetDinh WHERE Id = @BaoGiaId;
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiMoi, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoDuyetSoBo', @TrangThaiMoi, @NguoiThucHienId, COALESCE(@LyDo, N'Khach hang phan hoi bao gia.'));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, PhienBan
        FROM dbo.BaoGiaSoBo
        WHERE Id = @BaoGiaId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachDuyetBaoGiaSoBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoLenhDieuPhoi
    @NguoiThucHienId INT,
    @DonHangId INT,
    @KyThuatVienId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoLenhDieuPhoi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(30), @SanSang VARCHAR(20), @Id INT;
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThai <> 'ChoPhanCong' OR NOT EXISTS (
            SELECT 1 FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved')
            THROW 51009, N'Don phai duoc khach duyet bao gia truoc khi phan cong.', 1;
        SELECT @SanSang = ktv.TrangThaiSanSang
        FROM dbo.KyThuatVien AS ktv WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id
        WHERE ktv.Id = @KyThuatVienId AND nd.DangHoatDong = 1 AND nd.VaiTro = 'KTV';
        IF @SanSang IS NULL THROW 51004, N'Ky thuat vien khong ton tai hoac da bi khoa.', 1;
        IF @SanSang <> 'SanSang' OR EXISTS (
            SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @KyThuatVienId AND DangHoatDong = 1)
            THROW 51009, N'Ky thuat vien chua san sang hoac dang co don.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.fn_KyThuatVienPhuHop(@DonHangId) WHERE Id = @KyThuatVienId)
            THROW 51009, N'Thợ phải đúng tay nghề, khu vực, đang sẵn sàng và không giữ đơn khác.', 1;
        INSERT INTO dbo.LenhDieuPhoi (DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId)
        VALUES (@DonHangId, @KyThuatVienId, 'Pending', 1, @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'DangBan' WHERE Id = @KyThuatVienId;
        UPDATE dbo.DonHang SET KyThuatVienId = @KyThuatVienId, TrangThai = 'ChoNhan', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNhan', @NguoiThucHienId, N'Dieu phoi gui lenh phan cong.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.LenhDieuPhoi
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoLenhDieuPhoi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KTVPhanHoiDieuPhoi
    @NguoiThucHienId INT,
    @LenhDieuPhoiId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KTVPhanHoiDieuPhoi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @KTVId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT;
        SELECT @DonHangId = DonHangId, @KTVId = KyThuatVienId, @PhienBan = PhienBan,
               @TrangThai = TrangThai, @HoatDong = DangHoatDong
        FROM dbo.LenhDieuPhoi WITH (UPDLOCK, HOLDLOCK) WHERE Id = @LenhDieuPhoiId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay lenh dieu phoi.', 1;
        IF @KTVId <> @NguoiThucHienId THROW 51003, N'Lenh dieu phoi khong thuoc ky thuat vien nay.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @HoatDong <> 1
            THROW 51009, N'Lenh da thay doi hoac da duoc phan hoi.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Accepted', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Accepted hoac Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND TrangThai = 'ChoNhan' AND KyThuatVienId = @KTVId)
            THROW 51009, N'Don hang khong con cho ky thuat vien phan hoi.', 1;
        DECLARE @TrangThaiMoi VARCHAR(30) = CASE WHEN @QuyetDinh = 'Accepted' THEN 'DaTiepNhan' ELSE 'ChoPhanCong' END;
        UPDATE dbo.LenhDieuPhoi
        SET TrangThai = @QuyetDinh, DangHoatDong = CASE WHEN @QuyetDinh = 'Accepted' THEN 1 ELSE 0 END
        WHERE Id = @LenhDieuPhoiId;
        UPDATE dbo.DonHang
        SET TrangThai = @TrangThaiMoi,
            KyThuatVienId = CASE WHEN @QuyetDinh = 'Accepted' THEN @KTVId ELSE NULL END,
            NgayCapNhat = SYSUTCDATETIME()
        WHERE Id = @DonHangId;
        IF @QuyetDinh = 'Rejected'
            UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoNhan', @TrangThaiMoi, @NguoiThucHienId, COALESCE(@LyDo, N'Ky thuat vien phan hoi dieu phoi.'));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, PhienBan
        FROM dbo.LenhDieuPhoi
        WHERE Id = @LenhDieuPhoiId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KTVPhanHoiDieuPhoi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ChuyenTrangThaiDon
    @NguoiThucHienId INT,
    @DonHangId INT,
    @TrangThaiTiepTheo VARCHAR(30),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL,
    @DongYPhiHuy BIT = 0,
    @PhiHuyDuKien DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ChuyenTrangThaiDon;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'KTV', 'DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @KhachHangId INT, @KTVId INT, @PhienBan BINARY(8);
        SELECT @TrangThai = TrangThai, @KhachHangId = KhachHangId,
               @KTVId = KyThuatVienId, @PhienBan = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThaiTiepTheo IS NULL
            THROW 51009, N'Can chi dinh trang thai tiep theo.', 1;
        DECLARE @PhiHuy DECIMAL(18,2) = 0;
        IF @TrangThaiTiepTheo = 'Huy'
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
                THROW 51009, N'Phai nhap ly do huy don.', 1;
            IF NOT ((@VaiTro = 'KH' AND @KhachHangId = @NguoiThucHienId
                    AND @TrangThai IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi'))
                OR (@VaiTro IN ('DPV', 'ADMIN') AND @TrangThai IN
                    ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi')))
                THROW 51003, N'Khong duoc huy don tai trang thai hien tai.', 1;
            IF @TrangThai IN ('DangDiChuyen', 'DaDenNoi')
            BEGIN
                SELECT @PhiHuy = TRY_CONVERT(DECIMAL(18,2), GiaTri) FROM dbo.CauHinh WITH (HOLDLOCK) WHERE Khoa = 'PhiHuyDon';
                IF @PhiHuy IS NULL OR @PhiHuy NOT BETWEEN 1000 AND 1000000
                    THROW 51009, N'Cấu hình phí hủy đơn không hợp lệ.', 1;
                IF ISNULL(@DongYPhiHuy, 0) <> 1 OR @PhiHuyDuKien IS NULL OR @PhiHuyDuKien <> @PhiHuy
                    THROW 51009, N'KTV đã di chuyển. Cần xác nhận đúng phí hủy trước khi thực hiện.', 1;
            END;
            UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
            IF @KTVId IS NOT NULL
                UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        END
        ELSE
        BEGIN
            IF @VaiTro <> 'KTV' OR @KTVId IS NULL OR @KTVId <> @NguoiThucHienId
                THROW 51003, N'Chi ky thuat vien duoc phan cong duoc cap nhat tien do.', 1;
            IF NOT ((@TrangThai = 'DaTiepNhan' AND @TrangThaiTiepTheo = 'DangDiChuyen')
                OR (@TrangThai = 'DangDiChuyen' AND @TrangThaiTiepTheo = 'DaDenNoi')
                OR (@TrangThai = 'DaDenNoi' AND @TrangThaiTiepTheo = 'DangXuLy'))
                THROW 51009, N'Thu tu chuyen trang thai khong hop le. Bao gia va thanh toan co thu tuc rieng.', 1;
        END;
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiTiepTheo, PhiHuyDon = @PhiHuy, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, @TrangThaiTiepTheo, @NguoiThucHienId, COALESCE(@LyDo, N'Cap nhat tien do thi cong.'));
        DECLARE @Id INT = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen, TrangThai, PhiHuyDon, KyThuatVienId, NgayTao, NgayCapNhat, PhienBan
        FROM dbo.DonHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ChuyenTrangThaiDon;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemGhiChuDon
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NoiDung NVARCHAR(2000),
    @NoiBo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ThemGhiChuDon;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'KTV', 'DPV', 'CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KhachHangId INT, @KTVId INT, @Id INT;
        SELECT @KhachHangId = KhachHangId, @KTVId = KyThuatVienId FROM dbo.DonHang WITH (HOLDLOCK) WHERE Id = @DonHangId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF (@VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId)
           OR (@VaiTro = 'KTV' AND (@KTVId IS NULL OR @KTVId <> @NguoiThucHienId))
            THROW 51003, N'Khong duoc ghi chu tren don cua nguoi khac.', 1;
        IF @NoiBo IS NULL THROW 51009, N'Can xac dinh ghi chu noi bo hay cong khai.', 1;
        IF @VaiTro = 'KH' AND @NoiBo = 1 THROW 51003, N'Khach hang khong duoc tao ghi chu noi bo.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung ghi chu khong duoc rong.', 1;
        INSERT INTO dbo.GhiChuDon (DonHangId, NguoiVietId, NoiDung, NoiBo)
        VALUES (@DonHangId, @NguoiThucHienId, @NoiDung, @NoiBo);
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NguoiVietId, NoiDung, NoiBo, NgayTao
        FROM dbo.GhiChuDon
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemGhiChuDon;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuBangKeVatTu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @VatTu NVARCHAR(MAX),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_LuuBangKeVatTu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @Id INT, @LanSuaDoi INT;
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc ke khai vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'DangXuLy'
            THROW 51009, N'Don hang da thay doi hoac khong dang xu ly.', 1;
        IF ISJSON(@VatTu) <> 1 OR LEFT(LTRIM(@VatTu), 1) <> '[' OR @VatTu IS NULL
            THROW 51009, N'VatTu phai la mang JSON chua danh sach vat tu.', 1;
        IF (SELECT COUNT(*) FROM OPENJSON(@VatTu)) NOT BETWEEN 1 AND 50
            THROW 51009, N'Can tu 1 den 50 dong vat tu.', 1;
        IF EXISTS (SELECT 1 FROM OPENJSON(@VatTu) WHERE [type] <> 5)
            THROW 51009, N'Moi dong vat tu phai la mot doi tuong JSON.', 1;
        IF EXISTS (
            SELECT 1 FROM OPENJSON(@VatTu) AS j
            WHERE j.[type] <> 5
               OR NULLIF(LTRIM(RTRIM(JSON_VALUE(j.[value], '$.Ten'))), N'') IS NULL
               OR LEN(JSON_VALUE(j.[value], '$.Ten')) > 200
               OR TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(j.[value], '$.SoLuong')) IS NULL
               OR TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(j.[value], '$.SoLuong')) NOT BETWEEN 0.01 AND 1000
               OR TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(j.[value], '$.DonGia')) IS NULL
               OR TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(j.[value], '$.DonGia')) NOT BETWEEN 0 AND 1000000000
               OR (JSON_VALUE(j.[value], '$.SoThangBaoHanh') IS NOT NULL AND
                  (TRY_CONVERT(INT, JSON_VALUE(j.[value], '$.SoThangBaoHanh')) IS NULL OR
                   TRY_CONVERT(INT, JSON_VALUE(j.[value], '$.SoThangBaoHanh')) NOT BETWEEN 0 AND 120)))
            THROW 51009, N'Vat tu sai ten, so luong, don gia hoac thang bao hanh.', 1;
        SELECT @LanSuaDoi = ISNULL(MAX(LanSuaDoi), 0) + 1
        FROM dbo.BangKeVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        UPDATE dbo.BangKeVatTu SET DangApDung = 0 WHERE DonHangId = @DonHangId AND DangApDung = 1;
        INSERT INTO dbo.BangKeVatTu (DonHangId, LanSuaDoi, DangApDung, NguoiTaoId)
        VALUES (@DonHangId, @LanSuaDoi, 1, @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.ChiTietVatTu (BangKeVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        SELECT @Id, LTRIM(RTRIM(v.Ten)), v.SoLuong, v.DonGia, ISNULL(v.SoThangBaoHanh, 0)
        FROM OPENJSON(@VatTu) WITH (
            Ten NVARCHAR(200) '$.Ten', SoLuong DECIMAL(10,2) '$.SoLuong',
            DonGia DECIMAL(18,2) '$.DonGia', SoThangBaoHanh INT '$.SoThangBaoHanh') AS v;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.BangKeVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuBangKeVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoPhieuNghiemThu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NguyenNhan NVARCHAR(2000),
    @PhuongAnXuLy NVARCHAR(2000),
    @PhienBanDuKien BINARY(8) = NULL,
    @ChuKyKTVId INT = NULL,
    @AnhThanhPham NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoPhieuNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @Id INT;
        DECLARE @BangKeId INT, @TienVatTu DECIMAL(18,2) = 0;
        DECLARE @PhiKiemTra DECIMAL(18,2), @TienCong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc lap nghiem thu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'DangXuLy'
            THROW 51009, N'Don hang da thay doi hoac khong dang xu ly.', 1;
        IF NULLIF(LTRIM(RTRIM(@NguyenNhan)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@PhuongAnXuLy)), N'') IS NULL
            THROW 51009, N'Can nhap nguyen nhan va phuong an xu ly.', 1;
        SELECT @PhiKiemTra = PhiKiemTra, @TienCong = TienCong
        FROM dbo.BaoGiaSoBo WITH (HOLDLOCK) WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        IF @TienCong IS NULL THROW 51009, N'Chua co bao gia duoc khach hang chap nhan.', 1;
        -- Vat tu da trao doi truc tiep voi khach, duoc tong hop vao phieu nghiem thu.
        SELECT @BangKeId = Id
        FROM dbo.BangKeVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND DangApDung = 1;
        SELECT @TienVatTu = ISNULL(SUM(ThanhTien), 0)
        FROM dbo.ChiTietVatTu WITH (HOLDLOCK) WHERE BangKeVatTuId = @BangKeId;
        IF EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Don hang da co phieu nghiem thu hien hanh.', 1;
        INSERT INTO dbo.PhieuNghiemThu (DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TrangThai)
        VALUES (@DonHangId, @KTVId, @BangKeId, @NguyenNhan, @PhuongAnXuLy, @PhiKiemTra, @TienCong, @TienVatTu, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        -- Web gửi chữ ký và ảnh trong cùng giao dịch tạo phiếu.
        IF @AnhThanhPham IS NOT NULL
        BEGIN
            IF ISJSON(@AnhThanhPham) <> 1 OR LEFT(LTRIM(@AnhThanhPham), 1) <> '['
                THROW 51009, N'Danh sách ảnh thành phẩm không hợp lệ.', 1;
            IF EXISTS (
                SELECT 1 FROM OPENJSON(@AnhThanhPham) AS j
                LEFT JOIN dbo.TepDinhKem AS t ON t.Id = TRY_CONVERT(INT, j.value)
                WHERE t.Id IS NULL OR t.ChuSoHuuId <> @NguoiThucHienId
                   OR t.DonHangId <> @DonHangId OR t.DonHangId IS NULL OR t.MucDich <> 'AcceptancePhoto'
            ) THROW 51003, N'Ảnh thành phẩm không thuộc thợ hoặc đơn hàng.', 1;
        END;
        IF @ChuKyKTVId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyKTVId
                AND ChuSoHuuId = @NguoiThucHienId AND DonHangId = @DonHangId AND MucDich = 'TechnicianSignature')
                THROW 51003, N'Chữ ký thợ không hợp lệ.', 1;
            UPDATE dbo.PhieuNghiemThu SET ChuKyKTVId = @ChuKyKTVId WHERE Id = @Id;
        END;
        UPDATE dbo.DonHang SET TrangThai = 'ChoNghiemThu', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNghiemThu', @NguoiThucHienId, N'Ky thuat vien lap phieu nghiem thu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoPhieuNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KTVKyNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT,
    @ChuKyId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KTVKyNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @KTVId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @ChuKyCu INT;
        SELECT @DonHangId = DonHangId, @KTVId = KyThuatVienId, @PhienBan = PhienBan,
               @TrangThai = TrangThai, @ChuKyCu = ChuKyKTVId
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NghiemThuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay phieu nghiem thu.', 1;
        IF @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua phieu duoc ky.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @ChuKyCu IS NOT NULL
            THROW 51009, N'Phieu da thay doi hoac ky thuat vien da ky.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'TechnicianSignature' AND KieuMIME IN ('image/png', 'image/jpeg'))
            THROW 51009, N'Tep chu ky ky thuat vien khong hop le.', 1;
        UPDATE dbo.PhieuNghiemThu SET ChuKyKTVId = @ChuKyId WHERE Id = @NghiemThuId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @NghiemThuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KTVKyNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachHangKyNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT,
    @ChuKyId INT,
    @PhuongThucThanhToan VARCHAR(10),
    @PhienBanDuKien BINARY(8) = NULL,
    @TaiKhoanNganHangId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KhachHangKyNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @ChuKyKTVId INT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @ChuKyKTVId = ChuKyKTVId
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NghiemThuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay phieu nghiem thu.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'ChoNghiemThu')
            THROW 51003, N'Chi khach hang cua don cho nghiem thu duoc ky.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @ChuKyKTVId IS NULL
            THROW 51009, N'Phieu da thay doi hoac ky thuat vien chua ky.', 1;
        IF @PhuongThucThanhToan IS NULL OR @PhuongThucThanhToan NOT IN ('COD', 'BANK')
            THROW 51009, N'Phuong thuc thanh toan phai la COD hoac BANK.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'CustomerSignature' AND KieuMIME IN ('image/png', 'image/jpeg'))
            THROW 51009, N'Tep chu ky khach hang khong hop le.', 1;
        IF @TaiKhoanNganHangId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nhận tiền đã ngừng hoạt động.', 1;
        UPDATE dbo.PhieuNghiemThu
        SET ChuKyKHId = @ChuKyId, PhuongThucThanhToan = @PhuongThucThanhToan, TaiKhoanNganHangId = CASE WHEN @PhuongThucThanhToan = 'BANK' THEN @TaiKhoanNganHangId END,
            TrangThai = 'Approved', NgayDuyet = SYSUTCDATETIME()
        WHERE Id = @NghiemThuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, NgayDuyet, TongTien, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @NghiemThuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachHangKyNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacNhanThanhToanCOD
    @NguoiThucHienId INT,
    @DonHangId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XacNhanThanhToanCOD;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @NghiemThuId INT;
        DECLARE @SoTien DECIMAL(18,2), @TienCong DECIMAL(18,2), @TyLeHoaHong DECIMAL(5,2), @Id INT;
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc xac nhan thu COD.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'ChoNghiemThu'
            THROW 51009, N'Don hang da thay doi hoac da thanh toan.', 1;
        SELECT @NghiemThuId = Id, @SoTien = TongTien, @TienCong = TienCong
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'COD'
              AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
        IF @NghiemThuId IS NULL THROW 51009, N'Chua co nghiem thu du hai chu ky va chon COD.', 1;
        IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId)
            THROW 51009, N'Don hang da duoc ghi nhan thanh toan.', 1;
        SELECT @TyLeHoaHong = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        INSERT INTO dbo.ThanhToan (DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId)
        VALUES (@DonHangId, @NghiemThuId, @SoTien, 'COD', @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
        VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLeHoaHong, 'Pending');
        UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'HoanThanh', @NguoiThucHienId, N'Ky thuat vien da thu du tien mat COD.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, NgayTao
        FROM dbo.ThanhToan
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XacNhanThanhToanCOD;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauThanhToan
    @NguoiThucHienId INT,
    @DonHangId INT,
    @TaiKhoanNganHangId INT,
    @ChungTuId INT,
    @MaThamChieu NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauThanhToan;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @NghiemThuId INT, @SoTien DECIMAL(18,2), @Id INT, @TrangThaiDon VARCHAR(20), @Loai VARCHAR(12) = 'DichVu';
        SELECT @TrangThaiDon = TrangThai, @SoTien = PhiHuyDon
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId;
        IF @TrangThaiDon IS NULL THROW 51003, N'Chỉ chủ đơn hàng được gửi chứng từ.', 1;
        IF @TrangThaiDon = 'Huy' AND @SoTien > 0
            SET @Loai = 'PhiHuyDon';
        ELSE
        BEGIN
            IF @TrangThaiDon <> 'ChoNghiemThu' THROW 51009, N'Đơn không còn khoản phải thanh toán.', 1;
            SELECT @NghiemThuId = Id, @SoTien = TongTien FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
            WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
            IF @NghiemThuId IS NULL THROW 51009, N'Chưa có nghiệm thu đủ chữ ký và chọn chuyển khoản.', 1;
        END;
        IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId)
           OR EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WHERE DonHangId = @DonHangId AND TrangThai = 'Pending')
            THROW 51009, N'Don da thanh toan hoac da co yeu cau dang cho.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang WITH (HOLDLOCK) WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tai khoan nhan tien khong hop le.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChungTuId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'PaymentProof')
            THROW 51009, N'Chung tu thanh toan khong thuoc don hang nay.', 1;
        IF NULLIF(LTRIM(RTRIM(@MaThamChieu)), N'') IS NULL
            THROW 51009, N'Can nhap ma tham chieu giao dich ngan hang.', 1;
        INSERT INTO dbo.YeuCauThanhToan (DonHangId, LoaiThanhToan, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai)
        VALUES (@DonHangId, @Loai, @NghiemThuId, @NguoiThucHienId, @TaiKhoanNganHangId, @SoTien, @ChungTuId, LTRIM(RTRIM(@MaThamChieu)), 'Pending');
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NghiemThuId, SoTien, ChungTuId, MaThamChieu, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauThanhToan
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauThanhToan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacNhanThanhToanNganHang
    @NguoiThucHienId INT,
    @YeuCauThanhToanId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @SoTienThucNhan DECIMAL(18,2) = NULL,
    @MaThamChieu NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XacNhanThanhToanNganHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @NghiemThuId INT, @TaiKhoanId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20);
        DECLARE @SoTien DECIMAL(18,2), @ThamChieu NVARCHAR(100), @KTVId INT, @TienCong DECIMAL(18,2), @TyLe DECIMAL(5,2), @Id INT;
        DECLARE @Loai VARCHAR(12), @TrangThaiDon VARCHAR(20), @PhiHuy DECIMAL(18,2);
        SELECT @Loai = LoaiThanhToan, @DonHangId = DonHangId, @NghiemThuId = NghiemThuId, @TaiKhoanId = TaiKhoanNganHangId,
               @PhienBan = PhienBan, @TrangThai = TrangThai, @SoTien = SoTien, @ThamChieu = MaThamChieu
        FROM dbo.YeuCauThanhToan WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauThanhToanId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau thanh toan.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Yeu cau da thay doi hoac da duoc xu ly.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Confirmed', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Confirmed hoac Rejected.', 1;
        IF @QuyetDinh = 'Confirmed'
        BEGIN
            IF @SoTienThucNhan IS NULL OR @SoTienThucNhan <> @SoTien
                THROW 51009, N'So tien thuc nhan phai bang tong tien can thanh toan.', 1;
            SET @ThamChieu = COALESCE(NULLIF(LTRIM(RTRIM(@MaThamChieu)), N''), @ThamChieu);
            IF NULLIF(@ThamChieu, N'') IS NULL THROW 51009, N'Can ma tham chieu ngan hang.', 1;
            SELECT @KTVId = KyThuatVienId, @TrangThaiDon = TrangThai, @PhiHuy = PhiHuyDon
            FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
            IF @KTVId IS NULL THROW 51009, N'Đơn chưa có kỹ thuật viên.', 1;
            IF @Loai = 'PhiHuyDon'
            BEGIN
                IF @TrangThaiDon <> 'Huy' OR @PhiHuy <> @SoTien OR @PhiHuy <= 0 OR @NghiemThuId IS NOT NULL
                    THROW 51009, N'Khoản phí hủy không khớp đơn đã hủy.', 1;
                SET @TienCong = 0;
                SET @TyLe = 0; -- Phí di chuyển chuyển đủ cho KTV, không trừ hoa hồng.
            END
            ELSE
            BEGIN
                IF @TrangThaiDon <> 'ChoNghiemThu' THROW 51009, N'Đơn không còn chờ thanh toán.', 1;
                SELECT @TienCong = TienCong FROM dbo.PhieuNghiemThu WITH (HOLDLOCK)
                WHERE Id = @NghiemThuId AND DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                    AND TongTien = @SoTien AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
                IF @TienCong IS NULL THROW 51009, N'Nghiệm thu không hợp lệ.', 1;
                SELECT @TyLe = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
            END;
            IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId OR MaThamChieu = @ThamChieu)
                THROW 51009, N'Don hoac ma tham chieu nay da duoc thanh toan.', 1;
            INSERT INTO dbo.ThanhToan (DonHangId, LoaiThanhToan, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId)
            VALUES (@DonHangId, @Loai, @NghiemThuId, @SoTien, 'BANK', @NguoiThucHienId, @ThamChieu, @TaiKhoanId);
            SET @Id = SCOPE_IDENTITY();
            INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
            VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLe, 'Pending');
            IF @Loai = 'DichVu'
            BEGIN
                UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
                UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
                UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
                INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
                VALUES (@DonHangId, 'ChoNghiemThu', 'HoanThanh', @NguoiThucHienId, N'Ke toan xac nhan da nhan du chuyen khoan.');
            END;
        END;
        UPDATE dbo.YeuCauThanhToan SET TrangThai = @QuyetDinh, MaThamChieu = @ThamChieu WHERE Id = @YeuCauThanhToanId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, SoTien, MaThamChieu, TrangThai, PhienBan
        FROM dbo.YeuCauThanhToan
        WHERE Id = @YeuCauThanhToanId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XacNhanThanhToanNganHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiSoatCOD
    @NguoiThucHienId INT,
    @DoiSoatId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_DoiSoatCOD;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(20), @KTVId INT, @ThanhToanId INT;
        DECLARE @TienHoaHong DECIMAL(18,2), @SoTien DECIMAL(18,2), @PhuongThuc VARCHAR(10), @BienDong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai, @KTVId = KyThuatVienId,
               @ThanhToanId = ThanhToanId, @TienHoaHong = TienHoaHong
        FROM dbo.DoiSoat WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DoiSoatId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay doi soat.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Doi soat da thay doi hoac da duoc xac nhan.', 1;
        DECLARE @LoaiThanhToan VARCHAR(12);
        SELECT @LoaiThanhToan = LoaiThanhToan, @SoTien = SoTien, @PhuongThuc = PhuongThuc FROM dbo.ThanhToan WHERE Id = @ThanhToanId;
        -- COD: tho giu tien mat, tru hoa hong trong vi. BANK: cong tien tho duoc huong.
        SET @BienDong = CASE WHEN @PhuongThuc = 'COD' THEN -@TienHoaHong ELSE @SoTien - @TienHoaHong END;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2);
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
        IF @SoDu IS NULL THROW 51004, N'Khong tim thay vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @KTVId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @SoDu + @BienDong - @DangChoRut < 0
            THROW 51009, N'Ví KTV không đủ số dư khả dụng để trừ hoa hồng. Cần nạp ví hoặc xử lý yêu cầu rút đang chờ.', 1;
        IF @BienDong <> 0
        BEGIN
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, CASE WHEN @PhuongThuc = 'COD' THEN 'Commission' ELSE 'SettlementCredit' END,
                @BienDong, 'DoiSoat', @DoiSoatId, @NguoiThucHienId, CASE WHEN @LoaiThanhToan = 'PhiHuyDon' THEN N'Bù phí di chuyển do khách hủy đơn.' ELSE N'Đối soát thanh toán đơn hàng.' END);
        END;
        UPDATE dbo.DoiSoat SET TrangThai = 'Confirmed', NguoiDuyetId = @NguoiThucHienId WHERE Id = @DoiSoatId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TienHoaHong, TrangThai, NguoiDuyetId, PhienBan
        FROM dbo.DoiSoat
        WHERE Id = @DoiSoatId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_DoiSoatCOD;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauVi
    @NguoiThucHienId INT,
    @Loai VARCHAR(20),
    @SoTien DECIMAL(18,2),
    @GhiChu NVARCHAR(1000) = NULL,
    @ChungTuId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauVi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF @Loai IS NULL OR @Loai NOT IN ('Deposit', 'Withdrawal') OR @SoTien IS NULL OR @SoTien <= 0 OR @SoTien > 1000000000
            THROW 51009, N'Loai nap/rut hoac so tien khong hop le.', 1;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2), @Id INT;
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiThucHienId;
        IF @SoDu IS NULL THROW 51004, N'Chua co vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @NguoiThucHienId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @Loai = 'Withdrawal' AND @SoTien > @SoDu - @DangChoRut
            THROW 51009, N'So du kha dung khong du. Can tru cac yeu cau rut dang cho.', 1;
        IF @Loai = 'Deposit' AND (@ChungTuId IS NULL OR NOT EXISTS (
            SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChungTuId AND ChuSoHuuId = @NguoiThucHienId AND MucDich = 'WalletProof'))
            THROW 51009, N'Nap vi can chung tu chuyen tien cua chinh ky thuat vien.', 1;
        IF @Loai = 'Deposit' AND EXISTS (SELECT 1 FROM dbo.YeuCauVi
            WHERE ChungTuId = @ChungTuId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Chung tu nay da duoc su dung cho yeu cau nap vi.', 1;
        INSERT INTO dbo.YeuCauVi (KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai)
        VALUES (@NguoiThucHienId, @Loai, @SoTien, COALESCE(@GhiChu, N''), @ChungTuId, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauVi
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetYeuCauVi
    @NguoiThucHienId INT,
    @YeuCauViId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_DuyetYeuCauVi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(20), @Loai VARCHAR(20), @KTVId INT;
        DECLARE @SoTien DECIMAL(18,2), @SoDu DECIMAL(18,2), @ChungTuId INT, @BienDong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai, @Loai = Loai, @KTVId = KyThuatVienId,
               @SoTien = SoTien, @ChungTuId = ChungTuId
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauViId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau vi.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Yeu cau vi da thay doi hoac da duoc xu ly.', 1;
        IF @KTVId = @NguoiThucHienId THROW 51003, N'Khong duoc tu duyet yeu cau cua minh.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Approved', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        IF @QuyetDinh = 'Rejected' AND NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
            THROW 51009, N'Can nhap ly do tu choi yeu cau vi.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            IF @Loai = 'Deposit' AND NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem
                WHERE Id = @ChungTuId AND ChuSoHuuId = @KTVId AND MucDich = 'WalletProof')
                THROW 51009, N'Yeu cau nap tien chua co chung tu hop le.', 1;
            SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
            SET @BienDong = CASE WHEN @Loai = 'Deposit' THEN @SoTien ELSE -@SoTien END;
            IF @SoDu IS NULL OR @SoDu + @BienDong < 0
                THROW 51009, N'So du hien tai khong du de duyet rut tien.', 1;
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, @Loai, @BienDong, 'YeuCauVi', @YeuCauViId, @NguoiThucHienId, COALESCE(@LyDo, N'Duyet yeu cau vi.'));
        END;
        UPDATE dbo.YeuCauVi SET TrangThai = @QuyetDinh, LyDo = @LyDo WHERE Id = @YeuCauViId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KyThuatVienId, Loai, SoTien, TrangThai, LyDo, PhienBan
        FROM dbo.YeuCauVi
        WHERE Id = @YeuCauViId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_DuyetYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTaiKhoanNganHang
    @NguoiThucHienId INT,
    @MaNganHang VARCHAR(30),
    @TenNganHang NVARCHAR(200),
    @SoTaiKhoan VARCHAR(50),
    @ChuTaiKhoan NVARCHAR(200),
    @Id INT = NULL,
    @DangHoatDong BIT = 1,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_LuuTaiKhoanNganHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF NULLIF(LTRIM(RTRIM(@MaNganHang)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@TenNganHang)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(@SoTaiKhoan)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@ChuTaiKhoan)), N'') IS NULL
           OR @DangHoatDong IS NULL
            THROW 51009, N'Can nhap day du thong tin ngan hang.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.TaiKhoanNganHang (MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong)
            VALUES (@MaNganHang, @TenNganHang, @SoTaiKhoan, @ChuTaiKhoan, @DangHoatDong);
            SET @Id = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            DECLARE @PhienBan BINARY(8);
            SELECT @PhienBan = PhienBan FROM dbo.TaiKhoanNganHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id;
            IF @PhienBan IS NULL THROW 51004, N'Khong tim thay tai khoan ngan hang.', 1;
            IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
                THROW 51009, N'Tai khoan ngan hang da thay doi.', 1;
            -- Giu thong tin tai khoan da tham gia giao dich de bao toan lich su doi chieu.
            IF (EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE TaiKhoanNganHangId = @Id)
                OR EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WHERE TaiKhoanNganHangId = @Id))
                AND EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang
                    WHERE Id = @Id AND (MaNganHang <> @MaNganHang OR SoTaiKhoan <> @SoTaiKhoan OR ChuTaiKhoan <> @ChuTaiKhoan))
                THROW 51009, N'Tai khoan da co giao dich. Hay tao tai khoan moi va ngung tai khoan cu.', 1;
            UPDATE dbo.TaiKhoanNganHang
            SET MaNganHang = @MaNganHang, TenNganHang = @TenNganHang,
                SoTaiKhoan = @SoTaiKhoan, ChuTaiKhoan = @ChuTaiKhoan, DangHoatDong = @DangHoatDong
            WHERE Id = @Id;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu tài khoản ngân hàng', N'TaiKhoanNganHang', @Id);
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong, PhienBan
        FROM dbo.TaiKhoanNganHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuTaiKhoanNganHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauHoTro
    @NguoiThucHienId INT,
    @DonHangId INT,
    @Loai VARCHAR(20),
    @MoTa NVARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @NgayHoanThanh DATETIME2, @Id INT;
        SELECT @TrangThai = TrangThai, @NgayHoanThanh = NgayCapNhat
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId;
        IF @TrangThai IS NULL THROW 51003, N'Chi khach hang cua don duoc tao yeu cau ho tro.', 1;
        IF @Loai IS NULL OR @Loai NOT IN ('Complaint', 'Warranty') OR NULLIF(LTRIM(RTRIM(@MoTa)), N'') IS NULL
            THROW 51009, N'Loai ho tro hoac noi dung khong hop le.', 1;
        IF @Loai = 'Warranty'
        BEGIN
            IF @TrangThai <> 'HoanThanh' THROW 51009, N'Chi don da hoan thanh moi duoc yeu cau bao hanh.', 1;
            DECLARE @HanBaoHanh DATETIME2;
            SELECT @HanBaoHanh = HanBaoHanh FROM dbo.fn_HanBaoHanh(@DonHangId);
            IF @HanBaoHanh IS NULL OR @HanBaoHanh < SYSUTCDATETIME()
                THROW 51009, N'Don khong co vat tu bao hanh hoac da het han bao hanh.', 1;
        END;
        IF EXISTS (SELECT 1 FROM dbo.YeuCauHoTro WHERE DonHangId = @DonHangId AND Loai = @Loai AND TrangThai IN ('Open', 'InProgress'))
            THROW 51009, N'Don da co yeu cau cung loai dang duoc xu ly.', 1;
        INSERT INTO dbo.YeuCauHoTro (DonHangId, KhachHangId, Loai, MoTa, TrangThai)
        VALUES (@DonHangId, @NguoiThucHienId, @Loai, @MoTa, 'Open');
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        SELECT Id, @DonHangId, N'Yêu cầu hỗ trợ mới', @MoTa FROM dbo.NguoiDung WHERE VaiTro = 'CSKH' AND DangHoatDong = 1;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KhachHangId, Loai, MoTa, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauHoTro
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XuLyHoTro
    @NguoiThucHienId INT,
    @YeuCauHoTroId INT,
    @TrangThai VARCHAR(20),
    @KetQuaXuLy NVARCHAR(2000) = NULL,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XuLyHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThaiCu VARCHAR(20), @NguoiXuLyId INT, @KhachId INT, @DonId INT;
        SELECT @PhienBan = PhienBan, @TrangThaiCu = TrangThai, @NguoiXuLyId = NguoiXuLyId, @KhachId = KhachHangId, @DonId = DonHangId
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Yeu cau ho tro da thay doi.', 1;
        IF @VaiTro = 'CSKH' AND @NguoiXuLyId IS NOT NULL AND @NguoiXuLyId <> @NguoiThucHienId
            THROW 51003, N'Phiếu đang được nhân viên khác tiếp nhận.', 1;
        IF @TrangThai IS NULL OR NOT ((@TrangThaiCu = 'Open' AND @TrangThai IN ('InProgress', 'Rejected'))
            OR (@TrangThaiCu = 'InProgress' AND @TrangThai IN ('Resolved', 'Rejected')))
            THROW 51009, N'Thu tu xu ly: Open -> InProgress -> Resolved; co the tu choi yeu cau chua dong.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') AND NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N'') IS NULL
            THROW 51009, N'Can ghi ket qua hoac ly do tu choi.', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai = @TrangThai, KetQuaXuLy = @KetQuaXuLy, NguoiXuLyId = @NguoiThucHienId, NgayCapNhat = SYSUTCDATETIME()
        WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung, TrangThai)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, COALESCE(NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N''), N'CSKH đã tiếp nhận yêu cầu.'), @TrangThai);
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        VALUES (@KhachId, @DonId, N'Cập nhật yêu cầu hỗ trợ', COALESCE(@KetQuaXuLy, N'CSKH đã tiếp nhận yêu cầu.'));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, Loai, TrangThai, KetQuaXuLy, NguoiXuLyId, PhienBan
        FROM dbo.YeuCauHoTro
        WHERE Id = @YeuCauHoTroId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XuLyHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemTraoDoiHoTro
    @NguoiThucHienId INT,
    @YeuCauHoTroId INT,
    @NoiDung NVARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ThemTraoDoiHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KhachHangId INT, @TrangThai VARCHAR(20), @Id INT, @NhanVien INT, @DonId INT;
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai, @NhanVien = NguoiXuLyId, @DonId = DonHangId
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId
            THROW 51003, N'Khong duoc xem hoac trao doi ho tro cua khach hang khac.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') THROW 51009, N'Yeu cau ho tro da dong.', 1;
        IF @VaiTro = 'CSKH' AND (@TrangThai <> 'InProgress' OR @NhanVien IS NULL OR @NhanVien <> @NguoiThucHienId)
            THROW 51003, N'Cần tiếp nhận phiếu trước khi trả lời; chỉ nhân viên phụ trách được xử lý.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung trao doi khong duoc rong.', 1;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @NoiDung);
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.YeuCauHoTro SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        SELECT Id, @DonId, N'Trao đổi yêu cầu hỗ trợ', @NoiDung FROM dbo.NguoiDung
        WHERE DangHoatDong = 1 AND ((@VaiTro = 'KH' AND VaiTro = 'CSKH' AND (@NhanVien IS NULL OR Id = @NhanVien))
            OR (@VaiTro <> 'KH' AND Id = @KhachHangId));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, YeuCauHoTroId, NguoiGuiId, NoiDung, NgayTao
        FROM dbo.TraoDoiHoTro
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemTraoDoiHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDanhGiaDonHang
    @NguoiThucHienId INT,
    @DonHangId INT,
    @Diem INT,
    @NhanXet NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoDanhGiaDonHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KTVId INT, @Id INT;
        SELECT @KTVId = KyThuatVienId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'HoanThanh';
        IF @KTVId IS NULL THROW 51003, N'Chi chu don hang da hoan thanh duoc danh gia.', 1;
        IF @Diem IS NULL OR @Diem NOT BETWEEN 1 AND 5 THROW 51009, N'Diem danh gia phai tu 1 den 5.', 1;
        IF EXISTS (SELECT 1 FROM dbo.DanhGia WHERE DonHangId = @DonHangId)
            THROW 51009, N'Moi don hang chi duoc danh gia mot lan.', 1;
        INSERT INTO dbo.DanhGia (DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet)
        VALUES (@DonHangId, @NguoiThucHienId, @KTVId, @Diem, COALESCE(@NhanXet, N''));
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet, NgayTao
        FROM dbo.DanhGia
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDanhGiaDonHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTongHop
    @NguoiThucHienId INT,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1 AND VaiTro IN ('GD', 'KT', 'ADMIN'))
        THROW 51003, N'Khong co quyen xem bao cao tong hop.', 1;
    IF @TuNgay IS NOT NULL AND @DenNgay IS NOT NULL AND @TuNgay > @DenNgay
        THROW 51009, N'Khoang ngay bao cao khong hop le.', 1;
    SELECT Ngay, SoDon, TongThu, TienHoaHong
    FROM dbo.vw_DoanhThuNgay
    WHERE (@TuNgay IS NULL OR Ngay >= @TuNgay) AND (@DenNgay IS NULL OR Ngay <= @DenNgay)
    ORDER BY Ngay DESC;
    SELECT KyThuatVienId, HoTen, SoDonHoanThanh, DiemTrungBinh
    FROM dbo.vw_HieuSuatKyThuatVien ORDER BY SoDonHoanThanh DESC;
    SELECT TrangThai, COUNT_BIG(*) AS SoLuong FROM dbo.vw_DonHangTongHop
    WHERE (@TuNgay IS NULL OR NgayTao >= @TuNgay)
        AND (@DenNgay IS NULL OR NgayTao < DATEADD(DAY, 1, CONVERT(DATETIME2, @DenNgay)))
    GROUP BY TrangThai;
END;
GO

-- Thủ tục quản lý hồ sơ, tài khoản và yêu cầu ví.

CREATE OR ALTER PROCEDURE dbo.sp_HuyYeuCauVi
    @NguoiThucHienId INT,
    @YeuCauViId INT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_HuyYeuCauVi;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @YeuCauViId AND KyThuatVienId = @NguoiThucHienId
            AND TrangThai = 'Pending' AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Yêu cầu đã thay đổi hoặc không thuộc thợ.', 1;
        UPDATE dbo.YeuCauVi SET TrangThai = 'Cancelled', LyDo = N'Thợ hủy yêu cầu.' WHERE Id = @YeuCauViId;
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_YeuCauVi WHERE Id = @YeuCauViId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_HuyYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TuChoiNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT, @PhienBanDuKien BINARY(8), @LyDo NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_TuChoiNghiemThu;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        DECLARE @DonHangId INT;
        SELECT @DonHangId = nt.DonHangId FROM dbo.PhieuNghiemThu AS nt WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DonHang AS dh WITH (UPDLOCK, HOLDLOCK) ON dh.Id = nt.DonHangId
        WHERE nt.Id = @NghiemThuId AND nt.PhienBan = @PhienBanDuKien AND nt.TrangThai = 'Pending'
            AND dh.KhachHangId = @NguoiThucHienId AND dh.TrangThai = 'ChoNghiemThu';
        IF @DonHangId IS NULL THROW 51009, N'Phiếu đã thay đổi hoặc không thuộc khách hàng.', 1;
        IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL THROW 51009, N'Cần nêu lý do từ chối nghiệm thu.', 1;
        UPDATE dbo.PhieuNghiemThu SET TrangThai = 'Rejected' WHERE Id = @NghiemThuId;
        UPDATE dbo.DonHang SET TrangThai = 'DangXuLy', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang(DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoNghiemThu', 'DangXuLy', @NguoiThucHienId, @LyDo);
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_PhieuNghiemThu WHERE Id = @NghiemThuId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_TuChoiNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTuyChonGiamSat
    @NguoiThucHienId INT,
    @GiaTri NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_LuuTuyChonGiamSat;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('GD','CSKH','ADMIN')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF ISJSON(@GiaTri) <> 1 THROW 51009, N'Tùy chọn giám sát không hợp lệ.', 1;
        DECLARE @Khoa VARCHAR(100) = 'GiamSat_' + CONVERT(VARCHAR(10), @NguoiThucHienId);
        IF EXISTS (SELECT 1 FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa)
            UPDATE dbo.CauHinh SET GiaTri = @GiaTri WHERE Khoa = @Khoa;
        ELSE
            INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES (@Khoa, @GiaTri, N'Tùy chọn giám sát cá nhân');
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_LuuTuyChonGiamSat;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetChinhSach
    @NguoiThucHienId INT,
    @Khoa VARCHAR(100), @QuyetDinh VARCHAR(30), @GhiChu NVARCHAR(1000), @NgayHieuLuc DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_DuyetChinhSach;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('GD')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF @Khoa NOT LIKE 'DeXuatChinhSach[_]%' OR @QuyetDinh NOT IN ('Approved','Rejected','RevisionRequested')
            THROW 51009, N'Đề xuất hoặc quyết định không hợp lệ.', 1;
        DECLARE @GiaTri NVARCHAR(MAX);
        SELECT @GiaTri = GiaTri FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa;
        IF @GiaTri IS NULL OR ISJSON(@GiaTri) <> 1 THROW 51004, N'Không tìm thấy đề xuất.', 1;
        IF JSON_VALUE(@GiaTri, '$.status') <> 'Pending' THROW 51009, N'Đề xuất đã được xử lý.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            DECLARE @LoaiDeXuat VARCHAR(40) = JSON_VALUE(@GiaTri, '$.payload.type');
            IF @LoaiDeXuat = 'ServicePricing'
            BEGIN
                DECLARE @DichVuId INT = TRY_CONVERT(INT, JSON_VALUE(@GiaTri, '$.payload.serviceId'));
                IF @DichVuId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DichVuId)
                    THROW 51004, N'Dịch vụ trong đề xuất không còn tồn tại.', 1;
                UPDATE dbo.DichVu
                SET PhiKiemTra = TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(@GiaTri, '$.payload.inspectionFee')),
                    TienCong = TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(@GiaTri, '$.payload.laborFee')),
                    TyLeHoaHong = TRY_CONVERT(DECIMAL(5,2), JSON_VALUE(@GiaTri, '$.payload.commissionRatePercent'))
                WHERE Id = @DichVuId;
            END
            ELSE IF @LoaiDeXuat = 'Configuration'
            BEGIN
                DECLARE @KhoaCauHinh VARCHAR(80) = JSON_VALUE(@GiaTri, '$.payload.key');
                DECLARE @GiaTriMoi NVARCHAR(1000) = JSON_VALUE(@GiaTri, '$.payload.value');
                IF @KhoaCauHinh NOT IN ('TyLeHoaHongMacDinh', 'PhiHuyDon') OR @GiaTriMoi IS NULL
                    THROW 51009, N'Đề xuất cấu hình không hợp lệ.', 1;
                UPDATE dbo.CauHinh SET GiaTri = @GiaTriMoi WHERE Khoa = @KhoaCauHinh;
            END;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, ChiTiet)
        VALUES (@NguoiThucHienId, N'Duyệt chính sách', @Khoa, @QuyetDinh);
        -- Đề xuất chỉ là hàng chờ phê duyệt. Sau khi có quyết định, xóa khỏi
        -- CauHinh; nhật ký bên trên vẫn lưu dấu vết của quyết định.
        DELETE FROM dbo.CauHinh WHERE Khoa = @Khoa;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_DuyetChinhSach;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiPhuongThucThanhToan
    @NguoiThucHienId INT,
    @DonHangId INT, @PhuongThuc VARCHAR(10), @TaiKhoanNganHangId INT = NULL, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_DoiPhuongThucThanhToan;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId
            AND TrangThai = 'ChoNghiemThu' AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Đơn đã thay đổi hoặc không thuộc khách hàng.', 1;
        IF @PhuongThuc NOT IN ('COD','BANK') THROW 51009, N'Phương thức không hợp lệ.', 1;
        IF EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND TrangThai = 'Pending')
            THROW 51009, N'Đang có chứng từ chờ kế toán xác minh.', 1;
        IF @PhuongThuc = 'BANK' AND NOT EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nhận tiền không hợp lệ.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai = 'Approved')
            THROW 51009, N'Cần ký nghiệm thu trước khi đổi thanh toán.', 1;
        UPDATE dbo.PhieuNghiemThu SET PhuongThucThanhToan = @PhuongThuc,
            TaiKhoanNganHangId = CASE WHEN @PhuongThuc = 'BANK' THEN @TaiKhoanNganHangId END
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @DonHangId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_DoiPhuongThucThanhToan;
        THROW;
    END CATCH;
END;
GO


GO

-- MODULE: 06_trigger.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Trigger bảo vệ dữ liệu kể cả khi người quản trị thao tác trực tiếp trong SSMS.
   inserted/deleted là TẬP HỢP dòng, không giả định một dòng hoặc dùng con trỏ. */
CREATE OR ALTER TRIGGER dbo.tr_DonHang_KiemTraTrangThai
ON dbo.DonHang AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        LEFT JOIN deleted AS d ON d.Id = i.Id
        WHERE (d.Id IS NULL AND i.TrangThai <> 'ChoTiepNhan')
           OR (d.Id IS NOT NULL AND i.TrangThai <> d.TrangThai AND NOT (
                (d.TrangThai = 'ChoTiepNhan' AND i.TrangThai = 'ChoDuyetSoBo')
             OR (d.TrangThai = 'ChoDuyetSoBo' AND i.TrangThai IN ('ChoPhanCong','ChoTiepNhan'))
             OR (d.TrangThai = 'ChoPhanCong' AND i.TrangThai IN ('ChoNhan','ChoDuyetSoBo'))
             OR (d.TrangThai = 'ChoNhan' AND i.TrangThai IN ('DaTiepNhan','ChoPhanCong'))
             OR (d.TrangThai = 'DaTiepNhan' AND i.TrangThai = 'DangDiChuyen')
             OR (d.TrangThai = 'DangDiChuyen' AND i.TrangThai = 'DaDenNoi')
             OR (d.TrangThai = 'DaDenNoi' AND i.TrangThai = 'DangXuLy')
             OR (d.TrangThai = 'DangXuLy' AND i.TrangThai = 'ChoNghiemThu')
             OR (d.TrangThai = 'ChoNghiemThu' AND i.TrangThai IN ('HoanThanh','DangXuLy'))
             OR (d.TrangThai IN ('ChoTiepNhan','ChoDuyetSoBo','ChoPhanCong','ChoNhan','DaTiepNhan','DangDiChuyen','DaDenNoi') AND i.TrangThai = 'Huy')
           ))
    ) THROW 51009, N'Trạng thái đơn không được chuyển theo bước này.', 1;
    IF EXISTS (
        SELECT 1 FROM inserted AS i INNER JOIN deleted AS d ON d.Id = i.Id
        WHERE (d.TrangThai = 'Huy' AND (i.PhiHuyDon <> d.PhiHuyDon
            OR ISNULL(i.KyThuatVienId, 0) <> ISNULL(d.KyThuatVienId, 0)))
          OR (i.TrangThai = 'Huy' AND d.TrangThai IN ('DangDiChuyen','DaDenNoi') AND i.PhiHuyDon <= 0)
          OR (i.TrangThai = 'Huy' AND d.TrangThai NOT IN ('DangDiChuyen','DaDenNoi','Huy') AND i.PhiHuyDon <> 0)
    ) THROW 51009, N'Phí hủy phải đúng thời điểm di chuyển và không được đổi sau khi hủy.', 1;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        WHERE i.TrangThai IN ('DaTiepNhan','DangDiChuyen','DaDenNoi','DangXuLy','ChoNghiemThu','HoanThanh')
          AND i.KyThuatVienId IS NULL
    ) THROW 51009, N'Đơn đã tiếp nhận phải có kỹ thuật viên.', 1;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        WHERE i.TrangThai = 'HoanThanh'
          AND NOT EXISTS (SELECT 1 FROM dbo.ThanhToan AS tt WHERE tt.DonHangId = i.Id)
    ) THROW 51009, N'Chỉ hoàn thành đơn đã ghi nhận thanh toán.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ThanhToan_KiemTraChungTu
ON dbo.ThanhToan AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        LEFT JOIN dbo.PhieuNghiemThu AS nt ON nt.Id = i.NghiemThuId
        WHERE (i.LoaiThanhToan = 'DichVu' AND (nt.Id IS NULL OR nt.DonHangId <> i.DonHangId
            OR nt.TrangThai <> 'Approved' OR nt.TongTien <> i.SoTien OR nt.PhuongThucThanhToan <> i.PhuongThuc
            OR dh.TrangThai <> 'ChoNghiemThu'))
          OR (i.LoaiThanhToan = 'PhiHuyDon' AND (dh.TrangThai <> 'Huy' OR dh.PhiHuyDon <> i.SoTien
            OR dh.PhiHuyDon <= 0 OR dh.KyThuatVienId IS NULL OR i.NghiemThuId IS NOT NULL OR i.PhuongThuc <> 'BANK'))
    ) THROW 51009, N'Thanh toán phải khớp nghiệm thu hoặc đúng phí hủy đơn chuyển khoản.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ThanhToan_BatBien
ON dbo.ThanhToan INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 51009, N'Không được sửa/xóa chứng từ thanh toán; lập chứng từ điều chỉnh.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_GiaoDichVi_BatBien
ON dbo.GiaoDichVi INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 51009, N'Sổ cái ví chỉ được ghi thêm; không sửa hoặc xóa lịch sử.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_DanhGia_KiemTraDon
ON dbo.DanhGia AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        WHERE dh.TrangThai <> 'HoanThanh' OR dh.KhachHangId <> i.KhachHangId
           OR dh.KyThuatVienId <> i.KyThuatVienId OR dh.KyThuatVienId IS NULL
    ) THROW 51009, N'Đánh giá phải thuộc khách hàng và kỹ thuật viên của đơn hoàn thành.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ChiTietVatTu_KhoaNghiemThu
ON dbo.ChiTietVatTu AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM dbo.BangKeVatTu AS dx
        WHERE EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu AS nt WHERE nt.BangKeVatTuId = dx.Id) AND (
            EXISTS (SELECT 1 FROM inserted AS i WHERE i.BangKeVatTuId = dx.Id)
            OR EXISTS (SELECT 1 FROM deleted AS d WHERE d.BangKeVatTuId = dx.Id)
        )
    ) THROW 51009, N'Vật tư đã lập nghiệm thu không được sửa. Hãy lập phiên bản mới khi xử lý lại.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_PhieuNghiemThu_KiemTraChuKy
ON dbo.PhieuNghiemThu AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        LEFT JOIN dbo.TepDinhKem AS ckktv ON ckktv.Id = i.ChuKyKTVId
        LEFT JOIN dbo.TepDinhKem AS ckkh ON ckkh.Id = i.ChuKyKHId
        WHERE dh.KyThuatVienId <> i.KyThuatVienId
           OR (i.ChuKyKTVId IS NOT NULL AND (ckktv.ChuSoHuuId <> i.KyThuatVienId OR ckktv.DonHangId <> i.DonHangId OR ckktv.DonHangId IS NULL OR ckktv.MucDich <> 'TechnicianSignature'))
           OR (i.ChuKyKHId IS NOT NULL AND (ckkh.ChuSoHuuId <> dh.KhachHangId OR ckkh.DonHangId <> i.DonHangId OR ckkh.DonHangId IS NULL OR ckkh.MucDich <> 'CustomerSignature'))
    ) THROW 51009, N'Chữ ký phải thuộc đúng chủ sở hữu, đơn hàng và mục đích.', 1;
END;
GO


GO

-- MODULE: 07_security.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/* 7 role nghiệp vụ + role kỹ thuật nội bộ phục vụ đăng nhập và đăng ký.
   Tài khoản hf_* WITHOUT LOGIN dùng để EXECUTE AS USER khi demo hoặc từ backend.
   Không cấp db_owner/db_datareader/db_datawriter cho tài khoản ứng dụng.
   Backend lọc phạm vi dữ liệu theo JWT; role SQL giới hạn đối tượng được đọc/chạy.
   EXECUTE AS USER không tự xác định danh tính KH: tham số actor lấy từ JWT.
   Quyền IMPERSONATE chỉ cấp trên các user hf_* cho login kết nối ứng dụng.
   Chủ sở hữu dbo giữ nguyên giúp ownership chain: SP/View truy cập bảng nội bộ
   dù caller không được thao tác trực tiếp. Không sử dụng dynamic SQL cho CRUD. */
IF DATABASE_PRINCIPAL_ID('HomeFix_KH') IS NULL CREATE ROLE HomeFix_KH AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KH') IS NULL CREATE USER hf_KH WITHOUT LOGIN;
ALTER ROLE HomeFix_KH ADD MEMBER hf_KH;
IF DATABASE_PRINCIPAL_ID('HomeFix_KTV') IS NULL CREATE ROLE HomeFix_KTV AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KTV') IS NULL CREATE USER hf_KTV WITHOUT LOGIN;
ALTER ROLE HomeFix_KTV ADD MEMBER hf_KTV;
IF DATABASE_PRINCIPAL_ID('HomeFix_DPV') IS NULL CREATE ROLE HomeFix_DPV AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_DPV') IS NULL CREATE USER hf_DPV WITHOUT LOGIN;
ALTER ROLE HomeFix_DPV ADD MEMBER hf_DPV;
IF DATABASE_PRINCIPAL_ID('HomeFix_CSKH') IS NULL CREATE ROLE HomeFix_CSKH AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_CSKH') IS NULL CREATE USER hf_CSKH WITHOUT LOGIN;
ALTER ROLE HomeFix_CSKH ADD MEMBER hf_CSKH;
IF DATABASE_PRINCIPAL_ID('HomeFix_KT') IS NULL CREATE ROLE HomeFix_KT AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KT') IS NULL CREATE USER hf_KT WITHOUT LOGIN;
ALTER ROLE HomeFix_KT ADD MEMBER hf_KT;
IF DATABASE_PRINCIPAL_ID('HomeFix_GD') IS NULL CREATE ROLE HomeFix_GD AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_GD') IS NULL CREATE USER hf_GD WITHOUT LOGIN;
ALTER ROLE HomeFix_GD ADD MEMBER hf_GD;
IF DATABASE_PRINCIPAL_ID('HomeFix_ADMIN') IS NULL CREATE ROLE HomeFix_ADMIN AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_ADMIN') IS NULL CREATE USER hf_ADMIN WITHOUT LOGIN;
ALTER ROLE HomeFix_ADMIN ADD MEMBER hf_ADMIN;
IF DATABASE_PRINCIPAL_ID('HomeFix_UngDung') IS NULL CREATE ROLE HomeFix_UngDung AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_UngDung') IS NULL CREATE USER hf_UngDung WITHOUT LOGIN;
ALTER ROLE HomeFix_UngDung ADD MEMBER hf_UngDung;
GO
REVOKE EXECUTE ON OBJECT::dbo.sp_DuyetHoSoKTV FROM HomeFix_DPV;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.NguoiDung TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.KyThuatVien TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DanhMucDichVu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DichVu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DonHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LichSuDonHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LenhDieuPhoi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.BaoGiaSoBo TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.BangKeVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ChiTietVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TepDinhKem TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PhieuNghiemThu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TaiKhoanNganHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ThanhToan TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DoiSoat TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauThanhToan TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.HoSoKTV TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauHoTro TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TraoDoiHoTro TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DanhGia TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.GhiChuDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.NhatKy TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.CauHinh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT ON OBJECT::dbo.NguoiDung(MatKhauBam) TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
GO
-- Đọc dữ liệu: KH
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KH;
GO
-- Đọc dữ liệu: KTV
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KTV;
GO
-- Đọc dữ liệu: DPV
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_DPV;
GO
-- Đọc dữ liệu: CSKH
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_CSKH;
GO
-- Đọc dữ liệu: KT
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KT;
GO
-- Đọc dữ liệu: GD
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_GD;
GO
-- Đọc dữ liệu: ADMIN
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_NhatKy TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_ADMIN;
GO
-- Đọc dữ liệu: UngDung
GRANT SELECT ON OBJECT::dbo.vw_XacThucDangNhap TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_UngDung;
GO
GRANT EXECUTE ON OBJECT::dbo.sp_DangKyKhachHang TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoTaiKhoanNoiBo TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiMatKhau TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatThongTinNguoiDung TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KhoaMoKhoaTaiKhoan TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiVaiTroNguoiDung TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_AdminCapNhatTaiKhoan TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTho TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTrangThaiKTV TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_GuiHoSoKTV TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetHoSoKTV TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTepDinhKem TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DanhDauThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuDichVu TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuDanhMucDichVu TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuCauHinh TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoDonHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoBaoGiaSoBo TO HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KhachDuyetBaoGiaSoBo TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoLenhDieuPhoi TO HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KTVPhanHoiDieuPhoi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_ChuyenTrangThaiDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemGhiChuDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuBangKeVatTu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoPhieuNghiemThu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_KTVKyNghiemThu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_KhachHangKyNghiemThu TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XacNhanThanhToanCOD TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauThanhToan TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XacNhanThanhToanNganHang TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiSoatCOD TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauVi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetYeuCauVi TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTaiKhoanNganHang TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauHoTro TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XuLyHoTro TO HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemTraoDoiHoTro TO HomeFix_KH, HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoDanhGiaDonHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_GD, HomeFix_KT, HomeFix_ADMIN;
GO
-- TVF chỉ đọc: demo báo cáo và tra cứu, không được GRANT trực tiếp bảng.
GRANT SELECT ON OBJECT::dbo.fn_SoDuVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_DiemDanhGia TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_HanBaoHanh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_ThongKeDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.fn_HoaHong TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GO
/* Đối chiếu sau khi cài (chạy riêng trong SSMS):
EXECUTE AS USER = 'hf_KH';
SELECT Id, HoTen, VaiTro FROM dbo.vw_NguoiDung; -- được, view không có hash
SELECT SoDu FROM dbo.fn_SoDuVi(2);            -- được, TVF chỉ đọc
SELECT Id FROM dbo.NguoiDung;                -- lỗi 229: truy cập bảng bị chặn
SELECT MatKhauBam FROM dbo.vw_XacThucDangNhap; -- lỗi 229: chỉ hf_UngDung được đọc
REVERT; -- luôn trở lại tài khoản ban đầu sau demo quyền
*/

-- Quyền cho hồ sơ và báo cáo; không cấp quyền bảng.
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KH, HomeFix_KT, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_DPV, HomeFix_KT, HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_DPV, HomeFix_KT, HomeFix_GD;
GRANT EXECUTE ON OBJECT::dbo.sp_HuyYeuCauVi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TuChoiNghiemThu TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTuyChonGiamSat TO HomeFix_GD, HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetChinhSach TO HomeFix_GD;
GO

GRANT EXECUTE ON OBJECT::dbo.sp_DoiPhuongThucThanhToan TO HomeFix_KH;
GO

-- Hiệu suất toàn bộ KTV chỉ dành cho điều phối, giám đốc và quản trị.
DENY SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_KH, HomeFix_KTV, HomeFix_CSKH, HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_DPV, HomeFix_GD, HomeFix_ADMIN;
GO

-- Hai bộ phận này được xem thông tin thanh toán khi mở chi tiết đơn.
-- Chỉ cấp SELECT trên View; các bảng gốc vẫn bị DENY.
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_DPV, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_DPV, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.fn_KyThuatVienPhuHop TO HomeFix_DPV, HomeFix_ADMIN;
GO


GO

-- MODULE: 08_seed.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* DỮ LIỆU BAN ĐẦU SẠCH: 7 người dùng, 1 hồ sơ thợ, 5 nhóm/5 dịch vụ,
   1 tài khoản ngân hàng MÔ PHỎNG và cấu hình. KHÔNG có đơn/sổ cái/nhật ký.
   Mật khẩu cả 7 tài khoản: 123456. Chỉ dùng cho học tập trên máy cá nhân.
   Script chỉ chèn khi database còn trắng; không xóa giao dịch đang có. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.NguoiDung) OR EXISTS (SELECT 1 FROM dbo.DonHang)
        THROW 51009, N'Seed chỉ chạy trên database trắng. Không tự động xóa dữ liệu hiện có.', 1;
    DECLARE @MatKhauBam VARCHAR(100) = '$2b$10$6R3Jy/EiVEhpVTLlbrO1SuUsl9VMoJuAolWgiIYQ7V/1s0XW8OxHS';
    INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, MatKhauBam, VaiTro)
    VALUES (N'Khách hàng mẫu', '0900000001', @MatKhauBam, 'KH'),
           (N'Kỹ thuật viên mẫu', '0900000002', @MatKhauBam, 'KTV'),
           (N'Điều phối viên mẫu', '0900000003', @MatKhauBam, 'DPV'),
           (N'Chăm sóc khách hàng mẫu', '0900000004', @MatKhauBam, 'CSKH'),
           (N'Kế toán mẫu', '0900000005', @MatKhauBam, 'KT'),
           (N'Giám đốc mẫu', '0900000006', @MatKhauBam, 'GD'),
           (N'Quản trị viên mẫu', '0900000007', @MatKhauBam, 'ADMIN');
    INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu)
    SELECT Id, 'DIEN', N'Thành phố Hồ Chí Minh', 'SanSang', 0 FROM dbo.NguoiDung WHERE VaiTro = 'KTV';
    INSERT INTO dbo.DanhMucDichVu(Ten, Ma)
    VALUES (N'Điện', 'DIEN'), (N'Nước', 'NUOC'), (N'Điện lạnh', 'DIEN_LANH'), (N'Đồ gỗ', 'DO_GO'), (N'Khóa', 'KHOA');
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Kiểm tra và sửa chữa điện', N'Sửa ổ cắm, công tắc và sự cố điện gia đình.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DIEN';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Kiểm tra và sửa chữa nước', N'Khắc phục rò rỉ và thay phụ kiện đường nước.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'NUOC';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Bảo dưỡng máy lạnh', N'Kiểm tra và vệ sinh máy lạnh gia đình.', 50000, 200000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DIEN_LANH';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Sửa đồ gỗ gia đình', N'Sửa bản lề, cánh tủ và phụ kiện đồ gỗ.', 50000, 180000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'DO_GO';
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT Id, N'Sửa và thay khóa', N'Kiểm tra, sửa hoặc thay khóa dân dụng.', 50000, 150000, 15 FROM dbo.DanhMucDichVu WHERE Ma = 'KHOA';
    INSERT INTO dbo.TaiKhoanNganHang(MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan)
    VALUES ('DEMO', N'Ngân hàng mô phỏng - không chuyển tiền thật', '000000000000', N'HOMEFIX DEMO');
    INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES ('PhiHuyDon', N'60000', N'Phí hủy khi KTV đã di chuyển');
    INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi)
    VALUES ('TyLeHoaHongMacDinh', N'15', N'Tỷ lệ hoa hồng mặc định'),
           ('TaiKhoanNganHangMacDinh', N'1', N'Id tài khoản ngân hàng nhận tiền'),
           ('TenHeThong', N'HomeFix', N'Tên hệ thống'),
           ('SoDienThoaiHoTro', N'02800000000', N'Số điện thoại hỗ trợ mô phỏng');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
SELECT Id, HoTen, SoDienThoai, VaiTro, DangHoatDong FROM dbo.vw_NguoiDung ORDER BY Id;
GO


GO

-- MODULE: 10_backup_recovery.sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/* Sao lưu/phục hồi thuộc quyền DBA, không cho tài khoản ứng dụng chạy từ web.
   LƯU Ý SQL Server: BACKUP/RESTORE KHÔNG được chạy bên trong BEGIN TRANSACTION.
   Đây là ngoại lệ kỹ thuật của lệnh quản trị, không phải CRUD ngoài giao dịch.
   Module chỉ tạo thủ tục và hướng dẫn; cài đặt không tự sao lưu/xóa/phục hồi.
   Thư mục đích nằm trên MÁY CHỦ SQL Server, service account phải có quyền ghi. */
CREATE OR ALTER PROCEDURE dbo.sp_SaoLuuHeThong
    @DuongDan NVARCHAR(4000),
    @Loai VARCHAR(4) = 'FULL',
    @BanSaoDocLap BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(IS_SRVROLEMEMBER('sysadmin'), 0) <> 1 AND ISNULL(IS_ROLEMEMBER('db_owner'), 0) <> 1
        THROW 51003, N'Chỉ quản trị viên SQL Server/db_owner được sao lưu.', 1;
    IF @@TRANCOUNT > 0 THROW 51009, N'BACKUP không được chạy trong giao dịch đang mở.', 1;
    IF @Loai NOT IN ('FULL','DIFF','LOG') THROW 51009, N'Loại sao lưu chỉ gồm FULL, DIFF, LOG.', 1;
    IF NULLIF(LTRIM(RTRIM(@DuongDan)), N'') IS NULL
        THROW 51009, N'Phải cung cấp đường dẫn tập tin trên máy chủ SQL Server.', 1;
    IF @BanSaoDocLap = 1 AND @Loai <> 'FULL'
        THROW 51009, N'Bản sao độc lập COPY_ONLY chỉ dùng với FULL trong bài này.', 1;
    DECLARE @TenCSDL SYSNAME = DB_NAME();
    BEGIN TRY
        -- NOINIT: bổ sung backup set, không ghi đè backup cũ nếu trùng đường dẫn.
        -- Khi demo nên dùng tên tập tin mới cho từng lần chạy.
        IF @Loai = 'FULL' AND @BanSaoDocLap = 1
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH COPY_ONLY, NOINIT, CHECKSUM, STATS = 10;
        ELSE IF @Loai = 'FULL'
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH NOINIT, CHECKSUM, STATS = 10;
        ELSE IF @Loai = 'DIFF'
            BACKUP DATABASE @TenCSDL TO DISK = @DuongDan WITH DIFFERENTIAL, NOINIT, CHECKSUM, STATS = 10;
        ELSE
        BEGIN
            IF DATABASEPROPERTYEX(@TenCSDL, 'Recovery') <> 'FULL'
                THROW 51009, N'Sao lưu LOG yêu cầu recovery model FULL và full backup đầu tiên.', 1;
            BACKUP LOG @TenCSDL TO DISK = @DuongDan WITH NOINIT, CHECKSUM, STATS = 10;
        END;
        SELECT @TenCSDL AS TenCSDL, @Loai AS Loai, @DuongDan AS DuongDan, SYSUTCDATETIME() AS NgayHoanTat;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
