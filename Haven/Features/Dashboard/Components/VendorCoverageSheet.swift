import SwiftUI

/// Gap-focused vendor coverage sheet (Phase 56.1).
///
/// Responsibility is now narrow: show each uncovered system as a
/// prominent gap card with two inline actions ("Find a pro" / "I have
/// one") and a smaller dismissal affordance. Covered systems, add-custom
/// vendor, browse-specialty, add-routine, and recommendations all moved
/// to Property → Contacts (the canonical vendor management surface).
/// When every gap is resolved, the sheet shows a celebratory empty
/// state with a subtle "Manage all your vendors" link that routes the
/// caller to Contacts.
struct VendorCoverageSheet: View {
    let uncoveredItems: [VendorCoverageItem]
    /// Total vendor-eligible systems tracked in the household. Feeds the
    /// celebration line ("All N systems have a vendor lined up") and the
    /// header count. Covered items are no longer listed inside the
    /// sheet; they live on Contacts.
    let totalSystemCount: Int
    /// Phase 70.A1 follow-on F1: open `find_vendor` chez_requests keyed
    /// by canonical system category. When a gap has an entry here, its
    /// card switches from the "Find a pro / I have one / Have Chez
    /// handle it" stack to a single "Chez is finding you a {category}"
    /// status card. Tapping deep-links into the request thread.
    var chezRequests: [String: ChezRequestRow] = [:]
    /// Tap on a gap card's "Find a pro" button. Parent presents
    /// FindLocalVendorSheet with the gap's system category.
    let onFindVendor: (String) -> Void
    /// Tap on a gap card's "I have one" button. Parent presents
    /// AddVendorSheet with category prefill.
    let onAddVendor: (String) -> Void
    /// Fired when the user swipes or taps "Not applicable, dismiss"
    /// on a gap card. Parent persists to `dismissed_categories`.
    var onDismissItem: ((VendorCoverageItem) -> Void)?
    /// Round 2 (May 2026): "Remind me later" snooze callback. Parent
    /// upserts a `dismissed_categories` row with `snoozed_until` set so
    /// the gap resurfaces when the timestamp passes. Distinct from
    /// `onDismissItem` (permanent dismissal). Second arg is the number
    /// of months to snooze.
    var onSnoozeItem: ((VendorCoverageItem, Int) -> Void)?
    /// Phase 56.1: Fired from the celebratory empty state's
    /// "Manage all your vendors" link. Parent dismisses the sheet and
    /// routes to Property → Contacts.
    var onManageVendors: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    /// Local optimistic filter so the swiped/tapped row disappears
    /// immediately, without waiting for the dismissal round-trip.
    @State private var locallyDismissed: Set<String> = []
    /// Active snooze-duration picker, keyed by item id. Non-nil shows
    /// the picker sheet for that specific gap.
    @State private var snoozeTargetItem: VendorCoverageItem? = nil

    private var visibleUncovered: [VendorCoverageItem] {
        uncoveredItems.filter { !locallyDismissed.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    headerSummary

                    if visibleUncovered.isEmpty {
                        allCoveredCelebration
                    } else {
                        ForEach(visibleUncovered) { item in
                            if let request = chezRequests[item.id] {
                                chezHandlingCard(for: item, request: request)
                            } else {
                                gapCard(for: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, HavenTheme.spacing8)
                .padding(.bottom, HavenTheme.spacing24)
            }
            .background(HavenColors.background)
            .navigationTitle("Vendor Coverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(HavenColors.beige200)
                            .clipShape(Circle())
                    }
                }
            }
            .confirmationDialog(
                "Remind me later",
                isPresented: Binding(
                    get: { snoozeTargetItem != nil },
                    set: { if !$0 { snoozeTargetItem = nil } }
                ),
                titleVisibility: .visible,
                presenting: snoozeTargetItem
            ) { item in
                Button("In 3 months") { applySnooze(item: item, months: 3) }
                Button("In 6 months") { applySnooze(item: item, months: 6) }
                Button("In 1 year") { applySnooze(item: item, months: 12) }
                Button("In 3 years") { applySnooze(item: item, months: 36) }
                Button("Cancel", role: .cancel) { snoozeTargetItem = nil }
            } message: { item in
                Text("When should we bring up \(item.systemName) again?")
            }
        }
    }

