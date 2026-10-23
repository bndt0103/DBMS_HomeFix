import React from "react";
import { Link } from "react-router-dom";

export function AssignmentAlerts({ orders }) {
  const pending = orders.filter((order) => order.status === "ChoNhan");
  if (!pending.length) return null;
  return (
    <div className="assignment-alerts">
      <Link className="btn primary" to={"/orders/" + pending[0].id}>
        {pending.length} đơn chờ nhận
      </Link>
    </div>
  );
}
