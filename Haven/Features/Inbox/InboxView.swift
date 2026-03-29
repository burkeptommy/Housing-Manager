import SwiftUI

/// Displays all forwarded emails and their processing status.
/// Items that need user action (property assignment, classification) show inline action cards.
struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @State private var filter: InboxFilter = .needsAction

    enum InboxFilter: String, CaseIterable {
        case needsAction = "Needs Action"
        case unread = "Unread"
        case all = "All"
    }

    @State private var showDeleteConfirm = false
    @State private var itemToDelete: DatabaseService.InboxItemRow?

    var body: some View {
        List {
            // Filter picker
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(InboxFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if viewModel.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonCard(lineCount: 3)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            } else if filteredItems.isEmpty {
                Section {
                    emptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            } else {
                Section {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            InboxItemDetailView(
                                item: item,
                                properties: viewModel.properties,
                                onProcess: { propertyId, action, category in
                                    Task {
                                        await viewModel.processItem(item, propertyId: propertyId, action: action, documentCategory: category)
                                    }
                                },
                                onDismiss: {
                                    withAnimation { viewModel.dismissItem(item) }
                                }
                            )
                            .onAppear {
                                // Mark as read when tapped into
                                if !item.seen {
                                    viewModel.markAsRead(item)
                                }
                            }
                        } label: {
                            InboxItemCard(
                                item: item,
                                properties: viewModel.properties,
                                onProcess: { propertyId, action, category in
                                    Task { await viewModel.processItem(item, propertyId: propertyId, action: action, documentCategory: category) }
                                },
                                onDismiss: {
                                    withAnimation { viewModel.dismissItem(item) }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            if !item.seen {
                                Button {
                                    viewModel.markAsRead(item)
                                } label: {
                                    Label("Mark as Read", systemImage: "envelope.open")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .trackScreen("InboxView")
        .alert("Delete this item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task {
                        try? await DatabaseService.shared.deleteInboxItem(id: item.id)
                        viewModel.items.removeAll { $0.id == item.id }
                        Haptics.success()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var filteredItems: [DatabaseService.InboxItemRow] {
        switch filter {
        case .needsAction:
            return viewModel.items.filter { $0.isPending }
        case .unread:
            return viewModel.items.filter { !$0.seen }
        case .all:
            return viewModel.items
        }
    }

    private var emptyState: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Spacer().frame(height: 40)

            Image(systemName: "tray")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: HavenTheme.spacing8) {
                Text("No emails yet")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Forward contractor quotes, documents, or vendor info to your Haven email address. Alfred will process everything automatically.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            NavigationLink {
                ProjectEmailView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                    Text("View Your Haven Email")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(.white)
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, HavenTheme.spacing12)
                .background(HavenColors.navy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var items: [DatabaseService.InboxItemRow] = []
    @Published var properties: [PropertyRow] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        isLoading = items.isEmpty
        do {
            async let itemsReq = DatabaseService.shared.fetchAllInboxItems()
            async let propsReq = DatabaseService.shared.fetchProperties()
            let (loadedItems, loadedProps) = try await (itemsReq, propsReq)
            items = loadedItems
            properties = loadedProps
        } catch {
            print("[InboxVM] Load failed: \(error)")
        }
        isLoading = false
    }

    func processItem(
        _ item: DatabaseService.InboxItemRow,
        propertyId: UUID?,
        action: String,
        documentCategory: String?
    ) async {
        do {
            let _ = try await HavenSupabase.processInboxItem(
                inboxItemId: item.id.uuidString,
                propertyId: propertyId?.uuidString,
                action: action,
                documentCategory: documentCategory
            )
            Haptics.success()
            // Reload to reflect changes
            await load()
        } catch {
            print("[InboxVM] Process failed: \(error)")
            Haptics.error()
            self.error = "Processing failed: \(error.localizedDescription)"
        }
    }

    func dismissItem(_ item: DatabaseService.InboxItemRow) {
        // Mark as seen (moves to "All" history) instead of deleting
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: idx)
        }
        Task {
            try? await DatabaseService.shared.markInboxItemsSeen(ids: [item.id])
        }
    }

    func markAsRead(_ item: DatabaseService.InboxItemRow) {
        Task {
            try? await DatabaseService.shared.markInboxItemsSeen(ids: [item.id])
            // Reload to update the seen state
            await load()
        }
    }
}
