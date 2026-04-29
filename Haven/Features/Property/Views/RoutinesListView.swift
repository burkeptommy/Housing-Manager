import SwiftUI

/// Phase 55.3: Unified routines list. Replaces the Phase 54D
/// `HouseholdCadencesView`. Shows every active routine for the
/// household — trash, cleaning with Renata, lawn care with Blue Fox,
/// the full set — in one place. Tap a row to open the routine itself;
/// edit lives one level deeper inside `RoutineDetailView`. Swipe still
/// archives from the list.
///
/// Routines that used to live as `standing_appointments` now render
/// here too, so the user has a single surface for "everything that
/// just happens on a schedule" regardless of whether a vendor is
/// attached. Tasks (things the user has to actively book) stay on
/// the Maintenance schedule.
struct RoutinesListView: View {
    let householdId: UUID
    let propertyId: UUID?

    @StateObject private var viewModel = RoutinesListViewModel()
    @State private var showAddSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.routines.isEmpty {
                ProgressView("Loading active programs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.routines.isEmpty {
                emptyState
            } else {
                routineList
            }
        }
        .background(HavenColors.background)
        .navigationTitle("Active Programs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus").foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .task { await viewModel.load(householdId: householdId) }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await viewModel.load(householdId: householdId) }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                RoutineEditSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    existing: nil,
                    onSaved: { Task { await viewModel.load(householdId: householdId) } }
                )
            }
        }
        .trackScreen("RoutinesListView")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No active programs yet", systemImage: "calendar.badge.clock")
        } description: {
            Text("Set up recurring services and household rhythms. Trash day, cleaning, lawn care, pool service, and pickup schedules live here.")
        } actions: {
            HavenButton(
                title: "Add program",
                action: { showAddSheet = true },
                icon: "plus",
                isFullWidth: false
            )
        }
    }

    private var routineList: some View {
        List {
            Section {
                Text("Active programs are the recurring services and schedules Chez keeps humming along for you. One-time visits still live on the Maintenance schedule.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
            }

            ForEach(viewModel.routines) { routine in
                NavigationLink {
                    RoutineDetailView(
                        routine: routine,
                        householdId: householdId
                    )
                } label: {
                    routineCard(routine)
                }
                .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.delete(routine)
                                Haptics.success()
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .refreshable { await viewModel.load(householdId: householdId) }
    }

    @ViewBuilder
    private func routineCard(_ routine: RoutineRow) -> some View {
        let linkedVendor = viewModel.contractor(for: routine)
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                if let vendor = linkedVendor {
                    VendorLogoView(contractor: vendor, size: 36)
                } else {
                    Image(systemName: routine.resolvedIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.presentationLabel)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let vendor = linkedVendor {
                        Text(vendor.companyName)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.navy700)
                    }
                    Text(routine.typedCadence?.displayLabel ?? "Recurring")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text(routine.activeMonthsSummary)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }
}

/// Phase 55.3: View model for `RoutinesListView`. Loads routines and
/// contractors in parallel so the card can show vendor logos without
/// an N+1 lookup. Contractor lookup is indexed by id to match the
/// Phase 54E pattern in `HouseholdCadencesViewModel`.
@MainActor
final class RoutinesListViewModel: ObservableObject {
    @Published private(set) var routines: [RoutineRow] = []
    @Published private(set) var contractorsById: [UUID: ContractorRow] = [:]
    @Published private(set) var isLoading = false

    private let db = DatabaseService.shared

    func load(householdId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        async let routinesTask = db.fetchRoutines(householdId: householdId)
        async let contractorsTask = db.fetchContractors()
        do {
            let loaded = try await routinesTask
            routines = loaded.sorted {
                $0.presentationLabel.localizedCaseInsensitiveCompare($1.presentationLabel) == .orderedAscending
            }
        } catch {
            print("[RoutinesListVM] load routines failed: \(error)")
            routines = []
        }
        if let rows = try? await contractorsTask {
            contractorsById = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        } else {
            contractorsById = [:]
        }
    }

    func contractor(for routine: RoutineRow) -> ContractorRow? {
        guard let id = routine.vendorId else { return nil }
        return contractorsById[id]
    }

    func delete(_ routine: RoutineRow) async {
        do {
            try await db.archiveRoutine(id: routine.id)
            routines.removeAll { $0.id == routine.id }
            NotificationCenter.default.post(name: .routineChanged, object: nil)
        } catch {
            print("[RoutinesListVM] delete failed: \(error)")
        }
    }
}
