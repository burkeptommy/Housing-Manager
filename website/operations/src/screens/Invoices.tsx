import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime } from "../lib/api";
import { useNewInvoiceModal } from "../components/NewInvoiceModal";
import type { InvoiceStatus } from "../lib/types";

const STATUS_TONE: Record<InvoiceStatus, PillTone> = {
  draft: "neutral",
  sent: "info",
  viewed: "indigo",
  paid: "success",
  partial: "warning",
  overdue: "critical",
  void: "neutral",
};

type FilterKey = "all" | InvoiceStatus;

const FILTERS: { key: FilterKey; label: string }[] = [
  { key: "all", label: "All" },
  { key: "draft", label: "Draft" },
  { key: "sent", label: "Sent" },
  { key: "paid", label: "Paid" },
  { key: "overdue", label: "Overdue" },
];

export default function InvoicesScreen() {
  const { dashboard } = useWorkspace();
  const newInvoice = useNewInvoiceModal();
  const navigate = useNavigate();
  const [filter, setFilter] = useState<FilterKey>("all");
  const [query, setQuery] = useState("");

  const invoices = useMemo(() => dashboard?.invoices ?? [], [dashboard]);

  const filtered = useMemo(() => {
    let list = invoices;
    if (filter !== "all") {
      list = list.filter((inv) => inv.status === filter);
    }
    const q = query.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (inv) =>
          inv.invoiceNumber.toLowerCase().includes(q) ||
          inv.title.toLowerCase().includes(q) ||
          inv.propertyName.toLowerCase().includes(q),
      );
    }
    return list;
  }, [invoices, filter, query]);

  const counts = useMemo(() => {
    const c: Record<FilterKey, number> = {
      all: invoices.length,
      draft: 0,
      sent: 0,
      viewed: 0,
      paid: 0,
      partial: 0,
      overdue: 0,
      void: 0,
    };
    for (const inv of invoices) {
      c[inv.status] = (c[inv.status] ?? 0) + 1;
    }
    return c;
  }, [invoices]);

  if (!dashboard) return null;

  if (invoices.length === 0) {
    return (
      <EmptyState
        icon="receipt"
        title="No invoices yet"
        body="Convert an approved quote, or start an invoice from scratch. Once you send it, the homeowner sees it in their Chez inbox right away."
        cta={{ label: "+ New invoice", onClick: () => newInvoice.open() }}
      />
    );
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <Card padding="default">
        {/* Filter chips + search */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, marginBottom: 14, flexWrap: "wrap" }}>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
            {FILTERS.map((f) => {
              const isActive = filter === f.key;
              return (
                <button
                  key={f.key}
                  onClick={() => setFilter(f.key)}
                  style={{
                    padding: "6px 12px",
                    border: "1px solid var(--neutral-200)",
                    borderRadius: 999,
                    background: isActive ? "var(--indigo-900, #0A0A0A)" : "#fff",
                    color: isActive ? "#fff" : "var(--text)",
                    fontSize: 12.5,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "var(--sans)",
                  }}
                >
                  {f.label} {counts[f.key] > 0 ? <span style={{ opacity: 0.7, fontWeight: 500 }}>· {counts[f.key]}</span> : null}
                </button>
              );
            })}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "0 10px", border: "1px solid var(--neutral-200)", borderRadius: 10, background: "#fff", height: 34, width: 240 }}>
            <Icon name="search" size={14} stroke={1.9} />
            <input
              type="search"
              placeholder="Invoice number, title, or home..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              style={{ flex: 1, border: "none", outline: "none", background: "none", fontSize: 12.5, fontFamily: "var(--sans)", color: "var(--text)" }}
            />
          </div>
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <div style={{ padding: 28, textAlign: "center", fontSize: 13, color: "var(--text-muted)" }}>
            No invoices match the current filter.
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column" }}>
            {/* Header */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1.4fr 1.4fr 1fr 0.8fr 0.8fr 32px",
                alignItems: "center",
                padding: "10px 12px",
                borderBottom: "1px solid var(--neutral-200)",
                fontSize: 10,
                fontWeight: 600,
                letterSpacing: "0.08em",
                textTransform: "uppercase",
                color: "var(--text-soft)",
              }}
            >
              <span>Invoice</span>
              <span>Customer</span>
              <span>Status</span>
              <span style={{ textAlign: "right" }}>Total</span>
              <span style={{ textAlign: "right" }}>Updated</span>
              <span />
            </div>
            {filtered.map((inv) => (
              <button
                key={inv.id}
                onClick={() => navigate(`/invoices/${inv.id}`)}
                className="ops-row"
                style={{
                  display: "grid",
                  gridTemplateColumns: "1.4fr 1.4fr 1fr 0.8fr 0.8fr 32px",
                  alignItems: "center",
                  padding: "12px",
                  border: "none",
                  borderBottom: "1px solid var(--neutral-200)",
                  background: "none",
                  cursor: "pointer",
                  textAlign: "left",
                  width: "100%",
                  borderRadius: 0,
                  fontFamily: "var(--sans)",
                }}
              >
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                    {inv.invoiceNumber}
                  </div>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                    {inv.title || "Untitled"}
                  </div>
                </div>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, color: "var(--text)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                    {inv.propertyName || "No home linked"}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)" }}>
                    {inv.lineItems.length} item{inv.lineItems.length === 1 ? "" : "s"}
                  </div>
                </div>
                <div>
                  <Pill tone={STATUS_TONE[inv.status] ?? "neutral"}>{inv.statusLabel}</Pill>
                </div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", textAlign: "right" }}>
                  {formatCurrency(inv.total)}
                </div>
                <div style={{ fontSize: 11.5, color: "var(--text-muted)", textAlign: "right" }}>
                  {formatRelativeTime(inv.updatedAt)}
                </div>
                <div style={{ display: "flex", justifyContent: "flex-end", color: "var(--text-soft)" }}>
                  <Icon name="chevron" size={14} stroke={2} />
                </div>
              </button>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
