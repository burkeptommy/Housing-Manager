# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## Current Status (December 28, 2024)

**NOW:** Approval System (008) running in Claude Code

**NEXT:** Maintenance Calendar (009) - ready to go

---

## Full Roadmap

See detailed roadmap: `/ROADMAP.md`

```
PHASE 1: CORE TRUST MODEL ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━
[✓] Admin Portal (004)
[✓] Manager Portal (005)  
[✓] Homeowner Portal (006-007)
[✓] Test Suite (100%)
[→] Approval System (008) ← NOW

PHASE 2: INSTANT VALUE 🎯
━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Maintenance Calendar (009) ← NEXT
[ ] Document Vault (010)
[ ] Plaid Bill Detection (011)

PHASE 3: MAGIC ONBOARDING ⚡
━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Onboarding 2.0 (012)
[ ] Photo Upload + AI (013)
[ ] Email Parsing (014)

PHASE 4: COMMUNICATION 💬
━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] SMS/Text Interface (015)
[ ] Push Notifications (016)
[ ] In-App Messaging (017)

PHASE 5: NETWORK EFFECTS 🌐
━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Vendor Network (018)
[ ] Handyman Portal (019)
[ ] Member Recommendations (020)
```

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| 003 | `003-production-ready-real-data.md` | APIs, seed data, onboarding | ✅ Done |
| 004 | `004-admin-portal.md` | Admin portal + Tom's account | ✅ Done |
| 005 | `005-fix-login-connect-manager.md` | Fix login + Manager Portal | ✅ Done |
| 006 | `006-fix-demo-login-auto-tests.md` | Fix demo login + auto tests | ✅ Done |
| 007 | `007-fix-remaining-tests.md` | Fix 4 failing tests | ✅ Done (100%) |
| **008** | `008-approval-system.md` | Approval workflow | 🔄 Running |
| 009 | `009-maintenance-calendar.md` | Auto-generated maintenance | 📋 Ready |
| 010 | TBD | Document Vault | 📋 Planned |
| 011 | TBD | Plaid Integration | 📋 Planned |
| 012 | TBD | Onboarding 2.0 | 📋 Planned |

---

## After 008 Completes - Run This:

```
Read the prompt at prompts/009-maintenance-calendar.md and implement all phases.

This auto-generates maintenance tasks from ATTOM property data:
- Seasonal HVAC service based on heating/cooling type
- Pool opening/closing if pool detected
- Septic pumping schedule if septic
- Filter changes, chimney sweeps, etc.

User sees value IMMEDIATELY on signup - "12 maintenance tasks identified"

After implementing:
1. Run the Prisma migration
2. Deploy to production  
3. Run: pnpm test:e2e
4. Report results

CRITICAL: DO NOT DELETE any existing code, only add and refactor.
```

---

## The Data Capture Strategy

We don't eliminate the manager call - we change what it's FOR:

| Layer | Source | Data |
|-------|--------|------|
| **1. Automatic** | ATTOM API | Property basics, systems |
| **2. Automatic** | Plaid (future) | All recurring bills |
| **3. Low-effort** | Quick wizard | Family names, urgent issues |
| **4. Optional** | Photo upload | Appliance details via AI |
| **5. Manager call** | Verification | Confirm data + build relationship |
| **6. Over time** | Progressive | Fill gaps as we go |

**Result:** 15-min relationship call, not 45-min data entry

---

## Key Documents

| Document | Purpose |
|----------|---------|
| `/ROADMAP.md` | Full development roadmap |
| `/ONBOARDING_AUDIT.md` | Current vs competitor analysis |
| `/HAVEN_PROJECT_INSTRUCTIONS.md` | Master context for all development |

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
