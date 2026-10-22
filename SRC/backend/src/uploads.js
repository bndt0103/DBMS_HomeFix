import { Router } from "express";
import multer from "multer";
import sharp from "sharp";
import fs from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { config } from "./config.js";
import { exec, first } from "./db.js";
import { ok, wrap, fail, orderFor, positiveId } from "./common.js";
export const uploadsRouter = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
});
uploadsRouter.post(
  "/uploads",
  upload.single("file"),
  wrap(async (req, res) => {
    if (!req.file) fail(400, "Vui lòng chọn một ảnh.");
    let data;
    try {
      data = await sharp(req.file.buffer, { limitInputPixels: 25000000 })
        .rotate()
        .png()
        .toBuffer();
    } catch {
      fail(400, "Ảnh không hợp lệ. Chấp nhận ảnh PNG/JPEG/WebP.");
    }
    if (data.length > 5 * 1024 * 1024) fail(400, "Ảnh sau xử lý vượt 5 MiB.");
    const DonHangId = req.body.DonHangId
      ? positiveId(req.body.DonHangId)
      : null;
    if (DonHangId) await orderFor(req.user, DonHangId);
    const key = randomUUID() + ".png";
    await fs.mkdir(config.uploads, { recursive: true });
    const destination = path.join(config.uploads, key);
    await fs.writeFile(destination, data);
    try {
      const rows = await exec("sp_LuuTepDinhKem", {
        NguoiThucHienId: req.user.Id,
        DonHangId,
        MucDich: req.body.MucDich,
        KhoaLuuTru: key,
        TenTepGoc: path.basename(req.file.originalname).slice(0, 255),
        KieuMIME: "image/png",
        KichThuoc: data.length,
      });
      ok(res, rows[0]);
    } catch (error) {
      await fs.unlink(destination).catch(() => {});
      throw error;
    }
  }),
);
uploadsRouter.get(
  "/uploads/:id",
  wrap(async (req, res) => {
    const file = await first("vw_TepDinhKem", {
      Id: positiveId(req.params.id),
    });
    if (!file) fail(404, "Không có tệp đính kèm.");
    if (file.ChuSoHuuId !== req.user.Id) {
      if (file.DonHangId) await orderFor(req.user, file.DonHangId);
      else if (!["KT", "ADMIN"].includes(req.user.VaiTro))
        fail(403, "Bạn không có quyền xem tệp.");
    }
    if (!/^[a-f0-9-]+\.png$/i.test(file.KhoaLuuTru))
      fail(400, "Khóa tệp không hợp lệ.");
    res.type(file.KieuMIME).set("Cache-Control", "private, no-store");
    res.sendFile(path.join(config.uploads, file.KhoaLuuTru));
  }),
);
