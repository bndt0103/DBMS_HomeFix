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
/* LÊ TẤN TÀI - 24110319. Module 06, 07, 09, 10; đối soát trong 05.
   Chạy từng khối A01..A07 bằng DBA. Bài quyền hoàn tác ở cuối mỗi khối.
   Không dừng giữa EXECUTE AS và REVERT. Sao lưu/phục hồi nằm ở file riêng
   04b_SaoLuuPhucHoi.sql: chạy trọn khối, tự dọn các CSDL thực hành. */

-- A01. BẢY TRIGGER: loại kích hoạt, bảng được bảo vệ.
SELECT t.name AS TenTrigger, OBJECT_NAME(t.parent_id) AS Bang, t.is_instead_of_trigger AS ThayTheLenh,
    t.is_disabled AS DaTat FROM sys.triggers t WHERE t.parent_class = 1 ORDER BY t.name;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.tr_GiaoDichVi_BatBien')) AS MaNguonTrigger;
-- AFTER: chạy sau thay đổi/ràng buộc, vẫn trong cùng transaction, có thể THROW để hủy.
-- INSTEAD OF: chạy thay UPDATE/DELETE. Sổ cái chỉ ghi thêm, cần sai thì có chứng từ điều chỉnh.
GO

-- A02. TRIGGER BẤT BIẾN: thử sửa nhiều dòng sổ cái, mong đợi 51009.
IF NOT EXISTS (SELECT 1 FROM dbo.vw_GiaoDichVi)
    THROW 51999, N'Cần dữ liệu minh họa sổ ví để chạy A02.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.GiaoDichVi SET GhiChu = N'Không được sửa lịch sử'
    WHERE Id IN (SELECT TOP (2) Id FROM dbo.GiaoDichVi ORDER BY Id);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: sổ cái bị sửa.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiBaoVeSoCai;
END CATCH;
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien; -- chênh lệch 0.
GO

-- A03. GRANT -> REVOKE -> GRANT -> DENY: chạy truy vấn thật ở từng bước.
-- Dùng quyền SELECT của role KH trên view công khai; không đụng quyền bảng nghiệp vụ.
-- XACT_ABORT OFF trong đúng bài này để lỗi quyền dự kiến không hủy transaction DDL.
SET XACT_ABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;
    EXECUTE AS USER = 'hf_KH';
    SELECT USER_NAME() AS NguCanh, HAS_PERMS_BY_NAME('dbo.vw_DichVuCongKhai', 'OBJECT', 'SELECT') AS QuyenTruoc; -- 1.
    EXEC(N'SELECT TOP (3) Id, Ten FROM dbo.vw_DichVuCongKhai ORDER BY Id;');
    REVERT;

    REVOKE SELECT ON OBJECT::dbo.vw_DichVuCongKhai FROM HomeFix_KH;
    EXECUTE AS USER = 'hf_KH';
    SELECT HAS_PERMS_BY_NAME('dbo.vw_DichVuCongKhai', 'OBJECT', 'SELECT') AS QuyenSauRevoke; -- 0.
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id, Ten FROM dbo.vw_DichVuCongKhai ORDER BY Id;');
        THROW 51999, N'Kiểm tra thất bại: vẫn đọc được sau REVOKE.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT N'Bị chặn sau REVOKE' AS Buoc, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
    END CATCH;
    REVERT;

    GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;
    EXECUTE AS USER = 'hf_KH';
    EXEC(N'SELECT TOP (3) Id, Ten FROM dbo.vw_DichVuCongKhai ORDER BY Id;'); -- đọc lại được.
    REVERT;

    DENY SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;
    EXECUTE AS USER = 'hf_KH';
    BEGIN TRY
        EXEC(N'SELECT TOP (3) Id, Ten FROM dbo.vw_DichVuCongKhai ORDER BY Id;');
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
    IF USER_NAME() = 'hf_KH' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET XACT_ABORT ON;
    THROW;
END CATCH;
SET XACT_ABORT ON;
SELECT USER_NAME() AS DaTroLaiDBA, @@TRANCOUNT AS SoGiaoDichDangMo; -- dbo, 0.
-- REVOKE gỡ quyền đã cấp/cấm trực tiếp; không chủ động cấm quyền kế thừa từ role khác.
-- DENY là cấm rõ ràng. DBA/sysadmin không phải ngữ cảnh phù hợp để chứng minh bị chặn.
GO

-- A04. VIEW ĐƯỢC ĐỌC NHƯNG BẢNG/HASH BỊ CẤM; quyền EXECUTE cũng thu hồi được.
EXECUTE AS USER = 'hf_KH';
BEGIN TRY
    EXEC(N'SELECT TOP (3) Id, HoTen FROM dbo.vw_NguoiDung ORDER BY Id;');
    BEGIN TRY
        EXEC(N'SELECT MatKhauBam FROM dbo.NguoiDung;');
        THROW 51999, N'Kiểm tra thất bại: KH đọc được hash.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiDocBang;
    END CATCH;
    REVERT;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
