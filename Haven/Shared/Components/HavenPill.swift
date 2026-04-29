import SwiftUI

/// Chez status pill — small inline tag with a colored dot + 11pt
/// semibold label. Mirrors `ChezPill` from the design-system JSX
/// prototype.
///
/// Tones map to semantic colors at low opacity (12%) for the
/// background and the full color for the dot + text. The `salmon` /
/// `indigo` / `neutral` tones sit on top of the semantic ones for
/// brand-flavored pills (eyebrow accents, "Routine" markers, etc.).
struct HavenPill: View {
    enum Tone {
        case success
        case warning
        case critical
        case info
        case salmon
        case indigo
        case neutral
    }

    let label: String
    var tone: Tone = .success
    var icon: String? = nil
    var showsDot: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(foreground)
            } else if showsDot {
                Circle()
                    .fill(foreground)
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    private var foreground: Color {
        switch tone {
        case .success: return HavenColors.success
        case .warning: return HavenColors.warning
        case .critical: return HavenColors.critical
        case .info: return HavenColors.info
        case .salmon: return HavenColors.actionPressed
        case .indigo: return HavenColors.navy
        case .neutral: return HavenColors.textSecondary
        }
    }

    private var background: Color {
        switch tone {
        case .success: return HavenColors.success.opacity(0.12)
        case .warning: return HavenColors.warning.opacity(0.12)
        case .critical: return HavenColors.critical.opacity(0.12)
        case .info: return HavenColors.info.opacity(0.12)
        case .salmon: return HavenColors.actionPale
        case .indigo: return HavenColors.indigo50
        case .neutral: return HavenColors.beige200
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HavenPill(label: "On track", tone: .success)
        HavenPill(label: "Due soon", tone: .warning)
        HavenPill(label: "Overdue", tone: .critical)
        HavenPill(label: "New", tone: .info)
        HavenPill(label: "Routine", tone: .salmon)
        HavenPill(label: "12 covered", tone: .indigo)
        HavenPill(label: "Archived", tone: .neutral)
        HavenPill(label: "Verified", tone: .success, icon: "checkmark")
    }
    .padding()
    .background(HavenColors.background)
}
