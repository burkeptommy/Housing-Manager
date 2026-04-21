import SwiftUI

/// A card representing a single inbox item (forwarded email).
/// Shows status, summary, and inline action buttons for items needing user input.
struct InboxItemCard: View {
    let item: DatabaseService.InboxItemRow
    let properties: [PropertyRow]
    let projects: [PropertyProjectRow]
    var vehicles: [VehicleRow] = []
    let onProcess: (UUID?, String, String?, UUID?, UUID?) -> Void  // propertyId, action, category, targetProjectId, vehicleId
    let onDismiss: () -> Void

    @State private var selectedPropertyId: UUID?
    @State private var selectedCategory: String = "Other"
    @State private var isProcessing = false
    @State private var expanded = false
    @State private var showProjectPicker = false
    @State private var selectedProjectId: UUID?
    @State private var showCategoryChange = false
    @State private var showCategoryPicker = false
    @State private var selectedVehicleId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                headerContent
            }
            .buttonStyle(.plain)

            if expanded || item.isPending {
                Divider().padding(.horizontal, HavenTheme.spacing12)
                detailContent
            }
        }
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(borderColor.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .onAppear {
            if properties.count == 1 {
                selectedPropertyId = properties.first?.id
            }
            // Pre-select the AI-suggested category
            if let suggested = item.metadata?.suggestedCategory, !suggested.isEmpty {
                selectedCategory = suggested
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            DocumentCategoryPicker(selectedCategory: $selectedCategory)
                .presentationDetents([.large])
        }
    }

    // MARK: - Header

    private var headerContent: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(iconBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy800)
                        .lineLimit(1)

                    if item.isProcessing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Processing")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.navy500)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    } else if item.isPending {
                        Text("Action needed")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(HavenColors.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    if let date = item.createdAt {
                        Text(date, style: .relative)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    if let from = item.fromEmail, !from.isEmpty {
                        Text(from)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if !item.isPending {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing12)
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            // Summary
            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(4)
            }

            // Unsupported file type banner
            if item.metadata?.analysisSkipped == true {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("This file type couldn't be analyzed automatically. Please review and categorize.")
                        .font(HavenTypography.uiCaption)
                }
                .foregroundStyle(HavenColors.navy800)
                .padding(HavenTheme.spacing8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.navy.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
            }

            // Attachment indicator
            if let filename = item.attachmentFilename {
                HStack(spacing: 6) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 11))
                    Text(filename)
                        .font(HavenTypography.uiCaption)
                        .lineLimit(1)
                }
                .foregroundStyle(HavenColors.textTertiary)
            }

            // Action area
            if item.isPending {
                actionArea
            } else if item.relatedProjectId != nil || item.relatedDocumentId != nil {
                completedActionArea
            }
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.bottom, HavenTheme.spacing12)
        .padding(.top, HavenTheme.spacing8)
    }

    // MARK: - Action Area (for pending items)

    @ViewBuilder
    private var actionArea: some View {
        // Smart confirmation prompts for specific action types
        if item.actionType == "confirm_project_match" {
            confirmProjectMatchArea
        } else if item.actionType == "confirm_document_category" {
            confirmDocumentCategoryArea
        } else if item.actionType == "review_insurance_claim" {
            insuranceClaimActionArea
        } else if item.actionType == "resolve_duplicate" {
            duplicateResolutionArea
        } else if item.actionType == "confirm_vehicle_document" || item.actionType == "review_vehicle_invoice" {
            vehicleDocumentActionArea
        } else {
            standardActionArea
        }
    }

    // MARK: - Confirm Project Match

    private var confirmProjectMatchArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: HavenTheme.spacing8) {
                HavenButton(title: "Yes, that's right", action: {
                    Haptics.medium()
                    onProcess(nil, "confirm_project_match", nil, nil, nil)
                }, icon: "checkmark.circle.fill")

                Button {
                    showProjectPicker = true
                } label: {
                    Text("Different project")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            }

            Button {
                Haptics.medium()
                let propId = selectedPropertyId ?? properties.first?.id
                onProcess(propId, "process_document", "Contractor Quote", nil, nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill").font(.caption)
                    Text("Just Save as Document")
                        .font(HavenTypography.uiLabel)
                }
                .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Confirm Document Category

    private var confirmDocumentCategoryArea: some View {
        let isHighConfidence = item.metadata?.highConfidence == true

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if isHighConfidence {
                // High confidence: 1-tap "Looks Good" with subtle change option
                HavenButton(title: "Looks Good", action: {
                    Haptics.medium()
                    onProcess(nil, "confirm_document_category", nil, nil, nil)
                }, icon: "checkmark.circle.fill")

                Button {
                    Haptics.light()
                    showCategoryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.caption)
                        Text("Change Category")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                }
            } else {
                // Low/medium confidence: show current category, tap to search & change
                Button { showCategoryPicker = true } label: {
                    HStack {
                        Text(selectedCategory)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing8)
                    .background(HavenColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                }
                .buttonStyle(.plain)

                HStack(spacing: HavenTheme.spacing8) {
                    HavenButton(title: "Confirm", action: {
                        Haptics.medium()
                        onProcess(nil, "confirm_document_category", nil, nil, nil)
                    }, icon: "checkmark.circle.fill")

                    Button {
                        Haptics.medium()
                        onProcess(nil, "change_document_category", selectedCategory, nil, nil)
                    } label: {
                        Text("Save as \(selectedCategory)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                            .lineLimit(1)
                            .padding(.horizontal, HavenTheme.spacing12)
                            .padding(.vertical, 8)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Vehicle Document / Invoice Action Area

    private var vehicleDocumentActionArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if vehicles.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Which vehicle?")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Menu {
                        ForEach(vehicles) { vehicle in
                            Button {
                                selectedVehicleId = vehicle.id
                            } label: {
                                HStack {
                                    Text(vehicle.displayName)
                                    if selectedVehicleId == vehicle.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(vehicles.first(where: { $0.id == selectedVehicleId })?.displayName ?? "Select a vehicle")
                                .font(HavenTypography.body)
                                .foregroundStyle(selectedVehicleId != nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    }
                }
            }

            HStack(spacing: HavenTheme.spacing8) {
                Button {
                    guard !isProcessing else { return }
                    isProcessing = true
                    Haptics.medium()
                    let vid = selectedVehicleId ?? vehicles.first?.id
                    onProcess(nil, "process_vehicle_document", nil, nil, vid)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                        Text("Save to Vehicle")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .disabled(isProcessing)
            }

            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    guard !isProcessing else { return }
                    isProcessing = true
                    Haptics.medium()
                    let propId = selectedPropertyId ?? properties.first?.id
                    onProcess(propId, "process_document", selectedCategory, nil, nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill").font(.caption)
                        Text("Save as Document")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                }
                .disabled(isProcessing)

                Spacer()

                Button { onDismiss() } label: {
                    Text("Dismiss")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
        .onAppear {
            if vehicles.count == 1 {
                selectedVehicleId = vehicles.first?.id
            }
        }
    }

    // MARK: - Duplicate Resolution Action Area

    private var duplicateResolutionArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.warning)
                Text("This document may already exist in your vault.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.warning)
            }

            HavenButton(title: "Replace Existing", action: {
                Haptics.medium()
                onProcess(nil, "resolve_duplicate", "replace", nil, nil)
            }, icon: "arrow.triangle.swap")

            HavenButton(title: "Save Both Copies", action: {
                Haptics.medium()
                onProcess(nil, "resolve_duplicate", "save_both", nil, nil)
            }, style: .secondary, icon: "doc.on.doc")

            HavenButton(title: "Delete This Document", action: {
                Haptics.medium()
                onProcess(nil, "resolve_duplicate", "delete", nil, nil)
            }, style: .secondary, icon: "trash")
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Insurance Claim Action Area

    private var insuranceClaimActionArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            // Property picker (show when multiple properties)
            if properties.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Which property?")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Menu {
                        ForEach(properties) { prop in
                            Button { selectedPropertyId = prop.id } label: {
                                HStack {
                                    Text(prop.name)
                                    if selectedPropertyId == prop.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPropertyName ?? "Select a property")
                                .font(HavenTypography.body)
                                .foregroundStyle(selectedPropertyId != nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    }
                }
            }

            HStack(spacing: HavenTheme.spacing8) {
                Button {
                    guard !isProcessing else { return }
                    isProcessing = true
                    Haptics.medium()
                    let propId = selectedPropertyId ?? properties.first?.id
                    onProcess(propId, "create_claim_project", nil, nil, nil)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                        Text("Create Claim Project")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedPropertyId != nil || properties.count <= 1 ? HavenColors.navy : HavenColors.navy.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .disabled((selectedPropertyId == nil && properties.count > 1) || isProcessing)
            }

            HStack(spacing: HavenTheme.spacing12) {
                Button {
                    guard !isProcessing else { return }
                    isProcessing = true
                    Haptics.medium()
                    let propId = selectedPropertyId ?? properties.first?.id
                    onProcess(propId, "process_document", "Homeowners Insurance", nil, nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill").font(.caption)
                        Text("Save as Document")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.textTertiary)
                }
                .disabled(isProcessing)

                Spacer()

                Button { onDismiss() } label: {
                    Text("Dismiss")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Standard Action Area (existing logic)

    @ViewBuilder
    private var standardActionArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            // Property picker (show when multiple properties)
            if properties.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Which property?")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Menu {
                        ForEach(properties) { prop in
                            Button {
                                selectedPropertyId = prop.id
                            } label: {
                                HStack {
                                    Text(prop.name)
                                    if selectedPropertyId == prop.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPropertyName ?? "Select a property")
                                .font(HavenTypography.body)
                                .foregroundStyle(selectedPropertyId != nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    }
                }
            }

            // Document category picker
            if item.actionType == "classify_document" || item.actionType == "review" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What type of document?")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Button { showCategoryPicker = true } label: {
                        HStack {
                            Text(selectedCategory)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing8)
                        .background(HavenColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Action buttons
            let isQuoteType = item.actionType == "quote_received" || item.actionType == "assign_property" || item.type == "contractor_quote" || item.type == "project_created" || (item.type == "other" && item.actionType != "classify_document" && item.actionType != "review")

            if isQuoteType {
                VStack(spacing: HavenTheme.spacing8) {
                    HStack(spacing: HavenTheme.spacing8) {
                        Button {
                            guard !isProcessing else { return }
                            isProcessing = true
                            Haptics.medium()
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "process_quote", nil, nil, nil)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "hammer.fill")
                                Text("New Project")
                            }
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedPropertyId != nil || properties.count <= 1 ? HavenColors.navy : HavenColors.navy.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .disabled(selectedPropertyId == nil && properties.count > 1 || isProcessing)

                        if !projects.isEmpty {
                            Button {
                                showProjectPicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.badge.plus")
                                    Text("Add to Project")
                                }
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            }
                            .disabled(isProcessing)
                        }
                    }

                    HStack(spacing: HavenTheme.spacing12) {
                        Button {
                            guard !isProcessing else { return }
                            isProcessing = true
                            Haptics.medium()
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "process_document", "Contractor Quote", nil, nil)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.caption)
                                Text("Just Save Document")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.textTertiary)
                        }
                        .disabled(isProcessing)

                        Spacer()

                        Button { onDismiss() } label: {
                            Text("Dismiss")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .sheet(isPresented: $showProjectPicker) {
                    projectPickerSheet
                }
            }

            if !isQuoteType {
                HStack(spacing: HavenTheme.spacing8) {
                    if item.actionType == "classify_document" || item.actionType == "review" || item.type == "document_stored" {
                        Button {
                            guard !isProcessing else { return }
                            isProcessing = true
                            Haptics.medium()
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "process_document", selectedCategory, nil, nil)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.fill")
                                Text("Save Document")
                            }
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(.white)
                            .padding(.horizontal, HavenTheme.spacing12)
                            .padding(.vertical, 8)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .disabled(isProcessing)
                    }

                    Spacer()

                    Button { onDismiss() } label: {
                        Text("Skip")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Project Picker Sheet

    private var projectPickerSheet: some View {
        let action = item.actionType == "confirm_project_match" ? "move_to_project" : "add_to_project"
        return NavigationStack {
            List {
                ForEach(projects) { project in
                    Button {
                        Haptics.medium()
                        let propId = selectedPropertyId ?? properties.first?.id
                        onProcess(propId, action, nil, project.id, nil)
                        showProjectPicker = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(HavenColors.navy)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(project.category)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer()
                            Text(project.status.capitalized)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(item.actionType == "confirm_project_match" ? "Move to Project" : "Add to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showProjectPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Completed Action Area

    private var completedActionArea: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.success)
            if item.relatedProjectId != nil {
                Text("Project created")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.success)
            } else if item.relatedDocumentId != nil {
                let cat = item.metadata?.suggestedCategory
                Text(cat != nil ? "Saved as \(cat!)" : "Document saved")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.success)
            } else if item.relatedContractorId != nil {
                HStack(spacing: 0) {
                    Text("Vendor added")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.success)

                    Spacer()

                    Button {
                        Haptics.medium()
                        onProcess(nil, "remove_vendor", nil, nil, nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Remove")
                                .font(HavenTypography.uiCaption)
                        }
                        .foregroundStyle(HavenColors.critical.opacity(0.7))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var selectedPropertyName: String? {
        properties.first(where: { $0.id == selectedPropertyId })?.name
    }

    private var iconBackgroundColor: Color {
        if item.isPending { return HavenColors.warning }
        switch item.type {
        case "project_created": return HavenColors.success
        case "document_stored": return HavenColors.navy
        case "vendor_added": return HavenColors.success
        case "contractor_quote": return HavenColors.warning
        default: return HavenColors.textTertiary
        }
    }

    private var borderColor: Color {
        if item.isPending { return HavenColors.warning }
        return HavenColors.success
    }

    private var cardBackground: Color {
        if item.isPending { return HavenColors.warning.opacity(0.06) }
        return HavenColors.success.opacity(0.06)
    }
}
