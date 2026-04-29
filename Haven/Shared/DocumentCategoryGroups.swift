import Foundation

/// All valid document categories, grouped by section.
/// Matches the VALID_CATEGORIES array in analyze-document Edge Function.
enum DocumentCategoryGroups {
    static let all: [(section: String, categories: [String])] = [
        // Chez v1: "Estate Planning" group removed from the picker. Estate
        // categories still exist as raw values so legacy uploads decode,
        // but they're no longer offered to users.
        ("Entity Documents", [
            "LLC Operating Agreement", "LP Agreement", "S-Corp Documents",
            "EIN Documentation", "Annual Filings", "Bylaws",
        ]),
        ("Real Estate", [
            "Deed", "Mortgage", "Title Insurance", "Survey",
            "HOA Documents", "Lease Agreement", "Property Tax Records",
            "Appraisal Report", "Home Inspection Report",
        ]),
        ("Insurance", [
            "Life Insurance", "Umbrella Insurance", "Homeowners Insurance",
            "Auto Insurance", "Flood Insurance", "Jewelry/Art Rider",
            "Long-Term Care Insurance", "Disability Insurance",
            "Directors & Officers Insurance",
        ]),
        ("Financial Accounts", [
            "Brokerage Account", "Retirement Account (IRA/401k)", "Bank Account",
            "529 Plan", "Beneficiary Designation", "Stock Options/RSUs",
            "Crypto Wallet", "Alternative Investments", "Vehicle Loan Statement",
        ]),
        ("Tax Records", [
            "Federal Tax Return", "State Tax Return", "Gift Tax Return (Form 709)",
            "Property Tax Record", "Estate & Trust Return (Form 1041)",
            "K-1 Partnership Return",
        ]),
        ("Vehicle", [
            "Vehicle Title", "Vehicle Registration",
            "Vehicle Purchase/Lease Agreement", "Emissions Inspection",
        ]),
        ("Personal Property", [
            "Art Appraisal", "Jewelry Appraisal",
            "Collectibles Documentation", "Boat/Aircraft Registration",
        ]),
        ("Digital Assets", [
            "Domain Names", "Digital Account Inventory",
            "Social Media Accounts", "Intellectual Property",
        ]),
        ("Personal Identification", [
            "Passport", "Birth Certificate", "Marriage Certificate",
            "Divorce Decree", "Social Security Card",
            "Citizenship/Immigration", "Death Certificate",
        ]),
        ("Professional & Business", [
            "Employment Agreement", "Non-Compete/NDA", "Partnership Agreement",
            "Buy-Sell Agreement", "Succession Plan",
        ]),
        ("Home Projects", [
            "Project Plan", "Contractor Quote", "Project Invoice",
            "Before/After Photos", "Permit", "Inspection Report",
            "Completion Certificate",
        ]),
        ("Home Records", [
            "Blueprint/Floor Plan", "Property Layout", "Appliance Manual",
            "Warranty Card", "Home Inventory", "Utility Account", "Vendor Contract",
        ]),
        ("Home Financials", [
            "Home Bill/Invoice", "Property Tax Bill", "Utility Bill",
            "Repair Estimate", "Renovation Budget",
        ]),
        ("Other", [
            "Other Personal Documents",
        ]),
    ]

    /// Flat list of all categories for simple lookups
    static let flat: [String] = all.flatMap(\.categories)
}
