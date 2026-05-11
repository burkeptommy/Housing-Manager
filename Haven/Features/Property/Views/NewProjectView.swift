import SwiftUI

/// Create a new project — simple form: name, category, approach (Pro/DIY), optional description.
struct NewProjectView: View {
    let propertyID: UUID
    let householdId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    /// Phase 95 (gap #36) — when set, the new project is linked as
    /// a sub-project under this insurance-claim parent. Used by
    /// `ProjectDetailView`'s claim section "+ Add new project"
    /// affordance so users can spin out a sub-project (e.g.
    /// "Kitchen drywall replacement") directly into an in-flight
    /// claim without navigating back to the project list and using
    /// the link picker.
    var parentProjectId: UUID? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ProjectCategory = .other
    @State private var approach: ProjectApproach = .professional
    @State private var description = ""
    @State private var isSaving = false
    @State private var error: String?

    /// Phase 80 — context dict for the Chez handoff from this screen.
    /// Tom gets whatever the user has typed so far, even if they
    /// haven't saved.
    private var chezNewProjectContext: [String: String] {
        var c: [String: String] = [
            "property_id": propertyID.uuidString,
            "_source": "new_project_view",
            "source_entity_type": "project_draft",
            "source_entity_label": name.isEmpty ? "New \(category.rawValue) project" : name,
        ]
        if !name.isEmpty { c["draft_project_name"] = name }
        c["category"] = category.rawValue
        c["approach"] = approach == .diy ? "diy" : "professional"
        if !description.isEmpty {
            c["description"] = String(description.prefix(400))
        }
        return c
    }

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

                    // Phase 80 — Chez Concierge entry. Some users hit
                    // this screen and stall because they don't actually
                    // know what they need. Tom takes a half-formed idea
                    // and builds the project around it.
                    ChezEntryButton(
                        category: .general,
                        label: "Not sure what you need? Ask Chez",
                        caption: "Chez scopes the project, finds vendors, and gets quotes.",
                        context: chezNewProjectContext
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
                var insert = PropertyProjectInsert(
                    householdId: householdId,
                    propertyId: propertyID,
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    category: category.rawValue,
                    projectType: approach.rawValue
                )
                // Phase 95 (gap #36) — link to insurance-claim parent
                // when invoked from the claim sub-project flow.
                insert.parentProjectId = parentProjectId
                let project = try await viewModel.createProject(insert)
                Analytics.track(.propertyCreated, ["type": "project", "category": category.rawValue, "approach": approach.rawValue])

                // Trigger feasibility analysis in background
                Task {
                    await viewModel.loadFeasibility(projectId: project.id, projectName: project.name, category: project.category, description: project.description, location: nil)
                }

                Haptics.success()
                // Phase 95 audit fix — PropertyProjectsView and the
                // dashboard project surfaces both observe `.projectChanged`
                // to know when to reload. Without this post, a user who
                // creates a project sees no row appear until they kill
                // and relaunch.
                NotificationCenter.default.post(name: .projectChanged, object: nil)
                dismiss()
            } catch {
                self.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}
