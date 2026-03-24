import SwiftUI

struct EditDocumentDetailsView: View {
    let document: DocumentRow
    var onSave: ((DocumentRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: String
    @State private var selectedCategory: DocumentCategory?
    @State private var issuingInstitution: String
    @State private var accountNumberLast4: String
    @State private var hasEffectiveDate: Bool
    @State private var effectiveDate: Date
    @State private var hasExpirationDate: Bool
    @State private var expirationDate: Date
    @State private var hasRenewalDate: Bool
    @State private var renewalDate: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var error: String?

    init(document: DocumentRow, onSave: ((DocumentRow) -> Void)? = nil) {
        self.document = document
        self.onSave = onSave
        _title = State(initialValue: document.title)
        _category = State(initialValue: document.category)
        _selectedCategory = State(initialValue: DocumentCategory(rawValue: document.category))
        _issuingInstitution = State(initialValue: document.issuingInstitution ?? "")
        _accountNumberLast4 = State(initialValue: document.accountNumberLast4 ?? "")
        _notes = State(initialValue: document.notes ?? "")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        _hasEffectiveDate = State(initialValue: document.effectiveDate != nil)
        _effectiveDate = State(initialValue: document.effectiveDate.flatMap { dateFormatter.date(from: $0) } ?? Date())
        _hasExpirationDate = State(initialValue: document.expirationDate != nil)
        _expirationDate = State(initialValue: document.expirationDate.flatMap { dateFormatter.date(from: $0) } ?? Date())
        _hasRenewalDate = State(initialValue: document.renewalDate != nil)
        _renewalDate = State(initialValue: document.renewalDate.flatMap { dateFormatter.date(from: $0) } ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Title", text: $title)

                    Picker("Category", selection: $selectedCategory) {
                        Text("Custom").tag(nil as DocumentCategory?)
                        ForEach(DocumentCategory.groupedCategories, id: \.0) { group, categories in
                            Section(group) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat as DocumentCategory?)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedCategory) { _, newValue in
                        if let newValue {
                            category = newValue.rawValue
                        }
                    }
                }

                Section("Issuing Information") {
                    TextField("Issuing Institution", text: $issuingInstitution)
                    SecureField("Account # (last 4)", text: $accountNumberLast4)
                        .keyboardType(.numberPad)
                }

                Section("Dates") {
                    Toggle("Effective Date", isOn: $hasEffectiveDate)
                        .tint(HavenColors.navy800)
                    if hasEffectiveDate {
                        DatePicker("Effective", selection: $effectiveDate, displayedComponents: .date)
                    }
                    Toggle("Expiration Date", isOn: $hasExpirationDate)
                        .tint(HavenColors.navy800)
                    if hasExpirationDate {
                        DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date)
                    }
                    Toggle("Renewal Date", isOn: $hasRenewalDate)
                        .tint(HavenColors.navy800)
                    if hasRenewalDate {
                        DatePicker("Renewal", selection: $renewalDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(HavenColors.critical).font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("EditDocumentDetailsView")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        Analytics.track(.documentEdited, ["document_id": document.id.uuidString, "source": "edit_details_save"])
        isSaving = true
        error = nil
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            let update = DocumentUpdate(
                title: title,
                category: category,
                expirationDate: hasExpirationDate ? dateFormatter.string(from: expirationDate) : nil,
                renewalDate: hasRenewalDate ? dateFormatter.string(from: renewalDate) : nil,
                effectiveDate: hasEffectiveDate ? dateFormatter.string(from: effectiveDate) : nil,
                issuingInstitution: issuingInstitution.isEmpty ? nil : issuingInstitution,
                accountNumberLast4: accountNumberLast4.isEmpty ? nil : accountNumberLast4,
                notes: notes.isEmpty ? nil : notes
            )
            let updated = try await DatabaseService.shared.updateDocument(id: document.id, update)
            onSave?(updated)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
