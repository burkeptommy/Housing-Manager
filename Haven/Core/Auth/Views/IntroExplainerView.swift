import SwiftUI

struct IntroExplainerView: View {
    var onContinue: () -> Void
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                propertyPage.tag(0)
                alfredPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Bottom section: page dots + button
            VStack(spacing: 24) {
                // Custom page indicators
                HStack(spacing: 10) {
                    ForEach(0..<2, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? HavenColors.navy800 : HavenColors.beige300)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                // Button
                if currentPage == 1 {
                    Button {
                        Haptics.medium()
                        onContinue()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(HavenColors.textOnAction)
                            .frame(maxWidth: .infinity)
                            .frame(height: HavenTheme.buttonHeight)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button {
                        Haptics.light()
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(HavenColors.textOnAction)
                            .frame(maxWidth: .infinity)
                            .frame(height: HavenTheme.buttonHeight)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                }

                // Skip option (not on last page)
                if currentPage < 1 {
                    Button {
                        Haptics.light()
                        onContinue()
                    } label: {
                        Text("Skip")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, 40)
        }
        .background(HavenColors.cream)
        .trackScreen("IntroExplainerView")
    }

    // MARK: - Page 1: Property Management

    private var propertyPage: some View {
        introPage(
            icon: "house.and.flag.fill",
            iconColor: HavenColors.navy800,
            headline: "Your home, handled.",
            subheadline: "Everything you need to manage your property, from systems and maintenance to vendors and warranties.",
            features: [
                IntroFeature(icon: "wrench.and.screwdriver.fill", text: "Automated maintenance schedules with smart reminders"),
                IntroFeature(icon: "person.2.fill", text: "Vendor directory with ratings, service history, and one-tap calling"),
                IntroFeature(icon: "shield.fill", text: "Warranty tracking with expiration alerts"),
                IntroFeature(icon: "chart.bar.fill", text: "Cost tracking and seasonal maintenance overviews"),
            ]
        )
    }

    // MARK: - Page 2: Alfred AI

    private var alfredPage: some View {
        introPage(
            icon: "sparkles",
            iconColor: HavenColors.navy800,
            headline: "Alfred, at your service.",
            subheadline: "Your built-in AI concierge reads your documents, answers questions, runs scenarios, and helps you plan, backed by real human support when you need it.",
            features: [
                IntroFeature(icon: "bubble.left.and.bubble.right.fill", text: "Ask anything about your home, finances, or family"),
                IntroFeature(icon: "lightbulb.fill", text: "\u{201C}What If?\u{201D} scenarios powered by your real data"),
                IntroFeature(icon: "doc.badge.plus", text: "Upload documents by photo, scan, or file. Alfred handles the rest"),
                IntroFeature(icon: "calendar.badge.clock", text: "Schedule maintenance, draft emails, and find vendors for you"),
            ]
        )
    }

    // MARK: - Shared Page Layout

    private func introPage(icon: String, iconColor: Color, headline: String, subheadline: String, features: [IntroFeature]) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(iconColor)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(HavenColors.navy800.opacity(0.08))
                            .frame(width: 100, height: 100)
                    )
                    .padding(.bottom, 28)

                // Headline
                Text(headline)
                    .font(HavenTypography.largeTitle)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                // Subheadline
                Text(subheadline)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)

                // Feature rows
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(features) { feature in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 28, height: 28)

                            Text(feature.text)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 48)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
    }
}

// MARK: - Feature Model

private struct IntroFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

#Preview {
    IntroExplainerView(onContinue: {})
}
