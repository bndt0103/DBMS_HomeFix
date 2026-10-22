import { sql, pool, close } from "../src/db.js";

const categories = [
  { ma: "DienLanh", ten: "Điện lạnh" },
  { ma: "DienGiaDung", ten: "Điện gia dụng" },
  { ma: "DienNuoc", ten: "Điện nước" },
  { ma: "VeSinh", ten: "Vệ sinh & bảo trì" },
];

const serviceCatalog = [
  ['Sửa máy lạnh', 'DienLanh', 'Kiểm tra và sửa máy lạnh không lạnh, chảy nước.', 50000, 300000, 15, 1],
  ['Vệ sinh máy lạnh', 'DienLanh', 'Bảo dưỡng, vệ sinh dàn lạnh và dàn nóng.', 30000, 180000, 15, 1],
  ['Sửa tủ lạnh', 'DienLanh', 'Khắc phục lỗi tủ lạnh không đông đá, hở ron.', 50000, 300000, 15, 1],
  ['Sửa máy giặt', 'DienGiaDung', 'Sửa máy giặt mất nguồn, báo lỗi, không vắt.', 50000, 250000, 15, 1],
  ['Sửa điện nước', 'DienNuoc', 'Sửa rò rỉ, đường ống và thiết bị điện gia đình.', 50000, 200000, 15, 0],
  ['Vệ sinh thiết bị', 'VeSinh', 'Làm sạch và bảo trì định kỳ thiết bị gia đình.', 30000, 150000, 15, 0],
  ['Sửa điện tại nhà', 'DienNuoc', 'Khắc phục sự cố chập điện, mất điện, nhảy aptomat.', 50000, 200000, 15, 1],
  ['Sửa điện 3 pha', 'DienNuoc', 'Khắc phục sự cố tủ điện 3 pha, cân pha công nghiệp.', 100000, 500000, 15, 0],
  ['Lắp quạt trần', 'DienNuoc', 'Thi công và lắp ráp các loại quạt trần dân dụng.', 50000, 250000, 15, 1],
  ['Sửa quạt trần', 'DienNuoc', 'Sửa chữa quạt trần không quay, kêu to, hỏng tụ.', 30000, 150000, 15, 0],
  ['Thi công đèn trong nhà', 'DienNuoc', 'Lắp đặt, đi dây và thiết kế hệ thống chiếu sáng.', 50000, 300000, 15, 0],
  ['Sửa ống nước tại nhà', 'DienNuoc', 'Khắc phục các sự cố bục vỡ, rò rỉ đường ống nước.', 50000, 150000, 15, 1],
  ['Sửa máy bơm nước', 'DienNuoc', 'Kiểm tra và sửa chữa máy bơm nước không lên nước, kêu to.', 50000, 250000, 15, 1],
  ['Lắp phao nước tự động', 'DienNuoc', 'Lắp đặt phao điện, phao cơ ngắt nước tự động.', 30000, 150000, 15, 0],
  ['Thông nghẹt bồn rửa chén', 'DienNuoc', 'Xử lý triệt để bồn rửa chén bị tắc nghẽn nước.', 50000, 250000, 15, 1],
  ['Sửa vòi rửa bát', 'DienNuoc', 'Khắc phục vòi rửa bát bị rò rỉ nước, gãy vòi.', 30000, 100000, 15, 0],
  ['Thay vòi hoa sen', 'DienNuoc', 'Lắp mới, thay thế bộ vòi hoa sen nhà tắm.', 30000, 150000, 15, 0],
  ['Sửa bồn cầu', 'DienNuoc', 'Sửa bồn cầu rỉ nước, hỏng phao, nút nhấn không được.', 50000, 200000, 15, 1],
  ['Dò tìm rò rỉ nước ngầm', 'DienNuoc', 'Sử dụng máy siêu âm tìm điểm vỡ ống nước ngầm âm tường/nền.', 100000, 800000, 15, 0],
  ['Bơm gas máy lạnh', 'DienLanh', 'Kiểm tra và châm thêm gas cho máy lạnh.', 50000, 350000, 15, 0],
  ['Vệ sinh máy lạnh âm trần', 'DienLanh', 'Bảo dưỡng máy lạnh cassette, máy lạnh âm trần ống gió.', 100000, 450000, 15, 0],
  ['Sửa tủ mát, tủ đông', 'DienLanh', 'Bơm gas, thay lốc tủ đông công nghiệp/nhà hàng.', 100000, 500000, 15, 0],
  ['Vệ sinh máy giặt lồng ngang', 'DienGiaDung', 'Tháo lồng và vệ sinh máy giặt cửa trước.', 50000, 400000, 15, 0],
  ['Vệ sinh máy giặt lồng đứng', 'DienGiaDung', 'Tháo lồng và vệ sinh máy giặt cửa trên.', 50000, 250000, 15, 0],
  ['Sửa lò vi sóng', 'DienGiaDung', 'Sửa lò vi sóng mất nguồn, không nóng.', 50000, 200000, 15, 0],
  ['Sửa máy nước nóng năng lượng mặt trời', 'DienGiaDung', 'Khắc phục rò rỉ, thay ống thủy tinh năng lượng mặt trời.', 100000, 400000, 15, 0],
  ['Sửa máy nước nóng', 'DienGiaDung', 'Sửa máy nước nóng trực tiếp/gián tiếp không nóng.', 50000, 250000, 15, 0],
  ['Vệ sinh bồn nước inox', 'VeSinh', 'Súc rửa cặn bẩn bồn nước inox trên cao.', 50000, 350000, 15, 0],
  ['Vệ sinh bồn nước ngầm', 'VeSinh', 'Hút cặn và khử khuẩn bể nước ngầm bằng máy.', 100000, 600000, 15, 0],
  ['Vệ sinh sofa tại nhà', 'VeSinh', 'Giặt sofa nỉ, sofa da bằng công nghệ hơi nước.', 50000, 450000, 15, 0],
  ['Rút hầm cầu', 'VeSinh', 'Hút hầm cầu, nạo vét hố ga, xử lý mùi hôi.', 150000, 800000, 15, 0],
];

