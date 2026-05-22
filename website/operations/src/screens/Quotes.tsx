import { useEffect, useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { fetchQuoteComments, formatCurrency, formatRelativeTime, postProviderAction } from "../lib/api";
import type { Quote, QuoteComment, HomeRow } from "../lib/types";
import { useNewQuoteModal } from "../components/NewQuoteModal";
import { useNewInvoiceModal } from "../components/NewInvoiceModal";

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
  const newInvoice = useNewInvoiceModal();
  const [selectedQuoteId, setSelectedQuoteId] = useState<string | null>(null);
  const [busy, setBusy] = useState<"send" | "delete" | "duplicate" | null>(null);
  const [comments, setComments] = useState<QuoteComment[]>([]);
  // Wave M13 — quote duplication picker for the Operations Desk.
  // Same `duplicate_quote` action as the iOS BuildQuoteSheet's
  // duplicate flow. Opens with the operator's source quote already
  // chosen (the selected quote in the panel); they pick a target
  // home from the workspace's home list and confirm.
  const [duplicateModalOpen, setDuplicateModalOpen] = useState(false);
  const [duplicateTargetHome, setDuplicateTargetHome] = useState<HomeRow | null>(null);
  const [duplicateError, setDuplicateError] = useState<string | null>(null);
  // Per-quote homeowner search filter so a workspace with 50+ homes
  // doesn't dump a huge list on the operator.
  const [duplicateSearch, setDuplicateSearch] = useState("");
  const [commentsBusy, setCommentsBusy] = useState(false);
  const [showSavedForm, setShowSavedForm] = useState(false);
  const [savedFormBusy, setSavedFormBusy] = useState(false);
  const [savedFormName, setSavedFormName] = useState("");
  const [savedFormUnit, setSavedFormUnit] = useState("ea");
  const [savedFormPrice, setSavedFormPrice] = useState(0);

  const allQuotes = useMemo(() => dashboard?.quotes ?? [], [dashboard]);
  const savedItems = useMemo(() => dashboard?.savedQuoteItems ?? [], [dashboard]);

  // Wave V.1 — quote bundles. The pipeline list shows ONE row per
  // bundle (the parent); children render as tier cards in the detail
  // panel. Counter-offer chains (Phase 73b) keep their per-version
  // visibility because they're not bundle parents — `bundleMeta` is
  // only set on bundle parents via the BUNDLE_MARKER sentinel.
  const quotes = useMemo(
    () => allQuotes.filter((q) => !q.parentQuoteId || q.bundleMeta !== null),
    [allQuotes],
  );

  // The detail panel needs to walk the parent → children fan-out.
  // Build an index keyed by parent id once per dashboard refresh.
  const childrenByParentId = useMemo(() => {
    const map = new Map<string, typeof allQuotes>();
    for (const q of allQuotes) {
      if (q.parentQuoteId) {
        const arr = map.get(q.parentQuoteId) ?? [];
        arr.push(q);
        map.set(q.parentQuoteId, arr);
      }
    }
    // Sort children by tier order from the parent's bundleMeta when
    // available so the cards render in the contractor-authored order.
    return map;
  }, [allQuotes]);

  const selected = useMemo(() => {
    if (!quotes.length) return null;
    if (selectedQuoteId) return quotes.find((q) => q.id === selectedQuoteId) ?? quotes[0];
    return quotes[0];
  }, [selectedQuoteId, quotes]);

  // For a bundle parent, the ordered children. Empty array for non-bundle quotes.
  const selectedBundleChildren = useMemo(() => {
    if (!selected || !selected.bundleMeta) return [] as typeof allQuotes;
    const kids = (childrenByParentId.get(selected.id) ?? []).slice();
    const order = selected.bundleMeta.tiers;
    kids.sort((a, b) => {
      const ai = order.indexOf(a.bundleTierLabel ?? "");
      const bi = order.indexOf(b.bundleTierLabel ?? "");
      return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
    });
    return kids;
  }, [selected, childrenByParentId]);

  const isSelectedBundle = Boolean(selected?.bundleMeta);

  // Fetch the comment thread for the selected quote so we can show
  // homeowner questions inline + reply per-line.
  useEffect(() => {
    if (!selected) {
      setComments([]);
      return;
    }
    setCommentsBusy(true);
    let cancelled = false;
    fetchQuoteComments(selected.id)
      .then((rows) => { if (!cancelled) setComments(rows); })
      .catch((e) => { if (!cancelled) console.warn("[Quotes] fetchQuoteComments failed", e); })
      .finally(() => { if (!cancelled) setCommentsBusy(false); });
    return () => { cancelled = true; };
  }, [selected?.id]);

  async function reloadComments() {
    if (!selected) return;
    try {
      const rows = await fetchQuoteComments(selected.id);
      setComments(rows);
    } catch (e) {
      console.warn("[Quotes] reloadComments failed", e);
    }
  }

  if (!dashboard) return null;

  if (quotes.length === 0 && savedItems.length === 0) {
    return (
      <EmptyState
        icon="quote"
        title="No quotes yet"
        body="Send your first quote and the pipeline starts building. You can also seed the saved-items library with the small jobs you bid on most."
        cta={{ label: "+ Draft a quote", onClick: () => newQuote.open() }}
      />
    );
  }

  // Wave M13 — duplicate handler. Walks `duplicate_quote` with the
  // selected quote as the source + the operator-picked home as the
  // target. On success, refreshes the dashboard so the new draft
  // appears in the pipeline list, then jumps the selection to it.
  // dashboard is guaranteed non-null here because the early-return
  // bail above runs first when dashboard is missing.
  async function handleDuplicate() {
    if (!selected || !dashboard) return;
    if (!duplicateTargetHome) {
      setDuplicateError("Pick a home to duplicate to first.");
      return;
    }
    setBusy("duplicate");
    setDuplicateError(null);
    try {
      const result = await postProviderAction<{ duplicate: { id: string; isBundle: boolean; title: string } }>(
        "duplicate_quote",
        {
          workspaceId: dashboard.workspace.id,
          sourceQuoteId: selected.id,
          targetHouseholdId: duplicateTargetHome.householdId,
          targetPropertyId: duplicateTargetHome.propertyId,
          // No targetRequestId — this is the operator desk, not a
          // visit-context flow. The duplicate lands as a household-
          // scoped draft the operator can then attach to a request.
        },
      );
      await refresh();
      setDuplicateModalOpen(false);
      setDuplicateTargetHome(null);
      // Jump to the new duplicate so the operator sees it landed.
      setSelectedQuoteId(result.duplicate.id);
    } catch (e) {
      setDuplicateError(e instanceof Error ? e.message : "Couldn't duplicate the quote.");
    } finally {
      setBusy(null);
    }
  }

  // Workspace's home roster filtered by the search box. Empty search
  // shows every home alphabetized by name. dashboard is null-checked
  // by the early-return above, but this branch fires before it; use
  // optional chaining + empty fallback.
  const filteredHomes = (dashboard?.homes ?? [])
    .filter((h) => {
      if (!duplicateSearch.trim()) return true;
      const q = duplicateSearch.trim().toLowerCase();
      return (
        h.name.toLowerCase().includes(q) ||
        h.address.toLowerCase().includes(q)
      );
    })
    .sort((a, b) => a.name.localeCompare(b.name));

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
              {quotes.map((q) => {
                const kids = q.bundleMeta ? childrenByParentId.get(q.id) ?? [] : [];
                const isBundle = q.bundleMeta !== null;
                const tierTotals = isBundle ? kids.map((c) => c.total).filter((n) => n > 0) : [];
                const minTotal = tierTotals.length ? Math.min(...tierTotals) : 0;
                const maxTotal = tierTotals.length ? Math.max(...tierTotals) : 0;
                const subtitleSuffix = isBundle
                  ? `${kids.length} option${kids.length === 1 ? "" : "s"}`
                  : `${q.itemCount} item${q.itemCount === 1 ? "" : "s"}`;
                return (
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
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)", display: "flex", alignItems: "center", gap: 6 }}>
                        {q.audienceLabel}
                        {isBundle && (
                          <span style={{
                            fontSize: 10, fontWeight: 700, letterSpacing: "0.06em",
                            color: "var(--indigo)",
                            background: "var(--pearl)",
                            padding: "2px 7px", borderRadius: 999,
                            border: "1px solid var(--neutral-300)",
                          }}>
                            BUNDLE
                          </span>
                        )}
                        {q.suggestedByRequestId && (
                          /* Wave M8 — quote was staged from the field
                             tech's end-of-visit wizard. Operator
                             knows it needs line items + a send. */
                          <span style={{
                            fontSize: 10, fontWeight: 700, letterSpacing: "0.06em",
                            color: "var(--indigo)",
                            background: "var(--pearl)",
                            padding: "2px 7px", borderRadius: 999,
                            border: "1px solid var(--neutral-300)",
                          }}>
                            SUGGESTED
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                        {q.title} · {subtitleSuffix} · {formatRelativeTime(q.updatedAt)}
                      </div>
                    </div>
                    <Pill tone={STATUS_TONE[q.status] ?? "neutral"}>{q.statusLabel}</Pill>
                    <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", width: 100, textAlign: "right" }}>
                      {isBundle && tierTotals.length > 1 && minTotal !== maxTotal
                        ? `${formatCurrency(minTotal)}–${formatCurrency(maxTotal)}`
                        : formatCurrency(isBundle && tierTotals.length ? maxTotal : q.total)}
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </Card>

        <Card padding="default">
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
            <div className="ops-section-label">Saved line items</div>
            <button
              onClick={() => setShowSavedForm((v) => !v)}
              style={{ fontSize: 12, fontWeight: 600, color: "var(--salmon-dark)", background: "none", border: "none", cursor: "pointer" }}
            >
              {showSavedForm ? "Cancel" : "+ Add new"}
            </button>
          </div>
          {showSavedForm && (
            <div style={{ padding: 12, marginBottom: 10, border: "1px solid var(--neutral-200)", borderRadius: 10, background: "var(--pearl)", display: "flex", flexDirection: "column", gap: 8 }}>
              <input
                type="text"
                placeholder="Item name (e.g. Light fixture install)"
                value={savedFormName}
                onChange={(e) => setSavedFormName(e.target.value)}
                style={{ padding: "8px 10px", border: "1px solid var(--neutral-200)", borderRadius: 8, background: "#fff", fontSize: 13, fontFamily: "var(--sans)", color: "var(--text)" }}
              />
              <div style={{ display: "flex", gap: 8 }}>
                <input
                  type="text"
                  placeholder="Unit"
                  value={savedFormUnit}
                  onChange={(e) => setSavedFormUnit(e.target.value)}
                  style={{ width: 70, padding: "8px 10px", border: "1px solid var(--neutral-200)", borderRadius: 8, background: "#fff", fontSize: 13, fontFamily: "var(--sans)", color: "var(--text)" }}
                />
                <input
                  type="number"
                  placeholder="Default price"
                  value={savedFormPrice || ""}
                  onChange={(e) => setSavedFormPrice(Number(e.target.value) || 0)}
                  style={{ flex: 1, padding: "8px 10px", border: "1px solid var(--neutral-200)", borderRadius: 8, background: "#fff", fontSize: 13, fontFamily: "var(--sans)", color: "var(--text)" }}
                />
                <button
                  className="ops-button ops-button--salmon"
                  disabled={savedFormBusy || !savedFormName.trim()}
                  onClick={async () => {
                    if (!savedFormName.trim()) return;
                    setSavedFormBusy(true);
                    try {
                      await postProviderAction("save_quote_item", {
                        workspaceId: dashboard.workspace.id,
                        name: savedFormName.trim(),
                        unit: savedFormUnit.trim() || "ea",
                        defaultUnitPrice: savedFormPrice,
                      });
                      await refresh();
                      setSavedFormName("");
                      setSavedFormUnit("ea");
                      setSavedFormPrice(0);
                      setShowSavedForm(false);
                    } catch (e) {
                      alert(e instanceof Error ? e.message : "Couldn't save line item.");
                    } finally {
                      setSavedFormBusy(false);
                    }
                  }}
                  style={{ minHeight: 36, fontSize: 12 }}
                >
                  {savedFormBusy ? "Saving…" : "Save"}
                </button>
              </div>
            </div>
          )}
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
              {selected.recipientAddress || selected.propertyName || "No address on file"}
            </div>
            <div style={{ display: "flex", gap: 8, marginBottom: 16, flexWrap: "wrap" }}>
              {selected.publicShareUrl && (
                <a className="ops-button ops-button--ghost" href={selected.publicShareUrl} target="_blank" rel="noopener">
                  View public link
                </a>
              )}
              {!isSelectedBundle && (
                <button
                  className="ops-button ops-button--ghost"
                  onClick={() => newQuote.open({ editQuoteId: selected.id })}
                >
                  Edit quote
                </button>
              )}
              {/* Wave M13 — kitchen-table efficiency. Same
                  `duplicate_quote` edge fn action as the iOS
                  BuildQuoteSheet's duplicate flow. Operator picks a
                  target home from the workspace's home list. */}
              <button
                className="ops-button ops-button--ghost"
                onClick={() => {
                  setDuplicateTargetHome(null);
                  setDuplicateError(null);
                  setDuplicateSearch("");
                  setDuplicateModalOpen(true);
                }}
                disabled={busy !== null}
              >
                Duplicate
              </button>
              {selected.status === "approved" && (
                <button
                  className="ops-button ops-button--ghost"
                  onClick={() => {
                    // For bundles, the chosen child holds the actual
                    // line items. Source the invoice off it instead of
                    // the empty parent.
                    const sourceId = isSelectedBundle && selected.bundleMeta?.chosenChildId
                      ? selected.bundleMeta.chosenChildId
                      : selected.id;
                    newInvoice.open({ sourceQuoteId: sourceId });
                  }}
                >
                  Convert to invoice
                </button>
              )}
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
                      if (isSelectedBundle) {
                        await postProviderAction("send_quote_bundle", {
                          workspaceId: dashboard.workspace.id,
                          bundleId: selected.id,
                        });
                      } else {
                        const result = await postProviderAction<{
                          quote: { id: string; status: string };
                          delivery?: { sent: boolean; channel?: string; error?: string };
                        }>("send_quote", {
                          workspaceId: dashboard.workspace.id,
                          quoteId: selected.id,
                        });
                        if (result.delivery && result.delivery.sent === false) {
                          console.info("[send_quote] email channel failed:", result.delivery.error);
                        }
                      }
                      await refresh();
                    } catch (e) {
                      alert(e instanceof Error ? e.message : "Couldn't send the quote.");
                    } finally {
                      setBusy(null);
                    }
                  }}
                >
                  {busy === "send" ? "Sending..." : selected.status === "draft" ? (isSelectedBundle ? "Send bundle to homeowner" : "Send to homeowner") : "Resend"}
                </button>
              )}
            </div>

            {/* Homeowner questions — surfaces above the spreadsheet so
                the provider sees them before they edit anything.
                Bundles don't carry per-line questions (homeowner picks
                a tier first) so we hide the panel in bundle mode. */}
            {selected && !isSelectedBundle && (
              <QuestionsPanel
                quote={selected}
                comments={comments}
                workspaceId={dashboard.workspace.id}
                busy={commentsBusy}
                onReplied={async () => { await reloadComments(); }}
              />
            )}

            {/* Bundle tier cards — only when the selected quote is a bundle parent. */}
            {isSelectedBundle ? (
              <BundleTierCards
                parent={selected}
                children={selectedBundleChildren}
                workspaceId={dashboard.workspace.id}
                onPicked={async () => { await refresh(); }}
              />
            ) : (
              /* Spreadsheet — single-tier path keeps its original layout. */
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
                  selected.lineItems.map((line, i) => {
                    const lineComments = line.id ? comments.filter((c) => c.lineItemId === line.id) : [];
                    const openCount = lineComments.filter((c) => c.status === "open" && c.authorRole === "homeowner").length;
                    return (
                      <div key={i} style={{ display: "grid", gridTemplateColumns: "1fr 60px 60px 100px 100px", padding: "12px", borderBottom: i < selected.lineItems.length - 1 ? "1px solid var(--neutral-200)" : "none", alignItems: "center" }}>
                        <div>
                          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                            <span style={{ fontSize: 13, fontWeight: 500, color: "var(--text)" }}>{line.name}</span>
                            {openCount > 0 && (
                              <span style={{
                                fontSize: 10, fontWeight: 700, letterSpacing: "0.04em",
                                color: "var(--salmon-dark)",
                                background: "var(--salmon-pale)",
                                padding: "2px 6px", borderRadius: 999,
                              }}>
                                {openCount} question{openCount === 1 ? "" : "s"}
                              </span>
                            )}
                          </div>
                          {line.description && <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{line.description}</div>}
                        </div>
                        <div style={{ fontSize: 12, color: "var(--text)" }}>{line.unit ?? "ea"}</div>
                        <div style={{ fontSize: 12, color: "var(--text)" }}>{line.quantity ?? 1}</div>
                        <div style={{ fontSize: 12, color: "var(--text)", textAlign: "right" }}>{formatCurrency(line.unitPrice ?? 0)}</div>
                        <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--text)", textAlign: "right" }}>
                          {formatCurrency((line.quantity ?? 1) * (line.unitPrice ?? 0))}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            )}

            {/* Totals — single-tier only. Bundles surface per-tier totals on the cards above. */}
            {!isSelectedBundle && (
              <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
                <div style={{ width: 280, display: "flex", flexDirection: "column", gap: 6 }}>
                  <Row label="Total" value={formatCurrency(selected.total)} bold />
                </div>
              </div>
            )}

            {/* Wave Z.3 — Negotiation history. Walks the parent_quote_id
                chain UP to the root and DOWN through children so the
                whole back-and-forth shows on one timeline. Renders only
                when the chain has 2+ rows (i.e., this quote was either
                derived from another or has been replaced). */}
            {!isSelectedBundle && (
              <NegotiationTimeline
                selectedQuote={selected}
                allQuotes={allQuotes}
              />
            )}
          </>
        ) : (
          <EmptyState
            icon="quote"
            title="No quote selected"
            body="Pick a quote from the list to view or edit."
          />
        )}
      </Card>

      {/* Wave M13 — quote duplication modal. Renders over the entire
          screen at z=999 with a darkening backdrop. Operator picks a
          target home from the workspace's home roster and confirms.
          The duplicate uses the same `duplicate_quote` edge fn action
          as the iOS BuildQuoteSheet's duplicate flow. */}
      {duplicateModalOpen && selected && (
        <div
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setDuplicateModalOpen(false);
            }
          }}
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(15, 10, 40, 0.55)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
            padding: 24,
          }}
        >
          <div
            style={{
              background: "#fff",
              borderRadius: 16,
              maxWidth: 520,
              width: "100%",
              maxHeight: "85vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 20px 50px rgba(15, 10, 40, 0.25)",
            }}
          >
            <div style={{ padding: "20px 24px", borderBottom: "1px solid var(--neutral-200)" }}>
              <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 4 }}>
                Duplicate quote
              </div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
                Pick a target home
              </div>
              <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 6 }}>
                Source: {selected.title} ({formatCurrency(selected.total)}, {selected.itemCount} item{selected.itemCount === 1 ? "" : "s"})
              </div>
            </div>

            <div style={{ padding: "16px 24px", borderBottom: "1px solid var(--neutral-200)" }}>
              <input
                type="text"
                placeholder="Search homes by name or address..."
                value={duplicateSearch}
                onChange={(e) => setDuplicateSearch(e.target.value)}
                style={{
                  width: "100%",
                  padding: "10px 12px",
                  border: "1px solid var(--neutral-200)",
                  borderRadius: 10,
                  background: "var(--pearl)",
                  fontSize: 13,
                  fontFamily: "var(--sans)",
                  color: "var(--text)",
                }}
              />
            </div>

            <div style={{ flex: 1, overflowY: "auto", padding: "8px 16px" }}>
              {filteredHomes.length === 0 ? (
                <div style={{ padding: 24, textAlign: "center", fontSize: 13, color: "var(--text-muted)" }}>
                  {duplicateSearch.trim() ? "No matching homes." : "No homes in this workspace yet."}
                </div>
              ) : (
                filteredHomes.map((home) => {
                  const isSelected = duplicateTargetHome?.propertyId === home.propertyId;
                  return (
                    <button
                      key={home.propertyId}
                      onClick={() => setDuplicateTargetHome(home)}
                      style={{
                        width: "100%",
                        padding: "12px 14px",
                        marginBottom: 6,
                        background: isSelected ? "var(--salmon-50)" : "var(--pearl)",
                        border: isSelected ? "1px solid var(--salmon)" : "1px solid var(--neutral-200)",
                        borderRadius: 10,
                        cursor: "pointer",
                        textAlign: "left",
                        display: "flex",
                        flexDirection: "column",
                        gap: 2,
                        minHeight: 56,
                      }}
                    >
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>
                        {home.name}
                      </div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                        {home.address}
                      </div>
                    </button>
                  );
                })
              )}
            </div>

            {duplicateError && (
              <div style={{ padding: "10px 24px", borderTop: "1px solid var(--neutral-200)", color: "var(--critical)", fontSize: 12.5 }}>
                {duplicateError}
              </div>
            )}

            <div style={{ padding: "16px 24px", borderTop: "1px solid var(--neutral-200)", display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button
                className="ops-button ops-button--ghost"
                onClick={() => setDuplicateModalOpen(false)}
                disabled={busy === "duplicate"}
              >
                Cancel
              </button>
              <button
                className="ops-button ops-button--salmon"
                onClick={handleDuplicate}
                disabled={busy === "duplicate" || !duplicateTargetHome}
              >
                {busy === "duplicate" ? "Duplicating..." : "Duplicate"}
              </button>
            </div>
          </div>
        </div>
      )}
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
    case "success":  return "#0A0A0A";
    case "warning":  return "#6938EF";
    case "critical": return "#0A0A0A";
    case "info":     return "#6B6B7B";
    default:         return "var(--neutral-400)";
  }
}

