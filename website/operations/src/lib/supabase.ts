import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Same project + anon key as `website/handyman.js`. The anon key is safe
// to ship in client code — RLS gates everything per-workspace via
// `provider_workspace_members.user_id = auth.uid()`.
const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

export const supabase: SupabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  {
    auth: {
      // Reuse the session that `website/handyman.js` writes to localStorage
      // so users don't sign in twice when they hop between the auth pitch
      // and the operations app.
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  }
);

export const PROVIDER_API_URL = `${SUPABASE_URL}/functions/v1/handyman-provider`;
