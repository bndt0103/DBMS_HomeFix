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
/* Đỗ Anh Tuấn - 24110369. Phân hệ: Đặt đơn, báo giá và điều phối.
   Mỗi thành viên làm đủ 10 nhóm kiến thức; mã T01–T10.
   Quyền thực hành: DBA. Chạy trọn khối đến GO; dữ liệu nghiệp vụ và quyền được khôi phục. */

-- T01. THIẾT KẾ, RÀNG BUỘC VÀ DỮ LIỆU — module 00, 08.
-- Đọc cấu trúc thật, không tạo lại schema/seed trên CSDL đang dùng.
SELECT c.name AS Cot, TYPE_NAME(c.user_type_id) AS Kieu, c.is_nullable AS ChoNull,
    c.is_identity AS TuTang FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.BaoGiaSoBo');
SELECT name, type_desc FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID('dbo.BaoGiaSoBo');
SELECT name, OBJECT_NAME(referenced_object_id) AS BangCha FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.BaoGiaSoBo');
SELECT name, definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('dbo.BaoGiaSoBo');
SELECT VaiTro, COUNT(*) AS SoTaiKhoan FROM dbo.vw_NguoiDung GROUP BY VaiTro;
-- Cột bắt buộc: NOT NULL. DEFAULT chỉ dùng khi bỏ qua cột lúc INSERT.
-- 08_seed: dữ liệu gốc; du_lieu_mau: dữ liệu giao dịch minh họa, không chạy lại seed.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE TOP (1) dbo.BaoGiaSoBo SET PhiKiemTra = -1;
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

-- T02. INDEX — module 01.
-- Cột lọc mô phỏng chức năng: Đặt đơn, báo giá và điều phối. Không gỡ index thật của ứng dụng.
DROP TABLE IF EXISTS #TH_T_Index;
CREATE TABLE #TH_T_Index (
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
INSERT INTO #TH_T_Index(Id, KhachHangId, TrangThai, NgayTao, GhiChu)
SELECT N, N % 1000, 'ChoTiepNhan', CONVERT(DATE, '20261023'), REPLICATE('X', 200) FROM DaySo;

SELECT N'Trước index: đọc nhiều trang, dự kiến Clustered Index Scan' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KhachHangId, TrangThai, NgayTao FROM #TH_T_Index
WHERE KhachHangId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

CREATE INDEX IX_TH_T_TraCuu ON #TH_T_Index(KhachHangId, TrangThai) INCLUDE (NgayTao);

SELECT N'Sau index: cùng 50 kết quả, dự kiến Index Seek, logical reads giảm' AS Buoc;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT Id, KhachHangId, TrangThai, NgayTao FROM #TH_T_Index
WHERE KhachHangId = 42 AND TrangThai = 'ChoTiepNhan' OPTION (RECOMPILE);
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP INDEX IX_TH_T_TraCuu ON #TH_T_Index;
DROP TABLE #TH_T_Index;
-- Messages: so sánh logical reads của 2 SELECT, bỏ qua chi phí tạo index.
-- Execution Plan: Scan -> Seek. Không dùng FORCESEEK để ép kết luận.
-- Index tốn dung lượng, làm ghi chậm hơn; bảng ít dòng có thể vẫn chọn Scan.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO

-- T03. VIEW — module 03.
SELECT TOP (5) * FROM dbo.vw_DonHangTongHop ORDER BY Id;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vw_DonHangTongHop')) AS DinhNghiaView;
-- Viết view ngắn riêng để chứng minh CREATE VIEW, rồi rollback đối tượng.
IF OBJECT_ID('dbo.vw_TH_T') IS NOT NULL THROW 51999, N'Tên view thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE VIEW dbo.vw_TH_T AS SELECT Id FROM dbo.vw_DonHangTongHop;');
    EXEC(N'SELECT TOP (5) Id FROM dbo.vw_TH_T ORDER BY Id;');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.vw_TH_T') AS ViewSauRollback; -- NULL.
GO

