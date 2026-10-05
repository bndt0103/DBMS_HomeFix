-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
IF OBJECT_ID('dbo.DeXuatChinhSach') IS NULL
    BEGIN
        CREATE TABLE dbo.DeXuatChinhSach (
            Id INT IDENTITY PRIMARY KEY,
            MaDeXuat VARCHAR(20) NOT NULL UNIQUE,
            TieuDe NVARCHAR(250) NOT NULL,
            BoPhan NVARCHAR(120) NOT NULL,
            NgayGui DATETIME2 DEFAULT SYSUTCDATETIME() NOT NULL,
            NhomDichVu NVARCHAR(120) NOT NULL,
            ChietKhauHienTai DECIMAL(5, 2) NULL,
            ChietKhauDeXuat DECIMAL(5, 2) NULL,
            MucThuongHienTai NVARCHAR(50) NULL,
            MucThuongDeXuat NVARCHAR(50) NULL,
            TacDong NVARCHAR(2000) NOT NULL,
            LyDo NVARCHAR(2000) NOT NULL,
            TrangThai VARCHAR(20) DEFAULT 'Pending' NOT NULL CHECK (TrangThai IN ('Pending', 'Approved', 'RevisionRequested', 'Rejected')),
            YKienGiamDoc NVARCHAR(2000) NULL,
            NgayHieuLuc VARCHAR(20) NULL,
            NguoiDuyetId INT NULL FOREIGN KEY REFERENCES dbo.NguoiDung (Id),
            NgayDuyet DATETIME2 NULL,
            PhienBan ROWVERSION
        );
    END

GO
IF NOT EXISTS (SELECT 1
               FROM dbo.DeXuatChinhSach)
    BEGIN
        INSERT INTO dbo.DeXuatChinhSach (MaDeXuat, TieuDe, BoPhan, NhomDichVu, ChietKhauHienTai, ChietKhauDeXuat, MucThuongHienTai, MucThuongDeXuat, TacDong, LyDo)
        VALUES ('CS-10222', N'Điều chỉnh chiết khấu dịch vụ Điện nước từ 18% → 15%', N'Đề xuất: Lê Anh Tuấn', N'Điện nước', 18, 15, N'2.0% / đơn', N'3.5% / đơn', N'Dự báo tăng trưởng biên lợi nhuận ròng +2.4% cho nhóm dịch vụ kỹ thuật điện nước. Chính sách mới kỳ vọng tăng 12% lượng đơn hoàn thành do thu hút được đội ngũ kỹ thuật viên chất lượng cao.', N'Các hệ số chiết khấu hiện tại đang làm giảm động lực đăng ký mới của đội ngũ KTV, đề xuất giảm mức chiết khấu để tăng thưởng trực tiếp trên mỗi ca hoàn thành xuất sắc.'),
        ('CS-10223', N'Cập nhật bảng giá sản phẩm Vệ sinh thiết bị', N'Người gửi: Đỗ Văn An', N'Vệ sinh & bảo trì', 12, 10, N'1.5% / đơn', N'2.0% / đơn', N'Điều chỉnh phù hợp với biến động giá vật tư vệ sinh và duy trì mức cạnh tranh.', N'Bảng giá vật tư đã được rà soát theo nhà cung cấp mới.'),

        ('CS-10224', N'Chương trình ưu đãi Khách hàng mới tháng 11', N'Người gửi: Nguyễn Thị Hằng', N'Marketing', 0, 10, N'—', N'—', N'Dự kiến tăng lượng khách hàng mới và tỷ lệ đặt dịch vụ lần đầu.', N'Áp dụng mã giảm giá cho khách hàng lần đầu sử dụng HomeFix.');
    END

GO
IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 8)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (8);
GO
