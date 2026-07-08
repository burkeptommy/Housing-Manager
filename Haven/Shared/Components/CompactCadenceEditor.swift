import SwiftUI

/// Phase 7 M2 — the inline cadence editor for routine rows on the
/// suggested-actions review card. Deliberately NOT an extraction of
/// RoutineEditSheet's form (its weekday chips are coupled to its own
/// state machine); this is the minimal "confirm or adjust what the email
/// said" surface: a frequency menu + the shared ActiveMonthsPicker.
/// The chosen frequency travels as intervalDays; RoutineSeeder
/// .createFromIngestion maps it back to a RoutineCadenceType (and
/// synthesizes days_of_week for weekly variants), so the cadence rules
/// stay single-sourced.
enum CompactCadenceChoice: String, CaseIterable, Identifiable {
    case weekly, biweekly, triweekly, monthly, quarterly, semiannual, annual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: return "Every week"
        case .biweekly: return "Every 2 weeks"
        case .triweekly: return "Every 3 weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiannual: return "Twice a year"
        case .annual: return "Annually"
        }
    }

    var intervalDays: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .triweekly: return 21
        case .monthly: return 30
        case .quarterly: return 91
        case .semiannual: return 182
        case .annual: return 365
        }
    }

    /// Best-fit choice for an evidence interval ("every 2 weeks" → 14 →
    /// .biweekly). Bands match RoutineSeeder.createFromIngestion's mapping.
    static func nearest(toDays days: Int?) -> CompactCadenceChoice? {
        guard let days, days > 0 else { return nil }
        switch days {
        case 5...9: return .weekly
        case 12...16: return .biweekly
        case 19...23: return .triweekly
        case 26...34: return .monthly
        case 82...100: return .quarterly
        case 170...195: return .semiannual
        case 340...395: return .annual
        default: return nil
        }
    }
}

struct CompactCadenceEditor: View {
    @Binding var choice: CompactCadenceChoice
    @Binding var activeMonths: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                ForEach(CompactCadenceChoice.allCases) { c in
                    Button {
                        choice = c
                        Haptics.selection()
                    } label: {
                        if c == choice {
                            Label(c.label, systemImage: "checkmark")
                        } else {
                            Text(c.label)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .font(.system(size: 10))
                    Text(choice.label)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.navy800)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(HavenColors.beige200.opacity(0.6))
                .clipShape(Capsule())
            }

            ActiveMonthsPicker(selectedMonths: $activeMonths)
        }
    }
}
