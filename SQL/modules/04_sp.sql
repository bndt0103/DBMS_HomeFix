-- HomeFix / 04_sp: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/CSDL_HomeFix_02_ThuTucVaTrigger.sql
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

-- Nguồn: SRC/database/CSDL_HomeFix_12_HamVaView.sql
-- Báo cáo đơn hàng theo khoảng thời gian.
CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTongHop
    @TuNgay DATETIME2,
    @DenNgay DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @TuNgay IS NULL OR @DenNgay IS NULL OR @TuNgay >= @DenNgay
            THROW 51009, 'INVALID_DATE_RANGE', 1;
        SELECT *
        FROM dbo.fn_ThongKeDon(@TuNgay, @DenNgay)
        ORDER BY NhomDichVu;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
