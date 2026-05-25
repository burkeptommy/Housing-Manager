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
/// Behavior matches Apple Mail / Things 3:
///   - Drag right past threshold → leading action (Complete, green)
///   - Drag left past threshold → trailing action (Archive, gray)
///   - Below threshold on release → spring back to 0
///   - Past threshold on release → snap to fully-revealed action +
///     fire callback
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

    /// How far the finger must drag before the action background
    /// reveals "ready to commit." Below this, release springs back
    /// to zero with no action. Above, release commits.
    private let actionThreshold: CGFloat = 80
    /// Maximum visible action width (the background fully reveals).
    private let actionRevealWidth: CGFloat = 100
    /// Resistance multiplier past threshold so the row "stops"
    /// pulling along with the finger — communicates the commit edge.
    private let pastThresholdResistance: CGFloat = 0.35

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
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { value in
                guard !isAnimating else { return }
                // Ignore mostly-vertical drags so scroll keeps working.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                let raw = value.translation.width
                // Past threshold: resist so the row visually "locks."
                let bounded: CGFloat
                if abs(raw) <= actionThreshold {
                    bounded = raw
                } else {
                    let over = abs(raw) - actionThreshold
                    let dampened = actionThreshold + (over * pastThresholdResistance)
                    bounded = raw < 0 ? -dampened : dampened
                }
                offset = bounded

                // Haptic on threshold cross.
                let direction: HapticDirection
                if offset > actionThreshold { direction = .leading }
                else if offset < -actionThreshold { direction = .trailing }
                else { direction = .none }
                if direction != lastHapticDirection, direction != .none {
                    Haptics.light()
                }
                lastHapticDirection = direction
            }
            .onEnded { value in
                let final = value.translation.width
                if final >= actionThreshold {
                    commit(.complete)
                } else if final <= -actionThreshold {
                    commit(.archive)
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
