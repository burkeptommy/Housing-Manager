// Phase 95 — Centralized AI cost discipline.
//
// Every Edge Function that calls Claude should route through this helper
// instead of fetch()-ing the Anthropic API directly. It provides:
//
//   1. **Cheap-first model ladder.** Default is haiku-4-5 (~3-5× cheaper
//      than sonnet on input, ~3× on output). Sonnet stays in the ladder
//      as a fallback for resilience but is never billed unless haiku
//      errors out (rate limit, overload, server error). Per-call
//      override available for callers that genuinely need sonnet's
//      reasoning depth.
//
//   2. **Kill-switch.** Set CHEZ_AI_ENABLED=false in Edge Function
//      secrets to short-circuit every Claude call. Tom can flip this
//      in seconds if billing alerts fire.
//
//   3. **Per-day spend cap.** Set CHEZ_AI_DAILY_BUDGET_USD (default
//      $50). Each call estimates its cost (input + output tokens at
//      the model's rate) and refuses to fire if today's running total
//      already exceeds the cap. Prevents loops from blowing the bill.
//
//   4. **Telemetry.** Every successful call writes one row to
//      `chez_ai_usage` so daily spend is visible per call site / model.
//
//   5. **Optional ephemeral prompt caching.** When the system prompt is
//      reused across many turns (e.g. ask_alfred's dossier), pass
//      cache_system: true and only the first call in the 5-min window
//      pays full input tokens.
//
// Usage:
//   import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";
//   const result = await callClaudeWithDiscipline({
//     supabase,           // for telemetry inserts (optional but recommended)
//     apiKey,
//     tag: "analyze_request",
//     max_tokens: 800,
//     messages: [{ role: "user", content: prompt }],
//     // optional:
//     system: "You are…",
//     cache_system: true,
//     models: ["claude-haiku-4-5", "claude-sonnet-4-6"],  // override the ladder
//     request_id, household_id, user_id,
//   });
//   if (!result) {
//     // AI was disabled or every model failed. Render degraded UX.
//   }

// deno-lint-ignore-file no-explicit-any

const DEFAULT_MODELS: readonly string[] = [
  // Cheapest first. The 5-digit pinned date variant is rejected by the
  // free fallback if Anthropic deprecates it; the alias catches us.
  "claude-haiku-4-5-20251001",
  "claude-haiku-4-5",
  "claude-sonnet-4-6",
];

// Approx Anthropic prices (USD per 1M tokens) as of Q2 2026. These are
// rough — the real bill comes from Anthropic — but they're accurate
// enough for the per-day spend cap to be useful.
const PRICE_PER_1M_INPUT_USD: Record<string, number> = {
  "claude-haiku-4-5": 1.0,
  "claude-haiku-4-5-20251001": 1.0,
  "claude-haiku-3-5": 0.8,
  "claude-sonnet-4-6": 3.0,
  "claude-opus-4-5": 15.0,
  // Opus 4.6 — premium reasoning model. Reserved for high-stakes
  // calls (analyze_quote) where accuracy >> per-call cost. ~5×
  // sonnet, ~15× haiku on input. The budget cap will refuse to
  // fire it once the daily total exceeds CHEZ_AI_DAILY_BUDGET_USD,
  // so even a runaway opus loop is bounded.
  "claude-opus-4-6": 15.0,
};
const PRICE_PER_1M_OUTPUT_USD: Record<string, number> = {
  "claude-haiku-4-5": 5.0,
  "claude-haiku-4-5-20251001": 5.0,
  "claude-haiku-3-5": 4.0,
  "claude-sonnet-4-6": 15.0,
  "claude-opus-4-5": 75.0,
  "claude-opus-4-6": 75.0,
};

export interface AiCallOptions {
  /// Service-role Supabase client. Used for telemetry inserts +
  /// daily-spend gating. Pass null to skip both (smaller test calls).
  supabase: any | null;
  /// Anthropic API key. Falsy values cause a no-op return.
  apiKey: string | null | undefined;
  /// Telemetry tag — short identifier for the call site
  /// (e.g. "analyze_request", "research_project_pro").
  tag: string;
  /// Cap on output tokens. **Pick the smallest value the prompt can
  /// possibly need.** Bigger caps don't make output longer but they
  /// allow the model to ramble.
  max_tokens: number;
  messages: Array<{ role: "user" | "assistant"; content: string | any }>;
  /// Optional system prompt. When cache_system: true, the prompt is
  /// sent as an ephemeral cache block (5-min TTL).
  system?: string;
  cache_system?: boolean;
  /// Per-call ladder override. Defaults to DEFAULT_MODELS (cheapest first).
  models?: readonly string[];
  /// Per-call extras for telemetry rows.
  request_id?: string | null;
  household_id?: string | null;
  user_id?: string | null;
  /// Per-call temperature (default leaves Anthropic default in place).
  temperature?: number;
}

export interface AiCallResult {
  text: string;
  model_used: string;
  input_tokens: number;
  output_tokens: number;
  cache_read_tokens: number;
  cache_creation_tokens: number;
}

let _dailyTotalUsd: number | null = null;
let _dailyTotalLoadedAt = 0;

