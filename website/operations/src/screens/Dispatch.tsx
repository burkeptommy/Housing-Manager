import { useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { CREW_DEMO, UNASSIGNED_DEMO, VISITS_DEMO } from "../lib/fixtures";

export default function DispatchScreen() {
  const [selectedJobId, setSelectedJobId] = useState<string | null>("u2");
  const [filterChip, setFilterChip] = useState<"all" | "priority" | "bundles">("all");
  const selected = UNASSIGNED_DEMO.find((u) => u.id === selectedJobId) ?? null;

  const filteredQueue = UNASSIGNED_DEMO.filter((u) => {
    if (filterChip === "priority") return u.priority === "high";
    if (filterChip === "bundles") return u.bundle;
    return true;
  });

  return (
    <div className="ops-grid-dispatch">
      {/* Unassigned column */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
          <div className="ops-section-label">Unassigned · {filteredQueue.length}</div>
        </div>
        <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
          {(["all", "priority", "bundles"] as const).map((c) => (
            <button
              key={c}
              className="ops-button ops-button--ghost"
              style={{
                fontSize: 11,
                padding: "4px 10px",
                background: filterChip === c ? "var(--neutral-200)" : "#fff",
              }}
              onClick={() => setFilterChip(c)}
            >
              {c === "all" ? "All" : c === "priority" ? "Priority" : "Bundles"}
            </button>
          ))}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {filteredQueue.map((job) => {
            const isSel = selectedJobId === job.id;
            return (
              <button
                key={job.id}
                onClick={() => setSelectedJobId(job.id)}
                className="ops-card is-padded-tight is-hoverable"
                style={{
                  textAlign: "left",
                  background: isSel ? "var(--salmon-50)" : "#fff",
                  borderLeft: isSel ? "3px solid var(--salmon)" : "1px solid var(--neutral-200)",
                  cursor: "pointer",
                }}
              >
                <div style={{ display: "flex", gap: 6, marginBottom: 6, alignItems: "center" }}>
                  {job.priority === "high" && <Pill tone="critical">High</Pill>}
                  {job.bundle && <Pill tone="indigo">Bundle</Pill>}
                  <span style={{ marginLeft: "auto", fontSize: 11, color: "var(--text-soft)" }}>{job.age} ago</span>
                </div>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>{job.title}</div>
                <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
                  {job.home} · {job.requestedBy}
                </div>
              </button>
            );
          })}
        </div>
      </Card>

      {/* Today's lanes */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 14 }}>
          <div>
            <div className="ops-section-label">Today's board</div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, color: "var(--text)" }}>
              {new Date().toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" })}
            </div>
          </div>
          <div style={{ display: "flex", gap: 4, background: "var(--neutral-200)", padding: 3, borderRadius: 9 }}>
            {(["Day", "Lanes", "Map"] as const).map((label) => (
              <button
                key={label}
                className="ops-page-toolbar__seg-button"
                style={{
                  background: label === "Lanes" ? "var(--indigo)" : "transparent",
                  color: label === "Lanes" ? "#fff" : "var(--text-muted)",
                }}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Time gridline header */}
        <div style={{ display: "grid", gridTemplateColumns: "90px repeat(10, 1fr)", borderBottom: "1px solid var(--neutral-200)", paddingBottom: 4, marginBottom: 8 }}>
          <span />
          {["8a", "9", "10", "11", "12p", "1", "2", "3", "4", "5"].map((h) => (
            <span key={h} style={{ fontSize: 10, fontWeight: 600, color: "var(--text-soft)", letterSpacing: "0.06em" }}>{h}</span>
          ))}
        </div>

        {/* Lanes */}
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {CREW_DEMO.filter((c) => !c.desk).map((tech) => (
            <div key={tech.id} style={{ display: "grid", gridTemplateColumns: "90px 1fr", gap: 12, alignItems: "center" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <Avatar initials={tech.avatar} color={tech.color} size={28} />
                <span style={{ fontSize: 12, fontWeight: 600 }}>{tech.name.split(" ")[0]}</span>
              </div>
              <div style={{ position: "relative", height: 36, background: "var(--neutral-200)", borderRadius: 6 }}>
                {VISITS_DEMO.filter((v) => v.tech === tech.id).map((v) => {
                  const start = parseTime(v.time);
                  const left = ((start - 8) / 9) * 100;
                  const width = (v.duration / 60 / 9) * 100;
                  return (
                    <div
                      key={v.id}
                      style={{
                        position: "absolute",
                        left: `${left}%`,
                        width: `${width}%`,
                        top: 2,
                        bottom: 2,
                        background: v.priority === "high" ? "var(--salmon)" : "var(--indigo)",
                        color: "#fff",
                        borderRadius: 6,
                        padding: "4px 8px",
                        fontSize: 10.5,
                        fontWeight: 600,
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                      title={`${v.title} · ${v.home}`}
                    >
                      {v.title}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </Card>

      {/* Assign panel */}
      <Card padding="default">
        {selected ? (
          <>
            <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
              {selected.priority === "high" && <Pill tone="critical">High</Pill>}
              {selected.bundle && <Pill tone="indigo">Bundle</Pill>}
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 19, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>
              {selected.title}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 4 }}>
              {selected.home} · {selected.city}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 16 }}>
              Requested by {selected.requestedBy}
            </div>

            <div className="ops-section-label" style={{ marginBottom: 10 }}>Pick a technician</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 16 }}>
              {CREW_DEMO.filter((c) => !c.desk).map((tech, idx) => (
                <div
                  key={tech.id}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 10,
                    padding: 10,
                    border: idx === 0 ? "1px solid var(--salmon)" : "1px solid var(--neutral-200)",
                    background: idx === 0 ? "var(--salmon-50)" : "#fff",
                    borderRadius: 10,
                    cursor: "pointer",
                  }}
                >
                  <Avatar initials={tech.avatar} color={tech.color} size={32} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{tech.name}</div>
                    <div style={{ fontSize: 11, color: "var(--text-soft)" }}>
                      {idx === 0 ? "4 today · 9 open · already in Brookline" : "Available"}
                    </div>
                  </div>
                  {idx === 0 ? <Pill tone="success" withDot>Best fit</Pill> : <Pill tone="neutral">Available</Pill>}
                </div>
              ))}
            </div>

            <div className="ops-section-label" style={{ marginBottom: 8 }}>When</div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 16 }}>
              <input type="date" defaultValue="2026-04-28" style={selectInputStyle} />
              <select defaultValue="9-11" style={selectInputStyle}>
                <option value="9-11">9 AM – 11 AM</option>
                <option value="11-1">11 AM – 1 PM</option>
                <option value="1-3">1 PM – 3 PM</option>
                <option value="3-5">3 PM – 5 PM</option>
              </select>
            </div>

            <div className="ops-section-label" style={{ marginBottom: 8 }}>Notes</div>
            <textarea
              defaultValue={`Spring punch list for ${selected.requestedBy} — ${selected.home}. Bundle includes 5 small jobs.`}
              style={{
                ...selectInputStyle,
                width: "100%",
                minHeight: 80,
                padding: 10,
                resize: "vertical",
              }}
            />

            <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
              <button className="ops-button ops-button--ghost" style={{ flex: 1 }}>Save draft</button>
              <button className="ops-button ops-button--salmon" style={{ flex: 1 }}>Assign &amp; notify Mara</button>
            </div>
          </>
        ) : (
          <div style={{ fontSize: 13, color: "var(--text-muted)", textAlign: "center", padding: 24 }}>
            Pick a job from the unassigned queue to assign it.
          </div>
        )}
      </Card>
    </div>
  );
}

const selectInputStyle: React.CSSProperties = {
  height: 36,
  padding: "0 10px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 10,
  background: "#fff",
  fontSize: 13,
  color: "var(--text)",
  fontFamily: "var(--sans)",
};

function parseTime(time: string): number {
  // "8:30 AM" → 8.5 (24-hour decimal)
  const [hm, ampm] = time.split(" ");
  const [h, m] = hm.split(":").map(Number);
  let hour = h % 12;
  if (ampm === "PM") hour += 12;
  return hour + m / 60;
}
