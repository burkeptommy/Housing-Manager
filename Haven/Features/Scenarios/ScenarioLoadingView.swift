import SwiftUI

struct ScenarioLoadingView: View {
    let scenario: ScenarioDefinition?
    @Environment(\.dismiss) private var dismiss
    @State private var currentMessageIndex = 0
    @State private var dotCount = 0
    @State private var pulseScale: CGFloat = 1.0

    private let loadingMessages = [
        "Analyzing your trust provisions",
        "Checking beneficiary designations",
        "Calculating tax implications",
        "Reviewing insurance coverage",
        "Comparing financial accounts",
        "Evaluating property details",
        "Assessing family structure",
        "Building your personalized scenario",
    ]

    private let funFacts = [
        "The average American family has 4 key estate documents.",
        "Only 33% of Americans have a will or living trust.",
        "Probate can take 6-18 months and cost 3-7% of the estate.",
        "Updating beneficiaries takes about 15 minutes per account.",
        "A properly funded trust avoids probate entirely.",
        "The lifetime gift tax exemption is $13.61 million per person in 2024.",
        "529 plans can now be rolled over to Roth IRAs (up to $35K).",
        "Cost segregation studies can accelerate depreciation by 10-15 years.",
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(HavenColors.navy.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(HavenColors.navy.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.navy700)
            }

            // Status message
            VStack(spacing: 12) {
                Text("\(loadingMessages[currentMessageIndex])\(String(repeating: ".", count: dotCount))")
                    .font(Font.custom("Georgia", size: 16))
                    .foregroundStyle(HavenColors.navy800)
                    .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)

                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<loadingMessages.count, id: \.self) { i in
                        Circle()
                            .fill(i <= currentMessageIndex ? HavenColors.navy700 : HavenColors.beige300)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Fun fact
            VStack(spacing: 8) {
                Text("DID YOU KNOW?")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Text(funFacts[currentMessageIndex % funFacts.count])
                    .font(Font.custom("Georgia", size: 14))
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            .padding(.top, 16)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenColors.background)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        // Dot animation (cycles 0-3)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                dotCount = (dotCount + 1) % 4
            }
        }

        // Message cycling
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    if currentMessageIndex < loadingMessages.count - 1 {
                        currentMessageIndex += 1
                    }
                }
            }
        }
    }
}

#Preview {
    ScenarioLoadingView(scenario: nil)
}
