/* Nâng cấu trúc hiện có, giữ dữ liệu. Chạy trước các module định nghĩa lại đối tượng. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF COL_LENGTH('dbo.HoSoKTV', 'HoSoJSON') IS NULL
        ALTER TABLE dbo.HoSoKTV ADD HoSoJSON NVARCHAR(MAX) NULL
            CONSTRAINT CK_HoSoKTV_JSON CHECK (HoSoJSON IS NULL OR ISJSON(HoSoJSON) = 1);
    IF COL_LENGTH('dbo.HoSoKTV', 'GiayToMatTruocId') IS NULL
        ALTER TABLE dbo.HoSoKTV ADD GiayToMatTruocId INT NULL
            CONSTRAINT FK_HoSoKTV_MatTruoc REFERENCES dbo.TepDinhKem(Id);
    IF COL_LENGTH('dbo.HoSoKTV', 'GiayToMatSauId') IS NULL
        ALTER TABLE dbo.HoSoKTV ADD GiayToMatSauId INT NULL
            CONSTRAINT FK_HoSoKTV_MatSau REFERENCES dbo.TepDinhKem(Id);
    IF COL_LENGTH('dbo.PhieuNghiemThu', 'TaiKhoanNganHangId') IS NULL
        ALTER TABLE dbo.PhieuNghiemThu ADD TaiKhoanNganHangId INT NULL
            CONSTRAINT FK_NghiemThu_NganHang REFERENCES dbo.TaiKhoanNganHang(Id);
    -- Một thợ/hồ sơ giữ chuyên môn đầu tiên trong dữ liệu cũ.
    -- Không UPDATE dòng đã có mã hợp lệ để giữ nguyên ROWVERSION.
    UPDATE t
    SET NhomTayNghe = CASE
        WHEN c.ChuyenMon IN ('DIEN', N'Điện') THEN 'DIEN'
        WHEN c.ChuyenMon IN ('NUOC', N'Nước') THEN 'NUOC'
        WHEN c.ChuyenMon IN ('DIEN_LANH', N'Điện lạnh') THEN 'DIEN_LANH'
        WHEN c.ChuyenMon IN ('DO_GO', N'Đồ gỗ') THEN 'DO_GO'
        WHEN c.ChuyenMon IN ('KHOA', N'Khóa') THEN 'KHOA'
        ELSE CONVERT(VARCHAR(30), c.ChuyenMon)
    END
    FROM dbo.KyThuatVien AS t
    CROSS APPLY (SELECT REPLACE(t.NhomTayNghe, N';', N',') AS Chuoi) AS s
    CROSS APPLY (SELECT LTRIM(RTRIM(LEFT(s.Chuoi, CHARINDEX(N',', s.Chuoi + N',') - 1))) AS ChuyenMon) AS c
    WHERE t.NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA');
    UPDATE t
    SET NhomTayNghe = CASE
        WHEN c.ChuyenMon IN ('DIEN', N'Điện') THEN 'DIEN'
        WHEN c.ChuyenMon IN ('NUOC', N'Nước') THEN 'NUOC'
        WHEN c.ChuyenMon IN ('DIEN_LANH', N'Điện lạnh') THEN 'DIEN_LANH'
        WHEN c.ChuyenMon IN ('DO_GO', N'Đồ gỗ') THEN 'DO_GO'
        WHEN c.ChuyenMon IN ('KHOA', N'Khóa') THEN 'KHOA'
        ELSE CONVERT(VARCHAR(30), c.ChuyenMon)
    END
    FROM dbo.HoSoKTV AS t
    CROSS APPLY (SELECT REPLACE(t.NhomTayNghe, N';', N',') AS Chuoi) AS s
    CROSS APPLY (SELECT LTRIM(RTRIM(LEFT(s.Chuoi, CHARINDEX(N',', s.Chuoi + N',') - 1))) AS ChuyenMon) AS c
    WHERE t.NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA');
    IF OBJECT_ID('dbo.CK_KyThuatVien_MotChuyenMon', 'C') IS NOT NULL
        ALTER TABLE dbo.KyThuatVien DROP CONSTRAINT CK_KyThuatVien_MotChuyenMon;
    IF OBJECT_ID('dbo.CK_HoSoKTV_MotChuyenMon', 'C') IS NOT NULL
        ALTER TABLE dbo.HoSoKTV DROP CONSTRAINT CK_HoSoKTV_MotChuyenMon;
    IF OBJECT_ID('dbo.DF_KyThuatVien_TayNghe', 'D') IS NOT NULL
        ALTER TABLE dbo.KyThuatVien DROP CONSTRAINT DF_KyThuatVien_TayNghe;
    ALTER TABLE dbo.KyThuatVien ALTER COLUMN NhomTayNghe VARCHAR(30) NOT NULL;
    ALTER TABLE dbo.HoSoKTV ALTER COLUMN NhomTayNghe VARCHAR(30) NOT NULL;
    ALTER TABLE dbo.KyThuatVien ADD CONSTRAINT DF_KyThuatVien_TayNghe DEFAULT 'DIEN' FOR NhomTayNghe;
    ALTER TABLE dbo.KyThuatVien WITH CHECK ADD CONSTRAINT CK_KyThuatVien_MotChuyenMon
        CHECK (NhomTayNghe IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA'));
    ALTER TABLE dbo.HoSoKTV WITH CHECK ADD CONSTRAINT CK_HoSoKTV_MotChuyenMon
        CHECK (NhomTayNghe IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA'));
    ALTER TABLE dbo.YeuCauVi DROP CONSTRAINT CK_YeuCauVi_TrangThai;
    ALTER TABLE dbo.YeuCauVi WITH CHECK ADD CONSTRAINT CK_YeuCauVi_TrangThai
        CHECK (TrangThai IN ('Pending','Approved','Rejected','Cancelled'));
    ALTER TABLE dbo.TepDinhKem DROP CONSTRAINT CK_TepDinhKem_MucDich;
    ALTER TABLE dbo.TepDinhKem WITH CHECK ADD CONSTRAINT CK_TepDinhKem_MucDich
        CHECK (MucDich IN ('OrderFault','AcceptancePhoto','CustomerSignature','TechnicianSignature',
            'WalletProof','MaterialEvidence','PaymentProof','TechnicianDocument','Avatar'));
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Phí hủy không lập nghiệm thu giả; dùng lại thanh toán BANK và đối soát.
IF COL_LENGTH('dbo.DonHang', 'PhiHuyDon') IS NULL
    ALTER TABLE dbo.DonHang ADD PhiHuyDon DECIMAL(18,2) NOT NULL CONSTRAINT DF_DonHang_PhiHuy DEFAULT 0 WITH VALUES;
IF COL_LENGTH('dbo.ThanhToan', 'LoaiThanhToan') IS NULL
    ALTER TABLE dbo.ThanhToan ADD LoaiThanhToan VARCHAR(12) NOT NULL CONSTRAINT DF_ThanhToan_Loai DEFAULT 'DichVu' WITH VALUES;
IF COL_LENGTH('dbo.YeuCauThanhToan', 'LoaiThanhToan') IS NULL
    ALTER TABLE dbo.YeuCauThanhToan ADD LoaiThanhToan VARCHAR(12) NOT NULL CONSTRAINT DF_YeuCauThanhToan_Loai DEFAULT 'DichVu' WITH VALUES;
IF COL_LENGTH('dbo.YeuCauHoTro', 'NgayCapNhat') IS NULL
BEGIN
    ALTER TABLE dbo.YeuCauHoTro ADD NgayCapNhat DATETIME2(3) NULL;
    EXEC(N'UPDATE dbo.YeuCauHoTro SET NgayCapNhat = NgayTao;');
    ALTER TABLE dbo.YeuCauHoTro ALTER COLUMN NgayCapNhat DATETIME2(3) NOT NULL;
    ALTER TABLE dbo.YeuCauHoTro ADD CONSTRAINT DF_YeuCauHoTro_CapNhat DEFAULT SYSUTCDATETIME() FOR NgayCapNhat;
END;
IF COL_LENGTH('dbo.TraoDoiHoTro', 'TrangThai') IS NULL
    ALTER TABLE dbo.TraoDoiHoTro ADD TrangThai VARCHAR(12) NULL;
IF OBJECT_ID('dbo.UQ_ThanhToan_NghiemThu', 'UQ') IS NOT NULL
    ALTER TABLE dbo.ThanhToan DROP CONSTRAINT UQ_ThanhToan_NghiemThu;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ThanhToan') AND name = 'NghiemThuId' AND is_nullable = 0)
    ALTER TABLE dbo.ThanhToan ALTER COLUMN NghiemThuId INT NULL;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.YeuCauThanhToan') AND name = 'NghiemThuId' AND is_nullable = 0)
    ALTER TABLE dbo.YeuCauThanhToan ALTER COLUMN NghiemThuId INT NULL;
GO
IF OBJECT_ID('dbo.CK_DonHang_PhiHuy', 'C') IS NULL
    ALTER TABLE dbo.DonHang WITH CHECK ADD CONSTRAINT CK_DonHang_PhiHuy
        CHECK (PhiHuyDon >= 0 AND (PhiHuyDon = 0 OR (TrangThai = 'Huy' AND KyThuatVienId IS NOT NULL)));
IF OBJECT_ID('dbo.CK_ThanhToan_Loai', 'C') IS NULL
    ALTER TABLE dbo.ThanhToan WITH CHECK ADD CONSTRAINT CK_ThanhToan_Loai
        CHECK ((LoaiThanhToan = 'DichVu' AND NghiemThuId IS NOT NULL) OR (LoaiThanhToan = 'PhiHuyDon' AND NghiemThuId IS NULL AND PhuongThuc = 'BANK'));
IF OBJECT_ID('dbo.CK_YeuCauThanhToan_Loai', 'C') IS NULL
    ALTER TABLE dbo.YeuCauThanhToan WITH CHECK ADD CONSTRAINT CK_YeuCauThanhToan_Loai
        CHECK ((LoaiThanhToan = 'DichVu' AND NghiemThuId IS NOT NULL) OR (LoaiThanhToan = 'PhiHuyDon' AND NghiemThuId IS NULL));
IF OBJECT_ID('dbo.CK_TraoDoiHoTro_TrangThai', 'C') IS NULL
    ALTER TABLE dbo.TraoDoiHoTro WITH CHECK ADD CONSTRAINT CK_TraoDoiHoTro_TrangThai
        CHECK (TrangThai IN ('InProgress','Resolved','Rejected'));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.ThanhToan') AND name = 'UX_ThanhToan_NghiemThu')
    CREATE UNIQUE INDEX UX_ThanhToan_NghiemThu ON dbo.ThanhToan(NghiemThuId) WHERE NghiemThuId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM dbo.CauHinh WHERE Khoa = 'PhiHuyDon')
    INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES ('PhiHuyDon', N'60000', N'Phí hủy khi KTV đã di chuyển');
GO
