import SwiftUI
import UIKit
import Supabase

// MARK: - Native Haven Field

enum AppExperience: Equatable {
    case homeowner
    case field
}

extension Notification.Name {
    /// Posted by the visit-detail view after a successful coordination
    /// action (Confirm / Reschedule / Decline / Ask question) so the
    /// field dashboard refreshes and propagates the new request status
    /// back into the visits list. Avoids threading an `onCoordinated`
    /// callback through every NavigationLink construction site.
    static let havenFieldVisitChanged = Notification.Name("havenFieldVisitChanged")
}

enum HavenFieldVisitsFilter: String, CaseIterable, Identifiable {
    case requests = "Requests"
    case upcoming = "Upcoming"

    var id: String { rawValue }
}

enum HavenFieldMessageFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case quotes = "With quotes"
    case scheduling = "Scheduling"

    var id: String { rawValue }
}

struct HavenFieldDashboard: Decodable {
    var needsWorkspace: Bool
    var currentUser: HavenFieldCurrentUser?
    var permissions: HavenFieldPermissions?
    var workspace: HavenFieldWorkspace?
    var stats: HavenFieldStats?
    var visits: [HavenFieldVisit]
    var homes: [HavenFieldHome]
    var messages: [HavenFieldMessageThread]
    var recentWork: [HavenFieldVisit]
    var teamMembers: [HavenFieldTeamMember]

    init(
        needsWorkspace: Bool,
        currentUser: HavenFieldCurrentUser? = nil,
        permissions: HavenFieldPermissions? = nil,
        workspace: HavenFieldWorkspace? = nil,
        stats: HavenFieldStats? = nil,
        visits: [HavenFieldVisit] = [],
        homes: [HavenFieldHome] = [],
        messages: [HavenFieldMessageThread] = [],
        recentWork: [HavenFieldVisit] = [],
        teamMembers: [HavenFieldTeamMember] = []
    ) {
        self.needsWorkspace = needsWorkspace
        self.currentUser = currentUser
        self.permissions = permissions
        self.workspace = workspace
        self.stats = stats
        self.visits = visits
        self.homes = homes
        self.messages = messages
        self.recentWork = recentWork
        self.teamMembers = teamMembers
    }

    private enum CodingKeys: String, CodingKey {
        case needsWorkspace
        case currentUser
        case permissions
        case workspace
        case stats
        case visits
        case homes
        case messages
        case recentWork
        case teamMembers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        needsWorkspace = (try? container.decodeIfPresent(Bool.self, forKey: .needsWorkspace)) ?? false
        // Resilient nested decodes: a single bad field on a nested type
        // (e.g. a server-side shape change) should down-grade just that
        // field, not nuke the whole dashboard and dump the user back to
        // the workspace-setup form. Reference rule from CLAUDE.md:
        // every externally-fed struct uses `try?` per field.
        currentUser = (try? container.decodeIfPresent(HavenFieldCurrentUser.self, forKey: .currentUser)) ?? nil
        permissions = (try? container.decodeIfPresent(HavenFieldPermissions.self, forKey: .permissions)) ?? nil
        workspace = (try? container.decodeIfPresent(HavenFieldWorkspace.self, forKey: .workspace)) ?? nil
        stats = (try? container.decodeIfPresent(HavenFieldStats.self, forKey: .stats)) ?? nil
        visits = (try? container.decodeIfPresent([HavenFieldVisit].self, forKey: .visits)) ?? []
        homes = (try? container.decodeIfPresent([HavenFieldHome].self, forKey: .homes)) ?? []
        messages = (try? container.decodeIfPresent([HavenFieldMessageThread].self, forKey: .messages)) ?? []
        recentWork = (try? container.decodeIfPresent([HavenFieldVisit].self, forKey: .recentWork)) ?? []
        teamMembers = (try? container.decodeIfPresent([HavenFieldTeamMember].self, forKey: .teamMembers)) ?? []
    }
}

struct HavenFieldCurrentUser: Codable {
    let id: String?
    let memberId: String?
    let email: String?
    let fullName: String?
    let role: String?
    let roleLabel: String?
}

struct HavenFieldPermissions: Decodable {
    let canManageCrew: Bool
    let canAssignWork: Bool
    let canBuildQuotes: Bool
    let canManageWorkspace: Bool
    let isFieldTechnician: Bool

    private enum CodingKeys: String, CodingKey {
        case canManageCrew
        case canAssignWork
        case canBuildQuotes
        case canManageWorkspace
        case canSeeWorkspaceOverview
        case isFieldTechnician
    }

    init(
        canManageCrew: Bool,
        canAssignWork: Bool,
        canBuildQuotes: Bool,
        canManageWorkspace: Bool,
        isFieldTechnician: Bool
    ) {
        self.canManageCrew = canManageCrew
        self.canAssignWork = canAssignWork
        self.canBuildQuotes = canBuildQuotes
        self.canManageWorkspace = canManageWorkspace
        self.isFieldTechnician = isFieldTechnician
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let canManageCrew = try container.decodeIfPresent(Bool.self, forKey: .canManageCrew) ?? false
        let canAssignWork = try container.decodeIfPresent(Bool.self, forKey: .canAssignWork) ?? false
        let canBuildQuotes = try container.decodeIfPresent(Bool.self, forKey: .canBuildQuotes) ?? false
        let primaryWorkspaceFlag = try container.decodeIfPresent(Bool.self, forKey: .canManageWorkspace)
        let legacyWorkspaceFlag = try container.decodeIfPresent(Bool.self, forKey: .canSeeWorkspaceOverview)
        let canManageWorkspace = primaryWorkspaceFlag ?? legacyWorkspaceFlag ?? canManageCrew
        let isFieldTechnician = try container.decodeIfPresent(Bool.self, forKey: .isFieldTechnician) ?? false

        self.init(
            canManageCrew: canManageCrew,
            canAssignWork: canAssignWork,
            canBuildQuotes: canBuildQuotes,
            canManageWorkspace: canManageWorkspace,
            isFieldTechnician: isFieldTechnician
        )
    }
}

struct HavenFieldWorkspace: Codable {
    let id: String
    let companyName: String?
    let primaryEmail: String?
    let primaryPhone: String?
    let website: String?
    let contractorCount: Int?
    let activeMemberCount: Int?
    let invitedMemberCount: Int?
    let providerURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case primaryEmail
        case primaryPhone
        case website
        case contractorCount
        case activeMemberCount
        case invitedMemberCount
        case providerURL = "providerUrl"
    }
}

struct HavenFieldStats: Codable {
    let requestedVisits: Int?
    let upcomingVisits: Int?
    let unassignedVisits: Int?
    let todayStops: Int?
    let homesServiced: Int?
    let activeMembers: Int?
    let draftQuotes: Int?
    let quotesSent: Int?
    let completedVisits: Int?
    let openThreads: Int?
    let myAssignedVisits: Int?
}

struct HavenFieldVisit: Codable, Identifiable, Hashable {
    let id: String
    let requestId: String
    let householdId: String?
    let propertyId: String?
    let contractorId: String?
    let title: String
    let requestType: String?
    let status: String
    let statusLabel: String?
    let preferredTiming: String?
    let updatedAt: String?
    let routeDate: String?
    let property: HavenFieldPropertySummary?
    let visit: HavenFieldVisitTask?
    let fieldWorkspace: HavenFieldVisitWorkspaceSummary?
    let assignment: HavenFieldVisitAssignment?
    let latestMessage: HavenFieldLatestMessage?
    let quote: HavenFieldQuoteSummary?
    /// Phase 78: structured punch list rows for this visit, served by the
    /// handyman-provider edge function. Replaces VisitNotesParser regex.
    let punchItems: [HavenFieldPunchItem]

    private enum CodingKeys: String, CodingKey {
        case requestId
        case householdId
        case propertyId
        case contractorId
        case title
        case requestType
        case status
        case statusLabel
        case preferredTiming
        case updatedAt
        case routeDate
        case property
        case visit
        case fieldWorkspace
        case assignment
        case latestMessage
        case quote
        case punchItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Server doesn't emit a top-level `id` for visits — `requestId` is
        // the stable identity. Mirror it into `id` so SwiftUI's diffing
        // (Identifiable) and the in-code init stay consistent.
        let resolvedRequestId = (try? container.decodeIfPresent(String.self, forKey: .requestId)) ?? ""
        requestId = resolvedRequestId
        id = resolvedRequestId
        householdId = (try? container.decodeIfPresent(String.self, forKey: .householdId)) ?? nil
        propertyId = (try? container.decodeIfPresent(String.self, forKey: .propertyId)) ?? nil
        contractorId = (try? container.decodeIfPresent(String.self, forKey: .contractorId)) ?? nil
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "Visit"
        requestType = (try? container.decodeIfPresent(String.self, forKey: .requestType)) ?? nil
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        statusLabel = (try? container.decodeIfPresent(String.self, forKey: .statusLabel)) ?? nil
        preferredTiming = (try? container.decodeIfPresent(String.self, forKey: .preferredTiming)) ?? nil
        updatedAt = (try? container.decodeIfPresent(String.self, forKey: .updatedAt)) ?? nil
        routeDate = (try? container.decodeIfPresent(String.self, forKey: .routeDate)) ?? nil
        property = (try? container.decodeIfPresent(HavenFieldPropertySummary.self, forKey: .property)) ?? nil
        visit = (try? container.decodeIfPresent(HavenFieldVisitTask.self, forKey: .visit)) ?? nil
        fieldWorkspace = (try? container.decodeIfPresent(HavenFieldVisitWorkspaceSummary.self, forKey: .fieldWorkspace)) ?? nil
        assignment = (try? container.decodeIfPresent(HavenFieldVisitAssignment.self, forKey: .assignment)) ?? nil
        latestMessage = (try? container.decodeIfPresent(HavenFieldLatestMessage.self, forKey: .latestMessage)) ?? nil
        quote = (try? container.decodeIfPresent(HavenFieldQuoteSummary.self, forKey: .quote)) ?? nil
        punchItems = (try? container.decodeIfPresent([HavenFieldPunchItem].self, forKey: .punchItems)) ?? []
    }

    init(
        requestId: String,
        householdId: String?,
        propertyId: String?,
        contractorId: String?,
        title: String,
        requestType: String?,
        status: String,
        statusLabel: String?,
        preferredTiming: String?,
        updatedAt: String?,
        routeDate: String?,
        property: HavenFieldPropertySummary?,
        visit: HavenFieldVisitTask?,
        fieldWorkspace: HavenFieldVisitWorkspaceSummary?,
        assignment: HavenFieldVisitAssignment?,
        latestMessage: HavenFieldLatestMessage?,
        quote: HavenFieldQuoteSummary?,
        punchItems: [HavenFieldPunchItem] = []
    ) {
        self.requestId = requestId
        self.id = requestId
        self.householdId = householdId
        self.propertyId = propertyId
        self.contractorId = contractorId
        self.title = title
        self.requestType = requestType
        self.status = status
        self.statusLabel = statusLabel
        self.preferredTiming = preferredTiming
        self.updatedAt = updatedAt
        self.routeDate = routeDate
        self.property = property
        self.visit = visit
        self.fieldWorkspace = fieldWorkspace
        self.assignment = assignment
        self.latestMessage = latestMessage
        self.quote = quote
        self.punchItems = punchItems
    }
}

/// Phase 78: structured punch list row matching `handyman_punch_items`.
/// Mirrors the camelCase shape `mapPunchItemForClient` returns from the
/// handyman-provider edge function. Resilient decoder so a single bad
/// field on the server response doesn't take down the whole array.
struct HavenFieldPunchItem: Codable, Identifiable, Hashable {
    let id: String
    let householdId: String
    let propertyId: String?
    let assignedVisitTaskId: String?
    let systemId: String?
    let systemLabelSnapshot: String?
    let templateId: String?
    let title: String
    let description: String?
    let source: String
    let status: String
    let priority: String
    let estimatedMinutes: Int?
    let estimatedCostRange: String?
    let materialRequired: Bool
    let costBasis: String
    let addedAfterLock: Bool
    let proposedByRole: String?
    let proposedAt: String?
    let proposalMessage: String?
    let proposalStatus: String
    let proposalExpiresAt: String?
    let acceptedAt: String?
    let declinedAt: String?
    let declinedReason: String?
    let completedAt: String?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, householdId, propertyId, assignedVisitTaskId, systemId, systemLabelSnapshot
        case templateId, title, description, source, status, priority
        case estimatedMinutes, estimatedCostRange, materialRequired, costBasis, addedAfterLock
        case proposedByRole, proposedAt, proposalMessage, proposalStatus, proposalExpiresAt
        case acceptedAt, declinedAt, declinedReason, completedAt, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? ""
        propertyId = (try? c.decodeIfPresent(String.self, forKey: .propertyId)) ?? nil
        assignedVisitTaskId = (try? c.decodeIfPresent(String.self, forKey: .assignedVisitTaskId)) ?? nil
        systemId = (try? c.decodeIfPresent(String.self, forKey: .systemId)) ?? nil
        systemLabelSnapshot = (try? c.decodeIfPresent(String.self, forKey: .systemLabelSnapshot)) ?? nil
        templateId = (try? c.decodeIfPresent(String.self, forKey: .templateId)) ?? nil
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? "Item"
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? nil
        source = (try? c.decodeIfPresent(String.self, forKey: .source)) ?? "manual"
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "pending"
        priority = (try? c.decodeIfPresent(String.self, forKey: .priority)) ?? "medium"
        estimatedMinutes = (try? c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)) ?? nil
        estimatedCostRange = (try? c.decodeIfPresent(String.self, forKey: .estimatedCostRange)) ?? nil
        materialRequired = (try? c.decodeIfPresent(Bool.self, forKey: .materialRequired)) ?? false
        costBasis = (try? c.decodeIfPresent(String.self, forKey: .costBasis)) ?? "time_and_materials"
        addedAfterLock = (try? c.decodeIfPresent(Bool.self, forKey: .addedAfterLock)) ?? false
        proposedByRole = (try? c.decodeIfPresent(String.self, forKey: .proposedByRole)) ?? nil
        proposedAt = (try? c.decodeIfPresent(String.self, forKey: .proposedAt)) ?? nil
        proposalMessage = (try? c.decodeIfPresent(String.self, forKey: .proposalMessage)) ?? nil
        proposalStatus = (try? c.decodeIfPresent(String.self, forKey: .proposalStatus)) ?? "none"
        proposalExpiresAt = (try? c.decodeIfPresent(String.self, forKey: .proposalExpiresAt)) ?? nil
        acceptedAt = (try? c.decodeIfPresent(String.self, forKey: .acceptedAt)) ?? nil
        declinedAt = (try? c.decodeIfPresent(String.self, forKey: .declinedAt)) ?? nil
        declinedReason = (try? c.decodeIfPresent(String.self, forKey: .declinedReason)) ?? nil
        completedAt = (try? c.decodeIfPresent(String.self, forKey: .completedAt)) ?? nil
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
        updatedAt = (try? c.decodeIfPresent(String.self, forKey: .updatedAt)) ?? nil
    }

    /// Synthesize an ephemeral, non-persisted punch item from a parsed
    /// `VisitChildItem`. Used as a transitional fallback when the
    /// dashboard response hasn't migrated to structured rows yet.
    static func legacyEphemeral(id: String, title: String, estimatedMinutes: Int?) -> HavenFieldPunchItem {
        let json: [String: Any] = [
            "id": id,
            "householdId": "",
            "title": title,
            "source": "legacy_ephemeral",
            "status": "pending",
            "priority": "medium",
            "estimatedMinutes": estimatedMinutes as Any,
            "materialRequired": false,
            "costBasis": "time_and_materials",
            "addedAfterLock": false,
            "proposalStatus": "none",
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        return (try? JSONDecoder().decode(HavenFieldPunchItem.self, from: data)) ?? {
            // Should never hit this branch, but the decoder requires
            // *something* — synthesize a minimal placeholder.
            let fallbackJson = #"{"id":"\#(id)","householdId":"","title":"\#(title)","source":"legacy_ephemeral","status":"pending","priority":"medium","materialRequired":false,"costBasis":"time_and_materials","addedAfterLock":false,"proposalStatus":"none"}"#
            let fallbackData = fallbackJson.data(using: .utf8) ?? Data()
            return try! JSONDecoder().decode(HavenFieldPunchItem.self, from: fallbackData)
        }()
    }

    /// Display label for the system link chip ("Linked: Boiler. Basement").
    /// Prefers the live system name (would require a join client-side, omitted
    /// here) and falls back to the snapshot taken at delegate-time.
    var systemDisplayLabel: String? {
        if let snapshot = systemLabelSnapshot, !snapshot.isEmpty { return snapshot }
        return nil
    }
}

struct HavenFieldPropertySummary: Codable, Hashable {
    let id: String?
    let name: String?
    let address: String?
}

struct HavenFieldVisitTask: Codable, Hashable {
    let id: String?
    let title: String?
    let scheduledDate: String?
    let dueDate: String?
    /// Visit notes — contains the parsed punch-list block ("Punch list:\n- …").
    /// Phase 74b made the server include this; iOS now consumes it through
    /// `VisitNotesParser` to render the visit checklist on the field side.
    let notes: String?
    let description: String?
}

struct HavenFieldVisitWorkspaceSummary: Codable, Hashable {
    let portalToken: String?
    let url: String?
    let reportStatus: String?
    let completedAt: String?
}

struct HavenFieldVisitAssignment: Codable, Hashable {
    let id: String?
    let memberId: String?
    let memberName: String?
    let memberRole: String?
    let memberRoleLabel: String?
    let routeDate: String?
    let windowStartTime: String?
    let windowEndTime: String?
    let stopOrder: Int?
    let routeNotes: String?
}

struct HavenFieldLatestMessage: Codable, Hashable {
    let senderRole: String?
    let body: String?
    let createdAt: String?
}

struct HavenFieldQuoteSummary: Codable, Hashable {
    let id: String?
    let status: String?
    let statusLabel: String?
    let total: Double?
    let updatedAt: String?
    let publicShareUrl: String?
}

struct HavenFieldHome: Codable, Identifiable {
    let id: String
    let propertyId: String
    let householdId: String?
    let name: String
    let address: String
    let systemCount: Int
    let openRequests: Int
    let lastCompletedVisit: String?
    let assignedMembers: [String]
    let systems: [HavenFieldHomeSystem]
    let openTasks: [HavenFieldOpenTask]
    let recentVisits: [HavenFieldHomeVisit]
    let files: [HavenFieldHomeFile]

    private enum CodingKeys: String, CodingKey {
        case propertyId
        case householdId
        case name
        case address
        case systemCount
        case openRequests
        case lastCompletedVisit
        case assignedMembers
        case systems
        case openTasks
        case recentVisits
        case files
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        propertyId = try container.decode(String.self, forKey: .propertyId)
        id = propertyId
        householdId = (try? container.decodeIfPresent(String.self, forKey: .householdId)) ?? nil
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Home"
        address = (try? container.decodeIfPresent(String.self, forKey: .address)) ?? ""
        systemCount = (try? container.decodeIfPresent(Int.self, forKey: .systemCount)) ?? 0
        openRequests = (try? container.decodeIfPresent(Int.self, forKey: .openRequests)) ?? 0
        lastCompletedVisit = (try? container.decodeIfPresent(String.self, forKey: .lastCompletedVisit)) ?? nil
        assignedMembers = (try? container.decodeIfPresent([String].self, forKey: .assignedMembers)) ?? []
        // Resilient nested arrays: one bad element shouldn't take the whole
        // home down. Use try? at the array level so a malformed system /
        // visit / file degrades gracefully to an empty list.
        systems = (try? container.decodeIfPresent([HavenFieldHomeSystem].self, forKey: .systems)) ?? []
        openTasks = (try? container.decodeIfPresent([HavenFieldOpenTask].self, forKey: .openTasks)) ?? []
        recentVisits = (try? container.decodeIfPresent([HavenFieldHomeVisit].self, forKey: .recentVisits)) ?? []
        files = (try? container.decodeIfPresent([HavenFieldHomeFile].self, forKey: .files)) ?? []
    }
}

