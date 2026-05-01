import Foundation
import SwiftUI

/// Phase 80.1 — View model for the Chez profile (standing instructions).
/// Owns the read/write loop with the chez-concierge Edge Function.
/// Loads on init, debounces writes so users typing in the about-us
/// field don't fire one network call per keystroke.

@MainActor
final class ChezProfileViewModel: ObservableObject {
    @Published var profile: ChezProfile = ChezProfile()
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    /// Stamped after a successful save so the caller can flash a brief
    /// confirmation toast / haptic without owning that state itself.
    @Published var lastSavedAt: Date?

    private var saveTask: Task<Void, Never>?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await HavenSupabase.fetchChezProfile()
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezProfileVM] load failed: \(error)")
        }
    }

    /// Debounced save — writes to the Edge Function ~600ms after the
    /// last edit. Cancels in-flight writes to avoid out-of-order saves.
    func saveDebounced() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            await self?.saveNow()
        }
    }

    func saveNow() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await HavenSupabase.updateChezProfile(profile, replace: false)
            profile = saved
            lastSavedAt = Date()
            errorMessage = nil
            NotificationCenter.default.post(name: .chezProfileChanged, object: nil)
            Analytics.track(.chezProfileSaved, ["has_about_us": String(!(profile.aboutUs ?? "").isEmpty)])
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezProfileVM] save failed: \(error)")
        }
    }

    /// Initialize spending tiers with defaults if the user opens that
    /// section before any data is set.
    func ensureSpendingTiers() {
        if profile.spendingTiers == nil {
            profile.spendingTiers = .default
        }
    }
}
