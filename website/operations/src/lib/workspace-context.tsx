import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { Session } from "@supabase/supabase-js";
import { supabase } from "./supabase";
import type {
  ProviderWorkspace,
  ProviderWorkspaceMember,
  WorkspaceMode,
} from "./types";

interface WorkspaceContextValue {
  session: Session | null;
  workspace: ProviderWorkspace | null;
  member: ProviderWorkspaceMember | null;
  members: ProviderWorkspaceMember[];
  mode: WorkspaceMode;
  isLoading: boolean;
  error: string | null;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
}

const WorkspaceContext = createContext<WorkspaceContextValue | null>(null);

export function WorkspaceProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [workspace, setWorkspace] = useState<ProviderWorkspace | null>(null);
  const [member, setMember] = useState<ProviderWorkspaceMember | null>(null);
  const [members, setMembers] = useState<ProviderWorkspaceMember[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ?mode=sole|crew query string overrides the auto-detected mode. Useful
  // for the design-handoff fixtures route and for screenshot diffs.
  const queryMode = useMemo<WorkspaceMode | null>(() => {
    if (typeof window === "undefined") return null;
    const v = new URLSearchParams(window.location.search).get("mode");
    return v === "sole" || v === "crew" ? (v as WorkspaceMode) : null;
  }, []);

  const mode: WorkspaceMode =
    queryMode ?? (members.length > 1 ? "crew" : "sole");

  const fetchWorkspace = useCallback(
    async (currentSession: Session | null) => {
      if (!currentSession) {
        setWorkspace(null);
        setMember(null);
        setMembers([]);
        return;
      }
      try {
        const { data: memberRows, error: memberError } = await supabase
          .from("provider_workspace_members")
          .select("*")
          .eq("user_id", currentSession.user.id)
          .order("created_at", { ascending: true });

        if (memberError) throw memberError;
        const myMember = (memberRows ?? [])[0] ?? null;
        setMember(myMember);

        if (!myMember) {
          // Session exists but the user has no provider workspace yet.
          // Send them back to handyman.html for the bootstrap flow,
          // which knows how to spin up a `provider_workspaces` row +
          // attach an owner member. Skip the redirect when the URL
          // already carries `?demo=1` so design previews work without
          // a real workspace.
          if (typeof window !== "undefined" && new URLSearchParams(window.location.search).get("demo") !== "1") {
            window.location.assign("/handyman.html?bootstrap=1");
            return;
          }
          setWorkspace(null);
          setMembers([]);
          return;
        }

        const [{ data: ws, error: wsError }, { data: roster, error: rosterError }] =
          await Promise.all([
            supabase
              .from("provider_workspaces")
              .select("*")
              .eq("id", myMember.workspace_id)
              .single(),
            supabase
              .from("provider_workspace_members")
              .select("*")
              .eq("workspace_id", myMember.workspace_id)
              .order("role", { ascending: true }),
          ]);

        if (wsError) throw wsError;
        if (rosterError) throw rosterError;
        setWorkspace(ws);
        setMembers(roster ?? []);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        console.error("[WorkspaceProvider] fetch failed", msg);
        setError(msg);
      }
    },
    []
  );

  const refresh = useCallback(async () => {
    setIsLoading(true);
    const { data } = await supabase.auth.getSession();
    setSession(data.session);
    await fetchWorkspace(data.session);
    setIsLoading(false);
  }, [fetchWorkspace]);

  useEffect(() => {
    refresh();
    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      fetchWorkspace(newSession);
    });
    return () => sub.subscription.unsubscribe();
  }, [refresh, fetchWorkspace]);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    window.location.assign("/handyman.html");
  }, []);

  const value: WorkspaceContextValue = {
    session,
    workspace,
    member,
    members,
    mode,
    isLoading,
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
