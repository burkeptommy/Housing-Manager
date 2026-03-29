import SwiftUI

/// Sheet for editing project details — name, category, approach, description.
struct EditProjectSheet: View {
    let project: PropertyProjectRow
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: ProjectCategory
    @State private var approach: ProjectApproach
    @State private var description: String
    @State private var isSaving = false
    @State private var error: String?

    init(project: PropertyProjectRow, viewModel: ProjectsViewModel) {
        self.project = project
        self.viewModel = viewModel
        _name = State(initialValue: project.name)
        _category = State(initialValue: ProjectCategory(rawValue: project.category) ?? .other)
        _approach = State(initialValue: ProjectApproach(rawValue: project.projectType) ?? .professional)
        _description = State(initialValue: project.description ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing20) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PROJECT NAME")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        HavenTextField(title: "Project name", text: $name)
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        categoryGrid
                    }

                    // Approach
                    VStack(alignment: .leading, spacing: 6) {
                        Text("APPROACH")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        Picker("Approach", selection: $approach) {
                            ForEach(ProjectApproach.allCases, id: \.self) { a in
                                Label(a.displayName, systemImage: a.icon).tag(a)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DESCRIPTION")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        TextField("Additional details...", text: $description, axis: .vertical)
                            .font(HavenTypography.body)
                            .lineLimit(3...6)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if let error {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy800)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(HavenColors.navy)
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: HavenTheme.spacing8)], spacing: HavenTheme.spacing8) {
            ForEach(ProjectCategory.allCases) { cat in
                Button {
                    category = cat
                    Haptics.light()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 16))
                        Text(cat.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundStyle(category == cat ? .white : HavenColors.navy800)
                    .background(category == cat ? HavenColors.navy : HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        error = nil

        let updates = PropertyProjectUpdate(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            category: category.rawValue,
            projectType: approach.rawValue
        )

        do {
            try await viewModel.updateProject(id: project.id, updates)
            Haptics.success()
            dismiss()
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
            Haptics.error()
        }

        isSaving = false
    }
}
