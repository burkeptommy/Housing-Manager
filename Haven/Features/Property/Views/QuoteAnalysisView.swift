import SwiftUI
import PhotosUI

/// Upload and analyze a contractor quote for a project.
/// Shows extraction results with good/fair/overpriced ratings per line item.
struct QuoteAnalysisView: View {
    let project: PropertyProjectRow
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysis: QuoteAnalysis?
    @State private var error: String?
    @State private var importedCount = 0
    @State private var showImportOptions = false
    @State private var pendingImportItems: [QuoteLineItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing16) {
                    if let analysis {
                        analysisResults(analysis)
                    } else if isAnalyzing {
                        analyzingView
                    } else {
                        uploadPrompt
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Analyze Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("QuoteAnalysisView")
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
            .confirmationDialog("You already have items in this project", isPresented: $showImportOptions) {
                Button("Replace All Existing Items") {
                    Task { await importItems(pendingImportItems, replaceExisting: true) }
                }
                Button("Keep Existing & Add Quote Items") {
                    Task { await importItems(pendingImportItems, replaceExisting: false) }
                }
                Button("Cancel", role: .cancel) {
                    pendingImportItems = []
                }
            } message: {
                Text("Would you like to replace your current line items with the quote, or add the quote items alongside them?")
            }
        }
    }

    // MARK: - Upload Prompt

