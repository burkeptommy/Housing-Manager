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
    /// Phase 85: surface "Chez owns this contact" badge + salmon tint
    /// when the linked handyman is delegated to Chez (e.g. Chez is the
    /// homeowner's point of contact for handyman work).
    var chezOwned: Bool = false
    var onTap: () -> Void = {}                // tap card body
    var onCall: (() -> Void)? = nil           // tap phone button (linked only)

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            HStack(spacing: 12) {
                IconTile(
                    symbol: "wrench.and.screwdriver.fill",
                    tone: chezOwned ? .salmon : .indigo,
                    size: .large
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.66)
                        .textCase(.uppercase)
                        .foregroundStyle(HavenColors.textTertiary)
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(HavenTypography.fraunces(size: 17, weight: 600))
                            .tracking(-0.2)
                            .foregroundStyle(HavenColors.navy900)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if chezOwned {
                            ChezOwnsBadge(compact: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingButton
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(chezOwned
                          ? HavenColors.action.opacity(0.04)
                          : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(chezOwned
                            ? HavenColors.action.opacity(0.25)
                            : HavenColors.beige200,
                            lineWidth: 1)
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
            .accessibilityLabel("Call contractor")
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
            Text("Once your contractor finishes a visit it shows up here.")
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

// MARK: - HandymanVisitCard

/// Phase 78 — Homeowner-side visit card. Replaces the generic
/// `UnifiedTaskCard` rendering of `service_key='handyman'` rows so the
/// homeowner stops seeing "two tasks with super long notes" and starts
/// seeing the underlying handyman visit as a first-class entity:
/// vendor + date + status + structured punch list as checkable subitems.
///
/// Counts and items come from the structured `handyman_punch_items`
/// rows the Phase 78 backfill created — same source of truth the
/// handyman field app reads.
struct HandymanVisitCard: View {
    let title: String                    // "Spring Handyman Visit"
    let vendorName: String?              // "Burke Handymen LLC"
    let scheduledDate: Date?             // nextDueDate / route_date
    let statusLabel: String              // "Confirmed" / "Awaiting your accept"
    let isStatusActive: Bool             // green when confirmed, amber otherwise
    let totalItems: Int
    let doneItems: Int
    let punchItems: [HandymanVisitPunchItem]
    var hasNeedsAttentionItem: Bool = false  // any added_after_lock=true

    var onTap: () -> Void = {}
    var onToggleItem: (String) -> Void = { _ in }
    var onMessage: (() -> Void)? = nil
    var onAddItem: (() -> Void)? = nil

    @State private var isExpanded: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded { expandedItems }
            footer
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(hasNeedsAttentionItem ? HavenColors.action.opacity(0.4) : HavenColors.beige200, lineWidth: 1)
        )
        .shadow(
            color: TasksV5.cardShadowColor,
            radius: TasksV5.cardShadowRadius,
            x: 0,
            y: TasksV5.cardShadowY
        )
    }

    private var header: some View {
        Button(action: {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            onTap()
        }) {
            HStack(spacing: 12) {
                IconTile(symbol: "wrench.and.screwdriver.fill", tone: .indigo, size: .large)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("HANDYMAN VISIT")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.66)
                            .foregroundStyle(HavenColors.textTertiary)
                        if hasNeedsAttentionItem {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.action)
                        }
                    }
                    Text(title)
                        .font(HavenTypography.fraunces(size: 17, weight: 600))
                        .tracking(-0.2)
                        .foregroundStyle(HavenColors.navy900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        if let vendorName, !vendorName.isEmpty {
                            Text(vendorName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(1)
                        }
                        if let scheduledDate {
                            if vendorName?.isEmpty == false {
                                Text("·")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Text(Self.dateFormatter.string(from: scheduledDate))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    statusPill
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var statusPill: some View {
        Text(statusLabel)
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(isStatusActive ? HavenColors.success : HavenColors.action)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill((isStatusActive ? HavenColors.success : HavenColors.action).opacity(0.10))
            )
    }

    @ViewBuilder
    private var expandedItems: some View {
        if punchItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No items on this visit yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(HavenColors.textSecondary)
                if let onAddItem {
                    Button(action: onAddItem) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Add a punch item")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(HavenColors.action)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        } else {
            VStack(spacing: 6) {
                Divider().background(HavenColors.beige200)
                VStack(spacing: 6) {
                    ForEach(punchItems) { item in
                        Button(action: { onToggleItem(item.id) }) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(item.isDone ? HavenColors.success : HavenColors.textTertiary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(item.isDone ? HavenColors.textSecondary : HavenColors.navy900)
                                        .strikethrough(item.isDone, color: HavenColors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    if let badge = item.metaBadge {
                                        Text(badge)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(item.addedAfterLock ? HavenColors.action : HavenColors.textTertiary)
                                    }
                                }
                                Spacer(minLength: 6)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            // Progress text
            Text(progressLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            if let onAddItem {
                Button(action: onAddItem) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(HavenColors.navy800)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(HavenColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add punch item")
            }
            if let onMessage {
                Button(action: onMessage) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HavenColors.navy800)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(HavenColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Message contractor")
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, isExpanded ? 6 : 0)
    }

    private var progressLabel: String {
        if totalItems == 0 { return "Open visit" }
        return "\(doneItems) of \(totalItems) items done"
    }
}

/// Lightweight value type for `HandymanVisitCard.punchItems`. Caller
/// converts a `HandymanPunchItemRow` into one of these so the card
/// stays UI-only and doesn't import the DB model.
struct HandymanVisitPunchItem: Identifiable, Equatable {
    let id: String
    let title: String
    let isDone: Bool
    let estimatedMinutes: Int?
    let systemLabel: String?
    let addedAfterLock: Bool

    /// One-line meta badge under the title — minutes, system link, or
    /// "Added after Burke confirmed". First non-nil wins.
    var metaBadge: String? {
        if addedAfterLock { return "Added after contractor confirmed" }
        if let systemLabel { return "Linked: \(systemLabel)" }
        if let m = estimatedMinutes { return "~\(m) min" }
        return nil
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
            HandymanVisitCard(
                title: "Spring Service Visit",
                vendorName: "Burke Handymen LLC",
                scheduledDate: Date(),
                statusLabel: "Confirmed",
                isStatusActive: true,
                totalItems: 18,
                doneItems: 0,
                punchItems: [
                    .init(id: "1", title: "Clean dryer vent duct", isDone: false, estimatedMinutes: 45, systemLabel: nil, addedAfterLock: false),
                    .init(id: "2", title: "Fire extinguisher annual check", isDone: true, estimatedMinutes: 15, systemLabel: nil, addedAfterLock: false),
                    .init(id: "3", title: "Top up joint sand in pavers", isDone: false, estimatedMinutes: 30, systemLabel: nil, addedAfterLock: true),
                ],
                hasNeedsAttentionItem: true
            )
            PunchListCard(items: $items, extraCount: 19)
            RecommendedRow(title: "Treat weeds between pavers", due: "in 3 months")
            VisitHistoryEmptyCard()
        }
        .padding(20)
    }
    .background(HavenColors.background)
}
