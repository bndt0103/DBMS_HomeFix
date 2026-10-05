# Quy ước tên và đọc mã SQL

Tên bảng, cột, tham số và đối tượng nghiệp vụ dùng tiếng Việt không dấu, viết hoa chữ cái đầu mỗi từ (PascalCase). Ví dụ: `NgayTao`, `NguoiThucHienId`, `TrangThai`, `PhienBanDuKien`. Giữ các viết tắt quen thuộc như `Id`, `CCCD`, `OTP`, `JSON`, `MIME`, `KTV`, `COD`; tiền tố `PK`, `FK`, `CK`, `DF`, `UX`, `IX`, `sp`, `fn`, `vw`, `trg` biểu thị loại đối tượng SQL.

Từ khóa, kiểu dữ liệu, hàm và danh mục hệ thống SQL Server như `SELECT`, `INT`, `SYSUTCDATETIME()`, `sys.columns.name` giữ đúng cú pháp của SQL Server. Các mã trạng thái và mã lỗi là giá trị dữ liệu mà ứng dụng sử dụng, không phải tên cột; chúng được giữ ổn định để không làm thay đổi quy tắc xử lý.

## Cách trình bày

- `WHERE` đặt cùng dòng với điều kiện ngắn. Điều kiện dài chia theo từng nhóm `AND`/`OR`.
- `INSERT INTO` đặt cùng dòng với tên bảng và danh sách cột; `VALUES` đặt cùng dòng với bộ giá trị.
- Mỗi khối `BEGIN…END`, `TRY…CATCH` và giao dịch được thụt lề bốn khoảng trắng.
- Mỗi cột khi tạo bảng nằm trên một dòng; giữ rõ kiểu dữ liệu, NULL/NOT NULL và ràng buộc.
- `GO` ngăn cách các lô lệnh, đặc biệt giữa các định nghĩa thủ tục, hàm và trigger.

```sql
UPDATE dbo.YeuCauVi
SET TrangThai = @QuyetDinh,
    LyDo = @LyDo,
    NguoiDuyetId = @NguoiThucHienId,
    NgayDuyet = SYSUTCDATETIME()
WHERE Id = @YeuCauId;
```

## CSDL và ứng dụng

Bản tiếng Việt dùng CSDL mẫu `HomeFix_DBMS_Nhom08_TiengViet`. Không chạy các script mới trên lược đồ tiếng Anh cũ. Chạy `CAI_DAT.bat` hoặc làm theo README để khởi tạo bản mới. CSDL cũ được giữ lại; đây không phải script di chuyển dữ liệu cũ.

Truy vấn trong mã máy chủ đã dùng tên cột mới. `SRC/backend/src/sql-names.js` ánh xạ tên tham số và tên cột trả về với hợp đồng JSON hiện có của web. Hàm `qRaw` dùng khi xuất CSDL để giữ nguyên tên cột SQL. Cách này không tạo bảng hoặc cột tiếng Anh dự phòng trong CSDL.

## Đối chiếu tên cột và kết quả khung nhìn

