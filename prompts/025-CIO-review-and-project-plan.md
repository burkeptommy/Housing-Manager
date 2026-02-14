# Haven Mobile App - CIO Code Review & Project Plan

**Date:** February 13, 2026
**Reviewer:** CIO (Claude Opus)
**Current Build:** v1.0.0, Build 63 (iOS)
**Target:** Production-ready App Store release by end of February 2026
**Scope:** Mobile app only (no web launch)

---

## EXECUTIVE SUMMARY

Haven is a comprehensive home management platform built as an Expo/React Native mobile app backed by a NestJS API with PostgreSQL. The app has gone through 24+ development iterations and is at approximately **70-75% production readiness** for a public App Store launch.

The core architecture is solid. The monorepo structure (mobile, API, web, shared packages) is well-organized. The key differentiators -- Alfred AI assistant, email forwarding/case management, Monarch-style budgeting, and home system management -- are all structurally in place but have critical gaps that would cause crashes, broken workflows, or poor UX if shipped as-is.

**Bottom line:** The app needs 2-3 focused engineering sprints to be production-ready. The issues are fixable but non-trivial.

---

## CURRENT STATE BY FEATURE AREA

### 1. ALFRED - Personal Assistant (Score: 7/10)

**What's deployed and working:**
- Chat interface with typing indicators, quick actions, and suggestion buttons
- Claude API integration with 15 tools (bill management, home systems, vendors, maintenance)
- Comprehensive household context loading (270+ lines of data injected into prompts)
- "Batman's Alfred" personality model -- distinguished, proactive, helpful
- `research_and_add_system` tool that auto-creates full maintenance programs
- Proactive question system for data gap detection (water source, sewer type, heating fuel, etc.)

**What's broken or incomplete:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P0 - CRASH** | `getConversationHistory()` returns empty `[]` -- no persistence | Users lose all chat history on app restart |
| **P0 - CRASH** | Tool execution silently returns `null` on failure | User gets no feedback when actions fail |
| **P1 - BROKEN** | Email attachment upload: `TODO: Upload to GCS and store URL` | Forwarded email attachments are logged but not stored |
| **P1 - BROKEN** | Service request creation only logs, doesn't create DB record | "Request service" action is a no-op |
| **P2 - UX** | No streaming responses -- user waits for full Claude response | Long wait times with no progress indication |
| **P2 - UX** | No rate limiting on Alfred API | Potential for abuse and cost overruns |
| **P2 - UX** | Vendor messaging navigation goes to wrong screen with wrong header styling | UX inconsistency in Alfred tab |

**Key files:**
- `apps/mobile/src/screens/AlfredManagerScreen.tsx` (mobile chat UI)
- `apps/api/src/alfred/alfred.service.ts` (core Alfred logic, ~1100 lines)
- `apps/api/src/alfred/tools/bill-tools.ts` (bill management tools)
- `apps/api/src/alfred-email/alfred-email.service.ts` (email forwarding)

### 2. EMAIL FORWARDING & CASES (Score: 8/10)

**What's deployed and working:**
- SendGrid inbound webhook handling
- 3-tier sender authorization (AuthorizedEmail list, household members, family members)
- Intent-first "always ask" flow -- never auto-executes, always awaits user decision
- 45+ email intent types (camp registration, utility bills, vendor quotes, appointments, etc.)
- Case lifecycle (PROCESSING -> AWAITING_INPUT -> COMPLETED -> ARCHIVED)
- 6 test email scenarios for QA
- Action buttons: Add to Calendar, Track as Bill, Save Vendor, Create Reminder, etc.

**What's broken or incomplete:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P1** | Attachment upload not implemented (GCS TODO) | Email attachments lost |
| **P1** | Calendar actions create local FamilyEvent only -- no Google Calendar sync | Events don't appear in user's actual calendar |
| **P2** | No recurring event support | Email-detected recurring events are one-time only |
| **P2** | No conflict detection for calendar events | Can create overlapping events silently |
| **P3** | Test endpoint accessible in staging (guarded in prod) | Low risk but should verify |

### 3. BUDGETING & FORECASTING (Score: 6/10)

**What's deployed and working:**
- Monarch-style budget categories and structure
- Monthly budget overview with category breakdown
- Budget API service (`budgeting.service.ts`) with category management
- Plaid integration for bank account linking
- Transaction analyzer with 60+ merchant pattern matches
- Bill detection from Plaid transactions

