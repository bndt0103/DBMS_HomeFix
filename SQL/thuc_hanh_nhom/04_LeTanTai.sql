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
/* Lê Tấn Tài - 24110319. Phân hệ: Thanh toán, đối soát và ví kỹ thuật viên.
   Mỗi thành viên làm đủ 10 nhóm kiến thức; mã A01–A10.
   Quyền thực hành: DBA. Chạy trọn khối đến GO; dữ liệu nghiệp vụ và quyền được khôi phục. */

-- A01. THIẾT KẾ, RÀNG BUỘC VÀ DỮ LIỆU — module 00, 08.
-- Đọc cấu trúc thật, không tạo lại schema/seed trên CSDL đang dùng.
SELECT c.name AS Cot, TYPE_NAME(c.user_type_id) AS Kieu, c.is_nullable AS ChoNull,
    c.is_identity AS TuTang FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.KyThuatVien');
SELECT name, type_desc FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID('dbo.KyThuatVien');
SELECT name, OBJECT_NAME(referenced_object_id) AS BangCha FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.KyThuatVien');
SELECT name, definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('dbo.KyThuatVien');
SELECT VaiTro, COUNT(*) AS SoTaiKhoan FROM dbo.vw_NguoiDung GROUP BY VaiTro;
-- Cột bắt buộc: NOT NULL. DEFAULT chỉ dùng khi bỏ qua cột lúc INSERT.
-- 08_seed: dữ liệu gốc; du_lieu_mau: dữ liệu giao dịch minh họa, không chạy lại seed.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE TOP (1) dbo.KyThuatVien SET SoDu = -1;
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

-- A02. INDEX — module 01.
-- Cột lọc mô phỏng chức năng: Thanh toán, đối soát và ví kỹ thuật viên. Không gỡ index thật của ứng dụng.
DROP TABLE IF EXISTS #TH_A_Index;
CREATE TABLE #TH_A_Index (
    Id INT NOT NULL PRIMARY KEY,
    KyThuatVienId INT NOT NULL,
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
INSERT INTO #TH_A_Index(Id, KyThuatVienId, TrangThai, NgayTao, GhiChu)
SELECT N, N % 1000, 'ChoTiepNhan', CONVERT(DATE, '20261023'), REPLICATE('X', 200) FROM DaySo;

SELECT N'Trước index: đọc nhiều trang, dự kiến Clustered Index Scan' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KyThuatVienId, TrangThai, NgayTao FROM #TH_A_Index
WHERE KyThuatVienId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

CREATE INDEX IX_TH_A_TraCuu ON #TH_A_Index(KyThuatVienId, TrangThai) INCLUDE (NgayTao);

SELECT N'Sau index: cùng 50 kết quả, dự kiến Index Seek, logical reads giảm' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KyThuatVienId, TrangThai, NgayTao FROM #TH_A_Index
WHERE KyThuatVienId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP INDEX IX_TH_A_TraCuu ON #TH_A_Index;
DROP TABLE #TH_A_Index;
-- Messages: so sánh logical reads của 2 SELECT, bỏ qua chi phí tạo index.
-- Execution Plan: Scan -> Seek. Không dùng FORCESEEK để ép kết luận.
-- Index tốn dung lượng, làm ghi chậm hơn; bảng ít dòng có thể vẫn chọn Scan.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO

-- A03. VIEW — module 03.
SELECT TOP (5) * FROM dbo.vw_ViKyThuatVien ORDER BY Id;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vw_ViKyThuatVien')) AS DinhNghiaView;
-- Viết view ngắn riêng để chứng minh CREATE VIEW, rồi rollback đối tượng.
IF OBJECT_ID('dbo.vw_TH_A') IS NOT NULL THROW 51999, N'Tên view thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE VIEW dbo.vw_TH_A AS SELECT Id FROM dbo.vw_ViKyThuatVien;');
    EXEC(N'SELECT TOP (5) Id FROM dbo.vw_TH_A ORDER BY Id;');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.vw_TH_A') AS ViewSauRollback; -- NULL.
GO

