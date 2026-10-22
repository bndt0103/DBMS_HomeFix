-- Nghiep vu HomeFix: chi goi thu tuc; khong sua bang truc tiep tu ung dung.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDonHang
    @NguoiThucHienId INT,
    @DichVuId INT,
    @DiaChi NVARCHAR(500),
    @MoTa NVARCHAR(2000),
    @NgayHen DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoDonHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF NULLIF(LTRIM(RTRIM(@DiaChi)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@MoTa)), N'') IS NULL
            THROW 51009, N'Can nhap dia chi va mo ta su co.', 1;
        IF @NgayHen IS NOT NULL AND @NgayHen < SYSUTCDATETIME()
            THROW 51009, N'Ngay hen phai la thoi diem trong tuong lai (UTC).', 1;
        DECLARE @TenDichVu NVARCHAR(200);
        SELECT @TenDichVu = dv.Ten
        FROM dbo.DichVu AS dv WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
        WHERE dv.Id = @DichVuId AND dv.DangHoatDong = 1 AND dm.DangHoatDong = 1;
        IF @TenDichVu IS NULL
            THROW 51004, N'Dich vu khong ton tai hoac da tam ngung.', 1;
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen)
        VALUES (@NguoiThucHienId, @DichVuId, @TenDichVu, LTRIM(RTRIM(@DiaChi)), @MoTa, @NgayHen);
        DECLARE @Id INT = SCOPE_IDENTITY();
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@Id, NULL, 'ChoTiepNhan', @NguoiThucHienId, N'Khach hang tao yeu cau dich vu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen, TrangThai, KyThuatVienId, NgayTao, NgayCapNhat, PhienBan
        FROM dbo.DonHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDonHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoBaoGiaSoBo
    @NguoiThucHienId INT,
    @DonHangId INT,
    @PhiKiemTra DECIMAL(18,2),
    @TienCong DECIMAL(18,2),
    @TyLeHoaHong DECIMAL(5,2),
    @ChanDoan NVARCHAR(2000),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoBaoGiaSoBo;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @PhienBan BINARY(8), @Id INT;
        SELECT @TrangThai = TrangThai, @PhienBan = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThai <> 'ChoTiepNhan'
            THROW 51009, N'Chi bao gia khi don dang cho tiep nhan.', 1;
        IF @PhiKiemTra IS NULL OR @TienCong IS NULL OR @TyLeHoaHong IS NULL
           OR @PhiKiemTra NOT BETWEEN 0 AND 1000000000 OR @TienCong NOT BETWEEN 0 AND 1000000000
           OR @PhiKiemTra + @TienCong <= 0
           OR @TyLeHoaHong < 0 OR @TyLeHoaHong > 100
           OR NULLIF(LTRIM(RTRIM(@ChanDoan)), N'') IS NULL
            THROW 51009, N'Bao gia, chan doan hoac ty le hoa hong khong hop le.', 1;
        SELECT @Id = Id FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.BaoGiaSoBo (DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, ChanDoan, TrangThai)
            VALUES (@DonHangId, @PhiKiemTra, @TienCong, @TyLeHoaHong, @ChanDoan, 'Pending');
            SET @Id = SCOPE_IDENTITY();
        END
        ELSE
            UPDATE dbo.BaoGiaSoBo
            SET PhiKiemTra = @PhiKiemTra, TienCong = @TienCong, TyLeHoaHong = @TyLeHoaHong,
                ChanDoan = @ChanDoan, TrangThai = 'Pending', NgayTao = SYSUTCDATETIME()
            WHERE Id = @Id;
        UPDATE dbo.DonHang SET TrangThai = 'ChoDuyetSoBo', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoDuyetSoBo', @NguoiThucHienId, N'Gui bao gia so bo cho khach hang.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, ChanDoan, TrangThai, TongTien, NgayTao, PhienBan
        FROM dbo.BaoGiaSoBo
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoBaoGiaSoBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachDuyetBaoGiaSoBo
    @NguoiThucHienId INT,
    @BaoGiaId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KhachDuyetBaoGiaSoBo;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @ChuSoHuuId INT, @TrangThai VARCHAR(30), @PhienBan BINARY(8);
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE Id = @BaoGiaId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay bao gia.', 1;
        SELECT @ChuSoHuuId = KhachHangId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND TrangThai = 'ChoDuyetSoBo';
        IF @ChuSoHuuId IS NULL THROW 51009, N'Don hang khong con cho duyet bao gia.', 1;
        IF @ChuSoHuuId <> @NguoiThucHienId THROW 51003, N'Chi chu don hang duoc duyet bao gia.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Bao gia da thay doi hoac da duoc xu ly.', 1;
        IF @QuyetDinh NOT IN ('Approved', 'Rejected') OR @QuyetDinh IS NULL
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        DECLARE @TrangThaiMoi VARCHAR(30) = CASE WHEN @QuyetDinh = 'Approved' THEN 'ChoPhanCong' ELSE 'ChoTiepNhan' END;
        UPDATE dbo.BaoGiaSoBo SET TrangThai = @QuyetDinh WHERE Id = @BaoGiaId;
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiMoi, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoDuyetSoBo', @TrangThaiMoi, @NguoiThucHienId, COALESCE(@LyDo, N'Khach hang phan hoi bao gia.'));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, PhienBan
        FROM dbo.BaoGiaSoBo
        WHERE Id = @BaoGiaId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachDuyetBaoGiaSoBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoLenhDieuPhoi
    @NguoiThucHienId INT,
    @DonHangId INT,
    @KyThuatVienId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoLenhDieuPhoi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(30), @SanSang VARCHAR(20), @Id INT;
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThai <> 'ChoPhanCong' OR NOT EXISTS (
            SELECT 1 FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved')
            THROW 51009, N'Don phai duoc khach duyet bao gia truoc khi phan cong.', 1;
        SELECT @SanSang = ktv.TrangThaiSanSang
        FROM dbo.KyThuatVien AS ktv WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id
        WHERE ktv.Id = @KyThuatVienId AND nd.DangHoatDong = 1 AND nd.VaiTro = 'KTV';
        IF @SanSang IS NULL THROW 51004, N'Ky thuat vien khong ton tai hoac da bi khoa.', 1;
        IF @SanSang <> 'SanSang' OR EXISTS (
            SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @KyThuatVienId AND DangHoatDong = 1)
            THROW 51009, N'Ky thuat vien chua san sang hoac dang co don.', 1;
        INSERT INTO dbo.LenhDieuPhoi (DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId)
        VALUES (@DonHangId, @KyThuatVienId, 'Pending', 1, @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'DangBan' WHERE Id = @KyThuatVienId;
        UPDATE dbo.DonHang SET KyThuatVienId = @KyThuatVienId, TrangThai = 'ChoNhan', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNhan', @NguoiThucHienId, N'Dieu phoi gui lenh phan cong.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.LenhDieuPhoi
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoLenhDieuPhoi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KTVPhanHoiDieuPhoi
    @NguoiThucHienId INT,
    @LenhDieuPhoiId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KTVPhanHoiDieuPhoi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @KTVId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT;
        SELECT @DonHangId = DonHangId, @KTVId = KyThuatVienId, @PhienBan = PhienBan,
               @TrangThai = TrangThai, @HoatDong = DangHoatDong
        FROM dbo.LenhDieuPhoi WITH (UPDLOCK, HOLDLOCK) WHERE Id = @LenhDieuPhoiId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay lenh dieu phoi.', 1;
        IF @KTVId <> @NguoiThucHienId THROW 51003, N'Lenh dieu phoi khong thuoc ky thuat vien nay.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
            THROW 51009, N'Lenh da thay doi hoac da duoc phan hoi.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Accepted', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Accepted hoac Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND TrangThai = 'ChoNhan' AND KyThuatVienId = @KTVId)
            THROW 51009, N'Don hang khong con cho ky thuat vien phan hoi.', 1;
        DECLARE @TrangThaiMoi VARCHAR(30) = CASE WHEN @QuyetDinh = 'Accepted' THEN 'DaTiepNhan' ELSE 'ChoPhanCong' END;
        UPDATE dbo.LenhDieuPhoi
        SET TrangThai = @QuyetDinh, DangHoatDong = CASE WHEN @QuyetDinh = 'Accepted' THEN 1 ELSE 0 END
        WHERE Id = @LenhDieuPhoiId;
        UPDATE dbo.DonHang
        SET TrangThai = @TrangThaiMoi,
            KyThuatVienId = CASE WHEN @QuyetDinh = 'Accepted' THEN @KTVId ELSE NULL END,
            NgayCapNhat = SYSUTCDATETIME()
        WHERE Id = @DonHangId;
        IF @QuyetDinh = 'Rejected'
            UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoNhan', @TrangThaiMoi, @NguoiThucHienId, COALESCE(@LyDo, N'Ky thuat vien phan hoi dieu phoi.'));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, PhienBan
        FROM dbo.LenhDieuPhoi
        WHERE Id = @LenhDieuPhoiId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KTVPhanHoiDieuPhoi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ChuyenTrangThaiDon
    @NguoiThucHienId INT,
    @DonHangId INT,
    @TrangThaiTiepTheo VARCHAR(30),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ChuyenTrangThaiDon;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'KTV', 'DPV', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @KhachHangId INT, @KTVId INT, @PhienBan BINARY(8);
        SELECT @TrangThai = TrangThai, @KhachHangId = KhachHangId,
               @KTVId = KyThuatVienId, @PhienBan = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Don hang da thay doi. Hay tai lai du lieu.', 1;
        IF @TrangThaiTiepTheo IS NULL
            THROW 51009, N'Can chi dinh trang thai tiep theo.', 1;
        IF @TrangThaiTiepTheo = 'Huy'
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
                THROW 51009, N'Phai nhap ly do huy don.', 1;
            IF NOT ((@VaiTro = 'KH' AND @KhachHangId = @NguoiThucHienId
                    AND @TrangThai IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan'))
                OR (@VaiTro IN ('DPV', 'ADMIN') AND @TrangThai IN
                    ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi')))
                THROW 51003, N'Khong duoc huy don tai trang thai hien tai.', 1;
            UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
            IF @KTVId IS NOT NULL
                UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        END
        ELSE
        BEGIN
            IF @VaiTro <> 'KTV' OR @KTVId IS NULL OR @KTVId <> @NguoiThucHienId
                THROW 51003, N'Chi ky thuat vien duoc phan cong duoc cap nhat tien do.', 1;
            IF NOT ((@TrangThai = 'DaTiepNhan' AND @TrangThaiTiepTheo = 'DangDiChuyen')
                OR (@TrangThai = 'DangDiChuyen' AND @TrangThaiTiepTheo = 'DaDenNoi')
                OR (@TrangThai = 'DaDenNoi' AND @TrangThaiTiepTheo = 'DangXuLy'))
                THROW 51009, N'Thu tu chuyen trang thai khong hop le. Bao gia va thanh toan co thu tuc rieng.', 1;
        END;
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiTiepTheo, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, @TrangThaiTiepTheo, @NguoiThucHienId, COALESCE(@LyDo, N'Cap nhat tien do thi cong.'));
        DECLARE @Id INT = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen, TrangThai, KyThuatVienId, NgayTao, NgayCapNhat, PhienBan
        FROM dbo.DonHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ChuyenTrangThaiDon;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemGhiChuDon
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NoiDung NVARCHAR(2000),
    @NoiBo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ThemGhiChuDon;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'KTV', 'DPV', 'CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KhachHangId INT, @KTVId INT, @Id INT;
        SELECT @KhachHangId = KhachHangId, @KTVId = KyThuatVienId FROM dbo.DonHang WITH (HOLDLOCK) WHERE Id = @DonHangId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF (@VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId)
           OR (@VaiTro = 'KTV' AND (@KTVId IS NULL OR @KTVId <> @NguoiThucHienId))
            THROW 51003, N'Khong duoc ghi chu tren don cua nguoi khac.', 1;
        IF @NoiBo IS NULL THROW 51009, N'Can xac dinh ghi chu noi bo hay cong khai.', 1;
        IF @VaiTro = 'KH' AND @NoiBo = 1 THROW 51003, N'Khach hang khong duoc tao ghi chu noi bo.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung ghi chu khong duoc rong.', 1;
        INSERT INTO dbo.GhiChuDon (DonHangId, NguoiVietId, NoiDung, NoiBo)
        VALUES (@DonHangId, @NguoiThucHienId, @NoiDung, @NoiBo);
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NguoiVietId, NoiDung, NoiBo, NgayTao
        FROM dbo.GhiChuDon
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemGhiChuDon;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuViTriKhachHang
    @NguoiThucHienId INT,
    @DonHangId INT,
    @ViDo DECIMAL(10,7),
    @KinhDo DECIMAL(10,7)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_LuuViTriKhachHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF @ViDo IS NULL OR @KinhDo IS NULL OR @ViDo NOT BETWEEN -90 AND 90 OR @KinhDo NOT BETWEEN -180 AND 180
            THROW 51009, N'Toa do GPS khong hop le.', 1;
        DECLARE @KhachHangId INT, @TrangThai VARCHAR(30);
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KhachHangId <> @NguoiThucHienId THROW 51003, N'Chi chu don hang duoc chia se vi tri.', 1;
        IF @TrangThai IN ('HoanThanh', 'Huy') THROW 51009, N'Don hang da ket thuc.', 1;
        IF EXISTS (SELECT 1 FROM dbo.ViTriKhachHang WHERE DonHangId = @DonHangId)
            UPDATE dbo.ViTriKhachHang
            SET ViDo = @ViDo, KinhDo = @KinhDo, NgayCapNhat = SYSUTCDATETIME() WHERE DonHangId = @DonHangId;
        ELSE
            INSERT INTO dbo.ViTriKhachHang (DonHangId, KhachHangId, ViDo, KinhDo)
            VALUES (@DonHangId, @NguoiThucHienId, @ViDo, @KinhDo);
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT DonHangId, KhachHangId, ViDo, KinhDo, NgayCapNhat
        FROM dbo.ViTriKhachHang
        WHERE DonHangId = @DonHangId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuViTriKhachHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDeXuatVatTu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @VatTu NVARCHAR(MAX),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoDeXuatVatTu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @Id INT, @LanSuaDoi INT;
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc de xuat vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'DangXuLy'
            THROW 51009, N'Don hang da thay doi hoac khong dang xu ly.', 1;
        IF ISJSON(@VatTu) <> 1 OR LEFT(LTRIM(@VatTu), 1) <> '[' OR @VatTu IS NULL
            THROW 51009, N'VatTu phai la mang JSON chua danh sach vat tu.', 1;
        IF (SELECT COUNT(*) FROM OPENJSON(@VatTu)) NOT BETWEEN 1 AND 50
            THROW 51009, N'Can tu 1 den 50 dong vat tu.', 1;
        IF EXISTS (SELECT 1 FROM OPENJSON(@VatTu) WHERE [type] <> 5)
            THROW 51009, N'Moi dong vat tu phai la mot doi tuong JSON.', 1;
        IF EXISTS (
            SELECT 1 FROM OPENJSON(@VatTu) AS j
            WHERE j.[type] <> 5
               OR NULLIF(LTRIM(RTRIM(JSON_VALUE(j.[value], '$.Ten'))), N'') IS NULL
               OR LEN(JSON_VALUE(j.[value], '$.Ten')) > 200
               OR TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(j.[value], '$.SoLuong')) IS NULL
               OR TRY_CONVERT(DECIMAL(10,2), JSON_VALUE(j.[value], '$.SoLuong')) NOT BETWEEN 0.01 AND 1000
               OR TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(j.[value], '$.DonGia')) IS NULL
               OR TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(j.[value], '$.DonGia')) NOT BETWEEN 0 AND 1000000000
               OR (JSON_VALUE(j.[value], '$.SoThangBaoHanh') IS NOT NULL AND
                  (TRY_CONVERT(INT, JSON_VALUE(j.[value], '$.SoThangBaoHanh')) IS NULL OR
                   TRY_CONVERT(INT, JSON_VALUE(j.[value], '$.SoThangBaoHanh')) NOT BETWEEN 0 AND 120)))
            THROW 51009, N'Vat tu sai ten, so luong, don gia hoac thang bao hanh.', 1;
        SELECT @LanSuaDoi = ISNULL(MAX(LanSuaDoi), 0) + 1
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        UPDATE dbo.DeXuatVatTu SET DangApDung = 0 WHERE DonHangId = @DonHangId AND DangApDung = 1;
        INSERT INTO dbo.DeXuatVatTu (DonHangId, LanSuaDoi, DangApDung, TrangThai, NguoiTaoId)
        VALUES (@DonHangId, @LanSuaDoi, 1, 'Pending', @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.ChiTietDeXuatVatTu (DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        SELECT @Id, LTRIM(RTRIM(v.Ten)), v.SoLuong, v.DonGia, ISNULL(v.SoThangBaoHanh, 0)
        FROM OPENJSON(@VatTu) WITH (
            Ten NVARCHAR(200) '$.Ten', SoLuong DECIMAL(10,2) '$.SoLuong',
            DonGia DECIMAL(18,2) '$.DonGia', SoThangBaoHanh INT '$.SoThangBaoHanh') AS v;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, TrangThai, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.DeXuatVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDeXuatVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemChiTietVatTu
    @NguoiThucHienId INT,
    @DeXuatVatTuId INT,
    @Ten NVARCHAR(200),
    @SoLuong DECIMAL(10,2),
    @DonGia DECIMAL(18,2),
    @SoThangBaoHanh INT = 0,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ThemChiTietVatTu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT, @Id INT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @HoatDong = DangApDung
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DeXuatVatTuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay de xuat vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
            THROW 51009, N'Chi duoc them vat tu vao de xuat hien hanh chua duyet.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KyThuatVienId = @NguoiThucHienId AND TrangThai = 'DangXuLy')
            THROW 51003, N'Khong duoc sua vat tu cua don nay.', 1;
        IF NULLIF(LTRIM(RTRIM(@Ten)), N'') IS NULL OR @SoLuong IS NULL OR @SoLuong NOT BETWEEN 0.01 AND 1000
           OR @DonGia IS NULL OR @DonGia NOT BETWEEN 0 AND 1000000000
           OR @SoThangBaoHanh IS NULL OR @SoThangBaoHanh NOT BETWEEN 0 AND 120
            THROW 51009, N'Thong tin vat tu khong hop le.', 1;
        INSERT INTO dbo.ChiTietDeXuatVatTu (DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        VALUES (@DeXuatVatTuId, LTRIM(RTRIM(@Ten)), @SoLuong, @DonGia, @SoThangBaoHanh);
        SET @Id = SCOPE_IDENTITY();
        -- Cham vao phien ban de phien ban cu khong the duyet danh sach moi.
        UPDATE dbo.DeXuatVatTu SET DangApDung = DangApDung WHERE Id = @DeXuatVatTuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DeXuatVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh, ThanhTien
        FROM dbo.ChiTietDeXuatVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemChiTietVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachDuyetDeXuatVatTu
    @NguoiThucHienId INT,
    @DeXuatVatTuId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KhachDuyetDeXuatVatTu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @HoatDong BIT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @HoatDong = DangApDung
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DeXuatVatTuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay de xuat vat tu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @HoatDong <> 1
            THROW 51009, N'De xuat da thay doi hoac da duoc xu ly.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'DangXuLy')
            THROW 51003, N'Chi khach hang cua don dang xu ly duoc duyet vat tu.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Approved', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ChiTietDeXuatVatTu WHERE DeXuatVatTuId = @DeXuatVatTuId)
            THROW 51009, N'De xuat phai co it nhat mot dong vat tu.', 1;
        UPDATE dbo.DeXuatVatTu SET TrangThai = @QuyetDinh WHERE Id = @DeXuatVatTuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'DuyetVatTu', N'DeXuatVatTu', @DeXuatVatTuId, COALESCE(@LyDo, @QuyetDinh));
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, TrangThai, PhienBan
        FROM dbo.DeXuatVatTu
        WHERE Id = @DeXuatVatTuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachDuyetDeXuatVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoPhieuNghiemThu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NguyenNhan NVARCHAR(2000),
    @PhuongAnXuLy NVARCHAR(2000),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoPhieuNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @Id INT;
        DECLARE @DeXuatId INT, @TrangThaiVatTu VARCHAR(20), @TienVatTu DECIMAL(18,2) = 0;
        DECLARE @PhiKiemTra DECIMAL(18,2), @TienCong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc lap nghiem thu.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'DangXuLy'
            THROW 51009, N'Don hang da thay doi hoac khong dang xu ly.', 1;
        IF NULLIF(LTRIM(RTRIM(@NguyenNhan)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@PhuongAnXuLy)), N'') IS NULL
            THROW 51009, N'Can nhap nguyen nhan va phuong an xu ly.', 1;
        SELECT @PhiKiemTra = PhiKiemTra, @TienCong = TienCong
        FROM dbo.BaoGiaSoBo WITH (HOLDLOCK) WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        IF @TienCong IS NULL THROW 51009, N'Chua co bao gia duoc khach hang chap nhan.', 1;
        SELECT @DeXuatId = Id, @TrangThaiVatTu = TrangThai
        FROM dbo.DeXuatVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND DangApDung = 1;
        IF @TrangThaiVatTu = 'Pending' THROW 51009, N'Can khach hang duyet vat tu truoc khi nghiem thu.', 1;
        IF @TrangThaiVatTu = 'Approved'
            SELECT @TienVatTu = ISNULL(SUM(ThanhTien), 0)
            FROM dbo.ChiTietDeXuatVatTu WHERE DeXuatVatTuId = @DeXuatId;
        ELSE SET @DeXuatId = NULL;
        IF EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Don hang da co phieu nghiem thu hien hanh.', 1;
        INSERT INTO dbo.PhieuNghiemThu (DonHangId, KyThuatVienId, DeXuatVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TrangThai)
        VALUES (@DonHangId, @KTVId, @DeXuatId, @NguyenNhan, @PhuongAnXuLy, @PhiKiemTra, @TienCong, @TienVatTu, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.DonHang SET TrangThai = 'ChoNghiemThu', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNghiemThu', @NguoiThucHienId, N'Ky thuat vien lap phieu nghiem thu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, DeXuatVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoPhieuNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KTVKyNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT,
    @ChuKyId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KTVKyNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @KTVId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @ChuKyCu INT;
        SELECT @DonHangId = DonHangId, @KTVId = KyThuatVienId, @PhienBan = PhienBan,
               @TrangThai = TrangThai, @ChuKyCu = ChuKyKTVId
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NghiemThuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay phieu nghiem thu.', 1;
        IF @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua phieu duoc ky.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @ChuKyCu IS NOT NULL
            THROW 51009, N'Phieu da thay doi hoac ky thuat vien da ky.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'TechnicianSignature' AND KieuMIME IN ('image/png', 'image/jpeg'))
            THROW 51009, N'Tep chu ky ky thuat vien khong hop le.', 1;
        UPDATE dbo.PhieuNghiemThu SET ChuKyKTVId = @ChuKyId WHERE Id = @NghiemThuId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @NghiemThuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KTVKyNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhachHangKyNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT,
    @ChuKyId INT,
    @PhuongThucThanhToan VARCHAR(10),
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_KhachHangKyNghiemThu;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20), @ChuKyKTVId INT;
        SELECT @DonHangId = DonHangId, @PhienBan = PhienBan, @TrangThai = TrangThai, @ChuKyKTVId = ChuKyKTVId
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NghiemThuId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay phieu nghiem thu.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'ChoNghiemThu')
            THROW 51003, N'Chi khach hang cua don cho nghiem thu duoc ky.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending' OR @ChuKyKTVId IS NULL
            THROW 51009, N'Phieu da thay doi hoac ky thuat vien chua ky.', 1;
        IF @PhuongThucThanhToan IS NULL OR @PhuongThucThanhToan NOT IN ('COD', 'BANK')
            THROW 51009, N'Phuong thuc thanh toan phai la COD hoac BANK.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'CustomerSignature' AND KieuMIME IN ('image/png', 'image/jpeg'))
            THROW 51009, N'Tep chu ky khach hang khong hop le.', 1;
        UPDATE dbo.PhieuNghiemThu
        SET ChuKyKHId = @ChuKyId, PhuongThucThanhToan = @PhuongThucThanhToan,
            TrangThai = 'Approved', NgayDuyet = SYSUTCDATETIME()
        WHERE Id = @NghiemThuId;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, NgayDuyet, TongTien, PhienBan
        FROM dbo.PhieuNghiemThu
        WHERE Id = @NghiemThuId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_KhachHangKyNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacNhanThanhToanCOD
    @NguoiThucHienId INT,
    @DonHangId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XacNhanThanhToanCOD;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @KTVId INT, @TrangThai VARCHAR(30), @NghiemThuId INT;
        DECLARE @SoTien DECIMAL(18,2), @TienCong DECIMAL(18,2), @TyLeHoaHong DECIMAL(5,2), @Id INT;
        SELECT @PhienBan = PhienBan, @KTVId = KyThuatVienId, @TrangThai = TrangThai
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay don hang.', 1;
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc xac nhan thu COD.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'ChoNghiemThu'
            THROW 51009, N'Don hang da thay doi hoac da thanh toan.', 1;
        SELECT @NghiemThuId = Id, @SoTien = TongTien, @TienCong = TienCong
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'COD'
              AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
        IF @NghiemThuId IS NULL THROW 51009, N'Chua co nghiem thu du hai chu ky va chon COD.', 1;
        IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId)
            THROW 51009, N'Don hang da duoc ghi nhan thanh toan.', 1;
        SELECT @TyLeHoaHong = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        INSERT INTO dbo.ThanhToan (DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId)
        VALUES (@DonHangId, @NghiemThuId, @SoTien, 'COD', @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
        VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLeHoaHong, 'Pending');
        UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'HoanThanh', @NguoiThucHienId, N'Ky thuat vien da thu du tien mat COD.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, NgayTao
        FROM dbo.ThanhToan
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XacNhanThanhToanCOD;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauThanhToan
    @NguoiThucHienId INT,
    @DonHangId INT,
    @TaiKhoanNganHangId INT,
    @ChungTuId INT,
    @MaThamChieu NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauThanhToan;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @NghiemThuId INT, @SoTien DECIMAL(18,2), @Id INT;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'ChoNghiemThu')
            THROW 51003, N'Chi chu don hang dang cho thanh toan duoc gui yeu cau.', 1;
        SELECT @NghiemThuId = Id, @SoTien = TongTien
        FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
            AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
        IF @NghiemThuId IS NULL THROW 51009, N'Chua co phieu nghiem thu du chu ky va chon BANK.', 1;
        IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId)
           OR EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WHERE DonHangId = @DonHangId AND TrangThai = 'Pending')
            THROW 51009, N'Don da thanh toan hoac da co yeu cau dang cho.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang WITH (HOLDLOCK) WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tai khoan nhan tien khong hop le.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChungTuId AND ChuSoHuuId = @NguoiThucHienId
            AND DonHangId = @DonHangId AND MucDich = 'PaymentProof')
            THROW 51009, N'Chung tu thanh toan khong thuoc don hang nay.', 1;
        IF NULLIF(LTRIM(RTRIM(@MaThamChieu)), N'') IS NULL
            THROW 51009, N'Can nhap ma tham chieu giao dich ngan hang.', 1;
        INSERT INTO dbo.YeuCauThanhToan (DonHangId, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai)
        VALUES (@DonHangId, @NghiemThuId, @NguoiThucHienId, @TaiKhoanNganHangId, @SoTien, @ChungTuId, LTRIM(RTRIM(@MaThamChieu)), 'Pending');
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, NghiemThuId, SoTien, ChungTuId, MaThamChieu, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauThanhToan
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauThanhToan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacNhanThanhToanNganHang
    @NguoiThucHienId INT,
    @YeuCauThanhToanId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @SoTienThucNhan DECIMAL(18,2) = NULL,
    @MaThamChieu NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XacNhanThanhToanNganHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @DonHangId INT, @NghiemThuId INT, @TaiKhoanId INT, @PhienBan BINARY(8), @TrangThai VARCHAR(20);
        DECLARE @SoTien DECIMAL(18,2), @ThamChieu NVARCHAR(100), @KTVId INT, @TienCong DECIMAL(18,2), @TyLe DECIMAL(5,2), @Id INT;
        SELECT @DonHangId = DonHangId, @NghiemThuId = NghiemThuId, @TaiKhoanId = TaiKhoanNganHangId,
               @PhienBan = PhienBan, @TrangThai = TrangThai, @SoTien = SoTien, @ThamChieu = MaThamChieu
        FROM dbo.YeuCauThanhToan WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauThanhToanId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau thanh toan.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Yeu cau da thay doi hoac da duoc xu ly.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Confirmed', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Confirmed hoac Rejected.', 1;
        IF @QuyetDinh = 'Confirmed'
        BEGIN
            IF @SoTienThucNhan IS NULL OR @SoTienThucNhan <> @SoTien
                THROW 51009, N'So tien thuc nhan phai bang tong tien can thanh toan.', 1;
            SET @ThamChieu = COALESCE(NULLIF(LTRIM(RTRIM(@MaThamChieu)), N''), @ThamChieu);
            IF NULLIF(@ThamChieu, N'') IS NULL THROW 51009, N'Can ma tham chieu ngan hang.', 1;
            SELECT @KTVId = KyThuatVienId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND TrangThai = 'ChoNghiemThu';
            IF @KTVId IS NULL THROW 51009, N'Don hang khong con cho thanh toan.', 1;
            SELECT @TienCong = TienCong FROM dbo.PhieuNghiemThu WITH (HOLDLOCK)
            WHERE Id = @NghiemThuId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                AND TongTien = @SoTien AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
            IF @TienCong IS NULL THROW 51009, N'Nghiem thu khong hop le.', 1;
            IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId OR MaThamChieu = @ThamChieu)
                THROW 51009, N'Don hoac ma tham chieu nay da duoc thanh toan.', 1;
            SELECT @TyLe = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
            INSERT INTO dbo.ThanhToan (DonHangId, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId)
            VALUES (@DonHangId, @NghiemThuId, @SoTien, 'BANK', @NguoiThucHienId, @ThamChieu, @TaiKhoanId);
            SET @Id = SCOPE_IDENTITY();
            INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
            VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLe, 'Pending');
            UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
            UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
            UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
            INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
            VALUES (@DonHangId, 'ChoNghiemThu', 'HoanThanh', @NguoiThucHienId, N'Ke toan xac nhan da nhan du chuyen khoan.');
        END;
        UPDATE dbo.YeuCauThanhToan SET TrangThai = @QuyetDinh, MaThamChieu = @ThamChieu WHERE Id = @YeuCauThanhToanId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, SoTien, MaThamChieu, TrangThai, PhienBan
        FROM dbo.YeuCauThanhToan
        WHERE Id = @YeuCauThanhToanId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XacNhanThanhToanNganHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiSoatCOD
    @NguoiThucHienId INT,
    @DoiSoatId INT,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_DoiSoatCOD;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(20), @KTVId INT, @ThanhToanId INT;
        DECLARE @TienHoaHong DECIMAL(18,2), @SoTien DECIMAL(18,2), @PhuongThuc VARCHAR(10), @BienDong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai, @KTVId = KyThuatVienId,
               @ThanhToanId = ThanhToanId, @TienHoaHong = TienHoaHong
        FROM dbo.DoiSoat WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DoiSoatId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay doi soat.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Doi soat da thay doi hoac da duoc xac nhan.', 1;
        SELECT @SoTien = SoTien, @PhuongThuc = PhuongThuc FROM dbo.ThanhToan WHERE Id = @ThanhToanId;
        -- COD: tho giu tien mat, tru hoa hong trong vi. BANK: cong tien tho duoc huong.
        SET @BienDong = CASE WHEN @PhuongThuc = 'COD' THEN -@TienHoaHong ELSE @SoTien - @TienHoaHong END;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2);
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
        IF @SoDu IS NULL THROW 51004, N'Khong tim thay vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @KTVId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @SoDu + @BienDong - @DangChoRut < 0
            THROW 51009, N'Vi khong du so du kha dung de tru hoa hong. Can nap tien hoac xu ly yeu cau rut dang cho.', 1;
        IF @BienDong <> 0
        BEGIN
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, CASE WHEN @PhuongThuc = 'COD' THEN 'Commission' ELSE 'SettlementCredit' END,
                @BienDong, 'DoiSoat', @DoiSoatId, @NguoiThucHienId, N'Doi soat thanh toan don hang.');
        END;
        UPDATE dbo.DoiSoat SET TrangThai = 'Confirmed', NguoiDuyetId = @NguoiThucHienId WHERE Id = @DoiSoatId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TienHoaHong, TrangThai, NguoiDuyetId, PhienBan
        FROM dbo.DoiSoat
        WHERE Id = @DoiSoatId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_DoiSoatCOD;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauVi
    @NguoiThucHienId INT,
    @Loai VARCHAR(20),
    @SoTien DECIMAL(18,2),
    @GhiChu NVARCHAR(1000) = NULL,
    @ChungTuId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauVi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF @Loai IS NULL OR @Loai NOT IN ('Deposit', 'Withdrawal') OR @SoTien IS NULL OR @SoTien <= 0 OR @SoTien > 1000000000
            THROW 51009, N'Loai nap/rut hoac so tien khong hop le.', 1;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2), @Id INT;
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiThucHienId;
        IF @SoDu IS NULL THROW 51004, N'Chua co vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @NguoiThucHienId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @Loai = 'Withdrawal' AND @SoTien > @SoDu - @DangChoRut
            THROW 51009, N'So du kha dung khong du. Can tru cac yeu cau rut dang cho.', 1;
        IF @Loai = 'Deposit' AND (@ChungTuId IS NULL OR NOT EXISTS (
            SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChungTuId AND ChuSoHuuId = @NguoiThucHienId AND MucDich = 'WalletProof'))
            THROW 51009, N'Nap vi can chung tu chuyen tien cua chinh ky thuat vien.', 1;
        IF @Loai = 'Deposit' AND EXISTS (SELECT 1 FROM dbo.YeuCauVi
            WHERE ChungTuId = @ChungTuId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Chung tu nay da duoc su dung cho yeu cau nap vi.', 1;
        INSERT INTO dbo.YeuCauVi (KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai)
        VALUES (@NguoiThucHienId, @Loai, @SoTien, COALESCE(@GhiChu, N''), @ChungTuId, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauVi
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetYeuCauVi
    @NguoiThucHienId INT,
    @YeuCauViId INT,
    @QuyetDinh VARCHAR(20),
    @PhienBanDuKien BINARY(8) = NULL,
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_DuyetYeuCauVi;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'GD', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThai VARCHAR(20), @Loai VARCHAR(20), @KTVId INT;
        DECLARE @SoTien DECIMAL(18,2), @SoDu DECIMAL(18,2), @ChungTuId INT, @BienDong DECIMAL(18,2);
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai, @Loai = Loai, @KTVId = KyThuatVienId,
               @SoTien = SoTien, @ChungTuId = ChungTuId
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauViId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau vi.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThai <> 'Pending'
            THROW 51009, N'Yeu cau vi da thay doi hoac da duoc xu ly.', 1;
        IF @KTVId = @NguoiThucHienId THROW 51003, N'Khong duoc tu duyet yeu cau cua minh.', 1;
        IF @QuyetDinh IS NULL OR @QuyetDinh NOT IN ('Approved', 'Rejected')
            THROW 51009, N'Quyet dinh phai la Approved hoac Rejected.', 1;
        IF @QuyetDinh = 'Rejected' AND NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
            THROW 51009, N'Can nhap ly do tu choi yeu cau vi.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            IF @Loai = 'Deposit' AND NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem
                WHERE Id = @ChungTuId AND ChuSoHuuId = @KTVId AND MucDich = 'WalletProof')
                THROW 51009, N'Yeu cau nap tien chua co chung tu hop le.', 1;
            SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
            SET @BienDong = CASE WHEN @Loai = 'Deposit' THEN @SoTien ELSE -@SoTien END;
            IF @SoDu IS NULL OR @SoDu + @BienDong < 0
                THROW 51009, N'So du hien tai khong du de duyet rut tien.', 1;
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, @Loai, @BienDong, 'YeuCauVi', @YeuCauViId, @NguoiThucHienId, COALESCE(@LyDo, N'Duyet yeu cau vi.'));
        END;
        UPDATE dbo.YeuCauVi SET TrangThai = @QuyetDinh, LyDo = @LyDo WHERE Id = @YeuCauViId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KyThuatVienId, Loai, SoTien, TrangThai, LyDo, PhienBan
        FROM dbo.YeuCauVi
        WHERE Id = @YeuCauViId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_DuyetYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTaiKhoanNganHang
    @NguoiThucHienId INT,
    @MaNganHang VARCHAR(30),
    @TenNganHang NVARCHAR(200),
    @SoTaiKhoan VARCHAR(50),
    @ChuTaiKhoan NVARCHAR(200),
    @Id INT = NULL,
    @DangHoatDong BIT = 1,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_LuuTaiKhoanNganHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KT', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        IF NULLIF(LTRIM(RTRIM(@MaNganHang)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@TenNganHang)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(@SoTaiKhoan)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@ChuTaiKhoan)), N'') IS NULL
           OR @DangHoatDong IS NULL
            THROW 51009, N'Can nhap day du thong tin ngan hang.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.TaiKhoanNganHang (MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong)
            VALUES (@MaNganHang, @TenNganHang, @SoTaiKhoan, @ChuTaiKhoan, @DangHoatDong);
            SET @Id = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            DECLARE @PhienBan BINARY(8);
            SELECT @PhienBan = PhienBan FROM dbo.TaiKhoanNganHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id;
            IF @PhienBan IS NULL THROW 51004, N'Khong tim thay tai khoan ngan hang.', 1;
            IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
                THROW 51009, N'Tai khoan ngan hang da thay doi.', 1;
            -- Giu thong tin tai khoan da tham gia giao dich de bao toan lich su doi chieu.
            IF (EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE TaiKhoanNganHangId = @Id)
                OR EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WHERE TaiKhoanNganHangId = @Id))
                AND EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang
                    WHERE Id = @Id AND (MaNganHang <> @MaNganHang OR SoTaiKhoan <> @SoTaiKhoan OR ChuTaiKhoan <> @ChuTaiKhoan))
                THROW 51009, N'Tai khoan da co giao dich. Hay tao tai khoan moi va ngung tai khoan cu.', 1;
            UPDATE dbo.TaiKhoanNganHang
            SET MaNganHang = @MaNganHang, TenNganHang = @TenNganHang,
                SoTaiKhoan = @SoTaiKhoan, ChuTaiKhoan = @ChuTaiKhoan, DangHoatDong = @DangHoatDong
            WHERE Id = @Id;
        END;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong, PhienBan
        FROM dbo.TaiKhoanNganHang
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuTaiKhoanNganHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoYeuCauHoTro
    @NguoiThucHienId INT,
    @DonHangId INT,
    @Loai VARCHAR(20),
    @MoTa NVARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoYeuCauHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @TrangThai VARCHAR(30), @NgayHoanThanh DATETIME2, @Id INT;
        SELECT @TrangThai = TrangThai, @NgayHoanThanh = NgayCapNhat
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId;
        IF @TrangThai IS NULL THROW 51003, N'Chi khach hang cua don duoc tao yeu cau ho tro.', 1;
        IF @Loai IS NULL OR @Loai NOT IN ('Complaint', 'Warranty') OR NULLIF(LTRIM(RTRIM(@MoTa)), N'') IS NULL
            THROW 51009, N'Loai ho tro hoac noi dung khong hop le.', 1;
        IF @Loai = 'Warranty'
        BEGIN
            IF @TrangThai <> 'HoanThanh' THROW 51009, N'Chi don da hoan thanh moi duoc yeu cau bao hanh.', 1;
            DECLARE @HanBaoHanh DATETIME2;
            SELECT @HanBaoHanh = HanBaoHanh FROM dbo.fn_HanBaoHanh(@DonHangId);
            IF @HanBaoHanh IS NULL OR @HanBaoHanh < SYSUTCDATETIME()
                THROW 51009, N'Don khong co vat tu bao hanh hoac da het han bao hanh.', 1;
        END;
        IF EXISTS (SELECT 1 FROM dbo.YeuCauHoTro WHERE DonHangId = @DonHangId AND Loai = @Loai AND TrangThai IN ('Open', 'InProgress'))
            THROW 51009, N'Don da co yeu cau cung loai dang duoc xu ly.', 1;
        INSERT INTO dbo.YeuCauHoTro (DonHangId, KhachHangId, Loai, MoTa, TrangThai)
        VALUES (@DonHangId, @NguoiThucHienId, @Loai, @MoTa, 'Open');
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KhachHangId, Loai, MoTa, TrangThai, NgayTao, PhienBan
        FROM dbo.YeuCauHoTro
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoYeuCauHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XuLyHoTro
    @NguoiThucHienId INT,
    @YeuCauHoTroId INT,
    @TrangThai VARCHAR(20),
    @KetQuaXuLy NVARCHAR(2000) = NULL,
    @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_XuLyHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @PhienBan BINARY(8), @TrangThaiCu VARCHAR(20);
        SELECT @PhienBan = PhienBan, @TrangThaiCu = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Yeu cau ho tro da thay doi.', 1;
        IF @TrangThai IS NULL OR NOT ((@TrangThaiCu = 'Open' AND @TrangThai IN ('InProgress', 'Rejected'))
            OR (@TrangThaiCu = 'InProgress' AND @TrangThai IN ('Resolved', 'Rejected')))
            THROW 51009, N'Thu tu xu ly: Open -> InProgress -> Resolved; co the tu choi yeu cau chua dong.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') AND NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N'') IS NULL
            THROW 51009, N'Can ghi ket qua hoac ly do tu choi.', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai = @TrangThai, KetQuaXuLy = @KetQuaXuLy, NguoiXuLyId = @NguoiThucHienId
        WHERE Id = @YeuCauHoTroId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, Loai, TrangThai, KetQuaXuLy, NguoiXuLyId, PhienBan
        FROM dbo.YeuCauHoTro
        WHERE Id = @YeuCauHoTroId;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_XuLyHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThemTraoDoiHoTro
    @NguoiThucHienId INT,
    @YeuCauHoTroId INT,
    @NoiDung NVARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_ThemTraoDoiHoTro;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH', 'CSKH', 'ADMIN')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KhachHangId INT, @TrangThai VARCHAR(20), @Id INT;
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId
            THROW 51003, N'Khong duoc xem hoac trao doi ho tro cua khach hang khac.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') THROW 51009, N'Yeu cau ho tro da dong.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung trao doi khong duoc rong.', 1;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @NoiDung);
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, YeuCauHoTroId, NguoiGuiId, NoiDung, NgayTao
        FROM dbo.TraoDoiHoTro
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_ThemTraoDoiHoTro;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoDanhGiaDonHang
    @NguoiThucHienId INT,
    @DonHangId INT,
    @Diem INT,
    @NhanXet NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;
    DECLARE @SoGiaoDichBanDau INT = @@TRANCOUNT;
    DECLARE @DaTaoDiemLuu BIT = 0;
    BEGIN TRY
        IF @SoGiaoDichBanDau = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION sp_TaoDanhGiaDonHang;
            SET @DaTaoDiemLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro
        FROM dbo.NguoiDung
        WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Khong co quyen thuc hien thao tac nay.', 1;
        -- Tai khoan ung dung hf_* phai khop actor da xac thuc trong JWT.
        -- SESSION_CONTEXT duoc backend dat read_only tren ket noi rieng cua yeu cau.
        IF USER_NAME() LIKE N'hf[_]%' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Nguoi thuc hien khong khop phien CSDL da xac thuc.', 1;

        DECLARE @KTVId INT, @Id INT;
        SELECT @KTVId = KyThuatVienId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId AND TrangThai = 'HoanThanh';
        IF @KTVId IS NULL THROW 51003, N'Chi chu don hang da hoan thanh duoc danh gia.', 1;
        IF @Diem IS NULL OR @Diem NOT BETWEEN 1 AND 5 THROW 51009, N'Diem danh gia phai tu 1 den 5.', 1;
        IF EXISTS (SELECT 1 FROM dbo.DanhGia WHERE DonHangId = @DonHangId)
            THROW 51009, N'Moi don hang chi duoc danh gia mot lan.', 1;
        INSERT INTO dbo.DanhGia (DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet)
        VALUES (@DonHangId, @NguoiThucHienId, @KTVId, @Diem, COALESCE(@NhanXet, N''));
        SET @Id = SCOPE_IDENTITY();
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet, NgayTao
        FROM dbo.DanhGia
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_TaoDanhGiaDonHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTongHop
    @NguoiThucHienId INT,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1 AND VaiTro IN ('GD', 'KT', 'ADMIN'))
        THROW 51003, N'Khong co quyen xem bao cao tong hop.', 1;
    IF @TuNgay IS NOT NULL AND @DenNgay IS NOT NULL AND @TuNgay > @DenNgay
        THROW 51009, N'Khoang ngay bao cao khong hop le.', 1;
    SELECT Ngay, SoDon, TongThu, TienHoaHong
    FROM dbo.vw_DoanhThuNgay
    WHERE (@TuNgay IS NULL OR Ngay >= @TuNgay) AND (@DenNgay IS NULL OR Ngay <= @DenNgay)
    ORDER BY Ngay DESC;
    SELECT KyThuatVienId, HoTen, SoDonHoanThanh, DiemTrungBinh
    FROM dbo.vw_HieuSuatKyThuatVien ORDER BY SoDonHoanThanh DESC;
    SELECT TrangThai, COUNT_BIG(*) AS SoLuong FROM dbo.vw_DonHangTongHop
    WHERE (@TuNgay IS NULL OR NgayTao >= @TuNgay)
        AND (@DenNgay IS NULL OR NgayTao < DATEADD(DAY, 1, CONVERT(DATETIME2, @DenNgay)))
    GROUP BY TrangThai;
END;
GO
