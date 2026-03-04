import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Haven Premium")
                .font(.title.bold())
            Text("Subscription management coming soon")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Subscription")
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
