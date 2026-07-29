# Chez Contractor — buildout & test orchestrator

This is the **single entry point** for executing the Chez Contractor buildout work. Three companion plans, ~40 waves total, designed for subagent dispatch from fresh chats so the main thread stays slim.

---

## The three plans

| Plan | Path | Waves | Surface |
|---|---|---|---|
| **Mobile** | `Tests/e2e/CONTRACTOR_MOBILE_BUILDOUT_PLAN.md` | M0 (PWA decommission) + M1–M13 (13 waves) | Chez Field native iOS app — Haven Xcode project, target `HavenField`, scheme "Chez Field", `Haven/App/HavenFieldView.swift` |
| **Web** | `Tests/e2e/CONTRACTOR_WEB_BUILDOUT_PLAN.md` | W1–W20 + B1–B7 (27 waves) | Operations Desk SPA at `website/operations/` + cross-app |
| **Test** | `Tests/e2e/CONTRACTOR_BUILDOUT_TEST_PLAN.md` | T1–T11 (11 waves) | All three surfaces (web + mobile + iOS) |

Total surface area: **51 dispatch units**. None of them belong in the main chat — all dispatched via Agent subagents from fresh chats.

---

## Why subagents?

Every wave does heavy UI work — screenshots, DOM reads, cross-app DB checks, multi-tab Chrome MCP sessions, iOS simulator drives. Each of those costs ~2-5K tokens per screenshot. Running 3 sequential waves in the main thread would burn 30-50K tokens just on screenshot tool results.

Subagents fix this:
- Main thread sends a self-contained prompt to a fresh subagent
- Subagent does all the heavy work (screenshots, DOM reads, etc.) inside its own context window
- Subagent returns a single JSON block (≤ 500 tokens)
- Main thread aggregates results, makes decisions, dispatches next wave

This is the **only** way to ship 51 waves in one overnight + day session without main-thread compaction.

---

## How to use this

### Pre-flight (once at the start of every session)

1. Confirm the worktree is at the desired branch: `git status` clean
2. Confirm dev servers running:
   - **Vite (Operations Desk)**: `cd website/operations && npm run dev` → `localhost:5173/operations/`
   - **Static (legacy + auth)**: `cd website && python3 -m http.server 8000` → `localhost:8000/handyman.html`
3. Confirm Supabase linked: `supabase status` (should show local + linked OK)
4. Confirm Chrome MCP is connected: `mcp__Claude_in_Chrome__list_connected_browsers`
5. Confirm fixture data: `psql $SUPABASE_URL` → `SELECT count(*) FROM provider_workspaces WHERE company_name LIKE 'E2E Contractor%'` should return ≥ 3 (W1, W2, W3)
6. If fixtures missing or stale: run `psql -f Tests/e2e/cleanup-contractor.sql` then `node Tests/e2e/run-contractor.mjs`

### Dispatching a single wave (the standard pattern)

In a **fresh chat** (not the main session):

```
You are dispatched to execute Wave M{N} (or W{N}, B{N}, T{N}) of the Chez Contractor buildout.

Read these in order:
1. /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/Tests/e2e/CONTRACTOR_BUILDOUT_README.md  ← this file
2. /Users/tomburke/Documents/Projects/Housing-Manager/.claude/worktrees/priceless-burnell-028ac8/Tests/e2e/CONTRACTOR_{MOBILE|WEB|BUILDOUT_TEST}_PLAN.md  ← the relevant plan
3. /tmp/ui-test/CONTRACTOR_SETUP.md  ← env setup, JWT, test users

Execute the wave per its spec. Use the standard pre-flight + post-flight from this README.

Time-box: wave's stated effort + 25% buffer.

End with the standard JSON block (per the plan's output format).
```

### Dispatching a parallel batch

The mobile plan + web plan + test plan all describe parallelization within their wave-order sections. Use Agent tool with `run_in_background: true` for each independent wave so they fire concurrently.

