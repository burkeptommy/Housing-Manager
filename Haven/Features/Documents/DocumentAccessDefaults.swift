import Foundation

/// Single source of truth for which document categories default to
/// home-manager-visible vs home-manager-private at upload time.
///
/// Build 87 (Home Manager expansion): Home managers (`family_members.member_type
/// = 'home_manager'`) are linked household users with full editing access to
/// tasks, systems, and projects, but should NOT automatically see estate,
/// legal, financial, or medical documents. The category list below is the
/// authoritative source — when a new `DocumentInsert` is created, the
/// `visibleToHomeManagers` field is set from `visibleToHomeManagers(for:)`.
///
/// Categories are stored in two forms in `documents.category` depending on
/// the upload path:
/// - Manual / quiz / Edge Function classification: Title Case strings from
///   `DocumentCategory` raw values ("Will", "Power of Attorney", etc.).
/// - Legacy / email-forwarded paths sometimes use snake_case strings.
///
/// We accept both by lowercasing the input and matching against a set that
/// also stores everything lowercased.
///
/// **Keep in sync** with the TypeScript `PRIVATE_FROM_HOME_MANAGERS` constant
/// in `supabase/functions/receive-email/index.ts`,
/// `supabase/functions/process-inbox-item/index.ts`, and
/// `supabase/functions/analyze-document/index.ts`.
///
/// **Keep in sync** with the SQL backfill in
/// `supabase/migrations/20260440_document_home_manager_access_backfill.sql`.
enum DocumentAccessDefaults {
    /// Categories that are HIDDEN from home managers by default. All entries
    /// are lowercased so the lookup can normalize either Title Case or
    /// snake_case input. Anything NOT in this set is visible by default.
    static let privateFromHomeManagers: Set<String> = [
        // Estate Planning — DocumentCategory raw values + legacy snake_case
        "will",
        "trust",
        "power of attorney",
        "power_of_attorney",
        "healthcare directive",
        "healthcare_directive",
        "guardianship designation",
        "letter of intent",
        "living_will",
        "estate_plan",
        "beneficiary designation",
        "beneficiary_designation",

        // Financial Accounts
        "brokerage account",
        "retirement account (ira/401k)",
        "bank account",
        "529 plan",
        "stock options/rsus",
        "crypto wallet",
        "alternative investments",
        "financial_account",
        "investment_statement",
        "bank_statement",

        // Tax Records (returns and detailed records — bills are visible)
        "federal tax return",
        "state tax return",
        "gift tax return (form 709)",
        "property tax record",
        "estate & trust return (form 1041)",
        "tax_return",
        "tax_document",

        // Life / Long-Term / Disability Insurance (often names beneficiaries)
        "life insurance",
        "long-term care insurance",
        "disability insurance",
        "life_insurance",

        // Medical / Health (legacy snake_case — not in DocumentCategory enum
        // but may appear from email pipeline classifications)
        "medical_record",
        "health_insurance",

        // Legal (legacy)
        "legal_agreement",

        // Government IDs
        "passport",
        "birth certificate",
        "marriage certificate",
        "divorce decree",
        "social security card",
        "citizenship/immigration",
        "death certificate",
        "birth_certificate",
        "marriage_certificate",
        "divorce_decree",
        "social_security",
    ]

    /// Default `visible_to_home_managers` value for a new document based on
    /// its category. Nil or unknown categories default to visible (the safer
    /// choice for general home management documents).
    static func visibleToHomeManagers(for category: String?) -> Bool {
        guard let category = category?.lowercased() else { return true }
        return !privateFromHomeManagers.contains(category)
    }
}
