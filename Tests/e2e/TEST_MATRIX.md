# Onboarding edge-case test matrix

Pragmatic plan for exercising every meaningful branch of the onboarding flow
(`AddressHookView` → `PropertyHookView` → `AccountCreationStep` →
`FoundationalQuestionsForm` → `OnboardingModeForkView` → `HouseQuizView` →
walk-through → cinematic reveal → Dashboard) without trying to cover the
full Cartesian product.

Two surfaces:

  - **Foundational form** ("initial intake quiz") — 8 questions, single-shot.
  - **House Quiz** — ~28 questions across 3 chapters, with dynamic skips and
    answers that feed downstream behaviour (system creation, task seeding,
    contractor mirroring, provider search ranking).

For each surface the matrix is split into:

  - **Per-question branches** — every meaningful answer path on a single
    question.
  - **Cross-question edge cases** — interactions between questions that have
    been the source of historical bugs (foundational pre-fill into the quiz,
    dynamic skips, conditional sub-steps).

Each row in the matrix is owned by one of three test surfaces:

  | Mark | Owner | Why |
  |------|-------|-----|
  | **`UI`** | iOS Simulator (computer-use driving) | Behaviour depends on tap order, reveal animations, button enable/disable, multi-step progressive forms. |
  | **`E2E`** | `Tests/e2e/run.mjs` (Node, calls Edge Functions + PostgREST) | Behaviour is a deterministic write-and-verify against the schema; cheap to combinatorially expand. |
  | **`Unit`** | `HavenTests/` Swift | Pure Swift logic — answer mapper, reconciler, day-curator — already covered by Swift tests, just keep them green. |

---

## 1. Foundational form (8 questions)

### Q1 — Who lives here? (`singleChoice`)

| Answer | Owner | Notes |
|---|---|---|
| `just_me` | UI | Should not auto-create a child `family_member`. |
| `couple` | UI | Carries to quiz Q28; quiz should pre-fill `couple` answer. |
| `family_with_kids` | UI | Carries to Q28 + reveals kids sub-step in the quiz Caretakers flow. |
| `multi_gen` | UI | Same Q28 carry-through, distinct copy. |
| `something_else` | E2E | Free-form path; Q28 should let user retype. |

### Q2 — Pets? (`singleChoice`)

| Answer | Owner | Notes |
|---|---|---|
| `Yes, we have pets` | UI | Sets `properties.attributes["has_pets"] = true`; auto-creates Pet Waste system + the "Sanitize pet areas" task on synthetic turf. |
| `No pets` | UI | `has_pets = false`; no Pet Waste system. |

### Q3 — Vehicles? (`vehicleAdd`)

| Answer | Owner | Notes |
|---|---|---|
| Skip | UI | No vehicle row inserted; quiz Q24 still asks. |
| Add via VIN scan | UI (skip — camera) | Camera-only. Note as "manual QA only" in this run. |
| Add via insurance card upload | UI (skip — camera) | Same. |
| Add via type VIN/details | UI | Triggers `vehicle-lookup` Edge Function with the VIN; verify NHTSA decode + recall list. Use a known clean VIN like `5YJ3E1EA8KF317001`. |

### Q4 — Insurance carriers (`dualInsurance`)

| Answer | Owner | Notes |
|---|---|---|
| Skip both | UI | No utility_accounts. |
| Auto only | E2E | One `utility_accounts` row, type `auto_insurance`. |
| Home only | E2E | Same shape, type `home_insurance`. |
| Both | UI | Two rows. Quiz Q26 should pre-fill both. |

### Q5 — Trash & recycling (`trashWithDays`)

