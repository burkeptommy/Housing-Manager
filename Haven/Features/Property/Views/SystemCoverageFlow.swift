import SwiftUI

/// Chez v1: full-screen one-system-at-a-time install-date capture flow.
/// Opened from `SystemCoverageCard` on the Systems sub-tab.
///
/// Each card asks ONE question: "When was your roof installed?" with
/// three big buttons:
///   1. **I know the year** — opens an inline year picker (1900–today).
///   2. **I'll estimate** — reveals four quick-pick chips:
///         "Original to the house (1985)" — uses the property's year_built
///         "When we bought it (2019)"     — uses the user's purchase date
///         "Within the last 5 years"      — today − 2.5 years
///         "5 to 10 years ago"            — today − 7.5 years
///   3. **I don't know** — stamps `install_date_unknown_at`. The audit
///      gives this system a 90-day cooldown.
///
/// ATTOM-pre-filled rows show a "Confirm or correct" banner with a
/// pre-filled estimated year; the user can accept (one tap) or pick
/// a different option.
///
/// Progress bar at the top shows "3 of 12". On the last card, the
/// flow shows a celebratory completion screen with the new
/// percentage.
struct SystemCoverageFlow: View {
    let systems: [HomeSystemRow]
    let property: PropertyRow
    var onComplete: (() -> Void)?

    @State private var currentIndex: Int = 0
    @State private var totalProcessed: Int = 0
    @State private var animateProgress: Bool = false
    @Environment(\.dismiss) private var dismiss

    private let db = DatabaseService.shared
    private let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if systems.isEmpty {
                    emptyState
                } else if currentIndex >= systems.count {
                    completionScreen
                } else {
                    VStack(spacing: HavenTheme.spacing20) {
                        progressHeader
                        ScrollView {
                            cardForCurrentSystem
                                .padding(.horizontal, HavenTheme.pageMargin)
                                .padding(.top, HavenTheme.spacing12)
                                .padding(.bottom, HavenTheme.spacing32)
                        }
                    }
                }
            }
            .navigationTitle("System coverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: HavenTheme.spacing8) {
            HStack {
                Text("\(min(currentIndex + 1, systems.count)) of \(systems.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                    .tracking(1.2)
                    .contentTransition(.numericText(value: Double(currentIndex)))
                Spacer()
                if totalProcessed > 0 {
                    Text("\(totalProcessed) saved")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.success)
                        .contentTransition(.numericText(value: Double(totalProcessed)))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HavenColors.beige200)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [HavenColors.action, HavenColors.action.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(4, geo.size.width * CGFloat(currentIndex) / CGFloat(max(1, systems.count))))
                        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: currentIndex)
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing12)
    }

    // MARK: - Card for current system

    @ViewBuilder
    private var cardForCurrentSystem: some View {
        if currentIndex < systems.count {
            SystemCoverageCardView(
                system: systems[currentIndex],
                property: property,
                onSaveExact: { year in
                    Task { await save(yearString: "\(year)-01-01", source: "exact") }
                },
                onSaveEstimate: { year in
                    Task { await save(yearString: "\(year)-01-01", source: "estimated") }
                },
                onSaveUnknown: {
                    Task { await saveUnknown() }
                },
                onArchive: {
                    Task { await archiveCurrentSystem() }
                },
                onSkip: {
                    Haptics.light()
                    advance()
                }
            )
            .id(systems[currentIndex].id)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
        }
    }

    // MARK: - Completion screen

    private var completionScreen: some View {
        // Chez Design System: cinematic completion moment matching
        // QuizCinematicReveal — Fraunces hero number, success haptic
        // on appear, indigo-tinted shadow on the seal, single salmon
        // CTA. No confetti, no chime — Chez is premium, not gamified.
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(HavenColors.success)
                .shadow(color: HavenColors.navy.opacity(0.18), radius: 20, x: 0, y: 12)
            VStack(spacing: HavenTheme.spacing8) {
                Text("\(totalProcessed) of \(systems.count)")
                    .font(HavenTypography.fraunces(size: 56, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                    .contentTransition(.numericText(value: Double(totalProcessed)))
                Text(totalProcessed == systems.count
                    ? "every system on this property"
                    : "systems verified")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing24)
            }
            Spacer()
            HavenButton(
                title: "Done",
                action: {
                    Haptics.success()
                    onComplete?()
                    dismiss()
                },
                isFullWidth: true
            )
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing24)
        }
        .onAppear {
            Haptics.success()
        }
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.success)
            Text("Nothing to verify")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Every system on this property already has an install date on file.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Save / advance

    private func save(yearString: String, source: String) async {
        guard currentIndex < systems.count else { return }
        let system = systems[currentIndex]
        var update = HomeSystemUpdate()
        update.installDate = yearString
        update.installDateSource = source
        update.installDateConfirmedAt = Date()
        update.installDateAttomPrefilled = false
        _ = try? await db.updateHomeSystem(id: system.id, update)
        await MainActor.run {
            Haptics.success()
            totalProcessed += 1
            advance()
        }
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
    }

    private func saveUnknown() async {
        guard currentIndex < systems.count else { return }
        let system = systems[currentIndex]
        var update = HomeSystemUpdate()
        update.installDateSource = "unknown"
        update.installDateUnknownAt = Date()
        _ = try? await db.updateHomeSystem(id: system.id, update)
        await MainActor.run {
            Haptics.light()
            totalProcessed += 1
            advance()
        }
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
    }

    /// Soft-deletes the current system via `archived_at`. Used by the
    /// "I don't have this" affordance — meant for systems the home
    /// truly doesn't have (no irrigation, no pool) so they disappear
    /// from Browse Systems / Coverage / missing-profile across the app.
    /// Recoverable later via the Hidden systems list (future feature).
    private func archiveCurrentSystem() async {
        guard currentIndex < systems.count else { return }
        let system = systems[currentIndex]
        try? await db.archiveHomeSystem(id: system.id)
        await MainActor.run {
            Haptics.medium()
            totalProcessed += 1
            advance()
        }
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
    }

    private func advance() {
        // Chez Design System: tighter spring than `animationStandard`
        // for the card-to-card transition. Matches the "luxury watch"
        // damping spec — high damping, smooth, ~0.42s response.
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            currentIndex += 1
        }
    }
}

