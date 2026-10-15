-- Bảng lưu đề xuất chính sách do các bộ phận gửi lên.
IF OBJECT_ID('dbo.DeXuatChinhSach') IS NULL
    BEGIN
        -- Đề xuất chính sách.
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

-- Xóa các đề xuất demo đã từng được seed, để màn hình giám đốc chỉ nhận hồ sơ thật.
DELETE FROM dbo.DeXuatChinhSach
WHERE MaDeXuat IN ('CS-10222', 'CS-10223', 'CS-10224')
  AND TrangThai = 'Pending';
GO

-- Bổ sung thông báo cho các đề xuất đã có để lịch sử cũ cũng hiển thị.
INSERT dbo.ThongBao (NguoiDungId, TieuDe, NoiDungThongBao)
SELECT
    gd.Id,
    N'Đề xuất chính sách mới cần duyệt',
    CONCAT(p.MaDeXuat, N' · ', p.TieuDe, N' — ', p.BoPhan)
FROM dbo.DeXuatChinhSach p
CROSS JOIN dbo.NguoiDung gd
WHERE gd.VaiTro = 'GD'
  AND gd.DangHoatDong = 1
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.ThongBao t
      WHERE t.NguoiDungId = gd.Id
        AND t.TieuDe = N'Đề xuất chính sách mới cần duyệt'
        AND t.NoiDungThongBao LIKE CONCAT(p.MaDeXuat, N' ·%')
  );
GO

-- Khôi phục thông báo cho các yêu cầu hỗ trợ cũ chưa từng được đưa vào mục Thông báo.
INSERT dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDungThongBao, NgayTao)
SELECT
    t.KhachHangId,
    t.DonHangId,
    N'Đã tiếp nhận yêu cầu hỗ trợ',
    CONCAT(N'Yêu cầu ', CASE WHEN t.Loai = 'Complaint' THEN N'khiếu nại' ELSE N'bảo hành' END, N': ', t.MoTa),
    t.NgayTao
FROM dbo.YeuCauHoTro t
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.ThongBao n
    WHERE n.NguoiDungId = t.KhachHangId
      AND n.DonHangId = t.DonHangId
      AND n.TieuDe = N'Đã tiếp nhận yêu cầu hỗ trợ'
      AND n.NoiDungThongBao = CONCAT(N'Yêu cầu ', CASE WHEN t.Loai = 'Complaint' THEN N'khiếu nại' ELSE N'bảo hành' END, N': ', t.MoTa)
);
GO

INSERT dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDungThongBao, NgayTao)
SELECT
    cs.Id,
    t.DonHangId,
    CASE WHEN t.Loai = 'Complaint' THEN N'Khách hàng gửi khiếu nại mới' ELSE N'Khách hàng gửi yêu cầu bảo hành mới' END,
    t.MoTa,
    t.NgayTao
FROM dbo.YeuCauHoTro t
CROSS JOIN dbo.NguoiDung cs
WHERE cs.VaiTro = 'CSKH'
  AND cs.DangHoatDong = 1
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.ThongBao n
      WHERE n.NguoiDungId = cs.Id
        AND n.DonHangId = t.DonHangId
        AND n.TieuDe = CASE WHEN t.Loai = 'Complaint' THEN N'Khách hàng gửi khiếu nại mới' ELSE N'Khách hàng gửi yêu cầu bảo hành mới' END
        AND n.NoiDungThongBao = t.MoTa
  );
GO

-- Bổ sung thông báo cho các đơn đang chờ điều phối.
INSERT dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDungThongBao, NgayTao)
SELECT dpv.Id, d.Id, N'Có đơn dịch vụ mới cần điều phối', CONCAT(N'Mã đơn #', d.Id), d.NgayTao
FROM dbo.DonHang d
CROSS JOIN dbo.NguoiDung dpv
WHERE d.TrangThai IN ('ChoTiepNhan', 'ChoPhanCong')
  AND dpv.VaiTro = 'DPV'
  AND dpv.DangHoatDong = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ThongBao n
      WHERE n.NguoiDungId = dpv.Id
        AND n.DonHangId = d.Id
        AND n.TieuDe = N'Có đơn dịch vụ mới cần điều phối'
  );
GO

-- Bổ sung thông báo cho lời mời nhận việc còn hiệu lực của KTV.
INSERT dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDungThongBao, NgayTao)
SELECT a.KyThuatVienId, a.DonHangId, N'Bạn có lệnh mới', CONCAT(N'Vui lòng phản hồi đơn #', a.DonHangId, N' trước thời hạn.'), a.NgayTao
FROM dbo.LenhDieuPhoi a
WHERE a.DangHoatDong = 1
  AND a.TrangThai = 'Pending'
  AND a.NgayHetHan > SYSUTCDATETIME()
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ThongBao n
      WHERE n.NguoiDungId = a.KyThuatVienId
        AND n.DonHangId = a.DonHangId
        AND n.TieuDe = N'Bạn có lệnh mới'
  );
GO

-- Bổ sung thông báo cho hồ sơ KTV đang chờ quản trị viên.
INSERT dbo.ThongBao (NguoiDungId, TieuDe, NoiDungThongBao, NgayTao)
SELECT a.Id, N'Có hồ sơ kỹ thuật viên mới cần duyệt', CONCAT(N'Hồ sơ #', h.Id, N' của tài khoản #', h.NguoiDungId, N' đang chờ duyệt.'), h.NgayTao
FROM dbo.HoSoKTV h
CROSS JOIN dbo.NguoiDung a
WHERE h.TrangThai = 'Pending'
  AND a.VaiTro = 'ADMIN'
  AND a.DangHoatDong = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ThongBao n
      WHERE n.NguoiDungId = a.Id
        AND n.TieuDe = N'Có hồ sơ kỹ thuật viên mới cần duyệt'
        AND n.NoiDungThongBao LIKE CONCAT(N'Hồ sơ #', h.Id, N' %')
  );
GO

-- Bổ sung thông báo cho yêu cầu ví đang chờ kế toán.
INSERT dbo.ThongBao (NguoiDungId, TieuDe, NoiDungThongBao, NgayTao)
SELECT kt.Id, N'Yêu cầu ví mới cần xử lý', CONCAT(N'Yêu cầu ví #', w.Id, N': ', CASE WHEN w.Loai = 'Withdrawal' THEN N'Rút ' ELSE N'Nạp ' END, CONVERT(nvarchar(30), w.SoTien), N' đ — ', w.GhiChu), w.NgayTao
FROM dbo.YeuCauVi w
CROSS JOIN dbo.NguoiDung kt
WHERE w.TrangThai = 'Pending'
  AND kt.VaiTro = 'KT'
  AND kt.DangHoatDong = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ThongBao n
      WHERE n.NguoiDungId = kt.Id
        AND n.TieuDe = N'Yêu cầu ví mới cần xử lý'
        AND n.NoiDungThongBao LIKE CONCAT(N'Yêu cầu ví #', w.Id, N':%')
  );
GO

IF NOT EXISTS (SELECT 1
               FROM dbo.PhienBanCSDL
               WHERE PhienBan = 8)
    INSERT INTO dbo.PhienBanCSDL (PhienBan)
    VALUES (8);
GO