/// Read today's running spend from chez_ai_usage. Cached for 60 s so
/// we don't hammer the DB on every call. The cap exists to break
/// runaway loops; it doesn't need to be precise.
async function loadTodaysSpendUsd(supabase: any | null): Promise<number> {
  if (!supabase) return 0;
  const now = Date.now();
  if (_dailyTotalUsd !== null && now - _dailyTotalLoadedAt < 60_000) {
    return _dailyTotalUsd;
  }
  try {
    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const { data, error } = await supabase
      .from("chez_ai_usage")
      .select("model, input_tokens, output_tokens, cache_read_tokens")
      .gte("created_at", startOfDay.toISOString())
      .limit(5000);
    if (error || !data) {
      _dailyTotalUsd = 0;
      _dailyTotalLoadedAt = now;
      return 0;
    }
    let total = 0;
    for (const row of data as Array<{ model: string; input_tokens: number; output_tokens: number; cache_read_tokens: number }>) {
      const inRate = PRICE_PER_1M_INPUT_USD[row.model] ?? 3.0;
      const outRate = PRICE_PER_1M_OUTPUT_USD[row.model] ?? 15.0;
      const billedInput = Math.max(0, (row.input_tokens ?? 0) - (row.cache_read_tokens ?? 0)) +
        (row.cache_read_tokens ?? 0) * 0.1; // cache reads are ~10% of input price
      total += (billedInput / 1_000_000) * inRate;
      total += ((row.output_tokens ?? 0) / 1_000_000) * outRate;
    }
    _dailyTotalUsd = total;
    _dailyTotalLoadedAt = now;
    return total;
  } catch (e) {
    console.warn("[ai-discipline] daily spend lookup failed:", e);
    return 0;
  }
}

export async function callClaudeWithDiscipline(opts: AiCallOptions): Promise<AiCallResult | null> {
  // Hard kill-switch.
  const enabled = (Deno.env.get("CHEZ_AI_ENABLED") ?? "true").toLowerCase();
  if (enabled === "false" || enabled === "0" || enabled === "off") {
    console.warn(`[ai-discipline] disabled by kill-switch — skipping ${opts.tag}`);
    return null;
  }
  if (!opts.apiKey) {
    console.warn(`[ai-discipline] no API key — skipping ${opts.tag}`);
    return null;
  }

  // Per-day budget cap. Default $50/day. Set CHEZ_AI_DAILY_BUDGET_USD
  // higher when you want to spend more, or lower for paranoid days.
  const budgetStr = Deno.env.get("CHEZ_AI_DAILY_BUDGET_USD");
  const budget = budgetStr ? Number(budgetStr) : 50;
  if (budget > 0) {
    const spent = await loadTodaysSpendUsd(opts.supabase);
    if (spent >= budget) {
      console.warn(`[ai-discipline] daily budget $${budget} exhausted ($${spent.toFixed(2)} spent) — skipping ${opts.tag}`);
      return null;
    }
  }

  const models = opts.models?.length ? opts.models : DEFAULT_MODELS;
  const systemBlocks = opts.system
    ? (opts.cache_system
      ? [{ type: "text", text: opts.system, cache_control: { type: "ephemeral" } }]
      : opts.system)
    : undefined;

  let lastError: { status: number; body: string } | null = null;
  for (const model of models) {
    try {
      const body: Record<string, unknown> = {
        model,
        max_tokens: opts.max_tokens,
        messages: opts.messages,
      };
      if (systemBlocks) body.system = systemBlocks;
      if (opts.temperature !== undefined) body.temperature = opts.temperature;
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
        "x-api-key": opts.apiKey,
        "anthropic-version": "2023-06-01",
      };
      if (opts.cache_system) {
        headers["anthropic-beta"] = "prompt-caching-2024-07-31";
      }
      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers,
        body: JSON.stringify(body),
      });
      if (resp.ok) {
        const data = await resp.json() as {
          content?: Array<{ text?: string }>;
          usage?: {
            input_tokens?: number;
            output_tokens?: number;
            cache_read_input_tokens?: number;
            cache_creation_input_tokens?: number;
          };
        };
        const text = data.content?.[0]?.text?.trim() ?? "";
        const usage = data.usage ?? {};
        const result: AiCallResult = {
          text,
          model_used: model,
          input_tokens: usage.input_tokens ?? 0,
          output_tokens: usage.output_tokens ?? 0,
          cache_read_tokens: usage.cache_read_input_tokens ?? 0,
          cache_creation_tokens: usage.cache_creation_input_tokens ?? 0,
        };
        // Fire-and-forget telemetry.
        if (opts.supabase) {
          opts.supabase.from("chez_ai_usage").insert({
            tag: opts.tag,
            model,
            input_tokens: result.input_tokens,
            output_tokens: result.output_tokens,
            cache_read_tokens: result.cache_read_tokens,
            cache_creation_tokens: result.cache_creation_tokens,
            request_id: opts.request_id ?? null,
            household_id: opts.household_id ?? null,
            user_id: opts.user_id ?? null,
            max_tokens: opts.max_tokens,
          }).then(({ error }: { error: any }) => {
            if (error) console.warn("[ai-discipline] usage log failed:", error.message);
            // Bust the spend cache so subsequent calls within 60s see this row.
            _dailyTotalUsd = null;
          });
        }
        return result;
      }
      const errBody = await resp.text();
      lastError = { status: resp.status, body: errBody.slice(0, 300) };
      console.warn(`[ai-discipline] ${opts.tag} failed on ${model}: ${resp.status}`, errBody.slice(0, 200));
      const retryable = resp.status === 429 || resp.status === 529 || resp.status >= 500;
      if (!retryable) break;
    } catch (e) {
      lastError = { status: 0, body: String(e) };
      console.warn(`[ai-discipline] ${opts.tag} exception on ${model}:`, e);
    }
  }
  console.warn(`[ai-discipline] ${opts.tag} exhausted all models. last error:`, lastError);
  return null;
}