// MARK: - One system's card

/// Inner card view that renders the question + 3 big buttons + nested
/// year-picker / estimate-chip choices. Stateless above; the parent
/// owns the system index and persistence.
private struct SystemCoverageCardView: View {
    let system: HomeSystemRow
    let property: PropertyRow
    var onSaveExact: (Int) -> Void
    var onSaveEstimate: (Int) -> Void
    var onSaveUnknown: () -> Void
    var onArchive: () -> Void
    var onSkip: () -> Void

    @State private var mode: Mode = .options
    @State private var pickedYear: Int = Calendar.current.component(.year, from: Date())

    private enum Mode {
        case options
        case exactPicker
        case estimateChips
    }

    private var isAttomPrefill: Bool {
        system.installDateAttomPrefilled == true && system.installDateConfirmedAt == nil
    }

    private var prefillYear: Int? {
        guard let installDate = system.installDate, installDate.count >= 4 else { return nil }
        return Int(installDate.prefix(4))
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            heroHeader

            if isAttomPrefill, let year = prefillYear {
                attomConfirmCard(year: year)
            }

            switch mode {
            case .options:
                optionButtons
            case .exactPicker:
                yearPickerSection
            case .estimateChips:
                estimateChipsSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroHeader: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("WHEN WAS THIS INSTALLED?")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(system.displayName)
                    .font(HavenTypography.fraunces(size: 26, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(system.displayCategory)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func attomConfirmCard(year: Int) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(HavenColors.action)
                    Text("Estimated from public records")
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                }
                Text("Public records suggest \(year). Confirm if this matches what you know — or pick a more accurate year below.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                HavenButton(
                    title: "Yes, around \(year)",
                    action: { onSaveEstimate(year) },
                    icon: "checkmark",
                    isFullWidth: true
                )
            }
        }
    }

