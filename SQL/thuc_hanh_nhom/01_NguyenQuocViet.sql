USE [HomeFix_DBMS_Clean_20261022];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF @@TRANCOUNT <> 0 THROW 51999, N'Hãy kết thúc giao dịch cũ trước khi thực hành.', 1;
GO
/* NGUYỄN QUỐC VIỆT - 24110381. Module 00, 01, 08.
   Chạy phần đầu file trước, sau đó chọn trọn từng khối V01..V06 và F5.
   Quyền chạy: DBA trong SSMS. UPDATE/INSERT trực tiếp bên dưới chỉ để thử
   ràng buộc; backend vẫn ghi qua SP. Các thay đổi nghiệp vụ đều rollback. */

-- V01. CẤU TRÚC: bảng, khóa chính, khóa ngoại, miền giá trị.
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL;
SELECT name AS TenBang FROM sys.tables ORDER BY name;
SELECT c.name AS Cot, TYPE_NAME(c.user_type_id) AS Kieu, c.max_length AS SoByte,
    c.is_nullable AS ChoPhepNull, c.is_identity AS TuTang
FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.DonHang') ORDER BY c.column_id;
SELECT name AS Khoa, type_desc AS Loai FROM sys.key_constraints
WHERE parent_object_id IN (OBJECT_ID('dbo.NguoiDung'), OBJECT_ID('dbo.DonHang'));
SELECT name AS KhoaNgoai, OBJECT_NAME(parent_object_id) AS BangCon,
    OBJECT_NAME(referenced_object_id) AS BangCha FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('dbo.DonHang');
SELECT name AS RangBuoc, definition AS DieuKien FROM sys.check_constraints
WHERE parent_object_id IN (OBJECT_ID('dbo.NguoiDung'), OBJECT_ID('dbo.DichVu'));
-- Học: DonHang.KhachHangId -> NguoiDung.Id; DichVuId -> DichVu.Id.
-- FK chỉ kiểm tra Id tồn tại. SP còn kiểm tra khách thuộc vai trò KH.
GO

-- V02. SEED SẠCH VÀ DỮ LIỆU MINH HỌA: chỉ tra cứu, không chạy lại seed.
SELECT VaiTro, COUNT(*) AS SoTaiKhoan FROM dbo.vw_NguoiDung GROUP BY VaiTro;
SELECT Id, HoTen, SoDienThoai, VaiTro FROM dbo.vw_NguoiDung ORDER BY VaiTro, Id;
SELECT TenDanhMuc, COUNT(*) AS SoDichVu FROM dbo.vw_DichVuCongKhai GROUP BY TenDanhMuc;
SELECT Id, TenDanhMuc, Ten, PhiKiemTra, TienCong FROM dbo.vw_DichVuCongKhai ORDER BY DanhMucId, Id;
-- 08_seed.sql: 7 tài khoản gốc và danh mục/cấu hình, không có đơn.
-- du_lieu_mau.sql: bổ sung khách/thợ/dịch vụ/đơn để có dữ liệu thực hành.
GO

-- V03. CRUD DANH MỤC QUA SP: thêm -> sửa -> ngừng sử dụng -> rollback.
DECLARE @Admin INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1);
DECLARE @Ma VARCHAR(30) = 'TH_' + LEFT(CONVERT(VARCHAR(36), NEWID()), 8);
DECLARE @Id INT, @PB BINARY(8);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_LuuDanhMucDichVu @NguoiThucHienId = @Admin, @Ten = N'Danh mục thực hành', @Ma = @Ma;
    SELECT @Id = Id, @PB = PhienBan FROM dbo.vw_DanhMucDichVu WHERE Ma = @Ma;
    EXEC dbo.sp_LuuDanhMucDichVu @NguoiThucHienId = @Admin, @Id = @Id,
        @Ten = N'Danh mục đã sửa', @Ma = @Ma, @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DanhMucDichVu WHERE Id = @Id;
    EXEC dbo.sp_LuuDanhMucDichVu @NguoiThucHienId = @Admin, @Id = @Id,
        @Ten = N'Danh mục đã sửa', @Ma = @Ma, @DangHoatDong = 0, @PhienBanDuKien = @PB;
    SELECT Id, Ten, Ma, DangHoatDong FROM dbo.vw_DanhMucDichVu WHERE Id = @Id; -- 0: đã ngừng.
    ROLLBACK TRANSACTION;
    SELECT COUNT(*) AS SoDongConLai FROM dbo.vw_DanhMucDichVu WHERE Ma = @Ma; -- 0.
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- Không xóa cứng danh mục đang có dịch vụ; ngừng sử dụng để giữ lịch sử.
GO

