import SwiftUI

struct ProfileView: View {
    var body: some View {
        Form {
            Section("Account") {
                Text("Profile settings coming soon")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
