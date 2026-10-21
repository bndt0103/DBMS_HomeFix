import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import { auth } from './auth.js';
import { ok, fail, wrap, roles, z, str } from './common.js';

export const aiRouter = Router();

// Khóa API: Chỉ cho phép người dùng đã đăng nhập với vai trò Khách hàng (KH)
aiRouter.use('/ai', auth, roles('KH'));

// Giới hạn lượt gọi API AI: tối đa 50 câu hỏi mỗi 15 phút cho mỗi người dùng
const aiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 50,
  keyGenerator: (req) => String(req.user?.id || req.ip),
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: {
    error: {
      code: 'AI_RATE_LIMITED',
      message:
        'Bạn đã đạt giới hạn lượt hỏi AI (tối đa 50 câu / 15 phút). Vui lòng thử lại sau vài phút.',
    },
  },
});

const chatSchema = z.strictObject({
  message: str(1, 1000),
  history: z
    .array(
      z.strictObject({
        role: z.enum(['user', 'assistant']),
        content: z.string().trim().min(1).max(2000),
      }),
    )
    .max(10)
    .default([]),
});

const SYSTEM_PROMPT = `Bạn là "HomeFix AI" - Trợ lý ảo tư vấn kỹ thuật và dịch vụ sửa chữa nhà cửa chuyên nghiệp của hệ thống HomeFix (Đồ án Hệ quản trị cơ sở dữ liệu DBMS Nhóm 08).
Phong cách: Thân thiện, chu đáo, am hiểu kỹ thuật thực tế, súc tích và đặt sự an toàn của khách hàng lên hàng đầu.

Quy tắc và kiến thức nền tảng của HomeFix:
1. An toàn là số 1: Với các sự cố rò rỉ điện hoặc vỡ ống nước lớn, luôn nhắc khách cúp cầu dao (CB/Aptomat) hoặc khóa van nước tổng trước khi thao tác.
2. Dịch vụ cung cấp:
   - Điện tử - Điện lạnh: Máy lạnh/điều hòa (bơm gas, vệ sinh, không mát, chảy nước), Tủ lạnh (không đông đá, kêu to), Máy giặt (không vắt, rung lắc).
   - Điện dân dụng: Chập điện, nhảy aptomat, thay ổ cắm, lắp đèn, lắp quạt trần, đi lại đường dây.
   - Cấp thoát nước: Rò rỉ ống nước, nghẹt cống/lavabo/bồn cầu, thay phao bồn nước, sửa máy bơm.
   - Gia dụng khác: Bình nóng lạnh, bếp từ, lò vi sóng, hút mùi.
3. Quy trình làm việc 5 bước minh bạch:
   - Bước 1: Khách hàng chọn dịch vụ, mô tả tình trạng và đặt lịch hẹn (tự do từ 08:00 đến 17:59).
   - Bước 2: Điều phối viên tiếp nhận và lập báo giá sơ bộ từ mô tả của khách.
   - Bước 3: Khách hàng kiểm tra và BẤM DUYỆT báo giá, sau đó điều phối viên mới phân công kỹ thuật viên phù hợp.
   - Bước 4: Kỹ thuật viên nhận đơn, đến kiểm tra và xử lý; nếu cần vật tư thì gửi đề xuất riêng để khách duyệt trước.
   - Bước 5: Hai bên nghiệm thu chất lượng, thanh toán (Tiền mặt COD hoặc chuyển khoản) và phiếu bảo hành điện tử được kích hoạt.
4. Giá cả: Báo giá sơ bộ được hiển thị để khách xem và duyệt trước khi thi công. Nếu phát sinh hạng mục/vật tư mới, khách cần được gửi đề xuất riêng để xem và duyệt; không khẳng định giá cuối cùng trước khi có đủ thông tin.
5. Giới hạn tư vấn: Chỉ đưa hướng dẫn sơ bộ, không khẳng định chắc chắn nguyên nhân khi chưa kiểm tra trực tiếp. Không hướng dẫn khách tự sửa phần điện đang có nguy cơ giật/cháy, bình nóng lạnh rò điện hoặc thiết bị nguy hiểm; hướng dẫn ngắt nguồn/khóa van an toàn và gọi kỹ thuật viên.
6. QUY TẮC XƯNG HÔ BẮT BUỘC: Bạn luôn luôn xưng là "tôi" và gọi người dùng là "bạn". Tuyệt đối không xưng là "em", "mình" hay bất kỳ cách xưng hô nào khác.`;

