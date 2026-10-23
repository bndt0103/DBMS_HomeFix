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
    @NgayHen DATETIME2 = NULL,
    @TepDinhKem NVARCHAR(MAX) = NULL
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
        IF @TepDinhKem IS NOT NULL
        BEGIN
            IF ISJSON(@TepDinhKem) <> 1 OR LEFT(LTRIM(@TepDinhKem), 1) <> '['
                THROW 51009, N'Danh sách ảnh không hợp lệ.', 1;
            IF EXISTS (
                SELECT 1 FROM OPENJSON(@TepDinhKem) AS j
                LEFT JOIN dbo.TepDinhKem AS t WITH (UPDLOCK, HOLDLOCK) ON t.Id = TRY_CONVERT(INT, j.value)
                WHERE t.Id IS NULL OR t.ChuSoHuuId <> @NguoiThucHienId
                   OR t.MucDich <> 'OrderFault' OR t.DonHangId IS NOT NULL
            ) THROW 51003, N'Ảnh sự cố phải thuộc khách hàng và chưa gắn đơn khác.', 1;
        END;
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen)
        VALUES (@NguoiThucHienId, @DichVuId, @TenDichVu, LTRIM(RTRIM(@DiaChi)), @MoTa, @NgayHen);
        DECLARE @Id INT = SCOPE_IDENTITY();
        UPDATE dbo.TepDinhKem SET DonHangId = @Id
        WHERE Id IN (SELECT TRY_CONVERT(INT, value) FROM OPENJSON(@TepDinhKem));
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
        IF @TrangThai NOT IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong')
            THROW 51009, N'Chỉ được điều chỉnh báo giá trước khi phân công kỹ thuật viên.', 1;
        IF @PhiKiemTra IS NULL OR @TienCong IS NULL OR @TyLeHoaHong IS NULL
           OR @PhiKiemTra NOT BETWEEN 0 AND 1000000000 OR @TienCong NOT BETWEEN 0 AND 1000000000
           OR @PhiKiemTra + @TienCong <= 0
           OR @TyLeHoaHong < 0 OR @TyLeHoaHong > 100
           OR NULLIF(LTRIM(RTRIM(@ChanDoan)), N'') IS NULL OR LEN(@ChanDoan) > 1000
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
        VALUES (@DonHangId, @TrangThai, 'ChoDuyetSoBo', @NguoiThucHienId,
            CASE WHEN @TrangThai = 'ChoTiepNhan' THEN N'Gửi báo giá sơ bộ cho khách hàng.'
                 ELSE N'Điều chỉnh báo giá sơ bộ; khách hàng cần duyệt lại.' END);
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
        SELECT @DonHangId = DonHangId FROM dbo.BaoGiaSoBo WHERE Id = @BaoGiaId;
        IF @DonHangId IS NULL THROW 51004, N'Khong tim thay bao gia.', 1;
        -- Khóa đơn trước rồi khóa báo giá, cùng thứ tự với thủ tục điều chỉnh.
        SELECT @ChuSoHuuId = KhachHangId FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId AND TrangThai = 'ChoDuyetSoBo';
        SELECT @PhienBan = PhienBan, @TrangThai = TrangThai
        FROM dbo.BaoGiaSoBo WITH (UPDLOCK, HOLDLOCK) WHERE Id = @BaoGiaId;
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
        IF NOT EXISTS (SELECT 1 FROM dbo.fn_KyThuatVienPhuHop(@DonHangId) WHERE Id = @KyThuatVienId)
            THROW 51009, N'Thợ phải đúng tay nghề, khu vực, đang sẵn sàng và không giữ đơn khác.', 1;
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
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @HoatDong <> 1
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
    @LyDo NVARCHAR(1000) = NULL,
    @DongYPhiHuy BIT = 0,
    @PhiHuyDuKien DECIMAL(18,2) = NULL
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
        DECLARE @PhiHuy DECIMAL(18,2) = 0;
        IF @TrangThaiTiepTheo = 'Huy'
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL
                THROW 51009, N'Phai nhap ly do huy don.', 1;
            IF NOT ((@VaiTro = 'KH' AND @KhachHangId = @NguoiThucHienId
                    AND @TrangThai IN ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi'))
                OR (@VaiTro IN ('DPV', 'ADMIN') AND @TrangThai IN
                    ('ChoTiepNhan', 'ChoDuyetSoBo', 'ChoPhanCong', 'ChoNhan', 'DaTiepNhan', 'DangDiChuyen', 'DaDenNoi')))
                THROW 51003, N'Khong duoc huy don tai trang thai hien tai.', 1;
            IF @TrangThai IN ('DangDiChuyen', 'DaDenNoi')
            BEGIN
                SELECT @PhiHuy = TRY_CONVERT(DECIMAL(18,2), GiaTri) FROM dbo.CauHinh WITH (HOLDLOCK) WHERE Khoa = 'PhiHuyDon';
                IF @PhiHuy IS NULL OR @PhiHuy NOT BETWEEN 1000 AND 1000000
                    THROW 51009, N'Cấu hình phí hủy đơn không hợp lệ.', 1;
                IF ISNULL(@DongYPhiHuy, 0) <> 1 OR @PhiHuyDuKien IS NULL OR @PhiHuyDuKien <> @PhiHuy
                    THROW 51009, N'KTV đã di chuyển. Cần xác nhận đúng phí hủy trước khi thực hiện.', 1;
            END;
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
        UPDATE dbo.DonHang SET TrangThai = @TrangThaiTiepTheo, PhiHuyDon = @PhiHuy, NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, @TrangThaiTiepTheo, @NguoiThucHienId, COALESCE(@LyDo, N'Cap nhat tien do thi cong.'));
        DECLARE @Id INT = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, KhachHangId, DichVuId, TenDichVu, DiaChi, MoTa, NgayHen, TrangThai, PhiHuyDon, KyThuatVienId, NgayTao, NgayCapNhat, PhienBan
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

