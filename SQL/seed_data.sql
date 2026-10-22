SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* DỮ LIỆU BAN ĐẦU SẠCH: 7 người dùng, 1 hồ sơ thợ, 5 nhóm/5 dịch vụ,
   1 tài khoản ngân hàng MÔ PHỎNG và cấu hình. KHÔNG có đơn/OTP/sổ cái/nhật ký.
   Mật khẩu cả 7 tài khoản: 123456. Chỉ dùng cho học tập trên máy cá nhân.
   Script chỉ chèn khi database còn trắng; không xóa giao dịch đang có. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.NguoiDung) OR EXISTS (SELECT 1 FROM dbo.DonHang)
        THROW 51009, N'Seed chỉ chạy trên database trắng. Không tự động xóa dữ liệu hiện có.', 1;
    DECLARE @MatKhauBam VARCHAR(100) = '$2b$10$6R3Jy/EiVEhpVTLlbrO1SuUsl9VMoJuAolWgiIYQ7V/1s0XW8OxHS';
    INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, MatKhauBam, VaiTro)
    VALUES (N'Khách hàng mẫu', '0900000001', @MatKhauBam, 'KH'),
           (N'Kỹ thuật viên mẫu', '0900000002', @MatKhauBam, 'KTV'),
           (N'Điều phối viên mẫu', '0900000003', @MatKhauBam, 'DPV'),
           (N'Chăm sóc khách hàng mẫu', '0900000004', @MatKhauBam, 'CSKH'),
           (N'Kế toán mẫu', '0900000005', @MatKhauBam, 'KT'),
           (N'Giám đốc mẫu', '0900000006', @MatKhauBam, 'GD'),
           (N'Quản trị viên mẫu', '0900000007', @MatKhauBam, 'ADMIN');
    INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu)
    SELECT Id, N'Điện, Nước, Điện lạnh', N'Thành phố Hồ Chí Minh', 'SanSang', 0 FROM dbo.NguoiDung WHERE VaiTro = 'KTV';
    INSERT INTO dbo.DanhMucDichVu(Ten, Ma)
    VALUES (N'Điện lạnh', 'DienLanh'),
           (N'Điện gia dụng', 'DienGiaDung'),
           (N'Điện nước', 'DienNuoc'),
           (N'Vệ sinh & bảo trì', 'VeSinh');

    INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong)
    SELECT c.Id, s.Ten, s.MoTa, s.PhiKiemTra, s.TienCong, 15
    FROM (VALUES
      ('DienLanh', N'Sửa máy lạnh', N'Kiểm tra và sửa máy lạnh không lạnh, chảy nước.', 50000, 300000),
      ('DienLanh', N'Vệ sinh máy lạnh', N'Bảo dưỡng, vệ sinh dàn lạnh và dàn nóng.', 30000, 180000),
      ('DienLanh', N'Sửa tủ lạnh', N'Khắc phục lỗi tủ lạnh không đông đá, hở ron.', 50000, 300000),
      ('DienGiaDung', N'Sửa máy giặt', N'Sửa máy giặt mất nguồn, báo lỗi, không vắt.', 50000, 250000),
      ('DienNuoc', N'Sửa điện nước', N'Sửa rò rỉ, đường ống và thiết bị điện gia đình.', 50000, 200000),
      ('VeSinh', N'Vệ sinh thiết bị', N'Làm sạch và bảo trì định kỳ thiết bị gia đình.', 30000, 150000),
      ('DienNuoc', N'Sửa điện tại nhà', N'Khắc phục sự cố chập điện, mất điện, nhảy aptomat.', 50000, 200000),
      ('DienNuoc', N'Sửa điện 3 pha', N'Khắc phục sự cố tủ điện 3 pha, cân pha công nghiệp.', 100000, 500000),
      ('DienNuoc', N'Lắp quạt trần', N'Thi công và lắp ráp các loại quạt trần dân dụng.', 50000, 250000),
      ('DienNuoc', N'Sửa quạt trần', N'Sửa chữa quạt trần không quay, kêu to, hỏng tụ.', 30000, 150000),
      ('DienNuoc', N'Thi công đèn trong nhà', N'Lắp đặt, đi dây và thiết kế hệ thống chiếu sáng.', 50000, 300000),
      ('DienNuoc', N'Sửa ống nước tại nhà', N'Khắc phục các sự cố bục vỡ, rò rỉ đường ống nước.', 50000, 150000),
      ('DienNuoc', N'Sửa máy bơm nước', N'Kiểm tra và sửa chữa máy bơm nước không lên nước, kêu to.', 50000, 250000),
      ('DienNuoc', N'Lắp phao nước tự động', N'Lắp đặt phao điện, phao cơ ngắt nước tự động.', 30000, 150000),
      ('DienNuoc', N'Thông nghẹt bồn rửa chén', N'Xử lý triệt để bồn rửa chén bị tắc nghẽn nước.', 50000, 250000),
      ('DienNuoc', N'Sửa vòi rửa bát', N'Khắc phục vòi rửa bát bị rò rỉ nước, gãy vòi.', 30000, 100000),
      ('DienNuoc', N'Thay vòi hoa sen', N'Lắp mới, thay thế bộ vòi hoa sen nhà tắm.', 30000, 150000),
      ('DienNuoc', N'Sửa bồn cầu', N'Sửa bồn cầu rỉ nước, hỏng phao, nút nhấn không được.', 50000, 200000),
      ('DienNuoc', N'Dò tìm rò rỉ nước ngầm', N'Sử dụng máy siêu âm tìm điểm vỡ ống nước ngầm âm tường/nền.', 100000, 800000),
      ('DienLanh', N'Bơm gas máy lạnh', N'Kiểm tra và châm thêm gas cho máy lạnh.', 50000, 350000),
      ('DienLanh', N'Vệ sinh máy lạnh âm trần', N'Bảo dưỡng máy lạnh cassette, máy lạnh âm trần ống gió.', 100000, 450000),
      ('DienLanh', N'Sửa tủ mát, tủ đông', N'Bơm gas, thay lốc tủ đông công nghiệp/nhà hàng.', 100000, 500000),
      ('DienGiaDung', N'Vệ sinh máy giặt lồng ngang', N'Tháo lồng và vệ sinh máy giặt cửa trước.', 50000, 400000),
      ('DienGiaDung', N'Vệ sinh máy giặt lồng đứng', N'Tháo lồng và vệ sinh máy giặt cửa trên.', 50000, 250000),
      ('DienGiaDung', N'Sửa lò vi sóng', N'Sửa lò vi sóng mất nguồn, không nóng.', 50000, 200000),
      ('DienGiaDung', N'Sửa máy nước nóng năng lượng mặt trời', N'Khắc phục rò rỉ, thay ống thủy tinh năng lượng mặt trời.', 100000, 400000),
      ('DienGiaDung', N'Sửa máy nước nóng', N'Sửa máy nước nóng trực tiếp/gián tiếp không nóng.', 50000, 250000),
      ('VeSinh', N'Vệ sinh bồn nước inox', N'Súc rửa cặn bẩn bồn nước inox trên cao.', 50000, 350000),
      ('VeSinh', N'Vệ sinh bồn nước ngầm', N'Hút cặn và khử khuẩn bể nước ngầm bằng máy.', 100000, 600000),
      ('VeSinh', N'Vệ sinh sofa tại nhà', N'Giặt sofa nỉ, sofa da bằng công nghệ hơi nước.', 50000, 450000),
      ('VeSinh', N'Rút hầm cầu', N'Hút hầm cầu, nạo vét hố ga, xử lý mùi hôi.', 150000, 800000)
    ) AS s(MaNhom, Ten, MoTa, PhiKiemTra, TienCong)
    INNER JOIN dbo.DanhMucDichVu c ON c.Ma = s.MaNhom;
    INSERT INTO dbo.TaiKhoanNganHang(MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan)
    VALUES ('DEMO', N'Ngân hàng mô phỏng - không chuyển tiền thật', '000000000000', N'HOMEFIX DEMO');
    INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi)
    VALUES ('TyLeHoaHongMacDinh', N'15', N'Tỷ lệ hoa hồng mặc định'),
           ('TaiKhoanNganHangMacDinh', N'1', N'Id tài khoản ngân hàng nhận tiền'),
           ('TenHeThong', N'HomeFix', N'Tên hệ thống'),
           ('SoDienThoaiHoTro', N'02800000000', N'Số điện thoại hỗ trợ mô phỏng');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
SELECT Id, HoTen, SoDienThoai, VaiTro, DangHoatDong FROM dbo.vw_NguoiDung ORDER BY Id;
GO
