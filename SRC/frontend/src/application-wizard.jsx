import React, { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, upload } from './api';
import { useApp, useAction, Card, Field, ErrorBox, Submit, groups } from './shared';
import { PhotoPicker } from './technician-ui';
export function ApplicationWizard({ onDone }) {
  const { user } = useApp(),
    a = useAction(),
    [step, setStep] = useState(0),
    [form, setForm] = useState({
      serviceArea: '',
      experience: '',
      skillGroup: '',
      years: '',
      equipment: '',
      certificates: '',
      vehicle: '',
      identityNumber: '',
      agreed: false,
    }),
    [front, setFront] = useState([]),
    [back, setBack] = useState([]),
    cache = useRef(new Map());
  const set = (key, value) => setForm((v) => ({ ...v, [key]: value }));
  async function submit(e) {
    e.preventDefault();
    a.setError(null);
    if (step === 2 && (!front.length || !back.length)) {
      a.setError(new Error('Cần ảnh CCCD mặt trước và mặt sau.'));
      return;
    }
    if (step < 3) {
      setStep(step + 1);
      return;
    }
    await a.run(async () => {
      if (!form.agreed) throw new Error('Vui lòng xác nhận thông tin và điều khoản.');
      for (const file of [front[0], back[0]])
        if (!cache.current.has(file))
          cache.current.set(file, (await upload(file, 'TechnicianDocument')).id);
      await api('/technician-applications', {
        method: 'POST',
        body: {
          skillGroup: form.skillGroup,
          serviceArea: form.serviceArea,
          experience: form.experience,
          identityNumber: form.identityNumber,
          frontDocumentId: cache.current.get(front[0]),
          backDocumentId: cache.current.get(back[0]),
          profile: {
            years: Number(form.years),
            equipment: form.equipment,
            certificates: form.certificates,
            vehicle: form.vehicle,
          },
        },
      });
      onDone();
    }, 'Đã gửi hồ sơ. Vui lòng chờ quản trị viên xét duyệt.');
  }
  return (
    <Card title="Đăng ký hồ sơ kỹ thuật viên">
      <div className="wizard-steps">
        {['Thông tin', 'Chuyên môn', 'Giấy tờ', 'Hoàn thành'].map((name, i) => (
          <div
            key={name}
            className={step === i ? 'active' : step > i ? 'done' : ''}
            aria-current={step === i ? 'step' : undefined}
          >
            <span>{i + 1}</span>
            {name}
          </div>
        ))}
      </div>
      <form onSubmit={submit}>
        <ErrorBox error={a.error} />
        {step === 0 && (
          <>
            <div className="form-grid">
              <Field label="Họ và tên">
                <input readOnly value={user.fullName} />
              </Field>
              <Field label="Mã kỹ thuật viên">
                <input readOnly value="Tự động cấp sau khi hồ sơ được duyệt" />
              </Field>
              <Field label="Số điện thoại">
                <input readOnly value={user.phone} />
              </Field>
              <Field label="Khu vực hoạt động">
                <input
                  required
                  list="service-areas"
                  maxLength={120}
                  value={form.serviceArea}
                  onChange={(e) => set('serviceArea', e.target.value)}
                />
                <datalist id="service-areas">
                  {['TP.HCM', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ', 'Huế'].map((v) => (
                    <option key={v} value={v} />
                  ))}
                </datalist>
              </Field>
            </div>
            <small>
              Thông tin liên hệ lấy từ tài khoản đã xác thực.{' '}
              <Link to="/profile">Cập nhật hồ sơ cá nhân</Link>
            </small>
            <Field label="Mô tả kinh nghiệm làm việc">
              <textarea
                required
                minLength={10}
                maxLength={2000}
                value={form.experience}
                onChange={(e) => set('experience', e.target.value)}
              />
            </Field>
          </>
        )}
        {step === 1 && (
          <div className="form-grid">
            <Field label="Lĩnh vực chuyên môn">
              <select
                required
                value={form.skillGroup}
                onChange={(e) => set('skillGroup', e.target.value)}
              >
                <option value="">Chọn chuyên môn</option>
                {Object.entries(groups).map(([key, name]) => (
                  <option key={key} value={key}>
                    {name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Số năm kinh nghiệm">
              <input
                required
                type="number"
                min="0"
                max="60"
                step="1"
                value={form.years}
                onChange={(e) => set('years', e.target.value)}
              />
            </Field>
            <Field label="Thiết bị chuyên sâu">
              <input
                required
                maxLength={300}
                value={form.equipment}
                onChange={(e) => set('equipment', e.target.value)}
              />
            </Field>
            <Field label="Phạm vi phục vụ">
              <input
                required
                maxLength={120}
                value={form.serviceArea}
                onChange={(e) => set('serviceArea', e.target.value)}
              />
            </Field>
            <Field label="Chứng chỉ liên quan (nếu có)">
              <input
                maxLength={300}
                placeholder="Không có hoặc tên chứng chỉ"
                value={form.certificates}
                onChange={(e) => set('certificates', e.target.value)}
              />
            </Field>
            <Field label="Phương tiện di chuyển">
              <select
                required
                value={form.vehicle}
                onChange={(e) => set('vehicle', e.target.value)}
              >
                <option value="">Chọn phương tiện</option>
                {['Xe máy', 'Ô tô', 'Xe đạp điện', 'Phương tiện khác'].map((v) => (
                  <option key={v}>{v}</option>
                ))}
              </select>
            </Field>
          </div>
        )}
        {step === 2 && (
          <>
            <Field label="Số CCCD">
              <input
                required
                pattern="[0-9]{12}"
                inputMode="numeric"
                maxLength={12}
                value={form.identityNumber}
                onChange={(e) => set('identityNumber', e.target.value)}
                placeholder="12 chữ số"
              />
            </Field>
            <div className="form-grid">
              <PhotoPicker
                label="CCCD mặt trước"
                required
                files={front}
                multiple={false}
                onChange={setFront}
              />
              <PhotoPicker
                label="CCCD mặt sau"
                required
                files={back}
                multiple={false}
                onChange={setBack}
              />
            </div>
            <small>Giấy tờ chỉ được người nộp và quản trị viên xét duyệt truy cập.</small>
          </>
        )}
        {step === 3 && (
          <div className="application-review">
            <h3>Kiểm tra thông tin trước khi gửi</h3>
            <dl>
              <dt>Người nộp</dt>
              <dd>
                {user.fullName} · {user.phone}
              </dd>
              <dt>Chuyên môn</dt>
              <dd>
                {groups[form.skillGroup]} · {form.years} năm
              </dd>
              <dt>Khu vực</dt>
              <dd>{form.serviceArea}</dd>
              <dt>Thiết bị chuyên sâu</dt>
              <dd>{form.equipment}</dd>
              <dt>Chứng chỉ</dt>
              <dd>{form.certificates || 'Không có'}</dd>
              <dt>Phương tiện</dt>
              <dd>{form.vehicle}</dd>
              <dt>Giấy tờ</dt>
              <dd>Đã chọn đủ hai mặt CCCD</dd>
            </dl>
            <p className="pre-wrap">{form.experience}</p>
            <label className="checkbox">
              <input
                type="checkbox"
                required
                checked={form.agreed}
                onChange={(e) => set('agreed', e.target.checked)}
              />
              Tôi xác nhận thông tin chính xác và đồng ý quy định vận hành: chỉ nhận việc đúng
              chuyên môn, liên hệ khách sau khi nhận đơn và chờ khách duyệt mọi vật tư phát sinh.
            </label>
          </div>
        )}
        <div className="form-actions">
          {step > 0 && (
            <button
              className="btn"
              type="button"
              disabled={a.busy}
              onClick={() => {
                a.setError(null);
                setStep(step - 1);
              }}
            >
              Quay lại
            </button>
          )}
          <Submit busy={a.busy} disabled={a.busy || (step === 3 && !form.agreed)}>
            {step === 3 ? 'Gửi hồ sơ' : 'Tiếp tục'}
          </Submit>
        </div>
      </form>
    </Card>
  );
}
