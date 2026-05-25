import SwiftUI

/// Phase F2 (MaintenanceScheduleView parity): leading + trailing swipe
/// actions for cards rendered outside of a `List`. SwiftUI's native
/// `.swipeActions` only works inside `List`; Tasks v2 uses
/// `LazyVStack` of cards so we need a custom gesture.
///
/// Behavior matches Apple Mail / Things 3:
///   - Drag right past threshold → leading action (Complete, green)
///   - Drag left past threshold → trailing action (Snooze, amber)
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
    let onSnooze: () -> Void
    let completeLabel: String
    let snoozeLabel: String
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
    private enum CommittedAction { case none, complete, snooze }

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
            ZStack {
                Rectangle().fill(HavenColors.warning)
                actionLabel(symbol: "moon.zzz.fill", text: snoozeLabel)
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
                    commit(.snooze)
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
        // row (mark complete archives; snooze advances the date) so
        // the slide-out feels native.
        withAnimation(.easeInOut(duration: 0.22)) {
            offset = action == .complete ? actionRevealWidth * 6 : -actionRevealWidth * 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            switch action {
            case .complete: onComplete()
            case .snooze: onSnooze()
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
    /// Apply leading (Complete) + trailing (Snooze) swipe actions to a
    /// row rendered outside a List. See `SwipeActionRow` for behavior.
    func swipeRowActions(
        completeLabel: String = "Complete",
        snoozeLabel: String = "Snooze",
        onComplete: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) -> some View {
        SwipeActionRow(
            onComplete: onComplete,
            onSnooze: onSnooze,
            completeLabel: completeLabel,
            snoozeLabel: snoozeLabel
        ) {
            self
        }
    }
}
