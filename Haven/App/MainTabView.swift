import SwiftUI

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let openScenarioStudio = Notification.Name("openScenarioStudio")
    static let openAlfredWithContext = Notification.Name("openAlfredWithContext")
    static let popToRoot = Notification.Name("popToRoot")

    // Cross-tab data sync notifications
    static let maintenanceTaskChanged = Notification.Name("maintenanceTaskChanged")
    static let homeSystemChanged = Notification.Name("homeSystemChanged")
    static let contractorChanged = Notification.Name("contractorChanged")
    static let documentChanged = Notification.Name("documentChanged")
    static let propertyChanged = Notification.Name("propertyChanged")
    static let projectChanged = Notification.Name("projectChanged")
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showScenarioStudio = false
    @State private var scenarioInitialQuery: String?
    @State private var isKeyboardVisible = false
    @AppStorage("hasUsedScenarioStudio") private var hasUsedScenarioStudio = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Processing banner — visible across all tabs
                ProcessingBanner()

                TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(appState)
                    .tag(0)

                PropertyListView()
                    .tag(1)

                DocumentVaultView()
                    .tag(2)

                ChatView()
                    .tag(3)
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                customTabBar
            }
            } // end VStack

            // Floating "What If?" button
            if !isKeyboardVisible && !showScenarioStudio && selectedTab != 3 {
                Button {
                    Haptics.medium()
                    hasUsedScenarioStudio = true
                    showScenarioStudio = true
                    Analytics.track(.scenarioStudioOpened, ["source": "floating_button"])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .medium))
                        if !hasUsedScenarioStudio {
                            Text("Scenarios")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(HavenColors.cream)
                    .padding(.horizontal, hasUsedScenarioStudio ? 15 : 16)
                    .padding(.vertical, hasUsedScenarioStudio ? 15 : 12)
                    .background(HavenColors.navy800)
                    .clipShape(Capsule())
                    .shadow(color: HavenColors.navy800.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(hasUsedScenarioStudio ? 1.0 : pulseScale)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 72)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Scenario Planning")
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, newTab in
            Haptics.selection()
            let tabNames = ["Dashboard", "Property", "Life", "Alfred"]
            let name = newTab < tabNames.count ? tabNames[newTab] : "Unknown"
            Analytics.track(.tabSelected, ["tab": name, "tab_index": newTab])
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.userInfo?["tab"] as? Int {
                selectedTab = tab
                // Also pop to root on the target tab to clear any stale navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tab])
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAlfredWithContext)) { notification in
            // Switch to Alfred tab when "Ask Alfred about this project" is tapped
            selectedTab = 3
        }
        .onReceive(NotificationCenter.default.publisher(for: .openScenarioStudio)) { notification in
            if let query = notification.userInfo?["query"] as? String {
                scenarioInitialQuery = query
            }
            showScenarioStudio = true
        }
        .fullScreenCover(isPresented: $showScenarioStudio) {
            scenarioInitialQuery = nil
        } content: {
            ScenarioStudioView(initialQuery: scenarioInitialQuery)
        }
        .onAppear {
            startPulse()
        }
    }

    // Pulse animation for first-time discovery
    @State private var pulseScale: CGFloat = 1.0

    private func startPulse() {
        guard !hasUsedScenarioStudio else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "square.grid.2x2.fill", label: "Dashboard", tag: 0)
            tabButton(icon: "building.columns.fill", label: "Property", tag: 1)
            tabButton(icon: "heart.text.square.fill", label: "Life", tag: 2)
            alfredTabButton
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            HavenColors.creamLight
                .shadow(color: HavenColors.beige300.opacity(0.5), radius: 4, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            if selectedTab == tag {
                NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tag])
            } else {
                selectedTab = tag
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": tag])
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(height: 22)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .medium))
            }
            .foregroundStyle(selectedTab == tag ? HavenColors.navy800 : Color(red: 0.71, green: 0.69, blue: 0.65))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // Alfred gets a branded monogram icon
    private var alfredTabButton: some View {
        Button {
            if selectedTab == 3 {
                NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": 3])
            } else {
                selectedTab = 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": 3])
                }
            }
        } label: {
            VStack(spacing: 3) {
                alfredIcon
                    .frame(height: 22)
                Text("Alfred")
                    .font(.system(size: 10, weight: selectedTab == 3 ? .semibold : .medium))
            }
            .foregroundStyle(selectedTab == 3 ? HavenColors.navy800 : Color(red: 0.71, green: 0.69, blue: 0.65))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Alfred")
    }

    private var alfredIcon: some View {
        ZStack {
            Circle()
                .fill(selectedTab == 3 ? HavenColors.navy800 : Color(red: 0.71, green: 0.69, blue: 0.65))
                .frame(width: 22, height: 22)
            Text("A")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(HavenColors.creamLight)
        }
    }
}
