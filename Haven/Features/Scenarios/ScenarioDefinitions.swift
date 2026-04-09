import SwiftUI

// MARK: - Scenario Category

enum ScenarioCategory: String, CaseIterable, Identifiable {
    // Build 87: reordered home-first per Tom's TestFlight feedback. Haven
    // is a home-property app first, an estate-planning app second, so the
    // category list now opens with Home & Property and tucks Estate &
    // Legacy at the bottom. The order ScenarioStudioView renders is taken
    // straight from `allCases`.
    case home = "Home & Property"
    case tax = "Tax & Savings"
    case insurance = "Insurance & Protection"
    case kids = "Kids & Education"
    case wealth = "Wealth & Business"
    case estate = "Estate & Legacy"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .estate: return "🏛️"
        case .tax: return "💰"
        case .home: return "🏠"
        case .wealth: return "📊"
        case .kids: return "🎓"
        case .insurance: return "🛡️"
        }
    }

    var teaser: String {
        switch self {
        case .estate: return "What happens to your family, assets, and plans if the unexpected occurs"
        case .tax: return "Find hidden deductions, credits, and strategies that could save thousands"
        case .home: return "Refinance, sell, renovate, or rent — see the real numbers"
        case .wealth: return "Business structures, trusts, and wealth-building strategies"
        case .kids: return "Education funding, 529 plans, and planning for their future"
        case .insurance: return "Are you covered? See what happens when you need your safety net"
        }
    }

    var scenarios: [ScenarioDefinition] {
        ScenarioDefinition.all.filter { $0.category == self }
    }
}

// MARK: - Param Types

enum ParamType {
    case text, currency, picker, slider
}

struct ParamField: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let type: ParamType
    let options: [String]?
    let defaultValue: String?
}

// MARK: - Scenario Definition

struct ScenarioDefinition: Identifiable {
    let id: String
    let title: String
    let teaser: String
    let icon: String
    let category: ScenarioCategory
    let requiresParams: Bool
    let paramFields: [ParamField]?

    // MARK: - All Scenarios

    static let all: [ScenarioDefinition] = home + tax + insurance + kids + wealth + estate

    // MARK: Estate & Legacy

