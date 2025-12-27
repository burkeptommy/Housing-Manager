# Haven Development Prompts

This folder contains comprehensive prompts for Claude Code to implement features.

## How to Use with Claude Code

Point Claude Code to a prompt file:

```
Read the prompt at prompts/001-homeowner-portal-production-ready.md and implement it phase by phase. Start with Phase 1.
```

Or for a specific phase:

```
Read prompts/002-home-manager-intake-workbench.md and implement Phase 3: Intake Workbench UI.
```

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| 001 | `001-homeowner-portal-production-ready.md` | Activity logging, Dashboard, Your Home (zones), Money/Bills, Family pages | 🔄 Running |
| 002 | `002-home-manager-intake-workbench.md` | Onboarding queue, zone-based intake workbench, monthly funding calculator | ⏳ Next |

---

## Naming Convention

Files are numbered sequentially:
- `001-[feature-name].md`
- `002-[feature-name].md`
- etc.

---

## Prompt Structure

Each prompt follows this format:

1. **Goal** - What we're building and why
2. **Context** - Background and dependencies
3. **Phases** - Numbered implementation phases
   - Task X.1, X.2, etc.
   - Prisma schema changes
   - API endpoints
   - Frontend pages
4. **Build & Deploy** - Commands to ship
5. **Testing Checklist** - Verification steps

---

## Adding New Prompts

When creating new prompts:

1. Use next sequential number
2. Include clear phase breakdowns
3. Put Prisma schema changes first
4. Include both API and frontend code
5. End with build/deploy instructions
6. Add testing checklist
7. Update this README

---

## Project Location

All prompts assume the project is at:
```
/Users/tomburke/Projects/Housing-Manager/
```

---

## Dependencies Between Prompts

```
001 (Homeowner Portal)
 └── Requires: Activity logging foundation
 └── Creates: Dashboard, Your Home, Money, Family pages
 
002 (HM Intake Workbench)
 └── Requires: 001 complete (data must have somewhere to go)
 └── Creates: Onboarding queue, intake tool, data processing
 
003 (Approval System) - PLANNED
 └── Requires: 001 + 002
 └── Creates: Approval requests, homeowner approve/deny flow
 
004 (Handyman Portal) - PLANNED
 └── Requires: 001 + 002
 └── Creates: Task list, completion flow, photo upload
```

---

## Quick Reference

**Run a prompt:**
```
Read prompts/002-home-manager-intake-workbench.md and implement it.
```

**Check current status:**
See `/README.md` in project root

**After completing a prompt:**
1. Update status in this file
2. Update project README.md
3. Commit changes
