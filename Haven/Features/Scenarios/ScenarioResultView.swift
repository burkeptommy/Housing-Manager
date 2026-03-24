import SwiftUI

struct ScenarioResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: ScenarioResult
    let scenario: ScenarioDefinition?
    var onRunRelated: ((String) -> Void)?
    var onDone: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Educational disclaimer banner
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(HavenColors.textTertiary)
                        .font(.caption)
                    Text("For educational purposes only. Consult a qualified professional before acting on these results.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.cream)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                .padding(.horizontal, HavenTheme.pageMargin)

                // Personalization indicator
                personalizationBar

                // Hero section
                heroSection

                // Confidence indicator
                if result.confidenceLevel != nil {
                    confidenceIndicator
                }

                // Dynamic sections (custom/freeform)
                if !result.sections.isEmpty {
                    dynamicSectionsView
                }

                // Financial details (custom format)
                if let summaryLine = result.financialSummaryLine {
                    financialDetailsSection(summaryLine: summaryLine)
                }

                // Timeline
                if !result.timeline.isEmpty {
                    timelineSection
                }

                // Financial impact (pre-built format)
                if let impact = result.financialImpact, !impact.breakdown.isEmpty {
                    financialImpactSection(impact)
                }

                // Home scenario summary
                if result.netProceeds != nil || result.capitalGains != nil {
                    homeSummarySection
                }

                // Tax savings breakdown
                if let savings = result.savingsBreakdown {
                    savingsSection(savings)
                }

                // Steps to implement
                if let steps = result.stepsToImplement, !steps.isEmpty {
                    stepsSection(steps)
                }

                // Guardian chain
                if !result.guardianChain.isEmpty {
                    guardianSection
                }

                // Action items
                if !result.actionItems.isEmpty {
                    actionItemsSection
                }

                // Recommendations
                if !result.recommendations.isEmpty {
                    recommendationsSection
                }

                // Risks and considerations
                if let risks = result.risksAndConsiderations, !risks.isEmpty {
                    risksSection(risks)
                }

                // Tax implications
                if let implications = result.taxImplications, !implications.isEmpty {
                    taxImplicationsSection(implications)
                }

                // Did you know
                if let fact = result.didYouKnow {
                    didYouKnowCard(fact)
                }

                // Related scenarios
                if !result.relatedScenarios.isEmpty {
                    relatedScenariosSection
                }

                // Disclaimer
                disclaimerFooter
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing8)
            .padding(.bottom, HavenTheme.spacing32)
        }
        .background(HavenColors.background)
        .trackScreen("ScenarioResultView")
        .screenshotProtected()
        .onAppear {
            Analytics.track(.scenarioCompleted, ["severity": result.severity, "title": String(result.title.prefix(100))])
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Scenario Results")
                    .font(Font.custom("Georgia-Bold", size: 18))
                    .foregroundStyle(HavenColors.navy800)
            }
            ToolbarItem(placement: .topBarLeading) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy800)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.track(.scenarioShared, ["title": String(result.title.prefix(100))])
                })
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    if let onDone {
                        onDone()
                    } else {
                        dismiss()
                    }
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy800)
            }
        }
    }

    private var shareText: String {
        """
        What If: \(result.title)

        \(result.summary)

        Key Takeaway: \(result.actionItems.first?.title ?? "Review your plan")

        — Analyzed by Haven
        """
    }

    // MARK: - Personalization Bar

    private var personalizationBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                let score = result.personalizationScore
                let filled = Int(score * 5)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < filled ? HavenColors.navy700 : HavenColors.beige300)
                        .frame(width: 24, height: 8)
                }
                Text("Personalized: \(Int(score * 100))%")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.leading, 4)
            }

            if let used = result.documentsUsed, !used.isEmpty {
                Text("Using: \(used.joined(separator: ", "))")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let missing = result.documentsMissing, !missing.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 10))
                    Text("Missing: \(missing.joined(separator: ", "))")
                        .font(HavenTypography.uiCaption)
                }
                .foregroundStyle(HavenColors.warning)
            }
        }
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.title)
                .font(Font.custom("Georgia-Bold", size: 20))
                .foregroundStyle(HavenColors.navy800)

            severityBadge

            Text(result.summary)
                .font(Font.custom("Georgia", size: 14))
                .foregroundStyle(HavenColors.textSecondary)
                .lineSpacing(4)
        }
    }

    private var severityBadge: some View {
        let (label, color) = severityStyle(result.severity)
        return Text(label)
            .font(HavenTypography.uiCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("TIMELINE", icon: "clock")

            ForEach(Array(result.timeline.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    // Timeline indicator
                    VStack(spacing: 0) {
                        stepIndicator(step: step)
                        if index < result.timeline.count - 1 {
                            Rectangle()
                                .fill(HavenColors.beige300)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                        Text(step.description)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        if !step.details.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(step.details, id: \.self) { detail in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(detail)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func stepIndicator(step: TimelineStep) -> some View {
        Group {
            if step.flag == "critical" {
                Circle()
                    .fill(HavenColors.critical)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            } else if step.flag == "good" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.success)
            } else if step.flag == "warning" {
                Circle()
                    .fill(HavenColors.warning)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            } else {
                Circle()
                    .fill(HavenColors.navy700)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 28, height: 28)
    }

    // MARK: - Financial Impact

    private func financialImpactSection(_ impact: FinancialImpact) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("FINANCIAL IMPACT", icon: "chart.bar")

            // Summary totals
            HStack(spacing: 12) {
                financialStat(label: "Protected", value: impact.assetsProtected, color: HavenColors.success)
                financialStat(label: "At Risk", value: impact.assetsAtRisk, color: HavenColors.critical)
                financialStat(label: "Tax Exposure", value: impact.taxExposure, color: HavenColors.warning)
            }

            if let payouts = impact.insurancePayouts {
                HStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Insurance Payouts: \(payouts)")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            // Breakdown
            if !impact.breakdown.isEmpty {
                VStack(spacing: 0) {
                    ForEach(impact.breakdown) { item in
                        financialItemRow(item)
                        if item.id != impact.breakdown.last?.id {
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(HavenColors.beige300, lineWidth: 0.5)
                )
            }
        }
    }

    private func financialStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func financialItemRow(_ item: FinancialItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusDot(item.status)
                Text(item.item)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy800)
                Spacer()
                Text(item.amount)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            if let goesTo = item.goesTo {
                Text("→ \(goesTo)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let flag = item.flag {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(flag)
                        .font(HavenTypography.uiCaption)
                }
                .foregroundStyle(HavenColors.warning)
            }
        }
        .padding(12)
    }

    private func statusDot(_ status: String) -> some View {
        Circle()
            .fill(status == "protected" ? HavenColors.success :
                    status == "at_risk" ? HavenColors.critical :
                    HavenColors.textTertiary)
            .frame(width: 8, height: 8)
    }

    // MARK: - Home Summary

    private var homeSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("PROPERTY ANALYSIS", icon: "house")

            VStack(spacing: 0) {
                if let value = result.currentValueEstimate {
                    homeSummaryRow(label: "Current Value", value: value)
                    Divider().padding(.horizontal, 12)
                }
                if let price = result.purchasePrice {
                    homeSummaryRow(label: "Purchase Price", value: price)
                    Divider().padding(.horizontal, 12)
                }
                if let mortgage = result.mortgageBalance {
                    homeSummaryRow(label: "Mortgage Balance", value: mortgage)
                    Divider().padding(.horizontal, 12)
                }
                if let closing = result.closingCostsEstimate {
                    homeSummaryRow(label: "Closing Costs", value: closing)
                    Divider().padding(.horizontal, 12)
                }
                if let gains = result.capitalGains {
                    homeSummaryRow(label: "Capital Gains", value: gains)
                    Divider().padding(.horizontal, 12)
                }
                if let exclusion = result.exclusionAvailable {
                    homeSummaryRow(label: "Exclusion", value: exclusion)
                    Divider().padding(.horizontal, 12)
                }
                if let net = result.netProceeds {
                    homeSummaryRow(label: "Net Proceeds", value: net, highlight: true)
                }
            }
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(HavenColors.beige300, lineWidth: 0.5)
            )
        }
    }

    private func homeSummaryRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(highlight ? HavenTypography.headline : HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(highlight ? HavenTypography.headline : HavenTypography.uiLabel)
                .foregroundStyle(highlight ? HavenColors.navy800 : HavenColors.textPrimary)
        }
        .padding(12)
    }

    // MARK: - Savings Section

    private func savingsSection(_ savings: SavingsBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SAVINGS BREAKDOWN", icon: "dollarsign.circle")

            HStack {
                Text("Annual Tax Savings")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(savings.annualSavings)
                    .font(Font.custom("Georgia-Bold", size: 22))
                    .foregroundStyle(HavenColors.success)
            }
            .padding(14)
            .background(HavenColors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !savings.details.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(savings.details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(HavenColors.success)
                                .padding(.top, 2)
                            Text(detail)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Steps to Implement

    private func stepsSection(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("STEPS TO IMPLEMENT", icon: "list.number")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(HavenColors.navy700)
                            .clipShape(Circle())
                        Text(step)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Guardian Section

    private var guardianSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("GUARDIAN CHAIN", icon: "person.badge.key")

            HStack(spacing: 0) {
                ForEach(Array(result.guardianChain.enumerated()), id: \.element.id) { index, guardian in
                    VStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(index == 0 ? HavenColors.navy700 : HavenColors.textTertiary)
                        Text(guardian.name)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy800)
                            .multilineTextAlignment(.center)
                        Text(guardian.relationship)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(guardian.status.capitalized)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(index == 0 ? HavenColors.navy700 : HavenColors.textTertiary)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)

                    if index < result.guardianChain.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .padding(14)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(HavenColors.beige300, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Action Items

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("ACTION ITEMS", icon: "checklist")

            ForEach(result.actionItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    priorityBadge(item.priority)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)
                        Text(item.description)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        if let effort = item.effort {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(effort)
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .padding(12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            item.priority == "critical" ? HavenColors.critical.opacity(0.3) : HavenColors.beige300,
                            lineWidth: item.priority == "critical" ? 1 : 0.5
                        )
                )
            }
        }
    }

    private func priorityBadge(_ priority: String) -> some View {
        let (label, color) = priorityStyle(priority)
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("RECOMMENDATIONS", icon: "lightbulb")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, rec in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 20, alignment: .trailing)
                        Text(rec)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Risks

    private func risksSection(_ risks: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("RISKS & CONSIDERATIONS", icon: "exclamationmark.triangle")

            VStack(alignment: .leading, spacing: 6) {
                ForEach(risks, id: \.self) { risk in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.top, 2)
                        Text(risk)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Tax Implications

    private func taxImplicationsSection(_ implications: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("TAX IMPLICATIONS", icon: "doc.text")

            VStack(alignment: .leading, spacing: 6) {
                ForEach(implications, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(item)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Did You Know

    private func didYouKnowCard(_ fact: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.navy700)
                Text("DID YOU KNOW?")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.navy700)
            }
            Text(fact)
                .font(Font.custom("Georgia", size: 14))
                .foregroundStyle(HavenColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [HavenColors.navy.opacity(0.04), HavenColors.navy.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.navy.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Disclaimer

    private var disclaimerFooter: some View {
        Text(result.disclaimer)
            .font(HavenTypography.uiCaption)
            .foregroundStyle(HavenColors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.navy700)
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                let dots = confidenceDots(result.confidenceLevel ?? "medium")
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < dots ? HavenColors.navy700 : HavenColors.beige300)
                        .frame(width: 8, height: 8)
                }
            }

            Text("Analysis confidence: \(result.confidenceLevel?.capitalized ?? "Medium")")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)

            if let note = result.confidenceNote {
                Text("— \(note)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func confidenceDots(_ level: String) -> Int {
        switch level {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 2
        }
    }

    // MARK: - Dynamic Sections (Freeform)

    private var dynamicSectionsView: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(result.sections) { section in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(sectionFlagColor(section.flag))
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            if let icon = section.icon {
                                Image(systemName: icon)
                                    .font(.body)
                                    .foregroundStyle(sectionFlagColor(section.flag))
                            }
                            Text(section.heading)
                                .font(Font.custom("Georgia-Bold", size: 15))
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        if let highlight = section.highlight {
                            Text(highlight)
                                .font(Font.custom("Georgia-Bold", size: 24))
                                .foregroundStyle(sectionFlagColor(section.flag))
                                .padding(.vertical, 4)
                        }

                        Text(LocalizedStringKey(section.content))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(14)
                }
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HavenColors.beige300, lineWidth: 0.5)
                )
            }
        }
    }

    private func sectionFlagColor(_ flag: String?) -> Color {
        switch flag {
        case "good": return HavenColors.success
        case "warning": return HavenColors.warning
        case "critical": return HavenColors.critical
        default: return HavenColors.navy700
        }
    }

    // MARK: - Financial Details (Custom Format)

    private func financialDetailsSection(summaryLine: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("FINANCIAL IMPACT", icon: "chart.bar")

            Text(summaryLine)
                .font(Font.custom("Georgia-Bold", size: 16))
                .foregroundStyle(HavenColors.navy800)
                .padding(.bottom, 4)

            if !result.financialDetails.isEmpty {
                VStack(spacing: 0) {
                    ForEach(result.financialDetails) { detail in
                        HStack {
                            Text(detail.label)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text(detail.value)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(detailColor(detail.flag))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        if detail.id != result.financialDetails.last?.id {
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(HavenColors.beige300, lineWidth: 0.5)
                )
            }
        }
    }

    private func detailColor(_ flag: String?) -> Color {
        switch flag {
        case "good": return HavenColors.success
        case "warning": return HavenColors.warning
        case "critical": return HavenColors.critical
        default: return HavenColors.textPrimary
        }
    }

    // MARK: - Related Scenarios

    private var relatedScenariosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("EXPLORE NEXT", icon: "sparkles")

            ForEach(result.relatedScenarios, id: \.self) { scenario in
                Button {
                    Haptics.light()
                    onRunRelated?(scenario)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(HavenColors.navy700)
                        Text(scenario)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.navy700)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(12)
                    .background(HavenColors.navy.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func severityStyle(_ severity: String) -> (String, Color) {
        switch severity {
        case "critical": return ("Critical", HavenColors.critical)
        case "important": return ("Important", HavenColors.warning)
        case "opportunity": return ("Opportunity", HavenColors.success)
        default: return ("Informational", HavenColors.navy700)
        }
    }

    private func priorityStyle(_ priority: String) -> (String, Color) {
        switch priority {
        case "critical": return ("CRITICAL", HavenColors.critical)
        case "high": return ("HIGH", HavenColors.warning)
        case "medium": return ("MEDIUM", HavenColors.navy700)
        default: return ("LOW", HavenColors.textTertiary)
        }
    }
}
