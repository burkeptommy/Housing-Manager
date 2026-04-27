import SwiftUI

/// V5 Tasks tab — the top-level destination at `MainTabView` index 2.
/// Switches between Maintenance and Handyman screens via a serif
/// title-switcher chevron in the header (no segmented control).
///
/// Last-used mode persists via `@AppStorage` so returning users land
/// where they left off. Per-property maintenance flows are unchanged —
/// `PropertyDetailView` still pushes `MaintenanceHubView(filterPropertyId:)`
/// for the property-scoped lobby; `MaintenanceScheduleView` remains the
/// "See all" deep-dive surface that V5's section ArrowLinks push into.
enum TasksHubSection: String, CaseIterable, Identifiable {
    case maintenance
    case handyman

    var id: String { rawValue }

    var label: String {
        switch self {
        case .maintenance: return "Maintenance"
        case .handyman: return "Handyman"
        }
    }
}

struct TasksHubView: View {
    @AppStorage("tasksHubMode") private var rawMode: String = TasksHubSection.maintenance.rawValue
    @State private var showSwitcherSheet = false

    private var mode: TasksHubSection {
        TasksHubSection(rawValue: rawMode) ?? .maintenance
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .maintenance:
                    MaintenanceTabView(onSwitchMode: { showSwitcherSheet = true })
                        .transition(.opacity)
                case .handyman:
                    HandymanTabView(onSwitchMode: { showSwitcherSheet = true })
                        .transition(.opacity)
                }
            }
            .background(HavenColors.background)
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)        // HeaderSwitcher owns the top inset
        }
        .confirmationDialog(
            "Switch tab",
            isPresented: $showSwitcherSheet,
            titleVisibility: .hidden
        ) {
            Button("Maintenance") { setMode(.maintenance) }
            Button("Handyman")    { setMode(.handyman) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose the surface you want.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
            if let tab = notification.userInfo?["tab"] as? Int, tab == 2 {
                setMode(.maintenance)
            }
        }
    }

    private func setMode(_ next: TasksHubSection) {
        guard mode != next else { return }
        Haptics.selection()
        Analytics.track(.tabSelected, [
            "tab": "tasks",
            "section": next.rawValue
        ])
        withAnimation(.easeInOut(duration: 0.2)) {
            rawMode = next.rawValue
        }
    }
}
