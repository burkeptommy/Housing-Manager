import SwiftUI

/// The very first screen a new user sees — no account required.
/// Enter an address → see instant property data + maintenance schedule → prompted to create account.
/// This is the "Zillow model": deliver value before asking for anything.
struct AddressHookView: View {
    let onCreateAccount: () -> Void
    let onSignIn: () -> Void

    @StateObject private var viewModel = AddressHookViewModel()
    @State private var showInviteCodeSheet: Bool = false
    @State private var inviteCodePrefill: String? = nil
    /// Phase 20a — present the new 2-page hook screen after the user
    /// confirms they want to see what we know about their home. Replaces
    /// the legacy "Create Free Account to Save" CTA on the preview step.
    @State private var showPropertyHook: Bool = false
    /// Phase 20b — hard account creation gate presented after the user
    /// taps "Get Started with [address]" on PropertyHookView Page 2.
    @State private var showAccountCreation: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Phase 20 polish: removed the legacy `.preview` step entirely.
                // The old maintenance-list screen with "$967 estimated annual
                // cost" is gone. Find My Home now runs the property lookup
                // inline, then opens PropertyHookView directly with the
                // value-anchored hook + estate frame.
                addressStep

                // Bottom buttons
                bottomButtons
            }
            .background(HavenColors.background)
        }
        .trackScreen("AddressHookView")
        .sheet(isPresented: $showInviteCodeSheet) {
            InviteCodeEntrySheet(
                onAcceptInvitation: {
                    showInviteCodeSheet = false
                    onCreateAccount()
                },
                initialCode: inviteCodePrefill
            )
            .presentationDetents([.medium, .large])
        }
        .task {
            // If a universal-link or app-launch handler stashed a code in
            // UserDefaults before this view appeared, surface the sheet right
            // away with the code pre-filled.
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: PendingInviteKeys.hasPendingInvite),
               let code = defaults.string(forKey: PendingInviteKeys.code),
               !code.isEmpty {
                inviteCodePrefill = code
                showInviteCodeSheet = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .inviteCodeReceived)) { note in
            if let code = note.object as? String, !code.isEmpty {
                inviteCodePrefill = code
                showInviteCodeSheet = true
            }
        }
        // Phase 20a — present the new 2-page hook screen as a fullScreenCover
        // when the user taps "See what we know about your home" on the
        // preview step.
        .fullScreenCover(isPresented: $showPropertyHook) {
            propertyHookCover(for: viewModel)
        }
        // Phase 20b — present the hard account creation gate after the
        // user taps "Get Started with [address]" on PropertyHookView
        // Page 2. This sequencing relies on a brief delay between the
        // hook cover dismissing and this cover presenting; SwiftUI
        // handles that automatically with consecutive fullScreenCovers.
        .fullScreenCover(isPresented: $showAccountCreation) {
            AccountCreationStep(
                address1: viewModel.street,
                onCancel: {
                    showAccountCreation = false
                }
            )
        }
    }

    // MARK: - Address Step

    private var addressStep: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: 20)

                // Branding
                VStack(spacing: 8) {
                    Text("H")
                        .font(HavenTypography.fraunces(size: 56, weight: 400))
                        .foregroundStyle(HavenColors.creamLight)
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(HavenColors.navy800)
                        )
                    Text("Haven")
                        .font(HavenTypography.fraunces(size: 36, weight: 400))
                        .foregroundStyle(HavenColors.navy800)
                }

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Where's your home?")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.navy800)
                    Text("Enter your address and we'll build a personalized home maintenance plan, free, in seconds.")
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

    // MARK: - Tertiary Link Row

    private var tertiaryLinks: some View {
        HStack(spacing: HavenTheme.spacing16) {
            Button("I already have an account") {
                viewModel.cacheToUserDefaults()
                onSignIn()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)

            Text("·")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textTertiary)

            Button("I have an invite code") {
                inviteCodePrefill = nil
                showInviteCodeSheet = true
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
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

            // Phase 20 polish: single-step flow. Find My Home runs the
            // property lookup inline, then opens PropertyHookView directly
            // with the value-anchored hook. The legacy `.preview` step
            // (the maintenance-list screen with the $967 estimated cost)
            // is gone — that framing positioned Haven as a chore tracker
            // instead of an asset-protection tool, which was wrong for
            // the HNW audience.
            //
            // Phase 20 polish (Apr 7): use HavenButton's `isLoading` prop
            // so the button visibly transforms during the 5–10 second
            // ATTOM lookup. The label switches to "Getting your home
            // details..." and the spinner takes the icon slot, which is
            // a much clearer affordance than just dimming the button.
            HavenButton(
                title: viewModel.isLookingUpProperty
                    ? "Getting your home details..."
                    : "Find My Home",
                action: {
                    Task {
                        viewModel.cacheToUserDefaults()
                        await viewModel.lookupProperty()
                        // Open the hook view as soon as the lookup resolves,
                        // even if it returned no result — PropertyHookView
                        // handles the nil-lookup case by synthesizing a
                        // value range from whatever signal it has.
                        showPropertyHook = true
                    }
                },
                isLoading: viewModel.isLookingUpProperty,
                isDisabled: !viewModel.canProceed
            )

            tertiaryLinks
                .padding(.top, 4)
        }
        .padding(.horizontal, HavenTheme.padding)
        .padding(.bottom, 24)
    }
}

