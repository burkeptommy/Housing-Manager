import SwiftUI

/// Q28 caretaker section. Chips along the top let the user expand a card
/// with a single first-name field per role. Multiple roles can be expanded
/// simultaneously, and "Add another nanny" / "Add another housekeeper"
/// buttons stack additional name cards inside each role group.
///
/// Submit goes through HouseholdInviteCoordinator with sendInvite false
/// (caretakers usually don't need Haven access; Tom can later upgrade them
/// from the Family tab).
///
/// Skip is always positively framed. Empty caretakers and a tap on Continue
/// produce no side effects.
struct QuizCaretakerInlineForm: View {
    let householdId: UUID
    /// Called when the form is done (caretakers committed, or skipped).
    let onComplete: () -> Void

    @State private var expandedRoles: Set<Role> = []
    @State private var entries: [Role: [String]] = [:]
    @State private var isSubmitting: Bool = false
    @State private var submitError: String? = nil
    @State private var didConfirm: Bool = false

    private enum Role: String, CaseIterable, Hashable {
        case nanny
        case auPair
        case housekeeper
        case personalAssistant
        case propertyManager
        case elderCaregiver

        var label: String {
            switch self {
            case .nanny: return "Nanny"
            case .auPair: return "Au Pair"
            case .housekeeper: return "Housekeeper"
            case .personalAssistant: return "Personal Assistant"
            case .propertyManager: return "Property Manager"
            case .elderCaregiver: return "Elder Caregiver"
            }
        }

        var icon: String {
            switch self {
            case .nanny: return "person.fill"
            case .auPair: return "person.2.fill"
            case .housekeeper: return "house.fill"
            case .personalAssistant: return "briefcase.fill"
            case .propertyManager: return "building.2.fill"
            case .elderCaregiver: return "heart.fill"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("WHO ELSE HELPS CARE FOR YOUR HOME OR FAMILY?")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            Text("Optional. Add anyone who's regularly involved.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            chipRow

            ForEach(Array(Role.allCases), id: \.self) { role in
                if expandedRoles.contains(role) {
                    roleCard(role: role)
                        .transition(.opacity)
                }
            }

            if didConfirm {
                Text("Haven will remember them as part of your household.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let submitError {
                Text(submitError)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HStack(spacing: HavenTheme.spacing12) {
                HavenButton(
                    title: "Skip for now",
                    action: { onComplete() },
                    style: .secondary
                )
                HavenButton(
                    title: continueButtonLabel,
                    action: { Task { await submit() } }
                )
                .disabled(isSubmitting)
            }
        }
        .animation(HavenTheme.animationStandard, value: expandedRoles)
        .animation(HavenTheme.animationStandard, value: entries)
    }

    // MARK: - Chips

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HavenTheme.spacing8) {
                ForEach(Array(Role.allCases), id: \.self) { role in
                    chip(role: role)
                }
            }
        }
    }

    private func chip(role: Role) -> some View {
        let isExpanded = expandedRoles.contains(role)
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                if isExpanded {
                    expandedRoles.remove(role)
                } else {
                    expandedRoles.insert(role)
                    if entries[role]?.isEmpty ?? true {
                        entries[role] = [""]
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: role.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(role.label)
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(isExpanded ? HavenColors.textOnNavy : HavenColors.navy)
            .padding(.horizontal, HavenTheme.spacing12)
            .padding(.vertical, HavenTheme.spacing8)
            .background(isExpanded ? HavenColors.navy : HavenColors.creamLight)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isExpanded ? HavenColors.navy : HavenColors.beige300,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Role card

    private func roleCard(role: Role) -> some View {
        let names = entries[role] ?? [""]
        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text(role.label.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    withAnimation(HavenTheme.animationStandard) {
                        expandedRoles.remove(role)
                        entries[role] = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(names.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: HavenTheme.spacing8) {
                    HavenTextField(
                        title: "First name or nickname",
                        text: Binding(
                            get: { entries[role]?[index] ?? "" },
                            set: { newValue in
                                var current = entries[role] ?? [""]
                                while current.count <= index { current.append("") }
                                current[index] = newValue
                                entries[role] = current
                            }
                        )
                    )
                    .textInputAutocapitalization(.words)
                    if names.count > 1 {
                        Button {
                            var current = entries[role] ?? []
                            if index < current.count {
                                current.remove(at: index)
                                entries[role] = current
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                var current = entries[role] ?? []
                current.append("")
                entries[role] = current
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add another \(role.label.lowercased())")
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy)
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Submit

    private var continueButtonLabel: String {
        let total = countNonEmpty()
        if total == 0 { return "Continue" }
        if isSubmitting { return "Adding..." }
        return "Add \(total) \(total == 1 ? "person" : "people")"
    }

    private func countNonEmpty() -> Int {
        entries.values.flatMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }

    private func submit() async {
        let toAdd = entries.flatMap { (role, names) in
            names
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { (role: role, name: $0) }
        }

        guard !toAdd.isEmpty else {
            onComplete()
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        submitError = nil

        for entry in toAdd {
            let request = HouseholdInviteCoordinator.AddPersonRequest(
                householdId: householdId,
                firstName: entry.name,
                lastName: nil,
                relationship: entry.role.label,
                email: nil,
                phone: nil,
                dateOfBirth: nil,
                gender: nil,
                isMinor: false,
                sendInvite: false,
                personalMessage: nil,
                source: .quizCaretakerStep
            )
            do {
                _ = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(request)
            } catch {
                submitError = "Couldn't add \(entry.name): \(error.localizedDescription)"
                Haptics.error()
                return
            }
        }

        Haptics.success()
        didConfirm = true
        // Brief pause so the user sees the confirmation copy before the quiz advances.
        try? await Task.sleep(nanoseconds: 600_000_000)
        onComplete()
    }
}
