# Haven Payment System - Build Prompts

## Overview

These prompts build the complete payment orchestration system for Haven, enabling:
- Virtual card payments (Stripe Issuing)
- Digital & physical check payments (Checkbook.io)
- Automatic bill detection (Plaid)
- Payment scheduling and orchestration
- Alfred AI tool calling for bills
- Financial dashboard

---

## Quick Start

Run each phase in order in Claude Code:

```bash
# Phase 0: Configure API keys
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-0-configure-secrets.md

# Phase 1: Stripe Issuing (Virtual Cards)
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-1-stripe-issuing.md

# Phase 2: Bill Service & Payment Execution
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-2-bill-service.md

# Phase 3: Payment Orchestration Engine
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-3-orchestration-engine.md

# Phase 4: Alfred Tool Calling
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-4-alfred-tools.md

# Phase 5: Financial Dashboard
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-5-financial-dashboard.md

# Phase 6: Deploy & Test
Read and execute /Users/tomburke/Projects/Housing-Manager/prompts/PAYMENT-SYSTEM/PHASE-6-deploy-test.md
```

---

## API Keys Required

| Service | Keys | Status |
|---------|------|--------|
| Stripe | `sk_test_51SoFNh...` | ✅ Provided |
| Plaid | Client ID + Secret | ✅ Provided |
| Checkbook.io | API Key + Secret | ✅ Already in system |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     HAVEN PAYMENT SYSTEM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  USER LAYER                                                      │
│  ├── Alfred Chat (create bills, ask about payments)              │
│  ├── Financial Dashboard (see bills, history, approvals)         │
│  └── Push Notifications (approval requests, payment status)      │
│                                                                  │
│  SERVICE LAYER                                                   │
│  ├── BillService (CRUD for bills)                                │
│  ├── OrchestrationService (scheduling, preflight, routing)       │
│  ├── PaymentExecutionService (executes payments)                 │
│  └── DashboardService (aggregates data for UI)                   │
│                                                                  │
│  PAYMENT RAILS                                                   │
│  ├── Stripe Issuing (virtual cards)                              │
│  ├── Checkbook.io (digital + physical checks)                    │
│  └── Plaid (bank connection, transaction analysis)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Models Added

- `HouseholdCard` - Virtual card per household
- `Bill` - Recurring bills with payment config
- `BillPayment` - Individual payment records
- `PaymentApproval` - Approval workflow
- `ServiceRequest` - Haven team tasks

---

## Estimated Build Time

| Phase | Time |
|-------|------|
| Phase 0: Configure Secrets | 10 min |
| Phase 1: Stripe Issuing | 30 min |
| Phase 2: Bill Service | 45 min |
| Phase 3: Orchestration | 45 min |
| Phase 4: Alfred Tools | 30 min |
| Phase 5: Dashboard | 30 min |
| Phase 6: Deploy & Test | 30 min |
| **Total** | **~4 hours** |

---

## Test Mode

All services run in sandbox/test mode:
- Stripe: Test cards, simulated transactions
- Plaid: Sandbox bank (`user_good` / `pass_good`)
- Checkbook.io: Simulated check sending

No real money moves until you switch to production keys.
