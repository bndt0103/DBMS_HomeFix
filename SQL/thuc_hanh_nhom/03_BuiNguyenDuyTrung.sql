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
/* Bùi Nguyễn Duy Trung - 24110363. Phân hệ: Vật tư, nghiệm thu và bảo hành.
   Mỗi thành viên làm đủ 10 nhóm kiến thức; mã D01–D10.
   Quyền thực hành: DBA. Chạy trọn khối đến GO; dữ liệu nghiệp vụ và quyền được khôi phục. */

-- D01. THIẾT KẾ, RÀNG BUỘC VÀ DỮ LIỆU — module 00, 08.
-- Đọc cấu trúc thật, không tạo lại schema/seed trên CSDL đang dùng.
SELECT c.name AS Cot, TYPE_NAME(c.user_type_id) AS Kieu, c.is_nullable AS ChoNull,
    c.is_identity AS TuTang FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.ChiTietVatTu');
SELECT name, type_desc FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID('dbo.ChiTietVatTu');
SELECT name, OBJECT_NAME(referenced_object_id) AS BangCha FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.ChiTietVatTu');
SELECT name, definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('dbo.ChiTietVatTu');
SELECT VaiTro, COUNT(*) AS SoTaiKhoan FROM dbo.vw_NguoiDung GROUP BY VaiTro;
-- Cột bắt buộc: NOT NULL. DEFAULT chỉ dùng khi bỏ qua cột lúc INSERT.
-- 08_seed: dữ liệu gốc; du_lieu_mau: dữ liệu giao dịch minh họa, không chạy lại seed.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE TOP (1) dbo.ChiTietVatTu SET SoLuong = -1;
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: lệnh sai chưa bị chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
-- Kết quả: lỗi 547 (CHECK), câu UPDATE không được giữ lại.
GO

-- D02. INDEX — module 01.
-- Cột lọc mô phỏng chức năng: Vật tư, nghiệm thu và bảo hành. Không gỡ index thật của ứng dụng.
DROP TABLE IF EXISTS #TH_D_Index;
CREATE TABLE #TH_D_Index (
    Id INT NOT NULL PRIMARY KEY,
    BangKeVatTuId INT NOT NULL,
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
INSERT INTO #TH_D_Index(Id, BangKeVatTuId, TrangThai, NgayTao, GhiChu)
SELECT N, N % 1000, 'ChoTiepNhan', CONVERT(DATE, '20261023'), REPLICATE('X', 200) FROM DaySo;

SELECT N'Trước index: đọc nhiều trang, dự kiến Clustered Index Scan' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, BangKeVatTuId, TrangThai, NgayTao FROM #TH_D_Index
WHERE BangKeVatTuId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

CREATE INDEX IX_TH_D_TraCuu ON #TH_D_Index(BangKeVatTuId, TrangThai) INCLUDE (NgayTao);

SELECT N'Sau index: cùng 50 kết quả, dự kiến Index Seek, logical reads giảm' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, BangKeVatTuId, TrangThai, NgayTao FROM #TH_D_Index
WHERE BangKeVatTuId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP INDEX IX_TH_D_TraCuu ON #TH_D_Index;
DROP TABLE #TH_D_Index;
-- Messages: so sánh logical reads của 2 SELECT, bỏ qua chi phí tạo index.
-- Execution Plan: Scan -> Seek. Không dùng FORCESEEK để ép kết luận.
-- Index tốn dung lượng, làm ghi chậm hơn; bảng ít dòng có thể vẫn chọn Scan.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO

-- D03. VIEW — module 03.
SELECT TOP (5) * FROM dbo.vw_PhieuNghiemThu ORDER BY Id;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vw_PhieuNghiemThu')) AS DinhNghiaView;
-- Viết view ngắn riêng để chứng minh CREATE VIEW, rồi rollback đối tượng.
IF OBJECT_ID('dbo.vw_TH_D') IS NOT NULL THROW 51999, N'Tên view thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE VIEW dbo.vw_TH_D AS SELECT Id FROM dbo.vw_PhieuNghiemThu;');
    EXEC(N'SELECT TOP (5) Id FROM dbo.vw_TH_D ORDER BY Id;');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.vw_TH_D') AS ViewSauRollback; -- NULL.
GO

-- D04. FUNCTION — module 02.
SELECT d.Id, d.TrangThai, b.HanBaoHanh, dbo.fn_TongTienDonHang(d.Id) AS TongTien
FROM dbo.vw_DonHangTongHop d CROSS APPLY dbo.fn_HanBaoHanh(d.Id) b;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.fn_HanBaoHanh')) AS HamDangDung;
-- TVF dùng trong FROM/APPLY; scalar dùng trong SELECT. Hàm không ghi dữ liệu.
IF OBJECT_ID('dbo.fn_TH_D') IS NOT NULL THROW 51999, N'Tên hàm thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE FUNCTION dbo.fn_TH_D(@SoLuong DECIMAL(18,2), @DonGia DECIMAL(18,2)) RETURNS DECIMAL(18,2)
        AS BEGIN RETURN @SoLuong * @DonGia; END;');
    EXEC(N'SELECT dbo.fn_TH_D(2, 50000) AS KetQua;'); -- 100000.
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.fn_TH_D') AS HamSauRollback; -- NULL.
GO

