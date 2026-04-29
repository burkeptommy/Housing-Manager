import Foundation

/// App-facing reader for the low-code admin catalog managed from `/admin`.
/// The hardcoded Swift catalogs remain the fallback; published admin rows can
/// add, override, or cut quiz questions and maintenance templates.
final class AdminCatalogService {
    static let shared = AdminCatalogService()

    private let cacheKey = "chez.admin.publishedCatalog.v1"
    private let lock = NSLock()
    private var memoryItems: [AdminCatalogItem]?

    private init() {}

    @discardableResult
    func refreshPublishedCatalog() async -> [AdminCatalogItem] {
        do {
            let rows: [AdminCatalogItem] = try await HavenSupabase.from("admin_content_items")
                .select("id,item_type,title,status,category,description,sort_order,payload,updated_at")
                .in("status", values: ["active", "cut"])
                .order("sort_order", ascending: true)
                .execute()
                .value
            cache(rows)
            return rows
        } catch {
            print("[AdminCatalog] published catalog refresh failed: \(error.localizedDescription)")
            return cachedItems()
        }
    }

    func cachedItems() -> [AdminCatalogItem] {
        lock.lock()
        if let memoryItems {
            lock.unlock()
            return memoryItems
        }
        lock.unlock()

        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([AdminCatalogItem].self, from: data)
        else {
            return []
        }

        lock.lock()
        memoryItems = decoded
        lock.unlock()
        return decoded
    }

    func quizQuestions(applying items: [AdminCatalogItem]? = nil, to base: [HouseQuizQuestion]) -> [HouseQuizQuestion] {
        let catalog = items ?? cachedItems()
        let questionItems = catalog
            .filter { $0.itemType == "question" }
            .sorted { $0.sortOrder == $1.sortOrder ? $0.title < $1.title : $0.sortOrder < $1.sortOrder }

        guard !questionItems.isEmpty else { return base }

        let baseIds = Set(base.map(\.id))
        let cutIds = Set(questionItems.filter { $0.status == "cut" }.compactMap(questionId(for:)))
        let activeItems = questionItems.filter { $0.status == "active" }
        let activeByQuestionId = Dictionary(grouping: activeItems, by: { questionId(for: $0) ?? $0.id.uuidString })
            .compactMapValues { $0.last }

        var result: [HouseQuizQuestion] = []
        var touchedAdminIds = Set<UUID>()

        for fallback in base {
            if cutIds.contains(fallback.id) { continue }
            if let item = activeByQuestionId[fallback.id],
               let question = makeQuestion(from: item, fallback: fallback) {
                result.append(question)
                touchedAdminIds.insert(item.id)
            } else {
                result.append(fallback)
            }
        }

        for item in activeItems where !touchedAdminIds.contains(item.id) {
            let id = questionId(for: item) ?? "admin_\(slug(item.title))_\(item.id.uuidString.prefix(8))"
            guard !baseIds.contains(id),
                  let question = makeQuestion(from: item, fallback: nil, forcedId: id)
            else { continue }
            result.append(question)
            touchedAdminIds.insert(item.id)
        }

        return result.enumerated().sorted { lhs, rhs in
            let lhsOrder = sortOrderOverride(for: lhs.element, fallbackIndex: lhs.offset, activeByQuestionId: activeByQuestionId)
            let rhsOrder = sortOrderOverride(for: rhs.element, fallbackIndex: rhs.offset, activeByQuestionId: activeByQuestionId)
            return lhsOrder == rhsOrder ? lhs.offset < rhs.offset : lhsOrder < rhsOrder
        }.map(\.element)
    }

    func cachedMaintenanceTemplates(for category: String) -> [MaintenanceTemplate] {
        cachedItems()
            .filter { $0.itemType == "task" && $0.status == "active" }
            .compactMap(makeMaintenanceTemplate(from:))
            .filter { matchesCategory(query: category, candidate: $0.systemCategory) }
    }

    func cachedMaintenanceTemplate(forKey key: String) -> MaintenanceTemplate? {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cachedItems()
            .filter { $0.itemType == "task" && $0.status == "active" }
            .compactMap(makeMaintenanceTemplate(from:))
            .first { $0.templateKey.lowercased() == normalized }
    }

    func isTaskTemplateCut(_ template: MaintenanceTemplate) -> Bool {
        let keys = cutTaskKeys(for: template.systemCategory)
        return keys.contains(template.templateKey.lowercased())
            || keys.contains("\(template.systemCategory):\(template.title)".lowercased())
            || keys.contains(template.title.lowercased())
    }

