import React, { useEffect, useRef, useState } from 'react';
import { Phone, MessageCircle, Camera, ImagePlus, Trash2 } from 'lucide-react';
import { ErrorBox } from './shared';

export function ContactActions({ phone, reminder = false }) {
  const number = String(phone || '').replace(/[^+\d]/g, '');
  if (!number) return <p>Chưa có số điện thoại liên hệ.</p>;
  return (
    <div className="contact-actions">
      <a className="btn contact-call" href={'tel:' + number}>
        <Phone size={18} />
        {reminder ? 'Gọi nhắc khách' : 'Gọi khách hàng'}
      </a>
      <a className="btn" href={'sms:' + number}>
        <MessageCircle size={18} />
        Nhắn tin
      </a>
    </div>
  );
}
export function PhotoPicker({ label, files, onChange, required = false, multiple = true }) {
  const camera = useRef(null),
    picker = useRef(null),
    [urls, setUrls] = useState([]),
    [error, setError] = useState(null);
  useEffect(() => {
    const next = files.map((f) => URL.createObjectURL(f));
    setUrls(next);
    return () => next.forEach(URL.revokeObjectURL);
  }, [files]);
  function choose(event) {
    const selected = [...event.target.files];
    event.target.value = '';
    if (!selected.length) return;
    const next = multiple ? [...files, ...selected] : selected;
    if (
      next.length > (multiple ? 5 : 1) ||
      next.some((f) => !['image/jpeg', 'image/png'].includes(f.type) || f.size > 5242880)
    ) {
      setError(
        new Error('Chọn tối đa ' + (multiple ? 5 : 1) + ' ảnh JPG/PNG, mỗi ảnh không quá 5 MB.'),
      );
      return;
    }
    setError(null);
    onChange(next);
  }
  return (
    <div className="photo-picker">
      <b>
        {label}
        {required && ' *'}
      </b>
      <div className="image-grid">
        {urls.map((url, i) => (
          <div className="photo-preview" key={url}>
            <img src={url} alt={label + ' ' + (i + 1)} />
            <button
              type="button"
              className="btn small danger"
              aria-label={'Xóa ảnh ' + (i + 1)}
              onClick={() => onChange(files.filter((_, n) => n !== i))}
            >
              <Trash2 size={15} />
              Xóa ảnh
            </button>
          </div>
        ))}
      </div>
      <div className="actions">
        <button type="button" className="btn" onClick={() => camera.current.click()}>
          <Camera size={17} />
          Chụp ảnh
        </button>
        <button type="button" className="btn" onClick={() => picker.current.click()}>
          <ImagePlus size={17} />
          Thêm ảnh
        </button>
      </div>
      <input
        ref={camera}
        hidden
        type="file"
        accept="image/jpeg,image/png"
        capture="environment"
        onChange={choose}
      />
      <input
        ref={picker}
        aria-label={label}
        className="photo-file-input"
        type="file"
        accept="image/jpeg,image/png"
        multiple={multiple}
        onChange={choose}
      />
      <small>JPG/PNG, tối đa 5 MB mỗi ảnh.</small>
      <ErrorBox error={error} />
    </div>
  );
}
export function SignaturePad({ onChange }) {
  const canvas = useRef(null),
    drawing = useRef(false),
    dirty = useRef(false);
  useEffect(() => {
    const c = canvas.current.getContext('2d');
    c.fillStyle = '#fff';
    c.fillRect(0, 0, 800, 280);
  }, []);
  const point = (e) => {
    const r = canvas.current.getBoundingClientRect();
    return [
      ((e.clientX - r.left) * canvas.current.width) / r.width,
      ((e.clientY - r.top) * canvas.current.height) / r.height,
    ];
  };
  function finish() {
    if (!drawing.current) return;
    drawing.current = false;
    if (dirty.current)
      canvas.current.toBlob(
        (blob) => onChange(new File([blob], 'chu-ky.png', { type: 'image/png' })),
        'image/png',
      );
  }
  return (
    <div className="signature-field">
      <b>Chữ ký khách hàng</b>
      <p>Ký trực tiếp trong khung bên dưới.</p>
      <canvas
        ref={canvas}
        width={800}
        height={280}
        aria-label="Khung ký xác nhận nghiệm thu"
        onPointerDown={(e) => {
          e.preventDefault();
          canvas.current.setPointerCapture(e.pointerId);
          const c = canvas.current.getContext('2d');
          c.strokeStyle = '#173d30';
          c.lineWidth = 4;
          c.lineCap = 'round';
          c.beginPath();
          c.moveTo(...point(e));
          drawing.current = true;
        }}
        onPointerMove={(e) => {
          if (!drawing.current) return;
          const c = canvas.current.getContext('2d');
          c.lineTo(...point(e));
          c.stroke();
          dirty.current = true;
        }}
        onPointerUp={finish}
        onPointerCancel={finish}
      />
      <button
        type="button"
        className="btn small"
        onClick={() => {
          const c = canvas.current.getContext('2d');
          c.fillStyle = '#fff';
          c.fillRect(0, 0, 800, 280);
          dirty.current = false;
          onChange(null);
        }}
      >
        Ký lại
      </button>
    </div>
  );
}

export function PhotoPreview({ files, label = 'Ảnh thành phẩm' }) {
  const [urls, setUrls] = useState([]);
  useEffect(() => {
    const next = files.map((file) => URL.createObjectURL(file));
    setUrls(next);
    return () => next.forEach(URL.revokeObjectURL);
  }, [files]);
  return (
    <div className="image-grid">
      {urls.map((url, i) => (
        <img key={url} src={url} alt={label + ' ' + (i + 1)} />
      ))}
    </div>
  );
}
