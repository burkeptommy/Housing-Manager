import SwiftUI

/// Phase 95 (audit gap #56) — first-launch welcome for users
/// signed in as a home manager.
///
/// Without this, a freshly invited home manager lands on Dashboard
/// cold: same chrome the homeowner sees, same Tasks / Property /
/// Alfred tabs, no signal that some entries (delete property,
/// invite users, sensitive documents) will fail with RLS errors
/// because of their member_type. They have to discover the role
/// boundary by hitting walls.
///
/// This card is the explanation. Renders on Dashboard above all
/// other content for home managers, dismissable via a single
/// "Got it" CTA that flips an `@AppStorage` flag keyed per user
/// id so the dismissal sticks across launches but doesn't leak
/// across accounts.
struct HomeManagerWelcomeCard: View {
    let userId: UUID
    let householdName: String?

    @AppStorage private var dismissed: Bool

    init(userId: UUID, householdName: String?) {
        self.userId = userId
        self.householdName = householdName
        // Per-user dismissal key so a homeowner who later runs the
        // home-manager flow on a different account doesn't inherit
        // someone else's "Got it" tap.
        self._dismissed = AppStorage(
            wrappedValue: false,
            "home_manager_welcome_dismissed_\(userId.uuidString)"
        )
    }

    var body: some View {
        if !dismissed {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.action)
                        Text(headline)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        bulletRow(
                            icon: "checkmark.circle.fill",
                            color: HavenColors.success,
                            text: "Tasks, vendors, projects, and home systems are yours to manage."
                        )
                        bulletRow(
                            icon: "doc.text.fill",
                            color: HavenColors.success,
                            text: "Upload documents anytime. They go to the homeowner by default."
                        )
                        bulletRow(
                            icon: "lock.fill",
                            color: HavenColors.textSecondary,
                            text: "Some financial, medical, and legal documents stay private to the homeowner."
                        )
                        bulletRow(
                            icon: "person.fill.xmark",
                            color: HavenColors.textSecondary,
                            text: "Account settings, family members, and household membership stay with the homeowner."
                        )
                    }

                    Button {
                        Haptics.light()
                        Analytics.track(.homeManagerWelcomeDismissed, [
                            "user_id": userId.uuidString
                        ])
                        withAnimation(HavenTheme.animationStandard) {
                            dismissed = true
                        }
                    } label: {
                        Text("Got it")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnAction)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var headline: String {
        if let name = householdName, !name.isEmpty {
            return "Welcome to the \(name) household"
        }
        return "Welcome to Chez"
    }

    @ViewBuilder
    private func bulletRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)
                .padding(.top, 2)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
