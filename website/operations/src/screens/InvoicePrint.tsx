import { useEffect, useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency } from "../lib/api";

/**
 * Wave V.2 — invoice print / PDF view.
 *
 * Pragmatic V1 approach: a print-friendly HTML route that the
 * contractor opens in a new tab and saves as PDF via Cmd+P → "Save as
 * PDF". This avoids spinning up a server-side HTML→PDF pipeline (which
 * Deno Edge Functions don't support out of the box without a 3rd-party
 * service) and gives the contractor a clean, professional artifact.
 *
 * Layout: workspace letterhead → invoice number + dates → customer →
 * line items → totals → scope notes → message to homeowner. All
 * rendered on a single A4-friendly page with @media print rules
 * defined in operations.css that strip the SPA chrome.
 */
export default function InvoicePrintScreen() {
  const { invoiceId } = useParams<{ invoiceId: string }>();
  const { dashboard } = useWorkspace();
  const navigate = useNavigate();

  const invoice = useMemo(
    () => (dashboard?.invoices ?? []).find((inv) => inv.id === invoiceId) ?? null,
    [dashboard, invoiceId],
  );

  const home = useMemo(
    () => (dashboard?.homes ?? []).find((h) => h.propertyId === invoice?.propertyId) ?? null,
    [dashboard, invoice?.propertyId],
  );

  // Auto-open the browser print dialog ~250ms after mount so the
  // contractor lands on Save-as-PDF without an extra click. Disabled
  // when ?autoprint=0 so they can still review the layout first.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("autoprint") === "0") return;
    if (!invoice) return;
    const t = window.setTimeout(() => {
      try {
        window.print();
      } catch {
        // ignore — pop-up blockers etc.
      }
    }, 250);
    return () => window.clearTimeout(t);
  }, [invoice]);

  if (!dashboard) {
    return (
      <div style={{ padding: 32, fontFamily: "var(--sans)", color: "var(--text-muted)" }}>
        Loading invoice...
      </div>
    );
  }

  if (!invoice) {
    return (
      <div style={{ padding: 32, fontFamily: "var(--sans)" }}>
        <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, marginBottom: 8 }}>
          Invoice not found
        </div>
        <p style={{ color: "var(--text-muted)" }}>
          It may have been deleted, or you may not have access to this workspace.
        </p>
        <button
          onClick={() => navigate("/invoices")}
          className="ops-button ops-button--ghost"
          style={{ marginTop: 16 }}
        >
          Back to invoices
        </button>
      </div>
    );
  }

  const ws = dashboard.workspace;
  const subtotal = invoice.lineItems.reduce(
    (s, l) => s + (l.quantity ?? 1) * (l.unitPrice ?? 0),
    0,
  );

  return (
    <div className="invoice-print-shell" style={{ padding: 0 }}>
      {/* Action toolbar — hidden when printing */}
      <div className="invoice-print-toolbar" style={{
        position: "sticky", top: 0, zIndex: 20,
        background: "var(--pearl)",
        borderBottom: "1px solid var(--neutral-200)",
        padding: "12px 24px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <button
          className="ops-button ops-button--ghost"
          onClick={() => navigate(`/invoices/${invoice.id}`)}
        >
          ← Back to invoice
        </button>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)" }}>
          Save as PDF: press <strong>Cmd</strong>+<strong>P</strong> (Mac) or <strong>Ctrl</strong>+<strong>P</strong> (Windows), then choose "Save as PDF" as the destination.
        </div>
        <button
          className="ops-button ops-button--salmon"
          onClick={() => window.print()}
        >
          Print / Save as PDF
        </button>
      </div>

      {/* Printable page */}
      <div className="invoice-print-page" style={{
        maxWidth: 760,
        margin: "32px auto",
        padding: "48px 56px",
        background: "#fff",
        boxShadow: "0 8px 32px rgba(15, 10, 40,0.08)",
        fontFamily: "var(--sans)",
        color: "var(--text)",
      }}>
        {/* Letterhead */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "1fr auto",
          gap: 32,
          alignItems: "flex-start",
          paddingBottom: 24,
          borderBottom: "2px solid var(--indigo)",
        }}>
          <div>
            <div style={{
              fontFamily: "var(--serif)",
              fontSize: 30,
              fontWeight: 700,
              color: "var(--indigo)",
              letterSpacing: "-0.018em",
              marginBottom: 6,
            }}>
              {ws.companyName || "Your Company"}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", lineHeight: 1.6 }}>
              {ws.primaryEmail && <div>{ws.primaryEmail}</div>}
              {ws.primaryPhone && <div>{ws.primaryPhone}</div>}
              {ws.website && <div>{ws.website}</div>}
              {ws.licenseNumber && <div>License: {ws.licenseNumber}</div>}
            </div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{
              fontSize: 11,
              fontWeight: 700,
              letterSpacing: "0.16em",
              textTransform: "uppercase",
              color: "var(--text-soft)",
              marginBottom: 4,
            }}>
              Invoice
            </div>
            <div style={{
              fontFamily: "var(--serif)",
              fontSize: 22,
              fontWeight: 700,
              color: "var(--indigo)",
            }}>
              {invoice.invoiceNumber || "Pending"}
            </div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 8, lineHeight: 1.6 }}>
              {invoice.sentAt && <div>Issued: {new Date(invoice.sentAt).toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" })}</div>}
              {invoice.dueDate && <div>Due: {new Date(invoice.dueDate).toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" })}</div>}
              {!invoice.sentAt && (
                <div>Drafted: {new Date(invoice.createdAt).toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" })}</div>
              )}
            </div>
          </div>
        </div>

        {/* Bill To */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 32, marginTop: 28 }}>
          <div>
            <div style={{
              fontSize: 10,
              fontWeight: 700,
              letterSpacing: "0.16em",
              textTransform: "uppercase",
              color: "var(--text-soft)",
              marginBottom: 6,
            }}>
              Bill to
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>
              {home?.name || invoice.propertyName || "Customer"}
            </div>
            {home?.address && (
              <div style={{ fontSize: 12.5, color: "var(--text-muted)", lineHeight: 1.5 }}>
                {home.address}
              </div>
            )}
          </div>
          <div>
            <div style={{
              fontSize: 10,
              fontWeight: 700,
              letterSpacing: "0.16em",
              textTransform: "uppercase",
              color: "var(--text-soft)",
              marginBottom: 6,
            }}>
              For
            </div>
            <div style={{ fontSize: 14, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>
              {invoice.title || "Services rendered"}
            </div>
          </div>
        </div>

        {/* Line items */}
        <div style={{ marginTop: 32 }}>
          <table style={{
            width: "100%",
            borderCollapse: "collapse",
            fontSize: 12.5,
            color: "var(--text)",
          }}>
            <thead>
              <tr style={{
                borderBottom: "1px solid var(--indigo)",
              }}>
                <th style={{ textAlign: "left", padding: "10px 8px 10px 0", fontSize: 10.5, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)" }}>Description</th>
                <th style={{ textAlign: "right", padding: 10, fontSize: 10.5, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)", width: 60 }}>Qty</th>
                <th style={{ textAlign: "right", padding: 10, fontSize: 10.5, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)", width: 100 }}>Unit price</th>
                <th style={{ textAlign: "right", padding: "10px 0 10px 10px", fontSize: 10.5, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)", width: 100 }}>Amount</th>
              </tr>
            </thead>
            <tbody>
              {invoice.lineItems.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ padding: 16, fontSize: 13, color: "var(--text-muted)" }}>No line items.</td>
                </tr>
              ) : (
                invoice.lineItems.map((line, i) => {
                  const amount = (line.quantity ?? 1) * (line.unitPrice ?? 0);
                  return (
                    <tr key={i} style={{ borderBottom: "1px solid var(--neutral-200)" }}>
                      <td style={{ padding: "12px 8px 12px 0", verticalAlign: "top" }}>
                        <div style={{ fontWeight: 500 }}>{line.name}</div>
                        {line.description && (
                          <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 2 }}>
                            {line.description}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: 12, textAlign: "right", verticalAlign: "top", color: "var(--text-soft)" }}>
                        {line.quantity ?? 1} {line.unit ?? "ea"}
                      </td>
                      <td style={{ padding: 12, textAlign: "right", verticalAlign: "top", color: "var(--text-soft)" }}>
                        {formatCurrency(line.unitPrice ?? 0)}
                      </td>
                      <td style={{ padding: "12px 0 12px 10px", textAlign: "right", verticalAlign: "top", fontFamily: "var(--serif)", fontWeight: 600 }}>
                        {formatCurrency(amount)}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Totals */}
        <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
          <div style={{ width: 280, display: "flex", flexDirection: "column", gap: 6, fontSize: 12.5 }}>
            <TotalsRow label="Subtotal" value={formatCurrency(subtotal)} />
            {invoice.taxTotal > 0 && (
              <TotalsRow label="Tax" value={formatCurrency(invoice.taxTotal)} />
            )}
            <div style={{ borderTop: "1px solid var(--indigo)", marginTop: 4, paddingTop: 12, display: "flex", alignItems: "baseline", justifyContent: "space-between" }}>
              <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--indigo)" }}>
                Total due
              </span>
              <span style={{ fontFamily: "var(--serif)", fontSize: 26, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                {formatCurrency(invoice.total)}
              </span>
            </div>
            {invoice.amountPaid > 0 && invoice.amountPaid < invoice.total && (
              <>
                <TotalsRow label="Paid" value={formatCurrency(invoice.amountPaid)} />
                <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", borderTop: "1px solid var(--neutral-200)", paddingTop: 6 }}>
                  <span style={{ fontWeight: 700 }}>Remaining</span>
                  <span style={{ fontFamily: "var(--serif)", fontWeight: 700 }}>
                    {formatCurrency(invoice.total - invoice.amountPaid)}
                  </span>
                </div>
              </>
            )}
            {invoice.status === "paid" && (
              <div style={{
                marginTop: 8,
                padding: "8px 12px",
                background: "var(--pearl)",
                borderRadius: 8,
                textAlign: "center",
                fontSize: 11.5,
                fontWeight: 700,
                letterSpacing: "0.12em",
                textTransform: "uppercase",
                color: "#0A0A0A",
                border: "1px solid #0A0A0A",
              }}>
                Paid in full {invoice.paidAt ? `on ${new Date(invoice.paidAt).toLocaleDateString()}` : ""}
              </div>
            )}
          </div>
        </div>

        {/* Notes / message */}
        {(invoice.scopeNotes || invoice.homeownerMessage) && (
          <div style={{ marginTop: 32, paddingTop: 20, borderTop: "1px solid var(--neutral-200)" }}>
            {invoice.scopeNotes && (
              <div style={{ marginBottom: invoice.homeownerMessage ? 16 : 0 }}>
                <div style={{
                  fontSize: 10,
                  fontWeight: 700,
                  letterSpacing: "0.16em",
                  textTransform: "uppercase",
                  color: "var(--text-soft)",
                  marginBottom: 6,
                }}>
                  Scope of work
                </div>
                <p style={{ fontSize: 12.5, color: "var(--text)", whiteSpace: "pre-wrap", margin: 0, lineHeight: 1.6 }}>
                  {invoice.scopeNotes}
                </p>
              </div>
            )}
            {invoice.homeownerMessage && (
              <div>
                <div style={{
                  fontSize: 10,
                  fontWeight: 700,
                  letterSpacing: "0.16em",
                  textTransform: "uppercase",
                  color: "var(--text-soft)",
                  marginBottom: 6,
                }}>
                  Notes
                </div>
                <p style={{ fontSize: 12.5, color: "var(--text)", whiteSpace: "pre-wrap", margin: 0, lineHeight: 1.6 }}>
                  {invoice.homeownerMessage}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Footer / payment instructions */}
        <div style={{
          marginTop: 40,
          paddingTop: 16,
          borderTop: "1px solid var(--neutral-200)",
          fontSize: 11.5,
          color: "var(--text-muted)",
          lineHeight: 1.5,
          textAlign: "center",
        }}>
          Thank you for your business.
          {ws.primaryEmail && (
            <> Reply to <strong style={{ color: "var(--text)" }}>{ws.primaryEmail}</strong> with any questions.</>
          )}
        </div>
      </div>
    </div>
  );
}

function TotalsRow({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between" }}>
      <span style={{ color: "var(--text-muted)" }}>{label}</span>
      <span style={{ fontFamily: "var(--sans)", fontVariantNumeric: "tabular-nums" }}>{value}</span>
    </div>
  );
}
