# Handyman field-app gaps + UI quality + persistence findings

Aggregated findings from the overnight handyman E2E pass. Grouped by
category, then severity (critical → minor), then matrix section.

`verification` failures with `severity == critical` were auto-fixed
during the run and committed; they appear in
`HANDYMAN_OVERNIGHT_E2E_REPORT.md` instead of here.

This file is the sink for **gaps** (features absent and should exist),
**ui_quality_finding** (feature exists but design rule violated), and
**persistence_finding** (saves don't survive lifecycle). Plus any
`verification` failures triaged as architectural / non-mechanical.

---

## Gaps (features absent, deferred to product)

### Section 1 — Account creation + workspace setup

- **1.3** [`gap_found`] Workspace creation captures only company name + phone + optional website. Matrix expects logo upload + service area (ZIP codes / radius) + trade selection. iOS-as-thin-client design intent confirmed via on-screen copy "Use desktop for setup and quoting." **Suggested fix:** add a 4-step iOS workspace wizard mirroring desktop, OR surface a "Complete on desktop" card for owners with empty `service_zip_codes` / `categories`. **Estimated effort:** medium. **Tied to value prop:** new handyman signs up via iOS first → hits friction immediately when they need to fire up desktop just to set service area.

- **1.4** [`gap_found`] Workspace customization (brand color / hourly rate / business hours) entirely absent from iOS Settings — only "Open desktop command center" link + "Sign out". **Suggested fix:** Phase 1 surface read-only rows under WORKSPACE > Branding; Phase 2 add brand-color picker + hourly-rate field. Business-hours editor stays desktop. **Estimated effort:** small (read-only) → medium (edit). **Tied to value prop:** brand color propagates to quotes + customer-facing emails per matrix.

- **1.5** [`gap_found`] No invite-redemption affordance anywhere. Tested fresh signup with new email → landed straight on "Finish your field workspace" with no way to enter an invite code or accept an invitation. Blocks crew onboarding entirely. **Suggested fix:** "Have an invite code?" link beneath "Sign in to Chez Field" → opens InviteRedemptionSheet → server validates against `provider_workspace_members.invite_token`, links the auth user to the existing pending member row instead of creating a new workspace. Universal Link handler for `chez-field://join?token=...` should route to the same sheet. **Estimated effort:** medium. **Tied to value prop:** without invite acceptance, every new field user lands as workspace owner — there's no way for a crew member to join from iOS.

- **1.7** [`gap_found`] Multi-workspace switcher absent. Settings sheet hero shows the single workspace name with no chevron; top-of-app handyman header is non-interactive. **Suggested fix:** make the avatar + workspace name header tappable → opens WorkspaceSwitcherSheet listing all `provider_workspace_members` rows where `user_id=current_user.id` and `status='active'`. **Estimated effort:** medium. **Tied to value prop:** subcontractor handymen working across multiple companies have to sign-out / sign-in to switch — premium app should not require account juggling.

(populated by Wave 1a — 2026-05-06)

### Section 2 — CRM linking + quoting + scheduling

- **2.1** [`gap_found`] No "Add customer" affordance on Homes tab — only entry to add a customer is via Visits → New visit → Start pairing for a home, which is the brand-new-pair path (2.3), not the existing-account-search path. **Suggested fix:** add an "Add customer" button to Homes header that opens an address-search picker (Google Places + Chez household lookup); if existing → send link request via `provider_contractor_links` flow; if not → fall through to pair-a-home. **Estimated effort:** medium. (Wave 1b)

- **2.10** [`gap_found`] No revoke / "End relationship" affordance from handyman side. Tapping a customer home opens read-only detail. **Suggested fix:** "Manage relationship" row in customer-home detail under a kebab/cog. Defer the actual revoke action to desktop if needed but at minimum show relationship state pill. **Estimated effort:** small. (Wave 1b)

- **2.12-2.27** [`gap_found`] No quote builder in iOS (single-line / multi-line / draft / send / duplicate / sign). Onboarding card explicitly says "Use desktop for setup and quoting" — design intent. **Suggested fix:** mark 2.12-2.27 as Web in the matrix and add an iOS-only row covering "View quote sent from desktop in chat thread + customer accepts in-app", OR ship a minimal iOS quote viewer. (Wave 1b)

- **2.36-2.38** [`gap_found`] No week / month / list calendar views. Visits tab shows only a single "Confirmed route" card (in-progress visit) + non-tappable "Upcoming N scheduled" stat tile. **Suggested fix:** make the stat tile tappable → push a chronological list of upcoming visits sorted by `scheduled_date`. Defer week/month grids to v2. **Estimated effort:** small (list view) → medium (grid views). (Wave 1b)

- **Pending pair invitations visibility** [`gap_found`] After creating a pair invite (`status='pending_homeowner'`), the pair doesn't appear anywhere — handyman has no way to (a) see what invites are outstanding, (b) re-share the access code, (c) cancel the invite. **Suggested fix:** "Pending invites" strip above Homes search bar with re-share / cancel actions per row. **Estimated effort:** small. (Wave 1b)

### Section 5 — On-behalf-of assessment (the biggest gap surface)

- **5.1 / 5.21** [`gap_found`] No "Home assessment" visit type on the New Visit form (chips: Standard / Small repair / Install / Quote). Handyman cannot create an in-app assessment from scratch. **Suggested fix:** add `home_assessment` chip; on selection swap title for assessment-specific fields (concerns, present, access notes, preferred time). On save, dispatch `dispatch_home_assessment` action. **Estimated effort:** medium. (Wave 2a)

- **5.2** [`gap_found`] No assessment list / queue UI anywhere. `home_assessments` rows are invisible. **Suggested fix:** add a 4th nav tab "Assessments" OR a "Pending assessments" section on Visits tab. Wire `handyman-provider` `dashboard.assessments[]` and use existing dead-code `GuidedAssessmentView` (740 lines built, never instantiated). **Estimated effort:** large. **Tied to value prop:** on-behalf-of is the highest-leverage Field flow. (Wave 2a)

- **5.3** [`gap_found`] No assessment-detail surface. The visit-detail surface (HavenFieldVisitWorkspaceView) doesn't show customer phone, ATTOM facts, foundational answers, `homeowner_concerns`, or `homeowner_access_notes` — meaning gate codes and dog warnings never reach the field. **Suggested fix:** AssessmentDetailView component surfacing the access-notes prominently. **Estimated effort:** medium. **Tied to value prop:** without access notes the handyman walks into the home cold. (Wave 2a)

- **5.4** [`gap_found`] No tap-to-call. Phone number isn't even rendered anywhere in the field app. **Suggested fix:** add phone row via `tel://` URL after confirming `handyman-provider` returns customer phone in dashboard payload. **Estimated effort:** small. (Wave 2a)

- **5.5** [`gap_found`] Address renders as plain Text — tap does nothing. **Suggested fix:** wrap in Link to `https://maps.apple.com/?q=<encoded-address>` with a chevron / location-icon to communicate tappability. **Estimated effort:** small. (Wave 2a)

- **5.6** [`gap_found`] No "Start visit" check-in button. Edge function HAS `start_assessment_visit` action wired but iOS UI never invokes it. The "Execute the visit" tab is gated on check-in but check-in doesn't exist — entire tab inert. **Suggested fix:** add salmon "Start visit" CTA to visit-detail header → calls `start_assessment_visit` + grabs CLLocationManager fix. **Estimated effort:** medium. (Wave 2a)

- **5.7** [`gap_found`] Setup prompts are wired in handyman-provider (`setupPrompts: [...]`) and have a SwiftUI render branch but never surface in testing. Gated on `viewModel.payload?.session.seedPayload.firstVisit==true` AND requires portal session loaded. **Suggested fix:** for assessment visits, surface setup prompts unconditionally (the assessment is a first visit by definition). Audit why portal payload isn't loading. **Estimated effort:** small. (Wave 2a)

- **5.15 / 5.16** [`gap_found`] "Add system from label photo" launches camera directly with no library or manual fallback. If permission denied or camera fails, handyman is stuck. **Suggested fix:** Menu with 3 options: Take photo / Choose from library / Enter manually. Reuse existing add-system form for manual entry. **Estimated effort:** small. (Wave 2a)

- **5.19** [`gap_found`] Existing-system detail sheet is read-only — no edit affordance. Handyman cannot fill in missing manufacturer/model/serial on partially-detected systems. The only path is "Add new" → duplicate row. A4 edit-no-duplicate fails by impossibility. **CRITICAL.** **Suggested fix:** Add Edit affordance to system-detail sheet that PATCHes the row by id. Add "Replace existing" branch in identify-equipment edge function for capture-from-photo on existing rows. **Estimated effort:** medium. (Wave 2a)

- **5.20** [`gap_found`] No "Mark decommissioned" UI. The action exists (`decommissionHomeSystem` in SupabaseClient.swift, `decommission_system` in edge function, `home_systems.decommissioned_at` column) but no UI calls it. **Suggested fix:** Destructive-style "Mark decommissioned" button on system-detail sheet with optional reason TextField. Decommissioned rows render greyed in a separate section, not deleted. **Estimated effort:** small. (Wave 2a)

- **5.23** [`gap_found`] No "Mark for follow-up" affordance on systems. **Suggested fix:** add `followup_required` boolean + `followup_reason` text on assessment-system entry. When `submit_assessment_data` is called, create a `start_continuation_visit`-style flag for the next visit. **Estimated effort:** medium. (Wave 2a)

### Architectural

- **`GuidedAssessmentView.swift` is dead code (740 lines).** The whole guided assessment wizard was built but never wired into HavenFieldView — confirmed via grep. **Suggested fix:** decide whether to (a) wire it up by adding a navigation entry from a new Assessments tab, or (b) delete it entirely. Either way, the current state is ambiguous and bloats the binary. **Estimated effort:** small (delete) → medium (wire up). (Wave 2a)

### Section 5c — Vendor capture (Wave 2b)

- **5.25** [`gap_found`] No "Add vendor" affordance on Customer Home detail / Visit detail / Settings. Dead-code `VendorCaptureForm` exists in `GuidedAssessmentView.swift:489-531` but is unreachable. **Suggested fix:** ship a focused `VendorCaptureSheet` with company name + phone + category picker (using `SystemCategoryRegistry.canonical`) on Customer Home detail. **Estimated effort:** medium. **Tied to value prop:** Section 5c is the on-behalf-of vendor capture story — the "speed promise" hinges on this. (Wave 2b)

- **5.26 / 5.27** [`gap_found`] No camera-OCR for vendor business cards or stickers. **Suggested fix:** defer until 5.25 ships; then add cameraButton to AddVendorSheet routing through a new `extract-vendor-card` Edge Function (Claude Vision wrapper). **Estimated effort:** high. (Wave 2b)

- **5.28** [`gap_found`] No `confirmed: Bool` field on `HomeAssessmentContractorEntry` schema. **Suggested fix:** add `confirmed: Bool? + confirmed_at: timestamptz` to the captured-contractor JSON shape. (Wave 2b)

- **5.29** [`gap_found`] Surface doesn't exist; once 5.25 ships, no UI signaling for primary vs backup vendors per category. **Suggested fix:** optional `tier: 'primary' | 'backup' | nil` on captured-contractor. **Estimated effort:** small once 5.25 lands. (Wave 2b)

- **5.30** [`gap_found`] No notes / rating / reliability field. **Suggested fix:** add `notes: String?` to captured-contractor entry. (Wave 2b)

### Section 5d — Routine capture (Wave 2b)

- **5.31** [`gap_found`] No `+ Add routine` affordance anywhere in wired field app. Dead-code `RoutineCaptureForm` is missing cost + active months UI even though schema supports them. `HomeAssessmentRoutineEntry` is missing `cost / cost_unit / chez_owned / notes / start_date / time_of_day` fields. **Suggested fix:** build `RoutineCaptureSheet` modeled on homeowner-side `RoutineEditSheet.swift`. Reuse `ActiveMonthsPicker` component verbatim. **Estimated effort:** high. **Tied to value prop:** Section 5d is the heart of the recurring-services value prop. (Wave 2b)

- **5.32** [`gap_found`] No 'access_notes' field on routines schema (entry instructions like 'Key under the mat, code 1234'). **Suggested fix:** add `notes: String?` to `HomeAssessmentRoutineEntry`. (Wave 2b)

- **5.33-5.35** [`gap_found`] Same gap as 5.31 — surface doesn't exist. Each kind has specific UX expectations (pool: Apr-Oct default; snow: Dec-Apr default + per-storm cost-unit; pest: termite-bond notes). **Suggested fix:** kind-specific defaults in the future RoutineCaptureSheet. (Wave 2b)

- **5.36** [`gap_found`] Schema's `dayOfWeek: Int?` only supports a single day; trash + recycling on different days needs multi-day support OR multiple routine rows per cadence. **Suggested fix:** change `dayOfWeek: Int?` to `daysOfWeek: [Int]?` or document multi-row pattern. (Wave 2b)

- **5.37** [`gap_found`] Single cadence per row at schema level. **Suggested fix:** UX hint 'Two patterns? Add a second routine.' (acceptable given homeowner-side schema also single-cadence). (Wave 2b)

- **5.38** [`gap_found`] No `chez_owned: Bool` on `HomeAssessmentContractorEntry` or `HomeAssessmentRoutineEntry` — homeowner Phase 80.1 has the columns but the assessment ingest path doesn't propagate. **Suggested fix:** add `chezOwned: Bool? = false` to both entries; ingest reviewer calls `chez-concierge` `delegate_routine` / `delegate_contractor`. **Estimated effort:** medium. **Tied to value prop:** highest-value HNW concierge moment — handyman offers "want Chez to handle this for you?" live. (Wave 2b)

### Section 5 UI quality (Wave 2b)

- **B1** [`ui_quality_finding`] Salmon RadialGradient on top-right corner of brand hero card bleeds visually toward the iOS status bar. **Suggested fix:** audit hero card `.background` ZStack — likely needs `.ignoresSafeArea(.container, edges: .top)` removed or a navy-anchored extension above. **Severity:** minor. (Wave 2b)

- **B1** [`ui_quality_finding`] "Cancelled" status pill renders salmon — destructive/negative status should be critical-red or muted gray. **Suggested fix:** swap salmon for `HavenColors.critical.opacity(0.1)` background + `HavenColors.critical` text. **Severity:** minor. (Wave 2b)

### Section 5e — Observations / safety / code / recommendations (Wave 2c)

- **5.39 / 5.42** [`gap_found`] No "+ Add observation" / "+ Add recommendation" affordance on visit detail. Server-side `add_recommended_task` action exists in handyman-provider edge function; iOS doesn't call it. Recommendations card on the visit detail is read-only (renders pre-seeded items + toggles `createFollowUp`). **Suggested fix:** wire an inline Add button → AddRecommendationSheet (title + detail + category + priority + optional photo) → call `add_recommended_task`. Reuse the existing syncPortal pattern. **Estimated effort:** medium. **Tied to value prop:** without proactive observation capture, the visit detail is a worklist mark-off, not an inventory experience. (Wave 2c)

- **5.40 / 5.41** [`gap_found`] No type discriminator on observation/recommendation entries — safety_concern / code_violation should fire admin push immediately and render with red urgency framing. Today everything is bucketed by regex on title which misses obvious safety/code language. **Suggested fix:** add `kind: observation | safety_concern | code_violation | recommendation` to entry; gate priority badge color; server fires admin push when kind requires immediate action. (Wave 2c)

- **5.43** [`gap_found`] No photo / voice memo / tags on recommendations. **Suggested fix:** add `photo_paths: [String]`, `voice_memo_path: String?`, `tags: [String]` to entry. Route uploads through `upload_assessment_document` (already in edge function). **Estimated effort:** medium. (Wave 2c)

### Section 5f — Submit + handoff to Chez central (Wave 2c)

- **5.44** [`gap_found`] Field app's "Complete visit" writes to `handyman_request_visits` JSONB only. Server-side `submit_assessment_data` action — which fans out captured systems/contractors/routines to homeowner tables AND fires "your home is set up" push — is never invoked. **Suggested fix:** replace completeVisit's portal sync with two-step: call `submit_assessment_data` first → write captured_* JSONB to homeowner tables + fire push, then update visit report. The dead-code `GuidedAssessmentViewModel.swift` already implements `callField(action: 'submit_assessment_data', ...)` — use as starting reference. **Estimated effort:** large. **CRITICAL.** Without this, the entire on-behalf-of value prop is gone. (Wave 2c)

- **5.47** [`gap_found`] No inbound notification handling for "homeowner has reviewed your assessment". Push registration fires but no `assessment_reviewed` route. **Suggested fix:** server fires push with `type: 'assessment_reviewed'` when chez_request flips state; iOS handler routes to visit detail. (Wave 2c)

- **5.48 / 5.49** [`gap_found`] No audit trail / change history for handyman ↔ homeowner edits. **Suggested fix:** server-side `assessment_audit_log` table + RLS; iOS renders an "Activity" tab. **Estimated effort:** large. Defer to a future phase. (Wave 2c)

- **5.50 / 5.51 (multi-day continuation)** [`gap_found`] Server has `start_continuation_visit` action + `home_assessments.session_count` + `assessment_round` columns ready. iOS has zero UI for multi-visit continuation. The local UserDefaults draft cache works for kill→relaunch within the same visit, but no "continue next visit" button. **Suggested fix:** add "Save & continue next visit" button that calls `start_continuation_visit`; on next visit, iOS loads from in-progress assessment and resumes. **Estimated effort:** medium. **Tied to value prop:** CRITICAL for HNW estates — 10,000sqft homes need 2-3 visits to fully capture. (Wave 2c)

### Section 5g — Edge cases (Wave 2c)

- **5.52** [`gap_found`] No `homeowner_present` toggle in iOS UI. Column exists in `home_assessments`. **Suggested fix:** add `HomeownerPresentToggle` to visit detail check-in section. Wire to `update_assessment_progress`. **Estimated effort:** small. (Wave 2c)

- **5.53** [`gap_found`] No camera-permission-denied handler. **Suggested fix:** wrap PhotosPicker / camera with `AVCaptureDevice.authorizationStatus(for: .video)` check; surface `CameraPermissionRequiredSheet` with "Open Settings" + "Choose from library" + "Skip" options. **Severity:** small. (Wave 2c)

- **5.54** [`gap_found`] PARTIAL — local draft cache via `HavenFieldCache.saveDraft` works; sync errors set `syncMessage='Saved offline'`. Missing: visible offline banner, automatic retry on reconnect (NWPathMonitor), pending-write counter. **Suggested fix:** add `NWPathMonitor` observer + `OfflineBanner` overlay + auto-retry. **Estimated effort:** medium. **Tied to value prop:** Westchester estates have notoriously bad cell coverage; mechanical-rooms always do. (Wave 2c)

- **5.56** [`gap_found`] No retry queue for failed photo uploads. **Suggested fix:** persist `PendingPhotoUpload` model to UserDefaults; render queue indicator; retry on reconnect. **Estimated effort:** medium. (Wave 2c)

### Section 6 — Review homes (Wave 3a)

#### Section 6a — Multi-household aggregate views

- **6.5** [`gap_found`] No sort affordance on Homes tab. **Suggested fix:** add sort menu to toolbar (next visit / outstanding $ / lifetime value). **Estimated effort:** small. (Wave 3a)

- **6.6 / 6.7** [`gap_found`] Visits tab has REQUESTS / UPCOMING split but no day-bounded filter (Today / This week / This month). **Suggested fix:** replace binary REQUESTS/UPCOMING with 4-state segmented filter. **Estimated effort:** medium. (Wave 3a)

- **6.8** [`gap_found`] No "Outstanding" view aggregating unpaid invoices + expired quotes + open punch items + un-acknowledged messages. Only a numeric count surfaces. **Suggested fix:** new tab section or filter. **Estimated effort:** medium. (Wave 3a)

- **6.9 / 6.10** [`gap_found`] No map view + no route optimization. Visits tab UPCOMING shows 'Confirmed route' label but is a flat list of 1 visit. **Suggested fix:** Phase 1 — map button drops pins for each visit's address in MapKit. Phase 2 — Apple Maps Directions API for optimized stop_order. **Estimated effort:** large. **Tied to value prop:** Housecall Pro / ServiceTitan bake this in; 10% drive-time savings is real money for a Westchester handyman. (Wave 3a)

#### Section 6b — Per-household detail

- **6.11** [`gap_found`] Customer detail header missing photo of home, contact (phone, email), tap-to-call / tap-to-email. **Suggested fix:** augment header with optional `home_photo_url` (lazy AsyncImage) + CONTACT row with `tel:` URL scheme. **Estimated effort:** medium. (Wave 3a)

- **6.13** [`gap_found`] No routines section on home detail. Existing `routines` table queryable. **Suggested fix:** add Routines sub-tab listing recurring services with cadence + next due. **Estimated effort:** small. (Wave 3a)

- **6.14** [`gap_found`] No "All vendors the homeowner uses" surface (mirror of homeowner-side `contractors` list). **Suggested fix:** add Vendors sub-tab. **Estimated effort:** small. (Wave 3a)

- **6.18** [`gap_found`] Outstanding payments are just a numeric count, no breakdown. **Suggested fix:** tap-through to per-quote list with status pills + amounts. **Estimated effort:** small. (Wave 3a)

- **6.19** [`gap_found`] No notes / tags per household ('Has dog — call ahead', 'Side gate code 1234'). **Suggested fix:** add `households.handyman_notes` JSONB or new `provider_household_notes` table. **Estimated effort:** medium. (Wave 3a)

- **6.20** [`gap_found`] No year-over-year revenue per customer (lifetime value pattern). **Suggested fix:** computable from existing `provider_visit_assignments` + invoices. **Estimated effort:** small. (Wave 3a)

- **6.22** [`gap_found`] No read-only display of homeowner's `households.chez_profile` JSONB (about_us, communication, vendor_preferences, logistics, spending_tiers). **Suggested fix:** highest-value lowest-effort gap; existing column, just needs SwiftUI display. **Estimated effort:** small. **Tied to value prop:** saves the handyman from re-asking 'do you prefer email or text?', 'is there anything I should know about pets?'. (Wave 3a)

- **6.16** [`ui_quality_finding`] Visit row in customer-detail Recent section LOOKS tappable but isn't — same data row on Visits tab IS tappable. Inconsistent navigation. **Suggested fix:** wrap in NavigationLink to the same visit-detail destination. **Severity:** moderate. (Wave 3a)

#### Section 6c — Gap-filling view (Tom's high-value callout)

- **6.23** [`gap_found`] **HIGH-VALUE CALLOUT.** Per Tom's brief: "the handyman should be able to see from their app all the systems that home has setup currently, but also all the systems that the handyman could setup for them immediately ie. This home has a furnace as a system, but no model/brand/etc. the handyman should be able to input that or snap a picture to identify the model." TODAY: Customer Home detail / Systems sub-tab is read-only with empty state — no "Add system" button, no "Capture details" affordance. The system-capture flow ('Add system from label photo') exists ONLY on Visit detail / Systems sub-tab, gated behind an active visit. **Suggested fix:** lift the existing CaptureCard to a shared component, render it on home-detail Systems sub-tab when systems list is empty OR when any system has missing brand/model/serial. Add a per-row 'Capture details' button on partial-detail rows. **Estimated effort:** medium. (Wave 3a)

- **6.24 / 6.25 / 6.27** [`gap_found`] No Suggested systems / Suggested vendors / Missing routines proactive prompts on customer detail. The homeowner-side has VendorCoverageSheet; the field app should mirror this. **Suggested fix:** mirror VendorCoverageSheet logic on field side. **Estimated effort:** large. (Wave 3a)

- **6.26** [`gap_found`] No "Stale data" view (last_service_date > N years ago indicator on the systems list). **Suggested fix:** color-code system rows by `last_service_date` recency, surface "5 systems overdue for service" banner. **Estimated effort:** small. (Wave 3a)

- **6.28** [`gap_found`] No "Capture all" sweep mode (camera-first walkthrough). **Suggested fix:** new flow that auto-advances through every system + vendor + routine in one optimized capture flow. **Estimated effort:** large. (Wave 3a)

#### Section 6 UI quality (Wave 3a)

- **B1** [`ui_quality_finding`] '1 upcoming' status pill on Homes list cards uses salmon background + salmon icon + salmon text. Decorative status, not a CTA. **Suggested fix:** swap to navy tint matching the chat counter pill. **Severity:** minor. (Wave 3a)

- **B9** [`ui_quality_finding`] Search empty state echoes 500-char query verbatim, dominating screen. **Suggested fix:** truncate to first 30 chars + ellipsis. **Severity:** minor. (Wave 3a)

### Architectural — parallel tables (Wave 2c)

- **`home_assessments` vs `handyman_request_visits` are orphaned from each other.** Server has full assessment-lifecycle actions (`start_assessment_visit`, `update_assessment_progress`, `submit_assessment_data`, `add_recommended_task`, `mark_task_fixed_during_visit`, `start_continuation_visit`, `decommission_system`) wired into `home_assessments`. iOS Field app uses an entirely separate `handyman_request_visits` JSONB via `syncPortal`. The dead-code `GuidedAssessmentView.swift` is the only place that calls the home_assessments actions. **Suggested fix:** pick the canonical source of truth. Either (a) wire iOS Field to use home_assessments via the existing edge function actions (large effort), or (b) explicitly merge handyman_request_visits → home_assessments at submit time (medium effort), or (c) delete home_assessments + actions and consolidate on handyman_request_visits (small effort but loses queryability). The current "two parallel tables" situation guarantees data drift between dispatch and assessment. **Severity:** persistence_finding — major (architectural), needs Tom's design call. (Wave 2c)

## UI quality findings

### Severity: major

(populated as Wave 1+ runs land)

### Severity: moderate

(populated as Wave 1+ runs land)

### Severity: minor

- **1.1, 1.3, 1.11** [B1 salmon discipline] Salmon used as small body text on tertiary navigation links: "Create it here" / "Sign in instead" / "Cancel" link in Reset Password sheet. Per CLAUDE.md "Salmon is for actions only — never for small body text (only 3:1 contrast on white)." **Suggested fix:** demote to `HavenColors.navy800` underlined; keep salmon for primary CTAs only. Likely affects `HavenFieldApp.swift` AND `LoginView.swift`. (Wave 1a)

- **1.1, 1.3** [C1 stale validation] Inline validation messages don't clear after the user fills the field. Stale red message keeps rendering. **Suggested fix:** attach `.onChange(of: field)` that clears validation error when field becomes valid. **Note:** partially addressed in Wave 1a fix commit for the reset-password sheet specifically; the broader sign-in / sign-up forms still have this. (Wave 1a)

- **1.9** [A7 destructive action confirmation] Sign out fires immediately with no confirmation. **Suggested fix:** wrap in `.alert("Sign out?", message: "You'll need your password to sign in again.")` with Cancel + Sign out destructive actions. (Wave 1a)

- **1.1** [C1 validation completeness] Empty Create Account submit shows only "Please enter your email." — first/last/password/confirm errors are masked until email is filled. **Suggested fix:** refactor validation to show per-field errors below each input OR collect all empty fields into a single message. (Wave 1a)

---

## Persistence findings

### Severity: critical

(none yet)

### Severity: major

- **1.11** [A3 password reset never reaches Supabase Auth] Tested with `e2e-handyman-w1-owner-1.1-1778103827@havenhome.test` — `auth.users.recovery_sent_at` stays null after Send Reset Link tap. **Root cause:** Supabase auth rejects `.havenhome.test` emails as `email_address_invalid` (test-only artifact, not a real-user bug). **Status:** addressed in Wave 1a commit `eeecefde` — `friendlyError` now maps `email_address_invalid` to a clear user-facing message. **Note:** real `.com` emails work; this finding is informational. (Wave 1a)

- **1.11** [B9 error layer] Reset password sheet rendered errors on the parent SignInView BEHIND the sheet, not inside the sheet. User dismissed the sheet to see the error and lost their input. **FIXED** in Wave 1a commit `eeecefde` — split `resetPasswordError` from `errorMessage`, render inside sheet body, clear on field change. (Wave 1a)
