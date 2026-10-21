# Phụ lục cấu trúc và ràng buộc HomeFix

Trích xuất trực tiếp ngày 21/10/2026 từ `MSI\SQLEXPRESS / HomeFix_DBMS_Nhom08_TiengViet`. Không chứa mật khẩu hoặc bản ghi cá nhân. Đây là **định nghĩa cuối sau các migration**, dùng để đối chiếu khi các đoạn CREATE ban đầu và ALTER sau đó có khác nhau.

Đọc hướng dẫn chính trước: [ON_TAP_VAN_DAP_CHI_TIET.md](ON_TAP_VAN_DAP_CHI_TIET.md).

## Cách đọc phụ lục

Mỗi bảng có: mục đích → cột và NULL → khóa/unique/index → CHECK → FK. DEFAULT được ghi ngay cạnh cột. Cột tính toán không nhập giá trị trực tiếp. SQL Server có thể báo nullable cho cột tính toán theo metadata; hãy đọc thêm các toán hạng NOT NULL và biểu thức. Tên constraint do SQL Server tự sinh có hậu tố khác trên DB cài mới; điều cần hiểu là cột và điều kiện.

FK dưới đây đều là quan hệ từ bảng con sang bảng cha. Nếu cột con NULL được phép, liên kết là tùy chọn. NO_ACTION nghĩa không tự xóa bản ghi con khi xóa cha. FK không tự chứng minh đúng vai trò, đúng chủ đơn hoặc đúng tổng tiền; xem trigger/SP tương ứng.

Tổng: **30 bảng, 316 cột, 52 CHECK, 65 FK, 59 DEFAULT, 63 index (30 PK + 33 ngoài PK)**. Các CHECK/FK tại thời điểm trích xuất đều được kiểm tra trạng thái bật/trusted; xem kết quả cuối phụ lục.

## 1. BaoGiaSoBo

