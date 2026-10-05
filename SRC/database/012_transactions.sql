-- Do an He quan tri co so du lieu - Nhom 08.
-- Ten bang, cot va tham so: tieng Viet khong dau, PascalCase.
SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

GO
CREATE OR ALTER PROCEDURE dbo.sp_ChuyenTrangThaiDon
    @DonHangId INT, @NguoiThucHienId INT, @PhienBanDuKien BINARY(8), @TrangThaiTiepTheo VARCHAR(30), @LyDo NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION sp_ChuyenTrangThaiDon;
        DECLARE @TrangThaiTruocDo AS VARCHAR(30), @PhienBanHienTai AS BINARY(8);
        SELECT @TrangThaiTruocDo = TrangThai, @PhienBanHienTai = PhienBan
        FROM dbo.DonHang WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @DonHangId;
        IF @TrangThaiTruocDo IS NULL
            THROW 51004, 'ORDER_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NOT NULL AND @PhienBanDuKien <> @PhienBanHienTai
            THROW 51009, 'VERSION_CONFLICT', 1;
        IF NOT ((@TrangThaiTruocDo = 'ChoTiepNhan' AND @TrangThaiTiepTheo IN ('ChoDuyetSoBo', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoDuyetSoBo' AND @TrangThaiTiepTheo IN ('ChoPhanCong', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoPhanCong' AND @TrangThaiTiepTheo IN ('ChoNhan', 'Huy'))
            OR (@TrangThaiTruocDo = 'ChoNhan' AND @TrangThaiTiepTheo IN ('DaTiepNhan', 'ChoPhanCong', 'Huy'))
            OR (@TrangThaiTruocDo = 'DaTiepNhan' AND @TrangThaiTiepTheo IN ('DangDiChuyen', 'Huy'))
            OR (@TrangThaiTruocDo = 'DangDiChuyen' AND @TrangThaiTiepTheo IN ('DaDenNoi', 'Huy'))
            OR (@TrangThaiTruocDo = 'DaDenNoi' AND @TrangThaiTiepTheo = 'DangXuLy')
            OR (@TrangThaiTruocDo = 'DangXuLy' AND @TrangThaiTiepTheo = 'ChoNghiemThu')
            OR (@TrangThaiTruocDo = 'ChoNghiemThu' AND @TrangThaiTiepTheo IN ('HoanThanh', 'DangXuLy')))
            THROW 51009, 'INVALID_TRANSITION', 1;
        UPDATE dbo.DonHang
        SET TrangThai    = @TrangThaiTiepTheo,
            NgayCapNhat  = SYSUTCDATETIME(),
            NgayKhoiHanh = CASE WHEN @TrangThaiTiepTheo = 'DangDiChuyen' THEN SYSUTCDATETIME() ELSE NgayKhoiHanh END
        WHERE Id = @DonHangId;
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, @TrangThaiTruocDo, @TrangThaiTiepTheo, @NguoiThucHienId, @LyDo);
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION sp_ChuyenTrangThaiDon;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_DoiSoatCOD
    @DoiSoatId INT, @NguoiThucHienId INT, @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION sp_DoiSoatCOD;
        DECLARE @KTV AS INT,
            @HoaHong AS DECIMAL(18, 2),
            @TinhTrang AS VARCHAR(10),
            @PhienBan AS BINARY(8),
            @PhuongThuc AS VARCHAR(10),
            @TongTien AS DECIMAL(18, 2),
            @TienThucNhan AS DECIMAL(18, 2);
        SELECT @KTV = s.KyThuatVienId, @HoaHong = s.TienHoaHong, @TinhTrang = s.TrangThai, @PhienBan = s.PhienBan, @PhuongThuc = p.PhuongThuc, @TongTien = p.SoTien
        FROM dbo.DoiSoat AS s WITH (UPDLOCK, HOLDLOCK)
             INNER JOIN dbo.ThanhToan AS p ON p.Id = s.ThanhToanId
        WHERE s.Id = @DoiSoatId;
        IF @KTV IS NULL
            THROW 51004, 'SETTLEMENT_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @TinhTrang <> 'Pending' OR @PhienBan <> @PhienBanDuKien
            THROW 51009, 'SETTLEMENT_ALREADY_CONFIRMED_OR_STALE', 1;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'KT' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @PhuongThuc = 'COD'
            BEGIN
                IF (SELECT SoDu
                    FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK)
                    WHERE Id = @KTV) < @HoaHong
                    THROW 51009, 'INSUFFICIENT_BALANCE', 1;
                IF @HoaHong > 0
                    INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                    VALUES (@KTV, 'Commission', -@HoaHong, 'Settlement', @DoiSoatId, @NguoiThucHienId, N'Đối soát hoa hồng tiền mặt');
            END
        ELSE
            BEGIN
                SET @TienThucNhan = @TongTien - @HoaHong;
                IF @TienThucNhan < 0
                    THROW 51009, 'INVALID_SETTLEMENT_AMOUNT', 1;
                IF @TienThucNhan > 0
                    INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                    VALUES (@KTV, 'SettlementCredit', @TienThucNhan, 'Settlement', @DoiSoatId, @NguoiThucHienId, N'Tiền chuyển khoản HomeFix đã nhận: cộng tiền thuộc KTV sau hoa hồng (gồm phí kiểm tra và vật tư)');
            END
        UPDATE dbo.DoiSoat
        SET TrangThai      = 'Confirmed',
            NguoiXacNhanId = @NguoiThucHienId,
            NgayXacNhan    = SYSUTCDATETIME()
        WHERE Id = @DoiSoatId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId)
        VALUES (@NguoiThucHienId, 'ConfirmSettlement', 'DoiSoat', @DoiSoatId);
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION sp_DoiSoatCOD;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_TaoDonHang
    @KhachHangId INT, @DichVuId INT, @DiaChi NVARCHAR(500), @MoTa NVARCHAR(2000), @NgayHen DATETIME2=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION TaoDonHang;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @KhachHangId AND VaiTro = 'KH' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF LEN(LTRIM(RTRIM(@DiaChi))) < 10 OR LEN(LTRIM(RTRIM(@MoTa))) < 5
            THROW 51009, 'INVALID_ORDER_INPUT', 1;
        IF @NgayHen IS NOT NULL AND (@NgayHen < DATEADD(minute, 30, SYSUTCDATETIME()) OR @NgayHen > DATEADD(day, 30, SYSUTCDATETIME()) OR DATEPART(hour, DATEADD(hour, 7, @NgayHen)) NOT BETWEEN 8 AND 17 OR DATEPART(minute, @NgayHen) % 30 <> 0 OR DATEPART(second, @NgayHen) <> 0)
            THROW 51009, 'INVALID_SCHEDULE', 1;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.DichVu WITH (UPDLOCK, HOLDLOCK)
                       WHERE Id = @DichVuId AND DangHoatDong = 1)
            THROW 51004, 'SERVICE_UNAVAILABLE', 1;
        INSERT INTO dbo.DonHang (KhachHangId, DichVuId, TenDichVu, NhomDichVu, TenLienHe, SoDienThoaiLienHe, DiaChi, MoTa, NgayHen, PhiHuyTaiThoiDiemDat)
        SELECT u.Id, s.Id, s.Ten, s.MaNhom, u.HoTen, u.SoDienThoai, @DiaChi, @MoTa, @NgayHen, COALESCE ((SELECT TRY_CONVERT (DECIMAL(18, 2), GiaTri)
                                                                                                         FROM dbo.CauHinh
                                                                                                         WHERE [KhoaCauHinh] = 'cancellationFee'), 50000)
        FROM dbo.NguoiDung AS u CROSS JOIN dbo.DichVu AS s
        WHERE u.Id = @KhachHangId AND s.Id = @DichVuId;
        DECLARE @DonHangId AS INT = SCOPE_IDENTITY();
        INSERT INTO dbo.LichSuDonHang (DonHangId, TrangThaiSau, NguoiThucHienId, LyDo)
        VALUES (@DonHangId, 'ChoTiepNhan', @KhachHangId, N'Khách hàng đặt dịch vụ');
        SELECT *
        FROM dbo.DonHang
        WHERE Id = @DonHangId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION TaoDonHang;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_DuyetYeuCauVi
    @YeuCauId INT, @NguoiThucHienId INT, @QuyetDinh VARCHAR(10), @PhienBanDuKien BINARY(8), @LyDo NVARCHAR(1000)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION DuyetVi;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'KT' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @QuyetDinh NOT IN ('Approved', 'Rejected') OR @QuyetDinh IS NULL
            THROW 51009, 'INVALID_DECISION', 1;
        IF @QuyetDinh = 'Rejected' AND NULLIF (LTRIM(RTRIM(@LyDo)), '') IS NULL
            THROW 51009, 'REASON_REQUIRED', 1;
        DECLARE @KyThuatVienId AS INT, @SoTien AS DECIMAL(18, 2), @Loai AS VARCHAR(15), @TrangThai AS VARCHAR(10), @PhienBan AS BINARY(8);
        SELECT @KyThuatVienId = KyThuatVienId, @SoTien = SoTien, @Loai = Loai, @TrangThai = TrangThai, @PhienBan = PhienBan
        FROM dbo.YeuCauVi WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @YeuCauId;
        IF @KyThuatVienId IS NULL
            THROW 51004, 'REQUEST_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBan <> @PhienBanDuKien OR @TrangThai <> 'Pending'
            THROW 51009, 'VERSION_CONFLICT', 1;
        IF @QuyetDinh = 'Approved'
            BEGIN
                IF @Loai = 'Withdrawal'
                    BEGIN
                        IF (SELECT SoDu
                            FROM dbo.KyThuatVien WITH (UPDLOCK, HOLDLOCK)
                            WHERE Id = @KyThuatVienId) < @SoTien
                            THROW 51009, 'INSUFFICIENT_BALANCE', 1;
                        IF EXISTS (SELECT 1
                                   FROM dbo.LenhDieuPhoi WITH (UPDLOCK, HOLDLOCK)
                                   WHERE KyThuatVienId = @KyThuatVienId AND DangHoatDong = 1)
                            THROW 51009, 'ACTIVE_ASSIGNMENT', 1;
                    END
                INSERT INTO dbo.GiaoDichVi (KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu)
                SELECT KyThuatVienId, Loai, CASE WHEN [Loai] = 'Withdrawal' THEN -SoTien ELSE SoTien END, 'WalletRequest', Id, @NguoiThucHienId, GhiChu
                FROM dbo.YeuCauVi
                WHERE Id = @YeuCauId;
            END
        UPDATE dbo.YeuCauVi
        SET TrangThai    = @QuyetDinh,
            LyDo         = @LyDo,
            NguoiDuyetId = @NguoiThucHienId,
            NgayDuyet    = SYSUTCDATETIME()
        WHERE Id = @YeuCauId;
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, 'DecideWallet', 'YeuCauVi', @YeuCauId, @QuyetDinh);
        SELECT *
        FROM dbo.YeuCauVi
        WHERE Id = @YeuCauId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION DuyetVi;
        THROW;
    END CATCH
