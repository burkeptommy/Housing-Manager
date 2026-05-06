import SwiftUI

/// Phase 95 audit (Wave 5d) — household-level vendor spend rollup.
///
/// Pre-Phase-95, the homeowner could see per-vendor YTD spend on
/// `ContractorDetailView`, but had no path to "what did I spend on
/// home this year." For HNW homeowners that's a basic question — they
/// open Mint or QuickBooks every month and want the same lens here.
///
/// This view aggregates `documents.invoiceAmount` (deduped by document)
/// + `service_records.cost` (deduped on `invoiceDocumentId`) by:
///   • current calendar year total
///   • category breakdown (HVAC, Plumbing, Landscaping, etc.)
///   • per-vendor breakdown
///
/// Each row is tappable → routes to the relevant
/// `ContractorDetailView` so the homeowner can drill in. Empty state
/// nudges them toward forwarding a bill via email.
struct HouseholdSpendView: View {
    @StateObject private var viewModel = HouseholdSpendViewModel()
    @State private var selectedTab: SpendTab = .vendor

    enum SpendTab: String, CaseIterable, Identifiable {
        case vendor, category
        var id: String { rawValue }
        var label: String {
            switch self {
            case .vendor: return "By vendor"
            case .category: return "By category"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                heroCard
                tabPicker
                content
            }
            .padding(.horizontal, HavenTheme.spacing20)
            .padding(.vertical, HavenTheme.spacing24)
        }
        .background(HavenColors.background.ignoresSafeArea())
        .navigationTitle("Home spend")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .documentChanged)) { _ in
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .contractorChanged)) { _ in
            Task { await viewModel.load() }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("THIS YEAR")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(viewModel.formattedYearTotal)
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(HavenColors.textPrimary)
                if viewModel.lastYearTotal > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.yearOverYearDelta >= 0
                              ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(viewModel.yearOverYearDelta >= 0
                                             ? HavenColors.warning : HavenColors.success)
                        Text(viewModel.formattedYearOverYear)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                if viewModel.invoiceCount > 0 {
                    Text("\(viewModel.invoiceCount) invoice\(viewModel.invoiceCount == 1 ? "" : "s") · \(viewModel.vendorCount) vendor\(viewModel.vendorCount == 1 ? "" : "s")")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(SpendTab.allCases) { tab in
                Button {
                    Haptics.selection()
                    withAnimation(HavenTheme.animationStandard) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.label)
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(selectedTab == tab ? HavenColors.textOnNavy : HavenColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedTab == tab ? HavenColors.navy800 : HavenColors.surface)
                        )
                        .overlay(
                            Capsule().stroke(selectedTab == tab ? Color.clear : HavenColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.vendorBreakdown.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
        } else if viewModel.yearTotal == 0 {
            emptyState
        } else {
            switch selectedTab {
            case .vendor: vendorList
            case .category: categoryList
            }
        }
    }

    private var vendorList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.vendorBreakdown) { row in
                NavigationLink(value: row.id) {
                    spendRow(
                        title: row.contractor.companyName,
                        subtitle: row.invoiceCount == 1
                            ? "1 invoice this year"
                            : "\(row.invoiceCount) invoices this year",
                        amount: row.total
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: UUID.self) { contractorId in
            if let row = viewModel.vendorBreakdown.first(where: { $0.id == contractorId }) {
                ContractorDetailView(contractor: row.contractor)
            }
        }
    }

    private var categoryList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.categoryBreakdown) { row in
                spendRow(
                    title: row.category,
                    subtitle: row.vendorCount == 1
                        ? "1 vendor"
                        : "\(row.vendorCount) vendors",
                    amount: row.total
                )
            }
        }
    }

    private func spendRow(title: String, subtitle: String, amount: Double) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 8)
            Text(formatCurrency(amount))
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(HavenColors.border, lineWidth: 1)
        )
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(HavenColors.textTertiary)
            Text("No spend tracked yet")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Forward bills and invoices to your Chez inbox — we'll extract the amount and tally it here automatically.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

// MARK: - View model