**What's broken or incomplete:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P0 - CRASH** | Forecasts screen crashes when no bank connected (reported in prompt 023, fix applied but needs verification) | App crash on navigation |
| **P1** | Web billing page still uses hardcoded demo data (not relevant for mobile but shows data layer gaps) | N/A for mobile launch |
| **P1** | Plaid bill categorization has TODOs: `LANDSCAPING` and `HOUSEKEEPING` fall back to `OTHER_BILL` | Miscategorized transactions |
| **P2** | No manual transaction entry on mobile | Users can't track cash/check payments |
| **P2** | Budget insights/comparisons rely on having sufficient transaction history | Empty/unhelpful for new users |
| **P2** | "One Bill" references may still exist in UI copy | Confusing for users given pivot to budgeting |

**Key files:**
- `apps/mobile/app/(tabs)/money/` (Money tab screens)
- `apps/mobile/app/(tabs)/money/forecast.tsx` (forecasting screen)
- `apps/api/src/budgeting/budgeting.service.ts` (budget backend)
- `apps/api/src/plaid/transaction-analyzer.service.ts` (transaction categorization)
- `apps/api/src/plaid/plaid.service.ts` (Plaid integration)

### 4. VENDOR CRM (Score: 7.5/10)

**What's deployed and working:**
- Vendor list and detail screens with comprehensive data model
- CRM fields: rating, tags, source, referral tracking, last contact date
- HouseholdVendor relationship model (per-household vendor data)
- VendorActivity log and VendorMessage models
- Vendor type-specific data (electric rates, internet speeds, landscaping schedules, etc.)
- Bill accounts linked to vendors
- Service history tracking
- Vendor portal API (job board, schedule, messaging)

**What's broken or incomplete:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P1** | Vendor detail enhancements (contracts, type-specific data) defined in prompts but implementation status unclear | Rich vendor data may not render |
| **P2** | No vendor search/discovery in mobile (exists on web with Mapbox) | Users can't find new vendors |
| **P2** | Vendor messaging navigation issue (goes to wrong screen) | UX broken for vendor communication |
| **P3** | No vendor test coverage (0 test files found) | Risk of regressions |

**Key files:**
- `apps/mobile/app/(tabs)/manager/vendors/[id].tsx` (vendor detail)
- `apps/api/src/household-vendors/` (vendor-household relationships)
- `apps/api/src/vendor-portal/vendor-portal.service.ts` (vendor portal)

### 5. HOME SYSTEM MANAGEMENT & MAINTENANCE (Score: 8/10)

**What's deployed and working:**
- Home systems tracking with full model (HVAC, plumbing, electrical, roofing, appliances, etc.)
- Maintenance task management with status tracking (upcoming, due, overdue, completed)
- Auto-generated maintenance tasks from ATTOM property data
- Service request system with CRUD, permissions, and role-based access
- Checklist system for maintenance tasks with step-by-step tracking
- AI-powered `research_and_add_system` tool via Alfred that creates full maintenance programs
- Home Health Score calculation
- Property zones and systems display
- Maintenance tab with filtering (all, upcoming, overdue)
- Pull-to-refresh, empty states, error handling

**What's broken or incomplete:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P2** | Systems derived from tasks in mobile UI (fragile category mapping) | Systems display depends on maintenance tasks existing |
| **P2** | No smart home integrations (mentioned in data model but not implemented) | Feature gap |
| **P2** | Home manual/walkthrough removed in recent commit (broken walkthrough components) | Lost onboarding feature |
| **P3** | Document vault present but document-to-system linking unclear | Hard to find system-related docs |

### 6. OVERALL MOBILE APP QUALITY (Score: 6.5/10)