// ─── Questions panel — homeowner Q&A on a quote ──────────────────

interface QuestionsPanelProps {
  quote: { id: string; lineItems: { id?: string; name: string }[] };
  comments: QuoteComment[];
  workspaceId: string;
  busy: boolean;
  onReplied: () => Promise<void>;
}

function QuestionsPanel({ quote, comments, workspaceId, busy, onReplied }: QuestionsPanelProps) {
  // Group homeowner-authored comments. Each gets the line item context
  // (or "General" if no lineItemId) and any provider replies threaded
  // underneath via parent_comment_id.
  const homeownerQuestions = comments.filter((c) => c.authorRole === "homeowner");
  if (homeownerQuestions.length === 0 && !busy) return null;

  return (
    <div style={{
      marginBottom: 16,
      padding: 18,
      borderRadius: 14,
      background: "linear-gradient(155deg, #F4F0FE 0%, #EFEAFE 100%)",
      border: "1px solid rgba(105, 56, 239, 0.35)",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
        <Icon name="message" size={14} stroke={2} color="var(--salmon-dark)" />
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: "0.16em",
          textTransform: "uppercase", color: "var(--salmon-dark)",
        }}>
          Homeowner questions ({homeownerQuestions.length})
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {homeownerQuestions.map((q) => {
          const lineName = q.lineItemId
            ? quote.lineItems.find((li) => li.id === q.lineItemId)?.name ?? "Removed line item"
            : "General question";
          const replies = comments.filter((c) => c.parentCommentId === q.id);
          return (
            <QuestionItem
              key={q.id}
              question={q}
              lineName={lineName}
              replies={replies}
              workspaceId={workspaceId}
              onReplied={onReplied}
            />
          );
        })}
      </div>
    </div>
  );
}

