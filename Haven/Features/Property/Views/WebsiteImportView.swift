import SwiftUI

struct WebsiteImportView: View {
    var prefilledUrl: String?
    var onResult: (ImportedVendorData) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var url: String
    @State private var isLoading = false
    @State private var error: String?

    /// Phase 56.1: Optional `prefilledUrl` lets callers (notably the
    /// clipboard-aware AddVendorSheet banner) pre-populate the URL
    /// field so the user only has to tap Extract instead of re-paste.
    init(prefilledUrl: String? = nil, onResult: @escaping (ImportedVendorData) -> Void) {
        self.prefilledUrl = prefilledUrl
        self.onResult = onResult
        _url = State(initialValue: prefilledUrl ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 44))
                        .foregroundStyle(HavenColors.info)
                    Text("Import from Website")
                        .font(HavenTypography.title2)
                    Text("Paste the vendor's website and we'll extract their contact information automatically.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(HavenColors.textTertiary)
                        TextField("https://www.example.com", text: $url)
                            .font(HavenTypography.bodySmall)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )

                    if let error {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }

                    HavenButton(title: isLoading ? "Scanning website..." : "Extract Contact Info") {
                        Task { await extractFromWebsite() }
                    }
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal)

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(HavenColors.navy)
                        Text("Reading the website for business details...")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
            .navigationTitle("Website Import")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("WebsiteImportView")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func extractFromWebsite() async {
        isLoading = true
        error = nil

        // Normalize URL
        var normalizedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedUrl.hasPrefix("http://") && !normalizedUrl.hasPrefix("https://") {
            normalizedUrl = "https://" + normalizedUrl
        }

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isLoading = false
                return
            }

            // Call edge function to fetch + extract
            let data = try await HavenSupabase.extractVendorFromWebsite(
                url: normalizedUrl,
                householdId: householdId.uuidString
            )

            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var result = ImportedVendorData()
                result.companyName = json["business_name"] as? String ?? ""
                result.contactName = json["contact_name"] as? String
                result.phone = json["phone"] as? String ?? ""
                result.email = json["email"] as? String ?? ""
                result.address = json["address"] as? String ?? ""
                result.website = normalizedUrl
                result.licenseNumber = json["license_number"] as? String ?? ""
                result.source = .website

                // Services detected from the website
                if let services = json["services"] as? [String] {
                    result.detectedServices = services
                    // Auto-match to our system categories
                    result.specialties = Set(services.compactMap { service in
                        matchServiceToCategory(service)
                    })
                }

                Analytics.track(.contractorWebsiteImport, ["url": normalizedUrl, "success": true])
                onResult(result)
            } else {
                Analytics.track(.contractorWebsiteImport, ["url": normalizedUrl, "success": false])
                error = "Couldn't extract info from that website. Try entering details manually."
            }
        } catch {
            self.error = "Failed to read the website. Check the URL and try again."
            print("[WebsiteImport] Error: \(error)")
        }

        isLoading = false
    }

    /// Match a service description from a website to our system categories
    private func matchServiceToCategory(_ service: String) -> String? {
        let lower = service.lowercased()
        let categoryMatches: [(keywords: [String], category: String)] = [
            (["hvac", "heating", "cooling", "air condition", "furnace", "heat pump"], "HVAC"),
            (["plumb", "pipe", "drain", "water heater", "sewer", "faucet"], "Plumbing"),
            (["electric", "wiring", "panel", "outlet", "circuit"], "Electrical"),
            (["roof", "gutter", "shingle", "flashing"], "Roofing"),
            (["landscap", "lawn", "tree", "garden", "mow", "irrigation", "sprinkler"], "Landscaping"),
            (["pest", "termite", "exterminator", "rodent", "ant", "bug"], "Pest Control"),
            (["paint", "siding", "exterior", "power wash", "pressure wash"], "Siding/Exterior"),
            (["pool", "spa", "hot tub"], "Pool/Spa"),
            (["septic", "cesspool"], "Septic System"),
            (["well", "water test", "water quality"], "Well System"),
            (["generator", "backup power"], "Generator"),
            (["security", "alarm", "camera", "surveillance"], "Security System"),
            (["solar", "panel", "photovoltaic"], "Solar"),
            (["chimney", "fireplace", "sweep"], "Fire Protection"),
            (["garage door", "overhead door"], "Garage Door"),
            (["window", "door", "glass"], "Windows"),
            (["appliance", "refrigerator", "dishwasher", "washer", "dryer", "oven"], "Appliance"),
            (["floor", "tile", "carpet", "hardwood"], "Flooring"),
            (["insulation", "weatheriz", "energy audit"], "Insulation"),
            (["foundation", "basement", "waterproof", "crawl space"], "Crawl Space"),
        ]

        for match in categoryMatches {
            if match.keywords.contains(where: { lower.contains($0) }) {
                return match.category
            }
        }
        return nil
    }
}
