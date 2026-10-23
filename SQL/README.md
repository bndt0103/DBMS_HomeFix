# HomeFix: SQL Server và thực hành

Thành viên cài máy mới xem [hướng dẫn cài đặt](CAI_DAT_THANH_VIEN.md). Trên máy nhóm trưởng, kết nối **`MSI\SQLEXPRESS`**, chọn database **`HomeFix_DBMS_Clean_20261022`**. Kiểm tra trước khi chạy:

```sql
SELECT @@SERVERNAME AS MayChu, DB_NAME() AS TenCSDL;
```

## 1. Các file cần mở

| File | Nội dung |
|---|---|
| `CSDL_HomeFix.sql` | Bộ cài vào database mới, không ghi đè tên đã tồn tại |
| `seed_data.sql` | 7 tài khoản, 5 danh mục/5 dịch vụ, cấu hình và ngân hàng mẫu; không có giao dịch |
| `du_lieu_mau.sql` | Bổ sung khách, thợ, 20 dịch vụ và 10 đơn qua các thủ tục; chạy lặp không tạo trùng |
| `truy_van_mau.sql` | Chọn từng khối để demo view, function, SP, transaction, savepoint, lỗi ràng buộc, trigger, index và quyền |
| `sao_luu_mau.sql` | Sao lưu FULL COPY_ONLY và VERIFYONLY vào thư mục backup của SQL Server |

Dữ liệu minh họa chỉ là dữ liệu giả phục vụ học tập. Script không tạo file ảnh; metadata ảnh còn lại trong SQL không đồng nghĩa có file ảnh thật. Khi thao tác web cần ảnh/chữ ký mới, tải tệp lên từ form tương ứng.

## 2. Các module SQL

| Module | Thành phần |
|---|---|
| `00_schema.sql` | 28 bảng, PK, FK, UNIQUE, CHECK, DEFAULT, cột tính toán và ROWVERSION |
| `01_index.sql` | Index hỗ trợ truy vấn, UNIQUE lọc chống phân công trùng/bảng kê đang áp dụng trùng |
| `02_function.sql` | 2 hàm scalar và 4 hàm trả bảng |
| `03_view.sql` | 34 view phục vụ đọc dữ liệu |
| `04_sp.sql` | 19 thủ tục tài khoản, danh mục, cấu hình, tệp và tiện ích |
| `05_transaction.sql` | 30 thủ tục nghiệp vụ và báo cáo |
| `06_trigger.sql` | 7 trigger bảo vệ trạng thái, chứng từ, vật tư, chữ ký và đánh giá |
| `07_security.sql` | 7 role nghiệp vụ và ngữ cảnh xác thực nội bộ |
| `08_seed.sql` | Seed sạch, giống `seed_data.sql` |
| `09_data_migration.sql` | Chuyển cấu trúc cũ sang hiện tại, giữ dữ liệu |
| `10_backup_recovery.sql` | Thủ tục sao lưu và ví dụ phục hồi |

`CSDL_HomeFix.sql` được sinh từ các module bằng `npm.cmd run sql:build` trong `SRC`. Không sửa riêng bộ cài tổng. Tổng cộng 50 SP: 48 SP ghi có giao dịch, 1 SP báo cáo chỉ đọc và 1 SP sao lưu. BACKUP không được đặt trong transaction người dùng.

## 3. Luồng vật tư hiện tại

1. KTV được phân công cập nhật đơn đến `DangXuLy`.
2. KTV trao đổi trực tiếp với khách về vật tư và chi phí.
3. KTV chọn **Kê khai vật tư**, nhập tên, số lượng, đơn giá và thời gian bảo hành. Không có bước gửi khách duyệt riêng.
4. `sp_LuuBangKeVatTu` kiểm tra đúng thợ, trạng thái đơn và phiên bản; tạo bảng kê áp dụng mới. Khi sửa, nhập lại **toàn bộ danh sách**, không chỉ các dòng phát sinh. Phiên bản cũ vẫn được giữ để đối chiếu.
5. `sp_TaoPhieuNghiemThu` cộng vật tư của bảng kê áp dụng vào phí kiểm tra và tiền công. Khách kiểm tra tổng tiền, ký xác nhận **phiếu nghiệm thu cuối cùng**.

