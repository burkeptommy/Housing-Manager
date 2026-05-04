import SwiftUI

/// Phase 95 (audit gap #61) — lightweight "quick question to my
/// Chez specialist" composer.
///
/// `ChezRequestComposeSheet` is the canonical full-form path:
/// category picker, summary, description, attachments,
/// 1-business-day SLA caption. For "I just want to ask something
/// fast" that's heavyweight. This sheet is one textarea + Send,
/// submits as `category: .general` with the body doubling as both
/// summary (first 80 chars) and description, and lands in the same
/// `chez_requests` thread infrastructure so the admin queue sees
/// it like any other request.
///
/// Reuses `ChezRequestComposeViewModel.submit()` so the analytics
/// + push + admin email backstop stays identical to the canonical
/// path. Difference is purely UI: less to type, no decisions to
/// make.
struct ChezQuickQuestionSheet: View {
    @StateObject private var viewModel: ChezRequestComposeViewModel
    @Environment(\.dismiss) private var dismiss
    var onSent: (() -> Void)? = nil

    @State private var bodyText: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(contextHints: [String: String] = [:], onSent: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: ChezRequestComposeViewModel(
                category: .general,
                contextHints: contextHints,
                isCategoryFixed: true
            )
        )
        self.onSent = onSent
    }

    private var canSubmit: Bool {
        !isSubmitting
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                heroCard
                editor
                if let errorMessage {
                    Text(errorMessage)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.critical)
                }
                Spacer(minLength: 0)
                HavenButton(
                    title: isSubmitting ? "Sending..." : "Send to Chez",
                    action: { Task { await submit() } },
                    icon: "paperplane.fill",
                    isLoading: isSubmitting,
                    isDisabled: !canSubmit
                )
            }
            .padding(HavenTheme.pageMargin)
            .background(HavenColors.background)
            .navigationTitle("Quick question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var heroCard: some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ask anything")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("One sentence is fine. Chez replies within one business day; faster for anything tagged urgent.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
            Text("YOUR MESSAGE")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            TextEditor(text: $bodyText)
                .font(HavenTypography.body)
                .frame(minHeight: 180)
                .padding(HavenTheme.spacing8)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.border, lineWidth: 1)
                )
        }
    }

    @MainActor
    private func submit() async {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        // Phase 95 — derive a one-line summary from the first 80
        // chars of the body. Same body persists as `description`
        // so the admin sees the full text in the focused panel.
        viewModel.summary = String(trimmed.prefix(80))
        viewModel.description = trimmed

        await viewModel.submit()
        if viewModel.didSucceed {
            Analytics.track(.chezQuickQuestionSent, [:])
            onSent?()
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Couldn't send right now. Try again in a moment."
        }
    }
}
