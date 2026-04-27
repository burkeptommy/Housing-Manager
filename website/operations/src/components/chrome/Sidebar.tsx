import { NavLink } from "react-router-dom";
import { Icon } from "./Icon";
import { useWorkspace } from "../../lib/workspace-context";
import { Avatar, initialsFor } from "./Avatar";

interface NavItem {
  to: string;
  label: string;
  icon: string;
  end?: boolean;
  crewOnly?: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "Overview", icon: "grid", end: true },
  { to: "/dispatch", label: "Dispatch", icon: "dispatch" },
  { to: "/calendar", label: "Calendar", icon: "calendar" },
  { to: "/routes", label: "Routes", icon: "route" },
  { to: "/crew", label: "Crew", icon: "crew", crewOnly: true },
  { to: "/homes", label: "Homes", icon: "home" },
  { to: "/quotes", label: "Quotes", icon: "quote" },
  { to: "/messages", label: "Messages", icon: "message" },
];

export function Sidebar() {
  const { dashboard, mode, signOut } = useWorkspace();

  const visibleItems = NAV_ITEMS.filter(
    (item) => !item.crewOnly || mode === "crew"
  );

  const memberFullName = dashboard?.currentUser.fullName || dashboard?.currentUser.email || "Operator";
  const memberInitials = initialsFor(memberFullName);
  const memberEmail = dashboard?.currentUser.email ?? "";

  const workspaceName = dashboard?.workspace.companyName ?? "Workspace";
  const memberCount = dashboard?.workspace.activeMemberCount ?? 1;
  const subLabel =
    mode === "sole"
      ? "Sole proprietor"
      : `${memberCount} teammate${memberCount === 1 ? "" : "s"}`;

  return (
    <aside className="ops-sidebar">
      {/* Brand row */}
      <div className="ops-sidebar__brand">
        <div className="ops-sidebar__brand-mark">c</div>
        <div className="ops-sidebar__brand-text">
          <div className="ops-sidebar__brand-name">Chez</div>
          <div className="ops-sidebar__brand-eyebrow">Handyman</div>
        </div>
      </div>

      {/* Workspace switcher */}
      <button
        className="ops-sidebar__workspace"
        type="button"
        onClick={() => {
          // TODO multi-workspace: open switcher modal. v1 uses single workspace.
        }}
        aria-label="Switch workspace"
      >
        <Avatar
          initials={initialsFor(workspaceName)}
          size={28}
          fontSize={11}
          color="#5D4C8F"
        />
        <div className="ops-sidebar__workspace-info">
          <span className="ops-sidebar__workspace-name">{workspaceName}</span>
          <span className="ops-sidebar__workspace-sub">{subLabel}</span>
        </div>
        <Icon name="chevronDown" size={14} color="rgba(255,255,255,0.5)" stroke={2.2} />
      </button>

      {/* Nav */}
      <nav className="ops-sidebar__nav">
        {visibleItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            className={({ isActive }) =>
              `ops-sidebar__nav-item ${isActive ? "is-active" : ""}`
            }
          >
            <Icon name={item.icon} size={18} stroke={1.9} />
            {item.label}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="ops-sidebar__footer">
        <Avatar initials={memberInitials} size={32} color="#453A70" />
        <div className="ops-sidebar__footer-info">
          <div className="ops-sidebar__footer-name">{memberFullName}</div>
          <div className="ops-sidebar__footer-email">{memberEmail}</div>
        </div>
        <button
          className="ops-sidebar__footer-button"
          type="button"
          onClick={signOut}
          aria-label="Sign out"
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}
