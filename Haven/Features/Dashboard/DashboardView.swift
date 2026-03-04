import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing16) {
                    if viewModel.isLoading && !hasAppeared {
                        // Skeleton loading state
                        SkeletonScorecard()
                        SkeletonCard(lineCount: 2)
                        SkeletonCard(lineCount: 3)
                    } else {
                        CompletionScorecard(
                            overallReadiness: viewModel.overallReadiness,
                            categoryScores: viewModel.categoryScores
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))

                        QuickActions()

                        if !viewModel.upcomingExpirations.isEmpty {
                            UpcomingExpirations(items: viewModel.upcomingExpirations)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        if !viewModel.overdueMaintenanceTasks.isEmpty {
                            OverdueMaintenanceCard(tasks: viewModel.overdueMaintenanceTasks)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        RecentActivityFeed(documents: viewModel.recentDocuments)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.top, HavenTheme.spacing8)
                .padding(.bottom, HavenTheme.spacing32)
                .animation(HavenTheme.animationStandard, value: viewModel.isLoading)
            }
            .background(HavenColors.background)
            .navigationTitle("Haven")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Open app settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(appState)
                }
            }
            .refreshable {
                Haptics.light()
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
                hasAppeared = true
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