CREATE OR ALTER PROCEDURE dbo.sp_LuuBangKeVatTu
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
            SAVE TRANSACTION sp_LuuBangKeVatTu;
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
        IF @KTVId IS NULL OR @KTVId <> @NguoiThucHienId THROW 51003, N'Chi ky thuat vien cua don duoc ke khai vat tu.', 1;
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
        FROM dbo.BangKeVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId;
        UPDATE dbo.BangKeVatTu SET DangApDung = 0 WHERE DonHangId = @DonHangId AND DangApDung = 1;
        INSERT INTO dbo.BangKeVatTu (DonHangId, LanSuaDoi, DangApDung, NguoiTaoId)
        VALUES (@DonHangId, @LanSuaDoi, 1, @NguoiThucHienId);
        SET @Id = SCOPE_IDENTITY();
        INSERT INTO dbo.ChiTietVatTu (BangKeVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh)
        SELECT @Id, LTRIM(RTRIM(v.Ten)), v.SoLuong, v.DonGia, ISNULL(v.SoThangBaoHanh, 0)
        FROM OPENJSON(@VatTu) WITH (
            Ten NVARCHAR(200) '$.Ten', SoLuong DECIMAL(10,2) '$.SoLuong',
            DonGia DECIMAL(18,2) '$.DonGia', SoThangBaoHanh INT '$.SoThangBaoHanh') AS v;
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, LanSuaDoi, DangApDung, NguoiTaoId, NgayTao, PhienBan
        FROM dbo.BangKeVatTu
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @SoGiaoDichBanDau = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @SoGiaoDichBanDau > 0 AND XACT_STATE() = 1 AND @DaTaoDiemLuu = 1
            ROLLBACK TRANSACTION sp_LuuBangKeVatTu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoPhieuNghiemThu
    @NguoiThucHienId INT,
    @DonHangId INT,
    @NguyenNhan NVARCHAR(2000),
    @PhuongAnXuLy NVARCHAR(2000),
    @PhienBanDuKien BINARY(8) = NULL,
    @ChuKyKTVId INT = NULL,
    @AnhThanhPham NVARCHAR(MAX) = NULL
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
        DECLARE @BangKeId INT, @TienVatTu DECIMAL(18,2) = 0;
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
        -- Vat tu da trao doi truc tiep voi khach, duoc tong hop vao phieu nghiem thu.
        SELECT @BangKeId = Id
        FROM dbo.BangKeVatTu WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND DangApDung = 1;
        SELECT @TienVatTu = ISNULL(SUM(ThanhTien), 0)
        FROM dbo.ChiTietVatTu WITH (HOLDLOCK) WHERE BangKeVatTuId = @BangKeId;
        IF EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai IN ('Pending', 'Approved'))
            THROW 51009, N'Don hang da co phieu nghiem thu hien hanh.', 1;
        INSERT INTO dbo.PhieuNghiemThu (DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TrangThai)
        VALUES (@DonHangId, @KTVId, @BangKeId, @NguyenNhan, @PhuongAnXuLy, @PhiKiemTra, @TienCong, @TienVatTu, 'Pending');
        SET @Id = SCOPE_IDENTITY();
        -- Web gửi chữ ký và ảnh trong cùng giao dịch tạo phiếu.
        IF @AnhThanhPham IS NOT NULL
        BEGIN
            IF ISJSON(@AnhThanhPham) <> 1 OR LEFT(LTRIM(@AnhThanhPham), 1) <> '['
                THROW 51009, N'Danh sách ảnh thành phẩm không hợp lệ.', 1;
            IF EXISTS (
                SELECT 1 FROM OPENJSON(@AnhThanhPham) AS j
                LEFT JOIN dbo.TepDinhKem AS t ON t.Id = TRY_CONVERT(INT, j.value)
                WHERE t.Id IS NULL OR t.ChuSoHuuId <> @NguoiThucHienId
                   OR t.DonHangId <> @DonHangId OR t.DonHangId IS NULL OR t.MucDich <> 'AcceptancePhoto'
            ) THROW 51003, N'Ảnh thành phẩm không thuộc thợ hoặc đơn hàng.', 1;
        END;
        IF @ChuKyKTVId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.TepDinhKem WHERE Id = @ChuKyKTVId
                AND ChuSoHuuId = @NguoiThucHienId AND DonHangId = @DonHangId AND MucDich = 'TechnicianSignature')
                THROW 51003, N'Chữ ký thợ không hợp lệ.', 1;
            UPDATE dbo.PhieuNghiemThu SET ChuKyKTVId = @ChuKyKTVId WHERE Id = @Id;
        END;
        UPDATE dbo.DonHang SET TrangThai = 'ChoNghiemThu', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThai, 'ChoNghiemThu', @NguoiThucHienId, N'Ky thuat vien lap phieu nghiem thu.');
        IF @SoGiaoDichBanDau = 0
            COMMIT TRANSACTION;
        SELECT Id, DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, PhienBan
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
    @PhienBanDuKien BINARY(8) = NULL,
    @TaiKhoanNganHangId INT = NULL
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
        IF @TaiKhoanNganHangId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nhận tiền đã ngừng hoạt động.', 1;
        UPDATE dbo.PhieuNghiemThu
        SET ChuKyKHId = @ChuKyId, PhuongThucThanhToan = @PhuongThucThanhToan, TaiKhoanNganHangId = CASE WHEN @PhuongThucThanhToan = 'BANK' THEN @TaiKhoanNganHangId END,
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

        DECLARE @NghiemThuId INT, @SoTien DECIMAL(18,2), @Id INT, @TrangThaiDon VARCHAR(20), @Loai VARCHAR(12) = 'DichVu';
        SELECT @TrangThaiDon = TrangThai, @SoTien = PhiHuyDon
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId;
        IF @TrangThaiDon IS NULL THROW 51003, N'Chỉ chủ đơn hàng được gửi chứng từ.', 1;
        IF @TrangThaiDon = 'Huy' AND @SoTien > 0
            SET @Loai = 'PhiHuyDon';
        ELSE
        BEGIN
            IF @TrangThaiDon <> 'ChoNghiemThu' THROW 51009, N'Đơn không còn khoản phải thanh toán.', 1;
            SELECT @NghiemThuId = Id, @SoTien = TongTien FROM dbo.PhieuNghiemThu WITH (UPDLOCK, HOLDLOCK)
            WHERE DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
            IF @NghiemThuId IS NULL THROW 51009, N'Chưa có nghiệm thu đủ chữ ký và chọn chuyển khoản.', 1;
        END;
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
        INSERT INTO dbo.YeuCauThanhToan (DonHangId, LoaiThanhToan, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai)
        VALUES (@DonHangId, @Loai, @NghiemThuId, @NguoiThucHienId, @TaiKhoanNganHangId, @SoTien, @ChungTuId, LTRIM(RTRIM(@MaThamChieu)), 'Pending');
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
        DECLARE @Loai VARCHAR(12), @TrangThaiDon VARCHAR(20), @PhiHuy DECIMAL(18,2);
        SELECT @Loai = LoaiThanhToan, @DonHangId = DonHangId, @NghiemThuId = NghiemThuId, @TaiKhoanId = TaiKhoanNganHangId,
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
            SELECT @KTVId = KyThuatVienId, @TrangThaiDon = TrangThai, @PhiHuy = PhiHuyDon
            FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DonHangId;
            IF @KTVId IS NULL THROW 51009, N'Đơn chưa có kỹ thuật viên.', 1;
            IF @Loai = 'PhiHuyDon'
            BEGIN
                IF @TrangThaiDon <> 'Huy' OR @PhiHuy <> @SoTien OR @PhiHuy <= 0 OR @NghiemThuId IS NOT NULL
                    THROW 51009, N'Khoản phí hủy không khớp đơn đã hủy.', 1;
                SET @TienCong = 0;
                SET @TyLe = 0; -- Phí di chuyển chuyển đủ cho KTV, không trừ hoa hồng.
            END
            ELSE
            BEGIN
                IF @TrangThaiDon <> 'ChoNghiemThu' THROW 51009, N'Đơn không còn chờ thanh toán.', 1;
                SELECT @TienCong = TienCong FROM dbo.PhieuNghiemThu WITH (HOLDLOCK)
                WHERE Id = @NghiemThuId AND DonHangId = @DonHangId AND TrangThai = 'Approved' AND PhuongThucThanhToan = 'BANK'
                    AND TongTien = @SoTien AND ChuKyKTVId IS NOT NULL AND ChuKyKHId IS NOT NULL;
                IF @TienCong IS NULL THROW 51009, N'Nghiệm thu không hợp lệ.', 1;
                SELECT @TyLe = TyLeHoaHong FROM dbo.BaoGiaSoBo WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
            END;
            IF EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE DonHangId = @DonHangId OR MaThamChieu = @ThamChieu)
                THROW 51009, N'Don hoac ma tham chieu nay da duoc thanh toan.', 1;
            INSERT INTO dbo.ThanhToan (DonHangId, LoaiThanhToan, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId)
            VALUES (@DonHangId, @Loai, @NghiemThuId, @SoTien, 'BANK', @NguoiThucHienId, @ThamChieu, @TaiKhoanId);
            SET @Id = SCOPE_IDENTITY();
            INSERT INTO dbo.DoiSoat (ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TrangThai)
            VALUES (@Id, @DonHangId, @KTVId, @TienCong, @TyLe, 'Pending');
            IF @Loai = 'DichVu'
            BEGIN
                UPDATE dbo.DonHang SET TrangThai = 'HoanThanh', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
                UPDATE dbo.LenhDieuPhoi SET DangHoatDong = 0 WHERE DonHangId = @DonHangId AND DangHoatDong = 1;
                UPDATE dbo.KyThuatVien SET TrangThaiSanSang = 'SanSang' WHERE Id = @KTVId;
                INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
                VALUES (@DonHangId, 'ChoNghiemThu', 'HoanThanh', @NguoiThucHienId, N'Ke toan xac nhan da nhan du chuyen khoan.');
            END;
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
        DECLARE @LoaiThanhToan VARCHAR(12);
        SELECT @LoaiThanhToan = LoaiThanhToan, @SoTien = SoTien, @PhuongThuc = PhuongThuc FROM dbo.ThanhToan WHERE Id = @ThanhToanId;
        -- COD: tho giu tien mat, tru hoa hong trong vi. BANK: cong tien tho duoc huong.
        SET @BienDong = CASE WHEN @PhuongThuc = 'COD' THEN -@TienHoaHong ELSE @SoTien - @TienHoaHong END;
        DECLARE @SoDu DECIMAL(18,2), @DangChoRut DECIMAL(18,2);
        SELECT @SoDu = SoDu FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @KTVId;
        IF @SoDu IS NULL THROW 51004, N'Khong tim thay vi ky thuat vien.', 1;
        SELECT @DangChoRut = ISNULL(SUM(SoTien), 0)
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE KyThuatVienId = @KTVId AND Loai = 'Withdrawal' AND TrangThai = 'Pending';
        IF @SoDu + @BienDong - @DangChoRut < 0
            THROW 51009, N'Ví KTV không đủ số dư khả dụng để trừ hoa hồng. Cần nạp ví hoặc xử lý yêu cầu rút đang chờ.', 1;
        IF @BienDong <> 0
        BEGIN
            UPDATE dbo.KyThuatVien SET SoDu = SoDu + @BienDong WHERE Id = @KTVId;
            INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
            VALUES (@KTVId, CASE WHEN @PhuongThuc = 'COD' THEN 'Commission' ELSE 'SettlementCredit' END,
                @BienDong, 'DoiSoat', @DoiSoatId, @NguoiThucHienId, CASE WHEN @LoaiThanhToan = 'PhiHuyDon' THEN N'Bù phí di chuyển do khách hủy đơn.' ELSE N'Đối soát thanh toán đơn hàng.' END);
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
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu tài khoản ngân hàng', N'TaiKhoanNganHang', @Id);
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
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        SELECT Id, @DonHangId, N'Yêu cầu hỗ trợ mới', @MoTa FROM dbo.NguoiDung WHERE VaiTro = 'CSKH' AND DangHoatDong = 1;
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

        DECLARE @PhienBan BINARY(8), @TrangThaiCu VARCHAR(20), @NguoiXuLyId INT, @KhachId INT, @DonId INT;
        SELECT @PhienBan = PhienBan, @TrangThaiCu = TrangThai, @NguoiXuLyId = NguoiXuLyId, @KhachId = KhachHangId, @DonId = DonHangId
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan
            THROW 51009, N'Yeu cau ho tro da thay doi.', 1;
        IF @VaiTro = 'CSKH' AND @NguoiXuLyId IS NOT NULL AND @NguoiXuLyId <> @NguoiThucHienId
            THROW 51003, N'Phiếu đang được nhân viên khác tiếp nhận.', 1;
        IF @TrangThai IS NULL OR NOT ((@TrangThaiCu = 'Open' AND @TrangThai IN ('InProgress', 'Rejected'))
            OR (@TrangThaiCu = 'InProgress' AND @TrangThai IN ('Resolved', 'Rejected')))
            THROW 51009, N'Thu tu xu ly: Open -> InProgress -> Resolved; co the tu choi yeu cau chua dong.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') AND NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N'') IS NULL
            THROW 51009, N'Can ghi ket qua hoac ly do tu choi.', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai = @TrangThai, KetQuaXuLy = @KetQuaXuLy, NguoiXuLyId = @NguoiThucHienId, NgayCapNhat = SYSUTCDATETIME()
        WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung, TrangThai)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, COALESCE(NULLIF(LTRIM(RTRIM(@KetQuaXuLy)), N''), N'CSKH đã tiếp nhận yêu cầu.'), @TrangThai);
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        VALUES (@KhachId, @DonId, N'Cập nhật yêu cầu hỗ trợ', COALESCE(@KetQuaXuLy, N'CSKH đã tiếp nhận yêu cầu.'));
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

        DECLARE @KhachHangId INT, @TrangThai VARCHAR(20), @Id INT, @NhanVien INT, @DonId INT;
        SELECT @KhachHangId = KhachHangId, @TrangThai = TrangThai, @NhanVien = NguoiXuLyId, @DonId = DonHangId
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK) WHERE Id = @YeuCauHoTroId;
        IF @KhachHangId IS NULL THROW 51004, N'Khong tim thay yeu cau ho tro.', 1;
        IF @VaiTro = 'KH' AND @KhachHangId <> @NguoiThucHienId
            THROW 51003, N'Khong duoc xem hoac trao doi ho tro cua khach hang khac.', 1;
        IF @TrangThai IN ('Resolved', 'Rejected') THROW 51009, N'Yeu cau ho tro da dong.', 1;
        IF @VaiTro = 'CSKH' AND (@TrangThai <> 'InProgress' OR @NhanVien IS NULL OR @NhanVien <> @NguoiThucHienId)
            THROW 51003, N'Cần tiếp nhận phiếu trước khi trả lời; chỉ nhân viên phụ trách được xử lý.', 1;
        IF NULLIF(LTRIM(RTRIM(@NoiDung)), N'') IS NULL THROW 51009, N'Noi dung trao doi khong duoc rong.', 1;
        INSERT INTO dbo.TraoDoiHoTro (YeuCauHoTroId, NguoiGuiId, NoiDung)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @NoiDung);
        SET @Id = SCOPE_IDENTITY();
        UPDATE dbo.YeuCauHoTro SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.ThongBao (NguoiDungId, DonHangId, TieuDe, NoiDung)
        SELECT Id, @DonId, N'Trao đổi yêu cầu hỗ trợ', @NoiDung FROM dbo.NguoiDung
        WHERE DangHoatDong = 1 AND ((@VaiTro = 'KH' AND VaiTro = 'CSKH' AND (@NhanVien IS NULL OR Id = @NhanVien))
            OR (@VaiTro <> 'KH' AND Id = @KhachHangId));
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

