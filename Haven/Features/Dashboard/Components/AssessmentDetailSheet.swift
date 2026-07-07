import SwiftUI

/// Round 5 (May 2026, friend feedback): consolidated detail view for the
/// Free Assessment workflow. Replaces the old dashboard pattern of TWO
/// stacked cards (HomeAssessmentPendingCard + HomeAssessmentPrepCard).
///
/// The friend complaint: "I need to be able to click into that card to
/// get the details — when are they coming, why, what are they doing at
/// my house, who is coming." Plus the dashboard had two separate cards
/// for the same conceptual thing (the visit + prepping for the visit),
/// which felt bulky.
///
/// Solution: dashboard now shows ONE assessment card. Tapping it opens
/// this sheet, which includes visit details + the prep checklist + the
/// reschedule / switch-to-DIY actions. The standalone "Help us prep"
/// card is gone from the dashboard.
struct AssessmentDetailSheet: View {
    let assessment: HomeAssessmentRow
    let handymanFirstName: String?

    /// All four callbacks delegate to existing DashboardView plumbing —
    /// `AssessmentDetailSheet` doesn't own any DB writes. Keeps this
    /// view as a pure presentation layer.
    let onReschedule: () -> Void
    let onSwitchToDIY: () -> Void
    let onOpenNotes: () -> Void
    let onOpenPhotos: () -> Void
    let onOpenPrepQuiz: () -> Void

    @Environment(\.dismiss) private var dismiss

    private static let scheduledDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                    visitBlock
                    if assessment.status == .pending || assessment.status == .scheduled {
                        prepBlock
                    }
                    actionsBlock
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Your assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Visit block

    private var visitBlock: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text(statusLabel.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.action)
                Spacer()
            }

            Text(headline)
                .font(HavenTypography.fraunces(size: 24, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let scheduledLine = scheduledLine {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                    Text(scheduledLine)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .padding(.vertical, 4)
            }

            Text(subtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Who's coming + what they'll do.
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                detailRow(
                    icon: "person.fill",
                    title: "Who's coming",
                    body: handymanFirstName.map { "\($0), your Chez handyman" }
                        ?? "Chez is finding the right handyman for your area. You'll see their name and credentials here as soon as they're assigned."
                )
                detailRow(
                    icon: "checklist",
                    title: "What we'll do",
                    body: "A 60-90 minute walk-through to capture your home's systems, vendors, manuals, and any items that need follow-up. Free of charge, with no work or upsell during the visit."
                )
                detailRow(
                    icon: "house.fill",
                    title: "What you need to do",
                    body: "Be home (or unlock the door) when they arrive. The 'Help us prep' checklist below makes the visit faster but is all optional."
                )
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .fill(HavenColors.action.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Prep block

    private var prepBlock: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text("HELP US PREP")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.action)
                Spacer()
            }

            Text("Optional, but it makes the visit faster.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            VStack(spacing: 8) {
                prepRow(
                    icon: "pencil",
                    title: "Add notes for your contractor",
                    subtitle: notesSubtitle,
                    complete: !(assessment.preVisitNotes ?? "").isEmpty,
                    action: onOpenNotes
                )
                prepRow(
                    icon: "photo.on.rectangle",
                    title: "Upload photos",
                    subtitle: photosSubtitle,
                    complete: !(assessment.preVisitPhotos ?? []).isEmpty,
                    action: onOpenPhotos
                )
                prepRow(
                    icon: "list.bullet.rectangle",
                    title: "Tell us about your home",
                    subtitle: prepQuizSubtitle,
                    complete: prepQuizComplete,
                    action: onOpenPrepQuiz
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .fill(HavenColors.creamLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.beige300, lineWidth: 1)
        )
    }

    // MARK: - Actions block

    private var actionsBlock: some View {
        VStack(spacing: HavenTheme.spacing12) {
            if assessment.status == .pending || assessment.status == .scheduled {
                Button {
                    onReschedule()
                    dismiss()
                } label: {
                    Text("Reschedule")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .stroke(HavenColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onSwitchToDIY()
                    dismiss()
                } label: {
                    Text("Do this myself instead")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func detailRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 22, height: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(body)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(HavenColors.background)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var statusIcon: String {
        switch assessment.status {
        case .pending: return "calendar.badge.clock"
        case .scheduled: return "calendar.badge.checkmark"
        case .enRoute: return "car.fill"
        case .inProgress: return "person.fill.checkmark"
        case .submitted, .awaitingReview: return "hourglass"
        case .correctionsRequested: return "exclamationmark.triangle.fill"
        case .ingestionFailed: return "exclamationmark.octagon"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    private var statusLabel: String {
        switch assessment.status {
        case .pending: return "Free assessment"
        case .scheduled: return "Visit scheduled"
        case .enRoute: return "On the way"
        case .inProgress: return "At your home"
        case .submitted, .awaitingReview: return "Awaiting review"
        case .correctionsRequested: return "Follow-up needed"
        case .ingestionFailed: return "Setup paused"
        case .completed: return "Visit complete"
        case .cancelled: return "Cancelled"
        }
    }

    private var headline: String {
        switch assessment.status {
        case .pending: return "Your handyman is being assigned."
        case .scheduled: return "Your Chez handyman visit is scheduled."
        case .enRoute: return "Your handyman is on the way."
        case .inProgress: return "Your handyman is at your home."
        case .submitted: return "We're setting up your home now."
        case .awaitingReview: return "Your home is set up."
        case .correctionsRequested: return "We're following up on a few items."
        case .ingestionFailed: return "We hit a snag setting up your home."
        case .completed: return "Welcome to your fully-set-up home."
        case .cancelled: return "Assessment cancelled."
        }
    }

    private var subtitle: String {
        switch assessment.status {
        case .pending where scheduledLine == nil:
            return "Usually within 3 business days. We'll text you with the visit date once it's confirmed. Free of charge."
        case .pending, .scheduled:
            return "We'll text you the morning of. No prep needed. Just be home."
        case .enRoute:
            return "ETA shortly. They'll capture your systems, vendors, and routines."
        case .inProgress:
            return "Capturing systems, vendors, routines, and documents. We'll let you know when they're done."
        case .submitted:
            return "Should be ready in a few minutes."
        case .awaitingReview:
            return "Tap below to review what we captured for you."
        case .correctionsRequested:
            return "Your handyman will return to fix the items you flagged."
        case .ingestionFailed:
            return "Our team is on it. We'll text you once setup completes."
        case .completed:
            return "Everything's been set up for you."
        case .cancelled:
            return "You can switch back to Chez handling it from Settings."
        }
    }

    private var scheduledLine: String? {
        guard let scheduledAt = assessment.scheduledAt else { return nil }
        return "Scheduled for \(Self.scheduledDateFormatter.string(from: scheduledAt))"
    }

    // MARK: - Prep subtitle helpers (copied from HomeAssessmentPrepCard)

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
        let attrs = assessment.capturedAttributes ?? [:]
        let keys = ["year_built", "square_footage", "has_pets",
                    "parking_instructions", "special_access"]
        return keys.filter { attrs[$0] != nil }.count >= 3
    }
}
