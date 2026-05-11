import SwiftUI
import Contacts

/// Shows the household's forwarding email address for Chez.
/// Users can forward contractor quotes, documents, vendor info, and anything
/// home related. Chez processes and organizes everything automatically.
struct ProjectEmailView: View {
    @State private var emailAddress: String?
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var copied = false
    @State private var savedContact = false
    @State private var error: String?
    // Whitelist
    @State private var allowedSenders: [DatabaseService.AllowedSenderRow] = []
    @State private var showAddSender = false
    @State private var newSenderEmail = ""
    @State private var newSenderLabel = ""
    @State private var isAddingSender = false
    @State private var senderError: String?

    private let maxSenders = 20

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                // Icon
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(HavenColors.textPrimary)
                    .padding(.top, HavenTheme.spacing32)

                // Title
                VStack(spacing: HavenTheme.spacing8) {
                    Text("Your Household Email")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Forward anything related to your home, vendors, or family to this address. Chez will automatically extract vendors, analyze quotes, categorize documents, and create projects for you.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HavenTheme.spacing4)
                }

                if isLoading {
                    ProgressView()
                        .tint(HavenColors.navy700)
                        .padding(.vertical, HavenTheme.spacing32)
                } else if let email = emailAddress {
                    emailCard(email)
                } else {
                    generateCard
                }

                if let error {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                        .multilineTextAlignment(.center)
                }

                // Allowed senders whitelist
                allowedSendersCard

                // What Chez does with forwarded emails
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        Text("WHAT CHEZ DOES")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        chezAction(icon: "doc.text.magnifyingglass", title: "Contractor Quotes", detail: "Analyzes every line item against market rates, creates a project, and adds the vendor")
                        chezAction(icon: "doc.fill", title: "Documents", detail: "Categorizes insurance, tax, vehicle, and home documents. Extracts dates and key details.")
                        chezAction(icon: "person.crop.circle.badge.plus", title: "Vendor Info", detail: "Adds contractors and service providers to your vendor directory automatically")
                        chezAction(icon: "wrench.and.screwdriver.fill", title: "Home Systems", detail: "Extracts appliance details, model numbers, and warranty info from manuals and inspections")
                        chezAction(icon: "calendar.badge.clock", title: "Maintenance", detail: "Creates maintenance tasks from inspection reports and service recommendations")
                    }
                }

                // How it works
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        Text("HOW IT WORKS")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        howItWorksStep(number: "1", text: "You receive an email with a quote, document, or vendor info")
                        howItWorksStep(number: "2", text: "Forward it to your household email above")
                        howItWorksStep(number: "3", text: "Chez reads it, extracts everything useful, and organizes it for you")
                        howItWorksStep(number: "4", text: "Check your dashboard for a summary of what was created")
                    }
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing32)
        }
        .background(HavenColors.background)
        .navigationTitle("Household Email")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEmailAddress()
            await loadAllowedSenders()
        }
        .sheet(isPresented: $showAddSender) {
            addSenderSheet
        }
    }

    // MARK: - Email Card (when address exists)

    private func emailCard(_ email: String) -> some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing16) {
                Text("YOUR FORWARDING ADDRESS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Text(email)
                    .font(Font.system(size: 16))
                    .foregroundStyle(HavenColors.textPrimary)
                    .textSelection(.enabled)
                    .padding(.vertical, HavenTheme.spacing4)

                // Primary action: Save as Contact
                if !savedContact {
                    Button {
                        saveAsContact(email: email)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 14))
                            Text("Save to Contacts")
                                .font(HavenTypography.uiButton)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HavenColors.success)
                        Text("Saved to Contacts")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.success)
                    }
                }

                // Secondary actions
                HStack(spacing: HavenTheme.spacing12) {
                    Button {
                        UIPasteboard.general.string = email
                        copied = true
                        Haptics.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy")
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(copied ? .white : HavenColors.navy800)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(copied ? HavenColors.success : HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: email) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                }
            }
        }
    }

    // MARK: - Allowed Senders

    private var allowedSendersCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Text("ALLOWED SENDERS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text("\(allowedSenders.count)/\(maxSenders)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Text("Only emails from these addresses will be processed. This protects your household from spam.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)

                // Sender list
                ForEach(allowedSenders) { sender in
                    HStack(spacing: 10) {
                        Image(systemName: sender.isAutoAdded == true ? "person.fill" : "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(HavenColors.navy.opacity(0.5))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(sender.email)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                            if let label = sender.label, !label.isEmpty {
                                Text(label)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        Spacer()

                        if sender.isAutoAdded == true {
                            Text("Member")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        } else {
                            Button {
                                Task {
                                    try? await DatabaseService.shared.deleteAllowedSender(id: sender.id)
                                    allowedSenders.removeAll { $0.id == sender.id }
                                    Haptics.light()
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Add button
                if allowedSenders.count < maxSenders {
                    Button {
                        newSenderEmail = ""
                        newSenderLabel = ""
                        senderError = nil
                        showAddSender = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                            Text("Add Allowed Sender")
                                .font(HavenTypography.uiLabel)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Add Sender Sheet

    private var addSenderSheet: some View {
        NavigationStack {
            VStack(spacing: HavenTheme.spacing20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("EMAIL ADDRESS")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .fontWeight(.semibold)
                        .tracking(1)
                    TextField("email@example.com", text: $newSenderEmail)
                        .font(HavenTypography.body)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("LABEL (OPTIONAL)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .fontWeight(.semibold)
                        .tracking(1)
                    TextField("e.g. Kids' School, Daycare, Work", text: $newSenderLabel)
                        .font(HavenTypography.body)
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let senderError {
                    Text(senderError)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.critical)
                }

                Spacer()
            }
            .padding(HavenTheme.pageMargin)
            .navigationTitle("Add Allowed Sender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSender = false }
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await addSender() }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                    .fontWeight(.semibold)
                    .disabled(newSenderEmail.trimmingCharacters(in: .whitespaces).isEmpty || isAddingSender)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Generate Card (when no address exists)

    private var generateCard: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "envelope.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(HavenColors.navy700)

                Text("No forwarding email yet")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("Generate a unique email address for your household. Anyone in your household can use it to forward documents and quotes to Chez.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                HavenButton(title: isGenerating ? "Generating..." : "Generate Email Address", action: {
                    Task { await generateEmail() }
                }, icon: "sparkles")
                .disabled(isGenerating)
            }
        }
    }

    // MARK: - Helpers

    private func chezAction(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 28, height: 28)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(detail)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private func howItWorksStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(HavenColors.navy)
                .clipShape(Circle())

            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Data

    private func loadEmailAddress() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let address = try await DatabaseService.shared.fetchHouseholdEmailAddress()
            emailAddress = address
        } catch {
            print("[HouseholdEmail] Failed to load: \(error)")
        }
    }

    private func loadAllowedSenders() async {
        allowedSenders = (try? await DatabaseService.shared.fetchAllowedSenders()) ?? []
    }

    private func addSender() async {
        let email = newSenderEmail.trimmingCharacters(in: .whitespaces).lowercased()
        guard !email.isEmpty else { return }
        guard email.contains("@") && email.contains(".") else {
            senderError = "Please enter a valid email address."
            return
        }
        guard !allowedSenders.contains(where: { $0.email.lowercased() == email }) else {
            senderError = "This email is already in your allowed senders."
            return
        }

        isAddingSender = true
        senderError = nil

        do {
            // Get household ID from current user
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                senderError = "No household found."
                isAddingSender = false
                return
            }

            let sender = try await DatabaseService.shared.addAllowedSender(
                householdId: householdId,
                email: email,
                label: newSenderLabel.isEmpty ? nil : newSenderLabel.trimmingCharacters(in: .whitespaces)
            )
            allowedSenders.append(sender)
            Haptics.success()
            showAddSender = false
        } catch {
            senderError = "Failed to add sender. It may already exist."
            Haptics.error()
        }

        isAddingSender = false
    }

    private func generateEmail() async {
        isGenerating = true
        error = nil

        do {
            let address = try await DatabaseService.shared.generateHouseholdEmailAddress()
            emailAddress = address
            Haptics.success()
        } catch {
            self.error = "Failed to generate email. Please try again."
            Haptics.error()
            print("[HouseholdEmail] Failed to generate: \(error)")
        }

        isGenerating = false
    }

    private func saveAsContact(email: String) {
        let contact = CNMutableContact()
        contact.givenName = "Chez"
        contact.familyName = "Home"
        contact.organizationName = "Chez Home"
        contact.emailAddresses = [
            CNLabeledValue(label: CNLabelWork, value: email as NSString)
        ]
        contact.note = "Forward contractor quotes, home documents, insurance, vendor info, and anything related to your home to this address. Chez processes everything automatically."

        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                print("[HouseholdEmail] Contacts access denied")
                return
            }

            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)

            do {
                try store.execute(saveRequest)
                DispatchQueue.main.async {
                    savedContact = true
                    Haptics.success()
                }
            } catch {
                print("[HouseholdEmail] Failed to save contact: \(error)")
                DispatchQueue.main.async {
                    Haptics.error()
                }
            }
        }
    }
}
