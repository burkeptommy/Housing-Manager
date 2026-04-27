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

    private var quote: ProviderQuoteRow? { coordinator.quote }
    private var status: ProviderQuoteStatus { quote?.typedStatus ?? .draft }
    private var canRespond: Bool {
        // Once a quote has been responded to, we hide the action buttons
        // (the provider has to send a counter / new revision before the
        // homeowner can respond again).
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
                        heroCard(quote: q)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
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
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showApprovalSheet) {
            approvalSheet
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
