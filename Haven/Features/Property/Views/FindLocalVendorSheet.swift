import SwiftUI

/// Phase 19n: Local vendor picker that fires when the user taps a
/// "Find a contractor for: X" task. Calls the `find-local-vendors` edge
/// function with the task's town/state/category, displays up to 4 ranked
/// businesses (2 Haven Certified + 2 Suggested), and lets the user adopt
/// one with a single tap. Adopting a vendor:
///
///   1. Creates a `contractors` row with `source: "find_vendor"` and the
///      matching system category.
///   2. Walks every needs_vendor task in this household for the same
///      category and converts each via `MaintenanceViewModel.convertToVendorManaged`,
///      reframing the title from "Find a contractor for: X" to
///      "Schedule [Vendor]: X" and clearing the needs_vendor flag.
///   3. Posts `.contractorAdded` so the dashboard can re-fire the
///      delegation sheet for any 'either' tasks the new vendor could also
///      take over.
struct FindLocalVendorSheet: View {
    let task: MaintenanceTaskDBRow
    let town: String
    let state: String
    let systemCategory: String
    let categoryDisplayName: String
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var vendors: [HavenSupabase.LocalVendorResult] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var pendingAdoption: HavenSupabase.LocalVendorResult? = nil
    @State private var isAdding: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        header

                        if isLoading {
                            loadingState
                        } else if let error = loadError {
                            errorState(error)
                        } else if vendors.isEmpty {
                            emptyState
                        } else {
                            vendorList
                        }

