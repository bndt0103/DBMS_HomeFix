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
/* BÙI NGUYỄN DUY TRUNG - 24110363. Module 04, 05; trigger trạng thái trong 06.
   Chọn trọn từng khối D01..D08. Tất cả thử ghi nghiệp vụ đều rollback.
   Chỉ D06/D08 cần đơn đúng trạng thái; khối sẽ báo rõ nếu chưa có dữ liệu. */

-- D01. ĐỌC THAM SỐ SP VÀ THỬ SAI VAI TRÒ: mong đợi 51003.
SELECT name AS ThamSo, TYPE_NAME(user_type_id) AS Kieu, max_length AS SoByte
FROM sys.parameters WHERE object_id = OBJECT_ID('dbo.sp_TaoDonHang') ORDER BY parameter_id;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_TaoDonHang')) AS MaNguonThuTuc;
DECLARE @Admin INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Admin, @DichVuId = @DichVu,
        @DiaChi = N'Địa chỉ thử quyền', @MoTa = N'Tài khoản ADMIN không đóng vai khách để đặt đơn.';
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: chưa chặn sai vai trò.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51003 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiVaiTro;
END CATCH;
GO

-- D02. TẠO ĐƠN -> BÁO GIÁ -> KHÁCH DUYỆT: SP nhiều bước trong transaction ngoài.
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
GO

-- D03. SAVEPOINT VÀ COMMIT: quay lui phần sau điểm lưu, rồi chốt giao dịch ngoài.
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @Dau NVARCHAR(100) = N'[TH-D03] ' + CONVERT(NVARCHAR(36), NEWID());
DROP TABLE IF EXISTS #DauVetCommit;
CREATE TABLE #DauVetCommit(NoiDung NVARCHAR(100));
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO #DauVetCommit(NoiDung) VALUES (N'Phần trước savepoint được giữ khi COMMIT.');
    SAVE TRANSACTION TruocTaoDon;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử điểm lưu', @MoTa = @Dau;
    SELECT COUNT(*) AS SoDonTruocQuayLui FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau; -- 1.
    ROLLBACK TRANSACTION TruocTaoDon;
    COMMIT TRANSACTION;
    SELECT * FROM #DauVetCommit; -- vẫn 1 dòng.
    SELECT COUNT(*) AS SoDonSauQuayLui FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau; -- 0.
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
DROP TABLE #DauVetCommit;
-- SAVEPOINT không phải transaction độc lập; COMMIT trong transaction lồng chưa bền vững đến COMMIT ngoài cùng.
GO

-- D04. ROWVERSION: mô phỏng form cũ; cập nhật lần sau với phiên bản cũ bị từ chối.
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @DPV INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'DPV' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @Dau NVARCHAR(100) = N'[TH-D04] ' + CONVERT(NVARCHAR(36), NEWID());
DECLARE @Don INT, @PBCu BINARY(8);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử phiên bản', @MoTa = @Dau;
    SELECT @Don = Id, @PBCu = PhienBan FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau;
    EXEC dbo.sp_TaoBaoGiaSoBo @NguoiThucHienId = @DPV, @DonHangId = @Don,
        @PhiKiemTra = 50000, @TienCong = 200000, @TyLeHoaHong = 15,
        @ChanDoan = N'Báo giá làm thay đổi phiên bản đơn', @PhienBanDuKien = @PBCu;
    SELECT @PBCu AS PhienBanFormCu, PhienBan AS PhienBanHienTai FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @Khach, @DonHangId = @Don,
        @TrangThaiTiepTheo = 'Huy', @PhienBanDuKien = @PBCu, @LyDo = N'Thử dùng phiên bản cũ';
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: chưa chặn phiên bản cũ.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiPhienBan;
END CATCH;
-- ROWVERSION là số nhị phân 8 byte do SQL cấp, không phải ngày giờ.
GO

-- D05. TRIGGER NHIỀU DÒNG: CHECK chấp nhận HoanThanh, trigger chặn nhảy trạng thái.
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @Dau NVARCHAR(100) = N'[TH-D05] ' + CONVERT(NVARCHAR(36), NEWID());
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử trigger 1', @MoTa = @Dau;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử trigger 2', @MoTa = @Dau;
    UPDATE dbo.DonHang SET TrangThai = 'HoanThanh' WHERE MoTa = @Dau;
    ROLLBACK TRANSACTION;
    THROW 51999, N'Kiểm tra thất bại: trigger chưa chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS LoiTrigger;
