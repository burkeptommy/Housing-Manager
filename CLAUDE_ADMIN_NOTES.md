# Claude Admin Notes

Generated from `admin_codex_notes` where target IN ('claude','both'). When a new Claude session opens, scan this file before doing anything else.

**Synced:** 2026-05-01T13:50:04.340Z
**Pending:** 0 change requests · **Open questions:** 0 · **Feedback:** 100 · **Applied (last 30d):** 205

Reading order: 1. Questions for Claude. 2. Pending Changes. 3. Open Feedback (by entity). 4. Recently Applied (audit).

---

## 📋 Open Feedback (by entity)

### ❓ Quiz Questions

#### 13. Security or alarm system?  `q15_security`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — Q15 security subtitle em-dash was already replaced in Round 2 (commit 40a3c1d4).

#### 15. Pool or hot tub?  `q12_pool`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-04-30 · feedback · claude**
Verified. Q12 architecture (Build 87) creates SEPARATE home_systems rows for the two halves of the both answer: a Pool system with the chosen pool-type subtype + 3 children, AND a Hot Tub system with subtype hot_tub. Maintenance templates gate independently — pool templates fire on requiredSubtypes [pool], hot tub templates fire on [hot_tub], so both/in_ground+hot_tub households get the union. Caveat: hot tub Drain-and-refill + cover/jets templates over-fire for households whose hot tub is an attached spillover spa (shares water with the pool). Notes copy on those templates now tells those users to skip — drain rolls into pool service. Q12 follow-up question to distinguish detached vs attached is queued as a TODO in MaintenanceTemplates.swift above the hot-tub templates. Marking applied.

#### 2. What's your exterior siding?  `q2_siding`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — duplicate of 93602e78. Q2 siding subtitle was already fixed.

**2026-05-01 · feedback · claude**
Stale — Q2 siding subtitle em-dash was already replaced in Round 2 (commit 40a3c1d4).

#### 6. Do you have a mortgage on this home?  `q5_mortgage`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — Q5 mortgage was deleted in Batch 5 (commit 0367137f) per the original feedback note (b348f04c + f5992eea). Mapper retains a no-op case for round-trip safety on saved-for-later quizzes. Marking applied.

#### 6. What kind of water heater do you have?  `q8_water_heater`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Applied — Q8 water heater Not-sure option label simplified.

#### 8. Any major renovations in the last 10 years?  `q9b_renovations`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Applied — Q9b renovations subtitle em-dash replaced with period.

#### attom_derive_partial: q4_purchase  `live-quiz-q4_purchase`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — Q4 was deleted entirely in Batch 5 per earlier feedback (purchase price now flows through PropertyRecapCard which already pulls from ATTOM). The ATTOM pre-fill proposal is obsolete. Marking applied.

#### drop: q23_vehicle_count  `live-quiz-q23_vehicle_count`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — Q23 vehicle_count was already removed (Phase 67D); Q24 vehicleAdd handles the primary vehicle directly with a Skip option. Verified by grep over current HouseQuizQuestionLibrary. Marking applied.

#### Merge q11_lawn + q11b_lawn_type  `live-quiz-q11_lawn`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q11b_lawn_type was merged into the progressiveLawn kind (Phase 67D A4). Already merged.

**2026-05-01 · feedback · claude**
Stale — q11c_landscaping_months was removed; landscaping months moved to Phase C3 AnnualRhythmScreen. Already addressed.

#### Merge q12_pool + q12b_pool_chemistry  `live-quiz-q12_pool`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q12b_pool_chemistry was merged into the progressivePool kind (Build 87). Already merged.

**2026-05-01 · feedback · claude**
Stale — q12c_pool_months was removed; pool months moved to Phase C3 AnnualRhythmScreen. Already addressed.

#### Merge q14_irrigation + q14b_irrigation_months  `live-quiz-q14_irrigation`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q14b_irrigation_months was removed; active months for irrigation moved to Phase C3 AnnualRhythmScreen. Already addressed.

#### Merge q15_security + q15b_household_contractors  `live-quiz-q15_security`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Skipped per follow-up call. 15 contractor chips on the same screen as the 4-option security question would be visually overwhelming. Q15 + Q15b stay as separate consecutive screens. Marking applied as a deliberate non-merge.

#### Merge q18_trash + q18b_trash_day  `live-quiz-q18_trash`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q18b_trash_day was merged into the trashWithDays progressive kind (Phase 67D). Already merged.

#### Merge q25_garage_ev + q25b_ev_charger  `live-quiz-q25_garage_ev`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q25b_ev_charger was merged into the garageWithEV progressive kind (Phase 67D). Already merged.

#### Merge q28_household + q28b_pets  `live-quiz-q28_household`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q28b_pets was folded into Q28 caretakers payload (Phase 67D A10). Mapper reads q28_household.payload[petsAnswerId]. Already merged.

#### Merge q3_heating_fuel + q3b_hvac_type  `live-quiz-q3_heating_fuel`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Stale — q3+q3b were merged into q3_heating_system with 12 fuel+system combo options (Phase 67D A3). Already merged.

#### Merge q9_basement + q9b_renovations  `live-quiz-q9_basement`

**Section** ? · **Chapter** ? · **Kind** ?

**2026-05-01 · feedback · claude**
Deferred. Q9 + Q9b merge queued behind active Q9b renovationsMultiSelect kind work. Pattern matches Phase 67D progressivePool / progressiveLawn / trashWithDays merges already in place.

**2026-05-01 · feedback · claude**
Deferred. Q9 + Q9b merge is queued behind the active Q9b renovationsMultiSelect kind work. Once that kind ships and the renovations payload schema is stable, the merge into a progressive parent (e.g. "basementWithRenovations") is straightforward — pattern matches the Phase 67D progressivePool / progressiveLawn / trashWithDays merges already in place.

### 🛠 Maintenance Templates

#### 6. What kind of water heater do you have?  `live-quiz-q8_water_heater`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — empty proposed_diff. Q8 water heater label was simplified per 651b3c48.

#### 8. Any major renovations in the last 10 years?  `live-quiz-q9b_renovations`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied — same Q9b renovations subtitle voice fix shipped.

#### Annual Chimney Sweep  `Chimney:Annual chimney sweep`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-04-30 · feedback · claude**
Investigated. Only one Annual chimney sweep template exists in iOS code (MaintenanceTemplates.swift:1111) gated on requiredSubtypes [wood]. The duplicate display is the admin lab rendering the same template under two scopes — live-task-chimney-annual-chimney-sweep + live-handyman-chimney-annual-chimney-sweep — because the lab presents homeowner and handyman views independently. iOS-side this only seeds once. If the dual rendering in the lab is confusing, we could collapse the two scopes into a single row.

#### Annual cooling unit service  `Wine Cellar:Annual cooling unit service`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. Annual cooling unit service (Wine Cellar) defaults to the HVAC contractor (Q15b hvac_service) since wine-cellar cooling = mini-split work. Homeowner can override via per-task assignment.

#### Annual elevator inspection  `Elevator:Annual elevator inspection`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. Annual elevator inspection — Elevator is a registered specialty category. Custom elevator vendors land with category=Elevator and the reconciler matches. No Q15b chip for v1; residential elevators are rare enough that homeowner-add via Property → Contacts is sufficient.

#### Annual security system check  `Security System:Verify alarm system`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Annual security system check routes to the new Q15b security_service chip (gated on Q15 ≠ none). ADT / SimpliSafe / Vivint live in utility_providers as monitoring companies; the security_service chip captures a separate post-monitor security pro for system maintenance + battery + sensor work. Canonical aliases ("alarm", "security service", "alarm company") route any custom-named contractor to Security System.

#### Bundle: "Chimney Fall  `live-task-chimney-annual-chimney-sweep`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-04-30 · feedback · claude**
Deferring — same quote-leak bug as f58205f9. proposed_diff bundleId/bundleTitle have literal leading double-quote. Re-propose after the lab fixes. Architecture is sensible (Annual chimney sweep + Inspect chimney cap + Annual gas fireplace service share Fall + vendor-only — bundle would consolidate one visit).

#### Bundle: "HVAC Fall  `live-task-hvac-professional-hvac-tune-up-heating`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-04-30 · feedback · claude**
Deferring — same quote-leak bug as f58205f9. Re-propose after the lab fixes. Note that HVAC tune-up (heating) already pairs with Annual boiler service in many households as a single fall vendor visit, so the bundle is sensible. Will apply once the proposed_diff strings are clean.

#### Bundle: "Landscaping Spring  `live-task-landscaping-top-up-turf-infill`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-04-30 · feedback · claude**
Deferring — proposed_diff has a serialization bug: bundleId reads "\"Landscaping:spring" (leading literal double-quote character) and bundleTitle reads "Spring \"Landscaping Service". Looks like the lab is leaking JSON-quoted strings instead of unquoted values. Same bug present in the Chimney Fall and HVAC Fall proposals (c483a5ef and 9aa2e805). Once the lab strips the surrounding quotes, re-propose and I will apply. Architecturally the bundle merge is sensible — same pattern as the existing Generator:annual / Roofing:spring bundles.

#### Check foundation for cracks  `Crawl Space:Check foundation for cracks`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Check foundation for cracks (Crawl Space:annual bundle child) now routes to a Waterproofing & Basement contractor via the new Q15b waterproofing chip + canonical aliases ("waterproofing", "basement waterproofing", "waterproofing & basement", "basement systems", "foundation" → Crawl Space). American Dry Basements / Connecticut Basement Systems land in the right slot.

#### Check vapor barrier condition  `Crawl Space:Check vapor barrier condition`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Check vapor barrier condition routes to the Waterproofing & Basement contractor via the Q15b waterproofing chip.

#### Check Washing Machine Supply Hoses  `Handyman:washer_hoses_spring`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Washing machine supply hoses now route through the handyman punch rail — the Plumbing:annual_inspection bundle's reconciler pass writes `handyman_punch_items` rows for tier-1 handyman tasks instead of `maintenance_tasks`.

#### Descale tankless heater  `Water Heater:Descale tankless heater`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. Descale tankless heater routes to the HVAC vendor via the Q15b hvac_service chip — boiler+water heater are typically the same trade for HNW homes.

#### Drain and refill hot tub  `Pool/Spa:Drain and refill hot tub`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Drain and refill hot tub now routes to the pool vendor via the Q15b pool_service chip.

**2026-05-01 · feedback · claude**
Applied — voice rewrite shipped, em-dash removed from Drain and refill hot tub notes block (and en-dashes inside dollar/percent ranges normalized to hyphens).

#### Fire Extinguisher Annual Check  `Electrical:Fire extinguisher annual check`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Fire extinguisher annual check is a Handyman bundle child and now routes to the punch rail.

#### Flush Water Heater  `Water Heater:Flush water heater`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — Flush water heater notes em-dash was already replaced in Round 2 (commit 693691c7).

#### Foundation Walkaround: Cracks and Grading  `Handyman:foundation_walkaround_spring`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Foundation walkaround routes through the handyman punch rail at reconcile time. The Crawl Space:annual bundle's pro inspection (mold / cracks / vapor barrier) lives separately and now routes to a Waterproofing & Basement vendor via the new Q15b waterproofing chip + canonical alias (commit aebcdb65).

#### Inspect for mold or mildew  `Crawl Space:Inspect for mold or mildew`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Inspect for mold or mildew routes to the Waterproofing & Basement contractor via the Q15b waterproofing chip.

#### Inspect hot tub cover and jets  `Pool/Spa:Inspect hot tub cover and jets`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Inspect hot tub cover and jets is a Pool/Spa template (subtype=hot_tub); the same captured pool vendor handles hot tubs since most HNW pool services cover both. Q15b chip + aliases land it.

**2026-05-01 · feedback · claude**
Applied — em-dash replaced with period in hot tub cover/jets notes.

#### Inspect pool equipment  `Pool/Spa:Inspect pool equipment`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Inspect pool equipment routes to the captured pool vendor.

#### New task  `local-1777573048534`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-04-30 · feedback · claude**
Confirmed admin lab artifact. local-1777573048534 is a local-only test record that never made it into MaintenanceTemplates.swift, so there is nothing on the iOS side to delete. Marking applied — if you want it removed from the lab UI too, hit the trash icon in the admin draft list.

#### Pool closing and winterization  `Pool/Spa:Professional pool closing/winterization`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Pool closing and winterization routes to the captured pool vendor.

#### Pool heater service  `Pool/Spa:Pool heater service`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Pool heater service routes to the captured pool vendor.

#### Pool opening service  `Pool/Spa:Professional pool opening`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Pool opening service routes to the captured pool vendor.

#### Pool safety fence inspection  `Pool/Spa:Pool safety fence inspection`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Pool safety fence inspection is a Pool/Spa template; the new Q15b pool_service chip + canonical "pool" / "pool service" / "pool company" / "spa" aliases route any captured pool vendor to it.

#### Prune Shrubs and Hedges  `Landscaping:Prune shrubs and hedges`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Prune shrubs and hedges flagged isEssential: false so it stays opt-in via Recommended Services rather than auto-seeding for every Landscaping household.

#### Quarterly elevator service  `Elevator:Quarterly elevator service`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · tom**
if the home has an elevator then we map to an elevator company. that easy.

#### Recaulk Interior Trim and Baseboards ↔ Spot-Paint Interior Trim and Baseboards  `live-handyman-handyman-recaulk-interior-trim-and-baseboards`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — duplicate of cdf26a9e. Recaulk interior trim and baseboards was deleted in Batch 1 (commit 6b2b7acd). Marking applied.

**2026-04-30 · feedback · claude**
Duplicate of cdf26a9e — same pair. Confirmed intentional. See reply on cdf26a9e.

#### Recaulk Interior Trim and Baseboards ↔ Spot-Paint Interior Trim and Baseboards  `live-task-handyman-recaulk-interior-trim-and-baseboards`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — Recaulk interior trim and baseboards was deleted in Batch 1 (commit 6b2b7acd). Spot-Paint remains, but the duplicate pair is resolved. Marking applied.

**2026-04-30 · feedback · claude**
Confirmed intentional. Recaulk and Spot-Paint are separate trade actions — caulking is sealant, spot-paint is finish coat, both done independently. Recommend allowlisting the pair in the duplicate detector. Leaving pending so you can choose: (a) suppress in detector and close, or (b) override and merge.

#### Replace Cabinet Pulls and Knobs ↔ Tighten Loose Cabinet Pulls and Knobs  `live-handyman-handyman-replace-cabinet-pulls-and-knobs`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — duplicate of 6cca28be. Replace cabinet pulls and knobs was deleted in Batch 1 (commit 6b2b7acd). Marking applied.

**2026-04-30 · feedback · claude**
Duplicate of 6cca28be — same pair. Confirmed intentional. See reply on 6cca28be.

#### Replace Cabinet Pulls and Knobs ↔ Tighten Loose Cabinet Pulls and Knobs  `live-task-handyman-replace-cabinet-pulls-and-knobs`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — Replace cabinet pulls and knobs was deleted in Batch 1 (commit 6b2b7acd). Tighten Loose remains, but with no second template to dup against, the duplicate detector should suppress this pair on the next admin lab refresh. Marking applied.

**2026-04-30 · feedback · claude**
Confirmed intentional. Replace and Tighten are separate operations — Replace happens during a renovation/upgrade (drilling new holes), Tighten happens during routine handyman maintenance. Different trade actions, different cadences. Recommend allowlisting the pair in the duplicate detector. Leaving pending so you can choose: (a) suppress in detector and close, or (b) override and merge.

#### Replace Refrigerator Water Filter  `Appliance:Replace refrigerator water filter`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — duplicate of 2047ccda. Already fixed in Round 2.

**2026-04-30 · feedback · claude**
Applied via Phase 67E/F handyman-tier routing. The template was already configured as handyman-tier (routingOverride .diyDefault + 10min effort + no safety floor + no bundleId), so the reconciler routes it directly to handyman_punch_items rather than maintenance_tasks — Haven adds it to your handyman punch list automatically every six months. Updated the description + notes to make that explicit and to point homeowners without a handyman to the manufacturer subscription path. True auto-order (Amazon affiliate / one-tap reorder) is still queued as a separate capability ask.

**2026-04-30 · feedback · claude**
Deferring with a question — when you say Can you please do this for us, do you mean: (a) auto-order the replacement filter via Amazon/manufacturer when the cadence hits, (b) auto-create a one-tap reorder reminder with the SKU pre-filled, or (c) flag the task as auto-handled in the punch list with no user action needed? (a) needs an Amazon affiliate or manufacturer integration + payment plumbing — multi-week feature. (b) is feasible quickly via the existing service_records / equipment_catalog data we already have on most fridges (model number → standard filter SKU). (c) is the lightest. Tell me which and I will scope. Leaving pending until then.

