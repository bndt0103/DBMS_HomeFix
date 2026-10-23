SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* Thủ tục tài khoản và tiện ích.
   Mỗi lệnh ghi là một giao dịch nguyên tử. Nếu được gọi trong giao dịch khác,
   SAVE TRANSACTION giữ điểm quay lui; không COMMIT giao dịch của bên gọi.
   Mật khẩu được băm bcrypt ở backend; SQL chỉ lưu chuỗi băm. */
CREATE OR ALTER PROCEDURE dbo.sp_DangKyKhachHang
    @HoTen NVARCHAR(120), @SoDienThoai VARCHAR(15), @MatKhauBam VARCHAR(100),
    @Email NVARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DangKyKhachHang;

        SET @HoTen = LTRIM(RTRIM(@HoTen));
        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        IF EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE SoDienThoai = @SoDienThoai)
            THROW 51009, N'Số điện thoại đã được đăng ký.', 1;
        IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Email = @Email)
            THROW 51009, N'Email đã được sử dụng.', 1;
        INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, Email, MatKhauBam, VaiTro)
        VALUES (@HoTen, @SoDienThoai, @Email, @MatKhauBam, 'KH');
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DangKyKhachHang;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoTaiKhoanNoiBo
    @NguoiThucHienId INT, @HoTen NVARCHAR(120), @SoDienThoai VARCHAR(15),
    @MatKhauBam VARCHAR(100), @VaiTro VARCHAR(5), @Email NVARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_TaoTaiKhoanNoiBo;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        SET @HoTen = LTRIM(RTRIM(@HoTen));
        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không nằm trong bảy vai trò hệ thống.', 1;
        IF EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE SoDienThoai = @SoDienThoai)
            THROW 51009, N'Số điện thoại đã được sử dụng.', 1;
        INSERT INTO dbo.NguoiDung(HoTen, SoDienThoai, Email, MatKhauBam, VaiTro)
        VALUES (@HoTen, @SoDienThoai, @Email, @MatKhauBam, @VaiTro);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @VaiTro = 'KTV' INSERT INTO dbo.KyThuatVien(Id) VALUES (@Id);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Tạo tài khoản', N'NguoiDung', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_TaoTaiKhoanNoiBo;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiMatKhau
    @NguoiThucHienId INT, @MatKhauBam VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DoiMatKhau;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo' AND USER_NAME() <> N'hf_UngDung'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        UPDATE dbo.NguoiDung SET MatKhauBam = @MatKhauBam WHERE Id = @NguoiThucHienId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Đổi mật khẩu', N'NguoiDung', @NguoiThucHienId);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DoiMatKhau;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatThongTinNguoiDung
    @NguoiThucHienId INT, @HoTen NVARCHAR(120),
    @Email NVARCHAR(254) = NULL, @DiaChi NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatThongTinNguoiDung;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
        UPDATE dbo.NguoiDung SET HoTen = LTRIM(RTRIM(@HoTen)), Email = @Email, DiaChi = @DiaChi WHERE Id = @NguoiThucHienId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatThongTinNguoiDung;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KhoaMoKhoaTaiKhoan
    @NguoiThucHienId INT, @NguoiDungId INT, @DangHoatDong BIT,
    @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_KhoaMoKhoaTaiKhoan;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @NguoiDungId = @NguoiThucHienId AND @DangHoatDong = 0
            THROW 51009, N'Quản trị viên không được tự khóa tài khoản đang sử dụng.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND VaiTro = 'ADMIN')
           AND (SELECT COUNT(*) FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId) = 0
            THROW 51009, N'Phải duy trì ít nhất một quản trị viên đang hoạt động.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId AND TrangThai NOT IN ('HoanThanh','Huy'))
            THROW 51009, N'Kỹ thuật viên còn đơn đang thực hiện; cần xử lý đơn trước khi khóa.', 1;
        UPDATE dbo.NguoiDung SET DangHoatDong = @DangHoatDong WHERE Id = @NguoiDungId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, CASE WHEN @DangHoatDong = 1 THEN N'Mở khóa tài khoản' ELSE N'Khóa tài khoản' END, N'NguoiDung', @NguoiDungId);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_KhoaMoKhoaTaiKhoan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DoiVaiTroNguoiDung
    @NguoiThucHienId INT, @NguoiDungId INT, @VaiTro VARCHAR(5),
    @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DoiVaiTroNguoiDung;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không hợp lệ.', 1;
        IF @NguoiDungId = @NguoiThucHienId AND @VaiTro <> 'ADMIN'
            THROW 51009, N'Không được tự bỏ quyền quản trị của phiên đăng nhập.', 1;
        IF @VaiTro <> 'ADMIN' AND EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND VaiTro = 'ADMIN')
           AND NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId)
            THROW 51009, N'Phải giữ lại ít nhất một quản trị viên.', 1;
        IF @VaiTro <> 'KTV' AND EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.GiaoDichVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.YeuCauVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiDungId)
                THROW 51009, N'Thợ đã có chứng từ; giữ vai trò để bảo toàn lịch sử, có thể khóa tài khoản.', 1;
            DELETE FROM dbo.KyThuatVien WHERE Id = @NguoiDungId;
        END;
        UPDATE dbo.NguoiDung SET VaiTro = @VaiTro WHERE Id = @NguoiDungId;
        IF @VaiTro = 'KTV' AND NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
            INSERT INTO dbo.KyThuatVien(Id) VALUES (@NguoiDungId);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Đổi vai trò', N'NguoiDung', @NguoiDungId, @VaiTro);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DoiVaiTroNguoiDung;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdminCapNhatTaiKhoan
    @NguoiThucHienId INT, @NguoiDungId INT, @HoTen NVARCHAR(120),
    @SoDienThoai VARCHAR(15), @Email NVARCHAR(254) = NULL,
    @VaiTro VARCHAR(5), @NhomTayNghe VARCHAR(30) = NULL,
    @DangHoatDong BIT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT, @VaiTroCu VARCHAR(5);
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_AdminCapNhatTaiKhoan;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro = 'ADMIN' AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF USER_NAME() <> N'dbo' AND (
            TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
            OR USER_NAME() <> N'hf_ADMIN'
        ) THROW 51003, N'Ngữ cảnh tài khoản không khớp.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        SELECT @VaiTroCu = VaiTro FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId;
        IF @VaiTroCu IS NULL THROW 51004, N'Không tìm thấy tài khoản cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiDungId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;
        IF NULLIF(LTRIM(RTRIM(@HoTen)), N'') IS NULL OR @SoDienThoai LIKE '%[^0-9]%' OR LEN(@SoDienThoai) NOT BETWEEN 9 AND 15
            THROW 51009, N'Họ tên hoặc số điện thoại không hợp lệ.', 1;
        IF @VaiTro NOT IN ('KH','KTV','DPV','CSKH','KT','GD','ADMIN')
            THROW 51009, N'Vai trò không hợp lệ.', 1;
        IF @VaiTro = 'KTV' AND (@NhomTayNghe IS NULL OR @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA'))
            THROW 51009, N'KTV phải có đúng một chuyên môn hợp lệ.', 1;
        IF @NguoiDungId = @NguoiThucHienId AND (@VaiTro <> 'ADMIN' OR @DangHoatDong = 0)
            THROW 51009, N'Không được tự bỏ quyền hoặc khóa tài khoản quản trị đang dùng.', 1;
        IF (@VaiTroCu = 'ADMIN' AND (@VaiTro <> 'ADMIN' OR @DangHoatDong = 0))
           AND NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE VaiTro = 'ADMIN' AND DangHoatDong = 1 AND Id <> @NguoiDungId)
            THROW 51009, N'Phải duy trì ít nhất một quản trị viên đang hoạt động.', 1;
        IF @DangHoatDong = 0 AND EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId AND TrangThai NOT IN ('HoanThanh','Huy'))
            THROW 51009, N'KTV còn đơn đang thực hiện; cần xử lý trước khi khóa.', 1;
        IF @VaiTro <> 'KTV' AND EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.DonHang WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.GiaoDichVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.YeuCauVi WHERE KyThuatVienId = @NguoiDungId)
               OR EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiDungId)
                THROW 51009, N'KTV đã có chứng từ; hãy giữ vai trò KTV hoặc khóa tài khoản.', 1;
            DELETE FROM dbo.KyThuatVien WHERE Id = @NguoiDungId;
        END;
        UPDATE dbo.NguoiDung
        SET HoTen = LTRIM(RTRIM(@HoTen)), SoDienThoai = @SoDienThoai,
            Email = NULLIF(LTRIM(RTRIM(@Email)), N''), VaiTro = @VaiTro, DangHoatDong = @DangHoatDong
        WHERE Id = @NguoiDungId;
        IF @VaiTro = 'KTV' AND NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiDungId)
            INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe) VALUES (@NguoiDungId, @NhomTayNghe);
        ELSE IF @VaiTro = 'KTV'
            UPDATE dbo.KyThuatVien SET NhomTayNghe = @NhomTayNghe WHERE Id = @NguoiDungId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Cập nhật tài khoản', N'NguoiDung', @NguoiDungId, @VaiTro);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan
        FROM dbo.vw_NguoiDung WHERE Id = @NguoiDungId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_AdminCapNhatTaiKhoan;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTho
    @NguoiThucHienId INT, @NhomTayNghe NVARCHAR(200), @KhuVucPhucVu NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatTho;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KTV') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')
            THROW 51009, N'Kỹ thuật viên chỉ được chọn một chuyên môn hợp lệ.', 1;

        UPDATE dbo.KyThuatVien SET NhomTayNghe = @NhomTayNghe, KhuVucPhucVu = @KhuVucPhucVu WHERE Id = @NguoiThucHienId;
        IF @@ROWCOUNT = 0 THROW 51004, N'Chưa có hồ sơ kỹ thuật viên.', 1;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatTho;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTrangThaiKTV
    @NguoiThucHienId INT, @TrangThaiSanSang VARCHAR(12), @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_CapNhatTrangThaiKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KTV') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiThucHienId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.KyThuatVien WHERE Id = @NguoiThucHienId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @TrangThaiSanSang NOT IN ('SanSang','TamBan')
            THROW 51009, N'Chỉ tự chuyển giữa sẵn sàng và tạm bận.', 1;
        IF EXISTS (SELECT 1 FROM dbo.LenhDieuPhoi WHERE KyThuatVienId = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51009, N'Đang có phân công; không được đổi trạng thái thủ công.', 1;
        UPDATE dbo.KyThuatVien SET TrangThaiSanSang = @TrangThaiSanSang WHERE Id = @NguoiThucHienId;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NhomTayNghe, KhuVucPhucVu, TrangThaiSanSang, SoDu, PhienBan FROM dbo.vw_KyThuatVien WHERE Id = @NguoiThucHienId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_CapNhatTrangThaiKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GuiHoSoKTV
    @NguoiThucHienId INT, @NhomTayNghe NVARCHAR(200), @KhuVucPhucVu NVARCHAR(200),
    @KinhNghiem NVARCHAR(2000),
    @HoSoJSON NVARCHAR(MAX) = NULL, @GiayToMatTruocId INT = NULL, @GiayToMatSauId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_GuiHoSoKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('KH') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF EXISTS (SELECT 1 FROM dbo.HoSoKTV WITH (UPDLOCK, HOLDLOCK) WHERE NguoiDungId = @NguoiThucHienId AND TrangThai = 'Pending')
            THROW 51009, N'Đã có hồ sơ đang chờ duyệt.', 1;
        IF @NhomTayNghe NOT IN ('DIEN','NUOC','DIEN_LANH','DO_GO','KHOA')
            THROW 51009, N'Kỹ thuật viên chỉ được chọn một chuyên môn hợp lệ.', 1;
        IF @HoSoJSON IS NOT NULL AND ISJSON(@HoSoJSON) <> 1
            THROW 51009, N'Nội dung hồ sơ phải là JSON hợp lệ.', 1;
        IF EXISTS (
            SELECT Id FROM (VALUES (@GiayToMatTruocId), (@GiayToMatSauId)) AS x(Id)
            WHERE Id IS NOT NULL AND NOT EXISTS (
                SELECT 1 FROM dbo.TepDinhKem AS t WHERE t.Id = x.Id
                AND t.ChuSoHuuId = @NguoiThucHienId AND t.MucDich = 'TechnicianDocument')
        ) THROW 51003, N'Ảnh giấy tờ phải thuộc người nộp hồ sơ.', 1;
        INSERT INTO dbo.HoSoKTV(NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, HoSoJSON, GiayToMatTruocId, GiayToMatSauId)
        VALUES (@NguoiThucHienId, @NhomTayNghe, @KhuVucPhucVu, @KinhNghiem, @HoSoJSON, @GiayToMatTruocId, @GiayToMatSauId);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, TrangThai, LyDo, NgayTao, PhienBan FROM dbo.vw_HoSoKTV WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_GuiHoSoKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DuyetHoSoKTV
    @NguoiThucHienId INT, @HoSoId INT, @QuyetDinh VARCHAR(10), @PhienBanDuKien BINARY(8),
    @LyDo NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DuyetHoSoKTV;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WITH (UPDLOCK, HOLDLOCK) WHERE Id = @HoSoId)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WHERE Id = @HoSoId AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

        IF @QuyetDinh NOT IN ('Approved','Rejected') THROW 51009, N'Quyết định phải là Approved hoặc Rejected.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoSoKTV WHERE Id = @HoSoId AND TrangThai = 'Pending')
            THROW 51009, N'Hồ sơ đã được xử lý.', 1;
        DECLARE @NguoiDungId INT, @TayNghe NVARCHAR(200), @KhuVuc NVARCHAR(200);
        SELECT @NguoiDungId = NguoiDungId, @TayNghe = NhomTayNghe, @KhuVuc = KhuVucPhucVu FROM dbo.HoSoKTV WHERE Id = @HoSoId;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WITH (UPDLOCK, HOLDLOCK) WHERE Id = @NguoiDungId AND VaiTro = 'KH' AND DangHoatDong = 1)
            THROW 51009, N'Tài khoản nộp hồ sơ đã bị khóa hoặc thay đổi vai trò.', 1;
        IF @QuyetDinh = 'Approved'
        BEGIN
            UPDATE dbo.NguoiDung SET VaiTro = 'KTV' WHERE Id = @NguoiDungId;
            INSERT INTO dbo.KyThuatVien(Id, NhomTayNghe, KhuVucPhucVu)
            VALUES (@NguoiDungId, @TayNghe, @KhuVuc);
        END;
        UPDATE dbo.HoSoKTV SET TrangThai = @QuyetDinh, LyDo = @LyDo WHERE Id = @HoSoId;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, N'Duyệt hồ sơ thợ', N'HoSoKTV', @HoSoId, @QuyetDinh);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, TrangThai, LyDo, NgayTao, PhienBan FROM dbo.vw_HoSoKTV WHERE Id = @HoSoId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DuyetHoSoKTV;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuTepDinhKem
    @NguoiThucHienId INT, @DonHangId INT = NULL, @MucDich VARCHAR(25),
    @KhoaLuuTru VARCHAR(100), @TenTepGoc NVARCHAR(255), @KieuMIME VARCHAR(100), @KichThuoc INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuTepDinhKem;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        IF @KhoaLuuTru LIKE '%/%' OR @KhoaLuuTru LIKE '%\%' OR @KhoaLuuTru LIKE '%..%' OR LEN(@KhoaLuuTru) < 5
            THROW 51009, N'Khóa tệp không được chứa đường dẫn.', 1;
        IF @DonHangId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.DonHang WHERE Id = @DonHangId)
                THROW 51004, N'Không tìm thấy đơn hàng của tệp.', 1;
            IF NOT EXISTS (
                SELECT 1 FROM dbo.DonHang AS dh INNER JOIN dbo.NguoiDung AS nd ON nd.Id = @NguoiThucHienId
                WHERE dh.Id = @DonHangId AND (dh.KhachHangId = @NguoiThucHienId OR dh.KyThuatVienId = @NguoiThucHienId OR nd.VaiTro IN ('DPV','CSKH','KT','ADMIN'))
            ) THROW 51003, N'Không được thêm tệp vào đơn của người khác.', 1;
        END;
        IF @MucDich IN ('MaterialEvidence','AcceptancePhoto','CustomerSignature','TechnicianSignature','PaymentProof') AND @DonHangId IS NULL
            THROW 51009, N'Tệp nghiệp vụ này cần gắn với đơn hàng.', 1;
        IF @MucDich IN ('CustomerSignature','TechnicianSignature') AND @KieuMIME NOT IN ('image/png','image/jpeg','image/webp')
            THROW 51009, N'Chữ ký phải là tệp ảnh.', 1;
        INSERT INTO dbo.TepDinhKem(ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc)
        VALUES (@NguoiThucHienId, @DonHangId, @MucDich, @KhoaLuuTru, @TenTepGoc, @KieuMIME, @KichThuoc);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc, NgayTao FROM dbo.vw_TepDinhKem WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuTepDinhKem;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DanhDauThongBao
    @NguoiThucHienId INT, @ThongBaoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_DanhDauThongBao;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;

        UPDATE dbo.ThongBao SET DaDoc = 1 WHERE Id = @ThongBaoId AND NguoiDungId = @NguoiThucHienId;
        IF @@ROWCOUNT = 0 THROW 51004, N'Không tìm thấy thông báo của bạn.', 1;
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, NguoiDungId, DonHangId, TieuDe, NoiDung, DaDoc, NgayTao FROM dbo.vw_ThongBao WHERE Id = @ThongBaoId;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_DanhDauThongBao;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuDichVu
    @NguoiThucHienId INT, @Id INT = NULL, @DanhMucId INT, @Ten NVARCHAR(180),
    @MoTa NVARCHAR(1000), @PhiKiemTra DECIMAL(18,2), @TienCong DECIMAL(18,2), @TyLeHoaHong DECIMAL(5,2),
    @DangHoatDong BIT = 1, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuDichVu;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF @DangHoatDong = 1 AND NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WHERE Id = @DanhMucId AND DangHoatDong = 1)
            THROW 51009, N'Danh mục chưa tồn tại hoặc đã ngừng hoạt động.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.DichVu(DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong)
            VALUES (@DanhMucId, @Ten, @MoTa, @PhiKiemTra, @TienCong, @TyLeHoaHong, @DangHoatDong);
            SET @Id = CONVERT(INT, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DichVu WHERE Id = @Id AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

            UPDATE dbo.DichVu SET DanhMucId = @DanhMucId, Ten = @Ten, MoTa = @MoTa, PhiKiemTra = @PhiKiemTra,
                TienCong = @TienCong, TyLeHoaHong = @TyLeHoaHong, DangHoatDong = @DangHoatDong WHERE Id = @Id;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu dịch vụ', N'DichVu', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong, PhienBan FROM dbo.vw_DichVu WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuDichVu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuDanhMucDichVu
    @NguoiThucHienId INT, @Id INT = NULL, @Ten NVARCHAR(100), @Ma VARCHAR(30),
    @DangHoatDong BIT = 1, @PhienBanDuKien BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuDanhMucDichVu;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF NULLIF(LTRIM(RTRIM(@Ten)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Ma)), '') IS NULL
            THROW 51009, N'Tên và mã danh mục không được để trống.', 1;
        IF @Id IS NULL
        BEGIN
            INSERT INTO dbo.DanhMucDichVu(Ten, Ma, DangHoatDong) VALUES (@Ten, @Ma, @DangHoatDong);
            SET @Id = CONVERT(INT, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
        IF @PhienBanDuKien IS NULL
            THROW 51009, N'Phải gửi phiên bản dữ liệu đang xem trước khi cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WITH (UPDLOCK, HOLDLOCK) WHERE Id = @Id)
            THROW 51004, N'Không tìm thấy dữ liệu cần cập nhật.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDichVu WHERE Id = @Id AND PhienBan = @PhienBanDuKien)
            THROW 51009, N'Dữ liệu đã thay đổi; hãy tải lại và thử lại.', 1;

            UPDATE dbo.DanhMucDichVu SET Ten = @Ten, Ma = @Ma, DangHoatDong = @DangHoatDong WHERE Id = @Id;
        END;
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, N'Lưu danh mục dịch vụ', N'DanhMucDichVu', @Id);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Id, Ten, Ma, DangHoatDong, PhienBan FROM dbo.vw_DanhMucDichVu WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuDanhMucDichVu;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LuuCauHinh
    @NguoiThucHienId INT, @Khoa VARCHAR(80), @GiaTri NVARCHAR(1000), @NhanHienThi NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @GiaoDichNgoai INT = @@TRANCOUNT;
    BEGIN TRY
        IF @GiaoDichNgoai = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION s_LuuCauHinh;

        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND DangHoatDong = 1)
            THROW 51003, N'Tài khoản thực hiện không hợp lệ hoặc đã bị khóa.', 1;

        -- Backend đặt actor vào SESSION_CONTEXT rồi mới EXECUTE AS USER hf_<VaiTro>.
        -- Tham số Id không đủ để giả danh một người khác trong cùng role SQL.
        IF USER_NAME() <> N'dbo'
           AND (TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) IS NULL
             OR TRY_CONVERT(INT, SESSION_CONTEXT(N'NguoiDungId')) <> @NguoiThucHienId
             OR USER_NAME() <> N'hf_' + (SELECT VaiTro FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId))
            THROW 51003, N'Ngữ cảnh người dùng không khớp tài khoản và vai trò thực hiện.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Id = @NguoiThucHienId AND VaiTro IN ('ADMIN') AND DangHoatDong = 1)
            THROW 51003, N'Vai trò không được phép thực hiện thao tác này.', 1;

        IF @Khoa = 'TyLeHoaHongMacDinh' AND (TRY_CONVERT(DECIMAL(5,2), @GiaTri) IS NULL OR TRY_CONVERT(DECIMAL(5,2), @GiaTri) NOT BETWEEN 0 AND 100)
            THROW 51009, N'Tỷ lệ hoa hồng phải từ 0 đến 100 phần trăm.', 1;
        IF @Khoa = 'PhiHuyDon' AND (TRY_CONVERT(DECIMAL(18,2), @GiaTri) IS NULL OR TRY_CONVERT(DECIMAL(18,2), @GiaTri) NOT BETWEEN 1000 AND 1000000)
            THROW 51009, N'Phí hủy đơn phải từ 1000 đến 1000000 đồng.', 1;
        IF @Khoa = 'TaiKhoanNganHangMacDinh' AND NOT EXISTS (
            SELECT 1 FROM dbo.TaiKhoanNganHang WHERE Id = TRY_CONVERT(INT, @GiaTri) AND DangHoatDong = 1
        ) THROW 51009, N'Tài khoản ngân hàng mặc định phải đang hoạt động.', 1;
        IF @Khoa LIKE 'DeXuatChinhSach[_]%'
        BEGIN
            IF ISJSON(@GiaTri) <> 1
                THROW 51009, N'Đề xuất chính sách không hợp lệ.', 1;
            DECLARE @DoiTuongDeXuat VARCHAR(100) = JSON_VALUE(@GiaTri, '$.policySubject');
            IF NULLIF(@DoiTuongDeXuat, '') IS NULL
                THROW 51009, N'Đề xuất chính sách không hợp lệ.', 1;
            -- Bản gửi lại thay thế bằng cách xóa hẳn bản đang chờ cùng đối tượng,
            -- sau đó chèn đề xuất mới với khóa/mã mới.
            DELETE FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK)
            WHERE Khoa LIKE 'DeXuatChinhSach[_]%'
              AND ISJSON(GiaTri) = 1
              AND COALESCE(
                    JSON_VALUE(GiaTri, '$.policySubject'),
                    CASE JSON_VALUE(GiaTri, '$.payload.type')
                        WHEN 'ServicePricing' THEN CONCAT('DichVu_', JSON_VALUE(GiaTri, '$.payload.serviceId'))
                        WHEN 'Configuration' THEN CONCAT('CauHinh_', JSON_VALUE(GiaTri, '$.payload.key'))
                    END
                  ) = @DoiTuongDeXuat;
        END;
        IF EXISTS (SELECT 1 FROM dbo.CauHinh WITH (UPDLOCK, HOLDLOCK) WHERE Khoa = @Khoa)
            UPDATE dbo.CauHinh SET GiaTri = @GiaTri, NhanHienThi = @NhanHienThi WHERE Khoa = @Khoa;
        ELSE INSERT INTO dbo.CauHinh(Khoa, GiaTri, NhanHienThi) VALUES (@Khoa, @GiaTri, @NhanHienThi);
        INSERT INTO dbo.NhatKy(NguoiThucHienId, ThaoTac, DoiTuong, ChiTiet)
        VALUES (@NguoiThucHienId, N'Lưu cấu hình', N'CauHinh', @Khoa);
        IF @GiaoDichNgoai = 0 COMMIT TRANSACTION;
        SELECT Khoa, GiaTri, NhanHienThi FROM dbo.vw_CauHinh WHERE Khoa = @Khoa;
    END TRY
    BEGIN CATCH
        IF @GiaoDichNgoai = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @GiaoDichNgoai > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION s_LuuCauHinh;
        THROW;
    END CATCH;
END;
GO
