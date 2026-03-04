import SwiftUI

// MARK: - Step 1: Welcome

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 72))
                .foregroundStyle(Color.havenAccent)

            VStack(spacing: 12) {
                Text("Welcome to Haven")
                    .font(.title.bold())

                Text("The smart way to organize your family's estate documents and manage your properties.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "doc.text.fill", title: "Document Vault", description: "Securely store and organize estate documents")
                featureRow(icon: "house.fill", title: "Property Management", description: "Track systems, maintenance, and warranties")
                featureRow(icon: "brain.head.profile.fill", title: "AI Assistant", description: "Get personalized guidance and gap analysis")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, HavenTheme.padding)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.havenAccent)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Step 2: Household Name

struct OnboardingHouseholdStep: View {
    @Binding var householdName: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.havenAccent)

            VStack(spacing: 8) {
                Text("Name Your Household")
                    .font(.title2.bold())
                Text("This helps organize everything under one roof.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HavenTextField(title: "Household Name (e.g. \"The Burke Family\")", text: $householdName)
                .textInputAutocapitalization(.words)

            Spacer()
        }
        .padding(.horizontal, HavenTheme.padding)
    }
}

// MARK: - Step 3: Primary Member

struct OnboardingPrimaryMemberStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var phone: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenAccent)
                    Text("Your Information")
                        .font(.title2.bold())
                    Text("As the primary household member.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HavenTextField(title: "First Name", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        HavenTextField(title: "Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }

                    HavenTextField(title: "Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    HavenTextField(title: "Phone (optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .padding(.horizontal, HavenTheme.padding)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 4: Spouse/Partner

struct OnboardingSpouseStep: View {
    @Binding var addSpouse: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenAccent)
                    Text("Spouse or Partner")
                        .font(.title2.bold())
                    Text("Add them now, or skip and add later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                Toggle("Add Spouse/Partner", isOn: $addSpouse)
                    .tint(Color.havenAccent)

                if addSpouse {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            HavenTextField(title: "First Name", text: $firstName)
                                .textContentType(.givenName)
                                .textInputAutocapitalization(.words)
                            HavenTextField(title: "Last Name", text: $lastName)
                                .textContentType(.familyName)
                                .textInputAutocapitalization(.words)
                        }

                        HavenTextField(title: "Email (optional)", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, HavenTheme.padding)
            .animation(.easeInOut, value: addSpouse)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 5: Additional Family Members

struct OnboardingFamilyStep: View {
    @Binding var members: [AdditionalMember]

    private let relationships = ["Child", "Grandchild", "Parent", "Sibling", "Guardian", "Other"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenAccent)
                    Text("Family Members")
                        .font(.title2.bold())
                    Text("Add children, parents, or others. You can always add more later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                ForEach($members) { $member in
                    VStack(spacing: 12) {
                        HStack {
                            Text("Family Member")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Button {
                                members.removeAll { $0.id == member.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 12) {
                            HavenTextField(title: "First Name", text: $member.firstName)
                                .textInputAutocapitalization(.words)
                            HavenTextField(title: "Last Name", text: $member.lastName)
                                .textInputAutocapitalization(.words)
                        }

                        Picker("Relationship", selection: $member.relationship) {
                            ForEach(relationships, id: \.self) { r in
                                Text(r).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerRadius))
                }

                Button {
                    members.append(AdditionalMember())
                } label: {
                    Label("Add Family Member", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
            .padding(.horizontal, HavenTheme.padding)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 6: Module Explanation

struct OnboardingModulesStep: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenAccent)
                    Text("You're All Set!")
                        .font(.title2.bold())
                    Text("Here's what Haven can do for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                moduleCard(
                    icon: "doc.text.fill",
                    title: "Document Vault",
                    items: [
                        "Upload and organize estate documents by category",
                        "AI-powered analysis identifies gaps and issues",
                        "Track expirations and get renewal reminders",
                        "Generate a Family Reference Binder"
                    ]
                )

                moduleCard(
                    icon: "house.fill",
                    title: "Property & Home Systems",
                    items: [
                        "Track all your properties and their systems",
                        "Automated maintenance schedules with reminders",
                        "Warranty tracker with expiration alerts",
                        "Contractor directory with service history"
                    ]
                )
            }
            .padding(.horizontal, HavenTheme.padding)
        }
    }

    private func moduleCard(icon: String, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.havenAccent)
                Text(title)
                    .font(.headline)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(.top, 2)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cardCornerRadius))
    }
}
