-- Kiểm tra cơ sở dữ liệu đang được chọn.
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.PhienBanCSDL', N'U') IS NULL
    THROW 51009, N'Cơ sở dữ liệu hiện tại chưa có cấu trúc HomeFix.', 1;
GO

-- Thống kê các đối tượng nghiệp vụ.
SELECT type_desc AS LoaiDoiTuong, COUNT(*) AS SoLuong
FROM sys.objects
WHERE is_ms_shipped = 0
  AND type IN ('U', 'P', 'FN', 'IF', 'TF', 'V', 'TR')
GROUP BY type_desc
ORDER BY type_desc;

SELECT COUNT(*) AS SoChiMucKhongPhaiKhoaChinh
FROM sys.indexes
WHERE name IS NOT NULL
  AND is_primary_key = 0
  AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1;

SELECT name AS VaiTro
FROM sys.database_principals
WHERE type = 'R' AND name LIKE 'HomeFix[_]%'
ORDER BY name;
GO

-- Liệt kê thủ tục có xử lý giao dịch và lỗi.
SELECT p.name AS ThuTuc
FROM sys.procedures AS p
INNER JOIN sys.sql_modules AS m ON m.object_id = p.object_id
WHERE m.definition LIKE '%BEGIN TRANSACTION%'
  AND m.definition LIKE '%COMMIT TRANSACTION%'
  AND m.definition LIKE '%ROLLBACK%'
  AND m.definition LIKE '%BEGIN CATCH%'
ORDER BY p.name;
GO

-- Tra cứu quan hệ giữa thủ tục, hàm và khung nhìn.
SELECT OBJECT_NAME(referencing_id) AS DoiTuongGoi,
       referenced_entity_name AS DoiTuongDuocGoi
FROM sys.sql_expression_dependencies
WHERE referenced_entity_name LIKE 'fn[_]%'
   OR referenced_entity_name LIKE 'vw[_]%'
ORDER BY DoiTuongGoi, DoiTuongDuocGoi;
GO

-- Tính hoa hồng và đối chiếu số dư, đánh giá kỹ thuật viên.
SELECT dbo.fn_HoaHong(300000, 15) AS TienHoaHong;

SELECT k.Id, u.HoTen, v.SoDu, d.SoDanhGia, d.DiemTrungBinh
FROM dbo.KyThuatVien AS k
INNER JOIN dbo.NguoiDung AS u ON u.Id = k.Id
CROSS APPLY dbo.fn_SoDuVi(k.Id) AS v
CROSS APPLY dbo.fn_DiemDanhGia(k.Id) AS d;

-- Tra cứu hạn bảo hành của các nghiệm thu đã duyệt.
SELECT a.Id AS NghiemThuId, a.DonHangId, b.*
FROM dbo.PhieuNghiemThu AS a
CROSS APPLY dbo.fn_HanBaoHanh(a.Id) AS b;
GO

-- So sánh kết quả hàm thống kê với thủ tục báo cáo.
DECLARE @TuNgay DATETIME2 = '2020-01-01';
DECLARE @DenNgay DATETIME2 = DATEADD(day, 1, SYSUTCDATETIME());

SELECT * FROM dbo.fn_ThongKeDon(@TuNgay, @DenNgay);
EXEC dbo.sp_BaoCaoTongHop @TuNgay = @TuNgay, @DenNgay = @DenNgay;
GO

-- Tra cứu đơn hàng qua thủ tục của khách hàng.
DECLARE @KhachHangId INT = (
    SELECT TOP (1) Id FROM dbo.NguoiDung WHERE VaiTro = 'KH' ORDER BY Id
);
EXEC dbo.sp_DonHangCuaKhach @KhachHangId = @KhachHangId;
GO

-- Truy vấn các khung nhìn nghiệp vụ.
SELECT TOP (20) * FROM dbo.vw_DonHangTongHop ORDER BY Id DESC;
SELECT TOP (20) * FROM dbo.vw_DoanhThuNgay ORDER BY NgayNghiepVu DESC;
SELECT TOP (20) * FROM dbo.vw_ViKyThuatVien ORDER BY Id;
SELECT TOP (20) * FROM dbo.vw_HieuSuatKyThuatVien ORDER BY Id;
SELECT TOP (20) * FROM dbo.vw_HoTroCanXuLy ORDER BY Id DESC;
SELECT TOP (20) * FROM dbo.vw_DichVuCongKhai ORDER BY Id;
GO
