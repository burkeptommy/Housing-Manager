import SwiftUI

/// Phase 95 (audit gap #90) — soft-archive sheet for vehicles that
/// have left the household but whose service history needs to
/// stick around (sold / traded / totaled).
///
/// Distinct from the destructive `deleteVehicle` flow on the
/// VehicleDetailView toolbar. Delete is for "I never owned this";
/// archive is the common HNW case where the M5 was sold to a
/// neighbor and the buyer / Carfax export wants every service
/// record on file. Service records, recalls, documents, and
/// maintenance_tasks linked via vehicle_id stay accessible by
/// direct id even though the vehicle drops off the active garage.
struct ArchiveVehicleSheet: View {
    let vehicle: VehicleRow
    var onArchived: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ArchiveReason = .sold
    @State private var isArchiving = false
    @State private var errorMessage: String?

    enum ArchiveReason: String, CaseIterable, Identifiable {
        case sold
        case traded
        case totaled
        case other

        var id: String { rawValue }

        var label: String {
            switch self {
            case .sold:    return "Sold"
            case .traded:  return "Traded in"
            case .totaled: return "Totaled"
            case .other:   return "Other"
            }
        }

        var icon: String {
            switch self {
            case .sold:    return "dollarsign.circle"
            case .traded:  return "arrow.triangle.2.circlepath"
            case .totaled: return "exclamationmark.triangle"
            case .other:   return "archivebox"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    HavenCard {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                            Text("Archive \(vehicle.displayName)")
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("This takes the vehicle off your active garage list. Every service record, recall, and document stays on file so you can show the buyer or your insurer.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HavenCard {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                            Text("REASON")
                                .font(HavenTypography.uiSectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(HavenColors.textTertiary)
                            ForEach(ArchiveReason.allCases) { reason in
                                reasonRow(reason)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                    }

                    HavenButton(
                        title: isArchiving ? "Archiving..." : "Archive vehicle",
                        action: { Task { await archive() } },
                        icon: "archivebox.fill",
                        isLoading: isArchiving,
                        isDisabled: isArchiving
                    )
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Archive vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func reasonRow(_ reason: ArchiveReason) -> some View {
        Button {
            Haptics.selection()
            selectedReason = reason
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: reason.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(selectedReason == reason ? HavenColors.action : HavenColors.textSecondary)
                    .frame(width: 24)
                Text(reason.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selectedReason == reason ? HavenColors.action : HavenColors.beige300)
            }
            .padding(.vertical, HavenTheme.spacing8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func archive() async {
        isArchiving = true
        defer { isArchiving = false }
        errorMessage = nil
        do {
            try await DatabaseService.shared.archiveVehicle(
                id: vehicle.id,
                reason: selectedReason.rawValue
            )
            Analytics.track(.vehicleArchived, [
                "vehicle_id": vehicle.id.uuidString,
                "reason": selectedReason.rawValue
            ])
            Haptics.success()
            onArchived()
        } catch {
            errorMessage = "Couldn't archive right now. Try again in a moment."
            Haptics.error()
        }
    }
}