#### Replace sensor batteries  `Security System:Replace sensor batteries`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Sensor batteries already a Handyman bundle child — routes through the punch rail. The new Q15b security_service chip (commit aebcdb65) covers users who want a dedicated alarm-company vendor for the system itself.

#### Replace Smoke & CO Detector Batteries  `Handyman:smoke_co_batteries_spring`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Smoke & CO detector battery replacement now lands as a punch-rail row — Handyman:* bundle members route to handyman_punch_items rather than spawning standalone tasks.

#### Replace Smoke Detectors  `Electrical:Replace smoke detectors`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Replace smoke detectors (every 10 years) is a Handyman bundle child — routes to the punch rail. Distinct from the Electrical:fall bundle's annual electrician work.

#### Schedule exterior window re-caulking  `Windows:Schedule exterior window re-caulking`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied via Phase 67I (commit 69c9b4c5). Schedule exterior window re-caulking is a Handyman bundle child (Handyman:caulking_inspect_spring) and routes through the punch rail.

#### Sign up for mosquito and tick season  `Mosquito & Tick:Sign up for mosquito and tick season`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. Sign up for mosquito and tick season — existing Q15b mosquito_tick chip mirrors a contractor with category=Mosquito & Tick. Households using their pest-control vendor can pick that contractor via per-task assignment.

#### Solar panel cleaning  `Solar:Professional panel cleaning`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Solar panel cleaning routes to the captured solar vendor via the Q15b solar_service chip.

#### Solar system inspection  `Solar:Professional inspection`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied (commit aebcdb65). Solar system inspection routes to the new Q15b solar_service chip's captured vendor (gated on Q21 ∈ owned/leased).

#### Test T&P relief valve  `Water Heater:Test T&P relief valve`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. T&P relief valve routes to whoever handles Flush water heater — Q15b hvac_service chip captures the HVAC contractor by default.

#### Well system inspection  `Well System:Professional well inspection`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Applied. Well system inspection is a Well System template; the existing Q15b well_water_service chip mirrors a contractor with category=Well System so the reconciler auto-links.

### 🔨 Handyman Templates

#### Replace Refrigerator Water Filter  `Appliance:Replace refrigerator water filter`

**Category** ? · **Frequency** ? · **Priority** ? · **Cost** ?  
**Assignment** ? · **Routing** ? · **Safety floor** false · **Essential** ?

**2026-05-01 · feedback · claude**
Stale — Replace refrigerator water filter description was already fixed in Round 2 (commit 693691c7).

### 🔁 Routine Kinds

#### Mosquito and tick spraying  `mosquito_tick`

**Vendor-based** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Applied a smart vendor inheritance instead of merging the routines. Pest Control + Mosquito & Tick stay as separate routines (Mosquito has activeMonths Apr-Oct, Pest Control is year-round quarterly — losing that seasonality would be wrong). New linkPendingSiblingRoutineIfApplicable in RoutineSeeder.seedIfNeeded fires when the user adds a contractor of either kind: if a pending sibling routine exists without a vendor, it auto-links the contractor + flips the sibling to active. So adding Orkin once now activates BOTH pestControl + mosquitoTick routines if both were pending. User can swap later in routine settings when the vendor is actually different. Analytics route through routineSeededFromContractor with source sibling_inheritance.

### 🏠 System Categories

#### Cleaning Service  `Cleaning Service`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged. Cleaning Service is in the SystemProfileAudit archival set — legacy home_systems rows get archived on launch. RoutineKind.cleaning exists; RoutineSeeder creates the biweekly cleaning routine when a Cleaning contractor is added at Q15b. Zero maintenance templates anchor here. Registry entry stays as a vendor-anchor (Handyman pattern) so cleaners can be saved as contractors with this category. Marking applied — no code change needed.

#### Handyman  `Handyman`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged via Phase 67E/F. Handyman is in the SystemProfileAudit archival set; legacy home_systems rows archive on launch. RoutineKind.handymanRecurring exists for the singleton handyman routine. The 105 Handyman category templates fire via the reconciler tier-routing logic shipped in Phase 67E/F (commit 872eefb) — they land in handyman_punch_items rather than maintenance_tasks. Registry entry stays so handymen can be saved as contractors and so the Handyman tab can render the right icon. Marking applied — no code change needed.

#### Landscaping  `Landscaping`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Best-judgment outcome: kept Landscaping as a vendor-anchor category (so landscapers save with category=Landscaping) AND made one targeted fix — Prune shrubs and hedges moved from the duplicative Landscaping:ongoing bundle into Landscaping:spring (commit 693691c). The bi-weekly routine handles ongoing mowing / hedging / trimming. Spring + Fall cleanup tasks already exist via bundles (Landscaping:spring + Landscaping:fall) — those bundle 8 of the 18 templates into two seasonal task rows. The 3 decision-point templates (soil pH, arborist health, outdoor lighting) stay as standalone tasks. Hardscape (4) + synthetic turf (3) templates stay gated on their respective subtypes. The bigger Exterior UX umbrella (your point about gutters being exterior but not always landscaping) is a deeper UX restructure — it would unify Landscaping + Siding/Exterior + Roofing under one navigational shell — and is queued as Phase 67G. The current architecture is functional, just siloed by trade.

**2026-04-30 · feedback · claude**
Landscaping has 18 templates that break into 4 sub-groups: (1) lawn-routine work that should fold into the landscaping routine when a vendor is captured (mulch, prune, fertilize, aerate, overseed, pre-emergent, dethatch, leaf cleanup — 8 templates); (2) decision-point annual inspections that stay as standalone tasks (soil pH every 2yr, arborist health inspection annual, outdoor lighting service annual — 3 templates); (3) hardscape work for paver patios (pressure wash, joint sand, weed treatment, drainage check — 4 templates, gated on hardscape subtype); (4) synthetic turf work (infill, grooming, deep clean — 3 templates, gated on synthetic_turf subtype). Group (1) is the cleanest fold-into-routine candidate. Group (3) and (4) are arguably their own systems (Hardscape, Synthetic Turf). Group (2) stays. This is a multi-commit refactor — proposing a Phase 67G follow-up rather than rushing the restructure here. The current state is functional: lawn-routine templates fire when the user has the Landscaping system + matching vendor, the routine handles per-event scheduling. Marking deferred for now.

#### Mosquito & Tick Spraying  `Mosquito & Tick`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged. RoutineKind.mosquitoTick exists. The standalone Sign up for mosquito and tick season template (Spring, vendor-only) stays — decision-point task that prompts the user to renew their season contract. Per-event treatments are handled by the routine. Registry entry stays as vendor-anchor + decision-point template host. Marking applied — no code change needed.

#### Pest Control  `Pest Control`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged. RoutineKind.pestControl exists. The standalone Termite inspection template (Annual, -150) stays — that is a decision-point inspection separate from the recurring quarterly spray work the routine handles. Registry entry stays so the inspection can fire and so vendors save with this category. Marking applied — no code change needed.

#### Pet Waste Removal  `Pet Waste`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged. Pet Waste is in the SystemProfileAudit archival set — legacy home_systems rows archive on launch. RoutineKind.petWaste exists; RoutineSeeder creates the weekly routine for has_pets households via ensureSystemlessRoutines. Zero maintenance templates anchor here. Registry entry stays as a vendor-anchor. Marking applied — no code change needed.

#### Plumbing  `Plumbing`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Decision per follow-up — keep Plumbing as a system. The category anchors real maintenance tasks (Drain cleaning, anode rod work folded into Water Heater service, sump pump tests bundled into the spring handyman visit). Plumber is also a contractor category that links to plumbing tasks via Phase 19l vendor delegation. Marking applied without code change.

#### Pool Service  `Pool/Spa`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Applied with a refinement. Pool/Spa stays a system because real pool work (opening, closing, heater service, equipment inspection, safety fence) is system-anchored — those are not routines. The recurring weekly cleaning IS a routine (RoutineKind.poolService) which already exists. Renamed Pool/Spa system displayName from "Pool Service" to "Pool" to stop suggesting it is routine-shaped. Deleted Test and sanitize hot tub water (weekly DIY) per your note that it is not a real calendar task. Pool heater service was folded into the Pool/Spa:opening bundle in an earlier commit (61107635). Hot tub items stay on the separate Hot Tub system.

#### Snow Removal  `Snow Removal`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Already converged on the system rail (in serviceCategories archival set; RoutineKind.snowRemoval exists; RoutineSeeder seeds for snow-state households). One template stays — Renew snow plowing contract (Fall, vendor-only, -1200/season). It is a decision-point task NOT a routine — homeowners need a calendar reminder to renew the contract, not a recurring routine. Registry entry stays as a vendor-anchor + so the contract-renewal template can fire via reconciler when a Snow Removal contractor + system row exist. Marking applied — no code change needed.

#### Trash & Recycling  `Trash & Recycling`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Applied with the same vendor-anchor pattern Handyman uses. Existing legacy Trash & Recycling system rows now archive on next launch via the bumped runServiceSystemArchiveOnceIfNeeded gate (v1 → v2). Routines for trash/recycling/compost already exist (RoutineKind.trash/.recycling/.compost from Phase 54E). The registry entry stays so haulers can be saved as contractors with this category — same role Handyman registry entry plays.

#### Water Softener / Filtration  `Water Treatment`

**Tier** ? · **Priority** ? · **Cadence** ? · **Icon** ?

**2026-04-30 · feedback · claude**
Best-judgment outcome: keep Water Treatment as a top-level Specialty system (current state). The schema already supports parent_system_id for sub-system hierarchy (Phase 60+). When a user has a Well System AND adds Water Treatment, they can link via parent_system_id — Well becomes the parent and Filtration / Softener hang as children, alongside Acid Neutralizer / UV Filter that already work this way per CLAUDE.md. The auto-link prompt (when a user adds Filtration AND Well already exists, ask Make this part of your well system?) is a UX nicety queued as a follow-up — not blocking. The full virtual Water parent (auto-creating with Well + Filtration as children) would need a Q6 quiz redesign + migration which is out of scope for this session. Marking applied — current architecture is functional.

**2026-04-30 · feedback · claude**
Architectural — needs a design call. Current state: Water Treatment category (registry displayName Water Softener / Filtration) is a top-level Specialty system. Well System is a separate top-level Conditional system. Town water is implicit (no system row). Your idea: a parent Water system with child Well/Town/Filtration/Softener nodes. The schema already supports parent_system_id (Phase 60+) so child systems can hang under a parent — Well System already has Acid Neutralizer / UV Filter children per CLAUDE.md. Two options: (a) keep Water Softener / Filtration as its own top-level system (current state) and trust users to manually link via parent_system_id when they have a well; (b) introduce a virtual Water parent that auto-creates with Well + Filtration as children. (b) is cleaner architecturally but needs a quiz Q6 redesign + migration for existing households. Marking deferred until you confirm direction.

### 📝 General Notes

#### Add Appliance repair specialist as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Appliance repair specialist to DEFAULT_VENDOR_CATEGORIES (Sub-Zero / Wolf / Thermador focus).

#### Add Carpet + upholstery cleaner as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Carpet + upholstery cleaner to DEFAULT_VENDOR_CATEGORIES with role description.

#### Add Landscape designer as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Landscape designer to DEFAULT_VENDOR_CATEGORIES, distinct from week-to-week landscaping crew.

#### Add Locksmith as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Locksmith to DEFAULT_VENDOR_CATEGORIES (re-key, smart-lock, safe service).

#### Add Painter as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Painter to DEFAULT_VENDOR_CATEGORIES.

#### Add Pool service as a vendor type

**2026-05-01 · feedback · claude**
Applied. Pool service was added to website/admin.js DEFAULT_VENDOR_CATEGORIES in Phase 67I (commit 69c9b4c5) and Q15b now exposes a pool_service chip (commit aebcdb65) gated on Q12 ≠ none. Captured contractor mirrors with category=Pool/Spa so the existing pool/hot-tub templates auto-route at task creation time.

#### Add Pressure washer as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Pressure washer to DEFAULT_VENDOR_CATEGORIES.

#### Add Window cleaner as a vendor type

**2026-05-01 · feedback · claude**
Applied — added Window cleaner to DEFAULT_VENDOR_CATEGORIES.

#### Audit: Home gym / equipment service

**2026-05-01 · feedback · claude**
Deferred. Home gym / equipment service routine = Phase 67J optional-services library follow-up (new RoutineKind enum + RoutineSeeder default + UI surface).

#### Audit: Mail + package management

**2026-05-01 · feedback · claude**
Deferred. Mail + package management routine = Phase 67J optional-services library follow-up. These 5 lifestyle routines (gym/detail/wine/plants/mail) ship together once RoutineKind + UI library are extended.

#### Audit: Plant care (interior)

**2026-05-01 · feedback · claude**
Deferred. Plant care (interior) routine = Phase 67J optional-services library follow-up.

#### Audit: Vehicle detail

**2026-05-01 · feedback · claude**
Deferred. Vehicle detail routine = Phase 67J optional-services library follow-up.

**2026-05-01 · feedback · claude**
Deferred. Vehicle detail routine = Phase 67J optional-services library follow-up.

#### Audit: Wine inventory check

**2026-05-01 · feedback · claude**
Deferred. Wine inventory check routine = Phase 67J optional-services library follow-up.

### 📌 vendor

#### Well water service  `Well water service`

**2026-05-01 · feedback · claude**
Applied. Confirmed: every Well-category template (inspection, water-quality test, shock chlorination) routes through the existing Q15b well_water_service chip. Water Softener lives under Water Treatment though — call out if you want it retagged to Well System.

---

## ✅ Recently Applied (last 30 days)

These have already shipped. Review for retroactive QA only.

### Check Washing Machine Supply Hoses  `Handyman:washer_hoses_spring`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is likely a handyman

### Foundation Walkaround: Cracks and Grading  `Handyman:foundation_walkaround_spring`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is likely a handyman

### Inspect Exterior Caulking Around Windows & Doors  `Handyman:caulking_inspect_spring`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
This is likely a handyman

### Replace Smoke & CO Detector Batteries  `Handyman:smoke_co_batteries_spring`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is likely a handyman

### Fire Extinguisher Annual Check  `Electrical:Fire extinguisher annual check`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is probably for a handyman

### Replace Smoke Detectors  `Electrical:Replace smoke detectors`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is probably for a handyman right?

### Pet waste  `Pet waste`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
This is a routine so that's maybe why no tasks go to it, having a routine for the pet waste removal vendor is fine.

### Well water service  `Well water service`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets make sure any Well task goes to a well water service/vendor here. Also the water softener, well shock etc. the well bundle should go to the well water service.

### Add Carpet + upholstery cleaner as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Carpet + upholstery cleaner" vendor but the catalog doesn't list them.

What they do: Annual deep clean. Often runs at the same time as a window cleaning visit.

Proposal: add "Carpet + upholstery cleaner" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Appliance repair specialist as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Appliance repair specialist" vendor but the catalog doesn't list them.

What they do: Sub-Zero / Wolf / Thermador service. The brands' own factory networks, not a generalist.

Proposal: add "Appliance repair specialist" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Landscape designer as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Landscape designer" vendor but the catalog doesn't list them.

What they do: Annual planting plan + bed redesigns. Distinct from week-to-week landscaping crew.

Proposal: add "Landscape designer" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Locksmith as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Locksmith" vendor but the catalog doesn't list them.

What they do: Re-key after move-in, smart-lock setup, safe service.

Proposal: add "Locksmith" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Pressure washer as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Pressure washer" vendor but the catalog doesn't list them.

What they do: Driveway / siding / deck pressure washing. Annual or every-other-year.

Proposal: add "Pressure washer" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Window cleaner as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Window cleaner" vendor but the catalog doesn't list them.

What they do: Twice-a-year window + screen wash. Often paired with gutter cleaning at the same visit.

Proposal: add "Window cleaner" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Painter as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit 69c9b4c**
Coverage audit found that HNW homes typically have a "Painter" vendor but the catalog doesn't list them.

What they do: Interior + exterior repaint cycles. Most HNW homes redo high-traffic interior every 4-6 years and exterior every 7-10.

Proposal: add "Painter" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Add Pool service as a vendor type

**2026-05-01 · proposal_add · tom · applied 2026-05-01 · commit aebcdb6**
Coverage audit found that HNW homes typically have a "Pool service" vendor but the catalog doesn't list them.