struct HavenFieldHomeSystem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String?
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let notes: String?
    let installDate: String?
    let status: String?
    let subtype: String?
    let catalogSeries: String?
    let catalogModelName: String?
    let catalogFuelType: String?
    let catalogFeatures: [String]
    let reliabilityScore: Int?
    let scoreSummary: String?
    let lastServiceDate: String?
    let nextServiceDue: String?
    let totalSpent: Double?
    let cachedManualLinks: [HavenFieldLink]

    private enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes, status, subtype
        case modelNumber
        case serialNumber
        case installDate
        case catalogSeries
        case catalogModelName
        case catalogFuelType
        case catalogFeatures
        case reliabilityScore
        case scoreSummary
        case lastServiceDate
        case nextServiceDue
        case totalSpent
        case cachedManualLinks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "System"
        category = try container.decodeIfPresent(String.self, forKey: .category)
        manufacturer = try container.decodeIfPresent(String.self, forKey: .manufacturer)
        modelNumber = try container.decodeIfPresent(String.self, forKey: .modelNumber)
        serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        installDate = try container.decodeIfPresent(String.self, forKey: .installDate)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        catalogSeries = try container.decodeIfPresent(String.self, forKey: .catalogSeries)
        catalogModelName = try container.decodeIfPresent(String.self, forKey: .catalogModelName)
        catalogFuelType = try container.decodeIfPresent(String.self, forKey: .catalogFuelType)
        catalogFeatures = try container.decodeIfPresent([String].self, forKey: .catalogFeatures) ?? []
        reliabilityScore = try container.decodeIfPresent(Int.self, forKey: .reliabilityScore)
        scoreSummary = try container.decodeIfPresent(String.self, forKey: .scoreSummary)
        lastServiceDate = try container.decodeIfPresent(String.self, forKey: .lastServiceDate)
        nextServiceDue = try container.decodeIfPresent(String.self, forKey: .nextServiceDue)
        totalSpent = try container.decodeIfPresent(Double.self, forKey: .totalSpent)
        cachedManualLinks = try container.decodeIfPresent([HavenFieldLink].self, forKey: .cachedManualLinks) ?? []
    }
}

struct HavenFieldLink: Codable, Identifiable, Hashable {
    var id: String { url }
    let type: String?
    let url: String
    let cached: Bool?
}

struct HavenFieldOpenTask: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: String?
    let priority: String?
    let assignmentType: String?
    let serviceKey: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, dueDate, priority, assignmentType, serviceKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "Task"
        dueDate = (try? container.decodeIfPresent(String.self, forKey: .dueDate)) ?? nil
        priority = (try? container.decodeIfPresent(String.self, forKey: .priority)) ?? nil
        assignmentType = (try? container.decodeIfPresent(String.self, forKey: .assignmentType)) ?? nil
        serviceKey = (try? container.decodeIfPresent(String.self, forKey: .serviceKey)) ?? nil
    }
}

struct HavenFieldHomeVisit: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let routeDate: String?
    let statusLabel: String?
    let completedAt: String?

    /// Server emits the visit row WITHOUT a top-level `id` — `requestId`
    /// is the stable identity. Mirror it (or fall back to a UUID for
    /// defensive coverage) so SwiftUI's diffing has something stable.
    /// Keep CodingKeys aligned with stored properties so Encodable
    /// synthesis stays happy; read the legacy `requestId` field via a
    /// separate keys enum.
    private enum CodingKeys: String, CodingKey {
        case id, title, routeDate, statusLabel, completedAt
    }

    private enum FallbackKeys: String, CodingKey {
        case requestId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = try? decoder.container(keyedBy: FallbackKeys.self)
        let directId = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? nil
        let requestId = (try? fallback?.decodeIfPresent(String.self, forKey: .requestId)) ?? nil
        id = directId ?? requestId ?? UUID().uuidString
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "Visit"
        routeDate = (try? container.decodeIfPresent(String.self, forKey: .routeDate)) ?? nil
        statusLabel = (try? container.decodeIfPresent(String.self, forKey: .statusLabel)) ?? nil
        completedAt = (try? container.decodeIfPresent(String.self, forKey: .completedAt)) ?? nil
    }
}

struct HavenFieldHomeFile: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String?
    let uploadedAt: String?
    let notes: String?
    let signedURL: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, category, uploadedAt, notes
        case signedURL = "signedUrl"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "File"
        category = (try? container.decodeIfPresent(String.self, forKey: .category)) ?? nil
        uploadedAt = (try? container.decodeIfPresent(String.self, forKey: .uploadedAt)) ?? nil
        notes = (try? container.decodeIfPresent(String.self, forKey: .notes)) ?? nil
        signedURL = (try? container.decodeIfPresent(String.self, forKey: .signedURL)) ?? nil
    }
}

struct HavenFieldMessageThread: Codable, Identifiable {
    let id: String
    let requestId: String
    let propertyId: String?
    let title: String
    let requestType: String?
    let preferredTiming: String?
    let status: String?
    let statusLabel: String?
    let propertyName: String?
    let propertyAddress: String?
    let latestMessage: String?
    let latestMessageAt: String?
    let senderRole: String?
    let assignedMemberName: String?
    let fieldWorkspaceURL: String?
    let recentMessages: [HavenFieldThreadMessage]
    let quote: HavenFieldQuoteSummary?

    private enum CodingKeys: String, CodingKey {
        case requestId
        case propertyId
        case title
        case requestType
        case preferredTiming
        case status
        case statusLabel
        case propertyName
        case propertyAddress
        case latestMessage
        case latestMessageAt
        case senderRole
        case assignedMemberName
        case fieldWorkspaceURL = "fieldWorkspaceUrl"
        case recentMessages
        case quote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try container.decode(String.self, forKey: .requestId)
        id = requestId
        propertyId = try container.decodeIfPresent(String.self, forKey: .propertyId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Message thread"
        requestType = try container.decodeIfPresent(String.self, forKey: .requestType)
        preferredTiming = try container.decodeIfPresent(String.self, forKey: .preferredTiming)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        statusLabel = try container.decodeIfPresent(String.self, forKey: .statusLabel)
        propertyName = try container.decodeIfPresent(String.self, forKey: .propertyName)
        propertyAddress = try container.decodeIfPresent(String.self, forKey: .propertyAddress)
        latestMessage = try container.decodeIfPresent(String.self, forKey: .latestMessage)
        latestMessageAt = try container.decodeIfPresent(String.self, forKey: .latestMessageAt)
        senderRole = try container.decodeIfPresent(String.self, forKey: .senderRole)
        assignedMemberName = try container.decodeIfPresent(String.self, forKey: .assignedMemberName)
        fieldWorkspaceURL = try container.decodeIfPresent(String.self, forKey: .fieldWorkspaceURL)
        recentMessages = try container.decodeIfPresent([HavenFieldThreadMessage].self, forKey: .recentMessages) ?? []
        quote = try container.decodeIfPresent(HavenFieldQuoteSummary.self, forKey: .quote)
    }
}

struct HavenFieldThreadMessage: Codable, Identifiable, Hashable {
    let id: String
    let body: String?
    let senderRole: String?
    let createdAt: String?
}

struct HavenFieldTeamMember: Codable, Identifiable, Hashable {
    let id: String
    let fullName: String?
    let roleLabel: String?
    let todayStops: Int?
    let openVisits: Int?
}

struct HavenFieldPortalPayload: Codable {
    let session: HavenFieldPortalSession
    let report: HavenFieldVisitDraft?
    let request: HavenFieldPortalRequest?
    let messages: [HavenFieldPortalMessage]
}

struct HavenFieldPortalSession: Codable {
    let id: String
    let title: String?
    let status: String?
    let portalToken: String?
    let seedPayload: HavenFieldPortalSeed

    private enum CodingKeys: String, CodingKey {
        case id, title, status
        case portalToken = "portal_token"
        case seedPayload = "seed_payload"
    }
}

struct HavenFieldPortalSeed: Codable {
    let visitId: String?
    let visitTitle: String
    let scheduledDate: String?
    let dueDate: String?
    let firstVisit: Bool
    let property: HavenFieldPortalProperty
    let contractorName: String?
    let contractorPhone: String?
    let contractorEmail: String?
    let homeownerNotes: String?
    let checklist: [HavenFieldChecklistItem]
    let quickUpsells: [HavenFieldRecommendation]
    let setupPrompts: [HavenFieldSetupPrompt]
    let coordination: HavenFieldCoordinationSeed?
    let recommendations: [HavenFieldRecommendation]
}

struct HavenFieldPortalProperty: Codable {
    let name: String
    let addressLine: String?
    let propertyType: String?
    let squareFootage: Int?
    let yearBuilt: Int?
    let systemCount: Int?
    let knownSystems: [String]
    let systems: [HavenFieldSystemSnapshot]
}

struct HavenFieldCoordinationSeed: Codable {
    let status: String?
    let statusLabel: String?
    let intro: String?
    let lastMessage: String?
    let scheduledDate: String?
    let needsHomeownerReply: Bool?

    private enum CodingKeys: String, CodingKey {
        case status
        case statusLabel = "status_label"
        case intro
        case lastMessage = "last_message"
        case scheduledDate = "scheduled_date"
        case needsHomeownerReply = "needs_homeowner_reply"
    }
}

struct HavenFieldPortalRequest: Codable {
    let id: String
    let status: String?
    let statusLabel: String?
    let title: String?
    let preferredTiming: String?
    let propertyId: String?
    let householdId: String?
    let intro: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, title, intro
        case statusLabel = "status_label"
        case preferredTiming = "preferred_timing"
        case propertyId = "property_id"
        case householdId = "household_id"
    }
}

struct HavenFieldPortalMessage: Codable, Identifiable, Hashable {
    let id: String
    let senderRole: String?
    let body: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, body
        case senderRole = "sender_role"
        case createdAt = "created_at"
    }
}

struct HavenFieldChecklistItem: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var subtitle: String?
    var category: String?
    var status: String
    var source: String?
    var recommended: Bool?
}

struct HavenFieldSetupPrompt: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var detail: String?
    var category: String?
    var isRequired: Bool?
    var done: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, title, detail, category, done
        case isRequired = "isRequired"
    }
}

struct HavenFieldRecommendation: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var detail: String?
    var category: String?
    var priority: String?
    var createFollowUp: Bool?
    var priceHint: String?
    var minutesHint: Int?

    private enum CodingKeys: String, CodingKey {
        case id, title, detail, category, priority
        case createFollowUp = "create_follow_up"
        case priceHint = "priceHint"
        case minutesHint = "minutesHint"
    }
}

struct HavenFieldSystemSnapshot: Codable, Identifiable, Hashable {
    let id: String
    var systemId: String?
    var name: String
    var category: String
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var installDate: String?
    var notes: String?
    var lastServiceDate: String?
    var nextServiceDue: String?
    var serviced: Bool
    var needsSetup: Bool
    var status: String?
    var subtype: String?
    var catalogEntryId: String?
    var catalogSeries: String?
    var catalogModelName: String?
    var catalogFeatures: [String]
    var catalogFuelType: String?
    var catalogDisplayName: String?
    var catalogSubtitle: String?
    var reliabilityScore: Int?
    var scoreSummary: String?
    var cachedManualLinks: [HavenFieldLink]
    var labelPhotoName: String?
    var photoCapturedAt: String?

    init(
        id: String,
        systemId: String? = nil,
        name: String,
        category: String,
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        installDate: String? = nil,
        notes: String? = nil,
        lastServiceDate: String? = nil,
        nextServiceDue: String? = nil,
        serviced: Bool = false,
        needsSetup: Bool = false,
        status: String? = nil,
        subtype: String? = nil,
        catalogEntryId: String? = nil,
        catalogSeries: String? = nil,
        catalogModelName: String? = nil,
        catalogFeatures: [String] = [],
        catalogFuelType: String? = nil,
        catalogDisplayName: String? = nil,
        catalogSubtitle: String? = nil,
        reliabilityScore: Int? = nil,
        scoreSummary: String? = nil,
        cachedManualLinks: [HavenFieldLink] = [],
        labelPhotoName: String? = nil,
        photoCapturedAt: String? = nil
    ) {
        self.id = id
        self.systemId = systemId
        self.name = name
        self.category = category
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.installDate = installDate
        self.notes = notes
        self.lastServiceDate = lastServiceDate
        self.nextServiceDue = nextServiceDue
        self.serviced = serviced
        self.needsSetup = needsSetup
        self.status = status
        self.subtype = subtype
        self.catalogEntryId = catalogEntryId
        self.catalogSeries = catalogSeries
        self.catalogModelName = catalogModelName
        self.catalogFeatures = catalogFeatures
        self.catalogFuelType = catalogFuelType
        self.catalogDisplayName = catalogDisplayName
        self.catalogSubtitle = catalogSubtitle
        self.reliabilityScore = reliabilityScore
        self.scoreSummary = scoreSummary
        self.cachedManualLinks = cachedManualLinks
        self.labelPhotoName = labelPhotoName
        self.photoCapturedAt = photoCapturedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, manufacturer, notes, serviced, status, subtype
        case systemId = "system_id"
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case installDate = "install_date"
        case lastServiceDate = "last_service_date"
        case nextServiceDue = "next_service_due"
        case needsSetup = "needs_setup"
        case catalogEntryId = "catalog_entry_id"
        case catalogSeries = "catalog_series"
        case catalogModelName = "catalog_model_name"
        case catalogFeatures = "catalog_features"
        case catalogFuelType = "catalog_fuel_type"
        case catalogDisplayName = "catalog_display_name"
        case catalogSubtitle = "catalog_subtitle"
        case reliabilityScore = "reliability_score"
        case scoreSummary = "score_summary"
        case cachedManualLinks = "cached_manual_links"
        case labelPhotoName = "label_photo_name"
        case photoCapturedAt = "photo_captured_at"
    }
}

struct HavenFieldVisitDraft: Codable {
    var reportStatus: String
    var coordinationStatus: String?
    var checklist: [HavenFieldChecklistItem]
    var setupPrompts: [HavenFieldSetupPrompt]
    var quickUpsells: [HavenFieldRecommendation]
    var systemsSnapshot: [HavenFieldSystemSnapshot]
    var recommendations: [HavenFieldRecommendation]
    var fieldNotes: String
    var homeownerNotes: String
    var startedAt: String?
    var completedAt: String?

    private enum CodingKeys: String, CodingKey {
        case reportStatus = "report_status"
        case coordinationStatus = "coordination_status"
        case checklist
        case setupPrompts = "setup_prompts"
        case quickUpsells = "quick_upsells"
        case systemsSnapshot = "systems_snapshot"
        case recommendations
        case fieldNotes = "field_notes"
        case homeownerNotes = "homeowner_notes"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct HavenFieldCoordinationAction: Codable {
    let type: String
    let message: String?
    let proposedDate: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case message
        case proposedDate = "proposedDate"
    }
}

struct HavenFieldSendMessageResponse: Codable {
    let message: HavenFieldPortalMessage?
    let requestId: String?
    let propertyId: String?
}

struct HavenFieldCreateVisitResponse: Codable {
    let requestId: String?
    let visitTaskId: String?
    let portalToken: String?
    let portalUrl: String?
    let scheduledDate: String?
    let title: String?
    let propertyId: String?
}

struct HavenFieldPairingRequest: Codable, Identifiable {
    let id: String
    let status: String?
    let accessCode: String?
    let homeName: String?
    let homeownerName: String?
    let address: String?
    let shareText: String?
}

struct HavenFieldCreatePairingResponse: Codable {
    let pairingRequest: HavenFieldPairingRequest
}

enum HavenFieldCache {
    private static let dashboardKey = "haven-field-dashboard-cache"

    static func loadDashboard() -> HavenFieldDashboard? {
        guard let data = UserDefaults.standard.data(forKey: dashboardKey) else { return nil }
        return try? JSONDecoder().decode(HavenFieldDashboard.self, from: data)
    }

    static func saveDashboard(_ dashboard: HavenFieldDashboard) {
        // Chez v1: cache writes disabled while HavenFieldDashboard is
        // Decodable-only (the Field-app target hasn't been split out yet,
        // so encoding the dashboard for UserDefaults caching can't be
        // synthesized). The dashboard is always re-fetched from the
        // server on launch — losing the cache only costs a network round
        // trip on cold start. Re-enable when the Field app gets its own
        // target with full Codable structs.
        _ = dashboard
    }

    static func clearDashboard() {
        UserDefaults.standard.removeObject(forKey: dashboardKey)
    }

    static func draftKey(for token: String) -> String {
        "haven-field-visit-draft-\(token)"
    }

    static func loadDraft(token: String) -> HavenFieldVisitDraft? {
        guard let data = UserDefaults.standard.data(forKey: draftKey(for: token)) else { return nil }
        return try? JSONDecoder().decode(HavenFieldVisitDraft.self, from: data)
    }

    static func saveDraft(_ draft: HavenFieldVisitDraft, token: String) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: draftKey(for: token))
    }
}

