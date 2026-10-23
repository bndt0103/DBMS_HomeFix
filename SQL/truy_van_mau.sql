/* Bài học theo phân công 4 thành viên: xem thuc_hanh_nhom/HUONG_DAN.md.
   01_NguyenQuocViet.sql: schema, ràng buộc, seed, index trước/sau.
   02_DoAnhTuan.sql: view, function, tổng hợp và báo cáo.
   03_BuiNguyenDuyTrung.sql: SP, transaction, savepoint, phiên bản và nghiệp vụ.
   04_LeTanTai.sql: trigger, GRANT/REVOKE/DENY, đối soát và migration.
   04b_SaoLuuPhucHoi.sql: FULL/DIFF/LOG và phục hồi thực tế.
   File hiện tại vẫn giữ các truy vấn tổng hợp để tra cứu nhanh. */
USE [HomeFix_DBMS_Clean_20261022];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Chọn từng khối, nhấn F5. Không chạy CSDL_HomeFix.sql để demo trên database đã có.
   du_lieu_mau.sql bổ sung dữ liệu; file này dùng dữ liệu đó để đọc và thử rollback.
   Các khối cố ý gây lỗi đều bắt lỗi và rollback; không xóa đơn thật.
   Sau rollback, số ID có thể bị nhảy: IDENTITY không được hoàn lại. */

-- 1. XÁC NHẬN DATABASE, KHÁCH HÀNG VÀ DANH MỤC
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL;
SELECT Id, HoTen, SoDienThoai, DiaChi, VaiTro FROM dbo.vw_NguoiDung
WHERE SoDienThoai LIKE '0900001%' OR SoDienThoai LIKE '0900002%' ORDER BY VaiTro, Id;
SELECT MaDanhMuc, TenDanhMuc, COUNT(*) AS SoDichVu FROM dbo.vw_DichVuCongKhai
GROUP BY MaDanhMuc, TenDanhMuc ORDER BY MaDanhMuc;
SELECT Id, TenDanhMuc, Ten, PhiKiemTra, TienCong, TyLeHoaHong FROM dbo.vw_DichVuCongKhai ORDER BY DanhMucId, Id;
GO
-- 2. VIEW: ĐƠN, DOANH THU, ĐỐI SOÁT VÍ VÀ HỖ TRỢ
SELECT Id, TenKhachHang, TenDichVu, DiaChi, TrangThai, TongTien FROM dbo.vw_DonHangTongHop
WHERE MoTa LIKE N'[[]MINHHOA-%' ORDER BY Id;
SELECT TrangThai, COUNT(*) AS SoDon FROM dbo.vw_DonHangTongHop
WHERE MoTa LIKE N'[[]MINHHOA-%' GROUP BY TrangThai;
SELECT * FROM dbo.vw_DoanhThuNgay ORDER BY Ngay DESC;
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien ORDER BY Id;
SELECT * FROM dbo.vw_HieuSuatKyThuatVien ORDER BY KyThuatVienId;
SELECT Id, TenKhachHang, Loai, MoTa, TrangThai FROM dbo.vw_HoTroCanXuLy ORDER BY Id;
-- Bộ mẫu mới có 10 đơn, trong đó 3 hoàn thành; trạng thái có thể đổi khi thao tác web. ChenhLech ví phải bằng 0.
GO
-- 3. FUNCTION: TÍNH TIỀN, SỐ DƯ, ĐÁNH GIÁ, THỐNG KÊ VÀ BẢO HÀNH
SELECT dbo.fn_HoaHong(200000, 15) AS HoaHong; -- 30000
SELECT * FROM dbo.fn_ThongKeDon(NULL, NULL);
SELECT t.Id, t.HoTen, v.SoDu, dg.DiemTrungBinh FROM dbo.vw_KyThuatVien t
CROSS APPLY dbo.fn_SoDuVi(t.Id) v CROSS APPLY dbo.fn_DiemDanhGia(t.Id) dg ORDER BY t.Id;
SELECT d.Id, d.TrangThai, dbo.fn_TongTienDonHang(d.Id) AS TongTienTinh, bh.HanBaoHanh
FROM dbo.vw_DonHangTongHop d CROSS APPLY dbo.fn_HanBaoHanh(d.Id) bh
WHERE d.MoTa LIKE N'[[]MINHHOA-%' ORDER BY d.Id;
GO
-- 4. STORED PROCEDURE BÁO CÁO: NHIỀU BẢNG KẾT QUẢ
DECLARE @GiamDoc INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'GD' AND DangHoatDong = 1);
EXEC dbo.sp_BaoCaoTongHop @NguoiThucHienId = @GiamDoc;
GO
-- 5. TRANSACTION: TẠO ĐƠN RỒI ROLLBACK, KHÔNG ĐỂ LẠI ĐƠN THỬ
DECLARE @Khach INT = (SELECT Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900001005');
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @SoDonTruoc INT = (SELECT COUNT(*) FROM dbo.DonHang);
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử giao dịch', @MoTa = N'[DEMO-ROLLBACK] Đơn tạo để quan sát giao dịch.';
    SELECT COUNT(*) AS SoDonTrongGiaoDich FROM dbo.DonHang;
    ROLLBACK TRANSACTION;
    SELECT @SoDonTruoc AS SoDonTruoc, COUNT(*) AS SoDonSauRollback FROM dbo.DonHang;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- 6. SAVEPOINT: QUAY LẠI ĐIỂM LƯU RỒI COMMIT GIAO DỊCH NGOÀI
DECLARE @Khach INT = (SELECT Id FROM dbo.vw_NguoiDung WHERE SoDienThoai = '0900001005');
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
BEGIN TRY
    BEGIN TRANSACTION;
    SAVE TRANSACTION TruocKhiTaoDon;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu, @DiaChi = N'Địa chỉ thử savepoint', @MoTa = N'[DEMO-SAVEPOINT] Đơn sẽ được quay lại điểm lưu.';
    ROLLBACK TRANSACTION TruocKhiTaoDon;
    SELECT COUNT(*) AS SoDonConLai FROM dbo.DonHang WHERE MoTa LIKE N'[[]DEMO-SAVEPOINT]%'; -- 0
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- 7. CHECK: THỬ TIỀN CÔNG ÂM, MONG ĐỢI LỖI 547
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.DichVu SET TienCong = -1 WHERE Id = (SELECT MIN(Id) FROM dbo.DichVu);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Lỗi kiểm tra: giá âm không bị chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 THROW;
    SELECT ERROR_NUMBER() AS MaLoiDuKien, ERROR_MESSAGE() AS LoiCheck;
END CATCH;
GO
-- 8. FOREIGN KEY: THAM CHIẾU DANH MỤC KHÔNG TỒN TẠI, LỖI 547
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    VALUES (-1, N'Dịch vụ thử FK', N'Chỉ dùng để kiểm tra khóa ngoại.', 0, 100000, 15);
    ROLLBACK TRANSACTION;
    THROW 51999, N'Lỗi kiểm tra: khóa ngoại không bị chặn.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 THROW;
    SELECT ERROR_NUMBER() AS MaLoiDuKien, ERROR_MESSAGE() AS LoiKhoaNgoai;
END CATCH;
GO
-- 9. TRIGGER: KHÔNG CHO NHẢY TỪ ĐƠN MỚI SANG HOÀN THÀNH
DECLARE @Khach INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'KH' AND DangHoatDong = 1);
DECLARE @DichVu INT = (SELECT MIN(Id) FROM dbo.vw_DichVuCongKhai);
DECLARE @DonMoi INT, @Dau NVARCHAR(100) = CONVERT(NVARCHAR(36), NEWID());
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_TaoDonHang @NguoiThucHienId = @Khach, @DichVuId = @DichVu,
        @DiaChi = N'Địa chỉ kiểm tra trigger', @MoTa = @Dau;
    SELECT @DonMoi = Id FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau;
    UPDATE dbo.DonHang SET TrangThai = 'HoanThanh' WHERE Id = @DonMoi;
    ROLLBACK TRANSACTION;
    THROW 51999, N'Lỗi kiểm tra: trigger không chặn nhảy trạng thái.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51009 THROW;
    SELECT ERROR_NUMBER() AS MaLoiDuKien, ERROR_MESSAGE() AS LoiTrigger;
