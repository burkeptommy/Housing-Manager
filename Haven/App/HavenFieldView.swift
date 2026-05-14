import SwiftUI
import UIKit
import CoreLocation
import MapKit
import PhotosUI
import AVFoundation
import PencilKit
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

    /// Wave M12 — posted after a successful create_part_request /
    /// update_part_status round-trip so any open-count surface
    /// (Today-screen pill, FieldPartRequestsListView) refreshes its
    /// queue without prop-drilling a callback through every entry point.
    static let havenFieldPartRequestChanged = Notification.Name("havenFieldPartRequestChanged")

    /// T1.5 (post-overnight) — APNs deep-link routing primitives. The
    /// AppDelegate's `userNotificationCenter(_:didReceive:)` switches
    /// on `userInfo["type"]` and posts the appropriate name; the field
    /// root view + tabs subscribe to react.
    ///
    /// These mirror the homeowner-side pattern at HavenApp.swift:223-295
    /// (which has typed handyman_* / chez_* / vehicle_recall / etc.
    /// routing). Pre-T1.5 the field-app handler was anemic — it only
    /// posted `.inboxItemUpdated` with no payload parsing. Tap a
    /// "quote accepted" push → land on whatever tab was already open.
    /// Now: tap routes to the right tab + opens the right entity.
    static let havenFieldSwitchTab = Notification.Name("havenFieldSwitchTab")
    static let havenFieldOpenVisit = Notification.Name("havenFieldOpenVisit")
    static let havenFieldOpenThread = Notification.Name("havenFieldOpenThread")
    static let havenFieldOpenHome = Notification.Name("havenFieldOpenHome")
}

/// Bounds-safe subscript so closure-based bindings in
/// `FieldBuildQuoteSheet`'s tier editors can't index out of range
/// during the brief window between an array mutation and the next
/// view update. Mirrors the local helper in `QuizKidsInlineForm.swift`.
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
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
    /// Wave M9 — mid-stream cancellation context. Distinct from the
    /// existing M5 `cancelled_by_user_id` / `cancelled_by_role` fields:
    /// these only populate when the field tech ended a visit early via
    /// `cancel_visit_mid_stream`, not when the homeowner cancelled
    /// pre-visit. Renders the "Cancelled mid-visit at HH:MM" annotation.
    let cancellationReason: String?
    let cancelledAt: String?

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
        case cancellationReason
        case cancelledAt
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
        cancellationReason = (try? container.decodeIfPresent(String.self, forKey: .cancellationReason)) ?? nil
        cancelledAt = (try? container.decodeIfPresent(String.self, forKey: .cancelledAt)) ?? nil
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
        punchItems: [HavenFieldPunchItem] = [],
        cancellationReason: String? = nil,
        cancelledAt: String? = nil
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
        self.cancellationReason = cancellationReason
        self.cancelledAt = cancelledAt
    }
}

/// Wave M2 — one entry on `handyman_punch_items.attachments` JSONB array.
/// Server stamps `path` + `contentType` + optional `caption` + uploader
/// metadata; the dashboard read also folds in `signedUrl` so the iOS UI
/// can render the thumbnail without a per-image round-trip. Resilient
/// decoder so a malformed legacy entry doesn't take down the whole row.
struct HavenFieldPunchAttachment: Codable, Hashable, Identifiable {
    /// "photo" today; reserved for "video" / "doc" later. Default 'photo'
    /// keeps pre-M2 attachments — there shouldn't be any in production
    /// because attachments was 0% populated before this wave — sane.
    let kind: String
    let path: String
    let contentType: String?
    let caption: String?
    let uploadedAt: String?
    let uploadedBy: String?
    let signedUrl: String?

    var id: String { path }

    private enum CodingKeys: String, CodingKey {
        case kind, path, contentType, caption, uploadedAt, uploadedBy, signedUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? "photo"
        path = (try? c.decodeIfPresent(String.self, forKey: .path)) ?? ""
        contentType = (try? c.decodeIfPresent(String.self, forKey: .contentType)) ?? nil
        caption = (try? c.decodeIfPresent(String.self, forKey: .caption)) ?? nil
        uploadedAt = (try? c.decodeIfPresent(String.self, forKey: .uploadedAt)) ?? nil
        uploadedBy = (try? c.decodeIfPresent(String.self, forKey: .uploadedBy)) ?? nil
        signedUrl = (try? c.decodeIfPresent(String.self, forKey: .signedUrl)) ?? nil
    }
}

/// Wave M2 — one entry on `handyman_punch_items.materials_used` JSONB array.
/// The contractor desk's invoice convertor consumes the same shape so qty
/// × unit_cost rolls up directly into "Materials" line items on a draft
/// invoice. snake_case keys mirror the column convention.
struct HavenFieldPunchMaterial: Codable, Hashable, Identifiable {
    let sku: String?
    let name: String
    let qty: Double
    let unitCost: Double

    /// Synthesize a stable id off (sku, name) so SwiftUI's diffing keeps
    /// rows aligned across save → reload cycles. Non-unique among
    /// duplicates is fine — order is preserved by the array index.
    var id: String { (sku.map { "\($0)|" } ?? "") + name }

    private enum CodingKeys: String, CodingKey {
        case sku, name, qty
        case unitCost = "unit_cost"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sku = (try? c.decodeIfPresent(String.self, forKey: .sku)) ?? nil
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        qty = (try? c.decodeIfPresent(Double.self, forKey: .qty)) ?? 0
        unitCost = (try? c.decodeIfPresent(Double.self, forKey: .unitCost)) ?? 0
    }

    init(sku: String?, name: String, qty: Double, unitCost: Double) {
        self.sku = sku
        self.name = name
        self.qty = qty
        self.unitCost = unitCost
    }

    /// Used by `set_punch_materials` to round-trip back to the server.
    /// Encodes with snake_case `unit_cost` so the edge function's
    /// `numberValue(row.unit_cost ?? row.unitCost)` reads either spelling.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(sku, forKey: .sku)
        try c.encode(name, forKey: .name)
        try c.encode(qty, forKey: .qty)
        try c.encode(unitCost, forKey: .unitCost)
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
    /// Wave M2 — capture depth fields. Photos + materials + per-item time
    /// + voice. Default empties keep pre-Phase-M2 rows decoding cleanly.
    let attachments: [HavenFieldPunchAttachment]
    let materialsUsed: [HavenFieldPunchMaterial]
    let timeSpentSeconds: Int
    let voiceNotePath: String?
    /// Server-signed URL the iOS UI hands to AVAudioPlayer when the user
    /// taps the voice playback chip. Only set on dashboard hydration +
    /// after a fresh attach_punch_voice action.
    let voiceNoteSignedUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, householdId, propertyId, assignedVisitTaskId, systemId, systemLabelSnapshot
        case templateId, title, description, source, status, priority
        case estimatedMinutes, estimatedCostRange, materialRequired, costBasis, addedAfterLock
        case proposedByRole, proposedAt, proposalMessage, proposalStatus, proposalExpiresAt
        case acceptedAt, declinedAt, declinedReason, completedAt, createdAt, updatedAt
        case attachments, materialsUsed, timeSpentSeconds, voiceNotePath, voiceNoteSignedUrl
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
        attachments = (try? c.decodeIfPresent([HavenFieldPunchAttachment].self, forKey: .attachments)) ?? []
        materialsUsed = (try? c.decodeIfPresent([HavenFieldPunchMaterial].self, forKey: .materialsUsed)) ?? []
        timeSpentSeconds = (try? c.decodeIfPresent(Int.self, forKey: .timeSpentSeconds)) ?? 0
        voiceNotePath = (try? c.decodeIfPresent(String.self, forKey: .voiceNotePath)) ?? nil
        voiceNoteSignedUrl = (try? c.decodeIfPresent(String.self, forKey: .voiceNoteSignedUrl)) ?? nil
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

// MARK: - Wave M12 — Need part flow

/// Wave M12 — one part request row. Mirrors `provider_part_requests`
/// table + the camelCase shape `serializePartRequest` returns from the
/// `handyman-provider` edge function. Resilient decoder so a single
/// bad field doesn't take down the open-requests list.
///
/// Either `requestId` or `punchItemId` is set (or both, if a punch item
/// lives on a specific request). `urgency` is one of `blocking_now`,
/// `next_visit`, `order_for_stock`. `status` walks `open` → `ordered`
/// → `in_truck` → `fulfilled` (or `open` → `cancelled`).
struct HavenFieldPartRequest: Codable, Identifiable, Hashable {
    let id: String
    let workspaceId: String
    let requestId: String?
    let punchItemId: String?
    let description: String
    let urgency: String
    let photos: [HavenFieldPunchAttachment]
    let status: String
    let supplier: String?
    let supplierEta: String?
    let fulfilledAt: String?
    let requestedByMemberId: String
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, workspaceId, requestId, punchItemId, description, urgency, photos, status
        case supplier, supplierEta, fulfilledAt, requestedByMemberId, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? ""
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? nil
        punchItemId = (try? c.decodeIfPresent(String.self, forKey: .punchItemId)) ?? nil
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? ""
        urgency = (try? c.decodeIfPresent(String.self, forKey: .urgency)) ?? "next_visit"
        photos = (try? c.decodeIfPresent([HavenFieldPunchAttachment].self, forKey: .photos)) ?? []
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "open"
        supplier = (try? c.decodeIfPresent(String.self, forKey: .supplier)) ?? nil
        supplierEta = (try? c.decodeIfPresent(String.self, forKey: .supplierEta)) ?? nil
        fulfilledAt = (try? c.decodeIfPresent(String.self, forKey: .fulfilledAt)) ?? nil
        requestedByMemberId = (try? c.decodeIfPresent(String.self, forKey: .requestedByMemberId)) ?? ""
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
        updatedAt = (try? c.decodeIfPresent(String.self, forKey: .updatedAt)) ?? nil
    }

    /// Human-readable label for the urgency tier. Drives the chip
    /// label on the part-request list view + the badge on each row.
    var urgencyDisplayLabel: String {
        switch urgency {
        case "blocking_now": return "Blocking now"
        case "next_visit": return "Next visit"
        case "order_for_stock": return "Order for stock"
        default: return "Next visit"
        }
    }

    /// Human-readable label for the status. Drives the status pill on
    /// the list / detail views.
    var statusDisplayLabel: String {
        switch status {
        case "open": return "Open"
        case "ordered": return "Ordered"
        case "in_truck": return "In truck"
        case "fulfilled": return "Fulfilled"
        case "cancelled": return "Cancelled"
        default: return status.capitalized
        }
    }
}

/// Wave M12 — wrapper response shape returned by `list_open_part_requests`.
/// `openCount` is server-computed (filtered to status='open') so the
/// Today-screen pill renders without the iOS UI re-counting the array.
struct HavenFieldPartRequestList: Codable {
    let partRequests: [HavenFieldPartRequest]
    let openCount: Int

    private enum CodingKeys: String, CodingKey {
        case partRequests, openCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        partRequests = (try? c.decodeIfPresent([HavenFieldPartRequest].self, forKey: .partRequests)) ?? []
        openCount = (try? c.decodeIfPresent(Int.self, forKey: .openCount)) ?? 0
    }
}

/// Wave M12 — wrapper for create / update / attach responses. Every
/// part-request mutator returns a single `partRequest` field with the
/// server-canonical row.
struct HavenFieldPartRequestSingle: Codable {
    let partRequest: HavenFieldPartRequest

    private enum CodingKeys: String, CodingKey {
        case partRequest
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        partRequest = try c.decode(HavenFieldPartRequest.self, forKey: .partRequest)
    }
}

/// Wave M12 — wrapper for `attach_part_request_photo` response.
struct HavenFieldPartRequestPhotoUpload: Codable {
    let photo: HavenFieldPunchAttachment

    private enum CodingKeys: String, CodingKey {
        case photo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        photo = try c.decode(HavenFieldPunchAttachment.self, forKey: .photo)
    }
}

struct HavenFieldPropertySummary: Codable, Hashable {
    let id: String?
    let name: String?
    let address: String?
    /// N-customer-phone fix: served by `loadDashboard` per visit row.
    /// Resolved server-side from the household's primary family_member
    /// (or any non-staff family_member fallback). Optional + resilient
    /// decode so legacy / pre-fix payloads still work.
    let customerPhone: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case customerPhone
    }

    init(id: String?, name: String?, address: String?, customerPhone: String?) {
        self.id = id
        self.name = name
        self.address = address
        self.customerPhone = customerPhone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        address = (try? c.decodeIfPresent(String.self, forKey: .address)) ?? nil
        customerPhone = (try? c.decodeIfPresent(String.self, forKey: .customerPhone)) ?? nil
    }
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
    /// Wave M1 — visit lifecycle. Optional ISO timestamps + GPS coords +
    /// banked pause seconds. Defaults to nulls / 0 for legacy rows that
    /// pre-date the lifecycle phase. Resilient decoder so a future field
    /// drift on the server doesn't take down the entire assignment.
    let clockInAt: String?
    let clockOutAt: String?
    let pausedSeconds: Int
    let clockInLat: Double?
    let clockInLng: Double?
    let clockInAccuracyM: Int?
    /// Wave M6 — count of internal tech notes on this request. Drives
    /// the small "N notes" badge on the visit row + workspace header so
    /// a tech walking up to a job knows there's prior context to read.
    let techNotesCount: Int
    /// Wave M9 — additional workspace members assigned alongside the
    /// primary tech (see `memberId`). Both can check off punch items.
    /// Defaults to empty for legacy / pre-M9 rows.
    let coTechMemberIds: [String]
    /// Wave M9 — entry method captured before the visit. One of:
    /// `customer_present`, `lockbox`, `key_under_mat`, `door_code`. Drives
    /// the lockbox badge in the visit-detail header.
    let accessMethod: String?
    /// Wave M9 — free-form notes for the access method (lockbox code,
    /// key location, etc.).
    let accessNotes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case memberId
        case memberName
        case memberRole
        case memberRoleLabel
        case routeDate
        case windowStartTime
        case windowEndTime
        case stopOrder
        case routeNotes
        case clockInAt
        case clockOutAt
        case pausedSeconds
        case clockInLat
        case clockInLng
        case clockInAccuracyM
        case techNotesCount
        case coTechMemberIds
        case accessMethod
        case accessNotes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil
        memberId = (try? c.decodeIfPresent(String.self, forKey: .memberId)) ?? nil
        memberName = (try? c.decodeIfPresent(String.self, forKey: .memberName)) ?? nil
        memberRole = (try? c.decodeIfPresent(String.self, forKey: .memberRole)) ?? nil
        memberRoleLabel = (try? c.decodeIfPresent(String.self, forKey: .memberRoleLabel)) ?? nil
        routeDate = (try? c.decodeIfPresent(String.self, forKey: .routeDate)) ?? nil
        windowStartTime = (try? c.decodeIfPresent(String.self, forKey: .windowStartTime)) ?? nil
        windowEndTime = (try? c.decodeIfPresent(String.self, forKey: .windowEndTime)) ?? nil
        stopOrder = (try? c.decodeIfPresent(Int.self, forKey: .stopOrder)) ?? nil
        routeNotes = (try? c.decodeIfPresent(String.self, forKey: .routeNotes)) ?? nil
        clockInAt = (try? c.decodeIfPresent(String.self, forKey: .clockInAt)) ?? nil
        clockOutAt = (try? c.decodeIfPresent(String.self, forKey: .clockOutAt)) ?? nil
        pausedSeconds = (try? c.decodeIfPresent(Int.self, forKey: .pausedSeconds)) ?? 0
        clockInLat = (try? c.decodeIfPresent(Double.self, forKey: .clockInLat)) ?? nil
        clockInLng = (try? c.decodeIfPresent(Double.self, forKey: .clockInLng)) ?? nil
        clockInAccuracyM = (try? c.decodeIfPresent(Int.self, forKey: .clockInAccuracyM)) ?? nil
        techNotesCount = (try? c.decodeIfPresent(Int.self, forKey: .techNotesCount)) ?? 0
        coTechMemberIds = (try? c.decodeIfPresent([String].self, forKey: .coTechMemberIds)) ?? []
        accessMethod = (try? c.decodeIfPresent(String.self, forKey: .accessMethod)) ?? nil
        accessNotes = (try? c.decodeIfPresent(String.self, forKey: .accessNotes)) ?? nil
    }

    init(
        id: String? = nil,
        memberId: String? = nil,
        memberName: String? = nil,
        memberRole: String? = nil,
        memberRoleLabel: String? = nil,
        routeDate: String? = nil,
        windowStartTime: String? = nil,
        windowEndTime: String? = nil,
        stopOrder: Int? = nil,
        routeNotes: String? = nil,
        clockInAt: String? = nil,
        clockOutAt: String? = nil,
        pausedSeconds: Int = 0,
        clockInLat: Double? = nil,
        clockInLng: Double? = nil,
        clockInAccuracyM: Int? = nil,
        techNotesCount: Int = 0,
        coTechMemberIds: [String] = [],
        accessMethod: String? = nil,
        accessNotes: String? = nil
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.memberRole = memberRole
        self.memberRoleLabel = memberRoleLabel
        self.routeDate = routeDate
        self.windowStartTime = windowStartTime
        self.windowEndTime = windowEndTime
        self.stopOrder = stopOrder
        self.routeNotes = routeNotes
        self.clockInAt = clockInAt
        self.clockOutAt = clockOutAt
        self.pausedSeconds = pausedSeconds
        self.clockInLat = clockInLat
        self.clockInLng = clockInLng
        self.clockInAccuracyM = clockInAccuracyM
        self.techNotesCount = techNotesCount
        self.coTechMemberIds = coTechMemberIds
        self.accessMethod = accessMethod
        self.accessNotes = accessNotes
    }
}

struct HavenFieldLatestMessage: Codable, Hashable {
    let senderRole: String?
    let body: String?
    let createdAt: String?
}

/// Wave M6 — internal tech note row. Distinct from
/// `HavenFieldLatestMessage` (which is the customer-visible thread). Tech
/// notes are workspace-only and never surface on the homeowner's iOS app.
/// Resilient decoder so a single bad row doesn't take down the array.
struct HavenFieldTechNote: Codable, Identifiable, Hashable {
    let id: String
    let requestId: String
    let authorMemberId: String
    let authorName: String
    let body: String
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case requestId
        case authorMemberId
        case authorName
        case body
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? ""
        authorMemberId = (try? c.decodeIfPresent(String.self, forKey: .authorMemberId)) ?? ""
        authorName = (try? c.decodeIfPresent(String.self, forKey: .authorName)) ?? "Workspace member"
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? ""
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
    }

    init(id: String, requestId: String, authorMemberId: String, authorName: String, body: String, createdAt: String?) {
        self.id = id
        self.requestId = requestId
        self.authorMemberId = authorMemberId
        self.authorName = authorName
        self.body = body
        self.createdAt = createdAt
    }
}

struct HavenFieldQuoteSummary: Codable, Hashable {
    let id: String?
    let status: String?
    let statusLabel: String?
    let total: Double?
    let updatedAt: String?
    let publicShareUrl: String?
    /// Wave M4 — kitchen-table signature artifact. Server stamps these
    /// when the field tech captures a finger-drawn signature on the
    /// iPad. signatureSignedUrl is a 1-hour TTL URL the iOS UI hands
    /// AsyncImage so the post-sign confirmation strip renders the
    /// captured PNG inline. Resilient decoder so legacy quote rows
    /// (pre-M4) without these columns still hydrate cleanly.
    let signedAt: String?
    let signedName: String?
    let signerRole: String?
    let signaturePath: String?
    let signatureSignedUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, statusLabel, total, updatedAt, publicShareUrl
        case signedAt, signedName, signerRole, signaturePath, signatureSignedUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        statusLabel = (try? c.decodeIfPresent(String.self, forKey: .statusLabel)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
        updatedAt = (try? c.decodeIfPresent(String.self, forKey: .updatedAt)) ?? nil
        publicShareUrl = (try? c.decodeIfPresent(String.self, forKey: .publicShareUrl)) ?? nil
        signedAt = (try? c.decodeIfPresent(String.self, forKey: .signedAt)) ?? nil
        signedName = (try? c.decodeIfPresent(String.self, forKey: .signedName)) ?? nil
        signerRole = (try? c.decodeIfPresent(String.self, forKey: .signerRole)) ?? nil
        signaturePath = (try? c.decodeIfPresent(String.self, forKey: .signaturePath)) ?? nil
        signatureSignedUrl = (try? c.decodeIfPresent(String.self, forKey: .signatureSignedUrl)) ?? nil
    }
}

/// Wave M4 — one editable line on the kitchen-table BuildQuoteSheet.
/// Mirrors the snake_case shape `provider_quotes.line_items` rounds-trip
/// in via save_quote_bundle. punchItemId is set when the line was
/// pre-filled from a punch item; null when the field tech added a
/// fresh row.
struct HavenFieldQuoteDraftLine: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var description: String
    var unit: String
    var quantity: Double
    var unitPrice: Double
    var punchItemId: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, unit, quantity, unitPrice, punchItemId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? ""
        unit = (try? c.decodeIfPresent(String.self, forKey: .unit)) ?? "ea"
        quantity = (try? c.decodeIfPresent(Double.self, forKey: .quantity)) ?? 1
        unitPrice = (try? c.decodeIfPresent(Double.self, forKey: .unitPrice)) ?? 0
        punchItemId = (try? c.decodeIfPresent(String.self, forKey: .punchItemId)) ?? nil
    }

    init(
        id: String = UUID().uuidString,
        name: String = "",
        description: String = "",
        unit: String = "ea",
        quantity: Double = 1,
        unitPrice: Double = 0,
        punchItemId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.unit = unit
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.punchItemId = punchItemId
    }

    /// Computed total for the editor footer + the per-row display.
    var lineTotal: Double { (quantity * unitPrice * 100.0).rounded() / 100.0 }
}

/// Wave M4 — pre-fill payload returned by build_quote_from_visit.
/// The field tech edits these in the BuildQuoteSheet, then the save
/// round-trips through save_quote_bundle / send_quote_bundle which
/// owns the canonical quote row insert.
struct HavenFieldQuoteDraftPayload: Codable, Hashable {
    let requestId: String?
    let householdId: String?
    let propertyId: String?
    let contractorId: String?
    let visitTaskId: String?
    let workspaceId: String?
    let title: String
    let lineItems: [HavenFieldQuoteDraftLine]
    let subtotal: Double
    let taxTotal: Double
    let total: Double
    let defaultHourlyRateCents: Int
    let eligibleCount: Int
    let visitedCount: Int

    private enum CodingKeys: String, CodingKey {
        case requestId, householdId, propertyId, contractorId, visitTaskId, workspaceId
        case title, lineItems, subtotal, taxTotal, total
        case defaultHourlyRateCents, eligibleCount, visitedCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? nil
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? nil
        propertyId = (try? c.decodeIfPresent(String.self, forKey: .propertyId)) ?? nil
        contractorId = (try? c.decodeIfPresent(String.self, forKey: .contractorId)) ?? nil
        visitTaskId = (try? c.decodeIfPresent(String.self, forKey: .visitTaskId)) ?? nil
        workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? nil
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? "Untitled quote"
        lineItems = (try? c.decodeIfPresent([HavenFieldQuoteDraftLine].self, forKey: .lineItems)) ?? []
        subtotal = (try? c.decodeIfPresent(Double.self, forKey: .subtotal)) ?? 0
        taxTotal = (try? c.decodeIfPresent(Double.self, forKey: .taxTotal)) ?? 0
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? 0
        defaultHourlyRateCents = (try? c.decodeIfPresent(Int.self, forKey: .defaultHourlyRateCents)) ?? 12500
        eligibleCount = (try? c.decodeIfPresent(Int.self, forKey: .eligibleCount)) ?? 0
        visitedCount = (try? c.decodeIfPresent(Int.self, forKey: .visitedCount)) ?? 0
    }
}

/// Wave M4 — bundle tier payload for save_quote_bundle round-trip.
/// Used when the field tech adds a good/better/best multi-tier toggle
/// to the kitchen-table quote. snake_case keys mirror the edge-fn
/// shape; line items use unit_price for the same reason.
struct HavenFieldQuoteDraftBundleTier: Codable, Hashable {
    let label: String
    let lineItems: [HavenFieldQuoteDraftBundleLine]
    let scopeNotes: String?

    private enum CodingKeys: String, CodingKey {
        case label, lineItems, scopeNotes
    }

    init(label: String, lineItems: [HavenFieldQuoteDraftLine], scopeNotes: String? = nil) {
        self.label = label
        self.lineItems = lineItems.map { line in
            HavenFieldQuoteDraftBundleLine(
                id: line.id,
                name: line.name,
                description: line.description,
                unit: line.unit,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                punchItemId: line.punchItemId
            )
        }
        self.scopeNotes = scopeNotes
    }
}

struct HavenFieldQuoteDraftBundleLine: Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let unit: String
    let quantity: Double
    let unitPrice: Double
    let punchItemId: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, unit, quantity
        case unitPrice = "unit_price"
        case punchItemId = "punch_item_id"
    }
}

/// Wave M4 — server-side row returned by save_quote / save_quote_bundle.
/// Resilient decoder so a future schema bump (e.g. new line item
/// fields) doesn't take the whole save round-trip down.
struct HavenFieldQuoteDraftSavedRow: Codable, Hashable {
    let id: String
    let status: String?
    let total: Double?
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, total, title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? nil
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? nil
    }
}

struct HavenFieldQuoteDraftDelivery: Codable, Hashable {
    let sent: Bool
    let channel: String?
    let recipientCount: Int?

    private enum CodingKeys: String, CodingKey {
        case sent, channel, recipientCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sent = (try? c.decodeIfPresent(Bool.self, forKey: .sent)) ?? false
        channel = (try? c.decodeIfPresent(String.self, forKey: .channel)) ?? nil
        recipientCount = (try? c.decodeIfPresent(Int.self, forKey: .recipientCount)) ?? nil
    }
}

struct HavenFieldQuoteDraftSaveResult {
    let parent: HavenFieldQuoteDraftSavedRow?
    let children: [HavenFieldQuoteDraftSavedRow]
    let delivery: HavenFieldQuoteDraftDelivery?
}

/// Wave M4 — server-side quote shape returned by sign_quote. Renders
/// in the post-sign confirmation strip of the BuildQuoteSheet.
struct HavenFieldSignedQuote: Codable, Hashable {
    let id: String
    let status: String
    let signaturePath: String?
    let signatureSignedUrl: String?
    let signedAt: String?
    let signedName: String?
    let signerRole: String?
    let approvedAt: String?
    let total: Double
    let title: String

    private enum CodingKeys: String, CodingKey {
        case id, status, signaturePath, signatureSignedUrl
        case signedAt, signedName, signerRole, approvedAt, total, title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "approved"
        signaturePath = (try? c.decodeIfPresent(String.self, forKey: .signaturePath)) ?? nil
        signatureSignedUrl = (try? c.decodeIfPresent(String.self, forKey: .signatureSignedUrl)) ?? nil
        signedAt = (try? c.decodeIfPresent(String.self, forKey: .signedAt)) ?? nil
        signedName = (try? c.decodeIfPresent(String.self, forKey: .signedName)) ?? nil
        signerRole = (try? c.decodeIfPresent(String.self, forKey: .signerRole)) ?? nil
        approvedAt = (try? c.decodeIfPresent(String.self, forKey: .approvedAt)) ?? nil
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? 0
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
    }
}

// MARK: - Wave M13 — Quote duplication picker models
//
// Powers "Or duplicate from another quote" inside M4's
// FieldBuildQuoteSheet. Single network round-trip per picker open
// (`list_recent_quotes`) returns up to 50 quotes scoped to the
// signed-in tech's workspace, sorted reverse-chronologically. Picker
// row includes everything needed to render the cell without a second
// hop: customer name + address + total + status pill + signed flag +
// line item count + bundle flag.
//
// Tap-to-pick fires `duplicate_quote` which inserts a fresh draft
// (signature fields cleared, punch_item_id stripped per line) and
// returns a draft payload mirroring HavenFieldQuoteDraftPayload so
// the BuildQuoteSheet hydrates without a second round-trip.
//
// Same model type works for both single-tier and bundle source
// quotes; `isBundle` is the discriminator. The picker shows bundle
// rows with a small "BUNDLE" pill so the tech knows what they're
// duplicating.

/// Wave M13 — single quote summary returned by `list_recent_quotes`.
/// Resilient decoders so a row with a missing field (e.g. legacy
/// quote without prospect_name) hydrates as best it can without
/// taking the whole picker list down.
struct HavenFieldQuoteSummaryRow: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let customerName: String
    let customerAddress: String
    let total: Double
    let status: String
    let statusLabel: String
    let lineItemCount: Int
    let isBundle: Bool
    let isSigned: Bool
    let signedName: String?
    let updatedAt: String?
    let createdAt: String?
    /// Source identifiers stamped at write time so the duplicate flow
    /// can pre-fill `duplicate_quote` without a second lookup. The
    /// duplicate routes the new draft to a DIFFERENT household, so
    /// the iOS picker doesn't surface these to the user; they're
    /// tucked under the row for analytics + audit only.
    let householdId: String?
    let propertyId: String?
    let requestId: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, customerName, customerAddress
        case total, status, statusLabel, lineItemCount
        case isBundle, isSigned, signedName, updatedAt, createdAt
        case householdId, propertyId, requestId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? "Untitled quote"
        customerName = (try? c.decodeIfPresent(String.self, forKey: .customerName)) ?? "Customer"
        customerAddress = (try? c.decodeIfPresent(String.self, forKey: .customerAddress)) ?? ""
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? 0
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "draft"
        statusLabel = (try? c.decodeIfPresent(String.self, forKey: .statusLabel)) ?? "Draft"
        lineItemCount = (try? c.decodeIfPresent(Int.self, forKey: .lineItemCount)) ?? 0
        isBundle = (try? c.decodeIfPresent(Bool.self, forKey: .isBundle)) ?? false
        isSigned = (try? c.decodeIfPresent(Bool.self, forKey: .isSigned)) ?? false
        signedName = (try? c.decodeIfPresent(String.self, forKey: .signedName)) ?? nil
        updatedAt = (try? c.decodeIfPresent(String.self, forKey: .updatedAt)) ?? nil
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? nil
        propertyId = (try? c.decodeIfPresent(String.self, forKey: .propertyId)) ?? nil
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? nil
    }
}

/// Wave M13 — list_recent_quotes response wrapper. `quotes` is the
/// recency-sorted slice; `daysBack` + `limit` echo the request params
/// so the picker UI can render the active filter chip.
struct HavenFieldQuoteSummaryList: Codable {
    let quotes: [HavenFieldQuoteSummaryRow]
    let daysBack: Int
    let limit: Int

    private enum CodingKeys: String, CodingKey {
        case quotes, daysBack, limit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quotes = (try? c.decodeIfPresent([HavenFieldQuoteSummaryRow].self, forKey: .quotes)) ?? []
        daysBack = (try? c.decodeIfPresent(Int.self, forKey: .daysBack)) ?? 30
        limit = (try? c.decodeIfPresent(Int.self, forKey: .limit)) ?? 50
    }
}

/// Wave M13 — duplicate_quote response. The new draft id is in
/// `duplicate.id`; for single-tier sources, `duplicate.draft` is the
/// hydration payload for the BuildQuoteSheet (mirrors
/// HavenFieldQuoteDraftPayload). For bundle sources, `draft` is nil
/// and `childIds` lists the new tier child rows.
struct HavenFieldQuoteDuplicateResult: Codable {
    let duplicate: HavenFieldQuoteDuplicatePayload

    private enum CodingKeys: String, CodingKey {
        case duplicate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        duplicate = try c.decode(HavenFieldQuoteDuplicatePayload.self, forKey: .duplicate)
    }
}

struct HavenFieldQuoteDuplicatePayload: Codable {
    let id: String
    let isBundle: Bool
    let title: String
    let sourceQuoteId: String
    let childIds: [String]?
    let draft: HavenFieldQuoteDraftPayload?

    private enum CodingKeys: String, CodingKey {
        case id, isBundle, title, sourceQuoteId, childIds, draft
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        isBundle = (try? c.decodeIfPresent(Bool.self, forKey: .isBundle)) ?? false
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? "Untitled"
        sourceQuoteId = (try? c.decodeIfPresent(String.self, forKey: .sourceQuoteId)) ?? ""
        childIds = (try? c.decodeIfPresent([String].self, forKey: .childIds)) ?? nil
        draft = (try? c.decodeIfPresent(HavenFieldQuoteDraftPayload.self, forKey: .draft)) ?? nil
    }
}

// MARK: - Wave M11 — End-of-day summary models
//
// Mirrors the response shape of the `today_summary` action on
// handyman-provider. Three nested types: the parent envelope, the
// today block (with stops + clock totals + materials + revenue), and
// the tomorrow preview. Resilient decoders throughout so a single bad
// stop or a missing tomorrow block degrades gracefully without taking
// the whole sheet down.

struct HavenFieldDayStop: Codable, Identifiable, Hashable {
    let requestId: String
    let customerName: String
    let address: String
    let title: String
    let clockInAt: String?
    let clockOutAt: String?
    let totalMinutes: Int
    let invoiceId: String?

    var id: String { requestId }

    private enum CodingKeys: String, CodingKey {
        case requestId
        case customerName
        case address
        case title
        case clockInAt
        case clockOutAt
        case totalMinutes
        case invoiceId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? ""
        customerName = (try? c.decodeIfPresent(String.self, forKey: .customerName)) ?? "Customer"
        address = (try? c.decodeIfPresent(String.self, forKey: .address)) ?? ""
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? "Visit"
        clockInAt = (try? c.decodeIfPresent(String.self, forKey: .clockInAt)) ?? nil
        clockOutAt = (try? c.decodeIfPresent(String.self, forKey: .clockOutAt)) ?? nil
        totalMinutes = (try? c.decodeIfPresent(Int.self, forKey: .totalMinutes)) ?? 0
        invoiceId = (try? c.decodeIfPresent(String.self, forKey: .invoiceId)) ?? nil
    }

    init(
        requestId: String,
        customerName: String,
        address: String,
        title: String,
        clockInAt: String?,
        clockOutAt: String?,
        totalMinutes: Int,
        invoiceId: String?
    ) {
        self.requestId = requestId
        self.customerName = customerName
        self.address = address
        self.title = title
        self.clockInAt = clockInAt
        self.clockOutAt = clockOutAt
        self.totalMinutes = totalMinutes
        self.invoiceId = invoiceId
    }
}

struct HavenFieldDayToday: Codable, Hashable {
    let date: String
    let stopsCompleted: Int
    let stopsRemaining: Int
    let totalClockMinutes: Int
    let materialsCostCents: Int
    let revenueInvoicedCents: Int
    let stops: [HavenFieldDayStop]

    private enum CodingKeys: String, CodingKey {
        case date
        case stopsCompleted
        case stopsRemaining
        case totalClockMinutes
        case materialsCostCents
        case revenueInvoicedCents
        case stops
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = (try? c.decodeIfPresent(String.self, forKey: .date)) ?? ""
        stopsCompleted = (try? c.decodeIfPresent(Int.self, forKey: .stopsCompleted)) ?? 0
        stopsRemaining = (try? c.decodeIfPresent(Int.self, forKey: .stopsRemaining)) ?? 0
        totalClockMinutes = (try? c.decodeIfPresent(Int.self, forKey: .totalClockMinutes)) ?? 0
        materialsCostCents = (try? c.decodeIfPresent(Int.self, forKey: .materialsCostCents)) ?? 0
        revenueInvoicedCents = (try? c.decodeIfPresent(Int.self, forKey: .revenueInvoicedCents)) ?? 0
        // One bad stop element shouldn't take the whole array down. The
        // try? at the array level lets a future shape drift on a single
        // row degrade the bad row to skipped without losing the rest.
        stops = (try? c.decodeIfPresent([HavenFieldDayStop].self, forKey: .stops)) ?? []
    }

    init(
        date: String,
        stopsCompleted: Int,
        stopsRemaining: Int,
        totalClockMinutes: Int,
        materialsCostCents: Int,
        revenueInvoicedCents: Int,
        stops: [HavenFieldDayStop]
    ) {
        self.date = date
        self.stopsCompleted = stopsCompleted
        self.stopsRemaining = stopsRemaining
        self.totalClockMinutes = totalClockMinutes
        self.materialsCostCents = materialsCostCents
        self.revenueInvoicedCents = revenueInvoicedCents
        self.stops = stops
    }
}

struct HavenFieldDayTomorrow: Codable, Hashable {
    let date: String
    let stopsCount: Int
    let firstAt: String?
    let firstCustomer: String?
    /// Phase-stub for a future weather API integration. Server returns
    /// null today; we keep the field decoded so the UI can render it
    /// once a back-end weather lookup ships without a model migration.
    let weather: String?

    private enum CodingKeys: String, CodingKey {
        case date
        case stopsCount
        case firstAt
        case firstCustomer
        case weather
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = (try? c.decodeIfPresent(String.self, forKey: .date)) ?? ""
        stopsCount = (try? c.decodeIfPresent(Int.self, forKey: .stopsCount)) ?? 0
        firstAt = (try? c.decodeIfPresent(String.self, forKey: .firstAt)) ?? nil
        firstCustomer = (try? c.decodeIfPresent(String.self, forKey: .firstCustomer)) ?? nil
        weather = (try? c.decodeIfPresent(String.self, forKey: .weather)) ?? nil
    }

    init(date: String, stopsCount: Int, firstAt: String?, firstCustomer: String?, weather: String?) {
        self.date = date
        self.stopsCount = stopsCount
        self.firstAt = firstAt
        self.firstCustomer = firstCustomer
        self.weather = weather
    }
}

struct HavenFieldDaySummary: Codable, Hashable {
    let today: HavenFieldDayToday
    let tomorrow: HavenFieldDayTomorrow

    private enum CodingKeys: String, CodingKey {
        case today
        case tomorrow
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Defensive defaults — if the server ever drifts the shape,
        // an empty Today / Tomorrow block renders the empty state
        // rather than crashing the sheet.
        today = (try? c.decodeIfPresent(HavenFieldDayToday.self, forKey: .today))
            ?? HavenFieldDayToday(
                date: "",
                stopsCompleted: 0,
                stopsRemaining: 0,
                totalClockMinutes: 0,
                materialsCostCents: 0,
                revenueInvoicedCents: 0,
                stops: []
            )
        tomorrow = (try? c.decodeIfPresent(HavenFieldDayTomorrow.self, forKey: .tomorrow))
            ?? HavenFieldDayTomorrow(
                date: "",
                stopsCount: 0,
                firstAt: nil,
                firstCustomer: nil,
                weather: nil
            )
    }

    init(today: HavenFieldDayToday, tomorrow: HavenFieldDayTomorrow) {
        self.today = today
        self.tomorrow = tomorrow
    }
}

// MARK: - Wave M5 invoice models

/// Wave M5 — pre-fill payload returned by `convert_visit_to_invoice`.
/// Mirrors `HavenFieldQuoteDraftPayload` shape so the editor sheet
/// pattern can be cleanly forked from `FieldBuildQuoteSheet`. The
/// field tech edits these in-memory in `FieldBuildInvoiceSheet`,
/// then save / send round-trip through `save_invoice` /
/// `send_invoice`.
struct HavenFieldInvoiceDraftPayload: Codable, Hashable {
    let requestId: String?
    let householdId: String?
    let propertyId: String?
    let contractorId: String?
    let visitTaskId: String?
    let workspaceId: String?
    let title: String
    let lineItems: [HavenFieldQuoteDraftLine]
    let subtotal: Double
    let taxTotal: Double
    let total: Double
    let defaultHourlyRateCents: Int
    let eligibleCount: Int
    let visitedCount: Int

    private enum CodingKeys: String, CodingKey {
        case requestId, householdId, propertyId, contractorId, visitTaskId, workspaceId
        case title, lineItems, subtotal, taxTotal, total
        case defaultHourlyRateCents, eligibleCount, visitedCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        requestId = (try? c.decodeIfPresent(String.self, forKey: .requestId)) ?? nil
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? nil
        propertyId = (try? c.decodeIfPresent(String.self, forKey: .propertyId)) ?? nil
        contractorId = (try? c.decodeIfPresent(String.self, forKey: .contractorId)) ?? nil
        visitTaskId = (try? c.decodeIfPresent(String.self, forKey: .visitTaskId)) ?? nil
        workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? nil
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        lineItems = (try? c.decodeIfPresent([HavenFieldQuoteDraftLine].self, forKey: .lineItems)) ?? []
        subtotal = (try? c.decodeIfPresent(Double.self, forKey: .subtotal)) ?? 0
        taxTotal = (try? c.decodeIfPresent(Double.self, forKey: .taxTotal)) ?? 0
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? 0
        defaultHourlyRateCents = (try? c.decodeIfPresent(Int.self, forKey: .defaultHourlyRateCents)) ?? 12500
        eligibleCount = (try? c.decodeIfPresent(Int.self, forKey: .eligibleCount)) ?? 0
        visitedCount = (try? c.decodeIfPresent(Int.self, forKey: .visitedCount)) ?? 0
    }
}

/// Wave M5 — server row returned by save_invoice / send_invoice.
/// Resilient decoder tolerates pre-Wave-M5 shapes that don't expose
/// every column (e.g. legacy invoices without amount_paid / sent_at).
struct HavenFieldInvoiceRow: Codable, Hashable {
    let id: String
    let invoiceNumber: String?
    let title: String?
    let status: String?
    let subtotal: Double
    let taxTotal: Double
    let total: Double
    let amountPaid: Double
    let sentAt: String?
    let paidAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case invoiceNumber = "invoice_number"
        case title
        case status
        case subtotal
        case taxTotal = "tax_total"
        case total
        case amountPaid = "amount_paid"
        case sentAt = "sent_at"
        case paidAt = "paid_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        invoiceNumber = (try? c.decodeIfPresent(String.self, forKey: .invoiceNumber)) ?? nil
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? nil
        status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "draft"
        subtotal = (try? c.decodeIfPresent(Double.self, forKey: .subtotal)) ?? 0
        taxTotal = (try? c.decodeIfPresent(Double.self, forKey: .taxTotal)) ?? 0
        total = (try? c.decodeIfPresent(Double.self, forKey: .total)) ?? 0
        amountPaid = (try? c.decodeIfPresent(Double.self, forKey: .amountPaid)) ?? 0
        sentAt = (try? c.decodeIfPresent(String.self, forKey: .sentAt)) ?? nil
        paidAt = (try? c.decodeIfPresent(String.self, forKey: .paidAt)) ?? nil
    }
}

// MARK: - Wave M7 crew chat models

/// Wave M7 — single message inside a `crew_chat_threads` row. Author
/// name joins from `provider_workspace_members.full_name`. Resilient
/// decoder so a malformed row doesn't take down the whole conversation.
struct HavenFieldCrewChatMessage: Codable, Identifiable, Hashable {
    let id: String
    let threadId: String
    let workspaceId: String?
    let senderMemberId: String
    let senderName: String
    let body: String
    let attachments: [String]
    let readBy: [String]
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case threadId
        case workspaceId
        case senderMemberId
        case senderName
        case body
        case attachments
        case readBy
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        threadId = (try? c.decodeIfPresent(String.self, forKey: .threadId)) ?? ""
        workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? nil
        senderMemberId = (try? c.decodeIfPresent(String.self, forKey: .senderMemberId)) ?? ""
        senderName = (try? c.decodeIfPresent(String.self, forKey: .senderName)) ?? "Workspace member"
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? ""
        // Attachments today are an opaque array of identifiers; future
        // versions may carry richer shapes (signed URLs, mime types).
        // Decode as `[String]` and fall back to empty array.
        attachments = (try? c.decodeIfPresent([String].self, forKey: .attachments)) ?? []
        readBy = (try? c.decodeIfPresent([String].self, forKey: .readBy)) ?? []
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
    }

    init(
        id: String,
        threadId: String,
        workspaceId: String? = nil,
        senderMemberId: String,
        senderName: String,
        body: String,
        attachments: [String] = [],
        readBy: [String] = [],
        createdAt: String? = nil
    ) {
        self.id = id
        self.threadId = threadId
        self.workspaceId = workspaceId
        self.senderMemberId = senderMemberId
        self.senderName = senderName
        self.body = body
        self.attachments = attachments
        self.readBy = readBy
        self.createdAt = createdAt
    }
}

/// Wave M7 — last-message preview embedded in the thread list payload.
/// Shape mirrors `HavenFieldCrewChatMessage` but stripped down to the
/// fields the row card needs.
struct HavenFieldCrewChatLastMessage: Codable, Hashable {
    let id: String?
    let body: String
    let senderMemberId: String?
    let senderName: String
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, body, senderMemberId, senderName, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? ""
        senderMemberId = (try? c.decodeIfPresent(String.self, forKey: .senderMemberId)) ?? nil
        senderName = (try? c.decodeIfPresent(String.self, forKey: .senderName)) ?? "Workspace member"
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
    }
}

/// Wave M7 — one row in the Crew tab's thread list. Carries enough
/// state to render the row WITHOUT drilling into the thread itself.
/// `unreadCount` is computed server-side per the calling member.
struct HavenFieldCrewChatThread: Codable, Identifiable, Hashable {
    let id: String
    let workspaceId: String
    let name: String?
    /// One of `general` / `route_day` / `tech_pair`. The native UI uses
    /// it for the row icon — generals get the bubble icon, route_day
    /// gets the calendar icon, tech_pair gets the two-people icon.
    let kind: String
    let createdAt: String?
    let lastMessage: HavenFieldCrewChatLastMessage?
    let unreadCount: Int

    private enum CodingKeys: String, CodingKey {
        case id, workspaceId, name, kind, createdAt, lastMessage, unreadCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        workspaceId = (try? c.decodeIfPresent(String.self, forKey: .workspaceId)) ?? ""
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? nil
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? "general"
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? nil
        lastMessage = (try? c.decodeIfPresent(HavenFieldCrewChatLastMessage.self, forKey: .lastMessage)) ?? nil
        unreadCount = (try? c.decodeIfPresent(Int.self, forKey: .unreadCount)) ?? 0
    }

    /// Display label fall-back chain: explicit name → "Tuesday route"-
    /// style stub for `route_day` rows lacking a name → "Direct chat"
    /// for `tech_pair` → "Crew chat" otherwise.
    var displayName: String {
        if let trimmed = name?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty {
            return trimmed
        }
        switch kind {
        case "route_day": return "Route day"
        case "tech_pair": return "Direct chat"
        default: return "Crew chat"
        }
    }

    /// SF Symbol the thread row + thread header use to identify the
    /// thread kind at a glance.
    var iconName: String {
        switch kind {
        case "route_day": return "calendar.badge.clock"
        case "tech_pair": return "person.2.fill"
        default: return "bubble.left.and.bubble.right.fill"
        }
    }
}

/// Wave M7 — workspace member roster row consumed by the new-thread
/// sheet's member picker and the in-thread sender name lookup. Pulled
/// from PostgREST direct against `provider_workspace_members`.
struct HavenFieldCrewChatMember: Identifiable, Hashable {
    let id: String
    let role: String
    let fullName: String?
    let email: String?
    let status: String

    /// Display name fall-back chain: full name → local part of the
    /// email → "Workspace member". Used in chip pickers, message
    /// bubbles, and the read-receipt list.
    var displayName: String {
        if let trimmed = fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            return trimmed
        }
        if let email, !email.isEmpty {
            return email.split(separator: "@").first.map(String.init) ?? email
        }
        return "Workspace member"
    }

    /// Two-letter initials for the avatar bubble. Falls back to "?"
    /// for completely unknown rows so we never render an empty disc.
    var initials: String {
        let source = displayName
        let parts = source.split(separator: " ").compactMap { $0.first }
        if parts.count >= 2 {
            return String([parts.first!, parts.last!]).uppercased()
        }
        if let first = parts.first {
            return String(first).uppercased()
        }
        return "?"
    }
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
    /// T3.5 (post-overnight) — homeowner standing instructions surface.
    /// Sourced from `households.chez_profile` JSONB; server passes only
    /// the contractor-relevant subset (spending tiers + vendor prefs +
    /// logistics). Communication prefs are intentionally not surfaced.
    let chezProfile: HavenFieldChezProfile?
    /// T3.1 (post-overnight) — recurring services on this home, sourced
    /// from the `routines` table. Defaults empty so pre-payload-extension
    /// rows decode fine.
    let routines: [HavenFieldHomeRoutine]
    /// T3.2 (post-overnight) — vendors the homeowner uses, sourced from
    /// the `contractors` table. Mirror of homeowner-side contractors
    /// list. Defaults empty.
    let vendors: [HavenFieldHomeVendor]

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
        case chezProfile
        case routines
        case vendors
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
        chezProfile = (try? container.decodeIfPresent(HavenFieldChezProfile.self, forKey: .chezProfile)) ?? nil
        routines = (try? container.decodeIfPresent([HavenFieldHomeRoutine].self, forKey: .routines)) ?? []
        vendors = (try? container.decodeIfPresent([HavenFieldHomeVendor].self, forKey: .vendors)) ?? []
    }
}

/// T3.1 (post-overnight) — per-home recurring service sourced from
/// the `routines` table. Read-only on the field side for now (write
/// surface lands when T2.6 RoutineCaptureSheet ships).
struct HavenFieldHomeRoutine: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let kind: String?
    let cadence: String?
    let daysOfWeek: [Int]
    let timeOfDay: String?
    let activeMonths: [Int]
    let vendorId: String?
    let costCents: Double?
    let setupState: String
    let chezOwned: Bool
    let paused: Bool

    private enum CodingKeys: String, CodingKey {
        case id, label, kind, cadence, daysOfWeek, timeOfDay
        case activeMonths, vendorId, costCents, setupState, chezOwned, paused
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        label = (try? c.decodeIfPresent(String.self, forKey: .label)) ?? "Routine"
        kind = (try? c.decodeIfPresent(String.self, forKey: .kind)) ?? nil
        cadence = (try? c.decodeIfPresent(String.self, forKey: .cadence)) ?? nil
        daysOfWeek = (try? c.decodeIfPresent([Int].self, forKey: .daysOfWeek)) ?? []
        timeOfDay = (try? c.decodeIfPresent(String.self, forKey: .timeOfDay)) ?? nil
        activeMonths = (try? c.decodeIfPresent([Int].self, forKey: .activeMonths)) ?? []
        vendorId = (try? c.decodeIfPresent(String.self, forKey: .vendorId)) ?? nil
        costCents = (try? c.decodeIfPresent(Double.self, forKey: .costCents)) ?? nil
        setupState = (try? c.decodeIfPresent(String.self, forKey: .setupState)) ?? "active"
        chezOwned = (try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)) ?? false
        paused = (try? c.decodeIfPresent(Bool.self, forKey: .paused)) ?? false
    }

    /// "Tuesdays · Apr-Nov · $200" or similar one-liner for row display.
    var summary: String {
        var parts: [String] = []
        if !daysOfWeek.isEmpty {
            let formatter = DateFormatter()
            let names = formatter.shortStandaloneWeekdaySymbols ?? []
            // ISO 8601 1=Sunday..7=Saturday per CLAUDE.md routines schema.
            let dayLabels = daysOfWeek.compactMap { day -> String? in
                guard day >= 1, day <= 7, names.count >= 7 else { return nil }
                return names[day - 1]
            }
            if !dayLabels.isEmpty {
                parts.append(dayLabels.joined(separator: ", "))
            }
        } else if let cadence = cadence?.nonEmpty {
            parts.append(cadence.replacingOccurrences(of: "_", with: " ").capitalized)
        }
        if !activeMonths.isEmpty, activeMonths.count < 12 {
            let monthNames = DateFormatter().shortStandaloneMonthSymbols ?? []
            if monthNames.count == 12, let first = activeMonths.first, let last = activeMonths.last,
               first >= 1, first <= 12, last >= 1, last <= 12 {
                parts.append("\(monthNames[first - 1])-\(monthNames[last - 1])")
            }
        }
        if let cents = costCents, cents > 0 {
            parts.append("$\(Int(cents / 100))")
        }
        return parts.joined(separator: " · ")
    }
}

/// T3.2 (post-overnight) — per-home vendor sourced from the
/// `contractors` table. Read-only on the field side for now (write
/// surface lands when T2.5 Add vendor sheet ships). Carries everything
/// needed for the row + tap-to-call / tap-to-email affordances.
struct HavenFieldHomeVendor: Codable, Identifiable, Hashable {
    let id: String
    let companyName: String
    let contactName: String?
    let phone: String?
    let email: String?
    let website: String?
    let category: String?
    let source: String
    let logoUrl: String?
    let brandColor: String?
    let chezOwned: Bool

    private enum CodingKeys: String, CodingKey {
        case id, companyName, contactName, phone, email, website
        case category, source, logoUrl, brandColor, chezOwned
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        companyName = (try? c.decodeIfPresent(String.self, forKey: .companyName)) ?? "Vendor"
        contactName = (try? c.decodeIfPresent(String.self, forKey: .contactName)) ?? nil
        phone = (try? c.decodeIfPresent(String.self, forKey: .phone)) ?? nil
        email = (try? c.decodeIfPresent(String.self, forKey: .email)) ?? nil
        website = (try? c.decodeIfPresent(String.self, forKey: .website)) ?? nil
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? nil
        source = (try? c.decodeIfPresent(String.self, forKey: .source)) ?? "manual"
        logoUrl = (try? c.decodeIfPresent(String.self, forKey: .logoUrl)) ?? nil
        brandColor = (try? c.decodeIfPresent(String.self, forKey: .brandColor)) ?? nil
        chezOwned = (try? c.decodeIfPresent(Bool.self, forKey: .chezOwned)) ?? false
    }
}

/// T3.5 (post-overnight) — read-only standing-instructions struct
/// derived from `households.chez_profile`. The server hands us the
/// contractor-relevant subset (spending tiers + vendor preferences +
/// logistics). Communication preferences are intentionally not
/// surfaced — those are between the homeowner and Chez (operator
/// channel choice). Fully resilient decoder so a partial / mis-shaped
/// JSON blob doesn't take the home payload down.
struct HavenFieldChezProfile: Codable, Hashable {
    let spendingTiers: SpendingTiers?
    let vendorPreferences: VendorPreferences?
    let logistics: Logistics?

    struct SpendingTiers: Codable, Hashable {
        /// Auto-approve under this dollar amount (default $200).
        let autoApproveUnder: Double?
        /// Ping homeowner under this dollar amount (default $500).
        let pingUnder: Double?
        /// Explicit homeowner approval required above this amount
        /// (default $500). Per CLAUDE.md, also gates the home_manager
        /// approval guardrail.
        let explicitAbove: Double?

        private enum CodingKeys: String, CodingKey {
            case autoApproveUnder = "auto_approve_under"
            case pingUnder = "ping_under"
            case explicitAbove = "explicit_above"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            autoApproveUnder = (try? c.decodeIfPresent(Double.self, forKey: .autoApproveUnder)) ?? nil
            pingUnder = (try? c.decodeIfPresent(Double.self, forKey: .pingUnder)) ?? nil
            explicitAbove = (try? c.decodeIfPresent(Double.self, forKey: .explicitAbove)) ?? nil
        }
    }

    struct VendorPreferences: Codable, Hashable {
        /// E.g. "value", "balanced", "premium" — homeowner's posture.
        let budgetOrientation: String?
        let preferLocalOwned: Bool?
        let notes: String?

        private enum CodingKeys: String, CodingKey {
            case budgetOrientation = "budget_orientation"
            case preferLocalOwned = "prefer_local_owned"
            case notes
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            budgetOrientation = (try? c.decodeIfPresent(String.self, forKey: .budgetOrientation)) ?? nil
            preferLocalOwned = (try? c.decodeIfPresent(Bool.self, forKey: .preferLocalOwned)) ?? nil
            notes = (try? c.decodeIfPresent(String.self, forKey: .notes)) ?? nil
        }
    }

    struct Logistics: Codable, Hashable {
        /// Free-text pet warnings. Critical for handyman safety.
        let pets: String?
        /// Free-text entry instructions ("Side gate code 1234. Lockbox
        /// on the back porch."). Most important field for HNW estates.
        let entryInstructions: String?

        private enum CodingKeys: String, CodingKey {
            case pets
            case entryInstructions = "entry_instructions"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            pets = (try? c.decodeIfPresent(String.self, forKey: .pets)) ?? nil
            entryInstructions = (try? c.decodeIfPresent(String.self, forKey: .entryInstructions)) ?? nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case spendingTiers, vendorPreferences, logistics
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spendingTiers = (try? c.decodeIfPresent(SpendingTiers.self, forKey: .spendingTiers)) ?? nil
        vendorPreferences = (try? c.decodeIfPresent(VendorPreferences.self, forKey: .vendorPreferences)) ?? nil
        logistics = (try? c.decodeIfPresent(Logistics.self, forKey: .logistics)) ?? nil
    }

    /// Returns true when there's nothing meaningful to render (avoids
    /// showing an empty "Standing instructions" card).
    var isEmpty: Bool {
        let st = spendingTiers
        let vp = vendorPreferences
        let lg = logistics
        let hasSpend = (st?.autoApproveUnder ?? nil) != nil ||
                       (st?.pingUnder ?? nil) != nil ||
                       (st?.explicitAbove ?? nil) != nil
        let hasVendor = (vp?.budgetOrientation?.nonEmpty != nil) ||
                        (vp?.preferLocalOwned ?? nil) != nil ||
                        (vp?.notes?.nonEmpty != nil)
        let hasLogistics = (lg?.pets?.nonEmpty != nil) ||
                           (lg?.entryInstructions?.nonEmpty != nil)
        return !(hasSpend || hasVendor || hasLogistics)
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
    // Wave M3 — system inventory authoring fields.
    let decommissionedAt: String?
    let decommissionReason: String?
    let markedForFollowupAt: String?
    let followupReason: String?
    let voiceNotePath: String?

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
        case decommissionedAt
        case decommissionReason
        case markedForFollowupAt
        case followupReason
        case voiceNotePath
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
        decommissionedAt = try? container.decodeIfPresent(String.self, forKey: .decommissionedAt)
        decommissionReason = try? container.decodeIfPresent(String.self, forKey: .decommissionReason)
        markedForFollowupAt = try? container.decodeIfPresent(String.self, forKey: .markedForFollowupAt)
        followupReason = try? container.decodeIfPresent(String.self, forKey: .followupReason)
        voiceNotePath = try? container.decodeIfPresent(String.self, forKey: .voiceNotePath)
    }

    /// Wave M3 — derived flag the UI uses to dim decommissioned systems
    /// and surface a "REMOVED" pill. Honors both the explicit timestamp
    /// and the legacy status string.
    var isDecommissioned: Bool {
        if let stamp = decommissionedAt, !stamp.isEmpty { return true }
        if status?.lowercased() == "decommissioned" { return true }
        return false
    }

    /// Wave M3 — true when the model plate fields are missing. Drives the
    /// "Incomplete systems" gap-fill list at the top of the systems tab.
    var hasIncompleteIdentity: Bool {
        let manuf = manufacturer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let model = modelNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let serial = serialNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return manuf.isEmpty || model.isEmpty || serial.isEmpty
    }

    /// Wave M3 — true when the tech flagged this system as needing a
    /// follow-up visit (couldn't access tenant area, breaker locked,
    /// etc.). Drives the orange "FOLLOW-UP" pill.
    var needsFollowup: Bool {
        guard let stamp = markedForFollowupAt else { return false }
        return !stamp.isEmpty
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

/// Wave M10 — one customer pin returned by `nearest_customers`. Distance
/// is in meters from the tech's current location. `address` is the
/// canonical "street, city, state, zip" join the server geocoded;
/// `latitude` / `longitude` are the resolved coords. The map renders one
/// `Marker` per row, the list renders one `NavigationLink` per row that
/// pushes `HavenFieldHomeProfileView` for the matching home.
struct HavenFieldNearbyCustomer: Codable, Identifiable, Hashable {
    var id: String { propertyId }
    let householdId: String
    let propertyId: String
    let customerName: String
    let address: String
    let latitude: Double
    let longitude: Double
    let distanceMeters: Int

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? ""
        propertyId = (try? c.decodeIfPresent(String.self, forKey: .propertyId)) ?? ""
        customerName = (try? c.decodeIfPresent(String.self, forKey: .customerName)) ?? "Customer"
        address = (try? c.decodeIfPresent(String.self, forKey: .address)) ?? ""
        latitude = (try? c.decodeIfPresent(Double.self, forKey: .latitude)) ?? 0
        longitude = (try? c.decodeIfPresent(Double.self, forKey: .longitude)) ?? 0
        distanceMeters = (try? c.decodeIfPresent(Int.self, forKey: .distanceMeters)) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case householdId, propertyId, customerName, address, latitude, longitude, distanceMeters
    }
}

/// Wave M10 — full payload returned by `nearest_customers`. `note` is
/// populated when the workspace has zero linked customers OR zero
/// customers with addresses on file (separate empty states).
struct HavenFieldNearbyCustomersPayload: Decodable {
    let ok: Bool
    let customers: [HavenFieldNearbyCustomer]
    let note: String?
    let geocodedCount: Int?
    let candidateCount: Int?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = (try? c.decodeIfPresent(Bool.self, forKey: .ok)) ?? false
        customers = (try? c.decodeIfPresent([HavenFieldNearbyCustomer].self, forKey: .customers)) ?? []
        note = try? c.decodeIfPresent(String.self, forKey: .note)
        geocodedCount = try? c.decodeIfPresent(Int.self, forKey: .geocodedCount)
        candidateCount = try? c.decodeIfPresent(Int.self, forKey: .candidateCount)
    }

    private enum CodingKeys: String, CodingKey {
        case ok, customers, note, geocodedCount, candidateCount
    }
}

/// Wave M10 — structured business-card extraction returned by
/// `extract_business_card`. All fields nullable because cards vary
/// wildly in completeness; the iOS confirmation card lets the tech
/// fill in anything Claude couldn't read.
struct HavenFieldBusinessCardExtraction: Codable {
    let ok: Bool
    let companyName: String?
    let contactName: String?
    let phone: String?
    let email: String?
    let website: String?
    let tradeCategory: String?
    let confidence: String?
    let rawText: String?
    let parseError: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = (try? c.decodeIfPresent(Bool.self, forKey: .ok)) ?? false
        companyName = try? c.decodeIfPresent(String.self, forKey: .companyName)
        contactName = try? c.decodeIfPresent(String.self, forKey: .contactName)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
        website = try? c.decodeIfPresent(String.self, forKey: .website)
        tradeCategory = try? c.decodeIfPresent(String.self, forKey: .tradeCategory)
        confidence = try? c.decodeIfPresent(String.self, forKey: .confidence)
        rawText = try? c.decodeIfPresent(String.self, forKey: .rawText)
        parseError = try? c.decodeIfPresent(String.self, forKey: .parseError)
    }

    private enum CodingKeys: String, CodingKey {
        case ok, companyName, contactName, phone, email, website
        case tradeCategory, confidence, rawText, parseError
    }
}

/// Wave M10 — response from `create_contractor_from_card`. Mirrors the
/// homeowner-side `contractors` row shape so the iOS UI can show "Saved
/// Acme Plumbing to Customer 4" with the right brand fields.
struct HavenFieldCreatedContractorPayload: Decodable {
    let ok: Bool
    let contractor: HavenFieldCreatedContractor?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = (try? c.decodeIfPresent(Bool.self, forKey: .ok)) ?? false
        contractor = try? c.decodeIfPresent(HavenFieldCreatedContractor.self, forKey: .contractor)
    }

    private enum CodingKeys: String, CodingKey { case ok, contractor }
}

struct HavenFieldCreatedContractor: Decodable, Identifiable {
    let id: String
    let householdId: String
    let companyName: String
    let contactName: String?
    let phone: String?
    let email: String?
    let website: String?
    let specialties: [String]?
    let source: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        householdId = (try? c.decodeIfPresent(String.self, forKey: .householdId)) ?? ""
        companyName = (try? c.decodeIfPresent(String.self, forKey: .companyName)) ?? ""
        contactName = try? c.decodeIfPresent(String.self, forKey: .contactName)
        phone = try? c.decodeIfPresent(String.self, forKey: .phone)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
        website = try? c.decodeIfPresent(String.self, forKey: .website)
        specialties = try? c.decodeIfPresent([String].self, forKey: .specialties)
        source = try? c.decodeIfPresent(String.self, forKey: .source)
    }

    private enum CodingKeys: String, CodingKey {
        case id, phone, email, website, specialties, source
        case householdId = "household_id"
        case companyName = "company_name"
        case contactName = "contact_name"
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

    // MARK: - Wave M1 visit lifecycle

    /// Wave M1 — clock in to a visit. Optional GPS coords + accuracy
    /// stamp `provider_visit_assignments.clock_in_at` + lat/lng. Server
    /// also flips `handyman_requests.status` to `in_progress` and writes
    /// an audit-trail message into the homeowner's thread. The
    /// CLLocationManager prompt and grant flow lives in the calling view
    /// — this method just forwards what we got.
    func startVisit(
        workspaceId: String,
        requestId: String,
        latitude: Double?,
        longitude: Double?,
        accuracy: Double?
    ) async throws -> HavenFieldVisitAssignment {
        struct Request: Encodable {
            let action = "start_visit"
            let workspaceId: String
            let requestId: String
            let latitude: Double?
            let longitude: Double?
            let accuracy: Double?
        }
        struct Response: Decodable {
            let assignment: HavenFieldVisitAssignment
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.assignment
    }

    /// Wave M1 — open a pause window with a reason. NO status flip; the
    /// visit stays in_progress. Server inserts a provider_visit_pauses
    /// row that resume_visit later closes by stamping resumed_at.
    /// Idempotent: if a pause is already open, the server returns it.
    func pauseVisit(workspaceId: String, requestId: String, reason: String) async throws {
        struct Request: Encodable {
            let action = "pause_visit"
            let workspaceId: String
            let requestId: String
            let reason: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            reason: reason
        ))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Wave M1 — close the open pause and bank the elapsed seconds into
    /// `assignments.paused_seconds`. The running clock subtracts this
    /// total from elapsed for the live counter on the iOS UI.
    func resumeVisit(workspaceId: String, requestId: String) async throws -> HavenFieldVisitAssignment {
        struct Request: Encodable {
            let action = "resume_visit"
            let workspaceId: String
            let requestId: String
        }
        struct Response: Decodable {
            let assignment: HavenFieldVisitAssignment
            let addedSeconds: Int?
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId, requestId: requestId))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.assignment
    }

    /// Wave M1 — clock out + flip request to completed. If a pause is
    /// open at the moment of completion, the server closes it before
    /// computing the total so a "forgot to resume" doesn't mis-credit
    /// minutes. Returns the final total seconds the iOS app shows.
    func completeVisit(workspaceId: String, requestId: String) async throws -> (assignment: HavenFieldVisitAssignment, totalSeconds: Int) {
        struct Request: Encodable {
            let action = "complete_visit"
            let workspaceId: String
            let requestId: String
        }
        struct Response: Decodable {
            let assignment: HavenFieldVisitAssignment
            let totalSeconds: Int?
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId, requestId: requestId))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return (response.assignment, response.totalSeconds ?? 0)
    }

    // MARK: - Wave M9 visit edge cases

    /// Wave M9 — append a workspace member to the visit's co-tech
    /// roster. Server validates membership in the same workspace + non-
    /// duplication. Returns the updated assignment so the local view
    /// state can pick up the new id without a full dashboard reload.
    func addCoTech(
        workspaceId: String,
        requestId: String,
        memberId: String
    ) async throws -> HavenFieldVisitAssignment {
        struct Request: Encodable {
            let action = "add_co_tech"
            let workspaceId: String
            let requestId: String
            let memberId: String
        }
        struct Response: Decodable {
            let assignment: HavenFieldVisitAssignment
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            memberId: memberId
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.assignment
    }

    /// Wave M9 — capture entry method + free-form notes (lockbox code,
    /// key location, door code, etc.). Saved on the assignment row so
    /// dispatch + the operator can both read it.
    func setAccessMethod(
        workspaceId: String,
        requestId: String,
        method: String,
        notes: String?
    ) async throws -> HavenFieldVisitAssignment {
        struct Request: Encodable {
            let action = "set_access_method"
            let workspaceId: String
            let requestId: String
            let method: String
            let notes: String?
        }
        struct Response: Decodable {
            let assignment: HavenFieldVisitAssignment
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            method: method,
            notes: notes
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.assignment
    }

    /// Wave M9 — end the running visit early. Closes any open pause
    /// window so paused_seconds banks correctly, stamps the cancellation
    /// reason, and (when partialState.scheduleFollowup is true) creates
    /// a placeholder follow-up request linked to this one.
    func cancelVisitMidStream(
        workspaceId: String,
        requestId: String,
        reason: String,
        scheduleFollowup: Bool,
        proposedDate: Date?,
        durationMinutes: Int
    ) async throws -> (status: String, followupRequestId: String?) {
        struct Partial: Encodable {
            let scheduleFollowup: Bool
            let proposedDate: String?
            let durationMinutes: Int
        }
        struct Request: Encodable {
            let action = "cancel_visit_mid_stream"
            let workspaceId: String
            let requestId: String
            let reason: String
            let partialState: Partial
        }
        struct ResponseRequest: Decodable {
            let id: String?
            let status: String?
            let cancellationReason: String?
            let cancelledAt: String?
            let cancelledByMemberId: String?
        }
        struct Response: Decodable {
            let request: ResponseRequest?
            let followupRequestId: String?
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        let partial = Partial(
            scheduleFollowup: scheduleFollowup,
            proposedDate: proposedDate.map(isoFormatter.string(from:)),
            durationMinutes: durationMinutes
        )
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            reason: reason,
            partialState: partial
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return (response.request?.status ?? "cancelled", response.followupRequestId)
    }

    // MARK: - Wave M4 kitchen-table close

    /// Wave M4 — pre-fill a draft quote from the visit's completed
    /// punch items. Returns line items with labor priced off the
    /// workspace's default hourly rate + materials rolled in. The
    /// field tech edits these in the BuildQuoteSheet, then save /
    /// send round-trip through the existing save_quote_bundle action.
    func buildQuoteFromVisit(
        workspaceId: String,
        requestId: String
    ) async throws -> HavenFieldQuoteDraftPayload {
        struct Request: Encodable {
            let action = "build_quote_from_visit"
            let workspaceId: String
            let requestId: String
        }
        struct Response: Decodable {
            let draft: HavenFieldQuoteDraftPayload
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.draft
    }

    /// Wave M4 — save a draft quote bundle (parent + tier children).
    /// `tiers` is at minimum 1 entry for a single-tier quote (the
    /// kitchen-table default) and up to 4 for good/better/best/premier.
    /// Server-side `save_quote_bundle` handles the parent insert and
    /// child rows in one round-trip.
    ///
    /// Note: the existing edge-fn `save_quote_bundle` action requires
    /// at least 2 tiers. The single-tier kitchen-table flow routes
    /// through `save_quote` instead — see `saveQuote(...)` below.
    func saveQuoteBundle(
        workspaceId: String,
        requestId: String?,
        householdId: String?,
        propertyId: String?,
        contractorId: String?,
        title: String,
        homeownerMessage: String?,
        tiers: [HavenFieldQuoteDraftBundleTier],
        send: Bool
    ) async throws -> HavenFieldQuoteDraftSaveResult {
        struct Request: Encodable {
            let action: String
            let workspaceId: String
            let requestId: String?
            let householdId: String?
            let propertyId: String?
            let contractorId: String?
            let title: String
            let homeownerMessage: String?
            let tiers: [HavenFieldQuoteDraftBundleTier]
        }
        struct Response: Decodable {
            let parent: HavenFieldQuoteDraftSavedRow?
            let children: [HavenFieldQuoteDraftSavedRow]?
            let delivery: HavenFieldQuoteDraftDelivery?
        }
        let payload = Request(
            action: send ? "send_quote_bundle" : "save_quote_bundle",
            workspaceId: workspaceId,
            requestId: requestId,
            householdId: householdId,
            propertyId: propertyId,
            contractorId: contractorId,
            title: title,
            homeownerMessage: homeownerMessage,
            tiers: tiers
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return HavenFieldQuoteDraftSaveResult(
            parent: response.parent,
            children: response.children ?? [],
            delivery: response.delivery
        )
    }

    /// Wave M4 — single-tier quote save / send. Used when the field
    /// tech builds a one-tier kitchen-table quote (the default). The
    /// existing `save_quote` / `send_quote` action handles single-tier
    /// rows directly without a bundle parent.
    func saveSingleQuote(
        workspaceId: String,
        requestId: String?,
        householdId: String?,
        propertyId: String?,
        contractorId: String?,
        title: String,
        homeownerMessage: String?,
        lineItems: [HavenFieldQuoteDraftLine],
        send: Bool
    ) async throws -> HavenFieldQuoteDraftSavedRow {
        struct LineItemPayload: Encodable {
            let id: String
            let name: String
            let description: String
            let unit: String
            let quantity: Double
            let unit_price: Double
            let punch_item_id: String?
        }
        struct Request: Encodable {
            let action: String
            let workspaceId: String
            let requestId: String?
            let householdId: String?
            let propertyId: String?
            let contractorId: String?
            let title: String
            let homeownerMessage: String?
            let lineItems: [LineItemPayload]
        }
        struct Response: Decodable {
            let quote: HavenFieldQuoteDraftSavedRow?
        }
        let payload = Request(
            action: send ? "send_quote" : "save_quote",
            workspaceId: workspaceId,
            requestId: requestId,
            householdId: householdId,
            propertyId: propertyId,
            contractorId: contractorId,
            title: title,
            homeownerMessage: homeownerMessage,
            lineItems: lineItems.map { line in
                LineItemPayload(
                    id: line.id,
                    name: line.name,
                    description: line.description,
                    unit: line.unit,
                    quantity: line.quantity,
                    unit_price: line.unitPrice,
                    punch_item_id: line.punchItemId
                )
            }
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        guard let quote = response.quote else {
            throw URLError(.zeroByteResource)
        }
        return quote
    }

    /// Wave M5 — pre-fill an invoice draft from a completed visit.
    /// Mirrors `buildQuoteFromVisit` but lands the lines on the
    /// invoice path. The field tech edits these in-memory in
    /// `FieldBuildInvoiceSheet`, then save / send round-trips
    /// through `save_invoice` / `send_invoice`.
    func convertVisitToInvoice(
        workspaceId: String,
        requestId: String
    ) async throws -> HavenFieldInvoiceDraftPayload {
        struct Request: Encodable {
            let action = "convert_visit_to_invoice"
            let workspaceId: String
            let requestId: String
        }
        struct Response: Decodable {
            let draft: HavenFieldInvoiceDraftPayload
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.draft
    }

    /// Wave M5 — save / send an invoice draft. Single round-trip via
    /// `save_invoice` (status=draft) or `send_invoice` (status=sent
    /// + mirrored to homeowner inbox + push). Reuses the editable
    /// `HavenFieldQuoteDraftLine` shape for line items so the editor
    /// surface can be cleanly forked from `FieldBuildQuoteSheet`.
    func saveInvoice(
        workspaceId: String,
        invoiceId: String?,
        requestId: String?,
        householdId: String?,
        propertyId: String?,
        contractorId: String?,
        title: String,
        homeownerMessage: String?,
        scopeNotes: String?,
        lineItems: [HavenFieldQuoteDraftLine],
        send: Bool
    ) async throws -> HavenFieldInvoiceRow {
        struct LineItemPayload: Encodable {
            let id: String
            let name: String
            let description: String
            let unit: String
            let quantity: Double
            let unit_price: Double
            let punch_item_id: String?
        }
        struct Request: Encodable {
            let action: String
            let workspaceId: String
            let invoiceId: String?
            let requestId: String?
            let householdId: String?
            let propertyId: String?
            let contractorId: String?
            let title: String
            let homeownerMessage: String?
            let scopeNotes: String?
            let lineItems: [LineItemPayload]
        }
        struct Response: Decodable {
            let invoice: HavenFieldInvoiceRow?
        }
        let payload = Request(
            action: send ? "send_invoice" : "save_invoice",
            workspaceId: workspaceId,
            invoiceId: invoiceId,
            requestId: requestId,
            householdId: householdId,
            propertyId: propertyId,
            contractorId: contractorId,
            title: title,
            homeownerMessage: homeownerMessage,
            scopeNotes: scopeNotes,
            lineItems: lineItems.map { line in
                LineItemPayload(
                    id: line.id,
                    name: line.name,
                    description: line.description,
                    unit: line.unit,
                    quantity: line.quantity,
                    unit_price: line.unitPrice,
                    punch_item_id: line.punchItemId
                )
            }
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        guard let invoice = response.invoice else {
            throw URLError(.zeroByteResource)
        }
        return invoice
    }

    /// Wave M4 — capture a finger-drawn signature on the iPad. Server
    /// uploads to the private quote-signatures bucket, stamps
    /// signed_at + signed_name + signature_path + signer_role, walks
    /// the quote to approved (when not already), and returns the
    /// signed-URL for the PNG so the post-sign confirmation strip
    /// renders inline.
    func signQuote(
        workspaceId: String,
        quoteId: String,
        signatureBase64: String,
        signedName: String,
        signerRole: String
    ) async throws -> HavenFieldSignedQuote {
        struct Request: Encodable {
            let action = "sign_quote"
            let workspaceId: String
            let quoteId: String
            let signatureBase64: String
            let signedName: String
            let signerRole: String
        }
        struct Response: Decodable {
            let quote: HavenFieldSignedQuote
        }
        let payload = Request(
            workspaceId: workspaceId,
            quoteId: quoteId,
            signatureBase64: signatureBase64,
            signedName: signedName,
            signerRole: signerRole
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.quote
    }

    // MARK: - Wave M13 quote duplication

    /// Wave M13 — list this workspace's recent quotes for the duplication
    /// picker inside FieldBuildQuoteSheet. `daysBack` defaults to 30 to
    /// match the picker's default filter chip; pass 90 / 365 / 3650 for
    /// the wider time windows.
    ///
    /// Bundle children are filtered server-side so the picker shows ONE
    /// row per bundle (the parent), not three Good/Better/Best rows.
    /// Sorted reverse-chronologically by `updated_at`. Capped at 200
    /// rows server-side; default 50.
    func listRecentQuotes(
        workspaceId: String,
        daysBack: Int = 30,
        limit: Int = 50
    ) async throws -> HavenFieldQuoteSummaryList {
        struct Request: Encodable {
            let action = "list_recent_quotes"
            let workspaceId: String
            let daysBack: Int
            let limit: Int
        }
        let payload = Request(
            workspaceId: workspaceId,
            daysBack: daysBack,
            limit: limit
        )
        let data = try JSONEncoder().encode(payload)
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldQuoteSummaryList.self
        )
    }

    /// Wave M13 — duplicate an existing quote into a fresh draft for a
    /// different customer. Source quote can be a single-tier or a
    /// bundle parent (children copied with new ids per tier).
    /// `targetPropertyId` and `targetRequestId` are optional — the
    /// server falls back to the source's IDs when omitted, but the
    /// kitchen-table flow always passes the current visit's request +
    /// property so the duplicate lands on the right context.
    ///
    /// Returns the new quote id + (for single-tier) a draft payload
    /// the BuildQuoteSheet can hydrate without a second round-trip.
    func duplicateQuote(
        workspaceId: String,
        sourceQuoteId: String,
        targetHouseholdId: String,
        targetPropertyId: String?,
        targetRequestId: String?
    ) async throws -> HavenFieldQuoteDuplicatePayload {
        struct Request: Encodable {
            let action = "duplicate_quote"
            let workspaceId: String
            let sourceQuoteId: String
            let targetHouseholdId: String
            let targetPropertyId: String?
            let targetRequestId: String?
        }
        let payload = Request(
            workspaceId: workspaceId,
            sourceQuoteId: sourceQuoteId,
            targetHouseholdId: targetHouseholdId,
            targetPropertyId: targetPropertyId,
            targetRequestId: targetRequestId
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldQuoteDuplicateResult.self
        )
        return response.duplicate
    }

    // MARK: - Wave M11 end-of-day summary

    /// Wave M11 — fetch today's stops + clock totals + materials + invoiced
    /// revenue + tomorrow preview for the End of Day surface. workspaceId
    /// is optional — when omitted, the server resolves the caller's first
    /// active workspace (matches the iOS sole-mode default). Always returns
    /// a HavenFieldDaySummary; resilient decoders mean a partial server
    /// shape still hydrates the visible parts.
    func todaySummary(workspaceId: String?) async throws -> HavenFieldDaySummary {
        struct Request: Encodable {
            let action = "today_summary"
            let workspaceId: String?
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId))
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldDaySummary.self
        )
    }

    // MARK: - Wave M8 end-of-visit suggestion authoring

    /// Wave M8 — propose a follow-up task for the homeowner's task list.
    /// Lands as a `maintenance_tasks` row with `source = 'contractor_suggestion'`
    /// + a thread audit message tagged `metadata.kind = 'task_suggested'`.
    /// Optional `dueDate` is a "yyyy-MM-dd" string (no enforced format on
    /// the server beyond what `next_due_date` accepts).
    func suggestFollowupTask(
        workspaceId: String,
        requestId: String,
        title: String,
        description: String?,
        dueDate: String?
    ) async throws -> String {
        struct Request: Encodable {
            let action = "suggest_followup_task"
            let workspaceId: String
            let requestId: String
            let title: String
            let description: String?
            let dueDate: String?
        }
        struct Response: Decodable {
            let ok: Bool?
            let taskId: String?
        }
        let payload = Request(
            workspaceId: workspaceId,
            requestId: requestId,
            title: title,
            description: description,
            dueDate: dueDate
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.taskId ?? ""
    }

    /// Wave M8 — pre-create a draft `provider_quotes` row that the M4
    /// quote builder picks up (we open `FieldBuildQuoteSheet` after the
    /// draft lands so the tech can finish the line items + customer
    /// signature). Returns the new quote id so the parent view can
    /// route the M4 sheet at the right row.
    func suggestFollowupQuote(
        workspaceId: String,
        requestId: String,
        title: String,
        scopeNotes: String?
    ) async throws -> String {
        struct Request: Encodable {
            let action = "suggest_followup_quote"
            let workspaceId: String
            let requestId: String
            let title: String
            let scopeNotes: String?
        }
        struct Response: Decodable {
            let ok: Bool?
            let quoteId: String?
            let title: String?
        }
        let payload = Request(
            workspaceId: workspaceId,
            requestId: requestId,
            title: title,
            scopeNotes: scopeNotes
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.quoteId ?? ""
    }

    /// Wave M8 — schedule a brand-new follow-up visit on the same
    /// vendor relationship. Server creates the `handyman_requests` row
    /// + pre-stamps a `provider_visit_assignments` slot for the same
    /// member who suggested the follow-up. `proposedDate` is the
    /// requested arrival time as an ISO-8601 string.
    func scheduleFollowupVisit(
        workspaceId: String,
        requestId: String,
        proposedDate: Date,
        durationMinutes: Int,
        title: String?,
        details: String?
    ) async throws -> String {
        struct Request: Encodable {
            let action = "schedule_followup_visit"
            let workspaceId: String
            let requestId: String
            let proposedDate: String
            let durationMinutes: Int
            let title: String?
            let details: String?
        }
        struct Response: Decodable {
            let ok: Bool?
            let requestId: String?
            let title: String?
            let assignmentId: String?
        }
        let isoFormatter = ISO8601DateFormatter()
        let payload = Request(
            workspaceId: workspaceId,
            requestId: requestId,
            proposedDate: isoFormatter.string(from: proposedDate),
            durationMinutes: durationMinutes,
            title: title,
            details: details
        )
        let data = try JSONEncoder().encode(payload)
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.requestId ?? ""
    }

    // MARK: - Wave M6 internal tech notes

    /// Wave M6 — append an internal note to this visit. Tech notes are
    /// workspace-only. Returns the inserted note (with author name baked
    /// in so the row renders without a follow-up fetch).
    func addTechNote(workspaceId: String, requestId: String, body: String) async throws -> HavenFieldTechNote {
        struct Request: Encodable {
            let action = "add_tech_note"
            let workspaceId: String
            let requestId: String
            let body: String
        }
        struct Response: Decodable {
            let note: HavenFieldTechNote
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw URLError(.badURL)
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            body: trimmed
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.note
    }

    /// Wave M6 — list all tech notes for a visit, sorted by created_at
    /// ascending (oldest first; matches the chat-style render). Author
    /// names join from `provider_workspace_members.full_name`.
    func listTechNotes(workspaceId: String, requestId: String) async throws -> [HavenFieldTechNote] {
        struct Request: Encodable {
            let action = "list_tech_notes"
            let workspaceId: String
            let requestId: String
        }
        struct Response: Decodable {
            let notes: [HavenFieldTechNote]
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId, requestId: requestId))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: Response.self)
        return response.notes
    }

    // MARK: - Wave M7 crew chat

    /// Wave M7 — list every thread visible to the caller in the workspace,
    /// each with the most recent message preview + unread count. Threads
    /// are returned newest-created first; the iOS view re-sorts by last
    /// message activity so the most recently active thread floats up.
    func listCrewChatThreads(workspaceId: String) async throws -> [HavenFieldCrewChatThread] {
        struct Request: Encodable {
            let action = "list_threads"
            let workspaceId: String
        }
        struct Response: Decodable {
            let threads: [HavenFieldCrewChatThread]
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId))
        let response = try await perform(
            function: "crew-chat",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.threads
    }

    /// Wave M7 — send a single crew chat message. Sender member id is
    /// stamped server-side from the auth JWT; we never trust the client
    /// to claim a different sender.
    func sendCrewChatMessage(
        workspaceId: String,
        threadId: String,
        body: String,
        attachments: [String] = []
    ) async throws -> HavenFieldCrewChatMessage {
        struct Request: Encodable {
            let action = "send"
            let workspaceId: String
            let threadId: String
            let body: String
            let attachments: [String]
        }
        struct Response: Decodable {
            let message: HavenFieldCrewChatMessage
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw URLError(.badURL) }
        let data = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                threadId: threadId,
                body: trimmed,
                attachments: attachments
            )
        )
        let response = try await perform(
            function: "crew-chat",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.message
    }

    /// Wave M7 — append the caller's `member_id` to `read_by` on every
    /// message in the thread. Idempotent — calling twice is a no-op.
    func markCrewChatThreadRead(workspaceId: String, threadId: String) async throws {
        struct Request: Encodable {
            let action = "mark_read"
            let workspaceId: String
            let threadId: String
        }
        let data = try JSONEncoder().encode(Request(workspaceId: workspaceId, threadId: threadId))
        try await perform(function: "crew-chat", method: "POST", body: data)
    }

    /// Wave M7 — create a new crew chat thread. `kind` is one of
    /// `general` / `route_day` / `tech_pair`. memberIds is accepted by
    /// the edge function but not yet persisted to a participants table —
    /// every active workspace member sees every thread by RLS policy.
    func createCrewChatThread(
        workspaceId: String,
        name: String?,
        kind: String,
        memberIds: [String]
    ) async throws -> HavenFieldCrewChatThread {
        struct Request: Encodable {
            let action = "create_thread"
            let workspaceId: String
            let name: String?
            let kind: String
            let memberIds: [String]
        }
        struct Response: Decodable {
            let thread: HavenFieldCrewChatThread
        }
        let normalizedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = try JSONEncoder().encode(
            Request(
                workspaceId: workspaceId,
                name: (normalizedName?.isEmpty ?? true) ? nil : normalizedName,
                kind: kind,
                memberIds: memberIds
            )
        )
        let response = try await perform(
            function: "crew-chat",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        return response.thread
    }

    /// Wave M7 — fetch raw `crew_chat_messages` rows for a thread via
    /// PostgREST. The list_threads action returns only the last preview
    /// per thread; the Crew tab thread view renders the full history.
    /// RLS on `crew_chat_messages` gates by workspace via
    /// `get_my_provider_workspace_ids()`, so the caller's session JWT is
    /// the only auth boundary needed here.
    func fetchCrewChatMessages(
        workspaceId: String,
        threadId: String
    ) async throws -> [HavenFieldCrewChatMessage] {
        // We can't compute author names from a single PostgREST query
        // without `select=...,sender:provider_workspace_members(*)` and
        // even then names get nested deep. Instead, fetch the message
        // rows + the workspace's members in two parallel calls and join
        // in memory. The roster is small (≤ 25 members per workspace
        // per the largest fixture), so this is cheap.
        async let messagesTask = fetchCrewChatMessageRows(threadId: threadId, workspaceId: workspaceId)
        async let rosterTask = fetchWorkspaceMemberDirectory(workspaceId: workspaceId)
        let messages = try await messagesTask
        let roster = try await rosterTask

        let nameById = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0.displayName) })
        return messages.map { row in
            let displayName = nameById[row.senderMemberId] ?? row.senderName
            return HavenFieldCrewChatMessage(
                id: row.id,
                threadId: row.threadId,
                workspaceId: row.workspaceId ?? workspaceId,
                senderMemberId: row.senderMemberId,
                senderName: displayName,
                body: row.body,
                attachments: row.attachments,
                readBy: row.readBy,
                createdAt: row.createdAt
            )
        }
    }

    /// Internal helper for `fetchCrewChatMessages`. PostgREST GET
    /// against the `crew_chat_messages` table directly; member-name
    /// join is done after the fact in `fetchCrewChatMessages`.
    private func fetchCrewChatMessageRows(
        threadId: String,
        workspaceId: String
    ) async throws -> [HavenFieldCrewChatMessage] {
        struct Row: Decodable {
            let id: String
            let thread_id: String
            let workspace_id: String?
            let sender_member_id: String
            let body: String
            let attachments: [String]?
            let read_by: [String]?
            let created_at: String?
        }
        var components = URLComponents(string: "\(AppConfig.Supabase.url)/rest/v1/crew_chat_messages")
        components?.queryItems = [
            URLQueryItem(name: "thread_id", value: "eq.\(threadId)"),
            URLQueryItem(name: "workspace_id", value: "eq.\(workspaceId)"),
            URLQueryItem(name: "select", value: "id,thread_id,workspace_id,sender_member_id,body,attachments,read_by,created_at"),
            URLQueryItem(name: "order", value: "created_at.asc"),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Wave M7 — PostgREST requires `apikey: <anon key>` without a
        // "Bearer " prefix (in contrast to Edge Functions, which are
        // lenient about it). See `fetchWorkspaceMemberDirectory` for
        // the full diagnosis.
        request.setValue(AppConfig.Supabase.anonKey, forHTTPHeaderField: "apikey")
        if let accessToken = await HavenSupabase.safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.map { row in
            HavenFieldCrewChatMessage(
                id: row.id,
                threadId: row.thread_id,
                workspaceId: row.workspace_id,
                senderMemberId: row.sender_member_id,
                senderName: "Workspace member",
                body: row.body,
                attachments: row.attachments ?? [],
                readBy: row.read_by ?? [],
                createdAt: row.created_at
            )
        }
    }

    /// Wave M7 helper — pull every active workspace member for the new
    /// thread sheet (member chip picker) and the message-render name
    /// join. Defensive shape (no member shows up as empty string) so a
    /// row that's missing full_name + email still renders something.
    func fetchWorkspaceMemberDirectory(
        workspaceId: String
    ) async throws -> [HavenFieldCrewChatMember] {
        struct Row: Decodable {
            let id: String
            let workspace_id: String?
            let role: String?
            let full_name: String?
            let email: String?
            let status: String?
        }
        var components = URLComponents(string: "\(AppConfig.Supabase.url)/rest/v1/provider_workspace_members")
        components?.queryItems = [
            URLQueryItem(name: "workspace_id", value: "eq.\(workspaceId)"),
            URLQueryItem(name: "select", value: "id,workspace_id,role,full_name,email,status"),
            URLQueryItem(name: "order", value: "full_name.asc"),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Wave M7 — PostgREST is stricter than Edge Functions about the
        // `apikey` header: it expects the raw anon key WITHOUT a "Bearer "
        // prefix. The legacy `fetchOpenPause` helper used the Bearer
        // form and only worked by accident (its RLS policy lets the
        // anon role read open-pause rows). Use the bare key form here
        // because `provider_workspace_members`'s RLS hard-requires a
        // user JWT.
        request.setValue(AppConfig.Supabase.anonKey, forHTTPHeaderField: "apikey")
        if let accessToken = await HavenSupabase.safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.map { row in
            HavenFieldCrewChatMember(
                id: row.id,
                role: row.role ?? "technician",
                fullName: row.full_name?.trimmingCharacters(in: .whitespacesAndNewlines),
                email: row.email,
                status: row.status ?? "active"
            )
        }
    }

    /// Wave M1 — read the open pause window for this assignment, if any.
    /// Used by HavenFieldVisitWorkspaceView's onAppear hydration so a
    /// background → foreground cycle resumes into the right state. Hits
    /// the PostgREST endpoint directly (RLS scoped via session JWT).
    func fetchOpenPause(assignmentId: String) async throws -> [HavenFieldOpenPause] {
        var components = URLComponents(string: "\(AppConfig.Supabase.url)/rest/v1/provider_visit_pauses")
        components?.queryItems = [
            URLQueryItem(name: "assignment_id", value: "eq.\(assignmentId)"),
            URLQueryItem(name: "resumed_at", value: "is.null"),
            URLQueryItem(name: "select", value: "id,paused_at,resumed_at,reason"),
            URLQueryItem(name: "order", value: "paused_at.desc"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "apikey")
        if let accessToken = await HavenSupabase.safeAccessToken(timeout: 3.0) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfig.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode([HavenFieldOpenPause].self, from: data)
    }

    // MARK: - Wave M3 system inventory authoring

    /// Wave M3 — response shape every system-write action returns. iOS
    /// UI re-renders the affected row by replacing its model entry with
    /// the freshly-decoded value the server sends back.
    struct HavenFieldSystemUpdateResponse: Decodable {
        let ok: Bool?
        let system: HavenFieldHomeSystem?
    }

    /// Wave M3 — response shape attach_system_voice + delete_system_voice
    /// return. The signed URL lets the iOS UI play back the just-uploaded
    /// memo without a second round-trip.
    struct HavenFieldSystemVoiceResponse: Decodable {
        let ok: Bool?
        let voicePath: String?
        let signedUrl: String?
        let mimeType: String?
    }

    /// T3.7 (post-overnight) — lookup-manual response shape. Matches
    /// the catalog edge function at supabase/functions/lookup-manual/
    /// index.ts. `manualUrl` is a signed URL to a cached PDF when we
    /// have one; otherwise `supportUrl` is the manufacturer's portal
    /// deep-link the user can open in Safari to find the manual on
    /// the mfr's site.
    struct HavenFieldManualLookupResponse: Decodable {
        let found: Bool?
        let manualUrl: String?
        let supportUrl: String?
        let supportPhone: String?
        let manufacturer: String?
        let modelName: String?
        let modelNumber: String?
        let suggestion: String?

        private enum CodingKeys: String, CodingKey {
            case found
            case manualUrl = "manual_url"
            case supportUrl = "support_url"
            case supportPhone = "support_phone"
            case manufacturer
            case modelName = "model_name"
            case modelNumber = "model_number"
            case suggestion
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            found = (try? c.decodeIfPresent(Bool.self, forKey: .found)) ?? nil
            manualUrl = (try? c.decodeIfPresent(String.self, forKey: .manualUrl)) ?? nil
            supportUrl = (try? c.decodeIfPresent(String.self, forKey: .supportUrl)) ?? nil
            supportPhone = (try? c.decodeIfPresent(String.self, forKey: .supportPhone)) ?? nil
            manufacturer = (try? c.decodeIfPresent(String.self, forKey: .manufacturer)) ?? nil
            modelName = (try? c.decodeIfPresent(String.self, forKey: .modelName)) ?? nil
            modelNumber = (try? c.decodeIfPresent(String.self, forKey: .modelNumber)) ?? nil
            suggestion = (try? c.decodeIfPresent(String.self, forKey: .suggestion)) ?? nil
        }
    }

    /// Wave M3 — response shape extract_system_from_photo returns.
    /// Mirrors the identify-equipment edge function's structured Claude
    /// Vision JSON. Fields are nullable because the AI returns null when
    /// the plate is too blurry to read.
    struct HavenFieldExtractSystemResponse: Decodable {
        let ok: Bool?
        let identified: Bool?
        let manufacturer: String?
        let modelNumber: String?
        let serialNumber: String?
        let productType: String?
        let additionalSpecs: String?
        let confidence: String?
        let rawText: String?
    }

    /// Wave M3 — flag a system for follow-up on the next visit.
    /// Optional reason (free-form note: "tenant unavailable", "panel
    /// locked"). Surfaces on the homeowner's dashboard if material.
    func markSystemFollowup(
        workspaceId: String,
        systemId: String,
        reason: String?
    ) async throws -> HavenFieldHomeSystem? {
        struct Request: Encodable {
            let action = "mark_system_followup"
            let workspaceId: String
            let systemId: String
            let reason: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId,
            reason: reason
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemUpdateResponse.self
        )
        return response.system
    }

    /// Wave M3 — clear the follow-up flag (tech finished the work, or
    /// explicitly drops it off the next-visit prep list).
    func clearSystemFollowup(
        workspaceId: String,
        systemId: String
    ) async throws -> HavenFieldHomeSystem? {
        struct Request: Encodable {
            let action = "clear_system_followup"
            let workspaceId: String
            let systemId: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemUpdateResponse.self
        )
        return response.system
    }

    /// Wave M3 — mark a system as removed from the home (replaced,
    /// removed, damaged beyond repair). Server-side this also flips
    /// is_active=false + status='decommissioned' so the homeowner
    /// reconciler skips it on the next pass.
    func decommissionSystem(
        workspaceId: String,
        systemId: String,
        reason: String?
    ) async throws -> HavenFieldHomeSystem? {
        struct Request: Encodable {
            let action = "decommission_system"
            let workspaceId: String
            let systemId: String
            let reason: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId,
            reason: reason
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemUpdateResponse.self
        )
        return response.system
    }

    /// T2.5 (post-overnight) — capture a homeowner's existing vendor
    /// on the home detail Vendors sub-tab. Wraps the existing
    /// `create_contractor_from_card` action which inserts a contractor
    /// row scoped to the customer's household_id with source='chez_field'.
    ///
    /// Phone is required server-side. Caller passes the canonical
    /// SystemCategoryRegistry category string for the trade so the
    /// homeowner-side vendor coverage matcher picks it up cleanly.
    /// (See CLAUDE.md "Vendor coverage matches on canonical categories,
    /// never exact strings" hard rule.)
    func createVendorForHome(
        workspaceId: String,
        householdId: String,
        companyName: String,
        phone: String,
        contactName: String?,
        email: String?,
        website: String?,
        tradeCategory: String?,
        notes: String?
    ) async throws -> HavenFieldHomeVendor? {
        struct Request: Encodable {
            let action = "create_contractor_from_card"
            let workspaceId: String
            let householdId: String
            let companyName: String
            let phone: String
            let contactName: String?
            let email: String?
            let website: String?
            let tradeCategory: String?
            let notes: String?
        }
        struct Response: Decodable {
            let ok: Bool?
            let contractor: HavenFieldRawContractor?
        }
        struct HavenFieldRawContractor: Decodable {
            let id: String?
            let household_id: String?
            let company_name: String?
            let contact_name: String?
            let phone: String?
            let email: String?
            let website: String?
            let specialties: [String]?
            let source: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            householdId: householdId,
            companyName: companyName,
            phone: phone,
            contactName: contactName,
            email: email,
            website: website,
            tradeCategory: tradeCategory,
            notes: notes
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        guard let raw = response.contractor, let id = raw.id else { return nil }
        // Synthesize a HavenFieldHomeVendor from the raw row so the
        // calling sheet can prepend it to the home's vendor list
        // without waiting for a dashboard refresh round-trip.
        let json: [String: Any] = [
            "id": id,
            "companyName": raw.company_name ?? companyName,
            "contactName": raw.contact_name ?? (contactName ?? ""),
            "phone": raw.phone ?? phone,
            "email": raw.email ?? (email ?? ""),
            "website": raw.website ?? (website ?? ""),
            "category": (raw.specialties?.first ?? tradeCategory) ?? "",
            "source": raw.source ?? "chez_field",
            "logoUrl": "",
            "brandColor": "",
            "chezOwned": false,
        ]
        let bytes = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        return try? JSONDecoder().decode(HavenFieldHomeVendor.self, from: bytes)
    }

    /// T3.7 (post-overnight) — look up a system's manual / spec sheet
    /// on demand. The `lookup-manual` Edge Function takes a
    /// home_system_id and returns the cached PDF (signed URL) when
    /// available, or the manufacturer's support portal URL as a
    /// fallback. Pre-T3.7 the iOS field app surfaced ONLY the
    /// pre-cached links on the system row — no on-demand lookup
    /// affordance for systems without a cached link yet. Now the
    /// system detail sheet exposes a "Pull up manual" button when the
    /// system has a modelNumber.
    ///
    /// Note: lookup-manual is a generic catalog endpoint and doesn't
    /// require workspace auth. Routes through the standard
    /// callEdgeFunction layer (anon JWT is fine since the data is
    /// public catalog content).
    func lookupManual(homeSystemId: String) async throws -> HavenFieldManualLookupResponse {
        struct Request: Encodable {
            let home_system_id: String
        }
        let data = try JSONEncoder().encode(Request(home_system_id: homeSystemId))
        return try await perform(
            function: "lookup-manual",
            method: "POST",
            body: data,
            expecting: HavenFieldManualLookupResponse.self
        )
    }

    /// T1.2 (post-overnight) — fill in missing brand / model / serial /
    /// install date / notes on an existing home_systems row. Uses the
    /// `update_home_system` action. The server-side handler PATCHES by
    /// id (A4 edit-no-duplicate guard); only fields explicitly sent are
    /// touched. Sending an empty string clears a field; omitting a key
    /// leaves it untouched.
    ///
    /// Wave 2a / 3b found that existing-system rows are read-only on
    /// iOS, which made the only path "Add new" → duplicate row. With
    /// this method wired, the system detail sheet can finally close the
    /// loop: handyman taps Edit → fills in missing fields → save PATCHES
    /// the row in place.
    func updateHomeSystem(
        workspaceId: String,
        systemId: String,
        name: String? = nil,
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        installDate: String? = nil,
        notes: String? = nil
    ) async throws -> HavenFieldHomeSystem? {
        struct Request: Encodable {
            let action = "update_home_system"
            let workspaceId: String
            let systemId: String
            let name: String?
            let manufacturer: String?
            let modelNumber: String?
            let serialNumber: String?
            let installDate: String?
            let notes: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId,
            name: name,
            manufacturer: manufacturer,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            installDate: installDate,
            notes: notes
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemUpdateResponse.self
        )
        return response.system
    }

    /// Wave M3 — record a voice memo against a system. AVAudioRecorder
    /// writes m4a; the view reads bytes, base64-encodes, posts. Single
    /// voice note per system — re-recording overwrites the previous
    /// file. Returns a fresh signed URL so playback works inline.
    func attachSystemVoice(
        workspaceId: String,
        systemId: String,
        base64: String,
        mimeType: String
    ) async throws -> HavenFieldSystemVoiceResponse {
        struct Request: Encodable {
            let action = "attach_system_voice"
            let workspaceId: String
            let systemId: String
            let base64: String
            let mimeType: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId,
            base64: base64,
            mimeType: mimeType
        ))
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemVoiceResponse.self
        )
    }

    /// Wave M3 — delete the recorded voice memo for a system.
    func deleteSystemVoice(
        workspaceId: String,
        systemId: String
    ) async throws {
        struct Request: Encodable {
            let action = "delete_system_voice"
            let workspaceId: String
            let systemId: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            systemId: systemId
        ))
        try await perform(function: "handyman-provider", method: "POST", body: data)
    }

    /// Wave M3 — fetch a fresh signed URL for an existing voice memo.
    /// The path is stored on home_systems.voice_note_path; signed URLs
    /// from the upload response expire after an hour.
    func signSystemVoiceUrl(path: String) async throws -> URL? {
        struct Request: Encodable {
            let action = "sign_system_voice_url"
            let path: String
        }
        struct Response: Decodable { let signedUrl: String? }
        let data = try JSONEncoder().encode(Request(path: path))
        let response = try? await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: Response.self
        )
        guard let urlString = response?.signedUrl else { return nil }
        return URL(string: urlString)
    }

    /// Wave M3 — forward a model-plate photo to identify-equipment via
    /// the workspace-authed wrapper. Returns the structured AI shape the
    /// confirmation card renders before the tech saves it as a system.
    func extractSystemFromPhoto(
        workspaceId: String,
        base64: String,
        category: String?
    ) async throws -> HavenFieldExtractSystemResponse {
        struct Request: Encodable {
            let action = "extract_system_from_photo"
            let workspaceId: String
            let base64: String
            let category: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            base64: base64,
            category: category
        ))
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldExtractSystemResponse.self
        )
    }

    /// Wave M3 — insert a freshly-extracted system into home_systems via
    /// the workspace-authed `create_home_system` action. RLS on
    /// home_systems blocks INSERTs from workspace-member sessions; the
    /// edge function bypasses RLS via the service-role key after
    /// validating the workspace serves this property.
    func createHomeSystem(
        workspaceId: String,
        propertyId: String,
        householdId: String,
        name: String,
        category: String?,
        manufacturer: String?,
        modelNumber: String?,
        serialNumber: String?,
        notes: String?
    ) async throws -> HavenFieldHomeSystem? {
        struct Request: Encodable {
            let action = "create_home_system"
            let workspaceId: String
            let propertyId: String
            let householdId: String
            let name: String
            let category: String?
            let manufacturer: String?
            let modelNumber: String?
            let serialNumber: String?
            let notes: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            propertyId: propertyId,
            householdId: householdId,
            name: name,
            category: category,
            manufacturer: manufacturer,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            notes: notes
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldSystemUpdateResponse.self
        )
        return response.system
    }

    // MARK: - Wave M2 punch capture depth

    /// Wave M2 — partial response shape the four capture-depth actions
    /// return. Field UI updates the per-item state on success; the
    /// signed URLs let the iOS app render thumbnails / playback inline
    /// without a separate fetch round-trip.
    struct PunchCaptureUpdate: Decodable {
        struct Item: Decodable {
            let id: String
            let attachments: [HavenFieldPunchAttachment]
            let materialsUsed: [HavenFieldPunchMaterial]
            let timeSpentSeconds: Int
            let voiceNotePath: String?
            let voiceNoteSignedUrl: String?

            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
                attachments = (try? c.decodeIfPresent([HavenFieldPunchAttachment].self, forKey: .attachments)) ?? []
                materialsUsed = (try? c.decodeIfPresent([HavenFieldPunchMaterial].self, forKey: .materialsUsed)) ?? []
                timeSpentSeconds = (try? c.decodeIfPresent(Int.self, forKey: .timeSpentSeconds)) ?? 0
                voiceNotePath = (try? c.decodeIfPresent(String.self, forKey: .voiceNotePath)) ?? nil
                voiceNoteSignedUrl = (try? c.decodeIfPresent(String.self, forKey: .voiceNoteSignedUrl)) ?? nil
            }

            private enum CodingKeys: String, CodingKey {
                case id, attachments, materialsUsed, timeSpentSeconds, voiceNotePath, voiceNoteSignedUrl
            }
        }
        let item: Item
    }

    /// Wave M2 — attach a photo to a punch item. The view layer captures
    /// a UIImage via PhotosPicker, downsizes (1600px max edge) +
    /// JPEG-encodes (compression 0.82), and base64-encodes the bytes.
    /// Server returns the freshly-signed thumbnail URL inline so we can
    /// render the new tile without a follow-up fetch.
    func attachPunchPhoto(
        workspaceId: String,
        itemId: String,
        base64: String,
        contentType: String,
        caption: String?
    ) async throws -> PunchCaptureUpdate.Item {
        struct Request: Encodable {
            let action = "attach_punch_photo"
            let workspaceId: String
            let itemId: String
            let base64: String
            let contentType: String
            let caption: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            itemId: itemId,
            base64: base64,
            contentType: contentType,
            caption: caption
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: PunchCaptureUpdate.self)
        return response.item
    }

    /// Wave M2 — attach a voice note. AVAudioRecorder writes m4a/aac to
    /// a temp URL; the view reads bytes, base64-encodes, posts. Single
    /// voice note per item — re-recording overwrites the previous file
    /// in storage server-side.
    func attachPunchVoice(
        workspaceId: String,
        itemId: String,
        base64: String,
        mimeType: String
    ) async throws -> PunchCaptureUpdate.Item {
        struct Request: Encodable {
            let action = "attach_punch_voice"
            let workspaceId: String
            let itemId: String
            let base64: String
            let mimeType: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            itemId: itemId,
            base64: base64,
            mimeType: mimeType
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: PunchCaptureUpdate.self)
        return response.item
    }

    /// Wave M2 — replace the materials_used array on a punch item.
    /// The server validates each row (name non-empty, qty/unit_cost
    /// non-negative) and returns the round-tripped list so the iOS UI
    /// can render the canonical shape (e.g. server-side rounding).
    func setPunchMaterials(
        workspaceId: String,
        itemId: String,
        materials: [HavenFieldPunchMaterial]
    ) async throws -> PunchCaptureUpdate.Item {
        struct Request: Encodable {
            let action = "set_punch_materials"
            let workspaceId: String
            let itemId: String
            let materials: [HavenFieldPunchMaterial]
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            itemId: itemId,
            materials: materials
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: PunchCaptureUpdate.self)
        return response.item
    }

    /// Wave M2 — set the per-item elapsed-time counter. The view runs
    /// the timer in-memory; this writes the final value when the tech
    /// stops. Negative values are clamped to 0 server-side.
    func setPunchTimeSpent(
        workspaceId: String,
        itemId: String,
        seconds: Int
    ) async throws -> PunchCaptureUpdate.Item {
        struct Request: Encodable {
            let action = "set_punch_time_spent"
            let workspaceId: String
            let itemId: String
            let seconds: Int
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            itemId: itemId,
            seconds: seconds
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: PunchCaptureUpdate.self)
        return response.item
    }

    // MARK: - Wave M12 Need part flow

    /// Wave M12 — submit a part request. Either `requestId` or `punchItemId`
    /// is required (or both). When urgency is "blocking_now", server-side
    /// fires a push to every active owner/admin/dispatcher in the workspace.
    func createPartRequest(
        workspaceId: String,
        requestId: String?,
        punchItemId: String?,
        description: String,
        urgency: String,
        photos: [HavenFieldPunchAttachment]
    ) async throws -> HavenFieldPartRequest {
        struct PhotoBody: Encodable {
            let kind: String
            let path: String
            let contentType: String?
            let caption: String?
        }
        struct Request: Encodable {
            let action = "create_part_request"
            let workspaceId: String
            let requestId: String?
            let punchItemId: String?
            let description: String
            let urgency: String
            let photos: [PhotoBody]
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            requestId: requestId,
            punchItemId: punchItemId,
            description: description,
            urgency: urgency,
            photos: photos.map { PhotoBody(kind: $0.kind, path: $0.path, contentType: $0.contentType, caption: $0.caption) }
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldPartRequestSingle.self)
        return response.partRequest
    }

    /// Wave M12 — update part request status + optional supplier metadata.
    /// Status transitions: open → ordered → in_truck → fulfilled (or
    /// open → cancelled). When status flips to fulfilled, server stamps
    /// fulfilled_at = now().
    func updatePartStatus(
        workspaceId: String,
        partRequestId: String,
        status: String,
        supplier: String?,
        supplierEta: String?
    ) async throws -> HavenFieldPartRequest {
        struct Request: Encodable {
            let action = "update_part_status"
            let workspaceId: String
            let partRequestId: String
            let status: String
            let supplier: String?
            let supplierEta: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            partRequestId: partRequestId,
            status: status,
            supplier: supplier,
            supplierEta: supplierEta
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldPartRequestSingle.self)
        return response.partRequest
    }

    /// Wave M12 — list part requests for a workspace. Defaults to the
    /// open queue (status='open'); pass status="all" to fetch everything.
    /// Drives the Today-screen pill + the FieldPartRequestsListView surface.
    func listOpenPartRequests(
        workspaceId: String,
        statusFilter: String = "open"
    ) async throws -> HavenFieldPartRequestList {
        struct Request: Encodable {
            let action = "list_open_part_requests"
            let workspaceId: String
            let status: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            status: statusFilter
        ))
        return try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldPartRequestList.self)
    }

    /// Wave M12 — upload a photo to the part-requests bucket prefix.
    /// Returns `{ kind, path, signedUrl }` so the iOS sheet can render
    /// the thumbnail before the request row is created. The path is
    /// then passed in `photos` to `create_part_request`.
    func attachPartRequestPhoto(
        workspaceId: String,
        base64: String,
        contentType: String,
        caption: String?
    ) async throws -> HavenFieldPunchAttachment {
        struct Request: Encodable {
            let action = "attach_part_request_photo"
            let workspaceId: String
            let base64: String
            let contentType: String
            let caption: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            base64: base64,
            contentType: contentType,
            caption: caption
        ))
        let response = try await perform(function: "handyman-provider", method: "POST", body: data, expecting: HavenFieldPartRequestPhotoUpload.self)
        return response.photo
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

    // MARK: - Wave M10 — Closest customer to me + business card AI

    /// Wave M10 — fetch the workspace's customers sorted by distance
    /// from the tech's current location. The server geocodes property
    /// addresses via Nominatim (1/sec rate limit), so this call can
    /// take up to ~12 seconds for a workspace with 10 customers — show
    /// a skeleton while it's in flight.
    func nearestCustomers(
        workspaceId: String,
        latitude: Double,
        longitude: Double,
        limit: Int
    ) async throws -> HavenFieldNearbyCustomersPayload {
        struct Request: Encodable {
            let action = "nearest_customers"
            let workspaceId: String
            let latitude: Double
            let longitude: Double
            let limit: Int
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            latitude: latitude,
            longitude: longitude,
            limit: limit
        ))
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldNearbyCustomersPayload.self
        )
    }

    /// Wave M10 — extract structured business-card data via Claude
    /// Vision. Returns nullable fields the iOS confirmation card can
    /// edit before saving. Bytes arrive as base64 (UIImage → JPEG →
    /// base64); the iOS caller is responsible for downsizing to a
    /// sane width before sending.
    func extractBusinessCard(
        workspaceId: String,
        imageBase64: String
    ) async throws -> HavenFieldBusinessCardExtraction {
        struct Request: Encodable {
            let action = "extract_business_card"
            let workspaceId: String
            let imageBase64: String
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            imageBase64: imageBase64
        ))
        return try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldBusinessCardExtraction.self
        )
    }

    /// Wave M10 — insert a `contractors` row from a business-card
    /// capture. Workspace members can't INSERT directly into
    /// `contractors` (RLS gate); the edge function bypasses RLS via
    /// service-role after validating the workspace serves the target
    /// household.
    func createContractorFromCard(
        workspaceId: String,
        householdId: String,
        companyName: String,
        contactName: String?,
        phone: String,
        email: String?,
        website: String?,
        tradeCategory: String?,
        notes: String?
    ) async throws -> HavenFieldCreatedContractor? {
        struct Request: Encodable {
            let action = "create_contractor_from_card"
            let workspaceId: String
            let householdId: String
            let companyName: String
            let contactName: String?
            let phone: String
            let email: String?
            let website: String?
            let tradeCategory: String?
            let notes: String?
        }
        let data = try JSONEncoder().encode(Request(
            workspaceId: workspaceId,
            householdId: householdId,
            companyName: companyName,
            contactName: contactName,
            phone: phone,
            email: email,
            website: website,
            tradeCategory: tradeCategory,
            notes: notes
        ))
        let response = try await perform(
            function: "handyman-provider",
            method: "POST",
            body: data,
            expecting: HavenFieldCreatedContractorPayload.self
        )
        return response.contractor
    }
}

@MainActor
final class HavenFieldViewModel: ObservableObject {
    enum RootTab: Hashable {
        case home
        case visits
        case crew
        case clients
        case messages
    }

    @Published var dashboard: HavenFieldDashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab: RootTab = .home
    @Published var visitsFilter: HavenFieldVisitsFilter = .upcoming
    @Published var messageFilter: HavenFieldMessageFilter = .all
    /// Set true while a child surface (e.g. message thread) needs the
    /// floating safe-area-inset tab bar OUT of the way so its own bottom
    /// composer becomes visible. Wave 1b's `.toolbar(.hidden, for:.tabBar)`
    /// only hid SwiftUI's default tab bar; the field app's custom bar is
    /// added via `.safeAreaInset` and ignores per-screen toolbar modifiers.
    /// Set on `.onAppear`, cleared on `.onDisappear` of the consuming view.
    @Published var bottomTabBarHidden = false

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
    // Sprint #4 R4-E-3 fix: refresh dashboard on background → active so
    // the user doesn't have to cold-launch to see new visits, replies,
    // task date changes, etc. The existing pull-to-refresh + .task on
    // first appear handle the rest of the cases.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // D7 fix: SwiftUI's `.toolbar(.hidden, for: .tabBar)` modifier
        // on iOS 26 occasionally leaves a faint ghost of the native
        // tab bar behind the custom HavenFieldTabBar pill on certain
        // first-render paths (sweep mode, modal dismiss). UIKit
        // appearance configuration zeroes the bar's frame which makes
        // the ghost go away regardless of SwiftUI's render order. Safe
        // here because every Chez Field surface uses the custom pill.
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isHidden = true
    }

    /// Sprint #3 R3-E-4: solo workspaces (single active member) hide
    /// the Crew tab entirely — there's no one to chat with, and the
    /// pre-fix "Start a thread → New thread sheet has only you as a
    /// participant" flow let the user technically chat with themselves.
    /// Once a second member is invited and active the tab returns
    /// automatically.
    private var isSoloWorkspace: Bool {
        let activeCount = viewModel.dashboard?.workspace?.activeMemberCount ?? 1
        return activeCount <= 1
    }

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

            // Sprint #3 R3-E-4: gate the Crew tab on having ≥2 active
            // members. Solo workspaces never see this tab.
            if !isSoloWorkspace {
                NavigationStack {
                    // Wave M7 — intra-workspace messaging surface. Distinct
                    // from the Messages tab below (which is the
                    // customer-facing thread). Lives between Visits and
                    // Homes so route-day coordination chats sit next to
                    // the dispatch surface.
                    HavenFieldCrewTab(viewModel: viewModel)
                }
                .tabItem {
                    Label("Crew", systemImage: "person.2.wave.2.fill")
                }
                .tag(HavenFieldViewModel.RootTab.crew)
            }

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
            if !viewModel.bottomTabBarHidden {
                HavenFieldTabBar(
                    selectedTab: $viewModel.selectedTab,
                    showCrewTab: !isSoloWorkspace
                )
            }
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
        // T1.5 (post-overnight) — typed deep-link routing from APNs.
        // AppDelegate posts `.havenFieldSwitchTab` with userInfo["tab"]
        // set to one of "home" / "visits" / "crew" / "clients" / "messages".
        // We swap selectedTab and let downstream observers
        // (.havenFieldOpenVisit / .havenFieldOpenThread / .havenFieldOpenHome)
        // handle the entity-level deep link via the visit detail / thread
        // / home pickers' own onReceive handlers.
        .onReceive(NotificationCenter.default.publisher(for: .havenFieldSwitchTab)) { note in
            guard let tabKey = note.userInfo?["tab"] as? String else { return }
            switch tabKey {
            case "home":     viewModel.selectedTab = .home
            case "visits":   viewModel.selectedTab = .visits
            case "crew":
                if !isSoloWorkspace { viewModel.selectedTab = .crew }
            case "clients", "homes":
                viewModel.selectedTab = .clients
            case "messages":
                viewModel.selectedTab = .messages
            default:
                break
            }
        }
        // Sprint #3 R3-E-4: defensive — if the selected tab gets stuck
        // on .crew (e.g. user was on a 2-member workspace, the second
        // member left, and this dashboard refresh hides the Crew tab),
        // redirect to Overview so we don't render an orphaned selection.
        .onChange(of: viewModel.dashboard?.workspace?.activeMemberCount) { _, newValue in
            if (newValue ?? 1) <= 1 && viewModel.selectedTab == .crew {
                viewModel.selectedTab = .home
            }
        }
        // Sprint #4 R4-E-3 fix: refresh on background → active so
        // dispatcher reassignments, homeowner replies, status flips
        // from another tech, and concierge updates land without a
        // cold-launch cycle. Mirrors the pattern Apple's Mail and
        // Reminders apps use for foreground refresh.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.refresh() }
            }
        }
    }
}

private struct HavenFieldHomeTab: View {
    @ObservedObject var viewModel: HavenFieldViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    /// Wave M11 — End of Day sheet. Surfaced once the last today-stop's
    /// status flips to `completed` (no more visits in the upcoming queue
    /// and at least one with a completed-today status). Operator-controlled
    /// — they tap the CTA when ready to sign off; we don't auto-present.
    @State private var showEndOfDay = false

    /// Wave M12 — count of open part requests for this workspace. Drives
    /// the salmon pill that surfaces below the route summary card.
    /// Loaded on `.task` and refreshed on `.havenFieldPartRequestChanged`.
    @State private var openPartRequestCount: Int = 0
    @State private var showPartRequestsList = false

    private var requestedVisits: [HavenFieldVisit] {
        (viewModel.dashboard?.visits ?? [])
            .filter(\.belongsInRequestQueue)
            .sorted(by: fieldVisitSort)
    }

    /// Wave M11 — today's COMPLETED stops. We can't reuse `todayVisits`
    /// because that's gated on `belongsInUpcomingQueue` (status NOT yet
    /// completed). The End-of-day signal is "did the user finish at least
    /// one stop today AND have nothing remaining". So we count completed
    /// status rows whose route_date or scheduledDate is today, AND we know
    /// there's nothing left in todayVisits (which excludes completed).
    private var todayCompletedCount: Int {
        guard let dashboard = viewModel.dashboard else { return 0 }
        let today = DateFormatter.havenISODate.string(from: Date())
        return dashboard.visits
            .filter { ($0.routeDate ?? $0.visit?.scheduledDate ?? "") == today }
            .filter { $0.status == HandymanRequestStatus.completed.rawValue }
            .count
    }

    /// Wave M11 — show the End of Day CTA when remaining today-stops is 0
    /// AND at least one stop was completed today. Field tech sees the
    /// "Wrap up the day" salmon pill below the route summary.
    private var canShowEndOfDayCTA: Bool {
        todayVisits.isEmpty && todayCompletedCount > 0
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

    /// Wave M6 — route summary stats for today's stops. Drive time is
    /// estimated (NOT from a real routing engine — see deferred note in
    /// the wave plan): 15 min between stops. The mileage is a coarse
    /// proxy at 6 miles per stop, sufficient for the field tech to
    /// gauge "is this a tight day or a loose one" without GIS calls.
    /// When 0 stops, returns nil so the card hides cleanly.
    private struct RouteSummary {
        let stops: Int
        let driveMinutes: Int
        let estimatedMiles: Int
    }

    private var todayRouteSummary: RouteSummary? {
        let stops = todayVisits.count
        guard stops > 0 else { return nil }
        // Bugfix Sprint #5 R7-E-3 — dedup by location before estimating
        // drive time + miles. Two visits at the same propertyId (or two
        // visits with no propertyId at all that share an address) are
        // ONE physical stop on the route. The previous code treated
        // every assignment as a separate leg, which produced "606 miles
        // / 25h drive time" for 100 visits at the same address.
        // Visits with no propertyId fall back to a synthesized key from
        // the property summary's address line so the dedup still works
        // for prospect / unhoused requests.
        var locationKeys = Set<String>()
        for visit in todayVisits {
            let key = visit.propertyId
                ?? visit.property?.address?.lowercased()
                ?? "visit:\(visit.requestId)"
            locationKeys.insert(key)
        }
        let uniqueLocations = max(1, locationKeys.count)
        // Estimate: 15 min driving between consecutive UNIQUE stops, plus
        // 10 min initial leg. NOT a real routing call — flagged in the
        // JSON output as `route_summary_uses_stub_drive_time: true`.
        let driveMinutes = max(0, (uniqueLocations - 1) * 15) + 10
        let estimatedMiles = uniqueLocations * 6
        return RouteSummary(
            stops: stops,
            driveMinutes: driveMinutes,
            estimatedMiles: estimatedMiles
        )
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

                // Wave M6 — route summary card. Pulls today's stops and
                // surfaces a coarse drive-time estimate so the tech sees
                // "this is a 4-stop, 47-mile, 3h block" before drilling
                // in. Hidden when 0 stops; the empty-state Forward
                // Momentum card already covers that case.
                if let summary = todayRouteSummary {
                    FieldRouteSummaryCard(
                        stops: summary.stops,
                        driveMinutes: summary.driveMinutes,
                        estimatedMiles: summary.estimatedMiles
                    )
                }

                // Wave M12 — open part requests pill. Hidden when 0
                // open requests so the Today screen stays clean. Tap
                // routes to FieldPartRequestsListView.
                if openPartRequestCount > 0 {
                    FieldOpenPartRequestsPill(count: openPartRequestCount) {
                        showPartRequestsList = true
                    }
                }

                // Wave M11 — End of Day CTA. Visible when the field tech
                // has finished every today-stop. Salmon pill so it reads
                // as the natural next action; tap opens a focused sheet
                // with the day's totals + tomorrow preview.
                if canShowEndOfDayCTA {
                    Button {
                        showEndOfDay = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Wrap up the day")
                                .font(HavenTypography.uiLabel)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
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
                                    HavenFieldHomeProfileView(home: home, workspaceId: viewModel.dashboard?.workspace?.id)
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
        // Sprint #4 R4-E-3 fix: explicit pull-to-refresh on the
        // Overview ScrollView. The TabView root has the same modifier
        // but mounting it here ensures the gesture lands on this
        // particular ScrollView (SwiftUI's environmental refresh
        // sometimes doesn't bubble through a NavigationStack child).
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showSettings) {
            // Wave 5 finding: pre-fix this passed workspace.primaryEmail /
            // primaryPhone — meaning a crew tech opening Settings saw the
            // OWNER's email and phone displayed under their own name.
            // Now uses the signed-in user's contact info, falling back to
            // workspace contact only when the user info is missing.
            //
            // Sprint #3 R3-E-1 fix: phone fell back to workspace.primaryPhone
            // for non-owner members, leaking the owner's PII (e.g. crew2 saw
            // "555-1100" — the W2 owner's number). The HavenFieldCurrentUser
            // model has no phone field, so passing nil is the right answer
            // until we surface the member's own phone column from the server.
            // Owners (whose own contact IS the workspace primary) still see
            // their phone via the dedicated phone-on-member field once it lands.
            FieldWorkspaceSettingsSheet(
                companyName: viewModel.dashboard?.workspace?.companyName ?? "Chez Field",
                memberName: viewModel.dashboard?.currentUser?.fullName,
                email: viewModel.dashboard?.currentUser?.email
                    ?? viewModel.dashboard?.workspace?.primaryEmail,
                phone: nil,
                providerURL: viewModel.dashboard?.workspace?.providerURL,
                // N-permission-gating fix: hand the caller's role so the
                // sheet can hide the desktop-command-center link from
                // crew techs (only owners can open the Operations Desk).
                role: viewModel.dashboard?.currentUser?.role,
                onSignOut: {
                    appState.authService.signOut()
                }
            )
        }
        .sheet(isPresented: $showEndOfDay) {
            // Wave M11 — end-of-day summary sheet. Loads its own state
            // off `today_summary`. Presented as a focused sheet so the
            // sign-off motion is intentional.
            FieldEndOfDayView(workspaceId: viewModel.dashboard?.workspace?.id)
        }
        .sheet(isPresented: $showPartRequestsList) {
            // Wave M12 — open part requests list. Pulls from the
            // edge function on appear + on .havenFieldPartRequestChanged.
            if let workspaceId = viewModel.dashboard?.workspace?.id, !workspaceId.isEmpty {
                FieldPartRequestsListView(workspaceId: workspaceId)
            }
        }
        .task(id: viewModel.dashboard?.workspace?.id) {
            await loadOpenPartRequestCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .havenFieldPartRequestChanged)) { _ in
            Task { await loadOpenPartRequestCount() }
        }
    }

    /// Wave M12 — refresh the open-part-request count for the Today
    /// pill. Failures swallowed (logged to console) so the dashboard
    /// stays usable even if the edge function is briefly unreachable.
    private func loadOpenPartRequestCount() async {
        guard let workspaceId = viewModel.dashboard?.workspace?.id, !workspaceId.isEmpty else {
            await MainActor.run { openPartRequestCount = 0 }
            return
        }
        do {
            let response = try await HavenFieldService.shared.listOpenPartRequests(workspaceId: workspaceId)
            await MainActor.run { openPartRequestCount = response.openCount }
        } catch {
            print("[HavenFieldHomeTab] failed to load open part requests:", error.localizedDescription)
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
            // N-1 + N-3 fix: render the visit time as device-locale short
            // ("10:00 AM" not "10:00:00") AND suppress the "first at X"
            // segment entirely when no time is on file (was leaking the
            // literal "first at next up" fallback string).
            let when = first.assignment?.windowStartTime?.trimmedOrNil?.fieldShortTime
            let stopCount = todayVisits.count
            let stopWord = stopCount == 1 ? "stop" : "stops"
            let waitingCount = requestedVisits.count
            let waitingWord = waitingCount == 1 ? "request" : "requests"
            var parts: [String] = ["\(stopCount) \(stopWord) today"]
            if let when {
                parts.append("first at \(when)")
            }
            parts.append("\(waitingCount) \(waitingWord) waiting")
            return parts.joined(separator: " · ")
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
                                // Sprint #3 R3-E-6: when the user has zero
                                // upcoming visits but DOES have historical
                                // work in the dashboard, surface a hint
                                // about completed visits so the empty
                                // state doesn't feel like the work disappeared.
                                let allVisits = viewModel.dashboard?.visits ?? []
                                let todayStr = DateFormatter.havenISODate.string(from: Date())
                                let completedCount = allVisits.filter { $0.status == HandymanRequestStatus.completed.rawValue }.count
                                let staleCount = allVisits.filter {
                                    $0.status == HandymanRequestStatus.confirmed.rawValue && ($0.routeDate ?? "9999-12-31") < todayStr
                                }.count
                                FieldEmptyState(
                                    title: "No confirmed visits yet",
                                    subtitle: completedCount > 0
                                        ? "Once visits are confirmed, they'll show up here with routing, windows, and homeowner context. \(completedCount) completed visit\(completedCount == 1 ? "" : "s") in your history."
                                        : (staleCount > 0
                                            ? "No confirmed visits today. \(staleCount) older assignment\(staleCount == 1 ? "" : "s") still need cleanup from dispatch."
                                            : "Once visits are confirmed, they'll show up here with routing, windows, and homeowner context.")
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
                                                    // Wave 7: was salmon (B1 violation —
                                                    // pill is decorative status, not an
                                                    // action). Now navy-tinted to match
                                                    // the rest of the status pill family.
                                                    Text("NEXT UP")
                                                        .font(HavenTypography.caption)
                                                        .foregroundStyle(HavenColors.navy700)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(HavenColors.navy700.opacity(0.10))
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
            // Sprint #4 R4-E-3 fix: explicit pull-to-refresh on the
            // Visits ScrollView so reassignments + status changes
            // surface without a cold-launch cycle.
            .refreshable {
                await viewModel.refresh()
            }

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
    /// Wave M10 — destination for the "Closest customer to me" map view.
    @State private var showNearbyCustomers: Bool = false
    /// Wave M10 — destination for the business-card capture flow.
    @State private var showBusinessCardCapture: Bool = false

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

                // Wave M10 — two side-by-side CTAs above the home list.
                // "Closest customer" routes to the map view; "Add
                // existing vendor" opens the business-card capture flow.
                HStack(spacing: 10) {
                    Button {
                        showNearbyCustomers = true
                    } label: {
                        FieldClientsToolbarPill(
                            icon: "location.fill",
                            label: "Closest customer"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show closest customer to me")

                    Button {
                        showBusinessCardCapture = true
                    } label: {
                        FieldClientsToolbarPill(
                            icon: "rectangle.stack.badge.plus",
                            label: "Add existing vendor"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add existing vendor by business card")
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
                                HavenFieldHomeProfileView(home: home, workspaceId: viewModel.dashboard?.workspace?.id)
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
            // Sprint #4 R4-E-5 fix: extra bottom padding so the last
            // home row in a tall list doesn't sit underneath the
            // floating tab bar pill (was 40, now matches Visits at 140).
            .padding(.bottom, 140)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        // Sprint #4 R4-E-3 fix: explicit pull-to-refresh on the Homes
        // ScrollView so newly-paired homes + invoiced totals refresh
        // without a cold-launch cycle.
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showNearbyCustomers) {
            FieldNearbyCustomersView(
                workspaceId: viewModel.dashboard?.workspace?.id,
                homes: sortedHomes
            )
        }
        .sheet(isPresented: $showBusinessCardCapture) {
            FieldBusinessCardCaptureView(
                workspaceId: viewModel.dashboard?.workspace?.id,
                homes: sortedHomes
            )
        }
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
/// Wave M2 — load state for the four capture-depth actions on one row.
private enum FieldPunchActionInFlight {
    case none, photo, voice, materials, time
}

private struct FieldPunchItemRow: View {
    let item: HavenFieldPunchItem
    let isPending: Bool
    let workspaceId: String?
    let onToggleDone: () -> Void
    /// Wave M2 — fired after a successful capture-depth save so the
    /// parent can refresh punchItems from the server.
    let onItemUpdated: (HavenFieldService.PunchCaptureUpdate.Item) -> Void

    private var isDone: Bool { item.status == "done" }

    @State private var pendingAttachments: [HavenFieldPunchAttachment]?
    @State private var pendingMaterials: [HavenFieldPunchMaterial]?
    @State private var pendingTimeSeconds: Int?
    @State private var pendingVoiceUrl: String?
    @State private var pendingVoicePath: String?
    @State private var actionInFlight: FieldPunchActionInFlight = .none
    @State private var captureError: String?

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var lightboxAttachment: HavenFieldPunchAttachment?

    @StateObject private var voiceRecorder = FieldVoiceRecorder()
    @State private var voicePlayer: AVAudioPlayer?
    @State private var isPlayingVoice = false

    @State private var showMaterialsSheet = false

    /// Wave M12 — true while the punch-item-level Need part sheet is
    /// presented. The sheet pre-sets `punchItemId = item.id` so the
    /// operator can trace which line item the part unblocks.
    @State private var showPartRequestSheet = false

    @State private var timerStart: Date?
    @State private var timerNow: Date = Date()
    private let timerTick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var attachments: [HavenFieldPunchAttachment] {
        pendingAttachments ?? item.attachments
    }
    private var materials: [HavenFieldPunchMaterial] {
        pendingMaterials ?? item.materialsUsed
    }
    private var totalSeconds: Int {
        let base = pendingTimeSeconds ?? item.timeSpentSeconds
        if let start = timerStart {
            return base + max(0, Int(timerNow.timeIntervalSince(start)))
        }
        return base
    }
    private var voicePresent: Bool {
        (pendingVoicePath ?? item.voiceNotePath) != nil
    }
    private var voicePlaybackUrl: String? {
        pendingVoiceUrl ?? item.voiceNoteSignedUrl
    }
    private var workspaceIdResolved: String? {
        guard let id = workspaceId, !id.isEmpty else { return nil }
        return id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggleDone) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isDone ? HavenColors.success : HavenColors.beige400)
                        .font(.system(size: 22))
                        .opacity(isPending ? 0.5 : 1)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(item.title)
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                                .strikethrough(isDone, color: HavenColors.textSecondary)
                            if timerStart != nil || totalSeconds > 0 {
                                Text(formatPunchTimeMMSS(totalSeconds))
                                    .font(HavenTypography.uiLabelSmall.monospacedDigit())
                                    .foregroundStyle(timerStart != nil ? HavenColors.action : HavenColors.textSecondary)
                            }
                        }

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
            }
            .buttonStyle(.plain)
            .disabled(isPending)

            if workspaceIdResolved != nil {
                actionChipBar

                if !attachments.isEmpty {
                    photoThumbnailStrip
                }

                if voicePresent {
                    voicePlaybackChip
                }

                if !materials.isEmpty {
                    materialsSummaryLine
                }

                if let captureError {
                    Text(captureError)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.action)
                        .padding(.top, 2)
                }
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
        .onReceive(timerTick) { now in
            if timerStart != nil { timerNow = now }
        }
        .onChange(of: photoPickerItem) { _, newValue in
            guard let pickItem = newValue else { return }
            Task { await uploadPickedPhoto(pickItem) }
        }
        // Sprint #3 R1-E-6: when the recorder hits its 5-minute cap
        // it auto-stops the AVAudioRecorder and flips this flag. We
        // observe it here and run the same upload+attach flow that
        // tapping Stop manually would, so the file gets persisted
        // instead of dangling in the temp directory.
        .onChange(of: voiceRecorder.didReachMaxDuration) { _, reached in
            guard reached else { return }
            Task { await toggleVoiceRecording() }
        }
        .sheet(item: $lightboxAttachment) { attachment in
            FieldPunchPhotoLightbox(attachment: attachment)
        }
        .sheet(isPresented: $showMaterialsSheet) {
            FieldPunchMaterialsSheet(
                initial: materials,
                onSave: { rows in
                    Task { await saveMaterials(rows) }
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showPartRequestSheet) {
            // Wave M12 — punch-item-level Need part. punchItemId pre-set
            // so the operator can trace which line item the part unblocks.
            // requestId is null here because the punch item already
            // resolves to its parent visit server-side.
            if let workspaceId = workspaceIdResolved {
                FieldPartRequestSheet(
                    workspaceId: workspaceId,
                    requestId: nil,
                    punchItemId: item.id,
                    contextLabel: "For: \(item.title)",
                    onCreated: { _ in
                        showPartRequestSheet = false
                    }
                )
                .presentationDetents([.large])
            }
        }
    }

    @ViewBuilder
    private var actionChipBar: some View {
        // Horizontal scroll keeps the four chips on one line at any iPhone
        // width. Compact icon-first design so a screen with an HVAC visit
        // showing 8 punch items doesn't blow up the row height.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images,
                    preferredItemEncoding: .compatible
                ) {
                    actionChip(
                        icon: "camera.fill",
                        label: attachments.isEmpty ? "Photo" : "\(attachments.count)",
                        inFlight: actionInFlight == .photo,
                        accent: false
                    )
                }
                .disabled(actionInFlight != .none)

                Button {
                    Task { await toggleVoiceRecording() }
                } label: {
                    actionChip(
                        icon: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.fill",
                        label: voiceRecorder.isRecording
                            ? formatPunchTimeMMSS(voiceRecorder.elapsedSeconds)
                            : "Voice",
                        inFlight: actionInFlight == .voice,
                        accent: voiceRecorder.isRecording
                    )
                }
                .buttonStyle(.plain)
                .disabled(actionInFlight != .none && actionInFlight != .voice)

                Button {
                    showMaterialsSheet = true
                } label: {
                    actionChip(
                        icon: "shippingbox.fill",
                        label: materials.isEmpty ? "Parts" : "\(materials.count)",
                        inFlight: actionInFlight == .materials,
                        accent: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(actionInFlight != .none)

                Button {
                    Task { await toggleTimer() }
                } label: {
                    actionChip(
                        icon: "timer",
                        label: timerStart != nil ? "Stop" : (totalSeconds > 0 ? formatPunchTimeMMSS(totalSeconds) : "Time"),
                        inFlight: actionInFlight == .time,
                        accent: timerStart != nil
                    )
                }
                .buttonStyle(.plain)
                .disabled(actionInFlight != .none && actionInFlight != .time)

                // Wave M12 — Need part chip. Pre-sets punchItemId so the
                // operator knows which line item the part unblocks.
                Button {
                    showPartRequestSheet = true
                } label: {
                    actionChip(
                        icon: "wrench.fill",
                        label: "Part",
                        inFlight: false,
                        accent: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(actionInFlight != .none)
            }
        }
    }

    @ViewBuilder
    private func actionChip(icon: String, label: String, inFlight: Bool, accent: Bool) -> some View {
        HStack(spacing: 6) {
            if inFlight {
                ProgressView()
                    .scaleEffect(0.65)
                    .tint(accent ? .white : HavenColors.navy700)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent ? .white : HavenColors.navy700)
            }
            Text(label)
                .font(HavenTypography.uiLabelSmall.monospacedDigit())
                .foregroundStyle(accent ? .white : HavenColors.navy700)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(accent ? HavenColors.action : HavenColors.indigo50)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(accent ? Color.clear : HavenColors.border, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var photoThumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments, id: \.id) { attachment in
                    Button {
                        lightboxAttachment = attachment
                    } label: {
                        thumbnailTile(for: attachment)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private func thumbnailTile(for attachment: HavenFieldPunchAttachment) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(HavenColors.indigo50)
            if let urlString = attachment.signedUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().scaleEffect(0.7)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.textSecondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(HavenColors.border, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var voicePlaybackChip: some View {
        Button {
            Task { await toggleVoicePlayback() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isPlayingVoice ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(isPlayingVoice ? "Playing voice note" : "Voice note")
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(HavenColors.indigo50)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(HavenColors.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var materialsSummaryLine: some View {
        let total = materials.reduce(0.0) { $0 + ($1.qty * $1.unitCost) }
        HStack(spacing: 6) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
            Text("\(materials.count) material\(materials.count == 1 ? "" : "s") · $\(String(format: "%.2f", total))")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.top, 2)
    }

    private func uploadPickedPhoto(_ pickerItem: PhotosPickerItem) async {
        defer {
            DispatchQueue.main.async { self.photoPickerItem = nil }
        }
        guard let workspaceId = workspaceIdResolved else { return }
        await MainActor.run {
            actionInFlight = .photo
            captureError = nil
        }
        defer { Task { @MainActor in actionInFlight = .none } }

        do {
            guard let raw = try await pickerItem.loadTransferable(type: Data.self) else {
                throw NSError(domain: "FieldPunch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't read photo data"])
            }
            let downsized = try await Self.downsizeJpeg(rawData: raw, maxEdge: 1600, quality: 0.82)
            let base64 = downsized.base64EncodedString()

            let updated = try await HavenFieldService.shared.attachPunchPhoto(
                workspaceId: workspaceId,
                itemId: item.id,
                base64: base64,
                contentType: "image/jpeg",
                caption: nil
            )
            await MainActor.run {
                pendingAttachments = updated.attachments
                onItemUpdated(updated)
            }
        } catch {
            await MainActor.run {
                captureError = "Photo upload failed: \(error.localizedDescription)"
            }
        }
    }

    private func toggleVoiceRecording() async {
        guard let workspaceId = workspaceIdResolved else { return }
        if voiceRecorder.isRecording {
            await MainActor.run {
                actionInFlight = .voice
                captureError = nil
            }
            defer { Task { @MainActor in actionInFlight = .none } }
            do {
                guard let url = await voiceRecorder.stopAndReturnFile() else {
                    throw NSError(domain: "FieldPunch", code: 2, userInfo: [NSLocalizedDescriptionKey: "Couldn't read recording"])
                }
                let bytes = try Data(contentsOf: url)
                let base64 = bytes.base64EncodedString()
                let updated = try await HavenFieldService.shared.attachPunchVoice(
                    workspaceId: workspaceId,
                    itemId: item.id,
                    base64: base64,
                    mimeType: "audio/m4a"
                )
                await MainActor.run {
                    pendingVoicePath = updated.voiceNotePath
                    pendingVoiceUrl = updated.voiceNoteSignedUrl
                    onItemUpdated(updated)
                    try? FileManager.default.removeItem(at: url)
                }
            } catch {
                await MainActor.run {
                    captureError = "Voice upload failed: \(error.localizedDescription)"
                }
            }
        } else {
            do {
                try await voiceRecorder.start()
            } catch {
                await MainActor.run {
                    captureError = "Microphone unavailable: \(error.localizedDescription)"
                }
            }
        }
    }

    private func toggleVoicePlayback() async {
        guard let urlString = voicePlaybackUrl, let url = URL(string: urlString) else { return }
        if isPlayingVoice {
            voicePlayer?.stop()
            await MainActor.run { isPlayingVoice = false }
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let (data, _) = try await URLSession.shared.data(from: url)
            let player = try AVAudioPlayer(data: data)
            await MainActor.run {
                voicePlayer = player
                isPlayingVoice = true
            }
            player.play()
            Task { [weak player] in
                while let p = player, p.isPlaying { try? await Task.sleep(nanoseconds: 200_000_000) }
                await MainActor.run { isPlayingVoice = false }
            }
        } catch {
            await MainActor.run {
                captureError = "Playback failed: \(error.localizedDescription)"
            }
        }
    }

    private func saveMaterials(_ rows: [HavenFieldPunchMaterial]) async {
        guard let workspaceId = workspaceIdResolved else { return }
        await MainActor.run {
            actionInFlight = .materials
            captureError = nil
        }
        defer { Task { @MainActor in actionInFlight = .none } }
        do {
            let updated = try await HavenFieldService.shared.setPunchMaterials(
                workspaceId: workspaceId,
                itemId: item.id,
                materials: rows
            )
            await MainActor.run {
                pendingMaterials = updated.materialsUsed
                onItemUpdated(updated)
            }
        } catch {
            await MainActor.run {
                captureError = "Couldn't save materials: \(error.localizedDescription)"
            }
        }
    }

    private func toggleTimer() async {
        if let start = timerStart {
            guard let workspaceId = workspaceIdResolved else { return }
            let runSeconds = max(0, Int(Date().timeIntervalSince(start)))
            let banked = pendingTimeSeconds ?? item.timeSpentSeconds
            let total = banked + runSeconds
            await MainActor.run {
                actionInFlight = .time
                captureError = nil
                timerStart = nil
            }
            defer { Task { @MainActor in actionInFlight = .none } }
            do {
                let updated = try await HavenFieldService.shared.setPunchTimeSpent(
                    workspaceId: workspaceId,
                    itemId: item.id,
                    seconds: total
                )
                await MainActor.run {
                    pendingTimeSeconds = updated.timeSpentSeconds
                    onItemUpdated(updated)
                }
            } catch {
                await MainActor.run {
                    captureError = "Couldn't save time: \(error.localizedDescription)"
                }
            }
        } else {
            await MainActor.run {
                timerStart = Date()
                timerNow = Date()
            }
        }
    }

    /// Wave M12 — relaxed access from `private static` to `static` so the
    /// part-request sheet (which lives outside this struct) can reuse the
    /// downsize routine without duplicating it.
    static func downsizeJpeg(rawData: Data, maxEdge: CGFloat, quality: CGFloat) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = UIImage(data: rawData) else {
                    continuation.resume(throwing: NSError(domain: "FieldPunch", code: 3, userInfo: [NSLocalizedDescriptionKey: "Couldn't decode image"]))
                    return
                }
                let size = image.size
                let longest = max(size.width, size.height)
                let scale: CGFloat = longest > maxEdge ? (maxEdge / longest) : 1.0
                let newSize = CGSize(width: size.width * scale, height: size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1.0
                let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                let resized = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
                guard let data = resized.jpegData(compressionQuality: quality) else {
                    continuation.resume(throwing: NSError(domain: "FieldPunch", code: 4, userInfo: [NSLocalizedDescriptionKey: "Couldn't encode JPEG"]))
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
}

/// Wave M2 — full-screen lightbox for a tapped punch photo.
private struct FieldPunchPhotoLightbox: View {
    let attachment: HavenFieldPunchAttachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let urlString = attachment.signedUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .empty:
                        ProgressView().tint(.white)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 56))
                            .foregroundStyle(.white)
                    @unknown default: EmptyView()
                    }
                }
            } else {
                Text("Photo unavailable")
                    .foregroundStyle(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                Spacer()
                if let caption = attachment.caption, !caption.isEmpty {
                    Text(caption)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}

/// Wave M2 — sheet for editing the materials_used array on a punch item.
private struct FieldPunchMaterialsSheet: View {
    let initial: [HavenFieldPunchMaterial]
    let onSave: ([HavenFieldPunchMaterial]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rows: [Draft]

    private struct Draft: Identifiable {
        let id = UUID()
        var name: String
        var qty: String
        var unitCost: String
        init(_ source: HavenFieldPunchMaterial) {
            self.name = source.name
            self.qty = source.qty == 0 ? "" : String(format: "%g", source.qty)
            self.unitCost = source.unitCost == 0 ? "" : String(format: "%.2f", source.unitCost)
        }
        init() {
            self.name = ""
            self.qty = ""
            self.unitCost = ""
        }
    }

    init(initial: [HavenFieldPunchMaterial], onSave: @escaping ([HavenFieldPunchMaterial]) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _rows = State(initialValue: initial.isEmpty ? [Draft()] : initial.map { Draft($0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach($rows) { $row in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Material (e.g. Schedule 40 PVC, 1\")", text: $row.name)
                                .textInputAutocapitalization(.sentences)
                            HStack(spacing: 8) {
                                TextField("Qty", text: $row.qty)
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: 90)
                                TextField("Unit cost", text: $row.unitCost)
                                    .keyboardType(.decimalPad)
                            }
                            .font(.body.monospacedDigit())
                        }
                    }
                    .onDelete { indices in
                        rows.remove(atOffsets: indices)
                        if rows.isEmpty { rows.append(Draft()) }
                    }
                    Button {
                        rows.append(Draft())
                    } label: {
                        Label("Add material", systemImage: "plus.circle")
                    }
                } header: {
                    Text("MATERIALS USED")
                } footer: {
                    Text("Quantity and unit cost are optional. Save without them to capture just a name.")
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { commit() }
                        .bold()
                }
            }
        }
    }

    private func commit() {
        let cleaned = rows.compactMap { row -> HavenFieldPunchMaterial? in
            let name = row.name.trimmingCharacters(in: .whitespaces)
            if name.isEmpty { return nil }
            let qty = Double(row.qty) ?? 0
            let unitCost = Double(row.unitCost) ?? 0
            return HavenFieldPunchMaterial(sku: nil, name: name, qty: qty, unitCost: unitCost)
        }
        onSave(cleaned)
        dismiss()
    }
}

// MARK: - Wave M12 Need part flow UI

/// Wave M12 — modal sheet for submitting a part request mid-visit.
/// Used both at the visit level (whole-visit context) and from a punch
/// item's wrench chip (`punchItemId` pre-set so the operator can trace
/// which line item the part unblocks). All three iOS surfaces converge
/// on this single sheet.
///
/// Lifecycle: pickReady → uploading (per photo) → submitting → success
/// (auto-dismisses) or error (inline retry banner).
private struct FieldPartRequestSheet: View {
    let workspaceId: String
    let requestId: String?
    let punchItemId: String?
    /// Caller hands us a starting context label for the kicker so the
    /// tech sees "For: Brookfield · Boiler" or "For: this visit" before
    /// they type. Kept optional so the visit-level entry point can
    /// pass nil and let the sheet decide.
    let contextLabel: String?
    /// Fired after a successful create so the parent can refresh state
    /// (e.g. refresh the open-requests pill on Today).
    let onCreated: (HavenFieldPartRequest) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description: String = ""
    @State private var urgency: String = "next_visit"
    @State private var photos: [HavenFieldPunchAttachment] = []
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var isSubmitting = false
    @State private var validationError: String?
    @State private var submitError: String?
    @State private var didSucceed = false
    @State private var lightboxAttachment: HavenFieldPunchAttachment?

    private var canSubmit: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
            && !isUploadingPhoto
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    descriptionField

                    urgencyPicker

                    photoSection

                    if let validationError {
                        Text(validationError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }

                    if let submitError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.action)
                            Text(submitError)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer(minLength: 0)
                            Button("Retry") { Task { await submit() } }
                                .buttonStyle(FieldSecondaryButtonStyle(compact: true))
                        }
                        .padding(12)
                        .background(HavenColors.action.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    submitButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 60)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Need part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .onChange(of: photoPickerItem) { _, newValue in
                guard let item = newValue else { return }
                Task { await uploadPickedPhoto(item) }
            }
            .sheet(item: $lightboxAttachment) { attachment in
                FieldPunchPhotoLightbox(attachment: attachment)
            }
            .overlay(alignment: .bottom) {
                if didSucceed {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Sent to operator")
                            .font(HavenTypography.uiLabel)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .background(HavenColors.navy800)
                    .clipShape(Capsule())
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: didSucceed)
        }
    }

    @ViewBuilder
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PART REQUEST")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Text(headerTitle)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text(headerSubtitle)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HavenColors.border, lineWidth: 0.5)
        )
    }

    private var headerTitle: String {
        if let label = contextLabel, !label.isEmpty {
            return label
        }
        return punchItemId != nil ? "For this punch item" : "For this visit"
    }

    private var headerSubtitle: String {
        "Operator sees this in real time and can dispatch another tech with the part or order it from a supplier."
    }

    @ViewBuilder
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHAT PART DO YOU NEED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            TextField(
                "e.g. 1/2-inch copper compression fitting",
                text: $description,
                axis: .vertical
            )
            .lineLimit(3...6)
            .font(HavenTypography.body)
            .foregroundStyle(HavenColors.textPrimary)
            .padding(12)
            .background(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        validationError != nil ? HavenColors.action : HavenColors.border,
                        lineWidth: validationError != nil ? 1.5 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var urgencyPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("URGENCY")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            VStack(spacing: 8) {
                urgencyRow(
                    value: "blocking_now",
                    label: "Blocking now",
                    subtitle: "Visit can't continue without it.",
                    accentColor: HavenColors.critical
                )
                urgencyRow(
                    value: "next_visit",
                    label: "Next visit",
                    subtitle: "Bring it on the next stop here.",
                    accentColor: HavenColors.warning
                )
                urgencyRow(
                    value: "order_for_stock",
                    label: "Order for stock",
                    subtitle: "Restock the truck. No deadline.",
                    accentColor: HavenColors.textSecondary
                )
            }
        }
    }

    @ViewBuilder
    private func urgencyRow(value: String, label: String, subtitle: String, accentColor: Color) -> some View {
        let isSelected = urgency == value
        Button {
            urgency = value
            Haptics.selection()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? accentColor : HavenColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isSelected ? accentColor.opacity(0.06) : HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor.opacity(0.4) : HavenColors.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PHOTOS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images,
                    preferredItemEncoding: .compatible
                ) {
                    HStack(spacing: 6) {
                        if isUploadingPhoto {
                            ProgressView().scaleEffect(0.6)
                                .tint(HavenColors.navy700)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(isUploadingPhoto ? "Uploading" : "Add photo")
                            .font(HavenTypography.uiLabelSmall)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(HavenColors.indigo50)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(HavenColors.border, lineWidth: 0.5))
                }
                .disabled(isUploadingPhoto || isSubmitting)
            }

            if photos.isEmpty {
                Text("Optional. A photo helps the operator confirm the part.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos) { photo in
                            Button {
                                lightboxAttachment = photo
                            } label: {
                                photoThumbnail(photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    @ViewBuilder
    private func photoThumbnail(_ photo: HavenFieldPunchAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(HavenColors.indigo50)
                if let urlString = photo.signedUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: ProgressView().scaleEffect(0.7)
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure: Image(systemName: "photo").foregroundStyle(HavenColors.textSecondary)
                        @unknown default: EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(HavenColors.border, lineWidth: 0.5)
            )

            Button {
                photos.removeAll { $0.id == photo.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy800)
                    .background(Circle().fill(.white))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            if isSubmitting {
                HStack(spacing: 8) {
                    ProgressView().tint(HavenColors.textOnAction)
                    Text("Sending")
                }
            } else {
                Text("Submit")
            }
        }
        .buttonStyle(FieldPrimaryButtonStyle())
        .disabled(!canSubmit)
        .padding(.top, 4)
    }

    private func uploadPickedPhoto(_ pickerItem: PhotosPickerItem) async {
        defer { DispatchQueue.main.async { self.photoPickerItem = nil } }

        await MainActor.run { isUploadingPhoto = true; submitError = nil }
        defer { Task { @MainActor in isUploadingPhoto = false } }

        do {
            guard let raw = try await pickerItem.loadTransferable(type: Data.self) else {
                throw NSError(domain: "FieldPart", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't read photo data"])
            }
            let downsized = try await FieldPunchItemRow.downsizeJpeg(rawData: raw, maxEdge: 1600, quality: 0.82)
            let base64 = downsized.base64EncodedString()
            let uploaded = try await HavenFieldService.shared.attachPartRequestPhoto(
                workspaceId: workspaceId,
                base64: base64,
                contentType: "image/jpeg",
                caption: nil
            )
            await MainActor.run { photos.append(uploaded) }
        } catch {
            await MainActor.run {
                submitError = "Photo upload failed: \(error.localizedDescription)"
            }
        }
    }

    private func submit() async {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await MainActor.run {
                validationError = "What part do you need?"
            }
            return
        }
        await MainActor.run {
            validationError = nil
            submitError = nil
            isSubmitting = true
        }
        defer { Task { @MainActor in isSubmitting = false } }

        do {
            let row = try await HavenFieldService.shared.createPartRequest(
                workspaceId: workspaceId,
                requestId: requestId,
                punchItemId: punchItemId,
                description: trimmed,
                urgency: urgency,
                photos: photos
            )
            await MainActor.run {
                onCreated(row)
                didSucceed = true
                Haptics.success()
                NotificationCenter.default.post(name: .havenFieldPartRequestChanged, object: nil)
            }
            // Brief delay so the toast registers before the sheet vanishes.
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run {
                submitError = error.localizedDescription
                Haptics.error()
            }
        }
    }
}

/// Wave M12 — list of every open part request for the workspace. Tap
/// the Today-screen pill to land here. Operator can update status,
/// fulfillment, supplier from each row's detail.
private struct FieldPartRequestsListView: View {
    let workspaceId: String

    @Environment(\.dismiss) private var dismiss
    @State private var partRequests: [HavenFieldPartRequest] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selected: HavenFieldPartRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading && partRequests.isEmpty {
                        ForEach(0..<3, id: \.self) { _ in skeletonRow }
                    } else if let loadError, partRequests.isEmpty {
                        FieldErrorBanner(message: loadError)
                    } else if partRequests.isEmpty {
                        FieldEmptyState(
                            title: "No open part requests",
                            subtitle: "Tap Need part on a visit or punch item to flag one for the operator."
                        )
                    } else {
                        ForEach(partRequests) { req in
                            Button {
                                selected = req
                            } label: {
                                FieldPartRequestRow(request: req)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 60)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Part requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.action)
                }
            }
            .task {
                await load()
            }
            .refreshable {
                await load()
            }
            .sheet(item: $selected) { req in
                FieldPartRequestDetailSheet(request: req, workspaceId: workspaceId) { updated in
                    if let idx = partRequests.firstIndex(where: { $0.id == updated.id }) {
                        // Drop fulfilled / cancelled rows from the open list
                        // so the count + visible rows align with reality.
                        if updated.status == "fulfilled" || updated.status == "cancelled" {
                            partRequests.remove(at: idx)
                        } else {
                            partRequests[idx] = updated
                        }
                    }
                    selected = nil
                }
            }
        }
    }

    @ViewBuilder
    private var skeletonRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(HavenColors.indigo50)
                .frame(height: 16)
                .frame(maxWidth: 180)
            RoundedRectangle(cornerRadius: 6)
                .fill(HavenColors.indigo50.opacity(0.7))
                .frame(height: 12)
                .frame(maxWidth: 240)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .redacted(reason: .placeholder)
    }

    private func load() async {
        await MainActor.run { isLoading = true; loadError = nil }
        defer { Task { @MainActor in isLoading = false } }
        do {
            let response = try await HavenFieldService.shared.listOpenPartRequests(workspaceId: workspaceId)
            await MainActor.run {
                partRequests = response.partRequests.sorted { lhs, rhs in
                    // Sort by urgency tier descending (blocking_now first)
                    // then by createdAt descending so newest top.
                    let lOrder = urgencyOrder(lhs.urgency)
                    let rOrder = urgencyOrder(rhs.urgency)
                    if lOrder != rOrder { return lOrder > rOrder }
                    return (lhs.createdAt ?? "") > (rhs.createdAt ?? "")
                }
            }
        } catch {
            await MainActor.run { loadError = error.localizedDescription }
        }
    }

    private func urgencyOrder(_ urgency: String) -> Int {
        switch urgency {
        case "blocking_now": return 3
        case "next_visit": return 2
        case "order_for_stock": return 1
        default: return 0
        }
    }
}

/// Wave M12 — single row in the FieldPartRequestsListView.
private struct FieldPartRequestRow: View {
    let request: HavenFieldPartRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(request.description)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }

            HStack(spacing: 8) {
                urgencyPill
                statusPill
                if let supplier = request.supplier, !supplier.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(supplier)
                            .font(HavenTypography.uiLabelSmall)
                            .lineLimit(1)
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            if let eta = request.supplierEta, !eta.isEmpty {
                Text("ETA \(eta.fieldShortDate ?? eta)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var urgencyPill: some View {
        let color: Color = {
            switch request.urgency {
            case "blocking_now": return HavenColors.critical
            case "next_visit": return HavenColors.warning
            default: return HavenColors.textSecondary
            }
        }()
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(request.urgencyDisplayLabel)
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var statusPill: some View {
        Text(request.statusDisplayLabel)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(HavenColors.indigo50)
            .clipShape(Capsule())
    }
}

/// Wave M12 — detail sheet for a single part request. Shows photos
/// inline + lets the operator update status / supplier / ETA.
private struct FieldPartRequestDetailSheet: View {
    let request: HavenFieldPartRequest
    let workspaceId: String
    let onUpdated: (HavenFieldPartRequest) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var status: String
    @State private var supplier: String
    @State private var supplierEta: Date
    @State private var hasEta: Bool
    @State private var lightboxAttachment: HavenFieldPunchAttachment?
    @State private var isSubmitting = false
    @State private var submitError: String?

    init(request: HavenFieldPartRequest, workspaceId: String, onUpdated: @escaping (HavenFieldPartRequest) -> Void) {
        self.request = request
        self.workspaceId = workspaceId
        self.onUpdated = onUpdated
        _status = State(initialValue: request.status)
        _supplier = State(initialValue: request.supplier ?? "")
        let parsed = request.supplierEta.flatMap { ISO8601DateFormatter().date(from: $0) }
        _supplierEta = State(initialValue: parsed ?? Date().addingTimeInterval(60 * 60 * 24))
        _hasEta = State(initialValue: parsed != nil)
    }

    private let statuses: [(value: String, label: String)] = [
        ("open", "Open"),
        ("ordered", "Ordered"),
        ("in_truck", "In truck"),
        ("fulfilled", "Fulfilled"),
        ("cancelled", "Cancelled"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    descriptionCard

                    if !request.photos.isEmpty {
                        photoStrip
                    }

                    statusSection

                    supplierSection

                    if let submitError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.action)
                            Text(submitError)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(HavenColors.action.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        if isSubmitting {
                            HStack(spacing: 8) {
                                ProgressView().tint(HavenColors.textOnAction)
                                Text("Saving")
                            }
                        } else {
                            Text("Save changes")
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 60)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Part request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .sheet(item: $lightboxAttachment) { attachment in
                FieldPunchPhotoLightbox(attachment: attachment)
            }
        }
    }

    @ViewBuilder
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REQUESTED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Text(request.description)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PHOTOS")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(request.photos) { photo in
                        Button {
                            lightboxAttachment = photo
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(HavenColors.indigo50)
                                if let urlString = photo.signedUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty: ProgressView().scaleEffect(0.7)
                                        case .success(let img): img.resizable().scaledToFill()
                                        case .failure: Image(systemName: "photo").foregroundStyle(HavenColors.textSecondary)
                                        @unknown default: EmptyView()
                                        }
                                    }
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(HavenColors.border, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATUS")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Picker("Status", selection: $status) {
                ForEach(statuses, id: \.value) { row in
                    Text(row.label).tag(row.value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var supplierSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUPPLIER")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            TextField("Optional supplier name", text: $supplier)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HavenColors.border, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Toggle(isOn: $hasEta) {
                Text("Has ETA")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .tint(HavenColors.action)

            if hasEta {
                DatePicker("ETA", selection: $supplierEta, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func save() async {
        await MainActor.run {
            submitError = nil
            isSubmitting = true
        }
        defer { Task { @MainActor in isSubmitting = false } }
        do {
            let etaString: String? = hasEta ? ISO8601DateFormatter().string(from: supplierEta) : nil
            let trimmedSupplier = supplier.trimmingCharacters(in: .whitespacesAndNewlines)
            let updated = try await HavenFieldService.shared.updatePartStatus(
                workspaceId: workspaceId,
                partRequestId: request.id,
                status: status,
                supplier: trimmedSupplier.isEmpty ? nil : trimmedSupplier,
                supplierEta: etaString
            )
            await MainActor.run {
                onUpdated(updated)
                Haptics.success()
                NotificationCenter.default.post(name: .havenFieldPartRequestChanged, object: nil)
            }
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run {
                submitError = error.localizedDescription
                Haptics.error()
            }
        }
    }
}

/// Wave M12 — Today-screen pill component. Renders a chip with the
/// open-request count + a wrench icon. Tap routes to
/// FieldPartRequestsListView. Hidden when there are 0 open requests.
private struct FieldOpenPartRequestsPill: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(count) part \(count == 1 ? "request" : "requests") open")
                    .font(HavenTypography.uiLabel)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(HavenColors.action)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(HavenColors.action.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(HavenColors.action.opacity(0.25), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

/// Wave M2 — voice recorder helper.
@MainActor
final class FieldVoiceRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: Int = 0
    /// Sprint #3 R1-E-6: hard 5-minute cap. AAC at 22kHz mono medium
    /// quality runs ~24 KB/sec → ~7 MB cap. Plenty of headroom for
    /// any realistic voice note while preventing the "tech walked off
    /// with the mic on" failure mode that would let the file balloon
    /// to ~85 MB/hour and wedge upload.
    static let maxDurationSeconds: Int = 300
    /// Set when the recorder auto-stops itself at maxDurationSeconds.
    /// The owning view should observe this and run its save handler.
    @Published private(set) var didReachMaxDuration: Bool = false

    private var recorder: AVAudioRecorder?
    private var startedAt: Date?
    private var tickTask: Task<Void, Never>?
    private var fileUrl: URL?

    func start() async throws {
        let session = AVAudioSession.sharedInstance()
        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            } else {
                session.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        }
        if !granted {
            throw NSError(domain: "FieldVoice", code: 5, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
        }
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try session.setActive(true)

        let dir = FileManager.default.temporaryDirectory
        let path = dir.appendingPathComponent("punch-voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let rec = try AVAudioRecorder(url: path, settings: settings)
        rec.prepareToRecord()
        rec.record()
        recorder = rec
        fileUrl = path
        startedAt = Date()
        elapsedSeconds = 0
        isRecording = true
        didReachMaxDuration = false
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !(Task.isCancelled) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self, let started = self.startedAt else { return }
                    let elapsed = Int(Date().timeIntervalSince(started))
                    self.elapsedSeconds = elapsed
                    // Sprint #3 R1-E-6: auto-stop at the 5-minute cap.
                    // We mark didReachMaxDuration so the owning view
                    // can pick up the file via its existing onChange
                    // observer + run the save flow.
                    if elapsed >= Self.maxDurationSeconds && self.recorder != nil {
                        self.didReachMaxDuration = true
                        self.recorder?.stop()
                        // Leave the file path in place — stopAndReturnFile()
                        // will pick it up. The view marks didReachMaxDuration
                        // via onChange and calls stopAndReturnFile().
                    }
                }
            }
        }
    }

    func stopAndReturnFile() async -> URL? {
        guard let rec = recorder else { return nil }
        rec.stop()
        tickTask?.cancel()
        tickTask = nil
        let url = fileUrl
        recorder = nil
        startedAt = nil
        isRecording = false
        elapsedSeconds = 0
        // Sprint #3 R1-E-6: clear the cap-reached flag once the
        // owning view has consumed it, so the next start() call
        // starts from a clean slate.
        didReachMaxDuration = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return url
    }
}

/// Wave M2 — mm:ss formatter shared by timer chip + voice recorder.
private func formatPunchTimeMMSS(_ seconds: Int) -> String {
    let mins = min(99, max(0, seconds) / 60)
    let secs = max(0, seconds) % 60
    return String(format: "%02d:%02d", mins, secs)
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
                        // Wave 7: was salmon-tinted (B1 violation — pill is
                        // a status indicator, not an action). Aligned with
                        // the sibling quote/thread badges which are navy.
                        FieldClientBadge(
                            icon: "calendar.badge.clock",
                            label: "\(upcomingVisitCount) upcoming",
                            tint: HavenColors.navy700
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
                // D7 fix: pills wrapped awkwardly when both
                // upcoming-visits and quotes labels stacked next to a
                // long home name. Force one-line + tiny scale-down so
                // they always fit and never wrap.
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
        // Fixed-width prevents the surrounding HStack from compressing
        // the label below readable; combined with `minimumScaleFactor`
        // above the pill never wraps OR clips.
        .fixedSize(horizontal: true, vertical: false)
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
                                            rootViewModel: viewModel,
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

// MARK: - Wave M1 visit lifecycle

/// Wave M1 — single-shot location capture for clock-in. Asks for
/// when-in-use authorization, takes one location reading, hands it back
/// via the completion. The whole class lives for the duration of one
/// capture: instantiate, call `capture(...)`, the callback fires once
/// with either coords or nil-on-denied/timeout. The `CLLocationManager`
/// instance is held by the wrapper so the delegate stays alive for the
/// async hop into iOS' location service.
@MainActor
final class FieldLocationCapture: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    /// 4-second timeout — long enough for a typical residential GPS
    /// fix on iOS but short enough that the iOS UI's loading state
    /// doesn't trap the user staring at a spinner.
    private let timeout: TimeInterval = 4.0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func capture(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Fall through — the delegate will fire when the user
            // grants/denies, and that handler kicks off the request.
        case .authorizedWhenInUse, .authorizedAlways:
            requestSingleLocation()
        case .denied, .restricted:
            finish(with: nil)
        @unknown default:
            finish(with: nil)
        }
    }

    private func requestSingleLocation() {
        manager.requestLocation()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self!.timeout * 1_000_000_000))
            await MainActor.run { [weak self] in
                self?.finish(with: nil)
            }
        }
    }

    private func finish(with location: CLLocation?) {
        guard let cb = completion else { return }
        completion = nil
        cb(location)
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.requestSingleLocation()
            case .denied, .restricted:
                self.finish(with: nil)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor [weak self] in
            self?.finish(with: locations.last)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.finish(with: nil)
        }
    }
}

/// Wave M1 — visit lifecycle state derived from the assignment row.
/// Names the four user-visible states so the rendering logic stays a
/// simple switch instead of nested `if let`s.
enum FieldVisitLifecycleState: Equatable {
    case notStarted
    case running(clockInAt: Date, pausedSeconds: Int)
    case paused(clockInAt: Date, pausedSeconds: Int, pausedAt: Date)
    case completed(elapsed: Int)

    /// Read the lifecycle state out of an assignment, given the optional
    /// open pause's `paused_at`. iOS pulls the open pause's timestamp
    /// from the running clock view's local state — there's no single
    /// edge-fn-served boolean for "is currently paused" because the
    /// pause row is its own lifecycle.
    static func resolve(
        assignment: HavenFieldVisitAssignment?,
        currentlyPausedAt: Date?
    ) -> FieldVisitLifecycleState {
        guard let assignment else { return .notStarted }
        guard let clockInAtString = assignment.clockInAt,
              let clockInAt = parseISO(clockInAtString) else {
            return .notStarted
        }
        if let clockOutAtString = assignment.clockOutAt,
           let clockOutAt = parseISO(clockOutAtString) {
            // Final number — server already deducted paused_seconds.
            let totalSec = Int(clockOutAt.timeIntervalSince(clockInAt)) - assignment.pausedSeconds
            return .completed(elapsed: max(0, totalSec))
        }
        if let pausedAt = currentlyPausedAt {
            return .paused(clockInAt: clockInAt, pausedSeconds: assignment.pausedSeconds, pausedAt: pausedAt)
        }
        return .running(clockInAt: clockInAt, pausedSeconds: assignment.pausedSeconds)
    }

    private static func parseISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: string) { return parsed }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

/// Wave M1 — pause reason picker options, surfaced in the Pause modal.
enum FieldPauseReason: String, CaseIterable, Identifiable {
    case lunch = "Lunch"
    case wrongScope = "Customer answered for different reason"
    case issue = "Issue"
    case other = "Other"

    var id: String { rawValue }
}

/// Wave M9 — entry method picker options. The wire-format value is the
/// snake_case `code` (matches the server's `access_method` column +
/// `M9_ACCESS_METHODS` allowlist on the edge function).
enum FieldAccessMethod: String, CaseIterable, Identifiable {
    case customerPresent = "customer_present"
    case lockbox = "lockbox"
    case keyUnderMat = "key_under_mat"
    case doorCode = "door_code"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .customerPresent: return "Customer present"
        case .lockbox: return "Lockbox"
        case .keyUnderMat: return "Key under mat"
        case .doorCode: return "Door code"
        }
    }

    /// Inline notes prompt — guides the tech on what to capture so the
    /// next-day reader has actionable detail.
    var notesPrompt: String {
        switch self {
        case .customerPresent: return "Optional. e.g. \"Side door, ring twice\""
        case .lockbox: return "Lockbox code + location, e.g. \"Code 1234, side gate\""
        case .keyUnderMat: return "Key location, e.g. \"Under flowerpot on porch\""
        case .doorCode: return "Door code + which door, e.g. \"Garage door 5678\""
        }
    }

    /// SF Symbol for the row icon + header chip.
    var icon: String {
        switch self {
        case .customerPresent: return "person.fill"
        case .lockbox: return "lock.fill"
        case .keyUnderMat: return "key.fill"
        case .doorCode: return "number.square.fill"
        }
    }

    /// True when this method needs notes to be useful at all (lockbox
    /// code, key location, door code). `customer_present` is the only
    /// method where empty notes is a sensible default.
    var requiresNotes: Bool {
        switch self {
        case .customerPresent: return false
        case .lockbox, .keyUnderMat, .doorCode: return true
        }
    }
}

/// Wave M9 — mid-stream cancellation reason picker options. Wire format
/// matches the server's `M9_CANCEL_REASONS` allowlist; "Other" sends
/// the free-form text the tech typed in `body.reason` so the audit
/// message reads naturally.
enum FieldCancelReason: String, CaseIterable, Identifiable {
    case weather = "weather"
    case customerCancelled = "customer_cancelled"
    case techEmergency = "tech_emergency"
    case other = "other"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .weather: return "Weather"
        case .customerCancelled: return "Customer cancelled"
        case .techEmergency: return "Tech emergency"
        case .other: return "Other"
        }
    }
}

/// Wave M1 — open pause window decoded from PostgREST. Resilient
/// decoder so a future column drift doesn't take down the whole array.
struct HavenFieldOpenPause: Codable, Identifiable, Hashable {
    let id: String
    let pausedAt: String?
    let resumedAt: String?
    let reason: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case pausedAt = "paused_at"
        case resumedAt = "resumed_at"
        case reason
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        pausedAt = (try? c.decodeIfPresent(String.self, forKey: .pausedAt)) ?? nil
        resumedAt = (try? c.decodeIfPresent(String.self, forKey: .resumedAt)) ?? nil
        reason = (try? c.decodeIfPresent(String.self, forKey: .reason)) ?? nil
    }
}

private struct HavenFieldVisitWorkspaceView: View {
    @ObservedObject var viewModel: HavenFieldVisitWorkspaceModel
    /// Sprint #3 R1-E-7: observe app lifecycle so we can re-pull
    /// server-truth lifecycle state (open pause, current clock-in
    /// state, SLA countdown) when the user foregrounds. Without this
    /// the visit-detail UI would show stale paused/in-progress state
    /// for an unbounded time after wakeup.
    @Environment(\.scenePhase) private var scenePhase
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

    // MARK: Wave M1 lifecycle state

    /// The most recent assignment row from a successful start/pause/resume/
    /// complete network call. Falls back to `viewModel.visit.assignment`
    /// when the local override is nil so the UI reads from canonical
    /// dashboard state on first render.
    @State private var lifecycleAssignment: HavenFieldVisitAssignment?
    /// When the local pause was opened (server hasn't told us about
    /// existing open pauses, so we track the local opening here). Synced
    /// from the lifecycleAssignment if the server reports we're already
    /// paused on first load.
    @State private var currentlyPausedAt: Date?
    /// True while a lifecycle network request is in flight. Drives the
    /// loading skeleton on the lifecycle section without blocking other
    /// taps elsewhere on the view.
    @State private var lifecycleSyncing = false
    /// Localized error from the most recent lifecycle action — surfaces
    /// inline as a Retry banner on the lifecycle section.
    @State private var lifecycleError: String?
    /// Keeps the FieldLocationCapture instance alive for the duration of
    /// one start_visit hit. iOS' delegate-based auth grant flow needs a
    /// live anchor.
    @State private var locationCapture: FieldLocationCapture?
    /// True when location auth was denied or unavailable on the most
    /// recent capture attempt. Surfaces a small caption beneath Start.
    @State private var locationDenied = false
    /// Pause modal state.
    @State private var showPauseSheet = false
    @State private var pauseReason: FieldPauseReason = .lunch
    @State private var pauseOtherText = ""
    @State private var pauseSubmitting = false
    @State private var pauseValidationError: String?
    /// Live timer that ticks once a second while the workspace is on
    /// screen. The clock face reads from `Date.now` minus `clockInAt`,
    /// minus banked + currently-running pause seconds. Computed on each
    /// tick so background → foreground "just works" — `Date.now` jumps
    /// forward and the next tick paints the new total.
    @State private var nowTick: Date = Date()
    private let lifecycleTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Wave M6 tech notes state

    /// Loaded list of internal tech notes for this visit. Hydrated from
    /// `list_tech_notes` on first appear and after every successful add.
    @State private var techNotes: [HavenFieldTechNote] = []
    /// Composer text. Cleared after a successful add.
    @State private var techNoteComposer: String = ""
    /// True while a tech-note write is in flight. Lets the row render a
    /// spinner without blocking the rest of the workspace view.
    @State private var techNotesSubmitting: Bool = false
    /// Most recent error from the tech notes lane. Surfaces as an inline
    /// banner inside the section card.
    @State private var techNotesError: String?
    /// True after the first list_tech_notes round-trip completes so the
    /// empty state ("No internal notes yet") doesn't flash on first load.
    @State private var techNotesLoaded: Bool = false

    // MARK: Wave M4 kitchen-table close state

    /// True while the BuildQuoteSheet is presented over the visit
    /// workspace. Driven by the "Build quote" CTA on the visit-complete
    /// lifecycle screen.
    @State private var showBuildQuoteSheet = false
    /// Pre-fill payload returned by build_quote_from_visit. Cached so a
    /// second tap on Pre-fill doesn't re-fire the network call.
    @State private var quoteDraftPayload: HavenFieldQuoteDraftPayload?

    // MARK: Wave M5 visit-to-invoice state

    /// True while the BuildInvoiceSheet is presented over the visit
    /// workspace. Driven by the "Build invoice" CTA on the visit-
    /// complete lifecycle screen.
    @State private var showBuildInvoiceSheet = false
    /// Pre-fill payload returned by convert_visit_to_invoice. Cached
    /// so a re-open doesn't re-fire the network call.
    @State private var invoiceDraftPayload: HavenFieldInvoiceDraftPayload?

    // MARK: Wave M9 visit edge cases state

    /// Workspace member roster used by the co-tech picker. Loaded once
    /// per workspace via `fetchWorkspaceMemberDirectory` (the same
    /// helper M7's chat thread sheet uses, kept in one place to avoid
    /// double-fetching).
    @State private var workspaceMemberRoster: [HavenFieldCrewChatMember] = []
    /// True while the co-tech picker sheet is presented.
    @State private var showCoTechPicker = false
    /// True while the access-method sheet is presented.
    @State private var showAccessMethodSheet = false
    /// In-progress access-method draft (one of customer_present, lockbox,
    /// key_under_mat, door_code) + free-form notes for the lockbox
    /// code, key location, etc.
    @State private var accessMethodDraft: String = "customer_present"
    @State private var accessNotesDraft: String = ""
    @State private var accessMethodSubmitting: Bool = false
    @State private var accessMethodError: String?
    /// True while the mid-stream cancel sheet is presented. Shown only
    /// while the visit is in the `.running` lifecycle state.
    @State private var showCancelMidStreamSheet = false
    @State private var cancelReason: FieldCancelReason = .weather
    @State private var cancelOtherText: String = ""
    @State private var cancelScheduleFollowup: Bool = true
    @State private var cancelSubmitting: Bool = false
    @State private var cancelValidationError: String?
    @State private var cancelGenericError: String?
    /// In flight while a co-tech add is round-tripping. Drives row
    /// dimming on the picker sheet without locking out the lifecycle bar.
    @State private var coTechSyncing: Bool = false
    @State private var coTechError: String?

    // MARK: Wave M12 Need part state

    /// True while the part-request sheet is presented at the visit level.
    /// Punch-item-level entry points use a per-row sheet on
    /// FieldPunchItemRow rather than this flag.
    @State private var showPartRequestSheet = false

    // MARK: Wave M8 end-of-visit suggestion authoring state

    /// True after the lifecycle flips into `.completed` for the first
    /// time during this view's lifetime. Drives the "Anything to follow
    /// up on?" wizard sheet so it appears once after Complete lands and
    /// not again on every re-render. The wizard itself owns the dismiss
    /// path; flipping this back to false on dismiss prevents accidental
    /// re-presentation when the user comes back to the visit later.
    @State private var showEndOfVisitWizard: Bool = false
    /// True when the wizard has fired at least once during this view's
    /// lifetime. Belt-and-suspenders so background → foreground (E1
    /// preservation) doesn't pop the wizard a second time after the
    /// user has already worked through it. Persisted per-visit via
    /// AppStorage so a hard kill of the app doesn't re-fire either.
    @State private var endOfVisitWizardShown: Bool = false
    /// True after the wizard finishes saving its suggestions. Drives a
    /// 2-second dashboard banner ("Suggestions sent") so the tech sees
    /// confirmation even though the wizard auto-dismisses.
    @State private var endOfVisitWizardDidComplete: Bool = false
    /// Cached suggestions so background → foreground restores mid-wizard
    /// state. Encoded into AppStorage as JSON; the wizard hydrates from
    /// it on appear and writes through it on every queue mutation.
    @State private var endOfVisitWizardDraftJson: String = ""

    // MARK: - Wave M8 wizard presentation

    /// Per-visit AppStorage key so the wizard fires once per Complete
    /// even across launches. Hard kill mid-wizard? Wizard re-presents.
    /// Hard kill AFTER wizard finished? Wizard does NOT re-present.
    private var endOfVisitWizardShownKey: String {
        "havenfield.m8.wizardShown.\(viewModel.visit.requestId)"
    }

    /// Per-visit AppStorage key for the in-progress wizard draft. Lets
    /// background → foreground (E1) restore the queue, the observation
    /// text, and the chip mode the tech was last in.
    private var endOfVisitWizardDraftKey: String {
        "havenfield.m8.wizardDraft.\(viewModel.visit.requestId)"
    }

    /// Decides whether to present the wizard. Gates on the persisted
    /// "already shown for this visit" flag so re-entering a completed
    /// visit doesn't re-fire it (the tech already sent suggestions, or
    /// already opted out — either way we don't bug them again).
    private func presentEndOfVisitWizardIfNeeded() {
        if endOfVisitWizardShown { return }
        let alreadyShown = UserDefaults.standard.bool(forKey: endOfVisitWizardShownKey)
        if alreadyShown { return }
        endOfVisitWizardShown = true
        UserDefaults.standard.set(true, forKey: endOfVisitWizardShownKey)
        // Hydrate any preserved draft (E1 background → foreground state).
        endOfVisitWizardDraftJson = UserDefaults.standard.string(forKey: endOfVisitWizardDraftKey) ?? ""
        showEndOfVisitWizard = true
    }

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

                lifecycleSection

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
        .navigationTitle(viewModel.visit.title.fieldDisplayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            // Hydrate lifecycle state from the dashboard payload on
            // first appear. If the user backgrounded mid-paused, we'd
            // need to learn about it from the server — best-effort:
            // reload the open pause from PostgREST so the right state
            // resumes when the app re-foregrounds.
            await hydrateLifecycleStateFromServer()
            // Wave M6 — load internal tech notes so the section can
            // paint with real rows on first render. Errors surface
            // inside the section card, not as a global banner.
            await loadTechNotes()
        }
        .onReceive(lifecycleTimer) { tick in
            nowTick = tick
        }
        // Sprint #3 R1-E-7: foreground refresh of lifecycle state.
        // The lifecycleTimer keeps ticking but only updates nowTick;
        // a different device closing the pause via the admin portal,
        // or the SLA flipping while we were backgrounded, won't show
        // up until the user navigates away and back. Re-pull on every
        // .background → .active transition so the displayed state
        // matches server truth on wakeup.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await hydrateLifecycleStateFromServer() }
            }
        }
        // Wave M8 — present the end-of-visit wizard the FIRST time the
        // lifecycle flips into `.completed` during this view's lifetime.
        // Per-visit AppStorage gate (see endOfVisitWizardShownKey) prevents
        // the wizard from re-firing on background → foreground or on a
        // later return to the same visit.
        .onChange(of: lifecycleState) { _, newValue in
            if case .completed = newValue {
                presentEndOfVisitWizardIfNeeded()
            }
        }
        .onAppear {
            // Belt-and-suspenders: if the view re-appears already in the
            // completed state and the wizard hasn't been shown yet,
            // present it. Covers the case where complete_visit landed
            // before this view rendered (background → foreground re-entry
            // after Complete tap).
            if case .completed = lifecycleState {
                presentEndOfVisitWizardIfNeeded()
            }
        }
        // Wave M8 — write through the wizard's draft JSON to per-visit
        // UserDefaults so background → foreground (E1) restores the
        // queue + observation text exactly where the tech left them.
        .onChange(of: endOfVisitWizardDraftJson) { _, newValue in
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: endOfVisitWizardDraftKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: endOfVisitWizardDraftKey)
            }
        }
        .sheet(isPresented: $showPauseSheet) {
            pauseSheet
                .presentationDetents([.medium])
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
        .sheet(isPresented: $showBuildInvoiceSheet) {
            // Wave M5 — visit-to-invoice. Pre-fill labor + materials
            // line items from completed punch items, edit, save / send.
            FieldBuildInvoiceSheet(
                workspaceId: viewModel.workspaceId ?? "",
                requestId: viewModel.visit.requestId,
                visit: viewModel.visit,
                cachedDraft: invoiceDraftPayload,
                onDraftCached: { draft in
                    invoiceDraftPayload = draft
                },
                onClose: {
                    showBuildInvoiceSheet = false
                    NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
                }
            )
        }
        .sheet(isPresented: $showBuildQuoteSheet) {
            // Wave M4 — kitchen-table close. Pre-fill from completed
            // punch items, edit lines, optionally add tiers, capture
            // signature.
            FieldBuildQuoteSheet(
                workspaceId: viewModel.workspaceId ?? "",
                requestId: viewModel.visit.requestId,
                visit: viewModel.visit,
                cachedDraft: quoteDraftPayload,
                onDraftCached: { draft in
                    quoteDraftPayload = draft
                },
                onClose: {
                    showBuildQuoteSheet = false
                    NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
                }
            )
        }
        .sheet(isPresented: $showEndOfVisitWizard) {
            // Wave M8 — end-of-visit suggestion authoring. Drives recurring
            // revenue: the tech proposes a follow-up task, a quote draft
            // (chained into M4's BuildQuoteSheet), or a follow-up visit
            // slot. Auto-presents on the FIRST `.completed` lifecycle
            // transition during this view's lifetime; the wizard owns
            // its own dismiss + persistence.
            FieldEndOfVisitWizard(
                workspaceId: viewModel.workspaceId ?? "",
                requestId: viewModel.visit.requestId,
                visit: viewModel.visit,
                draftJsonBinding: $endOfVisitWizardDraftJson,
                onOpenQuoteDraft: { _ in
                    // Hand off to M4's existing BuildQuoteSheet — the draft
                    // row is already created server-side, so M4 just
                    // re-fetches and the tech edits in place.
                    showEndOfVisitWizard = false
                    showBuildQuoteSheet = true
                },
                onDismiss: { didSave in
                    showEndOfVisitWizard = false
                    if didSave {
                        endOfVisitWizardDidComplete = true
                        // Auto-fade the success banner after 3s.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            endOfVisitWizardDidComplete = false
                        }
                        // Refresh dashboard so the parent visit's queue
                        // reflects the new artifacts.
                        NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
                    }
                }
            )
            .interactiveDismissDisabled(false)
        }
        // Wave M9 — co-tech picker. Workspace-member roster loaded
        // lazily from the existing M7 fetch helper.
        .sheet(isPresented: $showCoTechPicker) {
            FieldCoTechPickerSheet(
                primaryMemberId: resolvedAssignment?.memberId,
                alreadyCoTechIds: resolvedAssignment?.coTechMemberIds ?? [],
                roster: workspaceMemberRoster,
                isLoadingRoster: workspaceMemberRoster.isEmpty && coTechSyncing,
                isSubmitting: coTechSyncing,
                errorMessage: coTechError,
                onSelect: { member in
                    Task { await addCoTech(memberId: member.id) }
                },
                onClose: {
                    showCoTechPicker = false
                    coTechError = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Wave M9 — access method sheet (lockbox / key location /
        // door code).
        .sheet(isPresented: $showAccessMethodSheet) {
            FieldAccessMethodSheet(
                method: $accessMethodDraft,
                notes: $accessNotesDraft,
                isSubmitting: accessMethodSubmitting,
                // N-validation-stale-render fix: pass via Binding so the
                // sheet can clear the message as the user types.
                errorMessage: $accessMethodError,
                onSave: {
                    Task { await saveAccessMethod() }
                },
                onClose: {
                    showAccessMethodSheet = false
                    accessMethodError = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Wave M9 — mid-stream cancellation.
        .sheet(isPresented: $showCancelMidStreamSheet) {
            FieldCancelMidStreamSheet(
                reason: $cancelReason,
                otherText: $cancelOtherText,
                scheduleFollowup: $cancelScheduleFollowup,
                isSubmitting: cancelSubmitting,
                validationError: cancelValidationError,
                genericError: cancelGenericError,
                onSubmit: {
                    Task { await cancelVisitMidStream() }
                },
                onClose: {
                    showCancelMidStreamSheet = false
                    cancelValidationError = nil
                    cancelGenericError = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPartRequestSheet) {
            // Wave M12 — visit-level Need part. requestId set, punchItemId
            // null so the operator knows this is a whole-visit context.
            // Punch-item-level entry points (the wrench chip on each
            // FieldPunchItemRow) present their own sheet with punchItemId
            // pre-set.
            if let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty {
                FieldPartRequestSheet(
                    workspaceId: workspaceId,
                    requestId: viewModel.visit.requestId,
                    punchItemId: nil,
                    contextLabel: visitContextLabel,
                    onCreated: { _ in
                        showPartRequestSheet = false
                    }
                )
                .presentationDetents([.large])
            }
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

    // MARK: - Wave M9 action handlers

    /// Lazy fetch the workspace member roster on first access (when the
    /// co-tech picker opens). Cached for the lifetime of this view.
    private func loadWorkspaceMembersIfNeeded() async {
        guard workspaceMemberRoster.isEmpty,
              let workspaceId = viewModel.workspaceId,
              !workspaceId.isEmpty else { return }
        coTechSyncing = true
        defer { coTechSyncing = false }
        do {
            let members = try await HavenFieldService.shared.fetchWorkspaceMemberDirectory(workspaceId: workspaceId)
            workspaceMemberRoster = members
        } catch {
            coTechError = "Couldn't load workspace members."
            print("[HavenFieldVisitWorkspaceView] loadWorkspaceMembersIfNeeded failed: \(error)")
        }
    }

    private func addCoTech(memberId: String) async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            coTechError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            coTechError = "Visit identifier missing."
            return
        }

        coTechError = nil
        coTechSyncing = true
        defer { coTechSyncing = false }

        do {
            let assignment = try await HavenFieldService.shared.addCoTech(
                workspaceId: workspaceId,
                requestId: requestId,
                memberId: memberId
            )
            lifecycleAssignment = assignment
            // Refresh the parent dashboard so other surfaces (Today
            // tile, Operations Desk via cross-app sync) pick up the
            // change.
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
            // Close the picker on success — leaves the user in the
            // visit detail with the new chip rendered.
            showCoTechPicker = false
        } catch {
            coTechError = friendlyServerError(from: error, fallback: "Couldn't add co-tech.")
        }
    }

    private func saveAccessMethod() async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            accessMethodError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            accessMethodError = "Visit identifier missing."
            return
        }

        let method = FieldAccessMethod(rawValue: accessMethodDraft) ?? .customerPresent
        let trimmedNotes = accessNotesDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        // C1 — every access method that needs notes (lockbox, key,
        // door code) fires a visible validation when notes are empty.
        if method.requiresNotes && trimmedNotes.isEmpty {
            accessMethodError = "Add the \(method.displayLabel.lowercased()) details so the next tech knows."
            return
        }

        accessMethodError = nil
        accessMethodSubmitting = true
        defer { accessMethodSubmitting = false }

        do {
            let assignment = try await HavenFieldService.shared.setAccessMethod(
                workspaceId: workspaceId,
                requestId: requestId,
                method: method.rawValue,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            lifecycleAssignment = assignment
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
            showAccessMethodSheet = false
        } catch {
            accessMethodError = friendlyServerError(from: error, fallback: "Couldn't save access method.")
        }
    }

    private func cancelVisitMidStream() async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            cancelGenericError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            cancelGenericError = "Visit identifier missing."
            return
        }

        // C1 — empty "Other" text fires inline validation. Other reasons
        // submit verbatim.
        let reasonForRecord: String
        if cancelReason == .other {
            let trimmed = cancelOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                cancelValidationError = "Tell the homeowner what happened."
                return
            }
            reasonForRecord = trimmed
        } else {
            reasonForRecord = cancelReason.displayLabel
        }

        cancelValidationError = nil
        cancelGenericError = nil
        cancelSubmitting = true
        defer { cancelSubmitting = false }

        // Default proposed date for the follow-up: tomorrow 9 AM.
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let proposedDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)

        do {
            let result = try await HavenFieldService.shared.cancelVisitMidStream(
                workspaceId: workspaceId,
                requestId: requestId,
                reason: reasonForRecord,
                scheduleFollowup: cancelScheduleFollowup,
                proposedDate: cancelScheduleFollowup ? proposedDate : nil,
                durationMinutes: 60
            )
            // Local lifecycle override — close the running clock state
            // so the UI flips to the cancelled annotation immediately
            // without waiting for the dashboard refresh.
            currentlyPausedAt = nil
            // Refresh the parent dashboard so the cancellation +
            // follow-up land on the Today list.
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
            showCancelMidStreamSheet = false
            print("[HavenFieldVisitWorkspaceView] cancel_visit_mid_stream OK status=\(result.status) followup=\(result.followupRequestId ?? "none")")
        } catch {
            cancelGenericError = friendlyServerError(from: error, fallback: "Couldn't cancel the visit.")
        }
    }

    private var headerCard: some View {
        FieldSectionCard(
            kicker: "Visit",
            title: viewModel.visit.property?.name ?? viewModel.visit.title.fieldDisplayTitle,
            inverse: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                FieldKeyValueRow(label: "Scheduled", value: routeSummary, inverse: true)
                // C-4 fix: route through `displayedStatusLabel` so the
                // local `.completed` lifecycle state wins over the stale
                // payload status when the user just finished the visit.
                FieldKeyValueRow(label: "Status", value: displayedStatusLabel, inverse: true)
                // Wave M6 — address renders as a tappable Apple Maps link.
                // The maps:// URL opens Apple Maps natively on device; the
                // simulator falls back to Maps if installed, otherwise the
                // tap is a graceful no-op.
                if let address = viewModel.visit.property?.address, !address.isEmpty {
                    FieldTappableAddressRow(address: address, inverse: true)
                }
                // N-customer-phone fix: tap-to-call row, served by the
                // workspace dashboard's per-visit `property.customerPhone`
                // field. Resolves to the household's primary
                // family_member phone server-side. Renders only when set
                // so families without a phone on file see a clean header.
                if let phone = viewModel.visit.property?.customerPhone,
                   !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    FieldTappablePhoneRow(phone: phone, inverse: true)
                }
                if let notes = viewModel.visit.assignment?.routeNotes, !notes.isEmpty {
                    FieldKeyValueRow(label: "Route notes", value: notes, inverse: true)
                }

                // Wave M9 — surface lockbox / non-customer-present access
                // method as a salmon-tinted badge in the header (one of
                // the load-bearing salmon usages allowed by Section 22
                // B1 — the tech needs this context BEFORE walking up).
                accessMethodHeaderBadge

                // Wave M9 — mid-stream cancellation annotation. Renders
                // only when the visit was cancelled mid-flight (M9-tagged
                // columns populated, distinct from M5 pre-visit cancel).
                cancelledStateHeaderAnnotation

                Text(viewModel.syncMessage)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.8))

                actionRow
            }
        }
    }

    /// Wave M9 — co-tech roster row + Add CTA. Renders inline in the
    /// lifecycle section card. Empty state explains the value to
    /// invite-curious techs without auto-presenting any UI.
    @ViewBuilder
    private var coTechSection: some View {
        let coTechIds = (resolvedAssignment?.coTechMemberIds ?? [])
        let coTechs: [HavenFieldCrewChatMember] = coTechIds.compactMap { id in
            workspaceMemberRoster.first(where: { $0.id == id })
        }
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                Text("CO-TECH")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Button {
                    Task { await loadWorkspaceMembersIfNeeded() }
                    showCoTechPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14, weight: .semibold))
                        Text(coTechs.isEmpty ? "Add co-tech" : "Add another")
                            .font(HavenTypography.caption.weight(.semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityLabel("Add a co-tech to this visit")
            }

            if coTechs.isEmpty {
                Text("Pair up with another tech to share punch-list check-off.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(coTechs) { member in
                        HStack(spacing: 10) {
                            FieldCoTechAvatar(initials: member.initials)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(HavenTypography.bodySmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(member.role.localizedCapitalized)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            if let coTechError {
                Text(coTechError)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
        .padding(12)
        .background(HavenColors.cream.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Wave M9 — lockbox / access method badge in the dark visit
    /// header. Renders only when a non-default access method was set;
    /// salmon-tinted to stand out against the indigo backdrop.
    @ViewBuilder
    private var accessMethodHeaderBadge: some View {
        let methodRaw = resolvedAssignment?.accessMethod
        let notes = resolvedAssignment?.accessNotes
        if let methodRaw,
           let method = FieldAccessMethod(rawValue: methodRaw),
           method != .customerPresent {
            Button {
                accessMethodDraft = methodRaw
                accessNotesDraft = notes ?? ""
                accessMethodError = nil
                showAccessMethodSheet = true
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: method.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                        .frame(width: 26, height: 26)
                        .background(HavenColors.action.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Access: \(method.displayLabel)")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.textOnNavy)
                        if let notes, !notes.isEmpty {
                            Text(notes)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textOnNavy.opacity(0.85))
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Tap to add lockbox or key details")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                }
                .padding(12)
                .background(HavenColors.action.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HavenColors.action.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .accessibilityLabel("Access method: \(method.displayLabel). Tap to edit.")
        }
    }

    /// Wave M9 — cancelled-state header annotation. Renders only when
    /// the visit was cancelled mid-flight (M9-tagged cancellation_reason
    /// + cancelled_at columns populated). Distinct from the M5 pre-visit
    /// homeowner cancel path.
    @ViewBuilder
    private var cancelledStateHeaderAnnotation: some View {
        if viewModel.visit.status == "cancelled",
           let cancelledAtIso = viewModel.visit.cancelledAt,
           let cancelledAt = parseISODate(cancelledAtIso) {
            let reason = viewModel.visit.cancellationReason ?? ""
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.critical)
                    .frame(width: 26, height: 26)
                    .background(HavenColors.critical.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cancelled mid-visit at \(timeOfDayString(cancelledAt))")
                        .font(HavenTypography.uiLabel.weight(.semibold))
                        .foregroundStyle(HavenColors.textOnNavy)
                    if !reason.isEmpty {
                        Text("Reason: \(reason)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textOnNavy.opacity(0.85))
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(HavenColors.critical.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(HavenColors.critical.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: Wave M1 lifecycle section

    /// Source-of-truth assignment for the lifecycle UI. Local override
    /// (set by start/pause/resume/complete responses) wins; otherwise
    /// fall through to the dashboard payload. Every render reads via
    /// this so the live timer reflects the most recent snapshot.
    private var resolvedAssignment: HavenFieldVisitAssignment? {
        lifecycleAssignment ?? viewModel.visit.assignment
    }

    /// Wave M12 — the kicker displayed at the top of the part-request
    /// sheet so the tech sees what visit they're flagging the part for.
    /// Falls through to the visit title when the home name isn't set.
    private var visitContextLabel: String {
        let homeName = viewModel.home?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let homeName, !homeName.isEmpty {
            return "For: \(homeName)"
        }
        let title = viewModel.visit.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            return "For: \(title)"
        }
        return "For this visit"
    }

    private var lifecycleState: FieldVisitLifecycleState {
        FieldVisitLifecycleState.resolve(
            assignment: resolvedAssignment,
            currentlyPausedAt: currentlyPausedAt
        )
    }

    /// C-4 fix — header card "Status" row label.
    /// When the local `lifecycleState` has flipped to `.completed` (because
    /// the user just tapped Complete or the M8 wizard auto-completed the
    /// visit), the server-side `payload?.request?.statusLabel` is still
    /// stale ("In progress") because the portal payload isn't re-fetched
    /// after a Phase 78 lifecycle action. Derive the displayed label from
    /// the same source-of-truth as `lifecycleSection` so both stay in sync.
    private var displayedStatusLabel: String {
        if case .completed = lifecycleState {
            return HandymanRequestStatus.completed.displayLabel
        }
        return viewModel.statusLabel
    }

    /// C-4 fix — actionRow + header CTA branching.
    /// Same problem as `displayedStatusLabel` — `viewModel.requestStatus`
    /// reads the stale payload even after the visit completed locally.
    /// Once `lifecycleState == .completed`, force-route through the
    /// completed branch so the "Sync now / Complete visit" CTAs disappear.
    private var displayedRequestStatus: String {
        if case .completed = lifecycleState {
            return HandymanRequestStatus.completed.rawValue
        }
        return viewModel.requestStatus
    }

    @ViewBuilder
    private var lifecycleSection: some View {
        FieldSectionCard(kicker: "Visit lifecycle", title: lifecycleHeadline) {
            VStack(alignment: .leading, spacing: 14) {
                // Live elapsed clock — only shown for in-flight states.
                switch lifecycleState {
                case .notStarted:
                    Text("Tap Start to clock in. We'll record the time and stamp your arrival GPS so the homeowner knows you're on-site.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                case .running, .paused:
                    elapsedClockView
                case .completed(let elapsed):
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(HavenColors.success)
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatElapsed(elapsed))
                                .font(HavenTypography.largeTitle)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Total time on-site")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                // Error banner specific to the lifecycle action — does
                // not collide with viewModel.errorMessage.
                if let lifecycleError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HavenColors.action)
                        Text(lifecycleError)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Button("Retry") {
                            self.lifecycleError = nil
                        }
                        .buttonStyle(FieldSecondaryButtonStyle(compact: true))
                    }
                    .padding(12)
                    .background(HavenColors.action.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                lifecycleButtonRow

                // Wave M9 — co-tech section + access tile. Both render
                // for every lifecycle state (techs may want to set
                // access pre-arrival or pair up before clock-in too).
                Divider()
                    .background(HavenColors.border)
                coTechSection
                accessMethodTile

                // Wave M12 — visit-level Need part button. Always
                // available so the tech can flag a part request before,
                // during, or after the lifecycle (sometimes they realize
                // they need a part during the wrap-up walkthrough).
                needPartButton
            }
        }
    }

    /// Wave M12 — visit-level Need part button. Opens the
    /// FieldPartRequestSheet with `requestId` set + null `punchItemId`
    /// so the operator knows this is a whole-visit context.
    @ViewBuilder
    private var needPartButton: some View {
        Button {
            showPartRequestSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.navy700)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Need part")
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Flag a needed part for the operator.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(12)
            .background(HavenColors.cream.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("Need part. Flag a needed part for the operator.")
    }

    /// Wave M9 — access method tile inside the lifecycle section. Tap
    /// opens the same sheet the header badge opens. Renders ALWAYS so
    /// the tech can set access pre-visit (door code captured before
    /// arrival) or edit it post-arrival.
    @ViewBuilder
    private var accessMethodTile: some View {
        let methodRaw = resolvedAssignment?.accessMethod ?? "customer_present"
        let method = FieldAccessMethod(rawValue: methodRaw) ?? .customerPresent
        let notes = resolvedAssignment?.accessNotes
        Button {
            accessMethodDraft = methodRaw
            accessNotesDraft = notes ?? ""
            accessMethodError = nil
            showAccessMethodSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: method.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACCESS METHOD")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text(method == .customerPresent && (notes?.isEmpty ?? true)
                         ? "Customer present (default). Tap to edit."
                         : (method.displayLabel + ((notes?.isEmpty ?? true) ? "" : " • \(notes ?? "")")))
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(12)
            .background(HavenColors.cream.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("Access method: \(method.displayLabel). Tap to change.")
    }

    @ViewBuilder
    private var elapsedClockView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(formatElapsed(elapsedSeconds))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(HavenColors.textPrimary)
                if case .paused = lifecycleState {
                    Text("PAUSED")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.action)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(HavenColors.action.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text(elapsedSubtitle)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    @ViewBuilder
    private var lifecycleButtonRow: some View {
        switch lifecycleState {
        case .notStarted:
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Task { await startLifecycle() }
                } label: {
                    if lifecycleSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(HavenColors.textOnAction)
                            Text("Starting...")
                        }
                    } else {
                        Text("Start visit")
                    }
                }
                .buttonStyle(FieldPrimaryButtonStyle())
                .disabled(lifecycleSyncing || resolvedAssignment == nil)

                if locationDenied {
                    Text("GPS unavailable. Visit start time will be recorded without location.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        case .running:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button("Pause") {
                        pauseReason = .lunch
                        pauseOtherText = ""
                        pauseValidationError = nil
                        showPauseSheet = true
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())
                    .disabled(lifecycleSyncing)

                    Button {
                        Task { await completeLifecycle() }
                    } label: {
                        if lifecycleSyncing {
                            ProgressView().tint(HavenColors.textOnAction)
                        } else {
                            Text("Complete")
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(lifecycleSyncing)
                }

                // Wave M9 — "End visit early" link. Salmon-tinted text
                // (one of the load-bearing salmon usages allowed by
                // Section 22 B1 — clearly destructive action that needs
                // attention) but rendered as a flat text button so it
                // doesn't compete with the primary Complete CTA above.
                Button {
                    cancelReason = .weather
                    cancelOtherText = ""
                    cancelScheduleFollowup = true
                    cancelValidationError = nil
                    cancelGenericError = nil
                    showCancelMidStreamSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.octagon")
                            .font(.system(size: 13, weight: .semibold))
                        Text("End visit early")
                            .font(HavenTypography.caption.weight(.semibold))
                    }
                    .foregroundStyle(HavenColors.action)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .disabled(lifecycleSyncing)
                .accessibilityLabel("End visit early. Opens cancellation reason picker.")
            }
        case .paused:
            HStack(spacing: 10) {
                Button {
                    Task { await resumeLifecycle() }
                } label: {
                    if lifecycleSyncing {
                        ProgressView().tint(HavenColors.textOnAction)
                    } else {
                        Text("Resume")
                    }
                }
                .buttonStyle(FieldPrimaryButtonStyle())
                .disabled(lifecycleSyncing)

                Button {
                    Task { await completeLifecycle() }
                } label: {
                    Text("Complete")
                }
                .buttonStyle(FieldSecondaryButtonStyle())
                .disabled(lifecycleSyncing)
            }
        case .completed:
            // Wave M4 — kitchen-table close. Visit is complete; the
            // primary post-visit action is to build a quote from the
            // punch list and (optionally) capture a customer signature
            // right there at the kitchen table.
            //
            // Wave M5 — once the visit has wrapped, the field tech can
            // also one-tap convert completed punch items into a draft
            // invoice. Pairs with the quote button: quote = future
            // work, invoice = work just finished.
            //
            // Wave M8 — and on top of both, an end-of-visit wizard fires
            // automatically (and is reachable from a secondary CTA) for
            // staging follow-up tasks / quote drafts / next-visit slots.
            VStack(alignment: .leading, spacing: 10) {
                if endOfVisitWizardDidComplete {
                    // Wave M8 — short-lived confirmation banner that
                    // fades after 3s. Reads as "we got your suggestions"
                    // without locking the tech into another modal.
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HavenColors.success)
                        Text("Suggestions sent to the homeowner.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(HavenColors.success.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity)
                }
                Button {
                    showBuildQuoteSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                        Text("Build quote")
                    }
                }
                .buttonStyle(FieldPrimaryButtonStyle())

                Button {
                    showBuildInvoiceSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "scroll.fill")
                        Text("Build invoice")
                    }
                }
                .buttonStyle(FieldSecondaryButtonStyle())

                // Wave M8 — secondary entry point so the tech can
                // re-open the wizard later (or for the first time, if
                // they tapped Skip the first time it appeared). Hidden
                // when the wizard is already on screen so we don't
                // leave a dead button behind it.
                if !showEndOfVisitWizard {
                    Button {
                        // Reset the per-visit gate so the wizard fires
                        // even after a previous Skip/Done. The draft
                        // JSON is also reloaded so the tech picks up
                        // any in-flight suggestions they had open.
                        endOfVisitWizardDraftJson = UserDefaults.standard.string(forKey: endOfVisitWizardDraftKey) ?? ""
                        showEndOfVisitWizard = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                            Text("Send follow-up suggestions")
                        }
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())
                }

                Text("Quote upcoming work or invoice the visit you just finished. Both pre-fill from the punch list.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var pauseSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Why are you pausing?")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    Picker("Reason", selection: $pauseReason) {
                        ForEach(FieldPauseReason.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: pauseReason) { _, _ in
                        pauseValidationError = nil
                    }

                    if pauseReason == .other {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tell the homeowner why")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            // Sprint #3 R1-E-8: switch to multi-line +
                            // 500-char cap. The pre-fix single-line
                            // field scrolled horizontally on long input
                            // with no length indicator and accepted
                            // unbounded paste, which would degrade the
                            // homeowner-facing pause notification copy.
                            // 500 chars is a generous cap that comfortably
                            // fits a paragraph of context without making
                            // the pause notification card unreadable.
                            TextField("e.g. waiting on parts", text: $pauseOtherText, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                // N-validation-stale-render fix: clear
                                // the validation message as soon as the
                                // user starts typing — without this the
                                // "Tell the homeowner why" error stays
                                // on screen even after they've satisfied
                                // it. Mirrors C-3's M3 follow-up pattern.
                                .onChange(of: pauseOtherText) { _, newValue in
                                    // Sprint #3 R1-E-8: 500-char hard cap
                                    // truncates anything pasted past the
                                    // limit. Doing it in onChange means
                                    // the displayed text + the bound state
                                    // both track the truncated value.
                                    if newValue.count > 500 {
                                        pauseOtherText = String(newValue.prefix(500))
                                    }
                                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        pauseValidationError = nil
                                    }
                                }
                            // Length counter so the operator knows when
                            // they're approaching the cap.
                            if pauseOtherText.count > 400 {
                                Text("\(pauseOtherText.count) / 500")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(pauseOtherText.count >= 500 ? HavenColors.critical : HavenColors.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }

                    if let pauseValidationError {
                        Text(pauseValidationError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }

                    Button {
                        Task { await submitPause() }
                    } label: {
                        if pauseSubmitting {
                            HStack(spacing: 8) {
                                ProgressView().tint(HavenColors.textOnAction)
                                Text("Pausing...")
                            }
                        } else {
                            Text("Pause visit")
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(pauseSubmitting)
                }
                .padding(20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Pause")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showPauseSheet = false
                    }
                }
            }
        }
    }

    /// Lifecycle headline — describes what state the visit is in.
    private var lifecycleHeadline: String {
        switch lifecycleState {
        case .notStarted:
            return "Ready when you are"
        case .running:
            return "Visit in progress"
        case .paused:
            return "Visit paused"
        case .completed:
            return "Visit complete"
        }
    }

    private var elapsedSubtitle: String {
        switch lifecycleState {
        case .running(let clockInAt, _):
            return "Started \(timeOfDayString(clockInAt))"
        case .paused(_, _, let pausedAt):
            return "Paused \(timeOfDayString(pausedAt))"
        default:
            return ""
        }
    }

    /// Live elapsed counter in seconds. Reads from `nowTick` so the
    /// view re-renders every second while the workspace is foregrounded.
    /// Background → foreground is naturally handled: when the timer fires
    /// after re-appearing, `Date.now` jumps to the current wall-clock
    /// and the next tick paints the right value.
    private var elapsedSeconds: Int {
        guard let assignment = resolvedAssignment,
              let clockInAtString = assignment.clockInAt,
              let clockInAt = parseISODate(clockInAtString) else {
            return 0
        }

        // Use `nowTick` so SwiftUI re-renders on every timer tick.
        let referenceNow = nowTick
        var elapsed = Int(referenceNow.timeIntervalSince(clockInAt)) - assignment.pausedSeconds
        // While locally paused, the live counter freezes at the moment
        // we entered pause — subtract the unbanked pause window too.
        if let pausedAt = currentlyPausedAt {
            elapsed -= Int(referenceNow.timeIntervalSince(pausedAt))
        }
        return max(0, elapsed)
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func timeOfDayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseISODate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: string) { return parsed }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    /// On view appear, ask the server whether there's an open pause
    /// window for this assignment. Sets `currentlyPausedAt` if so —
    /// otherwise leaves the running clock. Fault tolerant: a network
    /// failure here just keeps whatever state was last known.
    private func hydrateLifecycleStateFromServer() async {
        guard let assignmentId = (resolvedAssignment?.id),
              !assignmentId.isEmpty else { return }
        do {
            let pauses = try await HavenFieldService.shared.fetchOpenPause(assignmentId: assignmentId)
            if let openPause = pauses.first,
               let pausedAtString = openPause.pausedAt,
               let pausedAt = parseISODate(pausedAtString) {
                currentlyPausedAt = pausedAt
            } else {
                currentlyPausedAt = nil
            }
        } catch {
            // Best-effort. Don't bug the user about it.
            print("[HavenFieldVisitWorkspaceView] hydrate pause state failed: \(error)")
        }
    }

    private func startLifecycle() async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            lifecycleError = "Workspace not loaded yet. Try again in a moment."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            lifecycleError = "Visit identifier missing."
            return
        }

        lifecycleError = nil
        lifecycleSyncing = true
        defer { lifecycleSyncing = false }

        // Capture GPS — graceful failure on denied / timeout.
        let capture = FieldLocationCapture()
        locationCapture = capture
        let location: CLLocation? = await withCheckedContinuation { continuation in
            capture.capture { loc in
                continuation.resume(returning: loc)
            }
        }
        locationCapture = nil
        locationDenied = (location == nil)

        do {
            let assignment = try await HavenFieldService.shared.startVisit(
                workspaceId: workspaceId,
                requestId: requestId,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude,
                accuracy: location?.horizontalAccuracy
            )
            lifecycleAssignment = assignment
            currentlyPausedAt = nil
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            lifecycleError = friendlyServerError(from: error, fallback: "Couldn't start the visit. Tap Retry to dismiss this message and try again.")
        }
    }

    private func submitPause() async {
        if pauseReason == .other {
            let trimmed = pauseOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                pauseValidationError = "Tell the homeowner why."
                return
            }
        }
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            pauseValidationError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            pauseValidationError = "Visit identifier missing."
            return
        }

        let reasonText: String = (pauseReason == .other)
            ? pauseOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            : pauseReason.rawValue

        pauseValidationError = nil
        pauseSubmitting = true
        defer { pauseSubmitting = false }

        do {
            try await HavenFieldService.shared.pauseVisit(
                workspaceId: workspaceId,
                requestId: requestId,
                reason: reasonText
            )
            currentlyPausedAt = Date()
            showPauseSheet = false
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            pauseValidationError = friendlyServerError(from: error, fallback: "Couldn't pause the visit. Try again.")
        }
    }

    private func resumeLifecycle() async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            lifecycleError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            lifecycleError = "Visit identifier missing."
            return
        }

        lifecycleError = nil
        lifecycleSyncing = true
        defer { lifecycleSyncing = false }

        do {
            let assignment = try await HavenFieldService.shared.resumeVisit(
                workspaceId: workspaceId,
                requestId: requestId
            )
            lifecycleAssignment = assignment
            currentlyPausedAt = nil
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            lifecycleError = friendlyServerError(from: error, fallback: "Couldn't resume the visit. Tap Retry and try again.")
        }
    }

    private func completeLifecycle() async {
        guard let workspaceId = viewModel.workspaceId, !workspaceId.isEmpty else {
            lifecycleError = "Workspace not loaded yet."
            return
        }
        let requestId = viewModel.visit.requestId
        guard !requestId.isEmpty else {
            lifecycleError = "Visit identifier missing."
            return
        }

        lifecycleError = nil
        lifecycleSyncing = true
        defer { lifecycleSyncing = false }

        do {
            let result = try await HavenFieldService.shared.completeVisit(
                workspaceId: workspaceId,
                requestId: requestId
            )
            lifecycleAssignment = result.assignment
            currentlyPausedAt = nil
            await viewModel.onCoordinated?()
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            lifecycleError = friendlyServerError(from: error, fallback: "Couldn't complete the visit. Tap Retry and try again.")
        }
    }

    // MARK: Wave M6 tech notes

    /// Loads the workspace-only notes for this visit. Called from the
    /// view's `.task` modifier so the section paints with real rows on
    /// first appear.
    private func loadTechNotes() async {
        guard let workspaceId = viewModel.workspaceId else {
            techNotesLoaded = true
            return
        }
        do {
            let result = try await HavenFieldService.shared.listTechNotes(
                workspaceId: workspaceId,
                requestId: viewModel.visit.requestId
            )
            techNotes = result
            techNotesLoaded = true
            techNotesError = nil
        } catch {
            techNotesError = friendlyServerError(
                from: error,
                fallback: "Couldn't load internal notes. Pull to refresh."
            )
            techNotesLoaded = true
        }
    }

    /// Submits the composer text as an internal note. Optimistic-append
    /// would race with the server-side timestamp; instead we wait for
    /// the inserted row to come back and append that, so author + ts
    /// stay canonical.
    private func submitTechNote() async {
        let trimmed = techNoteComposer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !techNotesSubmitting else { return }
        guard let workspaceId = viewModel.workspaceId else {
            techNotesError = "Workspace not loaded yet. Try again in a moment."
            return
        }
        techNotesSubmitting = true
        defer { techNotesSubmitting = false }
        do {
            let inserted = try await HavenFieldService.shared.addTechNote(
                workspaceId: workspaceId,
                requestId: viewModel.visit.requestId,
                body: trimmed
            )
            techNotes.append(inserted)
            techNoteComposer = ""
            techNotesError = nil
            // N-7 fix: post the visit-changed notification so the
            // dashboard's denormalized techNotesCount + the visits-list
            // pill refresh on tab back-nav. Without this, the list
            // shows stale "2 notes" until a full tab switch.
            NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        } catch {
            techNotesError = friendlyServerError(
                from: error,
                fallback: "Couldn't save the note. Tap Add to retry."
            )
        }
    }

    private static let techNoteRelativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private func techNoteRelativeTime(_ iso: String?) -> String {
        guard let iso else { return "Just now" }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: iso) {
            return Self.techNoteRelativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        parser.formatOptions = [.withInternetDateTime]
        if let date = parser.date(from: iso) {
            return Self.techNoteRelativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return "Just now"
    }

    @ViewBuilder
    private var techNotesSection: some View {
        FieldSectionCard(kicker: "Internal", title: "Notes for the crew") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workspace-only. The homeowner never sees these.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)

                // Composer at the top so a tech can append context fast.
                VStack(alignment: .leading, spacing: 8) {
                    TextField(
                        "e.g. \"Customer prefers side door access.\"",
                        text: $techNoteComposer,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(12)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    HStack(spacing: 10) {
                        Spacer()
                        Button {
                            Task { await submitTechNote() }
                        } label: {
                            Text(techNotesSubmitting ? "Adding..." : "Add internal note")
                        }
                        .buttonStyle(FieldPrimaryButtonStyle())
                        .disabled(techNotesSubmitting || techNoteComposer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if let error = techNotesError {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // List below, sorted oldest first so the most recent
                // context lands at the bottom (chat convention).
                if techNotesLoaded && techNotes.isEmpty {
                    Text("No internal notes yet. Add the first.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.vertical, 6)
                } else if !techNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(techNotes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(HavenColors.textSecondary)
                                    Text(note.authorName)
                                        .font(HavenTypography.uiLabelSmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer(minLength: 6)
                                    Text(techNoteRelativeTime(note.createdAt))
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                Text(note.body)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
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
            } else if displayedRequestStatus == HandymanRequestStatus.confirmed.rawValue {
                HStack(spacing: 10) {
                    Button("On my way") {
                        Task { await viewModel.markOnMyWay() }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())

                    // Wave M6 — in-truck reschedule. Confirmed visits
                    // sometimes need to slip; the tech can propose a new
                    // window from the truck without calling dispatch.
                    Button("Reschedule") {
                        rescheduleDate = defaultRescheduleDate
                        showRescheduleSheet = true
                    }
                    .buttonStyle(FieldSecondaryButtonStyle())
                    .disabled(viewModel.isSyncing)
                }
            } else if displayedRequestStatus == HandymanRequestStatus.onMyWay.rawValue {
                Button("Check in") {
                    Task { await viewModel.checkIn() }
                }
                .buttonStyle(FieldPrimaryButtonStyle())
            } else if case .completed = lifecycleState {
                // C-4 fix: once the local lifecycle says completed, hide
                // the Sync now / Complete visit duo entirely. The lifecycle
                // section card already shows the green "Visit complete"
                // marker so we don't need a redundant CTA here. Without
                // this branch the user kept seeing "Complete visit" on a
                // visit they just finished.
                EmptyView()
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
                    // N-4 fix: "1 items" → "1 item".
                    FieldKeyValueRow(
                        label: "Open work",
                        value: {
                            let count = viewModel.home?.openTasks.count ?? 0
                            return "\(count) \(count == 1 ? "item" : "items")"
                        }()
                    )
                    if let homeownerNotes = viewModel.payload?.session.seedPayload.homeownerNotes, !homeownerNotes.isEmpty {
                        FieldKeyValueRow(label: "Homeowner note", value: homeownerNotes)
                    }
                    if let home = viewModel.home {
                        NavigationLink {
                            HavenFieldHomeProfileView(home: home, workspaceId: viewModel.workspaceId)
                        } label: {
                            Text("Open home profile")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.action)
                        }
                    }
                }
            }

            // Wave M6 — internal tech notes. Workspace-only, hidden
            // from homeowner. Composer at top, list below sorted oldest
            // first so the most recent context lands at the bottom.
            techNotesSection

            FieldSectionCard(kicker: "Recent", title: "Visits at this home") {
                if let recentVisits = viewModel.home?.recentVisits, !recentVisits.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(recentVisits) { visit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.title.fieldDisplayTitle)
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
                                            workspaceId: viewModel.workspaceId,
                                            onToggleDone: { Task { await togglePunchItem(item) } },
                                            onItemUpdated: { _ in
                                                // Wave M2 — capture-depth saves are
                                                // optimistic at the row level. Refresh
                                                // the dashboard so other surfaces (the
                                                // contractor desk + homeowner iOS) pick
                                                // up the change on next render.
                                                NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
                                            }
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
        // N-1 fix + N-5 separator fix: render times as "10:00 AM" not
        // "10:00:00", and use the canonical " · " middle dot separator.
        let window = [viewModel.visit.assignment?.windowStartTime, viewModel.visit.assignment?.windowEndTime]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .map { $0.fieldShortTime }
            .joined(separator: " to ")
        return [date, window.isEmpty ? nil : window].compactMap { $0 }.joined(separator: " · ").nonEmpty ?? "TBD"
    }
}

private struct HavenFieldHomeProfileView: View {
    let home: HavenFieldHome
    /// Wave M3 — optional workspace context for system inventory writes.
    /// Pass through from every entry point that has dashboard context;
    /// nil-safe so legacy thread-header navigation still compiles when
    /// the workspace isn't directly available.
    var workspaceId: String? = nil
    @State private var selectedTab: HomeProfileTab = .home
    @State private var selectedSystem: HavenFieldHomeSystem?
    /// Wave M3 — locally edited copy of the home's systems so inventory
    /// writes (decommission, follow-up flag, voice memo) re-render
    /// immediately without a dashboard refresh round-trip. Seeded from
    /// the home prop on appear; subsequent writes update entries inline
    /// via replaceSystem(_:).
    @State private var systems: [HavenFieldHomeSystem] = []
    @State private var showSystemSweep: Bool = false
    @State private var pendingDecommission: HavenFieldHomeSystem?
    @State private var pendingFollowup: HavenFieldHomeSystem?
    @State private var inFlightSystemId: String?
    @State private var systemBanner: String?
    @State private var systemBannerKind: SystemBannerKind = .info
    @State private var bulkAddedThisVisit: Int = 0
    /// T2.5 (post-overnight) — Add vendor flow state.
    @State private var showAddVendor = false
    @State private var capturedVendors: [HavenFieldHomeVendor] = []

    enum HomeProfileTab: String, CaseIterable {
        case home = "Home"
        case systems = "Systems"
        // T3.1 + T3.2 (post-overnight) — recurring services + vendors
        // surfaces. Read-only for now; write affordances land with T2.5
        // (Add vendor sheet) and T2.6 (RoutineCaptureSheet).
        case routines = "Routines"
        case vendors = "Vendors"
        case files = "Files"
    }

    enum SystemBannerKind { case info, success, error }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Home profile", selection: $selectedTab) {
                    ForEach(HomeProfileTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if let banner = systemBanner {
                    systemBannerCard(banner: banner)
                }

                switch selectedTab {
                case .home:
                    homeTab
                case .systems:
                    systemsTab
                case .routines:
                    routinesTab
                case .vendors:
                    vendorsTab
                case .files:
                    filesTab
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            // Sprint #4 R4-E-5 fix: bottom padding so the last task /
            // system row isn't clipped by the floating tab bar pill
            // when the section content overflows the visible viewport.
            // Pre-fix users couldn't reach the 5th task row in the
            // home detail "Tasks Chez sees" section because it sat
            // beneath the bottom tab bar with no scroll affordance.
            .padding(.bottom, 140)
        }
        .background(HavenColors.cream.ignoresSafeArea())
        .navigationTitle(home.name)
        .task {
            if systems.isEmpty {
                systems = home.systems
            }
        }
        .sheet(item: $selectedSystem) { system in
            HavenFieldHomeSystemDetailSheet(
                system: system,
                workspaceId: workspaceId,
                onChanged: { updated in replaceSystem(updated) },
                onMarkFollowup: { pendingFollowup = system },
                onDecommission: { pendingDecommission = system }
            )
        }
        .sheet(isPresented: $showSystemSweep) {
            HavenFieldSystemSweepSheet(
                home: home,
                workspaceId: workspaceId,
                bulkAddedCount: $bulkAddedThisVisit,
                onSystemCreated: { created in
                    systems.append(created)
                    setBanner("\(created.name) added to home", kind: .success)
                }
            )
        }
        .sheet(item: $pendingDecommission) { system in
            HavenFieldDecommissionSheet(system: system) { reason in
                Task { await runDecommission(system: system, reason: reason) }
            }
        }
        .sheet(item: $pendingFollowup) { system in
            HavenFieldFollowupSheet(system: system) { reason in
                Task { await runFollowup(system: system, reason: reason) }
            }
        }
    }

    private func systemBannerCard(banner: String) -> some View {
        let bgColor: Color
        switch systemBannerKind {
        case .info: bgColor = HavenColors.action.opacity(0.10)
        case .success: bgColor = HavenColors.success.opacity(0.12)
        case .error: bgColor = HavenColors.critical.opacity(0.10)
        }
        return Text(banner)
            .font(HavenTypography.caption)
            .foregroundStyle(HavenColors.textPrimary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.opacity)
    }

    private func setBanner(_ message: String, kind: SystemBannerKind, autoDismissAfter seconds: Double = 3.0) {
        withAnimation(.easeOut(duration: 0.2)) {
            systemBanner = message
            systemBannerKind = kind
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if systemBanner == message {
                withAnimation { systemBanner = nil }
            }
        }
    }

    private func replaceSystem(_ updated: HavenFieldHomeSystem) {
        if let index = systems.firstIndex(where: { $0.id == updated.id }) {
            systems[index] = updated
        }
    }

    private func runDecommission(system: HavenFieldHomeSystem, reason: String) async {
        guard let workspaceId, !workspaceId.isEmpty else {
            setBanner("Sign in to your workspace before editing systems.", kind: .error)
            return
        }
        inFlightSystemId = system.id
        defer { inFlightSystemId = nil }
        do {
            if let updated = try await HavenFieldService.shared.decommissionSystem(
                workspaceId: workspaceId,
                systemId: system.id,
                reason: reason
            ) {
                replaceSystem(updated)
                setBanner("\(system.name) marked as removed", kind: .success)
            } else {
                setBanner("\(system.name) marked as removed", kind: .success)
            }
        } catch {
            setBanner("Couldn't mark \(system.name) as removed. Please try again.", kind: .error)
        }
    }

    private func runFollowup(system: HavenFieldHomeSystem, reason: String) async {
        guard let workspaceId, !workspaceId.isEmpty else {
            setBanner("Sign in to your workspace before editing systems.", kind: .error)
            return
        }
        inFlightSystemId = system.id
        defer { inFlightSystemId = nil }
        do {
            if let updated = try await HavenFieldService.shared.markSystemFollowup(
                workspaceId: workspaceId,
                systemId: system.id,
                reason: reason.isEmpty ? nil : reason
            ) {
                replaceSystem(updated)
                setBanner("\(system.name) flagged for follow-up", kind: .info)
            }
        } catch {
            setBanner("Couldn't flag \(system.name) for follow-up.", kind: .error)
        }
    }

    private var visibleSystems: [HavenFieldHomeSystem] {
        systems.isEmpty ? home.systems : systems
    }

    private var incompleteSystems: [HavenFieldHomeSystem] {
        visibleSystems.filter { !$0.isDecommissioned && $0.hasIncompleteIdentity }
    }

    /// N-6 fix — Known systems list excludes anything already surfaced
    /// in the gap-fill list above so the same row never appears twice.
    /// Gap-fill is the "TODO" surface; Known systems is the complete
    /// inventory of systems that have model/serial/manufacturer set. A
    /// system without those fields belongs in gap-fill OR known systems,
    /// not both.
    private var knownSystems: [HavenFieldHomeSystem] {
        let incompleteIds = Set(incompleteSystems.map(\.id))
        return visibleSystems.filter { !incompleteIds.contains($0.id) }
    }

    private var followupSystems: [HavenFieldHomeSystem] {
        visibleSystems.filter { $0.needsFollowup && !$0.isDecommissioned }
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

            // T3.5 (post-overnight) — homeowner standing instructions.
            // Sourced from `households.chez_profile` JSONB. Renders only
            // when the homeowner has actually configured something —
            // empty profiles don't surface a useless "no instructions
            // yet" card. Saves the handyman from re-asking 'do you
            // prefer email or text?', 'is there anything I should know
            // about pets?'. Critical for HNW estates where the
            // entry_instructions field carries gate codes and dog
            // warnings the handyman MUST see before knocking.
            if let chezProfile = home.chezProfile, !chezProfile.isEmpty {
                chezProfileCard(profile: chezProfile)
            }

            FieldSectionCard(kicker: "Recent", title: "Visits at this home") {
                if home.recentVisits.isEmpty {
                    FieldEmptyState(title: "No visit history yet", subtitle: "Completed and upcoming visits will show up here as the relationship builds.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(home.recentVisits) { visit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.title.fieldDisplayTitle)
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
        VStack(alignment: .leading, spacing: 18) {
            // Wave M3 — sweep entry. Always visible at the top so a tech
            // can capture a fresh system in two taps regardless of how
            // many systems are already on file.
            FieldSectionCard(kicker: "System sweep", title: "Capture a system") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Snap a model plate; we'll extract the brand, model, and serial automatically. The homeowner sees every save when the visit closes.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    if bulkAddedThisVisit > 0 {
                        Text("\(bulkAddedThisVisit) system\(bulkAddedThisVisit == 1 ? "" : "s") added in this visit")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.success)
                            .padding(.bottom, 2)
                    }
                    Button {
                        showSystemSweep = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                            Text("Open sweep mode")
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(workspaceId == nil)
                    if workspaceId == nil {
                        Text("Sweep mode is only available from your active visit.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            // Wave M3 — incomplete-systems gap-fill list. Each tap opens
            // the sweep with the existing systemId so the extraction
            // patches the row instead of creating a new one.
            if !incompleteSystems.isEmpty {
                FieldSectionCard(
                    kicker: "Gap-fill",
                    title: "\(incompleteSystems.count) system\(incompleteSystems.count == 1 ? "" : "s") missing details"
                ) {
                    VStack(spacing: 12) {
                        ForEach(incompleteSystems) { system in
                            Button {
                                selectedSystem = system
                            } label: {
                                FieldM3SystemRow(
                                    system: system,
                                    showFollowupBadge: false,
                                    showRemovedBadge: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            FieldSectionCard(kicker: "Systems", title: "Known systems") {
                // N-6 fix: render `knownSystems` (visible minus incomplete)
                // so the same AC / Roof row that already shows in the
                // GAP-FILL section above doesn't show up here too.
                if knownSystems.isEmpty {
                    if !incompleteSystems.isEmpty {
                        // All systems are incomplete — gap-fill handled
                        // them, so this section gets a different empty
                        // copy than the totally-empty case.
                        FieldEmptyState(
                            title: "Every system needs details",
                            subtitle: "Tap a row in Gap-fill to capture model + serial. Once enough fields are populated they'll graduate into Known systems."
                        )
                    } else {
                        FieldEmptyState(
                            title: "No systems shared yet",
                            subtitle: "Once the homeowner grants access and the first visit captures labels, systems will appear here."
                        )
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(knownSystems) { system in
                            Button {
                                selectedSystem = system
                            } label: {
                                FieldM3SystemRow(
                                    system: system,
                                    showFollowupBadge: system.needsFollowup,
                                    showRemovedBadge: system.isDecommissioned
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    pendingDecommission = system
                                } label: {
                                    Label("Mark as removed", systemImage: "trash")
                                }
                                Button {
                                    pendingFollowup = system
                                } label: {
                                    Label("Flag for follow-up", systemImage: "flag")
                                }
                            }
                        }
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

    /// T3.1 (post-overnight) — read-only Routines surface. Sourced
    /// from the homeowner's `routines` table via the dashboard payload.
    /// Write affordances (create / edit) land with T2.6
    /// RoutineCaptureSheet in Phase C.
    private var routinesTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            FieldSectionCard(kicker: "Routines", title: "Recurring services on file") {
                if home.routines.isEmpty {
                    FieldEmptyState(
                        title: "No routines yet",
                        subtitle: "Recurring services like lawn care, cleaning, pest control, or pool service will show up here once captured."
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(home.routines) { routine in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: routineIcon(for: routine.kind))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(HavenColors.navy700)
                                    .frame(width: 22, alignment: .leading)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(routine.label)
                                            .font(HavenTypography.headline)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if routine.chezOwned {
                                            Text("CHEZ")
                                                .font(.system(size: 9, weight: .heavy))
                                                .tracking(0.6)
                                                .foregroundStyle(HavenColors.action)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HavenColors.action.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                        if routine.paused {
                                            Text("PAUSED")
                                                .font(.system(size: 9, weight: .heavy))
                                                .tracking(0.6)
                                                .foregroundStyle(HavenColors.warning)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HavenColors.warning.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                        Spacer()
                                    }
                                    if !routine.summary.isEmpty {
                                        Text(routine.summary)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
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

    /// T3.2 (post-overnight) — Vendors surface. Sourced from the
    /// homeowner's `contractors` table. Mirror of the homeowner-side
    /// contractors list. Each row exposes tap-to-call / tap-to-email.
    /// T2.5 (post-overnight) — write affordance: "+ Add vendor" CTA
    /// at the top of the section opens HavenFieldAddVendorSheet.
    private var vendorsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // T2.5 — capture button. Only visible when we know the
            // workspace + household, since the server enforces both
            // for create_contractor_from_card.
            if let workspaceId, let householdId = home.householdId, !householdId.isEmpty {
                Button {
                    showAddVendor = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add a vendor")
                            .font(HavenTypography.uiButton)
                        Spacer()
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            FieldSectionCard(kicker: "Vendors", title: "Who the homeowner uses") {
                if home.vendors.isEmpty && capturedVendors.isEmpty {
                    FieldEmptyState(
                        title: "No vendors on file",
                        subtitle: "Plumbers, electricians, landscapers — the homeowner's roster will show up here once captured during an assessment."
                    )
                } else {
                    VStack(spacing: 10) {
                        // T2.5 — show just-added vendors at top so the
                        // user gets immediate confirmation without
                        // waiting for a dashboard refresh round-trip.
                        ForEach(capturedVendors) { vendor in
                            vendorRow(vendor)
                        }
                        ForEach(home.vendors) { vendor in
                            vendorRow(vendor)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddVendor) {
            if let workspaceId, let householdId = home.householdId {
                HavenFieldAddVendorSheet(
                    workspaceId: workspaceId,
                    householdId: householdId,
                    onCreated: { newVendor in
                        // Optimistic local add — survives until next
                        // dashboard refresh, then the server-sourced
                        // entry takes over.
                        capturedVendors.insert(newVendor, at: 0)
                        showAddVendor = false
                    }
                )
            }
        }
    }

    /// T2.5 (post-overnight) — extracted vendor row body so both the
    /// just-added (`capturedVendors`) array and the server-sourced
    /// (`home.vendors`) array can use the same renderer.
    @ViewBuilder
    private func vendorRow(_ vendor: HavenFieldHomeVendor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(vendor.companyName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                if vendor.chezOwned {
                    Text("CHEZ")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.6)
                        .foregroundStyle(HavenColors.action)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.action.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            if let category = vendor.category?.nonEmpty {
                Text(category.capitalized)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            if let contact = vendor.contactName?.nonEmpty {
                Text("Contact: \(contact)")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            HStack(spacing: 14) {
                if let phone = vendor.phone?.nonEmpty,
                   let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: url) {
                        Label(phone, systemImage: "phone.fill")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
                if let email = vendor.email?.nonEmpty,
                   let url = URL(string: "mailto:\(email)") {
                    Link(destination: url) {
                        Label(email, systemImage: "envelope.fill")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
            if let website = vendor.website?.nonEmpty,
               let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                Link(destination: url) {
                    Label(website, systemImage: "safari.fill")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func routineIcon(for kind: String?) -> String {
        switch (kind ?? "").lowercased() {
        case let k where k.contains("lawn") || k.contains("landscap"):
            return "leaf.fill"
        case let k where k.contains("clean"):
            return "sparkles"
        case let k where k.contains("pool") || k.contains("spa"):
            return "drop.fill"
        case let k where k.contains("snow"):
            return "snowflake"
        case let k where k.contains("pest") || k.contains("mosquito") || k.contains("tick"):
            return "ladybug.fill"
        case let k where k.contains("trash") || k.contains("recycl") || k.contains("waste"):
            return "trash.fill"
        case let k where k.contains("pet"):
            return "pawprint.fill"
        case let k where k.contains("hvac"):
            return "fan.fill"
        case let k where k.contains("handyman"):
            return "hammer.fill"
        default:
            return "calendar.circle.fill"
        }
    }

    /// T3.5 (post-overnight) — homeowner standing instructions read-only
    /// card. Surfaces the contractor-relevant subset of `chez_profile`
    /// JSONB sent by the server. Most important field is the entry-
    /// instructions string (gate codes, lockbox codes, dog warnings) —
    /// HNW handymen need to see this BEFORE they knock.
    @ViewBuilder
    private func chezProfileCard(profile: HavenFieldChezProfile) -> some View {
        FieldSectionCard(kicker: "Standing instructions", title: "What the homeowner wants you to know") {
            VStack(alignment: .leading, spacing: 14) {
                if let logistics = profile.logistics {
                    if let entry = logistics.entryInstructions?.nonEmpty {
                        chezProfileBlock(
                            icon: "key.fill",
                            label: "Entry",
                            body: entry,
                            tint: HavenColors.action
                        )
                    }
                    if let pets = logistics.pets?.nonEmpty {
                        chezProfileBlock(
                            icon: "pawprint.fill",
                            label: "Pets",
                            body: pets,
                            tint: HavenColors.warning
                        )
                    }
                }
                if let vp = profile.vendorPreferences {
                    if let bo = vp.budgetOrientation?.nonEmpty {
                        chezProfileBlock(
                            icon: "dollarsign.circle",
                            label: "Budget posture",
                            body: bo.capitalized,
                            tint: HavenColors.navy700
                        )
                    }
                    if let local = vp.preferLocalOwned, local {
                        chezProfileBlock(
                            icon: "mappin.and.ellipse",
                            label: "Vendor preference",
                            body: "Prefers local-owned vendors when possible.",
                            tint: HavenColors.navy700
                        )
                    }
                    if let notes = vp.notes?.nonEmpty {
                        chezProfileBlock(
                            icon: "note.text",
                            label: "Vendor notes",
                            body: notes,
                            tint: HavenColors.navy700
                        )
                    }
                }
                if let st = profile.spendingTiers {
                    let summary = chezProfileSpendingSummary(st)
                    if !summary.isEmpty {
                        chezProfileBlock(
                            icon: "checkmark.shield.fill",
                            label: "Spending authority",
                            body: summary,
                            tint: HavenColors.success
                        )
                    }
                }
            }
        }
    }

    private func chezProfileBlock(
        icon: String,
        label: String,
        body: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, alignment: .leading)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(HavenTypography.uiLabelSmall)
                    .kerning(0.6)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(body)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func chezProfileSpendingSummary(_ st: HavenFieldChezProfile.SpendingTiers) -> String {
        var parts: [String] = []
        if let auto = st.autoApproveUnder {
            parts.append("Auto-approve under $\(Int(auto))")
        }
        if let ping = st.pingUnder {
            parts.append("Ping for approval under $\(Int(ping))")
        }
        if let explicit = st.explicitAbove {
            parts.append("Explicit approval above $\(Int(explicit))")
        }
        return parts.joined(separator: ". ")
    }
}

private struct HavenFieldMessageThreadView: View {
    let thread: HavenFieldMessageThread
    let workspaceId: String?
    let relatedVisit: HavenFieldVisit?
    let relatedHome: HavenFieldHome?
    /// Optional reference to the parent HavenFieldViewModel so the thread
    /// can hide the floating bottom tab bar while it owns the screen — its
    /// own bottom composer needs the safe-area room. Wave 4 found that the
    /// Wave 1b `.toolbar(.hidden, for:.tabBar)` only suppressed SwiftUI's
    /// default tab bar, not the field app's custom safe-area-inset bar.
    var rootViewModel: HavenFieldViewModel? = nil
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
        // the bar overlaps the message composer so the Send affordance is
        // clipped. Wave 1b's `.toolbar(.hidden, for:.tabBar)` doesn't
        // affect the safe-area-inset custom bar; flipping the parent
        // viewModel's bottomTabBarHidden flag does.
        .toolbar(.hidden, for: .tabBar)
        .onAppear { rootViewModel?.bottomTabBarHidden = true }
        .onDisappear { rootViewModel?.bottomTabBarHidden = false }
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
                        HavenFieldHomeProfileView(home: relatedHome, workspaceId: workspaceId)
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
                            Text("Code: \(request.accessCode ?? "Not generated")")
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
    /// Sprint #3 R3-E-4: solo workspaces (single active member) hide
    /// the Crew tab. The TabView in HavenFieldRootView gates on the
    /// same flag so taps via the system tab bar can't sneak in either.
    /// Default true for backward compat with any other call sites.
    var showCrewTab: Bool = true

    var body: some View {
        // Wave M7 — five-tab bar (was four pre-M7). The new "Crew"
        // affordance sits between Visits and Homes so route-day
        // coordination chats live next to the dispatch surface.
        // Spacing tightened from 10pt to 6pt to keep all five
        // pills inside the capsule on iPhone SE viewports.
        // Sprint #3 R3-E-4: when Crew is hidden the bar collapses to
        // four pills with the original spacing, which sits comfortably
        // on every iPhone width.
        HStack(spacing: showCrewTab ? 6 : 10) {
            tabButton(tab: .home, icon: "square.grid.2x2.fill", label: "Overview")
            tabButton(tab: .visits, icon: "calendar.badge.clock", label: "Visits")
            if showCrewTab {
                tabButton(tab: .crew, icon: "person.2.wave.2.fill", label: "Crew")
            }
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
                    // Bugfix Sprint #5 R6 hit-target — visible chrome stays
                    // 36×36 (intentional design density) but the tappable
                    // hit target meets WCAG 2.5.5 / Apple HIG 44pt minimum.
                    // .contentShape inside .frame keeps the visual tile
                    // sized while expanding the actual touch area.
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var companyInitials: String {
        let words = companyName.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "CF" : initials.uppercased()
    }
}

/// Wave M6 — route summary card on the Home tab. Shows the day's
/// stops + drive time + rough mileage so the tech can size up the
/// load at a glance. Drive time is currently a stub (15 min between
/// stops + 10 min initial leg); a future wave will replace it with a
/// real routing-engine call. Marked in the JSON as a stub.
private struct FieldRouteSummaryCard: View {
    let stops: Int
    let driveMinutes: Int
    let estimatedMiles: Int

    private var driveTimeLabel: String {
        let h = driveMinutes / 60
        let m = driveMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m drive time" }
        if h > 0 { return "\(h)h drive time" }
        return "\(m)m drive time"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "map.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 40, height: 40)
                .background(HavenColors.action.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text("ROUTE")
                    .font(HavenTypography.uiSectionHeader)
                    .kerning(1)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("\(stops) stop\(stops == 1 ? "" : "s")  ·  \(estimatedMiles) miles")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(driveTimeLabel + " (estimated)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Wave M11 — End of Day view
//
// Operational closure for the field tech. Renders today's totals (stops,
// hours, revenue, materials), the per-stop list (each tappable to the
// invoice if there is one), a tomorrow preview, and a "Sign off" CTA
// that just dismisses with a toast — no DB write yet (future timekeeping
// hook).

private struct FieldEndOfDayView: View {
    let workspaceId: String?

    @Environment(\.dismiss) private var dismiss
    @State private var summary: HavenFieldDaySummary?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var signedOff = false

    private var weekdayLabel: String {
        guard let summary, !summary.today.date.isEmpty,
              let date = DateFormatter.havenISODate.date(from: summary.today.date) else {
            return Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    /// Pretty H:MM:SS from total minutes. 6h 12m for 372 min, 47m for
    /// short days. Caps the "h" segment when zero.
    private static func formatClockMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    /// Compact currency for the hero strip + per-stop badges. Uses the
    /// device locale's currency code; integer cents in, $1,247 out.
    private static func formatCents(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: dollars)) ?? "$\(Int(dollars))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 80)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let summary {
                        heroCard(summary: summary)
                        stopsCard(summary: summary)
                        if summary.today.materialsCostCents > 0 {
                            materialsLine(summary: summary)
                        }
                        tomorrowCard(summary: summary)
                        signOffCTA
                    } else if let errorMessage {
                        FieldErrorBanner(message: errorMessage)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 60)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("End of day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.action)
                }
            }
            .overlay(alignment: .bottom) {
                if signedOff {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("See you tomorrow")
                            .font(HavenTypography.uiLabel)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .background(HavenColors.navy900)
                    .clipShape(Capsule())
                    .shadow(color: HavenColors.navy900.opacity(0.25), radius: 14, x: 0, y: 6)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                await load()
            }
        }
    }

    // Indigo gradient hero — "Day complete · 4 stops · 6h 12m · $1,247
    // invoiced". One serif headline + a body sub-line with the totals
    // joined by middle dots. Mirrors the FieldBrandHeroCard chrome but
    // is a closed (non-generic) variant so we can render the totals
    // directly.
    @ViewBuilder
    private func heroCard(summary: HavenFieldDaySummary) -> some View {
        let today = summary.today
        let stops = today.stopsCompleted
        let stopWord = stops == 1 ? "stop" : "stops"
        var parts: [String] = ["\(stops) \(stopWord)"]
        if today.totalClockMinutes > 0 {
            parts.append("\(Self.formatClockMinutes(today.totalClockMinutes)) on the clock")
        }
        if today.revenueInvoicedCents > 0 {
            parts.append("\(Self.formatCents(today.revenueInvoicedCents)) invoiced")
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text(weekdayLabel.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.74))
            Text("Day complete")
                .font(HavenTypography.largeTitle)
                .foregroundStyle(HavenColors.textOnNavy)
            Text(parts.joined(separator: " · "))
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.86))
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

    @ViewBuilder
    private func stopsCard(summary: HavenFieldDaySummary) -> some View {
        if summary.today.stops.isEmpty {
            FieldEmptyState(
                title: "No stops on the books today",
                subtitle: "Once you wrap your first visit, the rundown lands here."
            )
        } else {
            FieldSectionCard(kicker: "Today", title: "Per stop") {
                VStack(spacing: 12) {
                    ForEach(summary.today.stops) { stop in
                        endOfDayStopRow(stop: stop)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func endOfDayStopRow(stop: HavenFieldDayStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Status pill: clock-out lands → green checkmark, in-progress →
            // amber, untouched → grey. Lets the operator scan the day at a
            // glance.
            ZStack {
                Circle()
                    .fill(stopAccentColor(for: stop).opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: stop.clockOutAt != nil ? "checkmark" : "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(stopAccentColor(for: stop))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                Text(stop.customerName + (stop.address.isEmpty ? "" : " · \(stop.address)"))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if stop.totalMinutes > 0 {
                        Text(Self.formatClockMinutes(stop.totalMinutes))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    if let inAt = stop.clockInAt?.fieldClockTimeOfDay,
                       let outAt = stop.clockOutAt?.fieldClockTimeOfDay {
                        // B3 fix: en-dash → " to " keeps the time range
                        // readable without the AI-flavored typography.
                        Text("\(inAt) to \(outAt)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if stop.invoiceId != nil {
                        Text("Invoiced")
                            .font(HavenTypography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(HavenColors.action.opacity(0.12))
                            .foregroundStyle(HavenColors.action)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func stopAccentColor(for stop: HavenFieldDayStop) -> Color {
        if stop.clockOutAt != nil { return HavenColors.success }
        if stop.clockInAt != nil { return HavenColors.warning }
        return HavenColors.textSecondary
    }

    @ViewBuilder
    private func materialsLine(summary: HavenFieldDaySummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(HavenColors.indigo50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text("\(Self.formatCents(summary.today.materialsCostCents)) spent on materials today")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func tomorrowCard(summary: HavenFieldDaySummary) -> some View {
        let tomorrow = summary.tomorrow
        FieldSectionCard(kicker: "Tomorrow", title: "What's next") {
            if tomorrow.stopsCount == 0 {
                Text("No stops on the calendar for tomorrow.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    let stopWord = tomorrow.stopsCount == 1 ? "stop" : "stops"
                    Text("\(tomorrow.stopsCount) \(stopWord) scheduled")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let firstAt = tomorrow.firstAt?.trimmedOrNil {
                        let firstShort = firstAt.fieldShortTime
                        if let firstCustomer = tomorrow.firstCustomer?.trimmedOrNil {
                            Text("First at \(firstShort) with \(firstCustomer)")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Text("First at \(firstShort)")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 13, weight: .medium))
                        // B3 fix: em-dash placeholder → ellipsis. Reads
                        // as "weather data still loading" rather than
                        // the AI-flavored em-dash typography.
                        Text("Weather: …")
                            .font(HavenTypography.caption)
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var signOffCTA: some View {
        Button {
            Task {
                withAnimation(.easeOut(duration: 0.25)) {
                    signedOff = true
                }
                // Brief toast then dismiss. No DB write yet — future
                // timekeeping wave can hook into this CTA.
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                Text("Sign off")
                    .font(HavenTypography.uiLabel)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(FieldPrimaryButtonStyle())
        .padding(.top, 6)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await HavenFieldService.shared.todaySummary(workspaceId: workspaceId)
            self.summary = result
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
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
                Text(visit.title.fieldDisplayTitle)
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
        // N-1 fix: render Postgres time-column as "10:00 AM" not "10:00:00".
        let time = visit.assignment?.windowStartTime?.trimmedOrNil?.fieldShortTime
            ?? visit.routeDate?.fieldShortDate ?? "TBD"
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
                    Text(visit.title.fieldDisplayTitle)
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
        let base = home?.name ?? visit.property?.name ?? visit.title.fieldDisplayTitle
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

            // Wave 7: highlightNext used to flip the divider to salmon
            // (B1 violation — divider is decorative). The 'NEXT UP' pill
            // already conveys next-up state; keep this neutral.
            RoundedRectangle(cornerRadius: 1)
                .fill(HavenColors.border)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(visit.title.fieldDisplayTitle)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(home?.address ?? visit.property?.address ?? home?.name ?? visit.property?.name ?? "Connected home")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        // Wave M1 — time-on-site caption shows once the
                        // tech has clocked in. Cross-app parity with
                        // Operations Desk's TIME ON-SITE label.
                        if let timeOnSite = timeOnSiteLabel {
                            Text(timeOnSite)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        if highlightNext {
                            // Wave 7 final smoke caught this — same B1 violation
                            // as the Visits-tab pill, but on the Overview-tab
                            // 'Scheduled next' card (different render site).
                            // Now navy-tinted to match.
                            Text("NEXT UP")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(HavenColors.navy700.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        // Wave M6 — internal-notes badge so the tech sees
                        // there's prior workspace context before opening
                        // the visit. Hidden when zero.
                        if let count = visit.assignment?.techNotesCount, count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("\(count) note\(count == 1 ? "" : "s")")
                                    .font(HavenTypography.caption)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(HavenColors.navy700.opacity(0.10))
                            .clipShape(Capsule())
                        }
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

    /// Wave M1 — small caption that surfaces "TIME ON-SITE" when the
    /// tech has clocked in. Computed against the assignment's clock_in
    /// timestamps; static (non-live) on the row to keep the today list
    /// simple — the live H:MM:SS belongs to the workspace view.
    private var timeOnSiteLabel: String? {
        guard let assignment = visit.assignment,
              let clockInAtString = assignment.clockInAt,
              let clockInAt = parseISODate(clockInAtString) else {
            return nil
        }
        let endDate: Date
        if let clockOutString = assignment.clockOutAt,
           let clockOut = parseISODate(clockOutString) {
            endDate = clockOut
        } else {
            endDate = Date()
        }
        let elapsedSec = max(0, Int(endDate.timeIntervalSince(clockInAt)) - assignment.pausedSeconds)
        let h = elapsedSec / 3600
        let m = (elapsedSec % 3600) / 60
        let live = (assignment.clockOutAt == nil)
        let value: String
        if h > 0 {
            value = "\(h)h \(m)m"
        } else if m > 0 {
            value = "\(m)m"
        } else {
            value = live ? "Just started" : "0m"
        }
        return live ? "TIME ON-SITE: \(value) (live)" : "TIME ON-SITE: \(value)"
    }

    private func parseISODate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: string) { return parsed }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private var timeLabel: String {
        // N-1 fix: device-locale short time, not raw "10:00:00".
        visit.assignment?.windowStartTime?.trimmedOrNil?.fieldShortTime
            ?? visit.routeDate?.fieldShortDate ?? "TBD"
    }

    private var durationLabel: String {
        if let end = visit.assignment?.windowEndTime?.trimmedOrNil {
            return end.fieldShortTime
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
    /// N-permission-gating fix: caller's role on the workspace
    /// (`owner` / `lead_dispatcher` / `field_technician` / etc.).
    /// Used to gate the "Open desktop command center" link — only owners
    /// have access to the desktop Operations Desk; surfacing the link to
    /// a field tech they can't actually open is confusing and off-brand.
    /// Sign out stays available for everyone (it's account-scoped, not
    /// workspace-scoped).
    let role: String?
    let onSignOut: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isOwner: Bool {
        (role ?? "").lowercased() == "owner"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldBrandHeroCard(
                        kicker: "Settings",
                        title: companyName,
                        subtitle: "Profile, rates, branding, team, and notifications all live in the desktop command center. Tap below to open it."
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

                    // N-permission-gating fix: section title swaps to
                    // "Account" for non-owners since the only thing they
                    // see is Sign Out. "Owner tools" with no owner tools
                    // visible felt like a dead label.
                    FieldSectionCard(
                        kicker: "Workspace",
                        title: isOwner ? "Owner tools" : "Account"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            if isOwner, let providerURL, let url = URL(string: providerURL) {
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

                            // Wave 7: was salmon FieldPrimaryButtonStyle —
                            // major B1 violation since Sign Out is destructive,
                            // not the recommended next step. Now renders as a
                            // critical-red outlined button that signals 'danger
                            // zone' without burning the brand-action salmon.
                            Button("Sign out") {
                                dismiss()
                                onSignOut()
                            }
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.critical)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(HavenColors.critical.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    Text(visit.title.fieldDisplayTitle)
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
        // N-1 fix: device-locale short time, not raw "10:00:00 to 12:00:00".
        let start = visit.assignment?.windowStartTime?.trimmedOrNil?.fieldShortTime
        let end = visit.assignment?.windowEndTime?.trimmedOrNil?.fieldShortTime
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
        // N-4 fix: pluralize systems / open tasks correctly so the row
        // doesn't read "5 systems · 1 open tasks". Helper inline since
        // there's no other site that needs it yet.
        let lastVisit = home.lastCompletedVisit?.fieldDateTime
        let systemWord = home.systemCount == 1 ? "system" : "systems"
        let openCount = home.openTasks.count
        let openWord = openCount == 1 ? "open task" : "open tasks"
        let homeSummary = "\(home.systemCount) \(systemWord) · \(openCount) \(openWord)"
        guard let lastVisit else { return homeSummary }
        return "\(homeSummary) · last visit \(lastVisit)"
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

/// Wave M6 — tap-to-navigate row. Renders an address line with a pin
/// icon prefix and routes the tap through Apple Maps. Falls back to a
/// plain text row if the URL doesn't resolve. Mirrors `FieldKeyValueRow`
/// styling so it sits naturally inside the same hero card.
private struct FieldTappableAddressRow: View {
    let address: String
    var inverse: Bool = false

    private var mapsURL: URL? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://maps.apple.com/?q=\(encoded)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ADDRESS")
                .font(HavenTypography.uiSectionHeader)
                .kerning(1)
                .foregroundStyle(inverse ? HavenColors.textOnNavy.opacity(0.72) : HavenColors.textSecondary)
            if let url = mapsURL {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .semibold))
                        Text(address)
                            .font(HavenTypography.body)
                            .underline()
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.action)
                }
                .accessibilityLabel("Navigate to \(address)")
                .accessibilityHint("Opens Apple Maps with this address")
            } else {
                Text(address)
                    .font(HavenTypography.body)
                    .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Wave M6 — tap-to-call row. Renders a phone number with a phone icon
/// prefix and routes the tap through `tel://`. Sanitizes the digit
/// stream so formatted numbers (("(914) 555-0123") still produce a
/// dialer-ready URL.
private struct FieldTappablePhoneRow: View {
    let phone: String
    var label: String = "Customer phone"
    var inverse: Bool = false

    private var telURL: URL? {
        let digits = phone.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) || $0 == "+" }
        let asString = String(String.UnicodeScalarView(digits))
        guard !asString.isEmpty else { return nil }
        return URL(string: "tel://\(asString)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .kerning(1)
                .foregroundStyle(inverse ? HavenColors.textOnNavy.opacity(0.72) : HavenColors.textSecondary)
            if let url = telURL {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(phone)
                            .font(HavenTypography.body)
                            .underline()
                    }
                    .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.action)
                }
                .accessibilityLabel("Call \(phone)")
            } else {
                Text(phone)
                    .font(HavenTypography.body)
                    .foregroundStyle(inverse ? HavenColors.textOnNavy : HavenColors.textPrimary)
            }
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

    /// Wave M6 — three candidate slots in the next 14 business days.
    /// Stub heuristic: tomorrow 9am, day-after 1pm, 3 days out 9am. NOT
    /// a true open-windows lookup (the open-windows table doesn't ship
    /// until a later wave). Tapping a slot snaps `date` to that value
    /// for one-tap propose; the graphical picker below is the manual
    /// override for techs who want to dial in a precise minute.
    private var quickSlots: [Date] {
        let now = Date()
        let cal = Calendar.current
        let candidates: [(Int, Int)] = [(1, 9), (2, 13), (4, 9)]
        return candidates.compactMap { dayOffset, hour in
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: now) else { return nil }
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)
        }
    }

    private var slotFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d 'at' h:mm a"
        return f
    }

    private func isSlotSelected(_ slot: Date) -> Bool {
        abs(slot.timeIntervalSince(date)) < 60
    }

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

                    // Wave M6 — quick-pick slot row. One tap snaps the
                    // date and the tech can hit Propose without opening
                    // the picker.
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested slots")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        VStack(spacing: 8) {
                            ForEach(quickSlots, id: \.self) { slot in
                                Button {
                                    date = slot
                                } label: {
                                    HStack {
                                        Image(systemName: isSlotSelected(slot) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(isSlotSelected(slot) ? HavenColors.action : HavenColors.textSecondary)
                                        Text(slotFormatter.string(from: slot))
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(isSlotSelected(slot) ? HavenColors.action.opacity(0.08) : HavenColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSlotSelected(slot) ? HavenColors.action : HavenColors.border, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or pick exact time")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
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
                    }

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

// MARK: - Wave M9 visit edge cases (co-tech + access method + cancel)

/// Wave M9 — small avatar bubble used in the co-tech roster row + the
/// add-co-tech picker. Displays initials over a navy disc.
private struct FieldCoTechAvatar: View {
    let initials: String
    var body: some View {
        Text(initials)
            .font(HavenTypography.caption.weight(.semibold))
            .foregroundStyle(HavenColors.textOnNavy)
            .frame(width: 32, height: 32)
            .background(HavenColors.navy700)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

/// Wave M9 — "Add co-tech" picker. Lists every active workspace
/// member except the primary tech and any already-added co-techs.
/// Tap a row → calls `add_co_tech` action. Sheet closes on success.
private struct FieldCoTechPickerSheet: View {
    let primaryMemberId: String?
    let alreadyCoTechIds: [String]
    let roster: [HavenFieldCrewChatMember]
    let isLoadingRoster: Bool
    let isSubmitting: Bool
    let errorMessage: String?
    let onSelect: (HavenFieldCrewChatMember) -> Void
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var eligible: [HavenFieldCrewChatMember] {
        roster.filter { member in
            member.id != primaryMemberId &&
            !alreadyCoTechIds.contains(member.id) &&
            member.status == "active"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pair up with another tech to share punch-list check-off on this visit. Both techs can mark items done.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)

                    if let errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.action)
                            Text(errorMessage)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                        }
                        .padding(12)
                        .background(HavenColors.action.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if isLoadingRoster {
                        VStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { _ in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(HavenColors.cream)
                                        .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Rectangle()
                                            .fill(HavenColors.cream)
                                            .frame(width: 140, height: 12)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        Rectangle()
                                            .fill(HavenColors.cream)
                                            .frame(width: 80, height: 10)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(HavenColors.cream.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else if eligible.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No teammates to add")
                                .font(HavenTypography.bodySmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(roster.isEmpty
                                 ? "Couldn't load workspace members. Check your connection."
                                 : "Every active workspace member is already on this visit, or no one else is active.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(HavenColors.cream.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            ForEach(eligible) { member in
                                Button {
                                    onSelect(member)
                                } label: {
                                    HStack(spacing: 12) {
                                        FieldCoTechAvatar(initials: member.initials)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.displayName)
                                                .font(HavenTypography.body.weight(.semibold))
                                                .foregroundStyle(HavenColors.textPrimary)
                                            Text(member.role.localizedCapitalized)
                                                .font(HavenTypography.caption)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                        Spacer()
                                        if isSubmitting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(HavenColors.navy700)
                                        }
                                    }
                                    .padding(12)
                                    .background(HavenColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(HavenColors.border, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(isSubmitting)
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Add co-tech")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onClose()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }
}

/// Wave M9 — access method picker. Choose entry method + free-form
/// notes; Save round-trips through `set_access_method`.
private struct FieldAccessMethodSheet: View {
    @Binding var method: String
    @Binding var notes: String
    let isSubmitting: Bool
    /// N-validation-stale-render fix: was a `let String?` so the sheet
    /// couldn't clear the message itself when the user started typing.
    /// Now a Binding so the on-change of `notes` can reset it locally.
    @Binding var errorMessage: String?
    let onSave: () -> Void
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var resolvedMethod: FieldAccessMethod {
        FieldAccessMethod(rawValue: method) ?? .customerPresent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How will you get into the home?")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(FieldAccessMethod.allCases) { option in
                            Button {
                                method = option.rawValue
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: option == resolvedMethod ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(option == resolvedMethod ? HavenColors.action : HavenColors.textSecondary)
                                    Image(systemName: option.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(option.displayLabel)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(option == resolvedMethod ? HavenColors.action.opacity(0.08) : HavenColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(option == resolvedMethod ? HavenColors.action : HavenColors.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: 44)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(resolvedMethod.requiresNotes ? "Notes (required)" : "Notes (optional)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField(resolvedMethod.notesPrompt, text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textInputAutocapitalization(.sentences)
                            .padding(12)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            // N-validation-stale-render fix: clear the
                            // validation banner as soon as the user types
                            // — when the lockbox-method picker triggers
                            // "Add the lockbox details" the message used
                            // to persist even after the user typed valid
                            // text.
                            .onChange(of: notes) { _, newValue in
                                if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    errorMessage = nil
                                }
                            }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }

                    Button {
                        onSave()
                    } label: {
                        if isSubmitting {
                            HStack(spacing: 8) {
                                ProgressView().tint(HavenColors.textOnAction)
                                Text("Saving...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Save access method")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Access method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        onClose()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }
}

/// Wave M9 — mid-stream cancel sheet. Reason picker + optional
/// "Other" free-form text + schedule-follow-up toggle. Submit calls
/// `cancel_visit_mid_stream` and the parent dismisses on success.
private struct FieldCancelMidStreamSheet: View {
    @Binding var reason: FieldCancelReason
    @Binding var otherText: String
    @Binding var scheduleFollowup: Bool
    let isSubmitting: Bool
    let validationError: String?
    let genericError: String?
    let onSubmit: () -> Void
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Why are you ending the visit?")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    Text("We'll close the running clock, save what you've already captured, and let the homeowner know in their thread.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(FieldCancelReason.allCases) { option in
                            Button {
                                reason = option
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: option == reason ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(option == reason ? HavenColors.action : HavenColors.textSecondary)
                                    Text(option.displayLabel)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(option == reason ? HavenColors.action.opacity(0.08) : HavenColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(option == reason ? HavenColors.action : HavenColors.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: 44)
                        }
                    }

                    if reason == .other {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tell the homeowner what happened")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            TextField("e.g. car trouble, returning tomorrow", text: $otherText, axis: .vertical)
                                .lineLimit(2...4)
                                .textInputAutocapitalization(.sentences)
                                .padding(12)
                                .background(HavenColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Toggle(isOn: $scheduleFollowup) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Schedule a follow-up visit")
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Creates a placeholder request the homeowner can confirm.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: HavenColors.action))
                    .padding(12)
                    .background(HavenColors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let validationError {
                        Text(validationError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }
                    if let genericError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.action)
                            Text(genericError)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                        }
                        .padding(12)
                        .background(HavenColors.action.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Critical-tinted Cancel CTA — visit cancellation
                    // is destructive, so the primary action uses the
                    // critical color (per Section 22 B1: action salmon
                    // is for primary CTAs and load-bearing alerts; the
                    // cancel button itself is critical = red).
                    Button {
                        onSubmit()
                    } label: {
                        if isSubmitting {
                            HStack(spacing: 8) {
                                ProgressView().tint(HavenColors.textOnAction)
                                Text("Cancelling...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Cancel this visit")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(FieldCriticalButtonStyle())
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("End visit early")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Keep going") {
                        onClose()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }
}

/// Wave M9 — critical-tinted button style for destructive actions.
/// Mirrors `FieldPrimaryButtonStyle` but with `HavenColors.critical`
/// as the fill so cancellation reads as destructive at first glance.
private struct FieldCriticalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HavenTypography.body.weight(.semibold))
            .foregroundStyle(HavenColors.textOnAction)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .background(HavenColors.critical)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Wave M4 kitchen-table close

/// Wave M4 — full-screen sheet from the visit-complete screen. Lets
/// the field tech build a quote on the spot from the visit's punch
/// list, optionally add good/better/best tiers, and capture a
/// finger-drawn customer signature without leaving the kitchen table.
///
/// Lifecycle:
/// 1. On appear: if no cached draft, hit `build_quote_from_visit` to
///    pre-fill line items from completed punch items + materials.
/// 2. Tech edits lines, optionally adds bundle tiers, optionally adds
///    a homeowner message.
/// 3. Tap "Save draft" or "Send to customer" → routes through
///    `save_quote` / `send_quote` (single tier) or `save_quote_bundle`
///    / `send_quote_bundle` (≥ 2 tiers). The returned quote id is
///    the reference for the next step.
/// 4. Tap "Have customer sign here" → opens the signature pad over
///    the saved quote. PencilKit captures strokes; Submit uploads
///    the PNG via `sign_quote`. The post-sign confirmation strip
///    renders inline.
private struct FieldBuildQuoteSheet: View {
    let workspaceId: String
    let requestId: String
    let visit: HavenFieldVisit
    let cachedDraft: HavenFieldQuoteDraftPayload?
    let onDraftCached: (HavenFieldQuoteDraftPayload) -> Void
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Loading states

    /// Pre-fill payload from build_quote_from_visit. Cached on the
    /// parent so re-opening the sheet doesn't re-fire the network call.
    @State private var draftPayload: HavenFieldQuoteDraftPayload?
    /// True during the initial pre-fill round-trip + during save / send /
    /// sign actions. Drives the skeleton state.
    @State private var isLoadingDraft = false
    /// Most recent error from any network round-trip on this sheet.
    @State private var errorMessage: String?

    // MARK: - Editor state

    /// Editable line items. Mirrors draftPayload.lineItems on first
    /// hydrate; the field tech edits in place. Identifiable so SwiftUI
    /// diffing keeps row identity stable across re-renders.
    @State private var lineItems: [HavenFieldQuoteDraftLine] = []
    /// Quote title — pre-filled from "Quote for <visit title>".
    @State private var title: String = ""
    /// Optional homeowner-facing message attached to the quote.
    @State private var homeownerMessage: String = ""

    // MARK: - Tier state (multi-tier toggle)

    /// True after the tech taps "+ Add good / better / best options".
    /// Splits the editor into 3 sections (Good / Better / Best) each
    /// with their own line items. Single-tier flow stays the default.
    @State private var multiTierEnabled = false
    /// One line-item array per tier. Index 0 = Good, 1 = Better, 2 = Best.
    /// Initialized by mirroring the single-tier `lineItems` into "Good".
    @State private var tierLineItems: [[HavenFieldQuoteDraftLine]] = [[], [], []]
    private let tierLabels = ["Good", "Better", "Best"]

    // MARK: - Save / send result

    /// Quote id returned by save_quote / save_quote_bundle. Set after
    /// the first save round-trip; gates the "Have customer sign here"
    /// CTA (can't sign a quote that doesn't exist yet).
    @State private var savedQuoteId: String?
    /// True after a successful send_quote. Drives the "Sent to
    /// customer" status badge.
    @State private var quoteSentAt: Date?
    /// True while a save / send round-trip is in flight.
    @State private var isSaving = false
    /// True while a sign round-trip is in flight.
    @State private var isSigning = false

    // MARK: - Signature pad state

    /// True while the signature pad sheet is presented over the quote
    /// editor.
    @State private var showSignaturePad = false
    /// Result of a successful sign_quote call. Drives the post-sign
    /// confirmation strip.
    @State private var signedQuote: HavenFieldSignedQuote?

    // MARK: - Wave M13 — duplicate-from-another-quote state

    /// True while the duplicate picker sheet is presented over the
    /// editor. Picker is itself a sheet so the field tech can scroll
    /// past long quote lists without losing the editor underneath.
    @State private var showDuplicatePicker = false
    /// True during the duplicate_quote round-trip after the tech taps
    /// a row in the picker.
    @State private var isDuplicating = false
    /// Toast banner text after a successful duplicate (e.g.
    /// "Duplicated from Smith house quote — review the lines").
    @State private var duplicateBannerText: String?

    // MARK: - Computed

    private var totalSubtotal: Double {
        if multiTierEnabled {
            return tierLineItems.flatMap { $0 }.reduce(0) { $0 + $1.lineTotal }
        }
        return lineItems.reduce(0) { $0 + $1.lineTotal }
    }

    private var goodTierTotal: Double {
        tierLineItems[safe: 0]?.reduce(0) { $0 + $1.lineTotal } ?? 0
    }

    private var betterTierTotal: Double {
        tierLineItems[safe: 1]?.reduce(0) { $0 + $1.lineTotal } ?? 0
    }

    private var bestTierTotal: Double {
        tierLineItems[safe: 2]?.reduce(0) { $0 + $1.lineTotal } ?? 0
    }

    private var canSave: Bool {
        let activeLines = multiTierEnabled
            ? tierLineItems.first(where: { !$0.isEmpty }) ?? []
            : lineItems
        // Sprint #3 R1-E-5: reject negative unit prices / quantities
        // here too. Guards the build-quote-from-visit flow alongside
        // the other canSave at the EOD invoice screen.
        let allLineItemsValid = activeLines.allSatisfy {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
                && $0.unitPrice >= 0
                && $0.quantity >= 0
        }
        return !activeLines.isEmpty &&
            allLineItemsValid &&
            !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var moneyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f
    }

    private var customerName: String {
        visit.property?.name ?? visit.title.fieldDisplayTitle
    }

    private var customerAddress: String {
        visit.property?.address ?? "Address on file"
    }

    private var visitDateLabel: String {
        // N-9 fix: routeDate arrives as "2026-05-08" (Postgres date
        // column, no time) most of the time — ISO8601DateFormatter
        // can't parse those because it requires the time portion.
        // Try the simple yyyy-MM-dd shape FIRST, fall back to ISO8601
        // for the rare full-timestamp values, fall back to the raw
        // string only as a last resort. Output: "Fri May 8".
        guard let routeDate = visit.routeDate, !routeDate.isEmpty else { return "Today" }
        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.dateFormat = "yyyy-MM-dd"
        if let parsed = dateOnly.date(from: routeDate) {
            let display = DateFormatter()
            display.dateFormat = "EEE MMM d"
            return display.string(from: parsed)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: routeDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: routeDate)
        }()
        guard let date else { return routeDate }
        let display = DateFormatter()
        display.dateFormat = "EEE MMM d"
        return display.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    if isLoadingDraft && draftPayload == nil {
                        loadingSkeleton
                    } else if let signed = signedQuote {
                        signedConfirmationCard(signed)
                    } else {
                        prefillCardIfAvailable
                        // Wave M13 — kitchen-table efficiency: "same as
                        // the Smith house yesterday." Inline link below
                        // the pre-fill card so the field tech can reach
                        // the picker without scrolling. Hidden when a
                        // signed quote is rendered (the close-out path).
                        duplicateFromAnotherQuoteLink
                        if let banner = duplicateBannerText {
                            duplicateBanner(banner)
                        }
                        editorBody
                        if let savedQuoteId, signedQuote == nil {
                            signatureCTACard(quoteId: savedQuoteId)
                        }
                    }

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                }
                .padding(20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Build quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onClose()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .sheet(isPresented: $showSignaturePad) {
                if let savedQuoteId {
                    FieldQuoteSignaturePad(
                        workspaceId: workspaceId,
                        quoteId: savedQuoteId,
                        customerName: customerName,
                        isSigning: $isSigning,
                        onSigned: { signed in
                            signedQuote = signed
                            showSignaturePad = false
                        },
                        onCancel: {
                            showSignaturePad = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showDuplicatePicker) {
                // Wave M13 — quote duplication picker. Pass the visit's
                // household + property + request so the duplicate lands
                // on the right context. Workspace-scoped server-side.
                FieldDuplicateQuotePickerSheet(
                    workspaceId: workspaceId,
                    targetHouseholdId: visit.householdId ?? "",
                    targetPropertyId: visit.propertyId,
                    targetRequestId: requestId,
                    isDuplicating: $isDuplicating,
                    onDuplicated: { payload in
                        applyDuplicate(payload)
                        showDuplicatePicker = false
                    },
                    onCancel: {
                        showDuplicatePicker = false
                    }
                )
            }
        }
        .task {
            // First-appear hydration. Use cached draft if the parent
            // already loaded it; otherwise pre-fill from the visit's
            // punch list.
            if let cachedDraft {
                hydrate(from: cachedDraft)
            } else if draftPayload == nil {
                await loadDraft()
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("KITCHEN-TABLE CLOSE")
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textSecondary)
            Text(customerName)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                Text(visitDateLabel)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("·")
                    .foregroundStyle(HavenColors.textTertiary)
                FieldQuoteDraftBadge(savedQuoteId: savedQuoteId, sentAt: quoteSentAt)
            }
        }
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(HavenColors.creamLight.opacity(0.6))
                    .frame(height: 80)
            }
        }
    }

    @ViewBuilder
    private var prefillCardIfAvailable: some View {
        if let draft = draftPayload, draft.eligibleCount > 0 {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pre-filled from visit")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(draft.eligibleCount) line item\(draft.eligibleCount == 1 ? "" : "s") loaded from completed punch items.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Button {
                    Task { await loadDraft() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(14)
            .background(HavenColors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let draft = draftPayload, draft.eligibleCount == 0 {
            FieldEmptyState(
                title: "No punch items yet",
                subtitle: "Add line items below to build the quote from scratch."
            )
            .padding(14)
            .background(HavenColors.creamLight.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Wave M13 — inline link to open the duplication picker. Renders
    /// below the pre-fill card (or in its place when no punch items are
    /// available). Navy chip styling so it doesn't compete with the
    /// salmon CTAs at the bottom of the editor (Section 22 B1).
    private var duplicateFromAnotherQuoteLink: some View {
        Button {
            showDuplicatePicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Or duplicate from another quote")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(HavenColors.creamLight.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Wave M13 — short-lived success banner after a duplicate lands.
    /// Auto-clears after 3 seconds. Navy-on-cream so it reads as
    /// confirmation, not as an error (the error banner is salmon).
    private func duplicateBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(HavenColors.success)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                duplicateBannerText = nil
            }
        }
    }

    /// Wave M13 — apply the duplicate_quote response to the editor.
    /// Hydrates line items + title from the returned draft payload so
    /// the field tech can edit + send without a second round-trip.
    /// Bundle duplicates show a banner explaining they need to be
    /// reviewed in the operator desk (multi-tier editor isn't wired
    /// for hydration from a duplicate; field tech uses single-tier
    /// for kitchen-table closes).
    private func applyDuplicate(_ payload: HavenFieldQuoteDuplicatePayload) {
        savedQuoteId = payload.id
        if let draft = payload.draft {
            // Single-tier: hydrate the editor's line items + title from
            // the draft payload so the tech sees the duplicate's items
            // pre-loaded with new ids + signature fields cleared.
            multiTierEnabled = false
            lineItems = draft.lineItems
            title = draft.title
            duplicateBannerText = "Duplicated \(draft.lineItems.count) line item\(draft.lineItems.count == 1 ? "" : "s") from \(payload.title)"
        } else {
            // Bundle: the duplicate is saved but the editor doesn't
            // re-hydrate (multi-tier editor doesn't support hydration
            // from a saved bundle). Banner directs the tech to review
            // in the Operations Desk before sending.
            duplicateBannerText = "Bundle duplicate saved. Review and edit tiers before sending."
        }
        Haptics.success()
    }

    private var editorBody: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title + customer block
            FieldSectionCard(kicker: "Quote", title: "Title and recipient") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Quote title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(HavenTypography.body)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sending to")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(customerName)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(customerAddress)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Multi-tier toggle
            multiTierToggle

            // Line items list (single-tier or 3-tier)
            if multiTierEnabled {
                ForEach(0..<3, id: \.self) { tierIndex in
                    tierEditorSection(tierIndex)
                }
            } else {
                singleTierEditorSection
            }

            // Homeowner message
            FieldSectionCard(kicker: "Note", title: "Message to customer (optional)") {
                TextField(
                    "Thanks for letting us into your home today...",
                    text: $homeownerMessage,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .font(HavenTypography.body)
            }

            // Totals + actions
            totalsCard
            actionRow
        }
    }

    private var multiTierToggle: some View {
        Toggle(isOn: $multiTierEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(multiTierEnabled ? "Good / Better / Best options" : "+ Add good / better / best options")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Present multiple tiers so the customer picks at the table.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .tint(HavenColors.action)
        .padding(14)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: multiTierEnabled) { _, isEnabled in
            if isEnabled, tierLineItems.allSatisfy({ $0.isEmpty }) {
                // Mirror the single-tier lines into "Good" so the tech
                // doesn't lose their work toggling on.
                tierLineItems[0] = lineItems
                tierLineItems[1] = []
                tierLineItems[2] = []
            } else if !isEnabled, lineItems.isEmpty {
                // Toggling off: pull from the most populated tier so we
                // don't blank the editor.
                let firstNonEmpty = tierLineItems.first(where: { !$0.isEmpty }) ?? []
                lineItems = firstNonEmpty
            }
        }
    }

    private var singleTierEditorSection: some View {
        FieldSectionCard(kicker: "Line items", title: "What's on the quote") {
            VStack(alignment: .leading, spacing: 10) {
                if lineItems.isEmpty {
                    Text("No items yet. Tap + to add one.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach($lineItems) { $line in
                        FieldQuoteLineItemRow(
                            line: $line,
                            moneyFormatter: moneyFormatter,
                            onDelete: {
                                lineItems.removeAll { $0.id == line.id }
                            }
                        )
                    }
                }
                Button {
                    lineItems.append(HavenFieldQuoteDraftLine(name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(HavenColors.action)
                        Text("Add line")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.action)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }

    private func tierEditorSection(_ index: Int) -> some View {
        FieldSectionCard(
            kicker: tierLabels[safe: index] ?? "Tier",
            title: "\(tierLabels[safe: index] ?? "Tier") option"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if (tierLineItems[safe: index] ?? []).isEmpty {
                    Text("No items yet for this tier.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(tierLineItems[index].indices, id: \.self) { lineIndex in
                        FieldQuoteLineItemRow(
                            line: $tierLineItems[index][lineIndex],
                            moneyFormatter: moneyFormatter,
                            onDelete: {
                                guard tierLineItems[index].indices.contains(lineIndex) else { return }
                                tierLineItems[index].remove(at: lineIndex)
                            }
                        )
                    }
                }
                Button {
                    tierLineItems[index].append(
                        HavenFieldQuoteDraftLine(name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0)
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(HavenColors.action)
                        Text("Add to \(tierLabels[safe: index] ?? "this tier")")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.action)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if multiTierEnabled {
                HStack { Text("Good"); Spacer(); Text(formatMoney(goodTierTotal)) }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack { Text("Better"); Spacer(); Text(formatMoney(betterTierTotal)) }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack { Text("Best"); Spacer(); Text(formatMoney(bestTierTotal)) }
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Divider()
            }
            HStack {
                Text("Subtotal")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Text(formatMoney(totalSubtotal))
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button {
                Task { await save(send: false) }
            } label: {
                if isSaving {
                    ProgressView().tint(HavenColors.textOnAction)
                } else {
                    Text("Save draft")
                }
            }
            .buttonStyle(FieldSecondaryButtonStyle())
            .disabled(!canSave || isSaving)

            Button {
                Task { await save(send: true) }
            } label: {
                if isSaving {
                    ProgressView().tint(HavenColors.textOnAction)
                } else {
                    Text("Send to customer")
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())
            .disabled(!canSave || isSaving)
        }
    }

    private func signatureCTACard(quoteId _: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "signature")
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.action)
                Text("Have customer sign here")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Text("Capture a signature on the iPad to close the deal in person.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
            Button {
                showSignaturePad = true
            } label: {
                Text("Open signature pad")
            }
            .buttonStyle(FieldPrimaryButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.action.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(HavenColors.action.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func signedConfirmationCard(_ signed: HavenFieldSignedQuote) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed and approved")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Signed by \(signed.signedName ?? "the customer")\(signedDateSuffix(signed.signedAt))")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
            }

            if let url = signed.signatureSignedUrl, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(HavenColors.creamLight.opacity(0.4))
                            .frame(height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Text("Signature uploaded successfully.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            HStack {
                Text("Total")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(formatMoney(signed.total))
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            Button {
                onClose()
                dismiss()
            } label: {
                Text("Done")
            }
            .buttonStyle(FieldPrimaryButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.success.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(HavenColors.success.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(HavenColors.action)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(HavenColors.action.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formatMoney(_ value: Double) -> String {
        moneyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func signedDateSuffix(_ iso: String?) -> String {
        guard let iso, let date = parseISO(iso) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = " on MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    private func parseISO(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = f.date(from: string) { return parsed }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: string)
    }

    private func hydrate(from draft: HavenFieldQuoteDraftPayload) {
        draftPayload = draft
        lineItems = draft.lineItems
        title = draft.title
    }

    // MARK: - Network

    private func loadDraft() async {
        guard !workspaceId.isEmpty, !requestId.isEmpty else {
            errorMessage = "Visit identifier missing."
            return
        }
        errorMessage = nil
        isLoadingDraft = true
        defer { isLoadingDraft = false }
        do {
            let draft = try await HavenFieldService.shared.buildQuoteFromVisit(
                workspaceId: workspaceId,
                requestId: requestId
            )
            hydrate(from: draft)
            onDraftCached(draft)
        } catch {
            errorMessage = "Couldn't pre-fill the quote: \(error.localizedDescription)"
        }
    }

    private func save(send: Bool) async {
        guard canSave else { return }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            if multiTierEnabled {
                let tiers: [HavenFieldQuoteDraftBundleTier] = (0..<3).compactMap { idx in
                    let lines = tierLineItems[safe: idx] ?? []
                    let cleaned = lines.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                    guard !cleaned.isEmpty else { return nil }
                    return HavenFieldQuoteDraftBundleTier(
                        label: tierLabels[safe: idx] ?? "Option",
                        lineItems: cleaned
                    )
                }
                guard tiers.count >= 2 else {
                    errorMessage = "Add line items to at least two tiers (Good / Better)."
                    return
                }
                let result = try await HavenFieldService.shared.saveQuoteBundle(
                    workspaceId: workspaceId,
                    requestId: requestId,
                    householdId: draftPayload?.householdId,
                    propertyId: draftPayload?.propertyId,
                    contractorId: draftPayload?.contractorId,
                    title: title.trimmingCharacters(in: .whitespaces),
                    homeownerMessage: homeownerMessage.trimmingCharacters(in: .whitespaces).isEmpty ? nil : homeownerMessage,
                    tiers: tiers,
                    send: send
                )
                if let parentId = result.parent?.id, !parentId.isEmpty {
                    savedQuoteId = parentId
                    if send { quoteSentAt = Date() }
                }
            } else {
                let cleaned = lineItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                let saved = try await HavenFieldService.shared.saveSingleQuote(
                    workspaceId: workspaceId,
                    requestId: requestId,
                    householdId: draftPayload?.householdId,
                    propertyId: draftPayload?.propertyId,
                    contractorId: draftPayload?.contractorId,
                    title: title.trimmingCharacters(in: .whitespaces),
                    homeownerMessage: homeownerMessage.trimmingCharacters(in: .whitespaces).isEmpty ? nil : homeownerMessage,
                    lineItems: cleaned,
                    send: send
                )
                if !saved.id.isEmpty {
                    savedQuoteId = saved.id
                    if send { quoteSentAt = Date() }
                }
            }
        } catch {
            errorMessage = "Couldn't \(send ? "send" : "save") the quote: \(error.localizedDescription)"
        }
    }
}

/// Wave M4 — one editable row in the BuildQuoteSheet's line-item list.
/// Renders title + description + qty stepper + unit price + computed
/// total + delete button. Bind-driven so edits write back into the
/// parent's array directly.
private struct FieldQuoteLineItemRow: View {
    @Binding var line: HavenFieldQuoteDraftLine
    let moneyFormatter: NumberFormatter
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Item name", text: $line.name)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    if !line.description.isEmpty {
                        Text(line.description)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("Qty")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    Stepper(value: $line.quantity, in: 0.5...999, step: 0.5) {
                        Text(quantityLabel(line.quantity))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                            .monospacedDigit()
                    }
                    .labelsHidden()
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("$")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextField("0", value: $line.unitPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        // Sprint #3 R1-E-5: decimal pad doesn't show a
                        // minus key but Foundation's .number formatter
                        // accepts negative numbers from paste. Clamp to
                        // zero so a negative line item can't ship to the
                        // homeowner (and never produce a negative subtotal).
                        .onChange(of: line.unitPrice) { _, newValue in
                            if newValue < 0 { line.unitPrice = 0 }
                        }
                }

                Text("=")
                    .foregroundStyle(HavenColors.textTertiary)
                Text(moneyFormatter.string(from: NSNumber(value: line.lineTotal)) ?? "$0")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func quantityLabel(_ q: Double) -> String {
        if q == q.rounded() { return String(format: "%.0f", q) }
        return String(format: "%.1f", q)
    }
}

/// Wave M4 — small status pill on the BuildQuoteSheet header.
/// Shows "Draft" until a save round-trip lands a quote id, then "Saved",
/// then "Sent" after send_quote.
private struct FieldQuoteDraftBadge: View {
    let savedQuoteId: String?
    let sentAt: Date?

    var body: some View {
        let label: String
        let tone: Color
        if sentAt != nil {
            label = "Sent"
            tone = HavenColors.success
        } else if savedQuoteId != nil {
            label = "Saved"
            tone = HavenColors.action
        } else {
            label = "Draft"
            tone = HavenColors.textSecondary
        }
        return Text(label)
            .font(HavenTypography.caption)
            .foregroundStyle(tone)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tone.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Wave M5 BuildInvoiceSheet

/// Wave M5 — visit-to-invoice sheet. Mirrors `FieldBuildQuoteSheet`
/// but lands the editable lines on the invoice path. Pre-fills from
/// `convert_visit_to_invoice` (one Labor + N Materials lines per
/// completed punch item), lets the field tech edit / add / reorder
/// Wave M13 — quote duplication picker. Tapped from
/// `FieldBuildQuoteSheet` via "Or duplicate from another quote ->".
/// Shows the workspace's recent quotes (last 30 / 90 / all time)
/// sorted reverse-chronologically. Field tech taps a row to duplicate
/// that quote's line items into the current visit's draft.
///
/// Single network round-trip per filter change (`list_recent_quotes`
/// returns up to 50 rows). Tap-to-pick fires `duplicate_quote` which
/// inserts a fresh draft, strips signature + approval + punch_item_id
/// fields, and returns a hydration payload. The parent's
/// `applyDuplicate(...)` handler then re-hydrates the editor.
///
/// Discipline notes (Section 22):
/// - Salmon ONLY on the active filter chip + the confirm dialog
///   primary CTA. No salmon on row backgrounds (navy-on-cream chip
///   styling for the row container).
/// - 4 states wired: loading skeleton, empty (no recent quotes),
///   error with Retry CTA, populated list.
/// - 44pt min touch on every quote row + filter chip + confirm
///   buttons.
/// - Confirm dialog shows source customer + target customer so the
///   field tech can sanity-check before pasting onto the wrong house.
private struct FieldDuplicateQuotePickerSheet: View {
    let workspaceId: String
    let targetHouseholdId: String
    let targetPropertyId: String?
    let targetRequestId: String?
    @Binding var isDuplicating: Bool
    let onDuplicated: (HavenFieldQuoteDuplicatePayload) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Filter window in days. 30 / 90 / 3650 (≈ "all time").
    @State private var daysBack: Int = 30
    @State private var quotes: [HavenFieldQuoteSummaryRow] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    /// Quote selected for confirmation. Set on tap; cleared on
    /// confirm or cancel.
    @State private var pendingConfirm: HavenFieldQuoteSummaryRow?

    private let service = HavenFieldService.shared

    private let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filterChipRow
                    if isLoading && quotes.isEmpty {
                        loadingSkeleton
                    } else if let errorMessage {
                        errorBanner(errorMessage)
                    } else if quotes.isEmpty {
                        emptyState
                    } else {
                        quoteList
                    }
                }
                .padding(20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Pick a quote to duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .sheet(item: $pendingConfirm) { selected in
                confirmDialog(selected)
            }
        }
        .task {
            await loadQuotes()
        }
    }

    // MARK: - Subviews

    private var filterChipRow: some View {
        HStack(spacing: 8) {
            chip(label: "Last 30 days", value: 30)
            chip(label: "Last 90 days", value: 90)
            chip(label: "All time", value: 3650)
            Spacer()
        }
    }

    private func chip(label: String, value: Int) -> some View {
        Button {
            guard daysBack != value else { return }
            daysBack = value
            Task { await loadQuotes() }
        } label: {
            Text(label)
                .font(HavenTypography.caption)
                .fontWeight(.medium)
                .foregroundStyle(daysBack == value ? HavenColors.textOnAction : HavenColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 32)
                .background(
                    daysBack == value
                        ? HavenColors.action
                        : HavenColors.creamLight
                )
                .clipShape(Capsule())
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(HavenColors.creamLight.opacity(0.6))
                    .frame(height: 70)
            }
        }
    }

    private var emptyState: some View {
        FieldEmptyState(
            title: "No recent quotes",
            subtitle: daysBack == 30
                ? "No quotes in the last 30 days. Try a wider window."
                : "No quotes in your workspace history yet."
        )
    }

    private func errorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Button {
                Task { await loadQuotes() }
            } label: {
                Text("Retry")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(HavenColors.action)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.critical.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quoteList: some View {
        VStack(spacing: 8) {
            ForEach(quotes) { row in
                quoteRow(row)
            }
        }
    }

    private func quoteRow(_ row: HavenFieldQuoteSummaryRow) -> some View {
        Button {
            pendingConfirm = row
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(row.customerName)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        if row.isBundle {
                            statusPill(text: "BUNDLE", tint: HavenColors.textPrimary)
                        }
                        if row.isSigned {
                            statusPill(text: "SIGNED", tint: HavenColors.success)
                        }
                    }
                    Text(row.title)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(formattedTotal(row.total))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("·")
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("\(row.lineItemCount) item\(row.lineItemCount == 1 ? "" : "s")")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("·")
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(relativeDateLabel(row.updatedAt ?? row.createdAt))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
                statusPill(text: row.statusLabel, tint: tint(for: row.status))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(14)
            .frame(minHeight: 64)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(HavenColors.creamLight, lineWidth: 1)
            )
        }
    }

    private func statusPill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func tint(for status: String) -> Color {
        switch status {
        case "approved": return HavenColors.success
        case "declined", "withdrawn": return HavenColors.critical
        case "viewed", "sent": return HavenColors.action
        default: return HavenColors.textPrimary
        }
    }

    private func formattedTotal(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func relativeDateLabel(_ iso: String?) -> String {
        guard let iso, !iso.isEmpty, let date = isoParser.date(from: iso) else {
            return ""
        }
        return dateFormatter.localizedString(for: date, relativeTo: Date())
    }

    @ViewBuilder
    private func confirmDialog(_ selected: HavenFieldQuoteSummaryRow) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("DUPLICATE QUOTE")
                        .font(HavenTypography.uiSectionHeader)
                        .kerning(1.2)
                        .foregroundStyle(HavenColors.textSecondary)

                    Text("Duplicate quote for \(selected.customerName)?")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)

                    VStack(alignment: .leading, spacing: 10) {
                        contextRow(label: "Source", value: selected.title)
                        contextRow(label: "From", value: selected.customerName)
                        contextRow(label: "Total", value: formattedTotal(selected.total))
                        contextRow(label: "Items", value: "\(selected.lineItemCount)")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.creamLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("This creates a fresh draft for the current visit. Signature, approval, and any sent state are not copied.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.critical.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task { await confirmDuplicate(selected) }
                        } label: {
                            if isDuplicating {
                                ProgressView().tint(HavenColors.textOnAction)
                            } else {
                                Text("Duplicate quote")
                            }
                        }
                        .buttonStyle(FieldPrimaryButtonStyle())
                        .disabled(isDuplicating)

                        Button {
                            pendingConfirm = nil
                        } label: {
                            Text("Cancel")
                        }
                        .buttonStyle(FieldSecondaryButtonStyle())
                        .disabled(isDuplicating)
                    }
                }
                .padding(20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Confirm")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func contextRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func loadQuotes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            let list = try await service.listRecentQuotes(
                workspaceId: workspaceId,
                daysBack: daysBack,
                limit: 50
            )
            await MainActor.run {
                quotes = list.quotes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't load recent quotes. \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func confirmDuplicate(_ selected: HavenFieldQuoteSummaryRow) async {
        guard !targetHouseholdId.isEmpty else {
            await MainActor.run {
                errorMessage = "This visit doesn't have a household linked yet. Try a different visit."
            }
            return
        }
        await MainActor.run {
            isDuplicating = true
            errorMessage = nil
        }
        do {
            let payload = try await service.duplicateQuote(
                workspaceId: workspaceId,
                sourceQuoteId: selected.id,
                targetHouseholdId: targetHouseholdId,
                targetPropertyId: targetPropertyId,
                targetRequestId: targetRequestId
            )
            await MainActor.run {
                isDuplicating = false
                pendingConfirm = nil
                onDuplicated(payload)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDuplicating = false
                errorMessage = "Duplicate failed. \(error.localizedDescription)"
            }
        }
    }
}

/// lines, then save / send through `save_invoice` / `send_invoice`.
///
/// Discipline notes:
/// - Title row reads "Invoice draft" — never just "Invoice".
/// - Salmon stays on primary CTA + saved badge active tone only.
///   No salmon on tile backgrounds, dividers, or row decoration
///   (Section 22 B1).
/// - All states wired: loading skeleton, empty (no eligible items),
///   editor, error banner. Save / Send buttons disable on empty
///   line items + empty title (Section 22 B9 + C1).
private struct FieldBuildInvoiceSheet: View {
    let workspaceId: String
    let requestId: String
    let visit: HavenFieldVisit
    let cachedDraft: HavenFieldInvoiceDraftPayload?
    let onDraftCached: (HavenFieldInvoiceDraftPayload) -> Void
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Loading + draft state

    @State private var draftPayload: HavenFieldInvoiceDraftPayload?
    @State private var isLoadingDraft = false
    @State private var errorMessage: String?

    // MARK: - Editor state

    @State private var lineItems: [HavenFieldQuoteDraftLine] = []
    @State private var title: String = ""
    @State private var homeownerMessage: String = ""
    @State private var scopeNotes: String = ""

    // MARK: - Save / send result

    @State private var savedInvoiceId: String?
    @State private var savedInvoiceNumber: String?
    @State private var invoiceStatus: String?
    @State private var invoiceSentAt: Date?
    @State private var isSaving = false
    @State private var isSending = false

    // MARK: - Computed

    private var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.lineTotal }
    }

    /// Tax rate in percent. The schema doesn't carry a workspace tax
    /// setting yet (deferred to a future wave per Section 8.5 spec);
    /// default 0% but the field is editable so the tech can stamp a
    /// local rate at the kitchen table.
    @State private var taxRatePercent: Double = 0

    private var taxAmount: Double {
        ((subtotal * taxRatePercent) / 100.0 * 100).rounded() / 100.0
    }

    private var total: Double { subtotal + taxAmount }

    private var canSave: Bool {
        let cleaned = lineItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        // Sprint #3 R1-E-5: belt-and-suspenders check that no line item
        // has a negative unit price and tax rate is in [0, 100]. The
        // .onChange clamps catch paste-time bugs at the source; this
        // guards against a programmatic mutation slipping through.
        let allLineItemsValid = cleaned.allSatisfy { $0.unitPrice >= 0 && $0.quantity >= 0 }
        let taxValid = taxRatePercent >= 0 && taxRatePercent <= 100
        return !cleaned.isEmpty &&
            !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            allLineItemsValid &&
            taxValid &&
            !isSaving && !isSending
    }

    private var moneyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f
    }

    private var customerName: String {
        visit.property?.name ?? visit.title.fieldDisplayTitle
    }

    private var customerAddress: String {
        visit.property?.address ?? "Address on file"
    }

    private var visitDateLabel: String {
        // Mirror M4 N-9 fix: dates can be plain yyyy-MM-dd or full ISO.
        guard let routeDate = visit.routeDate, !routeDate.isEmpty else { return "Today" }
        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.dateFormat = "yyyy-MM-dd"
        if let parsed = dateOnly.date(from: routeDate) {
            let display = DateFormatter()
            display.dateFormat = "EEE MMM d"
            return display.string(from: parsed)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: routeDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: routeDate)
        }()
        guard let date else { return routeDate }
        let display = DateFormatter()
        display.dateFormat = "EEE MMM d"
        return display.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    if isLoadingDraft && draftPayload == nil {
                        loadingSkeleton
                    } else {
                        prefillCard
                        editorBody
                    }

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                }
                .padding(20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Build invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onClose()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .task {
            if let cachedDraft {
                hydrate(from: cachedDraft)
            } else if draftPayload == nil {
                await loadDraft()
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VISIT WRAP-UP")
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textSecondary)
            Text(customerName)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textSecondary)
                Text(visitDateLabel)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("·")
                    .foregroundStyle(HavenColors.textTertiary)
                FieldInvoiceDraftBadge(
                    invoiceNumber: savedInvoiceNumber,
                    sentAt: invoiceSentAt,
                    status: invoiceStatus
                )
            }
        }
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(HavenColors.creamLight.opacity(0.6))
                    .frame(height: 80)
            }
        }
    }

    @ViewBuilder
    private var prefillCard: some View {
        if let draft = draftPayload, draft.eligibleCount > 0 {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pre-filled from this visit")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("\(draft.eligibleCount) punch item\(draft.eligibleCount == 1 ? "" : "s") loaded as labor and materials lines.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Button {
                    Task { await loadDraft() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(14)
            .background(HavenColors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if draftPayload != nil {
            HStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No completed work to pre-fill")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Add line items below to invoice the visit from scratch.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Button {
                    Task { await loadDraft() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(14)
            .background(HavenColors.creamLight.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var editorBody: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title + customer block
            FieldSectionCard(kicker: "Invoice", title: "Title and recipient") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Invoice title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(HavenTypography.body)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sending to")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(customerName)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(customerAddress)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Line items list with reorder support
            lineItemsSection

            // Tax row + scope notes + homeowner message
            taxAndNotesSection

            // Totals + actions
            totalsCard
            actionRow
        }
    }

    /// Wave M5 — line items list. Each line is a `FieldQuoteLineItemRow`
    /// reused from M4 (same shape, same editor primitives). `onMove`
    /// gives the tech drag-to-reorder so they can group materials with
    /// labor at the kitchen table.
    private var lineItemsSection: some View {
        FieldSectionCard(kicker: "Line items", title: "What's on the invoice") {
            VStack(alignment: .leading, spacing: 10) {
                if lineItems.isEmpty {
                    Text("No items yet. Tap + to add one.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach($lineItems) { $line in
                        FieldQuoteLineItemRow(
                            line: $line,
                            moneyFormatter: moneyFormatter,
                            onDelete: {
                                lineItems.removeAll { $0.id == line.id }
                            }
                        )
                    }
                    .onMove { indices, dest in
                        lineItems.move(fromOffsets: indices, toOffset: dest)
                    }
                }
                Button {
                    lineItems.append(
                        HavenFieldQuoteDraftLine(name: "", description: "", unit: "ea", quantity: 1, unitPrice: 0)
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(HavenColors.action)
                        Text("Add line")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.action)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
    }

    private var taxAndNotesSection: some View {
        FieldSectionCard(kicker: "Tax and notes", title: "Tax rate and homeowner message") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Tax rate")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("0", value: $taxRatePercent, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                            .padding(8)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            // Sprint #3 R1-E-5: clamp to 0-100. Decimal
                            // pad accepts a pasted negative or a "9999"
                            // typo that would silently bill the homeowner
                            // millions in tax. 100% is the absolute cap
                            // since percentages above 100 don't make sense.
                            .onChange(of: taxRatePercent) { _, newValue in
                                if newValue < 0 { taxRatePercent = 0 }
                                else if newValue > 100 { taxRatePercent = 100 }
                            }
                        Text("%")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Scope of work (optional)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextField(
                        "What was completed during the visit...",
                        text: $scopeNotes,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .font(HavenTypography.body)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note to customer (optional)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    TextField(
                        "Thanks for letting us into your home today...",
                        text: $homeownerMessage,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .font(HavenTypography.body)
                }
            }
        }
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subtotal")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(formatMoney(subtotal))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .monospacedDigit()
            }
            HStack {
                Text("Tax (\(formatPercent(taxRatePercent)))")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(formatMoney(taxAmount))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .monospacedDigit()
            }
            Divider()
            HStack {
                Text("Total")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Text(formatMoney(total))
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Wave M5 — Save draft / Send to customer / Print here. The
    /// "Print here" button opens the iOS share sheet with a plain-
    /// text invoice transcript so the homeowner can AirDrop / Mail
    /// / Print from the OS-native share menu. Full PDF rendering is
    /// deferred to the Operations Desk's print route (already shipped).
    private var actionRow: some View {
        VStack(spacing: 10) {
            Button {
                Task { await save(send: false) }
            } label: {
                if isSaving && !isSending {
                    ProgressView().tint(HavenColors.textOnAction)
                } else {
                    Text("Save as draft")
                }
            }
            .buttonStyle(FieldSecondaryButtonStyle())
            .disabled(!canSave)

            Button {
                Task { await save(send: true) }
            } label: {
                if isSending {
                    ProgressView().tint(HavenColors.textOnAction)
                } else {
                    Text("Send to customer")
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())
            .disabled(!canSave)

            // "Print here" — share-sheet route. Only wires up once
            // we have something to share (saved or pre-filled lines).
            if let summary = printSummary {
                ShareLink(item: summary, subject: Text(title.isEmpty ? "Invoice" : title)) {
                    HStack(spacing: 8) {
                        Image(systemName: "printer")
                        Text("Print or share")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(HavenColors.textPrimary)
                }
                .accessibilityLabel("Print or share the invoice via the iOS share sheet")
            }
        }
    }

    private var printSummary: String? {
        let cleaned = lineItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !cleaned.isEmpty else { return nil }
        var lines: [String] = []
        lines.append(title.isEmpty ? "Invoice" : title)
        if let number = savedInvoiceNumber { lines.append("Invoice #\(number)") }
        lines.append("")
        lines.append("To: \(customerName)")
        lines.append(customerAddress)
        lines.append("")
        lines.append("Visit: \(visitDateLabel)")
        lines.append("")
        lines.append("Line items:")
        for line in cleaned {
            let qty = formatQuantity(line.quantity)
            let unit = line.unit.isEmpty ? "ea" : line.unit
            let price = formatMoney(line.unitPrice)
            let lineTotal = formatMoney(line.lineTotal)
            var row = "  \(line.name): \(qty) \(unit) @ \(price) = \(lineTotal)"
            if !line.description.isEmpty {
                row += "\n    \(line.description)"
            }
            lines.append(row)
        }
        lines.append("")
        lines.append("Subtotal: \(formatMoney(subtotal))")
        if taxRatePercent > 0 {
            lines.append("Tax (\(formatPercent(taxRatePercent))): \(formatMoney(taxAmount))")
        }
        lines.append("Total: \(formatMoney(total))")
        if !scopeNotes.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append("")
            lines.append("Scope of work:")
            lines.append(scopeNotes)
        }
        if !homeownerMessage.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append("")
            lines.append("Note: \(homeownerMessage)")
        }
        return lines.joined(separator: "\n")
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(HavenColors.action)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
            Button {
                errorMessage = nil
                Task { await loadDraft() }
            } label: {
                Text("Retry")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.action)
            }
            .frame(minWidth: 60, minHeight: 44)
        }
        .padding(12)
        .background(HavenColors.action.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formatMoney(_ value: Double) -> String {
        moneyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func formatPercent(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))%" }
        return String(format: "%.2f%%", value)
    }

    private func formatQuantity(_ q: Double) -> String {
        if q == q.rounded() { return String(format: "%.0f", q) }
        return String(format: "%.2f", q)
    }

    private func hydrate(from draft: HavenFieldInvoiceDraftPayload) {
        draftPayload = draft
        lineItems = draft.lineItems
        title = draft.title
    }

    // MARK: - Network

    private func loadDraft() async {
        guard !workspaceId.isEmpty, !requestId.isEmpty else {
            errorMessage = "Visit identifier missing."
            return
        }
        errorMessage = nil
        isLoadingDraft = true
        defer { isLoadingDraft = false }
        do {
            let draft = try await HavenFieldService.shared.convertVisitToInvoice(
                workspaceId: workspaceId,
                requestId: requestId
            )
            hydrate(from: draft)
            onDraftCached(draft)
        } catch {
            errorMessage = "Couldn't pre-fill the invoice: \(error.localizedDescription)"
        }
    }

    private func save(send: Bool) async {
        guard canSave else { return }
        errorMessage = nil
        if send { isSending = true } else { isSaving = true }
        defer {
            isSaving = false
            isSending = false
        }

        do {
            let cleaned = lineItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let saved = try await HavenFieldService.shared.saveInvoice(
                workspaceId: workspaceId,
                invoiceId: savedInvoiceId,
                requestId: requestId,
                householdId: draftPayload?.householdId,
                propertyId: draftPayload?.propertyId,
                contractorId: draftPayload?.contractorId,
                title: title.trimmingCharacters(in: .whitespaces),
                homeownerMessage: homeownerMessage.trimmingCharacters(in: .whitespaces).isEmpty ? nil : homeownerMessage,
                scopeNotes: scopeNotes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : scopeNotes,
                lineItems: cleaned,
                send: send
            )
            if !saved.id.isEmpty {
                savedInvoiceId = saved.id
                savedInvoiceNumber = saved.invoiceNumber
                invoiceStatus = saved.status
                if send {
                    invoiceSentAt = Date()
                }
            }
        } catch {
            errorMessage = "Couldn't \(send ? "send" : "save") the invoice: \(error.localizedDescription)"
        }
    }
}

/// Wave M5 — small status pill on the BuildInvoiceSheet header.
/// Shows "Invoice draft" until a save round-trip lands a number,
/// then the invoice number, then "Sent" after send_invoice. Mirrors
/// `FieldQuoteDraftBadge`.
private struct FieldInvoiceDraftBadge: View {
    let invoiceNumber: String?
    let sentAt: Date?
    let status: String?

    var body: some View {
        let label: String
        let tone: Color
        if sentAt != nil || status == "sent" {
            label = "Sent"
            tone = HavenColors.success
        } else if let number = invoiceNumber {
            label = number
            tone = HavenColors.action
        } else {
            label = "Invoice draft"
            tone = HavenColors.textSecondary
        }
        return Text(label)
            .font(HavenTypography.caption)
            .foregroundStyle(tone)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tone.opacity(0.12))
            .clipShape(Capsule())
    }
}

/// Wave M4 — finger-drawn signature pad. Wraps PencilKit's
/// `PKCanvasView` in a SwiftUI `UIViewRepresentable` so the field
/// tech can hand the iPad to the customer for a thumb-pen signature.
/// Captures the canvas as a PNG and routes through `sign_quote`.
///
/// Discipline notes:
/// - Strokes are dark indigo (HavenColors.textPrimary), NEVER salmon
///   — salmon is reserved for primary CTAs per Section 22 B1.
/// - The canvas height is fixed at 200pt (~50% of common iPad portrait
///   width) so there's no awkward zoom on tablets.
/// - Submit is gated on a non-empty signed name AND at least one
///   stroke; both validation errors render visibly.
private struct FieldQuoteSignaturePad: View {
    let workspaceId: String
    let quoteId: String
    let customerName: String
    @Binding var isSigning: Bool
    let onSigned: (HavenFieldSignedQuote) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var canvasView = PKCanvasView()
    @State private var signedName: String = ""
    @State private var signerRole: String = "homeowner"
    @State private var hasStrokes = false
    @State private var validationError: String?
    @State private var submissionError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HAVE CUSTOMER SIGN")
                            .font(HavenTypography.uiSectionHeader)
                            .kerning(1.2)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Hand them the iPad")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("They sign with their finger. The signature uploads with the quote so we have it on file.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Signed name")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        TextField("Customer name", text: $signedName)
                            .textFieldStyle(.roundedBorder)
                            .font(HavenTypography.body)
                            .autocorrectionDisabled()
                            .onAppear {
                                if signedName.isEmpty {
                                    signedName = customerName
                                }
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Signed by")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)
                        Picker("Role", selection: $signerRole) {
                            Text("Homeowner").tag("homeowner")
                            Text("Witness").tag("witness")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Signature")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Button {
                                canvasView.drawing = PKDrawing()
                                hasStrokes = false
                            } label: {
                                Text("Clear")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.action)
                            }
                            .frame(minWidth: 44, minHeight: 32)
                        }
                        FieldSignatureCanvas(
                            canvasView: $canvasView,
                            hasStrokes: $hasStrokes
                        )
                        .frame(height: 200)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(HavenColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let validationError {
                        Text(validationError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }
                    if let submissionError {
                        Text(submissionError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.action)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isSigning {
                            HStack(spacing: 8) {
                                ProgressView().tint(HavenColors.textOnAction)
                                Text("Submitting...")
                            }
                        } else {
                            Text("Submit signature")
                        }
                    }
                    .buttonStyle(FieldPrimaryButtonStyle())
                    .disabled(isSigning)
                }
                .padding(20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
    }

    private func submit() async {
        validationError = nil
        submissionError = nil

        let trimmedName = signedName.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            validationError = "Type the customer's name above."
            return
        }
        if !hasStrokes {
            validationError = "Have the customer draw a signature first."
            return
        }

        // Render the canvas to a PNG. Use the canvas bounds with white
        // background so the upload is a clean rectangle ready for inline
        // rendering on the operator desk + homeowner inbox.
        let bounds = canvasView.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            validationError = "Couldn't render signature. Try again."
            return
        }
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            canvasView.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        guard let pngData = image.pngData() else {
            validationError = "Couldn't encode signature. Try again."
            return
        }
        let base64 = pngData.base64EncodedString()

        isSigning = true
        defer { isSigning = false }

        do {
            let signed = try await HavenFieldService.shared.signQuote(
                workspaceId: workspaceId,
                quoteId: quoteId,
                signatureBase64: base64,
                signedName: trimmedName,
                signerRole: signerRole
            )
            onSigned(signed)
            dismiss()
        } catch {
            submissionError = "Couldn't submit signature: \(error.localizedDescription)"
        }
    }
}

/// SwiftUI wrapper for PencilKit's `PKCanvasView`. Tracks a binding so
/// the parent view can detect "are there any strokes yet?" without
/// polling. The delegate fires on every stroke change.
private struct FieldSignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var hasStrokes: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: UIColor(HavenColors.textPrimary), width: 2.5)
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No-op — the canvas drives itself via the user's gestures.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: FieldSignatureCanvas
        init(parent: FieldSignatureCanvas) {
            self.parent = parent
        }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async {
                self.parent.hasStrokes = !canvasView.drawing.strokes.isEmpty
            }
        }
    }
}

// MARK: - Wave M8 end-of-visit suggestion authoring

/// Local model: one staged suggestion in the wizard's queue. We keep
/// these client-side until the tech taps Done; then they get flushed
/// to the server via the three M8 actions (suggest_followup_task /
/// suggest_followup_quote / schedule_followup_visit). Identifiable so
/// SwiftUI diffing keeps the queue rows stable as the tech edits.
struct FieldEndOfVisitSuggestion: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case task
        case quote
        case visit
    }
    var id: UUID = UUID()
    var kind: Kind
    var title: String
    var detail: String?
    /// Task-only: ISO date string ("yyyy-MM-dd"), nil for "no specific date".
    var dueDate: String?
    /// Visit-only: proposed arrival as an ISO-8601 timestamp.
    var proposedDate: Date?
    /// Visit-only: visit duration estimate in minutes.
    var durationMinutes: Int?

    /// True after the suggestion has been flushed to the server. Lets
    /// the queue render a check + grays out the Remove button.
    var sent: Bool = false
}

/// Persisted draft shape for E1 background → foreground state preservation.
private struct FieldEndOfVisitWizardDraft: Codable, Equatable {
    var observation: String
    var queue: [FieldEndOfVisitSuggestion]

    static let empty = FieldEndOfVisitWizardDraft(observation: "", queue: [])
}

/// Wave M8 — the end-of-visit suggestion authoring wizard. Fires
/// automatically the FIRST time the lifecycle flips into `.completed`
/// (and from a secondary "Send follow-up suggestions" CTA below the
/// completed-state Build quote button). Three artifact types:
///   • Task — drives a `maintenance_tasks` row + thread audit message
///   • Quote — opens M4's `FieldBuildQuoteSheet` over a pre-created
///     draft `provider_quotes` row
///   • Visit — drives a fresh `handyman_requests` row pre-stamped with
///     a `provider_visit_assignments` slot for the suggesting tech
///
/// Discipline:
///   • Done is the only salmon (primary CTA) on the screen
///   • Skip is a clearly-secondary text button at the bottom
///   • All state preserved through E1 background → foreground via
///     AppStorage-backed JSON binding from the parent
///   • Empty observation submits OK (suggestions are the value), but
///     adding a task with empty title fires inline validation
///   • Min ≥ 44pt tap targets on every chip + every queue row's
///     Remove button (D7 / B6)
private struct FieldEndOfVisitWizard: View {
    let workspaceId: String
    let requestId: String
    let visit: HavenFieldVisit
    /// Two-way binding to the parent's JSON-string AppStorage cache.
    /// Wizard hydrates from this on appear and writes through on every
    /// queue / observation change so background → foreground (E1)
    /// preserves mid-wizard state.
    @Binding var draftJsonBinding: String
    /// Called when a suggested quote is finalized server-side. The
    /// parent dismisses the wizard and pushes M4's BuildQuoteSheet over
    /// the freshly-created draft so the tech can finish the line items
    /// + signature inline.
    let onOpenQuoteDraft: (String) -> Void
    /// Called when the tech taps Done (didSave=true) or Skip (false).
    let onDismiss: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form state

    @State private var observation: String = ""
    @State private var queue: [FieldEndOfVisitSuggestion] = []

    /// Which "Add" inline picker is open. Drives the conditional-render
    /// of the form below the chip row.
    private enum AddingMode: String { case none, task, quote, visit }
    @State private var addingMode: AddingMode = .none

    // MARK: - Add-task form state
    @State private var newTaskTitle: String = ""
    @State private var newTaskDetail: String = ""
    @State private var newTaskDueDate: Date = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
    @State private var newTaskUseDueDate: Bool = false
    @State private var newTaskValidationError: String? = nil

    // MARK: - Add-quote form state
    @State private var newQuoteTitle: String = ""
    @State private var newQuoteScopeNotes: String = ""
    @State private var newQuoteValidationError: String? = nil

    // MARK: - Add-visit form state
    @State private var newVisitTitle: String = ""
    @State private var newVisitDetails: String = ""
    @State private var newVisitDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var newVisitDurationMinutes: Int = 60
    @State private var newVisitValidationError: String? = nil

    // MARK: - Submit state

    @State private var isSubmitting: Bool = false
    @State private var submitError: String? = nil

    /// Templated task suggestions — quick-pick chips above the free-form
    /// title field. Tapping one fills the title + leaves the detail
    /// editable. Templates aren't substantive enough to warrant a
    /// separate sheet flow; they're just keyboard-savings.
    private static let taskTemplates: [String] = [
        "Replace HVAC filter in 90 days",
        "Reseal the valve before next service",
        "Annual furnace tune-up",
        "Inspect water heater anode rod",
        "Replace smoke detector batteries",
        "Service the well pressure tank"
    ]

    private var quickSlots: [Date] {
        // Tomorrow 9am, day-after 1pm, three days out 9am — same heuristic
        // as the M6 reschedule sheet so the tech reads a familiar pattern.
        let cal = Calendar.current
        let now = Date()
        let candidates: [(Int, Int)] = [(1, 9), (2, 13), (4, 9)]
        return candidates.compactMap { dayOffset, hour in
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: now) else { return nil }
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)
        }
    }

    private var slotFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d 'at' h:mm a"
        return f
    }

    private var canSubmit: Bool {
        !observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !queue.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    promptHeader
                    observationField
                    chipRow
                    addingForm
                    queueSection
                    submitSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Wrap-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") {
                        // Don't fire the Done flush — Skip means the
                        // tech wants to bail without sending anything.
                        clearPersistedDraft()
                        onDismiss(false)
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .task {
                hydrateFromBinding()
            }
            .onChange(of: observation) { _, _ in
                persistDraft()
            }
            .onChange(of: queue) { _, _ in
                persistDraft()
            }
        }
    }

    // MARK: - Prompt header

    private var promptHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ANYTHING TO FOLLOW UP ON?")
                .font(HavenTypography.uiSectionHeader)
                .kerning(1.2)
                .foregroundStyle(HavenColors.textSecondary)
            Text("Wrap up your visit")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Add anything you noticed, or stage follow-up work for the homeowner. They'll see your suggestions in their app.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Observation field

    private var observationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observation")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            TextField(
                "e.g. Boiler relief valve is starting to weep. Recommend replacement next service.",
                text: $observation,
                axis: .vertical
            )
            .lineLimit(3...8)
            .font(HavenTypography.body)
            .foregroundStyle(HavenColors.textPrimary)
            .padding(12)
            .background(HavenColors.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HavenColors.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Text("Saved with the visit notes. The homeowner sees this in their thread.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stage follow-ups")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            // 3 chips: tap to expand a small inline form below.
            HStack(spacing: 8) {
                addChip(label: "+ Task", systemImage: "checklist", mode: .task)
                addChip(label: "+ Quote", systemImage: "doc.text", mode: .quote)
                addChip(label: "+ Visit", systemImage: "calendar.badge.plus", mode: .visit)
            }
        }
    }

    private func addChip(label: String, systemImage: String, mode: AddingMode) -> some View {
        Button {
            // Toggle the form open / closed. Tapping the active chip
            // closes the form (lets the tech back out without scrolling).
            if addingMode == mode {
                addingMode = .none
            } else {
                addingMode = mode
                // Reset the new-row form state every open so previously-
                // typed text doesn't carry over from a prior chip session.
                resetNewRowState(for: mode)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(HavenTypography.uiButton)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(addingMode == mode ? HavenColors.navy800.opacity(0.08) : HavenColors.surface)
            .foregroundStyle(HavenColors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(addingMode == mode ? HavenColors.navy800 : HavenColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private func resetNewRowState(for mode: AddingMode) {
        switch mode {
        case .task:
            newTaskTitle = ""
            newTaskDetail = ""
            newTaskUseDueDate = false
            newTaskDueDate = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
            newTaskValidationError = nil
        case .quote:
            newQuoteTitle = ""
            newQuoteScopeNotes = observation
            newQuoteValidationError = nil
        case .visit:
            newVisitTitle = ""
            newVisitDetails = ""
            newVisitDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            newVisitDurationMinutes = 60
            newVisitValidationError = nil
        case .none:
            break
        }
    }

    // MARK: - Adding form

    @ViewBuilder
    private var addingForm: some View {
        switch addingMode {
        case .none:
            EmptyView()
        case .task:
            addTaskForm
        case .quote:
            addQuoteForm
        case .visit:
            addVisitForm
        }
    }

    private var addTaskForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New follow-up task")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)

            // Quick-pick templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.taskTemplates, id: \.self) { template in
                        Button {
                            newTaskTitle = template
                            newTaskValidationError = nil
                        } label: {
                            Text(template)
                                .font(HavenTypography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minHeight: 36)
                                .background(HavenColors.surface)
                                .foregroundStyle(HavenColors.textPrimary)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("Task title (e.g. Replace boiler relief valve)", text: $newTaskTitle)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                    newTaskValidationError != nil ? HavenColors.action : HavenColors.border,
                    lineWidth: 1
                ))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                // N-validation-stale-render fix: clear the validation
                // error as soon as the user starts typing the title.
                .onChange(of: newTaskTitle) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        newTaskValidationError = nil
                    }
                }

            if let error = newTaskValidationError {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.action)
            }

            TextField("Detail (optional)", text: $newTaskDetail, axis: .vertical)
                .lineLimit(2...4)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Toggle("Specific due date", isOn: $newTaskUseDueDate)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .tint(HavenColors.navy800)
            if newTaskUseDueDate {
                DatePicker("Due", selection: $newTaskDueDate, in: Date()..., displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            HStack(spacing: 10) {
                Button("Add to list") {
                    addTaskToQueue()
                }
                .buttonStyle(FieldSecondaryButtonStyle())
                Button("Cancel") {
                    addingMode = .none
                }
                .buttonStyle(FieldGhostButtonStyle())
            }
        }
        .padding(14)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var addQuoteForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New quote draft")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            Text("Stage a quote draft now and finish the line items in the quote builder. The customer doesn't see anything until you send.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)

            TextField("Quote title (e.g. Boiler relief valve replacement)", text: $newQuoteTitle)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                    newQuoteValidationError != nil ? HavenColors.action : HavenColors.border,
                    lineWidth: 1
                ))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                // N-validation-stale-render fix: clear the validation
                // error as soon as the user starts typing.
                .onChange(of: newQuoteTitle) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        newQuoteValidationError = nil
                    }
                }

            if let error = newQuoteValidationError {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.action)
            }

            TextField("Scope notes (optional)", text: $newQuoteScopeNotes, axis: .vertical)
                .lineLimit(2...5)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                Button("Add to list") {
                    addQuoteToQueue()
                }
                .buttonStyle(FieldSecondaryButtonStyle())
                Button("Cancel") {
                    addingMode = .none
                }
                .buttonStyle(FieldGhostButtonStyle())
            }
        }
        .padding(14)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var addVisitForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule a follow-up visit")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
            Text("Pick a quick slot or set a custom time. Adds the visit to your route.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)

            TextField("Visit title (e.g. Boiler relief valve replacement)", text: $newVisitTitle)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                    newVisitValidationError != nil ? HavenColors.action : HavenColors.border,
                    lineWidth: 1
                ))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                // N-validation-stale-render fix: clear the validation
                // error as soon as the user starts typing.
                .onChange(of: newVisitTitle) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        newVisitValidationError = nil
                    }
                }

            if let error = newVisitValidationError {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.action)
            }

            // Quick-pick slots
            VStack(spacing: 6) {
                ForEach(quickSlots, id: \.self) { slot in
                    Button {
                        newVisitDate = slot
                    } label: {
                        HStack {
                            Image(systemName: abs(slot.timeIntervalSince(newVisitDate)) < 60 ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(abs(slot.timeIntervalSince(newVisitDate)) < 60 ? HavenColors.navy800 : HavenColors.textSecondary)
                            Text(slotFormatter.string(from: slot))
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minHeight: 44)
                        .background(abs(slot.timeIntervalSince(newVisitDate)) < 60 ? HavenColors.navy800.opacity(0.06) : HavenColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(abs(slot.timeIntervalSince(newVisitDate)) < 60 ? HavenColors.navy800 : HavenColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            DatePicker("Or pick exact time", selection: $newVisitDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)

            HStack(spacing: 12) {
                Text("Duration")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                Picker("Duration", selection: $newVisitDurationMinutes) {
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("1 hr").tag(60)
                    Text("1.5 hr").tag(90)
                    Text("2 hr").tag(120)
                }
                .pickerStyle(.segmented)
            }

            TextField("Details (optional)", text: $newVisitDetails, axis: .vertical)
                .lineLimit(2...4)
                .font(HavenTypography.body)
                .padding(12)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                Button("Add to list") {
                    addVisitToQueue()
                }
                .buttonStyle(FieldSecondaryButtonStyle())
                Button("Cancel") {
                    addingMode = .none
                }
                .buttonStyle(FieldGhostButtonStyle())
            }
        }
        .padding(14)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Queue section

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Suggestions queue")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                if !queue.isEmpty {
                    Text("\(queue.count) staged")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            if queue.isEmpty {
                Text("No follow-ups yet.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(queue) { item in
                        queueRow(for: item)
                    }
                }
            }
        }
    }

    private func queueRow(for item: FieldEndOfVisitSuggestion) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kindIcon(item.kind))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(HavenColors.navy800)
                .frame(width: 28, height: 28)
                .background(HavenColors.navy800.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                HStack(spacing: 6) {
                    Text(kindLabel(item.kind))
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.beige200)
                        .clipShape(Capsule())
                    if let due = item.dueDate {
                        Text("Due \(due)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let proposed = item.proposedDate {
                        Text(slotFormatter.string(from: proposed))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if item.sent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HavenColors.success)
                            .font(.system(size: 12))
                    }
                }
            }
            Spacer()
            if !item.sent {
                Button {
                    queue.removeAll { $0.id == item.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove suggestion")
            }
        }
        .padding(12)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func kindIcon(_ kind: FieldEndOfVisitSuggestion.Kind) -> String {
        switch kind {
        case .task: return "checklist"
        case .quote: return "doc.text"
        case .visit: return "calendar.badge.plus"
        }
    }

    private func kindLabel(_ kind: FieldEndOfVisitSuggestion.Kind) -> String {
        switch kind {
        case .task: return "TASK"
        case .quote: return "QUOTE"
        case .visit: return "VISIT"
        }
    }

    // MARK: - Submit section

    private var submitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = submitError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(HavenColors.action)
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button("Retry") {
                        submitError = nil
                        Task { await submitAll() }
                    }
                    .buttonStyle(FieldSecondaryButtonStyle(compact: true))
                }
                .padding(12)
                .background(HavenColors.action.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                Task { await submitAll() }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(HavenColors.textOnAction)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    // B3 fix: em-dash → period + space. CTA reads as
                    // "Done. Send suggestions" without the AI-flavored
                    // dash typography.
                    Text(isSubmitting ? "Sending…" : "Done. Send suggestions")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(FieldPrimaryButtonStyle())
            .disabled(isSubmitting || !canSubmit)

            if !canSubmit {
                Text("Add an observation or stage at least one follow-up to send.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    // MARK: - Add → queue

    private func addTaskToQueue() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // C1 — empty submit fires inline validation. Salmon border
            // on the title field + a one-line message below it.
            newTaskValidationError = "Add a task title before staging."
            return
        }
        let dueIso: String?
        if newTaskUseDueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dueIso = formatter.string(from: newTaskDueDate)
        } else {
            dueIso = nil
        }
        let item = FieldEndOfVisitSuggestion(
            kind: .task,
            title: trimmed,
            detail: newTaskDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newTaskDetail,
            dueDate: dueIso,
            proposedDate: nil,
            durationMinutes: nil
        )
        queue.append(item)
        addingMode = .none
    }

    private func addQuoteToQueue() {
        let trimmed = newQuoteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            newQuoteValidationError = "Add a quote title before staging."
            return
        }
        let item = FieldEndOfVisitSuggestion(
            kind: .quote,
            title: trimmed,
            detail: newQuoteScopeNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newQuoteScopeNotes,
            dueDate: nil,
            proposedDate: nil,
            durationMinutes: nil
        )
        queue.append(item)
        addingMode = .none
    }

    private func addVisitToQueue() {
        let trimmed = newVisitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            newVisitValidationError = "Add a visit title before staging."
            return
        }
        let item = FieldEndOfVisitSuggestion(
            kind: .visit,
            title: trimmed,
            detail: newVisitDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newVisitDetails,
            dueDate: nil,
            proposedDate: newVisitDate,
            durationMinutes: newVisitDurationMinutes
        )
        queue.append(item)
        addingMode = .none
    }

    // MARK: - Submit all

    private func submitAll() async {
        guard !isSubmitting else { return }
        guard canSubmit else { return }
        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        // 1. The observation lands as an internal tech note (workspace
        //    only) — same M6 surface, no new edge fn needed. Skip the
        //    write if the field is empty.
        let trimmedObservation = observation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedObservation.isEmpty {
            do {
                _ = try await HavenFieldService.shared.addTechNote(
                    workspaceId: workspaceId,
                    requestId: requestId,
                    body: "Observation: \(trimmedObservation)"
                )
            } catch {
                submitError = friendlyServerError(from: error, fallback: "Couldn't save your observation. Tap Retry.")
                return
            }
        }

        // 2. Walk the queue. Order doesn't matter for correctness, but
        //    we send tasks first (lightest), then quotes, then visits
        //    (heaviest — touches the calendar). Sent items get marked
        //    so the queue row renders a check + the Remove button
        //    disappears. If a single item fails, we surface the error
        //    + bail; the user can Retry to flush the rest.
        var openedQuoteId: String? = nil
        for index in queue.indices where !queue[index].sent {
            let item = queue[index]
            do {
                switch item.kind {
                case .task:
                    _ = try await HavenFieldService.shared.suggestFollowupTask(
                        workspaceId: workspaceId,
                        requestId: requestId,
                        title: item.title,
                        description: item.detail,
                        dueDate: item.dueDate
                    )
                case .quote:
                    let quoteId = try await HavenFieldService.shared.suggestFollowupQuote(
                        workspaceId: workspaceId,
                        requestId: requestId,
                        title: item.title,
                        scopeNotes: item.detail
                    )
                    openedQuoteId = quoteId
                case .visit:
                    guard let proposed = item.proposedDate else {
                        submitError = "One of the visits is missing a proposed time."
                        return
                    }
                    _ = try await HavenFieldService.shared.scheduleFollowupVisit(
                        workspaceId: workspaceId,
                        requestId: requestId,
                        proposedDate: proposed,
                        durationMinutes: item.durationMinutes ?? 60,
                        title: item.title,
                        details: item.detail
                    )
                }
                queue[index].sent = true
            } catch {
                submitError = friendlyServerError(from: error, fallback: "Couldn't send a suggestion. Tap Retry to send the rest.")
                return
            }
        }

        // 3. All sent. Clear persisted draft (E1 cache no longer
        //    needed) and dismiss with `didSave=true` so the parent
        //    fires the success banner.
        clearPersistedDraft()

        // If the tech staged at least one quote, hand off to M4's
        // BuildQuoteSheet over the most recent draft so they can finish
        // the line items + signature inline.
        if let quoteId = openedQuoteId {
            onOpenQuoteDraft(quoteId)
        } else {
            onDismiss(true)
        }
        dismiss()
    }

    // MARK: - Persistence

    private func hydrateFromBinding() {
        let raw = draftJsonBinding
        guard !raw.isEmpty, let data = raw.data(using: .utf8) else { return }
        do {
            let draft = try JSONDecoder().decode(FieldEndOfVisitWizardDraft.self, from: data)
            observation = draft.observation
            queue = draft.queue
        } catch {
            // Corrupt cache — wipe it so the next persist starts clean.
            draftJsonBinding = ""
        }
    }

    private func persistDraft() {
        let draft = FieldEndOfVisitWizardDraft(observation: observation, queue: queue)
        guard let data = try? JSONEncoder().encode(draft),
              let raw = String(data: data, encoding: .utf8) else { return }
        draftJsonBinding = raw
    }

    private func clearPersistedDraft() {
        draftJsonBinding = ""
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
    /// Wave M3 — optional workspace context. When present we render the
    /// inline action row + status pills + voice memo affordance.
    var workspaceId: String? = nil
    /// Wave M3 — callback fired after a system mutation that should
    /// re-render the parent's row (voice memo attached).
    var onChanged: ((HavenFieldHomeSystem) -> Void)? = nil
    /// Wave M3 — parent invokes its decommission sheet.
    var onMarkFollowup: (() -> Void)? = nil
    var onDecommission: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    /// T1.2 (post-overnight) — Edit button reveals the inline edit form.
    /// Sheet stays in place; on save the form closes back to the detail.
    @State private var isEditing = false
    /// T3.7 (post-overnight) — Manual lookup sheet. Calls lookup-manual
    /// on present, renders the result.
    @State private var isLookingUpManual = false

    var body: some View {
        NavigationStack {
            List {
                if system.isDecommissioned {
                    Section {
                        Label {
                            Text("Removed from this home")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                        } icon: {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(HavenColors.critical)
                        }
                        if let reason = system.decommissionReason?.nonEmpty {
                            Text(reason)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                if system.needsFollowup {
                    Section {
                        Label {
                            Text("Flagged for follow-up")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.warning)
                        } icon: {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(HavenColors.warning)
                        }
                        if let reason = system.followupReason?.nonEmpty {
                            Text(reason)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

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

                if workspaceId != nil && !system.isDecommissioned {
                    Section("Field actions") {
                        // T1.2 (post-overnight) — Edit kicks off the
                        // inline edit form. A4 edit-no-duplicate guard
                        // is enforced server-side: update_home_system
                        // PATCHES the row by id, never inserts.
                        Button {
                            isEditing = true
                        } label: {
                            Label("Edit details", systemImage: "pencil")
                                .foregroundStyle(HavenColors.action)
                        }
                        // T3.7 (post-overnight) — Pull up manual /
                        // spec sheet. Calls lookup-manual edge function
                        // with the home_system_id; renders results in
                        // a sheet (cached PDF link if available, else
                        // mfr support portal). Gated on having a
                        // modelNumber so we don't open an empty search.
                        if system.modelNumber?.nonEmpty != nil {
                            Button {
                                isLookingUpManual = true
                            } label: {
                                Label("Pull up manual", systemImage: "doc.text.magnifyingglass")
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onMarkFollowup?()
                            }
                        } label: {
                            Label("Flag for follow-up", systemImage: "flag")
                                .foregroundStyle(HavenColors.warning)
                        }
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onDecommission?()
                            }
                        } label: {
                            Label("Mark as removed", systemImage: "trash")
                        }
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
            .sheet(isPresented: $isEditing) {
                if let workspaceId {
                    HavenFieldHomeSystemEditSheet(
                        system: system,
                        workspaceId: workspaceId,
                        onSaved: { updated in
                            isEditing = false
                            onChanged?(updated)
                        }
                    )
                }
            }
            .sheet(isPresented: $isLookingUpManual) {
                HavenFieldManualLookupSheet(systemId: system.id, systemName: system.name)
            }
        }
    }
}

/// T3.7 (post-overnight) — manual lookup result viewer. Calls
/// lookup-manual on appear, surfaces the result with tappable links.
/// When a cached PDF exists, the primary CTA opens it in Safari /
/// system PDF reader. Otherwise the manufacturer's support portal is
/// the fallback. Loading + error + not-found states all render with
/// helpful copy.
private struct HavenFieldManualLookupSheet: View {
    let systemId: String
    let systemName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var response: HavenFieldService.HavenFieldManualLookupResponse?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if isLoading {
                        VStack(spacing: 14) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Looking up the manual…")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else if let errorMessage {
                        FieldEmptyState(
                            title: "Couldn’t find a manual",
                            subtitle: errorMessage
                        )
                    } else if let response, response.found == true {
                        FieldSectionCard(
                            kicker: "Found",
                            title: response.modelName?.nonEmpty ?? response.modelNumber?.nonEmpty ?? systemName
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                if let manufacturer = response.manufacturer?.nonEmpty {
                                    FieldKeyValueRow(label: "Manufacturer", value: manufacturer)
                                }
                                if let model = response.modelNumber?.nonEmpty {
                                    FieldKeyValueRow(label: "Model", value: model)
                                }
                                if let manualUrl = response.manualUrl?.nonEmpty,
                                   let url = URL(string: manualUrl) {
                                    Link(destination: url) {
                                        Label("Open manual (PDF)", systemImage: "doc.text.fill")
                                            .font(HavenTypography.uiButton)
                                            .foregroundStyle(HavenColors.textOnAction)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(HavenColors.action)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                }
                                if let supportUrl = response.supportUrl?.nonEmpty,
                                   let url = URL(string: supportUrl) {
                                    Link(destination: url) {
                                        Label("Manufacturer support page", systemImage: "safari.fill")
                                            .font(HavenTypography.uiButton)
                                            .foregroundStyle(HavenColors.navy700)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(HavenColors.navy700.opacity(0.4), lineWidth: 1)
                                            )
                                    }
                                }
                                if let phone = response.supportPhone?.nonEmpty,
                                   let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })") {
                                    Link(destination: url) {
                                        Label("Support: \(phone)", systemImage: "phone.fill")
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.navy700)
                                    }
                                }
                            }
                        }
                    } else {
                        FieldEmptyState(
                            title: "No manual on file",
                            subtitle: response?.suggestion?.nonEmpty
                                ?? "Try editing the system and adding a more specific model number to widen the search."
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Manual lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await runLookup() }
    }

    private func runLookup() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            response = try await HavenFieldService.shared.lookupManual(homeSystemId: systemId)
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "We couldn’t reach the manual catalog right now.")
        }
    }
}

/// T1.2 (post-overnight) — editable form for `home_systems` rows.
/// Opens from `HavenFieldHomeSystemDetailSheet`'s "Edit details" row.
/// On save, calls `update_home_system` server-side which PATCHES the
/// existing row by id (A4 guard) — never inserts a duplicate. The
/// onSaved closure routes back to the parent so the row + sheet
/// re-render with the fresh values. Mirrors the homeowner-side
/// system-detail edit pattern but scoped to the field-app workspace
/// auth (workspace member must serve the household via at least one
/// linked contractor).

/// T2.5 (post-overnight) — capture an existing vendor the homeowner
/// uses, on the home detail Vendors sub-tab. Wires to the existing
/// create_contractor_from_card edge function action which inserts a
/// contractor row scoped to the household with source='chez_field'.
///
/// Phone is required server-side (the create_contractor_from_card
/// handler at handyman-provider:13000 throws "Phone is required" if
/// missing). Trade category goes through SystemCategoryRegistry-style
/// canonical strings to match the homeowner-side vendor coverage rule
/// (CLAUDE.md hard rule: 'Vendor coverage matches on canonical
/// categories, never exact strings.').
private struct HavenFieldAddVendorSheet: View {
    let workspaceId: String
    let householdId: String
    let onCreated: (HavenFieldHomeVendor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var companyName: String = ""
    @State private var contactName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var website: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    /// Common trade categories the field handyman is most likely to
    /// capture during an on-behalf-of assessment. Picker uses these
    /// canonical strings so the homeowner-side coverage matcher
    /// recognizes them. Free-text custom entry stays available via
    /// "Other…" → typed string saved to `category` directly.
    private let tradeOptions: [String] = [
        "HVAC", "Plumbing", "Electrical", "Landscaping", "Pest Control",
        "Pool/Spa", "Roofing", "Cleaning", "Snow Removal", "Tree Service",
        "Septic", "Well", "Chimney", "Handyman", "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Vendor") {
                    TextField("Company name", text: $companyName)
                        .textInputAutocapitalization(.words)
                    TextField("Contact name (optional)", text: $contactName)
                        .textInputAutocapitalization(.words)
                }

                Section("Trade") {
                    Picker("Category", selection: $category) {
                        Text("Pick a trade").tag("")
                        ForEach(tradeOptions, id: \.self) { trade in
                            Text(trade).tag(trade)
                        }
                    }
                }

                Section("Contact") {
                    TextField("Phone (required)", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Website (optional)", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Notes (optional)") {
                    TextField("e.g. emergency-only / weekly mow / installed water heater 2023", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Add a vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedCategory = trimmedCategory == "Other" ? "" : trimmedCategory
            let vendor = try await HavenFieldService.shared.createVendorForHome(
                workspaceId: workspaceId,
                householdId: householdId,
                companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                contactName: contactName.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
                website: website.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
                tradeCategory: resolvedCategory.nonEmpty,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
            )
            if let vendor {
                onCreated(vendor)
            }
            dismiss()
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "Couldn’t add the vendor. Please try again.")
        }
    }
}

private struct HavenFieldHomeSystemEditSheet: View {
    let system: HavenFieldHomeSystem
    let workspaceId: String
    let onSaved: (HavenFieldHomeSystem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var manufacturer: String
    @State private var modelNumber: String
    @State private var serialNumber: String
    @State private var installDate: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        system: HavenFieldHomeSystem,
        workspaceId: String,
        onSaved: @escaping (HavenFieldHomeSystem) -> Void
    ) {
        self.system = system
        self.workspaceId = workspaceId
        self.onSaved = onSaved
        _name = State(initialValue: system.name)
        _manufacturer = State(initialValue: system.manufacturer ?? "")
        _modelNumber = State(initialValue: system.modelNumber ?? "")
        _serialNumber = State(initialValue: system.serialNumber ?? "")
        _installDate = State(initialValue: system.installDate ?? "")
        _notes = State(initialValue: system.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("System") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    if let category = system.category?.nonEmpty {
                        LabeledContent("Category", value: category)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Section("Identity") {
                    TextField("Manufacturer", text: $manufacturer)
                        .textInputAutocapitalization(.words)
                    TextField("Model number", text: $modelNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Serial number", text: $serialNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Install date (YYYY-MM-DD, optional)", text: $installDate)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                }

                Section("Notes") {
                    TextField("Anything worth noting for the homeowner", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Edit system")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            // Send only fields the user actually filled in (or cleared
            // intentionally). Empty string clears; nil omits — server
            // honors both. We always send name since it's required.
            let updated = try await HavenFieldService.shared.updateHomeSystem(
                workspaceId: workspaceId,
                systemId: system.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
                modelNumber: modelNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                installDate: installDate.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if let updated {
                onSaved(updated)
            }
            dismiss()
        } catch {
            errorMessage = friendlyServerError(from: error, fallback: "Couldn’t save changes. Please try again.")
        }
    }
}

// MARK: - Wave M3 — system inventory authoring components

/// Wave M3 — system row variant with FOLLOW-UP / REMOVED status pills
/// and a dim treatment when the system has been decommissioned. Drops
/// into the same scrollable list slot the legacy FieldCompactSystemRow
/// occupies on the homeowner-side Property tab; both surfaces stay in
/// sync because both render off `home_systems` rows directly.
private struct FieldM3SystemRow: View {
    let system: HavenFieldHomeSystem
    let showFollowupBadge: Bool
    let showRemovedBadge: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(system.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(system.isDecommissioned ? HavenColors.textSecondary : HavenColors.textPrimary)
                        .strikethrough(system.isDecommissioned, color: HavenColors.textSecondary)
                    if showRemovedBadge {
                        statusPill(label: "REMOVED", color: HavenColors.critical)
                    } else if showFollowupBadge {
                        statusPill(label: "FOLLOW-UP", color: HavenColors.warning)
                    }
                    Spacer()
                }
                Text(detailLine)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                if system.hasIncompleteIdentity, !system.isDecommissioned {
                    // Section 22 B1 fix: salmon (action) was decorating an
                    // inactive list-row caption — out of bounds. textSecondary
                    // for muted info; the tap affordance to fix is the
                    // chevron + the row tap, not the caption color.
                    Text("Missing model plate details")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if system.voiceNotePath?.nonEmpty != nil {
                    Label("Voice memo on file", systemImage: "waveform")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HavenColors.beige400)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(system.isDecommissioned ? 0.55 : 1.0)
    }

    private var detailLine: String {
        let parts = [
            system.category?.nonEmpty,
            system.manufacturer?.nonEmpty,
            system.modelNumber?.nonEmpty
        ].compactMap { $0 }
        if parts.isEmpty {
            return "Tap to add brand and model details."
        }
        return parts.joined(separator: " • ")
    }

    private func statusPill(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

/// Wave M3 — decommission reason picker. Mirrors the four-option set
/// from the original spec; tech can also free-text the reason.
private struct HavenFieldDecommissionSheet: View {
    let system: HavenFieldHomeSystem
    var onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String = "Replaced"
    @State private var customReason: String = ""

    private static let reasons = [
        "Replaced",
        "Removed",
        "Damaged beyond repair",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Mark \(system.name) as removed?")
                        .font(HavenTypography.headline)
                    Text("The homeowner sees the system disappear from their list. We keep the service history on file for context.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Section("Why is it gone?") {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(Self.reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                if selectedReason == "Other" {
                    Section("Notes") {
                        TextField("Short note for the homeowner", text: $customReason, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            .navigationTitle("Mark as removed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm", role: .destructive) {
                        let reason = selectedReason == "Other"
                            ? customReason.trimmingCharacters(in: .whitespacesAndNewlines)
                            : selectedReason
                        onConfirm(reason)
                        dismiss()
                    }
                    .disabled(selectedReason == "Other" && customReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// Wave M3 — follow-up reason capture. The reason is the entire point
/// of this flow — silently accepting NULL produces useless
/// "flag for follow-up: <unknown>" rows on the next visit's prep
/// checklist. C-3 fix (2026-05-08): added inline validation that
/// matches the M1 pause modal's "Other branch validation" pattern
/// (Section 22 C1: empty submit fires visibly).
private struct HavenFieldFollowupSheet: View {
    let system: HavenFieldHomeSystem
    var onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = ""
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Flag \(system.name) for follow-up")
                        .font(HavenTypography.headline)
                    Text("We'll remind the next tech to circle back to this system on the next visit.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Section("Why couldn't you finish today?") {
                    TextField("e.g. tenant unavailable, attic locked", text: $reason, axis: .vertical)
                        .lineLimit(2...4)
                        .onChange(of: reason) { _, _ in
                            validationError = nil
                        }
                    if let validationError {
                        Text(validationError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Flag for follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Flag") {
                        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            validationError = "Tell us why so the next visit knows what to do."
                            return
                        }
                        onConfirm(trimmed)
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Wave M3 — system sweep mode. Camera-first capture of model plates
/// with an inline AI extraction confirmation flow. Falls back to a
/// debug "use test image" affordance on the simulator since the iOS
/// Simulator can't take real photos.
private struct HavenFieldSystemSweepSheet: View {
    let home: HavenFieldHome
    var workspaceId: String?
    @Binding var bulkAddedCount: Int
    var onSystemCreated: (HavenFieldHomeSystem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .ready
    @State private var capturedImage: UIImage?
    @State private var extraction: HavenFieldService.HavenFieldExtractSystemResponse?
    @State private var draftName: String = ""
    @State private var draftCategory: String = ""
    @State private var draftManufacturer: String = ""
    @State private var draftModel: String = ""
    @State private var draftSerial: String = ""
    @State private var draftNotes: String = ""
    @State private var errorMessage: String?
    @State private var isExtracting: Bool = false
    @State private var isSaving: Bool = false
    @State private var showCamera: Bool = false

    enum Stage {
        case ready, extracting, confirming, saving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    counterCard
                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.critical.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    switch stage {
                    case .ready:
                        readyStateCard
                    case .extracting:
                        extractingCard
                    case .confirming:
                        confirmCard
                    case .saving:
                        savingCard
                    }
                }
                .padding(16)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("System sweep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                HavenFieldCameraPicker { image in
                    capturedImage = image
                    Task { await runExtraction(image: image) }
                }
            }
        }
    }

    private var counterCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(home.name)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("\(bulkAddedCount) system\(bulkAddedCount == 1 ? "" : "s") added in this visit")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HavenColors.action)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var readyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snap a model plate")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Get the brand label clear in frame. We extract make, model, and serial automatically and you confirm the result before saving.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Button {
                resetDraft()
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Open camera")
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())

            #if DEBUG
            Button {
                resetDraft()
                Task { await runExtractionWithSeed() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Use test image (debug)")
                }
            }
            .buttonStyle(.bordered)
            .tint(HavenColors.action)
            #endif
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var extractingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Reading the model plate...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("This usually takes a few seconds.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var confirmCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(HavenColors.success)
                Text("Confirm system details")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            if let confidence = extraction?.confidence {
                Text("AI confidence: \(confidence.capitalized)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldRow(label: "Display name", value: $draftName, placeholder: "e.g. Furnace, attic A")
                fieldRow(label: "Category", value: $draftCategory, placeholder: "HVAC / Plumbing / etc.")
                fieldRow(label: "Manufacturer", value: $draftManufacturer, placeholder: "Brand")
                fieldRow(label: "Model number", value: $draftModel, placeholder: "Model")
                fieldRow(label: "Serial number", value: $draftSerial, placeholder: "Serial")
                fieldRow(label: "Notes", value: $draftNotes, placeholder: "Anything the homeowner should know")
            }

            HStack(spacing: 10) {
                Button("Re-shoot") {
                    resetDraft()
                    showCamera = true
                }
                .buttonStyle(.bordered)
                .tint(HavenColors.action)

                Spacer()

                Button {
                    Task { await saveSystem() }
                } label: {
                    Text(isSaving ? "Saving..." : "Save and continue")
                }
                .buttonStyle(FieldPrimaryButtonStyle())
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var savingCard: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Saving system to home record...")
                .font(HavenTypography.headline)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func fieldRow(label: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
            TextField(placeholder, text: value, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func resetDraft() {
        capturedImage = nil
        extraction = nil
        draftName = ""
        draftCategory = ""
        draftManufacturer = ""
        draftModel = ""
        draftSerial = ""
        draftNotes = ""
        errorMessage = nil
        stage = .ready
    }

    private func runExtraction(image: UIImage) async {
        guard let workspaceId, !workspaceId.isEmpty else {
            errorMessage = "Sign in to your workspace to use sweep mode."
            return
        }
        guard let data = image.jpegData(compressionQuality: 0.78) else {
            errorMessage = "Couldn't read the photo data. Please re-shoot."
            return
        }
        await postExtraction(base64: data.base64EncodedString())
    }

    #if DEBUG
    private func runExtractionWithSeed() async {
        guard let workspaceId, !workspaceId.isEmpty else {
            errorMessage = "Sign in to your workspace to use sweep mode."
            return
        }
        // Minimal valid JPEG bytes (1x1 white pixel) — identify-equipment
        // forwards to Claude Vision with media_type=image/jpeg, so we
        // need real JPEG bytes to exercise the AI path. The AI will
        // gracefully say "not identifiable" against a blank tile, which
        // is the path we want to verify on the simulator.
        let onePixel = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/APvSiiiv/9k="
        // Pre-fill the draft so the simulator-side reviewer has something
        // to confirm. Mirrors a high-confidence extraction.
        await MainActor.run {
            draftName = "Test furnace plate"
            draftCategory = "HVAC"
            draftManufacturer = "Carrier"
            draftModel = "58STA070-12"
            draftSerial = "DEBUG-\(Int.random(in: 1000...9999))"
            draftNotes = "Captured via debug seed (simulator)"
        }
        await postExtraction(base64: onePixel)
    }
    #endif

    private func postExtraction(base64: String) async {
        guard let workspaceId else { return }
        await MainActor.run {
            stage = .extracting
            isExtracting = true
            errorMessage = nil
        }
        do {
            let result = try await HavenFieldService.shared.extractSystemFromPhoto(
                workspaceId: workspaceId,
                base64: base64,
                category: nil
            )
            await MainActor.run {
                extraction = result
                if draftManufacturer.isEmpty, let m = result.manufacturer { draftManufacturer = m }
                if draftModel.isEmpty, let m = result.modelNumber { draftModel = m }
                if draftSerial.isEmpty, let s = result.serialNumber { draftSerial = s }
                if draftCategory.isEmpty, let p = result.productType { draftCategory = p.capitalized }
                if draftName.isEmpty {
                    let parts = [draftManufacturer, draftModel].filter { !$0.isEmpty }
                    draftName = parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if draftName.isEmpty { draftName = "New system" }
                }
                stage = .confirming
                isExtracting = false
            }
        } catch {
            await MainActor.run {
                stage = .ready
                isExtracting = false
                errorMessage = "Couldn't read the plate. Re-shoot or fill it in by hand."
            }
        }
    }

    private func saveSystem() async {
        guard let workspaceId, !workspaceId.isEmpty else { return }
        guard let householdId = home.householdId, !householdId.isEmpty else {
            await MainActor.run { errorMessage = "This home is missing a household id; can't save the system." }
            return
        }
        await MainActor.run {
            stage = .saving
            isSaving = true
            errorMessage = nil
        }
        do {
            let created = try await HavenFieldService.shared.createHomeSystem(
                workspaceId: workspaceId,
                propertyId: home.propertyId,
                householdId: householdId,
                name: draftName.trimmingCharacters(in: .whitespacesAndNewlines),
                category: draftCategory.nonEmpty,
                manufacturer: draftManufacturer.nonEmpty,
                modelNumber: draftModel.nonEmpty,
                serialNumber: draftSerial.nonEmpty,
                notes: draftNotes.nonEmpty
            )
            await MainActor.run {
                if let created {
                    onSystemCreated(created)
                    bulkAddedCount += 1
                }
                isSaving = false
                resetDraft()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                stage = .confirming
                errorMessage = "Save failed. Please try again."
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

// MARK: - Wave M10 — Closest customer + business card capture

/// Wave M10 — pill button used in the Homes tab toolbar row to surface
/// the two new flows. Matches the muted-chip aesthetic of FieldPunch's
/// chip bar so the row doesn't compete with the salmon CTAs elsewhere.
private struct FieldClientsToolbarPill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, 12)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Wave M10 — "Closest customer to me." Geolocates the tech, calls
/// nearest_customers, renders a top-half map + bottom-half sortable
/// list. Tap a row to recenter the map on that customer's pin.
struct FieldNearbyCustomersView: View {
    let workspaceId: String?
    let homes: [HavenFieldHome]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = FieldNearbyCustomersModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let error = model.errorMessage {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(HavenColors.critical.opacity(0.08))
                }

                mapPane
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.42)

                Divider()
                listPane
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Closest customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                guard let workspaceId else { return }
                await model.loadIfNeeded(workspaceId: workspaceId)
            }
        }
    }

    @ViewBuilder
    private var mapPane: some View {
        switch model.stage {
        case .idle, .askingPermission, .locating, .loading:
            mapPlaceholder(message: model.stageMessage)
        case .denied:
            mapPlaceholder(message: "Allow location access to find customers near you.")
        case .empty:
            mapPlaceholder(message: model.note ?? "No customers with mappable addresses yet.")
        case .ready:
            customerMap
        case .error:
            mapPlaceholder(message: model.errorMessage ?? "Something went wrong.")
        }
    }

    private var customerMap: some View {
        Map(position: $model.cameraPosition) {
            UserAnnotation()
            ForEach(model.customers) { customer in
                Marker(
                    customer.customerName.isEmpty ? "Customer" : customer.customerName,
                    systemImage: "house.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: customer.latitude,
                        longitude: customer.longitude
                    )
                )
                .tint(HavenColors.action)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    private func mapPlaceholder(message: String) -> some View {
        ZStack {
            HavenColors.surface
            // D1 fix: replace the ProgressView spinner with a beige
            // skeleton bar that pulses subtly. Same loading semantics,
            // less hospital-waiting-room vibe. The list pane underneath
            // also renders skeleton rows during these stages.
            if model.stage == .askingPermission || model.stage == .locating || model.stage == .loading {
                RoundedRectangle(cornerRadius: 16)
                    .fill(HavenColors.beige200.opacity(0.45))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 48)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 14) {
                Image(systemName: model.stage == .denied ? "location.slash.fill" : "map")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                Text(message)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if model.stage == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(HavenTypography.uiButton)
                    }
                    .buttonStyle(.bordered)
                    .tint(HavenColors.action)
                } else if model.stage == .error {
                    Button {
                        Task { await model.retry(workspaceId: workspaceId) }
                    } label: {
                        Text("Retry")
                            .font(HavenTypography.uiButton)
                    }
                    .buttonStyle(.bordered)
                    .tint(HavenColors.action)
                }
            }
        }
    }

    @ViewBuilder
    private var listPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !model.customers.isEmpty {
                    HStack {
                        Text("\(model.customers.count) nearby")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    ForEach(model.customers) { customer in
                        Button {
                            model.recenter(on: customer)
                        } label: {
                            FieldNearbyCustomerRow(customer: customer)
                        }
                        .buttonStyle(.plain)
                    }
                } else if model.stage == .ready || model.stage == .empty {
                    FieldEmptyState(
                        title: "No customers found nearby",
                        subtitle: model.note ?? "Customers with addresses on file will appear here."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                } else if model.stage == .loading || model.stage == .locating || model.stage == .askingPermission {
                    // D1 fix: skeleton placeholder while we look up
                    // addresses + reverse-geocode. Three ghost rows so
                    // the surface doesn't go blank under a spinner.
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            FieldNearbyCustomerSkeletonRow()
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

/// D1 fix — skeleton row for the M10 nearby-customers list while
/// addresses geocode. Same shape as `FieldNearbyCustomerRow` so the
/// transition into populated state doesn't reflow the layout. Three of
/// these stack in `listPane` during the loading stages.
private struct FieldNearbyCustomerSkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(HavenColors.beige200)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(HavenColors.beige200)
                    .frame(height: 14)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 4)
                    .fill(HavenColors.beige200.opacity(0.7))
                    .frame(height: 12)
                    .frame(maxWidth: 220)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 12)
                .fill(HavenColors.beige200)
                .frame(width: 56, height: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}

/// Wave M10 — list row for one nearby customer. Distance pill is on
/// the right; tapping recenters the map. Future iteration could push
/// to the home profile when the home is in the dashboard's home list.
private struct FieldNearbyCustomerRow: View {
    let customer: HavenFieldNearbyCustomer

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "house.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.customerName.isEmpty ? "Customer" : customer.customerName)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(customer.address)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(distanceLabel)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(HavenColors.surface)
                .overlay(Capsule().stroke(HavenColors.border, lineWidth: 1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var distanceLabel: String {
        let miles = Double(customer.distanceMeters) * 0.0006213712
        if miles < 0.1 { return "<0.1 mi" }
        if miles < 10 { return String(format: "%.1f mi", miles) }
        return "\(Int(miles.rounded())) mi"
    }
}

/// Wave M10 — view-model for the closest-customer flow. Owns the
/// CLLocation capture, the edge-fn call, and the map camera position
/// so the View can stay declarative.
@MainActor
final class FieldNearbyCustomersModel: ObservableObject {
    enum Stage: Equatable { case idle, askingPermission, locating, loading, denied, ready, empty, error }

    @Published var stage: Stage = .idle
    @Published var customers: [HavenFieldNearbyCustomer] = []
    @Published var note: String?
    @Published var errorMessage: String?
    @Published var cameraPosition: MapCameraPosition = .automatic
    private var lastWorkspaceId: String?
    private let locationCapture = FieldLocationCapture()

    var stageMessage: String {
        switch stage {
        case .idle: return "Tap to start finding customers near you."
        case .askingPermission: return "Allow location access to continue."
        case .locating: return "Finding your location..."
        case .loading: return "Looking up customer addresses..."
        case .denied: return "Location access denied."
        case .empty: return note ?? "No customers nearby yet."
        case .ready: return ""
        case .error: return errorMessage ?? "Something went wrong."
        }
    }

    func loadIfNeeded(workspaceId: String) async {
        if lastWorkspaceId == workspaceId && (stage == .ready || stage == .loading || stage == .locating) { return }
        lastWorkspaceId = workspaceId
        await runFlow(workspaceId: workspaceId)
    }

    func retry(workspaceId: String?) async {
        guard let workspaceId else { return }
        await runFlow(workspaceId: workspaceId)
    }

    func recenter(on customer: HavenFieldNearbyCustomer) {
        let center = CLLocationCoordinate2D(latitude: customer.latitude, longitude: customer.longitude)
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    private func runFlow(workspaceId: String) async {
        errorMessage = nil
        stage = .askingPermission

        let location: CLLocation? = await withCheckedContinuation { continuation in
            stage = .locating
            locationCapture.capture { location in
                continuation.resume(returning: location)
            }
        }

        guard let location else {
            stage = .denied
            return
        }

        stage = .loading
        do {
            let payload = try await HavenFieldService.shared.nearestCustomers(
                workspaceId: workspaceId,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                limit: 10
            )
            customers = payload.customers
            note = payload.note
            if customers.isEmpty {
                stage = .empty
            } else {
                stage = .ready
                fitMapToCustomers(myLocation: location)
            }
        } catch {
            stage = .error
            errorMessage = "Couldn't load nearby customers. Try again in a moment."
        }
    }

    private func fitMapToCustomers(myLocation: CLLocation) {
        var lats: [Double] = [myLocation.coordinate.latitude]
        var lngs: [Double] = [myLocation.coordinate.longitude]
        for customer in customers {
            lats.append(customer.latitude)
            lngs.append(customer.longitude)
        }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        // Pad span by 30% so pins aren't right at the edge of the map.
        let latDelta = max(0.02, (maxLat - minLat) * 1.3)
        let lngDelta = max(0.02, (maxLng - minLng) * 1.3)
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        ))
    }
}

/// Wave M10 — business-card capture flow. Camera-first, AI-extracted
/// fields surface as an editable confirmation card; save inserts a
/// new contractors row via the workspace-authed wrapper. Mirrors the
/// M3 system-sweep aesthetic so the operator's mental model is "snap
/// → confirm → save."
struct FieldBusinessCardCaptureView: View {
    let workspaceId: String?
    let homes: [HavenFieldHome]

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .pickHome
    @State private var selectedHomeId: String?
    @State private var capturedImage: UIImage?
    @State private var extraction: HavenFieldBusinessCardExtraction?
    @State private var draftCompany: String = ""
    @State private var draftContact: String = ""
    @State private var draftPhone: String = ""
    @State private var draftEmail: String = ""
    @State private var draftWebsite: String = ""
    @State private var draftCategory: String = ""
    @State private var draftNotes: String = ""
    @State private var savedContractor: HavenFieldCreatedContractor?
    @State private var errorMessage: String?
    @State private var isExtracting: Bool = false
    @State private var isSaving: Bool = false
    @State private var showCamera: Bool = false

    enum Stage { case pickHome, ready, extracting, confirming, saving, saved }

    private var selectedHome: HavenFieldHome? {
        homes.first(where: { $0.id == selectedHomeId })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.critical.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    switch stage {
                    case .pickHome: pickHomeCard
                    case .ready: readyCard
                    case .extracting: extractingCard
                    case .confirming: confirmingCard
                    case .saving: savingCard
                    case .saved: savedCard
                    }
                }
                .padding(16)
            }
            .background(HavenColors.cream.ignoresSafeArea())
            .navigationTitle("Add existing vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                HavenFieldCameraPicker { image in
                    capturedImage = image
                    Task { await runExtraction(image: image) }
                }
            }
        }
    }

    private var pickHomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which home is this vendor for?")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("The captured contact will be added to that homeowner's vendor directory.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            if homes.isEmpty {
                FieldEmptyState(
                    title: "No homes yet",
                    subtitle: "Once you have at least one customer, you can capture their existing vendors here."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(homes) { home in
                        Button {
                            selectedHomeId = home.id
                            stage = .ready
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(home.name)
                                        .font(HavenTypography.uiButton)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(home.address)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(HavenColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HavenColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snap the business card")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            if let home = selectedHome {
                Text("For \(home.name)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Text("Get the card flat in frame. We'll read the company, contact, phone, email, and trade automatically.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            Button {
                resetDraft()
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Open camera")
                }
            }
            .buttonStyle(FieldPrimaryButtonStyle())

            #if DEBUG
            Button {
                resetDraft()
                Task { await runExtractionWithSeed() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Use test image (debug)")
                }
            }
            .buttonStyle(.bordered)
            .tint(HavenColors.action)
            #endif

            Button("Choose a different home") {
                stage = .pickHome
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.action)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var extractingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Reading the card...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var confirmingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Confirm the contact")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            if let confidence = extraction?.confidence {
                Text("Confidence: \(confidence.capitalized)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                fieldRow(label: "Company", text: $draftCompany, required: true)
                fieldRow(label: "Contact name", text: $draftContact)
                fieldRow(label: "Phone", text: $draftPhone, required: true, keyboard: .phonePad)
                fieldRow(label: "Email", text: $draftEmail, keyboard: .emailAddress)
                fieldRow(label: "Website", text: $draftWebsite, keyboard: .URL)
                fieldRow(label: "Trade", text: $draftCategory)
                fieldRow(label: "Notes", text: $draftNotes)
            }

            HStack {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-shoot")
                    }
                }
                .buttonStyle(.bordered)
                .tint(HavenColors.action)

                Spacer()

                Button {
                    Task { await saveContractor() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Save vendor")
                    }
                }
                .buttonStyle(FieldPrimaryButtonStyle(compact: true))
                .disabled(!canSave)
            }
        }
        .padding(16)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var savingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Saving \(draftCompany.isEmpty ? "vendor" : draftCompany)...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var savedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vendor saved")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let saved = savedContractor {
                        Text(saved.companyName)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
            if let home = selectedHome {
                Text("Added to \(home.name)'s vendor directory.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Button {
                resetDraft()
                stage = .ready
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add another vendor")
                }
            }
            .buttonStyle(.bordered)
            .tint(HavenColors.action)
        }
        .padding(16)
        .background(HavenColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HavenColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func fieldRow(
        label: String,
        text: Binding<String>,
        required: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textSecondary)
                if required {
                    Text("*")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.action)
                }
            }
            TextField("", text: text, prompt: Text(label).foregroundStyle(HavenColors.textTertiary))
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(label == "Company" || label == "Contact name" ? .words : .never)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(HavenColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(HavenColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var canSave: Bool {
        !draftCompany.trimmingCharacters(in: .whitespaces).isEmpty
            && !draftPhone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func resetDraft() {
        capturedImage = nil
        extraction = nil
        draftCompany = ""
        draftContact = ""
        draftPhone = ""
        draftEmail = ""
        draftWebsite = ""
        draftCategory = ""
        draftNotes = ""
        savedContractor = nil
        errorMessage = nil
    }

    private func runExtraction(image: UIImage) async {
        let downsized = downsizedJpegBase64(from: image)
        await postExtraction(base64: downsized)
    }

    #if DEBUG
    private func runExtractionWithSeed() async {
        // Tiny valid JPEG. Same one Wave M3 uses for the simulator
        // debug path — Claude returns a graceful "no card visible"
        // which exercises the extract-then-fall-through path.
        let onePixel = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/APvSiiiv/9k="
        // Pre-fill so the simulator-side reviewer has fields to confirm.
        await MainActor.run {
            draftCompany = "Acme Plumbing & Heating"
            draftContact = "John Smith"
            draftPhone = "(203) 555-0142"
            draftEmail = "john@acmeplumbingct.com"
            draftWebsite = "acmeplumbingct.com"
            draftCategory = "Plumbing"
            draftNotes = "Captured via debug seed (simulator)"
        }
        await postExtraction(base64: onePixel)
    }
    #endif

    private func downsizedJpegBase64(from image: UIImage) -> String {
        let maxEdge: CGFloat = 1600
        let size = image.size
        let scale = min(1, maxEdge / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        let data = resized.jpegData(compressionQuality: 0.82) ?? Data()
        return data.base64EncodedString()
    }

    private func postExtraction(base64: String) async {
        guard let workspaceId, !workspaceId.isEmpty else {
            errorMessage = "Sign in to your workspace to capture vendors."
            return
        }
        await MainActor.run {
            stage = .extracting
            isExtracting = true
            errorMessage = nil
        }
        do {
            let result = try await HavenFieldService.shared.extractBusinessCard(
                workspaceId: workspaceId,
                imageBase64: base64
            )
            await MainActor.run {
                extraction = result
                if draftCompany.isEmpty, let v = result.companyName { draftCompany = v }
                if draftContact.isEmpty, let v = result.contactName { draftContact = v }
                if draftPhone.isEmpty, let v = result.phone { draftPhone = v }
                if draftEmail.isEmpty, let v = result.email { draftEmail = v }
                if draftWebsite.isEmpty, let v = result.website { draftWebsite = v }
                if draftCategory.isEmpty, let v = result.tradeCategory { draftCategory = v }
                stage = .confirming
                isExtracting = false
                if let parseError = result.parseError {
                    errorMessage = parseError
                }
            }
        } catch {
            await MainActor.run {
                stage = .ready
                isExtracting = false
                errorMessage = "Couldn't read the card. Re-shoot or fill it in by hand."
            }
        }
    }

    private func saveContractor() async {
        guard let workspaceId else { return }
        guard let householdId = selectedHome?.householdId, !householdId.isEmpty else {
            errorMessage = "This home doesn't have a household on file. Open the home profile first."
            return
        }
        await MainActor.run {
            stage = .saving
            isSaving = true
            errorMessage = nil
        }
        do {
            let saved = try await HavenFieldService.shared.createContractorFromCard(
                workspaceId: workspaceId,
                householdId: householdId,
                companyName: draftCompany.trimmingCharacters(in: .whitespaces),
                contactName: draftContact.trimmingCharacters(in: .whitespaces).fieldNilIfEmpty,
                phone: draftPhone.trimmingCharacters(in: .whitespaces),
                email: draftEmail.trimmingCharacters(in: .whitespaces).fieldNilIfEmpty,
                website: draftWebsite.trimmingCharacters(in: .whitespaces).fieldNilIfEmpty,
                tradeCategory: draftCategory.trimmingCharacters(in: .whitespaces).fieldNilIfEmpty,
                notes: draftNotes.trimmingCharacters(in: .whitespaces).fieldNilIfEmpty
            )
            await MainActor.run {
                savedContractor = saved
                isSaving = false
                stage = .saved
            }
        } catch {
            await MainActor.run {
                isSaving = false
                stage = .confirming
                errorMessage = "Save failed. Try again or check your connection."
            }
        }
    }
}

private extension String {
    var fieldNilIfEmpty: String? { self.isEmpty ? nil : self }
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
    // Sprint #4 R4-E-7 fix: align iOS queue classification with the
    // server's stats categorization (handyman-provider/index.ts ~line 2788
    // — server treats `scheduled` as upcoming, not request). Pre-fix,
    // iOS treated `scheduled` as a request-queue state, so an assigned
    // visit with status=scheduled never surfaced on the Today tab even
    // though the workspace owner had already assigned the tech.
    // Post-fix: assigned `scheduled` → upcoming queue (Today eligible);
    // unassigned `scheduled` → request queue (still needs dispatch).
    var belongsInRequestQueue: Bool {
        switch status {
        case HandymanRequestStatus.submitted.rawValue,
             HandymanRequestStatus.sentToHandyman.rawValue,
             HandymanRequestStatus.alternateDatesProposed.rawValue,
             HandymanRequestStatus.awaitingHomeowner.rawValue,
             HandymanRequestStatus.quoted.rawValue:
            return true
        case HandymanRequestStatus.scheduled.rawValue:
            // Scheduled but not yet assigned → still needs dispatch attention.
            return assignment?.memberId == nil
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
        case HandymanRequestStatus.scheduled.rawValue:
            // Scheduled AND assigned → on the assignee's Today/Visits tab.
            return assignment?.memberId != nil
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

    // Bugfix Sprint #5 R7-E-2 — assignment stop_order is the canonical
    // route-position field when set; honor it before falling back to
    // title. Two visits at the same route_date + window with different
    // stop_orders should sort by stop_order (the dispatcher's planned
    // sequence), not alphabetically by title.
    let leftStop = lhs.assignment?.stopOrder ?? Int.max
    let rightStop = rhs.assignment?.stopOrder ?? Int.max
    if leftStop != rightStop { return leftStop < rightStop }

    // Bugfix Sprint #5 R7-E-2 — use natural / numeric-aware comparison
    // so "Visit #2" sorts before "Visit #10" instead of after it. The
    // .numeric option treats embedded digit runs as numbers rather than
    // characters — fixes the "Visit #1, #10, #100, #11" ordering bug.
    let titleComparison = lhs.title.compare(
        rhs.title,
        options: [.caseInsensitive, .numeric]
    )
    if titleComparison != .orderedSame { return titleComparison == .orderedAscending }

    // Final tiebreaker — request id, so the order is deterministic
    // across renders even when title + window + stop are identical.
    return lhs.requestId < rhs.requestId
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
            // Sprint #4 R4-E-4 fix: pre-fix this stripped year
            // unconditionally, so a task accidentally created with
            // next_due_date = 1970-01-01 (epoch) rendered as "Jan 1"
            // and read as Jan 1 of the current year. Apple's Mail
            // pattern: omit year when same as current year, include
            // it otherwise. Year-distance guard catches both ancient
            // (1970-01-01) and far-future (2099-12-31) dates.
            let cal = Calendar.current
            let currentYear = cal.component(.year, from: Date())
            let dateYear = cal.component(.year, from: date)
            if dateYear == currentYear {
                return date.formatted(.dateTime.month(.abbreviated).day())
            }
            return date.formatted(.dateTime.month(.abbreviated).day().year())
        }
        return self
    }

    /// N-1 fix: convert Postgres time-column strings ("10:00:00") to a
    /// device-locale short time ("10:00 AM"). Falls back to the raw
    /// string if it doesn't parse, so we never blank out a real time
    /// for an unfamiliar shape. Strips trailing seconds when parsing
    /// fails too, so "10:00:00" → "10:00" at minimum.
    var fieldShortTime: String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "HH:mm:ss"
        if let date = parser.date(from: self) {
            let f = DateFormatter()
            f.timeStyle = .short
            f.dateStyle = .none
            return f.string(from: date)
        }
        // Fallback: try HH:mm
        parser.dateFormat = "HH:mm"
        if let date = parser.date(from: self) {
            let f = DateFormatter()
            f.timeStyle = .short
            f.dateStyle = .none
            return f.string(from: date)
        }
        // Last-ditch: strip trailing :SS if present so the worst case is
        // "10:00" instead of "10:00:00".
        let parts = split(separator: ":")
        if parts.count >= 2 {
            return "\(parts[0]):\(parts[1])"
        }
        return self
    }

    var fieldDateTime: String {
        guard let date = HavenFieldDateParser.parse(self) else { return self }
        return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    /// Wave M11 — render an ISO timestamp as just the time-of-day in
    /// device-locale short form ("9:42 AM"). Used by the End of Day
    /// per-stop summary. Falls back to the raw input string when the
    /// timestamp can't be parsed (matches the rest of the field-format
    /// helpers' graceful-degradation pattern).
    var fieldClockTimeOfDay: String {
        guard let date = HavenFieldDateParser.parse(self) else { return self }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
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

    /// N-2 fix: visit titles are sometimes stored as "standard visit:
    /// Customer 4" / "repair: Customer 4" / "quote: Customer 7" — the
    /// raw enum bleeds through as a colon-prefixed lowercase prefix.
    /// Strip the prefix when it matches a known visit-type, leaving the
    /// human-readable customer / job descriptor. Unknown shapes pass
    /// through unchanged so we never blank out a real title.
    var fieldDisplayTitle: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return self }
        let knownPrefixes: Set<String> = [
            "standard visit", "standard_visit",
            "repair", "install", "quote", "assembly", "question", "setup",
            // N-2 follow-up: Chez-routed work surfaces with a
            // "chez_routed:" / "chez routed:" prefix in some seed paths.
            // Strip it the same way other request_type prefixes get
            // stripped so the homeowner / customer name leads the title.
            "chez_routed", "chez routed",
        ]
        for prefix in knownPrefixes {
            let lowered = trimmed.lowercased()
            if lowered.hasPrefix("\(prefix):") {
                let after = trimmed.dropFirst(prefix.count + 1)
                let stripped = after.trimmingCharacters(in: .whitespacesAndNewlines)
                if !stripped.isEmpty { return stripped }
            }
        }
        return trimmed
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