Example: dispatch the test plan's "Parallel batch A" (T2 + T3 + T4 after T1 completes):

```typescript
// Pseudo-pattern — fire 3 subagents in one message
[
  { subagent_type: "general-purpose", run_in_background: true, prompt: "<T2 prompt>" },
  { subagent_type: "general-purpose", run_in_background: true, prompt: "<T3 prompt>" },
  { subagent_type: "general-purpose", run_in_background: true, prompt: "<T4 prompt>" }
]
```

Wait for completion notifications, aggregate results, dispatch next batch.

### Picking which wave to run next

Default order (when starting fresh):

1. **Pass 1 — Mobile foundation:** M1 → M2 → M6 → M3 (Mobile plan Pass 1)
2. **Pass 2 — Web foundation:** B7 → W2 → W3 → W18 (Web plan Pass 1)
3. **Pass 3 — Mobile sales:** M4 → M5 → M8 → M11 (Mobile plan Pass 2)
4. **Pass 4 — Web operations daily beat:** W1 → W5 → W8 → W9 (Web plan Pass 2)
5. **Pass 5 — Mobile edge cases:** M9 → M10 → M12 → M13 (Mobile plan Pass 3)
6. **Pass 6 — Web analytics + cases:** W4 → W6 → W10 → W14 → W15 (Web plan Pass 3)
7. **Pass 7 — Mobile crew chat:** M7 (Mobile plan Pass 4)
8. **Pass 8 — Web depth:** W7 → W11 → W12 → W16 → W17 → W20 (Web plan Pass 4)
9. **Pass 9 — Web integrations:** W13 → W19 → B1 → B2 → B3 (Web plan Pass 5)
10. **Pass 10 — Cross-app polish:** B4 → B5 → B6 (Web plan Pass 6)
11. **Pass 11 — Verification:** T1 → T2/T3/T4 (parallel) → T5/T6/T9 (parallel) → T7/T8/T10 (parallel) → T11 (Test plan all)

Total elapsed: roughly 60-80 wall-clock hours across multiple overnight runs. Each overnight = ~6-8 hours of dispatched work.

If only one overnight is available: prioritize **Pass 1 + Pass 2 + Pass 11** to land foundational shape + verify it works.

---

## Standard pre-flight (every wave)

Every subagent does these before touching code:

1. Read `/tmp/ui-test/CONTRACTOR_SETUP.md`
2. Confirm dev servers up (Vite at 5173, Python at 8000)
3. Confirm Chrome MCP connected; or iOS sim booted (for T-waves)
4. Open the relevant viewport:
   - Web waves: 1440×900 (with 1280×800 spot-check)
   - Mobile waves: 390×844 (iPhone 14 Pro mobile viewport)
   - Test waves: all three viewports
5. Sign in as the appropriate test user:
   - W1 solo: `e2e-contractor-w1@chezcontractor.test`
   - W2 crew6: `e2e-contractor-w2@chezcontractor.test`
   - W3 crew25: `e2e-contractor-w3@chezcontractor.test`
   - Customer C04: `e2e-customer-of-contractor-c04@havenhome.test`
6. Initial discipline check on the surface:
   - `grep -i 'handyman'` in rendered DOM = 0 user-facing instances
   - Em-dash count = 0 user-facing instances
   - Salmon usage matches Section 22 B1
7. Read CLAUDE.md sections relevant to the wave (Operations Desk SPA section for W-waves, Chez Field PWA section for M-waves, etc.)

---

## Standard post-flight (every wave)

Every subagent does these after implementing:

