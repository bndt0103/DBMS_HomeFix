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
    NhomTayNghe NVARCHAR(200) NOT NULL CONSTRAINT DF_KyThuatVien_TayNghe DEFAULT N'Chưa cập nhật',
    KhuVucPhucVu NVARCHAR(200) NOT NULL CONSTRAINT DF_KyThuatVien_KhuVuc DEFAULT N'Chưa cập nhật',
    TrangThaiSanSang VARCHAR(12) NOT NULL CONSTRAINT DF_KyThuatVien_SanSang DEFAULT 'TamBan',
    SoDu DECIMAL(18,2) NOT NULL CONSTRAINT DF_KyThuatVien_SoDu DEFAULT 0,
    ViDo DECIMAL(10,7) NULL,
    KinhDo DECIMAL(10,7) NULL,
    PhienBan ROWVERSION,
    CONSTRAINT CK_KyThuatVien_TrangThai CHECK (TrangThaiSanSang IN ('TamBan','SanSang','DangBan')),
    CONSTRAINT CK_KyThuatVien_SoDu CHECK (SoDu >= 0),
    CONSTRAINT CK_KyThuatVien_GPS CHECK ((ViDo IS NULL AND KinhDo IS NULL) OR (ViDo IS NOT NULL AND KinhDo IS NOT NULL AND ViDo BETWEEN -90 AND 90 AND KinhDo BETWEEN -180 AND 180))
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
    TrangThai VARCHAR(20) NOT NULL CONSTRAINT DF_DonHang_TrangThai DEFAULT 'ChoTiepNhan',
    KyThuatVienId INT NULL CONSTRAINT FK_DonHang_KTV REFERENCES dbo.KyThuatVien(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_DonHang_NgayTao DEFAULT SYSUTCDATETIME(),
    NgayCapNhat DATETIME2(3) NOT NULL CONSTRAINT DF_DonHang_CapNhat DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_DonHang_TrangThai CHECK (TrangThai IN ('ChoTiepNhan','ChoDuyetSoBo','ChoPhanCong','ChoNhan','DaTiepNhan','DangDiChuyen','DaDenNoi','DangXuLy','ChoNghiemThu','HoanThanh','Huy')),
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
CREATE TABLE dbo.DeXuatVatTu (
    Id INT IDENTITY CONSTRAINT PK_DeXuatVatTu PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_DeXuatVatTu_Don REFERENCES dbo.DonHang(Id),
    LanSuaDoi INT NOT NULL,
    DangApDung BIT NOT NULL CONSTRAINT DF_DeXuatVatTu_ApDung DEFAULT 1,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_DeXuatVatTu_TrangThai DEFAULT 'Pending',
    NguoiTaoId INT NOT NULL CONSTRAINT FK_DeXuatVatTu_NguoiTao REFERENCES dbo.NguoiDung(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_DeXuatVatTu_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT UQ_DeXuatVatTu_PhienBan UNIQUE (DonHangId, LanSuaDoi),
    CONSTRAINT CK_DeXuatVatTu_LanSuaDoi CHECK (LanSuaDoi > 0),
    CONSTRAINT CK_DeXuatVatTu_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected'))
);
CREATE TABLE dbo.ChiTietDeXuatVatTu (
    Id INT IDENTITY CONSTRAINT PK_ChiTietDeXuatVatTu PRIMARY KEY,
    DeXuatVatTuId INT NOT NULL CONSTRAINT FK_ChiTietDeXuatVatTu_DeXuat REFERENCES dbo.DeXuatVatTu(Id),
    Ten NVARCHAR(200) NOT NULL,
    SoLuong DECIMAL(10,2) NOT NULL,
    DonGia DECIMAL(18,2) NOT NULL,
    SoThangBaoHanh INT NOT NULL CONSTRAINT DF_ChiTietDeXuatVatTu_BaoHanh DEFAULT 0,
    ThanhTien AS (CONVERT(DECIMAL(18,2), SoLuong * DonGia)) PERSISTED,
    CONSTRAINT CK_ChiTietDeXuatVatTu_Gia CHECK (SoLuong > 0 AND DonGia >= 0 AND SoThangBaoHanh BETWEEN 0 AND 120)
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
    CONSTRAINT CK_TepDinhKem_MucDich CHECK (MucDich IN ('OrderFault','AcceptancePhoto','CustomerSignature','TechnicianSignature','WalletProof','PaymentProof','TechnicianDocument','Avatar')),
    CONSTRAINT CK_TepDinhKem_KichThuoc CHECK (KichThuoc BETWEEN 1 AND 10485760),
    CONSTRAINT CK_TepDinhKem_MIME CHECK (KieuMIME IN ('image/jpeg','image/png','image/webp','application/pdf'))
);
CREATE TABLE dbo.PhieuNghiemThu (
    Id INT IDENTITY CONSTRAINT PK_PhieuNghiemThu PRIMARY KEY,
    DonHangId INT NOT NULL CONSTRAINT FK_PhieuNghiemThu_Don REFERENCES dbo.DonHang(Id),
    KyThuatVienId INT NOT NULL CONSTRAINT FK_PhieuNghiemThu_KTV REFERENCES dbo.KyThuatVien(Id),
    DeXuatVatTuId INT NULL CONSTRAINT FK_PhieuNghiemThu_VatTu REFERENCES dbo.DeXuatVatTu(Id),
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
    NghiemThuId INT NOT NULL CONSTRAINT UQ_ThanhToan_NghiemThu UNIQUE CONSTRAINT FK_ThanhToan_NghiemThu REFERENCES dbo.PhieuNghiemThu(Id),
    SoTien DECIMAL(18,2) NOT NULL,
    PhuongThuc VARCHAR(4) NOT NULL,
    NguoiThuTienId INT NOT NULL CONSTRAINT FK_ThanhToan_NguoiThu REFERENCES dbo.NguoiDung(Id),
    MaThamChieu VARCHAR(100) NULL,
    TaiKhoanNganHangId INT NULL CONSTRAINT FK_ThanhToan_NganHang REFERENCES dbo.TaiKhoanNganHang(Id),
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_ThanhToan_Ngay DEFAULT SYSUTCDATETIME(),
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
    NghiemThuId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_NghiemThu REFERENCES dbo.PhieuNghiemThu(Id),
    KhachHangId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_Khach REFERENCES dbo.NguoiDung(Id),
    TaiKhoanNganHangId INT NOT NULL CONSTRAINT FK_YeuCauThanhToan_NganHang REFERENCES dbo.TaiKhoanNganHang(Id),
    SoTien DECIMAL(18,2) NOT NULL,
    ChungTuId INT NULL CONSTRAINT FK_YeuCauThanhToan_Tep REFERENCES dbo.TepDinhKem(Id),
    MaThamChieu VARCHAR(100) NULL,
    TrangThai VARCHAR(10) NOT NULL CONSTRAINT DF_YeuCauThanhToan_TrangThai DEFAULT 'Pending',
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauThanhToan_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
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
    CONSTRAINT CK_YeuCauVi_TrangThai CHECK (TrangThai IN ('Pending','Approved','Rejected'))
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
    NhomTayNghe NVARCHAR(200) NOT NULL,
    KhuVucPhucVu NVARCHAR(200) NOT NULL,
    KinhNghiem NVARCHAR(2000) NOT NULL,
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
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_YeuCauHoTro_Ngay DEFAULT SYSUTCDATETIME(),
    PhienBan ROWVERSION,
    CONSTRAINT CK_YeuCauHoTro_Loai CHECK (Loai IN ('Complaint','Warranty')),
    CONSTRAINT CK_YeuCauHoTro_TrangThai CHECK (TrangThai IN ('Open','InProgress','Resolved','Rejected'))
);
CREATE TABLE dbo.TraoDoiHoTro (
    Id INT IDENTITY CONSTRAINT PK_TraoDoiHoTro PRIMARY KEY,
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
CREATE TABLE dbo.ViTriKhachHang (
    DonHangId INT CONSTRAINT PK_ViTriKhachHang PRIMARY KEY CONSTRAINT FK_ViTriKhachHang_Don REFERENCES dbo.DonHang(Id),
    KhachHangId INT NOT NULL CONSTRAINT FK_ViTriKhachHang_Khach REFERENCES dbo.NguoiDung(Id),
    ViDo DECIMAL(10,7) NOT NULL,
    KinhDo DECIMAL(10,7) NOT NULL,
    NgayCapNhat DATETIME2(3) NOT NULL CONSTRAINT DF_ViTriKhachHang_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_ViTriKhachHang_GPS CHECK (ViDo BETWEEN -90 AND 90 AND KinhDo BETWEEN -180 AND 180)
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
CREATE TABLE dbo.XacThucOTP (
    Id UNIQUEIDENTIFIER CONSTRAINT PK_XacThucOTP PRIMARY KEY,
    MucDich VARCHAR(30) NOT NULL,
    DiaChiNhan NVARCHAR(254) NOT NULL,
    MaBam CHAR(64) NOT NULL,
    SoLanThu INT NOT NULL CONSTRAINT DF_XacThucOTP_LanThu DEFAULT 0,
    DaSuDung BIT NOT NULL CONSTRAINT DF_XacThucOTP_DaSuDung DEFAULT 0,
    NgayHetHan DATETIME2(3) NOT NULL,
    NgayTao DATETIME2(3) NOT NULL CONSTRAINT DF_XacThucOTP_Ngay DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_XacThucOTP_LanThu CHECK (SoLanThu BETWEEN 0 AND 5),
    CONSTRAINT CK_XacThucOTP_MaBam CHECK (LEN(MaBam) = 64 AND MaBam NOT LIKE '%[^0-9a-f]%')
);
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
CREATE UNIQUE INDEX UX_DeXuatVatTu_DangApDung ON dbo.DeXuatVatTu(DonHangId) WHERE DangApDung = 1;
CREATE UNIQUE INDEX UX_NghiemThu_Don ON dbo.PhieuNghiemThu(DonHangId) WHERE TrangThai <> 'Rejected';
CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieu ON dbo.ThanhToan(MaThamChieu) WHERE MaThamChieu IS NOT NULL;
CREATE UNIQUE INDEX UX_YeuCauThanhToan_DangCho ON dbo.YeuCauThanhToan(DonHangId) WHERE TrangThai = 'Pending';
CREATE UNIQUE INDEX UX_HoSoKTV_DangCho ON dbo.HoSoKTV(NguoiDungId) WHERE TrangThai = 'Pending';
CREATE INDEX IX_DonHang_Khach_TrangThai ON dbo.DonHang(KhachHangId, TrangThai) INCLUDE (DichVuId, KyThuatVienId, NgayTao);
CREATE INDEX IX_DonHang_Tho_TrangThai ON dbo.DonHang(KyThuatVienId, TrangThai) INCLUDE (KhachHangId, NgayTao);
CREATE INDEX IX_DonHang_TrangThai_Ngay ON dbo.DonHang(TrangThai, NgayTao DESC);
CREATE INDEX IX_LichSuDonHang_Don_Ngay ON dbo.LichSuDonHang(DonHangId, NgayTao, Id);
CREATE INDEX IX_ChiTietDeXuatVatTu_DeXuat ON dbo.ChiTietDeXuatVatTu(DeXuatVatTuId) INCLUDE (ThanhTien, SoThangBaoHanh);
CREATE INDEX IX_GiaoDichVi_Tho_Ngay ON dbo.GiaoDichVi(KyThuatVienId, NgayTao DESC) INCLUDE (SoTien, Loai);
CREATE INDEX IX_YeuCauVi_TrangThai_Ngay ON dbo.YeuCauVi(TrangThai, NgayTao) INCLUDE (KyThuatVienId, SoTien);
CREATE INDEX IX_YeuCauHoTro_TrangThai ON dbo.YeuCauHoTro(TrangThai, NgayTao) INCLUDE (DonHangId, KhachHangId);
CREATE INDEX IX_TraoDoiHoTro_YeuCau ON dbo.TraoDoiHoTro(YeuCauHoTroId, NgayTao);
CREATE INDEX IX_ThongBao_Nguoi_DaDoc ON dbo.ThongBao(NguoiDungId, DaDoc, NgayTao DESC);
CREATE INDEX IX_TepDinhKem_Don ON dbo.TepDinhKem(DonHangId, MucDich) INCLUDE (ChuSoHuuId);
CREATE INDEX IX_XacThucOTP_HetHan ON dbo.XacThucOTP(NgayHetHan);
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
    WHERE (@TuNgay IS NULL OR NgayTao >= @TuNgay)
        AND (@DenNgay IS NULL OR NgayTao < DATEADD(DAY, 1, CONVERT(DATETIME2, @DenNgay)))
);
GO
CREATE OR ALTER FUNCTION dbo.fn_HanBaoHanh (@DonHangId INT)
RETURNS TABLE
AS
RETURN (
    SELECT MAX(CASE WHEN ct.SoThangBaoHanh > 0 THEN DATEADD(MONTH, ct.SoThangBaoHanh, nt.NgayDuyet) END) AS HanBaoHanh
    FROM dbo.PhieuNghiemThu AS nt
    LEFT JOIN dbo.ChiTietDeXuatVatTu AS ct ON ct.DeXuatVatTuId = nt.DeXuatVatTuId
    WHERE nt.DonHangId = @DonHangId AND nt.TrangThai = 'Approved'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_TongTienDonHang (@DonHangId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18,2);
    SELECT @TongTien = TongTien FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai <> 'Rejected';
    IF @TongTien IS NULL
    BEGIN
        SELECT @TongTien = bg.TongTien + COALESCE((
            SELECT SUM(ct.ThanhTien)
            FROM dbo.DeXuatVatTu AS dx
            INNER JOIN dbo.ChiTietDeXuatVatTu AS ct ON ct.DeXuatVatTuId = dx.Id
            WHERE dx.DonHangId = @DonHangId AND dx.DangApDung = 1 AND dx.TrangThai = 'Approved'
        ), 0)
        FROM dbo.BaoGiaSoBo AS bg WHERE bg.DonHangId = @DonHangId AND bg.TrangThai = 'Approved';
    END;
    RETURN COALESCE(@TongTien, 0);
END;
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
    ktv.TrangThaiSanSang, ktv.SoDu, ktv.ViDo, ktv.KinhDo, ktv.PhienBan
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
CREATE OR ALTER VIEW dbo.vw_DeXuatVatTu
AS
SELECT Id, DonHangId, LanSuaDoi, DangApDung, TrangThai, NguoiTaoId, NgayTao, PhienBan
FROM dbo.DeXuatVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietDeXuatVatTu
AS
SELECT Id, DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh, ThanhTien
FROM dbo.ChiTietDeXuatVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_PhieuNghiemThu
AS
SELECT Id, DonHangId, KyThuatVienId, DeXuatVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, NgayDuyet, NgayTao, PhienBan
FROM dbo.PhieuNghiemThu;
GO
CREATE OR ALTER VIEW dbo.vw_ThanhToan
AS
SELECT Id, DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId, NgayTao
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
SELECT Id, DonHangId, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai, NgayTao, PhienBan
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
SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, TrangThai, LyDo, NgayTao, PhienBan
FROM dbo.HoSoKTV;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauHoTro
AS
SELECT Id, DonHangId, KhachHangId, Loai, MoTa, TrangThai, KetQuaXuLy, NguoiXuLyId, NgayTao, PhienBan
FROM dbo.YeuCauHoTro;
GO
CREATE OR ALTER VIEW dbo.vw_TraoDoiHoTro
AS
SELECT Id, YeuCauHoTroId, NguoiGuiId, NoiDung, NgayTao
FROM dbo.TraoDoiHoTro;
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
CREATE OR ALTER VIEW dbo.vw_ViTriKhachHang
AS
SELECT DonHangId, KhachHangId, ViDo, KinhDo, NgayCapNhat
FROM dbo.ViTriKhachHang;
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
SELECT Id, NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet, NgayTao
FROM dbo.NhatKy;
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
SELECT dh.Id, dh.KhachHangId, kh.HoTen AS TenKhachHang, kh.SoDienThoai AS SDTKhachHang,
    dh.DichVuId, dh.TenDichVu, dh.DiaChi, dh.MoTa, dh.NgayHen, dh.TrangThai,
    dh.KyThuatVienId, ktv.HoTen AS TenKyThuatVien, ktv.SoDienThoai AS SDTKyThuatVien,
    dh.NgayTao, dh.NgayCapNhat, dh.PhienBan, dbo.fn_TongTienDonHang(dh.Id) AS TongTien,
    (SELECT HanBaoHanh FROM dbo.fn_HanBaoHanh(dh.Id)) AS HanBaoHanh
FROM dbo.DonHang AS dh
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
SELECT CONVERT(DATE, tt.NgayTao) AS Ngay, COUNT_BIG(*) AS SoDon,
    SUM(tt.SoTien) AS TongThu, SUM(CASE WHEN tt.PhuongThuc = 'COD' THEN tt.SoTien ELSE 0 END) AS ThuCOD,
    SUM(CASE WHEN tt.PhuongThuc = 'BANK' THEN tt.SoTien ELSE 0 END) AS ThuNganHang,
    SUM(ds.TienHoaHong) AS TienHoaHong,
    SUM(CASE WHEN ds.TrangThai = 'Confirmed' THEN ds.TienHoaHong ELSE 0 END) AS HoaHongDaDoiSoat
FROM dbo.ThanhToan AS tt
INNER JOIN dbo.DoiSoat AS ds ON ds.ThanhToanId = tt.Id
GROUP BY CONVERT(DATE, tt.NgayTao);
GO
CREATE OR ALTER VIEW dbo.vw_ViKyThuatVien
AS
SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe, ktv.KhuVucPhucVu,
    ktv.TrangThaiSanSang, ktv.SoDu, (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS SoDuSoCai,
    ktv.SoDu - (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS ChenhLech, ktv.ViDo, ktv.KinhDo, ktv.PhienBan
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
CREATE OR ALTER VIEW dbo.vw_HoTroCanXuLy
AS
SELECT ht.Id, ht.DonHangId, ht.KhachHangId, nd.HoTen AS TenKhachHang,
    ht.Loai, ht.MoTa, ht.TrangThai, ht.KetQuaXuLy, ht.NguoiXuLyId, ht.NgayTao, ht.PhienBan
FROM dbo.YeuCauHoTro AS ht
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ht.KhachHangId
WHERE ht.TrangThai IN ('Open','InProgress');
GO
CREATE OR ALTER VIEW dbo.vw_XacThucOTP
AS
SELECT Id, MucDich, DiaChiNhan, SoLanThu, DaSuDung, NgayHetHan, NgayTao
FROM dbo.XacThucOTP;
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
   Các hàm băm bcrypt/OTP được tính ở backend; SQL không lưu mật khẩu/OTP rõ. */
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

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTho
    @NguoiThucHienId INT, @NhomTayNghe NVARCHAR(200), @KhuVucPhucVu NVARCHAR(200),
    @ViDo DECIMAL(10,7) = NULL, @KinhDo DECIMAL(10,7) = NULL
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

        UPDATE dbo.KyThuatVien SET NhomTayNghe = @NhomTayNghe, KhuVucPhucVu = @KhuVucPhucVu,
            ViDo = @ViDo, KinhDo = @KinhDo WHERE Id = @NguoiThucHienId;
        IF @@ROWCOUNT = 0 THROW 51004, N'Chưa có hồ sơ kỹ thuật viên.', 1;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, ViDo, KinhDo, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
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
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, ViDo, KinhDo, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
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
    @KinhNghiem NVARCHAR(2000)
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
        INSERT INTO dbo.HoSoKTV(NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem)
        VALUES (@NguoiThucHienId, @NhomTayNghe, @KhuVucPhucVu, @KinhNghiem);
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

CREATE OR ALTER PROCEDURE dbo.sp_TaoMaOTP
    @Id UNIQUEIDENTIFIER, @MucDich VARCHAR(30), @DiaChiNhan NVARCHAR(254),
    @MaBam CHAR(64), @NgayHetHan DATETIME2(3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_TaoMaOTP;

        IF @NgayHetHan <= SYSUTCDATETIME() OR @NgayHetHan > DATEADD(MINUTE, 15, SYSUTCDATETIME())
            THROW 51009, N'OTP chỉ có thời hạn tối đa 15 phút.', 1;
        IF @MucDich NOT IN ('Register','ResetPassword') THROW 51009, N'Mục đích OTP không hợp lệ.', 1;
        INSERT INTO dbo.XacThucOTP(Id, MucDich, DiaChiNhan, MaBam, NgayHetHan)
        VALUES (@Id, @MucDich, @DiaChiNhan, @MaBam, @NgayHetHan);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, MucDich, DiaChiNhan, NgayHetHan, DaSuDung FROM dbo.vw_XacThucOTP WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_TaoMaOTP;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacThucOTP
    @Id UNIQUEIDENTIFIER, @MaBam CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_XacThucOTP;

        DECLARE @DaXacThuc BIT = 0;
        DECLARE @MaDung CHAR(64), @SoLanThu INT, @DaSuDung BIT, @HetHan DATETIME2(3);
        SELECT @MaDung = MaBam, @SoLanThu = SoLanThu, @DaSuDung = DaSuDung, @HetHan = NgayHetHan
        FROM dbo.XacThucOTP WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id;
        IF @MaDung IS NOT NULL AND @DaSuDung = 0 AND @SoLanThu < 5 AND @HetHan > SYSUTCDATETIME()
        BEGIN
            SET @DaXacThuc = CASE WHEN @MaDung = @MaBam THEN 1 ELSE 0 END;
            UPDATE dbo.XacThucOTP SET SoLanThu = SoLanThu + 1, DaSuDung = @DaXacThuc WHERE Id = @Id;
        END;
        -- Sai OTP vẫn COMMIT số lần thử. Không THROW làm mất bộ đếm chống dò mã.
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT @DaXacThuc AS DaXacThuc;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_XacThucOTP;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DonDepOTPHetHan

AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DonDepOTPHetHan;

        DELETE FROM dbo.XacThucOTP WHERE NgayHetHan <= SYSUTCDATETIME() OR DaSuDung = 1;
        DECLARE @SoDong INT = @@ROWCOUNT;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT @SoDong AS SoDongDaXoa;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DonDepOTPHetHan;
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
        IF @MucDich IN ('OrderFault','AcceptancePhoto','CustomerSignature','TechnicianSignature','PaymentProof') AND @DonHangId IS NULL
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

CREATE OR ALTER PROCEDURE dbo.sp_GhiNhatKyVaThongBao
    @NguoiThucHienId INT, @ThaoTac NVARCHAR(100), @DoiTuong NVARCHAR(100),
    @DoiTuongId INT = NULL, @ChiTiet NVARCHAR(2000) = NULL, @NguoiNhanId INT = NULL,
    @TieuDe NVARCHAR(200) = NULL, @NoiDung NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_GhiNhatKyVaThongBao;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        IF @NguoiNhanId IS NOT NULL AND @NguoiNhanId <> @NguoiThucHienId
            AND NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('DPV','CSKH','KT','ADMIN'))
            THROW 51003, N'Không được gửi thông báo tùy ý đến người dùng khác.', 1;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, @ThaoTac, @DoiTuong, @DoiTuongId, @ChiTiet);
        IF @NguoiNhanId IS NOT NULL
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@TieuDe)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL
                THROW 51009, N'Thông báo cần có tiêu đề và nội dung.', 1;
            INSERT INTO dbo.ThongBao(NguoiDungId, TieuDe, NoiDung)
            VALUES (@NguoiNhanId, @TieuDe, @NoiDung);
        END;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT CONVERT(BIT, 1) AS DaGhiNhan;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_GhiNhatKyVaThongBao;
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
        IF @Khoa = 'TaiKhoanNganHangMacDinh' AND NOT EXISTS (
            SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = TRY_CONVERT(INT, @GiaTri) AND DangHoatDong = 1
        ) THROW 51009, N'Tài khoản ngân hàng mặc định phải đang hoạt động.', 1;
        IF EXISTS (SELECT 1 FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa)
            UPDATE dbo.CauHinh SET GiaTri = @GiaTri, NhanHienThi = @NhanHienThi WHERE Khoa = @Khoa;
        ELSE INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES (@Khoa, @GiaTri, @NhanHienThi);
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
    @NgayHen DATETIME2 = NULL
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
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen)
        VALUES (@NguoiThucHienId, @DichVuId, @TenDichVu, LTRIM(RTRIM(@DiaChi)), @MoTa, @NgayHen);
        DECLARE @Id INT = SCOPE_IDENTITY();
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
        IF @TrangThai <> 'ChoTiepNhan'
            THROW 51009, N'Chi bao gia khi don dang cho tiep nhan.', 1;
        IF @PhiKiemTra IS NULL OR @TienCong IS NULL OR @TyLeHoaHong IS NULL
           OR @PhiKiemTra NOT BETWEEN 0 AND 1000000000 OR @TienCong NOT BETWEEN 0 AND 1000000000
           OR @PhiKiemTra + @TienCong <= 0
           OR @TyLeHoaHong < 0 OR @TyLeHoaHong > 100
           OR NULLIF(LTRIM(RTRIM(@ChanDoan)), N'') IS NULL
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
        VALUES (@DonHangId, @TrangThai, 'ChoDuyetSoBo', @NguoiThucHienId, N'Gui bao gia so bo cho khach hang.');
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
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE Id = @BaoGiaId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay bao gia.', 1;
        SELECT @ChuSoHuuId = KhachHangId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND TrangThai = 'ChoDuyetSoBo';
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
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
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
        IF @TrangThaiTiepTheo = 'Huy'
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
                THROW 51009, N'Phai nhap ly do huy don.', 1;
            IF NOT ((@VaiTro = 'KH' AND @KhachHangId = @NguoiThucHienId
                    AND @TrangThai IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan'))
                OR (@VaiTro IN ('DPV', 'ADMIN') AND @TrangThai IN
                    ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi')))
                THROW 51003, N'Khong duoc huy don tai trang thai hien tai.', 1;
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
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiTiepTheo, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, @TrangThaiTiepTheo, @NguoiThucHienId, COALESCE(@LyDo, N'Cap nhat tien do thi cong.'));
        DECLARE @Id INT = @DonHangId;
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

CREATE OR ALTER PROCEDURE dbo.sp_LuuViTriKhachHang
    @NguoiThucHienId INT,
    @DonHangId INT,
    @ViDo DECIMAL(10,7),
    @KinhDo DECIMAL(10,7)
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
            SAVE TRANSACTION sp_LuuViTriKhachHang;
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

        IF @ViDo IS NULL OR @KinhDo IS NULL OR @ViDo NOT BETWEEN -90 AND 90 OR @KinhDo NOT BETWEEN -180 AND 180
            THROW 51009, N'Toa do GPS khong hop le.', 1;
        DECLARE @KhachHangId INT, @TrangThai VARCHAR(30);
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KhachHangId <> @NguoiThucHienId THROW 51003, N'Chi chu don hang duoc chia se vi tri.', 1;
        IF @TrangThai IN ('HoanThanh', 'Huy') THROW 51009, N'Don hang da ket thuc.', 1;
        IF EXISTS (SELECT 1 FROM dbo.ViTriKhachHang WHERE DonHangId = @DonHangId)
            UPDATE dbo.ViTriKhachHang
            SET ViDo = @ViDo, KinhDo = @KinhDo, NgayCapNhat = SYSUTCDATETIME() WHERE DonHangId = @DonHangId;
        ELSE
            INSERT INTO dbo.ViTriKhachHang (DonHangId, KhachHangId, ViDo, KinhDo)
            VALUES (@DonHangId, @NguoiThucHienId, @ViDo, @KinhDo);
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT DonHangId, KhachHangId, ViDo, KinhDo, NgayCapNhat
        FROM dbo.ViTriKhachHang
        WHERE DonHangId = @DonHangId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuViTriKhachHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDeXuatVatTu
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
            SAVE TRANSACTION sp_TaoDeXuatVatTu;
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
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc de xuat vat tu.', 1;
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
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        UPDATE dbo.DeXuatVatTu SET DangApDung = 0 WHERE DonHangId = @DonHangId AND DangApDung = 1;
        INSERT INTO dbo.DeXuatVatTu (DonHangId, LanSuaDoi, DangApDung, TrangThai, NguoiTaoId)
        VALUES (@DonHangId, @LanSuaDoi, 1, 'Pending', @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.ChiTietDeXuatVatTu (DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        SELECT @Id, LTRIM(RTRIM(v.Ten)), v.SoLuong, v.DonGia, ISNULL(v.SoThangBaoHanh, 0)
        FROM OPENJSON(@VatTu) WITH (
            Ten NVARCHAR(200) '$.Ten', SoLuong DECIMAL(10,2) '$.SoLuong',
            DonGia DECIMAL(18,2) '$.DonGia', SoThangBaoHanh INT '$.SoThangBaoHanh') AS v;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, TrangThai, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.DeXuatVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDeXuatVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemChiTietVatTu
    @NguoiThucHienId INT,
    @DeXuatVatTuId INT,
    @Ten NVARCHAR(200),
    @SoLuong DECIMAL(10,2),
    @DonGia DECIMAL(18,2),
    @SoThangBaoHanh INT = 0,
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
            SAVE TRANSACTION sp_ThemChiTietVatTu;
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

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT, @Id INT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @HoatDong = DangApDung
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DeXuatVatTuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay de xuat vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
            THROW 51009, N'Chi duoc them vat tu vao de xuat hien hanh chua duyet.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KyThuatVienId = @NguoiThucHienId AND TrangThai = 'DangXuLy')
            THROW 51003, N'Khong duoc sua vat tu cua don nay.', 1;
        IF NULLIF(LTRIM(RTRIM(@Ten)), N'') IS NULL OR @SoLuong IS NULL OR @SoLuong NOT BETWEEN 0.01 AND 1000
           OR @DonGia IS NULL OR @DonGia NOT BETWEEN 0 AND 1000000000
           OR @SoThangBaoHanh IS NULL OR @SoThangBaoHanh NOT BETWEEN 0 AND 120
            THROW 51009, N'Thong tin vat tu khong hop le.', 1;
        INSERT INTO dbo.ChiTietDeXuatVatTu (DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        VALUES (@DeXuatVatTuId, LTRIM(RTRIM(@Ten)), @SoLuong, @DonGia, @SoThangBaoHanh);
        SET @Id = SCOPE_IDENTITY();
        -- Cham vao phien ban de phien ban cu khong the duyet danh sach moi.
        UPDATE dbo.DeXuatVatTu SET DangApDung = DangApDung WHERE Id = @DeXuatVatTuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh, ThanhTien
        FROM dbo.ChiTietDeXuatVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemChiTietVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachDuyetDeXuatVatTu
    @NguoiThucHienId INT,
    @DeXuatVatTuId INT,
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
            SAVE TRANSACTION sp_KhachDuyetDeXuatVatTu;
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

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @HoatDong = DangApDung
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DeXuatVatTuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay de xuat vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
            THROW 51009, N'De xuat da thay doi hoac da duoc xu ly.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'DangXuLy')
            THROW 51003, N'Chi khach hang cua don dang xu ly duoc duyet vat tu.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Approved', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ChiTietDeXuatVatTu WHERE DeXuatVatTuId = @DeXuatVatTuId)
            THROW 51009, N'De xuat phai co it nhat mot dong vat tu.', 1;
        UPDATE dbo.DeXuatVatTu SET TrangThai = @QuyetDinh WHERE Id = @DeXuatVatTuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'DuyetVatTu', N'DeXuatVatTu', @DeXuatVatTuId, COALESCE(@LyDo, @QuyetDinh));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, TrangThai, PhienBan
        FROM dbo.DeXuatVatTu
        WHERE Id = @DeXuatVatTuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachDuyetDeXuatVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoPhieuNghiemThu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NguyenNhan NVARCHAR(2000),
    @PhuongAnXuLy NVARCHAR(2000),
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
        DECLARE @DeXuatId INT, @TrangThaiVatTu VARCHAR(20), @TienVatTu DECIMAL(18,2) = 0;
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
        SELECT @DeXuatId = Id, @TrangThaiVatTu = TrangThai
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND DangApDung = 1;
        IF @TrangThaiVatTu = 'Pending' THROW 51009, N'Can khach hang duyet vat tu truoc khi nghiem thu.', 1;
        IF @TrangThaiVatTu = 'Approved'
            SELECT @TienVatTu = ISNULL(SUM(ThanhTien), 0)
            FROM dbo.ChiTietDeXuatVatTu WHERE DeXuatVatTuId = @DeXuatId;
        ELSE SET @DeXuatId = NULL;
        IF EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Don hang da co phieu nghiem thu hien hanh.', 1;
        INSERT INTO dbo.PhieuNghiemThu (DonHangId, KyThuatVienId, DeXuatVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TrangThai)
        VALUES (@DonHangId, @KTVId, @DeXuatId, @NguyenNhan, @PhuongAnXuLy, @PhiKiemTra, @TienCong, @TienVatTu, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.DonHang SET TrangThai = 'ChoNghiemThu', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNghiemThu', @NguoiThucHienId, N'Ky thuat vien lap phieu nghiem thu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, DeXuatVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, PhienBan
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
        UPDATE dbo.PhieuNghiemThu
        SET ChuKyKHId = @ChuKyId, PhuongThucThanhToan = @PhuongThucThanhToan,
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

        DECLARE @NghiemThuId INT, @SoTien DECIMAL(18,2), @Id INT;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'ChoNghiemThu')
            THROW 51003, N'Chi chu don hang dang cho thanh toan duoc gui yeu cau.', 1;
        SELECT @NghiemThuId = Id, @SoTien = TongTien
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
            AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
        IF @NghiemThuId IS NULL THROW 51009, N'Chua co phieu nghiem thu du chu ky va chon BANK.', 1;
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
        INSERT INTO dbo.YeuCauThanhToan (DonHangId, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai)
        VALUES (@DonHangId, @NghiemThuId, @NguoiThucHienId, @TaiKhoanNganHangId, @SoTien, @ChungTuId, LTRIM(RTRIM(@MaThamChieu)), 'Pending');
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
        SELECT @DonHangId = DonHangId, @NghiemThuId = NghiemThuId, @TaiKhoanId = TaiKhoanNganHangId,
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
            SELECT @KTVId = KyThuatVienId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND TrangThai = 'ChoNghiemThu';
            IF @KTVId IS NULL THROW 51009, N'Don hang khong con cho thanh toan.', 1;
            SELECT @TienCong = TienCong FROM dbo.PhieuNghiemThu WITH (HOLDLOCK)
            WHERE Id = @NghiemThuId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                AND TongTien = @SoTien AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
            IF @TienCong IS NULL THROW 51009, N'Nghiem thu khong hop le.', 1;
            IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId OR MaThamChieu = @ThamChieu)
                THROW 51009, N'Don hoac ma tham chieu nay da duoc thanh toan.', 1;
            SELECT @TyLe = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
            INSERT INTO dbo.ThanhToan (DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId)
            VALUES (@DonHangId, @NghiemThuId, @SoTien, 'BANK', @NguoiThucHienId, @ThamChieu, @TaiKhoanId);
            SET @Id = SCOPE_IDENTITY();
            INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
            VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLe, 'Pending');
            UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
            UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
            UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
            INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
            VALUES (@DonHangId, 'ChoNghiemThu', 'HoanThanh', @NguoiThucHienId, N'Ke toan xac nhan da nhan du chuyen khoan.');
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
        SELECT @SoTien = SoTien, @PhuongThuc = PhuongThuc FROM dbo.ThanhToan WHERE Id = @ThanhToanId;
        -- COD: tho giu tien mat, tru hoa hong trong vi. BANK: cong tien tho duoc huong.
        SET @BienDong = CASE WHEN @PhuongThuc = 'COD' THEN -@TienHoaHong ELSE @SoTien - @TienHoaHong END;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2);
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
        IF @SoDu IS NULL THROW 51004, N'Khong tim thay vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @KTVId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @SoDu + @BienDong - @DangChoRut < 0
            THROW 51009, N'Vi khong du so du kha dung de tru hoa hong. Can nap tien hoac xu ly yeu cau rut dang cho.', 1;
        IF @BienDong <> 0
        BEGIN
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, CASE WHEN @PhuongThuc = 'COD' THEN 'Commission' ELSE 'SettlementCredit' END,
                @BienDong, 'DoiSoat', @DoiSoatId, @NguoiThucHienId, N'Doi soat thanh toan don hang.');
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

        DECLARE @PhienBan BINARY(8), @TrangThaiCu VARCHAR(20);
        SELECT @PhienBan = PhienBan, @TrangThaiCu = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Yeu cau ho tro da thay doi.', 1;
        IF @TrangThai IS NULL OR NOT ((@TrangThaiCu = 'Open' AND @TrangThai IN ('InProgress', 'Rejected'))
            OR (@TrangThaiCu = 'InProgress' AND @TrangThai IN ('Resolved', 'Rejected')))
            THROW 51009, N'Thu tu xu ly: Open -> InProgress -> Resolved; co the tu choi yeu cau chua dong.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') AND NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N'') IS NULL
            THROW 51009, N'Can ghi ket qua hoac ly do tu choi.', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai = @TrangThai, KetQuaXuLy = @KetQuaXuLy, NguoiXuLyId = @NguoiThucHienId
        WHERE Id = @YeuCauHoTroId;
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

        DECLARE @KhachHangId INT, @TrangThai VARCHAR(20), @Id INT;
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId
            THROW 51003, N'Khong duoc xem hoac trao doi ho tro cua khach hang khac.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') THROW 51009, N'Yeu cau ho tro da dong.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung trao doi khong duoc rong.', 1;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @NoiDung);
        SET @Id = SCOPE_IDENTITY();
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
             OR (d.TrangThai = 'ChoPhanCong' AND i.TrangThai = 'ChoNhan')
             OR (d.TrangThai = 'ChoNhan' AND i.TrangThai IN ('DaTiepNhan','ChoPhanCong'))
             OR (d.TrangThai = 'DaTiepNhan' AND i.TrangThai = 'DangDiChuyen')
             OR (d.TrangThai = 'DangDiChuyen' AND i.TrangThai = 'DaDenNoi')
             OR (d.TrangThai = 'DaDenNoi' AND i.TrangThai = 'DangXuLy')
             OR (d.TrangThai = 'DangXuLy' AND i.TrangThai = 'ChoNghiemThu')
             OR (d.TrangThai = 'ChoNghiemThu' AND i.TrangThai = 'HoanThanh')
             OR (d.TrangThai IN ('ChoTiepNhan','ChoDuyetSoBo','ChoPhanCong','ChoNhan','DaTiepNhan','DangDiChuyen','DaDenNoi') AND i.TrangThai = 'Huy')
           ))
    ) THROW 51009, N'Trạng thái đơn không được chuyển theo bước này.', 1;
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
        INNER JOIN dbo.PhieuNghiemThu AS nt ON nt.Id = i.NghiemThuId
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        WHERE nt.DonHangId <> i.DonHangId OR nt.TrangThai <> 'Approved'
           OR nt.TongTien <> i.SoTien OR nt.PhuongThucThanhToan <> i.PhuongThuc
           OR dh.TrangThai <> 'ChoNghiemThu'
    ) THROW 51009, N'Thanh toán phải khớp nghiệm thu đã được khách và thợ ký.', 1;
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
CREATE OR ALTER TRIGGER dbo.tr_ChiTietVatTu_KhoaDaDuyet
ON dbo.ChiTietDeXuatVatTu AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM dbo.DeXuatVatTu AS dx
        WHERE dx.TrangThai <> 'Pending' AND (
            EXISTS (SELECT 1 FROM inserted AS i WHERE i.DeXuatVatTuId = dx.Id)
            OR EXISTS (SELECT 1 FROM deleted AS d WHERE d.DeXuatVatTuId = dx.Id)
        )
    ) THROW 51009, N'Vật tư đã duyệt/từ chối phải lập phiên bản đề xuất mới.', 1;
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
/* 7 role nghiệp vụ + role kỹ thuật nội bộ phục vụ đăng nhập/OTP.
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
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DeXuatVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ChiTietDeXuatVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
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
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ViTriKhachHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.NhatKy TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.CauHinh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.XacThucOTP TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KH;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KTV;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_DPV;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_CSKH;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KT;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_GD;
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
GRANT SELECT ON OBJECT::dbo.vw_DeXuatVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietDeXuatVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_ADMIN;
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
GRANT SELECT ON OBJECT::dbo.vw_XacThucOTP TO HomeFix_UngDung;
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
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTho TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTrangThaiKTV TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_GuiHoSoKTV TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetHoSoKTV TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoMaOTP TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_XacThucOTP TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_DonDepOTPHetHan TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTepDinhKem TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_GhiNhatKyVaThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
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
GRANT EXECUTE ON OBJECT::dbo.sp_LuuViTriKhachHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoDeXuatVatTu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemChiTietVatTu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_KhachDuyetDeXuatVatTu TO HomeFix_KH;
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
   1 tài khoản ngân hàng MÔ PHỎNG và cấu hình. KHÔNG có đơn/OTP/sổ cái/nhật ký.
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
    SELECT Id, N'Điện, Nước, Điện lạnh', N'Thành phố Hồ Chí Minh', 'SanSang', 0 FROM dbo.NguoiDung WHERE VaiTro = 'KTV';
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

-- MODULE: 09_data_migration.sql
-- Phiên bản này dùng schema mới và seed sạch trên database mới.
-- Không tự chuyển dữ liệu giao dịch từ bản HomeFix cũ vào bản học tập.
-- Bộ cài CSDL_HomeFix.sql từ chối database đã tồn tại.
-- Khi cần giữ dữ liệu thật, lập kế hoạch chuyển đổi và kiểm tra riêng từ bản backup.
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
/* CÁCH DEMO TRONG SSMS - chạy từng khối sau khi sửa tên database/đường dẫn:

-- 1. Chọn database muốn sao lưu, ghi nhận recovery model trước khi thay đổi.
SELECT name, recovery_model_desc FROM sys.databases WHERE name = DB_NAME();
-- Dùng đường dẫn tồn tại, service account SQL có quyền ghi. Ví dụ D:\SQLBackup.
-- Không chạy trên database đang có giao dịch nghiệp vụ ngoài ý muốn.
ALTER DATABASE HomeFix_DBMS_Sach SET RECOVERY FULL;
GO
USE HomeFix_DBMS_Sach;
GO
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Full_20261022.bak', @Loai = 'FULL';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Diff_20261022.bak', @Loai = 'DIFF';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = N'D:\SQLBackup\HomeFix_Log_20261022.trn', @Loai = 'LOG';

-- 2. Xem thông tin backup set/logical name và kiểm tra backup có đọc được.
-- FILE = 1 phù hợp tập tin mới. Nếu đã backup nhiều lần cùng tập tin,
-- RESTORE HEADERONLY để chọn đúng Position, không mặc định bản mới nhất ở số 1.
RESTORE HEADERONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261022.bak';
RESTORE FILELISTONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261022.bak' WITH FILE = 1;
RESTORE VERIFYONLY FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261022.bak' WITH FILE = 1, CHECKSUM;
-- VERIFYONLY kiểm tra backup; chưa chứng minh toàn bộ CSDL phục hồi hoạt động.

-- 3. Khôi phục ra TÊN MỚI, không WITH REPLACE. Sửa logical name theo FILELISTONLY.
USE master;
GO
RESTORE DATABASE HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Full_20261022.bak'
WITH FILE = 1, NORECOVERY,
    MOVE N'HomeFix_DBMS_Sach' TO N'D:\SQLData\HomeFix_KiemTraPhucHoi.mdf',
    MOVE N'HomeFix_DBMS_Sach_log' TO N'D:\SQLData\HomeFix_KiemTraPhucHoi_log.ldf';
RESTORE DATABASE HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Diff_20261022.bak' WITH FILE = 1, NORECOVERY;
RESTORE LOG HomeFix_KiemTraPhucHoi
FROM DISK = N'D:\SQLBackup\HomeFix_Log_20261022.trn' WITH FILE = 1, RECOVERY;
-- Nếu chỉ phục hồi FULL: thay NORECOVERY bằng RECOVERY ở lệnh FULL và bỏ DIFF/LOG.
-- Nếu cần tới một thời điểm: thêm STOPAT = '2026-10-22T14:30:00' vào RESTORE LOG.
-- FULL/DIFF/LOG phải cùng chuỗi hợp lệ. COPY_ONLY FULL không lập nền cho DIFF.

-- 4. Kiểm tra CSDL được khôi phục. Không chạy web lên bản này ngoài ý muốn.
DBCC CHECKDB(N'HomeFix_KiemTraPhucHoi') WITH NO_INFOMSGS;
USE HomeFix_KiemTraPhucHoi;
SELECT Id, HoTen, VaiTro FROM dbo.vw_NguoiDung;
SELECT Id, TrangThai FROM dbo.vw_DonHangTongHop;
SELECT Id, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien;

LỖI THƯỜNG GẶP:
- 3201/Operating system error 3: sai đường dẫn trên máy SQL Server.
- Operating system error 5: service account SQL Server thiếu quyền thư mục.
- 4214: LOG chưa có full backup đầu tiên sau khi chuyển recovery model.
- 3117/4305: sai thứ tự hoặc thiếu mắt xích LOG, phải kiểm tra HEADERONLY.
- 3154: file thuộc database khác; dùng tên đích mới và MOVE đúng logical name.
- 'database is in use': cần dùng master và đóng kết nối tới bản phục hồi.
*/
