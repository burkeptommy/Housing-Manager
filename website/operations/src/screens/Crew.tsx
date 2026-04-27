import { useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { CREW_DEMO } from "../lib/fixtures";

const PERMISSIONS = [
  { id: "dispatch",  label: "Dispatch board", sub: "See today's lanes + drag visits between techs" },
  { id: "quotes",    label: "Quotes",         sub: "Build, edit, send quotes to homeowners" },
  { id: "crew",      label: "Crew admin",     sub: "Invite, deactivate, change roles" },
  { id: "messages",  label: "Homeowner messages", sub: "Reply to any thread on behalf of the company" },
];

const ACTIVITY = [
  { title: "Mara accepted the Brookline assignment", time: "12 min ago" },
  { title: "Diego marked the Newton sillcock complete", time: "1 hr ago" },
  { title: "Lou clocked in for radon pickup", time: "2 hr ago" },
];

export default function CrewScreen() {
  const [selectedId, setSelectedId] = useState<string>("MC");
  const [perms, setPerms] = useState<Record<string, boolean>>({
    dispatch: true, quotes: true, crew: false, messages: true,
  });
  const member = CREW_DEMO.find((c) => c.id === selectedId)!;

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1.1fr 0.9fr", gap: 24 }}>
      {/* Roster card */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 16 }}>
          <div>
            <div className="ops-section-label">Roster</div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)" }}>{CREW_DEMO.length} teammates · 4 in the field</div>
          </div>
          <button className="ops-button ops-button--salmon">+ Invite teammate</button>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
          {CREW_DEMO.map((c) => {
            const isSel = c.id === selectedId;
            return (
              <button
                key={c.id}
                onClick={() => setSelectedId(c.id)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  padding: "10px 12px",
                  border: "1px solid var(--neutral-200)",
                  borderRadius: 10,
                  background: isSel ? "var(--salmon-50)" : "#fff",
                  cursor: "pointer",
                  textAlign: "left",
                }}
              >
                <Avatar initials={c.avatar} color={c.color} size={36} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{c.name}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{c.title}</div>
                </div>
                <Pill tone={c.desk ? "indigo" : "neutral"}>{c.desk ? "Desk" : "Field"}</Pill>
                <div style={{ width: 60 }}>
                  <div style={{ height: 5, background: "var(--neutral-200)", borderRadius: 3, overflow: "hidden" }}>
                    <div style={{ width: "65%", height: "100%", background: "var(--indigo)" }} />
                  </div>
                </div>
                <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
              </button>
            );
          })}
        </div>
      </Card>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {/* Profile card */}
        <Card padding="default" style={{ padding: 0, overflow: "hidden" }}>
          <div style={{ background: "linear-gradient(135deg, var(--indigo), var(--indigo-600))", padding: "20px 24px", display: "flex", alignItems: "center", gap: 12 }}>
            <Avatar initials={member.avatar} color={member.color} size={48} />
            <div style={{ flex: 1, color: "#fff" }}>
              <div style={{ fontFamily: "var(--serif)", fontSize: 20, fontWeight: 600 }}>{member.name}</div>
              <div style={{ fontSize: 12.5, color: "rgba(255,255,255,0.7)" }}>{member.title}</div>
            </div>
            <Pill tone="success" withDot>Active</Pill>
          </div>
          <div style={{ padding: 18, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
            <Detail icon="mail"      label="Email"  value={`${member.id.toLowerCase()}@chez.example`} />
            <Detail icon="phone"     label="Phone"  value="617-555-0123" />
            <Detail icon="briefcase" label="Role"   value={member.role} />
            <Detail icon="shield"    label="Status" value="On route today" />
          </div>
        </Card>

        {/* Permissions card */}
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 12 }}>Access &amp; permissions</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {PERMISSIONS.map((p) => (
              <label
                key={p.id}
                style={{
                  display: "flex",
                  gap: 10,
                  alignItems: "center",
                  padding: 12,
                  border: "1px solid var(--neutral-200)",
                  borderRadius: 10,
                  cursor: "pointer",
                }}
              >
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{p.label}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{p.sub}</div>
                </div>
                <input
                  type="checkbox"
                  checked={!!perms[p.id]}
                  onChange={() => setPerms((s) => ({ ...s, [p.id]: !s[p.id] }))}
                  style={{ width: 36, height: 22, accentColor: "var(--salmon)" }}
                />
              </label>
            ))}
          </div>
          <button className="ops-button ops-button--indigo" style={{ marginTop: 14 }}>Save access</button>
        </Card>

        {/* Activity card */}
        <Card padding="default">
          <div className="ops-section-label" style={{ marginBottom: 8 }}>Recent activity</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
            {ACTIVITY.map((a, i) => (
              <div key={i} className="ops-row" style={{ padding: "10px 0" }}>
                <span className="ops-pill__dot" style={{ background: "#4A7C59", width: 8, height: 8, borderRadius: "50%" }} />
                <div style={{ flex: 1, fontSize: 13, color: "var(--text)" }}>{a.title}</div>
                <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{a.time}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

function Detail({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <div style={{ display: "flex", gap: 8 }}>
      <div style={{ width: 30, height: 30, borderRadius: 8, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name={icon} size={14} stroke={1.9} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 11, color: "var(--text-soft)", letterSpacing: "0.04em", textTransform: "uppercase", fontWeight: 600 }}>{label}</div>
        <div style={{ fontSize: 13, color: "var(--text)" }}>{value}</div>
      </div>
    </div>
  );
}
