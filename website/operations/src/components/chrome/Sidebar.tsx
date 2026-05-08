import { useEffect, useRef, useState } from "react";
import { NavLink } from "react-router-dom";
import { Icon } from "./Icon";
import { useWorkspace } from "../../lib/workspace-context";
import { Avatar, initialsFor } from "./Avatar";
import type { AvailableWorkspace, ProviderRole } from "../../lib/types";

interface NavItem {
  to: string;
  label: string;
  icon: string;
  end?: boolean;
  crewOnly?: boolean;
  /**
   * Wave P: gate Settings to roles that can edit the workspace
   * (owner / admin via canManageWorkspace). Tom does not want
   * dispatchers / technicians editing branding.
   */
  ownerOnly?: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "Overview", icon: "grid", end: true },
  { to: "/visits", label: "Visits", icon: "calendar" },
  { to: "/calendar", label: "Calendar", icon: "calendar" },
  { to: "/routes", label: "Routes", icon: "route" },
  { to: "/crew", label: "Crew", icon: "crew", crewOnly: true },
  { to: "/homes", label: "Homes", icon: "home" },
  { to: "/quotes", label: "Quotes", icon: "quote" },
  { to: "/invoices", label: "Invoices", icon: "receipt" },
  { to: "/messages", label: "Messages", icon: "message" },
  { to: "/settings", label: "Settings", icon: "gear", ownerOnly: true },
];

/**
 * Wave S — friendly role label for the dropdown rows. Mirrors the rest
 * of the SPA's role taxonomy (see types.ts ProviderRole). Anything we
 * don't recognize falls through to the role string itself.
 */
function roleDisplay(role: ProviderRole | string): string {
  switch (role) {
    case "owner":
      return "Owner";
    case "admin":
      return "Admin";
    case "dispatcher":
      return "Dispatcher";
    case "technician":
      return "Technician";
    default:
      return role || "Member";
  }
}

export function Sidebar() {
  const { dashboard, mode, signOut, switchWorkspace } = useWorkspace();
  const [switcherOpen, setSwitcherOpen] = useState(false);
  const switcherRef = useRef<HTMLDivElement | null>(null);

  const canEditWorkspace = Boolean(
    dashboard?.permissions.canManageWorkspace ?? dashboard?.permissions.canBootstrapWorkspace,
  );
  const visibleItems = NAV_ITEMS.filter((item) => {
    if (item.crewOnly && mode !== "crew") return false;
    if (item.ownerOnly && !canEditWorkspace) return false;
    return true;
  });

  const memberFullName = dashboard?.currentUser.fullName || dashboard?.currentUser.email || "Operator";
  const memberInitials = initialsFor(memberFullName);
  const memberEmail = dashboard?.currentUser.email ?? "";

  const workspaceName = dashboard?.workspace.companyName ?? "Workspace";
  const memberCount = dashboard?.workspace.activeMemberCount ?? 1;
  const subLabel =
    mode === "sole"
      ? "Sole proprietor"
      : `${memberCount} teammate${memberCount === 1 ? "" : "s"}`;

  // Wave S — only show the dropdown affordance for users with multiple
  // workspace memberships. Single-workspace users see the pill exactly
  // as before, with no chevron and no click handler.
  const availableWorkspaces: AvailableWorkspace[] = dashboard?.availableWorkspaces ?? [];
  const hasMultipleWorkspaces = availableWorkspaces.length > 1;

  // Click-outside + escape to close. Standard popover hygiene — no
  // headless-ui dependency, just a useEffect that listens at the
  // document level when the popover is open.
  useEffect(() => {
    if (!switcherOpen) return;
    const handlePointer = (event: MouseEvent) => {
      if (!switcherRef.current) return;
      if (switcherRef.current.contains(event.target as Node)) return;
      setSwitcherOpen(false);
    };
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSwitcherOpen(false);
    };
    document.addEventListener("mousedown", handlePointer);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handlePointer);
      document.removeEventListener("keydown", handleKey);
    };
  }, [switcherOpen]);

  const handleWorkspaceClick = () => {
    if (!hasMultipleWorkspaces) return;
    setSwitcherOpen((prev) => !prev);
  };

  const handleSelectWorkspace = (workspaceId: string) => {
    setSwitcherOpen(false);
    void switchWorkspace(workspaceId);
  };

  return (
    <aside className="ops-sidebar">
      {/* Brand row. The mark filename keeps its legacy "handyman" path
          for asset compat; only the user-visible strings rebrand. */}
      <a className="ops-sidebar__brand" href="/" aria-label="Chez Contractor">
        <img
          className="ops-sidebar__brand-mark-img"
          src="/chez-handyman-logo.png"
          alt=""
        />
        <div className="ops-sidebar__brand-text">
          <div className="ops-sidebar__brand-name">chez</div>
          <div className="ops-sidebar__brand-eyebrow">contractor</div>
        </div>
      </a>

      {/* Workspace switcher. Single-workspace users see a non-interactive
          pill (no chevron, no hover state escalation). Multi-workspace
          users get a button with a dropdown menu listing every
          membership. Wave S landed the dropdown; the prior version was a
          dead button with a TODO. */}
      <div className="ops-sidebar__workspace-wrap" ref={switcherRef}>
        <button
          className="ops-sidebar__workspace"
          type="button"
          onClick={handleWorkspaceClick}
          aria-label={hasMultipleWorkspaces ? "Switch workspace" : "Workspace"}
          aria-haspopup={hasMultipleWorkspaces ? "menu" : undefined}
          aria-expanded={hasMultipleWorkspaces ? switcherOpen : undefined}
          disabled={!hasMultipleWorkspaces}
          style={!hasMultipleWorkspaces ? { cursor: "default" } : undefined}
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
          {hasMultipleWorkspaces ? (
            <Icon name="chevronDown" size={14} color="rgba(255,255,255,0.5)" stroke={2.2} />
          ) : null}
        </button>

        {hasMultipleWorkspaces && switcherOpen ? (
          <div
            className="ops-sidebar__workspace-popover"
            role="menu"
            aria-label="Switch workspace"
          >
            <div className="ops-sidebar__workspace-popover__header">
              Your workspaces
            </div>
            {availableWorkspaces.map((ws) => (
              <button
                key={ws.id}
                className={`ops-sidebar__workspace-option${ws.isCurrent ? " is-current" : ""}`}
                type="button"
                role="menuitem"
                onClick={() => handleSelectWorkspace(ws.id)}
              >
                <Avatar
                  initials={initialsFor(ws.companyName)}
                  size={26}
                  fontSize={10}
                  color="#5D4C8F"
                />
                <div className="ops-sidebar__workspace-option-info">
                  <span className="ops-sidebar__workspace-option-name">{ws.companyName}</span>
                  <span className="ops-sidebar__workspace-option-role">{roleDisplay(ws.role)}</span>
                </div>
                <span className="ops-sidebar__workspace-option-check">
                  {ws.isCurrent ? <Icon name="check" size={14} stroke={2.4} color="#ED6955" /> : null}
                </span>
              </button>
            ))}
          </div>
        ) : null}
      </div>

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
