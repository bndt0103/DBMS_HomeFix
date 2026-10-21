-- HomeFix / 08_seed: sinh bởi npm run sql:build.
-- Chạy trong CSDL HomeFix theo thứ tự ở CSDL_HomeFix_Modules.sql.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

-- Nguồn: SRC/database/sample-data.sql
-- Dữ liệu mẫu phục vụ vận hành.
SET IDENTITY_INSERT dbo.[NguoiDung] ON;
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'1', N'Khách hàng An', N'0900000001', N'kh@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.746Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'2', N'Kỹ thuật viên Minh', N'0900000002', N'ktv@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KTV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.759Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'3', N'Điều phối Linh', N'0900000003', N'dpv@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'DPV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.797Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'4', N'Chăm sóc khách hàng', N'0900000004', N'cskh@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'CSKH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.805Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'5', N'Kế toán Hạnh', N'0900000005', N'kt@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KT', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.814Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'6', N'Quản trị HomeFix', N'0900000006', N'admin@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'ADMIN', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.824Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'7', N'Giám đốc HomeFix', N'0900000007', N'gd@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'GD', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.831Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'8', N'Khách hàng Bình', N'0900000008', N'kh2@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KH', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.836Z', NULL, NULL);
INSERT INTO dbo.[NguoiDung] ([Id], [HoTen], [SoDienThoai], [Email], [CCCD], [MatKhauBam], [VaiTro], [DiaChiMacDinh], [DangHoatDong], [PhienBanXacThuc], [NgayTao], [DuongDanAnhDaiDien], [KhoaDenNgay])
VALUES (N'9', N'Kỹ thuật viên Nam', N'0900000009', N'ktv2@homefix.local', NULL, N'$2b$12$uPMS1zDBe3ZavepirKiyAOqqzkLjurD9slClKim0dTu9c2hzjoaB2', N'KTV', N'1 Võ Văn Ngân, TP. Thủ Đức, TP.HCM', 1, 0, '2026-10-05T10:46:48.845Z', NULL, NULL);
SET IDENTITY_INSERT dbo.[NguoiDung] OFF;
GO
INSERT INTO dbo.[KyThuatVien] ([Id], [NhomTayNghe], [KhuVucPhucVu], [TrangThaiSanSang], [SoDu], [ViDo], [KinhDo], [DoChinhXacMet], [NgayCapNhatViTri])
VALUES (2, N'DienLanh', N'TP.HCM', N'SanSang', 0, NULL, NULL, NULL, NULL);
INSERT INTO dbo.[KyThuatVien] ([Id], [NhomTayNghe], [KhuVucPhucVu], [TrangThaiSanSang], [SoDu], [ViDo], [KinhDo], [DoChinhXacMet], [NgayCapNhatViTri])
VALUES (9, N'DienLanh', N'TP.HCM', N'SanSang', 0, NULL, NULL, NULL, NULL);
GO
SET IDENTITY_INSERT dbo.[DichVu] ON;
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'1', N'Sửa máy lạnh', N'DienLanh', N'Kiểm tra và sửa máy lạnh không lạnh, chảy nước.', 50000, 300000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'2', N'Vệ sinh máy lạnh', N'DienLanh', N'Bảo dưỡng, vệ sinh dàn lạnh và dàn nóng.', 30000, 180000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'3', N'Sửa tủ lạnh', N'DienLanh', N'Khắc phục lỗi tủ lạnh không đông đá, hở ron.', 50000, 300000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'4', N'Sửa máy giặt', N'DienGiaDung', N'Sửa máy giặt mất nguồn, báo lỗi, không vắt.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'5', N'Sửa điện nước', N'DienNuoc', N'Sửa rò rỉ, đường ống và thiết bị điện gia đình.', 50000, 200000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'6', N'Vệ sinh thiết bị', N'VeSinh', N'Làm sạch và bảo trì định kỳ thiết bị gia đình.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'7', N'Sửa điện tại nhà', N'DienNuoc', N'Khắc phục sự cố chập điện, mất điện, nhảy aptomat.', 50000, 200000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'8', N'Sửa điện 3 pha', N'DienNuoc', N'Khắc phục sự cố tủ điện 3 pha, cân pha công nghiệp.', 100000, 500000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'9', N'Lắp quạt trần', N'DienNuoc', N'Thi công và lắp ráp các loại quạt trần dân dụng.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'10', N'Sửa quạt trần', N'DienNuoc', N'Sửa chữa quạt trần không quay, kêu to, hỏng tụ.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'11', N'Thi công đèn trong nhà', N'DienNuoc', N'Lắp đặt, đi dây và thiết kế hệ thống chiếu sáng.', 50000, 300000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'12', N'Sửa ống nước tại nhà', N'DienNuoc', N'Khắc phục các sự cố bục vỡ, rò rỉ đường ống nước.', 50000, 150000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'13', N'Sửa máy bơm nước', N'DienNuoc', N'Kiểm tra và sửa chữa máy bơm nước không lên nước, kêu to.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'14', N'Lắp phao nước tự động', N'DienNuoc', N'Lắp đặt phao điện, phao cơ ngắt nước tự động.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'15', N'Thông nghẹt bồn rửa chén', N'DienNuoc', N'Xử lý triệt để bồn rửa chén bị tắc nghẽn nước.', 50000, 250000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'16', N'Sửa vòi rửa bát', N'DienNuoc', N'Khắc phục vòi rửa bát bị rò rỉ nước, gãy vòi.', 30000, 100000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'17', N'Thay vòi hoa sen', N'DienNuoc', N'Lắp mới, thay thế bộ vòi hoa sen nhà tắm.', 30000, 150000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'18', N'Sửa bồn cầu', N'DienNuoc', N'Sửa bồn cầu rỉ nước, hỏng phao, nút nhấn không được.', 50000, 200000, 15, 1, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'19', N'Dò tìm rò rỉ nước ngầm', N'DienNuoc', N'Sử dụng máy siêu âm tìm điểm vỡ ống nước ngầm âm tường/nền.', 100000, 800000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'20', N'Bơm gas máy lạnh', N'DienLanh', N'Kiểm tra và châm thêm gas cho máy lạnh.', 50000, 350000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'21', N'Vệ sinh máy lạnh âm trần', N'DienLanh', N'Bảo dưỡng máy lạnh cassette, máy lạnh âm trần ống gió.', 100000, 450000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'22', N'Sửa tủ mát, tủ đông', N'DienLanh', N'Bơm gas, thay lốc tủ đông công nghiệp/nhà hàng.', 100000, 500000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'23', N'Vệ sinh máy giặt lồng ngang', N'DienGiaDung', N'Tháo lồng và vệ sinh máy giặt cửa trước.', 50000, 400000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'24', N'Vệ sinh máy giặt lồng đứng', N'DienGiaDung', N'Tháo lồng và vệ sinh máy giặt cửa trên.', 50000, 250000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'25', N'Sửa lò vi sóng', N'DienGiaDung', N'Sửa lò vi sóng mất nguồn, không nóng.', 50000, 200000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'26', N'Sửa máy nước nóng năng lượng mặt trời', N'DienGiaDung', N'Khắc phục rò rỉ, thay ống thủy tinh năng lượng mặt trời.', 100000, 400000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'27', N'Sửa máy nước nóng', N'DienGiaDung', N'Sửa máy nước nóng trực tiếp/gián tiếp không nóng.', 50000, 250000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'28', N'Vệ sinh bồn nước inox', N'VeSinh', N'Súc rửa cặn bẩn bồn nước inox trên cao.', 50000, 350000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'29', N'Vệ sinh bồn nước ngầm', N'VeSinh', N'Hút cặn và khử khuẩn bể nước ngầm bằng máy.', 100000, 600000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'30', N'Vệ sinh sofa tại nhà', N'VeSinh', N'Giặt sofa nỉ, sofa da bằng công nghệ hơi nước.', 50000, 450000, 15, 0, 1);
INSERT INTO dbo.[DichVu] ([Id], [Ten], [MaNhom], [MoTa], [PhiKiemTra], [TienCong], [TyLeHoaHong], [PhoBien], [DangHoatDong])
VALUES (N'31', N'Rút hầm cầu', N'VeSinh', N'Hút hầm cầu, nạo vét hố ga, xử lý mùi hôi.', 150000, 800000, 15, 0, 1);
SET IDENTITY_INSERT dbo.[DichVu] OFF;
GO
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'assignmentMinutes', N'10', N'Phút phản hồi lệnh');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'cancellationFee', N'50000', N'Phí hủy khi đang di chuyển');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'minimumWallet', N'200000', N'Số dư tối thiểu nhận việc');
INSERT INTO dbo.[CauHinh] ([KhoaCauHinh], [GiaTri], [NhanHienThi])
VALUES (N'signatureRequired', N'false', N'Yêu cầu chữ ký nghiệm thu');
GO
SET IDENTITY_INSERT dbo.[GiaoDichVi] ON;
INSERT INTO dbo.[GiaoDichVi] ([Id], [KyThuatVienId], [Loai], [SoTien], [LoaiThamChieu], [ThamChieuId], [NguoiThucHienId], [GhiChu], [NgayTao])
VALUES (N'1', 2, N'Opening', 1000000, N'Opening', 2, NULL, N'Số dư mở đầu bộ dữ liệu demo', '2026-10-05T10:46:48.771Z');
INSERT INTO dbo.[GiaoDichVi] ([Id], [KyThuatVienId], [Loai], [SoTien], [LoaiThamChieu], [ThamChieuId], [NguoiThucHienId], [GhiChu], [NgayTao])
VALUES (N'2', 9, N'Opening', 1000000, N'Opening', 9, NULL, N'Số dư mở đầu bộ dữ liệu demo', '2026-10-05T10:46:48.855Z');
SET IDENTITY_INSERT dbo.[GiaoDichVi] OFF;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.PhienBanCSDL WHERE PhienBan = 6)
    INSERT dbo.PhienBanCSDL(PhienBan) VALUES(6);
GO
