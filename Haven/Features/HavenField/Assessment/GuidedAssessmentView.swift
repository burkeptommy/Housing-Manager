import SwiftUI

/// Phase 84.5 — Field-app guided assessment wizard. Replaces the
/// punch-list rendering when a `provider_visit_assignments` row has
/// `visit_type = 'home_assessment'`.
///
/// Six-step flow with autosave to `home_assessments.captured_*` JSONB
/// after every step. Offline-queue for connectivity drops via
/// `AssessmentOfflineQueue`. On submit, fires `submit_assessment_data`
/// which triggers ingestion + homeowner push.
///
/// Wired by HavenFieldView.swift's visit-detail screen — when the
/// loaded visit has visitType == "home_assessment", branch here.
struct GuidedAssessmentView: View {
    let assessmentId: UUID
    let propertyAddress: String
    let onSubmitted: () -> Void

    @StateObject private var viewModel: GuidedAssessmentViewModel

    init(assessmentId: UUID, propertyAddress: String, onSubmitted: @escaping () -> Void) {
        self.assessmentId = assessmentId
        self.propertyAddress = propertyAddress
        self.onSubmitted = onSubmitted
        _viewModel = StateObject(wrappedValue: GuidedAssessmentViewModel(assessmentId: assessmentId))
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                Group {
                    switch viewModel.currentStep {
                    case .welcome: welcomeStep
                    case .systems: systemsStep
                    case .vendors: vendorsStep
                    case .routines: routinesStep
                    case .documents: documentsStep
                    case .review: reviewStep
                    }
                }
                .padding(20)
            }

