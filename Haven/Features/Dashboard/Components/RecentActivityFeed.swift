import SwiftUI

// MARK: - Activity Event Model

enum ActivityEventType: String {
    case taskCompleted
    case documentProcessed
    case systemAdded
    case vendorLinked
    case invoiceProcessed
    case familyMemberJoined
    case propertyAdded
    case vehicleAdded
    case recallDetected
    case scenarioRun
    case inboxItemReceived
    case projectCreated
    case gapAnalysisRun
    case estateDocumentExtracted
}

struct RecentActivityEvent: Identifiable {
    let id: String
    let eventType: ActivityEventType
    let title: String
    let occurredAt: Date
    let icon: String
    let iconColor: Color
    /// The entity ID for navigation (task ID, document ID, contractor ID, system ID).
    let entityId: UUID?

    var subtitle: String {
        occurredAt.havenCompact
    }
}

// MARK: - View

/// Multi-source activity feed for the dashboard.
/// Shows the 7 most recent actionable events. Tappable rows.
struct RecentActivityFeed: View {
    let events: [RecentActivityEvent]
    /// Total event count before truncation, used to decide whether to show
    /// the "View all activity" link.
    var totalEventCount: Int = 0
    var onTap: ((RecentActivityEvent) -> Void)?
    var onViewAll: (() -> Void)?

