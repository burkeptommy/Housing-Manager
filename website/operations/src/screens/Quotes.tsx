import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime, postProviderAction } from "../lib/api";
import { useNewQuoteModal } from "../components/NewQuoteModal";

const STATUS_TONE: Record<string, PillTone> = {
  draft: "neutral",
  sent: "info",
  viewed: "indigo",
  approved: "success",
  declined: "critical",
  withdrawn: "neutral",
  countered_by_homeowner: "warning",
  superseded: "neutral",
};

export default function QuotesScreen() {
  const { dashboard, refresh } = useWorkspace();
  const newQuote = useNewQuoteModal();
  const [selectedQuoteId, setSelectedQuoteId] = useState<string | null>(null);
  const [busy, setBusy] = useState<"send" | "delete" | null>(null);

  const quotes = useMemo(() => dashboard?.quotes ?? [], [dashboard]);
  const savedItems = useMemo(() => dashboard?.savedQuoteItems ?? [], [dashboard]);

  const selected = useMemo(() => {
    if (!quotes.length) return null;
    if (selectedQuoteId) return quotes.find((q) => q.id === selectedQuoteId) ?? quotes[0];
    return quotes[0];
  }, [selectedQuoteId, quotes]);

  if (!dashboard) return null;

  if (quotes.length === 0 && savedItems.length === 0) {
    return (
      <EmptyState
        icon="quote"
        title="No quotes yet"
        body="Send your first quote and the pipeline starts building. You can also seed the saved-items library with the small jobs you bid on most."
        cta={{ label: "+ Draft a quote", onClick: () => alert("New-quote flow ships next.") }}
      />
    );
  }

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1.4fr", gap: 24, alignItems: "start" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 12 }}>Pipeline</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8, marginBottom: 16 }}>
            {(["draft", "sent", "viewed", "approved", "declined"] as const).map((s) => (
              <div key={s}>
                <div style={{ height: 3, borderRadius: 2, background: toneCss(STATUS_TONE[s] ?? "neutral"), marginBottom: 6 }} />
                <div style={{ fontSize: 10, color: "var(--text-soft)", letterSpacing: "0.06em", textTransform: "uppercase", fontWeight: 600 }}>{s}</div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 18, color: toneCss(STATUS_TONE[s] ?? "neutral"), fontWeight: 700 }}>
                  {quotes.filter((q) => q.status === s).length}
                </div>
              </div>
            ))}
          </div>

          <div className="ops-section-label" style={{ marginBottom: 8 }}>All quotes</div>
          {quotes.length === 0 ? (
            <div style={{ padding: 14, fontSize: 13, color: "var(--text-muted)" }}>No quotes yet.</div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column" }}>
              {quotes.map((q) => (
                <button
                  key={q.id}
                  onClick={() => setSelectedQuoteId(q.id)}
                  className="ops-row"
                  style={{
                    background: selected?.id === q.id ? "var(--salmon-50)" : "none",
                    border: "none",
                    borderBottom: "1px solid var(--neutral-200)",
                    padding: "10px 8px",
                    width: "100%",
                    cursor: "pointer",
                    textAlign: "left",
                    borderLeft: selected?.id === q.id ? "3px solid var(--salmon)" : "3px solid transparent",
                    borderRadius: 0,
                  }}
                >
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{q.audienceLabel}</div>
                    <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                      {q.title} · {q.itemCount} item{q.itemCount === 1 ? "" : "s"} · {formatRelativeTime(q.updatedAt)}
                    </div>
                  </div>
                  <Pill tone={STATUS_TONE[q.status] ?? "neutral"}>{q.statusLabel}</Pill>
                  <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", width: 80, textAlign: "right" }}>
                    {formatCurrency(q.total)}
                  </div>
                </button>
              ))}
            </div>
          )}
        </Card>

        <Card padding="default">
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
            <div className="ops-section-label">Saved line items</div>
            <button style={{ fontSize: 12, fontWeight: 600, color: "var(--salmon-dark)", background: "none", border: "none", cursor: "pointer" }}>+ Add new</button>
          </div>
          {savedItems.length === 0 ? (
            <div style={{ padding: 14, fontSize: 13, color: "var(--text-muted)" }}>
              No saved items. Save the small jobs you bid on most so future quotes build in seconds.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column" }}>
              {savedItems.map((item) => (
                <div key={item.id} className="ops-row" style={{ padding: "10px 0" }}>
                  <div style={{ flex: 1, fontSize: 12.5, color: "var(--text)" }}>{item.name}</div>
                  <div style={{ fontSize: 11, color: "var(--text-soft)", width: 30 }}>/{item.unit}</div>
                  <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", width: 70, textAlign: "right" }}>
                    {formatCurrency(item.defaultUnitPrice)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>

      <Card padding="default">
        {selected ? (
          <>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
              <Pill tone={STATUS_TONE[selected.status] ?? "neutral"}>{selected.statusLabel}</Pill>
              <Pill tone="indigo">{selected.title}</Pill>
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              {selected.audienceLabel}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 14 }}>
              {selected.recipientAddress || selected.propertyName || "—"}
            </div>
            <div style={{ display: "flex", gap: 8, marginBottom: 16, flexWrap: "wrap" }}>
              {selected.publicShareUrl && (
                <a className="ops-button ops-button--ghost" href={selected.publicShareUrl} target="_blank" rel="noopener">
                  View public link
                </a>
              )}
              <button
                className="ops-button ops-button--ghost"
                onClick={() => newQuote.open({ editQuoteId: selected.id })}
              >
                Edit quote
              </button>
              {selected.status === "draft" && (
                <button
                  className="ops-button ops-button--ghost"
                  disabled={busy !== null}
                  onClick={async () => {
                    if (!confirm(`Delete draft "${selected.title}"? This can't be undone.`)) return;
                    setBusy("delete");
                    try {
                      await postProviderAction("delete_quote", {
                        workspaceId: dashboard.workspace.id,
                        quoteId: selected.id,
                      });
                      setSelectedQuoteId(null);
                      await refresh();
                    } catch (e) {
                      alert(e instanceof Error ? e.message : "Couldn't delete the quote.");
                    } finally {
                      setBusy(null);
                    }
                  }}
                >
                  {busy === "delete" ? "Deleting…" : "Delete draft"}
                </button>
              )}
              {(selected.status === "draft" || selected.status === "viewed" || selected.status === "countered_by_homeowner") && (
                <button
                  className="ops-button ops-button--salmon"
                  style={{ marginLeft: "auto" }}
                  disabled={busy !== null}
                  onClick={async () => {
                    setBusy("send");
                    try {
                      const result = await postProviderAction<{
                        quote: { id: string; status: string };
                        delivery?: { sent: boolean; channel?: string; error?: string };
                      }>("send_quote", {
                        workspaceId: dashboard.workspace.id,
                        quoteId: selected.id,
                      });
                      await refresh();
                      // Surface delivery failures — the quote still
                      // mirrors into the homeowner's chat thread so
                      // it's marked sent, but the email channel
                      // failed. Tell the user.
                      if (result.delivery && result.delivery.sent === false) {
                        alert(`Quote saved + posted to the homeowner's chat thread, but the email didn't go out: ${result.delivery.error || "unknown error"}.\n\nThey'll still see it in their Chez Handyman tab.`);
                      }
                    } catch (e) {
                      alert(e instanceof Error ? e.message : "Couldn't send the quote.");
                    } finally {
                      setBusy(null);
                    }
                  }}
                >
                  {busy === "send" ? "Sending…" : selected.status === "draft" ? "Send to homeowner" : "Resend"}
                </button>
              )}
            </div>

            {/* Spreadsheet */}
            <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 12, overflow: "hidden" }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 60px 60px 100px 100px", padding: "10px 12px", borderBottom: "1px solid var(--neutral-200)", background: "var(--pearl)", fontSize: 10.5, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>
                <span>Item</span>
                <span>Unit</span>
                <span>Qty</span>
                <span style={{ textAlign: "right" }}>Unit price</span>
                <span style={{ textAlign: "right" }}>Subtotal</span>
              </div>
              {selected.lineItems.length === 0 ? (
                <div style={{ padding: 16, fontSize: 13, color: "var(--text-muted)" }}>
                  No line items on this quote yet.
                </div>
              ) : (
                selected.lineItems.map((line, i) => (
                  <div key={i} style={{ display: "grid", gridTemplateColumns: "1fr 60px 60px 100px 100px", padding: "12px", borderBottom: i < selected.lineItems.length - 1 ? "1px solid var(--neutral-200)" : "none", alignItems: "center" }}>
                    <div>
                      <div style={{ fontSize: 13, fontWeight: 500, color: "var(--text)" }}>{line.name}</div>
                      {line.description && <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{line.description}</div>}
                    </div>
                    <div style={{ fontSize: 12, color: "var(--text)" }}>{line.unit ?? "ea"}</div>
                    <div style={{ fontSize: 12, color: "var(--text)" }}>{line.quantity ?? 1}</div>
                    <div style={{ fontSize: 12, color: "var(--text)", textAlign: "right" }}>{formatCurrency(line.unitPrice ?? 0)}</div>
                    <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", textAlign: "right" }}>
                      {formatCurrency((line.quantity ?? 1) * (line.unitPrice ?? 0))}
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Totals */}
            <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
              <div style={{ width: 280, display: "flex", flexDirection: "column", gap: 6 }}>
                <Row label="Total" value={formatCurrency(selected.total)} bold />
              </div>
            </div>
          </>
        ) : (
          <EmptyState
            icon="quote"
            title="No quote selected"
            body="Pick a quote from the list to view or edit."
          />
        )}
      </Card>
    </div>
  );
}

function Row({ label, value, bold }: { label: string; value: string; bold?: boolean }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", fontSize: bold ? 14 : 12.5, color: bold ? "var(--text)" : "var(--text-muted)", fontWeight: bold ? 700 : 400 }}>
      <span>{label}</span>
      <span style={{ fontFamily: bold ? "var(--serif)" : "var(--sans)", fontVariantNumeric: "tabular-nums", color: bold ? "var(--indigo)" : undefined, fontSize: bold ? 22 : undefined }}>{value}</span>
    </div>
  );
}

function toneCss(t: PillTone): string {
  switch (t) {
    case "indigo":   return "var(--indigo)";
    case "salmon":   return "var(--salmon)";
    case "success":  return "#4A7C59";
    case "warning":  return "#C77E2E";
    case "critical": return "#C25A5E";
    case "info":     return "#5A8DB5";
    default:         return "var(--neutral-400)";
  }
}