What they do: Weekly chemistry + filter / pump care for pools and spas. Distinct from a house cleaner — pool chemistry needs a specialist.

Proposal: add "Pool service" to DEFAULT_VENDOR_CATEGORIES with a role description and example tasks. The Q15b chip array picks it up automatically.

(Drafted from the Audit tab.)

### Audit: Home gym / equipment service

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets add this to a routines library that has optional services the homeowners can add

### Audit: Vehicle detail

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets add this to a routines library that has optional services the homeowners can add

### Audit: Wine inventory check

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets add this to a routines library that has optional services the homeowners can add

### Audit: Plant care (interior)

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets add this to a routines library that has optional services the homeowners can add

### Audit: Mail + package management

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Lets add this to a routines library that has optional services the homeowners can add

### Annual cooling unit service  `Wine Cellar:Annual cooling unit service`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
not sure if we need a vendor for this one, but always allow the homeowner to add one of their contacts.

### Annual elevator inspection  `Elevator:Annual elevator inspection`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
If a home has an elevator, then we just map to an elevator vendor. that easy.

### Sign up for mosquito and tick season  `Mosquito & Tick:Sign up for mosquito and tick season`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Mosquito and tick should map to the pest control company - unless the person wants to add their own separate vendor but that would pull from pest control vendors. so this should just map to pest control.

### Check foundation for cracks  `Crawl Space:Check foundation for cracks`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
A lot of people will have a basement/waterproofing type of company like American dry basements, or Connecticut basement systems for example - for stuff like this lets just add a Waterproofing & Basement vendor type.

### Inspect for mold or mildew  `Crawl Space:Inspect for mold or mildew`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
A lot of people will have a basement/waterproofing type of company like American dry basements, or Connecticut basement systems for example - for stuff like this lets just add a Waterproofing & Basement vendor type.

### Check vapor barrier condition  `Crawl Space:Check vapor barrier condition`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
A lot of people will have a basement/waterproofing type of company like American dry basements, or Connecticut basement systems for example - for stuff like this lets just add a Waterproofing & Basement vendor type.

### Solar system inspection  `Solar:Professional inspection`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
If the house has solar panels, then we need a Solar vendor.

### Solar panel cleaning  `Solar:Professional panel cleaning`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
If the house has solar panels, then we need a Solar vendor.

### Replace sensor batteries  `Security System:Replace sensor batteries`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Replacing batteries seems like a handyman task to me.

### Annual security system check  `Security System:Verify alarm system`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Shouldn't we have security vendors like ADT, simplisafe, etc? We have those in our DB, lets make sure this task maps to a security vendor type.

### Pool safety fence inspection  `Pool/Spa:Pool safety fence inspection`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

### Inspect hot tub cover and jets  `Pool/Spa:Inspect hot tub cover and jets`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: notes
Before: Detached hot tubs only — attached spillover spas don't have removable covers ...
After: Detached hot tubs only. Attached spillover spas don't have removable covers ...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Detached hot tubs only. Attached spillover spas don't have removable covers ...",
  "from": "Detached hot tubs only — attached spillover spas don't have removable covers ...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "notes"
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6110763**
only for detachable hot tubs.

### Drain and refill hot tub  `Pool/Spa:Drain and refill hot tub`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Rewrite to comply with voice rule:

Rule: no-em-dash
Field: notes
Current: Detached hot tubs only. If your spa shares water with the pool (spillover / a...

We couldn't compute a clean before→after automatically. Claude will rewrite the line to drop the em-dash on the next session.

(Drafted from the Decisions tab. Claude rewrites the text manually on the next session — there's no mechanical fix Tom can preview.)

**Proposed diff:**
```json
{
  "from": "Detached hot tubs only. If your spa shares water with the pool (spillover / a...",
  "kind": "voice_rewrite",
  "rule": "no-em-dash",
  "field": "notes",
  "reason": "We couldn't compute a clean before→after automatically. Claude will rewrite the line to drop the em-dash on the next session."
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6110763**
We may want to have a follow up question about detached hot tubs because you would not do this for a hot tub attached to a pool.

### Pool heater service  `Pool/Spa:Pool heater service`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6110763**
this should be lumped in with pool opening service.

### Inspect pool equipment  `Pool/Spa:Inspect pool equipment`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

### Pool closing and winterization  `Pool/Spa:Professional pool closing/winterization`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

### Pool opening service  `Pool/Spa:Professional pool opening`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
We need a Pool vendor - pools get serviced as a routine so they definitely need a vendor. And that same vendor will likely do the rest of the pool stuff so lets make sure this maps to a pool vendor.

### Schedule exterior window re-caulking  `Windows:Schedule exterior window re-caulking`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
I think this is a handyman task/punch list item right?

### Well system inspection  `Well System:Professional well inspection`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This should map to a well vendor.

### Test water quality  `Well System:Test water quality`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This should map to a Well vendor. A well vendor is different than a plumber. A well vendor will shock the well, chlorinate/chemical it, soften the water, etc.

### Descale tankless heater  `Water Heater:Descale tankless heater`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This is HVAC also for vendor.

### Test T&P relief valve  `Water Heater:Test T&P relief valve`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Shouldn't this map to a plumber or HVAC? Map to whatever water heater and flush water heater map to.

### Flush water heater  `Water Heater:Flush water heater`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
Shouldn't this be the HVAC vendor as the vendor that is mapped to this task?

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: notes
Before: Anode rod inspection is part of the standard flush — pros pull and inspect ev...
After: Anode rod inspection is part of the standard flush. Pros pull and inspect ev...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Anode rod inspection is part of the standard flush. Pros pull and inspect ev...",
  "from": "Anode rod inspection is part of the standard flush — pros pull and inspect ev...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "notes"
}
```

### 8. Any major renovations in the last 10 years?  `q9b_renovations`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: subtitle
Before: Pick anything you've done — we'll remember the year so the maintenance schedu...
After: Pick anything you've done. We'll remember the year so the maintenance schedu...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Pick anything you've done. We'll remember the year so the maintenance schedu...",
  "from": "Pick anything you've done — we'll remember the year so the maintenance schedu...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "subtitle"
}
```

### Merge q9_basement + q9b_renovations  `live-quiz-q9_basement`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q9_basement` — "7. Do you have a basement or crawl space?"
- Kind: `multiSelect`
- Options: 5

**Sub-question:** `q9b_renovations` — "8. Any major renovations in the last 10 years?"
- Kind: `renovationsMultiSelect`
- Options: 10
- Conditional (`dynamicSkip` set): no

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq9b_renovations_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### 8. Any major renovations in the last 10 years?  `live-quiz-q9b_renovations`

**2026-05-01 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
**Voice fix — pre-computed.**

Template "8. Any major renovations in the last 10 years?" has a `no-em-dash` violation in field `subtitle`.

**BEFORE:**
> Pick anything you've done — we'll remember the year so the maintenance schedule reflects it.

**AFTER (proposed):**
> Pick anything you've done. We'll remember the year so the maintenance schedule reflects it.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "subtitle": {
    "to": "Pick anything you've done. We'll remember the year so the maintenance schedule reflects it.",
    "from": "Pick anything you've done — we'll remember the year so the maintenance schedule reflects it."
  }
}
```

### Replace Refrigerator Water Filter  `Appliance:Replace refrigerator water filter`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: description
Before: Haven adds this to your handyman punch list every six months — drop a fresh f...
After: Haven adds this to your handyman punch list every six months. Drop a fresh f...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Haven adds this to your handyman punch list every six months. Drop a fresh f...",
  "from": "Haven adds this to your handyman punch list every six months — drop a fresh f...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "description"
}
```

### 6. What kind of water heater do you have?  `q8_water_heater`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: answer-label-max-words
Field: answerOption.label
Before: Not sure — take a photo and we'll tell you
After: Not sure

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Not sure",
  "from": "Not sure — take a photo and we'll tell you",
  "kind": "voice_fix",
  "rule": "answer-label-max-words",
  "field": "answerOption.label"
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
should we have under the not sure "take a picture and we'll tell you!"

### 13. Security or alarm system?  `live-quiz-q15_security`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "13. Security or alarm system?" has a `no-em-dash` violation in field `subtitle`.

**BEFORE:**
> We won't share specifics — your setup stays private to you and any household members you invite.

**AFTER (proposed):**
> We won't share specifics. Your setup stays private to you and any household members you invite.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "subtitle": {
    "to": "We won't share specifics. Your setup stays private to you and any household members you invite.",
    "from": "We won't share specifics — your setup stays private to you and any household members you invite."
  }
}
```

### 6. What kind of water heater do you have?  `live-quiz-q8_water_heater`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
**Voice fix — pre-computed.**

Template "6. What kind of water heater do you have?" has a `answer-label-max-words` violation in field `answerOption.label`.

**BEFORE:**
> 

**AFTER (proposed):**
> 

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "answerOption.label": {
    "to": "",
    "from": ""
  }
}
```

### 2. What's your exterior siding?  `live-quiz-q2_siding`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "2. What's your exterior siding?" has a `no-em-dash` violation in field `subtitle`.

**BEFORE:**
> Pick all that apply — many homes mix two or three materials.

**AFTER (proposed):**
> Pick all that apply. Many homes mix two or three materials.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "subtitle": {
    "to": "Pick all that apply. Many homes mix two or three materials.",
    "from": "Pick all that apply — many homes mix two or three materials."
  }
}
```

### Replace Refrigerator Water Filter  `Appliance:Replace refrigerator water filter`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: description
Before: Haven adds this to your handyman punch list every six months — drop a fresh f...
After: Haven adds this to your handyman punch list every six months. Drop a fresh f...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Haven adds this to your handyman punch list every six months. Drop a fresh f...",
  "from": "Haven adds this to your handyman punch list every six months — drop a fresh f...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "description"
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 693691c**
Can you please do this for us?

### 13. Security or alarm system?  `q15_security`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: subtitle
Before: We won't share specifics — your setup stays private to you and any household ...
After: We won't share specifics. Your setup stays private to you and any household ...

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "We won't share specifics. Your setup stays private to you and any household ...",
  "from": "We won't share specifics — your setup stays private to you and any household ...",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "subtitle"
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
You should have a "prefer not to answer" option here incase people are cagey about telling an app what their security system is.

### 2. What's your exterior siding?  `q2_siding`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: subtitle
Before: Pick all that apply — many homes mix two or three materials.
After: Pick all that apply. Many homes mix two or three materials.

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Pick all that apply. Many homes mix two or three materials.",
  "from": "Pick all that apply — many homes mix two or three materials.",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "subtitle"
}
```

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 69c9b4c**
Apply voice fix:

Rule: no-em-dash
Field: subtitle
Before: Pick all that apply — many homes mix two or three materials.
After: Pick all that apply. Many homes mix two or three materials.

