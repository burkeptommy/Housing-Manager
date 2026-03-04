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
        .frame(minHeight: HavenTheme.minTouchTarget)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
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
        VStack(alignment: .leading, spacing: 2) {
            if isActive {
                Text(title)
                    .font(HavenTypography.caption)
                    .foregroundStyle(labelColor)
            }

            if isSecure {
                SecureField(isActive ? "" : title, text: $text)
                    .font(HavenTypography.body)
                    .focused($isFocused)
            } else {
                TextField(isActive ? "" : title, text: $text)
                    .font(HavenTypography.body)
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
            .foregroundStyle(Color.havenCritical)
        }
    }

    private var iconColor: Color {
        hasError ? Color.havenCritical : (isFocused ? Color.havenAccent : Color.secondary)
    }

    private var labelColor: Color {
        hasError ? Color.havenCritical : (isFocused ? Color.havenAccent : Color.secondary)
    }

    private var borderColor: Color {
        hasError ? Color.havenCritical : (isFocused ? Color.havenAccent : Color(.separator))
    }

    private var borderWidth: CGFloat {
        (isFocused || hasError) ? 1.5 : 0.5
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenTextField(title: "Email", text: .constant("tom@example.com"), icon: "envelope")
        HavenTextField(title: "Password", text: .constant(""), isSecure: true, icon: "lock")
        HavenTextField(title: "Account Number", text: .constant("1234"), icon: "creditcard", errorMessage: "Must be 4 digits")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
