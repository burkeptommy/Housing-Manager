import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { Icon } from "./chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, postProviderAction } from "../lib/api";
import type { HomeRow, SavedQuoteItem } from "../lib/types";

// ─── Context for opening the modal from anywhere ───

interface NewQuoteContextValue {
  open: (opts?: { propertyId?: string; requestId?: string; title?: string }) => void;
}
const NewQuoteContext = createContext<NewQuoteContextValue | null>(null);

interface OpenOpts {
  propertyId?: string;
  requestId?: string;
  title?: string;
}

const _openTrigger: { current: ((opts?: OpenOpts) => void) | null } = { current: null };

export function NewQuoteProvider({ children }: { children: ReactNode }) {
  const value: NewQuoteContextValue = {
    open: (opts) => _openTrigger.current?.(opts),
  };
  // Topbar dispatches a window event to open the modal from anywhere
  useEffect(() => {
    function handler(e: Event) {
      const detail = (e as CustomEvent).detail as OpenOpts | undefined;
      _openTrigger.current?.(detail);
    }
    window.addEventListener("ops:open-new-quote", handler);
    return () => window.removeEventListener("ops:open-new-quote", handler);
  }, []);
  return <NewQuoteContext.Provider value={value}>{children}</NewQuoteContext.Provider>;
}

export function useNewQuoteModal(): NewQuoteContextValue {
  const ctx = useContext(NewQuoteContext);
  if (!ctx) throw new Error("useNewQuoteModal must be used inside <NewQuoteProvider>");
  return ctx;
}

// ─── Modal ───

interface DraftLine {
  key: string;
  name: string;
  description: string;
  unit: string;
  quantity: number;
  unitPrice: number;
  savedItemId?: string;
}

