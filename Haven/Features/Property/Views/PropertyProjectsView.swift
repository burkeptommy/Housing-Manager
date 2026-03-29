import SwiftUI

/// Projects tab content inside PropertyDetailView.
struct PropertyProjectsView: View {
    let propertyID: UUID
    let householdId: UUID?
    var propertyLocation: String?
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showNewProject = false
    @State private var projectToDelete: PropertyProjectRow?

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                SkeletonCard(lineCount: 2)
                SkeletonCard(lineCount: 2)
            } else if viewModel.projects.isEmpty {
                EmptyStateView(
                    title: "No projects yet",
                    message: "Upload contractor quotes for deal analysis, or plan your next DIY project.",
                    icon: "hammer.fill",
                    actionTitle: "Start a Project",
                    action: { showNewProject = true }
                )
                .frame(minHeight: 300)
            } else {
                HavenButton(title: "New Project", action: {
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
            Text("This will permanently delete this project.")
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

                    HStack(spacing: 8) {
                        Text(project.category)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)

                        approachBadge(project.projectType)
                    }
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

    private func approachBadge(_ type: String) -> some View {
        let label = type == "diy" ? "DIY" : "Pro"
        return Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(HavenColors.navy.opacity(0.08))
            .clipShape(Capsule())
    }
}
