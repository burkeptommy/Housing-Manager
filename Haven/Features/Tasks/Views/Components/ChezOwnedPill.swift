import SwiftUI

/// Phase 70 (Tasks v2): Tiny salmon pill rendered inline on bundle parent
/// cards + routine rows when Chez owns the work.
///
/// Replaces the dedicated "Chez Handling" section the Phase 67 V5 view had.
/// One source of truth: a routine (or task) is either Chez-owned or not.
/// The pill communicates that without duplicating the row into a second
/// section, which was the design discipline Tom asked for ("don't show the
/// same routines twice").
///
/// Visual: 9pt uppercase "CHEZ" in white on `HavenColors.action` background.
/// Capsule shape, 12pt corner radius, 8pt horizontal padding. Matches the
/// existing `ChezOwnsBadge` (Haven/Features/ChezRequests/Components/) but
/// scaled down for inline use in a card row.
struct ChezOwnedPill: View {
    var body: some View {
        Text("CHEZ")
            .font(.system(size: 9, weight: .bold))
            .tracking(0.6)
            .foregroundColor(HavenColors.textOnAction)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(HavenColors.action)
            )
            .accessibilityLabel("Chez owns this. Chez is handling scheduling and follow-up.")
    }
}

#if DEBUG
#Preview {
    HStack {
        ChezOwnedPill()
        Text("Other content alongside")
            .font(.body)
    }
    .padding()
    .background(HavenColors.surface)
}
#endif
