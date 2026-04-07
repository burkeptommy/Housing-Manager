import SwiftUI

/// Uniform task card used across dashboard, maintenance list, and member profiles.
/// Shows: category icon, title (2 lines), location tag, assignee with avatar color, vendor, priority, date.
struct UnifiedTaskCard: View {
    let task: MaintenanceTaskDBRow
    var propertyName: String?
    var vehicleName: String?
    var systemName: String?
    var assigneeName: String?
    var assigneeAvatarColor: AvatarColor?
    var contractorName: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var isOverdue: Bool {
        guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
        return date < Date()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left: category icon
            Image(systemName: MaintenanceTaskIcon.icon(for: task))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.navy700)
                .frame(width: 32, height: 32)
                .background((isOverdue ? HavenColors.critical : HavenColors.navy700).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Center: title + metadata
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)

                // Location tag (property or vehicle)
                HStack(spacing: 6) {
                    if let vName = vehicleName, !vName.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 8))
                            Text(vName)
                        }
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.navy700)
                    } else if let pName = propertyName, !pName.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 8))
                            Text(pName)
                        }
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                    }

                    if let sName = systemName, !sName.isEmpty {
                        Text("\u{00B7}")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(sName)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                // Assignee + vendor row
                HStack(spacing: 8) {
                    if let name = assigneeName, !name.isEmpty {
                        let color = (assigneeAvatarColor ?? .navy).color
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                            Text(name)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    if let vendor = contractorName, !vendor.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 9))
                            Text(vendor)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(HavenColors.info)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(HavenColors.info.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer(minLength: 4)

            // Right: priority + date
            VStack(alignment: .trailing, spacing: 4) {
                if let priority = task.priority, !priority.isEmpty {
                    Text(priority.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(priorityColor(priority))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(priority).opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(task.nextDueDate.havenDateShort)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border.opacity(isOverdue ? 0.6 : 0.3), lineWidth: 0.5)
        }
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return HavenColors.critical
        case "medium": return HavenColors.warning
        case "low": return Color(red: 0.40, green: 0.55, blue: 0.42)
        default: return HavenColors.textTertiary
        }
    }
}
