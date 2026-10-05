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
