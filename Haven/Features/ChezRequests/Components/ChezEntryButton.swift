import SwiftUI

/// Phase 80 — Universal "Have a Chez Home Manager handle this" button.
/// Reusable across every entry point in the app. Tapping it posts the
/// `.openChezRequestComposer` notification with the right category +
/// context payload; `MainTabView` owns the sheet presentation.
///
/// Visual: salmon-tinted pill with a small concierge icon and a
/// trailing arrow chevron. Designed to be visually distinct from
/// regular CTAs (this is the premium escape hatch) but not
/// overwhelming on screens that already have other actions.
struct ChezEntryButton: View {
    let category: ChezCategory
    let label: String
    var caption: String? = nil
    let context: [String: String]

    var body: some View {
        Button(action: presentComposer) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let caption {
                        Text(caption)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        Text("Tom replies within 1 business day.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(HavenColors.action.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func presentComposer() {
        Haptics.light()
        var info: [String: Any] = ["category": category.rawValue]
        info["context"] = context
        NotificationCenter.default.post(
            name: .openChezRequestComposer,
            object: nil,
            userInfo: info
        )
    }
}

// MARK: - Inbox entry helpers

/// Phase 80 — keeps the inbox-specific category / copy / context-payload
/// rules in one place so `InboxItemDetailView` doesn't have to inline a
/// big switch and the rules are easy to evolve as new inbox types come
/// online. Pure functions, no state.
enum ChezInboxEntryHelper {
    /// Inbox types that get a Chez entry below the standard action stack.
    /// Add new types here as more high-value inbox surfaces come online.
    private static let supportedTypes: Set<String> = [
        "contractor_quote",
        "insurance_claim",
        "bill_invoice",
        "project_created",  // when a project is auto-created from an email — owner often wants help
    ]

    static func shouldRender(for type: String) -> Bool {
        supportedTypes.contains(type)
    }

    static func category(for type: String) -> ChezCategory {
        switch type {
        case "contractor_quote": return .getQuote
        case "insurance_claim": return .coordinateTask
        case "bill_invoice": return .general
        case "project_created": return .coordinateTask
        default: return .general
        }
    }

    static func label(for type: String) -> String {
        switch type {
        case "contractor_quote": return "Have Chez get a second quote"
        case "insurance_claim": return "Have Chez run point on this claim"
        case "bill_invoice": return "Have Chez review this bill"
        case "project_created": return "Have Chez handle this project"
        default: return "Have Chez handle this"
        }
    }

    static func caption(for type: String) -> String {
        switch type {
        case "contractor_quote":
            return "Tom gathers a comparable bid and a fair-market read."
        case "insurance_claim":
            return "Tom coordinates with the adjuster, contractors, and you."
        case "bill_invoice":
            return "Tom checks for fair pricing, errors, or overcharges."
        case "project_created":
            return "Tom owns the back-and-forth so you don't have to."
        default:
            return "Tom replies within 1 business day."
        }
    }

    static func context(item: DatabaseService.InboxItemRow, type: String) -> [String: String] {
        var c: [String: String] = [
            "inbox_item_id": item.id.uuidString,
            "inbox_type": type,
            "title": item.title,
        ]
        if let summary = item.summary, !summary.isEmpty {
            c["summary"] = String(summary.prefix(400))
        }
        if let from = item.fromEmail, !from.isEmpty {
            c["from"] = from
        }
        if let vendor = item.metadata?.vendorName, !vendor.isEmpty {
            c["vendor"] = vendor
        }
        if let amount = item.metadata?.billAmount, amount > 0 {
            c["amount"] = "$\(Int(amount))"
        }
        if let cat = item.metadata?.suggestedCategory, !cat.isEmpty {
            c["category"] = cat
        }
        if let projId = item.relatedProjectId?.uuidString {
            c["project_id"] = projId
        }
        if let docId = item.relatedDocumentId?.uuidString {
            c["document_id"] = docId
        }
        return c
    }
}
