import SwiftUI

/// Phase 67H: bottom sheet for adding a homeowner subitem to a bundle.
/// Two recurrence modes:
///   * `.once` — attach to the next bundle fire only, then archive
///     when that parent completes. Use case: one-shot reminder
///     ("ask the chimney sweep about the slow draft this fall").
///   * `.always` — append to every future bundle parent's "What's
///     included" list until the user archives it. Use case:
///     standing reminder ("remind me to ask about the boiler noise
///     each annual visit").
///
/// Default is `.once` because that's the most common single-use
/// case and avoids surprise persistence. The user can flip to
/// "Every visit" with one tap.
struct AddBundleSubitemSheet: View {
    /// Bundle the subitem attaches to (e.g. "Chimney:fall",
    /// "HVAC:spring"). Comes from the parent task's `templateId`.
    let bundleId: String
    /// Display name shown in the sheet header (e.g. "Fall Chimney
    /// Service"). Comes from the parent task's title.
    let bundleDisplayName: String
    /// Property scope for the new row. Comes from the parent task's
    /// `propertyId`.
    let propertyId: UUID
    /// Household scope for the new row. Comes from the parent task's
    /// `householdId`.
    let householdId: UUID

    /// Fired with the newly-inserted row so the parent view can
    /// optimistically refresh its "Custom additions" list.
    let onCreated: (BundleCustomSubitemRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var recurrence: Recurrence = .once
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @FocusState private var titleFocused: Bool

    enum Recurrence: String {
        case once
        case always
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ADDING TO")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.4)
                            .foregroundColor(HavenColors.textSecondary)
                        Text(bundleDisplayName)
                            .font(HavenTypography.headline)
                            .foregroundColor(HavenColors.textPrimary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField(
                        "e.g. Ask about the leaky outdoor faucet",
                        text: $title,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .focused($titleFocused)
                } header: {
                    Text("What should they handle?")
                }

                Section {
                    Picker("How often?", selection: $recurrence) {
                        Text("Just this visit").tag(Recurrence.once)
                        Text("Every visit").tag(Recurrence.always)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(recurrence == .once
                        ? "Shows on the next visit only. Disappears after the visit is marked complete."
                        : "Shows on every future visit until you remove it from the list."
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundColor(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Add to this visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onAppear {
                titleFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var insert = BundleCustomSubitemInsert(
            householdId: householdId,
            propertyId: propertyId,
            bundleId: bundleId,
            title: trimmed
        )
        insert.recurrence = recurrence.rawValue

        // Stamp the creator when we can resolve the session quickly.
        // RLS enforces household membership; nil here just means the
        // audit log loses a name, not that the insert fails.
        if let session = await HavenSupabase.safeSession(timeout: 1.0) {
            insert.addedByUserId = session.user.id
        }

        do {
            let row = try await DatabaseService.shared.createBundleCustomSubitem(insert)
            Haptics.success()
            Analytics.track(.bundleCustomSubitemAdded, [
                "bundle_id": bundleId,
                "recurrence": recurrence.rawValue,
            ])
            onCreated(row)
            dismiss()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