actor HavenFieldService {
    static let shared = HavenFieldService()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private func makeRequest(
        function name: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> URLRequest {
        var components = URLComponents(string: "\(AppConfig.Supabase.url)/functions/v1/\(name)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")
        if let accessToken = await HavenSupabase.safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    private func perform<T: Decodable>(
        function name: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        expecting: T.Type
    ) async throws -> T {
        let request = try await makeRequest(function: name, method: method, queryItems: queryItems, body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            print("[HavenFieldService] HTTP \(http.statusCode) on \(name): \(message.prefix(500))")
            throw NSError(domain: "ChezField", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Surface the raw response when decoding fails — saves a lot of
            // guesswork when the server response shape drifts.
            let rawPreview = String(data: data, encoding: .utf8)?.prefix(800) ?? "<binary>"
            print("[HavenFieldService] Decode error on \(name): \(error)")
            print("[HavenFieldService] Raw response preview: \(rawPreview)")
            throw error
        }
    }

    private func perform(
        function name: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws {
        let request = try await makeRequest(function: name, method: method, queryItems: queryItems, body: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func fetchDashboard() async throws -> HavenFieldDashboard {
        try await perform(function: "handyman-provider", expecting: HavenFieldDashboard.self)
    }

    func bootstrapWorkspace(
        fullName: String,
        companyName: String,
        phone: String,
        website: String,
        title: String? = nil
    ) async throws -> HavenFieldDashboard {
        struct Request: Encodable {
            let action = "bootstrap_workspace"
            let fullName: String
            let companyName: String
            let phone: String
            let website: String
            let title: String?
        }

        let data = try JSONEncoder().encode(
            Request(
                fullName: fullName,
                companyName: companyName,
                phone: phone,
                website: website,
                title: title
            )
        )
        return try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldDashboard.self)
    }

    func sendMessage(
        workspaceId: String,
        requestId: String? = nil,
        propertyId: String? = nil,
        body: String,
        status: String?,
        threadTitle: String? = nil
    ) async throws -> HavenFieldSendMessageResponse {
        struct Request: Encodable {
            let action = "send_message"
            let workspaceId: String
            let requestId: String?
            let propertyId: String?
            let body: String
            let status: String?
            let threadTitle: String?
        }
        let data = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                requestId: requestId,
                propertyId: propertyId,
                body: body,
                status: status,
                threadTitle: threadTitle
            )
        )
        return try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldSendMessageResponse.self)
    }

    /// Provider-side accept: walks the request to `confirmed` with the
    /// previously-proposed visit time. Mirrors the desktop "Confirm" action.
    func acceptVisitTime(workspaceId: String, requestId: String) async throws {
        struct Request: Encodable {
            let action = "accept_visit_time"
            let workspaceId: String
            let requestId: String
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId, requestId: requestId))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Provider-side propose: pushes a new proposed visit time and an
    /// optional note. Server fires a homeowner push notification.
    func proposeVisitTime(workspaceId: String, requestId: String, proposedAt: String, note: String?) async throws {
        struct Request: Encodable {
            let action = "propose_visit_time"
            let workspaceId: String
            let requestId: String
            let proposedAt: String
            let note: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            proposedAt: proposedAt,
            note: note?.trimmedOrNil
        ))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Update the underlying handyman_request status (e.g. `declined`,
    /// `cancelled`). Used by the visit-detail Decline action.
    func updateRequestStatus(workspaceId: String, requestId: String, status: String, reason: String?) async throws {
        struct Request: Encodable {
            let action = "update_request_status"
            let workspaceId: String
            let requestId: String
            let status: String
            let reason: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            status: status,
            reason: reason?.trimmedOrNil
        ))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    // MARK: - Phase 78 punch list / proposals

    /// Toggles a single punch item between status values
    /// (`pending` / `assigned` / `in_progress` / `done` / `cancelled`).
    /// On `done` the server-side trigger bumps `home_systems.last_service_date`
    /// when the item is system-linked.
    func updatePunchItemStatus(itemId: String, status: String) async throws {
        struct Request: Encodable {
            let action = "update_punch_item_status"
            let itemId: String
            let status: String
        }
        let data = try JSONEncoder().encode(Request(itemId: itemId, status: status))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Suggests a follow-up visit. Optional ISO `proposedAt` triggers
    /// the existing `propose_visit_time` RPC server-side so the
    /// homeowner sees the proposal in the same accept/counter flow.
    func proposeFollowupVisit(
        workspaceId: String,
        parentRequestId: String,
        title: String,
        details: String?,
        proposedAt: String?,
        punchItemIds: [String],
        costEstimateLow: Double?,
        costEstimateHigh: Double?,
        costEstimateKind: String?
    ) async throws -> String {
        struct Request: Encodable {
            let action = "propose_followup_visit"
            let workspaceId: String
            let parentRequestId: String
            let title: String
            let details: String?
            let proposedAt: String?
            let punchItemIds: [String]
            let costEstimateLow: Double?
            let costEstimateHigh: Double?
            let costEstimateKind: String?
        }
        struct Response: Decodable {
            let ok: Bool
            let requestId: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            parentRequestId: parentRequestId,
            title: title,
            details: details?.trimmedOrNil,
            proposedAt: proposedAt?.trimmedOrNil,
            punchItemIds: punchItemIds,
            costEstimateLow: costEstimateLow,
            costEstimateHigh: costEstimateHigh,
            costEstimateKind: costEstimateKind?.trimmedOrNil
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.requestId
    }

    /// Flags a maintenance task for the homeowner. Surfaces in their
    /// Proposals inbox; once accepted, becomes a real maintenance_tasks
    /// row. Lands as `assignment_type='vendor', needs_vendor=true`.
    func proposeHomeownerTask(
        workspaceId: String,
        originVisitTaskId: String,
        title: String,
        message: String?,
        suggestedCategory: String?,
        attachments: [[String: String]] = [],
        requiresHomeownerApproval: Bool = false
    ) async throws -> String {
        struct Request: Encodable {
            let action = "propose_homeowner_task"
            let workspaceId: String
            let originVisitTaskId: String
            let title: String
            let message: String?
            let suggestedCategory: String?
            let attachments: [[String: String]]
            let requiresHomeownerApproval: Bool
        }
        struct Response: Decodable {
            let ok: Bool
            let taskId: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            originVisitTaskId: originVisitTaskId,
            title: title,
            message: message?.trimmedOrNil,
            suggestedCategory: suggestedCategory?.trimmedOrNil,
            attachments: attachments,
            requiresHomeownerApproval: requiresHomeownerApproval
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.taskId
    }

    /// Adds one or more punch items to a specific visit. New items can
    /// reference a `templateId` (server auto-fills minutes / category)
    /// or be free-text. If the visit is already locked and the caller
    /// is the homeowner, items get `added_after_lock=true` server-side.
    struct PunchItemDraft: Encodable {
        let templateId: String?
        let title: String?
        let estimatedMinutes: Int?
        let priority: String?
        let materialRequired: Bool
        let systemId: String?
    }

    func addPunchItemsToVisit(visitTaskId: String, items: [PunchItemDraft]) async throws -> [String] {
        struct Request: Encodable {
            let action = "add_punch_items_to_visit"
            let visitTaskId: String
            let items: [PunchItemDraft]
        }
        struct Response: Decodable {
            let ok: Bool
            let count: Int
            let ids: [String]
        }
        let data = try JSONEncoder().encode(Request(visitTaskId: visitTaskId, items: items))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.ids
    }

    /// Generic accept / decline / cancel for any proposal-bearing row.
    /// `kind` is one of "task" | "punch_item" | "request". The decision
    /// rides on a separate `decision` key so it doesn't collide with
    /// the wrapper's `action` field.
    func respondToProposal(
        kind: String,
        id: String,
        action decisionAction: String,
        reason: String? = nil
    ) async throws {
        struct Request: Encodable {
            let action = "respond_to_proposal"
            let kind: String
            let id: String
            let decision: String
            let reason: String?
        }
        let data = try JSONEncoder().encode(Request(
            kind: kind,
            id: id,
            decision: decisionAction,
            reason: reason?.trimmedOrNil
        ))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Cancels a `handyman_requests` row. Reverts attached punch items
    /// to wishlist (assigned_visit_task_id=null) server-side.
    func cancelHandymanRequest(requestId: String, reason: String?) async throws {
        struct Request: Encodable {
            let action = "cancel_handyman_request"
            let requestId: String
            let reason: String?
        }
        let data = try JSONEncoder().encode(Request(requestId: requestId, reason: reason?.trimmedOrNil))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Homeowner-callable. Converts a `maintenance_tasks` row into a
    /// `handyman_punch_items` row delegated to a target visit (or
    /// wishlist when no visit is supplied).
    func delegateTaskToPunchList(taskId: String, targetVisitTaskId: String? = nil) async throws -> String {
        struct Request: Encodable {
            let action = "delegate_task_to_punch_list"
            let taskId: String
            let targetVisitTaskId: String?
        }
        struct Response: Decodable {
            let ok: Bool
            let punchItemId: String
        }
        let data = try JSONEncoder().encode(Request(taskId: taskId, targetVisitTaskId: targetVisitTaskId))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.punchItemId
    }

    func createAdHocVisit(
        workspaceId: String,
        propertyId: String,
        title: String,
        details: String,
        scheduledDate: String,
        requestType: String = "standard_visit"
    ) async throws -> HavenFieldCreateVisitResponse {
        struct Request: Encodable {
            let action = "create_ad_hoc_visit"
            let workspaceId: String
            let propertyId: String
            let title: String
            let details: String
            let scheduledDate: String
            let requestType: String
        }

        let data = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                propertyId: propertyId,
                title: title,
                details: details,
                scheduledDate: scheduledDate,
                requestType: requestType
            )
        )
        return try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldCreateVisitResponse.self)
    }

    func createPairingRequest(
        workspaceId: String,
        homeName: String,
        homeownerName: String,
        homeownerEmail: String,
        homeownerPhone: String,
        addressLine: String,
        city: String,
        state: String,
        postalCode: String,
        notes: String
    ) async throws -> HavenFieldCreatePairingResponse {
        struct Request: Encodable {
            let action = "create_pairing_request"
            let workspaceId: String
            let homeName: String
            let homeownerName: String
            let homeownerEmail: String
            let homeownerPhone: String
            let addressLine: String
            let city: String
            let state: String
            let postalCode: String
            let notes: String
        }

        let data = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                homeName: homeName,
                homeownerName: homeownerName,
                homeownerEmail: homeownerEmail,
                homeownerPhone: homeownerPhone,
                addressLine: addressLine,
                city: city,
                state: state,
                postalCode: postalCode,
                notes: notes
            )
        )
        return try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldCreatePairingResponse.self)
    }

    func fetchPortal(token: String) async throws -> HavenFieldPortalPayload {
        try await perform(
            function: "handyman-portal",
            queryItems: [URLQueryItem(name: "token", value: token)],
            expecting: HavenFieldPortalPayload.self
        )
    }

    func syncPortal(
        token: String,
        draft: HavenFieldVisitDraft,
        coordinationAction: HavenFieldCoordinationAction? = nil
    ) async throws -> HavenFieldPortalPayload {
        struct Request: Encodable {
            let token: String
            let report: HavenFieldVisitDraft
            let coordinationAction: HavenFieldCoordinationAction?
        }
        let data = try JSONEncoder().encode(Request(token: token, report: draft, coordinationAction: coordinationAction))
        return try await perform(function: "handyman-portal", method: "POST", body: data, expecting: HavenFieldPortalPayload.self)
    }
}

@MainActor
final class HavenFieldViewModel: ObservableObject {
    enum RootTab: Hashable {
        case home
        case visits
        case clients
        case messages
    }

    @Published var dashboard: HavenFieldDashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab: RootTab = .home
    @Published var visitsFilter: HavenFieldVisitsFilter = .upcoming
    @Published var messageFilter: HavenFieldMessageFilter = .all

    func load(initialDashboard: HavenFieldDashboard? = nil, force: Bool = false) async {
        if let initialDashboard, dashboard == nil {
            dashboard = initialDashboard
            HavenFieldCache.saveDashboard(initialDashboard)
        } else if dashboard == nil, let cached = HavenFieldCache.loadDashboard() {
            dashboard = cached
        }

        if isLoading { return }
        if dashboard != nil && !force { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fresh = try await HavenFieldService.shared.fetchDashboard()
            dashboard = fresh
            HavenFieldCache.saveDashboard(fresh)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            if dashboard == nil {
                dashboard = HavenFieldCache.loadDashboard()
            }
        }
    }

    func refresh() async {
        await load(force: true)
    }
}

@MainActor
final class HavenFieldVisitWorkspaceModel: ObservableObject {
    enum VisitTab: String, CaseIterable {
        case home = "Home"
        case visit = "Visit"
        case systems = "Systems"
        case files = "Files"
    }

    @Published var payload: HavenFieldPortalPayload?
    @Published var draft: HavenFieldVisitDraft?
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var syncMessage = "Up to date"
    @Published var selectedTab: VisitTab = .home
    @Published var errorMessage: String?

    let visit: HavenFieldVisit
    let home: HavenFieldHome?
    let workspaceId: String?
    /// Called after a successful coordination action so the parent
    /// dashboard can refresh and propagate the new request status back
    /// into the visits list. Optional — pure-display callers can ignore it.
    var onCoordinated: (() async -> Void)?

    init(visit: HavenFieldVisit, home: HavenFieldHome?, workspaceId: String?, onCoordinated: (() async -> Void)? = nil) {
        self.visit = visit
        self.home = home
        self.workspaceId = workspaceId
        self.onCoordinated = onCoordinated
    }

    var portalToken: String? { visit.fieldWorkspace?.portalToken }
    var messages: [HavenFieldPortalMessage] { payload?.messages ?? [] }
    var requestStatus: String { payload?.request?.status ?? visit.status }
    var statusLabel: String { payload?.request?.statusLabel ?? visit.statusLabel ?? visit.status.replacingOccurrences(of: "_", with: " ").capitalized }

    func load() async {
        guard let token = portalToken else { return }
        if let cached = HavenFieldCache.loadDraft(token: token) {
            draft = cached
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let payload = try await HavenFieldService.shared.fetchPortal(token: token)
            self.payload = payload
            draft = mergedDraft(from: payload)
            if let draft {
                HavenFieldCache.saveDraft(draft, token: token)
            }
            syncMessage = "Up to date"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            syncMessage = "Offline draft"
        }
    }

    func updateFieldNotes(_ value: String) {
        guard var draft else { return }
        draft.fieldNotes = value
        store(draft, message: "Notes saved on device")
    }

    func updateHomeownerNotes(_ value: String) {
        guard var draft else { return }
        draft.homeownerNotes = value
        store(draft, message: "Notes saved on device")
    }

    func toggleChecklist(_ item: HavenFieldChecklistItem) {
        guard var draft, let index = draft.checklist.firstIndex(where: { $0.id == item.id }) else { return }
        draft.checklist[index].status = draft.checklist[index].status == "done" ? "todo" : "done"
        store(draft, message: "Checklist updated")
    }

    func toggleSetupPrompt(_ item: HavenFieldSetupPrompt) {
        guard var draft, let index = draft.setupPrompts.firstIndex(where: { $0.id == item.id }) else { return }
        draft.setupPrompts[index].done = !(draft.setupPrompts[index].done ?? false)
        store(draft, message: "Setup updated")
    }

    func toggleRecommendation(_ item: HavenFieldRecommendation) {
        guard var draft, let index = draft.recommendations.firstIndex(where: { $0.id == item.id }) else { return }
        draft.recommendations[index].createFollowUp = !(draft.recommendations[index].createFollowUp ?? false)
        store(draft, message: "Recommendation updated")
    }

    func markOnMyWay() async {
        guard var draft else { return }
        draft.coordinationStatus = HandymanRequestStatus.onMyWay.rawValue
        await sync(draft: draft, message: "Handyman is on the way")
    }

    func checkIn() async {
        guard var draft else { return }
        draft.reportStatus = "in_progress"
        draft.coordinationStatus = HandymanRequestStatus.checkedIn.rawValue
        draft.startedAt = draft.startedAt ?? ISO8601DateFormatter().string(from: Date())
        await sync(draft: draft, message: "Checked in")
    }

    func completeVisit() async {
        guard var draft else {
            // Pre-Wave-3b this silently returned. A handyman tapping
            // "Complete visit" on a non-portal-session visit got no
            // feedback whatsoever. Now we surface the precondition so
            // the user knows why nothing happened. The deeper issue
            // (visits without portal sessions can't be completed end-to-end)
            // is documented as the parallel-tables architectural finding
            // in HANDYMAN_GAPS.md and needs product input.
            errorMessage = "This visit isn’t set up for live tracking yet. Tap Sync now first to load the visit checklist."
            return
        }
        draft.reportStatus = "completed"
        draft.coordinationStatus = draft.recommendations.contains(where: { $0.createFollowUp ?? false })
            ? HandymanRequestStatus.followUpRecommended.rawValue
            : HandymanRequestStatus.completed.rawValue
        draft.completedAt = ISO8601DateFormatter().string(from: Date())
        await sync(draft: draft, message: "Visit completed")
    }

    /// Coordination actions (Confirm / Reschedule / Decline / Ask question)
    /// hit the request directly via the provider edge function — they do
    /// NOT require a portal session / draft. The original `sync(...)`
    /// path bailed when `draft` was nil, which made every button no-op
    /// for not-yet-started visits. This routes each action to the right
    /// server endpoint, then asks the parent dashboard to refresh so the
    /// new status propagates back to the visits list.
    func performCoordination(type: String, message: String?, proposedDate: String?) async {
        guard let workspaceId, !workspaceId.isEmpty else {
            errorMessage = "Workspace not loaded yet. Try again in a moment."
            return
        }
        let requestId = visit.requestId
        guard !requestId.isEmpty else {
            errorMessage = "Visit identifier missing."
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            switch type {
            case "confirm_date":
                try await HavenFieldService.shared.acceptVisitTime(workspaceId: workspaceId, requestId: requestId)
                syncMessage = "Visit confirmed"
            case "propose_other_dates":
                guard let isoTimestamp = proposedDate?.trimmedOrNil else {
                    errorMessage = "Pick a new date and time."
                    return
                }
                try await HavenFieldService.shared.proposeVisitTime(
                    workspaceId: workspaceId,
                    requestId: requestId,
                    proposedAt: isoTimestamp,
                    note: message
                )
                syncMessage = "New time proposed"
            case "decline_visit":
                try await HavenFieldService.shared.updateRequestStatus(
                    workspaceId: workspaceId,
                    requestId: requestId,
                    status: "declined",
                    reason: message
                )
                syncMessage = "Visit declined"
            case "ask_question":
                let body = (message?.trimmedOrNil) ?? ""
                guard !body.isEmpty else {
                    errorMessage = "Type your question first."
                    return
                }
                try await sendMessage(body)
                syncMessage = "Message sent"
            default:
                let action = HavenFieldCoordinationAction(type: type, message: message?.trimmedOrNil, proposedDate: proposedDate?.trimmedOrNil)
                guard let existing = draft else { return }
                await sync(draft: existing, action: action, message: "Coordination updated")
                return
            }
            errorMessage = nil
            await onCoordinated?()
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "Couldn’t update the visit. Please try again.")
        }
    }

    func syncNow() async {
        guard let draft else { return }
        await sync(draft: draft, message: "Synced")
    }

    func sendMessage(_ body: String) async throws {
        guard let workspaceId, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = try await HavenFieldService.shared.sendMessage(
            workspaceId: workspaceId,
            requestId: visit.requestId,
            body: body,
            status: nil
        )
    }

    func identifySystem(index: Int, imageData: Data) async {
        guard var draft, draft.systemsSnapshot.indices.contains(index) else { return }
        do {
            let base64 = imageData.base64EncodedString()
            let response = try await HavenSupabase.identifyEquipment(imageBase64: base64, category: draft.systemsSnapshot[index].category)
            draft.systemsSnapshot[index] = patchedSystem(draft.systemsSnapshot[index], response: response)
            store(draft, message: "System identified from label photo")
            await sync(draft: draft, message: "System synced")
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "Couldn’t identify the equipment. Please try again or enter manually.")
        }
    }

    func addSystemFromPhoto(imageData: Data) async {
        guard var draft else { return }
        do {
            let base64 = imageData.base64EncodedString()
            let response = try await HavenSupabase.identifyEquipment(imageBase64: base64, category: nil)
            let system = patchedSystem(
                HavenFieldSystemSnapshot(
                    id: "local-\(UUID().uuidString)",
                    name: response.catalogMatch?.displayName ?? response.modelNumber ?? "New system",
                    category: response.catalogMatch?.category.name ?? "Other",
                    needsSetup: false
                ),
                response: response
            )
            draft.systemsSnapshot.append(system)
            store(draft, message: "System added")
            await sync(draft: draft, message: "System synced")
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "Couldn’t add the system. Please try again or enter manually.")
        }
    }

    private func mergedDraft(from payload: HavenFieldPortalPayload) -> HavenFieldVisitDraft {
        let seed = payload.session.seedPayload
        let report = payload.report
        return HavenFieldVisitDraft(
            reportStatus: report?.reportStatus ?? "draft",
            coordinationStatus: report?.coordinationStatus ?? payload.request?.status ?? seed.coordination?.status,
            checklist: !(report?.checklist.isEmpty ?? true) ? report?.checklist ?? [] : seed.checklist,
            setupPrompts: !(report?.setupPrompts.isEmpty ?? true) ? report?.setupPrompts ?? [] : seed.setupPrompts,
            quickUpsells: !(report?.quickUpsells.isEmpty ?? true) ? report?.quickUpsells ?? [] : seed.quickUpsells,
            systemsSnapshot: !(report?.systemsSnapshot.isEmpty ?? true) ? report?.systemsSnapshot ?? [] : seed.property.systems,
            recommendations: !(report?.recommendations.isEmpty ?? true) ? report?.recommendations ?? [] : (seed.recommendations.isEmpty ? seed.quickUpsells : seed.recommendations),
            fieldNotes: report?.fieldNotes ?? "",
            homeownerNotes: report?.homeownerNotes ?? seed.homeownerNotes ?? "",
            startedAt: report?.startedAt,
            completedAt: report?.completedAt
        )
    }

    private func store(_ draft: HavenFieldVisitDraft, message: String) {
        self.draft = draft
        if let token = portalToken {
            HavenFieldCache.saveDraft(draft, token: token)
        }
        syncMessage = message
    }

    private func sync(draft: HavenFieldVisitDraft, action: HavenFieldCoordinationAction? = nil, message: String) async {
        guard let token = portalToken else { return }
        store(draft, message: "Saving locally")
        isSyncing = true
        defer { isSyncing = false }
        do {
            let payload = try await HavenFieldService.shared.syncPortal(token: token, draft: draft, coordinationAction: action)
            self.payload = payload
            let merged = mergedDraft(from: payload)
            self.draft = merged
            HavenFieldCache.saveDraft(merged, token: token)
            syncMessage = message
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            syncMessage = "Saved offline"
        }
    }

    private func patchedSystem(_ existing: HavenFieldSystemSnapshot, response: EquipmentIdentifyResponse) -> HavenFieldSystemSnapshot {
        HavenFieldSystemSnapshot(
            id: existing.id,
            systemId: existing.systemId,
            name: response.catalogMatch?.displayName ?? existing.name,
            category: response.catalogMatch?.category.name ?? existing.category,
            manufacturer: response.manufacturer ?? existing.manufacturer,
            modelNumber: response.modelNumber ?? existing.modelNumber,
            serialNumber: response.serialNumber ?? existing.serialNumber,
            installDate: existing.installDate,
            notes: existing.notes,
            lastServiceDate: existing.lastServiceDate,
            nextServiceDue: existing.nextServiceDue,
            serviced: existing.serviced,
            needsSetup: false,
            status: existing.status,
            subtype: response.catalogMatch?.category.name ?? existing.subtype,
            catalogEntryId: response.catalogMatch?.id.uuidString ?? existing.catalogEntryId,
            catalogSeries: response.catalogMatch?.specs.series ?? existing.catalogSeries,
            catalogModelName: response.catalogMatch?.modelName ?? existing.catalogModelName,
            catalogFeatures: response.catalogMatch?.specs.keyFeatures ?? existing.catalogFeatures,
            catalogFuelType: response.catalogMatch?.specs.fuelType ?? existing.catalogFuelType,
            catalogDisplayName: response.catalogMatch?.displayName ?? existing.catalogDisplayName,
            catalogSubtitle: response.catalogMatch?.subtitle ?? existing.catalogSubtitle,
            reliabilityScore: response.catalogMatch?.scores?.reliability ?? existing.reliabilityScore,
            scoreSummary: response.catalogMatch?.scores?.summary ?? existing.scoreSummary,
            cachedManualLinks: existing.cachedManualLinks,
            labelPhotoName: "Label photo",
            photoCapturedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

/// Maps NSURL / Supabase / generic errors to user-friendly copy.
/// Pre-Wave-2a, several Field-app surfaces (visit confirm, system identify,
/// add-system) surfaced raw NSURLErrorDomain strings to users. This is the
/// single place to keep server-error UI strings honest. Real errors still
/// log via `print` for engineering follow-up.
private func friendlyServerError(from error: Error, fallback: String = "Something went wrong. Please try again.") -> String {
    print("[HavenFieldService] error: \(error)")
    let raw = error.localizedDescription.lowercased()
    if raw.contains("network") || raw.contains("offline") || raw.contains("internet") || raw.contains("-1009") || raw.contains("-1011") {
        return "Network error. Please check your connection and try again."
    }
    if raw.contains("does not exist") || raw.contains("42703") || raw.contains("internal") || raw.contains("500") {
        return fallback
    }
    if raw.contains("not authenticated") || raw.contains("jwt") || raw.contains("401") {
        return "Your session expired. Please sign in again."
    }
    if raw.contains("permission") || raw.contains("403") {
        return "You don’t have permission to do this."
    }
    return fallback
}

struct HavenFieldRootView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HavenFieldViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack {
                HavenFieldHomeTab(viewModel: viewModel)
            }
            .tabItem {
                Label("Overview", systemImage: "square.grid.2x2.fill")
            }
            .tag(HavenFieldViewModel.RootTab.home)

            NavigationStack {
                HavenFieldVisitsTab(viewModel: viewModel)
            }
            .tabItem {
                Label("Visits", systemImage: "calendar")
            }
            .tag(HavenFieldViewModel.RootTab.visits)

            NavigationStack {
                HavenFieldClientsTab(viewModel: viewModel)
            }
            .tabItem {
                Label("Homes", systemImage: "house.fill")
            }
            .tag(HavenFieldViewModel.RootTab.clients)

            NavigationStack {
                HavenFieldMessagesTab(viewModel: viewModel)
            }
            .tabItem {
                Label("Messages", systemImage: "message.fill")
            }
            .tag(HavenFieldViewModel.RootTab.messages)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HavenFieldTabBar(selectedTab: $viewModel.selectedTab)
        }
        .tint(HavenColors.action)
        .background(HavenColors.cream.ignoresSafeArea())
        .task {
            await viewModel.load(initialDashboard: appState.fieldDashboard)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .havenFieldVisitChanged)) { _ in
            Task { await viewModel.refresh() }
        }
    }
}