-- A04. FUNCTION — module 02.
SELECT k.Id, k.HoTen, v.SoDu FROM dbo.vw_KyThuatVien k CROSS APPLY dbo.fn_SoDuVi(k.Id) v;
SELECT dbo.fn_HoaHong(200000, 15) AS HoaHong; -- 30000.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.fn_SoDuVi')) AS HamDangDung;
-- TVF dùng trong FROM/APPLY; scalar dùng trong SELECT. Hàm không ghi dữ liệu.
IF OBJECT_ID('dbo.fn_TH_A') IS NOT NULL THROW 51999, N'Tên hàm thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE FUNCTION dbo.fn_TH_A(@TienCong DECIMAL(18,2), @TyLe DECIMAL(5,2)) RETURNS DECIMAL(18,2)
        AS BEGIN RETURN @TienCong * @TyLe / 100; END;');
    EXEC(N'SELECT dbo.fn_TH_A(200000, 15) AS KetQua;'); -- 30000.
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.fn_TH_A') AS HamSauRollback; -- NULL.
GO

-- A05. STORED PROCEDURE — module 04, 05.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_LuuTaiKhoanNganHang')) AS ThuTucDangDung;
DECLARE @Admin INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1);
DECLARE @So VARCHAR(30) = '9704' + RIGHT('0000000000' + CONVERT(VARCHAR(30), ABS(CONVERT(BIGINT, CHECKSUM(NEWID())))), 10);
DECLARE @Id INT, @PB BINARY(8);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_LuuTaiKhoanNganHang @NguoiThucHienId = @Admin, @MaNganHang = 'VCB',
        @TenNganHang = N'Vietcombank', @SoTaiKhoan = @So, @ChuTaiKhoan = N'HOMEFIX THỰC HÀNH';
    SELECT @Id = Id, @PB = PhienBan FROM dbo.vw_TaiKhoanNganHang WHERE SoTaiKhoan = @So;
    EXEC dbo.sp_LuuTaiKhoanNganHang @NguoiThucHienId = @Admin, @Id = @Id, @MaNganHang = 'VCB',
        @TenNganHang = N'Vietcombank', @SoTaiKhoan = @So, @ChuTaiKhoan = N'HOMEFIX ĐÃ SỬA',
        @DangHoatDong = 0, @PhienBanDuKien = @PB;
    SELECT Id, SoTaiKhoan, ChuTaiKhoan, DangHoatDong FROM dbo.vw_TaiKhoanNganHang WHERE Id = @Id;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- Tự viết một thủ tục tra cứu riêng; đối tượng được gỡ bằng rollback.
IF OBJECT_ID('dbo.sp_TH_A') IS NOT NULL THROW 51999, N'Tên SP thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE PROCEDURE dbo.sp_TH_A @Id INT = NULL AS
        BEGIN SET NOCOUNT ON; SELECT Id FROM dbo.vw_ViKyThuatVien WHERE @Id IS NULL OR Id = @Id; END;');
    EXEC dbo.sp_TH_A @Id = NULL;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.sp_TH_A') AS SPSauRollback; -- NULL.
GO

-- A06. TRIGGER — module 06.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.tr_GiaoDichVi_BatBien')) AS DinhNghiaTrigger;
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM dbo.GiaoDichVi;
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

-- A07. TRANSACTION VÀ ĐỒNG THỜI — module 05.
DECLARE @Id INT = (SELECT TOP (1) Id FROM dbo.KyThuatVien ORDER BY Id);
DECLARE @GiaCu DECIMAL(18,2) = (SELECT SoDu FROM dbo.KyThuatVien WHERE Id = @Id);
IF @Id IS NULL THROW 51999, N'Cần dữ liệu mẫu trước bài transaction.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    SAVE TRANSACTION TruocThayDoi;
    UPDATE dbo.KyThuatVien SET SoDu = SoDu + 1 WHERE Id = @Id;
    SELECT SoDu AS GiaTriTam FROM dbo.KyThuatVien WHERE Id = @Id;
    ROLLBACK TRANSACTION TruocThayDoi;
    SELECT SoDu AS GiaTriDaTraLai, @GiaCu AS GiaTriBanDau FROM dbo.KyThuatVien WHERE Id = @Id;
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