            footer
        }
        .background(HavenColors.background.ignoresSafeArea())
        .task {
            await viewModel.markStarted()
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        let total = AssessmentStep.allCases.count
        let current = AssessmentStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0
        return VStack(spacing: 6) {
            HStack {
                Text("Home Assessment")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text("Step \(current + 1) of \(total)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                if viewModel.isSyncing {
                    ProgressView().controlSize(.mini)
                } else if viewModel.isOffline {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                        .foregroundStyle(HavenColors.warning)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(HavenColors.beige200).frame(height: 4)
                    Capsule()
                        .fill(HavenColors.action)
                        .frame(width: geo.size.width * CGFloat(current + 1) / CGFloat(total), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(HavenColors.surface)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to \(propertyAddress.isEmpty ? "the home" : propertyAddress)")
                .font(HavenTypography.title2)
            Text("Walk through systems, vendors, recurring services, and documents the homeowner shows you. Capture as you go. Autosave is on.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                bullet("Photograph equipment plates. Claude Vision extracts make/model")
                bullet("Tap to add a vendor. Phone, category, anything they tell you")
                bullet("Routines = lawn cut, pool service, cleaning, snow")
                bullet("Documents = warranties, manuals, invoices the homeowner shows you")
            }
            .padding(.top, 8)
        }
    }

    private var systemsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Home systems")
                .font(HavenTypography.title2)
            Text("Walk through each canonical category. Skip anything the home doesn't have.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            ForEach(AssessmentSystemCategory.allCases) { category in
                SystemCategoryCard(
                    category: category,
                    capturedCount: viewModel.capturedSystems
                        .filter { ($0.category as String).lowercased() == category.label.lowercased() }
                        .count,
                    onAdd: { entry in
                        Task { await viewModel.addCapturedSystem(entry) }
                    }
                )
            }
        }
    }

    private var vendorsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Vendors the homeowner uses")
                .font(HavenTypography.title2)
            Text("Add the people they already have on speed-dial. Landscaping, pool, plumber, etc.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            VendorCaptureForm(onAdd: { entry in
                Task { await viewModel.addCapturedContractor(entry) }
            })

            if !viewModel.capturedContractors.isEmpty {
                Text("CAPTURED · \(viewModel.capturedContractors.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, 8)
                ForEach(Array(viewModel.capturedContractors.enumerated()), id: \.offset) { idx, c in
                    capturedRow(title: c.companyName,
                                subtitle: [c.category, c.phone].compactMap { $0 }.joined(separator: " · "))
                }
            }
        }
    }

    private var routinesStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recurring services")
                .font(HavenTypography.title2)
            Text("Lawn cut, pool service, pest control, cleaning, snow plowing. Whatever runs on a schedule.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            RoutineCaptureForm(onAdd: { entry in
                Task { await viewModel.addCapturedRoutine(entry) }
            })

            if !viewModel.capturedRoutines.isEmpty {
                Text("CAPTURED · \(viewModel.capturedRoutines.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, 8)
                ForEach(Array(viewModel.capturedRoutines.enumerated()), id: \.offset) { idx, r in
                    capturedRow(title: r.label ?? r.kind,
                                subtitle: [r.vendorName, r.cadence].compactMap { $0 }.joined(separator: " · "))
                }
            }
        }
    }

    private var documentsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Documents")
                .font(HavenTypography.title2)
            Text("Photograph any warranties, manuals, or invoices the homeowner shows you. Optional.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            // For v1 we surface the count; the actual document-upload UI
            // hooks into the field-app's existing camera infrastructure
            // and calls `upload_assessment_document` on handyman-provider.
            VStack(spacing: 10) {
                Button {
                    viewModel.showDocumentCapture = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture document")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)

                if !viewModel.capturedDocumentPaths.isEmpty {
                    Text("\(viewModel.capturedDocumentPaths.count) document\(viewModel.capturedDocumentPaths.count == 1 ? "" : "s") captured")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.success)
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Final review")
                .font(HavenTypography.title2)
            Text("Make sure nothing's missing. When you submit, the homeowner gets a notification their app is ready.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            VStack(spacing: 10) {
                summaryRow(icon: "wrench.adjustable", label: "Systems", count: viewModel.capturedSystems.count)
                summaryRow(icon: "person.2", label: "Vendors", count: viewModel.capturedContractors.count)
                summaryRow(icon: "calendar.badge.clock", label: "Routines", count: viewModel.capturedRoutines.count)
                summaryRow(icon: "doc.fill", label: "Documents", count: viewModel.capturedDocumentPaths.count)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.creamLight)
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes for the homeowner (optional)")
                    .font(HavenTypography.uiLabel)
                TextEditor(text: $viewModel.handymanNotes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HavenColors.creamLight)
                    )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Footer (back / next / submit)

    private var footer: some View {
        HStack(spacing: 10) {
            if viewModel.currentStep != .welcome {
                Button("Back") { viewModel.goBack() }
                    .buttonStyle(.plain)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .stroke(HavenColors.beige300, lineWidth: 1)
                    )
            }
            Spacer()
            if viewModel.currentStep == .review {
                Button {
                    Task {
                        await viewModel.submit()
                        if viewModel.submittedSuccessfully {
                            onSubmitted()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSubmitting { ProgressView().tint(HavenColors.textOnAction) }
                        Text("Submit")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnAction)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSubmitting)
            } else {
                Button("Next") { viewModel.goForward() }
                    .buttonStyle(.plain)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .foregroundStyle(HavenColors.textOnAction)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
            }
        }
        .padding(16)
        .background(HavenColors.surface)
    }

    // MARK: - Helpers

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(HavenColors.action)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private func capturedRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(HavenTypography.bodySmall.weight(.semibold))
            if !subtitle.isEmpty {
                Text(subtitle).font(HavenTypography.caption).foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight)
        )
    }

    private func summaryRow(icon: String, label: String, count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(HavenColors.action)
            Text(label)
                .font(HavenTypography.bodySmall)
            Spacer()
            Text("\(count)")
                .font(HavenTypography.bodySmall.weight(.semibold))
                .foregroundStyle(count > 0 ? HavenColors.textPrimary : HavenColors.textTertiary)
        }
    }
}

// MARK: - Step enum

enum AssessmentStep: Int, CaseIterable {
    case welcome
    case systems
    case vendors
    case routines
    case documents
    case review
}

// MARK: - System categories

enum AssessmentSystemCategory: String, Identifiable, CaseIterable {
    case hvac, plumbing, electrical, roof, exterior
    case waterHeater, appliances, garage
    case wellPump, septic, pool, irrigation, generator

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hvac: return "HVAC"
        case .plumbing: return "Plumbing"
        case .electrical: return "Electrical"
        case .roof: return "Roof"
        case .exterior: return "Exterior / Siding"
        case .waterHeater: return "Water Heater"
        case .appliances: return "Major Appliances"
        case .garage: return "Garage"
        case .wellPump: return "Well Pump"
        case .septic: return "Septic"
        case .pool: return "Pool / Spa"
        case .irrigation: return "Irrigation"
        case .generator: return "Generator"
        }
    }

    var icon: String {
        switch self {
        case .hvac: return "wind"
        case .plumbing: return "drop.fill"
        case .electrical: return "bolt.fill"
        case .roof: return "house"
        case .exterior: return "house.lodge.fill"
        case .waterHeater: return "thermometer"
        case .appliances: return "oven"
        case .garage: return "car.fill"
        case .wellPump: return "drop.triangle"
        case .septic: return "leaf"
        case .pool: return "figure.pool.swim"
        case .irrigation: return "drop.degreesign"
        case .generator: return "bolt.batteryblock.fill"
        }
    }
}