    private func applySnooze(item: VendorCoverageItem, months: Int) {
        _ = withAnimation {
            locallyDismissed.insert(item.id)
        }
        onSnoozeItem?(item, months)
        snoozeTargetItem = nil
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSummary: some View {
        if visibleUncovered.isEmpty {
            EmptyView()
        } else {
            Text("\(visibleUncovered.count) of \(totalSystemCount) systems need a vendor")
                .font(HavenTypography.fraunces(size: 16, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.bottom, 4)
        }
    }

    // MARK: - Chez Handling Card (Phase 70.A1 follow-on F1)

    /// Renders when an open `find_vendor` chez_request exists for this
    /// gap's category. Navy-tinted (signals "we're on it" vs. the
    /// attention-flavored salmon of an unresolved gap), single tap-row,
    /// no action buttons. Chevron deep-links into the existing thread
    /// via `.openChezRequest`, the same notification the push handler
    /// uses, so the InboxView listener routes to the Chez sub-tab and
    /// pushes ChezRequestDetailView for that id.
    private func chezHandlingCard(
        for item: VendorCoverageItem,
        request: ChezRequestRow
    ) -> some View {
        Button {
            Haptics.selection()
            NotificationCenter.default.post(
                name: .openChezRequest,
                object: nil,
                userInfo: ["request_id": request.id.uuidString]
            )
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.navy.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chez is finding you a \(item.systemName)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(chezHandlingCaption(for: request))
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, 6)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.navy.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chez is finding you a \(item.systemName). \(chezHandlingCaption(for: request))")
        .accessibilityHint("Open the conversation with Chez.")
    }

    private func chezHandlingCaption(for request: ChezRequestRow) -> String {
        // Lean on the resilient SLA copy already on ChezRequestRow —
        // it handles open / waiting-on-you / resolved + today / tomorrow
        // / specific-date branches.
        request.homeownerSlaCaption
    }

    // MARK: - Gap Card

    /// Prominent gap card — salmon-tinted so it reads as an attention
    /// surface separate from neutral content cards elsewhere. Two
    /// inline actions plus a smaller dismiss affordance.
    private func gapCard(for item: VendorCoverageItem) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text(item.systemName)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer(minLength: 0)
            }

            Text("No vendor assigned yet.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: HavenTheme.spacing8) {
                Button {
                    Haptics.medium()
                    onFindVendor(item.id)
                } label: {
                    Text("Find a pro")
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(HavenColors.action)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    onAddVendor(item.id)
                } label: {
                    Text("I have one")
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Phase 80 — third option in the gap-card stack: hand the
            // gap to Tom. Renders as a subtle full-width text button
            // between the primary CTAs and the dismiss affordance, so
            // it doesn't compete with "Find a pro" / "I have one" but
            // is impossible to miss if those don't appeal.
            Button {
                Haptics.light()
                NotificationCenter.default.post(
                    name: .openChezRequestComposer,
                    object: nil,
                    userInfo: [
                        "category": ChezCategory.findVendor.rawValue,
                        "context": [
                            "system_category": item.systemName,
                            "_source": "vendor_coverage_sheet",
                            "source_entity_type": "system",
                            "source_entity_label": item.systemName,
                        ],
                    ]
                )
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Have Chez handle it")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                }
                .foregroundStyle(HavenColors.action)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Round 2 (May 2026): two tertiary affordances side-by-side
            // for the homeowner's "I don't want this gap now" options.
            // "Remind me later" = temporary snooze for vendors they might
            // need in the future (e.g. roofer, 3+ years out). "Not
            // applicable" = permanent dismissal. Both work via the same
            // `dismissed_categories` row — snooze just adds an expiry.
            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    Haptics.light()
                    snoozeTargetItem = item
                } label: {
                    Text("Remind me later")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    _ = withAnimation {
                        locallyDismissed.insert(item.id)
                    }
                    onDismissItem?(item)
                } label: {
                    // BUG-016 fix: bumped from `textTertiary` (~2.5:1
                    // contrast on tinted card background, below WCAG AA
                    // 4.5:1 floor) to `textSecondary` which passes.
                    Text("Not applicable")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.action.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Empty-state celebration

    private var allCoveredCelebration: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(HavenColors.success)
            Text(celebrationTitle)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("You're set. Chez will let you know if anything changes.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            if onManageVendors != nil {
                Button {
                    Haptics.light()
                    onManageVendors?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Manage all your vendors")
                            .font(HavenTypography.uiLabel)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var celebrationTitle: String {
        if totalSystemCount > 0 {
            return "All \(totalSystemCount) systems have a vendor lined up"
        }
        return "All systems covered"
    }
}