-- A08. PHÂN QUYỀN — module 07.
SET XACT_ABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;
    EXECUTE AS USER = 'hf_KT';
    SELECT USER_NAME() AS NguCanh, HAS_PERMS_BY_NAME('dbo.vw_ViKyThuatVien', 'OBJECT', 'SELECT') AS QuyenTruoc; -- 1.
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_ViKyThuatVien ORDER BY Id;');
    REVERT;

    REVOKE SELECT ON OBJECT::dbo.vw_ViKyThuatVien FROM HomeFix_KT;
    EXECUTE AS USER = 'hf_KT';
    SELECT HAS_PERMS_BY_NAME('dbo.vw_ViKyThuatVien', 'OBJECT', 'SELECT') AS QuyenSauRevoke; -- 0.
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_ViKyThuatVien ORDER BY Id;');
        THROW 51999, N'Kiểm tra thất bại: vẫn đọc được sau REVOKE.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT N'Bị chặn sau REVOKE' AS Buoc, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
    END CATCH;
    REVERT;

    GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;
    EXECUTE AS USER = 'hf_KT';
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_ViKyThuatVien ORDER BY Id;'); -- đọc lại được.
    REVERT;

    DENY SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;
    EXECUTE AS USER = 'hf_KT';
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_ViKyThuatVien ORDER BY Id;');
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
    IF USER_NAME() = 'hf_KT' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET XACT_ABORT ON;
    THROW;
END CATCH;
SET XACT_ABORT ON;
SELECT USER_NAME() AS DaTroLaiDBA, @@TRANCOUNT AS SoGiaoDichDangMo; -- dbo, 0.
-- REVOKE gỡ quyền đã cấp/cấm trực tiếp; không chủ động cấm quyền kế thừa từ role khác.
-- DENY là cấm rõ ràng. DBA/sysadmin không phải ngữ cảnh phù hợp để chứng minh bị chặn.
GO

-- A09. MIGRATION — module 09.
-- Đối chiếu migration thật: xem cột/check/index trước khi ALTER.
SELECT name, TYPE_NAME(user_type_id) AS Kieu FROM sys.columns WHERE object_id = OBJECT_ID('dbo.KyThuatVien');
-- Mô phỏng nâng cấp phiên bản cũ trên bảng tạm, không ALTER bảng ứng dụng.
DROP TABLE IF EXISTS #TH_A_Cu;
CREATE TABLE #TH_A_Cu (Id INT PRIMARY KEY, Ten NVARCHAR(100));
INSERT INTO #TH_A_Cu(Id, Ten) VALUES (1, N'Dữ liệu cũ được giữ lại');
IF COL_LENGTH('tempdb..#TH_A_Cu', 'GhiChu') IS NULL
    ALTER TABLE #TH_A_Cu ADD GhiChu NVARCHAR(200) NULL;
-- Chạy lại kiểm tra: không thêm trùng cột.
IF COL_LENGTH('tempdb..#TH_A_Cu', 'GhiChu') IS NULL
    ALTER TABLE #TH_A_Cu ADD GhiChu NVARCHAR(200) NULL;
SELECT * FROM #TH_A_Cu;
DROP TABLE #TH_A_Cu;
-- Đọc module 09 trước khi nâng DB thật; db:upgrade chạy bởi DBA, cần sao lưu trước.
GO

-- A10. SAO LƯU VÀ PHỤC HỒI — module 10.
-- Mỗi người tự chạy FULL COPY_ONLY của mình, tên có MSSV và mã ngẫu nhiên.
IF @@TRANCOUNT <> 0 THROW 51999, N'Kết thúc giao dịch trước khi sao lưu.', 1;
DECLARE @ThuMuc NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
DECLARE @Tep NVARCHAR(4000) = @ThuMuc + N'\HomeFix_24110319_' + REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '') + N'.bak';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = @Tep, @Loai = 'FULL', @BanSaoDocLap = 1;
RESTORE VERIFYONLY FROM DISK = @Tep WITH FILE = 1, CHECKSUM;
SELECT @Tep AS TepSaoLuu;
-- Tiếp tục mở 05_SaoLuuPhucHoi_Chung.sql: mỗi người tự làm FULL/DIFF/LOG và phục hồi.
-- Không đổi recovery của bản gốc; không WITH REPLACE. VERIFYONLY chưa thay thế thử restore.
GO