    private var uploadPrompt: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 40)

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Upload a Contractor Quote")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Take a photo or upload a quote and Haven will extract every line item, compare to fair market pricing, and tell you if you're getting a good deal.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: HavenTheme.spacing12) {
                HavenButton(title: "Take Photo", action: {
                    showPhotoPicker = true
                }, icon: "camera.fill")

                HavenButton(title: "Choose from Files", action: {
                    showFilePicker = true
                }, style: .secondary, icon: "folder.fill")
            }

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
    }

    // MARK: - Analyzing

    private var analyzingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.5)
                .tint(HavenColors.navy)
            Text("Analyzing your quote...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Extracting line items and comparing to market prices. This may take a moment.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Analysis Results

    @ViewBuilder
    private func analysisResults(_ analysis: QuoteAnalysis) -> some View {
        // Vendor card
        if let vendor = analysis.vendor, vendor.name != nil {
            vendorCard(vendor)
        }

        // Overall assessment
        if let assessment = analysis.overallAssessment {
            overallCard(assessment)
        }

        // Line items
        if let items = analysis.lineItems, !items.isEmpty {
            lineItemsSection(items)
        }

        // DIY alternative
        if let diy = analysis.suggestedDiyAlternative {
            diyCard(diy)
        }

        // Negotiation tips
        if let tips = analysis.overallAssessment?.negotiationTips, !tips.isEmpty {
            tipsCard(tips)
        }

        // Import button
        if let items = analysis.lineItems, !items.isEmpty, importedCount == 0 {
            HavenButton(title: "Import \(items.count) Items to Project", action: {
                if !viewModel.lineItems.isEmpty {
                    pendingImportItems = items
                    showImportOptions = true
                } else {
                    Task { await importItems(items, replaceExisting: false) }
                }
            }, icon: "square.and.arrow.down")
        } else if importedCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HavenColors.success)
                Text("\(importedCount) items imported to project")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.success)
            }
        }
    }

    // MARK: - Cards

    private func vendorCard(_ vendor: QuoteVendor) -> some View {
        HavenCard {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(HavenColors.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vendor.name ?? "Unknown Vendor")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let phone = vendor.phone {
                        Text(phone)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let license = vendor.license {
                        Text("License: \(license)")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    private func overallCard(_ assessment: QuoteOverallAssessment) -> some View {
        let ratingColor = ratingColor(assessment.rating ?? "fair")
        let ratingIcon = ratingIcon(assessment.rating ?? "fair")
        let ratingLabel = ratingLabel(assessment.rating ?? "fair")

        return HavenCard {
            HStack {
                Image(systemName: ratingIcon)
                    .font(.title2)
                    .foregroundStyle(ratingColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall: \(ratingLabel)")
                        .font(HavenTypography.headline)
                        .foregroundStyle(ratingColor)
                    if let summary = assessment.summary {
                        Text(summary)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: HavenTheme.spacing16) {
                if let quoted = assessment.totalQuoted {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quoted")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(quoted))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
                if let fair = assessment.estimatedFairTotal {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fair Market")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(fair))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.success)
                    }
                }
                if let savings = assessment.potentialSavings, savings > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Potential Savings")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("$\(Int(savings))")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.success)
                    }
                }
                Spacer()
            }
        }
    }

    private func lineItemsSection(_ items: [QuoteLineItem]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("LINE ITEMS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(items) { item in
                HavenCard(padding: HavenTheme.spacing12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(item.description ?? "Item")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                            Spacer()
                            ratingBadge(item.rating ?? "fair")
                        }

                        HStack(spacing: HavenTheme.spacing16) {
                            if let qty = item.quantity, let unit = item.unit {
                                Text("\(qty.formatted()) \(unit)")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            if let total = item.totalPrice {
                                Text("Quoted: $\(total, specifier: "%.2f")")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            if let median = item.marketMedianPrice {
                                Text("Market: $\(median, specifier: "%.2f")")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.success)
                            }
                        }

                        if let reason = item.ratingReason, !reason.isEmpty {
                            Text(reason)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func diyCard(_ diy: QuoteDiyAlternative) -> some View {
        HavenCard {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(HavenColors.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DIY Alternative")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let cost = diy.estimatedDiyCost {
                        Text("Estimated: $\(Int(cost))")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.success)
                    }
                    if let notes = diy.notes {
                        Text(notes)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
                if let feasible = diy.feasible {
                    Text(feasible ? "Feasible" : "Hire a Pro")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(feasible ? HavenColors.success : HavenColors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((feasible ? HavenColors.success : HavenColors.warning).opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func tipsCard(_ tips: [String]) -> some View {
        HavenCard {
            Text("NEGOTIATION TIPS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(HavenColors.warning)
                        .frame(width: 16)
                    Text(tip)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Rating Helpers

    private func ratingBadge(_ rating: String) -> some View {
        Text(ratingLabel(rating))
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(ratingColor(rating))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ratingColor(rating).opacity(0.12))
            .clipShape(Capsule())
    }

    private func ratingColor(_ rating: String) -> Color {
        switch rating {
        case "good_deal": return HavenColors.success
        case "overpriced": return HavenColors.critical
        default: return HavenColors.warning
        }
    }

    private func ratingIcon(_ rating: String) -> String {
        switch rating {
        case "good_deal": return "checkmark.seal.fill"
        case "overpriced": return "exclamationmark.triangle.fill"
        default: return "equal.circle.fill"
        }
    }

    private func ratingLabel(_ rating: String) -> String {
        switch rating {
        case "good_deal": return "Good Deal"
        case "overpriced": return "Overpriced"
        default: return "Fair Price"
        }
    }

    // MARK: - Photo/File Handling

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            error = "Couldn't load the selected image."
            return
        }
        await analyzeImage(data)
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
        await analyzeImage(data)
    }

    private func analyzeImage(_ data: Data) async {
        isAnalyzing = true
        error = nil

        let base64 = data.base64EncodedString()

        do {
            let responseData = try await HavenSupabase.analyzeQuote(
                imageBase64: base64,
                projectName: project.name,
                projectCategory: project.category
            )

            if let rawString = String(data: responseData, encoding: .utf8) {
                print("[QuoteAnalysis] Raw response: \(rawString.prefix(500))")
            }

            struct AnalyzeResponse: Decodable {
                let analysis: QuoteAnalysis?
            }

            let response = try JSONDecoder().decode(AnalyzeResponse.self, from: responseData)
            analysis = response.analysis
            Haptics.success()
            Analytics.track(.documentAIAnalysisCompleted, ["type": "quote", "items": analysis?.lineItems?.count ?? 0])
        } catch {
            print("[QuoteAnalysis] Error: \(error)")
            self.error = "Quote analysis failed. Please try again."
            Haptics.error()
        }

        isAnalyzing = false
    }

    // MARK: - Import Items

    private func importItems(_ items: [QuoteLineItem], replaceExisting: Bool) async {
        let inserts = items.enumerated().compactMap { index, item -> ProjectLineItemInsert? in
            guard let desc = item.description else { return nil }
            return ProjectLineItemInsert(
                projectId: project.id,
                householdId: project.householdId,
                name: desc,
                category: item.category ?? "materials",
                quantity: item.quantity ?? 1,
                unit: item.unit ?? "each",
                estimatedUnitPrice: item.unitPrice ?? item.totalPrice,
                notes: item.ratingReason,
                sortOrder: index
            )
        }

        do {
            // Delete existing items if replacing
            if replaceExisting {
                for item in viewModel.lineItems {
                    try await viewModel.deleteLineItem(id: item.id)
                }
            }
            try await DatabaseService.shared.createLineItems(inserts)
            await viewModel.loadLineItems(projectId: project.id)
            try? await viewModel.recalculateActualSpend(projectId: project.id)
            importedCount = inserts.count
            Haptics.success()
        } catch {
            self.error = "Failed to import items: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