1. **TS clean** (web waves only): `cd website/operations && npx tsc --noEmit`
2. **Build clean** (web waves only): `npm run build`
3. **Apply migration** (if any): `supabase db push --linked`
4. **Edge Function deploy** (if any): `supabase functions deploy <fn> --no-verify-jwt`
5. **Take 1-3 screenshots** at the relevant viewport
6. **Cross-app DB cross-check** via service-role JWT (see `/tmp/ui-test/CONTRACTOR_SETUP.md` for JWT)
7. **Commit + push** to `claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG`:
   ```bash
   git add -A
   git commit -m "Wave {ID}: <one-line summary>

   <body listing files changed, schema migrations, edge fn deploys>

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
   git push origin claude/setup-monorepo-structure-01BAnndWeY6zCXMapoKmLMjG
   ```
8. **Confirm Vercel deploy** (within ~2 min of push, default branch auto-deploys)
9. **Return JSON block** in the format defined by the relevant plan

---

## Quality discipline (Section 22 — every wave)

This list is the **non-negotiable** discipline checklist. Every wave verifies these before marking PASS:

| Code | Description |
|---|---|
| **A1** | Save → reload → state persisted |
| **A3** | DB cross-check via service-role JWT confirms write landed |
| **B1** | Salmon discipline: only on primary CTA, active queue case accent (3px left bar), salmon-50 wash on highlighted system row in homeowner panel, fit-meter fill at success tier, SLA-critical pills. **No salmon decoration anywhere else.** |
| **B3** | No em dashes (`—` or `–`) in any user-facing copy |
| **B4** | No "handyman" in any user-facing copy. Internal class names / DB enums / file names preserved. |
| **B6** | Touch targets ≥ 44pt (mobile) or ≥ 44px (web) on every primary CTA |
| **B9** | Empty / loading / error / populated states for every async surface |
| **C1** | Empty submit on every form fires validation visibly |
| **C7** | Network failure mid-save → clear error + retry |
| **D1** | Skeleton loaders, never spinners on blank screens |
| **D2** | Nav active state visible (left rail / bottom tab) |
| **D7** | White-space discipline — no white-on-white, no overlapping text, no clipped descenders |
| **E1** | Background → foreground state preservation (mobile + iOS) |

---

## Progress tracking

Maintain `Tests/e2e/CONTRACTOR_BUILDOUT_PROGRESS.md` (create on first wave commit) with:

```markdown
# Chez Contractor buildout — progress log

## Status: <X waves complete / 51>

| Wave | Plan | Status | Commit | Date | Notes |
|---|---|---|---|---|---|
| M1 | Mobile | ✅ PASS | abc123 | 2026-05-08 | clock-in/out + GPS, 90 min |
| M2 | Mobile | ⏸ PARTIAL | def456 | 2026-05-08 | photos done; voice deferred |
| W2 | Web | ✅ PASS | ghi789 | 2026-05-09 | full settings depth |
| ... | ... | ... | ... | ... | ... |
```

Update after every commit. Log deferred work in `Tests/e2e/CONTRACTOR_GAPS.md`.

---

## Failure handling

If a wave returns FAIL:

1. **Log full failure** in `Tests/e2e/CONTRACTOR_BUILDOUT_FAILURES.md` with:
   - Wave ID
   - Step that failed
   - Repro steps
   - Error message / screenshot
   - Last working commit
2. **Decide**: dispatch a fix wave (new chat) OR defer to a later pass
3. **Update PROGRESS.md** with FAIL status + decision

If a test wave (T-wave) returns FAIL:
1. Trace the failing step back to the originating buildout wave (mobile/web/B)
2. Open a fix wave for that buildout wave
3. Re-run the test wave after fix lands

---

## Demo readiness checklist

Demo is **GO** when:

- ✅ Pass 1 (mobile foundation) complete: M1, M2, M6, M3
- ✅ Pass 2 (web foundation) complete: B7, W2, W3, W18
- ✅ T1 + T11 (visit lifecycle + final dry-run) PASS
- ✅ No regressions in demo path
- ✅ Vercel production deploy reflects latest commit
- ✅ Supabase Edge Functions deployed
- ✅ iOS Haven app TestFlight build current
- ✅ Section 22 discipline checklist clean on every demo screen
- ✅ www.getchez.com loads cleanly + auth flow round-trips through `?next=`