GO
DECLARE @GD INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'GD' AND DangHoatDong = 1);
DECLARE @NguCanhCu SQL_VARIANT = SESSION_CONTEXT(N'NguoiDungId');
SET XACT_ABORT OFF;
BEGIN TRY
    EXEC sys.sp_set_session_context @key = N'NguoiDungId', @value = @GD;
    BEGIN TRANSACTION;
    GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_GD;
    EXECUTE AS USER = 'hf_GD';
    EXEC dbo.sp_BaoCaoTongHop @NguoiThucHienId = @GD; -- chạy được.
    REVERT;
    REVOKE EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop FROM HomeFix_GD;
    EXECUTE AS USER = 'hf_GD';
    BEGIN TRY
        EXEC dbo.sp_BaoCaoTongHop @NguoiThucHienId = @GD;
        THROW 51999, N'Kiểm tra thất bại: vẫn EXECUTE được sau REVOKE.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiThuHoiExecute;
    END CATCH;
    REVERT;
    ROLLBACK TRANSACTION;
    EXEC sys.sp_set_session_context @key = N'NguoiDungId', @value = @NguCanhCu;
END TRY
BEGIN CATCH
    IF USER_NAME() = 'hf_GD' REVERT;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sys.sp_set_session_context @key = N'NguoiDungId', @value = @NguCanhCu;
    SET XACT_ABORT ON;
    THROW;
END CATCH;
SET XACT_ABORT ON;
-- SESSION_CONTEXT ở đây giả lập danh tính đã đăng nhập; web đặt từ JWT trên kết nối riêng.
GO

-- A05. THANH TOÁN/ĐỐI SOÁT: công thức ví và chặn duyệt lặp.
SELECT ds.Id, ds.DonHangId, tt.LoaiThanhToan, tt.PhuongThuc, tt.SoTien,
    ds.TienHoaHong, ds.TrangThai,
    CASE WHEN tt.PhuongThuc = 'COD' THEN -ds.TienHoaHong ELSE tt.SoTien - ds.TienHoaHong END AS BienDongViDuKien
FROM dbo.vw_DoiSoat ds JOIN dbo.vw_ThanhToan tt ON tt.Id = ds.ThanhToanId ORDER BY ds.Id;
DECLARE @KeToan INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KT' AND DangHoatDong = 1);
DECLARE @DS INT, @PB BINARY(8);
SELECT TOP (1) @DS = Id, @PB = PhienBan FROM dbo.vw_DoiSoat WHERE TrangThai = 'Confirmed' ORDER BY Id;
IF @DS IS NULL
    SELECT N'Cần một đối soát đã xác nhận để thử chặn duyệt lặp.' AS CanChuanBi;
ELSE
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_DoiSoatCOD @NguoiThucHienId = @KeToan, @DoiSoatId = @DS, @PhienBanDuKien = @PB;
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: cho đối soát lặp.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiDuyetLap;
END CATCH;
-- COD: thợ đang giữ tiền mặt, chỉ trừ hoa hồng, không cộng lại cả hóa đơn.
-- BANK: cộng tiền thu trừ hoa hồng. PhiHuyDon: hoa hồng 0, cộng đủ 60000.
-- Không đủ số dư khả dụng: từ chối; không tự UPDATE ví để vượt qua kiểm tra.
GO

-- A06. MIGRATION: kiểm tra cấu trúc đã nâng cấp, không chạy lại schema/seed.
SELECT OBJECT_ID('dbo.BangKeVatTu', 'U') AS BangKeHienTai,
    OBJECT_ID('dbo.DeXuatVatTu', 'U') AS TenCuDaBo; -- số Id, NULL.
SELECT COL_LENGTH('dbo.DonHang', 'PhiHuyDon') AS CotPhiHuy,
    COL_LENGTH('dbo.ThanhToan', 'LoaiThanhToan') AS CotLoaiThanhToan,
    COL_LENGTH('dbo.YeuCauHoTro', 'NgayCapNhat') AS CotNgayCapNhat;
SELECT name, filter_definition FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.ThanhToan') AND name = 'UX_ThanhToan_NghiemThu';
-- NghiemThuId NULL cho phí hủy; UNIQUE lọc chỉ xét NOT NULL, cho nhiều đơn phí hủy khác nhau.
-- Module 09 dùng IF COL_LENGTH/OBJECT_ID để bổ sung cấu trúc cũ và giữ dữ liệu.
-- 09 không tự định nghĩa lại mọi SP/View; db:upgrade còn chạy 02..07 cùng giao dịch.
GO

-- A07. KIỂM TRA TRƯỚC SAO LƯU: trạng thái, ràng buộc, sổ cái.
SELECT name, recovery_model_desc FROM sys.databases WHERE name = DB_NAME();
SELECT name AS RangBuocTat FROM sys.check_constraints WHERE is_disabled = 1 OR is_not_trusted = 1;
SELECT name AS KhoaNgoaiTat FROM sys.foreign_keys WHERE is_disabled = 1 OR is_not_trusted = 1;
SELECT Id, ChenhLech FROM dbo.vw_ViKyThuatVien WHERE ChenhLech <> 0; -- rỗng.
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
-- Mở 04b_SaoLuuPhucHoi.sql để demo FULL/DIFF/LOG và phục hồi thực tế.
GO