-- D05. STORED PROCEDURE — module 04, 05.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_LuuBangKeVatTu')) AS ThuTucDangDung;
DECLARE @Don INT, @Tho INT, @PB BINARY(8);
SELECT TOP (1) @Don = Id, @Tho = KyThuatVienId FROM dbo.vw_DonHangTongHop WHERE TrangThai = 'DangXuLy' ORDER BY Id;
IF @Don IS NULL
    SELECT N'Cần một đơn DangXuLy: DPV phân công, KTV nhận -> di chuyển -> đến nơi -> bắt đầu sửa.' AS CanChuanBi;
ELSE
BEGIN TRY
    BEGIN TRANSACTION;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_LuuBangKeVatTu @NguoiThucHienId = @Tho, @DonHangId = @Don,
        @VatTu = N'[{"Ten":"Linh kiện thử nghiệm","SoLuong":2,"DonGia":50000,"SoThangBaoHanh":6}]', @PhienBanDuKien = @PB;
    SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_TaoPhieuNghiemThu @NguoiThucHienId = @Tho, @DonHangId = @Don,
        @NguyenNhan = N'Linh kiện hư hỏng', @PhuongAnXuLy = N'Thay linh kiện, chạy thử', @PhienBanDuKien = @PB;
    SELECT DonHangId, TongTienVatTu, PhiKiemTra, TienCong, TongTien FROM dbo.vw_PhieuNghiemThu
    WHERE DonHangId = @Don AND TrangThai = 'Pending';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- Tự viết một thủ tục tra cứu riêng; đối tượng được gỡ bằng rollback.
IF OBJECT_ID('dbo.sp_TH_D') IS NOT NULL THROW 51999, N'Tên SP thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE PROCEDURE dbo.sp_TH_D @Id INT = NULL AS
        BEGIN SET NOCOUNT ON; SELECT Id FROM dbo.vw_PhieuNghiemThu WHERE @Id IS NULL OR Id = @Id; END;');
    EXEC dbo.sp_TH_D @Id = NULL;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.sp_TH_D') AS SPSauRollback; -- NULL.
GO

-- D06. TRIGGER — module 06.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.tr_ChiTietVatTu_KhoaNghiemThu')) AS DinhNghiaTrigger;
DECLARE @ChiTiet INT = (SELECT TOP (1) ct.Id FROM dbo.ChiTietVatTu ct
JOIN dbo.PhieuNghiemThu nt ON nt.BangKeVatTuId = ct.BangKeVatTuId ORDER BY ct.Id);
IF @ChiTiet IS NULL THROW 51999, N'Cần bảng kê đã được dùng trong nghiệm thu.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ChiTietVatTu SET DonGia = DonGia + 1 WHERE Id = @ChiTiet;
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: lệnh sai chưa bị chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
-- Phân biệt AFTER / INSTEAD OF; inserted/deleted là tập hợp, không phải một dòng.
GO

-- D07. TRANSACTION VÀ ĐỒNG THỜI — module 05.
DECLARE @Id INT = (SELECT TOP (1) Id FROM dbo.BangKeVatTu ORDER BY Id);
DECLARE @GiaCu DECIMAL(18,2) = (SELECT LanSuaDoi FROM dbo.BangKeVatTu WHERE Id = @Id);
IF @Id IS NULL THROW 51999, N'Cần dữ liệu mẫu trước bài transaction.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    SAVE TRANSACTION TruocThayDoi;
    UPDATE dbo.BangKeVatTu SET LanSuaDoi = LanSuaDoi + 1000000 WHERE Id = @Id;
    SELECT LanSuaDoi AS GiaTriTam FROM dbo.BangKeVatTu WHERE Id = @Id;
    ROLLBACK TRANSACTION TruocThayDoi;
    SELECT LanSuaDoi AS GiaTriDaTraLai, @GiaCu AS GiaTriBanDau FROM dbo.BangKeVatTu WHERE Id = @Id;
    COMMIT TRANSACTION; -- Chỉ kết thúc giao dịch sau khi đã hoàn tác thay đổi.
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
-- Đây là lệnh DBA trong bài học; web vẫn ghi qua SP.
-- UPDLOCK/HOLDLOCK và ROWVERSION trong SP chống hai người ghi đè cùng dòng.
-- Bài hai cửa sổ và phiên bản cũ được hướng dẫn riêng trong HUONG_DAN.md.
GO