async function updateCatalog() {
  const dbPool = await pool();

  console.log("Cập nhật danh mục dịch vụ theo HomeFix reference...");
  for (const c of categories) {
    const existing = await dbPool.request()
      .input("Ma", sql.VarChar(30), c.ma)
      .query("SELECT Id FROM dbo.DanhMucDichVu WHERE Ma = @Ma");
    if (!existing.recordset.length) {
      // Check if Ten exists
      const byName = await dbPool.request()
        .input("Ten", sql.NVarChar(100), c.ten)
        .query("SELECT Id FROM dbo.DanhMucDichVu WHERE Ten = @Ten");
      if (byName.recordset.length) {
        await dbPool.request()
          .input("Id", sql.Int, byName.recordset[0].Id)
          .input("Ma", sql.VarChar(30), c.ma)
          .query("UPDATE dbo.DanhMucDichVu SET Ma = @Ma, DangHoatDong = 1 WHERE Id = @Id");
      } else {
        await dbPool.request()
          .input("Ten", sql.NVarChar(100), c.ten)
          .input("Ma", sql.VarChar(30), c.ma)
          .query("INSERT INTO dbo.DanhMucDichVu (Ten, Ma, DangHoatDong) VALUES (@Ten, @Ma, 1)");
      }
    } else {
      await dbPool.request()
        .input("Id", sql.Int, existing.recordset[0].Id)
        .input("Ten", sql.NVarChar(100), c.ten)
        .query("UPDATE dbo.DanhMucDichVu SET Ten = @Ten, DangHoatDong = 1 WHERE Id = @Id");
    }
  }

  // Disable old categories that are not in the new 4 categories
  await dbPool.request().query(
    "UPDATE dbo.DanhMucDichVu SET DangHoatDong = 0 WHERE Ma NOT IN ('DienLanh', 'DienGiaDung', 'DienNuoc', 'VeSinh')"
  );

  // Disable old services that are not in the new list
  const newNames = serviceCatalog.map(s => s[0].replace(/'/g, "''"));
  const namesSql = newNames.map(n => `N'${n}'`).join(", ");
  await dbPool.request().query(
    `UPDATE dbo.DichVu SET DangHoatDong = 0 WHERE Ten NOT IN (${namesSql})`
  );

  console.log("Cập nhật 31 dịch vụ...");
  for (const item of serviceCatalog) {
    const [ten, maNhom, moTa, phiKt, tienCong, hoaHong] = item;
    const cat = await dbPool.request()
      .input("Ma", sql.VarChar(30), maNhom)
      .query("SELECT Id FROM dbo.DanhMucDichVu WHERE Ma = @Ma");
    const danhMucId = cat.recordset[0]?.Id;
    if (!danhMucId) {
      console.warn("Không tìm thấy danh mục cho", maNhom);
      continue;
    }

    const svc = await dbPool.request()
      .input("Ten", sql.NVarChar(180), ten)
      .query("SELECT Id FROM dbo.DichVu WHERE Ten = @Ten");
    if (svc.recordset.length) {
      await dbPool.request()
        .input("Id", sql.Int, svc.recordset[0].Id)
        .input("DanhMucId", sql.Int, danhMucId)
        .input("MoTa", sql.NVarChar(1000), moTa)
        .input("PhiKiemTra", sql.Decimal(18, 2), phiKt)
        .input("TienCong", sql.Decimal(18, 2), tienCong)
        .input("TyLeHoaHong", sql.Decimal(5, 2), hoaHong)
        .query(`
          UPDATE dbo.DichVu
          SET DanhMucId = @DanhMucId, MoTa = @MoTa, PhiKiemTra = @PhiKiemTra,
              TienCong = @TienCong, TyLeHoaHong = @TyLeHoaHong, DangHoatDong = 1
          WHERE Id = @Id
        `);
    } else {
      await dbPool.request()
        .input("DanhMucId", sql.Int, danhMucId)
        .input("Ten", sql.NVarChar(180), ten)
        .input("MoTa", sql.NVarChar(1000), moTa)
        .input("PhiKiemTra", sql.Decimal(18, 2), phiKt)
        .input("TienCong", sql.Decimal(18, 2), tienCong)
        .input("TyLeHoaHong", sql.Decimal(5, 2), hoaHong)
        .query(`
          INSERT INTO dbo.DichVu (DanhMucId, Ten, MoTa, PhiKiemTra, TienCong, TyLeHoaHong, DangHoatDong)
          VALUES (@DanhMucId, @Ten, @MoTa, @PhiKiemTra, @TienCong, @TyLeHoaHong, 1)
        `);
    }
  }

  const allActiveCats = await dbPool.request().query("SELECT Ten, Ma FROM dbo.DanhMucDichVu WHERE DangHoatDong = 1");
  const allActiveSvcs = await dbPool.request().query("SELECT Ten, DanhMucId, PhiKiemTra, TienCong FROM dbo.DichVu WHERE DangHoatDong = 1");
  console.log(`Hoàn thành: ${allActiveCats.recordset.length} danh mục đang hoạt động, ${allActiveSvcs.recordset.length} dịch vụ đang hoạt động.`);

  await close();
}

updateCatalog().catch(err => {
  console.error("Lỗi:", err);
  process.exit(1);
});
