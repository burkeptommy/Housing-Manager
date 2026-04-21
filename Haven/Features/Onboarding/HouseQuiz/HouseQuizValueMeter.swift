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
        case "q3_heating_fuel":
            return 6_000
        case "q3b_hvac_type":
            return 12_000
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
            // Pro capture is worth more than DIY for the meter.
            return answerId == "pro" ? 11_000 : 5_500
        case "q11b_lawn_type":
            return 4_000
        case "q12_pool":
            return answerId == "none" ? 3_500 : 9_000
        case "q12b_pool_chemistry":
            return 4_500
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
        case "q26_auto_insurance":
            return 7_500
        case "q27_homeowners_insurance":
            return 10_500

        // ── Chapter 3: Your People ───────────────────────────
        case "q23_vehicle_count":
            // DELTA scales with the number of vehicles.
            let count = Int(answerId) ?? (answerId == "4_plus" ? 4 : 1)
            return min(8_000, 2_500 + Double(count) * 1_500)
        case "q24_vehicle_add":
            return 6_000
        case "q25_garage_ev":
            return answerId == "none" ? 3_000 : 5_500
        case "q25b_ev_charger":
            return answerId == "yes" ? 5_500 : 3_000
        case "q28_household":
            // Household composition unlocks every downstream people feature.
            return 9_000
        case "q28b_pets":
            return answerId == "no_pets" ? 3_000 : 5_500
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
