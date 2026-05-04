import SwiftUI

/// Phase 84.5 — Dashboard card shown when a homeowner picked
/// "Have Chez handle it" at signup. Renders status-specific copy
/// across the assessment lifecycle (pending → scheduled → en_route →
/// in_progress → submitted → awaiting_review → completed/cancelled).
///
/// On `awaiting_review` status, tapping the card pushes the user into
/// `AssessmentReviewView` to confirm captured data. On other states
/// it's purely informational with two affordances:
///   • Reschedule (sheet)
///   • "I'd like to do this myself instead" (cancel)
struct HomeAssessmentPendingCard: View {
    let assessment: HomeAssessmentRow
    let handymanFirstName: String?
    let handymanPhotoURL: URL?
    let scheduledWindowText: String?
    /// Phase 85: full handyman trust profile fetched from the
    /// handyman_member_stats view. When present, the card swaps
    /// the compact handymanRow for the richer PreVisitTrustCard
    /// that surfaces credentials, ratings, specialties, and
    /// admin-verified seals.
    var trustProfile: HandymanTrustProfile? = nil

    let onReviewCaptured: () -> Void
    let onReschedule: () -> Void
    let onSwitchToDIY: () -> Void
    var onTapTrustProfile: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusHeader

            VStack(alignment: .leading, spacing: 6) {
                Text(headline)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Phase 85: prefer the richer PreVisitTrustCard when a
            // trust profile is available; fall back to the compact
            // handymanRow otherwise (for assessments that haven't
            // been dispatched yet OR when the trust view fails to load).
            if let trustProfile {
                PreVisitTrustCard(
                    profile: trustProfile,
                    compact: true,
                    onTap: { onTapTrustProfile?() }
                )
            } else {
                handymanRow
            }

            actionRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .fill(HavenColors.action.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .stroke(HavenColors.action.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var statusHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.action)
            Text(statusLabel.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.action)
            Spacer()
        }
    }

    @ViewBuilder
    private var handymanRow: some View {
        if let firstName = handymanFirstName {
            HStack(spacing: 10) {
                handymanAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your handyman")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(firstName)
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                }
                Spacer()
                if let window = scheduledWindowText {
                    Text(window)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.creamLight)
            )
        }
    }

    @ViewBuilder
    private var handymanAvatar: some View {
        if let url = handymanPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle().fill(HavenColors.action.opacity(0.2))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(HavenColors.action.opacity(0.18))
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            .frame(width: 36, height: 36)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        if assessment.status.needsReview {
            Button(action: onReviewCaptured) {
                Text("Review what we captured →")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 10) {
                Button(action: onReschedule) {
                    Text("Reschedule")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(HavenColors.creamLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onSwitchToDIY) {
                    Text("Do this myself")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Copy

    private var statusLabel: String {
        switch assessment.status {
        case .pending: return "Free assessment"
        case .scheduled: return "Visit scheduled"
        case .enRoute: return "On the way"
        case .inProgress: return "Capturing now"
        case .submitted: return "Setting up your home"
        case .awaitingReview: return "Ready to review"
        case .correctionsRequested: return "Following up"
        case .completed: return "All set"
        case .cancelled: return "Cancelled"
        }
    }

    private var statusIcon: String {
        switch assessment.status {
        case .pending: return "calendar.badge.clock"
        case .scheduled: return "calendar.badge.checkmark"
        case .enRoute: return "car.fill"
        case .inProgress: return "wrench.and.screwdriver.fill"
        case .submitted: return "gearshape.2.fill"
        case .awaitingReview: return "checkmark.seal.fill"
        case .correctionsRequested: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    private var headline: String {
        switch assessment.status {
        case .pending:
            return "Your handyman is being assigned."
        case .scheduled:
            if let window = scheduledWindowText {
                return "Your Chez handyman is coming \(window)."
            }
            return "Your Chez handyman visit is scheduled."
        case .enRoute:
            return "Your handyman is on the way."
        case .inProgress:
            return "Your handyman is at your home."
        case .submitted:
            return "We're setting up your home now."
        case .awaitingReview:
            return "Your home is set up."
        case .correctionsRequested:
            return "We're following up on a few items."
        case .completed:
            return "Welcome to your fully-set-up home."
        case .cancelled:
            return "Assessment cancelled."
        }
    }

    private var subtitle: String {
        switch assessment.status {
        case .pending:
            return "We'll text you the morning of your visit. Free of charge."
        case .scheduled:
            return "We'll text you the morning of. No prep needed — just be home."
        case .enRoute:
            return "ETA shortly. They'll capture your systems, vendors, and routines."
        case .inProgress:
            return "Capturing systems, vendors, routines, and documents. We'll let you know when they're done."
        case .submitted:
            return "Should be ready in a few minutes."
        case .awaitingReview:
            return "Tap to review what we captured for you."
        case .correctionsRequested:
            return "Your handyman will return to fix the items you flagged."
        case .completed:
            return "Everything's been set up for you."
        case .cancelled:
            return "You can switch back to Chez handling it from Settings."
        }
    }
}
