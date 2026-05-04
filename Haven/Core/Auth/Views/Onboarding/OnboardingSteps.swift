import SwiftUI

// MARK: - Phone Formatting Helper

private func formatPhoneNumber(_ input: String) -> String {
    let digits = input.filter { $0.isNumber }
    let limited = String(digits.prefix(10))

    switch limited.count {
    case 0:
        return ""
    case 1...3:
        return "(\(limited)"
    case 4...6:
        let area = limited.prefix(3)
        let middle = limited.dropFirst(3)
        return "(\(area)) \(middle)"
    case 7...10:
        let area = limited.prefix(3)
        let middle = limited.dropFirst(3).prefix(3)
        let last = limited.dropFirst(6)
        return "(\(area)) \(middle)-\(last)"
    default:
        return limited
    }
}

// MARK: - Step 1: About You (Primary Member)

struct OnboardingCombinedInfoStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var gender: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("About You")
                        .font(HavenTypography.title2)
                    Text("Tell us a bit about yourself so Chez can personalize your experience.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HavenTextField(title: "First Name", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        HavenTextField(title: "Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }

                    if !email.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(email)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(HavenColors.success)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        HavenTextField(title: "Email (optional)", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }

                    HavenTextField(title: "Phone (optional)", text: Binding(
                        get: { phone },
                        set: { phone = formatPhoneNumber($0) }
                    ))
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)

                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                        Text("Other").tag("other")
                        Text("Prefer Not to Say").tag("prefer_not_to_say")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, HavenTheme.padding)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 2: Spouse/Partner

struct OnboardingSpouseStep: View {
    @Binding var addSpouse: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var gender: String
    var spouseHasExistingAccount: Bool = false
    var isCheckingSpouseEmail: Bool = false
    var onEmailChanged: ((String) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Spouse or Partner")
                        .font(HavenTypography.title2)
                    Text("Add them now, or skip and add later.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, 32)

                if !addSpouse {
                    VStack(spacing: 12) {
                        Button {
                            withAnimation { addSpouse = true }
                        } label: {
                            Text("Yes, add my spouse or partner")
                                .font(HavenTypography.uiLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(HavenColors.navy.opacity(0.08))
                                .foregroundStyle(HavenColors.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Text("You can always add them later from Settings.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                } else {
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
                            .onChange(of: email) { _, newValue in
                                onEmailChanged?(newValue)
                            }

                        if isCheckingSpouseEmail {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text("Checking...")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        } else if spouseHasExistingAccount {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.checkmark")
                                    .foregroundStyle(HavenColors.success)
                                    .font(.caption)
                                Text("This person already has a Chez account. They'll be invited to join your household.")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.success)
                            }
                            .padding(12)
                            .background(HavenColors.success.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Picker("Gender", selection: $gender) {
                            Text("Male").tag("male")
                            Text("Female").tag("female")
                            Text("Other").tag("other")
                            Text("Prefer Not to Say").tag("prefer_not_to_say")
                        }
                        .pickerStyle(.segmented)

                        Button {
                            withAnimation {
                                addSpouse = false
                                firstName = ""
                                lastName = ""
                                email = ""
                            }
                        } label: {
                            Text("Remove")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
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

// MARK: - Step 3: Additional Family Members

struct OnboardingFamilyStep: View {
    @Binding var members: [AdditionalMember]

    private let relationships = ["Child", "Grandchild", "Parent", "Sibling", "Guardian", "Other"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Family Members")
                        .font(HavenTypography.title2)
                    Text("Add the people who live in or rely on your home — partners, children, parents, or other family members. Chez will match them when you upload documents.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                ForEach($members) { $member in
                    VStack(spacing: 12) {
                        HStack {
                            Text("Family Member")
                                .font(HavenTypography.uiLabel)
                            Spacer()
                            Button {
                                members.removeAll { $0.id == member.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(HavenColors.textTertiary)
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
                    .background(HavenColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerRadius))
                }

                Button {
                    members.append(AdditionalMember())
                } label: {
                    Label("Add Family Member", systemImage: "plus.circle.fill")
                        .font(HavenTypography.uiLabel)
                }
            }
            .padding(.horizontal, HavenTheme.padding)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 4: Features Overview

struct OnboardingFeaturesStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ChezBrandView(width: 144)

            VStack(spacing: 12) {
                Text("Welcome to Chez")
                    .font(HavenTypography.title)

                Text("The smart way to manage your home and protect what matters most.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "house.fill", title: "Home Management", description: "Track systems, maintenance, vendors, and costs")
                featureRow(icon: "doc.text.fill", title: "Document Vault", description: "Securely organize property and household documents")
                featureRow(icon: "sparkles", title: "Alfred AI", description: "Personalized guidance, scenarios, and gap analysis")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, HavenTheme.padding)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 36, height: 36)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(HavenTypography.caption).foregroundStyle(HavenColors.textSecondary)
            }
        }
    }
}

// MARK: - Step 5: All Set

struct OnboardingModulesStep: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("You're All Set!")
                        .font(HavenTypography.title2)
                    Text("Here's what you can start doing right away.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, 32)

                moduleCard(
                    icon: "house.fill",
                    title: "Property & Home Systems",
                    items: [
                        "Track properties, systems, and maintenance schedules",
                        "Warranty tracking and contractor directory"
                    ]
                )

                moduleCard(
                    icon: "doc.text.fill",
                    title: "Document Vault",
                    items: [
                        "Upload and organize property documents with AI analysis",
                        "Expiration reminders and Family Reference Binder"
                    ]
                )
            }
            .padding(.horizontal, HavenTheme.padding)
        }
    }

    private func moduleCard(icon: String, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(title)
                    .font(HavenTypography.headline)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(HavenTypography.uiLabelSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(HavenColors.success)
                        .frame(width: 14, height: 14)
                        .padding(.top, 3)
                    Text(item)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cardCornerRadius))
    }
}
