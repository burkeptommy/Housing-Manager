# Codex ↔ Claude communication log

Async Q&A channel between Codex (running tests) and Claude (lead dev who wrote the test plan). Codex writes a question here when blocked. Tom summons Claude in a separate session to read + answer in-place. Codex polls the file before resuming work on the affected scenario.

## Protocol

**When Codex should write here:**
- Architecture question ("why does Phase 80.2 route delegate_task through smart category routing?")
- Test interpretation ("matrix row 5.18 says 'specialty system inference' — what counts as a passing verification vs a gap?")
- Recent change context ("what did the morning fix pass change about AuthService that I should be aware of?")
- Fix-safety check ("I'm about to refactor `MaintenanceTaskReconciler.reconcile`. Safe to do, or does this have side effects I should know about?")
- Bug triage ("found a bug in PropertyRecapCard — should I fix it now or defer?")
- Anything genuinely blocking that a 5-min Claude consult would unblock

**When Codex should NOT write here:**
- Things resolvable by reading code + CLAUDE.md
- Things Codex can answer by running a quick script
- Pure preference questions ("what color should this be?") — assume the design system unless contradicted

**How Tom relays:**
- Codex flags a new question
- Tom opens a Claude Code session, pastes "answer the open questions in `Tests/e2e/CODEX_QUESTIONS.md`"
- Claude reads + answers in-place + commits + pushes
- Codex pulls + resumes

## Format per question

```markdown
## YYYY-MM-DD HH:MM — Short topic title

**Codex question:** [the question, specific and answerable]

**Context:** [matrix row reference, file:line if relevant, what you tried so far]

**Why blocking:** [what testing is paused on this — be honest, "nice-to-know" goes elsewhere]

**Answer (Claude):** [filled in later]

**Codex follow-up:** [if needed; delete this line if not]

---
```

## Open questions (newest first)

## 2026-05-09 23:32 — Slow-network signup simulation for row 1.6

**Codex question:** What is the preferred way to execute HOMEOWNER_COMPLETE_TEST_MATRIX Section 1a row 1.6 ("Slow network/3G signup race") in this simulator environment, given that `simctl` has no network conditioning subcommand, Network Link Conditioner is not installed, and non-interactive `sudo` is blocked for `pf`/`dnctl` throttling?

**Context:** Row 1.6 is part of Round A's must-address signup regression suite. I verified row 1.4 weak-password recovery and row 1.5 duplicate-email sign-in in the simulator. I checked `xcrun simctl help`, searched `/Applications` and `/Library` for Network Link Conditioner, verified `dnctl`/`pfctl` require sudo, and searched the app for existing E2E/network-delay launch hooks. I did not find a safe built-in slow-network path.

**Why blocking:** I can continue the rest of Round A, but I cannot honestly mark 1.6 as simulator-verified slow network without either an approved local mechanism, a DEBUG-only test hook, or explicit permission to record it as environment-limited/deferred.

**Answer (Claude):** [filled in later]

**Codex follow-up:** [if needed; delete this line if not]

---

---

## Resolved questions archive

_(Claude moves answered questions here once Codex confirms unblocked)_
