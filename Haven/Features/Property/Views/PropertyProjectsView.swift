import SwiftUI

/// Projects tab content inside PropertyDetailView.
struct PropertyProjectsView: View {
    let propertyID: UUID
    let householdId: UUID?
    var propertyLocation: String?
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showNewProject = false
    @State private var showLogHistorical = false
    @State private var showAddOptions = false
    @State private var projectToDelete: PropertyProjectRow?

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                SkeletonCard(lineCount: 2)
                SkeletonCard(lineCount: 2)
            } else if viewModel.projects.isEmpty {
                EmptyStateView(
                    title: "No projects yet",
                    message: "Plan a renovation or log past improvements to build your home's project history.",
                    icon: "hammer.fill",
                    actionTitle: "Add Project",
                    action: { showAddOptions = true }
                )
                .frame(minHeight: 300)
            } else {
                HavenButton(title: "Add Project", action: {
                    showAddOptions = true
                }, icon: "plus")

                if !viewModel.activeProjects.isEmpty {
                    projectSection("ACTIVE", projects: viewModel.activeProjects)
                }
                if !viewModel.completedProjects.isEmpty {
                    projectSection("COMPLETED", projects: viewModel.completedProjects)

                    // Total spend for completed projects
                    if viewModel.completedProjectsTotal > 0 {
                        Text("Total: $\(Int(viewModel.completedProjectsTotal).formatted())")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, HavenTheme.spacing8)
                    }
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
        .sheet(isPresented: $showLogHistorical) {
            if let hhId = householdId {
                LogHistoricalProjectView(propertyID: propertyID, householdId: hhId, viewModel: viewModel)
            }
        }
        .confirmationDialog("Add Project", isPresented: $showAddOptions) {
            Button("Plan New Project") { showNewProject = true }
            Button("Log Completed Project") { showLogHistorical = true }
            Button("Cancel", role: .cancel) {}
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
                let cardIcon = project.projectType == "insurance_claim" ? "shield.fill" : (ProjectCategory(rawValue: project.category)?.icon ?? "hammer.fill")
                Image(systemName: cardIcon)
                    .font(.title3)
                    .foregroundStyle(project.projectType == "insurance_claim" ? HavenColors.critical : HavenColors.navy)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if project.isHistorical {
                            if let spend = project.actualSpend, spend > 0 {
                                Text("$\(Int(spend).formatted())")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.navy800)
                            }
                        } else {
                            statusBadge(project.status)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(project.category)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)

                        if project.isHistorical {
                            if let dateStr = project.actualEndDate {
                                Text(formatProjectDate(dateStr))
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        } else {
                            approachBadge(project.projectType)
                        }
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

    /// Formats "2023-06-15" as "Jun 2023", or "2023" if only year available
    private func formatProjectDate(_ dateStr: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: dateStr) {
            let out = DateFormatter()
            out.dateFormat = "MMM yyyy"
            return out.string(from: date)
        }
        return String(dateStr.prefix(4)) // fallback to year
    }

    private func approachBadge(_ type: String) -> some View {
        let (label, icon, color): (String, String?, Color) = switch type {
        case "diy": ("DIY", nil, HavenColors.navy700)
        case "insurance_claim": ("Insurance Claim", "shield.fill", HavenColors.critical)
        default: ("Pro", nil, HavenColors.navy700)
        }
        return HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 8))
            }
            Text(label)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }
}
