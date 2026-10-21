-- HomeFix / 06_trigger: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_02_ThuTucVaTrigger.sql
-- Cập nhật số dư sau khi ghi giao dịch ví.
CREATE OR ALTER TRIGGER dbo.trg_Vi_GhiSo
    ON dbo.GiaoDichVi
    AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    WITH ChenhLechVi
    AS (SELECT KyThuatVienId, SUM(SoTien) AS SoTien
        FROM inserted
        GROUP BY KyThuatVienId)
    UPDATE k
    SET SoDu = k.SoDu + d.SoTien
    FROM dbo.KyThuatVien AS k
         INNER JOIN ChenhLechVi AS d ON d.KyThuatVienId = k.Id;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_02_ThuTucVaTrigger.sql
-- Ngăn sửa và xóa giao dịch ví.
CREATE OR ALTER TRIGGER dbo.trg_Vi_BatBien
    ON dbo.GiaoDichVi
    INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51009, 'LEDGER_IMMUTABLE', 1;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_02_ThuTucVaTrigger.sql
-- Ngăn sửa và xóa khoản thanh toán.
CREATE OR ALTER TRIGGER dbo.trg_ThanhToan_BatBien
    ON dbo.ThanhToan
    INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51009, 'PAYMENT_IMMUTABLE', 1;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_02_ThuTucVaTrigger.sql
-- Ghi nhật ký khi trạng thái đơn thay đổi.
CREATE OR ALTER TRIGGER dbo.trg_DonHang_GhiNhatKy
    ON dbo.DonHang
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.NhatKy (ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
    SELECT 'OrderStatus', 'DonHang', i.Id, CONCAT(d.TrangThai, ' -> ', i.TrangThai)
    FROM inserted AS i
         INNER JOIN deleted AS d ON d.Id = i.Id
    WHERE i.TrangThai <> d.TrangThai;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_05_ThanhToanNganHang.sql
-- Kiểm tra điều kiện đánh giá dịch vụ.
CREATE OR ALTER TRIGGER dbo.trg_DanhGia_DieuKien
    ON dbo.DanhGia
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.DonHang AS d ON d.Id = i.DonHangId
                    LEFT OUTER JOIN dbo.ThanhToan AS p ON p.DonHangId = d.Id
                    LEFT OUTER JOIN dbo.PhieuNghiemThu AS a ON a.Id = p.NghiemThuId
               WHERE i.KhachHangId <> d.KhachHangId OR d.TrangThai <> 'HoanThanh' OR p.Id IS NULL OR i.KyThuatVienId <> a.KyThuatVienId)
        THROW 51009, 'REVIEW_NOT_ELIGIBLE', 1;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_09_DeXuatChinhSach.sql
-- Gửi thông báo cho giám đốc khi có đề xuất chính sách mới.
CREATE OR ALTER TRIGGER dbo.trg_DeXuatChinhSach_ThongBaoGiamDoc
ON dbo.DeXuatChinhSach
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT dbo.ThongBao (NguoiDungId, TieuDe, NoiDungThongBao)
    SELECT
        gd.Id,
        N'Đề xuất chính sách mới cần duyệt',
        CONCAT(i.MaDeXuat, N' · ', i.TieuDe, N' — ', i.BoPhan)
    FROM inserted i
    CROSS JOIN dbo.NguoiDung gd
    WHERE gd.VaiTro = 'GD'
      AND gd.DangHoatDong = 1;
END;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
-- Kiểm tra vai trò khách hàng của đơn.
CREATE OR ALTER TRIGGER dbo.trg_DonHang_KhachHang
    ON dbo.DonHang
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.NguoiDung AS u ON u.Id = i.KhachHangId
               WHERE u.VaiTro <> 'KH')
        THROW 51009, 'CUSTOMER_ROLE_REQUIRED', 1;
END
GO

-- Nguồn: SRC/database/CSDL_HomeFix_13_ChiMucVaToanVen.sql
-- Kiểm tra thanh toán khớp nghiệm thu.
CREATE OR ALTER TRIGGER dbo.trg_ThanhToan_NghiemThu
    ON dbo.ThanhToan
    AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted AS i
                    INNER JOIN dbo.PhieuNghiemThu AS a ON a.Id = i.NghiemThuId
               WHERE a.DonHangId <> i.DonHangId OR a.TrangThai <> 'Approved' OR a.TongTien <> i.SoTien OR (i.PhuongThuc = 'COD' AND i.NguoiThuTienId <> a.KyThuatVienId))
        THROW 51009, 'PAYMENT_ACCEPTANCE_MISMATCH', 1;
END
GO
