import SwiftUI
import ContactsUI

struct TrustedContactFormView: View {
    @ObservedObject var viewModel: TrustedContactsViewModel
    var editingContact: TrustedContactRow?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role = "other"
    @State private var company = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showContactPicker = false
    @State private var formError: String?

    private var isEditing: Bool { editingContact != nil }

    private let roleOptions = [
        ("estate_attorney", "Estate Attorney"),
        ("executor", "Executor"),
        ("financial_advisor", "Financial Advisor"),
        ("trustee", "Trustee"),
        ("accountant", "Accountant"),
        ("insurance_agent", "Insurance Agent"),
        ("family", "Family Member"),
        ("other", "Other"),
    ]

    var body: some View {
        Form {
            // Import from contacts
            if !isEditing {
                Section {
                    Button {
                        showContactPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.title3)
                                .foregroundStyle(HavenColors.navy)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from Contacts")
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Auto-fill name, email, and phone")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                } header: {
                    Text("QUICK ADD")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                }
            }

            Section {
                TextField("Full Name", text: $name)
                    .font(HavenTypography.body)
                TextField("Email", text: $email)
                    .font(HavenTypography.body)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .font(HavenTypography.body)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            } header: {
                Text("CONTACT INFO")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                Picker("Role", selection: $role) {
                    ForEach(roleOptions, id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                .font(HavenTypography.body)

                TextField("Company / Firm", text: $company)
                    .font(HavenTypography.body)
            } header: {
                Text("ROLE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }

            Section {
                TextEditor(text: $notes)
                    .font(HavenTypography.body)
                    .frame(minHeight: 60)
            } header: {
                Text("NOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle(isEditing ? "Edit Contact" : "Add Trusted Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || isSaving)
                .fontWeight(.semibold)
            }
        }
        .trackScreen(editingContact != nil ? "TrustedContactEditView" : "TrustedContactAddView")
        .onAppear {
            if let contact = editingContact {
                name = contact.name
                email = contact.email
                phone = contact.phone ?? ""
                role = contact.role
                company = contact.company ?? ""
                notes = contact.notes ?? ""
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerWrapper { contact in
                if let fullName = contact.fullName {
                    name = fullName
                }
                if let emailAddr = contact.email {
                    email = emailAddr
                }
                if let phoneNum = contact.phone {
                    phone = phoneNum
                }
                if let org = contact.organization, !org.isEmpty {
                    company = org
                }
            }
        }
        .alert("Error", isPresented: .constant(formError != nil)) {
            Button("OK") { formError = nil }
        } message: {
            if let formError { Text(formError) }
        }
    }

    private func save() async {
        isSaving = true
        if let contact = editingContact {
            await viewModel.updateContact(id: contact.id, TrustedContactUpdate(
                name: name,
                email: email,
                phone: phone.isEmpty ? nil : phone,
                role: role,
                company: company.isEmpty ? nil : company,
                notes: notes.isEmpty ? nil : notes
            ))
        } else {
            let user = try? await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user?.householdId else {
                formError = "No household found"
                isSaving = false
                return
            }
            await viewModel.createContact(TrustedContactInsert(
                householdId: householdId,
                name: name,
                email: email,
                role: role,
                phone: phone.isEmpty ? nil : phone,
                company: company.isEmpty ? nil : company,
                notes: notes.isEmpty ? nil : notes
            ))
        }
        Analytics.track(editingContact != nil ? .trustedContactEdited : .trustedContactCreated, ["role": role])
        isSaving = false
        dismiss()
    }
}

// MARK: - iOS Contact Picker Bridge

struct PickedContact {
    var fullName: String?
    var email: String?
    var phone: String?
    var organization: String?
}

struct ContactPickerWrapper: UIViewControllerRepresentable {
    var onPick: (PickedContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (PickedContact) -> Void

        init(onPick: @escaping (PickedContact) -> Void) {
            self.onPick = onPick
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let email = contact.emailAddresses.first?.value as String?
            let phone = contact.phoneNumbers.first?.value.stringValue
            let org = contact.organizationName

            onPick(PickedContact(
                fullName: fullName,
                email: email,
                phone: phone,
                organization: org
            ))
        }
    }
}
