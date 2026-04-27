import SwiftUI

/// V5 IconTile — the rounded square that anchors every list row.
/// 36×36 default or 44×44 large. Two tones: `indigo` (info/neutral) and
/// `salmon` (decision/recommendation/action). Inner SF Symbol at 55% size.
struct IconTile: View {
    enum Tone {
        case indigo
        case salmon

        var background: Color {
            switch self {
            case .indigo: return HavenColors.indigo50
            case .salmon: return HavenColors.actionPale
            }
        }

        var foreground: Color {
            switch self {
            case .indigo: return HavenColors.navy800
            case .salmon: return HavenColors.actionPressed
            }
        }
    }

    enum Size {
        case small  // 36×36, used by program/decision/recommended rows
        case large  // 44×44, used by VendorCard hero and BrowseBand left tile

        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .large: return 44
            }
        }

        var radius: CGFloat {
            switch self {
            case .small: return 10
            case .large: return 12
            }
        }

        var symbolPointSize: CGFloat {
            // Match the JSX prototype's 55% inner-symbol sizing.
            dimension * 0.55
        }
    }

    let symbol: String
    var tone: Tone = .indigo
    var size: Size = .small

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                .fill(tone.background)
            Image(systemName: symbol)
                .font(.system(size: size.symbolPointSize, weight: .semibold))
                .foregroundStyle(tone.foreground)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            IconTile(symbol: "leaf.fill", tone: .indigo)
            IconTile(symbol: "bolt.fill", tone: .salmon)
            IconTile(symbol: "wrench.adjustable.fill", tone: .indigo, size: .large)
            IconTile(symbol: "sparkles", tone: .salmon, size: .large)
        }
    }
    .padding()
    .background(HavenColors.background)
}
