import SwiftUI

struct CategoryProgress: View {
    let category: DocumentCategory
    let documentCount: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
            HStack {
                Image(systemName: documentCount > 0 ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(documentCount > 0 ? Color.havenSuccess : .secondary)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(category.rawValue)
                    .font(HavenTypography.subheadline)
                Spacer()
                if documentCount > 0 {
                    Text("\(documentCount)")
                        .font(HavenTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.havenAccent)
                }
                Text("\(Int(progress * 100))%")
                    .font(HavenTypography.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? Color.havenSuccess : Color.havenAccent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(documentCount) documents, \(Int(progress * 100)) percent complete")
    }
}

#Preview {
    CategoryProgress(category: .will, documentCount: 2, progress: 0.6)
        .padding()
}
