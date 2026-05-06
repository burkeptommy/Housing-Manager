import SwiftUI

/// Phase 80.1 — Standing-instructions surface for Chez. The user fills
/// this once; Chez reads it on every request afterward, so subsequent
/// asks land with the concierge already knowing them.
///
/// Visual: settings-style scrollable form with five sections —
///   1. About your household (free-form intro)
///   2. Communication preferences
///   3. Spending authority (3 tiers)
///   4. Vendor preferences
///   5. Logistics (pets / entry / vendor access)
///   6. Standing engagements (read-only summary of routines / vendors
///      Chez owns; tap to revoke)
///
/// Save behavior: every edit fires `viewModel.saveDebounced()` so the
/// network call lands ~600ms after the last keystroke. Toolbar shows
/// a tiny "Saved" pill the moment the write succeeds.
struct ChezProfileView: View {
    @StateObject private var viewModel = ChezProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Optional: when presented as a sheet from another flow (e.g.
    /// "Set up your Chez profile" CTA inside the composer), call this
    /// when done so the parent can resume.
    var onDone: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    aboutUsSection
                    spendingTiersSection
                    communicationSection
                    vendorPreferencesSection
                    logisticsSection
                    standingEngagementsSection
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, 16)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Your Chez profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        Task { await viewModel.saveNow() }
                        onDone?()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.action)
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView().scaleEffect(0.8).tint(HavenColors.textSecondary)
                    } else if let saved = viewModel.lastSavedAt,
                              Date().timeIntervalSince(saved) < 3 {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.success)
                    }
                }
            }
            .task {
                Analytics.track(.chezProfileViewed)
                await viewModel.load()
            }
            .trackScreen("ChezProfileView")
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Standing instructions")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Fill this once. Chez reads it on every request, so the next ask lands with us already knowing your household.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - About us

    private var aboutUsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ABOUT YOUR HOUSEHOLD")
            captionText("Tell Chez who you are, what matters, and anything they should know up front.")
            TextEditor(text: Binding(
                get: { viewModel.profile.aboutUs ?? "" },
                set: { viewModel.profile.aboutUs = $0; viewModel.saveDebounced() }
            ))
            .font(HavenTypography.body)
            .frame(minHeight: 120)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if (viewModel.profile.aboutUs ?? "").isEmpty {
                    Text("e.g. Family of 4 in Bedford. Two dogs. Old colonial. Vendors should expect quirky plumbing. We host every other weekend so book vendors weekday mornings when possible.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Spending tiers

    private var spendingTiersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SPENDING AUTHORITY")
            captionText("How much can Chez spend on your behalf without asking? Defaults are conservative. Adjust to your taste.")
            tierStepper(
                label: "Auto-approve under",
                amount: Binding(
                    get: { viewModel.profile.spendingTiers?.autoApproveUnder ?? 200 },
                    set: { newVal in
                        viewModel.ensureSpendingTiers()
                        viewModel.profile.spendingTiers?.autoApproveUnder = newVal
                        viewModel.saveDebounced()
                    }
                ),
                step: 50, range: 0...2000,
                hint: "Chez handles routine work up to this amount and tells you after."
            )
            tierStepper(
                label: "Ping me under",
                amount: Binding(
                    get: { viewModel.profile.spendingTiers?.pingUnder ?? 500 },
                    set: { newVal in
                        viewModel.ensureSpendingTiers()
                        viewModel.profile.spendingTiers?.pingUnder = newVal
                        viewModel.saveDebounced()
                    }
                ),
                step: 50, range: 0...5000,
                hint: "Chez sends a quick heads-up before booking. Usually a 1-tap approve."
            )
            tierStepper(
                label: "Always ask above",
                amount: Binding(
                    get: { viewModel.profile.spendingTiers?.explicitAbove ?? 500 },
                    set: { newVal in
                        viewModel.ensureSpendingTiers()
                        viewModel.profile.spendingTiers?.explicitAbove = newVal
                        viewModel.saveDebounced()
                    }
                ),
                step: 100, range: 0...50000,
                hint: "Anything above this requires explicit approval before Chez moves."
            )
        }
        .padding(14)
        // Phase 95.1 fix: was a salmon-tinted background covering ~40%
        // of the screen on the Spending Authority section. The card is
        // a settings/configuration block, not a CTA — pure-white card
        // with subtle navy border matches every other section in the
        // form.
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HavenColors.beige300, lineWidth: 1)
                )
        )
    }

    private func tierStepper(
        label: String,
        amount: Binding<Int>,
        step: Int,
        range: ClosedRange<Int>,
        hint: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(hint)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Stepper(value: amount, in: range, step: step) {
                    Text("$\(amount.wrappedValue)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(minWidth: 64, alignment: .trailing)
                }
                .labelsHidden()
            }
        }
    }

    // MARK: - Communication

    private var communicationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("COMMUNICATION")
            captionText("How Chez should reach you and when.")
            Picker("Preferred channel", selection: Binding(
                get: { viewModel.profile.communication?.preferredChannel ?? "either" },
                set: { newVal in
                    if viewModel.profile.communication == nil {
                        viewModel.profile.communication = ChezCommunicationPrefs()
                    }
                    viewModel.profile.communication?.preferredChannel = newVal
                    viewModel.saveDebounced()
                }
            )) {
                Text("Email or push").tag("either")
                Text("Email only").tag("email")
                Text("SMS only").tag("sms")
            }
            .pickerStyle(.segmented)

            Toggle(isOn: Binding(
                get: { viewModel.profile.communication?.vacationMode ?? false },
                set: { newVal in
                    if viewModel.profile.communication == nil {
                        viewModel.profile.communication = ChezCommunicationPrefs()
                    }
                    viewModel.profile.communication?.vacationMode = newVal
                    viewModel.saveDebounced()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vacation mode").font(HavenTypography.uiLabel)
                    Text("Tell Chez you're traveling. They'll act with full latitude on standing engagements until you flip this off.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .tint(HavenColors.action)

            if viewModel.profile.communication?.vacationMode == true {
                TextField(
                    "Trip notes (optional). Dates, anyone with key access, etc.",
                    text: Binding(
                        get: { viewModel.profile.communication?.vacationNotes ?? "" },
                        set: { newVal in
                            if viewModel.profile.communication == nil {
                                viewModel.profile.communication = ChezCommunicationPrefs()
                            }
                            viewModel.profile.communication?.vacationNotes = newVal
                            viewModel.saveDebounced()
                        }
                    ),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .font(HavenTypography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Vendor preferences

    private var vendorPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("VENDOR PREFERENCES")
            captionText("How Chez should weigh choices when picking pros for you.")
            Picker("Budget orientation", selection: Binding(
                get: { viewModel.profile.vendorPreferences?.budgetOrientation ?? "standard" },
                set: { newVal in
                    if viewModel.profile.vendorPreferences == nil {
                        viewModel.profile.vendorPreferences = ChezVendorPrefs()
                    }
                    viewModel.profile.vendorPreferences?.budgetOrientation = newVal
                    viewModel.saveDebounced()
                }
            )) {
                Text("Budget").tag("budget")
                Text("Standard").tag("standard")
                Text("Premium").tag("premium")
            }
            .pickerStyle(.segmented)

            Toggle(isOn: Binding(
                get: { viewModel.profile.vendorPreferences?.preferLocalOwned ?? false },
                set: { newVal in
                    if viewModel.profile.vendorPreferences == nil {
                        viewModel.profile.vendorPreferences = ChezVendorPrefs()
                    }
                    viewModel.profile.vendorPreferences?.preferLocalOwned = newVal
                    viewModel.saveDebounced()
                }
            )) {
                Text("Prefer local-owned").font(HavenTypography.uiLabel)
            }
            .tint(HavenColors.action)

            Toggle(isOn: Binding(
                get: { viewModel.profile.vendorPreferences?.avoidChains ?? false },
                set: { newVal in
                    if viewModel.profile.vendorPreferences == nil {
                        viewModel.profile.vendorPreferences = ChezVendorPrefs()
                    }
                    viewModel.profile.vendorPreferences?.avoidChains = newVal
                    viewModel.saveDebounced()
                }
            )) {
                Text("Avoid chain brands").font(HavenTypography.uiLabel)
            }
            .tint(HavenColors.action)

            VStack(alignment: .leading, spacing: 4) {
                Text("Other notes for Chez")
                    .font(HavenTypography.uiLabel)
                TextField(
                    "e.g. Prefer female-owned. Vendors must be licensed + insured. No subcontracting without telling us first.",
                    text: Binding(
                        get: { viewModel.profile.vendorPreferences?.notes ?? "" },
                        set: { newVal in
                            if viewModel.profile.vendorPreferences == nil {
                                viewModel.profile.vendorPreferences = ChezVendorPrefs()
                            }
                            viewModel.profile.vendorPreferences?.notes = newVal
                            viewModel.saveDebounced()
                        }
                    ),
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(HavenTypography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Logistics

    private var logisticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("LOGISTICS & ACCESS")
            captionText("Anything vendors should know when arriving at the property.")
            Toggle(isOn: Binding(
                get: { viewModel.profile.logistics?.hasPets ?? false },
                set: { newVal in
                    if viewModel.profile.logistics == nil {
                        viewModel.profile.logistics = ChezLogistics()
                    }
                    viewModel.profile.logistics?.hasPets = newVal
                    viewModel.saveDebounced()
                }
            )) {
                Text("We have pets").font(HavenTypography.uiLabel)
            }
            .tint(HavenColors.action)

            if viewModel.profile.logistics?.hasPets == true {
                TextField(
                    "Pet notes (e.g. Friendly dog, lock back gate)",
                    text: Binding(
                        get: { viewModel.profile.logistics?.petNotes ?? "" },
                        set: { newVal in
                            if viewModel.profile.logistics == nil {
                                viewModel.profile.logistics = ChezLogistics()
                            }
                            viewModel.profile.logistics?.petNotes = newVal
                            viewModel.saveDebounced()
                        }
                    ),
                    axis: .vertical
                )
                .lineLimit(1...3)
                .font(HavenTypography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Entry instructions")
                    .font(HavenTypography.uiLabel)
                TextField(
                    "e.g. Side gate code 1234. Vendors use side entrance.",
                    text: Binding(
                        get: { viewModel.profile.logistics?.entryInstructions ?? "" },
                        set: { newVal in
                            if viewModel.profile.logistics == nil {
                                viewModel.profile.logistics = ChezLogistics()
                            }
                            viewModel.profile.logistics?.entryInstructions = newVal
                            viewModel.saveDebounced()
                        }
                    ),
                    axis: .vertical
                )
                .lineLimit(1...3)
                .font(HavenTypography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Standing engagements (read-only summary)

    private var standingEngagementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("STANDING ENGAGEMENTS")
            captionText("Everything you've handed off to Chez. Routines, vendor relationships, and individual tasks.")
            NavigationLink {
                ChezDelegationsListView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(HavenColors.action.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.action)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View what Chez owns")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Routines, vendors, and individual tasks Chez is handling for you.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
            .padding(.top, 4)
    }

    private func captionText(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.caption)
            .foregroundStyle(HavenColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
