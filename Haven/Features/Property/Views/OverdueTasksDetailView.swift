import SwiftUI

struct OverdueTasksDetailView: View {
    let tasks: [MaintenanceTaskDBRow]
    let systemNameLookup: (UUID?) -> String?
    let propertyAddress: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Summary
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.critical)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(tasks.count) Overdue Task\(tasks.count == 1 ? "" : "s")")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("These tasks are past their scheduled date.")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.critical.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))

                // Task list
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(HavenColors.critical)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(HavenColors.textPrimary)

                            HStack(spacing: 8) {
                                if let systemName = systemNameLookup(task.systemId) {
                                    Text(systemName)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }

                                Text(task.frequency)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }

                            Text("Due: \(task.nextDueDate.havenDateShort)")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.critical)

                            if let costRange = task.costRange {
                                Text("Est. \(costRange)")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .havenShadow()
                }

                // Scenario prompt
                Button {
                    Haptics.light()
                    let prompt = "What if I don't address the \(tasks.count) overdue maintenance items on my property at \(propertyAddress)? What are the risks?"
                    NotificationCenter.default.post(
                        name: .openScenarioStudio,
                        object: nil,
                        userInfo: ["query": prompt]
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("What could go wrong if I skip these?")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.critical)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HavenColors.critical.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle("Overdue Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("OverdueTasksDetailView", properties: ["task_count": tasks.count])
    }
}
