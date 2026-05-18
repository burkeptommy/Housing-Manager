import SwiftUI

/// Phase 84.5 — universal 7-question pre-onboarding form.
///
/// Captures the things only the homeowner can answer regardless of which
/// onboarding path they pick afterward (quiz vs handyman). Every answer
/// persists to `properties.house_quiz_state.answers` so the existing
/// reconciler reads them as if they came from the quiz.
///
/// Questions:
/// 1. Family composition (Q28)
/// 2. Pet presence (Q28 sub)
/// 3. Vehicles (Q24)
/// 4. Insurance carriers (Q26)
/// 5. Trash days (Q18)
/// 6. Top priority (Q30)
/// 7. DIY-vs-hire tier (Q36)
struct FoundationalQuestionsForm: View {
    @State private var answers: FoundationalAnswers
    @State private var stepIndex: Int = 0
    @State private var showSkipConfirm = false
    let onComplete: (FoundationalAnswers) -> Void
    /// Phase 95 — optional escape hatch. When provided, a "Skip for now"
    /// link appears in the toolbar; tapping confirms then calls this
    /// closure to drop the user on the dashboard with a banner offering
    /// to finish setup later. Pass `nil` to keep the form mandatory
    /// (the original Phase 84.5 behavior, e.g. first-launch flow where
    /// some signal IS required before we can render Path B fork).
    let onSkip: (() -> Void)?

    init(
        initial: FoundationalAnswers? = nil,
        onComplete: @escaping (FoundationalAnswers) -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self._answers = State(initialValue: initial ?? FoundationalAnswers())
        self.onComplete = onComplete
        self.onSkip = onSkip
    }

