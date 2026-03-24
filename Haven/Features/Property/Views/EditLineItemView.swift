import SwiftUI

/// Edit or create a project line item — presented as .sheet.
struct EditLineItemView: View {
    let item: ProjectLineItemRow?
    let householdId: UUID
    let projectId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: String
    @State private var quantityText: String
    @State private var unit: String
    @State private var estimatedPriceText: String
    @State private var actualPriceText: String
    @State private var store: String
    @State private var isPurchased: Bool
    @State private var isOwned: Bool
    @State private var notes: String
    @State private var isSaving = false
    @State private var error: String?

    private var isEditing: Bool { item != nil }

    init(item: ProjectLineItemRow?, householdId: UUID, projectId: UUID, viewModel: ProjectsViewModel) {
        self.item = item
        self.householdId = householdId
        self.projectId = projectId
        self.viewModel = viewModel
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? "materials")
        _quantityText = State(initialValue: item?.quantity.map { String(format: "%.0f", $0) } ?? "1")
        _unit = State(initialValue: item?.unit ?? "each")
        _estimatedPriceText = State(initialValue: item?.estimatedUnitPrice.map { String(format: "%.2f", $0) } ?? "")
        _actualPriceText = State(initialValue: item?.actualUnitPrice.map { String(format: "%.2f", $0) } ?? "")
        _store = State(initialValue: item?.suggestedStore ?? "")
        _isPurchased = State(initialValue: item?.isPurchased ?? false)
        _isOwned = State(initialValue: item?.isOwned ?? false)
        _notes = State(initialValue: item?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(LineItemCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat.rawValue)
                        }
                    }
                }

                Section("Quantity & Price") {
                    HStack {
                        TextField("Qty", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        Picker("Unit", selection: $unit) {
                            ForEach(ItemUnit.allCases, id: \.self) { u in
                                Text(u.rawValue).tag(u.rawValue)
                            }
                        }
                    }
                    HStack {
                        Text("Est. Price")
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text("$")
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField("0.00", text: $estimatedPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Actual Price")
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text("$")
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField("0.00", text: $actualPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Details") {
                    TextField("Store", text: $store)
                    Toggle("Purchased", isOn: $isPurchased)
                        .tint(HavenColors.success)
                    Toggle("I Already Own This", isOn: $isOwned)
                        .tint(HavenColors.info)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(HavenColors.navy)
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(name.isEmpty)
                            .fontWeight(.semibold)
                    }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen(isEditing ? "EditLineItemView" : "AddLineItemView")
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            if let item {
                let updates = ProjectLineItemUpdate(
                    name: name,
                    category: category,
                    quantity: Double(quantityText),
                    unit: unit,
                    estimatedUnitPrice: Double(estimatedPriceText),
                    actualUnitPrice: Double(actualPriceText),
                    suggestedStore: store.isEmpty ? nil : store,
                    isPurchased: isPurchased,
                    isOwned: isOwned,
                    notes: notes.isEmpty ? nil : notes
                )
                try await viewModel.updateLineItem(id: item.id, updates)
            } else {
                let insert = ProjectLineItemInsert(
                    projectId: projectId,
                    householdId: householdId,
                    name: name,
                    category: category,
                    quantity: Double(quantityText) ?? 1,
                    unit: unit,
                    estimatedUnitPrice: Double(estimatedPriceText),
                    suggestedStore: store.isEmpty ? nil : store,
                    isPurchased: isPurchased,
                    notes: notes.isEmpty ? nil : notes
                )
                try await viewModel.addLineItem(insert)
            }
            try await viewModel.recalculateActualSpend(projectId: projectId)
            Haptics.success()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}