Báo giá ban đầu của điều phối để khách duyệt trước khi giao thợ.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `ChanDoan` | NVARCHAR(2000) | Không | `—` |
| `PhiKiemTra` | DECIMAL(18,2) | Không | `—` |
| `TienCong` | DECIMAL(18,2) | Không | `—` |
| `TyLeHoaHong` | DECIMAL(5,2) | Không | `—` |
| `TongTien` | DECIMAL(18,2) | Có | `Tính tự động: (CONVERT([decimal](18,2),[PhiKiemTra]+[TienCong]))` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `NguoiTaoId` | INT | Không | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__BaoGiaSo__3214EC075ECAF9EB` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__BaoGiaSo__D159F4BFBA3D8F69` | UNIQUE constraint | DonHangId | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__BaoGiaSoB__PhiKi__70DDC3D8` | `([PhiKiemTra]>=(0))` | PhiKiemTra không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__BaoGiaSoB__TienC__71D1E811` | `([TienCong]>=(0))` | TienCong không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__BaoGiaSoB__Trang__74AE54BC` | `([TrangThai]='Rejected' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |
| `CK__BaoGiaSoB__TyLeH__72C60C4A` | `([TyLeHoaHong]>=(0) AND [TyLeHoaHong]<=(100))` | Tỷ lệ hoa hồng từ 0 đến 100, tính theo phần trăm tiền công. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__BaoGiaSoB__DonHa__6FE99F9F` | `BaoGiaSoBo.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__BaoGiaSoB__Nguoi__75A278F5` | `BaoGiaSoBo.NguoiTaoId` → `NguoiDung.Id` | NO_ACTION |
| `FK__BaoGiaSoB__Nguoi__76969D2E` | `BaoGiaSoBo.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |

## 2. CauHinh

Thông số nghiệp vụ dạng khóa/giá trị. Ứng dụng phải diễn giải và kiểm tra kiểu của từng giá trị.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `KhoaCauHinh` | VARCHAR(80) | Không | `—` |
| `GiaTri` | NVARCHAR(1000) | Không | `—` |
| `NhanHienThi` | NVARCHAR(200) | Không | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__CauHinh__1D212520F2B4114A` | PRIMARY KEY | KhoaCauHinh | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 3. ChiTietDeXuatVatTu

Từng dòng vật tư, số lượng, đơn giá, thành tiền tính tự động và thời hạn bảo hành.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `BaoGiaId` | INT | Không | `—` |
| `Ten` | NVARCHAR(200) | Không | `—` |
| `SoLuong` | DECIMAL(10,2) | Không | `—` |
| `DonViTinh` | NVARCHAR(30) | Không | `—` |
| `DonGia` | DECIMAL(18,2) | Không | `—` |
| `ThanhTien` | DECIMAL(18,2) | Có | `Tính tự động: (CONVERT([decimal](18,2),round([SoLuong]*[DonGia],(2))))` |
| `SoThangBaoHanh` | INT | Không | `((0))` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__ChiTietD__3214EC07FDB40874` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__ChiTietDe__DonGi__10566F31` | `([DonGia]>=(0) AND [DonGia]<=(100000000))` | Đơn giá từ 0 đến 100.000.000. |
| `CK__ChiTietDe__SoLuo__0F624AF8` | `([SoLuong]>(0) AND [SoLuong]<=(999.99))` | Số lượng lớn hơn 0, tối đa 999,99; không cho vật tư có số lượng âm hoặc bằng 0. |
| `CK__ChiTietDe__SoTha__123EB7A3` | `([SoThangBaoHanh]>=(0) AND [SoThangBaoHanh]<=(60))` | Bảo hành từ 0 đến 60 tháng; 0 nghĩa không có thời hạn bảo hành theo cột này. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__ChiTietDe__BaoGi__0E6E26BF` | `ChiTietDeXuatVatTu.BaoGiaId` → `DeXuatVatTu.Id` | NO_ACTION |

## 4. ChongLapYeuCau

Lưu kết quả của một yêu cầu theo người gọi, đường dẫn và khóa; phục vụ retry không tạo nghiệp vụ hai lần.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `NguoiThucHienId` | INT | Không | `—` |
| `DuongDan` | VARCHAR(160) | Không | `—` |
| `KhoaYeuCau` | VARCHAR(50) | Không | `—` |
| `MaBamDuLieu` | CHAR(64) | Không | `—` |
| `KetQuaJSON` | NVARCHAR(MAX) | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK_ChongLapYeuCau` | PRIMARY KEY | NguoiThucHienId, DuongDan, KhoaYeuCau | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__ChongLapY__KetQu__05A3D694` | `(isjson([KetQuaJSON])=(1))` | Chuỗi có cú pháp JSON hợp lệ; không thay cho kiểm schema/nội dung nghiệp vụ. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__ChongLapY__Nguoi__04AFB25B` | `ChongLapYeuCau.NguoiThucHienId` → `NguoiDung.Id` | NO_ACTION |

## 5. DanhGia

Điểm và nhận xét của khách sau khi đủ điều kiện hoàn thành/thanh toán.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `KhachHangId` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `DiemDanhGia` | INT | Không | `—` |
| `NhanXet` | NVARCHAR(1500) | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_DanhGia_KyThuatVien` | Index truy vấn | KyThuatVienId, DiemDanhGia (INCLUDE) | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__DanhGia__3214EC07E802863A` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__DanhGia__D159F4BF8DCD38DF` | UNIQUE constraint | DonHangId | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DanhGia__DiemDan__57DD0BE4` | `([DiemDanhGia]>=(1) AND [DiemDanhGia]<=(5))` | Điểm đánh giá nguyên trong khoảng 1–5; điều kiện được đánh giá do trigger kiểm thêm. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__DanhGia__DonHang__55009F39` | `DanhGia.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__DanhGia__KhachHa__55F4C372` | `DanhGia.KhachHangId` → `NguoiDung.Id` | NO_ACTION |
| `FK__DanhGia__KyThuat__56E8E7AB` | `DanhGia.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |

## 6. DeXuatChinhSach

Đề xuất chính sách cho giám đốc; quyết định duyệt chưa đồng nghĩa tự áp dụng giá mới vào danh mục.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `MaDeXuat` | VARCHAR(20) | Không | `—` |
| `TieuDe` | NVARCHAR(250) | Không | `—` |
| `BoPhan` | NVARCHAR(120) | Không | `—` |
| `NgayGui` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NhomDichVu` | NVARCHAR(120) | Không | `—` |
| `ChietKhauHienTai` | DECIMAL(5,2) | Có | `—` |
| `ChietKhauDeXuat` | DECIMAL(5,2) | Có | `—` |
| `MucThuongHienTai` | NVARCHAR(50) | Có | `—` |
| `MucThuongDeXuat` | NVARCHAR(50) | Có | `—` |
| `TacDong` | NVARCHAR(2000) | Không | `—` |
| `LyDo` | NVARCHAR(2000) | Không | `—` |
| `TrangThai` | VARCHAR(20) | Không | `('Pending')` |
| `YKienGiamDoc` | NVARCHAR(2000) | Có | `—` |
| `NgayHieuLuc` | VARCHAR(20) | Có | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__DeXuatCh__3214EC07023ACCB9` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__DeXuatCh__222447643D524163` | UNIQUE constraint | MaDeXuat | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DeXuatChi__Trang__345EC57D` | `([TrangThai]='Rejected' OR [TrangThai]='RevisionRequested' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `RevisionRequested`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__DeXuatChi__Nguoi__3552E9B6` | `DeXuatChinhSach.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |

## 7. DeXuatVatTu

Đầu phiếu vật tư theo đơn và lần sửa đổi; có trạng thái duyệt và bản đang áp dụng.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `LanSuaDoi` | INT | Không | `—` |
| `DangApDung` | BIT | Không | `((1))` |
| `GhiChu` | NVARCHAR(1000) | Có | `—` |
| `TongTien` | DECIMAL(18,2) | Không | `((0))` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `NguoiTaoId` | INT | Không | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__DeXuatVa__3214EC071F8156CF` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__DeXuatVa__E436D77CFBAED0BE` | UNIQUE constraint | DonHangId, LanSuaDoi | Không trùng tổ hợp khóa. |
| `UX_VatTu_DangApDung` | UNIQUE index | DonHangId | ([DangApDung]=(1)) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DeXuatVat__TongT__06CD04F7` | `([TongTien]>=(0))` | TongTien không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__DeXuatVat__Trang__08B54D69` | `([TrangThai]='Rejected' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__DeXuatVat__DonHa__03F0984C` | `DeXuatVatTu.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__DeXuatVat__Nguoi__09A971A2` | `DeXuatVatTu.NguoiTaoId` → `NguoiDung.Id` | NO_ACTION |
| `FK__DeXuatVat__Nguoi__0A9D95DB` | `DeXuatVatTu.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |

## 8. DichVu

Danh mục dịch vụ, phí, tiền công, tỷ lệ hoa hồng và cờ còn hoạt động.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `Ten` | NVARCHAR(150) | Không | `—` |
| `MaNhom` | NVARCHAR(60) | Không | `—` |
| `MoTa` | NVARCHAR(1500) | Không | `—` |
| `PhiKiemTra` | DECIMAL(18,2) | Không | `—` |
| `TienCong` | DECIMAL(18,2) | Không | `—` |
| `TyLeHoaHong` | DECIMAL(5,2) | Không | `—` |
| `PhoBien` | BIT | Không | `((0))` |
| `DangHoatDong` | BIT | Không | `((1))` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__DichVu__3214EC07DBA4BAF9` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DichVu__PhiKiemT__5CD6CB2B` | `([PhiKiemTra]>=(0))` | PhiKiemTra không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__DichVu__TienCong__5DCAEF64` | `([TienCong]>=(0))` | TienCong không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__DichVu__TyLeHoaH__5EBF139D` | `([TyLeHoaHong]>=(0) AND [TyLeHoaHong]<=(100))` | Tỷ lệ hoa hồng từ 0 đến 100, tính theo phần trăm tiền công. |

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 9. DoiSoat

Kế toán xác nhận phần tiền/hoa hồng của khoản thanh toán và ghi sổ ví.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `ThanhToanId` | INT | Không | `—` |
| `TienCong` | DECIMAL(18,2) | Không | `—` |
| `TyLeHoaHong` | DECIMAL(5,2) | Không | `—` |
| `TienHoaHong` | DECIMAL(18,2) | Có | `Tính tự động: (CONVERT([decimal](18,2),round(([TienCong]*[TyLeHoaHong])/(100),(2))))` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `NguoiXacNhanId` | INT | Có | `—` |
| `NgayXacNhan` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_DoiSoat_TrangThai` | Index truy vấn | TrangThai, KyThuatVienId, TienHoaHong (INCLUDE), ThanhToanId (INCLUDE) | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__DoiSoat__3214EC073CB61019` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__DoiSoat__24A8D6E53C65CBE4` | UNIQUE constraint | ThanhToanId | Không trùng tổ hợp khóa. |
| `UQ__DoiSoat__D159F4BFF11E3BE6` | UNIQUE constraint | DonHangId | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DoiSoat__TienCon__3C34F16F` | `([TienCong]>=(0))` | TienCong không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__DoiSoat__TrangTh__3F115E1A` | `([TrangThai]='Confirmed' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Confirmed`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |
| `CK__DoiSoat__TyLeHoa__3D2915A8` | `([TyLeHoaHong]>=(0) AND [TyLeHoaHong]<=(100))` | Tỷ lệ hoa hồng từ 0 đến 100, tính theo phần trăm tiền công. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__DoiSoat__DonHang__395884C4` | `DoiSoat.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__DoiSoat__KyThuat__3A4CA8FD` | `DoiSoat.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |
| `FK__DoiSoat__NguoiXa__40058253` | `DoiSoat.NguoiXacNhanId` → `NguoiDung.Id` | NO_ACTION |
| `FK__DoiSoat__ThanhTo__3B40CD36` | `DoiSoat.ThanhToanId` → `ThanhToan.Id` | NO_ACTION |

## 10. DonHang

Thông tin khách đặt dịch vụ, trạng thái xử lý và ảnh chụp thông tin tại thời điểm đặt.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `KhachHangId` | INT | Không | `—` |
| `DichVuId` | INT | Không | `—` |
| `TenDichVu` | NVARCHAR(150) | Không | `—` |
| `NhomDichVu` | NVARCHAR(60) | Không | `—` |
| `TenLienHe` | NVARCHAR(120) | Không | `—` |
| `SoDienThoaiLienHe` | VARCHAR(15) | Không | `—` |
| `DiaChi` | NVARCHAR(500) | Không | `—` |
| `MoTa` | NVARCHAR(2000) | Không | `—` |
| `NgayHen` | DATETIME2 | Có | `—` |
| `TrangThai` | VARCHAR(30) | Không | `('ChoTiepNhan')` |
| `KyThuatVienDuocGiaoId` | INT | Có | `—` |
| `NgayKhoiHanh` | DATETIME2 | Có | `—` |
| `LyDoHuy` | NVARCHAR(1000) | Có | `—` |
| `PhiHuy` | DECIMAL(18,2) | Không | `((0))` |
| `TrangThaiThanhToanPhiHuy` | VARCHAR(10) | Không | `('Unpaid')` |
| `NgayHuy` | DATETIME2 | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayCapNhat` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |
| `PhiHuyTaiThoiDiemDat` | DECIMAL(18,2) | Không | `((50000))` |
| `PhuongThucThanhToan` | VARCHAR(10) | Không | `('COD')` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_DonHang_KhachHang` | Index truy vấn | KhachHangId, NgayTao | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `IX_DonHang_TrangThai` | Index truy vấn | TrangThai, NgayTao | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__DonHang__3214EC07DB6029B7` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__DonHang__PhiHuy__693CA210` | `([PhiHuy]>=(0))` | PhiHuy không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__DonHang__TrangTh__66603565` | `([TrangThai]='Huy' OR [TrangThai]='HoanThanh' OR [TrangThai]='ChoNghiemThu' OR [TrangThai]='DangXuLy' OR [TrangThai]='DaDenNoi' OR [TrangThai]='DangDiChuyen' OR [TrangThai]='DaTiepNhan' OR [TrangThai]='ChoNhan' OR [TrangThai]='ChoPhanCong' OR [TrangThai]='ChoDuyetSoBo' OR [TrangThai]='ChoTiepNhan')` | TrangThai chỉ nhận một trong các mã: `Huy`, `HoanThanh`, `ChoNghiemThu`, `DangXuLy`, `DaDenNoi`, `DangDiChuyen`, `DaTiepNhan`, `ChoNhan`, `ChoPhanCong`, `ChoDuyetSoBo`, `ChoTiepNhan`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |
| `CK_DonHang_PhiHuyTaiThoiDiemDat` | `([PhiHuyTaiThoiDiemDat]>=(0))` | PhiHuyTaiThoiDiemDat không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK_DonHang_PhuongThucThanhToan` | `([PhuongThucThanhToan]='BANK' OR [PhuongThucThanhToan]='COD')` | PhuongThucThanhToan chỉ nhận: `BANK`, `COD`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__DonHang__DichVuI__6477ECF3` | `DonHang.DichVuId` → `DichVu.Id` | NO_ACTION |
| `FK__DonHang__KhachHa__6383C8BA` | `DonHang.KhachHangId` → `NguoiDung.Id` | NO_ACTION |
| `FK__DonHang__KyThuat__6754599E` | `DonHang.KyThuatVienDuocGiaoId` → `KyThuatVien.Id` | NO_ACTION |

## 11. GhiChuDon

Ghi chú gắn với đơn, tách phạm vi khách thấy và nội bộ.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `NguoiVietId` | INT | Không | `—` |
| `NoiDung` | NVARCHAR(2000) | Không | `—` |
| `PhamViHienThi` | VARCHAR(10) | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__GhiChuDo__3214EC0776BA2F22` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__GhiChuDon__PhamV__65370702` | `([PhamViHienThi]='Internal' OR [PhamViHienThi]='Customer')` | PhamViHienThi chỉ nhận: `Internal`, `Customer`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__GhiChuDon__DonHa__634EBE90` | `GhiChuDon.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__GhiChuDon__Nguoi__6442E2C9` | `GhiChuDon.NguoiVietId` → `NguoiDung.Id` | NO_ACTION |

## 12. GiaoDichVi

Sổ các biến động tiền có dấu; không sửa/xóa qua DML thông thường; tham chiếu nghiệp vụ chống trùng.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `Loai` | VARCHAR(20) | Không | `—` |
| `SoTien` | DECIMAL(18,2) | Không | `—` |
| `LoaiThamChieu` | VARCHAR(20) | Không | `—` |
| `ThamChieuId` | INT | Không | `—` |
| `NguoiThucHienId` | INT | Có | `—` |
| `GhiChu` | NVARCHAR(500) | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_Vi_KyThuatVien_Ngay` | Index truy vấn | KyThuatVienId, NgayTao, SoTien (INCLUDE), Loai (INCLUDE), ThamChieuId (INCLUDE) | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__GiaoDich__3214EC07766F2912` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__GiaoDich__07F449C1C4B20CDF` | UNIQUE constraint | LoaiThamChieu, ThamChieuId | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__GiaoDichV__SoTie__4F47C5E3` | `([SoTien]<>(0))` | Tiền biến động khác 0. Có thể âm khi trừ ví; loại và dấu đúng nghiệp vụ còn do tầng gọi/SP kiểm. |
| `CK_Vi_Loai` | `([Loai]='SettlementCredit' OR [Loai]='Reversal' OR [Loai]='Commission' OR [Loai]='Withdrawal' OR [Loai]='Deposit' OR [Loai]='Opening')` | Loai chỉ nhận: `SettlementCredit`, `Reversal`, `Commission`, `Withdrawal`, `Deposit`, `Opening`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__GiaoDichV__KyThu__4D5F7D71` | `GiaoDichVi.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |
| `FK__GiaoDichV__Nguoi__503BEA1C` | `GiaoDichVi.NguoiThucHienId` → `NguoiDung.Id` | NO_ACTION |

## 13. HoSoKTV

Hồ sơ xin trở thành KTV và quyết định duyệt, giữ thông tin kinh nghiệm.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `NguoiDungId` | INT | Không | `—` |
| `NhomTayNghe` | NVARCHAR(60) | Không | `—` |
| `KhuVucPhucVu` | NVARCHAR(120) | Không | `—` |
| `KinhNghiem` | NVARCHAR(2000) | Không | `—` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |
| `HoSoJSON` | NVARCHAR(2000) | Có | `—` |
| `GiayToMatTruocId` | INT | Có | `—` |
| `GiayToMatSauId` | INT | Có | `—` |
| `SoGiayTo` | VARCHAR(12) | Có | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__HoSoKTV__3214EC079CFD8B11` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UX_HoSo_ChoDuyet` | UNIQUE index | NguoiDungId | ([TrangThai]='Pending') — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__HoSoKTV__TrangTh__7E02B4CC` | `([TrangThai]='Rejected' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__HoSoKTV__GiayToM__36470DEF` | `HoSoKTV.GiayToMatTruocId` → `TepDinhKem.Id` | NO_ACTION |
| `FK__HoSoKTV__GiayToM__373B3228` | `HoSoKTV.GiayToMatSauId` → `TepDinhKem.Id` | NO_ACTION |
| `FK__HoSoKTV__NguoiDu__7C1A6C5A` | `HoSoKTV.NguoiDungId` → `NguoiDung.Id` | NO_ACTION |
| `FK__HoSoKTV__NguoiDu__7EF6D905` | `HoSoKTV.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |

## 14. KyThuatVien

Thông tin chuyên môn, khu vực, mức sẵn sàng, vị trí và số dư tổng hợp của KTV.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `NhomTayNghe` | NVARCHAR(60) | Không | `—` |
| `KhuVucPhucVu` | NVARCHAR(120) | Không | `—` |
| `TrangThaiSanSang` | VARCHAR(15) | Không | `('TamBan')` |
| `SoDu` | DECIMAL(18,2) | Không | `((0))` |
| `ViDo` | DECIMAL(10,7) | Có | `—` |
| `KinhDo` | DECIMAL(10,7) | Có | `—` |
| `DoChinhXacMet` | DECIMAL(12,2) | Có | `—` |
| `NgayCapNhatViTri` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__KyThuatV__3214EC07882A41AE` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__KyThuatVi__KinhD__59FA5E80` | `([KinhDo]>=(-180) AND [KinhDo]<=(180))` | Kinh độ từ −180 đến 180; cột cho NULL thì chưa có vị trí vẫn hợp lệ. |
| `CK__KyThuatVi__Trang__5629CD9C` | `([TrangThaiSanSang]='DangBan' OR [TrangThaiSanSang]='TamBan' OR [TrangThaiSanSang]='SanSang')` | TrangThaiSanSang chỉ nhận: `DangBan`, `TamBan`, `SanSang`. |
| `CK__KyThuatVie__SoDu__5812160E` | `([SoDu]>=(0))` | Số dư KTV không được âm; còn phối hợp trigger khi ghi sổ ví. |
| `CK__KyThuatVie__ViDo__59063A47` | `([ViDo]>=(-90) AND [ViDo]<=(90))` | Vĩ độ từ −90 đến 90; cột cho NULL thì chưa có vị trí vẫn hợp lệ. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__KyThuatVien__Id__5441852A` | `KyThuatVien.Id` → `NguoiDung.Id` | NO_ACTION |

## 15. LenhDieuPhoi

Lịch sử giao thợ, hạn phản hồi, trạng thái nhận/từ chối và cờ hoạt động.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `DangHoatDong` | BIT | Không | `((1))` |
| `NgayHetHan` | DATETIME2 | Không | `—` |
| `NguoiTaoId` | INT | Không | `—` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__LenhDieu__3214EC07FF77CEA4` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UX_PhanCong_DonHang` | UNIQUE index | DonHangId | ([DangHoatDong]=(1)) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |
| `UX_PhanCong_KyThuatVien` | UNIQUE index | KyThuatVienId | ([DangHoatDong]=(1)) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__LenhDieuP__Trang__7D439ABD` | `([TrangThai]='Expired' OR [TrangThai]='Rejected' OR [TrangThai]='Accepted' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Expired`, `Rejected`, `Accepted`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__LenhDieuP__DonHa__7A672E12` | `LenhDieuPhoi.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__LenhDieuP__KyThu__7B5B524B` | `LenhDieuPhoi.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |
| `FK__LenhDieuP__Nguoi__7F2BE32F` | `LenhDieuPhoi.NguoiTaoId` → `NguoiDung.Id` | NO_ACTION |

## 16. LichSuDonHang

Lịch sử chuyển trạng thái, người thực hiện và lý do do SP ghi.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `TrangThaiTruoc` | VARCHAR(30) | Có | `—` |
| `TrangThaiSau` | VARCHAR(30) | Không | `—` |
| `NguoiThucHienId` | INT | Có | `—` |
| `LyDo` | NVARCHAR(1000) | Không | `—` |
| `NgayPhatSinh` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__LichSuDo__3214EC07C165B8D2` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__LichSuDon__DonHa__5BAD9CC8` | `LichSuDonHang.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__LichSuDon__Nguoi__5CA1C101` | `LichSuDonHang.NguoiThucHienId` → `NguoiDung.Id` | NO_ACTION |

## 17. LichSuHoTro

Lịch sử xử lý từng phiếu hỗ trợ, ghi cùng giao dịch cập nhật phiếu.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `YeuCauHoTroId` | INT | Không | `—` |
| `NguoiThucHienId` | INT | Không | `—` |
| `TrangThai` | VARCHAR(15) | Không | `—` |
| `GhiChu` | NVARCHAR(2000) | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__LichSuHo__3214EC07EFD6A191` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__LichSuHoT__Nguoi__7849DB76` | `LichSuHoTro.NguoiThucHienId` → `NguoiDung.Id` | NO_ACTION |
| `FK__LichSuHoT__YeuCa__7755B73D` | `LichSuHoTro.YeuCauHoTroId` → `YeuCauHoTro.Id` | NO_ACTION |

## 18. NguoiDung

Thông tin tài khoản, vai trò ứng dụng, mật khẩu băm và trạng thái hoạt động.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `HoTen` | NVARCHAR(120) | Không | `—` |
| `SoDienThoai` | VARCHAR(15) | Không | `—` |
| `Email` | NVARCHAR(200) | Có | `—` |
| `CCCD` | VARCHAR(12) | Có | `—` |
| `MatKhauBam` | VARCHAR(100) | Không | `—` |
| `VaiTro` | VARCHAR(10) | Không | `—` |
| `DiaChiMacDinh` | NVARCHAR(500) | Có | `—` |
| `DangHoatDong` | BIT | Không | `((1))` |
| `PhienBanXacThuc` | INT | Không | `((0))` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |
| `DuongDanAnhDaiDien` | NVARCHAR(500) | Có | `—` |
| `KhoaDenNgay` | DATETIME2 | Có | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__NguoiDun__3214EC07E30E42A1` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__NguoiDun__0389B7BD5E4A36D1` | UNIQUE constraint | SoDienThoai | Không trùng tổ hợp khóa. |
| `UX_NguoiDung_CCCD` | UNIQUE index | CCCD | ([CCCD] IS NOT NULL) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |
| `UX_NguoiDung_Email` | UNIQUE index | Email | ([Email] IS NOT NULL) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__NguoiDung__VaiTr__4E88ABD4` | `([VaiTro]='GD' OR [VaiTro]='ADMIN' OR [VaiTro]='KT' OR [VaiTro]='CSKH' OR [VaiTro]='DPV' OR [VaiTro]='KTV' OR [VaiTro]='KH')` | VaiTro chỉ nhận: `GD`, `ADMIN`, `KT`, `CSKH`, `DPV`, `KTV`, `KH`. |

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 19. NhatKy

Nhật ký hành động phục vụ kiểm tra; không có FK cho mọi trường tham chiếu đa loại đối tượng.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `NguoiThucHienId` | INT | Có | `—` |
| `ThaoTac` | VARCHAR(80) | Không | `—` |
| `DoiTuong` | VARCHAR(60) | Không | `—` |
| `DoiTuongId` | INT | Có | `—` |
| `ChiTiet` | NVARCHAR(2000) | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__NhatKy__3214EC07FBA3ACB2` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 20. PhienBanCSDL

Các mốc phiên bản đã áp dụng; không phải ROWVERSION của dòng nghiệp vụ.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `PhienBan` | INT | Không | `—` |
| `NgayApDung` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__PhienBan__2423E788F8A37CC6` | PRIMARY KEY | PhienBan | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 21. PhieuNghiemThu

Kết quả thực hiện, cấu phần tiền, chữ ký khách/thợ và quyết định nghiệm thu.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `LanSuaDoi` | INT | Không | `—` |
| `NguyenNhan` | NVARCHAR(2000) | Không | `—` |
| `PhuongAnXuLy` | NVARCHAR(2000) | Không | `—` |
| `DeXuatVatTuId` | INT | Có | `—` |
| `PhiKiemTra` | DECIMAL(18,2) | Không | `—` |
| `TienCong` | DECIMAL(18,2) | Không | `—` |
| `TongTienVatTu` | DECIMAL(18,2) | Không | `—` |
| `TongTien` | DECIMAL(18,2) | Có | `Tính tự động: (CONVERT([decimal](18,2),([PhiKiemTra]+[TienCong])+[TongTienVatTu]))` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `NguoiDuyetId` | INT | Có | `—` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `ChuKyId` | INT | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |
| `PhuongThucThanhToanDeXuat` | VARCHAR(10) | Có | `—` |
| `ChuKyKTVId` | INT | Có | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__PhieuNgh__3214EC0733211AAF` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__PhieuNgh__E436D77C563C326F` | UNIQUE constraint | DonHangId, LanSuaDoi | Không trùng tổ hợp khóa. |
| `UX_NghiemThu_ChoDuyet` | UNIQUE index | DonHangId | ([TrangThai]='Pending') — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |
| `UX_NghiemThu_DaDuyet` | UNIQUE index | DonHangId | ([TrangThai]='Approved') — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__PhieuNghi__PhiKi__18EBB532` | `([PhiKiemTra]>=(0))` | PhiKiemTra không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__PhieuNghi__Phuon__382F5661` | `([PhuongThucThanhToanDeXuat]='BANK' OR [PhuongThucThanhToanDeXuat]='COD')` | PhuongThucThanhToanDeXuat chỉ nhận: `BANK`, `COD`. |
| `CK__PhieuNghi__TienC__19DFD96B` | `([TienCong]>=(0))` | TienCong không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__PhieuNghi__TongT__1AD3FDA4` | `([TongTienVatTu]>=(0))` | TongTienVatTu không được âm; miền kiểm tra chính xác nằm ở biểu thức bên trái. |
| `CK__PhieuNghi__Trang__1CBC4616` | `([TrangThai]='Rejected' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__PhieuNghi__DeXua__17F790F9` | `PhieuNghiemThu.DeXuatVatTuId` → `DeXuatVatTu.Id` | NO_ACTION |
| `FK__PhieuNghi__DonHa__160F4887` | `PhieuNghiemThu.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__PhieuNghi__KyThu__17036CC0` | `PhieuNghiemThu.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |
| `FK__PhieuNghi__Nguoi__1DB06A4F` | `PhieuNghiemThu.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |
| `FK_NghiemThu_ChuKy` | `PhieuNghiemThu.ChuKyId` → `TepDinhKem.Id` | NO_ACTION |
| `FK_NghiemThu_ChuKyKTV` | `PhieuNghiemThu.ChuKyKTVId` → `TepDinhKem.Id` | NO_ACTION |

## 22. TaiKhoanNhanTien

Danh mục tài khoản nhận chuyển khoản của HomeFix, quản trị viên quản lý.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `MaNganHang` | VARCHAR(20) | Không | `—` |
| `TenNganHang` | NVARCHAR(100) | Không | `—` |
| `SoTaiKhoan` | VARCHAR(30) | Không | `—` |
| `ChuTaiKhoan` | NVARCHAR(120) | Không | `—` |
| `DangHoatDong` | BIT | Không | `((1))` |
| `NguoiTaoId` | INT | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__TaiKhoan__3214EC07324DB198` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UX_TaiKhoanNganHang` | UNIQUE constraint | MaNganHang, SoTaiKhoan | Không trùng tổ hợp khóa. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__TaiKhoanN__Nguoi__1A9EF37A` | `TaiKhoanNhanTien.NguoiTaoId` → `NguoiDung.Id` | NO_ACTION |

## 23. TepDinhKem

Metadata của file lưu ngoài DB; chủ sở hữu, mục đích, MIME, dung lượng và khóa lưu trữ.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `ChuSoHuuId` | INT | Không | `—` |
| `DonHangId` | INT | Có | `—` |
| `NghiemThuId` | INT | Có | `—` |
| `MucDich` | VARCHAR(30) | Không | `—` |
| `KhoaLuuTru` | VARCHAR(100) | Không | `—` |
| `TenTepGoc` | NVARCHAR(255) | Không | `—` |
| `KieuMIME` | VARCHAR(50) | Không | `—` |
| `KichThuoc` | INT | Không | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__TepDinhK__3214EC076ED58F70` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__TepDinhK__5F5B829801FE9F93` | UNIQUE constraint | KhoaLuuTru | Không trùng tổ hợp khóa. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__TepDinhKe__KichT__2645B050` | `([KichThuoc]>(0) AND [KichThuoc]<=(5242880))` | Dung lượng tệp từ 1 đến 5.242.880 byte (5 MiB). Không tự kiểm nội dung file. |
| `CK_TepDinhKem_MucDich` | `([MucDich]='Avatar' OR [MucDich]='PaymentProof' OR [MucDich]='TechnicianDocument' OR [MucDich]='WalletProof' OR [MucDich]='TechnicianSignature' OR [MucDich]='CustomerSignature' OR [MucDich]='AcceptancePhoto' OR [MucDich]='MaterialEvidence' OR [MucDich]='OrderFault')` | MucDich chỉ nhận: `Avatar`, `PaymentProof`, `TechnicianDocument`, `WalletProof`, `TechnicianSignature`, `CustomerSignature`, `AcceptancePhoto`, `MaterialEvidence`, `OrderFault`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__TepDinhKe__ChuSo__22751F6C` | `TepDinhKem.ChuSoHuuId` → `NguoiDung.Id` | NO_ACTION |
| `FK__TepDinhKe__DonHa__236943A5` | `TepDinhKem.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__TepDinhKe__Nghie__245D67DE` | `TepDinhKem.NghiemThuId` → `PhieuNghiemThu.Id` | NO_ACTION |

## 24. ThanhToan

Khoản đã thanh toán; phương thức COD/BANK, nghiệm thu, số tiền và thông tin xác nhận.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `NghiemThuId` | INT | Không | `—` |
| `SoTien` | DECIMAL(18,2) | Không | `—` |
| `PhuongThuc` | VARCHAR(10) | Không | `('COD')` |
| `TrangThai` | VARCHAR(10) | Không | `('Paid')` |
| `NguoiThuTienId` | INT | Không | `—` |
| `NgayThanhToan` | DATETIME2 | Không | `(sysutcdatetime())` |
| `TaiKhoanNganHangId` | INT | Có | `—` |
| `MaThamChieuNganHang` | VARCHAR(100) | Có | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_ThanhToan_Ngay` | Index truy vấn | NgayThanhToan, SoTien (INCLUDE), PhuongThuc (INCLUDE), DonHangId (INCLUDE) | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__ThanhToa__3214EC070CB0826E` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UQ__ThanhToa__D159F4BFDA77A4B1` | UNIQUE constraint | DonHangId | Không trùng tổ hợp khóa. |
| `UQ__ThanhToa__DAE6D158CEAA98F6` | UNIQUE constraint | NghiemThuId | Không trùng tổ hợp khóa. |
| `UX_ThanhToan_MaThamChieuNganHang` | UNIQUE index | TaiKhoanNganHangId, MaThamChieuNganHang | ([MaThamChieuNganHang] IS NOT NULL) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__ThanhToan__SoTie__2EDAF651` | `([SoTien]>=(0))` | Số tiền không âm; việc khớp tổng nghiệm thu được trigger kiểm riêng. |
| `CK__ThanhToan__Trang__32AB8735` | `([TrangThai]='Paid')` | TrangThai chỉ nhận một trong các mã: `Paid`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |
| `CK_ThanhToan_PhuongThuc` | `([PhuongThuc]='BANK' OR [PhuongThuc]='COD')` | PhuongThuc chỉ nhận: `BANK`, `COD`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__ThanhToan__DonHa__2CF2ADDF` | `ThanhToan.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__ThanhToan__Nghie__2DE6D218` | `ThanhToan.NghiemThuId` → `PhieuNghiemThu.Id` | NO_ACTION |
| `FK__ThanhToan__TaiKh__1E6F845E` | `ThanhToan.TaiKhoanNganHangId` → `TaiKhoanNhanTien.Id` | NO_ACTION |
| `FK_ThanhToan_NguoiThuTien` | `ThanhToan.NguoiThuTienId` → `NguoiDung.Id` | NO_ACTION |

## 25. ThongBao

Thông báo trong ứng dụng, có thời điểm đọc; không phải hàng đợi email đã gửi.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `NguoiDungId` | INT | Không | `—` |
| `DonHangId` | INT | Có | `—` |
| `TieuDe` | NVARCHAR(200) | Không | `—` |
| `NoiDungThongBao` | NVARCHAR(1000) | Không | `—` |
| `NgayDoc` | DATETIME2 | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__ThongBao__3214EC079D414075` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__ThongBao__DonHan__69FBBC1F` | `ThongBao.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__ThongBao__NguoiD__690797E6` | `ThongBao.NguoiDungId` → `NguoiDung.Id` | NO_ACTION |

## 26. ViTriKhachHang

Vị trí khách gắn với đơn hàng, tọa độ, độ chính xác và thời gian cập nhật.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `DonHangId` | INT | Không | `—` |
| `ViDo` | DECIMAL(10,7) | Không | `—` |
| `KinhDo` | DECIMAL(10,7) | Không | `—` |
| `DoChinhXacMet` | DECIMAL(12,2) | Không | `—` |
| `NgayCapNhatViTri` | DATETIME2 | Không | `(sysutcdatetime())` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__ViTriKha__D159F4BE0969AE26` | PRIMARY KEY | DonHangId | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__ViTriKhac__DoChi__3DE82FB7` | `([DoChinhXacMet]>=(0) AND [DoChinhXacMet]<=(100000))` | Độ chính xác vị trí từ 0 đến 100.000 m. |
| `CK__ViTriKhac__KinhD__3CF40B7E` | `([KinhDo]>=(-180) AND [KinhDo]<=(180))` | Kinh độ từ −180 đến 180; cột cho NULL thì chưa có vị trí vẫn hợp lệ. |
| `CK__ViTriKhach__ViDo__3BFFE745` | `([ViDo]>=(-90) AND [ViDo]<=(90))` | Vĩ độ từ −90 đến 90; cột cho NULL thì chưa có vị trí vẫn hợp lệ. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__ViTriKhac__DonHa__3B0BC30C` | `ViTriKhachHang.DonHangId` → `DonHang.Id` | NO_ACTION |

## 27. XacThucOTP

Mã OTP băm, người nhận, mục đích, số lần thử, hết hạn và trạng thái sử dụng.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | UNIQUEIDENTIFIER | Không | `—` |
| `MucDich` | NVARCHAR(20) | Không | `—` |
| `KenhGui` | NVARCHAR(10) | Không | `—` |
| `DiaChiNhan` | NVARCHAR(200) | Không | `—` |
| `DuLieuRangBuoc` | NVARCHAR(64) | Không | `—` |
| `MaBamOTP` | NVARCHAR(64) | Không | `—` |
| `SoLanThu` | INT | Không | `((0))` |
| `SanSang` | BIT | Không | `((0))` |
| `DaSuDung` | BIT | Không | `((0))` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayHetHan` | DATETIME2 | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_XacThucOTP_DiaChiNhan` | Index truy vấn | DiaChiNhan, NgayTao | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__XacThucO__3214EC07E40B13FF` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

Bảng này không có CHECK trong metadata. NOT NULL, khóa, SP và backend vẫn có thể kiểm các điều kiện khác; không tự khẳng định mọi trường ở đây đã có CHECK.

### Khóa ngoại

Không có FK khai báo trong bảng này. Với trường tham chiếu mang nhiều loại đối tượng (như nhật ký), cần đọc logic ghi/kiểm tra ở tầng ứng dụng.

## 28. YeuCauHoTro

Phiếu khiếu nại/bảo hành và tình trạng xử lý hiện tại.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `KhachHangId` | INT | Không | `—` |
| `Loai` | VARCHAR(15) | Không | `—` |
| `MoTa` | NVARCHAR(2000) | Không | `—` |
| `TrangThai` | VARCHAR(15) | Không | `('Open')` |
| `NguoiDuocGiaoId` | INT | Có | `—` |
| `KetQuaXuLy` | NVARCHAR(2000) | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayCapNhat` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `IX_HoTro_TrangThai_Ngay` | Index truy vấn | TrangThai, NgayTao, DonHangId (INCLUDE), KhachHangId (INCLUDE), Loai (INCLUDE) | Hỗ trợ tìm/lọc/sắp xếp; không cấm dữ liệu trùng. |
| `PK__YeuCauHo__3214EC079E0F50C0` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__YeuCauHoT__Trang__719CDDE7` | `([TrangThai]='Rejected' OR [TrangThai]='Resolved' OR [TrangThai]='InProgress' OR [TrangThai]='Open')` | TrangThai chỉ nhận một trong các mã: `Rejected`, `Resolved`, `InProgress`, `Open`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |
| `CK__YeuCauHoTr__Loai__6FB49575` | `([Loai]='Warranty' OR [Loai]='Complaint')` | Loai chỉ nhận: `Warranty`, `Complaint`. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__YeuCauHoT__DonHa__6DCC4D03` | `YeuCauHoTro.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__YeuCauHoT__Khach__6EC0713C` | `YeuCauHoTro.KhachHangId` → `NguoiDung.Id` | NO_ACTION |
| `FK__YeuCauHoT__Nguoi__72910220` | `YeuCauHoTro.NguoiDuocGiaoId` → `NguoiDung.Id` | NO_ACTION |

## 29. YeuCauThanhToan

Luồng yêu cầu chuyển khoản/chứng từ trước khi tạo khoản ThanhToan chính thức.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `DonHangId` | INT | Không | `—` |
| `NghiemThuId` | INT | Không | `—` |
| `KhachHangId` | INT | Không | `—` |
| `TaiKhoanNganHangId` | INT | Không | `—` |
| `MaNganHang` | VARCHAR(20) | Không | `—` |
| `TenNganHang` | NVARCHAR(100) | Không | `—` |
| `SoTaiKhoan` | VARCHAR(30) | Không | `—` |
| `ChuTaiKhoan` | NVARCHAR(120) | Không | `—` |
| `SoTien` | DECIMAL(18,2) | Không | `—` |
| `NoiDungChuyenKhoan` | VARCHAR(60) | Có | `—` |
| `TrangThai` | VARCHAR(20) | Không | `('AwaitingTransfer')` |
| `DangHoatDong` | BIT | Không | `((1))` |
| `ChungTuId` | INT | Có | `—` |
| `MaThamChieuKhachHang` | NVARCHAR(100) | Có | `—` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `ThanhToanId` | INT | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `NgayGui` | DATETIME2 | Có | `—` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__YeuCauTh__3214EC070AD52137` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |
| `UX_ChuyenKhoan_ChungTu` | UNIQUE index | ChungTuId | ([ChungTuId] IS NOT NULL) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |
| `UX_ChuyenKhoan_DangHoatDong` | UNIQUE index | DonHangId | ([DangHoatDong]=(1)) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |
| `UX_ChuyenKhoan_NoiDung` | UNIQUE index | NoiDungChuyenKhoan | ([NoiDungChuyenKhoan] IS NOT NULL) — Chỉ những dòng thỏa bộ lọc tham gia index; duy nhất trong tập này. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__YeuCauTha__SoTie__251C81ED` | `([SoTien]>(0))` | Số tiền yêu cầu phải lớn hơn 0. |
| `CK__YeuCauTha__Trang__2704CA5F` | `([TrangThai]='Cancelled' OR [TrangThai]='Rejected' OR [TrangThai]='Confirmed' OR [TrangThai]='PendingReview' OR [TrangThai]='AwaitingTransfer')` | TrangThai chỉ nhận một trong các mã: `Cancelled`, `Rejected`, `Confirmed`, `PendingReview`, `AwaitingTransfer`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__YeuCauTha__Chung__28ED12D1` | `YeuCauThanhToan.ChungTuId` → `TepDinhKem.Id` | NO_ACTION |
| `FK__YeuCauTha__DonHa__214BF109` | `YeuCauThanhToan.DonHangId` → `DonHang.Id` | NO_ACTION |
| `FK__YeuCauTha__Khach__2334397B` | `YeuCauThanhToan.KhachHangId` → `NguoiDung.Id` | NO_ACTION |
| `FK__YeuCauTha__Nghie__22401542` | `YeuCauThanhToan.NghiemThuId` → `PhieuNghiemThu.Id` | NO_ACTION |
| `FK__YeuCauTha__Nguoi__29E1370A` | `YeuCauThanhToan.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |
| `FK__YeuCauTha__TaiKh__24285DB4` | `YeuCauThanhToan.TaiKhoanNganHangId` → `TaiKhoanNhanTien.Id` | NO_ACTION |
| `FK__YeuCauTha__Thanh__2AD55B43` | `YeuCauThanhToan.ThanhToanId` → `ThanhToan.Id` | NO_ACTION |

## 30. YeuCauVi

Đề nghị nạp/rút của KTV; tiền yêu cầu luôn dương, khi rút được đổi thành số âm trong sổ ví.

### Cột và giá trị mặc định

| Cột | Kiểu | NULL? | Mặc định hoặc công thức |
|---|---|---|---|
| `Id` | INT | Không | `—` |
| `KyThuatVienId` | INT | Không | `—` |
| `Loai` | VARCHAR(15) | Không | `—` |
| `SoTien` | DECIMAL(18,2) | Không | `—` |
| `GhiChu` | NVARCHAR(1000) | Không | `—` |
| `ChungTuId` | INT | Có | `—` |
| `TrangThai` | VARCHAR(10) | Không | `('Pending')` |
| `LyDo` | NVARCHAR(1000) | Có | `—` |
| `NguoiDuyetId` | INT | Có | `—` |
| `NgayDuyet` | DATETIME2 | Có | `—` |
| `NgayTao` | DATETIME2 | Không | `(sysutcdatetime())` |
| `PhienBan` | ROWVERSION (8 byte) | Không | `—` |

### Khóa, tính duy nhất và index

| Tên | Loại | Cột | Bộ lọc / giải thích |
|---|---|---|---|
| `PK__YeuCauVi__3214EC07DFDC7899` | PRIMARY KEY | Id | Duy nhất và không NULL; nhận diện bản ghi. |

### CHECK

| Tên | Điều kiện SQL cuối cùng | Giải thích |
|---|---|---|
| `CK__YeuCauVi__Loai__43D61337` | `([Loai]='Withdrawal' OR [Loai]='Deposit')` | Loai chỉ nhận: `Withdrawal`, `Deposit`. |
| `CK__YeuCauVi__SoTien__44CA3770` | `([SoTien]>(0))` | Số tiền yêu cầu phải lớn hơn 0. |
| `CK__YeuCauVi__TrangT__47A6A41B` | `([TrangThai]='Cancelled' OR [TrangThai]='Rejected' OR [TrangThai]='Approved' OR [TrangThai]='Pending')` | TrangThai chỉ nhận một trong các mã: `Cancelled`, `Rejected`, `Approved`, `Pending`. Kiểm miền giá trị, không tự kiểm trình tự chuyển giữa các trạng thái. |

### Khóa ngoại

| Tên | Cột con → cột cha | Khi xóa cha |
|---|---|---|
| `FK__YeuCauVi__ChungT__45BE5BA9` | `YeuCauVi.ChungTuId` → `TepDinhKem.Id` | NO_ACTION |
| `FK__YeuCauVi__KyThua__42E1EEFE` | `YeuCauVi.KyThuatVienId` → `KyThuatVien.Id` | NO_ACTION |
| `FK__YeuCauVi__NguoiD__489AC854` | `YeuCauVi.NguoiDuyetId` → `NguoiDung.Id` | NO_ACTION |

## Kiểm tra trạng thái ràng buộc

| Loại | Số lượng bị tắt | Số lượng không trusted |
|---|---:|---:|
| checks | 0 | 0 |
| fks | 0 | 0 |

`is_disabled=0`: ràng buộc đang bật. `is_not_trusted=0`: SQL Server tin cậy ràng buộc đối với dữ liệu hiện có. Không dùng NOCHECK để làm dữ liệu sai nhập được trong buổi demo.
