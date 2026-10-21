-- HomeFix / 01_index: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_NguoiDung_Email
    ON dbo.NguoiDung (Email) WHERE Email IS NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_NguoiDung_CCCD
    ON dbo.NguoiDung (CCCD) WHERE CCCD IS NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE INDEX IX_DonHang_KhachHang
    ON dbo.DonHang (KhachHangId, NgayTao DESC);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE INDEX IX_DonHang_TrangThai
    ON dbo.DonHang (TrangThai, NgayTao);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_PhanCong_DonHang
    ON dbo.LenhDieuPhoi (DonHangId) WHERE DangHoatDong = 1;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_PhanCong_KyThuatVien
    ON dbo.LenhDieuPhoi (KyThuatVienId) WHERE DangHoatDong = 1;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_VatTu_DangApDung
    ON dbo.DeXuatVatTu (DonHangId) WHERE DangApDung = 1;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_NghiemThu_ChoDuyet
    ON dbo.PhieuNghiemThu (DonHangId) WHERE TrangThai = 'Pending';
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_NghiemThu_DaDuyet
    ON dbo.PhieuNghiemThu (DonHangId) WHERE TrangThai = 'Approved';
GO

-- Nguồn: SRC/database/CSDL_HomeFix_01_BangVaRangBuoc.sql
CREATE UNIQUE INDEX UX_HoSo_ChoDuyet
    ON dbo.HoSoKTV (NguoiDungId) WHERE TrangThai = 'Pending';
GO

-- Nguồn: SRC/database/CSDL_HomeFix_04_XacThucOTP.sql
CREATE INDEX IX_XacThucOTP_DiaChiNhan
            ON dbo.XacThucOTP (DiaChiNhan, NgayTao);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE name = 'UX_ThanhToan_MaThamChieuNganHang' AND object_id = OBJECT_ID('dbo.ThanhToan'))
    -- Ngăn dùng lại mã tham chiếu ngân hàng.
    CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieuNganHang
        ON dbo.ThanhToan (TaiKhoanNganHangId, MaThamChieuNganHang) WHERE MaThamChieuNganHang IS NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
CREATE UNIQUE INDEX UX_ChuyenKhoan_DangHoatDong
            ON dbo.YeuCauThanhToan (DonHangId) WHERE DangHoatDong = 1;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
CREATE UNIQUE INDEX UX_ChuyenKhoan_NoiDung
            ON dbo.YeuCauThanhToan (NoiDungChuyenKhoan) WHERE NoiDungChuyenKhoan IS NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
CREATE UNIQUE INDEX UX_ChuyenKhoan_ChungTu
            ON dbo.YeuCauThanhToan (ChungTuId) WHERE ChungTuId IS NOT NULL;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.GiaoDichVi') AND name = 'IX_Vi_KyThuatVien_Ngay')
    -- Tăng tốc tra cứu giao dịch ví theo kỹ thuật viên và ngày.
    CREATE INDEX IX_Vi_KyThuatVien_Ngay
        ON dbo.GiaoDichVi (KyThuatVienId, NgayTao DESC)
        INCLUDE (SoTien, Loai, ThamChieuId);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.DoiSoat') AND name = 'IX_DoiSoat_TrangThai')
    -- Tăng tốc lọc đối soát theo trạng thái.
    CREATE INDEX IX_DoiSoat_TrangThai
        ON dbo.DoiSoat (TrangThai, KyThuatVienId)
        INCLUDE (TienHoaHong, ThanhToanId);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.YeuCauHoTro') AND name = 'IX_HoTro_TrangThai_Ngay')
    -- Tăng tốc tra cứu hỗ trợ theo trạng thái và ngày.
    CREATE INDEX IX_HoTro_TrangThai_Ngay
        ON dbo.YeuCauHoTro (TrangThai, NgayTao)
        INCLUDE (DonHangId, KhachHangId, Loai);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.ThanhToan') AND name = 'IX_ThanhToan_Ngay')
    -- Tăng tốc tổng hợp thanh toán theo ngày.
    CREATE INDEX IX_ThanhToan_Ngay
        ON dbo.ThanhToan (NgayThanhToan)
        INCLUDE (SoTien, PhuongThuc, DonHangId);
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.DanhGia') AND name = 'IX_DanhGia_KyThuatVien')
    -- Tăng tốc tổng hợp đánh giá kỹ thuật viên.
    CREATE INDEX IX_DanhGia_KyThuatVien
        ON dbo.DanhGia (KyThuatVienId)
        INCLUDE (DiemDanhGia);
GO
