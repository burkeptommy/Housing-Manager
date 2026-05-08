import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { Icon } from "./chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, postProviderAction } from "../lib/api";
import type { HomeRow, SavedQuoteItem } from "../lib/types";

// ─── Context for opening the modal from anywhere ───

interface NewQuoteContextValue {
  open: (opts?: { propertyId?: string; requestId?: string; title?: string; editQuoteId?: string }) => void;
}
const NewQuoteContext = createContext<NewQuoteContextValue | null>(null);

interface OpenOpts {
  propertyId?: string;
  requestId?: string;
  title?: string;
  suggestions?: SuggestedLine[];
  /**
   * If passed, the modal opens in edit mode for this existing quote.
   * Pre-fills every field from `dashboard.quotes` and routes the
   * save_quote action through `quoteId` so the row updates instead
   * of inserting a new draft.
   */
  editQuoteId?: string;
}

interface SuggestedLine {
  name: string;
  description?: string;
  unit?: string;
  quantity?: number;
  unitPrice?: number;
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

/**
 * Wave V.1 — quote bundles (good/better/best).
 *
 * Each quote is now a list of tiers. A single tier is a regular quote
 * (the existing flow). Two or more tiers turns the modal into bundle
 * mode and routes through `save_quote_bundle` / `send_quote_bundle`
 * instead of `save_quote` / `send_quote`. The contractor stays in one
 * modal and just clicks "+ Add another tier" to upgrade.
 */
interface DraftTier {
  key: string;
  label: string;
  lines: DraftLine[];
  showSavedPicker: boolean;
}

const DEFAULT_TIER_LABELS = ["Good", "Better", "Best", "Premium"];

function makeBlankTier(idx: number): DraftTier {
  return {
    key: `tier-${Date.now()}-${idx}`,
    label: DEFAULT_TIER_LABELS[idx] ?? `Option ${idx + 1}`,
    lines: [],
    showSavedPicker: false,
  };
}

export function NewQuoteModal() {
  const { dashboard, refresh } = useWorkspace();
  const [open, setOpen] = useState(false);
  const [propertyId, setPropertyId] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(null);
  const [editQuoteId, setEditQuoteId] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [scopeNotes, setScopeNotes] = useState("");
  const [homeownerMessage, setHomeownerMessage] = useState("");
  const [tiers, setTiers] = useState<DraftTier[]>([makeBlankTier(0)]);
  const [submitting, setSubmitting] = useState(false);

  const isBundle = tiers.length >= 2;

  // Register the global open trigger. We re-register on every dashboard
  // change so the closure can read the latest quotes when opening in
  // edit mode.
  useEffect(() => {
    _openTrigger.current = (opts?: OpenOpts) => {
      // Edit mode — pre-fill every field from the existing quote.
      // Bundle-edit is intentionally out of scope for V1 demo: bundles
      // edit only their tier-0 line items via this modal. The full
      // bundle editor is a follow-on phase.
      const existing = opts?.editQuoteId
        ? dashboard?.quotes.find((q) => q.id === opts.editQuoteId) ?? null
        : null;

      setOpen(true);
      setEditQuoteId(opts?.editQuoteId ?? null);

      if (existing) {
        setPropertyId(existing.propertyId || opts?.propertyId || null);
        setRequestId(existing.requestId || opts?.requestId || null);
        setTitle(existing.title);
        setScopeNotes(existing.scopeNotes ?? "");
        setHomeownerMessage(existing.homeownerMessage ?? "");
        setTiers([
          {
            key: `edit-${existing.id}`,
            label: existing.bundleTierLabel ?? "Quote",
            showSavedPicker: false,
            lines: existing.lineItems.map((line, i) => ({
              key: `edit-${existing.id}-${i}`,
              name: line.name,
              description: line.description ?? "",
              unit: line.unit ?? "ea",
              quantity: line.quantity ?? 1,
              unitPrice: line.unitPrice ?? 0,
            })),
          },
        ]);
        return;
      }

      setPropertyId(opts?.propertyId ?? null);
      setRequestId(opts?.requestId ?? null);
      setTitle(opts?.title ?? "");
      setScopeNotes("");
      setHomeownerMessage("");
      // Pre-populate from suggestions (e.g. punch list items from a
      // visit). Each suggestion becomes an editable draft line so the
      // handyman can adjust quantity/price before sending.
      const seeded = (opts?.suggestions ?? []).map((s, i) => ({
        key: `seed-${Date.now()}-${i}`,
        name: s.name,
        description: s.description ?? "",
        unit: s.unit ?? "ea",
        quantity: s.quantity ?? 1,
        unitPrice: s.unitPrice ?? 0,
      }));
      setTiers([
        {
          key: `tier-${Date.now()}-0`,
          label: "Quote",
          showSavedPicker: false,
          lines: seeded,
        },
      ]);
    };
    return () => {
      _openTrigger.current = null;
    };
  }, [dashboard]);

  const isEditing = Boolean(editQuoteId);

  const homes = useMemo(() => dashboard?.homes ?? [], [dashboard]);
  const savedItems = useMemo(() => dashboard?.savedQuoteItems ?? [], [dashboard]);
  const selectedHome = useMemo(() => homes.find((h) => h.propertyId === propertyId) ?? null, [homes, propertyId]);

  // Per-tier subtotals for the live "Subtotal" footer in each tier card.
  const tierSubtotals = tiers.map((t) => t.lines.reduce((s, l) => s + l.quantity * l.unitPrice, 0));

  if (!open || !dashboard) return null;

  function addBlankLine(tierKey: string) {
    setTiers((ts) =>
      ts.map((t) =>
        t.key === tierKey
          ? {
              ...t,
              lines: [
                ...t.lines,
                { key: `l-${Date.now()}`, name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0 },
              ],
            }
          : t,
      ),
    );
  }

  function addSavedLine(tierKey: string, item: SavedQuoteItem) {
    setTiers((ts) =>
      ts.map((t) =>
        t.key === tierKey
          ? {
              ...t,
              showSavedPicker: false,
              lines: [
                ...t.lines,
                {
                  key: `l-${Date.now()}`,
                  name: item.name,
                  description: item.description,
                  unit: item.unit,
                  quantity: item.defaultQuantity,
                  unitPrice: item.defaultUnitPrice,
                  savedItemId: item.id,
                },
              ],
            }
          : t,
      ),
    );
  }

  function updateLine(tierKey: string, lineKey: string, patch: Partial<DraftLine>) {
    setTiers((ts) =>
      ts.map((t) =>
        t.key === tierKey
          ? { ...t, lines: t.lines.map((l) => (l.key === lineKey ? { ...l, ...patch } : l)) }
          : t,
      ),
    );
  }

  function removeLine(tierKey: string, lineKey: string) {
    setTiers((ts) =>
      ts.map((t) => (t.key === tierKey ? { ...t, lines: t.lines.filter((l) => l.key !== lineKey) } : t)),
    );
  }

  function toggleSavedPicker(tierKey: string) {
    setTiers((ts) =>
      ts.map((t) => (t.key === tierKey ? { ...t, showSavedPicker: !t.showSavedPicker } : t)),
    );
  }

  function updateTierLabel(tierKey: string, nextLabel: string) {
    setTiers((ts) => ts.map((t) => (t.key === tierKey ? { ...t, label: nextLabel } : t)));
  }

  function addTier() {
    if (tiers.length >= 4) return;
    setTiers((ts) => {
      // First call upgrades the single tier 0 to "Good" so the labels
      // read Good/Better/Best after the click. Don't clobber a label
      // the contractor explicitly typed.
      const upgraded =
        ts.length === 1 && (ts[0].label === "Quote" || !ts[0].label.trim())
          ? [{ ...ts[0], label: DEFAULT_TIER_LABELS[0] }]
          : ts;
      return [...upgraded, makeBlankTier(upgraded.length)];
    });
  }

  function removeTier(tierKey: string) {
    setTiers((ts) => (ts.length === 1 ? ts : ts.filter((t) => t.key !== tierKey)));
  }

  async function submit(send: boolean) {
    if (!propertyId || !title.trim() || !selectedHome) {
      alert("Pick a home and add a title.");
      return;
    }
    // Every tier needs at least one line item.
    const emptyTier = tiers.find((t) => t.lines.length === 0);
    if (emptyTier) {
      alert(`The "${emptyTier.label}" tier has no line items. Add one or remove the tier.`);
      return;
    }
    setSubmitting(true);
    try {
      // Bundle path — two or more tiers route through save_quote_bundle.
      // Bundles cannot currently be edited inline; opening an existing
      // bundle parent in this modal (a follow-on TODO) would route here
      // when there are 2+ tiers, but for V1 demo we ship draft-only.
      if (isBundle) {
        if (isEditing) {
          alert("Editing an existing bundle is not supported yet. Delete it and recreate to change tiers.");
          return;
        }
        const payload = {
          workspaceId: dashboard!.workspace.id,
          propertyId,
          householdId: selectedHome.householdId,
          requestId: requestId || undefined,
          title: title.trim(),
          scopeNotes: scopeNotes.trim() || undefined,
          homeownerMessage: homeownerMessage.trim() || undefined,
          tiers: tiers.map((t) => ({
            label: (t.label || "Option").trim(),
            scopeNotes: undefined,
            lineItems: t.lines.map((l) => ({
              name: l.name,
              description: l.description,
              unit: l.unit,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              total: l.quantity * l.unitPrice,
            })),
          })),
        };
        await postProviderAction(send ? "send_quote_bundle" : "save_quote_bundle", payload);
        await refresh();
        setOpen(false);
        return;
      }

      // Single-tier path — preserves the original save_quote / send_quote flow.
      const lines = tiers[0]?.lines ?? [];
      if (lines.length === 0) {
        alert("Add at least one line item.");
        return;
      }
      const payload = {
        workspaceId: dashboard!.workspace.id,
        // In edit mode, threading quoteId routes through the
        // existingQuote branch in the edge function so the row updates
        // instead of inserting a duplicate draft.
        quoteId: editQuoteId || undefined,
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
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)" }}>
              {isEditing ? "Edit quote" : "New quote"}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 2 }}>
              {isEditing
                ? "Update the scope, line items, or message before sending."
                : "Build a quote, save as draft, or send it straight to the homeowner."}
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

          {/* Tiers — single tier renders the original line-items table.
              Two or more tiers turns the modal into bundle mode and
              each tier shows its own labeled line-items table. */}
          {tiers.map((tier, tierIdx) => {
            const tierSubtotal = tierSubtotals[tierIdx];
            return (
              <div key={tier.key}>
                <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
                  {isBundle ? (
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <input
                        type="text"
                        value={tier.label}
                        onChange={(e) => updateTierLabel(tier.key, e.target.value)}
                        placeholder={DEFAULT_TIER_LABELS[tierIdx] ?? `Option ${tierIdx + 1}`}
                        aria-label={`Tier ${tierIdx + 1} label`}
                        style={{
                          padding: "4px 10px",
                          border: "1px solid var(--neutral-300)",
                          borderRadius: 999,
                          background: "var(--pearl)",
                          fontSize: 12,
                          fontFamily: "var(--sans)",
                          fontWeight: 700,
                          letterSpacing: "0.04em",
                          color: "var(--indigo)",
                          width: 120,
                        }}
                      />
                      <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>line items</span>
                    </div>
                  ) : (
                    <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Line items</span>
                  )}
                  <div style={{ display: "flex", gap: 8 }}>
                    <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={() => toggleSavedPicker(tier.key)}>
                      + From saved ({savedItems.length})
                    </button>
                    <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={() => addBlankLine(tier.key)}>
                      + Add line
                    </button>
                    {isBundle && (
                      <button
                        className="ops-button ops-button--ghost"
                        style={{ fontSize: 12, color: "var(--critical, #C8392F)" }}
                        onClick={() => removeTier(tier.key)}
                        aria-label={`Remove ${tier.label} tier`}
                      >
                        Remove tier
                      </button>
                    )}
                  </div>
                </div>

                {tier.showSavedPicker && (
                  <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 10, marginBottom: 8, maxHeight: 200, overflowY: "auto" }}>
                    {savedItems.length === 0 ? (
                      <div style={{ padding: 14, fontSize: 13, color: "var(--text-muted)" }}>
                        Nothing in your saved-items library yet.
                      </div>
                    ) : (
                      savedItems.map((item) => (
                        <button
                          key={item.id}
                          onClick={() => addSavedLine(tier.key, item)}
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

                {tier.lines.length === 0 ? (
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
                    {tier.lines.map((line) => (
                      <div
                        key={line.key}
                        style={{ display: "grid", gridTemplateColumns: "1fr 60px 70px 100px 100px 30px", padding: 10, borderBottom: "1px solid var(--neutral-200)", alignItems: "center", gap: 6 }}
                      >
                        <input
                          type="text"
                          placeholder="Item name"
                          value={line.name}
                          onChange={(e) => updateLine(tier.key, line.key, { name: e.target.value })}
                          style={inlineInputStyle}
                        />
                        <input
                          type="text"
                          value={line.unit}
                          onChange={(e) => updateLine(tier.key, line.key, { unit: e.target.value })}
                          style={inlineInputStyle}
                        />
                        <input
                          type="number"
                          min="0"
                          step="0.5"
                          value={line.quantity}
                          onChange={(e) => updateLine(tier.key, line.key, { quantity: Number(e.target.value) || 0 })}
                          style={inlineInputStyle}
                        />
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={line.unitPrice}
                          onChange={(e) => updateLine(tier.key, line.key, { unitPrice: Number(e.target.value) || 0 })}
                          style={{ ...inlineInputStyle, textAlign: "right" }}
                        />
                        <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, textAlign: "right" }}>
                          {formatCurrency(line.quantity * line.unitPrice)}
                        </div>
                        <button onClick={() => removeLine(tier.key, line.key)} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 2 }} aria-label="Remove line">
                          <Icon name="remove" size={14} stroke={2} />
                        </button>
                      </div>
                    ))}
                    <div style={{ display: "flex", justifyContent: "space-between", padding: "12px 16px", background: "var(--pearl)" }}>
                      <span style={{ fontSize: 12.5, fontWeight: 600 }}>{isBundle ? `${tier.label} subtotal` : "Subtotal"}</span>
                      <span style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em" }}>
                        {formatCurrency(tierSubtotal)}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            );
          })}

          {/* Add-tier button. Bumps to bundle mode the moment a second
              tier is added. Disabled in edit mode (bundle-edit not in V1)
              and capped at four tiers. */}
          {!isEditing && tiers.length < 4 && (
            <div>
              <button
                className="ops-button ops-button--ghost"
                onClick={addTier}
                style={{ fontSize: 13, width: "100%", borderStyle: "dashed", borderColor: "var(--neutral-300)" }}
              >
                {tiers.length === 1 ? "+ Offer good / better / best options" : `+ Add ${DEFAULT_TIER_LABELS[tiers.length] ?? "another"} tier`}
              </button>
              {tiers.length === 1 && (
                <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 6, textAlign: "center" }}>
                  Send a single quote with two or three tiered options. The homeowner picks the one they want.
                </div>
              )}
            </div>
          )}

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
            {submitting ? "Saving..." : isEditing ? "Save changes" : isBundle ? "Save bundle as draft" : "Save as draft"}
          </button>
          <button className="ops-button ops-button--salmon" onClick={() => submit(true)} disabled={submitting}>
            {submitting ? "Sending..." : isBundle ? "Save & send bundle" : isEditing ? "Save & send to homeowner" : "Save & send to homeowner"}
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