END CATCH;
SELECT COUNT(*) AS SoDonThuConLai FROM dbo.vw_DonHangTongHop WHERE MoTa = @Dau; -- 0

GO
-- 10. INDEX: XEM CHỈ MỤC VÀ KẾ HOẠCH THỰC THI (BẬT CTRL+M TRONG SSMS)
SELECT i.name AS ChiMuc, i.is_unique AS DuyNhat, i.filter_definition AS DieuKienLoc
FROM sys.indexes i WHERE i.object_id = OBJECT_ID('dbo.DonHang') AND i.name IS NOT NULL;
DECLARE @Khach INT = (SELECT Id FROM dbo.NguoiDung WHERE SoDienThoai = '0900001001');
SET STATISTICS IO ON;
SELECT Id, KhachHangId, TrangThai, NgayTao FROM dbo.DonHang WHERE KhachHangId = @Khach;
-- Gợi ý chỉ dùng để minh họa Index Seek; không áp dụng máy móc cho mọi truy vấn.
SELECT Id, KhachHangId, TrangThai, NgayTao FROM dbo.DonHang WITH (INDEX(IX_DonHang_Khach_TrangThai), FORCESEEK)
WHERE KhachHangId = @Khach;
SET STATISTICS IO OFF;
-- Dữ liệu ít: optimizer có thể chọn Scan. Index không bảo đảm mọi truy vấn nhanh hơn.
GO
-- 11. BẢO MẬT: VIEW ĐƯỢC ĐỌC; BẢNG VÀ HASH BỊ CHẶN. LUÔN REVERT.
EXECUTE AS USER = 'hf_KH';
BEGIN TRY
    SELECT TOP (5) Id, Ten, PhiKiemTra FROM dbo.vw_DichVuCongKhai ORDER BY Id;
    BEGIN TRY
        SELECT MatKhauBam FROM dbo.NguoiDung;
        THROW 51999, N'Lỗi kiểm tra: role khách đọc được bảng mật khẩu.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (229, 230) THROW;
        SELECT USER_NAME() AS NguCanh, ERROR_NUMBER() AS MaLoiDuKien, ERROR_MESSAGE() AS LoiQuyen;
    END CATCH;
    REVERT;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
