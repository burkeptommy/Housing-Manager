import SwiftUI

/// Compact card for a single fiduciary role. Two variants:
///   - **Filled**: role icon + name + Primary/Alternate badge + source pill
///   - **Ghost**: unfilled role with "+" to nominate
struct FiduciaryRoleCard: View {
    let role: String
    let fiduciary: EstateFiduciary?
    var onTap: (() -> Void)?
    var onNominate: (() -> Void)?

    var body: some View {
        if let fid = fiduciary {
            filledCard(fid)
        } else {
            ghostCard
        }
    }

    // MARK: - Filled Card

    private func filledCard(_ fid: EstateFiduciary) -> some View {
        Button {
            Haptics.light()
            onTap?()
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.navy.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: Self.icon(for: role))
                        .font(.system(size: 16))
                        .foregroundStyle(HavenColors.navy700)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(fid.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)

                        if fid.isAlternate == true {
                            Text("Alternate")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.textOnNavy)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.navy700)
                                .clipShape(Capsule())
                        } else {
                            Text("Primary")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text(Self.displayRole(role))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        sourcePill(fid.source)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(HavenButtonPressStyle())
    }

    // MARK: - Ghost Card

    private var ghostCard: some View {
        Button {
            Haptics.light()
            onNominate?()
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                ZStack {
                    Circle()
                        .stroke(HavenColors.beige300, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.displayRole(role))
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("Tap to nominate")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Spacer()
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            }
        }
        .buttonStyle(HavenButtonPressStyle())
    }

    // MARK: - Source Pill

    private func sourcePill(_ source: String) -> some View {
        let label: String = switch source {
        case "from_will": "From your Will"
        case "from_trust": "From your Trust"
        case "from_poa": "From your POA"
        case "from_health_proxy": "From your Health Proxy"
        case "user_nomination": "Your nomination"
        default: source.replacingOccurrences(of: "_", with: " ").capitalized
        }

        return Text(label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(HavenColors.textTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
    }

    // MARK: - Static Helpers

    /// SF Symbol icon for a fiduciary role key.
    static func icon(for role: String) -> String {
        switch role {
        case "executor": return "person.crop.circle.badge.checkmark"
        case "trustee": return "building.columns"
        case "guardian": return "figure.and.child.holdinghands"
        case "health_proxy": return "heart.text.square"
        case "poa_agent": return "hand.raised"
        case "disposition_agent": return "leaf"
        case "successor_trustee": return "building.columns.fill"
        default: return "person.circle"
        }
    }

    /// Human-readable display name for a fiduciary role key.
    static func displayRole(_ role: String) -> String {
        switch role {
        case "executor": return "Executor"
        case "trustee": return "Trustee"
        case "guardian": return "Guardian"
        case "health_proxy": return "Healthcare Proxy"
        case "poa_agent": return "POA Agent"
        case "disposition_agent": return "Disposition Agent"
        case "successor_trustee": return "Successor Trustee"
        default: return role.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