Các bảng và đối tượng chính:

```sql
SELECT Id, DonHangId, LanSuaDoi, DangApDung, NgayTao FROM dbo.vw_BangKeVatTu;
SELECT BangKeVatTuId, Ten, SoLuong, DonGia, ThanhTien, SoThangBaoHanh FROM dbo.vw_ChiTietVatTu;
SELECT DonHangId, BangKeVatTuId, PhiKiemTra, TienCong, TongTienVatTu, TongTien FROM dbo.vw_PhieuNghiemThu;
```

`ThanhTien = SoLuong * DonGia` là cột tính toán. Số lượng phải dương, đơn giá không âm; thủ tục còn giới hạn số dòng, tên và mức giá. Tổng tiền do SQL tính, không lấy tổng tùy ý từ trình duyệt.

`tr_ChiTietVatTu_KhoaNghiemThu` chặn INSERT/UPDATE/DELETE các dòng thuộc bảng kê đã được dùng trong bất kỳ phiếu nghiệm thu nào. Nếu cần sửa vật tư sau khi khách yêu cầu xử lý lại, phải tạo bảng kê phiên bản mới; phiếu cũ vẫn giữ được chi tiết và tổng tiền. Bảng kê không còn cột trạng thái duyệt vật tư, không còn SP/API khách duyệt vật tư.

Khối **13–14** trong `truy_van_mau.sql` cho xem đơn giá, tổng hợp nghiệm thu và chạy thử SP trong giao dịch ngoài rồi rollback.

## 4. Thanh toán và đối soát

Thanh toán và đối soát là hai bước khác nhau: thanh toán ghi nhận khách đã trả; đối soát ghi phần tiền thuộc hệ thống/KTV vào sổ ví.

| Phương thức | Ghi nhận thanh toán | Kế toán đối soát |
|---|---|---|
| COD | KTV xác nhận đã nhận tiền mặt | Trừ hoa hồng từ ví KTV; không cộng lại tiền mặt |
| BANK | Khách gửi chứng từ; KT xác nhận đủ tiền, đúng mã giao dịch | Cộng khoản thanh toán trừ hoa hồng vào ví KTV |

Kế toán mở **Đối soát thanh toán** → chọn **Đối soát** ở đúng dòng → xem mã đơn, số tiền và hoa hồng → **Đồng ý đối soát**. Đóng hộp thoại không ghi dữ liệu. Không chuyển sang trang duyệt ví. Trang **Duyệt ví KTV** chỉ xử lý nạp/rút.

`sp_DoiSoatCOD` xử lý cả COD/BANK. Thủ tục khóa dòng, so phiên bản, cập nhật đối soát, số dư và sổ cái cùng transaction. Gửi lặp hoặc dùng phiên bản cũ bị từ chối; một tham chiếu nghiệp vụ chỉ ghi sổ một lần.

```sql
SELECT Id, DonHangId, TienCong, TyLeHoaHong, TienHoaHong, TrangThai FROM dbo.vw_DoiSoat;
SELECT Id, HoTen, SoDu, SoDuSoCai, ChenhLech FROM dbo.vw_ViKyThuatVien;
```

`ChenhLech` luôn phải bằng 0. Không tự UPDATE số dư hay chỉnh/xóa `GiaoDichVi` để chuẩn bị demo.

## 5. Cách giải thích các thành phần khi vấn đáp

