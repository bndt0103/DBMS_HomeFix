SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
/* View công khai ghi rõ từng cột; bí mật chỉ dành cho view xác thực nội bộ. */
CREATE OR ALTER VIEW dbo.vw_NguoiDung
AS
SELECT Id, HoTen, SoDienThoai, Email, VaiTro, DangHoatDong, DiaChi, NgayTao, PhienBan
FROM dbo.NguoiDung;
GO
CREATE OR ALTER VIEW dbo.vw_KyThuatVien
AS
SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe, ktv.KhuVucPhucVu,
    ktv.TrangThaiSanSang, ktv.SoDu, ktv.ViDo, ktv.KinhDo, ktv.PhienBan
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id;
GO
CREATE OR ALTER VIEW dbo.vw_DanhMucDichVu
AS
SELECT Id, Ten, Ma, DangHoatDong, PhienBan
FROM dbo.DanhMucDichVu;
GO
CREATE OR ALTER VIEW dbo.vw_DichVu
AS
SELECT Id, DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong, PhienBan
FROM dbo.DichVu;
GO
CREATE OR ALTER VIEW dbo.vw_LichSuDonHang
AS
SELECT Id, DonHangId, TrangThaiTruoc, TrangThaiSau, NguoiThucHienId, LyDo, NgayTao
FROM dbo.LichSuDonHang;
GO
CREATE OR ALTER VIEW dbo.vw_LenhDieuPhoi
AS
SELECT Id, DonHangId, KyThuatVienId, TrangThai, DangHoatDong, NguoiTaoId, NgayTao, PhienBan
FROM dbo.LenhDieuPhoi;
GO
CREATE OR ALTER VIEW dbo.vw_BaoGiaSoBo
AS
SELECT Id, DonHangId, PhiKiemTra, TienCong, TyLeHoaHong, TongTien, ChanDoan, TrangThai, NgayTao, PhienBan
FROM dbo.BaoGiaSoBo;
GO
CREATE OR ALTER VIEW dbo.vw_BangKeVatTu
AS
SELECT Id, DonHangId, LanSuaDoi, DangApDung, NguoiTaoId, NgayTao, PhienBan
FROM dbo.BangKeVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_ChiTietVatTu
AS
SELECT Id, BangKeVatTuId, Ten, SoLuong, DonGia, SoThangBaoHanh, ThanhTien
FROM dbo.ChiTietVatTu;
GO
CREATE OR ALTER VIEW dbo.vw_PhieuNghiemThu
AS
SELECT Id, DonHangId, KyThuatVienId, BangKeVatTuId, NguyenNhan, PhuongAnXuLy, PhiKiemTra, TienCong, TongTienVatTu, TongTien, TrangThai, ChuKyKTVId, ChuKyKHId, PhuongThucThanhToan, TaiKhoanNganHangId, NgayDuyet, NgayTao, PhienBan
FROM dbo.PhieuNghiemThu;
GO
CREATE OR ALTER VIEW dbo.vw_ThanhToan
AS
SELECT Id, DonHangId, LoaiThanhToan, NghiemThuId, SoTien, PhuongThuc, NguoiThuTienId, MaThamChieu, TaiKhoanNganHangId, NgayTao
FROM dbo.ThanhToan;
GO
CREATE OR ALTER VIEW dbo.vw_DoiSoat
AS
SELECT Id, ThanhToanId, DonHangId, KyThuatVienId, TienCong, TyLeHoaHong, TienHoaHong, TrangThai, NguoiDuyetId, NgayTao, PhienBan
FROM dbo.DoiSoat;
GO
CREATE OR ALTER VIEW dbo.vw_TaiKhoanNganHang
AS
SELECT Id, MaNganHang, TenNganHang, SoTaiKhoan, ChuTaiKhoan, DangHoatDong, PhienBan
FROM dbo.TaiKhoanNganHang;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauThanhToan
AS
SELECT Id, DonHangId, LoaiThanhToan, NghiemThuId, KhachHangId, TaiKhoanNganHangId, SoTien, ChungTuId, MaThamChieu, TrangThai, NgayTao, PhienBan
FROM dbo.YeuCauThanhToan;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauVi
AS
SELECT Id, KyThuatVienId, Loai, SoTien, GhiChu, ChungTuId, TrangThai, LyDo, NgayTao, PhienBan
FROM dbo.YeuCauVi;
GO
CREATE OR ALTER VIEW dbo.vw_GiaoDichVi
AS
SELECT Id, KyThuatVienId, Loai, SoTien, LoaiThamChieu, ThamChieuId, NguoiThucHienId, GhiChu, NgayTao
FROM dbo.GiaoDichVi;
GO
CREATE OR ALTER VIEW dbo.vw_HoSoKTV
AS
SELECT Id, NguoiDungId, NhomTayNghe, KhuVucPhucVu, KinhNghiem, HoSoJSON, GiayToMatTruocId, GiayToMatSauId, TrangThai, LyDo, NgayTao, PhienBan
FROM dbo.HoSoKTV;
GO
CREATE OR ALTER VIEW dbo.vw_YeuCauHoTro
AS
SELECT ht.Id, ht.DonHangId, ht.KhachHangId, kh.HoTen AS TenKhachHang, kh.SoDienThoai AS SDTKhachHang,
    ht.Loai, ht.MoTa, ht.TrangThai, ht.KetQuaXuLy, ht.NguoiXuLyId, nv.HoTen AS TenNguoiXuLy,
    dh.TenDichVu, dh.DiaChi, dh.TrangThai AS TrangThaiDon, ht.NgayTao, ht.NgayCapNhat, ht.PhienBan
