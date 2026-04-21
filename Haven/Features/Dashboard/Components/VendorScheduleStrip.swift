import SwiftUI

/// Phase 50: Dashboard's "YOUR HOME" hero replacement. Replaces the
/// Phase 19l dual-count card ("X to do · Y vendor-managed") with a
/// horizontal scroll of the next vendor service visits, plus an
/// overdue pill and a one-line "X tasks this week" summary below.
///
/// The strip is presentation-only — the data prep (vendor name + logo
/// resolution, last cost lookup) happens in `DashboardViewModel` so the
/// strip stays cheap to render.
struct VendorScheduleStrip: View {
    let visits: [DashboardVendorVisit]
    let overdueCount: Int
    let dueThisWeekCount: Int
    /// Phase 50 (sub-phase B first-login): the household's
    /// `*@alfred.havenhome.dev` forwarding address. When non-nil, the
    /// empty state appends a subtle caption with a copy-to-clipboard
    /// button so users see the second invoice path immediately.
    var forwardingEmail: String? = nil
    let onTapVisit: (MaintenanceTaskDBRow) -> Void
    let onSeeAll: () -> Void
    let onUploadInvoice: () -> Void
    let onAddVendor: () -> Void

    @State private var emailCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(alignment: .firstTextBaseline) {
                Text("YOUR HOME")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                if !visits.isEmpty {
                    Button(action: onSeeAll) {
                        HStack(spacing: 4) {
                            Text("See all")
                                .font(HavenTypography.uiLabelSmall)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)
                }
            }

            if visits.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HavenTheme.spacing12) {
                        ForEach(visits) { visit in
                            VendorVisitCard(
                                task: visit.task,
                                vendorName: visit.vendorName,
                                vendorLogoURL: visit.logoURL,
                                brandColorHex: visit.brandColorHex,
                                lastCost: visit.lastCost,
                                style: .compact,
                                onTap: { onTapVisit(visit.task) }
                            )
                        }
                        seeAllCard
                    }
                    .padding(.horizontal, 2)
                }
                .scrollClipDisabled()

                summaryRow
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                    // Phase 50 (sub-phase B first-login): post-quiz, this card
                    // is the primary CTA — it absorbs the role of the old
                    // "Upload your first document" Getting Started Step 2.
                    Text("Your maintenance plan is ready")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                Text("Upload an invoice or add a vendor to start tracking who handles what, and when they're next on site.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: HavenTheme.spacing8) {
                    Button(action: onUploadInvoice) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Upload invoice")
                                .font(HavenTypography.uiLabelSmall)
                        }
                        .foregroundStyle(HavenColors.creamLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onAddVendor) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add vendor")
                                .font(HavenTypography.uiLabelSmall)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if let forwardingEmail, !forwardingEmail.isEmpty {
                    forwardingEmailCaption(forwardingEmail)
                }
            }
        }
    }

    /// Phase 50 (sub-phase B first-login): subtle caption with a
    /// copy-to-clipboard button below the Upload/Add vendor row. Same
    /// pattern as `ProjectEmailView.swift` lines 159-175 and the Q17
    /// quiz milestone — `doc.on.doc` icon flips to a checkmark for two
    /// seconds after a successful copy. Hidden entirely when the
    /// household has no forwarding address loaded yet.
    @ViewBuilder
    private func forwardingEmailCaption(_ email: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Divider()
                .overlay(HavenColors.beige200)
                .padding(.top, 2)

            Text("Or forward invoices to")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)

            Button {
                UIPasteboard.general.string = email
                emailCopied = true
                Haptics.success()
                Analytics.track(.dashboardForwardingEmailCopied, ["source": "vendor_schedule_strip"])
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    emailCopied = false
                }
            } label: {
                HStack(spacing: 6) {
                    Text(email)
                        .font(HavenTypography.uiLabel.weight(.medium))
                        .foregroundStyle(HavenColors.navy700)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: emailCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(emailCopied ? HavenColors.success : HavenColors.navy700)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy forwarding email address")
            .accessibilityValue(email)

            Text("and we'll automatically build this out.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    // MARK: - See all card

    private var seeAllCard: some View {
        Button(action: onSeeAll) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                Text("See full schedule")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy700)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 140, height: 130)
            .background(HavenColors.navy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.navy.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        HStack(spacing: 10) {
            if overdueCount > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.warning)
                    Text("\(overdueCount) overdue")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.warning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(HavenColors.warning.opacity(0.12))
                .clipShape(Capsule())
            }
            if dueThisWeekCount > 0 {
                Text("\(dueThisWeekCount) task\(dueThisWeekCount == 1 ? "" : "s") this week")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
    }
}

/// Hydrated dashboard vendor visit row. The view model resolves vendor
/// name, logo URL, brand color, and most-recent service cost up front so
/// the strip stays presentation-only and avoids spawning per-card lookups
/// that thrash scrolling.
struct DashboardVendorVisit: Identifiable {
    let id: UUID
    let task: MaintenanceTaskDBRow
    let vendorName: String?
    let logoURL: URL?
    let brandColorHex: String?
    let lastCost: Double?

    init(
        task: MaintenanceTaskDBRow,
        vendorName: String?,
        logoURL: URL?,
        brandColorHex: String?,
        lastCost: Double?
    ) {
        self.id = task.id
        self.task = task
        self.vendorName = vendorName
        self.logoURL = logoURL
        self.brandColorHex = brandColorHex
        self.lastCost = lastCost
    }
}
