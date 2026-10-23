SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* UNIQUE lọc bảo vệ quy tắc nghiệp vụ; chỉ mục thường tăng tốc tra cứu.
   Các khóa chính/UNIQUE trong schema đã tự có chỉ mục, không tạo trùng. */
CREATE UNIQUE INDEX UX_NguoiDung_Email ON dbo.NguoiDung(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_LenhDieuPhoi_Don ON dbo.LenhDieuPhoi(DonHangId) WHERE DangHoatDong = 1;
CREATE UNIQUE INDEX UX_LenhDieuPhoi_Tho ON dbo.LenhDieuPhoi(KyThuatVienId) WHERE DangHoatDong = 1;
CREATE UNIQUE INDEX UX_BangKeVatTu_DangApDung ON dbo.BangKeVatTu(DonHangId) WHERE DangApDung = 1;
CREATE UNIQUE INDEX UX_NghiemThu_Don ON dbo.PhieuNghiemThu(DonHangId) WHERE TrangThai <> 'Rejected';
CREATE UNIQUE INDEX UX_ThanhToan_NghiemThu ON dbo.ThanhToan(NghiemThuId) WHERE NghiemThuId IS NOT NULL;
CREATE UNIQUE INDEX UX_ThanhToan_MaThamChieu ON dbo.ThanhToan(MaThamChieu) WHERE MaThamChieu IS NOT NULL;
CREATE UNIQUE INDEX UX_YeuCauThanhToan_DangCho ON dbo.YeuCauThanhToan(DonHangId) WHERE TrangThai = 'Pending';
CREATE UNIQUE INDEX UX_HoSoKTV_DangCho ON dbo.HoSoKTV(NguoiDungId) WHERE TrangThai = 'Pending';
CREATE INDEX IX_DonHang_Khach_TrangThai ON dbo.DonHang(KhachHangId, TrangThai) INCLUDE (DichVuId, KyThuatVienId, NgayTao);
CREATE INDEX IX_DonHang_Tho_TrangThai ON dbo.DonHang(KyThuatVienId, TrangThai) INCLUDE (KhachHangId, NgayTao);
CREATE INDEX IX_DonHang_TrangThai_Ngay ON dbo.DonHang(TrangThai, NgayTao DESC);
CREATE INDEX IX_LichSuDonHang_Don_Ngay ON dbo.LichSuDonHang(DonHangId, NgayTao, Id);
CREATE INDEX IX_ChiTietVatTu_DeXuat ON dbo.ChiTietVatTu(BangKeVatTuId) INCLUDE (ThanhTien, SoThangBaoHanh);
CREATE INDEX IX_GiaoDichVi_Tho_Ngay ON dbo.GiaoDichVi(KyThuatVienId, NgayTao DESC) INCLUDE (SoTien, Loai);
CREATE INDEX IX_YeuCauVi_TrangThai_Ngay ON dbo.YeuCauVi(TrangThai, NgayTao) INCLUDE (KyThuatVienId, SoTien);
CREATE INDEX IX_YeuCauHoTro_TrangThai ON dbo.YeuCauHoTro(TrangThai, NgayTao) INCLUDE (DonHangId, KhachHangId);
CREATE INDEX IX_TraoDoiHoTro_YeuCau ON dbo.TraoDoiHoTro(YeuCauHoTroId, NgayTao);
CREATE INDEX IX_ThongBao_Nguoi_DaDoc ON dbo.ThongBao(NguoiDungId, DaDoc, NgayTao DESC);
CREATE INDEX IX_TepDinhKem_Don ON dbo.TepDinhKem(DonHangId, MucDich) INCLUDE (ChuSoHuuId);
CREATE INDEX IX_XacThucOTP_HetHan ON dbo.XacThucOTP(NgayHetHan);
GO
