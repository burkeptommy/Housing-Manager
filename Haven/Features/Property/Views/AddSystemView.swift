import SwiftUI

struct AddSystemView: View {
    let propertyID: UUID
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "HVAC"
    @State private var manufacturer = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var installDate = Date()
    @State private var hasInstallDate = false
    @State private var expectedLifespan = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var addMaintenanceTemplates = true

    private let categories = SystemCategory.allCases.map(\.rawValue)

    var body: some View {
        NavigationStack {
            Form {
                Section("System Info") {
                    TextField("Name (e.g. Main HVAC Unit)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Details") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }

                Section("Installation") {
                    Toggle("Has Install Date", isOn: $hasInstallDate)
                    if hasInstallDate {
                        DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                    }
                    TextField("Expected Lifespan (years)", text: $expectedLifespan)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("Add Maintenance Templates", isOn: $addMaintenanceTemplates)
                } footer: {
                    Text("Automatically create maintenance tasks based on the system category.")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }

            let insert = HomeSystemInsert(
                propertyId: propertyID,
                householdId: householdId,
                name: name,
                category: category,
                manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                modelNumber: modelNumber.isEmpty ? nil : modelNumber,
                serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                installDate: hasInstallDate ? formatter.string(from: installDate) : nil,
                expectedLifespanYears: Int(expectedLifespan),
                status: "Good",
                notes: notes.isEmpty ? nil : notes
            )

            let system = try await DatabaseService.shared.createHomeSystem(insert)

            // Add maintenance templates
            if addMaintenanceTemplates {
                let templates = MaintenanceTemplates.templates(for: category)
                for template in templates {
                    let nextDue = Calendar.current.date(byAdding: template.interval, to: .now)!
                    let taskInsert = MaintenanceTaskInsert(
                        propertyId: propertyID,
                        householdId: householdId,
                        title: template.title,
                        frequency: template.frequency,
                        nextDueDate: formatter.string(from: nextDue),
                        systemId: system.id,
                        description: template.description,
                        priority: template.priority
                    )
                    _ = try await DatabaseService.shared.createMaintenanceTask(taskInsert)
                }
            }

            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Maintenance Templates

enum MaintenanceTemplates {
    struct Template {
        let title: String
        let description: String
        let frequency: String
        let priority: String
        let interval: DateComponents
    }

    static func templates(for category: String) -> [Template] {
        switch category {
        case "HVAC":
            return [
                Template(title: "Replace HVAC Filter", description: "Replace air filter for optimal airflow and air quality.", frequency: "Monthly", priority: "Medium", interval: DateComponents(month: 1)),
                Template(title: "Professional HVAC Service", description: "Schedule professional inspection and tune-up.", frequency: "Semi-Annually", priority: "High", interval: DateComponents(month: 6)),
            ]
        case "Water Heater":
            return [
                Template(title: "Flush Water Heater", description: "Drain and flush sediment from tank.", frequency: "Annually", priority: "Medium", interval: DateComponents(year: 1)),
                Template(title: "Check Anode Rod", description: "Inspect and replace anode rod if corroded.", frequency: "Every 2 Years", priority: "Medium", interval: DateComponents(year: 3)),
            ]
        case "Roofing":
            return [
                Template(title: "Roof Inspection", description: "Professional roof inspection for damage or wear.", frequency: "Annually", priority: "High", interval: DateComponents(year: 1)),
                Template(title: "Clean Gutters", description: "Clear gutters and downspouts of debris.", frequency: "Semi-Annually", priority: "Medium", interval: DateComponents(month: 6)),
            ]
        case "Plumbing":
            return [
                Template(title: "Check for Leaks", description: "Inspect visible pipes and fixtures for leaks.", frequency: "Quarterly", priority: "Medium", interval: DateComponents(month: 3)),
            ]
        case "Electrical":
            return [
                Template(title: "Test Smoke Detectors", description: "Test all smoke and CO detectors, replace batteries.", frequency: "Semi-Annually", priority: "High", interval: DateComponents(month: 6)),
                Template(title: "Inspect Electrical Panel", description: "Professional inspection of electrical panel and wiring.", frequency: "Annually", priority: "Medium", interval: DateComponents(year: 1)),
            ]
        case "Pool/Spa":
            return [
                Template(title: "Pool Chemical Balance", description: "Test and adjust pool water chemistry.", frequency: "Monthly", priority: "Medium", interval: DateComponents(month: 1)),
                Template(title: "Pool Filter Clean", description: "Clean or backwash pool filter.", frequency: "Quarterly", priority: "Medium", interval: DateComponents(month: 3)),
            ]
        case "Appliance":
            return [
                Template(title: "Clean Appliance Filters", description: "Clean or replace filters in dishwasher, dryer, etc.", frequency: "Quarterly", priority: "Low", interval: DateComponents(month: 3)),
            ]
        case "Septic System":
            return [
                Template(title: "Septic Tank Pumping", description: "Professional septic tank pumping and inspection.", frequency: "Every 2 Years", priority: "High", interval: DateComponents(year: 3)),
            ]
        case "Generator":
            return [
                Template(title: "Generator Test Run", description: "Run generator for 30 minutes under load.", frequency: "Monthly", priority: "Medium", interval: DateComponents(month: 1)),
                Template(title: "Generator Professional Service", description: "Oil change, filter replacement, full inspection.", frequency: "Annually", priority: "High", interval: DateComponents(year: 1)),
            ]
        case "Security System":
            return [
                Template(title: "Test Security System", description: "Test all sensors, cameras, and alarm functions.", frequency: "Quarterly", priority: "High", interval: DateComponents(month: 3)),
            ]
        case "Irrigation":
            return [
                Template(title: "Irrigation System Check", description: "Check heads, valves, and coverage. Adjust timers.", frequency: "Seasonal", priority: "Low", interval: DateComponents(month: 3)),
                Template(title: "Winterize Irrigation", description: "Blow out lines before freezing temperatures.", frequency: "Annually", priority: "High", interval: DateComponents(year: 1)),
            ]
        case "Solar":
            return [
                Template(title: "Clean Solar Panels", description: "Remove dust, debris, and bird droppings from panels.", frequency: "Semi-Annually", priority: "Medium", interval: DateComponents(month: 6)),
                Template(title: "Solar System Inspection", description: "Professional inspection of inverter, wiring, and output.", frequency: "Annually", priority: "Medium", interval: DateComponents(year: 1)),
            ]
        default:
            return [
                Template(title: "General Inspection", description: "Inspect system for proper operation and signs of wear.", frequency: "Annually", priority: "Medium", interval: DateComponents(year: 1)),
            ]
        }
    }
}

#Preview {
    AddSystemView(propertyID: UUID())
}
