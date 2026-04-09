import Foundation

/// Per-answer feedback strings shown after the user picks an answer.
/// Tom can edit copy here without touching the view code. Citations are
/// study names only — no URLs, no hyperlinks. Strings support `{city}` and
/// `{state}` interpolation, populated at render time.
enum HouseQuizFeedbackLibrary {

    /// Returns feedback for a given (questionId, answerId) pair, or nil if
    /// none exists. Single-select questions only — multi-select questions
    /// don't currently show per-answer feedback (the view skips it).
    static func feedback(for questionId: String, answerId: String) -> AnswerFeedback? {
        feedbackByQuestion[questionId]?[answerId]
    }

    private static let feedbackByQuestion: [String: [String: AnswerFeedback]] = [

        // MARK: Q1 — Roof material
        "q1_roof_material": [
            "asphalt": AnswerFeedback(
                badge: "Insight",
                title: "Asphalt roofs in {city} typically last 20-25 years.",
                subhead: "Tracking annual inspections adds about 3% to resale value.",
                citationName: "Remodeling Magazine Cost vs Value Report"
            ),
            "metal": AnswerFeedback(
                badge: "Insight",
                title: "Metal roofs last 50+ years and cut energy costs ~15% in {state}.",
                subhead: "Premium buyers pay more for properly maintained metal.",
                citationName: "Metal Roofing Alliance Industry Study"
            ),
            "tile": AnswerFeedback(
                badge: "Insight",
                title: "Tile roofs last 50-100 years but underlayment needs replacing every 20.",
                subhead: "We'll remind you to budget for the underlayment cycle.",
                citationName: "Tile Roofing Industry Alliance"
            ),
            "slate": AnswerFeedback(
                badge: "Insight",
                title: "Slate is a 75 to 200 year material, the longest-lived of all.",
                subhead: "Buyers pay premiums for original slate roofs in good condition.",
                citationName: "National Slate Association"
            ),
            "wood_shake": AnswerFeedback(
                badge: "Insight",
                title: "Wood shake adds character but needs treatment every 4-5 years in {state}.",
                subhead: "Skipping treatments shortens lifespan by half.",
                citationName: "Cedar Shake & Shingle Bureau"
            ),
            "flat_membrane": AnswerFeedback(
                badge: "Insight",
                title: "Flat roofs need annual seam inspections to prevent ponding leaks.",
                subhead: "We'll schedule these for you each spring.",
                citationName: "InterNACHI Flat Roof Guide"
            ),
        ],

        // MARK: Q3 — Heating fuel
        "q3_heating_fuel": [
            "oil": AnswerFeedback(
                badge: "Insight",
                title: "Oil-heat homes in the Northeast save ~$400/yr by tracking refill timing.",
                subhead: "Tank inspections also catch leaks before they become EPA fines.",
                citationName: "EIA Residential Heating Fuel Report"
            ),
            "natural_gas": AnswerFeedback(
                badge: "Insight",
                title: "Natural gas is the most stable heating cost in {state}.",
                subhead: "Annual furnace tune-ups still pay for themselves within 18 months.",
                citationName: "ENERGY STAR Furnace Maintenance Guide"
            ),
            "propane": AnswerFeedback(
                badge: "Insight",
                title: "Propane households save ~12% by locking in summer fill prices.",
                subhead: "We'll prompt you to schedule pre-winter top-offs.",
                citationName: "National Propane Gas Association"
            ),
            "electric": AnswerFeedback(
                badge: "Insight",
                title: "Electric heat pumps cut bills 30-40% vs. baseboards if maintained.",
                subhead: "Annual coil cleaning is the biggest factor.",
                citationName: "DOE Heat Pump Efficiency Study"
            ),
            "geothermal": AnswerFeedback(
                badge: "Insight",
                title: "Geothermal cuts heating costs 50-70% in {state}.",
                subhead: "Adds 5-10% to resale value when documented properly.",
                citationName: "Geothermal Exchange Organization"
            ),
        ],

        // MARK: Q6 — Water source
        "q6_water_source": [
            "private_well": AnswerFeedback(
                badge: "Insight",
                title: "Well-water homes that test annually catch 90% of contamination issues early.",
                subhead: "Untested wells are the #1 source of preventable household illness.",
                citationName: "EPA Private Well Owner's Guide"
            ),
            "shared_well": AnswerFeedback(
                badge: "Insight",
                title: "Shared wells need a written agreement to protect resale value.",
                subhead: "We'll prompt you to add yours to the document vault.",
                citationName: "EPA Drinking Water Standards"
            ),
            "municipal": AnswerFeedback(
                badge: "Insight",
                title: "Municipal water saves ~$300/yr in maintenance vs. wells.",
                subhead: "Even so, an annual whole-house filter check is worth the 10 minutes.",
                citationName: "American Water Works Association"
            ),
        ],

        // MARK: Q7 — Sewer / septic
        "q7_sewer_septic": [
            "septic": AnswerFeedback(
                badge: "Insight",
                title: "Septic systems pumped every 3-5 years last 25-30 years.",
                subhead: "Neglected ones fail in 10 to 15 years. Replacement runs $5K to $15K.",
                citationName: "EPA SepticSmart Guide"
            ),
        ],

        // MARK: Q11 — Lawn
        "q11_lawn": [
            "pro": AnswerFeedback(
                badge: "Insight",
                title: "Pro-maintained lawns add ~7% to first-impression resale value in {state}.",
                subhead: "Buyers form opinions in the first 8 seconds, so curb appeal compounds.",
                citationName: "Virginia Tech Curb Appeal Study"
            ),
            "diy": AnswerFeedback(
                badge: "Insight",
                title: "DIY lawn care saves $1,800/yr on average vs. pro service.",
                subhead: "Tracking aeration and overseeding keeps quality high.",
                citationName: "TurfTime Equipment Annual Report"
            ),
        ],

        // MARK: Q11b — Lawn type (Phase 19j)
        "q11b_lawn_type": [
            "natural": AnswerFeedback(
                badge: "Insight",
                title: "Natural lawns in {state} need 4-6 service touchpoints a year to stay healthy.",
                subhead: "We'll schedule aeration, overseeding, fertilizing, and leaf cleanup.",
                citationName: "Lawn Institute Maintenance Cycles Report"
            ),
            "turf": AnswerFeedback(
                badge: "Insight",
                title: "Synthetic turf saves ~22,000 gallons of water per year per 1,000 sq ft.",
                subhead: "Brushing the fibers and topping up infill keeps it looking new for 15-20 years.",
                citationName: "Synthetic Turf Council Lifecycle Study"
            ),
            "mixed": AnswerFeedback(
                badge: "Insight",
                title: "Mixed yards get the resale lift of natural grass plus the low-water cost of turf.",
                subhead: "We'll schedule both sets of tasks so neither gets neglected.",
                citationName: "NAR Home Features Survey"
            ),
            "not_sure": AnswerFeedback(
                badge: "Tip",
                title: "Not sure? Walk out and tug a blade. Natural grass roots, turf doesn't.",
                subhead: "You can always update this later from Property → Landscaping.",
                citationName: "Haven Field Guide"
            ),
        ],

        // MARK: Q12 — Pool
        "q12_pool": [
            "in_ground": AnswerFeedback(
                badge: "Insight",
                title: "Maintained pools in {state} add 5-8% to resale value.",
                subhead: "Neglected ones can subtract 10%. Buyers see them as liabilities.",
                citationName: "NAR Home Features Survey"
            ),
            "above_ground": AnswerFeedback(
                badge: "Insight",
                title: "Above-ground pools add lifestyle but rarely add resale value.",
                subhead: "Filter and pump tracking keeps maintenance costs predictable.",
                citationName: "Pool & Hot Tub Alliance"
            ),
            "hot_tub": AnswerFeedback(
                badge: "Insight",
                title: "Hot tubs cost $30-60/month to run if pumps and filters stay clean.",
                subhead: "We'll remind you to drain and refill twice a year.",
                citationName: "International Hot Tub Association"
            ),
        ],

        // MARK: Q13 — Pest control
        "q13_pest": [
            "quarterly_pro": AnswerFeedback(
                badge: "Insight",
                title: "Pro pest contracts in {state} save 3x their cost in termite prevention.",
                subhead: "Termite damage averages $8K per incident and isn't usually covered by insurance.",
                citationName: "NPMA Termite Damage Statistics"
            ),
            "termite_bond": AnswerFeedback(
                badge: "Insight",
                title: "Termite bonds add an average of $5K to resale value in {state}.",
                subhead: "Most are transferable to buyers if documented properly.",
                citationName: "NPMA Real Estate Transfer Study"
            ),
        ],

        // MARK: Q14 — Sprinklers
        "q14_irrigation": [
            "full": AnswerFeedback(
                badge: "Insight",
                title: "Tracking spring startup and winterization saves ~$1,200 in repairs over 5 years.",
                subhead: "Cracked pipes from skipped winterization are the #1 sprinkler failure.",
                citationName: "InterNACHI Plumbing Damage Report"
            ),
        ],

        // MARK: Q21 — Solar
        "q21_solar": [
            "owned": AnswerFeedback(
                badge: "Insight",
                title: "Owned solar adds an average of $15K to resale value in {state}.",
                subhead: "Maintained panels also keep their warranty valid for 25 years.",
                citationName: "Zillow Solar Premium Study"
            ),
            "leased": AnswerFeedback(
                badge: "Insight",
                title: "Leased solar can complicate sales. Buyers must qualify to assume the lease.",
                subhead: "Keeping the contract handy speeds the resale process.",
                citationName: "Lawrence Berkeley National Laboratory"
            ),
        ],

        // MARK: Q22 — Generator
        "q22_generator": [
            "whole_home": AnswerFeedback(
                badge: "Insight",
                title: "Whole-home generators add ~$10K to resale value in storm-prone areas like {state}.",
                subhead: "Annual load tests catch failure modes before they leave you in the dark.",
                citationName: "NAR Hurricane Preparedness Survey"
            ),
        ],

        // MARK: Q23 — Vehicle count
        "q23_vehicle_count": [
            "1": AnswerFeedback(
                badge: "Insight",
                title: "Tracking one car saves ~$400/yr in missed-service surprises.",
                subhead: "Most expensive vehicle problems start as ignored small ones.",
                citationName: "AAA Your Driving Costs Report"
            ),
            "2": AnswerFeedback(
                badge: "Insight",
                title: "Households tracking 2+ vehicles save ~$800/yr in surprise repairs.",
                subhead: "Synchronized service schedules avoid double trips to the shop.",
                citationName: "AAA Your Driving Costs Report"
            ),
        ],

        // MARK: Q25 — Garage / EV
        "q25_garage_ev": [
            "ev_l2": AnswerFeedback(
                badge: "Insight",
                title: "Level 2 chargers add $2-5K to resale value as EV adoption grows in {state}.",
                subhead: "Permits and installer records boost the premium at sale time.",
                citationName: "Rocky Mountain Institute EV Report"
            ),
        ],

        // MARK: Q5 — Mortgage
        "q5_mortgage": [
            "yes": AnswerFeedback(
                badge: "Insight",
                title: "Borrowers who refinance once during their loan save an average of $40K.",
                subhead: "We'll watch rate movements and flag when refi math works for you.",
                citationName: "Freddie Mac Refinance Study"
            ),
        ],

        // MARK: Q18 — Trash
        "q18_trash": [
            "private": AnswerFeedback(
                badge: "Insight",
                title: "Tracking pickup days and renewals saves the average household $120/yr.",
                subhead: "Late-fee surprises are the #1 utility billing complaint.",
                citationName: "Waste Business Journal"
            ),
        ],
    ]
}
