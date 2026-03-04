import SwiftUI

/// Consistent error state with icon, message, and retry button.
struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.havenCritical)
                .accessibilityHidden(true)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Something Went Wrong")
                    .font(HavenTypography.title3)

                Text(message)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing32)
            }

            if let retryAction {
                HavenButton(
                    title: "Try Again",
                    action: {
                        Haptics.medium()
                        retryAction()
                    },
                    style: .secondary,
                    icon: "arrow.clockwise"
                )
                .padding(.horizontal, HavenTheme.spacing48)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#Preview {
    ErrorView(message: "Unable to load your documents. Check your connection and try again.", retryAction: {})
}
