import SwiftUI

// MARK: - Section header

/// Section header for the enhanced Property sub-tabs. Renders a 10pt
/// uppercase eyebrow on the left, optional `sub` next to it, and an
/// optional action link on the right. Mirrors the JSX `SectionLabel`.
struct PropertyEnhancedSectionHeader: View {
    let title: String
    var sub: String? = nil
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textSoft)
            if let sub {
                Text(sub)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HavenColors.textSoft)
                    .lineLimit(1)
            }
            Spacer()
            if let actionLabel, let onAction {
                Button(action: {
                    Haptics.light()
                    onAction()
                }) {
                    Text(actionLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.navy500)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.bottom, HavenTheme.spacing12)
    }
}

// MARK: - Decision card

/// Salmon-tinted "Needs your decision" card for the Overview sub-tab.
/// Renders a title, sub-line, and a colored CTA. `subdued = true` swaps
/// the salmon wash for a plain white card with the indigo CTA color.
struct PropertyDecisionCard: View {
    let title: String
    let subtitle: String
    let cta: String
    var subdued: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.medium()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.top, 2)
                HStack(spacing: 4) {
                    Text(cta)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(subdued ? HavenColors.navy500 : HavenColors.action)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(subdued ? HavenColors.surface : HavenColors.action50)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .strokeBorder(
                        subdued ? HavenColors.beige200 : HavenColors.actionPale,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(HavenButtonPressStyle())
    }
}

// MARK: - Coming-up timeline row

/// Single row in the Overview "Coming up" timeline — date column on
/// the left, divider, then title + meta. Salmon meta tone signals
/// "needs vendor"; muted is informational.
struct PropertyTimelineRow: View {
    let dayNumber: String
    let monthLabel: String
    let title: String
    let meta: String
    var metaIsSalmon: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(monthLabel.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(HavenColors.textSoft)
                }
                .frame(width: 36)

                Rectangle()
                    .fill(HavenColors.beige200)
                    .frame(width: 1)
                    .frame(maxHeight: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(meta)
                        .font(.system(size: 12, weight: metaIsSalmon ? .semibold : .regular))
                        .foregroundStyle(metaIsSalmon ? HavenColors.action : HavenColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

/// White card wrapping a stack of `PropertyTimelineRow`s with hairline
/// dividers between each row.
struct PropertyTimelineCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
        .havenShadow(HavenTheme.shadowElevated)
    }
}

/// 1pt divider rendered between timeline rows. Insets so it stops
/// short of the date column for a slightly editorial feel.
struct PropertyTimelineDivider: View {
    var body: some View {
        Rectangle()
            .fill(HavenColors.beige200)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

// MARK: - Systems Browse grid tile

/// Category tile for the Systems "Browse" 2-column grid. Renders a
/// 36pt indigo-50 icon tile, the category name, and the system count.
///
/// May 2026 friend feedback Round 3: the optional per-tile attention
/// dot was removed. The verification banner above the grid and the
/// "X need profile" caption already communicate per-property state;
/// the dot rule ("any system lacks a preferred contractor") didn't
/// match either signal and read as visual noise.
struct PropertySystemsCategoryTile: View {
    let icon: String
    let title: String
    let systemCount: Int
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HavenColors.indigo50)
                    )

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    // Wave C-9 #6 fix: was lineLimit(1) which clipped
                    // "Electrical & Safety" to "Electrical & Safe..."
                    // on standard tile widths. lineLimit(2) lets the
                    // full label wrap to a second line on the widest
                    // group names without changing the grid layout.
                    // Safety connotation preserved.
                    .lineLimit(2)
                    .padding(.top, 12)

                Text("\(systemCount) system\(systemCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(HavenButtonPressStyle())
    }
}

// Note: Systems Browse uses the canonical `SystemGroup` model directly
// (see `Haven/Features/Property/Models/SystemGroup.swift`). The duplicate
// `PropertySystemsCategory` enum that lived here was deleted so the grid
// + the `SystemGroupListView` navigation destination always agree on
// bucket membership.

// MARK: - Editorial blurb (no card chrome)

/// Editorial pitch used at the top of empty-state surfaces. Serif
/// title + muted body, no card chrome — feels like a magazine page,
/// not an empty-state placeholder.
struct PropertyEditorialBlurb: View {
    let title: String
    let copy: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(HavenColors.textPrimary)
                .lineSpacing(2)
            Text(copy)
                .font(.system(size: 13))
                .foregroundStyle(HavenColors.textSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, HavenTheme.spacing8)
    }
}

// MARK: - Project starter row

/// One starter option in the Projects empty-state stack. The first
/// one is rendered with `tone: .hero` (indigo bg + salmon-light CTA);
/// the rest with `tone: .standard` (white card + indigo CTA).
struct PropertyProjectStarterRow: View {
    enum Tone {
        case hero
        case standard
    }

