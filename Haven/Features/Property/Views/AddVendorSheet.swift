import SwiftUI
import Contacts
import ContactsUI

struct AddVendorSheet: View {
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMethod: VendorImportMethod?
    @State private var showContactPicker = false
    @State private var showWebsiteImport = false
    @State private var showManualForm = false

    // Pre-filled data from contact or website import
    @State private var importedVendor = ImportedVendorData()

    enum VendorImportMethod {
        case contacts, website, manual
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(HavenColors.navy)
                        Text("Add a Vendor")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Choose the fastest way to add your vendor.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        // Option 1: Phone Contacts
                        importOptionCard(
                            icon: "person.crop.circle.fill",
                            title: "Import from Contacts",
                            subtitle: "Pull their info from your phone book",
                            color: HavenColors.success
                        ) {
                            Haptics.light()
                            Analytics.track(.contractorContactPickerUsed)
                            showContactPicker = true
                        }

                        // Option 2: Website
                        importOptionCard(
                            icon: "globe",
                            title: "Import from Website",
                            subtitle: "Paste their URL and we'll find their details",
                            color: HavenColors.info
                        ) {
                            Haptics.light()
                            Analytics.track(.contractorWebsiteImport, ["source": "add_vendor_sheet"])
                            showWebsiteImport = true
                        }

                        // Option 3: Manual
                        importOptionCard(
                            icon: "square.and.pencil",
                            title: "Enter Manually",
                            subtitle: "Type in vendor details yourself",
                            color: HavenColors.navy700
                        ) {
                            Haptics.light()
                            Analytics.track(.contractorCreated, ["source": "manual"])
                            importedVendor = ImportedVendorData() // Reset
                            showManualForm = true
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(HavenColors.background)
            .navigationTitle("Add Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("AddVendorSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contact in
                    // Map CNContact to our imported data
                    importedVendor = ImportedVendorData(
                        companyName: contact.organizationName.isEmpty
                            ? "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                            : contact.organizationName,
                        contactName: contact.organizationName.isEmpty
                            ? nil
                            : "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                        phone: contact.phoneNumbers.first?.value.stringValue ?? "",
                        email: (contact.emailAddresses.first?.value as String?) ?? "",
                        address: formatContactAddress(contact),
                        source: .contacts
                    )
                    showContactPicker = false
                    // Go straight to the review/save form
                    showManualForm = true
                }
            }
            .sheet(isPresented: $showWebsiteImport) {
                WebsiteImportView { result in
                    importedVendor = result
                    showWebsiteImport = false
                    showManualForm = true
                }
            }
            .sheet(isPresented: $showManualForm) {
                VendorReviewForm(
                    vendor: $importedVendor,
                    onSave: {
                        onComplete?()
                        dismiss()
                    }
                )
            }
        }
    }

    private func importOptionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding()
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    private func formatContactAddress(_ contact: CNContact) -> String {
        guard let postal = contact.postalAddresses.first?.value else { return "" }
        return [postal.street, postal.city, postal.state, postal.postalCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

// MARK: - Shared Import Data Model

struct ImportedVendorData {
    var companyName: String = ""
    var contactName: String?
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var website: String = ""
    var licenseNumber: String = ""
    var specialties: Set<String> = []
    var contactType: String = "Contractor / Service Provider"
    var detectedServices: [String] = []  // From website AI extraction
    var source: ImportSource = .manual

    enum ImportSource {
        case contacts, website, manual
    }
}
