import SwiftUI

/// Phase 16d — Q28 kids expansion. Renders below the residents chips when the
/// user picks "Family with kids" and lets them add one or more kids plus an
/// optional expecting entry. Visual style mirrors `QuizCaretakerInlineForm`
/// for consistency: the same chip-card-button rhythm, same cream surfaces,
/// same Skip / Continue footer.
///
/// Output is reported back to the parent via `onContinue(kids, expecting)`.
/// The parent (`HouseQuizView.caretakersBody`) is responsible for actually
/// recording the answer through the view model — this form only collects.
struct QuizKidsInlineForm: View {
    /// Initial kids to seed the form with (e.g. when the user is editing a
    /// previously-saved q28 answer). Empty for fresh runs.
    let initialKids: [QuizKidEntry]
    let initialExpecting: [QuizExpectingEntry]
    /// Called when the user taps Continue. Even when both arrays are empty
    /// the parent should advance — the form acts as an intentional pass-through.
    let onContinue: ([QuizKidEntry], [QuizExpectingEntry]) -> Void

    init(
        initialKids: [QuizKidEntry] = [],
        initialExpecting: [QuizExpectingEntry] = [],
        onContinue: @escaping ([QuizKidEntry], [QuizExpectingEntry]) -> Void
    ) {
        self.initialKids = initialKids
        self.initialExpecting = initialExpecting
        self.onContinue = onContinue
    }

    @State private var kids: [QuizKidEntry] = []
    @State private var expecting: [QuizExpectingEntry] = []
    @State private var didPrime: Bool = false

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("YOUR KIDS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            Text("Add each of your kids. We'll use this for emergency contacts and school reminders.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            ForEach(Array(kids.enumerated()), id: \.element.id) { index, _ in
                kidCard(at: index)
                    .transition(.opacity)
            }

            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        kids.append(QuizKidEntry(firstName: ""))
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text(kids.isEmpty ? "Add a kid" : "Add another kid")
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy)
                }
                .buttonStyle(.plain)

                if expecting.isEmpty {
                    Button {
                        Haptics.light()
                        withAnimation(HavenTheme.animationStandard) {
                            expecting.append(QuizExpectingEntry(dueDate: Self.defaultDueDate()))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.circle")
                            Text("Expecting?")
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy)
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(Array(expecting.enumerated()), id: \.element.id) { index, _ in
                expectingCard(at: index)
                    .transition(.opacity)
            }

            HavenButton(
                title: continueButtonLabel,
                action: {
                    Haptics.success()
                    let trimmedKids = kids
                        .map {
                            QuizKidEntry(
                                id: $0.id,
                                firstName: $0.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                                dateOfBirth: $0.dateOfBirth
                            )
                        }
                        .filter { !$0.firstName.isEmpty }
                    onContinue(trimmedKids, expecting)
                }
            )
        }
        .animation(HavenTheme.animationStandard, value: kids)
        .animation(HavenTheme.animationStandard, value: expecting)
        .onAppear {
            guard !didPrime else { return }
            didPrime = true
            kids = initialKids
            expecting = initialExpecting
        }
    }

    // MARK: - Kid card

    @ViewBuilder
    private func kidCard(at index: Int) -> some View {
        let kid = kids[index]
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("KID \(index + 1)")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        kids.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            HavenTextField(
                title: "First name",
                text: Binding(
                    get: { kids[safe: index]?.firstName ?? "" },
                    set: { newValue in
                        guard kids.indices.contains(index) else { return }
                        kids[index].firstName = newValue
                    }
                )
            )
            .textInputAutocapitalization(.words)

            DatePicker(
                "Date of birth",
                selection: Binding(
                    get: { Self.parseDate(kid.dateOfBirth) ?? Self.defaultKidBirthDate() },
                    set: { newValue in
                        guard kids.indices.contains(index) else { return }
                        kids[index].dateOfBirth = Self.isoFormatter.string(from: newValue)
                    }
                ),
                in: Self.kidBirthDateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Expecting card

    @ViewBuilder
    private func expectingCard(at index: Int) -> some View {
        let entry = expecting[index]
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("EXPECTING")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        expecting.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            DatePicker(
                "Due date",
                selection: Binding(
                    get: { Self.parseDate(entry.dueDate) ?? Self.defaultDueDateValue() },
                    set: { newValue in
                        guard expecting.indices.contains(index) else { return }
                        expecting[index].dueDate = Self.isoFormatter.string(from: newValue)
                    }
                ),
                in: Self.expectingDateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Helpers

    private var continueButtonLabel: String {
        let validKidCount = kids
            .filter { !$0.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        let totalAdds = validKidCount + expecting.count
        if totalAdds == 0 { return "Continue" }
        return "Continue with \(totalAdds) \(totalAdds == 1 ? "person" : "people")"
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return isoFormatter.date(from: string)
    }

    private static func defaultDueDate() -> String {
        isoFormatter.string(from: defaultDueDateValue())
    }

    private static func defaultDueDateValue() -> Date {
        Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    }

    private static func defaultKidBirthDate() -> Date {
        Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    }

    private static var kidBirthDateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let earliest = cal.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        let latest = Date()
        return earliest...latest
    }

    private static var expectingDateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let earliest = Date()
        let latest = cal.date(byAdding: .month, value: 11, to: Date()) ?? Date()
        return earliest...latest
    }
}

// Bounds-safe subscript so the closure-based bindings can't index out of range
// during the brief window between a remove and the next view update.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