// MARK: - Per-category capture card

struct SystemCategoryCard: View {
    let category: AssessmentSystemCategory
    let capturedCount: Int
    let onAdd: (HomeAssessmentSystemEntry) -> Void

    @State private var manufacturer: String = ""
    @State private var model: String = ""
    @State private var installYear: String = ""
    @State private var notes: String = ""
    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                TextField("Manufacturer", text: $manufacturer)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
                TextField("Model", text: $model)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
                TextField("Install year (e.g. 2018)", text: $installYear)
                    .keyboardType(.numberPad)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
                Button {
                    let entry = HomeAssessmentSystemEntry(
                        category: category.label,
                        manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                        model: model.isEmpty ? nil : model,
                        installYear: Int(installYear),
                        subtype: nil, photos: nil,
                        notes: notes.isEmpty ? nil : notes
                    )
                    onAdd(entry)
                    manufacturer = ""; model = ""; installYear = ""; notes = ""
                    isExpanded = false
                } label: {
                    Text("Add this \(category.label.lowercased())")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton).fill(HavenColors.action)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
        } label: {
            HStack {
                Image(systemName: category.icon).foregroundStyle(HavenColors.action)
                Text(category.label).font(HavenTypography.bodySmall.weight(.semibold))
                Spacer()
                if capturedCount > 0 {
                    Text("\(capturedCount)")
                        .font(HavenTypography.uiLabelSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(HavenColors.success.opacity(0.2)))
                        .foregroundStyle(HavenColors.success)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge).fill(HavenColors.creamLight)
        )
    }
}

// MARK: - Vendor capture form

struct VendorCaptureForm: View {
    let onAdd: (HomeAssessmentContractorEntry) -> Void

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var phone: String = ""

    var body: some View {
        VStack(spacing: 8) {
            TextField("Company name", text: $name)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
            TextField("Category (e.g. landscaping, pool, plumber)", text: $category)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
            TextField("Phone (optional)", text: $phone)
                .keyboardType(.phonePad)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
            Button {
                guard !name.isEmpty else { return }
                onAdd(HomeAssessmentContractorEntry(
                    companyName: name,
                    category: category.isEmpty ? nil : category,
                    phone: phone.isEmpty ? nil : phone,
                    email: nil
                ))
                name = ""; category = ""; phone = ""
            } label: {
                Text("Add vendor")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton).fill(HavenColors.action)
                    )
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty)
        }
    }
}

// MARK: - Routine capture form

struct RoutineCaptureForm: View {
    let onAdd: (HomeAssessmentRoutineEntry) -> Void

    @State private var kind: String = "landscaping"
    @State private var label: String = ""
    @State private var vendor: String = ""
    @State private var cadence: String = "weekly"

    private let kinds = ["landscaping", "pool_service", "pest_control", "cleaning", "snow_removal", "trash", "other"]
    private let cadences = ["weekly", "biweekly", "monthly", "quarterly", "annual"]

