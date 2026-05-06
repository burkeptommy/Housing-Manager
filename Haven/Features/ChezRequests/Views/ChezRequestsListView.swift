import SwiftUI

/// Phase 80 — The 4th Inbox sub-tab. A scrollable list of every Chez
/// request the homeowner has ever submitted, sectioned into Active and
/// Past. Empty state explains where the entry-point button lives.
///
/// Designed to be embedded inside `InboxView` when `filter == .chez`,
/// not a top-level NavigationStack — InboxView already provides one.
struct ChezRequestsListView: View {
    @StateObject private var viewModel = ChezRequestsViewModel()
    @State private var showResolved: Bool = false
    /// Phase 95 (gap #61) — drives the lightweight quick-question
    /// composer. Distinct from the full `.openChezRequestComposer`
    /// notification path which opens the multi-section form.
    @State private var showQuickQuestion: Bool = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if viewModel.requests.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezRequestChanged)) { _ in
            Task { await viewModel.load() }
        }
        .trackScreen("ChezRequestsListView")
        .sheet(isPresented: $showQuickQuestion) {
            ChezQuickQuestionSheet {
                Task { await viewModel.load() }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - List

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroIntro
                if !viewModel.activeRequests.isEmpty {
                    activeSection
                }
                if !viewModel.pastRequests.isEmpty {
                    pastSection
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, 16)
        }
        .background(HavenColors.background.ignoresSafeArea())
    }

    private var heroIntro: some View {
        VStack(spacing: HavenTheme.spacing8) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chez Home Manager")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Your concierge for vendors, quotes, and follow-ups.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
            }
            // Phase 95 (gap #61) — quick-question entry. Distinct
            // from the multi-section "+" composer; one tap → one
            // textarea → send. Keeps the formal request thread
            // infrastructure underneath but feels like a chat.
            Button {
                Haptics.selection()
                showQuickQuestion = true
            } label: {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Ask a quick question")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing12)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        )
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ACTIVE")
            ForEach(viewModel.activeRequests) { req in
                NavigationLink {
                    ChezRequestDetailView(requestId: req.id)
                } label: {
                    ChezRequestRowCard(request: req)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showResolved.toggle() }
            } label: {
                HStack {
                    Text("RESOLVED · \(viewModel.pastRequests.count)")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Image(systemName: showResolved ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            if showResolved {
                ForEach(viewModel.pastRequests) { req in
                    NavigationLink {
                        ChezRequestDetailView(requestId: req.id)
                    } label: {
                        ChezRequestRowCard(request: req)
                            .opacity(0.85)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
    }

    // MARK: - Empty + Loading

    private var loadingState: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard(lineCount: 2)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(spacing: 8) {
                Text("Need a hand?")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Whenever you're finding a vendor, getting a quote, scheduling a visit, or coordinating a task. Tap the \"Have Chez handle this\" button anywhere in the app, and Chez takes it from there.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button {
                Haptics.light()
                NotificationCenter.default.post(
                    name: .openChezRequestComposer,
                    object: nil,
                    userInfo: [
                        "category": ChezCategory.general.rawValue,
                        "context": [String: String]()
                    ]
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Ask Chez")
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HavenColors.action)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
