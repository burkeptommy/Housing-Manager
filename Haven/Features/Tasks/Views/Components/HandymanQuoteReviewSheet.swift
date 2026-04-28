import SwiftUI

/// Homeowner-side quote review. Reads from `HandymanRequestCoordinator.quote`
/// so the Realtime channel pushes provider updates straight in.
///
/// Lets the homeowner:
///   - Scan total + line items
///   - Approve (signed, requires typed name) → respond_to_provider_quote RPC
///   - Decline → same RPC, leaves room to chat about why
///   - Open chat → bounces back through the parent so the existing
///     HandymanChatSheet handles negotiation
struct HandymanQuoteReviewSheet: View {
    let vendor: ContractorRow?
    let onMessage: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = HandymanRequestCoordinator.shared
    @State private var showApprovalSheet = false
    @State private var signedName: String = ""
    @State private var submitting = false
    @State private var showHistorySheet = false
    /// When the user taps a past version from the history sheet we
    /// pin it here so the main view renders that version's line items
    /// and totals (read-only — actions stay scoped to the live quote).
    @State private var viewingVersion: ProviderQuoteRow?

    /// The quote currently displayed. Defaults to the live quote, but
    /// flips to a historical version when the user is browsing.
    private var quote: ProviderQuoteRow? { viewingVersion ?? coordinator.quote }
    /// The live, actionable quote — Approve/Decline always act on this
    /// even when the user is browsing an older version.
    private var liveQuote: ProviderQuoteRow? { coordinator.quote }
    private var isViewingHistorical: Bool {
        guard let pinned = viewingVersion, let live = liveQuote else { return false }
        return pinned.id != live.id
    }
    private var status: ProviderQuoteStatus { quote?.typedStatus ?? .draft }
    /// Older revisions exist when the chain has more than one row.
    private var hasHistory: Bool { coordinator.quoteHistory.count > 1 }
    private var canRespond: Bool {
        // Once a quote has been responded to, we hide the action buttons
        // (the provider has to send a counter / new revision before the
        // homeowner can respond again). Also: when browsing a
        // historical version, only the live quote can be acted on.
        if isViewingHistorical { return false }
        switch status {
        case .sent, .viewed: return true
        default: return false
        }
    }

    var body: some View {
        NavigationStack {
            if let q = quote {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if isViewingHistorical {
                            historicalBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        heroCard(quote: q)
                            .padding(.horizontal, 20)
                            .padding(.top, isViewingHistorical ? 8 : 16)
                            .padding(.bottom, 18)

                        if canRespond {
                            actionRow
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        } else {
                            statusBanner
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }

                        lineItemsSection(quote: q)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        if let scope = q.scopeNotes, !scope.isEmpty {
                            notesSection(label: "SCOPE NOTES", body: scope)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }
                        if let homeownerMsg = q.homeownerMessage, !homeownerMsg.isEmpty {
                            notesSection(label: "FROM \(vendor?.companyName.uppercased() ?? "YOUR HANDYMAN")", body: homeownerMsg)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }

                        Spacer(minLength: 40)
                    }
                }
            } else {
                emptyState
            }
        }
        .background(HavenColors.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Quote details")
                    .font(HavenTypography.fraunces(size: 18, weight: 600))
                    .foregroundStyle(HavenColors.navy900)
            }
            ToolbarItem(placement: .topBarLeading) {
                if hasHistory {
                    Button {
                        showHistorySheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showApprovalSheet) {
            approvalSheet
        }
        .sheet(isPresented: $showHistorySheet) {
            QuoteVersionHistorySheet(
                versions: coordinator.quoteHistory,
                liveQuoteId: liveQuote?.id,
                viewingId: viewingVersion?.id ?? liveQuote?.id,
                onSelect: { picked in
                    // Pin the chosen version (or unpin to return to live).
                    if picked.id == liveQuote?.id {
                        viewingVersion = nil
                    } else {
                        viewingVersion = picked
                    }
                    showHistorySheet = false
                }
            )
        }
    }

    // MARK: - Hero

    private func heroCard(quote: ProviderQuoteRow) -> some View {
        IndigoGradientCard(variant: .hero) {
            VStack(alignment: .leading, spacing: 0) {
                Text(vendor?.companyName.uppercased() ?? "HANDYMAN QUOTE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.32)
                    .foregroundStyle(HavenColors.actionLight)
                    .padding(.bottom, 6)

                Text(quote.title)
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                    .padding(.bottom, 14)
                    .multilineTextAlignment(.leading)

                Text(formatCurrency(quote.total))
                    .font(HavenTypography.fraunces(size: 40, weight: 700))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("\(quote.lineItems.count)")
                            .font(.system(size: 13, weight: .semibold))
                        Text("items")
                            .font(.system(size: 12.5))
                    }
                    if let sent = quote.sentAt {
                        Text("·")
                        Text("Sent \(sent.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 12.5))
                    }
                }
                .foregroundStyle(Color.white.opacity(0.75))
            }
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.selection()
                onMessage()
            } label: {
                actionButtonLabel(icon: "bubble.left.fill", title: "Message", isPrimary: false)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.selection()
                Task { await respond(.declined) }
            } label: {
                actionButtonLabel(icon: "xmark.circle", title: "Decline", isPrimary: false)
            }
            .buttonStyle(.plain)
            .disabled(submitting)

            Button {
                Haptics.medium()
                showApprovalSheet = true
            } label: {
                actionButtonLabel(icon: "checkmark.seal.fill", title: "Approve", isPrimary: true)
            }
            .buttonStyle(.plain)
            .disabled(submitting)
        }
    }

