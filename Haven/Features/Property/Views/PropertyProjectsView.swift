import SwiftUI

/// Projects tab content inside PropertyDetailView.
struct PropertyProjectsView: View {
    let propertyID: UUID
    let householdId: UUID?
    @StateObject private var viewModel = ProjectsViewModel()
    @ObservedObject private var researchService = ProjectResearchService.shared
    @State private var showNewProject = false
    @State private var projectToDelete: PropertyProjectRow?

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            // Research in progress banner
            if researchService.isResearching {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(HavenColors.navy700)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Researching costs...")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy800)
                        if let name = researchService.pendingProjectName {
                            Text(name)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.navy.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }

            if viewModel.isLoading && viewModel.projects.isEmpty {
                SkeletonCard(lineCount: 2)
                SkeletonCard(lineCount: 2)
            } else if viewModel.projects.isEmpty {
                EmptyStateView(
                    title: "No projects yet",
                    message: "Plan your next renovation with AI-powered cost estimates.",
                    icon: "hammer.fill",
                    actionTitle: "Plan a Project",
                    action: { showNewProject = true }
                )
                .frame(minHeight: 300)
            } else {
                HavenButton(title: "Plan a Project", action: {
                    showNewProject = true
                }, icon: "plus")

                if !viewModel.activeProjects.isEmpty {
                    projectSection("ACTIVE", projects: viewModel.activeProjects)
                }
                if !viewModel.completedProjects.isEmpty {
                    projectSection("COMPLETED", projects: viewModel.completedProjects)
                }
                if !viewModel.onHoldProjects.isEmpty {
                    projectSection("ON HOLD", projects: viewModel.onHoldProjects)
                }
            }
        }
        .task {
            await viewModel.loadProjects(propertyId: propertyID)
        }
        .onReceive(researchService.$completedProjectId) { projectId in
            if projectId != nil {
                // Research finished — reload projects to get AI data
                Task { await viewModel.loadProjects(propertyId: propertyID) }
                researchService.clearResult()
            }
        }
        .sheet(isPresented: $showNewProject) {
            if let hhId = householdId {
                NewProjectView(propertyID: propertyID, householdId: hhId, viewModel: viewModel)
            }
        }
        .confirmationDialog("Delete Project?", isPresented: .init(
            get: { projectToDelete != nil },
            set: { if !$0 { projectToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let project = projectToDelete else { return }
                Task {
                    try? await viewModel.deleteProject(id: project.id)
                    Analytics.track(.propertyDeleted, ["project_id": project.id.uuidString])
                    Haptics.success()
                }
            }
        } message: {
            Text("This will delete the project and all its line items.")
        }
    }

    @ViewBuilder
    private func projectSection(_ title: String, projects: [PropertyProjectRow]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(projects) { project in
                NavigationLink {
                    ProjectDetailView(project: project, viewModel: viewModel)
                } label: {
                    projectCard(project)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        projectToDelete = project
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func projectCard(_ project: PropertyProjectRow) -> some View {
        HavenCard {
            HStack(alignment: .top) {
                // Category icon
                let cat = ProjectCategory(rawValue: project.category)
                Image(systemName: cat?.icon ?? "hammer.fill")
                    .font(.title3)
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        statusBadge(project.status)
                    }

                    Text(project.category)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)

                    // Budget progress (if user set a budget)
                    if let budget = project.estimatedBudget, budget > 0 {
                        budgetProgressBar(budget: budget, spent: project.actualSpend ?? 0)
                    }

                    // AI estimates (always show when available)
                    if let diy = project.aiEstimatedDiyCost, let pro = project.aiEstimatedProCost {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "hammer.fill")
                                    .font(.caption2)
                                Text("DIY ~$\(Int(diy))")
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                Text("Pro ~$\(Int(pro))")
                            }
                        }
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    } else if researchService.isResearching && researchService.pendingProjectName == project.name {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.mini)
                            Text("Researching costs...")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    // Date + approach info
                    HStack(spacing: 12) {
                        if let startDate = project.targetStartDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(startDate)
                            }
                        }
                        let approach = ProjectApproach(rawValue: project.projectType)
                        if let approach, approach != .undecided {
                            HStack(spacing: 4) {
                                Image(systemName: approach.icon)
                                    .font(.caption2)
                                Text(approach.displayName)
                            }
                        }
                    }
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    private func statusBadge(_ status: String) -> some View {
        let ps = ProjectStatus(rawValue: status) ?? .planning
        return Text(ps.displayName)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(ps.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ps.color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func budgetProgressBar(budget: Double, spent: Double) -> some View {
        let pct = min(spent / budget, 1.5)
        let color: Color = pct > 1.0 ? HavenColors.critical : pct > 0.8 ? HavenColors.warning : HavenColors.success
        return VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(HavenColors.beige200)
                        .frame(height: 8)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(pct, 1.0), height: 8)
                        .animation(HavenTheme.animationProgress, value: pct)
                }
            }
            .frame(height: 8)

            HStack {
                Text("$\(Int(spent)) of $\(Int(budget))")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                if spent > budget {
                    Text("Over budget")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
    }
}