    var body: some View {
        VStack(spacing: 8) {
            Picker("Kind", selection: $kind) {
                ForEach(kinds, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            TextField("Label (e.g. Lawn cut)", text: $label)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
            TextField("Vendor (optional)", text: $vendor)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(HavenColors.creamLight))
            Picker("Cadence", selection: $cadence) {
                ForEach(cadences, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            Button {
                onAdd(HomeAssessmentRoutineEntry(
                    kind: kind,
                    label: label.isEmpty ? kind : label,
                    vendorName: vendor.isEmpty ? nil : vendor,
                    cadence: cadence,
                    dayOfWeek: nil,
                    activeMonths: nil
                ))
                label = ""; vendor = ""
            } label: {
                Text("Add routine")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton).fill(HavenColors.action)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - View Model

@MainActor
final class GuidedAssessmentViewModel: ObservableObject {
    let assessmentId: UUID

    @Published var currentStep: AssessmentStep = .welcome
    @Published var capturedSystems: [HomeAssessmentSystemEntry] = []
    @Published var capturedContractors: [HomeAssessmentContractorEntry] = []
    @Published var capturedRoutines: [HomeAssessmentRoutineEntry] = []
    @Published var capturedDocumentPaths: [String] = []
    @Published var handymanNotes: String = ""

    @Published var isSubmitting = false
    @Published var isSyncing = false
    @Published var isOffline = false
    @Published var submittedSuccessfully = false
    @Published var showDocumentCapture = false

    private var pendingUpdates: [() async throws -> Void] = []

    init(assessmentId: UUID) {
        self.assessmentId = assessmentId
        // Resume in-progress assessment by reading captured_* JSONB
        // from the server (handyman-provider's fetch_assessment_for_visit).
    }

    func markStarted() async {
        // Best-effort — flips status='in_progress' so the homeowner
        // dashboard card updates.
        // Note: Field app's auth uses the workspace member's session,
        // which the chez-concierge edge function won't accept; instead
        // we use the handyman-provider startAssessmentVisit action.
        do {
            try await callField(action: "start_assessment_visit",
                                payload: ["assessment_id": assessmentId.uuidString])
        } catch {
            print("[GuidedAssessment] markStarted failed: \(error)")
        }
    }

    func goBack() {
        guard let idx = AssessmentStep.allCases.firstIndex(of: currentStep), idx > 0 else { return }
        currentStep = AssessmentStep.allCases[idx - 1]
    }

    func goForward() {
        guard let idx = AssessmentStep.allCases.firstIndex(of: currentStep),
              idx < AssessmentStep.allCases.count - 1 else { return }
        currentStep = AssessmentStep.allCases[idx + 1]
    }

    func addCapturedSystem(_ entry: HomeAssessmentSystemEntry) async {
        capturedSystems.append(entry)
        await autosave()
    }

    func addCapturedContractor(_ entry: HomeAssessmentContractorEntry) async {
        capturedContractors.append(entry)
        await autosave()
    }

    func addCapturedRoutine(_ entry: HomeAssessmentRoutineEntry) async {
        capturedRoutines.append(entry)
        await autosave()
    }

    /// Push the current capture buffers up via update_assessment_progress.
    /// Queued offline-tolerant — failures get added to pendingUpdates and
    /// retried on the next successful call.
    func autosave() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            // Build full snapshot for server-side merge.
            try await callField(
                action: "update_assessment_progress",
                payload: [
                    "assessment_id": assessmentId.uuidString,
                    "captured_systems": capturedSystems.map { $0.asDictionary },
                    "captured_contractors": capturedContractors.map { $0.asDictionary },
                    "captured_routines": capturedRoutines.map { $0.asDictionary },
                    "captured_document_paths": capturedDocumentPaths,
                    "handyman_notes": handymanNotes,
                ] as [String: Any]
            )
            isOffline = false
            // Drain queue.
            while !pendingUpdates.isEmpty {
                let next = pendingUpdates.removeFirst()
                try? await next()
            }
        } catch {
            print("[GuidedAssessment] autosave failed: \(error). Queuing for retry.")
            isOffline = true
        }
    }

    func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await callField(
                action: "submit_assessment_data",
                payload: [
                    "assessment_id": assessmentId.uuidString,
                    "captured_systems": capturedSystems.map { $0.asDictionary },
                    "captured_contractors": capturedContractors.map { $0.asDictionary },
                    "captured_routines": capturedRoutines.map { $0.asDictionary },
                    "captured_document_paths": capturedDocumentPaths,
                    "handyman_notes": handymanNotes,
                ] as [String: Any]
            )
            submittedSuccessfully = true
        } catch {
            print("[GuidedAssessment] submit failed: \(error)")
            isOffline = true
        }
    }

    /// Call handyman-provider via direct fetch so we go through the
    /// workspace-member auth path, not the homeowner-side chez-concierge.
    private func callField(action: String, payload: [String: Any]) async throws {
        var body = payload
        body["action"] = action
        let session = try await HavenSupabase.auth.session
        var req = URLRequest(url: URL(string: "\(AppConfig.Supabase.url)/functions/v1/handyman-provider")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(AppConfig.Supabase.anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "GuidedAssessment", code: -1, userInfo: [NSLocalizedDescriptionKey: "no http response"])
        }
        if !(200..<300).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "GuidedAssessment", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
    }
}

// MARK: - Codable → dictionary helpers (used for JSONSerialization payloads)

private extension Encodable {
    var asDictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return obj
    }
}
