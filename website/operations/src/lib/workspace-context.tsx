import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { Session, RealtimeChannel } from "@supabase/supabase-js";
import { supabase } from "./supabase";
import { fetchDashboard } from "./api";
import type { Dashboard, WorkspaceMode } from "./types";

interface WorkspaceContextValue {
  session: Session | null;
  dashboard: Dashboard | null;
  mode: WorkspaceMode;
  isLoading: boolean;
  isRefreshing: boolean;
  error: string | null;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
  /**
   * Wave S — set the user's preferred workspace and reload the dashboard.
   * Persists to localStorage so the choice survives reloads. The full
   * page reloads after the dashboard refresh resolves, which clears any
   * route-level state stale to the previous workspace (selected quote,
   * open visit, draft text, etc.). No-op if the requested id is already
   * the current one or doesn't exist in availableWorkspaces.
   */
  switchWorkspace: (workspaceId: string) => Promise<void>;
}

/**
 * Wave S — localStorage key for the sticky workspace selection. Lives
 * outside React state so a full reload after switchWorkspace() picks up
 * the new value before the WorkspaceProvider mounts.
 */
const WORKSPACE_STORAGE_KEY = "ops:current_workspace_id";

function readStoredWorkspaceId(): string | undefined {
  if (typeof window === "undefined") return undefined;
  try {
    return window.localStorage.getItem(WORKSPACE_STORAGE_KEY) ?? undefined;
  } catch {
    return undefined;
  }
}

function writeStoredWorkspaceId(id: string | null): void {
  if (typeof window === "undefined") return;
  try {
    if (id) window.localStorage.setItem(WORKSPACE_STORAGE_KEY, id);
    else window.localStorage.removeItem(WORKSPACE_STORAGE_KEY);
  } catch {
    // Storage may be disabled (private mode, quota); silently fall back
    // to single-workspace behavior. The dashboard load still works.
  }
}

const WorkspaceContext = createContext<WorkspaceContextValue | null>(null);

