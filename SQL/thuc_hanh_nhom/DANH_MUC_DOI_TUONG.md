# Danh mục đối tượng SQL để bốn thành viên tra cứu

**Không còn chia độc quyền theo module.** Cả bốn thành viên học toàn bộ loại đối tượng, chọn ví dụ theo [phân công](PHAN_CONG.md). Danh mục sau là mã nguồn vận hành để đối chiếu, không phải khẳng định tác giả commit.

| Thành viên | View / Function / SP / Trigger tiêu biểu |
|---|---|
| Nguyễn Quốc Việt | `vw_DichVuCongKhai` / `fn_DiemDanhGia` / `sp_LuuDanhMucDichVu` / `tr_DanhGia_KiemTraDon` |
| Đỗ Anh Tuấn | `vw_DonHangTongHop` / `fn_KyThuatVienPhuHop` / `sp_TaoBaoGiaSoBo` / `tr_DonHang_KiemTraTrangThai` |
| Bùi Nguyễn Duy Trung | `vw_PhieuNghiemThu` / `fn_HanBaoHanh` / `sp_LuuBangKeVatTu` / `tr_ChiTietVatTu_KhoaNghiemThu` |
| Lê Tấn Tài | `vw_ViKyThuatVien` / `fn_SoDuVi` / `sp_LuuTaiKhoanNganHang` / `tr_GiaoDichVi_BatBien` |

