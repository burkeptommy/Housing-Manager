import SwiftUI
import PhotosUI
import QuickLook

/// Simplified project detail — dual mode:
/// - Pro: quote uploads, deal ratings, gap analysis, ROI
/// - DIY: materials cost, complexity, files, Alfred Q&A, ROI
struct ProjectDetailView: View {
    let project: PropertyProjectRow
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showQuoteUpload = false
    @State private var expandedEmailIndex: Int?
    @State private var showQuoteComparison = false
    @State private var showDeleteConfirmation = false
    @State private var showEditProject = false
    @State private var showStatusPicker = false
    @State private var showNotesEditor = false
    @State private var editedNotes = ""
    // File upload (DIY)
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var quickLookURL: URL?
    @State private var loadingFileId: UUID?
    @State private var thumbnailURLs: [UUID: URL] = [:]
    @State private var fileLoadError: String?

    private var liveProject: PropertyProjectRow {
        viewModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    private var isDIY: Bool {
        liveProject.projectType == "diy"
    }

    private var isInsuranceClaim: Bool {
        liveProject.projectType == "insurance_claim"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                statusCard
                if isInsuranceClaim {
                    claimInfoCard
                    filesSection
                } else {
                    roiCard
                    if isDIY {
                        diyOverviewCard
                        filesSection
                    } else {
                        quotesSection
                    }
                }
                askAlfredButton
                notesSection
            }
            .padding(HavenTheme.pageMargin)
        }
        .background(HavenColors.background)
        .navigationTitle(liveProject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditProject = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }
                    Button {
                        showStatusPicker = true
                    } label: {
                        Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .trackScreen("ProjectDetailView", properties: ["project_id": project.id.uuidString])
        .task {
            if isDIY || isInsuranceClaim {
                await viewModel.loadProjectFiles(projectId: project.id)
                await loadThumbnailURLs()
            }
            if !isDIY && !isInsuranceClaim {
                await viewModel.loadQuotes(projectId: project.id)
            }
            if !isInsuranceClaim && viewModel.feasibility == nil {
                await viewModel.loadFeasibility(projectName: liveProject.name, category: liveProject.category, description: liveProject.description, location: nil)
            }
        }
        .alert("Preview Unavailable", isPresented: .init(
            get: { fileLoadError != nil },
            set: { if !$0 { fileLoadError = nil } }
        )) {
            Button("OK") { fileLoadError = nil }
        } message: {
            Text(fileLoadError ?? "")
        }
        .sheet(isPresented: $showQuoteUpload) {
            QuoteUploadEntryView(
                propertyID: liveProject.propertyId,
                householdId: liveProject.householdId,
                location: nil,
                viewModel: viewModel,
                onComplete: {
                    showQuoteUpload = false
                    Task { await viewModel.loadQuotes(projectId: project.id) }
                },
                attachToProject: liveProject
            )
        }
        .sheet(isPresented: $showQuoteComparison) {
            NavigationStack {
                QuoteComparisonView(quotes: viewModel.quotes, projectName: liveProject.name)
            }
        }
        .sheet(isPresented: $showNotesEditor) {
            notesEditorSheet
        }
        .sheet(isPresented: $showEditProject) {
            EditProjectSheet(project: liveProject, viewModel: viewModel)
        }
        .confirmationDialog("Change Status", isPresented: $showStatusPicker) {
            ForEach(ProjectStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    Task {
                        try? await viewModel.updateProject(id: project.id, PropertyProjectUpdate(status: status.rawValue))
                        Haptics.success()
                    }
                }
            }
        }
        .confirmationDialog("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteProject(id: project.id)
                    Haptics.success()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this project.")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .any(of: [.images]))
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image, .pdf]) { result in
            Task { await handleFileSelection(result) }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await handlePhotoSelection(item) }
        }
        .quickLookPreview($quickLookURL)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HavenCard {
            HStack {
                let cat = ProjectCategory(rawValue: liveProject.category)
                Image(systemName: cat?.icon ?? "hammer.fill")
                    .font(.title2)
                    .foregroundStyle(HavenColors.navy)

                VStack(alignment: .leading, spacing: 4) {
                    Text(liveProject.category)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)

                    HStack(spacing: HavenTheme.spacing8) {
                        statusBadge(liveProject.status)
                        approachBadge(liveProject.projectType)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - ROI Card

    private var roiCard: some View {
        HavenCard {
            if viewModel.isLoadingFeasibility {
                HStack {
                    ProgressView()
                    Text("Calculating ROI...")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing8)
            } else if let f = viewModel.feasibility {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(HavenColors.navy)
                        Text("ROI ESTIMATE")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    // Hero ROI %
                    HStack(alignment: .firstTextBaseline) {
                        Text(f.roi?.typicalReturn ?? "N/A")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(roiColor(f.roi?.label))
                        Text("typical return")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    if let label = f.roi?.label {
                        Text(label)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(roiColor(label))
                            .clipShape(Capsule())
                    }

                    if let explanation = f.roi?.explanation {
                        Text(explanation)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Divider()

                    // Cost range
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pro Cost")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text(f.estimatedCostRange?.displayRange ?? "N/A")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DIY Cost")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text(f.estimatedDiyCostRange?.displayRange ?? "N/A")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    // Value increase
                    if let vi = f.valueIncrease {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Value Increase")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(vi.percentageIncrease ?? "N/A")
                                    .font(HavenTypography.body)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Time to Recoup")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(vi.timeToRecoup ?? "N/A")
                                    .font(HavenTypography.body)
                            }
                        }
                    }

                    if let tip = f.quickTip {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.warning)
                            Text(tip)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("ROI data unavailable")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing8)
            }
        }
    }

    private func roiColor(_ label: String?) -> Color {
        switch label?.lowercased() {
        case "high roi": return HavenColors.success
        case "moderate roi": return HavenColors.warning
        case "low roi": return HavenColors.critical
        default: return HavenColors.textTertiary
        }
    }

    // MARK: - DIY Overview Card

    // MARK: - Insurance Claim Card

    private var claimInfoCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(HavenColors.navy)
                    Text("CLAIM DETAILS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                if let research = liveProject.aiResearch {
                    // Claim number
                    if let claimNum = research.claimNumber {
                        claimDetailRow(label: "Claim #", value: claimNum)
                    }
                    // Policy number
                    if let policyNum = research.policyNumber {
                        claimDetailRow(label: "Policy #", value: policyNum)
                    }
                    // Insurance company
                    if let company = research.insuranceCompany {
                        claimDetailRow(label: "Insurance", value: company)
                    }
                    // Claim type
                    if let claimType = research.claimType {
                        claimDetailRow(label: "Type", value: claimType.replacingOccurrences(of: "_", with: " ").capitalized)
                    }

                    // Adjuster info
                    if let adjuster = research.adjuster {
                        Divider()
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundStyle(HavenColors.navy.opacity(0.6))
                            Text("CLAIMS ADVISOR")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .fontWeight(.semibold)
                                .tracking(0.5)
                        }
                        if let name = adjuster.name {
                            Text(name)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        HStack(spacing: 12) {
                            if let phone = adjuster.phone {
                                Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill").font(.caption)
                                        Text(phone).font(HavenTypography.uiCaption)
                                    }
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }
                            if let email = adjuster.email {
                                Link(destination: URL(string: "mailto:\(email)")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "envelope.fill").font(.caption)
                                        Text(email).font(HavenTypography.uiCaption)
                                    }
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }
                        }
                    }

                    // Email timeline
                    if let summaries = research.emailSummaries, !summaries.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CORRESPONDENCE")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                                .fontWeight(.semibold)
                                .tracking(0.5)

                            ForEach(Array(summaries.enumerated()), id: \.offset) { index, entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    if let subj = entry.subject {
                                        Text(subj)
                                            .font(HavenTypography.uiLabel)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    if let summary = entry.summary {
                                        Text(summary)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                    HStack {
                                        if let date = entry.date {
                                            Text(date)
                                                .font(.system(size: 9))
                                                .foregroundStyle(HavenColors.textTertiary)
                                        }
                                        if entry.rawBody != nil {
                                            Spacer()
                                            Button {
                                                withAnimation {
                                                    expandedEmailIndex = expandedEmailIndex == index ? nil : index
                                                }
                                            } label: {
                                                Text(expandedEmailIndex == index ? "Hide Email" : "Show Original Email")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(HavenColors.navy700)
                                            }
                                        }
                                    }
                                    if expandedEmailIndex == index, let body = entry.rawBody {
                                        Text(body)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(HavenColors.textSecondary)
                                            .padding(6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(HavenColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .textSelection(.enabled)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else {
                    Text("Claim details will appear as you forward related emails.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    private func claimDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .textSelection(.enabled)
        }
    }

    // MARK: - DIY Overview Card

    private var diyOverviewCard: some View {
        Group {
            if let f = viewModel.feasibility {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack(spacing: 8) {
                            Image(systemName: "hammer.fill")
                                .foregroundStyle(HavenColors.navy)
                            Text("DIY OVERVIEW")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        // Materials cost
                        if let mc = f.estimatedMaterialsCost {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Materials Cost")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(mc.displayRange)
                                        .font(HavenTypography.headline)
                                        .foregroundStyle(HavenColors.navy800)
                                }
                                Spacer()
                            }
                        }

                        HStack(spacing: HavenTheme.spacing16) {
                            // Complexity
                            if let complexity = f.complexity {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Complexity")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(complexity)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(complexityColor(complexity))
                                }
                            }

                            // Timeframe
                            if let time = f.estimatedTimeframe {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time Estimate")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(time)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                            }

                            // Market demand
                            if let demand = f.marketDemand {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Buyer Demand")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(demand)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                            }
                        }

                        if let note = f.complexityNote {
                            Text(note)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func complexityColor(_ complexity: String) -> Color {
        switch complexity.lowercased() {
        case "easy": return HavenColors.success
        case "moderate": return HavenColors.warning
        case "complex": return HavenColors.critical
        case "professional recommended": return HavenColors.critical
        default: return HavenColors.textPrimary
        }
    }

    // MARK: - Quotes Section (Pro)

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("QUOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                if !viewModel.quotes.isEmpty {
                    Text("\(viewModel.quotes.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            ForEach(viewModel.quotes) { quote in
                NavigationLink {
                    QuoteDetailView(quote: quote, viewModel: viewModel)
                } label: {
                    quoteCard(quote)
                }
                .buttonStyle(.plain)
            }

            Button {
                showQuoteUpload = true
                Analytics.track(.documentUploadStarted, ["type": "quote", "project_id": project.id.uuidString])
            } label: {
                HavenCard(padding: HavenTheme.spacing12) {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                            .foregroundStyle(HavenColors.navy)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.quotes.isEmpty ? "Upload a Contractor Quote" : "Upload Another Quote")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy800)
                            Text("Get a line-by-line deal analysis")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
            .buttonStyle(.plain)

            if viewModel.quotes.count >= 2 {
                Button {
                    showQuoteComparison = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption)
                        Text("Compare \(viewModel.quotes.count) Quotes")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quoteCard(_ quote: ProjectQuoteRow) -> some View {
        HavenCard(padding: HavenTheme.spacing12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quote.vendorName ?? "Contractor Quote")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    HStack(spacing: 8) {
                        if let date = quote.quoteDate {
                            Text(date)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        if let rating = quote.overallRating {
                            quoteRatingBadge(rating)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let total = quote.quoteTotal {
                        Text("$\(Int(total).formatted())")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                    }
                    if let fair = quote.estimatedFairTotal {
                        Text("Fair: $\(Int(fair).formatted())")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private func quoteRatingBadge(_ rating: String) -> some View {
        let (label, color): (String, Color) = {
            switch rating.lowercased() {
            case "good_deal": return ("Good Deal", HavenColors.success)
            case "overpriced": return ("Overpriced", HavenColors.critical)
            default: return ("Fair", HavenColors.warning)
            }
        }()

        return Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Files Section (DIY)

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("FILES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                if !viewModel.projectFiles.isEmpty {
                    Text("\(viewModel.projectFiles.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            // File grid
            if !viewModel.projectFiles.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.projectFiles) { file in
                        fileCard(file)
                    }
                }
            }

            // Upload buttons
            HStack(spacing: HavenTheme.spacing8) {
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.caption)
                        Text("Add Photo")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    showFilePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                        Text("Add File")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fileCard(_ file: ProjectFileRow) -> some View {
        Button {
            Task { await loadProjectFile(file) }
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HavenColors.navy.opacity(0.06))
                    .frame(height: 80)
                    .overlay {
                        if loadingFileId == file.id {
                            ProgressView()
                        } else if file.isImage, let url = thumbnailURLs[file.id] {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                        .foregroundStyle(HavenColors.navy.opacity(0.4))
                                default:
                                    ProgressView()
                                }
                            }
                        } else {
                            Image(systemName: file.isImage ? "photo.fill" : "doc.fill")
                                .font(.title2)
                                .foregroundStyle(HavenColors.navy.opacity(0.4))
                        }
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(file.filename)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task { try? await viewModel.deleteProjectFile(id: file.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func loadProjectFile(_ file: ProjectFileRow) async {
        loadingFileId = file.id
        defer { loadingFileId = nil }
        let db = DatabaseService.shared
        do {
            // Try documents bucket first (user uploads go here), fall back to inbox-attachments (email forwards)
            var url = try await db.getDocumentSignedURL(path: file.filePath)
            var (data, response) = try await URLSession.shared.data(from: url)
            var statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode != 200 {
                url = try await db.getInboxAttachmentSignedURL(path: file.filePath)
                (data, response) = try await URLSession.shared.data(from: url)
                statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            }

            guard statusCode == 200, !data.isEmpty else {
                await MainActor.run {
                    fileLoadError = "Could not load this file. It may have been moved or deleted."
                }
                return
            }

            let ext = (file.filename as NSString).pathExtension.isEmpty ? "pdf" : (file.filename as NSString).pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(file.id.uuidString)
                .appendingPathExtension(ext)
            try data.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("[ProjectDetail] Failed to load file: \(error)")
            await MainActor.run {
                fileLoadError = "Failed to preview file: \(error.localizedDescription)"
            }
        }
    }

    private func loadThumbnailURLs() async {
        let db = DatabaseService.shared
        let imageFiles = viewModel.projectFiles.filter(\.isImage).prefix(6)
        for file in imageFiles {
            do {
                // Try documents bucket first, fall back to inbox-attachments
                if let url = try? await db.getDocumentSignedURL(path: file.filePath) {
                    await MainActor.run { thumbnailURLs[file.id] = url }
                } else {
                    let url = try await db.getInboxAttachmentSignedURL(path: file.filePath)
                    await MainActor.run { thumbnailURLs[file.id] = url }
                }
            } catch {
                print("[ProjectDetail] Thumbnail URL failed for \(file.filename): \(error)")
            }
        }
    }

    // MARK: - File Upload Handlers

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let filename = "photo_\(Date().timeIntervalSince1970).jpg"
        try? await viewModel.uploadProjectFile(
            projectId: project.id,
            householdId: project.householdId,
            data: data,
            filename: filename,
            contentType: "image/jpeg"
        )
        selectedPhoto = nil
        Haptics.success()
    }

    private func handleFileSelection(_ result: Result<URL, Error>) async {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }

        let filename = url.lastPathComponent
        let contentType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
        try? await viewModel.uploadProjectFile(
            projectId: project.id,
            householdId: project.householdId,
            data: data,
            filename: filename,
            contentType: contentType
        )
        Haptics.success()
    }

    // MARK: - Ask Alfred

    private var askAlfredButton: some View {
        Button {
            // Navigate to Alfred tab with project context
            NotificationCenter.default.post(
                name: .openAlfredWithContext,
                object: nil,
                userInfo: [
                    "message": "I have a question about my \(liveProject.category) project: \(liveProject.name)",
                    "contextType": "project",
                    "contextId": project.id.uuidString,
                ]
            )
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ask Alfred About This Project")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy800)
                        Text(isDIY ? "Get DIY tips, material advice, and planning help" : "Questions about quotes, contractors, or next steps")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private var notesSection: some View {
        HavenCard {
            HStack {
                Text("NOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    editedNotes = liveProject.notes ?? ""
                    showNotesEditor = true
                } label: {
                    Text("Edit")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy)
                }
                .buttonStyle(.plain)
            }

            if let notes = liveProject.notes, !notes.isEmpty {
                Text(notes)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                Text("No notes yet.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private var notesEditorSheet: some View {
        NavigationStack {
            TextEditor(text: $editedNotes)
                .font(HavenTypography.body)
                .padding()
                .navigationTitle("Edit Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showNotesEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                try? await viewModel.updateProject(id: project.id, PropertyProjectUpdate(notes: editedNotes))
                                Haptics.success()
                                showNotesEditor = false
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
                .tint(HavenColors.navy)
        }
    }

    // MARK: - Badges

    private func statusBadge(_ status: String) -> some View {
        let ps = ProjectStatus(rawValue: status)
        return Text(ps?.displayName ?? status.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(ps?.color ?? HavenColors.textTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((ps?.color ?? HavenColors.textTertiary).opacity(0.12))
            .clipShape(Capsule())
    }

    private func approachBadge(_ type: String) -> some View {
        let label = type == "diy" ? "DIY" : type == "insurance_claim" ? "Claim" : "Pro"
        let icon = type == "diy" ? "hammer.fill" : type == "insurance_claim" ? "shield.fill" : "person.badge.shield.checkmark.fill"
        return HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(HavenColors.navy700)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(HavenColors.navy.opacity(0.08))
        .clipShape(Capsule())
    }
}

