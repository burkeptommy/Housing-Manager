import SwiftUI

struct SecuritySettingsView: View {
    @State private var biometricEnabled = false

    var body: some View {
        Form {
            Section("Authentication") {
                Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
            }
            Section("Data") {
                Button("Change Password") { }
                Button("Export My Data") { }
            }
        }
        .navigationTitle("Security")
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
    }
}
