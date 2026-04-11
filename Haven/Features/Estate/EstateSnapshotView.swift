import SwiftUI
import UIKit

/// Build 89 — In-app summary of the household's estate planning state.
/// Replaces the old "open the PDF export wizard" CTA on the post-intake
/// EstateOverviewCard with a native, scrollable read-only view that the
/// user can scan in seconds and optionally share with their attorney
/// (via email or clipboard) without ever generating a PDF.
///
/// Layout (top to bottom):
///   1. Hero        — large readiness ring + "Your Estate Snapshot" title + as-of date
///   2. On file     — green checkmarks for present documents, advisors, fiduciaries
///   3. Missing     — amber warnings for missing core docs, advisors, nominations
///   4. Recommends  — 2-3 prioritized next steps based on score + gaps
///   5. Share       — "Share with attorney" (mail compose) OR "Find an attorney"
///                    (FindLocalAdvisorSheet), plus a "Copy summary" secondary
///
/// All data is fetched in a `.task` block keyed on the householdId so the
/// view is self-contained — callers only have to thread the household id
/// through and present this as a sheet.
struct EstateSnapshotView: View {
    let householdId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var estateState: EstateStateRow?
    @State private var advisors: [HouseholdAdvisorRow] = []
    @State private var documents: [DocumentRow] = []
    @State private var isLoading = true
    @State private var loadError: String?

    /// Build 89 — town/state from the household's first property are used
    /// to seed the FindLocalAdvisorSheet's Google Places query so the
    /// "Find an Estate Attorney" results are region-aware. Optional
    /// because new households may not have a property yet, in which case
    /// the find sheet falls back to its "near you" mode.
    @State private var propertyTown: String?
    @State private var propertyState: String?

    @State private var showMailCompose = false
    @State private var showFindAttorney = false
    @State private var showCopiedToast = false

