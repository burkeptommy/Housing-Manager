# Chez Contractor buildout — progress log

## Status: 4/51 waves complete (Mobile Pass 1)

| Wave | Plan | Status | Commit | Date | Notes |
|---|---|---|---|---|---|
| M0 | Mobile (custom — not in original plan) | ✅ PASS | `25ebbbf0` | 2026-05-08 | PWA decommission + repoint every field URL to TestFlight (`https://testflight.apple.com/join/sw4xWsTA`). Deleted 6 PWA source files. Updated Operations Desk MobileInterstitial, vite.config.ts proxy, handyman-provider FIELD_SITE_URL, HandymanVisitService.portalURL + SMS/email body templates, plan docs. iOS + SPA both compile + deploy clean. |
| Auth fix | (custom — bug found in pre-flight) | ✅ PASS | `c1248a01` | 2026-05-08 | `HavenSimulatorAuthStorage`: simulator-only `AuthLocalStorage` that writes to `UserDefaults` instead of Keychain. Fixes `errSecMissingEntitlement` (-34018) which silently caused sign-in to bounce back to the welcome screen on every iOS Simulator build. Diagnosed from live sim log. Device + TestFlight + App Store builds unchanged. |
| M1 | Mobile | ✅ PASS | `b409fd18` | 2026-05-08 | Visit lifecycle: schema (`provider_visit_assignments` clock_in_at/clock_out_at/paused_seconds + GPS + `provider_visit_pauses` table), 4 edge fn actions (start_visit / pause_visit / resume_visit / complete_visit) on `handyman-provider`, native iOS UI in `HavenFieldVisitWorkspaceView` (4-state lifecycle, H:MM:SS counter via `Timer.publish` derived from clockInAt - pausedSeconds, GPS via `CLLocationManager`, pause modal with reason picker + "Other" branch validation). Operations Desk renders TIME ON-SITE + verified-arrival pill. Caught + fixed a critical snake_case→camelCase serialization bug mid-test. End-to-end verified on iPhone 16e iOS 26.2 with W2 owner session. |
| M2 | Mobile | ✅ PASS | `a814a67f` | 2026-05-08 | Punch capture depth: schema (attachments / materials_used / time_spent_seconds / voice_note_path on `handyman_punch_items` + `punch-item-attachments` storage bucket), 4 edge fn actions (attach_punch_photo / attach_punch_voice / set_punch_materials / set_punch_time_spent), `FieldPunchItemRow` redesigned with horizontal Photo/Voice/Parts/Time chip bar, `FieldVoiceRecorder` (AVFoundation), `FieldPunchPhotoLightbox`, `FieldPunchMaterialsSheet`. Photos via PhotosPicker (1600px max-edge JPEG downsizing), voice via AVAudioRecorder, materials with qty + unit_cost, per-item timer. Cross-app parity in Operations Desk's `VisitDetail.tsx` (`PunchCaptureDepthStrip`). Co-committed with M6 due to parallel-agent merge timing. |
| M6 | Mobile | ✅ PASS | `a814a67f` | 2026-05-08 | Field UX polish: schema (`provider_visit_tech_notes` table with workspace-RLS), 2 edge fn actions (add_tech_note / list_tech_notes) + `techNotesCount` denorm on assignment payload, native iOS surfaces (`FieldTappableAddressRow` with mappin icon → maps.apple.com, `FieldTappablePhoneRow` with phone.fill icon → tel://, `FieldRouteSummaryCard` on Today screen showing N stops + estimated drive time, in-truck reschedule sheet with 3 quick-pick slots + DatePicker, internal tech-to-tech notes section on visit Home tab). Operations Desk: "Internal Notes (workspace only)" sidebar card mirror. Verified end-to-end with badge flipping from "1 note" to "2 notes" on relaunch. Drive-time calc and reschedule slot picker are stubbed (heuristic) — flagged in deferred items. Customer phone pull-through deferred (property summary doesn't carry phone yet). |
| M3 | Mobile | ✅ PASS | `c9861c90` | 2026-05-08 | System inventory authoring: schema (`home_systems.decommissioned_at / decommission_reason / marked_for_followup_at / followup_reason / voice_note_path`), edge fn actions (extract_system_from_photo wrapper around identify-equipment, decommission_system, mark_system_followup, clear_system_followup, attach_system_voice, **create_home_system** — added in this commit to fix RLS-blocked direct PostgREST inserts from workspace members), native iOS `HavenFieldHomeProfileView` with system sweep mode (camera-first), gap-fill list, decommission flow with reason picker, follow-up toggle, voice-note button. Cross-app parity in `HomeDetail.tsx`. Schema landed under `a814a67f`; this commit fixes the two production blockers verification caught: the RLS gate on `home_systems` insert, and a debug-seed JPEG fix so the sim's "Use test image" path works without a real camera. |

## Vercel deploy state (last checked 2026-05-08 ~3:40 PM ET)

- `https://www.getchez.com/operations/` → **200** (Operations Desk SPA)
- `https://www.getchez.com/handyman-visit.html` → **404** (PWA retired ✓)
- `https://www.getchez.com/handyman.html` → **200** (legacy auth pitch still working)

## iOS Simulator state

- iPhone 16e (id `F9946648-90C6-42B0-AFCB-92E3807F36C8`, iOS 26.2) booted with ChezField.app installed + signed in as W2 owner.
- Field workspace renders correctly — Overview tab shows "Good afternoon, E2E", 9 homeowner requests, route summary card.
- Auth session persists in UserDefaults via `HavenSimulatorAuthStorage` (commit `c1248a01`).

## Schema migrations applied this pass

- `20261301_visit_lifecycle.sql`
- `20261302_punch_capture_depth.sql`
- `20261303_home_system_decommission.sql`
- `20261305_visit_tech_notes.sql`

## Deferred to follow-up waves

Captured in detail in the per-wave JSON outputs. High-priority deferred items:

- **M6 route_summary stub** — currently a 15-min-between-stops + 10-min-initial-leg estimate. Future wave: swap in Apple MapKit ETARequest or Google Directions API.
- **M6 reschedule quick-slot stub** — picks tomorrow 9am, day-after 1pm, 3 days out 9am. Future: real open-windows lookup against the tech's calendar.
- **M6 customer-phone pull-through** — `FieldTappablePhoneRow` is wired but property-summary shape doesn't include phone yet; needs join through `users.phone` or `family_members.phone` in `loadDashboard`.

## What's next

Per the orchestrator's pass plan, **Pass 2 — Web foundation** (B7 → W2 → W3 → W18) is the next block. Mobile Pass 2 (M4 → M5 → M8 → M11) covers the remaining sales + close-of-day flows.

Demo readiness for the mobile contractor surface: **GO** (all four mobile-foundation waves clean, sign-in works, native iOS surfaces are field-ready).
