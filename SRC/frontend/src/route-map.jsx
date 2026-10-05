import React, { useEffect, useRef, useState } from 'react';
import { Navigation, MapPin } from 'lucide-react';
import { api } from './api';
import { Card, ErrorBox, date } from './shared';
export function RouteMap({ order, technician = false }) {
  const [position, setPosition] = useState(null),
    [error, setError] = useState(null),
    [retry, setRetry] = useState(0),
    [mapLoading, setMapLoading] = useState(true),
    [mapSlow, setMapSlow] = useState(false);
  const [customerPosition, setCustomerPosition] = useState(null),
    [customerError, setCustomerError] = useState(null),
    [updating, setUpdating] = useState(false),
    [saved, setSaved] = useState(false);
  const aliveRef = useRef(true),
    savingRef = useRef(false),
    generation = useRef(0);
  useEffect(() => {
    aliveRef.current = true;
    return () => {
      aliveRef.current = false;
    };
  }, []);
  useEffect(() => {
    const controller = new AbortController();
    let alive = true,
      running = false;
    setCustomerPosition(null);
    setCustomerError(null);
    setSaved(false);
    const load = async () => {
      if (running || savingRef.current) return;
      running = true;
      const stamp = generation.current;
      try {
        const r = await api('/orders/' + order.id + '/customer-location', {
          signal: controller.signal,
        });
        if (alive && stamp === generation.current && !savingRef.current) {
          setCustomerPosition(r.data);
          setCustomerError(null);
        }
      } catch (e) {
        if (alive && e.name !== 'AbortError') setCustomerError(e);
      } finally {
        running = false;
      }
    };
    load();
    const timer = setInterval(load, 10000);
    const visible = () => {
      if (document.visibilityState === 'visible') load();
    };
    window.addEventListener('focus', load);
    document.addEventListener('visibilitychange', visible);
    return () => {
      alive = false;
      controller.abort();
      clearInterval(timer);
      window.removeEventListener('focus', load);
      document.removeEventListener('visibilitychange', visible);
    };
  }, [order.id]);
  async function updateCustomerGps() {
    if (savingRef.current) return;
    if (!navigator.geolocation) {
      setCustomerError(new Error('Thiết bị không hỗ trợ GPS.'));
      return;
    }
    savingRef.current = true;
    generation.current++;
    setUpdating(true);
    setSaved(false);
    setCustomerError(null);
    try {
      const p = await new Promise((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(
          resolve,
          (e) =>
            reject(
              new Error(
                e.code === 1
                  ? 'Bạn cần cho phép truy cập vị trí để gửi GPS cho kỹ thuật viên.'
                  : 'Chưa lấy được GPS hiện tại. Vui lòng thử lại ở nơi có tín hiệu tốt hơn.',
              ),
            ),
          { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 },
        ),
      );
      if (!aliveRef.current) return;
      const r = await api('/orders/' + order.id + '/customer-location', {
        method: 'PATCH',
        body: {
          latitude: p.coords.latitude,
          longitude: p.coords.longitude,
          accuracyMeters: p.coords.accuracy,
        },
      });
      if (aliveRef.current) {
        setCustomerPosition(r.data);
        setSaved(true);
      }
    } catch (e) {
      if (aliveRef.current) setCustomerError(e);
    } finally {
      savingRef.current = false;
      if (aliveRef.current) setUpdating(false);
    }
  }
  const active = ['DaTiepNhan', 'DangDiChuyen', 'DaDenNoi', 'DangXuLy', 'ChoNghiemThu'].includes(
    order.status,
  );
  useEffect(() => {
    let alive = true,
      watch,
      timer,
      lastSent = 0,
      lastDisplayed = 0,
      sending = false;
    setPosition(null);
    setError(null);
    if (technician) {
      if (!navigator.geolocation) {
        setError(new Error('Thiết bị chưa hỗ trợ GPS. Bạn vẫn có thể mở chỉ đường bằng địa chỉ.'));
        return;
      }
      watch = navigator.geolocation.watchPosition(
        async (p) => {
          if (!alive) return;
          const value = {
            latitude: p.coords.latitude,
            longitude: p.coords.longitude,
            accuracyMeters: p.coords.accuracy,
          };
          if (Date.now() - lastDisplayed >= 30000) {
            setPosition({ ...value, positionUpdatedAt: new Date().toISOString() });
            lastDisplayed = Date.now();
          }
          if (!active || sending || Date.now() - lastSent < 15000) return;
          sending = true;
          try {
            await api('/technicians/me/location', { method: 'PATCH', body: value });
            lastSent = Date.now();
            if (alive) setError(null);
          } catch (e) {
            if (alive) setError(e);
          } finally {
            sending = false;
          }
        },
        () => {
          if (alive)
            setError(
              new Error(
                'Chưa lấy được GPS. Cho phép truy cập vị trí để xem tuyến đường và chia sẻ vị trí với khách.',
              ),
            );
        },
        { enableHighAccuracy: true, timeout: 15000, maximumAge: 10000 },
      );
    } else {
      const load = async () => {
        try {
          const r = await api('/orders/' + order.id + '/technician-location');
          if (alive) {
            setPosition(r.data);
            setError(null);
          }
        } catch (e) {
          if (alive) setError(e);
        }
      };
      load();
      timer = setInterval(load, 15000);
    }
    return () => {
      alive = false;
      if (watch !== undefined) navigator.geolocation.clearWatch(watch);
      clearInterval(timer);
    };
  }, [order.id, active, technician, retry]);
  const origin =
    position?.latitude != null && position?.longitude != null
      ? `${position.latitude},${position.longitude}`
      : '';
  const destination =
    customerPosition?.latitude != null && customerPosition?.longitude != null
      ? `${customerPosition.latitude},${customerPosition.longitude}`
      : order.address;
  const direction = new URLSearchParams({
    api: '1',
    destination,
    travelmode: 'driving',
    ...(origin ? { origin } : {}),
  });
  const embed = new URLSearchParams(
    origin
      ? { saddr: origin, daddr: destination, output: 'embed' }
      : { q: destination, output: 'embed' },
  );
  const mapSource = 'https://www.google.com/maps?' + embed;
  useEffect(() => {
    setMapLoading(true);
    setMapSlow(false);
    const timer = setTimeout(() => setMapSlow(true), 15000);
    return () => clearTimeout(timer);
  }, [mapSource]);
  return (
    <Card
      title={technician ? 'Đường đến khách hàng' : 'Vị trí kỹ thuật viên'}
      className="route-card"
    >
      {mapLoading && (
        <div className="notice info" role="status">
          {mapSlow
            ? technician
              ? 'Bản đồ đang tải chậm. Bạn có thể dùng nút Mở chỉ đường bên dưới.'
              : 'Bản đồ đang tải chậm. Bạn vẫn có thể gửi GPS bằng nút bên dưới.'
            : 'Đang tải bản đồ và tuyến đường…'}
        </div>
      )}
      <iframe
        onLoad={() => setMapLoading(false)}
        title="Bản đồ vị trí và tuyến đường tới khách hàng"
        src={mapSource}
        loading="lazy"
        referrerPolicy="no-referrer-when-downgrade"
        allowFullScreen
      />
      <p>
        <MapPin size={16} /> Địa chỉ đặt dịch vụ: {order.address}
      </p>
      <small>
        {customerPosition
          ? `Điểm đến theo GPS khách gửi lúc ${date(customerPosition.positionUpdatedAt)} · Sai số khoảng ${Math.round(customerPosition.accuracyMeters)} m`
          : 'Chưa có GPS khách hàng; điểm đến đang dùng địa chỉ đặt dịch vụ.'}
      </small>
      <small>
        {origin
          ? `Vị trí thợ cập nhật ${date(position.positionUpdatedAt)}${position.accuracyMeters != null ? ' · Sai số khoảng ' + Math.round(position.accuracyMeters) + ' m' : ''}`
          : 'Đang hiển thị địa chỉ khách; chưa có vị trí GPS của thợ.'}
      </small>
      <ErrorBox error={error || customerError} />
      {saved && !technician && (
        <div className="notice success" role="status">
          Đã gửi vị trí hiện tại. Bản đồ của kỹ thuật viên sẽ tự cập nhật điểm đến.
        </div>
      )}
      <div className="actions">
        {technician ? (
          <>
            <a
              className="btn primary"
              href={'https://www.google.com/maps/dir/?' + direction}
              target="_blank"
              rel="noreferrer"
            >
              <Navigation size={18} />
              Mở chỉ đường
            </a>
            <button className="btn" onClick={() => setRetry((v) => v + 1)}>
              Cập nhật GPS
            </button>
          </>
        ) : (
          <button className="btn primary" disabled={updating} onClick={updateCustomerGps}>
            <MapPin size={18} />
            {updating ? 'Đang cập nhật vị trí…' : 'Cập nhật GPS của tôi'}
          </button>
        )}
      </div>
      {!technician && (
        <small>
          Khi bạn di chuyển, bấm nút để gửi vị trí mới cho thợ. GPS chỉ được lấy khi bạn bấm cập
          nhật.
        </small>
      )}
      {technician && (
        <small>
          {active
            ? 'Vị trí được chia sẻ khi màn hình đơn đang mở và bạn cho phép GPS.'
            : 'GPS dùng để xem đường; bắt đầu chia sẻ với khách sau khi nhận đơn.'}
        </small>
      )}
    </Card>
  );
}
