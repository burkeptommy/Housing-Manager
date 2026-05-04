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
    /// Phase 95 (gap #23) — drives the "Browse local pros" path. When
    /// the caller passed a `prefilledCategory`, tapping the option
    /// opens FindLocalVendorSheet directly. Otherwise the user picks
    /// a category first via `showBrowseCategoryPicker`.
    @State private var showBrowseLocal = false
    @State private var showBrowseCategoryPicker = false
    @State private var browseCategory: String?
    @State private var browseTown: String = ""
    @State private var browseState: String = ""
    @State private var browseHouseholdId: UUID?

    // Pre-filled data from contact or website import
    @State private var importedVendor = ImportedVendorData()

    enum VendorImportMethod {
        case contacts, website, manual, browseLocal
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

                        // Option 3: Browse local pros (Phase 95 / gap #23)
                        // Opens FindLocalVendorSheet for the prefilled
                        // category. When the caller didn't seed one,
                        // we route through `showBrowseCategoryPicker`
                        // so the user picks a category from the
                        // canonical SystemCategoryRegistry list first.
                        importOptionCard(
                            icon: "magnifyingglass",
                            title: "Browse local pros",
                            subtitle: "Top-rated vendors near your home",
                            color: HavenColors.action
                        ) {
                            Haptics.light()
                            Analytics.track(.contractorBrowseLocalOpened, [
                                "source": "add_vendor_sheet",
                                "has_category": prefilledCategory != nil
                            ])
                            if let cat = prefilledCategory {
                                browseCategory = cat
                                Task { await openBrowseLocal() }
                            } else {
                                showBrowseCategoryPicker = true
                            }
                        }

                        // Option 4: Manual
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
            // Phase 95 (gap #23) — category picker that fronts
            // FindLocalVendorSheet when the caller didn't pre-seed
            // a category. List sources from SystemCategoryRegistry's
            // universal + conditional + specialty tiers (excluding
            // sub-systems) so the user only sees categories that
            // match a real Places filter on the edge function side.
            .sheet(isPresented: $showBrowseCategoryPicker) {
                NavigationStack {
                    List {
                        ForEach(browseCategoryOptions, id: \.categoryKey) { meta in
                            Button {
                                browseCategory = meta.categoryKey
                                showBrowseCategoryPicker = false
                                Task { await openBrowseLocal() }
                            } label: {
                                HStack(spacing: HavenTheme.spacing12) {
                                    Image(systemName: meta.icon)
                                        .frame(width: 24)
                                        .foregroundStyle(HavenColors.navy700)
                                    Text(meta.displayName)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                                .padding(.vertical, HavenTheme.spacing4)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .navigationTitle("Pick a category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showBrowseCategoryPicker = false }
                        }
                    }
                }
            }
            // Phase 95 (gap #23) — the actual local-pros browser.
            // Reuses the same FindLocalVendorSheet that powers the
            // "Find a contractor for X" task path; the only
            // difference is we're here without a triggering task.
            .sheet(isPresented: $showBrowseLocal) {
                if let category = browseCategory,
                   let householdId = browseHouseholdId,
                   !browseTown.isEmpty,
                   !browseState.isEmpty {
                    FindLocalVendorSheet(
                        task: nil,
                        householdId: householdId,
                        town: browseTown,
                        state: browseState,
                        systemCategory: category,
                        categoryDisplayName: SystemCategoryRegistry.byCategoryKey[category]?.displayName ?? category,
                        onComplete: {
                            onComplete?()
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    /// Phase 95 (gap #23) — the deduplicated category list shown to
    /// the homeowner. Excludes sub-system entries (those are
    /// component-level; they don't have their own vendor lane) and
    /// preserves the registry's display priority so the most
    /// frequently-needed categories surface first.
    private var browseCategoryOptions: [SystemCategoryMeta] {
        let combined = SystemCategoryRegistry.universal
            + SystemCategoryRegistry.conditional
            + SystemCategoryRegistry.specialty
        return combined.sorted { lhs, rhs in
            if lhs.tier != rhs.tier {
                return lhs.tier.rawValue < rhs.tier.rawValue
            }
            return lhs.displayPriority < rhs.displayPriority
        }
    }

    /// Phase 95 (gap #23) — fetches the user's primary property to
    /// resolve town + state for the FindLocalVendorSheet query.
    /// Without these the edge function returns no results. When the
    /// fetch fails we silently fall back to the manual form so the
    /// user has a path forward — never block them in this flow.
    @MainActor
    private func openBrowseLocal() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                showManualForm = true
                return
            }
            browseHouseholdId = householdId
            let properties = (try? await DatabaseService.shared.fetchProperties()) ?? []
            if let primary = properties.first {
                browseTown = primary.city ?? ""
                browseState = primary.state ?? ""
            }
            if browseTown.isEmpty || browseState.isEmpty {
                // No address on file — manual entry is the only
                // sensible path until the user adds a property.
                showManualForm = true
                return
            }
            showBrowseLocal = true
        } catch {
            showManualForm = true
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
              !raw.isEmpty else { return }

        // Only inspect the first ~2KB. Long pastes (full emails, articles,
        // multi-line addresses) aren't valid URLs or phone numbers and the
        // detection regexes below would just waste cycles. The previous
        // 500-char cap silently dropped legitimately long URLs (campaign
        // tracking parameters, signed AWS / Brandfetch links).
        let inspectable = raw.count <= 2048 ? raw : String(raw.prefix(2048))

        let lowered = inspectable.lowercased()
        if lowered.hasPrefix("http://")
            || lowered.hasPrefix("https://")
            || lowered.hasPrefix("www.") {
            // Pass the full string through — the user pasted it, the
            // import flow can decide what to do with the length.
            clipboardSuggestion = .url(raw)
            return
        }

        let digits = inspectable.components(separatedBy: CharacterSet.decimalDigits.inverted)
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