                        addMyOwnButton
                            .padding(.top, HavenTheme.spacing16)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing16)
                    .padding(.bottom, HavenTheme.spacing48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
            .alert(
                "Add this vendor?",
                isPresented: Binding(
                    get: { pendingAdoption != nil },
                    set: { if !$0 { pendingAdoption = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { pendingAdoption = nil }
                Button("Add") {
                    if let vendor = pendingAdoption {
                        Task { await adoptVendor(vendor) }
                    }
                }
            } message: {
                if let vendor = pendingAdoption {
                    Text("Add \(vendor.name) as your \(categoryDisplayName) contractor? We'll move your matching tasks over.")
                }
            }
        }
        .task {
            await loadVendors()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("LOCAL VENDORS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.4)
                .foregroundStyle(HavenColors.textTertiary)

            Text("Top \(categoryDisplayName) pros in \(town), \(state).")
                .font(HavenTypography.fraunces(size: 24, weight: 600))
                .foregroundStyle(HavenColors.navy800)
                .fixedSize(horizontal: false, vertical: true)

            Text("We screen for high ratings, real reviews, and local independents. Tap a card to add them as your contractor.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ProgressView()
                .tint(HavenColors.navy)
            Text("Searching for vendors near you...")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.warning)
            Text("Couldn't load vendors")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(error)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await loadVendors() }
            } label: {
                Text("Try again")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.navy)
            }
            .padding(.top, HavenTheme.spacing4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No vendors found yet")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("We couldn't surface a strong local match. Add your own vendor below and Haven will use it for future tasks.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing32)
    }

    // MARK: - Vendor List

    private var vendorList: some View {
        let havenCertified = vendors.filter { $0.isHavenCertified }
        let suggested = vendors.filter { !$0.isHavenCertified }

        return VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            if !havenCertified.isEmpty {
                Text("HAVEN CERTIFIED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.success)
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(havenCertified) { vendor in
                        vendorCard(vendor)
                    }
                }
            }

            if !suggested.isEmpty {
                Text("SUGGESTED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, havenCertified.isEmpty ? 0 : HavenTheme.spacing8)
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(suggested) { vendor in
                        vendorCard(vendor)
                    }
                }
            }
        }
    }

    private func vendorCard(_ vendor: HavenSupabase.LocalVendorResult) -> some View {
        Button {
            Haptics.selection()
            pendingAdoption = vendor
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vendor.name)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let rating = vendor.rating {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.warning)
                                Text(String(format: "%.1f", rating))
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                if let reviews = vendor.reviewCount {
                                    Text("\u{00B7}")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text("\(reviews) reviews")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    if vendor.isHavenCertified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text("Certified")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(HavenColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HavenColors.success.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }

                if let address = vendor.address, !address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(address)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                if let phone = vendor.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(phone)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let website = vendor.website, !website.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(website)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.navy700)
                            .lineLimit(1)
                    }
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(
                        vendor.isHavenCertified
                            ? HavenColors.success.opacity(0.4)
                            : HavenColors.beige200,
                        lineWidth: vendor.isHavenCertified ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }

    private var addMyOwnButton: some View {
        Button {
            Haptics.light()
            // Phase 19n: opening the manual contractor add path stays as a
            // separate sheet on top of this one. We dismiss first so the
            // navigation stack is clean.
            NotificationCenter.default.post(name: .openManualContractorAdd, object: nil)
            dismiss()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                Text("Add my own instead")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(HavenColors.navy700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }

    // MARK: - Loading

    private func loadVendors() async {
        isLoading = true
        loadError = nil
        do {
            let response = try await HavenSupabase.findLocalVendors(
                town: town,
                state: state,
                category: systemCategory
            )
            vendors = response.vendors
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Adopt

    private func adoptVendor(_ vendor: HavenSupabase.LocalVendorResult) async {
        isAdding = true
        defer { isAdding = false }

        let db = DatabaseService.shared
        let householdId = task.householdId

        // 1. Create the contractor row, marked as find_vendor sourced.
        var insert = ContractorInsert(
            householdId: householdId,
            companyName: vendor.name,
            phone: vendor.phone ?? "Not provided"
        )
        insert.address = vendor.address
        insert.website = vendor.website
        insert.category = systemCategory
        insert.specialties = [systemCategory]
        insert.source = "find_vendor"

        let createdContractor: ContractorRow
        do {
            createdContractor = try await db.createContractor(insert)
        } catch {
            print("[FindLocalVendor] Failed to create contractor: \(error)")
            isAdding = false
            return
        }

        // 2. Walk every needs_vendor task whose system matches this category
        // and convert each via the existing viewmodel path. We refresh the
        // viewmodel first so its in-memory tasks are current; otherwise the
        // conversion would only see whatever was loaded earlier.
        await MaintenanceViewModel.shared.loadTasks()
        let candidates = MaintenanceViewModel.shared.tasks.filter { row in
            guard row.vehicleId == nil else { return false }
            guard row.assignmentType?.lowercased() == "vendor" else { return false }
            guard row.needsVendor == true else { return false }
            // Match the task's system category against the contractor's
            // category. Use the in-memory systems list maintained by the VM.
            guard let systemId = row.systemId,
                  let system = MaintenanceViewModel.shared.systems.first(where: { $0.id == systemId })
            else {
                // Fall back to the triggering task's systemId so the user
                // always sees at least the task they tapped get converted.
                return row.id == task.id
            }
            return system.category.lowercased() == systemCategory.lowercased()
        }

        for candidate in candidates {
            await MaintenanceViewModel.shared.convertToVendorManaged(
                taskId: candidate.id,
                contractor: createdContractor
            )
        }

        // 3. Notify everyone. The contractorAdded post fires the dashboard
        // delegation sheet for any 'either' tasks the new vendor could also
        // take over (Phase 19l re-fire path).
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: ["contractorId": createdContractor.id.uuidString]
        )
        Haptics.success()

        onComplete?()
        dismiss()
    }
}

extension Notification.Name {
    /// Phase 19n: posted by FindLocalVendorSheet when the user taps "Add my
    /// own instead". The maintenance list view (or any other host) listens
    /// for this and presents the manual ContractorDirectoryView add sheet.
    static let openManualContractorAdd = Notification.Name("openManualContractorAdd")
}
