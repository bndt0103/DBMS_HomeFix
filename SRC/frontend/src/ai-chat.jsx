import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Bot, X, Send, Trash2, ShieldAlert } from 'lucide-react';
import { api } from './api';
import { useApp } from './shared';
import './ai-chat.css';

const CHAT_STORAGE_KEY = (userId) => `homefix.ai_chat_history:${userId}`;
const LEGACY_CHAT_STORAGE_KEY = 'homefix.ai_chat_history';
const CHAT_TTL_MS = 24 * 60 * 60 * 1000; // Xóa sau 24 giờ không hoạt động

const INITIAL_MESSAGE = {
  id: 'init',
  role: 'assistant',
  content: `Xin chào bạn! Tôi là **HomeFix AI** - Trợ lý ảo tư vấn kỹ thuật và dịch vụ sửa chữa của HomeFix. 🛠️

Tôi có thể giúp bạn:
• **Bắt bệnh & Tư vấn xử lý sự cố:** Máy lạnh, máy giặt, tủ lạnh, chập điện, rò rỉ nước...
• **Hướng dẫn an toàn:** Cách phòng ngừa chập cháy, khóa van nước khẩn cấp.
• **Thông tin dịch vụ & Đặt lịch:** Hướng dẫn chọn giờ hẹn tự do từ 08:00 – 17:59.

Bạn đang cần hỗ trợ vấn đề gì ở nhà? Hãy nhắn cho tôi biết nhé!`,
  suggestions: [
    'Máy lạnh nhà mình không mát',
    'Cần thợ kiểm tra chập điện',
    'Đường ống nước bị rò rỉ',
    'Hướng dẫn đặt lịch hẹn',
    'Quy trình báo giá & bảo hành',
  ],
  time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
};

function formatText(text) {
  if (!text) return null;
  const lines = text.split('\n');
  return lines.map((line, i) => {
    // Process bold text **text**
    const parts = line.split(/(\*\*.*?\*\*)/g);
    const formattedLine = parts.map((part, j) => {
      if (part.startsWith('**') && part.endsWith('**')) {
        return <strong key={j}>{part.slice(2, -2)}</strong>;
      }
      return part;
    });

    if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
      return (
        <p key={i} style={{ margin: '3px 0 3px 8px' }}>
          {formattedLine}
        </p>
      );
    }
    return (
      <p key={i} style={{ margin: line ? '4px 0' : '6px 0' }}>
        {formattedLine}
      </p>
    );
  });
}

// Component cha: Chỉ render widget khi người dùng có vai trò là khách hàng
export function AIChat() {
  const { user } = useApp();
  if (user?.role !== 'KH') return null;
  return <AIChatWidget key={user.id} userId={user.id} />;
}

