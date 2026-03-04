import UIKit

/// Centralized haptic feedback for consistent tactile responses across Haven.
enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Light tap — tab switches, filter toggles, minor interactions.
    static func light() {
        lightGenerator.impactOccurred()
    }

    /// Medium tap — button presses, card selections.
    static func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy tap — destructive actions, major state changes.
    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Selection change — picker changes, list reorders.
    static func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Success — upload complete, task marked done, save confirmed.
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning — expiring items, low scores.
    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error — failed operations, validation errors.
    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