    private func actionButtonLabel(icon: String, title: String, isPrimary: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(isPrimary ? .white : HavenColors.navy900)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isPrimary ? HavenColors.action : HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isPrimary ? Color.clear : HavenColors.beige200, lineWidth: 1)
        )
    }

    // MARK: - Historical-version banner

    /// Shown above the hero when the user has tapped a past version
    /// from the history sheet. Cream callout with a "Back to current"
    /// affordance — keeps the homeowner oriented and prevents
    /// confusion when the displayed total doesn't match the live
    /// quote in the chat thread.
    private var historicalBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Viewing an earlier version")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                Text("Approve / Decline are disabled. Tap to return to the current quote.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                viewingVersion = nil
            } label: {
                Text("Back to current")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.beige200.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HavenColors.beige300, lineWidth: 1)
        )
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: bannerIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(bannerColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(HavenColors.navy900)
                Text(bannerBody)
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bannerColor.opacity(0.08))
        )
    }

    private var bannerIcon: String {
        switch status {
        case .approved: return "checkmark.seal.fill"
        case .declined: return "xmark.circle.fill"
        case .draft: return "doc.text"
        case .superseded: return "arrow.triangle.2.circlepath"
        case .withdrawn: return "minus.circle"
        default: return "info.circle"
        }
    }

    private var bannerColor: Color {
        switch status {
        case .approved: return HavenColors.success
        case .declined, .withdrawn: return HavenColors.critical
        case .draft, .superseded: return HavenColors.textTertiary
        default: return HavenColors.navy500
        }
    }

    private var bannerTitle: String {
        switch status {
        case .approved: return "You approved this quote"
        case .declined: return "You declined this quote"
        case .draft: return "Still in draft"
        case .superseded: return "Replaced by a newer revision"
        case .withdrawn: return "Withdrawn by your handyman"
        default: return "Quote status: \(status.rawValue)"
        }
    }

    private var bannerBody: String {
        switch status {
        case .approved: return "Your handyman is on the books to do this work."
        case .declined: return "Your handyman has been notified. You can chat about why or wait for a revised quote."
        case .draft: return "Your handyman is still finalizing this quote."
        case .superseded, .withdrawn: return "Open the chat to ask your handyman for the latest version."
        default: return ""
        }
    }

    // MARK: - Line items

    private func lineItemsSection(quote: ProviderQuoteRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LINE ITEMS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(quote.lineItems.enumerated()), id: \.element.id) { index, line in
                    LineItemRow(line: line, isLast: index == quote.lineItems.count - 1)
                }
                Divider()
                    .padding(.horizontal, 14)
                HStack {
                    Text("Total")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text(formatCurrency(quote.total))
                        .font(HavenTypography.fraunces(size: 22, weight: 700))
                        .tracking(-0.4)
                        .foregroundStyle(HavenColors.navy900)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
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

    private func notesSection(label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 4)
            Text(body)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No quote attached yet")
                .font(HavenTypography.fraunces(size: 18, weight: 600))
            Text("When your handyman sends a quote it will appear here for review.")
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
    }

    private var approvalSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Approve this quote")
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .foregroundStyle(HavenColors.navy900)

                if let q = quote {
                    Text("By signing, you authorize \(vendor?.companyName ?? "your handyman") to perform the work for \(formatCurrency(q.total)).")
                        .font(.system(size: 13.5))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineSpacing(2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Signature")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.66)
                        .textCase(.uppercase)
                        .foregroundStyle(HavenColors.textTertiary)
                    TextField("Type your full name", text: $signedName)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(HavenColors.beige200)
                        )
                }

                Spacer()

                Button {
                    Task {
                        let ok = await coordinator.respondToQuote(status: .approved, signedName: signedName)
                        if ok {
                            showApprovalSheet = false
                            signedName = ""
                        }
                    }
                } label: {
                    Text(submitting ? "Approving…" : "Sign + approve")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(signedName.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? HavenColors.beige400
                                      : HavenColors.action)
                        )
                }
                .buttonStyle(.plain)
                .disabled(signedName.trimmingCharacters(in: .whitespaces).isEmpty || submitting)
            }
            .padding(20)
            .navigationTitle("Approve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showApprovalSheet = false }
                }
            }
        }
    }

    private func respond(_ status: ProviderQuoteStatus) async {
        submitting = true
        let ok = await coordinator.respondToQuote(status: status)
        submitting = false
        if ok {
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

private struct LineItemRow: View {
    let line: ProviderQuoteLineItem
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                    if let desc = line.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("\(formatQuantity(line.quantity)) × \(formatCurrency(line.unitPrice)) / \(line.unit)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer()
                Text(formatCurrency(line.quantity * line.unitPrice))
                    .font(HavenTypography.fraunces(size: 16, weight: 600))
                    .foregroundStyle(HavenColors.navy900)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if !isLast {
                Divider().padding(.leading, 14)
            }
        }
    }

    private func formatQuantity(_ q: Double) -> String {
        if q.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(q))
        }
        return String(format: "%.1f", q)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Version history sheet

/// Lists every revision of a quote chain so the homeowner can scan the
/// negotiation arc — Provider $1,725 → Counter $1,200 → Provider $1,400
/// → Approved $1,300, etc. Tapping a row pins that version on the main
/// sheet (read-only); tapping the live row clears the pin.
struct QuoteVersionHistorySheet: View {
    let versions: [ProviderQuoteRow]
    let liveQuoteId: UUID?
    let viewingId: UUID?
    let onSelect: (ProviderQuoteRow) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Versions sorted oldest → newest so the timeline reads top-down
    /// like a chat thread. The fetcher returns DESC; flip it here.
    private var ordered: [ProviderQuoteRow] {
        versions.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Each row is one version of this quote — tap any to view its line items in detail.")
                        .font(.system(size: 13))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineSpacing(2)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    ForEach(Array(ordered.enumerated()), id: \.element.id) { idx, version in
                        Button {
                            onSelect(version)
                        } label: {
                            versionRow(
                                version: version,
                                versionNumber: idx + 1,
                                isLive: version.id == liveQuoteId,
                                isViewing: version.id == viewingId
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }

                    Spacer(minLength: 24)
                }
            }
            .background(HavenColors.background)
            .navigationTitle("Quote history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    private func versionRow(
        version: ProviderQuoteRow,
        versionNumber: Int,
        isLive: Bool,
        isViewing: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("V\(versionNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(HavenColors.beige200))
                statusPill(version.typedStatus)
                if isLive {
                    Text("CURRENT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(HavenColors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(HavenColors.success.opacity(0.12)))
                }
                Spacer()
                if isViewing {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(HavenColors.action)
                }
            }

            Text(currency(version.total))
                .font(HavenTypography.fraunces(size: 22, weight: 600))
                .foregroundStyle(HavenColors.navy900)

            HStack(spacing: 6) {
                Text("\(version.lineItems.count) item\(version.lineItems.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                if let when = version.updatedAt {
                    Text("·")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(when.formatted(.relative(presentation: .named)))
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isViewing ? HavenColors.action.opacity(0.4) : HavenColors.beige200, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statusPill(_ status: ProviderQuoteStatus) -> some View {
        let style = pillStyle(for: status)
        Text(style.label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(style.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(style.color.opacity(0.12)))
    }

    private func pillStyle(for status: ProviderQuoteStatus) -> (label: String, color: Color) {
        switch status {
        case .draft:                return ("Draft", HavenColors.textSecondary)
        case .sent:                 return ("Sent", HavenColors.action)
        case .viewed:               return ("Viewed", HavenColors.action)
        case .approved:             return ("Approved", HavenColors.success)
        case .declined:             return ("Declined", HavenColors.critical)
        case .counteredByHomeowner: return ("Countered", HavenColors.warning)
        case .superseded:           return ("Superseded", HavenColors.textTertiary)
        case .withdrawn:            return ("Withdrawn", HavenColors.textTertiary)
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
