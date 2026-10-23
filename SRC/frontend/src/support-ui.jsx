import React, { useEffect, useState } from "react";
import { api } from "./api";
import {
  useApp,
  useData,
  useAction,
  PageHead,
  Card,
  Field,
  ErrorBox,
  Loading,
  Empty,
  Submit,
  Modal,
  SearchField,
  matchesSearch,
  date,
  code,
  labels,
} from "./shared";

const active = (status) => ["Open", "InProgress"].includes(status);
const statusText = (status, customer) =>
  ({
    Open: customer ? "Đã gửi · Chờ CSKH tiếp nhận" : "Chờ tiếp nhận",
    InProgress: customer ? "CSKH đang xử lý" : "Đang xử lý",
    Resolved: "Đã giải quyết",
    Rejected: "Đã từ chối",
  })[status] || status;
function SupportStatus({ value, customer = false }) {
  return (
    <span
      className={
        "badge " +
        (value === "Resolved"
          ? "green"
          : value === "Rejected"
            ? "red"
            : "amber")
      }
    >
      {statusText(value, customer)}
    </span>
  );
}

export function SupportPage() {
  const { user } = useApp(),
    customer = user.role === "KH";
  const tickets = useData("/support/tickets", 10000);
  const [creating, setCreating] = useState(false),
    [selected, setSelected] = useState(null);
  const [search, setSearch] = useState(""),
    [status, setStatus] = useState(customer ? "all" : "active");
  const rows = (tickets.data || []).filter(
    (t) =>
      (status === "all" ||
        (status === "active" ? active(t.status) : t.status === status)) &&
      matchesSearch(search, [
        "HT-" + t.id,
        code(t.orderId),
        t.serviceName,
        t.customerName,
        t.customerPhone,
        t.description,
        t.handlerName,
        statusText(t.status, customer),
      ]),
  );
  return (
    <>
      <PageHead
        eyebrow={customer ? "HỖ TRỢ KHÁCH HÀNG" : "CHĂM SÓC KHÁCH HÀNG"}
        title={
          customer ? "Yêu cầu hỗ trợ của tôi" : "Tiếp nhận và xử lý hỗ trợ"
        }
        text={
          customer
            ? "Chọn đơn, gửi nội dung cần hỗ trợ và theo dõi phản hồi tại đây."
            : "Tiếp nhận phiếu, trao đổi với khách rồi ghi kết quả xử lý."
        }
      >
        {customer && (
          <button className="btn primary" onClick={() => setCreating(true)}>
            Chọn đơn cần hỗ trợ
          </button>
        )}
      </PageHead>
      <ErrorBox error={tickets.error} />
      <Card>
        <div className="filter-bar">
          <SearchField
            value={search}
            onChange={setSearch}
            placeholder={
              customer
                ? "Mã phiếu, mã đơn, dịch vụ, nội dung..."
                : "Mã phiếu, khách hàng, số điện thoại, mã đơn..."
            }
          />
          <Field label="Trạng thái">
            <select value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="all">Tất cả</option>
              <option value="active">Chưa kết thúc</option>
              {["Open", "InProgress", "Resolved", "Rejected"].map((v) => (
                <option key={v} value={v}>
                  {statusText(v, customer)}
                </option>
              ))}
            </select>
          </Field>
        </div>
        {tickets.loading ? (
          <Loading />
        ) : !rows.length ? (
          <Empty
            title="Không có yêu cầu phù hợp"
            text={
              customer
                ? "Phiếu chỉ được tạo khi bạn nhập nội dung và bấm Gửi yêu cầu."
                : "Thử chọn trạng thái khác."
            }
          />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Phiếu</th>
                  <th>Đơn dịch vụ</th>
                  {!customer && <th>Khách hàng</th>}
                  <th>Nội dung</th>
                  <th>Trạng thái</th>
                  {!customer && <th>Phụ trách</th>}
                  <th>Cập nhật</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((t) => (
                  <tr key={t.id}>
                    <td>
                      <b>HT-{t.id}</b>
                      <small>
                        {t.type === "Warranty"
                          ? "Bảo hành"
                          : "Hỗ trợ / khiếu nại"}
                      </small>
                    </td>
                    <td>
                      <b>{code(t.orderId)}</b>
                      <small>{t.serviceName}</small>
                    </td>
                    {!customer && (
                      <td>
                        {t.customerName}
                        <small>{t.customerPhone}</small>
                      </td>
                    )}
                    <td>{t.description}</td>
                    <td>
                      <SupportStatus value={t.status} customer={customer} />
                    </td>
                    {!customer && <td>{t.handlerName || "Chưa tiếp nhận"}</td>}
                    <td>{date(t.updatedAt || t.createdAt)}</td>
                    <td>
                      <button
                        className="btn small"
                        onClick={() => setSelected(t.id)}
                      >
                        {customer
                          ? "Xem phản hồi"
                          : t.status === "Open"
                            ? "Tiếp nhận / xem"
                            : active(t.status)
                              ? "Xử lý"
                              : "Xem kết quả"}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      {creating && (
        <SupportRequestModal
          onClose={() => setCreating(false)}
          onCreated={(ticket) => {
            setCreating(false);
            tickets.reload();
            setSelected(ticket.id);
          }}
        />
      )}
      {selected && (
        <SupportTicketModal
          id={selected}
          onClose={() => setSelected(null)}
          onUpdated={tickets.reload}
        />
      )}
    </>
  );
}

export function SupportRequestModal({ initialOrderId, onClose, onCreated }) {
  const orders = useData("/support/order-options"),
    action = useAction();
  const [orderId, setOrderId] = useState(String(initialOrderId || "")),
    [type, setType] = useState("Complaint");
  const [description, setDescription] = useState(""),
    [search, setSearch] = useState("");
  const order = orders.data?.find((o) => o.id === Number(orderId));
  const warranty =
    order?.status === "HoanThanh" &&
    order?.HanBaoHanh &&
    new Date(order.HanBaoHanh) >= new Date();
  useEffect(() => {
    if (!warranty) setType("Complaint");
  }, [warranty]);
  const options = (orders.data || []).filter(
    (o) =>
      o.id === Number(orderId) ||
      matchesSearch(search, [code(o.id), o.serviceName, o.address]),
  );
  return (
    <Modal
      title="Gửi yêu cầu hỗ trợ"
      onClose={() => {
        if (!action.busy) onClose();
      }}
    >
      <ErrorBox error={orders.error || action.error} />
      {orders.loading ? (
        <Loading />
      ) : !orders.data?.length ? (
        <Empty title="Bạn chưa có đơn dịch vụ để yêu cầu hỗ trợ" />
      ) : (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            action.run(async () => {
              const result = await api("/support/tickets", {
                method: "POST",
                body: {
                  orderId: Number(orderId),
                  type,
                  description: description.trim(),
                },
              });
              onCreated(result.data);
            }, "Đã gửi yêu cầu. CSKH sẽ tiếp nhận và phản hồi.");
          }}
        >
          {!initialOrderId && (
            <SearchField
              value={search}
              onChange={setSearch}
              placeholder="Tìm đơn theo mã, tên dịch vụ hoặc địa chỉ..."
            />
          )}
          <Field label="Đơn cần hỗ trợ">
            <select
              aria-label="Đơn cần hỗ trợ"
              required
              value={orderId}
              onChange={(e) => setOrderId(e.target.value)}
            >
              <option value="">Chọn đơn dịch vụ</option>
              {options.map((o) => (
                <option key={o.id} value={o.id}>
                  {code(o.id)} · {o.serviceName} · {labels[o.status]}
                </option>
              ))}
            </select>
          </Field>
          {order && (
            <p>
              <b>{order.serviceName}</b>
              <br />
              {order.address}
            </p>
          )}
          <Field label="Nội dung cần hỗ trợ">
            <select value={type} onChange={(e) => setType(e.target.value)}>
              <option value="Complaint">Hỗ trợ / khiếu nại về đơn</option>
              <option value="Warranty" disabled={!warranty}>
                Bảo hành vật tư
              </option>
            </select>
          </Field>
          <Field label="Mô tả yêu cầu">
            <textarea
              required
              minLength={10}
              maxLength={2000}
              rows={4}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </Field>
          <small>
            Bảo hành áp dụng cho đơn hoàn thành còn thời hạn bảo hành vật tư.
            Mỗi đơn chỉ có một phiếu cùng loại đang xử lý.
          </small>
          <div className="form-actions">
            <button
              type="button"
              className="btn"
              disabled={action.busy}
              onClick={onClose}
            >
              Quay lại
            </button>
            <Submit busy={action.busy} disabled={action.busy || !order}>
              Gửi yêu cầu
            </Submit>
          </div>
        </form>
      )}
    </Modal>
  );
}

export function SupportTicketModal({ id, onClose, onUpdated }) {
  const { user } = useApp(),
    customer = user.role === "KH";
  const ticket = useData("/support/tickets/" + id, 10000),
    action = useAction();
  const [message, setMessage] = useState(""),
    [closing, setClosing] = useState(null),
    [result, setResult] = useState("");
  const t = ticket.data;
  const responsible =
    user.role === "CSKH" && (!t?.handlerId || t.handlerId === user.id);
  async function update(path, method, body) {
    await api(path, { method, body });
    const fresh = await api("/support/tickets/" + id);
    ticket.setData(fresh.data);
    onUpdated?.();
  }
  const changeStatus = (status, resolution) =>
    action.run(async () => {
      await update("/support/tickets/" + id, "PATCH", {
        status,
        resolution,
        expectedVersion: t.version,
      });
      setClosing(null);
      setResult("");
    });
  return (
    <Modal
      title={(customer ? "Phản hồi phiếu " : "Xử lý phiếu ") + "HT-" + id}
      onClose={() => {
        if (!action.busy) onClose();
      }}
    >
      <ErrorBox error={ticket.error || action.error} />
      {ticket.loading ? (
        <Loading />
      ) : (
        t && (
          <>
            <p>
              <b>
                {code(t.orderId)} · {t.serviceName}
              </b>
              <br />
              {t.address}
            </p>
            {!customer && (
              <p>
                Khách hàng: <b>{t.customerName}</b> · {t.customerPhone}
              </p>
            )}
            <SupportStatus value={t.status} customer={customer} />
            <p className="pre-wrap">
              <b>Yêu cầu:</b> {t.description}
            </p>
            <small>
              {t.handlerName
                ? "CSKH phụ trách: " + t.handlerName
                : "Đang chờ CSKH tiếp nhận."}
            </small>
            <div className="timeline">
              {t.history.map((h) => (
                <div key={h.id}>
                  <span />
                  <section>
                    <b>
                      {h.authorRole === "KH" ? "Khách hàng" : "CSKH"} ·{" "}
                      {h.actorName}
                    </b>
                    {h.status && (
                      <p>
                        <SupportStatus value={h.status} customer={customer} />
                      </p>
                    )}
                    <p className="pre-wrap">{h.note}</p>
                    <small>{date(h.createdAt)}</small>
                  </section>
                </div>
              ))}
            </div>
            {t.resolution && !t.history.some((h) => h.status === t.status) && (
              <p className="pre-wrap">
                <b>Kết quả xử lý:</b> {t.resolution}
              </p>
            )}
            {!active(t.status) && (
              <p>Phiếu đã kết thúc. Nếu có vấn đề mới, hãy tạo yêu cầu khác.</p>
            )}
            {active(t.status) &&
              (customer || (responsible && t.status === "InProgress")) &&
              !closing && (
                <form
                  onSubmit={(e) => {
                    e.preventDefault();
                    action.run(async () => {
                      await update(
                        "/support/tickets/" + id + "/messages",
                        "POST",
                        { text: message.trim() },
                      );
                      setMessage("");
                    }, "Đã gửi phản hồi.");
                  }}
                >
                  <Field
                    label={
                      customer
                        ? "Thông tin bổ sung cho CSKH"
                        : "Phản hồi cho khách hàng"
                    }
                  >
                    <textarea
                      required
                      minLength={2}
                      maxLength={2000}
                      rows={3}
                      value={message}
                      onChange={(e) => setMessage(e.target.value)}
                    />
                  </Field>
                  <Submit busy={action.busy}>Gửi phản hồi</Submit>
                </form>
              )}
            {!customer && active(t.status) && !responsible && t.handlerName && (
              <p>Phiếu đang do {t.handlerName} xử lý.</p>
            )}
            {responsible && active(t.status) && !closing && (
              <div className="form-actions">
                {t.status === "Open" ? (
                  <button
                    className="btn primary"
                    disabled={action.busy}
                    onClick={() =>
                      changeStatus("InProgress", "CSKH đã tiếp nhận yêu cầu.")
                    }
                  >
                    Tiếp nhận
                  </button>
                ) : (
                  <button
                    className="btn primary"
                    disabled={action.busy}
                    onClick={() => setClosing("Resolved")}
                  >
                    Hoàn tất xử lý
                  </button>
                )}
                <button
                  className="btn danger"
                  disabled={action.busy}
                  onClick={() => setClosing("Rejected")}
                >
                  Từ chối yêu cầu
                </button>
              </div>
            )}
            {closing && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  changeStatus(closing, result.trim());
                }}
              >
                <Field
                  label={
                    closing === "Rejected" ? "Lý do từ chối" : "Kết quả xử lý"
                  }
                >
                  <textarea
                    required
                    minLength={5}
                    maxLength={2000}
                    rows={3}
                    value={result}
                    onChange={(e) => setResult(e.target.value)}
                  />
                </Field>
                <div className="form-actions">
                  <button
                    type="button"
                    className="btn"
                    disabled={action.busy}
                    onClick={() => setClosing(null)}
                  >
                    Quay lại trao đổi
                  </button>
                  <Submit busy={action.busy}>
                    {closing === "Rejected"
                      ? "Xác nhận từ chối"
                      : "Xác nhận hoàn tất"}
                  </Submit>
                </div>
              </form>
            )}
          </>
        )
      )}
    </Modal>
  );
}
