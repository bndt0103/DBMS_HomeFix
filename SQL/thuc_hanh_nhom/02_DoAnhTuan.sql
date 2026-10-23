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
/* ĐỖ ANH TUẤN - 24110369. Module 02, 03; phần báo cáo trong 05.
   Chọn trọn từng khối T01..T06. Không cần Id cố định.
   Đọc dữ liệu hiện có; đối tượng thực hành T06 được rollback ngay. */

-- T01. VIEW VÀ JOIN: nối khách - đơn - dịch vụ; giữ cả đơn chưa có thợ.
SELECT Id, TenKhachHang, SDTKhachHang, TenDichVu, TenKyThuatVien, TrangThai, TongTien
FROM dbo.vw_DonHangTongHop ORDER BY Id;
SELECT dm.Ten AS DanhMuc, dv.Ten AS DichVu, dv.PhiKiemTra, dv.TienCong
FROM dbo.vw_DanhMucDichVu dm INNER JOIN dbo.vw_DichVu dv ON dv.DanhMucId = dm.Id
WHERE dm.DangHoatDong = 1 AND dv.DangHoatDong = 1 ORDER BY dm.Id, dv.Id;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vw_DonHangTongHop')) AS MaNguonView;
-- INNER JOIN: cần dòng tương ứng. LEFT JOIN: đơn chưa phân công vẫn xuất hiện.
-- View thường không lưu sẵn kết quả; được truy vấn từ bảng gốc tại thời điểm đọc.
GO

-- T02. GROUP BY, HAVING, COUNT, SUM: đếm/tổng hợp, không nhân đôi đơn.
SELECT TrangThai, COUNT(*) AS SoDon FROM dbo.vw_DonHangTongHop GROUP BY TrangThai;
SELECT KhachHangId, TenKhachHang, COUNT(*) AS SoDon, SUM(TongTien) AS TongGiaTri
FROM dbo.vw_DonHangTongHop GROUP BY KhachHangId, TenKhachHang HAVING COUNT(*) >= 2;
SELECT Ngay, SoDon, TongThu, ThuCOD, ThuNganHang, TienHoaHong, HoaHongDaDoiSoat
FROM dbo.vw_DoanhThuNgay ORDER BY Ngay DESC;
-- WHERE lọc từng dòng trước GROUP BY. HAVING lọc nhóm sau tổng hợp.
-- TongThu là tiền đã thu, không phải lợi nhuận. HoaHongDaDoiSoat là phần đã chốt.
GO

-- T03. SCALAR FUNCTION: một giá trị; TVF: một bảng dùng trong FROM/APPLY.
SELECT dbo.fn_HoaHong(200000, 15) AS HoaHong; -- 30000, 15 nghĩa là 15%.
SELECT d.Id, d.TrangThai, d.PhiHuyDon, dbo.fn_TongTienDonHang(d.Id) AS TongTien
FROM dbo.vw_DonHangTongHop d ORDER BY d.Id;
SELECT k.Id, k.HoTen, v.SoDu, dg.DiemTrungBinh
FROM dbo.vw_KyThuatVien k
CROSS APPLY dbo.fn_SoDuVi(k.Id) v CROSS APPLY dbo.fn_DiemDanhGia(k.Id) dg ORDER BY k.Id;
SELECT * FROM dbo.fn_ThongKeDon(NULL, NULL);
SELECT * FROM dbo.fn_ThongKeDon('20261001', '20261031');
SELECT d.Id, d.TrangThai, bh.HanBaoHanh
FROM dbo.vw_DonHangTongHop d CROSS APPLY dbo.fn_HanBaoHanh(d.Id) bh ORDER BY d.Id;
-- Không có đánh giá/sổ ví: COALESCE trả 0. Không có bảo hành: HanBaoHanh NULL.
-- Ngày lọc là ngày Việt Nam; hàm đổi mốc biên về UTC, dùng >= đầu và < đầu ngày kế.
GO

-- T04. GIÁ VẬT TƯ VÀ NGHIỆM THU: không có bước duyệt bảng kê vật tư.
SELECT bk.DonHangId, bk.LanSuaDoi, bk.DangApDung, ct.Ten, ct.SoLuong, ct.DonGia, ct.ThanhTien
FROM dbo.vw_BangKeVatTu bk INNER JOIN dbo.vw_ChiTietVatTu ct ON ct.BangKeVatTuId = bk.Id
ORDER BY bk.DonHangId, bk.LanSuaDoi, ct.Id;
SELECT Id, DonHangId, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai
FROM dbo.vw_PhieuNghiemThu ORDER BY Id;
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien ORDER BY Id;
-- ThanhTien = SoLuong * DonGia. TongTien = PhiKiemTra + TienCong + TongTienVatTu.
-- Hoa hồng tính trên TienCong, không tính trên giá vật tư. ChenhLech phải bằng 0.
GO

-- T05. BÁO CÁO NHIỀU TẬP KẾT QUẢ: EXEC thủ tục chỉ đọc, không mở transaction.
DECLARE @GiamDoc INT = (SELECT MIN(Id) FROM dbo.vw_NguoiDung WHERE VaiTro = 'GD' AND DangHoatDong = 1);
EXEC dbo.sp_BaoCaoTongHop @NguoiThucHienId = @GiamDoc;
SELECT KyThuatVienId, HoTen, TongDon, SoDonHoanThanh, DiemTrungBinh, TongTienDaThu
FROM dbo.vw_HieuSuatKyThuatVien ORDER BY KyThuatVienId;
-- Đọc lần lượt các result grid của SP; tên cột và số liệu có thể đổi theo dữ liệu web.
GO

-- T06. TỰ VIẾT VIEW/HÀM NGẮN: tạo, dùng, rồi rollback để không để lại đối tượng.
-- CREATE VIEW/FUNCTION phải đứng đầu batch; EXEC dưới đây tạo một batch DDL riêng.
-- Hai tên chỉ phục vụ học tập, không thay thế view/hàm của ứng dụng.
IF OBJECT_ID('dbo.vw_ThucHanh_DonTheoTrangThai') IS NOT NULL OR OBJECT_ID('dbo.fn_ThucHanh_HoaHong') IS NOT NULL
    THROW 51999, N'Tên đối tượng thực hành đã tồn tại. Không ghi đè.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC(N'CREATE VIEW dbo.vw_ThucHanh_DonTheoTrangThai AS
        SELECT TrangThai, COUNT_BIG(*) AS SoDon FROM dbo.DonHang GROUP BY TrangThai;');
    EXEC(N'SELECT TrangThai, SoDon FROM dbo.vw_ThucHanh_DonTheoTrangThai;');
    EXEC(N'CREATE FUNCTION dbo.fn_ThucHanh_HoaHong(@TienCong DECIMAL(18,2), @TyLe DECIMAL(5,2))
        RETURNS DECIMAL(18,2) AS BEGIN RETURN ROUND(@TienCong * @TyLe / 100, 2); END;');
    EXEC(N'SELECT dbo.fn_ThucHanh_HoaHong(200000, 15) AS KetQua;'); -- 30000.
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT OBJECT_ID('dbo.vw_ThucHanh_DonTheoTrangThai') AS ViewDaGo,
    OBJECT_ID('dbo.fn_ThucHanh_HoaHong') AS HamDaGo; -- cả hai NULL.
SELECT @@TRANCOUNT AS SoGiaoDichDangMo; -- 0.
GO