    static let estate: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "estate_both_die",
            title: "If we were both gone tomorrow",
            teaser: "Full estate flow — who gets what, what's protected, what's at risk",
            icon: "person.2.slash",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_spouse_dies",
            title: "If only my spouse passed",
            teaser: "Joint vs. individual assets, survivor benefits, next steps",
            icon: "person.slash",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_incapacitated",
            title: "If I became incapacitated",
            teaser: "Who has power of attorney, healthcare decisions, access to accounts",
            icon: "bed.double",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_wrong_beneficiaries",
            title: "What if I die before updating my beneficiaries?",
            teaser: "Show which accounts bypass the trust and where the money actually goes",
            icon: "exclamationmark.arrow.triangle.2.circlepath",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_probate",
            title: "What does probate look like for my estate?",
            teaser: "What's in the trust vs. what isn't — cost and timeline of probate",
            icon: "building.columns",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_kids_early_money",
            title: "What if my kids need the money before age 30?",
            teaser: "Trust distribution rules, hardship provisions, trustee discretion",
            icon: "clock.badge.questionmark",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "estate_guardian_cant_serve",
            title: "What if the guardian I named can't serve?",
            teaser: "Successor chain, court appointment process, how to prepare",
            icon: "person.badge.key",
            category: .estate,
            requiresParams: false,
            paramFields: nil
        ),
    ]

    // MARK: Tax & Savings

    static let tax: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "tax_renovation",
            title: "What if I did a home renovation?",
            teaser: "Tax deductions, energy credits, cost basis increase",
            icon: "hammer",
            category: .tax,
            requiresParams: true,
            paramFields: [
                ParamField(key: "renovation_type", label: "Type of renovation", type: .picker, options: ["Kitchen", "Bathroom", "Basement", "Addition", "Energy/Solar", "Roof", "Landscaping", "Other"], defaultValue: "Kitchen"),
                ParamField(key: "budget", label: "Estimated budget", type: .currency, options: nil, defaultValue: "50000"),
            ]
        ),
        ScenarioDefinition(
            id: "tax_hire_kids",
            title: "What if I hired my kids in my business?",
            teaser: "UTMA, standard deduction, Roth IRA for minors",
            icon: "figure.and.child.holdinghands",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_roth_conversion",
            title: "What if I converted my Traditional IRA to Roth?",
            teaser: "Tax hit now vs. tax-free growth later — the break-even point",
            icon: "arrow.triangle.swap",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_529_max",
            title: "What if I maxed out 529 contributions?",
            teaser: "State tax deduction, growth projections, superfunding option",
            icon: "graduationcap",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_cost_segregation",
            title: "What if I did a cost segregation study?",
            teaser: "Accelerated depreciation on your property — potential huge deduction",
            icon: "chart.bar.doc.horizontal",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_1031_exchange",
            title: "What if I did a 1031 exchange?",
            teaser: "Defer capital gains by reinvesting in like-kind property",
            icon: "arrow.left.arrow.right",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_qcd",
            title: "What if I donated to charity from my IRA?",
            teaser: "Qualified Charitable Distribution benefits after age 70½",
            icon: "heart.circle",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "tax_home_office",
            title: "What if I took the home office deduction?",
            teaser: "Square footage method vs. simplified — which saves more",
            icon: "desktopcomputer",
            category: .tax,
            requiresParams: false,
            paramFields: nil
        ),
    ]

    // MARK: Home & Property

    static let home: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "home_refinance",
            title: "What if I refinanced my mortgage?",
            teaser: "Break-even analysis with current rates, monthly savings",
            icon: "percent",
            category: .home,
            requiresParams: true,
            paramFields: [
                ParamField(key: "new_rate", label: "New interest rate", type: .text, options: nil, defaultValue: "6.5"),
                ParamField(key: "new_term", label: "New term", type: .picker, options: ["15 years", "20 years", "30 years"], defaultValue: "30 years"),
            ]
        ),
        ScenarioDefinition(
            id: "home_sell",
            title: "What if I sold my house today?",
            teaser: "Net proceeds after mortgage, closing costs, and capital gains",
            icon: "dollarsign.arrow.circlepath",
            category: .home,
            requiresParams: true,
            paramFields: [
                ParamField(key: "sale_price", label: "Estimated sale price", type: .currency, options: nil, defaultValue: nil),
            ]
        ),
        ScenarioDefinition(
            id: "home_rent_out",
            title: "What if I rented out my house?",
            teaser: "Cash flow analysis, tax implications, landlord considerations",
            icon: "key.fill",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "home_finish_basement",
            title: "What if I finished my basement?",
            teaser: "Cost vs. value added, ROI analysis, permit requirements",
            icon: "square.stack.3d.down.right",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "home_solar",
            title: "What if I added solar panels?",
            teaser: "30% federal credit, payback period, energy savings",
            icon: "sun.max.trianglebadge.exclamationmark",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "home_roof_replacement",
            title: "What if my roof needed replacement?",
            teaser: "Insurance claim process, depreciation, out-of-pocket estimate",
            icon: "house.lodge",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "home_transfer_trust",
            title: "What if I transferred my home to my trust?",
            teaser: "Why it matters, deed retitling steps, avoiding probate",
            icon: "doc.on.doc",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "home_value_drop",
            title: "What if my home value dropped 20%?",
            teaser: "Equity impact, underwater scenarios, strategic options",
            icon: "chart.line.downtrend.xyaxis",
            category: .home,
            requiresParams: false,
            paramFields: nil
        ),
    ]

    // MARK: Wealth & Business

    static let wealth: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "wealth_llc",
            title: "What if I set up an LLC for my business?",
            teaser: "Liability protection, tax options, formation steps",
            icon: "building.2",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_business_in_trust",
            title: "What if I put my business in my trust?",
            teaser: "Estate planning benefits, succession planning, tax implications",
            icon: "briefcase",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_sep_ira",
            title: "What if I set up a SEP-IRA or Solo 401(k)?",
            teaser: "Contribution limits, tax savings, which is right for you",
            icon: "banknote",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_scorp",
            title: "What if I started paying myself a salary from my LLC?",
            teaser: "S-Corp election, FICA savings, reasonable compensation",
            icon: "creditcard",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_irrevocable_trust",
            title: "What if I created an irrevocable trust?",
            teaser: "Asset protection, estate tax reduction, loss of control trade-off",
            icon: "lock.doc",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_annual_gifting",
            title: "What if I gifted money to my kids annually?",
            teaser: "$18K exclusion, 529 superfunding, lifetime exemption strategy",
            icon: "gift",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_ilit",
            title: "What if I bought life insurance inside an ILIT?",
            teaser: "Remove insurance proceeds from your taxable estate",
            icon: "shield.lefthalf.filled",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "wealth_utma",
            title: "What if I set up a UTMA for each child?",
            teaser: "Pros, cons, kiddie tax rules, vs. 529 comparison",
            icon: "person.crop.circle.badge.plus",
            category: .wealth,
            requiresParams: false,
            paramFields: nil
        ),
    ]

    // MARK: Kids & Education

    static let kids: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "kids_529_private_school",
            title: "What if my kids need 529 money for private school?",
            teaser: "K-12 withdrawal rules, $10K annual limit, state impact",
            icon: "book",
            category: .kids,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "kids_scholarships",
            title: "What if my kids get scholarships?",
            teaser: "529 penalty-free withdrawal options, Roth rollover",
            icon: "trophy",
            category: .kids,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "kids_superfund_529",
            title: "What if I superfunded the 529s?",
            teaser: "5-year gift tax election — front-load $90K per child",
            icon: "arrow.up.right",
            category: .kids,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "kids_college_costs_double",
            title: "What if college costs double by then?",
            teaser: "Projection calculator based on your kids' ages and 529 balances",
            icon: "chart.line.uptrend.xyaxis",
            category: .kids,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "kids_no_college",
            title: "What if one kid doesn't go to college?",
            teaser: "Beneficiary change, Roth rollover option, penalty-free alternatives",
            icon: "arrow.triangle.branch",
            category: .kids,
            requiresParams: false,
            paramFields: nil
        ),
    ]

    // MARK: Insurance & Protection

    static let insurance: [ScenarioDefinition] = [
        ScenarioDefinition(
            id: "insurance_sued",
            title: "What if I got sued?",
            teaser: "Umbrella coverage analysis, asset exposure, protection gaps",
            icon: "exclamationmark.shield",
            category: .insurance,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "insurance_house_fire",
            title: "What if my house burned down?",
            teaser: "Full insurance claim walkthrough, coverage gaps, timeline",
            icon: "flame",
            category: .insurance,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "insurance_disability",
            title: "What if I became disabled?",
            teaser: "Disability coverage gap analysis, income replacement",
            icon: "figure.roll",
            category: .insurance,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "insurance_ltc",
            title: "What if I needed long-term care?",
            teaser: "Cost projections, no LTC policy impact, Medicaid planning",
            icon: "cross.case",
            category: .insurance,
            requiresParams: false,
            paramFields: nil
        ),
        ScenarioDefinition(
            id: "insurance_life_not_enough",
            title: "What if my life insurance wasn't enough?",
            teaser: "Coverage gap calculator — income replacement, debts, education",
            icon: "chart.bar.xaxis.ascending.badge.clock",
            category: .insurance,
            requiresParams: false,
            paramFields: nil
        ),
    ]
}
