SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/* 7 role nghiệp vụ + role kỹ thuật nội bộ phục vụ đăng nhập/OTP.
   Tài khoản hf_* WITHOUT LOGIN dùng để EXECUTE AS USER khi demo hoặc từ backend.
   Không cấp db_owner/db_datareader/db_datawriter cho tài khoản ứng dụng.
   Backend lọc phạm vi dữ liệu theo JWT; role SQL giới hạn đối tượng được đọc/chạy.
   EXECUTE AS USER không tự xác định danh tính KH: tham số actor lấy từ JWT.
   Quyền IMPERSONATE chỉ cấp trên các user hf_* cho login kết nối ứng dụng.
   Chủ sở hữu dbo giữ nguyên giúp ownership chain: SP/View truy cập bảng nội bộ
   dù caller không được thao tác trực tiếp. Không sử dụng dynamic SQL cho CRUD. */
IF DATABASE_PRINCIPAL_ID('HomeFix_KH') IS NULL CREATE ROLE HomeFix_KH AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KH') IS NULL CREATE USER hf_KH WITHOUT LOGIN;
ALTER ROLE HomeFix_KH ADD MEMBER hf_KH;
IF DATABASE_PRINCIPAL_ID('HomeFix_KTV') IS NULL CREATE ROLE HomeFix_KTV AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KTV') IS NULL CREATE USER hf_KTV WITHOUT LOGIN;
ALTER ROLE HomeFix_KTV ADD MEMBER hf_KTV;
IF DATABASE_PRINCIPAL_ID('HomeFix_DPV') IS NULL CREATE ROLE HomeFix_DPV AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_DPV') IS NULL CREATE USER hf_DPV WITHOUT LOGIN;
ALTER ROLE HomeFix_DPV ADD MEMBER hf_DPV;
IF DATABASE_PRINCIPAL_ID('HomeFix_CSKH') IS NULL CREATE ROLE HomeFix_CSKH AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_CSKH') IS NULL CREATE USER hf_CSKH WITHOUT LOGIN;
ALTER ROLE HomeFix_CSKH ADD MEMBER hf_CSKH;
IF DATABASE_PRINCIPAL_ID('HomeFix_KT') IS NULL CREATE ROLE HomeFix_KT AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_KT') IS NULL CREATE USER hf_KT WITHOUT LOGIN;
ALTER ROLE HomeFix_KT ADD MEMBER hf_KT;
IF DATABASE_PRINCIPAL_ID('HomeFix_GD') IS NULL CREATE ROLE HomeFix_GD AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_GD') IS NULL CREATE USER hf_GD WITHOUT LOGIN;
ALTER ROLE HomeFix_GD ADD MEMBER hf_GD;
IF DATABASE_PRINCIPAL_ID('HomeFix_ADMIN') IS NULL CREATE ROLE HomeFix_ADMIN AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_ADMIN') IS NULL CREATE USER hf_ADMIN WITHOUT LOGIN;
ALTER ROLE HomeFix_ADMIN ADD MEMBER hf_ADMIN;
IF DATABASE_PRINCIPAL_ID('HomeFix_UngDung') IS NULL CREATE ROLE HomeFix_UngDung AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID('hf_UngDung') IS NULL CREATE USER hf_UngDung WITHOUT LOGIN;
ALTER ROLE HomeFix_UngDung ADD MEMBER hf_UngDung;
GO
REVOKE EXECUTE ON OBJECT::dbo.sp_DuyetHoSoKTV FROM HomeFix_DPV;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.NguoiDung TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.KyThuatVien TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DanhMucDichVu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DichVu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DonHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LichSuDonHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LenhDieuPhoi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.BaoGiaSoBo TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.BangKeVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ChiTietVatTu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TepDinhKem TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PhieuNghiemThu TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TaiKhoanNganHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ThanhToan TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DoiSoat TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauThanhToan TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.HoSoKTV TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.YeuCauHoTro TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.TraoDoiHoTro TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.DanhGia TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.GhiChuDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ViTriKhachHang TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.ThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.NhatKy TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.CauHinh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.XacThucOTP TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY SELECT ON OBJECT::dbo.NguoiDung(MatKhauBam) TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
DENY UPDATE, DELETE ON OBJECT::dbo.GiaoDichVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
GO
-- Đọc dữ liệu: KH
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KH;
GO
-- Đọc dữ liệu: KTV
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_KTV;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KTV;
GO
-- Đọc dữ liệu: DPV
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_DPV;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_DPV;
GO
-- Đọc dữ liệu: CSKH
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_CSKH;
GO
-- Đọc dữ liệu: KT
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KT;
GO
-- Đọc dữ liệu: GD
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_GD;
GO
-- Đọc dữ liệu: ADMIN
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ThongBao TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DonHangTongHop TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_LichSuDonHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_LenhDieuPhoi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_BaoGiaSoBo TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_BangKeVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ChiTietVatTu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_PhieuNghiemThu TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ThanhToan TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_GhiChuDon TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ViTriKhachHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TepDinhKem TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TraoDoiHoTro TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HoTroCanXuLy TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_TaiKhoanNganHang TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauThanhToan TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DoiSoat TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauVi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_GiaoDichVi TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_ViKyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_DoanhThuNgay TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_HoSoKTV TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_NhatKy TO HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_ADMIN;
GO
-- Đọc dữ liệu: UngDung
GRANT SELECT ON OBJECT::dbo.vw_XacThucDangNhap TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_XacThucOTP TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_NguoiDung TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DichVuCongKhai TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DichVu TO HomeFix_UngDung;
GRANT SELECT ON OBJECT::dbo.vw_DanhMucDichVu TO HomeFix_UngDung;
GO
GRANT EXECUTE ON OBJECT::dbo.sp_DangKyKhachHang TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoTaiKhoanNoiBo TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiMatKhau TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN, HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatThongTinNguoiDung TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KhoaMoKhoaTaiKhoan TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiVaiTroNguoiDung TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTho TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_CapNhatTrangThaiKTV TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_GuiHoSoKTV TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetHoSoKTV TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoMaOTP TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_XacThucOTP TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_DonDepOTPHetHan TO HomeFix_UngDung;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTepDinhKem TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_GhiNhatKyVaThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DanhDauThongBao TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuDichVu TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuDanhMucDichVu TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuCauHinh TO HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoDonHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoBaoGiaSoBo TO HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KhachDuyetBaoGiaSoBo TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoLenhDieuPhoi TO HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_KTVPhanHoiDieuPhoi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_ChuyenTrangThaiDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemGhiChuDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuViTriKhachHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuBangKeVatTu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemChiTietVatTu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoPhieuNghiemThu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_KTVKyNghiemThu TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_KhachHangKyNghiemThu TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XacNhanThanhToanCOD TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauThanhToan TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XacNhanThanhToanNganHang TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DoiSoatCOD TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauVi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetYeuCauVi TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTaiKhoanNganHang TO HomeFix_KT, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoYeuCauHoTro TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_XuLyHoTro TO HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_ThemTraoDoiHoTro TO HomeFix_KH, HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_TaoDanhGiaDonHang TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_BaoCaoTongHop TO HomeFix_GD, HomeFix_KT, HomeFix_ADMIN;
GO
-- TVF chỉ đọc: demo báo cáo và tra cứu, không được GRANT trực tiếp bảng.
GRANT SELECT ON OBJECT::dbo.fn_SoDuVi TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_DiemDanhGia TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_HanBaoHanh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT SELECT ON OBJECT::dbo.fn_ThongKeDon TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.fn_HoaHong TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH, HomeFix_KT, HomeFix_GD, HomeFix_ADMIN;
GO
/* Đối chiếu sau khi cài (chạy riêng trong SSMS):
EXECUTE AS USER = 'hf_KH';
SELECT Id, HoTen, VaiTro FROM dbo.vw_NguoiDung; -- được, view không có hash
SELECT SoDu FROM dbo.fn_SoDuVi(2);            -- được, TVF chỉ đọc
SELECT Id FROM dbo.NguoiDung;                -- lỗi 229: truy cập bảng bị chặn
SELECT MatKhauBam FROM dbo.vw_XacThucDangNhap; -- lỗi 229: chỉ hf_UngDung được đọc
REVERT; -- luôn trở lại tài khoản ban đầu sau demo quyền
*/