    private static let asOfFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else {
                    contentScroll
                }
            }
            .background(HavenColors.background)
            .navigationTitle("Estate Snapshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showMailCompose) {
            if MailComposeView.canSend, let attorney = linkedAttorney, let email = attorney.email, !email.isEmpty {
                MailComposeView(
                    recipients: [email],
                    subject: emailSubject,
                    body: plainTextSummary,
                    attachmentData: nil,
                    attachmentMimeType: nil,
                    attachmentFileName: nil
                )
            }
        }
        .sheet(isPresented: $showFindAttorney) {
            FindLocalAdvisorSheet(
                advisorType: "estate_attorney",
                advisorLabel: "Estate Attorney",
                householdId: householdId,
                town: propertyTown,
                state: propertyState,
                onAdopt: { result in
                    Task { await adoptLocalAttorney(result) }
                    showFindAttorney = false
                }
            )
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .padding(.bottom, HavenTheme.spacing24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(HavenColors.navy)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.warning)
            Text("Couldn't load your snapshot")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadData() }
            }
            .font(HavenTypography.uiButton)
            .foregroundStyle(HavenColors.navy)
        }
        .padding(HavenTheme.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    private var contentScroll: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                heroSection
                onFileSection
                missingSection
                if !recommendations.isEmpty {
                    recommendationsSection
                } else if (estateState?.estateReadinessScore ?? 0) >= 80 {
                    greatShapeBanner
                }
                shareSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing16)
            .padding(.bottom, HavenTheme.spacing32)
        }
    }

    /// Build 89 — positive-state banner shown in place of the Next Steps
    /// section when the user has a strong (80%+) readiness score AND no
    /// remaining recommendations. Replaces the previous gap where the
    /// section just disappeared, leaving a noticeable hole between the
    /// missing section and the share section.
    private var greatShapeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16))
                .foregroundStyle(HavenColors.success)
            Text("Your estate planning is in excellent shape")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.success.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.success.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing12) {
                progressRing(score: estateState?.estateReadinessScore ?? 0, size: 96)

                Text("Your Estate Snapshot")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("As of \(Self.asOfFormatter.string(from: Date()))")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                if let tier = stalenessTierDisplay {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tier.color)
                            .frame(width: 6, height: 6)
                        Text(tier.label)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(tier.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tier.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - On File

    private var onFileSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                sectionHeader("WHAT'S ON FILE", icon: "checkmark.seal.fill", iconColor: HavenColors.success)

                // Documents
                VStack(alignment: .leading, spacing: 8) {
                    rowGroupLabel("Documents")
                    ForEach(EstateStateService.coreSevenDocs(in: estateState)) { doc in
                        statusRow(label: doc.label, present: doc.present)
                    }
                }

                Divider().background(HavenColors.beige200)

                // Advisors
                VStack(alignment: .leading, spacing: 8) {
                    rowGroupLabel("Advisors")
                    ForEach(advisorTypeSlots, id: \.type) { slot in
                        let advisor = advisors.first { $0.advisorType == slot.type }
                        statusRow(
                            label: slot.label,
                            present: advisor != nil,
                            detail: advisor?.displayName
                        )
                    }
                }

                Divider().background(HavenColors.beige200)

                // Fiduciary nominations
                VStack(alignment: .leading, spacing: 8) {
                    rowGroupLabel("Fiduciary Nominations")
                    ForEach(fiduciaryRoleSlots, id: \.key) { slot in
                        let nominee = nominee(for: slot.key)
                        statusRow(
                            label: slot.label,
                            present: nominee != nil,
                            detail: nominee
                        )
                    }
                }
            }
        }
    }

    // MARK: - Missing

    private var missingSection: some View {
        let missingDocs = EstateStateService.coreSevenDocs(in: estateState).filter { !$0.present }
        let missingAdvisors = advisorTypeSlots.filter { slot in
            !advisors.contains { $0.advisorType == slot.type }
        }
        let missingFiduciaries = fiduciaryRoleSlots.filter { nominee(for: $0.key) == nil }

        return Group {
            if missingDocs.isEmpty && missingAdvisors.isEmpty && missingFiduciaries.isEmpty {
                EmptyView()
            } else {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                        sectionHeader("WHAT'S MISSING", icon: "exclamationmark.triangle.fill", iconColor: HavenColors.warning)

                        if !missingDocs.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                rowGroupLabel("Documents to gather")
                                ForEach(missingDocs) { doc in
                                    missingRow(doc.label)
                                }
                            }
                        }

                        if !missingAdvisors.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                rowGroupLabel("Advisors to find")
                                ForEach(missingAdvisors, id: \.type) { slot in
                                    missingRow(slot.label)
                                }
                            }
                        }

                        if !missingFiduciaries.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                rowGroupLabel("Roles to nominate")
                                ForEach(missingFiduciaries, id: \.key) { slot in
                                    missingRow(slot.label)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                sectionHeader("NEXT STEPS", icon: "sparkles", iconColor: HavenColors.navy)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { idx, rec in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(HavenColors.navy)
                                .frame(width: 24, height: 24)
                                .background(HavenColors.navy.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(HavenTypography.bodySmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(rec.detail)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Share

    private var shareSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                sectionHeader("SHARE", icon: "square.and.arrow.up", iconColor: HavenColors.navy)

                if let attorney = linkedAttorney, let email = attorney.email, !email.isEmpty, MailComposeView.canSend {
                    Button {
                        Haptics.medium()
                        showMailCompose = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 13))
                            Text("Share with \(attorney.displayName)")
                                .font(HavenTypography.uiButton)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HavenColors.navy)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(HavenButtonPressStyle())

                    Text("We'll open Mail with a plain-text summary so you can review before sending.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    Button {
                        Haptics.medium()
                        showFindAttorney = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                            Text("Find an Estate Attorney")
                                .font(HavenTypography.uiButton)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HavenColors.navy)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(HavenButtonPressStyle())

                    Text(linkedAttorney == nil
                         ? "We'll surface vetted attorneys near you. Once you link one, this section becomes a one-tap email handoff."
                         : "Add an email to your linked attorney to enable email handoff.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Button {
                    Haptics.light()
                    UIPasteboard.general.string = plainTextSummary
                    withAnimation(HavenTheme.animationStandard) {
                        showCopiedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(HavenTheme.animationStandard) {
                            showCopiedToast = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13))
                        Text("Copy summary")
                            .font(HavenTypography.uiButton)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(HavenColors.creamLight)
                    .foregroundStyle(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .strokeBorder(HavenColors.beige300, lineWidth: 1)
                    }
                }
                .buttonStyle(HavenButtonPressStyle())
            }
        }
    }

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.success)
            Text("Summary copied")
                .font(HavenTypography.bodySmall.weight(.semibold))
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.vertical, HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    // MARK: - Shared Subviews

    private func sectionHeader(_ title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private func rowGroupLabel(_ label: String) -> some View {
        Text(label.uppercased())
            .font(HavenTypography.uiLabelSmall)
            .tracking(1.2)
            .foregroundStyle(HavenColors.textTertiary)
    }

    private func statusRow(label: String, present: Bool, detail: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: present ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 16))
                .foregroundStyle(present ? HavenColors.success : HavenColors.textTertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(present ? HavenColors.textPrimary : HavenColors.textSecondary)
                if present, let detail, !detail.isEmpty {
                    Text(detail)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func missingRow(_ label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.warning)
                .frame(width: 20)
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private func progressRing(score: Int, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(HavenColors.beige200, lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    scoreColor(score),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)%")
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("ready")
                    .font(.system(size: size * 0.11, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(width: size, height: size)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return HavenColors.success }
        if score >= 40 { return HavenColors.warning }
        return HavenColors.navy700
    }

    // MARK: - Computed

    /// Slots for the four advisor categories the Life tab tracks. Mirrors
    /// the order on AdvisorsSection so the snapshot matches the user's
    /// existing mental model.
    private let advisorTypeSlots: [(type: String, label: String)] = [
        ("estate_attorney", "Estate Attorney"),
        ("cpa_tax", "CPA / Tax Advisor"),
        ("financial_advisor", "Financial Advisor"),
        ("life_insurance", "Life Insurance"),
    ]

    /// Slots for the six fiduciary roles tracked in `estate_state.nominations`.
    /// Guardian appears regardless of whether the household has minors —
    /// the snapshot is descriptive, not prescriptive.
    private let fiduciaryRoleSlots: [(key: String, label: String)] = [
        ("executor", "Executor"),
        ("trustee", "Trustee"),
        ("guardian", "Guardian for Minors"),
        ("health_proxy", "Healthcare Proxy"),
        ("poa_agent", "Power of Attorney Agent"),
        ("disposition_agent", "Disposition Agent"),
    ]

    private var linkedAttorney: HouseholdAdvisorRow? {
        advisors.first { $0.advisorType == "estate_attorney" }
    }

    private func nominee(for roleKey: String) -> String? {
        guard let nominations = estateState?.nominations else { return nil }
        let nomination: FiduciaryNomination?
        switch roleKey {
        case "executor": nomination = nominations.executor
        case "trustee": nomination = nominations.trustee
        case "guardian": nomination = nominations.guardian
        case "health_proxy": nomination = nominations.healthProxy
        case "poa_agent": nomination = nominations.poaAgent
        case "disposition_agent": nomination = nominations.dispositionAgent
        default: nomination = nil
        }
        return nomination?.primary?.name
    }

    private struct Recommendation {
        let title: String
        let detail: String
    }

    /// Build 89 — generates 2-3 prioritized next steps based on which
    /// gaps would most improve the user's readiness score. Prioritized
    /// order: missing Will > missing POA > missing Healthcare Proxy >
    /// missing Executor > missing Estate Attorney > stale documents.
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []
        let docs = EstateStateService.coreSevenDocs(in: estateState)
        let presentByKey = Dictionary(uniqueKeysWithValues: docs.map { ($0.key, $0.present) })

        if presentByKey["has_will"] == false {
            recs.append(Recommendation(
                title: "Upload your will",
                detail: "A signed will is the foundation of your estate plan. Adding it unlocks the largest single jump in your readiness score."
            ))
        }
        if presentByKey["has_poa"] == false {
            recs.append(Recommendation(
                title: "Add a Power of Attorney",
                detail: "A POA lets a trusted person handle financial matters if you're unable to. Most attorneys draft this alongside your will."
            ))
        }
        if presentByKey["has_health_proxy"] == false {
            recs.append(Recommendation(
                title: "Designate a healthcare proxy",
                detail: "Your healthcare proxy speaks for you in medical decisions. Pair it with a HIPAA authorization for full coverage."
            ))
        }
        if nominee(for: "executor") == nil {
            recs.append(Recommendation(
                title: "Name your executor",
                detail: "The person who will carry out your wishes. You can review and update this in your intake answers anytime."
            ))
        }
        if linkedAttorney == nil {
            recs.append(Recommendation(
                title: "Connect with an estate attorney",
                detail: "An attorney can review your snapshot, fill the gaps, and update existing documents to match your current family situation."
            ))
        }
        if estateState?.stalenessTier == "amber" || estateState?.stalenessTier == "critical" {
            recs.append(Recommendation(
                title: "Schedule an estate review",
                detail: "Your documents are aging. Most planners recommend reviewing every 3-5 years and after major life events."
            ))
        }

        return Array(recs.prefix(3))
    }

    private var stalenessTierDisplay: (label: String, color: Color)? {
        guard let tier = estateState?.stalenessTier, tier != "none" else { return nil }
        switch tier {
        case "critical": return ("Documents need urgent review", HavenColors.critical)
        case "amber": return ("Documents may need updating", HavenColors.warning)
        case "info": return ("Documents are aging", HavenColors.info)
        default: return nil
        }
    }

    // MARK: - Plain-text summary (used by Mail + Copy)

    private var emailSubject: String {
        let score = estateState?.estateReadinessScore ?? 0
        return "Estate planning snapshot (\(score)% ready)"
    }

    private var plainTextSummary: String {
        var lines: [String] = []
        let score = estateState?.estateReadinessScore ?? 0
        lines.append("ESTATE PLANNING SNAPSHOT")
        lines.append("Generated by Haven on \(Self.asOfFormatter.string(from: Date()))")
        lines.append("")
        lines.append("Readiness score: \(score)%")
        if let tier = stalenessTierDisplay {
            lines.append("Status: \(tier.label)")
        }
        lines.append("")

        lines.append("DOCUMENTS ON FILE")
        for doc in EstateStateService.coreSevenDocs(in: estateState) {
            lines.append("\(doc.present ? "[x]" : "[ ]") \(doc.label)")
        }
        lines.append("")

        lines.append("LINKED ADVISORS")
        for slot in advisorTypeSlots {
            if let advisor = advisors.first(where: { $0.advisorType == slot.type }) {
                lines.append("[x] \(slot.label): \(advisor.displayName)")
            } else {
                lines.append("[ ] \(slot.label)")
            }
        }
        lines.append("")

        lines.append("FIDUCIARY NOMINATIONS")
        for slot in fiduciaryRoleSlots {
            if let name = nominee(for: slot.key) {
                lines.append("[x] \(slot.label): \(name)")
            } else {
                lines.append("[ ] \(slot.label)")
            }
        }
        lines.append("")

        if !recommendations.isEmpty {
            lines.append("NEXT STEPS")
            for (idx, rec) in recommendations.enumerated() {
                lines.append("\(idx + 1). \(rec.title)")
                lines.append("   \(rec.detail)")
            }
            lines.append("")
        }

        lines.append("--")
        lines.append("Sent from Haven · havenhome.dev")

        return lines.joined(separator: "\n")
    }

    // MARK: - Loading

    private func loadData() async {
        isLoading = true
        loadError = nil
        do {
            async let stateTask = EstateStateService.shared.fetch(householdId: householdId)
            async let advisorsTask = DatabaseService.shared.fetchHouseholdAdvisors(householdId: householdId)
            async let documentsTask = DatabaseService.shared.fetchDocuments()

            let (s, a, d) = try await (stateTask, advisorsTask, documentsTask)
            self.estateState = s
            self.advisors = a
            self.documents = d

            // Build 89 — pull the household's first property so the
            // "Find an Estate Attorney" sheet can seed Google Places
            // with a real town/state. Property fetch is best-effort and
            // failures don't bubble — the find sheet falls back to its
            // "near you" mode if we can't resolve a region.
            let properties = (try? await DatabaseService.shared.fetchProperties()) ?? []
            if let first = properties.first {
                propertyTown = first.city
                propertyState = first.state
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    /// When the user picks an attorney from the FindLocalAdvisorSheet,
    /// snapshot it into household_advisors so the snapshot view's next
    /// render flips from "Find an Estate Attorney" to "Share with {name}".
    /// Mirrors `AdvisorsSection.recordFromLocalResult`.
    private func adoptLocalAttorney(_ result: HavenSupabase.LocalVendorResult) async {
        let insert = HouseholdAdvisorInsert(
            householdId: householdId,
            advisorType: "estate_attorney",
            providerName: result.name,
            website: result.website,
            phone: result.phone
        )
        if let created = try? await DatabaseService.shared.createHouseholdAdvisor(insert) {
            advisors.removeAll { $0.advisorType == "estate_attorney" }
            advisors.append(created)
            NotificationCenter.default.post(name: .advisorChanged, object: nil)
        }
    }
}
