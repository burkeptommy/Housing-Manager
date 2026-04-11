import SwiftUI

/// Detail/edit sheet for a linked household advisor.
/// Pattern from UtilityDetailSheet on the Property tab.
struct AdvisorDetailSheet: View {
    let advisor: HouseholdAdvisorRow
    var onUpdate: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var contactName: String = ""
    @State private var companyName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var website: String = ""
    @State private var notes: String = ""
    @State private var showDeleteConfirm = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    // Hero
                    heroSection

                    // Editable fields
                    fieldSection

                    // Delete
                    deleteSection
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, HavenTheme.spacing16)
            }
            .background(HavenColors.background)
            .navigationTitle(advisor.typeLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .disabled(isSaving)
                }
            }
            .confirmationDialog("Remove this advisor?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    deleteAdvisor()
                }
            }
            .onAppear {
                contactName = advisor.contactName ?? ""
                companyName = advisor.companyName ?? ""
                phone = advisor.phone ?? ""
                email = advisor.email ?? ""
                website = advisor.website ?? ""
                notes = advisor.notes ?? ""
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(spacing: 16) {
            if let logoUrl = advisor.logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    brandInitial
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                brandInitial
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(advisor.displayName)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)

                if let subtitle = advisor.displaySubtitle {
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Text(advisor.typeLabel)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(HavenColors.navy.opacity(0.06))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private var brandInitial: some View {
        let color = advisor.brandColor.map { Color(hex: $0) } ?? HavenColors.navy700
        return Text(String(advisor.displayName.prefix(1)).uppercased())
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Fields

    private var fieldSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            Text("CONTACT DETAILS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            editField("Contact Name", text: $contactName)
            editField("Company / Firm", text: $companyName)
            editField("Phone", text: $phone, keyboardType: .phonePad)
            editField("Email", text: $email, keyboardType: .emailAddress)
            editField("Website", text: $website, keyboardType: .URL)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                TextEditor(text: $notes)
                    .font(HavenTypography.body)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
        }
    }

    private func editField(_ label: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            TextField(label, text: text)
                .font(HavenTypography.body)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding(HavenTheme.spacing12)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Remove This Advisor")
            }
            .font(HavenTypography.uiLabel)
            .foregroundStyle(HavenColors.critical)
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
        }
    }

    // MARK: - Actions

    private func save() {
        isSaving = true
        Task {
            let update = HouseholdAdvisorUpdate(
                providerName: companyName.isEmpty ? nil : companyName,
                phone: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email,
                website: website.isEmpty ? nil : website,
                contactName: contactName.isEmpty ? nil : contactName,
                companyName: companyName.isEmpty ? nil : companyName,
                notes: notes.isEmpty ? nil : notes
            )
            try? await DatabaseService.shared.updateHouseholdAdvisor(id: advisor.id, update)
            NotificationCenter.default.post(name: .advisorChanged, object: nil)
            onUpdate?()
            isSaving = false
            Haptics.success()
            dismiss()
        }
    }

    private func deleteAdvisor() {
        Task {
            try? await DatabaseService.shared.deleteHouseholdAdvisor(id: advisor.id)
            NotificationCenter.default.post(name: .advisorChanged, object: nil)
            onDelete?()
            dismiss()
        }
    }
}
