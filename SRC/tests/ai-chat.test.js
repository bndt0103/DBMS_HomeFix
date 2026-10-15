import test from 'node:test';
import assert from 'node:assert/strict';
import { chromium } from 'playwright';

const base = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const webBase = base.replace(/\/api$/, '');

async function api(method, path, body, token) {
  const headers = {};
  if (token) headers.Authorization = 'Bearer ' + token;
  if (body) headers['Content-Type'] = 'application/json';
  const r = await fetch(base + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await r.json().catch(() => ({}));
  return { status: r.status, ...json };
}

async function loginUser(email, password = 'HomeFix@123') {
  const res = await api('POST', '/auth/login', { identifier: email, password });
  if (res.status !== 200) {
    throw new Error(`Failed to login as ${email}: ${JSON.stringify(res)}`);
  }
  return res.data;
}

test('AI Chat: API authentication and validation', async (t) => {
  let customerToken;
  let techToken;

  await t.test('1. Chặn người dùng chưa đăng nhập gọi /api/ai/chat (401)', async () => {
    const res = await api('POST', '/ai/chat', { message: 'Xin chào' });
    assert.equal(res.status, 401);
    assert.equal(res.error?.code, 'UNAUTHENTICATED');
  });

  await t.test('2. Lấy token khách hàng và thợ để kiểm tra quyền hạn', async () => {
    const cust = await loginUser('kh@homefix.local');
    customerToken = cust.accessToken;
    assert.ok(customerToken);

    const tech = await loginUser('ktv@homefix.local');
    techToken = tech.accessToken;
    assert.ok(techToken);
  });

  await t.test('3. Chặn vai trò không phải khách hàng (KTV) gọi /api/ai/chat (403)', async () => {
    const res = await api('POST', '/ai/chat', { message: 'Tư vấn giúp' }, techToken);
    assert.equal(res.status, 403);
    assert.equal(res.error?.code, 'FORBIDDEN');
  });

  await t.test('4. Chặn tin nhắn trống hoặc rỗng (422)', async () => {
    const res = await api('POST', '/ai/chat', { message: '   ' }, customerToken);
    assert.equal(res.status, 422);
  });

  await t.test('5. Chặn tin nhắn quá dài vượt 1000 ký tự (422)', async () => {
    const longMsg = 'A'.repeat(1005);
    const res = await api('POST', '/ai/chat', { message: longMsg }, customerToken);
    assert.equal(res.status, 422);
  });

  await t.test('6. Chặn lịch sử chat có cấu trúc không hợp lệ (422)', async () => {
    const invalidHistory = [{ role: 'hacker', content: 'hack' }];
    const res = await api(
      'POST',
      '/ai/chat',
      { message: 'Tư vấn', history: invalidHistory },
      customerToken,
    );
    assert.equal(res.status, 422);
  });

  await t.test('7. Khách hàng gửi tin nhắn hợp lệ nhận được phản hồi chuẩn (200)', async () => {
    const res = await api('POST', '/ai/chat', { message: 'Máy lạnh không mát' }, customerToken);
    assert.equal(res.status, 200);
    assert.ok(res.data?.reply);
    assert.ok(Array.isArray(res.data?.suggestions));
    // Kiểm tra quy tắc xưng hô và quy trình điều phối
    const replyText = res.data.reply;
    assert.ok(!replyText.includes('Em là'));
    assert.ok(!replyText.includes('em nhé'));
  });

  await t.test('8. Chấp nhận 50 câu hỏi và chặn câu thứ 51 trong 15 phút', async () => {
    const secondCustomer = await loginUser('kh2@homefix.local');
    for (let i = 1; i <= 50; i++) {
      const res = await api(
        'POST',
        '/ai/chat',
        { message: `Câu hỏi ${i}` },
        secondCustomer.accessToken,
      );
      assert.equal(res.status, 200, `Lượt ${i} phải được chấp nhận`);
    }

    const limited = await api(
      'POST',
      '/ai/chat',
      { message: 'Câu hỏi thứ 51' },
      secondCustomer.accessToken,
    );
    assert.equal(limited.status, 429);
    assert.equal(limited.error?.code, 'AI_RATE_LIMITED');
  });
});

test('AI Chat UI: Mở chat, gửi tin và đăng xuất', async (t) => {
  let browser;
  try {
    browser = await chromium.launch({
      executablePath:
        process.env.EDGE_PATH || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
      headless: true,
    });
  } catch (err) {
    t.skip('Trình duyệt Playwright/Edge không khả dụng: ' + err.message);
    return;
  }

  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await context.newPage();

  try {
    await t.test('1. Kiểm tra nút AI Chat không hiển thị khi chưa đăng nhập', async () => {
      await page.goto(webBase);
      await page.waitForLoadState('networkidle');
      const chatBtnCount = await page.locator('.ai-chat-fab').count();
      assert.equal(chatBtnCount, 0, 'Nút AI Chat không được xuất hiện ở màn hình đăng nhập');
    });

    await t.test('2. Đăng nhập tài khoản khách hàng', async () => {
      await page.getByLabel('Số điện thoại hoặc email').fill('kh@homefix.local');
      await page.getByLabel('Mật khẩu', { exact: true }).fill('HomeFix@123');
      await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
      await page.locator('.customer-shell').waitFor({ timeout: 10000 });
    });

    await t.test('3. Mở khung chat AI và kiểm tra biểu ngữ quyền riêng tư', async () => {
      const fab = page.locator('.ai-chat-fab');
      await fab.waitFor({ state: 'visible', timeout: 5000 });
      await fab.click();

      const chatWindow = page.locator('.ai-chat-window');
      await chatWindow.waitFor({ state: 'visible', timeout: 5000 });

      // Kiểm tra banner quyền riêng tư
      const privacyBanner = page.locator('.ai-chat-privacy-banner');
      await privacyBanner.waitFor({ state: 'visible' });
      const bannerText = await privacyBanner.textContent();
      assert.ok(bannerText.includes('nhà cung cấp AI'));
      assert.ok(bannerText.includes('24 giờ'));
    });

    await t.test('4. Gửi tin nhắn và nhận phản hồi', async () => {
      const input = page.locator('.ai-chat-textarea');
      await input.fill('Tư vấn sửa máy lạnh');
      await page.locator('.ai-chat-send-btn').click();

      // Đợi tin nhắn của người dùng xuất hiện với chữ trắng
      const userBubble = page.locator('.ai-chat-message-row.user .ai-chat-bubble');
      await userBubble.waitFor({ state: 'visible', timeout: 5000 });

      // Đợi hàng phản hồi thật; hàng hiệu ứng đang nhập không có thời gian gửi.
      await page.waitForFunction(
        () =>
          document.querySelectorAll('.ai-chat-message-row.assistant .ai-chat-msg-time').length >= 2,
        null,
        { timeout: 12000 },
      );
      const assistantReplies = page
        .locator('.ai-chat-message-row.assistant')
        .filter({ has: page.locator('.ai-chat-msg-time') });
      const replyContent = await assistantReplies.last().textContent();
      assert.ok(replyContent.length > 20);
    });

    await t.test('5. Đăng xuất và xác nhận nút AI Chat biến mất', async () => {
      const logoutBtn = page.getByRole('button', { name: 'Đăng xuất' }).first();
      await logoutBtn.click();
      await page.locator('.auth-form').waitFor({ timeout: 8000 });

      // Xác nhận nút AI Chat đã bị gỡ bỏ khỏi DOM
      const fabAfterLogout = await page.locator('.ai-chat-fab').count();
      assert.equal(fabAfterLogout, 0, 'Nút AI Chat phải biến mất sau khi đăng xuất');
    });
  } finally {
    await browser.close();
  }
});
