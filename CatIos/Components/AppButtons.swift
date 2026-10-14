import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(LocalizedStringKey(title), systemImage: systemImage)
                } else {
                    Text(LocalizedStringKey(title))
                }
            }
            .font(AppTheme.headlineFont())
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(AppTheme.heroGradient)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(LocalizedStringKey(title), systemImage: systemImage)
                } else {
                    Text(LocalizedStringKey(title))
                }
            }
            .font(AppTheme.headlineFont())
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.1))
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Get started", systemImage: "arrow.right") {}
        SecondaryButton(title: "Not now") {}
    }
    .padding()
    .fantasyScreen()
}