    private var optionButtons: some View {
        VStack(spacing: HavenTheme.spacing12) {
            optionButton(
                title: "I know the year",
                subtitle: "I have paperwork or remember exactly",
                icon: "calendar",
                tint: HavenColors.success,
                action: {
                    pickedYear = prefillYear ?? currentYear
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        mode = .exactPicker
                    }
                }
            )
            optionButton(
                title: "I'll estimate",
                subtitle: "Pick from quick options based on your home",
                icon: "questionmark.circle",
                tint: HavenColors.action,
                action: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        mode = .estimateChips
                    }
                }
            )
            // Chez v1: 4th option — archives the system entirely. For
            // properties that don't have irrigation, a pool, etc.
            // Removes the row from Browse Systems and every audit /
            // coverage flow downstream. Recoverable later via the
            // Hidden systems list.
            optionButton(
                title: "I don't have this",
                subtitle: "Remove \(system.displayName) from this property",
                icon: "xmark.circle",
                tint: HavenColors.warning,
                action: {
                    onArchive()
                }
            )
            optionButton(
                title: "I don't know",
                subtitle: "Skip for now — Chez will ask again later",
                icon: "minus.circle",
                tint: HavenColors.textTertiary,
                action: {
                    onSaveUnknown()
                }
            )

            Button("Skip this one for now", action: onSkip)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.top, HavenTheme.spacing8)
        }
    }

    private func optionButton(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HavenCard(padding: HavenTheme.spacing16) {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .fill(tint.opacity(0.12))
                        )
                        .overlay(
                            // Chez Design System: 1pt indigo-08 stroke
                            // adds the "subtle structure on white surfaces"
                            // detail without competing with the tinted
                            // background.
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(HavenColors.navy.opacity(0.08), lineWidth: 1)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(subtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exact year picker

    private var yearPickerSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("Pick the year")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Picker("Year", selection: $pickedYear) {
                    ForEach((1900...currentYear).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 180)

                HStack(spacing: HavenTheme.spacing12) {
                    Button("Back") {
                        withAnimation(HavenTheme.animationStandard) { mode = .options }
                    }
                    .buttonStyle(.bordered)
                    .tint(HavenColors.navy700)

                    Spacer()

                    HavenButton(
                        title: "Save \(String(pickedYear))",
                        action: { onSaveExact(pickedYear) },
                        icon: "checkmark"
                    )
                }
            }
        }
    }

    // MARK: - Estimate chips

    private var estimateChipsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("Closest match?")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Pick the option that's closest. We'll record it as an estimate.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(estimateOptions, id: \.label) { option in
                    Button {
                        Haptics.medium()
                        onSaveEstimate(option.year)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .font(HavenTypography.uiButton)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(option.detail)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                            Text(String(option.year))
                                .font(HavenTypography.uiLabel.weight(.semibold))
                                .foregroundStyle(HavenColors.action)
                        }
                        .padding(.vertical, HavenTheme.spacing12)
                        .padding(.horizontal, HavenTheme.spacing16)
                        .background(HavenColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(HavenColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .buttonStyle(.plain)
                }

                Button("Back") {
                    withAnimation(HavenTheme.animationStandard) { mode = .options }
                }
                .buttonStyle(.bordered)
                .tint(HavenColors.navy700)
                .padding(.top, HavenTheme.spacing8)
            }
        }
    }

    /// Smart estimate options derived from the property's data:
    ///   - Year-built (always available from ATTOM)
    ///   - Purchase year (when `properties.purchase_date` exists)
    ///   - Within 5 years
    ///   - 5–10 years ago
    ///   - 10–20 years ago
    ///   - Over 20 years ago
    /// The last two were added because hardscape, plumbing, septic, and
    /// original windows are usually 15+ years old — without them the
    /// user had no honest option for older systems.
    private var estimateOptions: [EstimateOption] {
        var options: [EstimateOption] = []
        let now = currentYear

        if let yb = property.yearBuilt, yb > 1700, yb <= now {
            options.append(EstimateOption(
                label: "Original to the house",
                detail: "Built in \(yb)",
                year: yb
            ))
        }

        if let purchaseDate = property.purchaseDate, purchaseDate.count >= 4,
           let purchaseYear = Int(purchaseDate.prefix(4)), purchaseYear > 1700, purchaseYear <= now {
            options.append(EstimateOption(
                label: "Around when we bought it",
                detail: "Closed in \(purchaseYear)",
                year: purchaseYear
            ))
        }

        options.append(EstimateOption(
            label: "Within the last 5 years",
            detail: "Recent install",
            year: max(1900, now - 3)
        ))
        options.append(EstimateOption(
            label: "5 to 10 years ago",
            detail: "Mid-life",
            year: max(1900, now - 8)
        ))
        options.append(EstimateOption(
            label: "10 to 20 years ago",
            detail: "Mature",
            year: max(1900, now - 15)
        ))
        options.append(EstimateOption(
            label: "Over 20 years ago",
            detail: "Approaching replacement",
            year: max(1900, now - 25)
        ))

        return options
    }

    private struct EstimateOption {
        let label: String
        let detail: String
        let year: Int
    }
}
