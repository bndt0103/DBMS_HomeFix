-- HomeFix / 02_function: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tính hoa hồng từ tiền công và tỷ lệ.
CREATE OR ALTER FUNCTION dbo.fn_HoaHong
(
    @TienCongTinh DECIMAL(18, 2),
    @TyLe DECIMAL(5, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN CASE
        WHEN @TienCongTinh >= 0 AND @TyLe BETWEEN 0 AND 100
            THEN CONVERT(DECIMAL(18, 2), ROUND(@TienCongTinh * @TyLe / 100, 2))
        ELSE NULL
    END;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tính số dư từ sổ giao dịch ví.
CREATE OR ALTER FUNCTION dbo.fn_SoDuVi
(@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN
    (SELECT COALESCE(SUM(SoTien), CONVERT(DECIMAL(38, 2), 0)) AS SoDu
     FROM dbo.GiaoDichVi
     WHERE KyThuatVienId = @KyThuatVienId)
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tính số lượt và điểm đánh giá trung bình.
CREATE OR ALTER FUNCTION dbo.fn_DiemDanhGia
(@KyThuatVienId INT)
RETURNS TABLE
AS
RETURN
    (SELECT COUNT(*) AS SoDanhGia,
            AVG(CONVERT(DECIMAL(5, 2), DiemDanhGia)) AS DiemTrungBinh
     FROM dbo.DanhGia
     WHERE KyThuatVienId = @KyThuatVienId)
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tra cứu thời hạn bảo hành vật tư.
CREATE OR ALTER FUNCTION dbo.fn_HanBaoHanh
(@NghiemThuId INT)
RETURNS TABLE
AS
RETURN
    (SELECT i.Id AS VatTuId,
            i.Ten,
            i.SoThangBaoHanh,
            DATEADD(month, i.SoThangBaoHanh, a.NgayDuyet) AS NgayHetHan
     FROM dbo.PhieuNghiemThu AS a
          INNER JOIN dbo.ChiTietDeXuatVatTu AS i ON i.BaoGiaId = a.DeXuatVatTuId
     WHERE a.Id = @NghiemThuId
       AND a.TrangThai = 'Approved'
       AND i.SoThangBaoHanh > 0)
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Thống kê đơn hàng theo nhóm dịch vụ.
CREATE OR ALTER FUNCTION dbo.fn_ThongKeDon
(@TuNgay DATETIME2, @DenNgay DATETIME2)
RETURNS TABLE
AS
RETURN
    (SELECT NhomDichVu,
            COUNT(*) AS TongSoDon,
            SUM(CASE WHEN TrangThai = 'HoanThanh' THEN 1 ELSE 0 END) AS SoDonHoanThanh,
            SUM(CASE WHEN TrangThai = 'Huy' THEN 1 ELSE 0 END) AS SoDonHuy
     FROM dbo.DonHang
     WHERE NgayTao >= @TuNgay AND NgayTao < @DenNgay
     GROUP BY NhomDichVu)
GO
