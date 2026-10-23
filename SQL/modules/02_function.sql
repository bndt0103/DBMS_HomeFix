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
