import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useWorkspace } from "../lib/workspace-context";
import { Icon } from "./chrome/Icon";

interface CommandResult {
  id: string;
  group: "Visits" | "Homes" | "Threads" | "Quotes" | "Navigate";
  label: string;
  sub?: string;
  to: string;
}

/**
 * Cmd+K command palette — global search + navigation.
 * Indexes the entire dashboard (visits, homes, threads, quotes) plus
 * static navigation entries. Filter is fuzzy substring on the label
 * + sub-line; up/down to move, Enter to select, Escape to close.
 */
export function CommandPalette() {
  const { dashboard } = useWorkspace();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement | null>(null);

  // Cmd+K global hotkey
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setOpen((v) => !v);
      } else if (e.key === "Escape" && open) {
        e.preventDefault();
        setOpen(false);
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  // Listen for Topbar search-focus events
  useEffect(() => {
    function onOpen() {
      setOpen(true);
    }
    window.addEventListener("ops:open-search", onOpen);
    return () => window.removeEventListener("ops:open-search", onOpen);
  }, []);

  useEffect(() => {
    if (open) {
      setQuery("");
      setActiveIndex(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [open]);

  const allResults = useMemo<CommandResult[]>(() => {
    if (!dashboard) return [];
    const results: CommandResult[] = [];

    dashboard.visits.forEach((v) => {
      results.push({
        id: `v-${v.requestId}`,
        group: "Visits",
        label: v.title,
        sub: `${v.property?.name ?? ""}${v.statusLabel ? ` · ${v.statusLabel}` : ""}`,
        to: `/visits/${v.requestId}`,
      });
    });
    dashboard.homes.forEach((h) => {
      results.push({
        id: `h-${h.propertyId}`,
        group: "Homes",
        label: h.name,
        sub: h.address,
        to: `/homes/${h.propertyId}`,
      });
    });
    dashboard.messages.forEach((m) => {
      results.push({
        id: `t-${m.requestId}`,
        group: "Threads",
        label: m.propertyName || m.title,
        sub: m.latestMessage,
        to: `/messages?request=${m.requestId}`,
      });
    });
    dashboard.quotes.forEach((q) => {
      results.push({
        id: `q-${q.id}`,
        group: "Quotes",
        label: q.audienceLabel,
        sub: `${q.title} · ${q.statusLabel}`,
        to: `/quotes?id=${q.id}`,
      });
    });
    [
      { id: "n-overview", group: "Navigate" as const, label: "Overview", to: "/" },
      { id: "n-visits", group: "Navigate" as const, label: "Visits", to: "/visits" },
      { id: "n-calendar", group: "Navigate" as const, label: "Calendar", to: "/calendar" },
      { id: "n-routes", group: "Navigate" as const, label: "Routes", to: "/routes" },
      { id: "n-homes", group: "Navigate" as const, label: "Homes", to: "/homes" },
      { id: "n-quotes", group: "Navigate" as const, label: "Quotes", to: "/quotes" },
      { id: "n-messages", group: "Navigate" as const, label: "Messages", to: "/messages" },
      { id: "n-crew", group: "Navigate" as const, label: "Crew", to: "/crew" },
    ].forEach((n) => results.push(n));

    return results;
  }, [dashboard]);

  const filtered = useMemo(() => {
    if (!query.trim()) {
      return allResults.slice(0, 12);
    }
    const q = query.trim().toLowerCase();
    return allResults
      .filter((r) => r.label.toLowerCase().includes(q) || (r.sub ?? "").toLowerCase().includes(q))
      .slice(0, 20);
  }, [allResults, query]);

  // Group filtered results
  const grouped = useMemo(() => {
    const map = new Map<string, CommandResult[]>();
    filtered.forEach((r) => {
      const arr = map.get(r.group) ?? [];
      arr.push(r);
      map.set(r.group, arr);
    });
    return Array.from(map.entries());
  }, [filtered]);

  function handleKey(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActiveIndex((i) => Math.min(i + 1, filtered.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActiveIndex((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      const target = filtered[activeIndex];
      if (target) {
        setOpen(false);
        navigate(target.to);
      }
    }
  }

  if (!open) return null;

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 60,
        background: "rgba(42,34,82,0.45)",
        display: "flex", alignItems: "flex-start", justifyContent: "center",
        paddingTop: 100,
      }}
      onClick={() => setOpen(false)}
    >
      <div
        style={{
          background: "#fff",
          borderRadius: 16,
          width: "min(640px, 92vw)",
          boxShadow: "0 24px 60px rgba(42,34,82,0.4)",
          overflow: "hidden",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "16px 18px", borderBottom: "1px solid var(--neutral-200)" }}>
          <Icon name="search" size={18} stroke={1.9} color="var(--text-soft)" />
          <input
            ref={inputRef}
            type="search"
            placeholder="Search homes, visits, quotes, messages…"
            value={query}
            onChange={(e) => { setQuery(e.target.value); setActiveIndex(0); }}
            onKeyDown={handleKey}
            style={{
              flex: 1,
              fontSize: 15,
              border: "none",
              outline: "none",
              background: "transparent",
              fontFamily: "var(--sans)",
              color: "var(--text)",
            }}
          />
          <kbd style={{ fontSize: 11, color: "var(--text-soft)", padding: "2px 6px", border: "1px solid var(--neutral-200)", borderRadius: 4 }}>esc</kbd>
        </div>

        <div style={{ maxHeight: 460, overflowY: "auto", padding: "8px 0" }}>
          {filtered.length === 0 ? (
            <div style={{ padding: 24, textAlign: "center", fontSize: 13, color: "var(--text-muted)" }}>
              No matches. Try a different search.
            </div>
          ) : (
            grouped.map(([group, items]) => (
              <div key={group} style={{ marginBottom: 8 }}>
                <div style={{ padding: "6px 18px", fontSize: 10, fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)" }}>
                  {group}
                </div>
                {items.map((r) => {
                  const idx = filtered.indexOf(r);
                  const isActive = idx === activeIndex;
                  return (
                    <button
                      key={r.id}
                      onClick={() => { setOpen(false); navigate(r.to); }}
                      onMouseEnter={() => setActiveIndex(idx)}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 10,
                        width: "100%",
                        padding: "10px 18px",
                        background: isActive ? "var(--salmon-50)" : "transparent",
                        border: "none",
                        cursor: "pointer",
                        textAlign: "left",
                      }}
                    >
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{r.label}</div>
                        {r.sub && (
                          <div style={{ fontSize: 11.5, color: "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                            {r.sub}
                          </div>
                        )}
                      </div>
                      {isActive && <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />}
                    </button>
                  );
                })}
              </div>
            ))
          )}
        </div>

        <div style={{ padding: "8px 18px", borderTop: "1px solid var(--neutral-200)", display: "flex", gap: 16, fontSize: 11, color: "var(--text-soft)" }}>
          <span><kbd style={kbdStyle}>↑↓</kbd> Navigate</span>
          <span><kbd style={kbdStyle}>↵</kbd> Open</span>
          <span><kbd style={kbdStyle}>esc</kbd> Close</span>
          <span style={{ marginLeft: "auto" }}>{filtered.length} result{filtered.length === 1 ? "" : "s"}</span>
        </div>
      </div>
    </div>
  );
}

const kbdStyle: React.CSSProperties = {
  padding: "1px 5px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 4,
  fontFamily: "var(--sans)",
  fontSize: 10,
  color: "var(--text-muted)",
};
