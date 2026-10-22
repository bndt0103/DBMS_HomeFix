SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Trigger bảo vệ dữ liệu kể cả khi người quản trị thao tác trực tiếp trong SSMS.
   inserted/deleted là TẬP HỢP dòng, không giả định một dòng hoặc dùng con trỏ. */
CREATE OR ALTER TRIGGER dbo.tr_DonHang_KiemTraTrangThai
ON dbo.DonHang AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        LEFT JOIN deleted AS d ON d.Id = i.Id
        WHERE (d.Id IS NULL AND i.TrangThai <> 'ChoTiepNhan')
           OR (d.Id IS NOT NULL AND i.TrangThai <> d.TrangThai AND NOT (
                (d.TrangThai = 'ChoTiepNhan' AND i.TrangThai = 'ChoDuyetSoBo')
             OR (d.TrangThai = 'ChoDuyetSoBo' AND i.TrangThai IN ('ChoPhanCong','ChoTiepNhan'))
             OR (d.TrangThai = 'ChoPhanCong' AND i.TrangThai = 'ChoNhan')
             OR (d.TrangThai = 'ChoNhan' AND i.TrangThai IN ('DaTiepNhan','ChoPhanCong'))
             OR (d.TrangThai = 'DaTiepNhan' AND i.TrangThai = 'DangDiChuyen')
             OR (d.TrangThai = 'DangDiChuyen' AND i.TrangThai = 'DaDenNoi')
             OR (d.TrangThai = 'DaDenNoi' AND i.TrangThai = 'DangXuLy')
             OR (d.TrangThai = 'DangXuLy' AND i.TrangThai = 'ChoNghiemThu')
             OR (d.TrangThai = 'ChoNghiemThu' AND i.TrangThai = 'HoanThanh')
             OR (d.TrangThai IN ('ChoTiepNhan','ChoDuyetSoBo','ChoPhanCong','ChoNhan','DaTiepNhan','DangDiChuyen','DaDenNoi') AND i.TrangThai = 'Huy')
           ))
    ) THROW 51009, N'Trạng thái đơn không được chuyển theo bước này.', 1;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        WHERE i.TrangThai IN ('DaTiepNhan','DangDiChuyen','DaDenNoi','DangXuLy','ChoNghiemThu','HoanThanh')
          AND i.KyThuatVienId IS NULL
    ) THROW 51009, N'Đơn đã tiếp nhận phải có kỹ thuật viên.', 1;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        WHERE i.TrangThai = 'HoanThanh'
          AND NOT EXISTS (SELECT 1 FROM dbo.ThanhToan AS tt WHERE tt.DonHangId = i.Id)
    ) THROW 51009, N'Chỉ hoàn thành đơn đã ghi nhận thanh toán.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ThanhToan_KiemTraChungTu
ON dbo.ThanhToan AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.PhieuNghiemThu AS nt ON nt.Id = i.NghiemThuId
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        WHERE nt.DonHangId <> i.DonHangId OR nt.TrangThai <> 'Approved'
           OR nt.TongTien <> i.SoTien OR nt.PhuongThucThanhToan <> i.PhuongThuc
           OR dh.TrangThai <> 'ChoNghiemThu'
    ) THROW 51009, N'Thanh toán phải khớp nghiệm thu đã được khách và thợ ký.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ThanhToan_BatBien
ON dbo.ThanhToan INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 51009, N'Không được sửa/xóa chứng từ thanh toán; lập chứng từ điều chỉnh.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_GiaoDichVi_BatBien
ON dbo.GiaoDichVi INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 51009, N'Sổ cái ví chỉ được ghi thêm; không sửa hoặc xóa lịch sử.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_DanhGia_KiemTraDon
ON dbo.DanhGia AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        WHERE dh.TrangThai <> 'HoanThanh' OR dh.KhachHangId <> i.KhachHangId
           OR dh.KyThuatVienId <> i.KyThuatVienId OR dh.KyThuatVienId IS NULL
    ) THROW 51009, N'Đánh giá phải thuộc khách hàng và kỹ thuật viên của đơn hoàn thành.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_ChiTietVatTu_KhoaDaDuyet
ON dbo.ChiTietDeXuatVatTu AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM dbo.DeXuatVatTu AS dx
        WHERE dx.TrangThai <> 'Pending' AND (
            EXISTS (SELECT 1 FROM inserted AS i WHERE i.DeXuatVatTuId = dx.Id)
            OR EXISTS (SELECT 1 FROM deleted AS d WHERE d.DeXuatVatTuId = dx.Id)
        )
    ) THROW 51009, N'Vật tư đã duyệt/từ chối phải lập phiên bản đề xuất mới.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.tr_PhieuNghiemThu_KiemTraChuKy
ON dbo.PhieuNghiemThu AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        INNER JOIN dbo.DonHang AS dh ON dh.Id = i.DonHangId
        LEFT JOIN dbo.TepDinhKem AS ckktv ON ckktv.Id = i.ChuKyKTVId
        LEFT JOIN dbo.TepDinhKem AS ckkh ON ckkh.Id = i.ChuKyKHId
        WHERE dh.KyThuatVienId <> i.KyThuatVienId
           OR (i.ChuKyKTVId IS NOT NULL AND (ckktv.ChuSoHuuId <> i.KyThuatVienId OR ckktv.DonHangId <> i.DonHangId OR ckktv.DonHangId IS NULL OR ckktv.MucDich <> 'TechnicianSignature'))
           OR (i.ChuKyKHId IS NOT NULL AND (ckkh.ChuSoHuuId <> dh.KhachHangId OR ckkh.DonHangId <> i.DonHangId OR ckkh.DonHangId IS NULL OR ckkh.MucDich <> 'CustomerSignature'))
    ) THROW 51009, N'Chữ ký phải thuộc đúng chủ sở hữu, đơn hàng và mục đích.', 1;
END;
GO
