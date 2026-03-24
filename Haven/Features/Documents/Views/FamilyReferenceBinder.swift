import SwiftUI
import PDFKit

struct FamilyReferenceBinder: View {
    @StateObject private var viewModel = BinderViewModel()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    generatingView
                } else if let url = pdfURL {
                    pdfPreview(url)
                } else {
                    promptView
                }
            }
            .navigationTitle("Family Binder")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("FamilyReferenceBinder")
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var promptView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.navy)

            VStack(spacing: 8) {
                Text("Family Reference Binder")
                    .font(HavenTypography.title2)
                Text("Generate a comprehensive PDF of your estate and property portfolio, organized by section for easy reference.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 8) {
                binderSection(icon: "list.bullet", text: "Table of Contents")
                binderSection(icon: "person.2", text: "Family Member Directory")
                binderSection(icon: "doc.text", text: "Estate Planning Summary")
                binderSection(icon: "folder", text: "Document Inventory")
                binderSection(icon: "house", text: "Property Portfolio")
                binderSection(icon: "shield", text: "Insurance & Warranties")
                binderSection(icon: "banknote", text: "Financial Accounts")
                binderSection(icon: "person.crop.rectangle", text: "Key Contacts")
                binderSection(icon: "chart.bar", text: "Gap Analysis")
                binderSection(icon: "checklist", text: "Document Checklist")
            }
            .padding(.horizontal, 40)

            Button {
                Task { await generatePDF() }
            } label: {
                HStack {
                    Image(systemName: "doc.richtext")
                    Text("Generate PDF")
                }
                .font(HavenTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HavenColors.navy)
                .foregroundStyle(HavenColors.textOnNavy)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            if let error = viewModel.error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            Spacer()
        }
    }

    private func binderSection(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(HavenColors.navy)
                .frame(width: 20)
            Text(text)
                .font(HavenTypography.bodySmall)
        }
    }

    private var generatingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating your binder...")
                .font(HavenTypography.headline)
            Text("Compiling \(viewModel.statusText)")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
        }
    }

    private func pdfPreview(_ url: URL) -> some View {
        VStack(spacing: 0) {
            PDFViewRepresentable(url: url)

            HStack(spacing: 16) {
                Button {
                    Analytics.track(.familyBinderExported)
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    pdfURL = nil
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.inputBackground)
                    .foregroundStyle(HavenColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .font(HavenTypography.uiLabel)
            .padding()
        }
    }

    private func generatePDF() async {
        Analytics.track(.familyBinderViewed)
        await viewModel.loadAllData()
        if let url = viewModel.generatePDF() {
            pdfURL = url
        }
    }
}

// MARK: - PDF View

struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Binder ViewModel

@MainActor
final class BinderViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var statusText = ""
    @Published var error: String?

    private var familyMembers: [FamilyMemberRow] = []
    private var documents: [DocumentRow] = []
    private var properties: [PropertyRow] = []
    private var contractors: [ContractorRow] = []
    private var warranties: [WarrantyRow] = []
    private var maintenanceTasks: [MaintenanceTaskDBRow] = []

    private let db = DatabaseService.shared

    func loadAllData() async {
        isGenerating = true
        statusText = "family members..."
        do {
            familyMembers = try await db.fetchFamilyMembers()
            statusText = "documents..."
            documents = try await db.fetchDocuments()
            statusText = "properties..."
            properties = try await db.fetchProperties()
            statusText = "contractors..."
            contractors = try await db.fetchContractors()
            statusText = "warranties..."
            warranties = try await db.fetchWarranties()
            statusText = "maintenance tasks..."
            maintenanceTasks = try await db.fetchMaintenanceTasks()
            statusText = "generating PDF..."
        } catch {
            self.error = error.localizedDescription
            isGenerating = false
        }
    }

    func generatePDF() -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Haven_Family_Binder.pdf")

        do {
            // Apply NSFileProtectionComplete to the temp directory for this file
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: FileManager.default.temporaryDirectory.path
            )

            try renderer.writePDF(to: tempURL) { context in
                // 1. Cover Page
                drawCoverPage(context)

                // 2. Table of Contents
                drawTOC(context)

                // 3. Family Directory
                drawFamilyDirectory(context)

                // 4. Estate Planning Summary
                drawEstatePlanning(context)

                // 5. Document Inventory
                drawDocumentInventory(context)

                // 6. Property Portfolio
                drawPropertyPortfolio(context)

                // 7. Insurance Coverage
                drawInsuranceCoverage(context)

                // 8. Key Contacts
                drawKeyContacts(context)

                // 9. Gap Analysis
                drawGapAnalysis(context)

                // 10. Document Checklist
                drawDocumentChecklist(context)
            }
            isGenerating = false
            return tempURL
        } catch {
            self.error = error.localizedDescription
            isGenerating = false
            return nil
        }
    }

    // MARK: - PDF Drawing Helpers

    private let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    private let headerFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    private let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    private let captionFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    private let margin: CGFloat = 50

    private func drawCoverPage(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        let title = "Family Reference Binder"
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 32, weight: .bold)]
        title.draw(at: CGPoint(x: margin, y: 280), withAttributes: attrs)

        let subtitle = "Prepared by Haven"
        let subAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.secondaryLabel]
        subtitle.draw(at: CGPoint(x: margin, y: 330), withAttributes: subAttrs)

        let dateStr = Date().formatted(date: .long, time: .omitted)
        let dateAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel]
        dateStr.draw(at: CGPoint(x: margin, y: 360), withAttributes: dateAttrs)
    }

    private func drawTOC(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Table of Contents", at: margin, y: margin)
        let items = [
            "1. Family Member Directory",
            "2. Estate Planning Summary",
            "3. Document Inventory by Category",
            "4. Property Portfolio Summary",
            "5. Insurance Coverage Summary",
            "6. Key Contacts",
            "7. Gap Analysis & Recommendations",
            "8. Document Checklist"
        ]
        var y: CGFloat = margin + 50
        for item in items {
            item.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: bodyFont])
            y += 24
        }
    }

    private func drawFamilyDirectory(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Family Member Directory", at: margin, y: margin)
        var y: CGFloat = margin + 50

        for member in familyMembers {
            let line = "\(member.firstName) \(member.lastName) - \(member.relationship)"
            line.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont])
            y += 20
            if let email = member.email {
                "  Email: \(email)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                y += 16
            }
            if let phone = member.phone {
                "  Phone: \(phone)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                y += 16
            }
            y += 8
            if y > 740 { context.beginPage(); y = margin }
        }
    }

    private func drawEstatePlanning(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Estate Planning Summary", at: margin, y: margin)
        var y: CGFloat = margin + 50

        let estateDocs = documents.filter { doc in
            ["Will", "Trust", "Power of Attorney", "Healthcare Directive", "Guardianship Designation", "Letter of Intent"].contains(doc.category)
        }

        if estateDocs.isEmpty {
            "No estate planning documents uploaded yet.".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
        } else {
            for doc in estateDocs {
                doc.title.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont])
                y += 18
                let detail = "Category: \(doc.category) | Status: \(doc.status)"
                detail.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                y += 16
                if let summary = doc.aiSummary, !summary.isEmpty {
                    let truncated = String(summary.prefix(200))
                    truncated.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont])
                    y += 24
                }
                y += 8
                if y > 740 { context.beginPage(); y = margin }
            }
        }
    }

    private func drawDocumentInventory(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Document Inventory", at: margin, y: margin)
        var y: CGFloat = margin + 50

        for (group, categories) in DocumentCategory.groupedCategories {
            let docsInGroup = documents.filter { doc in categories.contains { $0.rawValue == doc.category } }
            group.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: headerFont])
            y += 28

            if docsInGroup.isEmpty {
                "  No documents in this section".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                y += 20
            } else {
                for doc in docsInGroup {
                    let check = "\u{2713} \(doc.title) (\(doc.category))"
                    check.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: bodyFont])
                    y += 18
                    if y > 740 { context.beginPage(); y = margin }
                }
            }
            y += 10
            if y > 740 { context.beginPage(); y = margin }
        }
    }

    private func drawPropertyPortfolio(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Property Portfolio", at: margin, y: margin)
        var y: CGFloat = margin + 50

        if properties.isEmpty {
            "No properties added yet.".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
        } else {
            for prop in properties {
                prop.name.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
                y += 20
                let addr = [prop.street, prop.city, prop.state].compactMap { $0 }.joined(separator: ", ")
                if !addr.isEmpty {
                    addr.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                    y += 16
                }
                "Type: \(prop.propertyType)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont])
                y += 24
                if y > 740 { context.beginPage(); y = margin }
            }
        }
    }

    private func drawInsuranceCoverage(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Insurance & Warranty Coverage", at: margin, y: margin)
        var y: CGFloat = margin + 50

        let insuranceDocs = documents.filter { doc in
            doc.category.contains("Insurance")
        }

        if !insuranceDocs.isEmpty {
            "Insurance Policies:".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
            y += 22
            for doc in insuranceDocs {
                "\u{2022} \(doc.title)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: bodyFont])
                y += 18
            }
            y += 10
        }

        if !warranties.isEmpty {
            "Active Warranties:".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
            y += 22
            for w in warranties {
                "\u{2022} \(w.provider) (\(w.warrantyType)) - Expires: \(w.endDate)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: bodyFont])
                y += 18
                if y > 740 { context.beginPage(); y = margin }
            }
        }

        if insuranceDocs.isEmpty && warranties.isEmpty {
            "No insurance documents or warranties found.".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
        }
    }

    private func drawKeyContacts(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Key Contacts", at: margin, y: margin)
        var y: CGFloat = margin + 50

        if contractors.isEmpty {
            "No contractors or service providers added yet.".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.secondaryLabel])
        } else {
            for contractor in contractors {
                contractor.companyName.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
                y += 20
                "  Phone: \(contractor.phone)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont])
                y += 16
                if let email = contractor.email {
                    "  Email: \(email)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont])
                    y += 16
                }
                if let specs = contractor.specialties, !specs.isEmpty {
                    "  Specialties: \(specs.joined(separator: ", "))".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: captionFont, .foregroundColor: UIColor.secondaryLabel])
                    y += 16
                }
                y += 10
                if y > 740 { context.beginPage(); y = margin }
            }
        }
    }

    private func drawGapAnalysis(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Gap Analysis & Recommendations", at: margin, y: margin)
        var y: CGFloat = margin + 50

        let existingCategories = Set(documents.map(\.category))
        let missingCategories = DocumentCategory.allCases.filter { !existingCategories.contains($0.rawValue) }

        let totalCats = DocumentCategory.allCases.count
        let filledCats = existingCategories.count
        let percentage = Int(Double(filledCats) / Double(totalCats) * 100)

        "Estate Readiness: \(percentage)% (\(filledCats)/\(totalCats) categories covered)".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
        y += 30

        if !missingCategories.isEmpty {
            "Missing Documents:".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
            y += 22

            for cat in missingCategories.prefix(30) {
                "\u{25CB} \(cat.rawValue) (\(cat.sectionGroup))".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: [.font: bodyFont])
                y += 18
                if y > 740 { context.beginPage(); y = margin }
            }
        }
    }

    private func drawDocumentChecklist(_ context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        drawSectionTitle("Document Checklist", at: margin, y: margin)
        var y: CGFloat = margin + 50

        let existingCategories = Set(documents.map(\.category))

        for (group, categories) in DocumentCategory.groupedCategories {
            group.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .semibold)])
            y += 22

            for cat in categories {
                let hasDoc = existingCategories.contains(cat.rawValue)
                let symbol = hasDoc ? "\u{2713}" : "\u{25CB}"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: hasDoc ? UIColor.label : UIColor.secondaryLabel
                ]
                "\(symbol) \(cat.rawValue)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: attrs)
                y += 16
                if y > 740 { context.beginPage(); y = margin }
            }
            y += 6
            if y > 740 { context.beginPage(); y = margin }
        }
    }

    private func drawSectionTitle(_ title: String, at x: CGFloat, y: CGFloat) {
        title.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: titleFont])
        let underline = UIBezierPath()
        underline.move(to: CGPoint(x: x, y: y + 32))
        underline.addLine(to: CGPoint(x: 562, y: y + 32))
        UIColor.systemGray4.setStroke()
        underline.lineWidth = 1
        underline.stroke()
    }
}

#Preview {
    FamilyReferenceBinder()
}
