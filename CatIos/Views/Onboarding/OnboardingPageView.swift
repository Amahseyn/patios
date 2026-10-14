import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppTheme.spacingL) {
            Spacer()
            if let imageName = page.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.primary.opacity(0.18), radius: 12, y: 4)
                    .accessibilityHidden(true)
            } else {
                EnchantedIconBadge(
                    systemImage: page.systemImage ?? "pawprint.fill",
                    tint: AppTheme.palette[page.tintIndex % AppTheme.palette.count],
                    size: 88
                )
            }
            VStack(spacing: AppTheme.spacingS) {
                Text(LocalizedStringKey(page.title))
                    .font(AppTheme.titleFont(26))
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.spacingM)
            Spacer()
        }
        .padding(AppTheme.spacingL)
    }
}