    let title: String
    let subtitle: String
    let cta: String
    var tone: Tone = .standard
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.medium()
            onTap()
        }) {
            HStack(spacing: HavenTheme.spacing12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(titleColor)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(cta)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ctaColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .strokeBorder(borderColor, lineWidth: tone == .hero ? 0 : 1)
            )
            .modifier(HeroShadowIfNeeded(active: tone == .hero))
        }
        .buttonStyle(HavenButtonPressStyle())
    }

    private var background: Color {
        tone == .hero ? HavenColors.navy : HavenColors.surface
    }

    private var borderColor: Color {
        tone == .hero ? Color.clear : HavenColors.beige200
    }

    private var titleColor: Color {
        tone == .hero ? HavenColors.textOnNavy : HavenColors.textPrimary
    }

    private var subtitleColor: Color {
        tone == .hero ? Color.white.opacity(0.7) : HavenColors.textSecondary
    }

    private var ctaColor: Color {
        tone == .hero ? HavenColors.actionLight : HavenColors.navy500
    }
}

private struct HeroShadowIfNeeded: ViewModifier {
    let active: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if active && colorScheme != .dark {
            content.shadow(
                color: HavenColors.navy900.opacity(0.18),
                radius: 16,
                y: 8
            )
        } else {
            content
        }
    }
}

// MARK: - Vendor spend strip

/// Two-column stat card sitting at the top of the Vendors tab. Each
/// column has an uppercase soft eyebrow + a serif number. The recurring
/// column appends a `/mo` suffix in muted weight 500.
struct PropertyVendorSpendStrip: View {
    let recurringMonthly: Double?
    let yearToDate: Double?

    var body: some View {
        HStack(spacing: 14) {
            statColumn(
                eyebrow: "Recurring spend",
                value: recurringMonthly.map { $0.formattedCompactCurrency() } ?? "",
                suffix: recurringMonthly == nil ? nil : " /mo"
            )
            Rectangle()
                .fill(HavenColors.beige200)
                .frame(width: 1, height: 36)
            statColumn(
                eyebrow: "This year",
                value: yearToDate.map { $0.formattedCompactCurrency() } ?? "",
                suffix: nil
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    private func statColumn(eyebrow: String, value: String, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.3)
                .foregroundStyle(HavenColors.textSoft)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(HavenColors.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Document vault hero

/// Hero card for the top of the Documents sub-tab. Serif "Vault" title
/// + summary line on the left, indigo-50 shield tile on the right, then
/// a salmon "Upload" CTA + ghost "Scan" button beneath.
struct PropertyDocumentVaultHero: View {
    let uploadedCount: Int
    let suggestedCount: Int
    let accessRolesCount: Int
    var onUpload: () -> Void
    var onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vault")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .tracking(-0.3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(summaryLine)
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "shield.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(HavenColors.indigo50)
                    )
            }

            HStack(spacing: 8) {
                HavenButton(
                    title: "Upload document",
                    action: onUpload,
                    style: .primary,
                    size: .compact,
                    icon: "doc.badge.plus",
                    isFullWidth: true
                )
                HavenButton(
                    title: "Scan",
                    action: onScan,
                    style: .secondary,
                    size: .compact,
                    icon: "doc.text.viewfinder",
                    isFullWidth: false
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
        .havenShadow(HavenTheme.shadowElevated)
    }

    private var summaryLine: String {
        var parts: [String] = []
        parts.append("\(uploadedCount) uploaded")
        if suggestedCount > 0 {
            parts.append("\(suggestedCount) suggested")
        }
        if accessRolesCount > 0 {
            parts.append("\(accessRolesCount) access role\(accessRolesCount == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Document suggestion model

/// Curated suggestion shown when the property's vault is empty or
/// sparse. `matchKey` is a lowercased substring used to filter out
/// suggestions for documents the user already has.
struct PropertyDocumentSuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let matchKey: String

    static let curated: [PropertyDocumentSuggestion] = [
        .init(icon: "shield.fill", title: "Homeowners insurance", subtitle: "Critical · annual renewal", matchKey: "homeowners"),
        .init(icon: "doc.text.fill", title: "Deed", subtitle: "On record at the county", matchKey: "deed"),
        .init(icon: "square.stack.3d.up.fill", title: "Mortgage statement", subtitle: "Lender on file", matchKey: "mortgage"),
        .init(icon: "magnifyingglass", title: "Home inspection", subtitle: "From your purchase", matchKey: "inspection")
    ]
}

// MARK: - Document suggested row

/// Suggested-document row: 36pt indigo-50 icon tile, name + sub, then
/// an indigo "+ Add" pill on the right.
struct PropertyDocumentSuggestedRow: View {
    let iconSystemName: String
    let title: String
    let subtitle: String
    var onAdd: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onAdd()
        }) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: iconSystemName)
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HavenColors.indigo50)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("+ Add")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(HavenColors.indigo50)
                    .clipShape(Capsule())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(HavenButtonPressStyle())
    }
}
