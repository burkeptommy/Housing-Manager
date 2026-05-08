import { useEffect, useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { postProviderAction } from "../lib/api";
import type { AggregateTask } from "../lib/types";

/**
 * Wave Z.2 — Tasks aggregate screen.
 *
 * One scannable list of every open punch item + maintenance task across
 * the workspace's customers. Tom called this out as a differentiator —
 * "I want to see every task we're on the hook for, not browse customer
 * by customer." Filters by status / customer / tech so a dispatcher
 * can pull a per-tech task plan in one click.
 *
 * Data path: `fetch_aggregate_tasks` action on the handyman-provider
 * Edge Function (Wave Z.2 added; not part of loadDashboard so the
 * regular page loads stay lean). Mutations go through the existing
 * `update_punch_item_status` action; maintenance_task completion is
 * out of scope for this screen (handled on the visit detail surface).
 */
export default function TasksScreen() {
  const { dashboard } = useWorkspace();
  const [tasks, setTasks] = useState<AggregateTask[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "open" | "completed">("open");
  const [customerFilter, setCustomerFilter] = useState<Set<string>>(new Set());
  const [techFilter, setTechFilter] = useState<Set<string>>(new Set());
  const [busyId, setBusyId] = useState<string | null>(null);

  // Initial fetch + reload on workspace switch.
  const workspaceId = dashboard?.workspace.id;
  useEffect(() => {
    if (!workspaceId) return;
    let cancelled = false;
    setLoading(true);
    setLoadError(null);
    postProviderAction<{ tasks: AggregateTask[] }>("fetch_aggregate_tasks", {
      workspaceId,
    })
      .then((res) => {
        if (cancelled) return;
        setTasks(res.tasks ?? []);
      })
      .catch((e) => {
        if (cancelled) return;
        setLoadError(e instanceof Error ? e.message : "Couldn't load tasks.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, [workspaceId]);

  const allTasks = tasks ?? [];

  // Distinct lists for the filter chips.
  const customers = useMemo(() => {
    const map = new Map<string, string>();
    for (const t of allTasks) {
      if (t.customerPropertyId && t.customerName) {
        map.set(t.customerPropertyId, t.customerName);
      }
    }
    return Array.from(map.entries())
      .map(([id, name]) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [allTasks]);

  const techs = useMemo(() => {
    const set = new Set<string>();
    for (const t of allTasks) {
      if (t.assignedTechName) set.add(t.assignedTechName);
    }
    return Array.from(set).sort();
  }, [allTasks]);

  // Apply all filters.
  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return allTasks.filter((t) => {
      // Status
      if (statusFilter === "open" && (t.status === "done" || t.status === "cancelled")) return false;
      if (statusFilter === "completed" && t.status !== "done") return false;
      // Customer
      if (customerFilter.size > 0 && !customerFilter.has(t.customerPropertyId)) return false;
      // Tech (null means unassigned)
      if (techFilter.size > 0) {
        if (!t.assignedTechName) return false;
        if (!techFilter.has(t.assignedTechName)) return false;
      }
      // Search
      if (q && !t.title.toLowerCase().includes(q) && !t.customerName.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [allTasks, statusFilter, customerFilter, techFilter, searchQuery]);

  // Group by customer for the rendered list (improves scan-ability
  // when filters land on a single customer's work).
  const grouped = useMemo(() => {
    const map = new Map<string, AggregateTask[]>();
    for (const t of filtered) {
      const key = t.customerPropertyId || "unassigned";
      const arr = map.get(key) ?? [];
      arr.push(t);
      map.set(key, arr);
    }
    return Array.from(map.entries()).map(([propertyId, items]) => ({
      propertyId,
      customerName: items[0]?.customerName || "Customer",
      items,
    }));
  }, [filtered]);

  const stats = useMemo(() => {
    let open = 0;
    let done = 0;
    for (const t of allTasks) {
      if (t.status === "done") done += 1;
      else if (t.status !== "cancelled") open += 1;
    }
    return { open, done };
  }, [allTasks]);

  // Tap-checkbox handler. Punch items get a real flip via
  // update_punch_item_status; maintenance_tasks don't have a server
  // action wired here (deferred to the visit detail surface) so we
  // optimistically toggle locally and surface an info pill in v1.
  async function toggleTask(t: AggregateTask) {
    if (busyId) return;
    setBusyId(t.id);

    if (t.source === "punch_item") {
      const newStatus = t.status === "done" ? "pending" : "done";
      // Optimistic
      setTasks((prev) =>
        prev ? prev.map((row) => (row.id === t.id ? { ...row, status: newStatus } : row)) : prev,
      );
      try {
        await postProviderAction("update_punch_item_status", {
          itemId: t.rawId,
          status: newStatus,
        });
      } catch (e) {
        // Revert
        setTasks((prev) =>
          prev ? prev.map((row) => (row.id === t.id ? { ...row, status: t.status } : row)) : prev,
        );
        alert(e instanceof Error ? e.message : "Couldn't update the task.");
      } finally {
        setBusyId(null);
      }
    } else {
      // Maintenance task — completion lives on the visit detail screen.
      // Defer rather than wire a partial path. Surface a hint and bail.
      alert("Mark this task complete from the visit detail screen.");
      setBusyId(null);
    }
  }

  function toggleCustomer(propertyId: string) {
    setCustomerFilter((prev) => {
      const next = new Set(prev);
      if (next.has(propertyId)) next.delete(propertyId);
      else next.add(propertyId);
      return next;
    });
  }

  function toggleTech(name: string) {
    setTechFilter((prev) => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name);
      else next.add(name);
      return next;
    });
  }

  if (!dashboard) return null;

  if (loading) {
    return (
      <Card padding="default">
        <div style={{ padding: 32, textAlign: "center", color: "var(--text-muted)", fontSize: 14 }}>
          Loading task aggregate...
        </div>
      </Card>
    );
  }

  if (loadError) {
    return (
      <Card padding="default">
        <EmptyState
          icon="wrench"
          title="Couldn't load tasks"
          body={loadError}
        />
      </Card>
    );
  }

  if (allTasks.length === 0) {
    return (
      <Card padding="default">
        <EmptyState
          icon="wrench"
          title="No tasks across your customers yet"
          body="When visits are assigned, every punch list item and visit task will roll up here for a one-glance status across the whole book."
        />
      </Card>
    );
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      {/* Header with stats + search */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
          <div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              All tasks
            </div>
            <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 2 }}>
              {stats.open} open across {customers.length} {customers.length === 1 ? "customer" : "customers"} · {stats.done} completed
            </div>
          </div>
          <div style={{ marginLeft: "auto", position: "relative", minWidth: 240 }}>
            <Icon name="search" size={14} stroke={1.9}
              style={{ position: "absolute", top: 11, left: 10, color: "var(--text-soft)" }}
            />
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search task or customer"
              style={{
                width: "100%",
                padding: "8px 10px 8px 30px",
                border: "1px solid var(--neutral-200)",
                borderRadius: 10,
                fontSize: 13,
                fontFamily: "var(--sans)",
                color: "var(--text)",
              }}
            />
          </div>
        </div>
      </Card>

      {/* Filters */}
      <Card padding="default">
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {/* Status row */}
          <FilterRow label="Status">
            {(["all", "open", "completed"] as const).map((s) => (
              <FilterChip
                key={s}
                active={statusFilter === s}
                onClick={() => setStatusFilter(s)}
              >
                {s === "all" ? "All" : s === "open" ? "Open" : "Completed"}
              </FilterChip>
            ))}
          </FilterRow>
          {customers.length > 0 && (
            <FilterRow label="Customer">
              {customerFilter.size > 0 && (
                <button
                  className="ops-button ops-button--ghost"
                  style={{ height: 26, padding: "2px 10px", fontSize: 11, color: "var(--text-soft)" }}
                  onClick={() => setCustomerFilter(new Set())}
                >
                  Clear
                </button>
              )}
              {customers.map((c) => (
                <FilterChip
                  key={c.id}
                  active={customerFilter.has(c.id)}
                  onClick={() => toggleCustomer(c.id)}
                >
                  {c.name}
                </FilterChip>
              ))}
            </FilterRow>
          )}
          {techs.length > 0 && (
            <FilterRow label="Tech">
              {techFilter.size > 0 && (
                <button
                  className="ops-button ops-button--ghost"
                  style={{ height: 26, padding: "2px 10px", fontSize: 11, color: "var(--text-soft)" }}
                  onClick={() => setTechFilter(new Set())}
                >
                  Clear
                </button>
              )}
              {techs.map((name) => (
                <FilterChip
                  key={name}
                  active={techFilter.has(name)}
                  onClick={() => toggleTech(name)}
                >
                  {name}
                </FilterChip>
              ))}
            </FilterRow>
          )}
        </div>
      </Card>

      {/* Task list */}
      {filtered.length === 0 ? (
        <Card padding="default">
          <EmptyState
            icon="wrench"
            title="No tasks match your filters"
            body="Adjust the filters above to see more rows, or clear them to view the full list."
          />
        </Card>
      ) : (
        <Card padding="default">
          {grouped.map((group, gi) => (
            <div key={group.propertyId}>
              <div style={{
                fontSize: 11,
                fontWeight: 600,
                letterSpacing: "0.08em",
                textTransform: "uppercase",
                color: "var(--text-soft)",
                padding: gi === 0 ? "0 0 8px" : "16px 0 8px",
                borderBottom: "1px solid var(--neutral-200)",
                marginBottom: 6,
              }}>
                {group.customerName} · {group.items.length} {group.items.length === 1 ? "task" : "tasks"}
              </div>
              {group.items.map((t) => (
                <TaskRow
                  key={t.id}
                  task={t}
                  busy={busyId === t.id}
                  onToggle={() => toggleTask(t)}
                />
              ))}
            </div>
          ))}
        </Card>
      )}
    </div>
  );
}

function FilterRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
      <span style={{
        fontSize: 10.5,
        fontWeight: 600,
        letterSpacing: "0.08em",
        textTransform: "uppercase",
        color: "var(--text-soft)",
        minWidth: 64,
      }}>
        {label}
      </span>
      <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
        {children}
      </div>
    </div>
  );
}

function FilterChip({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      style={{
        height: 28,
        padding: "0 12px",
        background: active ? "var(--indigo)" : "transparent",
        color: active ? "#fff" : "var(--text-muted)",
        border: active ? "1px solid var(--indigo)" : "1px solid var(--neutral-200)",
        borderRadius: 999,
        fontSize: 11.5,
        fontWeight: 500,
        cursor: "pointer",
        transition: "background 0.12s ease, color 0.12s ease",
      }}
    >
      {children}
    </button>
  );
}

function TaskRow({ task, busy, onToggle }: { task: AggregateTask; busy: boolean; onToggle: () => void }) {
  const isDone = task.status === "done";
  const isCancelled = task.status === "cancelled";
  const sourceTone: PillTone =
    task.source === "punch_item" ? "neutral" : "indigo";

  // Due date label.
  let dueLabel: string | null = null;
  if (task.dueDate) {
    const d = new Date(task.dueDate);
    if (!Number.isNaN(d.getTime())) {
      dueLabel = d.toLocaleDateString(undefined, { month: "short", day: "numeric" });
    }
  }

  return (
    <div style={{
      display: "flex",
      alignItems: "center",
      gap: 12,
      padding: "12px 0",
      borderBottom: "1px solid var(--neutral-100, #F3F4F6)",
      opacity: isDone || isCancelled ? 0.55 : 1,
    }}>
      <button
        type="button"
        onClick={onToggle}
        disabled={busy || isCancelled}
        aria-label={isDone ? "Mark task as not done" : "Mark task as done"}
        style={{
          width: 22,
          height: 22,
          minWidth: 22,
          borderRadius: 999,
          border: isDone ? "none" : "1.5px solid var(--neutral-300, #D8DADF)",
          background: isDone ? "var(--success, #10B981)" : "transparent",
          cursor: busy ? "wait" : "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: 0,
        }}
      >
        {isDone && <Icon name="check" size={12} stroke={3} color="#fff" />}
      </button>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 13,
          fontWeight: 500,
          color: "var(--text)",
          textDecoration: isDone ? "line-through" : "none",
          lineHeight: 1.4,
        }}>
          {task.title}
        </div>
        <div style={{
          fontSize: 11,
          color: "var(--text-muted)",
          marginTop: 3,
          display: "flex",
          alignItems: "center",
          gap: 8,
          flexWrap: "wrap",
        }}>
          <Pill tone={sourceTone}>{task.sourceKindLabel}</Pill>
          {task.estimatedMinutes != null && (
            <span>~{task.estimatedMinutes} min</span>
          )}
          {dueLabel && (
            <span style={{ display: "flex", alignItems: "center", gap: 3 }}>
              <Icon name="calendar" size={11} stroke={1.9} />
              {dueLabel}
            </span>
          )}
          {task.assignedTechName && (
            <span style={{ display: "flex", alignItems: "center", gap: 3 }}>
              <Icon name="user" size={11} stroke={1.9} />
              {task.assignedTechName}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
