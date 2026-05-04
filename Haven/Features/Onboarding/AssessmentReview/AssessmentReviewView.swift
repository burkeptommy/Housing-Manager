import SwiftUI

/// Phase 84.5 — The homeowner-facing review screen presented after a
/// handyman submits an assessment. Shows the captured systems, vendors,
/// routines, and documents in scannable sections. The homeowner can
/// either approve everything ("Looks great") or flag specific items
/// for correction.
///
/// Auto-presents on `chez_assessment_complete` push notification via
/// `.openChezAssessmentReview` notification.
struct AssessmentReviewView: View {
    let assessment: HomeAssessmentRow
    let onApproved: () async -> Void
    let onCorrectionsRequested: ([AssessmentCorrectionItem]) async -> Void

    @State private var flaggedItems: [AssessmentCorrectionItem] = []
    @State private var showCorrectionsSheet = false
    @State private var isSubmittingApproval = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    if let systems = assessment.capturedSystems, !systems.isEmpty {
                        capturedSystemsSection(systems)
                    }

                    if let contractors = assessment.capturedContractors, !contractors.isEmpty {
                        capturedContractorsSection(contractors)
                    }

                    if let routines = assessment.capturedRoutines, !routines.isEmpty {
                        capturedRoutinesSection(routines)
                    }

                    if let docs = assessment.capturedDocumentPaths, !docs.isEmpty {
                        capturedDocumentsSection(docs)
                    }

                    actionFooter
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, 16)
            }
            .navigationTitle("Welcome home")
            .navigationBarTitleDisplayMode(.inline)
            .background(HavenColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCorrectionsSheet) {
                AssessmentCorrectionsSheet(
                    assessment: assessment,
                    onSubmit: { items in
                        await onCorrectionsRequested(items)
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your home is set up")
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Here's what your Chez handyman captured during the visit. Take a quick look — anything wrong, just flag it and we'll come back.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private func capturedSystemsSection(_ items: [HomeAssessmentSystemEntry]) -> some View {
        sectionContainer(title: "Home systems", count: items.count) {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, system in
                    sectionRow(
                        title: [system.manufacturer, system.model].compactMap { $0 }.joined(separator: " ").isEmpty
                            ? system.category
                            : "\(system.category) — \([system.manufacturer, system.model].compactMap { $0 }.joined(separator: " "))",
                        subtitle: system.installYear.map { "Installed \($0)" } ?? "",
                        section: "system",
                        entityId: nil
                    )
                }
            }
        }
    }

    private func capturedContractorsSection(_ items: [HomeAssessmentContractorEntry]) -> some View {
        sectionContainer(title: "Vendors you use", count: items.count) {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, vendor in
                    sectionRow(
                        title: vendor.companyName,
                        subtitle: [vendor.category, vendor.phone].compactMap { $0 }.joined(separator: " · "),
                        section: "contractor",
                        entityId: nil
                    )
                }
            }
        }
    }

    private func capturedRoutinesSection(_ items: [HomeAssessmentRoutineEntry]) -> some View {
        sectionContainer(title: "Recurring services", count: items.count) {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, routine in
                    sectionRow(
                        title: routine.label ?? routine.kind,
                        subtitle: [routine.vendorName, routine.cadence].compactMap { $0 }.joined(separator: " · "),
                        section: "routine",
                        entityId: nil
                    )
                }
            }
        }
    }

    private func capturedDocumentsSection(_ items: [String]) -> some View {
        sectionContainer(title: "Documents captured", count: items.count) {
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { path in
                    sectionRow(
                        title: path.split(separator: "/").last.map(String.init) ?? path,
                        subtitle: "",
                        section: "document",
                        entityId: nil
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func sectionContainer<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text("\(count)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            content()
        }
    }

    @ViewBuilder
    private func sectionRow(
        title: String,
        subtitle: String,
        section: String,
        entityId: String?
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(HavenTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(HavenColors.creamLight)
        )
    }

    // MARK: - Action footer

    private var actionFooter: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    isSubmittingApproval = true
                    try? await HavenSupabase.submitAssessmentReview(assessmentId: assessment.id)
                    await onApproved()
                    isSubmittingApproval = false
                    dismiss()
                }
            } label: {
                HStack {
                    if isSubmittingApproval { ProgressView().tint(HavenColors.textOnAction) }
                    Text("Looks great — I'm all set")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnAction)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .fill(HavenColors.action)
                )
            }
            .buttonStyle(.plain)
            .disabled(isSubmittingApproval)

            Button {
                showCorrectionsSheet = true
            } label: {
                Text("Some of this isn't right")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// MARK: - Corrections sheet

struct AssessmentCorrectionsSheet: View {
    let assessment: HomeAssessmentRow
    let onSubmit: ([AssessmentCorrectionItem]) async -> Void

    @State private var items: [AssessmentCorrectionItem] = []
    @State private var draftSection: String = "system"
    @State private var draftNote: String = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    private let sections: [(String, String)] = [
        ("system", "A system"),
        ("contractor", "A vendor"),
        ("routine", "A recurring service"),
        ("document", "A document"),
        ("attribute", "Something else")
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What needs fixing?")
                    .font(HavenTypography.title2)
                Text("Tell us what your handyman missed or got wrong. We'll come back to fix it.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                Picker("Section", selection: $draftSection) {
                    ForEach(sections, id: \.0) { tup in
                        Text(tup.1).tag(tup.0)
                    }
                }
                .pickerStyle(.menu)

                TextEditor(text: $draftNote)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HavenColors.creamLight)
                    )

                Button {
                    let item = AssessmentCorrectionItem(
                        section: draftSection,
                        entityId: nil,
                        note: draftNote
                    )
                    items.append(item)
                    draftNote = ""
                } label: {
                    Label("Add this item", systemImage: "plus.circle")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !items.isEmpty {
                    Divider()
                    Text("FLAGGED ITEMS · \(items.count)")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(idx + 1).")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("[\(item.section)]")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(item.note)
                                            .font(HavenTypography.bodySmall)
                                    }
                                    Spacer()
                                    Button {
                                        items.remove(at: idx)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight)
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                Button {
                    Task {
                        guard !items.isEmpty else { return }
                        isSubmitting = true
                        await onSubmit(items)
                        isSubmitting = false
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isSubmitting { ProgressView().tint(HavenColors.textOnAction) }
                        Text("Send to Chez")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnAction)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(items.isEmpty ? HavenColors.action.opacity(0.4) : HavenColors.action)
                    )
                }
                .buttonStyle(.plain)
                .disabled(items.isEmpty || isSubmitting)
            }
            .padding(20)
            .navigationTitle("Flag items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
