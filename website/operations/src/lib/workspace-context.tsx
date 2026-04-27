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
        setDashboard(null);
        return;
      }
      if (isInitial) setIsLoading(true);
      else setIsRefreshing(true);
      try {
        const data = await fetchDashboard();
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
    await supabase.auth.signOut();
    window.location.assign("/handyman.html");
  }, []);

  const value: WorkspaceContextValue = {
    session,
    dashboard,
    mode,
    isLoading,
    isRefreshing,
    error,
    signOut,
    refresh,
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