- **PK/FK:** định danh và bảo đảm dòng tham chiếu tồn tại. FK không tự biết người được tham chiếu có vai trò KH hay KTV; SP kiểm tra thêm vai trò và quyền sở hữu.
- **CHECK/UNIQUE:** CHECK kiểm tra miền giá trị; UNIQUE chặn trùng điện thoại, chứng từ thanh toán, đánh giá. UNIQUE lọc chỉ xét các dòng còn hiệu lực, nên vẫn giữ lịch sử cũ.
- **DEFAULT:** cấp giá trị khi INSERT bỏ qua cột; không tự cập nhật ngày sửa khi UPDATE.
- **ROWVERSION:** 8 byte tự đổi khi UPDATE, không phải ngày giờ. Form gửi lại phiên bản đã đọc; SQL từ chối phiên bản cũ để tránh ghi đè.
- **View/TVF:** đóng gói phần đọc; view dùng như bảng trong FROM, TVF nhận được tham số. `fn_SoDuVi`, `fn_DiemDanhGia`, `fn_ThongKeDon`, `fn_HanBaoHanh` trả bảng; `fn_HoaHong`, `fn_TongTienDonHang` trả một giá trị.
- **Transaction:** gộp nhiều thay đổi thành một đơn vị cùng thành công hoặc cùng hủy. `UPDLOCK, HOLDLOCK` giữ khóa để trạng thái, phiên bản và số dư không bị thay đổi giữa lúc kiểm tra và ghi.
- **Savepoint:** SP tự BEGIN/COMMIT nếu chưa có transaction. Nếu caller đã mở, SP đặt SAVE TRANSACTION và không COMMIT thay caller. Trong CATCH, `XACT_STATE() = 1` mới rollback về savepoint được; `-1` cần chủ giao dịch rollback toàn bộ.
- **Trigger:** chạy tự động khi bảng thay đổi. `inserted`/`deleted` có thể có nhiều dòng, nên kiểm tra bằng EXISTS/JOIN. SP điều phối luồng, trigger chặn vi phạm khi dữ liệu bị ghi trực tiếp.
- **Index:** giảm lượng đọc cho truy vấn phù hợp nhưng tốn dung lượng và chi phí ghi. Dữ liệu ít có thể được optimizer chọn Scan; bật Ctrl+M và STATISTICS IO để quan sát.

Tỷ lệ hoa hồng lưu theo phần trăm: `15` là 15% tiền công. Tiền dùng DECIMAL; thời gian lưu UTC và hiển thị theo múi giờ Việt Nam.

## 6. Quyền của bảy bộ phận

Mật khẩu tài khoản học tập là **`123456`**. Mật khẩu trong CSDL được băm bcrypt.

| SĐT | Vai trò | Chức năng |
|---|---|---|
| 0900000001 | KH | Đặt đơn, duyệt sơ bộ, nghiệm thu, thanh toán, đánh giá và hỗ trợ |
| 0900000002 | KTV | Nhận việc, tiến độ, kê khai vật tư, nghiệm thu, COD và ví |
| 0900000003 | DPV | Báo giá sơ bộ, phân công, xem hiệu suất thợ |
| 0900000004 | CSKH | Xử lý hỗ trợ, xem chất lượng dịch vụ |
| 0900000005 | KT | Xác minh BANK, đối soát, duyệt nạp/rút và báo cáo tài chính |
| 0900000006 | GD | Báo cáo tổng hợp, chất lượng, hiệu suất và tài chính |
| 0900000007 | ADMIN | Tài khoản, vai trò, khóa/mở khóa, hồ sơ thợ, danh mục, cấu hình |

JWT kiểm tra vai trò ở API; truy vấn đơn/tệp được kiểm tra chủ sở hữu. Mỗi request chạy dưới user SQL `hf_*`, với Id đã xác thực trong SESSION_CONTEXT. SP so khớp actor với phiên, không tin Id do khách tùy ý gửi.

Bảy role `HomeFix_KH/KTV/DPV/CSKH/KT/GD/ADMIN` chỉ được EXECUTE các SP liên quan và SELECT view/TVF tương ứng, bị DENY truy cập bảng trực tiếp và cột hash. `HomeFix_UngDung` là ngữ cảnh xác thực nội bộ trước khi có JWT, không phải bộ phận thứ tám. Ownership chain cho phép View/SP cùng chủ dbo đọc/ghi bảng bên trong.

Khối **11** trong file truy vấn mẫu dùng `EXECUTE AS USER`, cho đọc view nhưng bắt lỗi 229/230 khi đọc bảng mật khẩu, sau đó luôn `REVERT`.

## 7. Cài mới hoặc nâng cấp

