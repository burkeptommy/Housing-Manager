import SwiftUI

/// The very first screen a new user sees — no account required.
/// Enter an address → see instant property data + maintenance schedule → prompted to create account.
/// This is the "Zillow model": deliver value before asking for anything.
struct AddressHookView: View {
    let onCreateAccount: () -> Void
    let onSignIn: () -> Void

    @StateObject private var viewModel = AddressHookViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress (only show on address and preview steps)
                if viewModel.currentStep != .address {
                    ProgressView(value: viewModel.progress)
                        .tint(HavenColors.navy)
                        .padding(.horizontal)
                }

                TabView(selection: $viewModel.currentStep) {
                    addressStep
                        .tag(AddressHookStep.address)

                    OnboardingSchedulePreviewStep(
                        street: viewModel.street,
                        city: viewModel.city,
                        state: viewModel.state,
                        propertyResult: viewModel.propertyLookupResult,
                        scheduleItems: viewModel.schedulePreview,
                        isLoading: viewModel.isLookingUpProperty
                    )
                    .tag(AddressHookStep.preview)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                .onChange(of: viewModel.currentStep) { _, _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

                // Bottom buttons
                bottomButtons
            }
            .background(HavenColors.background)
        }
        .trackScreen("AddressHookView")
    }

    // MARK: - Address Step

    private var addressStep: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: 20)

                // Branding
                VStack(spacing: 8) {
                    Text("H")
                        .font(Font.custom("Georgia", size: 64))
                        .foregroundStyle(HavenColors.navy800)
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(HavenColors.creamLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(HavenColors.beige300, lineWidth: 1)
                                )
                        )
                    Text("Haven")
                        .font(HavenTypography.largeTitle)
                }

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Where's your home?")
                        .font(HavenTypography.title2)
                    Text("Enter your address and we'll build a personalized home maintenance plan — free, in seconds.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: HavenTheme.spacing12) {
                    AddressAutocompleteField(
                        street: $viewModel.street,
                        unit: $viewModel.unit,
                        city: $viewModel.city,
                        state: $viewModel.state,
                        zipCode: $viewModel.zipCode
                    )
                }
                .padding(HavenTheme.spacing16)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            switch viewModel.currentStep {
            case .address:
                HavenButton(title: "Find My Home") {
                    Task {
                        viewModel.currentStep = .preview
                        await viewModel.lookupProperty()
                    }
                }
                .disabled(!viewModel.canProceed)

                Button("I already have an account") {
                    onSignIn()
                }
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            case .preview:
                if !viewModel.isLookingUpProperty {
                    HavenButton(title: "Create Free Account to Save", action: {
                        viewModel.cacheToUserDefaults()
                        onCreateAccount()
                    }, icon: "arrow.right")

                    Button("I already have an account") {
                        viewModel.cacheToUserDefaults()
                        onSignIn()
                    }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                    Button("Back") {
                        viewModel.currentStep = .address
                    }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, HavenTheme.padding)
        .padding(.bottom, 24)
    }
}

// MARK: - AddressHookStep

enum AddressHookStep: Int, CaseIterable {
    case address = 0
    case preview
}

// MARK: - AddressHookViewModel

@MainActor
final class AddressHookViewModel: ObservableObject {
    @Published var currentStep: AddressHookStep = .address
    @Published var errorMessage: String?

    // Address
    @Published var street = ""
    @Published var unit = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""

    // Property lookup
    @Published var propertyLookupResult: PropertyLookupResult?
    @Published var schedulePreview: [SchedulePreviewItem] = []
    @Published var isLookingUpProperty = false

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(AddressHookStep.allCases.count)
    }

    var canProceed: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func lookupProperty() async {
        isLookingUpProperty = true
        errorMessage = nil

        let fullAddress = [street, unit, city, state, zipCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        do {
            let responseData = try await HavenSupabase.propertyLookup(address: fullAddress)

            struct LookupResponse: Decodable {
                let success: Bool
                let property: PropertyLookupResult?
            }

            let response = try JSONDecoder().decode(LookupResponse.self, from: responseData)
            if response.success, let property = response.property {
                propertyLookupResult = property
            } else {
                propertyLookupResult = nil
            }
        } catch {
            print("[AddressHook] Property lookup failed: \(error)")
            propertyLookupResult = nil
        }

        schedulePreview = OnboardingScheduleGenerator.generate(
            from: propertyLookupResult,
            state: state
        )

        isLookingUpProperty = false
    }

    /// Cache the address + lookup result to UserDefaults so it survives the auth flow.
    func cacheToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(street, forKey: "addressHook_street")
        defaults.set(unit, forKey: "addressHook_unit")
        defaults.set(city, forKey: "addressHook_city")
        defaults.set(state, forKey: "addressHook_state")
        defaults.set(zipCode, forKey: "addressHook_zipCode")

        if let result = propertyLookupResult,
           let data = try? JSONEncoder().encode(result) {
            defaults.set(data, forKey: "addressHook_propertyResult")
        }

        defaults.set(true, forKey: "addressHook_hasData")
    }

    /// Load cached address data from a previous AddressHook session.
    static func loadCachedData() -> (street: String, unit: String, city: String, state: String, zipCode: String, propertyResult: PropertyLookupResult?)? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "addressHook_hasData") else { return nil }

        let street = defaults.string(forKey: "addressHook_street") ?? ""
        guard !street.isEmpty else { return nil }

        var propertyResult: PropertyLookupResult?
        if let data = defaults.data(forKey: "addressHook_propertyResult") {
            propertyResult = try? JSONDecoder().decode(PropertyLookupResult.self, from: data)
        }

        return (
            street: street,
            unit: defaults.string(forKey: "addressHook_unit") ?? "",
            city: defaults.string(forKey: "addressHook_city") ?? "",
            state: defaults.string(forKey: "addressHook_state") ?? "",
            zipCode: defaults.string(forKey: "addressHook_zipCode") ?? "",
            propertyResult: propertyResult
        )
    }

    /// Clear cached address data after it has been consumed by onboarding.
    static func clearCachedData() {
        let defaults = UserDefaults.standard
        for key in ["addressHook_street", "addressHook_unit", "addressHook_city",
                     "addressHook_state", "addressHook_zipCode", "addressHook_propertyResult",
                     "addressHook_hasData"] {
            defaults.removeObject(forKey: key)
        }
    }
}
