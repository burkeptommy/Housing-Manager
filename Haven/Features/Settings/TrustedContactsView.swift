import SwiftUI

struct TrustedContactsView: View {
    @StateObject private var viewModel = TrustedContactsViewModel()
    @State private var showAddContact = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contacts.isEmpty {
                ProgressView("Loading contacts...")
            } else if viewModel.contacts.isEmpty {
                ContentUnavailableView {
                    Label("Your Trusted Circle", systemImage: "person.badge.key")
                } description: {
                    Text("Add trusted contacts like your attorney, executor, or financial advisor. They can be granted access to specific documents for estate planning.")
                } actions: {
                    Button {
                        showAddContact = true
                    } label: {
                        Text("Add Trusted Contact")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HavenColors.navy)
                }
            } else {
                List {
                    ForEach(viewModel.contacts) { contact in
                        NavigationLink {
                            TrustedContactDetailView(contact: contact, viewModel: viewModel)
                        } label: {
                            contactRow(contact)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteContact(viewModel.contacts[index])
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(HavenColors.cream)
            }
        }
        .navigationTitle("Trusted Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddContact = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .trackScreen("TrustedContactsView")
        .task {
            await viewModel.loadContacts()
        }
        .sheet(isPresented: $showAddContact) {
            NavigationStack {
                TrustedContactFormView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }

    private func contactRow(_ contact: TrustedContactRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .font(.title3)
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(HavenColors.navy.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(HavenColors.textPrimary)
                HStack(spacing: 6) {
                    Text(contact.role.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    if let company = contact.company, !company.isEmpty {
                        Text("•")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(company)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            Spacer()

            statusBadge(contact.inviteStatus)
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(HavenTypography.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "accepted": return HavenColors.success
        case "sent": return HavenColors.info
        case "revoked": return HavenColors.critical
        default: return HavenColors.textTertiary
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TrustedContactsViewModel: ObservableObject {
    @Published var contacts: [TrustedContactRow] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = DatabaseService.shared

    func loadContacts() async {
        isLoading = true
        do {
            contacts = try await db.fetchTrustedContacts()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createContact(_ insert: TrustedContactInsert) async {
        do {
            let contact = try await db.createTrustedContact(insert)
            contacts.append(contact)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateContact(id: UUID, _ update: TrustedContactUpdate) async {
        do {
            let updated = try await db.updateTrustedContact(id: id, update)
            if let index = contacts.firstIndex(where: { $0.id == id }) {
                contacts[index] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteContact(_ contact: TrustedContactRow) async {
        do {
            try await db.deleteTrustedContact(id: contact.id)
            contacts.removeAll { $0.id == contact.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchSharedDocuments(contactId: UUID) async -> [DocumentRow] {
        (try? await db.fetchDocumentsForTrustedContact(contactId: contactId)) ?? []
    }

    func revokeDocumentAccess(contactId: UUID, documentId: UUID) async {
        do {
            try await db.revokeDocumentAccess(contactId: contactId, documentId: documentId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