FROM dbo.YeuCauHoTro AS ht
INNER JOIN dbo.NguoiDung AS kh ON kh.Id = ht.KhachHangId
INNER JOIN dbo.DonHang AS dh ON dh.Id = ht.DonHangId
LEFT JOIN dbo.NguoiDung AS nv ON nv.Id = ht.NguoiXuLyId;
GO
CREATE OR ALTER VIEW dbo.vw_TraoDoiHoTro
AS
SELECT td.Id, td.YeuCauHoTroId, td.NguoiGuiId, nd.HoTen, nd.VaiTro, td.NoiDung, td.TrangThai, td.NgayTao
FROM dbo.TraoDoiHoTro AS td INNER JOIN dbo.NguoiDung AS nd ON nd.Id = td.NguoiGuiId;
GO
CREATE OR ALTER VIEW dbo.vw_DanhGia
AS
SELECT Id, DonHangId, KhachHangId, KyThuatVienId, Diem, NhanXet, NgayTao
FROM dbo.DanhGia;
GO
CREATE OR ALTER VIEW dbo.vw_GhiChuDon
AS
SELECT Id, DonHangId, NguoiVietId, NoiDung, NoiBo, NgayTao
FROM dbo.GhiChuDon;
GO
CREATE OR ALTER VIEW dbo.vw_ViTriKhachHang
AS
SELECT DonHangId, KhachHangId, ViDo, KinhDo, NgayCapNhat
FROM dbo.ViTriKhachHang;
GO
CREATE OR ALTER VIEW dbo.vw_TepDinhKem
AS
SELECT Id, ChuSoHuuId, DonHangId, MucDich, KhoaLuuTru, TenTepGoc, KieuMIME, KichThuoc, NgayTao
FROM dbo.TepDinhKem;
GO
CREATE OR ALTER VIEW dbo.vw_ThongBao
AS
SELECT Id, NguoiDungId, DonHangId, TieuDe, NoiDung, DaDoc, NgayTao
FROM dbo.ThongBao;
GO
CREATE OR ALTER VIEW dbo.vw_NhatKy
AS
SELECT Id, NguoiThucHienId, ThaoTac, DoiTuong, DoiTuongId, ChiTiet, NgayTao
FROM dbo.NhatKy;
GO
CREATE OR ALTER VIEW dbo.vw_CauHinh
AS
SELECT Khoa, GiaTri, NhanHienThi
FROM dbo.CauHinh;
GO

CREATE OR ALTER VIEW dbo.vw_XacThucDangNhap
AS
SELECT Id, HoTen, SoDienThoai, Email, MatKhauBam, VaiTro, DangHoatDong, PhienBan
FROM dbo.NguoiDung;
GO
CREATE OR ALTER VIEW dbo.vw_DonHangTongHop
AS
SELECT dh.Id, dv.DanhMucId, dm.Ma AS MaDanhMuc, dh.KhachHangId, kh.HoTen AS TenKhachHang, kh.SoDienThoai AS SDTKhachHang,
    dh.DichVuId, dh.TenDichVu, dh.DiaChi, dh.MoTa, dh.NgayHen, dh.TrangThai,
    dh.KyThuatVienId, ktv.HoTen AS TenKyThuatVien, ktv.SoDienThoai AS SDTKyThuatVien,
    dh.PhiHuyDon, dh.NgayTao, dh.NgayCapNhat, dh.PhienBan, dbo.fn_TongTienDonHang(dh.Id) AS TongTien,
    (SELECT HanBaoHanh FROM dbo.fn_HanBaoHanh(dh.Id)) AS HanBaoHanh
