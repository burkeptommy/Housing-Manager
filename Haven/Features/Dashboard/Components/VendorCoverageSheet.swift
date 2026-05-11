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
    /// Tap on a gap card's "Find a pro" button. Parent presents
    /// FindLocalVendorSheet with the gap's system category.
    let onFindVendor: (String) -> Void
    /// Tap on a gap card's "I have one" button. Parent presents
    /// AddVendorSheet with category prefill.
    let onAddVendor: (String) -> Void
    /// Fired when the user swipes or taps "Not applicable, dismiss"
    /// on a gap card. Parent persists to `dismissed_categories`.
    var onDismissItem: ((VendorCoverageItem) -> Void)?
    /// Phase 56.1: Fired from the celebratory empty state's
    /// "Manage all your vendors" link. Parent dismisses the sheet and
    /// routes to Property → Contacts.
    var onManageVendors: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    /// Local optimistic filter so the swiped/tapped row disappears
    /// immediately, without waiting for the dismissal round-trip.
    @State private var locallyDismissed: Set<String> = []

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
                            gapCard(for: item)
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
        }
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

            Button {
                Haptics.light()
                _ = withAnimation {
                    locallyDismissed.insert(item.id)
                }
                onDismissItem?(item)
            } label: {
                // BUG-016 fix: bumped from `textTertiary` (~2.5:1
                // contrast on tinted card background, below WCAG AA
                // 4.5:1 floor) to `textSecondary` which passes. Also
                // renamed "Not applicable, dismiss" → "Not applicable"
                // so the affordance reads as a statement rather than
                // a redundant comma-joined instruction.
                Text("Not applicable")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
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
