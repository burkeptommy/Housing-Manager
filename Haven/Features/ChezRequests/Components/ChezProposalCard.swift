import SwiftUI

/// Phase 80.1 — Inline structured-proposal card. Renders inside a
/// `ChezMessageBubble` whenever a concierge-role message carries a
/// `proposal` JSONB blob. Three actions:
///   • Approve  → success-tinted, fires `decideChezProposal(.approved)`
///   • Counter  → opens the reply composer prefilled (handled by parent)
///   • Decline  → subtle red, fires `decideChezProposal(.declined)`
///
/// When the proposal has already been decided (`status != "pending"`),
/// the card renders a static "you approved this" / "you declined this"
/// banner instead of the action row, so the audit trail is preserved.
struct ChezProposalCard: View {
    let proposal: ChezProposal
    let messageId: UUID
    /// Called when the user taps Counter — the parent (typically the
    /// detail view) opens the reply composer prefilled with a counter
    /// template ("Could we adjust …?").
    var onCounter: ((ChezProposal) -> Void)?

    @State private var isDeciding: Bool = false
    @State private var localStatus: String?      // optimistic update
    @State private var errorMessage: String?

    private var effectiveStatus: ChezProposalStatusValue {
        if let raw = localStatus, let v = ChezProposalStatusValue(rawValue: raw) { return v }
        return proposal.typedStatus
    }

    var body: some View {
        // Wave 6 — route by kind before assuming the decision-card
        // shape. Info requests get their own card with per-field
        // inputs; unknown kinds degrade to a quiet caption with no
        // action buttons (older builds rendered them as broken vendor
        // cards with live Approve buttons).
        switch proposal.typedKind {
        case .infoRequest:
            ChezInfoRequestCard(proposal: proposal, messageId: messageId)
        case .unknown:
            unknownKindBody
        case .vendor, .dateSlot, .cost, .quote:
            decisionCardBody
        }
    }

    private var decisionCardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            payload
            if effectiveStatus == .pending {
                actionRow
            } else {
                decidedBanner
            }
            if let err = errorMessage {
                Text(err)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
    }

