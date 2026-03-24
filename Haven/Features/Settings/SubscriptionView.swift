import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Haven Premium")
                .font(HavenTypography.title)
            Text("Subscription management coming soon")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding()
        .navigationTitle("Subscription")
        .trackScreen("SubscriptionView")
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