@MainActor
final class HouseholdSpendViewModel: ObservableObject {
    @Published var vendorBreakdown: [VendorSpend] = []
    @Published var categoryBreakdown: [CategorySpend] = []
    @Published var yearTotal: Double = 0
    @Published var lastYearTotal: Double = 0
    @Published var invoiceCount: Int = 0
    @Published var vendorCount: Int = 0
    @Published var isLoading: Bool = false

    struct VendorSpend: Identifiable {
        let id: UUID
        let contractor: ContractorRow
        let total: Double
        let invoiceCount: Int
    }

    struct CategorySpend: Identifiable {
        let id = UUID()
        let category: String
        let total: Double
        let vendorCount: Int
    }

    var formattedYearTotal: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: yearTotal)) ?? "$\(Int(yearTotal))"
    }

    var yearOverYearDelta: Double { yearTotal - lastYearTotal }
    var formattedYearOverYear: String {
        guard lastYearTotal > 0 else { return "" }
        let delta = yearOverYearDelta
        let percent = (delta / lastYearTotal) * 100
        let sign = delta >= 0 ? "+" : ""
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        let amountStr = f.string(from: NSNumber(value: abs(delta))) ?? "$\(Int(abs(delta)))"
        return "\(sign)\(amountStr) (\(String(format: "%.0f", percent))%) vs last year"
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let db = DatabaseService.shared
        let calendar = Calendar.current
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: Date())) ?? Date.distantPast
        let lastYearStart = calendar.date(byAdding: .year, value: -1, to: yearStart) ?? Date.distantPast
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        async let contractors = (try? db.fetchContractors()) ?? []
        async let documents = (try? db.fetchDocuments(category: nil, status: nil)) ?? []

        let (loadedContractors, loadedDocuments) = await (contractors, documents)
        let contractorsById = Dictionary(uniqueKeysWithValues: loadedContractors.map { ($0.id, $0) })

        var vendorTotals: [UUID: Double] = [:]
        var vendorInvoiceCount: [UUID: Int] = [:]
        var thisYearTotal: Double = 0
        var lastYearTotalLocal: Double = 0
        var invoiceCountLocal = 0

        for doc in loadedDocuments {
            guard let amount = doc.invoiceAmount, amount > 0 else { continue }
            guard let dateStr = doc.invoiceDate,
                  let date = formatter.date(from: dateStr) else { continue }
            if date >= yearStart {
                thisYearTotal += amount
                invoiceCountLocal += 1
                if let cid = doc.contractorId {
                    vendorTotals[cid, default: 0] += amount
                    vendorInvoiceCount[cid, default: 0] += 1
                }
            } else if date >= lastYearStart && date < yearStart {
                lastYearTotalLocal += amount
            }
        }

        let vendors = vendorTotals
            .compactMap { (id, total) -> VendorSpend? in
                guard let contractor = contractorsById[id], let count = vendorInvoiceCount[id] else { return nil }
                return VendorSpend(id: id, contractor: contractor, total: total, invoiceCount: count)
            }
            .sorted { $0.total > $1.total }

        // Category aggregation: group vendors by canonical category.
        var categoryBuckets: [String: (total: Double, vendors: Set<UUID>)] = [:]
        for v in vendors {
            let category = v.contractor.category?.trimmingCharacters(in: .whitespaces) ?? "Other"
            let key = category.isEmpty ? "Other" : category
            var entry = categoryBuckets[key] ?? (0, [])
            entry.total += v.total
            entry.vendors.insert(v.contractor.id)
            categoryBuckets[key] = entry
        }
        let categories = categoryBuckets
            .map { CategorySpend(category: $0.key, total: $0.value.total, vendorCount: $0.value.vendors.count) }
            .sorted { $0.total > $1.total }

        self.vendorBreakdown = vendors
        self.categoryBreakdown = categories
        self.yearTotal = thisYearTotal
        self.lastYearTotal = lastYearTotalLocal
        self.invoiceCount = invoiceCountLocal
        self.vendorCount = vendors.count
    }
}
