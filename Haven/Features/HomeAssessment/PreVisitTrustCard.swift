import SwiftUI

// MARK: - PreVisitTrustCard (Phase 85 PR 3)
//
// Renders inside HomeAssessmentPendingCard once a handyman has been
// assigned to the homeowner's pending assessment. Shows everything an
// HNW homeowner needs to know about who's about to walk into their
// house: photo, name, years in business, license + insurance status,
// background-check verification, vehicle photo, prior ratings.
//
// Tap → expanded full-screen profile (HandymanProfileView) with bio
// + complete review list. Compact mode is used on the dashboard;
// expanded mode appears on the profile screen itself.

struct PreVisitTrustCard: View {
    let profile: HandymanTrustProfile
    var compact: Bool = true
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 14) {
                headerRow

                if !compact {
                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                credentialChips
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: header row

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR CHEZ HANDYMAN")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.action)
                    .tracking(1.0)
                HStack(spacing: 6) {
                    Text(profile.presentationName)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if profile.isFullyVerified {
                        chezVerifiedBadge
                    }
                }
                if let years = profile.yearsInBusiness {
                    Text("\(years) year\(years == 1 ? "" : "s") in business")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if let rating = profile.ratingLabel {
                    Text(rating)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            if compact {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.top, 6)
            }
        }
    }

    private var avatar: some View {
        Group {
            if let photoUrl = profile.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarFallback
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(HavenColors.beige200, lineWidth: 1)
                )
            } else {
                avatarFallback
            }
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(HavenColors.action.opacity(0.16))
                .frame(width: 56, height: 56)
            Image(systemName: "person.fill")
                .font(.system(size: 26))
                .foregroundStyle(HavenColors.action)
        }
    }

    private var chezVerifiedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Chez Verified")
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
        }
        .foregroundStyle(HavenColors.action)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(HavenColors.action.opacity(0.12))
        )
    }

    // MARK: credential chips

    private var credentialChips: some View {
        FlowLayout(spacing: 6) {
            // Specialties first (most relatable to homeowner).
            ForEach(Array(profile.specialties.prefix(compact ? 3 : 8)), id: \.self) { specialty in
                chip(text: specialty, verified: false)
            }
            // Verified credentials below.
            if let label = profile.licenseLabel {
                chip(text: label, verified: profile.licenseVerifiedAt != nil)
            }
            if let label = profile.insuranceLabel {
                chip(text: label, verified: profile.insuranceVerifiedAt != nil)
            }
            if let label = profile.backgroundCheckLabel {
                chip(text: label, verified: true) // background_check_completed_at IS the verification
            }
            // "+ N more" tail when compact + more specialties exist
            if compact && profile.specialties.count > 3 {
                chip(text: "+\(profile.specialties.count - 3) more", verified: false)
            }
        }
    }

    @ViewBuilder
    private func chip(text: String, verified: Bool) -> some View {
        HStack(spacing: 4) {
            if verified {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            Text(text)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(verified ? HavenColors.action : HavenColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(
                verified
                ? HavenColors.action.opacity(0.10)
                : HavenColors.beige200.opacity(0.6)
            )
        )
    }

    // MARK: a11y

    private var accessibilityLabel: String {
        var parts: [String] = ["Your Chez handyman", profile.presentationName]
        if let years = profile.yearsInBusiness {
            parts.append("\(years) years in business")
        }
        if let rating = profile.ratingLabel {
            parts.append(rating)
        }
        if profile.isFullyVerified {
            parts.append("Chez Verified")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - FlowLayout (chip wrapping)

/// Phase 85: lightweight flow layout for the credential chip rail.
/// SwiftUI's HStack can't wrap; this preserves the row when the chip
/// labels overflow. iOS 16+; matches the existing `Layout` API.
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
