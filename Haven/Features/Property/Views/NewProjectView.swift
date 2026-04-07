import SwiftUI

/// Create a new project — simple form: name, category, approach (Pro/DIY), optional description.
struct NewProjectView: View {
    let propertyID: UUID
    let householdId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ProjectCategory = .other
    @State private var approach: ProjectApproach = .professional
    @State private var description = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PROJECT NAME")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        TextField("e.g. Kitchen Cabinet Replacement", text: $name)
                            .font(HavenTypography.body)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.border, lineWidth: 1)
                            }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        categoryGrid
                    }

                    // Approach
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HOW ARE YOU DOING THIS?")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        HStack(spacing: HavenTheme.spacing8) {
                            ForEach(ProjectApproach.allCases, id: \.self) { a in
                                approachCard(a)
                            }
                        }
                    }

                    // Description — required when "Other" so we can estimate ROI
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category == .other ? "DESCRIBE YOUR PROJECT" : "DESCRIPTION (OPTIONAL)")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(category == .other ? HavenColors.textPrimary : HavenColors.textTertiary)

                        if category == .other {
                            Text("Help us estimate costs and ROI by describing what you're planning.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        TextEditor(text: $description)
                            .font(HavenTypography.body)
                            .frame(minHeight: category == .other ? 100 : 80)
                            .padding(HavenTheme.spacing8)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(category == .other && description.isEmpty ? HavenColors.warning : HavenColors.border, lineWidth: 1)
                            }
                    }

                    if let error {
                        Text(error)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.critical)
                    }

                    // Save
                    HavenButton(
                        title: "Create Project",
                        action: save,
                        isLoading: isSaving,
                        isDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty || (category == .other && description.trimmingCharacters(in: .whitespaces).isEmpty)
                    )
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(HavenColors.navy)
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
            ForEach(ProjectCategory.allCases) { cat in
                Button {
                    Haptics.light()
                    category = cat
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.title3)
                        Text(cat.rawValue)
                            .font(HavenTypography.uiCaption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(category == cat ? .white : HavenColors.navy800)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(category == cat ? HavenColors.navy : HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(category == cat ? Color.clear : HavenColors.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Approach Picker

    private func approachCard(_ a: ProjectApproach) -> some View {
        Button {
            Haptics.light()
            approach = a
        } label: {
            VStack(spacing: 6) {
                Image(systemName: a.icon)
                    .font(.title2)
                Text(a.displayName)
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(approach == a ? .white : HavenColors.navy800)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing16)
            .background(approach == a ? HavenColors.navy : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(approach == a ? Color.clear : HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if category == .other && description.trimmingCharacters(in: .whitespaces).isEmpty { return }
        isSaving = true
        error = nil

        Task {
            do {
                let insert = PropertyProjectInsert(
                    householdId: householdId,
                    propertyId: propertyID,
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    category: category.rawValue,
                    projectType: approach.rawValue
                )
                let project = try await viewModel.createProject(insert)
                Analytics.track(.propertyCreated, ["type": "project", "category": category.rawValue, "approach": approach.rawValue])

                // Trigger feasibility analysis in background
                Task {
                    await viewModel.loadFeasibility(projectId: project.id, projectName: project.name, category: project.category, description: project.description, location: nil)
                }

                Haptics.success()
                dismiss()
            } catch {
                self.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}
