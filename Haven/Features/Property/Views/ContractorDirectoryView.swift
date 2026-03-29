import SwiftUI

struct ContractorDirectoryView: View {
    var onSelect: ((ContractorRow) -> Void)?
    @StateObject private var viewModel = ContractorViewModel()
    @State private var showAddContractor = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contractors.isEmpty {
                ProgressView("Loading contractors...")
            } else if viewModel.contractors.isEmpty {
                ContentUnavailableView {
                    Label("Your Contact Network", systemImage: "person.crop.rectangle.badge.plus")
                } description: {
                    Text("Add contractors, attorneys, financial advisors, insurance agents, and other contacts.")
                } actions: {
                    Button("Add a Contact") {
                        showAddContractor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HavenColors.navy)
                }
            } else {
                contractorList
            }
        }
        .navigationTitle("Home & Estate Contacts")
        .trackScreen("ContractorDirectoryView")
        .searchable(text: $viewModel.searchText, prompt: "Search contractors...")
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                Analytics.track(.contractorSearched, ["query": newValue])
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortBy) {
                            ForEach(ContractorViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        if !viewModel.availableSpecialties.isEmpty {
                            Divider()
                            Picker("Specialty", selection: $viewModel.filterSpecialty) {
                                Text("All Specialties").tag(nil as String?)
                                ForEach(viewModel.availableSpecialties, id: \.self) { s in
                                    Text(s).tag(s as String?)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(HavenColors.navy)
                    }

                    Button {
                        showAddContractor = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadContractors()
        }
        .task {
            if viewModel.contractors.isEmpty {
                await viewModel.loadContractors()
            }
        }
        .sheet(isPresented: $showAddContractor) {
            AddVendorSheet(onComplete: {
                Task { await viewModel.loadContractors() }
            })
        }
    }

    private var contractorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if onSelect != nil {
                    Text("Tap a contact to assign them to this task")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(viewModel.filteredContractors) { contractor in
                    if let onSelect {
                        Button {
                            Haptics.light()
                            onSelect(contractor)
                        } label: {
                            contractorCard(contractor)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            ContractorDetailView(contractor: contractor)
                        } label: {
                            contractorCard(contractor)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    try? await DatabaseService.shared.deleteContractor(id: contractor.id)
                                    await viewModel.loadContractors()
                                    Haptics.success()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            Analytics.track(.contractorViewed, ["contractor_id": contractor.id.uuidString])
                        })
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    private func contractorCard(_ contractor: ContractorRow) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HavenColors.navy)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.companyName)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let contact = contractor.contactName {
                        Text(contact)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let specialties = contractor.specialties, !specialties.isEmpty {
                        Text(specialties.joined(separator: ", "))
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let rating = contractor.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(star <= rating ? HavenColors.warning : HavenColors.textTertiary)
                            }
                        }
                    }

                    let spent = viewModel.totalSpent(for: contractor.id)
                    if spent > 0 {
                        Text("$\(spent, specifier: "%.0f") spent")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    HStack(spacing: 8) {
                        if let url = sanitizedPhoneURL(contractor.phone) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                        if let email = contractor.email,
                           let url = sanitizedEmailURL(email) {
                            Link(destination: url) {
                                Image(systemName: "envelope.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Contractor Detail

struct ContractorDetailView: View {
    let contractor: ContractorRow
    @State private var serviceRecords: [ServiceRecordRow] = []
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {

            LazyVStack(alignment: .leading, spacing: 16) {
                HavenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(contractor.companyName)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let contact = contractor.contactName {
                            infoRow("Contact", value: contact)
                        }
                        infoRow("Phone", value: contractor.phone)
                        if let email = contractor.email {
                            infoRow("Email", value: email)
                        }
                        if let address = contractor.address {
                            infoRow("Address", value: address)
                        }
                        if let license = contractor.licenseNumber {
                            infoRow("License", value: license)
                        }
                        if contractor.insuranceVerified == true {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(HavenColors.success)
                                Text("Insurance Verified")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                    }
                }

                // Quick actions
                HStack(spacing: 12) {
                    if let url = sanitizedPhoneURL(contractor.phone) {
                        Link(destination: url) {
                            Label("Call", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(HavenColors.success.opacity(0.12))
                                .foregroundStyle(HavenColors.success)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    if let email = contractor.email,
                       let url = sanitizedEmailURL(email) {
                        Link(destination: url) {
                            Label("Email", systemImage: "envelope.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(HavenColors.info.opacity(0.12))
                                .foregroundStyle(HavenColors.info)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .font(HavenTypography.uiLabel)

                // Service history
                if !serviceRecords.isEmpty {
                    HavenCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service History")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            ForEach(serviceRecords) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.description)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(record.serviceDate)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                    Spacer()
                                    if let cost = record.cost {
                                        Text("$\(cost, specifier: "%.0f")")
                                            .font(HavenTypography.uiLabel)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle(contractor.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .confirmationDialog("Delete \(contractor.companyName)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await DatabaseService.shared.deleteContractor(id: contractor.id)
                    Haptics.success()
                    dismiss()
                }
            }
        } message: {
            Text("This contact and their service history will be permanently removed.")
        }
        .trackScreen("ContractorDetailView", properties: ["contractor_id": contractor.id.uuidString])
        .task {
            let allRecords = (try? await DatabaseService.shared.fetchServiceRecords()) ?? []
            serviceRecords = allRecords.filter { $0.contractorId == contractor.id }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }
}

// MARK: - Add Contractor

struct AddContractorView: View {
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var contactName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var licenseNumber = ""
    @State private var contactType = "Contractor / Service Provider"
    @State private var selectedSpecialties: Set<String> = []
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?

    private let contactTypes = [
        "Contractor / Service Provider",
        "Attorney",
        "Financial Advisor / CPA",
        "Insurance Agent",
        "Property Manager",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Type") {
                    Picker("Type", selection: $contactType) {
                        ForEach(contactTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section(contactType == "Contractor / Service Provider" ? "Company Info" : "Contact Info") {
                    TextField(contactType == "Contractor / Service Provider" ? "Company Name" : "Name / Firm", text: $companyName)
                    TextField("Contact Name", text: $contactName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Address") {
                    TextField("Address", text: $address)
                }

                if contactType == "Contractor / Service Provider" {
                    Section("Specialties") {
                        ForEach(SystemCategory.allCases, id: \.self) { cat in
                            Button {
                                if selectedSpecialties.contains(cat.rawValue) {
                                    selectedSpecialties.remove(cat.rawValue)
                                } else {
                                    selectedSpecialties.insert(cat.rawValue)
                                }
                            } label: {
                                HStack {
                                    Text(cat.rawValue)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if selectedSpecialties.contains(cat.rawValue) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(HavenColors.navy)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("License") {
                    TextField("License Number", text: $licenseNumber)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(companyName.isEmpty || phone.isEmpty || isSaving)
                }
            }
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }
            var allSpecialties = Array(selectedSpecialties)
            if contactType != "Contractor / Service Provider" {
                allSpecialties.insert(contactType, at: 0)
            }

            let insert = ContractorInsert(
                householdId: householdId,
                companyName: companyName,
                phone: phone,
                contactName: contactName.isEmpty ? nil : contactName,
                email: email.isEmpty ? nil : email,
                specialties: allSpecialties.isEmpty ? nil : allSpecialties,
                address: address.isEmpty ? nil : address,
                licenseNumber: licenseNumber.isEmpty ? nil : licenseNumber
            )
            _ = try await DatabaseService.shared.createContractor(insert)
            Analytics.track(.contractorCreated, ["company_name": companyName, "contact_type": contactType])
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - URL Helpers

private func sanitizedPhoneURL(_ phone: String) -> URL? {
    let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    return URL(string: "tel:\(cleaned)")
}

private func sanitizedEmailURL(_ email: String) -> URL? {
    URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))")
}

#Preview {
    NavigationStack {
        ContractorDirectoryView()
    }
}
