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
    /// Round 5 (May 2026, friend feedback): tapping the card opens the
    /// new AssessmentDetailSheet (visit details + prep checklist).
    /// Optional so legacy / preview call sites keep working.
    var onTapCard: (() -> Void)? = nil

    var body: some View {
        Button {
            if let onTapCard {
                onTapCard()
            }
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(onTapCard == nil)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                statusHeader
                if onTapCard != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.action.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(headline)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
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

            // Phase 96 — surface the homeowner's preferences on file
            // (initial booking window + reschedule-proposed dates) so
            // the pending card stops reading like a black box. Tom's
            // feedback: "it just says being assigned but doesn't give
            // me a timeframe of when itll be scheduled and also
            // doesnt let me select dates I prefer."
            if let summary = preferencesSummary {
                preferencesPanel(summary)
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
        .contentShape(Rectangle())
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
                    Text("Your contractor")
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
                    Text(rescheduleButtonLabel)
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
        case .ingestionFailed: return "Setup paused"
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
        case .ingestionFailed: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    /// Friendly date line built from `assessment.scheduledAt`. Returns
    /// `nil` when no date is set so the subtitle can fall back to the
    /// generic "we'll text you" copy. Format examples: "Saturday, May 24."
    /// or "Tuesday, June 3."
    private var formattedScheduledLine: String? {
        guard let scheduledAt = assessment.scheduledAt else { return nil }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return "Scheduled for \(f.string(from: scheduledAt))."
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
        case .ingestionFailed:
            return "We hit a snag setting up your home."
        case .completed:
            return "Welcome to your fully-set-up home."
        case .cancelled:
            return "Assessment cancelled."
        }
    }

    private var subtitle: String {
        // Round 2 feedback (May 2026): the friend reported the card never
        // shows when the handyman is coming — just "we're assigning" with
        // no date. When `assessment.scheduledAt` is populated (which can
        // happen before the status flips from `.pending` to `.scheduled`),
        // surface the date directly so the homeowner knows the plan.
        let scheduledLine = formattedScheduledLine
        switch assessment.status {
        case .pending:
            if let line = scheduledLine {
                return "\(line) We'll text you the morning of your visit. Free of charge."
            }
            // Round 2 (May 2026): the friend on TestFlight Build N saw
            // "Your handyman is being assigned" with no sense of when.
            // When `scheduledAt` isn't set yet, give the homeowner an
            // honest expected window so they're not left wondering
            // whether a date is coming today or in two weeks. This
            // matches the SLA we promise in the Chez handyman copy
            // elsewhere ("usually within 3 business days").
            //
            // Phase 96: also surface how long the request has been in
            // flight (computed from createdAt) so the SLA feels
            // concrete instead of abstract.
            if let elapsed = elapsedSinceRequest {
                return "\(elapsed) Usually confirmed within 3 business days. We'll text you the visit date. Free of charge."
            }
            return "Usually within 3 business days. We'll text you with the visit date once it's confirmed. Free of charge."
        case .scheduled:
            if let line = scheduledLine {
                return "\(line) We'll text you the morning of. No prep needed. Just be home."
            }
            return "We'll text you the morning of. No prep needed. Just be home."
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
        case .ingestionFailed:
            return "Our team is on it. We'll text you once setup completes."
        case .completed:
            return "Everything's been set up for you."
        case .cancelled:
            return "You can switch back to Chez handling it from Settings."
        }
    }

    // MARK: - Phase 96: preferences + elapsed-since-request

    /// "Requested 4 hours ago" / "Requested yesterday" — gives the
    /// "usually within 3 business days" SLA something concrete to
    /// stand on. Anchor preference: rescheduleRequestedAt (the most
    /// recent customer-initiated event) → createdAt (the original
    /// request). Nil when neither is available.
    private var elapsedSinceRequest: String? {
        let anchor = assessment.rescheduleRequestedAt ?? assessment.createdAt
        guard let anchor else { return nil }
        let elapsed = Date().timeIntervalSince(anchor)
        guard elapsed >= 0 else { return nil }
        let minutes = Int(elapsed / 60)
        let hours = Int(elapsed / 3600)
        let days = Int(elapsed / 86_400)
        let phrase: String
        if days >= 2 {
            phrase = "\(days) days ago"
        } else if days == 1 {
            phrase = "yesterday"
        } else if hours >= 2 {
            phrase = "\(hours) hours ago"
        } else if hours == 1 {
            phrase = "1 hour ago"
        } else if minutes >= 5 {
            phrase = "\(minutes) minutes ago"
        } else {
            phrase = "just now"
        }
        return "Requested \(phrase)."
    }

    /// One-line summary of the homeowner's preferences on file —
    /// preferred dates (from reschedule sheet) take precedence over
    /// the initial booking window. Returns nil when nothing is
    /// recorded; the panel is hidden in that case.
    private var preferencesSummary: String? {
        var parts: [String] = []
        if let dates = assessment.preferredDates, !dates.isEmpty {
            let formatted = dates.compactMap(Self.formatPreferredDate)
            if !formatted.isEmpty {
                parts.append(formatted.joined(separator: " or "))
            }
        } else if let start = assessment.preferredWindowStart,
                  !start.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let formatted = Self.formatPreferredDate(start) {
            parts.append("Any time after \(formatted)")
        }
        if let tod = assessment.preferredTimeOfDay?.trimmingCharacters(in: .whitespacesAndNewlines),
           !tod.isEmpty {
            parts.append(tod)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Parse YYYY-MM-DD or full ISO-8601 + reformat as "Thu, May 22".
    /// Returns nil if the input isn't parseable.
    private static func formatPreferredDate(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.timeZone = .current
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        let parsed: Date? = dateOnly.date(from: trimmed) ?? iso.date(from: trimmed)
        guard let date = parsed else { return nil }
        let out = DateFormatter()
        out.dateFormat = "EEE, MMM d"
        out.timeZone = .current
        return out.string(from: date)
    }

    /// Phase 96 — when there's no scheduled date yet, "Reschedule" reads
    /// wrong (nothing TO reschedule). Use the proactive label instead.
    private var rescheduleButtonLabel: String {
        assessment.scheduledAt == nil ? "Suggest dates" : "Reschedule"
    }

    /// Inline panel inserted between the handyman row and the action
    /// row. Reads as "Your preferred dates · Thu, May 22 or Fri, May 23
    /// · morning."
    @ViewBuilder
    private func preferencesPanel(_ summary: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your preferred dates")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(summary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(HavenColors.creamLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(HavenColors.action.opacity(0.15), lineWidth: 1)
        )
    }
}