export function NewQuoteModal() {
  const { dashboard, refresh } = useWorkspace();
  const [open, setOpen] = useState(false);
  const [propertyId, setPropertyId] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [scopeNotes, setScopeNotes] = useState("");
  const [homeownerMessage, setHomeownerMessage] = useState("");
  const [lines, setLines] = useState<DraftLine[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [showSavedPicker, setShowSavedPicker] = useState(false);

  // Register the global open trigger
  useEffect(() => {
    _openTrigger.current = (opts?: OpenOpts) => {
      setOpen(true);
      setPropertyId(opts?.propertyId ?? null);
      setRequestId(opts?.requestId ?? null);
      setTitle(opts?.title ?? "");
      setLines([]);
      setScopeNotes("");
      setHomeownerMessage("");
    };
    return () => {
      _openTrigger.current = null;
    };
  }, []);

  const homes = useMemo(() => dashboard?.homes ?? [], [dashboard]);
  const savedItems = useMemo(() => dashboard?.savedQuoteItems ?? [], [dashboard]);
  const selectedHome = useMemo(() => homes.find((h) => h.propertyId === propertyId) ?? null, [homes, propertyId]);

  const subtotal = lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);

  if (!open || !dashboard) return null;

  function addBlankLine() {
    setLines((ls) => [
      ...ls,
      { key: `l-${Date.now()}`, name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0 },
    ]);
  }

  function addSavedLine(item: SavedQuoteItem) {
    setLines((ls) => [
      ...ls,
      {
        key: `l-${Date.now()}`,
        name: item.name,
        description: item.description,
        unit: item.unit,
        quantity: item.defaultQuantity,
        unitPrice: item.defaultUnitPrice,
        savedItemId: item.id,
      },
    ]);
    setShowSavedPicker(false);
  }

  function updateLine(key: string, patch: Partial<DraftLine>) {
    setLines((ls) => ls.map((l) => (l.key === key ? { ...l, ...patch } : l)));
  }

  function removeLine(key: string) {
    setLines((ls) => ls.filter((l) => l.key !== key));
  }

  async function submit(send: boolean) {
    if (!propertyId || !title.trim() || lines.length === 0 || !selectedHome) {
      alert("Pick a home, add a title, and include at least one line item.");
      return;
    }
    setSubmitting(true);
    try {
      const payload = {
        workspaceId: dashboard!.workspace.id,
        propertyId,
        householdId: selectedHome.householdId,
        requestId: requestId || undefined,
        title: title.trim(),
        scopeNotes: scopeNotes.trim() || undefined,
        homeownerMessage: homeownerMessage.trim() || undefined,
        lineItems: lines.map((l) => ({
          name: l.name,
          description: l.description,
          unit: l.unit,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          total: l.quantity * l.unitPrice,
        })),
      };
      const result = await postProviderAction("save_quote", payload);
      if (send && result && typeof result === "object" && "quote" in result) {
        const quoteId = (result as { quote: { id: string } }).quote.id;
        await postProviderAction("send_quote", {
          workspaceId: dashboard!.workspace.id,
          quoteId,
        });
      }
      await refresh();
      setOpen(false);
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't save the quote.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 55,
        background: "rgba(42,34,82,0.4)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && setOpen(false)}
    >
      <div
        style={{
          background: "#fff", borderRadius: 16,
          width: "min(820px, 95vw)",
          maxHeight: "90vh", overflowY: "auto",
          boxShadow: "0 24px 60px rgba(42,34,82,0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ padding: 24, borderBottom: "1px solid var(--neutral-200)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)" }}>New quote</div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 2 }}>
              Build a quote, save as draft, or send it straight to the homeowner.
            </div>
          </div>
          <button onClick={() => !submitting && setOpen(false)} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }} aria-label="Close">
            <Icon name="remove" size={18} stroke={2} />
          </button>
        </div>

        <div style={{ padding: 24, display: "flex", flexDirection: "column", gap: 14 }}>
          <Field label="Home">
            <select
              value={propertyId ?? ""}
              onChange={(e) => setPropertyId(e.target.value || null)}
              style={inputStyle}
            >
              <option value="">Choose a home…</option>
              {homes.map((h) => (
                <option key={h.propertyId} value={h.propertyId}>
                  {h.name} {h.address ? `· ${h.address}` : ""}
                </option>
              ))}
            </select>
            {homes.length === 0 && (
              <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 4 }}>
                No homes on file yet. Once you've worked with a homeowner, they'll appear here.
              </div>
            )}
          </Field>

          <Field label="Quote title">
            <input
              type="text"
              placeholder="e.g. Spring punch list bundle"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              style={inputStyle}
            />
          </Field>

          {/* Lines */}
          <div>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Line items</span>
              <div style={{ display: "flex", gap: 8 }}>
                <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={() => setShowSavedPicker((v) => !v)}>
                  + From saved ({savedItems.length})
                </button>
                <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={addBlankLine}>
                  + Add line
                </button>
              </div>
            </div>

            {showSavedPicker && (
              <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 10, marginBottom: 8, maxHeight: 200, overflowY: "auto" }}>
                {savedItems.length === 0 ? (
                  <div style={{ padding: 14, fontSize: 13, color: "var(--text-muted)" }}>
                    Nothing in your saved-items library yet.
                  </div>
                ) : (
                  savedItems.map((item) => (
                    <button
                      key={item.id}
                      onClick={() => addSavedLine(item)}
                      style={{
                        display: "flex", width: "100%", alignItems: "center", gap: 10,
                        padding: "10px 12px", border: "none", background: "transparent",
                        borderBottom: "1px solid var(--neutral-200)", cursor: "pointer", textAlign: "left",
                      }}
                    >
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 13, fontWeight: 600 }}>{item.name}</div>
                        {item.description && <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{item.description}</div>}
                      </div>
                      <div style={{ fontSize: 11, color: "var(--text-soft)", width: 30 }}>/{item.unit}</div>
                      <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", width: 70, textAlign: "right" }}>
                        {formatCurrency(item.defaultUnitPrice)}
                      </div>
                    </button>
                  ))
                )}
              </div>
            )}

            {lines.length === 0 ? (
              <div style={{ padding: 18, border: "1px dashed var(--neutral-300)", borderRadius: 10, textAlign: "center", fontSize: 13, color: "var(--text-muted)" }}>
                No lines yet. Add one or pull from your saved library.
              </div>
            ) : (
              <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 10, overflow: "hidden" }}>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 60px 70px 100px 100px 30px", padding: "8px 12px", borderBottom: "1px solid var(--neutral-200)", background: "var(--pearl)", fontSize: 10, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>
                  <span>Item</span>
                  <span>Unit</span>
                  <span>Qty</span>
                  <span style={{ textAlign: "right" }}>Price</span>
                  <span style={{ textAlign: "right" }}>Subtotal</span>
                  <span />
                </div>
                {lines.map((line) => (
                  <div
                    key={line.key}
                    style={{ display: "grid", gridTemplateColumns: "1fr 60px 70px 100px 100px 30px", padding: 10, borderBottom: "1px solid var(--neutral-200)", alignItems: "center", gap: 6 }}
                  >
                    <input
                      type="text"
                      placeholder="Item name"
                      value={line.name}
                      onChange={(e) => updateLine(line.key, { name: e.target.value })}
                      style={inlineInputStyle}
                    />
                    <input
                      type="text"
                      value={line.unit}
                      onChange={(e) => updateLine(line.key, { unit: e.target.value })}
                      style={inlineInputStyle}
                    />
                    <input
                      type="number"
                      min="0"
                      step="0.5"
                      value={line.quantity}
                      onChange={(e) => updateLine(line.key, { quantity: Number(e.target.value) || 0 })}
                      style={inlineInputStyle}
                    />
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      value={line.unitPrice}
                      onChange={(e) => updateLine(line.key, { unitPrice: Number(e.target.value) || 0 })}
                      style={{ ...inlineInputStyle, textAlign: "right" }}
                    />
                    <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, textAlign: "right" }}>
                      {formatCurrency(line.quantity * line.unitPrice)}
                    </div>
                    <button onClick={() => removeLine(line.key)} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 2 }} aria-label="Remove line">
                      <Icon name="remove" size={14} stroke={2} />
                    </button>
                  </div>
                ))}
                <div style={{ display: "flex", justifyContent: "space-between", padding: "12px 16px", background: "var(--pearl)" }}>
                  <span style={{ fontSize: 12.5, fontWeight: 600 }}>Subtotal</span>
                  <span style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                    {formatCurrency(subtotal)}
                  </span>
                </div>
              </div>
            )}
          </div>

          <Field label="Scope notes (internal)">
            <textarea
              placeholder="Anything you want to remember about this scope…"
              value={scopeNotes}
              onChange={(e) => setScopeNotes(e.target.value)}
              style={{ ...inputStyle, minHeight: 60, resize: "vertical" }}
            />
          </Field>

          <Field label="Message to the homeowner">
            <textarea
              placeholder="What you'd like the homeowner to read along with the quote…"
              value={homeownerMessage}
              onChange={(e) => setHomeownerMessage(e.target.value)}
              style={{ ...inputStyle, minHeight: 80, resize: "vertical" }}
            />
          </Field>
        </div>

        <div style={{ padding: 18, borderTop: "1px solid var(--neutral-200)", display: "flex", gap: 8, justifyContent: "flex-end" }}>
          <button className="ops-button ops-button--ghost" onClick={() => !submitting && setOpen(false)} disabled={submitting}>Cancel</button>
          <button className="ops-button ops-button--ghost" onClick={() => submit(false)} disabled={submitting}>
            {submitting ? "Saving…" : "Save as draft"}
          </button>
          <button className="ops-button ops-button--salmon" onClick={() => submit(true)} disabled={submitting}>
            {submitting ? "Sending…" : "Save & send to homeowner"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>{label}</span>
      {children}
    </label>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "10px 12px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 10,
  background: "#fff",
  fontSize: 13,
  fontFamily: "var(--sans)",
  color: "var(--text)",
};

const inlineInputStyle: React.CSSProperties = {
  width: "100%",
  padding: "6px 8px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 6,
  background: "#fff",
  fontSize: 12.5,
  fontFamily: "var(--sans)",
  color: "var(--text)",
};

// satisfy unused-import lint when modal is rendered conditionally
export type _NewQuoteHomeShape = HomeRow;