**What's working well:**
- Authentication: Apple Sign-In, Google Sign-In, Email/Password, biometric (Face ID)
- Onboarding: Address autocomplete with Google Places, ATTOM property data lookup
- Navigation: Expo Router with grouped tabs, clean screen structure
- Error boundaries and fallback patterns throughout
- Safe context imports with try/catch fallbacks (won't crash if module missing)
- All promise chains have `.catch()` handlers
- iOS permissions properly declared (camera, photos, Face ID, location, calendar)
- Deep linking configured (`applinks:havenhome.dev`)
- RevenueCat integration for subscriptions with safe fallbacks
- Push notifications setup via expo-notifications
- Profile photo editor with upload/remove functionality

**Production readiness issues:**

| Priority | Issue | Impact |
|----------|-------|--------|
| **P0** | Several screens may crash on empty data (forecasts confirmed, others possible) | App Store rejection risk |
| **P1** | Hardcoded demo data in web billing page (not mobile, but API may serve it) | Users see fake data |
| **P1** | `getConversationHistory` returns `[]` -- chat not persisted | Core feature broken |
| **P1** | No offline handling beyond OfflineBanner component | App unusable without connectivity |
| **P2** | Calendar settings screen -- Google Calendar OAuth flow needs end-to-end testing | Calendar sync may fail silently |
| **P2** | Plaid is in sandbox mode (`PLAID_ENV` should be `production` for launch) | Bank connections won't work with real banks |
| **P2** | App version 1.0.0 but package.json says 0.1.0 -- version mismatch | Confusing but not blocking |
| **P2** | Settings screen has `require()` with try/catch -- not standard practice | Works but fragile |
| **P3** | No automated test suite for mobile app (0 mobile test files found) | Regression risk |
| **P3** | Multiple seed files (seed-bob-family, seed-burke, seed-morrison-demo) -- demo data cleanup needed | Won't affect production users |

---

## CRITICAL PATH: WHAT MUST BE FIXED BEFORE LAUNCH

### Tier 1: Launch Blockers (Must fix -- app will crash or core features broken)

1. **ErrorBoundary not applied** -- Component exists at `src/components/ErrorBoundary.tsx` but is never wrapped in `_layout.tsx`. Any unhandled React error crashes the app instead of showing graceful error UI. One-line fix.
2. **Conversation history persistence** -- Alfred chat history is lost on every app restart. Implement DB storage and retrieval.
3. **Forecasts empty state** -- Verify the crash fix from prompt 023 is working. Test with no bank connected.
4. **Tool execution error handling** -- Silent `null` returns when Alfred tools fail. User needs feedback.
5. **Email attachment upload** -- Complete the GCS upload TODO. Forwarded attachments are currently lost.
6. **Service request creation** -- `request_service` bill tool only logs, never creates a record.
7. **End-to-end testing on device** -- Full flow: signup -> onboarding -> dashboard -> connect bank -> chat with Alfred -> forward email -> action execution.

### Tier 2: Launch Degraders (Should fix -- features don't work as expected)

7. **Home Health Score status filter bug** -- `home-health.service.ts` checks for `'OVERDUE'`, `'UPCOMING'`, `'DUE_SOON'` but actual enum values are `'PENDING'`, `'SCHEDULED'`, `'IN_PROGRESS'`, `'COMPLETED'`, `'SKIPPED'`. Health score always shows 0 overdue/upcoming tasks.
8. **Calendar sync to Google Calendar** -- Email-detected events only create local records, not actual Google Calendar events.
9. **Plaid environment** -- Switch from sandbox to production for real bank connections.
10. **Vendor messaging navigation** -- Fix the wrong-screen navigation and header styling.
11. **Vendor search endpoint missing** -- Mobile "Find Vendors" tab calls `/vendors/search` which doesn't exist.
12. **Plaid bill categorization** -- Add LANDSCAPING and HOUSEKEEPING categories instead of OTHER_BILL fallback.
13. **"One Bill" to "Budgeting" copy audit** -- Ensure no old "one bill" language remains in the app.
14. **Empty state audit** -- Systematically test every screen with no data. Verify no crashes.

### Tier 3: Polish (Nice to have -- improves UX significantly)

13. **Alfred response streaming** -- Show incremental responses instead of waiting for full Claude response.
14. **Rate limiting** -- Protect Alfred API from abuse.
15. **Offline handling** -- Graceful degradation when no network.
16. **Manual transaction entry** -- Allow users to add non-Plaid transactions.
17. **SendGrid email domain verification** -- Required for production email forwarding.

---

## PROJECT PLAN: FEBRUARY 2026

### WEEK 1: Feb 14-16 (Critical Bug Fixes)

**Goal:** Fix all launch blockers (Tier 1)

| Task | Owner | Files | Est. Effort |
|------|-------|-------|-------------|
| Implement Alfred conversation persistence (DB storage/retrieval) | Engineer | `alfred.service.ts`, new Prisma model, `AlfredManagerScreen.tsx` | Medium |
| Verify forecasts crash fix, add defensive null checks across money screens | Engineer | `forecast.tsx`, money tab screens | Small |
| Add user-facing error messages for failed Alfred tool execution | Engineer | `alfred.service.ts` (line 1043) | Small |
| Implement GCS file upload for email attachments | Engineer | `alfred-email.service.ts` (line 148), `storage/` service | Medium |
| Implement actual service request creation in bill tools | Engineer | `bill-tools.ts` (line 433) | Small |

**Deliverable:** Build 64 with all P0 fixes, internal testing on device.

### WEEK 2: Feb 17-21 (Integration Fixes & Empty State Audit)

**Goal:** Fix all launch degraders (Tier 2)

| Task | Owner | Files | Est. Effort |
|------|-------|-------|-------------|
| Calendar sync: connect FamilyEvent creation to Google Calendar API | Engineer | `alfred-email.service.ts`, `calendars/` service | Medium |
| Switch Plaid to production environment | CEO/Engineer | `.env`, Cloud Run env vars | Small (config) |
| Fix vendor messaging navigation within Alfred tab | Engineer | Alfred tab navigation, vendor message screen | Small |
| Add LANDSCAPING and HOUSEKEEPING bill categories | Engineer | `plaid.service.ts` (line 492-496) | Small |
| Audit all UI copy for "one bill" references, replace with "budgeting" | Engineer | Mobile app screens | Small |
| Empty state audit: test every mobile screen with no data, fix crashes | Engineer | All mobile screens | Medium |
| Verify SendGrid domain and inbound email webhook in production | CEO/Engineer | SendGrid dashboard, DNS | Small (config) |

**Deliverable:** Build 65 with all integration fixes, TestFlight beta to 5 users.

### WEEK 3: Feb 22-26 (Polish, Testing & App Store Submission)

**Goal:** Polish, performance, App Store submission

| Task | Owner | Files | Est. Effort |
|------|-------|-------|-------------|
| Add Alfred response streaming (SSE or chunked responses) | Engineer | `alfred.service.ts`, `AlfredManagerScreen.tsx` | Medium |
| Add rate limiting to Alfred chat endpoint | Engineer | `alfred.controller.ts` | Small |
| Performance audit: app launch time, screen load times, memory | Engineer | Various | Medium |
| Full regression test on physical device (all navigation paths) | CEO + Engineer | N/A | Manual testing |
| App Store metadata: screenshots, description, keywords, privacy policy | CEO | App Store Connect | Medium |
| Final build + App Store submission | Engineer | `app.json` (bump version), EAS build | Small |

**Deliverable:** App Store submission by Feb 26.

### WEEK 4: Feb 27-28 (App Store Review & Hotfixes)

**Goal:** Respond to App Store review, fix any rejection issues

| Task | Owner | Files | Est. Effort |
|------|-------|-------|-------------|
| Monitor App Store review status | CEO | App Store Connect | Monitoring |
| Fix any App Store rejection issues (if any) | Engineer | Varies | Unknown |
| Prepare production API environment | Engineer | Cloud Run, env vars | Small |
| Final production verification | CEO + Engineer | Beta verification checklist | Manual testing |

**Deliverable:** App live in App Store.

---

## API ENVIRONMENT CHECKLIST (Pre-Launch)

All these must be configured in Cloud Run production:

- [ ] `DATABASE_URL` -- Production PostgreSQL
- [ ] `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
- [ ] `ANTHROPIC_API_KEY` -- For Alfred AI
- [ ] `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV=production` -- **Switch from sandbox**
- [ ] `SENDGRID_API_KEY` -- For email
- [ ] `ALFRED_EMAIL_DOMAIN` -- Email forwarding domain
- [ ] `GOOGLE_MAPS_API_KEY` -- Address autocomplete
- [ ] `ATTOM_API_KEY` -- Property data
- [ ] `CALENDAR_ENCRYPTION_KEY` -- Google Calendar token encryption
- [ ] `GCS_BUCKET` -- Google Cloud Storage for file uploads

---

## RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| App Store rejection (incomplete features) | Medium | High | Ensure all screens work end-to-end, remove any placeholder/test UI |
| Plaid production approval delayed | Medium | High | Start Plaid production application now, have graceful fallback if not approved |
| Alfred API costs spike | Low | Medium | Rate limiting + usage monitoring |
| SendGrid email domain not verified | Medium | Medium | Start verification process immediately |
| Google Calendar OAuth rejection | Low | Medium | Test OAuth flow thoroughly, ensure privacy policy covers calendar access |
| Performance issues on older devices | Low | Medium | Test on iPhone 12/13 as baseline |

---

## RECOMMENDATION

The app has a strong foundation. The architecture is sound, the data models are comprehensive, and the core experiences (Alfred chat, email forwarding, budgeting, home systems) are structurally complete. The gaps are execution gaps, not design gaps.

**My recommendation as CIO:** Focus the engineering effort on the 6 Tier 1 items first. Those are the difference between "crashes on use" and "works end-to-end." Tier 2 items are the difference between "works but rough" and "feels polished." Tier 3 can ship in a v1.1 update.

The end-of-February timeline is aggressive but achievable if engineering stays focused on the critical path and doesn't get pulled into new features. The biggest risk is scope creep -- the temptation to add "just one more thing" instead of fixing what's there.

**Key decision for CEO:** Do we ship with Plaid in sandbox mode (demo bank connections only) or wait for production approval? If Plaid production approval could delay launch, consider shipping without real bank connections and adding them in a v1.1 update. The budgeting, Alfred, and home system features all work independently of Plaid.