function getFallbackReply(message) {
  const q = (message || '').toLowerCase();

  if (
    q.includes('máy lạnh') ||
    q.includes('điều hòa') ||
    q.includes('không mát') ||
    q.includes('chảy nước')
  ) {
    return {
      reply: `Chào bạn! Đối với sự cố **Máy lạnh/Điều hòa**, các nguyên nhân phổ biến nhất gồm:

1. **Máy chạy nhưng không mát/mát yếu:**
   • Lưới lọc bụi quá bẩn cản gió (bạn có thể tự tháo rửa tấm lưới phía trước).
   • Máy bị thiếu gas hoặc rò rỉ gas ở mối nối.
   • Cục nóng giải nhiệt kém do quá bụi hoặc quạt cục nóng gặp sự cố.

2. **Máy lạnh bị chảy nước trong phòng:**
   • Ống thoát nước bị nghẹt rêu mốc hoặc bụi bẩn tích tụ.
   • Máng nước bị nứt hoặc máy bị nghiêng sai kỹ thuật.

👉 **Khuyến nghị:** Bạn nên vào mục **"Đặt dịch vụ"** ➔ chọn nhóm **Điện lạnh** để điều phối viên cử thợ HomeFix đến vệ sinh, đo áp suất gas và kiểm tra toàn diện cho bạn nhé!`,
      suggestions: [
        'Đặt dịch vụ vệ sinh máy lạnh',
        'Bảng giá nạp gas máy lạnh',
        'Cách tự vệ sinh lưới lọc',
        'Quy trình bảo hành của HomeFix',
      ],
    };
  }

  if (
    q.includes('chập điện') ||
    q.includes('mất điện') ||
    q.includes('aptomat') ||
    q.includes('nhảy cb') ||
    q.includes('ổ cắm') ||
    q.includes('điện')
  ) {
    return {
      reply: `⚠️ **CẢNH BÁO AN TOÀN ĐIỆN:**
Nếu nhà bạn đang có hiện tượng tóe lửa, bốc mùi khét hoặc Aptomat liên tục nhảy khi bật:
1. **Hãy lập tức ngắt cầu dao tổng (CB chính)** để bảo vệ an toàn cho cả gia đình.
2. Không cố gạt bật lại CB nhiều lần khi chưa ngắt các thiết bị công suất lớn (bình nóng lạnh, máy sưởi, lò nướng).
3. Rút phích cắm thiết bị nghi ngờ bị chập ra khỏi ổ điện.

👉 Đội ngũ kỹ thuật viên **Điện dân dụng của HomeFix** có đầy đủ đồng hồ đo chuyên dụng để dò tìm vị trí rò rỉ điện âm tường. Bạn hãy đặt lịch trên app để điều phối viên cử thợ có mặt xử lý an toàn ngay nhé!`,
      suggestions: [
        'Đặt thợ sửa điện khẩn cấp',
        'Nguyên nhân aptomat nhảy liên tục',
        'Báo giá sửa chập điện âm tường',
        'Thời gian thợ có mặt',
      ],
    };
  }

  if (
    q.includes('nước') ||
    q.includes('rò rỉ') ||
    q.includes('vỡ ống') ||
    q.includes('nghẹt') ||
    q.includes('tắc') ||
    q.includes('bồn cầu') ||
    q.includes('bơm')
  ) {
    return {
      reply: `Chào bạn! Về các sự cố **Hệ thống cấp thoát nước**:

• **Rò rỉ/vỡ ống nước:** Bạn nên tìm và **khóa van nước tổng** ngay để tránh ngập sàn và thất thoát nước sinh hoạt.
• **Nghẹt lavabo/bồn cầu:** Tránh dùng các vật sắc nhọn chọc sâu có thể làm thủng ống mềm. Có thể thử dùng pittong cao su hoặc dung dịch thông tắc vi sinh an toàn.
• **Máy bơm không lên nước:** Kiểm tra lại nguồn nước cấp, rơ-le áp lực hoặc tụ khởi động máy bơm.

👉 Đội ngũ thợ nước HomeFix luôn sẵn sàng máy nén thông tắc và thiết bị hàn ống nhiệt PPR chuyên dụng. Bạn có thể bấm **Đặt dịch vụ** ngay trên hệ thống!`,
      suggestions: [
        'Đặt thợ sửa ống nước',
        'Thông nghẹt cống & bồn rửa',
        'Sửa máy bơm nước gia đình',
        'Bảng giá sửa chữa điện nước',
      ],
    };
  }

  if (
    q.includes('máy giặt') ||
    q.includes('tủ lạnh') ||
    q.includes('bình nóng lạnh') ||
    q.includes('bếp từ')
  ) {
    return {
      reply: `Chào bạn! Về **Thiết bị điện gia dụng**:

• **Máy giặt rung lắc, không vắt:** Thường do kê máy không thăng bằng, quần áo bị dồn một phía hoặc gãy chảng ba/hỏng thụt giảm xóc.
• **Tủ lạnh ngăn mát không lạnh:** Có thể do quạt gió đóng băng, hỏng cảm biến xả đá (sensor) hoặc nghẹt đường gió hồi.
• **Bình nóng lạnh không nóng / rò điện:** Cực kỳ nguy hiểm, cần ngắt nguồn ngay và kiểm tra thanh đốt Magie, rơ-le chống giật ELCB.

👉 Kỹ thuật viên HomeFix đều được đào tạo bài bản và cam kết linh kiện thay thế chính hãng có bảo hành rõ ràng.`,
      suggestions: [
        'Đặt thợ sửa máy giặt',
        'Bảo dưỡng bình nóng lạnh',
        'Sửa tủ lạnh không đông đá',
        'Chính sách bảo hành linh kiện',
      ],
    };
  }

  if (q.includes('giá') || q.includes('chi phí') || q.includes('bao nhiêu') || q.includes('tiền')) {
    return {
      reply: `💰 **Chính sách Giá cả tại HomeFix:**

1. **Tuyệt đối minh bạch:** Mọi chi phí đều hiển thị rõ ràng trên hệ thống.
2. **Báo giá trước:** Điều phối viên gửi **Phiếu báo giá sơ bộ** dựa trên mô tả của bạn. Sau khi bạn duyệt, điều phối viên mới phân công thợ.
3. **Khách duyệt mới làm:** Bạn có quyền xem xét từng hạng mục (công thợ, linh kiện). Nếu bạn đồng ý duyệt thì thợ mới bắt đầu thi công.
4. **Phát sinh minh bạch:** Nếu cần thêm vật tư hoặc hạng mục, thợ cần gửi đề xuất để bạn xem và duyệt trên ứng dụng trước khi thực hiện.

👉 Bạn có thể đăng nhập tài khoản Khách hàng để xem chi tiết bảng giá cơ bản của từng dịch vụ nhé!`,
      suggestions: [
        'Quy trình duyệt báo giá',
        'Hình thức thanh toán hỗ trợ',
        'Phí hủy đơn nếu không đồng ý giá',
        'Đặt lịch khảo sát ngay',
      ],
    };
  }

  if (
    q.includes('đặt') ||
    q.includes('lịch') ||
    q.includes('hẹn') ||
    q.includes('quy trình') ||
    q.includes('hướng dẫn')
  ) {
    return {
      reply: `📋 **Hướng dẫn Đặt dịch vụ trên HomeFix cực kỳ đơn giản:**

1. Bấm vào nút **"Đặt dịch vụ"** (hoặc chọn dịch vụ trong danh mục).
2. Nhập địa chỉ nhà và mô tả ngắn gọn hiện tượng hỏng hóc.
3. **Chọn lịch hẹn:** Bạn có thể để trống nếu cần thợ đến sớm nhất, hoặc chọn giờ hẹn tự do trong khung **08:00 – 17:59** (đặt trước tối thiểu 30 phút).
4. Đính kèm 1–5 ảnh chụp thiết bị nếu có (giúp thợ chuẩn bị sẵn linh kiện phù hợp).
5. Bấm **"Gửi yêu cầu"** ➔ Điều phối viên gửi báo giá sơ bộ. Bạn duyệt báo giá rồi điều phối viên mới phân công kỹ thuật viên phù hợp!`,
      suggestions: [
        'Đi đến trang Đặt dịch vụ',
        'Xem danh sách đơn đã đặt',
        'Thời gian thợ đến là bao lâu?',
        'Có thanh toán chuyển khoản được không?',
      ],
    };
  }

  // Phản hồi chào hỏi / mặc định
  return {
    reply: `Xin chào bạn! Tôi là **HomeFix AI** - Trợ lý ảo hỗ trợ kỹ thuật và tư vấn dịch vụ của hệ thống HomeFix. 🛠️

Tôi có thể hỗ trợ bạn:
• **Bắt bệnh sự cố gia đình:** Máy lạnh, máy giặt, tủ lạnh, bình nước nóng, chập điện, rò rỉ nước...
• **Hướng dẫn an toàn:** Cách xử lý khẩn cấp trước khi thợ tới.
• **Thông tin dịch vụ & Báo giá:** Bảng giá minh bạch, quy trình duyệt giá trước khi làm.
• **Hỗ trợ đặt đơn:** Hướng dẫn đặt lịch hẹn nhanh chóng trên ứng dụng.

Bạn đang gặp sự cố gì ở nhà? Hãy nhắn cho tôi biết để tôi hỗ trợ bạn nhé!`,
    suggestions: [
      'Máy lạnh nhà mình không mát',
      'Cần thợ kiểm tra chập điện',
      'Đường ống nước bị rò rỉ',
      'Hướng dẫn cách đặt lịch hẹn',
      'Bảng giá dịch vụ sửa chữa',
    ],
  };
}

