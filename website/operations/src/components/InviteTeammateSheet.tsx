import { useEffect, useState } from "react";
import { Icon } from "./chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { postProviderAction } from "../lib/api";

/**
 * Wave P (W1.5): Crew "+ Invite teammate" sheet.
 *
 * Wires the Crew screen's previously-orphaned button to the existing
 * `invite_team_member` Edge Function action. The function already
 * handles invite_token generation and surfaces an inviteUrl in the
 * response. We capture email, role, optional full name + phone +
 * title, then refresh the dashboard so the new "invited" row lands
 * in the roster on success.
 *
 * Opens via the `ops:open-invite-teammate` window event so the Crew
 * screen (or any caller) can trigger it without prop-drilling.
 */
export function InviteTeammateSheet() {
  const { dashboard, refresh } = useWorkspace();
  const [open, setOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<"technician" | "dispatcher" | "admin">("technician");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [title, setTitle] = useState("");

  function reset() {
    setEmail("");
    setRole("technician");
    setFullName("");
    setPhone("");
    setTitle("");
    setError(null);
    setSuccess(null);
  }

  useEffect(() => {
    function handler() {
      reset();
      setOpen(true);
    }
    window.addEventListener("ops:open-invite-teammate", handler);
    return () => window.removeEventListener("ops:open-invite-teammate", handler);
  }, []);

  // Escape key closes (a11y).
  useEffect(() => {
    if (!open) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && !submitting) setOpen(false);
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, submitting]);

  if (!open || !dashboard) return null;

  function validate(): string | null {
    const trimmed = email.trim().toLowerCase();
    if (!trimmed) return "Email is required.";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) return "Enter a valid email address.";
    const myEmail = (dashboard?.currentUser.email || "").toLowerCase();
    if (myEmail && trimmed === myEmail) return "You cannot invite yourself.";
    if (dashboard?.teamMembers.some((m) => (m.email || "").toLowerCase() === trimmed && m.status === "active")) {
      return "Someone with that email is already on the team.";
    }
    return null;
  }

  async function submit() {
    const reason = validate();
    if (reason) {
      setError(reason);
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      await postProviderAction("invite_team_member", {
        workspaceId: dashboard!.workspace.id,
        email: email.trim().toLowerCase(),
        role,
        fullName: fullName.trim() || undefined,
        phone: phone.trim() || undefined,
        title: title.trim() || undefined,
      });
      await refresh();
      setSuccess(`Invite sent to ${email.trim()}. They will get an email link to join your workspace.`);
      // Auto-close after a beat so the operator sees confirmation.
      setTimeout(() => {
        setOpen(false);
      }, 1600);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't send the invite. Try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 60,
        background: "rgba(15, 10, 40, 0.45)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && setOpen(false)}
      role="dialog"
      aria-modal="true"
      aria-labelledby="invite-teammate-title"
    >
      <div
        style={{
          background: "#fff", borderRadius: 18, width: "min(540px, 95vw)",
          maxHeight: "90vh", overflowY: "auto",
          boxShadow: "0 24px 60px rgba(15, 10, 40, 0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{
          padding: 24, borderBottom: "1px solid var(--neutral-200)",
          display: "flex", alignItems: "flex-start", justifyContent: "space-between",
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 6 }}>
              Invite teammate
            </div>
            <div id="invite-teammate-title" style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              Bring a teammate onto your workspace
            </div>
            <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 6, lineHeight: 1.5 }}>
              They will get an email with a link to join. You can dispatch visits to them as soon as they accept.
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
          <Field label="Email" required>
            <input
              type="email"
              placeholder="teammate@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={inputStyle}
              autoFocus
              disabled={submitting}
            />
          </Field>

          <Field label="Role" required>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as typeof role)}
              style={{ ...inputStyle, cursor: "pointer" }}
              disabled={submitting}
            >
              <option value="technician">Technician (runs visits in the field)</option>
              <option value="dispatcher">Dispatcher (schedules visits, no admin)</option>
              <option value="admin">Admin (full workspace access)</option>
            </select>
          </Field>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <Field label="Full name">
              <input
                type="text"
                placeholder="Maya Patel"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                style={inputStyle}
                disabled={submitting}
              />
            </Field>
            <Field label="Phone">
              <input
                type="tel"
                placeholder="(555) 555-1234"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                style={inputStyle}
                disabled={submitting}
              />
            </Field>
          </div>

          <Field label="Title (optional)">
            <input
              type="text"
              placeholder="Lead Technician"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              style={inputStyle}
              disabled={submitting}
            />
          </Field>

          {error && (
            <div role="alert" style={{
              padding: "10px 12px", borderRadius: 10,
              background: "#FEEAE6", color: "var(--salmon-dark)",
              fontSize: 12.5, lineHeight: 1.5,
            }}>
              {error}
            </div>
          )}
          {success && (
            <div role="status" style={{
              padding: "10px 12px", borderRadius: 10,
              background: "rgba(10, 10, 15, 0.12)", color: "var(--success)",
              fontSize: 12.5, lineHeight: 1.5,
            }}>
              {success}
            </div>
          )}
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
            disabled={submitting || !email.trim()}
          >
            {submitting ? "Sending invite…" : "Send invite"}
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
