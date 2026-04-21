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
    /// Phase 50: Explicit recurring cadence detected on the invoice. Only
    /// populated when the invoice itself states the cadence (e.g. "monthly
    /// service plan") with confidence > 0.8. Used to surface a Dashboard
    /// suggestion card so the user can confirm and update the linked
    /// system's `service_interval_days`.
    let cadenceDetected: InvoiceCadenceDetected?
    /// Phase 52b: When the invoice implies a specialty system the household
    /// hasn't registered (e.g. a pool heater invoice when no Pool system
    /// exists), the server returns this suggestion for one-tap confirmation.
    let specialtySystemSuggestion: SpecialtySystemSuggestion?
    /// Phase 59: Structured vendor match. When confidence is "high" the
    /// iOS client silently files the document. When medium/low/ambiguous,
    /// the invoice review surface offers candidate chips so the user can
    /// pick the right vendor without typing.
    let vendorMatch: InvoiceVendorMatch?

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
        case cadenceDetected = "cadence_detected"
        case specialtySystemSuggestion = "specialty_system_suggestion"
        case vendorMatch = "vendor_match"
    }
}

/// Phase 59: vendor match metadata returned by process-invoice.
struct InvoiceVendorMatch: Codable {
    let contractorId: String?
    let confidence: String // "high" | "medium" | "low" | "ambiguous"
    let extractedName: String?
    let candidates: [InvoiceVendorCandidate]?

    enum CodingKeys: String, CodingKey {
        case contractorId = "contractor_id"
        case confidence
        case extractedName = "extracted_name"
        case candidates
    }
}

struct InvoiceVendorCandidate: Codable, Identifiable {
    var id: String { contractorId }
    let contractorId: String
    let name: String
    let score: Double

    enum CodingKeys: String, CodingKey {
        case contractorId = "contractor_id"
        case name
        case score
    }
}

struct InvoiceCadenceDetected: Codable {
    let intervalDays: Int?
    let confidence: Double?
    let quotedText: String?

    enum CodingKeys: String, CodingKey {
        case intervalDays = "interval_days"
        case confidence
        case quotedText = "quoted_text"
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

/// Phase 52b: Specialty system suggestion surfaced by the server when an
/// invoice or document implies a system the household hasn't registered.
struct SpecialtySystemSuggestion: Codable {
    let category: String
    let displayName: String
    let subtypeHint: String?
    let evidence: String
    let source: String  // "invoice" | "document"

    enum CodingKeys: String, CodingKey {
        case category
        case displayName = "display_name"
        case subtypeHint = "subtype_hint"
        case evidence
        case source
    }
}