**Owner: UI — this question now has the trash-pre-fill fix landed in [9838b11d](https://github.com/burkeptommy/Housing-Manager/commit/9838b11d) and must be re-verified.**

| Answer | Owner | Notes |
|---|---|---|
| 0 days picked | UI | Continue should be disabled when service is `municipal`/`private`; allowed when `not_sure`. |
| 1 day (e.g. Wed) | UI | **Round-trip into the House Quiz Q22 — the pickup-day picker MUST show Wed already filled.** |
| 2 days (e.g. Mon + Thu) | UI | Same round-trip; both days appear pre-filled. |
| All 7 | UI | Edge case — unusual but legal. Should not break the layout. |

### Q6 — What matters most? (`singleChoice`)

| Answer | Owner | Notes |
|---|---|---|
| `financial` | UI | Carries to quiz Q30. |
| `safety` | UI | Same. |
| `aesthetic` | UI | Same. |
| `minimal_effort` | UI | Special: should bias the mode-fork copy/recommendation toward handyman. |

### Q7 — How do you handle work? (`singleChoice`) — **the priorityRow tap-eat fix**

**This is the one that was broken until [beec7d67](https://github.com/burkeptommy/Housing-Manager/commit/beec7d67). Re-verify on every build.**

| Answer | Owner | Notes |
|---|---|---|
| `diy` ("I handle it") | UI | All `.either` tasks resolve to `.personal`. Quiz Q15 should pre-fill DIY. |
| `mixed` ("Mix of both") | UI | `.either` tasks: effort > 30min → vendor, else personal. |
| `hire_out` ("Hire it out") | UI | All `.either` tasks → vendor; needs_vendor=true on every uncovered system. |

### Q8 — If a Chez handyman visits (`willBeHomeForVisit` toggle + access notes)

| Answer | Owner | Notes |
|---|---|---|
| Toggle ON | UI | `homeowner_present: true` in `home_assessments`. |
| Toggle OFF | UI | `homeowner_present: false`; access notes field becomes more important. |

---

## 2. Cross-question carry-through (foundational → quiz)

The quiz's `firstUnresolvedIndex()` skips questions whose `house_quiz_state.answers[id]`
is already populated. The pre-fill happens in
`OnboardingViewModel.persistFoundationalAnswersAsQuizSeed`.

| Foundational answer | Quiz target | Test |
|---|---|---|
| Q1 household | `q28_household` | UI: pick `family_with_kids`, finish foundational, on quiz the Q28 step should auto-skip OR present pre-filled with `couple_with_kids`. |
| Q5 trash days | `q18_trash` | UI: pick Wed, advance to quiz Q22, confirm Wed renders pre-selected. **Just-shipped fix.** |
| Q6 priority | `q30_priorities` | UI: pick `financial`, on quiz Q30 it should be pre-checked. |
| Q7 tier | `q36_diy_vs_vendor` | UI: pick `mixed`, quiz Q15 (the `Your Pros` chapter opener) shows `Mix of both` with checkmark. |
| Q4 insurance | `q26_insurance` | E2E: pick both carriers, quiz Q26 dual-picker should show both rows pre-populated; tapping `Change` should re-open the picker. |
| Q3 vehicle (added) | `q24_vehicle_add` | UI: VIN-decode flow — verify carry-through. (Skip in low-budget runs.) |

---

## 3. House Quiz — per-question branches

Each row maps `(question, answer)` → expected backend side effect.

### Chapter 1 — Your Home

| Q | Answer | Owner | Side effect to verify |
|---|---|---|---|
| Q1 `q1_roof` | `asphalt` / `metal` / `tile` / `slate` / `wood_shake` / `flat_membrane` | E2E | Roofing system gets the matching subtype; templates list reflects it. |
| Q1 | `not_sure` | UI | No subtype written; system stays bare. |
| Q2 `q2_siding` | one selected | E2E | `properties.attributes["siding_material"]` is comma-joined. |
| Q2 | two+ selected | E2E | Same — multi-value attribute. |
| Q2 | `Other` (custom) | UI | Custom text input UX; verify save shape. |
| Q3 `q3_heating` | `oil_boiler_central_ac` | E2E | HVAC subtype `boiler` AND Q19 heating-provider question stays in flow. |
| Q3 | `electric_heatpump` / `geothermal` | UI | **Q19 should be skipped — verify the skip-toast on the next visible question.** |
| Q3 | `not_sure` | UI | Q19 still asks, but with relaxed copy. |
| Q4 `q6_water` | `municipal` | E2E | NO Well system created. |
| Q4 | `private_well` / `shared_well` | E2E | Well System home_systems row created. |
| Q5 `q7_sewer` | `municipal_sewer` | E2E | NO Septic system. |
| Q5 | `septic` | E2E | Septic system + reconciler-seeded "Septic pump-out (3-year)" task. |
| Q6 `q8_water_heater` | each of 6 options | E2E | Water Heater subtype matches; Tankless skips the "Anode rod" task. |
| Q7 `q9_basement` | `finished` only | E2E | No Sump Pump system. |
| Q7 | `unfinished` + `sump_pump` | E2E | Sump Pump system inserted. |
| Q7 | `crawl_space` only | E2E | Crawl Space system. |
| Q7 | `slab` | E2E | No basement-related system. |
| Q7 | `none of the above` (n/a here, multi-select) | — | n/a. |
| Q8 `q9b_renovations` | `none` | E2E | No date-stamping. |
| Q8 | `roof_replaced` + year | E2E | Stored in `customEntries`, ATTOM lifespan recalibrated downstream (Phase 60.4 territory; verify metadata persists at minimum). |
| Q9 `q10_appliances` | individual ones | E2E | Per-selected `home_systems` row in the `Appliance` category. |
| Q9 | SELECT ALL | UI | All ~8 rows inserted at once; no duplicates. |
| Q9 | custom add (Sauna…) | UI | Custom appliance system row with the typed name. |
| Q10 `q20_other_fuels` | `None` | UI | The None pill must be mutually exclusive with the others. |
| Q10 | `propane_fireplace` only | E2E | Propane Fireplace system + utility_account if heating fuel is not propane. |
| Q11 `q21_solar` | `yes_owned` / `yes_leased` | E2E | Solar Panels system created with subtype. |
| Q11 | `no` / `considering` | E2E | No Solar system. |
| Q12 `q22_generator` | `none` | UI | No Generator system, fuel sub-step hidden. |
| Q12 | `whole_home` + propane (heating ≠ propane) | UI | Backup Generator system + utility_account for propane. |
| Q12 | `whole_home` + propane (heating = propane) | UI | **Same-supplier confirmation card. Verify both Yes-same and Different-supplier branches.** |
| Q12 | `portable` + gasoline | E2E | No utility_account (gasoline isn't a delivery service). |
| Q13 `q11_lawn` | `pro` + provider catalog hit | E2E | Landscaping system + Contractor row + utility_account + ACTIVE Routine. |
| Q13 | `pro` + free-form name | E2E | Same shape, different Contractor.name source. |
| Q13 | `diy` | E2E | Landscaping system, no Contractor. |
| Q13 | `no_lawn` | UI | **Q14 (irrigation) should be skipped — verify the skip-toast.** |
| Q13 | `garden` | E2E | Landscaping with subtype `garden`. |
| Q13 | `hardscape` | E2E | Outdoor Hardscape system + 4 hardscape templates. |
| Q13 lawn type | `natural` / `synthetic` / `mixed` / `not_sure` | E2E | Subtype variants. Synthetic with pets adds the "Sanitize pet areas" task. |
| Q14 `q12_pool` | `none` | E2E | No Pool/Spa system. |
| Q14 | `in_ground` + `chlorine` | UI | Pool system (subtype `pool_inground_chlorine`) + 3 children (Pump, Filter, Heater). Chemistry-aware templates. |
| Q14 | `in_ground` + `salt` | E2E | Same shape, salt chemistry templates. |
| Q14 | `above_ground` + `chlorine` | E2E | Pool with `pool_above_ground_chlorine` subtype; same 3 children. |
| Q14 | `hot_tub_only` | UI | Hot Tub system, no pool children, hot-tub-specific templates only. |
| Q14 | `both` | UI | BOTH Pool + Hot Tub systems separately. |

### Chapter 2 — Your Pros

| Q | Answer | Owner | Side effect |
|---|---|---|---|
| Q15 `q36_diy_vs_vendor` | each tier | UI | Reconciler reflows `.either` tasks; verify task counts on the Dashboard differ between tiers. **Already pre-filled from foundational Q7.** |
| Q16 `q13_pest` | `recurring_pro_service` + provider | E2E | Pest Control system + Contractor + utility_account + Routine. |
| Q16 | `termite_bond` | E2E | Pest Control with subtype `termite_bond`. |
| Q16 | `diy` | E2E | Pest Control system, no contractor. |
| Q16 | `none` | E2E | NO Pest Control system. |
| Q17 `q14_irrigation` | `yes_full` + provider | E2E | Irrigation system + Contractor. |
| Q17 | `drip_only` | E2E | Irrigation with subtype `drip`. |
| Q17 | `no` | E2E | No Irrigation system. |
| Q18 `q15_security` | `yes_monitored` + provider | E2E | Security System + Contractor + utility_account + Routine. |
| Q18 | `yes_self_monitored` | E2E | Security System, no Contractor. |
| Q18 | `cameras_only` | E2E | Security System with subtype `cameras_only`. |
| Q18 | `none` | E2E | No Security System. |
| Q18 | `prefer_not_to_answer` | E2E | No system, attribute key flagged. |
| Q19 `q15b_household_contractors` | each chip selected w/ provider | E2E | Per-chip Contractor row + ACTIVE Routine (handyman is the exception — no routine). |
| Q19 | skip everything | E2E | Continue button labeled "You can skip this and add contractors later" — should advance with no inserts. |
| Q19 | conditional chip — septic pumper visible only when Q5 = septic | UI | Conditional chip visibility verified by toggling Q5. |
| Q20 `q16_electric` | catalog pick | E2E | utility_account with `provider_id` and snapshotted brand. |
| Q20 | custom name | E2E | utility_account with `provider_name` only. |
| Q21 `q17_internet` | catalog pick / custom | E2E | Same shape as Q20 with type `internet_cable`. |
| Q22 `q18_trash` | foundational pre-fill | UI | **Just-fixed pre-fill. Verify Wed appears pre-selected.** |
| Q22 | `municipal` + 1 day | UI | Continue enables only when day picked. |
| Q22 | `private` + 2 days | UI | Same gate. |
| Q22 | `not_sure` | UI | Continue allowed without days. |
| Q22 | private hauler with custom name | UI | Hauler name field appears; saves to `customText`. |
| Q23 `q19_heating_provider` | catalog | E2E | utility_account type matches Q3 fuel (oil/propane/natural_gas). |
| Q23 | conditional skip | UI | Q3 = electric/geothermal → Q23 should not appear. |

### Chapter 3 — Your People

| Q | Answer | Owner | Side effect |
|---|---|---|---|
| Q24 `q24_vehicle_add` | skip | E2E | No Vehicle row. |
| Q24 | type VIN | UI | NHTSA decode; vehicle row + recall list. |
| Q25 `q25_garage_ev` | `attached` / `semi_attached` / `detached` / `carport` + EV no | E2E | Garage Door system, no EV Charger system. |
| Q25 | any garage + EV yes | E2E | Garage Door + EV Charger (L2) system. |
| Q25 | `none` | UI | EV charger sub-question hidden. |
| Q26 `q26_insurance` | both carriers | E2E | Two utility_accounts. |
| Q26 | foundational pre-fill | UI | If foundational Q4 picked carriers, Q26 dual-picker shows them already. |
| Q28 `q28_household` | `just_me` | E2E | No additional `family_members`. |
| Q28 | `couple_with_kids` + 1 kid | UI | One `family_members` row inserted; kid form. |
| Q28 | `couple_with_kids` + expecting | UI | Expecting member row; due-date field. |
| Q28 | + nanny / au pair | UI | Caretaker row. |
| Q28 | + home manager | UI | Home Manager invite flow (Build 87 tower). |
| Q30 `q30_priorities` | foundational pre-fill | UI | Q6 carries through; tap-to-add additional priorities. |

---

## 4. Cross-cutting edge cases

| Case | Owner | Notes |
|---|---|---|
| Save-for-later → resume | UI | Tap `Save for later` mid-quiz, kill app, relaunch, verify quiz resumes at the right index. |
| Back-navigation hydration | UI | Tap `<` from Q5, verify Q4 answer is still highlighted. Repeat for every kind. |
| Unresolved-saved review screen | UI | Save 2-3 questions for later, finish to the review screen, jump back, finish. |
| Resume mid-quiz after kill | UI | Force-quit app at Q15, relaunch — should land on Q15 (or first unresolved). |
| Cinematic reveal numbers | UI | Verify the maintenance-task / vendor / system counts match what the DB actually has post-completion. |
| Vendor Coverage sweep auto-present | UI | When ≥2 systems are uncovered, the sweep should fire before the reveal. |
| Vendor Coverage sweep skip | UI | When 0-1 systems uncovered, the sweep should NOT fire — straight to reveal. |
| `firstUnresolvedIndex()` after foundational | UI | Foundational pre-fills Q15 + Q26 + Q22 + Q28 + Q30; quiz should skip past them when their answer is satisfied. |
| Mode fork: handyman path | UI | Pick `Send a Chez handyman to set up`. Verify `requestHomeAssessment` Edge Function 200s, home_assessments row inserted. (Cancel after — don't leave a real work item.) |
| Mode fork: DIY path | UI | Already covered. |
| Mode fork: waitlist | UI | If ATTOM detects out-of-coverage state, the join-waitlist path. |

---

## 5. Execution priority for this session

The matrix is large; this session executes the highest-value subset first.

**Round A — UI (must verify the just-shipped fixes):**
1. **Trash pre-fill round-trip** — foundational Wed → Q22 pre-filled.
2. **Q7 priority tier** — re-verify with the post-fix build.
3. **Heating fuel = electric → Q19 skipped** with a skip toast.
4. **Lawn = no_lawn → Q14 (irrigation) skipped** with a skip toast.
5. **Pool = in_ground → chemistry sub-step** + 3 pool children created.

**Round B — Backend (combinatorially expand):**
1. Each `q1_roof` material (7).
2. Each `q3_heating` fuel/system (8).
3. Each `q14_pool` variant + each chemistry (4 × 2).
4. Multi-select None-exclusion: q9_basement, q10_appliances, q20_other_fuels.
5. Provider pickers — catalog vs custom for q16/q17/q19/q20.
6. Q19 chips: each combination of {handyman, plumber, electrician, hvac, septic, well, chimney, tree} with an inline picker.

**Round C — Defer to manual QA (cost > value for now):**
- Camera-driven inputs (VIN scan, label scan, document upload).
- Save-for-later → kill app → resume.
- Cinematic reveal screenshot diffing (visual regression — separate phase).
- Mode fork handyman path beyond a smoke test.

---

## 6. Reset between runs

Each iteration starts clean:

```sh
supabase db query --linked --output json --file Tests/e2e/cleanup.sql
xcrun simctl uninstall <SIM_ID> com.havenhome.app
xcrun simctl install <SIM_ID> ./build/Build/Products/Debug-iphonesimulator/Chez.app
xcrun simctl launch <SIM_ID> com.havenhome.app
```

Test users follow the `e2e-test-*@havenhome.test` email pattern so the
`Tests/e2e/cleanup.sql` script wipes them in one shot.