(Drafted from the Decisions tab. The voice-fix script picks up this note's proposed_diff next session.)

**Proposed diff:**
```json
{
  "to": "Pick all that apply. Many homes mix two or three materials.",
  "from": "Pick all that apply — many homes mix two or three materials.",
  "kind": "voice_fix",
  "rule": "no-em-dash",
  "field": "subtitle"
}
```

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
make sure people can check off multiple not just select one.

### Prune Shrubs and Hedges  `Landscaping:Prune shrubs and hedges`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit aebcdb6**
This shouldn't be added automatically because how do we know if the home has shrubs or things to prune? This should be an opt-in.

### Replace Refrigerator Water Filter  `live-handyman-appliance-replace-refrigerator-water-filter`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "Replace Refrigerator Water Filter" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Haven adds this to your handyman punch list every six months — drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.

**AFTER (proposed):**
> Haven adds this to your handyman punch list every six months. Drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Haven adds this to your handyman punch list every six months. Drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.",
    "from": "Haven adds this to your handyman punch list every six months — drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Replace Refrigerator Water Filter" (templateKey: `Appliance:Replace refrigerator water filter`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

### Replace Refrigerator Water Filter  `live-task-appliance-replace-refrigerator-water-filter`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "Replace Refrigerator Water Filter" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Haven adds this to your handyman punch list every six months — drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.

**AFTER (proposed):**
> Haven adds this to your handyman punch list every six months. Drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Haven adds this to your handyman punch list every six months. Drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.",
    "from": "Haven adds this to your handyman punch list every six months — drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Replace Refrigerator Water Filter" (templateKey: `Appliance:Replace refrigerator water filter`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

### Drain and Refill Hot Tub  `live-task-pool-spa-drain-and-refill-hot-tub`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "Drain and Refill Hot Tub" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Detached hot tubs only. If your spa shares water with the pool (spillover / attached configuration), skip this — the pool service handles drain and refill via the pool seasonal close. Plan 2-3 hours for the standalone drain + refill cycle.

**AFTER (proposed):**
> Detached hot tubs only. If your spa shares water with the pool (spillover / attached configuration), skip this. The pool service handles drain and refill via the pool seasonal close. Plan 2-3 hours for the standalone drain + refill cycle.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Detached hot tubs only. If your spa shares water with the pool (spillover / attached configuration), skip this. The pool service handles drain and refill via the pool seasonal close. Plan 2-3 hours for the standalone drain + refill cycle.",
    "from": "Detached hot tubs only. If your spa shares water with the pool (spillover / attached configuration), skip this — the pool service handles drain and refill via the pool seasonal close. Plan 2-3 hours for the standalone drain + refill cycle."
  }
}
```

### Flush Water Heater  `live-task-water-heater-flush-water-heater`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 40a3c1d**
**Voice fix — pre-computed.**

Template "Flush Water Heater" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Anode rod inspection is part of the standard flush — pros pull and inspect every visit and replace when depleted past ~50%. The replacement requires a partial drain plus a 1-1/16" socket and breaker bar, both of which the plumber already has on the truck.

**AFTER (proposed):**
> Anode rod inspection is part of the standard flush. Pros pull and inspect every visit and replace when depleted past ~50%. The replacement requires a partial drain plus a 1-1/16" socket and breaker bar, both of which the plumber already has on the truck.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Anode rod inspection is part of the standard flush. Pros pull and inspect every visit and replace when depleted past ~50%. The replacement requires a partial drain plus a 1-1/16\" socket and breaker bar, both of which the plumber already has on the truck.",
    "from": "Anode rod inspection is part of the standard flush — pros pull and inspect every visit and replace when depleted past ~50%. The replacement requires a partial drain plus a 1-1/16\" socket and breaker bar, both of which the plumber already has on the truck."
  }
}
```

### Pool Service  `Pool/Spa`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 77b8419**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Landscaping  `Landscaping`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 693691c**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Snow Removal  `Snow Removal`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Plumbing  `Plumbing`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 0367137**
Plumbing is a vendor type,  not a system. A faucet, or well is something a plumber handles for the home. We already have water systems that a Plumber vendor type can service. Plumbing shouldn't be a system, it is a vendor that services plumbing type systems/tasks.

### Pest Control  `Pest Control`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Water Softener / Filtration  `Water Treatment`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 693691c**
This should maybe fold into a parent system for water. Under water that could be town/well/etc, you then have systems also for filtering, softening, etc. So maybe we just have a top level "Water" system. That could be "Well" with its own systems, and within Water we list "well" "filter" and "softener" or whatever else. but all should be folded into water.

### Cleaning Service  `Cleaning Service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Handyman  `Handyman`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a handyman. It is a vendor that is assigned to the house and lives in its own tab within our app for handymen. This is not a system.

### Trash & Recycling  `Trash & Recycling`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 48baf91**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Pet Waste Removal  `Pet Waste`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### Mosquito & Tick Spraying  `Mosquito & Tick`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit bf9d688**
This is not a system, this is a routine. Fold it into a routine but also check to ensure there aren't duplicate routines before doing so.

### 15. Pool or hot tub?  `q12_pool`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
lets make sure all the systems understand the maintenance differences for the both option versus a stand alone hot tub

### 8. Sewer or septic?  `q7_sewer_septic`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
need an option for other, such as a compost toilet. off grid people have that

### 6. Do you have a mortgage on this home?  `q5_mortgage`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
Since we're taking the document vault off I think we should delete this. it's intrusive and better to shorten the quiz.

**2026-04-30 · proposal_delete · tom · applied 2026-05-01 · commit 31c8e12**
This question doesn't really matter since we don't do anything with it. Should we just drop it?

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
This question doesn't really matter since we don't do anything with it. Should we just drop it?

### 5. How did you get this home?  `q4_purchase`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
why do we have this question? I feel like you should just ask if it's a new build and even then can't we scrape the data and only ask if the house was built in the last 12 months?

### Exterior Window Washing  `Window Cleaning:Exterior window washing`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 14f65c5**
most people do this annually max

### Annual Tree Assessment  `Tree Service:Annual tree assessment`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 11bc465**
saw this twice.

### Blind and Curtain Hardware Install  `Handyman:Blind and curtain hardware install`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
not maintenance.

### Fixture Swap and Hardware Refresh  `Handyman:Fixture swap and hardware refresh`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
delete.

### Grab Bar and Safety Hardware Install  `Handyman:Grab bar and safety hardware install`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
no.

### TV Mounting and Cord Cleanup  `Handyman:TV mounting and cord cleanup`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
not maintenance.

### Hang Mirrors, Art, and Shelving  `Handyman:Hang mirrors, art, and shelving`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
this isn't maintenance.

### Interior Caulk Refresh  `Handyman:Interior caulk refresh`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 14f65c5**
every 2-3 years is more reasonable for this.

### Whole-House Relamping  `Handyman:Whole-house relamping`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
no.

### Cabinet and Door Hardware Tune-Up  `Handyman:Cabinet and door hardware tune-up`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
dumb.

### Annual Chimney Sweep  `Chimney:Annual chimney sweep`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 11bc465**
saw this twice?

### Septic Tank Pumping  `Septic System:Septic tank pumping`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 14f65c5**
Every 2 years for us. Depends on the number of people in the home and size of tank.

### Inspect Anode Rod  `Water Heater:Inspect anode rod`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6110763**
This should be part of normal water heater maintenance.

### Whole-Home Humidifier Service  `HVAC:Whole-home humidifier service`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
Who TF is doing this?

### Power Wash Exterior Siding  `Siding/Exterior:Power wash exterior siding`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 14f65c5**
Semi annual for our area if their siding is Vinyl. For a wood house annual is good.

### Treat Moss and Algae  `Roofing:Treat moss and algae`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6110763**
should be /powerwash exterior. Which is more of a biannual task.

### Reseal Flashing and Seams  `Roofing:Reseal flashing and seams`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
I think this is not a thing.

### New task  `local-1777573048534`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 0367137**
I think this is what I accidentally added.

### Replace Cabinet Pulls and Knobs  `Handyman:Replace cabinet pulls and knobs`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
Delete.

### Recaulk Interior Trim and Baseboards  `Handyman:Recaulk interior trim and baseboards`

**2026-04-30 · feedback · tom · applied 2026-04-30 · commit 6b2b7ac**
Delete this. No one does this.

### attom_derive_partial: q4_purchase  `live-quiz-q4_purchase`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz quality proposal — attom_derive_partial.**

**Question:** `q4_purchase` — "5. How did you get this home?"
**Severity:** attom_derive_partial

**Why:** Currency input asks for purchase price + ownership origin. ATTOM has the last sale price + date for purchase paths. The origin question (purchase / inheritance / family / built / cash) still needs to be asked, but the price could pre-fill from ATTOM when origin = purchase.

**Specific fix:** Keep Q4 but pre-fill the price field from PropertyLookupResult.salesHistory[0].price when origin = purchase. Add a 'From public records' caption + 'Edit' affordance.

**Action for Claude next session:**
Don't delete the question — pre-fill it. Build/extend the ATTOMHelloCard component (or a per-field equivalent) that reads from `PropertyLookupResult` and shows confirmable rows. Confirmed values stamp `attributes.{field}_source = "manual"` so future ATTOM refreshes don't override. Falls through to manual input cleanly when ATTOM has no record.

**Proposed diff:**
```json
{
  "fix": "Keep Q4 but pre-fill the price field from PropertyLookupResult.salesHistory[0].price when origin = purchase. Add a 'From public records' caption + 'Edit' affordance.",
  "reason": "Currency input asks for purchase price + ownership origin. ATTOM has the last sale price + date for purchase paths. The origin question (purchase / inheritance / family / built / cash) still needs to be asked, but the price could pre-fill from ATTOM when origin = purchase.",
  "severity": "attom_derive_partial",
  "questionId": "q4_purchase"
}
```

### attom_derive: q2_siding  `live-quiz-q2_siding`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz quality proposal — attom_derive.**

**Question:** `q2_siding` — "2. What's your exterior siding?"
**Severity:** attom_derive

**Why:** Same pattern as Q1 — ATTOM has siding material in the property record for many homes. Pre-fill + confirm, don't ask cold.

**Specific fix:** Bundle into the same ATTOMHelloCard as Q1. Lower priority than Q1 since siding gets less downstream use.

**Action for Claude next session:**
Don't delete the question — pre-fill it. Build/extend the ATTOMHelloCard component (or a per-field equivalent) that reads from `PropertyLookupResult` and shows confirmable rows. Confirmed values stamp `attributes.{field}_source = "manual"` so future ATTOM refreshes don't override. Falls through to manual input cleanly when ATTOM has no record.

**Proposed diff:**
```json
{
  "fix": "Bundle into the same ATTOMHelloCard as Q1. Lower priority than Q1 since siding gets less downstream use.",
  "reason": "Same pattern as Q1 — ATTOM has siding material in the property record for many homes. Pre-fill + confirm, don't ask cold.",
  "severity": "attom_derive",
  "questionId": "q2_siding"
}
```

### attom_derive: q1_roof_material  `live-quiz-q1_roof_material`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz quality proposal — attom_derive.**

**Question:** `q1_roof_material` — "1. Your {yearBuilt} {street} roof: what's on top?"
**Severity:** attom_derive

**Why:** ATTOM property records often carry roof material. The quiz could open with an 'ATTOM Hello Card' that says 'We see your roof is asphalt — sound right?' with confirm or correct, instead of asking cold.

**Specific fix:** Add an ATTOMHelloCard component before Q1 that pre-fills from PropertyLookupResult. Tap any field to correct. Confirmed values stamp `attributes.{field}_source = 'manual'` so future ATTOM refreshes don't override. Falls through to manual input cleanly when ATTOM has no record.

**Action for Claude next session:**
Don't delete the question — pre-fill it. Build/extend the ATTOMHelloCard component (or a per-field equivalent) that reads from `PropertyLookupResult` and shows confirmable rows. Confirmed values stamp `attributes.{field}_source = "manual"` so future ATTOM refreshes don't override. Falls through to manual input cleanly when ATTOM has no record.

**Proposed diff:**
```json
{
  "fix": "Add an ATTOMHelloCard component before Q1 that pre-fills from PropertyLookupResult. Tap any field to correct. Confirmed values stamp `attributes.{field}_source = 'manual'` so future ATTOM refreshes don't override. Falls through to manual input cleanly when ATTOM has no record.",
  "reason": "ATTOM property records often carry roof material. The quiz could open with an 'ATTOM Hello Card' that says 'We see your roof is asphalt — sound right?' with confirm or correct, instead of asking cold.",
  "severity": "attom_derive",
  "questionId": "q1_roof_material"
}
```

### 39. Estate documents you have on hand?  `q29_estate_docs`

**2026-04-30 · proposal_delete · tom · applied 2026-05-01 · commit 2514c78**
We don't do estate management anymore and that got moved to a future release so we should be getting rid of all estate questions including this one.

### drop: q23_vehicle_count  `live-quiz-q23_vehicle_count`

**2026-04-30 · proposal_delete · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz quality proposal — drop.**

**Question:** `q23_vehicle_count` — "31. How many cars do you own?"
**Severity:** drop

**Why:** Vestigial — Q24 (vehicleAdd) handles the primary vehicle directly with a Skip button. Asking for a count first adds friction without value.

**Specific fix:** Delete Q23 from HouseQuizQuestionLibrary.swift. Re-title Q24 to 'Add your primary vehicle' with a Skip option.

**Action for Claude next session:**
Delete the `q23_vehicle_count` entry from `HouseQuizQuestionLibrary.swift`. Add a one-time migration that strips this question's saved answer from `properties.house_quiz_state` JSONB so resume flows don't trip on it. Update `milestoneIndices` (if any) to use stable question IDs not numeric indices, since indices shift after deletion. Bump value-meter deltas if removing this question would zero a milestone bump — redistribute its delta to nearby questions.

**Proposed diff:**
```json
{
  "fix": "Delete Q23 from HouseQuizQuestionLibrary.swift. Re-title Q24 to 'Add your primary vehicle' with a Skip option.",
  "reason": "Vestigial — Q24 (vehicleAdd) handles the primary vehicle directly with a Skip button. Asking for a count first adds friction without value.",
  "severity": "drop",
  "questionId": "q23_vehicle_count"
}
```

### Merge q28_household + q28b_pets  `live-quiz-q28_household`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q28_household` — "37. Who lives here, and who else helps?"
- Kind: `caretakers`
- Options: 5

**Sub-question:** `q28b_pets` — "38. Any pets in the household?"
- Kind: `singleChoice`
- Options: 5
- Conditional (`dynamicSkip` set): no

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq28b_pets_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q25_garage_ev + q25b_ev_charger  `live-quiz-q25_garage_ev`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q25_garage_ev` — "33. What kind of garage do you have?"
- Kind: `singleChoice`
- Options: 5

**Sub-question:** `q25b_ev_charger` — "34. Do you have a Level 2 EV charger?"
- Kind: `singleChoice`
- Options: 2
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq25b_ev_charger_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q18_trash + q18b_trash_day  `live-quiz-q18_trash`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q18_trash` — "25. Trash & recycling?"
- Kind: `singleChoice`
- Options: 3

**Sub-question:** `q18b_trash_day` — "26. Which days should Chez remind you about pickup?"
- Kind: `multiSelect`
- Options: 7
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq18b_trash_day_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q15_security + q15b_household_contractors  `live-quiz-q15_security`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q15_security` — "21. Security or alarm system?"
- Kind: `singleChoice`
- Options: 4

**Sub-question:** `q15b_household_contractors` — "22. Got any pros on speed dial?"
- Kind: `householdContractors`
- Options: 15
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq15b_household_contractors_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q14_irrigation + q14b_irrigation_months  `live-quiz-q14_irrigation`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q14_irrigation` — "19. Sprinkler or irrigation?"
- Kind: `singleChoice`
- Options: 3

**Sub-question:** `q14b_irrigation_months` — "20. Which months does the irrigation system usually run?"
- Kind: `multiSelect`
- Options: 0
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq14b_irrigation_months_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q12_pool + q12c_pool_months  `live-quiz-q12_pool`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q12_pool` — "15. Pool or hot tub?"
- Kind: `singleChoice`
- Options: 5

**Sub-question:** `q12c_pool_months` — "17. Which months does your pool company cover?"
- Kind: `multiSelect`
- Options: 0
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq12c_pool_months_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q12_pool` — "15. Pool or hot tub?"
- Kind: `singleChoice`
- Options: 5

**Sub-question:** `q12b_pool_chemistry` — "16. Saltwater or chlorine?"
- Kind: `singleChoice`
- Options: 3
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq12b_pool_chemistry_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q11_lawn + q11c_landscaping_months  `live-quiz-q11_lawn`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q11_lawn` — "12. Keeping up the {street} yard: you or a pro?"
- Kind: `singleChoice`
- Options: 5

**Sub-question:** `q11c_landscaping_months` — "14. Which months does your landscaping crew usually come?"
- Kind: `multiSelect`
- Options: 0
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq11c_landscaping_months_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q11_lawn` — "12. Keeping up the {street} yard: you or a pro?"
- Kind: `singleChoice`
- Options: 5

**Sub-question:** `q11b_lawn_type` — "13. Natural grass, turf, or both?"
- Kind: `singleChoice`
- Options: 4
- Conditional (`dynamicSkip` set): yes

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq11b_lawn_type_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Merge q3_heating_fuel + q3b_hvac_type  `live-quiz-q3_heating_fuel`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Quiz merge proposal — sub-question fold-in.**

Two consecutive questions could combine into one screen via progressive disclosure:

**Parent:** `q3_heating_fuel` — "3. Heat in a {state} home: what's yours running on?"
- Kind: `singleChoice`
- Options: 6

**Sub-question:** `q3b_hvac_type` — "4. What kind of HVAC system?"
- Kind: `singleChoice`
- Options: 8
- Conditional (`dynamicSkip` set): no

**Action for Claude next session:**
1. In `Haven/Features/Onboarding/HouseQuiz/HouseQuizModels.swift`, add a new `HouseQuizQuestionKind` case named for the combined flow (e.g. `progressivePool`, `progressiveLawn`, `trashWithDays`, `garageWithEV`).
2. In `HouseQuizQuestionLibrary.swift`, replace the parent question's kind with the new combined kind. Move the sub-question's answer options into a structured payload field on `HouseQuizAnswer` (use `payload` JSONB to hold both primary + sub answers as one record).
3. In `HouseQuizView.swift`, add a body renderer for the new kind: parent radio at top, sub-fields revealed below when not in the skip branch.
4. In `HouseQuizViewModel.hydrateEntryState`, restore both primary + sub state on resume from the structured payload.
5. Delete the sub-question entry from `HouseQuizQuestionLibrary`. Migration: `HouseQuizState.migrateMergeq3b_hvac_type_v1()` reads existing answers for the old sub-question and folds them into the new combined answer. Gate on UserDefaults.
6. Update `HouseQuizAnswerMapper` to read both primary + sub from the new payload and fire all the same side effects the old separate flow did. Don't drop any.
7. Sum the value-meter deltas of the two old questions onto the new combined question so the meter math doesn't regress.

### Replace Cabinet Pulls and Knobs ↔ Tighten Loose Cabinet Pulls and Knobs  `live-task-handyman-replace-cabinet-pulls-and-knobs`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Duplicate review — concrete merge analysis.**

Detected 57% title overlap, same systemCategory:

**Template A:** Replace Cabinet Pulls and Knobs
- Description: "Update the kitchen, bath, or built-in cabinet hardware. The handyman handles drilling new holes if the spread changes.…"
- Frequency: As needed · Cost: $75–$200 plus hardware
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Template B:** Tighten Loose Cabinet Pulls and Knobs
- Description: "Snug up hardware throughout the kitchen, bath, and built-ins. Often paired with a hinge tune-up on the same visit.…"
- Frequency: Annually · Cost: $50–$100
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Action for Claude next session:** Decide one of:
1. **Merge** — pick the better description, keep the broader subtype gate, set stableId on the survivor pointing at the deleted one's templateKey so completion history doesn't orphan.
2. **Rename one** — make the distinction concrete (add "winter"/"summer"/"interior"/"exterior" to one title).
3. **Confirm intentional** — close this note with reason; lab can suppress the duplicate detector for this pair via voice-rules.json or a similar allowlist.

### Recaulk Interior Trim and Baseboards ↔ Spot-Paint Interior Trim and Baseboards  `live-task-handyman-recaulk-interior-trim-and-baseboards`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Duplicate review — concrete merge analysis.**

Detected 67% title overlap, same systemCategory:

**Template A:** Recaulk Interior Trim and Baseboards
- Description: "Cut out old caulk that's separated from the wall or trim, lay a fresh bead, and tool it clean. Restores a tight, finished look at the seams.…"
- Frequency: As needed · Cost: $100–$300
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Template B:** Spot-Paint Interior Trim and Baseboards
- Description: "Touch up scuffs and chips on trim, baseboards, and door casings. The handyman matches sheen and color from your existing paint can.…"
- Frequency: As needed · Cost: $75–$200
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Action for Claude next session:** Decide one of:
1. **Merge** — pick the better description, keep the broader subtype gate, set stableId on the survivor pointing at the deleted one's templateKey so completion history doesn't orphan.
2. **Rename one** — make the distinction concrete (add "winter"/"summer"/"interior"/"exterior" to one title).
3. **Confirm intentional** — close this note with reason; lab can suppress the duplicate detector for this pair via voice-rules.json or a similar allowlist.

### Test Sump Pump Battery Backup  `live-handyman-plumbing-test-sump-pump-battery-backup`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Test Sump Pump Battery Backup" (templateKey: `Plumbing:Test sump pump battery backup`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Sump Pump Battery Backup" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years — if it doesn't hold charge, replace before spring rains.

**AFTER (proposed):**
> Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years. If it doesn't hold charge, replace before spring rains.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years. If it doesn't hold charge, replace before spring rains.",
    "from": "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years — if it doesn't hold charge, replace before spring rains."
  }
}
```

### Fire Extinguisher Annual Check  `live-handyman-electrical-fire-extinguisher-annual-check`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Fire Extinguisher Annual Check" (templateKey: `Electrical:Fire extinguisher annual check`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

### Replace Cabinet Pulls and Knobs ↔ Tighten Loose Cabinet Pulls and Knobs  `live-handyman-handyman-replace-cabinet-pulls-and-knobs`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Duplicate review — concrete merge analysis.**

Detected 57% title overlap, same systemCategory:

**Template A:** Replace Cabinet Pulls and Knobs
- Description: "Update the kitchen, bath, or built-in cabinet hardware. The handyman handles drilling new holes if the spread changes.…"
- Frequency: As needed · Cost: $75–$200 plus hardware
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Template B:** Tighten Loose Cabinet Pulls and Knobs
- Description: "Snug up hardware throughout the kitchen, bath, and built-ins. Often paired with a hinge tune-up on the same visit.…"
- Frequency: Annually · Cost: $50–$100
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Action for Claude next session:** Decide one of:
1. **Merge** — pick the better description, keep the broader subtype gate, set stableId on the survivor pointing at the deleted one's templateKey so completion history doesn't orphan.
2. **Rename one** — make the distinction concrete (add "winter"/"summer"/"interior"/"exterior" to one title).
3. **Confirm intentional** — close this note with reason; lab can suppress the duplicate detector for this pair via voice-rules.json or a similar allowlist.

### Recaulk Interior Trim and Baseboards ↔ Spot-Paint Interior Trim and Baseboards  `live-handyman-handyman-recaulk-interior-trim-and-baseboards`

**2026-04-30 · change_request · tom · applied 2026-05-01 · commit 31c8e12**
**Duplicate review — concrete merge analysis.**

Detected 67% title overlap, same systemCategory:

**Template A:** Recaulk Interior Trim and Baseboards
- Description: "Cut out old caulk that's separated from the wall or trim, lay a fresh bead, and tool it clean. Restores a tight, finished look at the seams.…"
- Frequency: As needed · Cost: $100–$300
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Template B:** Spot-Paint Interior Trim and Baseboards
- Description: "Touch up scuffs and chips on trim, baseboards, and door casings. The handyman matches sheen and color from your existing paint can.…"
- Frequency: As needed · Cost: $75–$200
- Seasonal: year-round
- Assignment: either
- Subtypes: []

**Action for Claude next session:** Decide one of:
1. **Merge** — pick the better description, keep the broader subtype gate, set stableId on the survivor pointing at the deleted one's templateKey so completion history doesn't orphan.
2. **Rename one** — make the distinction concrete (add "winter"/"summer"/"interior"/"exterior" to one title).
3. **Confirm intentional** — close this note with reason; lab can suppress the duplicate detector for this pair via voice-rules.json or a similar allowlist.

### Verify Radon Mitigation Fan  `live-handyman-handyman-verify-radon-mitigation-fan`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Verify Radon Mitigation Fan" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Confirm the mitigation fan reads correctly on its manometer — the fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.

**AFTER (proposed):**
> Confirm the mitigation fan reads correctly on its manometer. The fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Confirm the mitigation fan reads correctly on its manometer. The fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.",
    "from": "Confirm the mitigation fan reads correctly on its manometer — the fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement."
  }
}
```