If any of those is missing: demo is **NO-GO**. Defer demo or scope down what's shown.

---

## Test user reference card

Quick reference (full details in `/tmp/ui-test/CONTRACTOR_SETUP.md`):

| User | Workspace | Role | Email |
|---|---|---|---|
| W1 owner | E2E Contractor 01 (solo) | owner | `e2e-contractor-w1@chezcontractor.test` |
| W2 owner | E2E Contractor 02 (crew of 6) | owner | `e2e-contractor-w2@chezcontractor.test` |
| W2 tech 1 | E2E Contractor 02 | tech | `e2e-contractor-w2-tech1@chezcontractor.test` |
| W3 owner | E2E Contractor 03 (crew of 25) | owner | `e2e-contractor-w3@chezcontractor.test` |
| Customer 1 | (homeowner side) | — | `e2e-customer-of-contractor-c01@havenhome.test` |
| Customer 4 | (homeowner side, chez_owned routine) | — | `e2e-customer-of-contractor-c04@havenhome.test` |
| Tom (admin) | All workspaces | admin | `burkepthomas@gmail.com` |

Password for all test users: `Test1234!` (set at seed time).

---

## Files referenced by this orchestrator

| Path | Purpose |
|---|---|
| `Tests/e2e/CONTRACTOR_MOBILE_BUILDOUT_PLAN.md` | M1-M13 spec |
| `Tests/e2e/CONTRACTOR_WEB_BUILDOUT_PLAN.md` | W1-W20 + B1-B7 spec |
| `Tests/e2e/CONTRACTOR_BUILDOUT_TEST_PLAN.md` | T1-T11 spec |
| `Tests/e2e/CONTRACTOR_BUILDOUT_README.md` | this file |
| `Tests/e2e/cleanup-contractor.sql` | per-run cleanup script |
| `Tests/e2e/run-contractor.mjs` | fixture seed script |
| `Tests/e2e/CHEZ_CONTRACTOR_WEB_TEST_MATRIX.md` | original 27-section test matrix (overnight pass) |
| `Tests/e2e/HANDYMAN_OVERNIGHT_E2E_REPORT.md` | overnight findings report |
| `Tests/e2e/CONTRACTOR_BUILDOUT_PROGRESS.md` | progress log (create on first wave) |
| `Tests/e2e/CONTRACTOR_BUILDOUT_FAILURES.md` | failure log (create on first FAIL) |
| `Tests/e2e/CONTRACTOR_GAPS.md` | deferred work log (create on first PARTIAL) |
| `/tmp/ui-test/CONTRACTOR_SETUP.md` | env, JWT, test users (out of repo) |
| `CLAUDE.md` | project context (root) |

---

## Closing — what this orchestrator delivers

After running every wave defined here, the Chez Contractor system covers:

- ✅ **51 waves shipped** across mobile (13) + web (20) + cross-app (7) + verification (11)
- ✅ **Every Section 22 concern** addressed on every surface
- ✅ **Every cross-app parity check** verified via service-role JWT
- ✅ **Every demo path** clean
- ✅ **Every UI discipline rule** maintained throughout

Mobile contractor surface: **demo skeleton → field-ready depth.**
Web operator surface: **dispatch shell → enterprise-grade pro-services back office.**
Cross-app integration: **separate apps → unified concierge experience.**

Tom can demo the entire premium contractor flow end-to-end without any apologies.

---

## One-line dispatch invocation (cheat sheet)

```
Dispatch Wave {ID}. Read CONTRACTOR_BUILDOUT_README.md, then the relevant plan, then execute. Standard pre/post-flight. Standard JSON output.
```

That's it. Drop that line into a fresh chat with the wave ID filled in. The subagent does the rest.
