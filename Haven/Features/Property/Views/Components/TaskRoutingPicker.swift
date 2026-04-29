import SwiftUI

/// Phase 64: Unified routing picker surfaced on every task that needs a
/// routing decision. Renders in one of four modes based on the task's
/// bucket classification (derived from the template's `TaskRouting`
/// plus `safetyFloor` flag) and an active-contract override.
///
/// Buckets:
///  - `.vendorOnly`        → Bucket 1. Single "Find a vendor" option.
///  - `.vendorOrHandymanOrDIY` → Bucket 2. Three options (vendor / handyman / DIY).
///  - `.handymanOrDIY`     → Bucket 3. Two options (handyman / DIY).
///  - `.readOnly`          → Active service contract auto-routes; display only.
enum TaskRoutingMode {
    case vendorOnly
    case vendorOrHandymanOrDIY
    case handymanOrDIY
    case readOnly
}

enum TaskAssignedRoute: String {
    case vendor, handyman, diy
}

struct TaskRoutingPicker: View {
    let mode: TaskRoutingMode
    let currentRoute: TaskAssignedRoute?
    let safetyFloor: Bool
    let assignedVendorName: String?
    let preferredHandymanName: String?

    var onSelectVendor: () -> Void
    var onSelectHandyman: () -> Void
    var onSelectDIY: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("WHO SHOULD HANDLE THIS?")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            switch mode {
            case .readOnly:
                autoRoutedNotice
            case .vendorOnly:
                vendorButton(isPrimary: true)
            case .vendorOrHandymanOrDIY:
                VStack(spacing: HavenTheme.spacing8) {
                    vendorButton(isPrimary: currentRoute == .vendor)
                    handymanButton(isPrimary: currentRoute == .handyman)
                    if !safetyFloor {
                        diyButton(isPrimary: currentRoute == .diy)
                    }
                }
            case .handymanOrDIY:
                VStack(spacing: HavenTheme.spacing8) {
                    handymanButton(isPrimary: currentRoute == .handyman)
                    if !safetyFloor {
                        diyButton(isPrimary: currentRoute == .diy)
                    }
                }
            }
        }
    }

    private var autoRoutedNotice: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HavenColors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Scheduled with \(assignedVendorName ?? "your vendor")")
                    .font(HavenTypography.body)
                Text("Based on your service contract")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func vendorButton(isPrimary: Bool) -> some View {
        routeButton(
            label: "Find a vendor",
            icon: "person.fill.checkmark",
            subtitle: "Chez will help you book the right pro",
            isPrimary: isPrimary,
            action: onSelectVendor
        )
    }

    private func handymanButton(isPrimary: Bool) -> some View {
        let subtitle = preferredHandymanName.map { "Add to \($0)'s next visit" }
            ?? "Add to your handyman list"
        return routeButton(
            label: "Add to handyman visit",
            icon: "wrench.adjustable.fill",
            subtitle: subtitle,
            isPrimary: isPrimary,
            action: onSelectHandyman
        )
    }

    private func diyButton(isPrimary: Bool) -> some View {
        routeButton(
            label: "I'll handle it myself",
            icon: "hand.raised.fill",
            subtitle: "We'll add it to your personal list",
            isPrimary: isPrimary,
            action: onSelectDIY
        )
    }

    private func routeButton(
        label: String,
        icon: String,
        subtitle: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isPrimary ? HavenColors.textOnNavy : HavenColors.navy700)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.body)
                        .foregroundStyle(isPrimary ? HavenColors.textOnNavy : HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(isPrimary ? HavenColors.textOnNavy.opacity(0.9) : HavenColors.textSecondary)
                }
                Spacer()
                if isPrimary {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(HavenColors.textOnNavy)
                }
            }
            .padding(HavenTheme.spacing12)
            .background(isPrimary ? HavenColors.navy800 : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(isPrimary ? Color.clear : HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Derivation helpers

extension TaskRoutingMode {
    /// Maps a template's routing hint + safetyFloor + active-contract into
    /// the picker mode. Bucket 1 (`.vendorOnly`) wins regardless of other
    /// signals. Active contracts collapse everything to `.readOnly`.
    static func derive(
        templateRouting: TaskRouting?,
        safetyFloor: Bool,
        hasActiveContract: Bool
    ) -> TaskRoutingMode {
        if hasActiveContract { return .readOnly }
        if templateRouting == .vendorOnly || safetyFloor { return .vendorOnly }
        switch templateRouting {
        case .diyDefault:
            return .handymanOrDIY
        case .diyCapable, .vendorDefault, .some(.bundledIntoParent), .none:
            return .vendorOrHandymanOrDIY
        case .vendorOnly:
            return .vendorOnly
        }
    }
}