### Test Smoke and CO Detector Alarms  `live-handyman-handyman-smoke-co-alarm-test-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Smoke and CO Detector Alarms" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Fall audio-circuit verification. Press TEST on every alarm — especially important before the heating system starts producing CO.

**AFTER (proposed):**
> Fall audio-circuit verification. Press TEST on every alarm. Especially important before the heating system starts producing CO.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Fall audio-circuit verification. Press TEST on every alarm. Especially important before the heating system starts producing CO.",
    "from": "Fall audio-circuit verification. Press TEST on every alarm — especially important before the heating system starts producing CO."
  }
}
```

### Service Central Vacuum System  `live-handyman-handyman-service-central-vacuum-system`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Service Central Vacuum System" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook — lands on the fall handyman visit.

**AFTER (proposed):**
> Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook. Lands on the fall handyman visit.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook. Lands on the fall handyman visit.",
    "from": "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook — lands on the fall handyman visit."
  }
}
```

### Replace Smoke & CO Detector Batteries  `live-handyman-handyman-smoke-co-batteries-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Replace Smoke & CO Detector Batteries" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Fall battery swap — daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.

**AFTER (proposed):**
> Fall battery swap. Daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Fall battery swap. Daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.",
    "from": "Fall battery swap — daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely."
  }
}
```

### Check Attic Insulation Coverage  `live-handyman-handyman-attic-insulation-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Check Attic Insulation Coverage" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Eye-check the attic — look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.

**AFTER (proposed):**
> Eye-check the attic. Look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Eye-check the attic. Look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.",
    "from": "Eye-check the attic — look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference."
  }
}
```

### Ceiling Fan Direction Switch (winter)  `live-handyman-handyman-ceiling-fan-winter`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Ceiling Fan Direction Switch (winter)" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Flip ceiling fans to clockwise for gentle upward airflow — pushes warm air pooling at the ceiling back down into the room.

**AFTER (proposed):**
> Flip ceiling fans to clockwise for gentle upward airflow. Pushes warm air pooling at the ceiling back down into the room.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Flip ceiling fans to clockwise for gentle upward airflow. Pushes warm air pooling at the ceiling back down into the room.",
    "from": "Flip ceiling fans to clockwise for gentle upward airflow — pushes warm air pooling at the ceiling back down into the room."
  }
}
```

### Fall Handyman Visit  `live-handyman-handyman-fall-handyman-visit`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit d73d461**
**Voice fix — pre-computed.**

Template "Fall Handyman Visit" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> 
What's typically covered in a fall handyman visit:

Weatherization
• Exterior faucet winterization and hose bib covers
• Storm door and weatherstripping check (windows + doors)
• Window AC removal and storage (if applicable)
• Door hinge and lock lubrication

HVAC
• Air filter swap (heating season)
• Attic insulation check before heating season

Generator (if applicable)
• Oil level check
• Confirm weekly exercise cycle visually

Safety
• Smoke and CO detector battery swap
• Smoke detector age check (replace if 9+ years — bring spares)
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)

Plumbing
• Drain cleaning and sink trap check
• Hose bib shutoff valve test

Exterior
• Seal gaps around pipes and utility entries (pest prevention)
• Firebox and damper check (wood-burning fireplaces)

Other (conditional)
• Central vacuum service (if applicable)
• Radon mitigation fan check (if applicable)

Add anything you've been meaning to get to.


**AFTER (proposed):**
> What's typically covered in a fall handyman visit: Weatherization
• Exterior faucet winterization and hose bib covers
• Storm door and weatherstripping check (windows + doors)
• Window AC removal and storage (if applicable)
• Door hinge and lock lubrication HVAC
• Air filter swap (heating season)
• Attic insulation check before heating season Generator (if applicable)
• Oil level check
• Confirm weekly exercise cycle visually Safety
• Smoke and CO detector battery swap
• Smoke detector age check (replace if 9+ years. Bring spares)
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation) Plumbing
• Drain cleaning and sink trap check
• Hose bib shutoff valve test Exterior
• Seal gaps around pipes and utility entries (pest prevention)
• Firebox and damper check (wood-burning fireplaces) Other (conditional)
• Central vacuum service (if applicable)
• Radon mitigation fan check (if applicable) Add anything you've been meaning to get to.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "What's typically covered in a fall handyman visit: Weatherization\n• Exterior faucet winterization and hose bib covers\n• Storm door and weatherstripping check (windows + doors)\n• Window AC removal and storage (if applicable)\n• Door hinge and lock lubrication HVAC\n• Air filter swap (heating season)\n• Attic insulation check before heating season Generator (if applicable)\n• Oil level check\n• Confirm weekly exercise cycle visually Safety\n• Smoke and CO detector battery swap\n• Smoke detector age check (replace if 9+ years. Bring spares)\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation) Plumbing\n• Drain cleaning and sink trap check\n• Hose bib shutoff valve test Exterior\n• Seal gaps around pipes and utility entries (pest prevention)\n• Firebox and damper check (wood-burning fireplaces) Other (conditional)\n• Central vacuum service (if applicable)\n• Radon mitigation fan check (if applicable) Add anything you've been meaning to get to.",
    "from": "\nWhat's typically covered in a fall handyman visit:\n\nWeatherization\n• Exterior faucet winterization and hose bib covers\n• Storm door and weatherstripping check (windows + doors)\n• Window AC removal and storage (if applicable)\n• Door hinge and lock lubrication\n\nHVAC\n• Air filter swap (heating season)\n• Attic insulation check before heating season\n\nGenerator (if applicable)\n• Oil level check\n• Confirm weekly exercise cycle visually\n\nSafety\n• Smoke and CO detector battery swap\n• Smoke detector age check (replace if 9+ years — bring spares)\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n\nPlumbing\n• Drain cleaning and sink trap check\n• Hose bib shutoff valve test\n\nExterior\n• Seal gaps around pipes and utility entries (pest prevention)\n• Firebox and damper check (wood-burning fireplaces)\n\nOther (conditional)\n• Central vacuum service (if applicable)\n• Radon mitigation fan check (if applicable)\n\nAdd anything you've been meaning to get to.\n"
  }
}
```

### Test Sump Pump Function  `live-handyman-handyman-sump-pump-test-spring`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Sump Pump Function" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Distinct from the Phase 62 battery backup test — this one confirms the primary pump still cycles.

**AFTER (proposed):**
> Distinct from the Phase 62 battery backup test. This one confirms the primary pump still cycles.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Distinct from the Phase 62 battery backup test. This one confirms the primary pump still cycles.",
    "from": "Distinct from the Phase 62 battery backup test — this one confirms the primary pump still cycles."
  }
}
```

### Test Smoke and CO Detector Alarms  `live-handyman-handyman-smoke-co-alarm-test-spring`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Smoke and CO Detector Alarms" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap — this verifies the audio circuit.

**AFTER (proposed):**
> Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap. This verifies the audio circuit.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap. This verifies the audio circuit.",
    "from": "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap — this verifies the audio circuit."
  }
}
```

### Ceiling Fan Direction Switch (summer)  `live-handyman-handyman-ceiling-fan-summer`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Ceiling Fan Direction Switch (summer)" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only — the handyman handles the ones requiring a ladder.

**AFTER (proposed):**
> Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only. The handyman handles the ones requiring a ladder.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only. The handyman handles the ones requiring a ladder.",
    "from": "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only — the handyman handles the ones requiring a ladder."
  }
}
```

### Spring Handyman Visit  `live-handyman-handyman-spring-handyman-visit`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit d73d461**
**Voice fix — pre-computed.**

Template "Spring Handyman Visit" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> 
What's typically covered in a spring handyman visit:

HVAC
• Air filter swap (buy a case, swap during visit)
• Mini-split filter rinse (if applicable)

Plumbing
• Washing machine supply hose visual check
• Sump pump test (if applicable)
• Well cap and pressure tank visual (if well home)
• Water softener brine tank visual (if applicable)
• Whole-house filter swap (if applicable)

Exterior
• Caulking touch-up around windows and doors
• Driveway crack sealcoat spot-fill
• Deck/fence screw check
• Foundation grading walkaround
• Retaining wall condition check

Safety
• Smoke and CO detector battery swap
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)
• Test GFCI outlets

Appliances
• Refrigerator coil vacuum (if accessible)
• Dishwasher spray arm clean (if not covered by housekeeper)
• Ice maker filter replacement (if due)

Other (conditional)
• Crawl space visual for moisture (if applicable)
• Dehumidifier operation test (if applicable)
• Septic drain field walkaround (if applicable)
• Smart leak system test (if applicable)
• Turf drainage spot-check (synthetic turf homes)

Add anything you've been meaning to get to — that's what the handyman is for.


**AFTER (proposed):**
> What's typically covered in a spring handyman visit: HVAC
• Air filter swap (buy a case, swap during visit)
• Mini-split filter rinse (if applicable) Plumbing
• Washing machine supply hose visual check
• Sump pump test (if applicable)
• Well cap and pressure tank visual (if well home)
• Water softener brine tank visual (if applicable)
• Whole-house filter swap (if applicable) Exterior
• Caulking touch-up around windows and doors
• Driveway crack sealcoat spot-fill
• Deck/fence screw check
• Foundation grading walkaround
• Retaining wall condition check Safety
• Smoke and CO detector battery swap
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)
• Test GFCI outlets Appliances
• Refrigerator coil vacuum (if accessible)
• Dishwasher spray arm clean (if not covered by housekeeper)
• Ice maker filter replacement (if due) Other (conditional)
• Crawl space visual for moisture (if applicable)
• Dehumidifier operation test (if applicable)
• Septic drain field walkaround (if applicable)
• Smart leak system test (if applicable)
• Turf drainage spot-check (synthetic turf homes) Add anything you've been meaning to get to. That's what the handyman is for.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "What's typically covered in a spring handyman visit: HVAC\n• Air filter swap (buy a case, swap during visit)\n• Mini-split filter rinse (if applicable) Plumbing\n• Washing machine supply hose visual check\n• Sump pump test (if applicable)\n• Well cap and pressure tank visual (if well home)\n• Water softener brine tank visual (if applicable)\n• Whole-house filter swap (if applicable) Exterior\n• Caulking touch-up around windows and doors\n• Driveway crack sealcoat spot-fill\n• Deck/fence screw check\n• Foundation grading walkaround\n• Retaining wall condition check Safety\n• Smoke and CO detector battery swap\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n• Test GFCI outlets Appliances\n• Refrigerator coil vacuum (if accessible)\n• Dishwasher spray arm clean (if not covered by housekeeper)\n• Ice maker filter replacement (if due) Other (conditional)\n• Crawl space visual for moisture (if applicable)\n• Dehumidifier operation test (if applicable)\n• Septic drain field walkaround (if applicable)\n• Smart leak system test (if applicable)\n• Turf drainage spot-check (synthetic turf homes) Add anything you've been meaning to get to. That's what the handyman is for.",
    "from": "\nWhat's typically covered in a spring handyman visit:\n\nHVAC\n• Air filter swap (buy a case, swap during visit)\n• Mini-split filter rinse (if applicable)\n\nPlumbing\n• Washing machine supply hose visual check\n• Sump pump test (if applicable)\n• Well cap and pressure tank visual (if well home)\n• Water softener brine tank visual (if applicable)\n• Whole-house filter swap (if applicable)\n\nExterior\n• Caulking touch-up around windows and doors\n• Driveway crack sealcoat spot-fill\n• Deck/fence screw check\n• Foundation grading walkaround\n• Retaining wall condition check\n\nSafety\n• Smoke and CO detector battery swap\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n• Test GFCI outlets\n\nAppliances\n• Refrigerator coil vacuum (if accessible)\n• Dishwasher spray arm clean (if not covered by housekeeper)\n• Ice maker filter replacement (if due)\n\nOther (conditional)\n• Crawl space visual for moisture (if applicable)\n• Dehumidifier operation test (if applicable)\n• Septic drain field walkaround (if applicable)\n• Smart leak system test (if applicable)\n• Turf drainage spot-check (synthetic turf homes)\n\nAdd anything you've been meaning to get to — that's what the handyman is for.\n"
  }
}
```

### Bundle: "Landscaping Spring  `live-task-landscaping-top-up-turf-infill`

**2026-04-30 · proposal_add · tom · applied 2026-05-01 · commit a3f9d8e**
**Bundle-merge proposal — pre-structured.**

Pattern match: 4 standalone templates share systemCategory=`"Landscaping` + seasonalTiming=`Spring` + assignmentType=`vendor"`. Same shape as the existing Generator:annual / Roofing:spring / Pool/Spa:opening bundles. The vendor handles all of them in one visit anyway, so the homeowner shouldn't see 4 separate task rows.

**Proposed:**
- bundleId: `"Landscaping:spring`
- bundleTitle: "Spring "Landscaping Service" (set on the FIRST template only — that becomes the parent)
- Templates to fold in:
  1. Top Up Turf Infill (templateKey: Landscaping:Top up turf infill)
  2. Power Rake and Groom Turf (templateKey: Landscaping:Power rake and groom turf)
  3. Deep Clean Synthetic Turf (templateKey: Landscaping:Deep clean synthetic turf)
  4. Outdoor Lighting Service (templateKey: Landscaping:Outdoor lighting service)

