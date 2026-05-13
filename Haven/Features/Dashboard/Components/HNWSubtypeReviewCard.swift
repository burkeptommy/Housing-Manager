import SwiftUI

/// Phase 3.1: Dashboard prompt that surfaces the Phase 57 HNW subtype
/// review to recently-created properties. Mirrors the WhatsNewPhase57Card
/// pattern but flips the cutoff: this card shows to NEW properties (less
/// than 14 days old) so the homeowner gets the additional vendor
/// routines questionnaire shortly after onboarding, while the household
/// is still actively configuring the home.
///
/// Existing properties more than 14 days old never render this card —
/// they have their own pathway via WhatsNewPhase57Card.
///
/// Dismissed state is per-property (comma-joined UUID list) so a
/// household with multiple addresses can review each one independently.
struct HNWSubtypeReviewCard: View {
    let property: PropertyRow
    var onReviewComplete: (() -> Void)? = nil

    @AppStorage("hnwSubtypeReviewDismissed") private var dismissedRaw: String = ""
    @State private var showReview = false

    /// Window (in days) after `property.createdAt` during which the
    /// card is eligible to surface. Tuned for the first two weeks of
    /// onboarding — long enough for the user to actually open the
    /// dashboard and notice, short enough that the prompt isn't still
    /// firing six months later.
    static let visibilityWindowDays: Int = 14

    private var dismissedIds: Set<String> {
        Set(dismissedRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })
    }

    private var isDismissed: Bool {
        dismissedIds.contains(property.id.uuidString)
    }

    private func markDismissed() {
        var ids = dismissedIds
        ids.insert(property.id.uuidString)
        dismissedRaw = ids.sorted().joined(separator: ",")
    }

    private var shouldShow: Bool {
        guard !isDismissed else { return false }
        guard let createdAt = property.createdAt else { return false }
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)
        let windowSeconds = Double(Self.visibilityWindowDays) * 24 * 60 * 60
        // Render when the property was created less than N days ago.
        return interval >= 0 && interval <= windowSeconds
    }

    private var regionalPack: RegionalPack? {
        if let stored = property.regionalPack,
           let parsed = RegionalPack(rawValue: stored) {
            return parsed
        }
        return RegionalPack(state: property.state)
    }

    private var bodyText: String {
        let regional = regionalPack == .northeast
            ? " (radon, humidifier service, and more for Northeast homes)"
            : ""
        return "Take 2 minutes to confirm which premium routines apply to your home\(regional). Chez only schedules what you confirm."
    }

    var body: some View {
        if shouldShow {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(HavenColors.action)
                        Text("REVIEW YOUR HOME")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Button {
                            Haptics.light()
                            markDismissed()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .accessibilityLabel("Dismiss")
                    }

                    Text(bodyText)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)

                    HStack {
                        Button {
                            Haptics.light()
                            showReview = true
                        } label: {
                            Text("Review your home")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(HavenColors.navy800)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $showReview) {
                UpdateHomeDetailsSheet(
                    property: property,
                    onSaved: {
                        markDismissed()
                        onReviewComplete?()
                    }
                )
            }
        }
    }
}