SELECT USER_NAME() AS DaTroLaiNguCanhBanDau;
GO
-- 12. ĐỐI CHIẾU SAU DEMO: KHÔNG CÒN GIAO DỊCH MỞ HOẶC VÍ LỆCH
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien WHERE ChenhLech <> 0; -- rỗng
GO

-- 13. VẬT TƯ: XEM ĐƠN GIÁ VÀ CHI PHÍ TRÊN PHIẾU NGHIỆM THU
SELECT bk.Id, bk.DonHangId, bk.LanSuaDoi, bk.DangApDung, ct.Ten, ct.SoLuong, ct.DonGia, ct.ThanhTien
FROM dbo.vw_BangKeVatTu bk INNER JOIN dbo.vw_ChiTietVatTu ct ON ct.BangKeVatTuId = bk.Id
ORDER BY bk.DonHangId, bk.LanSuaDoi, ct.Id;
SELECT Id, DonHangId, BangKeVatTuId, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai
FROM dbo.vw_PhieuNghiemThu ORDER BY Id;
GO
-- 14. SP KÊ KHAI VẬT TƯ -> NGHIỆM THU, KHÔNG CÓ BƯỚC KHÁCH DUYỆT VẬT TƯ
-- Chỉ thao tác thử trong transaction ngoài, toàn bộ được rollback.
DECLARE @Don INT, @Tho INT, @PB BINARY(8);
SELECT TOP (1) @Don = Id, @Tho = KyThuatVienId FROM dbo.vw_DonHangTongHop
WHERE TrangThai = 'DangXuLy' AND KyThuatVienId IS NOT NULL ORDER BY Id;
IF @Don IS NULL
    PRINT N'Chưa có đơn đang xử lý. Có thể chạy luồng đặt đơn, phân công và tiến độ trên web trước.';
ELSE
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
        EXEC dbo.sp_LuuBangKeVatTu @NguoiThucHienId = @Tho, @DonHangId = @Don,
            @VatTu = N'[{"Ten":"Linh kiện thử nghiệm","SoLuong":2,"DonGia":50000,"SoThangBaoHanh":6}]', @PhienBanDuKien = @PB;
        SELECT dbo.fn_TongTienDonHang(@Don) AS TongTienSauKeKhai;
        SELECT @PB = PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @Don;
        EXEC dbo.sp_TaoPhieuNghiemThu @NguoiThucHienId = @Tho, @DonHangId = @Don,
            @NguyenNhan = N'Linh kiện hư hỏng', @PhuongAnXuLy = N'Thay linh kiện, kiểm tra lại', @PhienBanDuKien = @PB;
        SELECT TongTienVatTu, PhiKiemTra, TienCong, TongTien FROM dbo.vw_PhieuNghiemThu
        WHERE DonHangId = @Don AND TrangThai = 'Pending'; -- Vật tư 100000; tổng do SQL tính.
        ROLLBACK TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0
GO

-- 15. PHÍ HỦY: TRẠNG THÁI ĐƠN KHÁC VỚI TRẠNG THÁI THANH TOÁN/ĐỐI SOÁT
SELECT d.Id, d.TrangThai, d.PhiHuyDon, tt.LoaiThanhToan, tt.PhuongThuc, tt.SoTien,
    ds.TrangThai AS TrangThaiDoiSoat, ds.TienHoaHong
FROM dbo.vw_DonHangTongHop d
LEFT JOIN dbo.vw_ThanhToan tt ON tt.DonHangId = d.Id
LEFT JOIN dbo.vw_DoiSoat ds ON ds.DonHangId = d.Id
WHERE d.TrangThai = 'Huy' ORDER BY d.Id;
-- Hủy trước di chuyển: phí 0. Sau di chuyển: 60000, BANK, hoa hồng 0.
GO
-- 16. HỖ TRỢ: KHÁCH GỬI, CSKH TIẾP NHẬN; LỊCH SỬ CÓ THỜI GIAN THỰC
SELECT Id, DonHangId, TenKhachHang, Loai, MoTa, TrangThai, TenNguoiXuLy, NgayTao, NgayCapNhat
FROM dbo.vw_YeuCauHoTro ORDER BY Id DESC;
SELECT YeuCauHoTroId, HoTen, VaiTro, NoiDung, TrangThai, NgayTao
FROM dbo.vw_TraoDoiHoTro ORDER BY YeuCauHoTroId, Id;
-- Bộ mẫu sạch có thể chưa có phiếu: tạo bằng nút Gửi yêu cầu hỗ trợ trên web.
GO
