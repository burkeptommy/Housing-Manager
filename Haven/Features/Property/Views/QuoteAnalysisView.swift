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
    @State private var quoteSaved = false
    /// Phase 95 (gap #37) — drives the negotiation-email composer
    /// sheet. Only renders when at least one line item is rated
    /// `overpriced`, since that's what the Edge Function needs.
    @State private var showNegotiationEmail = false

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
            // Phase 95 (gap #37) — negotiation-email composer.
            // Reads the in-flight `analysis` payload to seed the
            // `draft-negotiation-email` request.
            .sheet(isPresented: $showNegotiationEmail) {
                if let analysis {
                    NegotiationEmailSheet(analysis: analysis, project: project)
                        .presentationDetents([.large])
                }
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
                Text("Take a photo or upload a quote and Chez will extract every line item, compare to fair market pricing, and tell you if you're getting a good deal.")
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

        // Phase 95 (gap #33) — line-item breakdown. The
        // `analyze-quote` Edge Function extracts every line item
        // with quantity, unit, fair-market range, and per-item
        // good/fair/overpriced rating; previously the data lived
        // in the response but never rendered. Without this the
        // user only saw the overall assessment + tips and had no
        // way to see WHY the rating landed where it did.
        if let items = analysis.lineItems, !items.isEmpty {
            lineItemsSection(items)
        }

        // Phase 95 (gap #33) — DIY alternative. Edge function
        // emits this on every quote; previously hidden so users
        // missed the "could you do this yourself for $X" framing
        // entirely.
        if let diy = analysis.suggestedDiyAlternative {
            diyCard(diy)
        }

        // Negotiation tips (prioritize itemized quote tip)
        let allTips = buildTips(analysis)
        if !allTips.isEmpty {
            tipsCard(allTips)
        }

        // Save quote confirmation
        if quoteSaved {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HavenColors.success)
                Text("Quote saved to project")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.success)
            }
        }

        // Phase 95 (gap #37) — draft-negotiation-email entry.
        // Renders only when the analysis flagged overpriced line
        // items (the Edge Function rejects requests without
        // them). Tap → open NegotiationEmailSheet which calls
        // `draft-negotiation-email`, lets the user review/edit
        // the body, and hands off to the iOS Mail composer.
        if hasOverpricedItems(analysis) {
            HavenButton(
                title: "Draft a negotiation email",
                action: {
                    Haptics.medium()
                    showNegotiationEmail = true
                },
                style: .secondary,
                icon: "envelope.fill"
            )
            .padding(.top, HavenTheme.spacing8)
        }

        // Phase 80 — Chez Concierge entry. Once the user has the AI's
        // analysis on screen, they often want a second opinion or want
        // Chez to negotiate / find a comparison quote. This pill is the
        // canonical handoff for that.
        ChezEntryButton(
            category: .getQuote,
            label: "Have Chez get a second quote",
            caption: "Chez gathers a comparable bid and a fair-market read.",
            context: chezQuoteContext(analysis)
        )
        .padding(.top, HavenTheme.spacing12)
    }

    /// Phase 95 (gap #37) — true when at least one analyzed
    /// line item is rated `overpriced`. Drives the "Draft a
    /// negotiation email" CTA's visibility.
    private func hasOverpricedItems(_ analysis: QuoteAnalysis) -> Bool {
        (analysis.lineItems ?? []).contains { ($0.rating ?? "") == "overpriced" }
    }

    /// Phase 80 — context for the Chez handoff. Includes vendor name,
    /// project name, quoted total, and assessment so Tom can act without
    /// asking the user to re-summarize.
    private func chezQuoteContext(_ analysis: QuoteAnalysis) -> [String: String] {
        var c: [String: String] = [
            "project_id": project.id.uuidString,
            "project_name": project.name,
        ]
        if let vendor = analysis.vendor?.name { c["vendor"] = vendor }
        if let total = analysis.overallAssessment?.totalQuoted {
            c["quoted_total"] = "$\(Int(total))"
        }
        if let fair = analysis.overallAssessment?.estimatedFairTotal {
            c["fair_market_estimate"] = "$\(Int(fair))"
        }
        if let rating = analysis.overallAssessment?.rating {
            c["assessment"] = rating
        }
        return c
    }

    // MARK: - Cards

    private func buildTips(_ analysis: QuoteAnalysis) -> [String] {
        var tips = analysis.overallAssessment?.negotiationTips ?? []
        let hasItemized = analysis.hasItemizedPricing ?? true
        if !hasItemized && !tips.contains(where: { $0.lowercased().contains("itemized") }) {
            tips.insert("Ask your contractor for an itemized quote breakdown. This helps you compare specific line items across vendors and negotiate individual costs.", at: 0)
        }
        return tips
    }

    private func vendorCard(_ vendor: QuoteVendor) -> some View {
        HavenCard {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(HavenColors.textPrimary)
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

                        if let qty = item.quantity, let unit = item.unit {
                            Text("\(qty.formatted()) \(unit)")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }

                        if let range = item.localPriceRange, let low = range.low, let high = range.high, high > low {
                            localRangeBar(item: item, low: low, high: high, countyName: range.countyName, costIndex: range.costIndex)
                        } else {
                            HStack(spacing: HavenTheme.spacing16) {
                                if let total = item.displayPrice {
                                    Text("Quoted: $\(total, specifier: "%.0f")")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                                if let median = item.marketMedianPrice {
                                    Text("Fair: $\(median, specifier: "%.0f")")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.success)
                                }
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
                    .foregroundStyle(HavenColors.textPrimary)
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

    /// Visual range bar showing where the quoted price falls within the local county range.
    private func localRangeBar(item: QuoteLineItem, low: Double, high: Double, countyName: String?, costIndex: String?) -> some View {
        let quoted = item.displayPrice
        let fair = item.marketMedianPrice

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if let county = countyName {
                    Text(county)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                if let idx = costIndex {
                    let idxLabel = switch idx {
                    case "very_high": "Very High Cost Area"
                    case "high": "High Cost Area"
                    case "low": "Low Cost Area"
                    default: ""
                    }
                    if !idxLabel.isEmpty {
                        Text("·")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(idxLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(idx == "very_high" || idx == "high" ? HavenColors.warning : HavenColors.success)
                    }
                }
            }

            HStack {
                Text("$\(Int(low).formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.success)
                Spacer()
                if let f = fair {
                    Text("Fair: $\(Int(f).formatted())")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
                Spacer()
                Text("$\(Int(high).formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.critical)
            }

            GeometryReader { geo in
                let barWidth = geo.size.width
                let range = high - low

                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [HavenColors.success.opacity(0.3), HavenColors.warning.opacity(0.3), HavenColors.critical.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())

                    if let f = fair, range > 0 {
                        let fairPos = max(0, min(barWidth, CGFloat((f - low) / range) * barWidth))
                        Rectangle()
                            .fill(HavenColors.navy700)
                            .frame(width: 2, height: 14)
                            .offset(x: fairPos - 1)
                    }

                    if let q = quoted, range > 0 {
                        let pos = max(0, min(barWidth - 12, CGFloat((q - low) / range) * barWidth - 6))
                        Circle()
                            .fill(q > high ? HavenColors.critical : q < low ? HavenColors.success : HavenColors.navy700)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .offset(x: pos)
                    }
                }
            }
            .frame(height: 14)

            if let q = quoted {
                HStack(spacing: 4) {
                    Text("Quoted:")
                        .font(.system(size: 10))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("$\(Int(q).formatted())")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(q > high ? HavenColors.critical : q < low ? HavenColors.success : HavenColors.textPrimary)
                    if q > high {
                        Text("above range")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.critical)
                    } else if q < low {
                        Text("below range")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.success)
                    }
                }
            }
        }
    }

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

        // Prepare data: compress images, handle large PDFs with text extraction
        let (imageBase64, extractedText, prepError) = await DocumentAnalysisService.shared.prepareForQuoteAnalysis(data)
        if let prepError {
            self.error = prepError
            isAnalyzing = false
            return
        }

        do {
            let responseData = try await HavenSupabase.analyzeQuote(
                imageBase64: imageBase64,
                text: extractedText,
                projectName: project.name,
                projectCategory: project.category
            )

            if let rawString = String(data: responseData, encoding: .utf8) {
                print("[QuoteAnalysis] Raw response: \(rawString.prefix(500))")
            }

            struct AnalyzeResponse: Decodable {
                let analysis: QuoteAnalysis?
            }

            // Check for server-side errors first
            struct ErrorResponse: Decodable {
                let error: String?
                let detail: String?
            }
            if let errResp = try? JSONDecoder().decode(ErrorResponse.self, from: responseData),
               let serverError = errResp.error {
                print("[QuoteAnalysis] Server error: \(serverError), detail: \(errResp.detail ?? "none")")
                self.error = "Quote analysis failed: \(serverError)"
                isAnalyzing = false
                return
            }

            let response = try JSONDecoder().decode(AnalyzeResponse.self, from: responseData)
            guard let parsed = response.analysis else {
                self.error = "Couldn't parse the quote. Try uploading a clearer photo or PDF."
                isAnalyzing = false
                return
            }
            analysis = parsed
            Haptics.success()
            Analytics.track(.documentAIAnalysisCompleted, ["type": "quote", "items": analysis?.lineItems?.count ?? 0])

            // Auto-create vendor from quote if we got vendor info
            if let vendorName = analysis?.vendor?.name, !vendorName.isEmpty {
                let vendorInsert = ContractorInsert(
                    householdId: project.householdId,
                    companyName: vendorName,
                    phone: analysis?.vendor?.phone ?? "Not provided",
                    contactName: nil,
                    email: analysis?.vendor?.email,
                    address: analysis?.vendor?.address,
                    licenseNumber: analysis?.vendor?.license
                )
                _ = try? await DatabaseService.shared.createContractor(vendorInsert)
            }
        } catch {
            print("[QuoteAnalysis] Error: \(error)")
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
        }

        isAnalyzing = false
    }

}
