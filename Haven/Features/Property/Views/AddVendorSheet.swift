import SwiftUI
import Contacts
import ContactsUI

struct AddVendorSheet: View {
    var onComplete: (() -> Void)?
    /// Phase 60.6: optional canonical category (e.g. "Plumbing",
    /// "Handyman"). When set, the downstream `VendorReviewForm` boots
    /// with this category preselected in the specialty picker so users
    /// coming from the post-quiz coverage sweep / vendor-coverage "I
    /// have one" flow don't have to hunt for the right label. Passed
    /// through on `ImportedVendorData.prefilledCategory`.
    var prefilledCategory: String?
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

    /// Phase 56.1: Notion-style paste detection. On sheet appear we
    /// inspect the clipboard once and, if it looks vendor-relevant
    /// (URL or phone number), offer a one-tap import banner above
    /// the three manual options. Dismissed banners stay dismissed for
    /// the lifetime of this sheet presentation.
    @State private var clipboardSuggestion: ClipboardSuggestion?

    enum ClipboardSuggestion {
        case url(String)
        case phone(String)
        case unknown(String)

        var icon: String {
            switch self {
            case .url: return "globe"
            case .phone: return "phone.fill"
            case .unknown: return "doc.on.clipboard"
            }
        }

        var title: String {
            switch self {
            case .url: return "URL on your clipboard"
            case .phone: return "Phone number on your clipboard"
            case .unknown: return "Use clipboard content?"
            }
        }

        var preview: String {
            switch self {
            case .url(let s), .phone(let s), .unknown(let s):
                return s.count > 60 ? String(s.prefix(60)) + "…" : s
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Add a Vendor")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Choose the fastest way to add your vendor.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.top, 20)

                    if let suggestion = clipboardSuggestion {
                        clipboardBanner(suggestion)
                            .padding(.horizontal)
                    }

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
            .onAppear {
                detectClipboardContent()
                // Phase 60.6: seed the ImportedVendorData with the
                // caller's prefilled category so VendorReviewForm boots
                // with the right specialty highlighted. Runs once per
                // sheet presentation and survives the three import
                // method transitions because state is view-level.
                if let cat = prefilledCategory,
                   importedVendor.prefilledCategory == nil {
                    importedVendor.prefilledCategory = cat
                }
            }
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
                WebsiteImportView(
                    prefilledUrl: importedVendor.website.isEmpty ? nil : importedVendor.website
                ) { result in
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
                        .font(.custom("Inter", size: 15).weight(.semibold))
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

    // MARK: - Phase 56.1 Clipboard detection

    /// Inspect the clipboard once on sheet open. If the string looks
    /// like a URL or phone number, surface a banner offering a one-tap
    /// import path. Reads the clipboard locally only — no polling,
    /// no background reads. iOS may show a system pasteboard toast,
    /// which is expected behavior for user-initiated paste flows.
    private func detectClipboardContent() {
        guard let raw = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              raw.count <= 500 else { return }

        let lowered = raw.lowercased()
        if lowered.hasPrefix("http://")
            || lowered.hasPrefix("https://")
            || lowered.hasPrefix("www.") {
            clipboardSuggestion = .url(raw)
            return
        }

        let digits = raw.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        if digits.count >= 7 && digits.count <= 15 {
            clipboardSuggestion = .phone(raw)
        }
    }

    /// Notion-inspired clipboard banner. Sits above the three import
    /// option cards and offers a single "Use it" action that routes
    /// to Website Import or the manual form with the captured data
    /// pre-filled.
    @ViewBuilder
    private func clipboardBanner(_ suggestion: ClipboardSuggestion) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: suggestion.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 32, height: 32)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(suggestion.preview)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.light()
                applyClipboardSuggestion(suggestion)
            } label: {
                Text("Use it")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textOnNavy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(HavenColors.navy)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button {
                Haptics.light()
                clipboardSuggestion = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func applyClipboardSuggestion(_ suggestion: ClipboardSuggestion) {
        switch suggestion {
        case .url(let url):
            importedVendor = ImportedVendorData()
            importedVendor.website = url
            Analytics.track(.contractorWebsiteImport, ["source": "clipboard"])
            showWebsiteImport = true
        case .phone(let phone):
            importedVendor = ImportedVendorData()
            importedVendor.phone = phone
            Analytics.track(.contractorCreated, ["source": "manual_clipboard_phone"])
            showManualForm = true
        case .unknown:
            clipboardSuggestion = nil
        }
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
    /// Phase 60.6: optional canonical category passed from the caller
    /// (post-quiz sweep, vendor-coverage "I have one"). Precedence in
    /// VendorReviewForm.onAppear: this field > detectedServices
    /// keyword match > companyName keyword match. Nil for users who
    /// open AddVendorSheet from the generic "+" entry point.
    var prefilledCategory: String?

    enum ImportSource {
        case contacts, website, manual
    }
}