**Action for Claude next session:**
1. In Haven/Features/Property/Services/MaintenanceTemplates.swift, add `bundleId: ""Landscaping:spring"` to all 4 templates listed.
2. Set `bundleTitle: "Spring "Landscaping Service"` on the FIRST template in the list (the parent — its title becomes the homeowner's task title).
3. Verify each child gets its templateKey preserved via stableId so existing completion history doesn't orphan.
4. Confirm AppState.backfillBundlesOnceIfNeeded re-runs (bump migration key to v_"Landscaping_spring) so existing households' standalone tasks fold into the new bundle parent.
5. xcodebuild -scheme Chez to confirm clean compile.

**Alternative:** if these templates have meaningfully different scheduling (e.g., one needs to happen 4 weeks before the others), leave them standalone.

**Proposed diff:**
```json
{
  "members": [
    {
      "title": "Top Up Turf Infill",
      "templateKey": "Landscaping:Top up turf infill"
    },
    {
      "title": "Power Rake and Groom Turf",
      "templateKey": "Landscaping:Power rake and groom turf"
    },
    {
      "title": "Deep Clean Synthetic Turf",
      "templateKey": "Landscaping:Deep clean synthetic turf"
    },
    {
      "title": "Outdoor Lighting Service",
      "templateKey": "Landscaping:Outdoor lighting service"
    }
  ],
  "bundleId": "\"Landscaping:spring",
  "bundleTitle": "Spring \"Landscaping Service",
  "parentTemplateKey": "Landscaping:Top up turf infill"
}
```

### Bundle: "Chimney Fall  `live-task-chimney-annual-chimney-sweep`

**2026-04-30 · proposal_add · tom · applied 2026-05-01 · commit a3f9d8e**
**Bundle-merge proposal — pre-structured.**

Pattern match: 3 standalone templates share systemCategory=`"Chimney` + seasonalTiming=`Fall` + assignmentType=`vendor"`. Same shape as the existing Generator:annual / Roofing:spring / Pool/Spa:opening bundles. The vendor handles all of them in one visit anyway, so the homeowner shouldn't see 3 separate task rows.

**Proposed:**
- bundleId: `"Chimney:fall`
- bundleTitle: "Fall "Chimney Service" (set on the FIRST template only — that becomes the parent)
- Templates to fold in:
  1. Annual Chimney Sweep (templateKey: Chimney:Annual chimney sweep)
  2. Inspect Chimney Cap and Crown (templateKey: Chimney:Inspect chimney cap and crown)
  3. Annual Gas Fireplace Service (templateKey: Chimney:Annual gas fireplace service)

**Action for Claude next session:**
1. In Haven/Features/Property/Services/MaintenanceTemplates.swift, add `bundleId: ""Chimney:fall"` to all 3 templates listed.
2. Set `bundleTitle: "Fall "Chimney Service"` on the FIRST template in the list (the parent — its title becomes the homeowner's task title).
3. Verify each child gets its templateKey preserved via stableId so existing completion history doesn't orphan.
4. Confirm AppState.backfillBundlesOnceIfNeeded re-runs (bump migration key to v_"Chimney_fall) so existing households' standalone tasks fold into the new bundle parent.
5. xcodebuild -scheme Chez to confirm clean compile.

**Alternative:** if these templates have meaningfully different scheduling (e.g., one needs to happen 4 weeks before the others), leave them standalone.

**Proposed diff:**
```json
{
  "members": [
    {
      "title": "Annual Chimney Sweep",
      "templateKey": "Chimney:Annual chimney sweep"
    },
    {
      "title": "Inspect Chimney Cap and Crown",
      "templateKey": "Chimney:Inspect chimney cap and crown"
    },
    {
      "title": "Annual Gas Fireplace Service",
      "templateKey": "Chimney:Annual gas fireplace service"
    }
  ],
  "bundleId": "\"Chimney:fall",
  "bundleTitle": "Fall \"Chimney Service",
  "parentTemplateKey": "Chimney:Annual chimney sweep"
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Chimney Sweep" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Schedule before first use each season. Each chimney is swept separately — if you have multiple flues, mention it so the sweep allocates the right amount of time.

**AFTER (proposed):**
> Schedule before first use each season. Each chimney is swept separately. If you have multiple flues, mention it so the sweep allocates the right amount of time.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Schedule before first use each season. Each chimney is swept separately. If you have multiple flues, mention it so the sweep allocates the right amount of time.",
    "from": "Schedule before first use each season. Each chimney is swept separately — if you have multiple flues, mention it so the sweep allocates the right amount of time."
  }
}
```

### Bundle: "HVAC Fall  `live-task-hvac-professional-hvac-tune-up-heating`

**2026-04-30 · proposal_add · tom · applied 2026-05-01 · commit a3f9d8e**
**Bundle-merge proposal — pre-structured.**

Pattern match: 4 standalone templates share systemCategory=`"HVAC` + seasonalTiming=`Fall` + assignmentType=`vendor"`. Same shape as the existing Generator:annual / Roofing:spring / Pool/Spa:opening bundles. The vendor handles all of them in one visit anyway, so the homeowner shouldn't see 4 separate task rows.

**Proposed:**
- bundleId: `"HVAC:fall`
- bundleTitle: "Fall "HVAC Service" (set on the FIRST template only — that becomes the parent)
- Templates to fold in:
  1. HVAC Tune-Up (heating) (templateKey: HVAC:Professional HVAC tune-up (heating))
  2. Bleed Radiators (templateKey: HVAC:Bleed radiators)
  3. Annual Boiler Service (templateKey: HVAC:Annual boiler service)
  4. Whole-Home Humidifier Service (templateKey: HVAC:Whole-home humidifier service)

**Action for Claude next session:**
1. In Haven/Features/Property/Services/MaintenanceTemplates.swift, add `bundleId: ""HVAC:fall"` to all 4 templates listed.
2. Set `bundleTitle: "Fall "HVAC Service"` on the FIRST template in the list (the parent — its title becomes the homeowner's task title).
3. Verify each child gets its templateKey preserved via stableId so existing completion history doesn't orphan.
4. Confirm AppState.backfillBundlesOnceIfNeeded re-runs (bump migration key to v_"HVAC_fall) so existing households' standalone tasks fold into the new bundle parent.
5. xcodebuild -scheme Chez to confirm clean compile.

**Alternative:** if these templates have meaningfully different scheduling (e.g., one needs to happen 4 weeks before the others), leave them standalone.

**Proposed diff:**
```json
{
  "members": [
    {
      "title": "HVAC Tune-Up (heating)",
      "templateKey": "HVAC:Professional HVAC tune-up (heating)"
    },
    {
      "title": "Bleed Radiators",
      "templateKey": "HVAC:Bleed radiators"
    },
    {
      "title": "Annual Boiler Service",
      "templateKey": "HVAC:Annual boiler service"
    },
    {
      "title": "Whole-Home Humidifier Service",
      "templateKey": "HVAC:Whole-home humidifier service"
    }
  ],
  "bundleId": "\"HVAC:fall",
  "bundleTitle": "Fall \"HVAC Service",
  "parentTemplateKey": "HVAC:Professional HVAC tune-up (heating)"
}
```

### Test Sump Pump Battery Backup  `live-task-plumbing-test-sump-pump-battery-backup`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Test Sump Pump Battery Backup" (templateKey: `Plumbing:Test sump pump battery backup`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Sump Pump Battery Backup" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years — if it doesn't hold charge, replace before spring rains.

**AFTER (proposed):**
> Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years. If it doesn't hold charge, replace before spring rains.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years. If it doesn't hold charge, replace before spring rains.",
    "from": "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years — if it doesn't hold charge, replace before spring rains."
  }
}
```

### Fire Extinguisher Annual Check  `live-task-electrical-fire-extinguisher-annual-check`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 872eefb**
**Punch-list re-route proposal.**

Template "Fire Extinguisher Annual Check" (templateKey: `Electrical:Fire extinguisher annual check`) currently seeds as a `maintenance_tasks` row at quiz completion. Day1TaskCurator then re-parents it under the singleton handyman routine via `parent_routine_id` — which hides it from the main task list but leaves it in maintenance_tasks anyway.

Per Tom's 5-tier model, this is tier 4 ("tasks just for handymen"). It should seed directly as a `handyman_punch_items` row, skipping maintenance_tasks entirely. The homeowner finds it on the Handyman tab's punch list — the only place it belongs.

**Action for Claude next session:**
1. In `MaintenanceTaskReconciler.reconcile(...)`, when the template's tier resolves to handyman (routingOverride .diyDefault/.diyCapable + effort ≤ 60 + no safety floor), insert into `handyman_punch_items` instead of `maintenance_tasks`.
2. The punch item carries `source: "auto_seed_handyman_tier"` so the punch list view can sort auto-populated items separately from manual additions.
3. Add a one-time migration in `AppState.initialize()` (gated on `hasMigratedHandymanTierToPunchItems_v1`) that finds existing `maintenance_tasks` rows for this templateKey + archives them + creates equivalent `handyman_punch_items` rows.
4. Verify Day1TaskCurator no longer needs to re-parent this template (it'll be skipped at the source).
5. Update CLAUDE.md to document: handyman-tier templates seed punch items directly.

**Bidirectional UI affordances** (separate but related work):
- Punch item → Task: "Schedule as a task" action on each punch item card. Creates a maintenance_task with `scheduled_date` set, archives the punch item with reason `promoted_to_task`.
- Task → Punch item: "Move to handyman list" action on each task detail sheet (already exists per Phase 56.4 docs). Archives the task with reason `moved_to_handyman_punch`, creates the punch item.

**Proposed diff:**
```json
{
  "to": {
    "destination": "handyman_punch_items"
  },
  "from": {
    "destination": "maintenance_tasks",
    "parent_routine_id": "<handyman routine UUID>"
  }
}
```

### Quarterly Elevator Service  `live-task-elevator-quarterly-elevator-service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Quarterly Elevator Service" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Most homes are on a quarterly service contract with the installer or a local specialist. If you've never used the emergency phone, this visit is when to test it — phone batteries die silently and you don't want to find out you can't call out from inside the cab during the next power blip.

**AFTER (proposed):**
> Most homes are on a quarterly service contract with the installer or a local specialist. If you've never used the emergency phone, this visit is when to test it. Phone batteries die silently and you don't want to find out you can't call out from inside the cab during the next power blip.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Most homes are on a quarterly service contract with the installer or a local specialist. If you've never used the emergency phone, this visit is when to test it. Phone batteries die silently and you don't want to find out you can't call out from inside the cab during the next power blip.",
    "from": "Most homes are on a quarterly service contract with the installer or a local specialist. If you've never used the emergency phone, this visit is when to test it — phone batteries die silently and you don't want to find out you can't call out from inside the cab during the next power blip."
  }
}
```

### Annual Cooling Unit Service  `live-task-wine-cellar-annual-cooling-unit-service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Cooling Unit Service" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Cooling unit failures can ruin a collection overnight — fine wine starts heat-damaging at 75°F+, and most modern units have no built-in alarm if the compressor fails on a Friday night. This is not a category to skip. Most manufacturer warranties require annual documented service.

**AFTER (proposed):**
> Cooling unit failures can ruin a collection overnight. Fine wine starts heat-damaging at 75°F+, and most modern units have no built-in alarm if the compressor fails on a Friday night. This is not a category to skip. Most manufacturer warranties require annual documented service.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Cooling unit failures can ruin a collection overnight. Fine wine starts heat-damaging at 75°F+, and most modern units have no built-in alarm if the compressor fails on a Friday night. This is not a category to skip. Most manufacturer warranties require annual documented service.",
    "from": "Cooling unit failures can ruin a collection overnight — fine wine starts heat-damaging at 75°F+, and most modern units have no built-in alarm if the compressor fails on a Friday night. This is not a category to skip. Most manufacturer warranties require annual documented service."
  }
}
```

### Annual Elevator Inspection  `live-task-elevator-annual-elevator-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Elevator Inspection" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Keep the certificate on file with other estate documents. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included — but the certificate is something you need to pull and file yourself.

**AFTER (proposed):**
> Keep the certificate on file with other estate documents. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included. But the certificate is something you need to pull and file yourself.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Keep the certificate on file with other estate documents. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included. But the certificate is something you need to pull and file yourself.",
    "from": "Keep the certificate on file with other estate documents. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included — but the certificate is something you need to pull and file yourself."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Elevator Inspection" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators — failing to keep current can void homeowner's insurance for elevator-related claims.

**AFTER (proposed):**
> Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators. Failing to keep current can void homeowner's insurance for elevator-related claims.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators. Failing to keep current can void homeowner's insurance for elevator-related claims.",
    "from": "Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators — failing to keep current can void homeowner's insurance for elevator-related claims."
  }
}
```

### Annual Exterior Power Washing  `live-task-pressure-washing-annual-exterior-power-washing`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Exterior Power Washing" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Schedule for late spring after the heaviest pollen settles — that way the cleaning lasts the longest into summer. Hardscape (concrete, stone, pavers) is more forgiving and can take higher pressure if needed. Always confirm with the vendor that they're using soft-wash on siding before they start.

**AFTER (proposed):**
> Schedule for late spring after the heaviest pollen settles. That way the cleaning lasts the longest into summer. Hardscape (concrete, stone, pavers) is more forgiving and can take higher pressure if needed. Always confirm with the vendor that they're using soft-wash on siding before they start.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Schedule for late spring after the heaviest pollen settles. That way the cleaning lasts the longest into summer. Hardscape (concrete, stone, pavers) is more forgiving and can take higher pressure if needed. Always confirm with the vendor that they're using soft-wash on siding before they start.",
    "from": "Schedule for late spring after the heaviest pollen settles — that way the cleaning lasts the longest into summer. Hardscape (concrete, stone, pavers) is more forgiving and can take higher pressure if needed. Always confirm with the vendor that they're using soft-wash on siding before they start."
  }
}
```

### Sign Up for Mosquito and Tick Season  `live-task-mosquito-tick-sign-up-for-mosquito-and-tick-season`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Sign Up for Mosquito and Tick Season" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Most mosquito and tick vendors run seasonal programs — an every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule.

**AFTER (proposed):**
> Most mosquito and tick vendors run seasonal programs. An every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Most mosquito and tick vendors run seasonal programs. An every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule.",
    "from": "Most mosquito and tick vendors run seasonal programs — an every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule."
  }
}
```

### Whole-House Relamping  `live-task-handyman-whole-house-relamping`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Whole-House Relamping" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach — high ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate "I'll get to it" moments.

**AFTER (proposed):**
> Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach. High ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate "I'll get to it" moments.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach. High ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate \"I'll get to it\" moments.",
    "from": "Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach — high ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate \"I'll get to it\" moments."
  }
}
```

### Smart Home Battery Sweep  `live-task-handyman-smart-home-battery-sweep`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Smart Home Battery Sweep" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices — this catches the ones the owner never thinks about until they die.

**AFTER (proposed):**
> Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices. This catches the ones the owner never thinks about until they die.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices. This catches the ones the owner never thinks about until they die.",
    "from": "Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices — this catches the ones the owner never thinks about until they die."
  }
}
```

### Ceiling Fan Direction Switch (winter)  `live-task-handyman-ceiling-fan-winter`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Ceiling Fan Direction Switch (winter)" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Flip ceiling fans to clockwise for gentle upward airflow — pushes warm air pooling at the ceiling back down into the room.

**AFTER (proposed):**
> Flip ceiling fans to clockwise for gentle upward airflow. Pushes warm air pooling at the ceiling back down into the room.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Flip ceiling fans to clockwise for gentle upward airflow. Pushes warm air pooling at the ceiling back down into the room.",
    "from": "Flip ceiling fans to clockwise for gentle upward airflow — pushes warm air pooling at the ceiling back down into the room."
  }
}
```

### Test Smoke and CO Detector Alarms  `live-task-handyman-smoke-co-alarm-test-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Smoke and CO Detector Alarms" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Fall audio-circuit verification. Press TEST on every alarm — especially important before the heating system starts producing CO.

**AFTER (proposed):**
> Fall audio-circuit verification. Press TEST on every alarm. Especially important before the heating system starts producing CO.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Fall audio-circuit verification. Press TEST on every alarm. Especially important before the heating system starts producing CO.",
    "from": "Fall audio-circuit verification. Press TEST on every alarm — especially important before the heating system starts producing CO."
  }
}
```

### Check Attic Insulation Coverage  `live-task-handyman-attic-insulation-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Check Attic Insulation Coverage" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Eye-check the attic — look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.

**AFTER (proposed):**
> Eye-check the attic. Look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Eye-check the attic. Look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.",
    "from": "Eye-check the attic — look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference."
  }
}
```

### Replace Smoke & CO Detector Batteries  `live-task-handyman-smoke-co-batteries-fall`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Replace Smoke & CO Detector Batteries" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Fall battery swap — daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.

**AFTER (proposed):**
> Fall battery swap. Daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Fall battery swap. Daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.",
    "from": "Fall battery swap — daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely."
  }
}
```

