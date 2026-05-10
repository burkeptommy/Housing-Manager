# Homeowner End-to-End Test Script

Last audited: 2026-05-10

This is the canonical homeowner E2E script for Chez. It is intentionally written as a product contract, not just as a reflection of what the current code happens to support. A pass means the homeowner can onboard, choose the right setup path, populate a complete home profile, hand work to Chez, and see Chez corporate/admin operations pick it up and move it forward.

Do not mark a scenario as passed because the code has no UI for it. If the homeowner product requires the behavior, run the step and record the failure or gap.

## Source Paths Audited

- Homeowner app tabs: `Haven/App/MainTabView.swift`
- New homeowner onboarding: `Haven/Core/Auth/Views/Onboarding/OnboardingView.swift`
- Foundational questions: `Haven/Features/Onboarding/Assessment/Views/FoundationalQuestionsForm.swift`
- Mode fork and booking: `Haven/Features/Onboarding/Assessment/Views/OnboardingModeForkView.swift`, `Haven/Features/Onboarding/Assessment/Views/BookHandymanWindowSheet.swift`
- Self quiz and mid-quiz handoff: `Haven/Features/Onboarding/HouseQuiz/HouseQuizView.swift`, `Haven/Features/Onboarding/HouseQuiz/HouseQuizViewModel.swift`
- Assessment pending/review UI: `Haven/Features/Dashboard/Components/HomeAssessmentPendingCard.swift`, `Haven/Features/Onboarding/AssessmentReview/AssessmentReviewView.swift`
- Chez ownership UI: `Haven/Features/ChezRequests/Views/ChezOwnershipView.swift`, `Haven/Features/ChezRequests/Components/ChezOwnsToggle.swift`
- Chez homeowner actions: `Haven/Features/ChezRequests/Services/ChezConciergeService.swift`
- Assessment lifecycle Edge Function: `supabase/functions/handyman-provider/index.ts`
- Chez admin/orchestration Edge Function: `supabase/functions/chez-concierge/index.ts`
- Chez admin portal: `website/admin.html`, `website/admin.js`
- Contractor operations portal: `website/operations/src/App.tsx`
- Existing E2E runners: `Tests/e2e/run.mjs`, `Tests/e2e/run-handyman.mjs`
- Existing matrices and known field gaps: `Tests/e2e/TEST_MATRIX.md`, `Tests/e2e/HANDYMAN_TEST_MATRIX.md`, `Tests/e2e/HANDYMAN_GAPS.md`

## Test Principles

1. Test the full homeowner promise, not only happy paths.
2. Every Chez-managed toggle must prove both sides: the homeowner sees the item as delegated, and Chez admin gets enough context to act.
3. Assessment-assisted onboarding must prove the handoff from homeowner request to Chez admin to contractor/handyman capture to homeowner review to canonical household data.
4. If the real Field app cannot execute a visit yet, simulate the visit through the database/Edge Function layer and mark the Field app gap separately.
5. For every failure, capture: account, household id, property id, screen, expected behavior, actual behavior, DB rows inspected, logs, and severity.

## Required Environments

Use a disposable test Supabase project or a seeded staging database. Do not run destructive cleanup scripts against production.

Required surfaces:

- Homeowner iOS app signed into the staging Supabase environment.
- Chez admin portal at `website/admin.html` served against the same environment.
- Contractor operations portal at `website/operations/` if contractor assignment needs to be visually verified.
- Supabase SQL console or service-role script for DB simulation.
- Ability to inspect auth users, households, properties, `home_assessments`, `chez_requests`, `concierge_messages`, `home_systems`, `contractors`, `routines`, `maintenance_tasks`, `property_projects`, `vehicles`, `documents`, `utility_accounts`, `routine_visits`, and `chez_workbench_actions`.

## Existing Automation To Run First

These runners are not enough for the full homeowner contract, but they give fast backend signal before the manual/product pass.

```bash
node Tests/e2e/run.mjs
node Tests/e2e/run-handyman.mjs
```

Expected:

- `run.mjs` creates a homeowner, runs foundational onboarding, smoke-tests the handyman mode fork, completes the self quiz, creates representative tasks, and delegates sample tasks to Chez.
- `run-handyman.mjs` creates provider/contractor workspaces and verifies provider dashboard, quote, visit, client, and messaging data.
- Any failure in either runner blocks the full manual pass until triaged.

## Test Identities

Use timestamped emails so each run is isolated:

| Persona | Email Pattern | Purpose |
| --- | --- | --- |
| DIY homeowner | `hm+diy+{run}@chez.test` | Full self quiz, self-managed tasks, manual vendors/routines. |
| Hire-out homeowner | `hm+hireout+{run}@chez.test` | Full quiz with vendor-heavy answers and post-quiz delegation. |
| Assessment-first homeowner | `hm+assessment+{run}@chez.test` | Foundational form, select Chez/handyman assessment immediately. |
| Mid-quiz handoff homeowner | `hm+handoff+{run}@chez.test` | Start the quiz, then choose to have Chez handle setup. |
| Existing homeowner supplement | `hm+supplement+{run}@chez.test` | Existing data plus supplemental assessment ingestion and dedup. |
| Household invitee | `hm+spouse+{run}@chez.test` | Spouse/family/home-manager/staff invite and permission checks. |
| Chez admin | staging admin email | Verify admin portal and corporate orchestration. |
| Contractor/handyman | seeded provider workspace member | Verify provider assignment and field/operations handoff. |

Use at least two properties across the run:

- Primary home: ordinary single-family property with ATTOM match.
- Edge home: no/partial ATTOM data, long address/name fields, large square footage, pool, generator, well/septic/propane, multiple vehicles, duplicate vendors, and several recurring routines.