async function callGemini(message, history = []) {
  const apiKey = (process.env.GEMINI_API_KEY || '').trim();
  const enabled = process.env.GEMINI_ENABLED !== 'false';
  if (!apiKey || !enabled) return null;

  const model = (process.env.GEMINI_MODEL || 'gemini-1.5-flash').trim();
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

  // Xây dựng ngữ cảnh sạch: Chỉ đưa các tin nhắn trước đó vào history, tránh lặp tin nhắn hiện tại
  const contents = [];
  for (const h of history.slice(-6)) {
    // Không đưa tin nhắn trùng lặp với message hiện tại vào phần lịch sử
    if (h.role === 'user' && h.content === message) continue;
    contents.push({
      role: h.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: String(h.content || '').slice(0, 1000) }],
    });
  }
  // Thêm tin nhắn hiện tại của người dùng một lần duy nhất
  contents.push({ role: 'user', parts: [{ text: String(message || '').slice(0, 1000) }] });

  const payload = {
    contents,
    systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 800,
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(10000),
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => '');
    console.warn(
      `[Gemini API] Request failed with status ${res.status}: ${errorText.slice(0, 200)}`,
    );
    return null;
  }

  const data = await res.json();
  const reply = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!reply) return null;

  return {
    reply: reply.trim(),
    suggestions: ['Đặt dịch vụ ngay', 'Bảng giá tham khảo', 'Cách đặt lịch hẹn trên HomeFix'],
  };
}

aiRouter.post(
  '/ai/chat',
  aiLimiter,
  wrap(async (req, res) => {
    const { message, history } = chatSchema.parse(req.body);

    try {
      const geminiResult = await callGemini(message, history);
      if (geminiResult && geminiResult.reply) {
        return ok(res, geminiResult);
      }
    } catch (err) {
      console.warn('[Gemini AI] Using fallback due to:', err.message);
    }

    const fallback = getFallbackReply(message);
    return ok(res, fallback);
  }),
);
