import SwiftUI

/// Create a new project — presented as .sheet from PropertyProjectsView.
struct NewProjectView: View {
    let propertyID: UUID
    let householdId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ProjectCategory = .other
    @State private var approach: ProjectApproach = .undecided
    @State private var description = ""
    @State private var budgetText = ""
    @State private var targetStartDate: Date?
    @State private var showDatePicker = false
    @State private var justExploring = false
    @State private var priority = "medium"
    @State private var isSaving = false
    @State private var error: String?
    @State private var navigateToProject: PropertyProjectRow?

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
                        TextField("e.g. Built-in Bookcase", text: $name)
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
                        Text("APPROACH")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        HStack(spacing: HavenTheme.spacing8) {
                            ForEach(ProjectApproach.allCases, id: \.self) { a in
                                approachCard(a)
                            }
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DESCRIPTION (OPTIONAL)")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        TextEditor(text: $description)
                            .font(HavenTypography.body)
                            .frame(minHeight: 80)
                            .padding(HavenTheme.spacing8)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.border, lineWidth: 1)
                            }
                    }

                    // Budget
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BUDGET")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        // "Just exploring" toggle
                        Button {
                            Haptics.light()
                            justExploring.toggle()
                            if justExploring { budgetText = "" }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: justExploring ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(justExploring ? HavenColors.navy : HavenColors.textTertiary)
                                Text("I'm just exploring — suggest a budget for me")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)

                        if !justExploring {
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundStyle(HavenColors.textSecondary)
                                TextField("Enter your budget", text: $budgetText)
                                    .keyboardType(.decimalPad)
                            }
                            .font(HavenTypography.body)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.border, lineWidth: 1)
                            }
                        }
                    }

                    // Start Date (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("START DATE (OPTIONAL)")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack {
                                Text(targetStartDate.map { dateString($0) } ?? "Not set")
                                    .foregroundStyle(targetStartDate == nil ? HavenColors.textTertiary : HavenColors.textPrimary)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundStyle(HavenColors.navy)
                            }
                            .font(HavenTypography.body)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .strokeBorder(HavenColors.border, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if showDatePicker {
                        DatePicker("Start Date", selection: Binding(
                            get: { targetStartDate ?? Date() },
                            set: { targetStartDate = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.navy)
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRIORITY")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                        .pickerStyle(.segmented)
                    }

                    if let error {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }

                    // CTAs
                    VStack(spacing: HavenTheme.spacing12) {
                        let budgetValid = justExploring || !budgetText.isEmpty
                        HavenButton(
                            title: "Create & Research Costs",
                            action: { Task { await saveAndResearch() } },
                            icon: "sparkle.magnifyingglass",
                            isLoading: viewModel.isResearching,
                            isDisabled: name.isEmpty || !budgetValid || isSaving
                        )

                        HavenButton(
                            title: "Save Without Research",
                            action: { Task { await save(research: false) } },
                            style: .secondary,
                            isLoading: isSaving && !viewModel.isResearching,
                            isDisabled: name.isEmpty || !budgetValid || viewModel.isResearching
                        )
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("NewProjectView")
            .navigationDestination(item: $navigateToProject) { project in
                ProjectDetailView(project: project, viewModel: viewModel)
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 90), spacing: HavenTheme.spacing8)
        ], spacing: HavenTheme.spacing8) {
            ForEach(ProjectCategory.allCases) { cat in
                Button {
                    Haptics.light()
                    category = cat
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 18))
                        Text(cat.rawValue)
                            .font(HavenTypography.uiCaption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(category == cat ? HavenColors.navy800 : HavenColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(category == cat ? HavenColors.navy.opacity(0.08) : HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(category == cat ? HavenColors.navy800 : HavenColors.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Approach Card

    private func approachCard(_ a: ProjectApproach) -> some View {
        Button {
            Haptics.light()
            approach = a
        } label: {
            VStack(spacing: 6) {
                Image(systemName: a.icon)
                    .font(.title3)
                Text(a.displayName)
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundStyle(approach == a ? HavenColors.navy800 : HavenColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(approach == a ? HavenColors.navy.opacity(0.08) : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(approach == a ? HavenColors.navy800 : HavenColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func save(research: Bool) async {
        isSaving = true
        error = nil
        do {
            let insert = buildInsert()
            let project = try await viewModel.createProject(insert)
            Analytics.track(.propertyCreated, ["project_name": name, "category": category.rawValue, "approach": approach.rawValue, "researched": research])
            Haptics.success()

            if research {
                // Fire off research in the background — dismiss immediately
                ProjectResearchService.shared.research(project: project, location: nil)
            }

            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }

    private func saveAndResearch() async {
        await save(research: true)
    }

    private func buildInsert() -> PropertyProjectInsert {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return PropertyProjectInsert(
            householdId: householdId,
            propertyId: propertyID,
            name: name,
            description: description.isEmpty ? nil : description,
            category: category.rawValue,
            projectType: approach.rawValue,
            priority: priority,
            estimatedBudget: Double(budgetText),
            targetStartDate: targetStartDate.map { f.string(from: $0) }
        )
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