## Global Pass Criteria

Every scenario must verify four layers when applicable:

| Layer | Required Evidence |
| --- | --- |
| Homeowner UI | Screen renders, primary action works, loading/error/retry state is sane, data remains after app restart. |
| Database | Canonical rows exist with correct household/property scope and no cross-household leakage. |
| Chez admin | Admin can find, understand, message, assign, schedule, and close the work. |
| Notifications/messages | Homeowner and admin unread counts, push/deep-link payloads, and conversation thread state are correct where supported. |

## Core Data Assertions

Use these as repeated checks throughout the script.

| Entity | Required Assertions |
| --- | --- |
| `households` | User belongs to exactly one expected household unless intentionally testing household switching. `chez_ownership_groups` reflects group toggles. |
| `properties` | Address, attributes, ATTOM corrections, `house_quiz_state`, and `assessment_mode` are scoped to the right household. |
| `home_assessments` | Status moves through the expected lifecycle; preferred window, access notes, homeowner presence, captured JSON, ingestion, review, and cancellation fields are correct. |
| `chez_requests` | Every delegated task/routine/vendor/entity/group/assessment creates or updates the correct case with category, summary, source/context, status, SLA, unread flags, and household scope. |
| `concierge_messages` | Initial system message captures enough context for Chez corporate to act; homeowner/admin replies stay in thread order. |
| `home_systems` | Quiz and assessment-created systems dedup, condition, photos, install source, decommission status, and Chez ownership flags are correct. |
| `contractors` | Vendors dedup by name/phone, category is canonical, manual vendors persist, and delegated vendors produce standing-engagement cases. |
| `routines` | Cadence, vendor link, setup state, active months, visits, and Chez ownership persist and show in Upcoming/admin. |
| `maintenance_tasks` | DIY vs vendor vs Chez-owned routing works; task state and due dates remain stable after refresh/restart. |
| `property_projects` | High-cost assessment recommendations become projects when expected and can be delegated to Chez. |
| `vehicles` | Vehicles from foundational form, quiz, manual add, and assessment ingestion dedup by VIN and support Chez management. |
| `documents` | Uploaded/scanned/assessment documents show under property Documents, can be delegated, and remain visible to home managers when intended. |
| `utility_accounts` | Providers from quiz and assessment ingestion persist, can be delegated, and appear in admin workbench. |
| `chez_activity_log` | Assessment completion, Chez-managed completions, and notable work surface in the homeowner digest/activity surfaces. |

## Cleanup And Isolation

Before each run:

1. Pick a unique `{run}` token, for example `20260510a`.
2. Run the existing cleanup scripts only against the disposable E2E data set.
3. Confirm there are no active `home_assessments`, open `chez_requests`, or auth users for the same email patterns.
4. Clear app state on the test device/simulator.
5. Clear admin portal local storage/session.

After each run:

1. Export the gap log.
2. Leave failed data in place until engineering has captured screenshots/logs.
3. Delete or cancel real-looking external work items so no vendor/customer is contacted.

## Script 1: New Homeowner Account And Foundational Questions

Run this for all new homeowner personas.

### 1.1 Signup, Address, Property Creation

Steps:

1. Launch the homeowner app from a fresh install.
2. Create an account using the persona email.
3. Enter first name, last name, phone if prompted, and a unique password.
4. Enter the test property address.
5. Complete address confirmation and any property data confirmation screens.
6. Force close and reopen before continuing.

Expected homeowner result:

- User returns to onboarding, not a blank screen.
- The property is still attached to the account.
- If ATTOM data exists, the property recap is prefilled.
- If ATTOM data is partial or missing, the user can still proceed by entering corrections/manual values.

Expected backend result:

- Auth user exists.
- Household membership exists for the user.
- One primary `properties` row exists for the household.
- Property `attributes` are not overwritten by empty ATTOM values.

Edge cases:

- Duplicate email should show a recoverable login/reset path.
- Invalid address should not create a partially unusable household.
- Long street/unit text should not overflow later dashboard/property cards.
- App kill during account creation should resume cleanly or allow restart without orphaning a paid/customer-looking record.

### 1.2 Foundational Questions

The current form is 8 steps:

1. Household composition.
2. Pets.
3. Vehicles.
4. Insurance carriers.
5. Trash and recycling days.
6. Top priority.
7. DIY vs hire-out tier.
8. Visit details for a possible Chez handyman visit.

Run three variants:

| Variant | Inputs | Expected |
| --- | --- | --- |
| Complete | Family with kids, pets, two vehicles, auto/home insurers, multiple trash days, safety priority, hire-out tier, homeowner present with access notes. | All answers persist into `properties.house_quiz_state.answers`; pets and visit details are available to the assessment request path. |
| Sparse | Just me, no pets, no vehicles, blank insurance, no trash days, minimal-effort priority, DIY tier, not home with access notes. | App allows intentional blanks where optional; required decisions are enforced; access notes are sent if assessment path is chosen. |
| Skip/Resume | Use any allowed "Skip for now" path if shown, relaunch app, then finish from dashboard/settings. | Dashboard shows a finish-setup banner; returning to the form preserves prior answers and does not duplicate vehicles/vendors. |

Backend assertions:

- `q28_household`, `q30_priorities`, `q36_diy_vs_vendor`, `q26_insurance`, and `q18_trash` are represented in `house_quiz_state.answers`.
- `properties.attributes.has_pets` is true only for pet households.
- Vehicle entries from the foundational form either become canonical `vehicles` rows or are available to the later reconciler. Record a gap if they disappear after onboarding.
- Visit details are passed to `request_home_assessment` when choosing the assessment path.

Edge cases:

- Add and remove multiple vehicles before advancing.
- Enter future year, very old year, lowercase make/model, blank make with model, and non-numeric year.
- Use special characters in insurance carrier names.
- Tap Back across all 8 steps and confirm selections do not reset.
- Kill app on step 8 and reopen.

## Script 2: Self-Quiz Onboarding, Full Home Profile

Persona: DIY homeowner and hire-out homeowner.

### 2.1 Choose Self Quiz

Steps:

1. After foundational questions, choose the path to answer the home setup quiz yourself.
2. Confirm the app enters the house quiz rather than creating a `home_assessments` row.
3. Edit property recap fields: year built, square footage, bedroom/bath count, lot size, purchase date, purchase price/value if shown.
4. Save and move forward.

Expected:

- `properties.attributes.assessment_mode` is `diy`.
- No active `home_assessments` row exists for this property.
- Property corrections persist to the Property tab after quiz completion.

### 2.2 Full Quiz Coverage

Use `Tests/e2e/TEST_MATRIX.md` as the per-question branch matrix and run the highest-coverage path below.

Required answers:

- Confirm/edit ATTOM-derived property facts.
- Select exterior/grounds signals: lawn, pool/spa, irrigation, trees, roof/gutters, pest, snow if regionally relevant.
- Select major systems: HVAC, heating fuel, generator, water heater, water treatment, well/septic/propane, electrical, plumbing.
- Add utility providers: electricity, gas/propane, water/sewer, trash, internet/security where applicable.
- Add vendors from search/catalog and manual entry.
- Add at least one duplicate-looking vendor to test dedup.
- Add insurance carriers and at least one document upload/extraction flow if available.
- Add household members: spouse/partner, kids/expected child, caretaker/home manager/staff/trusted contact where available.
- Add vehicles through VIN/manual entry and insurance upload if available.
- Create recurring routines: lawn, pool, pest, HVAC, gutter, generator, chimney, water softener, vehicle service.
- Create one custom task and one generated maintenance task.
- Create one project from a quote, invoice, or manual prompt if available.
- Exercise "Save and exit", app restart, and resume.
- Complete the quiz and review the completion summary.

Expected homeowner result:

- Completion summary lists tasks, vendors, systems, and gaps.
- Dashboard loads without requiring another onboarding step.
- Dashboard shows relevant cards: home coverage, upcoming work, Chez ownership hero, activity, getting-started prompts, assessment/request cards only when applicable.
- Property tab shows Overview, Systems, Projects, Vendors, and Documents with the created data.
- Tasks tab shows Maintenance and Handyman modes, with due tasks and any punch-list items.
- Alfred tab can answer a household-aware question without leaking another test household's data.

Expected backend result:

- `properties.house_quiz_state.completedAt` is set.
- `home_systems`, `contractors`, `routines`, `maintenance_tasks`, `vehicles`, `documents`, `utility_accounts`, and `property_projects` match the choices.
- Duplicate vendors/systems are deduped or flagged for review, not silently duplicated in a way that breaks admin operations.
- Household invite rows are created only for valid invited emails, with role/permissions matching the UI.

Edge cases:

- Leave optional provider blank, then manually add later.
- Choose "I do this myself" then later attach a vendor.
- Choose a vendor, then revoke/change it.
- Use duplicate vendor names with different phone formats.
- Upload unsupported document file type, oversized file, and valid PDF/image.
- Interrupt document extraction and resolve conflicts later.
- Toggle airplane mode during quiz save, then retry.
- Switch between foreground/background several times during reconciliation.

## Script 3: Mid-Quiz Handoff To Chez Assessment

Persona: mid-quiz handoff homeowner.

Purpose: The user starts the self quiz, gets partway through, then chooses to have Chez finish setup by sending a handyman/contractor.

Steps:

1. Complete signup and foundational questions.
2. Choose self quiz.
3. Answer enough quiz questions to create partial state: property facts, one system, one utility, one vendor, one routine.
4. Use the in-quiz path "Have Chez handle it" or "Send a Chez handyman instead".
5. Pick a preferred visit window and time of day.
6. Provide access instructions and whether the homeowner will be present.
7. Submit.
8. Confirm the app lands on Dashboard with the assessment pending card.

Expected homeowner result:

- Partial quiz answers are preserved and visible to the later assessment/review flow.
- Pending card shows the active assessment state.
- User can view/edit prep notes/photos where supported.
- User can reschedule, cancel, or switch back to self setup without leaving duplicate active assessments.

Expected backend result:

- One `home_assessments` row exists with `status = pending` or `scheduled`.
- `captured_quiz_state` or property `house_quiz_state` contains partial answers already collected.
- `preferred_window_start`, `preferred_time_of_day`, `homeowner_present`, and `homeowner_access_notes` reflect the booking form.
- `properties.attributes.assessment_mode = handyman`.
- Admin/corporate can see an assessment-related `chez_requests` case or pending assessment queue item.

Edge cases:

- Handoff after zero quiz questions.
- Handoff after many questions.
- Handoff while offline.
- Double tap submit.
- Cancel after pending, then resume self quiz.
- Reschedule after admin has already assigned a handyman.
- Existing active assessment should prevent creating a second active assessment for the same property.

## Script 4: Assessment-First Onboarding

Persona: assessment-first homeowner.

Purpose: The user chooses from the beginning to have Chez/contractor set up the home.

Steps:

1. Complete signup, address, property confirmation, and foundational questions.
2. At the mode fork, choose the path for Chez to handle setup with a handyman/contractor assessment.
3. Pick a preferred visit date/time window.
4. Set both homeowner-present and not-home variants across two runs.
5. Add prep notes and photos if the card/sheet allows it.
6. Visit Dashboard and Property tab before any field work has happened.
7. Open admin portal and find the request/assessment.

Expected homeowner result:

- Dashboard pending card is visible and status-specific.
- Prep card appears before scheduled/in-progress visit where appropriate.
- Property tab is not empty or broken even though the assessment is pending.
- User can reschedule, cancel, and switch to self setup.
- Notifications/deep links route to Dashboard and the assessment card.

Expected admin result:

- Admin Concierge cockpit or assessment queue shows the household, property, preferred window, access notes, foundational answers, and prep attachments.
- Admin can assign a handyman/provider workspace/member.
- Assignment changes `home_assessments.status` to `scheduled`, links `visit_assignment_id`/`handyman_member_id`, and creates enough provider-side data for a contractor to see the job.

Expected provider result:

- Contractor operations portal can see the scheduled visit or linked assignment.
- Contractor can view address, access instructions, homeowner presence, contact details allowed by policy, prep notes/photos, and known property facts.

Current expected gap to record if it still exists:

- The iOS Field app has no fully wired assessment queue/detail/start/submit flow for `home_assessments`; if unavailable, mark Field UI failure and continue with DB simulation in Script 5.

## Script 5: DB-Simulated Handyman Assessment Visit

Run this for assessment-first and mid-quiz handoff households. This is mandatory until the Field app can submit real `home_assessments` capture payloads.

### 5.1 Admin Assignment

Steps:

1. In admin portal, find the pending assessment household.
2. Assign a handyman/provider workspace/member.
3. Verify admin sees scheduled status and provider assignment.
4. Verify homeowner Dashboard updates from pending to scheduled.
5. Verify provider/operations portal shows the visit/assignment.

DB assertions:

- `home_assessments.status = scheduled`
- `scheduled_at` is set.
- `visit_assignment_id` and/or `handyman_member_id` are set.
- A matching provider-side assignment/visit row exists.
- A concierge/system message tells the homeowner what happened.

### 5.2 Simulate Visit State

Use the `handyman-provider` actions if available in your harness. If not, use service-role SQL in staging to set the same fields and then call the ingestion action.

Visit lifecycle to simulate:

1. Mark assessment en route.
2. Start assessment visit.
3. Update progress with homeowner present/not present, concerns, access notes, and room/area progress if supported.
4. Add captured systems, vendors, routines, vehicles, utility accounts, documents, quick fixes, and recommended tasks.
5. Submit assessment data.

Required captured payload:

```json
{
  "captured_systems": [
    {
      "category": "hvac",
      "subtype": "central_ac",
      "manufacturer": "Carrier",
      "model": "24ABC6",
      "install_year": 2016,
      "notes": "Outdoor condenser on east side.",
      "condition_rating": "fair",
      "condition_notes": "Needs spring service and filter change.",
      "equipment_plate_photos": ["assessments/{assessment_id}/systems/hvac-plate.jpg"],
      "condition_photos": ["assessments/{assessment_id}/systems/hvac-condition.jpg"]
    },
    {
      "category": "water_heater",
      "manufacturer": "Rheem",
      "model": "PROG50",
      "install_year": 2012,
      "condition_rating": "poor",
      "condition_notes": "Near end of life. Corrosion visible at base."
    },
    {
      "category": "generator",
      "manufacturer": "Generac",
      "model": "22kW",
      "install_year": 2020,
      "condition_rating": "good"
    },
    {
      "category": "old_softener",
      "manufacturer": "Unknown",
      "is_decommissioned": true,
      "decommissioned_reason": "Disconnected before homeowner purchased property."
    }
  ],
  "captured_contractors": [
    {
      "company_name": "Acme HVAC",
      "category": "hvac",
      "phone": "+1 555 010 1000",
      "email": "dispatch@acmehvac.test",
      "source": "homeowner_uses"
    },
    {
      "company_name": "Acme H.V.A.C.",
      "category": "hvac",
      "phone": "555-010-1000",
      "source": "homeowner_uses"
    },
    {
      "company_name": "GreenCut Lawn",
      "category": "lawn",
      "phone": "+1 555 010 2000"
    },
    {
      "company_name": "Blue Pool Co",
      "category": "pool",
      "phone": "+1 555 010 3000"
    }
  ],
  "captured_routines": [
    {
      "kind": "hvac_service",
      "vendor_name": "Acme HVAC",
      "cadence_type": "interval",
      "cadence_interval_days": 180,
      "active_months": [3, 4, 9, 10],
      "time_of_day": "morning"
    },
    {
      "kind": "lawn",
      "vendor_name": "GreenCut Lawn",
      "cadence_type": "weekly",
      "days_of_week": [2],
      "active_months": [4, 5, 6, 7, 8, 9, 10]
    },
    {
      "kind": "pool_service",
      "vendor_name": "Blue Pool Co",
      "cadence_type": "weekly",
      "days_of_week": [5],
      "active_months": [5, 6, 7, 8, 9]
    },
    {
      "kind": "generator_service",
      "vendor_name": null,
      "cadence_type": "interval",
      "cadence_interval_days": 365
    }
  ],
  "captured_vehicles": [
    {
      "vin": "1HGCM82633A004352",
      "year": 2021,
      "make": "Volvo",
      "model": "XC90",
      "trim": "T6",
      "color": "Black",
      "license_plate": "CHEZ001",
      "mileage": 42100
    },
    {
      "year": 1969,
      "make": "Ford",
      "model": "Mustang",
      "color": "Red"
    }
  ],
  "captured_utility_accounts": [
    {
      "provider_type": "electric",
      "provider_name": "Duke Energy",
      "account_number": "E2E-12345",
      "monthly_cost_cents": 24500,
      "phone": "+1 555 010 4000"
    },
    {
      "provider_type": "propane",
      "provider_name": "Suburban Propane",
      "monthly_cost_cents": 18000
    }
  ],
  "captured_document_paths": [
    {
      "path": "assessments/{assessment_id}/documents/hvac-invoice.pdf",
      "category": "Service Record"
    },
    {
      "path": "assessments/{assessment_id}/documents/homeowners-policy.pdf",
      "category": "Insurance"
    }
  ],
  "captured_quick_fixes": [
    {
      "description": "Replaced HVAC filter during assessment.",
      "cost_cents": 2500
    },
    {
      "description": "Tightened loose handrail bracket.",
      "cost_cents": 0
    }
  ],
  "captured_attributes": {
    "has_pets": true,
    "year_built_correction": 1998,
    "sq_ft_correction": 4200,
    "assessment_mode": "handyman"
  }
}
```

