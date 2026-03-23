import SwiftUI

struct RequiresAttentionSection: View {
    let expirations: [ExpirationItem]
    let upcomingTasks: [MaintenanceTaskDBRow]
    @State private var selectedTask: MaintenanceTaskDBRow?

    private var combinedItems: [AttentionItem] {
        var items: [AttentionItem] = []

        // Add expirations
        for exp in expirations {
            items.append(AttentionItem(
                id: exp.id,
                sourceId: exp.sourceId,
                title: exp.title,
                subtitle: exp.type.capitalized,
                icon: exp.icon,
                urgencyColor: exp.urgencyColor,
                daysRemaining: exp.daysRemaining,
                kind: .expiration(exp.type)
            ))
        }

        // Add upcoming maintenance (next 14 days, not overdue)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date.now
        let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now

        for task in upcomingTasks {
            guard let date = formatter.date(from: task.nextDueDate),
                  date >= now && date <= twoWeeks else { continue }
            let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
            items.append(AttentionItem(
                id: UUID(),
                sourceId: nil,
                title: task.title,
                subtitle: "Maintenance",
                icon: "wrench.and.screwdriver.fill",
                urgencyColor: days <= 3 ? HavenColors.critical : days <= 7 ? HavenColors.warning : HavenColors.info,
                daysRemaining: days,
                kind: .maintenance(task)
            ))
        }

        // Sort by urgency (most urgent first) and cap at 3
        return Array(items.sorted { $0.daysRemaining < $1.daysRemaining }.prefix(3))
    }

    var body: some View {
        if combinedItems.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("REQUIRES ATTENTION")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                VStack(spacing: 0) {
                    ForEach(Array(combinedItems.enumerated()), id: \.element.id) { index, item in
                        Group {
                            switch item.kind {
                            case .expiration(let type):
                                if type == "document", let docId = item.sourceId {
                                    NavigationLink {
                                        DocumentDetailView(documentID: docId)
                                    } label: {
                                        attentionRow(item)
                                    }
                                    .buttonStyle(.plain)
                                } else if type == "warranty" {
                                    Button {
                                        NotificationCenter.default.post(
                                            name: .switchToTab,
                                            object: nil,
                                            userInfo: ["tab": 1]
                                        )
                                    } label: {
                                        attentionRow(item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    attentionRow(item)
                                }

                            case .maintenance(let task):
                                Button {
                                    Haptics.light()
                                    selectedTask = task
                                } label: {
                                    attentionRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if index < combinedItems.count - 1 {
                            Divider()
                                .padding(.leading, 32)
                                .overlay(HavenColors.beige200)
                        }
                    }
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .havenShadow()
            }
            .sheet(item: $selectedTask) { task in
                NavigationStack {
                    MaintenanceTaskDetailSheet(task: task)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func attentionRow(_ item: AttentionItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundStyle(item.urgencyColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Spacer()

            Text(urgencyLabel(item.daysRemaining))
                .font(HavenTypography.uiLabelSmall)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.urgencyColor.opacity(0.12))
                .foregroundStyle(item.urgencyColor)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func urgencyLabel(_ days: Int) -> String {
        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days)d"
    }
}

// MARK: - Attention Item Model

private struct AttentionItem: Identifiable {
    let id: UUID
    let sourceId: UUID?
    let title: String
    let subtitle: String
    let icon: String
    let urgencyColor: Color
    let daysRemaining: Int
    let kind: AttentionKind
}

private enum AttentionKind {
    case expiration(String)  // carries the type: "document" or "warranty"
    case maintenance(MaintenanceTaskDBRow)
}