| Tên trước | Tên trong CSDL hiện tại |
|---|---|
| `acceptanceId` | `NghiemThuId` |
| `accountHolder` | `ChuTaiKhoan` |
| `accountNumber` | `SoTaiKhoan` |
| `accuracyMeters` | `DoChinhXacMet` |
| `action` | `ThaoTac` |
| `actorId` | `NguoiThucHienId` |
| `address` | `DiaChi` |
| `amount` | `SoTien` |
| `appliedAt` | `NgayApDung` |
| `assignedTechnicianId` | `KyThuatVienDuocGiaoId` |
| `assignedTo` | `NguoiDuocGiaoId` |
| `attempts` | `SoLanThu` |
| `authorId` | `NguoiVietId` |
| `availability` | `TrangThaiSanSang` |
| `avatarUrl` | `DuongDanAnhDaiDien` |
| `backDocumentId` | `GiayToMatSauId` |
| `balance` | `SoDu` |
| `bankAccountId` | `TaiKhoanNganHangId` |
| `bankCode` | `MaNganHang` |
| `bankName` | `TenNganHang` |
| `bankReference` | `MaThamChieuNganHang` |
| `binding` | `DuLieuRangBuoc` |
| `body` | `NoiDungThongBao` |
| `cancelReason` | `LyDoHuy` |
| `cancellationFee` | `PhiHuy` |
| `cancellationFeeSnapshot` | `PhiHuyTaiThoiDiemDat` |
| `cancellationPaymentStatus` | `TrangThaiThanhToanPhiHuy` |
| `cancelledAt` | `NgayHuy` |
| `cause` | `NguyenNhan` |
| `cccd` | `CCCD` |
| `channel` | `KenhGui` |
| `codeHash` | `MaBamOTP` |
| `comment` | `NhanXet` |
| `commissionAmount` | `TienHoaHong` |
| `commissionRatePercent` | `TyLeHoaHong` |
| `confirmedAt` | `NgayXacNhan` |
| `confirmedBy` | `NguoiXacNhanId` |
| `consumed` | `DaSuDung` |
| `contactName` | `TenLienHe` |
| `contactPhone` | `SoDienThoaiLienHe` |
| `createdAt` | `NgayTao` |
| `createdBy` | `NguoiTaoId` |
| `currentBonus` | `MucThuongHienTai` |
| `currentDiscount` | `ChietKhauHienTai` |
| `customerId` | `KhachHangId` |
| `customerReference` | `MaThamChieuKhachHang` |
| `decidedAt` | `NgayDuyet` |
| `decidedBy` | `NguoiDuyetId` |
| `defaultAddress` | `DiaChiMacDinh` |
| `departedAt` | `NgayKhoiHanh` |
| `department` | `BoPhan` |
| `description` | `MoTa` |
| `destination` | `DiaChiNhan` |
| `detail` | `ChiTiet` |
| `diagnosis` | `ChanDoan` |
| `directorNote` | `YKienGiamDoc` |
| `effectiveAt` | `NgayHieuLuc` |
| `email` | `Email` |
| `entity` | `DoiTuong` |
| `entityId` | `DoiTuongId` |
| `experience` | `KinhNghiem` |
| `expiresAt` | `NgayHetHan` |
| `fromStatus` | `TrangThaiTruoc` |
| `frontDocumentId` | `GiayToMatTruocId` |
| `fullName` | `HoTen` |
| `groupCode` | `MaNhom` |
| `happenedAt` | `NgayPhatSinh` |
| `id` | `Id` |
| `identityNumber` | `SoGiayTo` |
| `impact` | `TacDong` |
| `inspectionFee` | `PhiKiemTra` |
| `isActive` | `DangHoatDong` |
| `isCurrent` | `DangApDung` |
| `isPopular` | `PhoBien` |
| `key` | `KhoaCauHinh` |
| `label` | `NhanHienThi` |
| `laborFee` | `TienCong` |
| `latitude` | `ViDo` |
| `lineTotal` | `ThanhTien` |
| `lockedUntil` | `KhoaDenNgay` |
| `longitude` | `KinhDo` |
| `materialQuoteId` | `DeXuatVatTuId` |
| `materialTotal` | `TongTienVatTu` |
| `method` | `PhuongThuc` |
| `mimeType` | `KieuMIME` |
| `name` | `Ten` |
| `note` | `GhiChu` |
| `orderId` | `DonHangId` |
| `originalName` | `TenTepGoc` |
| `ownerId` | `ChuSoHuuId` |
| `paidAt` | `NgayThanhToan` |
| `passwordHash` | `MatKhauBam` |
| `payloadHash` | `MaBamDuLieu` |
| `paymentId` | `ThanhToanId` |
| `paymentMethod` | `PhuongThucThanhToan` |
| `phone` | `SoDienThoai` |
| `positionUpdatedAt` | `NgayCapNhatViTri` |
| `profileJson` | `HoSoJSON` |
| `proofId` | `ChungTuId` |
| `proposalCode` | `MaDeXuat` |
| `proposedBonus` | `MucThuongDeXuat` |
| `proposedDiscount` | `ChietKhauDeXuat` |
| `proposedPaymentMethod` | `PhuongThucThanhToanDeXuat` |
| `purpose` | `MucDich` |
| `quantity` | `SoLuong` |
| `quoteId` | `BaoGiaId` |
| `rating` | `DiemDanhGia` |
| `readAt` | `NgayDoc` |
| `ready` | `SanSang` |
| `reason` | `LyDo` |
| `receivedBy` | `NguoiThuTienId` |
| `referenceId` | `ThamChieuId` |
| `referenceType` | `LoaiThamChieu` |
| `requestKey` | `KhoaYeuCau` |
| `resolution` | `KetQuaXuLy` |
| `resultJson` | `KetQuaJSON` |
| `revision` | `LanSuaDoi` |
| `role` | `VaiTro` |
| `route` | `DuongDan` |
| `scheduledAt` | `NgayHen` |
| `serviceArea` | `KhuVucPhucVu` |
| `serviceGroup` | `NhomDichVu` |
| `serviceId` | `DichVuId` |
| `serviceName` | `TenDichVu` |
| `signatureId` | `ChuKyId` |
| `size` | `KichThuoc` |
| `skillGroup` | `NhomTayNghe` |
| `solution` | `PhuongAnXuLy` |
| `status` | `TrangThai` |
| `storageKey` | `KhoaLuuTru` |
| `submittedAt` | `NgayGui` |
| `technicianId` | `KyThuatVienId` |
| `text` | `NoiDung` |
| `ticketId` | `YeuCauHoTroId` |
| `title` | `TieuDe` |
| `toStatus` | `TrangThaiSau` |
| `tokenVersion` | `PhienBanXacThuc` |
| `total` | `TongTien` |
| `transferContent` | `NoiDungChuyenKhoan` |
| `type` | `Loai` |
| `unit` | `DonViTinh` |
| `unitPrice` | `DonGia` |
| `updatedAt` | `NgayCapNhat` |
| `userId` | `NguoiDungId` |
| `value` | `GiaTri` |
| `version` | `PhienBan` |
| `visibility` | `PhamViHienThi` |
| `warrantyMonths` | `SoThangBaoHanh` |
| `reviews` | `SoDanhGia` |
| `averageRating` | `DiemTrungBinh` |
| `materialId` | `VatTuId` |
| `totalOrders` | `TongSoDon` |
| `completedOrders` | `SoDonHoanThanh` |
| `cancelledOrders` | `SoDonHuy` |
| `customerName` | `TenKhachHang` |
| `technicianName` | `TenKyThuatVien` |
| `paymentStatus` | `TrangThaiThanhToan` |
| `businessDate` | `NgayNghiepVu` |
| `paidOrders` | `SoDonDaThanhToan` |
| `gmv` | `TongGiaTriGiaoDich` |
| `commissionRevenue` | `DoanhThuHoaHong` |
| `cachedBalance` | `SoDuLuuSan` |
| `difference` | `ChenhLech` |
| `responseDueAt` | `HanPhanHoi` |
| `estimatedTotal` | `TongTienDuKien` |