Required recommended tasks:

| Recommendation | Urgency | Expected Output |
| --- | --- | --- |
| Replace aging water heater | high or urgent | `chez_requests` case; if estimated cost is greater than $5,000, also `property_projects`. |
| Service HVAC before summer | normal | `chez_requests` or `maintenance_tasks` depending on homeowner response. |
| Homeowner already scheduled gutter cleaning | normal, response `homeowner_handled` | `maintenance_tasks` with scheduled date and notes. |
| Disputed roof concern | high, declined but disputed | `chez_requests` case tagged `disputed` and `needs_verification` if source is homeowner-reported. |
| Fixed filter change | fixed during visit | No follow-up case; service record exists. |

### 5.3 Submit And Ingest

Steps:

1. Submit the simulated assessment.
2. Confirm ingestion runs.
3. If ingestion fails, inspect `home_assessments.ingestion_error`, logs, and partial rows. Do not manually fix and mark pass.

Expected DB result:

- `home_assessments.status = awaiting_review`.
- `ingested_at` is set.
- Systems appear in `home_systems` with `onboarded_via = handyman_assessment`.
- Decommissioned system is inactive and includes decommission reason.
- Vendors appear in `contractors`; duplicate Acme HVAC entries are deduped or patched.
- Routines appear in `routines`; vendor-linked routines have `vendor_id`, missing vendor routine is `pending_vendor`.
- Vehicles appear in `vehicles`; VIN duplicate is skipped on rerun.
- Utility accounts appear in `utility_accounts`.
- Documents appear in `documents` with `uploaded_via = handyman_assessment`.
- Quick fixes appear in `service_records`.
- Recommended tasks create correct `chez_requests`, `maintenance_tasks`, and `property_projects`.
- Property `house_quiz_state.completedAt` is set or preserved, and attributes merge without dropping existing homeowner answers.
- `chez_activity_log` records assessment completion.

Idempotency checks:

- Submit/ingest the same payload twice. It must not duplicate systems, contractors, routines, vehicles, documents, or follow-up cases.
- Retry after one artificial failure. It should recover or expose an actionable `ingestion_failed` state.

### 5.4 Homeowner Review

Steps:

1. Return to homeowner app.
2. Verify push/deep link or dashboard status opens `AssessmentReviewView`.
3. Review captured systems, vendors, routines, documents, quick fixes, and recommended tasks.
4. Approve the assessment.
5. Repeat on another run and request corrections instead of approval.

Expected approve result:

- `home_assessments.status = completed`.
- `reviewed_at` and `completed_at` are set.
- Assessment pending card disappears or becomes completed history.
- Newly captured data is visible on Dashboard, Property, Tasks, Documents, Vehicles, and Activity surfaces.

Expected corrections result:

- `home_assessments.status = corrections_requested`.
- Correction notes persist.
- Admin sees a corrections-needed state and can reschedule/assign continuation.
- Homeowner sees clear next step, not a completed assessment.

Edge cases:

- Review while offline.
- Review after admin edits captured data.
- Approve with one duplicate vendor present.
- Correction request after some generated Chez cases already exist.
- Deep link from push when user is logged out.

## Script 6: Chez-Managed Task, Routine, Vendor, Entity, And Group Ownership

Run this after both self-quiz and assessment-ingested data exist.

### 6.1 Individual Task Delegation

Run two task variants:

| Variant | Setup | Expected Chez Request |
| --- | --- | --- |
| Task has no vendor | Open a maintenance task without an assigned vendor and tap "Have Chez source a vendor" or equivalent. | `maintenance_tasks.chez_owned = true`; `chez_requests.category = find_vendor`; system message explains needed vendor/category/property. |
| Task has vendor | Attach a contractor, then tap "Have Chez handle this task". | `maintenance_tasks.chez_owned = true`; `chez_requests.category = coordinate_task`; system message includes vendor and task context. |

Admin verification:

1. Open admin Concierge cockpit.
2. Find the new case.
3. Open dossier/context.
4. Use reply, mark read/unread, status transition, and proposal flow.
5. Propose vendor/date/cost/quote.
6. Approve, decline, and counter proposals across separate runs.
7. Update visit scheduling/completion if proposal is approved.

Homeowner verification:

- Task detail shows Chez is managing it.
- Concierge thread appears in homeowner inbox/requests.
- Proposal cards render correctly and decisions update admin.
- Revoking ownership returns the task to homeowner without deleting the conversation history.

Edge cases:

- Tap delegation twice quickly.
- Revoke while request is still open.
- Delegate a completed task.
- Delegate an overdue task.
- Delegate a task for a different household through a tampered payload. Must fail authorization.

### 6.2 Routine Delegation

Steps:

1. Open a recurring routine, for example lawn, pool, HVAC, generator, pest, or vehicle service.
2. Toggle "Have Chez own scheduling" or equivalent.
3. Add notes.
4. Verify the next upcoming visit is visible.
5. In admin Households workbench, use routine actions: schedule visit, log visit, mark complete, add notes.
6. Revoke the routine from the homeowner app.

