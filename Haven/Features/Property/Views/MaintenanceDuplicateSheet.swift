import SwiftUI

/// Phase 56.5: Review and resolve a single detected duplicate. Shows
/// both entities side-by-side; user picks keep-both / keep-primary /
/// keep-secondary. Archiving is reversible from the detail surface —
/// nothing is permanently deleted without intent.
///
/// The sheet never merges data. A resolution either (a) records that
/// the pair is NOT a duplicate (30-day dismissal via
/// DuplicateDismissalStore) or (b) archives the loser of the pair
/// (routines → `archived_at`; tasks → hard delete via the existing
/// `deleteMaintenanceTask` path since `maintenance_tasks` doesn't
/// have a soft-delete flag).
///
/// Phase 56.5 patch: the sheet no longer owns dismissal. The parent
/// (`MaintenanceScheduleView`) drives the queue via the
/// `.sheet(item: $reviewingMatch)` binding — setting the binding to
/// the next match swaps content in place (no flash to the list),
/// setting it to nil dismisses. This matches Apple Photos' "Review
/// Duplicates" pagination flow.
struct MaintenanceDuplicateSheet: View {
    let match: DuplicateDetector.Match
    /// 0-indexed position of `match` inside the parent's queue. Used
    /// for the "N of M" principal-toolbar progress indicator.
    let currentIndex: Int
    /// Total number of duplicates in the queue (including `match`).
    /// The progress indicator hides itself when this equals 1.
    let totalCount: Int
    let onResolve: (Resolution) async -> Void
    /// Fired from the Done toolbar button. Parent typically sets
    /// `reviewingMatch = nil` to close the queue early.
    let onCancel: () -> Void

    @State private var isResolving = false

    /// What the user picked in the review flow. The parent handler
    /// maps these cases to archive/delete writes + analytics events.
    enum Resolution {
        /// Not a duplicate — record the decision for 30 days so the
        /// pair doesn't resurface immediately.
        case keepBoth
        /// Archive the secondary entity, keep the primary.
        case keepPrimary
        /// Archive the primary entity, keep the secondary.
        case keepSecondary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing20) {
                    // Match reason — sits above the cards because the
                    // principal toolbar now carries the title. The user
                    // reads this to understand why Haven grouped these
                    // two entities.
                    Text(match.reason)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.top, HavenTheme.spacing16)

                    // Primary entity card
                    entityCard(
                        title: match.primary.displayName,
                        kind: match.primaryKind,
                        vendorName: match.primary.vendorName,
                        categoryLabel: match.primary.categoryLabel,
                        actionLabel: "Keep this, archive the other"
                    ) {
                        Task { await resolve(.keepPrimary) }
                    }

                    // "OR" divider
                    HStack {
                        Rectangle()
                            .fill(HavenColors.beige300)
                            .frame(height: 1)
                        Text("OR")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(HavenColors.beige300)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)

                    // Secondary entity card
                    entityCard(
                        title: match.secondary.displayName,
                        kind: match.secondaryKind,
                        vendorName: match.secondary.vendorName,
                        categoryLabel: match.secondary.categoryLabel,
                        actionLabel: "Keep this, archive the other"
                    ) {
                        Task { await resolve(.keepSecondary) }
                    }

                    // Not a duplicate — 30-day dismissal.
                    Button {
                        Task { await resolve(.keepBoth) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("These aren't duplicates")
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HavenTheme.spacing12)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing12)
                    .padding(.bottom, HavenTheme.spacing24)
                }
            }
            .background(HavenColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Review duplicate")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        if totalCount > 1 {
                            Text("\(currentIndex + 1) of \(totalCount)")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onCancel() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .disabled(isResolving)
        }
    }

    @ViewBuilder
    private func entityCard(
        title: String,
        kind: DuplicateDetector.EntityKind,
        vendorName: String?,
        categoryLabel: String?,
        actionLabel: String,
        onTap: @escaping () -> Void
    ) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    Image(systemName: kind == .routine
                          ? "calendar.badge.clock"
                          : "checklist")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.navy700)
                    Text(kind == .routine ? "ROUTINE" : "TASK")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)
                }

                Text(title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let vendorName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                        Text(vendorName)
                    }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                }

                if let categoryLabel {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 11))
                        Text(categoryLabel)
                    }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                }

                Button(action: onTap) {
                    Text(actionLabel)
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HavenTheme.spacing12)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    /// Phase 56.5 patch: no `dismiss()` call. The parent drives the
    /// sheet lifecycle via `reviewingMatch` — after `onResolve` lands
    /// it either swaps to the next match in place or sets the binding
    /// to nil. Calling `dismiss()` here would race with that
    /// re-presentation and drop the user back to the list between
    /// every review.
    private func resolve(_ resolution: Resolution) async {
        isResolving = true
        await onResolve(resolution)
        isResolving = false
    }
}