## 00_schema.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `NguoiDung` | TABLE | [00_schema.sql:19](../modules/00_schema.sql#L19) |
| `KyThuatVien` | TABLE | [00_schema.sql:35](../modules/00_schema.sql#L35) |
| `DanhMucDichVu` | TABLE | [00_schema.sql:49](../modules/00_schema.sql#L49) |
| `DichVu` | TABLE | [00_schema.sql:56](../modules/00_schema.sql#L56) |
| `DonHang` | TABLE | [00_schema.sql:69](../modules/00_schema.sql#L69) |
| `LichSuDonHang` | TABLE | [00_schema.sql:87](../modules/00_schema.sql#L87) |
| `LenhDieuPhoi` | TABLE | [00_schema.sql:96](../modules/00_schema.sql#L96) |
| `BaoGiaSoBo` | TABLE | [00_schema.sql:107](../modules/00_schema.sql#L107) |
| `BangKeVatTu` | TABLE | [00_schema.sql:121](../modules/00_schema.sql#L121) |
| `ChiTietVatTu` | TABLE | [00_schema.sql:132](../modules/00_schema.sql#L132) |
| `TepDinhKem` | TABLE | [00_schema.sql:142](../modules/00_schema.sql#L142) |
| `PhieuNghiemThu` | TABLE | [00_schema.sql:156](../modules/00_schema.sql#L156) |
| `TaiKhoanNganHang` | TABLE | [00_schema.sql:179](../modules/00_schema.sql#L179) |
| `ThanhToan` | TABLE | [00_schema.sql:190](../modules/00_schema.sql#L190) |
| `DoiSoat` | TABLE | [00_schema.sql:206](../modules/00_schema.sql#L206) |
| `YeuCauThanhToan` | TABLE | [00_schema.sql:221](../modules/00_schema.sql#L221) |
| `YeuCauVi` | TABLE | [00_schema.sql:238](../modules/00_schema.sql#L238) |
| `GiaoDichVi` | TABLE | [00_schema.sql:253](../modules/00_schema.sql#L253) |
| `HoSoKTV` | TABLE | [00_schema.sql:267](../modules/00_schema.sql#L267) |
| `YeuCauHoTro` | TABLE | [00_schema.sql:283](../modules/00_schema.sql#L283) |
| `TraoDoiHoTro` | TABLE | [00_schema.sql:298](../modules/00_schema.sql#L298) |
| `DanhGia` | TABLE | [00_schema.sql:306](../modules/00_schema.sql#L306) |
| `GhiChuDon` | TABLE | [00_schema.sql:316](../modules/00_schema.sql#L316) |
| `ViTriKhachHang` | TABLE | [00_schema.sql:324](../modules/00_schema.sql#L324) |
| `ThongBao` | TABLE | [00_schema.sql:332](../modules/00_schema.sql#L332) |
| `NhatKy` | TABLE | [00_schema.sql:341](../modules/00_schema.sql#L341) |
| `CauHinh` | TABLE | [00_schema.sql:350](../modules/00_schema.sql#L350) |
| `XacThucOTP` | TABLE | [00_schema.sql:355](../modules/00_schema.sql#L355) |

## 01_index.sql – cả bốn thành viên

Mở [01_index.sql](../modules/01_index.sql) để giải thích các lệnh, quyền và điều kiện nâng cấp. Ví dụ được chọn theo phân hệ từng người.

## 02_function.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `fn_HoaHong` | FUNCTION | [02_function.sql:10](../modules/02_function.sql#L10) |
| `fn_SoDuVi` | FUNCTION | [02_function.sql:19](../modules/02_function.sql#L19) |
| `fn_DiemDanhGia` | FUNCTION | [02_function.sql:27](../modules/02_function.sql#L27) |
| `fn_ThongKeDon` | FUNCTION | [02_function.sql:35](../modules/02_function.sql#L35) |
| `fn_HanBaoHanh` | FUNCTION | [02_function.sql:49](../modules/02_function.sql#L49) |
| `fn_TongTienDonHang` | FUNCTION | [02_function.sql:59](../modules/02_function.sql#L59) |
| `fn_KyThuatVienPhuHop` | FUNCTION | [02_function.sql:84](../modules/02_function.sql#L84) |

## 03_view.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `vw_NguoiDung` | VIEW | [03_view.sql:10](../modules/03_view.sql#L10) |
| `vw_KyThuatVien` | VIEW | [03_view.sql:15](../modules/03_view.sql#L15) |
| `vw_DanhMucDichVu` | VIEW | [03_view.sql:22](../modules/03_view.sql#L22) |
| `vw_DichVu` | VIEW | [03_view.sql:27](../modules/03_view.sql#L27) |
| `vw_LichSuDonHang` | VIEW | [03_view.sql:32](../modules/03_view.sql#L32) |
| `vw_LenhDieuPhoi` | VIEW | [03_view.sql:37](../modules/03_view.sql#L37) |
| `vw_BaoGiaSoBo` | VIEW | [03_view.sql:42](../modules/03_view.sql#L42) |
| `vw_BangKeVatTu` | VIEW | [03_view.sql:47](../modules/03_view.sql#L47) |
| `vw_ChiTietVatTu` | VIEW | [03_view.sql:52](../modules/03_view.sql#L52) |
| `vw_PhieuNghiemThu` | VIEW | [03_view.sql:57](../modules/03_view.sql#L57) |
| `vw_ThanhToan` | VIEW | [03_view.sql:62](../modules/03_view.sql#L62) |
| `vw_DoiSoat` | VIEW | [03_view.sql:67](../modules/03_view.sql#L67) |
| `vw_TaiKhoanNganHang` | VIEW | [03_view.sql:72](../modules/03_view.sql#L72) |
| `vw_YeuCauThanhToan` | VIEW | [03_view.sql:77](../modules/03_view.sql#L77) |
| `vw_YeuCauVi` | VIEW | [03_view.sql:82](../modules/03_view.sql#L82) |
| `vw_GiaoDichVi` | VIEW | [03_view.sql:87](../modules/03_view.sql#L87) |
| `vw_HoSoKTV` | VIEW | [03_view.sql:92](../modules/03_view.sql#L92) |
| `vw_YeuCauHoTro` | VIEW | [03_view.sql:97](../modules/03_view.sql#L97) |
| `vw_TraoDoiHoTro` | VIEW | [03_view.sql:107](../modules/03_view.sql#L107) |
| `vw_DanhGia` | VIEW | [03_view.sql:112](../modules/03_view.sql#L112) |
| `vw_GhiChuDon` | VIEW | [03_view.sql:117](../modules/03_view.sql#L117) |
| `vw_ViTriKhachHang` | VIEW | [03_view.sql:122](../modules/03_view.sql#L122) |
| `vw_TepDinhKem` | VIEW | [03_view.sql:127](../modules/03_view.sql#L127) |
| `vw_ThongBao` | VIEW | [03_view.sql:132](../modules/03_view.sql#L132) |
| `vw_NhatKy` | VIEW | [03_view.sql:137](../modules/03_view.sql#L137) |
| `vw_CauHinh` | VIEW | [03_view.sql:144](../modules/03_view.sql#L144) |
| `vw_XacThucDangNhap` | VIEW | [03_view.sql:150](../modules/03_view.sql#L150) |
| `vw_DonHangTongHop` | VIEW | [03_view.sql:155](../modules/03_view.sql#L155) |
| `vw_DichVuCongKhai` | VIEW | [03_view.sql:168](../modules/03_view.sql#L168) |
| `vw_DoanhThuNgay` | VIEW | [03_view.sql:176](../modules/03_view.sql#L176) |
| `vw_ViKyThuatVien` | VIEW | [03_view.sql:187](../modules/03_view.sql#L187) |
| `vw_HieuSuatKyThuatVien` | VIEW | [03_view.sql:195](../modules/03_view.sql#L195) |
| `vw_HoTroCanXuLy` | VIEW | [03_view.sql:207](../modules/03_view.sql#L207) |
| `vw_XacThucOTP` | VIEW | [03_view.sql:215](../modules/03_view.sql#L215) |

## 04_sp.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `sp_DangKyKhachHang` | PROCEDURE | [04_sp.sql:13](../modules/04_sp.sql#L13) |
| `sp_TaoTaiKhoanNoiBo` | PROCEDURE | [04_sp.sql:45](../modules/04_sp.sql#L45) |
| `sp_DoiMatKhau` | PROCEDURE | [04_sp.sql:93](../modules/04_sp.sql#L93) |
| `sp_CapNhatThongTinNguoiDung` | PROCEDURE | [04_sp.sql:129](../modules/04_sp.sql#L129) |
| `sp_KhoaMoKhoaTaiKhoan` | PROCEDURE | [04_sp.sql:165](../modules/04_sp.sql#L165) |
| `sp_DoiVaiTroNguoiDung` | PROCEDURE | [04_sp.sql:217](../modules/04_sp.sql#L217) |
| `sp_AdminCapNhatTaiKhoan` | PROCEDURE | [04_sp.sql:280](../modules/04_sp.sql#L280) |
| `sp_CapNhatTho` | PROCEDURE | [04_sp.sql:349](../modules/04_sp.sql#L349) |
| `sp_CapNhatTrangThaiKTV` | PROCEDURE | [04_sp.sql:390](../modules/04_sp.sql#L390) |
| `sp_GuiHoSoKTV` | PROCEDURE | [04_sp.sql:436](../modules/04_sp.sql#L436) |
| `sp_DuyetHoSoKTV` | PROCEDURE | [04_sp.sql:488](../modules/04_sp.sql#L488) |
| `sp_TaoMaOTP` | PROCEDURE | [04_sp.sql:546](../modules/04_sp.sql#L546) |
| `sp_XacThucOTP` | PROCEDURE | [04_sp.sql:574](../modules/04_sp.sql#L574) |
| `sp_DonDepOTPHetHan` | PROCEDURE | [04_sp.sql:606](../modules/04_sp.sql#L606) |
| `sp_LuuTepDinhKem` | PROCEDURE | [04_sp.sql:630](../modules/04_sp.sql#L630) |
| `sp_GhiNhatKyVaThongBao` | PROCEDURE | [04_sp.sql:682](../modules/04_sp.sql#L682) |
| `sp_DanhDauThongBao` | PROCEDURE | [04_sp.sql:729](../modules/04_sp.sql#L729) |
| `sp_LuuDichVu` | PROCEDURE | [04_sp.sql:764](../modules/04_sp.sql#L764) |
| `sp_LuuDanhMucDichVu` | PROCEDURE | [04_sp.sql:823](../modules/04_sp.sql#L823) |
| `sp_LuuCauHinh` | PROCEDURE | [04_sp.sql:879](../modules/04_sp.sql#L879) |

## 05_transaction.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `sp_TaoDonHang` | PROCEDURE | [05_transaction.sql:11](../modules/05_transaction.sql#L11) |
| `sp_TaoBaoGiaSoBo` | PROCEDURE | [05_transaction.sql:95](../modules/05_transaction.sql#L95) |
| `sp_KhachDuyetBaoGiaSoBo` | PROCEDURE | [05_transaction.sql:182](../modules/05_transaction.sql#L182) |
| `sp_TaoLenhDieuPhoi` | PROCEDURE | [05_transaction.sql:255](../modules/05_transaction.sql#L255) |
| `sp_KTVPhanHoiDieuPhoi` | PROCEDURE | [05_transaction.sql:334](../modules/05_transaction.sql#L334) |
| `sp_ChuyenTrangThaiDon` | PROCEDURE | [05_transaction.sql:414](../modules/05_transaction.sql#L414) |
| `sp_ThemGhiChuDon` | PROCEDURE | [05_transaction.sql:514](../modules/05_transaction.sql#L514) |
| `sp_LuuViTriKhachHang` | PROCEDURE | [05_transaction.sql:579](../modules/05_transaction.sql#L579) |
| `sp_LuuBangKeVatTu` | PROCEDURE | [05_transaction.sql:645](../modules/05_transaction.sql#L645) |
| `sp_ThemChiTietVatTu` | PROCEDURE | [05_transaction.sql:736](../modules/05_transaction.sql#L736) |
| `sp_TaoPhieuNghiemThu` | PROCEDURE | [05_transaction.sql:813](../modules/05_transaction.sql#L813) |
| `sp_KTVKyNghiemThu` | PROCEDURE | [05_transaction.sql:915](../modules/05_transaction.sql#L915) |
| `sp_KhachHangKyNghiemThu` | PROCEDURE | [05_transaction.sql:980](../modules/05_transaction.sql#L980) |
| `sp_XacNhanThanhToanCOD` | PROCEDURE | [05_transaction.sql:1057](../modules/05_transaction.sql#L1057) |
| `sp_TaoYeuCauThanhToan` | PROCEDURE | [05_transaction.sql:1135](../modules/05_transaction.sql#L1135) |
| `sp_XacNhanThanhToanNganHang` | PROCEDURE | [05_transaction.sql:1216](../modules/05_transaction.sql#L1216) |
| `sp_DoiSoatCOD` | PROCEDURE | [05_transaction.sql:1324](../modules/05_transaction.sql#L1324) |
| `sp_TaoYeuCauVi` | PROCEDURE | [05_transaction.sql:1404](../modules/05_transaction.sql#L1404) |
| `sp_DuyetYeuCauVi` | PROCEDURE | [05_transaction.sql:1477](../modules/05_transaction.sql#L1477) |
| `sp_LuuTaiKhoanNganHang` | PROCEDURE | [05_transaction.sql:1558](../modules/05_transaction.sql#L1558) |
| `sp_TaoYeuCauHoTro` | PROCEDURE | [05_transaction.sql:1645](../modules/05_transaction.sql#L1645) |
| `sp_XuLyHoTro` | PROCEDURE | [05_transaction.sql:1719](../modules/05_transaction.sql#L1719) |
| `sp_ThemTraoDoiHoTro` | PROCEDURE | [05_transaction.sql:1793](../modules/05_transaction.sql#L1793) |
| `sp_TaoDanhGiaDonHang` | PROCEDURE | [05_transaction.sql:1863](../modules/05_transaction.sql#L1863) |
| `sp_BaoCaoTongHop` | PROCEDURE | [05_transaction.sql:1926](../modules/05_transaction.sql#L1926) |
| `sp_HuyYeuCauVi` | PROCEDURE | [05_transaction.sql:1952](../modules/05_transaction.sql#L1952) |
| `sp_TuChoiNghiemThu` | PROCEDURE | [05_transaction.sql:1991](../modules/05_transaction.sql#L1991) |
| `sp_LuuTuyChonGiamSat` | PROCEDURE | [05_transaction.sql:2036](../modules/05_transaction.sql#L2036) |
| `sp_DuyetChinhSach` | PROCEDURE | [05_transaction.sql:2075](../modules/05_transaction.sql#L2075) |
| `sp_DoiPhuongThucThanhToan` | PROCEDURE | [05_transaction.sql:2142](../modules/05_transaction.sql#L2142) |

## 06_trigger.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `tr_DonHang_KiemTraTrangThai` | TRIGGER | [06_trigger.sql:11](../modules/06_trigger.sql#L11) |
| `tr_ThanhToan_KiemTraChungTu` | TRIGGER | [06_trigger.sql:52](../modules/06_trigger.sql#L52) |
| `tr_ThanhToan_BatBien` | TRIGGER | [06_trigger.sql:69](../modules/06_trigger.sql#L69) |
| `tr_GiaoDichVi_BatBien` | TRIGGER | [06_trigger.sql:76](../modules/06_trigger.sql#L76) |
| `tr_DanhGia_KiemTraDon` | TRIGGER | [06_trigger.sql:83](../modules/06_trigger.sql#L83) |
| `tr_ChiTietVatTu_KhoaNghiemThu` | TRIGGER | [06_trigger.sql:96](../modules/06_trigger.sql#L96) |
| `tr_PhieuNghiemThu_KiemTraChuKy` | TRIGGER | [06_trigger.sql:110](../modules/06_trigger.sql#L110) |

## 07_security.sql – cả bốn thành viên

Mở [07_security.sql](../modules/07_security.sql) để giải thích các lệnh, quyền và điều kiện nâng cấp. Ví dụ được chọn theo phân hệ từng người.

## 08_seed.sql – cả bốn thành viên

Mở [08_seed.sql](../modules/08_seed.sql) để giải thích các lệnh, quyền và điều kiện nâng cấp. Ví dụ được chọn theo phân hệ từng người.

## 09_data_migration.sql – cả bốn thành viên

Mở [09_data_migration.sql](../modules/09_data_migration.sql) để giải thích các lệnh, quyền và điều kiện nâng cấp. Ví dụ được chọn theo phân hệ từng người.

## 10_backup_recovery.sql – cả bốn thành viên

| Đối tượng | Loại | Vị trí nguồn |
|---|---|---|
| `sp_SaoLuuHeThong` | PROCEDURE | [10_backup_recovery.sql:9](../modules/10_backup_recovery.sql#L9) |

`XacThucOTP` và `ViTriKhachHang` là cấu trúc tương thích cũ, không phải chức năng OTP/Google Maps đang chạy trên web. Không xóa bảng có dữ liệu để đổi số lượng trong báo cáo.
