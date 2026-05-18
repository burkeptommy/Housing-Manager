import SwiftUI

/// Round 3 (May 2026) — focused vendor-coverage view.
///
/// Background: tapping the Dashboard's Spring readiness card used to land
/// users on `MaintenanceHubView` (Phase 66 lobby), which is a different
/// surface than the Tasks tab's `MaintenanceTabView` (Phase 67 V5). That
/// inconsistency hurt trust. Worse, the hero said "3 of 3 systems are
/// covered" while the Property tab said "22 systems" — the friend
/// reasonably read that as a data bug. Turned out to be a labeling bug:
/// the dashboard counts deduplicated coverage *categories*, not systems.
///
/// `CoverageView` is the new canonical destination for "what's covered?"
/// It accounts for every relevant category in one of four sections so
/// nothing is invisible:
///
///   • **Covered** — categories with a vendor on file
///   • **Needs a vendor** — uncovered categories that aren't dismissed
///   • **Snoozed or dismissed** — categories the user set aside (with
///     Restore actions)
///   • **Not counted** — systems whose category is intentionally excluded
///     from the coverage ratio (Appliance, Crawl Space, Sump Pump,
///     Garage Door, etc.) — defuses the "but I have 22 systems!" confusion
///
/// State comes from `DashboardViewModel` (passed via EnvironmentObject):
/// `coveredCoverageItems`, `uncoveredCoverageItems`, `dismissedCoverageRows`,
/// `notCountedSystems`. No new fetches.
struct CoverageView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    private var primaryPropertyName: String? {
        viewModel.properties.first(where: { $0.id == viewModel.primaryPropertyId })?.name
            ?? viewModel.properties.first?.name
    }

    private var coveredCount: Int { viewModel.coveredCoverageItems.count }
    private var uncoveredCount: Int { viewModel.uncoveredCoverageItems.count }
    private var dismissedCount: Int { viewModel.dismissedCoverageRows.count }

    /// Total categories accounted for in the headline (covered + uncovered).
    /// Dismissed are not in this count because the user set them aside.
    private var totalActiveCategories: Int { coveredCount + uncoveredCount }

    private var progress: Double {
        guard totalActiveCategories > 0 else { return 1.0 }
        return Double(coveredCount) / Double(totalActiveCategories)
    }

    /// Group `notCountedSystems` by category for the NOT COUNTED section
    /// so Appliance ×9 renders as a single row with a count badge instead
    /// of 9 separate rows.
    private var notCountedByCategory: [(category: String, count: Int)] {
        let grouped = Dictionary(grouping: viewModel.notCountedSystems, by: { $0.category })
        return grouped
            .map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                hero
                if !viewModel.coveredCoverageItems.isEmpty {
                    coveredSection
                }
                if !viewModel.uncoveredCoverageItems.isEmpty {
                    needsVendorSection
                }
                if !viewModel.dismissedCoverageRows.isEmpty {
                    snoozedSection
                }
                if !notCountedByCategory.isEmpty {
                    notCountedSection
                }
            }
            .padding(HavenTheme.pageMargin)
        }
        .background(HavenColors.background)
        .navigationTitle("Coverage")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("\(coveredCount) of \(totalActiveCategories) service categor\(totalActiveCategories == 1 ? "y" : "ies")")
                .font(HavenTypography.fraunces(size: 24, weight: 700))
                .foregroundStyle(HavenColors.textOnNavy)

            if let name = primaryPropertyName, !name.isEmpty {
                Text("covered for \(name)")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
            } else {
                Text("covered for your home")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color.green)
                .padding(.top, 4)

            Text("Covered means Chez knows who services the category, when the work happens, and how to track it.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.62))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing20)
        .background(HavenColors.navy800)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Covered

    private var coveredSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader("COVERED", count: coveredCount)
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.coveredCoverageItems) { item in
                    CoverageCoveredRow(item: item)
                }
            }
        }
    }

    // MARK: - Needs Vendor

    private var needsVendorSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader("NEEDS A VENDOR", count: uncoveredCount)
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.uncoveredCoverageItems) { item in
                    CoverageUncoveredRow(item: item, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Snoozed / Dismissed

    private var snoozedSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader("SNOOZED OR DISMISSED", count: dismissedCount)
            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.dismissedCoverageRows) { row in
                    CoverageDismissedRow(row: row, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Not Counted

    private var notCountedSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader("NOT COUNTED", count: notCountedByCategory.count)
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("These categories don't have their own coverage line. The handyman bundle or a parent system covers them.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.bottom, 4)
                ForEach(notCountedByCategory, id: \.category) { entry in
                    HStack(spacing: HavenTheme.spacing8) {
                        Text(entry.category)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        if entry.count > 1 {
                            Text("\(entry.count) systems")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text("\(count)")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(HavenColors.neutral500.opacity(0.15))
                .clipShape(Capsule())
            Spacer()
        }
    }
}

// MARK: - Covered Row

private struct CoverageCoveredRow: View {
    let item: VendorCoverageItem

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            VendorLogoView(
                logoUrl: item.vendorLogoURL,
                category: item.systemName,
                vendorName: item.vendorName,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.systemName)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                HStack(spacing: 6) {
                    if let vendor = item.vendorName, !vendor.isEmpty {
                        Text(vendor)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                    if let cadence = item.cadence, !cadence.isEmpty {
                        if item.vendorName != nil {
                            Text("·")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Text(cadence)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(HavenColors.success)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Uncovered Row

private struct CoverageUncoveredRow: View {
    let item: VendorCoverageItem
    @ObservedObject var viewModel: DashboardViewModel
    @State private var snoozeTarget: VendorCoverageItem?

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.action.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(item.systemName)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
            }

            HStack(spacing: HavenTheme.spacing8) {
                Button {
                    Haptics.light()
                    NotificationCenter.default.post(
                        name: .openCoverageFindVendor,
                        object: nil,
                        userInfo: ["category": item.id, "system_name": item.systemName]
                    )
                } label: {
                    Text("Find a pro")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    NotificationCenter.default.post(
                        name: .openCoverageAddVendor,
                        object: nil,
                        userInfo: ["category": item.id, "system_name": item.systemName]
                    )
                } label: {
                    Text("I have one")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.navy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    Haptics.light()
                    snoozeTarget = item
                } label: {
                    Text("Remind me later")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    Task {
                        guard let householdId = viewModel.primaryHouseholdId else { return }
                        try? await DatabaseService.shared.dismissCategory(
                            householdId: householdId,
                            category: item.id
                        )
                        Analytics.track(.coverageItemDismissed, ["category": item.id, "source": "coverage_view"])
                        await viewModel.refresh()
                    }
                } label: {
                    Text("Not applicable")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.action.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
        .confirmationDialog(
            "Remind me later",
            isPresented: Binding(
                get: { snoozeTarget != nil },
                set: { if !$0 { snoozeTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: snoozeTarget
        ) { target in
            Button("In 3 months") { applySnooze(target: target, months: 3) }
            Button("In 6 months") { applySnooze(target: target, months: 6) }
            Button("In 1 year") { applySnooze(target: target, months: 12) }
            Button("In 3 years") { applySnooze(target: target, months: 36) }
            Button("Cancel", role: .cancel) { snoozeTarget = nil }
        } message: { target in
            Text("When should we bring up \(target.systemName) again?")
        }
    }

    private func applySnooze(target: VendorCoverageItem, months: Int) {
        guard let householdId = viewModel.primaryHouseholdId else { return }
        let until = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        Task {
            try? await DatabaseService.shared.snoozeCategory(
                householdId: householdId,
                category: target.id,
                until: until
            )
            Analytics.track(.coverageItemSnoozed, [
                "category": target.id,
                "months": months,
                "source": "coverage_view"
            ])
            await viewModel.refresh()
        }
        snoozeTarget = nil
    }
}

// MARK: - Dismissed Row

private struct CoverageDismissedRow: View {
    let row: DismissedCategoryRow
    @ObservedObject var viewModel: DashboardViewModel

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var stateLabel: String {
        if let until = row.snoozedUntil {
            return "Reminds again \(Self.dateFormatter.string(from: until))"
        }
        return "Permanently dismissed"
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: row.snoozedUntil != nil ? "alarm" : "tray.full")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
                .frame(width: 28, height: 28)
                .background(HavenColors.neutral500.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.category)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(stateLabel)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer()

            Button {
                Haptics.light()
                Task {
                    try? await DatabaseService.shared.undismissCategory(category: row.category)
                    Analytics.track(.coverageItemRestored, ["category": row.category])
                    await viewModel.refresh()
                }
            } label: {
                Text("Restore")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.navy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted from CoverageView's "Find a pro" tap. DashboardView listens
    /// and presents FindLocalVendorSheet with the category prefilled.
    static let openCoverageFindVendor = Notification.Name("openCoverageFindVendor")
    /// Posted from CoverageView's "I have one" tap. DashboardView listens
    /// and presents AddVendorSheet with the category prefilled.
    static let openCoverageAddVendor = Notification.Name("openCoverageAddVendor")
}
