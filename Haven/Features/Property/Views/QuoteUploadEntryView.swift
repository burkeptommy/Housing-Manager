import SwiftUI
import PhotosUI

/// Upload a contractor quote — either creates a new project or attaches to an existing one.
/// When `attachToProject` is set, the quote is automatically linked (no matching step).
struct QuoteUploadEntryView: View {
    let propertyID: UUID
    let householdId: UUID
    let location: String?
    @ObservedObject var viewModel: ProjectsViewModel
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    /// If set, the quote is attached directly to this project (from "Upload Another Quote" in project detail).
    var attachToProject: PropertyProjectRow?

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var error: String?

    // Post-analysis state
    @State private var analysisResult: QuoteAnalysis?
    @State private var matchedProject: PropertyProjectRow?
    @State private var targetProject: PropertyProjectRow?

    private enum ViewState {
        case upload, analyzing, matchChoice, success
    }

    private var viewState: ViewState {
        if isAnalyzing { return .analyzing }
        if targetProject != nil { return .success }
        if analysisResult != nil && matchedProject != nil && attachToProject == nil { return .matchChoice }
        return .upload
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    switch viewState {
                    case .upload:
                        uploadView
                    case .analyzing:
                        analyzingView
                    case .matchChoice:
                        matchChoiceView
                    case .success:
                        successView
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Upload a Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy800)
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("QuoteUploadEntryView")
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task { await handlePhotoSelection(item) }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image, .pdf]) { result in
                switch result {
                case .success(let url):
                    Task { await handleFileSelection(url) }
                case .failure(let err):
                    error = err.localizedDescription
                }
            }
        }
    }

    // MARK: - Upload View

    private var uploadView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 32)

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HavenColors.navy800)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Upload a contractor quote")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.navy800)
                    .multilineTextAlignment(.center)

                if let project = attachToProject {
                    Text("This quote will be added to **\(project.name)**.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Take a photo or upload a PDF. Alfred will extract the vendor, analyze every line item against market pricing, and set up your project.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: HavenTheme.spacing12) {
                HavenButton(title: "Take a Photo", action: {
                    Haptics.light()
                    showPhotoPicker = true
                }, icon: "camera.fill")

                HavenButton(title: "Choose File", action: {
                    Haptics.light()
                    showFilePicker = true
                }, style: .secondary, icon: "folder.fill")
            }

            Spacer()
        }
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(HavenColors.navy700)
            VStack(spacing: HavenTheme.spacing8) {
                Text("Analyzing your quote...")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                Text("Extracting vendor details, researching fair market pricing for every line item, and comparing to your area.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }

    // MARK: - Match Choice View

    private var matchChoiceView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 32)

            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HavenColors.navy800)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Existing project found")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.navy800)

                if let matched = matchedProject {
                    Text("This looks like a quote for **\(matched.name)**. Add it to that project, or create a new one?")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let vendor = analysisResult?.vendor?.name {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(HavenColors.navy700)
                    Text(vendor)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if let total = analysisResult?.quoteTotal {
                        Text("$\(Int(total).formatted())")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                    }
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: HavenTheme.spacing12) {
                if let matched = matchedProject {
                    HavenButton(title: "Add to \(matched.name)", action: {
                        Task { await saveQuoteToProject(matched, analysis: analysisResult!, isNewProject: false) }
                    }, icon: "plus.circle.fill")
                }

                HavenButton(title: "Create New Project", action: {
                    Task {
                        guard let analysis = analysisResult else { return }
                        await createProjectAndSaveQuote(analysis)
                    }
                }, style: .secondary, icon: "folder.badge.plus")
            }

            Spacer()
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 32)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.success)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Quote Saved")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.navy800)

                if let project = targetProject {
                    Text("Added to \(project.name)")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let rating = analysisResult?.overallAssessment?.rating {
                    ratingBadge(rating)
                        .padding(.top, 4)
                }
            }

            HavenButton(title: "View Project", action: {
                onComplete()
            }, icon: "arrow.right")

            Spacer()
        }
    }

    private func ratingBadge(_ rating: String) -> some View {
        let (label, color): (String, Color) = {
            switch rating.lowercased() {
            case "good_deal": return ("Good Deal", HavenColors.success)
            case "overpriced": return ("Overpriced", HavenColors.critical)
            default: return ("Fair Price", HavenColors.warning)
            }
        }()

        return Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Handlers

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            error = "Couldn't load the selected image."
            return
        }
        await processQuote(data)
    }

    private func handleFileSelection(_ url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            error = "Couldn't access the selected file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else {
            error = "Couldn't read the selected file."
            return
        }
        await processQuote(data)
    }

    private func processQuote(_ data: Data) async {
        isAnalyzing = true
        error = nil

        let (imageBase64, extractedText, prepError) = await DocumentAnalysisService.shared.prepareForQuoteAnalysis(data)
        if let prepError {
            self.error = prepError
            isAnalyzing = false
            return
        }

        // If attaching to an existing project, dismiss immediately and process in background
        if let project = attachToProject {
            Haptics.success()
            dismiss()
            Task {
                do {
                    let responseData = try await HavenSupabase.analyzeQuote(
                        imageBase64: imageBase64,
                        text: extractedText,
                        propertyLocation: location
                    )
                    struct AnalyzeResponse: Decodable { let analysis: QuoteAnalysis? }
                    if let response = try? JSONDecoder().decode(AnalyzeResponse.self, from: responseData),
                       let analysis = response.analysis {
                        await saveQuoteToProject(project, analysis: analysis, isNewProject: false)
                    }
                } catch {
                    print("[QuoteUpload] Background analysis failed: \(error)")
                }
                onComplete()
            }
            return
        }

        do {
            let responseData = try await HavenSupabase.analyzeQuote(
                imageBase64: imageBase64,
                text: extractedText,
                propertyLocation: location
            )

            struct AnalyzeResponse: Decodable { let analysis: QuoteAnalysis? }
            struct ErrorResponse: Decodable { let error: String?; let detail: String? }

            if let errResp = try? JSONDecoder().decode(ErrorResponse.self, from: responseData),
               let serverError = errResp.error {
                error = "Quote analysis failed: \(serverError)"
                isAnalyzing = false
                return
            }

            let response = try JSONDecoder().decode(AnalyzeResponse.self, from: responseData)
            guard let analysis = response.analysis else {
                error = "Couldn't parse the quote. Try uploading a clearer photo or PDF."
                isAnalyzing = false
                return
            }

            analysisResult = analysis
            isAnalyzing = false

            // Check for matching existing project
            let category = analysis.projectType ?? "Other"
            if let matched = viewModel.findMatchingProject(category: category, propertyId: propertyID) {
                matchedProject = matched
                // viewState will switch to .matchChoice
            } else {
                // No match — create project and save quote
                await createProjectAndSaveQuote(analysis)
            }

        } catch {
            print("[QuoteUploadEntry] Error: \(error)")
            let nsError = error as NSError
            if nsError.domain == "EdgeFunction" || nsError.domain == "NSURLErrorDomain" {
                let msg = nsError.localizedDescription
                if msg.contains("timed out") || msg.contains("timeout") {
                    self.error = "Analysis timed out. Try a smaller or clearer file."
                } else if msg.contains("too large") || msg.contains("413") {
                    self.error = "File is too large. Try a smaller document."
                } else {
                    self.error = "Quote analysis failed: \(msg)"
                }
            } else {
                self.error = "Quote analysis failed. Please try again."
            }
            Haptics.error()
            isAnalyzing = false
        }
    }

    // MARK: - Save Logic

    private func createProjectAndSaveQuote(_ analysis: QuoteAnalysis) async {
        do {
            let projectName = analysis.projectType ?? "Quote from \(analysis.vendor?.name ?? "Contractor")"
            let category = analysis.projectType ?? "Other"

            let insert = PropertyProjectInsert(
                householdId: householdId,
                propertyId: propertyID,
                name: projectName,
                category: category,
                status: "planning",
                projectType: "pro"
            )
            let project = try await viewModel.createProject(insert)
            await saveQuoteToProject(project, analysis: analysis, isNewProject: true)
        } catch {
            self.error = "Failed to create project: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func saveQuoteToProject(_ project: PropertyProjectRow, analysis: QuoteAnalysis, isNewProject: Bool) async {
        do {
            // Auto-create or find vendor
            var contractorId: UUID?
            if let vendor = analysis.vendor {
                contractorId = await viewModel.findOrCreateContractor(vendor: vendor, householdId: householdId)
            }

            // Save the quote
            let quoteInsert = ProjectQuoteInsert(
                projectId: project.id,
                householdId: householdId,
                contractorId: contractorId,
                quoteDate: analysis.quoteDate,
                quoteTotal: analysis.overallAssessment?.totalQuoted ?? analysis.quoteTotal,
                estimatedFairTotal: analysis.overallAssessment?.estimatedFairTotal,
                overallRating: analysis.overallAssessment?.rating,
                analysis: analysis,
                trade: analysis.vendor?.trade
            )
            _ = try await viewModel.addQuote(quoteInsert)

            // Update project: set to pro, update cost estimate
            let fairTotal = analysis.overallAssessment?.estimatedFairTotal ?? analysis.quoteTotal
            var updates = PropertyProjectUpdate(projectType: "pro")
            if let cost = fairTotal {
                updates.aiEstimatedProCost = cost
            }
            try? await viewModel.updateProject(id: project.id, updates)

            targetProject = project
            Haptics.success()
            Analytics.track(.enrichmentCardCompleted, [
                "type": "quote_upload",
                "vendor": analysis.vendor?.name ?? "unknown",
                "items": analysis.lineItems?.count ?? 0,
                "attached_to_existing": !isNewProject,
            ])
        } catch {
            self.error = "Failed to save quote: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
