-- Thủ tục tra cứu và trigger nghiệp vụ.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Tra cứu đơn hàng của khách hàng.
CREATE OR ALTER PROCEDURE dbo.sp_DonHangCuaKhach
    @KhachHangId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.*, CASE WHEN t.Id IS NULL THEN 'Unpaid' ELSE 'Paid' END AS TrangThaiThanhToan
    FROM dbo.DonHang AS d
         LEFT OUTER JOIN dbo.ThanhToan AS t ON t.DonHangId = d.Id
    WHERE KhachHangId = @KhachHangId
    ORDER BY d.Id DESC;
END
GO

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
               WHERE i.KhachHangId <> d.KhachHangId OR d.TrangThai <> 'HoanThanh' OR p.Id IS NULL OR i.KyThuatVienId <> p.NguoiThuTienId)
        THROW 51009, 'REVIEW_NOT_ELIGIBLE', 1;
END
GO
