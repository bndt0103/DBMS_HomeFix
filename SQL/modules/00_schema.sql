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
