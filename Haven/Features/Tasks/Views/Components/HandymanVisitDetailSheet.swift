import SwiftUI

/// Detail view for a scheduled handyman visit. Surfaces:
///   - Hero with vendor + scheduled date + status
///   - Full punch list (parsed children from notes)
///   - Action row: Reschedule, Add to list, Cancel
///   - Notes about real-time updates (en route / on site / wrapped up)
///
/// Presented from `HandymanTabView` when the user taps the visit hero.
struct HandymanVisitDetailSheet: View {
    let visit: MaintenanceTaskDBRow
    let vendor: ContractorRow?
    let children: [VisitChildItem]
    let onMessage: () -> Void
    var onReviewQuote: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = HandymanRequestCoordinator.shared
    @State private var showRescheduleSheet = false
    @State private var showCancelConfirm = false

    private var dateLabel: String {
        let dateString = visit.scheduledDate ?? visit.nextDueDate
        guard let date = MaintenanceDateFormatting.date(from: dateString) else {
            return "Date pending"
        }
        return date.formatted(date: .complete, time: .omitted)
    }

    private var totalEstimateLabel: String? {
        let total = children.compactMap { $0.estimatedMinutes }.reduce(0, +)
        guard total > 0 else { return nil }
        let hours = Double(total) / 60.0
        if hours < 1 { return "~\(total) min" }
        if hours == hours.rounded() { return "~\(Int(hours)) hrs" }
        return String(format: "~%.1f hrs", hours)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    visitHero
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    actionRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    if let q = coordinator.quote, let review = onReviewQuote {
                        VisitDetailQuoteCard(quote: q, vendor: vendor, onTap: review)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    statusSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    punchListSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    if let notes = visit.notes, !notes.isEmpty, children.isEmpty {
                        notesFallbackSection(notes: notes)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(HavenColors.background)
            .task(id: visit.id) {
                // Switch the shared coordinator to THIS visit's
                // request_id whenever the sheet opens (or the user
                // navigates between visits). Without this, opening
                // the follow-up visit kept the coordinator pointed
                // at the main visit's request — every reschedule
                // message + quote that landed on the follow-up's
                // thread was invisible because Realtime + the chat
                // sheet read from coordinator.request.
                await coordinator.load(visit: visit, vendor: vendor)
            }
            .navigationTitle("Visit details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    // MARK: - Hero

    private var visitHero: some View {
        IndigoGradientCard(variant: .hero) {
            VStack(alignment: .leading, spacing: 0) {
                Text("UPCOMING VISIT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.32)
                    .foregroundStyle(HavenColors.actionLight)
                    .padding(.bottom, 6)

                Text(visit.title)
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                    Text(dateLabel)
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(.bottom, 4)

                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(vendor?.companyName ?? "Your handyman")
                        .font(.system(size: 12, weight: .medium))
                    if let total = totalEstimateLabel {
                        Text("·")
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text(total)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundStyle(Color.white.opacity(0.85))
            }
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 8) {
            actionButton(
                icon: "bubble.left.fill",
                title: "Message",
                tone: .salmon,
                action: onMessage
            )
            actionButton(
                icon: "calendar.badge.clock",
                title: "Reschedule",
                tone: .indigoOutline,
                action: { showRescheduleSheet = true }
            )
            actionButton(
                icon: "xmark.circle",
                title: "Cancel",
                tone: .indigoOutline,
                action: { showCancelConfirm = true }
            )
        }
        .confirmationDialog(
            "Cancel this visit?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, cancel visit", role: .destructive) {
                // TODO: server-side cancel + status update
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Your handyman will be notified.")
        }
        .sheet(isPresented: $showRescheduleSheet) {
            ReschedulePlaceholderSheet(visit: visit, vendor: vendor)
        }
    }

    private enum ButtonTone { case salmon, indigoOutline }

    private func actionButton(
        icon: String,
        title: String,
        tone: ButtonTone,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(tone == .salmon ? Color.white : HavenColors.navy900)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tone == .salmon ? HavenColors.action : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tone == .salmon ? Color.clear : HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DURING THE VISIT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                statusRow(icon: "clock.fill", title: "Scheduled", body: "We'll remind you the day before.", isActive: true)
                Divider().padding(.leading, 44)
                statusRow(icon: "location.fill", title: "On the way", body: "You'll get a heads-up when your handyman is en route.", isActive: false)
                Divider().padding(.leading, 44)
                statusRow(icon: "checkmark.seal.fill", title: "Wrapped up", body: "Real-time updates as items get checked off, plus before/after photos.", isActive: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
    }

    private func statusRow(icon: String, title: String, body: String, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? HavenColors.action : HavenColors.textTertiary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(isActive ? HavenColors.actionPale : HavenColors.beige200.opacity(0.5))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: - Punch list

    private var punchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("PUNCH LIST")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Text("\(children.count) item\(children.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    // TODO: add-to-this-visit flow
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add to list")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.actionPressed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            if children.isEmpty {
                emptyPunchListPlaceholder
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                        VisitChildDetailRow(child: child, isLast: index == children.count - 1)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
            }
        }
    }

    private var emptyPunchListPlaceholder: some View {
        Text("Nothing on the punch list yet — add items so your handyman knows what's on the docket.")
            .font(.system(size: 13))
            .foregroundStyle(HavenColors.textSecondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
    }

    private func notesFallbackSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VISIT NOTES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 4)
            Text(notes)
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.navy900)
                .lineSpacing(3)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(HavenColors.beige200, lineWidth: 1)
                )
        }
    }
}

private struct VisitChildDetailRow: View {
    let child: VisitChildItem
    let isLast: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(HavenColors.beige400, lineWidth: 1.7)
                    .frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(child.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HavenColors.navy900)
                if let mins = child.estimatedMinutes {
                    Text("~\(mins) min")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(TasksV5.punchListDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
    }
}

// Sub-card on the visit detail sheet that surfaces the attached quote.
// Tap opens the full quote review sheet via the parent's onReviewQuote
// callback.
private struct VisitDetailQuoteCard: View {
    let quote: ProviderQuoteRow
    let vendor: ContractorRow?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HavenColors.actionPale)
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HavenColors.actionPressed)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("QUOTE FROM \(vendor?.companyName.uppercased() ?? "HANDYMAN")")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(formatCurrency(quote.total))
                        .font(HavenTypography.fraunces(size: 22, weight: 700))
                        .tracking(-0.4)
                        .foregroundStyle(HavenColors.navy900)
                    Text("\(quote.lineItems.count) item\(quote.lineItems.count == 1 ? "" : "s") · Tap to review")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

private struct ReschedulePlaceholderSheet: View {
    let visit: MaintenanceTaskDBRow
    let vendor: ContractorRow?

    @Environment(\.dismiss) private var dismiss
    @State private var newDate = Date()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Propose a new time")
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .foregroundStyle(HavenColors.navy900)

                Text("Suggest a new date for your visit with \(vendor?.companyName ?? "your handyman"). They'll get a notification and can accept or counter.")
                    .font(.system(size: 13))
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineSpacing(2)

                DatePicker(
                    "New date",
                    selection: $newDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)

                Spacer()

                Button {
                    // TODO: post propose_visit_time RPC
                    dismiss()
                } label: {
                    Text("Propose time")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(HavenColors.action)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
