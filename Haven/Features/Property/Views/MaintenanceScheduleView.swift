import SwiftUI

struct MaintenanceScheduleView: View {
    @StateObject private var viewModel = MaintenanceViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                ProgressView("Loading tasks...")
            } else if viewModel.tasks.isEmpty {
                ContentUnavailableView {
                    Label("No Maintenance Tasks", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("Add systems to your properties to generate maintenance schedules.")
                }
            } else {
                taskList
            }
        }
        .navigationTitle("Maintenance")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Overdue Only", isOn: $viewModel.showOverdueOnly)
                    if !viewModel.properties.isEmpty {
                        Picker("Property", selection: $viewModel.filterPropertyId) {
                            Text("All Properties").tag(nil as UUID?)
                            ForEach(viewModel.properties) { p in
                                Text(p.name).tag(p.id as UUID?)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
        .task {
            if viewModel.tasks.isEmpty {
                await viewModel.loadTasks()
            }
        }
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary bar
                if viewModel.overdueCount > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("\(viewModel.overdueCount) overdue task\(viewModel.overdueCount == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ForEach(viewModel.filteredTasks) { task in
                    maintenanceRow(task)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func maintenanceRow(_ task: MaintenanceTaskDBRow) -> some View {
        let isOverdue: Bool = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            guard let date = f.date(from: task.nextDueDate) else { return false }
            return date < .now
        }()

        return HavenCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(isOverdue ? Color.red : Color.orange)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 8) {
                        Text(viewModel.propertyName(for: task.propertyId))
                        Text("\u{2022}")
                        Text("Due: \(task.nextDueDate)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let desc = task.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let priority = task.priority {
                        Text(priority)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(priority).opacity(0.12))
                            .foregroundStyle(priorityColor(priority))
                            .clipShape(Capsule())
                    }

                    Button("Done") {
                        Task { await viewModel.completeTask(task) }
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return .purple
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        MaintenanceScheduleView()
    }
}