FROM dbo.DonHang AS dh
INNER JOIN dbo.DichVu AS dv ON dv.Id = dh.DichVuId
INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
INNER JOIN dbo.NguoiDung AS kh ON kh.Id = dh.KhachHangId
LEFT JOIN dbo.NguoiDung AS ktv ON ktv.Id = dh.KyThuatVienId;
GO
CREATE OR ALTER VIEW dbo.vw_DichVuCongKhai
AS
SELECT dv.Id, dv.DanhMucId, dm.Ten AS TenDanhMuc, dm.Ma AS MaDanhMuc,
    dv.Ten, dv.MoTa, dv.PhiKiemTra, dv.TienCong, dv.TyLeHoaHong, dv.DangHoatDong, dv.PhienBan
FROM dbo.DichVu AS dv
INNER JOIN dbo.DanhMucDichVu AS dm ON dm.Id = dv.DanhMucId
WHERE dv.DangHoatDong = 1 AND dm.DangHoatDong = 1;
GO
CREATE OR ALTER VIEW dbo.vw_DoanhThuNgay
AS
SELECT CONVERT(DATE, DATEADD(HOUR, 7, tt.NgayTao)) AS Ngay, COUNT_BIG(*) AS SoDon,
    SUM(tt.SoTien) AS TongThu, SUM(CASE WHEN tt.PhuongThuc = 'COD' THEN tt.SoTien ELSE 0 END) AS ThuCOD,
    SUM(CASE WHEN tt.PhuongThuc = 'BANK' THEN tt.SoTien ELSE 0 END) AS ThuNganHang,
    SUM(ds.TienHoaHong) AS TienHoaHong,
    SUM(CASE WHEN ds.TrangThai = 'Confirmed' THEN ds.TienHoaHong ELSE 0 END) AS HoaHongDaDoiSoat
FROM dbo.ThanhToan AS tt
INNER JOIN dbo.DoiSoat AS ds ON ds.ThanhToanId = tt.Id
GROUP BY CONVERT(DATE, DATEADD(HOUR, 7, tt.NgayTao));
GO
CREATE OR ALTER VIEW dbo.vw_ViKyThuatVien
AS
SELECT ktv.Id, nd.HoTen, nd.SoDienThoai, ktv.NhomTayNghe, ktv.KhuVucPhucVu,
    ktv.TrangThaiSanSang, ktv.SoDu, (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS SoDuSoCai,
    ktv.SoDu - (SELECT SoDu FROM dbo.fn_SoDuVi(ktv.Id)) AS ChenhLech, ktv.ViDo, ktv.KinhDo, ktv.PhienBan
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id;
GO
CREATE OR ALTER VIEW dbo.vw_HieuSuatKyThuatVien
AS
SELECT ktv.Id AS KyThuatVienId, nd.HoTen, COUNT(dh.Id) AS TongDon,
    COALESCE(SUM(CASE WHEN dh.TrangThai = 'HoanThanh' THEN 1 ELSE 0 END), 0) AS SoDonHoanThanh,
    (SELECT DiemTrungBinh FROM dbo.fn_DiemDanhGia(ktv.Id)) AS DiemTrungBinh,
    COALESCE(SUM(CASE WHEN dh.TrangThai = 'HoanThanh' THEN tt.SoTien ELSE 0 END), 0) AS TongTienDaThu
FROM dbo.KyThuatVien AS ktv
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ktv.Id
LEFT JOIN dbo.DonHang AS dh ON dh.KyThuatVienId = ktv.Id
LEFT JOIN dbo.ThanhToan AS tt ON tt.DonHangId = dh.Id
GROUP BY ktv.Id, nd.HoTen;
GO
CREATE OR ALTER VIEW dbo.vw_HoTroCanXuLy
AS
SELECT ht.Id, ht.DonHangId, ht.KhachHangId, nd.HoTen AS TenKhachHang,
    ht.Loai, ht.MoTa, ht.TrangThai, ht.KetQuaXuLy, ht.NguoiXuLyId, ht.NgayTao, ht.PhienBan
FROM dbo.YeuCauHoTro AS ht
INNER JOIN dbo.NguoiDung AS nd ON nd.Id = ht.KhachHangId
WHERE ht.TrangThai IN ('Open','InProgress');
GO
CREATE OR ALTER VIEW dbo.vw_XacThucOTP
AS
SELECT Id, MucDich, DiaChiNhan, SoLanThu, DaSuDung, NgayHetHan, NgayTao
FROM dbo.XacThucOTP;
GO
