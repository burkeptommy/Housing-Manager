import Foundation

/// Phase 60.3: Per-question value deltas for the House Quiz protection
/// meter. These numbers should approximately sum to
/// `OnboardingScheduleGenerator.computeValueProtection(from:)` (12% of
/// the property's current value over 10 years) so the meter lands
/// correctly at the last question.
///
/// Deltas intentionally skew higher early in the quiz so the user sees
/// meaningful motion in the first 60 seconds. Answer-conditional deltas
/// reward vendor capture and system confirmation — picking "pro" for
/// lawn or pest control contributes more than "diy" because the captured
/// contractor unlocks downstream coordination value.
///
/// Tuning principle: the first ten answers should already land ~$100K
/// on a typical $500K home. A user who bails after Chapter 1 should
/// feel like they earned something.
enum HouseQuizValueMeter {

    /// Returns the running-total delta for this answer. Called from
    /// `HouseQuizViewModel.persist` right after the answer lands in state.
    static func delta(
        forQuestion questionId: String,
        answer: HouseQuizAnswer,
        property: PropertyRow,
        detectedSystems: [HomeSystemRow]
    ) -> Double {
        let homeValue = property.currentEstimatedValue ?? 500_000
        let selectedIds = Set(answer.selectedIds ?? [])
        let answerId = answer.answerId ?? ""

        switch questionId {
        // ── Chapter 1: Your Home ─────────────────────────────
        case "q1_roof_material":
            // Roof protection is the single biggest home-value driver.
            return 14_000
        case "q2_siding":
            return 8_500
        case "q3_heating_system":
            // Phase 67D (A3): Q3 + Q3b merged. Sum of old deltas
            // (q3_heating_fuel $6k + q3b_hvac_type $12k = $18k) so the
            // running total at the end of Chapter 1 is unchanged.
            return 18_000
        case "q4_purchase":
            // Proportional — a pricier home has more downside to protect.
            // Cap at $20K so the meter doesn't overshoot on $5M homes.
            return min(20_000, max(8_000, homeValue * 0.012))
        case "q5_mortgage":
            return 5_500
        case "q6_water_source":
            return 5_000
        case "q7_sewer_septic":
            // Septic systems have real failure-cost downside.
            return answerId == "septic" ? 9_000 : 5_000
        case "q8_water_heater":
            return 7_500
        case "q9_basement":
            return 5_000
        case "q10_appliances":
            // Scale with the number of appliances captured (max ~$8K).
            let count = max(1, selectedIds.count)
            return min(8_000, 1_800 + Double(count) * 800)
        case "q20_other_fuels":
            return 4_500
        case "q21_solar":
            // Solar is high-signal: the owned/leased answers add big value.
            return answerId == "owned" || answerId == "leased" ? 9_500 : 4_500
        case "q22_generator":
            // Generator capture unlocks fuel-delivery coordination value.
            return answerId == "none" ? 4_500 : 8_500

        // ── Chapter 2: Your Pros ─────────────────────────────
        case "q36_diy_vs_vendor":
            // Opens the Pros chapter — anchors everything that follows.
            return 10_000
        case "q11_lawn":
            // Phase 67D (A4): Q11 + Q11b merged. Pro path keeps the vendor
            // premium ($11k base + $4k lawn-type = $15k); diy/garden/
            // hardscape land at $5.5k base + $4k lawn-type = $9.5k. When
            // the lawn-type sub-section is hidden (no_lawn / garden /
            // hardscape), users still get the base since they finished
            // the question.
            return answerId == "pro" ? 15_000 : 9_500
        case "q12_pool":
            // Phase 67D (A5): Q12 + Q12b merged. Hot-tub-only and none
            // paths skip the chemistry sub-section — preserve the original
            // Q12 deltas there. Pool paths sum the chemistry $4.5k.
            switch answerId {
            case "none":    return 3_500
            case "hot_tub": return 9_000
            default:        return 13_500  // in_ground / above_ground / both
            }
        case "q13_pest":
            return answerId == "quarterly_pro" || answerId == "termite_bond" ? 9_500 : 5_500
        case "q14_irrigation":
            return answerId == "no" ? 3_500 : 7_500
        case "q15_security":
            return answerId == "monitored" ? 9_500 : 5_000
        case "q15b_household_contractors":
            // One-shot — delta scales with number of chips selected,
            // rewarded for each captured vendor (vendor orchestration is
            // the whole product thesis).
            let chipCount = max(1, selectedIds.count)
            return min(28_000, 4_500 * Double(chipCount))
        case "q16_electric":
            return 5_500
        case "q17_internet":
            // Forwarding-email milestone delivery anchor.
            return 6_500
        case "q18_trash":
            return 4_000
        case "q19_heating_provider":
            return 5_500
        case "q26_insurance":
            // Phase 67D (A9): Q26 + Q27 merged into a single dual-insurance
            // screen. Sum of old deltas (auto $7.5k + home $10.5k = $18k).
            return 18_000

        // ── Chapter 3: Your People ───────────────────────────
        case "q24_vehicle_add":
            // Phase 67D (A2): Q23 vehicle count dropped. Redistribute its
            // ~$4k average into Q24 (was $6k → now $10k) so the running
            // total at Chapter 2 entrance is unchanged.
            return 10_000
        case "q25_garage_ev":
            // Phase 67D (A8): Q25 + Q25b merged. EV path adds $5.5k on
            // top of garage base; no-garage stays at $3k.
            if answerId == "none" { return 3_000 }
            return answer.payload?["evCharger"] == "yes" ? 11_000 : 8_500
        case "q28_household":
            // Phase 67D (A10): Q28 + Q28b merged. Household composition
            // base ($9k) plus pets sub-step ($3k–$5.5k from payload).
            let petsAnswer = answer.payload?["petsAnswerId"]
            if petsAnswer == "no_pets" { return 12_000 }
            if petsAnswer != nil { return 14_500 }
            return 9_000  // pets sub-step not yet completed
        case "q29_estate_docs":
            // Estate vault anchor — the Life tab's whole promise.
            let count = max(1, selectedIds.count)
            return min(16_000, 4_000 * Double(count))
        case "q30_priorities":
            return 4_500

        default:
            // Unknown question — small default so forgotten additions
            // don't break the meter entirely.
            return 2_500
        }
    }

    /// Sum of deltas for a chapter under a baseline "typical" property.
    /// Used by `ChapterIntroCard` to preview how much protection the
    /// upcoming chapter will unlock. Deltas that depend on the user's
    /// answer use a neutral midpoint so the preview is a decent estimate
    /// without pretending to know the exact outcome.
    static func expectedValueForChapter(
        _ chapter: HouseQuizChapter,
        property: PropertyRow
    ) -> Double {
        let q = HouseQuizQuestionLibrary.allQuestions.filter { $0.chapter == chapter }
        let placeholderAnswer = HouseQuizAnswer(answerId: nil, answeredAt: Date())
        return q.reduce(0.0) { total, question in
            total + delta(
                forQuestion: question.id,
                answer: placeholderAnswer,
                property: property,
                detectedSystems: []
            )
        }
    }

    /// The total the meter should be approaching by the last question —
    /// used as a calibration reference so callers can warn when the
    /// running meter diverges materially from the expected final.
    /// 12% of home value over 10 years is the calibration target
    /// established in `OnboardingScheduleGenerator.computeValueProtection`.
    static func expectedFinalValue(for property: PropertyRow) -> Double {
        let homeValue = property.currentEstimatedValue ?? 500_000
        return homeValue * 0.12
    }
}
