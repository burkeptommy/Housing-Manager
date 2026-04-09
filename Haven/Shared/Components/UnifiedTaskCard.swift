import SwiftUI

/// Phase 19l: Variant the card renders based on task.assignmentType,
/// task.needsVendor, and task.assignedContractorId. Three modes:
///
///   - `.personal`: User does it themselves. Shows the existing layout
///     plus an effort badge (when the matched template has diyEffortMinutes)
///     and a "Have someone else do it →" delegate footer.
///
///   - `.vendorManaged`: A contractor handles the work. Shows vendor logo,
///     reframed title, vendor name, no effort badge, no assignee pill.
///
///   - `.findContractor`: Vendor task with no contractor on file. Shows an
///     orange "needs vendor" icon, find-a-contractor title, and a "Find →"
///     CTA that opens the local vendor sheet (Phase 19n) or the manual
///     contractor add flow as a stub for now.
private enum UnifiedTaskCardVariant {
    case personal
    case vendorManaged
    case findContractor
}

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

    /// Phase 19l: Optional full contractor row for the vendor-managed variant.
    /// When present, the card renders the contractor's logo + brand color
    /// alongside the company name. Falls back to a navy initial avatar.
    var contractor: ContractorRow?

    /// Phase 19l: Tap handler for the personal-card "Have someone else do it →"
    /// footer. When nil, the footer is hidden so the card stays clean for
    /// surfaces that don't support delegation (e.g. dashboard).
    var onDelegate: (() -> Void)?

    /// Phase 19l: Tap handler for the find-a-contractor "Find →" CTA. When
    /// nil, the variant still renders but the button does nothing (the row's
    /// outer Button is what actually navigates to the picker — see
    /// MaintenanceScheduleView).
    var onFindVendor: (() -> Void)?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var isOverdue: Bool {
        guard let date = dateFormatter.date(from: task.nextDueDate) else { return false }
        return date < Date()
    }

    /// Phase 19l: Decide which variant the row renders.
    private var variant: UnifiedTaskCardVariant {
        let assignment = task.assignmentType?.lowercased()
        if assignment == "vendor" {
            if task.needsVendor == true || task.assignedContractorId == nil {
                return .findContractor
            }
            return .vendorManaged
        }
        // "personal", "either", or nil/legacy → personal layout
        return .personal
    }

    /// Phase 19l: Look up the underlying template for effort badges and the
    /// canonical title. The card never re-derives wording — that's the
    /// reconciler/viewmodel's job — but it does need diyEffortMinutes and
    /// diyEffortLabel which only live on the template definition.
    private var matchedTemplate: MaintenanceTemplate? {
        guard let key = task.templateId else { return nil }
        return MaintenanceTemplates.template(forKey: key)
    }

    var body: some View {
        switch variant {
        case .personal:
            personalCard
        case .vendorManaged:
            vendorManagedCard
        case .findContractor:
            findContractorCard
        }
    }

    // MARK: - Personal Variant

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
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

                    // Phase 19l: effort badge under the title when the template
                    // has a diyEffortMinutes value. Vendor cards never show this.
                    if let minutes = matchedTemplate?.diyEffortMinutes {
                        HStack(spacing: 6) {
                            effortBadge(minutes: minutes)
                            if let effortLabel = matchedTemplate?.diyEffortLabel {
                                Text(effortLabel)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    locationTagRow

                    assigneeAndVendorRow
                }

                Spacer(minLength: 4)

                // Right: priority + date
                rightColumn
            }

            // Phase 19l: footer link to delegate to a vendor.
            if onDelegate != nil {
                Divider()
                    .overlay(HavenColors.beige200)
                    .padding(.top, HavenTheme.spacing12)

                Button {
                    Haptics.light()
                    onDelegate?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Have someone else do it")
                            .font(HavenTypography.uiLabel)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.top, HavenTheme.spacing8)
                }
                .buttonStyle(.plain)
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

    // MARK: - Vendor-Managed Variant

    private var vendorManagedCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: vendor logo (or initial fallback) — replaces the category icon
            vendorLogo
                .frame(width: 40, height: 40)

            // Center: reframed title + vendor subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)

                let vendorName = contractor?.companyName ?? contractorName ?? "Your vendor"
                HStack(spacing: 6) {
                    Text(vendorName)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                    if let cost = task.costRange, !cost.isEmpty {
                        Text("\u{00B7}")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(cost)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                locationTagRow
            }

            Spacer(minLength: 4)

            rightColumn
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border.opacity(isOverdue ? 0.6 : 0.3), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var vendorLogo: some View {
        let initial = String((contractor?.companyName ?? contractorName ?? "?").prefix(1)).uppercased()
        let brandColor: Color = {
            if let hex = contractor?.brandColor, !hex.isEmpty {
                return Color(hex: hex)
            }
            return HavenColors.navy
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(brandColor.opacity(0.12))
            if let urlString = contractor?.logoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(5)
                    default:
                        Text(initial)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(brandColor)
                    }
                }
            } else {
                Text(initial)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(brandColor)
            }
        }
    }

    // MARK: - Find-a-Contractor Variant

    private var findContractorCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: warning icon
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(HavenColors.warning)
                .frame(width: 32, height: 32)
                .background(HavenColors.warning.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Center: title + subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)

                Text("No vendor yet. We'll find you a vetted pro.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(2)

                locationTagRow
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    Haptics.light()
                    onFindVendor?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Find")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(HavenColors.warning)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

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
                .strokeBorder(HavenColors.warning.opacity(0.4), lineWidth: 0.75)
        }
    }

    // MARK: - Shared Subviews

    private var locationTagRow: some View {
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
    }

    private var assigneeAndVendorRow: some View {
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

    private var rightColumn: some View {
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

    // MARK: - Effort Badge

    /// Phase 19l: render minutes as "X min" / "1 hr" / "X hr Y min" so a
    /// 5-minute filter swap reads "5 min" and a 90-minute pool drain reads
    /// "1 hr 30 min". Vendor cards never show this badge.
    private func effortBadge(minutes: Int) -> some View {
        let label: String = {
            if minutes < 60 { return "\(minutes) min" }
            let hours = minutes / 60
            let remainder = minutes % 60
            if remainder == 0 {
                return hours == 1 ? "1 hr" : "\(hours) hr"
            }
            return "\(hours) hr \(remainder) min"
        }()
        return Text(label)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
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
