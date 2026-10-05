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