function QuestionItem({
  question,
  lineName,
  replies,
  workspaceId,
  onReplied,
}: {
  question: QuoteComment;
  lineName: string;
  replies: QuoteComment[];
  workspaceId: string;
  onReplied: () => Promise<void>;
}) {
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const isAnswered = question.status === "answered" && replies.length > 0;

  async function send() {
    const trimmed = draft.trim();
    if (!trimmed) return;
    setSending(true);
    try {
      await postProviderAction("reply_to_quote_comment", {
        workspaceId,
        parentCommentId: question.id,
        body: trimmed,
      });
      setDraft("");
      await onReplied();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't send reply.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div style={{
      padding: 14,
      borderRadius: 12,
      background: "#fff",
      border: "1px solid rgba(15, 10, 40, 0.08)",
    }}>
      <div style={{
        fontSize: 10, fontWeight: 700, letterSpacing: "0.14em",
        textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 6,
      }}>
        {lineName}
      </div>
      <div style={{ fontSize: 13, color: "var(--text)", lineHeight: 1.55, marginBottom: 8, whiteSpace: "pre-wrap" }}>
        {question.body}
      </div>
      <div style={{ fontSize: 11, color: "var(--text-soft)", marginBottom: 10 }}>
        Asked {new Date(question.createdAt).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })}
        {isAnswered && (
          <span style={{ marginLeft: 8, color: "var(--success)", fontWeight: 600 }}>
            · Replied
          </span>
        )}
      </div>

      {replies.length > 0 && (
        <div style={{
          padding: 10,
          background: "var(--cream)",
          borderRadius: 8,
          marginBottom: 10,
          display: "flex", flexDirection: "column", gap: 6,
        }}>
          {replies.map((r) => (
            <div key={r.id} style={{ fontSize: 12.5, color: "var(--text)", lineHeight: 1.5, whiteSpace: "pre-wrap" }}>
              <span style={{ fontWeight: 600, color: "var(--indigo)" }}>You · </span>
              {r.body}
            </div>
          ))}
        </div>
      )}

      <div style={{ display: "flex", gap: 6 }}>
        <input
          type="text"
          placeholder="Type a reply…"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter" && !sending) void send(); }}
          disabled={sending}
          style={{
            flex: 1,
            padding: "8px 12px",
            border: "1px solid var(--neutral-200)",
            borderRadius: 8,
            background: "#fff",
            fontSize: 13,
            fontFamily: "var(--sans)",
            color: "var(--text)",
          }}
        />
        <button
          className="ops-button ops-button--salmon"
          onClick={() => void send()}
          disabled={sending || !draft.trim()}
          style={{ minHeight: 36, fontSize: 13 }}
        >
          {sending ? "Sending…" : "Reply"}
        </button>
      </div>
    </div>
  );
}

