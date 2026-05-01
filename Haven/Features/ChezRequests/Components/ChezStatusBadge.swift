import SwiftUI

/// Phase 80 — Status pill for a Chez request. Three states with their
/// own tones so the homeowner reads "where am I in the workflow"
/// without studying copy.
struct ChezStatusBadge: View {
    let status: ChezStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(backgroundColor)
        )
    }

    private var dotColor: Color {
        switch status {
        case .open: return HavenColors.action
        case .waitingCustomer: return Color.orange
        case .resolved: return HavenColors.success
        }
    }

    private var textColor: Color {
        switch status {
        case .open: return HavenColors.action
        case .waitingCustomer: return Color.orange
        case .resolved: return HavenColors.success
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .open: return HavenColors.action.opacity(0.12)
        case .waitingCustomer: return Color.orange.opacity(0.12)
        case .resolved: return HavenColors.success.opacity(0.14)
        }
    }
}
