import { useLocation, useNavigate } from "react-router-dom";
import { Icon } from "./Icon";

interface RouteMeta {
  title: string;
  eyebrow?: string;
  breadcrumb?: string;
  primaryCta?: { label: string; to?: string; onClick?: () => void };
}

const ROUTE_META: Record<string, RouteMeta> = {
  "/": {
    eyebrow: "Operations · " + new Date().toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" }).toUpperCase(),
    title: "Today's desk",
    breadcrumb: "Workspace overview",
    primaryCta: { label: "+ New quote", to: "/quotes" },
  },
  "/dispatch": {
    title: "Dispatch",
    breadcrumb: "Assign visits to your crew",
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
    primaryCta: { label: "+ Invite teammate" },
  },
  "/homes": {
    title: "Homes",
    breadcrumb: "Every home you've worked on",
  },
  "/quotes": {
    title: "Quotes",
    breadcrumb: "Pipeline and quote builder",
    primaryCta: { label: "+ New quote" },
  },
  "/messages": {
    title: "Messages",
    breadcrumb: "Homeowner conversations",
  },
};

export function Topbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const meta = ROUTE_META[location.pathname] ?? { title: "Operations" };

  return (
    <header className="ops-topbar">
      <div className="ops-topbar__title-block">
        {meta.eyebrow && <div className="ops-topbar__eyebrow">{meta.eyebrow}</div>}
        <div className="ops-topbar__title">{meta.title}</div>
        {meta.breadcrumb && <div className="ops-topbar__breadcrumb">{meta.breadcrumb}</div>}
      </div>

      <div className="ops-topbar__right">
        <div className="ops-topbar__search">
          <span className="ops-topbar__search-icon">
            <Icon name="search" size={15} stroke={1.9} />
          </span>
          <input type="search" placeholder="Search homes, quotes, threads…" aria-label="Search" />
          <span className="ops-topbar__search-hint">⌘K</span>
        </div>

        <button className="ops-topbar__bell" type="button" aria-label="Notifications">
          <Icon name="bell" size={16} stroke={1.9} />
          <span className="ops-topbar__bell-dot" aria-hidden="true" />
        </button>

        {meta.primaryCta && (
          <button
            className="ops-button ops-button--salmon"
            onClick={() => {
              if (meta.primaryCta?.to) navigate(meta.primaryCta.to);
              meta.primaryCta?.onClick?.();
            }}
          >
            {meta.primaryCta.label}
          </button>
        )}
      </div>
    </header>
  );
}