END CATCH;
SELECT COUNT(*) AS SoDonThuConLai FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau; -- 0.
-- inserted là trạng thái mới, deleted là trạng thái cũ; EXISTS xử lý cả tập hợp.
GO

-- D06. VẬT TƯ -> NGHIỆM THU: 2 * 50000 = 100000; không gửi khách duyệt bảng kê.
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
GO

-- D07. HỖ TRỢ: chỉ gửi yêu cầu mới tạo phiếu, rồi CSKH tiếp nhận/giải quyết.
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @CSKH INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'CSKH' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @Dau NVARCHAR(100) = N'[TH-D07] ' + CONVERT(NVARCHAR(36), NEWID());
DECLARE @Don INT, @HoTro INT, @PB BINARY(8);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử hỗ trợ', @MoTa = @Dau;
    SELECT @Don = Id FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau;
    SELECT COUNT(*) AS SoHoTroSauDatDon FROM dbo.vw_YeuCauHoTro WHERE DonHangId = @Don; -- 0.
    EXEC dbo.sp_TaoYeuCauHoTro @NguoiThucHienId = @Khach, @DonHangId = @Don, @Loai = 'Complaint', @MoTa = N'Cần giải thích nội dung dịch vụ.';
    SELECT @HoTro = Id, @PB = PhienBan FROM dbo.vw_YeuCauHoTro WHERE DonHangId = @Don;
    EXEC dbo.sp_XuLyHoTro @NguoiThucHienId = @CSKH, @YeuCauHoTroId = @HoTro,
        @TrangThai = 'InProgress', @PhienBanDuKien = @PB;
    EXEC dbo.sp_ThemTraoDoiHoTro @NguoiThucHienId = @CSKH, @YeuCauHoTroId = @HoTro, @NoiDung = N'Đã liên hệ và giải thích cho khách.';
    SELECT @PB = PhienBan FROM dbo.vw_YeuCauHoTro WHERE Id = @HoTro;
    EXEC dbo.sp_XuLyHoTro @NguoiThucHienId = @CSKH, @YeuCauHoTroId = @HoTro,
        @TrangThai = 'Resolved', @KetQuaXuLy = N'Khách đã hiểu nội dung dịch vụ.', @PhienBanDuKien = @PB;
    SELECT Id, TrangThai, TenNguoiXuLy FROM dbo.vw_YeuCauHoTro WHERE Id = @HoTro;
    SELECT NoiDung, TrangThai, NgayTao FROM dbo.vw_TraoDoiHoTro WHERE YeuCauHoTroId = @HoTro ORDER BY Id;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- D08. HỦY SAU DI CHUYỂN: xác nhận mức phí, snapshot phí, rollback ngay.
DECLARE @Don INT, @Khach INT, @PB BINARY(8), @Phi DECIMAL(18,2);
SELECT TOP (1) @Don = Id, @Khach = KhachHangId, @PB = PhienBan FROM dbo.vw_DonHangTongHop
WHERE TrangThai IN ('DangDiChuyen', 'DaDenNoi') ORDER BY Id;
SELECT @Phi = TRY_CONVERT(DECIMAL(18,2), GiaTri) FROM dbo.vw_CauHinh WHERE Khoa = 'PhiHuyDon';
IF @Don IS NULL
    SELECT N'Cần đơn DangDiChuyen/DaDenNoi để thử phí hủy. Không dùng đơn DangXuLy.' AS CanChuanBi;
ELSE
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_ChuyenTrangThaiDon @NguoiThucHienId = @Khach, @DonHangId = @Don,
        @TrangThaiTiepTheo = 'Huy', @PhienBanDuKien = @PB, @LyDo = N'Thử phí hủy khi thợ đã di chuyển',
        @DongYPhiHuy = 1, @PhiHuyDuKien = @Phi;
    SELECT Id, TrangThai, PhiHuyDon, TongTien FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- PhiHuyDon mặc định 60000, chỉ BANK; KT xác nhận rồi đối soát cộng đủ phí vào ví thợ.
-- Trước di chuyển: 0. Đã bắt đầu sửa: yêu cầu CSKH, không hủy trực tiếp.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO
