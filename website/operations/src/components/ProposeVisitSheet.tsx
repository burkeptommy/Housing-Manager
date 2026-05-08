import { useEffect, useMemo, useState } from "react";
import { Icon } from "./chrome/Icon";
import { postProviderAction } from "../lib/api";

/**
 * Wave T: small modal that lets the contractor send 2-3 candidate
 * visit slots into a thread in one shot. Each slot has a date, start
 * time, end time, and an optional note. The homeowner-side iOS
 * renders the resulting metadata.kind=visit_proposed message as a
 * picker card with tap-to-accept. We don't go through the
 * propose_visit_time RPC per slot because that writes a single
 * proposed_visit_at on the request row; the slot card is chat-only
 * until the homeowner picks one and the existing accept_visit_time
 * path activates.
 */

interface Slot {
  key: string;
  date: string; // YYYY-MM-DD
  startTime: string; // HH:MM
  endTime: string; // HH:MM
  note: string;
}

interface ProposeVisitSheetProps {
  open: boolean;
  workspaceId: string;
  requestId: string;
  propertyName: string;
  onClose: () => void;
  onSent: () => void;
}

function nextWeekdayDate(daysAhead: number): string {
  const d = new Date();
  d.setDate(d.getDate() + daysAhead);
  return d.toISOString().slice(0, 10);
}

function defaultSlots(): Slot[] {
  return [
    { key: "1", date: nextWeekdayDate(1), startTime: "09:00", endTime: "11:00", note: "" },
    { key: "2", date: nextWeekdayDate(3), startTime: "13:00", endTime: "15:00", note: "" },
    { key: "3", date: nextWeekdayDate(5), startTime: "10:00", endTime: "12:00", note: "" },
  ];
}