    var body: some View {
        if events.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                // Addendum Fix 12: header with count pill + View all
                HStack {
                    Text("RECENT")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    Text("\(events.count)")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(HavenColors.beige200)
                        .clipShape(Capsule())

                    Spacer()

                    if totalEventCount > events.count, let onViewAll {
                        Button {
                            Haptics.light()
                            onViewAll()
                        } label: {
                            Text("View all")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.navy700)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 0) {
                    // Addendum Fix 8: group events by day so "Today"
                    // renders once as a header, not seven times per row.
                    let grouped = groupedByDay(events)
                    ForEach(Array(grouped.enumerated()), id: \.offset) { groupIdx, group in
                        if groupIdx > 0 {
                            Divider()
                                .foregroundStyle(HavenColors.beige200)
                                .padding(.leading, 40)
                        }

                        Text(group.label)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.leading, HavenTheme.spacing12)
                            .padding(.top, groupIdx == 0 ? HavenTheme.spacing8 : HavenTheme.spacing12)
                            .padding(.bottom, 2)

                        ForEach(Array(group.events.enumerated()), id: \.element.id) { rowIdx, event in
                            if rowIdx > 0 {
                                Divider()
                                    .foregroundStyle(HavenColors.beige200)
                                    .padding(.leading, 40)
                            }
                            Button {
                                Haptics.light()
                                onTap?(event)
                            } label: {
                                activityRow(event, showDate: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
            }
        }
    }

    private func activityRow(_ event: RecentActivityEvent, showDate: Bool = true) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: event.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(event.iconColor)
                .frame(width: 28, height: 28)
                .background(event.iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(HavenTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                // Addendum Fix 8: when the date is shown as a group
                // header, skip the per-row "Today" subtitle to avoid
                // repeating it 7 times.
                if showDate {
                    Text(event.subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, HavenTheme.spacing12)
        .padding(.horizontal, HavenTheme.spacing12)
        .contentShape(Rectangle())
    }

    /// Addendum Fix 8: group events by day label. Returns an ordered
    /// array of (label, events) pairs matching the input order (most
    /// recent first). The label is "Today", "Yesterday", or "MMM d".
    private func groupedByDay(_ events: [RecentActivityEvent]) -> [(label: String, events: [RecentActivityEvent])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var groups: [(label: String, events: [RecentActivityEvent])] = []
        var current: (label: String, events: [RecentActivityEvent])?

        for event in events {
            let label: String
            if calendar.isDateInToday(event.occurredAt) {
                label = "Today"
            } else if calendar.isDateInYesterday(event.occurredAt) {
                label = "Yesterday"
            } else {
                label = formatter.string(from: event.occurredAt)
            }

            if let existing = current, existing.label == label {
                current?.events.append(event)
            } else {
                if let finished = current { groups.append(finished) }
                current = (label: label, events: [event])
            }
        }
        if let finished = current { groups.append(finished) }
        return groups
    }
}

// MARK: - Icon + Color Helpers

extension ActivityEventType {
    var icon: String {
        switch self {
        case .taskCompleted:            return "checkmark.circle.fill"
        case .documentProcessed:        return "doc.fill"
        case .systemAdded:              return "plus.circle.fill"
        case .vendorLinked:             return "person.badge.plus"
        case .invoiceProcessed:         return "doc.text.magnifyingglass"
        case .familyMemberJoined:       return "person.2.fill"
        case .propertyAdded:            return "house.fill"
        case .vehicleAdded:             return "car.fill"
        case .recallDetected:           return "exclamationmark.triangle.fill"
        case .scenarioRun:              return "sparkles"
        case .inboxItemReceived:        return "envelope.badge.fill"
        case .projectCreated:           return "hammer.fill"
        case .gapAnalysisRun:           return "chart.bar.xaxis"
        case .estateDocumentExtracted:  return "building.columns.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .taskCompleted:            return HavenColors.success
        case .documentProcessed:        return HavenColors.navy700
        case .systemAdded:              return HavenColors.textSecondary
        case .vendorLinked:             return HavenColors.navy700
        case .invoiceProcessed:         return HavenColors.info
        case .familyMemberJoined:       return HavenColors.navy700
        case .propertyAdded:            return HavenColors.navy700
        case .vehicleAdded:             return HavenColors.navy700
        case .recallDetected:           return HavenColors.critical
        case .scenarioRun:              return HavenColors.action
        case .inboxItemReceived:        return HavenColors.warning
        case .projectCreated:           return HavenColors.navy700
        case .gapAnalysisRun:           return HavenColors.info
        case .estateDocumentExtracted:  return HavenColors.navy700
        }
    }
}

// MARK: - Assembly Result

/// Wraps the truncated display list alongside the total pre-truncation count
/// so the dashboard can decide whether to show a "View all activity" link.
struct ActivityAssemblyResult {
    let displayEvents: [RecentActivityEvent]
    let allEvents: [RecentActivityEvent]
    var totalCount: Int { allEvents.count }
}

// MARK: - Assembly Helper

extension RecentActivityFeed {
    /// Assembles recent activity events from multiple dashboard data sources.
    /// Prioritizes actionable events. Takes top 7, deduped by type+title.
    static func assembleEvents(
        tasks: [MaintenanceTaskDBRow],
        documents: [DocumentRow],
        systems: [HomeSystemRow],
        contractors: [ContractorRow],
        vehicles: [VehicleRow] = [],
        inboxItems: [DatabaseService.InboxItemRow] = [],
        properties: [PropertyRow] = [],
        familyMembers: [FamilyMemberRow] = [],
        projects: [PropertyProjectRow]? = nil
        // TODO: Phase 52 -- accept scenarioHistory once a typed Row model exists
    ) -> ActivityAssemblyResult {
        var events: [RecentActivityEvent] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // 1. Task completions (highest value)
        for task in tasks {
            guard let completedStr = task.lastCompletedDate,
                  let date = dateFormatter.date(from: completedStr)
            else { continue }
            events.append(RecentActivityEvent(
                id: "task_\(task.id.uuidString)",
                eventType: .taskCompleted,
                title: "\(task.title) completed",
                occurredAt: date,
                icon: ActivityEventType.taskCompleted.icon,
                iconColor: ActivityEventType.taskCompleted.iconColor,
                entityId: task.id
            ))
        }

        // 2. Document uploads
        for doc in documents {
            guard let uploadedAt = doc.uploadedAt else { continue }
            let isInvoice = doc.category.lowercased().contains("invoice")
            let eventType: ActivityEventType = isInvoice ? .invoiceProcessed : .documentProcessed
            events.append(RecentActivityEvent(
                id: "doc_\(doc.id.uuidString)",
                eventType: eventType,
                title: isInvoice
                    ? "Invoice processed: \(doc.title)"
                    : "\(doc.title) uploaded",
                occurredAt: uploadedAt,
                icon: eventType.icon,
                iconColor: eventType.iconColor,
                entityId: doc.id
            ))
        }

        // 3. Vendor additions
        for contractor in contractors {
            guard let createdAt = contractor.createdAt else { continue }
            events.append(RecentActivityEvent(
                id: "vendor_\(contractor.id.uuidString)",
                eventType: .vendorLinked,
                title: "\(contractor.companyName) added",
                occurredAt: createdAt,
                icon: ActivityEventType.vendorLinked.icon,
                iconColor: ActivityEventType.vendorLinked.iconColor,
                entityId: contractor.id
            ))
        }

        // 4. System additions (only recent -- skip old backfill noise)
        for system in systems {
            guard let createdAt = system.createdAt,
                  createdAt > sevenDaysAgo
            else { continue }
            events.append(RecentActivityEvent(
                id: "sys_\(system.id.uuidString)",
                eventType: .systemAdded,
                title: "\(system.name) added",
                occurredAt: createdAt,
                icon: ActivityEventType.systemAdded.icon,
                iconColor: ActivityEventType.systemAdded.iconColor,
                entityId: system.id
            ))
        }

        // 5. Vehicle additions
        for vehicle in vehicles {
            guard let createdAt = vehicle.createdAt else { continue }
            let label = [vehicle.year.map { "\($0)" }, vehicle.make, vehicle.model]
                .compactMap { $0 }
                .joined(separator: " ")
            events.append(RecentActivityEvent(
                id: "vehicle_\(vehicle.id.uuidString)",
                eventType: .vehicleAdded,
                title: "Vehicle added: \(label.isEmpty ? vehicle.name : label)",
                occurredAt: createdAt,
                icon: ActivityEventType.vehicleAdded.icon,
                iconColor: ActivityEventType.vehicleAdded.iconColor,
                entityId: vehicle.id
            ))
        }

        // 6. Inbox items received
        for item in inboxItems {
            guard let createdAt = item.createdAt else { continue }
            let truncatedTitle = item.title.count > 40
                ? String(item.title.prefix(37)) + "..."
                : item.title
            events.append(RecentActivityEvent(
                id: "inbox_\(item.id.uuidString)",
                eventType: .inboxItemReceived,
                title: "Email received: \(truncatedTitle)",
                occurredAt: createdAt,
                icon: ActivityEventType.inboxItemReceived.icon,
                iconColor: ActivityEventType.inboxItemReceived.iconColor,
                entityId: item.id
            ))
        }

        // 7. Property additions
        for property in properties {
            guard let createdAt = property.createdAt else { continue }
            let address = [property.street, property.city, property.state]
                .compactMap { $0 }
                .joined(separator: ", ")
            events.append(RecentActivityEvent(
                id: "property_\(property.id.uuidString)",
                eventType: .propertyAdded,
                title: "Property added: \(address.isEmpty ? property.name : address)",
                occurredAt: createdAt,
                icon: ActivityEventType.propertyAdded.icon,
                iconColor: ActivityEventType.propertyAdded.iconColor,
                entityId: property.id
            ))
        }

        // 8. Family member additions
        for member in familyMembers {
            guard let createdAt = member.createdAt else { continue }
            events.append(RecentActivityEvent(
                id: "family_\(member.id.uuidString)",
                eventType: .familyMemberJoined,
                title: "Family member joined: \(member.firstName)",
                occurredAt: createdAt,
                icon: ActivityEventType.familyMemberJoined.icon,
                iconColor: ActivityEventType.familyMemberJoined.iconColor,
                entityId: member.id
            ))
        }

        // 9. Project creation
        if let projects {
            for project in projects {
                guard let createdAt = project.createdAt else { continue }
                events.append(RecentActivityEvent(
                    id: "project_\(project.id.uuidString)",
                    eventType: .projectCreated,
                    title: "Project created: \(project.name)",
                    occurredAt: createdAt,
                    icon: ActivityEventType.projectCreated.icon,
                    iconColor: ActivityEventType.projectCreated.iconColor,
                    entityId: project.id
                ))
            }
        }

        // TODO: Phase 52 -- add scenarioRun events once ScenarioHistoryRow exists
        // TODO: Phase 52 -- add recallDetected events from vehicle recall data
        // TODO: Phase 52 -- add gapAnalysisRun events (no per-run row model yet)
        // TODO: Phase 52 -- add estateDocumentExtracted events from estate document analysis

        // Dedup by eventType + normalized title, sort by date desc
        var seenKeys = Set<String>()
        let deduped = events
            .sorted { $0.occurredAt > $1.occurredAt }
            .filter { event in
                let key = "\(event.eventType.rawValue)|\(event.title.lowercased())"
                return seenKeys.insert(key).inserted
            }

        return ActivityAssemblyResult(
            displayEvents: Array(deduped.prefix(7)),
            allEvents: deduped
        )
    }
}
