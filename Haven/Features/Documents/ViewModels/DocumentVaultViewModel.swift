import SwiftUI

@MainActor
final class DocumentVaultViewModel: ObservableObject {
    @Published var documents: [DocumentRow] = []
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?

    // Filter state
    @Published var filterCategory: DocumentCategory?
    @Published var filterStatus: String?
    @Published var filterFamilyMemberId: UUID?
    @Published var filterPropertyId: UUID?

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
            return matchesSearch && matchesCategory && matchesStatus
        }
    }

    /// Documents grouped by section group, with categories inside each group
    var sectionGroups: [(String, [(DocumentCategory, [DocumentRow])])] {
        let allDocs = searchText.isEmpty && filterStatus == nil ? documents : filteredDocuments
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

    var totalDocumentCount: Int { documents.count }

    var completionPercentage: Double {
        let totalCategories = DocumentCategory.allCases.count
        guard totalCategories > 0 else { return 0 }
        let categoriesWithDocs = Set(documents.map(\.category)).count
        return Double(categoriesWithDocs) / Double(totalCategories)
    }

    var missingCategories: [DocumentCategory] {
        let existingCategories = Set(documents.map(\.category))
        return DocumentCategory.allCases.filter { !existingCategories.contains($0.rawValue) }
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

            let (docs, members, props) = try await (docsTask, membersTask, propsTask)
            documents = docs
            familyMembers = members
            properties = props
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteDocument(_ doc: DocumentRow) async {
        do {
            try await db.deleteDocument(id: doc.id)
            documents.removeAll { $0.id == doc.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func documentsForCategory(_ category: DocumentCategory) -> [DocumentRow] {
        documents.filter { $0.category == category.rawValue }
    }

    func categoryDocCount(_ category: DocumentCategory) -> Int {
        documents.filter { $0.category == category.rawValue }.count
    }

    func clearFilters() {
        filterCategory = nil
        filterStatus = nil
        filterFamilyMemberId = nil
        filterPropertyId = nil
    }
}
