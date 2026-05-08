import SwiftUI

/// V5 IndigoGradientCard — the signature indigo gradient surface used by:
///   • Maintenance MiniHero (.hero variant — 3-stop gradient + 16pt padding)
///   • Handyman VisitHero (.hero variant — same)
///   • Maintenance BrowseBand (.band variant — 2-stop gradient)
///   • Handyman WhatWeHandleBand (.band variant — same)
///
/// Wraps any content in the right gradient + radius + shadow combo.
struct IndigoGradientCard<Content: View>: View {
    enum Variant {
        case hero
        case band

        var gradient: LinearGradient {
            switch self {
            case .hero: return TasksV5.heroGradient
            case .band: return TasksV5.bandGradient
            }
        }

        var padding: CGFloat {
            switch self {
            case .hero: return 16
            case .band: return 18
            }
        }

        var shadowColor: Color {
            switch self {
            case .hero: return TasksV5.heroShadowColor
            case .band: return TasksV5.bandShadowColor
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .hero: return TasksV5.heroShadowRadius
            case .band: return TasksV5.bandShadowRadius
            }
        }

        var shadowY: CGFloat {
            switch self {
            case .hero: return TasksV5.heroShadowY
            case .band: return TasksV5.bandShadowY
            }
        }
    }

    let variant: Variant
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(variant.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(variant.gradient)
            )
            .shadow(
                color: variant.shadowColor,
                radius: variant.shadowRadius,
                x: 0,
                y: variant.shadowY
            )
    }
}

// MARK: - Maintenance MiniHero content

/// V5 Maintenance MiniHero — sits below the YearRibbon. Three stats stacked
/// inside an `IndigoGradientCard.hero`. Coverage headline + progress bar +
/// programs / decisions / bundle-ready stat row.
struct MiniHeroContent: View {
    let scopeLabel: String                  // "this year" or "this spring"
    let coveredCount: Int
    let totalCount: Int
    let programCount: Int
    let decisionCount: Int
    let bundleReadyCount: Int

    private var pct: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(coveredCount) / Double(totalCount) * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: headline + count
            HStack(alignment: .firstTextBaseline) {
                Text("\(pct)% covered \(scopeLabel)")
                    .font(HavenTypography.fraunces(size: 17, weight: 500))
                    .tracking(-0.25)
                    .foregroundStyle(.white)
                Spacer(minLength: 8)
                Text("\(coveredCount)/\(totalCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.bottom, 10)

            // Progress bar (6pt tall, salmon fill)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(HavenColors.action)
                        .frame(width: geo.size.width * CGFloat(pct) / 100.0)
                        .animation(HavenTheme.animationProgress, value: pct)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 14)

            // Stats row: 3 columns with vertical dividers
            HStack(spacing: 0) {
                statColumn(value: programCount, label: "programs", isWarning: false)
                divider
                statColumn(value: decisionCount, label: "decisions", isWarning: true)
                divider
                statColumn(value: bundleReadyCount, label: "bundle-ready", isWarning: false)
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    private func statColumn(value: Int, label: String, isWarning: Bool) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(HavenTypography.fraunces(size: 22, weight: 700))
                .tracking(-0.4)
                .foregroundStyle(isWarning ? HavenColors.actionLight : Color.white)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(Color.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
    }
}

// MARK: - Handyman VisitHero content

/// V5 Handyman VisitHero — "NEXT VISIT" eyebrow + serif headline + sub
/// + Schedule visit CTA + phone shortcut. Sits inside an
/// `IndigoGradientCard.hero`.
struct VisitHeroContent: View {
    let itemCount: Int
    let vendorName: String?
    let estimateLabel: String?
    let onSchedule: () -> Void
    let onCall: (() -> Void)?

    private var headline: String {
        if itemCount == 0 {
            return "Nothing on the punch list yet"
        } else if itemCount == 1 {
            return "1 small job ready to bundle"
        } else {
            return "\(itemCount) small jobs ready to bundle"
        }
    }

    private var subline: String {
        let vendor = vendorName ?? "No contractor yet"
        if let estimate = estimateLabel, !estimate.isEmpty {
            return "\(vendor) · \(estimate) estimated"
        } else {
            return vendor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT VISIT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.32)                          // 0.12em on 11pt
                .foregroundStyle(HavenColors.actionLight)
                .padding(.bottom, 6)

            Text(headline)
                .font(HavenTypography.fraunces(size: 19, weight: 500))
                .tracking(-0.3)
                .lineSpacing(2)
                .foregroundStyle(.white)
                .padding(.bottom, 4)
                .fixedSize(horizontal: false, vertical: true)

            Text(subline)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.white.opacity(0.72))
                .padding(.bottom, 14)

            HStack(spacing: 8) {
                Button(action: {
                    Haptics.medium()
                    onSchedule()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Schedule visit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HavenColors.action)
                    )
                    .shadow(
                        color: TasksV5.salmonGlowColor,
                        radius: TasksV5.salmonGlowRadius,
                        x: 0,
                        y: TasksV5.salmonGlowY
                    )
                }
                .buttonStyle(.plain)

                if let onCall {
                    Button(action: {
                        Haptics.light()
                        onCall()
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call handyman")
                }
            }
        }
    }
}

// MARK: - BrowseBand (Maintenance end-of-feed CTA)

/// V5 BrowseBand — destination CTA at the end of the Maintenance feed.
/// Indigo gradient .band with sparkles + serif title + sub + chevron.
struct BrowseBand: View {
    var title: String = "Browse additional services"
    var subtitle: String = "15 seasonal & on-demand services"
    var action: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            IndigoGradientCard(variant: .band) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 44, height: 44)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(HavenColors.actionLight)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(HavenTypography.fraunces(size: 16, weight: 600))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WhatWeHandleBand (Handyman explainer)

/// V5 WhatWeHandleBand — explanatory band on the Handyman screen.
/// No chevron (it's not a destination). Indigo gradient .band with
/// sparkles tile + serif title + bulleted list of handyman job types.
struct WhatWeHandleBand: View {
    let items: [String] = [
        "Caulking and grout touch-ups",
        "Door and cabinet alignment",
        "Filter, battery, weatherstrip swaps",
        "Drywall and paint touch-ups",
        "Mounting, hanging, fixture installs",
        "Gutter, attic, exterior walk-downs",
    ]

    var body: some View {
        IndigoGradientCard(variant: .band) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(HavenColors.actionLight)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Small jobs that protect value")
                            .font(HavenTypography.fraunces(size: 16, weight: 600))
                            .foregroundStyle(.white)
                        Text("Bundle them into a single visit.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(HavenColors.actionLight)
                                .frame(width: 5, height: 5)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.92))
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 18) {
            IndigoGradientCard(variant: .hero) {
                MiniHeroContent(
                    scopeLabel: "this year",
                    coveredCount: 7,
                    totalCount: 16,
                    programCount: 7,
                    decisionCount: 5,
                    bundleReadyCount: 4
                )
            }
            IndigoGradientCard(variant: .hero) {
                VisitHeroContent(
                    itemCount: 23,
                    vendorName: "Burke Handymen LLC",
                    estimateLabel: "~3.5 hrs",
                    onSchedule: {},
                    onCall: {}
                )
            }
            BrowseBand()
            WhatWeHandleBand()
        }
        .padding(20)
    }
    .background(HavenColors.background)
}
