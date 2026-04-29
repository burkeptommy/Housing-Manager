import SwiftUI

struct DocumentCard: View {
    let document: DocumentRow

    private var categoryIcon: String {
        let group = DocumentCategory(rawValue: document.category)?.sectionGroup ?? ""
        switch group {
        case "Estate Planning": return "doc.text.fill"
        case "Entity Documents": return "building.2.fill"
        case "Real Estate": return "house.fill"
        case "Insurance": return "shield.fill"
        case "Financial Accounts": return "banknote.fill"
        case "Tax Records": return "doc.richtext.fill"
        case "Personal Property": return "car.fill"
        case "Digital Assets": return "desktopcomputer"
        case "Personal Identification": return "person.text.rectangle.fill"
        case "Professional & Business": return "briefcase.fill"
        default: return "doc.fill"
        }
    }

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(HavenColors.navy.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))

                if document.vaultLocked == true {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.havenWarning)
                        .padding(2)
                        .background(HavenColors.surface)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                Text(document.title)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: HavenTheme.spacing8) {
                    Text(document.category)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                    if let institution = document.issuingInstitution, !institution.isEmpty {
                        Text("\u{2022} \(institution)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: HavenTheme.spacing4) {
                Text(document.status.capitalized)
                    .font(HavenTypography.badgeLabel)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(HavenColors.statusColor(document.status).opacity(0.12))
                    .foregroundStyle(HavenColors.statusColor(document.status))
                    .clipShape(Capsule())

                if let expStr = document.expirationDate {
                    let formatter = DateFormatter()
                    let _ = formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: expStr) {
                        ExpirationBadge(date: date)
                    }
                }
            }
        }
        .padding(.vertical, HavenTheme.spacing4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.title), \(document.category), \(document.status)\(document.vaultLocked == true ? ", vault locked" : "")")
    }
}
