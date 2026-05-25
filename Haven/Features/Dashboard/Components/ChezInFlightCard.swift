import SwiftUI

/// Phase 70.A1 follow-on K2 — Dashboard card surfacing in-flight Chez
/// requests (open or waiting on customer). Tom's ask: "make sure the
/// homeowner can easily see where the chez managed tasks are so they
/// can review them easily, and easily chat about them."
///
/// Sits above `ChezActivityCard` (which is a backward-looking "this
/// week with Chez" digest). This card is forward-looking — "Chez is
/// currently working on N things, tap any of them to chat right now."
///
/// Hidden when there are no in-flight requests, so DIY-default users
/// never see it. Cap at 5 visible rows with a "View all in Inbox"
/// link routing to the Inbox → Chez sub-tab.
struct ChezInFlightCard: View {
    let requests: [ChezRequestRow]
    var onTapRequest: (ChezRequestRow) -> Void
    var onViewAll: () -> Void

    private static let visibleCap = 5

    var body: some View {
        guardEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                header
                ForEach(requests.prefix(Self.visibleCap)) { request in
                    requestRow(request)
                }
                if requests.count > Self.visibleCap {
                    viewAllLink
                }
            }
            .padding(HavenTheme.spacing16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.action.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: "person.fill.checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Chez is working on \(requests.count) \(requests.count == 1 ? "thing" : "things")")
                    .font(HavenTypography.title3)
                    .foregroundColor(HavenColors.textPrimary)
                    .lineLimit(1)
                Text("Tap to chat or see updates")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundColor(HavenColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func requestRow(_ request: ChezRequestRow) -> some View {
        Button {
            Haptics.selection()
            onTapRequest(request)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: request.typedCategory.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.navy700)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(HavenColors.navy.opacity(0.08))
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(request.summary)
                        .font(HavenTypography.body)
                        .foregroundColor(HavenColors.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    Text(request.homeownerSlaCaption)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundColor(statusColor(request))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if request.unreadForUser {
                    Circle()
                        .fill(HavenColors.action)
                        .frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(request.typedCategory.displayName): \(request.summary). \(request.homeownerSlaCaption).")
        .accessibilityHint("Open the conversation with Chez.")
    }

    private func statusColor(_ request: ChezRequestRow) -> Color {
        switch request.typedStatus {
        case .waitingCustomer: return HavenColors.action  // needs your attention
        case .open:            return HavenColors.textSecondary
        case .resolved:        return HavenColors.success
        }
    }

    private var viewAllLink: some View {
        Button {
            Haptics.selection()
            onViewAll()
        } label: {
            HStack(spacing: 4) {
                Text("View all \(requests.count) in Inbox")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(HavenColors.action)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                HavenColors.action.opacity(0.06),
                HavenColors.action.opacity(0.02),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func guardEmpty<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if requests.isEmpty {
            EmptyView()
        } else {
            content()
        }
    }
}
