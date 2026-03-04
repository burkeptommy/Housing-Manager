import SwiftUI

struct ContractorDirectoryView: View {
    @StateObject private var viewModel = ContractorViewModel()
    @State private var showAddContractor = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contractors.isEmpty {
                ProgressView("Loading contractors...")
            } else if viewModel.contractors.isEmpty {
                ContentUnavailableView {
                    Label("No Contractors", systemImage: "person.crop.rectangle.badge.plus")
                } description: {
                    Text("Add contractors to track your service providers.")
                } actions: {
                    Button("Add Contractor") {
                        showAddContractor = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                contractorList
            }
        }
        .navigationTitle("Contractors")
        .searchable(text: $viewModel.searchText, prompt: "Search contractors...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddContractor = true
                } label: {
                    Image(systemName: "plus")
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
            AddContractorView(onComplete: {
                Task { await viewModel.loadContractors() }
            })
        }
    }

    private var contractorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredContractors) { contractor in
                    NavigationLink {
                        ContractorDetailView(contractor: contractor)
                    } label: {
                        contractorCard(contractor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func contractorCard(_ contractor: ContractorRow) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.havenAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.companyName)
                        .font(.subheadline.weight(.medium))
                    if let contact = contractor.contactName {
                        Text(contact)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let specialties = contractor.specialties, !specialties.isEmpty {
                        Text(specialties.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Link(destination: URL(string: "tel:\(contractor.phone)")!) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                                .foregroundStyle(Color.havenAccent)
                        }
                        if let email = contractor.email {
                            Link(destination: URL(string: "mailto:\(email)")!) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.havenAccent)
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

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HavenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(contractor.companyName)
                            .font(.title2.bold())
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
                                    .foregroundStyle(.green)
                                Text("Insurance Verified")
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // Quick actions
                HStack(spacing: 12) {
                    Link(destination: URL(string: "tel:\(contractor.phone)")!) {
                        Label("Call", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if let email = contractor.email {
                        Link(destination: URL(string: "mailto:\(email)")!) {
                            Label("Email", systemImage: "envelope.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .font(.subheadline.weight(.medium))

                // Service history
                if !serviceRecords.isEmpty {
                    HavenCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service History")
                                .font(.headline)
                            ForEach(serviceRecords) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.description)
                                            .font(.subheadline)
                                        Text(record.serviceDate)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let cost = record.cost {
                                        Text("$\(cost, specifier: "%.0f")")
                                            .font(.caption.bold())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(contractor.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let allRecords = (try? await DatabaseService.shared.fetchServiceRecords()) ?? []
            serviceRecords = allRecords.filter { $0.contractorId == contractor.id }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
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
    @State private var selectedSpecialties: Set<String> = []
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Company Info") {
                    TextField("Company Name", text: $companyName)
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
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSpecialties.contains(cat.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.havenAccent)
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
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Add Contractor")
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
            let insert = ContractorInsert(
                householdId: householdId,
                companyName: companyName,
                phone: phone,
                contactName: contactName.isEmpty ? nil : contactName,
                email: email.isEmpty ? nil : email,
                specialties: selectedSpecialties.isEmpty ? nil : Array(selectedSpecialties),
                address: address.isEmpty ? nil : address,
                licenseNumber: licenseNumber.isEmpty ? nil : licenseNumber
            )
            _ = try await DatabaseService.shared.createContractor(insert)
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ContractorDirectoryView()
    }
}