// Component con: Chứa toàn bộ hook, luôn được gọi đồng nhất theo thứ tự
function AIChatWidget({ userId }) {
  const storageKey = CHAT_STORAGE_KEY(userId);
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState(() => {
    try {
      // Bản cũ dùng một khóa chung giữa các tài khoản; xóa để không giữ lịch sử không xác định chủ sở hữu.
      localStorage.removeItem(LEGACY_CHAT_STORAGE_KEY);
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (
          parsed?.savedAt &&
          Date.now() - parsed.savedAt >= 0 &&
          Date.now() - parsed.savedAt < CHAT_TTL_MS &&
          Array.isArray(parsed.items) &&
          parsed.items.length > 0
        ) {
          return parsed.items;
        }
        localStorage.removeItem(storageKey);
      }
    } catch {}
    return [INITIAL_MESSAGE];
  });
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);
  const textareaRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    try {
      localStorage.setItem(storageKey, JSON.stringify({ items: messages, savedAt: Date.now() }));
    } catch {}
  }, [messages, storageKey]);

  // Xóa lịch sử khỏi trình duyệt sau 24 giờ không hoạt động.
  useEffect(() => {
    const timer = window.setTimeout(() => {
      try {
        localStorage.removeItem(storageKey);
      } catch {}
    }, CHAT_TTL_MS);
    return () => window.clearTimeout(timer);
  }, [messages, storageKey]);

  useEffect(() => {
    if (open) {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, open, loading]);

  const handleSend = async (textToSend) => {
    const query = (textToSend || input).trim();
    if (!query || loading) return;

    if (
      query.toLowerCase().includes('đặt dịch vụ ngay') ||
      query.toLowerCase().includes('đi đến trang đặt dịch vụ')
    ) {
      setOpen(false);
      navigate('/services');
      return;
    }

    const userMsg = {
      id: Date.now().toString(),
      role: 'user',
      content: query,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    // Chỉ lấy lịch sử hội thoại trước đó (không bao gồm câu hỏi hiện tại) để tránh lặp ngữ cảnh
    const historyPayload = messages
      .filter((m) => m.id !== 'init')
      .slice(-6)
      .map((m) => ({ role: m.role, content: String(m.content).slice(0, 2000) }));

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      const res = await api('/ai/chat', {
        method: 'POST',
        body: { message: query, history: historyPayload },
      });

      const assistantMsg = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: res.reply || res.data?.reply || 'Tôi đã ghi nhận thông tin từ bạn.',
        suggestions: res.suggestions || res.data?.suggestions || [],
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages((prev) => [...prev, assistantMsg]);
    } catch (err) {
      const messageText =
        err?.code === 'AI_RATE_LIMITED'
          ? 'Bạn đang gửi tin nhắn quá nhanh. Vui lòng chờ vài phút rồi tiếp tục nhé!'
          : 'Hiện tại đường truyền đang bận một chút. Bạn có thể bấm chọn dịch vụ hoặc mô tả lại giúp tôi nhé!';

      const errorMsg = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: messageText,
        suggestions: ['Đặt dịch vụ ngay', 'Bảng giá tham khảo'],
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, errorMsg]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleClearHistory = () => {
    if (window.confirm('Bạn có muốn xóa cuộc trò chuyện và bắt đầu lại không?')) {
      setMessages([INITIAL_MESSAGE]);
      try {
        localStorage.removeItem(storageKey);
      } catch {}
    }
  };

  return (
    <>
      {/* Floating Action Button */}
      {!open && (
        <button
          className="ai-chat-fab"
          onClick={() => setOpen(true)}
          aria-label="Mở trợ lý ảo AI HomeFix"
        >
          <div className="ai-chat-fab-pulse">
            <Sparkles size={18} />
          </div>
          <span>Hỏi AI HomeFix</span>
        </button>
      )}

      {/* Chat Window */}
      {open && (
        <div className="ai-chat-window" role="dialog" aria-label="Cửa sổ trò chuyện HomeFix AI">
          {/* Header */}
          <div className="ai-chat-header">
            <div className="ai-chat-header-info">
              <div className="ai-chat-avatar">
                <Bot size={22} />
              </div>
              <div className="ai-chat-title">
                <h3>Trợ lý ảo HomeFix AI</h3>
                <div className="ai-chat-status">
                  <span className="ai-chat-status-dot" />
                  <span>Trực tuyến 24/7</span>
                </div>
              </div>
            </div>
            <div className="ai-chat-header-actions">
              <button
                className="ai-chat-icon-btn"
                onClick={handleClearHistory}
                title="Bắt đầu đoạn chat mới"
                aria-label="Xóa lịch sử trò chuyện"
              >
                <Trash2 size={16} />
              </button>
              <button
                className="ai-chat-icon-btn"
                onClick={() => setOpen(false)}
                title="Đóng cửa sổ chat"
                aria-label="Đóng cửa sổ chat"
              >
                <X size={18} />
              </button>
            </div>
          </div>

          {/* Privacy Notice Banner */}
          <div className="ai-chat-privacy-banner">
            <ShieldAlert size={14} className="ai-chat-privacy-icon" />
            <span>
              Tùy cấu hình HomeFix, tin nhắn và tối đa 6 tin nhắn trước đó có thể được gửi đến nhà
              cung cấp AI. Vui lòng không chia sẻ dữ liệu nhạy cảm (mật khẩu, ngân hàng, CCCD). Lịch
              sử chat lưu riêng theo tài khoản và tự xóa sau 24 giờ không hoạt động.
            </span>
          </div>

          {/* Messages Body */}
          <div className="ai-chat-body">
            {messages.map((msg) => (
              <div key={msg.id} className={`ai-chat-message-row ${msg.role}`}>
                {msg.role === 'assistant' && (
                  <div className="ai-chat-msg-avatar">
                    <Sparkles size={14} />
                  </div>
                )}
                <div style={{ maxWidth: '85%' }}>
                  <div className="ai-chat-bubble">{formatText(msg.content)}</div>
                  <div className="ai-chat-msg-time">{msg.time}</div>

                  {/* Suggestion Chips */}
                  {msg.role === 'assistant' && msg.suggestions && msg.suggestions.length > 0 && (
                    <div className="ai-chat-suggestions">
                      {msg.suggestions.map((sug, idx) => (
                        <button key={idx} className="ai-chip-btn" onClick={() => handleSend(sug)}>
                          {sug}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))}

            {loading && (
              <div className="ai-chat-message-row assistant">
                <div className="ai-chat-msg-avatar">
                  <Sparkles size={14} />
                </div>
                <div className="ai-chat-bubble">
                  <div className="ai-typing-indicator">
                    <span />
                    <span />
                    <span />
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Footer Input */}
          <div className="ai-chat-footer">
            <div className="ai-chat-input-form">
              <textarea
                ref={textareaRef}
                className="ai-chat-textarea"
                rows={1}
                maxLength={1000}
                placeholder="Hỏi về sự cố, báo giá, cách đặt thợ..."
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
              />
              <button
                className="ai-chat-send-btn"
                disabled={!input.trim() || loading}
                onClick={() => handleSend()}
                aria-label="Gửi tin nhắn"
              >
                <Send size={15} />
              </button>
            </div>
            <div className="ai-chat-disclaimer">
              HomeFix AI tư vấn kỹ thuật & hỗ trợ khách hàng đặt lịch.
            </div>
          </div>
        </div>
      )}
    </>
  );
}
