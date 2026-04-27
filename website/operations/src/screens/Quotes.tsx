import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { QUOTES_DEMO, QUOTE_BUILDER_DEMO, SAVED_LINE_ITEMS_DEMO, formatCurrencyCents } from "../lib/fixtures";

const STATUS_TONE: Record<string, PillTone> = {
  draft: "neutral",
  sent: "info",
  viewed: "indigo",
  approved: "success",
  declined: "critical",
};

export default function QuotesScreen() {
  const [lines, setLines] = useState(QUOTE_BUILDER_DEMO.lines);

  const totals = useMemo(() => {
    const subtotal = lines.reduce((sum, l) => sum + l.qty * l.priceCents, 0);
    const materials = Math.round(subtotal * (QUOTE_BUILDER_DEMO.materialsMarkupBp / 10000));
    const tax = Math.round((subtotal + materials) * (QUOTE_BUILDER_DEMO.taxBp / 10000));
    return { subtotal, materials, tax, total: subtotal + materials + tax };
  }, [lines]);

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1.4fr", gap: 24, alignItems: "start" }}>
      {/* Left column */}
      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 12 }}>Pipeline</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8, marginBottom: 16 }}>
            {(["draft", "sent", "viewed", "approved", "declined"] as const).map((s) => (
              <div key={s}>
                <div style={{ height: 3, borderRadius: 2, background: toneCss(STATUS_TONE[s]), marginBottom: 6 }} />
                <div style={{ fontSize: 10, color: "var(--text-soft)", letterSpacing: "0.06em", textTransform: "uppercase", fontWeight: 600 }}>{s}</div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 18, color: toneCss(STATUS_TONE[s]), fontWeight: 700 }}>
                  {QUOTES_DEMO.filter((q) => q.status === s).length}
                </div>
              </div>
            ))}
          </div>

          <div className="ops-section-label" style={{ marginBottom: 8 }}>All quotes</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
            {QUOTES_DEMO.map((q) => (
              <div key={q.id} className="ops-row" style={{ padding: "10px 0" }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{q.customer}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{q.property} · {q.items} items · {q.updated}</div>
                </div>
                <Pill tone={STATUS_TONE[q.status]}>{q.status}</Pill>
                <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", width: 80, textAlign: "right" }}>
                  {formatCurrencyCents(q.totalCents)}
                </div>
              </div>
            ))}
          </div>
        </Card>

        <Card padding="default">
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
            <div className="ops-section-label">Saved line items</div>
            <button style={{ fontSize: 12, fontWeight: 600, color: "var(--salmon-dark)", background: "none", border: "none", cursor: "pointer" }}>+ Add new</button>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
            {SAVED_LINE_ITEMS_DEMO.map((item) => (
              <div key={item.id} className="ops-row" style={{ padding: "10px 0" }}>
                <div style={{ flex: 1, fontSize: 12.5, color: "var(--text)" }}>{item.name}</div>
                <div style={{ fontSize: 11, color: "var(--text-soft)", width: 30 }}>/{item.unit}</div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", width: 70, textAlign: "right" }}>
                  {formatCurrencyCents(item.priceCents)}
                </div>
                <button
                  style={{
                    width: 28, height: 28, borderRadius: 8,
                    background: "var(--indigo-50)", color: "var(--indigo)",
                    border: "none", cursor: "pointer",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}
                  onClick={() => {
                    setLines((ls) => [
                      ...ls,
                      {
                        id: `l-${Date.now()}`,
                        name: item.name,
                        desc: "",
                        unit: item.unit,
                        qty: 1,
                        priceCents: item.priceCents,
                      },
                    ]);
                  }}
                  aria-label={`Add ${item.name}`}
                >
                  <Icon name="plus" size={14} stroke={2} />
                </button>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Right column — quote builder */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
          <Pill tone="neutral">Editing draft</Pill>
          <Pill tone="indigo">{QUOTE_BUILDER_DEMO.number}</Pill>
        </div>
        <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
          {QUOTE_BUILDER_DEMO.customer}
        </div>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 14 }}>{QUOTE_BUILDER_DEMO.property}</div>
        <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
          <button className="ops-button ops-button--ghost">Preview</button>
          <button className="ops-button ops-button--ghost">Save draft</button>
          <button className="ops-button ops-button--salmon" style={{ marginLeft: "auto" }}>Send to homeowner</button>
        </div>

        {/* Spreadsheet */}
        <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 12, overflow: "hidden" }}>
          <div style={{ display: "grid", gridTemplateColumns: "32px 1fr 60px 60px 100px 100px 30px", padding: "10px 12px", borderBottom: "1px solid var(--neutral-200)", background: "var(--pearl)", fontSize: 10.5, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>
            <span />
            <span>Item</span>
            <span>Unit</span>
            <span>Qty</span>
            <span style={{ textAlign: "right" }}>Unit price</span>
            <span style={{ textAlign: "right" }}>Subtotal</span>
            <span />
          </div>
          {lines.map((line) => (
            <div
              key={line.id}
              style={{
                display: "grid",
                gridTemplateColumns: "32px 1fr 60px 60px 100px 100px 30px",
                padding: "12px",
                borderBottom: "1px solid var(--neutral-200)",
                alignItems: "center",
              }}
            >
              <Icon name="drag" size={14} color="var(--text-soft)" stroke={1.6} />
              <div>
                <div style={{ fontSize: 13, fontWeight: 500, color: "var(--text)" }}>{line.name}</div>
                {line.desc && <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{line.desc}</div>}
              </div>
              <div style={{ fontSize: 12, color: "var(--text)", fontFamily: "var(--sans)", fontVariantNumeric: "tabular-nums" }}>{line.unit}</div>
              <div style={{ fontSize: 12, color: "var(--text)", fontVariantNumeric: "tabular-nums" }}>{line.qty}</div>
              <div style={{ fontSize: 12, color: "var(--text)", fontVariantNumeric: "tabular-nums", textAlign: "right" }}>{formatCurrencyCents(line.priceCents)}</div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", textAlign: "right", fontVariantNumeric: "tabular-nums" }}>
                {formatCurrencyCents(line.qty * line.priceCents)}
              </div>
              <button
                style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer" }}
                onClick={() => setLines((ls) => ls.filter((l) => l.id !== line.id))}
                aria-label="Remove line"
              >
                <Icon name="remove" size={14} stroke={2} />
              </button>
            </div>
          ))}
          <div style={{ padding: "12px", fontSize: 12, color: "var(--text-muted)" }}>
            <button style={{ background: "none", border: "none", color: "var(--salmon-dark)", fontWeight: 600, cursor: "pointer", fontSize: 12 }}>
              + Add line
            </button>
            <span style={{ marginLeft: 6 }}>or pick from saved →</span>
          </div>
        </div>

        {/* Totals footer */}
        <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
          <div style={{ width: 280, display: "flex", flexDirection: "column", gap: 6 }}>
            <Row label="Subtotal" value={formatCurrencyCents(totals.subtotal)} />
            <Row label={`Materials markup (${(QUOTE_BUILDER_DEMO.materialsMarkupBp / 100).toFixed(0)}%)`} value={formatCurrencyCents(totals.materials)} />
            <Row label={`Tax (${(QUOTE_BUILDER_DEMO.taxBp / 100).toFixed(2)}% MA)`} value={formatCurrencyCents(totals.tax)} />
            <div style={{ borderTop: "1px solid var(--neutral-200)", paddingTop: 8, display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <span style={{ fontSize: 12.5, fontWeight: 600, color: "var(--text)" }}>Total</span>
              <span style={{ fontFamily: "var(--serif)", fontSize: 26, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                {formatCurrencyCents(totals.total)}
              </span>
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12.5, color: "var(--text-muted)" }}>
      <span>{label}</span>
      <span style={{ fontVariantNumeric: "tabular-nums" }}>{value}</span>
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
