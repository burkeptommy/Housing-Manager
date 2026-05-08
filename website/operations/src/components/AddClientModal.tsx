import { useEffect, useState } from "react";
import { Icon } from "./chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { postProviderAction } from "../lib/api";

/**
 * Lets the handyman add a client (homeowner + property + workspace
 * linkage) without waiting for the homeowner to install the app and
 * sign up. Creates a "managed" home that immediately appears in the
 * /homes list and that quotes / visits can be built against. The
 * homeowner can later claim the record by signing up with the email
 * we stored.
 *
 * Opens via a window CustomEvent so the Topbar (or any other caller)
 * can trigger it without prop-drilling through the layout shell.
 */
export function AddClientModal() {
  const { dashboard, refresh } = useWorkspace();
  const [open, setOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [street, setStreet] = useState("");
  const [city, setCity] = useState("");
  const [state, setState] = useState("");
  const [zip, setZip] = useState("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    function handler() {
      setOpen(true);
      setName("");
      setEmail("");
      setPhone("");
      setStreet("");
      setCity("");
      setState("");
      setZip("");
      setNotes("");
    }
    window.addEventListener("ops:open-add-client", handler);
    return () => window.removeEventListener("ops:open-add-client", handler);
  }, []);

  // Escape key closes modal (a11y).
  useEffect(() => {
    if (!open) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && !submitting) setOpen(false);
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, submitting]);

  if (!open || !dashboard) return null;

  async function submit() {
    if (!street.trim() || !name.trim()) {
      alert("Client name and street address are required.");
      return;
    }
    if (email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      alert("Email format looks off. Leave blank or fix it before saving.");
      return;
    }
    setSubmitting(true);
    try {
      await postProviderAction("add_client", {
        workspaceId: dashboard!.workspace.id,
        clientName: name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        street: street.trim(),
        city: city.trim() || undefined,
        state: state.trim() || undefined,
        zip: zip.trim() || undefined,
        notes: notes.trim() || undefined,
      });
      await refresh();
      setOpen(false);
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't add client.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 60,
        background: "rgba(42, 34, 82, 0.45)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && setOpen(false)}
    >
      <div
        style={{
          background: "#fff", borderRadius: 18, width: "min(560px, 95vw)",
          maxHeight: "90vh", overflowY: "auto",
          boxShadow: "0 24px 60px rgba(42, 34, 82, 0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{
          padding: 24, borderBottom: "1px solid var(--neutral-200)",
          display: "flex", alignItems: "flex-start", justifyContent: "space-between",
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 6 }}>
              Add client
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              Bring a homeowner onto your books
            </div>
            <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 6, lineHeight: 1.5 }}>
              They'll show up in Homes immediately. You can build quotes and schedule visits right away. When they sign up later they'll claim the record.
            </div>
          </div>
          <button
            onClick={() => !submitting && setOpen(false)}
            style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }}
            aria-label="Close"
          >
            <Icon name="remove" size={18} stroke={2} />
          </button>
        </div>

        <div style={{ padding: 24, display: "flex", flexDirection: "column", gap: 14 }}>
          <Field label="Client name" required>
            <input
              type="text"
              placeholder="Jane Doe"
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={inputStyle}
              autoFocus
            />
          </Field>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <Field label="Email">
              <input
                type="email"
                placeholder="jane@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="Phone">
              <input
                type="tel"
                placeholder="(555) 555-1234"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                style={inputStyle}
              />
            </Field>
          </div>

          <Field label="Street address" required>
            <input
              type="text"
              placeholder="236 Sarles Street"
              value={street}
              onChange={(e) => setStreet(e.target.value)}
              style={inputStyle}
            />
          </Field>

          <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr", gap: 12 }}>
            <Field label="City">
              <input
                type="text"
                placeholder="Mount Kisco"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="State">
              <input
                type="text"
                placeholder="NY"
                value={state}
                onChange={(e) => setState(e.target.value.toUpperCase())}
                style={inputStyle}
                maxLength={2}
              />
            </Field>
            <Field label="ZIP">
              <input
                type="text"
                placeholder="10549"
                value={zip}
                onChange={(e) => setZip(e.target.value)}
                style={inputStyle}
                maxLength={10}
              />
            </Field>
          </div>

          <Field label="Notes (internal)">
            <textarea
              placeholder="Anything to remember: gate code, dog, parking, referral source…"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              style={{ ...inputStyle, minHeight: 70, resize: "vertical" }}
            />
          </Field>
        </div>

        <div style={{
          padding: 18, borderTop: "1px solid var(--neutral-200)",
          display: "flex", gap: 8, justifyContent: "flex-end",
        }}>
          <button
            className="ops-button ops-button--ghost"
            onClick={() => !submitting && setOpen(false)}
            disabled={submitting}
          >
            Cancel
          </button>
          <button
            className="ops-button ops-button--salmon"
            onClick={submit}
            disabled={submitting}
          >
            {submitting ? "Adding…" : "Add client"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <span style={{
        fontSize: 11, fontWeight: 600, letterSpacing: "0.06em",
        textTransform: "uppercase", color: "var(--text-soft)",
      }}>
        {label}{required && <span style={{ color: "var(--salmon-dark)" }}> *</span>}
      </span>
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
