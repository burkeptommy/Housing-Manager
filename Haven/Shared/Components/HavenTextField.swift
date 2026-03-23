import SwiftUI

struct HavenTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var icon: String? = nil
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    private var hasError: Bool { errorMessage != nil }
    private var isActive: Bool { isFocused || !text.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
            // Label above field — SF Pro 10pt, ALL CAPS, letter-spacing 1.5
            if isActive {
                Text(title.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(labelColor)
            }

            fieldContainer
            errorLabel
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private var fieldContainer: some View {
        HStack(spacing: HavenTheme.spacing8) {
            iconView
            inputContent
        }
        .padding(.horizontal, HavenTheme.spacing12)
        .padding(.vertical, 14)
        .background(HavenColors.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
        .shadow(
            color: isFocused && !hasError ? HavenColors.navy500.opacity(0.1) : .clear,
            radius: 4
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 20)
        }
    }

    private var inputContent: some View {
        Group {
            if isSecure {
                SecureField(isActive ? "" : title, text: $text)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .focused($isFocused)
            } else {
                TextField(isActive ? "" : title, text: $text)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
            }
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let errorMessage {
            HStack(spacing: HavenTheme.spacing4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                Text(errorMessage)
                    .font(HavenTypography.caption)
            }
            .foregroundStyle(HavenColors.critical)
        }
    }

    private var iconColor: Color {
        hasError ? HavenColors.critical : (isFocused ? HavenColors.navy700 : HavenColors.textTertiary)
    }

    private var labelColor: Color {
        hasError ? HavenColors.critical : (isFocused ? HavenColors.navy700 : HavenColors.textTertiary)
    }

    private var borderColor: Color {
        hasError ? HavenColors.critical : (isFocused ? HavenColors.navy500 : HavenColors.beige200)
    }

    private var borderWidth: CGFloat {
        (isFocused || hasError) ? 1 : 1
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenTextField(title: "Email", text: .constant("tom@example.com"), icon: "envelope")
        HavenTextField(title: "Password", text: .constant(""), isSecure: true, icon: "lock")
        HavenTextField(title: "Account Number", text: .constant("1234"), icon: "creditcard", errorMessage: "Must be 4 digits")
    }
    .padding()
    .background(HavenColors.background)
}
