import SwiftUI

/// Address-first property add flow used everywhere a user adds a property
/// to an existing household: PropertyListView toolbar +, PropertyListView
/// empty state, DashboardView Quick Actions, Dashboard "Add your home"
/// step, and AddressConfirmationIntercept's post-purge fallback.
///
/// Three steps: address entry → ATTOM preview → confirmation. The address
/// step matches the warm welcome of the pre-auth AddressHookView so users
/// see the same UX whether they're brand new or already signed in.
///
/// On confirmation, posts `.startHouseQuiz` with the new property if the
/// user taps the optional quiz prompt; the dashboard listens and presents
/// HouseQuizView.
struct AddPropertyFlow: View {
    /// Optional callback fired after the property is created (regardless of
    /// whether the user takes the quiz prompt or not). Use this to refresh
    /// list views.
    var onComplete: ((PropertyRow) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPropertyFlowViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.currentStep != .address {
                    ProgressView(value: viewModel.progress)
                        .tint(HavenColors.navy800)
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.top, HavenTheme.spacing8)
                }

                TabView(selection: $viewModel.currentStep) {
                    addressStep
                        .tag(AddPropertyFlowStep.address)

                    OnboardingSchedulePreviewStep(
                        street: viewModel.street,
                        city: viewModel.city,
                        state: viewModel.state,
                        propertyResult: $viewModel.propertyLookupResult,
                        scheduleItems: $viewModel.schedulePreview,
                        isLoading: viewModel.isLookingUpProperty,
                        onPropertyEdited: { viewModel.regenerateSchedule() }
                    )
                    .tag(AddPropertyFlowStep.preview)

                    confirmationStep
                        .tag(AddPropertyFlowStep.confirmation)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                bottomButtons
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep != .confirmation {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
            .trackScreen("AddPropertyFlow")
        }
    }

    // MARK: - Step 1: Address Entry

