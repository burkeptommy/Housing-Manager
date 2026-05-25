import SwiftUI

/// Phase 70 (Tasks v2): Inline children list rendered inside a `BundleParentCard`.
///
/// The single user-facing change Tom called out specifically: "make sure we
/// show the associated child tasks bundled into the parent." Bundle children
/// surface as read-only line items so the homeowner sees what a single
/// vendor visit actually covers without tapping into a detail sheet.
///
/// Truncation rules:
/// - 0–3 children: show all, no chevron
/// - 4+ children: show first 3 + `+ N more` chevron; tap to expand
/// - Expanded state is owned by the parent card (passed in via Binding)
///   so SwiftUI animates the height change smoothly
///
/// Per-child visual: bullet + 1-line title + tiny `vendor` / `DIY` capsule.
/// Children are NOT independently tappable (per Phase 54A — the bundle is
/// the atomic completion unit). VoiceOver labels mark them as `.staticText`.
struct BundleChildList: View {
    let children: [MaintenanceTemplate]
    @Binding var isExpanded: Bool

    /// Number of children shown when collapsed (Phase 70 spec: 3).
    private let collapsedCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(visibleChildren.enumerated()), id: \.offset) { _, child in
                ChildRow(template: child)
            }
            if shouldShowMoreRow {
                Button {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(moreRowLabel)
                            .font(HavenTypography.uiLabel)
                            .foregroundColor(HavenColors.action)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(HavenColors.action)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Show fewer items" : "Show \(hiddenCount) more items")
            }
        }
    }

    // MARK: - Visibility logic

    private var visibleChildren: [MaintenanceTemplate] {
        if isExpanded || children.count <= collapsedCount {
            return children
        }
        return Array(children.prefix(collapsedCount))
    }

    private var shouldShowMoreRow: Bool {
        children.count > collapsedCount
    }

    private var hiddenCount: Int {
        max(0, children.count - collapsedCount)
    }

    private var moreRowLabel: String {
        isExpanded ? "Show less" : "+ \(hiddenCount) more"
    }
}

// MARK: - Child row

/// One read-only line item inside a bundle. Bullet · title · tiny pill.
/// Pill priority order (highest wins): `safety` (red) > `DIY` (success
/// green) > `vendor` (navy). Vendor is the default for templates with
/// `assignmentType == .vendor`; DIY for `.diyDefault` routingOverride or
/// `.personal` assignment.
private struct ChildRow: View {
    let template: MaintenanceTemplate

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("·")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(HavenColors.action.opacity(0.6))
                .frame(width: 8, alignment: .leading)
            Text(template.title)
                .font(HavenTypography.body)
                .foregroundColor(HavenColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            childPill
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(template.title). \(accessibilityPillLabel)")
        .accessibilityAddTraits(.isStaticText)
    }

    // Tiny capsule pill on the trailing edge of each child row.
    @ViewBuilder
    private var childPill: some View {
        let label = pillLabel
        let color = pillColor
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.4)
            .foregroundColor(color.foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.background)
            )
    }

    // MARK: pill resolution

    private var pillLabel: String {
        if template.safetyFloor {
            return "SAFETY"
        }
        if template.routingOverride == .diyDefault || template.assignmentType == .personal {
            return "DIY"
        }
        return "VENDOR"
    }

    private var pillColor: (foreground: Color, background: Color) {
        if template.safetyFloor {
            return (HavenColors.critical, HavenColors.critical.opacity(0.12))
        }
        if template.routingOverride == .diyDefault || template.assignmentType == .personal {
            return (HavenColors.success, HavenColors.success.opacity(0.12))
        }
        return (HavenColors.navy800, HavenColors.navy800.opacity(0.08))
    }

    private var accessibilityPillLabel: String {
        switch pillLabel {
        case "SAFETY": return "Safety-critical task."
        case "DIY":    return "Do-it-yourself."
        default:       return "Handled by vendor."
        }
    }
}

// Preview fixtures omitted — the MaintenanceTemplate init has many
// optional parameters that drift over time. The component is best
// verified visually in a real simulator run against a seeded household.
