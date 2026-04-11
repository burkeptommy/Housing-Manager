import SwiftUI

/// Reusable field for linking an estate attorney to a document.
/// Renders as a tappable row matching the metadataCard pattern in
/// DocumentDetailView. Picker shows trusted_contacts filtered to
/// attorney roles, plus an "Add New Attorney" option.
struct LinkedAttorneyField: View {
    let document: DocumentRow
    let allTrustedContacts: [TrustedContactRow]
    var onUpdate: ((UUID?) -> Void)?
    var onAddNewAttorney: (() -> Void)?

    @State private var showPicker = false

    private var linkedAttorney: TrustedContactRow? {
        guard let id = document.linkedAttorneyContactId else { return nil }
        return allTrustedContacts.first { $0.id == id }
    }

    private var attorneyContacts: [TrustedContactRow] {
        allTrustedContacts.filter { contact in
            let role = contact.role.lowercased()
            return role.contains("attorney") || role.contains("lawyer")
                || role.contains("estate") || role.contains("legal")
        }
    }

    var body: some View {
        Button {
            Haptics.light()
            showPicker = true
        } label: {
            HStack {
                Text("Estate Attorney")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                if let attorney = linkedAttorney {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(attorney.name)
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.navy700)
                        if let firm = attorney.company, !firm.isEmpty {
                            Text(firm)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                } else {
                    Text("Link attorney")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            attorneyPickerSheet
        }
    }

    // MARK: - Picker Sheet

    private var attorneyPickerSheet: some View {
        NavigationStack {
            List {
                // Existing attorney contacts
                if !attorneyContacts.isEmpty {
                    Section {
                        ForEach(attorneyContacts) { contact in
                            Button {
                                Haptics.light()
                                onUpdate?(contact.id)
                                showPicker = false
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(HavenColors.navy.opacity(0.08))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "person.crop.circle.badge.checkmark")
                                            .font(.system(size: 14))
                                            .foregroundStyle(HavenColors.navy700)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(HavenTypography.headline)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if let firm = contact.company, !firm.isEmpty {
                                            Text(firm)
                                                .font(HavenTypography.bodySmall)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if contact.id == document.linkedAttorneyContactId {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HavenColors.success)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("YOUR CONTACTS")
                    }
                }

                // Add new attorney
                Section {
                    Button {
                        Haptics.light()
                        showPicker = false
                        // Small delay to let sheet dismiss before presenting new one
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAddNewAttorney?()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(HavenColors.beige300, lineWidth: 1.5)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            Text("Add New Attorney")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Remove link
                if document.linkedAttorneyContactId != nil {
                    Section {
                        Button(role: .destructive) {
                            Haptics.light()
                            onUpdate?(nil)
                            showPicker = false
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Remove Attorney Link")
                            }
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.critical)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Estate Attorney")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPicker = false }
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.navy)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