    /// Phase 95 (gap #2): bumped from 7 → 8 to capture will-be-home and
    /// access instructions inline. Previously these fields existed on
    /// FoundationalAnswers but were never collected during the form;
    /// the handyman path's prep card collected them after the fork.
    /// Now we capture them upfront so applyModeChoice(.handyman) can
    /// fire requestHomeAssessment with real data the first time.
    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                progressBar
                Spacer(minLength: 12)
                if onSkip != nil {
                    Button("Skip for now") {
                        Haptics.light()
                        showSkipConfirm = true
                    }
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .padding(.horizontal, HavenTheme.spacing20)
            .padding(.top, HavenTheme.spacing16)

            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                    stepHeader

                    Group {
                        switch stepIndex {
                        case 0: householdStep
                        case 1: petsStep
                        case 2: vehiclesStep
                        case 3: insuranceStep
                        case 4: trashStep
                        case 5: priorityStep
                        case 6: tierStep
                        case 7: visitDetailsStep
                        default: EmptyView()
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing24)
            }

            Divider()
            footerControls
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background.ignoresSafeArea())
        .alert("Skip these questions?", isPresented: $showSkipConfirm) {
            Button("Skip", role: .destructive) {
                onSkip?()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll see a banner on the dashboard so you can finish later. Without these answers Chez can't tailor maintenance, schedule recommendations, or invite the right people.")
        }
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(stepIndex + 1) of \(totalSteps)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text("About 5 minutes")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(HavenColors.beige200)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(HavenColors.action)
                        .frame(width: geo.size.width * progressFraction, height: 4)
                        .animation(HavenTheme.animationStandard, value: stepIndex)
                }
            }
            .frame(height: 4)
        }
    }

    private var progressFraction: CGFloat {
        CGFloat(stepIndex + 1) / CGFloat(totalSteps)
    }

    @ViewBuilder
    private var stepHeader: some View {
        let (title, subtitle) = stepCopy(for: stepIndex)
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private func stepCopy(for index: Int) -> (String, String) {
        switch index {
        case 0: return ("Who lives here?", "We tailor recommendations and tasks based on your household.")
        case 1: return ("Any pets?", "Pet households get specific routines (yard cleanup, pet-area treatments).")
        case 2: return ("What do you drive?", "We'll track maintenance for each vehicle alongside the home.")
        case 3: return ("Insurance carriers", "Optional. Helps us flag policy renewals and coverage gaps.")
        case 4: return ("Trash & recycling", "We'll remind you the day before each pickup.")
        case 5: return ("What matters most to you?", "Drives how we prioritize recommendations.")
        case 6: return ("How do you like to handle work?", "We use this to route every task: DIY-able vs hire-out vendor.")
        case 7: return ("If a Chez handyman visits...", "Helps the field team know what to expect on day one.")
        default: return ("", "")
        }
    }

    // MARK: Step 1 — Household composition (Q28)

    @ViewBuilder
    private var householdStep: some View {
        let options: [(String, String)] = [
            ("just_me", "Just me"),
            ("couple", "A couple"),
            ("family_with_kids", "Family with kids"),
            ("multi_generational", "Multi-generational household"),
            ("other", "Something else")
        ]
        VStack(spacing: 12) {
            ForEach(options, id: \.0) { (key, label) in
                singleChoiceRow(label: label, isSelected: answers.householdType == key) {
                    answers.householdType = key
                }
            }
        }
    }

    // MARK: Step 2 — Pets (Q28 sub)

    @ViewBuilder
    private var petsStep: some View {
        VStack(spacing: 12) {
            singleChoiceRow(label: "Yes, we have pets", isSelected: answers.hasPets == true) {
                answers.hasPets = true
            }
            singleChoiceRow(label: "No pets", isSelected: answers.hasPets == false) {
                answers.hasPets = false
            }
        }
    }

    // MARK: Step 3 — Vehicles (Q24)

    @ViewBuilder
    private var vehiclesStep: some View {
        VStack(spacing: 12) {
            ForEach(answers.vehicles.indices, id: \.self) { idx in
                vehicleRow(index: idx)
            }
            Button {
                // Adding a vehicle clears any prior explicit-skip state
                // so the breadcrumb reflects the homeowner's latest intent.
                answers.vehiclesSkipped = false
                answers.vehicles.append(FoundationalVehicle(vin: nil, year: nil, make: nil, model: nil))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add a vehicle")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.action)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .fill(HavenColors.action.opacity(0.1))
                )
            }
            Text("You can add more later. They stay attached to your household.")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)

            // Round 2 (May 2026): the Next button at the bottom of the
            // form already accepts an empty vehicle list, but tapping it
            // leaves no record of WHY — was the user actively skipping
            // or just not engaging? The explicit Skip captures intent so
            // drop-off analytics can distinguish the two, and the value
            // surfaces in the homeowner's record as "I'll add cars later"
            // rather than "didn't answer."
            if answers.vehicles.isEmpty {
                Button {
                    answers.vehiclesSkipped = true
                    Analytics.track(.foundationalVehiclesSkipped, [:])
                } label: {
                    HStack(spacing: 6) {
                        if answers.vehiclesSkipped == true {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.action)
                        }
                        Text(answers.vehiclesSkipped == true ? "I'll add cars later" : "Skip — I'll add cars later")
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(
                                answers.vehiclesSkipped == true
                                    ? HavenColors.action.opacity(0.4)
                                    : HavenColors.border,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func vehicleRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Vehicle \(index + 1)")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Button {
                    answers.vehicles.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            HStack(spacing: 8) {
                yearField(idx: index)
                makeField(idx: index)
            }
            modelField(idx: index)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .fill(HavenColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
        )
    }

    private func yearField(idx: Int) -> some View {
        TextField("Year", text: Binding(
            get: { answers.vehicles[idx].year.map(String.init) ?? "" },
            set: { answers.vehicles[idx].year = Int($0) }
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(HavenInputFieldStyle())
        .frame(width: 90)
    }

    private func makeField(idx: Int) -> some View {
        TextField("Make", text: Binding(
            get: { answers.vehicles[idx].make ?? "" },
            set: { answers.vehicles[idx].make = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(HavenInputFieldStyle())
    }

    private func modelField(idx: Int) -> some View {
        TextField("Model", text: Binding(
            get: { answers.vehicles[idx].model ?? "" },
            set: { answers.vehicles[idx].model = $0.isEmpty ? nil : $0 }
        ))
        .textFieldStyle(HavenInputFieldStyle())
    }

    // MARK: Step 4 — Insurance (Q26)

    @ViewBuilder
    private var insuranceStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AUTO INSURANCE")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                TextField("e.g. State Farm", text: Binding(
                    get: { answers.autoInsuranceCarrier ?? "" },
                    set: { answers.autoInsuranceCarrier = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(HavenInputFieldStyle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("HOME INSURANCE")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                TextField("e.g. Liberty Mutual", text: Binding(
                    get: { answers.homeInsuranceCarrier ?? "" },
                    set: { answers.homeInsuranceCarrier = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(HavenInputFieldStyle())
            }
            Text("Skip if you don't remember. We can capture this later.")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: Step 5 — Trash days (Q18)

    @ViewBuilder
    private var trashStep: some View {
        let dayLabels: [(Int, String)] = [
            (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
        ]
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(dayLabels, id: \.0) { (day, label) in
                    dayChip(day: day, label: label)
                }
            }
            Text("Tap each day pickup happens (trash, recycling, or both).")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private func dayChip(day: Int, label: String) -> some View {
        let isSelected = answers.trashPickupDays.contains(day)
        return Button {
            if isSelected {
                answers.trashPickupDays.removeAll { $0 == day }
            } else {
                answers.trashPickupDays.append(day)
            }
        } label: {
            Text(label)
                .font(HavenTypography.uiButton)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(isSelected ? HavenColors.action : HavenColors.surface)
                )
                .foregroundStyle(isSelected ? HavenColors.textOnAction : HavenColors.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(isSelected ? HavenColors.action : HavenColors.border, lineWidth: 1)
                )
        }
    }

    // MARK: Step 6 — Priority (Q30)

    @ViewBuilder
    private var priorityStep: some View {
        let options: [(String, String, String)] = [
            ("financial", "Protecting my investment", "Maximize home value, prevent expensive failures."),
            ("safety", "Safety & peace of mind", "Catch hazards early: gas, electrical, structural."),
            ("aesthetic", "Looking and feeling great", "Keep the home presenting at its best."),
            ("minimal_effort", "Minimal effort from me", "Hand off as much as possible to professionals.")
        ]
        VStack(spacing: 12) {
            ForEach(options, id: \.0) { (key, label, blurb) in
                selectableRow(
                    label: label,
                    blurb: blurb,
                    isSelected: answers.topPriority == key,
                    onTap: { answers.topPriority = key }
                )
            }
        }
    }

    /// Pre-2026-05-05 this was `priorityRow` and it was hardcoded to read
    /// and write `answers.topPriority`. Step 7 (`tierStep`) tried to layer
    /// `.onTapGesture` on top to redirect taps into `preferenceTier`, but
    /// the inner `Button` consumed every tap before `.onTapGesture` could
    /// fire — so step 7 never set `preferenceTier`, the Next button stayed
    /// disabled forever, AND tapping step 7 silently overwrote the step 6
    /// answer the user had already made. Caught driving the FoundationalQuestionsForm
    /// in the simulator with the same address used by the backend E2E test.
    /// Now the helper takes its selection state and tap handler as inputs
    /// so step 6 and step 7 can share the visual treatment without sharing
    /// the binding.
    private func selectableRow(
        label: String,
        blurb: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(blurb)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(isSelected ? HavenColors.action.opacity(0.1) : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(isSelected ? HavenColors.action : HavenColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    // MARK: Step 7 — DIY tier (Q36)

    @ViewBuilder
    private var tierStep: some View {
        let options: [(String, String, String)] = [
            ("diy", "I handle it", "I prefer to do most home tasks myself."),
            ("mixed", "Mix of both", "Some I'll do, bigger jobs I want a pro."),
            ("hire_out", "Hire it out", "I'd rather have professionals handle everything.")
        ]
        VStack(spacing: 12) {
            ForEach(options, id: \.0) { (key, label, blurb) in
                selectableRow(
                    label: label,
                    blurb: blurb,
                    isSelected: answers.preferenceTier == key,
                    onTap: { answers.preferenceTier = key }
                )
            }
        }
    }

    // MARK: Step 8 — Visit details (Phase 95, gap #2)

    /// Captures will-be-home + access notes upfront so the handyman
    /// path can fire requestHomeAssessment with real data the first
    /// time. The field is also useful for the DIY path (e.g. when the
    /// homeowner later requests an assessment from Settings).
    @ViewBuilder
    private var visitDetailsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $answers.willBeHomeForVisit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I'll be home")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Greet the team and walk through your home with them.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .tint(HavenColors.action)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.border, lineWidth: 1)
            )

            // Access notes only show when the user won't be home — that's
            // when gate codes / lockbox locations / dog-in-yard caveats
            // become important. Always-home visits don't need them.
            if !answers.willBeHomeForVisit {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ACCESS INSTRUCTIONS")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextEditor(text: Binding(
                        get: { answers.accessInstructions ?? "" },
                        set: { answers.accessInstructions = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 88)
                    .padding(8)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .stroke(HavenColors.border, lineWidth: 1)
                    )
                    Text("Gate code, lockbox location, dog in the yard, where to park, anything we should know before arriving.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    // MARK: Helpers

    private func singleChoiceRow(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.action)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(isSelected ? HavenColors.action.opacity(0.1) : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(isSelected ? HavenColors.action : HavenColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    private var footerControls: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    withAnimation(HavenTheme.animationStandard) {
                        stepIndex = max(0, stepIndex - 1)
                    }
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textPrimary)
            }
            Spacer()
            Button(stepIndex == totalSteps - 1 ? "Continue" : "Next") {
                if stepIndex == totalSteps - 1 {
                    onComplete(answers)
                } else {
                    withAnimation(HavenTheme.animationStandard) {
                        stepIndex = min(totalSteps - 1, stepIndex + 1)
                    }
                    Haptics.selection()
                }
            }
            .disabled(!canAdvance)
            .font(HavenTypography.uiButton)
            .foregroundStyle(canAdvance ? HavenColors.textOnAction : HavenColors.textOnAction.opacity(0.5))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .fill(canAdvance ? HavenColors.action : HavenColors.action.opacity(0.5))
            )
        }
    }

    private var canAdvance: Bool {
        switch stepIndex {
        case 0: return answers.householdType != nil
        case 1: return answers.hasPets != nil   // user must explicitly pick yes or no
        case 2: return true   // vehicles optional
        case 3: return true   // insurance optional
        case 4: return true   // trash days optional
        case 5: return answers.topPriority != nil
        case 6: return answers.preferenceTier != nil
        case 7: return true   // visit details all optional; toggle defaults to true
        default: return true
        }
    }
}

/// Standard Haven text input style.
private struct HavenInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(HavenColors.beige200.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.border, lineWidth: 1)
            )
    }
}