### Ceiling Fan Direction Switch (summer)  `live-task-handyman-ceiling-fan-summer`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Ceiling Fan Direction Switch (summer)" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only — the handyman handles the ones requiring a ladder.

**AFTER (proposed):**
> Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only. The handyman handles the ones requiring a ladder.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only. The handyman handles the ones requiring a ladder.",
    "from": "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only — the handyman handles the ones requiring a ladder."
  }
}
```

### Test Smoke and CO Detector Alarms  `live-task-handyman-smoke-co-alarm-test-spring`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Smoke and CO Detector Alarms" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap — this verifies the audio circuit.

**AFTER (proposed):**
> Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap. This verifies the audio circuit.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap. This verifies the audio circuit.",
    "from": "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap — this verifies the audio circuit."
  }
}
```

### Test Sump Pump Function  `live-task-handyman-sump-pump-test-spring`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Sump Pump Function" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Distinct from the Phase 62 battery backup test — this one confirms the primary pump still cycles.

**AFTER (proposed):**
> Distinct from the Phase 62 battery backup test. This one confirms the primary pump still cycles.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Distinct from the Phase 62 battery backup test. This one confirms the primary pump still cycles.",
    "from": "Distinct from the Phase 62 battery backup test — this one confirms the primary pump still cycles."
  }
}
```

### Verify Radon Mitigation Fan  `live-task-handyman-verify-radon-mitigation-fan`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Verify Radon Mitigation Fan" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Confirm the mitigation fan reads correctly on its manometer — the fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.

**AFTER (proposed):**
> Confirm the mitigation fan reads correctly on its manometer. The fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Confirm the mitigation fan reads correctly on its manometer. The fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.",
    "from": "Confirm the mitigation fan reads correctly on its manometer — the fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement."
  }
}
```

### Service Central Vacuum System  `live-task-handyman-service-central-vacuum-system`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Service Central Vacuum System" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook — lands on the fall handyman visit.

**AFTER (proposed):**
> Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook. Lands on the fall handyman visit.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook. Lands on the fall handyman visit.",
    "from": "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook — lands on the fall handyman visit."
  }
}
```

### Fall Handyman Visit  `live-task-handyman-fall-handyman-visit`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit d73d461**
**Voice fix — pre-computed.**

Template "Fall Handyman Visit" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> 
What's typically covered in a fall handyman visit:

Weatherization
• Exterior faucet winterization and hose bib covers
• Storm door and weatherstripping check (windows + doors)
• Window AC removal and storage (if applicable)
• Door hinge and lock lubrication

HVAC
• Air filter swap (heating season)
• Attic insulation check before heating season

Generator (if applicable)
• Oil level check
• Confirm weekly exercise cycle visually

Safety
• Smoke and CO detector battery swap
• Smoke detector age check (replace if 9+ years — bring spares)
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)

Plumbing
• Drain cleaning and sink trap check
• Hose bib shutoff valve test

Exterior
• Seal gaps around pipes and utility entries (pest prevention)
• Firebox and damper check (wood-burning fireplaces)

Other (conditional)
• Central vacuum service (if applicable)
• Radon mitigation fan check (if applicable)

Add anything you've been meaning to get to.


**AFTER (proposed):**
> What's typically covered in a fall handyman visit: Weatherization
• Exterior faucet winterization and hose bib covers
• Storm door and weatherstripping check (windows + doors)
• Window AC removal and storage (if applicable)
• Door hinge and lock lubrication HVAC
• Air filter swap (heating season)
• Attic insulation check before heating season Generator (if applicable)
• Oil level check
• Confirm weekly exercise cycle visually Safety
• Smoke and CO detector battery swap
• Smoke detector age check (replace if 9+ years. Bring spares)
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation) Plumbing
• Drain cleaning and sink trap check
• Hose bib shutoff valve test Exterior
• Seal gaps around pipes and utility entries (pest prevention)
• Firebox and damper check (wood-burning fireplaces) Other (conditional)
• Central vacuum service (if applicable)
• Radon mitigation fan check (if applicable) Add anything you've been meaning to get to.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "What's typically covered in a fall handyman visit: Weatherization\n• Exterior faucet winterization and hose bib covers\n• Storm door and weatherstripping check (windows + doors)\n• Window AC removal and storage (if applicable)\n• Door hinge and lock lubrication HVAC\n• Air filter swap (heating season)\n• Attic insulation check before heating season Generator (if applicable)\n• Oil level check\n• Confirm weekly exercise cycle visually Safety\n• Smoke and CO detector battery swap\n• Smoke detector age check (replace if 9+ years. Bring spares)\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation) Plumbing\n• Drain cleaning and sink trap check\n• Hose bib shutoff valve test Exterior\n• Seal gaps around pipes and utility entries (pest prevention)\n• Firebox and damper check (wood-burning fireplaces) Other (conditional)\n• Central vacuum service (if applicable)\n• Radon mitigation fan check (if applicable) Add anything you've been meaning to get to.",
    "from": "\nWhat's typically covered in a fall handyman visit:\n\nWeatherization\n• Exterior faucet winterization and hose bib covers\n• Storm door and weatherstripping check (windows + doors)\n• Window AC removal and storage (if applicable)\n• Door hinge and lock lubrication\n\nHVAC\n• Air filter swap (heating season)\n• Attic insulation check before heating season\n\nGenerator (if applicable)\n• Oil level check\n• Confirm weekly exercise cycle visually\n\nSafety\n• Smoke and CO detector battery swap\n• Smoke detector age check (replace if 9+ years — bring spares)\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n\nPlumbing\n• Drain cleaning and sink trap check\n• Hose bib shutoff valve test\n\nExterior\n• Seal gaps around pipes and utility entries (pest prevention)\n• Firebox and damper check (wood-burning fireplaces)\n\nOther (conditional)\n• Central vacuum service (if applicable)\n• Radon mitigation fan check (if applicable)\n\nAdd anything you've been meaning to get to.\n"
  }
}
```

### Spring Handyman Visit  `live-task-handyman-spring-handyman-visit`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit d73d461**
**Voice fix — pre-computed.**

Template "Spring Handyman Visit" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> 
What's typically covered in a spring handyman visit:

HVAC
• Air filter swap (buy a case, swap during visit)
• Mini-split filter rinse (if applicable)

Plumbing
• Washing machine supply hose visual check
• Sump pump test (if applicable)
• Well cap and pressure tank visual (if well home)
• Water softener brine tank visual (if applicable)
• Whole-house filter swap (if applicable)

Exterior
• Caulking touch-up around windows and doors
• Driveway crack sealcoat spot-fill
• Deck/fence screw check
• Foundation grading walkaround
• Retaining wall condition check

Safety
• Smoke and CO detector battery swap
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)
• Test GFCI outlets

Appliances
• Refrigerator coil vacuum (if accessible)
• Dishwasher spray arm clean (if not covered by housekeeper)
• Ice maker filter replacement (if due)

Other (conditional)
• Crawl space visual for moisture (if applicable)
• Dehumidifier operation test (if applicable)
• Septic drain field walkaround (if applicable)
• Smart leak system test (if applicable)
• Turf drainage spot-check (synthetic turf homes)

Add anything you've been meaning to get to — that's what the handyman is for.


**AFTER (proposed):**
> What's typically covered in a spring handyman visit: HVAC
• Air filter swap (buy a case, swap during visit)
• Mini-split filter rinse (if applicable) Plumbing
• Washing machine supply hose visual check
• Sump pump test (if applicable)
• Well cap and pressure tank visual (if well home)
• Water softener brine tank visual (if applicable)
• Whole-house filter swap (if applicable) Exterior
• Caulking touch-up around windows and doors
• Driveway crack sealcoat spot-fill
• Deck/fence screw check
• Foundation grading walkaround
• Retaining wall condition check Safety
• Smoke and CO detector battery swap
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)
• Test GFCI outlets Appliances
• Refrigerator coil vacuum (if accessible)
• Dishwasher spray arm clean (if not covered by housekeeper)
• Ice maker filter replacement (if due) Other (conditional)
• Crawl space visual for moisture (if applicable)
• Dehumidifier operation test (if applicable)
• Septic drain field walkaround (if applicable)
• Smart leak system test (if applicable)
• Turf drainage spot-check (synthetic turf homes) Add anything you've been meaning to get to. That's what the handyman is for.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "What's typically covered in a spring handyman visit: HVAC\n• Air filter swap (buy a case, swap during visit)\n• Mini-split filter rinse (if applicable) Plumbing\n• Washing machine supply hose visual check\n• Sump pump test (if applicable)\n• Well cap and pressure tank visual (if well home)\n• Water softener brine tank visual (if applicable)\n• Whole-house filter swap (if applicable) Exterior\n• Caulking touch-up around windows and doors\n• Driveway crack sealcoat spot-fill\n• Deck/fence screw check\n• Foundation grading walkaround\n• Retaining wall condition check Safety\n• Smoke and CO detector battery swap\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n• Test GFCI outlets Appliances\n• Refrigerator coil vacuum (if accessible)\n• Dishwasher spray arm clean (if not covered by housekeeper)\n• Ice maker filter replacement (if due) Other (conditional)\n• Crawl space visual for moisture (if applicable)\n• Dehumidifier operation test (if applicable)\n• Septic drain field walkaround (if applicable)\n• Smart leak system test (if applicable)\n• Turf drainage spot-check (synthetic turf homes) Add anything you've been meaning to get to. That's what the handyman is for.",
    "from": "\nWhat's typically covered in a spring handyman visit:\n\nHVAC\n• Air filter swap (buy a case, swap during visit)\n• Mini-split filter rinse (if applicable)\n\nPlumbing\n• Washing machine supply hose visual check\n• Sump pump test (if applicable)\n• Well cap and pressure tank visual (if well home)\n• Water softener brine tank visual (if applicable)\n• Whole-house filter swap (if applicable)\n\nExterior\n• Caulking touch-up around windows and doors\n• Driveway crack sealcoat spot-fill\n• Deck/fence screw check\n• Foundation grading walkaround\n• Retaining wall condition check\n\nSafety\n• Smoke and CO detector battery swap\n• Fire extinguisher gauge check\n• Camera perimeter walk-past\n• Verify smoke and CO detectors (self-test confirmation)\n• Test GFCI outlets\n\nAppliances\n• Refrigerator coil vacuum (if accessible)\n• Dishwasher spray arm clean (if not covered by housekeeper)\n• Ice maker filter replacement (if due)\n\nOther (conditional)\n• Crawl space visual for moisture (if applicable)\n• Dehumidifier operation test (if applicable)\n• Septic drain field walkaround (if applicable)\n• Smart leak system test (if applicable)\n• Turf drainage spot-check (synthetic turf homes)\n\nAdd anything you've been meaning to get to — that's what the handyman is for.\n"
  }
}
```

### Solar System Inspection  `live-task-solar-professional-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Solar System Inspection" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age — inverter failure is the #1 cause of unexpected solar downtime.

**AFTER (proposed):**
> Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age. Inverter failure is the #1 cause of unexpected solar downtime.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age. Inverter failure is the #1 cause of unexpected solar downtime.",
    "from": "Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age — inverter failure is the #1 cause of unexpected solar downtime."
  }
}
```

### Solar Panel Cleaning  `live-task-solar-professional-panel-cleaning`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Solar Panel Cleaning" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Output drops gradually so it's hard to notice from monthly bills alone — but a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months).

**AFTER (proposed):**
> Output drops gradually so it's hard to notice from monthly bills alone. But a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months).

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Output drops gradually so it's hard to notice from monthly bills alone. But a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months).",
    "from": "Output drops gradually so it's hard to notice from monthly bills alone — but a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months)."
  }
}
```

### Annual Security System Check  `live-task-security-system-verify-alarm-system`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Security System Check" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits — this is the annual confirmation that everything is still registering.

**AFTER (proposed):**
> Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits. This is the annual confirmation that everything is still registering.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits. This is the annual confirmation that everything is still registering.",
    "from": "Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits — this is the annual confirmation that everything is still registering."
  }
}
```

### Termite Inspection  `live-task-pest-control-professional-termite-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Termite Inspection" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Spring is termite swarming season — the easiest time to spot active colonies. Required to maintain most home warranties. If the inspector finds activity, treatment runs $1,500–$5,000 depending on severity, but skipping the inspection can mean a $30K+ structural repair down the line.

**AFTER (proposed):**
> Spring is termite swarming season. The easiest time to spot active colonies. Required to maintain most home warranties. If the inspector finds activity, treatment runs $1,500–$5,000 depending on severity, but skipping the inspection can mean a $30K+ structural repair down the line.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Spring is termite swarming season. The easiest time to spot active colonies. Required to maintain most home warranties. If the inspector finds activity, treatment runs $1,500–$5,000 depending on severity, but skipping the inspection can mean a $30K+ structural repair down the line.",
    "from": "Spring is termite swarming season — the easiest time to spot active colonies. Required to maintain most home warranties. If the inspector finds activity, treatment runs $1,500–$5,000 depending on severity, but skipping the inspection can mean a $30K+ structural repair down the line."
  }
}
```

### Inspect Hot Tub Cover and Jets  `live-task-pool-spa-inspect-hot-tub-cover-and-jets`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Inspect Hot Tub Cover and Jets" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> A waterlogged cover loses 20–40% of its insulation value, costing $30–$60/month in extra heating during cool months. Replacement covers run $300–$500 — pays for itself in 6–12 months. Soaked covers also start to mold inside, which is gross to rest your face on.

**AFTER (proposed):**
> A waterlogged cover loses 20–40% of its insulation value, costing $30–$60/month in extra heating during cool months. Replacement covers run $300–$500. Pays for itself in 6–12 months. Soaked covers also start to mold inside, which is gross to rest your face on.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "A waterlogged cover loses 20–40% of its insulation value, costing $30–$60/month in extra heating during cool months. Replacement covers run $300–$500. Pays for itself in 6–12 months. Soaked covers also start to mold inside, which is gross to rest your face on.",
    "from": "A waterlogged cover loses 20–40% of its insulation value, costing $30–$60/month in extra heating during cool months. Replacement covers run $300–$500 — pays for itself in 6–12 months. Soaked covers also start to mold inside, which is gross to rest your face on."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Inspect Hot Tub Cover and Jets" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Check the cover for cracks, waterlogging (lift one corner — if it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped.

**AFTER (proposed):**
> Check the cover for cracks, waterlogging (lift one corner. If it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Check the cover for cracks, waterlogging (lift one corner. If it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped.",
    "from": "Check the cover for cracks, waterlogging (lift one corner — if it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped."
  }
}
```

### Test and Sanitize Hot Tub Water  `live-task-pool-spa-test-and-sanitize-hot-tub-water`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test and Sanitize Hot Tub Water" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Use test strips or a digital tester to check bromine/chlorine, pH, and total alkalinity weekly. Add sanitizer to maintain levels and re-balance pH/alkalinity. Without weekly sanitizer additions, hot tub water gets cloudy + biofilm starts forming inside the plumbing — a much harder problem to recover from than just topping up sanitizer.

**AFTER (proposed):**
> Use test strips or a digital tester to check bromine/chlorine, pH, and total alkalinity weekly. Add sanitizer to maintain levels and re-balance pH/alkalinity. Without weekly sanitizer additions, hot tub water gets cloudy + biofilm starts forming inside the plumbing. A much harder problem to recover from than just topping up sanitizer.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Use test strips or a digital tester to check bromine/chlorine, pH, and total alkalinity weekly. Add sanitizer to maintain levels and re-balance pH/alkalinity. Without weekly sanitizer additions, hot tub water gets cloudy + biofilm starts forming inside the plumbing. A much harder problem to recover from than just topping up sanitizer.",
    "from": "Use test strips or a digital tester to check bromine/chlorine, pH, and total alkalinity weekly. Add sanitizer to maintain levels and re-balance pH/alkalinity. Without weekly sanitizer additions, hot tub water gets cloudy + biofilm starts forming inside the plumbing — a much harder problem to recover from than just topping up sanitizer."
  }
}
```

### Pool Heater Service  `live-task-pool-spa-pool-heater-service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Pool Heater Service" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Pool heater specialist services the heater — gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan.

