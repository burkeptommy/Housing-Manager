import SwiftUI

/// Standalone sheet wrapper around the existing `VINScannerView` camera
/// component. Used by the quiz `QuizVehicleInputSelector` so the same VIN
/// camera flow runs from the quiz, the AddVehicleView, and any future
/// "scan a VIN" entry point. Keeps presentation styling consistent.
struct VINScannerSheet: View {
    let onCapture: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VINScannerView { base64 in
            onCapture(base64)
            dismiss()
        }
        .ignoresSafeArea()
    }
}
