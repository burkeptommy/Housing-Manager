import SwiftUI

/// A card representing a single inbox item (forwarded email).
/// Shows status, summary, and inline action buttons for items needing user input.
struct InboxItemCard: View {
    let item: DatabaseService.InboxItemRow
    let properties: [PropertyRow]
    let onProcess: (UUID?, String, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedPropertyId: UUID?
    @State private var selectedCategory: String = "Other"
    @State private var isProcessing = false
    @State private var expanded = false

    private let documentCategories = [
        "Contractor Quote", "Warranty Card", "Inspection Report",
        "Homeowners Insurance", "Vehicle Title", "Deed", "Mortgage",
        "Property Tax Records", "Utility Bill", "Vendor Contract",
        "Appliance Manual", "Permit", "Home Bill/Invoice",
        "Other Personal Documents"
    ]

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
                    onProcess(nil, "confirm_project_match", nil)
                }, icon: "checkmark.circle.fill")

                Button {
                    // TODO: show project picker to move quote
                    onDismiss()
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
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
    }

    // MARK: - Confirm Document Category

    private var confirmDocumentCategoryArea: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            // Category picker to change if needed
            Menu {
                ForEach(documentCategories, id: \.self) { cat in
                    Button { selectedCategory = cat } label: {
                        HStack {
                            Text(cat)
                            if selectedCategory == cat { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory)
                        .font(HavenTypography.body)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing8)
                .background(HavenColors.background)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
            }

            HStack(spacing: HavenTheme.spacing8) {
                HavenButton(title: "Confirm", action: {
                    Haptics.medium()
                    onProcess(nil, "confirm_document_category", nil)
                }, icon: "checkmark.circle.fill")

                Button {
                    Haptics.medium()
                    onProcess(nil, "change_document_category", selectedCategory)
                } label: {
                    Text("Change Category")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
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

                    Menu {
                        ForEach(documentCategories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack {
                                    Text(cat)
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
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
                }
            }

            // Action buttons
            HStack(spacing: HavenTheme.spacing8) {
                if item.actionType == "assign_property" || item.type == "contractor_quote" || item.type == "project_created" || item.type == "other" {
                    Button {
                        guard !isProcessing else { return }
                        isProcessing = true
                        Haptics.medium()
                        let propId = selectedPropertyId ?? properties.first?.id
                        onProcess(propId, "process_quote", nil)
                    } label: {
                        HStack(spacing: 6) {
                            if isProcessing {
                                ProgressView().tint(.white).controlSize(.mini)
                            } else {
                                Image(systemName: "hammer.fill")
                            }
                            Text("Create Project")
                        }
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .padding(.vertical, 8)
                        .background(selectedPropertyId != nil ? HavenColors.navy : HavenColors.navy.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .disabled(selectedPropertyId == nil && properties.count > 1 || isProcessing)
                }

                if item.actionType == "classify_document" || item.actionType == "review" || item.type == "document_stored" {
                    Button {
                        guard !isProcessing else { return }
                        isProcessing = true
                        Haptics.medium()
                        let propId = selectedPropertyId ?? properties.first?.id
                        onProcess(propId, "process_document", selectedCategory)
                    } label: {
                        HStack(spacing: 6) {
                            if isProcessing {
                                ProgressView().tint(.white).controlSize(.mini)
                            } else {
                                Image(systemName: "doc.fill")
                            }
                            Text("Save Document")
                        }
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .padding(.vertical, 8)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .disabled(isProcessing)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Skip")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
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
                Text("Document saved")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.success)
            } else if item.relatedContractorId != nil {
                Text("Vendor added")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.success)
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
