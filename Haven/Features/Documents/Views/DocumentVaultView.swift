import SwiftUI

struct DocumentVaultView: View {
    @StateObject private var viewModel = DocumentVaultViewModel()
    @State private var showUpload = false
    @State private var showMissing = false
    @State private var showGapAnalysis = false
    @State private var showSearch = false
    @State private var expandedSections: Set<String> = []
    @State private var analyzingDocId: UUID?
    @State private var uploadCategory: DocumentCategory?
    @State private var showDuplicates = false
    @State private var showExpiring = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedMemberId: UUID?
    @State private var lifeTab: LifeTab = .documents

    enum LifeTab: String, CaseIterable {
        case documents = "Documents"
        case family = "Family"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Fixed header: title + tab picker
                VStack(spacing: 0) {
                    screenTitle("Life")
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.top, HavenTheme.spacing4)

                    Picker("Section", selection: $lifeTab) {
                        ForEach(LifeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.vertical, HavenTheme.spacing8)
                }

                if lifeTab == .family {
                    // Family tab — NOT inside ScrollView (it has its own List)
                    FamilyInboxView()
                } else {
                    // Documents tab — inside ScrollView
                    ScrollView {
                        // Family member scroller
                        if !viewModel.familyMembers.isEmpty {
                            familyMemberScroller
                                .padding(.top, HavenTheme.spacing8)
                                .padding(.bottom, HavenTheme.spacing4)
                        }

                        if viewModel.isLoading && viewModel.documents.isEmpty {
                            VStack(spacing: HavenTheme.spacing16) {
                                SkeletonCard()
                                SkeletonScorecard()
                                SkeletonCard(lineCount: 4)
                            }
                            .padding()
                        } else if viewModel.documents.isEmpty && viewModel.searchText.isEmpty {
                            emptyVaultContent
                        } else {
                            documentListContent
                        }
                    }
                }
            } // end VStack
            .background(HavenColors.background)
            .navigationTitle("Life")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(height: 0)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Menu("By Status") {
                            Button("Active") { Analytics.track(.documentFilterChanged, ["filter": "active"]); viewModel.filterStatus = "active" }
                            Button("Expired") { Analytics.track(.documentFilterChanged, ["filter": "expired"]); viewModel.filterStatus = "expired" }
                            Button("Expiring Soon") { Analytics.track(.documentFilterChanged, ["filter": "expiringSoon"]); viewModel.filterStatus = "expiringSoon" }
                            Button("Needs Review") { Analytics.track(.documentFilterChanged, ["filter": "needsReview"]); viewModel.filterStatus = "needsReview" }
                        }

