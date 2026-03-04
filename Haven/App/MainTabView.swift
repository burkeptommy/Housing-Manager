import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(appState)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            DocumentVaultView()
                .tabItem {
                    Label("Documents", systemImage: "folder.fill")
                }
                .tag(1)

            PropertyListView()
                .tabItem {
                    Label("Properties", systemImage: "building.2.fill")
                }
                .tag(2)

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.text.bubble.right.fill")
                }
                .tag(3)
        }
        .tint(Color.havenAccent)
        .onChange(of: selectedTab) { _, _ in
            Haptics.selection()
        }
    }
}
