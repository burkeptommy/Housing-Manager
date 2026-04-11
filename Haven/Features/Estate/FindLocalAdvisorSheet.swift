import SwiftUI

/// Sheet that searches for local professional advisors via Google Places.
/// Mirrors FindLocalVendorSheet but adapted for advisors (no task conversion).
struct FindLocalAdvisorSheet: View {
    let advisorType: String
    let advisorLabel: String
    let householdId: UUID
    var town: String?
    var state: String?
    var onAdopt: ((HavenSupabase.LocalVendorResult) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var vendors: [HavenSupabase.LocalVendorResult] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var adoptedId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOCAL ADVISORS")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        if let town, let state {
                            Text("Top \(advisorLabel.lowercased())s in \(town), \(state)")
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                        } else {
                            Text("Top \(advisorLabel.lowercased())s near you")
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        Text("Based on ratings, reviews, and local reputation")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing8)

                    if isLoading {
                        VStack(spacing: HavenTheme.spacing12) {
                            ProgressView()
                            Text("Searching for \(advisorLabel.lowercased())s near you...")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if let errorMessage {
                        VStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundStyle(HavenColors.warning)
                            Text("Couldn't load advisors")
                                .font(HavenTypography.bodySmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(errorMessage)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await loadVendors() }
                            }
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if vendors.isEmpty {
                        VStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("No advisors found yet")
                                .font(HavenTypography.bodySmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("You can add your own advisor below")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        // Haven Certified
                        let certified = vendors.filter { $0.isHavenCertified }
                        if !certified.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(HavenColors.success)
                                    Text("HAVEN CERTIFIED")
                                        .font(HavenTypography.uiSectionHeader)
                                        .tracking(1.2)
                                        .foregroundStyle(HavenColors.success)
                                }
                                .padding(.horizontal, HavenTheme.pageMargin)

                                ForEach(certified, id: \.googlePlaceId) { vendor in
                                    vendorCard(vendor: vendor, isCertified: true)
                                }
                            }
                        }

                        // Suggested
                        let suggested = vendors.filter { !$0.isHavenCertified }
                        if !suggested.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SUGGESTED")
                                    .font(HavenTypography.uiSectionHeader)
                                    .tracking(1.2)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .padding(.horizontal, HavenTheme.pageMargin)

                                ForEach(suggested, id: \.googlePlaceId) { vendor in
                                    vendorCard(vendor: vendor, isCertified: false)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(HavenColors.background)
            .navigationTitle("Find \(advisorLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
            }
            .task { await loadVendors() }
        }
    }

    // MARK: - Vendor Card

    private func vendorCard(vendor: HavenSupabase.LocalVendorResult, isCertified: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)

                    if let rating = vendor.rating, let count = vendor.reviewCount {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(HavenTypography.caption.weight(.semibold))
                            Text("(\(count) reviews)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                Spacer()

                if adoptedId == vendor.googlePlaceId {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.success)
                } else {
                    Button {
                        Haptics.medium()
                        adoptedId = vendor.googlePlaceId
                        onAdopt?(vendor)
                    } label: {
                        Text("Select")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textOnNavy)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }
            }

            if let address = vendor.address {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10))
                    Text(address)
                        .font(HavenTypography.caption)
                }
                .foregroundStyle(HavenColors.textSecondary)
            }

            HStack(spacing: 12) {
                if let phone = vendor.phone {
                    HStack(spacing: 4) {
                        Image(systemName: "phone")
                            .font(.system(size: 10))
                        Text(phone)
                            .font(HavenTypography.caption)
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
                if let website = vendor.website {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                        Text(websiteDisplay(website))
                            .font(HavenTypography.caption)
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(
                    isCertified ? HavenColors.success.opacity(0.3) : HavenColors.border,
                    lineWidth: 1
                )
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    // MARK: - Load

    private func loadVendors() async {
        guard let town = town ?? resolvedTown, let state = state ?? resolvedState else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await HavenSupabase.findLocalAdvisors(
                town: town,
                state: state,
                advisorType: advisorType
            )
            vendors = response.vendors
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Try to resolve town/state from the user's first property
    private var resolvedTown: String? {
        nil // Caller should pass town/state; fallback handled in the UI
    }

    private var resolvedState: String? {
        nil
    }

    private func websiteDisplay(_ url: String) -> String {
        url.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
