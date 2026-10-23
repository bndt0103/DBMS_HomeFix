import { SupportRequestModal } from "./support-ui";
import {
  ContactActions,
  PhotoPicker,
  PhotoPreview,
  SignaturePad,
} from "./technician-ui";
import { noPaymentDue, displayPaymentStatus } from "./payment-status";
import { AttentionDot } from "./attention";
import React, { useEffect, useRef, useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import {
  ArrowLeft,
  ArrowRight,
  MapPin,
  Phone,
  Clock,
  Plus,
  Trash2,
  RefreshCw,
  ShieldCheck,
  CheckCircle2,
  Receipt,
  Navigation,
  Star,
} from "lucide-react";
import { PaymentPanel, PaymentMethodFields } from "./payments-ui";
import { api, upload, uuid } from "./api";
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
  Badge,
  money,
  date,
  code,
  labels,
  ProtectedImage,
  MoneyBreakdown,
  Modal,
} from "./shared";
export function OrderDetail() {
  const { id } = useParams(),
    { user } = useApp(),
    navigate = useNavigate();
  const order = useData("/orders/" + id, 10000),
    history = useData("/orders/" + id + "/history"),
    materials = useData("/orders/" + id + "/materials"),
    acceptances = useData("/orders/" + id + "/acceptances"),
    files = useData(
      user.role === "KT" ? null : "/orders/" + id + "/attachments",
    ),
    reviews = useData("/orders/" + id + "/reviews"),
    cfg = useData("/app-config");
  const [modal, setModal] = useState(null);
  const o = order.data;
  const refresh = () => {
    order.reload();
    history.reload();
    materials.reload();
    acceptances.reload();
    files.reload();
    reviews.reload();
  };
  useEffect(() => {
    if (o?.version) {
      history.reload();
      materials.reload();
      acceptances.reload();
      files.reload();
      reviews.reload();
    }
  }, [o?.version]);
  const open = (type, record) =>
    setModal({ type, record, expectedVersion: o.version });
  if (order.loading) return <Loading />;
  if (order.error)
    return (
      <>
        <ErrorBox error={order.error} />
        <Link className="btn" to="/orders">
          Quay lại danh sách
        </Link>
      </>
    );
  if (!o) return null;
  const preliminary = o.currentPreliminaryQuote,
    acceptance = acceptances.data?.[0],
    assignment = o.currentAssignment;
  const customer = user.role === "KH",
    tech = user.role === "KTV",
    dispatcher = user.role === "DPV";
  const currentTech = tech && o.assignedTechnicianId === user.id;
  const actions = [];
  if (dispatcher && o.status === "ChoTiepNhan")
    actions.push(["preliminary", "Lập báo giá sơ bộ"]);
  if (dispatcher && ["ChoDuyetSoBo", "ChoPhanCong"].includes(o.status))
    actions.push(["preliminary", "Điều chỉnh báo giá sơ bộ"]);
  if (dispatcher && o.status === "ChoPhanCong")
    actions.push(["assign", "Phân công kỹ thuật viên"]);
  const pendingAssignment =
    currentTech && o.status === "ChoNhan" && assignment?.status === "Pending";
  const next = {
    DaTiepNhan: ["DangDiChuyen", "Bắt đầu di chuyển"],
    DangDiChuyen: ["DaDenNoi", "Xác nhận đã đến nơi"],
    DaDenNoi: ["DangXuLy", "Bắt đầu xử lý"],
  };
  if (currentTech && next[o.status])
    actions.push(["progress", next[o.status][1]]);
  if (currentTech && o.status === "DangXuLy") {
    actions.push(["material", "Kê khai vật tư"]);
    actions.push(["acceptance", "Hoàn thành · Lập phiếu nghiệm thu"]);
  }
  if (
    currentTech &&
    o.status === "ChoNghiemThu" &&
    acceptance?.status === "Approved" &&
    o.paymentStatus === "Unpaid" &&
    !noPaymentDue(o) &&
    (o.paymentMethod || "COD") === "COD"
  )
    actions.push(["cod", "Xác nhận đã thu COD"]);
  const techStep = ["DaTiepNhan", "DangDiChuyen"].includes(o.status)
    ? 0
    : o.status === "DaDenNoi"
      ? 1
      : ["DangXuLy", "ChoNghiemThu"].includes(o.status)
        ? 2
        : o.status === "HoanThanh"
          ? 3
          : -1;
  const step = [
    "ChoTiepNhan",
    "ChoDuyetSoBo",
    "ChoPhanCong",
    "ChoNhan",
  ].includes(o.status)
    ? 0
    : ["DaTiepNhan", "DangDiChuyen"].includes(o.status)
      ? 1
      : ["DaDenNoi", "DangXuLy", "ChoNghiemThu"].includes(o.status)
        ? 2
        : 3;
  return (
    <>
      <Link to="/orders" className="back-link">
        <ArrowLeft size={16} /> Danh sách đơn dịch vụ
      </Link>
      <PageHead
        eyebrow={code(o.id)}
        title={o.serviceName}
        text={"Tạo lúc " + date(o.createdAt)}
      >
        <Badge value={o.status} />
        <span
          title={
            noPaymentDue(o)
              ? "Không phát sinh chi phí cần thanh toán"
              : undefined
          }
        >
          <Badge value={displayPaymentStatus(o)} />
        </span>
        <button className="icon-btn" onClick={refresh} aria-label="Tải lại đơn">
          <RefreshCw size={19} />
        </button>
      </PageHead>
      {o.status === "Huy" && (
        <Card title="Đơn dịch vụ đã hủy">
          {Number(o.cancellationFee) > 0 ? (
            <>
              <p>
                Phí di chuyển của KTV: <b>{money(o.cancellationFee)}</b>. Thanh
                toán bằng chuyển khoản cho HomeFix.
              </p>
              <PaymentPanel order={o} onRefresh={refresh} />
            </>
          ) : (
            <p>Đơn được hủy trước khi KTV di chuyển. Không phát sinh phí.</p>
          )}
        </Card>
      )}
      {o.status !== "Huy" && (
        <div className="order-stepper">
          {(tech
            ? ["Đã nhận", "Đến nơi", "Đang làm", "Hoàn thành"]
            : ["Tiếp nhận", "Di chuyển", "Xử lý", "Hoàn thành"]
          ).map((s, i) => (
            <div
              key={s}
              className={i <= (tech ? techStep : step) ? "done" : ""}
            >
              <span>
                {i < (tech ? techStep : step) ? (
                  <CheckCircle2 size={18} />
                ) : (
                  i + 1
                )}
              </span>
              <b>{s}</b>
            </div>
          ))}
        </div>
      )}
      {pendingAssignment && (
        <section className="assignment-response">
          <div>
            <b>Đơn mới cần phản hồi</b>
            <p>Kiểm tra địa chỉ, mô tả và báo giá trước khi quyết định.</p>
          </div>
          <div className="contact-actions">
            <button
              className="btn reject-order"
              onClick={() => open("receive", { decision: "Rejected" })}
            >
              Từ chối đơn
            </button>
            <button
              className="btn accept-order"
              onClick={() => open("receive", { decision: "Accepted" })}
            >
              <CheckCircle2 size={18} />
              Chấp nhận đơn
            </button>
          </div>
        </section>
      )}
      {actions.length > 0 && (
        <div className="next-action">
          <div>
            <ShieldCheck size={23} />
            <div>
              <b>Bước tiếp theo</b>
              <small>Thực hiện sau khi kiểm tra thông tin công việc.</small>
            </div>
          </div>
          <div className="actions">
            {actions.map(([type, title], i) => (
              <button
                key={type}
                className={"btn " + (i === actions.length - 1 ? "primary" : "")}
                onClick={() => open(type)}
              >
                <AttentionDot />
                {title} <ArrowRight size={16} />
              </button>
            ))}
          </div>
        </div>
      )}
      {o.status === "ChoNhan" &&
        assignment?.status === "Pending" &&
        (dispatcher || currentTech) && <AssignmentNotice />}
      {customer && o.status === "ChoDuyetSoBo" && preliminary && (
        <Card title="Báo giá sơ bộ cần bạn xác nhận" className="highlight">
          {preliminary.diagnosis && (
            <p>
              <b>Chẩn đoán sơ bộ:</b> {preliminary.diagnosis}
            </p>
          )}
          <MoneyBreakdown value={preliminary} />
          <div className="actions">
            <button
              className="btn danger"
              onClick={() => open("reject-preliminary", preliminary)}
            >
              Từ chối báo giá
            </button>
            <button
              className="btn primary"
              onClick={() => open("approve-preliminary", preliminary)}
            >
              <AttentionDot />
              Đồng ý báo giá
            </button>
          </div>
        </Card>
      )}
      {customer &&
        o.status === "ChoNghiemThu" &&
        acceptance?.status === "Pending" && (
          <div className="notice warning">
            <ShieldCheck />
            <div>
              Thợ đã gửi phiếu nghiệm thu. Hãy kiểm tra thiết bị và xác nhận ở
              phần nghiệm thu bên dưới.
            </div>
          </div>
        )}
      <div className="two-column order-layout">
        <div>
          <Card title="Thông tin dịch vụ">
            <div className="detail-facts">
              <div>
                <MapPin />
                <p>
                  <small>Địa chỉ thực hiện</small>
                  <b>{o.address}</b>
                </p>
              </div>
              <div>
                <Clock />
                <p>
                  <small>Thời gian hẹn</small>
                  <b>{date(o.scheduledAt)}</b>
                </p>
              </div>
              <div>
                <Phone />
                <p>
                  <small>Khách hàng</small>
                  <b>
                    {o.contactName} ·{" "}
                    <a href={"tel:" + o.contactPhone}>{o.contactPhone}</a>
                  </b>
                </p>
              </div>
            </div>
            <div className="divider" />
            {currentTech && <ContactActions phone={o.contactPhone} />}
            <h3>Mô tả tình trạng</h3>
            <p className="pre-wrap">{o.description}</p>
            {o.technicianName && (
              <p>
                <b>Kỹ thuật viên:</b> {o.technicianName}
              </p>
            )}
            {files.data?.some((f) => f.purpose === "OrderFault") && (
              <div className="image-grid">
                {files.data
                  .filter((f) => f.purpose === "OrderFault")
                  .map((f) => (
                    <ProtectedImage
                      key={f.id}
                      id={f.id}
                      alt="Ảnh lỗi thiết bị"
                    />
                  ))}
              </div>
            )}
            {files.data?.some((f) => f.purpose === "MaterialEvidence") && (
              <>
                <h3>Ảnh hiện trạng / vật tư</h3>
                <div className="image-grid">
                  {files.data
                    .filter((f) => f.purpose === "MaterialEvidence")
                    .map((f) => (
                      <ProtectedImage key={f.id} id={f.id} alt="Ảnh vật tư" />
                    ))}
                </div>
              </>
            )}
          </Card>
          {preliminary && !(customer && o.status === "ChoDuyetSoBo") && (
            <Card
              title={
                o.status === "Huy"
                  ? "Báo giá tham khảo trước khi hủy"
                  : "Báo giá sơ bộ"
              }
            >
              <Badge value={preliminary.status} />
              {preliminary.status === "Rejected" ? (
                <p>
                  Lý do hủy:{" "}
                  {preliminary.reason
                    ? preliminary.reason.trim()
                    : "Khách hàng từ chối báo giá"}
                </p>
              ) : (
                preliminary.diagnosis && <p>{preliminary.diagnosis}</p>
              )}
              <MoneyBreakdown value={preliminary} />
            </Card>
          )}
          {materials.data?.map((m) => (
            <Card key={m.id} title={"Vật tư kê khai · Phiên bản " + m.revision}>
              <div className="row space">
                <span>{m.isCurrent ? "Đang áp dụng" : "Phiên bản cũ"}</span>
                <small>{date(m.createdAt)}</small>
              </div>
              {m.note && <p>{m.note}</p>}
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Vật tư</th>
                      <th>SL</th>
                      <th>Đơn giá</th>
                      <th>Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody>
                    {m.items?.map((item) => (
                      <tr key={item.id}>
                        <td>
                          <b>{item.name}</b>
                          <small>Bảo hành {item.warrantyMonths} tháng</small>
                        </td>
                        <td>{Number(item.quantity)}</td>
                        <td>{money(item.unitPrice)}</td>
                        <td>{money(item.lineTotal)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="row space total-line">
                <b>Tổng vật tư</b>
                <strong>{money(m.total)}</strong>
              </div>
            </Card>
          ))}
          {acceptances.data?.map((a) => (
            <Card
              key={a.id}
              title={"Phiếu nghiệm thu · Phiên bản " + a.revision}
            >
              <Badge value={a.status} />
              <h3>Nguyên nhân</h3>
              <p className="pre-wrap">{a.cause}</p>
              <h3>Biện pháp xử lý</h3>
              <p className="pre-wrap">{a.solution}</p>
              {user.role !== "KT" && (
                <div className="image-grid">
                  {a.photos?.map((p) => (
                    <ProtectedImage
                      key={p.id}
                      id={p.id}
                      alt="Ảnh sau sửa chữa"
                    />
                  ))}
                </div>
              )}
              <MoneyBreakdown value={a} />
              {a.proposedPaymentMethod && (
                <p>
                  Thanh toán dự kiến:{" "}
                  {a.proposedPaymentMethod === "BANK"
                    ? "Chuyển khoản"
                    : "Tiền mặt"}
                </p>
              )}
              {a.signatureId && user.role !== "KT" && (
                <>
                  <h3>Chữ ký khách hàng</h3>
                  <div className="image-grid">
                    <ProtectedImage
                      id={a.signatureId}
                      alt="Chữ ký trên phiếu nghiệm thu"
                    />
                  </div>
                </>
              )}
              {a.technicianSignatureId && user.role !== "KT" && (
                <>
                  <h3>Chữ ký kỹ thuật viên</h3>
                  <div className="image-grid">
                    <ProtectedImage
                      id={a.technicianSignatureId}
                      alt="Chữ ký kỹ thuật viên trên phiếu nghiệm thu"
                    />
                  </div>
                </>
              )}
              {a.reason && <p>Lý do yêu cầu sửa lại: {a.reason}</p>}
              {customer &&
                a.status === "Pending" &&
                o.status === "ChoNghiemThu" && (
                  <div className="actions">
                    <button
                      className="btn danger"
                      onClick={() => open("reject-acceptance", a)}
                    >
                      Yêu cầu xử lý lại
                    </button>
                    <button
                      className="btn primary"
                      onClick={() => open("approve-acceptance", a)}
                    >
                      <AttentionDot />
                      Xác nhận nghiệm thu
                    </button>
                  </div>
                )}
            </Card>
          ))}
          {["ChoNghiemThu", "HoanThanh"].includes(o.status) &&
            acceptance?.status === "Approved" && (
              <Card title="Thanh toán & đánh giá">
                <PaymentPanel order={o} onRefresh={refresh} />
                {customer &&
                  o.paymentStatus === "Paid" &&
                  !reviews.data?.length && (
                    <button
                      className="btn primary"
                      onClick={() => open("review")}
                    >
                      <Star size={17} /> Đánh giá dịch vụ
                    </button>
                  )}
                {reviews.data?.map((r) => (
                  <div className="review" key={r.id}>
                    <div className="stars">
                      {"★".repeat(r.rating)}
                      {"☆".repeat(5 - r.rating)}
                    </div>
                    <p>{r.comment || "Khách đã đánh giá dịch vụ."}</p>
                    <small>{date(r.createdAt)}</small>
                  </div>
                ))}
              </Card>
            )}
          {o.status === "Huy" && (
            <Card title="Thông tin hủy đơn">
              <p>
                <b>Lý do hủy:</b>{" "}
                {o.cancelReason ||
                  history.data
                    ?.slice()
                    ?.reverse()
                    ?.find(
                      (h) => h.toStatus === "Huy" || h.nextStatus === "Huy",
                    )?.reason ||
                  "Khách hàng hủy đơn."}
              </p>
              {o.cancellationFee > 0 && (
                <p>
                  <b>Phí hủy đơn:</b> {money(o.cancellationFee)}
                </p>
              )}
            </Card>
          )}
        </div>
        <aside>
          <Card title="Lịch sử xử lý">
            <div className="timeline">
              {history.data?.map((h) => (
                <div key={h.id}>
                  <span />
                  <section>
                    <b>{labels[h.toStatus] || h.toStatus}</b>
                    <p>{h.reason}</p>
                    <small>
                      {date(h.happenedAt || h.createdAt)}
                      {h.actorName ? " · " + h.actorName : ""}
                    </small>
                  </section>
                </div>
              ))}
            </div>
          </Card>
          {dispatcher && (
            <Card title="Ghi chú điều phối">
              <p>Lưu nội dung chẩn đoán từ ảnh hoặc trao đổi qua điện thoại.</p>
              <button className="btn" onClick={() => open("note")}>
                Thêm ghi chú
              </button>
              <Notes orderId={id} version={o.version} />
            </Card>
          )}
          {customer && (
            <Card title="Thông tin từ điều phối">
              <Notes orderId={id} version={o.version} />
            </Card>
          )}
          {customer && (
            <Card title="Cần hỗ trợ thêm?">
              <p>
                Gửi yêu cầu khiếu nại hoặc bảo hành để bộ phận chăm sóc khách
                hàng tiếp nhận.
              </p>
              <button className="btn" onClick={() => open("support")}>
                Gửi yêu cầu hỗ trợ
              </button>
            </Card>
          )}
          {((customer &&
            [
              "ChoTiepNhan",
              "ChoDuyetSoBo",
              "ChoPhanCong",
              "ChoNhan",
              "DaTiepNhan",
              "DangDiChuyen",
              "DaDenNoi",
            ].includes(o.status)) ||
            (dispatcher &&
              [
                "ChoTiepNhan",
                "ChoDuyetSoBo",
                "ChoPhanCong",
                "ChoNhan",
                "DaTiepNhan",
                "DangDiChuyen",
                "DaDenNoi",
              ].includes(o.status))) && (
            <button className="btn danger full" onClick={() => open("cancel")}>
              Hủy yêu cầu dịch vụ
            </button>
          )}
        </aside>
      </div>
      {modal?.type === "support" && (
        <SupportRequestModal
          initialOrderId={o.id}
          onClose={() => setModal(null)}
          onCreated={() => setModal(null)}
        />
      )}
      {modal && modal.type !== "support" && (
        <ActionModal
          modal={modal}
          order={o}
          config={cfg.data}
          next={next[o.status]}
          onClose={() => setModal(null)}
          onDone={async () => {
            const declined =
              modal.type === "receive" && modal.record?.decision === "Rejected";
            if (declined) {
              setModal(null);
              navigate("/orders");
              return;
            }
            // Chỉ đóng form khi đã nhận phiên bản mới để thao tác kế tiếp không dùng dữ liệu cũ.
            const [freshOrder, freshMaterials, freshAcceptances] =
              await Promise.all([
                api("/orders/" + id),
                api("/orders/" + id + "/materials"),
                api("/orders/" + id + "/acceptances"),
              ]);
            order.setData(freshOrder.data);
            materials.setData(freshMaterials.data);
            acceptances.setData(freshAcceptances.data);
            history.reload();
            files.reload();
            reviews.reload();
            setModal(null);
          }}
        />
      )}
    </>
  );
}
function Notes({ orderId, version }) {
  const n = useData("/orders/" + orderId + "/notes");
  useEffect(() => {
    n.reload();
  }, [version]);
  return (
    <div className="notes">
      {n.data?.map((note) => (
        <article key={note.id}>
          <b>
            {note.visibility === "Internal" ? "Nội bộ" : "Khách có thể xem"}
          </b>
          <p>{note.text}</p>
          <small>{date(note.createdAt)}</small>
        </article>
      ))}
    </div>
  );
}
function AssignmentNotice() {
  return <p className="assignment-pending">Chờ kỹ thuật viên phản hồi.</p>;
}

const titles = {
  preliminary: "Lập báo giá sơ bộ",
  assign: "Phân công kỹ thuật viên",
  receive: "Phản hồi lệnh công việc",
  progress: "Cập nhật tiến độ",
  material: "Kê khai vật tư",
  acceptance: "Lập phiếu nghiệm thu",
  cod: "Xác nhận thu tiền mặt",
  review: "Đánh giá dịch vụ",
  support: "Gửi yêu cầu hỗ trợ",
  cancel: "Hủy yêu cầu dịch vụ",
  note: "Ghi chú điều phối",
  "approve-preliminary": "Đồng ý báo giá",
  "reject-preliminary": "Từ chối báo giá",
  "approve-acceptance": "Xác nhận nghiệm thu",
  "reject-acceptance": "Yêu cầu xử lý lại",
};
function ActionModal({ modal, order, config, next, onClose, onDone }) {
  const a = useAction(),
    { type, record, expectedVersion } = modal;
  const [form, setForm] = useState({
    diagnosis: order.currentPreliminaryQuote?.diagnosis || "",
    inspectionFee:
      order.currentPreliminaryQuote?.inspectionFee ?? order.inspectionFee,
    laborFee: order.currentPreliminaryQuote?.laborFee ?? order.laborFee,
    reason: "",
    technicianId: "",
    decision: record?.decision || "Accepted",
    reasonChoice: "",
    cause: "",
    solution: "",
    note: "",
    rating: "5",
    comment: "",
    visibility: "Internal",
    confirmed: false,
    paymentMethod: record?.proposedPaymentMethod || "COD",
    bankAccountId: "",
  });
  const [items, setItems] = useState([
      {
        name: "",
        quantity: "1",
        unitPrice: "",
        warrantyMonths: 0,
      },
    ]),
    [files, setFiles] = useState([]);
  const [preview, setPreview] = useState(false),
    [capturedSignature, setCapturedSignature] = useState(null);
  const currentMaterials = useData(
    ["material", "acceptance"].includes(type)
      ? "/orders/" + order.id + "/materials"
      : null,
  );
  const materialInitialized = useRef(false);
  useEffect(() => {
    if (
      type !== "material" ||
      !currentMaterials.data ||
      materialInitialized.current
    )
      return;
    materialInitialized.current = true;
    const current = currentMaterials.data.find((row) => row.isCurrent);
    if (current?.items?.length)
      setItems(
        current.items.map((item) => ({
          name: item.name,
          quantity: String(item.quantity),
          unitPrice: String(item.unitPrice),
          warrantyMonths: item.warrantyMonths,
        })),
      );
  }, [type, currentMaterials.data]);
  const uploadCache = useRef(new Map()),
    keyRef = useRef(uuid());
  const candidates = useData(
    type === "assign" ? "/technicians/available?orderId=" + order.id : null,
    10000,
  );
  useEffect(() => {
    if (type !== "assign" || !form.technicianId || !candidates.data) return;
    const selected = candidates.data.find(
      (candidate) => candidate.id === Number(form.technicianId),
    );
    if (!selected?.canAssign)
      setForm((current) => ({ ...current, technicianId: "" }));
  }, [type, form.technicianId, candidates.data]);
  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }));
  const rejection = type.startsWith("reject-");
  const cancellationFee = ["DangDiChuyen", "DaDenNoi"].includes(order.status)
    ? Number(config?.cancellationFee || 60000)
    : 0;
  async function fileIds(purpose) {
    const ids = [];
    for (const f of files) {
      if (!uploadCache.current.has(f))
        uploadCache.current.set(f, (await upload(f, purpose, order.id)).id);
      ids.push(uploadCache.current.get(f));
    }
    return ids;
  }
  async function submit(e) {
    e.preventDefault();
    await a.run(async () => {
      if (
        ["material", "acceptance"].includes(type) &&
        (currentMaterials.loading || currentMaterials.error)
      )
        throw new Error("Chưa tải được chi phí vật tư. Vui lòng tải lại.");
      if (type === "acceptance" && !capturedSignature)
        throw new Error("Vui lòng ký xác nhận của kỹ thuật viên.");
      if (type === "acceptance" && !files.length)
        throw new Error("Cần ít nhất một ảnh thành phẩm.");
      if (
        type === "approve-acceptance" &&
        config?.signatureRequired &&
        !files.length &&
        !record?.signatureId
      )
        throw new Error("Vui lòng ký xác nhận hoặc chọn ảnh chữ ký.");
      if (
        type === "receive" &&
        form.decision === "Rejected" &&
        (!form.reasonChoice ||
          (form.reasonChoice === "Lý do khác" && form.reason.trim().length < 5))
      )
        throw new Error("Chọn lý do từ chối; lý do khác cần ít nhất 5 ký tự.");
      let path = "/orders/" + order.id,
        method = "POST",
        body = { expectedVersion },
        key;
      if (type === "preliminary") {
        path += "/preliminary-quotes";
        body.diagnosis = form.diagnosis;
        body.inspectionFee = Number(form.inspectionFee);
        body.laborFee = Number(form.laborFee);
      } else if (type === "assign") {
        path += "/assignments";
        body.technicianId = Number(form.technicianId);
      } else if (type === "receive") {
        path = "/assignments/" + order.currentAssignment.id + "/decision";
        body = {
          decision: form.decision,
          expectedVersion: order.currentAssignment.version,
          ...(form.decision === "Rejected"
            ? {
                reason:
                  form.reasonChoice === "Lý do khác"
                    ? "Lý do khác: " + form.reason.trim()
                    : form.reasonChoice,
              }
            : {}),
        };
      } else if (type === "progress") {
        path += "/progress";
        method = "PATCH";
        body.nextStatus = next[0];
      } else if (type === "material") {
        await fileIds("MaterialEvidence");
        path += "/materials";
        body = {
          items: items.map((i) => ({
            ...i,
            warrantyMonths: Number(i.warrantyMonths),
          })),
          expectedVersion,
        };
      } else if (type === "acceptance") {
        path += "/acceptances";
        body = {
          cause: form.cause,
          solution: form.solution,
          photoIds: await fileIds("AcceptancePhoto"),
          expectedVersion,
        };
        if (capturedSignature) {
          if (!uploadCache.current.has(capturedSignature))
            uploadCache.current.set(
              capturedSignature,
              (await upload(capturedSignature, "TechnicianSignature", order.id))
                .id,
            );
          body.technicianSignatureId =
            uploadCache.current.get(capturedSignature);
        }
      } else if (type === "cod") {
        path += "/payments/cod";
        key = keyRef.current;
      } else if (type === "review") {
        path += "/reviews";
        body = { rating: Number(form.rating), comment: form.comment };
      } else if (type === "cancel") {
        path += "/cancel";
        body.reason = form.reason;
        body.acceptCancellationFee = form.confirmed;
        body.expectedCancellationFee = cancellationFee;
      } else if (type === "note") {
        path += "/notes";
        body = {
          text: form.note,
          visibility: form.visibility,
          expectedVersion,
        };
      } else {
        const resource = type.split("-")[1];
        path +=
          "/" +
          {
            preliminary: "preliminary-quotes",
            acceptance: "acceptances",
          }[resource] +
          "/" +
          record.id +
          "/decision";
        body = {
          decision: rejection ? "Rejected" : "Approved",
          expectedVersion: record.version,
          ...(rejection ? { reason: form.reason } : {}),
        };
        if (type === "approve-acceptance") {
          body.paymentMethod = form.paymentMethod;
          if (form.paymentMethod === "BANK")
            body.bankAccountId = Number(form.bankAccountId);
          if (files.length)
            body.signatureId = (await fileIds("CustomerSignature"))[0];
          else if (record.signatureId) body.signatureId = record.signatureId;
        }
      }
      await api(path, { method, body, key });
      await onDone();
    });
  }
  const fileInput = (label, required = false, multiple = true) => (
    <PhotoPicker
      label={label}
      required={required}
      multiple={multiple}
      files={files}
      onChange={setFiles}
    />
  );
  const current = currentMaterials.data?.find((m) => m.isCurrent);
  const breakdown = {
    ...order.currentPreliminaryQuote,
    materialTotal: current?.total || 0,
    total:
      Number(order.currentPreliminaryQuote?.total || 0) +
      Number(current?.total || 0),
  };
  return (
    <Modal
      title={
        type === "receive"
          ? form.decision === "Rejected"
            ? "Lý do từ chối đơn"
            : "Chấp nhận đơn"
          : type === "preliminary" && order.currentPreliminaryQuote
            ? "Điều chỉnh báo giá sơ bộ"
            : titles[type]
      }
      onClose={onClose}
    >
      <form onSubmit={submit}>
        <ErrorBox error={a.error || candidates.error} />
        {type === "preliminary" && (
          <>
            <Field label="Chẩn đoán sơ bộ">
              <textarea
                required
                minLength={5}
                maxLength={1000}
                value={form.diagnosis}
                onChange={(e) => set("diagnosis", e.target.value)}
                rows={4}
              />
            </Field>
            <Field label="Phí kiểm tra (đồng)">
              <input
                type="number"
                min="0"
                max="1000000000"
                step="1"
                required
                value={form.inspectionFee ?? ""}
                onChange={(e) => set("inspectionFee", e.target.value)}
              />
            </Field>
            <Field label="Tiền công (đồng)">
              <input
                type="number"
                min="0"
                max="1000000000"
                step="1"
                required
                value={form.laborFee ?? ""}
                onChange={(e) => set("laborFee", e.target.value)}
              />
            </Field>
            <p>
              Tổng sơ bộ:{" "}
              <strong>
                {money(
                  Number(form.inspectionFee || 0) + Number(form.laborFee || 0),
                )}
              </strong>
            </p>
            <div className="notice info">
              Khách hàng cần duyệt báo giá mới trước khi phân công. Báo giá đã
              được đồng ý cũng phải duyệt lại nếu điều chỉnh.
            </div>
          </>
        )}
        {type === "assign" && (
          <>
            <Field label="Chọn kỹ thuật viên">
              <select
                required
                value={form.technicianId}
                onChange={(e) => set("technicianId", e.target.value)}
              >
                <option value="">Chọn thợ phù hợp</option>
                {candidates.data?.map((k) => (
                  <option key={k.id} value={k.id}>
                    {k.fullName} · {k.serviceArea}
                  </option>
                ))}
              </select>
            </Field>
            {candidates.data && !candidates.data.some((k) => k.canAssign) && (
              <div className="notice warning">
                Chưa có thợ đúng khu vực, tay nghề và đang sẵn sàng. Địa chỉ đơn
                cần ghi rõ quận hoặc thành phố.
              </div>
            )}
            <p>Một thợ chỉ giữ một lệnh hoặc ca đang làm tại một thời điểm.</p>
          </>
        )}
        {type === "receive" && (
          <>
            <p>
              {order.serviceName} · {order.address}
            </p>

            {form.decision === "Rejected" ? (
              <fieldset className="rejection-reasons">
                <legend>Chọn lý do từ chối</legend>
                {[
                  "Quá xa",
                  "Không đủ dụng cụ",
                  "Đang xử lý đơn khác",
                  "Lý do khác",
                ].map((reason) => (
                  <label key={reason}>
                    <input
                      type="radio"
                      name="rejectionReason"
                      value={reason}
                      checked={form.reasonChoice === reason}
                      onChange={() => set("reasonChoice", reason)}
                      required
                    />
                    {reason}
                  </label>
                ))}
                {form.reasonChoice === "Lý do khác" && (
                  <Field label="Nội dung lý do khác">
                    <textarea
                      required
                      minLength={5}
                      maxLength={950}
                      value={form.reason}
                      onChange={(e) => set("reason", e.target.value)}
                    />
                  </Field>
                )}
              </fieldset>
            ) : (
              <div className="notice info">
                Sau khi nhận đơn, hãy liên hệ khách và cập nhật tiến độ công
                việc.
              </div>
            )}
          </>
        )}
        {type === "progress" && (
          <p>
            Xác nhận: <b>{next?.[1]}</b>. Thời gian thực hiện sẽ được ghi lại
            trong lịch sử đơn.
          </p>
        )}
        {type === "material" && (
          <>
            <p>
              Nhập vật tư và đơn giá đã trao đổi trực tiếp với khách. Khi lưu,
              toàn bộ danh sách dưới đây thay bảng kê hiện hành và được tổng hợp
              vào phiếu nghiệm thu.
            </p>
            {items.map((item, i) => (
              <div className="material-editor" key={i}>
                <div className="row space">
                  <b>Vật tư {i + 1}</b>
                  {items.length > 1 && (
                    <button
                      type="button"
                      className="icon-btn danger"
                      onClick={() => setItems(items.filter((_, n) => n !== i))}
                      aria-label="Xóa dòng"
                    >
                      <Trash2 size={17} />
                    </button>
                  )}
                </div>
                <Field label="Tên vật tư">
                  <input
                    required
                    value={item.name}
                    onChange={(e) =>
                      setItems(
                        items.map((v, n) =>
                          n === i ? { ...v, name: e.target.value } : v,
                        ),
                      )
                    }
                  />
                </Field>
                <div className="form-grid">
                  <Field label="Số lượng">
                    <input
                      type="number"
                      min="0.01"
                      max="999.99"
                      step="0.01"
                      required
                      value={item.quantity}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) =>
                            n === i ? { ...v, quantity: e.target.value } : v,
                          ),
                        )
                      }
                    />
                  </Field>
                  <Field label="Đơn giá (đ)">
                    <input
                      type="number"
                      min="0"
                      max="100000000"
                      required
                      value={item.unitPrice}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) =>
                            n === i ? { ...v, unitPrice: e.target.value } : v,
                          ),
                        )
                      }
                    />
                  </Field>
                  <Field label="Bảo hành (tháng)">
                    <input
                      type="number"
                      min="0"
                      max="60"
                      required
                      value={item.warrantyMonths}
                      onChange={(e) =>
                        setItems(
                          items.map((v, n) =>
                            n === i
                              ? { ...v, warrantyMonths: e.target.value }
                              : v,
                          ),
                        )
                      }
                    />
                  </Field>
                </div>
              </div>
            ))}
            <button
              type="button"
              className="btn"
              disabled={items.length >= 20}
              onClick={() =>
                setItems([
                  ...items,
                  {
                    name: "",
                    quantity: "1",
                    unitPrice: "",
                    warrantyMonths: 0,
                  },
                ])
              }
            >
              <Plus size={16} /> Thêm vật tư
            </button>
            <div className="confirmation-amount">
              <small>Tổng vật tư</small>
              {money(
                items.reduce(
                  (sum, item) =>
                    sum +
                    Number(item.quantity || 0) * Number(item.unitPrice || 0),
                  0,
                ),
              )}
            </div>
            {fileInput("Ảnh vật tư / hiện trạng (không bắt buộc)")}
          </>
        )}
        {type === "acceptance" && (
          <>
            <div className="notice info">
              {order.contactName} · {order.address}
            </div>
            {preview ? (
              <Card title="Xem lại phiếu nghiệm thu">
                <h3>Nguyên nhân thực tế</h3>
                <p className="pre-wrap">{form.cause}</p>
                <h3>Biện pháp xử lý</h3>
                <p className="pre-wrap">{form.solution}</p>
                <PhotoPreview files={files} />
                {capturedSignature && (
                  <PhotoPreview
                    files={[capturedSignature]}
                    label="Chữ ký kỹ thuật viên"
                  />
                )}
                <p>
                  Phương thức dự kiến:{" "}
                  {form.paymentMethod === "BANK" ? "Chuyển khoản" : "Tiền mặt"}
                </p>
              </Card>
            ) : (
              <>
                <Field label="Nguyên nhân hư hỏng">
                  <textarea
                    required
                    minLength={5}
                    maxLength={2000}
                    value={form.cause}
                    onChange={(e) => set("cause", e.target.value)}
                  />
                </Field>
                <Field label="Biện pháp đã thực hiện">
                  <textarea
                    required
                    minLength={5}
                    maxLength={2000}
                    value={form.solution}
                    onChange={(e) => set("solution", e.target.value)}
                  />
                </Field>
                {fileInput("Ảnh thiết bị sau sửa chữa", true)}
                <SignaturePad
                  onChange={setCapturedSignature}
                  label="Chữ ký kỹ thuật viên"
                />
                {capturedSignature && (
                  <PhotoPreview
                    files={[capturedSignature]}
                    label="Chữ ký KTV đã lưu tạm"
                  />
                )}
                <small>
                  KTV ký xác nhận người lập phiếu. Khách vẫn xác nhận nghiệm thu
                  bằng tài khoản của mình; chữ ký KTV không thay thế chữ ký
                  khách.
                </small>
              </>
            )}
            {current?.items?.length > 0 && (
              <Card title="Vật tư kê khai">
                {current.items.map((item) => (
                  <p key={item.id}>
                    {item.name} × {Number(item.quantity)} ·{" "}
                    {money(item.lineTotal)} · BH {item.warrantyMonths} tháng
                  </p>
                ))}
              </Card>
            )}
            <ErrorBox error={currentMaterials.error} />
            {currentMaterials.loading ? (
              <Loading />
            ) : (
              <MoneyBreakdown value={breakdown} />
            )}
            <button
              className="btn"
              type="button"
              disabled={
                form.cause.trim().length < 5 ||
                form.solution.trim().length < 5 ||
                !files.length
              }
              onClick={() => setPreview((v) => !v)}
            >
              {preview ? "Tiếp tục chỉnh sửa" : "Xem lại phiếu"}
            </button>
            <div className="notice info">
              Gửi phiếu để khách xác nhận nghiệm thu và chọn phương thức thanh
              toán. Chỉ xác nhận thu tiền khi đã thực nhận.
            </div>
          </>
        )}
        {type.startsWith("approve-") && (
          <>
            <p>Xác nhận đồng ý nội dung phiếu và chi phí đã xem.</p>
            {record?.total !== undefined && (
              <div className="confirmation-amount">{money(record.total)}</div>
            )}
            {type === "approve-acceptance" && (
              <>
                <PaymentMethodFields
                  method={form.paymentMethod}
                  bankAccountId={form.bankAccountId}
                  onChange={(paymentMethod, bankAccountId) =>
                    setForm((s) => ({ ...s, paymentMethod, bankAccountId }))
                  }
                />
                {record.signatureId && (
                  <>
                    <h3>Chữ ký đã thu tại hiện trường</h3>
                    <div className="image-grid">
                      <ProtectedImage
                        id={record.signatureId}
                        alt="Chữ ký khách trên phiếu nghiệm thu"
                      />
                    </div>
                    <p>
                      Kiểm tra chữ ký này trước khi xác nhận. Bạn có thể ký lại
                      bên dưới.
                    </p>
                  </>
                )}
                <SignaturePad
                  onChange={(file) => setFiles(file ? [file] : [])}
                />
                {fileInput(
                  "Ảnh chữ ký của khách hàng",
                  config?.signatureRequired,
                  false,
                )}
                {!config?.signatureRequired && (
                  <small>
                    Chữ ký tùy chọn; xác nhận vẫn được ghi theo tài khoản khách
                    hàng.
                  </small>
                )}
                <label className="checkbox">
                  <input type="checkbox" required /> Tôi đã kiểm tra thiết bị và
                  đồng ý nghiệm thu.
                </label>
              </>
            )}
          </>
        )}
        {(rejection || type === "cancel") && (
          <>
            <Field
              label={
                type === "cancel"
                  ? "Lý do hủy"
                  : "Lý do từ chối / yêu cầu xử lý lại"
              }
            >
              <textarea
                required
                minLength={5}
                value={form.reason}
                onChange={(e) => set("reason", e.target.value)}
                rows={4}
              />
            </Field>
            {type === "cancel" &&
              (cancellationFee > 0 ? (
                <>
                  <div className="notice warning">
                    KTV đã di chuyển. Hủy đơn phát sinh{" "}
                    <b>{money(cancellationFee)}</b> phí di chuyển, chỉ thanh
                    toán chuyển khoản vào tài khoản HomeFix. Kế toán xác minh và
                    cộng đủ khoản này cho KTV.
                  </div>
                  <label className="checkbox">
                    <input
                      type="checkbox"
                      required
                      checked={form.confirmed}
                      onChange={(e) => set("confirmed", e.target.checked)}
                    />{" "}
                    Tôi đồng ý hủy và thanh toán phí {money(cancellationFee)}.
                  </label>
                </>
              ) : (
                <div className="notice info">
                  KTV chưa di chuyển. Hủy đơn không phát sinh phí.
                </div>
              ))}
          </>
        )}
        {type === "cod" && (
          <>
            <p>Chỉ xác nhận sau khi đã thực nhận đủ tiền mặt từ khách.</p>
            <div className="confirmation-amount">
              {money(order.currentAcceptance?.total)}
            </div>
            <label className="checkbox">
              <input type="checkbox" required /> Tôi đã nhận đủ số tiền trên từ
              khách hàng.
            </label>
          </>
        )}
        {type === "review" && (
          <>
            <Field label="Mức độ hài lòng">
              <select
                value={form.rating}
                onChange={(e) => set("rating", e.target.value)}
              >
                {[5, 4, 3, 2, 1].map((n) => (
                  <option key={n} value={n}>
                    {"★".repeat(n)} · {n} sao
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Nhận xét của bạn">
              <textarea
                maxLength={1500}
                value={form.comment}
                onChange={(e) => set("comment", e.target.value)}
              />
            </Field>
          </>
        )}
        {type === "note" && (
          <>
            <Field label="Nội dung">
              <textarea
                required
                value={form.note}
                onChange={(e) => set("note", e.target.value)}
              />
            </Field>
            <Field label="Phạm vi xem">
              <select
                value={form.visibility}
                onChange={(e) => set("visibility", e.target.value)}
              >
                <option value="Internal">Nội bộ điều phối / CSKH</option>
                <option value="Customer">Khách hàng có thể xem</option>
              </select>
            </Field>
          </>
        )}
        <div className="form-actions">
          <button
            type="button"
            className="btn"
            disabled={a.busy}
            onClick={onClose}
          >
            Quay lại
          </button>
          <Submit
            busy={a.busy}
            className={
              "btn " +
              (type === "receive" && form.decision === "Rejected"
                ? "reject-order"
                : "primary")
            }
            disabled={
              a.busy ||
              (["material", "acceptance"].includes(type) &&
                (currentMaterials.loading || !!currentMaterials.error)) ||
              (type === "receive" &&
                (new Date(order.currentAssignment.expiresAt).getTime() <=
                  Date.now() ||
                  (form.decision === "Rejected" &&
                    (!form.reasonChoice ||
                      (form.reasonChoice === "Lý do khác" &&
                        form.reason.trim().length < 5)))))
            }
          >
            {type === "receive"
              ? form.decision === "Rejected"
                ? "Xác nhận từ chối"
                : "Xác nhận nhận đơn"
              : type === "material"
                ? "Lưu vật tư"
                : type === "acceptance"
                  ? "Gửi phiếu nghiệm thu"
                  : "Xác nhận"}
          </Submit>
        </div>
      </form>
    </Modal>
  );
}
