import SwiftUI

/// Multi-select task curation sheet for a single home system.
/// Lets the user trim the task list directly without going to the global maintenance view.
struct ManageSystemTasksSheet: View {
    let system: HomeSystemRow
    let tasks: [MaintenanceTaskDBRow]
    var onDelete: (([UUID]) async -> Void)
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty {
                    Text("No tasks for this system yet.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(tasks, id: \.id) { task in
                        Button {
                            if selected.contains(task.id) {
                                selected.remove(task.id)
                            } else {
                                selected.insert(task.id)
                            }
                            Haptics.selection()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selected.contains(task.id) ? HavenColors.navy800 : HavenColors.textTertiary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    HStack(spacing: 6) {
                                        Text(task.frequency)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        if task.isTemplateBased == true {
                                            Text("Template")
                                                .font(HavenTypography.uiLabelSmall)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HavenColors.beige200)
                                                .clipShape(Capsule())
                                                .foregroundStyle(HavenColors.navy700)
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(HavenColors.creamLight)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Manage Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selected.count == tasks.count ? "Clear" : "All") {
                        selected = selected.count == tasks.count ? [] : Set(tasks.map(\.id))
                    }
                    .disabled(tasks.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    Button(role: .destructive) {
                        let ids = Array(selected)
                        Task {
                            await onDelete(ids)
                            dismiss()
                        }
                    } label: {
                        Text("Delete selected (\(selected.count))")
                            .font(HavenTypography.uiButton)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(HavenColors.critical)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.bottom, HavenTheme.spacing12)
                }
            }
        }
    }
}
