import SwiftUI

/// Phase 70.A1 follow-on F3 — horizontal Up Next 14-day strip.
///
/// Renders at the top of the Tasks tab between MiniHero and the
/// duplicate banner / Needs Attention section. Surfaces every task or
/// routine occurrence in the next 14 days regardless of which season
/// tile is active — solves the "I scheduled a Spring task for June
/// and now it's gone" problem because June falls in the 14-day window
/// even when the Spring tile is selected.
///
/// Hidden when there's nothing in the window (no empty state — keeps
/// the screen quiet for newly-onboarded households).
struct UpNextStripSection: View {
    let entries: [UpNextEntry]
    let contractor: (UpNextEntry) -> ContractorRow?
    let onTap: (UpNextEntry) -> Void
    let onSeeAll: () -> Void

    private static let visibleCap = 7

    var body: some View {
        guardEmpty {
            VStack(alignment: .leading, spacing: TasksV5.sectionLabelGap) {
                header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(entries.prefix(Self.visibleCap)) { entry in
                            UpNextCard(
                                title: entry.title,
                                date: entry.date,
                                status: entry.status,
                                contractor: contractor(entry),
                                categoryIcon: entry.categoryIcon,
                                onTap: { onTap(entry) }
                            )
                        }
                        if entries.count > Self.visibleCap {
                            seeAllCard
                        }
                    }
                    .padding(.horizontal, TasksV5.pageMargin)
                }
            }
            .padding(.bottom, TasksV5.sectionGap)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("UP NEXT")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
                .tracking(0.6)
            Text("·")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
            Text("Next 14 days")
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
            Spacer(minLength: 0)
            if entries.count > Self.visibleCap {
                Button {
                    Haptics.selection()
                    onSeeAll()
                } label: {
                    HStack(spacing: 4) {
                        Text("See all \(entries.count)")
                            .font(HavenTypography.uiLabel)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(HavenColors.navy800)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
    }

    private var seeAllCard: some View {
        Button {
            Haptics.selection()
            onSeeAll()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(HavenColors.navy700)
                Text("See all \(entries.count)")
                    .font(HavenTypography.headline)
                    .foregroundColor(HavenColors.textPrimary)
                Text("View the full year overview")
                    .font(HavenTypography.uiLabel)
                    .foregroundColor(HavenColors.textSecondary)
            }
            .padding(12)
            .frame(width: 220, height: 124, alignment: .topLeading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.border.opacity(0.4), lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func guardEmpty<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if entries.isEmpty {
            EmptyView()
        } else {
            content()
        }
    }
}
