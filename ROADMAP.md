# Haven Development Roadmap

**Last Updated:** December 28, 2024  
**Current Status:** Approval System (008) running

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         HAVEN ROADMAP                               │
│                "10-Minute Magic" Journey                            │
└─────────────────────────────────────────────────────────────────────┘

PHASE 1: CORE TRUST MODEL ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━
[✓] Admin Portal
[✓] Manager Portal  
[✓] Homeowner Portal
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

## Detailed Sequence

### NOW: Approval System (008) 🔄
**Status:** Running in Claude Code

**What it does:**
- Sarah requests approval for expenses
- Bob reviews and approves/rejects in /app
- Comments thread for discussion
- Activity logging

**Why it matters:** Core trust model - homeowners stay in control

---

### NEXT: Maintenance Calendar (009) 🎯
**Priority:** P0 - Highest Impact  
**Effort:** Medium (1-2 days)  
**Dependencies:** None (uses existing ATTOM data)

**What it does:**
```
Auto-generates maintenance tasks from property data:

ATTOM tells us          →    We generate
─────────────────────────────────────────
Gas heat                →    Annual furnace service (fall)
                        →    Filter changes (quarterly)
Central AC              →    AC tune-up (spring)
                        →    Filter changes (quarterly)
Pool                    →    Pool opening (spring)
                        →    Pool closing (fall)
                        →    Weekly service (summer)
Septic system           →    Septic pumping (every 3 years)
Year built: 1985        →    Roof inspection (>20 years)
                        →    Water heater check (>10 years)
Oil heat                →    Oil delivery scheduling
                        →    Tank inspection
Fireplace               →    Chimney sweep (annual)
```

**User sees immediately:**
- "12 maintenance tasks identified"
- Calendar view with seasonal items
- "3 items due this season"
- Manager can schedule vendors for any task

**Why it matters:** 
- Instant "wow" on signup
- Uses data we ALREADY HAVE
- Visible proof Haven is proactive
- Differentiator from every other app

---

### THEN: Document Vault (010)
**Priority:** P0  
**Effort:** Medium (1-2 days)  
**Dependencies:** None

**What it does:**
```
/app/vault
├── Property Documents (deed, survey, title)
├── Insurance Policies
├── Warranties & Manuals
├── Receipts & Invoices
├── Tax Records
└── Vendor Contracts

Features:
- Drag-and-drop upload
- Photo capture from mobile
- Category organization
- Expiration tracking (warranties, policies)
- Search (with OCR later)
- Share with manager
```

**Why it matters:**
- Expected feature for home management
- Enables email forwarding later
- Foundation for warranty tracking

---

### THEN: Plaid Bill Detection (011)
**Priority:** P0  
**Effort:** Medium-Hard (2-3 days)  
**Dependencies:** Plaid account setup

**What it does:**
```
User connects bank account
         ↓
Plaid returns all transactions
         ↓
AI categorizes recurring charges:
- Mortgage: $3,200/mo (Chase)
- Electric: $180/mo (Eversource)  
- Internet: $89/mo (Optimum)
- HOA: $450/mo (Bedford HOA)
- Insurance: $210/mo (State Farm)
... etc
         ↓
User confirms: "Found 14 bills - look right?"
         ↓
Bills auto-populate in system
```

**Why it matters:**
- Eliminates manual bill entry
- "Magic" moment in onboarding
- Catches bills user forgot about
- Most impactful automation

---

### THEN: Onboarding 2.0 (012)
**Priority:** P1  
**Effort:** Hard (3-4 days)  
**Dependencies:** 009, 010, 011 should be done first

**What it does:**
```
NEW FLOW (10 minutes to value):

1. Address (30s)
   └── Google Places autocomplete

2. Property Intelligence (instant)
   └── Show ATTOM data + maintenance calendar
   └── "We identified 12 things your home needs"

3. Connect Bills (2 min) - optional
   └── Plaid connection
   └── "Found 14 bills totaling $4,200/mo"

4. Quick Profile (2 min)
   └── Who lives here (just names)
   └── Anything urgent?
   
5. Meet Your Manager
   └── Sarah's photo + intro
   └── Schedule 15-min call OR text now

6. Dashboard with Value
   └── Maintenance calendar populated
   └── Bills listed (if Plaid connected)
   └── Document vault ready
   └── "Sarah is reviewing your home"
```

**Manager call becomes:**
- 15-20 minutes (not 45)
- Verify data, not collect it
- Build relationship
- Fill gaps (vendors, preferences)

---

### THEN: Photo Upload + AI (013)
**Priority:** P1  
**Effort:** Medium (2 days)  
**Dependencies:** Document vault (010)