Cài mới trong SSMS: mở `CSDL_HomeFix.sql`, bật **Query → SQLCMD Mode**, chọn tên database mới tại biến `TenCSDL`, chạy toàn bộ. Bộ cài từ chối tên đã tồn tại. Không chạy lại schema hoặc seed lên database đang dùng.

Khi nâng cấp, sao lưu trước và dừng ứng dụng; trong `SRC` chạy:

```powershell
npm.cmd run sql:build
npm.cmd run db:upgrade
npm.cmd run build
npm.cmd start
```

Nâng cấp đọc `DB_NAME` trong `.env`; không chạy seed, không reset dữ liệu. Module 09 chuyển tên bảng/cột vật tư, bỏ trạng thái duyệt và SP/View cũ. Bảng kê từng bị từ chối được đặt không áp dụng; các Id, số tiền nghiệm thu và sổ ví cũ được giữ.

## 8. Sao lưu và xử lý lỗi

Chạy từng khối của `sao_luu_mau.sql` bằng tài khoản DBA. File `.bak` nằm trên máy SQL Server; tài khoản dịch vụ SQL Server cần quyền ghi thư mục đó. `VERIFYONLY` kiểm tra bản sao; cần RESTORE sang **tên khác**, MOVE tệp dữ liệu/log sang đường dẫn mới và CHECKDB để kiểm chứng phục hồi thực tế. Không ghi đè database đang demo.

| Lỗi | Cách xử lý |
|---|---|
| 547 | Đọc tên CHECK/FK; kiểm tra giá, số lượng và Id tham chiếu |
| 2601/2627 | Trùng giá trị UNIQUE; kiểm tra điện thoại/chứng từ/phiên bản hiện hành |
| 51003 hoặc HTTP 403 | Sai vai trò, chủ đơn hoặc người được phân công |
| 51004 hoặc HTTP 404 | Dòng/tệp không tồn tại |
| 51009 hoặc HTTP 409 | Sai trạng thái, phiên bản cũ, vật tư đã nghiệm thu hoặc số dư không đủ; tải lại và kiểm tra dữ liệu |
| 229/230 | Ngữ cảnh SQL không có quyền đối tượng/cột |

Các khối gây lỗi minh họa đều có TRY/CATCH và rollback. Rollback không thu hồi số IDENTITY đã cấp, nên Id nhảy số là bình thường. Trước khi kết thúc kiểm tra `SELECT @@TRANCOUNT;` phải bằng 0.


## 9. Hỗ trợ khách hàng và phí hủy đơn

Đặt đơn chỉ tạo `DonHang` và lịch sử; không tự tạo `YeuCauHoTro`. Bộ dữ liệu minh họa cũng không chèn sẵn phiếu hỗ trợ. Khách chọn đơn ngay trong mục Hỗ trợ, nhập nội dung và bấm Gửi yêu cầu mới phát sinh phiếu.

Luồng trạng thái: `Open` (chờ tiếp nhận) → `InProgress` (CSKH đang xử lý) → `Resolved` (đã giải quyết). CSKH có thể chuyển phiếu đang mở sang `Rejected` nhưng phải ghi lý do. Khách chỉ gửi thông tin, xem phản hồi; không được sửa trạng thái. CSKH phải tiếp nhận trước khi trả lời và chỉ nhân viên phụ trách được kết thúc phiếu. Phiếu đã kết thúc không nhận tin nhắn mới.

`sp_XuLyHoTro` cập nhật phiếu, lưu một dòng `TraoDoiHoTro` có trạng thái và thời gian thực tế, đồng thời tạo thông báo cho khách trong cùng transaction. `sp_ThemTraoDoiHoTro` kiểm tra chủ phiếu và người phụ trách trước khi lưu. Không dùng ngày tạo phiếu để giả làm thời điểm phản hồi. Khách đang chờ CSKH không bị đếm là việc khách phải xử lý.

| Thời điểm khách hủy | Cách xử lý |
|---|---|
| Chờ tiếp nhận/báo giá/phân công/nhận ca hoặc KTV đã nhận nhưng chưa di chuyển | Hủy miễn phí |
| KTV đang di chuyển hoặc đã đến nơi, chưa bắt đầu sửa | Khách xác nhận phí 60.000đ trước khi hủy; chỉ chuyển khoản cho HomeFix |
| KTV đã bắt đầu sửa/nghiệm thu/hoàn thành | Không hủy trực tiếp; gửi yêu cầu CSKH |