Expected:

- `routines.chez_owned = true` and `chez_owned_at` set when delegated.
- A standing-engagement `chez_requests` case exists.
- Admin Upcoming feed can filter to Chez-owned routines.
- `routine_visits` or relevant visit rows are created by admin workbench actions.
- Revocation flips `routines.chez_owned = false` and does not create a new request.

Edge cases:

- Routine with no vendor.
- Routine with archived vendor.
- Routine outside active months.
- Routine already has upcoming visit.
- Routine generated by assessment ingestion.

### 6.3 Vendor Delegation

Steps:

1. Open Property -> Vendors.
2. Add a vendor manually and via quiz/assessment.
3. Toggle Chez management for an existing vendor relationship.
4. Admin opens the standing-engagement case and workbench vendor row.
5. Admin logs contact, quote, schedule, and message actions where supported.
6. Revoke delegation.

Expected:

- `contractors.chez_owned = true` and `chez_owned_at` set.
- A standing-engagement `chez_requests` case exists with vendor name/category/notes.
- Admin workbench owned-only filter includes the vendor.
- Revocation removes it from owned-only view after refresh.

Edge cases:

- Duplicate vendor merged by assessment ingestion should not create two standing engagements.
- Vendor with missing phone/email should still be delegatable and should create a "needs contact info" admin task or clear context gap.
- Vendor shared by multiple routines should show those relationships in admin.

### 6.4 Other Entity Delegation

For each entity type, toggle ownership on and off from the homeowner app and verify admin receipt.

| Entity | Surface | Edge Function | Expected |
| --- | --- | --- | --- |
| System | Property -> Systems -> system detail | `delegate_entity` with `entity_type = system` | `home_systems.chez_owned`, standing-engagement case, workbench row. |
| Project | Property -> Projects -> project detail | `delegate_entity` with `entity_type = project` | `property_projects.chez_owned`, project case/context. |
| Document | Property -> Documents -> document detail | `delegate_entity` with `entity_type = document` | `documents.chez_owned`, document management case. |
| Utility account | Property/vendor/utility surface | `delegate_entity` with `entity_type = utility` | `utility_accounts.chez_owned`, bill/account case. |
| Vehicle | Vehicle detail | `delegate_entity` with `entity_type = vehicle` | `vehicles.chez_owned`, vehicle management case. |
| Insurance | Property/insurance surface | `delegate_entity` with `entity_type = insurance` | `properties.chez_owned_insurance` key toggled, insurance case. |

Authorization checks:

- Tamper `entity_id` to another household. Must return unauthorized and not flip ownership.
- Tamper insurance `property_id`. Must return unauthorized.

### 6.5 Group-Level Ownership

From the Chez ownership screen, test every group:

| Group Key | Homeowner Meaning | Expected Backfill |
| --- | --- | --- |
| `all_routines` | Chez handles all recurring routines. | All existing `routines.chez_owned = true`. |
| `all_systems` | Chez manages all home systems. | All existing `home_systems.chez_owned = true`. |
| `all_vendors` | Chez manages all vendor relationships. | All existing `contractors.chez_owned = true`. |
| `all_projects` | Chez manages all projects. | All existing `property_projects.chez_owned = true`. |
| `all_bills` | Chez manages utility accounts/bills. | All existing `utility_accounts.chez_owned = true`. |
| `all_documents` | Chez files/manages all documents. | All existing `documents.chez_owned = true`. |
| `all_vehicles` | Chez manages all vehicles. | All existing `vehicles.chez_owned = true`. |
| `all_insurance` | Chez manages all insurance policies. | `properties.chez_owned_insurance` seeds/updates policy keys. |

Steps:

1. Turn one group on.
2. Verify `households.chez_ownership_groups[group].on = true`.
3. Verify existing entities are backfilled.
4. Verify exactly one summary `chez_requests` case is created, not one per entity.
5. Create a new entity in that group from homeowner UI.
6. Create a new entity in that group from assessment ingestion.
7. Verify new entities inherit ownership.
8. Turn group off and verify backfill off.
9. Use "hand off everything" and "return everything" if available.

Current likely failure to capture:

- Assessment ingestion currently checks group keys named `systems`, `vendors`, and `routines`, while group toggles write `all_systems`, `all_vendors`, and `all_routines`. New assessment-ingested systems/vendors/routines may not inherit group-level Chez ownership. This is a high-priority E2E failure if reproduced.

## Script 7: Homeowner App Surface Audit After Onboarding

Run this for every completed persona after data exists.

### 7.1 Dashboard

Verify:

- Pull-to-refresh works.
- Home coverage hero matches vendor/system coverage counts.
- Chez ownership hero count and group count match DB.
- Upcoming work includes routine visits, scheduled vendor visits, maintenance tasks, and Chez-managed work.
- Assessment card appears only for active assessment statuses.
- Assessment review opens only for `awaiting_review`.
- "This week with Chez" activity reflects assessment completion and Chez-managed work.
- Getting started prompts hide as actions are completed.
- Quick actions route to the correct tabs/sheets.
- Push/deep links to tasks, property, documents, invoices, Chez requests, handyman visits, and assessment review land correctly.

Edge cases:

- Empty account.
- Very data-heavy account.
- No network.
- Expired auth session.
- Dynamic type/accessibility sizes.
- Device date/timezone different from property timezone.

### 7.2 Property Tab

Verify property list and property detail:

