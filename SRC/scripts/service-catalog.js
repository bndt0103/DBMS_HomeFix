import fs from 'node:fs/promises';
import { q, one } from '../backend/src/db.js';
import { serviceCatalog } from '../database/service-catalog.js';
export async function applyServiceCatalog(t) {
  const hadColumn =
    (await one("SELECT COL_LENGTH('dbo.DichVu','PhoBien') AS length", {}, t)).length !== null;
  const source = await fs.readFile(
    new URL('../database/006_service_catalog.sql', import.meta.url),
    'utf8',
  );
  for (const batch of source.split(/^GO\s*$/m).filter((part) => part.trim())) {
    await q(batch, {}, t);
  }
  if (await one('SELECT PhienBan FROM dbo.PhienBanCSDL WHERE PhienBan=6', {}, t))
    return { alreadyApplied: true, inserted: 0 };
  let inserted = 0;
  for (const [name, groupCode, description, inspectionFee, laborFee, isPopular] of serviceCatalog) {
    const existing = await one('SELECT Id FROM dbo.DichVu WHERE Ten=@Ten', { name }, t);
    if (existing) {
      if (!hadColumn)
        await q(
          'UPDATE dbo.DichVu SET PhoBien=@popular WHERE Id=@Id',
          { id: existing.id, popular: !!isPopular },
          t,
        );
    } else {
      await q(
        'INSERT dbo.DichVu(Ten,MaNhom,MoTa,PhiKiemTra,TienCong,TyLeHoaHong,PhoBien) VALUES(@Ten,@MaNhom,@MoTa,@PhiKiemTra,@TienCong,15,@PhoBien)',
        { name, groupCode, description, inspectionFee, laborFee, isPopular: !!isPopular },
        t,
      );
      inserted++;
    }
  }
  await q('INSERT dbo.PhienBanCSDL(PhienBan) VALUES(6)', {}, t);
  return { alreadyApplied: false, inserted };
}
