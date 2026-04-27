import SwiftUI

/// V5 ArrowLink — text + trailing "→" glyph. Two tones:
///   - `.salmon` (primary action: "Choose vendor →", "Set up →")
///   - `.indigo` (navigation: "See all →", "View all →")
struct ArrowLink: View {
    enum Tone {
        case salmon
        case indigo

        var color: Color {
            switch self {
            case .salmon: return HavenColors.actionPressed   // #D14E3E
            case .indigo: return HavenColors.navy500          // #6B5AA0
            }
        }
    }

    let title: String
    var tone: Tone = .salmon
    var action: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text("→")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(tone.color)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title.lowercased())")
    }
}

/// V5 SectionLabel — the eyebrow + optional sub-label + optional trailing
/// ArrowLink that sits above every section's row list.
struct SectionLabel: View {
    let eyebrow: String
    var sub: String? = nil
    var action: ActionConfig? = nil

    struct ActionConfig {
        let title: String
        var tone: ArrowLink.Tone = .indigo
        let perform: () -> Void
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(eyebrow)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)                              // 0.15em on a 10pt body
                    .textCase(.uppercase)
                    .foregroundStyle(HavenColors.textTertiary)
                if let sub {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer(minLength: 0)
            }
            if let action {
                ArrowLink(title: action.title, tone: action.tone, action: action.perform)
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
    }
}

#Preview {
    VStack(spacing: 32) {
        SectionLabel(
            eyebrow: "Needs your decision",
            sub: "Due Apr 20",
            action: .init(title: "See all", perform: {})
        )
        SectionLabel(
            eyebrow: "Active programs",
            sub: "On autopilot",
            action: .init(title: "See all", perform: {})
        )
        SectionLabel(eyebrow: "Vehicles")
        SectionLabel(
            eyebrow: "Punch list",
            sub: "23 items",
            action: .init(title: "View all", perform: {})
        )
    }
    .padding(.vertical)
    .background(HavenColors.background)
}