    private var addressStep: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: HavenTheme.spacing16)

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Where's the home?")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("We'll pull public records and set up systems and a maintenance plan automatically.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HavenTheme.spacing8)
                }

                propertyTypePicker

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
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.critical)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    private var propertyTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HavenTheme.spacing8) {
                ForEach(AddPropertyFlowViewModel.propertyTypes, id: \.self) { type in
                    Button {
                        Haptics.selection()
                        viewModel.propertyType = type
                    } label: {
                        Text(type)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(viewModel.propertyType == type ? HavenColors.textOnNavy : HavenColors.textPrimary)
                            .padding(.horizontal, HavenTheme.spacing16)
                            .padding(.vertical, HavenTheme.spacing8)
                            .background(viewModel.propertyType == type ? HavenColors.navy800 : HavenColors.creamLight)
                            .clipShape(Capsule())
                            .overlay {
                                if viewModel.propertyType != type {
                                    Capsule().strokeBorder(HavenColors.beige300, lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HavenTheme.spacing4)
        }
    }

    // MARK: - Step 3: Confirmation

    private var confirmationStep: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                Spacer().frame(height: HavenTheme.spacing32)

                ZStack {
                    Circle()
                        .fill(HavenColors.success.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72, weight: .regular))
                        .foregroundStyle(HavenColors.success)
                }

                VStack(spacing: HavenTheme.spacing12) {
                    Text("Added \(viewModel.confirmationDisplayName)")
                        .font(HavenTypography.title)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let result = viewModel.creationResult {
                        Text(viewModel.confirmationSummary(for: result))
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, HavenTheme.spacing16)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: HavenTheme.spacing12) {
            switch viewModel.currentStep {
            case .address:
                HavenButton(title: "Find My Home") {
                    Task {
                        viewModel.currentStep = .preview
                        await viewModel.lookupProperty()
                    }
                }
                .disabled(!viewModel.canProceedFromAddress)

            case .preview:
                if !viewModel.isLookingUpProperty {
                    HavenButton(
                        title: viewModel.isCreating ? "Adding..." : "Add \(viewModel.previewActionLabel)",
                        action: {
                            Task { await viewModel.createProperty() }
                        }
                    )
                    .disabled(viewModel.isCreating)

                    Button("Back to address") {
                        viewModel.currentStep = .address
                    }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                }

            case .confirmation:
                HavenButton(title: "Take House Quiz") {
                    if let property = viewModel.creationResult?.property {
                        Analytics.track(.quizStarted, [
                            "source": "add_property_flow",
                            "property_id": property.id.uuidString
                        ])
                        NotificationCenter.default.post(
                            name: .startHouseQuiz,
                            object: property
                        )
                        onComplete?(property)
                        dismiss()
                    }
                }

                Button("Later, just add it") {
                    if let property = viewModel.creationResult?.property {
                        onComplete?(property)
                    }
                    dismiss()
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.bottom, HavenTheme.spacing24)
        .padding(.top, HavenTheme.spacing12)
    }
}

// MARK: - Step Enum

enum AddPropertyFlowStep: Int, CaseIterable {
    case address = 0
    case preview
    case confirmation
}

// MARK: - View Model

@MainActor
final class AddPropertyFlowViewModel: ObservableObject {
    static let propertyTypes = [
        "Primary Residence",
        "Vacation Home",
        "Rental Property",
        "Land"
    ]

    @Published var currentStep: AddPropertyFlowStep = .address
    @Published var errorMessage: String?

    @Published var propertyType: String = "Primary Residence"

    @Published var street = ""
    @Published var unit = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""

    @Published var propertyLookupResult: PropertyLookupResult?
    @Published var schedulePreview: [SchedulePreviewItem] = []
    @Published var isLookingUpProperty = false

    @Published var isCreating = false
    @Published var creationResult: PropertyCreationResult?

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(AddPropertyFlowStep.allCases.count)
    }

    var canProceedFromAddress: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var navigationTitle: String {
        switch currentStep {
        case .address: return "Add Property"
        case .preview: return "Confirm Details"
        case .confirmation: return ""
        }
    }

    var previewActionLabel: String {
        let trimmed = street.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "this property" }
        return trimmed
    }

    var confirmationDisplayName: String {
        if let property = creationResult?.property {
            return property.street ?? property.name
        }
        return "your property"
    }

    func confirmationSummary(for result: PropertyCreationResult) -> String {
        let systems = result.systemsCreated
        let tasks = result.tasksCreated
        if systems == 0 && tasks == 0 {
            return "We saved your property. Take the House Quiz so Haven knows what to track."
        }
        let systemsPhrase: String
        if systems == 0 {
            systemsPhrase = "no home systems yet"
        } else if systems == 1 {
            systemsPhrase = "1 home system"
        } else {
            systemsPhrase = "\(systems) home systems"
        }
        let tasksPhrase: String
        if tasks == 0 {
            tasksPhrase = "no maintenance tasks yet"
        } else if tasks == 1 {
            tasksPhrase = "1 maintenance task"
        } else {
            tasksPhrase = "\(tasks) maintenance tasks"
        }
        return "We set up \(systemsPhrase) and \(tasksPhrase) based on what we found."
    }

    func lookupProperty() async {
        isLookingUpProperty = true
        errorMessage = nil

        let fullAddress = [street, unit, city, state, zipCode]
            .map { $0.trimmingCharacters(in: .whitespaces) }
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
            print("[AddPropertyFlow] Property lookup failed: \(error)")
            propertyLookupResult = nil
        }

        schedulePreview = OnboardingScheduleGenerator.generate(
            from: propertyLookupResult,
            state: state
        )
        isLookingUpProperty = false
    }

    func regenerateSchedule() {
        schedulePreview = OnboardingScheduleGenerator.generate(
            from: propertyLookupResult,
            state: state
        )
    }

    func createProperty() async {
        guard !isCreating else { return }
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                errorMessage = "Couldn't find your household. Try signing out and back in."
                return
            }

            let address = AddressInput(
                street: street,
                unit: unit,
                city: city,
                state: state,
                zipCode: zipCode
            )

            let result = try await PropertyCreationService.shared.createProperty(
                address: address,
                householdId: householdId,
                propertyType: propertyType,
                lookupResult: propertyLookupResult
            )

            creationResult = result
            Analytics.track(.propertyCreated, [
                "source": "add_property_flow",
                "property_id": result.property.id.uuidString,
                "lookup_succeeded": result.lookupSucceeded
            ])
            Haptics.success()
            currentStep = .confirmation
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        } catch {
            errorMessage = "Setup failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
