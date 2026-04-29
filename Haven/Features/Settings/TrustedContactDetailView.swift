import SwiftUI

struct TrustedContactDetailView: View {
    let contact: TrustedContactRow
    @ObservedObject var viewModel: TrustedContactsViewModel
    @State private var sharedDocuments: [DocumentRow] = []
    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Contact info card
                contactInfoCard

                // Invite status card
                inviteStatusCard

                // Shared documents
                sharedDocumentsCard
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditForm = true
                    } label: {
                        Label("Edit Contact", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Contact", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .trackScreen("TrustedContactDetailView")
        .task {
            sharedDocuments = await viewModel.fetchSharedDocuments(contactId: contact.id)
        }
        .sheet(isPresented: $showEditForm) {
            NavigationStack {
                TrustedContactFormView(viewModel: viewModel, editingContact: contact)
            }
        }
        .confirmationDialog("Delete Contact?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteContact(contact)
                    dismiss()
                }
            }
        } message: {
            Text("This will remove \(contact.name) and revoke their access to all shared documents.")
        }
    }

    private var contactInfoCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.badge.key.fill")
                        .font(.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("CONTACT INFO")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                infoRow("Role", value: contact.role.replacingOccurrences(of: "_", with: " ").capitalized)

                if !contact.email.isEmpty {
                    infoRow("Email", value: contact.email)
                }

                if let phone = contact.phone, !phone.isEmpty {
                    infoRow("Phone", value: phone)
                }

                if let company = contact.company, !company.isEmpty {
                    infoRow("Company", value: company)
                }

                if let notes = contact.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(notes)
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private var inviteStatusCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("INVITE STATUS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                HStack {
                    Text("Status")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text(contact.inviteStatus.capitalized)
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                }

                if contact.inviteStatus == "pending" && !contact.email.isEmpty {
                    Button {
                        Task {
                            await viewModel.updateContact(id: contact.id, TrustedContactUpdate(inviteStatus: "sent"))
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Invite")
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch contact.inviteStatus {
        case "accepted": return HavenColors.success
        case "sent": return HavenColors.info
        case "revoked": return HavenColors.critical
        default: return HavenColors.textTertiary
        }
    }

    private var sharedDocumentsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("SHARED DOCUMENTS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text("\(sharedDocuments.count)")
                        .font(HavenTypography.badgeLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.12))
                        .foregroundStyle(HavenColors.textPrimary)
                        .clipShape(Capsule())
                }

                if sharedDocuments.isEmpty {
                    Text("Share documents with this contact from the document detail screen.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(sharedDocuments) { doc in
                        HStack(spacing: 10) {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(HavenColors.textSecondary)
                            VStack(alignment: .leading) {
                                Text(doc.title)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                Text(doc.category)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Button {
                                Task {
                                    Analytics.track(.trustedContactDocumentAccess, ["action": "revoked", "contact_id": contact.id.uuidString])
                                    await viewModel.revokeDocumentAccess(contactId: contact.id, documentId: doc.id)
                                    sharedDocuments.removeAll { $0.id == doc.id }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
