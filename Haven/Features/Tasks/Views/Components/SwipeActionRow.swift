import SwiftUI

/// Phase F2 + Phase 70.A1 follow-on F5: leading + trailing swipe actions
/// for cards rendered outside of a `List`. SwiftUI's native
/// `.swipeActions` only works inside `List`; Tasks v2 uses
/// `LazyVStack` of cards so we need a custom gesture.
///
/// Phase 70.A1 follow-on F5 swapped the trailing action from "Snooze"
/// (amber moon) to "Archive" (neutral gray archivebox) to match the
/// Apple-notification swipe-left mental model the homeowner asked for.
/// Snooze still exists — it just lives in the MaintenanceTaskDetailSheet
/// actions menu now, where the small minority of users who want
/// "come back later" instead of "out of view" can reach it.
///
/// Phase 70.A1 follow-on F5b (Tom's accidental-archive complaint):
/// asymmetric thresholds + iMessage-style confirmation. Tom was
/// archiving tasks he didn't mean to because (a) vertical scrolls
/// brushed sideways enough to register as a swipe, and (b) swipes past
/// 80pt auto-committed with no confirm step. The fix:
///   - `minimumDistance: 28` (was 14) so a slightly-off-vertical scroll
///     no longer fires the drag.
///   - `width > 1.4 * height` horizontal-dominance gate (was just `>`)
///     so the gesture only fires for clearly-horizontal intent.
///   - `completeThreshold: 80`, `archiveThreshold: 140` — destructive
///     action takes a longer pull, matches Mail / Messages.
///   - `pastThresholdResistance: 0.18` (was 0.35) — past the threshold
///     the row visibly "locks," giving stronger commit-edge feedback.
///   - **Archive shows a confirmationDialog on release past threshold.**
///     The auto-commit is gone for the destructive side. Complete still
///     auto-commits (non-destructive, undo via the existing toast).
///   - Undo toast in the parent view extended 5s → 8s so users who do
///     archive accidentally have more time to undo.
///
/// Behavior matches Apple Mail / Things 3 / Messages:
///   - Drag right past 80pt → leading action (Complete, green, auto-commit)
///   - Drag left past 140pt → trailing action (Archive, gray, confirm dialog)
///   - Below threshold on release → spring back to 0
///   - Light haptic on threshold cross, medium on action commit
///
/// Wrap any row content with `.swipeRowActions(...)`. Tap gestures
/// inside the content keep working because the drag gesture's
/// `minimumDistance` is non-zero.
struct SwipeActionRow<Content: View>: View {
    let onComplete: () -> Void
    let onArchive: () -> Void
    let completeLabel: String
    let archiveLabel: String
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var lastHapticDirection: HapticDirection = .none
    @State private var committedAction: CommittedAction = .none
    @State private var isAnimating = false
    @State private var pendingArchiveConfirmation = false

    /// Right-swipe (Complete, non-destructive) threshold. Below this on
    /// release → spring back. Above → auto-commit.
    private let completeThreshold: CGFloat = 80
    /// Left-swipe (Archive, destructive) threshold. Higher than complete
    /// so the user has to mean it. iMessage-style: above this on
    /// release → confirmation dialog, NOT auto-commit.
    private let archiveThreshold: CGFloat = 140
    /// Maximum visible action width (the background fully reveals).
    private let actionRevealWidth: CGFloat = 100
    /// Resistance multiplier past threshold so the row "stops"
    /// pulling along with the finger — communicates the commit edge.
    /// 0.18 (was 0.35) gives a stronger "lock" feel past the line.
    private let pastThresholdResistance: CGFloat = 0.18
    /// Horizontal-dominance ratio. The drag's horizontal translation
    /// must exceed `horizontalDominanceRatio × vertical translation`
    /// for the gesture to fire. 1.4 (was 1.0) so a slightly-off-vertical
    /// scroll still scrolls.
    private let horizontalDominanceRatio: CGFloat = 1.4

    private enum HapticDirection { case none, leading, trailing }
    private enum CommittedAction { case none, complete, archive }

    var body: some View {
        ZStack {
            actionBackgrounds
            content()
                .background(HavenColors.background)
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .confirmationDialog(
            "Archive this task?",
            isPresented: $pendingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                commit(.archive)
            }
            Button("Cancel", role: .cancel) {
                springBack()
            }
        } message: {
            Text("You can restore archived tasks from the task detail menu.")
        }
    }