-- D08. PHÂN QUYỀN — module 07.
SET XACT_ABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
    EXECUTE AS USER = 'hf_KTV';
    SELECT USER_NAME() AS NguCanh, HAS_PERMS_BY_NAME('dbo.vw_PhieuNghiemThu', 'OBJECT', 'SELECT') AS QuyenTruoc; -- 1.
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_PhieuNghiemThu ORDER BY Id;');
    REVERT;

    REVOKE SELECT ON OBJECT::dbo.vw_PhieuNghiemThu FROM HomeFix_KTV;
    EXECUTE AS USER = 'hf_KTV';
    SELECT HAS_PERMS_BY_NAME('dbo.vw_PhieuNghiemThu', 'OBJECT', 'SELECT') AS QuyenSauRevoke; -- 0.
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_PhieuNghiemThu ORDER BY Id;');
        THROW 51999, N'Kiểm tra thất bại: vẫn đọc được sau REVOKE.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT N'Bị chặn sau REVOKE' AS Buoc, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
    END CATCH;
    REVERT;

    GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
    EXECUTE AS USER = 'hf_KTV';
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_PhieuNghiemThu ORDER BY Id;'); -- đọc lại được.
    REVERT;

    DENY SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
    EXECUTE AS USER = 'hf_KTV';
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_PhieuNghiemThu ORDER BY Id;');
        THROW 51999, N'Kiểm tra thất bại: DENY chưa chặn.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT N'Bị chặn sau DENY' AS Buoc, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
    END CATCH;
    REVERT;
    ROLLBACK TRANSACTION; -- khôi phục đúng quyền ban đầu, kể cả khi ban đầu đã tùy chỉnh.
END TRY
BEGIN CATCH
    IF USER_NAME() = 'hf_KTV' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET XACT_ABORT ON;
    THROW;
END CATCH;
SET XACT_ABORT ON;
SELECT USER_NAME() AS DaTroLaiDBA, @@TRANCOUNT AS SoGiaoDichDangMo; -- dbo, 0.
-- REVOKE gỡ quyền đã cấp/cấm trực tiếp; không chủ động cấm quyền kế thừa từ role khác.
-- DENY là cấm rõ ràng. DBA/sysadmin không phải ngữ cảnh phù hợp để chứng minh bị chặn.
GO

-- D09. MIGRATION — module 09.
-- Đối chiếu migration thật: xem cột/check/index trước khi ALTER.
SELECT name, TYPE_NAME(user_type_id) AS Kieu FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ChiTietVatTu');
-- Mô phỏng nâng cấp phiên bản cũ trên bảng tạm, không ALTER bảng ứng dụng.
DROP TABLE IF EXISTS #TH_D_Cu;
CREATE TABLE #TH_D_Cu (Id INT PRIMARY KEY, Ten NVARCHAR(100));
INSERT INTO #TH_D_Cu(Id, Ten) VALUES (1, N'Dữ liệu cũ được giữ lại');
IF COL_LENGTH('tempdb..#TH_D_Cu', 'SoThangBaoHanh') IS NULL
    ALTER TABLE #TH_D_Cu ADD SoThangBaoHanh INT NOT NULL DEFAULT 0;
-- Chạy lại kiểm tra: không thêm trùng cột.
IF COL_LENGTH('tempdb..#TH_D_Cu', 'SoThangBaoHanh') IS NULL
    ALTER TABLE #TH_D_Cu ADD SoThangBaoHanh INT NOT NULL DEFAULT 0;
SELECT * FROM #TH_D_Cu;
DROP TABLE #TH_D_Cu;
-- Đọc module 09 trước khi nâng DB thật; db:upgrade chạy bởi DBA, cần sao lưu trước.
GO

-- D10. SAO LƯU VÀ PHỤC HỒI — module 10.
-- Mỗi người tự chạy FULL COPY_ONLY của mình, tên có MSSV và mã ngẫu nhiên.
IF @@TRANCOUNT <> 0 THROW 51999, N'Kết thúc giao dịch trước khi sao lưu.', 1;
DECLARE @ThuMuc NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
DECLARE @Tep NVARCHAR(4000) = @ThuMuc + N'\HomeFix_24110363_' + REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '') + N'.bak';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = @Tep, @Loai = 'FULL', @BanSaoDocLap = 1;
RESTORE VERIFYONLY FROM DISK = @Tep WITH FILE = 1, CHECKSUM;
SELECT @Tep AS TepSaoLuu;
-- Tiếp tục mở 05_SaoLuuPhucHoi_Chung.sql: mỗi người tự làm FULL/DIFF/LOG và phục hồi.
-- Không đổi recovery của bản gốc; không WITH REPLACE. VERIFYONLY chưa thay thế thử restore.
GO