// MARK: - Property Hook Cover

extension AddressHookView {
    /// Phase 20a — render the 2-page hook screen as a fullScreenCover.
    /// Page 2's CTA on the unauth path fires `onContinueToAccountGate`,
    /// which Phase 20b routes to `AccountCreationStep` (the hard account
    /// creation gate).
    fileprivate func propertyHookCover(for viewModel: AddressHookViewModel) -> some View {
        NavigationStack {
            PropertyHookView(
                address1: viewModel.street,
                city: viewModel.city,
                state: viewModel.state,
                yearBuilt: viewModel.propertyLookupResult?.yearBuilt,
                fuelType: viewModel.propertyLookupResult?.features?.heatingFuel,
                lookupResult: viewModel.propertyLookupResult,
                isAuthenticated: false,
                onContinueToAccountGate: {
                    // Phase 20b — dismiss this cover, then present the
                    // hard account creation gate. SwiftUI sequences the
                    // two covers cleanly: the first dismisses, the
                    // second presents on the next runloop tick.
                    showPropertyHook = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAccountCreation = true
                    }
                },
                onContinueToQuiz: {
                    // Unauthenticated users always go through the gate.
                }
            )
        }
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
                // Phase 60.1: instrument every hand-off point of the ATTOM
                // pipeline. If a field drops, the logs show exactly where.
                print("[ATTOM persist] edge-function decode: lastSalePrice=\(property.lastSalePrice?.description ?? "nil") estimatedValue=\(property.estimatedValue?.description ?? "nil") source=\(property.estimatedValueSource ?? "nil") yearBuilt=\(property.yearBuilt?.description ?? "nil") sqft=\(property.squareFootage?.description ?? "nil")")
                propertyLookupResult = property
            } else {
                print("[ATTOM persist] edge-function decode: no property (success=\(response.success))")
                propertyLookupResult = nil
            }
        } catch {
            print("[AddressHook] Property lookup failed: \(error)")
            print("[ATTOM persist] edge-function decode FAILED: \(error)")
            propertyLookupResult = nil
        }

        schedulePreview = OnboardingScheduleGenerator.generate(
            from: propertyLookupResult,
            state: state
        )

        isLookingUpProperty = false
    }

    /// Regenerate the schedule preview after the user corrects property details inline.
    func regenerateSchedule() {
        schedulePreview = OnboardingScheduleGenerator.generate(
            from: propertyLookupResult,
            state: state
        )
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
            // Phase 60.1: log the UserDefaults write so post-auth read
            // mismatches are traceable end-to-end.
            print("[ATTOM persist] UserDefaults write: lastSalePrice=\(result.lastSalePrice?.description ?? "nil") estimatedValue=\(result.estimatedValue?.description ?? "nil") fieldCount=\(data.count) bytes")
        } else if propertyLookupResult == nil {
            print("[ATTOM persist] UserDefaults write: no lookup result cached (propertyLookupResult is nil)")
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
            // Phase 60.1: post-auth UserDefaults read log. If the decoder
            // fails, propertyResult stays nil and we log that explicitly
            // so a post-auth trace shows exactly which leg dropped the data.
            if let cached = propertyResult {
                print("[ATTOM persist] UserDefaults read (post-auth): lastSalePrice=\(cached.lastSalePrice?.description ?? "nil") estimatedValue=\(cached.estimatedValue?.description ?? "nil")")
            } else {
                print("[ATTOM persist] UserDefaults read (post-auth): decoder returned nil for \(data.count) bytes of cached data")
            }
        } else {
            print("[ATTOM persist] UserDefaults read (post-auth): no cached propertyResult data")
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
                     "addressHook_hasData",
                     "addressHook_firstName", "addressHook_lastName"] {
            defaults.removeObject(forKey: key)
        }
    }

    /// Apr 7, 2026: stash the user's first/last name in UserDefaults from
    /// AccountCreationStep so it survives the Apple Sign In round-trip.
    /// Apple only returns `givenName`/`familyName` on the very first
    /// authorization for an app, ever — every subsequent sign-in returns
    /// nothing. Capturing the name BEFORE auth means we never have to
    /// rely on Apple to give it back.
    static func cachePendingName(first: String, last: String) {
        let defaults = UserDefaults.standard
        let trimmedFirst = first.trimmingCharacters(in: .whitespaces)
        let trimmedLast = last.trimmingCharacters(in: .whitespaces)
        if !trimmedFirst.isEmpty {
            defaults.set(trimmedFirst, forKey: "addressHook_firstName")
        }
        if !trimmedLast.isEmpty {
            defaults.set(trimmedLast, forKey: "addressHook_lastName")
        }
    }

    /// Load any pending first/last name stashed by AccountCreationStep.
    /// Returns empty strings (not nil) so callers can use them directly
    /// without unwrapping. `OnboardingViewModel.prefillFromAuth` checks
    /// these BEFORE falling back to session metadata.
    static func loadPendingName() -> (first: String, last: String) {
        let defaults = UserDefaults.standard
        return (
            first: defaults.string(forKey: "addressHook_firstName") ?? "",
            last: defaults.string(forKey: "addressHook_lastName") ?? ""
        )
    }
}