export function ProposeVisitSheet({ open, workspaceId, requestId, propertyName, onClose, onSent }: ProposeVisitSheetProps) {
  const [slots, setSlots] = useState<Slot[]>(defaultSlots());
  const [intro, setIntro] = useState<string>("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset slots whenever the modal re-opens for a different request.
  useEffect(() => {
    if (open) {
      setSlots(defaultSlots());
      setIntro("");
      setError(null);
    }
  }, [open, requestId]);

  const validSlots = useMemo(
    () =>
      slots.filter((s) => Boolean(s.date) && Boolean(s.startTime)),
    [slots],
  );

  if (!open) return null;

  function updateSlot(key: string, patch: Partial<Slot>) {
    setSlots((prev) => prev.map((s) => (s.key === key ? { ...s, ...patch } : s)));
  }

  function removeSlot(key: string) {
    setSlots((prev) => (prev.length > 1 ? prev.filter((s) => s.key !== key) : prev));
  }

  function addSlot() {
    if (slots.length >= 5) return;
    const fallback = nextWeekdayDate(slots.length + 2);
    setSlots((prev) => [
      ...prev,
      { key: String(Date.now()), date: fallback, startTime: "09:00", endTime: "11:00", note: "" },
    ]);
  }

  async function handleSend() {
    if (validSlots.length === 0) {
      setError("Add at least one slot with a date and start time.");
      return;
    }
    setSending(true);
    setError(null);
    try {
      const payloadSlots = validSlots.map((s) => {
        const startISO = new Date(`${s.date}T${s.startTime}:00`).toISOString();
        const endISO = s.endTime
          ? new Date(`${s.date}T${s.endTime}:00`).toISOString()
          : null;
        return {
          start: startISO,
          end: endISO,
          note: s.note.trim() || null,
        };
      });
      await postProviderAction("propose_visit_slots", {
        workspaceId,
        requestId,
        slots: payloadSlots,
        body: intro.trim() || undefined,
      });
      onSent();
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't send. Try again.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(20, 16, 50, 0.45)",
        zIndex: 1000,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 20,
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "#fff",
          borderRadius: 16,
          width: "100%",
          maxWidth: 520,
          maxHeight: "90vh",
          overflow: "auto",
          padding: 24,
          boxShadow: "0 25px 60px -10px rgba(20, 16, 50, 0.45)",
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>Suggest visit times</div>
            <div style={{ fontSize: 12, color: "var(--text-soft)" }}>
              {propertyName ? `for ${propertyName}` : "Pick 2 to 3 candidate slots"}
            </div>
          </div>
          <button
            onClick={onClose}
            className="ops-button ops-button--ghost"
            style={{ minHeight: 32, padding: "6px 10px" }}
            aria-label="Close"
          >
            <Icon name="remove" size={14} />
          </button>
        </div>

        <textarea
          placeholder="Add a quick note. Optional."
          value={intro}
          onChange={(e) => setIntro(e.target.value)}
          style={{
            width: "100%",
            border: "1px solid var(--neutral-200)",
            borderRadius: 10,
            padding: 10,
            fontFamily: "var(--sans)",
            fontSize: 13,
            minHeight: 56,
            resize: "vertical",
            marginBottom: 14,
          }}
        />

        <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 14 }}>
          {slots.map((slot, idx) => (
            <div
              key={slot.key}
              style={{
                border: "1px solid var(--neutral-200)",
                borderRadius: 12,
                padding: 12,
                background: "#FAFBFC",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>
                  Option {idx + 1}
                </div>
                {slots.length > 1 && (
                  <button
                    onClick={() => removeSlot(slot.key)}
                    className="ops-button ops-button--ghost"
                    style={{ minHeight: 24, padding: "2px 6px", fontSize: 11 }}
                  >
                    Remove
                  </button>
                )}
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 8 }}>
                <label style={{ display: "flex", flexDirection: "column", gap: 4, fontSize: 11, color: "var(--text-soft)" }}>
                  Date
                  <input
                    type="date"
                    value={slot.date}
                    onChange={(e) => updateSlot(slot.key, { date: e.target.value })}
                    style={{ padding: 6, fontSize: 13, border: "1px solid var(--neutral-200)", borderRadius: 8 }}
                  />
                </label>
                <label style={{ display: "flex", flexDirection: "column", gap: 4, fontSize: 11, color: "var(--text-soft)" }}>
                  Start
                  <input
                    type="time"
                    value={slot.startTime}
                    onChange={(e) => updateSlot(slot.key, { startTime: e.target.value })}
                    style={{ padding: 6, fontSize: 13, border: "1px solid var(--neutral-200)", borderRadius: 8 }}
                  />
                </label>
                <label style={{ display: "flex", flexDirection: "column", gap: 4, fontSize: 11, color: "var(--text-soft)" }}>
                  End
                  <input
                    type="time"
                    value={slot.endTime}
                    onChange={(e) => updateSlot(slot.key, { endTime: e.target.value })}
                    style={{ padding: 6, fontSize: 13, border: "1px solid var(--neutral-200)", borderRadius: 8 }}
                  />
                </label>
              </div>
              <input
                type="text"
                placeholder="Optional note. Example: bring ladder."
                value={slot.note}
                onChange={(e) => updateSlot(slot.key, { note: e.target.value })}
                style={{
                  width: "100%",
                  padding: 6,
                  fontSize: 12,
                  border: "1px solid var(--neutral-200)",
                  borderRadius: 8,
                }}
              />
            </div>
          ))}
        </div>

        {slots.length < 5 && (
          <button
            onClick={addSlot}
            className="ops-button ops-button--ghost"
            style={{ marginBottom: 14, fontSize: 12 }}
          >
            <Icon name="plus" size={12} /> Add another slot
          </button>
        )}

        {error && (
          <div style={{ fontSize: 12, color: "var(--critical, #c0392b)", marginBottom: 10 }}>
            {error}
          </div>
        )}

        <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
          <button
            onClick={onClose}
            className="ops-button ops-button--ghost"
            disabled={sending}
          >
            Cancel
          </button>
          <button
            onClick={handleSend}
            className="ops-button ops-button--salmon"
            disabled={sending || validSlots.length === 0}
          >
            {sending ? "Sending..." : `Send ${validSlots.length} option${validSlots.length === 1 ? "" : "s"}`} <Icon name="send" size={13} />
          </button>
        </div>
      </div>
    </div>
  );
}