// ─── Wave V.1 — bundle tier cards (good/better/best) ──────────────
//
// Renders the 3 (or 2 / 4) tiers of a bundle parent side-by-side as
// equal-height cards. Each card shows the tier label, total, line-
// item count + a snippet, and (when in-progress) a "Mark this tier
// approved" button that fires `decide_quote_bundle`. Once a tier has
// been picked, the chosen card gets a salmon left-border + "Approved"
// pill and the others fade with a "Superseded" pill.
//
// Layout discipline: salmon is reserved for the chosen tier's accent.
// Other cards stay on the indigo-on-pearl palette to match the rest
// of the cockpit.
//
// Note: the children prop is named `children` here only because it
// reads naturally for "the children of a bundle parent". React's
// reserved `children` prop is unused — we don't render JSX content
// through this slot. The eslint disable below is intentional.

interface BundleTierCardsProps {
  parent: import("../lib/types").Quote;
  // eslint-disable-next-line react/no-children-prop
  children: import("../lib/types").Quote[];
  workspaceId: string;
  onPicked: () => Promise<void>;
}

function BundleTierCards({ parent, children, workspaceId, onPicked }: BundleTierCardsProps) {
  const [busy, setBusy] = useState<string | null>(null);
  const meta = parent.bundleMeta;
  const chosenChildId = meta?.chosenChildId ?? null;

  if (children.length === 0) {
    return (
      <div style={{ padding: 24, fontSize: 13, color: "var(--text-muted)", textAlign: "center", border: "1px dashed var(--neutral-300)", borderRadius: 12 }}>
        This bundle has no tiers. Try deleting and recreating the bundle.
      </div>
    );
  }

  const sentLabel = parent.status === "approved" ? "Approved" : parent.status === "sent" || parent.status === "viewed" ? "In review" : null;

  return (
    <div>
      {/* Header strip */}
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
        <div>
          <div className="ops-section-label">Bundle options</div>
          <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 4 }}>
            {chosenChildId
              ? `Homeowner picked the ${meta?.chosenTierLabel ?? "selected"} tier.`
              : sentLabel === "In review"
                ? `Sent to the homeowner. Waiting on a tier choice.`
                : `Draft. Send the bundle when you're ready.`}
          </div>
        </div>
        {sentLabel && <Pill tone={parent.status === "approved" ? "success" : "info"}>{sentLabel}</Pill>}
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${children.length}, 1fr)`,
          gap: 12,
        }}
      >
        {children.map((child) => {
          const isChosen = chosenChildId === child.id;
          const isSuperseded = chosenChildId !== null && !isChosen;
          const tierLabel = child.bundleTierLabel ?? "Option";
          const lineCount = child.lineItems?.length ?? 0;
          return (
            <div
              key={child.id}
              style={{
                background: isChosen ? "var(--salmon-50)" : "#fff",
                border: `1px solid ${isChosen ? "var(--salmon)" : "var(--neutral-200)"}`,
                borderLeft: isChosen ? "4px solid var(--salmon)" : `4px solid ${isSuperseded ? "var(--neutral-300)" : "var(--indigo)"}`,
                borderRadius: 14,
                padding: 16,
                opacity: isSuperseded ? 0.55 : 1,
                display: "flex",
                flexDirection: "column",
                gap: 10,
              }}
            >
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 8 }}>
                <div style={{
                  fontSize: 11, fontWeight: 800, letterSpacing: "0.12em",
                  textTransform: "uppercase",
                  color: isChosen ? "var(--salmon-dark)" : "var(--indigo)",
                }}>
                  {tierLabel}
                </div>
                {isChosen && <Pill tone="success">Approved</Pill>}
                {isSuperseded && <Pill tone="neutral">Superseded</Pill>}
              </div>

              <div style={{
                fontFamily: "var(--serif)", fontSize: 28, fontWeight: 700,
                color: isChosen ? "var(--salmon-dark)" : "var(--indigo)",
                letterSpacing: "-0.018em", lineHeight: 1.1,
              }}>
                {formatCurrency(child.total)}
              </div>

              <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
                {lineCount} line item{lineCount === 1 ? "" : "s"}
              </div>

              {/* Inline line-item summary so the contractor can scan
                  what's in each tier without drilling in. */}
              <ul style={{
                margin: 0, padding: 0, listStyle: "none",
                display: "flex", flexDirection: "column", gap: 4,
                borderTop: "1px solid var(--neutral-200)",
                paddingTop: 10,
              }}>
                {child.lineItems.slice(0, 6).map((line, i) => (
                  <li key={i} style={{
                    display: "flex", alignItems: "baseline", justifyContent: "space-between",
                    fontSize: 12, color: "var(--text)",
                  }}>
                    <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                      {line.name}
                    </span>
                    <span style={{ fontFamily: "var(--serif)", fontWeight: 600, color: "var(--text-soft)", fontSize: 11.5 }}>
                      {formatCurrency((line.quantity ?? 1) * (line.unitPrice ?? 0))}
                    </span>
                  </li>
                ))}
                {child.lineItems.length > 6 && (
                  <li style={{ fontSize: 11, color: "var(--text-muted)" }}>
                    + {child.lineItems.length - 6} more
                  </li>
                )}
              </ul>

              {/* Action — only when sent & undecided. Provider-side
                  acceptance covers the in-person walkthrough demo. */}
              {(parent.status === "sent" || parent.status === "viewed") && !isChosen && !isSuperseded && (
                <button
                  className="ops-button ops-button--ghost"
                  style={{ marginTop: 4, fontSize: 12.5, width: "100%" }}
                  disabled={busy !== null}
                  onClick={async () => {
                    if (!confirm(`Mark the "${tierLabel}" tier as the homeowner's pick?`)) return;
                    setBusy(child.id);
                    try {
                      await postProviderAction("decide_quote_bundle", {
                        workspaceId,
                        parentId: parent.id,
                        chosenChildId: child.id,
                      });
                      await onPicked();
                    } catch (e) {
                      alert(e instanceof Error ? e.message : "Couldn't accept the tier.");
                    } finally {
                      setBusy(null);
                    }
                  }}
                >
                  {busy === child.id ? "Saving..." : "Mark this tier approved"}
                </button>
              )}

              {child.publicShareUrl && (
                <a
                  href={child.publicShareUrl}
                  target="_blank"
                  rel="noopener"
                  style={{
                    fontSize: 11.5, fontWeight: 600,
                    color: "var(--text-soft)",
                    textDecoration: "none",
                    marginTop: "auto",
                    paddingTop: 6,
                  }}
                >
                  Public link →
                </a>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Wave Z.3 — Negotiation history timeline ─────────────────────
//
// Walks the parent_quote_id chain in both directions (up to root,
// down through children) so the operator sees the whole back-and-
// forth. Phase 73b's data model: each counter / re-quote creates a
// new row pointing at its parent; bundle parents and children share
// the same FK column but are excluded from this surface (children
// of a bundle are NOT a counter chain — they're alternate tiers).
//
// Display: vertical timeline with one card per version. The current
// version gets a "Current" salmon pill; superseded versions render
// muted. Status flips show the actor (homeowner / provider / Chez)
// and the dollar shift if the total changed.

interface NegotiationTimelineProps {
  selectedQuote: Quote;
  allQuotes: readonly Quote[];
}

interface ChainNode {
  quote: Quote;
  isRoot: boolean;
  isCurrent: boolean;
}

function buildVersionChain(selectedQuote: Quote, allQuotes: readonly Quote[]): ChainNode[] {
  // Index by id for O(1) lookups. Skip bundle children — they share
  // the same parent_quote_id column but are alternate tiers, not
  // versions. The bundle parent has bundleMeta != null; children
  // have parentQuoteId set to the bundle parent which has bundleMeta.
  const byId = new Map<string, Quote>();
  for (const q of allQuotes) byId.set(q.id, q);

  // Walk UP: collect ancestors (including self).
  const lineage: Quote[] = [];
  let cursor: Quote | undefined = selectedQuote;
  const seen = new Set<string>();
  while (cursor && !seen.has(cursor.id)) {
    seen.add(cursor.id);
    lineage.unshift(cursor); // ancestors come first
    if (!cursor.parentQuoteId) break;
    const parent = byId.get(cursor.parentQuoteId);
    if (!parent) break;
    // If the parent has bundleMeta, this is a bundle child. Stop walking
    // up; bundle parents are not part of the negotiation chain.
    if (parent.bundleMeta) break;
    cursor = parent;
  }

  // Walk DOWN from each lineage member's children. Children of a
  // counter chain are themselves counter rows; bundle parents stop
  // the walk above so we do not accidentally descend into tier rows.
  const root = lineage[0];
  if (!root) return [];

  const result: Quote[] = [];
  const visited = new Set<string>();
  function walk(node: Quote) {
    if (visited.has(node.id)) return;
    visited.add(node.id);
    result.push(node);
    const kids = allQuotes.filter((q) => q.parentQuoteId === node.id);
    for (const k of kids) walk(k);
  }
  walk(root);

  // Sort by updatedAt ascending so older versions appear at the top.
  result.sort((a, b) => {
    const av = new Date(a.updatedAt).getTime();
    const bv = new Date(b.updatedAt).getTime();
    return av - bv;
  });

  return result.map((q) => ({
    quote: q,
    isRoot: q.id === root.id,
    isCurrent: q.id === selectedQuote.id,
  }));
}

function NegotiationTimeline({ selectedQuote, allQuotes }: NegotiationTimelineProps) {
  const chain = useMemo(
    () => buildVersionChain(selectedQuote, allQuotes),
    [selectedQuote, allQuotes],
  );

  // Single-version chain isn't a "negotiation". Hide.
  if (chain.length < 2) return null;

  return (
    <div style={{ marginTop: 28, paddingTop: 20, borderTop: "1px solid var(--neutral-200)" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 14 }}>
        <Icon name="history" size={14} stroke={1.9} color="var(--text-muted)" />
        <div className="ops-section-label" style={{ marginBottom: 0 }}>
          Negotiation history
        </div>
        <div style={{ fontSize: 11, color: "var(--text-soft)", marginLeft: 4 }}>
          {chain.length} version{chain.length === 1 ? "" : "s"}
        </div>
      </div>

      <div style={{ position: "relative", paddingLeft: 24 }}>
        {/* Vertical connector line */}
        <div style={{
          position: "absolute",
          left: 7,
          top: 8,
          bottom: 8,
          width: 1.5,
          background: "var(--neutral-200)",
        }} />

        {chain.map((node, i) => {
          const prev = i > 0 ? chain[i - 1] : null;
          return (
            <TimelineRow
              key={node.quote.id}
              node={node}
              previousTotal={prev ? prev.quote.total : null}
              isLast={i === chain.length - 1}
            />
          );
        })}
      </div>
    </div>
  );
}

function TimelineRow({
  node,
  previousTotal,
  isLast,
}: {
  node: ChainNode;
  previousTotal: number | null;
  isLast: boolean;
}) {
  const { quote, isRoot, isCurrent } = node;
  const status = quote.status;
  const tone: PillTone = STATUS_TONE[status] ?? "neutral";

  // Actor + label inferred from status. The schema doesn't carry an
  // explicit "who acted last" field, so this is a best-effort read.
  let actor = "Provider";
  let actionLabel = "Drafted";
  if (status === "countered_by_homeowner" || quote.homeownerRevisedAt) {
    actor = "Homeowner";
    actionLabel = "Countered";
  } else if (status === "approved" && quote.signedAt) {
    // Wave M4 — distinguish a kitchen-table close (signature_path
    // present) from a homeowner-typed-name approval. Witness
    // signatures get their own label so audit trail reads cleanly.
    actor = "Homeowner";
    const witnessSuffix = quote.signerRole === "witness" ? " · witnessed" : "";
    const signatureSuffix = quote.signaturePath ? " · signed in person" : "";
    actionLabel = `Approved${quote.signedName ? ` (${quote.signedName})` : ""}${signatureSuffix}${witnessSuffix}`;
  } else if (status === "declined") {
    actionLabel = "Declined";
  } else if (status === "sent") {
    actionLabel = isRoot ? "Sent" : "Re-quoted";
  } else if (status === "viewed") {
    actionLabel = "Sent (viewed)";
  } else if (status === "superseded") {
    actionLabel = "Replaced by next version";
  } else if (status === "draft") {
    actionLabel = isRoot ? "Drafted" : "Re-quoted draft";
  } else if (status === "withdrawn") {
    actionLabel = "Withdrawn";
  }

  // Dollar shift relative to the previous version.
  let shiftLabel: string | null = null;
  let shiftTone: "down" | "up" | "flat" | null = null;
  if (previousTotal != null && quote.total != null && previousTotal !== quote.total) {
    const delta = quote.total - previousTotal;
    const absStr = formatCurrency(Math.abs(delta));
    if (delta < 0) {
      shiftLabel = `↓ ${absStr}`;
      shiftTone = "down";
    } else {
      shiftLabel = `↑ ${absStr}`;
      shiftTone = "up";
    }
  } else if (previousTotal === quote.total) {
    shiftTone = "flat";
  }

  // Date stamp.
  const dateStr = (() => {
    try {
      const d = new Date(quote.updatedAt);
      return d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
    } catch (_) {
      return "";
    }
  })();

  return (
    <div style={{
      position: "relative",
      paddingBottom: isLast ? 0 : 18,
      opacity: status === "superseded" ? 0.65 : 1,
    }}>
      {/* Dot marker */}
      <div style={{
        position: "absolute",
        left: -23,
        top: 4,
        width: 16,
        height: 16,
        borderRadius: 999,
        background: isCurrent ? "var(--salmon)" : "#fff",
        border: isCurrent ? "none" : "2px solid var(--neutral-300, #D8DADF)",
        boxShadow: isCurrent ? "0 0 0 3px rgba(105, 56, 239, 0.18)" : "none",
      }} />

      <div style={{
        background: isCurrent ? "var(--salmon-50, #F4F0FE)" : "#fff",
        border: `1px solid ${isCurrent ? "rgba(105, 56, 239, 0.35)" : "var(--neutral-200)"}`,
        borderRadius: 10,
        padding: "10px 14px",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4, flexWrap: "wrap" }}>
          <span style={{ fontSize: 11.5, fontWeight: 600, color: "var(--text)" }}>
            {actor}
          </span>
          <span style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
            {actionLabel}
          </span>
          {isCurrent && <Pill tone="salmon">Current</Pill>}
          {!isCurrent && status === "superseded" && <Pill tone="neutral">Superseded</Pill>}
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 2, flexWrap: "wrap" }}>
          <Pill tone={tone}>{quote.statusLabel}</Pill>
          <span style={{
            fontFamily: "var(--serif)",
            fontSize: 14,
            fontWeight: 600,
            color: "var(--text)",
            fontVariantNumeric: "tabular-nums",
          }}>
            {formatCurrency(quote.total)}
          </span>
          {shiftLabel && (
            <span style={{
              fontSize: 11,
              fontWeight: 600,
              color: shiftTone === "down" ? "#0A0A0A" : "#0A0A0A",
              fontVariantNumeric: "tabular-nums",
            }}>
              {shiftLabel}
            </span>
          )}
        </div>

        <div style={{ fontSize: 11, color: "var(--text-soft)" }}>
          {dateStr} · {formatRelativeTime(quote.updatedAt)}
        </div>
      </div>
    </div>
  );
}