**AFTER (proposed):**
> Pool heater specialist services the heater. Gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Pool heater specialist services the heater. Gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan.",
    "from": "Pool heater specialist services the heater — gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan."
  }
}
```

### Winterize Irrigation System  `live-task-irrigation-winterize-irrigation-system`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Winterize Irrigation System" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass — and you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October.

**AFTER (proposed):**
> Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass. And you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass. And you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October.",
    "from": "Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass — and you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October."
  }
}
```

### Arborist Tree Health Inspection  `live-task-landscaping-arborist-tree-health-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Arborist Tree Health Inspection" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection — falling tree damage is often excluded from home insurance if due to visible neglect.

**AFTER (proposed):**
> Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection. Falling tree damage is often excluded from home insurance if due to visible neglect.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection. Falling tree damage is often excluded from home insurance if due to visible neglect.",
    "from": "Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection — falling tree damage is often excluded from home insurance if due to visible neglect."
  }
}
```

### Deep Clean Synthetic Turf  `live-task-landscaping-deep-clean-synthetic-turf`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Deep Clean Synthetic Turf" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Schedule for early spring before the heaviest pollen weeks — that way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two.

**AFTER (proposed):**
> Schedule for early spring before the heaviest pollen weeks. That way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Schedule for early spring before the heaviest pollen weeks. That way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two.",
    "from": "Schedule for early spring before the heaviest pollen weeks — that way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two."
  }
}
```

### Soil Ph Test and Lime Application  `live-task-landscaping-soil-ph-test-and-lime-application`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Soil Ph Test and Lime Application" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing — without correcting pH first, the fertilizer is wasted money.

**AFTER (proposed):**
> Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing. Without correcting pH first, the fertilizer is wasted money.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing. Without correcting pH first, the fertilizer is wasted money.",
    "from": "Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing — without correcting pH first, the fertilizer is wasted money."
  }
}
```

### Pre-Emergent Weed Control  `live-task-landscaping-pre-emergent-weed-control`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Pre-Emergent Weed Control" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Timed to soil temps in the low 50s — usually mid-March to mid-April in {state}

**AFTER (proposed):**
> Timed to soil temps in the low 50s. Usually mid-March to mid-April in {state}

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Timed to soil temps in the low 50s. Usually mid-March to mid-April in {state}",
    "from": "Timed to soil temps in the low 50s — usually mid-March to mid-April in {state}"
  }
}
```

### Schedule Exterior Window Re-Caulking  `live-task-windows-schedule-exterior-window-re-caulking`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Schedule Exterior Window Re-Caulking" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing — catching it early prevents wood rot and the $5K+ repair that follows.

**AFTER (proposed):**
> Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing. Catching it early prevents wood rot and the $5K+ repair that follows.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing. Catching it early prevents wood rot and the $5K+ repair that follows.",
    "from": "Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing — catching it early prevents wood rot and the $5K+ repair that follows."
  }
}
```

### Annual Gas Fireplace Service  `live-task-chimney-annual-gas-fireplace-service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Gas Fireplace Service" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep — gas fireplaces don't need creosote cleaning but they do need annual gas-side service.

**AFTER (proposed):**
> Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep. Gas fireplaces don't need creosote cleaning but they do need annual gas-side service.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep. Gas fireplaces don't need creosote cleaning but they do need annual gas-side service.",
    "from": "Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep — gas fireplaces don't need creosote cleaning but they do need annual gas-side service."
  }
}
```

### EV Charger Inspection  `live-task-electrical-ev-charger-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "EV Charger Inspection" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> If your charger is in an unconditioned garage or outdoors, check the housing for rodent damage and water intrusion at the same time. Some manufacturer warranties require documented annual inspection — ask before you buy if you're shopping a new install.

**AFTER (proposed):**
> If your charger is in an unconditioned garage or outdoors, check the housing for rodent damage and water intrusion at the same time. Some manufacturer warranties require documented annual inspection. Ask before you buy if you're shopping a new install.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "If your charger is in an unconditioned garage or outdoors, check the housing for rodent damage and water intrusion at the same time. Some manufacturer warranties require documented annual inspection. Ask before you buy if you're shopping a new install.",
    "from": "If your charger is in an unconditioned garage or outdoors, check the housing for rodent damage and water intrusion at the same time. Some manufacturer warranties require documented annual inspection — ask before you buy if you're shopping a new install."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "EV Charger Inspection" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Electrician inspects the EV charging station hardware, dedicated circuit and breaker, terminations at the charger and the panel, and the charging cable for wear or heat signatures. Higher-amperage L2 installs (40A / 50A circuits) draw more current for longer durations than typical residential loads — a slowly-loosening connection runs hot for months before it fails.

**AFTER (proposed):**
> Electrician inspects the EV charging station hardware, dedicated circuit and breaker, terminations at the charger and the panel, and the charging cable for wear or heat signatures. Higher-amperage L2 installs (40A / 50A circuits) draw more current for longer durations than typical residential loads. A slowly-loosening connection runs hot for months before it fails.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Electrician inspects the EV charging station hardware, dedicated circuit and breaker, terminations at the charger and the panel, and the charging cable for wear or heat signatures. Higher-amperage L2 installs (40A / 50A circuits) draw more current for longer durations than typical residential loads. A slowly-loosening connection runs hot for months before it fails.",
    "from": "Electrician inspects the EV charging station hardware, dedicated circuit and breaker, terminations at the charger and the panel, and the charging cable for wear or heat signatures. Higher-amperage L2 installs (40A / 50A circuits) draw more current for longer durations than typical residential loads — a slowly-loosening connection runs hot for months before it fails."
  }
}
```

### Inspect Electrical Panel  `live-task-electrical-inspect-electrical-panel`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Inspect Electrical Panel" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks — if you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade.

**AFTER (proposed):**
> Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks. If you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks. If you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade.",
    "from": "Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks — if you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade."
  }
}
```

### Replace Smoke Detectors  `live-task-electrical-replace-smoke-detectors`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Replace Smoke Detectors" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> If you have hardwired/interconnected detectors, replace them all at once with the same model — mixing brands or sensor types in an interconnected system can cause false alarms. Check the manufacture date on every detector while up there; some homes have a mix of newer and older units.

**AFTER (proposed):**
> If you have hardwired/interconnected detectors, replace them all at once with the same model. Mixing brands or sensor types in an interconnected system can cause false alarms. Check the manufacture date on every detector while up there; some homes have a mix of newer and older units.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "If you have hardwired/interconnected detectors, replace them all at once with the same model. Mixing brands or sensor types in an interconnected system can cause false alarms. Check the manufacture date on every detector while up there; some homes have a mix of newer and older units.",
    "from": "If you have hardwired/interconnected detectors, replace them all at once with the same model — mixing brands or sensor types in an interconnected system can cause false alarms. Check the manufacture date on every detector while up there; some homes have a mix of newer and older units."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Replace Smoke Detectors" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply — this is one of the few maintenance items where the timing isn't optional.

**AFTER (proposed):**
> Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply. This is one of the few maintenance items where the timing isn't optional.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply. This is one of the few maintenance items where the timing isn't optional.",
    "from": "Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply — this is one of the few maintenance items where the timing isn't optional."
  }
}
```

### Well System Inspection  `live-task-well-system-professional-well-inspection`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Well System Inspection" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Pump replacement is $1,500–$3,500 — annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency.

**AFTER (proposed):**
> Pump replacement is $1,500–$3,500. Annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Pump replacement is $1,500–$3,500. Annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency.",
    "from": "Pump replacement is $1,500–$3,500 — annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency."
  }
}
```

### Test Water Quality  `live-task-well-system-test-water-quality`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Test Water Quality" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Test in spring after the snowmelt and seasonal water-table shifts have moved through. Test sooner if you notice taste, odor, or color changes — those are the canary signs of a contamination event. State health departments often offer free or subsidized testing for private wells.

**AFTER (proposed):**
> Test in spring after the snowmelt and seasonal water-table shifts have moved through. Test sooner if you notice taste, odor, or color changes. Those are the canary signs of a contamination event. State health departments often offer free or subsidized testing for private wells.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Test in spring after the snowmelt and seasonal water-table shifts have moved through. Test sooner if you notice taste, odor, or color changes. Those are the canary signs of a contamination event. State health departments often offer free or subsidized testing for private wells.",
    "from": "Test in spring after the snowmelt and seasonal water-table shifts have moved through. Test sooner if you notice taste, odor, or color changes — those are the canary signs of a contamination event. State health departments often offer free or subsidized testing for private wells."
  }
}
```

### Drain Cleaning  `live-task-plumbing-professional-drain-cleaning`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Drain Cleaning" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this — the same root that's slowing one drain will eventually back up the whole house.

**AFTER (proposed):**
> Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this. The same root that's slowing one drain will eventually back up the whole house.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this. The same root that's slowing one drain will eventually back up the whole house.",
    "from": "Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this — the same root that's slowing one drain will eventually back up the whole house."
  }
}
```

### Air Duct Cleaning  `live-task-hvac-air-duct-cleaning`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Air Duct Cleaning" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Professional cleaning of the full supply and return ductwork — removes dust, allergens, and debris. Separate from the annual HVAC tune-up.

**AFTER (proposed):**
> Professional cleaning of the full supply and return ductwork. Removes dust, allergens, and debris. Separate from the annual HVAC tune-up.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Professional cleaning of the full supply and return ductwork. Removes dust, allergens, and debris. Separate from the annual HVAC tune-up.",
    "from": "Professional cleaning of the full supply and return ductwork — removes dust, allergens, and debris. Separate from the annual HVAC tune-up."
  }
}
```

### Geothermal Loop Pressure Check  `live-task-hvac-geothermal-loop-pressure-check`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Geothermal Loop Pressure Check" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Use the original installer if possible. Geothermal is specialized — most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues.

**AFTER (proposed):**
> Use the original installer if possible. Geothermal is specialized. Most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Use the original installer if possible. Geothermal is specialized. Most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues.",
    "from": "Use the original installer if possible. Geothermal is specialized — most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Geothermal Loop Pressure Check" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak — could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown.

**AFTER (proposed):**
> Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak. Could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak. Could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown.",
    "from": "Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak — could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown."
  }
}
```

### Annual Boiler Service  `live-task-hvac-annual-boiler-service`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Boiler Service" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Required for warranty on most boilers — the manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call.

**AFTER (proposed):**
> Required for warranty on most boilers. The manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Required for warranty on most boilers. The manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call.",
    "from": "Required for warranty on most boilers — the manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Annual Boiler Service" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house — a cracked heat exchanger can leak CO into living spaces.

**AFTER (proposed):**
> Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house. A cracked heat exchanger can leak CO into living spaces.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house. A cracked heat exchanger can leak CO into living spaces.",
    "from": "Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house — a cracked heat exchanger can leak CO into living spaces."
  }
}
```

### Bleed Radiators  `live-task-hvac-bleed-radiators`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Bleed Radiators" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Most boiler owners include this in the annual boiler service visit instead of a separate appointment — no point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech.

**AFTER (proposed):**
> Most boiler owners include this in the annual boiler service visit instead of a separate appointment. No point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Most boiler owners include this in the annual boiler service visit instead of a separate appointment. No point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech.",
    "from": "Most boiler owners include this in the annual boiler service visit instead of a separate appointment — no point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Bleed Radiators" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold — the room never gets warm even though the system runs constantly.

**AFTER (proposed):**
> Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold. The room never gets warm even though the system runs constantly.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold. The room never gets warm even though the system runs constantly.",
    "from": "Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold — the room never gets warm even though the system runs constantly."
  }
}
```

### Inspect Ductwork for Leaks  `live-task-hvac-inspect-ductwork-for-leaks`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Inspect Ductwork for Leaks" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks — sealing them recovers that money on every energy bill for the rest of the system's life.

**AFTER (proposed):**
> HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks. Sealing them recovers that money on every energy bill for the rest of the system's life.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks. Sealing them recovers that money on every energy bill for the rest of the system's life.",
    "from": "HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks — sealing them recovers that money on every energy bill for the rest of the system's life."
  }
}
```

### Exterior Painting Refresh  `live-task-siding-exterior-exterior-painting-refresh`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Exterior Painting Refresh" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Full exterior paint refresh — scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance.

**AFTER (proposed):**
> Full exterior paint refresh. Scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Full exterior paint refresh. Scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance.",
    "from": "Full exterior paint refresh — scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance."
  }
}
```

### Exterior Paint Touch-Up Walkaround  `live-task-siding-exterior-exterior-paint-touch-up-walkaround`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Exterior Paint Touch-Up Walkaround" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Best done in late spring after the wood has dried out from winter and before summer heat. Match the existing finish carefully — eggshell on a satin wall reads as a patch even after a few weeks of weathering. Most painters keep your color formulation on file once you've used them.

**AFTER (proposed):**
> Best done in late spring after the wood has dried out from winter and before summer heat. Match the existing finish carefully. Eggshell on a satin wall reads as a patch even after a few weeks of weathering. Most painters keep your color formulation on file once you've used them.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Best done in late spring after the wood has dried out from winter and before summer heat. Match the existing finish carefully. Eggshell on a satin wall reads as a patch even after a few weeks of weathering. Most painters keep your color formulation on file once you've used them.",
    "from": "Best done in late spring after the wood has dried out from winter and before summer heat. Match the existing finish carefully — eggshell on a satin wall reads as a patch even after a few weeks of weathering. Most painters keep your color formulation on file once you've used them."
  }
}
```

### Treat Moss and Algae  `live-task-roofing-treat-moss-and-algae`

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Treat Moss and Algae" has a `no-em-dash` violation in field `notes`.

**BEFORE:**
> Wood shake roofs are fragile and slippery — always pro-only with safety gear. For asphalt, fall application means the rains carry the treatment evenly across the shingles before winter. North-facing slopes show moss first; check those when deciding if you're due.

**AFTER (proposed):**
> Wood shake roofs are fragile and slippery. Always pro-only with safety gear. For asphalt, fall application means the rains carry the treatment evenly across the shingles before winter. North-facing slopes show moss first; check those when deciding if you're due.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "notes": {
    "to": "Wood shake roofs are fragile and slippery. Always pro-only with safety gear. For asphalt, fall application means the rains carry the treatment evenly across the shingles before winter. North-facing slopes show moss first; check those when deciding if you're due.",
    "from": "Wood shake roofs are fragile and slippery — always pro-only with safety gear. For asphalt, fall application means the rains carry the treatment evenly across the shingles before winter. North-facing slopes show moss first; check those when deciding if you're due."
  }
}
```

**2026-04-30 · change_request · tom · applied 2026-04-30 · commit 671327b**
**Voice fix — pre-computed.**

Template "Treat Moss and Algae" has a `no-em-dash` violation in field `description`.

**BEFORE:**
> Roofer applies a zinc-strip or oxygen-bleach moss/algae treatment to prevent the dark streaks and shingle damage that biological growth causes. The streaks aren't just cosmetic — moss lifts the granular surface of asphalt shingles and shortens the roof's life by 5–10 years if left untreated.

**AFTER (proposed):**
> Roofer applies a zinc-strip or oxygen-bleach moss/algae treatment to prevent the dark streaks and shingle damage that biological growth causes. The streaks aren't just cosmetic. Moss lifts the granular surface of asphalt shingles and shortens the roof's life by 5–10 years if left untreated.

**Why:** Em-dashes read as AI-generated to HNW audience. Tom's design rule baked into website/admin-data/voice-rules.json.

**Action for Claude next session:** Apply the diff above to MaintenanceTemplates.swift, re-run the voice lint to confirm clean.

**Proposed diff:**
```json
{
  "description": {
    "to": "Roofer applies a zinc-strip or oxygen-bleach moss/algae treatment to prevent the dark streaks and shingle damage that biological growth causes. The streaks aren't just cosmetic. Moss lifts the granular surface of asphalt shingles and shortens the roof's life by 5–10 years if left untreated.",
    "from": "Roofer applies a zinc-strip or oxygen-bleach moss/algae treatment to prevent the dark streaks and shingle damage that biological growth causes. The streaks aren't just cosmetic — moss lifts the granular surface of asphalt shingles and shortens the roof's life by 5–10 years if left untreated."
  }
}
```

### Mosquito and tick spraying  `mosquito_tick`

**2026-04-29 · feedback · tom · applied 2026-04-30 · commit 693691c**
I feel like mosquito and tick spraying is part of the quarterly pest control typically (we have it with Orkin today). Orkin comes and does their quarterly pest control and while they are here they also do the mosquito spraying, and then during the active months of mosquitos they just come monthly. Should we just lump pest control and mosquito control into the same routine? Maybe we have a sub routine within this?
