import SwiftUI

// MARK: - VendorCard

/// V5 VendorCard — sits between VisitHero and PunchListCard.
///
/// Two states:
///   • `.linked(vendor:)` — large indigo wrench tile + "YOUR HANDYMAN"
///     eyebrow + serif vendor name + 40×40 phone button on right
///   • `.empty(onFind:)`  — large indigo wrench tile + "FIND A HANDYMAN"
///     eyebrow + "We'll match you with a vetted local pro" + chevron
struct VendorCard: View {
    enum State {
        case linked(name: String, phoneURL: URL?)
        case empty
    }

    let state: State
    var onTap: () -> Void = {}                // tap card body
    var onCall: (() -> Void)? = nil           // tap phone button (linked only)

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            HStack(spacing: 12) {
                IconTile(symbol: "wrench.and.screwdriver.fill", tone: .indigo, size: .large)
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.66)
                        .textCase(.uppercase)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(displayName)
                        .font(HavenTypography.fraunces(size: 17, weight: 600))
                        .tracking(-0.2)
                        .foregroundStyle(HavenColors.navy900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingButton
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
            .shadow(
                color: TasksV5.cardShadowColor,
                radius: TasksV5.cardShadowRadius,
                x: 0,
                y: TasksV5.cardShadowY
            )
        }
        .buttonStyle(.plain)
    }

    private var eyebrow: String {
        switch state {
        case .linked: return "YOUR HANDYMAN"
        case .empty:  return "FIND A HANDYMAN"
        }
    }

    private var displayName: String {
        switch state {
        case .linked(let name, _): return name
        case .empty:               return "Match me with a vetted local pro"
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        switch state {
        case .linked(_, let phoneURL):
            Button {
                Haptics.light()
                if let phoneURL { UIApplication.shared.open(phoneURL) }
                onCall?()
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(HavenColors.beige200, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Call handyman")
        case .empty:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
    }
}

// MARK: - PunchListCard

/// V5 PunchListCard — checkbox list with circle toggles.
/// Each row: 22×22 circle (filled green when checked) + title (line-through
/// when checked) + optional duration on right. Footer: "+ N more" link
/// when there are extra items not shown.
struct PunchListItem: Identifiable, Equatable {
    /// Stable identifier — matches `HandymanPunchEntry.id` (String, not UUID,
    /// so the manual punch_items + maintenance_tasks lanes can co-exist).
    let id: String
    let title: String
    let duration: String?
    var isChecked: Bool
}

struct PunchListCard: View {
    @Binding var items: [PunchListItem]
    let extraCount: Int
    var onToggle: (String) -> Void = { _ in }
    var onTapItem: (String) -> Void = { _ in }
    var onShowMore: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                punchRow(item: item, isLast: index == items.count - 1)
            }
            if extraCount > 0 {
                Button(action: {
                    Haptics.selection()
                    onShowMore()
                }) {
                    Text("+ \(extraCount) more")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
        .shadow(
            color: TasksV5.cardShadowColor,
            radius: TasksV5.cardShadowRadius,
            x: 0,
            y: TasksV5.cardShadowY
        )
    }

    @ViewBuilder
    private func punchRow(item: PunchListItem, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    Haptics.light()
                    onToggle(item.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(item.isChecked ? HavenColors.success : Color.clear)
                            .frame(width: 22, height: 22)
                        Circle()
                            .stroke(
                                item.isChecked ? Color.clear : HavenColors.beige400,
                                lineWidth: 1.7
                            )
                            .frame(width: 22, height: 22)
                        if item.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isChecked ? "Mark incomplete" : "Mark complete")

                // Title — tap opens detail
                Button {
                    Haptics.selection()
                    onTapItem(item.id)
                } label: {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(item.isChecked ? HavenColors.textTertiary : HavenColors.navy900)
                        .strikethrough(item.isChecked, color: HavenColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)

                // Duration (optional)
                if let duration = item.duration {
                    Text(duration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                        .layoutPriority(1)
                }
            }
            .padding(.vertical, 12)

            if !isLast {
                Rectangle()
                    .fill(TasksV5.punchListDivider)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - RecommendedRow

/// V5 RecommendedRow — white row in the "Recommended" section on Handyman.
/// Salmon IconTile (sparkles) + title + due meta + 32×32 salmon "+" button
/// to add the item to the punch list.
struct RecommendedRow: View {
    let title: String
    let due: String                        // "in 3 months"
    var isAdding: Bool = false             // shows progress on the + button
    var onTap: () -> Void = {}             // open task preview
    var onAdd: () -> Void = {}             // add to punch list

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                Haptics.selection()
                onTap()
            }) {
                HStack(spacing: 12) {
                    IconTile(symbol: "sparkles", tone: .salmon)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.navy900)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(due)
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            // Salmon "+" button
            Button(action: {
                guard !isAdding else { return }
                Haptics.medium()
                onAdd()
            }) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action)
                        .frame(width: 32, height: 32)
                    if isAdding {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(
                    color: TasksV5.salmonPlusGlowColor,
                    radius: TasksV5.salmonPlusGlowRadius,
                    x: 0,
                    y: TasksV5.salmonPlusGlowY
                )
            }
            .buttonStyle(.plain)
            .disabled(isAdding)
            .accessibilityLabel("Add \(title) to punch list")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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

// MARK: - VisitHistoryEmptyCard

/// V5 dashed empty-state card for the Handyman screen's "Visit history"
/// section. Used pre-populated with the canonical copy from V5 spec.
struct VisitHistoryEmptyCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("No completed visits yet.")
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textSecondary)
            Text("Once your handyman finishes a visit it shows up here.")
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
                .foregroundStyle(HavenColors.beige300)
        )
    }
}

#Preview {
    @Previewable @State var items: [PunchListItem] = [
        .init(id: "p1", title: "Clean dryer vent duct", duration: nil, isChecked: false),
        .init(id: "p2", title: "Fire extinguisher annual check", duration: "15 min", isChecked: true),
        .init(id: "p3", title: "Annual radon test", duration: "20 min", isChecked: false),
        .init(id: "p4", title: "Re-caulk bath and shower seams", duration: "45 min", isChecked: false),
    ]

    ScrollView {
        VStack(spacing: 16) {
            VendorCard(state: .linked(name: "Burke Handymen LLC", phoneURL: nil))
            VendorCard(state: .empty)
            PunchListCard(items: $items, extraCount: 19)
            RecommendedRow(title: "Treat weeds between pavers", due: "in 3 months")
            VisitHistoryEmptyCard()
        }
        .padding(20)
    }
    .background(HavenColors.background)
}