- Overview: address, facts, household strips, coverage gaps, routines, tasks, and quick actions.
- Systems: add/edit/delete/decommission systems, attach documents, update install date/condition, delegate to Chez.
- Projects: create project, import from quote/invoice/email, update status/budget, delegate to Chez.
- Vendors: add vendor, search local vendor, manual vendor, duplicate warning/dedup, attach vendor to routine/task, delegate to Chez.
- Documents: upload/scan/import, extraction conflicts, rename/category/share, delegate to Chez.
- Utilities/policies if surfaced within vendors/overview/documents: add/edit/delegate.

DB assertions:

- All changes stay in the same household/property.
- Soft deletes/archive states are respected.
- Related cards update without full reinstall.

### 7.3 Tasks Tab

Verify:

- Maintenance mode shows generated tasks, custom tasks, upcoming tasks, overdue tasks, seasonal/year views, and completed tasks.
- Task detail supports complete, snooze/reschedule, attach vendor, add notes/photos/docs, delegate to handyman punch list, and delegate to Chez.
- Handyman mode supports punch list items, visit scheduling, quote/status surfaces, messages, and completed visit after-action report.
- Chez-owned tasks are visually distinct from personal tasks.
- Filters/counts remain correct after revoking Chez ownership.

Edge cases:

- Task with no property.
- Task with deleted system.
- Task with vendor no longer active.
- Recurring task expansion across year boundary.
- Multiple open visits tied to same task should not duplicate dashboard cards.

### 7.4 Alfred/Chat/Concierge

Verify:

- Household-aware Alfred can answer "What maintenance is overdue?", "What documents am I missing?", and "What is Chez handling for me?"
- Property/system/task context chat opens from detail screens.
- Chez request composer can create vendor search, quote, coordination, insurance claim, bill review, and general requests.
- Request list/thread shows messages, attachments, unread state, proposals, and status changes.
- Admin replies and proposals arrive without app reinstall.

Privacy checks:

- Alfred/admin context never includes another test household.
- Home manager/staff roles see only allowed property/household data.

### 7.5 Settings, Household, And Account

Verify:

- Profile edit, phone/email handling, password/reset/logout.
- Family member invite, spouse invite, home manager invite, staff/trusted contact invite.
- Role changes and removal.
- Add second property and switch between properties.
- Request supplemental assessment from settings or property surface.
- Finish skipped foundational questions from settings/home details.
- Security dashboard and subscription/billing gates if present.
- Notification preferences and device token registration.

Edge cases:

- Invite existing user vs new user.
- Invite invalid email.
- Remove the current user from household should be blocked or recoverable.
- Home manager cannot change owner-only settings.
- User logs out during active Chez request, then logs back in.

## Script 8: Chez Admin Portal Contract

Run this for every delegated item and assessment.

### 8.1 Concierge Cockpit

Verify:

- New requests appear quickly with correct category and SLA.
- Filters/search find by household, property, vendor, category, status, and urgency.
- Request detail includes homeowner thread, dossier, profile, property, systems, vendors, routines, previous cases, attachments, and assessment references.
- Admin can reply, mark read/unread, transition status, assign internal owner if supported, analyze request, ask Alfred, and draft vendor framing.
- Proposal flow supports create, edit where supported, approve/decline/counter from homeowner, and follow-up visit tracking.
- Assessment requests can be assigned to a handyman/provider.

Failure conditions:

- A Chez-managed toggle creates a DB row but no actionable admin case.
- Admin case lacks household/property/entity context.
- Admin cannot tell what action Chez corporate needs to take.
- Homeowner thread and admin status disagree.

### 8.2 Households Workbench

Verify:

- `fetch_households_list` shows all test households with expected counts.
- `fetch_household_workbench` returns routines, systems, vendors, tasks, projects, documents, utilities, vehicles, and cases.
- Owned-only filter includes every Chez-owned item and excludes unowned items.
- Focused entity detail shows enough context and action buttons.
- Workbench actions create real side effects and `chez_workbench_actions` audit rows.

Required workbench actions to exercise:

- Schedule routine visit.
- Log routine visit.
- Schedule vendor/system/project visit where supported.
- Log service on a system.
- Audit utility bill.
- Message homeowner from a focused entity.
- Create follow-up task/project/case from a gap.

### 8.3 Upcoming Feed

Verify:

- `fetch_upcoming` includes homeowner-created and admin-created visits/tasks.
- Chez-owned-only toggle is accurate.
- Type filters work.
- Time windows and dates are correct around timezone boundaries.
- Completing/rescheduling work updates homeowner Dashboard.

## Script 9: Contractor/Handyman Operations Contract

Run for assessment-assisted onboarding and any Chez request that should involve an external provider.

Expected provider/contractor capabilities:

- Provider sees assigned assessment/visit.
- Provider sees household/property context, access instructions, homeowner presence, and prep material.
- Provider can message Chez/admin or homeowner where policy allows.
- Provider can capture systems, vendors, routines, vehicles, documents, recommended tasks, quick fixes, and completion notes.
- Provider can submit the assessment in a way that writes `home_assessments.captured_*` and triggers ingestion.
- Provider can handle follow-up visits, quotes, routes, and invoices where supported.

Current expected gaps to record if still true:

- The Field app uses `handyman_request_visits` for visit JSON while assessment ingestion reads `home_assessments.captured_*`; these can drift.
- `GuidedAssessmentView` exists but is not wired as the active Field app assessment workflow.
- No complete Field UI for assessment queue/detail/start/check-in/submit against `home_assessments`.
- No wired Field capture for vendor/routine/vehicle/utility/document payloads in the active flow.
- Assessment contractor/routine capture models lack per-entry `chez_owned`, so "Managed by Chez" cannot be captured during the visit.
- There is no complete bridge for Chez corporate to delegate arbitrary Chez-owned work from `chez-concierge` into a provider workspace.

## Script 10: Critical Edge Cases

Run these after the main happy paths pass.