    /// Wave 6 — plain-text degradation for proposal kinds this build
    /// doesn't recognize. The message content already renders as normal
    /// bubble text above; this is just a quiet marker so the homeowner
    /// knows a structured update rode along. No decision buttons.
    private var unknownKindBody: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
            Text("Update from Chez")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(HavenColors.beige200.opacity(0.5))
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: kindIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
            Text(kindTitle)
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.action)
            Spacer()
            if effectiveStatus == .pending {
                Text("Awaiting your decision")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var kindIcon: String {
        switch proposal.typedKind {
        case .vendor: return "building.2.fill"
        case .dateSlot: return "calendar.badge.clock"
        case .cost: return "dollarsign.circle.fill"
        case .quote: return "doc.text.fill"
        // Wave 6 — these kinds never reach the decision-card body
        // (routed in `body`), but the switch stays exhaustive.
        case .infoRequest: return "questionmark.bubble.fill"
        case .unknown: return "sparkles"
        }
    }

    private var kindTitle: String {
        switch proposal.typedKind {
        case .vendor: return "VENDOR PROPOSAL"
        case .dateSlot: return "DATE OPTIONS"
        case .cost: return "COST PROPOSAL"
        case .quote: return "QUOTE PROPOSAL"
        // Wave 6 — unreachable from the decision-card body; exhaustive.
        case .infoRequest: return "CHEZ NEEDS DETAILS"
        case .unknown: return "UPDATE FROM CHEZ"
        }
    }

    // MARK: - Payload (renders the right shape per kind)

    @ViewBuilder
    private var payload: some View {
        switch proposal.typedKind {
        case .vendor:
            vendorPayload
        case .dateSlot:
            dateSlotPayload
        case .cost:
            costPayload
        case .quote:
            quotePayload
        case .infoRequest, .unknown:
            // Wave 6 — routed before the decision-card body renders;
            // nothing structured to show here.
            EmptyView()
        }
    }

    private var vendorPayload: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = proposal.vendor?.name, !name.isEmpty {
                Text(name)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            HStack(spacing: 12) {
                if let rating = proposal.vendor?.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if let count = proposal.vendor?.reviewCount {
                    Text("\(count) reviews")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if let phone = proposal.vendor?.phone, !phone.isEmpty {
                    Text(phone)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            // Phase 81.2 — Prefer the explicit cost-range string if the
            // admin picked from the combobox ("$1,000–2,500", "Will
            // quote on site visit"); fall back to the legacy numeric
            // estimatedCost.
            if let costRange = proposal.vendor?.estimatedCostRange, !costRange.isEmpty {
                Text("Estimated: \(costRange)")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            } else if let cost = proposal.vendor?.estimatedCost {
                Text("Estimated: $\(Int(cost))")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            // Phase 101 (C1) — fair-market context so the quoted price is
            // never a bare number. Sourced from Chez network history or
            // the operator's research.
            if let low = proposal.vendor?.fairMarketLowCents,
               let high = proposal.vendor?.fairMarketHighCents,
               high >= low, low > 0 {
                Text("Fair market: $\(low / 100) to $\(high / 100)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            // Phase 81.2 — Multi-slot availability list. Renders as a
            // bulleted list when the admin gave the vendor multiple
            // options. Falls back to the single estimatedWindow line
            // for legacy proposals.
            if let slots = proposal.vendor?.availabilitySlots, !slots.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Times offered:")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    ForEach(slots, id: \.self) { slot in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("•")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Text(slot)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
                .padding(.top, 2)
            } else if let win = proposal.vendor?.estimatedWindow, !win.isEmpty {
                Text("Earliest slot: \(win)")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            if let rationale = proposal.vendor?.rationale, !rationale.isEmpty {
                Text(rationale)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.top, 2)
            }
        }
    }

    private var dateSlotPayload: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach((proposal.dateSlot?.options ?? []).indices, id: \.self) { idx in
                let opt = (proposal.dateSlot?.options ?? [])[idx]
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                    Text(opt.label ?? opt.iso ?? "TBD")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                }
            }
        }
    }

    private var costPayload: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let amt = proposal.cost?.amount {
                Text("$\(Int(amt))")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            if let scope = proposal.cost?.scope, !scope.isEmpty {
                Text(scope)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            if let vendor = proposal.cost?.vendorName, !vendor.isEmpty {
                Text("Vendor: \(vendor)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var quotePayload: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let vendor = proposal.quote?.vendorName, !vendor.isEmpty {
                Text(vendor)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            if let total = proposal.quote?.total {
                Text("Total: $\(Int(total))")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            // Phase 101 (C1) — price context next to the number.
            if let low = proposal.quote?.fairMarketLow,
               let high = proposal.quote?.fairMarketHigh,
               high >= low, low > 0 {
                Text("Fair market: $\(Int(low)) to $\(Int(high))")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            if let valid = proposal.quote?.validUntil, !valid.isEmpty {
                Text("Valid until: \(valid)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            // Phase 101 (C2) — the other quotes Chez gathered, so this
            // reads as a comparison, not a lone number.
            if let alts = proposal.quote?.alternatives, !alts.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Also quoted:")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    ForEach(Array(alts.enumerated()), id: \.offset) { _, alt in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("•")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Text("\(alt.vendorName ?? "Vendor")\(alt.total.map { ": $\(Int($0))" } ?? "")")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                Task { await decide(.approved) }
            } label: {
                actionLabel("Approve", icon: "checkmark", primary: true)
            }
            .buttonStyle(.plain)
            .disabled(isDeciding)

            Button {
                onCounter?(proposal)
            } label: {
                actionLabel("Counter", icon: "arrow.uturn.left", primary: false)
            }
            .buttonStyle(.plain)
            .disabled(isDeciding)

            Button {
                Task { await decide(.declined) }
            } label: {
                actionLabel("Decline", icon: "xmark", primary: false, destructive: true)
            }
            .buttonStyle(.plain)
            .disabled(isDeciding)
        }
    }

    private func actionLabel(_ text: String, icon: String, primary: Bool, destructive: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
        }
        .foregroundStyle(primary ? Color.white : (destructive ? HavenColors.critical : HavenColors.navy700))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(primary ? HavenColors.success : HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    primary ? HavenColors.success : (destructive ? HavenColors.critical.opacity(0.4) : HavenColors.beige300),
                    lineWidth: 1
                )
        )
    }

    private var decidedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: decidedIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(decidedTint)
            Text(decidedText)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(decidedTint)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(decidedTint.opacity(0.1))
        )
    }

    private var decidedIcon: String {
        switch effectiveStatus {
        case .approved: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .countered: return "arrow.uturn.left.circle.fill"
        case .pending: return "clock"
        case .answered: return "checkmark.circle.fill"
        }
    }

    private var decidedTint: Color {
        switch effectiveStatus {
        case .approved: return HavenColors.success
        case .declined: return HavenColors.critical
        case .countered: return HavenColors.action
        case .pending: return HavenColors.textSecondary
        case .answered: return HavenColors.success
        }
    }

    private var decidedText: String {
        switch effectiveStatus {
        case .approved: return "You approved this proposal."
        case .declined: return "You declined this proposal."
        case .countered: return "You sent a counter-offer."
        case .pending: return "Awaiting your decision."
        case .answered: return "You sent your answers to Chez."
        }
    }

    // MARK: - Decision call

    private func decide(_ decision: ChezProposalDecision) async {
        isDeciding = true
        defer { isDeciding = false }
        errorMessage = nil
        // Optimistic update so the UI flips immediately.
        localStatus = decision.rawValue
        do {
            try await HavenSupabase.decideChezProposal(messageId: messageId, decision: decision)
            Haptics.success()
            Analytics.track(.chezProposalDecided, [
                "decision": decision.rawValue,
                "kind": proposal.kind,
            ])
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
        } catch {
            // Roll back optimistic update on failure.
            localStatus = nil
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}
