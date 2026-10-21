-- HomeFix / 03_view: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tổng hợp đơn hàng, khách hàng và thanh toán.
CREATE OR ALTER VIEW dbo.vw_DonHangTongHop
AS
SELECT d.*,
       u.HoTen AS TenKhachHang,
       k.HoTen AS TenKyThuatVien,
       CASE WHEN p.Id IS NULL THEN 'Unpaid' ELSE 'Paid' END AS TrangThaiThanhToan
FROM dbo.DonHang AS d
     INNER JOIN dbo.NguoiDung AS u ON u.Id = d.KhachHangId
     LEFT OUTER JOIN dbo.NguoiDung AS k ON k.Id = d.KyThuatVienDuocGiaoId
     LEFT OUTER JOIN dbo.ThanhToan AS p ON p.DonHangId = d.Id;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tổng hợp doanh thu theo ngày Việt Nam.
CREATE OR ALTER VIEW dbo.vw_DoanhThuNgay
AS
SELECT CONVERT(DATE, DATEADD(hour, 7, p.NgayThanhToan)) AS NgayNghiepVu,
       COUNT_BIG(*) AS SoDonDaThanhToan,
       SUM(p.SoTien) AS TongGiaTriGiaoDich,
       SUM(dbo.fn_HoaHong(s.TienCong, s.TyLeHoaHong)) AS DoanhThuHoaHong
FROM dbo.ThanhToan AS p
     INNER JOIN dbo.DoiSoat AS s ON s.ThanhToanId = p.Id
GROUP BY CONVERT(DATE, DATEADD(hour, 7, p.NgayThanhToan));
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Đối chiếu số dư ví với sổ giao dịch.
CREATE OR ALTER VIEW dbo.vw_ViKyThuatVien
AS
SELECT k.Id,
       u.HoTen,
       k.TrangThaiSanSang,
       k.SoDu AS SoDuLuuSan,
       v.SoDu,
       k.SoDu - v.SoDu AS ChenhLech
FROM dbo.KyThuatVien AS k
     INNER JOIN dbo.NguoiDung AS u ON u.Id = k.Id
     CROSS APPLY dbo.fn_SoDuVi(k.Id) AS v;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Tổng hợp hiệu suất và đánh giá kỹ thuật viên.
CREATE OR ALTER VIEW dbo.vw_HieuSuatKyThuatVien
AS
SELECT k.Id,
       u.HoTen,
       k.NhomTayNghe,
       r.SoDanhGia,
       r.DiemTrungBinh,
       (SELECT COUNT(*)
        FROM dbo.DonHang AS d
        WHERE d.KyThuatVienDuocGiaoId = k.Id) AS TongSoDon,
       (SELECT COUNT(*)
        FROM dbo.DonHang AS d
        WHERE d.KyThuatVienDuocGiaoId = k.Id
          AND d.TrangThai = 'HoanThanh') AS SoDonHoanThanh
FROM dbo.KyThuatVien AS k
     INNER JOIN dbo.NguoiDung AS u ON u.Id = k.Id
     CROSS APPLY dbo.fn_DiemDanhGia(k.Id) AS r;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Danh sách yêu cầu hỗ trợ chưa hoàn tất.
CREATE OR ALTER VIEW dbo.vw_HoTroCanXuLy
AS
SELECT t.Id,
       t.DonHangId,
       t.KhachHangId,
       u.HoTen AS TenKhachHang,
       t.Loai,
       t.MoTa,
       t.TrangThai,
       t.NguoiDuocGiaoId,
       t.NgayTao,
       DATEADD(hour, 24, t.NgayTao) AS HanPhanHoi
FROM dbo.YeuCauHoTro AS t
     INNER JOIN dbo.NguoiDung AS u ON u.Id = t.KhachHangId
WHERE t.TrangThai IN ('Open', 'InProgress');
GO

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Danh sách dịch vụ đang cung cấp.
CREATE OR ALTER VIEW dbo.vw_DichVuCongKhai
AS
SELECT Id,
       Ten,
       MaNhom,
       MoTa,
       PhiKiemTra,
       TienCong,
       PhoBien,
       PhiKiemTra + TienCong AS TongTienDuKien
FROM dbo.DichVu
WHERE DangHoatDong = 1;
GO