**What it does:**
```
User takes photos of:
- Water heater label
- HVAC unit
- Electrical panel
- Appliances

AI extracts:
- Brand, model, serial number
- Age estimate
- Warranty lookup
- Manual PDF link

Auto-populates home inventory
```

**Why it matters:**
- Gets detailed data without tedious questions
- Users already take photos of things
- Builds complete home inventory

---

### THEN: Email Parsing (014)
**Priority:** P1  
**Effort:** Medium (2 days)  
**Dependencies:** Document vault (010)

**What it does:**
```
User forwards emails to:
- bills@haven.app → Parsed into bill tracker
- docs@haven.app → Stored in document vault

We extract:
- Vendor name
- Amount due
- Due date
- Account number
- Category
```

**Why it matters:**
- Passive data collection
- Catches bills not in Plaid
- Easy for non-tech users

---

### THEN: SMS Interface (015)
**Priority:** P1  
**Effort:** Medium (2 days)  
**Dependencies:** Twilio account

**What it does:**
```
Bob texts Sarah's Haven number:
"Hey, dishwasher is making weird noise"

System:
- Creates service request
- Sarah sees in manager portal
- Sarah responds via portal or text
- Bob gets text response

Two-way SMS conversation
```

**Why it matters:**
- How people actually want to communicate
- Lower friction than opening app
- Feels like personal assistant

---

### LATER: Push Notifications (016)
**Priority:** P2  
**Effort:** Easy (1 day)

- Approval request pending
- Bill due in 3 days
- Maintenance task due
- Message from manager

---

### LATER: In-App Messaging (017)
**Priority:** P2  
**Effort:** Medium (2 days)

- Chat thread between Bob and Sarah
- Attached photos, documents
- History searchable

---

### LATER: Vendor Network (018)
**Priority:** P2  
**Effort:** Hard (3-4 days)

- Pre-vetted vendors by category
- Background checked, licensed, insured
- Member reviews and ratings
- Preferred pricing
- "Members in your area also use..."

---

### LATER: Handyman Portal (019)
**Priority:** P2  
**Effort:** Medium (2-3 days)

- Mike sees assigned work orders
- Check-in/check-out
- Photo documentation
- Time tracking
- Parts/expenses logging

---

## Summary: Next 5 Prompts

| Order | Prompt | What | Effort | Impact |
|-------|--------|------|--------|--------|
| **NOW** | 008 | Approval System | Medium | 🔥 Core |
| **1** | 009 | Maintenance Calendar | Medium | 🔥🔥🔥 Instant wow |
| **2** | 010 | Document Vault | Medium | 🔥🔥 Expected |
| **3** | 011 | Plaid Integration | Medium-Hard | 🔥🔥🔥 Magic |
| **4** | 012 | Onboarding 2.0 | Hard | 🔥🔥🔥 Transforms UX |

---

## After 008 Completes

Run this in Claude Code:

```
Read the prompt at prompts/009-maintenance-calendar.md and implement all phases.

This auto-generates maintenance tasks from ATTOM property data:
- Seasonal HVAC service based on heating/cooling type
- Pool opening/closing if pool detected
- Septic pumping schedule if septic
- Filter changes, chimney sweeps, etc.

User sees value IMMEDIATELY on signup - "12 maintenance tasks identified"

After implementing, run: pnpm test:e2e

CRITICAL: DO NOT DELETE any existing code, only add and refactor.
```

---

## Timeline Estimate

| Phase | Prompts | Time | Milestone |
|-------|---------|------|-----------|
| Phase 1 | 008 | Done today | Trust model complete |
| Phase 2 | 009-011 | 1 week | Instant value on signup |
| Phase 3 | 012-014 | 1 week | "10-minute magic" flow |
| Phase 4 | 015-017 | 1 week | Full communication |
| Phase 5 | 018-020 | 2 weeks | Network effects |

**Target:** Complete through Phase 3 by mid-January 2025

---

## The End State

After all phases:

```
NEW USER SIGNS UP
        ↓
    10 MINUTES LATER
        ↓
┌─────────────────────────────────────────┐
│ Dashboard shows:                        │
│ ✓ Property profile (ATTOM)              │
│ ✓ 14 bills detected (Plaid)             │
│ ✓ 12 maintenance tasks (auto-generated) │
│ ✓ Document vault ready                  │
│ ✓ Sarah assigned and ready to help      │
│                                         │
│ "Sarah is reviewing your home and will  │
│  reach out within 24 hours to confirm   │
│  everything looks right."               │
└─────────────────────────────────────────┘

USER THINKS: "Holy shit, this actually works."
```

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
