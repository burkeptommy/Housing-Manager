import SwiftUI
import PhotosUI

/// Phase 84.5 — Pre-visit prep card. Shown on the dashboard alongside
/// `HomeAssessmentPendingCard` when status is pending or scheduled and
/// the homeowner hasn't filled out pre-visit notes yet. Surfaces three
/// optional actions:
///   • Add notes for your handyman (writes to `pre_visit_notes`)
///   • Upload photos (writes to `pre_visit_photos`)
///   • Tell us about your home (5-question pre-visit quiz writes
///     to `captured_attributes` — year built, sq ft, has_pets, parking,
///     special access)
struct HomeAssessmentPrepCard: View {
    let assessment: HomeAssessmentRow

    /// Sheet presenter — opens a small editor for the chosen action.
    let onOpenNotes: () -> Void
    let onOpenPhotos: () -> Void
    let onOpenPrepQuiz: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text("HELP US PREP")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.action)
                Spacer()
            }

            Text("Make the visit faster — share anything that helps us prepare.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            VStack(spacing: 8) {
                prepRow(icon: "pencil",
                        title: "Add notes for your handyman",
                        subtitle: notesSubtitle,
                        complete: !(assessment.preVisitNotes ?? "").isEmpty,
                        action: onOpenNotes)
                prepRow(icon: "photo.on.rectangle",
                        title: "Upload photos",
                        subtitle: photosSubtitle,
                        complete: !(assessment.preVisitPhotos ?? []).isEmpty,
                        action: onOpenPhotos)
                prepRow(icon: "list.bullet.rectangle",
                        title: "Tell us about your home",
                        subtitle: prepQuizSubtitle,
                        complete: prepQuizComplete,
                        action: onOpenPrepQuiz)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .fill(HavenColors.creamLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .stroke(HavenColors.beige300, lineWidth: 1)
        )
    }

    private func prepRow(
        icon: String,
        title: String,
        subtitle: String,
        complete: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: complete ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 18))
                    .foregroundStyle(complete ? HavenColors.success : HavenColors.action)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.background)
            )
        }
        .buttonStyle(.plain)
    }

    private var notesSubtitle: String {
        if let n = assessment.preVisitNotes, !n.isEmpty {
            return n.count > 60 ? String(n.prefix(60)) + "…" : n
        }
        return "Anything they should know"
    }

    private var photosSubtitle: String {
        let count = assessment.preVisitPhotos?.count ?? 0
        if count == 0 { return "Photos of systems or rooms to focus on" }
        return "\(count) photo\(count == 1 ? "" : "s") attached"
    }

    private var prepQuizSubtitle: String {
        if prepQuizComplete { return "Pre-visit info complete" }
        return "Year built, parking, pets, special access"
    }

    private var prepQuizComplete: Bool {
        // Treat the quiz as complete when at least 3 of the prep keys
        // have been answered.
        let attrs = assessment.capturedAttributes ?? [:]
        let keys = ["year_built", "square_footage", "has_pets",
                    "parking_instructions", "special_access"]
        return keys.filter { attrs[$0] != nil }.count >= 3
    }
}
