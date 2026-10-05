import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Bell, BellOff } from 'lucide-react';
export function AssignmentAlerts({ orders }) {
  const [enabled, setEnabled] = useState(false),
    [error, setError] = useState(''),
    audio = useRef(null),
    seen = useRef(new Set());
  const pending = orders.filter((order) => order.status === 'ChoNhan'),
    key = pending
      .map((order) => order.id)
      .sort()
      .join(',');
  useEffect(
    () => () => {
      audio.current?.close().catch(() => {});
    },
    [],
  );
  useEffect(() => {
    if (!enabled || !audio.current) return;
    const fresh = pending.filter((order) => !seen.current.has(order.id));
    if (!fresh.length) return;
    for (const order of fresh) seen.current.add(order.id);
    const context = audio.current;
    if (context.state !== 'running') return;
    for (let i = 0; i < 3; i++) {
      const oscillator = context.createOscillator(),
        gain = context.createGain(),
        start = context.currentTime + i * 0.3;
      oscillator.frequency.value = i === 1 ? 880 : 660;
      gain.gain.setValueAtTime(0.12, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.22);
      oscillator.connect(gain);
      gain.connect(context.destination);
      oscillator.start(start);
      oscillator.stop(start + 0.22);
    }
    navigator.vibrate?.([180, 80, 180]);
  }, [key, enabled]);
  async function toggle() {
    if (enabled) {
      setEnabled(false);
      return;
    }
    try {
      const Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio) throw new Error('Thiết bị chưa hỗ trợ chuông trong trình duyệt.');
      if (!audio.current) audio.current = new Audio();
      await audio.current.resume();
      setError('');
      setEnabled(true);
    } catch (e) {
      setError(e.message);
    }
  }
  return (
    <div className="assignment-alerts">
      <button type="button" className="btn" aria-pressed={enabled} onClick={toggle}>
        {enabled ? <Bell size={17} /> : <BellOff size={17} />}Chuông đơn mới:{' '}
        {enabled ? 'Bật' : 'Tắt'}
      </button>
      {pending.length > 0 && (
        <Link className="btn primary" to={'/orders/' + pending[0].id}>
          Có {pending.length} đơn mới cần phản hồi
        </Link>
      )}
      {error && <small role="status">{error}</small>}
    </div>
  );
}
