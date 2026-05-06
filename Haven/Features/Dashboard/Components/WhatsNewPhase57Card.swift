import SwiftUI

/// Phase 57: Dashboard card that surfaces the new HNW routines to existing
/// users ("What's New") without dropping tasks on them unannounced. Renders
/// only when:
///   - The property was created before `phase57ReleaseDate`
///   - The user hasn't dismissed the card
///
/// Tapping the card opens `UpdateHomeDetailsSheet` so the user can toggle
/// any new subtype that applies to their home. The reconciler runs on save
/// and creates only the tasks they opted into.
///
/// New users who go through the House Quiz after the release date see the
/// toggles in `UpdateHomeDetailsSheet` (accessible from Settings or the
/// quiz review flow) — this card never renders for them because their
/// `property.createdAt` is after the release cutoff.
struct WhatsNewPhase57Card: View {
    let property: PropertyRow
    var onReviewComplete: (() -> Void)? = nil

    @AppStorage("whatsNewPhase57Dismissed") private var dismissed = false
    @State private var showReview = false

    /// Cutoff date for showing the card. Any property created strictly
    /// before this moment is considered an "existing" user who may benefit
    /// from reviewing the new HNW toggles. Set to the Phase 57 TestFlight
    /// ship date — adjust when the phase actually ships.
    static let phase57ReleaseDate: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 4
        c.day = 20
        return Calendar.current.date(from: c) ?? Date()
    }()

    private var shouldShow: Bool {
        guard !dismissed else { return false }
        guard let createdAt = property.createdAt else {
            // Defensive: if createdAt is somehow nil on an existing row,
            // err on the side of not showing (don't spam).
            return false
        }
        return createdAt < Self.phase57ReleaseDate
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
            ? " including Northeast-specific routines like radon testing and humidifier service"
            : ""
        return "Chez now tracks 10+ additional vendor routines\(regional). Review your home to add what applies. We'll only schedule what you confirm."
    }

    var body: some View {
        if shouldShow {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("NEW ROUTINES AVAILABLE")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Spacer()
                        Button {
                            dismissed = true
                            Haptics.light()
                            Analytics.track(.whatsNewPhase57Dismissed, ["property_id": property.id.uuidString])
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
                            Analytics.track(.whatsNewPhase57Opened, ["property_id": property.id.uuidString])
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
                        dismissed = true
                        onReviewComplete?()
                    }
                )
            }
        }
    }
}
