import SwiftUI

// MARK: - Role Icon + Gender Badge System

/// Returns the primary large icon and role badge for a family member based on relationship, age, and gender.
struct AvatarStyle {
    let icon: String        // Large center icon
    let badge: String?      // Small corner badge (relationship indicator)
    let defaultColor: AvatarColor

    /// Determine avatar style from member data.
    static func from(relationship: String, dateOfBirth: String?, gender: String?, isExpecting: Bool?) -> AvatarStyle {
        if isExpecting == true {
            return AvatarStyle(icon: "stroller.fill", badge: "heart.fill", defaultColor: .rose)
        }

        let isFemale = gender?.lowercased() == "female"
        let age = Self.computeAge(dateOfBirth)

        switch relationship.lowercased() {
        case "primary client":
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "star.fill",
                defaultColor: .navy
            )
        case "spouse/partner", "spouse", "partner":
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "heart.fill",
                defaultColor: .sage
            )
        case "child":
            return childStyle(age: age, isFemale: isFemale)
        case "grandchild":
            return grandchildStyle(age: age, isFemale: isFemale)
        case "parent":
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "house.fill",
                defaultColor: .amber
            )
        case "sibling":
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "person.2.fill",
                defaultColor: .teal
            )
        case "guardian":
            return AvatarStyle(
                icon: "checkmark.shield.fill",
                badge: nil,
                defaultColor: .slate
            )
        case "trustee":
            return AvatarStyle(
                icon: "building.columns.fill",
                badge: nil,
                defaultColor: .plum
            )
        case "executor":
            return AvatarStyle(
                icon: "doc.text.fill",
                badge: "checkmark.seal.fill",
                defaultColor: .coral
            )
        case "beneficiary":
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "gift.fill",
                defaultColor: .rose
            )
        default:
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: nil,
                defaultColor: .navy
            )
        }
    }

    private static func childStyle(age: Int?, isFemale: Bool) -> AvatarStyle {
        guard let age else {
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "figure.child",
                defaultColor: .coral
            )
        }
        if age <= 2 {
            // Infant
            return AvatarStyle(
                icon: "face.smiling.inverse",
                badge: isFemale ? "heart.circle.fill" : nil,
                defaultColor: isFemale ? .rose : .teal
            )
        } else if age <= 12 {
            // Kid
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "figure.child",
                defaultColor: isFemale ? .coral : .amber
            )
        } else {
            // Teen
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "graduationcap.fill",
                defaultColor: isFemale ? .plum : .teal
            )
        }
    }

    private static func grandchildStyle(age: Int?, isFemale: Bool) -> AvatarStyle {
        guard let age else {
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "sparkle",
                defaultColor: .amber
            )
        }
        if age <= 2 {
            return AvatarStyle(icon: "face.smiling.inverse", badge: "sparkle", defaultColor: isFemale ? .rose : .teal)
        } else {
            return AvatarStyle(
                icon: isFemale ? "person.crop.circle.fill" : "person.crop.square.fill",
                badge: "sparkle",
                defaultColor: .amber
            )
        }
    }

    private static func computeAge(_ dateOfBirth: String?) -> Int? {
        guard let dobStr = dateOfBirth else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dob = formatter.date(from: dobStr) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}

// MARK: - Gender Indicator

struct GenderBadge: View {
    let gender: String?
    let size: CGFloat

    var body: some View {
        if let g = gender?.lowercased(), g == "male" || g == "female" {
            Image(systemName: g == "female" ? "circle.fill" : "square.fill")
                .font(.system(size: size * 0.16, weight: .bold))
                .foregroundStyle(g == "female" ? Color(red: 0.85, green: 0.45, blue: 0.55) : Color(red: 0.35, green: 0.50, blue: 0.72))
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.24, height: size * 0.24)
                )
                .offset(x: size * 0.35, y: size * 0.35)
        }
    }
}

// MARK: - Avatar Colors

/// The available avatar accent colors users can pick from.
enum AvatarColor: String, CaseIterable, Identifiable {
    case navy = "navy"
    case sage = "sage"
    case coral = "coral"
    case plum = "plum"
    case amber = "amber"
    case teal = "teal"
    case rose = "rose"
    case slate = "slate"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .navy:  return Color(red: 0.106, green: 0.165, blue: 0.290)
        case .sage:  return Color(red: 0.40, green: 0.55, blue: 0.42)
        case .coral: return Color(red: 0.85, green: 0.45, blue: 0.35)
        case .plum:  return Color(red: 0.55, green: 0.35, blue: 0.55)
        case .amber: return Color(red: 0.80, green: 0.60, blue: 0.25)
        case .teal:  return Color(red: 0.20, green: 0.55, blue: 0.55)
        case .rose:  return Color(red: 0.78, green: 0.40, blue: 0.50)
        case .slate: return Color(red: 0.45, green: 0.48, blue: 0.52)
        }
    }

    var lightBackground: Color { color.opacity(0.12) }
}

// MARK: - The Avatar View

/// Reusable family member avatar — relationship-aware, gender-aware, with role badge.
struct FamilyAvatarView: View {
    let member: FamilyMemberRow
    var size: CGFloat = 64
    var showName: Bool = true
    var isSelected: Bool = false

    private var style: AvatarStyle {
        AvatarStyle.from(
            relationship: member.relationship,
            dateOfBirth: member.dateOfBirth,
            gender: member.gender,
            isExpecting: member.isExpecting
        )
    }

    private var accentColor: Color {
        if let key = member.avatarColor, let c = AvatarColor(rawValue: key) {
            return c.color
        }
        return style.defaultColor.color
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isSelected ? accentColor : accentColor.opacity(0.12))
                    .frame(width: size, height: size)

                // Border ring
                Circle()
                    .stroke(accentColor, lineWidth: isSelected ? 3 : 2)
                    .frame(width: size, height: size)

                // Main icon (large, face-level)
                Image(systemName: style.icon)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(isSelected ? .white : accentColor)

                // Role badge (top-right corner)
                if let badge = style.badge {
                    Image(systemName: badge)
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(size * 0.06)
                        .background(
                            Circle()
                                .fill(accentColor)
                                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                        )
                        .offset(x: size * 0.33, y: size * -0.33)
                }

                // Gender indicator (bottom-right, subtle)
                GenderBadge(gender: member.gender, size: size)
            }

            if showName {
                Text(member.firstName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? accentColor : HavenColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: size + 12)
    }
}

// MARK: - Standalone Avatar Preview (for forms without a FamilyMemberRow)

struct AvatarPreview: View {
    let relationship: String
    let gender: String
    let dateOfBirth: String?
    let isExpecting: Bool
    let avatarColor: AvatarColor
    var size: CGFloat = 88

    private var style: AvatarStyle {
        AvatarStyle.from(relationship: relationship, dateOfBirth: dateOfBirth, gender: gender, isExpecting: isExpecting)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor.color.opacity(0.12))
                .frame(width: size, height: size)
            Circle()
                .stroke(avatarColor.color, lineWidth: 3)
                .frame(width: size, height: size)
            Image(systemName: style.icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(avatarColor.color)

            if let badge = style.badge {
                Image(systemName: badge)
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(size * 0.06)
                    .background(Circle().fill(avatarColor.color))
                    .offset(x: size * 0.33, y: size * -0.33)
            }

            GenderBadge(gender: gender, size: size)
        }
    }
}
