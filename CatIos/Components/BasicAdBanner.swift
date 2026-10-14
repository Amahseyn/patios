import SwiftUI

struct BasicAdBanner: View {
    var onRemoveAds: () -> Void

    private var ad: HouseAd { HouseAd.today }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingS) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ad")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(LocalizedStringKey(ad.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(ad.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: AppTheme.spacingS)
            Button("Remove", action: onRemoveAds)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, AppTheme.spacingM)
        .padding(.vertical, AppTheme.spacingS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .overlay(alignment: .top) { Divider() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ad. \(ad.title). \(ad.detail)")
        .accessibilityHint("Remove ads with Pet Care+")
    }
}

#Preview {
    BasicAdBanner {}
}