    private var actionBackgrounds: some View {
        HStack(spacing: 0) {
            // Leading (revealed by right-swipe → drag offset > 0)
            ZStack {
                Rectangle().fill(HavenColors.success)
                actionLabel(symbol: "checkmark.circle.fill", text: completeLabel)
            }
            .frame(width: max(0, offset))
            .opacity(offset > 0 ? 1 : 0)

            Spacer(minLength: 0)

            // Trailing (revealed by left-swipe → drag offset < 0)
            // Phase 70.A1 follow-on F5: neutral gray archive, not amber
            // snooze. Apple Mail / Notifications pattern — Archive is a
            // neutral "out of view" action, not destructive.
            ZStack {
                Rectangle().fill(Color.gray)
                actionLabel(symbol: "archivebox.fill", text: archiveLabel)
            }
            .frame(width: max(0, -offset))
            .opacity(offset < 0 ? 1 : 0)
        }
    }

    private func actionLabel(symbol: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onChanged { value in
                guard !isAnimating else { return }
                // Strict horizontal-dominance gate. The drag's horizontal
                // translation must beat 1.4× the vertical translation
                // before we register as a swipe. Slightly-off-vertical
                // scrolls keep scrolling.
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                guard horizontal > vertical * horizontalDominanceRatio else { return }

                let raw = value.translation.width
                let threshold = raw >= 0 ? completeThreshold : archiveThreshold
                // Past threshold: resist so the row visually "locks."
                let bounded: CGFloat
                if abs(raw) <= threshold {
                    bounded = raw
                } else {
                    let over = abs(raw) - threshold
                    let dampened = threshold + (over * pastThresholdResistance)
                    bounded = raw < 0 ? -dampened : dampened
                }
                offset = bounded

                // Haptic on threshold cross.
                let direction: HapticDirection
                if offset > completeThreshold { direction = .leading }
                else if offset < -archiveThreshold { direction = .trailing }
                else { direction = .none }
                if direction != lastHapticDirection, direction != .none {
                    Haptics.light()
                }
                lastHapticDirection = direction
            }
            .onEnded { value in
                let final = value.translation.width
                if final >= completeThreshold {
                    // Complete auto-commits — non-destructive, undo
                    // available via the parent's toast.
                    commit(.complete)
                } else if final <= -archiveThreshold {
                    // Archive shows a confirmation dialog instead of
                    // auto-committing. The dialog's Cancel springs back;
                    // the dialog's Archive calls commit(.archive).
                    Haptics.medium()
                    pendingArchiveConfirmation = true
                } else {
                    springBack()
                }
            }
    }

    private func commit(_ action: CommittedAction) {
        committedAction = action
        Haptics.medium()
        isAnimating = true
        // Snap the row off-screen in the direction of commit, then
        // fire the callback. The parent list re-renders without this
        // row (mark complete archives; archive removes from view) so
        // the slide-out feels native.
        withAnimation(.easeInOut(duration: 0.22)) {
            offset = action == .complete ? actionRevealWidth * 6 : -actionRevealWidth * 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            switch action {
            case .complete: onComplete()
            case .archive:  onArchive()
            case .none: break
            }
            // Reset so the row can be re-used if the action didn't
            // actually remove it (rare, e.g. error path).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                offset = 0
                committedAction = .none
                isAnimating = false
                lastHapticDirection = .none
            }
        }
    }

    private func springBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            offset = 0
        }
        lastHapticDirection = .none
    }
}

extension View {
    /// Apply leading (Complete) + trailing (Archive) swipe actions to a
    /// row rendered outside a List. See `SwipeActionRow` for behavior.
    /// Phase 70.A1 follow-on F5: trailing swipe renamed Snooze→Archive
    /// to match the Apple-notification mental model. Snooze relocated
    /// to the task detail sheet's actions menu.
    /// Phase 70.A1 follow-on F5b: archive now requires confirmation
    /// (iMessage-style dialog) instead of auto-committing on release.
    func swipeRowActions(
        completeLabel: String = "Complete",
        archiveLabel: String = "Archive",
        onComplete: @escaping () -> Void,
        onArchive: @escaping () -> Void
    ) -> some View {
        SwipeActionRow(
            onComplete: onComplete,
            onArchive: onArchive,
            completeLabel: completeLabel,
            archiveLabel: archiveLabel
        ) {
            self
        }
    }
}
