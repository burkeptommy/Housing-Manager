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
    /// Phase 19l: Posted when a NEW contractor is created (not edited).
    /// Listeners use this to re-fire the post-quiz delegation sheet for any
    /// 'either' tasks that the new vendor's category could take over.
    /// `userInfo["contractorId"]` carries the new row's UUID.
    static let contractorAdded = Notification.Name("contractorAdded")
    static let advisorChanged = Notification.Name("advisorChanged")
    static let documentChanged = Notification.Name("documentChanged")
    static let propertyChanged = Notification.Name("propertyChanged")
    static let projectChanged = Notification.Name("projectChanged")
    /// Phase 51: Posted when a standing appointment is created, updated, paused, or archived.
    static let standingAppointmentChanged = Notification.Name("standingAppointmentChanged")
    /// Phase 54E: Posted when a household cadence is created, updated, or deleted.
    /// Property and Maintenance surfaces listen for this to refresh count badges
    /// and virtual-occurrence rows without manual pull-to-refresh.
    static let householdCadenceChanged = Notification.Name("householdCadenceChanged")
    /// Phase 55: Posted when a routine is created, updated, archived, or deleted.
    /// Replaces `.householdCadenceChanged` once Section 55.3 repoints the last
    /// legacy writer; for 55.1/55.2 both names coexist so readers don't miss
    /// updates during the transition.
    static let routineChanged = Notification.Name("routineChanged")
    static let inboxItemUpdated = Notification.Name("inboxItemUpdated")
    static let navigateToVehicle = Notification.Name("navigateToVehicle")
    static let navigateToInboxItem = Notification.Name("navigateToInboxItem")
    static let navigateToPropertySection = Notification.Name("navigateToPropertySection")

    // Invite + onboarding
    static let inviteCodeReceived = Notification.Name("inviteCodeReceived")
    /// Posted by AddPropertyFlow's confirmation step when the user taps
    /// "Take House Quiz". `object` carries the new `PropertyRow`.
    static let startHouseQuiz = Notification.Name("startHouseQuiz")
    static let estateStateChanged = Notification.Name("estateStateChanged")

    /// Phase 50: Posted by `InvoiceProcessingViewModel` after it detects an
    /// explicit recurring service cadence on an invoice (>0.8 confidence).
    /// The Dashboard listens for this and renders a confirmation card so
    /// the user can accept the new interval and update the system row.
    static let invoiceCadenceDetected = Notification.Name("invoiceCadenceDetected")
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var uploadManager = DocumentUploadManager.shared
    @State private var selectedTab = 0
    @State private var showScenarioStudio = false
    @State private var scenarioInitialQuery: String?
    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Processing banner — visible across all tabs
                ProcessingBanner { documentId in
                    selectedTab = 0
                    NotificationCenter.default.post(
                        name: .navigateToInboxItem,
                        object: nil,
                        userInfo: ["documentId": documentId]
                    )
                }

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

            // (Floating "What If?" FAB removed — Scenarios now lives in
            // the Alfred tab toolbar, so the AI surface area is in one
            // place. ScenarioStudioView still presents from MainTabView
            // via the .openScenarioStudio notification path below.)
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
            // Switch to Alfred tab so scenarios always feel like they
            // live "in Alfred" — the FAB used to present from any tab
            // but the experience is now anchored on tab 3.
            selectedTab = 3
            showScenarioStudio = true
        }
        .fullScreenCover(isPresented: $showScenarioStudio) {
            scenarioInitialQuery = nil
        } content: {
            ScenarioStudioView(initialQuery: scenarioInitialQuery)
        }
        .sheet(isPresented: $uploadManager.showInvoiceChoiceSheet) {
            if let review = uploadManager.currentInvoiceReview {
                InvoiceChoiceSheet(review: review) {
                    uploadManager.dismissCurrentInvoiceReview()
                }
            }
        }
        .sheet(isPresented: $uploadManager.showDuplicateSheet) {
            if let resolution = uploadManager.currentDuplicateResolution {
                DuplicateResolutionSheet(resolution: resolution, manager: uploadManager)
            }
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
            .foregroundStyle(selectedTab == tag ? HavenColors.action : HavenColors.tabInactive)
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
            .foregroundStyle(selectedTab == 3 ? HavenColors.action : HavenColors.tabInactive)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Alfred")
    }

    private var alfredIcon: some View {
        ZStack {
            Circle()
                .fill(selectedTab == 3 ? HavenColors.action : HavenColors.tabInactive)
                .frame(width: 22, height: 22)
            Text("A")
                .font(HavenTypography.fraunces(size: 13, weight: 700))
                .foregroundStyle(HavenColors.creamLight)
        }
    }
}
