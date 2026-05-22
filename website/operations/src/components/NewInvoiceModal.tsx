import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { Icon } from "./chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, postProviderAction } from "../lib/api";
import type { HomeRow, Quote } from "../lib/types";

// ─── Context for opening the modal from anywhere ───

interface OpenOpts {
  propertyId?: string;
  requestId?: string;
  title?: string;
  /**
   * If passed, the modal opens in edit mode for an existing draft.
   * Status must be `draft` — sent / paid invoices are read-only and
   * routed through the detail screen instead.
   */
  editInvoiceId?: string;
  /** When set, prefill line items + total from the approved quote. */
  sourceQuoteId?: string;
}

interface NewInvoiceContextValue {
  open: (opts?: OpenOpts) => void;
}

const NewInvoiceContext = createContext<NewInvoiceContextValue | null>(null);

const _openTrigger: { current: ((opts?: OpenOpts) => void) | null } = { current: null };

export function NewInvoiceProvider({ children }: { children: ReactNode }) {
  const value: NewInvoiceContextValue = {
    open: (opts) => _openTrigger.current?.(opts),
  };
  useEffect(() => {
    function handler(e: Event) {
      const detail = (e as CustomEvent).detail as OpenOpts | undefined;
      _openTrigger.current?.(detail);
    }
    window.addEventListener("ops:open-new-invoice", handler);
    return () => window.removeEventListener("ops:open-new-invoice", handler);
  }, []);
  return <NewInvoiceContext.Provider value={value}>{children}</NewInvoiceContext.Provider>;
}

export function useNewInvoiceModal(): NewInvoiceContextValue {
  const ctx = useContext(NewInvoiceContext);
  if (!ctx) throw new Error("useNewInvoiceModal must be used inside <NewInvoiceProvider>");
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
}

