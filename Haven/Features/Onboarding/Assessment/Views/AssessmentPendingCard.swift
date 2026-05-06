import SwiftUI

/// Phase 84.5 — Dashboard card shown after a homeowner picks "Send a
/// Chez handyman" but before the visit happens (or while it's
/// in-progress).
///
/// Renders one of three states:
///   • `.pending`    — visit not yet scheduled. Shows a "scheduling soon" copy.
///   • `.scheduled`  — visit dispatched. Shows handyman + verification code (G39),
///                     reschedule + cancel buttons (G40), multi-session indicator (G32).
///   • `.inProgress` — handyman is at the home. Shows a live-progress strip (G38, future).
///
/// Tapping the card opens an action sheet with reschedule / cancel /
/// "I'd like to do this myself instead" (escape hatch flips
/// assessment_mode to nil and surfaces the quiz card).
struct AssessmentPendingCard: View {
    let assessment: HomeAssessmentRow
    let handymanName: String?
    let handymanPhotoURL: URL?
    let verificationCode: String?

    let onReschedule: () -> Void
    let onCancel: () -> Void
    let onSwitchToSelf: () -> Void

    @State private var showActionSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            sectionHeader
            statusBlock
            if assessment.status == .scheduled {
                handymanIntro
            }
            if assessment.sessionCount > 1 {
                multiSessionBadge
            }
            actionsRow
        }
        .padding(HavenTheme.spacing20)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
        .havenShadow()
        .confirmationDialog("Assessment options", isPresented: $showActionSheet) {
            Button("Reschedule visit", action: onReschedule)
            Button("Cancel visit", role: .destructive, action: onCancel)
            Button("I'd like to do this myself instead") { onSwitchToSelf() }
            Button("Close", role: .cancel) {}
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("CHEZ HANDYMAN VISIT")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Button {
                showActionSheet = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusHeadline)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text(statusSubtitle)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private var handymanIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                if let photoURL = handymanPhotoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Circle().fill(HavenColors.beige200)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(HavenColors.action.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(HavenColors.action)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(handymanName ?? "Your Chez handyman")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let code = verificationCode {
                        Text("Code: \(code)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        Text("Coming soon")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
            }
            if verificationCode != nil {
                Text("Ask your handyman for this code at the door. It's how you know they're with Chez.")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var multiSessionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
            Text("Visit \(assessment.sessionCount) of multi-part assessment")
                .font(HavenTypography.uiLabelSmall)
        }
        .foregroundStyle(HavenColors.textSecondary)
    }

    private var actionsRow: some View {
        HStack {
            Button(action: onReschedule) {
                Text("Reschedule")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.action)
            }
            Spacer()
            if assessment.isPendingVisit {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    private var statusHeadline: String {
        switch assessment.status {
        case .pending:
            return "Scheduling your free visit"
        case .scheduled:
            if let scheduledAt = assessment.scheduledAt {
                let f = DateFormatter()
                f.dateStyle = .medium
                f.timeStyle = .short
                return "Visit on \(f.string(from: scheduledAt))"
            }
            return "Visit scheduled"
        case .enRoute:
            return "Your handyman is on the way"
        case .inProgress:
            return "Your handyman is at your home"
        case .submitted:
            return "Visit complete. Finalizing"
        case .ingestionFailed:
            return "Setup hit a snag"
        default:
            return "Visit pending"
        }
    }

    private var statusSubtitle: String {
        switch assessment.status {
        case .pending:
            return "We're matching you with a Chez handyman in your area. You'll get a text when they're scheduled."
        case .scheduled:
            return "We'll text you the morning of. Most visits take about 90 minutes."
        case .enRoute:
            return "They'll let themselves in if you've shared access instructions."
        case .inProgress:
            return "Capturing every system, vendor, and document. We'll notify you when they're done."
        case .submitted:
            return "Setting up your home in Chez now."
        case .ingestionFailed:
            return "Something went wrong on our end. Chez has been notified. We'll reach out shortly."
        default:
            return ""
        }
    }
}
