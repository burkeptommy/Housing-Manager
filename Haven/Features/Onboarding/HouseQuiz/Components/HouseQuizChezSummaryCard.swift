import SwiftUI

/// Phase 2.4: End-of-quiz Chez summary card.
///
/// Surfaces between the install-date sweep (or the bare end of the
/// quiz when no sweep is needed) and `QuizCinematicReveal`. Renders
/// when at least one Chez delegation intent was captured during the
/// quiz so the homeowner sees a tangible "here's what Chez is doing
/// for you" moment before the dignified-number reveal lands.
///
/// User-facing copy is always "Chez" — never an operator name.
struct HouseQuizChezSummaryCard: View {
    let intents: [ChezQuizRequestSubmitter.QuizIntent]
    let onContinue: () -> Void
    let onTapRow: (ChezQuizRequestSubmitter.QuizIntent) -> Void

    private var headline: String {
        let count = intents.count
        if count == 1 {
            return "Chez is taking 1 thing off your plate."
        }
        return "Chez is taking \(count) things off your plate."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text(headline)
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            Text("You'll get a message in your Chez inbox the moment we have options for you.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(Array(intents.enumerated()), id: \.offset) { _, intent in
                    Button {
                        Haptics.light()
                        onTapRow(intent)
                    } label: {
                        row(for: intent)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 52)
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(HavenColors.action.opacity(0.18), lineWidth: 1)
            )

            Button {
                Haptics.medium()
                onContinue()
            } label: {
                Text("Continue")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(HavenColors.navy800)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.pageMargin)
        .background(HavenColors.background)
    }

    @ViewBuilder
    private func row(for intent: ChezQuizRequestSubmitter.QuizIntent) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HavenColors.action.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: rowIcon(for: intent))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(intent.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(rowSubtitle(for: intent))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, HavenTheme.spacing12)
        .contentShape(Rectangle())
    }

    private func rowIcon(for intent: ChezQuizRequestSubmitter.QuizIntent) -> String {
        switch intent.category {
        case .findVendor: return "magnifyingglass"
        case .getQuote: return "doc.text.magnifyingglass"
        case .scheduleVisit: return "calendar.badge.plus"
        case .coordinateTask: return "checkmark.circle"
        case .findHandyman: return "wrench.and.screwdriver.fill"
        case .general: return "bubble.left.and.bubble.right.fill"
        }
    }

    private func rowSubtitle(for intent: ChezQuizRequestSubmitter.QuizIntent) -> String {
        switch intent.category {
        case .findVendor: return "Finding pros · in progress"
        case .getQuote: return "Getting quotes · in progress"
        case .scheduleVisit: return "Scheduling · in progress"
        case .coordinateTask: return "Coordinating · in progress"
        case .findHandyman: return "Finding a handyman · in progress"
        case .general: return "On it · in progress"
        }
    }
}

#if DEBUG
#Preview {
    let demoIntents: [ChezQuizRequestSubmitter.QuizIntent] = [
        .init(questionId: "q11_lawn", slotKey: "chezHandles", label: "Find a landscaper", category: .findVendor, systemCategory: "Landscaping", chipId: nil),
        .init(questionId: "q22_generator", slotKey: "chezHandles", label: "Quote a generator install", category: .getQuote, systemCategory: "Generator", chipId: nil),
        .init(questionId: "q26_insurance", slotKey: "chezHandlesHome", label: "Shop home insurance", category: .general, systemCategory: "home_insurance", chipId: nil),
    ]
    return ScrollView {
        HouseQuizChezSummaryCard(
            intents: demoIntents,
            onContinue: { },
            onTapRow: { _ in }
        )
    }
    .background(HavenColors.background)
}
#endif