END

GO
CREATE OR ALTER PROCEDURE dbo.sp_XuLyHoTro
    @YeuCauHoTroId INT, @NguoiThucHienId INT, @TrangThai VARCHAR(15), @KetQuaXuLy NVARCHAR(2000), @PhienBanDuKien BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @TuMoGiaoDich AS BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    BEGIN TRY
        IF @TuMoGiaoDich = 1
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION XuLyHoTro;
        IF NOT EXISTS (SELECT 1
                       FROM dbo.NguoiDung
                       WHERE Id = @NguoiThucHienId AND VaiTro = 'CSKH' AND DangHoatDong = 1)
            THROW 51003, 'FORBIDDEN', 1;
        IF @TrangThai IS NULL OR @TrangThai NOT IN ('InProgress', 'Resolved', 'Rejected') OR LEN(LTRIM(RTRIM(@KetQuaXuLy))) < 5
            THROW 51009, 'INVALID_SUPPORT_INPUT', 1;
        DECLARE @PhienBan AS BINARY(8), @TrangThaiTruocDo AS VARCHAR(15);
        SELECT @PhienBan = PhienBan, @TrangThaiTruocDo = TrangThai
        FROM dbo.YeuCauHoTro WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @YeuCauHoTroId;
        IF @PhienBan IS NULL
            THROW 51004, 'TICKET_NOT_FOUND', 1;
        IF @PhienBanDuKien IS NULL OR @PhienBanDuKien <> @PhienBan OR @TrangThaiTruocDo NOT IN ('Open', 'InProgress')
            THROW 51009, 'VERSION_CONFLICT', 1;
        UPDATE dbo.YeuCauHoTro
        SET TrangThai       = @TrangThai,
            KetQuaXuLy      = @KetQuaXuLy,
            NguoiDuocGiaoId = @NguoiThucHienId,
            NgayCapNhat     = SYSUTCDATETIME()
        WHERE Id = @YeuCauHoTroId;
        INSERT INTO dbo.LichSuHoTro (YeuCauHoTroId, NguoiThucHienId, TrangThai, GhiChu)
        VALUES (@YeuCauHoTroId, @NguoiThucHienId, @TrangThai, @KetQuaXuLy);
        INSERT INTO dbo.NhatKy (NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet)
        VALUES (@NguoiThucHienId, 'UpdateTicket', 'YeuCauHoTro', @YeuCauHoTroId, @TrangThai);
        SELECT *
        FROM dbo.YeuCauHoTro
        WHERE Id = @YeuCauHoTroId;
        IF @TuMoGiaoDich = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TuMoGiaoDich = 1 AND XACT_STATE() <> 0
            ROLLBACK;
        ELSE
            IF @TuMoGiaoDich = 0 AND XACT_STATE() = 1
                ROLLBACK TRANSACTION XuLyHoTro;
        THROW;
    END CATCH
END
GO
