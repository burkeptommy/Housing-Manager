import SwiftUI

@MainActor
final class PropertyListViewModel: ObservableObject {
    @Published var properties: [PropertyRow] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = DatabaseService.shared

    func loadProperties() async {
        isLoading = true
        do {
            properties = try await db.fetchProperties()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteProperty(_ property: PropertyRow) async {
        do {
            try await db.deleteProperty(id: property.id)
            properties.removeAll { $0.id == property.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
