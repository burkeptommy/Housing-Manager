import Foundation

struct InvoiceProcessingResult: Codable {
    let vendor: InvoiceVendor?
    let invoiceDate: String?
    let invoiceNumber: String?
    let totalAmount: Double?
    let completedTasks: [InvoiceCompletedTask]
    let newSystemsDiscovered: [InvoiceNewSystem]
    let serviceSummary: String?
    let partsAndMaterials: [InvoicePart]?
    let followUpNeeded: [InvoiceFollowUp]?
    // Vehicle-specific fields (populated when vehicle_id is sent to process-invoice)
    let mileageReported: Int?
    let nextServiceSuggestions: [VehicleNextServiceSuggestion]?

    enum CodingKeys: String, CodingKey {
        case vendor
        case invoiceDate = "invoice_date"
        case invoiceNumber = "invoice_number"
        case totalAmount = "total_amount"
        case completedTasks = "completed_tasks"
        case newSystemsDiscovered = "new_systems_discovered"
        case serviceSummary = "service_summary"
        case partsAndMaterials = "parts_and_materials"
        case followUpNeeded = "follow_up_needed"
        case mileageReported = "mileage_reported"
        case nextServiceSuggestions = "next_service_suggestions"
    }
}

struct VehicleNextServiceSuggestion: Codable {
    let type: String
    let suggestedDate: String?
    let suggestedMileage: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case suggestedDate = "suggested_date"
        case suggestedMileage = "suggested_mileage"
    }
}

struct InvoiceVendor: Codable {
    let companyName: String?
    let phone: String?
    let email: String?
    let address: String?
    let matchedContractorId: String?

    enum CodingKeys: String, CodingKey {
        case companyName = "company_name"
        case phone, email, address
        case matchedContractorId = "matched_contractor_id"
    }
}

struct InvoiceCompletedTask: Codable, Identifiable {
    var id: String { matchedMaintenanceTaskId ?? description }
    let description: String
    let matchedMaintenanceTaskId: String?
    let matchedMaintenanceTaskTitle: String?
    let matchedSystemId: String?
    let matchedSystemName: String?
    let confidence: String

    enum CodingKeys: String, CodingKey {
        case description
        case matchedMaintenanceTaskId = "matched_maintenance_task_id"
        case matchedMaintenanceTaskTitle = "matched_maintenance_task_title"
        case matchedSystemId = "matched_system_id"
        case matchedSystemName = "matched_system_name"
        case confidence
    }
}

struct InvoiceNewSystem: Codable, Identifiable {
    var id: String { name + (suggestedCategory ?? "") }
    let name: String
    let suggestedCategory: String?
    let parentSystemName: String?
    let parentSystemId: String?
    let manufacturer: String?
    let modelNumber: String?
    let details: String?
    let installDate: String?

    enum CodingKeys: String, CodingKey {
        case name
        case suggestedCategory = "suggested_category"
        case parentSystemName = "parent_system_name"
        case parentSystemId = "parent_system_id"
        case manufacturer
        case modelNumber = "model_number"
        case details
        case installDate = "install_date"
    }
}

struct InvoicePart: Codable, Identifiable {
    var id: String { item }
    let item: String
    let quantity: Double?
    let unitCost: Double?
    let totalCost: Double?

    enum CodingKeys: String, CodingKey {
        case item, quantity
        case unitCost = "unit_cost"
        case totalCost = "total_cost"
    }
}

struct InvoiceFollowUp: Codable, Identifiable {
    var id: String { description }
    let description: String
    let urgency: String?
    let suggestedDueDate: String?

    enum CodingKeys: String, CodingKey {
        case description, urgency
        case suggestedDueDate = "suggested_due_date"
    }
}
