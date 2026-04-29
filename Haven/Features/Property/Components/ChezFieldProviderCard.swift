import SwiftUI

/// A single Chez Field directory provider rendered as a tappable card.
/// Used by both `FindLocalVendorSheet` (auto-matched results above the
/// CHEZ CERTIFIED Google Places section) and `ChezDirectorySearchView`
/// (active browse / search of the full directory).
///
/// The card stays presentation-only: tapping fires `onTap`, and the
/// caller owns the confirmation alert + adoption flow via
/// `ChezDirectoryService`.
struct ChezFieldProviderCard: View {
    let provider: HavenSupabase.ChezFieldProvider
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.name)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let rating = provider.rating, rating > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.warning)
                                Text(String(format: "%.1f", rating))
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                if provider.reviewCount > 0 {
                                    Text("·")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text("\(provider.reviewCount) review\(provider.reviewCount == 1 ? "" : "s")")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text("On Chez")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.action)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HavenColors.actionPale)
                    .clipShape(Capsule())
                }

                if let blurb = provider.blurb, !blurb.isEmpty {
                    Text(blurb)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                if let city = provider.city, !city.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("\(city)\(provider.state.map { ", \($0)" } ?? "")")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let phone = provider.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(phone)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                if let website = provider.website, !website.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(website)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.navy500)
                            .lineLimit(1)
                    }
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.action.opacity(0.4), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
