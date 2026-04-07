import SwiftUI

/// "Didn't find yours? Add it" sheet for the utility provider picker.
/// Lets the user enter a name + website and previews the brand logo live as
/// they type the website (debounced 500ms via the `brand-logo` edge function).
///
/// On Save:
///   - Generates a slug from the name (lowercase, alphanumeric + hyphens).
///   - Calls DatabaseService.createUtilityProvider with the captured fields
///     and any logo URL / brand color the brand-logo lookup returned.
///   - Hands the new row back to the parent picker via `onAdded`.
struct UtilityProviderCustomAddSheet: View {
    let providerType: String
    let onAdded: (UtilityProviderRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var website: String = ""
    @State private var phone: String = ""
    @State private var fetchedLogoUrl: String? = nil
    @State private var fetchedBrandColor: String? = nil
    @State private var isLogoFetching: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var brandFetchTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    headerCard
                    nameField
                    websiteField
                    phoneField
                    if let saveError {
                        Text(saveError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                    HavenButton(title: isSaving ? "Adding..." : "Add provider", action: {
                        Task { await save() }
                    })
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
                .padding(HavenTheme.spacing20)
            }
            .background(HavenColors.background)
            .navigationTitle("Add provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: HavenTheme.spacing12) {
            logoPreview
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "New \(providerType.replacingOccurrences(of: "_", with: " ")) provider" : name)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(website.isEmpty ? "Add website to fetch logo" : website)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    @ViewBuilder
    private var logoPreview: some View {
        if let urlString = fetchedLogoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit).padding(6)
                case .failure:
                    placeholder
                default:
                    ProgressView()
                        .controlSize(.small)
                        .tint(HavenColors.navy)
                }
            }
            .frame(width: 56, height: 56)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        } else if isLogoFetching {
            ProgressView()
                .controlSize(.small)
                .tint(HavenColors.navy)
                .frame(width: 56, height: 56)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: 22))
            .foregroundStyle(HavenColors.textTertiary)
            .frame(width: 56, height: 56)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Provider name")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            HavenTextField(title: "Green Mountain Power", text: $name)
                .textInputAutocapitalization(.words)
        }
    }

    private var websiteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Website (optional)")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            HavenTextField(title: "greenmountainpower.com", text: $website)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled(true)
                .onChange(of: website) { _, newValue in
                    scheduleLogoFetch(for: newValue)
                }
            if isLogoFetching {
                Text("Fetching logo...")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Phone (optional)")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            HavenTextField(title: "(555) 555-5555", text: $phone)
                .keyboardType(.phonePad)
        }
    }

    // MARK: - Brand fetch

    private func scheduleLogoFetch(for newValue: String) {
        brandFetchTask?.cancel()
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 4, trimmed.contains(".") else {
            fetchedLogoUrl = nil
            fetchedBrandColor = nil
            return
        }
        isLogoFetching = true
        brandFetchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            do {
                let response = try await HavenSupabase.fetchBrandLogo(domain: trimmed)
                await MainActor.run {
                    self.fetchedLogoUrl = response.logoUrl ?? response.iconUrl
                    self.fetchedBrandColor = response.brandColor
                    self.isLogoFetching = false
                }
            } catch {
                await MainActor.run {
                    self.fetchedLogoUrl = nil
                    self.isLogoFetching = false
                }
            }
        }
    }

    // MARK: - Save

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let slug = slugify(trimmedName)
        let normalizedWebsite = website
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let websiteToSave: String? = normalizedWebsite.isEmpty ? nil : normalizedWebsite
        let phoneToSave: String? = phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : phone.trimmingCharacters(in: .whitespacesAndNewlines)

        let insert = UtilityProviderInsert(
            name: trimmedName,
            slug: slug,
            providerType: providerType,
            logoUrl: fetchedLogoUrl,
            brandColor: fetchedBrandColor,
            website: websiteToSave,
            phone: phoneToSave
        )

        do {
            let row = try await DatabaseService.shared.createUtilityProvider(insert)
            Haptics.success()
            onAdded(row)
        } catch {
            saveError = "Couldn't save that provider: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func slugify(_ raw: String) -> String {
        let lowered = raw.lowercased()
        var slug = ""
        for ch in lowered {
            if ch.isLetter || ch.isNumber {
                slug.append(ch)
            } else if ch.isWhitespace || ch == "-" || ch == "_" {
                if !slug.hasSuffix("-") { slug.append("-") }
            }
        }
        if slug.hasSuffix("-") { slug.removeLast() }
        return slug
    }
}
