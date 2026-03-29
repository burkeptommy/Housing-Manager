import SwiftUI

/// Full detail view for an inbox item (forwarded email).
/// Shows sender, subject, summary, attachment info, related items, and action buttons.
struct InboxItemDetailView: View {
    let item: DatabaseService.InboxItemRow
    let properties: [PropertyRow]
    let onProcess: (UUID?, String, String?) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPropertyId: UUID?
    @State private var selectedCategory: String = "Other"
    @State private var isProcessing = false

    private let documentCategories = [
        "Contractor Quote", "Warranty Card", "Inspection Report",
        "Homeowners Insurance", "Vehicle Title", "Deed", "Mortgage",
        "Property Tax Records", "Utility Bill", "Vendor Contract",
        "Appliance Manual", "Permit", "Home Bill/Invoice",
        "Other Personal Documents"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Status badge
                statusBadge

                // Email info
                emailInfoSection

                // Summary
                if let summary = item.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SUMMARY")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        Text(summary)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                // View Raw Email
                if let rawBody = item.rawEmailBody, !rawBody.isEmpty {
                    rawEmailSection(rawBody)
                }

                // Attachment
                if let filename = item.attachmentFilename {
                    attachmentCard(filename)
                }

                // Related items
                relatedItemsSection

                // Actions
                if item.isPending {
                    actionSection
                }

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
        }
        .background(HavenColors.background)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !item.isPending {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
        }
        .onAppear {
            if properties.count == 1 {
                selectedPropertyId = properties.first?.id
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if item.isPending {
                Text("Action needed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HavenColors.warning.opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HavenColors.success.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            if let date = item.createdAt {
                Text(date, style: .relative)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Email Info

    private var emailInfoSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if let from = item.fromEmail, !from.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(from)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }

            Text(item.title)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.navy800)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Attachment

    @State private var showRawEmail = false

    private func rawEmailSection(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { showRawEmail.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showRawEmail ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                    Text("View Raw Email")
                        .font(HavenTypography.uiCaption)
                }
                .foregroundStyle(HavenColors.textTertiary)
            }
            .buttonStyle(.plain)

            if showRawEmail {
                Text(body)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(HavenTheme.spacing8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .textSelection(.enabled)
            }
        }
    }

    private func attachmentCard(_ filename: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: attachmentIcon)
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(filename)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                if let contentType = item.attachmentContentType {
                    Text(contentType)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "paperclip")
                .font(.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(HavenTheme.spacing12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var attachmentIcon: String {
        let ct = item.attachmentContentType?.lowercased() ?? ""
        if ct.contains("pdf") { return "doc.fill" }
        if ct.contains("image") { return "photo.fill" }
        return "paperclip"
    }

    // MARK: - Related Items

    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if item.relatedProjectId != nil || item.relatedDocumentId != nil || item.relatedContractorId != nil {
                Text("CREATED FROM THIS EMAIL")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .fontWeight(.semibold)
                    .tracking(1)

                if item.relatedProjectId != nil {
                    relatedRow(icon: "hammer.fill", label: "Project created", color: HavenColors.success)
                }
                if item.relatedDocumentId != nil {
                    relatedRow(icon: "doc.fill", label: "Document saved", color: HavenColors.navy)
                }
                if item.relatedContractorId != nil {
                    relatedRow(icon: "person.crop.circle.badge.plus", label: "Vendor added", color: HavenColors.success)
                }
            }
        }
    }

    private func relatedRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(color)
        }
        .padding(HavenTheme.spacing12)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("TAKE ACTION")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(1)

            // Property picker
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
                            Text(properties.first(where: { $0.id == selectedPropertyId })?.name ?? "Select a property")
                                .font(HavenTypography.body)
                                .foregroundStyle(selectedPropertyId != nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Category picker for documents
            if item.actionType == "classify_document" || item.actionType == "review" || item.type == "document_stored" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Document type")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

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
                        .padding(HavenTheme.spacing12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Action buttons
            VStack(spacing: HavenTheme.spacing8) {
                HavenButton(
                    title: isProcessing ? "Processing..." : primaryActionTitle,
                    action: {
                        guard !isProcessing else { return }
                        isProcessing = true
                        let propId = selectedPropertyId ?? properties.first?.id
                        onProcess(propId, primaryActionType, item.actionType == "classify_document" ? selectedCategory : nil)
                    },
                    icon: primaryActionIcon,
                    isLoading: isProcessing,
                    isDisabled: isProcessing
                )

                Button("Skip") {
                    onDismiss()
                    dismiss()
                }
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var primaryActionTitle: String {
        switch item.type {
        case "contractor_quote", "project_created": return "Create Project"
        case "document_stored": return "Save Document"
        case "vendor_added": return "Add Vendor"
        default: return "Process"
        }
    }

    private var primaryActionType: String {
        switch item.type {
        case "contractor_quote", "project_created": return "process_quote"
        case "document_stored": return "process_document"
        default: return "process_quote"
        }
    }

    private var primaryActionIcon: String {
        switch item.type {
        case "contractor_quote", "project_created": return "hammer.fill"
        case "document_stored": return "doc.fill"
        case "vendor_added": return "person.crop.circle.badge.plus"
        default: return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        if item.isPending { return HavenColors.warning }
        switch item.type {
        case "project_created": return HavenColors.success
        case "document_stored": return HavenColors.navy
        case "vendor_added": return HavenColors.success
        default: return HavenColors.textTertiary
        }
    }
}