| Area | Edge Case | Expected |
| --- | --- | --- |
| Auth | Expired token during quiz save | User can reauth and continue without data loss. |
| Auth | Home manager/staff attempts owner-only action | Action blocked with no DB mutation. |
| RLS | Tampered household/property/entity ids | 403/unauthorized and no data leak. |
| Network | Offline during delegation | UI shows retry; no duplicate `chez_requests` on retry. |
| Network | Edge Function 500 during assessment request | User sees actionable error; no stuck onboarding state. |
| Idempotency | Double tap every primary submit | One row/case/visit, not duplicates. |
| Time | Daylight saving/timezone boundary for routines | Upcoming dates remain correct. |
| Data | Very large household with 100+ entities | Dashboard/admin load within acceptable time and no truncation/overlap. |
| Data | Special characters and long names | UI wraps, DB stores, search still works. |
| Dedupe | Same vendor from quiz and assessment | One vendor row or explicit merge workflow. |
| Dedupe | Same vehicle VIN from foundational form and assessment | One vehicle row. |
| Lifecycle | Revoke Chez ownership while case open | Ownership flips off; admin is informed or case remains as history. |
| Lifecycle | Assessment cancelled after scheduled | Provider/admin/homeowner all show cancelled and no active duplicate. |
| Lifecycle | Corrections requested after ingestion | Admin can reopen/reschedule; homeowner does not see completed state. |
| Lifecycle | Existing user supplemental assessment | Existing rows update/dedup; user data is not overwritten by blanks. |
| Notifications | Push for assessment complete | Routes to Dashboard and opens review when logged in; prompts login when logged out. |
| Accessibility | Largest Dynamic Type | Text fits, buttons remain tappable, sheets scroll. |
| Admin | Non-admin opens admin portal/API | Blocked. |
| Privacy | Admin workbench household switch | No stale household data remains in focused entity panel. |

## Known Expected Failures From Audit

Track these explicitly in the run report. If fixed, update this section.

| ID | Gap | Severity | Where It Should Fail |
| --- | --- | --- | --- |
| HMO-G1 | Field app assessment queue/detail/start/submit is not fully wired to `home_assessments`. | Critical | Scripts 4, 5, 9 |
| HMO-G2 | Active Field app submit writes `handyman_request_visits` JSON, while assessment ingestion reads `home_assessments.captured_*`. | Critical | Script 9 |
| HMO-G3 | Vendor/routine/vehicle/utility/document capture is not available in the active Field visit flow. | Critical | Script 9 |
| HMO-G4 | Captured assessment contractors/routines do not carry per-entry `chez_owned`, so managed-by-Chez cannot be captured during a visit. | High | Scripts 5, 6 |
| HMO-G5 | Group-level inheritance during assessment ingestion likely checks `systems/vendors/routines` instead of `all_systems/all_vendors/all_routines`. | High | Script 6.5 |
| HMO-G6 | Admin approval/revision gate for assessment recommendations is incomplete or not obvious. | High | Scripts 5, 8 |
| HMO-G7 | Bridge from Chez-managed arbitrary work to provider/contractor workspace is incomplete. | High | Scripts 8, 9 |
| HMO-G8 | Coverage/waitlist path may be unreachable if coverage is hardcoded available. | Medium | Scripts 3, 4 |
| HMO-G9 | Existing-user supplemental assessment dedup/update needs full validation with real mixed data. | Medium | Scripts 5, 10 |
| HMO-G10 | Field app has no Chez-owned awareness. | Medium | Scripts 6, 9 |

## Failure Report Template

Use this exact shape for every failed assertion.

```markdown
### Failure: {short title}

- Run token:
- Persona:
- Severity: Critical | High | Medium | Low
- Surface: Homeowner app | Admin portal | Provider portal | Edge Function | DB
- Scenario ID:
- Expected:
- Actual:
- Repro steps:
- Household id:
- Property id:
- Assessment id:
- Chez request id:
- Related rows inspected:
- Screenshots/videos:
- Logs:
- Suspected owner/module:
- Notes:
```

## Minimum Release Gate

Do not consider homeowner E2E green until these are true:

1. A new homeowner can complete self onboarding and land on a useful dashboard with systems, vendors, routines, vehicles, tasks, documents, and projects.
2. A new homeowner can choose Chez assessment onboarding and have that request visible/actionable in admin.
3. A simulated handyman assessment can ingest into canonical homeowner data and require homeowner review.
4. Approving assessment review makes the captured data visible across Dashboard, Property, Tasks, Documents, Vehicles, and Activity surfaces.
5. Requesting corrections loops back to admin/provider operations without marking the assessment complete.
6. Every "Managed by Chez" toggle creates an actionable admin case or workbench state with sufficient context.
7. Admin can schedule/log/advance Chez-managed routines, tasks, vendors, systems, projects, documents, utilities, vehicles, and insurance work.
8. Chez-owned group toggles backfill existing entities and new entities inherit correctly.
9. RLS/authorization tests prove one household cannot access or mutate another household's data.
10. Existing known critical gaps are either fixed or explicitly accepted with product/launch sign-off.

## Suggested Execution Order

1. Run `Tests/e2e/run.mjs` and `Tests/e2e/run-handyman.mjs`.
2. Execute Script 1 for all new homeowner personas.
3. Execute Script 2 for DIY and hire-out homeowners.
4. Execute Scripts 3 and 4 for mid-quiz and assessment-first paths.
5. Execute Script 5 with DB-simulated field capture.
6. Execute Script 6 across all Chez-managed ownership types.
7. Execute Scripts 7 and 8 across homeowner and admin surfaces.
8. Execute Script 9 against the contractor/Field/operations surface.
9. Execute Script 10 edge cases.
10. Produce one gap report with all failures grouped by severity and module.
