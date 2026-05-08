import { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, postProviderAction } from "../lib/api";
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

export default function InvoiceDetailScreen() {
  const { invoiceId } = useParams<{ invoiceId: string }>();
  const { dashboard, refresh } = useWorkspace();
  const navigate = useNavigate();
  const newInvoice = useNewInvoiceModal();
  const [busy, setBusy] = useState<"send" | "void" | "paid" | null>(null);

  const invoice = useMemo(
    () => (dashboard?.invoices ?? []).find((inv) => inv.id === invoiceId) ?? null,
    [dashboard, invoiceId],
  );

  const home = useMemo(
    () => (dashboard?.homes ?? []).find((h) => h.propertyId === invoice?.propertyId) ?? null,
    [dashboard, invoice?.propertyId],
  );

  if (!dashboard) return null;

  if (!invoice) {
    return (
      <Card padding="default">
        <div style={{ padding: 24, textAlign: "center" }}>
          <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>Invoice not found</div>
          <p style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 8 }}>
            It may have been deleted, or you may not have access.
          </p>
          <button
            className="ops-button ops-button--ghost"
            onClick={() => navigate("/invoices")}
            style={{ marginTop: 12 }}
          >
            ← Back to invoices
          </button>
        </div>
      </Card>
    );
  }

  const isDraft = invoice.status === "draft";
  const isSent = invoice.status === "sent" || invoice.status === "viewed";
  const isPaid = invoice.status === "paid" || invoice.status === "partial";
  const isVoid = invoice.status === "void";

  async function sendInvoice() {
    if (!invoice) return;
    if (!confirm("Send this invoice to the homeowner?")) return;
    setBusy("send");
    try {
      await postProviderAction("send_invoice", {
        workspaceId: dashboard!.workspace.id,
        invoiceId: invoice.id,
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't send the invoice.");
    } finally {
      setBusy(null);
    }
  }

  async function voidInvoice() {
    if (!invoice) return;
    if (!confirm("Void this invoice? This is permanent and tells the homeowner the invoice is no longer valid.")) return;
    setBusy("void");
    try {
      await postProviderAction("void_invoice", {
        workspaceId: dashboard!.workspace.id,
        invoiceId: invoice.id,
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't void the invoice.");
    } finally {
      setBusy(null);
    }
  }

  async function markPaid() {
    if (!invoice) return;
    if (!confirm("Mark this invoice as paid in full?")) return;
    setBusy("paid");
    try {
      await postProviderAction("mark_invoice_paid", {
        workspaceId: dashboard!.workspace.id,
        invoiceId: invoice.id,
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't mark the invoice paid.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 320px", gap: 24, alignItems: "start" }}>
      {/* Main column */}
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {/* Back link */}
        <button
          onClick={() => navigate("/invoices")}
          style={{
            background: "none",
            border: "none",
            color: "var(--text-soft)",
            cursor: "pointer",
            padding: 0,
            fontSize: 12.5,
            display: "flex",
            alignItems: "center",
            gap: 4,
            fontFamily: "var(--sans)",
          }}
        >
          <span style={{ display: "inline-block", transform: "rotate(180deg)" }}>
            <Icon name="chevron" size={12} stroke={2} />
          </span>
          All invoices
        </button>

        {/* Header card */}
        <Card padding="default">
          <div style={{ display: "flex", justifyContent: "space-between", gap: 16, alignItems: "flex-start" }}>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
                <span style={{ fontSize: 12, fontWeight: 600, color: "var(--text-soft)", letterSpacing: "0.04em" }}>
                  {invoice.invoiceNumber}
                </span>
                <Pill tone={STATUS_TONE[invoice.status] ?? "neutral"}>{invoice.statusLabel}</Pill>
              </div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 24, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.01em" }}>
                {invoice.title || "Untitled invoice"}
              </div>
              <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 4 }}>
                {invoice.propertyName ? `${invoice.propertyName}` : "No home linked"}
                {invoice.dueDate ? ` · Due ${new Date(invoice.dueDate).toLocaleDateString()}` : ""}
                {invoice.sentAt ? ` · Sent ${new Date(invoice.sentAt).toLocaleDateString()}` : ""}
                {invoice.paidAt ? ` · Paid ${new Date(invoice.paidAt).toLocaleDateString()}` : ""}
              </div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Total</div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 28, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.02em" }}>
                {formatCurrency(invoice.total)}
              </div>
              {invoice.amountPaid > 0 && invoice.amountPaid < invoice.total ? (
                <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 2 }}>
                  {formatCurrency(invoice.amountPaid)} paid · {formatCurrency(invoice.total - invoice.amountPaid)} remaining
                </div>
              ) : null}
            </div>
          </div>
        </Card>

        {/* Line items */}
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 12 }}>Line items</div>
          <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 10, overflow: "hidden" }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 80px 80px 100px 100px", padding: "8px 12px", borderBottom: "1px solid var(--neutral-200)", background: "var(--pearl)", fontSize: 10, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>
              <span>Item</span>
              <span>Unit</span>
              <span style={{ textAlign: "right" }}>Qty</span>
              <span style={{ textAlign: "right" }}>Price</span>
              <span style={{ textAlign: "right" }}>Subtotal</span>
            </div>
            {invoice.lineItems.length === 0 ? (
              <div style={{ padding: 14, fontSize: 13, color: "var(--text-muted)" }}>No line items.</div>
            ) : (
              invoice.lineItems.map((line, i) => {
                const subtotal = (line.quantity ?? 1) * (line.unitPrice ?? 0);
                return (
                  <div
                    key={line.id ?? i}
                    style={{
                      display: "grid",
                      gridTemplateColumns: "1fr 80px 80px 100px 100px",
                      padding: 10,
                      borderBottom: "1px solid var(--neutral-200)",
                      alignItems: "center",
                      gap: 6,
                      fontSize: 13,
                    }}
                  >
                    <div>
                      <div style={{ color: "var(--text)", fontWeight: 500 }}>{line.name}</div>
                      {line.description && (
                        <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 2 }}>{line.description}</div>
                      )}
                    </div>
                    <div style={{ color: "var(--text-soft)" }}>{line.unit ?? "ea"}</div>
                    <div style={{ textAlign: "right", color: "var(--text-soft)" }}>{line.quantity ?? 1}</div>
                    <div style={{ textAlign: "right", color: "var(--text-soft)" }}>{formatCurrency(line.unitPrice ?? 0)}</div>
                    <div style={{ textAlign: "right", fontFamily: "var(--serif)", fontWeight: 600, color: "var(--text)" }}>
                      {formatCurrency(subtotal)}
                    </div>
                  </div>
                );
              })
            )}
            <div style={{ display: "flex", justifyContent: "space-between", padding: "12px 16px", background: "var(--pearl)" }}>
              <span style={{ fontSize: 12.5, fontWeight: 600 }}>Total</span>
              <span style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                {formatCurrency(invoice.total)}
              </span>
            </div>
          </div>
        </Card>

        {/* Notes */}
        {(invoice.scopeNotes || invoice.homeownerMessage) && (
          <Card padding="default">
            {invoice.scopeNotes && (
              <div style={{ marginBottom: invoice.homeownerMessage ? 14 : 0 }}>
                <div className="ops-section-label" style={{ marginBottom: 6 }}>Scope notes (internal)</div>
                <p style={{ fontSize: 13, color: "var(--text)", whiteSpace: "pre-wrap" }}>{invoice.scopeNotes}</p>
              </div>
            )}
            {invoice.homeownerMessage && (
              <div>
                <div className="ops-section-label" style={{ marginBottom: 6 }}>Message to the homeowner</div>
                <p style={{ fontSize: 13, color: "var(--text)", whiteSpace: "pre-wrap" }}>{invoice.homeownerMessage}</p>
              </div>
            )}
          </Card>
        )}
      </div>

      {/* Sidebar */}
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {/* Actions */}
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 12 }}>Actions</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {isDraft && (
              <>
                <button
                  className="ops-button ops-button--salmon"
                  onClick={sendInvoice}
                  disabled={busy !== null}
                  style={{ width: "100%" }}
                >
                  {busy === "send" ? "Sending..." : "Send to homeowner"}
                </button>
                <button
                  className="ops-button ops-button--ghost"
                  onClick={() => newInvoice.open({ editInvoiceId: invoice.id })}
                  disabled={busy !== null}
                  style={{ width: "100%" }}
                >
                  Edit
                </button>
                <button
                  className="ops-button ops-button--ghost"
                  onClick={voidInvoice}
                  disabled={busy !== null}
                  style={{ width: "100%", color: "var(--critical, #C8392F)" }}
                >
                  {busy === "void" ? "Voiding..." : "Void"}
                </button>
              </>
            )}
            {isSent && (
              <>
                <button
                  className="ops-button ops-button--salmon"
                  onClick={markPaid}
                  disabled={busy !== null}
                  style={{ width: "100%" }}
                >
                  {busy === "paid" ? "Saving..." : "Mark as paid"}
                </button>
                <button
                  className="ops-button ops-button--ghost"
                  onClick={voidInvoice}
                  disabled={busy !== null}
                  style={{ width: "100%", color: "var(--critical, #C8392F)" }}
                >
                  {busy === "void" ? "Voiding..." : "Void"}
                </button>
              </>
            )}
            {isPaid && (
              <div style={{ padding: 12, background: "var(--pearl)", borderRadius: 10, fontSize: 13, color: "var(--text-muted)" }}>
                Marked paid {invoice.paidAt ? new Date(invoice.paidAt).toLocaleDateString() : ""}.
              </div>
            )}
            {isVoid && (
              <div style={{ padding: 12, background: "var(--pearl)", borderRadius: 10, fontSize: 13, color: "var(--text-muted)" }}>
                This invoice was voided.
              </div>
            )}

            {/* Wave V.2 — printable / PDF view. Always available; opens
                a print-friendly page in a new tab and auto-fires the
                print dialog so Cmd+P → Save as PDF lands instantly.
                A no-op when the invoice is voided is fine; the artifact
                is still useful for record-keeping. */}
            <button
              className="ops-button ops-button--ghost"
              onClick={() => window.open(`/operations/invoices/${invoice.id}/print`, "_blank", "noopener")}
              disabled={busy !== null}
              style={{ width: "100%", marginTop: isPaid || isVoid ? 8 : 0 }}
            >
              Download PDF / Print
            </button>
          </div>
        </Card>

        {/* Customer */}
        {home && (
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 8 }}>Customer</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{home.name}</div>
            {home.address && (
              <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 4 }}>{home.address}</div>
            )}
            <button
              onClick={() => navigate(`/homes/${home.propertyId}`)}
              style={{
                marginTop: 10,
                background: "none",
                border: "1px solid var(--neutral-200)",
                borderRadius: 10,
                padding: "8px 12px",
                fontSize: 12.5,
                fontWeight: 600,
                color: "var(--text)",
                cursor: "pointer",
                fontFamily: "var(--sans)",
                width: "100%",
              }}
            >
              Open home
            </button>
          </Card>
        )}
      </div>
    </div>
  );
}
