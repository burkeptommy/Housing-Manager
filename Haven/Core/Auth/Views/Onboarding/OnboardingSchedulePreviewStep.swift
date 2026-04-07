import SwiftUI

/// Step 2 of onboarding: The "instant payoff" — property details + 12-month maintenance plan.
/// Property details are tappable for inline correction if the API returned wrong data.
struct OnboardingSchedulePreviewStep: View {
    let street: String
    let city: String
    let state: String
    @Binding var propertyResult: PropertyLookupResult?
    @Binding var scheduleItems: [SchedulePreviewItem]
    let isLoading: Bool
    var onPropertyEdited: () -> Void = {}

    @State private var editingField: EditableField?
    @State private var hasEdited = false

    private let monthNames = Calendar.current.shortMonthSymbols

    enum EditableField: Hashable {
        case yearBuilt, squareFootage, bedrooms, bathrooms, propertyType
    }

    var body: some View {
        if isLoading {
            loadingView
        } else {
            contentView
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(HavenColors.navy700)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Building your home plan...")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                Text("Looking up property details and creating your personalized maintenance schedule.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                propertyCard
                if !detectedFeaturePills.isEmpty {
                    detectedFeaturesSection
                }
                if let protected = OnboardingScheduleGenerator.computeValueProtection(from: propertyResult) {
                    valueProtectionHeadline(protectedValue: protected)
                }
                scheduleSection
                if !featureTeasers.isEmpty {
                    featureValueTeaserSection
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
            .padding(.bottom, 80) // room for bottom buttons
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Property Card

    private var propertyCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(street)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                    Text("\(city), \(state)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "house.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(HavenColors.navy.opacity(0.3))
            }

            if propertyResult != nil {
                Divider()
                editablePropertyDetailsGrid

                // Hint text — fades out after first edit
                if !hasEdited {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 10))
                        Text("Tap any value to correct it")
                            .font(HavenTypography.uiCaption)
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                    .transition(.opacity)
                }
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Detected Features

    private struct DetectedPill: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
    }

    private var detectedFeaturePills: [DetectedPill] {
        guard let f = propertyResult?.features else { return [] }
        var pills: [DetectedPill] = []

        if f.pool == true {
            let label = f.poolType.map { "\($0) Pool" } ?? "Pool"
            pills.append(DetectedPill(icon: "drop.fill", label: label))
        }
        if f.garage == true {
            let label = f.garageSpaces.map { "\($0)-Car Garage" } ?? "Garage"
            pills.append(DetectedPill(icon: "car.fill", label: label))
        }
        if f.fireplace == true {
            let label = f.fireplaceType.map { "\($0) Fireplace" } ?? "Fireplace"
            pills.append(DetectedPill(icon: "flame.fill", label: label))
        }
        if let foundation = f.foundationType, foundation.lowercased().contains("basement") {
            if let size = f.basementSize {
                pills.append(DetectedPill(icon: "rectangle.split.1x2.fill", label: "\(size.formatted()) sf basement"))
            } else {
                pills.append(DetectedPill(icon: "rectangle.split.1x2.fill", label: "Basement"))
            }
        }
        if let stories = f.stories, stories > 0 {
            pills.append(DetectedPill(icon: "building.2.fill", label: stories == 1 ? "1 story" : "\(stories) stories"))
        }
        if let yearBuilt = propertyResult?.yearBuilt {
            pills.append(DetectedPill(icon: "calendar", label: "Built \(yearBuilt)"))
        }
        if let heating = f.heatingType {
            let fuel = f.heatingFuel.map { " (\($0))" } ?? ""
            pills.append(DetectedPill(icon: "thermometer.sun.fill", label: heating + fuel))
        }
        if let style = f.architectureType {
            pills.append(DetectedPill(icon: "house.fill", label: style))
        }
        if let lot = propertyResult?.lotSize, lot > 0 {
            // ATTOM returns lot size in square feet; convert to acres for display.
            let acres = Double(lot) / 43560.0
            if acres >= 0.1 {
                pills.append(DetectedPill(icon: "leaf.fill", label: String(format: "%.2f acres", acres)))
            }
        }

        return pills
    }

    private var detectedFeaturesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("DETECTED FEATURES")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            FlowLayout(spacing: 6) {
                ForEach(detectedFeaturePills) { pill in
                    HStack(spacing: 4) {
                        Image(systemName: pill.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(pill.label)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 10-Year Value Protection Headline

    private func valueProtectionHeadline(protectedValue: Double) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.creamLight)
                Text("\(protectedValue.formattedCompactCurrency()) protected over 10 years")
                    .font(.custom("Georgia", size: 18).weight(.semibold))
                    .foregroundStyle(HavenColors.creamLight)
            }
            Text("Homes maintained on schedule appreciate ~12% more than neglected homes.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.creamLight.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Text("Industry estimates from Remodeling Magazine + NAR studies.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.creamLight.opacity(0.6))
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [HavenColors.navy800, HavenColors.navy700],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    // MARK: - Per-Feature Value Teasers

    private var featureTeasers: [FeatureValueLibrary.Entry] {
        FeatureValueLibrary.resolve(keys: FeatureValueLibrary.keys(from: propertyResult?.features))
    }

    private var featureValueTeaserSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("WHAT THESE FEATURES MEAN")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: HavenTheme.spacing12),
                GridItem(.flexible(), spacing: HavenTheme.spacing12),
            ], spacing: HavenTheme.spacing12) {
                ForEach(featureTeasers, id: \.key) { entry in
                    teaserCard(entry)
                }
            }
        }
    }

    private func teaserCard(_ entry: FeatureValueLibrary.Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: entry.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                Text(entry.title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.annualUpkeep)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(entry.resaleImpact)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Editable Property Details Grid

    private var editablePropertyDetailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: HavenTheme.spacing12) {
            if propertyResult?.yearBuilt != nil || editingField == .yearBuilt {
                editableCell(
                    field: .yearBuilt,
                    label: "Built",
                    value: propertyResult?.yearBuilt.map { "\($0)" } ?? "—"
                )
            }
            if propertyResult?.squareFootage != nil || editingField == .squareFootage {
                editableCell(
                    field: .squareFootage,
                    label: "Sq Ft",
                    value: propertyResult?.squareFootage.map { $0.formatted() } ?? "—"
                )
            }
            if propertyResult?.bedrooms != nil || editingField == .bedrooms {
                editableCell(
                    field: .bedrooms,
                    label: "Beds",
                    value: propertyResult?.bedrooms.map { "\($0)" } ?? "—"
                )
            }
            if propertyResult?.bathrooms != nil || editingField == .bathrooms {
                editableCell(
                    field: .bathrooms,
                    label: "Baths",
                    value: propertyResult?.bathrooms.map { "\($0)" } ?? "—"
                )
            }
            if let estimatedValue = propertyResult?.estimatedValue {
                VStack(spacing: 2) {
                    Text(estimatedValue.formattedCompactCurrency())
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                    Text("Est. Value")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            if propertyResult?.propertyType != nil || editingField == .propertyType {
                editableCell(
                    field: .propertyType,
                    label: "Type",
                    value: propertyResult?.propertyType.map { formatPropertyType($0) } ?? "—"
                )
            }
        }
    }

    @ViewBuilder
    private func editableCell(field: EditableField, label: String, value: String) -> some View {
        if editingField == field {
            editingView(for: field, label: label)
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    editingField = field
                }
            } label: {
                VStack(spacing: 2) {
                    Text(value)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                    HStack(spacing: 2) {
                        Text(label)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Image(systemName: "pencil")
                            .font(.system(size: 8))
                            .foregroundStyle(HavenColors.textTertiary.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func editingView(for field: EditableField, label: String) -> some View {
        switch field {
        case .yearBuilt:
            numericEditor(
                label: label,
                value: propertyResult?.yearBuilt ?? 2000,
                range: 1800...2026,
                onCommit: { newValue in
                    propertyResult?.yearBuilt = newValue
                    commitEdit()
                }
            )
        case .squareFootage:
            numericEditor(
                label: label,
                value: propertyResult?.squareFootage ?? 2000,
                range: 200...50000,
                onCommit: { newValue in
                    propertyResult?.squareFootage = newValue
                    commitEdit()
                }
            )
        case .bedrooms:
            stepperEditor(
                label: label,
                value: propertyResult?.bedrooms ?? 3,
                range: 1...10,
                onCommit: { newValue in
                    propertyResult?.bedrooms = newValue
                    commitEdit()
                }
            )
        case .bathrooms:
            stepperEditor(
                label: label,
                value: propertyResult?.bathrooms ?? 2,
                range: 1...10,
                onCommit: { newValue in
                    propertyResult?.bathrooms = newValue
                    commitEdit()
                }
            )
        case .propertyType:
            propertyTypePicker(label: label)
        }
    }

    // MARK: - Inline Editors

    private func numericEditor(label: String, value: Int, range: ClosedRange<Int>, onCommit: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 4) {
            NumericTextField(value: value, range: range, onCommit: onCommit)
                .frame(width: 70, height: 30)

            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private func stepperEditor(label: String, value: Int, range: ClosedRange<Int>, onCommit: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    let newVal = max(range.lowerBound, value - 1)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(value > range.lowerBound ? HavenColors.navy700 : HavenColors.textTertiary.opacity(0.3))
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                    .frame(minWidth: 20)

                Button {
                    let newVal = min(range.upperBound, value + 1)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(value < range.upperBound ? HavenColors.navy700 : HavenColors.textTertiary.opacity(0.3))
                }
                .disabled(value >= range.upperBound)
            }

            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private func propertyTypePicker(label: String) -> some View {
        let types = ["Single Family", "Condo", "Townhouse", "Multi-Family"]
        return VStack(spacing: 4) {
            VStack(spacing: 4) {
                ForEach(types, id: \.self) { type in
                    Button {
                        propertyResult?.propertyType = type
                        commitEdit()
                    } label: {
                        Text(type)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(
                                propertyResult?.propertyType == type
                                    ? .white
                                    : HavenColors.navy700
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(
                                propertyResult?.propertyType == type
                                    ? HavenColors.navy
                                    : HavenColors.navy.opacity(0.06)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private func commitEdit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            editingField = nil
            hasEdited = true
        }
        onPropertyEdited()
    }

    private func formatPropertyType(_ type: String) -> String {
        type.replacingOccurrences(of: "Single Family", with: "Single Family")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your 12-Month Home Plan")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.navy800)
                Text("\(scheduleItems.count) maintenance tasks personalized for your home")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            // Group items by month
            let grouped = groupedByMonth
            ForEach(grouped, id: \.month) { group in
                monthSection(month: group.month, items: group.items)
            }

            annualCostSummary
        }
    }

    private struct MonthGroup {
        let month: Int
        let items: [SchedulePreviewItem]
    }

    private var groupedByMonth: [MonthGroup] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let dict = Dictionary(grouping: scheduleItems, by: \.month)

        // Build ordered list starting from current month
        var groups: [MonthGroup] = []
        for offset in 0..<12 {
            let month = ((currentMonth - 1 + offset) % 12) + 1
            if let items = dict[month], !items.isEmpty {
                groups.append(MonthGroup(month: month, items: items))
            }
        }
        return groups
    }

    private func monthSection(month: Int, items: [SchedulePreviewItem]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(monthNames[month - 1].uppercased())
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
                .fontWeight(.semibold)
                .tracking(1)

            ForEach(items) { item in
                taskRow(item)
            }
        }
    }

    private func taskRow(_ item: SchedulePreviewItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 28, height: 28)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.estimatedCost)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    if item.isDIY {
                        Text("DIY")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.success)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(HavenColors.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(item.frequency)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, HavenTheme.spacing12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var annualCostSummary: some View {
        // Parse cost ranges and estimate annual total
        let totalEstimate = scheduleItems.reduce(0.0) { sum, item in
            sum + parseMidpointCost(item.estimatedCost)
        }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Annual Cost")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("Based on typical costs in your area")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer()
            Text("~$\(Int(totalEstimate).formatted())")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.navy800)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Parse "$200–$400" or "$0 (DIY)" into a midpoint estimate.
    private func parseMidpointCost(_ cost: String) -> Double {
        let digits = cost.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
        guard !digits.isEmpty else { return 0 }
        if digits.count >= 2 {
            return (digits[0] + digits[1]) / 2
        }
        return digits[0]
    }

}

// MARK: - NumericTextField

/// A compact text field for entering numeric values with validation.
private struct NumericTextField: View {
    let value: Int
    let range: ClosedRange<Int>
    let onCommit: (Int) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(HavenTypography.headline)
            .foregroundStyle(HavenColors.navy800)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(HavenColors.navy.opacity(0.3), lineWidth: 1)
            )
            .focused($isFocused)
            .onAppear {
                text = "\(value)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onSubmit { commit() }
            .onChange(of: isFocused) { _, focused in
                if !focused { commit() }
            }
    }

    private func commit() {
        if let parsed = Int(text), range.contains(parsed) {
            onCommit(parsed)
        } else {
            onCommit(value) // revert to original
        }
    }
}