-- Thủ tục quản lý hồ sơ, tài khoản và yêu cầu ví.

CREATE OR ALTER PROCEDURE dbo.sp_HuyYeuCauVi
    @NguoiThucHienId INT,
    @YeuCauViId INT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_HuyYeuCauVi;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KTV')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @YeuCauViId AND KyThuatVienId = @NguoiThucHienId
            AND TrangThai = 'Pending' AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Yêu cầu đã thay đổi hoặc không thuộc thợ.', 1;
        UPDATE dbo.YeuCauVi SET TrangThai = 'Cancelled', LyDo = N'Thợ hủy yêu cầu.' WHERE Id = @YeuCauViId;
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_YeuCauVi WHERE Id = @YeuCauViId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_HuyYeuCauVi;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TuChoiNghiemThu
    @NguoiThucHienId INT,
    @NghiemThuId INT, @PhienBanDuKien BINARY(8), @LyDo NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_TuChoiNghiemThu;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        DECLARE @DonHangId INT;
        SELECT @DonHangId = nt.DonHangId FROM dbo.PhieuNghiemThu AS nt WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DonHang AS dh WITH (UPDLOCK, HOLDLOCK) ON dh.Id = nt.DonHangId
        WHERE nt.Id = @NghiemThuId AND nt.PhienBan = @PhienBanDuKien AND nt.TrangThai = 'Pending'
            AND dh.KhachHangId = @NguoiThucHienId AND dh.TrangThai = 'ChoNghiemThu';
        IF @DonHangId IS NULL THROW 51009, N'Phiếu đã thay đổi hoặc không thuộc khách hàng.', 1;
        IF NULLIF(LTRIM(RTRIM(@LyDo)), N'') IS NULL THROW 51009, N'Cần nêu lý do từ chối nghiệm thu.', 1;
        UPDATE dbo.PhieuNghiemThu SET TrangThai = 'Rejected' WHERE Id = @NghiemThuId;
        UPDATE dbo.DonHang SET TrangThai = 'DangXuLy', NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang(DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoNghiemThu', 'DangXuLy', @NguoiThucHienId, @LyDo);
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_PhieuNghiemThu WHERE Id = @NghiemThuId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_TuChoiNghiemThu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTuyChonGiamSat
    @NguoiThucHienId INT,
    @GiaTri NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_LuuTuyChonGiamSat;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('GD','CSKH','ADMIN')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF ISJSON(@GiaTri) <> 1 THROW 51009, N'Tùy chọn giám sát không hợp lệ.', 1;
        DECLARE @Khoa VARCHAR(100) = 'GiamSat_' + CONVERT(VARCHAR(10), @NguoiThucHienId);
        IF EXISTS (SELECT 1 FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa)
            UPDATE dbo.CauHinh SET GiaTri = @GiaTri WHERE Khoa = @Khoa;
        ELSE
            INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES (@Khoa, @GiaTri, N'Tùy chọn giám sát cá nhân');
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_LuuTuyChonGiamSat;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetChinhSach
    @NguoiThucHienId INT,
    @Khoa VARCHAR(100), @QuyetDinh VARCHAR(30), @GhiChu NVARCHAR(1000), @NgayHieuLuc DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_DuyetChinhSach;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('GD')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF @Khoa NOT LIKE 'DeXuatChinhSach[_]%' OR @QuyetDinh NOT IN ('Approved','Rejected','RevisionRequested')
            THROW 51009, N'Đề xuất hoặc quyết định không hợp lệ.', 1;
        DECLARE @GiaTri NVARCHAR(MAX);
        SELECT @GiaTri = GiaTri FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa;
        IF @GiaTri IS NULL OR ISJSON(@GiaTri) <> 1 THROW 51004, N'Không tìm thấy đề xuất.', 1;
        IF JSON_VALUE(@GiaTri, '$.status') <> 'Pending' THROW 51009, N'Đề xuất đã được xử lý.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            DECLARE @LoaiDeXuat VARCHAR(40) = JSON_VALUE(@GiaTri, '$.payload.type');
            IF @LoaiDeXuat = 'ServicePricing'
            BEGIN
                DECLARE @DichVuId INT = TRY_CONVERT(INT, JSON_VALUE(@GiaTri, '$.payload.serviceId'));
                IF @DichVuId IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @DichVuId)
                    THROW 51004, N'Dịch vụ trong đề xuất không còn tồn tại.', 1;
                UPDATE dbo.DichVu
                SET PhiKiemTra = TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(@GiaTri, '$.payload.inspectionFee')),
                    TienCong = TRY_CONVERT(DECIMAL(18,2), JSON_VALUE(@GiaTri, '$.payload.laborFee')),
                    TyLeHoaHong = TRY_CONVERT(DECIMAL(5,2), JSON_VALUE(@GiaTri, '$.payload.commissionRatePercent'))
                WHERE Id = @DichVuId;
            END
            ELSE IF @LoaiDeXuat = 'Configuration'
            BEGIN
                DECLARE @KhoaCauHinh VARCHAR(80) = JSON_VALUE(@GiaTri, '$.payload.key');
                DECLARE @GiaTriMoi NVARCHAR(1000) = JSON_VALUE(@GiaTri, '$.payload.value');
                IF @KhoaCauHinh NOT IN ('TyLeHoaHongMacDinh', 'PhiHuyDon') OR @GiaTriMoi IS NULL
                    THROW 51009, N'Đề xuất cấu hình không hợp lệ.', 1;
                UPDATE dbo.CauHinh SET GiaTri = @GiaTriMoi WHERE Khoa = @KhoaCauHinh;
            END;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, ChiTiet)
        VALUES (@NguoiThucHienId, N'Duyệt chính sách', @Khoa, @QuyetDinh);
        -- Đề xuất chỉ là hàng chờ phê duyệt. Sau khi có quyết định, xóa khỏi
        -- CauHinh; nhật ký bên trên vẫn lưu dấu vết của quyết định.
        DELETE FROM dbo.CauHinh WHERE Khoa = @Khoa;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_DuyetChinhSach;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiPhuongThucThanhToan
    @NguoiThucHienId INT,
    @DonHangId INT, @PhuongThuc VARCHAR(10), @TaiKhoanNganHangId INT = NULL, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @DaLuu BIT = 0;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE BEGIN
            SAVE TRANSACTION sp_DoiPhuongThucThanhToan;
            SET @DaLuu = 1;
        END;
        DECLARE @VaiTro VARCHAR(10);
        SELECT @VaiTro = VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1;
        IF @VaiTro IS NULL OR @VaiTro NOT IN ('KH')
            THROW 51003, N'Vai trò không được thực hiện thao tác.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
            OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_' + @VaiTro)
            THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
            WHERE Id = @DonHangId AND KhachHangId = @NguoiThucHienId
            AND TrangThai = 'ChoNghiemThu' AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Đơn đã thay đổi hoặc không thuộc khách hàng.', 1;
        IF @PhuongThuc NOT IN ('COD','BANK') THROW 51009, N'Phương thức không hợp lệ.', 1;
        IF EXISTS (SELECT 1 FROM dbo.YeuCauThanhToan WITH (UPDLOCK, HOLDLOCK) WHERE DonHangId = @DonHangId AND TrangThai = 'Pending')
            THROW 51009, N'Đang có chứng từ chờ kế toán xác minh.', 1;
        IF @PhuongThuc = 'BANK' AND NOT EXISTS (SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = @TaiKhoanNganHangId AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nhận tiền không hợp lệ.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.PhieuNghiemThu WHERE DonHangId = @DonHangId AND TrangThai = 'Approved')
            THROW 51009, N'Cần ký nghiệm thu trước khi đổi thanh toán.', 1;
        UPDATE dbo.PhieuNghiemThu SET PhuongThucThanhToan = @PhuongThuc,
            TaiKhoanNganHangId = CASE WHEN @PhuongThuc = 'BANK' THEN @TaiKhoanNganHangId END
        WHERE DonHangId = @DonHangId AND TrangThai = 'Approved';
        UPDATE dbo.DonHang SET NgayCapNhat = SYSUTCDATETIME() WHERE Id = @DonHangId;
        SELECT Id, TrangThai, PhienBan FROM dbo.vw_DonHangTongHop WHERE Id = @DonHangId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 AND @DaLuu = 1 ROLLBACK TRANSACTION sp_DoiPhuongThucThanhToan;
        THROW;
    END CATCH;
END;
GO