-- T04. FUNCTION — module 02.
DECLARE @Don INT = (SELECT TOP (1) Id FROM dbo.vw_DonHangTongHop WHERE TrangThai = 'ChoPhanCong' ORDER BY Id);
SELECT * FROM dbo.fn_KyThuatVienPhuHop(@Don);
SELECT * FROM dbo.fn_ThongKeDon(NULL, NULL);
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.fn_KyThuatVienPhuHop')) AS HamDangDung;
-- TVF dùng trong FROM/APPLY; scalar dùng trong SELECT. Hàm không ghi dữ liệu.
IF OBJECT_ID('dbo.fn_TH_T') IS NOT NULL THROW 51999, N'Tên hàm thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE FUNCTION dbo.fn_TH_T(@Phi DECIMAL(18,2), @Cong DECIMAL(18,2)) RETURNS DECIMAL(18,2)
        AS BEGIN RETURN @Phi + @Cong; END;');
    EXEC(N'SELECT dbo.fn_TH_T(50000, 150000) AS KetQua;'); -- 200000.
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.fn_TH_T') AS HamSauRollback; -- NULL.
GO

-- T05. STORED PROCEDURE — module 04, 05.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_TaoBaoGiaSoBo')) AS ThuTucDangDung;
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @DPV INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'DPV' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @Dau NVARCHAR(100) = N'[TH-D02] ' + CONVERT(NVARCHAR(36), NEWID());
DECLARE @Don INT, @BaoGia INT, @PB BINARY(8);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'01 Võ Văn Ngân, Thủ Đức', @MoTa = @Dau;
    SELECT @Don = Id, @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau;
    EXEC dbo.sp_TaoBaoGiaSoBo @NguoiThucHienId = @DPV, @DonHangId = @Don,
        @PhiKiemTra = 50000, @TienCong = 200000, @TyLeHoaHong = 15,
        @ChanDoan = N'Kiểm tra và sửa thiết bị', @PhienBanDuKien = @PB;
    SELECT @BaoGia = Id, @PB = PhienBan FROM dbo.vw_BaoGiaSoBo WHERE DonHangId = @Don;
    EXEC dbo.sp_KhachDuyetBaoGiaSoBo @NguoiThucHienId = @Khach, @BaoGiaId = @BaoGia,
        @QuyetDinh = 'Approved', @PhienBanDuKien = @PB;
    SELECT Id, TrangThai, TongTien FROM dbo.vw_DonHangTongHop WHERE Id = @Don; -- ChoPhanCong, 250000.
    SELECT TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo FROM dbo.vw_LichSuDonHang WHERE DonHangId = @Don ORDER BY Id;
    SELECT @@TRANCOUNT AS GiaoDichNgoaiVanCon; -- 1: SP không commit thay caller.
    ROLLBACK TRANSACTION;
    SELECT COUNT(*) AS SoDonThuConLai FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau; -- 0.
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- Tự viết một thủ tục tra cứu riêng; đối tượng được gỡ bằng rollback.
IF OBJECT_ID('dbo.sp_TH_T') IS NOT NULL THROW 51999, N'Tên SP thực hành đã tồn tại.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE PROCEDURE dbo.sp_TH_T @Id INT = NULL AS
        BEGIN SET NOCOUNT ON; SELECT Id FROM dbo.vw_DonHangTongHop WHERE @Id IS NULL OR Id = @Id; END;');
    EXEC dbo.sp_TH_T @Id = NULL;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.sp_TH_T') AS SPSauRollback; -- NULL.
GO

-- T06. TRIGGER — module 06.
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.tr_DonHang_KiemTraTrangThai')) AS DinhNghiaTrigger;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.DonHang SET TrangThai = 'ChoTiepNhan' WHERE TrangThai = 'HoanThanh';
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

-- T07. TRANSACTION VÀ ĐỒNG THỜI — module 05.
DECLARE @Id INT = (SELECT TOP (1) Id FROM dbo.BaoGiaSoBo ORDER BY Id);
DECLARE @GiaCu DECIMAL(18,2) = (SELECT PhiKiemTra FROM dbo.BaoGiaSoBo WHERE Id = @Id);
IF @Id IS NULL THROW 51999, N'Cần dữ liệu mẫu trước bài transaction.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    SAVE TRANSACTION TruocThayDoi;
    UPDATE dbo.BaoGiaSoBo SET PhiKiemTra = PhiKiemTra + 1 WHERE Id = @Id;
    SELECT PhiKiemTra AS GiaTriTam FROM dbo.BaoGiaSoBo WHERE Id = @Id;
    ROLLBACK TRANSACTION TruocThayDoi;
    SELECT PhiKiemTra AS GiaTriDaTraLai, @GiaCu AS GiaTriBanDau FROM dbo.BaoGiaSoBo WHERE Id = @Id;
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