export function WorkspaceProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const realtimeChannelRef = useRef<RealtimeChannel | null>(null);
  const refreshDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // ?mode=sole|crew query string overrides the auto-detected mode.
  const queryMode = useMemo<WorkspaceMode | null>(() => {
    if (typeof window === "undefined") return null;
    const v = new URLSearchParams(window.location.search).get("mode");
    return v === "sole" || v === "crew" ? (v as WorkspaceMode) : null;
  }, []);

  const detectedMode: WorkspaceMode =
    (dashboard?.workspace.activeMemberCount ?? 0) > 1 ? "crew" : "sole";
  const mode: WorkspaceMode = queryMode ?? detectedMode;

  const loadDashboard = useCallback(
    async (currentSession: Session | null, isInitial: boolean) => {
      if (!currentSession) {
        // No session — clear any cached dashboard AND flip isLoading off
        // so the App-level auth gate's `!isLoading && !session` redirect
        // can actually fire. Without this flag flip the SPA hangs on
        // "Loading your workspace…" forever for any unauth'd visitor.
        setDashboard(null);
        if (isInitial) setIsLoading(false);
        return;
      }
      if (isInitial) setIsLoading(true);
      else setIsRefreshing(true);
      try {
        // Wave S — pull the sticky workspace preference and pass it to
        // the edge function. Edge function validates membership and falls
        // back to the default first-active pick if the id is stale.
        const storedWorkspaceId = readStoredWorkspaceId();
        const data = await fetchDashboard(storedWorkspaceId);
        // If the loaded workspace ended up being a different one than
        // requested (stale localStorage entry pointing at a workspace
        // the user no longer belongs to), rewrite the cache so we don't
        // keep retrying that id on every refresh.
        if (storedWorkspaceId && data.workspace?.id && storedWorkspaceId !== data.workspace.id) {
          writeStoredWorkspaceId(data.workspace.id);
        }
        if (data.needsWorkspace) {
          // Session exists but no provider workspace yet — the bootstrap
          // flow lives on handyman.html. Redirect there with a hint.
          // Skip when the URL already carries `?demo=1` so design previews
          // work without a real workspace.
          const isDemo = new URLSearchParams(window.location.search).get("demo") === "1";
          if (!isDemo) {
            window.location.assign("/handyman.html?bootstrap=1");
            return;
          }
        }
        setDashboard(data);
        setError(null);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        console.error("[WorkspaceProvider] dashboard fetch failed", msg);
        setError(msg);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    []
  );

  const refresh = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    setSession(data.session);
    await loadDashboard(data.session, false);
  }, [loadDashboard]);

  /**
   * Schedule a debounced refresh so a burst of Realtime events doesn't
   * fire 50 dashboard fetches. We coalesce inside a 500ms window.
   */
  const scheduleRefresh = useCallback(() => {
    if (refreshDebounceRef.current) clearTimeout(refreshDebounceRef.current);
    refreshDebounceRef.current = setTimeout(() => {
      refresh();
    }, 500);
  }, [refresh]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const { data } = await supabase.auth.getSession();
      if (cancelled) return;
      setSession(data.session);
      await loadDashboard(data.session, true);
    })();

    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      loadDashboard(newSession, false);
    });
    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, [loadDashboard]);

  // Realtime: subscribe to inserts on handyman_request_messages and
  // handyman_requests as soon as we have a session. Phase 74 added the
  // provider-side SELECT policy so RLS lets the workspace owner see
  // these change events.
  //
  // On any insert we debounce-refresh the entire dashboard. The fetch
  // is one round-trip and propagates to every screen that reads
  // useWorkspace().dashboard, so screens stay in sync without bespoke
  // per-screen wiring.
  useEffect(() => {
    if (!session) return;

    const channel = supabase
      .channel("ops-desk-realtime")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "handyman_request_messages" },
        () => scheduleRefresh()
      )
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "handyman_requests" },
        () => scheduleRefresh()
      )
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "handyman_requests" },
        () => scheduleRefresh()
      )
      .subscribe();

    realtimeChannelRef.current = channel;

    return () => {
      channel.unsubscribe();
      realtimeChannelRef.current = null;
      if (refreshDebounceRef.current) {
        clearTimeout(refreshDebounceRef.current);
        refreshDebounceRef.current = null;
      }
    };
  }, [session, scheduleRefresh]);

  const signOut = useCallback(async () => {
    // Wave S — clear the sticky workspace preference on sign-out so the
    // next user landing on this browser doesn't inherit the previous
    // operator's last-selected workspace. Storage failure is non-fatal.
    writeStoredWorkspaceId(null);
    await supabase.auth.signOut();
    window.location.assign("/handyman.html");
  }, []);

  const switchWorkspace = useCallback(
    async (workspaceId: string) => {
      // Defensive guards: skip no-op switches and unknown ids.
      const id = workspaceId.trim();
      if (!id) return;
      const current = dashboard?.workspace?.id;
      if (current && current === id) return;
      const known = (dashboard?.availableWorkspaces ?? []).some((w) => w.id === id);
      if (!known) return;

      // Persist the choice BEFORE reloading so the next mount picks it up.
      writeStoredWorkspaceId(id);
      // Hard reload — switching workspaces invalidates every cached row
      // (assignments, quotes, visits, drafts in feature views). A reload
      // is simpler and more robust than threading invalidation through
      // every screen. Trade-off: ~700ms versus ~150ms incremental refresh,
      // but we get correctness for free.
      window.location.reload();
    },
    [dashboard?.availableWorkspaces, dashboard?.workspace?.id],
  );

  const value: WorkspaceContextValue = {
    session,
    dashboard,
    mode,
    isLoading,
    isRefreshing,
    error,
    signOut,
    refresh,
    switchWorkspace,
  };

  return (
    <WorkspaceContext.Provider value={value}>
      {children}
    </WorkspaceContext.Provider>
  );
}

export function useWorkspace(): WorkspaceContextValue {
  const ctx = useContext(WorkspaceContext);
  if (!ctx) {
    throw new Error("useWorkspace must be used inside <WorkspaceProvider>");
  }
  return ctx;
}
