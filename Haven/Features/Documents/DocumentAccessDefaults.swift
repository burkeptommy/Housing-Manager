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
/// Categories arrive in two formats in `documents.category` depending on
/// the upload path:
/// - Manual / quiz / Edge Function classification: Title Case strings from
///   `DocumentCategory` raw values ("Will", "Power of Attorney", etc.) or
///   AI-generated approximations from receive-email Claude classification.
/// - Legacy / older email-forwarded paths sometimes use snake_case strings
///   ("power_of_attorney", "bank_statement").
///
/// The lookup function normalizes BOTH formats by lowercasing AND replacing
/// underscores with spaces, then comparing against a set of space-separated
/// lowercased keys. So "Power of Attorney", "power of attorney",
/// "POWER_OF_ATTORNEY", and "power_of_attorney" all collapse to the same
/// lookup key "power of attorney".
///
/// **Keep in sync** with the TypeScript `PRIVATE_FROM_HOME_MANAGERS` constant
/// in `supabase/functions/receive-email/index.ts`,
/// `supabase/functions/process-inbox-item/index.ts`, and
/// `supabase/functions/analyze-document/index.ts`.
///
/// **Keep in sync** with the SQL backfill in
/// `supabase/migrations/20260441_document_home_manager_normalize_backfill.sql`.
enum DocumentAccessDefaults {
    /// Categories that are HIDDEN from home managers by default. All entries
    /// are space-separated lowercased keys; the lookup normalizes input to
    /// match this format. Anything NOT in this set is visible by default.
    static let privateFromHomeManagers: Set<String> = [
        // Estate Planning — DocumentCategory raw values + common Claude
        // classification variants
        "will",
        "trust",
        "power of attorney",
        "healthcare directive",
        "guardianship designation",
        "letter of intent",
        "living will",
        "estate plan",
        "beneficiary designation",

        // Financial Accounts — DocumentCategory raw values + plain variants
        "brokerage account",
        "retirement account (ira/401k)",
        "bank account",
        "529 plan",
        "stock options/rsus",
        "crypto wallet",
        "alternative investments",
        "financial account",
        "investment statement",
        "bank statement",

        // Tax Records — returns and detailed records (bills are visible)
        "federal tax return",
        "state tax return",
        "gift tax return (form 709)",
        "property tax record",
        "estate & trust return (form 1041)",
        "tax return",
        "tax document",

        // Life / Long-Term / Disability Insurance (often names beneficiaries
        // or contains medical underwriting details)
        "life insurance",
        "long-term care insurance",
        "disability insurance",

        // Medical / Health (not in the iOS DocumentCategory enum but common
        // Claude classifications from the email pipeline)
        "medical record",
        "health insurance",

        // Legal (general agreements not covered by the estate categories)
        "legal agreement",

        // Government IDs
        "passport",
        "birth certificate",
        "marriage certificate",
        "divorce decree",
        "social security card",
        "social security",
        "citizenship/immigration",
        "death certificate",
    ]

    /// Default `visible_to_home_managers` value for a new document based on
    /// its category. Nil or unknown categories default to visible (the safer
    /// choice for general home management documents).
    ///
    /// Normalizes the input by lowercasing AND replacing underscores with
    /// spaces, so both Title Case ("Power of Attorney") and legacy
    /// snake_case ("power_of_attorney") collapse to the same lookup key.
    static func visibleToHomeManagers(for category: String?) -> Bool {
        guard let category = category?.lowercased() else { return true }
        let normalized = category.replacingOccurrences(of: "_", with: " ")
        return !privateFromHomeManagers.contains(normalized)
    }
}