-- T08. PHÂN QUYỀN — module 07.
SET XACT_ABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;
    EXECUTE AS USER = 'hf_DPV';
    SELECT USER_NAME() AS NguCanh, HAS_PERMS_BY_NAME('dbo.vw_DonHangTongHop', 'OBJECT', 'SELECT') AS QuyenTruoc; -- 1.
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_DonHangTongHop ORDER BY Id;');
    REVERT;

    REVOKE SELECT ON OBJECT::dbo.vw_DonHangTongHop FROM HomeFix_DPV;
    EXECUTE AS USER = 'hf_DPV';
    SELECT HAS_PERMS_BY_NAME('dbo.vw_DonHangTongHop', 'OBJECT', 'SELECT') AS QuyenSauRevoke; -- 0.
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_DonHangTongHop ORDER BY Id;');
        THROW 51999, N'Kiểm tra thất bại: vẫn đọc được sau REVOKE.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT N'Bị chặn sau REVOKE' AS Buoc, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
    END CATCH;
    REVERT;

    GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;
    EXECUTE AS USER = 'hf_DPV';
    EXEC(N'SELECT TOP (3) Id FROM dbo.vw_DonHangTongHop ORDER BY Id;'); -- đọc lại được.
    REVERT;

    DENY SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;
    EXECUTE AS USER = 'hf_DPV';
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id FROM dbo.vw_DonHangTongHop ORDER BY Id;');
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
    IF USER_NAME() = 'hf_DPV' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET XACT_ABORT ON;
    THROW;
END CATCH;
SET XACT_ABORT ON;
SELECT USER_NAME() AS DaTroLaiDBA, @@TRANCOUNT AS SoGiaoDichDangMo; -- dbo, 0.
-- REVOKE gỡ quyền đã cấp/cấm trực tiếp; không chủ động cấm quyền kế thừa từ role khác.
-- DENY là cấm rõ ràng. DBA/sysadmin không phải ngữ cảnh phù hợp để chứng minh bị chặn.
GO

-- T09. MIGRATION — module 09.
-- Đối chiếu migration thật: xem cột/check/index trước khi ALTER.
SELECT name, TYPE_NAME(user_type_id) AS Kieu FROM sys.columns WHERE object_id = OBJECT_ID('dbo.BaoGiaSoBo');
-- Mô phỏng nâng cấp phiên bản cũ trên bảng tạm, không ALTER bảng ứng dụng.
DROP TABLE IF EXISTS #TH_T_Cu;
CREATE TABLE #TH_T_Cu (Id INT PRIMARY KEY, Ten NVARCHAR(100));
INSERT INTO #TH_T_Cu(Id, Ten) VALUES (1, N'Dữ liệu cũ được giữ lại');
IF COL_LENGTH('tempdb..#TH_T_Cu', 'NgayCapNhat') IS NULL
    ALTER TABLE #TH_T_Cu ADD NgayCapNhat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME();
-- Chạy lại kiểm tra: không thêm trùng cột.
IF COL_LENGTH('tempdb..#TH_T_Cu', 'NgayCapNhat') IS NULL
    ALTER TABLE #TH_T_Cu ADD NgayCapNhat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME();
SELECT * FROM #TH_T_Cu;
DROP TABLE #TH_T_Cu;
-- Đọc module 09 trước khi nâng DB thật; db:upgrade chạy bởi DBA, cần sao lưu trước.
GO

-- T10. SAO LƯU VÀ PHỤC HỒI — module 10.
-- Mỗi người tự chạy FULL COPY_ONLY của mình, tên có MSSV và mã ngẫu nhiên.
IF @@TRANCOUNT <> 0 THROW 51999, N'Kết thúc giao dịch trước khi sao lưu.', 1;
DECLARE @ThuMuc NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
DECLARE @Tep NVARCHAR(4000) = @ThuMuc + N'\HomeFix_24110369_' + REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '') + N'.bak';
EXEC dbo.sp_SaoLuuHeThong @DuongDan = @Tep, @Loai = 'FULL', @BanSaoDocLap = 1;
RESTORE VERIFYONLY FROM DISK = @Tep WITH FILE = 1, CHECKSUM;
SELECT @Tep AS TepSaoLuu;
-- Tiếp tục mở 05_SaoLuuPhucHoi_Chung.sql: mỗi người tự làm FULL/DIFF/LOG và phục hồi.
-- Không đổi recovery của bản gốc; không WITH REPLACE. VERIFYONLY chưa thay thế thử restore.
GO