export function NewInvoiceModal() {
  const { dashboard, refresh } = useWorkspace();
  const [open, setOpen] = useState(false);
  const [propertyId, setPropertyId] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(null);
  const [editInvoiceId, setEditInvoiceId] = useState<string | null>(null);
  const [sourceQuoteId, setSourceQuoteId] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [scopeNotes, setScopeNotes] = useState("");
  const [homeownerMessage, setHomeownerMessage] = useState("");
  const [dueDate, setDueDate] = useState<string>("");
  const [lines, setLines] = useState<DraftLine[]>([]);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    _openTrigger.current = (opts?: OpenOpts) => {
      const editing = opts?.editInvoiceId
        ? dashboard?.invoices.find((inv) => inv.id === opts.editInvoiceId) ?? null
        : null;

      const sourceQuote = opts?.sourceQuoteId
        ? dashboard?.quotes.find((q) => q.id === opts.sourceQuoteId) ?? null
        : null;

      setOpen(true);
      setEditInvoiceId(opts?.editInvoiceId ?? null);
      setSourceQuoteId(opts?.sourceQuoteId ?? null);

      if (editing) {
        setPropertyId(editing.propertyId || null);
        setRequestId(editing.requestId || null);
        setTitle(editing.title);
        setScopeNotes(editing.scopeNotes ?? "");
        setHomeownerMessage(editing.homeownerMessage ?? "");
        setDueDate(editing.dueDate ?? "");
        setLines(
          editing.lineItems.map((line, i) => ({
            key: `edit-${editing.id}-${i}`,
            name: line.name,
            description: line.description ?? "",
            unit: line.unit ?? "ea",
            quantity: line.quantity ?? 1,
            unitPrice: line.unitPrice ?? 0,
          })),
        );
        return;
      }

      if (sourceQuote) {
        setPropertyId(sourceQuote.propertyId || opts?.propertyId || null);
        setRequestId(sourceQuote.requestId || opts?.requestId || null);
        // B4 brand voice: strip em dashes that may have crept in from
        // legacy quote titles before auto-stamping the invoice title.
        const cleanedQuoteTitle = sourceQuote.title.replace(/—/g, ":");
        setTitle(`Invoice for ${cleanedQuoteTitle}`);
        setScopeNotes(sourceQuote.scopeNotes ?? "");
        setHomeownerMessage(sourceQuote.homeownerMessage ?? "");
        setDueDate("");
        setLines(
          sourceQuote.lineItems.map((line, i) => ({
            key: `quote-${sourceQuote.id}-${i}`,
            name: line.name,
            description: line.description ?? "",
            unit: line.unit ?? "ea",
            quantity: line.quantity ?? 1,
            unitPrice: line.unitPrice ?? 0,
          })),
        );
        return;
      }

      setPropertyId(opts?.propertyId ?? null);
      setRequestId(opts?.requestId ?? null);
      setTitle(opts?.title ?? "");
      setScopeNotes("");
      setHomeownerMessage("");
      setDueDate("");
      setLines([]);
    };
    return () => {
      _openTrigger.current = null;
    };
  }, [dashboard]);

  const isEditing = Boolean(editInvoiceId);

  const homes = useMemo(() => dashboard?.homes ?? [], [dashboard]);
  const approvedQuotes = useMemo<Quote[]>(
    () => (dashboard?.quotes ?? []).filter((q) => q.status === "approved"),
    [dashboard],
  );
  const selectedHome = useMemo(
    () => homes.find((h) => h.propertyId === propertyId) ?? null,
    [homes, propertyId],
  );
  const quotesForHome = useMemo(
    () => approvedQuotes.filter((q) => q.propertyId === propertyId),
    [approvedQuotes, propertyId],
  );

  const subtotal = lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);

  if (!open || !dashboard) return null;

  function addBlankLine() {
    setLines((ls) => [
      ...ls,
      { key: `l-${Date.now()}`, name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0 },
    ]);
  }

  function applyQuotePrefill(quoteId: string) {
    const quote = (dashboard?.quotes ?? []).find((q) => q.id === quoteId);
    if (!quote) return;
    setSourceQuoteId(quoteId);
    setTitle(`Invoice for ${quote.title.replace(/—/g, ":")}`);
    setScopeNotes(quote.scopeNotes ?? "");
    setHomeownerMessage(quote.homeownerMessage ?? "");
    setLines(
      quote.lineItems.map((line, i) => ({
        key: `quote-${quote.id}-${i}`,
        name: line.name,
        description: line.description ?? "",
        unit: line.unit ?? "ea",
        quantity: line.quantity ?? 1,
        unitPrice: line.unitPrice ?? 0,
      })),
    );
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
      const payload: Record<string, unknown> = {
        workspaceId: dashboard!.workspace.id,
        invoiceId: editInvoiceId || undefined,
        sourceQuoteId: sourceQuoteId || undefined,
        propertyId,
        householdId: selectedHome.householdId,
        requestId: requestId || undefined,
        title: title.trim(),
        scopeNotes: scopeNotes.trim() || undefined,
        homeownerMessage: homeownerMessage.trim() || undefined,
        dueDate: dueDate || undefined,
        lineItems: lines.map((l) => ({
          name: l.name,
          description: l.description,
          unit: l.unit,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
        })),
      };
      const action = send ? "send_invoice" : "save_invoice";
      await postProviderAction(action, payload);
      await refresh();
      setOpen(false);
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't save the invoice.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 55,
        background: "rgba(15, 10, 40,0.4)",
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
          boxShadow: "0 24px 60px rgba(15, 10, 40,0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ padding: 24, borderBottom: "1px solid var(--neutral-200)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)" }}>
              {isEditing ? "Edit invoice" : "New invoice"}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 2 }}>
              {isEditing
                ? "Update the line items, due date, or message before sending."
                : "Convert an approved quote, or build a fresh invoice from scratch."}
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
              onChange={(e) => {
                setPropertyId(e.target.value || null);
                // Drop the source quote since it may not match the new home.
                setSourceQuoteId(null);
              }}
              style={inputStyle}
            >
              <option value="">Choose a home...</option>
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

          {!isEditing && propertyId && quotesForHome.length > 0 && (
            <Field label="Start from approved quote (optional)">
              <select
                value={sourceQuoteId ?? ""}
                onChange={(e) => {
                  if (e.target.value) {
                    applyQuotePrefill(e.target.value);
                  } else {
                    setSourceQuoteId(null);
                  }
                }}
                style={inputStyle}
              >
                <option value="">Blank invoice</option>
                {quotesForHome.map((q) => (
                  <option key={q.id} value={q.id}>
                    {q.title} · {formatCurrency(q.total)} · approved {q.approvedAt ? new Date(q.approvedAt).toLocaleDateString() : ""}
                  </option>
                ))}
              </select>
              <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 4 }}>
                Picking a quote prefills the line items and total. You can still edit them.
              </div>
            </Field>
          )}

          <Field label="Invoice title">
            <input
              type="text"
              placeholder="e.g. Spring punch list bundle"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              style={inputStyle}
            />
          </Field>

          <Field label="Due date">
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              style={inputStyle}
            />
          </Field>

          {/* Lines */}
          <div>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Line items</span>
              <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={addBlankLine}>
                + Add line
              </button>
            </div>

            {lines.length === 0 ? (
              <div style={{ padding: 18, border: "1px dashed var(--neutral-300)", borderRadius: 10, textAlign: "center", fontSize: 13, color: "var(--text-muted)" }}>
                No lines yet. Add one or pull from an approved quote.
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
                  <span style={{ fontSize: 12.5, fontWeight: 600 }}>Total</span>
                  <span style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                    {formatCurrency(subtotal)}
                  </span>
                </div>
              </div>
            )}
          </div>

          <Field label="Scope notes (internal)">
            <textarea
              placeholder="Anything you want to remember about this invoice..."
              value={scopeNotes}
              onChange={(e) => setScopeNotes(e.target.value)}
              style={{ ...inputStyle, minHeight: 60, resize: "vertical" }}
            />
          </Field>

          <Field label="Message to the homeowner">
            <textarea
              placeholder="What you'd like the homeowner to read along with the invoice..."
              value={homeownerMessage}
              onChange={(e) => setHomeownerMessage(e.target.value)}
              style={{ ...inputStyle, minHeight: 80, resize: "vertical" }}
            />
          </Field>
        </div>

        <div style={{ padding: 18, borderTop: "1px solid var(--neutral-200)", display: "flex", gap: 8, justifyContent: "flex-end" }}>
          <button className="ops-button ops-button--ghost" onClick={() => !submitting && setOpen(false)} disabled={submitting}>Cancel</button>
          <button className="ops-button ops-button--ghost" onClick={() => submit(false)} disabled={submitting}>
            {submitting ? "Saving..." : isEditing ? "Save changes" : "Save as draft"}
          </button>
          <button className="ops-button ops-button--salmon" onClick={() => submit(true)} disabled={submitting}>
            {submitting ? "Sending..." : "Save and send"}
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

// satisfy unused-import lint
export type _NewInvoiceHomeShape = HomeRow;
