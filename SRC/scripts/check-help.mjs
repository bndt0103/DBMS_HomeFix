import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';
const folder = path.resolve('../HELP/html');
const out = path.resolve('../DOC/evidence/report-revision');
const browser = await chromium.launch({
  executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  headless: true,
});
const results = [];
try {
  const page = await browser.newPage();
  for (const width of [1080, 700]) {
    await page.setViewportSize({ width, height: 850 });
    for (const name of fs.readdirSync(folder).filter((f) => f.endsWith('.html'))) {
      await page.goto(pathToFileURL(path.join(folder, name)).href);
      const result = await page.evaluate(() => ({
        title: document.querySelector('h1')?.textContent,
        overflow: document.documentElement.scrollWidth > innerWidth + 1,
        brokenImages: [...document.images].filter((i) => !i.complete || !i.naturalWidth).length,
        contentWidth: document.querySelector('.content').getBoundingClientRect().width,
      }));
      assert.ok(result.title);
      assert.equal(result.overflow, false, `${name}: overflow`);
      assert.equal(result.brokenImages, 0, `${name}: images`);
      assert.equal(result.contentWidth, width, `${name}: content must fit pane`);
      results.push({ name, width, status: 'PASS' });
      if (width === 1080 && ['index.html', 'caidat.html', 'ktv.html'].includes(name))
        await page.screenshot({ path: path.join(out, 'help-' + name + '.png') });
    }
  }
  fs.writeFileSync(path.join(out, 'help-check.json'), JSON.stringify(results, null, 2));
  console.log(`Help PASS: ${results.length} pages/viewports; no missing images or overflow.`);
} finally {
  await browser.close();
}