                        if !viewModel.familyMembers.isEmpty {
                            Menu("By Family Member") {
                                ForEach(viewModel.familyMembers.sortedByAge()) { member in
                                    Button("\(member.firstName) \(member.lastName)") {
                                        viewModel.filterFamilyMemberId = member.id
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            Haptics.light()
                            Analytics.track(.missingDocumentsViewed)
                            showMissing = true
                        } label: {
                            Label("Missing Documents", systemImage: "exclamationmark.triangle")
                        }
                        Button {
                            Haptics.light()
                            Analytics.track(.gapAnalysisRequested, ["source": "vault_menu"])
                        } label: {
                            Label("Gap Analysis", systemImage: "chart.bar.doc.horizontal")
                        }

                        if !viewModel.deletedDocuments.isEmpty {
                            NavigationLink {
                                recentlyDeletedView
                            } label: {
                                Label("Recently Deleted (\(viewModel.deletedDocuments.count))", systemImage: "trash")
                            }
                        }

                        if viewModel.hasActiveFilters {
                            Divider()
                            Button("Clear Filters") { viewModel.clearFilters() }
                        }
                    } label: {
                        Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
                    }
                    .accessibilityLabel("Filter documents")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Haptics.light()
                            Analytics.track(.documentUploadStarted, ["source": "toolbar_menu"])
                            uploadCategory = nil
                            showUpload = true
                        } label: {
                            Label("Upload Document", systemImage: "doc.badge.plus")
                        }

                        Button {
                            Task { await viewModel.retagAllDocuments() }
                        } label: {
                            Label("Re-tag Family Members", systemImage: "person.crop.circle.badge.checkmark")
                        }
                        .disabled(viewModel.isRetagging)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
                    }
                    .accessibilityLabel("Document actions")
                }
            }
            .trackScreen("DocumentVaultView")
            .modifier(ConditionalSearchable(isActive: lifeTab == .documents, text: $viewModel.searchText))
            .onChange(of: viewModel.searchText) { _, newValue in
                if !newValue.isEmpty {
                    Analytics.track(.documentSearched, ["query_length": newValue.count])
                }
            }
            .refreshable {
                Haptics.light()
                Analytics.track(.documentRefreshed)
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
            .onAppear {
                // Refresh on return from detail view (e.g. after deletion)
                if !viewModel.documents.isEmpty {
                    Task { await viewModel.loadData() }
                }
            }
            .sheet(isPresented: $showUpload) {
                DocumentUploadView(onComplete: {
                    Haptics.success()
                    Task { await viewModel.loadData() }
                })
            }
            .sheet(isPresented: $showMissing) {
                NavigationStack {
                    MissingDocumentsView(
                        missingCategories: viewModel.missingCategories,
                        onUpload: { _ in
                            showMissing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showUpload = true
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showGapAnalysis) {
                NavigationStack {
                    GapAnalysisView()
                }
            }
            .sheet(isPresented: $showDuplicates) {
                NavigationStack {
                    DuplicateDocumentsView()
                        .environmentObject(viewModel)
                }
            }
            .sheet(isPresented: $showExpiring) {
                NavigationStack {
                    ExpiringDocumentsSheet(documents: viewModel.expiringDocuments)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 2 {
                    navigationPath = NavigationPath()
                }
            }
            .onChange(of: selectedMemberId) { _, newValue in
                if let memberId = newValue {
                    Analytics.track(.documentFilterChanged, ["filter": "family_member", "member_id": memberId.uuidString])
                }
                viewModel.filterFamilyMemberId = newValue
            }
        }
    }

    // MARK: - Family Member Scroller

    private func arrivalChecklistProgress(for member: FamilyMemberRow) -> (completed: Int, total: Int) {
        let items = NewArrivalChecklist.items(babyName: member.firstName)
        let key = "arrivalChecklist_\(member.id.uuidString)"
        let saved = UserDefaults.standard.string(forKey: key) ?? ""
        let completedIds = Set(saved.split(separator: ",").map(String.init))
        let existingCategories = Set(viewModel.documents.map(\.category))
        let completed = items.filter { item in
            if let cat = item.documentCategory, existingCategories.contains(cat) { return true }
            return completedIds.contains(item.id)
        }.count
        return (completed, items.count)
    }

    private var familyMemberScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) { selectedMemberId = nil }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(selectedMemberId == nil ? HavenColors.navy800 : HavenColors.beige300)
                                .frame(width: 52, height: 52)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(selectedMemberId == nil ? .white : HavenColors.textSecondary)
                        }
                        Text("All")
                            .font(.system(size: 11, weight: selectedMemberId == nil ? .semibold : .medium))
                            .foregroundStyle(selectedMemberId == nil ? HavenColors.navy800 : HavenColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                ForEach(viewModel.familyMembers.sortedByAge()) { member in
                    Button {
                        Haptics.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMemberId = selectedMemberId == member.id ? nil : member.id
                        }
                    } label: {
                        FamilyAvatarView(
                            member: member,
                            size: 52,
                            showName: true,
                            isSelected: selectedMemberId == member.id
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Manage button
                NavigationLink {
                    FamilyMembersView()
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(HavenColors.beige300, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                .frame(width: 52, height: 52)
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Text("Manage")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .frame(width: 60)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Empty Vault (warm, inviting)

    private var emptyVaultContent: some View {
        VStack(spacing: HavenTheme.spacing20) {
            // Empty state prompt — tappable to trigger upload
            Button {
                Haptics.light()
                uploadCategory = nil
                showUpload = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Start building your vault")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Tap here to upload your first document. Alfred will organize it automatically.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 40)
            .padding(.bottom, 20)

            if !viewModel.suggestedNextUploads.isEmpty {
                suggestedUploadsSection
            }
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.top, HavenTheme.spacing8)
        .padding(.bottom, HavenTheme.spacing32)
    }

    // MARK: - Document List (main layout)

    private var documentListContent: some View {
        LazyVStack(spacing: HavenTheme.spacing16) {
            // 1. Compact Estate Readiness
            compactReadinessCard

            // Expecting members — preparation checklists
            let expectingMembers = viewModel.familyMembers.filter { $0.isExpecting == true }
            ForEach(expectingMembers) { member in
                NavigationLink {
                    NewArrivalChecklistView(member: member, documents: viewModel.documents)
                } label: {
                    NewArrivalSummaryCard(
                        member: member,
                        completedCount: arrivalChecklistProgress(for: member).completed,
                        totalCount: arrivalChecklistProgress(for: member).total
                    )
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                    .havenShadow()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, HavenTheme.spacing16)
            }

            // Re-tag progress
            if viewModel.isRetagging, let progress = viewModel.retagProgress {
                HStack(spacing: 10) {
                    ProgressView().tint(HavenColors.navy)
                    Text(progress)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, HavenTheme.spacing16)
            }

            // 3a. Duplicate detection status
            if viewModel.duplicateService.hasDuplicates {
                duplicatesFoundBanner
            } else if viewModel.duplicateService.scanComplete && viewModel.totalDocumentCount > 0 {
                noDuplicatesBanner
            }

            // 3c. Expiring alert
            if !viewModel.expiringDocuments.isEmpty {
                Button { showExpiring = true } label: { expiringAlert }
                    .buttonStyle(.plain)
            }

            // 4. Active filters
            if viewModel.hasActiveFilters {
                filterBar
            }

            // 5. Smart Suggestions (if there are missing docs)
            if !viewModel.suggestedNextUploads.isEmpty && !viewModel.isFirstTimeUser {
                suggestedUploadsSection
            }

            // 6. First-time: simplified view
            if viewModel.isFirstTimeUser && viewModel.suggestedNextUploads.isEmpty == false {
                // Just show suggestions + browse all link (already above)
            } else {
                // 7. Category sections (collapsed by default)
                ForEach(viewModel.relevantSectionGroups, id: \.0) { groupName, categories in
                    sectionGroupView(groupName: groupName, categories: categories)
                }

                if viewModel.hasHiddenGroups {
                    Button {
                        withAnimation { viewModel.showAllCategories.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.showAllCategories ? "Show fewer categories" : "View all categories")
                                .font(HavenTypography.uiLabelSmall)
                            Image(systemName: viewModel.showAllCategories ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }

            if !viewModel.isFirstTimeUser {
                if !viewModel.uncategorizedDocuments.isEmpty {
                    uncategorizedSection
                }
            }

            // Browse all for first-time users
            if viewModel.isFirstTimeUser {
                browseAllCategoriesButton
            }
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .padding(.top, HavenTheme.spacing8)
        .padding(.bottom, HavenTheme.spacing32)
    }

    // MARK: - Compact Readiness Card

    private var compactReadinessCard: some View {
        NavigationLink {
            ReadinessDetailView()
                .environmentObject(viewModel)
        } label: {
            CompletionScorecard(vaultViewModel: viewModel)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HavenTheme.spacing16)
    }

    // MARK: - Smart Suggestions

    private var suggestedUploadsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("SUGGESTED NEXT STEPS")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.leading, HavenTheme.spacing4)

            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.suggestedNextUploads) { suggestion in
                    Button {
                        Haptics.light()
                        uploadCategory = suggestion.category
                        showUpload = true
                    } label: {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.category.rawValue)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(suggestion.reason)
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer()

                            Text("Upload")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy800)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()

            if viewModel.isFirstTimeUser {
                browseAllCategoriesLink
            }
        }
    }

    private var browseAllCategoriesLink: some View {
        HStack {
            Spacer()
            NavigationLink {
                allCategoriesListView
            } label: {
                HStack(spacing: 4) {
                    Text("View all categories")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy700)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                }
            }
            Spacer()
        }
    }

    private var browseAllCategoriesButton: some View {
        NavigationLink {
            allCategoriesListView
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("Browse All Categories")
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(HavenColors.navy700)
                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Categories List (for first-time users)

    private var allCategoriesListView: some View {
        ScrollView {
            LazyVStack(spacing: HavenTheme.spacing16) {
                ForEach(viewModel.sectionGroups, id: \.0) { groupName, categories in
                    sectionGroupView(groupName: groupName, categories: categories)
                }
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, HavenTheme.spacing8)
        }
        .navigationTitle("All Categories")
        .background(HavenColors.background)
    }

    // MARK: - Expiring Alert

    private var expiringAlert: some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(Color.havenWarning)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.expiringDocuments.count) document\(viewModel.expiringDocuments.count == 1 ? "" : "s") expiring soon")
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                    Text("Review and renew before they expire")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(HavenColors.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, HavenTheme.spacing16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.expiringDocuments.count) documents expiring soon. Tap to review.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Filters

    private var filterBar: some View {
        HStack {
            if viewModel.filterCategory != nil {
                filterChip(label: viewModel.filterCategory!.rawValue) {
                    Haptics.light()
                    viewModel.filterCategory = nil
                }
            }
            if let status = viewModel.filterStatus {
                filterChip(label: status.capitalized) {
                    Haptics.light()
                    viewModel.filterStatus = nil
                }
            }
            if let memberId = viewModel.filterFamilyMemberId,
               let member = viewModel.familyMembers.first(where: { $0.id == memberId }) {
                filterChip(label: "\(member.firstName) \(member.lastName)") {
                    Haptics.light()
                    viewModel.filterFamilyMemberId = nil
                }
            }
            Spacer()
            Button("Clear All") {
                Haptics.light()
                viewModel.clearFilters()
            }
            .font(HavenTypography.caption)
        }
    }

    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: HavenTheme.spacing4) {
            Text(label)
                .font(HavenTypography.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .accessibilityLabel("Remove \(label) filter")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(HavenColors.navy.opacity(0.12))
        .foregroundStyle(HavenColors.navy)
        .clipShape(Capsule())
    }

    // MARK: - Section Groups

    private func sectionGroupView(groupName: String, categories: [(DocumentCategory, [DocumentRow])]) -> some View {
        let totalDocs = categories.reduce(0) { $0 + $1.1.count }
        let filledCats = categories.filter { !$0.1.isEmpty }.count
        let hasVaultLocked = categories.flatMap(\.1).contains { $0.vaultLocked == true }

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.light()
                withAnimation(HavenTheme.animationStandard) {
                    if expandedSections.contains(groupName) {
                        expandedSections.remove(groupName)
                    } else {
                        expandedSections.insert(groupName)
                    }
                }
            } label: {
                HStack {
                    // Progress indicator
                    if filledCats > 0 {
                        ZStack {
                            Circle()
                                .stroke(HavenColors.beige300, lineWidth: 2.5)
                            Circle()
                                .trim(from: 0, to: Double(filledCats) / Double(max(categories.count, 1)))
                                .stroke(
                                    filledCats == categories.count ? HavenColors.success : HavenColors.navy700,
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            if filledCats == categories.count {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(HavenColors.success)
                            }
                        }
                        .frame(width: 20, height: 20)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(groupName.uppercased())
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        if totalDocs > 0 {
                            Text("\(totalDocs) doc\(totalDocs == 1 ? "" : "s") \u{2022} \(filledCats)/\(categories.count) categories")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("\(categories.count) categories")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary.opacity(0.7))
                        }
                    }
                    Spacer()

                    if hasVaultLocked {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.havenWarning)
                    }

                    if totalDocs > 0 {
                        Text("\(totalDocs)")
                            .font(HavenTypography.badgeLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.navy.opacity(0.12))
                            .foregroundStyle(HavenColors.navy)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                        .rotationEffect(.degrees(expandedSections.contains(groupName) ? 90 : 0))
                }
                .padding(.vertical, HavenTheme.spacing12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(groupName)
            .accessibilityHint(expandedSections.contains(groupName) ? "Collapse section" : "Expand section")

            if expandedSections.contains(groupName) {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(categories, id: \.0) { category, docs in
                        if !docs.isEmpty {
                            NavigationLink {
                                DocumentCategoryView(category: category)
                                    .environmentObject(viewModel)
                            } label: {
                                categoryRow(category: category, docs: docs)
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Soft prompt for empty categories
                            Button {
                                Haptics.light()
                                uploadCategory = category
                                showUpload = true
                            } label: {
                                emptyCategoryRow(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, HavenTheme.spacing4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    private func categoryRow(category: DocumentCategory, docs: [DocumentRow]) -> some View {
        let hasVaultLocked = docs.contains { $0.vaultLocked == true }

        return HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.havenSuccess)
                .font(.body)
                .accessibilityHidden(true)

            Text(category.rawValue)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textPrimary)

            if hasVaultLocked {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.havenWarning)
                    .accessibilityLabel("Contains vault locked document")
            }

            Spacer()

            Text("\(docs.count)")
                .font(HavenTypography.badgeLabel)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(HavenColors.navy.opacity(0.12))
                .foregroundStyle(HavenColors.navy)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(HavenColors.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(docs.count) documents\(hasVaultLocked ? ", contains vault locked document" : "")")
    }

    private func emptyCategoryRow(category: DocumentCategory) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            if viewModel.dismissedCategories.contains(category.rawValue) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(HavenColors.textTertiary.opacity(0.4))
                    .font(.body)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(HavenColors.textTertiary.opacity(0.5))
                    .font(.body)
            }

            Text(category.rawValue)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textTertiary)
                .strikethrough(viewModel.dismissedCategories.contains(category.rawValue))

            Spacer()

            if viewModel.dismissedCategories.contains(category.rawValue) {
                Text("N/A")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            } else {
                Text("Upload")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.navy700.opacity(0.6))
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            if viewModel.dismissedCategories.contains(category.rawValue) {
                Button {
                    Task { await viewModel.undismissCategory(category.rawValue) }
                } label: {
                    Label("Mark as Applicable", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    Haptics.light()
                    uploadCategory = category
                    showUpload = true
                } label: {
                    Label("Upload Document", systemImage: "doc.badge.plus")
                }

                Button {
                    Task { await viewModel.dismissCategory(category.rawValue) }
                } label: {
                    Label("Not Applicable to Me", systemImage: "minus.circle")
                }
            }
        }
        .accessibilityLabel(
            viewModel.dismissedCategories.contains(category.rawValue)
                ? "\(category.rawValue), marked as not applicable. Long press to change."
                : "\(category.rawValue), not yet uploaded. Tap to upload, or long press for options."
        )
    }

    // MARK: - Uncategorized Section

    private var uncategorizedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNCATEGORIZED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("\(viewModel.uncategorizedDocuments.count) doc\(viewModel.uncategorizedDocuments.count == 1 ? "" : "s") need categorization")
                        .font(HavenTypography.caption)
                        .foregroundStyle(Color.havenWarning)
                }
                Spacer()
                Image(systemName: "questionmark.folder")
                    .font(.title3)
                    .foregroundStyle(Color.havenWarning)
            }
            .padding(.vertical, HavenTheme.spacing12)

            VStack(spacing: HavenTheme.spacing8) {
                ForEach(viewModel.uncategorizedDocuments) { doc in
                    uncategorizedDocRow(doc)
                }
            }
            .padding(.leading, HavenTheme.spacing4)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    // MARK: - Recently Deleted

    private var recentlyDeletedView: some View {
        List {
            if viewModel.deletedDocuments.isEmpty {
                Text("No recently deleted documents.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.deletedDocuments) { doc in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title)
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(1)
                            Text(doc.category)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                        Button {
                            Haptics.light()
                            Task { await viewModel.restoreDocument(doc) }
                        } label: {
                            Text("Restore")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy800)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.permanentlyDeleteDocument(doc) }
                        } label: {
                            Label("Delete Forever", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.background)
        .navigationTitle("Recently Deleted")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func uncategorizedDocRow(_ doc: DocumentRow) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "doc.questionmark")
                .foregroundStyle(Color.havenWarning)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(doc.category)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Spacer()

            if analyzingDocId == doc.id {
                ProgressView()
                    .tint(HavenColors.navy800)
            } else {
                Button {
                    Haptics.light()
                    analyzingDocId = doc.id
                    Task {
                        await viewModel.reanalyzeDocument(doc)
                        analyzingDocId = nil
                    }
                } label: {
                    Text("Analyze")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy800)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                }

                Button {
                    Haptics.light()
                    Task { await viewModel.deleteDocumentWithFile(doc) }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(HavenColors.critical)
                        .padding(8)
                }
                .accessibilityLabel("Delete \(doc.title)")
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    // MARK: - Duplicate Detection Banners

    private var duplicatesFoundBanner: some View {
        Button {
            Analytics.track(.duplicateDocumentsViewed, ["duplicate_count": viewModel.duplicateService.totalDuplicateCount])
            showDuplicates = true
        } label: {
            HavenCard {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.title3)
                        .foregroundStyle(Color.havenWarning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.duplicateService.totalDuplicateCount) duplicate\(viewModel.duplicateService.totalDuplicateCount == 1 ? "" : "s") found")
                            .font(HavenTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Tap to review and clean up")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HavenTheme.spacing16)
    }

    private var noDuplicatesBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color.havenSuccess)
            Text("No duplicate documents found")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, HavenTheme.spacing16)
    }
}

// MARK: - Expiring Documents Sheet

private struct ExpiringDocumentsSheet: View {
    let documents: [DocumentRow]
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        List {
            Section {
                Text("These documents expire within the next 30 days. Review and renew them to stay current.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(documents) { doc in
                NavigationLink {
                    DocumentDetailView(documentID: doc.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(Color.havenWarning)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                            Text(doc.category)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        Spacer()

                        if let expStr = doc.expirationDate,
                           let date = dateFormatter.date(from: expStr) {
                            Text(date, style: .date)
                                .font(HavenTypography.caption)
                                .foregroundStyle(Color.havenWarning)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Expiring Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

/// Applies `.searchable` only when `isActive` is true. Used so the Family
/// sub-tab of `DocumentVaultView` doesn't render a "Search documents..." bar
/// (which competes with the Family hub's content for vertical space and is
/// irrelevant on that tab).
private struct ConditionalSearchable: ViewModifier {
    let isActive: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if isActive {
            content.searchable(text: $text, prompt: "Search documents...")
        } else {
            content
        }
    }
}

#Preview {
    DocumentVaultView()
}