## Đối chiếu đối tượng

| Tên trước | Tên hiện tại |
|---|---|
| `SchemaVersion` | `PhienBanCSDL` |
| `AuthOtp` | `XacThucOTP` |
| `Idempotency` | `ChongLapYeuCau` |
| `trg_DonHang_Audit` | `trg_DonHang_GhiNhatKy` |
| `UX_User_Email` | `UX_NguoiDung_Email` |
| `UX_User_CCCD` | `UX_NguoiDung_CCCD` |
| `IX_Order_Customer` | `IX_DonHang_KhachHang` |
| `IX_Order_Status` | `IX_DonHang_TrangThai` |
| `UX_Assignment_Order` | `UX_PhanCong_DonHang` |
| `UX_Assignment_Technician` | `UX_PhanCong_KyThuatVien` |
| `UX_Material_Current` | `UX_VatTu_DangApDung` |
| `UX_Acceptance_Pending` | `UX_NghiemThu_ChoDuyet` |
| `UX_Acceptance_Approved` | `UX_NghiemThu_DaDuyet` |
| `FK_Acceptance_Signature` | `FK_NghiemThu_ChuKy` |
| `UX_Application_Pending` | `UX_HoSo_ChoDuyet` |
| `PK_Idempotency` | `PK_ChongLapYeuCau` |
| `DF_Order_CancellationSnapshot` | `DF_DonHang_PhiHuyTaiThoiDiemDat` |
| `CK_Order_CancellationSnapshot` | `CK_DonHang_PhiHuyTaiThoiDiemDat` |
| `IX_AuthOtp_Destination` | `IX_XacThucOTP_DiaChiNhan` |
| `DF_Order_PaymentMethod` | `DF_DonHang_PhuongThucThanhToan` |
| `CK_Order_PaymentMethod` | `CK_DonHang_PhuongThucThanhToan` |
| `UX_BankAccount` | `UX_TaiKhoanNganHang` |
| `CK_Payment_Method` | `CK_ThanhToan_PhuongThuc` |
| `FK_Payment_Receiver` | `FK_ThanhToan_NguoiThuTien` |
| `UX_Payment_BankReference` | `UX_ThanhToan_MaThamChieuNganHang` |
| `UX_Transfer_Active` | `UX_ChuyenKhoan_DangHoatDong` |
| `UX_Transfer_Content` | `UX_ChuyenKhoan_NoiDung` |
| `UX_Transfer_Proof` | `UX_ChuyenKhoan_ChungTu` |
| `CK_Upload_Purpose` | `CK_TepDinhKem_MucDich` |
| `CK_Wallet_Type` | `CK_Vi_Loai` |
| `DF_Service_IsPopular` | `DF_DichVu_PhoBien` |
| `IX_Wallet_Technician_Date` | `IX_Vi_KyThuatVien_Ngay` |
| `IX_Settlement_Status` | `IX_DoiSoat_TrangThai` |
| `IX_Support_Status_Date` | `IX_HoTro_TrangThai_Ngay` |
| `IX_Payment_Date` | `IX_ThanhToan_Ngay` |
| `IX_Review_Technician` | `IX_DanhGia_KyThuatVien` |
