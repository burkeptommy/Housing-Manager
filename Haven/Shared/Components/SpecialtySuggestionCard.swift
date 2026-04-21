import SwiftUI

/// Phase 52b: Reusable card that surfaces specialty system suggestions.
/// Used in InvoiceReviewSheet and InboxItemDetailView when the server
/// detects a system the household hasn't registered (e.g. a pool heater
/// invoice when no Pool system exists).
struct SpecialtySuggestionCard: View {
    let suggestion: SpecialtySystemSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HavenCard {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.action)

            Text(headline)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            Text(question)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: HavenTheme.spacing8) {
                HavenButton(
                    title: "Yes, add it",
                    action: onAccept,
                    isFullWidth: true
                )

                HavenButton(
                    title: "Not mine",
                    action: onDismiss,
                    style: .secondary,
                    isFullWidth: true
                )
            }
        }
    }

    // MARK: - Copy

    private var headline: String {
        switch suggestion.source {
        case "invoice":
            return "We noticed this invoice is from a \(suggestion.displayName) service."
        case "document":
            return "This document mentions a \(suggestion.displayName)."
        default:
            return "We found a reference to a \(suggestion.displayName)."
        }
    }

    private var question: String {
        switch suggestion.source {
        case "invoice":
            return "Do you have a \(suggestion.displayName)?"
        default:
            return "Do you have one?"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SpecialtySuggestionCard(
            suggestion: SpecialtySystemSuggestion(
                category: "pool/spa",
                displayName: "Pool",
                subtypeHint: "in_ground",
                evidence: "Invoice from Blue Haven Pools",
                source: "invoice"
            ),
            onAccept: {},
            onDismiss: {}
        )

        SpecialtySuggestionCard(
            suggestion: SpecialtySystemSuggestion(
                category: "generator",
                displayName: "Generator",
                subtypeHint: nil,
                evidence: "Document references a Generac 22kW unit",
                source: "document"
            ),
            onAccept: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(HavenColors.background)
}