-- Quyền cho hồ sơ và báo cáo; không cấp quyền bảng.
GRANT SELECT ON OBJECT::dbo.vw_CauHinh TO HomeFix_KH, HomeFix_KTV, HomeFix_DPV, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_KyThuatVien TO HomeFix_KH, HomeFix_KT, HomeFix_CSKH;
GRANT SELECT ON OBJECT::dbo.vw_YeuCauHoTro TO HomeFix_DPV, HomeFix_KT, HomeFix_GD;
GRANT SELECT ON OBJECT::dbo.vw_DanhGia TO HomeFix_DPV, HomeFix_KT, HomeFix_GD;
GRANT EXECUTE ON OBJECT::dbo.sp_HuyYeuCauVi TO HomeFix_KTV;
GRANT EXECUTE ON OBJECT::dbo.sp_TuChoiNghiemThu TO HomeFix_KH;
GRANT EXECUTE ON OBJECT::dbo.sp_LuuTuyChonGiamSat TO HomeFix_GD, HomeFix_CSKH, HomeFix_ADMIN;
GRANT EXECUTE ON OBJECT::dbo.sp_DuyetChinhSach TO HomeFix_GD;
GO

GRANT EXECUTE ON OBJECT::dbo.sp_DoiPhuongThucThanhToan TO HomeFix_KH;
GO

-- Hiệu suất toàn bộ KTV chỉ dành cho điều phối, giám đốc và quản trị.
DENY SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_KH, HomeFix_KTV, HomeFix_CSKH, HomeFix_KT;
GRANT SELECT ON OBJECT::dbo.vw_HieuSuatKyThuatVien TO HomeFix_DPV, HomeFix_GD, HomeFix_ADMIN;
GO