private struct HavenFieldHomeTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false

    private var requestedVisits: [HavenFieldVisit] {
        (viewModel.dashboard?.visits ?? [])
            .filter(\.belongsInRequestQueue)
            .sorted(by: fieldVisitSort)
    }

    private var todayVisits: [HavenFieldVisit] {
        guard let dashboard = viewModel.dashboard else { return [] }
        let today = DateFormatter.havenISODate.string(from: Date())
        return dashboard.visits
            .filter { ($0.routeDate ?? $0.visit?.scheduledDate ?? "") == today && $0.belongsInUpcomingQueue }
            .sorted(by: fieldVisitSort)
    }

    private var upcomingVisits: [HavenFieldVisit] {
        (viewModel.dashboard?.visits ?? [])
            .filter(\.belongsInUpcomingQueue)
            .filter { visit in
                guard let routeDate = visit.routeDate ?? visit.visit?.scheduledDate else { return false }
                return routeDate >= DateFormatter.havenISODate.string(from: Date())
            }
            .sorted(by: fieldVisitSort)
    }

    private var heroVisits: [HavenFieldVisit] {
        todayVisits.isEmpty ? upcomingVisits : todayVisits
    }

    private var routePreviewVisits: [HavenFieldVisit] {
        Array(heroVisits.prefix(3))
    }

    private var nextVisit: HavenFieldVisit? {
        heroVisits.first ?? requestedVisits.first
    }

    private var recentHomes: [HavenFieldHome] {
        (viewModel.dashboard?.homes ?? [])
            .sorted {
                String($1.lastCompletedVisit ?? "") < String($0.lastCompletedVisit ?? "")
            }
    }

    private var unreadThreadsCount: Int {
        (viewModel.dashboard?.messages ?? []).filter(\.fieldNeedsAttention).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FieldWorkspaceHeader(
                    companyName: viewModel.dashboard?.workspace?.companyName ?? "Chez Field",
                    memberName: viewModel.dashboard?.currentUser?.fullName,
                    roleLabel: viewModel.dashboard?.currentUser?.roleLabel ?? "Field workspace",
                    subtitle: headerSubtitle,
                    onOpenSettings: { showSettings = true }
                )

                if let errorMessage = viewModel.errorMessage {
                    FieldErrorBanner(message: errorMessage)
                }

                FieldBrandHeroCard(
                    kicker: heroKicker,
                    title: greetingTitle,
                    subtitle: heroSubtitle
                ) {
                    if let nextVisit {
                        FieldRouteHeroPreview(
                            visit: nextVisit,
                            home: home(for: nextVisit),
                            badgeValue: nextVisit.belongsInRequestQueue ? "!" : "1"
                        )
                    }

                    heroPrimaryAction

                    HStack(spacing: 12) {
                        Button {
                            viewModel.visitsFilter = .requests
                            viewModel.selectedTab = .visits
                        } label: {
                            FieldHeroMetric(
                                value: "\(requestedVisits.count)",
                                label: "Requests",
                                dotColor: HavenColors.actionLight
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.visitsFilter = .upcoming
                            viewModel.selectedTab = .visits
                        } label: {
                            FieldHeroMetric(
                                value: "\(upcomingVisits.count)",
                                label: "Upcoming",
                                dotColor: HavenColors.indigo400
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.messageFilter = .all
                            viewModel.selectedTab = .messages
                        } label: {
                            FieldHeroMetric(
                                value: "\(unreadThreadsCount)",
                                label: "Messages",
                                dotColor: HavenColors.warning
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if routePreviewVisits.isEmpty {
                    FieldForwardMomentumCard(
                        title: "No route is on deck yet",
                        subtitle: "Pair a home, create an ad hoc visit, or jump into homeowner requests to get the board moving.",
                        primaryTitle: "Open visits",
                        secondaryTitle: requestedVisits.isEmpty ? nil : "Review requests"
                    ) {
                        viewModel.visitsFilter = .upcoming
                        viewModel.selectedTab = .visits
                    } secondaryAction: {
                        viewModel.visitsFilter = .requests
                        viewModel.selectedTab = .visits
                    }
                } else {
                    FieldSectionCard(kicker: "Today", title: todayVisits.isEmpty ? "Scheduled next" : "Your route") {
                        VStack(spacing: 14) {
                            ForEach(Array(routePreviewVisits.enumerated()), id: \.element.id) { index, visit in
                                NavigationLink {
                                    HavenFieldVisitWorkspaceView(
                                        viewModel: HavenFieldVisitWorkspaceModel(
                                            visit: visit,
                                            home: home(for: visit),
                                            workspaceId: viewModel.dashboard?.workspace?.id
                                        )
                                    )
                                } label: {
                                    FieldScheduledVisitRow(
                                        visit: visit,
                                        home: home(for: visit),
                                        highlightNext: index == 0 && visit.belongsInUpcomingQueue
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !requestedVisits.isEmpty {
                    FieldSectionCard(kicker: "Requests", title: "Need a response") {
                        VStack(spacing: 12) {
                            ForEach(Array(requestedVisits.prefix(3))) { visit in
                                NavigationLink {
                                    HavenFieldVisitWorkspaceView(
                                        viewModel: HavenFieldVisitWorkspaceModel(
                                            visit: visit,
                                            home: home(for: visit),
                                            workspaceId: viewModel.dashboard?.workspace?.id
                                        )
                                    )
                                } label: {
                                    FieldRequestQueueRow(
                                        visit: visit,
                                        home: home(for: visit),
                                        ageLabel: visit.updatedAt?.fieldRelativeTime
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                FieldSectionCard(kicker: "Homes", title: "Recently serviced homes") {
                    if recentHomes.isEmpty {
                        FieldEmptyState(
                            title: "No homes connected yet",
                            subtitle: "Once homeowners connect this handyman in Chez, service history and systems will show up here."
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(recentHomes.prefix(4))) { home in
                                NavigationLink {
                                    HavenFieldHomeProfileView(home: home)
                                } label: {
                                    FieldHomeRow(home: home)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .padding(.bottom, 140)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            FieldWorkspaceSettingsSheet(
                companyName: viewModel.dashboard?.workspace?.companyName ?? "Chez Field",
                memberName: viewModel.dashboard?.currentUser?.fullName,
                email: viewModel.dashboard?.workspace?.primaryEmail,
                phone: viewModel.dashboard?.workspace?.primaryPhone,
                providerURL: viewModel.dashboard?.workspace?.providerURL
            ) {
                appState.authService.signOut()
            }
        }
    }

    @ViewBuilder
    private var heroPrimaryAction: some View {
        if let nextVisit {
            NavigationLink {
                HavenFieldVisitWorkspaceView(
                    viewModel: HavenFieldVisitWorkspaceModel(
                        visit: nextVisit,
                        home: home(for: nextVisit),
                        workspaceId: viewModel.dashboard?.workspace?.id
                    )
                )
            } label: {
                HStack(spacing: 8) {
                    Text(nextVisit.belongsInRequestQueue ? "Open request" : "Start route")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())
        } else {
            Button {
                viewModel.visitsFilter = .upcoming
                viewModel.selectedTab = .visits
            } label: {
                HStack(spacing: 8) {
                    Text("Open visits")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())
        }
    }

    private var headerSubtitle: String {
        let person = viewModel.dashboard?.currentUser?.fullName?.components(separatedBy: " ").first
        let stops = todayVisits.count
        let stopLabel = "\(stops) stop\(stops == 1 ? "" : "s") today"
        if let person, !person.isEmpty {
            return "\(person) · \(stopLabel)"
        }
        return stopLabel
    }

    private var heroKicker: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var greetingTitle: String {
        let firstName = viewModel.dashboard?.currentUser?.fullName?
            .split(separator: " ")
            .first
            .map(String.init)
        return "\(Date.now.fieldGreeting), \(firstName ?? "there")"
    }

    private var heroSubtitle: String {
        if let first = todayVisits.first {
            let when = first.assignment?.windowStartTime?.trimmedOrNil ?? "next up"
            return "\(todayVisits.count) stop\(todayVisits.count == 1 ? "" : "s") today · first at \(when) · \(requestedVisits.count) request\(requestedVisits.count == 1 ? "" : "s") waiting"
        }
        if let first = upcomingVisits.first {
            return "\(upcomingVisits.count) confirmed visit\(upcomingVisits.count == 1 ? "" : "s") ahead · next \(first.routeDate?.fieldRouteDateLabel ?? "soon")"
        }
        if !requestedVisits.isEmpty {
            return "\(requestedVisits.count) homeowner request\(requestedVisits.count == 1 ? "" : "s") need a response before the route fills in."
        }
        return "No route is on deck yet. Pair homes, add a visit, or jump into homeowner requests to get the day moving."
    }

    private func home(for visit: HavenFieldVisit) -> HavenFieldHome? {
        guard let propertyId = visit.propertyId else { return nil }
        return viewModel.dashboard?.homes.first(where: { $0.propertyId == propertyId })
    }

}

private struct HavenFieldVisitsTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @State private var showVisitActions = false
    @State private var showAdHocComposer = false
    @State private var showPairingComposer = false

    private var filteredVisits: [HavenFieldVisit] {
        let visits = viewModel.dashboard?.visits ?? []
        switch viewModel.visitsFilter {
        case .requests:
            return visits.filter(\.belongsInRequestQueue).sorted(by: fieldVisitSort)
        case .upcoming:
            return visits.filter(\.belongsInUpcomingQueue).sorted(by: fieldVisitSort)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Visits")
                                .font(HavenTypography.title)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Requests, confirmed stops, and route-ready work.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Text(allVisitCountLabel)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HavenColors.surface)
                            .overlay(Capsule().stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 12) {
                        ForEach(HavenFieldVisitsFilter.allCases) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewModel.visitsFilter = filter
                                }
                            } label: {
                                FieldVisitModeTile(
                                    title: filter.rawValue,
                                    value: filter == .requests ? requestCount : upcomingCount,
                                    subtitle: filter == .requests
                                        ? (requestCount == 0 ? "No new requests" : "\(requestCount) need a response")
                                        : (todayUpcomingCount == 0 ? "\(upcomingCount) scheduled" : "\(todayUpcomingCount) today"),
                                    isSelected: viewModel.visitsFilter == filter
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.visitsFilter == .requests {
                        FieldSectionCard(kicker: "Need a response", title: "Homeowner requests") {
                            if filteredVisits.isEmpty {
                                FieldEmptyState(
                                    title: "No homeowner requests yet",
                                    subtitle: "New visit requests, date changes, and quote follow-ups will land here first."
                                )
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(filteredVisits) { visit in
                                        NavigationLink {
                                            HavenFieldVisitWorkspaceView(
                                                viewModel: HavenFieldVisitWorkspaceModel(
                                                    visit: visit,
                                                    home: viewModel.dashboard?.homes.first(where: { $0.propertyId == visit.propertyId }),
                                                    workspaceId: viewModel.dashboard?.workspace?.id
                                                )
                                            )
                                        } label: {
                                            FieldRequestQueueRow(
                                                visit: visit,
                                                home: viewModel.dashboard?.homes.first(where: { $0.propertyId == visit.propertyId }),
                                                ageLabel: visit.updatedAt?.fieldRelativeTime
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    } else {
                        FieldSectionCard(kicker: "Schedule", title: "Confirmed route") {
                            if filteredVisits.isEmpty {
                                FieldEmptyState(
                                    title: "No confirmed visits yet",
                                    subtitle: "Once visits are confirmed, they’ll show up here with routing, windows, and homeowner context."
                                )
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(groupedUpcomingVisits, id: \.dateKey) { group in
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Text(group.label.uppercased())
                                                    .font(HavenTypography.uiSectionHeader)
                                                    .kerning(1.2)
                                                    .foregroundStyle(HavenColors.textSecondary)
                                                Spacer()
                                                if group.isToday {
                                                    Text("NEXT UP")
                                                        .font(HavenTypography.caption)
                                                        .foregroundStyle(HavenColors.action)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(HavenColors.action50)
                                                        .clipShape(Capsule())
                                                }
                                            }

                                            VStack(spacing: 12) {
                                                ForEach(Array(group.visits.enumerated()), id: \.element.id) { index, visit in
                                                    NavigationLink {
                                                        HavenFieldVisitWorkspaceView(
                                                            viewModel: HavenFieldVisitWorkspaceModel(
                                                                visit: visit,
                                                                home: viewModel.dashboard?.homes.first(where: { $0.propertyId == visit.propertyId }),
                                                                workspaceId: viewModel.dashboard?.workspace?.id
                                                            )
                                                        )
                                                    } label: {
                                                        FieldScheduledVisitRow(
                                                            visit: visit,
                                                            home: viewModel.dashboard?.homes.first(where: { $0.propertyId == visit.propertyId }),
                                                            highlightNext: group.isToday && index == 0
                                                        )
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                        .padding(.bottom, group == groupedUpcomingVisits.last ? 0 : 2)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 140)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)

            FieldFloatingActionButton(label: "New visit", systemImage: "plus") {
                showVisitActions = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 36)
        }
        .confirmationDialog("Add to Chez Field", isPresented: $showVisitActions) {
            Button("Create ad hoc visit") {
                showAdHocComposer = true
            }
            Button("Start pairing for a home") {
                showPairingComposer = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Create a confirmed visit for a connected home, or create a pairing request for a home that hasn't joined Chez yet.")
        }
        .sheet(isPresented: $showAdHocComposer) {
            HavenFieldAdHocVisitComposer(
                homes: viewModel.dashboard?.homes ?? [],
                workspaceId: viewModel.dashboard?.workspace?.id,
                onCreated: {
                    viewModel.visitsFilter = .upcoming
                    await viewModel.refresh()
                }
            )
        }
        .sheet(isPresented: $showPairingComposer) {
            HavenFieldPairingRequestComposer(
                workspaceId: viewModel.dashboard?.workspace?.id,
                onCreated: {
                    await viewModel.refresh()
                }
            )
        }
    }

    private var requestCount: Int {
        (viewModel.dashboard?.visits ?? []).filter(\.belongsInRequestQueue).count
    }

    private var upcomingCount: Int {
        (viewModel.dashboard?.visits ?? []).filter(\.belongsInUpcomingQueue).count
    }

    private var todayUpcomingCount: Int {
        let today = DateFormatter.havenISODate.string(from: Date())
        return (viewModel.dashboard?.visits ?? []).filter {
            $0.belongsInUpcomingQueue && ($0.routeDate ?? $0.visit?.scheduledDate ?? "") == today
        }.count
    }

    private var allVisitCountLabel: String {
        let total = (viewModel.dashboard?.visits ?? []).filter {
            $0.belongsInRequestQueue || $0.belongsInUpcomingQueue
        }.count
        if total == 0 { return "All clear" }
        if total == 1 { return "1 active" }
        return "\(total) active"
    }

    private var groupedUpcomingVisits: [FieldVisitDateGroup] {
        let groups = Dictionary(grouping: filteredVisits) { $0.routeDate ?? $0.visit?.scheduledDate ?? "No date" }
        return groups.keys.sorted().map { key in
            let visits = (groups[key] ?? []).sorted(by: fieldVisitSort)
            return FieldVisitDateGroup(
                dateKey: key,
                label: key == "No date" ? "No date" : key.fieldRouteDateLabel,
                isToday: key == DateFormatter.havenISODate.string(from: Date()),
                visits: visits
            )
        }
    }
}

private struct FieldVisitDateGroup: Equatable {
    let dateKey: String
    let label: String
    let isToday: Bool
    let visits: [HavenFieldVisit]
}

private struct HavenFieldClientsTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @State private var searchText: String = ""

    private var sortedHomes: [HavenFieldHome] {
        (viewModel.dashboard?.homes ?? []).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var filteredHomes: [HavenFieldHome] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sortedHomes }
        return sortedHomes.filter { home in
            home.name.localizedCaseInsensitiveContains(trimmed)
                || home.address.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homes")
                            .font(HavenTypography.title)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Every home you service, with their open work and history.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Text(homeCountLabel)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.surface)
                        .overlay(Capsule().stroke(HavenColors.border, lineWidth: 1))
                        .clipShape(Capsule())
                }

                if !sortedHomes.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(HavenColors.textSecondary)
                            .font(HavenTypography.uiLabel)
                        TextField("Search by name or address", text: $searchText)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if filteredHomes.isEmpty {
                    FieldSectionCard(kicker: "Homes", title: sortedHomes.isEmpty ? "No homes yet" : "No matches") {
                        FieldEmptyState(
                            title: sortedHomes.isEmpty
                                ? "Homes you service will appear here"
                                : "No homes match \u{201C}\(searchText)\u{201D}",
                            subtitle: sortedHomes.isEmpty
                                ? "Once a homeowner accepts a pairing or you complete your first visit, the home shows up here and you'll see their visits, systems, and shared files in one place."
                                : "Try a different name or address."
                        )
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredHomes) { home in
                            NavigationLink {
                                HavenFieldHomeProfileView(home: home)
                            } label: {
                                FieldClientRow(
                                    home: home,
                                    upcomingVisitCount: upcomingVisitCount(for: home),
                                    openQuoteCount: openQuoteCount(for: home),
                                    openThreadCount: openThreadCount(for: home)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .padding(.bottom, 40)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var homeCountLabel: String {
        let count = sortedHomes.count
        if count == 0 { return "No homes" }
        if count == 1 { return "1 home" }
        return "\(count) homes"
    }

    private func upcomingVisitCount(for home: HavenFieldHome) -> Int {
        (viewModel.dashboard?.visits ?? []).filter {
            $0.propertyId == home.propertyId && ($0.belongsInUpcomingQueue || $0.belongsInRequestQueue)
        }.count
    }

    private func openQuoteCount(for home: HavenFieldHome) -> Int {
        (viewModel.dashboard?.visits ?? []).filter {
            $0.propertyId == home.propertyId && $0.quote != nil
        }.count
    }

    private func openThreadCount(for home: HavenFieldHome) -> Int {
        (viewModel.dashboard?.messages ?? []).filter {
            $0.propertyId == home.propertyId
        }.count
    }
}

/// Phase 78: tappable punch list row. Tap toggles status between
/// pending and done via the edge function. Shows a system-link chip
/// when the item is linked to a `home_systems` row, an "Added after
/// lock" badge when the homeowner inserted the item after the visit
/// was confirmed, an estimated-minutes label, and a strikethrough on
/// done. Renders dimmed while a status mutation is in flight.
private struct FieldPunchItemRow: View {
    let item: HavenFieldPunchItem
    let isPending: Bool
    let onToggleDone: () -> Void

    private var isDone: Bool { item.status == "done" }

    var body: some View {
        Button(action: onToggleDone) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? HavenColors.success : HavenColors.beige400)
                    .font(.system(size: 22))
                    .opacity(isPending ? 0.5 : 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .strikethrough(isDone, color: HavenColors.textSecondary)

                    HStack(spacing: 8) {
                        if let minutes = item.estimatedMinutes {
                            Label("~\(minutes) min", systemImage: "clock")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .labelStyle(.titleAndIcon)
                        }
                        if let systemLabel = item.systemDisplayLabel {
                            Label(systemLabel, systemImage: "wrench.and.screwdriver.fill")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.navy700)
                                .labelStyle(.titleAndIcon)
                        }
                        if item.materialRequired {
                            Label("Materials", systemImage: "shippingbox.fill")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.action)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    if item.addedAfterLock {
                        Label("Added by homeowner after you confirmed", systemImage: "exclamationmark.triangle.fill")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                            .labelStyle(.titleAndIcon)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 8)

                if isPending {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(14)
            .background(isDone ? HavenColors.success.opacity(0.05) : HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDone ? HavenColors.success.opacity(0.25) : HavenColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(isPending ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isPending)
    }
}

private struct FieldClientRow: View {
    let home: HavenFieldHome
    let upcomingVisitCount: Int
    let openQuoteCount: Int
    let openThreadCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(HavenColors.navy800.opacity(0.08))
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HavenColors.navy800)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(home.name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(home.address)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    if upcomingVisitCount > 0 {
                        FieldClientBadge(
                            icon: "calendar.badge.clock",
                            label: "\(upcomingVisitCount) upcoming",
                            tint: HavenColors.action
                        )
                    }
                    if openQuoteCount > 0 {
                        FieldClientBadge(
                            icon: "doc.text",
                            label: "\(openQuoteCount) quote\(openQuoteCount == 1 ? "" : "s")",
                            tint: HavenColors.navy700
                        )
                    }
                    if openThreadCount > 0 {
                        FieldClientBadge(
                            icon: "bubble.left.fill",
                            label: "\(openThreadCount)",
                            tint: HavenColors.navy700
                        )
                    }
                    if upcomingVisitCount == 0 && openQuoteCount == 0 && openThreadCount == 0 {
                        Text("No active work")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 6)
        }
        .padding(16)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct FieldClientBadge: View {
    let icon: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(HavenTypography.uiLabelSmall)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

private struct HavenFieldMessagesTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @State private var composeHome: HavenFieldHome?
    @State private var showHomePicker = false

    private var sortedThreads: [HavenFieldMessageThread] {
        (viewModel.dashboard?.messages ?? [])
            .sorted { String($1.latestMessageAt ?? "") < String($0.latestMessageAt ?? "") }
    }

    private var filteredThreads: [HavenFieldMessageThread] {
        switch viewModel.messageFilter {
        case .all:
            return sortedThreads
        case .unread:
            return sortedThreads.filter(\.fieldNeedsAttention)
        case .quotes:
            return sortedThreads.filter { $0.quote != nil }
        case .scheduling:
            return sortedThreads.filter(\.isSchedulingThread)
        }
    }

    private func thread(for home: HavenFieldHome) -> HavenFieldMessageThread? {
        sortedThreads.first { $0.propertyId == home.propertyId }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Messages")
                            .font(HavenTypography.title)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.indigo50)
                            .clipShape(Circle())
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(HavenFieldMessageFilter.allCases) { filter in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        viewModel.messageFilter = filter
                                    }
                                } label: {
                                    FieldMessageFilterChip(
                                        title: filter.rawValue,
                                        count: count(for: filter),
                                        isSelected: viewModel.messageFilter == filter
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    FieldSectionCard(kicker: "Collaboration", title: "Homeowner threads") {
                        if filteredThreads.isEmpty {
                            FieldEmptyState(
                                title: "No homeowner threads yet",
                                subtitle: viewModel.dashboard?.homes.isEmpty == true
                                    ? "Once a homeowner connects this handyman in Chez, conversations will show up here."
                                    : "Messages, quote replies, and scheduling notes will land here."
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredThreads) { thread in
                                    NavigationLink {
                                        HavenFieldMessageThreadView(
                                            thread: thread,
                                            workspaceId: viewModel.dashboard?.workspace?.id,
                                            relatedVisit: viewModel.dashboard?.visits.first(where: { $0.requestId == thread.requestId }),
                                            relatedHome: viewModel.dashboard?.homes.first(where: { $0.propertyId == thread.propertyId }),
                                            onRealtimeUpdate: { [weak viewModel] in
                                                await viewModel?.refresh()
                                            }
                                        )
                                    } label: {
                                        FieldMessageThreadRow(thread: thread)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 140)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)

            if !(viewModel.dashboard?.homes ?? []).isEmpty {
                FieldFloatingActionButton(label: "New message", systemImage: "plus") {
                    showHomePicker = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 36)
            }
        }
        .sheet(item: $composeHome) { home in
            HavenFieldOutboundMessageComposer(
                home: home,
                existingThread: thread(for: home),
                workspaceId: viewModel.dashboard?.workspace?.id,
                onSent: {
                    await viewModel.refresh()
                }
            )
        }
        .sheet(isPresented: $showHomePicker) {
            HavenFieldHomePickerSheet(
                homes: viewModel.dashboard?.homes ?? [],
                title: "Start a new message",
                subtitle: "Choose a connected home so the conversation stays tied to the right service record."
            ) { home in
                composeHome = home
            }
        }
    }

    private func count(for filter: HavenFieldMessageFilter) -> Int {
        switch filter {
        case .all:
            return sortedThreads.count
        case .unread:
            return sortedThreads.filter(\.fieldNeedsAttention).count
        case .quotes:
            return sortedThreads.filter { $0.quote != nil }.count
        case .scheduling:
            return sortedThreads.filter(\.isSchedulingThread).count
        }
    }
}

private struct HavenFieldVisitWorkspaceView: View {
    @ObservedObject var viewModel: HavenFieldVisitWorkspaceModel
    @State private var showCoordinationComposer = false
    @State private var coordinationMode: String = "ask_question"
    @State private var coordinationMessage = ""
    @State private var proposedDate = ""
    @State private var showMessageComposer = false
    @State private var messageBody = ""
    @State private var showRescheduleSheet = false
    @State private var rescheduleDate: Date = Date().addingTimeInterval(60 * 60 * 24)
    @State private var rescheduleNote = ""
    @State private var showDeclineConfirmation = false
    @State private var captureTargetIndex: Int?
    @State private var showCamera = false
    @State private var showAddSystemCamera = false
    @State private var selectedSystem: HavenFieldSystemSnapshot?
    /// Phase 78: items currently mid-flight on the toggle-done network
    /// call. Lets the row show a spinner / dimmed state without an
    /// optimistic mutation that would race with the server response.
    @State private var pendingItemIds: Set<String> = []
    /// Local override map so a successful toggle reads as 'done' until
    /// the parent dashboard refresh comes back with the new server state.
    @State private var locallyDoneItemIds: Set<String> = []

    /// Phase 78: toggles a punch item between pending and done. Hits the
    /// `update_punch_item_status` edge action; on success, posts
    /// `.havenFieldVisitChanged` so the dashboard refreshes and the
    /// canonical state propagates back. Optimistic locally for snappy UI.
    private func togglePunchItem(_ item: HavenFieldPunchItem) async {
        guard !pendingItemIds.contains(item.id) else { return }
        let isCurrentlyDone = locallyDoneItemIds.contains(item.id) || item.status == "done"
        let newStatus = isCurrentlyDone ? "pending" : "done"

        pendingItemIds.insert(item.id)
        defer { pendingItemIds.remove(item.id) }

        do {
            try await HavenFieldService.shared.updatePunchItemStatus(itemId: item.id, status: newStatus)
            if newStatus == "done" {
                locallyDoneItemIds.insert(item.id)
            } else {
                locallyDoneItemIds.remove(item.id)
            }
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            print("[HavenFieldVisitWorkspaceView] togglePunchItem failed: \(error)")
        }
    }

    private var defaultRescheduleDate: Date {
        if let dateString = viewModel.visit.routeDate ?? viewModel.visit.visit?.scheduledDate,
           let parsed = DateFormatter.havenISODate.date(from: dateString) {
            // Default to a day later than the currently-scheduled visit so
            // the picker starts at a sensible "next attempt" anchor.
            return Calendar.current.date(byAdding: .day, value: 1, to: parsed) ?? parsed
        }
        return Date().addingTimeInterval(60 * 60 * 24)
    }

    /// The visit's punch list — parsed from the parent maintenance_task's
    /// notes via the same `VisitNotesParser` the homeowner chat sheet and
    /// the Operations Desk use. This is the SOURCE OF TRUTH for what the
    /// Phase 78: structured punch list rows for THIS visit, served by
    /// the `handyman-provider` edge function as `visit.punchItems`. The
    /// SOURCE OF TRUTH on both this app and the desktop Operations Desk.
    ///
    /// Falls back to legacy `VisitNotesParser` parsing only when the
    /// dashboard hasn't migrated yet (e.g., a stale-cached visit before
    /// the server roll-out propagates). Once Phase 78 backfill has
    /// shipped to all environments, the fallback can be deleted.
    private var punchItems: [HavenFieldPunchItem] {
        if !viewModel.visit.punchItems.isEmpty {
            return viewModel.visit.punchItems
        }
        // Legacy fallback — synthesize ephemeral rows from notes so a
        // pre-Phase-78 dashboard response still renders something.
        let primary = viewModel.visit.visit?.notes?.trimmedOrNil ?? ""
        let secondary = viewModel.visit.visit?.description?.trimmedOrNil ?? ""
        let source = primary.isEmpty ? secondary : primary
        guard !source.isEmpty else { return [] }
        let parsed = VisitNotesParser.parsePunchList(from: source)
        return parsed.map { child in
            HavenFieldPunchItem.legacyEphemeral(
                id: child.id,
                title: child.title,
                estimatedMinutes: child.estimatedMinutes
            )
        }
    }

    /// Punch list grouped into the same physical-zone categories the
    /// desktop Operations Desk uses (`website/operations/src/lib/api.ts`'s
    /// `categorizePunchItem`). Lets the handyman knock out a whole zone
    /// before moving to the next one — the same flow as desktop.
    private var groupedPunchList: [(category: FieldPunchCategory, items: [HavenFieldPunchItem])] {
        guard !punchItems.isEmpty else { return [] }
        var buckets: [FieldPunchCategory: [HavenFieldPunchItem]] = [:]
        for item in punchItems {
            let cat = FieldPunchCategory.categorize(item.title)
            buckets[cat, default: []].append(item)
        }
        return FieldPunchCategory.allCases
            .compactMap { cat in
                guard let items = buckets[cat], !items.isEmpty else { return nil }
                return (category: cat, items: items)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if let errorMessage = viewModel.errorMessage {
                    FieldErrorBanner(message: errorMessage)
                }

                Picker("Visit tab", selection: $viewModel.selectedTab) {
                    ForEach(HavenFieldVisitWorkspaceModel.VisitTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                tabContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle(viewModel.visit.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Message") {
                    showMessageComposer = true
                }
                .foregroundStyle(HavenColors.action)
            }
        }
        .sheet(isPresented: $showCoordinationComposer) {
            HavenFieldCoordinationComposer(
                mode: coordinationMode,
                message: $coordinationMessage,
                proposedDate: $proposedDate,
                onSubmit: {
                    Task {
                        await viewModel.performCoordination(type: coordinationMode, message: coordinationMessage, proposedDate: proposedDate)
                        coordinationMessage = ""
                        proposedDate = ""
                        showCoordinationComposer = false
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMessageComposer) {
            HavenFieldMessageComposer(
                messageBody: $messageBody,
                onSend: {
                    Task {
                        try? await viewModel.sendMessage(messageBody)
                        messageBody = ""
                        showMessageComposer = false
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedSystem) { system in
            HavenFieldSystemDetailSheet(system: system)
        }
        .sheet(isPresented: $showCamera) {
            HavenFieldCameraPicker { image in
                guard let data = image.jpegData(compressionQuality: 0.82), let target = captureTargetIndex else { return }
                Task { await viewModel.identifySystem(index: target, imageData: data) }
            }
        }
        .sheet(isPresented: $showAddSystemCamera) {
            HavenFieldCameraPicker { image in
                guard let data = image.jpegData(compressionQuality: 0.82) else { return }
                Task { await viewModel.addSystemFromPhoto(imageData: data) }
            }
        }
        .sheet(isPresented: $showRescheduleSheet) {
            HavenFieldRescheduleSheet(
                date: $rescheduleDate,
                note: $rescheduleNote,
                isSubmitting: viewModel.isSyncing,
                onSubmit: {
                    let iso = ISO8601DateFormatter().string(from: rescheduleDate)
                    Task {
                        await viewModel.performCoordination(
                            type: "propose_other_dates",
                            message: rescheduleNote,
                            proposedDate: iso
                        )
                        rescheduleNote = ""
                        showRescheduleSheet = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Decline this visit?",
            isPresented: $showDeclineConfirmation,
            titleVisibility: .visible
        ) {
            Button("Decline visit", role: .destructive) {
                Task {
                    await viewModel.performCoordination(type: "decline_visit", message: nil, proposedDate: nil)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The homeowner will be notified that you can't take this visit. You can leave them a note from Messages first if you want to explain.")
        }
    }

    private var headerCard: some View {
        FieldSectionCard(
            kicker: "Visit",
            title: viewModel.visit.property?.name ?? viewModel.visit.title,
            inverse: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                FieldKeyValueRow(label: "Scheduled", value: routeSummary, inverse: true)
                FieldKeyValueRow(label: "Status", value: viewModel.statusLabel, inverse: true)
                if let address = viewModel.visit.property?.address, !address.isEmpty {
                    FieldKeyValueRow(label: "Address", value: address, inverse: true)
                }
                if let notes = viewModel.visit.assignment?.routeNotes, !notes.isEmpty {
                    FieldKeyValueRow(label: "Route notes", value: notes, inverse: true)
                }
                Text(viewModel.syncMessage)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.8))

                actionRow
            }
        }
    }

    private var actionRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            if needsConfirmation {
                HStack(spacing: 10) {
                    Button(viewModel.isSyncing ? "Confirming…" : "Confirm") {
                        Task { await viewModel.performCoordination(type: "confirm_date", message: nil, proposedDate: nil) }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(viewModel.isSyncing)

                    Button("Reschedule") {
                        rescheduleDate = defaultRescheduleDate
                        showRescheduleSheet = true
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())
                    .disabled(viewModel.isSyncing)
                }

                HStack(spacing: 10) {
                    Button("Ask question") {
                        messageBody = ""
                        showMessageComposer = true
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())
                    .disabled(viewModel.isSyncing)

                    Button("Decline") {
                        showDeclineConfirmation = true
                    }
                    .buttonStyle(FieldGhostButtonStyle())
                    .disabled(viewModel.isSyncing)
                }
            } else if viewModel.requestStatus == HandymanRequestStatus.confirmed.rawValue {
                Button("On my way") {
                    Task { await viewModel.markOnMyWay() }
                }
                .buttonStyle(FieldPrimaryButtonStyle())
            } else if viewModel.requestStatus == HandymanRequestStatus.onMyWay.rawValue {
                Button("Check in") {
                    Task { await viewModel.checkIn() }
                }
                .buttonStyle(FieldPrimaryButtonStyle())
            } else {
                HStack(spacing: 10) {
                    Button("Sync now") {
                        Task { await viewModel.syncNow() }
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())

                    Button("Complete visit") {
                        Task { await viewModel.completeVisit() }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(viewModel.draft?.reportStatus == "completed")
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .home:
            homeTab
        case .visit:
            visitTab
        case .systems:
            systemsTab
        case .files:
            filesTab
        }
    }

    private var homeTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldSectionCard(kicker: "Home", title: "House context") {
                VStack(alignment: .leading, spacing: 10) {
                    FieldKeyValueRow(label: "Type", value: viewModel.payload?.session.seedPayload.property.propertyType ?? "Home")
                    FieldKeyValueRow(label: "Known systems", value: "\(viewModel.home?.systems.count ?? viewModel.draft?.systemsSnapshot.count ?? 0)")
                    FieldKeyValueRow(label: "Open work", value: "\(viewModel.home?.openTasks.count ?? 0) items")
                    if let homeownerNotes = viewModel.payload?.session.seedPayload.homeownerNotes, !homeownerNotes.isEmpty {
                        FieldKeyValueRow(label: "Homeowner note", value: homeownerNotes)
                    }
                    if let home = viewModel.home {
                        NavigationLink {
                            HavenFieldHomeProfileView(home: home)
                        } label: {
                            Text("Open home profile")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.action)
                        }
                    }
                }
            }

            FieldSectionCard(kicker: "Recent", title: "Visits at this home") {
                if let recentVisits = viewModel.home?.recentVisits, !recentVisits.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(recentVisits) { visit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text([visit.routeDate?.fieldShortDate, visit.statusLabel].compactMap { $0 }.joined(separator: " • "))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                } else {
                    FieldEmptyState(title: "No visit history yet", subtitle: "Completed visits will start building the service record for this home.")
                }
            }

            FieldSectionCard(kicker: "Open work", title: "Tasks Chez sees for this house") {
                if let openTasks = viewModel.home?.openTasks, !openTasks.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(openTasks) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text([task.dueDate?.fieldShortDate, task.priority?.capitalized].compactMap { $0 }.joined(separator: " • "))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                } else {
                    FieldEmptyState(title: "No additional open tasks", subtitle: "As the homeowner’s maintenance list evolves, Chez will surface tasks you can handle while you’re already here.")
                }
            }
        }
    }

    private var visitTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldSectionCard(kicker: "Checklist", title: "Execute the visit") {
                VStack(spacing: 12) {
                    if let draftChecklist = viewModel.draft?.checklist, !draftChecklist.isEmpty {
                        ForEach(draftChecklist) { item in
                            Button {
                                viewModel.toggleChecklist(item)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.status == "done" ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.status == "done" ? HavenColors.success : HavenColors.beige400)
                                        .font(.system(size: 22))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.title)
                                            .font(HavenTypography.headline)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if let subtitle = item.subtitle, !subtitle.isEmpty {
                                            Text(subtitle)
                                                .font(HavenTypography.bodySmall)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Text(item.source == "punch_list" ? "Punch list" : "Visit")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.action)
                                }
                                .padding(14)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    } else if !punchItems.isEmpty {
                        // Phase 78: structured punch items from the server
                        // (handyman-provider edge function). Same SOURCE
                        // OF TRUTH the desktop Operations Desk reads. Each
                        // item is checkable — tap writes status='done' via
                        // update_punch_item_status, which trips the DB
                        // trigger that bumps home_systems.last_service_date
                        // when the item is system-linked. Categorization
                        // mirrors PUNCH_CATEGORIES on the web side so the
                        // outside → up → in → safety walkaround order
                        // stays consistent across surfaces.
                        ForEach(groupedPunchList, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: group.category.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(HavenColors.action)
                                    Text(group.category.label.uppercased())
                                        .font(HavenTypography.uiSectionHeader)
                                        .kerning(1.2)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    Spacer()
                                    Text("\(group.items.count)")
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                .padding(.top, group.category == groupedPunchList.first?.category ? 0 : 4)

                                VStack(spacing: 8) {
                                    ForEach(group.items) { item in
                                        FieldPunchItemRow(
                                            item: item,
                                            isPending: pendingItemIds.contains(item.id),
                                            onToggleDone: { Task { await togglePunchItem(item) } }
                                        )
                                    }
                                }
                            }
                        }
                        Text("Tap an item to mark it done. Chez updates the homeowner instantly and stamps the system's last-serviced date.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    } else {
                        FieldEmptyState(
                            title: "No tasks captured yet",
                            subtitle: "When you check in, this becomes the live checklist for the visit. Until then, the homeowner's open work shows up here once it's posted."
                        )
                    }
                }
            }

            FieldSectionCard(kicker: "Recommendations", title: "What else should the homeowner do?") {
                VStack(spacing: 12) {
                    ForEach(viewModel.draft?.recommendations ?? []) { item in
                        Button {
                            viewModel.toggleRecommendation(item)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: (item.createFollowUp ?? false) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle((item.createFollowUp ?? false) ? HavenColors.action : HavenColors.beige400)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(HavenTypography.headline)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    if let detail = item.detail, !detail.isEmpty {
                                        Text(detail)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                                Spacer()
                                Text((item.priority ?? "normal").capitalized)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            FieldSectionCard(kicker: "Notes", title: "What should Chez remember?") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Field notes")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextEditor(text: Binding(
                        get: { viewModel.draft?.fieldNotes ?? "" },
                        set: { viewModel.updateFieldNotes($0) }
                    ))
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Text("Homeowner notes")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextEditor(text: Binding(
                        get: { viewModel.draft?.homeownerNotes ?? "" },
                        set: { viewModel.updateHomeownerNotes($0) }
                    ))
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var systemsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let homeSystems = viewModel.home?.systems, !homeSystems.isEmpty {
                // The same systems list the homeowner sees in their property
                // detail. Tap any row to open the system sheet (model, manual,
                // service history). When the visit becomes live, this still
                // shows but the "Map the house" capture flow takes over for
                // adding/identifying new systems.
                FieldSectionCard(
                    kicker: "Systems · \(homeSystems.count)",
                    title: "What's already at this home"
                ) {
                    VStack(spacing: 12) {
                        ForEach(homeSystems) { system in
                            Button {
                                selectedSystem = HavenFieldSystemSnapshot(
                                    id: system.id,
                                    systemId: system.id,
                                    name: system.name,
                                    category: system.category ?? "",
                                    manufacturer: system.manufacturer,
                                    modelNumber: system.modelNumber,
                                    serialNumber: system.serialNumber,
                                    installDate: system.installDate,
                                    notes: system.notes,
                                    lastServiceDate: system.lastServiceDate,
                                    nextServiceDue: system.nextServiceDue,
                                    status: system.status,
                                    subtype: system.subtype,
                                    catalogModelName: system.catalogModelName,
                                    catalogFeatures: system.catalogFeatures,
                                    catalogFuelType: system.catalogFuelType,
                                    catalogDisplayName: system.catalogModelName,
                                    reliabilityScore: system.reliabilityScore,
                                    scoreSummary: system.scoreSummary,
                                    cachedManualLinks: system.cachedManualLinks
                                )
                            } label: {
                                FieldCompactSystemRow(system: system)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if viewModel.payload?.session.seedPayload.firstVisit == true {
                FieldSectionCard(kicker: "Setup", title: "Leave this home easier to service next time") {
                    VStack(spacing: 12) {
                        ForEach(viewModel.draft?.setupPrompts ?? []) { prompt in
                            Button {
                                viewModel.toggleSetupPrompt(prompt)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: (prompt.done ?? false) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle((prompt.done ?? false) ? HavenColors.success : HavenColors.beige400)
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(prompt.title)
                                            .font(HavenTypography.headline)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if let detail = prompt.detail, !detail.isEmpty {
                                            Text(detail)
                                                .font(HavenTypography.bodySmall)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if prompt.isRequired == true {
                                        Text("Required")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.action)
                                    }
                                }
                                .padding(14)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            FieldSectionCard(kicker: "Capture", title: (viewModel.home?.systems.isEmpty ?? true) ? "Map the house while you're here" : "Found something new?") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Snap a label and Chez identifies the model, looks up the manual, and adds it to the home's profile.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)

                    Button("Add system from label photo") {
                        showAddSystemCamera = true
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())

                    ForEach(Array((viewModel.draft?.systemsSnapshot ?? []).enumerated()), id: \.element.id) { index, system in
                        FieldSystemCard(
                            system: system,
                            onCapture: {
                                captureTargetIndex = index
                                showCamera = true
                            },
                            onOpenDetail: {
                                selectedSystem = system
                            }
                        )
                    }
                }
            }
        }
    }

    private var filesTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldSectionCard(kicker: "Capture", title: "Add a photo to this home") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Snap a label, a finished install, or anything worth remembering. Chez identifies systems automatically and threads everything into the home's profile.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    Button {
                        showAddSystemCamera = true
                    } label: {
                        Label("Take a photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                }
            }

            FieldSectionCard(kicker: "Shared files", title: "What’s already on this home") {
                if let files = viewModel.home?.files, !files.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(files) { file in
                            if let urlString = file.signedURL, let url = URL(string: urlString) {
                                Link(destination: url) {
                                    FieldFileRow(file: file)
                                }
                            } else {
                                FieldFileRow(file: file)
                            }
                        }
                    }
                } else {
                    FieldEmptyState(title: "No shared files yet", subtitle: "Homeowner-shared documents, manuals, and photos will appear here as the relationship deepens.")
                }
            }

            FieldSectionCard(kicker: "Captured today", title: "Label photos and field evidence") {
                let captured = (viewModel.draft?.systemsSnapshot ?? []).filter { ($0.labelPhotoName ?? "").isEmpty == false || ($0.photoCapturedAt ?? "").isEmpty == false }
                if captured.isEmpty {
                    FieldEmptyState(title: "No photos captured yet", subtitle: "Every label photo you take starts building the house profile for future visits.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(captured) { system in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(system.name)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text([system.labelPhotoName, system.photoCapturedAt?.fieldDateTime].compactMap { $0 }.joined(separator: " • "))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
            }
        }
    }

    private var needsConfirmation: Bool {
        [
            HandymanRequestStatus.submitted.rawValue,
            HandymanRequestStatus.sentToHandyman.rawValue,
            HandymanRequestStatus.alternateDatesProposed.rawValue,
            HandymanRequestStatus.awaitingHomeowner.rawValue,
            HandymanRequestStatus.scheduled.rawValue
        ].contains(viewModel.requestStatus)
    }

    private var routeSummary: String {
        let date = (viewModel.visit.assignment?.routeDate ?? viewModel.visit.routeDate ?? viewModel.visit.visit?.scheduledDate)?.fieldShortDate
        let window = [viewModel.visit.assignment?.windowStartTime, viewModel.visit.assignment?.windowEndTime]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " to ")
        return [date, window.isEmpty ? nil : window].compactMap { $0 }.joined(separator: " • ").nonEmpty ?? "TBD"
    }
}

private struct HavenFieldHomeProfileView: View {
    let home: HavenFieldHome
    @State private var selectedTab: HomeProfileTab = .home
    @State private var selectedSystem: HavenFieldHomeSystem?

    enum HomeProfileTab: String, CaseIterable {
        case home = "Home"
        case systems = "Systems"
        case files = "Files"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Home profile", selection: $selectedTab) {
                    ForEach(HomeProfileTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .home:
                    homeTab
                case .systems:
                    systemsTab
                case .files:
                    filesTab
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle(home.name)
        .sheet(item: $selectedSystem) { system in
            HavenFieldHomeSystemDetailSheet(system: system)
        }
    }

    private var homeTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldSectionCard(kicker: "Home", title: home.name) {
                VStack(alignment: .leading, spacing: 10) {
                    FieldKeyValueRow(label: "Address", value: home.address)
                    FieldKeyValueRow(label: "Systems", value: "\(home.systemCount)")
                    FieldKeyValueRow(label: "Outstanding work", value: "\(home.openTasks.count)")
                    if let lastCompletedVisit = home.lastCompletedVisit?.fieldDateTime {
                        FieldKeyValueRow(label: "Last completed visit", value: lastCompletedVisit)
                    }
                }
            }

            FieldSectionCard(kicker: "Recent", title: "Visits at this home") {
                if home.recentVisits.isEmpty {
                    FieldEmptyState(title: "No visit history yet", subtitle: "Completed and upcoming visits will show up here as the relationship builds.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(home.recentVisits) { visit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text([visit.routeDate?.fieldShortDate, visit.statusLabel, visit.completedAt?.fieldDateTime].compactMap { $0 }.joined(separator: " • "))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
            }

            FieldSectionCard(kicker: "Open work", title: "Tasks Chez sees for this house") {
                if home.openTasks.isEmpty {
                    FieldEmptyState(title: "No open tasks right now", subtitle: "As the homeowner’s maintenance list changes, Chez will surface the jobs you can handle while you’re there.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(home.openTasks) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(
                                    [
                                        task.dueDate?.fieldShortDate,
                                        task.priority?.capitalized,
                                        task.assignmentType?.replacingOccurrences(of: "_", with: " ").capitalized
                                    ]
                                        .compactMap { $0 }
                                        .joined(separator: " • ")
                                )
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
            }
        }
    }

    private var systemsTab: some View {
        FieldSectionCard(kicker: "Systems", title: "Known systems") {
            if home.systems.isEmpty {
                FieldEmptyState(title: "No systems shared yet", subtitle: "Once the homeowner grants access and the first visit captures labels, systems will appear here.")
            } else {
                VStack(spacing: 12) {
                    ForEach(home.systems) { system in
                        Button {
                            selectedSystem = system
                        } label: {
                            FieldCompactSystemRow(system: system)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filesTab: some View {
        FieldSectionCard(kicker: "Files", title: "Shared documents and photos") {
            if home.files.isEmpty {
                FieldEmptyState(title: "No shared files yet", subtitle: "Homeowner documents, manuals, labels, and field photos will appear here.")
            } else {
                VStack(spacing: 12) {
                    ForEach(home.files) { file in
                        if let urlString = file.signedURL, let url = URL(string: urlString) {
                            Link(destination: url) {
                                FieldFileRow(file: file)
                            }
                        } else {
                            FieldFileRow(file: file)
                        }
                    }
                }
            }
        }
    }
}

private struct HavenFieldMessageThreadView: View {
    let thread: HavenFieldMessageThread
    let workspaceId: String?
    let relatedVisit: HavenFieldVisit?
    let relatedHome: HavenFieldHome?
    /// Called when Realtime sees a new row land on this request's
    /// `handyman_request_messages` so the parent can refresh its
    /// dashboard and re-render the thread with the new messages.
    var onRealtimeUpdate: (() async -> Void)? = nil
    @State private var messageBody = ""
    @State private var isSending = false
    @State private var feedback: String?
    @State private var selectedStatus: String = ""

    private var orderedMessages: [HavenFieldThreadMessage] {
        thread.recentMessages.sorted { lhs, rhs in
            let l = lhs.createdAt.flatMap(HavenFieldDateParser.parse) ?? .distantPast
            let r = rhs.createdAt.flatMap(HavenFieldDateParser.parse) ?? .distantPast
            return l < r
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            threadHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if orderedMessages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundStyle(HavenColors.textSecondary.opacity(0.6))
                                Text("Start the conversation")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Send a quick message to confirm timing, ask a question, or share an update from the field.")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(orderedMessages) { message in
                                FieldChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .onAppear {
                    if let last = orderedMessages.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }
                .onChange(of: orderedMessages.count) { _, _ in
                    if let last = orderedMessages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            composer
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle(thread.propertyName ?? thread.title)
        .navigationBarTitleDisplayMode(.inline)
        // Hide the floating tab bar while reading or composing in a thread —
        // pre-Wave-1b the bar overlapped the message composer so the Send
        // affordance was clipped and the textarea was barely usable.
        .toolbar(.hidden, for: .tabBar)
        .task {
            await subscribeToRealtime()
        }
    }

    private var threadHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if let address = thread.propertyAddress, !address.isEmpty {
                        Text(address)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 12)
                Text(thread.statusLabel ?? thread.status ?? "Open")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(HavenColors.navy700.opacity(0.10))
                    .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                if let relatedVisit {
                    NavigationLink {
                        HavenFieldVisitWorkspaceView(
                            viewModel: HavenFieldVisitWorkspaceModel(
                                visit: relatedVisit,
                                home: relatedHome,
                                workspaceId: workspaceId
                            )
                        )
                    } label: {
                        Label("Visit", systemImage: "calendar.badge.clock")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.action)
                    }
                }
                if let relatedHome {
                    NavigationLink {
                        HavenFieldHomeProfileView(home: relatedHome)
                    } label: {
                        Label("Home", systemImage: "house")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.action)
                    }
                }
                if let urlString = thread.quote?.publicShareUrl, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Quote", systemImage: "doc.text.magnifyingglass")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.action)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            HavenColors.surface
                .overlay(
                    Rectangle()
                        .fill(HavenColors.border)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        )
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let feedback {
                Text(feedback)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if messageBody.isEmpty {
                        Text("Send a message…")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                    }
                    TextField("", text: $messageBody, axis: .vertical)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .lineLimit(1...5)
                }
                .background(HavenColors.creamLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))

                Button {
                    Task { await sendMessage() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? HavenColors.action : HavenColors.action.opacity(0.4))
                        Image(systemName: isSending ? "hourglass" : "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HavenColors.textOnAction)
                    }
                    .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .disabled(!canSend || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .padding(.top, 10)
        .background(HavenColors.surface.ignoresSafeArea(edges: .bottom))
        .overlay(
            Rectangle()
                .fill(HavenColors.border)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }

    private var canSend: Bool {
        !messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Open a Realtime subscription scoped to this thread's `request_id`.
    /// Whenever a new `handyman_request_messages` row lands, fire the
    /// parent's refresh callback so the dashboard re-fetches and the
    /// thread re-renders with the inbound message. Stays open while the
    /// view is on screen; the channel is unsubscribed on `.task`'s
    /// cancellation when the view disappears.
    private func subscribeToRealtime() async {
        guard let onRealtimeUpdate else { return }
        let channelName = "ops-thread-\(thread.requestId)"
        let channel = HavenSupabase.client.realtimeV2.channel(channelName)
        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "handyman_request_messages",
            filter: .eq("request_id", value: thread.requestId)
        )
        do {
            try await channel.subscribeWithError()
        } catch {
            print("[HavenFieldMessageThreadView] Realtime subscribe failed: \(error)")
            return
        }
        defer {
            Task { await channel.unsubscribe() }
        }
        for await _ in inserts {
            await onRealtimeUpdate()
        }
    }

    private func sendMessage() async {
        guard let workspaceId else { return }
        isSending = true
        defer { isSending = false }
        do {
            _ = try await HavenFieldService.shared.sendMessage(
                workspaceId: workspaceId,
                requestId: thread.requestId,
                body: messageBody,
                status: selectedStatus.trimmedOrNil
            )
            feedback = "Message sent to the homeowner"
            messageBody = ""
            selectedStatus = ""
        } catch {
            feedback = error.localizedDescription
        }
    }
}

/// Chat bubble for the field-side message thread. Mirrors the homeowner
/// `HandymanChatSheet.MessageBubble` style: salmon-fill right-aligned
/// for "you" (vendor / handyman), white surface left-aligned for the
/// homeowner. Sender label sits above the bubble; relative timestamp
/// reads beneath in a muted tone.
private struct FieldChatBubble: View {
    let message: HavenFieldThreadMessage

    private var isFromVendor: Bool {
        // "vendor", "owner", "admin", "dispatcher", "technician" all
        // resolve as field-side. Only the homeowner's posts stay left-
        // aligned.
        guard let role = message.senderRole?.lowercased() else { return true }
        return !role.contains("home") && !role.contains("client") && !role.contains("customer")
    }

    private var senderLabel: String {
        if isFromVendor { return "You" }
        if let role = message.senderRole, !role.isEmpty {
            return role.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return "Homeowner"
    }

    private var bubbleBackground: Color {
        // Vendor-side (You) bubbles use navy ink to keep salmon reserved
        // for primary CTAs per CLAUDE.md hard rule (B1 salmon discipline).
        // Pre-Wave 1b this rendered as HavenColors.action which made every
        // own-side message feel like a CTA and diluted the FAB / Send-button
        // hierarchy.
        isFromVendor ? HavenColors.navy800 : HavenColors.surface
    }

    private var bubbleForeground: Color {
        isFromVendor ? Color.white : HavenColors.textPrimary
    }

    private var timestampLabel: String {
        message.createdAt?.fieldRelativeTime ?? ""
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isFromVendor {
                Spacer(minLength: 56)
                bubbleStack
            } else {
                bubbleStack
                Spacer(minLength: 56)
            }
        }
    }

    private var bubbleStack: some View {
        VStack(alignment: isFromVendor ? .trailing : .leading, spacing: 4) {
            Text(senderLabel.uppercased())
                .font(HavenTypography.uiLabelSmall)
                .kerning(0.8)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.horizontal, 4)

            VStack(alignment: isFromVendor ? .trailing : .leading, spacing: 4) {
                Text(message.body ?? "")
                    .font(HavenTypography.body)
                    .foregroundStyle(bubbleForeground)
                    .multilineTextAlignment(isFromVendor ? .trailing : .leading)

                if !timestampLabel.isEmpty {
                    Text(timestampLabel)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(bubbleForeground.opacity(0.65))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(bubbleBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFromVendor ? Color.clear : HavenColors.border, lineWidth: 1)
            )
        }
    }
}

private struct HavenFieldOutboundMessageComposer: View {
    let home: HavenFieldHome
    let existingThread: HavenFieldMessageThread?
    let workspaceId: String?
    let onSent: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var messageBody = ""
    @State private var status: String = HandymanRequestStatus.awaitingHomeowner.rawValue
    @State private var isSending = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Outreach",
                        title: home.name,
                        subtitle: "Send a scheduling note, visit update, or quick follow-up directly to this homeowner."
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(home.address)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textOnAction.opacity(0.88))
                            Text(existingThread == nil ? "This starts a new Chez Field thread for the home." : "This continues the existing homeowner thread and keeps the history together.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textOnAction.opacity(0.78))
                        }
                    }

                    if let thread = existingThread, let quote = thread.quote, quote.status != "draft" {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "doc.badge.arrow.up")
                                .foregroundStyle(HavenColors.action)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Latest quote can go with this update")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("When you send this note, Chez can keep the latest quote link close to the homeowner conversation.")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(HavenColors.action.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    FieldSectionCard(kicker: "Compose", title: "Message the homeowner") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status update")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textSecondary)
                                Picker("Status update", selection: $status) {
                                    Text("Reply needed").tag(HandymanRequestStatus.awaitingHomeowner.rawValue)
                                    Text("Confirmed").tag(HandymanRequestStatus.confirmed.rawValue)
                                    Text("On my way").tag(HandymanRequestStatus.onMyWay.rawValue)
                                    Text("Follow-up recommended").tag(HandymanRequestStatus.followUpRecommended.rawValue)
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            TextEditor(text: $messageBody)
                                .frame(minHeight: 150)
                                .padding(10)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                            if let feedback {
                                Text(feedback)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Button(isSending ? "Sending..." : "Send update") {
                                Task { await send() }
                            }
                            .buttonStyle(FieldPrimaryButtonStyle())
                            .disabled(isSending || messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("New update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        guard let workspaceId else { return }
        isSending = true
        defer { isSending = false }

        do {
            _ = try await HavenFieldService.shared.sendMessage(
                workspaceId: workspaceId,
                requestId: existingThread?.requestId,
                propertyId: home.propertyId,
                body: messageBody,
                status: status.trimmedOrNil,
                threadTitle: "Update for \(home.name)"
            )
            await onSent()
            dismiss()
        } catch {
            feedback = error.localizedDescription
        }
    }
}

private struct HavenFieldHomePickerSheet: View {
    let homes: [HavenFieldHome]
    let title: String
    let subtitle: String
    let onSelect: (HavenFieldHome) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Homes",
                        title: title,
                        subtitle: subtitle
                    ) {
                        Text("\(homes.count) connected home\(homes.count == 1 ? "" : "s") ready")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textOnAction.opacity(0.82))
                    }

                    if homes.isEmpty {
                        FieldSectionCard(kicker: "Availability", title: "No connected homes yet") {
                            FieldEmptyState(
                                title: "No homes are linked to this handyman yet",
                                subtitle: "Once a homeowner selects this provider in Chez, or you start a pairing request from Visits, the home will appear here."
                            )
                        }
                    } else {
                        FieldSectionCard(kicker: "Choose", title: "Connected homes") {
                            VStack(spacing: 12) {
                                ForEach(homes) { home in
                                    Button {
                                        onSelect(home)
                                        dismiss()
                                    } label: {
                                        FieldHomeRow(home: home)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct HavenFieldAdHocVisitComposer: View {
    private enum VisitKind: String, CaseIterable, Identifiable {
        case standardVisit = "standard_visit"
        case repair = "repair"
        case install = "install"
        case quote = "quote"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .standardVisit: return "Standard visit"
            case .repair: return "Small repair"
            case .install: return "Install / upgrade"
            case .quote: return "Quote walkthrough"
            }
        }
    }

    let homes: [HavenFieldHome]
    let workspaceId: String?
    let onCreated: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedHomeId: String = ""
    @State private var title = ""
    @State private var details = ""
    @State private var scheduledDate = Date()
    @State private var visitKind: VisitKind = .standardVisit
    @State private var isSaving = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Visits",
                        title: "Create an ad hoc visit",
                        subtitle: "Add work that came together in the field and turn it into a real Chez Field visit with home context and a service record."
                    ) {
                        Text("Confirmed visits land in Upcoming and can be started right from the field app.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textOnAction.opacity(0.82))
                    }

                    if homes.isEmpty {
                        FieldSectionCard(kicker: "Need a home", title: "No connected homes yet") {
                            FieldEmptyState(
                                title: "Connect a home before you add a field visit",
                                subtitle: "Use the pairing request flow from Visits to connect a home that hasn't joined Chez yet."
                            )
                        }
                    } else {
                        FieldSectionCard(kicker: "Scope", title: "Visit details") {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Home")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    Picker("Home", selection: $selectedHomeId) {
                                        ForEach(homes) { home in
                                            Text(home.name).tag(home.propertyId)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(HavenColors.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Visit type")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    Picker("Visit type", selection: $visitKind) {
                                        ForEach(VisitKind.allCases) { kind in
                                            Text(kind.title).tag(kind)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Title")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    TextField("Adjust side gate latch", text: $title)
                                        .textFieldStyle(.plain)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(HavenColors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Scheduled date")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(HavenColors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Scope notes")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    TextEditor(text: $details)
                                        .frame(minHeight: 120)
                                        .padding(10)
                                        .background(HavenColors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                }

                                if let feedback {
                                    Text(feedback)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }

                                Button(isSaving ? "Creating..." : "Create visit") {
                                    Task { await createVisit() }
                                }
                                .buttonStyle(FieldPrimaryButtonStyle())
                                .disabled(isSaving || selectedHomeId.isEmpty || title.trimmedOrNil == nil)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("New visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedHomeId.isEmpty {
                    selectedHomeId = homes.first?.propertyId ?? ""
                }
                if title.isEmpty {
                    title = visitKind.title
                }
            }
            .onChange(of: visitKind) { _, newValue in
                if title == VisitKind.standardVisit.title ||
                    title == VisitKind.repair.title ||
                    title == VisitKind.install.title ||
                    title == VisitKind.quote.title {
                    title = newValue.title
                }
            }
        }
    }

    private func createVisit() async {
        guard let workspaceId, let resolvedTitle = title.trimmedOrNil else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await HavenFieldService.shared.createAdHocVisit(
                workspaceId: workspaceId,
                propertyId: selectedHomeId,
                title: resolvedTitle,
                details: details.trimmedOrNil ?? "",
                scheduledDate: DateFormatter.havenISODate.string(from: scheduledDate),
                requestType: visitKind.rawValue
            )
            await onCreated()
            dismiss()
        } catch {
            // Pre-Wave-1b this surfaced raw JSON like
            // {"error":"column properties.square_feet does not exist (42703)"}
            // to the user. Now it falls back to a friendly message and logs
            // the actual error for engineering. The Wave 1b square_feet bug
            // is fixed in handyman-provider edge function but other server
            // errors still need a graceful surface.
            print("[HavenFieldAdHocVisitComposer] createVisit failed: \(error)")
            let raw = error.localizedDescription.lowercased()
            if raw.contains("does not exist") || raw.contains("42703") || raw.contains("internal") {
                feedback = "Could not create the visit. Please try again or refresh."
            } else if raw.contains("network") || raw.contains("offline") {
                feedback = "Network error. Please check your connection."
            } else {
                feedback = "Could not create the visit. Please try again."
            }
        }
    }
}

private struct HavenFieldPairingRequestComposer: View {
    let workspaceId: String?
    let onCreated: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var homeName = ""
    @State private var homeownerName = ""
    @State private var homeownerEmail = ""
    @State private var homeownerPhone = ""
    @State private var addressLine = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var feedback: String?
    @State private var pairingRequest: HavenFieldPairingRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Pairing",
                        title: pairingRequest == nil ? "Start a home pairing" : "Share the Chez pairing",
                        subtitle: pairingRequest == nil
                            ? "Use this when you are already working with a home that is not yet fully connected to Chez."
                            : "The homeowner can use this code once they download Chez so the home and handyman relationship connect cleanly."
                    ) {
                        if let request = pairingRequest {
                            Text("Code: \(request.accessCode ?? "—")")
                                .font(HavenTypography.title2)
                                .foregroundStyle(HavenColors.textOnAction)
                        } else {
                            Text("Create a pairing code and share it by text or email from the field.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textOnAction.opacity(0.82))
                        }
                    }

                    if let request = pairingRequest {
                        FieldSectionCard(kicker: "Share", title: request.homeName ?? "Pair this home") {
                            VStack(alignment: .leading, spacing: 14) {
                                if let address = request.address?.nonEmpty {
                                    Text(address)
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }

                                if let shareText = request.shareText?.nonEmpty {
                                    Text(shareText)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)

                                    HStack(spacing: 12) {
                                        Button("Copy text") {
                                            UIPasteboard.general.string = shareText
                                            feedback = "Pairing instructions copied"
                                        }
                                        .buttonStyle(FieldSecondaryButtonStyle(compact: true))

                                        ShareLink(item: shareText) {
                                            Text("Share")
                                        }
                                        .buttonStyle(FieldPrimaryButtonStyle(compact: true))
                                    }
                                }

                                if let feedback {
                                    Text(feedback)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                    } else {
                        FieldSectionCard(kicker: "Home", title: "Who should this pair to?") {
                            VStack(alignment: .leading, spacing: 14) {
                                fieldInput("Home name", text: $homeName, placeholder: "146 Putnam Park Road")
                                fieldInput("Homeowner name", text: $homeownerName, placeholder: "Taylor Morgan")
                                fieldInput("Homeowner email", text: $homeownerEmail, placeholder: "taylor@example.com", keyboard: .emailAddress)
                                fieldInput("Homeowner phone", text: $homeownerPhone, placeholder: "(203) 555-0114", keyboard: .phonePad)
                                fieldInput("Address", text: $addressLine, placeholder: "146 Putnam Park Road")

                                HStack(spacing: 12) {
                                    fieldInput("City", text: $city, placeholder: "Bethel")
                                    fieldInput("State", text: $state, placeholder: "CT")
                                    fieldInput("ZIP", text: $postalCode, placeholder: "06801", keyboard: .numberPad)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 100)
                                        .padding(10)
                                        .background(HavenColors.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                }

                                if let feedback {
                                    Text(feedback)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }

                                Button(isSaving ? "Creating..." : "Create pairing request") {
                                    Task { await createPairingRequest() }
                                }
                                .buttonStyle(FieldPrimaryButtonStyle())
                                .disabled(isSaving || homeName.trimmedOrNil == nil || (homeownerEmail.trimmedOrNil == nil && homeownerPhone.trimmedOrNil == nil))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Pair a home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                if pairingRequest != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldInput(
        _ label: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func createPairingRequest() async {
        guard let workspaceId, let resolvedHomeName = homeName.trimmedOrNil else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await HavenFieldService.shared.createPairingRequest(
                workspaceId: workspaceId,
                homeName: resolvedHomeName,
                homeownerName: homeownerName.trimmedOrNil ?? "",
                homeownerEmail: homeownerEmail.trimmedOrNil ?? "",
                homeownerPhone: homeownerPhone.trimmedOrNil ?? "",
                addressLine: addressLine.trimmedOrNil ?? "",
                city: city.trimmedOrNil ?? "",
                state: state.trimmedOrNil ?? "",
                postalCode: postalCode.trimmedOrNil ?? "",
                notes: notes.trimmedOrNil ?? ""
            )
            pairingRequest = response.pairingRequest
            feedback = nil
            await onCreated()
        } catch {
            feedback = error.localizedDescription
        }
    }
}

private struct FieldBrandHeroCard<Content: View>: View {
    let kicker: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kicker.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.74))
            Text(title)
                .font(HavenTypography.largeTitle)
                .foregroundStyle(HavenColors.textOnNavy)
            Text(subtitle)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.86))
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [HavenColors.navy900, HavenColors.navy800],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [HavenColors.action.opacity(0.24), Color.clear],
                    center: .topTrailing,
                    startRadius: 18,
                    endRadius: 220
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: HavenColors.navy900.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}

private struct FieldHeroMetric: View {
    let value: String
    let label: String
    var dotColor: Color = HavenColors.action

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.78))
            }
            Text(value)
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textOnNavy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct HavenFieldTabBar: View {
    @Binding var selectedTab: HavenFieldViewModel.RootTab

    var body: some View {
        HStack(spacing: 10) {
            tabButton(tab: .home, icon: "square.grid.2x2.fill", label: "Overview")
            tabButton(tab: .visits, icon: "calendar.badge.clock", label: "Visits")
            tabButton(tab: .clients, icon: "house.fill", label: "Homes")
            tabButton(tab: .messages, icon: "bubble.left.and.bubble.right.fill", label: "Messages")
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(HavenColors.creamLight)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .shadow(color: HavenColors.beige300.opacity(0.4), radius: 8, x: 0, y: -2)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(HavenColors.cream.opacity(0.96).ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func tabButton(tab: HavenFieldViewModel.RootTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? HavenColors.action : Color.clear)
                    .frame(width: 4, height: 4)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .frame(height: 22)
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? HavenColors.action : HavenColors.tabInactive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct FieldFloatingActionButton: View {
    let label: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                Text(label)
                    .font(HavenTypography.uiButton)
            }
            .foregroundStyle(HavenColors.textOnAction)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [HavenColors.actionPressed, HavenColors.action],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(color: HavenColors.action.opacity(0.28), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct FieldWorkspaceHeader: View {
    let companyName: String
    let memberName: String?
    let roleLabel: String
    let subtitle: String
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            FieldAvatarBadge(initials: companyInitials, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(companyName)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)

                    Text(roleLabel.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HavenColors.indigo50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.indigo50)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var companyInitials: String {
        let words = companyName.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "CF" : initials.uppercased()
    }
}

private struct FieldRouteHeroPreview: View {
    let visit: HavenFieldVisit
    let home: HavenFieldHome?
    let badgeValue: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(HavenColors.action)
                    .frame(width: 36, height: 36)
                Text(badgeValue)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textOnAction)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(visit.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textOnNavy)
                Text(previewLine)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.72))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var previewLine: String {
        let homeName = home?.name ?? visit.property?.name ?? "Connected home"
        let time = visit.assignment?.windowStartTime?.trimmedOrNil ?? visit.routeDate?.fieldShortDate ?? "TBD"
        if visit.belongsInRequestQueue {
            return "\(homeName) · Needs a reply"
        }
        return "\(homeName) · \(time)"
    }
}

private struct FieldForwardMomentumCard: View {
    let title: String
    let subtitle: String
    let primaryTitle: String
    let secondaryTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEXT STEP")
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textSecondary)

            Text(title)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            Text(subtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: 10) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(FieldPrimaryButtonStyle(compact: true))

                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .buttonStyle(FieldSecondaryButtonStyle(compact: true))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: HavenColors.beige300.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

private struct FieldVisitModeTile: View {
    let title: String
    let value: Int
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.1)
                .foregroundStyle(isSelected ? HavenColors.textOnNavy.opacity(0.72) : HavenColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(value)")
                    .font(HavenTypography.largeTitle)
                    .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.textPrimary)
                Text(subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(isSelected ? HavenColors.textOnNavy.opacity(0.74) : HavenColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [HavenColors.navy900, HavenColors.navy800],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    HavenColors.surface
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.white.opacity(0.06) : HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: isSelected ? HavenColors.navy900.opacity(0.14) : HavenColors.beige300.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct FieldMessageFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(HavenTypography.uiButton)
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isSelected ? Color.white.opacity(0.18) : HavenColors.indigo50)
                .clipShape(Capsule())
        }
        .foregroundStyle(isSelected ? HavenColors.textOnNavy : HavenColors.navy700)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? HavenColors.navy900 : HavenColors.surface)
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.white.opacity(0.06) : HavenColors.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

private struct FieldAvatarBadge: View {
    let initials: String
    var size: CGFloat = 36
    var showUnreadDot: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(HavenColors.indigo50)
                .frame(width: size, height: size)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(HavenColors.navy700)
                )

            if showUnreadDot {
                Circle()
                    .fill(HavenColors.action)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(HavenColors.surface, lineWidth: 2))
                    .offset(x: 1, y: -1)
            }
        }
    }
}

private struct FieldRequestQueueRow: View {
    let visit: HavenFieldVisit
    let home: HavenFieldHome?
    let ageLabel: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FieldAvatarBadge(initials: requestInitials)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(visit.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if let ageLabel {
                        Text(ageLabel)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Text(requestContext)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                HStack(spacing: 8) {
                    Text("Respond")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textOnAction)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.action)
                        .clipShape(Capsule())

                    Text("View")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.surface)
                        .overlay(Capsule().stroke(HavenColors.border, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var requestContext: String {
        let homeName = home?.name ?? visit.property?.name ?? "Connected home"
        let timing = visit.preferredTiming?.nonEmpty
        return [homeName, timing].compactMap { $0 }.joined(separator: " · ")
    }

    private var requestInitials: String {
        let base = home?.name ?? visit.property?.name ?? visit.title
        return base.fieldInitials
    }
}

private struct FieldScheduledVisitRow: View {
    let visit: HavenFieldVisit
    let home: HavenFieldHome?
    let highlightNext: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeLabel)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(durationLabel)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .frame(width: 74, alignment: .leading)

            RoundedRectangle(cornerRadius: 1)
                .fill(highlightNext ? HavenColors.action : HavenColors.border)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(visit.title)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(home?.address ?? visit.property?.address ?? home?.name ?? visit.property?.name ?? "Connected home")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer(minLength: 8)
                    if highlightNext {
                        Text("NEXT UP")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(HavenColors.action50)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var timeLabel: String {
        visit.assignment?.windowStartTime?.trimmedOrNil ?? visit.routeDate?.fieldShortDate ?? "TBD"
    }

    private var durationLabel: String {
        if let end = visit.assignment?.windowEndTime?.trimmedOrNil {
            return end
        }
        return visit.statusLabel ?? "Scheduled"
    }
}

private struct FieldWorkspaceSettingsSheet: View {
    let companyName: String
    let memberName: String?
    let email: String?
    let phone: String?
    let providerURL: String?
    let onSignOut: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Settings",
                        title: companyName,
                        subtitle: "Account, desktop command center, and owner actions stay here so the field flow stays focused."
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let trimmedName = memberName?.nonEmpty {
                                Text(trimmedName)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textOnNavy)
                            }
                            Text([email?.nonEmpty, phone?.nonEmpty].compactMap { $0 }.joined(separator: " • "))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textOnNavy.opacity(0.74))
                        }
                    }

                    FieldSectionCard(kicker: "Workspace", title: "Owner tools") {
                        VStack(alignment: .leading, spacing: 12) {
                            if let providerURL, let url = URL(string: providerURL) {
                                Link(destination: url) {
                                    Label("Open desktop command center", systemImage: "arrow.up.right.square")
                                        .font(HavenTypography.uiButton)
                                        .foregroundStyle(HavenColors.navy700)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .background(HavenColors.indigo50)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }

                            Button("Sign out") {
                                dismiss()
                                onSignOut()
                            }
                            .buttonStyle(FieldPrimaryButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct FieldFilterChips<Option: Hashable & CaseIterable & RawRepresentable>: View where Option.RawValue == String {
    let options: Option.AllCases
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(options), id: \.self) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(isSelected ? HavenColors.textOnAction : HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isSelected ? HavenColors.action : HavenColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? HavenColors.actionPressed.opacity(0.35) : HavenColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FieldSectionCard<Content: View>: View {
    let kicker: String
    let title: String
    var inverse: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(kicker.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(inverse ? HavenColors.textOnNavy.opacity(0.78) : HavenColors.textSecondary)
            Text(title)
                .font(HavenTypography.largeTitle)
                .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.textPrimary)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if inverse {
                    HavenColors.navy800
                } else {
                    LinearGradient(
                        colors: [HavenColors.surface, HavenColors.creamLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(inverse ? HavenColors.navy600.opacity(0.55) : HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: inverse ? HavenColors.navy700.opacity(0.14) : HavenColors.beige300.opacity(0.24), radius: 14, x: 0, y: 8)
    }
}

private struct FieldVisitRow: View {
    let visit: HavenFieldVisit
    let emphasized: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(visit.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(visit.property?.name ?? "Home")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Text(visit.statusLabel ?? visit.status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.action)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(HavenColors.action.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text([visit.routeDate?.fieldShortDate, routeWindow].compactMap { $0 }.joined(separator: " • "))
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            if let message = visit.latestMessage?.body, !message.isEmpty {
                Text(message)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            emphasized
                ? HavenColors.action.opacity(0.08)
                : HavenColors.surface
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    emphasized ? HavenColors.action.opacity(0.18) : HavenColors.border,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: emphasized ? HavenColors.action.opacity(0.08) : HavenColors.beige300.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private var routeWindow: String? {
        let start = visit.assignment?.windowStartTime?.trimmedOrNil
        let end = visit.assignment?.windowEndTime?.trimmedOrNil
        if let start, let end { return "\(start) to \(end)" }
        return start ?? end
    }
}

private struct FieldHomeRow: View {
    let home: HavenFieldHome

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FieldAvatarBadge(initials: home.name.fieldInitials)

            VStack(alignment: .leading, spacing: 6) {
                Text(home.name)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(home.address)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(summary)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: HavenColors.beige300.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private var summary: String {
        let lastVisit = home.lastCompletedVisit?.fieldDateTime
        let homeSummary = "\(home.systemCount) systems • \(home.openTasks.count) open tasks"
        guard let lastVisit else { return homeSummary }
        return "\(homeSummary) • last visit \(lastVisit)"
    }
}

private struct FieldHomeMessageRow: View {
    let home: HavenFieldHome
    let thread: HavenFieldMessageThread?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(home.name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(home.address)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(summary)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Text(thread == nil ? "New" : "Message")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.action)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(HavenColors.action.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var summary: String {
        let requestSummary: String? = {
            if let statusLabel = thread?.statusLabel?.nonEmpty {
                return statusLabel
            }
            if home.openRequests > 0 {
                return "\(home.openRequests) open request\(home.openRequests == 1 ? "" : "s")"
            }
            return nil
        }()

        let lastVisitSummary: String? = {
            guard let visit = home.lastCompletedVisit else { return nil }
            return "Last visit \(visit.fieldDateTime)"
        }()

        let parts = [requestSummary, lastVisitSummary].compactMap { $0 }
        let joined = parts.joined(separator: " • ")
        return joined.isEmpty ? "Send a quick update, schedule note, or follow-up." : joined
    }
}

private struct FieldMessageThreadRow: View {
    let thread: HavenFieldMessageThread

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FieldAvatarBadge(
                initials: (thread.propertyName ?? thread.title).fieldInitials,
                size: 40,
                showUnreadDot: thread.fieldNeedsAttention
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.propertyName ?? thread.title)
                        .font(thread.fieldNeedsAttention ? HavenTypography.uiLabel : HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer(minLength: 8)
                    Text(thread.latestMessageAt?.fieldRelativeTime ?? "")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Text(thread.latestMessage ?? "No messages yet")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(thread.fieldNeedsAttention ? HavenColors.textPrimary : HavenColors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let status = thread.statusLabel?.nonEmpty ?? thread.status?.nonEmpty {
                        Text(status.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(HavenColors.indigo50)
                            .clipShape(Capsule())
                    }

                    if thread.quote != nil {
                        Text("QUOTE ATTACHED")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(HavenColors.indigo50)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(thread.fieldNeedsAttention ? HavenColors.action50 : HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: HavenColors.beige300.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

private struct FieldSystemCard: View {
    let system: HavenFieldSystemSnapshot
    let onCapture: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.catalogDisplayName?.nonEmpty ?? system.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(
                        [
                            system.category.nonEmpty,
                            system.manufacturer?.nonEmpty,
                            system.modelNumber?.nonEmpty.map { "Model \($0)" }
                        ]
                            .compactMap { $0 }
                            .joined(separator: " • ")
                    )
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                if system.reliabilityScore != nil {
                    Text("Reliability \(system.reliabilityScore ?? 0)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.action)
                }
            }

            if let summary = system.scoreSummary?.nonEmpty {
                Text(summary)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            HStack(spacing: 10) {
                Button(system.labelPhotoName == nil ? "Take label photo" : "Refresh label photo") {
                    onCapture()
                }
                .buttonStyle(FieldPrimaryButtonStyle(compact: true))

                Button("Details") {
                    onOpenDetail()
                }
                .buttonStyle(FieldSecondaryButtonStyle(compact: true))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: HavenColors.beige300.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

private struct FieldCompactSystemRow: View {
    let system: HavenFieldHomeSystem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(system.name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(
                    [
                        system.category?.nonEmpty,
                        system.manufacturer?.nonEmpty,
                        system.modelNumber?.nonEmpty
                    ]
                        .compactMap { $0 }
                        .joined(separator: " • ")
                )
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

                if let score = system.reliabilityScore {
                    Text("Reliability \(score)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.action)
                } else if let due = system.nextServiceDue?.fieldShortDate {
                    Text("Next service \(due)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.beige400)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct FieldFileRow: View {
    let file: HavenFieldHomeFile

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundStyle(HavenColors.navy600)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text([file.category?.nonEmpty, file.uploadedAt?.fieldShortDate].compactMap { $0 }.joined(separator: " • "))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                if let notes = file.notes?.nonEmpty {
                    Text(notes)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer()
            if file.signedURL != nil {
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(HavenColors.action)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct FieldErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(HavenTypography.caption)
            .foregroundStyle(HavenColors.critical)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.critical.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct FieldEmptyState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(subtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}

private struct FieldKeyValueRow: View {
    let label: String
    let value: String
    /// When the row sits inside a navy `FieldSectionCard(inverse: true)`,
    /// flip the foregrounds to white-on-navy so the text remains
    /// readable. Phase 67 visit hero card was rendering navy on navy.
    var inverse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1)
                .foregroundStyle(inverse ? HavenColors.textOnNavy.opacity(0.72) : HavenColors.textSecondary)
            Text(value)
                .font(HavenTypography.body)
                .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HavenFieldCoordinationComposer: View {
    let mode: String
    @Binding var message: String
    @Binding var proposedDate: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var alternateDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                if mode == "propose_other_dates" {
                    DatePicker("Alternate date", selection: $alternateDate, displayedComponents: .date)
                }
                TextField(mode == "ask_question" ? "Question" : "Coordination note", text: $message, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
            .onAppear {
                if let parsed = DateFormatter.havenISODate.date(from: proposedDate) {
                    alternateDate = parsed
                }
            }
            .navigationTitle(sheetTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") {
                        if mode == "propose_other_dates" {
                            proposedDate = DateFormatter.havenISODate.string(from: alternateDate)
                        }
                        onSubmit()
                    }
                }
            }
        }
    }

    private var sheetTitle: String {
        switch mode {
        case "propose_other_dates": return "Reschedule"
        case "decline_visit": return "Decline visit"
        case "ask_question": return "Ask question"
        default: return "Coordinate"
        }
    }
}

/// Dedicated reschedule sheet — surfaces a real date+time picker
/// (`.dateAndTime`) plus an optional note. Replaces the generic
/// "propose_other_dates" mode of `HavenFieldCoordinationComposer`,
/// which only had a date picker and a confusing "Coordination note"
/// text field that read like an unrelated comment.
private struct HavenFieldRescheduleSheet: View {
    @Binding var date: Date
    @Binding var note: String
    let isSubmitting: Bool
    let onSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PROPOSE A NEW TIME")
                            .font(HavenTypography.uiSectionHeader)
                            .kerning(1.2)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("When would work better?")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("The homeowner sees this proposal in their app and can accept, counter, or chat.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    DatePicker(
                        "",
                        selection: $date,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField(
                            "e.g. \"Running long on a job. Earliest I can swing by is 2 PM.\"",
                            text: $note,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(12)
                        .background(HavenColors.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        onSubmit()
                    } label: {
                        Text(isSubmitting ? "Proposing…" : "Propose this time")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Reschedule visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }
}

private struct HavenFieldMessageComposer: View {
    @Binding var messageBody: String
    let onSend: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Send a note to the homeowner", text: $messageBody, axis: .vertical)
                    .lineLimit(6, reservesSpace: true)
            }
            .navigationTitle("Message homeowner")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") { onSend() }
                        .disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct HavenFieldSystemDetailSheet: View {
    let system: HavenFieldSystemSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("System") {
                    Text(system.catalogDisplayName?.nonEmpty ?? system.name)
                    if let model = system.modelNumber?.nonEmpty {
                        Label("Model \(model)", systemImage: "number")
                    }
                    if let serial = system.serialNumber?.nonEmpty {
                        Label("Serial \(serial)", systemImage: "barcode")
                    }
                    if let manufacturer = system.manufacturer?.nonEmpty {
                        Label(manufacturer, systemImage: "wrench.and.screwdriver")
                    }
                }

                Section("Reliability") {
                    if let score = system.reliabilityScore {
                        Text("Score: \(score)")
                    }
                    if let summary = system.scoreSummary?.nonEmpty {
                        Text(summary)
                    }
                }

                Section("Service") {
                    if let last = system.lastServiceDate?.nonEmpty {
                        Text("Last service: \(last)")
                    }
                    if let next = system.nextServiceDue?.nonEmpty {
                        Text("Next due: \(next)")
                    }
                    if let subtype = system.subtype?.nonEmpty {
                        Text("Subtype: \(subtype)")
                    }
                    if let fuel = system.catalogFuelType?.nonEmpty {
                        Text("Fuel: \(fuel)")
                    }
                }

                if !system.catalogFeatures.isEmpty {
                    Section("Catalog details") {
                        ForEach(system.catalogFeatures, id: \.self) { feature in
                            Text(feature)
                        }
                    }
                }

                if !system.cachedManualLinks.isEmpty {
                    Section("Manuals") {
                        ForEach(system.cachedManualLinks) { link in
                            if let url = URL(string: link.url) {
                                Link(link.type?.capitalized ?? "Open manual", destination: url)
                            }
                        }
                    }
                }

                if let notes = system.notes?.nonEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle("System detail")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct HavenFieldHomeSystemDetailSheet: View {
    let system: HavenFieldHomeSystem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    LabeledContent("Name", value: system.name)
                    if let category = system.category?.nonEmpty {
                        LabeledContent("Category", value: category)
                    }
                    if let subtype = system.subtype?.nonEmpty {
                        LabeledContent("Subtype", value: subtype)
                    }
                    if let manufacturer = system.manufacturer?.nonEmpty {
                        LabeledContent("Manufacturer", value: manufacturer)
                    }
                    if let model = system.modelNumber?.nonEmpty {
                        LabeledContent("Model", value: model)
                    }
                    if let serial = system.serialNumber?.nonEmpty {
                        LabeledContent("Serial", value: serial)
                    }
                    if let installDate = system.installDate?.fieldShortDate {
                        LabeledContent("Installed", value: installDate)
                    }
                    if let fuel = system.catalogFuelType?.nonEmpty {
                        LabeledContent("Fuel", value: fuel)
                    }
                    if let status = system.status?.nonEmpty {
                        LabeledContent("Status", value: status.capitalized)
                    }
                }

                if system.reliabilityScore != nil || system.scoreSummary?.nonEmpty != nil {
                    Section("Reliability") {
                        if let score = system.reliabilityScore {
                            LabeledContent("Score", value: "\(score)")
                        }
                        if let summary = system.scoreSummary?.nonEmpty {
                            Text(summary)
                        }
                    }
                }

                if system.lastServiceDate?.fieldShortDate != nil || system.nextServiceDue?.fieldShortDate != nil || system.totalSpent != nil {
                    Section("Service") {
                        if let lastServiceDate = system.lastServiceDate?.fieldShortDate {
                            LabeledContent("Last service", value: lastServiceDate)
                        }
                        if let nextServiceDue = system.nextServiceDue?.fieldShortDate {
                            LabeledContent("Next due", value: nextServiceDue)
                        }
                        if let totalSpent = system.totalSpent {
                            LabeledContent("Recorded spend", value: totalSpent.formatted(.currency(code: "USD")))
                        }
                    }
                }

                if !system.catalogFeatures.isEmpty {
                    Section("Features") {
                        ForEach(system.catalogFeatures, id: \.self) { feature in
                            Text(feature)
                        }
                    }
                }

                if !system.cachedManualLinks.isEmpty {
                    Section("Manuals") {
                        ForEach(system.cachedManualLinks) { link in
                            if let url = URL(string: link.url) {
                                Link(link.type?.nonEmpty ?? "Manual", destination: url)
                            }
                        }
                    }
                }

                if let notes = system.notes?.nonEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle(system.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HavenFieldCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImage: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImage = onImage
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private struct FieldPrimaryButtonStyle: ButtonStyle {
    var compact: Bool = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HavenTypography.uiButton)
            .foregroundStyle(HavenColors.textOnAction)
            .padding(.vertical, compact ? 10 : 12)
            .padding(.horizontal, compact ? 14 : 18)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(
                isEnabled
                    ? (configuration.isPressed ? HavenColors.actionPressed : HavenColors.action)
                    : HavenColors.action.opacity(0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 16 : 18))
            // Disabled state: dimmed bg + de-emphasized label so users see
            // the button isn't yet actionable. Pre-Wave-1b the disabled
            // state was indistinguishable from active and users tapped a
            // dead button repeatedly.
            .opacity(isEnabled ? 1.0 : 0.85)
    }
}

private struct FieldSecondaryButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HavenTypography.uiButton)
            .foregroundStyle(HavenColors.navy700)
            .padding(.vertical, compact ? 10 : 12)
            .padding(.horizontal, compact ? 14 : 18)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 16 : 18)
                    .stroke(HavenColors.navy600.opacity(configuration.isPressed ? 0.45 : 0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 16 : 18))
    }
}

private struct FieldGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HavenTypography.uiButton)
            .foregroundStyle(HavenColors.textSecondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(HavenColors.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private extension DateFormatter {
    static let havenISODate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension HavenFieldVisit {
    var belongsInRequestQueue: Bool {
        switch status {
        case HandymanRequestStatus.submitted.rawValue,
             HandymanRequestStatus.scheduled.rawValue,
             HandymanRequestStatus.sentToHandyman.rawValue,
             HandymanRequestStatus.alternateDatesProposed.rawValue,
             HandymanRequestStatus.awaitingHomeowner.rawValue,
             HandymanRequestStatus.quoted.rawValue:
            return true
        default:
            return false
        }
    }

    var belongsInUpcomingQueue: Bool {
        switch status {
        case HandymanRequestStatus.confirmed.rawValue,
             HandymanRequestStatus.onMyWay.rawValue,
             HandymanRequestStatus.checkedIn.rawValue,
             HandymanRequestStatus.inProgress.rawValue:
            return true
        default:
            return false
        }
    }
}

private func fieldVisitSort(_ lhs: HavenFieldVisit, _ rhs: HavenFieldVisit) -> Bool {
    let leftDate = lhs.routeDate ?? lhs.visit?.scheduledDate ?? "9999-12-31"
    let rightDate = rhs.routeDate ?? rhs.visit?.scheduledDate ?? "9999-12-31"
    if leftDate != rightDate { return leftDate < rightDate }

    let leftWindow = lhs.assignment?.windowStartTime?.trimmedOrNil ?? "99:99"
    let rightWindow = rhs.assignment?.windowStartTime?.trimmedOrNil ?? "99:99"
    if leftWindow != rightWindow { return leftWindow < rightWindow }

    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
}

private extension HavenFieldMessageThread {
    var fieldNeedsAttention: Bool {
        guard let senderRole = senderRole?.lowercased() else { return false }
        return senderRole.contains("home") || senderRole.contains("owner") || senderRole.contains("customer")
    }

    var isSchedulingThread: Bool {
        let haystack = [
            status,
            statusLabel,
            requestType,
            latestMessage
        ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        return haystack.contains("schedule")
            || haystack.contains("confirm")
            || haystack.contains("resched")
            || haystack.contains("date")
            || haystack.contains("visit")
    }
}

/// Physical-work-zone categories for the visit punch list. Mirrors
/// `PUNCH_CATEGORIES` + `categorizePunchItem` in
/// `website/operations/src/lib/api.ts` so the same ordered grouping that
/// shows on the Operations Desk shows on iOS — the handyman moves
/// outside → up → in → safety walkaround across both surfaces.
enum FieldPunchCategory: Int, CaseIterable, Hashable {
    case exterior, roofing, atticInsulation, plumbing, kitchenLaundry, bathrooms, hvacAir, electrical, safety, general

    var label: String {
        switch self {
        case .exterior: return "Exterior + Grounds"
        case .roofing: return "Roof + Gutters"
        case .atticInsulation: return "Attic + Insulation"
        case .plumbing: return "Plumbing"
        case .kitchenLaundry: return "Kitchen + Laundry"
        case .bathrooms: return "Bathrooms"
        case .hvacAir: return "HVAC + Air"
        case .electrical: return "Electrical"
        case .safety: return "Safety walkaround"
        case .general: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .exterior, .roofing, .atticInsulation, .kitchenLaundry: return "house.fill"
        case .plumbing, .bathrooms, .hvacAir, .general: return "wrench.fill"
        case .electrical: return "bolt.fill"
        case .safety: return "shield.fill"
        }
    }

    /// Order matters — first match wins. Specific phrases (smoke detector)
    /// run BEFORE broader ones (detector → safety) so categorization
    /// stays consistent with the desktop logic.
    static func categorize(_ title: String) -> FieldPunchCategory {
        let t = title.lowercased()
        if t.range(of: #"(smoke|carbon monoxide|\bco\b|co2|fire extinguisher|radon)"#, options: .regularExpression) != nil { return .safety }
        if t.range(of: #"(gfci|afci)"#, options: .regularExpression) != nil { return .safety }
        if t.range(of: #"(gutter|downspout|roof|shingle|chimney|flashing)"#, options: .regularExpression) != nil { return .roofing }
        if t.range(of: #"(attic|insulation)"#, options: .regularExpression) != nil { return .atticInsulation }
        if t.range(of: #"(bath|shower|toilet|vanity|tub)"#, options: .regularExpression) != nil { return .bathrooms }
        if t.range(of: #"(dryer|washing machine|washer|dishwasher|garbage disposal|kitchen|range hood|fridge|refrigerator|ice maker)"#, options: .regularExpression) != nil { return .kitchenLaundry }
        if t.range(of: #"(hvac|furnace|boiler|ac\b|air condition|mini[- ]?split|heat pump|humidifier|filter|ceiling fan|duct|thermostat)"#, options: .regularExpression) != nil { return .hvacAir }
        if t.range(of: #"(pipe|plumb|water heater|anode|sump|drain|leak|valve)"#, options: .regularExpression) != nil { return .plumbing }
        if t.range(of: #"(exterior|outdoor|outside|paint chip|siding|deck|fence|driveway|patio|hardscape|hose|faucet|spigot|hose bib|winterize|reopen.*faucet)"#, options: .regularExpression) != nil { return .exterior }
        if t.range(of: #"(foundation|grading|landscape|tree|shrub|bush|pest|paver|joint sand|weed)"#, options: .regularExpression) != nil { return .exterior }
        if t.range(of: #"(weatherstrip|weather strip|window|door)"#, options: .regularExpression) != nil { return .exterior }
        if t.range(of: #"(caulk|seal)"#, options: .regularExpression) != nil { return .exterior }
        if t.range(of: #"(outlet|breaker|panel|electric|wiring|ev charger)"#, options: .regularExpression) != nil { return .electrical }
        if t.range(of: #"(bleed.*radiator|radiator)"#, options: .regularExpression) != nil { return .plumbing }
        return .general
    }
}

/// Postgres timestamps come back as ISO 8601 with fractional seconds and a
/// `+00:00` offset (`2026-04-28T00:14:56.209414+00:00`). The default
/// `ISO8601DateFormatter` rejects fractional seconds, so without explicit
/// options it returns nil and every "fieldDateTime" call falls back to the
/// raw string. This helper tries both formats once and caches the result.
private enum HavenFieldDateParser {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let withoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ raw: String) -> Date? {
        if let date = withFractionalSeconds.date(from: raw) { return date }
        return withoutFractionalSeconds.date(from: raw)
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var nonEmpty: String? {
        trimmedOrNil
    }

    var fieldShortDate: String {
        if let date = DateFormatter.havenISODate.date(from: self) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
        return self
    }

    var fieldDateTime: String {
        guard let date = HavenFieldDateParser.parse(self) else { return self }
        return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    var fieldRelativeTime: String {
        guard let date = HavenFieldDateParser.parse(self) else { return fieldDateTime }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var fieldRouteDateLabel: String {
        guard let date = DateFormatter.havenISODate.date(from: self) else { return self }
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var fieldInitials: String {
        let parts = split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
        if !letters.isEmpty { return letters.uppercased() }
        return String(prefix(2)).uppercased()
    }
}

private extension Date {
    var fieldGreeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 4..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
