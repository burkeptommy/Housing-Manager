import SwiftUI

/// Swipeable card stack for rating 15 estate planning concerns.
/// Top card visible, next 2 peek behind. Rate H/S/L/NA to animate
/// the card away. Swipe left to go back.
struct EstateConcernsCardStack: View {
    let existingRatings: [EstateConcernRating]
    var onRate: ((String, String) -> Void)? // (concernId, rating)
    var onComplete: (() -> Void)?

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var ratings: [String: String] = [:] // concernId -> rating

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            // Progress
            HStack {
                Text("\(currentIndex + 1) of \(Self.concerns.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                if currentIndex > 0 {
                    Button {
                        Haptics.light()
                        withAnimation(HavenTheme.animationCard) {
                            currentIndex -= 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Back")
                                .font(HavenTypography.uiLabelSmall)
                        }
                        .foregroundStyle(HavenColors.navy700)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.beige200)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.navy700)
                        .frame(width: geo.size.width * (CGFloat(currentIndex) / CGFloat(Self.concerns.count)), height: 4)
                        .animation(.easeOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 4)

            // Card stack
            ZStack {
                ForEach(Array(Self.concerns.enumerated().reversed()), id: \.element.id) { index, concern in
                    if index >= currentIndex && index < currentIndex + 3 {
                        let offset = index - currentIndex
                        concernCard(concern, offset: offset)
                            .offset(x: offset == 0 ? dragOffset : 0, y: CGFloat(offset) * 6)
                            .scaleEffect(1.0 - CGFloat(offset) * 0.04)
                            .opacity(offset == 2 ? 0.5 : 1.0)
                            .zIndex(Double(Self.concerns.count - index))
                    }
                }
            }
            .frame(minHeight: 240)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 && currentIndex > 0 {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -80 && currentIndex > 0 {
                            withAnimation(HavenTheme.animationCard) {
                                currentIndex -= 1
                                dragOffset = 0
                            }
                        } else {
                            withAnimation(HavenTheme.animationCard) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            // Privacy note
            Text("Haven doesn't ask for account numbers or balances. Your attorney will collect those securely in your meeting.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing16)
        }
        .onAppear {
            // Hydrate from existing ratings
            for rating in existingRatings {
                ratings[rating.concernId] = rating.rating
            }
            // Resume at first unrated
            if let firstUnrated = Self.concerns.firstIndex(where: { ratings[$0.id] == nil }) {
                currentIndex = firstUnrated
            }
        }
    }

    // MARK: - Concern Card

    private func concernCard(_ concern: EstateConcern, offset: Int) -> some View {
        VStack(spacing: HavenTheme.spacing16) {
            VStack(spacing: HavenTheme.spacing8) {
                Text(concern.question)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let note = concern.contextNote {
                    Text(note)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, HavenTheme.spacing8)

            // Rating buttons
            if offset == 0 {
                HStack(spacing: HavenTheme.spacing12) {
                    ratingButton("H", label: "High", color: HavenColors.critical, concernId: concern.id)
                    ratingButton("S", label: "Some", color: HavenColors.warning, concernId: concern.id)
                    ratingButton("L", label: "Low", color: HavenColors.success, concernId: concern.id)
                    ratingButton("NA", label: "N/A", color: HavenColors.textTertiary, concernId: concern.id)
                }
            }

            // Show existing rating if going back
            if let existing = ratings[concern.id] {
                HStack(spacing: 4) {
                    Circle()
                        .fill(ratingColor(existing))
                        .frame(width: 6, height: 6)
                    Text("Rated: \(ratingLabel(existing))")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing20)
        .frame(maxWidth: .infinity)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border, lineWidth: 1)
        }
        .havenShadow()
    }

    private func ratingButton(_ short: String, label: String, color: Color, concernId: String) -> some View {
        Button {
            Haptics.medium()
            let ratingValue = label.lowercased()
            ratings[concernId] = ratingValue
            onRate?(concernId, ratingValue)

            // Advance or complete
            if currentIndex < Self.concerns.count - 1 {
                withAnimation(HavenTheme.animationCard) {
                    currentIndex += 1
                }
            } else {
                onComplete?()
            }
        } label: {
            VStack(spacing: 2) {
                Text(short)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ratings[concernId] == label.lowercased() ? .white : color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ratings[concernId] == label.lowercased() ? .white.opacity(0.8) : HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ratings[concernId] == label.lowercased() ? color : color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(HavenButtonPressStyle())
    }

    private func ratingColor(_ rating: String) -> Color {
        switch rating {
        case "high": return HavenColors.critical
        case "some": return HavenColors.warning
        case "low": return HavenColors.success
        default: return HavenColors.textTertiary
        }
    }

    private func ratingLabel(_ rating: String) -> String {
        switch rating {
        case "high": return "High"
        case "some": return "Some"
        case "low": return "Low"
        case "n/a", "na": return "N/A"
        default: return rating.capitalized
        }
    }

    // MARK: - Concerns Data

    struct EstateConcern: Identifiable {
        let id: String
        let question: String
        let contextNote: String?
    }

    static let concerns: [EstateConcern] = [
        EstateConcern(id: "home_protection", question: "What happens to my home(s) if something happens to me?", contextNote: nil),
        EstateConcern(id: "child_guardian", question: "Will my kids be cared for by who I choose?", contextNote: nil),
        EstateConcern(id: "financial_management", question: "Who manages my finances if I can't?", contextNote: nil),
        EstateConcern(id: "spouse_protection", question: "Is my spouse/partner protected?", contextNote: nil),
        EstateConcern(id: "business_continuity", question: "Will my business continue without me?", contextNote: nil),
        EstateConcern(id: "estate_tax", question: "Am I paying more estate tax than necessary?", contextNote: nil),
        EstateConcern(id: "retirement_beneficiaries", question: "Are my retirement accounts going to the right people?", contextNote: nil),
        EstateConcern(id: "long_term_care", question: "What if I need long-term care?", contextNote: nil),
        EstateConcern(id: "digital_access", question: "Are my digital accounts accessible to my family?", contextNote: nil),
        EstateConcern(id: "life_insurance", question: "Is my life insurance adequate?", contextNote: nil),
        EstateConcern(id: "trust_funding", question: "Are my trusts actually funded?", contextNote: nil),
        EstateConcern(id: "pet_care", question: "Will my pets be cared for?", contextNote: nil),
        EstateConcern(id: "charitable_goals", question: "Are my charitable goals documented?", contextNote: nil),
        EstateConcern(id: "healthcare_wishes", question: "Do my healthcare wishes match my documents?", contextNote: nil),
        EstateConcern(id: "tax_law_changes", question: "Is my estate plan current with tax law changes?", contextNote: nil),
    ]
}