    private func cache(_ items: [AdminCatalogItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
        lock.lock()
        memoryItems = items
        lock.unlock()
    }

    private func cutTaskKeys(for category: String) -> Set<String> {
        let keys = cachedItems()
            .filter { $0.itemType == "task" && $0.status == "cut" }
            .filter { item in
                let itemCategory = item.payload.string("systemCategory") ?? item.category ?? ""
                return itemCategory.isEmpty || matchesCategory(query: category, candidate: itemCategory)
            }
            .flatMap { item -> [String] in
                [
                    item.payload.string("templateKey"),
                    item.payload.string("stableId"),
                    item.title,
                    "\(item.category ?? ""):\(item.title)",
                ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            }
        return Set(keys)
    }

    private func questionId(for item: AdminCatalogItem) -> String? {
        item.payload.string("questionId")
            ?? item.payload.string("id")
            ?? item.payload.string("stableId")
    }

    private func makeQuestion(
        from item: AdminCatalogItem,
        fallback: HouseQuizQuestion?,
        forcedId: String? = nil
    ) -> HouseQuizQuestion? {
        let id = forcedId ?? questionId(for: item) ?? fallback?.id
        guard let id, !id.isEmpty else { return nil }

        let section = sectionValue(from: item.payload.string("section") ?? item.category)
            ?? fallback?.section
            ?? .homeBasics
        let chapter = chapterValue(from: item.payload.string("chapter") ?? item.category)
            ?? fallback?.chapter
            ?? HouseQuizQuestion.defaultChapter(for: section)
        let kind = item.payload.string("kind")
            .flatMap(HouseQuizQuestionKind.init(rawValue:))
            ?? fallback?.kind
            ?? .singleChoice

        return HouseQuizQuestion(
            id: id,
            section: section,
            chapter: chapter,
            title: item.title,
            fallbackTitle: item.payload.string("fallbackTitle") ?? fallback?.fallbackTitle,
            subtitle: item.payload.string("subtitle") ?? nonEmpty(item.description) ?? fallback?.subtitle,
            kind: kind,
            answerOptions: answerOptions(from: item, fallback: fallback),
            documentUploadCategory: fallback?.documentUploadCategory,
            providerFollowUpAnswerIds: Set(
                item.payload.stringArray("providerFollowUpAnswerIds")
                    ?? fallback.map { Array($0.providerFollowUpAnswerIds) }
                    ?? []
            ),
            providerTypes: item.payload.stringArray("providerTypes") ?? fallback?.providerTypes ?? [],
            dynamicProviderTypes: fallback?.dynamicProviderTypes,
            dynamicSkip: fallback?.dynamicSkip,
            supportsSelectAll: item.payload.bool("supportsSelectAll") ?? fallback?.supportsSelectAll ?? false,
            providerSearchPlaceholder: item.payload.string("providerSearchPlaceholder") ?? fallback?.providerSearchPlaceholder,
            sliderMin: item.payload.int("sliderMin") ?? fallback?.sliderMin ?? 1,
            sliderMax: item.payload.int("sliderMax") ?? fallback?.sliderMax ?? 10,
            sliderLeftLabel: item.payload.string("sliderLeftLabel") ?? fallback?.sliderLeftLabel,
            sliderRightLabel: item.payload.string("sliderRightLabel") ?? fallback?.sliderRightLabel
        )
    }

    private func answerOptions(from item: AdminCatalogItem, fallback: HouseQuizQuestion?) -> [AnswerOption] {
        guard let rawOptions = item.payload.array("answerOptions"), !rawOptions.isEmpty else {
            return fallback?.answerOptions ?? []
        }

        let fallbackOptions = fallback?.answerOptions ?? []
        return rawOptions.enumerated().compactMap { index, value in
            switch value {
            case .string(let label):
                let fallbackId = index < fallbackOptions.count ? fallbackOptions[index].id : nil
                return AnswerOption(id: fallbackId ?? slug(label), label: label)
            case .object(let object):
                let label = object.string("label") ?? object.string("title") ?? object.string("name")
                guard let label, !label.isEmpty else { return nil }
                let fallbackId = index < fallbackOptions.count ? fallbackOptions[index].id : nil
                return AnswerOption(
                    id: object.string("id") ?? object.string("value") ?? fallbackId ?? slug(label),
                    label: label,
                    icon: object.string("icon"),
                    acceptsCustomInput: object.bool("acceptsCustomInput") ?? false
                )
            default:
                return nil
            }
        }
    }

    private func sortOrderOverride(
        for question: HouseQuizQuestion,
        fallbackIndex: Int,
        activeByQuestionId: [String: AdminCatalogItem]
    ) -> Int {
        activeByQuestionId[question.id]?.sortOrder ?? (10_000 + fallbackIndex)
    }

    private func makeMaintenanceTemplate(from item: AdminCatalogItem) -> MaintenanceTemplate? {
        let payload = item.payload
        let systemCategory = payload.string("systemCategory") ?? item.category ?? "Handyman"
        guard !systemCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        let assignment = assignmentType(from: item)
        let safetyFloor = payload.bool("safetyFloor") ?? payload.bool("alwaysPro") ?? false
        let proRequired = payload.bool("proRequired")
            ?? payload.bool("professionalRequired")
            ?? (safetyFloor || assignment == .vendor)

        return MaintenanceTemplate(
            systemCategory: systemCategory,
            title: item.title,
            description: nonEmpty(item.description) ?? payload.string("description") ?? item.title,
            frequency: payload.string("cadence") ?? payload.string("frequency") ?? "Annually",
            priority: payload.string("priority") ?? "Medium",
            estimatedCostRange: payload.string("cost") ?? payload.string("estimatedCostRange") ?? "",
            isDIY: assignment == .personal,
            seasonalTiming: payload.string("season") ?? payload.string("seasonalTiming"),
            professionalRequired: proRequired,
            notes: payload.string("notes"),
            requiredSubtypes: Set(payload.stringArray("requiredSubtypes") ?? []),
            isEssential: payload.bool("essential") ?? payload.bool("isEssential") ?? true,
            equipmentKeywords: payload.stringArray("equipmentKeywords") ?? [],
            assignmentType: assignment,
            diyEffortMinutes: payload.int("diyMinutes") ?? payload.int("diyEffortMinutes"),
            diyEffortLabel: payload.string("diyNote") ?? payload.string("diyEffortLabel"),
            stableId: payload.string("templateKey") ?? payload.string("stableId") ?? "Admin:\(item.id.uuidString)",
            bundleId: payload.string("bundle") ?? payload.string("bundleId"),
            bundleTitle: payload.string("bundleTitle"),
            routingOverride: routing(from: item),
            safetyFloor: safetyFloor,
            maxIntervalDays: payload.int("maxIntervalDays"),
            warrantyLinked: payload.bool("warrantyLinked") ?? false,
            regionalPack: payload.string("regionalGate").flatMap(RegionalPack.init(rawValue:))
        )
    }

    private func assignmentType(from item: AdminCatalogItem) -> TaskAssignmentType {
        if let raw = item.payload.string("assignmentType"),
           let value = TaskAssignmentType(rawValue: raw) {
            return value
        }

        let haystack = [
            item.payload.string("operationalType"),
            item.payload.string("whoHandles"),
            item.payload.string("routingHint"),
        ].compactMap { $0 }.joined(separator: " ").lowercased()

        if haystack.contains("vendor") || haystack.contains("pro") || item.payload.bool("safetyFloor") == true {
            return .vendor
        }
        if haystack.contains("homeowner") || haystack.contains("diy") {
            return .personal
        }
        return .either
    }

    private func routing(from item: AdminCatalogItem) -> TaskRouting? {
        if let raw = item.payload.string("routing"),
           let value = TaskRouting(rawValue: raw) {
            return value
        }

        let operationalType = (item.payload.string("operationalType") ?? "").lowercased()
        let whoHandles = (item.payload.string("whoHandles") ?? "").lowercased()
        if item.payload.bool("safetyFloor") == true || whoHandles.contains("always pro") {
            return .vendorOnly
        }
        if operationalType.contains("handyman") {
            return .diyCapable
        }
        if whoHandles.contains("vendor") || whoHandles.contains("pro") {
            return .vendorDefault
        }
        return nil
    }

    private func sectionValue(from raw: String?) -> HouseQuizSection? {
        guard let raw else { return nil }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = HouseQuizSection(rawValue: normalized) { return direct }
        return HouseQuizSection.allCases.first {
            $0.title.caseInsensitiveCompare(normalized) == .orderedSame
        }
    }

    private func chapterValue(from raw: String?) -> HouseQuizChapter? {
        guard let raw else { return nil }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        if let direct = HouseQuizChapter(rawValue: normalized) { return direct }
        return HouseQuizChapter.allCases.first {
            $0.title.replacingOccurrences(of: " ", with: "_").lowercased() == normalized
        }
    }

    private func matchesCategory(query: String, candidate: String) -> Bool {
        let lhs = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rhs = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lhs == rhs || lhs.contains(rhs) || rhs.contains(lhs)
    }

    private func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func slug(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

struct AdminCatalogItem: Codable, Identifiable {
    let id: UUID
    let itemType: String
    let title: String
    let status: String
    let category: String?
    let description: String?
    let sortOrder: Int
    let payload: [String: AdminJSONValue]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status, category, description, payload
        case itemType = "item_type"
        case sortOrder = "sort_order"
        case updatedAt = "updated_at"
    }
}

enum AdminJSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AdminJSONValue])
    case object([String: AdminJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AdminJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AdminJSONValue].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        default: return nil
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .double(let value): return Int(value)
        case .string(let value): return Int(value)
        default: return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let value): return value
        case .string(let value):
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: return nil
            }
        default:
            return nil
        }
    }
}

private extension Dictionary where Key == String, Value == AdminJSONValue {
    func string(_ key: String) -> String? {
        guard let raw = self[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else { return nil }
        return raw
    }

    func int(_ key: String) -> Int? {
        self[key]?.intValue
    }

    func bool(_ key: String) -> Bool? {
        self[key]?.boolValue
    }

    func array(_ key: String) -> [AdminJSONValue]? {
        if case .array(let values) = self[key] {
            return values
        }
        return nil
    }

    func stringArray(_ key: String) -> [String]? {
        guard let value = self[key] else { return nil }
        switch value {
        case .array(let values):
            let strings = values.compactMap { $0.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return strings.isEmpty ? nil : strings
        case .string(let raw):
            let separator: Character = raw.contains("|") ? "|" : ","
            let strings = raw.split(separator: separator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return strings.isEmpty ? nil : strings
        default:
            return nil
        }
    }
}
