import { chromium } from 'playwright';
import fs from 'node:fs';
import assert from 'node:assert/strict';
const base = process.env.TEST_BASE_URL?.replace(/\/api$/, '') || 'http://localhost:3000';
const folder = 'test-results/screenshots';
fs.mkdirSync(folder, { recursive: true });
const browser = await chromium.launch({
  executablePath:
    process.env.EDGE_PATH || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  headless: true,
});
const cases = [];
const faults = [];
try {
  for (const [role, paths] of Object.entries({
    kh: ['/', '/services', '/orders', '/support', '/profile', '/applications', '/notifications'],
    ktv: ['/', '/orders', '/wallet'],
    dpv: ['/', '/orders', '/reports'],
    cskh: ['/', '/support'],
    kt: ['/', '/finance', '/reports'],
    admin: [
      '/',
      '/admin/users',
      '/admin/services',
      '/admin/settings',
      '/admin/audit',
      '/applications',
    ],
    gd: ['/', '/reports'],
  })) {
    const context = await browser.newContext({
        viewport: { width: 1440, height: 1000 },
        locale: 'vi-VN',
      }),
      page = await context.newPage();
    page.on('pageerror', (e) => faults.push(role + ': ' + e.message));
    page.on('response', (r) => {
      if (r.url().includes('/api/') && r.status() >= 400)
        faults.push(`${role}: HTTP ${r.status()} ${r.url()}`);
    });
    await page.goto(base);
    if (role === 'kh')
      await page.screenshot({ path: folder + '/01-login-desktop.png', fullPage: false });
    await page.getByLabel('Số điện thoại hoặc email').fill(role + '@homefix.local');
    await page.getByLabel('Mật khẩu', { exact: true }).fill('HomeFix@123');
    await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
    await page.locator('.app-shell').waitFor();
    for (const pathname of paths) {
      // Navigation through the SPA preserves the in-memory access token.
      await page.evaluate((p) => {
        history.pushState({}, '', p);
        dispatchEvent(new PopStateEvent('popstate'));
      }, pathname);
      await page.waitForTimeout(650);
      await page
        .locator('.loading')
        .waitFor({ state: 'hidden' })
        .catch(() => {});
      assert.equal(
        await page.locator('[role=alert]').count(),
        0,
        role + ' ' + pathname + ': ' + (await page.locator('main').innerText()),
      );
      assert.ok(await page.locator('main').innerText(), role + ' ' + pathname + ' blank');
      assert.ok(
        await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1),
        role + ' ' + pathname + ' desktop overflow',
      );
      if (
        pathname === '/' ||
        pathname === '/finance' ||
        pathname === '/reports' ||
        pathname === '/admin/users'
      )
        await page.screenshot({
          path:
            folder +
            '/' +
            role +
            '-' +
            (pathname.slice(1).replaceAll('/', '-') || 'home') +
            '-desktop.png',
          fullPage: false,
        });
      cases.push({ role, path: pathname, viewport: '1440x1000', status: 'PASS' });
    }
    await context.close();
  }
  assert.deepEqual(faults, []);
  console.log(
    'UI smoke PASS:',
    cases.length,
    'pages; no JS/API errors or horizontal page overflow.',
  );
} finally {
  await browser.close();
  fs.writeFileSync(
    'test-results/ui-results.json',
    JSON.stringify({ executedAt: new Date().toISOString(), cases, faults }, null, 2),
  );
}
