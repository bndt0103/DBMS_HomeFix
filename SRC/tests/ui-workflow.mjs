import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import sharp from 'sharp';
const base =
    process.env.TEST_BASE_URL?.replace(/\/api$/, '') ||
    process.env.HOMEFIX_TEST_URL ||
    'http://localhost:3000',
  out = 'test-results/screenshots',
  steps = [],
  faults = [];
let orderId;
fs.mkdirSync(out, { recursive: true });
await sharp({ create: { width: 640, height: 480, channels: 3, background: '#e2f0e7' } })
  .composite([
    {
      input: Buffer.from(
        '<svg width="640" height="480"><rect x="180" y="80" width="280" height="320" rx="15" fill="#fff" stroke="#087b4b" stroke-width="5"/><circle cx="320" cy="250" r="90" fill="#d1e8dc" stroke="#087b4b" stroke-width="5"/><path d="m280 250 28 28 60-64" fill="none" stroke="#087b4b" stroke-width="14"/></svg>',
      ),
    },
  ])
  .png()
  .toFile('test-results/repair-evidence.png');
const browser = await chromium.launch({
  executablePath:
    process.env.EDGE_PATH || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  headless: true,
  args: process.env.HOMEFIX_TEST_RESOLVER_RULES
    ? ['--host-resolver-rules=' + process.env.HOMEFIX_TEST_RESOLVER_RULES]
    : [],
});
async function login(role) {
  const context = await browser.newContext({
      viewport: { width: 1440, height: 1000 },
      locale: 'vi-VN',
      permissions: ['geolocation'],
      geolocation: { latitude: 10.85, longitude: 106.77 },
    }),
    page = await context.newPage();
  page.on('pageerror', (e) => faults.push(e.message));
  await page.goto(base);
  await page.getByLabel('Số điện thoại hoặc email').fill(role + '@homefix.local');
  await page.getByLabel('Mật khẩu', { exact: true }).fill('HomeFix@123');
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  await page.locator('.app-shell').waitFor();
  return page;
}
async function nav(page, path) {
  await page.evaluate((p) => {
    history.pushState({}, '', p);
    dispatchEvent(new PopStateEvent('popstate'));
  }, path);
  await page.waitForTimeout(450);
}
async function fresh(page) {
  await page.getByRole('button', { name: 'Tải lại đơn', exact: true }).click();
  await page.waitForTimeout(500);
}
async function action(page, name, fill = async () => {}) {
  await page.getByRole('button', { name, exact: false }).click();
  const dialog = page.getByRole('dialog');
  await dialog.waitFor();
  await fill(dialog);
  const submitName =
    name === 'Chấp nhận đơn'
      ? 'Xác nhận nhận đơn'
      : name === 'Đề xuất vật tư'
        ? 'Gửi khách hàng duyệt'
        : name.includes('Lập phiếu nghiệm thu')
          ? 'Gửi phiếu nghiệm thu'
          : 'Xác nhận';
  await dialog.getByRole('button', { name: submitName, exact: true }).click();
  await Promise.race([
    dialog.waitFor({ state: 'hidden' }),
    dialog
      .getByRole('alert')
      .waitFor()
      .then(async () => {
        throw new Error(await dialog.getByRole('alert').innerText());
      }),
  ]);
  steps.push(name);
  await page.waitForTimeout(400);
}
try {
  const kh = await login('kh'),
    dpv = await login('dpv'),
    ktv = await login('ktv'),
    kt = await login('kt');
  await ktv.getByRole('heading', { name: /Sẵn sàng cho một ngày/ }).waitFor();
  await ktv.waitForTimeout(300);
  if (
    (await ktv
      .getByRole('switch', { name: 'Sẵn sàng nhận việc', exact: true })
      .getAttribute('aria-checked')) === 'false'
  )
    await ktv.getByRole('switch', { name: 'Sẵn sàng nhận việc', exact: true }).click();
  await nav(kh, '/book/1');
  await kh.getByLabel('Địa chỉ thực hiện').fill('1 Võ Văn Ngân, Thủ Đức, TP.HCM');
  await kh
    .getByLabel('Thiết bị gặp vấn đề gì?')
    .fill('[UI TEST] Máy lạnh không làm mát. Đề nghị kiểm tra tại nhà.');
  await kh.getByRole('button', { name: 'Gửi yêu cầu đặt dịch vụ' }).click();
  await kh.waitForURL(/\/orders\/\d+$/);
  orderId = Number(kh.url().split('/').at(-1));
  steps.push('KH đặt dịch vụ');
  await nav(dpv, '/orders/' + orderId);
  await action(dpv, 'Lập báo giá sơ bộ', (d) =>
    d
      .getByLabel('Chẩn đoán sơ bộ')
      .fill('Kiểm tra máy lạnh không mát; báo giá công kiểm tra và sửa chữa.'),
  );
  await fresh(kh);
  await action(kh, 'Đồng ý báo giá');
  await fresh(dpv);
  await action(dpv, 'Phân công kỹ thuật viên', async (d) => {
    await d.getByRole('option', { name: /Kỹ thuật viên Minh/ }).waitFor({ state: 'attached' });
    const value = await d.getByRole('option', { name: /Kỹ thuật viên Minh/ }).getAttribute('value');
    await d.getByLabel('Chọn kỹ thuật viên').selectOption(value);
  });
  await nav(ktv, '/orders/' + orderId);
  await action(ktv, 'Chấp nhận đơn');
  // GPS customer -> assigned technician, across two independent sessions.
  const customerMap = kh.locator('.route-card'),
    techMap = ktv.locator('.route-card');
  await customerMap
    .getByRole('button', { name: 'Cập nhật GPS của tôi', exact: true })
    .waitFor({ timeout: 25000 });
  assert.equal(
    await customerMap.getByRole('link', { name: 'Mở chỉ đường', exact: true }).count(),
    0,
  );
  assert.equal(await customerMap.getByRole('button').count(), 1);
  const waitDestination = async (latitude, longitude) => {
    await ktv.waitForFunction(
      ({ latitude, longitude }) => {
        const frame = document.querySelector('.route-card iframe');
        if (!frame) return false;
        const p = new URL(frame.src).searchParams;
        return (p.get('daddr') || p.get('q')) === `${latitude},${longitude}`;
      },
      { latitude, longitude },
      { timeout: 25000 },
    );
    const href = await techMap
      .getByRole('link', { name: 'Mở chỉ đường', exact: true })
      .getAttribute('href');
    assert.equal(new URL(href).searchParams.get('destination'), `${latitude},${longitude}`);
  };
  for (const point of [
    { latitude: 10.85123, longitude: 106.77123 },
    { latitude: 10.86123, longitude: 106.78123 },
  ]) {
    await kh.context().setGeolocation({ ...point, accuracy: 12 });
    await customerMap.getByRole('button', { name: 'Cập nhật GPS của tôi', exact: true }).click();
    await customerMap.getByText('Đã gửi vị trí hiện tại.', { exact: false }).waitFor();
    await waitDestination(point.latitude, point.longitude);
  }
  await kh.evaluate(() => {
    navigator.geolocation.getCurrentPosition = (_ok, error) => error({ code: 1 });
  });
  await customerMap.getByRole('button', { name: 'Cập nhật GPS của tôi', exact: true }).click();
  await customerMap.getByRole('alert').waitFor();
  assert.match(await customerMap.getByRole('alert').innerText(), /cho phép truy cập vị trí/);
  assert.equal(
    new URL(await customerMap.locator('iframe').getAttribute('src')).searchParams.get('daddr'),
    '10.86123,106.78123',
  );
  steps.push('KH cập nhật GPS hai lần; bản đồ KTV tự đổi điểm đến; từ chối quyền giữ vị trí cũ');

  for (const name of ['Bắt đầu di chuyển', 'Xác nhận đã đến nơi', 'Bắt đầu xử lý'])
    await action(ktv, name);
  await action(ktv, 'Đề xuất vật tư', async (d) => {
    await d.getByLabel('Tên vật tư').fill('Van máy lạnh');
    await d.getByLabel('Đơn giá (đ)').fill('220000');
    await d.getByLabel('Bảo hành (tháng)').fill('6');
    await d.getByLabel('Ghi chú').fill('Van cũ bị hỏng, cần thay mới.');
  });
  await fresh(kh);
  await action(kh, 'Đồng ý thay vật tư');
  await fresh(ktv);
  await action(ktv, 'Hoàn thành · Lập phiếu nghiệm thu', async (d) => {
    await d
      .getByLabel('Nguyên nhân hư hỏng')
      .fill('Van máy lạnh đã hỏng gây giảm khả năng làm mát.');
    await d
      .getByLabel('Biện pháp đã thực hiện')
      .fill('Đã thay van, kiểm tra kín và chạy thử ổn định.');
    await d
      .getByLabel('Ảnh thiết bị sau sửa chữa', { exact: true })
      .setInputFiles('test-results/repair-evidence.png');
    const canvas = d.locator('canvas');
    await canvas.scrollIntoViewIfNeeded();
    const box = await canvas.boundingBox();
    await d.page().mouse.move(box.x + 40, box.y + 50);
    await d.page().mouse.down();
    await d.page().mouse.move(box.x + 100, box.y + 90, { steps: 8 });
    await d.page().mouse.move(box.x + 150, box.y + 35, { steps: 8 });
    await d.page().mouse.up();
    await d.getByAltText('Chữ ký đã lưu tạm 1', { exact: true }).waitFor();
    await d.getByRole('button', { name: 'Xem lại phiếu', exact: true }).click();
    await d.getByRole('heading', { name: 'Xem lại phiếu nghiệm thu', exact: true }).waitFor();
  });
  await fresh(kh);
  await kh.getByRole('heading', { name: 'Chữ ký khách hàng', exact: true }).waitFor();
  await kh.screenshot({ path: out + '/workflow-kh-acceptance.png', fullPage: true });
  await action(kh, 'Xác nhận nghiệm thu', (d) => d.getByRole('checkbox').check());
  await fresh(ktv);
  await action(ktv, 'Xác nhận đã thu COD', (d) => d.getByRole('checkbox').check());
  await nav(kt, '/finance?tab=wallet');
  const row = kt.getByRole('row').filter({
    has: kt.getByRole('link', { name: 'HF-' + String(orderId).padStart(6, '0'), exact: true }),
  });
  await row.getByRole('button', { name: 'Đối soát', exact: true }).click();
  await kt.getByRole('dialog').getByRole('button', { name: 'Xác nhận xử lý' }).click();
  await kt.getByRole('dialog').waitFor({ state: 'hidden' });
  steps.push('KT đối soát hoa hồng');
  await fresh(kh);
  await action(kh, 'Đánh giá dịch vụ', (d) =>
    d.getByLabel('Nhận xét của bạn').fill('Kỹ thuật viên giải thích rõ, sửa đúng yêu cầu.'),
  );
  await kh.screenshot({ path: out + '/workflow-kh-completed.png', fullPage: true });
  await fresh(ktv);
  assert.equal(await ktv.getByRole('alert').count(), 0);
  await ktv.screenshot({ path: out + '/workflow-ktv-completed-desktop.png', fullPage: true });
  assert.ok(
    await ktv.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1),
    'Order detail desktop overflow',
  );
  assert.deepEqual(faults, []);
  console.log('UI full workflow PASS:', steps.length, 'actions. Order', orderId);
} catch (e) {
  faults.push(e.message);
  for (const [i, context] of browser.contexts().entries())
    await context
      .pages()[0]
      ?.screenshot({ path: out + '/failure-workflow-' + i + '.png', fullPage: true })
      .catch(() => {});
  throw e;
} finally {
  await browser.close();
  fs.writeFileSync(
    'test-results/ui-workflow-results.json',
    JSON.stringify({ executedAt: new Date().toISOString(), orderId, steps, faults }, null, 2),
  );
}