Phí mặc định lưu tại `CauHinh.Khoa = 'PhiHuyDon'`. `sp_ChuyenTrangThaiDon` tự lấy phí và lưu snapshot vào `DonHang.PhiHuyDon`; không lấy giá tùy ý từ HTTP. Tham số `DongYPhiHuy`, `PhiHuyDuKien` chỉ kiểm tra khách đã đồng ý đúng mức phí. Hủy đồng thời với KTV bắt đầu di chuyển dùng khóa và ROWVERSION; giao dịch nào dùng dữ liệu cũ bị từ chối.

Không thêm bảng nghiệp vụ. `ThanhToan` và `YeuCauThanhToan` có `LoaiThanhToan` phân biệt `DichVu`/`PhiHuyDon`. Phí hủy không cần nghiệm thu nên `NghiemThuId` để NULL; CHECK bắt buộc phí hủy chỉ có BANK, còn thanh toán dịch vụ phải tham chiếu nghiệm thu. UNIQUE lọc trên `NghiemThuId IS NOT NULL` giữ quy tắc một nghiệm thu chỉ thanh toán một lần nhưng cho phép nhiều đơn hủy độc lập.

Khách gửi chứng từ → KT xác minh đúng 60.000đ và mã giao dịch → tạo đối soát → KT xác nhận đối soát → cộng **đủ 60.000đ** vào ví KTV, hoa hồng bằng 0. Đơn vẫn `Huy`, không chuyển thành `HoanThanh`. Việc KT xác minh phí cũ không thay trạng thái sẵn sàng của KTV đang làm đơn khác. SP và UNIQUE của sổ cái ngăn cộng ví hai lần.

Khối 15–16 trong `truy_van_mau.sql` dùng để xem phí hủy, loại khoản thu và lịch sử hỗ trợ. Các khoản phí hủy được tách khỏi GMV dịch vụ ở báo cáo tổng quan và vẫn xuất hiện trong dòng tiền chuyển khoản.

## 10. Thực hành SQL theo phân công 4 thành viên

Bắt đầu từ [Hướng dẫn học và demo](thuc_hanh_nhom/HUONG_DAN.md), [bảng phân công](thuc_hanh_nhom/PHAN_CONG.md) và [kết quả rà soát](thuc_hanh_nhom/KET_QUA_RASOAT.md).

| Thành viên | File thực hành |
|---|---|
| Nguyễn Quốc Việt – 24110381 | [Thiết kế, ràng buộc, seed và index](thuc_hanh_nhom/01_NguyenQuocViet.sql) |
| Đỗ Anh Tuấn – 24110369 | [View, function và báo cáo](thuc_hanh_nhom/02_DoAnhTuan.sql) |
| Bùi Nguyễn Duy Trung – 24110363 | [SP, transaction và nghiệp vụ đơn](thuc_hanh_nhom/03_BuiNguyenDuyTrung.sql) |
| Lê Tấn Tài – 24110319 | [Trigger, quyền, đối soát và migration](thuc_hanh_nhom/04_LeTanTai.sql); [backup/restore](thuc_hanh_nhom/04b_SaoLuuPhucHoi.sql) |

Bảng đúng định dạng cuối rubric đã có trong repo: [Word](thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.docx), [PDF](thuc_hanh_nhom/BangPhanCong_SQL_Nhom08.pdf). Máy nhóm trưởng còn giữ bản bàn giao tại `D:\Subject_K5\DBMS\ProjectCK\TaiLieuVanDap_Nhom08`.

Mỗi người chạy phần đầu file, sau đó chọn trọn từng khối theo mã bài. Các bài thử ghi/quyền có rollback; bài index dùng bảng tạm, bài FULL/DIFF/LOG dùng bản sao riêng và tự dọn database thực hành. Không chạy lại bộ cài để chuẩn bị demo trên CSDL đang có dữ liệu.
