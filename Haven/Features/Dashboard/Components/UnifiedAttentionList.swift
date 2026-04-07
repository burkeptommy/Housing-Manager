import SwiftUI

// MARK: - Attention Item Model

struct AttentionItem: Identifiable {
    let id: UUID
    let sourceId: UUID?
    let title: String
    let subtitle: String
    let icon: String
    let urgencyColor: Color
    let daysRemaining: Int
    let kind: AttentionKind
    let priority: String?
    let assignedName: String?

    init(id: UUID, sourceId: UUID? = nil, title: String, subtitle: String, icon: String,
         urgencyColor: Color, daysRemaining: Int, kind: AttentionKind,
         priority: String? = nil, assignedName: String? = nil) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.urgencyColor = urgencyColor
        self.daysRemaining = daysRemaining
        self.kind = kind
        self.priority = priority
        self.assignedName = assignedName
    }
}

enum AttentionKind {
    case expiration(String)  // carries the type: "document" or "warranty"
    case maintenance(MaintenanceTaskDBRow)
    case vehicleAlert
    case estateNudge
}

// MARK: - Unified Attention List

struct UnifiedAttentionList: View {
    let items: [AttentionItem]
    let onItemTapped: (AttentionItem) -> Void
    var onSeeAll: (() -> Void)?
    var onDeleteTask: ((MaintenanceTaskDBRow) -> Void)?

    @State private var selectedTask: MaintenanceTaskDBRow?

    var body: some View {
        if items.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack {
                    Text("NEEDS YOUR ATTENTION")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    Spacer()

                    if items.count > 3 {
                        Button {
                            Haptics.light()
                            onSeeAll?()
                        } label: {
                            Text("See all (\(items.count))")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy500)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        itemView(item)

                        if index < min(items.count, 3) - 1 {
                            Divider()
                                .overlay(HavenColors.beige200)
                                .padding(.horizontal, HavenTheme.spacing12)
                        }
                    }
                }
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

    @ViewBuilder
    private func itemView(_ item: AttentionItem) -> some View {
        let row = attentionRow(item)

        switch item.kind {
        case .expiration(let type):
            if type == "document", let docId = item.sourceId {
                NavigationLink {
                    DocumentDetailView(documentID: docId)
                } label: { row }
                .buttonStyle(.plain)
            } else if type == "warranty" {
                Button {
                    Haptics.light()
                    Analytics.track(.unifiedAttentionItemTapped, ["kind": "warranty"])
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                } label: { row }
                .buttonStyle(.plain)
            } else {
                row
            }

        case .maintenance(let task):
            Button {
                Haptics.light()
                Analytics.track(.unifiedAttentionItemTapped, ["kind": "maintenance"])
                selectedTask = task
            } label: { row }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    Haptics.medium()
                    onDeleteTask?(task)
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }

        case .vehicleAlert:
            Button {
                Haptics.light()
                Analytics.track(.unifiedAttentionItemTapped, ["kind": "vehicle"])
                onItemTapped(item)
            } label: { row }
            .buttonStyle(.plain)

        case .estateNudge:
            Button {
                Haptics.light()
                Analytics.track(.unifiedAttentionItemTapped, ["kind": "estate"])
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
            } label: { row }
            .buttonStyle(.plain)
        }
    }

    private func attentionRow(_ item: AttentionItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            // Urgency dot
            Circle()
                .fill(item.urgencyColor)
                .frame(width: 8, height: 8)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)

                // Metadata row: assignee + priority
                HStack(spacing: 8) {
                    if let name = item.assignedName, !name.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                            Text(name)
                                .font(HavenTypography.uiCaption)
                        }
                        .foregroundStyle(HavenColors.textSecondary)
                    }

                    if let priority = item.priority, !priority.isEmpty {
                        Text(priority.capitalized)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(priorityColor(priority))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(priority).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, HavenTheme.spacing12)
        .contentShape(Rectangle())
    }

    private func urgencyLabel(_ days: Int) -> String {
        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days)d"
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return HavenColors.critical
        case "medium": return HavenColors.warning
        case "low": return Color(red: 0.40, green: 0.55, blue: 0.42)
        default: return HavenColors.textTertiary
        }
    }
}
