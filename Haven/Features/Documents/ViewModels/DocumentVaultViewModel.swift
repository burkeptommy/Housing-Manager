import SwiftUI
import PDFKit

@MainActor
final class DocumentVaultViewModel: ObservableObject {
    @Published var documents: [DocumentRow] = []
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var searchText = ""
    @Published var deletedDocuments: [DocumentRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var dismissedCategories: Set<String> = []

    // Filter state
    @Published var filterCategory: DocumentCategory?
    @Published var filterStatus: String?
    @Published var filterFamilyMemberId: UUID?
    @Published var filterPropertyId: UUID?
    @Published var showAllCategories = false

    // Duplicate detection
    let duplicateService = DuplicateDetectionService.shared

    // Family member document links (for scroller readiness + filtering)
    @Published var documentFamilyMemberLinks: [DocumentFamilyMemberRow] = []

    // Bulk re-tag state
    @Published var isRetagging = false
    @Published var retagProgress: String?

    private let db = DatabaseService.shared

    var filteredDocuments: [DocumentRow] {
        documents.filter { doc in
            let matchesSearch = searchText.isEmpty ||
                doc.title.localizedCaseInsensitiveContains(searchText) ||
                doc.category.localizedCaseInsensitiveContains(searchText) ||
                (doc.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                (doc.aiSummary ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = filterCategory == nil || doc.category == filterCategory?.rawValue
            let matchesStatus = filterStatus == nil || doc.status == filterStatus
            let matchesMember: Bool = {
                guard let memberId = filterFamilyMemberId else { return true }
                let memberDocIds = Set(documentFamilyMemberLinks.filter { $0.familyMemberId == memberId }.map(\.documentId))
                return memberDocIds.contains(doc.id)
            }()
            return matchesSearch && matchesCategory && matchesStatus && matchesMember
        }
    }

    /// Documents grouped by section group, with categories inside each group
    var sectionGroups: [(String, [(DocumentCategory, [DocumentRow])])] {
        let allDocs = searchText.isEmpty && filterStatus == nil && filterFamilyMemberId == nil ? documents : filteredDocuments
        var result: [(String, [(DocumentCategory, [DocumentRow])])] = []

        for (groupName, categories) in DocumentCategory.groupedCategories {
            var categoryItems: [(DocumentCategory, [DocumentRow])] = []
            for cat in categories {
                let docs = allDocs.filter { $0.category == cat.rawValue }
                categoryItems.append((cat, docs))
            }
            // Only include groups that have at least one document or are core groups
            let hasDocuments = categoryItems.contains { !$0.1.isEmpty }
            if hasDocuments || searchText.isEmpty {
                result.append((groupName, categoryItems))
            }
        }
        return result
    }

    /// Section groups filtered to show only core groups + groups with documents (unless "show all" is on)
    var relevantSectionGroups: [(String, [(DocumentCategory, [DocumentRow])])] {
        if showAllCategories { return sectionGroups }

        let coreGroups: Set<String> = ["Estate Planning", "Insurance", "Real Estate", "Financial Accounts", "Personal Identification"]

        return sectionGroups.filter { group, categories in
            if coreGroups.contains(group) { return true }
            return categories.contains { _, docs in !docs.isEmpty }
        }
    }

    var hasHiddenGroups: Bool {
        sectionGroups.count != relevantSectionGroups.count
    }

    var totalDocumentCount: Int { documents.count }

    // MARK: - Weighted Readiness

    /// Category weights: critical docs count more toward readiness.
    static let categoryWeights: [String: Double] = [
        // Estate Planning (critical)
        "Will": 10, "Trust": 10, "Power of Attorney": 8, "Healthcare Directive": 8,
        "Guardianship Designation": 4, "Letter of Intent": 3,
        // Real Estate
        "Deed": 8, "Mortgage": 6, "Title Insurance": 5, "Homeowners Insurance": 7,
        "Survey": 2, "HOA Documents": 2, "Lease Agreement": 3, "Property Tax Records": 3,
        // Insurance (important)
        "Life Insurance": 8, "Auto Insurance": 5, "Umbrella Insurance": 4,
        "Long-Term Care Insurance": 4, "Disability Insurance": 3,
        "Jewelry/Art Rider": 1, "Directors & Officers Insurance": 1,
        // Financial
        "Beneficiary Designation": 7, "Retirement Account (IRA/401k)": 5,
        "Bank Account": 4, "Brokerage Account": 4, "529 Plan": 3,
        "Stock Options/RSUs": 2, "Crypto Wallet": 1, "Alternative Investments": 1,
        // Personal ID
        "Passport": 5, "Birth Certificate": 5, "Marriage Certificate": 4,
        "Social Security Card": 4, "Death Certificate": 2,
        "Divorce Decree": 2, "Citizenship/Immigration": 2,
        // Tax
        "Federal Tax Return": 5, "State Tax Return": 3,
        "Gift Tax Return (Form 709)": 2, "Property Tax Record": 2,
        "Estate & Trust Return (Form 1041)": 2,
    ]

    /// Weight for categories not explicitly listed
    private static let defaultWeight: Double = 1

    /// Core categories that count toward readiness (excludes Home Projects, Home Records, Home Financials by default)
    private static let coreGroups: Set<String> = [
        "Estate Planning", "Real Estate", "Insurance", "Financial Accounts",
        "Tax Records", "Personal Identification", "Entity Documents",
        "Personal Property", "Digital Assets", "Professional & Business"
    ]

    var completionPercentage: Double {
        let existingCategories = Set(documents.map(\.category))
        var earnedWeight = 0.0
        var totalWeight = 0.0

        for (_, categories) in DocumentCategory.groupedCategories {
            for cat in categories {
                let group = cat.sectionGroup
                // Skip non-core groups unless user has docs in them
                if !Self.coreGroups.contains(group) && !existingCategories.contains(cat.rawValue) {
                    continue
                }
                // Skip dismissed categories
                if dismissedCategories.contains(cat.rawValue) { continue }

                let weight = Self.categoryWeights[cat.rawValue] ?? Self.defaultWeight
                totalWeight += weight
                if existingCategories.contains(cat.rawValue) {
                    earnedWeight += weight
                }
            }
        }

        guard totalWeight > 0 else { return 0 }
        return earnedWeight / totalWeight
    }

    var missingCategories: [DocumentCategory] {
        let existingCategories = Set(documents.map(\.category))
        return DocumentCategory.allCases.filter {
            !existingCategories.contains($0.rawValue) && !dismissedCategories.contains($0.rawValue)
        }
    }

    var categoryScores: [CategoryScore] {
        let existingCategories = Set(documents.map(\.category))
        return DocumentCategory.groupedCategories.map { groupName, categories in
            let activeCategories = categories.filter { !dismissedCategories.contains($0.rawValue) }
            let filled = activeCategories.filter { existingCategories.contains($0.rawValue) }.count
            return CategoryScore(
                category: groupName,
                percentage: activeCategories.isEmpty ? 0 : Double(filled) / Double(activeCategories.count) * 100,
                actual: filled,
                expected: activeCategories.count
            )
        }
    }

    var expiringDocuments: [DocumentRow] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: .now)!

        return documents.filter { doc in
            guard let expStr = doc.expirationDate,
                  let expDate = dateFormatter.date(from: expStr) else { return false }
            return expDate <= thirtyDaysFromNow && expDate >= .now
        }
    }

    func loadData() async {
        isLoading = true
        error = nil
        do {
            async let docsTask = db.fetchDocuments()
            async let membersTask = db.fetchFamilyMembers()
            async let propsTask = db.fetchProperties()
            async let deletedTask = db.fetchDeletedDocuments()

            let (docs, members, props, deleted) = try await (docsTask, membersTask, propsTask, deletedTask)
            documents = docs
            familyMembers = members
            properties = props
            deletedDocuments = deleted

            let dismissed = (try? await db.fetchDismissedCategories()) ?? []
            dismissedCategories = Set(dismissed.map(\.category))

            // Fetch document-family member links for readiness + filtering
            let links = (try? await db.fetchAllDocumentFamilyMemberLinks()) ?? []
            documentFamilyMemberLinks = links

            // Run duplicate detection (instant — metadata-only, no network)
            duplicateService.scanForDuplicates(documents: docs)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteDocument(_ doc: DocumentRow) async {
        do {
            try await db.deleteDocument(id: doc.id)
            documents.removeAll { $0.id == doc.id }
            deletedDocuments.insert(doc, at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restoreDocument(_ doc: DocumentRow) async {
        do {
            try await db.restoreDocument(id: doc.id)
            deletedDocuments.removeAll { $0.id == doc.id }
            await loadData()
            Haptics.success()
        } catch {
            self.error = "Failed to restore: \(error.localizedDescription)"
        }
    }

    func permanentlyDeleteDocument(_ doc: DocumentRow) async {
        do {
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [doc.filePath])
            try await db.permanentlyDeleteDocument(id: doc.id)
            deletedDocuments.removeAll { $0.id == doc.id }
            Haptics.success()
        } catch {
            self.error = "Failed to delete: \(error.localizedDescription)"
        }
    }

    func documentsForCategory(_ category: DocumentCategory) -> [DocumentRow] {
        documents.filter { $0.category == category.rawValue }
    }

    func categoryDocCount(_ category: DocumentCategory) -> Int {
        documents.filter { $0.category == category.rawValue }.count
    }

    /// Documents whose category doesn't match any known DocumentCategory
    var uncategorizedDocuments: [DocumentRow] {
        let knownCategories = Set(DocumentCategory.allCases.map(\.rawValue))
        return documents.filter { !knownCategories.contains($0.category) }
    }

    /// Re-run AI analysis on a document to get a proper category
    func reanalyzeDocument(_ doc: DocumentRow) async {
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            // Download the file to get image data for analysis
            let url = try await db.getDocumentSignedURL(path: doc.filePath)
            let (data, _) = try await URLSession.shared.data(from: url)

            // Render as image for AI
            var imageData: Data?
            if doc.filePath.lowercased().hasSuffix(".pdf") {
                if let provider = CGDataProvider(data: data as CFData),
                   let pdf = CGPDFDocument(provider),
                   let page = pdf.page(at: 1) {
                    let pageRect = page.getBoxRect(.mediaBox)
                    let scale = min(1536 / pageRect.width, 1536 / pageRect.height, 2.0)
                    let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let image = renderer.image { ctx in
                        UIColor.white.setFill()
                        ctx.fill(CGRect(origin: .zero, size: size))
                        ctx.cgContext.translateBy(x: 0, y: size.height)
                        ctx.cgContext.scaleBy(x: scale, y: -scale)
                        ctx.cgContext.drawPDFPage(page)
                    }
                    imageData = image.jpegData(compressionQuality: 0.7)
                }
            } else {
                imageData = UIImage(data: data)?.jpegData(compressionQuality: 0.7)
            }

            let analysis = try await DocumentAnalysisService.shared.analyzeDocument(
                documentId: doc.id,
                imageData: imageData,
                category: "Unknown",
                householdId: householdId
            )

            // Match category
            let matched = DocumentCategory.allCases.first {
                $0.rawValue.lowercased() == analysis.categorySuggestion.lowercased()
            } ?? DocumentCategory.allCases.first {
                let s = analysis.categorySuggestion.lowercased()
                let r = $0.rawValue.lowercased()
                return r.contains(s) || s.contains(r)
            }

            let categoryValue = matched?.rawValue ?? analysis.categorySuggestion
            let aiTitle = analysis.extractedMetadata["title"]?.stringValue
                ?? analysis.extractedMetadata["document_title"]?.stringValue
                ?? categoryValue

            _ = try await db.updateDocument(id: doc.id, DocumentUpdate(
                title: aiTitle,
                category: categoryValue
            ))

            // Refresh
            await loadData()
            Haptics.success()
        } catch {
            self.error = "Re-analysis failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    /// Re-tag all documents: search extracted text, AI summaries, titles, parties,
    /// and the actual document file content for family member names.
    func retagAllDocuments() async {
        isRetagging = true
        retagProgress = "Loading document data..."

        let allParties = (try? await db.fetchAllDocumentParties()) ?? []
        let allContent = (try? await db.fetchAllDocumentContent()) ?? []
        let members = familyMembers
        var linkedCount = 0

        let currentLinks = (try? await db.fetchAllDocumentFamilyMemberLinks()) ?? []
        var linkedSet = Set(currentLinks.map { "\($0.documentId)|\($0.familyMemberId)" })

        let memberMatchers = members.map { MemberNameMatcher(member: $0) }
        let contentByDocId = Dictionary(grouping: allContent, by: \.documentId)
            .mapValues { $0.first?.extractedText ?? "" }

        print("[ReTag] Starting scan of \(documents.count) documents with \(members.count) family members")
        for matcher in memberMatchers {
            print("[ReTag] Member: \(matcher.member.firstName) \(matcher.member.lastName), legal: \(matcher.member.legalName ?? "none"), variants: \(matcher.nameVariants)")
        }

        for (index, doc) in documents.enumerated() {
            retagProgress = "Scanning \(index + 1) of \(documents.count)..."

            // Build searchable text from all available sources
            var textParts: [String] = []
            textParts.append(doc.title)
            if let summary = doc.aiSummary { textParts.append(summary) }

            let extractedContent = contentByDocId[doc.id] ?? ""
            if !extractedContent.isEmpty {
                textParts.append(extractedContent)
            }

            // Include party names
            let docParties = allParties.filter { $0.documentId == doc.id }
            for party in docParties {
                textParts.append(party.name)
            }

            // If no extracted content exists, try to download and extract text from the PDF
            if extractedContent.isEmpty && doc.aiSummary == nil && docParties.isEmpty {
                retagProgress = "Reading \(index + 1) of \(documents.count)..."
                if let pdfText = await extractTextFromDocument(doc) {
                    textParts.append(pdfText)
                }
            }

            let searchBlob = textParts.joined(separator: " ").lowercased()
            print("[ReTag] Doc '\(doc.title)': blob length=\(searchBlob.count), hasContent=\(!extractedContent.isEmpty), hasSummary=\(doc.aiSummary != nil), parties=\(docParties.count)")
            // For short blobs, print full content for debugging
            if searchBlob.count < 2000 {
                print("[ReTag] Full blob: \(searchBlob.prefix(1000))")
            } else {
                print("[ReTag] Blob preview: \(searchBlob.prefix(500))...")
            }

            // Match each family member
            for matcher in memberMatchers {
                let found = matcher.appearsIn(text: searchBlob)
                if found { print("[ReTag] MATCH: \(matcher.member.firstName) found in '\(doc.title)'") }
                if found {
                    let key = "\(doc.id)|\(matcher.member.id)"
                    if !linkedSet.contains(key) {
                        do {
                            try await db.linkDocumentToFamilyMember(
                                documentId: doc.id,
                                familyMemberId: matcher.member.id
                            )
                            linkedSet.insert(key)
                            linkedCount += 1
                            print("[ReTag] Linked \(matcher.member.firstName) to '\(doc.title)'")
                        } catch {
                            print("[ReTag] Failed to link \(matcher.member.firstName) to '\(doc.title)': \(error)")
                        }
                    }
                }
            }

            // Update unlinked party records
            for party in docParties where party.familyMemberId == nil {
                for matcher in memberMatchers {
                    if matcher.matches(name: party.name) {
                        try? await db.updateDocumentParty(
                            id: party.id,
                            DocumentPartyUpdate(familyMemberId: matcher.member.id)
                        )
                        break
                    }
                }
            }
        }

        retagProgress = "Done — \(linkedCount) new tag\(linkedCount == 1 ? "" : "s")"
        print("[ReTag] Complete: \(linkedCount) new links created")
        await loadData()
        Haptics.success()

        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isRetagging = false
        retagProgress = nil
    }

    /// Download a document and extract text from PDF for name matching.
    private func extractTextFromDocument(_ doc: DocumentRow) async -> String? {
        guard doc.vaultLocked != true else { return nil }
        do {
            let url = try await db.getDocumentSignedURL(path: doc.filePath)
            let (data, _) = try await URLSession.shared.data(from: url)

            if doc.filePath.lowercased().hasSuffix(".pdf") {
                // Extract text from PDF using PDFKit
                guard let provider = CGDataProvider(data: data as CFData),
                      let pdfDoc = CGPDFDocument(provider) else { return nil }

                var fullText = ""
                for pageNum in 1...pdfDoc.numberOfPages {
                    guard pdfDoc.page(at: pageNum) != nil else { continue }
                    // Use PDFKit for text extraction
                    if let pdfPage = PDFDocument(data: data)?.page(at: pageNum - 1) {
                        fullText += pdfPage.string ?? ""
                        fullText += " "
                    }
                }
                return fullText.isEmpty ? nil : fullText
            }
            return nil
        } catch {
            print("[ReTag] Failed to download \(doc.title): \(error)")
            return nil
        }
    }

    /// Builds all name variants for a family member and provides smart matching.
    private struct MemberNameMatcher {
        let member: FamilyMemberRow
        let nameVariants: [String]    // All possible full-name forms, lowercased
        let firstNames: [String]      // All first/given name tokens, lowercased
        let lastName: String          // Last name, lowercased

        init(member: FamilyMemberRow) {
            self.member = member
            self.lastName = member.lastName.lowercased()

            var firsts: [String] = [member.firstName.lowercased()]
            var variants: [String] = [
                "\(member.firstName) \(member.lastName)".lowercased()
            ]

            // Parse legal name into variants (e.g. "Thomas Patrick Burke")
            if let legal = member.legalName, !legal.isEmpty {
                let legalLower = legal.lowercased()
                variants.append(legalLower)

                let parts = legalLower.split(separator: " ").map(String.init)
                if parts.count >= 2 {
                    let legalFirst = parts[0]
                    let legalLast = parts[parts.count - 1]
                    firsts.append(legalFirst)

                    // "Thomas Burke" (first + last, no middle)
                    variants.append("\(legalFirst) \(legalLast)")

                    // Middle names as additional given names
                    if parts.count >= 3 {
                        // "Thomas P Burke" (first + middle initial + last)
                        for i in 1..<(parts.count - 1) {
                            let middleInitial = String(parts[i].prefix(1))
                            variants.append("\(legalFirst) \(middleInitial) \(legalLast)")
                            // Also just first + middle + last (already covered by full legal name)
                        }
                    }
                }
            }

            self.firstNames = Array(Set(firsts))
            self.nameVariants = Array(Set(variants))
        }

        /// Check if a party name matches this member.
        func matches(name: String) -> Bool {
            let target = name.lowercased().trimmingCharacters(in: .whitespaces)

            // Exact match against any variant
            for variant in nameVariants {
                if target == variant { return true }
            }

            // Target contains first name + last name (handles "Thomas Patrick Burke" matching "Thomas Burke")
            for first in firstNames {
                if target.contains(first) && target.contains(lastName) {
                    return true
                }
            }

            // Any variant is contained in the target (handles "Grantor: Thomas Patrick Burke" matching "Thomas Burke")
            for variant in nameVariants {
                if target.contains(variant) { return true }
            }

            return false
        }

        /// Check if this member's name appears anywhere in a block of text (title, summary).
        func appearsIn(text: String) -> Bool {
            for first in firstNames {
                if text.contains(first) && text.contains(lastName) {
                    return true
                }
            }
            for variant in nameVariants {
                if text.contains(variant) { return true }
            }
            return false
        }
    }

    /// Delete a document's file from storage and its DB record
    func deleteDocumentWithFile(_ doc: DocumentRow) async {
        do {
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [doc.filePath])
            try await db.deleteDocument(id: doc.id)
            documents.removeAll { $0.id == doc.id }
            Haptics.success()
        } catch {
            self.error = "Failed to delete: \(error.localizedDescription)"
        }
    }

    func dismissCategory(_ category: String) async {
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }
            try await db.dismissCategory(householdId: householdId, category: category)
            dismissedCategories.insert(category)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func undismissCategory(_ category: String) async {
        do {
            try await db.undismissCategory(category: category)
            dismissedCategories.remove(category)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Smart Suggestions

    struct DocumentSuggestion: Identifiable {
        let id = UUID()
        let category: DocumentCategory
        let reason: String
    }

    /// Prioritized list of the most important missing documents to upload next
    var suggestedNextUploads: [DocumentSuggestion] {
        let existing = Set(documents.map(\.category))
        var suggestions: [DocumentSuggestion] = []

        let priorities: [(DocumentCategory, String)] = [
            (.trust, "Designates who manages your estate"),
            (.will, "Ensures your wishes are carried out"),
            (.powerOfAttorney, "Authorizes someone to act on your behalf"),
            (.healthcareDirective, "Guides medical decisions if you can't"),
            (.homeownersInsurance, "Protects your home and belongings"),
            (.lifeInsurance, "Financial security for your family"),
            (.deed, "Proves ownership of your property"),
            (.mortgage, "Records your home loan details"),
            (.passport, "Primary identification document"),
            (.birthCertificate, "Essential identity record"),
            (.federalTaxReturn, "Most recent tax filing"),
            (.beneficiaryDesignation, "Controls who receives your accounts"),
            (.titleInsurance, "Protects your property title"),
            (.autoInsurance, "Required vehicle coverage"),
            (.retirementAccount, "Tracks your retirement savings"),
        ]

        for (cat, reason) in priorities {
            if !existing.contains(cat.rawValue) {
                suggestions.append(DocumentSuggestion(category: cat, reason: reason))
            }
            if suggestions.count >= 5 { break }
        }

        return suggestions
    }

    /// Whether the user is in "first-time" state (fewer than 5 documents)
    var isFirstTimeUser: Bool {
        documents.count < 5
    }

    /// Natural language readiness description
    // MARK: - Level System

    struct ReadinessLevel: Identifiable {
        let id: Int
        let name: String
        let icon: String
        let color: AvatarColor
        let threshold: Double   // Overall % needed to reach this level
        let description: String
    }

    static let levels: [ReadinessLevel] = [
        ReadinessLevel(id: 1, name: "Starter", icon: "leaf.fill", color: .navy, threshold: 0,
                       description: "Upload your core documents to build your safety net"),
        ReadinessLevel(id: 2, name: "Building Momentum", icon: "flame.fill", color: .coral, threshold: 0.20,
                       description: "Your essentials are coming together — keep going"),
        ReadinessLevel(id: 3, name: "Well Covered", icon: "bolt.fill", color: .teal, threshold: 0.45,
                       description: "You're ahead of most families"),
        ReadinessLevel(id: 4, name: "Fully Organized", icon: "star.fill", color: .amber, threshold: 0.70,
                       description: "Strong foundation — just a few finishing touches"),
        ReadinessLevel(id: 5, name: "Estate Master", icon: "checkmark.shield.fill", color: .sage, threshold: 0.90,
                       description: "Outstanding — your estate is fully protected"),
    ]

    var currentLevel: ReadinessLevel {
        let pct = completionPercentage
        return Self.levels.last(where: { pct >= $0.threshold }) ?? Self.levels[0]
    }

    var nextLevel: ReadinessLevel? {
        let current = currentLevel
        return Self.levels.first(where: { $0.threshold > current.threshold })
    }

    /// Progress within the current level (0.0 to 1.0)
    var levelProgress: Double {
        let pct = completionPercentage
        let current = currentLevel
        guard let next = nextLevel else { return 1.0 } // Max level
        let range = next.threshold - current.threshold
        guard range > 0 else { return 1.0 }
        return min((pct - current.threshold) / range, 1.0)
    }

    var readinessDescription: String { currentLevel.description }

    /// Top documents by weight that the user is missing — biggest impact first
    var highestImpactMissing: [(category: String, weight: Double)] {
        let existingCategories = Set(documents.map(\.category))
        return Self.categoryWeights
            .filter { !existingCategories.contains($0.key) && !dismissedCategories.contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (category: $0.key, weight: $0.value) }
    }

    var hasActiveFilters: Bool {
        filterCategory != nil || filterStatus != nil || filterFamilyMemberId != nil || filterPropertyId != nil
    }

    func clearFilters() {
        filterCategory = nil
        filterStatus = nil
        filterFamilyMemberId = nil
        filterPropertyId = nil
    }

    /// Calculate document coverage readiness for a specific family member
    func memberReadiness(for memberId: UUID) -> Double {
        let memberDocIds = documentFamilyMemberLinks
            .filter { $0.familyMemberId == memberId }
            .map(\.documentId)
        let memberDocs = documents.filter { memberDocIds.contains($0.id) }
        let coveredCategories = Set(memberDocs.map(\.category))
        let expectedCategories = 8.0
        return min(Double(coveredCategories.count) / expectedCategories, 1.0)
    }
}
