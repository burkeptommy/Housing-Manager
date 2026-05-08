import { useEffect, useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { postProviderAction } from "../lib/api";
import type { Workspace } from "../lib/types";

/**
 * Wave P (W1.4): Workspace branding + service-area settings.
 *
 * Lets owners/admins edit the columns find-network-handymen reads
 * (service_state, service_city, service_zip_codes, categories,
 * display_blurb, headshot_url, license_number) plus the identity
 * fields (company_name, primary_email, primary_phone, website) that
 * appear on every quote, invite email, and homeowner-facing card.
 *
 * Saves via the existing `update_workspace_directory` action — we
 * extended the function in this same wave to accept the identity
 * fields too, so one call writes all changed columns at once.
 *
 * Save button is disabled until the form is dirty so unchanged
 * submits never round-trip.
 */

const CATEGORY_OPTIONS: { id: string; label: string }[] = [
  // Per Tom's rebrand mandate: "handyman" stays out of user-facing copy.
  // The DB id remains `handyman` (so existing rows + the find-network
  // edge function still match), but the visible label uses the
  // trade-specific descriptor "General repair".
  { id: "handyman", label: "General repair" },
  { id: "hvac", label: "HVAC" },
  { id: "plumbing", label: "Plumbing" },
  { id: "electrical", label: "Electrical" },
  { id: "landscaping", label: "Landscaping" },
  { id: "painting", label: "Painting" },
  { id: "roofing", label: "Roofing" },
  { id: "pest_control", label: "Pest control" },
  { id: "cleaning", label: "Cleaning" },
  { id: "appliance", label: "Appliance repair" },
];

interface FormState {
  companyName: string;
  primaryEmail: string;
  primaryPhone: string;
  website: string;
  headshotUrl: string;
  serviceCity: string;
  serviceState: string;
  serviceZipCodesText: string;
  categories: string[];
  licenseNumber: string;
  displayBlurb: string;
  isListedInDirectory: boolean;
}

function buildInitial(workspace: Workspace | undefined): FormState {
  if (!workspace) {
    return {
      companyName: "",
      primaryEmail: "",
      primaryPhone: "",
      website: "",
      headshotUrl: "",
      serviceCity: "",
      serviceState: "",
      serviceZipCodesText: "",
      categories: [],
      licenseNumber: "",
      displayBlurb: "",
      isListedInDirectory: false,
    };
  }
  const zips = Array.isArray(workspace.serviceZipCodes) ? workspace.serviceZipCodes : [];
  const cats = Array.isArray(workspace.categories) ? workspace.categories : [];
  return {
    companyName: workspace.companyName ?? "",
    primaryEmail: workspace.primaryEmail ?? "",
    primaryPhone: workspace.primaryPhone ?? "",
    website: workspace.website ?? "",
    headshotUrl: workspace.headshotUrl ?? "",
    serviceCity: workspace.serviceCity ?? "",
    serviceState: workspace.serviceState ?? "",
    serviceZipCodesText: zips.join(", "),
    categories: cats,
    licenseNumber: workspace.licenseNumber ?? "",
    displayBlurb: workspace.displayBlurb ?? "",
    isListedInDirectory: Boolean(workspace.isListedInDirectory),
  };
}

export default function SettingsScreen() {
  const { dashboard, refresh } = useWorkspace();
  const [form, setForm] = useState<FormState>(() => buildInitial(dashboard?.workspace));
  const [initial, setInitial] = useState<FormState>(form);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<number | null>(null);

  // Re-seed when the dashboard reloads so the form picks up the latest
  // server state after a refresh elsewhere in the app.
  useEffect(() => {
    if (!dashboard) return;
    const next = buildInitial(dashboard.workspace);
    setForm(next);
    setInitial(next);
  }, [dashboard?.workspace.id]);

  const dirty = useMemo(() => JSON.stringify(form) !== JSON.stringify(initial), [form, initial]);
  // Owner/admin gate. Server returns `canManageWorkspace` (defined in
  // rolePermissions). `canBootstrapWorkspace` is a legacy alias kept on
  // the Permissions type — fall through to it if a future build returns
  // it instead.
  const canEdit = Boolean(
    dashboard?.permissions.canManageWorkspace ?? dashboard?.permissions.canBootstrapWorkspace,
  );

  if (!dashboard) return null;

  if (!canEdit) {
    return (
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="lock" size={16} stroke={2} />
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: "var(--text)" }}>
              Settings are owner and admin only
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 4 }}>
              Ask the workspace owner to update branding or service area.
            </div>
          </div>
        </div>
      </Card>
    );
  }

  function update<K extends keyof FormState>(key: K, value: FormState[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function toggleCategory(id: string) {
    setForm((prev) => ({
      ...prev,
      categories: prev.categories.includes(id)
        ? prev.categories.filter((c) => c !== id)
        : [...prev.categories, id],
    }));
  }

  function validate(): string | null {
    if (!form.companyName.trim()) return "Company name is required.";
    if (form.primaryEmail.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.primaryEmail.trim())) {
      return "Primary email is not a valid address.";
    }
    if (form.serviceState.trim() && !/^[A-Za-z]{2}$/.test(form.serviceState.trim())) {
      return "State should be a 2-letter code (NY, CT, NJ).";
    }
    if (form.displayBlurb.length > 280) {
      return "Display blurb is capped at 280 characters.";
    }
    return null;
  }

  async function save() {
    const reason = validate();
    if (reason) {
      setError(reason);
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      const zips = form.serviceZipCodesText
        .split(/[,;\s]+/)
        .map((z) => z.trim())
        .filter((z) => /^\d{5}$/.test(z));
      await postProviderAction("update_workspace_directory", {
        workspaceId: dashboard!.workspace.id,
        companyName: form.companyName.trim(),
        primaryEmail: form.primaryEmail.trim(),
        primaryPhone: form.primaryPhone.trim(),
        website: form.website.trim(),
        headshotUrl: form.headshotUrl.trim(),
        serviceCity: form.serviceCity.trim(),
        serviceState: form.serviceState.trim(),
        serviceZipCodes: Array.from(new Set(zips)),
        categories: form.categories,
        licenseNumber: form.licenseNumber.trim(),
        displayBlurb: form.displayBlurb.trim(),
        isListedInDirectory: form.isListedInDirectory,
      });
      await refresh();
      setSavedAt(Date.now());
      setInitial(form);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't save settings.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16, maxWidth: 880 }}>
      {/* Header card */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="gear" size={20} stroke={1.9} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: "var(--serif)", fontSize: 20, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              Workspace settings
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginTop: 4 }}>
              These details show up on every quote, invite email, and homeowner-facing card.
            </div>
          </div>
          {form.isListedInDirectory ? (
            <Pill tone="success" withDot>Listed in directory</Pill>
          ) : (
            <Pill tone="indigo">Private</Pill>
          )}
        </div>
      </Card>

      {/* Identity */}
      <Card padding="default">
        <div className="ops-section-label" style={{ marginBottom: 4 }}>Identity</div>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 16 }}>
          Company name, contact info, and your public website.
        </div>
        <Field label="Company name" required>
          <input
            type="text"
            value={form.companyName}
            onChange={(e) => update("companyName", e.target.value)}
            style={inputStyle}
            disabled={submitting}
            placeholder="Acme Home Services"
          />
        </Field>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 12 }}>
          <Field label="Primary email">
            <input
              type="email"
              value={form.primaryEmail}
              onChange={(e) => update("primaryEmail", e.target.value)}
              style={inputStyle}
              disabled={submitting}
              placeholder="hello@example.com"
            />
          </Field>
          <Field label="Primary phone">
            <input
              type="tel"
              value={form.primaryPhone}
              onChange={(e) => update("primaryPhone", e.target.value)}
              style={inputStyle}
              disabled={submitting}
              placeholder="(555) 555-1234"
            />
          </Field>
        </div>
        <div style={{ marginTop: 12 }}>
          <Field label="Website">
            <input
              type="url"
              value={form.website}
              onChange={(e) => update("website", e.target.value)}
              style={inputStyle}
              disabled={submitting}
              placeholder="https://yourcompany.com"
            />
          </Field>
        </div>
        <div style={{ marginTop: 12 }}>
          <Field label="Logo URL">
            <input
              type="url"
              value={form.headshotUrl}
              onChange={(e) => update("headshotUrl", e.target.value)}
              style={inputStyle}
              disabled={submitting}
              placeholder="https://yourcompany.com/logo.png"
            />
          </Field>
        </div>
      </Card>

      {/* Service area */}
      <Card padding="default">
        <div className="ops-section-label" style={{ marginBottom: 4 }}>Service area</div>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 16 }}>
          Where you work and what you handle. Homeowners filter by these when they search.
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 12 }}>
          <Field label="Primary city">
            <input
              type="text"
              value={form.serviceCity}
              onChange={(e) => update("serviceCity", e.target.value)}
              style={inputStyle}
              disabled={submitting}
              placeholder="Mount Kisco"
            />
          </Field>
          <Field label="State">
            <input
              type="text"
              value={form.serviceState}
              onChange={(e) => update("serviceState", e.target.value.toUpperCase())}
              style={inputStyle}
              disabled={submitting}
              maxLength={2}
              placeholder="NY"
            />
          </Field>
        </div>
        <div style={{ marginTop: 12 }}>
          <Field label="ZIP codes">
            <textarea
              value={form.serviceZipCodesText}
              onChange={(e) => update("serviceZipCodesText", e.target.value)}
              style={{ ...inputStyle, minHeight: 60, resize: "vertical" }}
              disabled={submitting}
              placeholder="10549, 10510, 10570 (comma-separated)"
            />
          </Field>
          <div style={{ fontSize: 11.5, color: "var(--text-soft)", marginTop: 4 }}>
            Five-digit ZIPs only. Up to 50 will save.
          </div>
        </div>
        <div style={{ marginTop: 16 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 8 }}>
            Categories
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {CATEGORY_OPTIONS.map((c) => {
              const on = form.categories.includes(c.id);
              return (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => toggleCategory(c.id)}
                  disabled={submitting}
                  style={{
                    padding: "6px 12px",
                    borderRadius: 999,
                    border: on ? "1px solid var(--salmon)" : "1px solid var(--neutral-200)",
                    background: on ? "var(--salmon-50)" : "#fff",
                    color: on ? "var(--salmon-dark)" : "var(--text-muted)",
                    fontSize: 12,
                    fontWeight: on ? 600 : 500,
                    cursor: submitting ? "not-allowed" : "pointer",
                  }}
                >
                  {c.label}
                </button>
              );
            })}
          </div>
        </div>
      </Card>

      {/* Compliance */}
      <Card padding="default">
        <div className="ops-section-label" style={{ marginBottom: 4 }}>Compliance and bio</div>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 16 }}>
          License number stays private. The bio shows on your homeowner-facing card.
        </div>
        <Field label="License number">
          <input
            type="text"
            value={form.licenseNumber}
            onChange={(e) => update("licenseNumber", e.target.value)}
            style={inputStyle}
            disabled={submitting}
            placeholder="WC-12345-H22"
          />
        </Field>
        <div style={{ marginTop: 12 }}>
          <Field label="Bio">
            <textarea
              value={form.displayBlurb}
              onChange={(e) => update("displayBlurb", e.target.value.slice(0, 280))}
              style={{ ...inputStyle, minHeight: 90, resize: "vertical" }}
              disabled={submitting}
              placeholder="A short pitch homeowners read when they find you."
            />
          </Field>
          <div style={{ fontSize: 11.5, color: "var(--text-soft)", marginTop: 4 }}>
            {form.displayBlurb.length} of 280 characters
          </div>
        </div>
        <div style={{ marginTop: 16, display: "flex", alignItems: "center", gap: 12, padding: 12, borderRadius: 10, background: "var(--indigo-50)" }}>
          <input
            id="setting-listed"
            type="checkbox"
            checked={form.isListedInDirectory}
            onChange={(e) => update("isListedInDirectory", e.target.checked)}
            disabled={submitting}
            style={{ width: 16, height: 16, cursor: "pointer", flex: "none" }}
          />
          <label htmlFor="setting-listed" style={{ fontSize: 13, color: "var(--text)", cursor: "pointer", flex: 1 }}>
            <div style={{ fontWeight: 600, marginBottom: 2 }}>List us in the homeowner directory</div>
            <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
              When on, homeowners searching for a pro in your area will see your card.
            </div>
          </label>
        </div>
      </Card>

      {/* Save bar */}
      <div style={{
        display: "flex", alignItems: "center", gap: 12,
        padding: "16px 20px", borderRadius: 16,
        background: "#fff", border: "1px solid var(--neutral-200)",
        position: "sticky", bottom: 16, zIndex: 5,
        boxShadow: "0 6px 22px rgba(42, 34, 82, 0.08)",
      }}>
        <div style={{ flex: 1, fontSize: 12.5, color: "var(--text-muted)" }}>
          {error ? (
            <span style={{ color: "var(--salmon-dark)", fontWeight: 600 }}>{error}</span>
          ) : savedAt ? (
            <span style={{ color: "var(--success)", fontWeight: 600 }}>Saved.</span>
          ) : dirty ? (
            "You have unsaved changes."
          ) : (
            "Everything is up to date."
          )}
        </div>
        <button
          className="ops-button ops-button--ghost"
          onClick={() => {
            setForm(initial);
            setError(null);
          }}
          disabled={submitting || !dirty}
        >
          Reset
        </button>
        <button
          className="ops-button ops-button--salmon"
          onClick={save}
          disabled={submitting || !dirty}
        >
          {submitting ? "Saving…" : "Save changes"}
        </button>
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
