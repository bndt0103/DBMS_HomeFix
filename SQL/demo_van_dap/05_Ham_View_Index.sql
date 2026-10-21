-- Chay tung khoi trong SSMS. Du lieu demo rieng.
USE [HomeFix_VanDap_20261022];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SELECT dbo.fn_HoaHong(200000,15) AS HoaHong30000,
       dbo.fn_HoaHong(-1,15) AS DauVaoSaiTraNULL;
DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
SELECT * FROM dbo.fn_SoDuVi(@KTV);
SELECT * FROM dbo.fn_DiemDanhGia(@KTV);
SELECT * FROM dbo.fn_HanBaoHanh(-1); -- Rong vi khong co nghiem thu nay.
SELECT * FROM dbo.fn_ThongKeDon('20260101','20270101');
SELECT TOP (10) * FROM dbo.vw_DichVuCongKhai;
SELECT * FROM dbo.vw_ViKyThuatVien; -- ChenhLech phai bang 0.
SELECT TOP (10) * FROM dbo.vw_DonHangTongHop;
SELECT TOP (10) * FROM dbo.vw_DoanhThuNgay;
SELECT TOP (10) * FROM dbo.vw_HieuSuatKyThuatVien;
SELECT TOP (10) * FROM dbo.vw_HoTroCanXuLy;
DECLARE @KH INT=(SELECT MIN(Id) FROM dbo.NguoiDung WHERE VaiTro='KH');
EXEC dbo.sp_DonHangCuaKhach @KH;
EXEC dbo.sp_BaoCaoTongHop '20260101','20270101';
GO
-- Ctrl+M trong SSMS de bat Actual Execution Plan; xem Messages cho logical reads.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DECLARE @KTV INT=(SELECT MIN(Id) FROM dbo.KyThuatVien);
SELECT NgayTao,SoTien,Loai,ThamChieuId
FROM dbo.GiaoDichVi WHERE KyThuatVienId=@KTV ORDER BY NgayTao DESC;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
-- DB nho co the duoc chon Scan; khong khang dinh luon Seek hay nhanh hon X lan.
GO