-- V04a. CHECK: giá âm bị chặn, lỗi 547. Xem tên CK_DichVu_Gia trong thông báo.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.DichVu SET TienCong = -1 WHERE Id = (SELECT MIN(Id) FROM dbo.DichVu);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: CHECK chưa chặn giá âm.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiCheck;
END CATCH;
GO
-- V04b. FOREIGN KEY: không có danh mục -1, lỗi 547.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    VALUES (-1, N'Dịch vụ thử FK', N'Minh họa tham chiếu không tồn tại.', 0, 100000, 15);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: FK chưa chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiKhoaNgoai;
END CATCH;
GO
-- V04c. UNIQUE: hai người dùng không được trùng số điện thoại.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.NguoiDung SET SoDienThoai = (SELECT SoDienThoai FROM dbo.NguoiDung WHERE Id = (SELECT MIN(Id) FROM dbo.NguoiDung))
    WHERE Id = (SELECT MAX(Id) FROM dbo.NguoiDung);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: UNIQUE chưa chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiTrungSoDienThoai;
END CATCH;
GO

-- V05. INDEX HIỆN CÓ: không xóa các index nghiệp vụ để làm thí nghiệm.
SELECT OBJECT_NAME(object_id) AS Bang, name AS ChiMuc, is_unique AS DuyNhat, filter_definition AS DieuKienLoc
FROM sys.indexes WHERE object_id IN (OBJECT_ID('dbo.DonHang'), OBJECT_ID('dbo.LenhDieuPhoi')) AND name IS NOT NULL;
-- UX_LenhDieuPhoi_Don: một đơn có tối đa một phân công còn hiệu lực.
-- UX_LenhDieuPhoi_Tho: một thợ có tối đa một phân công còn hiệu lực.
-- IX_DonHang_Khach_TrangThai: lọc theo khách trước, rồi theo trạng thái.
GO

-- V06. SO SÁNH THẬT TRƯỚC/SAU INDEX. Bật Ctrl+M rồi chọn TRỌN khối đến GO.
-- Bảng # là bảng tạm của cửa sổ hiện tại, mô phỏng đơn có nhiều dòng.
-- 50.000 dòng là dữ liệu đo, không chèn vào bảng DonHang của HomeFix.
DROP TABLE IF EXISTS #DonHangDoIndex;
CREATE TABLE #DonHangDoIndex (
    Id INT NOT NULL PRIMARY KEY,
    KhachHangId INT NOT NULL,
    TrangThai VARCHAR(20) NOT NULL,
    NgayTao DATE NOT NULL,
    GhiChu CHAR(200) NOT NULL
);
;WITH ChuSo AS (
    SELECT N FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) x(N)
), DaySo AS (
    SELECT TOP (50000) ROW_NUMBER() OVER (ORDER BY a.N, b.N, c.N, d.N, e.N) AS N
    FROM ChuSo a CROSS JOIN ChuSo b CROSS JOIN ChuSo c CROSS JOIN ChuSo d CROSS JOIN ChuSo e
)
INSERT INTO #DonHangDoIndex(Id, KhachHangId, TrangThai, NgayTao, GhiChu)
SELECT N, N % 1000, 'ChoTiepNhan', CONVERT(DATE, '20261023'), REPLICATE('X', 200) FROM DaySo;

SELECT N'Trước index: đọc nhiều trang, dự kiến Clustered Index Scan' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KhachHangId, TrangThai, NgayTao FROM #DonHangDoIndex
WHERE KhachHangId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

CREATE INDEX IX_ThucHanh_Khach_TrangThai ON #DonHangDoIndex(KhachHangId, TrangThai) INCLUDE (NgayTao);

SELECT N'Sau index: cùng 50 kết quả, dự kiến Index Seek, logical reads giảm' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KhachHangId, TrangThai, NgayTao FROM #DonHangDoIndex
WHERE KhachHangId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP INDEX IX_ThucHanh_Khach_TrangThai ON #DonHangDoIndex;
DROP TABLE #DonHangDoIndex;
-- Messages: so sánh logical reads của 2 SELECT, bỏ qua chi phí tạo index.
-- Execution Plan: Scan -> Seek. Không dùng FORCESEEK để ép kết luận.
-- Index tốn dung lượng, làm ghi chậm hơn; bảng ít dòng có thể vẫn chọn Scan.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO
