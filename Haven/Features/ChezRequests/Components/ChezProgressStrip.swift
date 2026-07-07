import SwiftUI

/// Wave 6 — "What Chez is doing" progress timeline. A compact,
/// homeowner-safe strip that sits under the request header: a one-line
/// headline ("Chez called 3 vendors · 2 quotes in") with a soft pulsing
/// dot while the request is open, expandable into the full step
/// timeline. Labels never expose vendor names from the private call
/// ledger. Loads its own data and renders nothing on failure or when
/// there's nothing worth showing (zero-noise degradation), so wiring it
/// in is a single line.
struct ChezProgressStrip: View {
    let requestId: UUID
    /// True while the request is not yet resolved — drives the pulsing
    /// "still working" accent dot.
    var isActive: Bool = true

    @State private var progress: ChezRequestProgress?
    @State private var expanded = false
    @State private var pulse = false

    var body: some View {
        Group {
            if let progress, progress.hasContent {
                content(progress)
            } else {
                EmptyView()
            }
        }
        .task(id: requestId) { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezRequestChanged)) { _ in
            Task { await load() }
        }
    }

    private func content(_ progress: ChezRequestProgress) -> some View {
        VStack(alignment: .leading, spacing: expanded ? 12 : 0) {
            Button {
                withAnimation(HavenTheme.animationStandard) { expanded.toggle() }
                if expanded {
                    Haptics.selection()
                    Analytics.track(.chezProgressExpanded, ["request_id": requestId.uuidString])
                }
            } label: {
                HStack(spacing: 10) {
                    accentDot
                    Text(progress.headline ?? "Chez is on it")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if !progress.steps.isEmpty {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if expanded {
                timeline(progress.steps)
            }
        }
        .padding(14)
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

    private var accentDot: some View {
        Circle()
            .fill(isActive ? HavenColors.action : HavenColors.success)
            .frame(width: 8, height: 8)
            .opacity(isActive ? (pulse ? 0.4 : 1.0) : 1.0)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }

    private func timeline(_ steps: [ChezProgressStep]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        Image(systemName: symbol(for: step.kind))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.action)
                            .frame(width: 20, height: 20)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(HavenColors.beige300)
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.label ?? "")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let at = step.at {
                            Text(Self.relativeDate(at))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .padding(.bottom, index < steps.count - 1 ? 14 : 0)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func symbol(for kind: String?) -> String {
        switch kind {
        case "submitted": return "paperplane.fill"
        case "research": return "sparkles"
        case "outreach": return "phone.fill"
        case "proposal": return "doc.text.fill"
        case "visit_scheduled": return "calendar"
        case "visit_completed": return "checkmark.seal.fill"
        case "resolved": return "checkmark.seal.fill"
        default: return "circle.fill"
        }
    }

    private func load() async {
        do {
            progress = try await HavenSupabase.fetchChezRequestProgress(requestId: requestId)
        } catch {
            // Zero-noise degradation: leave whatever we had (or nothing).
        }
    }

    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
