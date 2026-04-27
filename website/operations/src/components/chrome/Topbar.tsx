import { useLocation, useNavigate } from "react-router-dom";
import { Icon } from "./Icon";

interface RouteMeta {
  title: string;
  eyebrow?: string;
  breadcrumb?: string;
  primaryCta?: { label: string; action: "new-quote" | "navigate"; to?: string };
}

const ROUTE_META: Record<string, RouteMeta> = {
  "/": {
    eyebrow: "Operations · " + new Date().toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" }).toUpperCase(),
    title: "Today's desk",
    breadcrumb: "Workspace overview",
    primaryCta: { label: "+ New quote", action: "new-quote" },
  },
  "/visits": {
    title: "Visits",
    breadcrumb: "Schedule, route, and run today's work",
  },
  "/calendar": {
    title: "Calendar",
    breadcrumb: "Visits across your team",
  },
  "/routes": {
    title: "Routes",
    breadcrumb: "Per-tech daily routing",
  },
  "/crew": {
    title: "Crew",
    breadcrumb: "Roster, profiles, and access",
  },
  "/homes": {
    title: "Homes",
    breadcrumb: "Every home you've worked on",
    primaryCta: { label: "+ New quote", action: "new-quote" },
  },
  "/quotes": {
    title: "Quotes",
    breadcrumb: "Pipeline and quote builder",
    primaryCta: { label: "+ New quote", action: "new-quote" },
  },
  "/messages": {
    title: "Messages",
    breadcrumb: "Homeowner conversations",
  },
};

export function Topbar() {
  const location = useLocation();
  const navigate = useNavigate();
  // Match exact route or prefix (so /visits/:id still shows "Visits" meta)
  const meta = (() => {
    if (ROUTE_META[location.pathname]) return ROUTE_META[location.pathname];
    if (location.pathname.startsWith("/visits/")) return ROUTE_META["/visits"];
    if (location.pathname.startsWith("/homes/")) return ROUTE_META["/homes"];
    return { title: "Operations" };
  })();

  function openSearch() {
    window.dispatchEvent(new CustomEvent("ops:open-search"));
  }

  function handleCta() {
    if (!meta.primaryCta) return;
    if (meta.primaryCta.action === "new-quote") {
      window.dispatchEvent(new CustomEvent("ops:open-new-quote"));
    } else if (meta.primaryCta.action === "navigate" && meta.primaryCta.to) {
      navigate(meta.primaryCta.to);
    }
  }

  return (
    <header className="ops-topbar">
      <div className="ops-topbar__title-block">
        {meta.eyebrow && <div className="ops-topbar__eyebrow">{meta.eyebrow}</div>}
        <div className="ops-topbar__title">{meta.title}</div>
        {meta.breadcrumb && <div className="ops-topbar__breadcrumb">{meta.breadcrumb}</div>}
      </div>

      <div className="ops-topbar__right">
        <button
          className="ops-topbar__search"
          type="button"
          onClick={openSearch}
          style={{ background: "#fff", border: "1px solid var(--neutral-200)", borderRadius: 10, padding: 0, cursor: "pointer", display: "flex", alignItems: "center", height: 36, width: 240 }}
          aria-label="Search (Cmd+K)"
        >
          <span className="ops-topbar__search-icon" style={{ position: "static", transform: "none", marginLeft: 10 }}>
            <Icon name="search" size={15} stroke={1.9} />
          </span>
          <span style={{ flex: 1, fontSize: 13, color: "var(--text-soft)", textAlign: "left", padding: "0 10px", fontFamily: "var(--sans)" }}>
            Search…
          </span>
          <span className="ops-topbar__search-hint" style={{ position: "static", transform: "none", marginRight: 10 }}>⌘K</span>
        </button>

        <button className="ops-topbar__bell" type="button" aria-label="Notifications">
          <Icon name="bell" size={16} stroke={1.9} />
        </button>

        {meta.primaryCta && (
          <button
            className="ops-button ops-button--salmon"
            onClick={handleCta}
          >
            {meta.primaryCta.label}
          </button>
        )}
      </div>
    </header>
  );
}
